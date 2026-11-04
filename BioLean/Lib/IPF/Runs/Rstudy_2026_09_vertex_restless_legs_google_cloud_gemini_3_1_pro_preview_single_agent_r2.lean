import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-single_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-single_agent-r2`: google-cloud:gemini-3.1-pro-preview, restless legs syndrome, genes ACO1, MEIS1, GLIPR1, PTPRD, GABARAPL2, BTBD9. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_google_cloud_gemini_3_1_pro_preview_single_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def BTBD9 : Entity .protein := ⟨"UniProt:Q96Q07", "BTBD9"⟩
def ACO1 : Entity .protein := ⟨"UniProt:P21399", "ACO1"⟩
def ironHomeostasis : Entity .process := ⟨"GO:0006879", "intracellular iron ion homeostasis"⟩
def PTPRD : Entity .protein := ⟨"UniProt:P23468", "PTPRD"⟩
def inhibitorySynapseAssembly : Entity .process := ⟨"GO:1904862", "inhibitory synapse assembly"⟩
def MEIS1 : Entity .protein := ⟨"UniProt:O00470", "MEIS1"⟩
def cerebellarOutput : Entity .process := ⟨"BLN:CerebellarOutput", "cerebellar output (the output activity of the cerebellum)"⟩
def rls : Entity .disease := ⟨"MONDO:0005391", "restless legs syndrome"⟩

/-- Run step hyp1-btbd9-aco1.1: BTBD9 binds ACO1. -/
def S1 : Statement where
  id := "S1"
  text := "BTBD9 binds ACO1"
  claim := .rel ⟨.ro, 2436, false⟩ BTBD9 ACO1
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:ACO1-BTBD9", kind := .curatedDb, note := "STRING links ACO1 and BTBD9 with combined score 0.45 (experimental 0.41, database 0.00, text-mining 0.09)" }
  ]

/-- Run step hyp1-btbd9-aco1.2: BTBD9 lowers the amount of ACO1. -/
def S2 : Statement where
  id := "S2"
  text := "BTBD9 lowers the amount of ACO1"
  claim := .effect BTBD9 .neg (.amount ACO1)
  evidence := []

/-- Run step hyp1-btbd9-aco1.3: ACO1 is associated with iron homeostasis (no direction). -/
def S3 : Statement where
  id := "S3"
  text := "ACO1 is associated with iron homeostasis (no direction)"
  claim := .assoc ACO1 none (.process ironHomeostasis)
  evidence := [
    { pmid := 0, year := 2026, ref := "P21399", kind := .curatedDb, note := "promotes its mRNA binding activity through which it regulates the expression of genes involved in iron uptake, sequestration and utilization" },
    { pmid := 0, year := 2026, ref := "AGR:MGI:87879:MP:0005637", kind := .curatedDb, note := "Aco1 -- the orthologue of human ACO1 -- shows abnormal iron homeostasis", taxon := some Taxa.mouse }
  ]

/-- Run step hyp1-btbd9-aco1.4: iron homeostasis is associated with restless legs syndrome (no direction). -/
def S4 : Statement where
  id := "S4"
  text := "iron homeostasis is associated with restless legs syndrome (no direction)"
  claim := .assoc ironHomeostasis none (.disease rls)
  evidence := [
    { pmid := 30363981, year := 2014, kind := .review, note := "the complex interplay between iron metabolism and RLS" }
  ]

/-- Run step hyp2-ptprd-synapse.1: PTPRD is required for inhibitory synapse development (losing PTPRD lowers it). -/
def S5 : Statement where
  id := "S5"
  text := "PTPRD is required for inhibitory synapse development (losing PTPRD lowers it)"
  claim := .effect PTPRD .pos (.process inhibitorySynapseAssembly)
  evidence := [
    { pmid := 22286174, year := 2012, kind := .inVitro, note := "Slitrk3 required trans-interaction with axonal PTPδ to induce inhibitory presynaptic differentiation", taxon := some Taxa.rat }
  ]

/-- Run step hyp2-ptprd-synapse.2: inhibitory synapse development lowers restless legs syndrome risk. -/
def S6 : Statement where
  id := "S6"
  text := "inhibitory synapse development lowers restless legs syndrome risk"
  claim := .effect inhibitorySynapseAssembly .neg (.disease rls)
  evidence := []

/-- Run step hyp2-ptprd-synapse.3: PTPRD is associated with restless legs syndrome (no direction for the gene). -/
def S7 : Statement where
  id := "S7"
  text := "PTPRD is associated with restless legs syndrome (no direction for the gene)"
  claim := .assoc PTPRD none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs34602324", kind := .observational, note := "rs34602324-G is associated with 'Restless legs syndrome' at p = 5e-162, beta 0.120799 unit (increase) [0.11-0.13] (mapped gene PTPRD" },
    { pmid := 0, year := 2026, ref := "rs6477358", kind := .observational, note := "rs6477358-T is associated with 'Restless legs syndrome' at p = 9e-110, beta 0.13158695 unit (decrease) [0.12-0.14] (mapped gene PTPRD" },
    { pmid := 0, year := 2026, ref := "OT:PTPRD-MONDO_0005391", kind := .observational, note := "Open Targets 2026.06 scores the PTPRD-restless legs syndrome association at 0.39 (literature 0.20, genetic_association 0.63)" }
  ]

/-- Run step hyp3-meis1-cerebellum.1: MEIS1 restrains cerebellar output. -/
def S8 : Statement where
  id := "S8"
  text := "MEIS1 restrains cerebellar output"
  claim := .effect MEIS1 .neg (.process cerebellarOutput)
  evidence := [
    { pmid := 42309051, year := 2026, kind := .mechanistic, note := "Disinhibition of cerebellar output by loss of restless legs syndrome-associated gene MEIS1", taxon := some Taxa.zebrafish }
  ]

/-- Run step hyp3-meis1-cerebellum.2: cerebellar output raises restless legs syndrome risk. -/
def S9 : Statement where
  id := "S9"
  text := "cerebellar output raises restless legs syndrome risk"
  claim := .effect cerebellarOutput .pos (.disease rls)
  evidence := []

/-- Run step hyp3-meis1-cerebellum.3: MEIS1 is associated with restless legs syndrome (no direction for the gene). -/
def S10 : Statement where
  id := "S10"
  text := "MEIS1 is associated with restless legs syndrome (no direction for the gene)"
  claim := .assoc MEIS1 none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs113851554", kind := .observational, note := "rs113851554-T is associated with 'Restless legs syndrome' at p = 1e-1371, beta 0.668701 unit (increase) [0.65-0.69] (mapped gene MEIS1" },
    { pmid := 0, year := 2026, ref := "OT:MEIS1-MONDO_0005391", kind := .observational, note := "Open Targets 2026.06 scores the MEIS1-restless legs syndrome association at 0.55 (literature 0.18, genetic_association 0.82, genetic_literature 0.30)" },
    { pmid := 42309051, year := 2026, kind := .review, note := "restless legs syndrome-associated gene MEIS1" },
    { pmid := 0, year := 2026, ref := "rs1820989", kind := .observational, note := "rs1820989-A is associated with 'Restless legs syndrome' at p = 1e-58, odds ratio 1.1363636 [1.11-1.15] (author-reported gene MEIS1" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10]

/-- hyp2-ptprd-synapse, claim 1: PTPRD limits Restless Legs Syndrome risk by promoting inhibitory synapse development. -/
def h2c1a1 := viaProcess (lit S5) (lit S6)

/-- hyp3-meis1-cerebellum, claim 1: MEIS1 restricts cerebellar output to prevent Restless Legs Syndrome. -/
def h3c1a1 := viaProcess (lit S8) (lit S9)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp2-ptprd-synapse" "c1a1" h2c1a1,
    arm "hyp3-meis1-cerebellum" "c1a1" h3c1a1]

#eval printRows "study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-single_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_google_cloud_gemini_3_1_pro_preview_single_agent_r2
