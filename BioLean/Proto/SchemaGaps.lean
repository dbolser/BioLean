import BioLean.Derivation
import BioLean.Examples.Quantity
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR2.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR2.MolecularBiology
import BioLean.Lib.TextbookClaimsR3.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR3.MolecularBiology
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR3.Photosynthesis
import BioLean.Lib.TextbookClaimsR3.TheCellularBasisOfInheritance

/-!
# Prototype 08: or, approximate quantities, a second context slot

Program 08 (`docs/programs/08-schema-gaps.md`). Nothing here is in the core. Each part is labelled
with what it would change in the core if adopted:

| part | option | would change |
|---|---|---|
| 1 `Op.andS`, `Op.orS`, `Frame3.union` | D-b, D-d | new opinion operators (`Belief.lean`); `Frame3` a new opinion type |
| 2 `unionE`, `unionInL/R`, `unionLub`, `unionSubj` | D-c | nothing for the builder and the three statement schemas (definitions; today's rules use them); one new rule, `unionSubj`, only for an "or" on the subject |
| 3 `XClaim.or`, `orIntroL/R`, `orBoth`, `orElim` | D-b | new `Claim` constructor and four `Derivation` rules; `orElim` as written here (Lean functions on derivations) is refused inside `Derivation` itself (non-positive occurrence, `scripts/stress/gaps_positivity.py`), so the core would need assumptions threaded through every rule |
| 4 `Approx`, `Tol`, `QShape`, `XClaim.about`, `XClaim.fewer`, nine rules (`ofCount` to `ratioA`) | A-b | two `Claim` constructors, three small types, nine rules, a clash check |
| 5 `Ctx2`, `inCtx2`, `dropAxiom`, `transport2` | C-b | nothing for `Ctx2`, `inCtx2`, `dropAxiom` (definitions outside the core); one new rule, `transport2`; a `Ctx` type change only if `Ctx2` replaced the core `Ctx` |

`XClaim` extends the core `Claim` (`XClaim.base`); `XDerivation` embeds core derivations
(`XDerivation.core`). Parts 2 and 5 need no `XDerivation` at all: they build entities and statements
that today's `Derivation` already uses. The cases are the ones in `BioLean/Stress/SchemaGaps.lean`;
each prints `PROTO <tab> case <tab> option <tab> result`.
-/

namespace BioLean.Proto.SchemaGaps
open BioLean Derivation BioLean.Textbook.R2 BioLean.Textbook.R3

def proto (id opt msg : String) : IO Unit := IO.println s!"PROTO\t{id}\t{opt}\t{msg}"
def tb (note : String) : Evidence := { pmid := 0, year := 2013, kind := .textbook, note := note }
def paper (pmid year : Nat) (k : EvidenceKind) (note : String) : Evidence :=
  { pmid := pmid, year := year, kind := k, note := note }
def isaAx {k₁ k₂ : Kind} (a : Entity k₁) (b : Entity k₂) (h : Rel.isA.accepts k₁ k₂ = true := by decide) :
    Statement :=
  { id := s!"isa:{a.curie}<{b.curie}", text := s!"{a.label} is_a {b.label}", claim := .rel Rel.isA a b h,
    evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "is_a on OLS4" }] }
def vstr : Verdict → String
  | .established => "established" | .contested => "contested" | .refuted => "refuted"
  | .unsupported => "unsupported"
def ostr (o : Opinion) : String := s!"b={o.belief.toDecimal 2} d={o.disbelief.toDecimal 2} u={o.uncertainty.toDecimal 2}"

/-! ## Part 1. Opinions on a disjunction (D-b, D-d)

Jøsang, *Belief Calculus* (arXiv cs/0606029, 2006), Eq. 35 and 37: the product of two binomial
opinions puts mass `bx·by` on (x, y), `dx·dy` on (¬x, ¬y), and so on. Reading off "x and y" gives the
simple multiplication below; "x or y" is its De Morgan dual, simple comultiplication:
b = bx + by − bx·by, d = dx·dy, u = dx·uy + ux·dy + ux·uy. Both assume x and y independent.
For exclusive alternatives in one frame, Eq. 17: belief masses of disjoint elements add. -/

namespace Op

/-- Simple multiplication: the opinion on "x and y" for independent x, y. -/
def andS (x y : Opinion) : Opinion where
  belief := x.belief * y.belief
  disbelief := x.disbelief + y.disbelief - x.disbelief * y.disbelief
  uncertainty := x.belief * y.uncertainty + x.uncertainty * y.belief + x.uncertainty * y.uncertainty
  belief_nonneg := mul_nonneg x.belief_nonneg y.belief_nonneg
  disbelief_nonneg := by
    nlinarith [x.disbelief_nonneg, y.disbelief_nonneg,
      mul_nonneg y.disbelief_nonneg (sub_nonneg.2 x.disbelief_lt_one.le)]
  uncertainty_pos := by
    have := mul_pos x.uncertainty_pos y.uncertainty_pos
    have := mul_nonneg x.belief_nonneg y.uncertainty_pos.le
    have := mul_nonneg x.uncertainty_pos.le y.belief_nonneg
    linarith
  sum_eq_one := by
    linear_combination (y.belief + y.uncertainty) * x.sum_eq_one + (1 - x.disbelief) * y.sum_eq_one

/-- Simple comultiplication: the opinion on "x or y" for independent x, y. -/
def orS (x y : Opinion) : Opinion := (andS x.negate y.negate).negate

theorem orS_belief (x y : Opinion) : (orS x y).belief = x.belief + y.belief - x.belief * y.belief := rfl
theorem orS_disbelief (x y : Opinion) : (orS x y).disbelief = x.disbelief * y.disbelief := rfl
theorem orS_comm (x y : Opinion) : orS x y = orS y x := by
  ext <;> simp only [orS, andS, Opinion.negate] <;> ring

/-- Or-introduction never lowers belief. -/
theorem belief_le_orS (x y : Opinion) : x.belief ≤ (orS x y).belief := by
  rw [orS_belief]; nlinarith [y.belief_nonneg, x.belief_le_one]

/-- Evidence on one disjunct only: belief carries over, disbelief vanishes (the other may hold). -/
theorem orS_vacuous (x : Opinion) : (orS x .vacuous).belief = x.belief ∧ (orS x .vacuous).disbelief = 0 := by
  simp [orS_belief, orS_disbelief, Opinion.vacuous]

/-- An opinion over a frame of three exclusive alternatives {A, B, rest}: masses on each singleton
and on the whole frame (uncertainty). -/
structure Frame3 where
  bA : ℚ
  bB : ℚ
  bRest : ℚ
  u : ℚ
  hA : 0 ≤ bA := by norm_num
  hB : 0 ≤ bB := by norm_num
  hR : 0 ≤ bRest := by norm_num
  hu : 0 < u := by norm_num
  sum : bA + bB + bRest + u = 1 := by norm_num

/-- Coarsen the frame to {A ∪ B, rest}: belief masses of exclusive elements add (Jøsang Eq. 17). -/
def Frame3.union (f : Frame3) : Opinion :=
  ⟨f.bA + f.bB, f.bRest, f.u, add_nonneg f.hA f.hB, f.hR, f.hu, by linarith [f.sum]⟩

/-- The binomial opinion on A alone, from the same frame. -/
def Frame3.onA (f : Frame3) : Opinion :=
  ⟨f.bA, f.bB + f.bRest, f.u, f.hA, add_nonneg f.hB f.hR, f.hu, by linarith [f.sum]⟩
def Frame3.onB (f : Frame3) : Opinion :=
  ⟨f.bB, f.bA + f.bRest, f.u, f.hB, add_nonneg f.hA f.hR, f.hu, by linarith [f.sum]⟩

end Op

/-! ## Part 2. Union entities (D-c)

Most textbook "or"s sit inside one claim: has output ATP or GTP; precedes mitosis or meiosis. A
union class `a ⊔ b` (OWL `ObjectUnionOf`) states them as one ordinary `Claim.rel`. Three axiom schemas
make the existing is_a laws use it: each member is_a the union (two schemas, definitional), and the
union is_a any common ancestor of its members in the imported closure (`unionLub`). No new claim
constructor. One rule, `unionSubj` (part 3), is needed only for an "or" on the subject. -/

/-- The union class `a ⊔ b`, of the same kind. -/
def unionE {k : Kind} (a b : Entity k) : Entity k := ⟨s!"({a.curie}|{b.curie})", s!"{a.label} or {b.label}"⟩

/-- `a is_a a ⊔ b`, true by definition. -/
def unionInL {k : Kind} (a b : Entity k) (h : Rel.isA.accepts k k = true := by decide) : Statement :=
  { id := s!"union:{a.curie}<{(unionE a b).curie}", text := s!"{a.label} is_a {(unionE a b).label}",
    claim := .rel Rel.isA a (unionE a b) h,
    evidence := [{ pmid := 0, year := 0, kind := .definitional, note := "A ⊑ A ⊔ B" }] }
