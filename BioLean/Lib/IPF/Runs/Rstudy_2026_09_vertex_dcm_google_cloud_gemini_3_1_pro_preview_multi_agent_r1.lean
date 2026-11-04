import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-dcm-google-cloud-gemini-3.1-pro-preview-multi_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-dcm-google-cloud-gemini-3.1-pro-preview-multi_agent-r1`: google-cloud:gemini-3.1-pro-preview, dilated cardiomyopathy, genes LMNA, MYH7, TTN, TNNT2, RBM20, ABCB9, OR8J3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_dcm_google_cloud_gemini_3_1_pro_preview_multi_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def RBM20 : Entity .protein := ⟨"UniProt:Q5T481", "RBM20"⟩
def TTN : Entity .protein := ⟨"UniProt:Q8WZ42", "TTN"⟩
def MYH7 : Entity .protein := ⟨"UniProt:P12883", "MYH7"⟩
def TNNT2 : Entity .protein := ⟨"UniProt:P45379", "TNNT2"⟩
def LMNA : Entity .protein := ⟨"UniProt:P02545", "LMNA"⟩
def dcm : Entity .disease := ⟨"MONDO:0005021", "dilated cardiomyopathy"⟩
def cardiacMuscleContraction : Entity .process := ⟨"GO:0060048", "cardiac muscle contraction"⟩
def nuclearLamina : Entity .component := ⟨"GO:0005652", "nuclear lamina"⟩
def cardiomyocyte : Entity .cellType := ⟨"CL:0000746", "cardiac muscle cell"⟩

/-- Run step H1.1: RBM20 binds TTN (the run's note: TTN pre-mRNA, to regulate its splicing). -/
def S1 : Statement where
  id := "S1"
  text := "RBM20 binds TTN (the run's note: TTN pre-mRNA, to regulate its splicing)"
  claim := .rel ⟨.ro, 2436, false⟩ RBM20 TTN
  evidence := [
    { pmid := 0, year := 2026, ref := "Q5T481", kind := .curatedDb, note := "RNA-binding protein that acts as a regulator of mRNA splicing of a subset of genes encoding key structural proteins involved in cardiac development, such as TTN (Titin)" }
  ]

/-- Run step H1.2: RBM20 is associated with dilated cardiomyopathy. -/
def S2 : Statement where
  id := "S2"
  text := "RBM20 is associated with dilated cardiomyopathy"
  claim := .assoc RBM20 none (.disease dcm)
  evidence := [
    { pmid := 41817671, year := 2026, kind := .observational, note := "RBM20-related dilated cardiomyopathy" }
  ]

/-- Run step H1.3: TTN is associated with dilated cardiomyopathy. -/
def S3 : Statement where
  id := "S3"
  text := "TTN is associated with dilated cardiomyopathy"
  claim := .assoc TTN none (.disease dcm)
  evidence := [
    { pmid := 22335739, year := 2012, kind := .observational, note := "TTN truncating mutations are a common cause of dilated cardiomyopathy" }
  ]

/-- Run step H2.1: MYH7 binds TNNT2. -/
def S4 : Statement where
  id := "S4"
  text := "MYH7 binds TNNT2"
  claim := .rel ⟨.ro, 2436, false⟩ MYH7 TNNT2
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:MYH7-TNNT2", kind := .textMined, note := "STRING links MYH7 and TNNT2 with combined score 0.97 (experimental 0.11, database 0.00, text-mining 0.96)" }
  ]

/-- Run step H2.2: MYH7 binds TTN. -/
def S5 : Statement where
  id := "S5"
  text := "MYH7 binds TTN"
  claim := .rel ⟨.ro, 2436, false⟩ MYH7 TTN
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:MYH7-TTN", kind := .textMined, note := "STRING links MYH7 and TTN with combined score 0.96 (experimental 0.10, database 0.00, text-mining 0.92)" }
  ]

/-- Run step H2.3: TNNT2 binds TTN. -/
def S6 : Statement where
  id := "S6"
  text := "TNNT2 binds TTN"
  claim := .rel ⟨.ro, 2436, false⟩ TNNT2 TTN
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:TTN-TNNT2", kind := .textMined, note := "STRING links TTN and TNNT2 with combined score 0.86 (experimental 0.00, database 0.00, text-mining 0.84)" }
  ]

/-- Run step H2.4: MYH7 is required for cardiac muscle contraction (losing MYH7 lowers it). -/
def S7 : Statement where
  id := "S7"
  text := "MYH7 is required for cardiac muscle contraction (losing MYH7 lowers it)"
  claim := .effect MYH7 .pos (.process cardiacMuscleContraction)
  evidence := [
    { pmid := 0, year := 2026, ref := "P12883", kind := .curatedDb, note := "Myosins are actin-based motor molecules with ATPase activity essential for muscle contraction. Forms regular bipolar thick filaments that, together with actin thin filaments, constitute the fundamental contractile unit of skeletal and cardi" }
  ]

/-- Run step H2.5: MYH7 is associated with dilated cardiomyopathy. -/
def S8 : Statement where
  id := "S8"
  text := "MYH7 is associated with dilated cardiomyopathy"
  claim := .assoc MYH7 none (.disease dcm)
  evidence := []

/-- Run step H2.6: TNNT2 is associated with dilated cardiomyopathy. -/
def S9 : Statement where
  id := "S9"
  text := "TNNT2 is associated with dilated cardiomyopathy"
  claim := .assoc TNNT2 none (.disease dcm)
  evidence := [
    { pmid := 41969674, year := 2026, kind := .observational, note := "a sporadic case of dilated cardiomyopathy (DCM) associated with a TNNT2 variant" }
  ]

/-- Run step H3.2: LMNA is associated with dilated cardiomyopathy (the step's cardiomyocyte context is dropped). -/
def S10 : Statement where
  id := "S10"
  text := "LMNA is associated with dilated cardiomyopathy (the step's cardiomyocyte context is dropped)"
  claim := .assoc LMNA none (.disease dcm)
  evidence := [
    { pmid := 0, year := 2026, ref := "PMID:PPR1285401", kind := .review, note := "LMNA R541C variant associated with dilated cardiomyopathy" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10]

/-- H2, claim 4: Sarcomeric structural proteins physically interact to maintain cardiac contraction. -/
def h2c4a1 := lit S7

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H2" "c4a1" h2c4a1]

#eval printRows "study-2026-09-vertex-dcm-google-cloud-gemini-3.1-pro-preview-multi_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_dcm_google_cloud_gemini_3_1_pro_preview_multi_agent_r1
