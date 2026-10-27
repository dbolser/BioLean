# RO chain fix: regression test

Does fixing the seven bad RO chains (rows 14, 16, 79, 87, 88, 89, 90 in `docs/ro-chains.md`) break anything else? Short answer: no. No inferred TBox axiom changes, RO stays consistent and coherent, and the fixed chains give the intended inferences on test data. Issue drafts: `docs/ro-issues.md`.

Input: `data/ro.owl`, release 2026-09-04. ROBOT 1.9.11, Java 11. Work dir `/tmp/ro-fix/`, scripts in `/tmp/ro-scripts/`.

Note on IDs: in ro.owl, 'starts with' is RO_0002224 and 'ends with' is RO_0002230. RO_0002223 ('starts') and RO_0002229 ('ends') are their inverses.

## Variants

All variants were made by editing the OFN conversion of ro.owl line by line (`/tmp/ro-scripts/fix.py`). The 7 bad axioms have no axiom annotations, so nothing else is lost.

| file | change |
|---|---|
| `ro.ofn` | unmodified (`robot convert` of ro.owl) |
| `ro-fixed.ofn` | the task's fix. Delete rows 14, 16, 79, 87-89. Row 90 becomes `RO_0002234 o inverse(RO_0002233) -> RO_0002413`. Add 4 neg∘pos / pos∘neg chains to RO_0002409: `2409 o 2629`, `2629 o 2409`, `2630 o 2629`, `2629 o 2630` |
| `ro-fixed-retarget.ofn` | as ro-fixed, plus the 3 neg∘neg chains moved to RO_0002407 (`2409 o 2630`, `2630 o 2409`, `2630 o 2630` -> indirectly positively regulates) |
| `ro-fixed-notrans.ofn`, `ro-fixed-retarget-notrans.ofn` | as above, minus `TransitiveObjectProperty(RO_0002409)` (transitivity is also neg∘neg -> neg) |

## (a, c) Reasoner diff, TBox

Generators: SubClass, EquivalentClass, DisjointClasses, ClassAssertion, PropertyAssertion, SubObjectProperty, EquivalentObjectProperty, InverseObjectProperties, ObjectPropertyDomain, ObjectPropertyRange. `--include-indirect true --create-new-ontology true`.

| reasoner | variants | inferred axioms | diff vs unmodified | time |
|---|---|---:|---|---|
| ELK | all 5 | 3,153 (2,991 SubObjectPropertyOf, 61 SubClassOf, 100 ClassAssertion) | **none** (files byte-identical) | ~12 s |
| JFact (SubClass, EquivalentClass, SubObjectProperty) | ro, ro-fixed, ro-fixed-retarget, ro-fixed-retarget-notrans | 5,066 (5,004 SubObjectPropertyOf, 61 SubClassOf) | **none** | 51-197 s |
| HermiT, full generator list | ro, ro-fixed, ro-fixed-notrans | - | did not finish within 600 s (timeout, exit 124) | >10 min |
| HermiT, SubClass + EquivalentClass only | ro, ro-fixed | - | did not finish within 15 min | >15 min |
| JFact, full generator list | 4 variants | - | did not finish within 25 min (stopped) | - |

So HermiT was skipped under the 10-minute rule, and JFact (full SROIQ, same OWL API interface) was used in its place for the DL check.

ELK does not see two of the changed axioms: row 79 and the fixed row 90 both use ObjectInverseOf, which ELK drops. ELK also ignores InverseObjectProperties, so `location of` is not linked to `located in`. JFact does handle inverses.

Why there is no diff: removing a chain only changes inferences where the chain fires. In RO's TBox no named class is defined with any of the affected properties. The property hierarchy also comes from SubObjectPropertyOf axioms, not from chains. So the chains only matter for data (ABox) and for class expressions in downstream ontologies.

**Every axiom that appears or disappears.** Inferred: none, under either ELK or JFact. Asserted (ro-fixed vs unmodified):

