import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/psoriasis-ukbt-n3-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `psoriasis-ukbt-n3-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r3`: google-cloud:gemini-3.1-pro-preview, psoriasis, genes ADAR, DVL2, ZBP1, CARS2, KHK, AP1G2, USP6, EIF2AK4, HELZ2, GUCA1C, IL11, UTP20. -/

namespace BioLean.Lib.IPF.Runs.Rpsoriasis_ukbt_n3_ukbt15_google_cloud_gemini_3_1_pro_preview_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def ADAR : Entity .protein := ⟨"UniProt:P55265", "ADAR"⟩
def aToIEditing : Entity .process := ⟨"GO:0006382", "adenosine to inosine editing"⟩
def ifnSignaling : Entity .process := ⟨"GO:0140888", "interferon-mediated signaling pathway"⟩
def psoriasis : Entity .disease := ⟨"MONDO:0005083", "psoriasis"⟩
def EIF2AK4 : Entity .protein := ⟨"UniProt:Q9P2K8", "EIF2AK4"⟩
def il17aProduction : Entity .process := ⟨"GO:0097087", "interleukin-17A production"⟩
def detc : Entity .cellType := ⟨"CL:0000916", "dendritic epidermal T cell"⟩
def il17aInDetc : Entity .process := il17aProduction.inCtx { cellType := detc }

/-- Run step hyp1.1: ADAR is required for A-to-I RNA editing (the run's 'formation of editosomes'): losing ADAR lowers it. -/
def S1 : Statement where
  id := "S1"
  text := "ADAR is required for A-to-I RNA editing (the run's 'formation of editosomes'): losing ADAR lowers it"
  claim := .effect ADAR .pos (.process aToIEditing)
  evidence := [
    { pmid := 42424135, year := 2026, kind := .inVitro, note := "ADAR1 knockdown or expression of ADAR1G1119R and ADAR1P3A alleles pathogenic variants reduced adenosine-to-inosine RNA editing" }
  ]

/-- Run step hyp1.2: A-to-I RNA editing (the run's 'formation of editosomes') inhibits interferon signalling. -/
def S2 : Statement where
  id := "S2"
  text := "A-to-I RNA editing (the run's 'formation of editosomes') inhibits interferon signalling"
  claim := .effect aToIEditing .neg (.process ifnSignaling)
  evidence := []

/-- Run step hyp1.3: interferon signalling leads to psoriasis. -/
def S3 : Statement where
  id := "S3"
  text := "interferon signalling leads to psoriasis"
  claim := .effect ifnSignaling .pos (.disease psoriasis)
  evidence := [
    { pmid := 42424135, year := 2026, kind := .observational, note := "define a novel IFN-dependent psoriasis subtype" }
  ]

/-- Run step hyp2.2: EIF2AK4 is associated with IL-17A production in epidermal gamma-delta T cells (direction not given). -/
def S4 : Statement where
  id := "S4"
  text := "EIF2AK4 is associated with IL-17A production in epidermal gamma-delta T cells (direction not given)"
  claim := .assoc EIF2AK4 none (.process il17aInDetc)
  evidence := []

/-- Run step hyp2.3: EIF2AK4 is associated with psoriasis risk (direction not given). Sign: no direction: the step's polarity is unknown, and the cited row's 'decrease' belongs to allele 'rs182525087-?', which names no allele and is not EIF2AK4 itself. -/
def S5 : Statement where
  id := "S5"
  text := "EIF2AK4 is associated with psoriasis risk (direction not given)"
  claim := .assoc EIF2AK4 none (.disease psoriasis)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs182525087", kind := .observational, note := "rs182525087-? is associated with 'Psoriasis' at p = 4e-6, beta 0.8275 unit (decrease) [0.47-1.18] (mapped gene EIF2AK4" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5]

/-- hyp1, claim 1: ADAR loss-of-function variants drive an interferon-dependent psoriasis subtype through impaired RNA editing.. -/
def h1c1a1 := viaProcess (lit S1) (viaProcess (lit S2) (lit S3))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp1" "c1a1" h1c1a1]

#eval printRows "psoriasis-ukbt-n3-ukbt15-google-cloud-gemini-3.1-pro-preview-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rpsoriasis_ukbt_n3_ukbt15_google_cloud_gemini_3_1_pro_preview_multi_agent_r3
