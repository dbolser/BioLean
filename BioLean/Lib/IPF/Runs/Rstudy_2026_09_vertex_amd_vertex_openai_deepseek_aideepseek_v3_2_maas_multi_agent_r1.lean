import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-amd-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-amd-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r1`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, age-related macular degeneration, genes LIPC, ARMS2, CETP, C3, TNFRSF10A, MCF2L2, CACNA1E. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_amd_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def LIPC : Entity .protein := ⟨"UniProt:P11150", "LIPC"⟩
def CETP : Entity .protein := ⟨"UniProt:P11597", "CETP"⟩
def C3 : Entity .protein := ⟨"UniProt:P01024", "C3"⟩
def TNFRSF10A : Entity .protein := ⟨"UniProt:O00220", "TNFRSF10A"⟩
def amd : Entity .disease := ⟨"MONDO:0005150", "age-related macular degeneration"⟩
def lipoproteinRemodeling : Entity .process := ⟨"GO:0034369", "plasma lipoprotein particle remodeling"⟩
def bruchLipidDeposition : Entity .phenotype := ⟨"BLN:BruchMembraneLipidDeposition", "lipid deposition in Bruch's membrane"⟩
def complementAbnormality : Entity .phenotype := ⟨"HP:0005339", "Abnormality of complement system"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def chronicInflammation : Entity .process := ⟨"GO:0002544", "chronic inflammatory response"⟩
def trailSignaling : Entity .process := ⟨"GO:0036462", "TRAIL-activated apoptotic signaling pathway"⟩
def apoptoticProcess : Entity .process := ⟨"GO:0006915", "apoptotic process"⟩
def photoreceptorCell : Entity .cellType := ⟨"CL:0000210", "photoreceptor cell"⟩
def photoreceptorLoss : Entity .phenotype := ⟨"UPHENO:0085312", "decreased number of eye photoreceptor cell"⟩
def photoreceptorApoptosis : Entity .process := apoptoticProcess.inCtx { cellType := photoreceptorCell }

def statements : List Statement := []

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-amd-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_amd_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r1
