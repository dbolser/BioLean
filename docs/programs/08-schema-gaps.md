# Program 08: disjunction, "about" counts, a second context slot

Written 2026-10-31 (started 2026-10-30, interrupted, finished today). Reviewed and corrected the same
day by an independent agent (changes listed in section 7). Decision 8. This is a program of work, not
a decision. Nothing in the core changed. Dan decides at the points in section 6.

Files: `BioLean/Stress/SchemaGaps.lean` (today's core, 50 cases, about 10 s),
`BioLean/Proto/SchemaGaps.lean` (prototypes of every core option, the same cases, about 16 s),
`data/stress/08/` (tables), `scripts/stress/gaps_*.py` (survey, lookups, table writer, checks).

## Summary

- **What I did.** Built 50 stress cases: 45 on real OpenStax sentences, 5 synthetic. Ran each in Lean
  against today's core, then against a prototype of each option. Every observed behaviour is pinned
  (`#guard`, `theorem ... := by decide +kernel`, `#check_failure`, `#no_lean`). 126 CURIEs checked
  on OLS4 (one obsolete, already in the library). 23 references checked.
- **Today: 11 PASS, 20 FAIL, 10 SILENT, 9 INEXPRESSIBLE.** 11 FAILs are on approximate numbers.
  Of the 22 single numbers round 3 stores for "about" sentences, 20 are rounded values stored as
  exact. Three FAILs are round 2 keeping one half of an "or" (D03, D06, D13). D13 derives a false
  claim: "premeiotic DNA replication precedes mitosis".
- **"Or": a union entity (A ⊔ B) does most of the work.** It states 7 of the 14 real "or" cases and
  fixes all three FAILs. On the object side it needs no core change; an "or" on the subject needs one
  new rule. One real sentence (D17) needs a claim-level `or`. As prototyped, its or-elimination cannot
  go into the core `Derivation`: Lean refuses it. It would need assumptions threaded through every rule.
- **"About" needs intervals.** Writing the tolerance as data, plus a clash check outside the core,
  stops 7 of the 11 FAILs (6 observed, 1 predicted). An `about` constructor with interval rules stops
  9 (observed) and derives all 4 SILENT cases (rates, unit changes, ratios). That is a real core change.
- **Context: most failures are the emitter putting a state on the wrong bearer.** Nesting fixes them
  today. A canonical list of conditions fixes the three faults of nesting, and it lives outside the
  core; only moving two states to another species needs a new rule. One FAIL survives every option:
  adding "glucose present" to a lactose claim is free by is_a, and wrong (C11).
- **What matters now.** Run the three cheap experiments outside the core first (E1 to E3). Then change
  the core only for what they leave: most likely the interval rules (A-b), plus two single rules,
  `unionSubj` and `transport2`.

## Words used here

| word | meaning here |
|---|---|
| disjunct | one side of an "or" |
| union entity, A ⊔ B | a class whose members are in A or in B (OWL `ObjectUnionOf`) |
| coarsen | replace "A or B" by a common ancestor C of both (ATP or GTP: purine NTP) |
| claim-level or | "claim P or claim Q", two whole claims |
| comultiplication | Jøsang's opinion on "x or y" for independent x and y |
| frame | a set of alternatives that exclude each other (one TCA turn makes ATP, or GTP) |
| `Rivalry` | the core's group of statements of which at most one is true |
| interval | a number written as lowest and highest value, [lo, hi] |
| ±10% reading | "about n" read as [0.9n, 1.1n] |
| last-digit reading | "about n" read as n ± half a unit in the last stated digit ("4.6 million": ± 0.05 million) |
| bearer | the thing a state belongs to (damaged cells, not a damaged organism) |
| slot | a field of `Ctx`: taxon, anatomy, cell type, component, stage, life stage, condition |
| nesting | refining an entity by hand, `(e.refine r f).refine s g`, outside `inCtx` |
| core change | a new Claim constructor, Derivation rule, opinion operator or type in `BioLean/*.lean` |
| outside the core | data, annotation, emitter conventions, library definitions, scripts, lints |
| PASS, FAIL | right conclusion; wrong conclusion |
| SILENT | no conclusion where one is due |
| INEXPRESSIBLE | the case cannot be stated |
| R2, R3 | the second and third rounds of textbook encoding (`BioLean/Lib/TextbookClaimsR2`, `R3`) |
| (obs), (pred) | observed by running Lean; predicted from the code, not run |
| `#no_lean` | a pin in the stress file: fails if R2 or R3 ever gains a statement for that sentence |

## 1. The question

Decision 8 lists three gaps. What the code does today:

**Disjunction.** `Claim` has 17 constructors (`Stress: coreShapes`). None takes two claims.
`Entity` has one builder, `refine`, and no union. Round 3 refused the three "one ATP (or an
equivalent)" records as weakenings (blocker `disjunction`). Round 2 still holds the stronger half,
"TCA has output ATP". The core's `Rivalry` says "at most one of these is true", the opposite half of
an exclusive "or".

