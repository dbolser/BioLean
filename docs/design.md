# BioLean: design and scope

Written 2026-10-23. Companion to [related-work.md](related-work.md).

## 1. The idea in one paragraph

A paper's claim becomes a `Statement`: a typed, ontology-grounded relation plus the
papers that support or deny it. A `Derivation` is a proof-shaped argument that chains
statements into a higher-level claim. Lean checks the shape: every link joins, every
sign composes. The strength is computed separately, as a subjective-logic opinion
(belief, disbelief, uncertainty). Named derivations form a library, biolib, and new
proofs reuse them. `Derivation.axioms` lists the papers a proof rests on, the way
`#print axioms` lists the axioms a Mathlib theorem rests on.

## 2. Framework choice

The question was: what should sit under a proof system whose axioms are weighted
literature statements? Candidates and verdicts:

| framework | what it gives | why not as the core |
|---|---|---|
| Lean 4 + Mathlib | dependent types for claim shape, kernel-checked numbers, a library culture | chosen |
| Probabilistic logic programming (ProbLog, Scallop) | search plus weights in one engine | weights are probabilities, so conflict collapses to one number; no type-checked shape; no library reuse story |
| Markov logic, PSL | soft rules, joint inference | opaque global optimisation, not auditable per proof |
| Bayesian networks | proper probability, causal DAGs | needs a joint model up front; the literature does not supply one |
| Argumentation frameworks (Dung, ASPIC+) | defeat and attack between arguments, competing hypotheses | no strength algebra of its own; a good layer on top later |
| Datalog with provenance semirings | fast derivation search, certified in Lean already | semaglutide-scale search is trivial; add at thousands of statements |
| Nanopublications, BEL | per-statement provenance formats | formats, not reasoners; both communities faded |

Why subjective logic for strength: one piece of evidence is an opinion with some belief
and some uncertainty. Independent items fuse, so belief rises with more papers.
Refuting items add disbelief instead. A claim with both high belief and high disbelief
is **contested**, which is the honest answer when the literature disagrees. INDRA's
belief score is a special case of this, so INDRA's priors can be reused.

Why Lean and not a plain graph: the graph says the edges exist. Lean says the argument
is well-formed and the arithmetic is right, once, for every proof, with a proof term
you can hand to someone. The theorems in `Belief.lean` (a chain is never stronger than
its weakest link; supporting evidence never lowers belief; fusion never raises
uncertainty) hold for every derivation anyone will ever write.

## 3. The core, module by module

| file | contents |
|---|---|
| `BioLean/Belief.lean` | `Opinion` over ℚ with invariants; `fuse`, `chain`, `ofReliability`; the laws as theorems |
| `BioLean/Ontology.lean` | `Kind`, `Entity k` with a CURIE and label |
| `BioLean/Claim.lean` | `Sign` with composition; `Target` (activity, amount, process, phenotype, site); `Claim.effect`, `Claim.mediatedBy` |
| `BioLean/Evidence.lean` | `EvidenceKind`, `Evidence`, `Statement`, swappable `EvidenceModel` weights |
| `BioLean/Derivation.lean` | `Derivation c`, `opinion`, `axioms`, `pmids`, `verdict`, `report`, `Established` |
| `BioLean/Lib/*` | biolib: grounded entities, rendered statements, named derivations |
| `BioLean/Examples/Ozempic.lean` | the question, as theorems checked by `decide +kernel` |
| `biolean/` (Python) | corpus access, Claude extraction, CURIE grounding, Lean emitter |

Numbers in a derivation are exact rationals. `decide +kernel` evaluates them inside the
kernel, so a theorem like `Established claim (95/100)` is a real proof, not a print-out.

## 4. What the demo shows

Claim: semaglutide has a negative effect on feeding behavior (GO:0007631).

1. **Two independent routes fused.** Direct clinical evidence (trials) and a
   mechanistic chain (semaglutide activates GLP1R; GLP1R activity reduces intake).
2. **Sign algebra does real work.** Sitagliptin inhibits DPP4, DPP4 degrades GLP-1, so
   sitagliptin raises GLP-1: two negatives compose to a positive, and Lean checks it.
3. **Mechanism is not magnitude.** The chain predicts sitagliptin should reduce intake.
   The clinical literature says it is weight-neutral. Fusing both gives *contested*.
   This is the failure mode of every sign-only reasoning system, made visible.
