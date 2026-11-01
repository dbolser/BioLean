# The formal system: what BioLean is, and what it might become

Written 2026-11-01 from commit 16d5e43 plus today's untracked files. The code is the authority.
Programs: [programs/README.md](programs/README.md).

## Summary

- **What I did.** Read the core, the prototypes, the stress files and the program docs. Wrote
  down the core, what is outside it, the decisions and every proposed change.
- **The core today:** 11 kinds, 17 `Claim` constructors, 5 targets, 13 evidence kinds, 18
  `Derivation` rules, 9 opinion operators, `Rivalry`, two coverage measures. No program changed a
  rule or type; program 01's E1 re-ran the is_a import (adds Sulfolobus).
- **58 extensions proposed, none adopted.** All six `BioLean/Proto` and eleven `BioLean/Stress`
  files compile today, with no `sorry`.
- **Same idea, different names:** an end year on `Evidence` (03, 09,
  10a), a multinomial frame (03, 08, 09), a wider `transport` (01b, 08, 10b, 10c).
- **Some clash:** three different unions (05, 08, 10b); GO functions as continuants (04) against
  GO-CAM import (10b); defeat (01b) would be the first non-monotone rule.
- **What matters now:** decide by cluster (4.2), and test every change against section 5.

## Words used here

| word | meaning |
|---|---|
| core | the modules directly in `BioLean/`, with the generated `RO.lean` and `Ontology/IsA.lean` |
| constructor, rule, operator, type | a new `Claim` shape; a new `Derivation` step; a new function on opinions; a new type or field |
| monotone | adding a statement never removes a derivation |
| closed world | "no record says otherwise, so ..." |
| prototype | a candidate core change, kept outside the core |

## 1. The system in one page

### 1.1 Things and context

- **Kind** (11): chemical, protein, gene, process, function, phenotype, disease, anatomy, cellType,
  component, taxon. Process and function are occurrents, the rest continuants (`Kind.sort`).
- **Entity k**: a CURIE and a label. **Rel**: an RO, BFO or rdfs id plus an inverse flag.
  `Rel.accepts` checks only the BFO sort against RO's domain and range.
- **Data**: RO has 642 relations, 164 chains (126 on, 38 blocked), 124 inverses, 45 transitive. The
  is_a closure of used terms has 3,588 terms and 4,897 edges (pinned in `Tests/`).
- **Context is refinement.** `Entity.refine e r f` is e ⊓ ∃r.f, same kind, curie `e&r=(f)`.
  `Entity.inCtx` applies a `Ctx` in a fixed order, so one context gives one curie.
- **Ctx** (7 fields): anatomy, cellType, component, stage (GO process), lifeStage (UBERON),
  condition (organism state on the taxon, or environment on the subject), taxon (outermost).
- Dose, duration, strain and system are protocol, on `Evidence`.

### 1.2 Claims (`Claim.lean`)

| constructor | says |
|---|---|
| `effect a s t` | a has a signed (+ or −) effect on t |
| `mediatedBy a s t m` | that effect runs via m |
| `noEffect a t` | a measured null |
| `rel r a b` | a r b; kinds checked at construction |
| `notRel r a b` | not (a r b) |
| `count w p n` | every w has exactly n p |
| `atLeast w p n` | at least n |
| `countBetween w p lo hi` | lo to hi |
| `cardinality c n` | class c has n kinds of member |
| `measure x q lo hi u` | quality q of every x in [lo, hi], unit u |
| `atLeastMeasure x q lo u` | at least lo |
| `less a b q` | every a is below every b in q |
| `produces p m n` | one run of p makes n m |
| `consumes p m n` | uses n |
| `yield p m n` | nets n |
| `homeostasis r held` | r holds held near a set point; no sign, no arms, no check |
| `quant q c` | some c, or most c |

**Target** (5): `activity` (protein or GO function), `amount` (any kind: a hole, program 06),
`process`, `phenotype`, `site`.

### 1.3 Evidence and statements (`Evidence.lean`)

`Evidence`: pmid, year, kind, polarity, note, and protocol fields. `Statement`: id, text, claim,
evidence. Its opinion fuses one item per PMID (PMID 0, non-paper evidence, is never merged).
`asOf year` keeps items published by then.
Weights sit in a swappable `EvidenceModel`; pseudo-count n = 2r / (1 − r):

