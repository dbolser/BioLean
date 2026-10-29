import BioLean

/-! Rendered from `data/ipf/curated.json` by `scripts/ipf/02_render_lean.py`. Do not edit by hand.
The statements of hypothesis-agent run 20260824T223623Z-4f7d1a (IPF, six genes), one per chain step,
with the evidence the run cited. Every quote is a verified substring of its source. -/

namespace BioLean.Lib.IPF

def ipf : Entity .disease := ⟨"MONDO:0800504", "idiopathic pulmonary fibrosis"⟩
def pulmonaryFibrosis : Entity .disease := ⟨"MONDO:0002771", "pulmonary fibrosis"⟩
def rs35705950 : Entity .variant := ⟨"dbSNP:rs35705950", "MUC5B promoter variant rs35705950"⟩
def sftpcBrichos : Entity .variant := ⟨"BLN:SFTPC-BRICHOS-mutation", "SFTPC BRICHOS-domain mutation (no public identifier for the class)"⟩
def MUC5B : Entity .protein := ⟨"UniProt:Q9HC84", "MUC5B"⟩
def DSP : Entity .protein := ⟨"UniProt:P15924", "DSP (desmoplakin)"⟩
def TERT : Entity .protein := ⟨"UniProt:O14746", "TERT"⟩
def TOLLIP : Entity .protein := ⟨"UniProt:Q9H0E2", "TOLLIP"⟩
def IRAK1 : Entity .protein := ⟨"UniProt:P51617", "IRAK1"⟩
def FAM13A : Entity .protein := ⟨"UniProt:O94988", "FAM13A"⟩
def RHOA : Entity .protein := ⟨"UniProt:P61586", "RHOA"⟩
def erStress : Entity .process := ⟨"GO:0034976", "response to endoplasmic reticulum stress"⟩
def emt : Entity .process := ⟨"GO:0001837", "epithelial to mesenchymal transition"⟩
def telomereMaintenance : Entity .process := ⟨"GO:0000723", "telomere maintenance"⟩
def cellularSenescence : Entity .process := ⟨"GO:0090398", "cellular senescence"⟩
def aggrephagy : Entity .process := ⟨"GO:0035973", "aggrephagy"⟩
def at2 : Entity .cellType := ⟨"CL:0002063", "pulmonary alveolar type 2 cell"⟩
def shortTelomeres : Entity .phenotype := ⟨"HP:0031413", "short telomere length"⟩

/-- Cellular senescence in alveolar type 2 cells: a refinement, as in M2. -/
def at2Senescence : Entity .process := cellularSenescence.inCtx { cellType := at2 }

/-- Run step H1.1: rs35705950 raises MUC5B. -/
def I1 : Statement where
  id := "I1"
  text := "rs35705950 raises MUC5B"
  claim := .effect rs35705950 .pos (.amount MUC5B)
  evidence := [
    { pmid := 27630174, year := 2016, kind := .review, polarity := .supports, note := "a common gain-of-function promoter variant in MUC5B rs35705950" },
    { pmid := 41091081, year := 2026, kind := .observational, polarity := .supports, note := "MUC5B was ectopically expressed in AT2 cells in controls with the risk variant" }
  ]

/-- Run step H1.2: MUC5B raises ER stress. -/
def I2 : Statement where
  id := "I2"
  text := "MUC5B raises ER stress"
  claim := .effect MUC5B .pos (.process erStress)
  evidence := [
    { pmid := 41091081, year := 2026, kind := .inVitro, polarity := .supports, note := "we demonstrated a direct relationship between MUC5B expression and ER stress in bronchiolar epithelia in vitro" }
  ]

/-- Run step H1.3: DSP restrains EMT. -/
def I3 : Statement where
  id := "I3"
  text := "DSP restrains EMT"
  claim := .effect DSP .neg (.process emt)
  evidence := [
    { pmid := 42120512, year := 2026, kind := .mechanistic, polarity := .supports, note := "SYISL promotes DSP degradation, thereby relieving a key constraint on epithelial integrity" }
  ]

/-- Run step H1.4: ER stress drives pulmonary fibrosis. -/
def I4 : Statement where
  id := "I4"
  text := "ER stress drives pulmonary fibrosis"
  claim := .effect erStress .pos (.disease pulmonaryFibrosis)
  evidence := [
    { pmid := 41090357, year := 2025, kind := .mechanistic, polarity := .supports, note := "selective inhibition of RIDD with PAIR2 reduced AT2 differentiation into profibrotic transitional cells and protected mice from bleomycin-induced pulmonary fibrosis", taxon := some Taxa.mouse }
  ]

