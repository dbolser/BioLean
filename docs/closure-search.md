# Closure search: what follows from the textbook

2026-10-28. First use of the library *as a library*: forward-chain BioLean's rules over the 1,248
compiled textbook statements (round 2) and the 126 enabled RO chains, keep every conclusion with its
derivation, then hand a sample to Lean to certify. Scripts: `scripts/search/closure.py`,
`scripts/search/emit_closure_lean.py`; output `data/search/closure_report.txt`,
`data/search/derivations.json`, `BioLean/Examples/Closure.lean`.

## Numbers

| | |
|---|---:|
| statements loaded (rel 971, notRel 27, effect 250) | 1,248 |
| derived facts, fixpoint at depth 4 | 1,551 |
| after dropping lifts to the 25 hub entities (cell, body, ATP, ...) | 1,175 |
| by rule: transitivity 674, RO chain 460, is_a generalises object 185, is_a inherits 95, viaAmount 73, is_a inherits effect 56, viaActivity 4, notRel inherits 4 | |
| derivations emitted to Lean | 60 |
| **certified by the kernel (shape and `Established`)** | **60 of 60** |
| clashes (a r b and ¬ a r b both derived) | 2 |

## What the search found, in order of importance

**1. Two unsound rules of ours.** The first run produced 19,705 facts including "DNA is_a messenger
RNA" and "salivary glands overlap ganglia". Both came from rules that are valid for individuals,
which is what RO is written for, applied to our claims, which are class-level existentials ("every
nuclear membrane has some phospholipid").
- `relInv`: the inverse of an existential does not follow. Removed from the core. Inverse-direction
  claims must be asserted as such; the gonad example now is.
- the is_a laws applied to is_a itself: "subclass inherits the superclass's relations" must exclude
  the class hierarchy. `RO.chainOK` tightened; tests pin it.
After the fixes the closure is finite (1,551) and a random sample reads like a textbook: prometaphase
is part of the mitotic cell cycle; the rib cage has part bone; the ER membrane has part lipid; the
cell wall has part polysaccharide; DNA-templated transcription termination has output RNA.

**2. The remaining wrong conclusions have two causes, neither a rule.** Over-general subjects from
annotation ("cells have cell walls" without the plant context, so organs acquire cellulose), and junk
groundings ("salivary amylase inhibits binding"). Context (M2) and grounding, again.

**3. Sign chains through feedback are formally right and biologically misleading.** "Glucose
catabolism raises ATP; ATP inhibits sugar catabolism; therefore glucose catabolism inhibits itself."
Each premise is in the book and the sign product is correct. The conclusion describes a regulatory
loop as if it were a one-way effect. 56 of the 73 `viaAmount` conclusions pass through the ATP
feedback statement. This is the "mechanism is not magnitude" limit from the Ozempic demo in its
cleanest form: static sign algebra cannot represent a loop. A `Claim.loop` or a dynamics layer is
the honest answer; until then, a report should flag chains that pass through a self-inhibiting node.

**4. The one real clash is a quantifier.** "Most neurons have axons" (rel) against "some neurons
have no axons" (notRel). The schema has no "most" or "some", so the annotator made "some lack" a
universal negation. Quantity (M3) is confirmed as the next schema milestone.

**5. A rule the search uses that Lean lacks.** 56 conclusions use "a is_a b, b has effect on t,
therefore a has that effect" (`isaInheritEffect`). It is sound for class-level claims and should
become a constructor; those 56 could not be certified.

**6. Dan's question.** "Cancer is a disease of energy metabolism": the only paths run "defective DNA
repair causes cancer, DNA repair occurs in cells, cells make ATP". Seven chapters connect cancer to
energy metabolism only through the word "cells". Not a result, and not expected to be one here; the
question needs the literature layer and context.

## What a certified derivation looks like

```lean
/-- ribose part of nucleic acid -/
def c52 := (Derivation.relChain (r₃ := ⟨.bfo, 50, false⟩)
  (Derivation.lit HowCellsObtainEnergy.how_cells_obtain_energy_m45438_21)   -- ribose part of RNA
  (Derivation.lit MolecularBiology.molbio_m45473_47))                       -- RNA is_a nucleic acid
example : Established (claim c52) (7/10) := ⟨c52, by decide +kernel⟩
```

The search proposed it, the kernel checked that the two statements compose under an RO law and that
the belief clears 0.7. That is the CertifyingDatalog pattern from the roadmap, working end to end.

## Phase 4 (2026-10-29): refinement edges, three guards, the neuron quantifiers

What changed. (1) `closure.py` now loads Lean's refinement axiom by default: for each of the 142 refined
entities in the facts, `e ⊓ ∃r.f is_a e` (rule `refineAxiom`, belief 999/1000, as `Entity.refineAxiom`);
a nested context drops one refinement at a time. These are definitional, so they count neither as
textbook statements nor as derived facts. (2) Three guards put flags on derived effect facts
(`flags` in `closure.json` and `closure_ic.json`). Nothing is dropped. (3) "Some neurons have no
dendrites" (body:m45539-54) and "some neurons contain no axons" (-109) now have an `m3` field with
`quant: some`, so they no longer act as universal negations. (4) In `holes.py`, a context against its
own base term ("insulin ⊓ located in blood raises insulin") now counts as reflexive.

`--legacy` turns off (1), (2) and the new reflexive test. On the old data it reproduces every earlier
output byte for byte (`closure.json`, `closure_ic.json`, `derivations_ic.json`, `holes.json`, `docs/holes.md`).

The numbers are on the data of e31670c (the M3 schema-gap commit, which landed during this task and
adds 19 round-3 statements); the first column is the last published run, for reference.

| | a0e235c, published | before (e31670c, `--legacy`) | new code, neuron not fixed | neuron fix only (`--legacy`) | **after** |
|---|---:|---:|---:|---:|---:|
| textbook statements | 1,378 | 1,397 | 1,397 | 1,395 | **1,395** |
| refinement axioms | 0 | 0 | 142 | 0 | **142** |
| derived facts (fixpoint at depth 4) | 1,606 | 1,614 | 2,289 | 1,614 | **2,287** |
| kept by IC at 2.5 | 881 | 886 | 1,254 | 886 | **1,254** |
| clashes (`r a b` and `¬ r a b`) | 2 | 2 | 5 | 0 | **1** |
| sign clashes (`a →+ t` and `a →− t`) | 0 | 0 | 45 | 0 | **45** |
| derived effect facts | 151 | 151 | 343 | 151 | **343** |
| of which chain conclusions (viaAmount, viaActivity) | 94 | 94 | 196 | 94 | **196** |
| flagged feedback | (16) | (16) | 95 | (16) | **95** |
| flagged parthood | (0) | (0) | 0 | (0) | **0** |
| flagged shared_cause | (0) | (0) | 0 | (0) | **0** |
| holes found | 7,418 | 7,527 | 8,586 | 7,527 | **8,586** |
| holes after screening | 2,611 | 2,674 | 3,393 | 2,674 | **3,393** |
| hypotheses (grouped) | 1,016 | 1,046 | 1,300 | 1,046 | **1,300** |
| holes dropped as reflexive | 2 | 2 | 46 | 2 | **46** |

Bracketed flags: the guards are off under `--legacy`; these are the counts when the guards are run on
that closure. On the a0e235c data the refinement axioms reproduce the scratch run of phase 3 exactly
(129 edges, 2,190 derived, 5 clashes); the e31670c data adds 13 refined entities.

### Clashes

With the refinement edges there were five. Four were the two neuron sentences: once directly ("neurons
have dendrites", body:m45539-50, against "some neurons have no dendrites" read as "no neuron has a
dendrite"), and once more each for neuron ⊓ in taxon Mammalia, which now inherits both sides. The `some`
fix removes all four.

**One remains, and it is a real annotation error.** "Animal cells also have a centrosome"
(cell:m45432-318) was annotated in round 2 as `cell has_part centrosome`, true of every cell. Plant
cells are cells, so they get centrosomes and then centrioles, against "plant cells lack centrioles"
(cell:m45432-75):

```
plant cell [CL:0000000 ⊓ in_taxon Viridiplantae] has part centrioles   (relTrans)
  plant cell has part centrosome   (isaInherit)
    plant cell is_a cell   [refine:CL:0000000&RO:0002162=(NCBITaxon:33090)]
    cell has part centrosome   [cell:m45432-318]   <- the error: needs the animal context
  centrosome has part centrioles   [cell:m45432-68]
¬plant cell has part centrioles   [cell:m45432-75]
```

The fix is to annotate -318 with `taxon: Metazoa` (it is not made here). Before the refinement edges,
the closure could not see this: "plant cell" was an island with no link to "cell".

### The guards

Each is a flag on a derived effect fact, computed over its derivation tree.

- **feedback.** Some premise `x → y` of the chain has an effect (stated or derived) running from `y`
  back to `x` or to something upstream of `x`. A derivation with one effect premise (one inherited
  statement) is not a chain and is not flagged; 15 such inherited statements are one edge of a stated
  loop, for example "blood glucose lowers blood glucagon".
- **parthood.** Some premise `x → y` has `x part_of y`, `y part_of x` or `has_part` stated.
- **shared_cause.** Some step `a → m`, `m → t` of the chain has both `a → m` and `a → t` stated.

**Feedback flags 95 of the 196 chain conclusions (48 percent), 95 of the 343 derived effect facts (28
percent).** Without the refinement edges it flags 16 of 94 chain conclusions (round 2 alone: 15 of
77). The edges bring the body's homeostatic loops in, because they link "glucose ⊓ in blood" to
"glucose": 80 of the 95 pass through a refined entity. By loop: glucose and insulin 39, glucagon and
glucose 30, ATP and glucose catabolism 14, depolarisation and the sodium channel 3, depolarisation
and sodium 3, calcium and parathyroid hormone 3, calcitonin and calcium 3.

The five shallowest (names cleaned; the raw trees are in `data/search/closure_report.txt`):

```
glucose lowers blood glucose                                  (viaAmount)
  glucose raises insulin                       [body:m45537-52]
  insulin lowers blood glucose                 [body:m45537-53]
  loop: blood glucose raises insulin (derived from -52 by the refinement edge)

glucose catabolism lowers ATP biosynthesis                    (viaAmount)
  glucose catabolism raises ATP                [energy:m45438-49]
  ATP lowers ATP biosynthesis                  [energy:m45437-246]
  loop: ATP lowers glucose catabolism          [energy:m45437-244]

glucose catabolism lowers cell death                          (viaAmount)
  glucose catabolism raises ATP                [energy:m45438-49]
  ATP lowers cell death                        [energy:m45439-64]
  loop: ATP lowers glucose catabolism          [energy:m45437-244]

glycolysis lowers glucose catabolism                          (viaAmount)
  glycolysis raises ATP                        [energy:m45440-75]
  ATP lowers glucose catabolism                [energy:m45437-244]
  loop: glucose catabolism raises ATP          [energy:m45438-49]

oxidative phosphorylation lowers glucose catabolism           (viaAmount)
  oxidative phosphorylation raises ATP         [energy:m45440-70]
  ATP lowers glucose catabolism                [energy:m45437-244]
  loop: glucose catabolism raises ATP          [energy:m45438-49]
```

**The edges also create 45 sign clashes, and every one has a flagged side.** The chain goes round the
loop and comes back with the opposite sign:

```
glucose lowers insulin                                        (viaAmount, b=0.51)
  glucose lowers blood glucose                                (viaAmount)
    glucose raises insulin                     [body:m45537-52]
    insulin lowers blood glucose               [body:m45537-53]
  blood glucose raises insulin                                (isaInheritEffect)
    blood glucose is_a glucose                 [refine:...]
    glucose raises insulin                     [body:m45537-52]
against: glucose raises insulin                [body:m45537-52]
```

Static sign algebra cannot hold a loop; the flag says where it tried. A `Claim.loop` or a dynamics
layer is still the honest answer (finding 3 above).

**Parthood and shared_cause flag nothing in the closure, and that is a real result, not a bug** (each
was checked on a planted case). No effect statement in the corpus runs between a part and its whole, so
no chain can contain one. The shared-cause shape occurs once in the whole corpus: statins lower
HMG-CoA reductase, which raises cholesterol, and statins lower cholesterol is also stated. Its
conclusion is the stated fact, so it is never derived, and it is a mechanism, not a common cause.
Both shapes live in the hole search, where a hole *proposes* the bad premise:

- 16 open effect holes run between a part and its whole: "carbohydrate raises the amount of plasma
  membrane", "centriole raises microtubule", "microtubule raises centriole", "cytoskeleton raises actin
  filament", "actin filament raises cytoskeleton" (each completes a sentence through the other).
- 59 open effect holes are a common cause read as a sequence (`m → t` where the book says `a → m` and
  `a → t`): "cholesterol lowers LDL receptor activity" (familial hypercholesterolemia does both), "oxygen
  in the leaf lowers CO2 in the leaf" and the reverse (stomatal closure does both), "oxygen in the lungs
  lowers CO2 in the lungs" (blood does both), "oxygen lowers CO2" (blood vessels do both). 3 of the 59
  were judged "true but unstated" earlier, so this is a flag, not a screen.

### Side findings

- **A correction.** Finding 3 above says 56 of the 73 viaAmount conclusions pass through the ATP
  feedback statement. A recount on the same round-2 data: 34 pass through ATP as a node, 6 use "ATP
  inhibits glucose catabolism" (energy:m45437-244), 7 use "ATP inhibits ATP synthesis" (-246), and the
  feedback guard flags 15.
- The guard sees loops only through effect statements. "ATP inhibits ATP synthesis" closes its loop
  through `has_output` (synthesis makes ATP), which is not an effect, so chains through it are flagged
  only when another loop is on the path.
- **The refinement edges bring a new hole artefact.** 16 of the new top 40 holes are unjudged, and 11
  of them have the shape "X is_a (Y ⊓ context)": "glucose catabolic process is_a glycolysis ⊓ occurs in
  skeletal muscle", "meiosis I is_a meiosis ⊓ in taxon animals". Every refined entity is now a
  subclass, so `isaInherit` proposes an unrefined class as a subclass of somebody else's context. On a
  quick read all 11 are false (mostly part_of read as is_a); a screen for them is cheap.
- The closure's own reflexive drop still compares exact curies, so "glucose lowers blood glucose" is
  kept (and flagged). That is right for the closure: it is a statement about the loop, not a tautology.

Reproduce:

```
PYTHONHASHSEED=1 python3 scripts/search/closure.py data/textbook/claims_m2 /tmp/obo/go.obo 4 > data/search/closure_report.txt
PYTHONHASHSEED=1 python3 scripts/search/holes.py data/textbook/claims_m2 /tmp/obo/go.obo 4
# the earlier behaviour: add --legacy to both
```
