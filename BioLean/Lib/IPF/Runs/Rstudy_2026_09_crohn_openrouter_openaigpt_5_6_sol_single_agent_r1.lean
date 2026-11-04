import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-crohn-openrouter-openaigpt-5.6-sol-single_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-crohn-openrouter-openaigpt-5.6-sol-single_agent-r1`: openrouter:openai/gpt-5.6-sol, Crohn disease, genes IL12B, IL23R, NOD2, LACC1, GPR35, MEIS1, TRIM4. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_crohn_openrouter_openaigpt_5_6_sol_single_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def il12b : Entity .protein := ⟨"UniProt:P29460", "IL12B"⟩
def il23r : Entity .protein := ⟨"UniProt:Q5VWK5", "IL23R"⟩
def il23signaling : Entity .process := ⟨"Reactome:R-HSA-9020933", "Interleukin-23 signaling (IL23R receptor-complex activation)"⟩
def th17commit : Entity .process := ⟨"GO:2000330", "positive regulation of T-helper 17 cell lineage commitment"⟩
def il17production : Entity .process := ⟨"GO:0032740", "positive regulation of interleukin-17 production"⟩
def crohn : Entity .disease := ⟨"MONDO:0005011", "Crohn disease"⟩
def mdp : Entity .chemical := ⟨"CHEBI:59414", "muramyl dipeptide"⟩
def nod2signaling : Entity .process := ⟨"GO:0070431", "nucleotide-binding oligomerization domain containing 2 signaling pathway"⟩
def autophagy : Entity .process := ⟨"GO:0006914", "autophagy"⟩
def nod2 : Entity .protein := ⟨"UniProt:Q9HC29", "NOD2"⟩
def lacc1 : Entity .protein := ⟨"UniProt:Q8IV20", "LACC1"⟩
def innateImmune : Entity .process := ⟨"GO:0045087", "innate immune response"⟩
def kyna : Entity .chemical := ⟨"CHEBI:18344", "kynurenic acid"⟩
def gpr35 : Entity .protein := ⟨"UniProt:Q9HC97", "GPR35"⟩
def inflammatoryResponse : Entity .process := ⟨"GO:0006954", "inflammatory response"⟩

/-- Run step H1.1: IL12B-containing IL-23 activates the IL23R receptor complex / IL-23 signaling. -/
def S1 : Statement where
  id := "S1"
  text := "IL12B-containing IL-23 activates the IL23R receptor complex / IL-23 signaling"
  claim := .effect il12b .pos (.process il23signaling)
  evidence := [
    { pmid := 0, year := 2026, ref := "P29460", kind := .curatedDb, note := "IL-23 binds to a heterodimeric receptor complex composed of IL12RB1 and IL23R, activates the Jak-Stat signaling cascade" },
    { pmid := 0, year := 2026, ref := "Q5VWK5", kind := .curatedDb, note := "Binds IL23 and mediates T-cells, NK cells and possibly certain macrophage/myeloid cells stimulation probably through activation of the Jak-Stat signaling cascade" }
  ]

/-- Run step H1.2: IL-23 signaling drives T-helper 17 lineage commitment (compound object, part 1). -/
def S2 : Statement where
  id := "S2"
  text := "IL-23 signaling drives T-helper 17 lineage commitment (compound object, part 1)"
  claim := .effect il23signaling .pos (.process th17commit)
  evidence := []

/-- Run step H1.2: IL-23 signaling drives IL-17 production (compound object, part 2). -/
def S3 : Statement where
  id := "S3"
  text := "IL-23 signaling drives IL-17 production (compound object, part 2)"
  claim := .effect il23signaling .pos (.process il17production)
  evidence := []

/-- Run step H1.3: persistent IL-23-responsive T-cell inflammation leads to Crohn disease. -/
def S4 : Statement where
  id := "S4"
  text := "persistent IL-23-responsive T-cell inflammation leads to Crohn disease"
  claim := .effect il17production .pos (.disease crohn)
  evidence := []

/-- Run step H2.1: bacterial muramyl dipeptide activates NOD2/RIPK2 signaling (compound object, part 1). -/
def S5 : Statement where
  id := "S5"
  text := "bacterial muramyl dipeptide activates NOD2/RIPK2 signaling (compound object, part 1)"
  claim := .effect mdp .pos (.process nod2signaling)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC29", kind := .curatedDb, note := "Specifically activated by muramyl dipeptide (MDP), a fragment of bacterial peptidoglycan found in every bacterial peptidoglycan type" }
  ]

/-- Run step H2.1: bacterial muramyl dipeptide / NOD2 promotes autophagy (compound object, part 2). -/
def S6 : Statement where
  id := "S6"
  text := "bacterial muramyl dipeptide / NOD2 promotes autophagy (compound object, part 2)"
  claim := .effect mdp .pos (.process autophagy)
  evidence := []

/-- Run step H2.2: LACC1 (FAMIN) promotes NOD2 signaling, macrophage metabolism, autophagy and bacterial clearance. -/
def S7 : Statement where
  id := "S7"
  text := "LACC1 (FAMIN) promotes NOD2 signaling, macrophage metabolism, autophagy and bacterial clearance"
  claim := .effect lacc1 .pos (.process innateImmune)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8IV20", kind := .curatedDb, note := "associates with the NOD2-signaling complex and promotes optimal NOD2-induced signaling, cytokine secretion and bacterial clearance" }
  ]

/-- Run step H2.3: NOD2-LACC1 microbial clearance lowers Crohn risk (run step: impaired clearance raises it). Sign: inverted: the run's subject is impaired (loss of) NOD2-LACC1 microbial clearance leading to Crohn (+); the entity is the clearance/innate-immune process and the sign flips to neg. -/
def S8 : Statement where
  id := "S8"
  text := "NOD2-LACC1 microbial clearance lowers Crohn risk (run step: impaired clearance raises it)"
  claim := .effect innateImmune .neg (.disease crohn)
  evidence := []

/-- Run step H3.1: kynurenic acid activates GPR35 G-protein signaling. Sign: run polarity is 'unknown'; the cited UniProt Q9HC97 states the ligand activates GPR35 signaling, so pos. Run subject is compound (kynurenic acid and 5-HIAA), grounded to kynurenic acid; 5-HIAA dropped. -/
def S9 : Statement where
  id := "S9"
  text := "kynurenic acid activates GPR35 G-protein signaling"
  claim := .effect kyna .pos (.activity gpr35)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC97", kind := .curatedDb, note := "binds to several ligands including the tryptophan metabolite kynurenic acid (KYNA), lysophosphatidic acid (LPA) or 5-hydroxyindoleacetic acid (5-HIAA) with high affinity, leading to rapid and transient activation of numerous intracellular s" }
  ]

/-- Run step H3.3: GPR35 is associated with Crohn disease (direction unresolved: risk and protective alleles both reported). -/
def S10 : Statement where
  id := "S10"
  text := "GPR35 is associated with Crohn disease (direction unresolved: risk and protective alleles both reported)"
  claim := .assoc gpr35 none (.disease crohn)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs3749172", kind := .observational, note := "rs3749172-A is associated with 'Crohn's disease' at p = 6e-11, odds ratio 1.45" },
    { pmid := 0, year := 2026, ref := "rs34236350", kind := .observational, note := "rs34236350-? is associated with 'Crohn's disease' at p = 1e-32, beta 0.1795 unit (increase)" },
    { pmid := 0, year := 2026, ref := "rs2975780", kind := .observational, note := "rs2975780-A is associated with 'Crohn's disease' at p = 6e-19, odds ratio 0.71" },
    { pmid := 0, year := 2026, ref := "AGR:MGI:1929509:MP:0008537", kind := .curatedDb, polarity := .refutes, note := "of Gpr35 -- the orthologue of human GPR35 -- shows increased susceptibility to induced colitis", taxon := some Taxa.mouse }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10]

/-- H1, claim 1: IL12B-containing IL-23 activates IL23R-positive intestinal T cells to sustain pathogenic Th17 inflammation. -/
def h1c1a1 := viaProcess (lit S1) (viaProcess (lit S3) (lit S4))

/-- H2, claim 2: NOD2 and LACC1 couple bacterial sensing to macrophage metabolism, autophagy, and clearance. -/
def h2c2a1 := viaProcess (lit S7) (lit S8)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H2" "c2a1" h2c2a1]

#eval printRows "study-2026-09-crohn-openrouter-openaigpt-5.6-sol-single_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_crohn_openrouter_openaigpt_5_6_sol_single_agent_r1
