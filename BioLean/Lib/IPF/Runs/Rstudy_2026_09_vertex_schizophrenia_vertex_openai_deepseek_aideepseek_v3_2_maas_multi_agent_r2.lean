import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-schizophrenia-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-schizophrenia-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, schizophrenia, genes CSMD1, NXPH3, C4A, CX3CR1, CCDC136, C1QA, C4B. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_schizophrenia_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def CSMD1 : Entity .protein := ⟨"UniProt:Q96PZ7", "CSMD1"⟩
def C4A : Entity .protein := ⟨"UniProt:P0C0L4", "C4A"⟩
def C4B : Entity .protein := ⟨"UniProt:P0C0L5", "C4B"⟩
def C1QA : Entity .protein := ⟨"UniProt:P02745", "C1QA"⟩
def CX3CR1 : Entity .protein := ⟨"UniProt:P49238", "CX3CR1"⟩
def NXPH3 : Entity .protein := ⟨"UniProt:O95157", "NXPH3"⟩
def CCDC136 : Entity .protein := ⟨"UniProt:Q96JN2", "CCDC136"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def schizophrenia : Entity .disease := ⟨"MONDO:0005090", "schizophrenia"⟩
def microglia : Entity .cellType := ⟨"CL:0000129", "microglial cell"⟩
def synapsePruning : Entity .process := ⟨"GO:0098883", "synapse pruning"⟩
def synapseAssembly : Entity .process := ⟨"GO:0007416", "synapse assembly"⟩
def synapseMaintenance : Entity .process := ⟨"GO:0099558", "maintenance of synapse structure"⟩
def abnormalNeuronMorphology : Entity .phenotype := ⟨"HP:0012757", "Abnormal neuron morphology"⟩
def microglialSynapsePruning : Entity .process := synapsePruning.inCtx { cellType := microglia }

/-- Run step complement_synaptic_pruning.2: C4A raises complement activation (run: increases_amount of 'complement cascade overactivation'). -/
def S1 : Statement where
  id := "S1"
  text := "C4A raises complement activation (run: increases_amount of 'complement cascade overactivation')"
  claim := .effect C4A .pos (.process complementActivation)
  evidence := []

/-- Run step complement_synaptic_pruning.3: C4B raises complement activation (run: increases_amount of 'complement cascade overactivation'). -/
def S2 : Statement where
  id := "S2"
  text := "C4B raises complement activation (run: increases_amount of 'complement cascade overactivation')"
  claim := .effect C4B .pos (.process complementActivation)
  evidence := []

/-- Run step complement_synaptic_pruning.4: C1QA activates complement activation (run: activates 'complement cascade overactivation'). -/
def S3 : Statement where
  id := "S3"
  text := "C1QA activates complement activation (run: activates 'complement cascade overactivation')"
  claim := .effect C1QA .pos (.process complementActivation)
  evidence := []

/-- Run step synaptic_structural_deficit.1: NXPH3 is required for synapse assembly (required_for: losing NXPH3 lowers it); first part of 'synapse formation and maintenance'. -/
def S4 : Statement where
  id := "S4"
  text := "NXPH3 is required for synapse assembly (required_for: losing NXPH3 lowers it); first part of 'synapse formation and maintenance'"
  claim := .effect NXPH3 .pos (.process synapseAssembly)
  evidence := []

/-- Run step synaptic_structural_deficit.1: NXPH3 is required for maintenance of synapse structure (required_for: losing NXPH3 lowers it); second part of 'synapse formation and maintenance'. -/
def S5 : Statement where
  id := "S5"
  text := "NXPH3 is required for maintenance of synapse structure (required_for: losing NXPH3 lowers it); second part of 'synapse formation and maintenance'"
  claim := .effect NXPH3 .pos (.process synapseMaintenance)
  evidence := []

/-- Run step synaptic_structural_deficit.2: CCDC136 is required for neuronal structure (required_for: losing CCDC136 gives abnormal neuron morphology). Sign: the run's required_for (+) on 'neuronal structure': a structure has no amount, so it is written as CCDC136 lowering the HP 'Abnormal neuron morphology' phenotype ('A structural anomaly of a neuron'); same claim, not a sign change. -/
def S6 : Statement where
  id := "S6"
  text := "CCDC136 is required for neuronal structure (required_for: losing CCDC136 gives abnormal neuron morphology)"
  claim := .effect CCDC136 .neg (.phenotype abnormalNeuronMorphology)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-schizophrenia-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_schizophrenia_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r2
