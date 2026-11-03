import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-schizophrenia-google-cloud-gemini-3.1-pro-preview-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-schizophrenia-google-cloud-gemini-3.1-pro-preview-multi_agent-r3`: google-cloud:gemini-3.1-pro-preview, schizophrenia, genes CSMD1, NXPH3, C4A, CX3CR1, CCDC136, C1QA, C4B. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_schizophrenia_google_cloud_gemini_3_1_pro_preview_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def CSMD1 : Entity .protein := ⟨"UniProt:Q96PZ7", "CSMD1"⟩
def C4A : Entity .protein := ⟨"UniProt:P0C0L4", "C4A"⟩
def C4B : Entity .protein := ⟨"UniProt:P0C0L5", "C4B"⟩
def C1QA : Entity .protein := ⟨"UniProt:P02745", "C1QA"⟩
def CX3CR1 : Entity .protein := ⟨"UniProt:P49238", "CX3CR1"⟩
def synapsePruning : Entity .process := ⟨"GO:0098883", "synapse pruning"⟩
def microgliaActivation : Entity .process := ⟨"GO:0001774", "microglial cell activation"⟩
def schizophrenia : Entity .disease := ⟨"MONDO:0005090", "schizophrenia"⟩

/-- Run step hyp-1.1: CSMD1 inhibits C4A. -/
def S1 : Statement where
  id := "S1"
  text := "CSMD1 inhibits C4A"
  claim := .effect CSMD1 .neg (.activity C4A)
  evidence := []

/-- Run step hyp-1.2: C4A drives synapse pruning. -/
def S2 : Statement where
  id := "S2"
  text := "C4A drives synapse pruning"
  claim := .effect C4A .pos (.process synapsePruning)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .mechanistic, note := "In mice, C4 mediated synapse elimination during postnatal development", taxon := some Taxa.mouse }
  ]

/-- Run step hyp-1.3: C4B drives synapse pruning. -/
def S3 : Statement where
  id := "S3"
  text := "C4B drives synapse pruning"
  claim := .effect C4B .pos (.process synapsePruning)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .mechanistic, note := "In mice, C4 mediated synapse elimination during postnatal development", taxon := some Taxa.mouse },
    { pmid := 42000733, year := 2026, kind := .review, polarity := .refutes, note := "C4A, in contrast to C4B, is implicated in synaptic pruning" }
  ]

/-- Run step hyp-2.1: C1QA drives microglial cell activation. -/
def S4 : Statement where
  id := "S4"
  text := "C1QA drives microglial cell activation"
  claim := .effect C1QA .pos (.process microgliaActivation)
  evidence := []

/-- Run step hyp-2.2: CX3CR1 inhibits microglial cell activation. -/
def S5 : Statement where
  id := "S5"
  text := "CX3CR1 inhibits microglial cell activation"
  claim := .effect CX3CR1 .neg (.process microgliaActivation)
  evidence := []

/-- Run step hyp-2.3: microglial cell activation drives synapse pruning. -/
def S6 : Statement where
  id := "S6"
  text := "microglial cell activation drives synapse pruning"
  claim := .effect microgliaActivation .pos (.process synapsePruning)
  evidence := []

/-- Bridge, not in the run: higher C4A expression goes with schizophrenia risk (stated by both papers the run cited for hyp-1.2 and hyp-1.3; the mechanism asserts it, but no step makes it). -/
def B1 : Statement where
  id := "B1"
  text := "higher C4A expression goes with schizophrenia risk (stated by both papers the run cited for hyp-1.2 and hyp-1.3; the mechanism asserts it, but no step makes it)"
  claim := .assoc C4A (some .pos) (.disease schizophrenia)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .observational, note := "each common C4 allele associating with schizophrenia in proportion to its tendency to generate greater expression of C4A" },
    { pmid := 42000733, year := 2026, kind := .review, note := "C4A, in contrast to C4B, is implicated in synaptic pruning and increased risk for schizophrenia" }
  ]

/-- Bridge, not in the run: lower CX3CR1 expression goes with schizophrenia (stated by the paper the run cited for hyp-2.2 and hyp-2.3; no step makes it). -/
def B2 : Statement where
  id := "B2"
  text := "lower CX3CR1 expression goes with schizophrenia (stated by the paper the run cited for hyp-2.2 and hyp-2.3; no step makes it)"
  claim := .assoc CX3CR1 (some .neg) (.disease schizophrenia)
  evidence := [
    { pmid := 42276261, year := 2026, kind := .observational, note := "In SZ individuals, blood CX3CR1 underexpression" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, B1, B2]

/-- hyp-1, claim 1: Loss of CSMD1 inhibition exacerbates C4A/C4B-mediated synaptic pruning in schizophrenia. -/
def h1c1a1 := viaActivity (lit S1) (fromAssoc (lit B1))

/-- hyp-1, claim 2: Loss of CSMD1 inhibition exacerbates C4A/C4B-mediated synaptic pruning in schizophrenia. -/
def h1c2a1 := fromAssoc (lit B1)

/-- hyp-1, claim 4: Loss of CSMD1 inhibition exacerbates C4A/C4B-mediated synaptic pruning in schizophrenia. -/
def h1c4a1 := viaActivity (lit S1) (lit S2)

/-- hyp-1, claim 5: Loss of CSMD1 inhibition exacerbates C4A/C4B-mediated synaptic pruning in schizophrenia. -/
def h1c5a1 := lit S2

/-- hyp-1, claim 6: Loss of CSMD1 inhibition exacerbates C4A/C4B-mediated synaptic pruning in schizophrenia. -/
def h1c6a1 := lit S3

/-- hyp-2, claim 2: CX3CR1 dysregulation amplifies C1QA-initiated microglial activation and synaptic pruning in schizophrenia. -/
def h2c2a1 := fromAssoc (lit B2)

/-- hyp-2, claim 3: CX3CR1 dysregulation amplifies C1QA-initiated microglial activation and synaptic pruning in schizophrenia. -/
def h2c3a1 := viaProcess (lit S4) (lit S6)

/-- hyp-2, claim 4: CX3CR1 dysregulation amplifies C1QA-initiated microglial activation and synaptic pruning in schizophrenia. -/
def h2c4a1 := viaProcess (lit S5) (lit S6)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp-1" "c1a1" h1c1a1,
    arm "hyp-1" "c2a1" h1c2a1,
    arm "hyp-1" "c4a1" h1c4a1,
    arm "hyp-1" "c5a1" h1c5a1,
    arm "hyp-1" "c6a1" h1c6a1,
    arm "hyp-2" "c2a1" h2c2a1,
    arm "hyp-2" "c3a1" h2c3a1,
    arm "hyp-2" "c4a1" h2c4a1]

#eval printRows "study-2026-09-vertex-schizophrenia-google-cloud-gemini-3.1-pro-preview-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_schizophrenia_google_cloud_gemini_3_1_pro_preview_multi_agent_r3
