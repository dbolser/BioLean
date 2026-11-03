import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-alzheimers-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-alzheimers-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, Alzheimer disease, genes TREM2, RNPS1, INPP5D, APOE, MS4A4A, LPIN2, PLCG2, ABI3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def TREM2 : Entity .protein := ⟨"UniProt:Q9NZC2", "TREM2"⟩
def INPP5D : Entity .protein := ⟨"UniProt:Q92835", "INPP5D"⟩
def PLCG2 : Entity .protein := ⟨"UniProt:P16885", "PLCG2"⟩
def ABI3 : Entity .protein := ⟨"UniProt:Q9P2A4", "ABI3"⟩
def APOE : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def MS4A4A : Entity .protein := ⟨"UniProt:Q96JQ5", "MS4A4A"⟩
def apoeE4 : Entity .variant := ⟨"BLN:APOE-epsilon4", "APOE epsilon4 allele"⟩
def alzheimerDisease : Entity .disease := ⟨"MONDO:0004975", "Alzheimer disease"⟩
def abClearance : Entity .process := ⟨"GO:0150094", "amyloid-beta clearance by cellular catabolic process"⟩
def microgliaActivation : Entity .process := ⟨"GO:0001774", "microglial cell activation"⟩
def calciumSignaling : Entity .process := ⟨"GO:0019722", "calcium-mediated signaling"⟩
def immuneActivation : Entity .process := ⟨"GO:0002253", "activation of immune response"⟩
def pi3kSignaling : Entity .process := ⟨"GO:0043491", "phosphatidylinositol 3-kinase/protein kinase B signal transduction"⟩
def brainCholesterolAbnormal : Entity .phenotype := ⟨"UPHENO:0051760", "brain cholesterol level phenotype"⟩
def plcg2InApoeE4Carriers : Entity .protein := PLCG2.inCtx { condition := some (.organism apoeE4) }

/-- Run step H1.1: TREM2 promotes microglial phagocytosis (clearance) of amyloid-beta. Sign: inverted: the run's subject is 'TREM2' with polarity negative, but its note says the step is about loss-of-function variants that impair phagocytosis. -/
def S1 : Statement where
  id := "S1"
  text := "TREM2 promotes microglial phagocytosis (clearance) of amyloid-beta"
  claim := .effect TREM2 .pos (.process abClearance)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9NZC2", kind := .curatedDb, note := "Acts as a receptor for amyloid-beta protein 42, a cleavage product of the amyloid-beta precursor protein APP, and mediates its uptake and degradation by microglia" },
    { pmid := 41315858, year := 2026, kind := .review, note := "Microglial phagocytosis of Aβ via TREM2" }
  ]

/-- Run step H1.2: INPP5D restrains pro-inflammatory microglial activation. Sign: inverted: the run's subject is 'INPP5D' with polarity positive, but its note says 'loss of function increases inflammation'. -/
def S2 : Statement where
  id := "S2"
  text := "INPP5D restrains pro-inflammatory microglial activation"
  claim := .effect INPP5D .neg (.process microgliaActivation)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .mechanistic, note := "Microglial INPP5D deficiency cell-autonomously promoted RIPK1-mediated transcriptional induction of diverse LOAD risk genes, proinflammatory cytokines", taxon := some Taxa.mouse }
  ]

/-- Run step H1.3: PLCG2 increases calcium signaling (first part of 'calcium signaling and immune activation'). -/
def S3 : Statement where
  id := "S3"
  text := "PLCG2 increases calcium signaling (first part of 'calcium signaling and immune activation')"
  claim := .effect PLCG2 .pos (.process calciumSignaling)
  evidence := []

/-- Run step H1.3: PLCG2 increases immune activation (second part of 'calcium signaling and immune activation'). -/
def S4 : Statement where
  id := "S4"
  text := "PLCG2 increases immune activation (second part of 'calcium signaling and immune activation')"
  claim := .effect PLCG2 .pos (.process immuneActivation)
  evidence := []

/-- Run step H1.4: ABI3 raises the risk of Alzheimer disease. -/
def S5 : Statement where
  id := "S5"
  text := "ABI3 raises the risk of Alzheimer disease"
  claim := .effect ABI3 .pos (.disease alzheimerDisease)
  evidence := []

