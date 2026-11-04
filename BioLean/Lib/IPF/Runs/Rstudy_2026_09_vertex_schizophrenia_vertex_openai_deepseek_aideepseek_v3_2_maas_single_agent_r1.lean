import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-schizophrenia-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-schizophrenia-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, schizophrenia, genes CSMD1, NXPH3, C4A, CX3CR1, CCDC136, C1QA, C4B. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_schizophrenia_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def C4A : Entity .protein := ⟨"UniProt:P0C0L4", "C4A"⟩
def CSMD1 : Entity .protein := ⟨"UniProt:Q96PZ7", "CSMD1"⟩
def CX3CR1 : Entity .protein := ⟨"UniProt:P49238", "CX3CR1"⟩
def C1QA : Entity .protein := ⟨"UniProt:P02745", "C1QA"⟩
def NXPH3 : Entity .protein := ⟨"UniProt:O95157", "NXPH3"⟩
def schizophrenia : Entity .disease := ⟨"MONDO:0005090", "schizophrenia"⟩
def synapsePruning : Entity .process := ⟨"GO:0098883", "synapse pruning"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def abnormalMicrogliaPhysiology : Entity .phenotype := ⟨"MP:0003691", "abnormal microglial cell physiology"⟩
def impairedSynapticPhysiology : Entity .phenotype := ⟨"MP:0021010", "impaired synaptic physiology"⟩
def synapticMembraneAdhesion : Entity .process := ⟨"GO:0099560", "synaptic membrane adhesion"⟩
def synapseMaintenance : Entity .process := ⟨"GO:0099558", "maintenance of synapse structure"⟩
def synapticConnectivity : Entity .phenotype := ⟨"BLN:SynapticConnectivity", "synaptic connectivity (the pattern and number of synaptic connections within a neural circuit)"⟩

/-- Run step H1.2: C4A drives synapse pruning. -/
def S1 : Statement where
  id := "S1"
  text := "C4A drives synapse pruning"
  claim := .effect C4A .pos (.process synapsePruning)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .mechanistic, note := "In mice, C4 mediated synapse elimination during postnatal development.", taxon := some Taxa.mouse }
  ]

/-- Run step H1.3: excessive synapse pruning causes schizophrenia. -/
def S2 : Statement where
  id := "S2"
  text := "excessive synapse pruning causes schizophrenia"
  claim := .effect synapsePruning .pos (.disease schizophrenia)
  evidence := []

/-- Run step H2.1: CX3CR1 is associated with schizophrenia (no direction given by the step). -/
def S3 : Statement where
  id := "S3"
  text := "CX3CR1 is associated with schizophrenia (no direction given by the step)"
  claim := .assoc CX3CR1 none (.disease schizophrenia)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:CX3CR1-MONDO_0005090", kind := .textMined, note := "Open Targets 2026.06 scores the CX3CR1-schizophrenia association at 0.06 (literature 0.50)." },
    { pmid := 42276261, year := 2026, kind := .observational, note := "In SZ individuals, blood CX3CR1 underexpression in the peripheral blood may serve as a peripheral biomarker" }
  ]

/-- Run step H2.2: CX3CR1 loss impairs microglial function (CX3CR1 lowers abnormal microglial physiology). Sign: inverted: the run's subject is CX3CR1 deficiency; its object 'impaired microglial function' is grounded as the abnormal-microglial-physiology phenotype, which the deficiency raises. -/
def S4 : Statement where
  id := "S4"
  text := "CX3CR1 loss impairs microglial function (CX3CR1 lowers abnormal microglial physiology)"
  claim := .effect CX3CR1 .neg (.phenotype abnormalMicrogliaPhysiology)
  evidence := []

/-- Run step H2.3: C1QA activates complement. -/
def S5 : Statement where
  id := "S5"
  text := "C1QA activates complement"
  claim := .effect C1QA .pos (.process complementActivation)
  evidence := []

/-- Run step H2.4: impaired microglial function leads to synaptic dysfunction. Sign: not inverted: 'impaired microglial function' is grounded as the abnormal phenotype itself. -/
def S6 : Statement where
  id := "S6"
  text := "impaired microglial function leads to synaptic dysfunction"
  claim := .effect abnormalMicrogliaPhysiology .pos (.phenotype impairedSynapticPhysiology)
  evidence := []

/-- Run step H2.4: complement activation leads to synaptic dysfunction. -/
def S7 : Statement where
  id := "S7"
  text := "complement activation leads to synaptic dysfunction"
  claim := .effect complementActivation .pos (.phenotype impairedSynapticPhysiology)
  evidence := []

/-- Run step H3.1: NXPH3 is associated with schizophrenia (no direction given by the step). -/
def S8 : Statement where
  id := "S8"
  text := "NXPH3 is associated with schizophrenia (no direction given by the step)"
  claim := .assoc NXPH3 none (.disease schizophrenia)
  evidence := []

/-- Run step H3.2: NXPH3 is required for synaptic membrane adhesion (losing NXPH3 lowers it). -/
def S9 : Statement where
  id := "S9"
  text := "NXPH3 is required for synaptic membrane adhesion (losing NXPH3 lowers it)"
  claim := .effect NXPH3 .pos (.process synapticMembraneAdhesion)
  evidence := []

/-- Run step H3.2: NXPH3 is required for synapse stability (losing NXPH3 lowers it). -/
def S10 : Statement where
  id := "S10"
  text := "NXPH3 is required for synapse stability (losing NXPH3 lowers it)"
  claim := .effect NXPH3 .pos (.process synapseMaintenance)
  evidence := []

/-- Run step H3.3: NXPH3 loss disrupts synaptic connectivity. Sign: inverted twice: the run's subject is NXPH3 dysfunction and its object is disrupted synaptic connectivity. -/
def S11 : Statement where
  id := "S11"
  text := "NXPH3 loss disrupts synaptic connectivity"
  claim := .effect NXPH3 .pos (.phenotype synapticConnectivity)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11]

/-- H1, claim 1: Complement dysregulation: C4A-mediated excessive synaptic pruning unchecked by CSMD1 deficiency. -/
def h1c1a1 := viaProcess (lit S1) (lit S2)

/-- H2, claim 2: Microglial dysfunction: CX3CR1 impairment plus C1QA-mediated complement activation disrupt synaptic homeostasis. -/
def h2c2a1 := viaPhenotype (lit S4) (lit S6)

/-- H2, claim 4: Microglial dysfunction: CX3CR1 impairment plus C1QA-mediated complement activation disrupt synaptic homeostasis. -/
def h2c4a1 := viaProcess (lit S5) (lit S7)

/-- H3, claim 2: Synaptic adhesion defect: rare NXPH3 variants disrupt neurexin stabilization at synapses. -/
def h3c2a1 := lit S11

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H2" "c2a1" h2c2a1,
    arm "H2" "c4a1" h2c4a1,
    arm "H3" "c2a1" h3c2a1]

#eval printRows "study-2026-09-vertex-schizophrenia-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_schizophrenia_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r1
