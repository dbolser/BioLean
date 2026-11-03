import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-alzheimers-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-alzheimers-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, Alzheimer disease, genes TREM2, RNPS1, INPP5D, APOE, MS4A4A, LPIN2, PLCG2, ABI3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def alzheimers : Entity .disease := ⟨"MONDO:0004975", "Alzheimer disease"⟩
def TREM2 : Entity .protein := ⟨"UniProt:Q9NZC2", "TREM2"⟩
def PLCG2 : Entity .protein := ⟨"UniProt:P16885", "PLCG2"⟩
def ABI3 : Entity .protein := ⟨"UniProt:Q9P2A4", "ABI3"⟩
def MS4A4A : Entity .protein := ⟨"UniProt:Q96JQ5", "MS4A4A"⟩
def INPP5D : Entity .protein := ⟨"UniProt:Q92835", "INPP5D"⟩
def innateImmuneResponse : Entity .process := ⟨"GO:0045087", "innate immune response"⟩
def microglia : Entity .cellType := ⟨"CL:0000129", "microglial cell"⟩
def neuroinflammation : Entity .process := ⟨"GO:0150076", "neuroinflammatory response"⟩
def microglialInnateImmunity : Entity .process := innateImmuneResponse.inCtx { cellType := microglia }

/-- Run step hyp1.1: the microglial innate immune response lowers Alzheimer disease risk (the run: 'Microglial innate immune dysfunction leads to Alzheimer disease', polarity unknown). Sign: inverted: the run's subject is dysfunction (impairment, per its mechanism) of the response. The step's polarity is unknown; the direction is the run's own, from hyp1's mechanism ('impair microglial-mediated innate immunity ... accelerating . -/
def S1 : Statement where
  id := "S1"
  text := "the microglial innate immune response lowers Alzheimer disease risk (the run: 'Microglial innate immune dysfunction leads to Alzheimer disease', polarity unknown)"
  claim := .effect microglialInnateImmunity .neg (.disease alzheimers)
  evidence := [
    { pmid := 41785844, year := 2026, kind := .review, note := "dampening protective microglial responses and highlighting MS4A inhibition as a potential strategy to rejuvenate the brain's innate immune system in Alzheimer's disease" },
    { pmid := 28714976, year := 2017, kind := .observational, polarity := .refutes, note := "These genetic findings provide additional evidence that the microglia-mediated innate immune response contributes directly to the development of Alzheimer's disease" }
  ]

/-- Run step hyp2.1: MS4A4A restrains TREM2 signaling (first half of 'Dysregulated TREM2 signaling via MS4A4A'). Sign: the step says 'dysregulated' with polarity unknown; direction from PMID:41785844 ('restrain'), which agrees with the run's mechanism ('MS4A4A negatively regulates TREM2 signaling'). The text credits MS4A4A and MS4A6A acting 'cooperatively'. -/
def S2 : Statement where
  id := "S2"
  text := "MS4A4A restrains TREM2 signaling (first half of 'Dysregulated TREM2 signaling via MS4A4A')"
  claim := .effect MS4A4A .neg (.activity TREM2)
  evidence := [
    { pmid := 41785844, year := 2026, kind := .review, note := "MS4A4A and MS4A6A are microglia-expressed genes linked to Alzheimer's disease risk. In this issue of Neuron, Rosner et al.1 show that these proteins cooperatively restrain TREM2 signaling" }
  ]

/-- Run step hyp2.1: TREM2 signaling lowers Alzheimer disease risk (second half of 'Dysregulated TREM2 signaling via MS4A4A leads to Alzheimer disease'). Sign: the step says 'dysregulated' with polarity unknown; direction from PMID:41785844, which calls the microglial responses TREM2 signaling drives 'protective' in Alzheimer's disease. The direction rests on that one qualifier. -/
def S3 : Statement where
  id := "S3"
  text := "TREM2 signaling lowers Alzheimer disease risk (second half of 'Dysregulated TREM2 signaling via MS4A4A leads to Alzheimer disease')"
  claim := .effect TREM2 .neg (.disease alzheimers)
  evidence := [
    { pmid := 41785844, year := 2026, kind := .review, note := "restrain TREM2 signaling, dampening protective microglial responses and highlighting MS4A inhibition as a potential strategy to rejuvenate the brain's innate immune system in Alzheimer's disease" }
  ]

/-- Run step hyp3.1: INPP5D restrains the neuroinflammatory response (first half of 'Dysregulated inflammatory signaling via INPP5D repression'). Sign: inverted: the run's subject is INPP5D repression; 'dysregulated' and the unknown polarity give no sign, so the direction is PMID:41633359's (INPP5D deficiency promoted induction of proinflammatory cytokines), which agrees with the run's mec. -/
def S4 : Statement where
  id := "S4"
  text := "INPP5D restrains the neuroinflammatory response (first half of 'Dysregulated inflammatory signaling via INPP5D repression')"
  claim := .effect INPP5D .neg (.process neuroinflammation)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .mechanistic, note := "Microglial INPP5D deficiency cell-autonomously promoted RIPK1-mediated transcriptional induction of diverse LOAD risk genes, proinflammatory cytokines", taxon := some Taxa.mouse }
  ]

/-- Run step hyp3.1: the neuroinflammatory response raises Alzheimer disease risk (second half of 'Dysregulated inflammatory signaling via INPP5D repression leads to Alzheimer disease'). Sign: 'dysregulated' and the unknown polarity give no sign; direction from PMID:41633359 ('neuroinflammation for promoting ... LOAD'), a proposal from data on TDP-43 pathology, neuronal loss and motor dysfunction, not AD. LOAD taken as Alzheimer . -/
def S5 : Statement where
  id := "S5"
  text := "the neuroinflammatory response raises Alzheimer disease risk (second half of 'Dysregulated inflammatory signaling via INPP5D repression leads to Alzheimer disease')"
  claim := .effect neuroinflammation .pos (.disease alzheimers)
  evidence := [
    { pmid := 41633359, year := 2026, kind := .hypothesis, note := "Our data suggest that INPP5D functions as an intracellular rheostat in regulating RIPK1-mediated neuroinflammation for promoting aging-related neurodegenerative diseases, including LOAD" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5]

/-- hyp2, claim 1: MS4A4A-mediated suppression of TREM2 protective microglial function. -/
def h2c1a1 := viaActivity (lit S2) (lit S3)

/-- hyp2, claim 2: MS4A4A-mediated suppression of TREM2 protective microglial function. -/
def h2c2a1 := lit S3

/-- hyp3, claim 1: INPP5D-mediated regulation of neuroinflammatory signaling in Alzheimer disease. -/
def h3c1a1 := viaProcess (lit S4) (lit S5)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "hyp2" "c1a1" h2c1a1,
    arm "hyp2" "c2a1" h2c2a1,
    arm "hyp3" "c1a1" h3c1a1]

#eval printRows "study-2026-09-vertex-alzheimers-vertex-openai-deepseek-aideepseek-v3.2-maas-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_alzheimers_vertex_openai_deepseek_aideepseek_v3_2_maas_multi_agent_r2
