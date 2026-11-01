import BioLean.Derivation
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR2.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR2.Photosynthesis

/-!
# Stress set 10b: literature at scale (M8)

Program: `docs/programs/10b-literature-at-scale.md`. Case table: `data/stress/10b/cases.tsv`.

52 curated statements from SIGNOR, GO-CAM, Reactome and GOA about entities the textbook already
uses (insulin, glucagon, glucose, calcium, PTH, calcitonin, ATP synthase, sodium channels, ADH), each
mapped to a BioLean statement whose evidence carries its PMID, and compared with the compiled textbook
statements. Plus the M8 exit question, "does metformin extend lifespan in humans?", as far as the core
can take it. Nothing here changes the core.

**Importer M0** (the baseline every case runs; the rules a first M8 importer would use):
* an entity already in biolib is reused by CURIE (`Textbook.R2.e_*`), so labels match; anything else is
  built with its OLS4 label;
* UniProt -> `PR:<acc>` protein; a chain id (`P01275-PRO_0000011256`, a Reactome `GCG(53-81)`) -> the
  precursor `PR:<acc>` (the chain is lost); SIGNOR and Reactome complexes, families and sets -> a
  placeholder curie with no OBO id;
* SIGNOR `up/down-regulates activity` -> `Claim.effect a s (.activity b)`, `quantity` -> `(.amount b)`,
  bare `up/down-regulates` -> activity (a guess); `form complex` and `unknown` -> `Claim.rel`;
* GO-CAM: activity A enabled_by P -[signed causal]-> activity B enabled_by Q gives `effect P s (activity Q)`;
  `part_of` a process gives `rel involved_in`; location facts are lifted as class-level claims;
* Reactome: a reaction is a process (its GO BP cross-reference if it has one, else `Reactome:<id>`);
  inputs and outputs are `rel has_input / has_output`, each participant refined by its compartment;
* evidence: one `curatedDb` item per PMID; GO_REF and Reactome-only evidence get PMID 0.

