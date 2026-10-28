# M2 context: judgement of the three designs

**Recommendation: adopt refinement (design B), hardened, with protocol fields on Evidence.** The
hybrid hypothesis is right about where things go, but wrong to split by field name. Most textbook
"conditions" belong to the claim, not to the experiment.

## 1. Soundness, checked in the Lean

| test | wrapper (A) | refinement (B) | evidence (C) |
|---|---|---|---|
| S1 no silent fusion | type-level: context is in the `Claim` index; `both` cannot join | type-level: context is in the subject entity's curie; `both` cannot join | **evaluation-level only**: claim is bare, `both(mouse, human)` type-checks; an untagged item counts as universal and fuses (builder showed b=0.888) |
| S2 transport weighted | needs `.transport` warrant, checks sibling taxa (`transportOK`), warrant listed in `axioms` | needs `.crossSpecies` item, listed in `axioms`; **only checks `T1 ≠ T2`**, so mouse to Mammalia is allowed (discounted generalisation) | fixed 3/10 weight, sibling check, but **no warrant and not listed in `axioms`** (`.transport _ _ d => d.axioms`) |
| S3 free specialisation | `specialise`, lossless (`rfl`) | `refineMono` + is_a laws; capped by the 0.9 ontology-axiom weight via `weakest` | query-side subsumption, lossless |
| S4 no free widening | yes | yes; is_a laws push down only | yes |
| S5 conditions separate | yes, but `clash` cannot see inside a context | yes, different subjects | yes in each context, but the bare claims look contradictory |
| holes found | `contextualise` nests (`inContext h (inContext m c)` is legal); old rules blind to contexts | refine order and RO domain unchecked (fail safe); transport upward | per-item tag discipline; transport invisible to audit |

All three share one hole: a curator can put mouse evidence on a context-free claim. In A and B that
mistake is one visible decision per claim and shows in the printed claim. In C it is one invisible
decision per evidence item, and it already happened in the real data (m45466-103 became universal).
By the stated rule, **C loses**. A and B both pass.

## 2. Data fit (190 claims)

Context fields by claim constructor:

| field | total | effect | rel | notRel | where it actually sits |
|---|---|---|---|---|---|
| taxon | 98 | 23 | 69 | 6 | the whole claim; it refines the subject |
| anatomy | 50 | 41 | 9 | 0 | usually locates **one participant** ("blood glucose", "neurogenesis in hippocampus") |
| cellType | 25 | 10 | 14 | 1 | 10 are taxon proxies (eukaryotic, prokaryotic, animal, plant cell); 15 locate a participant |
| condition | 37 | 20 | 17 | 0 | see below |

The 37 conditions, by hand:

| kind | n | examples | belongs on |
|---|---|---|---|
| environment / physiological state | 9 | hypotonic, hypertonic, insufficient oxygen, hot dry day, excess food intake, glycogen stores full | claim (subject) |
| genotype / perturbation | 7 | defective NER genes, telomerase-deficient, zygote missing an autosome, tortoiseshell cats | claim (organism) |
| disease | 4 | celiac disease, rheumatoid arthritis | claim (organism) |
| stage | 3 | early female embryos, developing seed cells, telophase I | claim |
| quantifier or taxon leak | 7 | some cancer cells, some organisms, single-celled eukaryotes, also humans and birds | `Claim.quant` or taxon, not context |
| precondition | 7 | checkpoint not met, DNA damage cannot be repaired, only if nuclear envelopes formed | a conditional claim; out of M2 scope |
| **experiment protocol (dose, duration, strain, in vitro)** | **0** | | Evidence |

| field kind | A wrapper | B refinement | C evidence |
|---|---|---|---|
| taxon | natural | natural (`in_taxon`, RO:0002162, as GO taxon constraints use) | natural |
| anatomy | claim-wide; cannot say *which* entity is in blood | natural: refines the located entity | wrong level: textbook claims have no experiment |
| cellType | claim-wide | natural | wrong level |
| condition | free text, exact match | entity via RO; placement forced for disease (`drug ⊓ has_modifier RA`) | free text on evidence; "cell swells" vs "cell shrinks" become bare rivals |
| protocol | none | Evidence fields (dose, duration, strain, `ExpSystem`) | Evidence fields |

Split by **what the field qualifies**, not by its name.

## 3. Cost

| | A | B | C |
|---|---|---|---|
| new constructors | 2 (`Claim.inContext`, `EvidenceKind.transport`) | 1 (`EvidenceKind.crossSpecies`), plus `ExpSystem` | 1 (`Derivation.transport`), plus `Ctx`, `ContextModel` |
| new rules | 3 | 3 (one, `isaInheritEffect`, was already open in STATUS) | 1 |
| core lines | 158 | 71 | 281 (+233/-48) |
| existing rules changed | 0, but every old rule needs a same-context lift | **0**; old rules see through refined entities | all 16 `opinion` clauses take a query |

