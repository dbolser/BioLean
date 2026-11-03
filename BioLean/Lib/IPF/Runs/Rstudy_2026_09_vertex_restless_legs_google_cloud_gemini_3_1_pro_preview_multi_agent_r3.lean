import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-multi_agent-r3`: google-cloud:gemini-3.1-pro-preview, restless legs syndrome, genes ACO1, MEIS1, GLIPR1, PTPRD, GABARAPL2, BTBD9. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_google_cloud_gemini_3_1_pro_preview_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def meis1RiskAlleles : Entity .variant := ⟨"BLN:MEIS1-RLSRiskAlleles", "RLS risk alleles at the MEIS1 locus"⟩
def btbd9RiskAlleles : Entity .variant := ⟨"BLN:BTBD9-RLSRiskAlleles", "RLS risk alleles at the BTBD9 locus"⟩
def ptprdRiskAlleles : Entity .variant := ⟨"BLN:PTPRD-RLSRiskAlleles", "RLS risk alleles at the PTPRD locus"⟩
def MEIS1 : Entity .protein := ⟨"UniProt:O00470", "MEIS1"⟩
def BTBD9 : Entity .protein := ⟨"UniProt:Q96Q07", "BTBD9"⟩
def ACO1 : Entity .protein := ⟨"UniProt:P21399", "ACO1"⟩
def PTPRD : Entity .protein := ⟨"UniProt:P23468", "PTPRD"⟩
def cerebellarOutput : Entity .process := ⟨"BLN:CerebellarOutput", "cerebellar output (activity leaving the cerebellum)"⟩
def ironHomeostasis : Entity .process := ⟨"GO:0006879", "intracellular iron ion homeostasis"⟩
def synapseAssembly : Entity .process := ⟨"GO:0007416", "synapse assembly"⟩
def rls : Entity .disease := ⟨"MONDO:0005391", "restless legs syndrome"⟩

/-- Run step MEIS1_cerebellar_disinhibition.1: RLS risk alleles at the MEIS1 locus lower MEIS1. -/
def S1 : Statement where
  id := "S1"
  text := "RLS risk alleles at the MEIS1 locus lower MEIS1"
  claim := .effect meis1RiskAlleles .neg (.amount MEIS1)
  evidence := []

/-- Run step MEIS1_cerebellar_disinhibition.2: MEIS1 inhibits cerebellar output (the run's context, cerebellum, is carried by the object). -/
def S2 : Statement where
  id := "S2"
  text := "MEIS1 inhibits cerebellar output (the run's context, cerebellum, is carried by the object)"
  claim := .effect MEIS1 .neg (.process cerebellarOutput)
  evidence := [
    { pmid := 42309051, year := 2026, kind := .mechanistic, note := "Disinhibition of cerebellar output by loss of restless legs syndrome-associated gene MEIS1", taxon := some Taxa.zebrafish }
  ]

/-- Run step MEIS1_cerebellar_disinhibition.3: cerebellar output raises the risk of RLS. -/
def S3 : Statement where
  id := "S3"
  text := "cerebellar output raises the risk of RLS"
  claim := .effect cerebellarOutput .pos (.disease rls)
  evidence := []

/-- Run step BTBD9_ACO1_iron_homeostasis.1: RLS risk alleles at the BTBD9 locus lower BTBD9. -/
def S4 : Statement where
  id := "S4"
  text := "RLS risk alleles at the BTBD9 locus lower BTBD9"
  claim := .effect btbd9RiskAlleles .neg (.amount BTBD9)
  evidence := []

/-- Run step BTBD9_ACO1_iron_homeostasis.2: BTBD9 binds ACO1. -/
def S5 : Statement where
  id := "S5"
  text := "BTBD9 binds ACO1"
  claim := .rel ⟨.ro, 2436, false⟩ BTBD9 ACO1
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:ACO1-BTBD9", kind := .curatedDb, note := "STRING links ACO1 and BTBD9 with combined score 0.45 (experimental 0.41, database 0.00, text-mining 0.09)" }
  ]

/-- Run step BTBD9_ACO1_iron_homeostasis.3: ACO1 is required for cellular iron homeostasis. -/
def S6 : Statement where
  id := "S6"
  text := "ACO1 is required for cellular iron homeostasis"
  claim := .effect ACO1 .pos (.process ironHomeostasis)
  evidence := [
    { pmid := 0, year := 2026, ref := "P21399", kind := .curatedDb, note := "Iron deprivation, promotes its mRNA binding activity through which it regulates the expression of genes involved in iron uptake, sequestration and utilization" }
  ]

/-- Run step BTBD9_ACO1_iron_homeostasis.4: cellular iron homeostasis raises the risk of RLS. Sign: the run's sign: subject 'cellular iron homeostasis', polarity positive; the step's context names 'iron deficiency' as a disease state, and the mechanism says iron deficiency drives RLS, but the step's own subject and polarity say the opposi. -/
def S7 : Statement where
  id := "S7"
  text := "cellular iron homeostasis raises the risk of RLS"
  claim := .effect ironHomeostasis .pos (.disease rls)
  evidence := []

/-- Run step PTPRD_synaptic_differentiation.1: RLS risk alleles at the PTPRD locus lower PTPRD. -/
def S8 : Statement where
  id := "S8"
  text := "RLS risk alleles at the PTPRD locus lower PTPRD"
  claim := .effect ptprdRiskAlleles .neg (.amount PTPRD)
  evidence := []

/-- Run step PTPRD_synaptic_differentiation.2: PTPRD activates synapse assembly (pre- and post-synaptic differentiation). -/
def S9 : Statement where
  id := "S9"
  text := "PTPRD activates synapse assembly (pre- and post-synaptic differentiation)"
  claim := .effect PTPRD .pos (.process synapseAssembly)
  evidence := [
    { pmid := 0, year := 2026, ref := "P23468", kind := .crossSpecies, note := "Can bidirectionally induce pre- and post-synaptic differentiation of neurons" }
  ]

/-- Run step PTPRD_synaptic_differentiation.3: synapse assembly raises the risk of RLS. Sign: the run's sign: polarity positive, although its note says 'Altered synaptic differentiation', which has no direction, and the title says the risk variants impair it. -/
def S10 : Statement where
  id := "S10"
  text := "synapse assembly raises the risk of RLS"
  claim := .effect synapseAssembly .pos (.disease rls)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10]

/-- MEIS1_cerebellar_disinhibition, claim 1: MEIS1 loss-of-function disinhibits cerebellar output, disrupting circadian sleep/wake cycles.. -/
def h1c1a1 := viaAmount (lit S1) (viaProcess (lit S2) (lit S3))

/-- BTBD9_ACO1_iron_homeostasis, claim 2: BTBD9 disrupts ACO1-mediated neuronal iron homeostasis, leading to restless legs syndrome.. -/
def h2c2a1 := viaProcess (lit S6) (lit S7)

/-- PTPRD_synaptic_differentiation, claim 1: PTPRD genetic variants impair trans-synaptic neuronal differentiation, disrupting motor circuits.. -/
def h3c1a1 := viaAmount (lit S8) (viaProcess (lit S9) (lit S10))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "MEIS1_cerebellar_disinhibition" "c1a1" h1c1a1,
    arm "BTBD9_ACO1_iron_homeostasis" "c2a1" h2c2a1,
    arm "PTPRD_synaptic_differentiation" "c1a1" h3c1a1]

#eval printRows "study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_google_cloud_gemini_3_1_pro_preview_multi_agent_r3
