# Program 09: chemiosmosis with the real record, not illustrative items

Written 2026-10-30. A program of work, not a decision: decision 9 asked what to do about the
illustrative items in `BioLean/Examples/Chemiosmosis.lean`, and Dan chose "more research needed".
Nothing in the core was changed.

Files: `BioLean/Stress/ChemiosmosisReal.lean` (the record and every pin; about 28 s, exit 0, no
`sorry`, 68 theorems and 146 `#guard`s), `data/stress/09/` (record, cases, checks, sweeps),
`scripts/stress/chemiosmosis_*.py` (emitter, exact mirror, runner, checkers).

## Summary

- **What I did.** I replaced the example's illustrative items with the real record: 62 dated papers,
  1952 to 2024, all checked. 58 have a direction and are encoded on today's core. 49 stress cases,
  all run in Lean and pinned. An independent review re-ran everything and fixed what it found (section 9).
- **The M2 exit, on real items.** "Contested in 1965" holds. "Slater refuted by 1974" fails in every
  year, in both encodings (proved), under every weighting tried. "Established by 1974" fails (1974
  belief 0.702), but hangs on two 1966 papers whose direction I took from memory. Drop either one
  and, in the example's own encoding, chemiosmosis is established every year 1974 to 2025.
- **Why Slater is never refuted.** Seven reports of a chemical intermediate were never retracted, so
  they vote for ever (own belief 0.739 today). The rivalry turns that into disbelief in
  chemiosmosis. Only 2 of the 7 have a dated refutation. Letting evidence fade with age (N) fades
  chemiosmosis too.
- **Other failures.** Williams' localised coupling as a third rival makes chemiosmosis contested from
  1982 to 2025, though it refines proton coupling. A rival with no data is refuted. In 47 years the
  verdict sits within 0.02 of a threshold.
- **Tally.** 12 PASS, 22 FAIL, 6 SILENT, 9 INEXPRESSIBLE. 12 of the 22 FAILs share one cause: undead
  evidence. Right: hypotheses weigh nothing, the fusion algebra, context by refinement, and
  chemiosmosis on its own evidence (established from 1973).
- **What matters now.** M2's "met" holds only on a hand-picked sample. The next steps need no core
  change: check the two decisive 1966 papers (E1), then a sourced retirement list (D1, E2), a lint
  against rivals that refine each other (M), and the exit restated on the full record (E8).

## Words used here

| word | meaning here |
|---|---|
| opinion | belief b, disbelief d, uncertainty u, summing to 1 (`Belief.lean`) |
| established, refuted | b at least θ = 4/5; d at least θ |
| contested | b and d both at least τ = 1/4 (checked first) |
| unsupported | none of the above |
| pseudo-count | weight r counts as r/(1-r) items: an experiment (1/2) is 1, a review (3/5) is 1.5. STATUS counts twice this (an RCT is 11); only the ratios matter |
| rivalry | `Rivalry`: rivals that cannot both be true; each rival's belief becomes disbelief in the others |
| C, S, W, G, M | chemiosmosis (Mitchell), chemical intermediate (Slater), localised coupling (Williams), conformational model (Green), murburn (Manoj) |
| single entry | each item on the one rival it bears on, as the `Rivalry` docstring asks |
| dual entry | a discriminating experiment also goes on S as a refutation, as the example does; it counts twice |
| advocate's review | a review by a theory's own author; weight 0 in the baseline, like a hypothesis |
| memory item | an item whose direction I took from memory, not from a source: UNVERIFIED |
| undead evidence | an item never retracted that still votes decades later |
| undercutter | evidence that an argument for a claim is weak, without showing the claim false |
| margin | distance from an opinion to the nearest threshold that would change its verdict |
| PROTO | prototype in `BioLean.Proto.ChemiosmosisReal`; not core |

## 1. The question

The example replays the chemiosmotic controversy as dated evidence: six real papers and three
illustrative items (PMID 0). The M2 exit says: chemiosmosis contested in 1965, established by 1974,
and Slater refuted by 1974, in Lean. With the illustrative items all three are theorems. Do they
hold on the real record? If not, what should change: the record, the encoding, or the core?

