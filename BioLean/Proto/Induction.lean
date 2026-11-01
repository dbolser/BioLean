import BioLean.Derivation
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR2.Photosynthesis
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsB

/-!
# Prototype 10c: a learned rule as a value, and a derivation that uses it

Program 10c (`docs/programs/10c-rule-induction.md`). Nothing here is in the core. If adopted, it would
change the core in these ways:

| part | what | would change |
|---|---|---|
| 1 `Term`, `Atom`, `Rule` | a Horn rule over relation atoms, with its support and its tests | a new type |
| 1 `Rule.opinion` | the rule's strength: the fused tests; no test, no belief | nothing new: `fuse` over `Evidence` |
| 2 `XClaim.invented` | a claim with a predicate that no ontology has (predicate invention) | a new `Claim` constructor |
| 2 `IDerivation.apply2`, `applyInv2` | fire a two-atom rule (RO head, or invented head); Lean checks the premises match its body | a new `Derivation` rule |
| 2 opinion of a use | premises by `weakest`, then `chain` with the rule's opinion | nothing new: existing operators, used as `transport` uses them |

`IDerivation.core` embeds today's derivations unchanged, so every core theorem still holds for them.
The four rules in part 3 are real outputs or real gaps of `scripts/stress/induction_mine.py` on the
textbook (program 10c, `data/stress/10c/`), applied to real textbook statements (R2). Each case prints
`PROTO <tab> case <tab> result`.
-/

namespace BioLean.Proto.Induction
open BioLean BioLean.Textbook

def proto (id msg : String) : IO Unit := IO.println s!"PROTO\t{id}\t{msg}"
def vstr : Derivation.Verdict → String
  | .established => "established" | .contested => "contested" | .refuted => "refuted"
  | .unsupported => "unsupported"
def ostr (o : Opinion) : String :=
  s!"b={o.belief.toDecimal 2} d={o.disbelief.toDecimal 2} u={o.uncertainty.toDecimal 2}"

/-! ## Part 1. A rule as a value -/

/-- A term of a rule atom: a variable, or a constant curie. -/
inductive Term
  | var (n : Nat)
  | const (curie : String)
  deriving DecidableEq, Repr

/-- A predicate: an RO relation, or one invented by the learner (or by hand) that no ontology has. -/
inductive Pred
  | ro (r : Rel)
  | invented (name : String)
  deriving DecidableEq, Repr

structure Atom where
  pred : Pred
  s : Term
  o : Term
  deriving DecidableEq, Repr

/-- A learned Horn rule `head ← body`. `support` names the statements it was learned from
(provenance only: they are not evidence for the rule, because a rule always fits the data it was
fitted to). `tests` are the evidence: one item per prediction checked against a statement the learner
did not see (support: confirmed; refutes: contradicted). No tests, no belief. -/
structure Rule where
  name : String
  body : List Atom
  head : Atom
  support : List String
  tests : List Evidence

def Rule.opinion [EvidenceModel] (ρ : Rule) : Opinion :=
  ρ.tests.foldl (fun acc e => acc.fuse e.opinion) Opinion.vacuous

/-- A substitution: variable number to curie. -/
abbrev Subst := List (Nat × String)

def Term.inst (σ : Subst) : Term → Option String
  | .var n => σ.lookup n
  | .const c => some c

/-! ## Part 2. Claims with invented predicates, and derivations that fire rules -/

/-- A claim of the core, or one stated with an invented predicate over two curies. -/
inductive XClaim
  | base (c : Claim)
  | invented (name : String) (a b : String)

/-- The (predicate, subject, object) a claim asserts, when it is a binary relation. -/
def XClaim.triple? : XClaim → Option (Pred × String × String)
  | .base (.rel r a b _) => some (.ro r, a.curie, b.curie)
  | .invented p a b => some (.invented p, a, b)
  | _ => none

/-- Does atom `α` under `σ` say what claim `c` says? -/
def Atom.matches (σ : Subst) (α : Atom) (c : XClaim) : Bool :=
  match c.triple?, α.s.inst σ, α.o.inst σ with
  | some (p, a, b), some x, some y => p == α.pred && a == x && b == y
  | _, _, _ => false

