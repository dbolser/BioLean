import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260825T001904Z-300a86/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260825T001904Z-300a86`: anthropic:claude-opus-5, Alzheimer's disease, genes TREM2, RNPS1, INPP5D, APOE, MS4A4A, LPIN2, PLCG2, ABI3. -/

namespace BioLean.Lib.IPF.Runs.R20260825T001904Z_300a86

open BioLean BioLean.Lib.IPF Derivation

def APOE : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def TREM2 : Entity .protein := ⟨"UniProt:Q9NZC2", "TREM2"⟩
def dap12Signaling : Entity .process := ⟨"Reactome:R-HSA-2424491", "DAP12 signaling"⟩
def PLCG2 : Entity .protein := ⟨"UniProt:P16885", "PLCG2"⟩
def ip3 : Entity .chemical := ⟨"CHEBI:16595", "1D-myo-inositol 1,4,5-trisphosphate"⟩
def calciumIon : Entity .chemical := ⟨"CHEBI:29108", "calcium(2+)"⟩
def INPP5D : Entity .protein := ⟨"UniProt:Q92835", "INPP5D"⟩
def pi3kSignaling : Entity .process := ⟨"GO:0043491", "phosphatidylinositol 3-kinase/protein kinase B signal transduction"⟩
def abClearance : Entity .process := ⟨"GO:0097242", "amyloid-beta clearance"⟩
def plaqueCompaction : Entity .process := ⟨"BLN:AmyloidPlaqueCompaction", "amyloid plaque compaction"⟩
def ad : Entity .disease := ⟨"MONDO:0004975", "Alzheimer disease"⟩
def MS4A4A : Entity .protein := ⟨"UniProt:Q96JQ5", "MS4A4A"⟩
def rs1582763 : Entity .variant := ⟨"dbSNP:rs1582763", "rs1582763 A allele (MS4A4A/MS4A6A locus)"⟩
def ABI3 : Entity .protein := ⟨"UniProt:Q9P2A4", "ABI3"⟩
def cellMotility : Entity .process := ⟨"GO:0048870", "cell motility"⟩
def projectionAssembly : Entity .process := ⟨"GO:0120031", "plasma membrane bounded cell projection assembly"⟩
def plaqueEncapsulation : Entity .process := ⟨"BLN:MicroglialPlaqueEncapsulation", "microglial encapsulation of amyloid plaques (microglial plaque barrier)"⟩
def LPIN2 : Entity .protein := ⟨"UniProt:Q92539", "LPIN2"⟩
def phosphatidicAcid : Entity .chemical := ⟨"CHEBI:16337", "phosphatidic acid"⟩
def microglia : Entity .cellType := ⟨"CL:0000129", "microglial cell"⟩
def cholesterolTransport : Entity .process := ⟨"GO:0030301", "cholesterol transport"⟩
def lipidStress : Entity .process := ⟨"BLN:MicroglialLipidStress", "lipid stress in microglia"⟩
def RNPS1 : Entity .protein := ⟨"UniProt:Q15287", "RNPS1"⟩
def nmd : Entity .process := ⟨"GO:0000184", "nuclear-transcribed mRNA catabolic process, nonsense-mediated decay"⟩
def altSplicing : Entity .process := ⟨"GO:0000380", "alternative mRNA splicing, via spliceosome"⟩
def RIPK1 : Entity .protein := ⟨"UniProt:Q13546", "RIPK1"⟩
def inflammatoryMediators : Entity .process := ⟨"GO:0002532", "production of molecular mediator involved in inflammatory response"⟩
def rosiptor : Entity .chemical := ⟨"CHEBI:756440", "rosiptor"⟩

/-- Run step H1.1: APOE binds TREM2. -/
def S1 : Statement where
  id := "S1"
  text := "APOE binds TREM2"
  claim := .rel ⟨.ro, 2436, false⟩ APOE TREM2
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:APOE-TREM2", kind := .curatedDb, note := "STRING links APOE and TREM2 with combined score 1.00 (experimental 0.58, database 0.00, text-mining 0.99)" }
  ]

/-- Run step H1.2: TREM2 activates DAP12 signalling. -/
def S2 : Statement where
  id := "S2"
  text := "TREM2 activates DAP12 signalling"
  claim := .effect TREM2 .pos (.process dap12Signaling)
  evidence := [
    { pmid := 42602355, year := 2026, kind := .review, note := "It engages with adaptors like DAP12 and DAP10, activating key signaling pathways" }
  ]

/-- Run step H1.3: DAP12 signalling activates PLCG2. -/
def S3 : Statement where
  id := "S3"
  text := "DAP12 signalling activates PLCG2"
  claim := .effect dap12Signaling .pos (.activity PLCG2)
  evidence := [
    { pmid := 42602355, year := 2026, kind := .review, note := "engages with adaptors like DAP12 and DAP10, activating key signaling pathways, including SYK, PI3K-AKT-mTOR, and PLCγ2" }
  ]

/-- Run step H1.4: PLCG2 raises IP3. -/
def S4 : Statement where
  id := "S4"
  text := "PLCG2 raises IP3"
  claim := .effect PLCG2 .pos (.amount ip3)
  evidence := []

/-- Run step H1.4: PLCG2 raises Ca2+. -/
def S5 : Statement where
  id := "S5"
  text := "PLCG2 raises Ca2+"
  claim := .effect PLCG2 .pos (.amount calciumIon)
  evidence := []

/-- Run step H1.5: INPP5D inhibits PI3K/PIP3 signalling. -/
def S6 : Statement where
  id := "S6"
  text := "INPP5D inhibits PI3K/PIP3 signalling"
  claim := .effect INPP5D .neg (.process pi3kSignaling)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:INPP5D-tractability", kind := .curatedDb, note := "hydrolyzes the 5-phosphate of phosphatidylinositol-3,4,5-trisphosphate (PtdIns(3,4,5)P3) to produce PtdIns(3,4)P2, thereby negatively regulating the PI3K (phosphoinositide 3-kinase) pathways" }
  ]

/-- Run step H1.6: microglial plaque (amyloid-beta) clearance lowers AD risk. -/
def S7 : Statement where
  id := "S7"
  text := "microglial plaque (amyloid-beta) clearance lowers AD risk"
  claim := .effect abClearance .neg (.disease ad)
  evidence := []

/-- Run step H1.6: amyloid plaque compaction lowers AD risk. -/
def S8 : Statement where
  id := "S8"
  text := "amyloid plaque compaction lowers AD risk"
  claim := .effect plaqueCompaction .neg (.disease ad)
  evidence := []

/-- Run step H2.1: MS4A4A lowers TREM2. -/
def S9 : Statement where
  id := "S9"
  text := "MS4A4A lowers TREM2"
  claim := .effect MS4A4A .neg (.amount TREM2)
  evidence := [
    { pmid := 41435829, year := 2026, kind := .mechanistic, note := "By modulating MS4A4A using knockout, overexpression, and degrading antibodies in macrophages, microglia, non-human primates (NHPs), and a mouse model of amyloid pathology, we provide evidence that MS4A4A and MS4A6A are negative regulators o", taxon := some Taxa.mouse },
    { pmid := 41785844, year := 2026, kind := .review, note := "these proteins cooperatively restrain TREM2 signaling" }
  ]

/-- Run step H2.2: the rs1582763 A allele goes with lower AD risk. Sign: the run's polarity is unknown; the cited GWAS row gives OR 0.91 for rs1582763-A. -/
def S10 : Statement where
  id := "S10"
  text := "the rs1582763 A allele goes with lower AD risk"
  claim := .assoc rs1582763 (some .neg) (.disease ad)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs1582763", kind := .observational, note := "rs1582763-A is associated with 'Alzheimer's disease' at p = 4e-42, odds ratio 0.91 [0.9-0.92]" }
  ]

/-- Run step H2.3: ABI3 is required for cell motility (losing ABI3 lowers motility). -/
def S11 : Statement where
  id := "S11"
  text := "ABI3 is required for cell motility (losing ABI3 lowers motility)"
  claim := .effect ABI3 .pos (.process cellMotility)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9P2A4", kind := .curatedDb, polarity := .refutes, note := "In vitro, reduces cell motility" }
  ]

/-- Run step H2.3: ABI3 is required for microglial process extension (losing ABI3 lowers it). -/
def S12 : Statement where
  id := "S12"
  text := "ABI3 is required for microglial process extension (losing ABI3 lowers it)"
  claim := .effect ABI3 .pos (.process projectionAssembly)
  evidence := []

/-- Run step H2.4: microglial encapsulation of plaques lowers AD risk. -/
def S13 : Statement where
  id := "S13"
  text := "microglial encapsulation of plaques lowers AD risk"
  claim := .effect plaqueEncapsulation .neg (.disease ad)
  evidence := []

/-- Run step H3.1: LPIN2 lowers phosphatidic acid. -/
def S14 : Statement where
  id := "S14"
  text := "LPIN2 lowers phosphatidic acid"
  claim := .effect LPIN2 .neg (.amount phosphatidicAcid)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q92539", kind := .crossSpecies, note := "Acts as a magnesium-dependent phosphatidate phosphatase enzyme which catalyzes the conversion of phosphatidic acid to diacylglycerol" }
  ]

/-- Run step H3.2: LPIN2 is expressed in microglia. -/
def S15 : Statement where
  id := "S15"
  text := "LPIN2 is expressed in microglia"
  claim := .rel ⟨.ro, 2206, false⟩ LPIN2 microglia
  evidence := [
    { pmid := 0, year := 2026, ref := "HPA:ENSG00000101577", kind := .observational, note := "RNA single cell type specific nCPM.Microglia: 333.7" }
  ]

/-- Run step H3.3: APOE is associated with cholesterol transport and efflux (LXR). -/
def S16 : Statement where
  id := "S16"
  text := "APOE is associated with cholesterol transport and efflux (LXR)"
  claim := .assoc APOE none (.process cholesterolTransport)
  evidence := []

/-- Run step H3.4: microglial lipid stress raises AD risk. -/
def S17 : Statement where
  id := "S17"
  text := "microglial lipid stress raises AD risk"
  claim := .effect lipidStress .pos (.disease ad)
  evidence := []

/-- Run step H4.1: RNPS1 is required for nonsense-mediated decay (losing RNPS1 lowers NMD). -/
def S18 : Statement where
  id := "S18"
  text := "RNPS1 is required for nonsense-mediated decay (losing RNPS1 lowers NMD)"
  claim := .effect RNPS1 .pos (.process nmd)
  evidence := []

/-- Run step H4.1: RNPS1 is required for alternative splicing (losing RNPS1 lowers it). -/
def S19 : Statement where
  id := "S19"
  text := "RNPS1 is required for alternative splicing (losing RNPS1 lowers it)"
  claim := .effect RNPS1 .pos (.process altSplicing)
  evidence := []

/-- Run step H4.2: NMD lowers INPP5D transcripts. -/
def S20 : Statement where
  id := "S20"
  text := "NMD lowers INPP5D transcripts"
  claim := .effect nmd .neg (.amount INPP5D)
  evidence := []

/-- Run step H4.2: NMD lowers PLCG2 transcripts. -/
def S21 : Statement where
  id := "S21"
  text := "NMD lowers PLCG2 transcripts"
  claim := .effect nmd .neg (.amount PLCG2)
  evidence := []

/-- Run step H4.2: alternative splicing lowers INPP5D transcripts. -/
def S22 : Statement where
  id := "S22"
  text := "alternative splicing lowers INPP5D transcripts"
  claim := .effect altSplicing .neg (.amount INPP5D)
  evidence := []

/-- Run step H4.2: alternative splicing lowers PLCG2 transcripts. -/
def S23 : Statement where
  id := "S23"
  text := "alternative splicing lowers PLCG2 transcripts"
  claim := .effect altSplicing .neg (.amount PLCG2)
  evidence := []

/-- Run step H4.3: RNPS1 is associated with AD. -/
def S24 : Statement where
  id := "S24"
  text := "RNPS1 is associated with AD"
  claim := .assoc RNPS1 none (.disease ad)
  evidence := [
    { pmid := 0, year := 2026, ref := "GWAS:RNPS1:no-association", kind := .observational, polarity := .refutes, note := "reports no association between any RNPS1 variant and Alzheimer disease (MONDO_0004975) among the 6716 curated associations for that trait" }
  ]

/-- Run step H5.1: INPP5D inhibits RIPK1 kinase. -/
def S25 : Statement where
  id := "S25"
  text := "INPP5D inhibits RIPK1 kinase"
  claim := .effect INPP5D .neg (.activity RIPK1)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .inVitro, note := "the N-terminal SH2 domain of INPP5D, an important LOAD risk gene, directly interacted with the cell death regulator RIPK1 at p-Y383 to suppress RIPK1 kinase activation" }
  ]

/-- Run step H5.2: RIPK1 raises proinflammatory mediators. -/
def S26 : Statement where
  id := "S26"
  text := "RIPK1 raises proinflammatory mediators"
  claim := .effect RIPK1 .pos (.process inflammatoryMediators)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .mechanistic, note := "Microglial INPP5D deficiency cell-autonomously promoted RIPK1-mediated transcriptional induction of diverse LOAD risk genes, proinflammatory cytokines, complements, and ROS mediators", taxon := some Taxa.mouse }
  ]

/-- Run step H5.3: INPP5D inhibits microglial amyloid-beta clearance. -/
def S27 : Statement where
  id := "S27"
  text := "INPP5D inhibits microglial amyloid-beta clearance"
  claim := .effect INPP5D .neg (.process abClearance)
  evidence := [
    { pmid := 42582107, year := 2026, kind := .inVitro, note := "INPP5D overexpression partially rescued the enhanced Aβ clearance phenotype" }
  ]

/-- Run step H5.4: INPP5D is expressed in microglia. -/
def S28 : Statement where
  id := "S28"
  text := "INPP5D is expressed in microglia"
  claim := .rel ⟨.ro, 2206, false⟩ INPP5D microglia
  evidence := [
    { pmid := 0, year := 2026, ref := "HPA:ENSG00000168918", kind := .observational, note := "RNA single cell type specific nCPM.Microglia: 1021.1" }
  ]

/-- Run step H5.5: rosiptor activates INPP5D. -/
def S29 : Statement where
  id := "S29"
  text := "rosiptor activates INPP5D"
  claim := .effect rosiptor .pos (.activity INPP5D)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20, S21, S22, S23, S24, S25, S26, S27, S28, S29]

/-- H1, claim 3: TREM2/DAP12–PLCG2 signalling sets the microglial activation threshold; INPP5D is the brake and coding variants shift it in either direction. -/
def h1c3a1 := viaProcess (lit S27) (lit S7)

/-- H5, claim 1: INPP5D disinhibition is the tractable node: SHIP1 sits at the intersection of the RIPK1-inflammatory and CD22-phagocytic arms and already has a phase-3 small mo. -/
def h5c1a1 := viaActivity (lit S25) (lit S26)

/-- H5, claim 2: INPP5D disinhibition is the tractable node: SHIP1 sits at the intersection of the RIPK1-inflammatory and CD22-phagocytic arms and already has a phase-3 small mo. -/
def h5c2a1 := lit S27

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c3a1" h1c3a1,
    arm "H5" "c1a1" h5c1a1,
    arm "H5" "c2a1" h5c2a1]

#eval printRows "20260825T001904Z-300a86" rows

end BioLean.Lib.IPF.Runs.R20260825T001904Z_300a86
