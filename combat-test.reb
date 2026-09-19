Rebol [Title: "Glossary day 24 - tests (v2)"]

do %combat.reb

failures: glossary-failures
check: func [ok msg][
    print either ok [ajoin ["ok   " msg]][
        failures: failures + 1
        ajoin ["FAIL " msg]]
]

check 4 = length? groups "example parses into 4 groups"
check [radiation bludgeoning] = groups/1/weak "group 1 weak to radiation+bludgeoning"
check [fire] = groups/2/immune "group 2 immune to fire"

check 5216 = day24/part-one "part one: winner ends with 5216 units"

day24/boost-by 1570
day24/fight-the-battle
check day24/the-immune-system-won? "boost 1570: the immune system wins"
check 51 = day24/count-the-survivors "boost 1570 leaves 51 units"

check 51 = day24/part-two "part two: least winning bonus leaves 51 units"

print either failures = 0 ["all tests passed"]["some tests FAILED"]
quit/return failures
