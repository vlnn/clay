Rebol [
    Title:   "Glossary - a top-down dialect, v3"
    Purpose: {A glossary is a block of definitions read top to bottom.
              The first entry is the table of contents; every later entry
              must define a phrase some earlier body has already used
              (the use-before-define law). Phrase names are kebab-case
              and bodies spell them exactly as defined, so every phrase
              has one grep-able spelling and nothing is ever rewritten
              or dropped. Argument specs may read as sentence templates:
              [from an attacker to a defender] declares attacker and
              defender. `example:` entries sit at a phrase's first
              mention and run as tests after the glossary loads. Words
              that no definition or primitive ever answers are a
              compile-time error: an unfulfilled wish. glossary-print
              renders the source as prose for review.}
]

template-words: [the a an of to by in with from for at on some]
example-links:  [is are]

glossary-failures: 0

template-args: func [spec /local out w][
    out: copy []
    foreach w spec [unless find template-words w [append out w]]
    out
]

glossary-wishes: func [body locals wished /local walk][
    walk: func [blk /local v w][
        forall blk [
            v: blk/1
            case [
                set-word? v [append locals to word! v]
                any [lit-word? v refinement? v] []
                all [word? v  find example-links v] []
                all [word? v  find [foreach func function does] v][
                    w: pick blk 2
                    case [
                        word? w  [append locals w]
                        block? w [foreach x w [if word? x [append locals x]]]
                    ]
                ]
                word? v [
                    unless any [find locals v  find wished v][append wished v]
                ]
                any [path? v  set-path? v][
                    w: first v
                    if all [word? w  not find locals w  not find wished w][
                        append wished w
                    ]
                ]
                any [block? v  paren? v][walk to block! v]
            ]
        ]
    ]
    walk body
]

run-example: func [subject body ctx /local pos left right expect got][
    pos: any [find body 'is  find body 'are]
    unless pos [
        print ajoin ["FAIL example (" subject "): no 'is'/'are' assertion"]
        glossary-failures: glossary-failures + 1
        exit
    ]
    left:  copy/part body pos
    right: copy next pos
    set/any 'got try [do bind/copy left ctx]
    expect: either 1 = length? right [first right][do bind/copy right ctx]
    case [
        error? get/any 'got [
            print ajoin ["FAIL example (" subject "): " mold get/any 'got]
            glossary-failures: glossary-failures + 1
        ]
        not equal? get/any 'got expect [
            print ajoin ["FAIL example (" subject "): got " mold get/any 'got
                         ", expected " mold expect]
            glossary-failures: glossary-failures + 1
        ]
        true [print ajoin ["ok   example (" subject ")"]]
    ]
]

glossary-entries: func [defs /local entries name b1 b2][
    entries: copy []
    parse defs [some [
        set name set-word! (b2: none)
        set b1 block! opt [set b2 block!]
        (append/only entries reduce [
            to word! name
            either b2 [b1][copy []]
            either b2 [b2][b1]])
    ]]
    entries
]

glossary: func [
    defs [block!]
    /local entries name wished defined stripped all-locals locals
           table examples spec body bound i argspec msg wrapped
           subject ctx e w v wish-origin prev n0
][
    entries: glossary-entries defs

    table: copy []
    foreach e entries [unless 'example = first e [append table first e]]

    wished: copy []  defined: copy []  all-locals: copy []  examples: copy []
    wish-origin: copy []  prev: none
    foreach e entries [
        set [name argspec body] e
        either name = 'example [
            subject: none
            foreach v body [
                if all [none? subject  word? v  find table v  not find defined v
                        prev = select wish-origin v][
                    subject: v]
            ]
            n0: length? wished
            glossary-wishes body copy [] wished
            foreach w skip wished n0 [append wish-origin reduce [w prev]]
            append/only examples reduce [any [subject prev "..."] body]
            append/only all-locals none
        ][
            unless any [empty? defined  find wished name][
                do make error! ajoin [
                    "Glossary law: '" name "' is defined before anything wished for it"]
            ]
            append defined name
            locals: template-args argspec
            n0: length? wished
            glossary-wishes body locals wished
            foreach w skip wished n0 [append wish-origin reduce [w name]]
            append/only all-locals locals
            prev: name
        ]
    ]
    foreach w wished [
        unless any [find defined w  value? w  find [return break continue] w][
            do make error! ajoin [
                "Unfulfilled wish: '" w "' is used but never defined"]
        ]
    ]

    spec: copy []
    foreach w defined [append spec to set-word! w]
    append spec none
    ctx: make object! spec

    repeat i length? entries [
        set [name argspec body] pick entries i
        if name = 'example [continue]
        bound: bind/copy body ctx
        msg: ajoin ["in '" name "':"]
        wrapped: compose/only [
            set/any 'glossary-err try (bound)
            either error? get/any 'glossary-err [
                print [(msg) mold disarm-safe get/any 'glossary-err]
                do get/any 'glossary-err
            ][
                get/any 'glossary-err
            ]
        ]
        spec: template-args argspec
        locals: exclude unique any [pick all-locals i copy []] spec
        unless empty? locals [append spec /local  append spec locals]
        set in ctx name func spec wrapped
    ]

    glossary-failures: 0
    foreach e examples [run-example first e second e ctx]
    ctx
]

disarm-safe: func [e][reduce [e/id e/arg1]]

;; ------------------------------------------------------------- the printer

spaced: func [w][replace/all form w "-" " "]

render-prose: func [blk table /local out v s][
    out: copy ""
    foreach v blk [
        s: case [
            all [word? v  find table v][spaced v]
            any [set-word? v  set-path? v][mold v]
            lit-word? v [form v]
            block? v  [ajoin ["[" render-prose v table "]"]]
            paren? v  [ajoin ["(" render-prose to block! v table ")"]]
            string? v [mold v]
            true      [form v]
        ]
        unless empty? out [append out " "]
        append out s
    ]
    out
]

glossary-print: func [defs /local entries table e name argspec body out][
    entries: glossary-entries defs
    table: copy []
    foreach e entries [unless 'example = first e [append table first e]]
    out: copy ""
    foreach e entries [
        set [name argspec body] e
        append out either name = 'example [
            ajoin ["    e.g. " render-prose body table "^/"]
        ][
            ajoin [
                spaced name
                either empty? argspec [""][ajoin [" (" render-prose argspec table ")"]]
                ":^/    " render-prose body table "^/"
            ]
        ]
    ]
    out
]

;; ------------------------------------------------- ordering & small helpers

whole: func [x][to integer! x]

lex-greater?: func [a [block!] b [block!] /local i][
    repeat i length? a [
        if a/:i > b/:i [return true]
        if a/:i < b/:i [return false]
    ]
    false
]

pick-max: func [coll score /local best bs s c][
    best: none  bs: none
    foreach c coll [
        s: score c
        if any [none? best  lex-greater? s bs][best: c  bs: s]
    ]
    best
]

key-scores: func [keys g /local out f k][
    out: copy []
    foreach k keys [f: get k  append out f g]
    out
]

ranked: func [coll keys [block!] /local pool out best][
    pool: copy coll
    out: copy []
    while [not empty? pool][
        best: pick-max pool func [g] compose/only [key-scores (keys) g]
        append out best
        remove find/same pool best
    ]
    out
]