The axis is supersession. Cumulative fusion never forgets (STATUS, learned #2); a rivalry was meant
to fix that.

## 2. The record

`data/stress/09/record.tsv`, emitted into Lean by `chemiosmosis_emit.py`.

| rival | experiments | reviews | hypotheses | total |
|---|---:|---:|---:|---:|
| C chemiosmosis | 19 (16 for, 3 against) | 5 | 4 | 28 |
| S chemical intermediate | 9 (7 for, 2 against) | 1 | 1 | 11 |
| W localised coupling | 8 (7 for, 1 against) | 4 | 5 | 17 |
| G conformational | 0 | 0 | 1 | 1 |
| M murburn | 0 | 0 | 1 | 1 |
| neutral (kept aside) | | | | 4 |

- **Checked.** 73 works in 74 checks: 69 on Europe PMC, 5 on Crossref (Slater 1967 on both). The
  review re-checked all of them afresh, plus every DOI in the record and 33 CURIEs on OLS4.
- **Direction.** For the 39 C and S items, the direction comes from the title in 22, the abstract in
  8, history papers in 3 and memory in 6.
- **Weights.** Experiment 1/2. Review 3/5. Hypothesis 0. An advocate's own review 0 in the baseline.

## 3. The options

### 3.1 The idea, and what it does to the formal system

| letter | idea | changes the core? | needs |
|---|---|---|---|
| A | keep the illustrative items | no (data) | nothing |
| B | swap each illustrative item for one real one | no (data) | three PMIDs (done) |
| C | the full real record on today's core, reported as it is | no (data and a Stress file) | one agreed encoding |
| D | retire an item from the year it was shown wrong. D1 a dated list; D2 a field on `Evidence`; D3 an attack graph; D4 drop a whole rival | D1 no; D2 yes (new field; `Statement.asOf` and `Evidence.opinionAt` change); D3 yes (new type and operator); D4 no (curator builds per-year rivalries) | a sourced date per report; only 2 of 7 have one |
| E | "phosphohistidine is C~I" as `Claim.rel is_a`, plus a rule lifting `mediatedBy` along is_a of the mediator | yes: a new `Derivation` rule, and `Rivalry` must take derivations | the isomer; the rule's opinion |
| F | neutral evidence. F1 a side list; F2 a third `Polarity`; F3 polarity by year | F1 no; F2 yes (new constructor); F3 yes (type change) | nothing for F1 (done) |
| G | one lab, one vote | yes as an averaging-fusion operator plus a source key (M6); no as a merge at import. Run here only as a crude merge | a lab key per item (done) |
| H | one multinomial opinion over the rivals (Jøsang 2016) | yes: new opinion type and operator; `Rivalry` rewritten | where a refutation's mass goes |
| I | a rival takes disbelief only once in scope. I1 from its proposal; I2 from its first item that is not a hypothesis | yes, small, inside `Rivalry.opinions`; or no, if the curator builds each year's rivalry from the rivals in scope | nothing new |
| J | rival hierarchy: proton coupling (parent) rivals S; bulk and localised protons are rival children | no as two rivalries; yes if child evidence must lift (needs E) | a parent or child reading per item |
| K | recorded consensus as evidence (Nobel 1978 speech as `.textbook`, 4/5) | no if `.textbook` is reused; yes for `EvidenceKind.canonical` (M4) | a rule for what counts as consensus |
| L | thresholds per question, and a margin report | no (θ and τ are already parameters) | a stated reason per choice |
| M | lint: no PMID on two rivals; no two rivals with one claim; no rival refining another | no as a Bool lint; yes as proof fields on `Rivalry` | refinement read from the curie (done) |
| N | forgetting: each item's weight halves every h years | yes: a new operator (an age-discounted `opinionAt`); no new type | a half-life, and a reason for it |

N was added at review: the usual answer to "fusion never forgets".

### 3.2 Right and wrong (all run, except E)

| letter | right | wrong |
|---|---|---|
| A | theorems stay green | rests on invented items; drop any one of its 4 real experiments and C falls to 0.750 (CH-07) |
| B | every item real; 1965 and 1974 opinions equal the example's exactly (CH-37) | one item per side, chosen to pass |
| C | honest; shows the undead evidence; 1965 survives | M2 drops from met to partly met |
| D | retire all 7 reports, dual entry: 1974 C established (0.803), S refuted (0.819) | 1965 C then unsupported (0.585); the 2 sourced retirements alone leave 1974 C at 0.728 (single); 5 of 7 dates are judgement |
| E | not run: CH-11 becomes stateable; J gets its lifting rule | two core changes for one case family |
| F | CH-13, CH-14 stateable (F2, F3) | no verdict moves: a vacuous item changes nothing (`fuse_vacuous`) |
| G | honours "one lab, one vote" (CH-17) | C contested every year 1965 to 2025, never established |
| H | each PMID counts once | C's share is at most 0.567 in any year; coarsened, W and G are refuted with no data in every year tested |
| I | I2 stops "refuted with no evidence" (CH-08, CH-19, CH-22); example theorems unchanged | I1 leaves W refuted 1962 to 1981; I2 frees murburn (CH-45 PASS to FAIL) |
| J | W no longer contests C; child W never refuted | parent keeps undead S; child evidence cannot reach the parent without E |
| K | dual entry: C established every year from 1977, through the 1978 dissent (proved) | single entry: still unsupported (1978 b=0.758) |
| L | shows fragility: τ = 1/5 makes 1974 contested, θ = 7/10 established | tuning to pass is p-hacking; report margins instead |
| M | flags CH-18, CH-20, CH-40; clean on single entry and on J | no verdict moves |
| N | old reports fade: with h = 10, S's belief is 0.083 by 2020 | S is never refuted; single entry never establishes C, because C's evidence fades too (h = 5, 10, 20) |

## 4. The stress set

The full table, with input, sources, the test that pins each case and its cause, is in
`data/stress/09/cases.tsv`. Four cases are synthetic (CH-20, CH-35, CH-36, CH-38).

### 4.1 By cause

| cause | cases | marks |
|---|---|---|
| undead evidence: nothing retires an item | 13 | 12 FAIL, 1 INEXPRESSIBLE |
| weights and kinds the curator picks | 7 | 5 FAIL, 1 SILENT, 1 PASS |
| argument structure cannot be stated | 6 | 6 INEXPRESSIBLE |
| scope: disbelief to a rival with no data | 3 | 2 FAIL, 1 PASS |
| flat rivals where one refines another | 3 | 1 FAIL, 1 SILENT, 1 INEXPRESSIBLE |
| textbook and record do not connect | 3 | 2 SILENT, 1 INEXPRESSIBLE |
| independence (one lab, one text) | 2 | 1 FAIL, 1 SILENT |
| lint: rivalry not checked | 2 | 1 FAIL, 1 SILENT |
| works as designed | 10 | 10 PASS |

Five of the FAILs (CH-07, CH-15, CH-16, CH-25, CH-26) are wrong only under a changed weight, review
rule or dropped item. They measure fragility, not a wrong baseline verdict.

### 4.2 Every case

| id | probes | cause | mark |
|---|---|---|---|
| CH-01 | exit claim 1: contested in 1965 | works | PASS |
| CH-02 | exit claim 2: established by 1974 | undead | FAIL |
| CH-03 | exit claim 3: Slater refuted by 1974 | undead | FAIL |
| CH-04 | is C ever established (single entry) | undead | FAIL |
| CH-05 | dual entry as a lever | undead | FAIL |
| CH-06 | one claim, no rivals | undead | FAIL |
| CH-07 | leave one out, example's real papers | weights | FAIL |
| CH-08 | refuted with no evidence (C, 1962 to 1963) | scope | FAIL |
| CH-09 | own evidence established, rivalry says no | undead | FAIL |
| CH-10 | reassigned phosphohistidine reports still vote | undead | FAIL |
| CH-11 | refuting an instance, not the hypothesis | argument | INEXPRESSIBLE |
| CH-12 | unreplicated reports never retire | undead | FAIL |
| CH-13 | reinterpretation over time (X_E) | argument | INEXPRESSIBLE |
| CH-14 | neutral evidence | argument | INEXPRESSIBLE |
| CH-15 | an advocate's own reviews | weights | FAIL |
| CH-16 | one survey review outweighs one experiment | weights | FAIL |
| CH-17 | one lab's series as many votes | independence | FAIL |
| CH-18 | double counting across rivals not flagged | lint | SILENT |
| CH-19 | Williams as a flat third rival | hierarchy | FAIL |
| CH-20 | a statement as its own rival | lint | FAIL |
| CH-21 | evidence that cannot tell bulk from local | hierarchy | INEXPRESSIBLE |
| CH-22 | refuted before proposed (Green 1974) | scope | FAIL |
| CH-23 | priority without evidence (Davies 1952) | works | PASS |
| CH-24 | a theory with no data has no belief | works | PASS |
| CH-25 | experiment weight x2 | weights | FAIL |
| CH-26 | experiment weight x1/2 | weights | FAIL |
| CH-27 | down-weighting the unreplicated side | undead | FAIL |
| CH-28 | dated retirement; what it takes to pass | undead | INEXPRESSIBLE |
| CH-29 | the 2013 textbook as canon | undead | FAIL |
| CH-30 | textbook and historical claim never meet | textbook | SILENT |
| CH-31 | the gradient has no entity | textbook | INEXPRESSIBLE |
| CH-32 | chloroplast evidence on a respiration claim | textbook | SILENT |
| CH-33 | supports the whole, refutes a part | argument | INEXPRESSIBLE |
| CH-34 | one late dissent undoes canon (Maloff 1978) | undead | FAIL |
| CH-35 | order of evidence does not matter | works | PASS |
| CH-36 | eliminating a rival does not crown the other | works | PASS |
| CH-37 | option B swap | works | PASS |
| CH-38 | same PMID twice counts once | works | PASS |
| CH-39 | chemiosmosis on its own evidence | works | PASS |
| CH-40 | a rival that refines another | hierarchy | SILENT |
| CH-41 | an undercutter (van der Bend 1985) | argument | INEXPRESSIBLE |
| CH-42 | coupling mode set by a condition (Chiang 1989) | works | PASS |
| CH-43 | modern dissent as a theory (Nath 2017) | weights | PASS |
| CH-44 | an attack on an attacker (Silva 2020) | argument | INEXPRESSIBLE |
| CH-45 | murburn as a fourth rival | scope | PASS |
| CH-46 | late weightless proposal (Slater 1985) | works | PASS |
| CH-47 | recorded consensus as evidence (Nobel 1978) | undead | FAIL |
| CH-48 | verdicts on a knife edge | weights | SILENT |
| CH-49 | same text in two venues (1966 grey book) | independence | SILENT |

## 5. Results observed

All numbers are from `lake env lean BioLean/Stress/ChemiosmosisReal.lean` on 2026-10-30, truncated
to three decimals, and each is pinned there by a theorem or `#guard`. The Python mirror
(`chemiosmosis_mirror.py`, exact fractions) agrees on all 40 printed cells and reproduces the
example's tables (34 of 34).

### 5.1 The M2 exit claims, real items only

| claim | single entry | dual entry | robust? |
|---|---|---|---|
| C contested in 1965 | contested 1965 to 1973 | contested | yes in single entry: no single item flips it. Dual entry rests on Lehninger 1962 (memory). Holds in 50 of 72 encodings |
| C established by 1974 | unsupported from 1974 for good; never established (proved) | unsupported; established in 1977 only | no: hangs on memory items (5.3) |
| S refuted by 1974 | contested every year from 1964; never refuted (proved) | never refuted (proved) | yes: no weighting or memory choice refutes S without retiring reports |

- **C, single entry.** Refuted in 1962 and 1963, with no data. Contested 1965 to 1973. Unsupported
  from 1974 on. Best year 1977, at 0.750.
- **C, dual entry.** Established in 1977. Maloff 1978 takes it away for good (proved).
- **S.** Established in 1962 and 1963. Contested in every year from 1964 (proved).

### 5.2 Year table

| year | C single | S single | C dual | S dual |
|---|---|---|---|---|
| 1963 | 0.000 / 0.866 refuted | 0.866 / 0.000 established | | |
| 1965 | 0.486 / 0.351 contested | 0.520 / 0.400 contested | 0.533 / 0.288 contested | 0.481 / 0.444 contested |
| 1974 | 0.702 / 0.243 unsupported | 0.505 / 0.426 contested | 0.767 / 0.173 unsupported | 0.378 / 0.571 contested |
| 1977 | 0.750 / 0.207 unsupported | 0.490 / 0.451 contested | 0.819 / 0.133 established | 0.349 / 0.609 contested |
| 1978 | 0.719 / 0.239 unsupported | 0.535 / 0.401 contested | 0.782 / 0.172 unsupported | 0.371 / 0.584 contested |
| 2020 | 0.735 / 0.225 unsupported | 0.523 / 0.415 contested | 0.796 / 0.161 unsupported | 0.365 / 0.591 contested |

Cells are b / d. On its own evidence, chemiosmosis is established from 1973 (1974: 13/16). The
intermediate's own belief was 5/7 in 1974 and is 0.739 today.

### 5.3 What one item decides

| encoding, year | left out | effect |
|---|---|---|
| single, 1965 | any one item | none |
| single, 1974 | any one of 15 (13 pro-C experiments, two 1964 reassignments) | C contested |
| dual, 1965 | Lehninger & Wadkins 1962 (memory) | C unsupported |
| dual, 1974 | Chance & Mela 1966 or Tager 1966 (memory) | C established every year 1974 to 2025 |
| single, 1974 | Chance & Mela, Tager and Lehninger together | C established 1973 to 2025 |
| three rivals, 1985 | Hitchens & Kell 1982 or 1983 | C unsupported, W refuted |
| example's real papers, 1974 | any of its 4 experiments | C falls to 0.750 |

So exit claim 2 is decided by two 1966 papers whose direction is from memory. Neither has an
abstract on Europe PMC. S is never refuted in any row.

### 5.4 Williams as a third rival

- **Single entry.** W is refuted in 1962, 1963, 1965 and 1967 to 1981, with no data of its own.
  Chemiosmosis is contested 1982 to 2025 (2020: C 0.682 / 0.281, W 0.387 / 0.557).
- **Dual entry, or all weights x2.** C established in 1977 only.
- **The Rivalry accepts W, though W's mediator refines C's** (CH-40): the core's refinement axiom
  says hydron in the inner membrane is_a hydron, at 0.999.
- **Fixes.** J removes the false contest. I2 removes the refutation with no data. H does neither.

### 5.5 Weights by a factor of 2

On the pseudo-count: experiments 1/2 to 2/3 or 1/3; reviews 3/5 to 3/4 or 3/7. Every cell pinned
(`weightRow`).

| weights | 1965 C, single | 1974 C, single | 1974 C, dual | S refuted ever? |
|---|---|---|---|---|
| standard | contested | unsupported | unsupported | no |
| experiments x2 | **unsupported** | unsupported | **established** | no |
| experiments x1/2 | contested | **contested** | unsupported | no |
| reviews x2 | contested | **contested** | unsupported | no |
| reviews x1/2 | contested | unsupported | unsupported | no |
| all x2 | contested | unsupported | **established** | no |
| all x1/2 | contested | **contested** | unsupported | no |
| C x2, S x1/2 | **unsupported** | unsupported | **established** | no |

Six of seven changed rows move a verdict. No weighting refutes Slater.

### 5.6 Thresholds and margins

- τ = 1/5 makes 1974 chemiosmosis contested; θ = 7/10 makes it established from 1974.
- The 1974 margin is 1/148.
- The knife edge is chronic. Single entry: within 0.02 of a verdict-changing threshold in 47 years;
  1978 to 2019 all at 0.010 (d = 0.239 against τ). Dual entry: 54 years; 2020 is 0.004 under 4/5.

### 5.7 What it takes to pass (CH-28)

The grid: 2 entry rules x 2 review rules x 3 retirement sets x 3 weightings x 2 (memory items kept or
dropped) = 72. The exit passes in 8. All 8 retire all 7 reports, 5 with no dated source, and drop
the 6 memory items. Of the 72, 1965 contested holds in 50 and 1974 C established in 35. 1974 S
refuted holds in 18: none without retirement; 2 with only the two sourced retirements (both dual
entry, all weights x2, memory items dropped); 16 that retire all 7.

### 5.8 Forgetting (option N, added at review)

Each item's pseudo-count halves every h years. Computed in pseudo-counts, outside the core; with no
decay it equals the core's rivalry exactly (pinned for 1965, 1974 and 2020, both entries).

- For h = 5, 10 and 20: single entry never establishes C, and S is never refuted in either entry.
- Dual entry establishes C only in 1976 and 1977 (h = 5, 10) or 1977 and 1986 (h = 20).
- In 2020 (h = 10) both are unsupported: C 0.621 / 0.106, S 0.083 / 0.619. In this record the last
  experiment for C is from 1977, so forgetting erases the winner too. It would need K beside it.

### 5.9 Corrections

Three predictions in an earlier agent's research notes were wrong when run. H was meant to stop W
and G being refuted with no data; it does not. Under shared counting (CH-21) S is not contested
every year. In Chiang & Dilley 1989 (CH-42) the localised arm is 100 mM KCl plus 5 mM CaCl2, not
CaCl2 alone. The review's corrections are in section 9.

## 6. Experiments for later

Each has its exit test first, then its cost in agent tasks.

| id | exit test | what | cost |
|---|---|---|---|
| E1 | each of the 8 memory directions gets a quoted sentence from a checked source, or is dropped; grid and 5.3 rerun. c21 and c22 first: they decide exit claim 2 | verify directions; 1966 Nature letters may be paywalled | 1 |
| E2 | every S report has a sourced retirement year or "never"; grid rerun; pass count reported | option D1, outside the core | 1 to 2 |
| E3 | CH-10, CH-12 and CH-28 PASS; no example theorem changes; 1965 stays contested | prototype D2 (`retiredIn` on a copy of `Evidence`) | 1 |
| E4 | CH-19, CH-21 and CH-40 PASS; the refinement lint is clean on every rivalry in the repo | options J and M together; decide which localised items are child-level | 2 |
| E5 | CH-18 PASS without dual entry; a coarsened rival with no data is not refuted; a `belief_le` analogue proved | option H done properly | 3 to 4 |
| E6 | CH-41 and CH-44 expressible; van der Bend weakens the localised tests it reproduced and leaves the Hitchens & Kell 1983 design standing | an undercutting list outside the core: (attacker, attacked item) pairs | 2 |
| E7 | every verdict printed with its margin; CH-48 flagged | option L in `Derivation.report` style, outside the core | 0.5 |
| E8 | a theorem over the full record, one agreed encoding: contested 1965; C established and S refuted by 1978 | restate the M2 exit, after E1, E2, E4 | 1 |
| E9 | single entry, h = 10, with the 1978 speech and the 2013 textbook as canon on C: C established in every year from 1978, and S's belief under 1/4 from 1990 | N plus K: does canon rescue forgetting? | 0.5 |

## 7. What would change the decision

- If Chance & Mela 1966 or Tager 1966 did not argue against chemiosmosis, dual entry passes exit claim
  2 in every year from 1974 (5.3). E1 settles this. Claim 3 would still fail.
- If the exit year moved from 1974 to 1978, canon plus dual entry (K) passes claim 2 with no
  retirement. Harold 2001 dates the controversy at 15 years from 1961; Manoj 2019 says "since
  mid-1970s". So 1974 is itself early.
- If Dan accepts a curator's dated retirement as data, "Slater refuted" needs no core change (D1).
  But 5 of the 7 dates are not in the record.
- If W stays a flat rival, chemiosmosis is contested from 1982. Only J, or a hierarchy in H, avoids it.
- If the weights of 5.5 are a fair range, no verdict here is robust: program 10a comes first.

**Roadmap.**
- M2 exit: met on a curated sample only. STATUS and ROADMAP say "met"; this doc does not edit them.
- M4 canonical kind: option K, CH-47; and E9.
- M6 averaging fusion and weights: options G and N, CH-17, CH-25 to CH-27; shared with program 10a.
- M8 literature at scale: dated records like this are what M8 must produce, with direction and
  retirement as fields.

## 8. Limits

- The mirror checks the arithmetic, not my reading of the core. Lean is the authority.
- Direction comes from the title for 22 of the 39 C and S items: weaker than an abstract.
- "Experiment" lumps designs together at 1/2: a reconstitution weighs the same as a stoichiometry note.
- Chloroplast, bacterial and liposome items sit on a mitochondrial claim with no transfer step (CH-32).
- Putting Rieger 2014, Toth 2020, Lee 2021 and Silverstein 2024 under Williams' rival is my grouping.
- The record is my selection. Verdicts resting on one item (5.3) could move with another.

## 9. Review (2026-10-30)

An independent agent re-ran every file and checked every source.
- **Reproduced.** Lean compiles (exit 0, no `sorry`). Every script reproduced its outputs exactly.
- **Checked afresh** (`chemiosmosis_review.py`, new download folder). 69 PMIDs on full title, first
  author and year; 64 DOIs; 33 CURIEs; 19 quoted phrases in `cases.tsv`; the 3 textbook sentences.
  All pass. I read the abstract behind every case that has one.
- **Fixed.** 41 `#guard`s and 1 theorem added: numbers that were only in the mirror (grid sub-counts,
  the weights table, several cells) are now pinned. The memory dependence of claim 2 is now in the
  Summary. CH-41 misread van der Bend 1985: it names the Hitchens & Kell 1983 design as the one
  test that "may discriminate". Record notes for w13 and w15 corrected. RO:0002219 was used but not
  checked. Option labels G, D2 and I were imprecise. Option N was missing. A cause column was added
  to `cases.tsv`. Eight test citations were loose; the cases script now checks each one exists.
- **Not changed.** Marks and verdicts. The w13 direction (refutes W) stays, as the core's only option;
  leaving it out changes no three-rival verdict.

## 10. References (checked)

Title, first author and year checked on Europe PMC (PMIDs) or Crossref (DOIs) on 2026-10-30. Titles
are cut short here; all 74 in full are in `data/stress/09/references_checked.tsv`.

| id | first author, year | short title |
|---|---|---|
| PMID 14925142 | Davies RE 1952 | transport of ions by nervous tissue |
| PMID 13111237 | Slater EC 1953 | phosphorylation in the respiratory chain |
| PMID 13771349 | Mitchell P 1961 | chemi-osmotic type of mechanism |
| PMID 13785509 | Williams RJP 1961 | chains of catalysts |
| PMID 14014715 | Boyer PD 1962 | phosphohistidine ... probable intermediate |
| PMID 14463786 | Lehninger AL 1962 | Oxidative phosphorylation |
| PMID 5871845 | Mitchell RA 1964 | phosphohistidine ... succinate thiokinase |
| PMID 5332854 | Kreil G 1964 | phosphohistidine in E. coli succinate thiokinase |
| PMID 4222981 | Mitchell P 1965 | stoichiometry of proton translocation |
| PMID 5870319 | Mitchell P 1965 | evidence discriminating ... chemical and chemiosmotic |
| PMID 5329743 | Mitchell P 1966 | chemiosmotic coupling (Biol Rev) |
| PMID 22082452 | Mitchell P 2011 | the same, 1966 (grey book reprint) |
| PMID 5220864 | Jagendorf AT 1966 | ATP formation by acid-base transition |
| PMID 5970146 | Chance B 1966 | proton movements in mitochondrial membranes |
| PMID 4381909 | Tager JM 1966 | chemi-osmotic theory of oxidative phosphorylation |
| PMID 16742541 | Mitchell P 1967 | respiration-driven proton translocation |
| PMID 4517939 | Oesterhelt D 1973 | a new photoreceptor membrane |
| PMID 4517936 | Boyer PD 1973 | a new concept for energy coupling |
| PMID 4272126 | Racker E 1974 | reconstitution of purple membrane vesicles |
| PMID 4151654 | Green DE 1974 | the electromechanochemical model |
| PMID 15223 | Wikstrom MK 1977 | proton pump coupled to cytochrome c oxidase |
| PMID 18361775 | Boyer PD 1977 | oxidative phosphorylation and photophosphorylation |
| PMID 670292 | Maloff BL 1978 | membrane potentials of giant mitochondria |
| PMID 708723 | Williams RJP 1978 | the multifarious couplings of energy transduction |
| PMID 6293600 | Hitchens GD 1982 | localized energy coupling ... chromatophores |
| PMID 6870853 | Hitchens GD 1983 | uncouplers can shuttle between ... sites |
| PMID 2996506 | Van der Bend RL 1985 | a critical appraisal of ... localized energy coupling |
| DOI 10.1016/0304-4173(85)90005-9 | Ferguson SJ 1985 | fully delocalised ... or localised proton flow? |
| PMID 2861851 | Slater EC 1985 | a hypothesis ... not involving the proton gradient |
| PMID 2422160 | Nagle JF 1986 | models of localized energy coupling |
| PMID 16666959 | Chiang GG 1989 | Ca-gated switching ... coupling |
| PMID 24476986 | Rieger B 2014 | lateral pH gradient ... ATP-synthase |
| PMID 28882384 | Nath S 2017 | two-ion theory of energy coupling |
| PMID 31622585 | Manoj KM 2019 | chemiosmotic and murburn explanations |
| PMID 32717593 | Silva PJ 2020 | chemiosmotic misunderstandings |
| PMID 8842371 | Prebble J 1996 | successful theory development in biology |
| PMID 11536297 | Harold FM 2001 | gleanings of a chemiosmotic eye |
| PMID 11859886 | Prebble J 2001 | philosophical origins of Mitchell's concepts |
| PMID 12068893 | Allchin D 2002 | to err and win a Nobel Prize |
| PMID 23104597 | Prebble JN 2013 | contrasting approaches to a biological problem |
| DOI 10.1207/s15516709cog1104_4 | Pollock JL 1987 | Defeasible Reasoning |
| DOI 10.1007/978-3-319-42337-1 | Jøsang A 2016 | Subjective Logic |

Also: Ernster L, presentation speech, Nobel Prize in Chemistry 1978, read 2026-10-30 at
https://www.nobelprize.org/prizes/chemistry/1978/ceremony-speech/. OpenStax Concepts of Biology,
how-cells-obtain-energy-m45439-36, -37 and -73. CURIEs: `curies_checked.tsv`.

## 11. UNVERIFIED

- Directions from memory (8). Chance & Mela 1966 and Tager 1966 against C: exit claim 2 in dual entry
  depends on each. Lehninger & Wadkins 1962 for S: the dual 1965 verdict depends on it. Mitchell &
  Moyle 1965 (PMID 5870319), by title and authorship. Slater 1967 against C. The 1977 joint review
  for C. Williams 1978 FEBS Lett (PMID 23315) for W, by authorship. Ferguson 1985 against W. None has
  an abstract on Europe PMC; the papers there citing c21 and c22 are not open access.
- Wikstrom 1977 being at odds with Mitchell's redox-loop scheme (CH-33).
- The X_E reinterpretation of Hind & Jagendorf 1963 (CH-13).
- Which phosphohistidine isomer Boyer reported (CHEBI:18847 or CHEBI:19855).
- That Science 1979 (PMID 388618) is the printed Nobel lecture.
- Retirement years for Pinchot 1960 and 1962, Griffiths & Chaplain 1962, Painter & Hunter 1970 and
  Griffiths 1976: no dated refutation found; 1974 in PROTO D1 is my judgement.
- Murburn entered as a hypothesis only; its authors' claimed experimental support was not checked.
- Option E is reasoned, not run. Options G, H, J and N were run only as crude prototypes.