/-- The rule fires on these premise claims under `σ` and concludes `(x, y)`: Lean checks this by
`decide` at every use. -/
def Rule.fires (ρ : Rule) (σ : Subst) (cs : List XClaim) (x y : String) : Bool :=
  ρ.body.length == cs.length && (ρ.body.zip cs).all (fun (α, c) => α.matches σ c) &&
  ρ.head.s.inst σ == some x && ρ.head.o.inst σ == some y

/-- A statement stated with an invented predicate (here: synthetic, from a textbook sentence). -/
structure XStatement where
  id : String
  name : String
  a : String
  b : String
  evidence : List Evidence

/-- Derivations over `XClaim`. `core` is today's `Derivation`, untouched. -/
inductive IDerivation : XClaim → Type
  | core {c : Claim} (d : Derivation c) : IDerivation (.base c)
  | xlit (s : XStatement) : IDerivation (.invented s.name s.a s.b)
  /-- Fire a two-atom rule whose head is an RO relation. -/
  | apply2 {c₁ c₂ : XClaim} {k₁ k₂ : Kind} (ρ : Rule) (r : Rel) (σ : Subst)
      (d₁ : IDerivation c₁) (d₂ : IDerivation c₂) (a : Entity k₁) (b : Entity k₂)
      (hr : ρ.head.pred = .ro r := by decide) (h : r.accepts k₁ k₂ = true := by decide)
      (ok : ρ.fires σ [c₁, c₂] a.curie b.curie = true := by decide) :
      IDerivation (.base (.rel r a b h))
  /-- Fire a two-atom rule whose head is an invented predicate. -/
  | applyInv2 {c₁ c₂ : XClaim} (ρ : Rule) (p : String) (σ : Subst)
      (d₁ : IDerivation c₁) (d₂ : IDerivation c₂) (x y : String)
      (hp : ρ.head.pred = .invented p := by decide)
      (ok : ρ.fires σ [c₁, c₂] x y = true := by decide) :
      IDerivation (.invented p x y)

namespace IDerivation
variable [EvidenceModel]

/-- Strength of a use of a rule: the premises by `weakest` (a logical step), then `chain` with the
rule's own opinion (an empirical step, as `transport` chains with its evidence item). -/
def opinion : {c : XClaim} → IDerivation c → Opinion
  | _, .core d => d.opinion
  | _, .xlit s => s.evidence.foldl (fun acc e => acc.fuse e.opinion) Opinion.vacuous
  | _, .apply2 ρ _ _ d₁ d₂ .. => (d₁.opinion.weakest d₂.opinion).chain ρ.opinion
  | _, .applyInv2 ρ _ _ d₁ d₂ .. => (d₁.opinion.weakest d₂.opinion).chain ρ.opinion

/-- The rules a derivation uses: what `axioms` would list next to the statements. -/
def rules : {c : XClaim} → IDerivation c → List String
  | _, .core _ => []
  | _, .xlit _ => []
  | _, .apply2 ρ _ _ d₁ d₂ .. => ρ.name :: d₁.rules ++ d₂.rules
  | _, .applyInv2 ρ _ _ d₁ d₂ .. => ρ.name :: d₁.rules ++ d₂.rules

/-- A conclusion through a learned rule is never more believed than the rule. -/
theorem apply2_belief_le_rule {c₁ c₂ : XClaim} {k₁ k₂ : Kind} (ρ : Rule) (r : Rel) (σ : Subst)
    (d₁ : IDerivation c₁) (d₂ : IDerivation c₂) (a : Entity k₁) (b : Entity k₂)
    (hr : ρ.head.pred = .ro r) (h : r.accepts k₁ k₂ = true) (ok : ρ.fires σ [c₁, c₂] a.curie b.curie = true) :
    (apply2 ρ r σ d₁ d₂ a b hr h ok).opinion.belief ≤ ρ.opinion.belief :=
  Opinion.chain_belief_le_right _ _

/-- An untested rule gives no belief at all, however strong the premises. -/
theorem apply2_untested {c₁ c₂ : XClaim} {k₁ k₂ : Kind} (ρ : Rule) (r : Rel) (σ : Subst)
    (d₁ : IDerivation c₁) (d₂ : IDerivation c₂) (a : Entity k₁) (b : Entity k₂)
    (hr : ρ.head.pred = .ro r) (h : r.accepts k₁ k₂ = true) (ok : ρ.fires σ [c₁, c₂] a.curie b.curie = true)
    (ht : ρ.tests = []) :
    (apply2 ρ r σ d₁ d₂ a b hr h ok).opinion.belief = 0 := by
  simp [opinion, Rule.opinion, ht, Opinion.chain, Opinion.vacuous]