| kind | r | n | kind | r | n |
|---|---|---:|---|---|---:|
| metaAnalysis, ontologyAxiom | 9/10 | 18 | mechanistic | 7/10 | 4.67 |
| rct | 17/20 | 11.33 | review | 3/5 | 3 |
| curatedDb, textbook | 4/5 | 8 | observational, inVitro | 1/2 | 2 |
| definitional | 999/1000 | 1998 | textMined, crossSpecies | 3/10 | 0.86 |
| | | | hypothesis | 0 | 0 |

### 1.4 Opinions (`Belief.lean`)

Belief b, disbelief d, uncertainty u over ℚ; b + d + u = 1; b, d ≥ 0; u > 0.

| operator | does | used in |
|---|---|---|
| `vacuous` | (0, 0, 1), unit of `fuse` | fold start; items before their year |
| `ofReliability` | one item: r into b or d | `Evidence.opinion`, `against` |
| `fuse` | cumulative fusion: pseudo-counts add | statements, `both`, `generalize`, `Rivalry`, `clash` |
| `chain` | b multiplies, d = 0 | `viaActivity`, `viaAmount`, `transport` |
| `weakest` | b = min, d = 0 | every logical rule |
| `discount w` | b, d times w | `generalize` (w = coverage) |
| `negate` | swaps b and d | `clash` |
| `against` | (0, b, 1 − b) from a rival | `Rivalry` |
| `prob a` | b + a·u, base rate a | no verdict reads it |

### 1.5 Derivation rules (`Derivation.lean`)

| rule | premises ⊢ conclusion | opinion | note |
|---|---|---|---|
| `lit` | Statement ⊢ its claim | fused evidence | the axiom |
| `viaActivity` | a →s₁ activity(b); b →s₂ t ⊢ a →s₁·s₂ t | chain | mechanism, not magnitude |
| `viaAmount` | a →s₁ amount(m); m →s₂ t ⊢ a →s₁·s₂ t | chain | runs through loops (02b) |
| `both` | two derivations of c ⊢ c | fuse | assumes independence |
| `relChain` | a r₁ b; b r₂ c ⊢ a r₃ c if `RO.chainOK` | weakest | chains, transitivity, is_a laws |
| `notRelSub` | a is_a b; ¬(b r c) ⊢ ¬(a r c) | weakest | sound |
| `notRelObj` | ¬(a r c); b is_a c ⊢ ¬(a r b) | weakest | sound |
| `sequencesOver` | k symbols, length n ⊢ kⁿ kinds | weakest | side goals by `decide` |
| `pigeonhole` | a items, one of b < a holes each ⊢ some hole has ≥ 2 | weakest | |
| `perSet` | n parts, s sets ⊢ n/s per set | weakest | assumes equal sets |
| `fusionAdds` | inputs with a, b parts ⊢ output has a + b | weakest | |
| `netYield` | makes a, uses b ⊢ nets a − b | weakest | |
| `compareIntervals` | disjoint intervals ⊢ a < b | weakest | units are strings |
| `weaken` | c ⊢ some c, most c | unchanged | assumes a non-empty class; not checked |
| `refineMono` | f is_a g ⊢ e⊓∃r.f is_a e⊓∃r.g | unchanged | sound |
| `isaInheritEffect` | a is_a b; b →s t ⊢ a →s t | weakest | sound; universals narrow for free |
| `transport` | effect in taxon T₁; `.crossSpecies` item ⊢ same in sibling T₂ | chain with item | effects only; item in `axioms` |
| `generalize` | p in distinct taxa, each is_a T ⊢ p in T | fuse, discount by coverage | induction |

No inversion rule: claims are class-level existentials. `clash` is a computation, not a rule.

### 1.6 Rivalry, coverage, verdicts

- **Rivalry**: two or more statements, at most one true. Each rival's own opinion is fused with
  `against` every other rival's own belief, once.
- **Coverage**: `bracketing` (default) is the share of T's children holding a sample (every NCBI
  child at the 8 target clades, imported children below), recursing when only one is hit;
  `cladeFraction` counts known leaves.
- **Verdict**: contested if b ≥ τ and d ≥ τ; else established if b ≥ θ; refuted if d ≥ θ; else
  unsupported. θ = 4/5, τ = 1/4. For one statement, established exactly when S ≥ 4R + 8, with S
  and R the pseudo-counts for and against (`statement_established_iff`, `Stress/Weights.lean`).

