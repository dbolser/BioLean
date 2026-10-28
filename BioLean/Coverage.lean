import BioLean.Taxa
import BioLean.Belief

/-!
# Coverage (M4)

How much of a target clade `T` a set of sampled taxa covers, read off the imported NCBITaxon
hierarchy. `Derivation.generalize` discounts its fused instance opinion by one of two measures.

**Children are NCBI's at the targets, biolib's below.** For the generalisation targets
(`Ontology.targets`: cellular organisms, Eukaryota, Opisthokonta, Metazoa, Bacteria, Archaea,
Viridiplantae, Mammalia) `children` is every direct NCBI child, bins left out (unclassified,
environmental samples, incertae sedis, candidate phyla): Eukaryota has 18, Opisthokonta 6. Below the
targets the known taxa are still the is_a ancestor closure of the taxa biolib uses
(`BioLean/Ontology/IsA.lean`), so children there are under-counted and a known leaf is a used taxon
with nothing used below it, which can be a genus (Euglena) or an order (Lepidoptera).

* **Bracketing** (`bracketing`, the default, plan 2026-10-28 §3 and §5): sampled taxa under at least
  two distinct children of `T` bracket its common ancestor, and coverage is the fraction of `T`'s
  children holding a sample. Samples under exactly one child `C` bracket nothing at `T`, so the
  measure recurses: `C`'s own bracketing, scaled by `1 / #children T`, since one sampled lineage
  covers at most its share. No sample under any child gives 0, so a single taxon always gives 0.
* **Clade fraction** (`cladeFraction`, kept for comparison): the fraction of the known leaves under
  `T` that lie in a sampled clade.

Both lie in `[0, 1]` and are monotone in the sample (`Measure.eval_mono`): adding an instance never
lowers coverage.
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

/-- Bracketing, recursing to the deepest bracketed split: covered children over children if at least
two are covered; if one child `c` is, `c`'s bracketing over the children of `t`; else 0. -/
def bracketing (t : Code) (sampled : List Code) : (fuel : Nat := maxDepth) → ℚ
  | 0 => 0
  | n + 1 => match covered t sampled with
    | [] => 0
    | [c] => bracketing c sampled n / (children t).length
    | cs => cs.length / (children t).length

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

/-! ## Coverage lies in `[0, 1]` and never falls as the sample grows -/

private theorem ratio_mem {k n : ℕ} (h : k ≤ n) : 0 ≤ (k : ℚ) / n ∧ (k : ℚ) / n ≤ 1 :=
  ⟨by positivity, by
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    · rw [div_le_one (by exact_mod_cast hn)]; exact_mod_cast h⟩

theorem bracketing_mem (t : Code) (s : List Code) (n : Nat) :
    0 ≤ bracketing t s n ∧ bracketing t s n ≤ 1 := by
  induction n generalizing t with
  | zero => simp [bracketing]
  | succ n ih =>
    simp only [bracketing]
    split
    · norm_num
    · rename_i c _
      obtain ⟨h0, h1⟩ := ih c
      refine ⟨by positivity, ?_⟩
      rcases Nat.eq_zero_or_pos (children t).length with h | h
      · simp [h]
      · rw [div_le_one (by exact_mod_cast h)]
        exact h1.trans (by exact_mod_cast h)
    · exact ratio_mem (List.length_filter_le _ _)

/-- A sample in one child of `t` covers at most that child's share, so it never establishes a
claim about `t` at a threshold above `1 / #children t`. -/
theorem bracketing_single {t c : Code} {s : List Code} (h : covered t s = [c]) (n : Nat) :
    bracketing t s (n + 1) ≤ 1 / (children t).length := by
  simp only [bracketing, h]; gcongr; exact (bracketing_mem c s n).2