**Prototypes** (namespace `BioLean.Proto.Literature`, NOT core): importer M1 (fixes outside the core:
complex map, chain map, evidence kind from the source's own flags) and three candidate rules
(`enablesInherit`, `widenProcess`, a shared-PMID lint), to see which marks would flip.

CURIEs checked on OLS4 and PMIDs on Europe PMC on 2026-11-01 (`data/stress/10b/curies_checked.tsv`,
`references_checked.tsv`, `isa_checked.tsv`; re-checked live by the review pass, `review_checked.tsv`). Every
curated record was looked up again in its source extract (`records_checked.tsv`). PMIDs 9000000x are SYNTHETIC.

**Review pass (2026-11-01).** Three records did not match their source and were re-read from it: G02d (the
model's "part_of D-glucose transmembrane transport" fact is GLUT1's; GLUT4's activity is part_of glucose
homeostasis), G11 (the ATP(4-) output belongs to the proton transporter activity, not to ATP synthase
activity), O02 (GOA has no AVP hormone-activity row with an extension; replaced by PTH's real one). Marks
changed: S11 and M08 can be stated in the core (pinned below), Y03 is a missed fusion, G07 carries the same
wrong paper as S07.
-/

namespace BioLean.Stress.Literature
open BioLean Derivation BioLean.Textbook.R2 BioLean.Textbook.R3

/-! ## 0. Helpers -/

/-- One curated record: a curated-database item with its PMID. -/
def cdb (pmid year : Nat) (note : String) (p : Opinion.Polarity := .supports) : Evidence :=
  { pmid, year, kind := .curatedDb, polarity := p, note }
def item (pmid year : Nat) (k : EvidenceKind) (note : String) (p : Opinion.Polarity := .supports) :
    Evidence := { pmid, year, kind := k, polarity := p, note }
def st (id text : String) (c : Claim) (es : List Evidence) : Statement :=
  { id, text, claim := c, evidence := es }

def vn : Verdict → String
  | .established => "established" | .contested => "contested"
  | .refuted => "refuted" | .unsupported => "unsupported"

/-- Same claim, as the kernel sees it (curies, labels, signs, relations, nesting all equal). When this is
true, `Derivation.both` of the two statements type-checks and their evidence fuses. -/
def sameClaim (a b : Statement) : Bool := toString a.claim == toString b.claim
/-- Same subject curie: the curated statement is at least about the textbook's entity. -/
def meets (a b : Statement) : Bool := a.claim.subjectCurie == b.claim.subjectCurie

def show3 (o : Opinion) : String :=
  s!"b={o.belief.toDecimal 2} d={o.disbelief.toDecimal 2} {vn o.verdict}"

/-! ## 1. Entities (importer M0)

Reused from biolib by curie: `e_PR_P01275` (labelled "glucagon"; OLS4: pro-glucagon (human)),
`e_PR_P01258` ("calcitonin"; OLS4: calcitonin isoforms 1/2 (human)), `e_PR_000009054` ("insulin";
OLS4: preproinsulin), `e_PR_000013429`, `e_CHEBI_17234` glucose, `e_CHEBI_29108` calcium(2+),
`e_CHEBI_29101` sodium(1+), `e_CHEBI_15422` ATP, `e_CHEBI_34543` ("antidiuretic hormone"; OLS4:
argipressin), `e_GO_0098708`, `e_GO_0005248`, `e_GO_0045259`, `e_GO_0046933`, `e_GO_0015986`,
`e_GO_0015985`, `e_UBERON_0000178` blood, `e_CL_0000169`, `e_CL_0000171`, `e_GO_0005829` cytosol,
`e_GO_0005576` (biolib label "extracellular fluid"; OLS4: extracellular region). New ones carry their OLS4 label. -/
namespace E
def ins     : Entity .protein := ⟨"PR:P01308", "preproinsulin (human)"⟩
def insr    : Entity .protein := ⟨"PR:P06213", "insulin receptor (human)"⟩
def irs1    : Entity .protein := ⟨"PR:P35568", "insulin receptor substrate 1 (human)"⟩
def pik3cg  : Entity .protein := ⟨"PR:P48736", "phosphatidylinositol 4,5-bisphosphate 3-kinase catalytic subunit gamma isoform (human)"⟩
def glut4   : Entity .protein := ⟨"PR:P14672", "solute carrier family 2, facilitated glucose transporter member 4 (human)"⟩
def gcgr    : Entity .protein := ⟨"PR:P47871", "glucagon receptor (human)"⟩
def pth     : Entity .protein := ⟨"PR:P01270", "parathyroid hormone (human)"⟩
def pth1r   : Entity .protein := ⟨"PR:Q03431", "parathyroid hormone/parathyroid hormone-related peptide receptor (human)"⟩
def casr    : Entity .protein := ⟨"PR:P41180", "extracellular calcium-sensing receptor (human)"⟩
def gnai1   : Entity .protein := ⟨"PR:P63096", "guanine nucleotide-binding protein G(i) subunit alpha-1 (human)"⟩
def gnas    : Entity .protein := ⟨"PR:P63092", "guanine nucleotide-binding protein G(s) subunit alpha isoforms Gnas-1/Gnas-2/3/4 (human)"⟩
def prkaca  : Entity .protein := ⟨"PR:P17612", "cAMP-dependent protein kinase catalytic subunit alpha (human)"⟩
def trpv5   : Entity .protein := ⟨"PR:Q9NQA5", "transient receptor potential cation channel subfamily V member 5 (human)"⟩
def calcr   : Entity .protein := ⟨"PR:P30988", "calcitonin receptor (human)"⟩
def avp     : Entity .protein := ⟨"PR:P01185", "vasopressin-neurophysin 2-copeptin (human)"⟩
def avpr2   : Entity .protein := ⟨"PR:P30518", "vasopressin V2 receptor (human)"⟩
def scn1a   : Entity .protein := ⟨"PR:P35498", "sodium channel protein type 1 subunit alpha (human)"⟩
def fabp4   : Entity .protein := ⟨"PR:P15090", "fatty acid-binding protein, adipocyte (human)"⟩
def prkaa1  : Entity .protein := ⟨"PR:Q13131", "5'-AMP-activated protein kinase catalytic subunit alpha-1 (human)"⟩
def ndufs1  : Entity .protein := ⟨"PR:P28331", "NADH-ubiquinone oxidoreductase 75 kDa subunit, mitochondrial (human)"⟩
def g6pc1   : Entity .protein := ⟨"PR:P35575", "glucose-6-phosphatase catalytic subunit 1 (human)"⟩
def pck1    : Entity .protein := ⟨"PR:P35558", "phosphoenolpyruvate carboxykinase, cytosolic [GTP] (human)"⟩
/-- Worm AMPK. Not in PR, so the UniProt id stays (QuickGO gene product Q95ZQ4, aak-2). -/
def aak2    : Entity .protein := ⟨"UniProtKB:Q95ZQ4", "aak-2 (C. elegans)"⟩
/-- SIGNOR complex SIGNOR-C264: no OBO id under M0. A complex is a `component` here. -/
def atpSynthaseC264 : Entity .component := ⟨"SIGNOR:SIGNOR-C264", "ATP synthase (SIGNOR complex)"⟩
def aGlucose : Entity .chemical := ⟨"CHEBI:17925", "alpha-D-glucose"⟩
def glcp     : Entity .chemical := ⟨"CHEBI:4167", "D-glucopyranose"⟩
def vasopressin : Entity .chemical := ⟨"CHEBI:9937", "vasopressin"⟩
def atp4     : Entity .chemical := ⟨"CHEBI:30616", "ATP(4-)"⟩
def glucagonPeptide : Entity .chemical := ⟨"CHEBI:5391", "glucagon"⟩
def metformin : Entity .chemical := ⟨"CHEBI:6801", "metformin"⟩
def lifespan : Entity .phenotype := ⟨"PATO:0000050", "life span"⟩
def worm     : Entity .taxon := ⟨"NCBITaxon:6239", "Caenorhabditis elegans"⟩
def t2d      : Entity .disease := ⟨"MONDO:0005148", "type 2 diabetes mellitus"⟩
def glcTransport : Entity .process := ⟨"GO:1904659", "D-glucose transmembrane transport"⟩
def pmfMitoAtp : Entity .process := ⟨"GO:0042776", "proton motive force-driven mitochondrial ATP synthesis"⟩
def insulinSecretion : Entity .process := ⟨"GO:0030073", "insulin secretion"⟩
def adultLifespan : Entity .process := ⟨"GO:0008340", "determination of adult lifespan"⟩
def mitoMatrix : Entity .component := ⟨"GO:0005759", "mitochondrial matrix"⟩
def cytoplasm  : Entity .component := ⟨"GO:0005737", "cytoplasm"⟩
def plasmaMembrane : Entity .component := ⟨"GO:0005886", "plasma membrane"⟩
def proteinComplex : Entity .component := ⟨"GO:0032991", "protein-containing complex"⟩
def zfaBetaCell : Entity .cellType := ⟨"ZFA:0009102", "pancreatic B cell"⟩
def hormoneActivity : Entity .function := ⟨"GO:0005179", "hormone activity"⟩
def glucoseHomeostasis : Entity .process := ⟨"GO:0042593", "glucose homeostasis"⟩
def gpcrAcSignal : Entity .process := ⟨"GO:0007189", "adenylate cyclase-activating G protein-coupled receptor signaling pathway"⟩
def hydron : Entity .chemical := ⟨"CHEBI:15378", "hydron"⟩
def calcitoninBinding : Entity .function := ⟨"GO:0032841", "calcitonin binding"⟩
def protonTransporterAct : Entity .function := ⟨"GO:0015078", "proton transmembrane transporter activity"⟩
/-- A Reactome reaction with no GO cross-reference: a process with a database id, not an OBO id. -/
def rx (id label : String) : Entity .process := ⟨s!"Reactome:{id}", label⟩
/-- A Reactome complex or set: a placeholder with no OBO id. -/
def rc (id label : String) : Entity .component := ⟨s!"Reactome:{id}", label⟩
end E

def enabledBy : Rel := ⟨.ro, 2333, false⟩
def causallyUpstreamOf : Rel := ⟨.ro, 2411, false⟩
def causallyInfluences : Rel := ⟨.ro, 2566, false⟩

/-! ## 2. Textbook statements compared against (compiled biolib, rounds 2 and 3) -/

def tbInsulinLowersGlucose := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45537_53
def tbGlucoseRaisesInsulin := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45537_200
def tbGlucoseLowersGlucagon := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45537_199
def tbGlucagonRaisesGlucose := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45537_201
def tbCalcitoninLowersCa := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45537_135
def tbPthRaisesCa := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45537_140
def tbCaLowersPth := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45537_141
def tbInsulinGlucoseImport := BioLean.Textbook.R2.TheBodySSystemsB.the_body_s_systems_m45537_202
def tbHypothalamusAdh := BioLean.Textbook.R2.TheBodySSystemsB.the_body_s_systems_m45537_99
def tbNaChannelNa := BioLean.Textbook.R2.TheBodySSystemsB.the_body_s_systems_m45539_90
def tbAtpSynthaseAtp := BioLean.Textbook.R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45439_72
def tbPmfAtpOutput := BioLean.Textbook.R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45439_74
def tbProtonsPowerAtpSynthase := BioLean.Textbook.R2.Photosynthesis.photosynthesis_m45452_91

-- what the textbook statements say, pinned, so a re-emission of the book shows up here
#guard toString tbInsulinLowersGlucose.claim == "insulin [PR:000009054] →− amount of glucose ⊓ located in (blood) [CHEBI:17234&RO:0001025=(UBERON:0000178)]"
#guard tbGlucoseLowersGlucagon.claim.subjectCurie == "CHEBI:17234"
#guard toString tbAtpSynthaseAtp.claim == "ATP synthase [GO:0045259] →+ amount of ATP [CHEBI:15422]"
#guard toString tbNaChannelNa.claim == "voltage-gated sodium channel activity [GO:0005248] →+ amount of sodium [CHEBI:29101]"
#guard toString tbPmfAtpOutput.claim == "proton motive force-driven ATP synthesis [GO:0015986] has output ATP [CHEBI:15422]"
#guard toString tbInsulinGlucoseImport.claim == "insulin [PR:000009054] →+ glucose import [GO:0098708]"

/-! ## 3. SIGNOR (NDEx release 26-Nov-2025, CC BY-SA 4.0) -/

/-- S01. INS up-regulates activity INSR (SIGNOR, binding, direct), and the same fact in GO-CAM
(gomodel:6a18a9ba00001280: hormone activity enabled_by INS directly positively regulates insulin
receptor activity enabled_by INSR, ECO:0000303). -/
def S01s := st "S01-signor" "INS up-regulates activity INSR" (.effect E.ins .pos (.activity E.insr))
  [cdb 2550426 1989 "SIGNOR; binding; direct", cdb 16956584 2006 "SIGNOR; binding; direct"]
def S01g := st "S01-gocam" "INS hormone activity directly positively regulates INSR activity"
  (.effect E.ins .pos (.activity E.insr)) [cdb 14986111 2004 "GO-CAM 6a18a9ba00001280; ECO:0000303"]
def S01 : Derivation S01s.claim := .both (.lit S01s) (.lit S01g)
#guard sameClaim S01s S01g
#guard S01s.opinion.belief == 8/9 ∧ S01.opinion.belief == 12/13
#guard S01.pmids == [2550426, 16956584, 14986111]

/-- S02. INS up-regulates activity SLC2A4 (indirect; SIGNOR's sentence is about adipose cells) and SLC2A4 up-regulates
quantity glucose (relocalization). Chained by `viaActivity`. -/
def S02a := st "S02a" "INS up-regulates activity SLC2A4" (.effect E.ins .pos (.activity E.glut4))
  [cdb 9415393 1997 "SIGNOR; indirect; BTO:0000887 muscle"]
def S02b := st "S02b" "SLC2A4 up-regulates quantity glucose (relocalization)"
  (.effect E.glut4 .pos (.amount e_CHEBI_17234)) [cdb 17403369 2007 "SIGNOR; relocalization"]
def S02 : Derivation (.effect E.ins .pos (.amount e_CHEBI_17234)) := .viaActivity (.lit S02a) (.lit S02b)
-- derived: insulin raises the amount of glucose (no location); the textbook says insulin lowers blood glucose
#guard toString S02.claim == "preproinsulin (human) [PR:P01308] →+ amount of glucose [CHEBI:17234]"
#guard S02.opinion.belief == 16/25 ∧ S02.opinion.verdict == .unsupported
#guard !(toString S02.claim == toString tbInsulinLowersGlucose.claim)

/-- S03. calcium(2+) up-regulates quantity INS (relocalization; BTO:0000783 pancreatic beta cell, dropped). -/
def S03 := st "S03" "calcium(2+) up-regulates quantity INS" (.effect e_CHEBI_29108 .pos (.amount E.ins))
  [cdb 24843404 2010 "SIGNOR; relocalization; BTO:0000783 pancreatic beta cell (dropped by M0)"]
#guard !meets S03 tbGlucoseRaisesInsulin ∧ !sameClaim S03 tbGlucoseRaisesInsulin
-- the beta-cell context fits the core (`Ctx.cellType`), so M1 can keep it
example : Claim := .effect e_CHEBI_29108 .pos (.amount (E.ins.inCtx { cellType := e_CL_0000169 }))

/-- S04. alpha-D-glucose up-regulates quantity GCG (PMID 31693916; the sentence is about GLP-1). -/
def S04 := st "S04" "alpha-D-glucose up-regulates quantity GCG" (.effect E.aGlucose .pos (.amount e_PR_P01275))
  [cdb 31693916 2020 "SIGNOR; BTO:0000783; sentence: incretins GIP and GLP-1 are secreted in response to glucose"]
#guard !meets S04 tbGlucoseLowersGlucagon ∧ !sameClaim S04 tbGlucoseLowersGlucagon
-- OLS4 says alpha-D-glucose is_a glucose; the core's imported is_a closure does not know it
#guard Ontology.isACurie "CHEBI:17925" "CHEBI:17234" == false

/-- S05. GCG up-regulates GCGR (SIGNOR, binding, bare) and GO-CAM glucagon hormone activity
(enabled_by P01275-PRO_0000011256, read as the precursor) directly positively regulates GCGR. -/
def S05s := st "S05-signor" "GCG up-regulates GCGR" (.effect e_PR_P01275 .pos (.activity E.gcgr))
  [cdb 22863277 2012 "SIGNOR; binding; bare up-regulates read as activity", cdb 12529935 2002 "SIGNOR"]
def S05g := st "S05-gocam" "glucagon hormone activity directly positively regulates GCGR activity"
  (.effect e_PR_P01275 .pos (.activity E.gcgr)) [cdb 32193322 2020 "GO-CAM 68d5ebd600000298; chain PRO_0000011256 -> precursor"]
def S05 : Derivation S05s.claim := .both (.lit S05s) (.lit S05g)
#guard sameClaim S05s S05g ∧ meets S05s tbGlucagonRaisesGlucose
#guard S05.opinion.belief == 12/13

/-- S06. PTH up-regulates PTH1R (SIGNOR, binding) and GO-CAM PTH hormone activity -> PTH1R. -/
def S06s := st "S06-signor" "PTH up-regulates PTH1R" (.effect E.pth .pos (.activity E.pth1r))
  [cdb 18981475 2008 "SIGNOR; binding; bare up-regulates read as activity"]
def S06g := st "S06-gocam" "PTH hormone activity directly positively regulates PTH1R activity"
  (.effect E.pth .pos (.activity E.pth1r)) [cdb 35932760 2022 "GO-CAM 69ea894900002023"]
def S06 : Derivation S06s.claim := .both (.lit S06s) (.lit S06g)
#guard sameClaim S06s S06g ∧ S06.opinion.belief == 8/9
-- but the textbook's PTH is the species-neutral PR:000013429, so the subject does not meet
#guard !meets S06s tbPthRaisesCa

/-- S07. AVP up-regulates AVPR2 (SIGNOR). Its PMID 1560825 is "Molecular cloning and expression of a
rat V1a arginine vasopressin receptor": another receptor, another species. -/
def S07 := st "S07" "AVP up-regulates AVPR2" (.effect E.avp .pos (.activity E.avpr2))
  [cdb 1560825 1992 "SIGNOR; binding; paper is on the rat V1a receptor"]
#guard S07.opinion.verdict == .established ∧ S07.pmids == [1560825]

/-- S08. vasopressin (CHEBI:9937) up-regulates activity AVPR2 (SIGNOR, a 148-receptor screen). -/
def S08 := st "S08" "vasopressin up-regulates activity AVPR2" (.effect E.vasopressin .pos (.activity E.avpr2))
  [cdb 31160049 2019 "SIGNOR; chemical activation; HEK293 screen"]
#guard !sameClaim S08 S07 ∧ !meets S08 S07 ∧ !meets S08 tbHypothalamusAdh
-- three ids for one hormone: textbook CHEBI:34543 argipressin, SIGNOR CHEBI:9937 and UniProt P01185.
-- The core's is_a closure knows the ChEBI pair; nothing links either to the UniProt precursor.
#guard Ontology.isACurie "CHEBI:34543" "CHEBI:9937" == true

/-- S09. SCN1A up-regulates quantity sodium(1+) (relocalization). The textbook says the same of the GO
function (GO:0005248); GOA says SCN1A enables GO:0005248 (IMP, PMID 14672992, case O01). -/
def S09 := st "S09" "SCN1A up-regulates quantity sodium(1+)" (.effect E.scn1a .pos (.amount e_CHEBI_29101))
  [cdb 27262167 2016 "SIGNOR; relocalization"]
#guard !meets S09 tbNaChannelNa ∧ !sameClaim S09 tbNaChannelNa

/-- S10. ATP synthase (SIGNOR-C264) up-regulates quantity ATP. Under M0 the complex has no OBO id. -/
def S10 := st "S10" "ATP synthase up-regulates quantity ATP" (.effect E.atpSynthaseC264 .pos (.amount e_CHEBI_15422))
  [cdb 21874297 2012 "SIGNOR; chemical modification"]
#guard !sameClaim S10 tbAtpSynthaseAtp

/-- S11. hydron up-regulates activity ATP synthase. The target is a complex; `Target.activity` takes a
protein or a GO function only, so M0's complex placeholder cannot be the target (`by decide` fails on the
kind) and M0 drops the edge. The core can state it: map the complex's activity to its GO function, as the
textbook itself does in m45452-91 ("the hydrogen ion stream powers ATP synthase activity"). -/
example : ¬ (Kind.component = .protein ∨ Kind.component = .function) := by decide
def S11m1 := st "S11-M1" "hydron up-regulates ATP synthase activity" (.effect E.hydron .pos (.activity e_GO_0046933))
  [cdb 31115493 2019 "SIGNOR; SIGNOR-C264 activity mapped to GO:0046933"]
-- stated, but its subject (a chemical) is not the textbook's (a GO process), so nothing fuses
#guard S11m1.opinion.verdict == .established ∧ !meets S11m1 tbProtonsPowerAtpSynthase
#guard toString tbProtonsPowerAtpSynthase.claim == "energy coupled proton transport, down electrochemical gradie [GO:0015985] →+ activity of ATP synthase [GO:0046933]"

/-- S12. metformin up-regulates quantity (by expression) G6PC1. The SIGNOR sentence from PMID 17909097
says metformin "inhibited the expression of the hepatic gluconeogenic genes pepck and g6pase": the
sign is wrong. SIGNOR's PCK1 edge from the same paper has the right sign. -/
def S12 := st "S12" "metformin up-regulates quantity G6PC1" (.effect E.metformin .pos (.amount E.g6pc1))
  [cdb 17909097 2008 "SIGNOR; sentence: metformin ... inhibited the expression of ... pepck and g6pase"]
def S12pck := st "S12-pck1" "metformin down-regulates quantity PCK1" (.effect E.metformin .neg (.amount E.pck1))
  [cdb 17909097 2008 "SIGNOR; same sentence"]
#guard S12.opinion.verdict == .established ∧ S12pck.opinion.verdict == .established

/-- S13. INSR "unknown" (phosphorylation) FABP4: no sign. Stated as `Claim.rel causally influences`. -/
def S13 := st "S13" "INSR causally influences FABP4 (sign unknown)" (.rel causallyInfluences E.insr E.fabp4)
  [cdb 1648089 1991 "SIGNOR; unknown; phosphorylation Tyr20"]
#guard S13.opinion.verdict == .established

/-- S14. Two edges from one high-throughput paper (PMID 31160049): vasopressin -> AVPR2 (S08) and
AVPR2 -> GNAS. The chain treats them as independent. -/
def S14b := st "S14b" "AVPR2 up-regulates activity GNAS" (.effect E.avpr2 .pos (.activity E.gnas))
  [cdb 31160049 2019 "SIGNOR; binding; HEK293 screen"]
def S14 : Derivation (.effect E.vasopressin .pos (.activity E.gnas)) := .viaActivity (.lit S08) (.lit S14b)
#guard S14.pmids == [31160049] ∧ S14.sharedAxioms == [] ∧ S14.opinion.belief == 16/25

/-! ## 4. GO-CAM (CC BY 4.0, GO Consortium; models fetched 2026-10-30 from api.geneontology.org) -/

-- G02. gomodel:6a18a9ba00001280, insulin to glucose uptake in skeletal muscle (Human)
def G02a := st "G02-insr-irs1" "INSR activity directly positively regulates IRS1 adaptor activity"
  (.effect E.insr .pos (.activity E.irs1)) [cdb 38056462 2023 "GO-CAM 6a18a9ba00001280; ECO:0000314"]
def G02b := st "G02-irs1-pi3k" "IRS1 adaptor activity directly positively regulates PI3K activity (PIK3CG)"
  (.effect E.irs1 .pos (.activity E.pik3cg)) [cdb 7493946 1995 "GO-CAM; ECO:0000314"]
def G02c := st "G02-pi3k-glut4" "PI3K activity indirectly positively regulates D-glucose transporter activity (SLC2A4)"
  (.effect E.pik3cg .pos (.activity E.glut4)) [cdb 11277933 2001 "GO-CAM; ECO:0000314; paper is on PI4K92"]
/-- The model puts GLUT4's D-glucose transporter activity part_of glucose homeostasis (PMID 14562105, Bogan
2003, a GLUT4 paper). Its "part_of D-glucose transmembrane transport" fact is enabled by GLUT1 (P11166,
PMID 18245775, a GLUT1 paper), so it is not about this chain. -/
def G02d := st "G02-glut4-bp" "GLUT4 D-glucose transporter activity part_of glucose homeostasis"
  (.rel Rel.involvedIn E.glut4 E.glucoseHomeostasis) [cdb 14562105 2003 "GO-CAM 6a18a9ba00001280; ECO:0000314"]
def G02 : Derivation (.effect E.ins .pos (.activity E.glut4)) :=
  .viaActivity (.lit S01g) (.viaActivity (.lit G02a) (.viaActivity (.lit G02b) (.lit G02c)))
#guard G02.opinion.belief == 256/625 ∧ G02.opinion.verdict == .unsupported
-- the chain ends at an activity; the model's GLUT4 fact is about glucose homeostasis, not glucose import
#guard !meets G02d tbInsulinGlucoseImport
#guard toString G02d.claim == "solute carrier family 2, facilitated glucose transporter member 4 (human) [PR:P14672] involved in glucose homeostasis [GO:0042593]"

-- G03, G04. gomodel:69ea894900002023, CASR suppresses PTH (Human)
def G03a := st "G03-ca-casr" "calcium(2+) is small molecule activator of CASR GPCR activity"
  (.effect e_CHEBI_29108 .pos (.activity E.casr)) [cdb 38632411 2024 "GO-CAM 69ea894900002023; RO:0012005"]
def G03b := st "G03-casr-gi" "CASR GPCR activity directly positively regulates G protein activity (GNAI1)"
  (.effect E.casr .pos (.activity E.gnai1)) [cdb 38632411 2024 "GO-CAM; RO:0002629"]
def G03c := st "G03-gi-pth" "G protein activity (GNAI1) indirectly negatively regulates PTH hormone activity"
  (.effect E.gnai1 .neg (.activity E.pth)) [cdb 15331768 2004 "GO-CAM; RO:0002409; paper is on neuromedin U receptors"]
def G03 : Derivation (.effect e_CHEBI_29108 .neg (.activity E.pth)) :=
  .viaActivity (.lit G03a) (.viaActivity (.lit G03b) (.lit G03c))
-- the sign algebra gives the right sign: raised calcium lowers PTH
#guard toString G03.claim == "calcium [CHEBI:29108] →− activity of parathyroid hormone (human) [PR:P01270]"
#guard G03.opinion.belief == 64/125
-- but not the textbook claim: activity vs amount in blood, PR:P01270 vs PR:000013429; and one PMID twice
#guard !(toString G03.claim == toString tbCaLowersPth.claim) ∧ meets G03a tbCaLowersPth
#guard G03.pmids == [38632411, 15331768] ∧ G03.sharedAxioms == []

-- G05, G06. same model: PTH to TRPV5 in the distal tubule
def G05a := st "G05-pth1r-gs" "PTH1R activity directly positively regulates G protein activity (GNAS)"
  (.effect E.pth1r .pos (.activity E.gnas)) [cdb 19674967 2009 "GO-CAM; RO:0002629"]
def G05b := st "G05-gs-pka" "G protein activity (GNAS) indirectly positively regulates PKA activity (PRKACA)"
  (.effect E.gnas .pos (.activity E.prkaca)) [cdb 10200251 1999 "GO-CAM; RO:0002407"]
def G06 := st "G06-pka-trpv5" "PKA activity directly positively regulates calcium channel activity (TRPV5)"
  (.effect E.prkaca .pos (.activity E.trpv5)) [cdb 11029056 2000 "GO-CAM; RO:0002629; paper is on MAP2c localisation"]
def G05 : Derivation (.effect E.pth .pos (.activity E.trpv5)) :=
  .viaActivity (.lit S06g) (.viaActivity (.lit G05a) (.viaActivity (.lit G05b) (.lit G06)))
#guard G05.opinion.belief == 256/625 ∧ !meets S06g tbPthRaisesCa
#guard G06.opinion.verdict == .established ∧ G06.pmids == [11029056]

-- G07. AVP -> AVPR2 in GO-CAM (gomodel:67e5e74400004286); fuses with SIGNOR's S07
def G07g := st "G07-gocam" "AVP hormone activity directly positively regulates vasopressin receptor activity (AVPR2)"
  (.effect E.avp .pos (.activity E.avpr2)) [cdb 33742150 2021 "GO-CAM 67e5e74400004286; chain PRO_0000020515 -> precursor"]
def G07 : Derivation S07.claim := .both (.lit S07) (.lit G07g)
#guard sameClaim S07 G07g ∧ G07.opinion.belief == 8/9 ∧ G07.pmids == [1560825, 33742150]

-- G08. calcitonin -> CALCR (gomodel:66b5638000001772); the model ends at cAMP
def G08 := st "G08" "calcitonin hormone activity directly positively regulates calcitonin receptor activity"
  (.effect e_PR_P01258 .pos (.activity E.calcr)) [cdb 32296767 2020 "GO-CAM 66b5638000001772; paper is on adrenomedullin receptors"]
#guard meets G08 tbCalcitoninLowersCa ∧ !sameClaim G08 tbCalcitoninLowersCa

-- G09. location facts of individuals, lifted to class level (gomodel:6a18a9ba00001280)
def G09a := st "G09a" "glucose located_in cytoplasm" (.rel Rel.locatedIn e_CHEBI_17234 E.cytoplasm)
  [cdb 19251038 2009 "GO-CAM; an individual's location"]
def G09b := st "G09b" "glucose located_in extracellular region" (.rel Rel.locatedIn e_CHEBI_17234 e_GO_0005576)
  [cdb 19251038 2009 "GO-CAM; an individual's location"]
-- both accepted as "every glucose is in some cytoplasm" and "... in some extracellular region"
#guard G09a.opinion.verdict == .established ∧ G09b.opinion.verdict == .established

-- G10. zebrafish anatomy in a human model
def G10 := st "G10" "plasma membrane part_of pancreatic B cell (ZFA)" (.rel Rel.partOf E.plasmaMembrane E.zfaBetaCell)
  [cdb 40811462 2025 "GO-CAM 6a18a9ba00001280; ZFA term in a human model"]
#guard G10.opinion.verdict == .established ∧ G10.claim.subjectCurie == "GO:0005886"

-- G11. Reactome-imported GO-CAM (R-HSA-163210): the ATP(4-) output sits on a proton transmembrane
-- transporter activity enabled by a generic complex (the import types the "ATP is released" step that way);
-- the ATP synthase activity individual has_output water
def G11 := st "G11" "proton transmembrane transporter activity (enabled_by protein-containing complex) has_output ATP(4-)"
  (.rel Rel.hasOutput (E.protonTransporterAct.refine enabledBy E.proteinComplex) E.atp4)
  [{ pmid := 0, year := 2026, kind := .curatedDb, note := "GO-CAM R-HSA-163210; ECO:0000313; sources Reactome:R-HSA-163210, R-HSA-164834" }]
#guard !sameClaim G11 tbPmfAtpOutput ∧ !meets G11 tbPmfAtpOutput
#guard Ontology.isACurie "CHEBI:30616" "CHEBI:15422" == false

-- G12. unsigned causal: proton transporter activity causally upstream of ATP synthase activity
def G12 := st "G12" "proton transmembrane transporter activity causally upstream of ATP synthase activity"
  (.rel causallyUpstreamOf E.protonTransporterAct e_GO_0046933)
  [{ pmid := 0, year := 2026, kind := .curatedDb, note := "GO-CAM R-HSA-163210; RO:0002411; ECO:0000313" }]
#guard !sameClaim G12 tbProtonsPowerAtpSynthase

/-! ## 5. Reactome (release 98, CC0) -/

/-- R01. GLUT4 tetramer transports Glc from extracellular region to cytosol (R-HSA-8981570). M0
grounds the reaction to its GO cross-reference GO:1904659, so the claim reads "every D-glucose
transmembrane transport takes glucose from outside the cell", which GLUT2 efflux (R02) contradicts. -/
def R01in := st "R01-in" "D-glucose transmembrane transport has_input Glc [extracellular region]"
  (.rel Rel.hasInput E.glcTransport (E.glcp.inCtx { component := e_GO_0005576 }))
  [cdb 1756912 1991 "Reactome R-HSA-8981570", cdb 11994746 2002 "Reactome", cdb 1918382 1991 "Reactome", cdb 2656669 1989 "Reactome"]
def R01out := st "R01-out" "D-glucose transmembrane transport has_output Glc [cytosol]"
  (.rel Rel.hasOutput E.glcTransport (E.glcp.inCtx { component := e_GO_0005829 }))
  [cdb 1756912 1991 "Reactome R-HSA-8981570"]
#guard R01in.opinion.verdict == .established ∧ R01in.opinion.belief == 16/17
#guard Ontology.isACurie "CHEBI:4167" "CHEBI:17234" == false

/-- R02. GLUT2 transports Glc from cytosol to extracellular region (R-HSA-450095, no GO cross-reference):
the last step of the liver's glucose release. -/
def R02 := st "R02" "R-HSA-450095 has_output Glc [extracellular region]"
  (.rel Rel.hasOutput (E.rx "R-HSA-450095" "GLUT2 transports Glc from cytosol to extracellular region")
    (E.glcp.inCtx { component := e_GO_0005576 }))
  [cdb 8457197 1993 "Reactome", cdb 9751501 1998 "Reactome", cdb 9354798 1997 "Reactome"]
#guard !meets R02 tbGlucagonRaisesGlucose

/-- R03. Insulin binds the insulin receptor (R-HSA-74716): two complexes in, one complex out. -/
def R03 := st "R03" "R-HSA-74716 has_input Insulin [extracellular region] (complex)"
  (.rel Rel.hasInput (E.rx "R-HSA-74716" "Insulin binds the insulin receptor") (E.rc "R-HSA-74674" "Insulin (complex)"))
  [cdb 11737239 2001 "Reactome", cdb 7781591 1995 "Reactome"]
#guard !meets R03 S01s

/-- R04. Enzyme-bound ATP is released (R-HSA-164834; GO cross-reference GO:0042776; no PMID). -/
def R04 := st "R04" "proton motive force-driven mitochondrial ATP synthesis has_output ATP(4-) [mitochondrial matrix]"
  (.rel Rel.hasOutput E.pmfMitoAtp (E.atp4.inCtx { component := E.mitoMatrix }))
  [{ pmid := 0, year := 2026, kind := .curatedDb, note := "Reactome R-HSA-164834; no literature reference" }]
/-- The textbook's has_output passes down to the subprocess by the core's is_a law (OLS4: GO:0042776
is_a GO:0015986), but the objects still differ (ATP vs ATP(4-) in the matrix). -/
def R04isa := st "R04-isa" "GO:0042776 is_a GO:0015986" (.rel Rel.isA E.pmfMitoAtp e_GO_0015986)
  [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "GO is_a, OLS4 2026-11-01" }]
