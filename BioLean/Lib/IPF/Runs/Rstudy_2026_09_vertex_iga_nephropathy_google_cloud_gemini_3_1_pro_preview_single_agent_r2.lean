import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-single_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-single_agent-r2`: google-cloud:gemini-3.1-pro-preview, IgA glomerulonephritis, genes TNFSF13, ITGAX, DEFA4, CFH, CARD9, OR4X1, ZNF174. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_google_cloud_gemini_3_1_pro_preview_single_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def TNFSF13 : Entity .protein := ⟨"UniProt:O75888", "TNFSF13"⟩
def bCellActivation : Entity .process := ⟨"GO:0042113", "B cell activation"⟩
def iga : Entity .protein := ⟨"PR:000050176", "IgA heavy chain protein"⟩
def igan : Entity .disease := ⟨"MONDO:0005342", "IgA glomerulonephritis"⟩
def CFH : Entity .protein := ⟨"UniProt:P08603", "CFH"⟩
def complementAP : Entity .process := ⟨"GO:0006957", "complement activation, alternative pathway"⟩
def CARD9 : Entity .protein := ⟨"UniProt:Q9H257", "CARD9"⟩
def ITGAX : Entity .protein := ⟨"UniProt:P20702", "ITGAX"⟩
def DEFA4 : Entity .protein := ⟨"UniProt:P12838", "DEFA4"⟩
def innateImmuneResponse : Entity .process := ⟨"GO:0045087", "innate immune response"⟩

/-- Run step hyp-1.1: TNFSF13 activates B cells (B cell activation). -/
def S1 : Statement where
  id := "S1"
  text := "TNFSF13 activates B cells (B cell activation)"
  claim := .effect TNFSF13 .pos (.process bCellActivation)
  evidence := []

/-- Run step hyp-1.2: B cells (activated) raise IgA. -/
def S2 : Statement where
  id := "S2"
  text := "B cells (activated) raise IgA"
  claim := .effect bCellActivation .pos (.amount iga)
  evidence := []

/-- Run step hyp-1.3: IgA leads to IgA nephropathy. -/
def S3 : Statement where
  id := "S3"
  text := "IgA leads to IgA nephropathy"
  claim := .effect iga .pos (.disease igan)
  evidence := []

/-- Run step hyp-2.1: CFH inhibits the complement alternative pathway. -/
def S4 : Statement where
  id := "S4"
  text := "CFH inhibits the complement alternative pathway"
  claim := .effect CFH .neg (.process complementAP)
  evidence := [
    { pmid := 0, year := 2026, ref := "P08603", kind := .curatedDb, note := "Accelerates the decay of the complement alternative pathway (AP) C3 convertase C3bBb, thus preventing local formation of more C3b" }
  ]

/-- Run step hyp-2.2: complement alternative pathway activation leads to IgA nephropathy. -/
def S5 : Statement where
  id := "S5"
  text := "complement alternative pathway activation leads to IgA nephropathy"
  claim := .effect complementAP .pos (.disease igan)
  evidence := []

/-- Run step hyp-3.1: CARD9 activates the innate immune response. -/
def S6 : Statement where
  id := "S6"
  text := "CARD9 activates the innate immune response"
  claim := .effect CARD9 .pos (.process innateImmuneResponse)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9H257", kind := .curatedDb, note := "plays a key role in innate immune response against fungi by forming signaling complexes downstream of C-type lectin receptors (PubMed:26961233, PubMed:33558980). CARD9-mediated signals are essential for antifungal immunity" }
  ]

/-- Run step hyp-3.2: ITGAX activates the innate immune response. -/
def S7 : Statement where
  id := "S7"
  text := "ITGAX activates the innate immune response"
  claim := .effect ITGAX .pos (.process innateImmuneResponse)
  evidence := []

/-- Run step hyp-3.3: DEFA4 activates the innate immune response. -/
def S8 : Statement where
  id := "S8"
  text := "DEFA4 activates the innate immune response"
  claim := .effect DEFA4 .pos (.process innateImmuneResponse)
  evidence := []

/-- Run step hyp-3.4: the innate immune response leads to IgA nephropathy. -/
def S9 : Statement where
  id := "S9"
  text := "the innate immune response leads to IgA nephropathy"
  claim := .effect innateImmuneResponse .pos (.disease igan)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9]

/-- hyp-1, claim 1: TNFSF13 promotes pathogenic IgA overproduction. -/
def h1c1a1 := viaProcess (lit S1) (viaAmount (lit S2) (lit S3))

/-- hyp-2, claim 1: CFH deficiency impairs complement regulation, exacerbating glomerular injury. -/
def h2c1a1 := viaProcess (lit S4) (lit S5)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp-1" "c1a1" h1c1a1,
    arm "hyp-2" "c1a1" h2c1a1]

#eval printRows "study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-single_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_google_cloud_gemini_3_1_pro_preview_single_agent_r2
