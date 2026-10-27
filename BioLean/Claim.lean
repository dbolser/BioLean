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
  /-- The activity of a protein (a GO molecular function, implicitly). -/
  | activity (p : Entity .protein)
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
    | .activity p => s!"activity of {p}"
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

instance : ToString Claim where
  toString
    | .effect a s t => s!"{a} {s.arrow} {t}"
    | .mediatedBy a s t m => s!"{a} {s.arrow} {t}  via  {m}"
    | .rel r a b _ => s!"{a} {r} {b}"
    | .notRel r a b _ => s!"¬({a} {r} {b})"

instance : Repr Claim := ⟨fun c _ => toString c⟩

end BioLean