def R04d : Derivation (.rel Rel.hasOutput E.pmfMitoAtp e_CHEBI_15422) := .relChain (.lit R04isa) (.lit tbPmfAtpOutput)
#guard R04d.opinion.belief == 4/5 ∧ !(toString R04d.claim == toString R04.claim)

/-- R05. "Parathyroid hormone receptor can bind parathyroid hormone" (R-HSA-420489): both inputs are
DefinedSets (PTH, PTHrP, TIP39; PTH1R or PTH2R). The core has no union of entities; M0's placeholder
makes the set one opaque thing. -/
def R05 := st "R05" "R-HSA-420489 has_input PTH1R,PTH2R ligands (a set)"
  (.rel Rel.hasInput (E.rx "R-HSA-420489" "Parathyroid hormone receptor can bind parathyroid hormone")
    (E.rc "R-HSA-420569" "PTH1R,PTH2R ligands (DefinedSet)"))
  [cdb 8397094 1993 "Reactome"]
#guard !meets R05 tbPthRaisesCa

/-- R06. Glucagon binds glucagon receptor (R-HSA-163625): the input is GCG(53-81), the glucagon
peptide. M0 maps the chain to the precursor PR:P01275 (pro-glucagon). PR has no mature-glucagon term
(UNVERIFIED: one OLS4 label search); ChEBI has one (CHEBI:5391). -/
def R06 := st "R06" "R-HSA-163625 has_input GCG(53-81) [extracellular region], read as pro-glucagon"
  (.rel Rel.hasInput (E.rx "R-HSA-163625" "Glucagon binds to Glucagon receptor") (e_PR_P01275.inCtx { component := e_GO_0005576 }))
  [cdb 11946536 1972 "Reactome", cdb 15464082 2004 "Reactome", cdb 2826231 1987 "Reactome", cdb 8144028 1994 "Reactome"]
