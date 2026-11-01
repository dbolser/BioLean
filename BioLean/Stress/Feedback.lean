import BioLean.Derivation
import BioLean.Examples.Homeostasis
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR2.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR2.Photosynthesis
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR3.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR3.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR3.Photosynthesis
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsB

/-!
# Stress set 02b: feedback loops against today's core

Program 02b (`docs/programs/02b-feedback-loops.md`). Decision 2 (Dan, 2026-10-29): a loop is a
claim in its own right, `Claim.homeostasis regulator held`. This file runs 44 cases (loops, and
things that look like loops) through the core as it is (`BioLean/*.lean`) and the compiled
textbook (R2, R3). Nothing here changes the core. The prototypes (a loop sign, several regulators,
a set point as a measure claim, a loop-aware reading of derivations) are in
`BioLean/Proto/Feedback.lean`. The closure cases (C..) run in `scripts/stress/closure_loops.py`.

Every case prints one `OBS` line; `data/stress/02b/scripts/cases.py` reads them into
`data/stress/02b/cases.tsv`. Pins (`#guard`, `example`, `theorem ... := by decide +kernel`,
`#fb_no_lean`) make a later change to the core or the libraries break this file visibly.

Marks: PASS right conclusion; FAIL wrong conclusion; SILENT no conclusion where one is due;
INEXPRESSIBLE the core cannot state it. SYNTHETIC marks a statement I wrote from a sentence that
has no Lean yet, or a made-up edge case; its source is named on it. Literature statements cite
papers checked on Europe PMC (`data/stress/02b/refs.tsv`); CURIEs are checked on OLS4
(`data/stress/02b/curies.tsv`).

The rule for a round trip, used in the marks: going once round a negative loop gives "x lowers x".
That is false as a net effect (more glucose does not lower blood glucose; the loop only pushes
back), so it is FAIL as an effect claim. Going round a positive loop gives "x raises x", which is
true as a net effect (amplification), so it is PASS, even though the loop is not named.
-/

namespace BioLean.Stress.Feedback
open BioLean Derivation BioLean.Textbook BioLean.Textbook.R2 BioLean.Textbook.R3

/-! ## Helpers (probes, not core) -/

def obs (id msg : String) : IO Unit := IO.println s!"OBS\t{id}\t{msg}"
def tb (note : String) : Evidence := { pmid := 0, year := 2013, kind := .textbook, note := note }
def paper (pmid year : Nat) (k : EvidenceKind) (note : String) (p : Opinion.Polarity := .supports) :
    Evidence := { pmid := pmid, year := year, kind := k, note := note, polarity := p }
def ostr (o : Opinion) : String :=
  s!"b={o.belief.toDecimal} d={o.disbelief.toDecimal} u={o.uncertainty.toDecimal}"
def vstr (o : Opinion) : String :=
  match o.verdict with
  | .established => "established" | .contested => "contested" | .refuted => "refuted" | .unsupported => "unsupported"

/-- The shape of a claim. No wildcard on purpose: a new constructor (a `loop` with a sign, a
`setPoint`) makes this file fail to compile, which flips every INEXPRESSIBLE pin at once. -/
def shape : Claim → String
  | .effect .. => "effect" | .mediatedBy .. => "mediatedBy" | .noEffect .. => "noEffect"
  | .rel .. => "rel" | .notRel .. => "notRel" | .count .. => "count" | .atLeast .. => "atLeast"
  | .countBetween .. => "countBetween" | .cardinality .. => "cardinality" | .measure .. => "measure"
  | .atLeastMeasure .. => "atLeastMeasure" | .less .. => "less" | .produces .. => "produces"
  | .consumes .. => "consumes" | .yield .. => "yield" | .homeostasis .. => "homeostasis"
  | .quant _ c => s!"quant {shape c}"

/-- What `Claim.homeostasis` holds: exactly a regulator and a held target, nothing else. The
pattern has the constructor's exact arity, so adding a sign, a second regulator or a set point to
the constructor breaks this definition. This is the pin for "what homeostasis cannot hold". -/
def homeoFields : Claim → Option (String × String)
  | .homeostasis r h => some (r.curie, toString h)
  | _ => none

/-- The kinds of target. No wildcard: a ratio target (energy charge) or a set-point target breaks it. -/
def targetShape : Target → String
  | .activity .. => "activity" | .amount .. => "amount" | .process .. => "process"
  | .phenotype .. => "phenotype" | .site .. => "site"

def targetCurie : Target → String
  | .activity p _ => p.curie | .amount m => m.curie | .process p => p.curie
  | .phenotype p => p.curie | .site a => a.curie