end IDerivation

/-! ## Part 3. Four rules, and two with their tests -/

def x : Term := .var 0
def y : Term := .var 1
def z : Term := .var 2
def derivesFrom : Rel := ⟨.ro, 1000, false⟩

/-- One test item: a held-out prediction the rule got right (`supports`) or wrong (`refutes`). Weight
`.observational` (1/2, pseudo-count 2) is a choice, recorded here, not a calibration. -/
def test (note : String) (p : Opinion.Polarity := .supports) : Evidence :=
  { pmid := 0, year := 2026, kind := .observational, polarity := p, note := note }

/-- R1, learned (I18) by `induction_mine.py`, AMIE 3.0 and Popper (P18, exact mode): `has_input(x,y) ← has_output(x,z), derives_from(z,y)`. "If a process makes z and z
is made from y, y is an input." Support 3, PCA 1.0 on the full textbook. True biology for a product's
carbon source. Tests: the leave-one-out runs of `induction_tasks.py` (I18 recovers the Calvin cycle's
CO2 from the other two). -/
def R1 : Rule where
  name := "has_input <= has_output, derives_from"
  body := [⟨.ro Rel.hasOutput, x, z⟩, ⟨.ro derivesFrom, z, y⟩]
  head := ⟨.ro Rel.hasInput, x, y⟩
  support := ["cell-structure-and-function-m45432-231", "how-cells-obtain-energy-m45437-13", "photosynthesis-m45453-20"]
  tests := [test "I18: Calvin cycle has input CO2 recovered with photosynthesis-m45453-20 held out"]

/-- The Calvin cycle has input CO2 (photosynthesis-m45453-20), from "the Calvin cycle makes sugars"
(m45453-51) and "the carbon in sugars comes from CO2" (m45453-4). -/
def calvinCO2 := IDerivation.apply2 R1 Rel.hasInput [(0, "GO:0019253"), (1, "CHEBI:16526"), (2, "CHEBI:16646")]
  (.core (.lit R2.Photosynthesis.photosynthesis_m45453_51)) (.core (.lit R2.Photosynthesis.photosynthesis_m45453_4))
  R2.e_GO_0019253 R2.e_CHEBI_16526

#guard (match (XClaim.base R2.Photosynthesis.photosynthesis_m45453_20.claim).triple? with
  | some (_, a, b) => a == "GO:0019253" && b == "CHEBI:16526" | none => false)
#guard calvinCO2.opinion.belief == 2 / 5        -- 4/5 premises × 1/2 rule
#guard calvinCO2.opinion.verdict == .unsupported
#guard calvinCO2.rules == ["has_input <= has_output, derives_from"]
-- With no test, the same use is worth nothing.
#guard (IDerivation.apply2 { R1 with tests := [] } Rel.hasInput [(0, "GO:0019253"), (1, "CHEBI:16526"), (2, "CHEBI:16646")]
  (.core (.lit R2.Photosynthesis.photosynthesis_m45453_51)) (.core (.lit R2.Photosynthesis.photosynthesis_m45453_4))
  R2.e_GO_0019253 R2.e_CHEBI_16526).opinion.belief == 0
/- Four confirmed tests and no failure give the rule belief 4/5. The use is not established: `chain`
multiplies, 4/5 × 4/5 = 16/25, so even a well-tested rule does not establish its conclusion from
textbook premises. That is the price of `chain` (the same as for `transport`). -/
#guard (IDerivation.apply2 { R1 with tests := List.replicate 4 (test "LOO") } Rel.hasInput
  [(0, "GO:0019253"), (1, "CHEBI:16526"), (2, "CHEBI:16646")]
  (.core (.lit R2.Photosynthesis.photosynthesis_m45453_51)) (.core (.lit R2.Photosynthesis.photosynthesis_m45453_4))
  R2.e_GO_0019253 R2.e_CHEBI_16526).opinion.belief == 16 / 25

