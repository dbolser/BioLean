import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-single_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-single_agent-r3`: google-cloud:gemini-3.1-pro-preview, restless legs syndrome, genes ACO1, MEIS1, GLIPR1, PTPRD, GABARAPL2, BTBD9. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_google_cloud_gemini_3_1_pro_preview_single_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def MEIS1 : Entity .protein := ⟨"UniProt:O00470", "MEIS1"⟩
def PTPRD : Entity .protein := ⟨"UniProt:P23468", "PTPRD"⟩
def BTBD9 : Entity .protein := ⟨"UniProt:Q96Q07", "BTBD9"⟩
def ACO1 : Entity .protein := ⟨"UniProt:P21399", "ACO1"⟩
def rls : Entity .disease := ⟨"MONDO:0005391", "restless legs syndrome"⟩
def circadianSleepWake : Entity .process := ⟨"GO:0042745", "circadian sleep/wake cycle"⟩
def synapseAssembly : Entity .process := ⟨"GO:0007416", "synapse assembly"⟩
def ironHomeostasis : Entity .process := ⟨"GO:0006879", "intracellular iron ion homeostasis"⟩

/-- Run step hyp-1.1: MEIS1 is associated with restless legs syndrome (direction not given). Sign: unsigned: the run gives polarity unknown; the GWAS row gives the direction of the rs113851554 T allele, not of MEIS1. -/
def S1 : Statement where
  id := "S1"
  text := "MEIS1 is associated with restless legs syndrome (direction not given)"
  claim := .assoc MEIS1 none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs113851554", kind := .observational, note := "rs113851554-T is associated with 'Restless legs syndrome' at p = 1e-1371, beta 0.668701 unit (increase) [0.65-0.69] (mapped gene MEIS1" }
  ]

/-- Run step hyp-1.2: MEIS1 is required for the circadian sleep/wake cycle (losing MEIS1 lowers it). -/
def S2 : Statement where
  id := "S2"
  text := "MEIS1 is required for the circadian sleep/wake cycle (losing MEIS1 lowers it)"
  claim := .effect MEIS1 .pos (.process circadianSleepWake)
  evidence := []

/-- Run step hyp-1.3: PTPRD is associated with restless legs syndrome (direction not given). Sign: unsigned: the run gives polarity unknown; the GWAS row gives the direction of the rs34602324 G allele, not of PTPRD, and the pleiotropy paper gives none. -/
def S3 : Statement where
  id := "S3"
  text := "PTPRD is associated with restless legs syndrome (direction not given)"
  claim := .assoc PTPRD none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs34602324", kind := .observational, note := "rs34602324-G is associated with 'Restless legs syndrome' at p = 5e-162, beta 0.120799 unit (increase) [0.11-0.13] (mapped gene PTPRD" },
    { pmid := 40561837, year := 2025, kind := .observational, note := "Our findings suggest that the PTPRD gene may contribute to the comorbidity of ADHD and RLS through pleiotropic effects" }
  ]

/-- Run step hyp-1.4: PTPRD is required for synaptic differentiation, grounded as synapse assembly (losing PTPRD lowers it). -/
def S4 : Statement where
  id := "S4"
  text := "PTPRD is required for synaptic differentiation, grounded as synapse assembly (losing PTPRD lowers it)"
  claim := .effect PTPRD .pos (.process synapseAssembly)
  evidence := [
    { pmid := 0, year := 2026, ref := "P23468", kind := .crossSpecies, note := "Can bidirectionally induce pre- and post-synaptic differentiation of neurons" }
  ]

/-- Run step hyp-2.1: BTBD9 is associated with restless legs syndrome (direction not given). Sign: unsigned: the run gives polarity unknown; the GWAS row gives the direction of the rs10947738 A allele, not of BTBD9. -/
def S5 : Statement where
  id := "S5"
  text := "BTBD9 is associated with restless legs syndrome (direction not given)"
  claim := .assoc BTBD9 none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs10947738", kind := .observational, note := "rs10947738-A is associated with 'Restless legs syndrome' at p = 1e-688, beta 0.282407 unit (increase) [0.27-0.29] (mapped gene BTBD9" }
  ]

/-- Run step hyp-2.2: BTBD9 binds ACO1. -/
def S6 : Statement where
  id := "S6"
  text := "BTBD9 binds ACO1"
  claim := .rel ⟨.ro, 2436, false⟩ BTBD9 ACO1
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:ACO1-BTBD9", kind := .curatedDb, note := "STRING links ACO1 and BTBD9 with combined score 0.45 (experimental 0.41, database 0.00, text-mining 0.09)" }
  ]

/-- Run step hyp-2.3: ACO1 is required for iron homeostasis (losing ACO1 lowers it). -/
def S7 : Statement where
  id := "S7"
  text := "ACO1 is required for iron homeostasis (losing ACO1 lowers it)"
  claim := .effect ACO1 .pos (.process ironHomeostasis)
  evidence := [
    { pmid := 0, year := 2026, ref := "P21399", kind := .curatedDb, note := "Iron deprivation, promotes its mRNA binding activity through which it regulates the expression of genes involved in iron uptake, sequestration and utilization" }
  ]

/-- Run step hyp-2.4: iron homeostasis is associated with restless legs syndrome (direction not given). Sign: unsigned: the run gives polarity unknown, and the review says the role of iron in RLS 'is still a matter of debate'. -/
def S8 : Statement where
  id := "S8"
  text := "iron homeostasis is associated with restless legs syndrome (direction not given)"
  claim := .assoc ironHomeostasis none (.disease rls)
  evidence := [
    { pmid := 30363981, year := 2014, kind := .review, note := "A link between restless legs syndrome (RLS) and iron has been recognized for several decades" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8]

/-- hyp-1, claim 2: Variants in MEIS1 and PTPRD converge on disrupted synaptic differentiation and circadian sleep-wake circuitry.. -/
def h1c2a1 := lit S2

/-- hyp-1, claim 4: Variants in MEIS1 and PTPRD converge on disrupted synaptic differentiation and circadian sleep-wake circuitry.. -/
def h1c4a1 := lit S4

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp-1" "c2a1" h1c2a1,
    arm "hyp-1" "c4a1" h1c4a1]

#eval printRows "study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-single_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_google_cloud_gemini_3_1_pro_preview_single_agent_r3
