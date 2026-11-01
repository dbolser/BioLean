import BioLean.Derivation
import BioLean.Examples.Homeostasis
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR2.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR2.MolecularBiology
import BioLean.Lib.TextbookClaimsR2.Photosynthesis
import BioLean.Lib.TextbookClaimsR2.ReproductionAtTheCellularLevel
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR2.TheCellularBasisOfInheritance
import BioLean.Lib.TextbookClaimsR3.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR3.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR3.MolecularBiology
import BioLean.Lib.TextbookClaimsR3.Photosynthesis
import BioLean.Lib.TextbookClaimsR3.ReproductionAtTheCellularLevel
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR3.TheCellularBasisOfInheritance

/-!
# Program 06: prototypes of an "opposes" relation

`docs/programs/06-opposition.md`. Nothing here changes the core. Each option is prototyped in this
file, next to the cases that exercise it, because a new file cannot import another new file.

| option | what | core change if adopted |
|---|---|---|
| (b) | `OpposesAt a b t`: a raises t and b lowers t, both derived. A structure over core derivations | none (library definition) |
| (c) | primitive `opposes a b`, symmetric, with `flip`: a opposes b, b →s t ⊢ a →(−s) t | new Claim constructor, two new Derivation rules |
| (f) | primitive `opposesAt a b t`, asserted per target, `flipAt` only at that t | new Claim constructor, two new Derivation rules |
| (e) | `CounterReg a b held`: two `homeostasis` loops on one held target, with opposite arms | none (library definition) plus loop annotations |
| (d) | ChEBI receptor roles turned into signed effects on receptor activity by a hand table | none (emitter and data) |
| (g) | an interaction target: "a lowers the effect of b on t" | new Target constructor |
| (h) | opposite targets (RO:0002604 "is opposite of", an annotation property) widen (b) | none for detection; a rule would be a core change |

(c) and (f) need a claim the core does not have, so they are prototyped on a wrapper type `OClaim`
with its own derivations `ODeriv`, which embed core derivations unchanged. (g) is prototyped as a
wrapper target `ITarget`. Every observed result is printed as an `OBS` line and pinned by `#guard`,
`example` or `theorem ... := by decide +kernel`.

Statement sources: OpenStax Concepts of Biology through the compiled libraries R2 and R3 (R3
supersedes R2 by id), and papers checked on Europe PMC (`data/stress/06/references_checked.tsv`).
SYNTHETIC marks a statement I wrote; its source is named on the statement. CURIEs are checked on OLS4
(`data/stress/06/curies_checked.tsv`).
-/

namespace BioLean.Proto.Opposes
open BioLean Derivation BioLean.Textbook.R2 BioLean.Textbook.R3

/-! ## Helpers -/

def obs (id msg : String) : IO Unit := IO.println s!"OBS\t{id}\t{msg}"

def tb (note : String) : Evidence := { pmid := 0, year := 2013, kind := .textbook, note := note }

def paper (pmid year : Nat) (k : EvidenceKind) (note : String) : Evidence :=
  { pmid := pmid, year := year, kind := k, note := note }

/-- An opinion as `b/d/u` with three decimals, for OBS lines. -/
def ostr (o : Opinion) : String :=
  s!"b={o.belief.toDecimal} d={o.disbelief.toDecimal} u={o.uncertainty.toDecimal}"

def sgn : Sign → String | .pos => "+" | .neg => "-"

/-! ## The library as data

`#collect name` defines `name : List Statement` holding every compiled textbook statement, R3
first; an R2 statement is dropped when R3 has one of the same name. -/

open Lean Elab Command in
elab "#collect " n:ident : command => do
  let env ← getEnv
  let st := mkConst ``BioLean.Statement
  let mut r3 : Array Name := #[]
  let mut r2 : Array Name := #[]
  for (nm, ci) in env.constants.map₁.toList do
    if ci.type == st then
      if (`BioLean.Textbook.R3).isPrefixOf nm then r3 := r3.push nm
      else if (`BioLean.Textbook.R2).isPrefixOf nm then r2 := r2.push nm
  let last := fun (x : Name) => x.componentsRev.head!
  let r3last := r3.map last
  let r2keep := r2.filter fun x => !r3last.contains (last x)
  let all := (r3 ++ r2keep).qsort (fun a b => a.toString < b.toString)
  let ids : Array (TSyntax `term) := all.map fun x => ⟨mkIdent x⟩
  elabCommand (← `(def $n : List BioLean.Statement := [$ids,*]))

#collect library

-- 480 R3 statements and 1,485 R2 statements not superseded.
#guard library.length = 1965

/-- A target by curie, so two statements on the same target compare equal whatever the label. -/
def tkey : Target → String
  | .activity p _ => s!"activity:{p.curie}" | .amount m => s!"amount:{m.curie}"
  | .process p => s!"process:{p.curie}" | .phenotype p => s!"phenotype:{p.curie}"
  | .site a => s!"site:{a.curie}"

/-- A signed effect read off a statement. Effects under `some` or `most` are left out. -/
structure Eff where
  id : String
  agent : String
  alabel : String
  sign : Sign
  tk : String
  tstr : String

def effOf (s : Statement) : Option Eff := match s.claim with
  | .effect a sg t => some ⟨s.id, a.curie, a.label, sg, tkey t, toString t⟩
  | _ => none

def effs : List Eff := library.filterMap effOf
#guard effs.length = 365

/-! ## Option (b): opposition defined, not asserted -/

/-- `a` raises `t` and `b` lowers `t`. Both halves are core derivations, so this adds nothing the
core cannot already prove: it names a pair of facts. Strength: the weaker half. -/
structure OpposesAt {k₁ k₂ : Kind} (a : Entity k₁) (b : Entity k₂) (t : Target) where
  up : Derivation (.effect a .pos t)
  down : Derivation (.effect b .neg t)

