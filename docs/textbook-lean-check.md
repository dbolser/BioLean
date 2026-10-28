# Lean-checking the textbook

2026-10-27. Every textbook claim binned "now" (expressible in the M1 schema) was emitted as a Lean
`Statement` and compiled. Generator: `scripts/textbook/emit_lean.py`; runner:
`scripts/textbook/check_lean.sh`; modules: `BioLean/Lib/TextbookClaims/*.lean` (kept out of the
library build on purpose: the failures are the finding).

## Numbers

| step | claims |
|---|---:|
| binned "now" after M1 (`aggregate_m1.py`) | 811 |
| emitted as Lean (two grounded entities, supported ontology, parsable Lean) | 702 |
| **compiled** | **570 (81% of emitted, 70% of "now")** |
| rejected by Lean | 132 |

Not emitted: 67 use an ontology with no `Kind` yet (SO sequence features, NCIT, EFO, OBA), 29 have
fewer than two grounded entities, 13 have a Lean string without a sign or target.

| chapter module | statements | rejected |
|---|---:|---:|
| CellStructureAndFunction | 62 | 8 |
| HowCellsObtainEnergy | 59 | 11 |
| MolecularBiology | 60 | 3 |
| Photosynthesis | 80 | 2 |
| ReproductionAtTheCellularLevel | 43 | 10 |
| TheBodySSystemsA | 157 | 62 |
| TheBodySSystemsB | 216 | 32 |
| TheCellularBasisOfInheritance | 25 | 4 |

## What Lean rejected, and who was wrong

| failure | n | typical case | who is wrong |
|---|---:|---|---|
| `.process` target given a non-process entity | 72 | "sweating lowers body temperature" with the target grounded to a PATO quality or an UBERON part | annotator picked the wrong target constructor |
| `.phenotype` target given a GO process | 30 | "exercise increases heart rate" with heart rate as GO:0002027 (a process) | arguable; a PATO/HP term exists |
| `.activity` target given a GO molecular function | 12 | "products inhibit the enzymes that made them", enzyme = GO:0003824 catalytic activity | **our schema**: `Target.activity` wants a protein; a GO function is the honest grounding for "enzymes" |
| RO domain or range violated | 19 | `capable_of mitochondrion ATP` (range must be a process; the claim is `produces`); `precedes centrosome centrosome-duplication` (a thing cannot precede a process) | annotator; Lean's RO typing caught a real mis-annotation each time |

Of the 19 domain/range rejections, 14 are `capable_of` with a chemical as object: "mitochondria
produce ATP", "the ER makes lipids", "peroxisomes break down fatty acids". The right relation is
`produces` (or `has_output` on the process). This is the most common annotator error and it is
exactly the kind the type checker is for.

## What this shows

1. **Type-checking a textbook finds annotation errors at a useful rate.** 132 of 702 statements,
   nearly one in five, had a shape error that a reader would have waved through.
2. **One schema gap is now concrete.** `Target.activity` should accept a GO molecular function as
   well as a protein; 12 claims about "enzymes" need it.
3. **Ontology coverage, not logic, blocks the rest.** 67 claims use SO, NCIT, EFO or OBA, which have
   no `Kind`. Adding `sequenceFeature` would admit most of them.
4. **A Lean test now pins the RO axioms we rely on** (`BioLean/Tests/RO.lean`): the chains the
   textbook derivations use, the inverses, the blocked chains staying blocked, and the domain/range
   sorts. An RO release that changes any of them breaks the build.

## Round 2: Sonnet, structured output (2026-10-27, later)

Round 1's parser had to guess which entity was subject and which was target from Haiku's free-form
Lean strings, which produced most of the 132 rejections. Round 2 re-annotated all 4,695 claims with
Sonnet into structured fields (subject CURIE, RO relation, object CURIE, sign, target, mediator,
context, one of twelve fixed blockers), with OAK's candidate groundings supplied. The emitter
(`scripts/textbook/emit_lean_m2.py`) does no string parsing. Modules: `BioLean/Lib/TextbookClaimsR2/`.

