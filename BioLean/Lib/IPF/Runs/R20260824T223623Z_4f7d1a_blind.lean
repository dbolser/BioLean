import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260824T223623Z-4f7d1a.blind/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260824T223623Z-4f7d1a`: anthropic:claude-opus-5, idiopathic pulmonary fibrosis, genes MUC5B, TERT, SFTPC, TOLLIP, DSP, FAM13A. -/

namespace BioLean.Lib.IPF.Runs.R20260824T223623Z_4f7d1a_blind

open BioLean BioLean.Lib.IPF Derivation

def rs35705950 : Entity .variant := ⟨"dbSNP:rs35705950", "MUC5B promoter variant rs35705950"⟩
def MUC5B : Entity .protein := ⟨"UniProt:Q9HC84", "MUC5B"⟩
def erStress : Entity .process := ⟨"GO:0034976", "response to endoplasmic reticulum stress"⟩
def DSP : Entity .protein := ⟨"UniProt:P15924", "DSP"⟩
def emt : Entity .process := ⟨"GO:0001837", "epithelial to mesenchymal transition"⟩
def pulmonaryFibrosis : Entity .disease := ⟨"MONDO:0002771", "pulmonary fibrosis"⟩
def ipf : Entity .disease := ⟨"MONDO:0800504", "idiopathic pulmonary fibrosis"⟩
def TERT : Entity .protein := ⟨"UniProt:O14746", "TERT"⟩
def telomereMaintenance : Entity .process := ⟨"GO:0000723", "telomere maintenance"⟩
def shortTelomereLength : Entity .phenotype := ⟨"HP:0031413", "Short telomere length"⟩
def sftpcBrichosMutant : Entity .variant := ⟨"BLN:SFTPC-BRICHOS-mutant", "SFTPC BRICHOS-domain mutant pro-SFTPC (class of variants, no ID)"⟩
def at2 : Entity .cellType := ⟨"CL:0002063", "pulmonary alveolar type 2 cell"⟩
def cellularSenescence : Entity .process := ⟨"GO:0090398", "cellular senescence"⟩
def TOLLIP : Entity .protein := ⟨"UniProt:Q9H0E2", "TOLLIP"⟩
def IRAK1 : Entity .protein := ⟨"UniProt:P51617", "IRAK1"⟩
def aggrephagy : Entity .process := ⟨"GO:0035973", "aggrephagy"⟩
def FAM13A : Entity .protein := ⟨"UniProt:O94988", "FAM13A"⟩
def RHOA : Entity .protein := ⟨"UniProt:P61586", "RHOA"⟩
def at2ErStress : Entity .process := erStress.inCtx { cellType := at2 }
def at2Senescence : Entity .process := cellularSenescence.inCtx { cellType := at2 }

/-- Run step H1.1: rs35705950 raises MUC5B. -/
def H1_1 : Statement where
  id := "H1_1"
  text := "rs35705950 raises MUC5B"
  claim := .effect rs35705950 .pos (.amount MUC5B)
  evidence := [
    { pmid := 27630174, year := 2016, kind := .review, note := "a common gain-of-function promoter variant in MUC5B rs35705950" },
    { pmid := 41091081, year := 2026, kind := .observational, note := "MUC5B was ectopically expressed in AT2 cells in controls with the risk variant" }
  ]

/-- Run step H1.2: MUC5B (ectopic expression) drives ER stress. -/
def H1_2 : Statement where
  id := "H1_2"
  text := "MUC5B (ectopic expression) drives ER stress"
  claim := .effect MUC5B .pos (.process erStress)
  evidence := [
    { pmid := 41091081, year := 2026, kind := .inVitro, note := "Ectopic expression of MUC5B in the respiratory bronchiole initiates endoplasmic reticulum stress" }
  ]

/-- Run step H1.3: DSP restrains EMT (via Hippo/YAP). -/
def H1_3 : Statement where
  id := "H1_3"
  text := "DSP restrains EMT (via Hippo/YAP)"
  claim := .effect DSP .neg (.process emt)
  evidence := [
    { pmid := 42120512, year := 2026, kind := .inVitro, note := "SYISL promotes DSP degradation, thereby relieving a key constraint on epithelial integrity. This event initiates a downstream signaling cascade, activating the PI3K-AKT pathway and promoting YAP1 dephosphorylation and nuclear translocation." }
  ]

/-- Run step H1.4: EMT drives pulmonary fibrosis (first half of the compound subject). -/
def H1_4emt : Statement where
  id := "H1_4emt"
  text := "EMT drives pulmonary fibrosis (first half of the compound subject)"
  claim := .effect emt .pos (.disease pulmonaryFibrosis)
  evidence := [
    { pmid := 42120512, year := 2026, kind := .inVitro, note := "collectively promotes an EMT-associated state and increased epithelial plasticity. The resultant aberrant epithelial-mesenchymal crosstalk contributes to pathological extracellular matrix (ECM) deposition" }
  ]

/-- Run step H1.4: ER stress drives pulmonary fibrosis (second half of the compound subject). -/
def H1_4er : Statement where
  id := "H1_4er"
  text := "ER stress drives pulmonary fibrosis (second half of the compound subject)"
  claim := .effect erStress .pos (.disease pulmonaryFibrosis)
  evidence := [
    { pmid := 41090357, year := 2025, kind := .mechanistic, note := "selective inhibition of RIDD with PAIR2 reduced AT2 differentiation into profibrotic transitional cells and protected mice from bleomycin-induced pulmonary fibrosis", taxon := some Taxa.mouse },
    { pmid := 18635891, year := 2008, kind := .observational, note := "Severe ER stress response in the AECIIs of patients with sporadic IPF may underlie the apoptosis of this cell type and development of fibrosis in this disease" }
  ]

/-- Run step H2.1: TERT is required for telomere maintenance (required_for, written as a positive effect). -/
def H2_1 : Statement where
  id := "H2_1"
  text := "TERT is required for telomere maintenance (required_for, written as a positive effect)"
  claim := .effect TERT .pos (.process telomereMaintenance)
  evidence := [
    { pmid := 0, year := 2026, ref := "O14746", kind := .curatedDb, note := "Catalytic component of the teleromerase holoenzyme complex whose main activity is the elongation of telomeres" }
  ]

/-- Run step H2.2: short telomere length raises IPF risk. -/
def H2_2 : Statement where
  id := "H2_2"
  text := "short telomere length raises IPF risk"
  claim := .effect shortTelomereLength .pos (.disease ipf)
  evidence := [
    { pmid := 41728098, year := 2026, kind := .observational, note := "shows significant shorter telomere lengths in IPF patients compared to healthy controls that suggest telomere as a risk factor for IPF occurrence" }
  ]

/-- Run step H2.3: BRICHOS-mutant pro-SFTPC drives ER stress in AT2 cells. -/
def H2_3 : Statement where
  id := "H2_3"
  text := "BRICHOS-mutant pro-SFTPC drives ER stress in AT2 cells"
  claim := .effect sftpcBrichosMutant .pos (.process at2ErStress)
  evidence := []

/-- Run step H2.4: AT2 senescence (failed alveolar regeneration) drives IPF. -/
def H2_4 : Statement where
  id := "H2_4"
  text := "AT2 senescence (failed alveolar regeneration) drives IPF"
  claim := .effect at2Senescence .pos (.disease ipf)
  evidence := [
    { pmid := 42346293, year := 2026, kind := .review, note := "Senescent alveolar epithelial cells and fibroblasts contribute to impaired tissue repair and persistent fibrotic remodeling" }
  ]

/-- Run step H3.1: TOLLIP inhibits IRAK1 (phosphorylation, in IL-1R/TLR signalling). -/
def H3_1 : Statement where
  id := "H3_1"
  text := "TOLLIP inhibits IRAK1 (phosphorylation, in IL-1R/TLR signalling)"
  claim := .effect TOLLIP .neg (.activity IRAK1)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9H0E2", kind := .curatedDb, note := "Inhibits IRAK1 phosphorylation and kinase activity" }
  ]

/-- Run step H3.2: TOLLIP is required for autophagic clearance of ubiquitin conjugates (required_for, written as a positive effect). -/
def H3_2 : Statement where
  id := "H3_2"
  text := "TOLLIP is required for autophagic clearance of ubiquitin conjugates (required_for, written as a positive effect)"
  claim := .effect TOLLIP .pos (.process aggrephagy)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9H0E2", kind := .curatedDb, note := "functioning as a ubiquitin-ATG8 family adapter and thus mediating autophagic clearance of ubiquitin conjugates" }
  ]

/-- Run step H4.1: FAM13A inhibits RhoA activity. -/
def H4_1 : Statement where
  id := "H4_1"
  text := "FAM13A inhibits RhoA activity"
  claim := .effect FAM13A .neg (.activity RHOA)
  evidence := []

def statements : List Statement := [H1_1, H1_2, H1_3, H1_4emt, H1_4er, H2_1, H2_2, H2_3, H2_4, H3_1, H3_2, H4_1]

/-- H1, claim 1: Distal airway secretory reprogramming: MUC5B over-expression plus DSP-dependent junction/EMT change converts the respiratory bronchiole into a fibrogenic, ER-st. -/
def h1c1a1 := viaAmount (lit H1_1) (viaProcess (lit H1_2) (lit H1_4er))

/-- H1, claim 2: Distal airway secretory reprogramming: MUC5B over-expression plus DSP-dependent junction/EMT change converts the respiratory bronchiole into a fibrogenic, ER-st. -/
def h1c2a1 := viaProcess (lit H1_3) (lit H1_4emt)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H1" "c2a1" h1c2a1]

#eval printRows "20260824T223623Z-4f7d1a.blind" rows

end BioLean.Lib.IPF.Runs.R20260824T223623Z_4f7d1a_blind
