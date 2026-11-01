# Program 10c: rule induction

Written 2026-11-01; reviewed and corrected the same day (section 10). Decision 10, part 3 of 3. A program
of work, not a decision. Nothing in the core changed. Dan decides at the points in section 8.

## Summary

- **What I did.** 37 induction tasks from the compiled textbook: hide true statements, ask for them
  and for checked false ones. Ran today's core (Lean and the closure search) and three learners (a
  small miner, AMIE 3.0, Popper 5.0). Judged 64 learned rules and samples of predictions. Prototyped
  a learned rule as a derivation rule in Lean.
- **Today's BioLean: 18 PASS, 2 FAIL, 16 SILENT, 1 INEXPRESSIBLE.** Right whenever deduction is
  enough, and on the one induction rule it already has (`generalize` over taxa, I37). Silent wherever
  a class or path rule is needed. Caution: a system that concludes nothing gets 10 of those PASSes.
- **Both FAILs are annotation, not induction.** A sentence annotated for every X, plus the free
  refinement step: "the bacterial chromosome is in a nucleus" (I25), "the bacterial cell wall has
  cellulose" (I10, round-2 library). 68 round-2 Lean statements dropped a context their annotation had.
- **Learners find little, and most of it is wrong.** At PCA 0.5, AMIE recalls 4.9 percent of held-out
  facts; the closure 2.8. Judged precision of new predictions: 0.17 (miner), 0.23 (AMIE); 0.20 and
  0.30 if truths only in the book's scope count. Of 64 rules: 13 true, 16 true in the book's scope
  only, 35 artefacts.
- **G1 (organelle abundance) needs words, not a better learner.** Given a hand-written "high demand"
  predicate, Popper learns the G1 rule exactly in every fold. Without it, predicate invention finds
  nothing.
- **What matters now.** Options A (a class rule as a hypothesis fact) and H (`generalize`) work today
  with no core change. The FAILs need annotation fixes. Dan's open choice: path rules get a core rule
  (C, prototyped: a new type and a new `Derivation` rule), or learners stay outside (F).

Files:
- `BioLean/Stress/Induction.lean`: today's core on the cases. 26 cases pinned; about 10 s; no `sorry`.
- `BioLean/Proto/Induction.lean`: a learned rule as a value, and a derivation rule that fires it. About 5 s.
- `scripts/stress/induction_*.py`: search with hold-out, miner, AMIE and Popper runners, tasks,
  cross-validation, precision sample, CURIE and reference checks, `cases.tsv` writer and checker.
- `data/stress/10c/`: `cases.tsv` (full table), runs, judgements, `curies_checked.tsv`, `refs_checked.tsv`.

## Words used here

| word | meaning here |
|---|---|
| ILP | inductive logic programming: learn logic rules from examples and background facts |
| Horn rule | `head <= body`: if every body atom holds, the head holds |
| class rule | "every D has r to C": `r(x,C) <= is_a(x,D)` |
| path rule | variables only: `has_input(x,y) <= has_output(x,z), derives_from(z,y)` |
| feature, taxon rule | `r(x,C) <= b(x,D)`; taxon rule: b = `in_taxon` |
| support | known facts the rule predicts |
| PCA confidence | support over predictions whose subject has some fact of the head relation (AMIE) |
| LGG | least general generalisation: the most specific class over all supports |
| predicate invention | the learner adds a predicate, defined by a rule of its own |
| hypothesis weight | `EvidenceKind.hypothesis`, weight 0: stated, no belief |
| `generalize` | the core's induction rule (M4): instances in several taxa give the clade, discounted by coverage |
| search | the closure search (`scripts/search/closure.py`), here as a copy with hold-out |
| artefact | a rule that fits the data for a reason that is not biology |

## 1. The question

The hole search (`docs/holes.md`) runs each rule backwards to propose one missing fact. It cannot
propose a missing rule or invent a predicate. One hole, G1, needs a rule: "cells with a high demand
for a function have many of the organelle that does it" (m45432-155, -189, -203).

1. What can a learner recover from the compiled textbook (recall and precision on held-out facts)?
2. Which learned rules are biology, and which are artefacts of annotation or ontology?
3. How should a learned rule enter BioLean: as a fact, as data, as a new rule kind, or not at all?
4. What would G1 need?

