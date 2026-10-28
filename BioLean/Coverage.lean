import BioLean.Taxa
import BioLean.Belief

/-!
# Coverage (M4)

How much of a target clade `T` a set of sampled taxa covers, read off the imported NCBITaxon
hierarchy. `Derivation.generalize` discounts its fused instance opinion by one of two measures.

**"Known" is not NCBI.** The known taxa are the is_a ancestor closure of the taxa biolib uses
(`BioLean/Ontology/IsA.lean`), so `children` under-counts the real children (Eukaryota has 4
known children here and 21 in NCBI, 18 of them named clades; Opisthokonta 2 here, 6 named in NCBI)
and a known leaf is a used taxon with nothing used below it, which can be a genus (Euglena) or an
order (Lepidoptera). Both measures are relative to what biolib talks about, and both grow or shrink
as biolib does. The under-count makes bracketing generous.

* **Bracketing** (`bracketing`, the provisional default, plan 2026-10-28 §3): sampled taxa under at
  least two distinct children of `T` bracket its common ancestor, and coverage is the fraction of
  `T`'s known children holding a sample; a sample under one child brackets nothing and gives 0.
* **Clade fraction** (`cladeFraction`, kept for comparison): the fraction of the known leaves under
  `T` that lie in a sampled clade.
-/

namespace BioLean.Coverage
open Ontology

/-- The known leaves under `t`, `t` itself if it has no known children, found by walking down the
imported children. `maxDepth` is the longest is_a chain, so the fuel never runs out. -/
def leaves (t : Code) : (fuel : Nat := maxDepth) → List Code
  | 0 => [t]
  | n + 1 => match children t with
    | [] => [t]
    | cs => (cs.flatMap (leaves · n)).eraseDups

/-- The children of `t` that hold a sampled taxon. -/
def covered (t : Code) (sampled : List Code) : List Code :=
  (children t).filter fun c => sampled.any (isA · c)

/-- Bracketing: covered children over known children, if at least two children are covered. -/
def bracketing (t : Code) (sampled : List Code) : ℚ :=
  let k := (covered t sampled).length
  if 2 ≤ k then (k : ℚ) / (children t).length else 0

/-- Clade fraction: known leaves under `t` lying in a sampled clade, over known leaves under `t`. -/
def cladeFraction (t : Code) (sampled : List Code) : ℚ :=
  let inSample := sampled.flatMap (leaves ·)
  let ls := leaves t
  ((ls.filter inSample.contains).length : ℚ) / ls.length

/-- Which coverage measure `generalize` discounts by. -/
inductive Measure
  | bracketing
  | cladeFraction
  deriving DecidableEq, Repr

instance : ToString Measure := ⟨fun | .bracketing => "bracketing" | .cladeFraction => "clade fraction"⟩

/-- The coverage of `T` by the sampled taxa. A taxon whose curie does not encode (refined, or an
unknown prefix) counts for nothing, and so does a `T` that does not encode. -/
def Measure.eval (m : Measure) (T : Entity .taxon) (sampled : List (Entity .taxon)) : ℚ :=
  match Curie.encode T.curie with
  | none => 0
  | some t =>
    let s := sampled.filterMap (Curie.encode ·.curie)
    match m with
    | .bracketing => Coverage.bracketing t s
    | .cladeFraction => Coverage.cladeFraction t s

private theorem ratio_mem {k n : ℕ} (h : k ≤ n) : 0 ≤ (k : ℚ) / n ∧ (k : ℚ) / n ≤ 1 :=
  ⟨by positivity, by
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    · rw [div_le_one (by exact_mod_cast hn)]; exact_mod_cast h⟩

theorem Measure.eval_mem (m : Measure) (T : Entity .taxon) (sampled : List (Entity .taxon)) :
    0 ≤ m.eval T sampled ∧ m.eval T sampled ≤ 1 := by
  unfold Measure.eval
  split
  · norm_num
  · cases m
    · simp only [Coverage.bracketing]; split
      · exact ratio_mem (List.length_filter_le _ _)
      · norm_num
    · exact ratio_mem (List.length_filter_le _ _)

theorem Measure.eval_nonneg (m : Measure) (T : Entity .taxon) (s : List (Entity .taxon)) :
    0 ≤ m.eval T s := (m.eval_mem T s).1
theorem Measure.eval_le_one (m : Measure) (T : Entity .taxon) (s : List (Entity .taxon)) :
    m.eval T s ≤ 1 := (m.eval_mem T s).2

/-- The side condition of `generalize`: at least one sampled taxon, none twice, each is_a `T`. -/
def admissible (T : Entity .taxon) (sampled : List (Entity .taxon)) : Bool :=
  !sampled.isEmpty && decide (sampled.map (·.curie)).Nodup && sampled.all (Taxa.isA ·.curie T.curie)

end BioLean.Coverage