example : Claim := .rel Rel.hasInput (E.rx "R-HSA-163625" "") (E.glucagonPeptide.inCtx { component := e_GO_0005576 })
-- biolib labels GO:0005576 "extracellular fluid"; OLS4 says "extracellular region"
#guard toString R06.claim == "Glucagon binds to Glucagon receptor [Reactome:R-HSA-163625] has input glucagon ⊓ located in (extracellular fluid) [PR:P01275&RO:0001025=(GO:0005576)]"

/-- R07. Exocytosis of insulin (R-HSA-265166, GO:0030073 insulin secretion): inferred from mouse
(R-MMU-216883), nine PMIDs. M0 counts nine human curated records. -/
def R07pmids : List (Nat × Nat) := [(12403834, 2002), (17900700, 2007), (16443778, 2006), (12684222, 2003),
  (8997178, 1996), (18162464, 2008), (14514350, 2003), (7641683, 1995), (11873862, 2001)]
def R07 := st "R07" "insulin secretion has_input Ca2+ [cytosol]"
  (.rel Rel.hasInput E.insulinSecretion (e_CHEBI_29108.inCtx { component := e_GO_0005829 }))
  (R07pmids.map fun (p, y) => cdb p y "Reactome R-HSA-265166; inferred from mouse R-MMU-216883")
