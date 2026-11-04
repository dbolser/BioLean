import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260825T112130Z-0df74a/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260825T112130Z-0df74a`: openai:gpt-5.6-sol, Alzheimer's disease, genes TREM2, RNPS1, INPP5D, APOE, MS4A4A, LPIN2, PLCG2, ABI3. -/

namespace BioLean.Lib.IPF.Runs.R20260825T112130Z_0df74a

open BioLean BioLean.Lib.IPF Derivation

def AD : Entity .disease := ⟨"MONDO:0004975", "Alzheimer disease"⟩
def APOE : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def apoe4 : Entity .variant := ⟨"BLN:APOE-e4", "APOE e4 allele (encodes the APOE4 isoform)"⟩
def TREM2 : Entity .protein := ⟨"UniProt:Q9NZC2", "TREM2"⟩
def PLCG2 : Entity .protein := ⟨"UniProt:P16885", "PLCG2"⟩
def INPP5D : Entity .protein := ⟨"UniProt:Q92835", "INPP5D"⟩
def MS4A4A : Entity .protein := ⟨"UniProt:Q96JQ5", "MS4A4A"⟩
def ABI3 : Entity .protein := ⟨"UniProt:Q9P2A4", "ABI3"⟩
def LPIN2 : Entity .protein := ⟨"UniProt:Q92539", "LPIN2"⟩
def abClearanceCatabolic : Entity .process := ⟨"GO:0150094", "amyloid-beta clearance by cellular catabolic process"⟩
def abClearance : Entity .process := ⟨"GO:0097242", "amyloid-beta clearance"⟩
def dag : Entity .chemical := ⟨"CHEBI:18035", "diglyceride"⟩
def erMembrane : Entity .component := ⟨"GO:0005789", "endoplasmic reticulum membrane"⟩
def ip3 : Entity .chemical := ⟨"CHEBI:16595", "1D-myo-inositol 1,4,5-trisphosphate"⟩
def pi3kSignaling : Entity .process := ⟨"GO:0043491", "phosphatidylinositol 3-kinase/protein kinase B signal transduction"⟩
def microglia : Entity .cellType := ⟨"CL:0000129", "microglial cell"⟩
def cellChemotaxis : Entity .process := ⟨"GO:0060326", "cell chemotaxis"⟩
def endocytosis : Entity .process := ⟨"GO:0006897", "endocytosis"⟩
def microgliaActivation : Entity .process := ⟨"GO:0001774", "microglial cell activation"⟩
def cytoskeletonOrg : Entity .process := ⟨"GO:0007010", "cytoskeleton organization"⟩
def plaqueEncasement : Entity .process := ⟨"BLN:MicroglialPlaqueEncasement", "microglial encasement of amyloid plaques"⟩
def plaqueCompaction : Entity .process := ⟨"BLN:AmyloidPlaqueCompaction", "amyloid plaque compaction"⟩
def phospholipidMetabolism : Entity .process := ⟨"GO:0006644", "phospholipid metabolic process"⟩
def dagER : Entity .chemical := dag.inCtx { component := erMembrane }
def microgliaChemotaxis : Entity .process := cellChemotaxis.inCtx { cellType := microglia }
def microgliaEndocytosis : Entity .process := endocytosis.inCtx { cellType := microglia }

/-- Run step H1.1: APOE (in lipoproteins) binds TREM2. -/
def S1 : Statement where
  id := "S1"
  text := "APOE (in lipoproteins) binds TREM2"
  claim := .rel ⟨.ro, 2436, false⟩ APOE TREM2
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9NZC2", kind := .curatedDb, note := "Acts as a receptor for lipoprotein particles such as LDL, VLDL, and HDL and for apolipoproteins such as APOA1, APOA2, APOB, APOE, APOE2, APOE3, APOE4, and CLU" },
    { pmid := 0, year := 2026, ref := "STRING:APOE-TREM2", kind := .curatedDb, note := "STRING links APOE and TREM2 with combined score 1.00 (experimental 0.58, database 0.00, text-mining 0.99)" }
  ]

/-- Run step H1.2: TREM2 is required for microglial uptake and degradation of Abeta42 (losing TREM2 lowers it). -/
def S2 : Statement where
  id := "S2"
  text := "TREM2 is required for microglial uptake and degradation of Abeta42 (losing TREM2 lowers it)"
  claim := .effect TREM2 .pos (.process abClearanceCatabolic)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9NZC2", kind := .curatedDb, note := "Acts as a receptor for amyloid-beta protein 42, a cleavage product of the amyloid-beta precursor protein APP, and mediates its uptake and degradation by microglia" }
  ]

/-- Run step H1.3: the APOE e4 allele lowers productive (TREM2-dependent) Abeta clearance. -/
def S3 : Statement where
  id := "S3"
  text := "the APOE e4 allele lowers productive (TREM2-dependent) Abeta clearance"
  claim := .effect apoe4 .neg (.process abClearanceCatabolic)
  evidence := []

/-- Run step H1.4: productive Abeta clearance lowers Alzheimer's disease risk. Sign: inverted: the run's subject is 'reduced productive amyloid clearance' (+). -/
def S4 : Statement where
  id := "S4"
  text := "productive Abeta clearance lowers Alzheimer's disease risk"
  claim := .effect abClearanceCatabolic .neg (.disease AD)
  evidence := []

/-- Run step H2.1: TREM2 (with its adaptor DAP12) activates PLCG2. -/
def S5 : Statement where
  id := "S5"
  text := "TREM2 (with its adaptor DAP12) activates PLCG2"
  claim := .effect TREM2 .pos (.activity PLCG2)
  evidence := []

/-- Run step H2.2: PLCG2 raises DAG. -/
def S6 : Statement where
  id := "S6"
  text := "PLCG2 raises DAG"
  claim := .effect PLCG2 .pos (.amount dag)
  evidence := [
    { pmid := 0, year := 2026, ref := "P16885", kind := .curatedDb, note := "The production of the second messenger molecules diacylglycerol (DAG) and inositol 1,4,5-trisphosphate (IP3) is mediated by activated phosphatidylinositol-specific phospholipase C enzymes" }
  ]

/-- Run step H2.2: PLCG2 raises IP3. -/
def S7 : Statement where
  id := "S7"
  text := "PLCG2 raises IP3"
  claim := .effect PLCG2 .pos (.amount ip3)
  evidence := [
    { pmid := 0, year := 2026, ref := "P16885", kind := .curatedDb, note := "The production of the second messenger molecules diacylglycerol (DAG) and inositol 1,4,5-trisphosphate (IP3) is mediated by activated phosphatidylinositol-specific phospholipase C enzymes" }
  ]

/-- Run step H2.3: INPP5D inhibits PI3K signaling. -/
def S8 : Statement where
  id := "S8"
  text := "INPP5D inhibits PI3K signaling"
  claim := .effect INPP5D .neg (.process pi3kSignaling)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q92835", kind := .curatedDb, note := "hydrolyzes the 5-phosphate of phosphatidylinositol-3,4,5-trisphosphate (PtdIns(3,4,5)P3) to produce PtdIns(3,4)P2, thereby negatively regulating the PI3K (phosphoinositide 3-kinase) pathways" }
  ]

/-- Run step H2.4: PLCG2 activation is required for microglial chemotaxis. -/
def S9 : Statement where
  id := "S9"
  text := "PLCG2 activation is required for microglial chemotaxis"
  claim := .effect PLCG2 .pos (.process microgliaChemotaxis)
  evidence := []

/-- Run step H2.4: PLCG2 activation is required for microglial endocytosis. -/
def S10 : Statement where
  id := "S10"
  text := "PLCG2 activation is required for microglial endocytosis"
  claim := .effect PLCG2 .pos (.process microgliaEndocytosis)
  evidence := []

/-- Run step H2.4: INPP5D lowers microglial chemotaxis. Sign: inverted: the run's subject is 'INPP5D inhibition' (required for, +), read as inhibition of INPP5D, as the mechanism ('excessive INPP5D braking reduces ... chemotaxis, endocytosis') and the falsification test (INPP5D inhibition improves Abe. -/
def S11 : Statement where
  id := "S11"
  text := "INPP5D lowers microglial chemotaxis"
  claim := .effect INPP5D .neg (.process microgliaChemotaxis)
  evidence := []

/-- Run step H2.4: INPP5D lowers microglial endocytosis. Sign: inverted: the run's subject is 'INPP5D inhibition' (required for, +), read as inhibition of INPP5D, as in the mechanism. -/
def S12 : Statement where
  id := "S12"
  text := "INPP5D lowers microglial endocytosis"
  claim := .effect INPP5D .neg (.process microgliaEndocytosis)
  evidence := []

/-- Run step H2.5: microglial chemotaxis lowers Alzheimer's disease risk. Sign: inverted: the run's subject is 'deficient microglial chemotaxis and endocytosis' (+). -/
def S13 : Statement where
  id := "S13"
  text := "microglial chemotaxis lowers Alzheimer's disease risk"
  claim := .effect microgliaChemotaxis .neg (.disease AD)
  evidence := []

/-- Run step H2.5: microglial endocytosis lowers Alzheimer's disease risk. Sign: inverted: the run's subject is 'deficient microglial chemotaxis and endocytosis' (+). -/
def S14 : Statement where
  id := "S14"
  text := "microglial endocytosis lowers Alzheimer's disease risk"
  claim := .effect microgliaEndocytosis .neg (.disease AD)
  evidence := []

/-- Run step H3.1: MS4A4A raises functional TREM2. -/
def S15 : Statement where
  id := "S15"
  text := "MS4A4A raises functional TREM2"
  claim := .effect MS4A4A .pos (.amount TREM2)
  evidence := [
    { pmid := 0, year := 2026, ref := "PMID:PMC12738020", kind := .inVitro, note := "Microglial MS4A4A elevates TREM2 signaling" },
    { pmid := 41435829, year := 2026, kind := .mechanistic, polarity := .refutes, note := "MS4A4A and MS4A6A are negative regulators of both the transmembrane and soluble TREM2 proteins", taxon := some Taxa.mouse }
  ]

/-- Run step H3.2: TREM2 activates the microglial (plaque) response. -/
def S16 : Statement where
  id := "S16"
  text := "TREM2 activates the microglial (plaque) response"
  claim := .effect TREM2 .pos (.process microgliaActivation)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9NZC2", kind := .crossSpecies, note := "Binding to amyloid-beta 42 mediates microglial activation" },
    { pmid := 28602351, year := 2017, kind := .mechanistic, note := "Activation is initiated in a Trem2-independent manner that involves downregulation of microglia checkpoints, followed by activation of a Trem2-dependent program", taxon := some Taxa.mouse }
  ]

/-- Run step H3.3: the protective microglial plaque response lowers Alzheimer's disease pathology. -/
def S17 : Statement where
  id := "S17"
  text := "the protective microglial plaque response lowers Alzheimer's disease pathology"
  claim := .effect microgliaActivation .neg (.disease AD .severity)
  evidence := [
    { pmid := 28602351, year := 2017, kind := .hypothesis, note := "This unique microglia-type has the potential to restrict neurodegeneration" }
  ]

/-- Run step H4.1: TREM2 signaling activates (ABI3-dependent) cytoskeletal remodeling. -/
def S18 : Statement where
  id := "S18"
  text := "TREM2 signaling activates (ABI3-dependent) cytoskeletal remodeling"
  claim := .effect TREM2 .pos (.process cytoskeletonOrg)
  evidence := []

/-- Run step H4.1: PLCG2 signaling activates (ABI3-dependent) cytoskeletal remodeling. -/
def S19 : Statement where
  id := "S19"
  text := "PLCG2 signaling activates (ABI3-dependent) cytoskeletal remodeling"
  claim := .effect PLCG2 .pos (.process cytoskeletonOrg)
  evidence := []

/-- Run step H4.2: cytoskeletal remodeling is required for microglial plaque encasement. -/
def S20 : Statement where
  id := "S20"
  text := "cytoskeletal remodeling is required for microglial plaque encasement"
  claim := .effect cytoskeletonOrg .pos (.process plaqueEncasement)
  evidence := []

/-- Run step H4.2: cytoskeletal remodeling is required for plaque compaction. -/
def S21 : Statement where
  id := "S21"
  text := "cytoskeletal remodeling is required for plaque compaction"
  claim := .effect cytoskeletonOrg .pos (.process plaqueCompaction)
  evidence := []

/-- Run step H4.3: microglial plaque encasement lowers Alzheimer's disease pathology. Sign: inverted: the run's subject is 'loss of plaque encasement and compaction' (+). -/
def S22 : Statement where
  id := "S22"
  text := "microglial plaque encasement lowers Alzheimer's disease pathology"
  claim := .effect plaqueEncasement .neg (.disease AD .severity)
  evidence := []

/-- Run step H4.3: plaque compaction lowers Alzheimer's disease pathology. Sign: inverted: the run's subject is 'loss of plaque encasement and compaction' (+). -/
def S23 : Statement where
  id := "S23"
  text := "plaque compaction lowers Alzheimer's disease pathology"
  claim := .effect plaqueCompaction .neg (.disease AD .severity)
  evidence := []

/-- Run step H5.1: LPIN2 raises biosynthetic DAG (DAG in the ER membrane, kept apart from PLCG2's signalling DAG as the run's H5.2 note asks). -/
def S24 : Statement where
  id := "S24"
  text := "LPIN2 raises biosynthetic DAG (DAG in the ER membrane, kept apart from PLCG2's signalling DAG as the run's H5.2 note asks)"
  claim := .effect LPIN2 .pos (.amount dagER)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q92539", kind := .crossSpecies, note := "catalyzes the conversion of phosphatidic acid to diacylglycerol during triglyceride, phosphatidylcholine and phosphatidylethanolamine biosynthesis in the endoplasmic reticulum membrane" }
  ]

/-- Run step H5.2: LPIN2-dependent phospholipid remodeling is required for the sustained TREM2 response. -/
def S25 : Statement where
  id := "S25"
  text := "LPIN2-dependent phospholipid remodeling is required for the sustained TREM2 response"
  claim := .effect phospholipidMetabolism .pos (.activity TREM2)
  evidence := []

/-- Run step H5.2: LPIN2-dependent phospholipid remodeling is required for the sustained PLCG2 response. -/
def S26 : Statement where
  id := "S26"
  text := "LPIN2-dependent phospholipid remodeling is required for the sustained PLCG2 response"
  claim := .effect phospholipidMetabolism .pos (.activity PLCG2)
  evidence := []

/-- Run step H5.3: sustained microglial lipid remodeling supports Abeta clearance. Sign: inverted: the run's subject is 'failure of sustained microglial lipid remodeling' (-). -/
def S27 : Statement where
  id := "S27"
  text := "sustained microglial lipid remodeling supports Abeta clearance"
  claim := .effect phospholipidMetabolism .pos (.process abClearance)
  evidence := []

/-- Bridge, not in the run: LPIN2 drives phospholipid metabolism (the run's 'LPIN2-dependent' qualifier, stated by its cited UniProt text). -/
def B1 : Statement where
  id := "B1"
  text := "LPIN2 drives phospholipid metabolism (the run's 'LPIN2-dependent' qualifier, stated by its cited UniProt text)"
  claim := .effect LPIN2 .pos (.process phospholipidMetabolism)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q92539", kind := .crossSpecies, note := "catalyzes the conversion of phosphatidic acid to diacylglycerol during triglyceride, phosphatidylcholine and phosphatidylethanolamine biosynthesis" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20, S21, S22, S23, S24, S25, S26, S27, B1]

/-- H1, claim 1: APOE4 makes TREM2-mediated lipid and amyloid handling less productive. -/
def h1c1a1 := viaProcess (lit S3) (lit S4)

/-- H1, claim 2: APOE4 makes TREM2-mediated lipid and amyloid handling less productive. -/
def h1c2a1 := viaProcess (lit S2) (lit S4)

/-- H1, claim 2: APOE4 makes TREM2-mediated lipid and amyloid handling less productive. -/
def h1c2a2 := viaActivity (lit S5) (viaProcess (lit S9) (lit S13))

/-- H1, claim 2: APOE4 makes TREM2-mediated lipid and amyloid handling less productive. -/
def h1c2a3 := viaActivity (lit S5) (viaProcess (lit S10) (lit S14))

/-- H2, claim 1: PLCG2 and INPP5D set the gain of protective TREM2–DAP12 microglial signaling. -/
def h2c1a1 := viaProcess (lit S2) (lit S4)

/-- H2, claim 1: PLCG2 and INPP5D set the gain of protective TREM2–DAP12 microglial signaling. -/
def h2c1a2 := viaActivity (lit S5) (viaProcess (lit S9) (lit S13))

/-- H2, claim 1: PLCG2 and INPP5D set the gain of protective TREM2–DAP12 microglial signaling. -/
def h2c1a3 := viaActivity (lit S5) (viaProcess (lit S10) (lit S14))

/-- H2, claim 2: PLCG2 and INPP5D set the gain of protective TREM2–DAP12 microglial signaling. -/
def h2c2a1 := viaProcess (lit S9) (lit S13)

/-- H2, claim 2: PLCG2 and INPP5D set the gain of protective TREM2–DAP12 microglial signaling. -/
def h2c2a2 := viaProcess (lit S10) (lit S14)

/-- H2, claim 3: PLCG2 and INPP5D set the gain of protective TREM2–DAP12 microglial signaling. -/
def h2c3a1 := viaProcess (lit S11) (lit S13)

/-- H2, claim 3: PLCG2 and INPP5D set the gain of protective TREM2–DAP12 microglial signaling. -/
def h2c3a2 := viaProcess (lit S12) (lit S14)

/-- H3, claim 1: MS4A4A controls the availability of a protective TREM2 microglial state. -/
def h3c1a1 := viaAmount (lit S15) (viaActivity (lit S5) (viaProcess (lit S19) (viaProcess (lit S20) (lit S22))))

/-- H3, claim 1: MS4A4A controls the availability of a protective TREM2 microglial state. -/
def h3c1a2 := viaAmount (lit S15) (viaActivity (lit S5) (viaProcess (lit S19) (viaProcess (lit S21) (lit S23))))

/-- H3, claim 1: MS4A4A controls the availability of a protective TREM2 microglial state. -/
def h3c1a3 := viaAmount (lit S15) (viaProcess (lit S16) (lit S17))

/-- H3, claim 1: MS4A4A controls the availability of a protective TREM2 microglial state. -/
def h3c1a4 := viaAmount (lit S15) (viaProcess (lit S18) (viaProcess (lit S20) (lit S22)))

/-- H3, claim 1: MS4A4A controls the availability of a protective TREM2 microglial state. -/
def h3c1a5 := viaAmount (lit S15) (viaProcess (lit S18) (viaProcess (lit S21) (lit S23)))

/-- H3, claim 2: MS4A4A controls the availability of a protective TREM2 microglial state. -/
def h3c2a1 := viaActivity (lit S5) (viaProcess (lit S19) (viaProcess (lit S20) (lit S22)))

/-- H3, claim 2: MS4A4A controls the availability of a protective TREM2 microglial state. -/
def h3c2a2 := viaActivity (lit S5) (viaProcess (lit S19) (viaProcess (lit S21) (lit S23)))

/-- H3, claim 2: MS4A4A controls the availability of a protective TREM2 microglial state. -/
def h3c2a3 := viaProcess (lit S16) (lit S17)

/-- H3, claim 2: MS4A4A controls the availability of a protective TREM2 microglial state. -/
def h3c2a4 := viaProcess (lit S18) (viaProcess (lit S20) (lit S22))

/-- H3, claim 2: MS4A4A controls the availability of a protective TREM2 microglial state. -/
def h3c2a5 := viaProcess (lit S18) (viaProcess (lit S21) (lit S23))

/-- H5, claim 1: LPIN2 is a non-genetic lipid-metabolic modifier of microglial TREM2–PLCG2 responses. -/
def h5c1a1 := viaProcess (lit B1) (lit S27)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H1" "c2a1" h1c2a1,
    arm "H1" "c2a2" h1c2a2,
    arm "H1" "c2a3" h1c2a3,
    arm "H2" "c1a1" h2c1a1,
    arm "H2" "c1a2" h2c1a2,
    arm "H2" "c1a3" h2c1a3,
    arm "H2" "c2a1" h2c2a1,
    arm "H2" "c2a2" h2c2a2,
    arm "H2" "c3a1" h2c3a1,
    arm "H2" "c3a2" h2c3a2,
    arm "H3" "c1a1" h3c1a1,
    arm "H3" "c1a2" h3c1a2,
    arm "H3" "c1a3" h3c1a3,
    arm "H3" "c1a4" h3c1a4,
    arm "H3" "c1a5" h3c1a5,
    arm "H3" "c2a1" h3c2a1,
    arm "H3" "c2a2" h3c2a2,
    arm "H3" "c2a3" h3c2a3,
    arm "H3" "c2a4" h3c2a4,
    arm "H3" "c2a5" h3c2a5,
    arm "H5" "c1a1" h5c1a1]

#eval printRows "20260825T112130Z-0df74a" rows

end BioLean.Lib.IPF.Runs.R20260825T112130Z_0df74a