4. **Competing hypotheses.** "Nausea mediates the effect" has evidence for and against:
   contested. The top-level claim is unaffected, because the mechanism dispute does
   not touch the clinical route. Central (hypothalamus) versus peripheral (area
   postrema, vagus) is shown the same way.
5. **Evidence trail.** `axioms` and `pmids` list exactly which papers a verdict rests on.

Results from `lake build BioLeanLib` (all theorems check by `decide +kernel`):

| derivation | belief | disbelief | verdict |
|---|---:|---:|---|
| semaglutide reduces feeding (clinical + mechanistic, fused) | 0.968 | 0.000 | established |
| mechanistic route alone (S1 then S2) | 0.805 | 0.000 | established at 0.8 |
| sitagliptin reduces feeding (4-step chain + clinical S8) | 0.365 | 0.585 | contested |
| nausea mediates the anorectic effect (S9a vs S9b) | 0.388 | 0.577 | contested |
| acts centrally via hypothalamus (S9c, mixed) | 0.524 | 0.377 | contested |
| acts via area postrema and vagal afferents (S9d) | 0.909 | 0.000 | established |

The 66 quotes behind the 12 statements were each checked as verbatim substrings of the
cited abstract in the local corpus (`data/demo/curated.json`). The main claim rests on 3
statements and 17 PMIDs; the sitagliptin verdict on 5 statements and 28 PMIDs.

## 5. Known gaps, in order of importance

1. **Independence.** Fusion assumes independent evidence. Papers cite each other and
   reviews repeat trials. Repeated PMIDs are now dropped within a statement, and
   `report` warns when a derivation uses one statement twice. Nothing yet discounts a
   review that restates a trial already counted. INDRA hit the same wall.
2. **Reading reliability versus consensus.** One number per evidence kind mixes "how
   likely the extraction is right" with "how strong the study is". Needs two factors.
3. **Chains hide conflict.** A chain through a contested link reports uncertainty, not
   disbelief. The report should at least list contested axioms.
4. **No context slot.** Species, tissue, dose and condition are missing from `Claim`.
   Most literature contradictions are context differences.
5. **No ontology inference.** "Specific claim supports general claim" via `is_a` is
   absent. It gave INDRA a large share of its support links.
6. **Weights are uncalibrated.** The `EvidenceModel` table is a starting point. ECO
   codes on GOA and GO-CAM edges are the natural calibration key.
7. **Grounding is exact-match only.** Everyday words (hunger, satiety, energy intake) do
   not hit HP or GO labels. The corpus export also has broken synonyms for most
   ontologies, which needs fixing upstream.

## 6. Scope: what it would take

The data already here covers the plan.

| step | input | work | size |
|---|---|---|---|
| Fix the core | gaps 1 to 3 above | Lean, one to two weeks | small |
| Seed biolib from curated sources | GO-CAM (about 1,500 models, ECO codes), SIGNOR (signed, with sentences), Reactome, GOA (1.28M PMID links) | map to `Statement`, write importers in Python | medium |
| Text-mined long tail | PubTator3 relations (on disk; no sentences), Open Targets europepmc (26M sentences) | import as `textMined` evidence with low weight | medium |
| LLM extraction over the corpus | 28.5M abstracts | the pipeline exists; cost drives the design | see below |
| Grounding | 6M OBO terms, 71k UniProt | synonym repair, add Gilda or a fuzzy layer | small |
| Search | thousands of statements | Datalog finds chains, Lean checks them (CertifyingDatalog pattern) | medium |
| Competing hypotheses | contested claims | an argumentation layer over derivations | research |

LLM extraction cost, rough: a PubMed abstract averages 356 tokens. With a 2k-token
system prompt cached, each call is about 0.5k uncached input and about 0.6k output.

| scope | abstracts | Opus 5.5 | Haiku 5.5 |
|---|---|---:|---:|
| GLP-1 sub-corpus | 15k | $300 | $8 |
| one disease area | 500k | $9k | $250 |
| all of PubMed | 28.5M | $500k | $14k |

Haiku-class extraction over everything is tractable; Opus over a disease area is
tractable; Opus over everything is not the first step. The right order is: curated
sources first, text-mined relations second, LLM extraction targeted at the gaps.

## 7. Immediate next steps

1. Compile and run the demo once the Mathlib cache finishes (in progress).
2. Run `biolean extract` on the 15k GLP-1 sub-corpus with a key, compare its
   statements to the curated 12, and measure precision.
3. Import GO-CAM for one pathway as the first non-demo biolib module.
4. Decide the context slot design (species, tissue, condition) before the library grows.