#guard R07.opinion.verdict == .established ∧ R07.opinion.belief == 36/37

/-- R08. SCNAs:SCNBs transport Na+ from extracellular region to cytosol (R-HSA-5576895). -/
def R08 := st "R08" "R-HSA-5576895 has_output Na+ [cytosol]"
  (.rel Rel.hasOutput (E.rx "R-HSA-5576895" "SCNAs:SCNBs transport Na+ from extracellular region to cytosol")
    (e_CHEBI_29101.inCtx { component := e_GO_0005829 }))
  [cdb 21566136 2011 "Reactome", cdb 14500339 2003 "Reactome", cdb 1309946 1992 "Reactome"]
#guard !meets R08 tbNaChannelNa

/-! ## 6. GOA (QuickGO, 2026-11-01, CC BY 4.0) -/

def O01 := st "O01" "SCN1A enables voltage-gated sodium channel activity" (.rel Rel.enables E.scn1a e_GO_0005248)
  [cdb 14672992 2003 "GOA IMP"]
#guard O01.opinion.verdict == .established

/-- O02. PTH enables hormone activity (IDA, PMID 35932760), with the extension has_input(UniProtKB:Q03431)
and part_of(GO:0007189). The core states the extension as refinements of the function. (The first pass
had an AVP row here that GOA does not hold: PMID 33664408 annotates AVPR2, not AVP.) -/
def O02 := st "O02" "PTH enables hormone activity with has_input PTH1R, part_of GO:0007189"
  (.rel Rel.enables E.pth ((E.hormoneActivity.refine Rel.hasInput E.pth1r).refine Rel.partOf E.gpcrAcSignal))
  [cdb 35932760 2022 "GOA IDA (UniProt); extension has_input(UniProtKB:Q03431),part_of(GO:0007189)"]
#guard O02.opinion.verdict == .established
-- the same paper backs GO-CAM's S06g: fusing the two would count one paper twice
#guard O02.pmids == S06g.pmids

def O03 := st "O03" "aak-2 involved_in determination of adult lifespan (C. elegans)"
  (.rel Rel.involvedIn (E.aak2.inCtx { taxon := some E.worm }) E.adultLifespan) [cdb 15574588 2004 "GOA (WB) IMP"]
#guard O03.opinion.verdict == .established

/-- O04. CALCR enables calcitonin binding (three PMIDs) and CALCR NOT enables calcitonin binding
(PMID 15563840, two novel isoforms; the GAF has no isoform). The same PMID is on both sides. -/
def O04yes := st "O04-yes" "CALCR enables calcitonin binding" (.rel Rel.enables E.calcr E.calcitoninBinding)
  [cdb 15563840 2004 "GOA IPI", cdb 8078488 1994 "GOA IDA", cdb 7769107 1995 "GOA IDA; isoform P30988-2"]
def O04no := st "O04-no" "CALCR NOT enables calcitonin binding" (.notRel Rel.enables E.calcr E.calcitoninBinding)
  [cdb 15563840 2004 "GOA IDA; NOT; two novel isoforms; no gene-product form"]
def O04 : Opinion := Derivation.clash (.lit O04yes) (.lit O04no)
#guard O04yes.opinion.verdict == .established ∧ O04.verdict == .unsupported
#guard O04.belief == 12/17 ∧ O04.disbelief == 4/17

/-! ## 7. The textbook's own grounding -/

-- T01: "insulin" is PR:000009054, which OLS4 labels preproinsulin (the hormone is PR:000050339)
#guard tbInsulinLowersGlucose.claim.subjectCurie == "PR:000009054" ∧ tbInsulinLowersGlucose.opinion.verdict == .established
-- T02: "glucagon" is PR:P01275, pro-glucagon (human): a human-specific precursor that also yields GLP-1
#guard tbGlucagonRaisesGlucose.claim.subjectCurie == "PR:P01275"

/-! ## 8. Synthetic edge cases (PMIDs 9000000x are SYNTHETIC) -/

