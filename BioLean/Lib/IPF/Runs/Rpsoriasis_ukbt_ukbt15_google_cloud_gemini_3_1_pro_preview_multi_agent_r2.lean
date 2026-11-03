import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/psoriasis-ukbt-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `psoriasis-ukbt-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r2`: google-cloud:gemini-3.1-pro-preview, psoriasis, genes ADAR, DVL2, ZBP1, CARS2, KHK, AP1G2, USP6, EIF2AK4, HELZ2, GUCA1C, IL11, UTP20. -/

namespace BioLean.Lib.IPF.Runs.Rpsoriasis_ukbt_ukbt15_google_cloud_gemini_3_1_pro_preview_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def ADAR : Entity .protein := ⟨"UniProt:P55265", "ADAR"⟩
def aToIEditing : Entity .process := ⟨"GO:0006382", "adenosine to inosine editing"⟩
def ifnSignaling : Entity .process := ⟨"GO:0140888", "interferon-mediated signaling pathway"⟩
def psoriasis : Entity .disease := ⟨"MONDO:0005083", "psoriasis"⟩

/-- Run step h1_adar_interferon.1: ADAR is required for adenosine-to-inosine RNA editing (required_for: losing ADAR lowers editing). -/
def S1 : Statement where
  id := "S1"
  text := "ADAR is required for adenosine-to-inosine RNA editing (required_for: losing ADAR lowers editing)"
  claim := .effect ADAR .pos (.process aToIEditing)
  evidence := [
    { pmid := 42424135, year := 2026, kind := .inVitro, note := "ADAR1 knockdown or expression of ADAR1G1119R and ADAR1P3A alleles pathogenic variants reduced adenosine-to-inosine RNA editing" }
  ]

/-- Run step h1_adar_interferon.2: A-to-I RNA editing inhibits interferon signalling. -/
def S2 : Statement where
  id := "S2"
  text := "A-to-I RNA editing inhibits interferon signalling"
  claim := .effect aToIEditing .neg (.process ifnSignaling)
  evidence := []

/-- Run step h1_adar_interferon.3: interferon signalling raises the risk of psoriasis. Sign: the run gives this step 'unknown' polarity; the cited PMID:42424135 gives it as positive ('IFN-dependent psoriasis subtype'). -/
def S3 : Statement where
  id := "S3"
  text := "interferon signalling raises the risk of psoriasis"
  claim := .effect ifnSignaling .pos (.disease psoriasis)
  evidence := [
    { pmid := 42424135, year := 2026, kind := .observational, note := "a novel IFN-dependent psoriasis subtype" }
  ]

def statements : List Statement := [S1, S2, S3]

/-- h1_adar_interferon, claim 1: ADAR loss-of-function drives an interferon-dependent psoriasis subtype. -/
def h1c1a1 := viaProcess (lit S1) (viaProcess (lit S2) (lit S3))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "h1_adar_interferon" "c1a1" h1c1a1]

#eval printRows "psoriasis-ukbt-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rpsoriasis_ukbt_ukbt15_google_cloud_gemini_3_1_pro_preview_multi_agent_r2