def unionInR {k : Kind} (a b : Entity k) (h : Rel.isA.accepts k k = true := by decide) : Statement :=
  { id := s!"union:{b.curie}<{(unionE a b).curie}", text := s!"{b.label} is_a {(unionE a b).label}",
    claim := .rel Rel.isA b (unionE a b) h,
    evidence := [{ pmid := 0, year := 0, kind := .definitional, note := "B ⊑ A ⊔ B" }] }
/-- `a ⊔ b is_a c` when both members are is_a `c` in the imported closure (decided at construction). -/
def unionLub {k : Kind} (a b c : Entity k) (_ha : Ontology.isACurie a.curie c.curie = true := by decide)
    (_hb : Ontology.isACurie b.curie c.curie = true := by decide) (h : Rel.isA.accepts k k = true := by decide) :
    Statement :=
  { id := s!"union:{(unionE a b).curie}<{c.curie}", text := s!"{(unionE a b).label} is_a {c.label}",
    claim := .rel Rel.isA (unionE a b) c h,
    evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "both members is_a c in the closure" }] }

/-! ## Part 3 and 4. The extended claim type (D-b, A-b) -/

/-- How the interval of an approximate number was set. -/
inductive Tol
  | exact          -- an exact number, as the core stores it
  | stated         -- the source gives the range ("about 25 to 30 cm")
  | pct (p : ℚ)    -- a convention: ± p of the value ("about" read as ±10 percent)
  | lastDigit (place : ℚ)  -- a convention: ± half a unit in the last stated digit
  | derived        -- computed from other intervals
  deriving DecidableEq, Repr

/-- An approximate number: the value as written, the interval it stands for, and how. -/
structure Approx where
  nominal : ℚ
  lo : ℚ
  hi : ℚ
  tol : Tol
  deriving DecidableEq, Repr

namespace Approx
def exact (n : ℚ) : Approx := ⟨n, n, n, .exact⟩
def range (lo hi : ℚ) : Approx := ⟨(lo + hi) / 2, lo, hi, .stated⟩
/-- "about n", read as ± p of n (n ≥ 0). -/
def pct (n p : ℚ) : Approx := ⟨n, n - n * p, n + n * p, .pct p⟩
/-- "about n", read as ± half a unit in the last stated digit (`place` = that unit). -/
def digit (n place : ℚ) : Approx := ⟨n, n - place / 2, n + place / 2, .lastDigit place⟩
def sub (a b : Approx) : Approx := ⟨a.nominal - b.nominal, a.lo - b.hi, a.hi - b.lo, .derived⟩
def scale (a : Approx) (k : ℚ) : Approx := ⟨a.nominal * k, a.lo * k, a.hi * k, .derived⟩
/-- Division of non-negative intervals by a positive one. -/
def div (a b : Approx) : Approx := ⟨a.nominal / b.nominal, a.lo / b.hi, a.hi / b.lo, .derived⟩
def overlaps (a b : Approx) : Bool := decide (a.lo ≤ b.hi) && decide (b.lo ≤ a.hi)
def contains (a : Approx) (x : ℚ) : Bool := decide (a.lo ≤ x) && decide (x ≤ a.hi)
instance : ToString Approx := ⟨fun a => s!"~{a.nominal} [{a.lo}, {a.hi}]"⟩
end Approx

/-- A core quantity claim with its number taken out. -/
inductive QShape
  | count {k₁ k₂ : Kind} (whole : Entity k₁) (part : Entity k₂)
  | card {k : Kind} (c : Entity k)
  | measure {k : Kind} (x : Entity k) (q : Entity .phenotype) (u : String)
  | produces {k : Kind} (p : Entity .process) (m : Entity k)
  | consumes {k : Kind} (p : Entity .process) (m : Entity k)
  | yield {k : Kind} (p : Entity .process) (m : Entity k)
  | ratio (num den : QShape)

def QShape.toString : QShape → String
  | .count w p => s!"#{p.curie} per {w.curie}"
  | .card c => s!"|{c.curie}|"
  | .measure x q u => s!"{q.curie} of {x.curie} in {u}"
  | .produces p m => s!"{p.curie} makes {m.curie}"
  | .consumes p m => s!"{p.curie} uses {m.curie}"
  | .yield p m => s!"{p.curie} nets {m.curie}"
  | .ratio n d => s!"({n.toString}) / ({d.toString})"

/-- Claims with the prototype constructors. -/
inductive XClaim
  | base (c : Claim)
  | or (p q : XClaim)
  | about (s : QShape) (a : Approx)
  /-- every `a` has fewer `part`s than every `b`: what `less` is for counts. -/
  | fewer {k₁ k₂ k₃ : Kind} (a : Entity k₁) (b : Entity k₂) (part : Entity k₃)

def XClaim.toString : XClaim → String
  | .base c => c.toString
  | .or p q => s!"({p.toString}) ∨ ({q.toString})"
  | .about s a => s!"{s.toString} = {a}"
  | .fewer a b p => s!"{a.curie} has fewer {p.curie} than {b.curie}"
instance : ToString XClaim := ⟨XClaim.toString⟩

structure XStatement where
  id : String
  text : String
  claim : XClaim
  evidence : List Evidence

def XStatement.opinion [EvidenceModel] (s : XStatement) : Opinion :=
  s.evidence.foldl (fun acc e => acc.fuse e.opinion) .vacuous

/-- The assumption `p`, for case analysis. Definitional weight, so a conditional derivation is as
strong as its side premises; it is discharged by `orElim` and never listed as an axiom. -/
def hyp (p : Claim) : Statement :=
  { id := s!"hyp:{p}", text := "assumed for case analysis", claim := p,
    evidence := [{ pmid := 0, year := 0, kind := .definitional, note := "hypothesis, discharged" }] }