/-- Run step H1.4: EMT drives pulmonary fibrosis. -/
def I5 : Statement where
  id := "I5"
  text := "EMT drives pulmonary fibrosis"
  claim := .effect emt .pos (.disease pulmonaryFibrosis)
  evidence := [
    { pmid := 42120512, year := 2026, kind := .mechanistic, polarity := .supports, note := "The resultant aberrant epithelial-mesenchymal crosstalk contributes to pathological extracellular matrix (ECM) deposition" }
  ]

/-- Run step H2.1: TERT maintains telomeres. -/
def I6 : Statement where
  id := "I6"
  text := "TERT maintains telomeres"
  claim := .effect TERT .pos (.process telomereMaintenance)
  evidence := [
    { pmid := 0, year := 2026, kind := .curatedDb, polarity := .supports, note := "UniProt:O14746: main activity is the elongation of telomeres" }
  ]

/-- Run step bridge: telomere maintenance prevents short telomeres. -/
def I7 : Statement where
  id := "I7"
  text := "telomere maintenance prevents short telomeres"
  claim := .effect telomereMaintenance .neg (.phenotype shortTelomeres)
  evidence := [
    { pmid := 0, year := 2026, kind := .textbook, polarity := .supports, note := "GO:0000723: GO definition of telomere maintenance: maintenance of proper telomeric length. The run never states this link." }
  ]

/-- Run step H2.2: short telomeres raise IPF risk. -/
def I8 : Statement where
  id := "I8"
  text := "short telomeres raise IPF risk"
  claim := .effect shortTelomeres .pos (.disease ipf)
  evidence := [
    { pmid := 41728098, year := 2026, kind := .observational, polarity := .supports, note := "significant shorter telomere lengths in IPF patients compared to healthy controls" },
    { pmid := 23535734, year := 2013, kind := .observational, polarity := .supports, note := "Lead SNPs at two loci (TERC and TERT) associate with several cancers and other diseases, including idiopathic pulmonary fibrosis" }
  ]

/-- Run step H2.3: mutant pro-SFTPC raises ER stress. -/
def I9 : Statement where
  id := "I9"
  text := "mutant pro-SFTPC raises ER stress"
  claim := .effect sftpcBrichos .pos (.process erStress)
  evidence := []

/-- Run step H2.4: AT2 senescence drives IPF. -/
def I10 : Statement where
  id := "I10"
  text := "AT2 senescence drives IPF"
  claim := .effect at2Senescence .pos (.disease ipf)
  evidence := [
    { pmid := 32661339, year := 2020, kind := .observational, polarity := .supports, note := "accumulation of PATS-like cells in human fibrotic lungs was observed" },
    { pmid := 32678092, year := 2020, kind := .observational, polarity := .supports, note := "state appears in several independent models of lung injury and persists in human lung fibrosis" },
    { pmid := 42346293, year := 2026, kind := .review, polarity := .supports, note := "cellular senescence is not merely a consequence of tissue injury but a central driver of disease progression" }
  ]

/-- Run step H3.1: TOLLIP inhibits IRAK1. -/
def I11 : Statement where
  id := "I11"
  text := "TOLLIP inhibits IRAK1"
  claim := .effect TOLLIP .neg (.activity IRAK1)
  evidence := [
    { pmid := 0, year := 2026, kind := .curatedDb, polarity := .supports, note := "UniProt:Q9H0E2: Inhibits IRAK1 phosphorylation and kinase activity" }
  ]

/-- Run step H3.2: TOLLIP drives aggrephagy. -/
def I12 : Statement where
  id := "I12"
  text := "TOLLIP drives aggrephagy"
  claim := .effect TOLLIP .pos (.process aggrephagy)
  evidence := [
    { pmid := 0, year := 2026, kind := .curatedDb, polarity := .supports, note := "UniProt:Q9H0E2: mediating autophagic clearance of ubiquitin conjugates" }
  ]

/-- Run step H4.1: FAM13A inhibits RHOA. -/
def I13 : Statement where
  id := "I13"
  text := "FAM13A inhibits RHOA"
  claim := .effect FAM13A .neg (.activity RHOA)
  evidence := [
    { pmid := 42266412, year := 2026, kind := .review, polarity := .supports, note := "a protein with a characteristic RhoGAP domain" }
  ]

def statements : List Statement := [I1, I2, I3, I4, I5, I6, I7, I8, I9, I10, I11, I12, I13]

end BioLean.Lib.IPF
