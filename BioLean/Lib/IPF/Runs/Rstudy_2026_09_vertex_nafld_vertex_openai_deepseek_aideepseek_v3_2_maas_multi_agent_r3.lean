import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-nafld-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-nafld-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r3`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, non-alcoholic fatty liver disease, genes PNPLA3, APOE, APOA5, LIPC, CMIP, RBM27, SMIM32. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_nafld_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def rs738409 : Entity .variant := ⟨"dbSNP:rs738409", "rs738409 G allele (PNPLA3 I148M)"⟩
def PNPLA3 : Entity .protein := ⟨"UniProt:Q9NST1", "PNPLA3"⟩
def paSynthesis : Entity .process := ⟨"GO:0006654", "phosphatidic acid biosynthetic process"⟩
def triglyceride : Entity .chemical := ⟨"CHEBI:17855", "triglyceride"⟩
def hepaticSteatosis : Entity .phenotype := ⟨"HP:0001397", "Hepatic steatosis"⟩
def nafld : Entity .disease := ⟨"MONDO:0013209", "metabolic dysfunction-associated steatotic liver disease"⟩
def APOE : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def lipoproteinClearance : Entity .process := ⟨"GO:0034381", "plasma lipoprotein particle clearance"⟩
def CMIP : Entity .protein := ⟨"UniProt:Q8IY22", "CMIP"⟩
def cmipMethylation : Entity .variant := ⟨"BLN:CMIP-methylation-change", "altered DNA methylation of CMIP intron 1 (direction not stated)"⟩
def fattyAcidUptake : Entity .process := ⟨"GO:0044539", "long-chain fatty acid import into cell"⟩

/-- Run step h1.1: the PNPLA3 I148M (rs738409 G) allele goes with hepatic steatosis. Sign: the step's polarity is unknown; direction from PMID:21878620, which says the I148M variant is associated with triacylglycerol accumulation in the liver. -/
def S1 : Statement where
  id := "S1"
  text := "the PNPLA3 I148M (rs738409 G) allele goes with hepatic steatosis"
  claim := .assoc rs738409 (some .pos) (.phenotype hepaticSteatosis)
  evidence := [
    { pmid := 21878620, year := 2011, kind := .review, note := "PNPLA3-I148M), a serine protease of unknown function, is associated with accumulation of triacylglycerol (TAG) in the liver" }
  ]

/-- Run step h1.2: PNPLA3 raises phosphatidic acid synthesis. -/
def S2 : Statement where
  id := "S2"
  text := "PNPLA3 raises phosphatidic acid synthesis"
  claim := .effect PNPLA3 .pos (.process paSynthesis)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9NST1", kind := .curatedDb, note := "Specifically catalyzes coenzyme A (CoA)-dependent acylation of 1-acyl-sn-glycerol 3-phosphate (2-lysophosphatidic acid/LPA) to generate phosphatidic acid (PA)" },
    { pmid := 21878620, year := 2011, kind := .inVitro, polarity := .refutes, note := "Neither the wild-type nor mutant enzyme catalyzed transfer of oleic acid from oleoyl-CoA to glycerophosphate, lysophosphatidic acid, or diacylglycerol" }
  ]

/-- Run step h1.3: phosphatidic acid synthesis raises triglyceride amount. -/
def S3 : Statement where
  id := "S3"
  text := "phosphatidic acid synthesis raises triglyceride amount"
  claim := .effect paSynthesis .pos (.amount triglyceride)
  evidence := []

/-- Run step h2.1: APOE deficiency is associated with NAFLD (unsigned). Sign: the run's subject is APOE deficiency (loss of APOE); the step and its citations give no direction, so there is nothing to invert. -/
def S4 : Statement where
  id := "S4"
  text := "APOE deficiency is associated with NAFLD (unsigned)"
  claim := .assoc APOE none (.disease nafld)
  evidence := []

/-- Run step h2.2: APOE is required for lipoprotein clearance (losing APOE lowers clearance). -/
def S5 : Statement where
  id := "S5"
  text := "APOE is required for lipoprotein clearance (losing APOE lowers clearance)"
  claim := .effect APOE .pos (.process lipoproteinClearance)
  evidence := [
    { pmid := 0, year := 2026, ref := "P02649", kind := .curatedDb, note := "A main function of APOE is to mediate lipoprotein clearance through the uptake of chylomicrons, VLDLs, and HDLs by hepatocytes" }
  ]

/-- Run step h3.1: CMIP methylation changes are associated with NAFLD (unsigned). Sign: the step and its citation give no direction for the methylation change. -/
def S6 : Statement where
  id := "S6"
  text := "CMIP methylation changes are associated with NAFLD (unsigned)"
  claim := .assoc cmipMethylation none (.disease nafld)
  evidence := [
    { pmid := 36609599, year := 2023, kind := .observational, note := "We first identified alterations in the methylation status of the Cmip intron 1 region in mouse liver tissues with high-fat high-sucrose diet-induced NAFLD", taxon := some Taxa.mouse }
  ]

/-- Run step h3.2: CMIP raises fatty acid uptake (run: increases_amount of CD36-mediated fatty acid uptake). -/
def S7 : Statement where
  id := "S7"
  text := "CMIP raises fatty acid uptake (run: increases_amount of CD36-mediated fatty acid uptake)"
  claim := .effect CMIP .pos (.process fattyAcidUptake)
  evidence := []

/-- Bridge, not in the run: the I148M (rs738409 G) allele lowers PNPLA3 activity (stated by the paper the run cited for h1.1; no step links the variant to PNPLA3). -/
def B1 : Statement where
  id := "B1"
  text := "the I148M (rs738409 G) allele lowers PNPLA3 activity (stated by the paper the run cited for h1.1; no step links the variant to PNPLA3)"
  claim := .effect rs738409 .neg (.activity PNPLA3)
  evidence := [
    { pmid := 21878620, year := 2011, kind := .inVitro, note := "the I148M substitution causes a loss of function" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, B1]

/-- h1, claim 2: PNPLA3 variant disrupts hepatic triglyceride metabolism through phosphatidic acid synthesis. -/
def h1c2a1 := fromAssoc (lit S1)

/-- h1, claim 3: PNPLA3 variant disrupts hepatic triglyceride metabolism through phosphatidic acid synthesis. -/
def h1c3a1 := viaActivity (lit B1) (viaProcess (lit S2) (lit S3))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "h1" "c2a1" h1c2a1,
    arm "h1" "c3a1" h1c3a1]

#eval printRows "study-2026-09-vertex-nafld-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_nafld_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r3