/-- Y01. The exact textbook claim with the opposite sign, as a curated record. -/
def Y01 := st "Y01" "SYNTHETIC: glucose raises glucagon in blood from alpha cells"
  (.effect e_CHEBI_17234 .pos (.amount (e_PR_P01275.inCtx { anatomy := e_UBERON_0000178, cellType := e_CL_0000171 })))
  [cdb 90000001 2026 "SYNTHETIC"]
-- both are established; no rule relates an effect and its opposite sign
#guard Y01.opinion.verdict == .established ∧ tbGlucoseLowersGlucagon.opinion.verdict == .established
#guard Y01.claim.subjectCurie == tbGlucoseLowersGlucagon.claim.subjectCurie

/-- Y02. The same contradiction entered by the importer as refuting evidence on the textbook claim. -/
def Y02 : Statement := { tbGlucoseLowersGlucagon with
  evidence := tbGlucoseLowersGlucagon.evidence ++ [cdb 90000002 2026 "SYNTHETIC curated record, opposite sign" .refutes] }
#guard Y02.opinion.verdict == .contested ∧ Y02.opinion.belief == 4/9

/- Y03. One curie, two labels: the kernel sees two entities. Real: `Taxa.human` is "Homo sapiens",
the textbook's `e_NCBITaxon_9606` is "humans". -/
#guard Taxa.human.curie == e_NCBITaxon_9606.curie
example : Taxa.human ≠ e_NCBITaxon_9606 := by decide

/- Y04. UniProt-style PR ids cannot be encoded for the core's is_a lookup, so OLS4's
PR:P01308 is_a PR:000009054 is invisible. -/
#guard Curie.encode "PR:P01308" == none ∧ Ontology.isACurie "PR:P01308" "PR:000009054" == false

/-! ## 9. The M8 exit question: does metformin extend lifespan in humans? -/

def onTaxon (t : Entity .taxon) : Ctx := { taxon := some t }
def metIn (c : Ctx) : Entity .chemical := E.metformin.inCtx c
def lifespanUp (c : Ctx) : Claim := .effect (metIn c) .pos (.phenotype E.lifespan)

/-- M01, M02: the curated mechanism (SIGNOR). -/
def M01 := st "M01" "metformin up-regulates activity PRKAA1" (.effect E.metformin .pos (.activity E.prkaa1))
  [cdb 11602624 2001 "SIGNOR; indirect; hepatocytes and isolated rat skeletal muscle"]
def M02 := st "M02" "metformin down-regulates activity NDUFS1 (complex I)" (.effect E.metformin .neg (.activity E.ndufs1))
  [cdb 24843020 2014 "SIGNOR; chemical inhibition; human cancer cells"]
#guard M01.opinion.verdict == .established ∧ M02.opinion.verdict == .established

/-- M03. Worms: no curated source states a drug effect on lifespan; from the literature. Cabreiro 2013:
the effect runs through the E. coli the worms eat, and "increases or decreases worm lifespan, depending on
E. coli strain metformin sensitivity and glucose concentration". The claim carries no bacterial context. -/
def M03 := st "M03" "metformin extends lifespan in C. elegans" (lifespanUp (onTaxon E.worm))
  [item 20090912 2010 .mechanistic "Onken 2010", item 23540700 2013 .mechanistic "Cabreiro 2013; sign depends on the E. coli strain"]
#guard M03.opinion.verdict == .established ∧ M03.opinion.belief == 14/17

/-- M04. Mice: Martin-Montalvo 2013 (male mice, 0.1% in the diet, longer; strain UNVERIFIED) against the ITP
(Strong 2016, no significant effect at 0.1%; strain UM-HET3 UNVERIFIED, not in the abstract). -/
def M04 := st "M04" "metformin extends lifespan in mice" (lifespanUp (onTaxon Taxa.mouse))
  [{ item 23900241 2013 .mechanistic "Martin-Montalvo 2013: male mice, 0.1% diet" with dose := some "0.1% w/w diet" },
   { item 27312235 2016 .mechanistic "Strong 2016 (ITP): no significant effect" .refutes with strain := some "UM-HET3" }]
#guard M04.opinion.verdict == .contested ∧ M04.opinion.belief == 7/17 ∧ M04.opinion.disbelief == 7/17

/-- M05. People with type 2 diabetes, observational. M0 gives the meta-analysis its kind's weight. -/
def t2dHuman : Ctx := { taxon := some Taxa.human, condition := some (.organism E.t2d) }
def M05 := st "M05" "metformin extends lifespan in people with type 2 diabetes" (lifespanUp t2dHuman)
  [item 25041462 2014 .observational "Bannister 2014", item 28802803 2017 .metaAnalysis "Campbell 2017 (pooled observational)",
   item 36287641 2022 .observational "Keys 2022: not associated with survival equal or superior to the general population" .refutes]
#guard M05.opinion.verdict == .established ∧ M05.opinion.belief == 5/6

/-- M06. Mouse to human by `transport` (sibling taxa), with a cross-species item. -/
def transportItem : Evidence := item 27304507 2016 .crossSpecies "Barzilai 2016 (TAME): the case for translation"
def M06 : Derivation (lifespanUp (onTaxon Taxa.human)) :=
  .transport {} Taxa.human (T₁ := Taxa.mouse) (.lit M04) transportItem
#guard M06.opinion.verdict == .unsupported ∧ M06.opinion.belief == 21/170

/- M07. From people with diabetes to people without: the subjects differ, and no rule moves a claim
across an organism condition. -/
#guard !(toString M05.claim == toString M06.claim)

/- M08. The mechanistic route: metformin activates human AMPK (M01); worm AMPK is "involved in
determination of adult lifespan" (O03), unsigned and in another taxon. Nothing chains, which is right:
no source gives a signed AMPK-to-lifespan step in humans. Every piece can be stated: the signed worm step
from Apfeld 2004 ("AAK-2 ... functions to extend lifespan") and the human mechanism as a hypothesis. -/
#guard !meets M01 O03
def M08worm := st "M08-worm" "aak-2 extends lifespan in C. elegans" (.effect (E.aak2.inCtx (onTaxon E.worm)) .pos (.phenotype E.lifespan))
  [item 15574588 2004 .mechanistic "Apfeld 2004: AAK-2 functions to extend lifespan"]
def M08hyp : Claim := .mediatedBy (metIn (onTaxon Taxa.human)) .pos (.phenotype E.lifespan) (.activity E.prkaa1)
-- the worm protein is not the human one, and no rule links orthologs, so M01 cannot chain into M08worm.
-- One mechanistic paper (weight 0.7) does not establish it.
#guard M08worm.claim.subjectCurie == "UniProtKB:Q95ZQ4&RO:0002162=(NCBITaxon:6239)" ∧ E.prkaa1.curie == "PR:Q13131"
#guard M08worm.opinion.verdict == .unsupported ∧ M08worm.opinion.belief == 7/10

/-- M09. The exit answer the core gives today: the transported mouse claim, with TAME as a
hypothesis (weight 0) fused in. -/
def M09tame := st "M09-tame" "TAME proposes a trial of metformin against ageing" (lifespanUp (onTaxon Taxa.human))
  [item 27304507 2016 .hypothesis "Barzilai 2016: proposed trial"]
def M09 : Derivation (lifespanUp (onTaxon Taxa.human)) := .both M06 (.lit M09tame)
#guard M09.opinion.verdict == .unsupported ∧ M09.opinion.belief == 21/170
#guard M09.pmids == [23900241, 27312235, 27304507]

end BioLean.Stress.Literature

/-! ## 10. Prototypes (NOT core): what would flip marks -/

namespace BioLean.Proto.Literature
open BioLean BioLean.Stress.Literature BioLean.Textbook.R2

/-- Importer M1, outside the core: hand map of SIGNOR complex SIGNOR-C264 to GO:0045259. -/
def S10m1 := st "S10-M1" "ATP synthase up-regulates quantity ATP" (.effect e_GO_0045259 .pos (.amount e_CHEBI_15422))
  [cdb 21874297 2012 "SIGNOR; SIGNOR-C264 mapped to GO:0045259"]
def S10fused : Derivation tbAtpSynthaseAtp.claim := .both (.lit tbAtpSynthaseAtp) (.lit S10m1)
#guard sameClaim S10m1 tbAtpSynthaseAtp ∧ S10fused.opinion.belief == 8/9

/-- Importer M1: an inferred Reactome reaction is one cross-species item, not nine curated ones. -/
def R07m1 : Statement := { R07 with evidence := [item 0 2026 .crossSpecies "Reactome R-HSA-265166 inferred from mouse"] }
#guard R07m1.opinion.verdict == .unsupported ∧ R07m1.opinion.belief == 3/10

/-- Importer M1: a meta-analysis of observational studies counts as observational (program 10a, B1). -/
def M05m1 : Statement := { M05 with evidence := M05.evidence.map fun e =>
  if e.kind == .metaAnalysis then { e with kind := .observational } else e }
