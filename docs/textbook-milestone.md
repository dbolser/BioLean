# Textbook milestone: how much of OpenStax *Concepts of Biology* can BioLean hold?

Corpus: 7 chapters, 39 modules, about 61k words (body systems split into two files, so 8 claim files). Source text is not committed.
Every number below is recomputed from `data/textbook/claims/*.json` by `scripts/textbook/aggregate.py` (`uv run python scripts/textbook/aggregate.py`).

Caveat: the per-chapter summaries given to this report mixed units. `n_claims` was sometimes all records (cell 863), sometimes claims only (energy 438). `n_sentences` was sometimes a regex split count (cell 650, file has 643 distinct). Bins and entity counts matched the files. Tables here use file counts only.

## 1. Headline

| measure | value |
|---|---:|
| distinct source sentences | 3,723 |
| records (atomic statements) | 5,422 |
| claims (record not binned not_claim) | 4,695 |
| exact duplicate records (summaries repeat text) | 44 |
| claims with a Lean term (not just a comment) | 2,743 (58%) |
| **bin: now** | **411 (8.8% of claims)** |
| bin: with_context | 554 (11.8%) |
| bin: missing_construct | 3,730 (79.4%) |
| bin: not_claim | 727 (13.4% of records) |
| kind: effect | 1,177 (25.1%) |
| kind: process_description | 922 (19.6%) |
| kind: definitional | 898 (19.1%) |
| kind: structural | 869 (18.5%) |
| kind: other | 436 (9.3%) |
| kind: quantitative | 336 (7.2%) |
| kind: procedural | 57 (1.2%) |
| entity mentions | 12,100 |
| **grounded to a CURIE** | **11,253 (93.0%)** |
| verified on OLS4 | 11,233 (92.8%) |

409 of the 411 `now` claims are kind=effect, yet only 35% of effect claims fit now (409 of 1,177); 443 need Context, 325 a missing construct (mostly "X produces Y").

| ontology | mentions | grounded | rate |
|---|---:|---:|---:|
| GO | 4,294 | 4,240 | 98.7% |
| UBERON | 2,423 | 2,407 | 99.3% |
| CHEBI | 2,147 | 2,089 | 97.3% |
| CL | 650 | 648 | 99.7% |
| NCBITaxon | 455 | 435 | 95.6% |
| SO | 344 | 343 | 99.7% |
| PATO | 307 | 287 | 93.5% |
| PR, MONDO, HP, OBI | 409 | 399 | 97.6% |
| other (NCIT, OBA, EFO, ...) | 783 | 405 | 51.7% |
| none assigned | 288 | 0 | 0% |

Once an ontology fits, grounding is near total. The misses are the 1,071 mentions with no home ontology: generic nouns, qualities as agents, exposures.

**Prediction (notes 2026-10-27, section 5).**

| prediction | result | verdict |
|---|---|---|
| entities ground above 80% | 93.0% (lowest chapter: inheritance at 81.4%) | held |
| claims split roughly evenly: effect / structural / definitional | 25 / 18.5 / 19 %, plus process_description 20% | held by kind |
| the effect share is what "we have" | only 8.8% of claims are expressible now | failed |
| process descriptions are really definitions that belong in the ontology | only 15% are already axioms (section 5) | mostly failed |

## 2. Per chapter

| file | sentences | claims | now | with_context | missing | not_claim | grounded |
|---|---:|---:|---:|---:|---:|---:|---:|
| cell-structure-and-function | 643 | 702 | 9 | 135 | 558 | 161 | 90.9% |
| how-cells-obtain-energy | 561 | 438 | 38 | 92 | 308 | 232 | 93.8% |
| photosynthesis | 270 | 331 | 31 | 29 | 271 | 77 | 94.5% |
| reproduction-at-the-cellular-level | 311 | 422 | 26 | 20 | 376 | 33 | 98.2% |
| the-cellular-basis-of-inheritance | 384 | 467 | 36 | 61 | 370 | 44 | 81.4% |
| molecular-biology | 437 | 577 | 5 | 40 | 532 | 70 | 87.8% |
| the-body-s-systems-a | 498 | 716 | 143 | 89 | 484 | 57 | 94.0% |
| the-body-s-systems-b | 621 | 1,042 | 123 | 88 | 831 | 53 | 99.5% |