/-- Can the two core chaining rules join `c₁` then `c₂`? `viaAmount` needs `c₁` to end on an
amount and `viaActivity` on an activity, and `c₂`'s agent to be that very entity (kind, curie and
label). This mirrors the premises of the two rules in `Derivation.lean`; it is used only to pin
where a loop cannot be closed. There is no rule with a process or phenotype in the middle. -/
def chainable : Claim → Claim → Bool
  | .effect _ _ (.amount (k := k) m), .effect (k := k') b _ _ => k == k' && m.curie == b.curie && m.label == b.label
  | .effect _ _ (.activity (k := k) m _), .effect (k := k') b _ _ => k == k' && m.curie == b.curie && m.label == b.label
  | _, _ => false

def chapters : List Lean.Name :=
  [`CellStructureAndFunction, `HowCellsObtainEnergy, `MolecularBiology, `Photosynthesis,
   `ReproductionAtTheCellularLevel, `TheBodySSystemsA, `TheBodySSystemsB, `TheCellularBasisOfInheritance]

open Lean Elab Command in
/-- `#fb_no_lean Chapter name`: neither R2 nor R3 has a statement `name`; fails if the chapter is
not imported in both rounds, so a typo cannot pass. When the record gets Lean, this pin breaks. -/
elab "#fb_no_lean " m:ident n:ident : command => do
  let env ← getEnv
  for pre in [`BioLean.Textbook.R2, `BioLean.Textbook.R3] do
    unless env.isNamespace (pre ++ m.getId) do throwError "{pre ++ m.getId} is not imported"
    for c in chapters do
      if env.contains (pre ++ c ++ n.getId) then
        throwError "{pre ++ c ++ n.getId} exists: the record now has Lean"

/-! ## Entities not in the textbook libraries (CURIEs and labels as on OLS4) -/

def crh : Entity .protein := ⟨"PR:000005867", "corticoliberin"⟩
def acth : Entity .chemical := ⟨"CHEBI:3892", "corticotropin"⟩
def cortisol : Entity .chemical := ⟨"CHEBI:17650", "cortisol"⟩
def dexamethasone : Entity .chemical := ⟨"CHEBI:41879", "dexamethasone"⟩
def plasmaOsmolality : Entity .phenotype := ⟨"OBA:2045426", "blood plasma osmolality"⟩
def renalWaterAbsorption : Entity .process := ⟨"GO:0070295", "renal water absorption"⟩
def baroreflex : Entity .process :=
  ⟨"GO:0003025", "regulation of systemic arterial blood pressure by baroreceptor feedback"⟩
def arterialPressure : Entity .phenotype := ⟨"OBA:0000143", "systemic arterial blood pressure"⟩
def goiter : Entity .disease := ⟨"MONDO:0005397", "goiter"⟩
def guardCell : Entity .anatomy := ⟨"PO:0000293", "guard cell"⟩
def leaf : Entity .anatomy := ⟨"PO:0025034", "leaf"⟩
def ile : Entity .chemical := ⟨"CHEBI:17191", "L-isoleucine"⟩
def thrDeaminase : Entity .function := ⟨"GO:0004794", "threonine deaminase activity"⟩
def ecoli : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩
def uterineContraction : Entity .process := ⟨"GO:0070471", "uterine smooth muscle contraction"⟩
def thrombin : Entity .protein := ⟨"PR:000007299", "prothrombin"⟩   -- PR has no separate thrombin class found; the active form is a cleavage product
def factorV : Entity .protein := ⟨"PR:000007300", "coagulation factor V"⟩
def proteinC : Entity .protein := ⟨"PR:000013261", "vitamin K-dependent protein C"⟩
def estradiol : Entity .chemical := ⟨"CHEBI:16469", "17beta-estradiol"⟩
def ethene : Entity .chemical := ⟨"CHEBI:18153", "ethene"⟩
def ethyleneSynthesis : Entity .process := ⟨"GO:0009693", "ethylene biosynthetic process"⟩
def climactericRipening : Entity .process := ⟨"GO:0009836", "fruit ripening, climacteric"⟩
def tomato : Entity .taxon := ⟨"NCBITaxon:4081", "Solanum lycopersicum"⟩
def tastePerception : Entity .process := ⟨"GO:0050909", "sensory perception of taste"⟩
def bodyTemp : Entity .phenotype := ⟨"OBA:VT0005535", "body temperature trait"⟩
def pyrogen : Entity .chemical := ⟨"NCIT:C71583", "Pyrogen"⟩   -- NCIT, outside the ontologies the emitter supports
def hotEnvironment : Entity .phenotype := ⟨"BLN:hot_environment", "hot environment"⟩   -- placeholder, as BLN:hot_dry_day in R3
def sustainedHighE2 : Entity .phenotype := ⟨"BLN:sustained_high_estradiol", "sustained high estradiol"⟩   -- placeholder
def hypovolemia : Entity .phenotype := ⟨"BLN:hypovolemia", "reduced plasma volume"⟩   -- placeholder

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
abbrev t4 := e_CHEBI_30660
abbrev thyroid := e_UBERON_0002046
abbrev hypothalamus := e_UBERON_0001898
abbrev adh := e_CHEBI_34543
abbrev bloodCO2 := e_CHEBI_16526.inCtx { anatomy := blood }

/-- Refinement edges, as `closure.py` loads them: `e ⊓ ∃r.f is_a e`, belief 999/1000. -/
def bgIsaGlucose : Derivation (.rel Rel.isA bloodGlucose glucose) := .lit (Entity.refineAxiom glucose Rel.locatedIn blood)

/-! ## A. Negative loops from the textbook and physiology -/

/-! ### L01 glucose and insulin: going round the loop gives "glucose lowers blood glucose" -/
def L01_roundTrip : Derivation (.effect glucose .neg (.amount bloodGlucose)) :=
  .viaAmount (.lit R2.TheBodySSystemsB.the_body_s_systems_m45537_52)
    (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_53)
theorem L01_belief : L01_roundTrip.opinion.belief = 16 / 25 := by decide +kernel
theorem L01_established : Established (.effect glucose .neg (.amount bloodGlucose)) (3 / 5) :=
  ⟨L01_roundTrip, by decide +kernel⟩
example : L01_roundTrip.verdict = .unsupported := by decide +kernel
/-- The loop itself, stated as the decision says (`Examples/Homeostasis.lean` with R2/R3 entities). -/
def L01_loop : Statement := ⟨"the-body-s-systems-m45537-333~loop", "insulin holds blood glucose near a set point",
  .homeostasis insulin (.amount bloodGlucose), [tb "Blood-glucose levels are regulated by hormones produced by the pancreas: insulin and glucagon."]⟩
theorem L01_loop_belief : (Derivation.lit L01_loop).opinion.belief = 4 / 5 := by decide +kernel
#eval obs "L01" s!"core derives '{L01_roundTrip.claim}' {ostr L01_roundTrip.opinion} (Established at 3/5; default verdict {vstr L01_roundTrip.opinion}, as for every two-step textbook chain, right or wrong: N05 has the same belief); the homeostasis claim compiles at b=0.8 but nothing links it to the derivation"

/-! ### L02 glucose and glucagon, through a refinement edge -/
def L02_glucagonCtxIsa : Derivation (.rel Rel.isA (glucagon.inCtx { anatomy := blood, cellType := e_CL_0000171 }) glucagon) :=
  .relChain (.lit (Entity.refineAxiom (glucagon.refine Rel.locatedIn blood) Rel.partOf e_CL_0000171))
    (.lit (Entity.refineAxiom glucagon Rel.locatedIn blood))
def L02_roundTrip : Derivation (.effect glucose .neg (.amount bloodGlucose)) :=
  .viaAmount (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_199)
    (.isaInheritEffect L02_glucagonCtxIsa (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_201))
theorem L02_belief : L02_roundTrip.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "L02" s!"core derives '{L02_roundTrip.claim}' {ostr L02_roundTrip.opinion} via the refinement edge (glucagon in blood in alpha cell is_a glucagon)"

/-! ### L03 calcium and parathyroid hormone -/
def L03_roundTrip : Derivation (.effect calcium .neg (.amount bloodCalcium)) :=
  .viaAmount (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_141)
    (.isaInheritEffect (.lit (Entity.refineAxiom pth Rel.locatedIn blood)) (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_140))
theorem L03_belief : L03_roundTrip.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "L03" s!"core derives '{L03_roundTrip.claim}' {ostr L03_roundTrip.opinion}"

/-! ### L04 calcitonin: a textbook loop that the literature disputes (Hirsch 2001, PMID 15758481) -/
def L04_loopTb : Statement := ⟨"the-body-s-systems-m45537-134~loop", "calcitonin holds blood calcium",
  .homeostasis calcitonin (.amount bloodCalcium), [tb "Calcitonin is released in response to rising calcium ion concentrations in the blood and has the effect of reducing those levels."]⟩
def L04_loopLit : Statement := { L04_loopTb with evidence := L04_loopTb.evidence ++
  [paper 15758481 2001 .review "Hirsch 2001: early purported roles in blood calcium regulation are no longer considered as physiological functions" .refutes] }
example : (Derivation.lit L04_loopTb).verdict = .established := by decide +kernel
example : (Derivation.lit L04_loopLit).verdict = .unsupported := by decide +kernel
theorem L04_disbelief : (Derivation.lit L04_loopLit).opinion.disbelief = 3 / 13 := by decide +kernel
#eval obs "L04" s!"textbook alone: {vstr (Derivation.lit L04_loopTb).opinion}; with the refuting review: {vstr (Derivation.lit L04_loopLit).opinion} {ostr (Derivation.lit L04_loopLit).opinion}"

/-! ### L05 thermoregulation as compiled: "maintains" became "raises" -/
abbrev s77 := R3.TheBodySSystemsA.the_body_s_systems_m45534_77
#guard shape s77.claim == "effect"
#guard (match s77.claim with | .effect _ .pos _ => true | _ => false)
#guard s77.claim.subjectCurie == "UBERON:0001898&RO:0001025=(UBERON:0001898)&RO:0002162=(NCBITaxon:7742)"
#eval obs "L05" s!"R3 -77 reads '{s77.claim}': the hypothalamus raises temperature; the book says it maintains a set point. Also: hypothalamus refined by 'located in hypothalamus'"

/-! ### L06 osmoregulation by ADH: the loop closes through a process, and no rule chains a process -/
def L06_sense : Statement := ⟨"syn:L06-sense", "plasma osmolality raises ADH (vasopressin) release",
  .effect plasmaOsmolality .pos (.amount adh), [paper 14613925 2004 .mechanistic "Kondo 2004 (rats): plasma AVP correlated with plasma Na; osmotically induced AVP release"]⟩
def L06_act : Statement := ⟨"syn:L06-act", "ADH raises renal water absorption",
  .effect adh .pos (.process renalWaterAbsorption), [paper 22374125 2012 .review "Juul 2012: vasopressin controls reabsorption via V2 receptors and aquaporins"]⟩
def L06_back : Statement := ⟨"syn:L06-back", "renal water absorption lowers plasma osmolality",
  .effect renalWaterAbsorption .neg (.phenotype plasmaOsmolality), [paper 18509340 2008 .review "Bourque 2008: renal function stabilises tonicity"]⟩
def L06_half : Derivation (.effect plasmaOsmolality .pos (.process renalWaterAbsorption)) := .viaAmount (.lit L06_sense) (.lit L06_act)
#guard chainable L06_sense.claim L06_act.claim
#guard !chainable L06_half.claim L06_back.claim
theorem L06_belief : L06_half.opinion.belief = 21 / 50 := by decide +kernel
#eval obs "L06" s!"core derives '{L06_half.claim}' {ostr L06_half.opinion} (right), then stops: a process ({targetShape (.process renalWaterAbsorption)}) cannot be chained; the loop never closes"

/-! ### L07 blood pressure: a fast loop and a slow loop on one variable (Guyton 1991, PMID 2063193) -/
def L07_fast : Claim := .homeostasis baroreflex (.phenotype arterialPressure)
def L07_slow : Claim := .homeostasis e_UBERON_0002113 (.phenotype arterialPressure)
#guard homeoFields L07_fast == some ("GO:0003025", "systemic arterial blood pressure [OBA:0000143]")
#guard (homeoFields L07_slow).map (·.2) == (homeoFields L07_fast).map (·.2)
#eval obs "L07" s!"both loops compile as homeostasis on {(homeoFields L07_fast).map (·.2)}; nothing can say seconds vs days, or that the kidney sets the long-term level"

/-! ### L08 thyroid axis: the negative arm has no Lean -/
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45537_258
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45537_260
/-- SYNTHETIC encoding of -258 ("increasing levels of these hormones ... inhibit further signaling"), as proposed in `homeostasis_m3.json`. -/
def L08_back : Statement := ⟨"the-body-s-systems-m45537-258", "T3 lowers TSH",
  .effect t3 .neg (.amount tsh), [tb "Increasing levels of these hormones in the blood then give feedback to the hypothalamus and anterior pituitary to inhibit further signaling to the thyroid gland."]⟩
def L08_roundTrip : Derivation (.effect tsh .neg (.amount tsh)) :=
  .viaAmount (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_129)
    (.isaInheritEffect (.lit (Entity.refineAxiom t3 Rel.locatedIn thyroid)) (.lit L08_back))
theorem L08_belief : L08_roundTrip.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "L08" s!"today no loop: -258 and -260 have no Lean (pinned). With the proposed arm the core derives '{L08_roundTrip.claim}' {ostr L08_roundTrip.opinion}, the same round trip as L01"

/-! ### L09 goiter: a right conclusion through the loop (Chopra 1975, PMID 1117981) -/
def L09_goiterT4 : Statement := ⟨"the-body-s-systems-m45537-263", "goiter lowers T4 (inability to form T3 and T4)",
  .effect goiter .neg (.amount t4), [tb "Goiter ... results in the inability of the thyroid gland to form T3 and T4."]⟩
def L09_goiterT3 : Statement := ⟨"the-body-s-systems-m45537-263#T3", "goiter lowers T3",
  .effect goiter .neg (.amount t3), [tb "Goiter ... results in the inability of the thyroid gland to form T3 and T4."]⟩
def L09_t4Back : Statement := ⟨"the-body-s-systems-m45537-258#T4", "T4 lowers TSH",
  .effect t4 .neg (.amount tsh), [tb "Increasing levels of these hormones ... inhibit further signaling to the thyroid gland."]⟩
def L09_viaT4 : Derivation (.effect goiter .pos (.amount tsh)) := .viaAmount (.lit L09_goiterT4) (.lit L09_t4Back)
def L09_viaT3 : Derivation (.effect goiter .pos (.amount tsh)) := .viaAmount (.lit L09_goiterT3) (.lit L08_back)
theorem L09_belief : L09_viaT4.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "L09" s!"core derives '{L09_viaT4.claim}' {ostr L09_viaT4.opinion} (right: TSH supranormal, Chopra 1975); the T3 route gives the same answer from a premise Chopra contradicts (T3 supranormal)"

/-! ### L10 cortisol (HPA) axis: a three-step round trip (Herman 2016, PMID 27065163) -/
def herman (note : String) : Evidence := paper 27065163 2016 .review note
def L10_crh : Statement := ⟨"syn:L10-crh", "CRH raises ACTH", .effect crh .pos (.amount acth), [herman "HPA axis driven by CRH release"]⟩
def L10_acth : Statement := ⟨"syn:L10-acth", "ACTH raises cortisol", .effect acth .pos (.amount cortisol), [herman "activation of the HPA axis causes secretion of glucocorticoids"]⟩
def L10_back : Statement := ⟨"syn:L10-back", "cortisol lowers CRH", .effect cortisol .neg (.amount crh), [herman "glucocorticoids act at the PVN to rapidly inhibit CRH neuronal activity"]⟩
def L10_roundTrip : Derivation (.effect cortisol .neg (.amount cortisol)) :=
  .viaAmount (.viaAmount (.lit L10_back) (.lit L10_crh)) (.lit L10_acth)
theorem L10_belief : L10_roundTrip.opinion.belief = 27 / 125 := by decide +kernel
#eval obs "L10" s!"core derives '{L10_roundTrip.claim}' {ostr L10_roundTrip.opinion}: a three-node round trip, weaker but the same mistake"

/-! ### L11 dexamethasone suppression: a right conclusion through the negative arm -/
def L11_dex : Statement := ⟨"syn:L11-dex", "dexamethasone lowers ACTH (glucocorticoid negative feedback)",
  .effect dexamethasone .neg (.amount acth),
  [paper 16759341 2006 .observational "Aouizerate 2006: dexamethasone suppression tests probe glucocorticoid negative feedback",
   paper 18334580 2008 .review "Nieman 2008: the dexamethasone suppression test is a first-line test for Cushing's syndrome"]⟩
def L11_cortisol : Derivation (.effect dexamethasone .neg (.amount cortisol)) := .viaAmount (.lit L11_dex) (.lit L10_acth)
theorem L11_belief : L11_cortisol.opinion.belief = 3 / 7 := by decide +kernel
#eval obs "L11" s!"core derives '{L11_cortisol.claim}' {ostr L11_cortisol.opinion} (right: the principle of the suppression test)"

/-! ### L12 erythropoietin and oxygen: the return arm runs through a process -/
abbrev s238 := R2.TheBodySSystemsB.the_body_s_systems_m45537_238
abbrev s240 := R3.TheBodySSystemsB.the_body_s_systems_m45537_240
#guard chainable s238.claim s240.claim
#guard (match s240.claim with | .effect _ _ t => targetShape t == "process" | _ => false)
def L12_half : Derivation (.effect e_CHEBI_15379 .neg (.process (e_GO_0030218.inCtx { anatomy := e_UBERON_0002371 }))) := .viaAmount (.lit s238) (.lit s240)
theorem L12_belief : L12_half.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "L12" s!"core derives '{L12_half.claim}' {ostr L12_half.opinion} (right: low oxygen raises red cell formation) and stops at the process; no loop"

/-! ### L13 breathing and CO2: the book's sentence has no Lean; the sensor arm ends on a process -/
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45536_30
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45536_31
def L13_sense : Statement := ⟨"the-body-s-systems-m45536-31", "blood CO2 raises breathing",
  .effect bloodCO2 .pos (.process e_GO_0003016), [paper 26335642 2015 .review "Guyenet 2015: neurons activated by PCO2 stimulate breathing"]⟩
def L13_back : Statement := ⟨"syn:L13-back", "breathing lowers blood CO2",
  .effect e_GO_0003016 .neg (.amount bloodCO2), [paper 26335642 2015 .review "Guyenet 2015: chemoreflexes mediate rapid stabilization of arterial PCO2"]⟩
#guard !chainable L13_sense.claim L13_back.claim
#eval obs "L13" s!"no round trip: the sensor arm ends on {targetShape (.process e_GO_0003016)}; the core cannot close a loop through breathing"

/-! ### L14 stomata and leaf water -/
abbrev s84 := R3.Photosynthesis.photosynthesis_m45448_84
abbrev s85 := R2.Photosynthesis.photosynthesis_m45448_85
#guard shape s84.claim == "rel"
#guard (match s85.claim with | .effect _ .neg t => targetShape t == "process" | _ => false)
#eval obs "L14" s!"R3 -84 is '{shape s84.claim}' (plants capable of stomatal closure on a hot dry day), R2 -85 '{s85.claim}'; no water-deficit arm, no loop"

/-! ### L15 atrial natriuretic peptide and blood volume -/
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45537_226
/-- SYNTHETIC grounding of -226: "a hormone" is ANP (PR:P01160, the R2 entity used by -227). -/
def L15_sense : Statement := ⟨"the-body-s-systems-m45537-226", "blood volume raises ANP",
  .effect e_OBA_0003648 .pos (.amount e_PR_P01160), [tb "The heart has endocrine cells in the walls of the atria that release a hormone in response to increased blood volume."]⟩
def L15_roundTrip : Derivation (.effect e_OBA_0003648 .neg (.phenotype e_OBA_0003648)) :=
  .viaAmount (.lit L15_sense) (.lit R2.TheBodySSystemsB.the_body_s_systems_m45537_227)
theorem L15_belief : L15_roundTrip.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "L15" s!"with -226 grounded, core derives '{L15_roundTrip.claim}' {ostr L15_roundTrip.opinion}"

/-! ### L16 aldosterone "regulates": a signless arm -/
abbrev s153 := R3.TheBodySSystemsB.the_body_s_systems_m45537_153
#guard (match s153.claim with | .effect _ .neg _ => true | _ => false)
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45537_150
example : Rel.accepts ⟨.ro, 2211, false⟩ .chemical .chemical = false := by decide
#eval obs "L16" s!"sensor arm compiles ('{s153.claim}'); 'aldosterone regulates ion concentration' has no sign, RO 'regulates' (RO:0002211) takes processes only, and homeostasis would claim more than the book"

/-! ### L17 leptin and eating: a loop that mostly defends one direction (Ahima 1996, PMID 8717038) -/
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45537_254
def L17_back : Statement := ⟨"the-body-s-systems-m45537-254", "leptin lowers food intake",
  .effect e_PR_000009758 .neg (.process e_GO_0042755), [tb "Leptin produces a feeling of satiety after eating, reducing the urge for further eating."]⟩
def L17_roundTrip : Derivation (.effect e_GO_0042755 .neg (.process e_GO_0042755)) :=
  .viaAmount (.lit R2.TheBodySSystemsB.the_body_s_systems_m45537_251) (.lit L17_back)
#guard L17_roundTrip.claim.subjectCurie == "GO:0042755"
theorem L17_belief : L17_roundTrip.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "L17" s!"core derives '{L17_roundTrip.claim}' {ostr L17_roundTrip.opinion} (exactly reflexive); no claim can say the loop acts mainly when leptin falls"

/-! ### L18 feedback inhibition: isoleucine and threonine deaminase (Eisenstein 1991, PMID 2005118) -/
def eis : Evidence := paper 2005118 1991 .inVitro "Eisenstein 1991: feedback inhibition of threonine deaminase by isoleucine controls branched chain amino acid biosynthesis"
def ileCtx : Entity .chemical := ile.inCtx { taxon := ecoli }
def L18_inhib : Statement := ⟨"syn:L18-inhib", "isoleucine inhibits threonine deaminase", .effect ileCtx .neg (.activity thrDeaminase), [eis]⟩
def L18_make : Statement := ⟨"syn:L18-make", "threonine deaminase activity raises isoleucine", .effect thrDeaminase .pos (.amount ileCtx), [eis]⟩
def L18_roundTrip : Derivation (.effect ileCtx .neg (.amount ileCtx)) := .viaActivity (.lit L18_inhib) (.lit L18_make)
def L18_loop : Claim := .homeostasis ileCtx (.amount ileCtx)
theorem L18_belief : L18_roundTrip.opinion.belief = 1 / 4 := by decide +kernel
#guard homeoFields L18_loop == some (ileCtx.curie, toString (Target.amount ileCtx))
#eval obs "L18" s!"core derives '{L18_roundTrip.claim}' {ostr L18_roundTrip.opinion}; the loop compiles with regulator = held"

/-! ### L19 ATP and sugar catabolism: the held quantity is a ratio (energy charge, Atkinson 1968) -/
abbrev s244 := R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45437_244
abbrev s247 := R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45437_247
#guard (match s244.claim with | .effect _ .neg t => targetShape t == "process" | _ => false)
#guard (match s247.claim with | .effect _ .pos t => targetCurie t == "GO:0003824" | _ => false)
#eval obs "L19" s!"arms compile ('{s244.claim}', '{s247.claim}'); a Target is one entity's activity, amount, process, phenotype or site; no ratio of ATP to ADP"

/-! ## B. Positive loops -/

/-! ### P01 oxytocin in labour, stated as homeostasis: the core accepts it (Russell 2003, PMID 12609499) -/
def russell : Evidence := paper 12609499 2003 .mechanistic "Russell 2003: oxytocin secretion is stimulated by uterine contractions; oxytocin stimulates further contractions; a positive feedback loop is activated"
def P01_asLoop : Statement := ⟨"syn:P01-loop", "oxytocin holds uterine contraction (wrong: a positive loop)",
  .homeostasis e_CHEBI_7872 (.process uterineContraction), [russell]⟩
def P01_act : Statement := ⟨"syn:P01-act", "oxytocin raises uterine contraction", .effect e_CHEBI_7872 .pos (.process uterineContraction), [russell]⟩
def P01_back : Statement := ⟨"syn:P01-back", "uterine contraction raises oxytocin", .effect uterineContraction .pos (.amount e_CHEBI_7872), [russell]⟩
theorem P01_accepted : (Derivation.lit P01_asLoop).opinion.belief = 7 / 10 := by decide +kernel
#guard !chainable P01_act.claim P01_back.claim
#eval obs "P01" s!"core accepts '{P01_asLoop.claim}' at b=0.7: homeostasis has no sign, so a positive loop passes as negative feedback; the arms cannot chain (process)"

/-! ### P02 clotting: thrombin amplifies itself through factor V (Panteleev 2010, PMID 20441738) -/
def pant : Evidence := paper 20441738 2010 .mechanistic "Panteleev 2010: a single positive feedback of factor V activation by thrombin"
def P02_act : Statement := ⟨"syn:P02-act", "thrombin activates factor V", .effect thrombin .pos (.activity factorV), [pant]⟩
def P02_back : Statement := ⟨"syn:P02-back", "factor V activity raises thrombin", .effect factorV .pos (.amount thrombin), [paper 11434702 2001 .review "Hoffman 2001: amplification, cofactors activated for large scale thrombin generation"]⟩
def P02_selfRaise : Derivation (.effect thrombin .pos (.amount thrombin)) := .viaActivity (.lit P02_act) (.lit P02_back)
theorem P02_belief : P02_selfRaise.opinion.belief = 21 / 50 := by decide +kernel
#eval obs "P02" s!"core derives '{P02_selfRaise.claim}' {ostr P02_selfRaise.opinion}: true as a net effect (amplification)"

/-! ### P03 clotting: the same node also has a negative loop (Esmon 2003, PMID 12970121) -/
def esmon (n : String) : Evidence := paper 12970121 2003 .review n
def P03_pc : Statement := ⟨"syn:P03-pc", "thrombin (with thrombomodulin) activates protein C", .effect thrombin .pos (.activity proteinC), [esmon "thrombomodulin binds thrombin ... augmenting protein C activation"]⟩
def P03_off : Statement := ⟨"syn:P03-off", "activated protein C inactivates factor Va", .effect proteinC .neg (.activity factorV), [esmon "APC inactivates factors Va and VIIIa, thereby inhibiting further thrombin generation"]⟩
def P03_selfLower : Derivation (.effect thrombin .neg (.amount thrombin)) :=
  .viaActivity (.viaActivity (.lit P03_pc) (.lit P03_off)) (.lit P02_back)
theorem P03_belief : P03_selfLower.opinion.belief = 27 / 125 := by decide +kernel
#eval obs "P03" s!"core derives both '{P02_selfRaise.claim}' and '{P03_selfLower.claim}' {ostr P03_selfLower.opinion}; no rule relates them or says which acts when"

/-! ### P04 action potential: depolarisation raises depolarisation (textbook -87 says 'positive feedback loop') -/
abbrev s89 := R2.TheBodySSystemsB.the_body_s_systems_m45539_89
abbrev s90 := R2.TheBodySSystemsB.the_body_s_systems_m45539_90
abbrev s83 := R2.TheBodySSystemsB.the_body_s_systems_m45539_83
def P04_selfRaise : Derivation (.effect e_GO_0051899 .pos (.process e_GO_0051899)) :=
  .viaAmount (.viaActivity (.lit s89) (.lit s90)) (.lit s83)
theorem P04_belief : P04_selfRaise.opinion.belief = 64 / 125 := by decide +kernel
#eval obs "P04" s!"core derives '{P04_selfRaise.claim}' {ostr P04_selfRaise.opinion} from R2 -89, -90, -83: right (regenerative depolarisation)"

/-! ### P05 action potential: the potassium arm cannot close a negative loop -/
abbrev s95 := R2.TheBodySSystemsB.the_body_s_systems_m45539_95
abbrev s97 := R2.TheBodySSystemsB.the_body_s_systems_m45539_97
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45539_96
#guard !chainable s95.claim s97.claim
#eval obs "P05" s!"'{s95.claim}' and '{s97.claim}' do not join (K+ channel activity to K+ efflux has no Lean; repolarisation to depolarisation is process to process)"

/-! ### P06 the LH surge: estradiol's arm changes sign (Christian 2010, PMID 20237240) -/
def chr (n : String) : Evidence := paper 20237240 2010 .review n
def P06_neg : Statement := ⟨"syn:P06-neg", "estradiol lowers LH", .effect estradiol .neg (.amount e_PR_P01229), [chr "ovarian steroids normally exert homeostatic negative feedback"]⟩
def P06_pos : Statement := ⟨"syn:P06-pos", "estradiol raises LH", .effect estradiol .pos (.amount e_PR_P01229), [chr "during sustained exposure to elevated estradiol the feedback action switches to positive"]⟩
/-- Sustained high estradiol is a state of the organism, so it is an `organism` condition (has_modifier on the taxon
filler), not an `environment` one (surrounded_by, the subject's surroundings). -/
def P06_posCtx : Statement := { P06_pos with claim := .effect (estradiol.inCtx { taxon := Taxa.human, condition := some (.organism sustainedHighE2) }) .pos (.amount e_PR_P01229) }
#guard P06_neg.claim.subjectCurie == P06_pos.claim.subjectCurie
#guard P06_posCtx.claim.subjectCurie != P06_neg.claim.subjectCurie
#eval obs "P06" s!"bare: '{P06_neg.claim}' and '{P06_pos.claim}' sit side by side, no clash check for effects; with a placeholder condition the subjects differ ({P06_posCtx.claim.subjectCurie}); no ontology term for 'sustained high estradiol'"

/-! ### P07 ethylene in climacteric ripening: autocatalysis (Alexander 2002, PMID 12324528) -/
def P07_auto : Statement := ⟨"syn:P07-auto", "ethylene raises ethylene synthesis in ripening tomato",
  .effect (ethene.inCtx { taxon := tomato, stage := climactericRipening }) .pos (.process ethyleneSynthesis),
  [paper 12324528 2002 .review "Alexander 2002: initiation and subsequent autocatalytic phase of ethylene production during ripening"]⟩
def P07_out : Claim := .rel Rel.hasOutput ethyleneSynthesis ethene
#guard (match P07_auto.claim with | .effect _ _ t => targetShape t == "process" | _ => false)
#guard shape P07_out == "rel"
#eval obs "P07" s!"'{P07_auto.claim}' compiles with taxon and stage; the return arm is has_output (a rel), and no rule bridges rel to effect, so the loop does not close"

/-! ### P08 a positive loop made of two negative arms: the toggle switch (Gardner 2000, PMID 10659857)
"The toggle is constructed from any two repressible promoters arranged in a mutually inhibitory network." The abstract
names no repressors; LacI and TetR are an illustrative pair (which pair the paper used is UNVERIFIED here). -/
def gardner : Evidence := paper 10659857 2000 .mechanistic "Gardner 2000: two repressible promoters arranged in a mutually inhibitory network; bistable"
def lacI : Entity .protein := (⟨"PR:000023070", "lactose operon repressor"⟩ : Entity .protein).inCtx { taxon := ecoli }
def tetR : Entity .protein := (⟨"PR:P04483", "tetracycline repressor protein class B from transposon Tn10 (Escherichia coli)"⟩ : Entity .protein).inCtx { taxon := ecoli }
def P08_ab : Statement := ⟨"syn:P08-ab", "LacI represses TetR", .effect lacI .neg (.amount tetR), [gardner]⟩
def P08_ba : Statement := ⟨"syn:P08-ba", "TetR represses LacI", .effect tetR .neg (.amount lacI), [gardner]⟩
def P08_self : Derivation (.effect lacI .pos (.amount lacI)) := .viaAmount (.lit P08_ab) (.lit P08_ba)
example : Sign.neg * Sign.neg = Sign.pos := rfl
theorem P08_belief : P08_self.opinion.belief = 49 / 100 := by decide +kernel
#eval obs "P08" s!"core derives '{P08_self.claim}' {ostr P08_self.opinion}: two negative arms make a positive loop, and 'LacI raises LacI' is right as a net effect (the state reinforces itself); homeostasis cannot name it"

/-! ## C. Two regulators, time scales, set points -/

/-! ### T01 insulin and glucagon: one loop, two regulators pushing opposite ways (-333) -/
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45537_333
def T01_ins : Claim := .homeostasis insulin (.amount bloodGlucose)
def T01_glc : Claim := .homeostasis glucagon (.amount bloodGlucose)
#guard (homeoFields T01_ins).map (·.2) == (homeoFields T01_glc).map (·.2)
#eval obs "T01" s!"two separate claims, '{T01_ins}' and '{T01_glc}'; nothing says they are one loop, or that insulin lowers and glucagon raises"

/-! ### T02 PTH and calcitonin on blood calcium -/
def T02_pth : Claim := .homeostasis pth (.amount bloodCalcium)
def T02_ct : Claim := .homeostasis calcitonin (.amount bloodCalcium)
#guard (homeoFields T02_pth).map (·.2) == (homeoFields T02_ct).map (·.2)
#eval obs "T02" s!"as T01: two claims; the opposite directions live only in the arms (-140, -135)"

/-! ### T03 several effectors of one loop (thermoregulation; Morrison 2019, PMID 30256726) -/
abbrev s61 := R2.TheBodySSystemsA.the_body_s_systems_m45534_61
#guard (match s61.claim with | .effect _ .neg (.phenotype p) => p.curie == "PATO:0000146" | _ => false)
#fb_no_lean TheBodySSystemsA the_body_s_systems_m45534_78
#fb_no_lean TheBodySSystemsA the_body_s_systems_m45534_79
def T03_loop : Claim := .homeostasis (hypothalamus.inCtx { taxon := Taxa.mammalia }) (.phenotype bodyTemp)
#eval obs "T03" s!"'{T03_loop}' compiles; its effectors (vasodilation '{s61.claim}', vasoconstriction, shivering, sweating) cannot be attached, nor which fires on which side of the set point; -78 and -79 (the 'or' sentences) have no Lean"

/-! ### T04 a set point moved by another loop's variable (Kondo 2004, PMID 14613925) -/
def T04_shift : Statement := ⟨"syn:T04", "hypovolemia lowers the plasma Na threshold for ADH release",
  .effect hypovolemia .pos (.amount adh), [paper 14613925 2004 .mechanistic "Kondo 2004 (rats): thresholds of plasma Na for AVP release decreased only in the acute hypovolemia group"]⟩
#eval obs "T04" s!"the nearest core claim is '{T04_shift.claim}', which says something else: the threshold (set point) moved, not the level"

/-! ### T05 a slow loop on the gain: receptor down-regulation (textbook -328; Gavin 1974, PMID 4359334) -/
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45537_328
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45537_82
def insulinReceptor : Entity .protein := ⟨"PR:000009064", "insulin receptor"⟩
def gavin : Evidence := paper 4359334 1974 .inVitro
  "Gavin 1974: chronic (5-16 hr) insulin exposure lowered insulin receptor concentrations; acute exposure (0-2 hr) was without effect"
def T05_slow : Statement := ⟨"syn:T05", "insulin lowers insulin receptor number (over hours)",
  .effect insulin .neg (.amount insulinReceptor), [gavin]⟩
/-- The fast arm -52 (glucose raises insulin, minutes) chained with the slow arm (hours). -/
def T05_chain : Derivation (.effect glucose .neg (.amount insulinReceptor)) :=
  .viaAmount (.lit R2.TheBodySSystemsB.the_body_s_systems_m45537_52) (.lit T05_slow)
theorem T05_belief : T05_chain.opinion.belief = 2 / 5 := by decide +kernel
#guard shape T05_slow.claim == shape R2.TheBodySSystemsB.the_body_s_systems_m45537_52.claim
#eval obs "T05" s!"-328 and -82 (class-level: any hormone, its receptor) have no Lean (pinned); for insulin the slow arm compiles and the core derives '{T05_chain.claim}' {ostr T05_chain.opinion}, true only for a sustained rise (Gavin 1974: no effect at 0-2 hr); no claim carries a time scale"

/-! ### S01 a set point as a measure (Protsiv 2020, PMID 31908267) -/
def S01_canon : Statement := ⟨"syn:S01-1868", "human body temperature is 37 °C",
  .measure Taxa.human bodyTemp 37 37 "°C", [paper 31908267 2020 .observational "Protsiv 2020: the canonical 37°C established in the 19th century"]⟩
#guard shape S01_canon.claim == "measure"
#eval obs "S01" s!"'{S01_canon.claim}' compiles as a measure; no field ties it to the loop '{T03_loop}', and Protsiv finds the mean falling 0.03 °C per birth decade"

/-! ### S02 fever: pyrogens move the set point (textbook -82 to -92; Cabanac 2006, PMID 16540712) -/
#fb_no_lean TheBodySSystemsA the_body_s_systems_m45534_85
#fb_no_lean TheBodySSystemsA the_body_s_systems_m45534_92
def S02_effect : Statement := ⟨"the-body-s-systems-m45534-92", "pyrogens raise body temperature",
  .effect pyrogen .pos (.phenotype bodyTemp), [tb "Pyrogens reset the body’s thermostat to a higher temperature, resulting in fever."]⟩
#eval obs "S02" s!"the best the core can say is '{S02_effect.claim}'; 'reset the thermostat' has no claim; R2/R3 have no Lean for -85 or -92 (NCIT pyrogen unsupported)"

/-! ### S03 heat stroke looks like fever (Biddle 2006, PMID 16617919) -/
def S03_heat : Statement := ⟨"syn:S03", "a hot environment raises body temperature",
  .effect hotEnvironment .pos (.phenotype bodyTemp), [paper 16617919 2006 .review "Biddle 2006: fever differs from hyperthermia associated with hot environs"]⟩
#guard shape S03_heat.claim == shape S02_effect.claim
#guard (match S02_effect.claim, S03_heat.claim with | .effect _ s₁ t₁, .effect _ s₂ t₂ => s₁ == s₂ && targetCurie t₁ == targetCurie t₂ | _, _ => false)
#eval obs "S03" s!"fever '{S02_effect.claim}' and heat '{S03_heat.claim}' have the same shape, sign and target; the core cannot say one moved the set point and the other overwhelmed the loop"

/-! ## D. Look-alikes: things that are not (homeostatic) loops -/

/-! ### N01 sympathetic and parasympathetic: opposite effects, no loop -/
abbrev s370 := R2.TheBodySSystemsB.the_body_s_systems_m45539_370
abbrev s374 := R2.TheBodySSystemsB.the_body_s_systems_m45539_374
#guard !chainable s370.claim s374.claim && !chainable s374.claim s370.claim
#eval obs "N01" s!"'{s370.claim}' and '{s374.claim}' do not chain and no loop is claimed: right (antagonists, not a loop by themselves)"

/-! ### N02 antibodies and viruses: a negative loop that is not homeostasis -/
abbrev s65 := R2.CellStructureAndFunction.cell_structure_and_function_m45433_65
abbrev s63 := R3.CellStructureAndFunction.cell_structure_and_function_m45433_63
def N02_roundTrip := Derivation.viaAmount (.lit s65) (.lit s63)
theorem N02_belief : N02_roundTrip.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "N02" s!"core derives '{N02_roundTrip.claim}' {ostr N02_roundTrip.opinion}; no homeostasis is claimed (right), but the round trip is an effect (see C03 for the closure)"

/-! ### N03 the word 'feedback' without a loop (cortex and thalamus) -/
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45539_231
#fb_no_lean TheBodySSystemsB the_body_s_systems_m45539_232
#eval obs "N03" "no Lean for -231 or -232 and no loop concluded: right (a neural connection, not a regulated variable)"

/-! ### N04 adrenaline raises blood glucose (-181), so 'raises insulin': wrong (Porte 1966, PMID 5327883; Kris 1966, PMID 4955799) -/
abbrev s181 := R3.TheBodySSystemsB.the_body_s_systems_m45537_181
abbrev s200 := R3.TheBodySSystemsB.the_body_s_systems_m45537_200
abbrev s201 := R3.TheBodySSystemsB.the_body_s_systems_m45537_201
def bgRaisesInsulin := Derivation.isaInheritEffect bgIsaGlucose (.lit s200)
def N04_adrInsulin := Derivation.viaAmount (.lit s181) bgRaisesInsulin
theorem N04_belief : N04_adrInsulin.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "N04" s!"core derives '{N04_adrInsulin.claim}' {ostr N04_adrInsulin.opinion}; catecholamines inhibit insulin release (Porte 1966, Kris 1966): wrong"

/-! ### N05 glucagon raises blood glucose, so 'raises insulin': right (Samols 1965, PMID 14346763) -/
def N05_glcInsulin := Derivation.viaAmount (.lit s201) bgRaisesInsulin
theorem N05_belief : N05_glcInsulin.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "N05" s!"core derives '{N05_glcInsulin.claim}' {ostr N05_glcInsulin.opinion}: right (glucagon promotes insulin secretion)"

/-! ### N06 anticipatory insulin: feed-forward, not feedback (Teff 2011, PMID 21256146) -/
def N06_ff : Statement := ⟨"syn:N06", "taste raises insulin before glucose rises (cephalic phase)",
  .effect tastePerception .pos (.amount insulin), [paper 21256146 2011 .review "Teff 2011: cephalic phase insulin release, an anticipatory response"]⟩
def N06_chain := Derivation.viaAmount (.lit N06_ff) (.lit R3.TheBodySSystemsB.the_body_s_systems_m45537_53)
#guard N06_chain.claim.subjectCurie == "GO:0050909"
theorem N06_belief : N06_chain.opinion.belief = 12 / 25 := by decide +kernel
#eval obs "N06" s!"'{N06_ff.claim}' compiles; the core derives '{N06_chain.claim}' {ostr N06_chain.opinion}, which never returns to taste, so no loop is concluded: right (feed-forward)"

/-! ## E. Synthetic edge cases -/

/-! ### X01 a loop claim with no arms anywhere -/
def X01_loop : Statement := ⟨"syn:X01", "SYNTHETIC: insulin holds blood calcium", .homeostasis insulin (.amount bloodCalcium), [tb "synthetic"]⟩
theorem X01_accepted : (Derivation.lit X01_loop).opinion.belief = 4 / 5 := by decide +kernel
#eval obs "X01" s!"core accepts '{X01_loop.claim}' at b=0.8; nothing asks for the two arms"

/-! ### X02 a loop claim whose stated arms multiply to a positive sign -/
def X02_arm1 : Statement := ⟨"syn:X02-1", "SYNTHETIC: insulin raises blood glucose", .effect insulin .pos (.amount bloodGlucose), [tb "synthetic"]⟩
def X02_arm2 : Statement := ⟨"syn:X02-2", "SYNTHETIC: blood glucose raises insulin", .effect bloodGlucose .pos (.amount insulin), [tb "synthetic"]⟩
def X02_loop : Statement := ⟨"syn:X02", "SYNTHETIC: insulin holds blood glucose", .homeostasis insulin (.amount bloodGlucose), [tb "synthetic"]⟩
def X02_self := Derivation.viaAmount (.lit X02_arm1) (.lit X02_arm2)
#guard Sign.pos * Sign.pos == Sign.pos
#eval obs "X02" s!"core accepts '{X02_loop.claim}' beside arms that make a positive loop ('{X02_self.claim}'); no check of the loop sign"

/-! ### X03 a chain through a loop's variable that uses no arm of the loop -/
def X03_meal : Statement := ⟨"syn:X03-1", "SYNTHETIC: a meal raises blood glucose", .effect e_GO_0042755 .pos (.amount bloodGlucose), [tb "synthetic"]⟩
def X03_store : Statement := ⟨"syn:X03-2", "SYNTHETIC: blood glucose raises glycogen synthesis", .effect bloodGlucose .pos (.process ⟨"GO:0005978", "glycogen biosynthetic process"⟩), [tb "synthetic"]⟩
def X03_chain := Derivation.viaAmount (.lit X03_meal) (.lit X03_store)
theorem X03_belief : X03_chain.opinion.belief = 16 / 25 := by decide +kernel
#eval obs "X03" s!"core derives '{X03_chain.claim}' {ostr X03_chain.opinion}; no loop arm used, nothing to label (right)"

end BioLean.Stress.Feedback