### 1.7 Key theorems

| theorem | says |
|---|---|
| `uncertainty_pos`, `belief_lt_one` | nothing is proved outright |
| `belief_le_fuse_of_supports`, `fuse_belief_le_of_refutes` | support never lowers belief; refutation never raises it |
| `fuse_uncertainty_le_left`, `uncertainty_le_discount` | evidence never adds ignorance; discounting never removes it |
| `chain_belief_le_*`, `weakest_belief_le_*`, `chain_le_weakest` | a step is never stronger than a premise |
| `forall_opinionAt` | an opinion changes only in evidence years |
| `opinion_generalize_le_coverage` | a generalisation never beats its coverage |
| `Rivalry.belief_le` | a rivalry never raises a rival's belief |
| `bracketing_single`, `Measure.eval_mono` | one lineage covers at most 1/#children; more samples never cover less |
| `cellular_above_eukaryota` | the flaw: "all cellular organisms" 32/33, "all eukaryotes" 16/75 |
| `contested_1965`, `settled_1974` | M2 exit; rests on illustrative items and double entry (03, 09) |

## 2. Outside the core

| piece | where | kernel-checked? |
|---|---|---|
| annotation rounds | `data/textbook/claims*` | no |
| emitters: R2 1,591 of 1,594 compile; R3 480 compile, 1 rejected (`r3_skip.tsv`) | `scripts/textbook/emit_lean*.py` | the output compiles |
| corrections (70 contexts, 9 false universals) | `promote_context_to_m3.py`, `apply_false_as_written.py` | the output compiles |
| ontology and RO import | `scripts/ontology/import_isa.py`, `scripts/ro/import_ro.py` | output is core data |
| closure search: the core's rules in Python, guard flags, IC cut 2.5 (from `scripts/ontology/ic.py`) | `scripts/search/closure.py` | 60 derivations (`Examples/Closure.lean`) |
| hole search: one missing premise per sentence | `scripts/search/holes.py` | no |
| lints: `taxonConsistent`, `Review.sigLint`, amount, obsolete, GO taxon | core, `Stress/AnnotationErrors.lean`, programs 04, 06 | flag only |
| stress sets | `BioLean/Stress/`, `data/stress/NN/cases.tsv` | yes |
| prototypes | `BioLean/Proto/`, `BioLean.Proto.*` in Stress files | yes, alone |

## 3. Decisions

### 3.1 Decided

| decision | date | recorded in |
|---|---|---|
| Lean for shape, subjective logic for strength, exact ℚ | 2026-10-23 | `docs/design.md` |
| structure as `Claim.rel`, typed by RO; RO chains as data, 38 blocked | 2026-10-27 | CHANGELOG (M1); `docs/m1-checks.md` |
| logical steps use `weakest` | 2026-10-27 | CHANGELOG (M1 checks) |
| no `relInv`; is_a laws never on is_a | 2026-10-28 | CHANGELOG (closure search) |
| context as refinement; protocol on `Evidence` | 2026-10-28 | `docs/m2/judgement.md` |
| `isaInheritEffect` | 2026-10-28 | STATUS |
| IC for triviality, threshold open (Dan) | 2026-10-28 | CHANGELOG (M3) |
| a loop is a claim, `Claim.homeostasis`; no dynamics (Dan) | 2026-10-29 | STATUS; commit 777e10c |
| bracketing kept for now, flaw stated; Dan: "not decided", research it (decision 1, 3.2) | 2026-10-29 | `plan-2026-10-28-overnight.md` §6; STATUS |

### 3.2 Deferred to a program