## 2. What exists

| system | learns | needs negatives | invents predicates | here |
|---|---|---|---|---|
| Popper (Cropper and Morel 2021) | Horn programs, learning from failures | yes | yes (Cropper and Morel 2021b) | run, 4 tasks |
| Aleph (Progol line, Muggleton 1995) | one clause at a time, inverse entailment | yes | no | not run |
| Metagol (Muggleton et al. 2015) | meta-interpretive learning from metarules | yes | yes | not run |
| AMIE (Galárraga et al. 2013, 2015; Lajus et al. 2020) | closed path rules, PCA confidence | no | no | AMIE 3.0, all tasks |
| AnyBURL (Meilicke et al. 2019) | sampled path and constant rules | no | no | not run |
| `induction_mine.py` (here) | AMIE-style path, class, feature, taxon rules | no | no | all tasks |
| analogy (Gentner 1983) | map a structure to another domain | no | no | only as `transport` |
| BioLean's `generalize` (M4) | one predicate, widened from sampled taxa to a clade | no | no | in the core; I37 |

ILP in biology: Muggleton et al. 1992; King et al. 2004. Predicate invention: Muggleton and Buntine
1988. What the "core change" labels rest on, in the code:
- `Claim` has no variables, so a rule cannot be a claim.
- `Derivation` has a fixed list of rules. The only rule table is data: `RO.chainOK` (RO chains,
  transitivity, is_a laws). Logical steps take `Opinion.weakest`.
- Two empirical steps exist: `transport` (an evidence item, between sibling taxa) and `generalize`
  (induction over taxa, discounted by coverage).
- `EvidenceKind.hypothesis` (weight 0) lets a statement sit in the library with no belief.
- `Claim.less a b q` exists; `compareIntervals` is the only rule that concludes it.
- The search (copied with hold-out as `induction_closure.py`) applies relChain, transitivity,
  isaInherit, isaGeneralise, isaInheritEffect, viaActivity, viaAmount, notRelSub. Not `generalize`.

## 3. The options

| | idea | core change? | needs | right | wrong |
|---|---|---|---|---|---|
| A | A learned class rule "every D r C" is the statement `D r C` with hypothesis evidence; held-out tests add evidence | **No** (data) | a script writing statements and tests | works today; tested, I07 is *established* at 0.8 | class rules only; every subclass gets the full belief, true or false (I11, I12, I15) |
| B | A learned path rule `r1 ∘ r2 ⊑ r3` in a second chain table | **Yes**: a new `Derivation` rule (in `RO.chainOK` it would be a logical, weakest-link step, which it is not) | the table, an opinion per entry | I18 | two-atom paths only |
| C | A Horn rule is a value (body, head, support, tests); `apply` fires it, Lean checks the match by `decide`; strength: premises by `weakest`, then `chain` with the tests | **Yes**: a new type (`Rule`) and a new `Derivation` rule. Prototype in `Proto/Induction.lean` | a test protocol; `axioms` lists rules | any rule shape; untested gives 0; a use never beats its rule (theorems) | checks the match, not the truth: accepts "mitochondria photosynthesise" (I19); `chain` multiplies |
| D | Invented predicates: a claim with a predicate no ontology has (`XClaim.invented`) | **Yes**: a new `Claim` constructor | naming, review | G1 can be stated (I31) | no learner invents the predicate (P32); an ungrounded name joins nothing |
| D' | Abundance as quantity: `Claim.less` with an EQ-style quality, or counts plus `compareIntervals` | **No** | a comparison class; sourced counts | no new words | today's nearest form is false as written (I30) |
| E | Analogy: move a rule to a sibling class in one weighted step | **Yes**: widen `transport` from sibling taxa to sibling classes | a sibling relation, a weight | how biologists reason | one number for a mechanism-dependent step; descent as analogy fails (I19) |
| F | Learners stay outside: they propose, an agent or Dan accepts some as statements; rules seed the hole search | **No** (scripts, data) | curation time | small core | the kernel never uses a learned rule |
| G | Do not induce; use curated axioms (M5) and RO only | **No** | nothing | no artefacts | G1-type knowledge never appears |
| H | Taxon rules by the core's own `generalize` (M4); the search learns to apply it | **No** (in the core; the search is a script) | instances in two or more lineages | sound: one lineage gives belief 0 (I37); a taxon outside the clade is refused | taxon contexts only; 16/27 here, because "prokaryotes" is annotated as Bacteria, so Archaea look unsampled |

