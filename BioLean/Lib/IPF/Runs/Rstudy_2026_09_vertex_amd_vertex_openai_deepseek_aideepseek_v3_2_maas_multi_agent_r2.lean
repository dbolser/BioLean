import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-amd-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-amd-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, age-related macular degeneration, genes LIPC, ARMS2, CETP, C3, TNFRSF10A, MCF2L2, CACNA1E. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_amd_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def LIPC : Entity .protein := ⟨"UniProt:P11150", "LIPC"⟩
def CETP : Entity .protein := ⟨"UniProt:P11597", "CETP"⟩
def C3 : Entity .protein := ⟨"UniProt:P01024", "C3"⟩
def TNFRSF10A : Entity .protein := ⟨"UniProt:O00220", "TNFRSF10A"⟩
def ARMS2 : Entity .protein := ⟨"UniProt:P0C7Q2", "ARMS2"⟩
def amd : Entity .disease := ⟨"MONDO:0005150", "age-related macular degeneration"⟩
def abnormalLipidMetabolism : Entity .phenotype := ⟨"MP:0013245", "abnormal lipid metabolism"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def retinitis : Entity .phenotype := ⟨"HP:0032118", "Retinitis"⟩
def retinalDegeneration : Entity .phenotype := ⟨"HP:0000546", "Retinal degeneration"⟩
def apoptoticSignaling : Entity .process := ⟨"GO:0097190", "apoptotic signaling pathway"⟩
def cellDeath : Entity .process := ⟨"GO:0008219", "cell death"⟩
def retina : Entity .anatomy := ⟨"UBERON:0000966", "retina"⟩
def retinalCellDeath : Entity .process := cellDeath.inCtx { anatomy := retina }

/-- Run step hyp1.3: abnormal lipid metabolism raises AMD risk. -/
def S1 : Statement where
  id := "S1"
  text := "abnormal lipid metabolism raises AMD risk"
  claim := .effect abnormalLipidMetabolism .pos (.disease amd)
  evidence := []

/-- Run step hyp2.1: C3 activates complement activation. -/
def S2 : Statement where
  id := "S2"
  text := "C3 activates complement activation"
  claim := .effect C3 .pos (.process complementActivation)
  evidence := []

/-- Run step hyp2.2: complement activation leads to retinal inflammation (retinitis). -/
def S3 : Statement where
  id := "S3"
  text := "complement activation leads to retinal inflammation (retinitis)"
  claim := .effect complementActivation .pos (.phenotype retinitis)
  evidence := []

/-- Run step hyp2.2: complement activation leads to retinal damage (retinal degeneration). -/
def S4 : Statement where
  id := "S4"
  text := "complement activation leads to retinal damage (retinal degeneration)"
  claim := .effect complementActivation .pos (.phenotype retinalDegeneration)
  evidence := []

/-- Run step hyp2.3: retinal inflammation (retinitis) leads to AMD. -/
def S5 : Statement where
  id := "S5"
  text := "retinal inflammation (retinitis) leads to AMD"
  claim := .effect retinitis .pos (.disease amd)
  evidence := []

/-- Run step hyp2.3: retinal damage (retinal degeneration) leads to AMD. -/
def S6 : Statement where
  id := "S6"
  text := "retinal damage (retinal degeneration) leads to AMD"
  claim := .effect retinalDegeneration .pos (.disease amd)
  evidence := []

/-- Run step hyp3.1: TNFRSF10A activates apoptotic signaling. -/
def S7 : Statement where
  id := "S7"
  text := "TNFRSF10A activates apoptotic signaling"
  claim := .effect TNFRSF10A .pos (.process apoptoticSignaling)
  evidence := []

/-- Run step hyp3.2: apoptotic signaling leads to retinal cell death. -/
def S8 : Statement where
  id := "S8"
  text := "apoptotic signaling leads to retinal cell death"
  claim := .effect apoptoticSignaling .pos (.process retinalCellDeath)
  evidence := []

/-- Run step hyp3.3: retinal cell death leads to AMD. -/
def S9 : Statement where
  id := "S9"
  text := "retinal cell death leads to AMD"
  claim := .effect retinalCellDeath .pos (.disease amd)
  evidence := []

/-- Run step hyp4.1: ARMS2 is associated with AMD. Sign: none: the step's polarity is unknown, and the cited rows give directions for alleles (rs36212733-C beta increase, rs10490924-T OR 2.76, rs3750846 allele not given), not for ARMS2 itself. -/
def S10 : Statement where
  id := "S10"
  text := "ARMS2 is associated with AMD"
  claim := .assoc ARMS2 none (.disease amd)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs36212733", kind := .observational, note := "rs36212733-C is associated with 'Age-related macular degeneration' at p = 7e-1192, beta 0.6057 unit (increase) [0.59-0.62] (mapped gene ARMS2" },
    { pmid := 0, year := 2026, ref := "rs3750846", kind := .observational, note := "rs3750846-? is associated with 'Advanced age-related macular degeneration' at p = 7e-735, odds ratio 2.81 (author-reported gene ARMS2" },
    { pmid := 0, year := 2026, ref := "rs10490924", kind := .observational, note := "rs10490924-T is associated with 'Age-related macular degeneration' at p = 4e-540, odds ratio 2.76 [2.72-2.80] (author-reported gene ARMS2" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-amd-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_amd_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r2
