import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-multi_agent-r2`: google-cloud:gemini-3.1-pro-preview, psoriasis, genes IL12B, EGFL8, TRAF3IP2, TYK2, IL23R, GLE1, UHRF2. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_psoriasis_google_cloud_gemini_3_1_pro_preview_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def IL12B : Entity .protein := ⟨"UniProt:P29460", "IL12B"⟩
def IL23R : Entity .protein := ⟨"UniProt:Q5VWK5", "IL23R"⟩
def TYK2 : Entity .protein := ⟨"UniProt:P29597", "TYK2"⟩
def TRAF3IP2 : Entity .protein := ⟨"UniProt:O43734", "TRAF3IP2"⟩
def EGFL8 : Entity .protein := ⟨"UniProt:Q99944", "EGFL8"⟩
def th17Response : Entity .process := ⟨"GO:0072538", "T-helper 17 type immune response"⟩
def psoriasis : Entity .disease := ⟨"MONDO:0005083", "psoriasis"⟩

/-- Run step hyp-1.1: IL12B binds IL23R. -/
def S1 : Statement where
  id := "S1"
  text := "IL12B binds IL23R"
  claim := .rel ⟨.ro, 2436, false⟩ IL12B IL23R
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:IL12B-IL23R", kind := .curatedDb, note := "STRING links IL12B and IL23R with combined score 0.99 (experimental 0.93, database 0.65, text-mining 0.46)" }
  ]

/-- Run step hyp-1.2: IL23R binds TYK2. -/
def S2 : Statement where
  id := "S2"
  text := "IL23R binds TYK2"
  claim := .rel ⟨.ro, 2436, false⟩ IL23R TYK2
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:IL23R-TYK2", kind := .curatedDb, note := "STRING links IL23R and TYK2 with combined score 0.98 (experimental 0.00, database 0.80, text-mining 0.90)" }
  ]

/-- Run step hyp-1.3: TYK2 is required for the T-helper 17 type immune response (required_for: losing TYK2 lowers it). -/
def S3 : Statement where
  id := "S3"
  text := "TYK2 is required for the T-helper 17 type immune response (required_for: losing TYK2 lowers it)"
  claim := .effect TYK2 .pos (.process th17Response)
  evidence := []

/-- Run step hyp-1.4: TRAF3IP2 is associated with the T-helper 17 type immune response (no direction given). -/
def S4 : Statement where
  id := "S4"
  text := "TRAF3IP2 is associated with the T-helper 17 type immune response (no direction given)"
  claim := .assoc TRAF3IP2 none (.process th17Response)
  evidence := []

/-- Run step hyp-1.5: The T-helper 17 type immune response leads to psoriasis. -/
def S5 : Statement where
  id := "S5"
  text := "The T-helper 17 type immune response leads to psoriasis"
  claim := .effect th17Response .pos (.disease psoriasis)
  evidence := []

/-- Run step hyp-2.1: EGFL8 leads to psoriasis. -/
def S6 : Statement where
  id := "S6"
  text := "EGFL8 leads to psoriasis"
  claim := .effect EGFL8 .pos (.disease psoriasis)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6]

/-- hyp-1, claim 3: Interleukin-23 receptor complex signaling via TYK2 and TRAF3IP2 drives Th17-mediated psoriasis. -/
def h1c3a1 := viaProcess (lit S3) (lit S5)

/-- hyp-2, claim 1: EGFL8 variants confer genetic susceptibility to psoriasis. -/
def h2c1a1 := lit S6

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp-1" "c3a1" h1c3a1,
    arm "hyp-2" "c1a1" h2c1a1]

#eval printRows "study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_psoriasis_google_cloud_gemini_3_1_pro_preview_multi_agent_r2