A, D', F, G and H leave the core alone. B, C, D and E each add a constructor, a rule or a type.

**I30 (option D').** With a quality built by refinement (PATO:0001555 "has number of", towards
mitochondrion, RO:0002503), `Claim.less cell (muscle cell) q` typechecks. But muscle cell is_a cell, so
it says every muscle cell has fewer mitochondria than itself; CL has no class for "other cells".

## 4. The stress set

Each task hides zero or more of the 1,401 compiled statements, gives the rest, and asks for **pos**
(true facts, with a checked source) and **neg** (false facts, checked source).

**Mark rule**: FAIL if any neg is concluded; else PASS if every pos is (a task with no pos passes by
staying silent); else SILENT; INEXPRESSIBLE if the predicate is not in the vocabulary. Concluded means
derived with belief above 0; for a learner, predicted with PCA at least 0.5 and support at least 2.
**BioLean** is the Lean core with its built libraries, searched by the closure search. Its mark is the
search's, except where a Lean theorem shows more: I10 (FAIL, round-2 library) and I37 (PASS,
`generalize`). `cases.tsv` keeps the search's own mark as `mark_search`. Popper's mark uses exact
mode. "syn" marks hand-written facts. All 262 CURIEs cited in the program's files were checked on OLS4
on 2026-11-01; none obsolete.

Families: A deduction (I01-06), B class (I07-17), C path (I18-24), D taxon (I25-27, I37), E feature
(I28-29), F invention (I30-33), G guards (I34-36).

| id | probes | BioLean | miner (onto) | miner (tb) | AMIE | Popper |
|---|---|---|---|---|---|---|
| I01 | part_of is transitive | PASS | PASS | SILENT | SILENT | - |
| I02 | has_part is transitive | PASS | SILENT | SILENT | SILENT | - |
| I03 | is_a passes an effect down | PASS | PASS | PASS | PASS | - |
| I04 | is_a passes capable_of down | PASS | SILENT | SILENT | SILENT | - |
| I05 | RO chain occurs_in ∘ part_of | PASS | SILENT | SILENT | SILENT | - |
| I06 | drug inhibits enzyme | PASS | SILENT | SILENT | SILENT | - |
| I07 | lobes part of cortex | SILENT | PASS | PASS | PASS | - |
| I08 | thalamus, not spinal cord, in brain | SILENT | PASS | PASS | PASS | - |
| I09 | aspirin, not aldosterone | SILENT | FAIL | SILENT | SILENT | - |
| I10 | cell walls by lineage | **FAIL** (round 2) | FAIL | SILENT | SILENT | - |
| I11 | phases of mitosis | SILENT | SILENT | SILENT | SILENT | - |
| I12 | islet cell types | SILENT | FAIL | PASS | PASS | - |
| I13 | what halves ploidy | SILENT | FAIL | SILENT | SILENT | - |
| I14 | tumour suppressors | SILENT | SILENT | SILENT | SILENT | - |
| I15 | what makes ATP | SILENT | FAIL | PASS | PASS | - |
| I16 | HIV enters host cells | SILENT | SILENT | SILENT | SILENT | - |
| I17 | who has a nucleus | SILENT | SILENT | SILENT | SILENT | - |
| I18 | a product's source is an input | SILENT | PASS | PASS | PASS | PASS |
| I19 | descent as analogy | PASS | FAIL | FAIL | FAIL | - |
| I20 | inverting has_part | PASS | FAIL | FAIL | FAIL | - |
| I21 | upward parthood | PASS | FAIL | FAIL | FAIL | - |
| I22 | a whole does what its part does | SILENT | SILENT | SILENT | SILENT | - |
| I23 | the brief's organ rule | SILENT | SILENT | SILENT | SILENT | SILENT |
| I24 | parthood as causation | PASS | FAIL | FAIL | FAIL | - |
| I25 | bacterial DNA and ribosomes | **FAIL** | FAIL | FAIL | FAIL | - |
| I26 | eukaryotic DNA and ribosomes | PASS | SILENT | SILENT | SILENT | - |
| I27 | plant cell wall | SILENT | PASS | SILENT | SILENT | - |
| I28 | CO2 in, sugar out | SILENT | PASS | PASS | SILENT | - |
| I29 | glucose in, ATP up (not anabolism) | PASS | PASS | PASS | PASS | - |
| I30 | G1 as the core holds it | INEXPRESSIBLE | INEXPRESSIBLE | INEXPRESSIBLE | INEXPRESSIBLE | - |
| I31 | G1, demand given (syn) | SILENT | SILENT | SILENT | SILENT | PASS |
| I32 | G1, capability as proxy (syn) | PASS | PASS | PASS | PASS | FAIL |
| I33 | organelles from bacteria | PASS | PASS | PASS | PASS | - |
| I34 | one instance is not a rule | PASS | PASS | PASS | PASS | - |
| I35 | rule defeated by a negation (syn) | PASS | PASS | PASS | PASS | - |
| I36 | duplicate sentence (syn) | PASS | PASS | PASS | PASS | - |
| I37 | widen a taxon rule (`generalize`) | PASS (Lean) | SILENT | SILENT | SILENT | - |

