import BioLean.Ontology
import BioLean.RO

/-!
# Claims

A `Claim` is the formal counterpart of one sentence in a paper. The vocabulary is
deliberately small and close to INDRA / Biolink: an agent has a signed effect on a
target. Signs compose, so a chain of effects has a well-defined overall sign. A
second constructor records a *mechanistic* claim: that an effect runs via some
intermediate target. Competing hypotheses are usually competing `mediatedBy` claims.
-/

namespace BioLean

/-- Direction of an effect. -/
inductive Sign
  | pos
  | neg
  deriving DecidableEq, Repr

namespace Sign

/-- Composition of signs along a causal chain. -/
def mul : Sign → Sign → Sign
  | .pos, s => s
  | .neg, .pos => .neg
  | .neg, .neg => .pos

instance : Mul Sign := ⟨mul⟩

@[simp] theorem pos_mul (s : Sign) : pos * s = s := rfl
@[simp] theorem neg_mul_pos : neg * pos = neg := rfl
@[simp] theorem neg_mul_neg : neg * neg = pos := rfl

theorem mul_comm (s t : Sign) : s * t = t * s := by
  cases s <;> cases t <;> rfl

theorem mul_assoc (s t v : Sign) : s * t * v = s * (t * v) := by
  cases s <;> cases t <;> cases v <;> rfl

def arrow : Sign → String
  | .pos => "→+"
  | .neg => "→−"

end Sign

/-- What an effect acts on. -/
inductive Target
  /-- The activity of a protein, or a GO molecular function itself (the honest grounding for
  "enzymes", "receptors", "channels" when no specific protein is named). -/
  | activity {k : Kind} (p : Entity k) (h : k = .protein ∨ k = .function := by decide)
  /-- The abundance of a molecule (a chemical or a protein). -/
  | amount {k : Kind} (m : Entity k)
  /-- A biological process. -/
  | process (p : Entity .process)
  /-- A phenotype or quality. -/
  | phenotype (p : Entity .phenotype)
  /-- An anatomical site at which an effect is exerted. -/
  | site (a : Entity .anatomy)

instance : ToString Target where
  toString
    | .activity p _ => s!"activity of {p}"
    | .amount m => s!"amount of {m}"
    | .process p => s!"{p}"
    | .phenotype p => s!"{p}"
    | .site a => s!"site {a}"

instance : Repr Target := ⟨fun t _ => toString t⟩

namespace Rel

/-- Does relation `r` admit subject kind `k₁` and object kind `k₂`, by RO's rdfs:domain and
rdfs:range? Relations with no declared domain or range accept anything. Inverses swap the two. -/
def accepts (r : Rel) (k₁ k₂ : Kind) : Bool :=
  let base := { r with inv := false }
  let (d, g) := if r.inv then (RO.ranges, RO.domains) else (RO.domains, RO.ranges)
  (match d.lookup base with | some s => s == k₁.sort | none => true) &&
  (match g.lookup base with | some s => s == k₂.sort | none => true)

def label (r : Rel) : String :=
  let base := { r with inv := false }
  let l := match RO.labels.lookup base with
    | some l => l
    | none => if r.ns == .rdfs then "is_a" else r.curie
  if r.inv then s!"inverse({l})" else l

instance : ToString Rel := ⟨label⟩

end Rel

/-- How many of a class a sentence is about. A bare claim is universal ("every neuron ...");
`some` and `most` are weaker. "Some neurons have no axons" does not contradict "most neurons have
axons"; it would contradict "every neuron has an axon". -/
inductive Quantifier
  | some
  | most
  deriving DecidableEq, Repr

/-- A formal claim. -/
inductive Claim
  /-- `agent` has a `sign`ed effect on `target`. -/
  | effect {k : Kind} (agent : Entity k) (sign : Sign) (target : Target)
  /-- The `sign`ed effect of `agent` on `target` runs via `mediator`. -/
  | mediatedBy {k : Kind} (agent : Entity k) (sign : Sign) (target : Target) (mediator : Target)
  /-- `a r b` for an RO relation `r`: part_of, occurs_in, has_output, is_a, ... The kinds must fit
  RO's declared domain and range (`Rel.accepts`), checked by `decide` at construction. -/
  | rel {k₁ k₂ : Kind} (r : Rel) (a : Entity k₁) (b : Entity k₂)
      (h : r.accepts k₁ k₂ = true := by decide)
  /-- `¬ (a r b)`: a genuine negation, e.g. "a prokaryotic cell has no nucleus as a part".
  OWL EL cannot say this; CL fakes it with a `lacks_part` property. -/
  | notRel {k₁ k₂ : Kind} (r : Rel) (a : Entity k₁) (b : Entity k₂)
      (h : r.accepts k₁ k₂ = true := by decide)
  -- Quantities (M3). Numbers are exact: `ℕ` for counts, `ℚ` for measurements.
  /-- Every `whole` has exactly `n` parts of kind `part`: a codon has 3 nucleotides. -/
  | count {k₁ k₂ : Kind} (whole : Entity k₁) (part : Entity k₂) (n : Nat)
  /-- Every `whole` has at least `n` parts of kind `part`. -/
  | atLeast {k₁ k₂ : Kind} (whole : Entity k₁) (part : Entity k₂) (n : Nat)
  /-- The class `c` has exactly `n` kinds of member: there are 64 codons, 20 amino acids. -/
  | cardinality {k : Kind} (c : Entity k) (n : Nat)
  /-- Quality `q` of every `x` lies in `[lo, hi]` in unit `u`: prokaryotic cell diameter 0.1 to 5 µm. -/
  | measure {k : Kind} (x : Entity k) (q : Entity .phenotype) (lo hi : Rat) (u : String)
  /-- Every `a` is below every `b` in quality `q`. -/
  | less {k₁ k₂ : Kind} (a : Entity k₁) (b : Entity k₂) (q : Entity .phenotype)
  /-- One run of process `p` makes `n` of `m`. -/
  | produces {k : Kind} (p : Entity .process) (m : Entity k) (n : Nat)
  /-- One run of process `p` uses `n` of `m`. -/
  | consumes {k : Kind} (p : Entity .process) (m : Entity k) (n : Nat)
  /-- Net change in `m` per run of `p`, made minus used. -/
  | yield {k : Kind} (p : Entity .process) (m : Entity k) (n : Int)
  /-- A weaker-than-universal claim. -/
  | quant (q : Quantifier) (c : Claim)

partial def Claim.toString : Claim → String
    | .effect a s t => s!"{a} {s.arrow} {t}"
    | .mediatedBy a s t m => s!"{a} {s.arrow} {t}  via  {m}"
    | .rel r a b _ => s!"{a} {r} {b}"
    | .notRel r a b _ => s!"¬({a} {r} {b})"
    | .count w p n => s!"{w} has {n} × {p}"
    | .atLeast w p n => s!"{w} has ≥ {n} × {p}"
    | .cardinality c n => s!"|{c}| = {n}"
    | .measure x q lo hi u => s!"{q} of {x} ∈ [{lo}, {hi}] {u}"
    | .less a b q => s!"{a} < {b} in {q}"
    | .produces p m n => s!"{p} makes {n} × {m}"
    | .consumes p m n => s!"{p} uses {n} × {m}"
    | .yield p m n => s!"{p} nets {n} × {m}"
    | .quant Quantifier.some c => s!"some: {c.toString}"
    | .quant Quantifier.most c => s!"most: {c.toString}"

instance : ToString Claim := ⟨Claim.toString⟩
instance : Repr Claim := ⟨fun c _ => c.toString⟩

end BioLean
