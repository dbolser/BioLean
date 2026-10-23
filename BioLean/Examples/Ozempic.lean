import BioLean.Lib.GLP1

/-!
# Does Ozempic reduce hunger?

The question, formalized: does semaglutide have a negative effect on feeding behavior
(GO:0007631)? Lean checks that each derivation below is well-formed. `decide +kernel`
then computes the belief exactly and checks it against the threshold.
-/

namespace BioLean.Examples

open BioLean.Lib Derivation

/-- Semaglutide reduces food intake, established at belief ≥ 0.95. -/
theorem semaglutide_reduces_hunger :
    Established (.effect semaglutide .neg (.process feedingBehavior)) (95 / 100) :=
  ⟨semaglutide_reduces_feeding, by decide +kernel⟩

/-- The mechanistic route alone already clears 0.8. -/
theorem semaglutide_reduces_hunger_mechanistic :
    Established (.effect semaglutide .neg (.process feedingBehavior)) (8 / 10) :=
  ⟨semaglutide_reduces_feeding_mechanistic, by decide +kernel⟩

/-- Sign algebra: sitagliptin raises GLP-1 because two negatives compose. Lean checks
the type; nothing else is needed. -/
example : Derivation (.effect sitagliptin .pos (.amount glp1)) := sitagliptin_raises_glp1

/-- The mechanistic prediction for sitagliptin is NOT established once the clinical
counter-evidence is fused in. -/
theorem sitagliptin_contested : sitagliptin_reduces_feeding.verdict = .contested := by
  decide +kernel

/-- The nausea mechanism is contested; the top-level claim is not. -/
theorem nausea_contested : nausea_mediates.verdict = .contested := by decide +kernel

/-! ### Reports -/

#eval IO.println semaglutide_reduces_feeding.report
#eval IO.println sitagliptin_reduces_feeding.report
#eval IO.println nausea_mediates.report
#eval IO.println acts_via_hypothalamus.report
#eval IO.println acts_via_areaPostrema.report

-- The biological `#print axioms`: which statements, which papers.
#eval semaglutide_reduces_feeding.axioms.map (·.id)
#eval semaglutide_reduces_feeding.pmids

end BioLean.Examples