`cases.tsv`'s `test` column names each Lean pin (26 cases). The Python pin, `induction_cases.py
check`, recomputes every mark, re-runs the search on all 37 tasks (about 1 s), and exits 1 on any
change.

## 5. Results observed

### 5.1 Marks

| system | PASS | FAIL | SILENT | INEXPRESSIBLE |
|---|---:|---:|---:|---:|
| **BioLean today** | 18 | 2 | 16 | 1 |
| the closure search alone | 17 | 1 | 18 | 1 |
| null (concludes nothing; a baseline) | 10 | 0 | 26 | 1 |
| miner, ontology is_a | 13 | 10 | 13 | 1 |
| miner, textbook is_a | 13 | 5 | 18 | 1 |
| AMIE 3.0 | 12 | 5 | 19 | 1 |
| Popper 5.0 (4 tasks) | 2 | 1 | 1 | 0 |

- **Deduction: BioLean passes all six** as kernel-checked theorems; five at 0.8, I06 (an effect chain)
  at 0.64, *unsupported*.
- **Taxon induction: `generalize` is right both ways (I37).** From the prokaryote and eukaryote
  sentences: "ribosomes are in the cytoplasm in cellular organisms" (16/27). From the eukaryote
  sentence alone, "every chromosome is in a nucleus" gets 0. The search and the learners get neither.
- **Class rules: the search is silent on all eleven.** The round-2 library FAILs I10. The
  ontology-background miner FAILs 5, all LATTICE: the least general class is far too broad.
- **Four traps: every learner FAILs, BioLean passes.** "Mitochondria photosynthesise" (I19), "every
  phospholipid is part of a mitochondrial membrane" (I20), "every bone is part of the rib cage" (I21),
  "the nasal cavity raises oxygen" (I24). BioLean passes as the null system does: it has no such rule
  (pinned).
- **Learners pass 7 tasks where BioLean is silent.** Sound on 3: I15 (M1's bridge "output m raises
  m"), I18 (the one new true path rule), and I07 for the ontology miner only; the other two pass I07
  with the upward rule that FAILs I21. I28 by a SCOPE rule. Unsound on I08 and I12 (inverting
  has_part) and I27 (the cell-wall rule that FAILs I10).
- **I31 and I32:** the miners are silent on I31, and pass I32, only because `has_abundant` has 3 facts,
  below their threshold of 4 for a head relation. Popper's FAIL on I32 is its run with no negatives.

### 5.2 Recall and precision on held-out facts

Five folds over 1,266 statements (not is_a, not negations), seed 10. Precision here is a floor: a
prediction that is not a held-out fact counts as wrong even when it is true.

| method | background | min PCA | predictions | hits | recall | precision floor | recall with closure |
|---|---|---:|---:|---:|---:|---:|---:|
| closure (today) | textbook | - | - | 36 | 0.028 | - | - |
| miner | textbook is_a | 0.5 | 3,051 | 45 | 0.036 | 0.015 | 0.055 |
| AMIE 3.0 | textbook is_a | 0.5 | 2,540 | 62 | 0.049 | 0.024 | 0.068 |
| miner | ontology is_a | 0.5 | 33,816 | 71 | 0.056 | 0.002 | 0.077 |
| miner | ontology is_a | 0.1 | 108,962 | 192 | 0.152 | 0.002 | 0.160 |

Leave-one-out, the closure re-derives 49 of 1,266 statements (3.9 percent). The ontology background
doubles recall at PCA 0.1 and multiplies predictions by eleven.

**Judged precision.** New predictions on the full textbook, read as "every A r some B", judged by me.
"Scope" means true only in the book's scope (eukaryotes, mammals).

| learner | judged | true | scope | unclear | false | precision | with scope |
|---|---|---:|---:|---:|---:|---:|---:|
| miner, textbook is_a, PCA at least 0.5 | 30 of 1,000 | 5 | 1 | 4 | 20 | 0.17 | 0.20 |
| AMIE 3.0, PCA at least 0.5 | 30 of 759 | 7 | 2 | 1 | 20 | 0.23 | 0.30 |
| Popper, P18 program | all 48 | 6 | - | 1 | 41 | 0.13 | - |
| the brief's rule, as Popper learned it | all 21 | 14 | - | 0 | 7 | 0.67 | - |

Commonest errors: inverting has_part ("every bicarbonate is part of pancreatic juice"), and category
errors ("a phospholipid happens during the nucleus"); typing heads by RO domain and range would remove
the second kind.

### 5.3 Which learned rules are true biology

64 rules: every rule that decided a task, plus the top rules (`rule_judgements.tsv`).

| verdict | rules | meaning | examples |
|---|---:|---|---|
| TRUE | 13 | true in general | has_input <= has_output, derives_from; "output m raises m" (M1's bridge); is_a inheritance |
| SCOPE | 16 | true for the book, false outside | "CO2 in, so sugar out" (carbon fixation only); "oxygen in, so in mitochondria" (not bacteria) |
| LATTICE | 20 | the least general class is far too broad | "every drug lowers inflammation"; "every cellular component produces ATP" (GO's root) |
| FORM | 11 | unsound shape for class-level claims | inverting has_part; upward inheritance; parthood as causation |
| ANNOT | 4 | artefact of the annotation | all supports run through "cells derive from cells" (m45428-74) |

- **PCA rewards sparsity.** "Every cellular component produces ATP" scores 1.0: only 3 of its 144
  subjects have any `produces` fact.
- **Annotation shapes rules.** "Anti-inflammatory drugs that may be used include aspirin, topical pain
  relievers, and corticosteroid injections" (m45538-200) is annotated "corticosteroid is_a
  anti-inflammatory drug", a role written as is_a. Through ChEBI that carries "anti-inflammatory" to
  aldosterone, which promotes inflammation (Brown 2013).
- **The true rules are mostly known.** Only one true path rule is new and not in RO:
  `has_input(x,y) <= has_output(x,z), derives_from(z,y)`. All three learners found it.

### 5.4 G1 and predicate invention (Popper)

The G1 sentences are not compiled (blocker "proportion"), so I wrote two predicates by hand
(synthetic): `has_abundant` (erythroblast, ribosome; secretory cell, Golgi; muscle cell,
mitochondrion) and `high_demand` (from each sentence's own "because"). Negatives: a generic cell is
not rich in any of the three.

| task | background | negatives | Popper's program | held-out |
|---|---|---|---|---|
| P31, 3 folds | capable_of + high_demand | generic cell | `has_abundant(X,O) :- high_demand(X,F), capable_of(O,F)` | 3 of 3 |
| P31b, 3 folds | same | + 6 cross pairs (closed world) | the same rule | 3 of 3 |
| P32, 3 folds | capable_of only (demand read as capability); invention on | generic cell | none | 0 of 3 |
| P32, no negatives | same | none | `has_abundant(X,O) :- capable_of(O,_), capable_of(X,_)` | all 3 negatives predicted |

**With the words, G1 is easy. Without them, it is impossible.** The book says all cells make ATP
(molbio-m45480-10), so capability cannot separate muscle cells from cells; only demand can. No
ontology states organelle number as logic (OLS4 has only abnormal phenotypes, UPHENO:0063670). But CL
definitions state it in text: the ionocyte (CL:0005006) is "characterized by abundant mitochondria";
renal intercalated cells (CL:0005010) are "also called mitochondria-rich cells". G1 is a vocabulary
task (D or D') first.

### 5.5 Popper on the textbook (P18, P23)

| task | mode | result |
|---|---|---|
| P18 has_input, Calvin cycle CO2 hidden | noisy (minimum description length) | empty program |
| P18 | exact | 4 rules, one the true R1; predicts the hidden fact. 48 new predictions, 6 true |
| P23 involved_in, amygdala hidden | exact | `involved_in <= capable_of` plus an upward rule; amygdala not predicted |
| P23, amygdala as a training example | exact | the brief's rule `involved_in(x,p) <= part_of(x,s), capable_of(s,p)`, **from that one example** |

The brief's rule adds 21 predictions: 14 true (stroma in photosynthesis, glomerulus in filtration), 7
false (desmosomes in ATP synthesis, amygdala in hearing): a whole's generic capability passes to every
part. RO's chain is weaker and sound, `part_of ∘ capable_of ⊑ part of structure that is capable of`
(RO:0002329), and the core applies it (pinned, *established*).

### 5.6 Today's core: the two FAILs

- **I25.** "A chromosome is a structure within the nucleus that is made up of DNA, the hereditary
  material, and proteins" (m45432-100) is annotated for every chromosome. With the refinement axiom
  (chromosome ⊓ in taxon Bacteria is_a chromosome), the core establishes "the bacterial chromosome is
  located in a nucleus" at 0.8 (`I25_false_established`). The book's negation (m45429-15) is about
  the cell, so `clash` cannot see it. Fix: refine m45432-100 to eukaryotes.
- **I10.** m45432-355 is the glossary entry "cell wall: a rigid cell covering made of cellulose in
  plants, peptidoglycan in bacteria, ... and chitin in fungi". Its annotation has the plant context;
  the round-2 Lean statement dropped it, so the library establishes "the bacterial cell wall contains
  cellulose" (theorem). The search reads round 3, which keeps the context, and is silent.
- **The I10 hazard is systematic.** 68 round-2 Lean statements dropped a context their annotation had
  (41 of them a taxon); 15 have no round-3 record (`r2_context_dropped.tsv`).
- **I35 (right).** A learned "every cell has a nucleus" entered as a fact reaches prokaryotes, and
  `clash` with the book's negation gives *refuted*.

Specialisation is free in the core; widening is not (`generalize`). Both FAILs are narrow sentences
annotated wide.

### 5.7 The prototype in numbers

Each test is one observational item (weight 1/2; a choice).

| rule | tests | rule opinion | one use | verdict |
|---|---|---|---|---|
| R1 has_input <= has_output, derives_from | 1 confirmation | b 1/2 | Calvin cycle has input CO2: b 2/5 | unsupported |
| R1, untested | none | vacuous | b 0 | unsupported |
| R2 capable_of <= derives_from, capable_of | 1 refutation | d 1/2 | mitochondria photosynthesise: b 0 | unsupported, not refuted |
| R3 G1 rule (invented predicates) | 3 leave-one-out (P31) | b 3/4 | muscle cell, abundant mitochondria: b 3/5 | unsupported |
| R4 the brief's rule | 14 true, 7 false (P23) | b 7/11, d 7/22: contested | amygdala in memory: b 28/55 | unsupported |

`chain` multiplies (4/5 × 4/5 = 16/25), so a learned rule rarely establishes anything. It drops the
rule's disbelief, so a refuted rule gives "unsupported", never "refuted".

## 6. Experiments for later

Exit test first; cost in agent tasks.

| | experiment | exit test | cost |
|---|---|---|---|
| X1 | Lattice guard: refuse class rules whose class has low information content (decision 7's IC) | at least 15 of the 20 LATTICE rules refused, at most 2 of the 13 TRUE | 1 |
| X2 | Two-atom bodies for class and taxon rules (`in_taxon(x,T), is_a(x,D)`) | I25's ribosome negative no longer predicted; its chromosome positive still is | 1 |
| X3 | Book negations as negatives; heads typed by RO domain and range | judged precision of the miner at PCA 0.5 from 0.17 to at least 0.35 | 1 |
| X4 | Rules seed the hole search (a copy of `holes.py` that also runs R1 and R3 backwards) | proposes "muscle cell has high demand for ATP synthesis" once R3 is given | 1 |
| X5 | Option A with automatic leave-one-out tests as evidence | I07-style rules reach 0.8 only with 4 or more confirmations and no refutation; I11, I12, I15 negatives stay below 0.5 | 2 |
| X6 | Option C in a branch: `Rule`, `Derivation.apply`, rules in `axioms` | every pin in `Proto/Induction.lean` passes unchanged in the core | 2 |
| X7 | G1 vocabulary: annotate the four G1 sentences, their "because" clauses, and CL's abundance definitions (D or D') | Popper learns R3 and predicts an abundance fact it did not see | 2 |
| X8 | Fix the annotation FAILs: refine m45432-100; let round 3 supersede round 2 in the library, or refine the 68 statements | I25 and I10 negatives not derivable; I26 and I37 unchanged | 1, touches `data/textbook` |
| X9 | Aleph and Metagol on the 4 Popper tasks | each gives a program or none | 2 |
| X10 | Second corpus (M7): learn on *Concepts of Biology*, test on *Biology 2e* | judged precision of TRUE and SCOPE rules on the new book at least 0.5 | 3 |
| X11 | Option H: a copy of the closure search that also applies `generalize` | I37 PASS in the search column; no new FAIL on the 37 tasks | 1 |

Milestones: X4 is M8's "holes fed to an ILP-style search". X1 reuses M5's ontology data. X10 is M7's
measurement for rules. X11 joins M4's rule to M8's search.

## 7. What the formal system would become

- **A, D', F, G, H**: no change. BioLean stays "statements, fixed rules, opinions". H uses a rule the
  core already has.
- **C**: rules become first-class, evidenced objects; `axioms` lists statements *and* rules. Every
  use is kernel-checked for shape. **B** is a narrow C.
- **D**: claims may use words no ontology has. That changes what a claim is.
- **E**: one existing rule widened.

## 8. What would change the decision

- If X1 and X3 lift judged precision of class rules above 0.8, option A alone may be enough.
- If X6 shows C is cheap and X4 finds holes worth having, C is the home for path rules.
- If a learner invents a demand-like predicate from data alone (P32 passes), D needs no hand-written
  words. Today none does.
- If curated sources (GO-CAM, program 10b) give tens of instances per pattern, these numbers change.
- Design choice: should a refuted rule refute its conclusions? With `chain`, it cannot.

## 9. Limits

- **My judgements are not source-checked per item** (rule verdicts, precision samples, Popper
  predictions). The marks rest on checked sources; these do not.
- **PASS by silence.** 10 of BioLean's 18 PASSes are neg-only tasks (the null row).
- **Small data, few negatives.** 1,401 statements; most rules have support 2 or 3. The book states few
  negations, so learners fall back on PCA or closed-world negatives.
- **The G1 facts are synthetic**, written by me from the sentences.
- **Thresholds are choices**: PCA 0.5, support 2, head relation with at least 4 facts, depth 4, test
  weight 1/2.
- **The closure copy loads 1,401 statements and 184 refinement axioms; `closure.json` says 1,402 and
  185.** The 2,223 derived facts are identical (key, depth, belief). The pin re-runs the copy, not
  `closure.py`.
- **Ties and order.** Tied rules, and Popper's rule order, can differ between runs ("rule 0" in
  `predictions_judged.tsv` follows the first run). Marks, counts and programs do not (two re-runs).
- **AMIE 3.0, not 3.5.1** (3.5.1 needs Java 17; this machine has 11). With `-const` AMIE did not
  finish in 100 s. Popper constants are mapped to safe atoms (`popper/constants.tsv`).

## 10. What the review changed

| found | done |
|---|---|
| `generalize`, the core's own induction rule, was missing ("`transport` is the one empirical step") | option H and case I37, pinned by theorems |
| the summary said "one FAIL"; the round-2 library FAILs I10 (a pinned theorem) | I10 marked FAIL; `mark_search` kept |
| 10 of the PASSes come from silence; I07 was a "sound" pass for two learners using the upward rule | null baseline row; corrected |
| three precision judgements counted book-scope truths as true | marked "scope" |
| I25's ribosome negative cited a sentence that does not support it | Bakshi 2012 added |
| three quotes were paraphrases; "organelle number only as abnormal phenotypes" was too strong | real sentences; CL definitions cited |
| 118 CURIEs never checked; the Python pin only re-read stored runs | all checked; the pin re-runs the search |

## 11. References (checked)

Checked on Crossref, DataCite, Europe PMC or Reactome on 2026-11-01 (`refs_checked.tsv`): first author
and title match the record.

- Bakshi S, Siryaporn A, Goulian M, Weisshaar JC (2012). Superresolution imaging of ribosomes and RNA polymerase in live Escherichia coli cells. *Mol Microbiol*. PMID 22624875.
- Brown NJ (2013). Contribution of aldosterone to cardiovascular and renal inflammation and fibrosis. *Nat Rev Nephrol*. PMID 23774812.
- Cropper A, Morel R (2021). Learning programs by learning from failures. *Machine Learning*. doi:10.1007/s10994-020-05934-z.
- Cropper A, Morel R (2021b). Predicate invention by learning from failures. arXiv. doi:10.48550/arXiv.2104.14426.
- Galárraga L, Teflioudi C, Hose K, Suchanek F (2013). AMIE: association rule mining under incomplete evidence in ontological knowledge bases. *WWW 2013*. doi:10.1145/2488388.2488425.
- Galárraga L, Teflioudi C, Hose K, Suchanek F (2015). Fast rule mining in ontological knowledge bases with AMIE+. *The VLDB Journal*. doi:10.1007/s00778-015-0394-1.
- Gentner D (1983). Structure-mapping: a theoretical framework for analogy. *Cognitive Science*. doi:10.1207/s15516709cog0702_3.
- Gow NAR, Latge JP, Munro CA (2017). The fungal cell wall: structure, biosynthesis, and function. *Microbiol Spectr*. PMID 28513415.
- Jeay S, Sonenshein GE, Postel-Vinay MC, Kelly PA, Baixeras E (2002). Growth hormone can act as a cytokine controlling survival and proliferation of immune cells. *Mol Cell Endocrinol*. PMID 11911939.
- Ji P, Murata-Hori M, Lodish HF (2011). Formation of mammalian erythrocytes: chromatin condensation and enucleation. *Trends Cell Biol*. PMID 21592797.
- King R et al. (2004). Functional genomic hypothesis generation and experimentation by a robot scientist. *Nature*. doi:10.1038/nature02236.
- Lajus J, Galárraga L, Suchanek F (2020). Fast and exact rule mining with AMIE 3. *ESWC 2020*, LNCS. doi:10.1007/978-3-030-49461-2_3.
- McGaugh JL (2004). The amygdala modulates the consolidation of memories of emotionally arousing experiences. *Annu Rev Neurosci*. PMID 15217324.
- Meilicke C, Chekol M, Ruffinelli D, Stuckenschmidt H (2019). Anytime bottom-up rule learning for knowledge graph completion. *IJCAI 2019*. doi:10.24963/ijcai.2019/435.
- Muggleton S (1995). Inverse entailment and Progol. *New Generation Computing*. doi:10.1007/BF03037227.
- Muggleton S, Buntine W (1988). Machine invention of first-order predicates by inverting resolution. *Machine Learning Proceedings 1988*. doi:10.1016/B978-0-934613-64-4.50040-2.
- Muggleton S et al. (1992). Protein secondary structure prediction using logic-based machine learning. *Protein Engineering*. doi:10.1093/protein/5.7.647.
- Muggleton S, Lin D, Tamaddoni-Nezhad A (2015). Meta-interpretive learning of higher-order dyadic datalog: predicate invention revisited. *Machine Learning*. doi:10.1007/s10994-014-5471-y.
- Weinberg RA (1995). The retinoblastoma protein and cell cycle control. *Cell*. PMID 7736585 (I14's positive).
- Reactome R-HSA-70263 (Gluconeogenesis), R-HSA-75105 (Fatty acyl-CoA biosynthesis): names checked.
- OpenStax, *Concepts of Biology*: the textbook sentences.

## 12. UNVERIFIED

- Aleph: no paper checked; named only as part of the Progol line.
- Plotkin's least general generalisation (1970): not checked, so not cited.
- Every judgement in `rule_judgements.tsv`, `precision_judged.tsv` and
  `popper/predictions_judged.tsv`, and the biology inside their reasons (for example "peroxisomes use
  oxygen"): mine, from general knowledge, not checked per item.
