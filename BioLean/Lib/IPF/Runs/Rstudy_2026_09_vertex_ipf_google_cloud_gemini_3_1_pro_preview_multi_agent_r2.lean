import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-ipf-google-cloud-gemini-3.1-pro-preview-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-ipf-google-cloud-gemini-3.1-pro-preview-multi_agent-r2`: google-cloud:gemini-3.1-pro-preview, idiopathic pulmonary fibrosis, genes MUC5B, TERT, SFTPC, TOLLIP, DSP, FAM13A. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_ipf_google_cloud_gemini_3_1_pro_preview_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def muc5b : Entity .protein := ⟨"UniProt:Q9HC84", "MUC5B"⟩
def tollip : Entity .protein := ⟨"UniProt:Q9H0E2", "TOLLIP"⟩
def sftpc : Entity .protein := ⟨"UniProt:P11686", "SFTPC"⟩
def dsp : Entity .protein := ⟨"UniProt:P15924", "DSP"⟩
def fam13a : Entity .protein := ⟨"UniProt:O94988", "FAM13A"⟩
def tert : Entity .protein := ⟨"UniProt:O14746", "TERT"⟩
def mucociliaryClearance : Entity .process := ⟨"GO:0120197", "mucociliary clearance"⟩
def immuneResponse : Entity .process := ⟨"GO:0006955", "immune response"⟩
def endosome : Entity .component := ⟨"GO:0005768", "endosome"⟩
def at2 : Entity .cellType := ⟨"CL:0002063", "pulmonary alveolar type 2 cell"⟩
def abnormalCellPhysiology : Entity .phenotype := ⟨"HP:0011017", "Abnormal cellular physiology"⟩
def wnt : Entity .process := ⟨"GO:0016055", "Wnt signaling pathway"⟩
def ecmOrganization : Entity .process := ⟨"GO:0030198", "extracellular matrix organization"⟩
def epithelialCellDifferentiation : Entity .process := ⟨"GO:0030855", "epithelial cell differentiation"⟩
def telomereMaintenance : Entity .process := ⟨"GO:0000723", "telomere maintenance"⟩
def cellularSenescence : Entity .process := ⟨"GO:0090398", "cellular senescence"⟩
def ipf : Entity .disease := ⟨"MONDO:0800504", "idiopathic pulmonary fibrosis"⟩
def sftpcInEndosome : Entity .protein := sftpc.inCtx { component := endosome }
def at2Dysfunction : Entity .phenotype := abnormalCellPhysiology.inCtx { cellType := at2 }

/-- Run step hyp_muc5b_tollip.2: MUC5B inhibits mucociliary clearance. -/
def h1s2 : Statement where
  id := "h1s2"
  text := "MUC5B inhibits mucociliary clearance"
  claim := .effect muc5b .neg (.process mucociliaryClearance)
  evidence := []

/-- Run step hyp_muc5b_tollip.3: TOLLIP is associated with the immune response (no direction). -/
def h1s3 : Statement where
  id := "h1s3"
  text := "TOLLIP is associated with the immune response (no direction)"
  claim := .assoc tollip none (.process immuneResponse)
  evidence := []

/-- Run step hyp_muc5b_tollip.4: mucociliary clearance raises the risk of IPF (the run's sign). -/
def h1s4 : Statement where
  id := "h1s4"
  text := "mucociliary clearance raises the risk of IPF (the run's sign)"
  claim := .effect mucociliaryClearance .pos (.disease ipf)
  evidence := [
    { pmid := 42532628, year := 2026, kind := .observational, polarity := .refutes, note := "mucociliary impairment drive idiopathic pulmonary fibrosis susceptibility" }
  ]

/-- Run step hyp_sftpc_at2.1: SFTPC is associated with its own accumulation in endosomes (no direction). -/
def h2s1 : Statement where
  id := "h2s1"
  text := "SFTPC is associated with its own accumulation in endosomes (no direction)"
  claim := .assoc sftpc none (.amount sftpcInEndosome)
  evidence := []

/-- Run step hyp_sftpc_at2.2: SFTPC accumulating in endosomes drives AT2 cell dysfunction. -/
def h2s2 : Statement where
  id := "h2s2"
  text := "SFTPC accumulating in endosomes drives AT2 cell dysfunction"
  claim := .effect sftpcInEndosome .pos (.phenotype at2Dysfunction)
  evidence := [
    { pmid := 42658012, year := 2026, kind := .inVitro, note := "reveals AT2 dysfunction due to endosomal SFTPC accumulation" }
  ]

/-- Run step hyp_sftpc_at2.3: AT2 cell dysfunction raises the risk of IPF. -/
def h2s3 : Statement where
  id := "h2s3"
  text := "AT2 cell dysfunction raises the risk of IPF"
  claim := .effect at2Dysfunction .pos (.disease ipf)
  evidence := []

/-- Run step hyp_dsp_fam13a_epithelium.1: DSP inhibits Wnt signalling. -/
def h3s1 : Statement where
  id := "h3s1"
  text := "DSP inhibits Wnt signalling"
  claim := .effect dsp .neg (.process wnt)
  evidence := [
    { pmid := 42690534, year := 2026, kind := .inVitro, note := "DSP overexpression suppressed Wnt/β-catenin signaling" }
  ]

/-- Run step hyp_dsp_fam13a_epithelium.2: Wnt signalling activates extracellular matrix remodelling. -/
def h3s2 : Statement where
  id := "h3s2"
  text := "Wnt signalling activates extracellular matrix remodelling"
  claim := .effect wnt .pos (.process ecmOrganization)
  evidence := [
    { pmid := 42690534, year := 2026, kind := .inVitro, note := "Wnt/β-Catenin-mediated extracellular matrix remodeling" }
  ]

/-- Run step hyp_dsp_fam13a_epithelium.3: FAM13A goes with epithelial cell differentiation (direction from the cited text). Sign: the run gives associated_with, polarity unknown; the direction is from PMID:42083809, where losing the FAM13A long isoform in iPSCs prevented mature airway or alveolar epithelial lineages from emerging. It is not the run's 'upregulated FAM1. -/
def h3s3 : Statement where
  id := "h3s3"
  text := "FAM13A goes with epithelial cell differentiation (direction from the cited text)"
  claim := .assoc fam13a (some .pos) (.process epithelialCellDifferentiation)
  evidence := [
    { pmid := 42083809, year := 2026, kind := .inVitro, note := "we disrupted the long isoform of FAM13A in human induced pluripotent stem cells (iPSCs). Specific loss of this isoform prevented the emergence in culture of mature airway or alveolar epithelial lineages" }
  ]

/-- Run step hyp_dsp_fam13a_epithelium.4: extracellular matrix remodelling raises the risk of IPF. -/
def h3s4 : Statement where
  id := "h3s4"
  text := "extracellular matrix remodelling raises the risk of IPF"
  claim := .effect ecmOrganization .pos (.disease ipf)
  evidence := []

/-- Run step hyp_tert_telomeres.1: TERT is associated with telomere maintenance (no direction). -/
def h4s1 : Statement where
  id := "h4s1"
  text := "TERT is associated with telomere maintenance (no direction)"
  claim := .assoc tert none (.process telomereMaintenance)
  evidence := []

/-- Run step hyp_tert_telomeres.2: telomere maintenance promotes cellular senescence (the run's sign). -/
def h4s2 : Statement where
  id := "h4s2"
  text := "telomere maintenance promotes cellular senescence (the run's sign)"
  claim := .effect telomereMaintenance .pos (.process cellularSenescence)
  evidence := []

/-- Run step hyp_tert_telomeres.3: cellular senescence raises the risk of IPF. -/
def h4s3 : Statement where
  id := "h4s3"
  text := "cellular senescence raises the risk of IPF"
  claim := .effect cellularSenescence .pos (.disease ipf)
  evidence := []

def statements : List Statement := [h1s2, h1s3, h1s4, h2s1, h2s2, h2s3, h3s1, h3s2, h3s3, h3s4, h4s1, h4s2, h4s3]

/-- hyp_muc5b_tollip, claim 1: MUC5B overexpression impairs mucociliary clearance while TOLLIP modulates localized immune responses.. -/
def h1c1a1 := viaProcess (lit h1s2) (lit h1s4)

/-- hyp_dsp_fam13a_epithelium, claim 1: Epithelial DSP loss and FAM13A upregulation drive Wnt-mediated ECM remodeling.. -/
def h3c1a1 := viaProcess (lit h3s1) (viaProcess (lit h3s2) (lit h3s4))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp_muc5b_tollip" "c1a1" h1c1a1,
    arm "hyp_dsp_fam13a_epithelium" "c1a1" h3c1a1]

#eval printRows "study-2026-09-vertex-ipf-google-cloud-gemini-3.1-pro-preview-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_ipf_google_cloud_gemini_3_1_pro_preview_multi_agent_r2
