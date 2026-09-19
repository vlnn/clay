Rebol [Title: "glossary v2 sanity"]
do %glossary.reb

tiny: glossary [
    answers:  [the doubled seed and the tripled seed]
    example:  [the doubled seed is 42]
    example:  [the tripled seed is 63]

    the-doubled-seed: [twice of the seed]
    the-tripled-seed: [3 * the seed]
    twice:    [a number][2 * number]
    the-seed: [21]
]
print tiny/the-doubled-seed

if error? err: try [
    glossary [top: [x] orphan: [1]]
][print ["law check fired:" err/arg1]]

if error? err: try [
    glossary [top: [mystery word]]
][print ["wish check fired:" err/arg1]]

if error? err: try [
    glossary [top: [the thing] the: [1]]
][print ["function-word check fired:" err/arg1]]

failing: glossary [
    answers: [the broken sum]
    example: [the broken sum is 5]
    the-broken-sum: [2 + 2]
]
print ["failures counted:" glossary-failures]