| decision | program | the program advises |
|---|---|---|
| 1 instances to universals | [01](programs/01-universals-and-descent.md), [01b](programs/01b-descent-sketch.md) | fix weights and check loss records before any Lean prototype |
| 2 loops, follow-up | [02b](programs/02b-feedback-loops.md) | decide a loop sign plus regulators, or fix the docstring |
| 3 rivals | [03](programs/03-rivals-and-hypotheses.md) | five curation rules; decide the withdrawal year |
| 4 annotation errors | [04](programs/04-annotation-errors.md) | finer signatures, lint or core; obsolete and GO lints |
| 5 grade terms | [05](programs/05-grade-terms.md) | data only: GO's union class |
| 6 opposes | [06](programs/06-opposition.md) | no constructor; amount lint |
| 7 IC threshold | [07](programs/07-triviality-threshold.md) | keep 2.5; Dan rates the sheet |
| 8 or, about, context | [08](programs/08-schema-gaps.md) | E1 to E3 first; then intervals, `unionSubj`, `transport2` |
| 9 illustrative items | [09](programs/09-chemiosmosis-real-record.md) | read the 1966 letters; retirement list as data |
| 10 weights, literature, induction | [10a](programs/10a-evidence-weights.md), [10b](programs/10b-literature-at-scale.md), [10c](programs/10c-rule-induction.md) | drop retracted papers at import; importer M1; choose `Rule` (C) or learners outside (F) |

Open with no program: `Target.disease`.

### 3.3 The veto list (reversible defaults, 2026-10-28)

From `docs/plan-2026-10-28-overnight.md` §3 to §6; all still hold unless marked.

| default | tested by |
|---|---|
| bracketing over NCBI children | 01, 01b |
| IC cut 2.5 | 07: keep, not robust |
| import only the ancestor closure of used terms | none |
| Entity keeps its release, Statement its year | 03, 09, 10a: all want an end year |
| rival belief becomes disbelief; hypothesis weighs 0 | 03, 09 |
| illustrative chemiosmosis items; experiments on both rivals | 03, 09: the M2 exit rests on both |
| no `opposes` relation | 06: keep |
| prokaryote = Bacteria | 05: add the union class |
| weakenings with a blocker emitted; refinement edges in the closure | edges: 02b (L02, N04 chain through one), 07 (restatements by refinement); weakenings: none |
| "either/or" weakenings refused; "about" stored as exact | 08: 20 of 22 "about" numbers wrong |
| centrosome kept as the demonstration | fixed 2026-10-29 (program 01, E0) |

## 4. Candidate extensions

### 4.1 One row each

Every row is proposed, not adopted. Advice is the program's own. P/ is `BioLean/Proto/`, S/ is
`BioLean/Stress/`. X54 to X58 were added when this table was checked against the program docs.

