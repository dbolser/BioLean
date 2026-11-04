import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-crohn-openrouter-anthropicclaude-opus-5-single_agent-r1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-crohn-openrouter-anthropicclaude-opus-5-single_agent-r1`: openrouter:anthropic/claude-opus-5, Crohn disease, genes IL12B, IL23R, NOD2, LACC1, GPR35, MEIS1, TRIM4. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_crohn_openrouter_anthropicclaude_opus_5_single_agent_r1

open BioLean BioLean.Lib.IPF Derivation

def crohn : Entity .disease := ⟨"MONDO:0005011", "Crohn disease"⟩
def rs755374 : Entity .variant := ⟨"dbSNP:rs755374", "rs755374 risk allele (allele not named in the cited GWAS Catalog row; IL12B locus)"⟩
def rs6556412 : Entity .variant := ⟨"dbSNP:rs6556412", "rs6556412 A allele (IL12B locus)"⟩
def il23 : Entity .process := ⟨"GO:0032627", "interleukin-23 production"⟩
def IL23R : Entity .protein := ⟨"UniProt:Q5VWK5", "IL23R"⟩
def th17Commitment : Entity .process := ⟨"GO:0072540", "T-helper 17 cell lineage commitment"⟩
def il17Production : Entity .process := ⟨"GO:0032620", "interleukin-17 production"⟩
def th17Response : Entity .process := ⟨"GO:0072538", "T-helper 17 type immune response"⟩
def rs2066847 : Entity .variant := ⟨"dbSNP:rs2066847", "rs2066847 T allele (NOD2 frameshift)"⟩
def rs2066844 : Entity .variant := ⟨"dbSNP:rs2066844", "rs2066844 risk allele (allele not named in the cited GWAS Catalog row; NOD2 missense)"⟩
def rs2066845 : Entity .variant := ⟨"dbSNP:rs2066845", "rs2066845 risk allele (allele not named in the cited GWAS Catalog row; NOD2 missense)"⟩
def nod2Signalling : Entity .process := ⟨"GO:0070431", "nucleotide-binding oligomerization domain containing 2 signaling pathway"⟩
def LACC1 : Entity .protein := ⟨"UniProt:Q8IV20", "LACC1"⟩
def macrophage : Entity .cellType := ⟨"CL:0000235", "macrophage"⟩
def cytokineProduction : Entity .process := ⟨"GO:0001816", "cytokine production"⟩
def bacterialDefense : Entity .process := ⟨"GO:0042742", "defense response to bacterium"⟩
def purineInterconversion : Entity .process := ⟨"GO:0015950", "purine nucleotide interconversion"⟩
def oxphos : Entity .process := ⟨"GO:0006119", "oxidative phosphorylation"⟩
def macrophageActivation : Entity .process := ⟨"GO:0042116", "macrophage activation"⟩
def kynurenicAcid : Entity .chemical := ⟨"CHEBI:18344", "kynurenic acid"⟩
def hiaa : Entity .chemical := ⟨"CHEBI:27823", "(5-hydroxyindol-3-yl)acetic acid"⟩
def GPR35 : Entity .protein := ⟨"UniProt:Q9HC97", "GPR35"⟩
def neutrophilMigration : Entity .process := ⟨"GO:1990266", "neutrophil migration"⟩
def rs34236350 : Entity .variant := ⟨"dbSNP:rs34236350", "rs34236350 (GPR35 locus; the cited GWAS Catalog row names no allele, so the association is unsigned)"⟩
def rs2975780 : Entity .variant := ⟨"dbSNP:rs2975780", "rs2975780 A allele (GPR35 locus)"⟩
def rs3749172 : Entity .variant := ⟨"dbSNP:rs3749172", "rs3749172 A allele (GPR35 missense)"⟩
def rs4676410 : Entity .variant := ⟨"dbSNP:rs4676410", "rs4676410 A allele (GPR35 locus)"⟩
def macCytokineProduction : Entity .process := cytokineProduction.inCtx { cellType := macrophage }
def macBacterialDefense : Entity .process := bacterialDefense.inCtx { cellType := macrophage }

/-- Run step H1.1: the rs755374 risk allele raises IL-23 (p40-containing heterodimer), as IL-23 production (the run's increases_amount; no protein term exists for the heterodimer). -/
def S1 : Statement where
  id := "S1"
  text := "the rs755374 risk allele raises IL-23 (p40-containing heterodimer), as IL-23 production (the run's increases_amount; no protein term exists for the heterodimer)"
  claim := .effect rs755374 .pos (.process il23)
  evidence := []

/-- Run step H1.1: the rs6556412 A allele raises IL-23 (p40-containing heterodimer), as IL-23 production. -/
def S2 : Statement where
  id := "S2"
  text := "the rs6556412 A allele raises IL-23 (p40-containing heterodimer), as IL-23 production"
  claim := .effect rs6556412 .pos (.process il23)
  evidence := []

/-- Run step H1.2: IL-23 (production) activates IL23R. -/
def S3 : Statement where
  id := "S3"
  text := "IL-23 (production) activates IL23R"
  claim := .effect il23 .pos (.activity IL23R)
  evidence := []

/-- Run step H1.3: IL23R signalling promotes Th17 lineage commitment. -/
def S4 : Statement where
  id := "S4"
  text := "IL23R signalling promotes Th17 lineage commitment"
  claim := .effect IL23R .pos (.process th17Commitment)
  evidence := []

/-- Run step H1.3: IL23R signalling promotes IL-17 production. -/
def S5 : Statement where
  id := "S5"
  text := "IL23R signalling promotes IL-17 production"
  claim := .effect IL23R .pos (.process il17Production)
  evidence := []

/-- Run step H1.4: a Th17 mucosal response leads to Crohn disease. -/
def S6 : Statement where
  id := "S6"
  text := "a Th17 mucosal response leads to Crohn disease"
  claim := .effect th17Response .pos (.disease crohn)
  evidence := []

/-- Run step H1.4: IL-17 production leads to Crohn disease. -/
def S7 : Statement where
  id := "S7"
  text := "IL-17 production leads to Crohn disease"
  claim := .effect il17Production .pos (.disease crohn)
  evidence := []

/-- Run step H2.1: the rs2066847 T allele (NOD2 frameshift) reduces NOD2 (MDP-RIPK2-NF-kB) signalling. -/
def S8 : Statement where
  id := "S8"
  text := "the rs2066847 T allele (NOD2 frameshift) reduces NOD2 (MDP-RIPK2-NF-kB) signalling"
  claim := .effect rs2066847 .neg (.process nod2Signalling)
  evidence := [
    { pmid := 11385576, year := 2001, kind := .hypothesis, polarity := .refutes, note := "These observations suggest that the NOD2 gene product confers susceptibility to Crohn's disease by altering the recognition of these components and/or by over-activating NF-kB in monocytes" }
  ]

/-- Run step H2.1: the rs2066844 risk allele (NOD2 missense) reduces NOD2 signalling. -/
def S9 : Statement where
  id := "S9"
  text := "the rs2066844 risk allele (NOD2 missense) reduces NOD2 signalling"
  claim := .effect rs2066844 .neg (.process nod2Signalling)
  evidence := [
    { pmid := 11385576, year := 2001, kind := .hypothesis, polarity := .refutes, note := "These observations suggest that the NOD2 gene product confers susceptibility to Crohn's disease by altering the recognition of these components and/or by over-activating NF-kB in monocytes" }
  ]

/-- Run step H2.1: the rs2066845 risk allele (NOD2 missense) reduces NOD2 signalling. -/
def S10 : Statement where
  id := "S10"
  text := "the rs2066845 risk allele (NOD2 missense) reduces NOD2 signalling"
  claim := .effect rs2066845 .neg (.process nod2Signalling)
  evidence := [
    { pmid := 11385576, year := 2001, kind := .hypothesis, polarity := .refutes, note := "These observations suggest that the NOD2 gene product confers susceptibility to Crohn's disease by altering the recognition of these components and/or by over-activating NF-kB in monocytes" }
  ]

/-- Run step H2.2: LACC1 is required for (promotes) cytokine secretion in macrophages. -/
def S11 : Statement where
  id := "S11"
  text := "LACC1 is required for (promotes) cytokine secretion in macrophages"
  claim := .effect LACC1 .pos (.process macCytokineProduction)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8IV20", kind := .curatedDb, note := "Participates in pattern recognition receptor (PRR)-induced cytokines in macrophages: associates with the NOD2-signaling complex and promotes optimal NOD2-induced signaling, cytokine secretion and bacterial clearance" }
  ]

/-- Run step H2.2: LACC1 is required for (promotes) bacterial clearance by macrophages. -/
def S12 : Statement where
  id := "S12"
  text := "LACC1 is required for (promotes) bacterial clearance by macrophages"
  claim := .effect LACC1 .pos (.process macBacterialDefense)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8IV20", kind := .curatedDb, note := "Participates in pattern recognition receptor (PRR)-induced cytokines in macrophages: associates with the NOD2-signaling complex and promotes optimal NOD2-induced signaling, cytokine secretion and bacterial clearance" }
  ]

/-- Run step H2.3: the purine nucleotide cycle is required for the macrophage effector state (IL-1beta, TNF output). -/
def S13 : Statement where
  id := "S13"
  text := "the purine nucleotide cycle is required for the macrophage effector state (IL-1beta, TNF output)"
  claim := .effect purineInterconversion .pos (.process macrophageActivation)
  evidence := []

/-- Run step H2.3: oxidative phosphorylation is required for the macrophage effector state (IL-1beta, TNF output). -/
def S14 : Statement where
  id := "S14"
  text := "oxidative phosphorylation is required for the macrophage effector state (IL-1beta, TNF output)"
  claim := .effect oxphos .pos (.process macrophageActivation)
  evidence := []

/-- Run step H2.4: impaired macrophage clearance of mucosa-invading bacteria leads to Crohn disease. Sign: inverted: the run's subject is impaired (loss of) macrophage bacterial clearance, with sign +. -/
def S15 : Statement where
  id := "S15"
  text := "impaired macrophage clearance of mucosa-invading bacteria leads to Crohn disease"
  claim := .effect macBacterialDefense .neg (.disease crohn)
  evidence := []

/-- Run step H3.1: kynurenic acid activates GPR35. -/
def S16 : Statement where
  id := "S16"
  text := "kynurenic acid activates GPR35"
  claim := .effect kynurenicAcid .pos (.activity GPR35)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC97", kind := .curatedDb, note := "binds to several ligands including the tryptophan metabolite kynurenic acid (KYNA), lysophosphatidic acid (LPA) or 5-hydroxyindoleacetic acid (5-HIAA) with high affinity, leading to rapid and transient activation of numerous intracellular s" },
    { pmid := 40623474, year := 2025, kind := .mechanistic, note := "Mechanistically, KYNA induced MAT browning and regulated disease procession of CD via GPR35-ERK1/2-PGC-1α signaling pathway", taxon := some Taxa.mouse }
  ]

/-- Run step H3.1: 5-HIAA activates GPR35. -/
def S17 : Statement where
  id := "S17"
  text := "5-HIAA activates GPR35"
  claim := .effect hiaa .pos (.activity GPR35)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC97", kind := .curatedDb, note := "binds to several ligands including the tryptophan metabolite kynurenic acid (KYNA), lysophosphatidic acid (LPA) or 5-hydroxyindoleacetic acid (5-HIAA) with high affinity, leading to rapid and transient activation of numerous intracellular s" }
  ]

/-- Run step H3.2: GPR35 leads to neutrophil recruitment at the mucosa. -/
def S18 : Statement where
  id := "S18"
  text := "GPR35 leads to neutrophil recruitment at the mucosa"
  claim := .effect GPR35 .pos (.process neutrophilMigration)
  evidence := []

/-- Run step H3.2: GPR35 leads to bacterial clearance at the mucosa. -/
def S19 : Statement where
  id := "S19"
  text := "GPR35 leads to bacterial clearance at the mucosa"
  claim := .effect GPR35 .pos (.process bacterialDefense)
  evidence := []

/-- Run step H3.3: rs34236350 is associated with Crohn disease risk (no allele named, so no direction). Sign: the run gives polarity unknown; the cited GWAS row gives 'beta 0.1795 (increase)' for 'rs34236350-?', an allele it does not name. Some allele of any associated SNP raises risk, so a direction for an unnamed 'effect allele' says nothing beyo. -/
def S20 : Statement where
  id := "S20"
  text := "rs34236350 is associated with Crohn disease risk (no allele named, so no direction)"
  claim := .assoc rs34236350 none (.disease crohn)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs34236350", kind := .observational, note := "rs34236350-? is associated with 'Crohn's disease' at p = 1e-32, beta 0.1795 unit (increase)" }
  ]

/-- Run step H3.3: the rs2975780 A allele goes with lower Crohn disease risk. Sign: the run gives polarity unknown; direction from the cited GWAS row (OR 0.71 for the A allele). -/
def S21 : Statement where
  id := "S21"
  text := "the rs2975780 A allele goes with lower Crohn disease risk"
  claim := .assoc rs2975780 (some .neg) (.disease crohn)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs2975780", kind := .observational, note := "rs2975780-A is associated with 'Crohn's disease' at p = 6e-19, odds ratio 0.71 [0.66-0.77]" }
  ]

/-- Run step H3.3: the rs3749172 A allele goes with higher Crohn disease risk. Sign: the run gives polarity unknown; direction from the cited GWAS row (OR 1.45 for the A allele). -/
def S22 : Statement where
  id := "S22"
  text := "the rs3749172 A allele goes with higher Crohn disease risk"
  claim := .assoc rs3749172 (some .pos) (.disease crohn)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs3749172", kind := .observational, note := "rs3749172-A is associated with 'Crohn's disease' at p = 6e-11, odds ratio 1.45" }
  ]

/-- Run step H3.3: the rs4676410 A allele goes with higher Crohn disease risk. Sign: the run gives polarity unknown; direction from the GWAS row (OR 1.128 for the A allele); the run names this variant in its mechanism and cites it as supporting, not at the step. -/
def S23 : Statement where
  id := "S23"
  text := "the rs4676410 A allele goes with higher Crohn disease risk"
  claim := .assoc rs4676410 (some .pos) (.disease crohn)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs4676410", kind := .observational, note := "rs4676410-A is associated with 'Crohn's disease' at p = 1e-8, odds ratio 1.128 [1.082-1.175]" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20, S21, S22, S23]

/-- H1, claim 1: IL-12p40/IL-23R axis drives a Th17-polarised mucosal T-cell response; the risk architecture is the same axis that ustekinumab/risankizumab already validate. -/
def h1c1a1 := viaProcess (lit S1) (viaActivity (lit S3) (viaProcess (lit S5) (lit S7)))

/-- H1, claim 2: IL-12p40/IL-23R axis drives a Th17-polarised mucosal T-cell response; the risk architecture is the same axis that ustekinumab/risankizumab already validate. -/
def h1c2a1 := viaProcess (lit S2) (viaActivity (lit S3) (viaProcess (lit S5) (lit S7)))

/-- H1, claim 3: IL-12p40/IL-23R axis drives a Th17-polarised mucosal T-cell response; the risk architecture is the same axis that ustekinumab/risankizumab already validate. -/
def h1c3a1 := viaProcess (lit S5) (lit S7)

/-- H2, claim 4: NOD2 and LACC1/FAMIN act in one macrophage peptidoglycan-sensing/immunometabolism module: risk alleles blunt NOD2-driven bacterial clearance. -/
def h2c4a1 := viaProcess (lit S12) (lit S15)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H1" "c2a1" h1c2a1,
    arm "H1" "c3a1" h1c3a1,
    arm "H2" "c4a1" h2c4a1]

#eval printRows "study-2026-09-crohn-openrouter-anthropicclaude-opus-5-single_agent-r1" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_crohn_openrouter_anthropicclaude_opus_5_single_agent_r1
