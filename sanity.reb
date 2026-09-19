Rebol [Title: "clay sanity"]
do %clay.reb

failures: 0
expect: func [ok msg][
    print either ok [ajoin ["ok   " msg]][
        failures: failures + 1
        ajoin ["FAIL " msg]]
]

tiny: clay [
    answers:  [the-doubled-seed the-tripled-seed]
    example:  [the-doubled-seed is 42]
    example:  [the-tripled-seed is 63]

    the-doubled-seed: [twice the-seed]
    the-tripled-seed: [3 * the-seed]
    twice:    [a Number][2 * number]
    the-seed: [21]
]
expect 42 = tiny/the-doubled-seed "a fired tablet should answer through its context"
expect 0 = tiny/clay-cracks "a sound tablet should fire with no cracks"
expect not value? 'cracks "crack counts should live on the tablet, not in a global"

err: try [clay [top: [x] orphan: [1]]]
expect all [error? err  find err/arg1 "defined before"]
    "the law should reject a definition nothing pledged"

err: try [clay [top: [mystery-word]]]
expect all [error? err  find err/arg1 "never defined"]
    "an unfulfilled pledge should be a compile error"
expect all [error? err  find err/arg1 "first pledged in 'top'"]
    "an unfulfilled pledge should name where it was first pledged"

err: try [clay [answers: [the-thing]  the-thing: [1]  junk 42  never-seen: [2]]]
expect all [error? err  find err/arg1 "malformed"]
    "a malformed entry should error, not truncate the tablet"

err: try [clay [answers: [the-thing]  the-thing: 42]]
expect all [error? err  find err/arg1 "malformed"]
    "an entry that is neither block nor string should error"

err: try [clay [answers: [the-thing]  the-thing: [1]  the-thing: [2]]]
expect all [error? err  find err/arg1 "defined twice"]
    "a duplicate definition should be a compile error"

err: try [clay/soft [answers: [the-thing]  example: [the-thing 5]  the-thing: [5]]]
expect all [error? err  find err/arg1 "'is'/'are'"]
    "an example without is/are should error at load, even soft"

looped: clay [
    answers: [the-repeat-sum the-for-sum the-doubled-list the-trimmed-list]
    the-repeat-sum:   [t: 0  repeat i 4 [t: t + i]  t]
    the-for-sum:      [t: 0  for j 1 3 1 [t: t + j]  t]
    the-doubled-list: [map-each x [1 2 3] [x * 2]]
    the-trimmed-list: [v: copy [1 2 3 4]  remove-each y v [y > 2]  v]
]
expect 10 = looped/the-repeat-sum "repeat should bind its loop word"
expect 6 = looped/the-for-sum "for should bind its loop word"
expect [2 4 6] = looped/the-doubled-list "map-each should bind its loop word"
expect [1 2] = looped/the-trimmed-list "remove-each should bind its loop word"

err: try [clay [answers: [the-echo]  the-echo: [double 3]
               double: [a number][2 * number]]]
expect all [error? err  find err/arg1 "no Nouns"]
    "a sentence template without a Noun should be a compile error"

err: try [clay [answers: [the-echo]  the-echo: [double 3]
               double: [a Number times Extra][2 * number]]]
expect all [error? err  find err/arg1 "stray Noun"]
    "a Noun the body never touches should be a compile error"

err: try [clay [answers: [the-echo]  the-echo: [double 3]
               double: [a Number][2 * Number]]]
expect all [error? err  find err/arg1 "lowercase"]
    "a capitalized word in a body should be a compile error"

spoken: clay [
    answers: [the-greeting]
    the-greeting: [greet "world"]
    greet: [a Name by some polite words][ajoin ["hello, " name]]
]
expect "hello, world" = spoken/the-greeting
    "Nouns should bind as arguments; any lowercase word should be prose"

cracked: clay [
    answers: [the-broken-sum]
    example: [the-broken-sum is 5]
    the-broken-sum: [2 + 2]
]
expect 1 = cracked/clay-cracks "a failed example should be counted as a crack"

still-soft: clay/soft [
    answers: [the-broken-sum]
    example: [the-broken-sum is 5]
    the-broken-sum: [2 + 2]
]
expect 0 = still-soft/clay-cracks "a soft load should run no examples"
expect 4 = still-soft/the-broken-sum "a soft load should still define phrases"
expect 1 = cracked/clay-cracks
    "a later load should not clobber an earlier tablet's crack count"

the-hoard: copy [1 2 3]
guarded: clay [
    primitives: [the-hoard]
    answers: [the-hoard-total]
    the-hoard-total: [t: 0  foreach x the-hoard [t: t + x]  t]
]
expect 6 = guarded/the-hoard-total "declared shared state should be usable"

err: try [clay [
    primitives: []
    answers: [the-hoard-total]
    the-hoard-total: [t: 0  foreach x the-hoard [t: t + x]  t]
]]
expect all [error? err  find err/arg1 "shared state"]
    "shared state missing from primitives: should be a compile error"

err: try [clay [primitives: [no-such-hoard]  answers: [x]  x: [1]]]
expect all [error? err  find err/arg1 "not provided"]
    "a primitive the host lacks should be a compile error"

shaky: clay [
    answers: [the-shaky-division]
    the-shaky-division: [1 / 0]
]
err: try [shaky/the-shaky-division]
expect all [error? err  find mold cracked-open err "/ 0"]
    "cracked-open should point near the offending code"
expect not value? 'clay-err "clay-err should not leak into the global context"

documented: clay [
    answers: [the-sum]
    the-sum: [2 + 3]
    doc: "adds two and three"
]
expect "adds two and three" = first spec-of get in documented 'the-sum
    "doc: should land in the generated function's spec"

err: try [clay [doc: "orphan doc" top: [1]]]
expect all [error? err  find err/arg1 "before any definition"]
    "doc: before any definition should be an error"

err: try [clay [answers: [x] x: [1] doc: "one" doc: "two"]]
expect all [error? err  find err/arg1 "documented twice"]
    "a second doc: on one definition should be an error"

print either failures = 0 ["all sanity checks passed"]["some sanity checks FAILED"]
quit/return failures
