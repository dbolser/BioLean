import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-multi_agent-r3`: google-cloud:gemini-3.1-pro-preview, Alzheimer disease, genes TREM2, RNPS1, INPP5D, APOE, MS4A4A, LPIN2, PLCG2, ABI3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_google_cloud_gemini_3_1_pro_preview_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def MS4A4A : Entity .protein := ⟨"UniProt:Q96JQ5", "MS4A4A"⟩
def TREM2 : Entity .protein := ⟨"UniProt:Q9NZC2", "TREM2"⟩
def ABI3 : Entity .protein := ⟨"UniProt:Q9P2A4", "ABI3"⟩
def PLCG2 : Entity .protein := ⟨"UniProt:P16885", "PLCG2"⟩
def INPP5D : Entity .protein := ⟨"UniProt:Q92835", "INPP5D"⟩
def RIPK1 : Entity .protein := ⟨"UniProt:Q13546", "RIPK1"⟩
def apoe4 : Entity .variant := ⟨"BLN:APOE-e4", "APOE ε4 allele"⟩
def innateImmunity : Entity .process := ⟨"GO:0045087", "innate immune response"⟩
def abnormalCholesterolHomeostasis : Entity .phenotype := ⟨"MP:0005278", "abnormal cholesterol homeostasis"⟩
def myelination : Entity .process := ⟨"GO:0042552", "myelination"⟩
def neuroinflammation : Entity .process := ⟨"GO:0150076", "neuroinflammatory response"⟩
def alzheimers : Entity .disease := ⟨"MONDO:0004975", "Alzheimer disease"⟩

/-- Run step H1.1: MS4A4A lowers TREM2 protein. -/
def S1 : Statement where
  id := "S1"
  text := "MS4A4A lowers TREM2 protein"
  claim := .effect MS4A4A .neg (.amount TREM2)
  evidence := [
    { pmid := 41435829, year := 2026, kind := .mechanistic, note := "MS4A4A and MS4A6A are negative regulators of both the transmembrane and soluble TREM2 proteins", taxon := some Taxa.mouse }
  ]

/-- Run step H1.2: TREM2 activates the innate immune response. -/
def S2 : Statement where
  id := "S2"
  text := "TREM2 activates the innate immune response"
  claim := .effect TREM2 .pos (.process innateImmunity)
  evidence := []

/-- Run step H1.3: ABI3 activates the innate immune response. -/
def S3 : Statement where
  id := "S3"
  text := "ABI3 activates the innate immune response"
  claim := .effect ABI3 .pos (.process innateImmunity)
  evidence := []

/-- Run step H1.4: PLCG2 activates the innate immune response. -/
def S4 : Statement where
  id := "S4"
  text := "PLCG2 activates the innate immune response"
  claim := .effect PLCG2 .pos (.process innateImmunity)
  evidence := []

/-- Run step H1.5: the innate immune response lowers the risk of Alzheimer disease. -/
def S5 : Statement where
  id := "S5"
  text := "the innate immune response lowers the risk of Alzheimer disease"
  claim := .effect innateImmunity .neg (.disease alzheimers)
  evidence := [
    { pmid := 28714976, year := 2017, kind := .observational, polarity := .refutes, note := "the microglia-mediated innate immune response contributes directly to the development of Alzheimer's disease" }
  ]

/-- Run step H2.1: the APOE ε4 allele goes with abnormal cholesterol homeostasis. Sign: the run's polarity is 'unknown'; direction from the cited text, which says APOE4 alters cholesterol homeostasis (the target is the abnormal phenotype, so 'altered' is pos). -/
def S6 : Statement where
  id := "S6"
  text := "the APOE ε4 allele goes with abnormal cholesterol homeostasis"
  claim := .assoc apoe4 (some .pos) (.phenotype abnormalCholesterolHomeostasis)
  evidence := [
    { pmid := 36385529, year := 2022, kind := .observational, note := "APOE4 significantly altered signalling pathways associated with cholesterol homeostasis and transport" }
  ]

/-- Run step H2.2: abnormal cholesterol homeostasis lowers myelination. -/
def S7 : Statement where
  id := "S7"
  text := "abnormal cholesterol homeostasis lowers myelination"
  claim := .effect abnormalCholesterolHomeostasis .neg (.process myelination)
  evidence := [
    { pmid := 36385529, year := 2022, kind := .mechanistic, note := "Pharmacologically facilitating cholesterol transport increases axonal myelination and improves learning and memory in APOE4 mice", taxon := some Taxa.mouse }
  ]

/-- Run step H2.3: myelination lowers the risk of Alzheimer disease. -/
def S8 : Statement where
  id := "S8"
  text := "myelination lowers the risk of Alzheimer disease"
  claim := .effect myelination .neg (.disease alzheimers)
  evidence := []

/-- Run step H3.1: INPP5D inhibits RIPK1 kinase activity. -/
def S9 : Statement where
  id := "S9"
  text := "INPP5D inhibits RIPK1 kinase activity"
  claim := .effect INPP5D .neg (.activity RIPK1)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .inVitro, note := "the N-terminal SH2 domain of INPP5D, an important LOAD risk gene, directly interacted with the cell death regulator RIPK1 at p-Y383 to suppress RIPK1 kinase activation" }
  ]

/-- Run step H3.2: RIPK1 drives the neuroinflammatory response. -/
def S10 : Statement where
  id := "S10"
  text := "RIPK1 drives the neuroinflammatory response"
  claim := .effect RIPK1 .pos (.process neuroinflammation)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .mechanistic, note := "Microglial INPP5D deficiency cell-autonomously promoted RIPK1-mediated transcriptional induction of diverse LOAD risk genes, proinflammatory cytokines, complements, and ROS mediators", taxon := some Taxa.mouse }
  ]

/-- Run step H3.3: the neuroinflammatory response raises the risk of Alzheimer disease. -/
def S11 : Statement where
  id := "S11"
  text := "the neuroinflammatory response raises the risk of Alzheimer disease"
  claim := .effect neuroinflammation .pos (.disease alzheimers)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .hypothesis, note := "RIPK1-mediated neuroinflammation for promoting aging-related neurodegenerative diseases, including LOAD" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11]

/-- H1, claim 1: MS4A4A negatively regulates TREM2, ABI3, and PLCG2-mediated microglial innate immunity. -/
def h1c1a1 := viaAmount (lit S1) (viaProcess (lit S2) (lit S5))

/-- H1, claim 2: MS4A4A negatively regulates TREM2, ABI3, and PLCG2-mediated microglial innate immunity. -/
def h1c2a1 := viaProcess (lit S2) (lit S5)

/-- H1, claim 3: MS4A4A negatively regulates TREM2, ABI3, and PLCG2-mediated microglial innate immunity. -/
def h1c3a1 := viaProcess (lit S3) (lit S5)

/-- H1, claim 4: MS4A4A negatively regulates TREM2, ABI3, and PLCG2-mediated microglial innate immunity. -/
def h1c4a1 := viaProcess (lit S4) (lit S5)

/-- H2, claim 1: APOE4 impairs oligodendrocyte myelination via cholesterol dysregulation. -/
def h2c1a1 := viaPhenotype (fromAssoc (lit S6)) (viaProcess (lit S7) (lit S8))

/-- H3, claim 1: INPP5D protects against AD by repressing RIPK1-driven neuroinflammation. -/
def h3c1a1 := viaActivity (lit S9) (viaProcess (lit S10) (lit S11))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H1" "c2a1" h1c2a1,
    arm "H1" "c3a1" h1c3a1,
    arm "H1" "c4a1" h1c4a1,
    arm "H2" "c1a1" h2c1a1,
    arm "H3" "c1a1" h3c1a1]

#eval printRows "study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_google_cloud_gemini_3_1_pro_preview_multi_agent_r3
