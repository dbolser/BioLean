import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-dcm-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-dcm-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r2`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, dilated cardiomyopathy, genes LMNA, MYH7, TTN, TNNT2, RBM20, ABCB9, OR8J3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_dcm_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def dcm : Entity .disease := ⟨"MONDO:0005021", "dilated cardiomyopathy"⟩
def ttnTruncating : Entity .variant := ⟨"BLN:TTN-truncatingVariant", "TTN truncating variant (any truncating allele)"⟩
def myh7Truncating : Entity .variant := ⟨"BLN:MYH7-truncatingVariant", "MYH7 truncating variant (any truncating allele)"⟩
def lmnaDominantNegative : Entity .variant := ⟨"BLN:LMNA-dominantNegativeVariant", "LMNA dominant-negative variant (any such allele)"⟩
def rbm20 : Entity .protein := ⟨"UniProt:Q5T481", "RBM20"⟩
def cardiacMuscleContraction : Entity .process := ⟨"GO:0060048", "cardiac muscle contraction"⟩
def alternativeSplicing : Entity .process := ⟨"GO:0000380", "alternative mRNA splicing, via spliceosome"⟩
def abnormalSarcomereIsoforms : Entity .phenotype := ⟨"BLN:AbnormalSarcomereProteinIsoforms", "abnormal isoform composition of sarcomere proteins"⟩
def increasedFragility : Entity .phenotype := ⟨"PATO:0002055", "increased fragility"⟩
def nuclearEnvelope : Entity .component := ⟨"GO:0005635", "nuclear envelope"⟩
def cellDeath : Entity .process := ⟨"GO:0008219", "cell death"⟩
def cardiomyocyte : Entity .cellType := ⟨"CL:0000746", "cardiac muscle cell"⟩
def myocardialFibrosis : Entity .phenotype := ⟨"HP:0001685", "Myocardial fibrosis"⟩
def nuclearEnvelopeFragility : Entity .phenotype := increasedFragility.inCtx { component := nuclearEnvelope }
def cardiomyocyteDeath : Entity .process := cellDeath.inCtx { cellType := cardiomyocyte }

/-- Run step hyp1.2: sarcomere (cardiac muscle) contraction lowers the risk of dilated cardiomyopathy; impaired contraction raises it. Sign: inverted: the run's subject is impaired sarcomere contraction, polarity positive. -/
def S1 : Statement where
  id := "S1"
  text := "sarcomere (cardiac muscle) contraction lowers the risk of dilated cardiomyopathy; impaired contraction raises it"
  claim := .effect cardiacMuscleContraction .neg (.disease dcm)
  evidence := []

/-- Run step hyp2.3: abnormal sarcomere protein isoforms raise the risk of dilated cardiomyopathy. -/
def S2 : Statement where
  id := "S2"
  text := "abnormal sarcomere protein isoforms raise the risk of dilated cardiomyopathy"
  claim := .effect abnormalSarcomereIsoforms .pos (.disease dcm)
  evidence := []

/-- Run step hyp3.3: cardiomyocyte death raises the risk of dilated cardiomyopathy. -/
def S3 : Statement where
  id := "S3"
  text := "cardiomyocyte death raises the risk of dilated cardiomyopathy"
  claim := .effect cardiomyocyteDeath .pos (.disease dcm)
  evidence := []

/-- Run step hyp3.3: myocardial fibrosis raises the risk of dilated cardiomyopathy. -/
def S4 : Statement where
  id := "S4"
  text := "myocardial fibrosis raises the risk of dilated cardiomyopathy"
  claim := .effect myocardialFibrosis .pos (.disease dcm)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-dcm-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_dcm_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r2