## 4. Elegance and reuse

| | A | B | C |
|---|---|---|---|
| is_a laws | not used; private 19-edge table | used directly (`refineAxiom` + `relChain`) | not used; private ancestor table |
| RO | no | yes (`in_taxon`, `located_in`, `has_modifier`, `surrounded_by`, `happens_during`) | no |
| chains across contexts | blocked (`viaAmount` cannot take an `inContext` premise) | work: `isaInheritEffect` lifts a bare NAD+ effect to `NAD+ ⊓ liver`, then `viaAmount` | one query per derivation, so cross-tissue chains fit no query |

## 5. The hybrid hypothesis

**Supported, with one change.** The hypothesis is design B as built. Textbook `condition` is
claim-level 23 of 37 times, a misfiled quantifier 7 times, a precondition 7 times, and protocol
0 times. So conditions must be refinable entities, not Evidence text. Evidence keeps only
protocol, which does not split claims.

## 6. Design to implement (one page)

**Types**

| item | definition |
|---|---|
| `Entity.refine e r f (h : r.accepts k k' = true := by decide)` | B's `e ⊓ ∃r.f`, bracketed filler curie, **plus an RO domain check** |
| `structure Ctx` | `taxon, anatomy, cellType, component, stage, condition : Option Entity` (condition is an Entity: PATO, ENVO, MONDO, or `BLN:` placeholder) |
| `Entity.inCtx e (c : Ctx)` | the only public way to refine. Applies fields in the fixed order anatomy, cellType, component, condition, stage, taxon, each with a fixed relation, so one context gives one curie |
| organism state | disease, genotype, age and diet refine the **taxon filler** (`in_taxon (human ⊓ has_disease celiac)`), not the drug or the microvillus. This fixes B's forced cases T12 and T23 |
| `Evidence` | add `dose, duration, strain : Option String`, `system : Option ExpSystem`, `taxon : Option (Entity .taxon)` |
| `EvidenceKind.crossSpecies` | weight 3/10 |

**Relations used by `inCtx`:** taxon `in_taxon` RO:0002162; anatomy and component `located_in`
RO:0001025, or `occurs_in` BFO:0000066 for processes; cellType `part_of` or `occurs_in`; stage
`happens_during` RO:0002092; organism condition `has_modifier` RO:0002573; environment
`surrounded_by` RO:0002219.

**Rules** (3, none changed)

| rule | statement | opinion |
|---|---|---|
| `refineMono` | f is_a g ⊢ e ⊓ ∃r.f is_a e ⊓ ∃r.g | same |
| `isaInheritEffect` | a is_a b, b →s t ⊢ a →s t | `weakest` |
| `transport` | effect on `a ⊓ in_taxon T1` ⊢ same on `a ⊓ in_taxon T2`, **T1, T2 siblings** (neither is_a the other), `.crossSpecies` item required and listed in `axioms` | `chain` |

Make the refinement axiom lossless: give `refineAxiom` its own evidence kind at weight 1, since
it is true by definition. Then S3 is exact, not capped at 0.9.

**Lint** (decidable, not kernel-enforced): `Statement.taxonConsistent`. If any evidence item sets
`taxon`, the claim's subject must carry an `in_taxon` filler that the evidence taxon is_a. This
narrows the shared S1 hole to evidence that has no taxon at all.

**Coverage of the 190**

| group | n | covered? |
|---|---|---|
| taxon | 98 | yes |
| cellType as taxon proxy | 10 | yes, remapped to NCBITaxon (eukaryotic cell to Eukaryota, and so on) |
| cellType locating a participant | 15 | yes |
| anatomy | 50 | yes, on the located entity |
| conditions: environment, stage, disease, genotype | 23 | yes, as entities; about 8 need `BLN:` placeholders |
| conditions: quantifier or taxon leaks | 7 | not context; re-encode with `Claim.quant` (M3) or a taxon |
| conditions: preconditions | 7 | **no**; need conditional claims (later milestone) |
| no context | 5 | bare claim, or `quant .some` (m45466-103) |
| also lost, unrelated to context | about 4 | "only" (T21, T32), "and some fungi" (T30), onset "early in life" (T14) |

About 176 of 190 (93 percent) are covered as context.
Import the is_a data (NCBITaxon, CL, UBERON, GO) like `RO.lean`; all designs use hand tables now.
