import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260825T112130Z-e77e3a/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260825T112130Z-e77e3a`: openai:gpt-5.6-sol, restless legs syndrome, genes ACO1, MEIS1, GLIPR1, PTPRD, GABARAPL2, BTBD9. -/

namespace BioLean.Lib.IPF.Runs.R20260825T112130Z_e77e3a

open BioLean BioLean.Lib.IPF Derivation

def rls : Entity .disease := ⟨"MONDO:0005391", "restless legs syndrome"⟩
def MEIS1 : Entity .protein := ⟨"UniProt:O00470", "MEIS1"⟩
def BTBD9 : Entity .protein := ⟨"UniProt:Q96Q07", "BTBD9"⟩
def ACO1 : Entity .protein := ⟨"UniProt:P21399", "ACO1"⟩
def PTPRD : Entity .protein := ⟨"UniProt:P23468", "PTPRD"⟩
def meis1RiskAlleles : Entity .variant := ⟨"BLN:MEIS1-RLSRiskAlleles", "RLS risk alleles at the MEIS1 locus (the class; no single variant named)"⟩
def ptprdRiskAlleles : Entity .variant := ⟨"BLN:PTPRD-RLSRiskAlleles", "RLS risk alleles at the PTPRD locus (the class; no single variant named)"⟩
def nervousSystemDevelopment : Entity .process := ⟨"GO:0007399", "nervous system development"⟩
def abnormalNervousSystemDevelopment : Entity .phenotype := ⟨"MP:0003861", "abnormal nervous system development"⟩
def ironTranslationRegulation : Entity .process := ⟨"GO:0006447", "regulation of translational initiation by iron"⟩
def ironHomeostasis : Entity .process := ⟨"GO:0006879", "intracellular iron ion homeostasis"⟩
def abnormalNeuroElectrophysiology : Entity .phenotype := ⟨"HP:0001311", "Abnormal nervous system electrophysiology"⟩
def sleepDisturbance : Entity .phenotype := ⟨"HP:0002360", "Sleep disturbance"⟩
def synapseAssembly : Entity .process := ⟨"GO:0007416", "synapse assembly"⟩
def abnormalSynapticPlasticity : Entity .phenotype := ⟨"MP:0004859", "abnormal synaptic plasticity"⟩
def abnormalSensorimotorGating : Entity .phenotype := ⟨"MP:0002634", "abnormal sensorimotor gating"⟩

/-- Run step H1.1: RLS risk alleles at MEIS1 go with an altered MEIS1 amount, direction not given (the run: altered MEIS1 regulation). -/
def S1 : Statement where
  id := "S1"
  text := "RLS risk alleles at MEIS1 go with an altered MEIS1 amount, direction not given (the run: altered MEIS1 regulation)"
  claim := .assoc meis1RiskAlleles none (.amount MEIS1)
  evidence := []

/-- Run step H1.2: MEIS1 is required for nervous system development (the run: normal neural and sleep–wake circuit development, in brain). -/
def S2 : Statement where
  id := "S2"
  text := "MEIS1 is required for nervous system development (the run: normal neural and sleep–wake circuit development, in brain)"
  claim := .effect MEIS1 .pos (.process nervousSystemDevelopment)
  evidence := []

/-- Run step H1.3: abnormal nervous system development raises RLS risk (the run: abnormal sleep–motor circuit development). -/
def S3 : Statement where
  id := "S3"
  text := "abnormal nervous system development raises RLS risk (the run: abnormal sleep–motor circuit development)"
  claim := .effect abnormalNervousSystemDevelopment .pos (.disease rls)
  evidence := []

/-- Run step H2.1: BTBD9 is associated with ACO1, direction unknown. -/
def S4 : Statement where
  id := "S4"
  text := "BTBD9 is associated with ACO1, direction unknown"
  claim := .assoc BTBD9 none (.activity ACO1)
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:ACO1-BTBD9", kind := .curatedDb, note := "STRING links ACO1 and BTBD9 with combined score 0.45 (experimental 0.41, database 0.00, text-mining 0.09)" }
  ]

/-- Run step H2.2: ACO1 is required for iron-regulated translation of iron-metabolism mRNAs (the run: cellular iron-responsive RNA regulation). -/
def S5 : Statement where
  id := "S5"
  text := "ACO1 is required for iron-regulated translation of iron-metabolism mRNAs (the run: cellular iron-responsive RNA regulation)"
  claim := .effect ACO1 .pos (.process ironTranslationRegulation)
  evidence := [
    { pmid := 0, year := 2026, ref := "P21399", kind := .curatedDb, note := "Binds to iron-responsive elements (IRES) in the untranslated region of target mRNAs preventing for instance the translation of ferritin" }
  ]

/-- Run step H2.2: ACO1 is required for intracellular iron homeostasis. -/
def S6 : Statement where
  id := "S6"
  text := "ACO1 is required for intracellular iron homeostasis"
  claim := .effect ACO1 .pos (.process ironHomeostasis)
  evidence := [
    { pmid := 0, year := 2026, ref := "P21399", kind := .curatedDb, note := "Iron deprivation, promotes its mRNA binding activity through which it regulates the expression of genes involved in iron uptake, sequestration and utilization" }
  ]

/-- Run step H2.3: loss of BTBD9 leads to abnormal nervous system electrophysiology. Sign: inverted: the run's subject is 'BTBD9–ACO1 pathway dysfunction', split per gene. -/
def S7 : Statement where
  id := "S7"
  text := "loss of BTBD9 leads to abnormal nervous system electrophysiology"
  claim := .effect BTBD9 .neg (.phenotype abnormalNeuroElectrophysiology)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1916625:MP:0002272", kind := .curatedDb, note := "the genotype Btbd9<tm1d(EUCOMM)Wtsi>/Btbd9<tm1d(EUCOMM)Wtsi> of Btbd9 -- the orthologue of human BTBD9 -- shows abnormal nervous system electrophysiology", taxon := some Taxa.mouse }
  ]

/-- Run step H2.3: loss of BTBD9 leads to sleep disturbance (the run: abnormal sleep behavior). Sign: inverted: the run's subject is 'BTBD9–ACO1 pathway dysfunction', split per gene. -/
def S8 : Statement where
  id := "S8"
  text := "loss of BTBD9 leads to sleep disturbance (the run: abnormal sleep behavior)"
  claim := .effect BTBD9 .neg (.phenotype sleepDisturbance)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1916625:MP:0011396", kind := .curatedDb, note := "the genotype Btbd9<tm1c(EUCOMM)Wtsi>/Btbd9<tm1c(EUCOMM)Wtsi> Tg(Pcp2-cre)2Mpin/0 of Btbd9 -- the orthologue of human BTBD9 -- shows abnormal sleep behavior", taxon := some Taxa.mouse }
  ]

/-- Run step H2.3: loss of ACO1 leads to abnormal nervous system electrophysiology. Sign: inverted: the run's subject is 'BTBD9–ACO1 pathway dysfunction', split per gene. -/
def S9 : Statement where
  id := "S9"
  text := "loss of ACO1 leads to abnormal nervous system electrophysiology"
  claim := .effect ACO1 .neg (.phenotype abnormalNeuroElectrophysiology)
  evidence := []

/-- Run step H2.3: loss of ACO1 leads to sleep disturbance. Sign: inverted: the run's subject is 'BTBD9–ACO1 pathway dysfunction', split per gene. -/
def S10 : Statement where
  id := "S10"
  text := "loss of ACO1 leads to sleep disturbance"
  claim := .effect ACO1 .neg (.phenotype sleepDisturbance)
  evidence := []

/-- Run step H2.4: abnormal nervous system electrophysiology raises RLS risk. -/
def S11 : Statement where
  id := "S11"
  text := "abnormal nervous system electrophysiology raises RLS risk"
  claim := .effect abnormalNeuroElectrophysiology .pos (.disease rls)
  evidence := []

/-- Run step H2.4: sleep disturbance raises RLS risk (the run: abnormal sleep behavior). -/
def S12 : Statement where
  id := "S12"
  text := "sleep disturbance raises RLS risk (the run: abnormal sleep behavior)"
  claim := .effect sleepDisturbance .pos (.disease rls)
  evidence := []

/-- Run step H3.1: RLS risk alleles at PTPRD go with an altered PTPRD amount, direction not given (the run: altered PTPRD regulation or function). -/
def S13 : Statement where
  id := "S13"
  text := "RLS risk alleles at PTPRD go with an altered PTPRD amount, direction not given (the run: altered PTPRD regulation or function)"
  claim := .assoc ptprdRiskAlleles none (.amount PTPRD)
  evidence := []

/-- Run step H3.1: RLS risk alleles at PTPRD go with altered PTPRD activity, direction not given (the run: altered PTPRD regulation or function). -/
def S14 : Statement where
  id := "S14"
  text := "RLS risk alleles at PTPRD go with altered PTPRD activity, direction not given (the run: altered PTPRD regulation or function)"
  claim := .assoc ptprdRiskAlleles none (.activity PTPRD)
  evidence := []

/-- Run step H3.2: PTPRD is required for synapse assembly (the run: trans-synaptic pre- and postsynaptic differentiation, in excitatory and inhibitory neurons). -/
def S15 : Statement where
  id := "S15"
  text := "PTPRD is required for synapse assembly (the run: trans-synaptic pre- and postsynaptic differentiation, in excitatory and inhibitory neurons)"
  claim := .effect PTPRD .pos (.process synapseAssembly)
  evidence := [
    { pmid := 0, year := 2026, ref := "P23468", kind := .crossSpecies, note := "Can bidirectionally induce pre- and post-synaptic differentiation of neurons by mediating interaction with IL1RAP and IL1RAPL1 trans-synaptically" }
  ]

/-- Run step H3.3: loss of synapse assembly leads to abnormal synaptic plasticity (the run: disrupted PTPRD-dependent synaptic differentiation → abnormal sensorimotor circuit plasticity). Sign: inverted: the run's subject is 'disrupted PTPRD-dependent synaptic differentiation'. -/
def S16 : Statement where
  id := "S16"
  text := "loss of synapse assembly leads to abnormal synaptic plasticity (the run: disrupted PTPRD-dependent synaptic differentiation → abnormal sensorimotor circuit plasticity)"
  claim := .effect synapseAssembly .neg (.phenotype abnormalSynapticPlasticity)
  evidence := []

/-- Run step H3.3: loss of synapse assembly leads to abnormal sensorimotor gating (the run: disrupted PTPRD-dependent synaptic differentiation → abnormal sensorimotor circuit gating). Sign: inverted: the run's subject is 'disrupted PTPRD-dependent synaptic differentiation'. -/
def S17 : Statement where
  id := "S17"
  text := "loss of synapse assembly leads to abnormal sensorimotor gating (the run: disrupted PTPRD-dependent synaptic differentiation → abnormal sensorimotor circuit gating)"
  claim := .effect synapseAssembly .neg (.phenotype abnormalSensorimotorGating)
  evidence := []

/-- Run step H3.4: abnormal sensorimotor gating raises RLS risk. -/
def S18 : Statement where
  id := "S18"
  text := "abnormal sensorimotor gating raises RLS risk"
  claim := .effect abnormalSensorimotorGating .pos (.disease rls)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18]

/-- H2, claim 1: BTBD9 risk acts through ACO1-dependent iron sensing to alter neuronal excitability. -/
def h2c1a1 := viaPhenotype (lit S7) (lit S11)

/-- H2, claim 1: BTBD9 risk acts through ACO1-dependent iron sensing to alter neuronal excitability. -/
def h2c1a2 := viaPhenotype (lit S8) (lit S12)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H2" "c1a1" h2c1a1,
    arm "H2" "c1a2" h2c1a2]

#eval printRows "20260825T112130Z-e77e3a" rows

end BioLean.Lib.IPF.Runs.R20260825T112130Z_e77e3a
