# Clay

A tiny language for writing a program as a **tablet**: one bounded page of
definitions that reads top to bottom, where the answer comes first and every
phrase is explained further down — never before you have asked for it.

Clay is implemented as a [Rebol 3](https://github.com/Oldes/Rebol3) dialect in
about 200 lines (`clay.reb`). A program is a `.clay` file loaded with:

```rebol
day24: clay load %combat.clay
day24/part-one    ;= 5216
```

The worked example here is Advent of Code 2018 day 24 (`combat.clay`), whose
opening reads:

```rebol
primitives: [groups originals ranked pick-max whole]

answers: [part-one part-two]
example: [part-one is 5216]
example: [part-two is 51]

part-one: [restore-the-armies  fight-the-battle  count-the-survivors]
part-two: [rearm-with the-least-winning-bonus  fight-the-battle  count-the-survivors]

fight-the-battle: [
    until [any [the-war-is-over?  zero? casualties-in-a-round]]
]
doc: "Rounds continue until one army is empty or a round kills nobody; a stalemate is not a victory."
example: [restore-the-armies  fight-the-battle  the-war-is-over? is true]
```

## Why invent this

Clay began as a question about reading order. Most code is arranged for the
machine — helpers first, answer last, or whatever order accretion left — and
then read by someone who arrived with a question. A tablet inverts that: the
incipit states what the page answers, and the law makes the argument order
the only order the page can have. Three things fall out:

- **Dead code cannot exist.** Defining a phrase nobody asked for is a
  compile error, so a tablet never accumulates leftovers.
- **Tests live where doubt lives.** An example at a phrase's first mention
  is a promise (red before green); after its definition, a demonstration.
  Either way the assertion sits inside the argument, not in a distant file.
- **The vocabulary is closed.** Every word must be defined further down or
  answered by the host, which catches typos, version mismatches, and
  hallucinated vocabulary alike — that last one matters when code is
  generated: a model, or a tired human, cannot lean on a word that nothing
  answers.

The name is the design: clay is soft while you shape it (`clay/soft`) and
hardens in the kiln. A tablet is *bounded* — one page arguing top to
bottom — because one page is the unit a reader can actually hold.

## The law

**Pledge before define.** A phrase may only be defined after some earlier body
has used it — using a word is a pledge that the tablet will define it below.
The first entry — the *incipit* — is exempt: it states what the tablet
answers, and pledges everything else. Defining a phrase nobody has asked for
is a compile error, so dead code cannot exist and the page can only be read
in the order it argues.

**Unfulfilled pledges.** Every word in every body must eventually be defined on
the tablet or already mean something in the host. A word that is neither is a
compile error naming it — which catches typos, version mismatches, and
hallucinated vocabulary alike.

## Entries

A tablet is a sequence of entries, each a set-word followed by one or two
blocks (or a string, for `doc:`):

```rebol
phrase-name: [body]                          ; a definition
phrase-name: [sentence template] [body]      ; a definition taking arguments
doc: "what rule this definition encodes"     ; documents the entry above
example: [scenario is expected]              ; a fired assertion
```

- **Names are kebab-case** and bodies spell them exactly as defined
  (`fight-the-battle` everywhere), so every phrase has one grep-able spelling.
- **Sentence templates**: an argument spec is a sentence of function words
  and Nouns, as in a contract's defined terms. The capitalized Nouns are the
  arguments — `hurt: [from an Attacker to a Defender] [...]` declares
  `attacker` and `defender` — and every lowercase word is decorative, in any
  language. Capitals appear only in specs, at the argument's one declaration
  site; bodies stay lowercase and exact. A template with no Noun, a stray
  Noun the body never touches, and a capital inside a body are each compile
  errors.
- **Set-words inside a body** (`tally: 0`) are that definition's private
  nouns — never shared state. Shared state lives only in host primitives the
  tablet's `primitives:` entry declares (here: `groups`, `originals`).
- **`doc:`** attaches to the definition immediately above and is compiled
  into the generated function's spec, so the host's native `help` shows it:

  ```
  >> help day24/hurt
  DESCRIPTION:
       Damage one whole group deals another: its effective power,
       doubled by weakness, cancelled by immunity.
  ```

## Firing: examples as tests

Clay is soft while you shape it and hardens in the kiln. Loading a tablet
**fires** it: every `example:` runs, in page order, against the live
definitions. `is` / `are` splits scenario from expectation; the scenario is a
sequence of phrases (its own setup included), the expectation is a value or an
expression. A failed example is a **crack**, reported with its subject and
counted on the tablet itself (`day24/clay-cracks`):

```rebol
example: [restore-the-armies  casualties-in-a-round
          the-units are [0 905 797 4434]]
```

While a piece is still being shaped, skip the kiln:

```rebol
day24: clay/soft load %combat.clay    ; no examples run, day24/clay-cracks = 0
```

An example belongs to a *place*, and plays one of two roles there:

- **a promise** — placed at a phrase's first mention, before its definition
  exists (test-first, red before green);
- **a demonstration** — placed right after a definition it exercises.

Phrases an example merely uses for setup (`restore-the-armies` at the head of
most examples here) are *fixtures*, not subjects; attribution goes to the
just-defined phrase when mentioned, otherwise to the phrase first mentioned
at that spot.

## Host contract

A tablet runs against a host script that provides its primitives — for
`combat.clay`, the driver `combat.reb` defines the mutable world (`groups`,
`originals`), the input dialect (`armies [...]`), and loads the tablet. The
machinery itself contributes a small standard vocabulary: `ranked` and
`pick-max` (descending lexicographic orderings — score functions return
blocks of keys) and `whole` (integer floor).

The contract is declared, and checked, on the tablet: an optional
`primitives:` entry ahead of the incipit lists the host words the page leans
on. Each listed word must exist in the host, and once the entry is present,
any *shared state* a body reaches for — a series or object that is neither
defined on the tablet nor listed — fails the load. Plain vocabulary
(functions, natives) stays free; it is the mutable world that must be
declared.

## Writing a good tablet

- **Answer first.** The incipit names the answers; everything below exists
  because something above pledged it. If you cannot say what the tablet
  answers, it is not a tablet yet.
- **Name phrases as prose.** Kebab-case noun phrases and questions —
  `casualties-in-a-round`, `the-war-is-over?` — so bodies read aloud. A body
  that wants a comment usually wants another phrase instead.
- **Promise before you build.** Put `example:` at a phrase's first mention,
  watch it crack, then define the phrase below it. Test-first is the natural
  gait of the law.
- **`doc:` carries the rule, not the mechanics.** "A stalemate is not a
  victory" earns its line; "loops until the condition holds" does not.
- **Declare the world, keep it small.** Everything mutable lives in the host
  and on the `primitives:` list; set-words inside bodies stay private. A
  growing list means the host is doing too little or the tablet too much.
- **Open examples with their fixture.** `restore-the-armies` at the head of
  an example resets the world, so examples never depend on firing order.
- **Shape soft, commit fired.** `clay/soft` while sketching; a tablet goes
  into version control with `clay-cracks` at zero.
- **Loop, don't recurse.** A phrase cannot pledge itself before it exists,
  so direct recursion is impossible under the law — by design. Write the
  cycle as `forever`/`until` (see `the-least-winning-bonus`).
- **One page.** A tablet that outgrows the page wants to be two tablets;
  the series protocol below is the planned answer.

## Running

Requires the [Oldes Rebol 3](https://github.com/Oldes/Rebol3/releases) binary
(a single self-contained executable; this was built against 3.22.1).

```bash
rebol3 -q combat-test.reb      # full suite: fires the tablet + host checks
rebol3 -q sanity.reb           # machinery checks: law, pledges, docs, cracks
rebol3 -qs --do 'do %combat.reb print day24/part-one print day24/part-two'
```

The `-s` flag matters for `--do` and the REPL: without a script file on the
command line, Rebol's `secure` sandbox blocks file reads and `do %combat.reb`
fails with a security violation.

To solve your own AoC input: replace the `armies [...]` block in `combat.reb`
and delete (or re-target) the tablet's `example:` entries — they assert the
worked example's numbers.

## Files

| file              | role                                            |
|-------------------|-------------------------------------------------|
| `clay.reb`        | the language: law, pledges, docs, kiln, helpers |
| `combat.clay`     | the tablet: AoC 2018 day 24, top to bottom      |
| `combat.reb`      | the host: world state, input dialect, load      |
| `combat-test.reb` | firing plus host-side checks                    |
| `sanity.reb`      | machinery self-tests on a tiny tablet           |

## Where the metaphor points next

The tablet tradition names the features Clay doesn't have yet: a **series**
protocol for programs that outgrow one tablet, with each file ending in a
*catchline* — a pledge of the first phrase of the next tablet; a trailing
**colophon** entry for authorship and versioning; and a kiln report that flags
phrases used as fixtures in many examples but never fired as subjects.