| id | prog | extension | core change | prototype | stress set showed | advice |
|---|---|---|---|---|---|---|
| X1 | 01 | cap: no clade above a lineage inside it | changed definition | none | 0 for every sample (base case) | later |
| X2 | 01, 01b | bracket rule; "the ancestor of T had X" | rule, constructor | Python | silent on every true universal | later |
| X3 | 01b | descent default, defeated by a loss record | rule (non-monotone), type | Python | 26 of 33 (25 fairly) with defeat, 11 with fusion | later |
| X4 | 01b | `conj`, an AND keeping disbelief | operator | Python | carries loss records | later |
| X5 | 01b | `transport` for `rel` claims | rule widened | none | not run; ≤ 3/10 by arithmetic, so always silent | no |
| X6 | 01 | universal with named exceptions | field, rule | none | never wrong, silent on 21 of 33 | later |
| X7 | 02b | sign and regulators on `homeostasis` | constructor | P/Feedback | positive loops stateable | decide |
| X8 | 02b | `closeT`: a loop from two arms | rule | P/Feedback | concludes a loop, never homeostasis | later |
| X9 | 02b | `shiftsSetPoint` | constructor | P/Feedback | fever and heat stroke differ | later |
| X10 | 02b | block revisits in chains | two rules changed | P/Feedback | blocks true positive loops | rejected |
| X11 | 02b | `Derivation` indexed by asserted loops | type (non-monotone) | none | only way to keep the docstring | later |
| X12 | 03 | withdrawal year on `Evidence` | field | S/Rivals (emulated) | 26 PASS, 0 FAIL single entry | decide |
| X13 | 03 | finding key; ignore shared items | field; changed definition | P/Multinomial | 1 case in 41; worse | no |
| X14 | 03 | base rate 1/k, closed flag on `Rivalry` | field | P/Multinomial | S07 stateable | later |
| X15 | 03, 08, 09 | multinomial frame over rivals | type, operator | P/Multinomial, P/SchemaGaps | plain statements do as well | no |
| X16 | 03 | "one of these" claim, survivor rule | constructor, rule | none | not run | later |
| X17 | 03, 09, 10a | averaging fusion, source key | operator, field | S/Weights | loses fair cases | no |
| X18 | 04 | `Kind.role`; signature table in `Rel.accepts` | constructor, changed definition | lint `Review.sigLint` | 23 more errors caught; 25 statements stop compiling | decide |
| X19 | 04 | RO domain and range inherited | core data | Python | 3 more catches | decide |
| X20 | 04 | GO functions as BFO functions | changes `Kind.sort` | none | X19 forces this choice | decide |
| X21 | 05 | `TaxonExpr` (clade, union, minus), `Grade` | type | P/TaxonUnion | minus calls a sponge a protist | later |
| X22 | 05 | `mem`, `unionIntro`, `generalizeG`, `refineIntro`, union coverage | rules, measure | P/TaxonUnion | coverages disagree: 1, 0, 1/4 | later |
| X23 | 05 | `countSub`: counts narrow | rule | P/TaxonUnion | wrong for V. cholerae | later |
| X24 | 06 | `opposes a b`, `symm`, `flip` | constructor, rules | P/Opposes | right 15, wrong 20 | no |
| X25 | 06 | `opposesAt a b t`, `flipAt` | constructor, rules | P/Opposes | circular | no |
| X26 | 06 | `Target.effectOf` | constructor | P/Opposes | context already says it | later (06 E6) |
| X27 | 06 | `Target.amount` for substances only | type change | lint, S/Opposition | keeps all 75 amounts | lint now |
| X28 | 07 | IC discount in `opinionWith` | changed definition | none | mixes sure with interesting | no |
| X29 | 08 | `Claim.or`, four rules, `andS`, `orS` | constructor, rules, operators, type | P/SchemaGaps | or-elim refused inside `Derivation` | later |
| X30 | 08 | union entity A ⊔ B; `unionSubj` | none; rule | P/SchemaGaps | 7 of 14 "or"s; all 3 FAILs fixed | decide |
| X31 | 08 | `about`, `fewer`, 3 types, 9 interval rules | constructors, types, rules | P/SchemaGaps | 9 of 11 FAILs stopped | decide later |
| X32 | 08 | `approx` flag; all-interval; extra `Ctx` slot; swap rules | field; rules | none | not run | no |
| X33 | 08 | `transport2` | rule | P/SchemaGaps | the one context case needing a rule | decide |
| X34 | 09 | mediator lift; `Rivalry` of derivations | rule, type | S/ChemiosmosisReal | 1974 worse | later (09 E10) |
| X35 | 09 | neutral polarity; proofs on `Rivalry` | constructor, types | S/ChemiosmosisReal | no verdict moves | no |
| X36 | 09 | rival in scope from its first data | changed definition | S/ChemiosmosisReal | fixes 3 cases, breaks 1 | later |
| X37 | 09 | `EvidenceKind.canonical` | constructor | S/ChemiosmosisReal | established from 1977 | later |
| X38 | 09, 10a | half-life on evidence | operator | S/Weights | facts decay; two theorems break | no |
| X39 | 10a | ECO and design terms | fields or type | none | ECO lacks trial designs | later |
| X40 | 10a | GRADE-like certainty | field | S/Weights | loses smoking and lung cancer | no |
| X41 | 10a | pools, precision, participants, ceilings | fields | S/Weights | ceilings lose fair cases | later |
| X42 | 10a | base rate read by the verdict | field, changed verdict | S/Weights | 24 FAIL, worst | no |
| X43 | 10a | claim "mouse models c well" | constructor | none | not run | later |
| X44 | 10b | `enablesInherit` | rule | S/Literature | flips S09 | later |
| X45 | 10b | `widenProcess` | rule | S/Literature | unsound for − | no |
| X46 | 10b | three more bridge rules: activity to process, `has_output` to amount, two effects to `mediatedBy` | rules | argued | bridges spread errors | later |
| X47 | 10b | `Entity` equal by curie | type change | argued | hides mislabels | later |
| X48 | 10b | sets: "any of", "one of" | type | argued | two kinds of union | later |
| X49 | 10b | GO-CAM model as context | type | argued | a second context system | later |
| X50 | 10b | transport across a condition | rule | argued | the M8 choice | decide |
| X51 | 10c | `Rule` type, `apply` | type, rule | P/Induction | untested gives 0; shape not truth | decide |
| X52 | 10c | invented predicates | constructor | P/Induction | no learner invents the word | later |
| X53 | 10c | learned chain table; transport to classes | rules | none | analogy fails | no |
| X54 | 03 | graded likelihood per item (C) | field, operator | none | not run | later (03 X8) |
| X55 | 03 | Bayesian model comparison (F) | type, operator | none | not run; no uncertainty mass | none given |
| X56 | 03, 09 | argumentation layer: attack edges, undercut (03 G, 09 D3) | types, operator | none | not run | later |
| X57 | 06 | `flip` gated by innervation (i), or discounted for "often" (c′) | rules | none | not run | later (06 E9) |
| X58 | 10a | own reliability for refuting items (M) | field in `EvidenceModel` | S/Weights | loses K02, K05, R05 | no |