Body systems hold 266 of the 411 `now` claims (hormones, reflexes). Molecular biology has 5: it is structure, counts and order.

## 3. Missing constructs, ranked

111 raw construct names, folded into families by the script.

| # | family | claims | % of missing | example |
|---:|---|---:|---:|---|
| 1 | is_a / identity | 882 | 23.6 | A cell is the smallest unit of a living thing |
| 2 | has_part / part_of / made_of | 498 | 13.4 | The human body is made of cells |
| 3 | quantity / comparison / quantifier | 422 | 11.3 | Prokaryotic cells are smaller than eukaryotic cells |
| 4 | located_in / occurs_in / spatial | 269 | 7.2 | Epithelial cells cover the organs and body cavities |
| 5 | capable_of / has_function / enables | 257 | 6.9 | Epithelial cells protect the surface of the body |
| 6 | sequence / occurs_during | 245 | 6.6 | The centrosome replicates before the cell divides |
| 7 | transport / connects | 183 | 4.9 | The ER membrane is continuous with the nuclear envelope |
| 8 | has_output (+ 21 joint in/out) | 176 | 4.7 | The gonads produce steroid hormones |
| 9 | has_input | 130 | 3.5 | All new cells arise from existing cells |
| 10 | necessity (requires) | 121 | 3.2 | Cell division requires DNA replication |
| 11 | negation / absence | 85 | 2.3 | A prokaryotic cell lacks a nucleus |
| 12 | has_quality | 82 | 2.2 | The prokaryotic chromosome is circular |
| 13 | unsigned effect / regulation | 75 | 2.0 | Hormones regulate body processes |
| 14 | binding | 56 | 1.5 | Each receptor binds a specific substance |
| 15 | procedure / method | 51 | 1.4 | Light microscopes can be used to view living organisms |
| 16 | conditional / modality | 49 | 1.3 | The temperature set point can be adjusted |
| 17 | derives_from / evolution | 42 | 1.1 | Each chromosome of a homologous pair is inherited from a different parent |
| 18 | disjunction | 34 | 0.9 | All cells are either prokaryotic or eukaryotic |
| 19 | disease target | 20 | 0.5 | Uncontrolled cell division causes cancer |
| 20 | missing entity kind (variant, sequence feature) | 13 | 0.3 | An unrepaired thymine dimer leads to a mutation |
| | other (feedback, mechanism, encodes, ...) | 40 | 1.1 | |

The top six are plain RO/OBO relations: 2,573 claims, 69% of the missing bin.

## 4. What is derivable

From `docs/textbook-derivations.md`: 60 attempts (52 derivations plus 8 gap analyses).

| measure | value |
|---|---:|
| derivations whose conclusion is a stated sentence | 52 |
| typecheck today (`lit`, `viaAmount`, `viaActivity`, `both`) | 4 (all hormone feedback loops) |
| typecheck with the already-proposed `inContext` / `specialise` / `generalize` / `transport` | 6 |
| theorems found by hand (incl. sibling sentences) | about 65 (1.4% of claims, a lower bound) |
| Lean terms that exactly restate another claim (theorem by `lit`) | 287 of 2,743 |
| proofs that caught the book overclaiming | 2 (codon degeneracy, tortoiseshell cat) |

Rules that do the work: `viaAmount` (10 derivations), `both` (3), `viaActivity` (2). The existing chain core is right. It just has too few premises it can accept.

| blocking constructor | derivations blocked |
|---|---:|
| structural claims (isA, partOf, hasPart, lacksPart, occursIn, hasInput, hasOutput, transport, requires) | 24 |
| quantity + count (arithmetic side goal, `norm_num` / `decide`) | 13 |
| inheritIsA | 7 |
| inContext | 5 |
| inputPositive, viaGradient, occursInLift, pathCompose | 3 each |
| 7 rules | 2 each |
| 19 rules | 1 each |

## 5. How much is already ontology axiom

From `docs/textbook-axioms.md`: 240 sampled structural/definitional claims checked against GO, UBERON, CL and CHEBI logic on OLS4.

| class | n | % |
|---|---:|---:|
| already an axiom | 36 | 15% |
| only in definition text | 62 | 26% |
| not in the ontology | 142 | 59% |

