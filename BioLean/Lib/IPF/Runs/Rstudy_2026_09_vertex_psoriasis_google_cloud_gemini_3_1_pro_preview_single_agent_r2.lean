import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-single_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-single_agent-r2`: google-cloud:gemini-3.1-pro-preview, psoriasis, genes IL12B, EGFL8, TRAF3IP2, TYK2, IL23R, GLE1, UHRF2. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_psoriasis_google_cloud_gemini_3_1_pro_preview_single_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def IL12B : Entity .protein := ⟨"UniProt:P29460", "IL12B"⟩
def IL23R : Entity .protein := ⟨"UniProt:Q5VWK5", "IL23R"⟩
def TYK2 : Entity .protein := ⟨"UniProt:P29597", "TYK2"⟩
def TRAF3IP2 : Entity .protein := ⟨"UniProt:O43734", "TRAF3IP2"⟩
def cytokineProduction : Entity .process := ⟨"GO:0001816", "cytokine production"⟩
def psoriasis : Entity .disease := ⟨"MONDO:0005083", "psoriasis"⟩

/-- Run step hyp1.1: IL12B binds IL23R. -/
def S1 : Statement where
  id := "S1"
  text := "IL12B binds IL23R"
  claim := .rel ⟨.ro, 2436, false⟩ IL12B IL23R
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:IL12B-IL23R", kind := .curatedDb, note := "STRING links IL12B and IL23R with combined score 0.99 (experimental 0.93, database 0.65, text-mining 0.46)" }
  ]

/-- Run step hyp1.2: IL23R binds TYK2. -/
def S2 : Statement where
  id := "S2"
  text := "IL23R binds TYK2"
  claim := .rel ⟨.ro, 2436, false⟩ IL23R TYK2
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:IL23R-TYK2", kind := .curatedDb, note := "STRING links IL23R and TYK2 with combined score 0.98 (experimental 0.00, database 0.80, text-mining 0.90)" }
  ]

/-- Run step hyp1.3: TYK2 raises the risk of psoriasis. -/
def S3 : Statement where
  id := "S3"
  text := "TYK2 raises the risk of psoriasis"
  claim := .effect TYK2 .pos (.disease psoriasis)
  evidence := []

/-- Run step hyp2.1: TRAF3IP2 raises cytokine production (run: increases_amount 'Cytokine'). Sign: the run's object is the protein class 'Cytokine' with increases_amount; GO:0001816 is defined as the appearance of a cytokine resulting in an increase in its levels, so the sign carries over unchanged. -/
def S4 : Statement where
  id := "S4"
  text := "TRAF3IP2 raises cytokine production (run: increases_amount 'Cytokine')"
  claim := .effect TRAF3IP2 .pos (.process cytokineProduction)
  evidence := []

/-- Run step hyp2.2: TRAF3IP2 is associated with psoriasis (no direction). Sign: the run gives polarity unknown; the cited GWAS row gives a direction only for the rs33980500-T allele, not for TRAF3IP2 itself, so the direction stays none. -/
def S5 : Statement where
  id := "S5"
  text := "TRAF3IP2 is associated with psoriasis (no direction)"
  claim := .assoc TRAF3IP2 none (.disease psoriasis)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs33980500", kind := .observational, note := "rs33980500-T is associated with 'Psoriasis' at p = 4e-45, odds ratio 1.52 (author-reported gene TRAF3IP2" },
    { pmid := 0, year := 2026, ref := "OT:TRAF3IP2-MONDO_0005083", kind := .observational, note := "Open Targets 2026.06 scores the TRAF3IP2-psoriasis association at 0.67" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5]

/-- hyp1, claim 3: IL-23 receptor signaling via TYK2 drives Th17 expansion in psoriasis. -/
def h1c3a1 := lit S3

/-- hyp2, claim 2: TRAF3IP2 mediates downstream inflammatory signaling in target cells. -/
def h2c2a1 := lit S4

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp1" "c3a1" h1c3a1,
    arm "hyp2" "c2a1" h2c2a1]

#eval printRows "study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-single_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_psoriasis_google_cloud_gemini_3_1_pro_preview_single_agent_r2
