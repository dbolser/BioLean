import BioLean.Ontology

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

/-- A formal claim. -/
inductive Claim
  /-- `agent` has a `sign`ed effect on `target`. -/
  | effect {k : Kind} (agent : Entity k) (sign : Sign) (target : Target)
  /-- The `sign`ed effect of `agent` on `target` runs via `mediator`. -/
  | mediatedBy {k : Kind} (agent : Entity k) (sign : Sign) (target : Target) (mediator : Target)

instance : ToString Claim where
  toString
    | .effect a s t => s!"{a} {s.arrow} {t}"
    | .mediatedBy a s t m => s!"{a} {s.arrow} {t}  via  {m}"

instance : Repr Claim := ⟨fun c _ => toString c⟩

end BioLean
