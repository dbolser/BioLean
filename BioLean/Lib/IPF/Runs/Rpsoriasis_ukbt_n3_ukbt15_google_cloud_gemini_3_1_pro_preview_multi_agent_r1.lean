import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/psoriasis-ukbt-n3-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `psoriasis-ukbt-n3-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r1`: google-cloud:gemini-3.1-pro-preview, psoriasis, genes ADAR, DVL2, ZBP1, CARS2, KHK, AP1G2, USP6, EIF2AK4, HELZ2, GUCA1C, IL11, UTP20. -/

namespace BioLean.Lib.IPF.Runs.Rpsoriasis_ukbt_n3_ukbt15_google_cloud_gemini_3_1_pro_preview_multi_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def ADAR : Entity .protein := ⟨"UniProt:P55265", "ADAR"⟩
def aToIEditing : Entity .process := ⟨"GO:0006382", "adenosine to inosine editing"⟩
def ifnSignaling : Entity .process := ⟨"GO:0140888", "interferon-mediated signaling pathway"⟩
def psoriasis : Entity .disease := ⟨"MONDO:0005083", "psoriasis"⟩
def DVL2 : Entity .protein := ⟨"UniProt:O14641", "DVL2"⟩
def wntDvlActivation : Entity .process := ⟨"Reactome:R-HSA-201688", "WNT mediated activation of DVL"⟩
def canonicalWnt : Entity .process := ⟨"GO:0060070", "canonical Wnt signaling pathway"⟩
def EIF2AK4 : Entity .protein := ⟨"UniProt:Q9P2K8", "EIF2AK4"⟩
def IL17A : Entity .protein := ⟨"UniProt:Q16552", "IL17A"⟩
def gdTCell : Entity .cellType := ⟨"CL:0000798", "gamma-delta T cell"⟩
def il17aInGdT : Entity .protein := IL17A.inCtx { cellType := gdTCell }

/-- Run step hyp1_ADAR.1: ADAR raises adenosine-to-inosine RNA editing. -/
def S1 : Statement where
  id := "S1"
  text := "ADAR raises adenosine-to-inosine RNA editing"
  claim := .effect ADAR .pos (.process aToIEditing)
  evidence := [
    { pmid := 42424135, year := 2026, kind := .inVitro, note := "ADAR1 knockdown or expression of ADAR1G1119R and ADAR1P3A alleles pathogenic variants reduced adenosine-to-inosine RNA editing" }
  ]

/-- Run step hyp1_ADAR.2: A-to-I RNA editing lowers interferon signalling. -/
def S2 : Statement where
  id := "S2"
  text := "A-to-I RNA editing lowers interferon signalling"
  claim := .effect aToIEditing .neg (.process ifnSignaling)
  evidence := []

/-- Run step hyp1_ADAR.3: interferon signalling drives psoriasis. -/
def S3 : Statement where
  id := "S3"
  text := "interferon signalling drives psoriasis"
  claim := .effect ifnSignaling .pos (.disease psoriasis)
  evidence := [
    { pmid := 42424135, year := 2026, kind := .observational, note := "a novel IFN-dependent psoriasis subtype" }
  ]

/-- Run step hyp2_DVL2.1: DVL2 activates the WNT-mediated activation of DVL (Reactome pathway). -/
def S4 : Statement where
  id := "S4"
  text := "DVL2 activates the WNT-mediated activation of DVL (Reactome pathway)"
  claim := .effect DVL2 .pos (.process wntDvlActivation)
  evidence := []

/-- Run step hyp2_DVL2.2: WNT-mediated activation of DVL activates canonical Wnt/beta-catenin signalling. -/
def S5 : Statement where
  id := "S5"
  text := "WNT-mediated activation of DVL activates canonical Wnt/beta-catenin signalling"
  claim := .effect wntDvlActivation .pos (.process canonicalWnt)
  evidence := []

/-- Run step hyp2_DVL2.3: canonical Wnt/beta-catenin signalling drives psoriasis. -/
def S6 : Statement where
  id := "S6"
  text := "canonical Wnt/beta-catenin signalling drives psoriasis"
  claim := .effect canonicalWnt .pos (.disease psoriasis)
  evidence := []

/-- Run step hyp3_EIF2AK4.1: EIF2AK4 lowers IL-17A in gamma-delta T cells. -/
def S7 : Statement where
  id := "S7"
  text := "EIF2AK4 lowers IL-17A in gamma-delta T cells"
  claim := .effect EIF2AK4 .neg (.amount il17aInGdT)
  evidence := []

/-- Run step hyp3_EIF2AK4.2: IL-17A goes with psoriasis (no direction). Sign: the run gives polarity 'unknown'; the cited text reports IL-17 production in a mouse psoriasis model with no comparison, so it gives no direction. -/
def S8 : Statement where
  id := "S8"
  text := "IL-17A goes with psoriasis (no direction)"
  claim := .assoc IL17A none (.disease psoriasis)
  evidence := [
    { pmid := 40073267, year := 2025, kind := .observational, note := "In murine models of wound repair and psoriasis, these epidermal γδ T cells upregulate CCR6 and produce IL-17", taxon := some Taxa.mouse }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8]

/-- hyp1_ADAR, claim 1: ADAR deficiency promotes an interferon-dependent psoriasis subtype. -/
def h1c1a1 := viaProcess (lit S1) (viaProcess (lit S2) (lit S3))

/-- hyp2_DVL2, claim 1: DVL2 mediates pathogenic Wnt/β-catenin signaling in psoriasis. -/
def h2c1a1 := viaProcess (lit S4) (viaProcess (lit S5) (lit S6))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp1_ADAR" "c1a1" h1c1a1,
    arm "hyp2_DVL2" "c1a1" h2c1a1]

#eval printRows "psoriasis-ukbt-n3-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rpsoriasis_ukbt_n3_ukbt15_google_cloud_gemini_3_1_pro_preview_multi_agent_r1
