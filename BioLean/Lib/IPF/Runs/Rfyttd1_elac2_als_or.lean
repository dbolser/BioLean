import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/fyttd1-elac2-als-or/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `fyttd1-elac2-als-or`: openrouter:anthropic/claude-opus-5, amyotrophic lateral sclerosis, genes FYTTD1, ELAC2. -/

namespace BioLean.Lib.IPF.Runs.Rfyttd1_elac2_als_or

open BioLean BioLean.Lib.IPF Derivation

def c9Hre : Entity .variant := ⟨"BLN:C9orf72-G4C2RepeatExpansion", "C9orf72 GGGGCC hexanucleotide repeat expansion (expanded allele)"⟩
def tdp43Proteinopathy : Entity .disease := ⟨"MONDO:0700038", "TDP-43 proteinopathy"⟩
def nct : Entity .process := ⟨"GO:0006913", "nucleocytoplasmic transport"⟩
def FYTTD1 : Entity .protein := ⟨"UniProt:Q96QD9", "FYTTD1"⟩
def mrnaExport : Entity .process := ⟨"GO:0006406", "mRNA export from nucleus"⟩
def mnDegeneration : Entity .phenotype := ⟨"UPHENO:0079518", "motor neuron degeneration"⟩
def als : Entity .disease := ⟨"MONDO:0004976", "amyotrophic lateral sclerosis"⟩
def ELAC2 : Entity .protein := ⟨"UniProt:Q9BQ52", "ELAC2"⟩
def trna3End : Entity .process := ⟨"GO:0042780", "tRNA 3'-end processing"⟩
def trfProcessing : Entity .process := ⟨"GO:0140891", "tRNA-derived regulatory ncRNA processing"⟩
def tiRna : Entity .chemical := ⟨"BLN:AngiogeninTiRNA", "tRNA-derived stress-induced small RNAs (tiRNAs) made by angiogenin cleavage"⟩
def translation : Entity .process := ⟨"GO:0006412", "translation"⟩
def trnaProcessing : Entity .process := ⟨"GO:0008033", "tRNA processing"⟩
def neurodegeneration : Entity .phenotype := ⟨"HP:0002180", "Neurodegeneration"⟩
def mtRnaProcessing : Entity .process := ⟨"GO:0000963", "mitochondrial RNA processing"⟩
def mtRibosomeAssembly : Entity .process := ⟨"GO:0061668", "mitochondrial ribosome assembly"⟩
def oxphos : Entity .process := ⟨"GO:0006119", "oxidative phosphorylation"⟩
def striatedMuscle : Entity .anatomy := ⟨"UBERON:0002036", "striated muscle tissue"⟩
def oxphosStriatedMuscle : Entity .process := oxphos.inCtx { anatomy := striatedMuscle }

/-- Run step H1.1: the C9orf72 repeat expansion inhibits nucleocytoplasmic transport. -/
def S1 : Statement where
  id := "S1"
  text := "the C9orf72 repeat expansion inhibits nucleocytoplasmic transport"
  claim := .effect c9Hre .neg (.process nct)
  evidence := [
    { pmid := 26308891, year := 2015, kind := .inVitro, note := "Nuclear import is impaired as a result of HRE expression in the fly model and in C9orf72 iPSC-derived neurons" },
    { pmid := 26308899, year := 2015, kind := .mechanistic, note := "a primary consequence of G4C2 repeat expansion is the compromise of nucleocytoplasmic transport through the nuclear pore", taxon := some Taxa.fly },
    { pmid := 29628143, year := 2018, kind := .review, note := "Defects in nucleocytoplasmic transport have been identified as a key pathogenic event in amyotrophic lateral sclerosis (ALS) and frontotemporal dementia (FTD) mediated by a GGGGCC hexanucleotide repeat expansion in C9ORF72" }
  ]

/-- Run step H1.1: TDP-43 pathology inhibits nucleocytoplasmic transport. -/
def S2 : Statement where
  id := "S2"
  text := "TDP-43 pathology inhibits nucleocytoplasmic transport"
  claim := .effect tdp43Proteinopathy .neg (.process nct)
  evidence := [
    { pmid := 29311743, year := 2018, kind := .inVitro, note := "Aggregated and disease-linked mutant TDP-43 triggered the sequestration and/or mislocalization of nucleoporins and transport factors, and interfered with nuclear protein import and RNA export" }
  ]

/-- Run step H1.2: FYTTD1 is required for mRNA export from the nucleus (losing FYTTD1 lowers mRNA export). -/
def S3 : Statement where
  id := "S3"
  text := "FYTTD1 is required for mRNA export from the nucleus (losing FYTTD1 lowers mRNA export)"
  claim := .effect FYTTD1 .pos (.process mrnaExport)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q96QD9", kind := .curatedDb, note := "Required for mRNA export from the nucleus to the cytoplasm" }
  ]

/-- Run step H1.3: loss of FYTTD1's mRNA export adapter function leads to motor neuron degeneration. Sign: inverted: the run's subject is loss of mRNA export adapter function, read as FYTTD1's own function (the run calls FYTTD1 the adapter). -/
def S4 : Statement where
  id := "S4"
  text := "loss of FYTTD1's mRNA export adapter function leads to motor neuron degeneration"
  claim := .effect FYTTD1 .neg (.phenotype mnDegeneration)
  evidence := []

