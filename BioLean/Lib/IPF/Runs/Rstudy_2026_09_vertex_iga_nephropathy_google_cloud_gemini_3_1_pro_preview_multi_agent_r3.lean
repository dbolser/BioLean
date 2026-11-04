import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-multi_agent-r3`: google-cloud:gemini-3.1-pro-preview, IgA glomerulonephritis, genes TNFSF13, ITGAX, DEFA4, CFH, CARD9, OR4X1, ZNF174. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_google_cloud_gemini_3_1_pro_preview_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def ITGAX : Entity .protein := ⟨"UniProt:P20702", "ITGAX"⟩
def CARD9 : Entity .protein := ⟨"UniProt:Q9H257", "CARD9"⟩
def TNFSF13 : Entity .protein := ⟨"UniProt:O75888", "TNFSF13"⟩
def CFH : Entity .protein := ⟨"UniProt:P08603", "CFH"⟩
def DEFA4 : Entity .protein := ⟨"UniProt:P12838", "DEFA4"⟩
def iC3b : Entity .protein := ⟨"PR:000019178", "complement C3 proteolytic cleavage product"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def neutrophilDegranulation : Entity .process := ⟨"GO:0043312", "neutrophil degranulation"⟩
def glomerularInjury : Entity .phenotype := ⟨"HP:0100820", "Glomerulopathy"⟩
def iga : Entity .disease := ⟨"MONDO:0005342", "IgA glomerulonephritis"⟩
def intestine : Entity .anatomy := ⟨"UBERON:0000160", "intestine"⟩
def kidney : Entity .anatomy := ⟨"UBERON:0002113", "kidney"⟩
def macrophage : Entity .cellType := ⟨"CL:0000235", "macrophage"⟩
def tnfsf13Intestine : Entity .protein := TNFSF13.inCtx { anatomy := intestine }

/-- Run step h1_card9_itgax_tnfsf13.1: ITGAX activates CARD9. -/
def S1 : Statement where
  id := "S1"
  text := "ITGAX activates CARD9"
  claim := .effect ITGAX .pos (.activity CARD9)
  evidence := []

/-- Run step h1_card9_itgax_tnfsf13.2: CARD9 raises the amount of TNFSF13 (APRIL) in the gut. -/
def S2 : Statement where
  id := "S2"
  text := "CARD9 raises the amount of TNFSF13 (APRIL) in the gut"
  claim := .effect CARD9 .pos (.amount tnfsf13Intestine)
  evidence := []

/-- Run step h2_cfh_itgax.1: CFH inhibits complement activation. -/
def S3 : Statement where
  id := "S3"
  text := "CFH inhibits complement activation"
  claim := .effect CFH .neg (.process complementActivation)
  evidence := []

/-- Run step h2_cfh_itgax.2: complement activation raises the amount of iC3b. -/
def S4 : Statement where
  id := "S4"
  text := "complement activation raises the amount of iC3b"
  claim := .effect complementActivation .pos (.amount iC3b)
  evidence := []

/-- Run step h2_cfh_itgax.3: iC3b binds ITGAX (CR4). -/
def S5 : Statement where
  id := "S5"
  text := "iC3b binds ITGAX (CR4)"
  claim := .rel ⟨.ro, 2436, false⟩ iC3b ITGAX
  evidence := []

/-- Run step h3_defa4.1: neutrophil degranulation raises the amount of DEFA4. -/
def S6 : Statement where
  id := "S6"
  text := "neutrophil degranulation raises the amount of DEFA4"
  claim := .effect neutrophilDegranulation .pos (.amount DEFA4)
  evidence := []

/-- Run step h3_defa4.2: DEFA4 leads to glomerular injury (glomerulopathy; the step's 'kidney' context is implied by the glomerulus). Sign: the run's polarity is unknown, but 'leads to glomerular injury' is an undirected change to an abnormal state that has an HP term, so the guide's undirected-change rule makes it pos on that phenotype. -/
def S7 : Statement where
  id := "S7"
  text := "DEFA4 leads to glomerular injury (glomerulopathy; the step's 'kidney' context is implied by the glomerulus)"
  claim := .effect DEFA4 .pos (.phenotype glomerularInjury)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_google_cloud_gemini_3_1_pro_preview_multi_agent_r3
