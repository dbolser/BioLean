import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-iga-nephropathy-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-iga-nephropathy-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, IgA glomerulonephritis, genes TNFSF13, ITGAX, DEFA4, CFH, CARD9, OR4X1, ZNF174. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def tnfsf13Variants : Entity .variant := ⟨"BLN:TNFSF13-variants", "unspecified TNFSF13 (APRIL) genetic variants"⟩
def cfhVariants : Entity .variant := ⟨"BLN:CFH-variants", "unspecified CFH genetic variants"⟩
def TNFSF13 : Entity .protein := ⟨"UniProt:O75888", "TNFSF13"⟩
def CFH : Entity .protein := ⟨"UniProt:P08603", "CFH"⟩
def DEFA4 : Entity .protein := ⟨"UniProt:P12838", "DEFA4"⟩
def bCellActivation : Entity .process := ⟨"GO:0042113", "B cell activation"⟩
def immunoglobulinProduction : Entity .process := ⟨"GO:0002377", "immunoglobulin production"⟩
def igaPlasmaCell : Entity .cellType := ⟨"CL:0000987", "IgA plasma cell"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def nephritis : Entity .phenotype := ⟨"HP:0000123", "Nephritis"⟩
def neutrophilMigration : Entity .process := ⟨"GO:1990266", "neutrophil migration"⟩
def neutrophilDegranulation : Entity .process := ⟨"GO:0043312", "neutrophil degranulation"⟩
def glomerulusAbnormal : Entity .phenotype := ⟨"HP:0000095", "Abnormal renal glomerulus morphology"⟩
def igan : Entity .disease := ⟨"MONDO:0005342", "IgA glomerulonephritis"⟩
def igaProduction : Entity .process := immunoglobulinProduction.inCtx { cellType := igaPlasmaCell }

/-- Run step 1.1: TNFSF13 genetic variants raise the amount of TNFSF13. -/
def S1 : Statement where
  id := "S1"
  text := "TNFSF13 genetic variants raise the amount of TNFSF13"
  claim := .effect tnfsf13Variants .pos (.amount TNFSF13)
  evidence := []

/-- Run step 1.2: TNFSF13 (APRIL) activates B cell activation. -/
def S2 : Statement where
  id := "S2"
  text := "TNFSF13 (APRIL) activates B cell activation"
  claim := .effect TNFSF13 .pos (.process bCellActivation)
  evidence := []

/-- Run step 2.1: CFH genetic variants lower the amount of complement factor H. -/
def S3 : Statement where
  id := "S3"
  text := "CFH genetic variants lower the amount of complement factor H"
  claim := .effect cfhVariants .neg (.amount CFH)
  evidence := []

/-- Run step 2.2: complement factor H inhibits complement activation. -/
def S4 : Statement where
  id := "S4"
  text := "complement factor H inhibits complement activation"
  claim := .effect CFH .neg (.process complementActivation)
  evidence := []

/-- Run step 3.1: DEFA4 activates neutrophil recruitment (neutrophil migration). -/
def S5 : Statement where
  id := "S5"
  text := "DEFA4 activates neutrophil recruitment (neutrophil migration)"
  claim := .effect DEFA4 .pos (.process neutrophilMigration)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-iga-nephropathy-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r2