/-- R2, learned (I19): `capable_of(x,y) ← derives_from(x,z), capable_of(z,y)`, "a thing can do what
its ancestor can". Support 3, PCA 0.75, but all three supports run through one reflexive fact ("cells
derive from cells", m45428-74), so each support is predicted from itself: an artefact. Its one
prediction about organelles is false. Test: the I19 negative. -/
def R2r : Rule where
  name := "capable_of <= derives_from, capable_of"
  body := [⟨.ro derivesFrom, x, z⟩, ⟨.ro Rel.capableOf, z, y⟩]
  head := ⟨.ro Rel.capableOf, x, y⟩
  support := ["molbio-m45480-10", "cell-structure-and-function-m45435-5", "cell-structure-and-function-m45433-3"]
  tests := [test "I19: mitochondria photosynthesise (false)" .refutes]

/-- The rule's shape is fine, so Lean accepts the false conclusion "mitochondria photosynthesise" from
"aerobic bacteria became mitochondria" (m45432-261) and "bacteria photosynthesise" (m45432-242): Lean
checks shape, not truth. The refuting test leaves the use with no belief. -/
def mitoPhoto := IDerivation.apply2 R2r Rel.capableOf [(0, "GO:0005739"), (1, "GO:0015979"), (2, "NCBITaxon:2")]
  (.core (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45432_261))
  (.core (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45432_242))
  R2.e_GO_0005739 R2.e_GO_0015979
#guard mitoPhoto.opinion.belief == 0
#guard R2r.opinion.disbelief == 1 / 2
#guard mitoPhoto.opinion.verdict == .unsupported   -- not refuted: `chain` drops the rule's disbelief

/-- R3, the G1 hole of `docs/holes.md` (I31): `has_abundant(x,o) ← high_demand(x,f), capable_of(o,f)`. Neither
predicate is in any ontology: both are written by hand from the three sentences (synthetic). Given them, Popper
learns exactly this rule from any two of the three (P31); without `high_demand` it finds no rule at all, even with
predicate invention on (P32). -/
def R3 : Rule where
  name := "has_abundant <= high_demand, capable_of"
  body := [⟨.invented "high_demand", x, z⟩, ⟨.ro Rel.capableOf, y, z⟩]
  head := ⟨.invented "has_abundant", x, y⟩
  support := ["cell-structure-and-function-m45432-189", "cell-structure-and-function-m45432-155"]
  tests := []

def muscleDemand : XStatement :=
  { id := "synthetic:m45432-203-because", name := "high_demand", a := "CL:0000187", b := "GO:0006754",
    evidence := [{ pmid := 0, year := 2013, kind := .textbook, note := "muscle cells need a lot of energy to contract (m45432-203)" }] }
def muscleMito := IDerivation.applyInv2 R3 "has_abundant" [(0, "CL:0000187"), (1, "GO:0005739"), (2, "GO:0006754")]
  (.xlit muscleDemand) (.core (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45432_192))
  "CL:0000187" "GO:0005739"
#guard muscleMito.opinion.belief == 0           -- untested: hypothesis weight
#guard muscleMito.rules == ["has_abundant <= high_demand, capable_of"]
/- The check is real: the same rule refuses ribosomes for muscle (ribosomes are not capable of ATP
synthesis in the record), because the second premise does not match the body under σ. -/
#guard !R3.fires [(0, "CL:0000187"), (1, "GO:0005840"), (2, "GO:0006754")]
  [.invented "high_demand" "CL:0000187" "GO:0006754", .base R2.CellStructureAndFunction.cell_structure_and_function_m45429_12.claim]
  "CL:0000187" "GO:0005840"

/-- R4, the brief's example (I23), stated by hand: `involved_in(x,p) ← part_of(x,s), capable_of(s,p)`.
Support 1 in the textbook (amygdala, limbic system, memory), below any learner's threshold. RO already
has the sound, weaker chain `part_of ∘ capable_of ⊑ part of structure that is capable of`
(RO:0002329), which the core applies today; this rule claims more. -/
def R4 : Rule where
  name := "involved_in <= part_of, capable_of"
  body := [⟨.ro Rel.partOf, x, z⟩, ⟨.ro Rel.capableOf, z, y⟩]
  head := ⟨.ro Rel.involvedIn, x, y⟩
  support := ["the-body-s-systems-m45539-244", "the-body-s-systems-m45539-242"]
  tests := []
