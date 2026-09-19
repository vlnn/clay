Rebol [
    Title:   "Glossary - a top-down dialect, v2"
    Purpose: {A glossary is a block of definitions read top to bottom.
              The first entry is the table of contents; every later entry
              must define a phrase some earlier body has already used
              (the use-before-define law). A phrase name may span several
              words: bodies write `fight the battle`, the definition is
              `fight-the-battle:`, and the compiler joins the longest
              matching run (no meaning is ever silently dropped). Only a
              small closed set of English function words is decorative.
              `example:` entries sit at a phrase's first mention and run
              as tests after the glossary loads. Words that no definition
              or primitive ever answers are a compile error: an
              unfulfilled wish.}
]

function-words: [the a an of to by in with and or then its their from for at on]
example-links:  [is are]

glossary-failures: 0

phrase-tokens: func [name /local parts][
    parts: copy []
    foreach s split to string! name #"-" [append parts to word! s]
    parts
]

glossary-munch: func [blk table longest /local out i k run cand joined v][
    out: copy []
    i: 1
    while [i <= length? blk][
        v: pick blk i
        case [
            word? v [
                k: min longest (1 + (length? blk) - i)
                cand: none
                while [all [none? cand  k >= 2]][
                    run: copy/part at blk i k
                    if parse run [some word!][
                        joined: attempt [to word! form-phrase run]
                        if all [joined  find table joined][cand: joined]
                    ]
                    k: k - 1
                ]
                either cand [
                    append out cand
                    i: i + length? phrase-tokens cand
                ][
                    append out v
                    i: i + 1
                ]
            ]
            block? v [append/only out glossary-munch v table longest  i: i + 1]
            paren? v [
                append/only out to paren! glossary-munch to block! v table longest
                i: i + 1
            ]
            true [append/only out v  i: i + 1]
        ]
    ]
    out
]

form-phrase: func [run /local s][
    s: copy ""
    foreach w run [append s to string! w  append s "-"]
    head remove back tail s
]

glossary-strip: func [blk /local out v][
    out: copy []
    foreach v blk [
        case [
            all [word? v  find function-words v] []
            block? v [append/only out glossary-strip v]
            paren? v [append/only out to paren! glossary-strip to block! v]
            true     [append/only out v]
        ]
    ]
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
    left:  glossary-strip copy/part body pos
    right: glossary-strip next pos
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

glossary: func [
    defs [block!]
    /local entries name b1 b2 wished defined stripped all-locals locals
           table longest examples spec body bound i argspec msg wrapped
           subject munched ctx e w v wish-origin prev n0
][
    entries: copy []
    parse defs [some [
        set name set-word! (b2: none)
        set b1 block! opt [set b2 block!]
        (append/only entries reduce [
            to word! name
            either b2 [b1][copy []]
            either b2 [b2][b1]])
    ]]

    table: copy []  longest: 1
    foreach e entries [
        unless 'example = first e [
            append table first e
            longest: max longest length? phrase-tokens first e
        ]
    ]
    foreach w table [
        if find function-words w [
            do make error! ajoin [
                "Glossary law: '" w "' is a function word and cannot be defined"]
        ]
    ]

    wished: copy []  defined: copy []  stripped: copy []
    all-locals: copy []  examples: copy []
    wish-origin: copy []  prev: none
    foreach e entries [
        set [name argspec body] e
        munched: glossary-munch body table longest
        either name = 'example [
            subject: none
            foreach v munched [
                if all [none? subject  word? v  find table v  not find defined v
                        prev = select wish-origin v][
                    subject: v]
            ]
            n0: length? wished
            glossary-wishes glossary-strip munched copy [] wished
            foreach w skip wished n0 [append wish-origin reduce [w prev]]
            append/only examples reduce [any [subject prev "..."] munched]
            append/only stripped none
            append/only all-locals none
        ][
            unless any [empty? defined  find wished name][
                do make error! ajoin [
                    "Glossary law: '" name "' is defined before anything wished for it"]
            ]
            append defined name
            body: glossary-strip munched
            append/only stripped body
            locals: glossary-strip argspec
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
        bound: bind/copy pick stripped i ctx
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
        spec: glossary-strip argspec
        locals: exclude unique any [pick all-locals i copy []] spec
        unless empty? locals [append spec /local  append spec locals]
        set in ctx name func spec wrapped
    ]

    glossary-failures: 0
    foreach e examples [run-example first e second e ctx]
    ctx
]

disarm-safe: func [e][reduce [e/id e/arg1]]

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
