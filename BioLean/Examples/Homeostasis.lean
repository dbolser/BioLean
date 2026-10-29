import BioLean.Derivation

/-!
# Homeostasis: a feedback loop as a claim in its own right

Blood glucose and insulin (OpenStax 24.3, `the-body-s-systems-m45537`). The two arms are ordinary
`effect` claims. `Claim.homeostasis` says they close a loop that holds glucose near a set point.
Chaining the arms as a one-way cascade gives "glucose lowers blood glucose" (glucose raises insulin,
insulin lowers glucose): formally right, biologically misleading. Naming the loop lets the closure
search say which chain crossed which loop (`scripts/search/closure.py`). No dynamics: set point,
gain and time scale are for ODE models, not for this claim.
-/

namespace BioLean.Homeostasis
open Derivation

def tb (note : String) : Evidence := { pmid := 0, year := 2013, kind := .textbook, note := note }

def glucose : Entity .chemical := ⟨"CHEBI:17234", "glucose"⟩
def insulin : Entity .protein  := ⟨"PR:000009054", "insulin"⟩     -- unverified, as in Examples/Context

/-- Arm 1: "When blood-glucose levels rise, beta cells release insulin." -/
def S_glucoseRaisesInsulin : Statement :=
  ⟨"body:m45537-52", "rising blood glucose raises insulin", .effect glucose .pos (.amount insulin),
   [tb "OpenStax 24.3"]⟩
/-- Arm 2: "insulin facilitates the uptake of glucose by the body's cells." -/
def S_insulinLowersGlucose : Statement :=
  ⟨"body:m45537-53", "insulin lowers blood glucose", .effect insulin .neg (.amount glucose),
   [tb "OpenStax 24.3"]⟩
/-- The loop: the book's "negative feedback" sentence, stated as a thing. -/
def S_loop : Statement :=
  ⟨"body:m45537-loop", "insulin holds blood glucose near a set point", .homeostasis insulin (.amount glucose),
   [tb "OpenStax 24.3: blood-glucose levels are regulated by negative feedback"]⟩

/-- A negative loop: the product of the two arm signs is negative. -/
theorem negativeLoop : Sign.pos * Sign.neg = Sign.neg := by decide

#eval S_loop.claim