### 4.2 Overlaps and conflicts

| cluster | rows | what to know |
|---|---|---|
| end year | X12, 09 `retiredIn`, 10a H2 | one field, three names. Read by `opinion`, not only `asOf`; restate `forall_opinionAt` |
| time | X12, X38 | an end year keeps facts; ageing fades all of them |
| frames | X15, X16, X29 | "one of these" and `Claim.or` are both disjunctions |
| unions | X21, X30, X48, GO `NCBITaxon_Union:0000004` | **conflict**: a taxon-only type, an entity of any kind, plain data. Pick one class union; keep "one of, unknown which" as disjunction |
| independence | X13, X17, 10b `sharedPmids` | finding key and source key solve different problems |
| base rates | X14, X42 | **conflict**: 03 keeps verdicts; 10a changes all |
| wider transport | X5, X33, X50, X53 | one rule (siblings on any `Ctx` field, warrant in `axioms`) could serve all |
| up the object | X34, X44 to X46 | safe for + only |
| non-monotone | X3, X11, X21, X56 | **conflict** with every rule today: closed-world conditions in the core, or only in lints? |
| AND with disbelief | X4, X29 | one new operator, not a change to `chain` or `weakest` |
| kinds | X18, X20 | **conflict**: X20 makes functions continuants, so GO-CAM's "activity occurs_in place" (10b) stops compiling |
| identity, context | X32, X47, X49 | one identity policy, one wider `Ctx` |
| evidence kinds | X37, X39 | ECO should absorb `canonical` |
| learned rules | X51, X53 | evidence, not logic: never `weakest` |

## 5. Invariants any extension must keep

| invariant | held by | at risk from |
|---|---|---|
| uncertainty never reaches 0 | `uncertainty_pos` | new operators: X4, X15, X29, X38; X55 has no u |
| a logical step never beats its weakest premise | `weakest_belief_le_*`, `chain_le_weakest` | X53 (X51 keeps it) |
| steps add no disbelief; disbelief comes from refutations, `clash`, `against` | `chain`, `weakest` set d = 0 | X4, X29, on purpose |
| support never lowers belief; refutation never raises it | `belief_le_fuse_of_supports`, `fuse_belief_le_of_refutes` | X17, X38 |
| a hypothesis adds no belief | `.hypothesis` weighs 0 | raising it (03 E1) |
| specialisation is free through is_a | `refineAxiom`; is_a laws | X23; false universals spread this way |
| widening is never free | `opinion_generalize_le_coverage`, `Taxa.siblings`, items in `axioms` | X5, X22, X33, X50, X53; X45 widens free |
| no silent fusion across contexts | context in the subject curie | X47, X49 |
| a rivalry decides losers, not winners | `Rivalry.belief_le` | X16 (outside `Rivalry`) |
| every conclusion lists what it rests on | `Derivation.axioms` | X3, X12, X51 must list theirs |
| relations typed at construction | `Rel.accepts` | X18 to X20 tighten it |
| class-level existentials; no inversion | `RO.chainOK`, no `relInv` | X44 to X46 |
| monotone | every rule is a positive constructor | X3, X11, X21, X56 |
| opinions change only in evidence years | `forall_opinionAt` | X12 restates; X38 breaks |
| laws hold for any weights | `[EvidenceModel]` on every law | X41 |
| prototypes stay outside the core | no core import of Proto or Stress | all |

**Wanted, not held.** Coherence (a broad claim never above a narrower one it implies) fails:
`cellular_above_eukaryota`. The `homeostasis` docstring's promise fails: the core proves
"glucose lowers blood glucose" (02b).
