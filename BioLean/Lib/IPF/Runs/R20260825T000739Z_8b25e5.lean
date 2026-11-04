import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260825T000739Z-8b25e5/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260825T000739Z-8b25e5`: openai:gpt-5.6-sol, Alzheimer's disease, genes TREM2, RNPS1, INPP5D, APOE, MS4A4A, LPIN2, PLCG2, ABI3. -/

namespace BioLean.Lib.IPF.Runs.R20260825T000739Z_8b25e5

open BioLean BioLean.Lib.IPF Derivation

def trem2 : Entity .protein := ⟨"UniProt:Q9NZC2", "TREM2"⟩
def plcg2 : Entity .protein := ⟨"UniProt:P16885", "PLCG2"⟩
def inpp5d : Entity .protein := ⟨"UniProt:Q92835", "INPP5D"⟩
def apoe : Entity .protein := ⟨"UniProt:P02649", "APOE"⟩
def abi3 : Entity .protein := ⟨"UniProt:Q9P2A4", "ABI3"⟩
def ms4a4a : Entity .protein := ⟨"UniProt:Q96JQ5", "MS4A4A"⟩
def ad : Entity .disease := ⟨"MONDO:0004975", "Alzheimer disease"⟩
def plaqueCompaction : Entity .phenotype := ⟨"BLN:AmyloidPlaqueCompaction", "amyloid plaque compaction"⟩
def synapseLoss : Entity .phenotype := ⟨"MP:0015055", "decreased synapse density"⟩
def plaqueBarrier : Entity .process := ⟨"BLN:MicroglialPlaqueBarrier", "organized microglial barrier around amyloid plaques"⟩
def apoeE4 : Entity .variant := ⟨"BLN:APOE-e4", "APOE ε4 allele"⟩
def rs75932628 : Entity .variant := ⟨"dbSNP:rs75932628", "rs75932628 T allele (TREM2)"⟩
def rs72824905 : Entity .variant := ⟨"dbSNP:rs72824905", "rs72824905 G allele (PLCG2)"⟩
def rs10933431 : Entity .variant := ⟨"dbSNP:rs10933431", "rs10933431 G allele (INPP5D)"⟩
def rs28394864 : Entity .variant := ⟨"dbSNP:rs28394864", "rs28394864 A allele (ABI3, author-reported gene)"⟩
def rs616338 : Entity .variant := ⟨"dbSNP:rs616338", "rs616338 T allele (ABI3)"⟩
def rs4938933 : Entity .variant := ⟨"dbSNP:rs4938933", "rs4938933 at the MS4A4A locus (no allele named in the cited records)"⟩

/-- Run step H1.1: TREM2 activates PLCG2 (PLCG2-dependent phosphoinositide signaling). -/
def S1 : Statement where
  id := "S1"
  text := "TREM2 activates PLCG2 (PLCG2-dependent phosphoinositide signaling)"
  claim := .effect trem2 .pos (.activity plcg2)
  evidence := []

/-- Run step H1.2: INPP5D inhibits PLCG2 (PLCG2-dependent phosphoinositide signaling). -/
def S2 : Statement where
  id := "S2"
  text := "INPP5D inhibits PLCG2 (PLCG2-dependent phosphoinositide signaling)"
  claim := .effect inpp5d .neg (.activity plcg2)
  evidence := []

/-- Run step H1.3: the PLCG2-dependent microglial response compacts amyloid plaques. -/
def S3 : Statement where
  id := "S3"
  text := "the PLCG2-dependent microglial response compacts amyloid plaques"
  claim := .effect plcg2 .pos (.phenotype plaqueCompaction)
  evidence := [
    { pmid := 42357928, year := 2026, kind := .mechanistic, note := "Alzheimer's Protection by PLCγ2 Compacts Plaques", taxon := some Taxa.mouse }
  ]

/-- Run step H1.3: the PLCG2-dependent microglial response protects synapses (less synapse loss). Sign: inverted: the run's object is synapse protection, grounded as decreased synapse density. -/
def S4 : Statement where
  id := "S4"
  text := "the PLCG2-dependent microglial response protects synapses (less synapse loss)"
  claim := .effect plcg2 .neg (.phenotype synapseLoss)
  evidence := [
    { pmid := 42357928, year := 2026, kind := .mechanistic, note := "Alzheimer's Protection by PLCγ2 Compacts Plaques, Redistributes Microglia, and Protects Synapses", taxon := some Taxa.mouse }
  ]

/-- Run step H1.4: the rs75932628 T allele (TREM2) goes with higher Alzheimer's disease risk. Sign: the run's polarity is unknown; direction from the cited GWAS row, T allele odds ratio 2.22. -/
def S5 : Statement where
  id := "S5"
  text := "the rs75932628 T allele (TREM2) goes with higher Alzheimer's disease risk"
  claim := .assoc rs75932628 (some .pos) (.disease ad)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs75932628", kind := .observational, note := "rs75932628-T is associated with 'Alzheimer's disease, proxy Alzheimer's disease or related dementias' at p = 3e-38, odds ratio 2.22 [1.97-2.51]" }
  ]

/-- Run step H1.4: the rs72824905 G allele (PLCG2) goes with lower Alzheimer's disease risk. Sign: the run's polarity is unknown; direction from the cited GWAS row, G allele odds ratio 0.73. -/
def S6 : Statement where
  id := "S6"
  text := "the rs72824905 G allele (PLCG2) goes with lower Alzheimer's disease risk"
  claim := .assoc rs72824905 (some .neg) (.disease ad)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs72824905", kind := .observational, note := "rs72824905-G is associated with 'Alzheimer's disease, proxy Alzheimer's disease or related dementias' at p = 7e-17, odds ratio 0.73 [0.67-0.78]" },
    { pmid := 42357928, year := 2026, kind := .review, note := "The Alzheimer's disease protective P522R PLCG2 coding variant (rs72824905)" }
  ]

/-- Run step H1.4: the rs10933431 G allele (INPP5D) goes with lower Alzheimer's disease risk. Sign: the run's polarity is unknown; direction from the cited GWAS row, G allele odds ratio 0.93. -/
def S7 : Statement where
  id := "S7"
  text := "the rs10933431 G allele (INPP5D) goes with lower Alzheimer's disease risk"
  claim := .assoc rs10933431 (some .neg) (.disease ad)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs10933431", kind := .observational, note := "rs10933431-G is associated with 'Alzheimer's disease, proxy Alzheimer's disease or related dementias' at p = 2e-19, odds ratio 0.93 [0.92-0.95]" }
  ]

/-- Run step H2.1: ABI3 is required for an organized microglial barrier around plaques (losing ABI3 lowers it). -/
def S8 : Statement where
  id := "S8"
  text := "ABI3 is required for an organized microglial barrier around plaques (losing ABI3 lowers it)"
  claim := .effect abi3 .pos (.process plaqueBarrier)
  evidence := []

/-- Run step H2.2: the TREM2-associated microglial state is required for restricting Alzheimer pathology. Sign: inverted: the run's object is restriction of Alzheimer pathology, grounded as AD severity; required_for (+) on restriction is TREM2 lowering severity. -/
def S9 : Statement where
  id := "S9"
  text := "the TREM2-associated microglial state is required for restricting Alzheimer pathology"
  claim := .effect trem2 .neg (.disease ad .severity)
  evidence := [
    { pmid := 28602351, year := 2017, kind := .hypothesis, note := "This unique microglia-type has the potential to restrict neurodegeneration" }
  ]

/-- Run step H2.3: the rs28394864 A allele (ABI3, author-reported) goes with higher Alzheimer's disease risk. Sign: the run's polarity is unknown; direction from the cited GWAS row, A allele beta 5.62 z-unit (increase). -/
def S10 : Statement where
  id := "S10"
  text := "the rs28394864 A allele (ABI3, author-reported) goes with higher Alzheimer's disease risk"
  claim := .assoc rs28394864 (some .pos) (.disease ad)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs28394864", kind := .observational, note := "rs28394864-A is associated with 'Alzheimer's disease or family history of Alzheimer's disease' at p = 2e-8, beta 5.62 z-unit (increase)" }
  ]

/-- Run step H2.3: the rs616338 T allele (ABI3) goes with higher Alzheimer's disease risk. Sign: the run's polarity is unknown; direction from the cited GWAS row, T allele odds ratio 1.31. -/
def S11 : Statement where
  id := "S11"
  text := "the rs616338 T allele (ABI3) goes with higher Alzheimer's disease risk"
  claim := .assoc rs616338 (some .pos) (.disease ad)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs616338", kind := .observational, note := "rs616338-T is associated with 'Alzheimer's disease, proxy Alzheimer's disease or related dementias' at p = 8e-18, odds ratio 1.31 [1.23-1.39]" }
  ]

/-- Run step H3.1: APOE-containing lipoprotein activates TREM2 (the TREM2-dependent microglial lipid response). -/
def S12 : Statement where
  id := "S12"
  text := "APOE-containing lipoprotein activates TREM2 (the TREM2-dependent microglial lipid response)"
  claim := .effect apoe .pos (.activity trem2)
  evidence := []

/-- Run step H3.2: APOE ε4 dosage raises Alzheimer's disease risk. -/
def S13 : Statement where
  id := "S13"
  text := "APOE ε4 dosage raises Alzheimer's disease risk"
  claim := .effect apoeE4 .pos (.disease ad)
  evidence := [
    { pmid := 8346443, year := 1993, kind := .observational, note := "Risk for AD increased from 20% to 90% and mean age at onset decreased from 84 to 68 years with increasing number of APOE-epsilon 4 alleles" }
  ]

/-- Run step H3.3: the TREM2-dependent microglial lipid response lowers restriction of Alzheimer pathology (run's sign), i.e. raises AD severity. Sign: inverted: the run's object is restriction of Alzheimer pathology and its polarity is negative, so TREM2 raises AD severity; the step's own note says the opposite. -/
def S14 : Statement where
  id := "S14"
  text := "the TREM2-dependent microglial lipid response lowers restriction of Alzheimer pathology (run's sign), i.e. raises AD severity"
  claim := .effect trem2 .pos (.disease ad .severity)
  evidence := [
    { pmid := 28602351, year := 2017, kind := .hypothesis, polarity := .refutes, note := "This unique microglia-type has the potential to restrict neurodegeneration" }
  ]

/-- Run step H4.2: variation at the MS4A4A locus (rs4938933) is associated with late-onset Alzheimer's disease. -/
def S15 : Statement where
  id := "S15"
  text := "variation at the MS4A4A locus (rs4938933) is associated with late-onset Alzheimer's disease"
  claim := .assoc rs4938933 none (.disease ad)
  evidence := [
    { pmid := 21460841, year := 2011, kind := .observational, note := "genome-wide association study of late-onset Alzheimer disease using a three-stage design consisting of a discovery stage (stage 1) and two replication stages (stages 2 and 3). Both joint analysis and meta-analysis approaches were used. We o" },
    { pmid := 0, year := 2026, ref := "rs4938933", kind := .observational, note := "rs4938933-? is associated with 'Alzheimer's disease (late onset)' at p = 8e-12, odds ratio 1.12 [1.09-1.15]" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15]

/-- H1, claim 4: TREM2–PLCG2 activation opposed by INPP5D sets the plaque-responsive microglial state. -/
def h1c4a1 := viaActivity (lit S1) (lit S3)

/-- H1, claim 5: TREM2–PLCG2 activation opposed by INPP5D sets the plaque-responsive microglial state. -/
def h1c5a1 := lit S3

/-- H1, claim 6: TREM2–PLCG2 activation opposed by INPP5D sets the plaque-responsive microglial state. -/
def h1c6a1 := viaActivity (lit S2) (lit S3)

/-- H1, claim 7: TREM2–PLCG2 activation opposed by INPP5D sets the plaque-responsive microglial state. -/
def h1c7a1 := viaActivity (lit S1) (lit S4)

/-- H1, claim 8: TREM2–PLCG2 activation opposed by INPP5D sets the plaque-responsive microglial state. -/
def h1c8a1 := lit S4

/-- H1, claim 9: TREM2–PLCG2 activation opposed by INPP5D sets the plaque-responsive microglial state. -/
def h1c9a1 := viaActivity (lit S2) (lit S4)

/-- H2, claim 2: ABI3-dependent microglial organization builds a protective barrier around amyloid plaques. -/
def h2c2a1 := lit S8

/-- H2, claim 3: ABI3-dependent microglial organization builds a protective barrier around amyloid plaques. -/
def h2c3a1 := lit S9

/-- H2, claim 3: ABI3-dependent microglial organization builds a protective barrier around amyloid plaques. -/
def h2c3a2 := lit S14

/-- H3, claim 1: APOE genotype alters Alzheimer risk through a TREM2-coupled lipid-sensing microglial program. -/
def h3c1a1 := lit S13

/-- H3, claim 2: APOE genotype alters Alzheimer risk through a TREM2-coupled lipid-sensing microglial program. -/
def h3c2a1 := lit S9

/-- H3, claim 2: APOE genotype alters Alzheimer risk through a TREM2-coupled lipid-sensing microglial program. -/
def h3c2a2 := lit S14

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c4a1" h1c4a1,
    arm "H1" "c5a1" h1c5a1,
    arm "H1" "c6a1" h1c6a1,
    arm "H1" "c7a1" h1c7a1,
    arm "H1" "c8a1" h1c8a1,
    arm "H1" "c9a1" h1c9a1,
    arm "H2" "c2a1" h2c2a1,
    arm "H2" "c3a1" h2c3a1,
    arm "H2" "c3a2" h2c3a2,
    arm "H3" "c1a1" h3c1a1,
    arm "H3" "c2a1" h3c2a1,
    arm "H3" "c2a2" h3c2a2]

#eval printRows "20260825T000739Z-8b25e5" rows

end BioLean.Lib.IPF.Runs.R20260825T000739Z_8b25e5
