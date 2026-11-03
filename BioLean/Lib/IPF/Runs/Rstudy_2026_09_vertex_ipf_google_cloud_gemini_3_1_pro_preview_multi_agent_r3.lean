import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-ipf-google-cloud-gemini-3.1-pro-preview-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-ipf-google-cloud-gemini-3.1-pro-preview-multi_agent-r3`: google-cloud:gemini-3.1-pro-preview, idiopathic pulmonary fibrosis, genes MUC5B, TERT, SFTPC, TOLLIP, DSP, FAM13A. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_ipf_google_cloud_gemini_3_1_pro_preview_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def tert : Entity .protein := ⟨"UniProt:O14746", "TERT"⟩
def telomereMaintenance : Entity .process := ⟨"GO:0000723", "telomere maintenance"⟩
def telomereDysfunction : Entity .phenotype := ⟨"HP:0031412", "Abnormal telomere morphology"⟩
def ipf : Entity .disease := ⟨"MONDO:0800504", "idiopathic pulmonary fibrosis"⟩
def dsp : Entity .protein := ⟨"UniProt:P15924", "DSP"⟩
def wntSignaling : Entity .process := ⟨"GO:0016055", "Wnt signaling pathway"⟩
def ecmOrganization : Entity .process := ⟨"GO:0030198", "extracellular matrix organization"⟩
def sftpc : Entity .protein := ⟨"UniProt:P11686", "SFTPC"⟩
def endosome : Entity .component := ⟨"GO:0005768", "endosome"⟩
def at2 : Entity .cellType := ⟨"CL:0002063", "pulmonary alveolar type 2 cell"⟩
def abnormalCellPhysiology : Entity .phenotype := ⟨"HP:0011017", "Abnormal cellular physiology"⟩
def muc5b : Entity .protein := ⟨"UniProt:Q9HC84", "MUC5B"⟩
def mucociliaryClearance : Entity .process := ⟨"GO:0120197", "mucociliary clearance"⟩
def sftpcEndosomal : Entity .protein := sftpc.inCtx { component := endosome }
def at2Dysfunction : Entity .phenotype := abnormalCellPhysiology.inCtx { cellType := at2 }

/-- Run step hyp-tert-telomere.1: TERT is required for telomere maintenance (losing TERT lowers it). -/
def S1 : Statement where
  id := "S1"
  text := "TERT is required for telomere maintenance (losing TERT lowers it)"
  claim := .effect tert .pos (.process telomereMaintenance)
  evidence := []

/-- Run step hyp-tert-telomere.2: telomere maintenance prevents telomere dysfunction. -/
def S2 : Statement where
  id := "S2"
  text := "telomere maintenance prevents telomere dysfunction"
  claim := .effect telomereMaintenance .neg (.phenotype telomereDysfunction)
  evidence := []

/-- Run step hyp-tert-telomere.3: telomere dysfunction raises IPF risk. -/
def S3 : Statement where
  id := "S3"
  text := "telomere dysfunction raises IPF risk"
  claim := .effect telomereDysfunction .pos (.disease ipf)
  evidence := [
    { pmid := 42532628, year := 2026, kind := .observational, note := "Telomere dysfunction and mucociliary impairment drive idiopathic pulmonary fibrosis susceptibility" }
  ]

/-- Run step hyp-dsp-wnt.1: DSP inhibits Wnt signaling. -/
def S4 : Statement where
  id := "S4"
  text := "DSP inhibits Wnt signaling"
  claim := .effect dsp .neg (.process wntSignaling)
  evidence := [
    { pmid := 42690534, year := 2026, kind := .inVitro, note := "DSP overexpression suppressed Wnt/β-catenin signaling" }
  ]

/-- Run step hyp-dsp-wnt.2: Wnt signaling drives extracellular matrix remodeling. -/
def S5 : Statement where
  id := "S5"
  text := "Wnt signaling drives extracellular matrix remodeling"
  claim := .effect wntSignaling .pos (.process ecmOrganization)
  evidence := [
    { pmid := 42690534, year := 2026, kind := .inVitro, note := "Wnt/β-Catenin-mediated extracellular matrix remodeling" }
  ]

/-- Run step hyp-dsp-wnt.3: extracellular matrix remodeling raises IPF risk. -/
def S6 : Statement where
  id := "S6"
  text := "extracellular matrix remodeling raises IPF risk"
  claim := .effect ecmOrganization .pos (.disease ipf)
  evidence := []

/-- Run step hyp-sftpc-at2.1: SFTPC goes with SFTPC accumulating in endosomes (run gives no direction). Sign: the run's polarity is 'unknown'; the cited text gives the accumulation for the I73T variant, not a direction for SFTPC itself. -/
def S7 : Statement where
  id := "S7"
  text := "SFTPC goes with SFTPC accumulating in endosomes (run gives no direction)"
  claim := .assoc sftpc none (.amount sftpcEndosomal)
  evidence := [
    { pmid := 42658012, year := 2026, kind := .inVitro, note := "SFTPC accumulation in enlarged early endosomes" }
  ]

/-- Run step hyp-sftpc-at2.2: endosomal SFTPC accumulation causes type II pneumocyte dysfunction. -/
def S8 : Statement where
  id := "S8"
  text := "endosomal SFTPC accumulation causes type II pneumocyte dysfunction"
  claim := .effect sftpcEndosomal .pos (.phenotype at2Dysfunction)
  evidence := [
    { pmid := 42658012, year := 2026, kind := .inVitro, note := "AT2 dysfunction due to endosomal SFTPC accumulation" }
  ]

/-- Run step hyp-sftpc-at2.3: type II pneumocyte dysfunction raises IPF risk. -/
def S9 : Statement where
  id := "S9"
  text := "type II pneumocyte dysfunction raises IPF risk"
  claim := .effect at2Dysfunction .pos (.disease ipf)
  evidence := []

/-- Run step hyp-muc5b-mucociliary.2: MUC5B impairs mucociliary clearance. Sign: inverted: the run's object is mucociliary impairment. -/
def S10 : Statement where
  id := "S10"
  text := "MUC5B impairs mucociliary clearance"
  claim := .effect muc5b .neg (.process mucociliaryClearance)
  evidence := []

/-- Run step hyp-muc5b-mucociliary.3: mucociliary clearance lowers IPF risk. Sign: inverted: the run's subject is mucociliary impairment. -/
def S11 : Statement where
  id := "S11"
  text := "mucociliary clearance lowers IPF risk"
  claim := .effect mucociliaryClearance .neg (.disease ipf)
  evidence := [
    { pmid := 42532628, year := 2026, kind := .observational, note := "mucociliary impairment drive idiopathic pulmonary fibrosis susceptibility" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11]

/-- hyp-tert-telomere, claim 1: TERT loss of function drives idiopathic pulmonary fibrosis via telomere dysfunction. -/
def h1c1a1 := viaProcess (lit S1) (viaPhenotype (lit S2) (lit S3))

/-- hyp-dsp-wnt, claim 1: Desmoplakin loss in alveolar epithelium drives Wnt/β-catenin-mediated extracellular matrix remodeling. -/
def h2c1a1 := viaProcess (lit S4) (viaProcess (lit S5) (lit S6))

/-- hyp-muc5b-mucociliary, claim 1: MUC5B promoter polymorphism drives mucociliary impairment and susceptibility to fibrosis. -/
def h4c1a1 := viaProcess (lit S10) (lit S11)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp-tert-telomere" "c1a1" h1c1a1,
    arm "hyp-dsp-wnt" "c1a1" h2c1a1,
    arm "hyp-muc5b-mucociliary" "c1a1" h4c1a1]

#eval printRows "study-2026-09-vertex-ipf-google-cloud-gemini-3.1-pro-preview-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_ipf_google_cloud_gemini_3_1_pro_preview_multi_agent_r3
