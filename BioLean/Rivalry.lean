import BioLean.Derivation

/-!
# Rivalry (M2)

A `Rivalry` groups statements that cannot both be true: competing mechanisms for one effect, such
as chemiosmotic coupling against a chemical high-energy intermediate. It is a computation over
statements, not a derivation rule: it changes no claim, only how the rivals' opinions are read.
-/

namespace BioLean

/-- "Not this", from belief `b` in a rival: the opinion `⟨0, b, 1 − b⟩`. -/
def Opinion.against (o : Opinion) : Opinion :=
  Opinion.ofReliability o.belief o.belief_nonneg o.belief_lt_one .refutes

/-- Mutually exclusive statements: at most one is true, and all may be false (the list need not
be exhaustive). Belief in one rival counts as disbelief in each other: rival `i`'s own opinion is
fused with `against` of every other rival's own belief. One step, from own opinions, not iterated.

Fusing pure disbelief never raises belief (`Rivalry.belief_le`), so a rivalry decides losers, not
winners: a rival is established only if its own evidence already establishes it. Evidence that
bears on one rival only through the exclusion belongs on that rival alone; the rivalry carries it
to the others, and entering it on both counts it twice. -/
structure Rivalry where
  rivals : List Statement
  two_le : 2 ≤ rivals.length := by decide

namespace Rivalry

/-- Each element with the list of the others, in order. -/
def others {α : Type} (pre : List α) : List α → List (α × List α)
  | [] => []
  | x :: xs => (x, pre ++ xs) :: others (pre ++ [x]) xs

/-- Each rival with its opinion under the rivalry. -/
def opinions [EvidenceModel] (r : Rivalry) : List (Statement × Opinion) :=
  (others [] r.rivals).map fun (s, rest) => (s, rest.foldl (fun o t => o.fuse t.opinion.against) s.opinion)

/-- The rivalry as it stood at the end of `year`. -/
def asOf (r : Rivalry) (year : Nat) : Rivalry :=
  ⟨r.rivals.map (·.asOf year), by simpa using r.two_le⟩

/-- Each rival with its opinion under the rivalry in `year`. -/
def opinionsAt [EvidenceModel] (r : Rivalry) (year : Nat) : List (Statement × Opinion) :=
  (r.asOf year).opinions

/-- Each rival's id with its verdict under the rivalry. -/
def verdicts [EvidenceModel] (r : Rivalry) (θ : ℚ := 4 / 5) (τ : ℚ := 1 / 4) :
    List (String × Derivation.Verdict) :=
  r.opinions.map fun (s, o) => (s.id, o.verdict θ τ)

/-- A rivalry never raises a rival's belief above what its own evidence gives. -/
theorem belief_le [EvidenceModel] (r : Rivalry) : ∀ p ∈ r.opinions, p.2.belief ≤ p.1.opinion.belief := by
  have fold : ∀ (rest : List Statement) (o : Opinion),
      (rest.foldl (fun o t => o.fuse t.opinion.against) o).belief ≤ o.belief := by
    intro rest
    induction rest with
    | nil => intro o; exact le_rfl
    | cons t rest ih =>
      intro o
      exact (ih _).trans (Opinion.fuse_belief_le_of_refutes _ _ rfl)
  simp only [opinions, List.mem_map]
  rintro _ ⟨⟨s, rest⟩, -, rfl⟩
  exact fold rest s.opinion

end Rivalry
end BioLean
