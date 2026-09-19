Rebol [
    Title: "AoC 2018 day 24, written in the Glossary dialect (v2)"
]

do %glossary.reb

groups:    copy []
originals: copy []

armies: func [spec [block!] /local army n h g traits ws im d e i][
    clear groups  clear originals
    parse spec [some [
        'immune quote system: (army: 'immune)
      | quote infection:      (army: 'infection)
      | set n integer! 'units  set h integer! 'hp (
            g: make object! [
                units: n  hp: h  damage: 0  element: none  init: 0
                side: army  weak: copy []  immune: copy []
                claim: none  claimed: false]
            append groups g)
        opt [set traits block! (
            parse traits [some [
                'weak   set ws block! (append g/weak ws)
              | 'immune set im block! (append g/immune im)]])]
        'attack set d integer! set e word!  'initiative set i integer! (
            g/damage: d  g/element: e  g/init: i
            append originals reduce [g n d])
    ]]
]

armies [
    immune system:
    17   units 5390 hp [weak [radiation bludgeoning]]               attack 4507 fire        initiative 2
    989  units 1274 hp [immune [fire] weak [bludgeoning slashing]]  attack 25   slashing    initiative 3

    infection:
    801  units 4706 hp [weak [radiation]]                           attack 116  bludgeoning initiative 1
    4485 units 2961 hp [immune [radiation] weak [fire cold]]        attack 12   slashing    initiative 4
]

day24: glossary [
    answers: [part one and part two]
    example: [part one is 5216]
    example: [part two is 51]

    part-one: [restore the armies  fight the battle  count the survivors]
    part-two: [boost by the least winning bonus  fight the battle  count the survivors]

    fight-the-battle: [
        until [any [the war is over?  zero? casualties in a round]]
    ]
    example: [
        restore the armies  casualties in a round
        the units are [0 905 797 4434]
    ]

    casualties-in-a-round: [
        choose targets
        tally: 0
        foreach attacker ranked the living by [initiative] [
            tally: tally + strike attacker]
        tally
    ]

    choose-targets: [
        foreach g groups [g/claim: none  g/claimed: false]
        foreach attacker ranked the living by [power initiative] [
            attacker/claim: best target for attacker
            if attacker/claim [attacker/claim/claimed: true]
        ]
    ]

    strike: [an attacker][
        defender: attacker/claim
        if any [none? defender  attacker/units <= 0][return 0]
        kills: min defender/units  whole (hurt attacker defender) / defender/hp
        defender/units: defender/units - kills
        kills
    ]
    example: [restore the armies  hurt of group 1 to group 4 is twice power of group 1]
    example: [restore the armies  hurt of group 1 to group 2 is 0]

    best-target-for: [an attacker][
        pick-max hittable enemies of attacker  func [d][
            reduce [hurt attacker d  power d  initiative d]]
    ]

    hittable-enemies-of: [an attacker][
        pool: copy []
        foreach d groups [
            if all [d/units > 0
                    d/side <> attacker/side
                    not d/claimed
                    0 < hurt attacker d][append pool d]]
        pool
    ]

    hurt: [from an attacker to a defender][
        if find defender/immune attacker/element [return 0]
        either find defender/weak attacker/element
            [2 * power attacker]
            [power attacker]
    ]

    power: [a group-of-units][group-of-units/units * group-of-units/damage]
    example: [restore the armies  power of group 4 is 53820]

    initiative: [a group-of-units][group-of-units/init]

    the-living: [
        pool: copy []
        foreach g groups [if g/units > 0 [append pool g]]
        pool
    ]

    the-war-is-over?: [any [wiped-out? 'immune  wiped-out? 'infection]]
    wiped-out?: [a side][zero? units-of side]
    units-of: [a side][
        n: 0
        foreach g groups [if g/side = side [n: n + g/units]]
        n
    ]

    count-the-survivors: [(units-of 'immune) + units-of 'infection]
    restore-the-armies:  [foreach [g u d] originals [g/units: u  g/damage: d]]

    boost-by: [a bonus][
        restore the armies
        foreach g groups [if g/side = 'immune [g/damage: g/damage + bonus]]
    ]
    the-least-winning-bonus: [
        n: 0
        forever [
            boost by n  fight the battle
            if the immune system won? [break]
            n: n + 1]
        n
    ]
    the-immune-system-won?: [
        all [not wiped-out? 'immune  wiped-out? 'infection]
    ]

    group:     [i][pick groups i]
    twice:     [a number][2 * number]
    the-units: [
        u: copy []
        foreach g groups [append u g/units]
        u
    ]
]
