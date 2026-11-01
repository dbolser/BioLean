import BioLean.Derivation
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR3.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsB

/-!
# Program 02b: prototypes for loops

`docs/programs/02b-feedback-loops.md`. Nothing here changes the core. A new file cannot import
another new file, so the cases that exercise each prototype are restated here (the same statements
as `BioLean/Stress/Feedback.lean`, same ids).

| option | what is prototyped here | core change if adopted |
|---|---|---|
| (B) loop sign | `Loop.sign` (TEDDY_0000034 negative, TEDDY_0000035 positive feedback loop) | changes `Claim.homeostasis` (new field) or a new `Claim.loop` |
| (C) several regulators | `Loop.regulators`, each with the sign of its arm on the held target | same constructor change as (B) |
| (D) set point | `Loop.setPoint` is a core `Claim.measure`; `LClaim.shiftsSetPoint` for fever | (D1) a link in data: none; (D2) a new constructor |
| (E) loop-aware reading | `classify`: a derivation that goes round an asserted loop is reported as that loop | none (library function, mirrored in `scripts/stress/closure_loops.py`) |
| (E') strict reading | `classifyStrict`: every node on the cycle must be a node of the loop (fixes the P03 mislabel) | none (closure flag `--strict`) |
| (F) close a loop from its arms | `LDeriv.close` (arms linked by base curie, a compiled check) and `LDeriv.closeT` (linked by the kernel: Lean unification plus an is_a premise): two arms give a loop whose sign is the product of theirs | a new `Derivation` rule (and the claim of (B)) |
| (E5) arm check, a lint | `armsFor`: the textbook arm pairs behind an asserted `homeostasis` claim, with their signs | none (data lint) |
| (G) block round trips | `blockedByG`: refuse any chain whose path revisits a node | a side condition on `viaAmount`/`viaActivity`; rejected below |

Pins are `#guard`, `example` and `theorem ... := by decide +kernel`. Each case prints a `PROTO`
line, read by `data/stress/02b/scripts/cases.py`.
-/

namespace BioLean.Proto.Feedback
open BioLean Derivation BioLean.Textbook BioLean.Textbook.R2 BioLean.Textbook.R3

def proto (id msg : String) : IO Unit := IO.println s!"PROTO\t{id}\t{msg}"
def tb (note : String) : Evidence := { pmid := 0, year := 2013, kind := .textbook, note := note }
def paper (pmid year : Nat) (k : EvidenceKind) (note : String) : Evidence :=
  { pmid := pmid, year := year, kind := k, note := note }

/-- The unrefined head of a curie: `CHEBI:17234` from `CHEBI:17234&RO:0001025=(UBERON:0000178)`.
Loop nodes are compared on this, as `closure.py` does, so "glucose in blood" is glucose. -/
def base (c : String) : String := (c.splitOn "&").headD c

def targetCurie : Target → String
  | .activity p _ => p.curie | .amount m => m.curie | .process p => p.curie
  | .phenotype p => p.curie | .site a => a.curie

/-! ## (B, C, D) The loop as data -/

/-- A regulator and the sign of its arm on the held target: insulin lowers glucose (`neg`),
glucagon raises it (`pos`). -/
structure Regulator where
  {k : Kind}
  agent : Entity k
  dir : Sign

/-- A set point as a core measure claim: quality `q` of `holder` lies in `[lo, hi]` `unit`. -/
structure SetPoint where
  {k : Kind}
  holder : Entity k
  q : Entity .phenotype
  lo : ℚ
  hi : ℚ
  unit : String

def SetPoint.claim (s : SetPoint) : Claim := .measure s.holder s.q s.lo s.hi s.unit

/-- A feedback loop. `homeostatic` says the loop holds `held` near a set point (what
`Claim.homeostasis` means); a negative loop that clears something to zero (antibodies and a
virus) is a loop but not homeostatic. -/
structure Loop where
  id : String
  sign : Sign
  held : Target
  regulators : List Regulator
  homeostatic : Bool := false
  setPoint : Option SetPoint := none

/-- The loop's nodes, as base curies: the held target, then each regulator. -/
def Loop.nodes (l : Loop) : List String := base (targetCurie l.held) :: l.regulators.map (base ·.agent.curie)

/-- What the core can hold of a loop: one `Claim.homeostasis` per regulator, and only for a
negative homeostatic loop. The sign, the pairing and each regulator's direction are lost. -/
def Loop.toCore (l : Loop) : List Claim :=
  if l.sign == .neg && l.homeostatic then l.regulators.map fun r => .homeostasis r.agent l.held else []

/-- Claims with loops: the core claims, a loop, and a shift of a loop's set point. -/
inductive LClaim
  | core (c : Claim)
  | loop (l : Loop)
  /-- `agent` moves the set point of loop `l` up (`pos`) or down (`neg`): pyrogens and fever. -/
  | shiftsSetPoint {k : Kind} (agent : Entity k) (s : Sign) (l : Loop)

def LClaim.describe : LClaim → String
  | .core c => toString c
  | .loop l => s!"loop {l.id}: {if l.sign == .neg then "negative" else "positive"}, held {l.held}, regulators {l.regulators.map (·.agent.label)}{if l.homeostatic then ", homeostatic" else ""}{match l.setPoint with | some s => s!", set point {s.claim}" | none => ""}"
  | .shiftsSetPoint a s l => s!"{a} {s.arrow} set point of loop {l.id}"

/-! ## (F) Closing a loop from its arms -/

/-- Derivations over `LClaim`. `close` is the new rule: an arm `x →s₁ t₁` whose target is `y`'s
entity and an arm `y →s₂ t₂` whose target is `x`'s entity make a loop of sign `s₁ * s₂` with
regulator `y` (direction `s₂`) holding `t₂`. Thomas (1998): a negative circuit is needed for
homeostasis, not enough for it, so `close` concludes a loop, never `homeostatic := true`. Entity
identity in `close` is by base curie, checked by `LDeriv.linked` in compiled code (`#guard`), not
by the kernel: the type of `close` itself puts no condition on the arms, so unrelated arms build a
"loop" (pinned below). `closeT` puts the condition in the type instead, with the core's own
identity (unification, plus an is_a premise for a refined end), so the kernel checks it.
Opinions are `weakest`, as for the logical rules. -/
inductive LDeriv : LClaim → Type
  | core {c : Claim} (d : Derivation c) : LDeriv (.core c)
  | assert (l : Loop) (o : Opinion) : LDeriv (.loop l)
  | close {k₁ k₂ : Kind} {x : Entity k₁} {y : Entity k₂} {s₁ s₂ : Sign} {t₁ t₂ : Target}
      (up : Derivation (.effect x s₁ t₁)) (down : Derivation (.effect y s₂ t₂)) (id : String) :
      LDeriv (.loop { id := id, sign := s₁ * s₂, held := t₂, regulators := [⟨y, s₂⟩] })
  /-- `close` with the core's own identity, checked by the kernel: the up arm ends on the amount of
  the regulator `y` itself, the down arm starts from `y` and ends on `x'`, and `x'` is_a `x` (a
  refinement edge, as `isaInheritEffect` uses). No curie is parsed; Lean unification does the
  linking, so unrelated arms do not typecheck (pinned with `#check_failure`). -/
  | closeT {k₁ k₂ : Kind} {x x' : Entity k₁} {y : Entity k₂} {s₁ s₂ : Sign}
      {h : Rel.isA.accepts k₁ k₁ = true}
      (up : Derivation (.effect x s₁ (.amount y))) (down : Derivation (.effect y s₂ (.amount x')))
      (isa : Derivation (.rel Rel.isA x' x h)) (id : String) :
      LDeriv (.loop { id := id, sign := s₁ * s₂, held := .amount x', regulators := [⟨y, s₂⟩] })

/-- The claim an `LDeriv` proves. -/
def LDeriv.result {c : LClaim} (_ : LDeriv c) : LClaim := c
def LClaim.loop? : LClaim → Option Loop | .loop l => some l | _ => none

/-- The side condition of `close`: each arm ends on the other's agent (by base curie). -/
def LDeriv.linked : {c : LClaim} → LDeriv c → Bool
  | _, .close (x := x) (y := y) (t₁ := t₁) (t₂ := t₂) .. => base (targetCurie t₁) == base y.curie && base (targetCurie t₂) == base x.curie
  | _, _ => true

def LDeriv.opinion [EvidenceModel] : {c : LClaim} → LDeriv c → Opinion
  | _, .core d => d.opinion
  | _, .assert _ o => o
  | _, .close up down .. => up.opinion.weakest down.opinion
  | _, .closeT up down isa .. => (up.opinion.weakest down.opinion).weakest isa.opinion

/-! ## (E) Reading a core derivation against asserted loops -/

/-- The effect premises of a derivation, as (base agent, sign, base target), with the node path. -/
def premises : {c : Claim} → Derivation c → List (String × Sign × String)
  | _, .lit s => match s.claim with
      | .effect a sg t => [(base a.curie, sg, base (targetCurie t))]
      | _ => []
  | _, .viaAmount d₁ d₂ => premises d₁ ++ premises d₂
  | _, .viaActivity d₁ d₂ => premises d₁ ++ premises d₂
  | _, .isaInheritEffect _ d => premises d
  | _, .both d₁ d₂ => premises d₁ ++ premises d₂
  | _, _ => []

/-- The base-curie path of an effect chain: agent, each intermediate, target. -/
def path {c : Claim} (d : Derivation c) : List String :=
  match premises d with
  | [] => []
  | p :: ps => p.1 :: (p :: ps).map (·.2.2)

def revisits {c : Claim} (d : Derivation c) : Bool := (path d).eraseDups.length < (path d).length

def Loop.isArm (l : Loop) (p : String × Sign × String) : Bool :=
  p.1 != p.2.2 && l.nodes.contains p.1 && l.nodes.contains p.2.2

def Loop.crosses {c : Claim} (l : Loop) (d : Derivation c) : Bool := (premises d).any l.isArm

/-- How the loop-aware closure reports a derived effect. -/
inductive Reading
  | plain
  | crosses (ids : List String)     -- kept as an effect, labelled with the loops it crosses
  | roundTrip (id : String)         -- reported as the loop, not as an effect
  | cycle                           -- revisits a node, but no asserted loop covers it: flagged effect
  deriving DecidableEq, Repr

def Reading.str : Reading → String
  | .plain => "plain" | .crosses ids => s!"crosses {ids}" | .roundTrip id => s!"round trip of loop {id}" | .cycle => "cycle (no asserted loop)"

/-- A derivation whose path revisits a node, every revisited node in an asserted loop it
crosses, is that loop going round. Otherwise it is labelled with each loop it crosses. -/
def classify {c : Claim} (ls : List Loop) (d : Derivation c) : Reading :=
  let p := path d
  let dup := p.filter fun n => p.count n > 1
  if revisits d then
    match ls.find? (fun l => l.crosses d && dup.all l.nodes.contains) with
    | some l => .roundTrip l.id
    | none => .cycle
  else
    match ls.filter (·.crosses d) with
    | [] => .plain
    | cs => .crosses (cs.map (·.id))

/-- (G) Blocking every chain that revisits a node. -/
def blockedByG {c : Claim} (d : Derivation c) : Bool := revisits d

/-! ## The loops (asserted, as the proposal in `data/stress/02b/homeostasis_m3.json` would) -/

abbrev glucose := e_CHEBI_17234
abbrev blood := e_UBERON_0000178
abbrev insulin := e_PR_000009054
abbrev glucagon := e_PR_P01275
abbrev bloodGlucose := glucose.inCtx { anatomy := blood }
abbrev calcium := e_CHEBI_29108
abbrev pth := e_PR_000013429
abbrev calcitonin := e_PR_P01258
abbrev bloodCalcium := calcium.inCtx { anatomy := blood }
abbrev tsh := e_PR_P01222
abbrev t3 := e_CHEBI_18258
abbrev thyroid := e_UBERON_0002046
def bodyTemp : Entity .phenotype := ⟨"OBA:VT0005535", "body temperature trait"⟩
def thrombin : Entity .protein := ⟨"PR:000007299", "prothrombin"⟩
def factorV : Entity .protein := ⟨"PR:000007300", "coagulation factor V"⟩
def crh : Entity .protein := ⟨"PR:000005867", "corticoliberin"⟩
def acth : Entity .chemical := ⟨"CHEBI:3892", "corticotropin"⟩
def cortisol : Entity .chemical := ⟨"CHEBI:17650", "cortisol"⟩
def pyrogen : Entity .chemical := ⟨"NCIT:C71583", "Pyrogen"⟩
def hotEnvironment : Entity .phenotype := ⟨"BLN:hot_environment", "hot environment"⟩
def hypovolemia : Entity .phenotype := ⟨"BLN:hypovolemia", "reduced plasma volume"⟩
def plasmaOsmolality : Entity .phenotype := ⟨"OBA:2045426", "blood plasma osmolality"⟩
def oxytocin := e_CHEBI_7872
def uterineContraction : Entity .process := ⟨"GO:0070471", "uterine smooth muscle contraction"⟩
def estradiol : Entity .chemical := ⟨"CHEBI:16469", "17beta-estradiol"⟩
def sustainedHighE2 : Entity .phenotype := ⟨"BLN:sustained_high_estradiol", "sustained high estradiol"⟩

def glucoseLoop : Loop :=
  { id := "glucose", sign := .neg, held := .amount bloodGlucose,
    regulators := [⟨insulin, .neg⟩, ⟨glucagon, .pos⟩], homeostatic := true }
def calciumLoop : Loop :=
  { id := "calcium", sign := .neg, held := .amount bloodCalcium,
    regulators := [⟨pth, .pos⟩, ⟨calcitonin, .neg⟩], homeostatic := true }
def thyroidLoop : Loop :=
  { id := "thyroid", sign := .neg, held := .amount (t3.inCtx { anatomy := thyroid }),
    regulators := [⟨tsh, .pos⟩], homeostatic := true }
def hpaLoop : Loop :=
  { id := "HPA", sign := .neg, held := .amount cortisol,
    regulators := [⟨acth, .pos⟩, ⟨crh, .pos⟩], homeostatic := true }
def thermoLoop : Loop :=
  { id := "temperature", sign := .neg, held := .phenotype bodyTemp,
    regulators := [⟨e_UBERON_0001898.inCtx { taxon := Taxa.mammalia }, .neg⟩], homeostatic := true,
    setPoint := some ⟨Taxa.human, bodyTemp, 37, 37, "°C"⟩ }
def anpLoop : Loop :=
  { id := "ANP", sign := .neg, held := .phenotype e_OBA_0003648,
    regulators := [⟨e_PR_P01160, .neg⟩], homeostatic := true }
def leptinLoop : Loop :=
  { id := "leptin", sign := .neg, held := .process e_GO_0042755,
    regulators := [⟨e_PR_000009758, .neg⟩], homeostatic := true }
def thrombinLoop : Loop := { id := "thrombin+", sign := .pos, held := .amount thrombin, regulators := [⟨factorV, .pos⟩] }
def apLoop : Loop :=
  { id := "depolarisation+", sign := .pos, held := .process e_GO_0051899,
    regulators := [⟨e_GO_0005248, .pos⟩, ⟨e_CHEBI_29101, .pos⟩] }
def osmoLoop : Loop :=
  { id := "osmolality", sign := .neg, held := .phenotype plasmaOsmolality,
    regulators := [⟨e_CHEBI_34543, .neg⟩], homeostatic := true }
def oxytocinLoop : Loop := { id := "oxytocin+", sign := .pos, held := .process uterineContraction, regulators := [⟨oxytocin, .pos⟩] }

def asserted : List Loop :=
  [glucoseLoop, calciumLoop, thyroidLoop, hpaLoop, thermoLoop, anpLoop, leptinLoop, thrombinLoop, apLoop, osmoLoop]

/-! ## The textbook and literature statements (as in `Stress/Feedback.lean`) -/

def bgIsaGlucose : Derivation (.rel Rel.isA bloodGlucose glucose) := .lit (Entity.refineAxiom glucose Rel.locatedIn blood)
def L01 : Derivation (.effect glucose .neg (.amount bloodGlucose)) :=
  .viaAmount (.lit R2.TheBodySSystemsB.the_body_s_systems_m45537_52) (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_53)
def L02 : Derivation (.effect glucose .neg (.amount bloodGlucose)) :=
  .viaAmount (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_199)
    (.isaInheritEffect (.relChain (.lit (Entity.refineAxiom (glucagon.refine Rel.locatedIn blood) Rel.partOf e_CL_0000171))
      (.lit (Entity.refineAxiom glucagon Rel.locatedIn blood))) (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_201))
def L03 : Derivation (.effect calcium .neg (.amount bloodCalcium)) :=
  .viaAmount (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_141)
    (.isaInheritEffect (.lit (Entity.refineAxiom pth Rel.locatedIn blood)) (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_140))
def S258 : Statement := ⟨"the-body-s-systems-m45537-258", "T3 lowers TSH", .effect t3 .neg (.amount tsh), [tb "-258 (proposed)"]⟩
def L08 : Derivation (.effect tsh .neg (.amount tsh)) :=
  .viaAmount (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_129)
    (.isaInheritEffect (.lit (Entity.refineAxiom t3 Rel.locatedIn thyroid)) (.lit S258))
def herman : Evidence := paper 27065163 2016 .review "Herman 2016"
def S_crh : Statement := ⟨"syn:L10-crh", "CRH raises ACTH", .effect crh .pos (.amount acth), [herman]⟩
def S_acth : Statement := ⟨"syn:L10-acth", "ACTH raises cortisol", .effect acth .pos (.amount cortisol), [herman]⟩
def S_cortBack : Statement := ⟨"syn:L10-back", "cortisol lowers CRH", .effect cortisol .neg (.amount crh), [herman]⟩
def L10 : Derivation (.effect cortisol .neg (.amount cortisol)) := .viaAmount (.viaAmount (.lit S_cortBack) (.lit S_crh)) (.lit S_acth)
def dexamethasone : Entity .chemical := ⟨"CHEBI:41879", "dexamethasone"⟩
def S_dex : Statement := ⟨"syn:L11-dex", "dexamethasone lowers ACTH", .effect dexamethasone .neg (.amount acth), [paper 16759341 2006 .observational "Aouizerate 2006"]⟩
def L11 : Derivation (.effect dexamethasone .neg (.amount cortisol)) := .viaAmount (.lit S_dex) (.lit S_acth)
def S226 : Statement := ⟨"the-body-s-systems-m45537-226", "blood volume raises ANP", .effect e_OBA_0003648 .pos (.amount e_PR_P01160), [tb "-226 (proposed)"]⟩
def L15 : Derivation (.effect e_OBA_0003648 .neg (.phenotype e_OBA_0003648)) := .viaAmount (.lit S226) (.lit R2.TheBodySSystemsB.the_body_s_systems_m45537_227)
def S254 : Statement := ⟨"the-body-s-systems-m45537-254", "leptin lowers food intake", .effect e_PR_000009758 .neg (.process e_GO_0042755), [tb "-254 (proposed)"]⟩
def L17 : Derivation (.effect e_GO_0042755 .neg (.process e_GO_0042755)) := .viaAmount (.lit R2.TheBodySSystemsB.the_body_s_systems_m45537_251) (.lit S254)
def pant : Evidence := paper 20441738 2010 .mechanistic "Panteleev 2010"
def S_fv : Statement := ⟨"syn:P02-act", "thrombin activates factor V", .effect thrombin .pos (.activity factorV), [pant]⟩
def S_fvBack : Statement := ⟨"syn:P02-back", "factor V raises thrombin", .effect factorV .pos (.amount thrombin), [paper 11434702 2001 .review "Hoffman 2001"]⟩
def P02 : Derivation (.effect thrombin .pos (.amount thrombin)) := .viaActivity (.lit S_fv) (.lit S_fvBack)
def P04 : Derivation (.effect e_GO_0051899 .pos (.process e_GO_0051899)) :=
  .viaAmount (.viaActivity (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_89) (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_90))
    (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_83)
def N02 := Derivation.viaAmount (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45433_65) (.lit R3.CellStructureAndFunction.cell_structure_and_function_m45433_63)
def bgRaisesInsulin := Derivation.isaInheritEffect bgIsaGlucose (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_200)
def N04 := Derivation.viaAmount (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_181) bgRaisesInsulin
def N05 := Derivation.viaAmount (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_201) bgRaisesInsulin
def S_meal : Statement := ⟨"syn:X03-1", "SYNTHETIC: a meal raises blood glucose", .effect e_GO_0042755 .pos (.amount bloodGlucose), [tb "synthetic"]⟩
def S_store : Statement := ⟨"syn:X03-2", "SYNTHETIC: blood glucose raises glycogen synthesis", .effect bloodGlucose .pos (.process ⟨"GO:0005978", "glycogen biosynthetic process"⟩), [tb "synthetic"]⟩
def X03 := Derivation.viaAmount (.lit S_meal) (.lit S_store)
/-- "glucose lowers insulin": round the glucose loop one and a half times (a closure sign clash). -/
def windTwice := Derivation.viaAmount L01 bgRaisesInsulin

/-! ## (E) The readings, pinned -/

#guard path L01 == ["CHEBI:17234", "PR:000009054", "CHEBI:17234"]
#guard classify asserted L01 == .roundTrip "glucose"
#guard classify asserted L02 == .roundTrip "glucose"
#guard classify asserted L03 == .roundTrip "calcium"
#guard classify asserted L08 == .roundTrip "thyroid"
#guard classify asserted L10 == .roundTrip "HPA"
#guard classify asserted L15 == .roundTrip "ANP"
#guard classify asserted L17 == .roundTrip "leptin"
#guard classify asserted P02 == .roundTrip "thrombin+"
#guard classify asserted P04 == .roundTrip "depolarisation+"
#guard classify asserted windTwice == .roundTrip "glucose"
#guard classify asserted L11 == .crosses ["HPA"]
#guard classify asserted N04 == .crosses ["glucose"]
#guard classify asserted N05 == .crosses ["glucose"]
#guard classify asserted N02 == .cycle
#guard classify asserted X03 == .plain
#eval proto "L01" s!"{Reading.str (classify asserted L01)}: '{L01.claim}' is reported as loop glucose, not as an effect"
#eval proto "L02" s!"{Reading.str (classify asserted L02)}"
#eval proto "L03" s!"{Reading.str (classify asserted L03)}"
#eval proto "L08" s!"{Reading.str (classify asserted L08)} (with the proposed arm -258)"
#eval proto "L10" s!"{Reading.str (classify asserted L10)}: a three-node round trip is found"
#eval proto "L11" s!"{Reading.str (classify asserted L11)}: '{L11.claim}' kept as an effect, labelled"
#eval proto "L15" s!"{Reading.str (classify asserted L15)}"
#eval proto "L17" s!"{Reading.str (classify asserted L17)} (the asymmetry is still not stated)"
#eval proto "P02" s!"{Reading.str (classify asserted P02)}: a positive round trip, true either way; now named"
#eval proto "P04" s!"{Reading.str (classify asserted P04)}"
#eval proto "N02" s!"{Reading.str (classify asserted N02)}: no asserted loop, so it stays a flagged effect and is not called homeostasis"
#eval proto "N04" s!"{Reading.str (classify asserted N04)}: still derives '{N04.claim}' (wrong), now labelled as crossing the glucose loop"
#eval proto "N05" s!"{Reading.str (classify asserted N05)}: '{N05.claim}' kept (right)"
#eval proto "X03" s!"{Reading.str (classify asserted X03)}: a chain through blood glucose with no arm of the loop is not labelled"
#eval proto "C02" s!"(Lean mirror of closure case C02) {Reading.str (classify asserted windTwice)}: '{windTwice.claim}' (a sign clash with -200) is the glucose loop wound one and a half times"

/-! ## (E') A stricter reading: every node on the cycle must be a node of the loop

`classify` only asks that the revisited nodes lie in a loop the chain crosses. P03 shows why that
is too weak: thrombin activates protein C, protein C inactivates factor V, factor V makes thrombin.
That is a negative loop (Esmon 2003), but its only revisited node, thrombin, is in the asserted
positive loop `thrombin+`, and its last arm is an arm of that loop, so `classify` reports a
negative round trip as the positive loop. `classifyStrict` asks that every node between the first
and last revisit be a node of the loop. -/

def proteinC : Entity .protein := ⟨"PR:000013261", "vitamin K-dependent protein C"⟩
def esmon : Evidence := paper 12970121 2003 .review "Esmon 2003"
def S_pc : Statement := ⟨"syn:P03-pc", "thrombin activates protein C", .effect thrombin .pos (.activity proteinC), [esmon]⟩
def S_off : Statement := ⟨"syn:P03-off", "protein C inactivates factor V", .effect proteinC .neg (.activity factorV), [esmon]⟩
def P03 : Derivation (.effect thrombin .neg (.amount thrombin)) := .viaActivity (.viaActivity (.lit S_pc) (.lit S_off)) (.lit S_fvBack)
def proteinCLoop : Loop :=
  { id := "proteinC-", sign := .neg, held := .amount thrombin, regulators := [⟨proteinC, .neg⟩, ⟨factorV, .pos⟩] }

/-- The nodes from the first revisited node to the last: the part of the path that goes round. -/
def cycleSeg (p : List String) : List String :=
  let idx := (List.range p.length).filter fun i => p.count (p.getD i "") > 1
  match idx.head?, idx.getLast? with
  | some i, some j => (p.drop i).take (j - i + 1)
  | _, _ => []

def classifyStrict {c : Claim} (ls : List Loop) (d : Derivation c) : Reading :=
  if revisits d then
    match ls.find? (fun l => l.crosses d && (cycleSeg (path d)).all l.nodes.contains) with
    | some l => .roundTrip l.id
    | none => .cycle
  else classify ls d

#guard path P03 == ["PR:000007299", "PR:000013261", "PR:000007300", "PR:000007299"]
#guard classify asserted P03 == .roundTrip "thrombin+"          -- the mislabel
#guard classifyStrict asserted P03 == .cycle                     -- strict: not the positive loop
#guard classifyStrict (asserted ++ [proteinCLoop]) P03 == .roundTrip "proteinC-"
-- the strict rule keeps every round trip the loose rule found in this file
#guard [L01, L02].all (classifyStrict asserted · == .roundTrip "glucose")
#guard classifyStrict asserted L03 == .roundTrip "calcium" && classifyStrict asserted L08 == .roundTrip "thyroid"
#guard classifyStrict asserted L10 == .roundTrip "HPA" && classifyStrict asserted L15 == .roundTrip "ANP"
#guard classifyStrict asserted L17 == .roundTrip "leptin" && classifyStrict asserted P02 == .roundTrip "thrombin+"
#guard classifyStrict asserted P04 == .roundTrip "depolarisation+" && classifyStrict asserted windTwice == .roundTrip "glucose"
#eval proto "P03" s!"loose reading: {Reading.str (classify asserted P03)} (wrong: '{P03.claim}' is the protein C brake, a negative loop); strict: {Reading.str (classifyStrict asserted P03)}; with the protein C loop asserted: {Reading.str (classifyStrict (asserted ++ [proteinCLoop]) P03)}"

/-! ## L18 feedback inhibition: isoleucine and threonine deaminase -/

def ecoli : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩
def ile : Entity .chemical := (⟨"CHEBI:17191", "L-isoleucine"⟩ : Entity .chemical).inCtx { taxon := ecoli }
def thrDeaminase : Entity .function := ⟨"GO:0004794", "threonine deaminase activity"⟩
def eis : Evidence := paper 2005118 1991 .inVitro "Eisenstein 1991"
def L18 : Derivation (.effect ile .neg (.amount ile)) :=
  .viaActivity (.lit ⟨"syn:L18-inhib", "isoleucine inhibits threonine deaminase", .effect ile .neg (.activity thrDeaminase), [eis]⟩)
    (.lit ⟨"syn:L18-make", "threonine deaminase raises isoleucine", .effect thrDeaminase .pos (.amount ile), [eis]⟩)
def ileLoop : Loop := { id := "isoleucine", sign := .neg, held := .amount ile, regulators := [⟨thrDeaminase, .pos⟩], homeostatic := true }
#guard classifyStrict [ileLoop] L18 == .roundTrip "isoleucine"
#guard classifyStrict [] L18 == .cycle
#eval proto "L18" s!"{Reading.str (classifyStrict [ileLoop] L18)} once the end-product loop is asserted; without it, {Reading.str (classifyStrict [] L18)}"

/-! ## (G) Blocking round trips in the core would throw away true results -/

#guard [blockedByG L01, blockedByG L10, blockedByG P02, blockedByG P04] == [true, true, true, true]
#guard !blockedByG N04 && !blockedByG N05
#eval proto "G" "a revisit guard blocks L01 and L10 (false) and P02 and P04 (true positive loops) alike, and leaves N04 (false) alone"

/-! ## (F) Closing loops from arms -/

def closeGlucose : LDeriv (.loop { id := "glucose/insulin", sign := .pos * .neg, held := .amount bloodGlucose, regulators := [⟨insulin, .neg⟩] }) :=
  .close (x := glucose) (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_200) (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_53) "glucose/insulin"
example : Sign.pos * Sign.neg = .neg := rfl
theorem closeGlucose_belief : closeGlucose.opinion.belief = 4 / 5 := by decide +kernel
def closeThrombin : LDeriv (.loop { id := "thrombin+", sign := .pos * .pos, held := .amount thrombin, regulators := [⟨factorV, .pos⟩] }) :=
  .close (.lit S_fv) (.lit S_fvBack) "thrombin+"
#guard closeGlucose.linked && closeThrombin.linked
#guard !(LDeriv.close (.lit S_fv) (.lit S_dex) "bad").linked
/-- The kernel-checked `closeT`: R2 -52 (glucose raises insulin), R3 -53 (insulin lowers blood glucose), and the
refinement edge blood glucose is_a glucose. -/
def closeGlucoseT := LDeriv.closeT (.lit R2.TheBodySSystemsB.the_body_s_systems_m45537_52)
  (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_53) bgIsaGlucose "glucose/insulin"
theorem closeGlucoseT_belief : closeGlucoseT.opinion.belief = 4 / 5 := by decide +kernel
example : closeGlucoseT.result.loop?.map (·.sign) = some .neg := rfl
-- unrelated arms do not typecheck as closeT: -52 ends on insulin, but the down arm starts from dexamethasone
-- (the failure message is dropped; an unexpected success would be an error, and `#guard_msgs` would then fail)
#guard_msgs (drop info) in
#check_failure (LDeriv.closeT (.lit R2.TheBodySSystemsB.the_body_s_systems_m45537_52) (.lit S_dex) bgIsaGlucose "bad")
#eval proto "F" s!"close(-200, -53) gives a negative loop at b={closeGlucose.opinion.belief.toDecimal}; close(P02 arms) a positive loop. closeT(-52, -53, blood glucose is_a glucose) gives the same loop with the arms linked by the kernel (b={closeGlucoseT.opinion.belief.toDecimal}); unrelated arms do not typecheck. Neither is homeostatic: that needs a set point or an assertion"

/-! ## (B) Sign: what the core form loses -/

def X02_arm1 : Statement := ⟨"syn:X02-1", "SYNTHETIC: insulin raises blood glucose", .effect insulin .pos (.amount bloodGlucose), [tb "synthetic"]⟩
def X02_arm2 : Statement := ⟨"syn:X02-2", "SYNTHETIC: blood glucose raises insulin", .effect bloodGlucose .pos (.amount insulin), [tb "synthetic"]⟩
def closeX02 := LDeriv.close (.lit X02_arm2) (.lit X02_arm1) "X02"
/-- An asserted homeostasis claim agrees with the loop its arms close only if that loop is negative. -/
def agrees (c : Claim) (l : Loop) : Bool :=
  match c with
  | .homeostasis r h => l.sign == .neg && base r.curie ∈ l.nodes && base (targetCurie h) ∈ l.nodes
  | _ => false
#guard !agrees (.homeostasis insulin (.amount bloodGlucose)) { id := "X02", sign := .pos * .pos, held := .amount bloodGlucose, regulators := [⟨insulin, .pos⟩] }
#guard agrees (.homeostasis insulin (.amount bloodGlucose)) { id := "glucose/insulin", sign := .pos * .neg, held := .amount bloodGlucose, regulators := [⟨insulin, .neg⟩] }
-- the loop `close` actually builds from X02's arms, read off its type, disagrees with the asserted claim; the glucose one agrees
#guard closeX02.linked
#guard closeX02.result.loop?.map (agrees (.homeostasis insulin (.amount bloodGlucose))) == some false
#guard closeGlucose.result.loop?.map (agrees (.homeostasis insulin (.amount bloodGlucose))) == some true
#eval proto "X02" "the arms close a positive loop, so the asserted homeostasis claim disagrees: flagged"

/-- (E5, a lint outside the core) The arm pairs in `arms` that close the loop an asserted `homeostasis` claim names: one
from the held variable to the regulator, one back, by base curie; each pair with its two signs. -/
def effEnds : Claim → Option (String × Sign × String)
  | .effect a s t => some (base a.curie, s, base (targetCurie t))
  | _ => none
def armsFor (c : Claim) (arms : List Claim) : List (Sign × Sign) :=
  match c with
  | .homeostasis r h =>
    let es := arms.filterMap effEnds
    let ups := es.filter fun e => e.1 == base (targetCurie h) && e.2.2 == base r.curie
    let downs := es.filter fun e => e.1 == base r.curie && e.2.2 == base (targetCurie h)
    ups.flatMap fun u => downs.map fun d => (u.2.1, d.2.1)
  | _ => []
/-- The textbook arms on blood glucose and blood calcium (R2, R3). -/
def bookArms : List Claim :=
  [R2.TheBodySSystemsB.the_body_s_systems_m45537_52.claim, R3.TheBodySSystemsB.the_body_s_systems_m45537_53.claim,
   R3.TheBodySSystemsB.the_body_s_systems_m45537_199.claim, R3.TheBodySSystemsB.the_body_s_systems_m45537_200.claim,
   R3.TheBodySSystemsB.the_body_s_systems_m45537_201.claim, R3.TheBodySSystemsB.the_body_s_systems_m45537_140.claim,
   R3.TheBodySSystemsB.the_body_s_systems_m45537_141.claim]
def X01_claim : Claim := .homeostasis insulin (.amount bloodCalcium)
#guard (armsFor X01_claim bookArms).isEmpty                                                    -- X01: no arms at all
#guard (armsFor (.homeostasis insulin (.amount bloodGlucose)) bookArms).all (fun p => p.1 * p.2 == .neg)
#guard !(armsFor (.homeostasis insulin (.amount bloodGlucose)) bookArms).isEmpty                -- the real loop has its arms
#guard !(armsFor (.homeostasis pth (.amount bloodCalcium)) bookArms).isEmpty
#guard armsFor (.homeostasis insulin (.amount bloodGlucose)) [X02_arm1.claim, X02_arm2.claim] == [(.pos, .pos)]   -- X02: positive
#eval proto "X01" s!"the arm check finds {(armsFor X01_claim bookArms).length} arm pairs for '{X01_claim}' among the textbook glucose and calcium arms (the insulin loop has {(armsFor (.homeostasis insulin (.amount bloodGlucose)) bookArms).length}, the PTH loop {(armsFor (.homeostasis pth (.amount bloodCalcium)) bookArms).length}): visible as unsupported by arms"

#guard oxytocinLoop.toCore.isEmpty
#guard thrombinLoop.toCore.isEmpty
#guard (glucoseLoop.toCore).length == 2
#guard glucoseLoop.toCore.map toString == ({ glucoseLoop with regulators := [⟨insulin, .pos⟩, ⟨glucagon, .neg⟩] }).toCore.map toString
#eval proto "P01" s!"{LClaim.describe (.loop oxytocinLoop)}; toCore gives nothing, so the core can no longer be told a positive loop is homeostasis"
#eval proto "T01" s!"{LClaim.describe (.loop glucoseLoop)}; toCore gives {glucoseLoop.toCore.length} homeostasis claims and forgets the directions (swapping them maps to the same claims)"
#eval proto "T02" s!"{LClaim.describe (.loop calciumLoop)}"

/-! ## (D) Set points -/

#guard (thermoLoop.setPoint.map (·.claim)).isSome
#guard (match thermoLoop.setPoint with | some s => s.q.curie == targetCurie thermoLoop.held | none => false)
def fever : LClaim := .shiftsSetPoint pyrogen .pos thermoLoop
def heat : LClaim := .core (.effect hotEnvironment .pos (.phenotype bodyTemp))
def isShift : LClaim → Bool | .shiftsSetPoint .. => true | _ => false
#guard isShift fever && !isShift heat
def adhThreshold : LClaim := .shiftsSetPoint hypovolemia .neg osmoLoop
#eval proto "S01" s!"{LClaim.describe (.loop thermoLoop)}: the set point is a core measure claim tied to the loop"
#eval proto "S02" s!"{LClaim.describe fever}"
#eval proto "S03" s!"fever is '{LClaim.describe fever}', heat stroke is '{LClaim.describe heat}': now different claims"
#eval proto "T04" s!"{LClaim.describe adhThreshold} (Kondo 2004: hypovolemia lowers the Na threshold for AVP release)"

/-! ## P08 a positive loop made of two negative arms (Gardner 2000 toggle switch; LacI and TetR an illustrative pair) -/

def ecoliT : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩
def lacI : Entity .protein := (⟨"PR:000023070", "lactose operon repressor"⟩ : Entity .protein).inCtx { taxon := ecoliT }
def tetR : Entity .protein := (⟨"PR:P04483", "tetracycline repressor protein class B from transposon Tn10 (Escherichia coli)"⟩ : Entity .protein).inCtx { taxon := ecoliT }
def gardner : Evidence := paper 10659857 2000 .mechanistic "Gardner 2000"
def S_ab : Statement := ⟨"syn:P08-ab", "LacI represses TetR", .effect lacI .neg (.amount tetR), [gardner]⟩
def S_ba : Statement := ⟨"syn:P08-ba", "TetR represses LacI", .effect tetR .neg (.amount lacI), [gardner]⟩
def P08 : Derivation (.effect lacI .pos (.amount lacI)) := .viaAmount (.lit S_ab) (.lit S_ba)
def toggleLoop : Loop := { id := "toggle+", sign := .pos, held := .amount lacI, regulators := [⟨tetR, .neg⟩] }
def closeToggle := LDeriv.close (.lit S_ab) (.lit S_ba) "toggle"
#guard classify [toggleLoop] P08 == .roundTrip "toggle+"
#guard classify [] P08 == .cycle
#guard closeToggle.linked && closeToggle.result.loop?.map (·.sign) == some .pos      -- neg * neg = pos
#guard toggleLoop.toCore.isEmpty                                                      -- not homeostasis
#guard blockedByG P08                                                                  -- (G) would block this true loop too
#eval proto "P08" s!"{Reading.str (classify [toggleLoop] P08)} once asserted (signed); close gives a loop of sign {if closeToggle.result.loop?.map (·.sign) == some .pos then "positive" else "negative"} from two negative arms; toCore gives nothing"

/-! ## The LH surge: the arm's sign depends on a condition -/

def lhLoop : Loop := { id := "LH", sign := .neg, held := .amount e_PR_P01229, regulators := [⟨estradiol, .neg⟩], homeostatic := true }
def lhSurge : Loop :=
  { id := "LH-surge", sign := .pos, held := .amount e_PR_P01229,
    regulators := [⟨estradiol.inCtx { taxon := Taxa.human, condition := some (.organism sustainedHighE2) }, .pos⟩] }
#guard lhLoop.sign != lhSurge.sign
#eval proto "P06" s!"two loops, '{lhLoop.id}' negative and '{lhSurge.id}' positive under a placeholder condition; the switch itself is still not a claim"

end BioLean.Proto.Feedback
