import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-crohn-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-crohn-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r2`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, Crohn disease, genes IL12B, IL23R, NOD2, LACC1, GPR35, MEIS1, TRIM4. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_crohn_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def IL12B : Entity .protein := ⟨"UniProt:P29460", "IL12B"⟩
def IL23R : Entity .protein := ⟨"UniProt:Q5VWK5", "IL23R"⟩
def il23Complex : Entity .component := ⟨"GO:0070743", "interleukin-23 complex"⟩
def il23Signaling : Entity .process := ⟨"GO:0038155", "interleukin-23-mediated signaling pathway"⟩
def th17Response : Entity .process := ⟨"GO:0072538", "T-helper 17 type immune response"⟩
def crohn : Entity .disease := ⟨"MONDO:0005011", "Crohn disease"⟩
def NOD2 : Entity .protein := ⟨"UniProt:Q9HC29", "NOD2"⟩
def pgnDetection : Entity .process := ⟨"GO:0032499", "detection of peptidoglycan"⟩
def innateImmuneResponse : Entity .process := ⟨"GO:0045087", "innate immune response"⟩
def LACC1 : Entity .protein := ⟨"UniProt:Q8IV20", "LACC1"⟩
def cytokineProduction : Entity .process := ⟨"GO:0001816", "cytokine production"⟩
def macrophageDysfunction : Entity .phenotype := ⟨"UPHENO:0085601", "macrophage physiology phenotype"⟩
def GPR35 : Entity .protein := ⟨"UniProt:Q9HC97", "GPR35"⟩
def gpr35RiskVariants : Entity .variant := ⟨"BLN:GPR35-CrohnRiskVariants", "GPR35 Crohn disease risk variants (a class, no single ID; the run cites rs34236350 and rs3749171 with no allele named)"⟩

/-- Run step hyp1.2: the IL-23 complex activates IL-23-mediated signalling. -/
def S1 : Statement where
  id := "S1"
  text := "the IL-23 complex activates IL-23-mediated signalling"
  claim := .effect il23Complex .pos (.process il23Signaling)
  evidence := [
    { pmid := 0, year := 2026, ref := "P29460", kind := .curatedDb, note := "IL-23 binds to a heterodimeric receptor complex composed of IL12RB1 and IL23R, activates the Jak-Stat signaling cascade" },
    { pmid := 0, year := 2026, ref := "Q5VWK5", kind := .curatedDb, note := "Binds IL23 and mediates T-cells, NK cells and possibly certain macrophage/myeloid cells stimulation probably through activation of the Jak-Stat signaling cascade" }
  ]

/-- Run step hyp1.4: the Th17 immune response raises the risk of Crohn disease. -/
def S2 : Statement where
  id := "S2"
  text := "the Th17 immune response raises the risk of Crohn disease"
  claim := .effect th17Response .pos (.disease crohn)
  evidence := []

/-- Run step hyp2.1: NOD2 is required for detection of bacterial peptidoglycan. -/
def S3 : Statement where
  id := "S3"
  text := "NOD2 is required for detection of bacterial peptidoglycan"
  claim := .effect NOD2 .pos (.process pgnDetection)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC29", kind := .curatedDb, note := "Pattern recognition receptor (PRR) that detects bacterial peptidoglycan fragments" }
  ]

/-- Run step hyp2.2: detection of bacterial peptidoglycan activates the innate immune response. -/
def S4 : Statement where
  id := "S4"
  text := "detection of bacterial peptidoglycan activates the innate immune response"
  claim := .effect pgnDetection .pos (.process innateImmuneResponse)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC29", kind := .curatedDb, note := "6-O-phospho-MDP-binding triggers oligomerization that facilitates the binding and subsequent activation of the proximal adapter receptor-interacting RIPK2 (PubMed:11087742, PubMed:17355968, PubMed:21887730, PubMed:23806334, PubMed:28436939)" }
  ]

/-- Run step hyp2.3: LACC1 increases cytokine secretion (the run's increases_amount on a process, so a process target). -/
def S5 : Statement where
  id := "S5"
  text := "LACC1 increases cytokine secretion (the run's increases_amount on a process, so a process target)"
  claim := .effect LACC1 .pos (.process cytokineProduction)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8IV20", kind := .curatedDb, note := "associates with the NOD2-signaling complex and promotes optimal NOD2-induced signaling, cytokine secretion and bacterial clearance" },
    { pmid := 0, year := 2026, ref := "Q8IV20", kind := .curatedDb, polarity := .refutes, note := "Through L-ornithine controls cellular polyamine pools likely triggering polyamine-mediated proinflammatory cytokine suppression" }
  ]

/-- Run step hyp2.4: abnormal macrophage function raises the risk of Crohn disease (macrophage part of a compound subject). Sign: the run's subject is 'dysregulated', which has no direction; grounded as the abnormal-macrophage-function phenotype (the guide's 'abnormal X' rule, applied to a subject), effect pos as the run states. -/
def S6 : Statement where
  id := "S6"
  text := "abnormal macrophage function raises the risk of Crohn disease (macrophage part of a compound subject)"
  claim := .effect macrophageDysfunction .pos (.disease crohn)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6]

def rows : List Lean.Json :=
  statements.map statementRow ++ []

#eval printRows "study-2026-09-vertex-crohn-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_crohn_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r2
