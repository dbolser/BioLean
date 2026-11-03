import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-dcm-vertex-openai-moonshotaikimi-k2-thinking-maas-multi_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-dcm-vertex-openai-moonshotaikimi-k2-thinking-maas-multi_agent-r3`: vertex-openai:moonshotai/kimi-k2-thinking-maas, dilated cardiomyopathy, genes LMNA, MYH7, TTN, TNNT2, RBM20, ABCB9, OR8J3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_dcm_vertex_openai_moonshotaikimi_k2_thinking_maas_multi_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def LMNA : Entity .protein := ⟨"UniProt:P02545", "LMNA"⟩
def nuclearEnvelopeOrganization : Entity .process := ⟨"GO:0006998", "nuclear envelope organization"⟩
def TTN : Entity .protein := ⟨"UniProt:Q8WZ42", "TTN"⟩
def RBM20 : Entity .protein := ⟨"UniProt:Q5T481", "RBM20"⟩
def MYH7 : Entity .protein := ⟨"UniProt:P12883", "MYH7"⟩
def TNNT2 : Entity .protein := ⟨"UniProt:P45379", "TNNT2"⟩
def dcm : Entity .disease := ⟨"MONDO:0005021", "dilated cardiomyopathy"⟩

/-- Run step h002.1: lamin A/C is required for the nuclear envelope, expressed as nuclear envelope organization: losing LMNA lowers it. -/
def S1 : Statement where
  id := "S1"
  text := "lamin A/C is required for the nuclear envelope, expressed as nuclear envelope organization: losing LMNA lowers it"
  claim := .effect LMNA .pos (.process nuclearEnvelopeOrganization)
  evidence := [
    { pmid := 0, year := 2026, ref := "P02545", kind := .curatedDb, note := "Lamins provide a framework for the nuclear envelope" }
  ]

/-- Run step h002.2: titin leads to dilated cardiomyopathy (positive, as the run states it). -/
def S2 : Statement where
  id := "S2"
  text := "titin leads to dilated cardiomyopathy (positive, as the run states it)"
  claim := .effect TTN .pos (.disease dcm)
  evidence := []

/-- Run step h003.1: RBM20 is required for titin (target: titin activity; losing RBM20 lowers it). -/
def S3 : Statement where
  id := "S3"
  text := "RBM20 is required for titin (target: titin activity; losing RBM20 lowers it)"
  claim := .effect RBM20 .pos (.activity TTN)
  evidence := []

/-- Run step h003.2: loss of RBM20 function leads to dilated cardiomyopathy. Sign: inverted: the run's subject is 'RBM20 malfunction' with positive polarity. -/
def S4 : Statement where
  id := "S4"
  text := "loss of RBM20 function leads to dilated cardiomyopathy"
  claim := .effect RBM20 .neg (.disease dcm)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4]

/-- h001, claim 2: Sarcomere structural defect drives DCM through MYH7, TTN, and TNNT2 dysfunction. -/
def h1c2a1 := lit S2

/-- h002, claim 2: Nuclear envelope and sarcomere defects converge via LMNA and TTN to cause DCM. -/
def h2c2a1 := lit S1

/-- h002, claim 3: Nuclear envelope and sarcomere defects converge via LMNA and TTN to cause DCM. -/
def h2c3a1 := lit S2

/-- h003, claim 1: RBM20-TTN splicing axis regulates DCM through isoform switching. -/
def h3c1a1 := viaActivity (lit S3) (lit S2)

/-- h003, claim 1: RBM20-TTN splicing axis regulates DCM through isoform switching. -/
def h3c1a2 := lit S4

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "h001" "c2a1" h1c2a1,
    arm "h002" "c2a1" h2c2a1,
    arm "h002" "c3a1" h2c3a1,
    arm "h003" "c1a1" h3c1a1,
    arm "h003" "c1a2" h3c1a2]

#eval printRows "study-2026-09-vertex-dcm-vertex-openai-moonshotaikimi-k2-thinking-maas-multi_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_dcm_vertex_openai_moonshotaikimi_k2_thinking_maas_multi_agent_r3
