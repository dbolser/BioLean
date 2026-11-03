import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-crohn-google-cloud-gemini-3.1-pro-preview-single_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-crohn-google-cloud-gemini-3.1-pro-preview-single_agent-r2`: google-cloud:gemini-3.1-pro-preview, Crohn disease, genes IL12B, IL23R, NOD2, LACC1, GPR35, MEIS1, TRIM4. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_crohn_google_cloud_gemini_3_1_pro_preview_single_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def IL12B : Entity .protein := ⟨"UniProt:P29460", "IL12B"⟩
def IL23R : Entity .protein := ⟨"UniProt:Q5VWK5", "IL23R"⟩
def NOD2 : Entity .protein := ⟨"UniProt:Q9HC29", "NOD2"⟩
def LACC1 : Entity .protein := ⟨"UniProt:Q8IV20", "LACC1"⟩
def GPR35 : Entity .protein := ⟨"UniProt:Q9HC97", "GPR35"⟩
def il23Signaling : Entity .process := ⟨"GO:0038155", "interleukin-23-mediated signaling pathway"⟩
def innateImmuneResponse : Entity .process := ⟨"GO:0045087", "innate immune response"⟩
def macrophageChemotaxis : Entity .process := ⟨"GO:0048246", "macrophage chemotaxis"⟩
def crohn : Entity .disease := ⟨"MONDO:0005011", "Crohn disease"⟩
def cd4AbTCell : Entity .cellType := ⟨"CL:0000624", "CD4-positive, alpha-beta T cell"⟩
def macrophage : Entity .cellType := ⟨"CL:0000235", "macrophage"⟩
def rs11209026 : Entity .variant := ⟨"dbSNP:rs11209026", "rs11209026 G allele (IL23R missense; GWAS Catalog risk allele for Crohn disease)"⟩
def rs2066847 : Entity .variant := ⟨"dbSNP:rs2066847", "rs2066847 T allele (NOD2 frameshift; GWAS Catalog risk allele for Crohn disease)"⟩
def rs3764147 : Entity .variant := ⟨"dbSNP:rs3764147", "rs3764147 G allele (LACC1 missense; GWAS Catalog risk allele for Crohn disease)"⟩

/-- Run step H1_IL23_axis.1: IL12B binds IL23R (run context: CD4-positive alpha-beta T cells, dropped). -/
def S1 : Statement where
  id := "S1"
  text := "IL12B binds IL23R (run context: CD4-positive alpha-beta T cells, dropped)"
  claim := .rel ⟨.ro, 2436, false⟩ IL12B IL23R
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:IL12B-IL23R", kind := .curatedDb, note := "STRING links IL12B and IL23R with combined score 0.99 (experimental 0.93, database 0.65, text-mining 0.46)" },
    { pmid := 0, year := 2026, ref := "P29460", kind := .curatedDb, note := "Associates with IL23A to form the IL-23 interleukin, a heterodimeric cytokine which functions in innate and adaptive immunity. IL-23 may constitute with IL-17 an acute response to infection in peripheral tissues. IL-23 binds to a heterodime" }
  ]

/-- Run step H1_IL23_axis.2: IL23R activates IL-23-mediated signaling (run context: CD4-positive alpha-beta T cells, dropped). -/
def S2 : Statement where
  id := "S2"
  text := "IL23R activates IL-23-mediated signaling (run context: CD4-positive alpha-beta T cells, dropped)"
  claim := .effect IL23R .pos (.process il23Signaling)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q5VWK5", kind := .curatedDb, note := "Binds IL23 and mediates T-cells, NK cells and possibly certain macrophage/myeloid cells stimulation probably through activation of the Jak-Stat signaling cascade" }
  ]

/-- Run step H1_IL23_axis.3: IL-23-mediated signaling raises Crohn disease risk. -/
def S3 : Statement where
  id := "S3"
  text := "IL-23-mediated signaling raises Crohn disease risk"
  claim := .effect il23Signaling .pos (.disease crohn)
  evidence := []

/-- Run step H2_NOD2_sensing.1: LACC1 binds NOD2 (run context: macrophage, dropped). -/
def S4 : Statement where
  id := "S4"
  text := "LACC1 binds NOD2 (run context: macrophage, dropped)"
  claim := .rel ⟨.ro, 2436, false⟩ LACC1 NOD2
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8IV20", kind := .curatedDb, note := "associates with the NOD2-signaling complex" },
    { pmid := 0, year := 2026, ref := "STRING:NOD2-LACC1", kind := .textMined, note := "STRING links NOD2 and LACC1 with combined score 0.70 (experimental 0.00, database 0.00, text-mining 0.69)" }
  ]

/-- Run step H2_NOD2_sensing.2: NOD2 activates the innate immune response (run context: macrophage, dropped). -/
def S5 : Statement where
  id := "S5"
  text := "NOD2 activates the innate immune response (run context: macrophage, dropped)"
  claim := .effect NOD2 .pos (.process innateImmuneResponse)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC29", kind := .curatedDb, note := "This in turn leads to the transcriptional activation of hundreds of genes involved in immune response" }
  ]

/-- Run step H2_NOD2_sensing.3: the innate immune response raises Crohn disease risk. -/
def S6 : Statement where
  id := "S6"
  text := "the innate immune response raises Crohn disease risk"
  claim := .effect innateImmuneResponse .pos (.disease crohn)
  evidence := []

/-- Run step H3_GPR35_macrophages.1: GPR35 promotes macrophage chemotaxis. -/
def S7 : Statement where
  id := "S7"
  text := "GPR35 promotes macrophage chemotaxis"
  claim := .effect GPR35 .pos (.process macrophageChemotaxis)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC97", kind := .crossSpecies, note := "In macrophages, activation by lysophosphatidic acid promotes GPR35-induced signaling with a distinct transcriptional profile characterized by TNF production associated with ERK and NF-kappa-B activation (By similarity). In turn, induces che", taxon := some Taxa.mouse }
  ]

/-- Run step H3_GPR35_macrophages.2: macrophage chemotaxis raises Crohn disease risk. -/
def S8 : Statement where
  id := "S8"
  text := "macrophage chemotaxis raises Crohn disease risk"
  claim := .effect macrophageChemotaxis .pos (.disease crohn)
  evidence := []

/-- Bridge, not in the run: IL12B, as a subunit of IL-23, drives IL-23-mediated signaling (the run's H1.1 is a binds step, which cannot compose). -/
def B1 : Statement where
  id := "B1"
  text := "IL12B, as a subunit of IL-23, drives IL-23-mediated signaling (the run's H1.1 is a binds step, which cannot compose)"
  claim := .effect IL12B .pos (.process il23Signaling)
  evidence := [
    { pmid := 0, year := 2026, ref := "P29460", kind := .curatedDb, note := "Associates with IL23A to form the IL-23 interleukin, a heterodimeric cytokine which functions in innate and adaptive immunity. IL-23 may constitute with IL-17 an acute response to infection in peripheral tissues. IL-23 binds to a heterodime" }
  ]

/-- Bridge, not in the run: LACC1 promotes NOD2 signaling (the run's H2.1 is a binds step, which cannot compose; its title says LACC1 enhances NOD2 sensing). -/
def B2 : Statement where
  id := "B2"
  text := "LACC1 promotes NOD2 signaling (the run's H2.1 is a binds step, which cannot compose; its title says LACC1 enhances NOD2 sensing)"
  claim := .effect LACC1 .pos (.activity NOD2)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8IV20", kind := .curatedDb, note := "associates with the NOD2-signaling complex and promotes optimal NOD2-induced signaling" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, B1, B2]

/-- H1_IL23_axis, claim 1: IL-23 receptor signaling drives intestinal inflammation.. -/
def h1c1a1 := viaProcess (lit B1) (lit S3)

/-- H1_IL23_axis, claim 2: IL-23 receptor signaling drives intestinal inflammation.. -/
def h1c2a1 := viaProcess (lit S2) (lit S3)

/-- H2_NOD2_sensing, claim 1: LACC1 enhances NOD2-mediated bacterial sensing and immune activation.. -/
def h2c1a1 := viaProcess (lit S5) (lit S6)

/-- H2_NOD2_sensing, claim 2: LACC1 enhances NOD2-mediated bacterial sensing and immune activation.. -/
def h2c2a1 := viaActivity (lit B2) (viaProcess (lit S5) (lit S6))

/-- H3_GPR35_macrophages, claim 1: GPR35 promotes macrophage chemotaxis and inflammation in the colon.. -/
def h3c1a1 := viaProcess (lit S7) (lit S8)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1_IL23_axis" "c1a1" h1c1a1,
    arm "H1_IL23_axis" "c2a1" h1c2a1,
    arm "H2_NOD2_sensing" "c1a1" h2c1a1,
    arm "H2_NOD2_sensing" "c2a1" h2c2a1,
    arm "H3_GPR35_macrophages" "c1a1" h3c1a1]

#eval printRows "study-2026-09-vertex-crohn-google-cloud-gemini-3.1-pro-preview-single_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_crohn_google_cloud_gemini_3_1_pro_preview_single_agent_r2
