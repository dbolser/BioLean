import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-restless-legs-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-restless-legs-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r2`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, restless legs syndrome, genes ACO1, MEIS1, GLIPR1, PTPRD, GABARAPL2, BTBD9. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def MEIS1 : Entity .protein := ⟨"UniProt:O00470", "MEIS1"⟩
def BTBD9 : Entity .protein := ⟨"UniProt:Q96Q07", "BTBD9"⟩
def PTPRD : Entity .protein := ⟨"UniProt:P23468", "PTPRD"⟩
def rls : Entity .disease := ⟨"MONDO:0005391", "restless legs syndrome"⟩
def brain : Entity .anatomy := ⟨"UBERON:0000955", "brain"⟩
def synapticTransmission : Entity .process := ⟨"GO:0007268", "chemical synaptic transmission"⟩
def synapticPlasticity : Entity .process := ⟨"GO:0048167", "regulation of synaptic plasticity"⟩

/-- Run step MEIS1-cerebellar-disinhibition.1: MEIS1 is associated with restless legs syndrome (unsigned). -/
def S1 : Statement where
  id := "S1"
  text := "MEIS1 is associated with restless legs syndrome (unsigned)"
  claim := .assoc MEIS1 none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:MEIS1-MONDO_0005391", kind := .observational, note := "scores the MEIS1-restless legs syndrome association at 0.55" },
    { pmid := 42309051, year := 2026, kind := .review, note := "restless legs syndrome-associated gene MEIS1" }
  ]

/-- Run step MEIS1-cerebellar-disinhibition.2: MEIS1 is expressed in brain (the run's relation is 'translocates'). -/
def S2 : Statement where
  id := "S2"
  text := "MEIS1 is expressed in brain (the run's relation is 'translocates')"
  claim := .rel ⟨.ro, 2206, false⟩ MEIS1 brain
  evidence := []

/-- Run step BTBD9-synaptic-dopamine.1: BTBD9 is associated with restless legs syndrome (unsigned). -/
def S3 : Statement where
  id := "S3"
  text := "BTBD9 is associated with restless legs syndrome (unsigned)"
  claim := .assoc BTBD9 none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:BTBD9-MONDO_0005391", kind := .observational, note := "scores the BTBD9-restless legs syndrome association at 0.48" }
  ]

/-- Run step BTBD9-synaptic-dopamine.2: BTBD9 lowers synaptic transmission. Sign: the run's sign as written: subject BTBD9 (no loss wording), relation leads_to, polarity negative; the title says BTBD9 loss impairs transmission, which would be positive. -/
def S4 : Statement where
  id := "S4"
  text := "BTBD9 lowers synaptic transmission"
  claim := .effect BTBD9 .neg (.process synapticTransmission)
  evidence := []

/-- Run step PTPRD-synaptic-adhesion.1: PTPRD is associated with restless legs syndrome (unsigned). -/
def S5 : Statement where
  id := "S5"
  text := "PTPRD is associated with restless legs syndrome (unsigned)"
  claim := .assoc PTPRD none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:PTPRD-MONDO_0005391", kind := .observational, note := "scores the PTPRD-restless legs syndrome association at 0.39" }
  ]

/-- Run step PTPRD-synaptic-adhesion.2: PTPRD raises synaptic plasticity. -/
def S6 : Statement where
  id := "S6"
  text := "PTPRD raises synaptic plasticity"
  claim := .effect PTPRD .pos (.process synapticPlasticity)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6]

/-- BTBD9-synaptic-dopamine, claim 2: BTBD9 loss impairs synaptic transmission and dopamine signaling, causing sleep-related motor symptoms. -/
def h2c2a1 := lit S4

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "BTBD9-synaptic-dopamine" "c2a1" h2c2a1]

#eval printRows "study-2026-09-vertex-restless-legs-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r2
