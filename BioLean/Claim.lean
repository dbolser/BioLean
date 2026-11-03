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

/-- Which aspect of a disease an effect acts on. They are different claims with different
evidence: a TOLLIP allele lowers the risk of IPF and raises its mortality. RO keeps them apart too:
RO:0019501 confers susceptibility (risk), RO:0003305 contributes to severity. -/
inductive DiseaseAspect
  /-- Getting the disease: susceptibility, incidence, onset. -/
  | risk
  /-- How bad it is when you have it. -/
  | severity
  /-- How fast it worsens: decline, exacerbation, mortality. -/
  | progression
  deriving DecidableEq, Repr

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
  /-- One aspect of a disease: "the MUC5B promoter variant raises the risk of IPF". -/
  | disease (d : Entity .disease) (aspect : DiseaseAspect := .risk)

instance : ToString Target where
  toString
    | .activity p _ => s!"activity of {p}"
    | .amount m => s!"amount of {m}"
    | .process p => s!"{p}"
    | .phenotype p => s!"{p}"
    | .site a => s!"site {a}"
    | .disease d .risk => s!"risk of {d}"
    | .disease d .severity => s!"severity of {d}"
    | .disease d .progression => s!"progression of {d}"

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

/-- Context as refinement (M2): `e.refine r f` is the class `e ⊓ ∃r.f`, description-logic style,
of the same kind as `e`. "Hepatocyte in mouse" has curie `CL:0000182&RO:0002162=(NCBITaxon:10090)`.
The filler is bracketed so that a refined filler (aged mouse) cannot collide with a second
refinement of the subject. The kinds must fit RO's domain and range, as for `Claim.rel`. Build
contexts with `Entity.inCtx` (`BioLean/Context.lean`), which fixes relation and order. -/
def Entity.refine {k k' : Kind} (e : Entity k) (r : Rel) (f : Entity k')
    (_h : r.accepts k k' = true := by decide) : Entity k where
  curie := s!"{e.curie}&{r.curie}=({f.curie})"
  label := s!"{e.label} ⊓ {r} ({f.label})"

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
  /-- `agent` has no effect on `target`: a measured null ("uncouplers leave H+/O unchanged"). This
  is a positive finding. Refuting evidence on `effect agent s target` is not the same thing: it
  says the effect is not `s`, which still allows the opposite sign, and a failure to see an effect
  is not a measurement that there is none. -/
  | noEffect {k : Kind} (agent : Entity k) (target : Target)
  /-- `x` goes with `t`: carrying `x`, or having more of it, goes with more (`some .pos`) or less
  (`some .neg`) of `t`, or with a difference of unstated direction (`none`). An association, not
  an effect: it may be confounded, tag a nearby cause (linkage), or run backwards (the disease
  changes `x`). RO:0003308 correlated with condition is `none`; RO:0019501 confers susceptibility
  is `some .pos` on risk. `Derivation.fromAssoc` reads a signed one as an effect, at a discount. -/
  | assoc {k : Kind} (x : Entity k) (dir : Option Sign) (t : Target)
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
  /-- Every `whole` has between `lo` and `hi` parts of kind `part`: an alveolar sac has 20 to 30
  alveoli. `count` is the point case; write `count`, not `countBetween n n`. -/
  | countBetween {k₁ k₂ : Kind} (whole : Entity k₁) (part : Entity k₂) (lo hi : Nat)
  /-- The class `c` has exactly `n` kinds of member: there are 64 codons, 20 amino acids. -/
  | cardinality {k : Kind} (c : Entity k) (n : Nat)
  /-- Quality `q` of every `x` lies in `[lo, hi]` in unit `u`: prokaryotic cell diameter 0.1 to 5 µm. -/
  | measure {k : Kind} (x : Entity k) (q : Entity .phenotype) (lo hi : Rat) (u : String)
  /-- Quality `q` of every `x` is at least `lo` in unit `u`, with no upper bound: the human small
  intestine is over 6 m long. A separate constructor, not an optional `hi`, so `compareIntervals`
  keeps its closed intervals. -/
  | atLeastMeasure {k : Kind} (x : Entity k) (q : Entity .phenotype) (lo : Rat) (u : String)
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
    | .noEffect a t => s!"{a} →0 {t}"
    | .assoc x (some .pos) t => s!"{x} ~+ {t}"
    | .assoc x (some .neg) t => s!"{x} ~− {t}"
    | .assoc x none t => s!"{x} ~ {t}"
    | .rel r a b _ => s!"{a} {r} {b}"
    | .notRel r a b _ => s!"¬({a} {r} {b})"
    | .count w p n => s!"{w} has {n} × {p}"
    | .atLeast w p n => s!"{w} has ≥ {n} × {p}"
    | .countBetween w p lo hi => s!"{w} has {lo} to {hi} × {p}"
    | .cardinality c n => s!"|{c}| = {n}"
    | .measure x q lo hi u => s!"{q} of {x} ∈ [{lo}, {hi}] {u}"
    | .atLeastMeasure x q lo u => s!"{q} of {x} ≥ {lo} {u}"
    | .less a b q => s!"{a} < {b} in {q}"
    | .produces p m n => s!"{p} makes {n} × {m}"
    | .consumes p m n => s!"{p} uses {n} × {m}"
    | .yield p m n => s!"{p} nets {n} × {m}"
    | .quant Quantifier.some c => s!"some: {c.toString}"
    | .quant Quantifier.most c => s!"most: {c.toString}"

instance : ToString Claim := ⟨Claim.toString⟩

/-- The curie of a claim's subject: the agent, the first relatum, the whole or the process. -/
def Claim.subjectCurie : Claim → String
  | .effect a .. | .mediatedBy a .. | .noEffect a _ | .assoc a .. | .rel _ a .. | .notRel _ a .. => a.curie
  | .count w .. | .atLeast w .. | .countBetween w .. => w.curie
  | .cardinality c _ | .measure c .. | .atLeastMeasure c .. | .less c .. => c.curie
  | .produces p .. | .consumes p .. | .yield p .. => p.curie
  | .quant _ c => c.subjectCurie
instance : Repr Claim := ⟨fun c _ => c.toString⟩

end BioLean
