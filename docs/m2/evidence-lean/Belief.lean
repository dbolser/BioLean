import Mathlib.Data.Rat.Defs
import Mathlib.Tactic

/-!
# Belief: subjective-logic opinions over ℚ

Every literature-derived statement in BioLean carries an *opinion* in the sense of
Jøsang's subjective logic: a belief mass `b`, a disbelief mass `d` and an uncertainty
mass `u`, with `b + d + u = 1`. Two operators are used:

* `fuse` (cumulative fusion) combines two *independent* bodies of evidence about the
  same claim. Agreeing evidence raises belief; conflicting evidence leaves both `b`
  and `d` large, which is how a contested claim shows up.
* `chain` (serial composition) carries belief through a mechanistic step. A chain can
  only argue *for* its conclusion, so its disbelief is zero and anything not believed
  becomes uncertainty.

We keep `0 < u` as an invariant: no finite body of evidence makes a dogmatic opinion.
This keeps `fuse` total (its denominator is never zero).

Lean checks the algebra below once and for all. Numbers in a particular derivation are
then computed by `decide +kernel` or `#eval`.
-/

namespace BioLean

/-- A subjective-logic opinion. The three masses are rationals so that every
derivation's strength is computable exactly and checkable by the kernel. -/
@[ext]
structure Opinion where
  belief : ℚ
  disbelief : ℚ
  uncertainty : ℚ
  belief_nonneg : 0 ≤ belief
  disbelief_nonneg : 0 ≤ disbelief
  uncertainty_pos : 0 < uncertainty
  sum_eq_one : belief + disbelief + uncertainty = 1

namespace Opinion

theorem belief_lt_one (o : Opinion) : o.belief < 1 := by
  linarith [o.disbelief_nonneg, o.uncertainty_pos, o.sum_eq_one]

theorem belief_le_one (o : Opinion) : o.belief ≤ 1 := o.belief_lt_one.le

theorem disbelief_lt_one (o : Opinion) : o.disbelief < 1 := by
  linarith [o.belief_nonneg, o.uncertainty_pos, o.sum_eq_one]

theorem uncertainty_le_one (o : Opinion) : o.uncertainty ≤ 1 := by
  linarith [o.belief_nonneg, o.disbelief_nonneg, o.sum_eq_one]

/-- Total ignorance: the unit of `fuse`. -/
def vacuous : Opinion :=
  ⟨0, 0, 1, le_rfl, le_rfl, one_pos, by norm_num⟩

/-- Projected probability with base rate `a` (default ½). -/
def prob (o : Opinion) (a : ℚ := 1 / 2) : ℚ :=
  o.belief + a * o.uncertainty

/-- The opinion about `¬c` given an opinion about `c`: belief and disbelief swap. -/
def negate (o : Opinion) : Opinion :=
  ⟨o.disbelief, o.belief, o.uncertainty, o.disbelief_nonneg, o.belief_nonneg, o.uncertainty_pos,
    by have := o.sum_eq_one; linarith⟩

@[simp] theorem negate_negate (o : Opinion) : o.negate.negate = o := by
  cases o; rfl

/-! ### Cumulative fusion -/

/-- The denominator of cumulative fusion. -/
def kappa (x y : Opinion) : ℚ :=
  x.uncertainty + y.uncertainty - x.uncertainty * y.uncertainty

theorem kappa_pos (x y : Opinion) : 0 < kappa x y := by
  unfold kappa
  have hx := x.uncertainty_pos
  have hy := y.uncertainty_pos
  have hx1 := x.uncertainty_le_one
  nlinarith