#guard M05m1.opinion.verdict == .contested
#guard M05m1.opinion.belief == 1/2 ∧ M05m1.opinion.disbelief == 1/4

/-- Importer M1: SIGNOR's M01 rests on Zhou 2001 (hepatocytes; isolated rat skeletal muscle). If the importer
fills `Evidence.taxon`, the core's existing lint `Statement.taxonConsistent` flags rat evidence on a claim
about a human protein with no taxon context. -/
def M01rat : Statement := { M01 with evidence := M01.evidence.map fun e => { e with taxon := some Taxa.rat } }
#guard M01.taxonConsistent ∧ !M01rat.taxonConsistent

/-- Option I, outside the core: PubTator3's ten signed metformin-G6PC1 relations (9 negative_correlate, 1
positive_correlate; `pubtator_metformin_g6pc1.tsv`) as `textMined` items on SIGNOR's wrong-signed S12. -/
def ptNeg : List (Nat × Nat) := [(10576523, 1999), (19579180, 2009), (22758368, 2012), (24428821, 2014),
  (29256045, 2018), (30970232, 2019), (32375255, 2020), (39922487, 2025), (42545322, 2026)]
def ptItems : List Evidence :=
  ptNeg.map (fun (p, y) => item p y .textMined "PubTator3 negative_correlate" .refutes) ++
    [item 42555357 2026 .textMined "PubTator3 positive_correlate"]
def S12pt : Statement := { S12 with evidence := S12.evidence ++ ptItems }
-- better than SIGNOR alone (established), not yet right (metformin lowers G6PC1 expression)
#guard S12pt.opinion.verdict == .contested ∧ S12pt.opinion.belief == 31/65 ∧ S12pt.opinion.disbelief == 27/65

/-- Option F, outside the core: a sign clash for effects, built like `Derivation.clash` from the existing
`fuse` and `negate`. Not a rule and not a new operator: it reads two derivations and returns an opinion. -/
def effectClash {k : Kind} {a : Entity k} {s₁ s₂ : Sign} {t : Target}
    (d₁ : Derivation (.effect a s₁ t)) (d₂ : Derivation (.effect a s₂ t)) (_h : s₁ ≠ s₂ := by decide) : Opinion :=
  d₁.opinion.fuse d₂.opinion.negate
def Y01clash : Opinion := effectClash (.lit tbGlucoseLowersGlucagon) (.lit Y01)
#guard Y01clash.verdict == .contested ∧ Y01clash.belief == 4/9 ∧ Y01clash.disbelief == 4/9

/-- Candidate rules (new `Derivation` constructors if adopted). -/
inductive PDeriv : Claim → Type
  | core {c : Claim} (d : Derivation c) : PDeriv c
  /-- A protein that enables a function has the function's effects: `P enables F`, `F →s t` give `P →s t`. -/
  | enablesInherit {k : Kind} {p : Entity k} {f : Entity .function} {s : Sign} {t : Target}
      {h : Rel.enables.accepts k .function = true}
      (en : PDeriv (.rel Rel.enables p f h)) (ft : PDeriv (.effect f s t)) : PDeriv (.effect p s t)
  /-- A positive effect on a subprocess is a positive effect on the process: `a →+ p`, `p is_a q` give `a →+ q`. -/
  | widenProcess {k : Kind} {a : Entity k} {p q : Entity .process} {h : Rel.isA.accepts .process .process = true}
      (ap : PDeriv (.effect a .pos (.process p))) (pq : PDeriv (.rel Rel.isA p q h)) : PDeriv (.effect a .pos (.process q))
  | isaInheritEffect {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {s : Sign} {t : Target}
      {h : Rel.isA.accepts k₁ k₂ = true}
      (ab : PDeriv (.rel Rel.isA a b h)) (bt : PDeriv (.effect b s t)) : PDeriv (.effect a s t)
  | both {c : Claim} (d₁ d₂ : PDeriv c) : PDeriv c

def PDeriv.opinion [EvidenceModel] : {c : Claim} → PDeriv c → Opinion
  | _, .core d => d.opinion
  | _, .enablesInherit en ft => en.opinion.weakest ft.opinion
  | _, .widenProcess ap pq => ap.opinion.weakest pq.opinion
  | _, .isaInheritEffect ab bt => ab.opinion.weakest bt.opinion
  | _, .both d₁ d₂ => d₁.opinion.fuse d₂.opinion

/-- S09 with `enablesInherit`: GOA's SCN1A enables GO:0005248 plus the textbook's GO:0005248 →+ Na+
gives SCN1A →+ Na+, which fuses with SIGNOR's S09. -/
def S09p : PDeriv S09.claim :=
  .both (.core (.lit S09)) (.enablesInherit (.core (.lit O01)) (.core (.lit tbNaChannelNa)))
#guard S09p.opinion.belief == 8/9

/-- G02 and the textbook, with `isaInheritEffect` (OLS4: PR:P01308 is_a PR:000009054) and `widenProcess`
(OLS4: GO:0098708 is_a GO:1904659). From the textbook alone this reaches "human preproinsulin →+ D-glucose
transmembrane transport", the textbook's claim made specific to human and general in the process. The
GO-CAM chain is not used: it still ends at "→+ activity of GLUT4", and the model puts GLUT4's activity in
glucose homeostasis, so the curated mechanism and the textbook claim still do not meet. G02 stays SILENT. -/
def insIsa := st "isa-ins" "PR:P01308 is_a PR:000009054" (.rel Rel.isA E.ins e_PR_000009054)
  [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "PR is_a, OLS4 2026-11-01" }]
def importIsa := st "isa-import" "GO:0098708 is_a GO:1904659" (.rel Rel.isA e_GO_0098708 E.glcTransport)
  [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "GO is_a, OLS4 2026-11-01" }]
def G02p : PDeriv (.effect E.ins .pos (.process E.glcTransport)) :=
  .widenProcess (.isaInheritEffect (.core (.lit insIsa)) (.core (.lit tbInsulinGlucoseImport))) (.core (.lit importIsa))
#guard G02p.opinion.belief == 4/5 ∧ !(toString G02.claim == toString (Claim.effect E.ins .pos (.process E.glcTransport)))

/-- Shared-PMID lint (outside the core, a report check): PMIDs cited by two different axioms. -/
def sharedPmids {c : Claim} (d : Derivation c) : List Nat :=
  let per := d.axioms.map fun s => (s.id, s.pmids.eraseDups)
  (per.flatMap (·.2)).eraseDups.filter fun p => (per.filter fun x => x.2.contains p).length > 1
#guard sharedPmids S14 == [31160049] ∧ sharedPmids G03 == [38632411] ∧ sharedPmids S01 == []

end BioLean.Proto.Literature

/-! ## 11. Results: one row per case, read by `scripts/stress/literature_cases.py` -/

namespace BioLean.Stress.Literature
open BioLean BioLean.Proto.Literature

inductive Mark | pass | fail | silent | inexpressible
def Mark.str : Mark → String
  | .pass => "PASS" | .fail => "FAIL" | .silent => "SILENT" | .inexpressible => "INEXPRESSIBLE"

structure Row where
  id : String
  mark : Mark
  observed : String
  test : String

def yn (b : Bool) : String := if b then "yes" else "no"

