import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260824T202248Z-29d6aa/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260824T202248Z-29d6aa`: openai:gpt-5.6-sol, idiopathic pulmonary fibrosis, genes MUC5B, TERT, SFTPC, TOLLIP, DSP, FAM13A. -/

namespace BioLean.Lib.IPF.Runs.R20260824T202248Z_29d6aa

open BioLean BioLean.Lib.IPF Derivation

def MUC5B : Entity .protein := ⟨"UniProt:Q9HC84", "MUC5B"⟩
def TOLLIP : Entity .protein := ⟨"UniProt:Q9H0E2", "TOLLIP"⟩
def TERT : Entity .protein := ⟨"UniProt:O14746", "TERT"⟩
def DSP : Entity .protein := ⟨"UniProt:P15924", "DSP"⟩
def SFTPC : Entity .protein := ⟨"UniProt:P11686", "SFTPC"⟩
def erStress : Entity .process := ⟨"GO:0034976", "response to endoplasmic reticulum stress"⟩
def aggrephagy : Entity .process := ⟨"GO:0035973", "aggrephagy"⟩
def proteotoxicStress : Entity .process := ⟨"GO:0035966", "response to topologically incorrect protein"⟩
def telomereExtension : Entity .process := ⟨"GO:0007004", "telomere maintenance via telomerase"⟩
def desmosomeOrg : Entity .process := ⟨"GO:0002934", "desmosome organization"⟩
def telomereDamage : Entity .process := ⟨"BLN:TelomereDamage", "telomere damage"⟩
def epitheliumRegeneration : Entity .process := ⟨"GO:1990399", "epithelium regeneration"⟩
def surfaceTension : Entity .phenotype := ⟨"PATO:0001461", "surface tension"⟩
def ipf : Entity .disease := ⟨"MONDO:0800504", "idiopathic pulmonary fibrosis"⟩
def telomereCapping : Entity .process := ⟨"GO:0016233", "telomere capping"⟩
def at2 : Entity .cellType := ⟨"CL:0002063", "pulmonary alveolar type 2 cell"⟩
def at2Injury : Entity .phenotype := ⟨"BLN:AT2Injury", "alveolar type II cell injury"⟩
def abnormalWoundHealing : Entity .phenotype := ⟨"MP:0005023", "abnormal wound healing"⟩
def at2Regeneration : Entity .process := epitheliumRegeneration.inCtx { cellType := at2 }

/-- Run step H1.1: ectopic MUC5B in the respiratory bronchiole initiates epithelial ER stress. -/
def S1 : Statement where
  id := "S1"
  text := "ectopic MUC5B in the respiratory bronchiole initiates epithelial ER stress"
  claim := .effect MUC5B .pos (.process erStress)
  evidence := [
    { pmid := 41091081, year := 2026, kind := .inVitro, note := "Ectopic expression of MUC5B in the respiratory bronchiole initiates endoplasmic reticulum stress in the IPF lung" }
  ]

/-- Run step H1.2: TOLLIP is required for selective autophagic clearance of ubiquitinated cargo. -/
def S2 : Statement where
  id := "S2"
  text := "TOLLIP is required for selective autophagic clearance of ubiquitinated cargo"
  claim := .effect TOLLIP .pos (.process aggrephagy)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9H0E2", kind := .curatedDb, note := "Connects the ubiquitin pathway to autophagy by functioning as a ubiquitin-ATG8 family adapter and thus mediating autophagic clearance of ubiquitin conjugates" }
  ]

/-- Run step H1.3: persistent epithelial proteotoxic stress leads to IPF. -/
def S3 : Statement where
  id := "S3"
  text := "persistent epithelial proteotoxic stress leads to IPF"
  claim := .effect proteotoxicStress .pos (.disease ipf)
  evidence := []

/-- Run step H2.1: TERT is required for telomere extension. -/
def S4 : Statement where
  id := "S4"
  text := "TERT is required for telomere extension"
  claim := .effect TERT .pos (.process telomereExtension)
  evidence := [
    { pmid := 0, year := 2026, ref := "O14746", kind := .curatedDb, note := "the elongation of telomeres by acting as a reverse transcriptase that adds simple sequence repeats to chromosome ends" }
  ]

/-- Run step H2.2: DSP is required for desmosome organization (one half of a compound object). -/
def S5 : Statement where
  id := "S5"
  text := "DSP is required for desmosome organization (one half of a compound object)"
  claim := .effect DSP .pos (.process desmosomeOrg)
  evidence := [
    { pmid := 0, year := 2026, ref := "P15924", kind := .curatedDb, note := "Required for the maintenance of protein abundance of desmosome junction components DSG1, DSG2, DSC2, DSC3, PKP1, PKP2 and PKP3" }
  ]

/-- Run step H2.2: DSP is required for telomere protection (telomere capping; other half of the compound object). -/
def S6 : Statement where
  id := "S6"
  text := "DSP is required for telomere protection (telomere capping; other half of the compound object)"
  claim := .effect DSP .pos (.process telomereCapping)
  evidence := [
    { pmid := 0, year := 2026, ref := "P15924", kind := .curatedDb, note := "Binds to telomere DNA (via C-terminus) and acts to prevent telomere damage and maintain telomere length via its interaction with TRF2" }
  ]

/-- Run step H2.3: telomere damage leads to IPF (one half of a compound subject). -/
def S7 : Statement where
  id := "S7"
  text := "telomere damage leads to IPF (one half of a compound subject)"
  claim := .effect telomereDamage .pos (.disease ipf)
  evidence := []

/-- Run step H2.3: epithelial regeneration protects against IPF (run's 'epithelial repair failure', loss-of-function inverted). Sign: inverted: the run's subject is 'epithelial repair failure' (loss of epithelial regeneration), stated as leading positively to IPF. -/
def S8 : Statement where
  id := "S8"
  text := "epithelial regeneration protects against IPF (run's 'epithelial repair failure', loss-of-function inverted)"
  claim := .effect epitheliumRegeneration .neg (.disease ipf)
  evidence := []

/-- Run step H3.1: SFTPC lowers alveolar surface tension (run's 'low-tension alveolar surface film'). Sign: the run's object is the low-tension surface film; SFTPC lowers surface tension, so the effect on surface tension is negative. -/
def S9 : Statement where
  id := "S9"
  text := "SFTPC lowers alveolar surface tension (run's 'low-tension alveolar surface film')"
  claim := .effect SFTPC .neg (.phenotype surfaceTension)
  evidence := [
    { pmid := 0, year := 2026, ref := "P11686", kind := .curatedDb, note := "promote alveolar stability by lowering the surface tension at the air-liquid interface in the peripheral air spaces" }
  ]

/-- Run step H3.2: SFTPC protects alveolar type II cells from injury (run's 'SFTPC dysfunction', loss-of-function inverted; one half of a compound object). Sign: inverted: the run's subject is 'SFTPC dysfunction' (loss of function), stated as leading positively to AT2 injury. -/
def S10 : Statement where
  id := "S10"
  text := "SFTPC protects alveolar type II cells from injury (run's 'SFTPC dysfunction', loss-of-function inverted; one half of a compound object)"
  claim := .effect SFTPC .neg (.phenotype at2Injury)
  evidence := []

/-- Run step H3.3: alveolar type II cell injury leads to IPF (one half of a compound subject). -/
def S11 : Statement where
  id := "S11"
  text := "alveolar type II cell injury leads to IPF (one half of a compound subject)"
  claim := .effect at2Injury .pos (.disease ipf)
  evidence := []

/-- Run step H3.2: SFTPC is needed for alveolar type II cell repair (run's 'SFTPC dysfunction' leads to 'failed repair'; other half of the compound object). Sign: inverted twice: the run's subject is 'SFTPC dysfunction' (loss of SFTPC) and this half of its object is 'failed repair' (loss of AT2 epithelial regeneration); the run's + becomes SFTPC →+ regeneration. -/
def S12 : Statement where
  id := "S12"
  text := "SFTPC is needed for alveolar type II cell repair (run's 'SFTPC dysfunction' leads to 'failed repair'; other half of the compound object)"
  claim := .effect SFTPC .pos (.process at2Regeneration)
  evidence := []

/-- Run step H3.3: alveolar type II cell repair protects against IPF (run's 'failed repair' leads to IPF, loss-of-function inverted; other half of the compound subject). Sign: inverted: this half of the run's subject is 'failed repair' (loss of AT2 epithelial regeneration), stated as leading positively to IPF. -/
def S13 : Statement where
  id := "S13"
  text := "alveolar type II cell repair protects against IPF (run's 'failed repair' leads to IPF, loss-of-function inverted; other half of the compound subject)"
  claim := .effect at2Regeneration .neg (.disease ipf)
  evidence := []

/-- Run step H4.2: abnormal epithelial wound repair leads to IPF. -/
def S14 : Statement where
  id := "S14"
  text := "abnormal epithelial wound repair leads to IPF"
  claim := .effect abnormalWoundHealing .pos (.disease ipf)
  evidence := []

/-- Bridge, not in the run: DSP prevents telomere damage (stated by the UniProt text the run cited for H2.2; the run's mechanism names this role but no step makes it). -/
def B1 : Statement where
  id := "B1"
  text := "DSP prevents telomere damage (stated by the UniProt text the run cited for H2.2; the run's mechanism names this role but no step makes it)"
  claim := .effect DSP .neg (.process telomereDamage)
  evidence := [
    { pmid := 0, year := 2026, ref := "P15924", kind := .curatedDb, note := "Binds to telomere DNA (via C-terminus) and acts to prevent telomere damage" }
  ]

/-- Bridge, not in the run: MUC5B injures alveolar epithelium with loss of AT2 cells (stated by the paper the run cited for H1.1; no step makes it). -/
def B2 : Statement where
  id := "B2"
  text := "MUC5B injures alveolar epithelium with loss of AT2 cells (stated by the paper the run cited for H1.1; no step makes it)"
  claim := .effect MUC5B .pos (.phenotype at2Injury)
  evidence := [
    { pmid := 41091081, year := 2026, kind := .observational, note := "MUC5B injures alveolar and bronchiolar epithelia that results in loss of AT2 cells" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, B1, B2]

/-- H1, claim 1: Ectopic MUC5B plus inadequate TOLLIP-dependent proteostasis sustains bronchiolar epithelial stress. -/
def h1c1a1 := viaPhenotype (lit B2) (lit S11)

/-- H2, claim 2: TERT and DSP converge on telomere protection and epithelial regenerative competence. -/
def h2c2a1 := viaProcess (lit B1) (lit S7)

/-- H3, claim 1: SFTPC dysfunction makes alveolar type II cells an initiating site of IPF. -/
def h3c1a1 := viaPhenotype (lit S10) (lit S11)

/-- H3, claim 1: SFTPC dysfunction makes alveolar type II cells an initiating site of IPF. -/
def h3c1a2 := viaProcess (lit S12) (lit S13)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H2" "c2a1" h2c2a1,
    arm "H3" "c1a1" h3c1a1,
    arm "H3" "c1a2" h3c1a2]

#eval printRows "20260824T202248Z-29d6aa" rows

end BioLean.Lib.IPF.Runs.R20260824T202248Z_29d6aa
