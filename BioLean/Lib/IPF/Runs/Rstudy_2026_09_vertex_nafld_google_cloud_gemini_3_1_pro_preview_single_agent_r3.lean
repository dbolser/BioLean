import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-nafld-google-cloud-gemini-3.1-pro-preview-single_agent-r3/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-nafld-google-cloud-gemini-3.1-pro-preview-single_agent-r3`: google-cloud:gemini-3.1-pro-preview, non-alcoholic fatty liver disease, genes PNPLA3, APOE, APOA5, LIPC, CMIP, RBM27, SMIM32. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_nafld_google_cloud_gemini_3_1_pro_preview_single_agent_r3

open BioLean BioLean.Lib.IPF Derivation

def PNPLA3 : Entity .protein := ⟨"UniProt:Q9NST1", "PNPLA3"⟩
def APOE : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def APOA5 : Entity .protein := ⟨"UniProt:Q6Q788", "APOA5"⟩
def LIPC : Entity .protein := ⟨"UniProt:P11150", "LIPC"⟩
def CMIP : Entity .protein := ⟨"UniProt:Q8IY22", "CMIP"⟩
def GBP2 : Entity .protein := ⟨"UniProt:P32456", "GBP2"⟩
def PPARG : Entity .protein := ⟨"UniProt:P37231", "PPARG"⟩
def CD36 : Entity .protein := ⟨"UniProt:P16671", "CD36"⟩
def tgMetabolism : Entity .process := ⟨"GO:0006641", "triglyceride metabolic process"⟩
def lipoproteinClearance : Entity .process := ⟨"GO:0034381", "plasma lipoprotein particle clearance"⟩
def nafld : Entity .disease := ⟨"MONDO:0013209", "metabolic dysfunction-associated steatotic liver disease"⟩

/-- Run step hypothesis_1.1: PNPLA3 is associated with NAFLD (the run writes it disease-first: NAFLD associated_with PNPLA3; unsigned). Sign: the step is unsigned; the cited GWAS rows give directions for single alleles (rs738408-T up, rs3747207-G down), not for PNPLA3 amount or activity, so the gene-level direction stays none. -/
def S1 : Statement where
  id := "S1"
  text := "PNPLA3 is associated with NAFLD (the run writes it disease-first: NAFLD associated_with PNPLA3; unsigned)"
  claim := .assoc PNPLA3 none (.disease nafld)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs738408", kind := .observational, note := "rs738408-T is associated with 'Nonalcoholic fatty liver disease' at p = 2e-271, beta 35.21 z score (increase) (mapped gene PNPLA3; study GCST90271622, PMID 37709864)" },
    { pmid := 0, year := 2026, ref := "rs3747207", kind := .observational, note := "rs3747207-G is associated with 'Metabolic dysfunction-associated steatotic liver disease (MTAG)' at p = 5e-128, beta 0.2312531 unit (decrease) [0.21-0.25] (mapped gene PNPLA3; study GCST90728570, PMID 41686896)" }
  ]

/-- Run step hypothesis_1.2: PNPLA3 activates triglyceride metabolic process (run context hepatocytes, liver: a setting, dropped). -/
def S2 : Statement where
  id := "S2"
  text := "PNPLA3 activates triglyceride metabolic process (run context hepatocytes, liver: a setting, dropped)"
  claim := .effect PNPLA3 .pos (.process tgMetabolism)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9NST1", kind := .curatedDb, note := "Additionally possesses low triacylglycerol lipase and CoA-independent acylglycerol transacylase activities and thus may play a role in acyl-chain remodeling of triglycerides" }
  ]

/-- Run step hypothesis_1.3: triglyceride metabolic process is associated with NAFLD (unsigned; run context liver dropped). -/
def S3 : Statement where
  id := "S3"
  text := "triglyceride metabolic process is associated with NAFLD (unsigned; run context liver dropped)"
  claim := .assoc tgMetabolism none (.disease nafld)
  evidence := []

/-- Run step hypothesis_2.1: APOA5 activates plasma lipoprotein particle clearance. -/
def S4 : Statement where
  id := "S4"
  text := "APOA5 activates plasma lipoprotein particle clearance"
  claim := .effect APOA5 .pos (.process lipoproteinClearance)
  evidence := []

/-- Run step hypothesis_2.2: APOE activates plasma lipoprotein particle clearance. -/
def S5 : Statement where
  id := "S5"
  text := "APOE activates plasma lipoprotein particle clearance"
  claim := .effect APOE .pos (.process lipoproteinClearance)
  evidence := [
    { pmid := 0, year := 2026, ref := "P02649", kind := .curatedDb, note := "A main function of APOE is to mediate lipoprotein clearance through the uptake of chylomicrons, VLDLs, and HDLs by hepatocytes" }
  ]

/-- Run step hypothesis_2.3: LIPC activates plasma lipoprotein particle clearance. -/
def S6 : Statement where
  id := "S6"
  text := "LIPC activates plasma lipoprotein particle clearance"
  claim := .effect LIPC .pos (.process lipoproteinClearance)
  evidence := []

/-- Run step hypothesis_2.4: plasma lipoprotein particle clearance is associated with NAFLD (unsigned; run context liver dropped). -/
def S7 : Statement where
  id := "S7"
  text := "plasma lipoprotein particle clearance is associated with NAFLD (unsigned; run context liver dropped)"
  claim := .assoc lipoproteinClearance none (.disease nafld)
  evidence := []

/-- Run step hypothesis_3.1: CMIP activates GBP2 (first part of the run's 'Gbp2-PPARγ-CD36 axis'). -/
def S8 : Statement where
  id := "S8"
  text := "CMIP activates GBP2 (first part of the run's 'Gbp2-PPARγ-CD36 axis')"
  claim := .effect CMIP .pos (.activity GBP2)
  evidence := []

/-- Run step hypothesis_3.1: CMIP activates PPARG (second part of the run's 'Gbp2-PPARγ-CD36 axis'). -/
def S9 : Statement where
  id := "S9"
  text := "CMIP activates PPARG (second part of the run's 'Gbp2-PPARγ-CD36 axis')"
  claim := .effect CMIP .pos (.activity PPARG)
  evidence := [
    { pmid := 36609599, year := 2023, kind := .mechanistic, note := "Pparγ and Cd36 expression levels were dramatically decreased in the livers of ob/ob mice administered siCmip", taxon := some Taxa.mouse }
  ]

/-- Run step hypothesis_3.1: CMIP activates CD36 (third part of the run's 'Gbp2-PPARγ-CD36 axis'). -/
def S10 : Statement where
  id := "S10"
  text := "CMIP activates CD36 (third part of the run's 'Gbp2-PPARγ-CD36 axis')"
  claim := .effect CMIP .pos (.activity CD36)
  evidence := [
    { pmid := 36609599, year := 2023, kind := .mechanistic, note := "Pparγ and Cd36 expression levels were dramatically decreased in the livers of ob/ob mice administered siCmip", taxon := some Taxa.mouse }
  ]

/-- Run step hypothesis_3.2: GBP2 is associated with NAFLD (higher in NAFLD liver). Sign: the step is unsigned; the direction is from PMID:36609599, cited for the step: Gbp2 expression is enhanced in human NAFLD liver. -/
def S11 : Statement where
  id := "S11"
  text := "GBP2 is associated with NAFLD (higher in NAFLD liver)"
  claim := .assoc GBP2 (some .pos) (.disease nafld)
  evidence := [
    { pmid := 36609599, year := 2023, kind := .observational, note := "Cmip and Gbp2 expression levels are enhanced in human liver tissues bearing NAFLD features" }
  ]

/-- Run step hypothesis_3.2: PPARG is associated with NAFLD (unsigned). -/
def S12 : Statement where
  id := "S12"
  text := "PPARG is associated with NAFLD (unsigned)"
  claim := .assoc PPARG none (.disease nafld)
  evidence := [
    { pmid := 36609599, year := 2023, kind := .mechanistic, note := "regulate the development of nonalcoholic fatty liver disease by controlling the Gbp2-Pparγ-CD36 axis", taxon := some Taxa.mouse }
  ]

/-- Run step hypothesis_3.2: CD36 is associated with NAFLD (unsigned). -/
def S13 : Statement where
  id := "S13"
  text := "CD36 is associated with NAFLD (unsigned)"
  claim := .assoc CD36 none (.disease nafld)
  evidence := [
    { pmid := 36609599, year := 2023, kind := .mechanistic, note := "regulate the development of nonalcoholic fatty liver disease by controlling the Gbp2-Pparγ-CD36 axis", taxon := some Taxa.mouse }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13]

/-- hypothesis_3, claim 1: Epigenetic regulation of CMIP alters the PPARγ-CD36 axis to drive hepatic steatosis.. -/
def h3c1a1 := viaActivity (lit S8) (fromAssoc (lit S11))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hypothesis_3" "c1a1" h3c1a1]

#eval printRows "study-2026-09-vertex-nafld-google-cloud-gemini-3.1-pro-preview-single_agent-r3" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_nafld_google_cloud_gemini_3_1_pro_preview_single_agent_r3