def rows : List Row := [
  ⟨"S01", .pass, s!"SIGNOR and GO-CAM give one claim (same: {yn (sameClaim S01s S01g)}); fused {show3 S01.opinion}, PMIDs {S01.pmids}", "S01"⟩,
  ⟨"S02", .fail, s!"derives {S02.claim} at {show3 S02.opinion}; textbook m45537-53 says insulin lowers blood glucose; nothing flags the clash", "S02"⟩,
  ⟨"S03", .silent, s!"subject calcium vs glucose (meets: {yn (meets S03 tbGlucoseRaisesInsulin)}); no rule makes Ca2+ a mediator; BTO beta cell dropped", "S03"⟩,
  ⟨"S04", .pass, s!"no fusion, no contradiction: subject CHEBI:17925 vs CHEBI:17234 (core is_a links them: {yn (Ontology.isACurie "CHEBI:17925" "CHEBI:17234")}); right for the wrong reason", "S04"⟩,
  ⟨"S05", .pass, s!"SIGNOR and GO-CAM fuse: {show3 S05.opinion}; subject is the textbook's glucagon entity (meets: {yn (meets S05s tbGlucagonRaisesGlucose)})", "S05"⟩,
  ⟨"S06", .pass, s!"SIGNOR and GO-CAM fuse: {show3 S06.opinion}; meets textbook PTH PR:000013429: {yn (meets S06s tbPthRaisesCa)}", "S06"⟩,
  ⟨"S07", .fail, s!"{show3 S07.opinion} on PMID {S07.pmids}, a rat V1a receptor paper", "S07"⟩,
  ⟨"S08", .silent, s!"vasopressin (CHEBI:9937) and AVP (PR:P01185) claims: same {yn (sameClaim S08 S07)}; the core's is_a links only the two ChEBI ids", "S08"⟩,
  ⟨"S09", .silent, s!"protein SCN1A vs GO function GO:0005248: meets {yn (meets S09 tbNaChannelNa)}; prototype enablesInherit fuses them at {show3 S09p.opinion}", "S09"⟩,
  ⟨"S10", .silent, s!"SIGNOR-C264 has no OBO id: same claim {yn (sameClaim S10 tbAtpSynthaseAtp)}; with the M1 complex map: same {yn (sameClaim S10m1 tbAtpSynthaseAtp)}, fused {show3 S10fused.opinion}", "S10"⟩,
  ⟨"S11", .silent, s!"M0's complex placeholder cannot be an activity target (decide), so M0 drops the edge; mapped to GO:0046933 it is stated ({show3 S11m1.opinion}) but meets textbook m45452-91: {yn (meets S11m1 tbProtonsPowerAtpSynthase)}", "S11"⟩,
  ⟨"S12", .fail, s!"{show3 S12.opinion} for metformin raising G6PC1; the cited sentence says it lowers it; PCK1 edge from the same paper {show3 S12pck.opinion}; with PubTator3's 10 signed items (option I): {show3 S12pt.opinion}", "S12"⟩,
  ⟨"S13", .pass, s!"stated as Claim.rel causally influences, {show3 S13.opinion}; does not chain with effects", "S13"⟩,
  ⟨"S14", .silent, s!"chain {show3 S14.opinion} rests on PMIDs {S14.pmids} twice; sharedAxioms = {S14.sharedAxioms}; prototype PMID lint: {sharedPmids S14}", "S14"⟩,
  ⟨"G02", .silent, s!"chain to {G02.claim}: {show3 G02.opinion}; stops at an activity; the model's GLUT4 fact is {G02d.claim}; prototype is_a + widenProcess turn the textbook claim into {Claim.effect E.ins .pos (.process E.glcTransport)} ({show3 G02p.opinion}), which the chain still does not meet", "G02"⟩,
  ⟨"G03", .pass, s!"chain derives {G03.claim}: right sign, {show3 G03.opinion}", "G03"⟩,
  ⟨"G04", .silent, s!"G03 ends in activity of PR:P01270; textbook m45537-141 is amount of PR:000013429 in blood: same {yn (toString G03.claim == toString tbCaLowersPth.claim)}; PMID 38632411 on two steps, sharedAxioms = {G03.sharedAxioms}", "G03"⟩,
  ⟨"G05", .silent, s!"chain to {G05.claim}: {show3 G05.opinion}; no step to blood calcium; subject meets textbook PTH: {yn (meets S06g tbPthRaisesCa)}", "G05"⟩,
  ⟨"G06", .fail, s!"{show3 G06.opinion} on PMID {G06.pmids}, a paper on MAP2c localisation", "G06"⟩,
  ⟨"G07", .fail, s!"SIGNOR and GO-CAM fuse: {show3 G07.opinion}, up from {show3 G07g.opinion} on the good paper alone; the axioms keep S07's wrong paper: PMIDs {G07.pmids}", "G07"⟩,
  ⟨"G08", .pass, s!"same subject as textbook calcitonin (meets: {yn (meets G08 tbCalcitoninLowersCa)}); no fusion, no contradiction", "G08"⟩,
  ⟨"G09", .fail, s!"both lifted to class level: cytoplasm {show3 G09a.opinion}, extracellular {show3 G09b.opinion}", "G09"⟩,
  ⟨"G10", .fail, s!"zebrafish term accepted, {show3 G10.opinion}; no link to CL:0000169", "G10"⟩,
  ⟨"G11", .silent, s!"{G11.claim}: subject and object differ from textbook m45439-74; core is_a ATP(4-) to ATP: {yn (Ontology.isACurie "CHEBI:30616" "CHEBI:15422")}", "G11"⟩,
  ⟨"G12", .silent, s!"unsigned rel vs textbook m45452-91 effect: same {yn (sameClaim G12 tbProtonsPowerAtpSynthase)}", "G12"⟩,
  ⟨"R01", .fail, s!"class claim on all of GO:1904659: {show3 R01in.opinion}; GLUT2 efflux (R02) is a counterexample; core is_a D-glucopyranose to glucose: {yn (Ontology.isACurie "CHEBI:4167" "CHEBI:17234")}", "R01"⟩,
  ⟨"R02", .silent, s!"placeholder process, rel vs textbook effect: meets {yn (meets R02 tbGlucagonRaisesGlucose)}", "R02"⟩,
  ⟨"R03", .silent, s!"complex placeholders; meets S01: {yn (meets R03 S01s)}", "R03"⟩,
  ⟨"R04", .silent, s!"textbook has_output passes to GO:0042776 by is_a ({show3 R04d.opinion}) but objects differ: same {yn (toString R04d.claim == toString R04.claim)}", "R04"⟩,
  ⟨"R05", .inexpressible, "a DefinedSet becomes one opaque placeholder; the core has no union of entities", "R05"⟩,
  ⟨"R06", .fail, s!"the glucagon peptide GCG(53-81) is stated as {R06.claim}", "R06"⟩,
  ⟨"R07", .fail, s!"inferred-from-mouse reaction as nine human curated items: {show3 R07.opinion}; M1 (one crossSpecies item): {show3 R07m1.opinion}", "R07"⟩,
  ⟨"R08", .silent, s!"rel with compartments vs textbook effect: meets {yn (meets R08 tbNaChannelNa)}", "R08"⟩,
  ⟨"O01", .pass, s!"stated as Claim.rel enables, {show3 O01.opinion}", "O01"⟩,
  ⟨"O02", .pass, s!"extension kept as refinements: {O02.claim}; same PMID as GO-CAM S06g: {yn (O02.pmids == S06g.pmids)}", "O02"⟩,
  ⟨"O03", .pass, s!"stated in worm context, unsigned: {show3 O03.opinion}", "O03"⟩,
  ⟨"O04", .fail, s!"clash of 3 positive rows and 1 NOT row: {show3 O04}; an isoform difference read as a contradiction", "O04"⟩,
  ⟨"T01", .fail, s!"textbook insulin claims rest on {tbInsulinLowersGlucose.claim.subjectCurie} (OLS4: preproinsulin), {show3 tbInsulinLowersGlucose.opinion}", "T01"⟩,
  ⟨"T02", .fail, s!"textbook glucagon is {tbGlucagonRaisesGlucose.claim.subjectCurie} (OLS4: pro-glucagon (human))", "T02"⟩,
  ⟨"Y01", .silent, s!"curated {show3 Y01.opinion} and textbook {show3 tbGlucoseLowersGlucagon.opinion}, opposite signs, nothing flags it; prototype effectClash (outside the core): {show3 Y01clash}", "Y01"⟩,
  ⟨"Y02", .pass, s!"entered as refuting evidence: {show3 Y02.opinion}", "Y02"⟩,
  ⟨"Y03", .silent, "Taxa.human and e_NCBITaxon_9606 share a curie but are different entities (decide), so claims built on the two never fuse; no wrong claim is drawn", "Y03"⟩,
  ⟨"Y04", .silent, s!"Curie.encode PR:P01308 = {repr (Curie.encode "PR:P01308")}; core is_a PR:P01308 to PR:000009054: {yn (Ontology.isACurie "PR:P01308" "PR:000009054")}", "Y04"⟩,
  ⟨"M01", .pass, s!"{show3 M01.opinion}; the evidence is rat cells: with Evidence.taxon filled, the core lint taxonConsistent says {yn M01rat.taxonConsistent}", "M01"⟩,
  ⟨"M02", .pass, s!"{show3 M02.opinion}", "M01"⟩,
  ⟨"M03", .pass, s!"{show3 M03.opinion} in C. elegans from two papers; no curated source states it", "M03"⟩,
  ⟨"M04", .pass, s!"{show3 M04.opinion} in mice", "M04"⟩,
  ⟨"M05", .fail, s!"{show3 M05.opinion} in people with type 2 diabetes; with the meta-analysis as observational (M1): {show3 M05m1.opinion}", "M05"⟩,
  ⟨"M06", .pass, s!"mouse to human by transport: {show3 M06.opinion}", "M06"⟩,
  ⟨"M07", .silent, s!"the diabetes claim and the human claim never meet: same {yn (toString M05.claim == toString M06.claim)}; no rule across an organism condition", "M07"⟩,
  ⟨"M08", .pass, s!"no chain, which is right; the signed worm step can be stated ({show3 M08worm.opinion}, one paper) and the human mechanism as a mediatedBy hypothesis, but the worm protein is not the human one and no rule links orthologs", "M08"⟩,
  ⟨"M09", .pass, s!"exit answer: {show3 M09.opinion}; rests on {M09.axioms.length} statements, PMIDs {M09.pmids}", "M09"⟩
]

#guard rows.length == 52
#eval rows.forM fun r => IO.println s!"ROW\t{r.id}\t{r.mark.str}\t{r.observed}\t{r.test}"

end BioLean.Stress.Literature
