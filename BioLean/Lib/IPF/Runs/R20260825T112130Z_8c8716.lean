import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260825T112130Z-8c8716/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260825T112130Z-8c8716`: openai:gpt-5.6-sol, schizophrenia, genes CSMD1, NXPH3, C4A, CX3CR1, CCDC136, C1QA, C4B. -/

namespace BioLean.Lib.IPF.Runs.R20260825T112130Z_8c8716

open BioLean BioLean.Lib.IPF Derivation

def schizophrenia : Entity .disease := ⟨"MONDO:0005090", "schizophrenia"⟩
def C4A : Entity .protein := ⟨"UniProt:P0C0L4", "C4A"⟩
def C4B : Entity .protein := ⟨"UniProt:P0C0L5", "C4B"⟩
def C1QA : Entity .protein := ⟨"UniProt:P02745", "C1QA"⟩
def CX3CR1 : Entity .protein := ⟨"UniProt:P49238", "CX3CR1"⟩
def CSMD1 : Entity .protein := ⟨"UniProt:Q96PZ7", "CSMD1"⟩
def NXPH3 : Entity .protein := ⟨"UniProt:O95157", "NXPH3"⟩
def alphaNeurexins : Entity .protein := ⟨"BLN:AlphaNeurexins", "alpha-neurexins (the alpha isoforms of the neurexin family)"⟩
def classicalComplement : Entity .process := ⟨"GO:0006958", "complement activation, classical pathway"⟩
def synapsePruning : Entity .process := ⟨"GO:0098883", "synapse pruning"⟩
def synapseMaturation : Entity .process := ⟨"GO:0060074", "synapse maturation"⟩
def opsonization : Entity .process := ⟨"GO:0008228", "opsonization"⟩
def synapse : Entity .component := ⟨"GO:0045202", "synapse"⟩
def abnormalSpatialLearning : Entity .phenotype := ⟨"MP:0001463", "abnormal spatial learning"⟩
def abnormalLocomotorBehavior : Entity .phenotype := ⟨"MP:0001392", "abnormal locomotor behavior"⟩
def abnormalSensorimotorGating : Entity .phenotype := ⟨"MP:0002634", "abnormal sensorimotor gating"⟩
def synapticOpsonization : Entity .process := opsonization.inCtx { component := synapse }

/-- Run step H1.1: C4A goes with higher schizophrenia risk: C4 alleles that make more C4A carry more risk. Sign: H1.1 is associated_with with polarity unknown; the direction is from PMID:26814963, cited for the step, which reports each common C4 allele associating with schizophrenia in proportion to the C4A expression it generates. -/
def H1_1 : Statement where
  id := "H1_1"
  text := "C4A goes with higher schizophrenia risk: C4 alleles that make more C4A carry more risk"
  claim := .assoc C4A (some .pos) (.disease schizophrenia)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .observational, note := "each common C4 allele associating with schizophrenia in proportion to its tendency to generate greater expression of C4A" }
  ]

/-- Run step H1.1: C4B is associated with schizophrenia risk, direction not stated (the C4B half of the C4A/C4B locus). Sign: unsigned: H1.1 has polarity unknown, and PMID:26814963 ties the direction to C4A expression only; no cited text gives C4B a direction. -/
def H1_1b : Statement where
  id := "H1_1b"
  text := "C4B is associated with schizophrenia risk, direction not stated (the C4B half of the C4A/C4B locus)"
  claim := .assoc C4B none (.disease schizophrenia)
  evidence := [
    { pmid := 26814963, year := 2016, kind := .observational, note := "Schizophrenia risk from complex variation of complement component 4" }
  ]

/-- Run step H1.2: C1QA activates the classical complement pathway. -/
def H1_2a : Statement where
  id := "H1_2a"
  text := "C1QA activates the classical complement pathway"
  claim := .effect C1QA .pos (.process classicalComplement)
  evidence := [
    { pmid := 0, year := 2026, ref := "P02745", kind := .curatedDb, note := "Core component of the complement C1 complex, a multiprotein complex that initiates the classical pathway of the complement system" }
  ]

/-- Run step H1.2: C4A activates the classical complement pathway (it is one of its components). -/
def H1_2b : Statement where
  id := "H1_2b"
  text := "C4A activates the classical complement pathway (it is one of its components)"
  claim := .effect C4A .pos (.process classicalComplement)
  evidence := [
    { pmid := 0, year := 2026, ref := "P0C0L4", kind := .curatedDb, note := "Precursor of non-enzymatic components of the classical, lectin and GZMK complement pathways" }
  ]

/-- Run step H1.2: C4B activates the classical complement pathway (it is one of its components). -/
def H1_2c : Statement where
  id := "H1_2c"
  text := "C4B activates the classical complement pathway (it is one of its components)"
  claim := .effect C4B .pos (.process classicalComplement)
  evidence := [
    { pmid := 0, year := 2026, ref := "P0C0L5", kind := .curatedDb, note := "Precursor of non-enzymatic components of the classical, lectin and GZMK complement pathways" }
  ]

/-- Run step H1.3: the classical complement pathway drives synapse pruning. -/
def H1_3 : Statement where
  id := "H1_3"
  text := "the classical complement pathway drives synapse pruning"
  claim := .effect classicalComplement .pos (.process synapsePruning)
  evidence := [
    { pmid := 38301948, year := 2024, kind := .review, note := "C4A is believed to contribute to physiological synapse removal through signaling within the C1q initiated classical activation axis of the complement system" }
  ]

/-- Run step H1.4: CX3CR1 is required for synapse pruning (losing CX3CR1 lowers pruning). -/
def H1_4a : Statement where
  id := "H1_4a"
  text := "CX3CR1 is required for synapse pruning (losing CX3CR1 lowers pruning)"
  claim := .effect CX3CR1 .pos (.process synapsePruning)
  evidence := [
    { pmid := 0, year := 2026, ref := "P49238", kind := .crossSpecies, note := "Involved in brain development by participating in synaptic pruning" }
  ]

/-- Run step H1.4: CX3CR1 is required for synapse maturation (losing CX3CR1 lowers maturation). -/
def H1_4b : Statement where
  id := "H1_4b"
  text := "CX3CR1 is required for synapse maturation (losing CX3CR1 lowers maturation)"
  claim := .effect CX3CR1 .pos (.process synapseMaturation)
  evidence := []

/-- Run step H2.1: CSMD1 is associated with schizophrenia risk, direction not stated. Sign: unsigned: H2.1 has polarity unknown; both GWAS Catalog rows report the risk allele as '?', the Open Targets score is unsigned, and no other cited text gives CSMD1 a direction. -/
def H2_1 : Statement where
  id := "H2_1"
  text := "CSMD1 is associated with schizophrenia risk, direction not stated"
  claim := .assoc CSMD1 none (.disease schizophrenia)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs6986895", kind := .observational, note := "rs6986895-? is associated with 'Schizophrenia' at p = 6e-10, odds ratio 1.0590752 [1.04-1.08] (mapped gene CSMD1" },
    { pmid := 0, year := 2026, ref := "rs10098869", kind := .observational, note := "rs10098869-? is associated with 'Schizophrenia' at p = 2e-10, no effect size reported (mapped gene CSMD1" },
    { pmid := 0, year := 2026, ref := "OT:CSMD1-MONDO_0005090", kind := .curatedDb, note := "Open Targets 2026.06 scores the CSMD1-schizophrenia association at 0.51 (literature 0.41, animal_model 0.29, genetic_association 0.81)" },
    { pmid := 40112933, year := 2025, kind := .review, note := "CUB and sushi multiple domains 1 (CSMD1) is predominantly expressed in brain and robustly associated with schizophrenia risk" },
    { pmid := 0, year := 2026, ref := "PMID:PPR1218914", kind := .review, note := "Genome-wide association studies have identified CSMD1 as a major schizophrenia risk gene, an association robustly replicated across populations of diverse ancestries" }
  ]

/-- Run step H2.2: CSMD1 inhibits the classical complement pathway. -/
def H2_2 : Statement where
  id := "H2_2"
  text := "CSMD1 inhibits the classical complement pathway"
  claim := .effect CSMD1 .neg (.process classicalComplement)
  evidence := [
    { pmid := 40112933, year := 2025, kind := .inVitro, note := "CSMD1 encodes a complement classical pathway inhibitor" }
  ]

/-- Run step H2.3: CSMD1 restrains synaptic opsonization (reduced CSMD1 function increases C1q/C4 opsonization of synapses). Sign: inverted: the run's subject is 'reduced CSMD1 function' (polarity positive to 'increased C1q/C4 synaptic opsonization'), so CSMD1 lowers synaptic opsonization, the same direction as H2.2's 'inhibits'. -/
def H2_3 : Statement where
  id := "H2_3"
  text := "CSMD1 restrains synaptic opsonization (reduced CSMD1 function increases C1q/C4 opsonization of synapses)"
  claim := .effect CSMD1 .neg (.process synapticOpsonization)
  evidence := []

/-- Run step H2.4: C1q/C4 opsonization of synapses drives synapse elimination. -/
def H2_4 : Statement where
  id := "H2_4"
  text := "C1q/C4 opsonization of synapses drives synapse elimination"
  claim := .effect synapticOpsonization .pos (.process synapsePruning)
  evidence := []

/-- Run step H2.5: excessive synapse elimination raises schizophrenia risk. -/
def H2_5 : Statement where
  id := "H2_5"
  text := "excessive synapse elimination raises schizophrenia risk"
  claim := .effect synapsePruning .pos (.disease schizophrenia)
  evidence := []

/-- Run step H3.1: NXPH3 binds the alpha-neurexins. -/
def H3_1 : Statement where
  id := "H3_1"
  text := "NXPH3 binds the alpha-neurexins"
  claim := .rel ⟨.ro, 2436, false⟩ NXPH3 alphaNeurexins
  evidence := [
    { pmid := 0, year := 2026, ref := "O95157", kind := .crossSpecies, note := "Ligand for alpha-neurexins (By similarity)" }
  ]

/-- Run step H3.3: NXPH3 protects against abnormal spatial learning (loss of NXPH3 function leads to it). Sign: inverted: the run's subject is 'loss of NXPH3 function'; 'abnormal learning' is grounded as the MP phenotype abnormal spatial learning, the only learning phenotype any citation reports. -/
def H3_3a : Statement where
  id := "H3_3a"
  text := "NXPH3 protects against abnormal spatial learning (loss of NXPH3 function leads to it)"
  claim := .effect NXPH3 .neg (.phenotype abnormalSpatialLearning)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1336188:MP:0001463", kind := .curatedDb, note := "Nxph3<tm1.1Mami>/Nxph3<tm1.1Mami> of Nxph3 -- the orthologue of human NXPH3 -- shows abnormal spatial learning", taxon := some Taxa.mouse },
    { pmid := 0, year := 2026, ref := "AGR:MGI:1336188:MP:0002169", kind := .curatedDb, polarity := .refutes, note := "Nxph3<tm1Mami>/Nxph3<tm1Mami> of Nxph3 -- the orthologue of human NXPH3 -- shows no abnormal phenotype detected", taxon := some Taxa.mouse }
  ]

/-- Run step H3.3: NXPH3 protects against abnormal locomotor behaviour (loss of NXPH3 function leads to it). Sign: inverted: the run's subject is 'loss of NXPH3 function'. -/
def H3_3b : Statement where
  id := "H3_3b"
  text := "NXPH3 protects against abnormal locomotor behaviour (loss of NXPH3 function leads to it)"
  claim := .effect NXPH3 .neg (.phenotype abnormalLocomotorBehavior)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1336188:MP:0001392", kind := .curatedDb, note := "Nxph3<tm1.1Mami>/Nxph3<tm1.1Mami> of Nxph3 -- the orthologue of human NXPH3 -- shows abnormal locomotor behavior", taxon := some Taxa.mouse },
    { pmid := 0, year := 2026, ref := "AGR:MGI:1336188:MP:0002169", kind := .curatedDb, polarity := .refutes, note := "Nxph3<tm1Mami>/Nxph3<tm1Mami> of Nxph3 -- the orthologue of human NXPH3 -- shows no abnormal phenotype detected", taxon := some Taxa.mouse }
  ]

/-- Run step H3.3: NXPH3 protects against abnormal sensorimotor gating (loss of NXPH3 function leads to it). Sign: inverted: the run's subject is 'loss of NXPH3 function'. -/
def H3_3c : Statement where
  id := "H3_3c"
  text := "NXPH3 protects against abnormal sensorimotor gating (loss of NXPH3 function leads to it)"
  claim := .effect NXPH3 .neg (.phenotype abnormalSensorimotorGating)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1336188:MP:0002169", kind := .curatedDb, polarity := .refutes, note := "Nxph3<tm1Mami>/Nxph3<tm1Mami> of Nxph3 -- the orthologue of human NXPH3 -- shows no abnormal phenotype detected", taxon := some Taxa.mouse }
  ]

def statements : List Statement := [H1_1, H1_1b, H1_2a, H1_2b, H1_2c, H1_3, H1_4a, H1_4b, H2_1, H2_2, H2_3, H2_4, H2_5, H3_1, H3_3a, H3_3b, H3_3c]

/-- H1, claim 1: C4A-biased classical complement tagging drives excessive microglial synapse pruning. -/
def h1c1a1 := fromAssoc (lit H1_1)

/-- H1, claim 1: C4A-biased classical complement tagging drives excessive microglial synapse pruning. -/
def h1c1a2 := viaProcess (lit H1_2b) (viaProcess (lit H1_3) (lit H2_5))

/-- H1, claim 2: C4A-biased classical complement tagging drives excessive microglial synapse pruning. -/
def h1c2a1 := viaProcess (lit H1_2b) (lit H1_3)

/-- H2, claim 1: Loss of synaptic CSMD1 complement restraint sensitizes neuronal synapses to C4-mediated elimination. -/
def h2c1a1 := viaProcess (lit H2_2) (viaProcess (lit H1_3) (lit H2_5))

/-- H2, claim 1: Loss of synaptic CSMD1 complement restraint sensitizes neuronal synapses to C4-mediated elimination. -/
def h2c1a2 := viaProcess (lit H2_3) (viaProcess (lit H2_4) (lit H2_5))

/-- H3, claim 2: NXPH3 deficiency disrupts α-neurexin-dependent synapse organization independently of complement. -/
def h3c2a1 := lit H3_3a

/-- H3, claim 3: NXPH3 deficiency disrupts α-neurexin-dependent synapse organization independently of complement. -/
def h3c3a1 := lit H3_3b

/-- H3, claim 4: NXPH3 deficiency disrupts α-neurexin-dependent synapse organization independently of complement. -/
def h3c4a1 := lit H3_3c

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H1" "c1a2" h1c1a2,
    arm "H1" "c2a1" h1c2a1,
    arm "H2" "c1a1" h2c1a1,
    arm "H2" "c1a2" h2c1a2,
    arm "H3" "c2a1" h3c2a1,
    arm "H3" "c3a1" h3c3a1,
    arm "H3" "c4a1" h3c4a1]

#eval printRows "20260825T112130Z-8c8716" rows

end BioLean.Lib.IPF.Runs.R20260825T112130Z_8c8716
