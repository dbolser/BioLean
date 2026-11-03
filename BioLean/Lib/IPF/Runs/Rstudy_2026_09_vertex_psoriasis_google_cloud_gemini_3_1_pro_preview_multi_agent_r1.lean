import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-multi_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-multi_agent-r1`: google-cloud:gemini-3.1-pro-preview, psoriasis, genes IL12B, EGFL8, TRAF3IP2, TYK2, IL23R, GLE1, UHRF2. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_psoriasis_google_cloud_gemini_3_1_pro_preview_multi_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def IL12B : Entity .protein := ⟨"UniProt:P29460", "IL12B"⟩
def IL23R : Entity .protein := ⟨"UniProt:Q5VWK5", "IL23R"⟩
def TYK2 : Entity .protein := ⟨"UniProt:P29597", "TYK2"⟩
def TRAF3IP2 : Entity .protein := ⟨"UniProt:O43734", "TRAF3IP2"⟩
def psoriasis : Entity .disease := ⟨"MONDO:0005083", "psoriasis"⟩

/-- Run step hyp_IL23_TRAF3IP2_psoriasis.1: IL12B binds IL23R. -/
def S1 : Statement where
  id := "S1"
  text := "IL12B binds IL23R"
  claim := .rel ⟨.ro, 2436, false⟩ IL12B IL23R
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:IL12B-IL23R", kind := .curatedDb, note := "STRING links IL12B and IL23R with combined score 0.99 (experimental 0.93, database 0.65, text-mining 0.46)" }
  ]

/-- Run step hyp_IL23_TRAF3IP2_psoriasis.2: IL23R activates TYK2. -/
def S2 : Statement where
  id := "S2"
  text := "IL23R activates TYK2"
  claim := .effect IL23R .pos (.activity TYK2)
  evidence := []

/-- Run step hyp_IL23_TRAF3IP2_psoriasis.3: TYK2 activates TRAF3IP2. -/
def S3 : Statement where
  id := "S3"
  text := "TYK2 activates TRAF3IP2"
  claim := .effect TYK2 .pos (.activity TRAF3IP2)
  evidence := []

/-- Run step hyp_IL23_TRAF3IP2_psoriasis.4: TRAF3IP2 leads to psoriasis. -/
def S4 : Statement where
  id := "S4"
  text := "TRAF3IP2 leads to psoriasis"
  claim := .effect TRAF3IP2 .pos (.disease psoriasis)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4]

/-- hyp_IL23_TRAF3IP2_psoriasis, claim 2: The IL-23 receptor complex utilizes TYK2 signaling to drive TRAF3IP2-mediated psoriatic inflammation.. -/
def h1c2a1 := viaActivity (lit S2) (viaActivity (lit S3) (lit S4))

/-- hyp_IL23_TRAF3IP2_psoriasis, claim 3: The IL-23 receptor complex utilizes TYK2 signaling to drive TRAF3IP2-mediated psoriatic inflammation.. -/
def h1c3a1 := viaActivity (lit S3) (lit S4)

/-- hyp_IL23_TRAF3IP2_psoriasis, claim 4: The IL-23 receptor complex utilizes TYK2 signaling to drive TRAF3IP2-mediated psoriatic inflammation.. -/
def h1c4a1 := lit S4

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp_IL23_TRAF3IP2_psoriasis" "c2a1" h1c2a1,
    arm "hyp_IL23_TRAF3IP2_psoriasis" "c3a1" h1c3a1,
    arm "hyp_IL23_TRAF3IP2_psoriasis" "c4a1" h1c4a1]

#eval printRows "study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-multi_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_psoriasis_google_cloud_gemini_3_1_pro_preview_multi_agent_r1