/-- Run step H2.1: ELAC2 is required for pre-tRNA 3'-end processing (losing ELAC2 lowers it). -/
def S5 : Statement where
  id := "S5"
  text := "ELAC2 is required for pre-tRNA 3'-end processing (losing ELAC2 lowers it)"
  claim := .effect ELAC2 .pos (.process trna3End)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9BQ52", kind := .curatedDb, note := "Involved in tRNA maturation, by removing a 3'-trailer from precursor tRNA" }
  ]

/-- Run step H2.2: pre-tRNA 3'-end processing goes with tRNA-derived fragment biogenesis (direction not given). -/
def S6 : Statement where
  id := "S6"
  text := "pre-tRNA 3'-end processing goes with tRNA-derived fragment biogenesis (direction not given)"
  claim := .assoc trna3End none (.process trfProcessing)
  evidence := []

/-- Run step H2.3: angiogenin-generated tRNA fragments (tiRNAs) inhibit translation. -/
def S7 : Statement where
  id := "S7"
  text := "angiogenin-generated tRNA fragments (tiRNAs) inhibit translation"
  claim := .effect tiRna .neg (.process translation)
  evidence := [
    { pmid := 19332886, year := 2009, kind := .inVitro, note := "transfection of angiogenin-induced tiRNAs promotes phospho-eIF2alpha-independent translational arrest" }
  ]

/-- Run step H2.4: impaired tRNA maturation leads to neurodegeneration. Sign: inverted: the run's subject is 'disordered tRNA maturation', which carries no direction; read as impaired maturation, as the run's mechanism (partial ELAC2 loss of function) and PMID:24766810 (defective CLP1, impaired pre-tRNA cleavage) giv. -/
def S8 : Statement where
  id := "S8"
  text := "impaired tRNA maturation leads to neurodegeneration"
  claim := .effect trnaProcessing .neg (.phenotype neurodegeneration)
  evidence := [
    { pmid := 24766810, year := 2014, kind := .observational, note := "Our data link tRNA maturation to neuronal development and neurodegeneration through defective CLP1 function in humans" }
  ]

/-- Bridge, not in the run: ELAC2 is involved in tRNA maturation (bridge from the run's own UniProt citation). -/
def B1 : Statement where
  id := "B1"
  text := "ELAC2 is involved in tRNA maturation (bridge from the run's own UniProt citation)"
  claim := .effect ELAC2 .pos (.process trnaProcessing)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9BQ52", kind := .curatedDb, note := "Involved in tRNA maturation" }
  ]

/-- Run step H3.1: ELAC2 is required for mitochondrial RNA processing. -/
def S9 : Statement where
  id := "S9"
  text := "ELAC2 is required for mitochondrial RNA processing"
  claim := .effect ELAC2 .pos (.process mtRnaProcessing)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9BQ52", kind := .curatedDb, note := "Associates with mitochondrial DNA complexes at the nucleoids to initiate RNA processing and ribosome assembly" }
  ]

/-- Run step H3.1: ELAC2 is required for mitochondrial ribosome assembly. -/
def S10 : Statement where
  id := "S10"
  text := "ELAC2 is required for mitochondrial ribosome assembly"
  claim := .effect ELAC2 .pos (.process mtRibosomeAssembly)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9BQ52", kind := .curatedDb, note := "Associates with mitochondrial DNA complexes at the nucleoids to initiate RNA processing and ribosome assembly" }
  ]

/-- Run step H3.2: loss of ELAC2 lowers oxidative phosphorylation in striated muscle. Sign: inverted: the run's subject is Elac2 conditional deletion; the step's context and note limit the result to striated muscle (Ckmm-cre), so the target is refined. -/
def S11 : Statement where
  id := "S11"
  text := "loss of ELAC2 lowers oxidative phosphorylation in striated muscle"
  claim := .effect ELAC2 .pos (.process oxphosStriatedMuscle)
  evidence := []

/-- Run step H3.3: impaired mitochondrial ATP production leads to motor neuron degeneration. Sign: inverted: the run's subject is impaired mitochondrial ATP production, merged with oxidative phosphorylation (the run's mechanism names OXPHOS for this node). -/
def S12 : Statement where
  id := "S12"
  text := "impaired mitochondrial ATP production leads to motor neuron degeneration"
  claim := .effect oxphos .neg (.phenotype mnDegeneration)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, B1, S9, S10, S11, S12]

/-- H1, claim 2: FYTTD1/UIF is a candidate effector of the ALS nucleocytoplasmic mRNA-export block, not a risk gene. -/
def h1c2a1 := lit S4

/-- H2, claim 2: ELAC2 (RNase Z) sets the substrate pool for angiogenin-driven tRNA fragments implicated in motor neuron stress responses. -/
def h2c2a1 := viaProcess (lit B1) (lit S8)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c2a1" h1c2a1,
    arm "H2" "c2a1" h2c2a1]

#eval printRows "fyttd1-elac2-als-or" rows

end BioLean.Lib.IPF.Runs.Rfyttd1_elac2_als_or
