# Programs of work

One program per open decision. For each, Dan chose "more research needed". A program lays out the
options and runs a stress set of sourced cases on today's core. None changed the core. What the core
is, and every change the programs propose, is in [../formal-system.md](../formal-system.md).

Updated 2026-11-01.

## Summary

- **13 programs, 906 stress cases run on today's core** (plus 8 prototype-only rows). Program 01's
  33 cases were predicted, not run; 01b ran them.
- **Across all of them: 263 PASS, 161 FAIL, 406 SILENT, 76 INEXPRESSIBLE.** Most SILENTs are one
  program (04, seeded errors). The counts mean different things in each program, so compare
  within a row, not across rows.
- **Not yet committed:** 10b and 10c (docs, data, scripts, Lean). Their Lean files compile alone
  (checked 2026-11-01) but are not build roots in `lakefile.toml`. This file and
  `../formal-system.md` are not committed either.

## How to read the marks

| mark | means |
|---|---|
| PASS | the right conclusion |
| FAIL | a wrong conclusion |
| SILENT | no conclusion where one is due |
| INEXPRESSIBLE | the case cannot be stated |

Counts are for today's core, from each `data/stress/NN/cases.tsv` (07: two sets, `cases.tsv` 32 and
`sheet_cases.tsv` 59, so 91 cases).

## All programs

| program | decision | the question | status | PASS | FAIL | SILENT | INEXPR. | headline |
|---|---|---|---|---:|---:|---:|---:|---|
| [01](01-universals-and-descent.md) | 1: instances to universals | How do instances become a universal, and what may narrow one? | written 2026-10-29; E0 to E2 run | 4* | 6* | 22* | n/a | False universals come from free narrowing and dropped context, not from `generalize`. Dan leans to option (k), descent as a default |
| [01b](01b-descent-sketch.md) | 1, follow-up | Does option (k) hold up when run? | reviewed 2026-11-01 | 19 | 7 | 43 | 16 | (k) is right on 26 of 33 (25 scored fairly) only if a record defeats the default; 11 if they fuse. Not ready to build: weights on a knife edge |
| [02b](02b-feedback-loops.md) | 2, follow-up (decided: a loop is a claim) | What breaks when the loop claim meets the textbook? | reviewed 2026-11-01 | 15 | 15 | 14 | 12 | The core still proves "glucose lowers blood glucose". Choice left: a loop sign plus regulators |
| [03](03-rivals-and-hypotheses.md) | 3: rivals and hypotheses | Rivals double-count and hypotheses weigh 0: which formal system for rivals? | reviewed 2026-10-30 and 2026-10-31 | 10 | 14 | 14 | 3 | Enter each item once: FAIL 14 to 1, no core change, but the M2 exit theorem then fails. Choice: a withdrawal year |
| [04](04-annotation-errors.md) | 4: annotation errors | How many annotation errors do we catch, and which check is cheapest? | reviewed and re-run 2026-11-01 | 65 | 0 | 231 | 3 | Catches 1 in 10 seeded errors, silent rather than wrong. The GO taxon lint finds the most real errors (about 42), outside the core |
| [05](05-grade-terms.md) | 5: grade terms | How do we say prokaryote, protist, algae, invertebrate? | reviewed 2026-10-31 | 9 | 11 | 18 | 9 | GO's union class brings archaea back with 3 statements, no core change. Protist and invertebrate are classes nowhere |
| [06](06-opposition.md) | 6: opposes | Should "opposes" be a relation? | reviewed 2026-10-31 | 26 | 4 | 13 | 4 | No: the flip rule is wrong 20 times in 35. Two real holes found: "amount of" takes anything; antagonists chain badly |
| [07](07-triviality-threshold.md) | 7: IC threshold | Where do we cut trivial derived facts? | reviewed 2026-10-31; no human rating yet | 41 | 29 | 17 | 4 | Keep 2.5; it is not robust and rests on LLM stand-ins. Next: Dan rates the sheet, about 2 hours |
| [08](08-schema-gaps.md) | 8: schema gaps | How do we say "or", "about n", and two states at once? | reviewed 2026-10-31 | 11 | 20 | 10 | 9 | Commonest failure is false exactness: 20 of 22 "about" numbers stored as exact. A union entity covers most "or"s |
| [09](09-chemiosmosis-real-record.md) | 9: illustrative items | Does chemiosmosis win on the real record? | reviewed 2026-10-31 | 12 | 23 | 6 | 9 | No: Slater is never refuted. A dated retirement list fixes it with zero margin. The direction of two 1966 letters is from memory |
| [10a](10a-evidence-weights.md) | 10, part 1: weights (M6) | Are the weights right, and what should M6 test? | reviewed 2026-10-31 | 19 | 22 | 5 | 5 | Only "drop retracted papers at import" is safe. The M6 exit test passes today and tests nothing new |
| [10b](10b-literature-at-scale.md) | 10, part 2: literature (M8) | Can curated sources come in at scale? | reviewed 2026-11-01; not committed | 18 | 14 | 19 | 1 | The core is not the blocker; import is where errors get in. Metformin extends human lifespan: unsupported, 0.12 |
| [10c](10c-rule-induction.md) | 10, part 3: rule induction | Can BioLean learn rules, and where would they live? | reviewed 2026-11-01; not committed | 18 | 2 | 16 | 1 | Right on deduction, silent where a rule is needed. Learners are weak. Choice: a core `Rule` type, or learners outside |
| **all run** | | | | **263** | **161** | **406** | **76** | 906 cases; 01 not included |

