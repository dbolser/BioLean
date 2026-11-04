import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-crohn-openrouter-openaigpt-5.6-sol-multi_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-crohn-openrouter-openaigpt-5.6-sol-multi_agent-r1`: openrouter:openai/gpt-5.6-sol, Crohn disease, genes IL12B, IL23R, NOD2, LACC1, GPR35, MEIS1, TRIM4. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_crohn_openrouter_openaigpt_5_6_sol_multi_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def IL12B : Entity .protein := ⟨"UniProt:P29460", "IL12B"⟩
def IL23R : Entity .protein := ⟨"UniProt:Q5VWK5", "IL23R"⟩
def il23Signaling : Entity .process := ⟨"GO:0038155", "interleukin-23-mediated signaling pathway"⟩
def crohn : Entity .disease := ⟨"MONDO:0005011", "Crohn disease"⟩
def mdp : Entity .chemical := ⟨"CHEBI:59414", "muramyl dipeptide"⟩
def NOD2 : Entity .protein := ⟨"UniProt:Q9HC29", "NOD2"⟩
def LACC1 : Entity .protein := ⟨"UniProt:Q8IV20", "LACC1"⟩
def nod2Defense : Entity .process := ⟨"GO:0045087", "innate immune response"⟩
def kynurenicAcid : Entity .chemical := ⟨"CHEBI:18344", "kynurenic acid"⟩
def GPR35 : Entity .protein := ⟨"UniProt:Q9HC97", "GPR35"⟩
def chemotaxis : Entity .process := ⟨"GO:0006935", "chemotaxis"⟩
def rs3749172 : Entity .variant := ⟨"dbSNP:rs3749172", "rs3749172 A allele (GPR35)"⟩

/-- Run step H1.1: IL-23 (the IL12B-encoded p40 subunit) binds the IL23R receptor complex. -/
def S1 : Statement where
  id := "S1"
  text := "IL-23 (the IL12B-encoded p40 subunit) binds the IL23R receptor complex"
  claim := .rel ⟨.ro, 2436, false⟩ IL12B IL23R
  evidence := [
    { pmid := 0, year := 2026, ref := "P29460", kind := .curatedDb, note := "IL-23 binds to a heterodimeric receptor complex composed of IL12RB1 and IL23R" },
    { pmid := 0, year := 2026, ref := "Q5VWK5", kind := .curatedDb, note := "Associates with IL12RB1 to form the interleukin-23 receptor. Binds IL23" },
    { pmid := 0, year := 2026, ref := "STRING:IL12B-IL23R", kind := .curatedDb, note := "STRING links IL12B and IL23R with combined score 0.99 (experimental 0.93, database 0.65, text-mining 0.46)." }
  ]

/-- Run step H1.2: the IL23R receptor complex activates IL-23 / JAK-STAT signaling. -/
def S2 : Statement where
  id := "S2"
  text := "the IL23R receptor complex activates IL-23 / JAK-STAT signaling"
  claim := .effect IL23R .pos (.process il23Signaling)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q5VWK5", kind := .curatedDb, note := "mediates T-cells, NK cells and possibly certain macrophage/myeloid cells stimulation probably through activation of the Jak-Stat signaling cascade" }
  ]

/-- Run step H1.3: persistent IL-23 signaling drives Crohn disease intestinal inflammation. -/
def S3 : Statement where
  id := "S3"
  text := "persistent IL-23 signaling drives Crohn disease intestinal inflammation"
  claim := .effect il23Signaling .pos (.disease crohn)
  evidence := []

/-- Run step H2.1: bacterial muramyl dipeptide activates NOD2. -/
def S4 : Statement where
  id := "S4"
  text := "bacterial muramyl dipeptide activates NOD2"
  claim := .effect mdp .pos (.activity NOD2)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC29", kind := .curatedDb, note := "Specifically activated by muramyl dipeptide (MDP), a fragment of bacterial peptidoglycan" }
  ]

/-- Run step H2.2: LACC1 promotes NOD2-complex signaling, cytokine secretion and bacterial clearance. -/
def S5 : Statement where
  id := "S5"
  text := "LACC1 promotes NOD2-complex signaling, cytokine secretion and bacterial clearance"
  claim := .effect LACC1 .pos (.process nod2Defense)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8IV20", kind := .curatedDb, note := "associates with the NOD2-signaling complex and promotes optimal NOD2-induced signaling, cytokine secretion and bacterial clearance" },
    { pmid := 27478939, year := 2016, kind := .inVitro, note := "FAMIN-dependent FAO controlled inflammasome activation, mitochondrial and NADPH-oxidase-dependent production of reactive oxygen species (ROS), and the bactericidal activity of macrophages" }
  ]

/-- Run step H2.3: loss of NOD2-LACC1 antibacterial defense leads to Crohn disease (the defense is protective). Sign: inverted: the run's subject is 'Reduced NOD2-LACC1 antibacterial defense', so the node is the defense process and defense →− Crohn risk. -/
def S6 : Statement where
  id := "S6"
  text := "loss of NOD2-LACC1 antibacterial defense leads to Crohn disease (the defense is protective)"
  claim := .effect nod2Defense .neg (.disease crohn)
  evidence := []

/-- Run step H3.1: kynurenic acid (and other ligands) activate GPR35. -/
def S7 : Statement where
  id := "S7"
  text := "kynurenic acid (and other ligands) activate GPR35"
  claim := .effect kynurenicAcid .pos (.activity GPR35)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC97", kind := .curatedDb, note := "binds to several ligands including the tryptophan metabolite kynurenic acid (KYNA), lysophosphatidic acid (LPA) or 5-hydroxyindoleacetic acid (5-HIAA) with high affinity, leading to rapid and transient activation of numerous intracellular s" }
  ]

/-- Run step H3.2: GPR35 signaling induces chemotaxis and inflammatory-cell recruitment. Sign: run polarity 'unknown'; the cited UniProt text gives the direction: GPR35 induces chemotaxis of macrophages. -/
def S8 : Statement where
  id := "S8"
  text := "GPR35 signaling induces chemotaxis and inflammatory-cell recruitment"
  claim := .effect GPR35 .pos (.process chemotaxis)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC97", kind := .crossSpecies, note := "activation by lysophosphatidic acid promotes GPR35-induced signaling with a distinct transcriptional profile characterized by TNF production associated with ERK and NF-kappa-B activation (By similarity). In turn, induces chemotaxis of macro" }
  ]

/-- Run step H3.3: the GPR35 risk allele rs3749172-A is associated with Crohn disease. -/
def S9 : Statement where
  id := "S9"
  text := "the GPR35 risk allele rs3749172-A is associated with Crohn disease"
  claim := .assoc rs3749172 (some .pos) (.disease crohn)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs3749172", kind := .observational, note := "rs3749172-A is associated with 'Crohn's disease' at p = 6e-11, odds ratio 1.45" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9]

/-- H1, claim 2: IL12B-containing IL-23 drives IL23R-dependent pathogenic cytokine signaling. -/
def h1c2a1 := viaProcess (lit S2) (lit S3)

/-- H2, claim 2: NOD2–LACC1 failure couples defective bacterial sensing to macrophage immunometabolic dysfunction. -/
def h2c2a1 := viaProcess (lit S5) (lit S6)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c2a1" h1c2a1,
    arm "H2" "c2a1" h2c2a1]

#eval printRows "study-2026-09-crohn-openrouter-openaigpt-5.6-sol-multi_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_crohn_openrouter_openaigpt_5_6_sol_multi_agent_r1
