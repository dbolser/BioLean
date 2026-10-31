# Program 09: chemiosmosis with the real record, not illustrative items

Written 2026-10-30; rebuilt and reviewed 2026-10-31. A program of work, not a decision: for decision 9
(the illustrative items in `BioLean/Examples/Chemiosmosis.lean`) Dan chose "more research needed".
Nothing in the core was changed.

Files: `BioLean/Stress/ChemiosmosisReal.lean` (33 s, exit 0, no `sorry`, 75 theorems, 3 examples,
177 `#guard`s), `data/stress/09/`, `scripts/stress/chemiosmosis_*.py`. Prototypes (PROTO) sit in
`BioLean.Proto.ChemiosmosisReal` at the end of that file; the Stress part never uses them.

## Summary

- **What I did.** Replaced the illustrative items with the real record: 62 dated papers, each
  checked; 58 encoded. 50 stress cases, run in Lean and pinned. A review re-ran it
  all (all reproduced) and added one case and one dated retirement.
- **The M2 exit.** "Contested in 1965" holds. "Established by 1974" fails (belief 0.702); in single
  entry chemiosmosis is never established, in any year (proved). "Slater refuted" fails in every
  year, both encodings, every weighting (proved).
- **Why.** Seven reports of a chemical intermediate were never retracted, so they vote for ever.
  The rivalry turns that into disbelief in chemiosmosis. 13 of the 23 FAILs share this cause. Even
  the 1978 Nobel consensus, entered against Slater, does not refute him (CH-50).