inductive XDerivation : XClaim → Type
  | core {c : Claim} (d : Derivation c) : XDerivation (.base c)
  | lit (s : XStatement) : XDerivation s.claim
  /-- `p ⊢ p ∨ q`: a sound weakening. Opinion: comultiplication with a vacuous `q`. -/
  | orIntroL {p : XClaim} (q : XClaim) (d : XDerivation p) : XDerivation (.or p q)
  | orIntroR (p : XClaim) {q : XClaim} (d : XDerivation q) : XDerivation (.or p q)
  /-- Opinions on both disjuncts, assumed independent: comultiplication. -/
  | orBoth {p q : XClaim} (dp : XDerivation p) (dq : XDerivation q) : XDerivation (.or p q)
  /-- Case analysis: `p ∨ q`, a way from any derivation of `p` to `r`, and one from `q` to `r`, give
  `r`. The two ways are Lean functions, run on the assumption `hyp p` (and `hyp q`). -/
  | orElim {p q r : Claim} (d : XDerivation (.or (.base p) (.base q)))
      (f : Derivation p → Derivation r) (g : Derivation q → Derivation r) : XDerivation (.base r)
  /-- Union elimination on the subject (D-c): `a r c` and `b r c` give `(a ⊔ b) r c`. -/
  | unionSubj {k₁ k₂ : Kind} {a b : Entity k₁} {c : Entity k₂} {r : Rel} {h : r.accepts k₁ k₂ = true}
      (da : Derivation (.rel r a c h)) (db : Derivation (.rel r b c h)) : XDerivation (.base (.rel r (unionE a b) c h))
  /-- The core RO chain, lifted so it can follow `unionSubj`. -/
  | xRelChain {k₁ k₂ k₃ : Kind} {a : Entity k₁} {b : Entity k₂} {c : Entity k₃} {r₁ r₂ r₃ : Rel}
      {h₁ : r₁.accepts k₁ k₂ = true} {h₂ : r₂.accepts k₂ k₃ = true}
      (ab : XDerivation (.base (.rel r₁ a b h₁))) (bc : XDerivation (.base (.rel r₂ b c h₂)))
      (ok : RO.chainOK r₁ r₂ r₃ = true := by decide) (h₃ : r₃.accepts k₁ k₃ = true := by decide) :
      XDerivation (.base (.rel r₃ a c h₃))
  -- Approximate quantities (A-b). Exact core claims embed as degenerate intervals.
  | ofCount {k₁ k₂ : Kind} {w : Entity k₁} {p : Entity k₂} {n : Nat} (d : Derivation (.count w p n)) :
      XDerivation (.about (.count w p) (.exact n))
  | ofCard {k : Kind} {c : Entity k} {n : Nat} (d : Derivation (.cardinality c n)) :
      XDerivation (.about (.card c) (.exact n))
  /-- Widen an interval: a sound weakening. -/
  | widen {s : QShape} {a : Approx} (b : Approx) (d : XDerivation (.about s a))
      (h : (decide (b.lo ≤ a.lo) && decide (a.hi ≤ b.hi)) = true := by decide +kernel) : XDerivation (.about s b)
  /-- Net yield by interval subtraction: [a.lo − b.hi, a.hi − b.lo]. -/
  | netA {k : Kind} {p : Entity .process} {m : Entity k} {a b : Approx}
      (made : XDerivation (.about (.produces p m) a)) (used : XDerivation (.about (.consumes p m) b)) :
      XDerivation (.about (.yield p m) (a.sub b))
  /-- Equal division of an approximate count by an exact number of sets. -/
  | perSetA {k₁ k₂ k₃ : Kind} {w : Entity k₁} {part : Entity k₂} {set : Entity k₃} {a : Approx} {s : Nat}
      (parts : XDerivation (.about (.count w part) a)) (sets : Derivation (.count w set s))
      (h : 0 < s := by decide) : XDerivation (.about (.count set part) (a.scale (1 / (s : ℚ))))
  /-- Pigeonhole needs every possible item count above every possible hole count. -/
  | pigeonholeA {k₁ k₂ : Kind} {item : Entity k₁} {hole : Entity k₂} {a b : Approx}
      (items : XDerivation (.about (.card item) a)) (holes : XDerivation (.about (.card hole) b))
      (each : Derivation (.count item hole 1)) (h : decide (b.hi < a.lo) = true := by decide +kernel) :
      XDerivation (.base (.quant .some (.atLeast hole item 2)))
  /-- Disjoint approximate counts order two wholes. -/
  | fewerA {k₁ k₂ k₃ : Kind} {w₁ : Entity k₁} {w₂ : Entity k₂} {part : Entity k₃} {a b : Approx}
      (d₁ : XDerivation (.about (.count w₁ part) a)) (d₂ : XDerivation (.about (.count w₂ part) b))
      (h : decide (a.hi < b.lo) = true := by decide +kernel) : XDerivation (.fewer w₁ w₂ part)
  /-- Change of unit by an exact positive factor (per minute to per hour: × 60). The factor is data. -/
  | scaleA {k : Kind} {x : Entity k} {q : Entity .phenotype} {u : String} {a : Approx} (u' : String) (f : ℚ)
      (d : XDerivation (.about (.measure x q u) a)) (h : decide (0 < f) = true := by decide +kernel) :
      XDerivation (.about (.measure x q u') (a.scale f))
  /-- Ratio of two approximate quantities (numerator non-negative, denominator positive). -/
  | ratioA {s₁ s₂ : QShape} {a b : Approx} (d₁ : XDerivation (.about s₁ a)) (d₂ : XDerivation (.about s₂ b))
      (h : (decide (0 ≤ a.lo) && decide (0 < b.lo)) = true := by decide +kernel) : XDerivation (.about (.ratio s₁ s₂) (a.div b))
  /-- Transport between sibling taxa, with any number of organism states carried along (C-b). -/
  | transport2 {k : Kind} {a : Entity k} {s : Sign} {t : Target} (c : Ctx) (states : List (Entity .phenotype))
      {T₁ : Entity .taxon} (T₂ : Entity .taxon)
      (d : Derivation (.effect (a.inCtx { c with taxon := some (states.foldl (fun x st => x.refine Rel.hasModifier st) T₁) }) s t))
      (e : Evidence) (hk : e.kind = .crossSpecies := by decide) (hs : Taxa.siblings T₁ T₂ = true := by decide) :
      XDerivation (.base (.effect (a.inCtx { c with taxon := some (states.foldl (fun x st => x.refine Rel.hasModifier st) T₂) }) s t))

namespace XDerivation
variable [EvidenceModel]

def opinion : {c : XClaim} → XDerivation c → Opinion
  | _, .core d => d.opinion
  | _, .lit s => s.opinion
  | _, .orIntroL _ d => Op.orS d.opinion .vacuous
  | _, .orIntroR _ d => Op.orS .vacuous d.opinion
  | _, .orBoth dp dq => Op.orS dp.opinion dq.opinion
  | _, .orElim (p := p) (q := q) d f g =>
      (d.opinion.weakest (f (.lit (hyp p))).opinion).weakest (g (.lit (hyp q))).opinion
  | _, .unionSubj da db => da.opinion.weakest db.opinion
  | _, .xRelChain ab bc .. => ab.opinion.weakest bc.opinion
  | _, .ofCount d => d.opinion
  | _, .ofCard d => d.opinion
  | _, .widen _ d _ => d.opinion
  | _, .netA m u => m.opinion.weakest u.opinion
  | _, .perSetA p s _ => p.opinion.weakest s.opinion
  | _, .pigeonholeA i h e _ => (i.opinion.weakest h.opinion).weakest e.opinion
  | _, .fewerA a b _ => a.opinion.weakest b.opinion
  | _, .scaleA _ _ d _ => d.opinion
  | _, .ratioA a b _ => a.opinion.weakest b.opinion
  | _, .transport2 _ _ _ d e .. => d.opinion.chain e.opinion

/-- The ids of the statements a derivation rests on; discharged hypotheses are left out. -/
def axiomIds : {c : XClaim} → XDerivation c → List String
  | _, .core d => d.axioms.map (·.id)
  | _, .lit s => [s.id]
  | _, .orIntroL _ d | _, .orIntroR _ d => d.axiomIds
  | _, .orBoth dp dq => dp.axiomIds ++ dq.axiomIds
  | _, .orElim (p := p) (q := q) d f g =>
      d.axiomIds ++ ((f (.lit (hyp p))).axioms ++ (g (.lit (hyp q))).axioms).filterMap fun s =>
        if s.id.startsWith "hyp:" then none else some s.id
  | _, .unionSubj da db => (da.axioms ++ db.axioms).map (·.id)
  | _, .xRelChain ab bc .. => ab.axiomIds ++ bc.axiomIds
  | _, .ofCount d | _, .ofCard d => d.axioms.map (·.id)
  | _, .widen _ d _ | _, .scaleA _ _ d _ => d.axiomIds
  | _, .netA m u => m.axiomIds ++ u.axiomIds
  | _, .perSetA p s _ => p.axiomIds ++ s.axioms.map (·.id)
  | _, .pigeonholeA i h e _ => i.axiomIds ++ h.axiomIds ++ e.axioms.map (·.id)
  | _, .fewerA a b _ | _, .ratioA a b _ => a.axiomIds ++ b.axiomIds
  | _, .transport2 _ _ _ d .. => d.axioms.map (·.id)

def verdict {c : XClaim} (d : XDerivation c) : Verdict := d.opinion.verdict

/-- Two approximate values of one quantity that cannot both hold. `none` if the intervals overlap.
Otherwise the opinion on the first, with the second read as evidence against it. -/
def clash {s : QShape} {a b : Approx} (d₁ : XDerivation (.about s a)) (d₂ : XDerivation (.about s b)) : Option Opinion :=
  if a.overlaps b then none else some (d₁.opinion.fuse d₂.opinion.negate)

end XDerivation

/-! ## Part 5. A second context slot (C-b)

A condition says which slot it refines (the subject, the cell-type filler, or the taxon filler) and
how (a state, `has_modifier`; or surroundings, `surrounded_by`). Any number are allowed. `inCtx2`
applies them in one canonical order (sorted by slot, relation and curie), so the same set gives the
same curie whatever order it was written in. With zero or one condition it gives the core's curie. -/

inductive Slot | subject | cellType | taxon
  deriving DecidableEq, Repr
inductive How | state | surroundings
  deriving DecidableEq, Repr

structure Cond where
  slot : Slot
  how : How
  {kind : Kind}
  filler : Entity kind

def Cond.rel (c : Cond) : Rel := match c.how with | .state => Rel.hasModifier | .surroundings => Rel.surroundedBy
def Cond.key (c : Cond) : String :=
  let s := match c.slot with | .subject => "0" | .cellType => "1" | .taxon => "2"
  let h := match c.how with | .state => "s" | .surroundings => "e"
  s ++ h ++ c.filler.curie

structure Ctx2 where
  /-- The core slots. `base.condition` is ignored: conditions go in `conds`. -/
  base : Ctx := {}
  conds : List Cond := []

/-- Refine by a list of conditions, skipping any whose relation RO refuses (see `Ctx2.fits`). -/
def refineAll {k : Kind} (e : Entity k) (cs : List Cond) : Entity k :=
  cs.foldl (fun x c => if h : c.rel.accepts k c.kind = true then x.refine c.rel c.filler h else x) e

/-- Lexicographic order on characters. Structural, so the kernel and `decide` can run it. -/
def lexLe : List Char → List Char → Bool
  | [], _ => true
  | _ :: _, [] => false
  | a :: as, b :: bs => if a.toNat < b.toNat then true else if a.toNat = b.toNat then lexLe as bs else false

/-- Insertion sort by key. Structural (not `List.mergeSort`, whose well-founded recursion blocks
unfolding), so a sorted context is definitionally the core context when there is one condition. -/
def insertCond (x : Cond) : List Cond → List Cond
  | [] => [x]
  | y :: ys => if lexLe x.key.toList y.key.toList then x :: y :: ys else y :: insertCond x ys
def sortConds : List Cond → List Cond
  | [] => []
  | x :: xs => insertCond x (sortConds xs)

def Ctx2.sorted (c : Ctx2) (s : Slot) : List Cond := sortConds (c.conds.filter (·.slot == s))

/-- Every condition fits its slot (RO domain and range). A lint, decided by `#guard`. -/
def Ctx2.fits (c : Ctx2) (k : Kind) : Bool :=
  c.conds.all fun x => match x.slot with
    | .subject => x.rel.accepts k x.kind
    | .cellType => x.rel.accepts .cellType x.kind
    | .taxon => x.rel.accepts .taxon x.kind

def inCtx2 {k : Kind} (e : Entity k) (c : Ctx2) : Entity k :=
  let cellConds := c.sorted .cellType
  let ct : Option (Entity .cellType) :=
    if cellConds.isEmpty then c.base.cellType
    else some (refineAll (c.base.cellType.getD ⟨"CL:0000000", "cell"⟩) cellConds)
  let taxConds := c.sorted .taxon
  let tx : Option (Entity .taxon) :=
    if taxConds.isEmpty then c.base.taxon else some (refineAll (c.base.taxon.getD Taxa.cellularOrganisms) taxConds)
  let e := e.refineOpt (Ctx.locRel k) c.base.anatomy (by cases k <;> decide)
  let e := e.refineOpt (Ctx.cellRel k) ct (by cases k <;> decide)
  let e := e.refineOpt (Ctx.locRel k) c.base.component (by cases k <;> decide)
  let e := refineAll e (c.sorted .subject)
  let e := e.refineOpt Rel.happensDuring c.base.stage (by cases k <;> decide)
  let e := e.refineOpt (Ctx.lifeStageRel k) c.base.lifeStage (by cases k <;> decide)
  e.refineOpt Rel.inTaxon tx (by cases k <;> decide)

/-- A core context as a `Ctx2`: an organism state refines the taxon, an environment the subject. -/
def Ctx2.ofCtx (c : Ctx) : Ctx2 :=
  { base := { c with condition := none },
    conds := match c.condition with
      | some (.organism s _) => [⟨.taxon, .state, s⟩]
      | some (.environment s) => [⟨.subject, .surroundings, s⟩]
      | none => [] }

/-- Dropping conditions is a subsumption: `e` in `big` is_a `e` in `small` when the conditions of
`small` are among those of `big` and the core slots agree. True in description logic for existential
restrictions, so `.definitional`, like `Entity.refineAxiom`. -/
def dropAxiom {k : Kind} (e : Entity k) (big small : Ctx2)
    (_hsub : small.conds.all (fun x => big.conds.any (·.key == x.key)) = true := by decide +kernel)
    (_hbase : ((inCtx2 e { big with conds := [] }).curie == (inCtx2 e { small with conds := [] }).curie) = true := by decide +kernel)
    (h : Rel.isA.accepts k k = true := by decide) : Statement :=
  { id := s!"drop:{(inCtx2 e big).curie}<{(inCtx2 e small).curie}", text := "fewer conditions, larger class",
    claim := .rel Rel.isA (inCtx2 e big) (inCtx2 e small) h,
    evidence := [{ pmid := 0, year := 0, kind := .definitional, note := "C ⊓ ∃r.F ⊓ ∃s.G ⊑ C ⊓ ∃s.G" }] }

/-! ## Entities (checked on OLS4, `data/stress/08/curies_checked.tsv`) -/

def prokCell   : Entity .cellType := ⟨"CL:0000520", "prokaryotic cell"⟩
def eukCell    : Entity .cellType := ⟨"CL:0000255", "eukaryotic cell"⟩
def enucleateRbc : Entity .cellType := ⟨"CL:0000595", "enucleate erythrocyte"⟩
def gtp        : Entity .chemical := ⟨"CHEBI:15996", "GTP"⟩
def purineNTP  : Entity .chemical := ⟨"CHEBI:26398", "purine ribonucleoside triphosphate"⟩
def meiosisI   : Entity .process := ⟨"GO:0007127", "meiosis I"⟩
def meiosisII  : Entity .process := ⟨"GO:0007135", "meiosis II"⟩
def meioticDivision : Entity .process := ⟨"GO:0140013", "meiotic nuclear division"⟩
def premeioticRep : Entity .process := ⟨"GO:0006279", "premeiotic DNA replication"⟩
def nondisjunction : Entity .process := ⟨"BLN:nondisjunction", "chromosome nondisjunction"⟩
def cytoplasm  : Entity .component := ⟨"GO:0005737", "cytoplasm"⟩
def pmCytoSide : Entity .component := ⟨"GO:0009898", "cytoplasmic side of plasma membrane"⟩
def erCytoSide : Entity .component := ⟨"GO:0098554", "cytoplasmic side of endoplasmic reticulum membrane"⟩
def carbohydrate : Entity .chemical := ⟨"CHEBI:16646", "carbohydrate"⟩
def glycoprotein : Entity .chemical := ⟨"CHEBI:17089", "glycoprotein"⟩
def glycolipid : Entity .chemical := ⟨"CHEBI:33563", "glycolipid"⟩
def carbDerivative : Entity .chemical := ⟨"CHEBI:63299", "carbohydrate derivative"⟩
def hypothalamus : Entity .anatomy := ⟨"UBERON:0001898", "hypothalamus"⟩
def vasodilation : Entity .process := ⟨"GO:0042311", "vasodilation"⟩
def vasoconstriction : Entity .process := ⟨"GO:0042310", "vasoconstriction"⟩
def vesselDiameter : Entity .process := ⟨"GO:0097746", "blood vessel diameter maintenance"⟩
def organism   : Entity .anatomy := ⟨"UBERON:0000468", "multicellular organism"⟩
def hair       : Entity .anatomy := ⟨"UBERON:0001037", "strand of hair"⟩
def feather    : Entity .anatomy := ⟨"UBERON:0000022", "feather"⟩
def adipose    : Entity .anatomy := ⟨"UBERON:0001013", "adipose tissue"⟩
def aves       : Entity .taxon := ⟨"NCBITaxon:8782", "Aves"⟩
def regCatalytic : Entity .process := ⟨"GO:0050790", "regulation of catalytic activity"⟩
def posRegCatalytic : Entity .process := ⟨"GO:0043085", "positive regulation of catalytic activity"⟩
def negRegCatalytic : Entity .process := ⟨"GO:0043086", "negative regulation of catalytic activity"⟩
def fork : Entity .component := ⟨"GO:0005657", "replication fork"⟩
def damaged := e_PATO_0001167
def rapid : Entity .phenotype := ⟨"BLN:rapidly_dividing", "rapidly dividing"⟩
def inCulture : Entity .phenotype := ⟨"BLN:grown_in_culture", "grown in culture"⟩
def cellCycle : Entity .process := ⟨"GO:0007049", "cell cycle"⟩
def aged : Entity .phenotype := ⟨"PATO:0001764", "increased age"⟩
def male : Entity .phenotype := ⟨"PATO:0000384", "male"⟩
def heat : Entity .phenotype := ⟨"PECO:0007173", "high temperature exposure"⟩
def drought : Entity .phenotype := ⟨"PECO:0007404", "drought exposure"⟩

/-! ## D. Disjunction under the prototypes -/

/-! ### Part 1 checks: the operators. -/
def ofR (r : ℚ) (pol : Opinion.Polarity) (h0 : 0 ≤ r := by norm_num) (h1 : r < 1 := by norm_num) : Opinion :=
  Opinion.ofReliability r h0 h1 pol
-- D14: evidence for A only (a textbook item, 0.8): "A or B" keeps b = 0.8 and has no disbelief.
theorem d14_or_one_side : (Op.orS (ofR (4/5) .supports) .vacuous).belief = 4 / 5 ∧
    (Op.orS (ofR (4/5) .supports) .vacuous).disbelief = 0 := by decide +kernel
-- D15: two independent disjuncts, each refuted at 0.8: "A or B" has d = 0.64, not refuted.
theorem d15_two_refuted : (Op.orS (ofR (4/5) .refutes) (ofR (4/5) .refutes)).disbelief = 16 / 25 := by decide +kernel
theorem d15_not_refuted : (Op.orS (ofR (4/5) .refutes) (ofR (4/5) .refutes)).verdict = .unsupported := by decide +kernel
-- D16: one reaction per TCA turn makes ATP (mass 1/2) or GTP (mass 2/5), exclusive, rest 0, u 1/10.
-- Coarsening adds (9/10, established); comultiplication of the two marginals (b 1/2, 2/5) gives 7/10.
def d16 : Op.Frame3 := { bA := 1/2, bB := 2/5, bRest := 0, u := 1/10 }
theorem d16_coarsen : d16.union.belief = 9 / 10 ∧ d16.union.verdict = .established := by decide +kernel
theorem d16_comul : (Op.orS d16.onA d16.onB).belief = 7 / 10 ∧ (Op.orS d16.onA d16.onB).disbelief = 1 / 5 := by decide +kernel
#eval proto "D14" "D-b" s!"or-intro from A (b 0.8): {ostr (Op.orS (ofR (4/5) .supports) .vacuous)}"
#eval proto "D15" "D-b" s!"two refuted disjuncts (d 0.8 each): {ostr (Op.orS (ofR (4/5) .refutes) (ofR (4/5) .refutes))}, {vstr (Op.orS (ofR (4/5) .refutes) (ofR (4/5) .refutes)).verdict}"
#eval proto "D16" "D-d" s!"exclusive frame coarsened: {ostr d16.union} ({vstr d16.union.verdict}); comultiplication instead: {ostr (Op.orS d16.onA d16.onB)} ({vstr (Op.orS d16.onA d16.onB).verdict})"

/-! ### D01. "All cells are either prokaryotic or eukaryotic" as `cell is_a (prokaryotic ⊔ eukaryotic)`.
With union elimination on the subject, the R2 statements "prokaryotic cells have a plasma membrane"
(m45429-54) and "eukaryotic cells have a plasma membrane" (m45429-62) give "every cell has a plasma
membrane", which R2 also states directly (m45429-5). -/
def prokEuk := unionE e_CL_0000520 e_CL_0000255
def d01_stmt : Statement :=
  { id := "cell-structure-and-function-m45428-11", text := "All cells are either prokaryotic or eukaryotic",
    claim := .rel Rel.isA e_CL_0000000 prokEuk, evidence := [tb "all are grouped into one of two broad categories"] }
def d01_pmProk := BioLean.Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45429_54
def d01_pmEuk := BioLean.Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45429_62
#guard d01_pmProk.claim.subjectCurie = prokCell.curie ∧ d01_pmEuk.claim.subjectCurie = eukCell.curie
def d01 : XDerivation (.base (.rel Rel.hasPart e_CL_0000000 e_GO_0005886)) :=
  .xRelChain (r₃ := Rel.hasPart) (.core (.lit d01_stmt))
    (.unionSubj (a := e_CL_0000520) (b := e_CL_0000255) (.lit d01_pmProk) (.lit d01_pmEuk))
theorem d01_established : d01.verdict = .established := by decide +kernel
#eval proto "D01" "D-c" s!"stated cell is_a (prok ⊔ euk); derived '{(XClaim.base (.rel Rel.hasPart e_CL_0000000 e_GO_0005886))}' {vstr d01.verdict}, axioms {d01.axiomIds}"
#eval proto "D01" "D-b" "Claim-level or needs one is_a claim per disjunct and orElim; same result, two hypotheses"

/-! ### D02. No disjunctive syllogism: the prototype has no general negation, so nothing makes an
enucleate erythrocyte prokaryotic. -/
#guard !Ontology.isACurie enucleateRbc.curie prokCell.curie
#eval proto "D02" "D-b,D-c" "no rule from 'not eukaryotic' to 'prokaryotic' (no general negation); nothing derived"

/-! ### D03. "One ATP (or an equivalent)" as `TCA has output (ATP ⊔ GTP)`: true as stated, and it
coarsens soundly to "has output a purine NTP". Same result by claim-level `or` and case analysis. -/
def atpGtp := unionE e_CHEBI_15422 gtp
def d03_stmt : Statement :=
  { id := "how-cells-obtain-energy-m45439-28", text := "One ATP (or an equivalent) is made per cycle",
    claim := .rel Rel.hasOutput e_GO_0006099 atpGtp, evidence := [tb "One ATP (or an equivalent) is also made in each cycle."] }
def d03_union : Derivation (.rel Rel.hasOutput e_GO_0006099 purineNTP) :=
  .relChain (r₃ := Rel.hasOutput) (.lit d03_stmt) (.lit (unionLub e_CHEBI_15422 gtp purineNTP))
theorem d03_union_established : d03_union.verdict = .established := by decide +kernel
def d03_or : XStatement :=
  { id := "how-cells-obtain-energy-m45439-28/or", text := "TCA has output ATP, or TCA has output GTP",
    claim := .or (.base (.rel Rel.hasOutput e_GO_0006099 e_CHEBI_15422)) (.base (.rel Rel.hasOutput e_GO_0006099 gtp)),
    evidence := [tb "One ATP (or an equivalent) is also made in each cycle."] }
def d03_elim : XDerivation (.base (.rel Rel.hasOutput e_GO_0006099 purineNTP)) :=
  .orElim (.lit d03_or) (fun d => .relChain (r₃ := Rel.hasOutput) d (.lit (isaAx e_CHEBI_15422 purineNTP)))
    (fun d => .relChain (r₃ := Rel.hasOutput) d (.lit (isaAx gtp purineNTP)))
theorem d03_elim_established : d03_elim.verdict = .established := by decide +kernel
#eval proto "D03" "D-c" s!"TCA has output (ATP ⊔ GTP) stated; coarsened to purine NTP, {vstr d03_union.verdict}"
#eval proto "D03" "D-b" s!"orElim over the two disjuncts gives the same, {ostr d03_elim.opinion}, axioms {d03_elim.axiomIds}"

/-! ### D05, D06, D07, D09: object-side "or"s become one `rel` with a union filler. -/
def d05 : Claim := .rel Rel.happensDuring nondisjunction (unionE meiosisI meiosisII)
def d05_coarse : Derivation (.rel Rel.happensDuring nondisjunction meioticDivision) :=
  .relChain (r₃ := Rel.happensDuring)
    (.lit { id := "the-cellular-basis-of-inheritance-m45467-34", text := "Nondisjunction can occur during either meiosis I or II",
            claim := d05, evidence := [tb "Nondisjunction can occur during either meiosis I or II"] })
    (.lit (unionLub meiosisI meiosisII meioticDivision))
theorem d05_coarse_established : d05_coarse.verdict = .established := by decide +kernel
#eval proto "D05" "D-c" s!"stated '{d05}'; coarsened to meiotic nuclear division, {vstr d05_coarse.verdict} (subject still BLN)"
/- D06. -311 is a three-way "or" over every ribosome: cytoplasm ⊔ (PM side ⊔ ER side). -183 says
ribosomes "may be attached to either" side: a `some` claim, not a universal. (Review 2026-10-31: the
first version stated -183's two-way union as a universal, which says every ribosome is attached to a
membrane: false for free ribosomes.) -/
def d06 : Claim := .rel Rel.locatedIn e_GO_0005840 (unionE cytoplasm (unionE pmCytoSide erCytoSide))
def d06_some : Claim := .quant .some (.rel Rel.locatedIn e_GO_0005840 (unionE pmCytoSide erCytoSide))
#guard d06.toString.endsWith "[(GO:0005737|(GO:0009898|GO:0098554))]"
#eval proto "D06" "D-c" s!"stated '{d06}' (true for all three places) and, for -183, 'some ribosomes located in PM side or ER side'"
def d07 : Claim := .rel Rel.partOf carbohydrate (unionE glycoprotein glycolipid)
def d07_coarse : Derivation (.rel Rel.partOf carbohydrate carbDerivative) :=
  .relChain (r₃ := Rel.partOf)
    (.lit { id := "cell-structure-and-function-m45433-53", text := "bound either to proteins or to lipids", claim := d07,
            evidence := [tb "bound either to proteins (forming glycoproteins) or to lipids (forming glycolipids)"] })
    (.lit (unionLub glycoprotein glycolipid carbDerivative))
theorem d07_coarse_established : d07_coarse.verdict = .established := by decide +kernel
#eval proto "D07" "D-c" s!"stated '{d07}' (exhaustive); coarsened to part of a carbohydrate derivative, {vstr d07_coarse.verdict}"
def endotherm := unionE Taxa.mammalia aves
def d09 : Claim := .rel Rel.hasPart (organism.inCtx { taxon := endotherm }) (unionE (unionE hair adipose) feather)
#guard !Taxa.known endotherm
#eval proto "D09" "D-c" s!"stated '{d09.subjectCurie} has part (hair ⊔ adipose) ⊔ feather'; the union taxon is unknown to Taxa, so no transport or coverage"

/-! ### D08, D11: a union of processes as an effect target is stateable, but no rule moves an effect to
a superclass target (the sign may not survive), so nothing follows. The split by condition (D08)
stays the right encoding. D11 needs GO:0043085 in the imported closure, not a schema change. -/
def d08 : Claim := .effect hypothalamus .pos (.process (unionE vasodilation vasoconstriction))
#eval proto "D08" "D-c" s!"stated '{d08}'; weaker than the split by condition; nothing derived"
#guard !Ontology.isACurie posRegCatalytic.curie regCatalytic.curie
#check_failure (unionLub posRegCatalytic negRegCatalytic regCatalytic)
#eval proto "D12" "D-a" "no prototype needed: the split into two claims is stateable in today's core (stress file, d12_drought, d12_underwatered)"
#eval proto "D11" "D-c" "union of GO:0043085 and GO:0043086 stateable; unionLub to GO:0050790 refused: GO:0043085 is not in the imported closure"

/-! ### D13. "before the cell enters mitosis or meiosis" as precedes (mitotic ⊔ meiotic division). The is_a
law now gives "premeiotic DNA replication precedes (mitotic ⊔ meiotic division)": true. The FAIL of
the stress file is gone, and the coarsening to nuclear division still follows. -/
def mitMei := unionE e_GO_0140014 meioticDivision
def d13_stmt : Statement :=
  { id := "molbio-m45475-4", text := "DNA replication occurs before mitosis or meiosis",
    claim := .rel Rel.precedes e_GO_0006260 mitMei, evidence := [tb "before the cell enters mitosis or meiosis"] }
def d13_premeiotic : Derivation (.rel Rel.precedes premeioticRep mitMei) :=
  .relChain (r₃ := Rel.precedes) (.lit (isaAx premeioticRep e_GO_0006260)) (.lit d13_stmt)
def d13_coarse : Derivation (.rel Rel.precedes e_GO_0006260 e_GO_0000280) :=
  .relChain (r₃ := Rel.precedes) (.lit d13_stmt) (.lit (unionLub e_GO_0140014 meioticDivision e_GO_0000280))
theorem d13_coarse_established : d13_coarse.verdict = .established := by decide +kernel
theorem d13_premeiotic_established : d13_premeiotic.verdict = .established := by decide +kernel
#eval proto "D13" "D-c" s!"derived '{d13_premeiotic.claim}' (true); coarsening to nuclear division {vstr d13_coarse.verdict}"

/-! ### D17. A claim-level "or" from the book (added in review): two hedged explanations of why trisomy
21 is survivable (the-cellular-basis-of-inheritance-m45467-139). D-b states it; each disjunct alone
gets no belief, and the "or" carries the textbook weight. D-c cannot state it (two claims with
different predicates). The placeholder terms are as in the stress file. -/
def chr21Gene : Entity .gene := ⟨"BLN:chromosome_21_gene", "gene on chromosome 21"⟩
def chr18Gene : Entity .gene := ⟨"BLN:chromosome_18_gene", "gene on chromosome 18"⟩
def inCriticalPathway : Entity .phenotype := ⟨"BLN:involvement_in_critical_pathways", "involvement in critical pathways"⟩
def dosageEffect : Entity .phenotype := ⟨"BLN:dosage_effect_on_pathways", "effect of dosage on pathways"⟩
def d17_or : XStatement :=
  { id := "the-cellular-basis-of-inheritance-m45467-139", text := "The genes may be less involved in critical pathways, or the differences in dosage may make less of a difference to those pathways.",
    claim := .or (.base (.less chr21Gene chr18Gene inCriticalPathway)) (.base (.less chr21Gene chr18Gene dosageEffect)),
    evidence := [tb "The genes may be less involved in critical pathways, or the differences in dosage may make less of a difference"] }
theorem d17_or_established : (XDerivation.lit d17_or).verdict = .established := by decide +kernel
#eval proto "D17" "D-b" s!"stated '{d17_or.claim}' at {ostr (XDerivation.lit d17_or).opinion}; neither disjunct is asserted (no statement carries it alone)"
#eval proto "D17" "D-c" "not stateable: two claims with different predicates, no shared slot for a union"

/-! ## A. Approximate numbers under the prototype (A-b)

Two conventions for a bare "about n": `pct n (1/10)` (± 10 percent) and `digit n place` (± half a unit
in the last stated digit). A stated range is `range lo hi`. Textbook items are `XStatement`s at
textbook weight. -/

def tbA (id text : String) (s : QShape) (a : Approx) : XStatement := ⟨id, text, .about s a, [tb text]⟩
def humanRbc := e_CL_0000232.inCtx { taxon := e_NCBITaxon_9606 }

-- A01, A02: red cell diameter and thickness against Bandaru and Killeen (PMID 32965812).
def a01_book := tbA "cell-structure-and-function-m45428-20" "about eight micrometers" (.measure humanRbc e_PATO_0001334 "µm") (.pct 8 (1/10))
def a01_data : XStatement := ⟨"PMID:32965812", "6.2 to 8.2 µm", .about (.measure humanRbc e_PATO_0001334 "µm") (.range (31/5) (41/5)),
  [paper 32965812 2026 .review "Bandaru and Killeen"]⟩
#guard (XDerivation.lit a01_book).clash (.lit a01_data) |>.isNone
#eval proto "A01" "A-b" "about 8 µm (±10%) overlaps the data 6.2 to 8.2 µm: consistent, no clash"
def a02_book := tbA "cell-structure-and-function-m45433-32" "approximately 8 µm thick" (.measure humanRbc e_PATO_0000915 "µm") (.pct 8 (1/10))
def a02_data : XStatement := ⟨"PMID:32965812", "0.8 to 2.5 µm thick", .about (.measure humanRbc e_PATO_0000915 "µm") (.range (4/5) (5/2)),
  [paper 32965812 2026 .review "Bandaru and Killeen"]⟩
def a02_clash := (XDerivation.lit a02_book).clash (.lit a02_data)
theorem a02_flagged : (a02_clash.map (·.verdict)) = some .unsupported := by decide +kernel
theorem a02_clash_belief : (a02_clash.map (·.belief.toDecimal 2)) = some "0.61" ∧ (a02_clash.map (·.disbelief.toDecimal 2)) = some "0.23" := by decide +kernel
#eval proto "A02" "A-b" s!"about 8 µm (±10%) against 0.8 to 2.5 µm: clash flagged; the book value becomes {(a02_clash.map ostr).getD "-"} (unsupported, was established)"
-- A03: trachea, a stated range, against Kumari 2019.
def trachea := e_UBERON_0003126.inCtx { taxon := e_NCBITaxon_9606 }
def a03_book := tbA "the-body-s-systems-m45536-45" "about 25 to 30 cm" (.measure trachea e_PATO_0000122 "cm") (.range 25 30)
def a03_data : XStatement := ⟨"PMID:31828242", "10.14 ± 2.04 cm", .about (.measure trachea e_PATO_0000122 "cm") (.range (606/100) (1422/100)),
  [paper 31828242 2019 .observational "Kumari 2019"]⟩
def a03_clash := (XDerivation.lit a03_book).clash (.lit a03_data)
theorem a03_flagged : (a03_clash.map (·.verdict)) = some .unsupported := by decide +kernel
theorem a03_clash_belief : (a03_clash.map (·.belief.toDecimal 2)) = some "0.66" ∧ (a03_clash.map (·.disbelief.toDecimal 2)) = some "0.16" := by decide +kernel
#eval proto "A03" "A-b" s!"25 to 30 cm against 6.06 to 14.22 cm: clash flagged, book value {(a03_clash.map ostr).getD "-"}"
-- A04: E. coli genome "4.6 million" (last digit 0.1 million) against Blattner's 4,639,221.
def ecoliGenome := e_SO_0001026.inCtx { taxon := e_NCBITaxon_562 }
def a04_book := tbA "molbio-m45473-77" "4.6 million base pairs" (.count ecoliGenome e_SO_0000028) (.digit 4600000 100000)
def a04_data : XStatement := ⟨"PMID:9278503", "4,639,221 bp", .about (.count ecoliGenome e_SO_0000028) (.exact 4639221),
  [paper 9278503 1997 .observational "Blattner 1997"]⟩
#guard (XDerivation.lit a04_book).clash (.lit a04_data) |>.isNone
#eval proto "A04" "A-b" "4.6 million (±0.05 million) contains 4,639,221: consistent"
-- A05: per fork, from the rounded and from the measured genome.
def a05_forks : Statement := ⟨"SYNTHETIC:two-forks", "two forks", .count ecoliGenome fork 2, [tb "in both directions"]⟩
def a05_book := XDerivation.perSetA (.lit a04_book) (.lit a05_forks)
def a05_data := XDerivation.perSetA (.lit a04_data) (.lit a05_forks)
#guard (Approx.digit 4600000 100000).scale (1/2) = ⟨2300000, 2275000, 2325000, .derived⟩
#guard ((Approx.exact 4639221).scale (1/2)).lo = 4639221 / 2
#eval proto "A05" "A-b" "per fork: [2275000, 2325000] from the book; exactly 4639221/2 from the data (no odd-number failure)"
-- A06: rate per fork = (per-fork count) / (42 min, last digit 1 min, in seconds).
def repEcoli := e_GO_0006260.inCtx { taxon := e_NCBITaxon_562 }
def a06_time := tbA "molbio-m45475-97" "approximately 42 minutes" (.measure repEcoli e_PATO_0001309 "s") (.digit 2520 60)
def a06_rate := XDerivation.ratioA a05_book (.lit a06_time)
def a06_book : Approx := .pct 1000 (1/10)
#guard (Approx.div ((Approx.digit 4600000 100000).scale (1/2)) (.digit 2520 60)).overlaps a06_book
#guard (Approx.div ((Approx.digit 4600000 100000).scale (1/2)) (.digit 2520 60)) = ⟨57500 / 63, 2275000 / 2550, 2325000 / 2490, .derived⟩
#eval proto "A06" "A-b" s!"derived rate {(Approx.div ((Approx.digit 4600000 100000).scale (1/2)) (.digit 2520 60))} nt/s per fork; overlaps the book's about 1000: consistent"
-- A07: 15 per minute → per hour → per day.
def breath := e_GO_0003016.inCtx { taxon := e_NCBITaxon_9606 }
def a07_min := tbA "the-body-s-systems-m45536-16" "approximately 15 times per minute" (.measure breath e_PATO_0000044 "breaths/min") (.pct 15 (1/10))
def a07_hour := XDerivation.scaleA "breaths/h" 60 (.lit a07_min)
def a07_day := XDerivation.scaleA "breaths/day" 24 a07_hour
#guard ((Approx.pct 15 (1/10)).scale 60).contains 900 ∧ (((Approx.pct 15 (1/10)).scale 60).scale 24).contains 21600
#eval proto "A07" "A-b" s!"15/min (±10%) gives {(Approx.pct 15 (1/10)).scale 60} per hour and {((Approx.pct 15 (1/10)).scale 60).scale 24} per day; both book values inside"
-- A08: "around 100,000, the same number as a lobster": overlap, not equality.
def flyNS := e_UBERON_0001016.inCtx { taxon := e_NCBITaxon_7227 }
def lobsterNS := e_UBERON_0001016.inCtx { taxon := e_NCBITaxon_6705 }
#guard (Approx.pct 100000 (1/10)).overlaps (.pct 100000 (1/10)) ∧ (Approx.pct 100000 (1/10)) ≠ .exact 100000
#guard !(Approx.pct 100000 (1/10)).contains 139255 ∧ (Approx.digit 100000 100000).contains 139255
#eval proto "A08" "A-b" "fly and lobster: overlap (consistent), equality no longer claimed. 139,255 (fly brain alone) is outside ±10% but inside the last-digit reading [50000, 150000]"
-- A09: 86 billion against Azevedo 86.1 ± 8.1 billion.
def humanBrain := e_UBERON_0000955.inCtx { taxon := e_NCBITaxon_9606 }
def a09_book := tbA "the-body-s-systems-m45539-40" "around 86 billion" (.count humanBrain e_CL_0000540) (.pct 86000000000 (1/10))
def a09_data : XStatement := ⟨"PMID:19226510", "86.1 ± 8.1 billion", .about (.count humanBrain e_CL_0000540) (.range 78000000000 94200000000),
  [paper 19226510 2009 .observational "Azevedo 2009"]⟩
#guard (XDerivation.lit a09_book).clash (.lit a09_data) |>.isNone
#eval proto "A09" "A-b" "around 86 billion (±10%) overlaps 86.1 ± 8.1 billion: consistent"
-- A10: fly against human, counts with intervals.
def a08_fly := tbA "the-body-s-systems-m45539-36" "around 100,000 neurons" (.count flyNS e_CL_0000540) (.pct 100000 (1/10))
def a10 : XDerivation (.fewer flyNS humanBrain e_CL_0000540) := .fewerA (.lit a08_fly) (.lit a09_book)
theorem a10_established : a10.verdict = .established := by decide +kernel
#eval proto "A10" "A-b" s!"derived '{XClaim.fewer flyNS humanBrain e_CL_0000540}' {vstr a10.verdict}"
-- A11, A12: not fixed by tolerance.
#guard (Approx.pct 1000 (1/10)).contains 700 = false ∧ (Approx.digit 1000 1000).contains 700
#eval proto "A11" "A-b" "unchanged: 'about 50' as a lower bound still refutes ChEBI's ten-residue polypeptides; the problem is 'typical', not 'about'"
#eval proto "A12" "A-b" "unchanged: no rule from a clade measure to rat or human; and the convention decides: 700/day is outside ±10% of 1000, inside the last-digit reading"
-- A13: red cells across a pin head, 2 mm in µm over 8 µm.
def pinHead : Entity .anatomy := ⟨"BLN:pin_head", "head of a pin (not biological)"⟩
def a13_pin := tbA "cell-structure-and-function-m45428-21" "about two thousandths of a meter" (.measure pinHead e_PATO_0001334 "µm") (.pct 2000 (1/10))
def a13 := XDerivation.ratioA (.lit a13_pin) (.lit a01_book)
#guard (Approx.div (.pct 2000 (1/10)) (.pct 8 (1/10))).contains 250
#guard (Approx.div (.pct 2000 (1/10)) (.pct 8 (1/10))) = ⟨250, 2250 / 11, 2750 / 9, .derived⟩
#eval proto "A13" "A-b" s!"derived {Approx.div (.pct 2000 (1/10)) (.pct 8 (1/10))} red cells across the pin head (a width ratio); contains 250. The book says 'fit on'; by area that is about 49,000, and ratioA cannot tell a width from an area"
-- A14, A15: the exact controls embed and still fire.
def a14 : XDerivation (.base (.quant .some (.atLeast BioLean.Quantity.aminoAcid BioLean.Quantity.senseCodon 2))) :=
  .pigeonholeA (.ofCard (.lit BioLean.Quantity.S_sense61)) (.ofCard (.lit BioLean.Quantity.S_aa20)) (.lit BioLean.Quantity.S_oneEach)
theorem a14_established : a14.verdict = .established := by decide +kernel
def a15 := XDerivation.perSetA (.ofCount (.lit BioLean.Quantity.S_46)) (.lit BioLean.Quantity.S_2sets)
#guard (Approx.exact 46).scale (1 / 2) = ⟨23, 23, 23, .derived⟩
#eval proto "A14" "A-b" s!"exact counts embed; pigeonholeA fires, {vstr a14.verdict}"
#eval proto "A15" "A-b" "exact counts embed; perSetA gives exactly 23"
-- A16: about 100 made, about 90 used.
def synth : Entity .process := ⟨"BLN:synthetic_process", "a synthetic process"⟩
def a16 := XDerivation.netA (.lit (tbA "SYNTHETIC:made" "about 100" (.produces synth e_CHEBI_15422) (.pct 100 (1/10))))
  (.lit (tbA "SYNTHETIC:used" "about 90" (.consumes synth e_CHEBI_15422) (.pct 90 (1/10))))
#guard (Approx.sub (.pct 100 (1/10)) (.pct 90 (1/10))).lo < 0 ∧ 0 < (Approx.sub (.pct 100 (1/10)) (.pct 90 (1/10))).hi
#guard (Approx.sub (.pct 100 (1/10)) (.pct 90 (1/10))) = ⟨10, -9, 29, .derived⟩
#eval proto "A16" "A-b" s!"net {Approx.sub (.pct 100 (1/10)) (.pct 90 (1/10))}: sign unknown, no exact yield"
-- A17: about 22 items, about 20 holes: pigeonholeA is refused.
#guard decide ((Approx.pct 20 (1/10)).hi < (Approx.pct 22 (1/10)).lo) = false
#check_failure (XDerivation.pigeonholeA (.lit (tbA "SYNTHETIC:22" "about 22 items" (.card e_CHEBI_15422) (.pct 22 (1/10))))
  (.lit (tbA "SYNTHETIC:20" "about 20 holes" (.card gtp) (.pct 20 (1/10))))
  (.lit ⟨"SYNTHETIC:one-each", "each item has one hole", .count e_CHEBI_15422 gtp 1, [tb "synthetic"]⟩))
-- positive control: with about 30 items against about 20 holes the same rule fires, so the refusal
-- above is the interval test, not a failure to compute
def a17_control := XDerivation.pigeonholeA (.lit (tbA "SYNTHETIC:30" "about 30 items" (.card e_CHEBI_15422) (.pct 30 (1/10))))
  (.lit (tbA "SYNTHETIC:20" "about 20 holes" (.card gtp) (.pct 20 (1/10))))
  (.lit ⟨"SYNTHETIC:one-each", "each item has one hole", .count e_CHEBI_15422 gtp 1, [tb "synthetic"]⟩)
#eval proto "A17" "A-b" "pigeonholeA refused: holes up to 22, items down to 19.8"
#eval proto "A18" "A-b" "unchanged (the core's less is kept)"

/-! ## C. A second context slot under the prototype (C-b) -/

/-! Compatibility: with zero or one condition, `inCtx2` gives the core curie. Checked on four real R3
subjects (celiac, X inactivation, hypotonic import, hot dry day). -/
#guard (inCtx2 e_GO_0006955 (.ofCtx { taxon := e_NCBITaxon_9606, condition := some (.organism e_MONDO_0005130) })).curie =
  BioLean.Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45432_24.claim.subjectCurie
#guard (inCtx2 e_GO_0009048 (.ofCtx { taxon := e_NCBITaxon_40674, lifeStage := e_UBERON_0000068, condition := some (.organism e_PATO_0000383) })).curie =
  BioLean.Textbook.R3.TheCellularBasisOfInheritance.the_cellular_basis_of_inheritance_m45467_58.claim.subjectCurie
#guard (inCtx2 e_GO_0098657 (.ofCtx { cellType := e_CL_0000000, condition := some (.environment e_PATO_0001656) })).curie =
  BioLean.Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45434_70.claim.subjectCurie
#guard (inCtx2 e_NCBITaxon_33090 (.ofCtx { condition := some (.environment e_BLN_hot_dry_day) })).curie =
  BioLean.Textbook.R3.Photosynthesis.photosynthesis_m45448_84.claim.subjectCurie
#eval proto "C06" "C-b" "same curie as the core (pinned)"
#eval proto "C07" "C-b" "same curie as the core (pinned)"
#eval proto "C15" "C-b" "unchanged (two core slots)"

-- C01: damaged endothelial cells, the state on the subject.
def c01 := inCtx2 e_CL_0000115 { base := { anatomy := e_UBERON_0001981 }, conds := [⟨.subject, .state, damaged⟩] }
#guard c01.curie = "CL:0000115&RO:0001025=(UBERON:0001981)&RO:0002573=(PATO:0001167)"
#eval proto "C01" "C-b" s!"subject '{c01.curie}' (the cells are damaged)"
-- C02, C03: states of the cells, on the cell-type filler.
def c02 := inCtx2 e_GO_0051318 { base := { taxon := e_NCBITaxon_9606, cellType := e_CL_0000000 }, conds := [⟨.cellType, .state, rapid⟩] }
#guard c02.curie = "GO:0051318&BFO:0000066=(CL:0000000&RO:0002573=(BLN:rapidly_dividing))&RO:0002162=(NCBITaxon:9606)"
#guard ({ conds := [⟨.subject, .state, rapid⟩] } : Ctx2).fits .process = false
def c03a := inCtx2 cellCycle { base := { taxon := e_NCBITaxon_40674 }, conds := [⟨.cellType, .state, rapid⟩, ⟨.cellType, .state, inCulture⟩] }
def c03b := inCtx2 cellCycle { base := { taxon := e_NCBITaxon_40674 }, conds := [⟨.cellType, .state, inCulture⟩, ⟨.cellType, .state, rapid⟩] }
#guard c03a.curie = c03b.curie
#eval proto "C02" "C-b" s!"subject '{c02.curie}'; a state on the process itself is refused by fits (has_modifier domain)"
#eval proto "C03" "C-b" s!"two cell states, one curie in either order: '{c03a.curie}'"
-- C04: two organism states, transported to rat.
def c04_two : Statement :=
  { id := "PMID:21113150", text := "aged telomerase-deficient mice",
    claim := .effect (e_GO_0003720.inCtx { taxon := some ([aged, e_BLN_telomerase_deficient].foldl (fun x st => x.refine Rel.hasModifier st) e_NCBITaxon_10090) })
      .neg (.phenotype e_HP_0002180),
    evidence := [paper 21113150 2011 .mechanistic "Jaskelioff 2011"] }
def xs : Evidence := { pmid := 0, year := 2026, kind := .crossSpecies, note := "placeholder mouse-to-rat item" }
def c04 := XDerivation.transport2 {} [aged, e_BLN_telomerase_deficient] (T₁ := e_NCBITaxon_10090) Taxa.rat (.lit c04_two) xs
theorem c04_belief : c04.opinion.belief = 21 / 100 := by decide +kernel
#eval proto "C04" "C-b" s!"two-state transport to rat works: {ostr c04.opinion}"
-- C05: one set of states, one curie.
def c05a := inCtx2 e_NCBITaxon_10090 { conds := [⟨.subject, .state, aged⟩, ⟨.subject, .state, e_BLN_telomerase_deficient⟩] }
def c05b := inCtx2 e_NCBITaxon_10090 { conds := [⟨.subject, .state, e_BLN_telomerase_deficient⟩, ⟨.subject, .state, aged⟩] }
#guard c05a.curie = c05b.curie
#eval proto "C05" "C-b" s!"both orders give '{c05a.curie}'"
-- C08: the solution around the cells.
def c08 := inCtx2 e_GO_0098657 { base := { cellType := e_CL_0000000 }, conds := [⟨.cellType, .surroundings, e_PATO_0001656⟩] }
#guard c08.curie = "GO:0098657&BFO:0000066=(CL:0000000&RO:0002219=(PATO:0001656))"
#eval proto "C08" "C-b" s!"subject '{c08.curie}' (solution around the cell)"
-- C09, C10: hot and dry as two conditions; a drought claim specialises, a hot-only claim does not follow.
def hotDry : Ctx2 := { conds := [⟨.subject, .surroundings, heat⟩, ⟨.subject, .surroundings, drought⟩] }
def droughtOnly : Ctx2 := { conds := [⟨.subject, .surroundings, drought⟩] }
def c10_drought : Statement :=
  { id := "PMID:36499153", text := "stomatal closure under drought",
    claim := .rel Rel.capableOf (inCtx2 e_NCBITaxon_33090 droughtOnly) e_GO_0090332, evidence := [paper 36499153 2022 .review "Liu 2022"] }
def c10 : Derivation (.rel Rel.capableOf (inCtx2 e_NCBITaxon_33090 hotDry) e_GO_0090332) :=
  .relChain (r₃ := Rel.capableOf) (.lit (dropAxiom e_NCBITaxon_33090 hotDry droughtOnly)) (.lit c10_drought)
theorem c10_belief : c10.opinion.belief = 3 / 5 := by decide +kernel
#eval proto "C10" "C-b" s!"drought claim specialises to hot and dry: {ostr c10.opinion} (review weight)"
def heatOnly : Ctx2 := { conds := [⟨.subject, .surroundings, heat⟩] }
-- a hot-only class is not a subclass of the hot-and-dry class: dropAxiom refuses it
#check_failure (dropAxiom e_NCBITaxon_33090 heatOnly hotDry)
#eval proto "C09" "C-b" "still nothing derives 'plants close stomata when hot' (dropAxiom refuses heat-only is_a hot-and-dry)"
-- C11: monotone inheritance across glucose is still derivable (FAIL stays).
def lacCtx : Ctx2 := { base := { taxon := e_NCBITaxon_562 } }
def lacGlc : Ctx2 := { base := { taxon := e_NCBITaxon_562 }, conds := [⟨.taxon, .surroundings, e_CHEBI_17234⟩] }
#guard (inCtx2 e_CHEBI_17716 lacGlc).curie = "CHEBI:17716&RO:0002162=(NCBITaxon:562&RO:0002219=(CHEBI:17234))"
#guard (inCtx2 e_CHEBI_17716 lacCtx).curie = BioLean.Textbook.R3.MolecularBiology.molbio_m45480_33.claim.subjectCurie
def c11 : Derivation (.effect (inCtx2 e_CHEBI_17716 lacGlc) .pos (.process e_GO_0005990)) :=
  .isaInheritEffect (.lit (dropAxiom e_CHEBI_17716 lacGlc lacCtx)) (.lit BioLean.Textbook.R3.MolecularBiology.molbio_m45480_33)
theorem c11_established : c11.verdict = .established := by decide +kernel
#eval proto "C11" "C-b" s!"still derived: lactose in E. coli on glucose ->+ lactose catabolism, {vstr c11.verdict} (wrong)"
-- C12: an environment and an organism state together, in canonical form.
def c12ctx : Ctx2 := { base := { taxon := e_NCBITaxon_562 }, conds := [⟨.subject, .surroundings, e_CHEBI_17716⟩, ⟨.taxon, .surroundings, e_CHEBI_17234⟩] }
def c12 : Derivation (.effect (inCtx2 e_CHEBI_36229 c12ctx) .neg (.activity e_PR_000023070)) :=
  .isaInheritEffect (.lit (dropAxiom e_CHEBI_36229 c12ctx (.ofCtx { taxon := e_NCBITaxon_562, condition := some (.environment e_CHEBI_17716) })))
    (.lit BioLean.Textbook.R3.MolecularBiology.molbio_m45480_41)
theorem c12_established : c12.verdict = .established := by decide +kernel
#eval proto "C12" "C-b" s!"derived for '{(inCtx2 e_CHEBI_36229 c12ctx).curie}', {vstr c12.verdict}, a canonical inCtx2 form"
-- C13: male tortoiseshell, either order.
def tortoise : Ctx2 := .ofCtx { taxon := e_NCBITaxon_9685, condition := some (.organism e_BLN_tortoiseshell) }
def maleTortoise : Ctx2 := { base := { taxon := e_NCBITaxon_9685 }, conds := [⟨.taxon, .state, male⟩, ⟨.taxon, .state, e_BLN_tortoiseshell⟩] }
#guard (inCtx2 e_GO_0009048 tortoise).curie = BioLean.Textbook.R3.TheCellularBasisOfInheritance.the_cellular_basis_of_inheritance_m45467_63.claim.subjectCurie
def tortoiseMale : Ctx2 := { base := { taxon := e_NCBITaxon_9685 }, conds := [⟨.taxon, .state, e_BLN_tortoiseshell⟩, ⟨.taxon, .state, male⟩] }
#guard (inCtx2 e_GO_0009048 maleTortoise).curie = (inCtx2 e_GO_0009048 tortoiseMale).curie
def c13 : Derivation (.effect (inCtx2 e_GO_0009048 maleTortoise) .pos (.phenotype e_PATO_0001533)) :=
  .isaInheritEffect (.lit (dropAxiom e_GO_0009048 maleTortoise tortoise)) (.lit BioLean.Textbook.R3.TheCellularBasisOfInheritance.the_cellular_basis_of_inheritance_m45467_63)
theorem c13_established : c13.verdict = .established := by decide +kernel
#eval proto "C13" "C-b" s!"derived for male tortoiseshell cats, {vstr c13.verdict}, whichever order the states are written"
#eval proto "C14" "C-b" "unchanged: the fix is the secretion reading, stateable in the core today (emitter)"

end BioLean.Proto.SchemaGaps
