Rebol [
    Title:   "Clay - a top-down tablet language"
    Purpose: {A .clay file is a tablet: one bounded page of definitions
              read top to bottom under the law - pledge before define.
              Loading fires every example in the kiln; failures are
              cracks, counted on the returned context (ctx/clay-cracks).
              A tablet is loaded with:  clay load %some.clay
              The README tells the rest.}
]

example-links: [is are]

capitalized?: function [w][
    ch: first form w
    all [ch >= #"A"  ch <= #"Z"]
]

template-args: function [spec][
    collect [
        foreach w spec [
            if all [word? w  capitalized? w][keep to word! lowercase form w]]
    ]
]

mentions?: function [blk w][
    foreach v blk [
        case [
            all [any-word? v  w = to word! v][return true]
            any [path? v  set-path? v][
                if mentions? to block! v w [return true]]
            any [block? v  paren? v][
                if mentions? to block! v w [return true]]
        ]
    ]
    false
]

lowercase!: function [name body][
    foreach v body [
        case [
            all [any-word? v  capitalized? v][
                do make error! ajoin [
                    "Clay body: '" name "' spells '" v
                    "' with a capital; bodies are lowercase"]
            ]
            any [path? v  set-path? v  block? v  paren? v][
                lowercase! name to block! v]
        ]
    ]
]

clay-entries: func [defs /local name b1 b2 s mark][
    collect [
        unless parse defs [some [
            mark:
            set name set-word! (b2: none  s: none)
            [set s string! | set b1 block! opt [set b2 block!]]
            (keep to word! name
             keep/only either b2 [b1][copy []]
             either s [keep s][keep/only either b2 [b2][b1]])
        ]][
            do make error! ajoin [
                "Clay entry malformed near: " mold copy/part mark 3]
        ]
    ]
]

clay-pledges: function [body locals pledged][
    walk: func [blk /local v w][
        forall blk [
            v: blk/1
            case [
                set-word? v [append locals to word! v]
                any [lit-word? v refinement? v] []
                all [word? v  find example-links v] []
                all [word? v  find [foreach repeat for map-each remove-each
                                    func function does] v][
                    w: pick blk 2
                    case [
                        word? w  [append locals w]
                        block? w [foreach x w [if word? x [append locals x]]]
                    ]
                ]
                word? v [
                    unless any [find locals v  find pledged v][append pledged v]
                ]
                any [path? v  set-path? v][
                    w: first v
                    if all [word? w  not find locals w  not find pledged w][
                        append pledged w
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
            unless any [name = 'example  name = 'primitives  string? body][
                keep name]]
    ]

    pledged: copy []  defined: copy []  all-locals: copy []  examples: copy []
    pledge-origin: copy []  prev: none  docs: copy []  prims: none
    foreach [name argspec body] entries [
        case [
            name = 'primitives [
                if prims [do make error! "primitives: is declared twice"]
                unless empty? defined [
                    do make error! "primitives: must precede the incipit"
                ]
                unless parse body [any word!][
                    do make error! "primitives: takes a block of words"
                ]
                prims: body
                append/only all-locals none
            ]
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
                unless any [find body 'is  find body 'are][
                    do make error! ajoin [
                        "example has no 'is'/'are' assertion: " mold body]
                ]
                lowercase! name body
                subject: none
                if all [prev  find body prev][subject: prev]
                foreach v body [
                    if all [none? subject  word? v  find table v
                            not find defined v
                            prev = select pledge-origin v][
                        subject: v]
                ]
                n0: length? pledged
                clay-pledges body copy [] pledged
                foreach w skip pledged n0 [append pledge-origin reduce [w prev]]
                append examples any [subject prev "..."]
                append/only examples body
                append/only all-locals none
            ]
            true [
                if find defined name [
                    do make error! ajoin ["'" name "' is defined twice"]
                ]
                unless any [empty? defined  find pledged name][
                    do make error! ajoin [
                        "Clay law: '" name "' is defined before anything pledged it"]
                ]
                append defined name
                locals: template-args argspec
                unless any [empty? argspec  not empty? locals][
                    do make error! ajoin [
                        "Clay spec: '" name "' has a sentence with no Nouns: "
                        mold argspec]
                ]
                foreach a locals [
                    unless mentions? body a [
                        do make error! ajoin [
                            "Clay spec: '" name "' declares a stray Noun: '" a "'"]
                    ]
                ]
                lowercase! name body
                n0: length? pledged
                clay-pledges body locals pledged
                foreach w skip pledged n0 [append pledge-origin reduce [w name]]
                append/only all-locals locals
                prev: name
            ]
        ]
    ]
    if prims [
        foreach w prims [
            unless value? w [
                do make error! ajoin [
                    "Primitive '" w "' is not provided by the host"]
            ]
        ]
    ]
    foreach w pledged [
        case [
            any [find defined w  find [return break continue] w][]
            not value? w [
                origin: select pledge-origin w
                do make error! ajoin [
                    "Unfulfilled pledge: '" w "' is used but never defined"
                    either origin [
                        ajoin [" (first pledged in '" origin "')"]][""]]
            ]
            all [prims  shared-state? get w  not find prims w][
                do make error! ajoin [
                    "Undeclared shared state: '" w
                    "' is missing from the primitives: entry"]
            ]
        ]
    ]

    ctx: make object! append collect [
        foreach w defined [keep to set-word! w]
        keep to set-word! 'clay-cracks
    ] none

    foreach [name argspec body] entries [
        locals: take all-locals
        if any [name = 'example  name = 'primitives  string? body][continue]
        msg: ajoin ["in '" name "':"]
        wrapped: compose/deep/only [
            set/any 'clay-err try (bind/copy body ctx)
            either error? get/any 'clay-err [
                print [(msg) mold cracked-open get/any 'clay-err]
                do get/any 'clay-err
            ][
                get/any 'clay-err
            ]
        ]
        spec: template-args argspec
        locals: exclude unique append locals 'clay-err spec
        append spec /local
        append spec locals
        if d: select docs name [insert spec d]
        set in ctx name func spec wrapped
    ]

    ctx/clay-cracks: either soft [0][kiln examples ctx]
    ctx
]

shared-state?: func [v [any-type!]][any [series? :v  object? :v  map? :v]]

cracked-open: func [e][reduce [e/id e/arg1 e/near]]

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
