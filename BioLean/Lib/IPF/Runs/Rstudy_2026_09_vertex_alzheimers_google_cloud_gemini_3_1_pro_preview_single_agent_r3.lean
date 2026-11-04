import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-single_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-single_agent-r3`: google-cloud:gemini-3.1-pro-preview, Alzheimer disease, genes TREM2, RNPS1, INPP5D, APOE, MS4A4A, LPIN2, PLCG2, ABI3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_google_cloud_gemini_3_1_pro_preview_single_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def MS4A4A : Entity .protein := ⟨"UniProt:Q96JQ5", "MS4A4A"⟩
def TREM2 : Entity .protein := ⟨"UniProt:Q9NZC2", "TREM2"⟩
def ABI3 : Entity .protein := ⟨"UniProt:Q9P2A4", "ABI3"⟩
def PLCG2 : Entity .protein := ⟨"UniProt:P16885", "PLCG2"⟩
def INPP5D : Entity .protein := ⟨"UniProt:Q92835", "INPP5D"⟩
def APOE : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def microglia : Entity .cellType := ⟨"CL:0000129", "microglial cell"⟩
def phagocytosis : Entity .process := ⟨"GO:0006909", "phagocytosis"⟩
def neuroinflammation : Entity .process := ⟨"GO:0150076", "neuroinflammatory response"⟩
def myelination : Entity .process := ⟨"GO:0042552", "myelination"⟩
def alzheimers : Entity .disease := ⟨"MONDO:0004975", "Alzheimer disease"⟩
def microglialPhagocytosis : Entity .process := phagocytosis.inCtx { cellType := microglia }

/-- Run step H1.1: MS4A4A lowers TREM2. -/
def S1 : Statement where
  id := "S1"
  text := "MS4A4A lowers TREM2"
  claim := .effect MS4A4A .neg (.amount TREM2)
  evidence := [
    { pmid := 41435829, year := 2026, kind := .mechanistic, note := "By modulating MS4A4A using knockout, overexpression, and degrading antibodies in macrophages, microglia, non-human primates (NHPs), and a mouse model of amyloid pathology, we provide evidence that MS4A4A and MS4A6A are negative regulators o", taxon := some Taxa.mouse }
  ]

/-- Run step H1.2: TREM2 activates microglial phagocytosis. -/
def S2 : Statement where
  id := "S2"
  text := "TREM2 activates microglial phagocytosis"
  claim := .effect TREM2 .pos (.process microglialPhagocytosis)
  evidence := [
    { pmid := 41315858, year := 2026, kind := .review, note := "Microglial phagocytosis of Aβ via TREM2" }
  ]

/-- Run step H1.3: microglial phagocytosis slows Alzheimer disease. Sign: the run's relation is decreases_amount on a disease; read as lowering its progression (the mechanism says 'exacerbates the progression'). -/
def S3 : Statement where
  id := "S3"
  text := "microglial phagocytosis slows Alzheimer disease"
  claim := .effect microglialPhagocytosis .neg (.disease alzheimers .progression)
  evidence := [
    { pmid := 41315858, year := 2026, kind := .review, note := "Microglial phagocytosis of Aβ via TREM2, LRP1, CD33, TAM receptors and anti-Aβ antibodies appears to reduce AD pathology" },
    { pmid := 41315858, year := 2026, kind := .review, polarity := .refutes, note := "microglial phagocytosis of synapses and neurons seems detrimental in the later stages of AD" }
  ]

/-- Run step H2.1: ABI3 is associated with PLCG2 (no direction). -/
def S4 : Statement where
  id := "S4"
  text := "ABI3 is associated with PLCG2 (no direction)"
  claim := .assoc ABI3 none (.activity PLCG2)
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:ABI3-PLCG2", kind := .textMined, note := "STRING links ABI3 and PLCG2 with combined score 0.67 (experimental 0.00, database 0.00, text-mining 0.65)" }
  ]

/-- Run step H2.2: PLCG2 is associated with INPP5D (no direction). -/
def S5 : Statement where
  id := "S5"
  text := "PLCG2 is associated with INPP5D (no direction)"
  claim := .assoc PLCG2 none (.activity INPP5D)
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:INPP5D-PLCG2", kind := .textMined, note := "STRING links INPP5D and PLCG2 with combined score 0.82 (experimental 0.09, database 0.50, text-mining 0.54)" }
  ]

/-- Run step H2.3: INPP5D inhibits neuroinflammation. -/
def S6 : Statement where
  id := "S6"
  text := "INPP5D inhibits neuroinflammation"
  claim := .effect INPP5D .neg (.process neuroinflammation)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .mechanistic, note := "Microglial INPP5D deficiency cell-autonomously promoted RIPK1-mediated transcriptional induction of diverse LOAD risk genes, proinflammatory cytokines, complements, and ROS mediators", taxon := some Taxa.mouse }
  ]

/-- Run step H2.4: neuroinflammation leads to Alzheimer disease. -/
def S7 : Statement where
  id := "S7"
  text := "neuroinflammation leads to Alzheimer disease"
  claim := .effect neuroinflammation .pos (.disease alzheimers)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .hypothesis, note := "RIPK1-mediated neuroinflammation for promoting aging-related neurodegenerative diseases, including LOAD" }
  ]

/-- Run step H3.1: APOE lowers myelination. Sign: the run's relation is decreases_amount on a process; read as a negative effect on it. -/
def S8 : Statement where
  id := "S8"
  text := "APOE lowers myelination"
  claim := .effect APOE .neg (.process myelination)
  evidence := []

/-- Run step H3.2: myelination slows Alzheimer disease. Sign: the run's relation is inhibits on a disease; the mechanism says loss of myelin 'leads to cognitive decline and exacerbates Alzheimer's disease' (progression: 'decline', 'exacerbation'). -/
def S9 : Statement where
  id := "S9"
  text := "myelination slows Alzheimer disease"
  claim := .effect myelination .neg (.disease alzheimers .progression)
  evidence := []

/-- Run step H3.3: APOE is associated with Alzheimer disease (no direction). -/
def S10 : Statement where
  id := "S10"
  text := "APOE is associated with Alzheimer disease (no direction)"
  claim := .assoc APOE none (.disease alzheimers)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs429358", kind := .observational, note := "rs429358-? is associated with 'Alzheimer's disease (age of onset)' at p = 4e-497, odds ratio 3.32 (mapped gene APOE" },
    { pmid := 0, year := 2026, ref := "OT:APOE-MONDO_0004975", kind := .observational, note := "Open Targets 2026.06 scores the APOE-Alzheimer disease association at 0.68 (literature 1.00, affected_pathway 0.27, rna_expression 0.02, genetic_association 0.86)" },
    { pmid := 36385529, year := 2022, kind := .review, note := "APOE4 is the strongest genetic risk factor for Alzheimer's disease" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10]

/-- H1, claim 1: MS4A4A negatively regulates TREM2-dependent microglial phagocytosis. -/
def h1c1a1 := viaAmount (lit S1) (viaProcess (lit S2) (lit S3))

/-- H1, claim 2: MS4A4A negatively regulates TREM2-dependent microglial phagocytosis. -/
def h1c2a1 := viaProcess (lit S2) (lit S3)

/-- H2, claim 3: PLCG2, ABI3, and INPP5D interact to limit microglial neuroinflammation. -/
def h2c3a1 := viaProcess (lit S6) (lit S7)

/-- H3, claim 1: APOE impairs oligodendrocyte myelination via cholesterol dysregulation. -/
def h3c1a1 := viaProcess (lit S8) (lit S9)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H1" "c2a1" h1c2a1,
    arm "H2" "c3a1" h2c3a1,
    arm "H3" "c1a1" h3c1a1]

#eval printRows "study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-single_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_google_cloud_gemini_3_1_pro_preview_single_agent_r3