The hits are mostly UBERON partonomy. GO processes carry almost no has_input / has_output / occurs_in logic (photosynthesis has none). BioLean cannot hand structure to the ontologies; it must state it.

## 6. Ten instructive claims

Ids drop the chapter prefix (molbio, photo, body, repro, inherit, energy).

| id | kind / bin | claim | lean | lesson |
|---|---|---|---|---|
| molbio m45475-112 | effect / now | NER corrects thymine dimers | `Claim.effect ner .neg (.amount thymineDimer)` | the clean case |
| photo m45448-42 | effect / now | photosynthesis produces sugar | `Claim.effect photosynthesis .pos (.amount sugar)` | body-b rebinned this shape to has_output: bins differ by file |
| body m45537-204 | effect / missing | gonads produce steroid hormones | `-- needs has_output: gonad has_output steroidHormone` | "produces" is RO, not an effect |
| repro m45462-47 | effect / with_context | damaged p53 in cancer cells cannot trigger cell death | `Claim.inContext {cellType := some neoplasticCell} (.noEffect mutantP53 (.process cellDeath))` | context plus negation |
| inherit m45467-121 | effect / with_context | X inactivation makes sex chromosome aberrations milder | `Claim.inContext {taxa:[human]} (Claim.mediatedBy sexChromosomeAneuploidy .pos (.phenotype milderEffects) (.process xInactivation))` | ungroundable phenotype |
| body m45536-81 | structural / with_context | vertebrate circulation is closed-loop | `Claim.inContext {taxa := [vertebrata]} (Claim.hasQuality circulatorySystem closed)` | context also needs hasQuality |
| body m45535-266 | structural / missing | colon = ascending + transverse + descending | `Claim.hasPart colon ascendingColon  -- proposed` | the 13% family |
| energy m45440-77 | definitional / missing | fermentation regenerates NAD+ after glycolysis | `-- ontology layer: GO:0006113` | a definition |
| energy m45439-21 | quantitative / missing | two carbons enter the TCA cycle per acetyl | `-- proposed: Claim.quantity` | stoichiometry premise |
| energy m45437-177 | process_description / missing | after catalysis an enzyme releases products and repeats | `-- proposed: ordered steps bind -> catalyze -> release` | processes need order |

## 7. What this says about the core

The signed-effect core holds 8.8% of the textbook. Even with Context it holds 21%, so effects are a minority dialect of biology, not its grammar. The missing 79% is not exotic: is_a, part_of, quantity, location, function and order are 69% of it, and every one is a standard RO/OBO relation. GO and UBERON hold only 15% of these as axioms, so BioLean must state them as Claims itself, not defer to the ontologies. The derivation study gives the same answer from the other side: chaining works, but 24 of 52 proofs die because structural facts cannot be premises, and 13 more die because numbers cannot be. Next step: add structural `Claim` constructors and `Claim.quantity`, plus bridge rules (`inputPositive`, `outputPositive`, `inheritIsA`) into the existing chain rules. That buys more than any further work on effects.

## 8. The story, with examples

Written after the run, as the narrative a short paper would tell: "ontologising A-level biology".

**The ontologies name everything.** 93 percent of entity mentions ground, and where an ontology
fits, grounding is near total: GO 98.7, UBERON 99.3, CL 99.7, SO 99.7, ChEBI 97.3. The misses are
nouns with no home ontology: "living things", "nutrients", "stiffness", "a sugary drink". The
vocabulary of an introductory textbook is, to within a few percent, already a controlled
vocabulary. That part of the problem is solved.

**The ontologies state almost none of the relations.** Of 240 sampled structural and definitional
claims, 15 percent are logical axioms in GO, UBERON, CL or ChEBI, and nearly all of those are
UBERON partonomy (heart has atria, adrenal gland has cortex and medulla). GO:0015979
photosynthesis has no logical axioms beyond "is_a metabolic process": no has_input carbon
dioxide, no has_output oxygen, no occurs_in chloroplast. The textbook says all three in one
sentence. Another 26 percent are stated only in the definition text, in English, where no reasoner
reads them: "the Calvin cycle uses ATP and NADPH" is in GO's definition and in no axiom. So the
textbook is mostly the ontology's own relations, written out in prose that the ontology never
formalised. Canon is in the definitions, not the logic.