theorem covered_sublist (t : Code) {s s' : List Code} (h : s ⊆ s') :
    (covered t s).Sublist (covered t s') :=
  List.monotone_filter_right _ fun c hc => by
    obtain ⟨x, hx, hxc⟩ := List.any_eq_true.1 hc
    exact List.any_eq_true.2 ⟨x, h hx, hxc⟩

theorem bracketing_mono (t : Code) {s s' : List Code} (h : s ⊆ s') (n : Nat) :
    bracketing t s n ≤ bracketing t s' n := by
  induction n generalizing t with
  | zero => simp [bracketing]
  | succ n ih =>
    have hsub := covered_sublist t h
    have hmem := (bracketing_mem t s' (n + 1)).1
    simp only [bracketing] at hmem ⊢
    generalize covered t s = L at hsub ⊢
    generalize covered t s' = L' at hsub hmem ⊢
    rcases L with _ | ⟨c, _ | ⟨c₂, L⟩⟩ <;> rcases L' with _ | ⟨c', _ | ⟨c₂', L'⟩⟩ <;>
      simp only at hmem ⊢
    all_goals try first
      | exact hmem
      | (simp at hsub; done)
      | (have := hsub.length_le; simp at this; omega)
    · obtain rfl := List.mem_singleton.1 (List.singleton_sublist.1 hsub)
      gcongr; exact ih c
    · gcongr
      have := (bracketing_mem c s n).2
      simp only [List.length_cons, Nat.cast_add, Nat.cast_one]
      linarith [(Nat.cast_nonneg L'.length : (0 : ℚ) ≤ L'.length)]
    · gcongr; exact hsub.length_le

theorem cladeFraction_mono (t : Code) {s s' : List Code} (h : s ⊆ s') :
    cladeFraction t s ≤ cladeFraction t s' := by
  unfold cladeFraction
  dsimp only
  gcongr
  refine (List.monotone_filter_right _ fun a ha => ?_).length_le
  obtain ⟨x, hx, hax⟩ := List.mem_flatMap.1 (List.contains_iff_mem.1 ha)
  exact List.contains_iff_mem.2 (List.mem_flatMap.2 ⟨x, h hx, hax⟩)

theorem Measure.eval_mem (m : Measure) (T : Entity .taxon) (sampled : List (Entity .taxon)) :
    0 ≤ m.eval T sampled ∧ m.eval T sampled ≤ 1 := by
  unfold Measure.eval
  split
  · norm_num
  · cases m
    · exact bracketing_mem _ _ _
    · exact ratio_mem (List.length_filter_le _ _)

theorem Measure.eval_nonneg (m : Measure) (T : Entity .taxon) (s : List (Entity .taxon)) :
    0 ≤ m.eval T s := (m.eval_mem T s).1
theorem Measure.eval_le_one (m : Measure) (T : Entity .taxon) (s : List (Entity .taxon)) :
    m.eval T s ≤ 1 := (m.eval_mem T s).2

/-- Coverage is monotone in the sample: a larger sample never covers less. -/
theorem Measure.eval_mono (m : Measure) (T : Entity .taxon) {s s' : List (Entity .taxon)}
    (h : s ⊆ s') : m.eval T s ≤ m.eval T s' := by
  unfold Measure.eval
  split
  · exact le_rfl
  · have hs : s.filterMap (Curie.encode ·.curie) ⊆ s'.filterMap (Curie.encode ·.curie) := fun x hx => by
      obtain ⟨a, ha, hax⟩ := List.mem_filterMap.1 hx
      exact List.mem_filterMap.2 ⟨a, h ha, hax⟩
    cases m
    · exact bracketing_mono _ hs _
    · exact cladeFraction_mono _ hs

/-- Adding an instance never lowers coverage. -/
theorem Measure.eval_le_cons (m : Measure) (T x : Entity .taxon) (s : List (Entity .taxon)) :
    m.eval T s ≤ m.eval T (x :: s) := m.eval_mono T (List.subset_cons_self x s)

/-- The side condition of `generalize`: at least one sampled taxon, none twice, each is_a `T`. -/
def admissible (T : Entity .taxon) (sampled : List (Entity .taxon)) : Bool :=
  !sampled.isEmpty && decide (sampled.map (·.curie)).Nodup && sampled.all (Taxa.isA ·.curie T.curie)

end BioLean.Coverage
