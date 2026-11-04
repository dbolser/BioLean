import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260824T223623Z-4f7d1a/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260824T223623Z-4f7d1a`: anthropic:claude-opus-5, idiopathic pulmonary fibrosis, genes MUC5B, TERT, SFTPC, TOLLIP, DSP, FAM13A. -/

namespace BioLean.Lib.IPF.Runs.R20260824T223623Z_4f7d1a

open BioLean BioLean.Lib.IPF Derivation

def ipf : Entity .disease := ⟨"MONDO:0800504", "idiopathic pulmonary fibrosis"⟩
def pulmonaryFibrosis : Entity .disease := ⟨"MONDO:0002771", "pulmonary fibrosis"⟩
def cpfe : Entity .disease := ⟨"MONDO:0017591", "combined pulmonary fibrosis-emphysema syndrome"⟩
def pulmonarySsc : Entity .disease := ⟨"MONDO:0002047", "pulmonary systemic sclerosis"⟩
def rs35705950 : Entity .variant := ⟨"dbSNP:rs35705950", "rs35705950 minor (risk) allele, MUC5B promoter"⟩
def rs5743890 : Entity .variant := ⟨"dbSNP:rs5743890", "rs5743890 minor allele (TOLLIP)"⟩
def rs2609255 : Entity .variant := ⟨"dbSNP:rs2609255", "rs2609255 minor allele, two copies (FAM13A)"⟩
def sftpcBrichos : Entity .variant := ⟨"BLN:SFTPC-BRICHOS-mutation", "SFTPC BRICHOS-domain mutation (no public identifier for the class)"⟩
def fam13aVariants : Entity .variant := ⟨"BLN:FAM13A-variants", "FAM13A variants, unspecified (the run names no variant)"⟩
def MUC5B : Entity .protein := ⟨"UniProt:Q9HC84", "MUC5B"⟩
def DSP : Entity .protein := ⟨"UniProt:P15924", "DSP"⟩
def TERT : Entity .protein := ⟨"UniProt:O14746", "TERT"⟩
def SFTPC : Entity .protein := ⟨"UniProt:P11686", "SFTPC"⟩
def TOLLIP : Entity .protein := ⟨"UniProt:Q9H0E2", "TOLLIP"⟩
def IRAK1 : Entity .protein := ⟨"UniProt:P51617", "IRAK1"⟩
def FAM13A : Entity .protein := ⟨"UniProt:O94988", "FAM13A"⟩
def RHOA : Entity .protein := ⟨"UniProt:P61586", "RHOA"⟩
def erStress : Entity .process := ⟨"GO:0034976", "response to endoplasmic reticulum stress"⟩
def emt : Entity .process := ⟨"GO:0001837", "epithelial to mesenchymal transition"⟩
def telomereMaintenance : Entity .process := ⟨"GO:0000723", "telomere maintenance"⟩
def cellularSenescence : Entity .process := ⟨"GO:0090398", "cellular senescence"⟩
def aggrephagy : Entity .process := ⟨"GO:0035973", "aggrephagy"⟩
def epitheliumRegeneration : Entity .process := ⟨"GO:1990399", "epithelium regeneration"⟩
def at2 : Entity .cellType := ⟨"CL:0002063", "pulmonary alveolar type 2 cell"⟩
def lungAlveolus : Entity .anatomy := ⟨"UBERON:0002299", "alveolus of lung"⟩
def shortTelomeres : Entity .phenotype := ⟨"HP:0031413", "Short telomere length"⟩
def uip : Entity .phenotype := ⟨"HP:0031950", "Usual interstitial pneumonia"⟩
def emphysema : Entity .phenotype := ⟨"HP:0002097", "Emphysema"⟩
def at2Senescence : Entity .process := cellularSenescence.inCtx { cellType := at2 }
def alveolarRegeneration : Entity .process := epitheliumRegeneration.inCtx { anatomy := lungAlveolus }
def uipInSscIld : Entity .phenotype := uip.inCtx { condition := some (.organism pulmonarySsc) }

/-- Run step H1.1: rs35705950 raises MUC5B. -/
def I1 : Statement where
  id := "I1"
  text := "rs35705950 raises MUC5B"
  claim := .effect rs35705950 .pos (.amount MUC5B)
  evidence := [
    { pmid := 27630174, year := 2016, kind := .review, note := "a common gain-of-function promoter variant in MUC5B rs35705950" },
    { pmid := 21506741, year := 2011, kind := .observational, note := "The variant allele of rs35705950 was associated with up-regulation in MUC5B expression in the lung in unaffected subjects" },
    { pmid := 41091081, year := 2026, kind := .observational, note := "MUC5B was ectopically expressed in AT2 cells in controls with the risk variant" },
    { pmid := 30345907, year := 2018, kind := .review, note := "the gain-of-function MUC5B promoter variant rs35705950" }
  ]

/-- Run step H1.2: MUC5B raises ER stress. -/
def I2 : Statement where
  id := "I2"
  text := "MUC5B raises ER stress"
  claim := .effect MUC5B .pos (.process erStress)
  evidence := [
    { pmid := 41091081, year := 2026, kind := .inVitro, note := "we demonstrated a direct relationship between MUC5B expression and ER stress in bronchiolar epithelia in vitro" }
  ]

/-- Run step H1.3: DSP restrains EMT. -/
def I3 : Statement where
  id := "I3"
  text := "DSP restrains EMT"
  claim := .effect DSP .neg (.process emt)
  evidence := [
    { pmid := 42120512, year := 2026, kind := .inVitro, note := "SYISL promotes DSP degradation, thereby relieving a key constraint on epithelial integrity. This event initiates a downstream signaling cascade, activating the PI3K-AKT pathway and promoting YAP1 dephosphorylation and nuclear translocation." }
  ]

/-- Run step H1.4: ER stress drives pulmonary fibrosis. -/
def I4 : Statement where
  id := "I4"
  text := "ER stress drives pulmonary fibrosis"
  claim := .effect erStress .pos (.disease pulmonaryFibrosis)
  evidence := [
    { pmid := 41090357, year := 2025, kind := .mechanistic, note := "selective inhibition of RIDD with PAIR2 reduced AT2 differentiation into profibrotic transitional cells and protected mice from bleomycin-induced pulmonary fibrosis", taxon := some Taxa.mouse },
    { pmid := 18635891, year := 2008, kind := .hypothesis, note := "Severe ER stress response in the AECIIs of patients with sporadic IPF may underlie the apoptosis of this cell type and development of fibrosis in this disease" }
  ]

/-- Run step H1.4: EMT drives pulmonary fibrosis. -/
def I5 : Statement where
  id := "I5"
  text := "EMT drives pulmonary fibrosis"
  claim := .effect emt .pos (.disease pulmonaryFibrosis)
  evidence := [
    { pmid := 42120512, year := 2026, kind := .inVitro, note := "which collectively promotes an EMT-associated state and increased epithelial plasticity. The resultant aberrant epithelial-mesenchymal crosstalk contributes to pathological extracellular matrix (ECM) deposition" }
  ]

/-- Run step H2.1: TERT is required for telomere maintenance (required_for). -/
def I6 : Statement where
  id := "I6"
  text := "TERT is required for telomere maintenance (required_for)"
  claim := .effect TERT .pos (.process telomereMaintenance)
  evidence := [
    { pmid := 0, year := 2026, ref := "O14746", kind := .curatedDb, note := "main activity is the elongation of telomeres" }
  ]

/-- Bridge, not in the run: telomere maintenance prevents short telomeres. -/
def I7 : Statement where
  id := "I7"
  text := "telomere maintenance prevents short telomeres"
  claim := .effect telomereMaintenance .neg (.phenotype shortTelomeres)
  evidence := [
    { pmid := 0, year := 2026, ref := "GO:0000723", kind := .textbook, note := "maintenance of proper telomeric length" }
  ]

/-- Run step H2.2: short telomeres go with IPF. Sign: the run's step is associated_with with unknown polarity; the direction is from the meta-analysis the run cited for the step (PMID:41728098). -/
def I8 : Statement where
  id := "I8"
  text := "short telomeres go with IPF"
  claim := .assoc shortTelomeres (some .pos) (.disease ipf)
  evidence := [
    { pmid := 41728098, year := 2026, kind := .observational, note := "significant shorter telomere lengths in IPF patients compared to healthy controls" },
    { pmid := 42587125, year := 2026, kind := .review, note := "IPF patients frequently bear germline mutations in telomerase genes, critically short telomeres" }
  ]

/-- Run step H2.3: mutant pro-SFTPC raises ER stress. -/
def I9 : Statement where
  id := "I9"
  text := "mutant pro-SFTPC raises ER stress"
  claim := .effect sftpcBrichos .pos (.process erStress)
  evidence := []

/-- Run step H2.4: AT2 senescence drives IPF. -/
def I10 : Statement where
  id := "I10"
  text := "AT2 senescence drives IPF"
  claim := .effect at2Senescence .pos (.disease ipf)
  evidence := [
    { pmid := 42346293, year := 2026, kind := .review, note := "Senescent alveolar epithelial cells and fibroblasts contribute to impaired tissue repair and persistent fibrotic remodeling" }
  ]

/-- Run step H2.4: alveolar regeneration protects against IPF. Sign: inverted: the run's subject is 'failed alveolar regeneration' (second part of 'AT2 senescence / failed alveolar regeneration'). -/
def I14 : Statement where
  id := "I14"
  text := "alveolar regeneration protects against IPF"
  claim := .effect alveolarRegeneration .neg (.disease ipf)
  evidence := []

/-- Run step H3.1: TOLLIP inhibits IRAK1. -/
def I11 : Statement where
  id := "I11"
  text := "TOLLIP inhibits IRAK1"
  claim := .effect TOLLIP .neg (.activity IRAK1)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9H0E2", kind := .curatedDb, note := "Inhibits IRAK1 phosphorylation and kinase activity" }
  ]

/-- Run step H3.2: TOLLIP is required for aggrephagy (required_for). -/
def I12 : Statement where
  id := "I12"
  text := "TOLLIP is required for aggrephagy (required_for)"
  claim := .effect TOLLIP .pos (.process aggrephagy)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9H0E2", kind := .curatedDb, note := "mediating autophagic clearance of ubiquitin conjugates" }
  ]

/-- Run step H3.3: the rs5743890 minor allele goes with lower IPF risk. Sign: the run's step is unsigned and names 'TOLLIP variants'; the GWAS it cites for the step calls the rs5743890 minor allele protective. -/
def I15 : Statement where
  id := "I15"
  text := "the rs5743890 minor allele goes with lower IPF risk"
  claim := .assoc rs5743890 (some .neg) (.disease ipf)
  evidence := [
    { pmid := 24429156, year := 2013, kind := .observational, note := "Individuals who developed IPF despite having the protective TOLLIP minor allele of rs5743890" }
  ]

/-- Run step H3.3: the rs5743890 minor allele goes with higher IPF mortality. Sign: the run's step is unsigned and names 'TOLLIP variants'; the GWAS it cites for the step gives a hazard ratio of 1.72 for mortality in IPF for the rs5743890 minor allele. -/
def I16 : Statement where
  id := "I16"
  text := "the rs5743890 minor allele goes with higher IPF mortality"
  claim := .assoc rs5743890 (some .pos) (.disease ipf .progression)
  evidence := [
    { pmid := 24429156, year := 2013, kind := .observational, note := "Individuals who developed IPF despite having the protective TOLLIP minor allele of rs5743890 carried an increased mortality risk (meta-analysis with fixed-effect model: hazard ratio 1·72 [95% CI 1·24-2·38]; p=0·0012)" }
  ]

/-- Run step H4.1: FAM13A inhibits RHOA. -/
def I13 : Statement where
  id := "I13"
  text := "FAM13A inhibits RHOA"
  claim := .effect FAM13A .neg (.activity RHOA)
  evidence := []

/-- Run step H4.2: FAM13A variants go with IPF (direction not given). -/
def I17 : Statement where
  id := "I17"
  text := "FAM13A variants go with IPF (direction not given)"
  claim := .assoc fam13aVariants none (.disease ipf)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:FAM13A-EFO_0000768", kind := .observational, note := "scores the FAM13A-idiopathic pulmonary fibrosis association at 0.56 (literature 0.45, genetic_association 0.72)" },
    { pmid := 31900205, year := 2020, kind := .review, note := "Family with sequence similarity 13 member A (FAM13A) genetic variants have been associated with several chronic respiratory diseases including chronic obstructive pulmonary disease (COPD), cystic fibrosis (CF), idiopathic pulmonary fibrosis" }
  ]

/-- Run step H4.3: two copies of the rs2609255 minor allele go with a UIP pattern in systemic sclerosis ILD. Sign: the run's step is unsigned and names 'FAM13A variants'; the study it cites for the step gives odds ratio 3.40 for two copies of the rs2609255 minor allele. -/
def I18 : Statement where
  id := "I18"
  text := "two copies of the rs2609255 minor allele go with a UIP pattern in systemic sclerosis ILD"
  claim := .assoc rs2609255 (some .pos) (.phenotype uipInSscIld)
  evidence := [
    { pmid := 39418199, year := 2025, kind := .observational, note := "patients carrying two copies of the IPF risk gene FAM13A minor allele rs2609255 had significantly higher odds of a definite UIP pattern compared with the other patterns (odds ratio 3.40, 95% CI 1.19-9.70)" }
  ]

/-- Run step H4.3: FAM13A variants go with emphysema (direction not given). -/
def I19 : Statement where
  id := "I19"
  text := "FAM13A variants go with emphysema (direction not given)"
  claim := .assoc fam13aVariants none (.phenotype emphysema)
  evidence := []

/-- Run step H4.3: FAM13A variants go with combined pulmonary fibrosis and emphysema (direction not given). -/
def I20 : Statement where
  id := "I20"
  text := "FAM13A variants go with combined pulmonary fibrosis and emphysema (direction not given)"
  claim := .assoc fam13aVariants none (.disease cpfe)
  evidence := []

/-- Run step H5.1: MUC5B goes with IPF (direction not given). -/
def I21 : Statement where
  id := "I21"
  text := "MUC5B goes with IPF (direction not given)"
  claim := .assoc MUC5B none (.disease ipf)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:MUC5B-EFO_0000768", kind := .observational, note := "scores the MUC5B-idiopathic pulmonary fibrosis association at 0.60" },
    { pmid := 21506741, year := 2011, kind := .observational, note := "A common polymorphism in the promoter of MUC5B is associated with familial interstitial pneumonia and idiopathic pulmonary fibrosis" },
    { pmid := 29066090, year := 2017, kind := .observational, note := "signal of association with IPF susceptibility near A-kinase anchoring protein 13 (AKAP13; rs62025270, odds ratio [OR] 1·27 [95% CI 1·18-1·37], p=1·32 × 10-9) and confirmed previously reported signals, including in mucin 5B (MUC5B; rs3570595" }
  ]

/-- Run step H5.1: TERT goes with IPF (direction not given). -/
def I22 : Statement where
  id := "I22"
  text := "TERT goes with IPF (direction not given)"
  claim := .assoc TERT none (.disease ipf)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:TERT-EFO_0000768", kind := .observational, note := "scores the TERT-idiopathic pulmonary fibrosis association at 0.72" },
    { pmid := 23535734, year := 2013, kind := .observational, note := "Lead SNPs at two loci (TERC and TERT) associate with several cancers and other diseases, including idiopathic pulmonary fibrosis" }
  ]

/-- Run step H5.1: SFTPC goes with IPF (direction not given). -/
def I23 : Statement where
  id := "I23"
  text := "SFTPC goes with IPF (direction not given)"
  claim := .assoc SFTPC none (.disease ipf)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:SFTPC-EFO_0000768", kind := .observational, note := "scores the SFTPC-idiopathic pulmonary fibrosis association at 0.39" },
    { pmid := 27630174, year := 2016, kind := .review, note := "Idiopathic pulmonary fibrosis (IPF) is an incurable complex genetic disorder that is associated with sequence changes in 7 genes (MUC5B, TERT, TERC, RTEL1, PARN, SFTPC, and SFTPA2)" }
  ]

/-- Run step H5.1: TOLLIP goes with IPF (direction not given). -/
def I24 : Statement where
  id := "I24"
  text := "TOLLIP goes with IPF (direction not given)"
  claim := .assoc TOLLIP none (.disease ipf)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:TOLLIP-EFO_0000768", kind := .observational, note := "scores the TOLLIP-idiopathic pulmonary fibrosis association at 0.38" },
    { pmid := 24429156, year := 2013, kind := .observational, note := "Novel variants in TOLLIP and SPPL2C are associated with IPF susceptibility" }
  ]

/-- Run step H5.1: DSP goes with IPF (direction not given). -/
def I25 : Statement where
  id := "I25"
  text := "DSP goes with IPF (direction not given)"
  claim := .assoc DSP none (.disease ipf)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:DSP-EFO_0000768", kind := .observational, note := "scores the DSP-idiopathic pulmonary fibrosis association at 0.59" },
    { pmid := 29066090, year := 2017, kind := .observational, note := "signal of association with IPF susceptibility near A-kinase anchoring protein 13 (AKAP13; rs62025270, odds ratio [OR] 1·27 [95% CI 1·18-1·37], p=1·32 × 10-9) and confirmed previously reported signals, including in mucin 5B (MUC5B; rs3570595" }
  ]

/-- Run step H5.1: FAM13A goes with IPF (direction not given). -/
def I26 : Statement where
  id := "I26"
  text := "FAM13A goes with IPF (direction not given)"
  claim := .assoc FAM13A none (.disease ipf)
  evidence := [
    { pmid := 0, year := 2026, ref := "OT:FAM13A-EFO_0000768", kind := .observational, note := "scores the FAM13A-idiopathic pulmonary fibrosis association at 0.56" }
  ]

def statements : List Statement := [I1, I2, I3, I4, I5, I6, I7, I8, I9, I10, I14, I11, I12, I15, I16, I13, I17, I18, I19, I20, I21, I22, I23, I24, I25, I26]

/-- H1, claim 1: Distal airway secretory reprogramming: MUC5B over-expression plus DSP-dependent junction/EMT change converts the respiratory bronchiole into a fibrogenic, ER-st. -/
def h1c1a1 := viaAmount (lit I1) (viaProcess (lit I2) (lit I4))

/-- H1, claim 2: Distal airway secretory reprogramming: MUC5B over-expression plus DSP-dependent junction/EMT change converts the respiratory bronchiole into a fibrogenic, ER-st. -/
def h1c2a1 := viaProcess (lit I3) (lit I5)

/-- H2, claim 1: Alveolar type II cell exhaustion: TERT-dependent telomere attrition and misfolded pro-SFTPC converge on the same AT2 proteostasis/senescence failure. -/
def h2c1a1 := viaProcess (lit I6) (viaPhenotype (lit I7) (fromAssoc (lit I8)))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H1" "c2a1" h1c2a1,
    arm "H2" "c1a1" h2c1a1]

#eval printRows "20260824T223623Z-4f7d1a" rows

end BioLean.Lib.IPF.Runs.R20260824T223623Z_4f7d1a
