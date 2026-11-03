import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-dcm-google-cloud-gemini-3.1-pro-preview-single_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-dcm-google-cloud-gemini-3.1-pro-preview-single_agent-r2`: google-cloud:gemini-3.1-pro-preview, dilated cardiomyopathy, genes LMNA, MYH7, TTN, TNNT2, RBM20, ABCB9, OR8J3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_dcm_google_cloud_gemini_3_1_pro_preview_single_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def RBM20 : Entity .protein := ⟨"UniProt:Q5T481", "RBM20"⟩
def TTN : Entity .protein := ⟨"UniProt:Q8WZ42", "TTN"⟩
def TNNT2 : Entity .protein := ⟨"UniProt:P45379", "TNNT2"⟩
def MYH7 : Entity .protein := ⟨"UniProt:P12883", "MYH7"⟩
def LMNA : Entity .protein := ⟨"UniProt:P02545", "LMNA"⟩
def sarcomereOrganization : Entity .process := ⟨"GO:0045214", "sarcomere organization"⟩
def cardiacMuscleContraction : Entity .process := ⟨"GO:0060048", "cardiac muscle contraction"⟩
def nuclearEnvelopeOrganization : Entity .process := ⟨"GO:0006998", "nuclear envelope organization"⟩
def anatomicalStructureHomeostasis : Entity .process := ⟨"GO:0060249", "anatomical structure homeostasis"⟩
def heart : Entity .anatomy := ⟨"UBERON:0000948", "heart"⟩
def dcm : Entity .disease := ⟨"MONDO:0005021", "dilated cardiomyopathy"⟩
def cardiacHomeostasis : Entity .process := anatomicalStructureHomeostasis.inCtx { anatomy := heart }

/-- Run step hyp_1.1: RBM20 is required for TTN: losing RBM20 lowers TTN function (the run's note: RBM20 regulates TTN splicing). -/
def S1 : Statement where
  id := "S1"
  text := "RBM20 is required for TTN: losing RBM20 lowers TTN function (the run's note: RBM20 regulates TTN splicing)"
  claim := .effect RBM20 .pos (.activity TTN)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q5T481", kind := .curatedDb, note := "RBM20-mediated exon skipping is hormone-dependent and is essential for TTN isoform transition in both cardiac and skeletal muscles" }
  ]

/-- Run step hyp_1.2: TTN is required for sarcomere organization. -/
def S2 : Statement where
  id := "S2"
  text := "TTN is required for sarcomere organization"
  claim := .effect TTN .pos (.process sarcomereOrganization)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8WZ42", kind := .curatedDb, note := "Key component in the assembly and functioning of vertebrate striated muscles" }
  ]

/-- Run step hyp_1.3: sarcomere organization protects against dilated cardiomyopathy. -/
def S3 : Statement where
  id := "S3"
  text := "sarcomere organization protects against dilated cardiomyopathy"
  claim := .effect sarcomereOrganization .neg (.disease dcm)
  evidence := []

/-- Run step hyp_2.1: TNNT2 activates MYH7 (the run's note: TNNT2 confers calcium sensitivity to the actomyosin ATPase, of which MYH7 is the motor); the run's context, cardiac muscle cell, is dropped. -/
def S4 : Statement where
  id := "S4"
  text := "TNNT2 activates MYH7 (the run's note: TNNT2 confers calcium sensitivity to the actomyosin ATPase, of which MYH7 is the motor); the run's context, cardiac muscle cell, is dropped"
  claim := .effect TNNT2 .pos (.activity MYH7)
  evidence := []

/-- Run step hyp_2.2: MYH7 is required for cardiac muscle contraction (the run's 'cardiac muscle contractility'). -/
def S5 : Statement where
  id := "S5"
  text := "MYH7 is required for cardiac muscle contraction (the run's 'cardiac muscle contractility')"
  claim := .effect MYH7 .pos (.process cardiacMuscleContraction)
  evidence := [
    { pmid := 0, year := 2026, ref := "P12883", kind := .curatedDb, note := "Myosins are actin-based motor molecules with ATPase activity essential for muscle contraction. Forms regular bipolar thick filaments that, together with actin thin filaments, constitute the fundamental contractile unit of skeletal and cardi" }
  ]

/-- Run step hyp_2.3: cardiac muscle contraction protects against dilated cardiomyopathy. -/
def S6 : Statement where
  id := "S6"
  text := "cardiac muscle contraction protects against dilated cardiomyopathy"
  claim := .effect cardiacMuscleContraction .neg (.disease dcm)
  evidence := []

/-- Run step hyp_3.1: LMNA is required for nuclear envelope organization. -/
def S7 : Statement where
  id := "S7"
  text := "LMNA is required for nuclear envelope organization"
  claim := .effect LMNA .pos (.process nuclearEnvelopeOrganization)
  evidence := [
    { pmid := 0, year := 2026, ref := "P02545", kind := .curatedDb, note := "Lamins provide a framework for the nuclear envelope, bridging the nuclear envelope and chromatin, thereby playing an important role in nuclear assembly" }
  ]

/-- Run step hyp_3.2: nuclear envelope organization is required for cardiac homeostasis; the run's context, cardiac muscle cell, is dropped. -/
def S8 : Statement where
  id := "S8"
  text := "nuclear envelope organization is required for cardiac homeostasis; the run's context, cardiac muscle cell, is dropped"
  claim := .effect nuclearEnvelopeOrganization .pos (.process cardiacHomeostasis)
  evidence := []

/-- Run step hyp_3.3: cardiac homeostasis protects against dilated cardiomyopathy. -/
def S9 : Statement where
  id := "S9"
  text := "cardiac homeostasis protects against dilated cardiomyopathy"
  claim := .effect cardiacHomeostasis .neg (.disease dcm)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9]

/-- hyp_1, claim 1: RBM20 regulates TTN splicing to maintain sarcomere integrity. -/
def h1c1a1 := viaActivity (lit S1) (viaProcess (lit S2) (lit S3))

/-- hyp_1, claim 2: RBM20 regulates TTN splicing to maintain sarcomere integrity. -/
def h1c2a1 := viaProcess (lit S2) (lit S3)

/-- hyp_2, claim 1: TNNT2 regulates MYH7 actomyosin ATPase activity for cardiac contractility. -/
def h2c1a1 := viaActivity (lit S4) (viaProcess (lit S5) (lit S6))

/-- hyp_2, claim 2: TNNT2 regulates MYH7 actomyosin ATPase activity for cardiac contractility. -/
def h2c2a1 := viaProcess (lit S5) (lit S6)

/-- hyp_3, claim 1: LMNA maintains nuclear envelope integrity required for cardiac homeostasis. -/
def h3c1a1 := viaProcess (lit S7) (viaProcess (lit S8) (lit S9))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp_1" "c1a1" h1c1a1,
    arm "hyp_1" "c2a1" h1c2a1,
    arm "hyp_2" "c1a1" h2c1a1,
    arm "hyp_2" "c2a1" h2c2a1,
    arm "hyp_3" "c1a1" h3c1a1]

#eval printRows "study-2026-09-vertex-dcm-google-cloud-gemini-3.1-pro-preview-single_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_dcm_google_cloud_gemini_3_1_pro_preview_single_agent_r2