def amygdalaMemory := IDerivation.apply2 R4 Rel.involvedIn [(0, "UBERON:0001876"), (1, "GO:0007613"), (2, "UBERON:0000349")]
  (.core (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_244)) (.core (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_242))
  R2.e_UBERON_0001876 R2.e_GO_0007613
#guard amygdalaMemory.opinion.belief == 0
/-- R4, as Popper learned it (P23, fold 1: the amygdala sentence as the only example of the pattern; Popper 5.0,
exact mode). Its tests are the 21 new predictions it adds over the textbook, judged by the program author (not
source-checked, `data/stress/10c/popper/predictions_judged.tsv`): 14 true (stroma and thylakoids in photosynthesis,
glomerulus in filtration, ion channels in transport), 7 false (desmosomes in ATP synthesis, amygdala in hearing).
The false ones come from a whole's generic capability passing to every part. -/
def R4j : Rule := { R4 with
  tests := List.replicate 14 (test "P23 prediction judged true") ++ List.replicate 7 (test "P23 prediction judged false" .refutes) }
def amygdalaMemoryJ := IDerivation.apply2 R4j Rel.involvedIn [(0, "UBERON:0001876"), (1, "GO:0007613"), (2, "UBERON:0000349")]
  (.core (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_244)) (.core (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_242))
  R2.e_UBERON_0001876 R2.e_GO_0007613
#guard R4j.opinion.belief == 7 / 11 && R4j.opinion.disbelief == 7 / 22
#guard R4j.opinion.verdict == .contested               -- a third of its new predictions are false
#guard amygdalaMemoryJ.opinion.belief == 28 / 55        -- 4/5 premises × 7/11 rule
#guard amygdalaMemoryJ.opinion.verdict == .unsupported  -- true conclusion, but the rule is not good enough

/-- R3 with the three leave-one-out tests of P31 (Popper learned this rule in every fold, and each fold predicted
its held-out sentence). The tests reuse the support sentences, one at a time: honest cross-validation, but
three sentences are all the evidence there is. -/
def R3t : Rule := { R3 with tests := List.replicate 3 (test "P31 leave-one-out: held-out sentence predicted") }
def muscleMitoT := IDerivation.applyInv2 R3t "has_abundant" [(0, "CL:0000187"), (1, "GO:0005739"), (2, "GO:0006754")]
  (.xlit muscleDemand) (.core (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45432_192))
  "CL:0000187" "GO:0005739"
#guard R3t.opinion.belief == 3 / 4
#guard muscleMitoT.opinion.belief == 3 / 5             -- 4/5 premises × 3/4 rule: not established

/-- RO's sound version, in today's core. -/
def amygdalaRO := Derivation.relChain (r₃ := ⟨.ro, 2329, false⟩)
  (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_244) (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_242)
theorem amygdala_part_of_structure_capable_of_memory : Established (Derivation.claim amygdalaRO) (4/5) :=
  ⟨amygdalaRO, by decide +kernel⟩

#eval do
  proto "I18" s!"R1 fires: Calvin cycle has input CO2, {ostr calvinCO2.opinion} {vstr calvinCO2.opinion.verdict}; rules {calvinCO2.rules}"
  proto "I19" s!"R2 fires: mitochondria capable of photosynthesis (false), {ostr mitoPhoto.opinion} {vstr mitoPhoto.opinion.verdict}; the rule {ostr R2r.opinion}"
  proto "I31" s!"R3 fires with invented predicates: muscle cell has_abundant mitochondrion, {ostr muscleMito.opinion} {vstr muscleMito.opinion.verdict}"
  proto "I23" s!"R4 fires: amygdala involved in memory, {ostr amygdalaMemory.opinion}; RO:0002329 in the core: {ostr amygdalaRO.opinion} {vstr amygdalaRO.verdict}"
  proto "I23" s!"R4 with 21 judged tests: rule {ostr R4j.opinion} {vstr R4j.opinion.verdict}; use {ostr amygdalaMemoryJ.opinion} {vstr amygdalaMemoryJ.opinion.verdict}"
  proto "I31" s!"R3 with 3 LOO tests (Popper P31): rule {ostr R3t.opinion}; use {ostr muscleMitoT.opinion} {vstr muscleMitoT.opinion.verdict}"

end BioLean.Proto.Induction