```
- RO_0001025 'located in' o inverse('located in')            -> RO_0002379 'spatially coextensive with'
- RO_0002224 'starts with' o RO_0002230 'ends with'           -> RO_0002087 'immediately preceded by'
- RO_0002230 'ends with' o RO_0002224 'starts with'           -> RO_0002090 'immediately precedes'
- RO_0002234 'has output' o RO_0002233 'has input'            -> RO_0002413 'provides input for'
- RO_0002409 'indirectly neg reg' o RO_0002630 'directly neg reg' -> RO_0002409
- RO_0002630 'directly neg reg' o RO_0002409 'indirectly neg reg' -> RO_0002409
- RO_0002630 'directly neg reg' o RO_0002630 'directly neg reg'   -> RO_0002409
+ RO_0002234 'has output' o inverse(RO_0002233 'has input')   -> RO_0002413
+ RO_0002409 o RO_0002629 'directly pos reg'                   -> RO_0002409
+ RO_0002629 o RO_0002409                                      -> RO_0002409
+ RO_0002630 o RO_0002629                                      -> RO_0002409
+ RO_0002629 o RO_0002630                                      -> RO_0002409
```

## (d) Consistency and coherence

`robot reason` stops with an error if the ontology is inconsistent or has unsatisfiable classes. Every ELK and JFact run above exited 0, so all variants are consistent with no unsatisfiable classes, before and after.

OWL 2 DL profile (`robot validate-profile --profile DL`): ro, ro-fixed, ro-fixed-retarget and ro-fixed-retarget-notrans are all in profile, so the chains are regular. A test variant that adds `RO_0002407 o RO_0002630 -> RO_0002409` (indirect pos then direct neg) fails with "Use of property in chain causes cycle", because it clashes with the existing `RO_0002409 o RO_0002409 -> RO_0002407`. So that chain cannot be added.

## ABox test (does the fix do the right thing?)

