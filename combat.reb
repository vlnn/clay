Rebol [
    Title: "AoC 2018 day 24 - host driver for combat.glossary"
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

day24: glossary load %combat.glossary
