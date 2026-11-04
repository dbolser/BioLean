import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260825T000740Z-c7b373/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260825T000740Z-c7b373`: openai:gpt-5.6-sol, restless legs syndrome, genes ACO1, MEIS1, GLIPR1, PTPRD, GABARAPL2, BTBD9. -/

namespace BioLean.Lib.IPF.Runs.R20260825T000740Z_c7b373

open BioLean BioLean.Lib.IPF Derivation

def MEIS1 : Entity .protein := ⟨"UniProt:O00470", "MEIS1"⟩
def BTBD9 : Entity .protein := ⟨"UniProt:Q96Q07", "BTBD9"⟩
def PTPRD : Entity .protein := ⟨"UniProt:P23468", "PTPRD"⟩
def ACO1 : Entity .protein := ⟨"UniProt:P21399", "ACO1"⟩
def rls : Entity .disease := ⟨"MONDO:0005391", "restless legs syndrome"⟩
def sleepWakeDisturbance : Entity .phenotype := ⟨"HP:0006979", "Sleep-wake cycle disturbance"⟩
def abnSomatosensoryCortexMorph : Entity .phenotype := ⟨"MP:0000860", "abnormal primary somatosensory cortex morphology"⟩
def abnNervousElectrophys : Entity .phenotype := ⟨"HP:0001311", "Abnormal nervous system electrophysiology"⟩
def somatosensorySystem : Entity .anatomy := ⟨"UBERON:0003942", "somatosensory system"⟩
def abnSleepBehavior : Entity .phenotype := ⟨"MP:0011396", "abnormal sleep behavior"⟩
def motorDeficit : Entity .phenotype := ⟨"HP:0004302", "Functional motor deficit"⟩
def motorCircuitDisinhibition : Entity .phenotype := ⟨"BLN:MotorCircuitDisinhibition", "motor-circuit disinhibition (reduced inhibitory control of motor circuits)"⟩
def abnIronHomeostasis : Entity .phenotype := ⟨"HP:0011031", "Abnormality of iron homeostasis"⟩
def nervousSystem : Entity .anatomy := ⟨"UBERON:0001016", "nervous system"⟩
def abnCentralSensory : Entity .phenotype := ⟨"HP:0011730", "Abnormal central sensory function"⟩
def sleepProcess : Entity .process := ⟨"GO:0030431", "sleep"⟩
def plms : Entity .phenotype := ⟨"HP:5200295", "Periodic limb movements of sleep"⟩
def somatosensoryElectrophysAbn : Entity .phenotype := abnNervousElectrophys.inCtx { anatomy := somatosensorySystem }
def neuralIronHomeostasisAbn : Entity .phenotype := abnIronHomeostasis.inCtx { anatomy := nervousSystem }
def sleepSensoryDysfunction : Entity .phenotype := abnCentralSensory.inCtx { stage := sleepProcess }

/-- Run step H1_MEIS1_CIRCADIAN.1: MEIS1 is required for the normal circadian sleep/wake cycle: losing MEIS1 disturbs the cycle. Sign: the run's required_for (+) on 'normal circadian sleep/wake cycle': a cycle has no amount, so losing MEIS1 gives an abnormal cycle (undirected change, HP 'Sleep-wake cycle disturbance', +), inverted for the loss: MEIS1 →− disturbance. Same m. -/
def S1 : Statement where
  id := "S1"
  text := "MEIS1 is required for the normal circadian sleep/wake cycle: losing MEIS1 disturbs the cycle"
  claim := .effect MEIS1 .neg (.phenotype sleepWakeDisturbance)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:104717:MP:0020478", kind := .curatedDb, note := "the genotype Meis1<em1Rihw>/Meis1<em1Rihw> of Meis1 -- the orthologue of human MEIS1 -- shows abnormal circadian sleep/wake cycle", taxon := some Taxa.mouse }
  ]

/-- Run step H1_MEIS1_CIRCADIAN.2: a disrupted (abnormal) circadian sleep/wake cycle raises the risk of restless legs syndrome. -/
def S2 : Statement where
  id := "S2"
  text := "a disrupted (abnormal) circadian sleep/wake cycle raises the risk of restless legs syndrome"
  claim := .effect sleepWakeDisturbance .pos (.disease rls)
  evidence := []

/-- Run step H2_BTBD9_SLEEP_SENSORY.1: loss of BTBD9 causes abnormal primary somatosensory cortex morphology. Sign: inverted: the run's subject is 'BTBD9 dysfunction'. -/
def S3 : Statement where
  id := "S3"
  text := "loss of BTBD9 causes abnormal primary somatosensory cortex morphology"
  claim := .effect BTBD9 .neg (.phenotype abnSomatosensoryCortexMorph)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1916625:MP:0000860", kind := .curatedDb, note := "the genotype Btbd9<tm1c(EUCOMM)Wtsi>/Btbd9<tm1c(EUCOMM)Wtsi> Emx1<tm1(cre)Yql>/Emx1<+> of Btbd9 -- the orthologue of human BTBD9 -- shows abnormal primary somatosensory cortex morphology", taxon := some Taxa.mouse }
  ]

/-- Run step H2_BTBD9_SLEEP_SENSORY.1: loss of BTBD9 causes abnormal electrophysiology of somatosensory circuits. Sign: inverted: the run's subject is 'BTBD9 dysfunction'. -/
def S4 : Statement where
  id := "S4"
  text := "loss of BTBD9 causes abnormal electrophysiology of somatosensory circuits"
  claim := .effect BTBD9 .neg (.phenotype somatosensoryElectrophysAbn)
  evidence := []

/-- Run step H2_BTBD9_SLEEP_SENSORY.2: loss of BTBD9 causes abnormal sleep behavior. Sign: inverted: the run's subject is 'BTBD9 dysfunction'. -/
def S5 : Statement where
  id := "S5"
  text := "loss of BTBD9 causes abnormal sleep behavior"
  claim := .effect BTBD9 .neg (.phenotype abnSleepBehavior)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1916625:MP:0011396", kind := .curatedDb, note := "the genotype Btbd9<tm1c(EUCOMM)Wtsi>/Btbd9<tm1c(EUCOMM)Wtsi> Tg(Pcp2-cre)2Mpin/0 of Btbd9 -- the orthologue of human BTBD9 -- shows abnormal sleep behavior", taxon := some Taxa.mouse }
  ]

/-- Run step H3_PTPRD_MOTOR_CIRCUIT.1: loss of PTPRD causes a motor function deficit. Sign: inverted: the run's subject is 'PTPRD dysfunction'. -/
def S6 : Statement where
  id := "S6"
  text := "loss of PTPRD causes a motor function deficit"
  claim := .effect PTPRD .neg (.phenotype motorDeficit)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:97812:MP:0001522", kind := .curatedDb, note := "the genotype Ptprd<tm1Yiw>/Ptprd<tm1Yiw> of Ptprd -- the orthologue of human PTPRD -- shows impaired swimming", taxon := some Taxa.mouse }
  ]

/-- Run step H3_PTPRD_MOTOR_CIRCUIT.2: motor-circuit disinhibition raises the risk of restless legs syndrome. -/
def S7 : Statement where
  id := "S7"
  text := "motor-circuit disinhibition raises the risk of restless legs syndrome"
  claim := .effect motorCircuitDisinhibition .pos (.disease rls)
  evidence := []

/-- Run step H4_ACO1_IRON_MODIFIER.1: loss of ACO1 causes abnormal iron homeostasis. Sign: inverted: the run's subject is 'ACO1 dysfunction'. -/
def S8 : Statement where
  id := "S8"
  text := "loss of ACO1 causes abnormal iron homeostasis"
  claim := .effect ACO1 .neg (.phenotype abnIronHomeostasis)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:87879:MP:0005637", kind := .curatedDb, note := "the genotype Aco1<tm1Roua>/Aco1<tm1Roua> of Aco1 -- the orthologue of human ACO1 -- shows abnormal iron homeostasis", taxon := some Taxa.mouse }
  ]

/-- Run step H4_ACO1_IRON_MODIFIER.2: abnormal neural iron homeostasis raises the risk of restless legs syndrome. -/
def S9 : Statement where
  id := "S9"
  text := "abnormal neural iron homeostasis raises the risk of restless legs syndrome"
  claim := .effect neuralIronHomeostasisAbn .pos (.disease rls)
  evidence := []

/-- Run step H2_BTBD9_SLEEP_SENSORY.3: sleep-dependent sensory-circuit dysfunction raises the risk of restless legs syndrome. -/
def S10 : Statement where
  id := "S10"
  text := "sleep-dependent sensory-circuit dysfunction raises the risk of restless legs syndrome"
  claim := .effect sleepSensoryDysfunction .pos (.disease rls)
  evidence := []

/-- Run step H2_BTBD9_SLEEP_SENSORY.3: sleep-dependent sensory-circuit dysfunction leads to periodic limb movements of sleep. -/
def S11 : Statement where
  id := "S11"
  text := "sleep-dependent sensory-circuit dysfunction leads to periodic limb movements of sleep"
  claim := .effect sleepSensoryDysfunction .pos (.phenotype plms)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11]

/-- H1_MEIS1_CIRCADIAN, claim 1: MEIS1 risk variation promotes RLS by disrupting circadian sleep–wake control. -/
def h1c1a1 := viaPhenotype (lit S1) (lit S2)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1_MEIS1_CIRCADIAN" "c1a1" h1c1a1]

#eval printRows "20260825T000740Z-c7b373" rows

end BioLean.Lib.IPF.Runs.R20260825T000740Z_c7b373
