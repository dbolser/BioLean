import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260825T001904Z-3b7b5b/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260825T001904Z-3b7b5b`: anthropic:claude-opus-5, schizophrenia, genes CSMD1, NXPH3, C4A, CX3CR1, CCDC136, C1QA, C4B. -/

namespace BioLean.Lib.IPF.Runs.R20260825T001904Z_3b7b5b

open BioLean BioLean.Lib.IPF Derivation

def C4A : Entity .protein := ⟨"UniProt:P0C0L4", "C4A"⟩
def C4B : Entity .protein := ⟨"UniProt:P0C0L5", "C4B"⟩
def C1QA : Entity .protein := ⟨"UniProt:P02745", "C1QA"⟩
def CSMD1 : Entity .protein := ⟨"UniProt:Q96PZ7", "CSMD1"⟩
def CX3CR1 : Entity .protein := ⟨"UniProt:P49238", "CX3CR1"⟩
def NXPH3 : Entity .protein := ⟨"UniProt:O95157", "NXPH3"⟩
def CCDC136 : Entity .protein := ⟨"UniProt:Q96JN2", "CCDC136"⟩
def alphaNeurexin : Entity .protein := ⟨"BLN:AlphaNeurexin", "alpha-neurexin (the alpha isoforms of the neurexins, as a class)"⟩
def synapse : Entity .component := ⟨"GO:0045202", "synapse"⟩
def liver : Entity .anatomy := ⟨"UBERON:0002107", "liver"⟩
def classicalComplement : Entity .process := ⟨"GO:0006958", "complement activation, classical pathway"⟩
def opsonization : Entity .process := ⟨"GO:0008228", "opsonization"⟩
def synapsePruning : Entity .process := ⟨"GO:0098883", "synapse pruning"⟩
def complementPruning : Entity .process := ⟨"GO:0150062", "complement-mediated synapse pruning"⟩
def corticalThinning : Entity .phenotype := ⟨"UPHENO:0080827", "decreased thickness of the cerebral cortex"⟩
def abnormalEPSC : Entity .phenotype := ⟨"MP:0002910", "abnormal excitatory postsynaptic currents"⟩
def abnormalIPSC : Entity .phenotype := ⟨"MP:0002945", "abnormal inhibitory postsynaptic currents"⟩
def abnormalStartle : Entity .phenotype := ⟨"MP:0001486", "abnormal startle reflex"⟩
def abnormalGating : Entity .phenotype := ⟨"MP:0002634", "abnormal sensorimotor gating"⟩
def microglialSurveillance : Entity .process := ⟨"BLN:MicroglialSynapticSurveillance", "microglial surveillance of synapses (process extension and contact with synaptic structures)"⟩
def microglialRefinement : Entity .process := ⟨"BLN:MicroglialSynapticRefinement", "microglial synaptic refinement (selective, correctly timed removal of synapses by microglia)"⟩
def scz : Entity .disease := ⟨"MONDO:0005090", "schizophrenia"⟩
def psychoticDisorder : Entity .disease := ⟨"MONDO:0005485", "psychotic disorder"⟩
def synapseOpsonization : Entity .process := opsonization.inCtx { component := synapse }

/-- Run step H1.1: C4A protein is located at synapses (the location part of 'C4A increases C4 protein at synapse'). -/
def S1 : Statement where
  id := "S1"
  text := "C4A protein is located at synapses (the location part of 'C4A increases C4 protein at synapse')"
  claim := .rel ⟨.ro, 1025, false⟩ C4A synapse
  evidence := [
    { pmid := 26814963, year := 2016, kind := .observational, note := "Human C4 protein localized to neuronal synapses" }
  ]

/-- Run step H1.2: C1QA activates the classical complement pathway. -/
def S2 : Statement where
  id := "S2"
  text := "C1QA activates the classical complement pathway"
  claim := .effect C1QA .pos (.process classicalComplement)
  evidence := [
    { pmid := 38301948, year := 2024, kind := .review, note := "the C1q initiated classical activation axis of the complement system" }
  ]

/-- Run step H1.3: CSMD1 inhibits the classical complement pathway. -/
def S3 : Statement where
  id := "S3"
  text := "CSMD1 inhibits the classical complement pathway"
  claim := .effect CSMD1 .neg (.process classicalComplement)
  evidence := [
    { pmid := 40112933, year := 2025, kind := .inVitro, note := "CSMD1 encodes a complement classical pathway inhibitor" }
  ]

/-- Run step H1.4: complement tagging of synapses raises synapse pruning. -/
def S4 : Statement where
  id := "S4"
  text := "complement tagging of synapses raises synapse pruning"
  claim := .effect synapseOpsonization .pos (.process synapsePruning)
  evidence := [
    { pmid := 22632727, year := 2012, kind := .mechanistic, note := "microglia engulf presynaptic inputs during peak retinogeniculate pruning and that engulfment is dependent upon neural activity and the microglia-specific phagocytic signaling pathway, complement receptor 3(CR3)/C3", taxon := some Taxa.mouse },
    { pmid := 26814963, year := 2016, kind := .mechanistic, note := "In mice, C4 mediated synapse elimination during postnatal development", taxon := some Taxa.mouse },
    { pmid := 41903141, year := 2026, kind := .review, polarity := .refutes, note := "Contrary to the models of excessive microglia-mediated synaptic elimination, our previous results indicate that C4-OE reduces spine formation and elimination", taxon := some Taxa.mouse }
  ]

/-- Run step H1.4: complement tagging of synapses leads to cortical thinning. -/
def S5 : Statement where
  id := "S5"
  text := "complement tagging of synapses leads to cortical thinning"
  claim := .effect synapseOpsonization .pos (.phenotype corticalThinning)
  evidence := []

/-- Run step H1.5: excess synapse pruning raises schizophrenia risk. -/
def S6 : Statement where
  id := "S6"
  text := "excess synapse pruning raises schizophrenia risk"
  claim := .effect synapsePruning .pos (.disease scz)
  evidence := []

/-- Run step H2.1: C1QA is required for normal excitatory postsynaptic currents (it lowers the 'abnormal' phenotype). Sign: the run says C1QA is required for normal currents; written as C1QA lowering the MP 'abnormal excitatory postsynaptic currents' phenotype, which the knockout shows. -/
def S7 : Statement where
  id := "S7"
  text := "C1QA is required for normal excitatory postsynaptic currents (it lowers the 'abnormal' phenotype)"
  claim := .effect C1QA .neg (.phenotype abnormalEPSC)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:88223:MP:0002910", kind := .curatedDb, note := "the genotype C1qa<tm1Mjw>/C1qa<tm1Mjw> of C1qa -- the orthologue of human C1QA -- shows abnormal excitatory postsynaptic currents", taxon := some Taxa.mouse }
  ]

/-- Run step H2.1: C1QA is required for normal inhibitory postsynaptic currents (it lowers the 'abnormal' phenotype). Sign: the run says C1QA is required for normal currents; written as C1QA lowering the MP 'abnormal inhibitory postsynaptic currents' phenotype, which the knockout shows. -/
def S8 : Statement where
  id := "S8"
  text := "C1QA is required for normal inhibitory postsynaptic currents (it lowers the 'abnormal' phenotype)"
  claim := .effect C1QA .neg (.phenotype abnormalIPSC)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:88223:MP:0002945", kind := .curatedDb, note := "the genotype C1qa<tm1Mjw>/C1qa<tm1Mjw> of C1qa -- the orthologue of human C1QA -- shows abnormal inhibitory postsynaptic currents", taxon := some Taxa.mouse }
  ]

/-- Run step H2.2: lower C1q goes with first-episode psychosis. Sign: the run gives polarity 'unknown' (its note says a decrease); PMID:38301948 reports lower CSF C1qA in first-episode psychosis. -/
def S9 : Statement where
  id := "S9"
  text := "lower C1q goes with first-episode psychosis"
  claim := .assoc C1QA (some .neg) (.disease psychoticDisorder)
  evidence := [
    { pmid := 38301948, year := 2024, kind := .observational, note := "CSF concentrations of C1qA were lower in individuals diagnosed with FEP" }
  ]

/-- Run step H2.3: CX3CR1 is required for microglial synaptic surveillance. -/
def S10 : Statement where
  id := "S10"
  text := "CX3CR1 is required for microglial synaptic surveillance"
  claim := .effect CX3CR1 .pos (.process microglialSurveillance)
  evidence := []

/-- Run step H2.4: microglial synaptic refinement lowers schizophrenia risk (degraded refinement raises it). Sign: inverted: the run's subject is degraded microglial synaptic refinement. -/
def S11 : Statement where
  id := "S11"
  text := "microglial synaptic refinement lowers schizophrenia risk (degraded refinement raises it)"
  claim := .effect microglialRefinement .neg (.disease scz)
  evidence := []

/-- Run step H3.1: NXPH3 binds alpha-neurexins. -/
def S12 : Statement where
  id := "S12"
  text := "NXPH3 binds alpha-neurexins"
  claim := .rel ⟨.ro, 2436, false⟩ NXPH3 alphaNeurexin
  evidence := [
    { pmid := 0, year := 2026, ref := "O95157", kind := .crossSpecies, note := "Ligand for alpha-neurexins (By similarity)" }
  ]

/-- Run step H3.2: NXPH3 is required for a normal acoustic startle (it lowers the 'abnormal startle reflex' phenotype). Sign: the run says NXPH3 is required for normal startle; written as NXPH3 lowering the MP 'abnormal startle reflex' phenotype; the knockout shows increased startle, a child term. -/
def S13 : Statement where
  id := "S13"
  text := "NXPH3 is required for a normal acoustic startle (it lowers the 'abnormal startle reflex' phenotype)"
  claim := .effect NXPH3 .neg (.phenotype abnormalStartle)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1336188:MP:0001488", kind := .curatedDb, note := "the genotype Nxph3<tm1.1Mami>/Nxph3<tm1.1Mami> of Nxph3 -- the orthologue of human NXPH3 -- shows increased startle reflex", taxon := some Taxa.mouse }
  ]

/-- Run step H3.2: NXPH3 is required for normal sensorimotor gating (it lowers the 'abnormal sensorimotor gating' phenotype). Sign: the run says NXPH3 is required for normal sensorimotor gating; written as NXPH3 lowering the MP 'abnormal sensorimotor gating' phenotype. -/
def S14 : Statement where
  id := "S14"
  text := "NXPH3 is required for normal sensorimotor gating (it lowers the 'abnormal sensorimotor gating' phenotype)"
  claim := .effect NXPH3 .neg (.phenotype abnormalGating)
  evidence := []

/-- Run step H4.1: C4A is expressed in the liver (the source part of 'C4A increases circulating C4', context liver). -/
def S15 : Statement where
  id := "S15"
  text := "C4A is expressed in the liver (the source part of 'C4A increases circulating C4', context liver)"
  claim := .rel ⟨.ro, 2206, false⟩ C4A liver
  evidence := []

/-- Run step H4.3: CX3CR1 is required for the microglial response to complement-opsonised synapses (complement-mediated synapse pruning). -/
def S16 : Statement where
  id := "S16"
  text := "CX3CR1 is required for the microglial response to complement-opsonised synapses (complement-mediated synapse pruning)"
  claim := .effect CX3CR1 .pos (.process complementPruning)
  evidence := []

/-- Run step H4.4: lower CX3CR1 goes with schizophrenia. Sign: the run gives polarity 'unknown'; PMID:42276261 reports CX3CR1 underexpression in the blood of people with schizophrenia. -/
def S17 : Statement where
  id := "S17"
  text := "lower CX3CR1 goes with schizophrenia"
  claim := .assoc CX3CR1 (some .neg) (.disease scz)
  evidence := [
    { pmid := 42276261, year := 2026, kind := .observational, note := "In SZ individuals, blood CX3CR1 underexpression" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17]

/-- H2, claim 2: The complement change in schizophrenia is a loss of tonic C1q/CX3CR1 surveillance, not a gain — mistimed rather than excessive pruning. -/
def h2c2a1 := fromAssoc (lit S17)

/-- H3, claim 2: NXPH3 and CCDC136 mark a neuron-intrinsic, complement-independent arm: neurexin-ligand signalling in deep cortical neurons setting sensorimotor gating. -/
def h3c2a1 := lit S13

/-- H3, claim 3: NXPH3 and CCDC136 mark a neuron-intrinsic, complement-independent arm: neurexin-ligand signalling in deep cortical neurons setting sensorimotor gating. -/
def h3c3a1 := lit S14

/-- H4, claim 3: Peripheral, not brain-intrinsic: liver-derived C4 crossing a permeable barrier drives the association, making CX3CR1 the only tractable node. -/
def h4c3a1 := fromAssoc (lit S17)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H2" "c2a1" h2c2a1,
    arm "H3" "c2a1" h3c2a1,
    arm "H3" "c3a1" h3c3a1,
    arm "H4" "c3a1" h4c3a1]

#eval printRows "20260825T001904Z-3b7b5b" rows

end BioLean.Lib.IPF.Runs.R20260825T001904Z_3b7b5b