/-- Cumulative fusion of two independent opinions about the same claim. -/
def fuse (x y : Opinion) : Opinion where
  belief := (x.belief * y.uncertainty + y.belief * x.uncertainty) / kappa x y
  disbelief := (x.disbelief * y.uncertainty + y.disbelief * x.uncertainty) / kappa x y
  uncertainty := x.uncertainty * y.uncertainty / kappa x y
  belief_nonneg := by
    apply div_nonneg _ (kappa_pos x y).le
    have := x.belief_nonneg; have := y.belief_nonneg
    have := x.uncertainty_pos; have := y.uncertainty_pos
    positivity
  disbelief_nonneg := by
    apply div_nonneg _ (kappa_pos x y).le
    have := x.disbelief_nonneg; have := y.disbelief_nonneg
    have := x.uncertainty_pos; have := y.uncertainty_pos
    positivity
  uncertainty_pos := by
    apply div_pos _ (kappa_pos x y)
    exact mul_pos x.uncertainty_pos y.uncertainty_pos
  sum_eq_one := by
    rw [← add_div, ← add_div, div_eq_one_iff_eq (kappa_pos x y).ne']
    have hx := x.sum_eq_one
    have hy := y.sum_eq_one
    unfold kappa
    linear_combination y.uncertainty * hx + x.uncertainty * hy

theorem fuse_comm (x y : Opinion) : fuse x y = fuse y x := by
  ext <;> simp only [fuse, kappa] <;> ring

theorem fuse_vacuous (x : Opinion) : fuse x vacuous = x := by
  ext <;> simp [fuse, kappa, vacuous]

theorem vacuous_fuse (x : Opinion) : fuse vacuous x = x := by
  rw [fuse_comm, fuse_vacuous]

/-- Adding evidence that carries no disbelief never lowers belief. -/
theorem belief_le_fuse_of_supports (x y : Opinion) (hy : y.disbelief = 0) :
    x.belief ≤ (fuse x y).belief := by
  simp only [fuse]
  rw [le_div_iff₀ (kappa_pos x y)]
  unfold kappa
  have hx := x.belief_le_one
  have hu : y.uncertainty = 1 - y.belief := by linarith [y.sum_eq_one]
  rw [hu]
  nlinarith [mul_nonneg (mul_nonneg x.uncertainty_pos.le y.belief_nonneg) (sub_nonneg.2 hx)]

/-- Adding evidence that carries no belief never lowers disbelief. -/
theorem disbelief_le_fuse_of_refutes (x y : Opinion) (hy : y.belief = 0) :
    x.disbelief ≤ (fuse x y).disbelief := by
  simp only [fuse]
  rw [le_div_iff₀ (kappa_pos x y)]
  unfold kappa
  have hx := x.disbelief_lt_one.le
  have hu : y.uncertainty = 1 - y.disbelief := by linarith [y.sum_eq_one]
  rw [hu]
  nlinarith [mul_nonneg (mul_nonneg x.uncertainty_pos.le y.disbelief_nonneg) (sub_nonneg.2 hx)]

/-- Fusion never increases uncertainty: more evidence, less ignorance. -/
theorem fuse_uncertainty_le_left (x y : Opinion) : (fuse x y).uncertainty ≤ x.uncertainty := by
  simp only [fuse]
  rw [div_le_iff₀ (kappa_pos x y)]
  unfold kappa
  have hx := x.uncertainty_pos
  have hy := y.uncertainty_le_one
  nlinarith [mul_nonneg (mul_nonneg hx.le hx.le) (sub_nonneg.2 hy)]

/-! ### Serial composition (mechanistic chaining) -/

/-- Carry belief through a mechanistic step. The chain argues only *for* its
conclusion, so disbelief is zero and the remainder is uncertainty. -/
def chain (x y : Opinion) : Opinion where
  belief := x.belief * y.belief
  disbelief := 0
  uncertainty := 1 - x.belief * y.belief
  belief_nonneg := mul_nonneg x.belief_nonneg y.belief_nonneg
  disbelief_nonneg := le_rfl
  uncertainty_pos := by
    have h1 := x.belief_lt_one
    have h2 := y.belief_le_one
    have h3 := x.belief_nonneg
    have h4 := y.belief_nonneg
    nlinarith
  sum_eq_one := by ring

/-- A chain is never stronger than its first link. -/
theorem chain_belief_le_left (x y : Opinion) : (chain x y).belief ≤ x.belief := by
  simp only [chain]
  have := y.belief_le_one
  have := x.belief_nonneg
  nlinarith

/-- A chain is never stronger than its second link. -/
theorem chain_belief_le_right (x y : Opinion) : (chain x y).belief ≤ y.belief := by
  simp only [chain]
  have := x.belief_le_one
  have := y.belief_nonneg
  nlinarith

theorem chain_comm (x y : Opinion) : chain x y = chain y x := by
  ext <;> simp only [chain] <;> ring

/-! ### Evidence to opinion -/

/-- Which way a piece of evidence points. -/
inductive Polarity
  | supports
  | refutes
  deriving DecidableEq, Repr

/-- The opinion contributed by one piece of evidence of reliability `r`, `0 ≤ r < 1`.
Supporting evidence puts `r` into belief, refuting evidence into disbelief. -/
def ofReliability (r : ℚ) (h0 : 0 ≤ r) (h1 : r < 1) : Polarity → Opinion
  | .supports => ⟨r, 0, 1 - r, h0, le_rfl, by linarith, by ring⟩
  | .refutes => ⟨0, r, 1 - r, le_rfl, h0, by linarith, by ring⟩

/-! ### Weakest link (logical steps) -/

/-- Compose two opinions through a *logical* step, such as an RO property chain applied to two
established relations: the conclusion is as believed as the weaker premise, and no less. Unlike
`chain`, belief does not multiply, so a twelve-step partonomy is not penalised for being finely
divided. Disbelief is zero, as for `chain`. -/
def weakest (x y : Opinion) : Opinion where
  belief := min x.belief y.belief
  disbelief := 0
  uncertainty := 1 - min x.belief y.belief
  belief_nonneg := le_min x.belief_nonneg y.belief_nonneg
  disbelief_nonneg := le_rfl
  uncertainty_pos := by have := min_le_left x.belief y.belief; have := x.belief_lt_one; linarith
  sum_eq_one := by ring

theorem weakest_belief_le_left (x y : Opinion) : (weakest x y).belief ≤ x.belief := min_le_left _ _
theorem weakest_belief_le_right (x y : Opinion) : (weakest x y).belief ≤ y.belief := min_le_right _ _
theorem chain_le_weakest (x y : Opinion) : (chain x y).belief ≤ (weakest x y).belief := by
  unfold chain weakest; simp only
  rcases le_total x.belief y.belief with h | h
  · rw [min_eq_left h]; nlinarith [x.belief_nonneg, y.belief_lt_one]
  · rw [min_eq_right h]; nlinarith [y.belief_nonneg, x.belief_lt_one]

/-! ### Discounting (trust in a transfer step) -/

/-- Subjective-logic trust discounting by a fixed weight `w ∈ [0, 1]`: belief and disbelief both
shrink by `w`, the rest becomes uncertainty. Used for cross-context transport (M2): a mouse result
read as a human one keeps its direction, at a fraction of its strength. -/
def discount (w : ℚ) (h0 : 0 ≤ w) (h1 : w ≤ 1) (x : Opinion) : Opinion where
  belief := w * x.belief
  disbelief := w * x.disbelief
  uncertainty := 1 - w * (x.belief + x.disbelief)
  belief_nonneg := mul_nonneg h0 x.belief_nonneg
  disbelief_nonneg := mul_nonneg h0 x.disbelief_nonneg
  uncertainty_pos := by
    have := x.sum_eq_one; have := x.uncertainty_pos
    nlinarith [x.belief_nonneg, x.disbelief_nonneg]
  sum_eq_one := by ring

theorem discount_belief_le (w : ℚ) (h0 : 0 ≤ w) (h1 : w ≤ 1) (x : Opinion) :
    (discount w h0 h1 x).belief ≤ w := by
  simp only [discount]; nlinarith [x.belief_le_one]

/-! ### Printing -/

/-- Fixed-point decimal rendering of a rational in `[0, 1]`, for reports. -/
def _root_.Rat.toDecimal (q : ℚ) (digits : Nat := 3) : String :=
  let scale : ℕ := 10 ^ digits
  let n : ℕ := (q * scale).floor.toNat
  let whole := n / scale
  let frac := n % scale
  let fracStr := toString frac
  let pad := String.ofList (List.replicate (digits - fracStr.length) '0')
  s!"{whole}.{pad}{fracStr}"

instance : Repr Opinion where
  reprPrec o _ :=
    s!"⟨b={o.belief.toDecimal} d={o.disbelief.toDecimal} u={o.uncertainty.toDecimal}⟩"

instance : ToString Opinion := ⟨fun o => reprStr o⟩

end Opinion
end BioLean
