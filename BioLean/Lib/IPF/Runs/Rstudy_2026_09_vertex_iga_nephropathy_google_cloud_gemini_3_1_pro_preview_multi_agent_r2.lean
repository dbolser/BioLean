import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-multi_agent-r2`: google-cloud:gemini-3.1-pro-preview, IgA glomerulonephritis, genes TNFSF13, ITGAX, DEFA4, CFH, CARD9, OR4X1, ZNF174. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_google_cloud_gemini_3_1_pro_preview_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def DEFA4 : Entity .protein := ⟨"UniProt:P12838", "DEFA4"⟩
def CARD9 : Entity .protein := ⟨"UniProt:Q9H257", "CARD9"⟩
def TNFSF13 : Entity .protein := ⟨"UniProt:O75888", "TNFSF13"⟩
def CFH : Entity .protein := ⟨"UniProt:P08603", "CFH"⟩
def ITGAX : Entity .protein := ⟨"UniProt:P20702", "ITGAX"⟩
def intestinalMicrobiota : Entity .phenotype := ⟨"BLN:IntestinalMicrobiota", "intestinal microbiota (the host's gut microbial load, as a trait)"⟩
def gdIgA1 : Entity .phenotype := ⟨"OBA:2050057", "serum galactose-deficient IgA1 amount"⟩
def glomerularIgADeposition : Entity .phenotype := ⟨"HP:0000794", "IgA deposition in the glomerulus"⟩
def complementAP : Entity .process := ⟨"GO:0006957", "complement activation, alternative pathway"⟩
def igan : Entity .disease := ⟨"MONDO:0005342", "IgA glomerulonephritis"⟩

/-- Run step H1_mucosal_dysbiosis.1: DEFA4 inhibits the intestinal microbiota. -/
def S1 : Statement where
  id := "S1"
  text := "DEFA4 inhibits the intestinal microbiota"
  claim := .effect DEFA4 .neg (.phenotype intestinalMicrobiota)
  evidence := []

/-- Run step H1_mucosal_dysbiosis.2: the intestinal microbiota activates CARD9. -/
def S2 : Statement where
  id := "S2"
  text := "the intestinal microbiota activates CARD9"
  claim := .effect intestinalMicrobiota .pos (.activity CARD9)
  evidence := []

/-- Run step H1_mucosal_dysbiosis.3: CARD9 raises TNFSF13 (APRIL). -/
def S3 : Statement where
  id := "S3"
  text := "CARD9 raises TNFSF13 (APRIL)"
  claim := .effect CARD9 .pos (.amount TNFSF13)
  evidence := []

/-- Run step H1_mucosal_dysbiosis.4: TNFSF13 raises galactose-deficient IgA1. -/
def S4 : Statement where
  id := "S4"
  text := "TNFSF13 raises galactose-deficient IgA1"
  claim := .effect TNFSF13 .pos (.phenotype gdIgA1)
  evidence := []

/-- Run step H1_mucosal_dysbiosis.5: galactose-deficient IgA1 causes IgA nephropathy. -/
def S5 : Statement where
  id := "S5"
  text := "galactose-deficient IgA1 causes IgA nephropathy"
  claim := .effect gdIgA1 .pos (.disease igan)
  evidence := []

/-- Run step H2_complement_infiltration.1: glomerular IgA1 immune-complex deposits activate the alternative complement pathway. -/
def S6 : Statement where
  id := "S6"
  text := "glomerular IgA1 immune-complex deposits activate the alternative complement pathway"
  claim := .effect glomerularIgADeposition .pos (.process complementAP)
  evidence := []

/-- Run step H2_complement_infiltration.2: CFH inhibits the alternative complement pathway. -/
def S7 : Statement where
  id := "S7"
  text := "CFH inhibits the alternative complement pathway"
  claim := .effect CFH .neg (.process complementAP)
  evidence := [
    { pmid := 0, year := 2026, ref := "P08603", kind := .curatedDb, note := "Accelerates the decay of the complement alternative pathway (AP) C3 convertase C3bBb, thus preventing local formation of more C3b" }
  ]

/-- Run step H2_complement_infiltration.3: the alternative complement pathway activates ITGAX. -/
def S8 : Statement where
  id := "S8"
  text := "the alternative complement pathway activates ITGAX"
  claim := .effect complementAP .pos (.activity ITGAX)
  evidence := []

/-- Run step H2_complement_infiltration.4: ITGAX drives IgA nephropathy. -/
def S9 : Statement where
  id := "S9"
  text := "ITGAX drives IgA nephropathy"
  claim := .effect ITGAX .pos (.disease igan)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9]

/-- H1_mucosal_dysbiosis, claim 1: Intestinal dysbiosis drives CARD9-mediated TNFSF13 overproduction and Gd-IgA1 secretion. -/
def h1c1a1 := viaPhenotype (lit S1) (viaActivity (lit S2) (viaAmount (lit S3) (viaPhenotype (lit S4) (lit S5))))

/-- H1_mucosal_dysbiosis, claim 2: Intestinal dysbiosis drives CARD9-mediated TNFSF13 overproduction and Gd-IgA1 secretion. -/
def h1c2a1 := viaAmount (lit S3) (viaPhenotype (lit S4) (lit S5))

/-- H1_mucosal_dysbiosis, claim 3: Intestinal dysbiosis drives CARD9-mediated TNFSF13 overproduction and Gd-IgA1 secretion. -/
def h1c3a1 := viaPhenotype (lit S4) (lit S5)

/-- H2_complement_infiltration, claim 1: Defective CFH complement regulation recruits ITGAX-expressing myeloid cells to glomerular deposits. -/
def h2c1a1 := viaProcess (lit S7) (viaActivity (lit S8) (lit S9))

/-- H2_complement_infiltration, claim 2: Defective CFH complement regulation recruits ITGAX-expressing myeloid cells to glomerular deposits. -/
def h2c2a1 := lit S9

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1_mucosal_dysbiosis" "c1a1" h1c1a1,
    arm "H1_mucosal_dysbiosis" "c2a1" h1c2a1,
    arm "H1_mucosal_dysbiosis" "c3a1" h1c3a1,
    arm "H2_complement_infiltration" "c1a1" h2c1a1,
    arm "H2_complement_infiltration" "c2a1" h2c2a1]

#eval printRows "study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_google_cloud_gemini_3_1_pro_preview_multi_agent_r2
