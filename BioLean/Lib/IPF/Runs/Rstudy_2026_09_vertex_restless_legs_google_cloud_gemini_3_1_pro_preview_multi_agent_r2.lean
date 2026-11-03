import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-multi_agent-r2`: google-cloud:gemini-3.1-pro-preview, restless legs syndrome, genes ACO1, MEIS1, GLIPR1, PTPRD, GABARAPL2, BTBD9. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_google_cloud_gemini_3_1_pro_preview_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def MEIS1 : Entity .protein := ⟨"UniProt:O00470", "MEIS1"⟩
def BTBD9 : Entity .protein := ⟨"UniProt:Q96Q07", "BTBD9"⟩
def PTPRD : Entity .protein := ⟨"UniProt:P23468", "PTPRD"⟩
def ACO1 : Entity .protein := ⟨"UniProt:P21399", "ACO1"⟩
def rls : Entity .disease := ⟨"MONDO:0005391", "restless legs syndrome"⟩
def sleepDisturbance : Entity .phenotype := ⟨"HP:0002360", "Sleep disturbance"⟩
def purkinjeMorphologyAbnormal : Entity .phenotype := ⟨"MP:0000877", "abnormal Purkinje cell morphology"⟩
def cerebellarOutput : Entity .process := ⟨"BLN:CerebellarOutput", "cerebellar output"⟩
def synapseAssembly : Entity .process := ⟨"GO:0007416", "synapse assembly"⟩
def motorBehavior : Entity .process := ⟨"GO:0061744", "motor behavior"⟩
def ironImport : Entity .process := ⟨"GO:0033212", "iron import into cell"⟩

/-- Run step H1.1: MEIS1 is required for normal sleep: losing it gives a sleep disturbance. Sign: the run says MEIS1 is required_for (+) 'sleep behavior', and its mechanism says disruption gives 'altered sleep behavior'; a behaviour is not a quantity, so the step is loss of MEIS1 leads to abnormal sleep (undirected change, HP 'Sleep dis. -/
def S1 : Statement where
  id := "S1"
  text := "MEIS1 is required for normal sleep: losing it gives a sleep disturbance"
  claim := .effect MEIS1 .neg (.phenotype sleepDisturbance)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:104717:MP:0020478", kind := .curatedDb, note := "the genotype Meis1<sup>em1Rihw</sup>/Meis1<sup>em1Rihw</sup> of Meis1 -- the orthologue of human MEIS1 -- shows abnormal circadian sleep/wake cycle", taxon := some Taxa.mouse }
  ]

/-- Run step H1.2: MEIS1 inhibits cerebellar output. -/
def S2 : Statement where
  id := "S2"
  text := "MEIS1 inhibits cerebellar output"
  claim := .effect MEIS1 .neg (.process cerebellarOutput)
  evidence := [
    { pmid := 42309051, year := 2026, kind := .mechanistic, note := "Disinhibition of cerebellar output by loss of restless legs syndrome-associated gene MEIS1", taxon := some Taxa.zebrafish }
  ]

/-- Run step H1.3: BTBD9 is required for normal Purkinje cell morphology: losing it gives abnormal Purkinje cell morphology. Sign: the run says BTBD9 is required_for (+) 'Purkinje cell morphology', and its mechanism says loss of BTBD9 'results in abnormal morphology of Purkinje cells'; morphology has no amount, so the step is an undirected change on the 'abnormal Purki. -/
def S3 : Statement where
  id := "S3"
  text := "BTBD9 is required for normal Purkinje cell morphology: losing it gives abnormal Purkinje cell morphology"
  claim := .effect BTBD9 .neg (.phenotype purkinjeMorphologyAbnormal)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1916625:MP:0000877", kind := .curatedDb, note := "the genotype Btbd9<sup>tm1d(EUCOMM)Wtsi</sup>/Btbd9<sup>tm1d(EUCOMM)Wtsi</sup> of Btbd9 -- the orthologue of human BTBD9 -- shows abnormal Purkinje cell morphology", taxon := some Taxa.mouse }
  ]

/-- Run step H1.4: BTBD9 is required for normal sleep: losing it gives a sleep disturbance. Sign: as S1: required_for (+) 'sleep behavior' read as loss of BTBD9 leads to abnormal sleep, inverted for the loss: BTBD9 →− sleep disturbance. -/
def S4 : Statement where
  id := "S4"
  text := "BTBD9 is required for normal sleep: losing it gives a sleep disturbance"
  claim := .effect BTBD9 .neg (.phenotype sleepDisturbance)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1916625:MP:0011396", kind := .curatedDb, note := "the genotype Btbd9<sup>tm1c(EUCOMM)Wtsi</sup>/Btbd9<sup>tm1c(EUCOMM)Wtsi</sup> Tg(Pcp2-cre)2Mpin/0 of Btbd9 -- the orthologue of human BTBD9 -- shows abnormal sleep behavior", taxon := some Taxa.mouse }
  ]

/-- Run step H1.5: MEIS1 is associated with restless legs syndrome (no direction for the gene). Sign: unknown in the run; the cited GWAS rows give a direction for an allele (rs113851554-T, rs1820989-A), not for MEIS1, so none. -/
def S5 : Statement where
  id := "S5"
  text := "MEIS1 is associated with restless legs syndrome (no direction for the gene)"
  claim := .assoc MEIS1 none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs113851554", kind := .observational, note := "rs113851554-T is associated with 'Restless legs syndrome' at p = 1e-1371, beta 0.668701 unit (increase) [0.65-0.69] (mapped gene MEIS1" },
    { pmid := 0, year := 2026, ref := "rs1820989", kind := .observational, note := "rs1820989-A is associated with 'Restless legs syndrome' at p = 1e-58, odds ratio 1.1363636 [1.11-1.15] (author-reported gene MEIS1" },
    { pmid := 42309051, year := 2026, kind := .review, note := "restless legs syndrome-associated gene MEIS1" }
  ]

/-- Run step H1.6: BTBD9 is associated with restless legs syndrome (no direction for the gene). Sign: unknown in the run; the cited GWAS rows give a direction for an allele (rs10947738-A, rs61192259-A), not for BTBD9, so none. -/
def S6 : Statement where
  id := "S6"
  text := "BTBD9 is associated with restless legs syndrome (no direction for the gene)"
  claim := .assoc BTBD9 none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs10947738", kind := .observational, note := "rs10947738-A is associated with 'Restless legs syndrome' at p = 1e-688, beta 0.282407 unit (increase) [0.27-0.29] (mapped gene BTBD9" },
    { pmid := 0, year := 2026, ref := "rs61192259", kind := .observational, note := "rs61192259-A is associated with 'Restless legs syndrome' at p = 4e-202, odds ratio 1.26 [1.25-1.28] (author-reported gene BTBD9" }
  ]

/-- Run step H2.1: PTPRD promotes synaptic differentiation (synapse assembly). -/
def S7 : Statement where
  id := "S7"
  text := "PTPRD promotes synaptic differentiation (synapse assembly)"
  claim := .effect PTPRD .pos (.process synapseAssembly)
  evidence := [
    { pmid := 0, year := 2026, ref := "P23468", kind := .crossSpecies, note := "Can bidirectionally induce pre- and post-synaptic differentiation of neurons" }
  ]

/-- Run step H2.2: PTPRD is required for motor behavior: losing it lowers motor performance. -/
def S8 : Statement where
  id := "S8"
  text := "PTPRD is required for motor behavior: losing it lowers motor performance"
  claim := .effect PTPRD .pos (.process motorBehavior)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:97812:MP:0001522", kind := .curatedDb, note := "the genotype Ptprd<sup>tm1Yiw</sup>/Ptprd<sup>tm1Yiw</sup> of Ptprd -- the orthologue of human PTPRD -- shows impaired swimming", taxon := some Taxa.mouse },
    { pmid := 0, year := 2026, ref := "AGR:MGI:97812:MP:0010053", kind := .curatedDb, note := "the genotype Ptprd<sup>tm2a(KOMP)Wtsi</sup>/Ptprd<sup>tm2a(KOMP)Wtsi</sup> of Ptprd -- the orthologue of human PTPRD -- shows decreased grip strength", taxon := some Taxa.mouse }
  ]

/-- Run step H2.3: PTPRD is associated with restless legs syndrome (no direction for the gene). Sign: unknown in the run; the cited GWAS rows give a direction for an allele (rs34602324-G, rs1836229-A), not for PTPRD, so none. -/
def S9 : Statement where
  id := "S9"
  text := "PTPRD is associated with restless legs syndrome (no direction for the gene)"
  claim := .assoc PTPRD none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs34602324", kind := .observational, note := "rs34602324-G is associated with 'Restless legs syndrome' at p = 5e-162, beta 0.120799 unit (increase) [0.11-0.13] (mapped gene PTPRD" },
    { pmid := 0, year := 2026, ref := "rs1836229", kind := .observational, note := "rs1836229-A is associated with 'Restless legs syndrome' at p = 7e-42, odds ratio 1.1111112 [1.1-1.12] (author-reported gene PTPRD" }
  ]

/-- Run step H3.1: BTBD9 binds ACO1. -/
def S10 : Statement where
  id := "S10"
  text := "BTBD9 binds ACO1"
  claim := .rel ⟨.ro, 2436, false⟩ BTBD9 ACO1
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:ACO1-BTBD9", kind := .curatedDb, note := "STRING links ACO1 and BTBD9 with combined score 0.45 (experimental 0.41" }
  ]

/-- Run step H3.2: ACO1 promotes iron uptake. -/
def S11 : Statement where
  id := "S11"
  text := "ACO1 promotes iron uptake"
  claim := .effect ACO1 .pos (.process ironImport)
  evidence := []

/-- Run step H3.3: iron uptake is associated with restless legs syndrome (no direction). Sign: unknown in the run, and the cited text gives no direction, so none. -/
def S12 : Statement where
  id := "S12"
  text := "iron uptake is associated with restless legs syndrome (no direction)"
  claim := .assoc ironImport none (.disease rls)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12]

/-- H1, claim 3: MEIS1 and BTBD9 risk variants disrupt cerebellar Purkinje cell morphology and output, driving motor and sleep phenotypes in Restless Legs Syndrome.. -/
def h1c3a1 := lit S2

/-- H1, claim 4: MEIS1 and BTBD9 risk variants disrupt cerebellar Purkinje cell morphology and output, driving motor and sleep phenotypes in Restless Legs Syndrome.. -/
def h1c4a1 := lit S3

/-- H2, claim 2: PTPRD loss of function impairs synaptic differentiation and drives motor deficits in Restless Legs Syndrome.. -/
def h2c2a1 := lit S8

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c3a1" h1c3a1,
    arm "H1" "c4a1" h1c4a1,
    arm "H2" "c2a1" h2c2a1]

#eval printRows "study-2026-09-vertex-restless-legs-google-cloud-gemini-3.1-pro-preview-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_restless_legs_google_cloud_gemini_3_1_pro_preview_multi_agent_r2
