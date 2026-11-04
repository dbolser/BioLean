import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260824T235535Z-e9ec87/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260824T235535Z-e9ec87`: anthropic:claude-opus-5, schizophrenia, genes CSMD1, NXPH3, C4A, CX3CR1, CCDC136, C1QA, C4B. -/

namespace BioLean.Lib.IPF.Runs.R20260824T235535Z_e9ec87

open BioLean BioLean.Lib.IPF Derivation

def c4aHighCopy : Entity .variant := ⟨"BLN:C4A-highCopyNumber", "C4 structural haplotypes carrying more C4A copies"⟩
def csmd1RiskAlleles : Entity .variant := ⟨"BLN:CSMD1-schizophreniaRiskAlleles", "common CSMD1 schizophrenia risk alleles (presumed loss of function)"⟩
def C4A : Entity .protein := ⟨"UniProt:P0C0L4", "C4A"⟩
def C1QA : Entity .protein := ⟨"UniProt:P02745", "C1QA"⟩
def CSMD1 : Entity .protein := ⟨"UniProt:Q96PZ7", "CSMD1"⟩
def CX3CR1 : Entity .protein := ⟨"UniProt:P49238", "CX3CR1"⟩
def NXPH3 : Entity .protein := ⟨"UniProt:O95157", "NXPH3"⟩
def alphaNeurexins : Entity .protein := ⟨"BLN:AlphaNeurexins", "alpha-neurexins (NRXN1/2/3 alpha isoforms)"⟩
def synapse : Entity .component := ⟨"GO:0045202", "synapse"⟩
def synapsePruning : Entity .process := ⟨"GO:0098883", "synapse pruning"⟩
def classicalComplement : Entity .process := ⟨"GO:0006958", "complement activation, classical pathway"⟩
def microglialActivation : Entity .process := ⟨"GO:0001774", "microglial cell activation"⟩
def cx3cReceptorActivity : Entity .function := ⟨"GO:0016495", "C-X3-C chemokine receptor activity"⟩
def abnormalEPSC : Entity .phenotype := ⟨"MP:0002910", "abnormal excitatory postsynaptic currents"⟩
def abnormalIPSC : Entity .phenotype := ⟨"MP:0002945", "abnormal inhibitory postsynaptic currents"⟩
def apoptoticCellClearance : Entity .process := ⟨"GO:0043277", "apoptotic cell clearance"⟩
def neurogenesis : Entity .process := ⟨"GO:0022008", "neurogenesis"⟩
def prepulseInhibition : Entity .process := ⟨"GO:0060134", "prepulse inhibition"⟩
def spatialLearning : Entity .process := ⟨"GO:0008542", "visual learning"⟩
def schizophrenia : Entity .disease := ⟨"MONDO:0005090", "schizophrenia"⟩
def schizophreniaMouse : Entity .disease := schizophrenia.inCtx { taxon := Taxa.mouse }

/-- Run step H1.1: C4 haplotypes with more C4A copies raise C4A protein. -/
def S1 : Statement where
  id := "S1"
  text := "C4 haplotypes with more C4A copies raise C4A protein"
  claim := .effect c4aHighCopy .pos (.amount C4A)
  evidence := [
    { pmid := 42113976, year := 2026, kind := .observational, note := "a large positive correlation between the number of C4A gene copies and the amount of C4 protein only in neutrophils and only in the schizophrenia group" }
  ]

/-- Run step H1.2: C4A is located at synapses (the run says 'binds'; its note and source say localisation). -/
def S2 : Statement where
  id := "S2"
  text := "C4A is located at synapses (the run says 'binds'; its note and source say localisation)"
  claim := .rel ⟨.ro, 1025, false⟩ C4A synapse
  evidence := [
    { pmid := 0, year := 2026, ref := "P0C0L4", kind := .curatedDb, note := "Location: Secreted, Synapse, Cell projection, axon, Cell projection, dendrite" },
    { pmid := 26814963, year := 2016, kind := .observational, note := "Human C4 protein localized to neuronal synapses, dendrites, axons, and cell bodies." }
  ]

/-- Run step H1.3: C1QA (C1q) is required for microglial synapse pruning. -/
def S3 : Statement where
  id := "S3"
  text := "C1QA (C1q) is required for microglial synapse pruning"
  claim := .effect C1QA .pos (.process synapsePruning)
  evidence := []

/-- Run step H1.4: excess synapse pruning raises schizophrenia risk. -/
def S4 : Statement where
  id := "S4"
  text := "excess synapse pruning raises schizophrenia risk"
  claim := .effect synapsePruning .pos (.disease schizophrenia)
  evidence := []

/-- Bridge, not in the run: C4A promotes synapse pruning (stated by texts the run cited; no step makes it). -/
def S5 : Statement where
  id := "S5"
  text := "C4A promotes synapse pruning (stated by texts the run cited; no step makes it)"
  claim := .effect C4A .pos (.process synapsePruning)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .mechanistic, note := "In mice, C4 mediated synapse elimination during postnatal development.", taxon := some Taxa.mouse },
    { pmid := 38301948, year := 2024, kind := .review, note := "C4A is believed to contribute to physiological synapse removal" },
    { pmid := 42000733, year := 2026, kind := .review, note := "C4A, in contrast to C4B, is implicated in synaptic pruning" }
  ]

/-- Run step H2.1: CSMD1 schizophrenia risk alleles lower CSMD1 protein (at the synapse). -/
def S6 : Statement where
  id := "S6"
  text := "CSMD1 schizophrenia risk alleles lower CSMD1 protein (at the synapse)"
  claim := .effect csmd1RiskAlleles .neg (.amount CSMD1)
  evidence := []

/-- Run step H2.2: CSMD1 inhibits the classical complement pathway (astrocytes, brain). -/
def S7 : Statement where
  id := "S7"
  text := "CSMD1 inhibits the classical complement pathway (astrocytes, brain)"
  claim := .effect CSMD1 .neg (.process classicalComplement)
  evidence := [
    { pmid := 40112933, year := 2025, kind := .inVitro, note := "CSMD1 encodes a complement classical pathway inhibitor" }
  ]

/-- Run step H2.3: the classical complement pathway drives synapse elimination. -/
def S8 : Statement where
  id := "S8"
  text := "the classical complement pathway drives synapse elimination"
  claim := .effect classicalComplement .pos (.process synapsePruning)
  evidence := []

/-- Run step H2.4: loss of Csmd1 goes with a schizophrenia-like state in mice. Sign: the step is unsigned; direction from the cited AGR model annotation (the knockout models schizophrenia), then inverted: the run's subject is the Csmd1 knockout. -/
def S9 : Statement where
  id := "S9"
  text := "loss of Csmd1 goes with a schizophrenia-like state in mice"
  claim := .assoc CSMD1 (some .neg) (.disease schizophreniaMouse)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:2137383:DOID:5419", kind := .curatedDb, note := "which carries Csmd1, the orthologue of human CSMD1 -- is curated by MGI as a model of schizophrenia", taxon := some Taxa.mouse }
  ]

/-- Run step H3.1: CX3CR1 restrains microglial (phagocytic) activation. -/
def S10 : Statement where
  id := "S10"
  text := "CX3CR1 restrains microglial (phagocytic) activation"
  claim := .effect CX3CR1 .neg (.process microglialActivation)
  evidence := []

/-- Run step H3.2: microglial phagocytic activation is required for complement-dependent synapse pruning. -/
def S11 : Statement where
  id := "S11"
  text := "microglial phagocytic activation is required for complement-dependent synapse pruning"
  claim := .effect microglialActivation .pos (.process synapsePruning)
  evidence := [
    { pmid := 22632727, year := 2012, kind := .mechanistic, note := "microglia engulf presynaptic inputs during peak retinogeniculate pruning and that engulfment is dependent upon neural activity and the microglia-specific phagocytic signaling pathway, complement receptor 3(CR3)/C3", taxon := some Taxa.mouse }
  ]

/-- Run step H3.3: disrupted CX3CL1-CX3CR1 signalling goes with schizophrenia. Sign: the step is unsigned; direction from the cited meta-analysis (axis 'disruption' in schizophrenia, with CX3CL1 down in brain and CX3CR1 down in blood), then inverted: the run's subject is the axis disruption. -/
def S12 : Statement where
  id := "S12"
  text := "disrupted CX3CL1-CX3CR1 signalling goes with schizophrenia"
  claim := .assoc cx3cReceptorActivity (some .neg) (.disease schizophrenia)
  evidence := [
    { pmid := 42276261, year := 2026, kind := .observational, note := "neuroimmune dysregulation in Schizophrenia: convergent evidence for excessive complement system activity and CX3CL1-CX3CR1 axis disruption" }
  ]

/-- Run step H4.2: C1q deficiency causes abnormal excitatory synaptic transmission (hippocampus). Sign: inverted: the run's subject is C1q deficiency; 'abnormal X' is a phenotype term, so the effect is on its presence. -/
def S13 : Statement where
  id := "S13"
  text := "C1q deficiency causes abnormal excitatory synaptic transmission (hippocampus)"
  claim := .effect C1QA .neg (.phenotype abnormalEPSC)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:88223:MP:0002910", kind := .curatedDb, note := "of C1qa -- the orthologue of human C1QA -- shows abnormal excitatory postsynaptic currents", taxon := some Taxa.mouse }
  ]

/-- Run step H4.2: C1q deficiency causes abnormal inhibitory synaptic transmission (hippocampus). Sign: inverted: the run's subject is C1q deficiency; 'abnormal X' is a phenotype term, so the effect is on its presence. -/
def S14 : Statement where
  id := "S14"
  text := "C1q deficiency causes abnormal inhibitory synaptic transmission (hippocampus)"
  claim := .effect C1QA .neg (.phenotype abnormalIPSC)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:88223:MP:0002945", kind := .curatedDb, note := "of C1qa -- the orthologue of human C1QA -- shows abnormal inhibitory postsynaptic currents", taxon := some Taxa.mouse }
  ]

/-- Run step H4.3: impaired complement-dependent (apoptotic cell) clearance raises schizophrenia risk. Sign: inverted: the run's subject is impaired clearance. -/
def S15 : Statement where
  id := "S15"
  text := "impaired complement-dependent (apoptotic cell) clearance raises schizophrenia risk"
  claim := .effect apoptoticCellClearance .neg (.disease schizophrenia)
  evidence := []

/-- Run step H4.3: impaired (complement-dependent) neurogenesis raises schizophrenia risk. Sign: inverted: the run's subject is impaired neurogenesis. -/
def S16 : Statement where
  id := "S16"
  text := "impaired (complement-dependent) neurogenesis raises schizophrenia risk"
  claim := .effect neurogenesis .neg (.disease schizophrenia)
  evidence := []

/-- Run step H5.1: NXPH3 binds alpha-neurexins (cortical neurons). -/
def S17 : Statement where
  id := "S17"
  text := "NXPH3 binds alpha-neurexins (cortical neurons)"
  claim := .rel ⟨.ro, 2436, false⟩ NXPH3 alphaNeurexins
  evidence := [
    { pmid := 0, year := 2026, ref := "O95157", kind := .crossSpecies, note := "Ligand for alpha-neurexins (By similarity)" }
  ]

/-- Run step H5.2: NXPH3(-neurexin signalling) is required for sensorimotor gating (prepulse inhibition). -/
def S18 : Statement where
  id := "S18"
  text := "NXPH3(-neurexin signalling) is required for sensorimotor gating (prepulse inhibition)"
  claim := .effect NXPH3 .pos (.process prepulseInhibition)
  evidence := []

/-- Run step H5.2: NXPH3(-neurexin signalling) is required for spatial learning. -/
def S19 : Statement where
  id := "S19"
  text := "NXPH3(-neurexin signalling) is required for spatial learning"
  claim := .effect NXPH3 .pos (.process spatialLearning)
  evidence := []

/-- Run step H5.3: a sensorimotor gating deficit goes with schizophrenia. Sign: unsigned: the step's polarity is 'unknown' and no cited text gives a direction (the label's 'deficit' would be inverted). -/
def S20 : Statement where
  id := "S20"
  text := "a sensorimotor gating deficit goes with schizophrenia"
  claim := .assoc prepulseInhibition none (.disease schizophrenia)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20]

/-- H1, claim 1: C4A dosage drives classical-pathway tagging of synapses that C1q-bearing microglia eliminate, so excess C4A causes over-pruning of cortical synapses. -/
def h1c1a1 := viaAmount (lit S1) (viaProcess (lit S5) (lit S4))

/-- H2, claim 1: CSMD1 is a neuronal/astrocytic brake on classical complement at the synapse; loss-of-function releases C4b/C3b deposition and produces the same over-pruning end. -/
def h2c1a1 := viaAmount (lit S6) (viaProcess (lit S7) (viaProcess (lit S8) (lit S4)))

/-- H2, claim 2: CSMD1 is a neuronal/astrocytic brake on classical complement at the synapse; loss-of-function releases C4b/C3b deposition and produces the same over-pruning end. -/
def h2c2a1 := viaAmount (lit S6) (fromAssoc (lit S9))

/-- H3, claim 1: The primary lesion is microglial state, not complement substrate: CX3CL1-CX3CR1 signalling failure licenses microglia to prune, and complement gene changes are . -/
def h3c1a1 := viaProcess (lit S10) (viaProcess (lit S11) (lit S4))

/-- H4, claim 1: Complement in schizophrenia is deficient rather than excessive: reduced C1q and divergent C4A/C4B change impair clearance and neurogenesis, and the pruning mode. -/
def h4c1a1 := viaProcess (lit S3) (lit S4)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H2" "c1a1" h2c1a1,
    arm "H2" "c2a1" h2c2a1,
    arm "H3" "c1a1" h3c1a1,
    arm "H4" "c1a1" h4c1a1]

#eval printRows "20260824T235535Z-e9ec87" rows

end BioLean.Lib.IPF.Runs.R20260824T235535Z_e9ec87