/-- Run step H2.1: the APOE epsilon4 allele leads to abnormal brain cholesterol (the run's 'cholesterol dysregulation in brain'). Sign: undirected change: 'dysregulation' is expressed as pos on the abnormal-phenotype term. -/
def S6 : Statement where
  id := "S6"
  text := "the APOE epsilon4 allele leads to abnormal brain cholesterol (the run's 'cholesterol dysregulation in brain')"
  claim := .effect apoeE4 .pos (.phenotype brainCholesterolAbnormal)
  evidence := []

/-- Run step H2.2: APOE lowers TREM2 signaling. -/
def S7 : Statement where
  id := "S7"
  text := "APOE lowers TREM2 signaling"
  claim := .effect APOE .neg (.activity TREM2)
  evidence := []

/-- Run step H2.3: PLCG2 lowers the risk of Alzheimer disease in APOE epsilon4 carriers (protective variants delay onset). -/
def S8 : Statement where
  id := "S8"
  text := "PLCG2 lowers the risk of Alzheimer disease in APOE epsilon4 carriers (protective variants delay onset)"
  claim := .effect plcg2InApoeE4Carriers .neg (.disease alzheimerDisease)
  evidence := []

/-- Run step H3.1: MS4A4A lowers TREM2 signaling. -/
def S9 : Statement where
  id := "S9"
  text := "MS4A4A lowers TREM2 signaling"
  claim := .effect MS4A4A .neg (.activity TREM2)
  evidence := [
    { pmid := 41435829, year := 2026, kind := .mechanistic, note := "By modulating MS4A4A using knockout, overexpression, and degrading antibodies in macrophages, microglia, non-human primates (NHPs), and a mouse model of amyloid pathology, we provide evidence that MS4A4A and MS4A6A are negative regulators o", taxon := some Taxa.mouse }
  ]

/-- Run step H3.3: INPP5D increases PI3K signaling (the run: INPP5D reduces 'PI3K pathway suppression'). Sign: inverted: the run's object is 'PI3K pathway suppression' with polarity negative, i.e. INPP5D lowers the suppression of PI3K signaling. -/
def S10 : Statement where
  id := "S10"
  text := "INPP5D increases PI3K signaling (the run: INPP5D reduces 'PI3K pathway suppression')"
  claim := .effect INPP5D .pos (.process pi3kSignaling)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q92835", kind := .curatedDb, polarity := .refutes, note := "thereby negatively regulating the PI3K (phosphoinositide 3-kinase) pathways" }
  ]

/-- Bridge, not in the run: microglial phagocytosis of amyloid-beta reduces Alzheimer disease pathology. -/
def B1 : Statement where
  id := "B1"
  text := "microglial phagocytosis of amyloid-beta reduces Alzheimer disease pathology"
  claim := .effect abClearance .neg (.disease alzheimerDisease .severity)
  evidence := [
    { pmid := 41315858, year := 2026, kind := .review, note := "Microglial phagocytosis of Aβ via TREM2, LRP1, CD33, TAM receptors and anti-Aβ antibodies appears to reduce AD pathology" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, B1]

/-- H1, claim 1: Microglial innate immune signaling disruption by rare variants. -/
def h1c1a1 := viaProcess (lit S1) (lit B1)

/-- H1, claim 4: Microglial innate immune signaling disruption by rare variants. -/
def h1c4a1 := lit S5

/-- H2, claim 2: APOE ε4 lipid dysregulation with TREM2/PLCG2 modulation. -/
def h2c2a1 := lit S8

/-- H3, claim 1: MS4A4A-TREM2 inhibitory axis in microglial regulation. -/
def h3c1a1 := lit S9

/-- H3, claim 2: MS4A4A-TREM2 inhibitory axis in microglial regulation. -/
def h3c2a1 := lit S10

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H1" "c4a1" h1c4a1,
    arm "H2" "c2a1" h2c2a1,
    arm "H3" "c1a1" h3c1a1,
    arm "H3" "c2a1" h3c2a1]

#eval printRows "study-2026-09-vertex-alzheimers-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r1
