import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-iga-nephropathy-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-iga-nephropathy-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, IgA glomerulonephritis, genes TNFSF13, ITGAX, DEFA4, CFH, CARD9, OR4X1, ZNF174. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def TNFSF13 : Entity .protein := ⟨"UniProt:O75888", "TNFSF13"⟩
def immunoglobulinProduction : Entity .process := ⟨"GO:0002377", "immunoglobulin production"⟩
def igaPlasmaCell : Entity .cellType := ⟨"CL:0000987", "IgA plasma cell"⟩
def igaGlomerularDeposition : Entity .phenotype := ⟨"HP:0000794", "IgA deposition in the glomerulus"⟩
def igan : Entity .disease := ⟨"MONDO:0005342", "IgA glomerulonephritis"⟩
def CFH : Entity .protein := ⟨"UniProt:P08603", "CFH"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def glomerulopathy : Entity .phenotype := ⟨"HP:0100820", "Glomerulopathy"⟩
def CARD9 : Entity .protein := ⟨"UniProt:Q9H257", "CARD9"⟩
def inflammatoryCytokineProduction : Entity .process := ⟨"GO:0002534", "cytokine production involved in inflammatory response"⟩
def ITGAX : Entity .protein := ⟨"UniProt:P20702", "ITGAX"⟩
def antigenPresentation : Entity .process := ⟨"GO:0019882", "antigen processing and presentation"⟩
def tCellActivation : Entity .process := ⟨"GO:0042110", "T cell activation"⟩
def glomerulonephritis : Entity .phenotype := ⟨"HP:0000099", "Glomerulonephritis"⟩
def igaProduction : Entity .process := immunoglobulinProduction.inCtx { cellType := igaPlasmaCell }

def statements : List Statement := []

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-iga-nephropathy-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r1
