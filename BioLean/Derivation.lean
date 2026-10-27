import BioLean.Evidence

/-!
# Derivations

A `Derivation c` is a proof-like object for the claim `c`. Lean's type checker
guarantees the *shape* of the argument: the subject of each step is the object of the
previous one, and signs compose correctly. The *strength* of the argument is a
separate computation, `Derivation.opinion`, over the belief algebra.

This is the split that makes a mathlib-style library possible. A lemma in `BioLean.Lib`
is a named derivation. A new proof reuses it like any other term, and inherits its
evidence. `Derivation.axioms` lists the literature statements a derivation rests on,
the biological analogue of `#print axioms`.
-/

namespace BioLean

inductive Derivation : Claim → Type
  /-- A literature statement, taken as an axiom. -/
  | lit (s : Statement) : Derivation s.claim
  /-- Chain through a protein's activity: `a →s₁ activity(b)` and `b →s₂ t` give
  `a →(s₁·s₂) t`. -/
  | viaActivity {k : Kind} {a : Entity k} {b : Entity .protein} {s₁ s₂ : Sign} {t : Target}
      (ab : Derivation (.effect a s₁ (.activity b)))
      (bt : Derivation (.effect b s₂ t)) :
      Derivation (.effect a (s₁ * s₂) t)
  /-- Chain through a molecule's abundance: `a →s₁ amount(m)` and `m →s₂ t` give
  `a →(s₁·s₂) t`. -/
  | viaAmount {k k' : Kind} {a : Entity k} {m : Entity k'} {s₁ s₂ : Sign} {t : Target}
      (am : Derivation (.effect a s₁ (.amount m)))
      (mt : Derivation (.effect m s₂ t)) :
      Derivation (.effect a (s₁ * s₂) t)
  /-- Two independent derivations of the same claim. -/
  | both {c : Claim} (d₁ d₂ : Derivation c) : Derivation c
  /-- Compose two relations along an RO axiom: a property chain `r₁ ∘ r₂ ⊑ r₃`, transitivity
  (`r ∘ r ⊑ r`), or the `is_a` laws (a subclass inherits its superclass's relations; a relation
  to a subclass is a relation to the superclass). `RO.chainOK` decides which. This is a logical
  step, so its opinion is `Opinion.weakest`, not `chain`: the conclusion is as believed as the
  weaker premise (decision recorded in CHANGELOG 2026-10-27, after the chain-length experiment). -/
  | relChain {k₁ k₂ k₃ : Kind} {a : Entity k₁} {b : Entity k₂} {c : Entity k₃} {r₁ r₂ r₃ : Rel}
      {h₁ : r₁.accepts k₁ k₂ = true} {h₂ : r₂.accepts k₂ k₃ = true}
      (ab : Derivation (.rel r₁ a b h₁)) (bc : Derivation (.rel r₂ b c h₂))
      (ok : RO.chainOK r₁ r₂ r₃ = true := by decide) (h₃ : r₃.accepts k₁ k₃ = true := by decide) :
      Derivation (.rel r₃ a c h₃)
  /-- Read a relation backwards: `a r b` gives `b r⁻¹ a`, or `b r' a` for RO's declared inverse. -/
  | relInv {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {r : Rel} {h : r.accepts k₁ k₂ = true}
      (ab : Derivation (.rel r a b h)) (r' : Rel)
      (ok : RO.inverseOK r r' = true := by decide) (h' : r'.accepts k₂ k₁ = true := by decide) :
      Derivation (.rel r' b a h')
  /-- A subclass inherits a negation: `a is_a b` and `¬(b r c)` give `¬(a r c)`. -/
  | notRelSub {k₁ k₂ k₃ : Kind} {a : Entity k₁} {b : Entity k₂} {c : Entity k₃} {r : Rel}
      {h₁ : Rel.isA.accepts k₁ k₂ = true} {h₂ : r.accepts k₂ k₃ = true}
      (ab : Derivation (.rel Rel.isA a b h₁)) (bc : Derivation (.notRel r b c h₂))
      (h₃ : r.accepts k₁ k₃ = true := by decide) :
      Derivation (.notRel r a c h₃)
  /-- A negation covers subclasses of the object: `¬(a r c)` and `b is_a c` give `¬(a r b)`. -/
  | notRelObj {k₁ k₂ k₃ : Kind} {a : Entity k₁} {b : Entity k₂} {c : Entity k₃} {r : Rel}
      {h₁ : r.accepts k₁ k₃ = true} {h₂ : Rel.isA.accepts k₂ k₃ = true}
      (ac : Derivation (.notRel r a c h₁)) (bc : Derivation (.rel Rel.isA b c h₂))
      (h₃ : r.accepts k₁ k₂ = true := by decide) :
      Derivation (.notRel r a b h₃)

namespace Derivation

variable [EvidenceModel]

/-- The strength of a derivation. -/
def opinion : {c : Claim} → Derivation c → Opinion
  | _, .lit s => s.opinion
  | _, .viaActivity ab bt => ab.opinion.chain bt.opinion
  | _, .viaAmount am mt => am.opinion.chain mt.opinion
  | _, .both d₁ d₂ => d₁.opinion.fuse d₂.opinion
  | _, .relChain ab bc .. => ab.opinion.weakest bc.opinion
  | _, .relInv ab .. => ab.opinion
  | _, .notRelSub ab bc .. => ab.opinion.weakest bc.opinion
  | _, .notRelObj ac bc .. => ac.opinion.weakest bc.opinion

/-- The literature statements a derivation rests on, in order of first use. -/
def axioms : {c : Claim} → Derivation c → List Statement
  | _, .lit s => [s]
  | _, .viaActivity ab bt => ab.axioms ++ bt.axioms
  | _, .viaAmount am mt => am.axioms ++ mt.axioms
  | _, .both d₁ d₂ => d₁.axioms ++ d₂.axioms
  | _, .relChain ab bc .. => ab.axioms ++ bc.axioms
  | _, .relInv ab .. => ab.axioms
  | _, .notRelSub ab bc .. => ab.axioms ++ bc.axioms
  | _, .notRelObj ac bc .. => ac.axioms ++ bc.axioms

/-- Every PMID cited anywhere in the derivation, without repeats. -/
def pmids {c : Claim} (d : Derivation c) : List Nat :=
  (d.axioms.flatMap Statement.pmids).eraseDups

/-- A one-word reading of an opinion, with thresholds `θ` (established / refuted) and
`τ` (the floor at which a competing mass counts as a real dispute). -/
inductive Verdict
  | established
  | contested
  | refuted
  | unsupported
  deriving DecidableEq, Repr

def _root_.BioLean.Opinion.verdict (o : Opinion) (θ : ℚ := 4 / 5) (τ : ℚ := 1 / 4) : Verdict :=
  if τ ≤ o.belief ∧ τ ≤ o.disbelief then .contested
  else if θ ≤ o.belief then .established
  else if θ ≤ o.disbelief then .refuted
  else .unsupported

def verdict {c : Claim} (d : Derivation c) (θ : ℚ := 4 / 5) (τ : ℚ := 1 / 4) : Verdict :=
  d.opinion.verdict θ τ

/-- The proposition "claim `c` is established at level `θ`": some derivation reaches
belief `θ`. -/
def _root_.BioLean.Established (c : Claim) (θ : ℚ) : Prop :=
  ∃ d : Derivation c, θ ≤ d.opinion.belief

/-- The claim a derivation proves. -/
def claim {c : Claim} (_ : Derivation c) : Claim := c

/-- Pretty-print a derivation as an indented tree with the opinion at each node. -/
partial def render {c : Claim} (d : Derivation c) (indent : String := "") : String :=
  match d with
  | .lit s =>
      s!"{indent}{s.opinion} {s.id}: {s.claim}  [{s.distinctEvidence.length} refs]"
  | .viaActivity ab bt =>
      s!"{indent}{d.opinion} chain ⊢ {d.claim}\n" ++
        render ab (indent ++ "  ") ++ "\n" ++ render bt (indent ++ "  ")
  | .viaAmount am mt =>
      s!"{indent}{d.opinion} chain ⊢ {d.claim}\n" ++
        render am (indent ++ "  ") ++ "\n" ++ render mt (indent ++ "  ")
  | .both d₁ d₂ =>
      s!"{indent}{d.opinion} fuse ⊢ {d.claim}\n" ++
        render d₁ (indent ++ "  ") ++ "\n" ++ render d₂ (indent ++ "  ")
  | .relChain ab bc .. =>
      s!"{indent}{d.opinion} RO chain ⊢ {d.claim}\n" ++
        render ab (indent ++ "  ") ++ "\n" ++ render bc (indent ++ "  ")
  | .relInv ab .. =>
      s!"{indent}{d.opinion} inverse ⊢ {d.claim}\n" ++ render ab (indent ++ "  ")
  | .notRelSub ab bc .. =>
      s!"{indent}{d.opinion} is_a inherits ¬ ⊢ {d.claim}\n" ++
        render ab (indent ++ "  ") ++ "\n" ++ render bc (indent ++ "  ")
  | .notRelObj ac bc .. =>
      s!"{indent}{d.opinion} ¬ covers subclass ⊢ {d.claim}\n" ++
        render ac (indent ++ "  ") ++ "\n" ++ render bc (indent ++ "  ")

/-- Statements used more than once in a derivation. `fuse` assumes independence, so a
shared axiom means the strength is over-stated. -/
def sharedAxioms {c : Claim} (d : Derivation c) : List String :=
  let ids := d.axioms.map (·.id)
  (ids.filter (fun i => (ids.count i) > 1)).eraseDups

/-- A full report: verdict, tree, and the literature it rests on. -/
def report {c : Claim} (d : Derivation c) : String :=
  let warn := if d.sharedAxioms.isEmpty then ""
    else s!"\nWARNING shared axioms (not independent): {d.sharedAxioms}"
  s!"Claim: {c}\nVerdict: {repr d.verdict}  {d.opinion}{warn}\n\n{d.render}\n\n" ++
    s!"Rests on {d.axioms.length} statements, {d.pmids.length} PMIDs: " ++
    s!"{d.pmids.map toString |> String.intercalate ", "}"

/-- Two derivations that contradict each other, `a r b` and `¬(a r b)`, read as one opinion
about `a r b`: the negation's belief becomes disbelief, then the two fuse. The verdict is
*contested* when both sides are strong, which is where an ontology inconsistency shows up. -/
def clash {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {r : Rel} {h : r.accepts k₁ k₂ = true}
    (yes : Derivation (.rel r a b h)) (no : Derivation (.notRel r a b h)) : Opinion :=
  yes.opinion.fuse no.opinion.negate

/-! ### Theorems about derivations -/

/-- A chained argument is never stronger than either of its steps. -/
theorem opinion_viaActivity_le_left {k : Kind} {a : Entity k} {b : Entity .protein}
    {s₁ s₂ : Sign} {t : Target}
    (ab : Derivation (.effect a s₁ (.activity b))) (bt : Derivation (.effect b s₂ t)) :
    (viaActivity ab bt).opinion.belief ≤ ab.opinion.belief :=
  Opinion.chain_belief_le_left _ _

theorem opinion_viaActivity_le_right {k : Kind} {a : Entity k} {b : Entity .protein}
    {s₁ s₂ : Sign} {t : Target}
    (ab : Derivation (.effect a s₁ (.activity b))) (bt : Derivation (.effect b s₂ t)) :
    (viaActivity ab bt).opinion.belief ≤ bt.opinion.belief :=
  Opinion.chain_belief_le_right _ _

/-- A second, independent derivation never weakens a chain-only derivation. -/
theorem opinion_both_ge_of_chain {c : Claim} (d₁ d₂ : Derivation c)
    (h : d₂.opinion.disbelief = 0) :
    d₁.opinion.belief ≤ (both d₁ d₂).opinion.belief :=
  Opinion.belief_le_fuse_of_supports _ _ h

/-- Chains carry no disbelief. -/
theorem opinion_viaActivity_disbelief {k : Kind} {a : Entity k} {b : Entity .protein}
    {s₁ s₂ : Sign} {t : Target}
    (ab : Derivation (.effect a s₁ (.activity b))) (bt : Derivation (.effect b s₂ t)) :
    (viaActivity ab bt).opinion.disbelief = 0 := rfl

theorem opinion_viaAmount_disbelief {k k' : Kind} {a : Entity k} {m : Entity k'}
    {s₁ s₂ : Sign} {t : Target}
    (am : Derivation (.effect a s₁ (.amount m))) (mt : Derivation (.effect m s₂ t)) :
    (viaAmount am mt).opinion.disbelief = 0 := rfl

end Derivation
end BioLean
