import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-ipf-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-ipf-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r3`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, idiopathic pulmonary fibrosis, genes MUC5B, TERT, SFTPC, TOLLIP, DSP, FAM13A. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_ipf_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def rs35705950 : Entity .variant := ⟨"dbSNP:rs35705950", "rs35705950 T allele (MUC5B promoter)"⟩
def ipf : Entity .disease := ⟨"MONDO:0800504", "idiopathic pulmonary fibrosis"⟩
def TOLLIP : Entity .protein := ⟨"UniProt:Q9H0E2", "TOLLIP"⟩
def autophagy : Entity .process := ⟨"GO:0006914", "autophagy"⟩
def TERT : Entity .protein := ⟨"UniProt:O14746", "TERT"⟩
def shortTelomeres : Entity .phenotype := ⟨"HP:0031413", "Short telomere length"⟩
def sftpcMutation : Entity .variant := ⟨"BLN:SFTPC-mutation", "SFTPC mutation (any, unspecified; the run's note: misfolding mutations in rare familial cases)"⟩
def erStress : Entity .process := ⟨"GO:0034976", "response to endoplasmic reticulum stress"⟩
def aec : Entity .cellType := ⟨"CL:0000322", "pulmonary alveolar epithelial cell"⟩
def cellularSenescence : Entity .process := ⟨"GO:0090398", "cellular senescence"⟩
def apoptosis : Entity .process := ⟨"GO:0006915", "apoptotic process"⟩
def DSP : Entity .protein := ⟨"UniProt:P15924", "DSP"⟩
def epithelialStructureMaintenance : Entity .process := ⟨"GO:0010669", "epithelial structure maintenance"⟩
def FAM13A : Entity .protein := ⟨"UniProt:O94988", "FAM13A"⟩
def abnormalCytoskeleton : Entity .phenotype := ⟨"MP:0020378", "abnormal cell cytoskeleton morphology"⟩
def fibrotic : Entity .phenotype := ⟨"PATO:0040019", "fibrotic"⟩
def abnormalCellPhysiology : Entity .phenotype := ⟨"HP:0011017", "Abnormal cellular physiology"⟩
def epithelialCell : Entity .cellType := ⟨"CL:0000066", "epithelial cell"⟩
def aecSenescence : Entity .process := cellularSenescence.inCtx { cellType := aec }
def aecApoptosis : Entity .process := apoptosis.inCtx { cellType := aec }
def epithelialDysfunction : Entity .phenotype := abnormalCellPhysiology.inCtx { cellType := epithelialCell }

/-- Run step hyp1.1: the rs35705950 T allele raises the risk of IPF. -/
def S1 : Statement where
  id := "S1"
  text := "the rs35705950 T allele raises the risk of IPF"
  claim := .effect rs35705950 .pos (.disease ipf)
  evidence := []

/-- Run step hyp1.2: TOLLIP promotes autophagy (less TOLLIP, defective autophagy). Sign: inverted at both ends: the run's subject 'TOLLIP dysregulation' is undirected, its note says the variant 'may reduce TOLLIP expression'; the object is 'defective autophagy'. Reduced TOLLIP leads to reduced autophagy, so TOLLIP →+ autophagy. -/
def S2 : Statement where
  id := "S2"
  text := "TOLLIP promotes autophagy (less TOLLIP, defective autophagy)"
  claim := .effect TOLLIP .pos (.process autophagy)
  evidence := []

/-- Run step hyp2.1: TERT prevents short telomeres (TERT dysfunction leads to telomere shortening). Sign: inverted: the run's subject is 'TERT dysfunction' (note: variants 'reduce telomerase activity'). -/
def S3 : Statement where
  id := "S3"
  text := "TERT prevents short telomeres (TERT dysfunction leads to telomere shortening)"
  claim := .effect TERT .neg (.phenotype shortTelomeres)
  evidence := []

/-- Run step hyp2.2: SFTPC mutation causes ER stress. -/
def S4 : Statement where
  id := "S4"
  text := "SFTPC mutation causes ER stress"
  claim := .effect sftpcMutation .pos (.process erStress)
  evidence := []

/-- Run step hyp3.1: DSP maintains epithelial integrity (DSP dysfunction impairs epithelial barrier integrity). Sign: inverted at both ends: the run's subject is 'DSP dysfunction' (note: rs2076295 'disrupts desmosomal adhesion'), the object 'impaired epithelial barrier integrity'. -/
def S5 : Statement where
  id := "S5"
  text := "DSP maintains epithelial integrity (DSP dysfunction impairs epithelial barrier integrity)"
  claim := .effect DSP .pos (.process epithelialStructureMaintenance)
  evidence := []

/-- Run step hyp2.3: epithelial cell dysfunction drives senescence of alveolar epithelial cells (first half of the compound object 'senescence/apoptosis'). Sign: 'combined epithelial dysfunction' is an undirected change with an abnormal-X term (HP:0011017 Abnormal cellular physiology, refined to epithelial cell, as for 'AT2 cell dysfunction' in run 20260824T223623Z-4f7d1a), so pos is the step's own . -/
def S6 : Statement where
  id := "S6"
  text := "epithelial cell dysfunction drives senescence of alveolar epithelial cells (first half of the compound object 'senescence/apoptosis')"
  claim := .effect epithelialDysfunction .pos (.process aecSenescence)
  evidence := []

/-- Run step hyp2.3: epithelial cell dysfunction drives apoptosis of alveolar epithelial cells (second half of the compound object 'senescence/apoptosis'). Sign: as S6. -/
def S7 : Statement where
  id := "S7"
  text := "epithelial cell dysfunction drives apoptosis of alveolar epithelial cells (second half of the compound object 'senescence/apoptosis')"
  claim := .effect epithelialDysfunction .pos (.process aecApoptosis)
  evidence := []

/-- Run step hyp3.3: cytoskeletal defects drive fibrotic remodelling (cytoskeletal half of the compound subject 'combined cytoskeletal and signaling defects'). Sign: 'cytoskeletal defects' is an undirected change with an abnormal-X term (MP:0020378 abnormal cell cytoskeleton morphology; HP has none), so pos is the step's own polarity. -/
def S8 : Statement where
  id := "S8"
  text := "cytoskeletal defects drive fibrotic remodelling (cytoskeletal half of the compound subject 'combined cytoskeletal and signaling defects')"
  claim := .effect abnormalCytoskeleton .pos (.phenotype fibrotic)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8]

/-- hyp1, claim 1: Promoter variant drives mucin overexpression and impaired autophagy via MUC5B/TOLLIP co-regulation. -/
def h1c1a1 := lit S1

/-- hyp1, claim 3: Promoter variant drives mucin overexpression and impaired autophagy via MUC5B/TOLLIP co-regulation. -/
def h1c3a1 := lit S2

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp1" "c1a1" h1c1a1,
    arm "hyp1" "c3a1" h1c3a1]

#eval printRows "study-2026-09-vertex-ipf-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_ipf_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r3
