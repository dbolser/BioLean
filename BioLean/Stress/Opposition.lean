import BioLean.Derivation
import BioLean.Examples.Homeostasis
import BioLean.Lib.TextbookClaimsR2.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR3.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsB

/-!
# Stress set 06: "opposes", against today's core

Program 06 (`docs/programs/06-opposition.md`). Every case here uses the current core only
(`BioLean/*.lean`), the built textbook libraries R2 and R3, and `Examples/Homeostasis`. Nothing here
changes the core. The prototypes of options (b) to (h) are in `BioLean/Proto/Opposes.lean`. The
table is `data/stress/06/cases.tsv`, written by `scripts/stress/opposes_cases.py` from the `OBS`
lines this file and the prototype print.

Pins: `#guard`, `example`, `theorem ... := by decide +kernel`, and `#no_lean` (no R2 or R3
statement for that sentence). If a later change to the core or the libraries flips a behaviour, a
pin breaks. Marks: PASS right conclusion; FAIL wrong conclusion; SILENT no conclusion where one is
due; INEXPRESSIBLE the core cannot state it. SYNTHETIC marks a statement I wrote.
-/

namespace BioLean.Stress.Opposition
open BioLean Derivation BioLean.Textbook.R2 BioLean.Textbook.R3

def obs (id msg : String) : IO Unit := IO.println s!"OBS\t{id}\t{msg}"
def tb (note : String) : Evidence := { pmid := 0, year := 2013, kind := .textbook, note := note }
def paper (pmid year : Nat) (k : EvidenceKind) (note : String) : Evidence :=
  { pmid := pmid, year := year, kind := k, note := note }
def ostr (o : Opinion) : String :=
  s!"b={o.belief.toDecimal} d={o.disbelief.toDecimal} u={o.uncertainty.toDecimal}"

/-! ## What the core can say -/

/-- The shape of a claim. No wildcard on purpose: a new constructor (an `opposes`) makes this file
fail to compile, which flips every INEXPRESSIBLE pin below at once. -/
def shape : Claim → String
  | .effect .. => "effect" | .mediatedBy .. => "mediatedBy" | .noEffect .. => "noEffect"
  | .rel .. => "rel" | .notRel .. => "notRel" | .count .. => "count" | .atLeast .. => "atLeast"
  | .countBetween .. => "countBetween" | .cardinality .. => "cardinality" | .measure .. => "measure"
  | .atLeastMeasure .. => "atLeastMeasure" | .less .. => "less" | .produces .. => "produces"
  | .consumes .. => "consumes" | .yield .. => "yield" | .homeostasis .. => "homeostasis"
  | .quant _ c => s!"quant {shape c}"

/-- The kinds of target. No wildcard: a target "the effect of b on t" (option g) breaks this. -/
def targetShape : Target → String
  | .activity .. => "activity" | .amount .. => "amount" | .process .. => "process"
  | .phenotype .. => "phenotype" | .site .. => "site"