| | round 1 (Haiku, strings) | round 2 (Sonnet, structured) |
|---|---:|---:|
| claims judged expressible | 811 | 1,906 (41%) |
| emitted as Lean | 702 | 1,594 |
| compiled | 570 (81%) | **1,591 (99.8%)** |
| rejected by Lean | 132 | 3 |

The 312 expressible-but-not-emitted claims are 190 that need a context (species or tissue, M2) and
122 whose entities live in ontologies without a `Kind` (PO, ENVO, ECOCORE, NCIT, COB "organism").

Before the schema fix, Lean rejected 22: 20 were `.activity` given a GO molecular function ("enzymes",
"transporters", "receptors"). `Target.activity` now accepts a protein or a GO function, which also
generalised `viaActivity`. The three that remain are real:

| claim | Lean's objection | who is right |
|---|---|---|
| obesity causes type 2 diabetes | `.phenotype` given a MONDO disease | schema: no disease target yet |
| neurotransmitter receptors are located on dendrites | `located_in` with a GO *function* as subject | Lean: an activity is not a thing with a location; needs the receptor protein or complex |
| neurotransmitter binds to receptors | `binds` with a GO function as object | same |

Constructors Sonnet used: rel 1,442, effect 416, notRel 42, mediatedBy 6. Relations: has part 362,
part of 158, is_a 144, capable of 121, has output 108, located in 97, produces 93, has input 92,
occurs in 75, happens during 51. Sonnet changed 138 CURIEs, usually against OAK's more generic
suggestion. Confidence: high 1,542, medium 2,823, low 330.

The 2,789 not expressible, by blocker: other 716, definition only 472, ungrounded entity 448,
quantity 430, process description 382, compound sentence 377, context required 190, unsupported
ontology 164, necessity 117, ordering 106, has quality 76, disjunction 30. Quantity (M3) and
context (M2) are the two schema items; the rest are either the ontology layer (definitions,
process descriptions) or text work (compound sentences, grounding).

## Round 3: quantity and context (2026-10-28, overnight)

The 620 claims that round 2 blocked as needing a quantity (430) or a context (190) were re-annotated against
the M2 context and M3 quantity constructors (`data/textbook/claims_m3/`, field `m3`). Emitter:
`scripts/textbook/emit_lean_m3.py`. Modules: `BioLean/Lib/TextbookClaimsR3/` (lean_lib `TextbookR3`). Skip list:
`data/textbook/r3_skip.tsv`.

Where context goes. Taxon, stage and condition refine the subject with `Entity.inCtx`. Anatomy, cell type and
component refine the entity they locate. The annotation does not say which entity that is, so the emitter uses a
rule: the target of an effect on an amount, process or activity ("insulin lowers blood glucose" refines glucose),
otherwise the subject. The closure needs the same curies, so the emitter's Python copy of `inCtx` was checked
against Lean: all 351 statements give the same subject and object curie.

| step | claims |
|---|---:|
| re-annotated | 620 |
| given a constructor | 425 |
| constructor plus a blocker (a weakening; skipped, as the rule says) | 57 |
| skipped by the emitter: ontology with no `Kind` (NCIT 7, EFO 1, OBI 1), `count` with a relation other than has part (2), `measure` with an open end (1) | 12 |
| emitted | 356 |
| **compiled** | **351 (98.6%)** |
| rejected by Lean | 5 |

All five rejections are of one kind, a context filler of the wrong kind. "Adult" (UBERON:0000113) and "early
embryo" (UBERON:0000068) are UBERON life stages, and `Ctx.stage` is `Entity .process`. The schema is wrong, not the
annotator: a life stage is not a process. There were no target-kind, RO-domain or arithmetic errors, and the
emitter needed no fixes after its first build. The likely reason is that the annotators had already elaborated
their claims in Lean.

