import BioLean.Lib.GLP1Statements

/-!
# biolib: the GLP-1 / appetite module

Named derivations that other proofs can reuse, in the way a mathlib lemma is reused.
Each one rests on the literature statements in `GLP1Statements`; `Derivation.axioms`
recovers them.
-/

namespace BioLean.Lib

open Derivation

/-! ### Single-statement lemmas -/

def semaglutide_activates_GLP1R : Derivation (.effect semaglutide .pos (.activity GLP1R)) := lit S1
def GLP1R_reduces_feeding : Derivation (.effect GLP1R .neg (.process feedingBehavior)) := lit S2
def glp1_activates_GLP1R : Derivation (.effect glp1 .pos (.activity GLP1R)) := lit S3
def DPP4_degrades_glp1 : Derivation (.effect DPP4 .neg (.amount glp1)) := lit S4
def sitagliptin_inhibits_DPP4 : Derivation (.effect sitagliptin .neg (.activity DPP4)) := lit S5
def GLP1R_delays_gastricEmptying : Derivation (.effect GLP1R .neg (.process gastricEmptying)) := lit S6
def semaglutide_reduces_feeding_clinical :
    Derivation (.effect semaglutide .neg (.process feedingBehavior)) := lit S7

/-! ### Chained lemmas -/

/-- Mechanistic route: semaglutide activates GLP1R, and GLP1R activity reduces intake. -/
def semaglutide_reduces_feeding_mechanistic :
    Derivation (.effect semaglutide .neg (.process feedingBehavior)) :=
  viaActivity semaglutide_activates_GLP1R GLP1R_reduces_feeding

/-- The main result: two independent routes fused. -/
def semaglutide_reduces_feeding :
    Derivation (.effect semaglutide .neg (.process feedingBehavior)) :=
  both semaglutide_reduces_feeding_clinical semaglutide_reduces_feeding_mechanistic

/-- Endogenous GLP-1 reduces intake through its receptor. -/
def glp1_reduces_feeding : Derivation (.effect glp1 .neg (.process feedingBehavior)) :=
  viaActivity glp1_activates_GLP1R GLP1R_reduces_feeding

/-- Inhibiting the enzyme that degrades GLP-1 raises GLP-1: `neg * neg = pos`. -/
def sitagliptin_raises_glp1 : Derivation (.effect sitagliptin .pos (.amount glp1)) :=
  viaActivity sitagliptin_inhibits_DPP4 DPP4_degrades_glp1

/-- The textbook chain predicts that sitagliptin should reduce intake. -/
def sitagliptin_reduces_feeding_mechanistic :
    Derivation (.effect sitagliptin .neg (.process feedingBehavior)) :=
  viaAmount sitagliptin_raises_glp1 glp1_reduces_feeding

/-- ...but the clinical literature mostly says it does not. Fusing both shows the conflict. -/
def sitagliptin_reduces_feeding :
    Derivation (.effect sitagliptin .neg (.process feedingBehavior)) :=
  both sitagliptin_reduces_feeding_mechanistic (lit S8)

/-! ### Mechanism disputes (competing hypotheses) -/

/-- Nausea as the mediator: S9a argues for it, S9b against it. -/
def nausea_mediates :
    Derivation (.mediatedBy GLP1R .neg (.process feedingBehavior) (.phenotype nausea)) :=
  both (lit S9a) (lit S9b)

def acts_via_hypothalamus :
    Derivation (.mediatedBy semaglutide .neg (.process feedingBehavior) (.site hypothalamus)) :=
  lit S9c

def acts_via_areaPostrema :
    Derivation (.mediatedBy semaglutide .neg (.process feedingBehavior) (.site areaPostrema)) :=
  lit S9d

end BioLean.Lib
