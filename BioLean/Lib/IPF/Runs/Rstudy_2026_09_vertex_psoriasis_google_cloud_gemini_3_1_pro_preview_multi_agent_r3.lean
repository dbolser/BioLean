import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-multi_agent-r3`: google-cloud:gemini-3.1-pro-preview, psoriasis, genes IL12B, EGFL8, TRAF3IP2, TYK2, IL23R, GLE1, UHRF2. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_psoriasis_google_cloud_gemini_3_1_pro_preview_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def IL12B : Entity .protein := ⟨"UniProt:P29460", "IL12B"⟩
def IL23R : Entity .protein := ⟨"UniProt:Q5VWK5", "IL23R"⟩
def TYK2 : Entity .protein := ⟨"UniProt:P29597", "TYK2"⟩
def TRAF3IP2 : Entity .protein := ⟨"UniProt:O43734", "TRAF3IP2"⟩
def th17CellAmount : Entity .phenotype := ⟨"OBA:0005025", "T-helper 17 cell amount"⟩
def psoriasis : Entity .disease := ⟨"MONDO:0005083", "psoriasis"⟩

/-- Run step hyp1_il23_axis.1: IL12B binds IL23R. -/
def S1 : Statement where
  id := "S1"
  text := "IL12B binds IL23R"
  claim := .rel ⟨.ro, 2436, false⟩ IL12B IL23R
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:IL12B-IL23R", kind := .curatedDb, note := "STRING links IL12B and IL23R with combined score 0.99 (experimental 0.93, database 0.65, text-mining 0.46)." }
  ]

/-- Run step hyp1_il23_axis.2: IL23R activates TYK2. -/
def S2 : Statement where
  id := "S2"
  text := "IL23R activates TYK2"
  claim := .effect IL23R .pos (.activity TYK2)
  evidence := []

/-- Run step hyp1_il23_axis.3: TYK2 raises the amount of T-helper 17 cells. -/
def S5 : Statement where
  id := "S5"
  text := "TYK2 raises the amount of T-helper 17 cells"
  claim := .effect TYK2 .pos (.phenotype th17CellAmount)
  evidence := []

/-- Run step hyp1_il23_axis.4: the amount of T-helper 17 cells goes with psoriasis (direction not stated). Sign: the run's polarity is unknown and no cited text names Th17 cells, so the direction is none. -/
def S3 : Statement where
  id := "S3"
  text := "the amount of T-helper 17 cells goes with psoriasis (direction not stated)"
  claim := .assoc th17CellAmount none (.disease psoriasis)
  evidence := []

/-- Run step hyp2_traf3ip2_il17.1: TRAF3IP2 raises the risk of psoriasis. -/
def S4 : Statement where
  id := "S4"
  text := "TRAF3IP2 raises the risk of psoriasis"
  claim := .effect TRAF3IP2 .pos (.disease psoriasis)
  evidence := []

def statements : List Statement := [S1, S2, S5, S3, S4]

/-- hyp2_traf3ip2_il17, claim 1: TRAF3IP2 mediates downstream IL-17 inflammatory signaling in psoriasis. -/
def h2c1a1 := lit S4

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp2_traf3ip2_il17" "c1a1" h2c1a1]

#eval printRows "study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_psoriasis_google_cloud_gemini_3_1_pro_preview_multi_agent_r3
