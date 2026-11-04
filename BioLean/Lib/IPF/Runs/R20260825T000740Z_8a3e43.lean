import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260825T000740Z-8a3e43/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260825T000740Z-8a3e43`: openai:gpt-5.6-sol, schizophrenia, genes CSMD1, NXPH3, C4A, CX3CR1, CCDC136, C1QA, C4B. -/

namespace BioLean.Lib.IPF.Runs.R20260825T000740Z_8a3e43

open BioLean BioLean.Lib.IPF Derivation

def c4RiskVariation : Entity .variant := ⟨"BLN:C4-schizophrenia-associated-variation", "schizophrenia risk alleles at the C4A/C4B (complement C4) locus, structural and SNP"⟩
def c4a : Entity .protein := ⟨"UniProt:P0C0L4", "C4A"⟩
def c4b : Entity .protein := ⟨"UniProt:P0C0L5", "C4B"⟩
def c1qa : Entity .protein := ⟨"UniProt:P02745", "C1QA"⟩
def cx3cr1 : Entity .protein := ⟨"UniProt:P49238", "CX3CR1"⟩
def csmd1RiskVariation : Entity .variant := ⟨"BLN:CSMD1-schizophrenia-associated-variation", "schizophrenia risk alleles in CSMD1"⟩
def csmd1 : Entity .protein := ⟨"UniProt:Q96PZ7", "CSMD1"⟩
def nxph3 : Entity .protein := ⟨"UniProt:O95157", "NXPH3"⟩
def nrxn1 : Entity .protein := ⟨"UniProt:Q9ULB1", "NRXN1"⟩
def nrxn2 : Entity .protein := ⟨"UniProt:Q9P2S2", "NRXN2"⟩
def nrxn3 : Entity .protein := ⟨"UniProt:Q9Y4C0", "NRXN3"⟩
def synapsePruning : Entity .process := ⟨"GO:0098883", "synapse pruning"⟩
def classicalComplement : Entity .process := ⟨"GO:0006958", "complement activation, classical pathway"⟩
def synapseMaturation : Entity .process := ⟨"GO:0060074", "synapse maturation"⟩
def abnormalMicrogliaPhysiology : Entity .phenotype := ⟨"MP:0003691", "abnormal microglial cell physiology"⟩
def abnormalSpatialLearning : Entity .phenotype := ⟨"MP:0001463", "abnormal spatial learning"⟩
def abnormalStartleReflex : Entity .phenotype := ⟨"MP:0001486", "abnormal startle reflex"⟩
def abnormalSynapticTransmission : Entity .phenotype := ⟨"HP:0012535", "Abnormal synaptic transmission"⟩
def cognitiveImpairment : Entity .phenotype := ⟨"HP:0100543", "Cognitive impairment"⟩
def schizophrenia : Entity .disease := ⟨"MONDO:0005090", "schizophrenia"⟩

/-- Run step H1.1: schizophrenia-associated C4-locus variation raises C4A. -/
def S1 : Statement where
  id := "S1"
  text := "schizophrenia-associated C4-locus variation raises C4A"
  claim := .effect c4RiskVariation .pos (.amount c4a)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .observational, note := "each common C4 allele associating with schizophrenia in proportion to its tendency to generate greater expression of C4A" }
  ]

/-- Run step H1.1: schizophrenia-associated C4-locus variation raises C4B. -/
def S2 : Statement where
  id := "S2"
  text := "schizophrenia-associated C4-locus variation raises C4B"
  claim := .effect c4RiskVariation .pos (.amount c4b)
  evidence := []

/-- Run step H1.2: C1QA drives synapse elimination. -/
def S3 : Statement where
  id := "S3"
  text := "C1QA drives synapse elimination"
  claim := .effect c1qa .pos (.process synapsePruning)
  evidence := []

/-- Run step H1.2: C4A drives synapse elimination. -/
def S4 : Statement where
  id := "S4"
  text := "C4A drives synapse elimination"
  claim := .effect c4a .pos (.process synapsePruning)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .mechanistic, note := "In mice, C4 mediated synapse elimination during postnatal development", taxon := some Taxa.mouse },
    { pmid := 38301948, year := 2024, kind := .review, note := "C4A is believed to contribute to physiological synapse removal" }
  ]

/-- Run step H1.2: C4B drives synapse elimination. -/
def S5 : Statement where
  id := "S5"
  text := "C4B drives synapse elimination"
  claim := .effect c4b .pos (.process synapsePruning)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .mechanistic, note := "In mice, C4 mediated synapse elimination during postnatal development", taxon := some Taxa.mouse },
    { pmid := 42000733, year := 2026, kind := .review, polarity := .refutes, note := "C4A, in contrast to C4B, is implicated in synaptic pruning" }
  ]

/-- Run step H1.3: excess synapse elimination raises schizophrenia risk. -/
def S6 : Statement where
  id := "S6"
  text := "excess synapse elimination raises schizophrenia risk"
  claim := .effect synapsePruning .pos (.disease schizophrenia)
  evidence := []

/-- Run step H2.1: schizophrenia-associated CSMD1 variation lowers CSMD1 function. Sign: inverted: the run's object is reduced CSMD1 function. -/
def S7 : Statement where
  id := "S7"
  text := "schizophrenia-associated CSMD1 variation lowers CSMD1 function"
  claim := .effect csmd1RiskVariation .neg (.activity csmd1)
  evidence := []

/-- Run step H2.2: CSMD1 inhibits the classical complement pathway. -/
def S8 : Statement where
  id := "S8"
  text := "CSMD1 inhibits the classical complement pathway"
  claim := .effect csmd1 .neg (.process classicalComplement)
  evidence := [
    { pmid := 40112933, year := 2025, kind := .inVitro, note := "CSMD1 encodes a complement classical pathway inhibitor" }
  ]

/-- Run step H3.2: CX3CR1 is required for synapse maturation (losing CX3CR1 lowers it). -/
def S9 : Statement where
  id := "S9"
  text := "CX3CR1 is required for synapse maturation (losing CX3CR1 lowers it)"
  claim := .effect cx3cr1 .pos (.process synapseMaturation)
  evidence := []

/-- Run step H3.2: CX3CR1 is required for normal microglial physiology (losing CX3CR1 gives abnormal microglial physiology). Sign: the run's 'required for normal microglial physiology' written as CX3CR1 lowering the 'abnormal microglial cell physiology' phenotype; same claim, not a sign change. -/
def S10 : Statement where
  id := "S10"
  text := "CX3CR1 is required for normal microglial physiology (losing CX3CR1 gives abnormal microglial physiology)"
  claim := .effect cx3cr1 .neg (.phenotype abnormalMicrogliaPhysiology)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1333815:MP:0003691", kind := .curatedDb, note := "Cx3cr1 -- the orthologue of human CX3CR1 -- shows abnormal microglial cell physiology", taxon := some Taxa.mouse },
    { pmid := 0, year := 2026, ref := "P49238", kind := .crossSpecies, note := "Required to restrain the microglial inflammatory response in the CNS" }
  ]

/-- Run step H4.1: NXPH3 binds neurexin-1-alpha. -/
def S11 : Statement where
  id := "S11"
  text := "NXPH3 binds neurexin-1-alpha"
  claim := .rel ⟨.ro, 2436, false⟩ nxph3 nrxn1
  evidence := [
    { pmid := 0, year := 2026, ref := "O95157", kind := .crossSpecies, note := "Ligand for alpha-neurexins (By similarity)" }
  ]

/-- Run step H4.1: NXPH3 binds neurexin-2-alpha. -/
def S12 : Statement where
  id := "S12"
  text := "NXPH3 binds neurexin-2-alpha"
  claim := .rel ⟨.ro, 2436, false⟩ nxph3 nrxn2
  evidence := [
    { pmid := 0, year := 2026, ref := "O95157", kind := .crossSpecies, note := "Ligand for alpha-neurexins (By similarity)" }
  ]

/-- Run step H4.1: NXPH3 binds neurexin-3-alpha. -/
def S13 : Statement where
  id := "S13"
  text := "NXPH3 binds neurexin-3-alpha"
  claim := .rel ⟨.ro, 2436, false⟩ nxph3 nrxn3
  evidence := [
    { pmid := 0, year := 2026, ref := "O95157", kind := .crossSpecies, note := "Ligand for alpha-neurexins (By similarity)" }
  ]

/-- Run step H4.2: losing NXPH3 gives abnormal spatial learning. Sign: inverted: the run's subject is loss of NXPH3 signaling. -/
def S14 : Statement where
  id := "S14"
  text := "losing NXPH3 gives abnormal spatial learning"
  claim := .effect nxph3 .neg (.phenotype abnormalSpatialLearning)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1336188:MP:0001463", kind := .curatedDb, note := "Nxph3 -- the orthologue of human NXPH3 -- shows abnormal spatial learning", taxon := some Taxa.mouse }
  ]

/-- Run step H4.2: losing NXPH3 gives an abnormal startle reflex. Sign: inverted: the run's subject is loss of NXPH3 signaling. -/
def S15 : Statement where
  id := "S15"
  text := "losing NXPH3 gives an abnormal startle reflex"
  claim := .effect nxph3 .neg (.phenotype abnormalStartleReflex)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1336188:MP:0001488", kind := .curatedDb, note := "Nxph3 -- the orthologue of human NXPH3 -- shows increased startle reflex", taxon := some Taxa.mouse }
  ]

/-- Run step H4.3: synaptic circuit dysfunction leads to cognitive impairment. -/
def S16 : Statement where
  id := "S16"
  text := "synaptic circuit dysfunction leads to cognitive impairment"
  claim := .effect abnormalSynapticTransmission .pos (.phenotype cognitiveImpairment)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16]

/-- H1, claim 1: Increased C4A/C4B dosage drives excessive complement-dependent synapse elimination. -/
def h1c1a1 := viaAmount (lit S1) (viaProcess (lit S4) (lit S6))

/-- H1, claim 1: Increased C4A/C4B dosage drives excessive complement-dependent synapse elimination. -/
def h1c1a2 := viaAmount (lit S2) (viaProcess (lit S5) (lit S6))

/-- H1, claim 2: Increased C4A/C4B dosage drives excessive complement-dependent synapse elimination. -/
def h1c2a1 := viaProcess (lit S3) (lit S6)

/-- H3, claim 1: Low C1QA or impaired CX3CR1 signaling causes mistimed, incomplete microglial circuit maturation. -/
def h3c1a1 := viaProcess (lit S3) (lit S6)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H1" "c1a2" h1c1a2,
    arm "H1" "c2a1" h1c2a1,
    arm "H3" "c1a1" h3c1a1]

#eval printRows "20260825T000740Z-8a3e43" rows

end BioLean.Lib.IPF.Runs.R20260825T000740Z_8a3e43
