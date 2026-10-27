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