**Approximate numbers.** `count`, `atLeast` and `cardinality` take a `Nat`. `measure` takes `lo hi :
ℚ`. Six arithmetic rules (`sequencesOver`, `pigeonhole`, `perSet`, `fusionAdds`, `netYield`,
`compareIntervals`) need exact numbers or disjoint intervals. "About" survives only in the
statement text.

**Context.** `Ctx` has one `condition : Option Condition`. An organism state refines the taxon
filler; an environment refines the subject (`Context.lean`). Two conditions fit only by nesting by
hand. `transport` needs a known taxon, so it refuses a taxon refined by a state.

Three sub-questions follow. Which "or"s need a claim-level `or`, and which only a union class? Which
arithmetic rules survive approximation? Does nested `Entity.refine` already handle two conditions?

## 2. The options

### Disjunction

| | idea | core change? | needs | right | wrong |
|---|---|---|---|---|---|
| D-a | split the "or" by taxon or condition, or coarsen it to a common ancestor, at annotation | no (data) | emitter rules | R3 already does it (cytokinesis by taxon) | loses exhaustive "or"s; needs a named ancestor; wrong for a hedge (D17) |
| D-b | `Claim.or p q`; rules or-intro left and right, or-both, or-elim (case analysis); opinion by comultiplication | yes: 1 constructor, 4 rules, 2 operators, and assumptions in `Derivation` | or-elim needs reasoning under an assumption. Written as in the prototype (Lean functions on derivations), Lean refuses it inside `Derivation` (non-positive occurrence, `orelim_positivity.txt`). So `Derivation` would need an assumption context, which touches every rule | any "or"; hedges (D17); opinions on disjunctions | heavy; an "or" cannot feed a core rule; independence assumed |
| D-c | union entity `A ⊔ B` inside an ordinary claim; statements "A is_a A ⊔ B" and "A ⊔ B is_a C when both are" | object side: no (definitions like `Entity.refine`; today's rules use them unchanged). Subject side: 1 new rule (`unionSubj`) | the imported closure for the common ancestor | the object-side "or"s, which are most of them; the existing is_a laws do the work | two different claims ("dilates or constricts", D17); union taxa are unknown to `Taxa` |
| D-d | exclusive alternatives as one frame; belief of A ∪ B is the sum (coarsening) | yes: a multinomial opinion type and a coarsening operator | overlaps program 03 (`Proto/Multinomial.lean`); the core `Rivalry` already gives "at most one" | one event with exclusive outcomes | needs to know the alternatives exclude each other |

### Approximate numbers

| | idea | core change? | needs | right | wrong |
|---|---|---|---|---|---|
| A-a | write "about n" as an interval at annotation (`measure`, `countBetween`), with a stated convention; a clash lint outside the core | no (data, lint) | a convention: ±10% or last digit | stops spurious exactness; no new type | `produces`, `consumes`, `cardinality` have no interval form; "about" still lost as a flag; rules go silent |
| A-b | `about (shape) (interval, how set)` constructor; interval versions of the rules; a clash check | yes: 2 constructors (`about`, `fewer`), 3 small types (`Approx`, `Tol`, `QShape`), 9 rules | the convention as data | arithmetic survives; conflicts are visible | duplicates the quantity constructors; units are strings |
| A-c | every quantity an interval; exact is lo = hi; rewrite the 6 rules | yes: change 6 rules and 6 constructors | a migration of R3 | one quantity type | "about" is lost unless a flag is added |
| A-d | keep exact numbers; add an `approx` flag on `Statement`; a lint refuses exact rules on flagged premises | small: 1 field, 1 lint | the emitter sets the flag | cheap, honest | refuses instead of computing; no ranges |

A-c and A-d were not prototyped.

### A second context slot

| | idea | core change? | needs | right | wrong |
|---|---|---|---|---|---|
| C-a | emitter convention: put a cell state on the cell-type filler, a subject state on the subject, by nesting | no (emitter) | rules in a copy of `emit_lean_m3.py` | fixes all wrong-bearer cases today | order of nesting makes two classes; `transport` refuses refined taxa |
| C-b | `conds : List Cond`, each with slot (subject, cell type, taxon) and relation (state or surroundings); one canonical order; statement "more conditions is_a fewer" | identity, order, dropping: no (`Ctx2`, `inCtx2`, `dropAxiom` are definitions; today's rules use them). Two-state transport: 1 new rule (`transport2`). Replacing the core `Ctx` would be a type change; no case here needs it | sort by key | one class per set of states; any order; two-state transport | does not stop wrong specialisation (C11) |
| C-c | one extra slot, a state of the subject | small: 1 `Ctx` field | none | damaged cells | a process cannot carry `has_modifier` (BioLean's RO domain table: continuant); only one more slot |
| C-d | rules that swap or drop nested refinements | yes: 2 Derivation rules | none | identity by proof, no type change | proofs get longer; curies still differ |

C-c and C-d were not prototyped.

## 3. The stress set

Full table: `data/stress/08/cases.tsv` (16 columns: id, gap, synthetic, probes, input sentence,
CURIEs, correct, source, encoding today, lost, observed, mark, test, prototype observed, mark under
prototype, results under each option). Written by `scripts/stress/gaps_cases.py` from the `OBS` and
`PROTO` lines the Lean files print. Sentences come from the surveys in `data/stress/08/survey_*.tsv`
(56 "or" rows, 27 "about" rows, 97 context rows) and from the round 3 blockers. The 45 real cases use
48 distinct sentences.

| id | sentence (short; ids in `cases.tsv`) | probes | today | best option |
|---|---|---|---|---|
| D01 | all cells prokaryotic or eukaryotic | exhaustive classification | INEXPRESSIBLE | PASS (D-c) |
| D02 | (guard) enucleate red cell is not prokaryotic | no disjunctive syllogism | PASS | PASS |
| D03 | one ATP (or an equivalent) per TCA turn | one disjunct kept | FAIL | PASS (D-b, D-c) |
| D04 | cleavage furrow (animals) or cell plate (plants) | split by taxon | PASS | PASS |
| D05 | nondisjunction in meiosis I or II | object-side or | INEXPRESSIBLE | PASS (D-c) |
| D06 | ribosomes in cytoplasm, or on PM or ER | one disjunct kept | FAIL | PASS (D-c) |
| D07 | carbohydrates on proteins or lipids | exhaustive object or | INEXPRESSIBLE | PASS (D-c) |
| D08 | vasodilation or vasoconstriction | split by condition | INEXPRESSIBLE | PASS (D-a) |
| D09 | endotherms have fur, fat or feathers | or on subject and object | INEXPRESSIBLE | PASS (D-c) |
| D10 | it either happens or it does not | tautology | PASS | PASS |
| D11 | promote or reduce enzyme activity | unsigned regulation | SILENT | SILENT |
| D12 | drought or not watered, water leaves | or in the antecedent | SILENT | PASS (D-a) |
| D13 | before mitosis or meiosis | one disjunct, inherited | FAIL | PASS (D-c) |
| D14 | SYNTHETIC: evidence for A only | opinion on A or B | INEXPRESSIBLE | PASS (D-b) |
| D15 | SYNTHETIC: two refuted disjuncts | opinion on A or B | INEXPRESSIBLE | PASS (D-b) |
| D16 | SYNTHETIC: ATP or GTP as one frame | exclusive alternatives | INEXPRESSIBLE | PASS (D-d) |
| D17 | genes less involved, or dosage matters less | claim-level or (a hedge) | INEXPRESSIBLE | PASS (D-b) |
| A01 | red cell about 8 µm across | about stored as a point | FAIL | PASS |
| A02 | red cell approximately 8 µm thick | wrong number vs data | FAIL | PASS |
| A03 | trachea about 25 to 30 cm | wrong stated range | FAIL | PASS |
| A04 | E. coli genome 4.6 million bp | rounded, stored exact | FAIL | PASS |
| A05 | per replication fork | exact arithmetic on a rounded count | FAIL | PASS |
| A06 | about 1000 nt per second | rate from count and time | SILENT | PASS |
| A07 | 15 per minute, 900 an hour | unit change | SILENT | PASS |
| A08 | fly about 100,000 neurons, same as lobster | "same number" | FAIL | PASS |
| A09 | human brain about 86 billion neurons | about vs measured spread | FAIL | PASS |
| A10 | fly against human brain | comparing counts | SILENT | PASS |
| A11 | approximately 50 to over 1,000 residues | typical as a minimum | FAIL | FAIL |
| A12 | about 1,000 new neurons a day, mammals | clade value | FAIL | FAIL |
| A13 | about 250 red cells on a pin head | ratio of approximations | SILENT | PASS |
| A14 | control: codon pigeonhole | exact stays exact | PASS | PASS |
| A15 | control: 46 chromosomes in 2 sets | exact division | PASS | PASS |
| A16 | SYNTHETIC: about 100 made, about 90 used | net of approximations | FAIL | PASS |
| A17 | SYNTHETIC: about 22 items, about 20 holes | pigeonhole on approximations | FAIL | PASS |
| A18 | about 1,000 times thicker than a membrane | ratio weakened to order | PASS | PASS |
| C01 | when cells lining a vessel are damaged | state of the subject | FAIL | PASS |
| C02 | G1 in rapidly dividing human cells | state of the cells | FAIL | PASS |
| C03 | fast-dividing cells in culture | two cell states | SILENT | PASS |
| C04 | aged telomerase-deficient mice | two organism states, transport | SILENT | PASS |
| C05 | the same two states, two orders | identity | FAIL | PASS |
| C06 | control: celiac disease | one state | PASS | PASS |
| C07 | control: female mammalian embryos | three slots | PASS | PASS |
| C08 | in a hypotonic solution water enters | surroundings of the cell | FAIL | PASS |
| C09 | hot, dry day, stomata close | two conditions in one term | PASS | PASS |
| C10 | the same, against drought | specialise one condition to two | SILENT | PASS |
| C11 | lactose present, then add glucose | monotone inheritance | FAIL | FAIL |
| C12 | allolactose and the repressor, on glucose | the same move where it is right | PASS | PASS |
| C13 | male tortoiseshell cats | order of nesting | SILENT | PASS |
| C14 | alpha cells release glucagon | source in a location slot | FAIL | FAIL |
| C15 | control: telomerase in adult somatic cells | two core slots | PASS | PASS |

**Is it fair?** Partly. 11 cases PASS today: five controls (A14, A15, C06, C07, C15), two guards
where silence is right (D02, C09), a tautology (D10) and three right encodings (D04, A18, C12). Two
tilts remain. The five synthetic cases (D14 to D16, A16, A17) were built to show what an option adds,
so they all favour one. And the first version had no claim-level "or", although the survey held one
(D17); the review added it.

## 4. Results observed

### Marks (`data/stress/08/marks.tsv`)

| gap | when | PASS | FAIL | SILENT | INEXPRESSIBLE |
|---|---|---:|---:|---:|---:|
| or (17) | today | 3 | 3 | 2 | 9 |
| | best option | 16 | 0 | 1 | 0 |
| about (18) | today | 3 | 11 | 4 | 0 |
| | best option | 16 | 2 | 0 | 0 |
| context (15) | today | 5 | 6 | 4 | 0 |
| | best option | 13 | 2 | 0 | 0 |
| all (50) | today | 11 | 20 | 10 | 9 |
| | best option | 45 | 4 | 1 | 0 |

"Best option" is the best option for each case. Many of those wins need no core change (below).

### Disjunction

- **The three FAILs come from round 2 keeping one disjunct.** D03: "TCA has output ATP" stands at
  0.8. D13: "DNA replication precedes mitotic nuclear division", from which the is_a law derives
  "premeiotic DNA replication precedes mitotic nuclear division", established. GO:0006279 is "The
  replication of DNA that precedes meiotic cell division". D06: "every ribosome is located in the
  cytoplasm". On OLS4 the ER's cytoplasmic side is part of the cytoplasm, but the plasma membrane's
  cytoplasmic side (GO:0009898) is part of the plasma membrane. So the claim is false for ribosomes
  on the bacterial plasma membrane (Rapoport 2007). BioLean cannot see this: its closure is is_a only.
- **Union entities fix all three (obs).** `TCA has output (ATP ⊔ GTP)` is true as stated;
  `unionLub` coarsens it. `precedes (mitotic ⊔ meiotic)` makes the premeiotic case true.
  `located in (cytoplasm ⊔ PM side ⊔ ER side)` is true for every ribosome. D05, D07, D09 become
  stateable. D01 needs the one extra rule (`unionSubj`): "cell is_a (prokaryotic ⊔ eukaryotic)" plus
  the two R2 membrane statements give "every cell has a plasma membrane", established.
- **One real sentence needs a claim-level `or` (D17).** "The genes may be less involved in critical
  pathways, or the differences in dosage may make less of a difference". Two hedged explanations, with
  different predicates: no union states it. Today each half alone would stand at 0.8 (over-strong),
  and a `Rivalry` reads them as exclusive, cutting each to 4/9 (wrong logic). `Claim.or` states it,
  with belief on the "or" and none on either half. It also works for D03 (`orElim`, same 0.8).
- **The cost of `Claim.or` is in the rules.** An "or" claim cannot feed a core rule unless every rule is
  lifted, and or-elimination needs assumptions. Lean refuses the prototype's form of it inside a
  derivation type (`scripts/stress/gaps_positivity.py`).
- **Splitting is often right, and R3 already does it:** D04 by taxon, D08 by condition, D12 (an "or"
  in the antecedent is two claims, both stateable today).
- **D11 is a closure gap, not a schema gap:** GO:0043085 is not in the imported closure, so
  `unionLub` to GO:0050790 is refused (pinned).
- **No option adds a disjunctive syllogism.** D02 stays PASS. The core has no general negation, and
  a class-level "has no nucleus" does not give "is not eukaryotic". Adding one would be the risk.

### Opinions on a disjunction (D14 to D16, obs)

| case | inputs | operator | result |
|---|---|---|---|
| D14 | A at b 0.8; B unknown | comultiplication | b 0.80, d 0, u 0.20 (`orS_vacuous`) |
| D15 | A and B each refuted at d 0.8, independent | comultiplication | b 0, d 0.64: unsupported, not refuted |
| D16 | one TCA turn: ATP mass 0.5, GTP mass 0.4, exclusive | frame coarsening | b 0.90: established |
| D16 | the same marginals, read as independent | comultiplication | b 0.70, d 0.20: unsupported |

Proved for every input: or-introduction never lowers belief (`belief_le_orS`), comultiplication is
symmetric (`orS_comm`). D16 shows the trap: comultiplication assumes independence, and exclusive
alternatives are not independent. The right operator depends on knowing which case holds.

### Approximate numbers

- **Spurious exactness is the rule.** `gaps_about_count.py`: round 3 has 25 records from "about"
  sentences. 23 are quantities; 22 hold one number; only the trachea keeps a range. Two of the 22
  are exact by nature (one chromosome, one origin), so 20 are rounded values stored as exact.
- **Exact rules then fire on them.** `perSet` gives exactly 2,300,000 bp per fork and cannot fire on
  the measured (odd) 4,639,221 (A05). `netYield` gives exactly 10 (A16). `pigeonhole` fires on
  "about 22 against about 20" (A17). Fly and lobster have exactly equal neuron counts (A08).
- **Wrong numbers are never challenged.** With the data entered, A02 and A03 stay established. The
  only reaction is `compareIntervals` deriving "every human red cell is thinner than every human red
  cell" (b 0.6), with no flag.
- **A-a, tolerance as data (obs):** A01, A04 and A09 become right; A05 goes SILENT (`perSet` refuses
  `countBetween`). A02 still derives the absurd `less`; the lint outside the core flags A02 and A03.
  A16 and A17 stay FAIL: `produces`, `consumes` and `cardinality` have no interval form.
- **A-b, interval rules (obs):** clashes are flagged and the textbook value drops from established
  to unsupported (A02: b 0.61, d 0.23; A03: b 0.66, d 0.16). Rates, unit changes and ratios are
  derived and agree with the book (A06 [892, 934] nt/s per fork; A07). A10 derives "a fly has fewer
  neurons than a human brain". A16 gives [-9, 29]; A17 is refused (and fires on about 30 against
  about 20, a control).
- **A13 needs care.** `ratioA` gives [204.5, 305.6]: the number of red cells across a pin head. The
  book says 250 "could fit on the head of a pin"; covering the head would take about 49,000. The rule
  cannot tell a width from an area, because units are strings.
- **The convention matters.** Under ±10%, 139,255 fly brain neurons clash with "around 100,000", and
  700 new neurons a day clash with "about 1,000". Under the last-digit reading neither clashes. A
  source that states its spread (Azevedo's ± 8.1 billion) avoids the choice.
- **Two FAILs survive every option.** A11: "approximately 50" read as every polypeptide's minimum;
  ChEBI defines a polypeptide as ten or more residues. A12: a Mammalia value, with no rule from a
  clade measure to a member. The problem is "typical" and "for mammals", not "about".

**Which arithmetic rules survive approximation**

| rule | with intervals | built here |
|---|---|---|
| `sequencesOver` (k^n) | alphabets and lengths are exact by nature; unchanged | no need |
| `pigeonhole` | yes, if every possible item count exceeds every possible hole count | `pigeonholeA` |
| `perSet` | yes, as scaling, if the number of sets is exact | `perSetA` |
| `fusionAdds` | yes, interval addition | not built (same pattern as `netA`) |
| `netYield` | yes, interval subtraction; the sign may be lost | `netA` |
| `compareIntervals` | yes, unchanged, once "about" is widened to an interval | `compareA` not needed |
| exact equality ("the same number") | no: becomes overlap | `Approx.overlaps` |

### A second context slot

- **Wrong bearers are emitter choices (obs).** C01: the organism is damaged, not the cells. C02:
  the human is rapidly dividing. C08: the solution surrounds the process. C14: glucagon is "located
  in blood and part of an alpha cell" at once. Each right reading is stateable today, by nesting or
  (C14) as an effect on glucagon secretion (GO:0070091) in alpha cells.
- **The core convention itself puts some environments on the wrong bearer.** An environment refines
  the subject. So "E. coli on glucose" cannot be written with `Ctx`: glucose would surround lactose
  (C11) or be a quality of E. coli. C11 and C12 nest it by hand on the taxon filler.
- **Nested refinement handles two conditions, with three faults (obs).** Two orders give two classes
  (C05). The is_a laws drop only the outer refinement, so male tortoiseshell cats inherit the
  tortoiseshell claim in one order only (C13). `transport` refuses a taxon refined by a state, so
  the aged telomerase-deficient result cannot go to rat (C04). The one-state version can (b 0.24).
- **C-b fixes all three (obs).** One curie per set of states, in any order. `dropAxiom` ("more
  conditions is_a fewer") gives the tortoiseshell result for male cats and a drought claim for a hot,
  dry day (b 0.6). It refuses the upward move (heat alone from hot and dry, C09). `transport2` moves
  the two-state mouse result to rat (b 0.21). With zero or one condition `inCtx2` gives the core's
  curie, pinned on six real R3 subjects. Only `transport2` is a new rule.
- **C-c alone is not enough.** A state cannot sit on a process: BioLean's RO table gives
  `has_modifier` a continuant domain (C02). The cells carry the state, so the cell-type filler needs it.
- **C11 is the deepest finding.** "Lactose in E. coli makes lactose catabolism go" plus "E. coli on
  glucose is an E. coli" gives "on glucose, lactose catabolism goes", established. Inada 1996:
  glucose represses beta-galactosidase by inducer exclusion. The same move is right one step
  further down: allolactose still inactivates the repressor on glucose (C12, PASS under every
  option). C10 uses the same move and lands right, but heat alone opens stomata (Urban 2017).
  Refinement is monotone; regulation is not. No option in this program tells C11 from C12.

### What each option fixes (observed unless marked)

| option | core change | cases it moves to PASS |
|---|---|---|
| D-a split or coarsen | none | D08, D12 (split, stateable today); D03 and D13 only if the annotator writes the coarse claim instead of one disjunct (pred) |
| D-c union entity | none on the object side; 1 rule (`unionSubj`) on the subject side | D01 (needs the rule), D03, D05, D06, D07, D09, D13 |
| D-b claim-level or | 1 constructor, 4 rules, 2 operators, assumptions in `Derivation` | D03, D14, D15, D17 |
| D-d frame coarsening | new opinion type | D16 |
| A-a tolerance as data, plus lint | none | A01, A04, A09; A02 and A03 with the lint; A05 to SILENT; A08 (pred) |
| A-b about with interval rules | 2 constructors, 3 types, 9 rules | A01 to A10, A13, A16, A17 |
| C-a emitter nesting | none | C01, C02, C03 (one order), C08, C14 |
| C-b list of conditions | none, except 1 rule (`transport2`) for C04 | C04, C05, C10, C13, plus all C-a cases |

## 5. Experiments for later

Each has its exit test first. Cost in agent tasks (one task is one agent run of an hour or two).

| # | experiment | exit test (written first) | cost |
|---|---|---|---|
| E1 | Classify all 56 "or" survey rows: object-side (union), split by taxon or condition, claim-level, tautology | a TSV with one class per row; decision rule: if claim-level is under 10 percent, D-b is deferred | 1 |
| E2 | Re-emit the 20 rounded "about" quantities of R3 (`about_quantities.tsv`) under both conventions (A-a), into `data/stress/08/` only | no point interval left among them; count of closure facts that change; list of cases where the two conventions disagree | 1 to 2 |
| E3 | A clash lint over every R3 `measure` and `count` pair on one subject, plus the literature numbers in this set | flags A02 and A03; reports its false-positive count on the 54 round 3 measure records (41 `measure` claims in the built Lean) | 1 |
| E4 | Bearer convention for the 33 round 3 records with a condition (22 organism, 11 environment; 29 in the built Lean), in a copied emitter | C01, C02, C08, C11 subjects right; every record still compiles | 1 |
| E5 | Union entity (D-c) in a copied emitter for the "or" rows E1 marks as object-side | D03, D06 and D13 replaced; the closure no longer derives "premeiotic DNA replication precedes mitotic nuclear division" | 2 |
| E6 | `Ctx2` (C-b) as a library module outside the core, only if E4 leaves C04, C05, C13 | `inCtx2` equals `inCtx` on all R3 subjects with at most one condition; `Tests/Context` passes unchanged; `transport2` proposed as a core rule only if real literature needs it | 2 |
| E7 | Interval rules (A-b) as a core change, only if E2 and E3 leave arithmetic FAILs | the 7 Quantity theorems unchanged; A05, A16, A17 behave as in the prototype | 2 |
| E8 | Count closure facts that specialise an effect across an added condition (the C11 and C10 pattern) | a list with each fact marked right or wrong by a source; feeds program 01's defaults | 1 |

## 6. What would change the decision

- **If E1 finds many claim-level "or"s,** D-b moves up. In this set there is one among 14 real
  cases (D17), a hedge between two explanations. D-b's real price is assumptions in `Derivation`.
- **If literature numbers mostly come with a spread** (mean ± SD, ranges), A-b with stated ranges
  needs no convention, and the ±10% against last-digit question goes away.
- **If the clash lint (E3) catches most wrong numbers,** A-a plus the lint may be enough, and A-b waits
  until arithmetic on approximations matters for a real derivation.
- **If E4 fixes all wrong bearers,** C-b is only about identity and transport. Those matter once
  literature with several states per claim (age, genotype, diet) arrives, as in C04.
- **If exclusive frames are common** (one reaction, several outcomes), D-d joins program 03's
  multinomial work instead of being separate.
- **C11 belongs to defaults, not to schema.** If Dan wants it fixed, it goes with program 01's
  defeasible options, not here.

## 7. Limits

- **The marks are mine,** made from the observed line next to each one in `cases.tsv`. The biology
  in "correct" is from the cited source; I did not run experiments.
- **The sentence choice is biased** to what my regular expressions found (`gaps_survey.py`). One
  textbook only.
- **The tolerance conventions are my choice.** Neither ±10% nor last digit is a standard the book
  states.
- **Units are strings.** `scaleA` trusts the factor (× 60 from per minute to per hour), and `ratioA`
  cannot tell a width from an area (A13). A wrong factor would pass.
- **Comultiplication assumes independence** (D16 shows where that is wrong), and `dropAxiom` reads
  every condition as an existential restriction, as `Entity.refineAxiom` does. That reading is why
  C11 is derivable.
- **C-b's canonical order assumes the conditions hold at once.** A sequence (pre-treatment, then
  challenge) is protocol, which BioLean keeps on `Evidence`, not in context.
- **Union taxa are unknown to `Taxa`,** so they get no transport and no coverage (D09).
- **The prototype is not wired into the core.** `XDerivation` embeds core derivations, but core rules
  cannot take an `XClaim`. Parts 2 and 5 (union entities, `Ctx2`) avoid this: they build entities and
  statements that today's `Derivation` already uses.
- **Synthetic cases (D14 to D16, A16, A17) test logic, not biology.** A05's "two forks" and C04's
  two-state statement are mine, built from the cited text. D17's two halves use placeholder (BLN) terms.
- **R1 is checked by grep only.** `#no_lean` pins R2 and R3. The R1 library is not built, so it cannot
  be imported; its sources contain none of the "no Lean" records.
- **Review changes (2026-10-31).** D06 was PASS ("true for all three places"); it is FAIL, and its
  prototype claim was a false universal (every ribosome on a membrane). D12's best-option mark was
  SILENT, against the option table; it is PASS. D17 was added. C11 and C12 wrote glucose as a quality
  of E. coli; they now write it as surroundings. D10 and nine "no Lean" observations had no pin; they
  have one. A03 and A09 under A-a were predicted; they are observed. "24 of the 25" quantities was not
  reproducible; it is now computed by a script. D-c, C-b and A-b core-change labels were corrected.

## 8. Files

| file | what |
|---|---|
| `BioLean/Stress/SchemaGaps.lean` | the 50 cases against today's core, plus option A-a run as data; prints `OBS` lines |
| `BioLean/Proto/SchemaGaps.lean` | `Op.andS`, `Op.orS`, `Frame3`; `unionE`, `unionInL/R`, `unionLub`; `XClaim`, `XDerivation`, `Approx`; `Ctx2`, `inCtx2`, `dropAxiom`, `transport2`; the cases again; prints `PROTO` lines |
| `data/stress/08/cases.tsv` | the full table, one row per case |
| `data/stress/08/marks.tsv` | mark counts per gap, today and under the best option |
| `data/stress/08/lean_output.txt` | the raw `OBS` and `PROTO` lines |
| `data/stress/08/about_quantities.tsv` | how R3 stores the numbers of the "about" sentences |
| `data/stress/08/orelim_positivity.txt` | Lean refusing or-elimination inside a derivation type |
| `data/stress/08/curies_checked.tsv` | 126 CURIEs on OLS4: 108 live, 17 placeholders (BLN), 1 obsolete (CL:0002371) |
| `data/stress/08/references_checked.tsv` | 23 references, title and first author matched |
| `data/stress/08/review_*.tsv` | the independent re-check: references, abstract quotes, CURIEs, quoted phrases in the Lean comments |
| `data/stress/08/survey_*.tsv` | the "or", "about" and context surveys of `data/textbook/claims*` |
| `scripts/stress/gaps_cases.py` | runs both Lean files and writes `cases.tsv`, `marks.tsv` |
| `scripts/stress/gaps_*.py` (others) | survey; about count; positivity check; CURIE checks (OLS4); reference checks (Europe PMC, Crossref, DataCite); review; record viewers |

To rerun: `python3 scripts/stress/gaps_cases.py` from the repo root (about 30 s).

## 9. References (checked)

Checked on Europe PMC (PMID) or Crossref and DataCite (DOI); title, first author and year match
(`references_checked.tsv`, `review_refs.tsv`). Quoted phrases were checked against the abstract
(`review_quotes.tsv`), except Centerwall 1973 and Lyon 1961, which have no abstract: they are used
for their titles only.

| source | id | used for |
|---|---|---|
| Azevedo FA et al. 2009. Equal numbers of neuronal and nonneuronal cells make the human brain an isometrically scaled-up primate brain | PMID 19226510 | A09: 86.1 ± 8.1 billion neurons (adult male) |
| Bandaru SS et al. Poikilocytosis (StatPearls; Europe PMC year 2026) | PMID 32965812 | A01, A02, A18: 6.2 to 8.2 µm across; 2 to 2.5 µm thick at most |
| Blattner FR et al. 1997. The complete genome sequence of Escherichia coli K-12 | PMID 9278503 | A04, A05: 4,639,221 bp |
| Cameron HA et al. 2001. Adult neurogenesis produces a large pool of new granule cells in the dentate gyrus | PMID 11406822 | A12: 9,000 new cells a day, young adult rats |
| Centerwall WR et al. 1973. Male tortoiseshell and calico (T-C) cats | PMID 4798734 | C13 (title only) |
| Charkoudian N. 2003. Skin blood flow in adult human thermoregulation | PMID 12744548 | D08: cutaneous vasodilation in heat |
| Dorkenwald S et al. 2024. Neuronal wiring diagram of an adult brain | PMID 39358518 | A08: 139,255 neurons |
| Hattori M et al. 2000. The DNA sequence of human chromosome 21 | PMID 10830953 | D17: smallest autosome; 127 known and 98 predicted genes on 21q |
| Inada T et al. 1996. Mechanism responsible for glucose-lactose diauxie in Escherichia coli | PMID 9133663 | C11, C12: inducer exclusion |
| Jaskelioff M et al. 2011. Telomerase reactivation reverses tissue degeneration in aged telomerase-deficient mice | PMID 21113150 | C04 |
| Jøsang A et al. 2005. Multiplication and comultiplication of beliefs | doi:10.1016/j.ijar.2004.03.003 | D14, D15: origin of the operators |
| Jøsang A. 2006. Belief Calculus (arXiv) | doi:10.48550/arXiv.cs/0606029 | Eq. 35, 37 (product masses), Eq. 17 (coarsening), read on ar5iv |
| Kim NW et al. 1994. Specific association of human telomerase activity with immortal cells and cancer | PMID 7605428 | C15: none of 50 normal somatic tissues positive |
| Kumari S et al. 2019. Clinical implications of vocal cord-carina distance and tracheal length in the Indian population | PMID 31828242 | A03: 10.14 ± 2.04 and 9.37 ± 1.28 cm |
| Lambeth DO et al. 2004. Expression of two succinyl-CoA synthetases with different nucleotide specificities in mammalian tissues | PMID 15234968 | D03 |
| Liu H et al. 2022. Signaling transduction of ABA, ROS, and Ca2+ in plant stomatal closure in response to drought | PMID 36499153 | C10 |
| Lyon MF. 1961. Gene action in the X-chromosome of the mouse (Mus musculus L.) | PMID 13764598 | C07 (title only) |
| Mackman N et al. 2007. Role of the extrinsic pathway of blood coagulation in hemostasis and thrombosis | PMID 17556654 | C01: tissue factor on endothelial cells under pathological conditions |
| Morrison SF et al. 2019. Central mechanisms for thermoregulation | PMID 30256726 | D08: vasoconstriction and shivering |
| Rapoport TA. 2007. Protein translocation across the eukaryotic endoplasmic reticulum and bacterial plasma membranes | PMID 18046402 | D06 |
| Sorrells SF et al. 2018. Human hippocampal neurogenesis drops sharply in children to undetectable levels in adults | PMID 29513649 | A12 |
| Spalding KL et al. 2013. Dynamics of hippocampal neurogenesis in adult humans | PMID 23746839 | A12: 700 new neurons per hippocampus per day |
| Urban J et al. 2017. Increase in leaf temperature opens stomata and decouples net photosynthesis from stomatal conductance | PMID 28338959 | C09, C10 |

Ontology definitions used as sources (OLS4, `curies_checked.tsv`): GO:0006279, GO:0005737, GO:0009898,
GO:0032154, GO:0009504, GO:0043085, GO:0043086 (and their parents), CL:0000171, CL:0000595,
CHEBI:15841. The is_a path GO:0006279 to GO:0006260 (through GO:0033260) and the part_of ancestors of
GO:0009898 and GO:0098554 were read from OLS4 on 2026-10-31.

## 10. UNVERIFIED

- That Jøsang and McAnally 2005 define the same simple operators as the 2006 arXiv paper: only the 2006
  paper's equations were read (the 2006 paper attributes them to the 2005 one).
- Cooper and Helmstetter 1968 (PMID 4866337, title checked) has no abstract on Europe PMC, so its
  replication time is not used.
- Whether the full adult fly nervous system (brain plus ventral nerve cord) is above 150,000 neurons:
  only the brain count (139,255) was checked, so A08's verdict under the last-digit reading is open.
- The lobster half of A08 ("the same number as a lobster"): no lobster neuron count was checked.
- Endotherm insulation (D09): that every endotherm has hair, fat or feathers was not checked against a
  source.
- D17's two explanations (pathway involvement, dosage sensitivity) were not checked against the
  literature; only the size of chromosome 21 was.
- That ribosomes bound to the bacterial plasma membrane fall under GO:0009898 rather than the cytoplasm
  is read from GO's definitions (D06); no GO annotation of a ribosome to GO:0009898 was looked up.
