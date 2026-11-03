import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-crohn-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-crohn-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r3`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, Crohn disease, genes IL12B, IL23R, NOD2, LACC1, GPR35, MEIS1, TRIM4. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_crohn_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def nod2Variant : Entity .variant := ⟨"BLN:NOD2-CrohnAssociatedVariants", "Crohn-associated NOD2 variants (unspecified; the run treats them as risk alleles)"⟩
def il23rVariant : Entity .variant := ⟨"BLN:IL23R-CrohnAssociatedVariants", "Crohn-associated IL23R variants (unspecified; the run treats them as risk alleles)"⟩
def il12bVariant : Entity .variant := ⟨"BLN:IL12B-CrohnAssociatedVariants", "Crohn-associated IL12B variants (unspecified; the run treats them as risk alleles)"⟩
def lacc1Variant : Entity .variant := ⟨"BLN:LACC1-CrohnAssociatedVariants", "Crohn-associated LACC1 variants (unspecified; the run treats them as risk alleles)"⟩
def bacterialDetection : Entity .process := ⟨"GO:0016045", "detection of bacterium"⟩
def bacterialDefense : Entity .process := ⟨"GO:0042742", "defense response to bacterium"⟩
def intestinalInflammation : Entity .phenotype := ⟨"HP:4000055", "Intestinal inflammation"⟩
def crohn : Entity .disease := ⟨"MONDO:0005011", "Crohn disease"⟩
def th17Differentiation : Entity .process := ⟨"GO:0072539", "T-helper 17 cell differentiation"⟩
def il12Production : Entity .process := ⟨"GO:0032615", "interleukin-12 production"⟩
def th1Response : Entity .process := ⟨"GO:0042088", "T-helper 1 type immune response"⟩
def th17Response : Entity .process := ⟨"GO:0072538", "T-helper 17 type immune response"⟩
def abnormalMetabolism : Entity .phenotype := ⟨"HP:0032245", "Abnormal metabolism"⟩
def tCell : Entity .cellType := ⟨"CL:0000084", "T cell"⟩
def abnormalTCellPhysiology : Entity .phenotype := ⟨"HP:0011840", "Abnormal T cell physiology"⟩
def tCellAbnormalMetabolism : Entity .phenotype := abnormalMetabolism.inCtx { cellType := tCell }

/-- Run step hypothesis_2.1: Crohn-associated IL23R variants raise Th17 cell differentiation. -/
def S6 : Statement where
  id := "S6"
  text := "Crohn-associated IL23R variants raise Th17 cell differentiation"
  claim := .effect il23rVariant .pos (.process th17Differentiation)
  evidence := []

/-- Run step hypothesis_2.2: Crohn-associated IL12B variants raise IL-12 production. -/
def S7 : Statement where
  id := "S7"
  text := "Crohn-associated IL12B variants raise IL-12 production"
  claim := .effect il12bVariant .pos (.process il12Production)
  evidence := []

/-- Run step hypothesis_3.1: Crohn-associated LACC1 variants cause abnormal T cell metabolism (run: lead to altered T cell metabolism). Sign: polarity field 'unknown'; the direction is from the cited PMID:40089498, which attributes the LACC1 promoter risk variants 'to changes in T cell metabolism': pos on abnormal metabolism refined to T cells (undirected-change rule). -/
def S12 : Statement where
  id := "S12"
  text := "Crohn-associated LACC1 variants cause abnormal T cell metabolism (run: lead to altered T cell metabolism)"
  claim := .effect lacc1Variant .pos (.phenotype tCellAbnormalMetabolism)
  evidence := [
    { pmid := 40089498, year := 2025, kind := .inVitro, note := "attributing promoter region variants to changes in T cell metabolism and function" }
  ]

/-- Run step hypothesis_3.3: abnormal T cell physiology causes intestinal inflammation (run: dysregulated T cell responses lead to intestinal inflammation). Sign: polarity field 'unknown'; the direction is from the cited PMID:40089498, which proposes the T cell changes as the mechanism 'linking these specific LACC1 variants to colitis' (a proposal, kind hypothesis); 'dysregulated T cell responses' is. -/
def S14 : Statement where
  id := "S14"
  text := "abnormal T cell physiology causes intestinal inflammation (run: dysregulated T cell responses lead to intestinal inflammation)"
  claim := .effect abnormalTCellPhysiology .pos (.phenotype intestinalInflammation)
  evidence := [
    { pmid := 40089498, year := 2025, kind := .hypothesis, note := "a mechanism linking these specific LACC1 variants to colitis by attributing promoter region variants to changes in T cell metabolism and function" }
  ]

def statements : List Statement := [S6, S7, S12, S14]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-crohn-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_crohn_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r3
