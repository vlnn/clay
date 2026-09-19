Rebol [
    Title:   "Clay - a top-down tablet language"
    Purpose: {A .clay file is a tablet: one bounded page of definitions
              read top to bottom. The first entry is the incipit; every
              later entry must define a phrase some earlier body has
              already used (the law: wish before define). Phrase names
              are kebab-case and bodies spell them exactly as defined.
              Argument specs may read as sentence templates:
              [from an attacker to a defender] declares attacker and
              defender. doc: entries document the definition just above
              and surface through the host's native help. example:
              entries sit at a phrase's first mention or definition.
              Loading a tablet fires it in the kiln: every example runs,
              and failures are cracks. clay/soft skips the firing while
              a piece is still being shaped. Words that no definition or
              primitive ever answers are a compile-time error: an
              unfulfilled wish.
              A tablet is loaded with:  clay load %some.clay}
]

template-words: [the a an of to by in with from for at on some]
example-links:  [is are]

cracks: 0

template-args: function [spec][
    collect [foreach w spec [unless find template-words w [keep w]]]
]

clay-entries: func [defs /local name b1 b2 s][
    collect [
        parse defs [some [
            set name set-word! (b2: none  s: none)
            [set s string! | set b1 block! opt [set b2 block!]]
            (keep to word! name
             keep/only either b2 [b1][copy []]
             either s [keep s][keep/only either b2 [b2][b1]])
        ]]
    ]
]

clay-wishes: function [body locals wished][
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

fire-example: function [subject body ctx][
    got: none
    pos: any [find body 'is  find body 'are]
    unless pos [
        print ajoin ["CRACK (" subject "): no 'is'/'are' assertion"]
        return false
    ]
    left:  copy/part body pos
    right: copy next pos
    set/any 'got try [do bind/copy left ctx]
    expect: either all [1 = length? right  block? first right]
        [first right]
        [do bind/copy right ctx]
    case [
        error? get/any 'got [
            print ajoin ["CRACK (" subject "): " mold get/any 'got]
            false
        ]
        not equal? get/any 'got expect [
            print ajoin ["CRACK (" subject "): got " mold get/any 'got
                         ", expected " mold expect]
            false
        ]
        true [print ajoin ["ok   fired (" subject ")"]  true]
    ]
]

kiln: function [examples ctx][
    flaws: 0
    foreach [subject body] examples [
        unless fire-example subject body ctx [flaws: flaws + 1]
    ]
    flaws
]

clay: function [
    defs [block!]
    /soft "shape only: skip the kiln, run no examples"
][
    entries: clay-entries defs

    table: collect [
        foreach [name argspec body] entries [
            unless any [name = 'example  string? body][keep name]]
    ]

    wished: copy []  defined: copy []  all-locals: copy []  examples: copy []
    wish-origin: copy []  prev: none  docs: copy []
    foreach [name argspec body] entries [
        case [
            string? body [
                unless name = 'doc [
                    do make error! ajoin [
                        "Only doc: may take a string; '" name "' is given one"]
                ]
                unless prev [
                    do make error! "doc: appears before any definition"
                ]
                if select docs prev [
                    do make error! ajoin ["'" prev "' is documented twice"]
                ]
                append docs reduce [prev body]
                append/only all-locals none
            ]
            name = 'example [
                subject: none
                if all [prev  find body prev][subject: prev]
                foreach v body [
                    if all [none? subject  word? v  find table v
                            not find defined v
                            prev = select wish-origin v][
                        subject: v]
                ]
                n0: length? wished
                clay-wishes body copy [] wished
                foreach w skip wished n0 [append wish-origin reduce [w prev]]
                append examples any [subject prev "..."]
                append/only examples body
                append/only all-locals none
            ]
            true [
                unless any [empty? defined  find wished name][
                    do make error! ajoin [
                        "Clay law: '" name "' is defined before anything wished for it"]
                ]
                append defined name
                locals: template-args argspec
                n0: length? wished
                clay-wishes body locals wished
                foreach w skip wished n0 [append wish-origin reduce [w name]]
                append/only all-locals locals
                prev: name
            ]
        ]
    ]
    foreach w wished [
        unless any [find defined w  value? w  find [return break continue] w][
            do make error! ajoin [
                "Unfulfilled wish: '" w "' is used but never defined"]
        ]
    ]

    ctx: make object! append collect [foreach w defined [keep to set-word! w]] none

    foreach [name argspec body] entries [
        locals: take all-locals
        if any [name = 'example  string? body][continue]
        msg: ajoin ["in '" name "':"]
        wrapped: compose/only [
            set/any 'clay-err try (bind/copy body ctx)
            either error? get/any 'clay-err [
                print [(msg) mold cracked-open get/any 'clay-err]
                do get/any 'clay-err
            ][
                get/any 'clay-err
            ]
        ]
        spec: template-args argspec
        locals: exclude unique locals spec
        unless empty? locals [append spec /local  append spec locals]
        if d: select docs name [insert spec d]
        set in ctx name func spec wrapped
    ]

    set 'cracks either soft [0][kiln examples ctx]
    ctx
]

cracked-open: func [e][reduce [e/id e/arg1]]

;; ------------------------------------------------- ordering & small helpers

whole: func [x][to integer! x]

pick-max: function [coll score][
    best: none  bs: none
    foreach c coll [
        s: score c
        if any [none? best  s > bs][best: c  bs: s]
    ]
    best
]

key-scores: function [keys g][
    collect [foreach k keys [f: get k  keep f g]]
]

ranked: function [coll keys [block!]][
    pool: copy coll
    collect [
        while [not empty? pool][
            best: pick-max pool func [g] compose/only [key-scores (keys) g]
            keep best
            remove find/same pool best
        ]
    ]
]
