import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-single_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-single_agent-r2`: google-cloud:gemini-3.1-pro-preview, Alzheimer disease, genes TREM2, RNPS1, INPP5D, APOE, MS4A4A, LPIN2, PLCG2, ABI3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_google_cloud_gemini_3_1_pro_preview_single_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def APOE : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def TREM2 : Entity .protein := ⟨"UniProt:Q9NZC2", "TREM2"⟩
def PLCG2 : Entity .protein := ⟨"UniProt:P16885", "PLCG2"⟩
def MS4A4A : Entity .protein := ⟨"UniProt:Q96JQ5", "MS4A4A"⟩
def INPP5D : Entity .protein := ⟨"UniProt:Q92835", "INPP5D"⟩
def ABI3 : Entity .protein := ⟨"UniProt:Q9P2A4", "ABI3"⟩
def microglialActivation : Entity .process := ⟨"GO:0001774", "microglial cell activation"⟩
def alzheimerDisease : Entity .disease := ⟨"MONDO:0004975", "Alzheimer disease"⟩

/-- Run step H1.1: APOE binds TREM2 (run: binds, polarity unknown). -/
def S1 : Statement where
  id := "S1"
  text := "APOE binds TREM2 (run: binds, polarity unknown)"
  claim := .rel ⟨.ro, 2436, false⟩ APOE TREM2
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9NZC2", kind := .curatedDb, note := "Acts as a receptor for lipoprotein particles such as LDL, VLDL, and HDL and for apolipoproteins such as APOA1, APOA2, APOB, APOE" },
    { pmid := 0, year := 2026, ref := "STRING:APOE-TREM2", kind := .curatedDb, note := "STRING links APOE and TREM2 with combined score 1.00 (experimental 0.58, database 0.00, text-mining 0.99)" }
  ]

/-- Run step H1.2: TREM2 activates PLCG2. -/
def S2 : Statement where
  id := "S2"
  text := "TREM2 activates PLCG2"
  claim := .effect TREM2 .pos (.activity PLCG2)
  evidence := []

/-- Run step H1.3, H3.2: PLCG2 lowers Alzheimer disease risk (run: PLCG2 inhibits Alzheimer disease). -/
def S3 : Statement where
  id := "S3"
  text := "PLCG2 lowers Alzheimer disease risk (run: PLCG2 inhibits Alzheimer disease)"
  claim := .effect PLCG2 .neg (.disease alzheimerDisease)
  evidence := []

/-- Run step H2.1: MS4A4A inhibits TREM2 (the cited paper: a post-transcriptional, indirect negative regulator of TREM2 protein levels, via MS4A6A and DAP12). -/
def S4 : Statement where
  id := "S4"
  text := "MS4A4A inhibits TREM2 (the cited paper: a post-transcriptional, indirect negative regulator of TREM2 protein levels, via MS4A6A and DAP12)"
  claim := .effect MS4A4A .neg (.activity TREM2)
  evidence := [
    { pmid := 41435829, year := 2026, kind := .mechanistic, note := "By modulating MS4A4A using knockout, overexpression, and degrading antibodies in macrophages, microglia, non-human primates (NHPs), and a mouse model of amyloid pathology, we provide evidence that MS4A4A and MS4A6A are negative regulators o", taxon := some Taxa.mouse }
  ]

/-- Run step H2.2: TREM2 lowers Alzheimer disease risk (run: TREM2 inhibits Alzheimer disease). -/
def S5 : Statement where
  id := "S5"
  text := "TREM2 lowers Alzheimer disease risk (run: TREM2 inhibits Alzheimer disease)"
  claim := .effect TREM2 .neg (.disease alzheimerDisease)
  evidence := []

/-- Run step H3.1: INPP5D inhibits PLCG2. -/
def S6 : Statement where
  id := "S6"
  text := "INPP5D inhibits PLCG2"
  claim := .effect INPP5D .neg (.activity PLCG2)
  evidence := []

/-- Run step H4.1: ABI3 is required for microglial activation (losing ABI3 lowers activation). -/
def S7 : Statement where
  id := "S7"
  text := "ABI3 is required for microglial activation (losing ABI3 lowers activation)"
  claim := .effect ABI3 .pos (.process microglialActivation)
  evidence := []

/-- Run step H4.2: microglial activation lowers Alzheimer disease risk (run: microglial activation inhibits Alzheimer disease). -/
def S8 : Statement where
  id := "S8"
  text := "microglial activation lowers Alzheimer disease risk (run: microglial activation inhibits Alzheimer disease)"
  claim := .effect microglialActivation .neg (.disease alzheimerDisease)
  evidence := [
    { pmid := 28714976, year := 2017, kind := .observational, polarity := .refutes, note := "the microglia-mediated innate immune response contributes directly to the development of Alzheimer's disease" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8]

/-- H1, claim 2: APOE activates TREM2-PLCG2 signaling to promote microglial phagocytosis. -/
def h1c2a1 := viaActivity (lit S2) (lit S3)

/-- H1, claim 2: APOE activates TREM2-PLCG2 signaling to promote microglial phagocytosis. -/
def h1c2a2 := lit S5

/-- H1, claim 3: APOE activates TREM2-PLCG2 signaling to promote microglial phagocytosis. -/
def h1c3a1 := lit S3

/-- H2, claim 1: MS4A4A negatively regulates protective TREM2 signaling in microglia. -/
def h2c1a1 := viaActivity (lit S4) (viaActivity (lit S2) (lit S3))

/-- H2, claim 1: MS4A4A negatively regulates protective TREM2 signaling in microglia. -/
def h2c1a2 := viaActivity (lit S4) (lit S5)

/-- H2, claim 2: MS4A4A negatively regulates protective TREM2 signaling in microglia. -/
def h2c2a1 := viaActivity (lit S2) (lit S3)

/-- H2, claim 2: MS4A4A negatively regulates protective TREM2 signaling in microglia. -/
def h2c2a2 := lit S5

/-- H3, claim 1: INPP5D suppresses PLCG2 activation by depleting PIP3 in microglia. -/
def h3c1a1 := viaActivity (lit S6) (lit S3)

/-- H3, claim 2: INPP5D suppresses PLCG2 activation by depleting PIP3 in microglia. -/
def h3c2a1 := lit S3

/-- H4, claim 1: ABI3 is required for microglial plaque compaction and immune response. -/
def h4c1a1 := viaProcess (lit S7) (lit S8)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c2a1" h1c2a1,
    arm "H1" "c2a2" h1c2a2,
    arm "H1" "c3a1" h1c3a1,
    arm "H2" "c1a1" h2c1a1,
    arm "H2" "c1a2" h2c1a2,
    arm "H2" "c2a1" h2c2a1,
    arm "H2" "c2a2" h2c2a2,
    arm "H3" "c1a1" h3c1a1,
    arm "H3" "c2a1" h3c2a1,
    arm "H4" "c1a1" h4c1a1]

#eval printRows "study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-single_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_google_cloud_gemini_3_1_pro_preview_single_agent_r2