namespace OpposesAt
variable {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {t : Target}
def opinion [EvidenceModel] (o : OpposesAt a b t) : Opinion := o.up.opinion.weakest o.down.opinion
def axioms (o : OpposesAt a b t) : List Statement := o.up.axioms ++ o.down.axioms
end OpposesAt

/-- Every pair of statements, one raising and one lowering the same target, with different agents. -/
def bPairs : List (Eff × Eff) :=
  effs.flatMap fun e₁ => if e₁.sign = .pos then
    (effs.filter fun e₂ => e₂.sign = .neg && e₂.tk == e₁.tk && e₂.agent != e₁.agent).map (e₁, ·) else []

/-- The distinct unordered agent pairs among them. -/
def bAgentPairs : List (String × String) :=
  (bPairs.map fun (x, y) => if x.agent < y.agent then (x.agent, y.agent) else (y.agent, x.agent)).eraseDups

#guard bPairs.length = 82
#guard bAgentPairs.length = 50

/-- My reading of the 50 agent pairs (`data/stress/06/b_pairs.tsv` has the reason for each):
`A` real antagonism in the textbook or physiology sense, `M` one agent acts on the other (inhibitor
and its enzyme), `C` coincidence: both statements are fair readings, but nobody calls the agents a
pair, `X` an annotation artefact: at least one statement misreads its sentence ("reabsorbed lowers
ATP"). A process as agent is not by itself an artefact ("vasoconstriction lowers blood flow" is C).
The 6 `A` pairs and the 1 `M` pair are below. They are the pairs that share an exact target; (b)
misses pairs on opposite targets, such as the bronchi (option h). -/
def antagonistPairs : List (String × String) :=
  [("UBERON:0000011", "UBERON:0000013"), ("CHEBI:33568", "UBERON:0000011"), ("CHEBI:15422", "CHEBI:16761"),
   ("PR:000013429", "PR:P01258"), ("CHEBI:33568", "PR:000009054"), ("PR:000009054", "PR:P01275"),
   ("CHEBI:87631", "PR:000008636")]
#guard antagonistPairs.all (bAgentPairs.contains ·)

/-! ### (b) on the six hole sentences -/

abbrev symp := e_UBERON_0000013
abbrev para := e_UBERON_0000011
def s299 := TheBodySSystemsB.the_body_s_systems_m45539_299   -- symp raises heart rate
def s300 := TheBodySSystemsB.the_body_s_systems_m45539_300   -- symp inhibits digestion
def s371 := TheBodySSystemsB.the_body_s_systems_m45539_371   -- symp raises blood pressure
def s306 := TheBodySSystemsB.the_body_s_systems_m45539_306   -- para slows heart rate
def s307 := TheBodySSystemsB.the_body_s_systems_m45539_307   -- para lowers blood pressure
def s308 := TheBodySSystemsB.the_body_s_systems_m45539_308   -- para stimulates digestion
def s373 := TheBodySSystemsB.the_body_s_systems_m45539_373   -- symp lowers skin blood flow (R3)
def s377 := TheBodySSystemsB.the_body_s_systems_m45539_377   -- para raises skin blood flow (R3)

def b_hr : OpposesAt symp para (.phenotype e_OBA_1001087) := ⟨.lit s299, .lit s306⟩
def b_bp : OpposesAt symp para (.phenotype e_OBA_VT0000183) := ⟨.lit s371, .lit s307⟩
def b_dig : OpposesAt para symp (.process e_GO_0007586) := ⟨.lit s308, .lit s300⟩
def b_skin : OpposesAt para symp (.process (e_GO_0008015.inCtx { anatomy := e_UBERON_0002097 })) :=
  ⟨.lit s377, .lit s373⟩

-- (b) needs both sentences as input, so it makes none of the six a theorem.
#guard b_hr.axioms.map (·.id) = ["the-body-s-systems-m45539-299", "the-body-s-systems-m45539-306"]
theorem b_hr_belief : b_hr.opinion.belief = 4 / 5 := by decide +kernel

/-! ## Options (c) and (f): a primitive opposition claim with a sign-flip rule -/

/-- The claims of the prototype: the core's, plus `opposes a b` (option c: symmetric, no target)
and `opposesAt a b t` (option f: one target, sign-free: "they have opposing effects on t"). -/
inductive OClaim
  | core (c : Claim)
  | opposes {k₁ k₂ : Kind} (a : Entity k₁) (b : Entity k₂)
  | opposesAt {k₁ k₂ : Kind} (a : Entity k₁) (b : Entity k₂) (t : Target)

structure OStatement where
  id : String
  text : String
  claim : OClaim
  evidence : List Evidence

def OStatement.opinion [EvidenceModel] (s : OStatement) : Opinion :=
  s.evidence.foldl (fun acc e => acc.fuse e.opinion) Opinion.vacuous

/-- Derivations of the prototype. `core` embeds a core derivation unchanged. `flip` is option (c):
`a opposes b` and `b →s t` give `a →(−s) t` for every t. `flipAt` is option (f): the same, only at
the t named in the opposition. Both are logical steps: opinion `weakest`, as for `relChain`. -/
inductive ODeriv : OClaim → Type
  | core {c : Claim} (d : Derivation c) : ODeriv (.core c)
  | olit (s : OStatement) : ODeriv s.claim
  | symm {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} (o : ODeriv (.opposes a b)) : ODeriv (.opposes b a)
  | flip {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {s : Sign} {t : Target}
      (o : ODeriv (.opposes a b)) (e : ODeriv (.core (.effect b s t))) :
      ODeriv (.core (.effect a (Sign.neg * s) t))
  | symmAt {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {t : Target} (o : ODeriv (.opposesAt a b t)) :
      ODeriv (.opposesAt b a t)
  | flipAt {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {s : Sign} {t : Target}
      (o : ODeriv (.opposesAt a b t)) (e : ODeriv (.core (.effect b s t))) :
      ODeriv (.core (.effect a (Sign.neg * s) t))
  | both {c : OClaim} (d₁ d₂ : ODeriv c) : ODeriv c

namespace ODeriv
def opinion [EvidenceModel] : {c : OClaim} → ODeriv c → Opinion
  | _, .core d => d.opinion
  | _, .olit s => s.opinion
  | _, .symm o => o.opinion
  | _, .flip o e => o.opinion.weakest e.opinion
  | _, .symmAt o => o.opinion
  | _, .flipAt o e => o.opinion.weakest e.opinion
  | _, .both d₁ d₂ => d₁.opinion.fuse d₂.opinion

def axioms : {c : OClaim} → ODeriv c → List String
  | _, .core d => d.axioms.map (·.id)
  | _, .olit s => [s.id]
  | _, .symm o => o.axioms
  | _, .flip o e => o.axioms ++ e.axioms
  | _, .symmAt o => o.axioms
  | _, .flipAt o e => o.axioms ++ e.axioms
  | _, .both d₁ d₂ => d₁.axioms ++ d₂.axioms
end ODeriv

/-- `the-body-s-systems-m45539-296`: "There are two divisions of the autonomic nervous system that
often have opposing effects: the sympathetic nervous system and the parasympathetic nervous system."
R1 to R3 bin it `missing_construct`; there is no Lean for it. As `opposes` it loses "often". -/
def oppPS : OStatement :=
  ⟨"the-body-s-systems-m45539-296", "the parasympathetic and sympathetic divisions have opposing effects",
   .opposes para symp, [tb "There are two divisions of the autonomic nervous system that often have opposing effects"]⟩

def c_ps : ODeriv (.opposes para symp) := .olit oppPS
def c_sp : ODeriv (.opposes symp para) := .symm c_ps

/-! ### (c) makes the six hole sentences theorems. Each `def` type-checks only if the conclusion is
exactly the stated sentence's claim. -/

def c306 : ODeriv (.core s306.claim) := .flip c_ps (.core (.lit s299))
def c307 : ODeriv (.core s307.claim) := .flip c_ps (.core (.lit s371))
def c308 : ODeriv (.core s308.claim) := .flip c_ps (.core (.lit s300))
def c299 : ODeriv (.core s299.claim) := .flip c_sp (.core (.lit s306))
def c371 : ODeriv (.core s371.claim) := .flip c_sp (.core (.lit s307))
def c300 : ODeriv (.core s300.claim) := .flip c_sp (.core (.lit s308))
/-- And the skin pair: "parasympathetic activation increases blood flow to the skin" (false) follows
from the true sympathetic sentence. -/
def c377 : ODeriv (.core s377.claim) := .flip c_ps (.core (.lit s373))

theorem c306_belief : c306.opinion.belief = 4 / 5 := by decide +kernel
/-- Fusing the derived 306 with the stated 306 counts one textbook paragraph twice: 0.889. -/
theorem c306_both_belief : (ODeriv.both c306 (.core (.lit s306))).opinion.belief = 8 / 9 := by decide +kernel

/-! ### (c) over the whole library

`cRun pairs` applies `flip` once to every effect statement of either member of each asserted pair
and sorts the conclusions: `theorem` (the library states it), `clash` (the library states the
opposite sign), `new`. This is the forward step a closure search would take with rule (c). -/

structure Concl where
  agent : String
  alabel : String
  sign : Sign
  tk : String
  tstr : String
  fromId : String
  fromAgent : String
  kind : String

def classify (agent alabel : String) (s : Sign) (tk tstr fromId : String) (fromAgent : String := "") : Concl :=
  let same := effs.any fun e => e.agent == agent && e.sign == s && e.tk == tk
  let opp := effs.any fun e => e.agent == agent && e.sign != s && e.tk == tk
  ⟨agent, alabel, s, tk, tstr, fromId, fromAgent, if same then "theorem" else if opp then "clash" else "new"⟩

def labelOf (c : String) : String := ((effs.find? (·.agent == c)).map (·.alabel)).getD c

/-- One direction: `a opposes b`, every effect of `b` flipped onto `a`. -/
def cFrom (a b : String) : List Concl :=
  (effs.filter (·.agent == b)).map fun e => classify a (labelOf a) (Sign.neg * e.sign) e.tk e.tstr e.id e.agent

/-- Drop repeated conclusions (same agent, sign and target), keeping the first source. -/
def dedupC (l : List Concl) : List Concl :=
  l.foldl (fun acc c => if acc.any (fun d => d.agent == c.agent && d.sign == c.sign && d.tk == c.tk) then acc
    else acc ++ [c]) []

def cRun (pairs : List (String × String)) : List Concl :=
  dedupC (pairs.flatMap fun (a, b) => cFrom a b ++ cFrom b a)

def count (k : String) (l : List Concl) : Nat := (l.filter (·.kind == k)).length

/-- The three pairs the textbook names: the autonomic branches (m45539-296), insulin and glucagon
(m45537-331, -333), and calcitonin and PTH (the book's opposite effects, 135 and 140). -/
def bookPairs : List (String × String) :=
  [("UBERON:0000011", "UBERON:0000013"), ("PR:000009054", "PR:P01275"), ("PR:P01258", "PR:000013429")]

def cBook := cRun bookPairs
#guard cBook.length = 16
#guard (count "theorem" cBook, count "clash" cBook, count "new" cBook) = (12, 0, 4)

/-- Promote every (b) pair to a primitive opposition, as a search that read "opposite sign on one
target" as "these two oppose" would do. -/
def cAll := cRun bAgentPairs
#guard cAll.length = 175
#guard (count "theorem" cAll, count "clash" cAll, count "new" cAll) = (69, 0, 106)

/-! ### (f): opposition asserted per target -/

/-- The book's sentence for the parasympathetic effects names three targets of the sympathetic
sentence it answers (m45539-306 to 308 resets "heart rate, blood pressure, digestion"). As (f), one
`opposesAt` per target. -/
def oppAt (t : Target) (tname : String) : OStatement :=
  ⟨s!"the-body-s-systems-m45539-306..308/{tname}", s!"the two divisions oppose at {tname}",
   .opposesAt para symp t, [tb "The parasympathetic nervous system resets organ function after the sympathetic nervous system is activated including slowing of heart rate, lowered blood pressure, and stimulation of digestion."]⟩

def f306 : ODeriv (.core s306.claim) := .flipAt (.olit (oppAt (.phenotype e_OBA_1001087) "heart rate")) (.core (.lit s299))
def f307 : ODeriv (.core s307.claim) := .flipAt (.olit (oppAt (.phenotype e_OBA_VT0000183) "blood pressure")) (.core (.lit s371))
def f308 : ODeriv (.core s308.claim) := .flipAt (.olit (oppAt (.process e_GO_0007586) "digestion")) (.core (.lit s300))
def f299 : ODeriv (.core s299.claim) := .flipAt (.symmAt (.olit (oppAt (.phenotype e_OBA_1001087) "heart rate"))) (.core (.lit s306))
def f371 : ODeriv (.core s371.claim) := .flipAt (.symmAt (.olit (oppAt (.phenotype e_OBA_VT0000183) "blood pressure"))) (.core (.lit s307))
def f300 : ODeriv (.core s300.claim) := .flipAt (.symmAt (.olit (oppAt (.process e_GO_0007586) "digestion"))) (.core (.lit s308))

/-- (f) as data: the scoped run fires only at the asserted targets. With the three book targets it
adds nothing new and nothing false. -/
def fRun (pairs : List (String × String × String)) : List Concl :=
  pairs.flatMap fun (a, b, t) =>
    ((effs.filter fun e => e.agent == b && e.tk == t).map fun e => classify a (labelOf a) (Sign.neg * e.sign) e.tk e.tstr e.id) ++
    ((effs.filter fun e => e.agent == a && e.tk == t).map fun e => classify b (labelOf b) (Sign.neg * e.sign) e.tk e.tstr e.id)

def fBook := fRun [("UBERON:0000011", "UBERON:0000013", "phenotype:OBA:1001087"),
                   ("UBERON:0000011", "UBERON:0000013", "phenotype:OBA:VT0000183"),
                   ("UBERON:0000011", "UBERON:0000013", "process:GO:0007586")]
#guard (count "theorem" fBook, count "clash" fBook, count "new" fBook) = (11, 0, 0)

/-- (f) is circular when annotated from the book. Its `opposesAt` statements cite the 306-308
sentence, so f306 rests on the sentence it derives, and f299 rests on that one sentence alone (it
does imply the sympathetic sign; option (a) gets the same by annotating one more effect from it).
The ids differ ("...-306..308/heart rate" and "...-306"), so a check by id, like the core's
`sharedAxioms`, cannot see the double count. -/
def from306 (ids : List String) : Bool :=
  ids.all fun i => i.startsWith "the-body-s-systems-m45539-306..308/" ||
    i ∈ ["the-body-s-systems-m45539-306", "the-body-s-systems-m45539-307", "the-body-s-systems-m45539-308"]
#guard f306.axioms = ["the-body-s-systems-m45539-306..308/heart rate", "the-body-s-systems-m45539-299"]
#guard from306 f299.axioms && from306 f371.axioms && from306 f300.axioms
theorem f306_both_belief : (ODeriv.both f306 (.core (.lit s306))).opinion.belief = 8 / 9 := by decide +kernel
#guard ((ODeriv.both f306 (.core (.lit s306))).axioms.eraseDups.length) = 3

/-- Annotated from the parasympathetic sentence that lists skin (m45539-374 to -377), (f) at skin
re-derives the false m45539-377 from the true -373, as (c) does. -/
def oppAtSkin : OStatement :=
  ⟨"the-body-s-systems-m45539-374..377/skin", "the two divisions oppose at skin blood flow",
   .opposesAt para symp (.process (e_GO_0008015.inCtx { anatomy := e_UBERON_0002097 })),
   [tb "Activation of the parasympathetic nervous system decreases heart rate and blood pressure and increases digestion and blood flow to the skin."]⟩
def f377 : ODeriv (.core s377.claim) := .flipAt (.olit oppAtSkin) (.core (.lit s373))
theorem f377_belief : f377.opinion.belief = 4 / 5 := by decide +kernel

/-! ## Entities used below (all checked on OLS4) -/

def sweatSecretion : Entity .process := ⟨"GO:0160269", "sweat secretion"⟩
def epiSecretion : Entity .process := ⟨"GO:0048242", "epinephrine secretion"⟩
def adrenalMedulla : Entity .anatomy := ⟨"UBERON:0001236", "adrenal medulla"⟩
def salivaSecretion : Entity .process := ⟨"GO:0046541", "saliva secretion"⟩
def calcitriol : Entity .chemical := ⟨"CHEBI:17823", "calcitriol"⟩
def naloxone : Entity .chemical := ⟨"CHEBI:7459", "naloxone"⟩
def morphine : Entity .chemical := ⟨"CHEBI:17303", "morphine"⟩
def mor : Entity .protein := ⟨"PR:000001612", "mu-type opioid receptor"⟩
def painPerception : Entity .process := ⟨"GO:0019233", "sensory perception of pain"⟩
def histamineMast : Entity .process := ⟨"GO:0002553", "histamine secretion by mast cell"⟩
def breathing : Entity .process := ⟨"GO:0007585", "respiratory gaseous exchange by respiratory system"⟩
def wee1 : Entity .protein := ⟨"PR:000017403", "Wee1-like protein kinase"⟩
def cdc25c : Entity .protein := ⟨"PR:000005193", "M-phase inducer phosphatase 3"⟩
def cdk1 : Entity .protein := ⟨"PR:000003271", "cyclin-dependent kinase 1"⟩
def pi3k : Entity .protein := ⟨"PR:000012719", "PI 4,5-bisphosphate 3-kinase catalytic subunit alpha"⟩
def pten : Entity .protein := ⟨"PR:000028746", "PTEN"⟩
def pip3 : Entity .chemical := ⟨"CHEBI:16618", "1-phosphatidyl-1D-myo-inositol 3,4,5-trisphosphate"⟩
def auxin : Entity .chemical := ⟨"CHEBI:22676", "auxin"⟩
def cytokinin : Entity .chemical := ⟨"CHEBI:23530", "cytokinin"⟩
def secondaryShoot : Entity .process := ⟨"GO:0010223", "secondary shoot formation"⟩
def rootMeristemGrowth : Entity .process := ⟨"GO:0010449", "root meristem growth"⟩
def cellDivision : Entity .process := ⟨"GO:0051301", "cell division"⟩
def gaba : Entity .chemical := ⟨"CHEBI:16865", "gamma-aminobutyric acid"⟩
def glutamate : Entity .chemical := ⟨"CHEBI:29985", "L-glutamate(1-)"⟩
def depolarization : Entity .process := ⟨"GO:0051899", "membrane depolarization"⟩
def neonate : Entity .anatomy := ⟨"UBERON:0007221", "neonate stage"⟩
def adultStage : Entity .anatomy := ⟨"UBERON:0000113", "post-juvenile adult stage"⟩
def argipressin : Entity .chemical := ⟨"CHEBI:34543", "argipressin"⟩
def renalWater : Entity .process := ⟨"GO:0070295", "renal water absorption"⟩
def leftVentricle : Entity .anatomy := ⟨"UBERON:0002084", "heart left ventricle"⟩
def pupil : Entity .anatomy := ⟨"UBERON:0001771", "pupil"⟩
def diameter : Entity .phenotype := ⟨"PATO:0001334", "diameter"⟩

/-- Pupil diameter as a refined quality: diameter ⊓ characteristic of (pupil), RO:0000052. -/
def pupilDiameter : Entity .phenotype := diameter.refine ⟨.ro, 52, false⟩ pupil

/-! ## Cases for (c) beyond the book sentences

Each case: the input statement(s), the (c) conclusion as an `ODeriv` (it type-checks, so the
prototype derives it), its opinion, and what the source says. -/

/-- A literature statement. -/
def litS {k : Kind} (id text : String) (a : Entity k) (s : Sign) (t : Target) (ev : List Evidence) : Statement :=
  ⟨id, text, .effect a s t, ev⟩

/-! ### Single-branch effectors: (c) invents a parasympathetic effect -/

/-- `the-body-s-systems-m45534-81` (R2): the sympathetic system directs temperature homeostasis. -/
def s81 := TheBodySSystemsA.the_body_s_systems_m45534_81
def cThermo : ODeriv (.core (.effect para .neg (.process e_GO_0001659))) := .flip c_ps (.core (.lit s81))

/-- Sugenoya 1990 (PMID 2282916): sympathetic sudomotor bursts precede sweat expulsion. -/
def sSweat := litS "PMID:2282916" "sympathetic activity raises sweating" symp .pos (.process sweatSecretion)
  [paper 2282916 1990 .mechanistic "Sweat expulsion was always preceded by bursts of SSA"]
def cSweat : ODeriv (.core (.effect para .neg (.process sweatSecretion))) := .flip c_ps (.core (.lit sSweat))

/-- Wilson 2002 (PMID 12482898): adrenal catecholamine release is mediated by sympathetic
preganglionic neurones. The hole search proposed "sympathetic raises adrenaline" (docs/holes.md row 591). -/
def sAdrenal := litS "PMID:12482898" "sympathetic activity raises adrenal epinephrine secretion" symp .pos
  (.process (epiSecretion.inCtx { anatomy := adrenalMedulla }))
  [paper 12482898 2002 .mechanistic "intravascular release of adrenal catecholamines ... mediated via thoracolumbar spinal sympathetic preganglionic neurones"]
def cAdrenal : ODeriv (.core (.effect para .neg (.process (epiSecretion.inCtx { anatomy := adrenalMedulla })))) :=
  .flip c_ps (.core (.lit sAdrenal))

/-! ### A synergistic effector: both branches raise salivary secretion (Proctor 2007, PMID 17157080) -/

def sSalivaP := litS "PMID:17157080/para" "parasympathetic nerves evoke saliva secretion" para .pos (.process salivaSecretion)
  [paper 17157080 2007 .review "All salivary glands are supplied by cholinergic parasympathetic nerves ... evoking the secretion of saliva"]
def sSalivaS := litS "PMID:17157080/symp" "sympathetic nerves evoke salivary protein secretion" symp .pos (.process salivaSecretion)
  [paper 17157080 2007 .review "Most salivary glands also receive a variable innervation from sympathetic nerves ... greater release of stored proteins"]
def cSaliva : ODeriv (.core (.effect symp .neg (.process salivaSecretion))) := .flip c_sp (.core (.lit sSalivaP))
/-- The derived "sympathetic lowers saliva" read against the stated "sympathetic raises saliva":
belief and disbelief both high, so contested. Built by hand: the core has no clash for effects. -/
def salivaClash : Opinion := (Derivation.lit sSalivaS).opinion.fuse cSaliva.opinion.negate

/-! ### Dual innervation done right: pupil, left ventricle -/

/-- Liu 2017 (PMID 28954227): "Pupil size is collectively controlled by the sympathetic dilator and
parasympathetic sphincter muscles." -/
def sPupilS := litS "PMID:28954227" "sympathetic activity raises pupil diameter" symp .pos (.phenotype pupilDiameter)
  [paper 28954227 2017 .mechanistic "Pupil size is collectively controlled by the sympathetic dilator and parasympathetic sphincter muscles"]
def cPupil : ODeriv (.core (.effect para .neg (.phenotype pupilDiameter))) := .flip c_ps (.core (.lit sPupilS))

/-- Textbook R2 m45537-180: epinephrine raises cardiac muscle contraction. As a sympathetic effect on
the left ventricle it is SYNTHETIC (my annotation); Machhada 2016 (PMID 26940639) finds a tonic
vagal inhibition of left ventricular contractility, so (c)'s conclusion is right there. -/
def sLV := litS "SYNTHETIC/LV" "sympathetic activity raises left ventricular contraction" symp .pos
  (.process (e_GO_0060048.inCtx { anatomy := leftVentricle })) [tb "SYNTHETIC: textbook m45537-180 read as a sympathetic effect"]
def cLV : ODeriv (.core (.effect para .neg (.process (e_GO_0060048.inCtx { anatomy := leftVentricle })))) :=
  .flip c_ps (.core (.lit sLV))

/-! ### Hormone pairs -/

def oppIG : OStatement :=
  ⟨"the-body-s-systems-m45537-331/333", "insulin and glucagon have opposing actions", .opposes e_PR_000009054 e_PR_P01275,
   [tb "Many hormone systems regulate body functions through opposing hormone actions. ... Blood-glucose levels are regulated by hormones produced by the pancreas: insulin and glucagon."]⟩
/-- SYNTHETIC: the book gives the two effects (m45537-135, -140) but never says "opposing". -/
def oppCP : OStatement :=
  ⟨"SYNTHETIC/calcitonin-PTH", "calcitonin and PTH have opposing actions", .opposes e_PR_P01258 e_PR_000013429,
   [tb "SYNTHETIC: from m45537-135 and -140, and m45537-331 'opposing hormone actions'"]⟩

def s53 := TheBodySSystemsB.the_body_s_systems_m45537_53     -- insulin lowers blood glucose (R3)
def s201 := TheBodySSystemsB.the_body_s_systems_m45537_201   -- glucagon raises blood glucose (R3)
def s202 := TheBodySSystemsB.the_body_s_systems_m45537_202   -- insulin raises glucose import (R2)
def s135 := TheBodySSystemsB.the_body_s_systems_m45537_135   -- calcitonin lowers blood calcium (R3)
def s140 := TheBodySSystemsB.the_body_s_systems_m45537_140   -- PTH raises blood calcium (R3)

def c53 : ODeriv (.core s53.claim) := .flip (.olit oppIG) (.core (.lit s201))
def c135 : ODeriv (.core s135.claim) := .flip (.olit oppCP) (.core (.lit s140))
/-- Glucagon lowers glucose import into cells: (c) says so; no source I found says it. -/
def cImport : ODeriv (.core (.effect e_PR_P01275 .neg (.process e_GO_0098708))) := .flip (.symm (.olit oppIG)) (.core (.lit s202))

/-- PTH raises calcitriol. Felsenfeld 2015 (PMID 25815174): "Calcitonin is known to stimulate renal
1,25 (OH)2 vitamin D (1,25D) production at a site in the proximal tubule different from parathyroid
hormone". So both raise it. Shinki 1999 (PMID 10393981) finds calcitonin, not PTH, drives it in
normocalcaemic rats. -/
def sPTHcalcitriol := litS "PMID:25815174/PTH" "PTH raises calcitriol" e_PR_000013429 .pos (.amount calcitriol)
  [paper 25815174 2015 .review "at a site in the proximal tubule different from parathyroid hormone"]
def sCTcalcitriol := litS "PMID:25815174/CT" "calcitonin raises calcitriol" e_PR_P01258 .pos (.amount calcitriol)
  [paper 25815174 2015 .review "Calcitonin is known to stimulate renal 1,25 (OH)2 vitamin D (1,25D) production",
   paper 10393981 1999 .mechanistic "CT greatly increased the expression of CYP27B1 mRNA in the kidney of normocalcemic sham-TPTX rats"]
def cCalcitriol : ODeriv (.core (.effect e_PR_P01258 .neg (.amount calcitriol))) := .flip (.olit oppCP) (.core (.lit sPTHcalcitriol))
def calcitriolClash : Opinion := (Derivation.lit sCTcalcitriol).opinion.fuse cCalcitriol.opinion.negate

/-- Promoted pair (epinephrine, insulin), from their opposite signs on blood glucose. R3 m45537-182:
epinephrine raises glycolysis in skeletal muscle. (c) then says insulin lowers it. Kelley 1990
(PMID 2113769): insulin raises muscle glucose uptake, storage, oxidation and glycolysis. -/
def oppEI : OStatement :=
  ⟨"PROMOTED/(b)/blood-glucose", "epinephrine and insulin oppose (promoted from one shared target)",
   .opposes e_PR_000009054 e_CHEBI_33568, [tb "PROMOTED: R3 m45537-181 and -53 have opposite signs on blood glucose"]⟩
def s182 := TheBodySSystemsB.the_body_s_systems_m45537_182
def s183 := TheBodySSystemsB.the_body_s_systems_m45537_183
def cGlycolysis : ODeriv (.core (.effect e_PR_000009054 .neg (.process (e_GO_0006096.inCtx { anatomy := e_UBERON_0014892 })))) :=
  .flip (.olit oppEI) (.core (.lit s182))
/-- And the true one from the same pair: insulin lowers lipolysis in adipose tissue (antilipolytic). -/
def cLipolysis : ODeriv (.core (.effect e_PR_000009054 .neg (.process (e_GO_0016042.inCtx { anatomy := e_UBERON_0001013 })))) :=
  .flip (.olit oppEI) (.core (.lit s183))

/-- Promoted pair (sympathetic, ANP) from blood pressure. R2 m45537-301 (R3): ANP lowers blood Na+.
Twice through (c): ANP opposes symp, symp opposes para, so para agrees with ANP everywhere. -/
def oppSA : OStatement :=
  ⟨"PROMOTED/(b)/blood-pressure", "sympathetic system and ANP oppose (promoted from one shared target)",
   .opposes symp e_PR_P01160, [tb "PROMOTED: R2 m45539-371 and m45537-300 have opposite signs on blood pressure"]⟩
def s301 := TheBodySSystemsB.the_body_s_systems_m45537_301
def cNa1 : ODeriv (.core (.effect symp .pos (.amount (e_CHEBI_29101.inCtx { anatomy := e_UBERON_0000178 })))) :=
  .flip (.olit oppSA) (.core (.lit s301))
def cNa2 : ODeriv (.core (.effect para .neg (.amount (e_CHEBI_29101.inCtx { anatomy := e_UBERON_0000178 })))) :=
  .flip c_ps cNa1
def cDigANP : ODeriv (.core (.effect e_PR_P01160 .pos (.process e_GO_0007586))) := .flip (.symm (.olit oppSA)) (.core (.lit s300))

/-! ### Drugs at a receptor -/

def sMorMOR := litS "CHEMBL70/mechanism" "morphine is a mu opioid receptor agonist" morphine .pos (.activity mor)
  [{ pmid := 0, year := 2026, kind := .curatedDb, note := "ChEMBL mechanism: Mu opioid receptor agonist; ChEBI has_role CHEBI:55322" }]
def sNalMOR := litS "CHEMBL80/mechanism" "naloxone is an opioid receptor antagonist" naloxone .neg (.activity mor)
  [{ pmid := 0, year := 2026, kind := .curatedDb, note := "ChEMBL mechanism: Opioid receptors; mu/kappa/delta antagonist; ChEBI has_role CHEBI:50137" }]
def b_mor : OpposesAt morphine naloxone (.activity mor) := ⟨.lit sMorMOR, .lit sNalMOR⟩

def oppNM : OStatement :=
  ⟨"SYNTHETIC/naloxone-morphine", "naloxone opposes morphine", .opposes naloxone morphine,
   [tb "SYNTHETIC: naloxone antagonises morphine (Olofsen 2010, PMID 20461002)"]⟩
/-- Morphine lowers pain perception (analgesia). ChEBI role CHEBI:35482 "opioid analgesic". -/
def sMorPain := litS "CHEBI:17303/role" "morphine lowers pain perception" morphine .neg (.process painPerception)
  [{ pmid := 0, year := 2026, kind := .curatedDb, note := "ChEBI has_role CHEBI:35482 opioid analgesic" }]
def cNalPain : ODeriv (.core (.effect naloxone .pos (.process painPerception))) := .flip (.olit oppNM) (.core (.lit sMorPain))
/-- El-Sobky 1976 (PMID 186714), title: "Lack of effect of naloxone on pain perception in humans". -/
def sNalPainNull : Statement :=
  ⟨"PMID:186714", "naloxone has no effect on pain perception", .noEffect naloxone (.process painPerception),
   [paper 186714 1976 .rct "Lack of effect of naloxone on pain perception in humans (title)"]⟩
/-- Morphine releases histamine from mast cells; Barke 1993 (PMID 7694026): its pharmacology "is
distinct from that of known opiate receptors". -/
def sMorHist := litS "PMID:7694026" "morphine raises mast cell histamine release" morphine .pos (.process histamineMast)
  [paper 7694026 1993 .review "Opiates have long been known to cause the release of histamine from mast cells"]
def cNalHist : ODeriv (.core (.effect naloxone .neg (.process histamineMast))) := .flip (.olit oppNM) (.core (.lit sMorHist))
/-- At the receptor (c) gets ChEMBL's sign for naloxone from morphine's. -/
def cNalMOR : ODeriv (.core sNalMOR.claim) := .flip (.olit oppNM) (.core (.lit sMorMOR))
/-- Breathing: morphine lowers it (Olofsen 2010), so (c) says naloxone raises it, as a plain effect.
The source gives a reversal of morphine's effect, not an effect of naloxone alone. -/
def sMorBreath := litS "PMID:20461002/morphine" "morphine lowers breathing" morphine .neg (.process breathing)
  [paper 20461002 2010 .rct "morphine- and morphine-6-glucuronide-induced respiratory depression in healthy volunteers"]
def cNalBreath : ODeriv (.core (.effect naloxone .pos (.process breathing))) := .flip (.olit oppNM) (.core (.lit sMorBreath))

/-! ### Kinase and phosphatase -/

/-- Perry 2007 (PMID 17480229): Cdc25 activates and Wee1 inhibits Cdc2 (CDK1)/cyclin B. -/
def sWee1 := litS "PMID:17480229/Wee1" "Wee1 inhibits CDK1" wee1 .neg (.activity cdk1)
  [paper 17480229 2007 .review "inhibit the activators and activate the inhibitors of mitosis, Cdc25 and Wee1, respectively"]
def sCdc25 := litS "PMID:17480229/Cdc25" "Cdc25 activates CDK1" cdc25c .pos (.activity cdk1)
  [paper 17480229 2007 .review "inhibit the activators and activate the inhibitors of mitosis, Cdc25 and Wee1, respectively"]
def b_cdk1 : OpposesAt cdc25c wee1 (.activity cdk1) := ⟨.lit sCdc25, .lit sWee1⟩
def oppWC : OStatement := ⟨"SYNTHETIC/Wee1-Cdc25", "Wee1 opposes Cdc25", .opposes wee1 cdc25c,
  [paper 17480229 2007 .review "Cdc25 and Wee1: analogous opposites? (title)"]⟩
def cWee1 : ODeriv (.core sWee1.claim) := .flip (.olit oppWC) (.core (.lit sCdc25))

/-- Maehama 1998 (PMID 9593664): PTEN dephosphorylates PIP3; PI3K makes it (insulin-induced). -/
def sPI3K := litS "PMID:9593664/PI3K" "PI3K raises PIP3" pi3k .pos (.amount pip3)
  [paper 9593664 1998 .inVitro "reduced insulin-induced PtdIns(3,4,5)P3 production ... without effecting insulin-induced phosphoinositide 3-kinase activation"]
def sPTEN := litS "PMID:9593664/PTEN" "PTEN lowers PIP3" pten .neg (.amount pip3)
  [paper 9593664 1998 .inVitro "Purified recombinant PTEN catalyzed dephosphorylation of PtdIns(3,4,5)P3"]
def b_pip3 : OpposesAt pi3k pten (.amount pip3) := ⟨.lit sPI3K, .lit sPTEN⟩
def oppPP : OStatement := ⟨"SYNTHETIC/PTEN-PI3K", "PTEN opposes PI3K", .opposes pten pi3k,
  [paper 9593664 1998 .inVitro "Purified recombinant PTEN catalyzed dephosphorylation of PtdIns(3,4,5)P3"]⟩
def cPTEN : ODeriv (.core sPTEN.claim) := .flip (.olit oppPP) (.core (.lit sPI3K))

/-! ### Plant hormones -/

/-- Müller and Leyser 2011 (PMID 21504914): "auxin inhibits the activation of axillary buds, and hence
shoot branching, while cytokinin has the opposite effect." -/
def sAuxBud := litS "PMID:21504914/auxin" "auxin inhibits shoot branching" auxin .neg (.process secondaryShoot)
  [paper 21504914 2011 .review "auxin inhibits the activation of axillary buds, and hence shoot branching"]
def sCkBud := litS "PMID:21504914/cytokinin" "cytokinin promotes shoot branching" cytokinin .pos (.process secondaryShoot)
  [paper 21504914 2011 .review "while cytokinin has the opposite effect"]
def b_bud : OpposesAt cytokinin auxin (.process secondaryShoot) := ⟨.lit sCkBud, .lit sAuxBud⟩
def oppAC : OStatement := ⟨"SYNTHETIC/auxin-cytokinin", "auxin opposes cytokinin", .opposes auxin cytokinin,
  [paper 21504914 2011 .review "cytokinin has the opposite effect"]⟩
def cBud : ODeriv (.core sAuxBud.claim) := .flip (.olit oppAC) (.core (.lit sCkBud))
/-- Cytokinin promotes cell division (ChEBI's definition of CHEBI:23530). (c) then says auxin lowers
it; Dello Ioio 2008 (PMID 19039136): "auxin mediates degradation of the SHY2 protein, sustaining PIN
activities and cell division". -/
def sCkDiv := litS "CHEBI:23530/def" "cytokinin promotes cell division" cytokinin .pos (.process cellDivision)
  [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "CHEBI:23530: A phytohormone that promote cell division" }]
def cAuxDiv : ODeriv (.core (.effect auxin .neg (.process cellDivision))) := .flip (.olit oppAC) (.core (.lit sCkDiv))
/-- Root meristem (Dello Ioio 2008): cytokinin promotes differentiation, auxin sustains division, so
at root meristem growth they oppose: cytokinin lowers it. (c) from auxin raises gives that. -/
def sAuxRoot := litS "PMID:19039136/auxin" "auxin sustains root meristem growth" auxin .pos (.process rootMeristemGrowth)
  [paper 19039136 2008 .mechanistic "auxin mediates degradation of the SHY2 protein, sustaining PIN activities and cell division"]
def cCkRoot : ODeriv (.core (.effect cytokinin .neg (.process rootMeristemGrowth))) := .flip (.symm (.olit oppAC)) (.core (.lit sAuxRoot))

/-! ### Neurotransmitters -/

def oppGG : OStatement := ⟨"SYNTHETIC/GABA-glutamate", "GABA opposes glutamate", .opposes gaba glutamate,
  [paper 12209121 2002 .review "a mismatch between GABA-mediated inhibition and glutamatergic excitation"]⟩
/-- In adult neurons glutamate depolarises (Ben-Ari 2002, PMID 12209121). -/
def sGluAdult := litS "PMID:12209121/glu-adult" "glutamate depolarises adult neurons" glutamate .pos
  (.process (depolarization.inCtx { cellType := e_CL_0000540, lifeStage := adultStage }))
  [paper 12209121 2002 .review "glutamatergic excitation"]
def cGabaAdult : ODeriv (.core (.effect gaba .neg (.process (depolarization.inCtx { cellType := e_CL_0000540, lifeStage := adultStage })))) :=
  .flip (.olit oppGG) (.core (.lit sGluAdult))
/-- In neonatal neurons too glutamate depolarises; (c) then says GABA does not, which is wrong:
"In the immature brain, GABA (gamma-aminobutyric acid) is excitatory". -/
def sGluNeo := litS "PMID:12209121/glu-neonate" "glutamate depolarises neonatal neurons" glutamate .pos
  (.process (depolarization.inCtx { cellType := e_CL_0000540, lifeStage := neonate }))
  [paper 12209121 2002 .review "glutamatergic contacts"]
def cGabaNeo : ODeriv (.core (.effect gaba .neg (.process (depolarization.inCtx { cellType := e_CL_0000540, lifeStage := neonate })))) :=
  .flip (.olit oppGG) (.core (.lit sGluNeo))
/-- Glutamate is the substrate of GABA synthesis (GO:0004351: L-glutamate = 4-aminobutanoate + CO2),
so glutamate raises GABA. (c) then says GABA lowers GABA. -/
def sGluGaba := litS "GO:0004351/def" "glutamate raises GABA (substrate of glutamate decarboxylase)" glutamate .pos (.amount gaba)
  [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "GO:0004351: L-glutamate = 4-aminobutanoate + CO2" }]
def cGabaSelf : ODeriv (.core (.effect gaba .neg (.amount gaba))) := .flip (.olit oppGG) (.core (.lit sGluGaba))

/-! ### The holes search's own reading: opposition as "lowers the amount of"

Svendsen 2018 (PMID 30380405): "glucagon stimulates insulin secretion". So reading "glucagon opposes
insulin" as "glucagon lowers the amount of insulin" is false for this pair, even where its chained
conclusion is true. Shown in the stress file against today's core. -/
def sGlucagonInsulin := litS "PMID:30380405" "glucagon raises insulin secretion" e_PR_P01275 .pos (.amount e_PR_000009054)
  [paper 30380405 2018 .mechanistic "We found that glucagon stimulates insulin secretion through both Gcgr and GLP-1R"]

/-! ### SYNTHETIC edge case: self-opposition

Nothing in `ODeriv` stops `opposes a a`. With it, `flip` turns any effect of `a` into its opposite:
here naloxone both lowers and raises mu receptor activity. A guard `a ≠ b` would be needed. -/
def oppSelf : OStatement := ⟨"SYNTHETIC/self", "naloxone opposes naloxone", .opposes naloxone naloxone,
  [tb "SYNTHETIC: a mis-annotation"]⟩
def cSelf : ODeriv (.core (.effect naloxone .pos (.activity mor))) := .flip (.olit oppSelf) (.core (.lit sNalMOR))

/-! ## Option (e): counter-regulation tied to `Claim.homeostasis` -/

/-- Two regulators of one held quantity, each named in a loop, with opposite arms on it. -/
structure CounterReg {k₁ k₂ : Kind} (a : Entity k₁) (b : Entity k₂) (held : Target) where
  loopA : Derivation (.homeostasis a held)
  loopB : Derivation (.homeostasis b held)
  opp : OpposesAt a b held

abbrev bloodGlucose : Target := .amount (e_CHEBI_17234.inCtx { anatomy := e_UBERON_0000178 })
abbrev bloodCalcium : Target := .amount (e_CHEBI_29108.inCtx { anatomy := e_UBERON_0000178 })

/-- Loop annotations of real sentences (mine): m45537-333 and the book's negative feedback for blood
glucose; calcium as for `Claim.homeostasis`'s own docstring (calcitonin and PTH and blood calcium). -/
def loop {k : Kind} (id : String) (r : Entity k) (held : Target) (note : String) : Statement :=
  ⟨id, s!"{r.label} holds a quantity near a set point", .homeostasis r held, [tb note]⟩
def loopIns := loop "the-body-s-systems-m45537-333/insulin" e_PR_000009054 bloodGlucose "Blood-glucose levels are regulated by hormones produced by the pancreas: insulin and glucagon."
def loopGlc := loop "the-body-s-systems-m45537-333/glucagon" e_PR_P01275 bloodGlucose "Blood-glucose levels are regulated by hormones produced by the pancreas: insulin and glucagon."
def loopPTH := loop "SYNTHETIC/loop-PTH" e_PR_000013429 bloodCalcium "SYNTHETIC: PTH raises blood calcium when it falls (m45537-140)"
def loopCT := loop "SYNTHETIC/loop-CT" e_PR_P01258 bloodCalcium "SYNTHETIC: calcitonin lowers rising blood calcium (m45537-134, -135)"

def e_glucose : CounterReg e_PR_P01275 e_PR_000009054 bloodGlucose :=
  ⟨.lit loopGlc, .lit loopIns, ⟨.lit s201, .lit s53⟩⟩
def e_calcium : CounterReg e_PR_000013429 e_PR_P01258 bloodCalcium :=
  ⟨.lit loopPTH, .lit loopCT, ⟨.lit s140, .lit s135⟩⟩

/-- (e) as data: an agent pair from (b) passes if both agents have a loop on that very target. -/
def loopsOn (loops : List Statement) (agent tk : String) : Bool :=
  loops.any fun s => match s.claim with
    | .homeostasis r h => r.curie == agent && tkey h == tk
    | _ => false

def ePass (loops : List Statement) : List (Eff × Eff) :=
  bPairs.filter fun (x, y) => loopsOn loops x.agent x.tk && loopsOn loops y.agent y.tk

/-- Today: the library has no homeostasis claims; the one in `Examples/Homeostasis` is on
`amount glucose`, not blood glucose, so it matches nothing. -/
def libLoops : List Statement := library.filter fun s => match s.claim with | .homeostasis .. => true | _ => false
#guard libLoops.length = 0
#guard (ePass [BioLean.Homeostasis.S_loop]).length = 0
-- With the four loop annotations: insulin/glucagon (2 statement pairs) and PTH/calcitonin (1). The
-- coincidental pairs (K+/Na+ at aldosterone, sympathetic/ANP at blood pressure) are filtered out.
-- This is by construction: I annotated loops only for those two pairs. E5 is the real test.
#guard (ePass [loopIns, loopGlc, loopPTH, loopCT]).length = 3

/-! ## Option (d): ChEBI receptor roles as signed effects -/

/-- ChEBI roles name the receptor only in their label; the link to the PR receptor is mine. -/
def roleBridge : List (String × String × Sign) :=
  [("CHEBI:50137", "PR:000001612", .neg),   -- mu-opioid receptor antagonist
   ("CHEBI:55322", "PR:000001612", .pos)]   -- mu-opioid receptor agonist

/-- The roles OLS4 lists for naloxone and morphine (has_role, 2026-10-31), as data. -/
def chebiRoles : List (String × String) :=
  [("CHEBI:7459", "CHEBI:35488"), ("CHEBI:7459", "CHEBI:50137"), ("CHEBI:7459", "CHEBI:90755"),
   ("CHEBI:17303", "CHEBI:176497"), ("CHEBI:17303", "CHEBI:35482"), ("CHEBI:17303", "CHEBI:35620"),
   ("CHEBI:17303", "CHEBI:35703"), ("CHEBI:17303", "CHEBI:38867"), ("CHEBI:17303", "CHEBI:55322"),
   ("CHEBI:17303", "CHEBI:76924"), ("CHEBI:17303", "CHEBI:78298"), ("CHEBI:17303", "CHEBI:88188")]

def bridged : List (String × String × Sign) :=
  chebiRoles.filterMap fun (drug, role) =>
    (roleBridge.find? (·.1 == role)).map fun (_, rec, s) => (drug, rec, s)
#guard bridged = [("CHEBI:7459", "PR:000001612", .neg), ("CHEBI:17303", "PR:000001612", .pos)]
-- Naloxone's role list includes "central nervous system depressant" (CHEBI:35488).
#guard chebiRoles.contains ("CHEBI:7459", "CHEBI:35488")

/-! ## Option (g): an interaction target, "a lowers the effect of b on t" -/

/-- The core's targets plus the effect of an agent on a target. -/
inductive ITarget
  | base (t : Target)
  | effectOf {k : Kind} (agent : Entity k) (sign : Sign) (t : Target)

structure IStatement where
  id : String
  agentCurie : String
  sign : Sign
  target : ITarget
  evidence : List Evidence

def iNalMor : IStatement := ⟨"PMID:20461002", naloxone.curie, .neg, .effectOf morphine .neg (.process breathing),
  [paper 20461002 2010 .rct "Opioid-induced respiratory depression is antagonized effectively by the competitive opioid receptor antagonist naloxone"]⟩
def iAnpAvp : IStatement := ⟨"PMID:3006248", e_PR_P01160.curie, .neg, .effectOf argipressin .pos (.process renalWater),
  [paper 3006248 1986 .inVitro "Atriopeptin III inhibition of the hydraulic conductivity response to the hormone arginine vasopressin"]⟩
/-- Accentuated antagonism, Uijtdehaage 2000 (PMID 10954067): "vagal effects became progressively
stronger with increasing sympathetic background activity". -/
def iAccent : IStatement := ⟨"PMID:10954067", symp.curie, .pos, .effectOf para .neg (.phenotype e_OBA_1001087),
  [paper 10954067 2000 .observational "vagal effects became progressively stronger with increasing sympathetic background activity"]⟩

/-- H06 under (c): stated as `opposes ANP argipressin`, (c) flips "vasopressin raises renal water
absorption" into "ANP lowers renal water absorption": right in sign (ANP is diuretic), but the
interaction (ANP acts on vasopressin's effect) is lost. -/
def sAvpWater := litS "PMID:3006248/AVP" "vasopressin raises renal water absorption" argipressin .pos (.process renalWater)
  [paper 3006248 1986 .inVitro "vasopressin-stimulated water transport"]
def oppAV : OStatement := ⟨"SYNTHETIC/ANP-AVP", "ANP opposes vasopressin", .opposes e_PR_P01160 argipressin,
  [paper 3006248 1986 .inVitro "Inhibition of vasopressin action by atrial natriuretic factor (title)"]⟩
def cAnpWater : ODeriv (.core (.effect e_PR_P01160 .neg (.process renalWater))) := .flip (.olit oppAV) (.core (.lit sAvpWater))

/-! ## Option (h): opposite targets -/

/-- RO:0002604 "is opposite of" is an annotation property, not imported into `RO.lean`. A pair of
opposite processes, as data. -/
def opposite : List (String × String) := [("process:GO:0006939", "process:GO:0044557")]
def oppositeKey (tk : String) : Option String :=
  -- strip a context suffix, compare on the base process
  let base := (tk.takeWhile (· != '&')).toString
  (opposite.find? (·.1 == base)).map (·.2) <|> (opposite.find? (·.2 == base)).map (·.1)

/-- (b) widened by (h): a raises P, b raises Q, P opposite Q, same context suffix. -/
def hPairs : List (Eff × Eff) :=
  effs.flatMap fun e₁ => if e₁.sign = .pos then
    (effs.filter fun e₂ => e₂.sign = .pos && e₂.agent != e₁.agent &&
      (oppositeKey e₁.tk).isSome && (oppositeKey e₁.tk) == some ((e₂.tk.takeWhile (· != '&')).toString) &&
      (e₁.tk.dropWhile (· != '&')).toString == (e₂.tk.dropWhile (· != '&')).toString).map (e₁, ·) else []

def s60 := TheBodySSystemsA.the_body_s_systems_m45536_60
def s61 := TheBodySSystemsA.the_body_s_systems_m45536_61

/-! ## The `amount` typing hole, measured

How many library effects use `Target.amount`, and on which kinds. 75 in all: 55 chemicals and 9
proteins; the other 11 (taxa, anatomy, a cell type, components) are sensible amounts, so a kind-level
restriction to molecules would break them (see the lint T22 in the stress file). -/
def kindName : Kind → String
  | .chemical => "chemical" | .protein => "protein" | .gene => "gene" | .process => "process"
  | .function => "function" | .phenotype => "phenotype" | .disease => "disease" | .anatomy => "anatomy"
  | .cellType => "cellType" | .component => "component" | .taxon => "taxon"
def amountKind : Claim → Option String
  | .effect _ _ (.amount (k := k) _) => some (kindName k)
  | .mediatedBy _ _ (.amount (k := k) _) _ => some (kindName k)
  | _ => none
def amountKinds : List String := library.filterMap (amountKind ·.claim)
#guard amountKinds.length = 75
#guard (amountKinds.filter (· ∈ ["chemical", "protein"])).length = 64

/-- The amount lint of the stress file (T22), repeated here because a new file cannot import another:
anatomy must be is_a UBERON:0000463 organism substance; a process, phenotype, function or disease
has no amount. Run over every library amount: none is refused. -/
def amountLint {k : Kind} (e : Entity k) : Bool :=
  match k with
  | .anatomy => Ontology.isACurie (Ctx.baseCurie e.curie) "UBERON:0000463"
  | .process | .phenotype | .function | .disease => false
  | _ => true
def lintOK : Claim → Bool
  | .effect _ _ (.amount m) => amountLint m
  | .mediatedBy _ _ (.amount m) _ => amountLint m
  | _ => true
#guard (library.filter (!lintOK ·.claim)).length = 0
#guard !lintOK (.effect para .neg (.amount symp)) && !lintOK (.effect symp .neg (.amount para))

/-! ## Observed results -/

def concl (c : Concl) : String := s!"{c.alabel} [{c.agent}] {sgn c.sign} {c.tstr} (from {c.fromId}, agent {c.fromAgent}): {c.kind}"

#eval show IO Unit from do
  obs "PROTO-b-scan" s!"{bPairs.length} statement pairs, {bAgentPairs.length} agent pairs act with opposite signs on one target; {antagonistPairs.length} are real (6 antagonist pairs, 1 inhibitor and its enzyme; my reading)"
  for (x, y) in bPairs do
    IO.println s!"BPAIR\t{x.agent}\t{x.alabel}\t{x.id}\t{y.agent}\t{y.alabel}\t{y.id}\t{x.tstr}"
  obs "PROTO-b-six" s!"(b) needs both sentences: b_hr rests on {b_hr.axioms.map (·.id)}; belief {b_hr.opinion.belief.toDecimal}; 0 of 6 become theorems"
  obs "PROTO-c-six" s!"(c) derives 299, 300, 306, 307, 308, 371 from their mirrors and m45539-296; c306 {ostr c306.opinion}; fused with stated 306 {ostr (ODeriv.both c306 (.core (.lit s306))).opinion}"
  obs "PROTO-c-skin" s!"(c) derives m45539-377 'parasympathetic raises skin blood flow' from 373: {ostr c377.opinion}, axioms {c377.axioms}"
  obs "PROTO-c-book" s!"(c) with the 3 book pairs: {cBook.length} conclusions, theorem {count "theorem" cBook}, clash {count "clash" cBook}, new {count "new" cBook}"
  for c in cBook do IO.println s!"CBOOK\t{concl c}"
  obs "PROTO-c-all" s!"(c) with all 50 (b) pairs promoted: {cAll.length} conclusions, theorem {count "theorem" cAll}, clash {count "clash" cAll}, new {count "new" cAll}"
  for c in cAll.filter (·.kind == "new") do IO.println s!"CNEW\t{concl c}"
  obs "PROTO-f-book" s!"(f) with opposesAt at heart rate, blood pressure, digestion: theorem {count "theorem" fBook}, clash {count "clash" fBook}, new {count "new" fBook}; f306 {ostr f306.opinion}"
  obs "PROTO-f-circular" s!"(f) annotated from the 306-308 sentence: f306 rests on {f306.axioms}; f299 rests on {f299.axioms} (one sentence); f306 fused with stated 306 {ostr (ODeriv.both f306 (.core (.lit s306))).opinion}, distinct ids {((ODeriv.both f306 (.core (.lit s306))).axioms.eraseDups.length)}"
  obs "PROTO-f-skin" s!"(f) annotated from the 374-377 sentence derives m45539-377 'parasympathetic raises skin blood flow' from 373: {ostr f377.opinion}"
  obs "PROTO-c-thermo" s!"(c) derives 'parasympathetic lowers temperature homeostasis' from m45534-81: {ostr cThermo.opinion}"
  obs "PROTO-c-sweat" s!"(c) derives 'parasympathetic lowers sweat secretion': {ostr cSweat.opinion}"
  obs "PROTO-c-adrenal" s!"(c) derives 'parasympathetic lowers adrenal epinephrine secretion': {ostr cAdrenal.opinion}"
  obs "PROTO-c-saliva" s!"(c) derives 'sympathetic lowers saliva secretion' {ostr cSaliva.opinion}; against the stated sympathetic secretion: {ostr salivaClash} = {repr salivaClash.verdict}"
  obs "PROTO-c-pupil" s!"(c) derives 'parasympathetic lowers pupil diameter': {ostr cPupil.opinion}"
  obs "PROTO-c-LV" s!"(c) derives 'parasympathetic lowers left ventricular contraction': {ostr cLV.opinion}"
  obs "PROTO-c-glucose" s!"(c) derives m45537-53 'insulin lowers blood glucose' from 201: {ostr c53.opinion}"
  obs "PROTO-c-import" s!"(c) derives 'glucagon lowers glucose import' from m45537-202: {ostr cImport.opinion}"
  obs "PROTO-c-calcium" s!"(c) derives m45537-135 'calcitonin lowers blood calcium' from 140: {ostr c135.opinion}"
  obs "PROTO-c-calcitriol" s!"(c) derives 'calcitonin lowers calcitriol' {ostr cCalcitriol.opinion}; against Felsenfeld and Shinki: {ostr calcitriolClash} = {repr calcitriolClash.verdict}"
  obs "PROTO-c-glycolysis" s!"(c) on promoted (insulin, epinephrine) derives 'insulin lowers glycolysis in skeletal muscle' from m45537-182: {ostr cGlycolysis.opinion}"
  obs "PROTO-c-lipolysis" s!"(c) on the same pair derives 'insulin lowers lipolysis in adipose tissue' from m45537-183: {ostr cLipolysis.opinion}"
  obs "PROTO-c-ANP" s!"(c) on promoted (symp, ANP): 'symp raises blood Na+' {ostr cNa1.opinion}; twice: 'para lowers blood Na+' {ostr cNa2.opinion}, axioms {cNa2.axioms}; 'ANP raises digestion' {ostr cDigANP.opinion}"
  obs "PROTO-b-mor" s!"(b) at mu receptor activity from ChEMBL mechanisms: {ostr b_mor.opinion}"
  obs "PROTO-c-pain" s!"(c) derives 'naloxone raises pain perception' {ostr cNalPain.opinion}; El-Sobky 1976 states noEffect: {sNalPainNull.claim}"
  obs "PROTO-c-histamine" s!"(c) derives 'naloxone lowers mast cell histamine release' {ostr cNalHist.opinion}"
  obs "PROTO-c-mor" s!"(c) derives ChEMBL's 'naloxone lowers mu receptor activity' from morphine's agonism: {ostr cNalMOR.opinion}"
  obs "PROTO-c-breath" s!"(c) derives 'naloxone raises breathing' as a plain effect from 'morphine lowers breathing': {ostr cNalBreath.opinion}"
  obs "PROTO-c-water" s!"(c) with opposes(ANP, vasopressin) derives 'ANP lowers renal water absorption': {ostr cAnpWater.opinion}"
  obs "PROTO-b-cdk1" s!"(b) Cdc25 and Wee1 at CDK1 activity {ostr b_cdk1.opinion}; (c) gives Wee1 inhibits CDK1 as a theorem {ostr cWee1.opinion}"
  obs "PROTO-b-pip3" s!"(b) PI3K and PTEN at PIP3 {ostr b_pip3.opinion}; (c) gives 'PTEN lowers PIP3' as a theorem {ostr cPTEN.opinion}"
  obs "PROTO-b-bud" s!"(b) cytokinin and auxin at shoot branching {ostr b_bud.opinion}; (c) theorem {ostr cBud.opinion}"
  obs "PROTO-c-division" s!"(c) derives 'auxin lowers cell division' from ChEBI's cytokinin definition {ostr cAuxDiv.opinion}"
  obs "PROTO-c-root" s!"(c) derives 'cytokinin lowers root meristem growth' {ostr cCkRoot.opinion}"
  obs "PROTO-c-gaba" s!"(c) adult: 'GABA lowers depolarisation' {ostr cGabaAdult.opinion}; neonate: same {ostr cGabaNeo.opinion}; 'GABA lowers GABA' {ostr cGabaSelf.opinion}"
  obs "PROTO-c-self" s!"(c) accepts 'naloxone opposes naloxone' and turns 'naloxone lowers mu receptor activity' into 'naloxone raises mu receptor activity' {ostr cSelf.opinion}"
  obs "PROTO-e" s!"(e) loops in library {libLoops.length}; with Examples/Homeostasis S_loop {(ePass [BioLean.Homeostasis.S_loop]).length} pairs; with 4 loop annotations {(ePass [loopIns, loopGlc, loopPTH, loopCT]).length} pairs: {(ePass [loopIns, loopGlc, loopPTH, loopCT]).map fun (x, y) => (x.alabel, y.alabel)}"
  obs "PROTO-e-glucose" s!"(e) CounterReg glucagon/insulin at blood glucose: loops {e_glucose.loopA.opinion.belief.toDecimal}, opposition {ostr e_glucose.opp.opinion}"
  obs "PROTO-d" s!"(d) ChEBI roles bridged to receptor effects: {bridged.length} of {chebiRoles.length} roles; naloxone also has role CHEBI:35488 'central nervous system depressant'"
  obs "PROTO-g" s!"(g) states: naloxone lowers morphine's effect on breathing; ANP lowers argipressin's effect on renal water absorption; sympathetic activity raises the vagal effect on heart rate ({[iNalMor, iAnpAvp, iAccent].length} interaction claims)"
  obs "PROTO-amount" s!"amount targets in the library: {amountKinds.length}; by kind {amountKinds.eraseDups.map fun k => (k, amountKinds.count k)}; refused by the amount lint: {(library.filter (!lintOK ·.claim)).length} of {library.length} statements; the two hole statements refused: {!lintOK (.effect para .neg (.amount symp)) && !lintOK (.effect symp .neg (.amount para))}; CT statement alone {ostr (Derivation.lit sCTcalcitriol).opinion}"
  obs "PROTO-h" s!"(h) with contraction opposite relaxation: {hPairs.length} pair(s): {hPairs.map fun (x, y) => (x.alabel, x.id, y.alabel, y.id)}"

/-! ## Pins of the counts printed above -/

#guard (cAll.filter (·.kind == "new")).length = 106
#guard hPairs.length = 2
#guard (ePass [loopIns, loopGlc, loopPTH, loopCT]).all fun (x, y) =>
  (x.agent, y.agent) ∈ [("PR:P01275", "PR:000009054"), ("PR:000013429", "PR:P01258")]
theorem c377_belief : c377.opinion.belief = 4 / 5 := by decide +kernel
theorem cNa2_belief : cNa2.opinion.belief = 4 / 5 := by decide +kernel
theorem saliva_contested : salivaClash.verdict = .contested := by decide +kernel
#guard calcitriolClash.verdict = .unsupported
#guard cNalBreath.opinion.belief == 4 / 5 && cNalMOR.opinion.belief == 4 / 5
#guard cAnpWater.opinion.belief == 1 / 2 && cPTEN.opinion.belief == 1 / 2

end BioLean.Proto.Opposes
