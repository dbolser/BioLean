import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-amd-google-cloud-gemini-3.1-pro-preview-multi_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-amd-google-cloud-gemini-3.1-pro-preview-multi_agent-r1`: google-cloud:gemini-3.1-pro-preview, age-related macular degeneration, genes LIPC, ARMS2, CETP, C3, TNFRSF10A, MCF2L2, CACNA1E. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_amd_google_cloud_gemini_3_1_pro_preview_multi_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def CETP : Entity .protein := ⟨"UniProt:P11597", "CETP"⟩
def LIPC : Entity .protein := ⟨"UniProt:P11150", "LIPC"⟩
def ARMS2 : Entity .protein := ⟨"UniProt:P0C7Q2", "ARMS2"⟩
def C3 : Entity .protein := ⟨"UniProt:P01024", "C3"⟩
def TNFRSF10A : Entity .protein := ⟨"UniProt:O00220", "TNFRSF10A"⟩
def cholesterolMetabolism : Entity .process := ⟨"GO:0008203", "cholesterol metabolic process"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def apoptosis : Entity .process := ⟨"GO:0006915", "apoptotic process"⟩
def retinalEndothelialCell : Entity .cellType := ⟨"CL:0002585", "retinal blood vessel endothelial cell"⟩
def amd : Entity .disease := ⟨"MONDO:0005150", "age-related macular degeneration"⟩
def retinalEndothelialApoptosis : Entity .process := apoptosis.inCtx { cellType := retinalEndothelialCell }

/-- Run step h1_cholesterol.1: CETP drives cholesterol metabolism. -/
def S1 : Statement where
  id := "S1"
  text := "CETP drives cholesterol metabolism"
  claim := .effect CETP .pos (.process cholesterolMetabolism)
  evidence := [
    { pmid := 0, year := 2026, ref := "P11597", kind := .curatedDb, note := "Allows the net movement of cholesteryl ester from high density lipoproteins/HDL to triglyceride-rich very low density lipoproteins/VLDL" }
  ]

/-- Run step h1_cholesterol.2: LIPC drives cholesterol metabolism. -/
def S2 : Statement where
  id := "S2"
  text := "LIPC drives cholesterol metabolism"
  claim := .effect LIPC .pos (.process cholesterolMetabolism)
  evidence := []

/-- Run step h1_cholesterol.3: cholesterol metabolism is associated with AMD (no direction). -/
def S3 : Statement where
  id := "S3"
  text := "cholesterol metabolism is associated with AMD (no direction)"
  claim := .assoc cholesterolMetabolism none (.disease amd)
  evidence := []

/-- Run step h2_complement.1: ARMS2 is associated with C3 (no direction). -/
def S4 : Statement where
  id := "S4"
  text := "ARMS2 is associated with C3 (no direction)"
  claim := .assoc ARMS2 none (.activity C3)
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:C3-ARMS2", kind := .curatedDb, note := "STRING links C3 and ARMS2 with combined score 0.70 (experimental 0.24, database 0.00, text-mining 0.62)" }
  ]

/-- Run step h2_complement.2: C3 drives complement activation. -/
def S5 : Statement where
  id := "S5"
  text := "C3 drives complement activation"
  claim := .effect C3 .pos (.process complementActivation)
  evidence := [
    { pmid := 0, year := 2026, ref := "P01024", kind := .curatedDb, note := "In the alternative complement pathway, recruits the serine protease CFB to form the C5 convertase that cleaves and activates C5" }
  ]

/-- Run step h2_complement.3: complement activation is associated with AMD (no direction). -/
def S6 : Statement where
  id := "S6"
  text := "complement activation is associated with AMD (no direction)"
  claim := .assoc complementActivation none (.disease amd)
  evidence := []

/-- Run step h3_apoptosis.1: TNFRSF10A drives apoptosis of retinal blood vessel endothelial cells. -/
def S7 : Statement where
  id := "S7"
  text := "TNFRSF10A drives apoptosis of retinal blood vessel endothelial cells"
  claim := .effect TNFRSF10A .pos (.process retinalEndothelialApoptosis)
  evidence := []

/-- Run step h3_apoptosis.2: apoptosis is associated with AMD (no direction). -/
def S8 : Statement where
  id := "S8"
  text := "apoptosis is associated with AMD (no direction)"
  claim := .assoc apoptosis none (.disease amd)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-amd-google-cloud-gemini-3.1-pro-preview-multi_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_amd_google_cloud_gemini_3_1_pro_preview_multi_agent_r1
