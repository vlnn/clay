Rebol [Title: "glossary v4 sanity"]
do %glossary.reb

tiny: glossary [
    answers:  [the-doubled-seed the-tripled-seed]
    example:  [the-doubled-seed is 42]
    example:  [the-tripled-seed is 63]

    the-doubled-seed: [twice the-seed]
    the-tripled-seed: [3 * the-seed]
    twice:    [a number][2 * number]
    the-seed: [21]
]
print tiny/the-doubled-seed

if error? err: try [
    glossary [top: [x] orphan: [1]]
][print ["law check fired:" err/arg1]]

if error? err: try [
    glossary [top: [mystery-word]]
][print ["wish check fired:" err/arg1]]

failing: glossary [
    answers: [the-broken-sum]
    example: [the-broken-sum is 5]
    the-broken-sum: [2 + 2]
]
print ["failures counted:" glossary-failures]

documented: glossary [
    answers: [the-sum]
    the-sum: [2 + 3]
    doc: "adds two and three"
]
print mold spec-of get in documented 'the-sum

if error? err: try [
    glossary [doc: "orphan doc" top: [1]]
][print ["doc-placement check fired:" err/arg1]]

if error? err: try [
    glossary [answers: [x] x: [1] doc: "one" doc: "two"]
][print ["duplicate-doc check fired:" err/arg1]]
