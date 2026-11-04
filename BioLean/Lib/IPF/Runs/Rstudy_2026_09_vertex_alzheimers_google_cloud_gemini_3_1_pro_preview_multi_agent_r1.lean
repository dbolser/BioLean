import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-multi_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-multi_agent-r1`: google-cloud:gemini-3.1-pro-preview, Alzheimer disease, genes TREM2, RNPS1, INPP5D, APOE, MS4A4A, LPIN2, PLCG2, ABI3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_google_cloud_gemini_3_1_pro_preview_multi_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def APOE : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def TREM2 : Entity .protein := ⟨"UniProt:Q9NZC2", "TREM2"⟩
def MS4A4A : Entity .protein := ⟨"UniProt:Q96JQ5", "MS4A4A"⟩
def INPP5D : Entity .protein := ⟨"UniProt:Q92835", "INPP5D"⟩
def RIPK1 : Entity .protein := ⟨"UniProt:Q13546", "RIPK1"⟩
def PLCG2 : Entity .protein := ⟨"UniProt:P16885", "PLCG2"⟩
def ABI3 : Entity .protein := ⟨"UniProt:Q9P2A4", "ABI3"⟩
def alzheimers : Entity .disease := ⟨"MONDO:0004975", "Alzheimer disease"⟩
def antiApoptosis : Entity .process := ⟨"GO:0043066", "negative regulation of apoptotic process"⟩
def matureMicroglia : Entity .cellType := ⟨"CL:0002629", "mature microglial cell"⟩
def senilePlaques : Entity .phenotype := ⟨"HP:0100256", "Senile plaques"⟩
def microglialSurvival : Entity .process := antiApoptosis.inCtx { cellType := matureMicroglia }

/-- Run step h1.1: APOE binds TREM2. -/
def S1 : Statement where
  id := "S1"
  text := "APOE binds TREM2"
  claim := .rel ⟨.ro, 2436, false⟩ APOE TREM2
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:APOE-TREM2", kind := .curatedDb, note := "STRING links APOE and TREM2 with combined score 1.00 (experimental 0.58, database 0.00, text-mining 0.99)" }
  ]

/-- Run step h1.2: TREM2 promotes microglial survival. -/
def S2 : Statement where
  id := "S2"
  text := "TREM2 promotes microglial survival"
  claim := .effect TREM2 .pos (.process microglialSurvival)
  evidence := [
    { pmid := 42689388, year := 2026, kind := .inVitro, note := "TREM2 knockdown aggravated LPS-induced loss of viability, apoptosis, inflammatory cytokine production, and M1-like polarization in BV-2 cells", taxon := some Taxa.mouse }
  ]

/-- Run step h1.3: TREM2 is associated with Alzheimer disease (no direction for TREM2 itself). -/
def S3 : Statement where
  id := "S3"
  text := "TREM2 is associated with Alzheimer disease (no direction for TREM2 itself)"
  claim := .assoc TREM2 none (.disease alzheimers)
  evidence := [
    { pmid := 28714976, year := 2017, kind := .observational, note := "a new genome-wide significant variant in TREM2 (rs143332484: p.Arg62His, P = 1.55 × 10-14, OR = 1.67, MAFcases = 0.0143, MAFcontrols = 0.0089), a known susceptibility gene for Alzheimer's disease" },
    { pmid := 0, year := 2026, ref := "OT:TREM2-MONDO_0004975", kind := .observational, note := "Open Targets 2026.06 scores the TREM2-Alzheimer disease association at 0.55 (literature 0.99, genetic_association 0.86)" }
  ]

/-- Run step h2.1: MS4A4A lowers the amount of TREM2. -/
def S4 : Statement where
  id := "S4"
  text := "MS4A4A lowers the amount of TREM2"
  claim := .effect MS4A4A .neg (.amount TREM2)
  evidence := [
    { pmid := 41435829, year := 2026, kind := .mechanistic, note := "MS4A4A and MS4A6A are negative regulators of both the transmembrane and soluble TREM2 proteins", taxon := some Taxa.mouse }
  ]

/-- Run step h2.2: MS4A4A is associated with Alzheimer disease (no direction). -/
def S5 : Statement where
  id := "S5"
  text := "MS4A4A is associated with Alzheimer disease (no direction)"
  claim := .assoc MS4A4A none (.disease alzheimers)
  evidence := [
    { pmid := 41435829, year := 2026, kind := .review, note := "The Alzheimer's disease risk genes MS4A4A and MS4A6A" },
    { pmid := 0, year := 2026, ref := "OT:MS4A4A-MONDO_0004975", kind := .observational, note := "Open Targets 2026.06 scores the MS4A4A-Alzheimer disease association at 0.25 (literature 0.74, genetic_association 0.38)" }
  ]

/-- Run step h3.1: INPP5D inhibits RIPK1 kinase activity. -/
def S6 : Statement where
  id := "S6"
  text := "INPP5D inhibits RIPK1 kinase activity"
  claim := .effect INPP5D .neg (.activity RIPK1)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .inVitro, note := "Repression of RIPK1 kinase by INPP5D" }
  ]

/-- Run step h3.2: PLCG2 lowers amyloid plaques. -/
def S7 : Statement where
  id := "S7"
  text := "PLCG2 lowers amyloid plaques"
  claim := .effect PLCG2 .neg (.phenotype senilePlaques)
  evidence := []

/-- Run step h3.3: ABI3 is associated with amyloid plaques (no direction for ABI3 itself). -/
def S8 : Statement where
  id := "S8"
  text := "ABI3 is associated with amyloid plaques (no direction for ABI3 itself)"
  claim := .assoc ABI3 none (.phenotype senilePlaques)
  evidence := [
    { pmid := 42092345, year := 2026, kind := .mechanistic, note := "Abi3S212F produced a dysfunctional microglial state that reduced dense-core plaque compaction, selectively lowering dense-core burden", taxon := some Taxa.mouse }
  ]

/-- Run step h3.4: INPP5D is associated with Alzheimer disease (no direction). -/
def S9 : Statement where
  id := "S9"
  text := "INPP5D is associated with Alzheimer disease (no direction)"
  claim := .assoc INPP5D none (.disease alzheimers)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .review, note := "INPP5D, an important LOAD risk gene" },
    { pmid := 0, year := 2026, ref := "OT:INPP5D-MONDO_0004975", kind := .observational, note := "Open Targets 2026.06 scores the INPP5D-Alzheimer disease association at 0.47 (literature 0.91, genetic_association 0.73)" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-alzheimers-google-cloud-gemini-3.1-pro-preview-multi_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_google_cloud_gemini_3_1_pro_preview_multi_agent_r1
