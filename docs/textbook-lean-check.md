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
