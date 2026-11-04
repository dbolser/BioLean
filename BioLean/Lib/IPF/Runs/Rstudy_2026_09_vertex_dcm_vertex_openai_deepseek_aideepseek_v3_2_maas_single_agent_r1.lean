import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-vertex-dcm-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-vertex-dcm-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1`: vertex-openai:deepseek-ai/deepseek-v3.2-maas, dilated cardiomyopathy, genes LMNA, MYH7, TTN, TNNT2, RBM20, ABCB9, OR8J3. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_dcm_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def dcm : Entity .disease := ⟨"MONDO:0005021", "dilated cardiomyopathy"⟩
def LMNA : Entity .protein := ⟨"UniProt:P02545", "LMNA"⟩
def lmnaVariants : Entity .variant := ⟨"BLN:LMNA-pathogenic-variants", "pathogenic LMNA variants"⟩
def nuclearIntegrity : Entity .phenotype := ⟨"BLN:NuclearMechanicalIntegrity", "nuclear mechanical integrity"⟩
def ttnVariants : Entity .variant := ⟨"BLN:TTN-pathogenic-variants", "pathogenic TTN variants"⟩
def myh7Variants : Entity .variant := ⟨"BLN:MYH7-pathogenic-variants", "pathogenic MYH7 variants"⟩
def tnnt2Variants : Entity .variant := ⟨"BLN:TNNT2-pathogenic-variants", "pathogenic TNNT2 variants"⟩
def MYH7 : Entity .protein := ⟨"UniProt:P12883", "MYH7"⟩
def TTN : Entity .protein := ⟨"UniProt:Q8WZ42", "TTN"⟩
def TNNT2 : Entity .protein := ⟨"UniProt:P45379", "TNNT2"⟩
def sarcomereOrganization : Entity .process := ⟨"GO:0045214", "sarcomere organization"⟩
def muscleContraction : Entity .process := ⟨"GO:0006936", "muscle contraction"⟩
def cardiomyocyte : Entity .cellType := ⟨"CL:0000746", "cardiac muscle cell"⟩
def RBM20 : Entity .protein := ⟨"UniProt:Q5T481", "RBM20"⟩
def rbm20Variants : Entity .variant := ⟨"BLN:RBM20-pathogenic-variants", "pathogenic RBM20 variants"⟩
def altSplicing : Entity .process := ⟨"GO:0000380", "alternative mRNA splicing, via spliceosome"⟩
def abnormalTtnIsoforms : Entity .phenotype := ⟨"BLN:AbnormalTitinIsoformExpression", "abnormal titin (TTN) isoform expression from mis-splicing of TTN"⟩

/-- Run step h1.1: LMNA (lamin A/C) is required for nuclear mechanical integrity; required_for read as pos. -/
def s_h1_1 : Statement where
  id := "s_h1_1"
  text := "LMNA (lamin A/C) is required for nuclear mechanical integrity; required_for read as pos"
  claim := .effect LMNA .pos (.phenotype nuclearIntegrity)
  evidence := [
    { pmid := 0, year := 2026, ref := "P02545", kind := .curatedDb, note := "Lamin A and C also regulate matrix stiffness by conferring nuclear mechanical properties" }
  ]

/-- Run step h1.2: pathogenic LMNA variants cause dilated cardiomyopathy. -/
def s_h1_2 : Statement where
  id := "s_h1_2"
  text := "pathogenic LMNA variants cause dilated cardiomyopathy"
  claim := .effect lmnaVariants .pos (.disease dcm)
  evidence := [
    { pmid := 42373902, year := 2026, kind := .review, note := "Mutations in LMNA, which encodes the nuclear envelope protein lamin A/C, cause laminopathies that frequently present as dilated cardiomyopathy" },
    { pmid := 0, year := 2026, ref := "GWAS:LMNA:no-association", kind := .observational, polarity := .refutes, note := "reports no association between any LMNA variant and dilated cardiomyopathy" }
  ]

/-- Run step h2.1: MYH7 is required for sarcomere organization (assembly); required_for read as pos; the MYH7 member of the list, assembly part of the compound object. -/
def s_h2_1_myh7_sarc : Statement where
  id := "s_h2_1_myh7_sarc"
  text := "MYH7 is required for sarcomere organization (assembly); required_for read as pos; the MYH7 member of the list, assembly part of the compound object"
  claim := .effect MYH7 .pos (.process sarcomereOrganization)
  evidence := []

/-- Run step h2.1: MYH7 is required for muscle contraction; required_for read as pos; the MYH7 member of the list, contraction part of the compound object. -/
def s_h2_1_myh7_contr : Statement where
  id := "s_h2_1_myh7_contr"
  text := "MYH7 is required for muscle contraction; required_for read as pos; the MYH7 member of the list, contraction part of the compound object"
  claim := .effect MYH7 .pos (.process muscleContraction)
  evidence := [
    { pmid := 0, year := 2026, ref := "P12883", kind := .curatedDb, note := "Myosins are actin-based motor molecules with ATPase activity essential for muscle contraction" }
  ]

/-- Run step h2.1: TNNT2 is required for sarcomere organization (assembly); required_for read as pos; the TNNT2 member of the list, assembly part of the compound object. -/
def s_h2_1_tnnt2_sarc : Statement where
  id := "s_h2_1_tnnt2_sarc"
  text := "TNNT2 is required for sarcomere organization (assembly); required_for read as pos; the TNNT2 member of the list, assembly part of the compound object"
  claim := .effect TNNT2 .pos (.process sarcomereOrganization)
  evidence := []

/-- Run step h2.1: TNNT2 is required for muscle contraction; required_for read as pos; the TNNT2 member of the list, contraction part of the compound object. -/
def s_h2_1_tnnt2_contr : Statement where
  id := "s_h2_1_tnnt2_contr"
  text := "TNNT2 is required for muscle contraction; required_for read as pos; the TNNT2 member of the list, contraction part of the compound object"
  claim := .effect TNNT2 .pos (.process muscleContraction)
  evidence := []

/-- Run step h2.1: TTN is required for sarcomere organization (assembly); required_for read as pos; the TTN member of the list, assembly part of the compound object. -/
def s_h2_1_ttn_sarc : Statement where
  id := "s_h2_1_ttn_sarc"
  text := "TTN is required for sarcomere organization (assembly); required_for read as pos; the TTN member of the list, assembly part of the compound object"
  claim := .effect TTN .pos (.process sarcomereOrganization)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8WZ42", kind := .curatedDb, note := "Key component in the assembly and functioning of vertebrate striated muscles" }
  ]

/-- Run step h2.1: TTN is required for muscle contraction; required_for read as pos; the TTN member of the list, contraction part of the compound object. -/
def s_h2_1_ttn_contr : Statement where
  id := "s_h2_1_ttn_contr"
  text := "TTN is required for muscle contraction; required_for read as pos; the TTN member of the list, contraction part of the compound object"
  claim := .effect TTN .pos (.process muscleContraction)
  evidence := []

/-- Run step h2.2: pathogenic TTN variants cause dilated cardiomyopathy (the TTN member of 'sarcomere gene variants'). -/
def s_h2_2_ttn : Statement where
  id := "s_h2_2_ttn"
  text := "pathogenic TTN variants cause dilated cardiomyopathy (the TTN member of 'sarcomere gene variants')"
  claim := .effect ttnVariants .pos (.disease dcm)
  evidence := [
    { pmid := 22335739, year := 2012, kind := .observational, note := "TTN truncating mutations are a common cause of dilated cardiomyopathy" }
  ]

/-- Run step h2.2: pathogenic MYH7 variants cause dilated cardiomyopathy (the MYH7 member of 'sarcomere gene variants'). -/
def s_h2_2_myh7 : Statement where
  id := "s_h2_2_myh7"
  text := "pathogenic MYH7 variants cause dilated cardiomyopathy (the MYH7 member of 'sarcomere gene variants')"
  claim := .effect myh7Variants .pos (.disease dcm)
  evidence := [
    { pmid := 0, year := 2026, ref := "GWAS:MYH7:no-association", kind := .observational, polarity := .refutes, note := "reports no association between any MYH7 variant and dilated cardiomyopathy" }
  ]

/-- Run step h2.2: pathogenic TNNT2 variants cause dilated cardiomyopathy (the TNNT2 member of 'sarcomere gene variants'). -/
def s_h2_2_tnnt2 : Statement where
  id := "s_h2_2_tnnt2"
  text := "pathogenic TNNT2 variants cause dilated cardiomyopathy (the TNNT2 member of 'sarcomere gene variants')"
  claim := .effect tnnt2Variants .pos (.disease dcm)
  evidence := [
    { pmid := 0, year := 2026, ref := "GWAS:TNNT2:no-association", kind := .observational, polarity := .refutes, note := "reports no association between any TNNT2 variant and dilated cardiomyopathy" }
  ]

/-- Run step h2.3: MYH7 is expressed in cardiomyocytes (the run's 'associated_with cardiomyocytes', polarity unknown; its note says expression). -/
def s_h2_3_myh7 : Statement where
  id := "s_h2_3_myh7"
  text := "MYH7 is expressed in cardiomyocytes (the run's 'associated_with cardiomyocytes', polarity unknown; its note says expression)"
  claim := .rel ⟨.ro, 2206, false⟩ MYH7 cardiomyocyte
  evidence := [
    { pmid := 0, year := 2026, ref := "HPA:ENSG00000092054", kind := .observational, note := "Single-cell: Cardiomyocytes 2902.2 nCPM" }
  ]

/-- Run step h2.3: TNNT2 is expressed in cardiomyocytes (the run's 'associated_with cardiomyocytes', polarity unknown; its note says expression). -/
def s_h2_3_tnnt2 : Statement where
  id := "s_h2_3_tnnt2"
  text := "TNNT2 is expressed in cardiomyocytes (the run's 'associated_with cardiomyocytes', polarity unknown; its note says expression)"
  claim := .rel ⟨.ro, 2206, false⟩ TNNT2 cardiomyocyte
  evidence := [
    { pmid := 0, year := 2026, ref := "HPA:ENSG00000118194", kind := .observational, note := "Single-cell: Cardiomyocytes 198.7 nCPM" }
  ]

/-- Run step h2.3: TTN is expressed in cardiomyocytes (the run's 'associated_with cardiomyocytes', polarity unknown; its note says expression). -/
def s_h2_3_ttn : Statement where
  id := "s_h2_3_ttn"
  text := "TTN is expressed in cardiomyocytes (the run's 'associated_with cardiomyocytes', polarity unknown; its note says expression)"
  claim := .rel ⟨.ro, 2206, false⟩ TTN cardiomyocyte
  evidence := [
    { pmid := 0, year := 2026, ref := "HPA:ENSG00000155657", kind := .observational, note := "Single-cell: Cardiomyocytes 24623.7 nCPM" }
  ]

/-- Run step h3.1: RBM20 is required for (TTN) alternative splicing; required_for read as pos; the TTN qualifier is dropped because no field can restrict a process to one gene's transcripts. -/
def s_h3_1 : Statement where
  id := "s_h3_1"
  text := "RBM20 is required for (TTN) alternative splicing; required_for read as pos; the TTN qualifier is dropped because no field can restrict a process to one gene's transcripts"
  claim := .effect RBM20 .pos (.process altSplicing)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q5T481", kind := .curatedDb, note := "RBM20-mediated exon skipping is hormone-dependent and is essential for TTN isoform transition in both cardiac and skeletal muscles" }
  ]

/-- Run step h3.3: abnormal TTN splicing (abnormal TTN isoform expression) leads to dilated cardiomyopathy. -/
def s_h3_3 : Statement where
  id := "s_h3_3"
  text := "abnormal TTN splicing (abnormal TTN isoform expression) leads to dilated cardiomyopathy"
  claim := .effect abnormalTtnIsoforms .pos (.disease dcm)
  evidence := []

/-- Run step h3.4: RBM20 is expressed in cardiomyocytes (the run's 'associated_with cardiomyocytes', polarity unknown; its note says expression). -/
def s_h3_4 : Statement where
  id := "s_h3_4"
  text := "RBM20 is expressed in cardiomyocytes (the run's 'associated_with cardiomyocytes', polarity unknown; its note says expression)"
  claim := .rel ⟨.ro, 2206, false⟩ RBM20 cardiomyocyte
  evidence := [
    { pmid := 0, year := 2026, ref := "HPA:ENSG00000203867", kind := .observational, note := "Single-cell: Cardiomyocytes 2187.7 nCPM" }
  ]

def statements : List Statement := [s_h1_1, s_h1_2, s_h2_1_myh7_sarc, s_h2_1_myh7_contr, s_h2_1_tnnt2_sarc, s_h2_1_tnnt2_contr, s_h2_1_ttn_sarc, s_h2_1_ttn_contr, s_h2_2_ttn, s_h2_2_myh7, s_h2_2_tnnt2, s_h2_3_myh7, s_h2_3_tnnt2, s_h2_3_ttn, s_h3_1, s_h3_3, s_h3_4]

/-- h1, claim 1: Nuclear lamina disruption through LMNA mutations causes cardiomyocyte fragility and dilated cardiomyopathy. -/
def h1c1a1 := lit s_h1_2

/-- h2, claim 1: Sarcomere assembly disruption through MYH7, TTN, and TNNT2 mutations impairs cardiac contractility and causes dilated cardiomyopathy. -/
def h2c1a1 := lit s_h2_2_ttn

/-- h2, claim 2: Sarcomere assembly disruption through MYH7, TTN, and TNNT2 mutations impairs cardiac contractility and causes dilated cardiomyopathy. -/
def h2c2a1 := lit s_h2_2_myh7

/-- h2, claim 3: Sarcomere assembly disruption through MYH7, TTN, and TNNT2 mutations impairs cardiac contractility and causes dilated cardiomyopathy. -/
def h2c3a1 := lit s_h2_2_tnnt2

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "h1" "c1a1" h1c1a1,
    arm "h2" "c1a1" h2c1a1,
    arm "h2" "c2a1" h2c2a1,
    arm "h2" "c3a1" h2c3a1]

#eval printRows "study-2026-09-vertex-dcm-vertex-openai-deepseek-aideepseek-v3.2-maas-single_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_vertex_dcm_vertex_openai_deepseek_aideepseek_v3_2_maas_single_agent_r1
