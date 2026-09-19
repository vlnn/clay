Rebol [Title: "clay sanity"]
do %clay.reb

tiny: clay [
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
    clay [top: [x] orphan: [1]]
][print ["law check fired:" err/arg1]]

if error? err: try [
    clay [top: [mystery-word]]
][print ["wish check fired:" err/arg1]]

cracked: clay [
    answers: [the-broken-sum]
    example: [the-broken-sum is 5]
    the-broken-sum: [2 + 2]
]
print ["cracks counted:" cracks]

still-soft: clay/soft [
    answers: [the-broken-sum]
    example: [the-broken-sum is 5]
    the-broken-sum: [2 + 2]
]
print ["soft load, cracks:" cracks "value:" still-soft/the-broken-sum]

documented: clay [
    answers: [the-sum]
    the-sum: [2 + 3]
    doc: "adds two and three"
]
print mold spec-of get in documented 'the-sum

if error? err: try [
    clay [doc: "orphan doc" top: [1]]
][print ["doc-placement check fired:" err/arg1]]

if error? err: try [
    clay [answers: [x] x: [1] doc: "one" doc: "two"]
][print ["duplicate-doc check fired:" err/arg1]]
