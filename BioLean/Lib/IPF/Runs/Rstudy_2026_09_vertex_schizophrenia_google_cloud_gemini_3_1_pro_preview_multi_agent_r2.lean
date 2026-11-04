import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-schizophrenia-google-cloud-gemini-3.1-pro-preview-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-schizophrenia-google-cloud-gemini-3.1-pro-preview-multi_agent-r2`: google-cloud:gemini-3.1-pro-preview, schizophrenia, genes CSMD1, NXPH3, C4A, CX3CR1, CCDC136, C1QA, C4B. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_schizophrenia_google_cloud_gemini_3_1_pro_preview_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def C1QA : Entity .protein := ⟨"UniProt:P02745", "C1QA"⟩
def C4A : Entity .protein := ⟨"UniProt:P0C0L4", "C4A"⟩
def C4B : Entity .protein := ⟨"UniProt:P0C0L5", "C4B"⟩
def CSMD1 : Entity .protein := ⟨"UniProt:Q96PZ7", "CSMD1"⟩
def CX3CR1 : Entity .protein := ⟨"UniProt:P49238", "CX3CR1"⟩
def classicalComplement : Entity .process := ⟨"GO:0006958", "complement activation, classical pathway"⟩
def microglialActivation : Entity .process := ⟨"GO:0001774", "microglial cell activation"⟩
def synapsePruning : Entity .process := ⟨"GO:0098883", "synapse pruning"⟩
def schizophrenia : Entity .disease := ⟨"MONDO:0005090", "schizophrenia"⟩

/-- Run step h1_c4a_c1qa_pruning.1: C1QA activates C4A. -/
def S1 : Statement where
  id := "S1"
  text := "C1QA activates C4A"
  claim := .effect C1QA .pos (.activity C4A)
  evidence := []

/-- Run step h1_c4a_c1qa_pruning.2: C4A leads to synapse pruning. -/
def S2 : Statement where
  id := "S2"
  text := "C4A leads to synapse pruning"
  claim := .effect C4A .pos (.process synapsePruning)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .mechanistic, note := "In mice, C4 mediated synapse elimination during postnatal development", taxon := some Taxa.mouse }
  ]

/-- Run step h1_c4a_c1qa_pruning.3, h2_csmd1_inhibition.3, h3_cx3cr1_dysregulation.3: synapse pruning is associated with schizophrenia (no direction). Sign: the run gives polarity unknown in all three hypotheses; the one text that states the step says 'aberrant', which has no direction, so the association is unsigned. -/
def S3 : Statement where
  id := "S3"
  text := "synapse pruning is associated with schizophrenia (no direction)"
  claim := .assoc synapsePruning none (.disease schizophrenia)
  evidence := [
    { pmid := 42276261, year := 2026, kind := .review, note := "Schizophrenia pathogenesis may involve aberrant synaptic pruning" }
  ]

/-- Run step h2_csmd1_inhibition.1: CSMD1 inhibits classical complement activation. -/
def S4 : Statement where
  id := "S4"
  text := "CSMD1 inhibits classical complement activation"
  claim := .effect CSMD1 .neg (.process classicalComplement)
  evidence := [
    { pmid := 40112933, year := 2025, kind := .inVitro, note := "CSMD1 encodes a complement classical pathway inhibitor" }
  ]

/-- Run step h2_csmd1_inhibition.2: classical complement activation leads to synapse pruning. -/
def S5 : Statement where
  id := "S5"
  text := "classical complement activation leads to synapse pruning"
  claim := .effect classicalComplement .pos (.process synapsePruning)
  evidence := []

/-- Run step h3_cx3cr1_dysregulation.1: CX3CR1 inhibits microglial cell activation. -/
def S6 : Statement where
  id := "S6"
  text := "CX3CR1 inhibits microglial cell activation"
  claim := .effect CX3CR1 .neg (.process microglialActivation)
  evidence := []

/-- Run step h3_cx3cr1_dysregulation.2: microglial cell activation leads to synapse pruning. -/
def S7 : Statement where
  id := "S7"
  text := "microglial cell activation leads to synapse pruning"
  claim := .effect microglialActivation .pos (.process synapsePruning)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7]

/-- h1_c4a_c1qa_pruning, claim 4: C1QA and C4A/B drive excessive microglial synaptic pruning in schizophrenia. -/
def h1c4a1 := viaActivity (lit S1) (lit S2)

/-- h1_c4a_c1qa_pruning, claim 5: C1QA and C4A/B drive excessive microglial synaptic pruning in schizophrenia. -/
def h1c5a1 := lit S2

/-- h2_csmd1_inhibition, claim 2: Loss of CSMD1 complement inhibition promotes synaptic over-pruning. -/
def h2c2a1 := viaProcess (lit S4) (lit S5)

/-- h3_cx3cr1_dysregulation, claim 2: Disruption of CX3CR1 signaling disinhibits microglial pruning. -/
def h3c2a1 := viaProcess (lit S6) (lit S7)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "h1_c4a_c1qa_pruning" "c4a1" h1c4a1,
    arm "h1_c4a_c1qa_pruning" "c5a1" h1c5a1,
    arm "h2_csmd1_inhibition" "c2a1" h2c2a1,
    arm "h3_cx3cr1_dysregulation" "c2a1" h3c2a1]

#eval printRows "study-2026-09-vertex-schizophrenia-google-cloud-gemini-3.1-pro-preview-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_schizophrenia_google_cloud_gemini_3_1_pro_preview_multi_agent_r2