\* Program 01: predicted on 33 cases for option (c), which is today's core; one more case reads
contested. 04 has 4 more rows run on prototypes only (3 PASS, 1 FAIL); 05 has 4.

## Where the files are

| program | stress (today's core) | prototype | data |
|---|---|---|---|
| 01 | `BioLean/Examples/Transcription.lean` (E1) | none | `data/textbook/false_as_written.tsv` |
| 01b | `BioLean/Stress/Descent.lean` | Python sketch | `data/stress/01b/` |
| 02b | `BioLean/Stress/Feedback.lean` | `BioLean/Proto/Feedback.lean` | `data/stress/02b/` |
| 03 | `BioLean/Stress/Rivals.lean` | `BioLean/Proto/Multinomial.lean` | `data/stress/03/` |
| 04 | `BioLean/Stress/AnnotationErrors.lean` | inside the stress file | `data/stress/04/` |
| 05 | `BioLean/Stress/GradeTerms.lean` | `BioLean/Proto/TaxonUnion.lean` | `data/stress/05/` |
| 06 | `BioLean/Stress/Opposition.lean` | `BioLean/Proto/Opposes.lean` | `data/stress/06/` |
| 07 | none (Python only) | none | `data/stress/07/` |
| 08 | `BioLean/Stress/SchemaGaps.lean` | `BioLean/Proto/SchemaGaps.lean` | `data/stress/08/` |
| 09 | `BioLean/Stress/ChemiosmosisReal.lean` | inside the stress file | `data/stress/09/` |
| 10a | `BioLean/Stress/Weights.lean` | inside the stress file | `data/stress/10a/` |
| 10b | `BioLean/Stress/Literature.lean` | inside the stress file | `data/stress/10b/` |
| 10c | `BioLean/Stress/Induction.lean` | `BioLean/Proto/Induction.lean` | `data/stress/10c/` |

## Choices waiting for Dan

One line each; the program doc has the detail.

| program | choice |
|---|---|
| 01, 01b | build descent with defeat later, or not; first fix the weights (E14) and check the losses are on record (E10b) |
| 02b | a loop sign plus regulators in the core, or loops stay data |
| 03 | a withdrawal year: a field on `Evidence`, or a table beside the core |
| 04 | finer relation signatures: a lint, or a core change that stops 25 statements compiling |
| 05 | GO's union class as data now; core grades later, if at all |
| 06 | keep two signed effects per effector; add the amount lint outside the core |
| 07 | rate the 100-row sheet |
| 08 | run E1 to E3; then intervals, `unionSubj` and `transport2` |
| 09 | read the two 1966 letters; agree the retirement list; restate the M2 exit at 1978 |
| 10a | drop retracted papers at import; rewrite the M6 exit test |
| 10b | a rule across organism conditions, or diabetic evidence never informs the healthy |
| 10c | learned rules in the core (C) or outside it (F) |

Three programs want the same end year on `Evidence` (03, 09, 10a). Decide it once:
[../formal-system.md](../formal-system.md), section 4.2.
