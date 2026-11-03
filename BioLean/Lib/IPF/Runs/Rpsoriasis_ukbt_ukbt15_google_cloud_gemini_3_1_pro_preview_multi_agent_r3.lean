import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/psoriasis-ukbt-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `psoriasis-ukbt-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r3`: google-cloud:gemini-3.1-pro-preview, psoriasis, genes ADAR, DVL2, ZBP1, CARS2, KHK, AP1G2, USP6, EIF2AK4, HELZ2, GUCA1C, IL11, UTP20. -/

namespace BioLean.Lib.IPF.Runs.Rpsoriasis_ukbt_ukbt15_google_cloud_gemini_3_1_pro_preview_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def ADAR : Entity .protein := ⟨"UniProt:P55265", "ADAR"⟩
def atoiEditing : Entity .process := ⟨"GO:0006382", "adenosine to inosine editing"⟩
def typeIIfnSignaling : Entity .process := ⟨"GO:0060337", "type I interferon-mediated signaling pathway"⟩
def psoriasis : Entity .disease := ⟨"MONDO:0005083", "psoriasis"⟩

/-- Run step hyp_ADAR_psoriasis.1: ADAR is required for A-to-I RNA editing (losing ADAR lowers editing). -/
def S1 : Statement where
  id := "S1"
  text := "ADAR is required for A-to-I RNA editing (losing ADAR lowers editing)"
  claim := .effect ADAR .pos (.process atoiEditing)
  evidence := [
    { pmid := 0, year := 2026, ref := "P55265", kind := .curatedDb, note := "Catalyzes the hydrolytic deamination of adenosine to inosine in double-stranded RNA (dsRNA) referred to as A-to-I RNA editing" },
    { pmid := 42424135, year := 2026, kind := .inVitro, note := "ADAR1 knockdown or expression of ADAR1G1119R and ADAR1P3A alleles pathogenic variants reduced adenosine-to-inosine RNA editing" }
  ]

/-- Run step hyp_ADAR_psoriasis.2: A-to-I RNA editing inhibits type I interferon signaling. -/
def S2 : Statement where
  id := "S2"
  text := "A-to-I RNA editing inhibits type I interferon signaling"
  claim := .effect atoiEditing .neg (.process typeIIfnSignaling)
  evidence := []

/-- Run step hyp_ADAR_psoriasis.3: type I interferon signaling goes with psoriasis (higher IFN signalling in psoriasis). Sign: the run's polarity is 'unknown'; the text it cited gives the direction: psoriasis families 'characterized by a strong IFN signature in skin and blood' (PMID:42424135). -/
def S3 : Statement where
  id := "S3"
  text := "type I interferon signaling goes with psoriasis (higher IFN signalling in psoriasis)"
  claim := .assoc typeIIfnSignaling (some .pos) (.disease psoriasis)
  evidence := [
    { pmid := 42424135, year := 2026, kind := .observational, note := "early-onset plaque psoriasis, with or without psoriatic arthritis, segregating as a monogenic trait and characterized by a strong IFN signature in skin and blood" }
  ]

def statements : List Statement := [S1, S2, S3]

/-- hyp_ADAR_psoriasis, claim 1: ADAR loss-of-function drives an interferon-dependent subtype of psoriasis. -/
def h1c1a1 := viaProcess (lit S1) (viaProcess (lit S2) (fromAssoc (lit S3)))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp_ADAR_psoriasis" "c1a1" h1c1a1]

#eval printRows "psoriasis-ukbt-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rpsoriasis_ukbt_ukbt15_google_cloud_gemini_3_1_pro_preview_multi_agent_r3