/-- The rules. No wildcard: a rule that takes two agents (option c's `flip`) breaks this. The only
rules whose conclusion has a different agent from a premise's are `viaActivity` and `viaAmount`
(the agent acts on the other's activity or amount) and `isaInheritEffect` (an is_a link). -/
def ruleName {c : Claim} : Derivation c → String
  | .lit .. => "lit" | .viaActivity .. => "viaActivity" | .viaAmount .. => "viaAmount" | .both .. => "both"
  | .relChain .. => "relChain" | .sequencesOver .. => "sequencesOver" | .pigeonhole .. => "pigeonhole"
  | .perSet .. => "perSet" | .fusionAdds .. => "fusionAdds" | .netYield .. => "netYield"
  | .compareIntervals .. => "compareIntervals" | .weaken .. => "weaken" | .notRelSub .. => "notRelSub"
  | .notRelObj .. => "notRelObj" | .refineMono .. => "refineMono" | .isaInheritEffect .. => "isaInheritEffect"
  | .transport .. => "transport" | .generalize .. => "generalize"

def chapters : List Lean.Name :=
  [`CellStructureAndFunction, `HowCellsObtainEnergy, `MolecularBiology, `Photosynthesis,
   `ReproductionAtTheCellularLevel, `TheBodySSystemsA, `TheBodySSystemsB, `TheCellularBasisOfInheritance]

open Lean Elab Command in
/-- `#no_lean Chapter name`: neither R2 nor R3 has a statement `name` in an imported chapter module;
fails if the chapter is not imported in both rounds, so a typo cannot pass. -/
elab "#no_lean " m:ident n:ident : command => do
  let env ← getEnv
  for pre in [`BioLean.Textbook.R2, `BioLean.Textbook.R3] do
    unless env.isNamespace (pre ++ m.getId) do throwError "{pre ++ m.getId} is not imported"
    for c in chapters do
      if env.contains (pre ++ c ++ n.getId) then
        throwError "{pre ++ c ++ n.getId} exists: the record now has Lean"

abbrev symp := e_UBERON_0000013
abbrev para := e_UBERON_0000011
def s295 := TheBodySSystemsB.the_body_s_systems_m45539_295
def s299 := TheBodySSystemsB.the_body_s_systems_m45539_299
def s300 := TheBodySSystemsB.the_body_s_systems_m45539_300
def s371 := TheBodySSystemsB.the_body_s_systems_m45539_371
def s306 := TheBodySSystemsB.the_body_s_systems_m45539_306
def s307 := TheBodySSystemsB.the_body_s_systems_m45539_307
def s308 := TheBodySSystemsB.the_body_s_systems_m45539_308
def s373 := TheBodySSystemsB.the_body_s_systems_m45539_373
def s377 := TheBodySSystemsB.the_body_s_systems_m45539_377
def s81 := TheBodySSystemsA.the_body_s_systems_m45534_81
def s60 := TheBodySSystemsA.the_body_s_systems_m45536_60
def s61 := TheBodySSystemsA.the_body_s_systems_m45536_61
def s53 := TheBodySSystemsB.the_body_s_systems_m45537_53
def s201 := TheBodySSystemsB.the_body_s_systems_m45537_201
def s202 := TheBodySSystemsB.the_body_s_systems_m45537_202
def s135 := TheBodySSystemsB.the_body_s_systems_m45537_135
def s140 := TheBodySSystemsB.the_body_s_systems_m45537_140
def s153 := TheBodySSystemsB.the_body_s_systems_m45537_153
def s156 := TheBodySSystemsB.the_body_s_systems_m45537_156
def s244 := HowCellsObtainEnergy.how_cells_obtain_energy_m45437_244
def s248 := BioLean.Textbook.R3.HowCellsObtainEnergy.how_cells_obtain_energy_m45437_248   -- R3 supersedes R2

/-! ## T01. The opposition sentence itself

`the-body-s-systems-m45539-296` "...two divisions of the autonomic nervous system that often have
opposing effects" has no Lean in R1 to R3 (bin `missing_construct`); its neighbour -295 kept only
"the autonomic nervous system has part the sympathetic system". INEXPRESSIBLE. -/
#no_lean TheBodySSystemsB the_body_s_systems_m45539_296
#guard shape s295.claim = "rel"
def coreShapes : List String :=
  ["effect", "mediatedBy", "noEffect", "rel", "notRel", "count", "atLeast", "countBetween",
   "cardinality", "measure", "atLeastMeasure", "less", "produces", "consumes", "yield", "homeostasis", "quant"]
#guard coreShapes.length = 17 ∧ !coreShapes.contains "opposes"

/-! ## T02. The hormone opposition sentences: m45537-331 ("opposing hormone actions") and -333
("insulin and glucagon") have no Lean. INEXPRESSIBLE. -/
#no_lean TheBodySSystemsB the_body_s_systems_m45537_331
#no_lean TheBodySSystemsB the_body_s_systems_m45537_333

/-! ## T03 to T05. The six hole sentences, as axioms

Today each is its own axiom at textbook strength, and the effects already state the antagonism per
effector (option a). Nothing derives one from its mirror: no rule takes two agents, and the two
branches are not is_a related in UBERON. -/
#guard [s299, s300, s371, s306, s307, s308].all fun s => shape s.claim = "effect"
theorem s306_lit : (Derivation.lit s306).opinion.belief = 4 / 5 := by decide +kernel
#guard !Ontology.isACurie para.curie symp.curie && !Ontology.isACurie symp.curie para.curie

/-! ## T06. The hole search's typing: "the parasympathetic system lowers the amount of the
sympathetic system" (docs/holes.md row 1) is accepted by the core, because `Target.amount` takes an
entity of any kind. With it, `viaAmount` derives the six sentences, and also the false one about
skin blood flow and a false one about temperature homeostasis. So the hole is rule (c) in disguise,
and the core already admits it. FAIL. -/
def holePara : Statement :=
  ⟨"holes:row1", "parasympathetic nervous system lowers the amount of sympathetic nervous system",
   .effect para .neg (.amount symp), [tb "SYNTHETIC: hole search hypothesis, docs/holes.md row 1"]⟩
def holeSymp : Statement :=
  ⟨"holes:row2", "sympathetic nervous system lowers the amount of parasympathetic nervous system",
   .effect symp .neg (.amount para), [tb "SYNTHETIC: hole search hypothesis, docs/holes.md row 2"]⟩
#guard targetShape (.amount symp) = "amount"

def h306 : Derivation s306.claim := .viaAmount (.lit holePara) (.lit s299)
def h307 : Derivation s307.claim := .viaAmount (.lit holePara) (.lit s371)
def h308 : Derivation s308.claim := .viaAmount (.lit holePara) (.lit s300)
def h299 : Derivation s299.claim := .viaAmount (.lit holeSymp) (.lit s306)
def h371 : Derivation s371.claim := .viaAmount (.lit holeSymp) (.lit s307)
def h300 : Derivation s300.claim := .viaAmount (.lit holeSymp) (.lit s308)
def h377 : Derivation s377.claim := .viaAmount (.lit holePara) (.lit s373)
def hThermo : Derivation (.effect para .neg (.process e_GO_0001659)) := .viaAmount (.lit holePara) (.lit s81)
theorem h306_belief : h306.opinion.belief = 16 / 25 := by decide +kernel

/-! ## T07. The same typing for a hormone pair. "Glucagon lowers the amount of insulin" with R3
m45537-53 (insulin lowers blood glucose) derives m45537-201 (glucagon raises blood glucose): a true
conclusion from a false premise. Svendsen 2018 (PMID 30380405): "glucagon stimulates insulin
secretion". FAIL (premise). -/
def holeGlc : Statement :=
  ⟨"SYNTHETIC/hole-glucagon", "glucagon lowers the amount of insulin", .effect e_PR_P01275 .neg (.amount e_PR_000009054),
   [tb "SYNTHETIC: the hole-search reading of 'insulin and glucagon oppose'"]⟩
def svendsen : Statement :=
  ⟨"PMID:30380405", "glucagon raises insulin", .effect e_PR_P01275 .pos (.amount e_PR_000009054),
   [paper 30380405 2018 .mechanistic "We found that glucagon stimulates insulin secretion through both Gcgr and GLP-1R"]⟩
def hGlc : Derivation s201.claim := .viaAmount (.lit holeGlc) (.lit s53)

/-! ## T08 to T10. Per-effector antagonism the library already holds (option a)

Insulin and glucagon at blood glucose (R3 m45537-53, -201), calcitonin and PTH at blood calcium
(R3 -135, -140), ATP and ADP at glucose catabolism (R2 m45437-244, -248). The two effects of each
pair share a target exactly. PASS: the antagonism is stated per effector. -/
#guard match s53.claim, s201.claim with
  | .effect _ .neg t₁, .effect _ .pos t₂ => toString t₁ == toString t₂ | _, _ => false
#guard match s135.claim, s140.claim with
  | .effect _ .neg t₁, .effect _ .pos t₂ => toString t₁ == toString t₂ | _, _ => false
#guard match s244.claim, s248.claim with
  | .effect _ .neg t₁, .effect _ .pos t₂ => toString t₁ == toString t₂ | _, _ => false

/-! ## T11. Insulin's second effect in R2 (m45537-202, glucose import into cells) and glucagon's
(release from the liver) are on different targets, so nothing pairs them. Correct: the book's
picture is two effects on blood glucose. PASS (silent where nothing is due). -/
#guard match s202.claim with | .effect _ .pos (.process p) => p.curie == "GO:0098708" | _ => false

/-! ## T12. K+ and Na+ act on aldosterone with opposite signs (R3 m45537-153, -156). They are two
stimuli, not antagonists. Today nothing calls them opposed. PASS. -/
#guard match s153.claim, s156.claim with
  | .effect a .neg t₁, .effect b .pos t₂ => toString t₁ == toString t₂ && a.curie != b.curie | _, _ => false

/-! ## T13. Bronchi: R3 m45536-60 (parasympathetic raises smooth muscle contraction in bronchi) and
-61 (sympathetic raises relaxation of smooth muscle in bronchi). Opposite processes, both stated.
Nothing links contraction and relaxation. PASS for the two effects; the opposition is unstated. -/
#guard match s60.claim, s61.claim with
  | .effect _ .pos (.process p), .effect _ .pos (.process q) => p.curie != q.curie | _, _ => false

/-! ## T14. Feedback, not opposition: the one homeostasis claim (`Examples/Homeostasis`) is on
`amount glucose` with no blood context, while R3's arms are on glucose in blood. Glucagon has no
loop claim. So nothing ties the two hormones to one loop today. SILENT. -/
#guard match BioLean.Homeostasis.S_loop.claim, s53.claim with
  | .homeostasis _ h, .effect _ _ t => toString h != toString t | _, _ => false

/-! ## T15 to T17. Drugs at a receptor (literature and curated data)

Per-target effects are expressible: morphine raises, naloxone lowers mu receptor activity (ChEMBL
mechanisms CHEMBL70 agonist, CHEMBL80 antagonist). RO's own relations are expressible as `rel`
claims: RO:0018027 "is agonist of", RO:0018029 "is antagonist of". A neutral antagonist's
no-effect is expressible as `noEffect`. -/
def naloxone : Entity .chemical := ⟨"CHEBI:7459", "naloxone"⟩
def morphine : Entity .chemical := ⟨"CHEBI:17303", "morphine"⟩
def mor : Entity .protein := ⟨"PR:000001612", "mu-type opioid receptor"⟩
def painPerception : Entity .process := ⟨"GO:0019233", "sensory perception of pain"⟩
def biceps : Entity .anatomy := ⟨"UBERON:0001507", "biceps brachii"⟩
def triceps : Entity .anatomy := ⟨"UBERON:0001509", "triceps brachii"⟩
def isAgonistOf : Rel := ⟨.ro, 18027, false⟩
def isInverseAgonistOf : Rel := ⟨.ro, 18028, false⟩
def isAntagonistOf : Rel := ⟨.ro, 18029, false⟩
def hasMuscleAntagonist : Rel := ⟨.ro, 2568, false⟩

example : Claim := .effect morphine .pos (.activity mor)
example : Claim := .effect naloxone .neg (.activity mor)
example : Claim := .rel isAgonistOf morphine mor
example : Claim := .rel isAntagonistOf naloxone mor
example : Claim := .noEffect naloxone (.process painPerception)
#guard RO.labels.lookup isAntagonistOf = some "is antagonist of"
#guard RO.labels.lookup isAgonistOf = some "is agonist of"

/-! ## T18. The RO antagonism relations are inert: no imported chain, inverse or transitivity uses
them, so a `rel` claim with them derives nothing. And RO:0002604 "is opposite of" is an annotation
property, not imported. -/
def roUses (r : Rel) : Bool :=
  RO.chains.any (fun (ps, c) => c == r || ps.contains r) || RO.transitive.contains r ||
  RO.inverses.any (fun (x, y) => x == r || y == r)
#guard !roUses isAntagonistOf && !roUses isAgonistOf && !roUses isInverseAgonistOf && !roUses hasMuscleAntagonist
#guard RO.labels.lookup ⟨.ro, 2604, false⟩ = none

/-! ## T19. Antagonism between drugs is an interaction: "naloxone reverses morphine-induced
respiratory depression" (Olofsen 2010, PMID 20461002) is an effect on an effect. No target takes an
effect, so the interaction itself is INEXPRESSIBLE. -/
#guard [targetShape (.amount mor), targetShape (.activity mor), targetShape (.process painPerception)] =
  ["amount", "activity", "process"]

/-! ## T19b. But its content is expressible today as a conditional effect (M2 context,
`Ctx.condition` with RO:0002573 has_modifier): "naloxone, in humans given morphine, raises breathing"
(Olofsen 2010), and "ANP, in rabbits with vasopressin, lowers renal water absorption" (Dillingham
1986, PMID 3006248, rabbit collecting tubules). What is lost is the link to the agonist's own effect:
no rule relates the conditional claim to "morphine lowers breathing". PASS for D04 and H06 as
statements; option (g) would add the link, not the content. -/
def human : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def rabbit : Entity .taxon := ⟨"NCBITaxon:9986", "Oryctolagus cuniculus"⟩
def breathing : Entity .process := ⟨"GO:0007585", "respiratory gaseous exchange by respiratory system"⟩
def argipressin : Entity .chemical := ⟨"CHEBI:34543", "argipressin"⟩
def renalWater : Entity .process := ⟨"GO:0070295", "renal water absorption"⟩
def nalGivenMorphine : Claim :=
  .effect (naloxone.inCtx { taxon := some human, condition := some (.organism morphine) }) .pos (.process breathing)
def anpGivenAvp : Claim :=
  .effect (e_PR_P01160.inCtx { taxon := some rabbit, condition := some (.organism argipressin) }) .neg (.process renalWater)
#guard nalGivenMorphine.subjectCurie = "CHEBI:7459&RO:0002162=(NCBITaxon:9606&RO:0002573=(CHEBI:17303))"
#guard anpGivenAvp.subjectCurie = "PR:P01160&RO:0002162=(NCBITaxon:9986&RO:0002573=(CHEBI:34543))"

/-! ## T20. Antagonistic muscles: RO:0002568 "has muscle antagonist" is expressible between two
UBERON muscles. The effects are not: no OBO term for elbow flexion or forearm supination as a normal
movement was found on OLS4 (only HP abnormalities). INEXPRESSIBLE for the effects, PASS for the
relation. -/
example : Claim := .rel hasMuscleAntagonist biceps triceps

/-! ## T21. Context keeps opposite actions apart: GABA depolarises neonatal neurons and
hyperpolarises adult ones (Ben-Ari 2002, PMID 12209121). Two claims with life-stage contexts have
different targets, so they never fuse or clash. PASS. -/
def gaba : Entity .chemical := ⟨"CHEBI:16865", "gamma-aminobutyric acid"⟩
def depolarization : Entity .process := ⟨"GO:0051899", "membrane depolarization"⟩
def neonate : Entity .anatomy := ⟨"UBERON:0007221", "neonate stage"⟩
def adultStage : Entity .anatomy := ⟨"UBERON:0000113", "post-juvenile adult stage"⟩
def gabaNeo : Claim := .effect gaba .pos (.process (depolarization.inCtx { cellType := e_CL_0000540, lifeStage := neonate }))
def gabaAdult : Claim := .effect gaba .neg (.process (depolarization.inCtx { cellType := e_CL_0000540, lifeStage := adultStage }))
#guard match gabaNeo, gabaAdult with
  | .effect _ _ t₁, .effect _ _ t₂ => toString t₁ != toString t₂ | _, _ => false

/-! ## T22. A lint that closes the T06 hole outside the core. Of the 75 `amount` targets in R2 and R3,
64 are chemicals or proteins and 11 are not (5 taxa, 3 anatomy, 1 cell type, 2 components), all
sensible ("amount of blood", "amount of bacteria"). So restricting `amount` to molecular kinds would
break 11 good statements. The lint: an anatomy entity must be is_a UBERON:0000463 "organism
substance" (blood, milk, gastric juice pass; both nervous systems fail), and a process, phenotype,
function or disease has no amount at all. The prototype runs it over the whole library: all 75 pass.
In the core it would be a side condition on `Target.amount` (like `transport`'s `Taxa.siblings`):
that is a core change. -/
def organismSubstance : String := "UBERON:0000463"
def amountLint {k : Kind} (e : Entity k) : Bool :=
  match k with
  | .anatomy => Ontology.isACurie (Ctx.baseCurie e.curie) organismSubstance
  | .process | .phenotype | .function | .disease => false
  | _ => true
#guard amountLint e_UBERON_0000178 && amountLint (⟨"UBERON:0001913", "milk"⟩ : Entity .anatomy) &&
  amountLint (⟨"UBERON:0001971", "gastric juice"⟩ : Entity .anatomy) &&
  amountLint (e_UBERON_0000178.inCtx { anatomy := e_UBERON_0002097 })
#guard !amountLint symp && !amountLint para && !amountLint e_GO_0007586 && !amountLint e_OBA_1001087

/-! ## T23. A per-target antagonist effect chains through today's rules (case D07)

ChEMBL's action types give per-target effects (T15): morphine raises, naloxone lowers mu receptor
activity. Matthes 1996 (PMID 8893006): "a lack of mu receptors abolishes the analgesic effect of
morphine", so mu receptor activity lowers pain perception. `viaActivity` then derives "morphine
lowers pain perception" (right) and "naloxone raises pain perception" (over-general) with no new
rule. El-Sobky 1976 (PMID 186714, title) found no effect of naloxone on pain perception in humans;
Levine 1978 (PMID 80579) found that naloxone raised postoperative dental pain, in placebo responders
only. So "naloxone raises pain" holds only where opioids are acting. The plain per-target encoding of
an antagonist drops that condition; rule (c) is not needed to get the error. FAIL. -/
def curated (note : String) : Evidence := { pmid := 0, year := 2026, kind := .curatedDb, note := note }
def sMorMOR : Statement := ⟨"CHEMBL70/mechanism", "morphine is a mu opioid receptor agonist",
  .effect morphine .pos (.activity mor), [curated "ChEMBL mechanism: Mu opioid receptor agonist"]⟩
def sNalMOR : Statement := ⟨"CHEMBL80/mechanism", "naloxone is an opioid receptor antagonist",
  .effect naloxone .neg (.activity mor), [curated "ChEMBL mechanism: Opioid receptors; mu/kappa/delta antagonist"]⟩
def sMORpain : Statement := ⟨"PMID:8893006", "mu opioid receptor activity lowers pain perception",
  .effect mor .neg (.process painPerception),
  [paper 8893006 1996 .mechanistic "a lack of mu receptors abolishes the analgesic effect of morphine"]⟩
def dMorPain : Derivation (.effect morphine .neg (.process painPerception)) := .viaActivity (.lit sMorMOR) (.lit sMORpain)
def dNalPain : Derivation (.effect naloxone .pos (.process painPerception)) := .viaActivity (.lit sNalMOR) (.lit sMORpain)
theorem dNalPain_belief : dNalPain.opinion.belief = 14 / 25 := by decide +kernel
#guard ruleName dNalPain = "viaActivity" && dMorPain.opinion.belief == dNalPain.opinion.belief

/-! ## Observed -/

#eval show IO Unit from do
  obs "T01" s!"m45539-296 has no Lean; -295 is '{s295.claim}' ({shape s295.claim}); Claim has {coreShapes.length} constructors, none is 'opposes'"
  obs "T02" "m45537-331 and -333 have no Lean"
  obs "T03" s!"299, 300, 371, 306, 307, 308 are separate axioms, each {ostr (Derivation.lit s306).opinion}; para is_a symp: {Ontology.isACurie para.curie symp.curie}"
  obs "T06" s!"core accepts '{holePara.claim}'; viaAmount derives 306 {ostr h306.opinion} via rule {ruleName h306}, and 307, 308, 299, 371, 300; also 377 '{s377.claim}' and '{hThermo.claim}'"
  obs "T07" s!"'{holeGlc.claim}' + m45537-53 derives '{hGlc.claim}' {ostr hGlc.opinion}; Svendsen 2018 states '{svendsen.claim}'"
  obs "T08" s!"insulin and glucagon: '{s53.claim}' and '{s201.claim}'"
  obs "T09" s!"calcitonin and PTH: '{s135.claim}' and '{s140.claim}'"
  obs "T10" s!"ATP and ADP: '{s244.claim}' and '{s248.claim}'"
  obs "T11" s!"insulin R2: '{s202.claim}'; no glucagon statement on that target"
  obs "T12" s!"'{s153.claim}' and '{s156.claim}': opposite signs, nothing called opposed"
  obs "T13" s!"bronchi: '{s60.claim}' and '{s61.claim}'"
  obs "T14" s!"loop '{BioLean.Homeostasis.S_loop.claim}' vs arm '{s53.claim}': targets differ; no glucagon loop"
  obs "T15" "morphine →+ activity MOR, naloxone →− activity MOR, RO:0018027 and RO:0018029 rel claims, naloxone →0 pain: all type-check"
  obs "T18" s!"RO:0018027/18028/18029/2568 used by a chain, inverse or transitivity: {roUses isAgonistOf || roUses isInverseAgonistOf || roUses isAntagonistOf || roUses hasMuscleAntagonist}; RO:0002604 imported: {(RO.labels.lookup ⟨.ro, 2604, false⟩).isSome}"
  obs "T19" "no Target constructor takes an effect: interaction claims cannot be stated"
  obs "T20" "biceps has_muscle_antagonist triceps type-checks; no OBO process for elbow flexion"
  obs "T22" s!"amount lint (anatomy must be is_a UBERON:0000463; no process, phenotype, function or disease): blood {amountLint e_UBERON_0000178}, blood in skin {amountLint (e_UBERON_0000178.inCtx { anatomy := e_UBERON_0002097 })}, sympathetic system {amountLint symp}, parasympathetic system {amountLint para}, digestion {amountLint e_GO_0007586}, heart rate {amountLint e_OBA_1001087}"
  obs "T19b" s!"conditional effects type-check: '{nalGivenMorphine}' and '{anpGivenAvp}'"
  obs "T23" s!"viaActivity derives '{dMorPain.claim}' {ostr dMorPain.opinion} and '{dNalPain.claim}' {ostr dNalPain.opinion}, from ChEMBL's per-target signs and Matthes 1996"
  obs "T21" s!"GABA neonate '{gabaNeo}' and adult '{gabaAdult}' have different targets"

end BioLean.Stress.Opposition
