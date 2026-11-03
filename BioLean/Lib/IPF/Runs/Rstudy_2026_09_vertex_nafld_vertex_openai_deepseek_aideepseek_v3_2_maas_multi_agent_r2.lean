import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-nafld-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-nafld-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, non-alcoholic fatty liver disease, genes PNPLA3, APOE, APOA5, LIPC, CMIP, RBM27, SMIM32. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_nafld_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def nafld : Entity .disease := ⟨"MONDO:0013209", "metabolic dysfunction-associated steatotic liver disease"⟩
def PNPLA3 : Entity .protein := ⟨"UniProt:Q9NST1", "PNPLA3"⟩
def APOE : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def APOA5 : Entity .protein := ⟨"UniProt:Q6Q788", "APOA5"⟩
def hepaticSteatosis : Entity .phenotype := ⟨"HP:0001397", "Hepatic steatosis"⟩
def trlClearance : Entity .process := ⟨"GO:0071830", "triglyceride-rich lipoprotein particle clearance"⟩
def lipoproteinClearance : Entity .process := ⟨"GO:0034381", "plasma lipoprotein particle clearance"⟩
def vldlClearance : Entity .process := ⟨"GO:0034447", "very-low-density lipoprotein particle clearance"⟩
def lplActivity : Entity .function := ⟨"GO:0004465", "lipoprotein lipase activity"⟩
def vldlAssembly : Entity .process := ⟨"GO:0034379", "very-low-density lipoprotein particle assembly"⟩

/-- Run step hypo-1.1: NAFLD activates PNPLA3 (the run's subject is the disease, its object the gene). -/
def S1 : Statement where
  id := "S1"
  text := "NAFLD activates PNPLA3 (the run's subject is the disease, its object the gene)"
  claim := .effect nafld .pos (.activity PNPLA3)
  evidence := []

/-- Run step hypo-2.1: APOE promotes clearance of triglyceride-rich lipoproteins. -/
def S2 : Statement where
  id := "S2"
  text := "APOE promotes clearance of triglyceride-rich lipoproteins"
  claim := .effect APOE .pos (.process trlClearance)
  evidence := [
    { pmid := 0, year := 2026, ref := "P02649", kind := .curatedDb, note := "A main function of APOE is to mediate lipoprotein clearance through the uptake of chylomicrons, VLDLs, and HDLs by hepatocytes" }
  ]

/-- Run step hypo-3.1: APOA5 stimulates lipoprotein lipase hydrolysis of VLDL triglyceride. -/
def S3 : Statement where
  id := "S3"
  text := "APOA5 stimulates lipoprotein lipase hydrolysis of VLDL triglyceride"
  claim := .effect APOA5 .pos (.activity lplActivity)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q6Q788", kind := .crossSpecies, note := "a potent stimulator of apo-CII lipoprotein lipase (LPL) TG hydrolysis", taxon := some Taxa.mouse }
  ]

/-- Run step hypo-3.2: APOA5 inhibits hepatic VLDL production. -/
def S4 : Statement where
  id := "S4"
  text := "APOA5 inhibits hepatic VLDL production"
  claim := .effect APOA5 .neg (.process vldlAssembly)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q6Q788", kind := .crossSpecies, note := "an inhibitor of the hepatic VLDL-TG production rate (without affecting the VLDL-apoB production rate) (By similarity)", taxon := some Taxa.mouse }
  ]

def statements : List Statement := [S1, S2, S3, S4]

/-- hypo-3, claim 2: APOA5 dysfunction reduces triglyceride clearance and increases hepatic VLDL production. -/
def h3c2a1 := lit S3

/-- hypo-3, claim 3: APOA5 dysfunction reduces triglyceride clearance and increases hepatic VLDL production. -/
def h3c3a1 := lit S4

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hypo-3" "c2a1" h3c2a1,
    arm "hypo-3" "c3a1" h3c3a1]

#eval printRows "study-2026-09-vertex-nafld-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_nafld_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r2
