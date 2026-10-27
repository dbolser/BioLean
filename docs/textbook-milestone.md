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
