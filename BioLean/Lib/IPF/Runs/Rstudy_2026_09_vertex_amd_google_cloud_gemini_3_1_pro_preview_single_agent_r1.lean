import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-amd-google-cloud-gemini-3.1-pro-preview-single_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-amd-google-cloud-gemini-3.1-pro-preview-single_agent-r1`: google-cloud:gemini-3.1-pro-preview, age-related macular degeneration, genes LIPC, ARMS2, CETP, C3, TNFRSF10A, MCF2L2, CACNA1E. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_amd_google_cloud_gemini_3_1_pro_preview_single_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def LIPC : Entity .protein := ⟨"UniProt:P11150", "LIPC"⟩
def CETP : Entity .protein := ⟨"UniProt:P11597", "CETP"⟩
def ARMS2 : Entity .protein := ⟨"UniProt:P0C7Q2", "ARMS2"⟩
def C3 : Entity .protein := ⟨"UniProt:P01024", "C3"⟩
def TNFRSF10A : Entity .protein := ⟨"UniProt:O00220", "TNFRSF10A"⟩
def lipidMetabolism : Entity .process := ⟨"GO:0006629", "lipid metabolic process"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def apoptoticProcess : Entity .process := ⟨"GO:0006915", "apoptotic process"⟩
def rpeCell : Entity .cellType := ⟨"CL:0002586", "retinal pigment epithelial cell"⟩
def amd : Entity .disease := ⟨"MONDO:0005150", "age-related macular degeneration"⟩

/-- Run step lipid_metabolism.1: LIPC raises lipid metabolism (it catalyzes lipid hydrolysis). Sign: the run gives polarity unknown; the cited UniProt text says LIPC catalyzes the hydrolysis of triglycerides and phospholipids, which is lipid metabolism, so pos. -/
def S1 : Statement where
  id := "S1"
  text := "LIPC raises lipid metabolism (it catalyzes lipid hydrolysis)"
  claim := .effect LIPC .pos (.process lipidMetabolism)
  evidence := [
    { pmid := 0, year := 2026, ref := "P11150", kind := .curatedDb, note := "Catalyzes the hydrolysis of triglycerides and phospholipids present in circulating plasma lipoproteins" }
  ]

/-- Run step lipid_metabolism.3: lipid metabolism is associated with AMD (no direction). -/
def S2 : Statement where
  id := "S2"
  text := "lipid metabolism is associated with AMD (no direction)"
  claim := .assoc lipidMetabolism none (.disease amd)
  evidence := []

/-- Run step complement_activation.1: ARMS2 binds C3. -/
def S3 : Statement where
  id := "S3"
  text := "ARMS2 binds C3"
  claim := .rel ⟨.ro, 2436, false⟩ ARMS2 C3
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:C3-ARMS2", kind := .curatedDb, note := "STRING links C3 and ARMS2 with combined score 0.70 (experimental 0.24, database 0.00, text-mining 0.62)" }
  ]

/-- Run step complement_activation.2: C3 activates complement activation. -/
def S4 : Statement where
  id := "S4"
  text := "C3 activates complement activation"
  claim := .effect C3 .pos (.process complementActivation)
  evidence := [
    { pmid := 0, year := 2026, ref := "P01024", kind := .curatedDb, note := "it then recruits the serine protease complement C2b to form the C5 convertase, which cleaves and activate C5, the next component of the complement pathways" }
  ]

/-- Run step tnfrsf10a_apoptosis.1: TNFRSF10A activates apoptosis. -/
def S5 : Statement where
  id := "S5"
  text := "TNFRSF10A activates apoptosis"
  claim := .effect TNFRSF10A .pos (.process apoptoticProcess)
  evidence := [
    { pmid := 0, year := 2026, ref := "O00220", kind := .curatedDb, note := "The adapter molecule FADD recruits caspase-8 to the activated receptor. The resulting death-inducing signaling complex (DISC) performs caspase-8 proteolytic activation which initiates the subsequent cascade of caspases (aspartate-specific c" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-amd-google-cloud-gemini-3.1-pro-preview-single_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_amd_google_cloud_gemini_3_1_pro_preview_single_agent_r1