Since the TBox diff is empty, I asserted the textbook instances as individuals (`/tmp/ro-fix/abox/abox.ofn`). For each variant I took a STAR module over the 16 affected properties (~380 logical axioms, with RO's metadata individuals removed), merged in the test data, and ran HermiT (PropertyAssertion, ~2-3 min each). Asserted facts:

```
wound_healing starts_with hemostasis; hemostasis ends_with fibrin_clot_formation
mitotic_cell_cycle ends_with M_phase; M_phase starts_with prophase
heart located_in thoracic_cavity; left_lung located_in thoracic_cavity
insulin_receptor directly_pos_reg Akt; Akt directly_neg_reg GSK3; GSK3 directly_neg_reg glycogen_synthase
PTEN indirectly_neg_reg Akt; GSK3 indirectly_neg_reg glycogen_biosynthesis
glycolysis has_output pyruvate; PDH_reaction has_input pyruvate
```

Inferred facts on the affected properties:

| inference | unmodified | ro-fixed | retarget + no transitivity |
|---|---|---|---|
| wound_healing immediately_preceded_by fibrin_clot_formation | yes (wrong) | no | no |
| mitotic_cell_cycle immediately_precedes prophase | yes (wrong) | no | no |
| heart spatially_coextensive_with left_lung (both ways) | yes (wrong) | no | no |
| heart / left_lung coextensive with itself | yes | no | no |
| Akt indirectly_NEG_reg glycogen_synthase / glycogen_biosynthesis | yes (wrong) | no | no |
| PTEN indirectly_NEG_reg GSK3 | yes (wrong) | no | no |
| PTEN indirectly_NEG_reg glycogen_synthase / glycogen_biosynthesis | yes | no | no |
| PTEN indirectly_POS_reg glycogen_synthase / glycogen_biosynthesis | yes, both signs at once | no | no |
| insulin_receptor indirectly_NEG_reg GSK3 | no | yes (right) | yes (right) |
| insulin_receptor indirectly_POS_reg glycogen_biosynthesis | no | yes (right) | yes (right) |
| insulin_receptor indirectly_NEG_reg glycogen_biosynthesis | no | yes (wrong, from transitivity) | no |
| Akt indirectly_POS_reg glycogen_synthase / glycogen_biosynthesis | no | no (lost) | yes (right) |
| PTEN indirectly_POS_reg GSK3 | no | no | yes (right) |
| insulin_receptor indirectly_POS_reg glycogen_synthase | no | no | yes (right) |
| glycolysis provides_input_for PDH_reaction | no (missed) | yes (right) | yes (right) |
| glycolysis immediately_precedes PDH_reaction (via 2413 ⊑ 2412 ⊑ 2090) | no | yes | yes |

What this shows:
- The task's fix (ro-fixed) removes every wrong inference except one: transitivity of RO_0002409 still gives insulin_receptor *negatively* regulating glycogen_biosynthesis, right next to the correct *positive* one. It also drops neg∘neg at the indirect level completely.
- Retargeting the 3 chains to RO_0002407 and dropping RO_0002409 transitivity gives only correct-sign inferences.
- Still missing (and allowed to be missing): PTEN negatively regulates glycogen synthase (neg∘neg∘neg). Deriving it needs `2407 o 2630 -> 2409`, which breaks regularity (see (d)).
- Unrelated to this fix: in all variants, every direct regulation also yields 'immediately precedes' (Akt immediately_precedes GSK3), through directly regulates ⊑ immediately causally upstream of ⊑ immediately precedes.

## (e) Downstream use (`/tmp/obo/*.obo`, downloaded 2026-10-27)

I mapped each file's Typedef ids to RO via `id:` or `xref: RO:` (Uberon uses shorthand like `immediately_preceded_by`), then counted `relationship:` and `intersection_of:` lines in [Term] stanzas (`/tmp/ro-scripts/obocount.py`).

| property | go.obo | uberon.obo | cl-basic.obo |
|---|---|---|---|
| RO_0002087 immediately preceded by | 0 | 8 rel (stage succession: larval←embryo, 2-cell←zygote, ...) | 0 |
| RO_0002090 immediately precedes | 0 | 0 | 0 |
| RO_0002379 spatially coextensive with | 0 | 0 | 0 |
| RO_0002407 / 2409 / 2629 / 2630 | 0 | 0 | 0 |
| RO_0002413 provides input for | 0 | 0 | 0 |
| chain inputs: starts with; ends with | 0 | 14 rel + 8 ix; 6 rel | 0 |
| chain inputs: located in | 0 | 184 rel + 55 ix | 0 |
| chain inputs: has input / has output | 0 | 0 | 0 |

The bad chains are also copied into downstream files:
- `uberon.obo` has its own `holds_over_chain` copies: `immediately_preceded_by: starts_with ends_with`, `RO:0002090: ends_with starts_with`, and `RO:0002413: RO:0002234 RO:0002233`, the last with the same missing inverse.
- `go.obo` has only `positively_regulates: negatively_regulates negatively_regulates`, which is correct.

Do the chains fire downstream (class level, with is_a inheritance; `/tmp/ro-scripts/pairs.py`)?
- starts_with ∘ ends_with, ends_with ∘ starts_with in Uberon: **0 pairs**. Uberon's 8 'immediately preceded by' links are asserted, so the fix does not touch them.
- located_in ∘ location_of in Uberon: **67 pairs**, so the bad RO_0002379 chain entails 67 false existentials. 65 have the form "X spatially coextensive with some 'organism substance'" (X = tracheobronchial lymph node, mediastinal fat pad, nasal turbinal, ...). 2 are reflexive (fluid ~ itself). Only DL reasoners see these. ELK `materialize` on uberon+RO, before and after, shows no change because ELK drops the inverse.
- has_output ∘ has_input: 0 pairs anywhere.
- ELK `robot merge ... materialize --term` (the 6 affected properties), before vs after, for go, uberon and cl: **no change** (uberon 8 = 8 asserted, go 0, cl 0).

Who actually depends on these axioms: no class-level content in GO, Uberon or CL. The regulation and provides-input-for chains matter for instance data, mainly GO-CAM models, which use directly positively/negatively regulates and provides input for between activities. Those models are not covered by these files.
