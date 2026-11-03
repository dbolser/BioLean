import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-single_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-single_agent-r3`: google-cloud:gemini-3.1-pro-preview, psoriasis, genes IL12B, EGFL8, TRAF3IP2, TYK2, IL23R, GLE1, UHRF2. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_psoriasis_google_cloud_gemini_3_1_pro_preview_single_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def IL12B : Entity .protein := ⟨"UniProt:P29460", "IL12B"⟩
def IL23R : Entity .protein := ⟨"UniProt:Q5VWK5", "IL23R"⟩
def TYK2 : Entity .protein := ⟨"UniProt:P29597", "TYK2"⟩
def TRAF3IP2 : Entity .protein := ⟨"UniProt:O43734", "TRAF3IP2"⟩
def jakStatPosReg : Entity .process := ⟨"GO:0046427", "positive regulation of receptor signaling pathway via JAK-STAT"⟩
def th17Response : Entity .process := ⟨"GO:0072538", "T-helper 17 type immune response"⟩
def il17Production : Entity .process := ⟨"GO:0032620", "interleukin-17 production"⟩
def psoriasis : Entity .disease := ⟨"MONDO:0005083", "psoriasis"⟩

/-- Run step H2-TYK2-intracellular.1: IL23R activates TYK2. -/
def S1 : Statement where
  id := "S1"
  text := "IL23R activates TYK2"
  claim := .effect IL23R .pos (.activity TYK2)
  evidence := []

/-- Run step H2-TYK2-intracellular.2: TYK2 activates positive regulation of JAK-STAT receptor signalling. -/
def S2 : Statement where
  id := "S2"
  text := "TYK2 activates positive regulation of JAK-STAT receptor signalling"
  claim := .effect TYK2 .pos (.process jakStatPosReg)
  evidence := []

/-- Run step H2-TYK2-intracellular.3: positive regulation of JAK-STAT receptor signalling raises psoriasis risk. -/
def S3 : Statement where
  id := "S3"
  text := "positive regulation of JAK-STAT receptor signalling raises psoriasis risk"
  claim := .effect jakStatPosReg .pos (.disease psoriasis)
  evidence := []

/-- Run step H3-TRAF3IP2-IL17.1: the T-helper 17 immune response increases interleukin-17 production. -/
def S4 : Statement where
  id := "S4"
  text := "the T-helper 17 immune response increases interleukin-17 production"
  claim := .effect th17Response .pos (.process il17Production)
  evidence := []

/-- Run step H3-TRAF3IP2-IL17.2: interleukin-17 production activates TRAF3IP2. -/
def S5 : Statement where
  id := "S5"
  text := "interleukin-17 production activates TRAF3IP2"
  claim := .effect il17Production .pos (.activity TRAF3IP2)
  evidence := []

/-- Run step H3-TRAF3IP2-IL17.3: TRAF3IP2 raises psoriasis risk. -/
def S6 : Statement where
  id := "S6"
  text := "TRAF3IP2 raises psoriasis risk"
  claim := .effect TRAF3IP2 .pos (.disease psoriasis)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6]

/-- H1-IL23-extracellular, claim 2: IL12B and IL23R drive psoriasis via extracellular IL-23 signaling. -/
def h1c2a1 := viaActivity (lit S1) (viaProcess (lit S2) (lit S3))

/-- H2-TYK2-intracellular, claim 1: TYK2 mediates intracellular signaling from the IL-23 receptor to drive psoriasis. -/
def h2c1a1 := viaProcess (lit S2) (lit S3)

/-- H3-TRAF3IP2-IL17, claim 1: TRAF3IP2 mediates downstream IL-17 receptor signaling in psoriasis. -/
def h3c1a1 := lit S6

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1-IL23-extracellular" "c2a1" h1c2a1,
    arm "H2-TYK2-intracellular" "c1a1" h2c1a1,
    arm "H3-TRAF3IP2-IL17" "c1a1" h3c1a1]

#eval printRows "study-2026-09-vertex-psoriasis-google-cloud-gemini-3.1-pro-preview-single_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_psoriasis_google_cloud_gemini_3_1_pro_preview_single_agent_r3