Compiled, by constructor: rel 112, effect 66, count 60, measure 48, less 15, cardinality 12, atLeast 12, produces
7, consumes 7, notRel 6, yield 6. 246 use a context (taxon 170, anatomy 55, organism condition 20, cell type 14,
stage 10, component 8, environment 8). 45 are quantified (most 27, some 18).

### The whole textbook

33 of the 351 were already compiled in round 2 as weaker claims, usually "has part" where the sentence gives a
number. Each claim counts once here, in its round-3 form.

| family | round 2 | rounds 2 and 3 |
|---|---:|---:|
| relational (rel, notRel) | 1,290 | 1,376 |
| causal (effect, mediatedBy) | 301 | 366 |
| quantity (count, atLeast, cardinality, measure, less, produces, consumes, yield) | 0 | 167 |
| **compiled, of 4,695 claims** | **1,591 (33.9%)** | **1,909 (40.7%)** |

### Closure and holes

`scripts/search/closure.py` now also loads the round-3 rel, notRel and effect claims, with refined entities as
composite curies. Where round 3 re-annotated a record, its claim replaces the round-2 one. A claim marked some or
most loads nothing, so it does not act as a universal. The IC filter (threshold 2.5) is now the default. The hub
list needs `--hubs`, and `--no-m3` reproduces the earlier run exactly. A refined entity takes the IC of its base
term, which is a lower bound.

| | before (round 2) | after (rounds 2 and 3) |
|---|---:|---:|
| facts asserted | 1,248 | 1,378 |
| derived, novel | 1,551 | 1,606 |
| kept by IC >= 2.5 (default) | 837 | 881 |
| kept by the hub list (`--hubs`) | 1,175 | 1,254 |
| clashes | 2 | 2 |
| holes found | 6,735 | 7,418 |
| holes after screening | 2,172 | 2,611 |
| hypotheses (grouped) | 842 | 1,016 |

- 140 round-3 facts came in. 16 round-2 records stopped asserting. For 10 of them the fact is gone; the other 6
  facts are still asserted by other sentences. "Most neurons contain axons" no longer says it of every neuron.
- 64 derived facts were gained, all about a refined entity; 52 pass IC. 9 were lost. Each one traces to a
  universal that was withdrawn, for example "food has part a structure capable of transmembrane transport",
  which came from "some membrane proteins transport materials".
- There are still 2 clashes. Both now rest on round-2 sentences that round 3 never saw: "some neurons contain no
  axons" (body:m45539-109) and "... no dendrites" (-54) are annotated as universal negations. They need `some`.
- Refined entities are islands: nothing links "glucose ⊓ located in blood" to "glucose". Lean has that link
  (`Entity.refineAxiom`: e ⊓ ∃r.f is_a e), but the closure does not load it. A scratch run with those 129 edges
  gave 2,190 derived facts and 5 clashes. One of the new clashes is a real annotation error. Round 2 turned
  "Animal cells also have a centrosome" (cell:m45432-318) into a claim about every cell, which gives plant cells
  centrioles, against "plant cells lack centrioles" (cell:m45432-75). This was not committed.

Hand-found holes (`docs/textbook-derivations.md`, Reverse): none of the eight was rediscovered.
- G1 and G5 still cannot be expressed (proportion), and quantity claims do not enter the closure anyway.
- G2, G3, G7 and G8 were not in round 3, because quantity or context was not what blocked them.
- G4: -117 is still blocked ("other").
- G6: the sentence now gets four candidate holes through the new blood-glucose and glucagon facts, but none is
  the sugary drink. They are artefacts. "Insulin ⊓ located in blood raises insulin" gets through because the
  reflexive screen compares exact curies, not base terms.

Reproduce:

```
python3 scripts/textbook/emit_lean_m3.py data/textbook/claims_m3 /tmp/obo/go.obo BioLean/Lib/TextbookClaimsR3
lake build TextbookR3
PYTHONHASHSEED=1 python3 scripts/search/closure.py data/textbook/claims_m2 /tmp/obo/go.obo 4
PYTHONHASHSEED=1 python3 scripts/search/holes.py data/textbook/claims_m2 /tmp/obo/go.obo 4
```
