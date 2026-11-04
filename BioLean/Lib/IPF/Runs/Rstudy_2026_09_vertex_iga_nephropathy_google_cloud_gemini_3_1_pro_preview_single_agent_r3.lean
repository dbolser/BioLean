import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-single_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-single_agent-r3`: google-cloud:gemini-3.1-pro-preview, IgA glomerulonephritis, genes TNFSF13, ITGAX, DEFA4, CFH, CARD9, OR4X1, ZNF174. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_google_cloud_gemini_3_1_pro_preview_single_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def TNFSF13 : Entity .protein := ⟨"UniProt:O75888", "TNFSF13"⟩
def IgA : Entity .protein := ⟨"PR:000050176", "IgA heavy chain protein"⟩
def igaNephropathy : Entity .disease := ⟨"MONDO:0005342", "IgA glomerulonephritis"⟩
def CFH : Entity .protein := ⟨"UniProt:P08603", "CFH"⟩
def complementActivation : Entity .process := ⟨"GO:0006956", "complement activation"⟩
def DEFA4 : Entity .protein := ⟨"UniProt:P12838", "DEFA4"⟩
def ITGAX : Entity .protein := ⟨"UniProt:P20702", "ITGAX"⟩
def CARD9 : Entity .protein := ⟨"UniProt:Q9H257", "CARD9"⟩
def innateImmuneResponse : Entity .process := ⟨"GO:0045087", "innate immune response"⟩

/-- Run step H1-TNFSF13-IgA.1: TNFSF13 (APRIL) raises the amount of IgA. -/
def S1 : Statement where
  id := "S1"
  text := "TNFSF13 (APRIL) raises the amount of IgA"
  claim := .effect TNFSF13 .pos (.amount IgA)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1916833:MP:0001807", kind := .curatedDb, note := "the genotype Tnfsf13<sup>tm1Geha</sup>/Tnfsf13<sup>tm1Geha</sup> of Tnfsf13 -- the orthologue of human TNFSF13 -- shows decreased IgA level", taxon := some Taxa.mouse }
  ]

/-- Run step H1-TNFSF13-IgA.2: IgA leads to IgA glomerulonephritis. -/
def S2 : Statement where
  id := "S2"
  text := "IgA leads to IgA glomerulonephritis"
  claim := .effect IgA .pos (.disease igaNephropathy)
  evidence := []

/-- Run step H2-CFH-Complement.1: CFH inhibits complement activation. -/
def S3 : Statement where
  id := "S3"
  text := "CFH inhibits complement activation"
  claim := .effect CFH .neg (.process complementActivation)
  evidence := [
    { pmid := 0, year := 2026, ref := "P08603", kind := .curatedDb, note := "Acts as a soluble inhibitor of complement, where its binding to self markers such as glycan structures prevents complement activation" }
  ]

/-- Run step H2-CFH-Complement.2: complement activation leads to IgA glomerulonephritis. -/
def S4 : Statement where
  id := "S4"
  text := "complement activation leads to IgA glomerulonephritis"
  claim := .effect complementActivation .pos (.disease igaNephropathy)
  evidence := [
    { pmid := 36316518, year := 2022, kind := .observational, note := "Increased retinal drusen in IgA glomerulonephritis are further evidence for complement activation in disease pathogenesis." }
  ]

/-- Run step H3-Innate-Mucosal-IgA.1: DEFA4 is associated with the innate immune response (no direction). Sign: run polarity 'unknown'; no cited text gives a direction. -/
def S5 : Statement where
  id := "S5"
  text := "DEFA4 is associated with the innate immune response (no direction)"
  claim := .assoc DEFA4 none (.process innateImmuneResponse)
  evidence := []

/-- Run step H3-Innate-Mucosal-IgA.2: ITGAX is associated with the innate immune response (no direction). Sign: run polarity 'unknown'; no cited text gives a direction. -/
def S6 : Statement where
  id := "S6"
  text := "ITGAX is associated with the innate immune response (no direction)"
  claim := .assoc ITGAX none (.process innateImmuneResponse)
  evidence := []

/-- Run step H3-Innate-Mucosal-IgA.3: more CARD9 goes with more innate immune response (CARD9 is essential for the antifungal innate response). Sign: run polarity 'unknown'; direction from the UniProt text cited for the step: CARD9 forms the signalling complexes of the innate immune response against fungi and its signals are 'essential for' antifungal immunity, the guide's required_for r. -/
def S7 : Statement where
  id := "S7"
  text := "more CARD9 goes with more innate immune response (CARD9 is essential for the antifungal innate response)"
  claim := .assoc CARD9 (some .pos) (.process innateImmuneResponse)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9H257", kind := .curatedDb, note := "plays a key role in innate immune response against fungi by forming signaling complexes downstream of C-type lectin receptors (PubMed:26961233, PubMed:33558980). CARD9-mediated signals are essential for antifungal immunity" }
  ]

/-- Run step H3-Innate-Mucosal-IgA.4: the innate immune response leads to IgA glomerulonephritis. -/
def S8 : Statement where
  id := "S8"
  text := "the innate immune response leads to IgA glomerulonephritis"
  claim := .effect innateImmuneResponse .pos (.disease igaNephropathy)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8]

/-- H1-TNFSF13-IgA, claim 1: Excess TNFSF13 promotes the overproduction of pathogenic IgA complexes that deposit in the kidney.. -/
def h1c1a1 := viaAmount (lit S1) (lit S2)

/-- H2-CFH-Complement, claim 1: Reduced Complement Factor H function unleashes destructive complement activation in the glomerulus.. -/
def h2c1a1 := viaProcess (lit S3) (lit S4)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1-TNFSF13-IgA" "c1a1" h1c1a1,
    arm "H2-CFH-Complement" "c1a1" h2c1a1]

#eval printRows "study-2026-09-vertex-iga-nephropathy-google-cloud-gemini-3.1-pro-preview-single_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_iga_nephropathy_google_cloud_gemini_3_1_pro_preview_single_agent_r3
