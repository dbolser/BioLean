import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-schizophrenia-google-cloud-gemini-3.1-pro-preview-single_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-schizophrenia-google-cloud-gemini-3.1-pro-preview-single_agent-r3`: google-cloud:gemini-3.1-pro-preview, schizophrenia, genes CSMD1, NXPH3, C4A, CX3CR1, CCDC136, C1QA, C4B. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_schizophrenia_google_cloud_gemini_3_1_pro_preview_single_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def CSMD1 : Entity .protein := ⟨"UniProt:Q96PZ7", "CSMD1"⟩
def C4A : Entity .protein := ⟨"UniProt:P0C0L4", "C4A"⟩
def C4B : Entity .protein := ⟨"UniProt:P0C0L5", "C4B"⟩
def C1QA : Entity .protein := ⟨"UniProt:P02745", "C1QA"⟩
def CX3CR1 : Entity .protein := ⟨"UniProt:P49238", "CX3CR1"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def synapsePruning : Entity .process := ⟨"GO:0098883", "synapse pruning"⟩
def microglialActivation : Entity .process := ⟨"GO:0001774", "microglial cell activation"⟩
def schizophrenia : Entity .disease := ⟨"MONDO:0005090", "schizophrenia"⟩

/-- Run step hyp-1.1: CSMD1 inhibits complement activation. -/
def S1 : Statement where
  id := "S1"
  text := "CSMD1 inhibits complement activation"
  claim := .effect CSMD1 .neg (.process complementActivation)
  evidence := [
    { pmid := 40112933, year := 2025, kind := .inVitro, note := "CSMD1 encodes a complement classical pathway inhibitor" }
  ]

/-- Run step hyp-1.2, hyp-2.2: C4A activates complement activation. -/
def S2 : Statement where
  id := "S2"
  text := "C4A activates complement activation"
  claim := .effect C4A .pos (.process complementActivation)
  evidence := [
    { pmid := 0, year := 2026, ref := "P0C0L4", kind := .curatedDb, note := "It then recruits the serine protease complement C2b to form the C3 and C5 convertases, which cleave and activate C3 and C5, respectively, the next components of the complement pathways" }
  ]

/-- Run step hyp-1.3: C4B activates complement activation. -/
def S3 : Statement where
  id := "S3"
  text := "C4B activates complement activation"
  claim := .effect C4B .pos (.process complementActivation)
  evidence := []

/-- Run step hyp-1.4, hyp-2.3: complement activation drives synapse pruning. -/
def S4 : Statement where
  id := "S4"
  text := "complement activation drives synapse pruning"
  claim := .effect complementActivation .pos (.process synapsePruning)
  evidence := [
    { pmid := 22632727, year := 2012, kind := .mechanistic, note := "We show that microglia engulf presynaptic inputs during peak retinogeniculate pruning and that engulfment is dependent upon neural activity and the microglia-specific phagocytic signaling pathway, complement receptor 3(CR3)/C3", taxon := some Taxa.mouse },
    { pmid := 42276261, year := 2026, kind := .review, note := "aberrant synaptic pruning mediated by excessive complement system activity" }
  ]

/-- Run step hyp-1.5, hyp-2.6: synapse pruning leads to schizophrenia. -/
def S5 : Statement where
  id := "S5"
  text := "synapse pruning leads to schizophrenia"
  claim := .effect synapsePruning .pos (.disease schizophrenia)
  evidence := []

/-- Run step hyp-2.1: C1QA activates complement activation (classical pathway). -/
def S6 : Statement where
  id := "S6"
  text := "C1QA activates complement activation (classical pathway)"
  claim := .effect C1QA .pos (.process complementActivation)
  evidence := [
    { pmid := 0, year := 2026, ref := "P02745", kind := .curatedDb, note := "Core component of the complement C1 complex, a multiprotein complex that initiates the classical pathway of the complement system" }
  ]

/-- Run step hyp-2.4: CX3CR1 activates microglia. -/
def S7 : Statement where
  id := "S7"
  text := "CX3CR1 activates microglia"
  claim := .effect CX3CR1 .pos (.process microglialActivation)
  evidence := [
    { pmid := 0, year := 2026, ref := "P49238", kind := .crossSpecies, polarity := .refutes, note := "Required to restrain the microglial inflammatory response in the CNS" }
  ]

/-- Run step hyp-2.5: microglia (microglial activation) drive synapse pruning. -/
def S8 : Statement where
  id := "S8"
  text := "microglia (microglial activation) drive synapse pruning"
  claim := .effect microglialActivation .pos (.process synapsePruning)
  evidence := [
    { pmid := 0, year := 2026, ref := "P49238", kind := .crossSpecies, note := "synaptic pruning, a natural process during which brain microglia eliminates extra synapses" },
    { pmid := 22632727, year := 2012, kind := .mechanistic, note := "we demonstrate a role for microglia in activity-dependent synaptic pruning", taxon := some Taxa.mouse }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8]

/-- hyp-1, claim 1: CSMD1 loss relieves inhibition on C4A/C4B-mediated complement activation, leading to excessive synaptic pruning in schizophrenia. -/
def h1c1a1 := viaProcess (lit S1) (viaProcess (lit S4) (lit S5))

/-- hyp-1, claim 2: CSMD1 loss relieves inhibition on C4A/C4B-mediated complement activation, leading to excessive synaptic pruning in schizophrenia. -/
def h1c2a1 := viaProcess (lit S2) (viaProcess (lit S4) (lit S5))

/-- hyp-1, claim 3: CSMD1 loss relieves inhibition on C4A/C4B-mediated complement activation, leading to excessive synaptic pruning in schizophrenia. -/
def h1c3a1 := viaProcess (lit S3) (viaProcess (lit S4) (lit S5))

/-- hyp-2, claim 1: C1QA and C4A initiate complement-dependent synaptic pruning by CX3CR1-expressing microglia. -/
def h2c1a1 := viaProcess (lit S6) (viaProcess (lit S4) (lit S5))

/-- hyp-2, claim 2: C1QA and C4A initiate complement-dependent synaptic pruning by CX3CR1-expressing microglia. -/
def h2c2a1 := viaProcess (lit S2) (viaProcess (lit S4) (lit S5))

/-- hyp-2, claim 3: C1QA and C4A initiate complement-dependent synaptic pruning by CX3CR1-expressing microglia. -/
def h2c3a1 := viaProcess (lit S7) (viaProcess (lit S8) (lit S5))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp-1" "c1a1" h1c1a1,
    arm "hyp-1" "c2a1" h1c2a1,
    arm "hyp-1" "c3a1" h1c3a1,
    arm "hyp-2" "c1a1" h2c1a1,
    arm "hyp-2" "c2a1" h2c2a1,
    arm "hyp-2" "c3a1" h2c3a1]

#eval printRows "study-2026-09-vertex-schizophrenia-google-cloud-gemini-3.1-pro-preview-single_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_schizophrenia_google_cloud_gemini_3_1_pro_preview_single_agent_r3
