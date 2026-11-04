import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-restless-legs-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-restless-legs-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r1`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, restless legs syndrome, genes ACO1, MEIS1, GLIPR1, PTPRD, GABARAPL2, BTBD9. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def MEIS1 : Entity .protein := ⟨"UniProt:O00470", "MEIS1"⟩
def BTBD9 : Entity .protein := ⟨"UniProt:Q96Q07", "BTBD9"⟩
def PTPRD : Entity .protein := ⟨"UniProt:P23468", "PTPRD"⟩
def rls : Entity .disease := ⟨"MONDO:0005391", "restless legs syndrome"⟩

/-- Run step h1.1: MEIS1 is associated with restless legs syndrome (direction not stated). Sign: the step's polarity is 'unknown' and it cites nothing; the mechanism's beta (rs113851554-T, 0.669) is for a variant allele, not the gene, and comes from no cited text. -/
def S1 : Statement where
  id := "S1"
  text := "MEIS1 is associated with restless legs syndrome (direction not stated)"
  claim := .assoc MEIS1 none (.disease rls)
  evidence := []

/-- Run step h2.1: BTBD9 is associated with restless legs syndrome (direction not stated). Sign: the step's polarity is 'unknown' and it cites nothing; the mechanism's beta (rs10947738-A, 0.282) is for a variant allele, not the gene, and comes from no cited text. -/
def S2 : Statement where
  id := "S2"
  text := "BTBD9 is associated with restless legs syndrome (direction not stated)"
  claim := .assoc BTBD9 none (.disease rls)
  evidence := []

/-- Run step h3.1: PTPRD is associated with restless legs syndrome (direction not stated). Sign: the step's polarity is 'unknown' and it cites nothing; the mechanism's beta (rs34602324-G, 0.121) is for a variant allele, not the gene, and comes from no cited text. -/
def S3 : Statement where
  id := "S3"
  text := "PTPRD is associated with restless legs syndrome (direction not stated)"
  claim := .assoc PTPRD none (.disease rls)
  evidence := []

def statements : List Statement := [S1, S2, S3]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-restless-legs-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r1