**Signed effects are a dialect, not the grammar.** BioLean's `Claim.effect` holds 8.8 percent of
the claims. Even restricted to kind=effect it holds only a third, because "the gonads produce
steroid hormones" (`body:m45537-204`) and "photosynthesis produces sugar" (`photo:m45448-42`) are
RO has_output, not a signed influence, and the verifiers split on how to bin them. The schema was
built on pharmacology, where everything is an agent raising or lowering a target. Cell biology is
mostly what is part of what, where it happens, and in what order.

**The missing constructors are six ordinary relations.** is_a (882 claims: "a cell is the smallest
unit of a living thing"), part_of and has_part (498: "the colon consists of ascending, transverse
and descending colon"), quantity and comparison (422: "prokaryotic cells are smaller than
eukaryotic cells"; "two carbons enter the TCA cycle per acetyl"), located_in and occurs_in (269:
"epithelial cells cover the organs and body cavities"), capable_of (257: "epithelial cells protect
the surface of the body"), and sequence (245: "the centrosome replicates before the cell
divides"). Together they are 69 percent of what is missing. Nothing exotic appears until item 11,
negation ("a prokaryotic cell lacks a nucleus", 85 claims).

**The chain core is right, but starved.** Fifty-two textbook sentences follow from others. Four
type-check in the current Lean, all hormone feedback loops:

- "A rise in blood glucose after a meal triggers adjustments that lower blood glucose"
  (`body:m45534-23`) = `viaAmount` of "glucose raises insulin" and "insulin lowers glucose";
  positive times negative is negative.
- "Blood calcium level is maintained homeostatically" (`body:m45534-5`) = `both` of the calcitonin
  chain and the PTH chain, with no shared axioms.
- "Hormone production and release are primarily controlled by negative feedback"
  (`body:m45537-255`): thyroid hormone lowers TSH, TSH raises thyroid hormone, so thyroid hormone
  lowers itself. One instance of a general law.

Twenty-four of the 52 are blocked solely because structural claims are not Claim constructors;
13 because there is no numeric claim with an arithmetic side goal, which Lean discharges by
`norm_num`. Chemiosmosis (`energy:m45439-129`) is the `generalize` rule from case study 4 running
over cellular component rather than taxon: ATP synthase makes ATP from a proton gradient in
thylakoids and in mitochondria, so "across a membrane" with no component.

**Proof catches the book overclaiming.** "More than one codon corresponds to a given amino acid"
(`molbio:m45479-93`): 61 sense codons onto 20 amino acids gives, by pigeonhole, that *some* amino
acid has several codons, not that a given one does. "A tortoiseshell cat has to be female"
(`inherit:m45467-66`): the proof needs "males have one X", which the book's own XXY sentences
(`-73` to `-75`) contradict. Fill the hole with the true premise and the theorem is "a
tortoiseshell cat has two X chromosomes". Both are places where formalising a textbook sentence
improves it.

**Holes are hypotheses.** Eight sentences look derivable and are not. The smallest hole: "a sugary
drink stimulates the pancreas to produce insulin" (`body:m45537-52`) needs only "a sugary drink
raises blood glucose", which no sentence states; add it and the derivation type-checks today. The
best ILP target: three sentences, high-secretion cells have abundant Golgi, muscle cells have many
mitochondria, immature red cells are rich in ribosomes (`cell:m45432-155, -203, -189`), share one
missing clause, `abundant(cell, organelle) ← capable_of(organelle, F) ∧ highDemand(cell, F)`. One
induced rule explains three textbook sentences. Endosymbiosis (`cell:m45432-260`) is a different
shape: the shared features of mitochondria and bacteria are predictions of the hypothesis, not
premises for it, so the right machinery is `Statement.predictedBy` with a rival to compare against,
not a derivation.

**What a paper would claim.** An introductory biology textbook is (a) almost entirely groundable
in existing open ontologies, (b) almost entirely *not* already formalised in them, and (c) 70
percent expressible with six Relation Ontology predicates added to a signed-effect core, with
(d) a measurable fraction of its sentences being theorems of the others, some of which the proofs
sharpen. Every number here is recomputable from `data/textbook/claims/*.json` with
`scripts/textbook/aggregate.py`; the derivations are in `docs/textbook-derivations.md`, the
axiom check in `docs/textbook-axioms.md`.
