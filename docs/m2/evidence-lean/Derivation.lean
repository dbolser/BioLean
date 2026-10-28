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
  | viaActivity {k k' : Kind} {a : Entity k} {b : Entity k'} {s₁ s₂ : Sign} {t : Target}
      {h : k' = .protein ∨ k' = .function}
      (ab : Derivation (.effect a s₁ (.activity b h)))
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
  -- There is deliberately no `relInv` rule. Claims are class-level existentials ("every a has some
  -- b"), and the inverse of an existential does not follow: every nuclear membrane has some
  -- phospholipid, but not every phospholipid is part of a nuclear membrane. State the inverse
  -- direction as its own claim when the source asserts it (`Rel.flip`). Found by the closure search.
  -- Quantity rules (M3). Each is a logical step with an arithmetic side goal.
  /-- Sequences of length `n` over an alphabet of `k` symbols number `k ^ n`: four bases, three
  per codon, 64 codons. Models `seq` as a sequence over `sym`. -/
  | sequencesOver {k₁ k₂ : Kind} {sym : Entity k₁} {seq : Entity k₂} {k n m : ℕ}
      (alphabet : Derivation (.cardinality sym k)) (length : Derivation (.count seq sym n))
      (h : k ^ n = m := by decide) : Derivation (.cardinality seq m)
  /-- Pigeonhole: `a` items each assigned one `b`, more items than holes, so some hole has two.
  61 sense codons, 20 amino acids: some amino acid has at least two codons. -/
  | pigeonhole {k₁ k₂ : Kind} {item : Entity k₁} {hole : Entity k₂} {a b : ℕ}
      (items : Derivation (.cardinality item a)) (holes : Derivation (.cardinality hole b))
      (each : Derivation (.count item hole 1))
      (h : b < a := by decide) : Derivation (.quant Quantifier.some (.atLeast hole item 2))
  /-- Equal division: a whole with `n` parts arranged in `s` equal sets has `n / s` per set.
  46 chromosomes in 2 sets, 23 per set. Assumes the sets are equal, which is what "set" means here. -/
  | perSet {k₁ k₂ k₃ : Kind} {whole : Entity k₁} {part : Entity k₂} {set : Entity k₃} {n s m : ℕ}
      (parts : Derivation (.count whole part n)) (sets : Derivation (.count whole set s))
      (h : s * m = n := by decide) : Derivation (.count set part m)
  /-- Fusion adds: a process with two inputs and one output conserves the counted parts.
  Haploid egg (1 set) + haploid sperm (1 set) → diploid zygote (2 sets). -/
  | fusionAdds {k₁ k₂ k₃ k₄ : Kind} {p : Entity .process} {x : Entity k₁} {y : Entity k₂}
      {z : Entity k₃} {part : Entity k₄} {a b c : ℕ}
      {hx : Rel.hasInput.accepts .process k₁ = true} {hy : Rel.hasInput.accepts .process k₂ = true}
      {hz : Rel.hasOutput.accepts .process k₃ = true}
      (inx : Derivation (.rel Rel.hasInput p x hx)) (iny : Derivation (.rel Rel.hasInput p y hy))
      (out : Derivation (.rel Rel.hasOutput p z hz))
      (cx : Derivation (.count x part a)) (cy : Derivation (.count y part b))
      (h : a + b = c := by decide) : Derivation (.count z part c)
  /-- Net yield is made minus used: glycolysis makes 4 ATP and uses 2, net 2. -/
  | netYield {k : Kind} {p : Entity .process} {m : Entity k} {a b : ℕ} {n : ℤ}
      (made : Derivation (.produces p m a)) (used : Derivation (.consumes p m b))
      (h : (a : ℤ) - b = n := by decide) : Derivation (.yield p m n)
  /-- Disjoint intervals order the classes: prokaryotes 0.1 to 5 µm, eukaryotes 10 to 100 µm,
  so every prokaryote is smaller than every eukaryote. -/
  | compareIntervals {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {q : Entity .phenotype}
      {lo₁ hi₁ lo₂ hi₂ : ℚ} {u : String}
      (ma : Derivation (.measure a q lo₁ hi₁ u)) (mb : Derivation (.measure b q lo₂ hi₂ u))
      (h : hi₁ < lo₂ := by norm_num) : Derivation (.less a b q)
  /-- A universal claim implies the `some` and `most` forms (for a non-empty class). -/
  | weaken {c : Claim} (q : Quantifier) (d : Derivation c) : Derivation (.quant q c)
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
  /-- Cross-taxon transport (M2): read `d`, evaluated in taxon `src`, as evidence about the same
  bare claim in a sibling taxon `dst`, discounted by `ContextModel.transport` (3/10 by default).
  The only way evidence from one taxon reaches a query about another. The claim does not change,
  because in this design context lives on evidence, not on claims. -/
  | transport {c : Claim} (src dst : Entity .taxon) (d : Derivation c) : Derivation c

namespace Derivation

variable [EvidenceModel] [ContextModel]

/-- The strength of a derivation, evaluated in context `q` (default: no context). Every leaf
filters its evidence by `q`; `transport` is the one rule that changes `q`. -/
def opinion {c : Claim} (d : Derivation c) (q : Ctx := {}) : Opinion :=
  go q d
where
  go (q : Ctx) : {c : Claim} → Derivation c → Opinion
  | _, .lit s => s.opinion q
  | _, .transport src dst d =>
      match q.taxon with
      | some t =>
          if ContextModel.isA t.curie dst.curie && Ctx.siblings src dst then
            (go { q with taxon := some src } d).discount ContextModel.transport
              ContextModel.transport_nonneg ContextModel.transport_le_one
          else Opinion.vacuous
      | none => Opinion.vacuous
  | _, .viaActivity ab bt => (go q ab).chain (go q bt)
  | _, .viaAmount am mt => (go q am).chain (go q mt)
  | _, .both d₁ d₂ => (go q d₁).fuse (go q d₂)
  | _, .relChain ab bc .. => (go q ab).weakest (go q bc)
  | _, .notRelSub ab bc .. => (go q ab).weakest (go q bc)
  | _, .notRelObj ac bc .. => (go q ac).weakest (go q bc)
  | _, .sequencesOver a l .. => (go q a).weakest (go q l)
  | _, .pigeonhole i hs e .. => ((go q i).weakest (go q hs)).weakest (go q e)
  | _, .perSet p s .. => (go q p).weakest (go q s)
  | _, .fusionAdds ix iy o cx cy .. => ((((go q ix).weakest (go q iy)).weakest (go q o)).weakest (go q cx)).weakest (go q cy)
  | _, .netYield m u .. => (go q m).weakest (go q u)
  | _, .compareIntervals a b .. => (go q a).weakest (go q b)
  | _, .weaken _ d => (go q d)

/-- The literature statements a derivation rests on, in order of first use. -/
def axioms : {c : Claim} → Derivation c → List Statement
  | _, .lit s => [s]
  | _, .viaActivity ab bt => ab.axioms ++ bt.axioms
  | _, .viaAmount am mt => am.axioms ++ mt.axioms
  | _, .both d₁ d₂ => d₁.axioms ++ d₂.axioms
  | _, .relChain ab bc .. => ab.axioms ++ bc.axioms
  | _, .notRelSub ab bc .. => ab.axioms ++ bc.axioms
  | _, .notRelObj ac bc .. => ac.axioms ++ bc.axioms
  | _, .sequencesOver a l .. => a.axioms ++ l.axioms
  | _, .pigeonhole i hs e .. => i.axioms ++ hs.axioms ++ e.axioms
  | _, .perSet p s .. => p.axioms ++ s.axioms
  | _, .fusionAdds ix iy o cx cy .. => ix.axioms ++ iy.axioms ++ o.axioms ++ cx.axioms ++ cy.axioms
  | _, .netYield m u .. => m.axioms ++ u.axioms
  | _, .compareIntervals a b .. => a.axioms ++ b.axioms
  | _, .weaken _ d => d.axioms
  | _, .transport _ _ d => d.axioms

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

def verdict {c : Claim} (d : Derivation c) (θ : ℚ := 4 / 5) (τ : ℚ := 1 / 4) (q : Ctx := {}) :
    Verdict :=
  (d.opinion q).verdict θ τ

/-- The proposition "claim `c` is established at level `θ`": some derivation reaches
belief `θ`. -/
def _root_.BioLean.Established (c : Claim) (θ : ℚ) : Prop :=
  ∃ d : Derivation c, θ ≤ d.opinion.belief

/-- "Claim `c` is established at level `θ` in context `q`". -/
def _root_.BioLean.EstablishedIn (q : Ctx) (c : Claim) (θ : ℚ) : Prop :=
  ∃ d : Derivation c, θ ≤ (d.opinion q).belief

/-- The claim a derivation proves. -/
def claim {c : Claim} (_ : Derivation c) : Claim := c

/-- Pretty-print a derivation as an indented tree with the opinion at each node. -/
partial def render {c : Claim} (d : Derivation c) (indent : String := "") (q : Ctx := {}) :
    String :=
  let node (rule : String) (kids : List String) : String :=
    s!"{indent}{d.opinion q} {rule} ⊢ {d.claim}\n" ++ String.intercalate "\n" kids
  match d with
  | .lit s =>
      s!"{indent}{s.opinion q} {s.id}: {s.claim}  [{s.distinctEvidence.length} refs]"
  | .viaActivity ab bt =>
      s!"{indent}{d.opinion q} chain ⊢ {d.claim}\n" ++
        render ab (indent ++ "  ") q ++ "\n" ++ render bt (indent ++ "  ") q
  | .viaAmount am mt =>
      s!"{indent}{d.opinion q} chain ⊢ {d.claim}\n" ++
        render am (indent ++ "  ") q ++ "\n" ++ render mt (indent ++ "  ") q
  | .both d₁ d₂ =>
      s!"{indent}{d.opinion q} fuse ⊢ {d.claim}\n" ++
        render d₁ (indent ++ "  ") q ++ "\n" ++ render d₂ (indent ++ "  ") q
  | .relChain ab bc .. =>
      s!"{indent}{d.opinion q} RO chain ⊢ {d.claim}\n" ++
        render ab (indent ++ "  ") q ++ "\n" ++ render bc (indent ++ "  ") q
  | .notRelSub ab bc .. =>
      s!"{indent}{d.opinion q} is_a inherits ¬ ⊢ {d.claim}\n" ++
        render ab (indent ++ "  ") q ++ "\n" ++ render bc (indent ++ "  ") q
  | .notRelObj ac bc .. =>
      s!"{indent}{d.opinion q} ¬ covers subclass ⊢ {d.claim}\n" ++
        render ac (indent ++ "  ") q ++ "\n" ++ render bc (indent ++ "  ") q
  | .sequencesOver a l .. => node "k^n sequences" [render a (indent ++ "  ") q, render l (indent ++ "  ") q]
  | .pigeonhole i hs e .. => node "pigeonhole" [render i (indent ++ "  ") q, render hs (indent ++ "  ") q, render e (indent ++ "  ") q]
  | .perSet p s .. => node "equal division" [render p (indent ++ "  ") q, render s (indent ++ "  ") q]
  | .fusionAdds ix iy o cx cy .. => node "fusion adds" [render ix (indent ++ "  ") q, render iy (indent ++ "  ") q, render o (indent ++ "  ") q, render cx (indent ++ "  ") q, render cy (indent ++ "  ") q]
  | .netYield m u .. => node "made − used" [render m (indent ++ "  ") q, render u (indent ++ "  ") q]
  | .compareIntervals a b .. => node "disjoint intervals" [render a (indent ++ "  ") q, render b (indent ++ "  ") q]
  | .weaken qt d' => node s!"weaken to {repr qt}" [render d' (indent ++ "  ") q]
  | .transport src dst d' => node s!"transport {src} ⇒ {dst}"
      [render d' (indent ++ "  ") { q with taxon := some src }]

/-- Statements used more than once in a derivation. `fuse` assumes independence, so a
shared axiom means the strength is over-stated. -/
def sharedAxioms {c : Claim} (d : Derivation c) : List String :=
  let ids := d.axioms.map (·.id)
  (ids.filter (fun i => (ids.count i) > 1)).eraseDups

/-- A full report: verdict, tree, and the literature it rests on. -/
def report {c : Claim} (d : Derivation c) (q : Ctx := {}) : String :=
  let warn := if d.sharedAxioms.isEmpty then ""
    else s!"\nWARNING shared axioms (not independent): {d.sharedAxioms}"
  let ctx := if toString q == "any context" then "" else s!"  [in {q}]"
  s!"Claim: {c}{ctx}\nVerdict: {repr (d.verdict (q := q))}  {d.opinion q}{warn}\n\n{d.render (q := q)}\n\n" ++
    s!"Rests on {d.axioms.length} statements, {d.pmids.length} PMIDs: " ++
    s!"{d.pmids.map toString |> String.intercalate ", "}"

/-- Two derivations that contradict each other, `a r b` and `¬(a r b)`, read as one opinion
about `a r b`: the negation's belief becomes disbelief, then the two fuse. The verdict is
*contested* when both sides are strong, which is where an ontology inconsistency shows up. -/
def clash {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {r : Rel} {h : r.accepts k₁ k₂ = true}
    (yes : Derivation (.rel r a b h)) (no : Derivation (.notRel r a b h)) (q : Ctx := {}) :
    Opinion :=
  (yes.opinion q).fuse (no.opinion q).negate

/-! ### Theorems about derivations -/

/-- A chained argument is never stronger than either of its steps. -/
theorem opinion_viaActivity_le_left {k k' : Kind} {a : Entity k} {b : Entity k'}
    {s₁ s₂ : Sign} {t : Target} {h : k' = .protein ∨ k' = .function}
    (ab : Derivation (.effect a s₁ (.activity b h))) (bt : Derivation (.effect b s₂ t)) :
    (viaActivity ab bt).opinion.belief ≤ ab.opinion.belief :=
  Opinion.chain_belief_le_left _ _

theorem opinion_viaActivity_le_right {k k' : Kind} {a : Entity k} {b : Entity k'}
    {s₁ s₂ : Sign} {t : Target} {h : k' = .protein ∨ k' = .function}
    (ab : Derivation (.effect a s₁ (.activity b h))) (bt : Derivation (.effect b s₂ t)) :
    (viaActivity ab bt).opinion.belief ≤ bt.opinion.belief :=
  Opinion.chain_belief_le_right _ _

/-- A second, independent derivation never weakens a chain-only derivation. -/
theorem opinion_both_ge_of_chain {c : Claim} (d₁ d₂ : Derivation c)
    (h : d₂.opinion.disbelief = 0) :
    d₁.opinion.belief ≤ (both d₁ d₂).opinion.belief :=
  Opinion.belief_le_fuse_of_supports _ _ h

/-- Chains carry no disbelief. -/
theorem opinion_viaActivity_disbelief {k k' : Kind} {a : Entity k} {b : Entity k'}
    {s₁ s₂ : Sign} {t : Target} {h : k' = .protein ∨ k' = .function}
    (ab : Derivation (.effect a s₁ (.activity b h))) (bt : Derivation (.effect b s₂ t)) :
    (viaActivity ab bt).opinion.disbelief = 0 := rfl

theorem opinion_viaAmount_disbelief {k k' : Kind} {a : Entity k} {m : Entity k'}
    {s₁ s₂ : Sign} {t : Target}
    (am : Derivation (.effect a s₁ (.amount m))) (mt : Derivation (.effect m s₂ t)) :
    (viaAmount am mt).opinion.disbelief = 0 := rfl

/-- Transport is never free and never strong: whatever `d` is, and in whatever context it is
asked, a transported derivation believes at most `ContextModel.transport` (3/10 by default). -/
theorem opinion_transport_belief_le {c : Claim} (src dst : Entity .taxon) (d : Derivation c)
    (q : Ctx) : ((transport src dst d).opinion q).belief ≤ ContextModel.transport := by
  have h0 := ContextModel.transport_nonneg
  simp only [opinion, opinion.go]
  split
  · split
    · exact Opinion.discount_belief_le _ _ _ _
    · exact h0
  · exact h0

end Derivation
end BioLean
