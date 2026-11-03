import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-multi_agent-r2`: google-cloud:gemini-3.1-pro-preview, Alzheimer disease, genes TREM2, RNPS1, INPP5D, APOE, MS4A4A, LPIN2, PLCG2, ABI3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_google_cloud_gemini_3_1_pro_preview_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def TREM2 : Entity .protein := ⟨"UniProt:Q9NZC2", "TREM2"⟩
def PLCG2 : Entity .protein := ⟨"UniProt:P16885", "PLCG2"⟩
def ABI3 : Entity .protein := ⟨"UniProt:Q9P2A4", "ABI3"⟩
def APOE : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def INPP5D : Entity .protein := ⟨"UniProt:Q92835", "INPP5D"⟩
def RIPK1 : Entity .protein := ⟨"UniProt:Q13546", "RIPK1"⟩
def MS4A4A : Entity .protein := ⟨"UniProt:Q96JQ5", "MS4A4A"⟩
def ad : Entity .disease := ⟨"MONDO:0004975", "Alzheimer disease"⟩

/-- Run step H1.1: TREM2 activates PLCG2. -/
def S1 : Statement where
  id := "S1"
  text := "TREM2 activates PLCG2"
  claim := .effect TREM2 .pos (.activity PLCG2)
  evidence := []

/-- Run step H1.2: PLCG2 lowers Alzheimer disease risk. -/
def S2 : Statement where
  id := "S2"
  text := "PLCG2 lowers Alzheimer disease risk"
  claim := .effect PLCG2 .neg (.disease ad)
  evidence := [
    { pmid := 41888907, year := 2026, kind := .review, note := "in vivo models that show how PLCG2 modulates microglial states, promotes brain resilience, and mitigates AD-related pathophysiology" }
  ]

/-- Run step H1.3: ABI3 is associated with TREM2 (no direction). Sign: the step's polarity is unknown and no cited text gives one. -/
def S3 : Statement where
  id := "S3"
  text := "ABI3 is associated with TREM2 (no direction)"
  claim := .assoc ABI3 none (.activity TREM2)
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:ABI3-TREM2", kind := .textMined, note := "STRING links ABI3 and TREM2 with combined score 0.65 (experimental 0.00, database 0.00, text-mining 0.63)" }
  ]

/-- Run step H1.4: ABI3 lowers Alzheimer disease risk. -/
def S4 : Statement where
  id := "S4"
  text := "ABI3 lowers Alzheimer disease risk"
  claim := .effect ABI3 .neg (.disease ad)
  evidence := []

/-- Run step H2.1: APOE binds TREM2. -/
def S5 : Statement where
  id := "S5"
  text := "APOE binds TREM2"
  claim := .rel ⟨.ro, 2436, false⟩ APOE TREM2
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:APOE-TREM2", kind := .curatedDb, note := "STRING links APOE and TREM2 with combined score 1.00 (experimental 0.58" }
  ]

/-- Run step H2.2, H4.2: TREM2 lowers Alzheimer disease risk. -/
def S6 : Statement where
  id := "S6"
  text := "TREM2 lowers Alzheimer disease risk"
  claim := .effect TREM2 .neg (.disease ad)
  evidence := []

/-- Run step H2.3: APOE is associated with Alzheimer disease (no direction). Sign: the step's polarity is unknown; the cited text gives a direction only for the APOE epsilon 4 allele, not for the gene the step names. -/
def S7 : Statement where
  id := "S7"
  text := "APOE is associated with Alzheimer disease (no direction)"
  claim := .assoc APOE none (.disease ad)
  evidence := [
    { pmid := 8346443, year := 1993, kind := .observational, note := "Risk for AD increased from 20% to 90% and mean age at onset decreased from 84 to 68 years with increasing number of APOE-epsilon 4 alleles" },
    { pmid := 0, year := 2026, ref := "OT:APOE-MONDO_0004975", kind := .observational, note := "Open Targets 2026.06 scores the APOE-Alzheimer disease association at 0.68" }
  ]

/-- Run step H3.1: INPP5D inhibits RIPK1 kinase activity. -/
def S8 : Statement where
  id := "S8"
  text := "INPP5D inhibits RIPK1 kinase activity"
  claim := .effect INPP5D .neg (.activity RIPK1)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .inVitro, note := "INPP5D, an important LOAD risk gene, directly interacted with the cell death regulator RIPK1 at p-Y383 to suppress RIPK1 kinase activation" }
  ]

/-- Run step H3.2: INPP5D lowers Alzheimer disease risk. -/
def S9 : Statement where
  id := "S9"
  text := "INPP5D lowers Alzheimer disease risk"
  claim := .effect INPP5D .neg (.disease ad)
  evidence := []

/-- Run step H4.1: MS4A4A inhibits TREM2. -/
def S10 : Statement where
  id := "S10"
  text := "MS4A4A inhibits TREM2"
  claim := .effect MS4A4A .neg (.activity TREM2)
  evidence := [
    { pmid := 41435829, year := 2026, kind := .mechanistic, note := "By modulating MS4A4A using knockout, overexpression, and degrading antibodies in macrophages, microglia, non-human primates (NHPs), and a mouse model of amyloid pathology, we provide evidence that MS4A4A and MS4A6A are negative regulators o", taxon := some Taxa.mouse }
  ]

/-- Bridge, not in the run: RIPK1 kinase activity raises Alzheimer disease risk. Sign: read from 'RIPK1-mediated neuroinflammation for promoting ... LOAD'; the paper proposes this, it does not test AD. -/
def S11 : Statement where
  id := "S11"
  text := "RIPK1 kinase activity raises Alzheimer disease risk"
  claim := .effect RIPK1 .pos (.disease ad)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .hypothesis, note := "RIPK1-mediated neuroinflammation for promoting aging-related neurodegenerative diseases, including LOAD" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11]

/-- H1, claim 1: TREM2, PLCG2, and ABI3 form a microglial signaling complex that clears amyloid plaques. -/
def h1c1a1 := viaActivity (lit S1) (lit S2)

/-- H1, claim 1: TREM2, PLCG2, and ABI3 form a microglial signaling complex that clears amyloid plaques. -/
def h1c1a2 := lit S6

/-- H1, claim 2: TREM2, PLCG2, and ABI3 form a microglial signaling complex that clears amyloid plaques. -/
def h1c2a1 := lit S2

/-- H1, claim 3: TREM2, PLCG2, and ABI3 form a microglial signaling complex that clears amyloid plaques. -/
def h1c3a1 := lit S4

/-- H3, claim 1: INPP5D inhibits RIPK1 to suppress microglial inflammation. -/
def h3c1a1 := viaActivity (lit S8) (lit S11)

/-- H3, claim 1: INPP5D inhibits RIPK1 to suppress microglial inflammation. -/
def h3c1a2 := lit S9

/-- H4, claim 1: MS4A4A negatively regulates TREM2 in microglia. -/
def h4c1a1 := viaActivity (lit S10) (viaActivity (lit S1) (lit S2))

/-- H4, claim 1: MS4A4A negatively regulates TREM2 in microglia. -/
def h4c1a2 := viaActivity (lit S10) (lit S6)

/-- H4, claim 2: MS4A4A negatively regulates TREM2 in microglia. -/
def h4c2a1 := viaActivity (lit S1) (lit S2)

/-- H4, claim 2: MS4A4A negatively regulates TREM2 in microglia. -/
def h4c2a2 := lit S6

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H1" "c1a2" h1c1a2,
    arm "H1" "c2a1" h1c2a1,
    arm "H1" "c3a1" h1c3a1,
    arm "H3" "c1a1" h3c1a1,
    arm "H3" "c1a2" h3c1a2,
    arm "H4" "c1a1" h4c1a1,
    arm "H4" "c1a2" h4c1a2,
    arm "H4" "c2a1" h4c2a1,
    arm "H4" "c2a2" h4c2a2]

#eval printRows "study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_google_cloud_gemini_3_1_pro_preview_multi_agent_r2
