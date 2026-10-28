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