- **What fixes it, outside the core.** Retire the reports by date: two from 1964 (reassigned); five
  from 1978, my reading of one blanket sentence in the Nobel speech ("no experimental evidence could
  be obtained"). Drop the six memory items too, and single entry passes the exit restated for 1978.
  But 1965 then sits exactly on the threshold.
- **Tally.** 12 PASS, 23 FAIL, 6 SILENT, 9 INEXPRESSIBLE. Also wrong: Williams as a flat rival; a
  rival with no data is refuted. Right: hypotheses weigh nothing, the fusion algebra, context.
- **What matters now.** M2's "done" holds only on a hand-picked sample. Next, all outside the core:
  read the two 1966 letters (E1), agree the retirement list as data (D1, E2), restate the exit at
  1978 (E8).

## Words used here

| word | meaning here |
|---|---|
| opinion | belief b, disbelief d, uncertainty u, summing to 1 (`Belief.lean`) |
| established, refuted | b at least θ = 4/5; d at least θ |
| contested | b and d both at least τ = 1/4 (checked first) |
| unsupported | none of the above |
| pseudo-count | weight r counts as r/(1-r) items: experiment (1/2) 1, review (3/5) 1.5 |
| rivalry | `Rivalry`: rivals that cannot both be true; each one's belief is disbelief in the others |
| C, S, W, G, M | chemiosmosis (Mitchell), chemical intermediate (Slater), localised coupling (Williams), conformational model (Green), murburn (Manoj) |
| single entry | each item on the one rival it bears on, as the `Rivalry` docstring asks |
| dual entry | a discriminating experiment also refutes S, as in the example; it counts twice |
| advocate's review | a review by a theory's own author; weight 0 in the baseline |
| memory item | direction taken from memory, not a source: UNVERIFIED |
| undead evidence | an item never retracted that still votes decades later |
| retire | stop counting an item from a given year |
| undercutter | evidence that an argument for a claim is weak, without showing the claim false |
| parent, child rival | proton coupling (parent) rivals S; bulk and localised protons (children) rival each other |
| margin | distance from an opinion to the nearest verdict threshold |

## 1. The question

The example replays the chemiosmotic controversy as dated evidence: six real papers and three
illustrative items (PMID 0). The M2 exit: chemiosmosis contested in 1965, established by 1974, and
Slater refuted by 1974, in Lean. With the illustrative items all three are theorems. Do they hold on
the real record? If not, what should change: the record, the encoding, or the core?

The axis is supersession. Cumulative fusion never forgets (STATUS, learned #2); the rivalry was meant
to fix that.

## 2. The record

`data/stress/09/record.tsv`, emitted into Lean by `chemiosmosis_emit.py` (re-emitted at review: no
change).

| rival | experiments | reviews | hypotheses | total |
|---|---:|---:|---:|---:|
| C chemiosmosis | 19 (16 for, 3 against) | 5 | 4 | 28 |
| S chemical intermediate | 9 (7 for, 2 against) | 1 | 1 | 11 |
| W localised coupling | 8 (7 for, 1 against) | 4 | 5 | 17 |
| G conformational | 0 | 0 | 1 | 1 |
| M murburn | 0 | 0 | 1 | 1 |
| neutral (kept aside) | | | | 4 |

- **Checked.** 75 works in 76 checks: 71 on Europe PMC, 5 on Crossref (Slater 1967 on both).
- **Direction.** For the 39 C and S items: title 22, abstract 8, history papers 3, memory 6.

## 3. The options

### 3.1 The idea, and what it does to the formal system

| letter | idea | changes the core? | needs |
|---|---|---|---|
| A | keep the illustrative items | no (data) | nothing |
| B | swap each illustrative item for one real one | no (data) | three PMIDs (done) |
| C | the full real record on today's core, reported as it is | no (data and a Stress file) | one agreed encoding |
| D | retire an item from the year it was shown wrong. D1 a dated list; D2 a field on `Evidence`; D3 an attack graph; D4 drop a whole rival | D1 no; D2 yes (new field, `Evidence.opinionAt` changes); D3 yes (new type and operator); D4 no (per-year rivalries) | dated sources: 2 of 7 have one; the 1978 Nobel speech dates 5 as a class |
| E | the phosphohistidine reports on a narrower claim ("via phospho-L-histidine", CHEBI:26048), lifted to S along is_a of the mediator | yes: a new `Derivation` rule, and `Rivalry` must take derivations | the rule's opinion (`weakest`, as for is_a) |
| F | neutral evidence. F1 a side list; F2 a third `Polarity`; F3 polarity by year | F1 no; F2 yes (new constructor); F3 yes (type change) | nothing for F1 (done) |
| G | one lab, one vote | yes as an averaging operator plus a source key (M6); no as a merge at import | a lab key per item (done) |
| H | one multinomial opinion over the rivals (Jøsang 2016) | yes: new opinion type and operator; `Rivalry` rewritten | where a refutation's mass goes |
| I | a rival takes disbelief only once in scope. I1 from its proposal; I2 from its first non-hypothesis item | yes, small, in `Rivalry.opinions`; or no (per-year rivalries) | nothing new |
| J | rival hierarchy: proton coupling (parent) rivals S; bulk and localised protons are rival children | no as two rivalries; yes if child evidence must lift (needs E) | a parent or child reading per item |
| K | recorded consensus as evidence (Nobel 1978 speech as `.textbook`, 4/5) | no if `.textbook` is reused; yes for `EvidenceKind.canonical` (M4) | a rule for what counts as consensus |
| L | thresholds per question, and a margin report | no (θ and τ are already parameters) | a stated reason per choice |
| M | lint: no PMID on two rivals; no two rivals with one claim; no rival refining another | no as a Bool lint; yes as proof fields on `Rivalry` | refinement read from the curie (done) |
| N | forgetting: each item's weight halves every h years | yes: a new operator (age-discounted `opinionAt`) | a half-life, and a reason |

### 3.2 Right and wrong (all run; prototypes where the core lacks them)

| letter | right | wrong |
|---|---|---|
| A | theorems stay green | rests on invented items; drop any one of its 4 real experiments: C 0.750 (CH-07) |
| B | every item real; 1965 and 1974 opinions equal the example's exactly (CH-37) | one item per side, chosen to pass |
| C | honest; shows the undead evidence; 1965 survives | M2 drops from met to partly met |
| D | all 7 retired by 1974, dual: 1974 C established (0.803), S refuted (0.819). Dated retirement, no memory items, single: the exit at 1978 passes (5.10) | dual: 1965 C unsupported (0.585); the 1978 pass has no margin; the phosphohistidine pair alone: 1974 C 0.728 |
| E | CH-11 stateable; the 1964 papers no longer count against S as a whole | the disputed instance still lifts b = 0.400; S's own belief rises to 0.860; C contested 1965 to 2025 |
| F | CH-13, CH-14 stateable (F2, F3) | no verdict moves: a vacuous item changes nothing (`fuse_vacuous`) |
| G | honours "one lab, one vote" (CH-17) | C contested every year 1965 to 2025, never established |
| H | each PMID counts once | C's share is at most 0.567 in any year; coarsened, W and G are refuted with no data |
| I | I2 stops "refuted with no evidence" (CH-08, CH-19, CH-22); example theorems unchanged | I1 leaves W refuted in most years 1962 to 1981; I2 frees murburn (CH-45 PASS to FAIL) |
| J | W no longer contests C; child W never refuted | parent keeps undead S; child evidence cannot reach the parent without E |
| K | dual: C established every year from 1977 (proved). On both rivals, single entry too, from 1978 (CH-50) | on C only, single entry: unsupported (1978 b = 0.758); on both, S is still never refuted |
| L | shows fragility: τ = 1/5 makes 1974 contested, θ = 7/10 established | tuning to pass is p-hacking; report margins instead |
| M | flags CH-18, CH-20, CH-40; clean on single entry and on J | no verdict moves |
| N | old reports fade: with h = 10, S's belief is 0.083 by 2020 | S never refuted; single entry never establishes C: its evidence fades too |

Read correctly, CH-11 retires the phosphohistidine reports with their refutations (D1,
`phosphoBoth`): 1974 C is then contested (0.604 / 0.348). So today's "unsupported" leans on two 1964
papers counted against Slater's whole hypothesis.

## 4. The stress set

The full table (input, sources, pinning test, cause) is in `data/stress/09/cases.tsv`. Four cases are synthetic (CH-20, CH-35, CH-36, CH-38).

### 4.1 By cause

| cause | cases | marks |
|---|---|---|
| undead evidence: nothing retires an item | 14 | 13 FAIL, 1 INEXPRESSIBLE |
| weights and kinds the curator picks | 7 | 5 FAIL, 1 SILENT, 1 PASS |
| argument structure cannot be stated | 6 | 6 INEXPRESSIBLE |
| scope: disbelief to a rival with no data | 3 | 2 FAIL, 1 PASS |
| flat rivals where one refines another | 3 | 1 FAIL, 1 SILENT, 1 INEXPRESSIBLE |
| textbook and record do not connect | 3 | 2 SILENT, 1 INEXPRESSIBLE |
| independence (one lab, one text) | 2 | 1 FAIL, 1 SILENT |
| lint: rivalry not checked | 2 | 1 FAIL, 1 SILENT |
| works as designed | 10 | 10 PASS |

Five FAILs (CH-07, CH-15, CH-16, CH-25, CH-26) measure fragility: they are wrong only under a
changed weight, review rule or dropped item.

### 4.2 Every case

| id | probes | cause | mark |
|---|---|---|---|
| CH-01 | exit claim 1: contested in 1965 | works | PASS |
| CH-02 | exit claim 2: established by 1974 | undead | FAIL |
| CH-03 | exit claim 3: Slater refuted by 1974 | undead | FAIL |
| CH-04 | is C ever established (single entry) | undead | FAIL |
| CH-05 | dual entry as a lever | undead | FAIL |
| CH-06 | one claim, no rivals | undead | FAIL |
| CH-07 | leave one out, the example's real papers | weights | FAIL |
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
| CH-50 | recorded consensus on both rivals (Nobel 1978) | undead | FAIL |

## 5. Results observed

All numbers are from `lake env lean BioLean/Stress/ChemiosmosisReal.lean`, re-run 2026-10-31,
truncated to three decimals. Each is pinned there by a theorem or `#guard`. The Python mirror
(exact fractions) agrees on all 40 printed cells, on option E and on 5.10.

### 5.1 The M2 exit claims, real items only

| claim | single entry | dual entry | robust? |
|---|---|---|---|
| C contested in 1965 | contested 1965 to 1973 | contested | single entry: no single item flips it. Dual entry rests on Lehninger 1962 (memory). 50 of 72 encodings |
| C established by 1974 | unsupported from 1974 for good; never established (proved) | unsupported; established in 1977 only | no: hangs on memory items (5.3) |
| S refuted by 1974 | contested every year from 1964; never refuted (proved) | never refuted (proved) | yes: no weighting or memory choice refutes S without retiring reports |

- **C, single entry.** Refuted 1962 to 1963, with no data; best year 1977, at 0.750. Dual entry:
  established in 1977 only; Maloff 1978 ends it (proved).

### 5.2 Year table

| year | C single | S single | C dual | S dual |
|---|---|---|---|---|
| 1963 | 0.000 / 0.866 refuted | 0.866 / 0.000 established | | |
| 1965 | 0.486 / 0.351 contested | 0.520 / 0.400 contested | 0.533 / 0.288 contested | 0.481 / 0.444 contested |
| 1974 | 0.702 / 0.243 unsupported | 0.505 / 0.426 contested | 0.767 / 0.173 unsupported | 0.378 / 0.571 contested |
| 1977 | 0.750 / 0.207 unsupported | 0.490 / 0.451 contested | 0.819 / 0.133 established | 0.349 / 0.609 contested |
| 1978 | 0.719 / 0.239 unsupported | 0.535 / 0.401 contested | 0.782 / 0.172 unsupported | 0.371 / 0.584 contested |
| 2020 | 0.735 / 0.225 unsupported | 0.523 / 0.415 contested | 0.796 / 0.161 unsupported | 0.365 / 0.591 contested |

Cells are b / d. On its own evidence C is established from 1973 (1974: 13/16); S's own belief is 5/7
in 1974 and 0.739 today.

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

So exit claim 2 is decided by two 1966 Nature letters whose direction is from memory. S is never
refuted in any row.

**Tried (E1, not settled).** No abstracts; Nature is paywalled; no citing abstract gives either
direction. Mitchell & Moyle 1967 (PMID 4291593) cites Tager et al. 1966 first: probably a reply.
Three citing papers are free scans in PMC: Mitchell & Moyle 1967 Biochem J (c08), Hopfer 1968 (c10),
van Dam & Slater 1967 (PMID 4170459). No text layer was readable here; a person can read them.

### 5.4 Williams as a third rival

- **Single entry.** W is refuted in 1962, 1963, 1965 and 1967 to 1981, with no data of its own.
  Chemiosmosis is contested 1982 to 2025 (2020: C 0.682 / 0.281, W 0.387 / 0.557).
- **Dual entry, or all weights x2.** C established in 1977 only.
- **The Rivalry accepts W, though W's mediator refines C's** (CH-40): by the core's refinement
  axiom, hydron in the inner membrane is_a hydron (0.999).
- **Fixes.** J removes the false contest; I2 the refutation with no data; H neither.

### 5.5 Weights by a factor of 2

On the pseudo-count: experiments 1/2 to 2/3 or 1/3; reviews 3/5 to 3/4 or 3/7. Every cell pinned.

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
- The knife edge is chronic. Single entry: within 0.02 of a threshold in 47 years (1978 to 2019 at
  0.010). Dual entry: 54 years; 2020 is 0.004 under 4/5.

### 5.7 What it takes to pass (CH-28)

The grid: 2 entry rules x 2 review rules x 3 retirement sets x 3 weightings x 2 memory rules = 72
encodings. The exit passes in 8. All 8 retire all 7 reports by 1974 (5 of them by
judgement) and drop the 6 memory items. Of the 72, 1965 contested holds in 50, 1974 C established in
35, and 1974 S refuted in 18: none without retirement, 2 with only the phosphohistidine pair, 16
with all 7.

### 5.8 Forgetting (option N)

Each item's pseudo-count halves every h years; with no decay it equals the core (pinned).

- h = 5, 10, 20: single entry never establishes C; S is never refuted in either entry.
- Dual entry establishes C only in 1976 to 1977 (h = 5, 10) or 1977 and 1986 (h = 20).
- 2020, h = 10: both unsupported (C 0.621 / 0.106, S 0.083 / 0.619). C's last supporting experiment
  is from 1977, so forgetting erases the winner too.

### 5.9 Option E: the right grain

The four phosphohistidine items move from S to "via phospho-L-histidine", lifted to S by
`Opinion.weakest` against a definitional is_a: belief passes up, disbelief does not.

| year, encoding | C under the rivalry | S under the rivalry | S's own belief |
|---|---|---|---|
| 1963, single | 0.000 / 0.866 refuted (as today) | 0.866 / 0.000 established | 0.866 |
| 1965, single | 0.327 / 0.563 contested | 0.563 / 0.327 contested | |
| 1974, single | 0.586 / 0.368 contested | 0.536 / 0.376 contested | 0.860 (today 5/7) |
| 1974, dual | 0.763 / 0.177 unsupported | 0.373 / 0.565 contested | |

- 1974: the instance claim is 2 for, 2 against; its 0.400 belief lifts, its disbelief does not.
- Single entry: C contested 1965 to 2025. Dual: established 1977 only, as today. S never refuted.
- Sanity pin: with nothing lifted, E equals the core's rivalry with the four items retired.
- Caveat (review): the example labels C~I "non-phosphorylated"; phosphohistidine is phosphorylated.
  The is_a holds only if S means "some chemical intermediate", as the record reads it.

### 5.10 Dated retirement and canon on both sides (added at review)

| encoding | 1965 C | 1978 C | 1978 S | exit at 1978? |
|---|---|---|---|---|
| canon on both rivals, single (CH-50) | contested | established (0.804) | contested (0.407 / 0.544) | no: S never refuted (proved) |
| dated retirement, single | contested | unsupported (0.795) | unsupported (0.169 / 0.718) | no: S never refuted |
| dated retirement, dual | unsupported | established (0.808) | refuted (0.842) | no: 1965 fails |
| dated retirement, single, no memory items | contested (1/2, 1/4) | established (0.882) | refuted (0.904) | yes (proved) |

- **The dates.** The phosphohistidine pair from 1964; the other five from 1978, by Ernster's
  "Despite intensive efforts in many laboratories, however, no experimental evidence could be
  obtained for these hypotheses". It names none of the five and describes 1961: my reading. D1.
- **No margin.** In the passing row, 1965 disbelief is exactly 1/4, on τ. It also needs E1 to drop,
  not confirm, the memory items. The 1974 exit still fails claim 3 (1974 S unsupported).
- **Canon is not enough.** A 4/5 refutation of S in 1978 leaves S contested: the reports outvote
  it.

### 5.11 Checks and corrections

- **Review re-run.** Lean compiles (exit 0, 33 s). Every script reproduces its file byte for byte.
  From a fresh download every PMID (71), DOI (64), CURIE (34), quote (20) and textbook sentence (3)
  is OK; separate code re-checked 38 PMIDs, 6 DOIs and all CURIEs.
- **Fixed at review.** E's is_a against the C~I label (5.9); "done", not "met".

## 6. Experiments for later

Exit test first, then cost in agent tasks.

| id | exit test | what | cost |
|---|---|---|---|
| E1 | each of the 8 memory directions quoted from a checked source, or dropped; grid, 5.3 and 5.10 rerun; c21, c22 first | the 1966 letters, or the three free PMC scans that cite Tager (5.3) | 1 |
| E2 | every S report has a sourced retirement year or "never"; grid rerun; pass count reported | option D1, outside the core; Ernster 1978 already gives a blanket date (5.10) | 1 to 2 |
| E3 | CH-10, CH-12, CH-28 PASS; no example theorem changes; 1965 stays contested | prototype D2 (`retiredIn` on a copy of `Evidence`) | 1 |
| E4 | CH-19, CH-21, CH-40 PASS; the refinement lint is clean on every rivalry in the repo | J and M together; decide which localised items are child-level | 2 |
| E5 | CH-18 PASS without dual entry; a coarsened rival with no data is not refuted; a `belief_le` analogue proved | option H done properly | 3 to 4 |
| E6 | CH-41 and CH-44 expressible; van der Bend weakens the tests it reproduced, not the Hitchens & Kell 1983 design | an undercutting list outside the core: (attacker, attacked item) pairs | 2 |
| E7 | every verdict printed with its margin; CH-48 flagged | option L, outside the core | 0.5 |
| E8 | a theorem over the full record, one agreed encoding: contested 1965; C established and S refuted by 1978 | restate the M2 exit, after E1, E2, E4. Prototyped: passes without memory items, at zero margin (5.10) | 1 |
| E9 | single entry, h = 10, 1978 speech and 2013 textbook as canon on C: C established every year from 1978; S's belief under 1/4 from 1990 | N plus K: does canon rescue forgetting? | 0.5 |
| E10 | CH-11 PASS: the instance lifts support only while it is established, so 1974 equals D1 `phosphoBoth` (C 0.604 / 0.348) | E with a lift that reads the instance's verdict, not its belief | 0.5 |

## 7. What would change the decision

- If Chance & Mela 1966 or Tager 1966 did not argue against chemiosmosis, dual entry passes exit
  claim 2 in every year from 1974 (5.3). E1 settles this. Claim 3 would still fail.
- If the exit year moved to 1978, canon (K) passes claim 2 with no retirement; claim 3 still fails.
  1974 is itself early: Harold 2001 has a controversy "that lasted for 15 years".
- If Dan accepts a dated retirement list as data (D1), the exit at 1978 passes in single entry with
  these dates, once the memory items go (5.10). No core change, but no margin.
- If W stays a flat rival, chemiosmosis is contested from 1982. Only J, or a hierarchy in H, avoids it.
- If the weights of 5.5 are a fair range, no verdict here is robust: program 10a comes first.

**Roadmap.** M2 exit: met on a curated sample only (ROADMAP marks M2 "done"; not edited here).
M4 canonical kind: K, CH-47, CH-50, E9. M6 fusion and weights: G, N, CH-17, CH-25 to CH-27, with program
10a. M8 literature at scale: needs dated records like this, with direction and retirement.

## 8. Limits

- The mirror checks the arithmetic, not my reading of the core. Lean is the authority.
- Direction comes from the title for 22 of the 39 C and S items: weaker than an abstract.
- "Experiment" lumps designs together at 1/2: a reconstitution weighs the same as a stoichiometry note.
- Chloroplast, bacterial and liposome items sit on a mitochondrial claim with no transfer step (CH-32).
- Putting Rieger 2014, Toth 2020, Lee 2021 and Silverstein 2024 under Williams' rival is my grouping.
- The prototypes are crude and outside the core. E's is_a and the 1978 blanket date are my readings.
- The record is my selection. Verdicts resting on one item (5.3) could move with another.

## 9. References (checked)

Title, first author and year checked on Europe PMC (PMIDs) or Crossref (DOIs), 2026-10-30, and
again from fresh downloads on 2026-10-31. The main ones, titles cut short; all 76 checks in full are
in `data/stress/09/references_checked.tsv`.

| id | first author, year | short title |
|---|---|---|
| PMID 14925142 | Davies RE 1952 | ion transport by nervous tissue |
| PMID 13111237 | Slater EC 1953 | respiratory chain phosphorylation |
| PMID 13771349 | Mitchell P 1961 | chemi-osmotic mechanism |
| PMID 13785509 | Williams RJP 1961 | chains of catalysts |
| PMID 14014715 | Boyer PD 1962 | phosphohistidine intermediate |
| PMID 14463786 | Lehninger AL 1962 | Oxidative phosphorylation |
| PMID 5871845 | Mitchell RA 1964 | phosphohistidine, succinate thiokinase |
| PMID 5332854 | Kreil G 1964 | E. coli succinate thiokinase |
| PMID 4222981 | Mitchell P 1965 | proton translocation stoichiometry |
| PMID 5870319 | Mitchell P 1965 | evidence discriminating the mechanisms |
| PMID 5329743 | Mitchell P 1966 | chemiosmotic coupling (Biol Rev) |
| PMID 22082452 | Mitchell P 2011 | grey book reprint (1966) |
| PMID 5220864 | Jagendorf AT 1966 | acid-base ATP formation |
| PMID 5970146 | Chance B 1966 | proton movements |
| PMID 4381909 | Tager JM 1966 | chemi-osmotic theory |
| PMID 4291593 | Mitchell P 1967 | chemiosmotic hypothesis |
| PMID 16742541 | Mitchell P 1967 | respiration-driven proton translocation |
| PMID 4170459 | van Dam K 1967 | mechanism of uncoupling |
| PMID 4517939 | Oesterhelt D 1973 | new photoreceptor membrane |
| PMID 4517936 | Boyer PD 1973 | new concept for energy coupling |
| PMID 4272126 | Racker E 1974 | purple membrane vesicles |
| PMID 4151654 | Green DE 1974 | electromechanochemical model |
| PMID 15223 | Wikstrom MK 1977 | cytochrome c oxidase proton pump |
| PMID 18361775 | Boyer PD 1977 | joint review |
| PMID 670292 | Maloff BL 1978 | giant mitochondria potentials |
| PMID 708723 | Williams RJP 1978 | multifarious couplings |
| PMID 6293600 | Hitchens GD 1982 | localized coupling, chromatophores |
| PMID 6870853 | Hitchens GD 1983 | uncouplers shuttle between sites |
| PMID 2996506 | Van der Bend RL 1985 | critical appraisal, localized coupling |
| DOI 10.1016/0304-4173(85)90005-9 | Ferguson SJ 1985 | delocalised or localised? |
| PMID 2861851 | Slater EC 1985 | gradient not obligatory |
| PMID 2422160 | Nagle JF 1986 | models of localized coupling |
| PMID 16666959 | Chiang GG 1989 | Ca-gated switching |
| PMID 24476986 | Rieger B 2014 | lateral pH gradient |
| PMID 28882384 | Nath S 2017 | two-ion theory |
| PMID 31622585 | Manoj KM 2019 | chemiosmotic and murburn |
| PMID 32717593 | Silva PJ 2020 | chemiosmotic misunderstandings |
| PMID 8842371 | Prebble J 1996 | successful theory development |
| PMID 11536297 | Harold FM 2001 | gleanings of a chemiosmotic eye |
| PMID 11859886 | Prebble J 2001 | philosophical origins |
| PMID 12068893 | Allchin D 2002 | to err and win a Nobel Prize |
| PMID 23104597 | Prebble JN 2013 | contrasting approaches |
| DOI 10.1207/s15516709cog1104_4 | Pollock JL 1987 | Defeasible Reasoning |
| DOI 10.1007/978-3-319-42337-1 | Jøsang A 2016 | Subjective Logic |

Also: Ernster L, presentation speech, Nobel Prize in Chemistry 1978, read 2026-10-30 and 31 at
https://www.nobelprize.org/prizes/chemistry/1978/ceremony-speech/. OpenStax Concepts of Biology,
how-cells-obtain-energy-m45439-36, -37 and -73. CURIEs, all on OLS4, none obsolete:
`curies_checked.tsv` (34).

## 10. UNVERIFIED

- Directions from memory (8), none with an abstract: Chance & Mela 1966 and Tager 1966 against C;
  Lehninger & Wadkins 1962 for S; Mitchell & Moyle 1965 (PMID 5870319) for C; Slater 1967 against C;
  the 1977 joint review for C; Williams 1978 (PMID 23315) for W; Ferguson 1985 against W.
- Mitchell & Moyle 1967 (PMID 4291593) as a reply to Tager 1966: inferred from its first reference.
- Wikstrom 1977 being at odds with Mitchell's redox-loop scheme (CH-33).
- The X_E reinterpretation of Hind & Jagendorf 1963 (CH-13).
- Which phosphohistidine isomer Boyer reported (CHEBI:18847 or CHEBI:19855); PROTO E uses their
  parent, CHEBI:26048.
- That Science 1979 (PMID 388618) is the printed Nobel lecture.
- Retirement years for the five unrefuted S reports: none found per report. PROTO D1 uses 1974
  (judgement) and 1978 (Ernster's blanket sentence, my reading).
- What the three PMC scans say about Tager 1966: not read.
- Murburn entered as a hypothesis only; its authors' claimed data not checked.
