import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/fyttd1-elac2-als-or-plus/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `fyttd1-elac2-als-or-plus`: openrouter:anthropic/claude-opus-5, amyotrophic lateral sclerosis, genes FYTTD1, ELAC2. -/

namespace BioLean.Lib.IPF.Runs.Rfyttd1_elac2_als_or_plus

open BioLean BioLean.Lib.IPF Derivation

def c9Hre : Entity .variant := ⟨"BLN:C9orf72-G4C2-repeat-expansion", "C9orf72 GGGGCC hexanucleotide repeat expansion"⟩
def tdp43Proteinopathy : Entity .disease := ⟨"MONDO:0700038", "TDP-43 proteinopathy"⟩
def nct : Entity .process := ⟨"GO:0006913", "nucleocytoplasmic transport"⟩
def FYTTD1 : Entity .protein := ⟨"UniProt:Q96QD9", "FYTTD1"⟩
def mrnaExport : Entity .process := ⟨"GO:0006406", "mRNA export from nucleus"⟩
def als : Entity .disease := ⟨"MONDO:0004976", "amyotrophic lateral sclerosis"⟩
def neurodegeneration : Entity .phenotype := ⟨"HP:0002180", "Neurodegeneration"⟩
def motorNeuron : Entity .cellType := ⟨"CL:0000100", "motor neuron"⟩
def ELAC2 : Entity .protein := ⟨"UniProt:Q9BQ52", "ELAC2"⟩
def trna3End : Entity .process := ⟨"GO:0042780", "tRNA 3'-end processing"⟩
def trnaProcessing : Entity .process := ⟨"GO:0008033", "tRNA processing"⟩
def mitoRnaProcessing : Entity .process := ⟨"GO:0000963", "mitochondrial RNA processing"⟩
def mitoRibosomeAssembly : Entity .process := ⟨"GO:0061668", "mitochondrial ribosome assembly"⟩
def oxPhos : Entity .process := ⟨"GO:0006119", "oxidative phosphorylation"⟩
def striatedMuscle : Entity .anatomy := ⟨"UBERON:0002036", "striated muscle tissue"⟩
def trfBiogenesis : Entity .process := ⟨"GO:0140891", "tRNA-derived regulatory ncRNA processing"⟩
def tiRna : Entity .chemical := ⟨"BLN:AngiogeninTiRNA", "angiogenin-induced tRNA-derived fragments (tiRNAs)"⟩
def translation : Entity .process := ⟨"GO:0006412", "translation"⟩
def mrnaPackaging : Entity .process := ⟨"BLN:CotranscriptionalMrnaPackagingByTrex", "co-transcriptional mRNA packaging by TREX"⟩
def trex : Entity .component := ⟨"GO:0000346", "transcription export complex"⟩
def rLoop : Entity .chemical := ⟨"BLN:RLoop", "R-loop (RNA-DNA hybrid with a displaced DNA strand)"⟩
def dnaDamage : Entity .process := ⟨"BLN:DnaDamage", "DNA damage"⟩
def dpr : Entity .protein := ⟨"BLN:C9orf72DipeptideRepeatProteins", "C9orf72 dipeptide repeat proteins (DPRs)"⟩
def mlOrganelleAssembly : Entity .process := ⟨"GO:0140694", "membraneless organelle assembly"⟩
def fyttd1InC9 : Entity .protein := FYTTD1.inCtx { condition := some (.organism c9Hre) }
def mrnaExportInAls : Entity .process := mrnaExport.inCtx { condition := some (.organism als) }
def mnDegeneration : Entity .phenotype := neurodegeneration.inCtx { cellType := motorNeuron }
def muscleOxPhos : Entity .process := oxPhos.inCtx { anatomy := striatedMuscle }

/-- Run step H1.1: The C9orf72 GGGGCC repeat expansion inhibits nucleocytoplasmic transport (first half of the compound subject). -/
def H1s1a : Statement where
  id := "H1s1a"
  text := "The C9orf72 GGGGCC repeat expansion inhibits nucleocytoplasmic transport (first half of the compound subject)"
  claim := .effect c9Hre .neg (.process nct)
  evidence := [
    { pmid := 26308891, year := 2015, kind := .inVitro, note := "The C9orf72 repeat expansion disrupts nucleocytoplasmic transport" },
    { pmid := 26308899, year := 2015, kind := .inVitro, note := "GGGGCC repeat expansion in C9orf72 compromises nucleocytoplasmic transport" }
  ]

/-- Run step H1.1: TDP-43 pathology (TDP-43 proteinopathy) inhibits nucleocytoplasmic transport (second half of the compound subject). -/
def H1s1b : Statement where
  id := "H1s1b"
  text := "TDP-43 pathology (TDP-43 proteinopathy) inhibits nucleocytoplasmic transport (second half of the compound subject)"
  claim := .effect tdp43Proteinopathy .neg (.process nct)
  evidence := [
    { pmid := 29311743, year := 2018, kind := .inVitro, note := "TDP-43 pathology disrupts nuclear pore complexes and nucleocytoplasmic transport" }
  ]

/-- Run step H1.2: FYTTD1 is required for mRNA export from the nucleus (required_for: losing FYTTD1 lowers export). -/
def H1s2 : Statement where
  id := "H1s2"
  text := "FYTTD1 is required for mRNA export from the nucleus (required_for: losing FYTTD1 lowers export)"
  claim := .effect FYTTD1 .pos (.process mrnaExport)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q96QD9", kind := .curatedDb, note := "Required for mRNA export from the nucleus to the cytoplasm" }
  ]

/-- Run step H1.3: Loss of mRNA export adapter function leads to motor neuron degeneration, so mRNA export lowers motor neuron degeneration. Sign: the run's subject is the loss of the function (leads_to, positive); grounded as the export process itself, so the same claim carries sign neg. -/
def H1s3 : Statement where
  id := "H1s3"
  text := "Loss of mRNA export adapter function leads to motor neuron degeneration, so mRNA export lowers motor neuron degeneration"
  claim := .effect mrnaExport .neg (.phenotype mnDegeneration)
  evidence := []

/-- Run step H2.1: ELAC2 is required for pre-tRNA 3'-end processing (required_for: losing ELAC2 lowers it). -/
def H2s1 : Statement where
  id := "H2s1"
  text := "ELAC2 is required for pre-tRNA 3'-end processing (required_for: losing ELAC2 lowers it)"
  claim := .effect ELAC2 .pos (.process trna3End)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9BQ52", kind := .curatedDb, note := "Involved in tRNA maturation, by removing a 3'-trailer from precursor tRNA" }
  ]

/-- Run step H2.2: Pre-tRNA 3'-end maturation is associated with tRNA-derived fragment (tsRNA/tRF) biogenesis. -/
def H2s2 : Statement where
  id := "H2s2"
  text := "Pre-tRNA 3'-end maturation is associated with tRNA-derived fragment (tsRNA/tRF) biogenesis"
  claim := .assoc trna3End none (.process trfBiogenesis)
  evidence := []

/-- Run step H2.3: Angiogenin-induced tRNA-derived fragments (tiRNAs) inhibit stress-induced protein translation. -/
def H2s3 : Statement where
  id := "H2s3"
  text := "Angiogenin-induced tRNA-derived fragments (tiRNAs) inhibit stress-induced protein translation"
  claim := .effect tiRna .neg (.process translation)
  evidence := [
    { pmid := 19332886, year := 2009, kind := .inVitro, note := "transfection of angiogenin-induced tiRNAs promotes phospho-eIF2alpha-independent translational arrest" }
  ]

/-- Run step H2.4: Disordered (defective) tRNA maturation leads to neurodegeneration, so tRNA maturation lowers neurodegeneration. Sign: the run's subject is 'disordered tRNA maturation' (leads_to, positive), read as defective maturation as in the cited CLP1 paper; grounded as tRNA processing (synonym 'tRNA maturation'), so the claim carries sign neg. -/
def H2s4 : Statement where
  id := "H2s4"
  text := "Disordered (defective) tRNA maturation leads to neurodegeneration, so tRNA maturation lowers neurodegeneration"
  claim := .effect trnaProcessing .neg (.phenotype neurodegeneration)
  evidence := [
    { pmid := 24766810, year := 2014, kind := .observational, note := "Our data link tRNA maturation to neuronal development and neurodegeneration through defective CLP1 function in humans" },
    { pmid := 40294208, year := 2025, kind := .review, note := "defects in tRNA processing may lead to neurological disorders" }
  ]

/-- Run step H3.1: ELAC2 is required for mitochondrial RNA processing (first half of the compound object; required_for). -/
def H3s1a : Statement where
  id := "H3s1a"
  text := "ELAC2 is required for mitochondrial RNA processing (first half of the compound object; required_for)"
  claim := .effect ELAC2 .pos (.process mitoRnaProcessing)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9BQ52", kind := .curatedDb, note := "Associates with mitochondrial DNA complexes at the nucleoids to initiate RNA processing and ribosome assembly" }
  ]

/-- Run step H3.1: ELAC2 is required for mitochondrial ribosome assembly (second half of the compound object; required_for). -/
def H3s1b : Statement where
  id := "H3s1b"
  text := "ELAC2 is required for mitochondrial ribosome assembly (second half of the compound object; required_for)"
  claim := .effect ELAC2 .pos (.process mitoRibosomeAssembly)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9BQ52", kind := .curatedDb, note := "Associates with mitochondrial DNA complexes at the nucleoids to initiate RNA processing and ribosome assembly" }
  ]

/-- Run step H3.2: Elac2 conditional deletion in striated muscle lowers oxidative phosphorylation there, so ELAC2 raises oxidative phosphorylation in striated muscle. Sign: the run's subject is the Elac2 deletion (decreases_amount, negative); grounded as ELAC2 itself, so the same claim carries sign pos. decreases_amount on a process is read as a process target. The run's context (striated muscle, Ckmm-cre) is . -/
def H3s2 : Statement where
  id := "H3s2"
  text := "Elac2 conditional deletion in striated muscle lowers oxidative phosphorylation there, so ELAC2 raises oxidative phosphorylation in striated muscle"
  claim := .effect ELAC2 .pos (.process muscleOxPhos)
  evidence := []

/-- Run step H3.3: Impaired mitochondrial ATP production leads to motor neuron degeneration, so oxidative phosphorylation lowers motor neuron degeneration. Sign: the run's subject is 'impaired mitochondrial ATP production' (leads_to, positive); grounded as oxidative phosphorylation, so the claim carries sign neg. -/
def H3s3 : Statement where
  id := "H3s3"
  text := "Impaired mitochondrial ATP production leads to motor neuron degeneration, so oxidative phosphorylation lowers motor neuron degeneration"
  claim := .effect oxPhos .neg (.phenotype mnDegeneration)
  evidence := []

/-- Run step H4.1: FYTTD1 is required for mRNA export from the nucleus (required_for: losing FYTTD1 lowers export). -/
def H4s1 : Statement where
  id := "H4s1"
  text := "FYTTD1 is required for mRNA export from the nucleus (required_for: losing FYTTD1 lowers export)"
  claim := .effect FYTTD1 .pos (.process mrnaExport)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q96QD9", kind := .curatedDb, note := "Required for mRNA export from the nucleus to the cytoplasm" }
  ]

/-- Run step H4.2: The C9orf72 GGGGCC repeat expansion inhibits nucleocytoplasmic transport (first half of the compound subject). -/
def H4s2a : Statement where
  id := "H4s2a"
  text := "The C9orf72 GGGGCC repeat expansion inhibits nucleocytoplasmic transport (first half of the compound subject)"
  claim := .effect c9Hre .neg (.process nct)
  evidence := [
    { pmid := 26308891, year := 2015, kind := .inVitro, note := "The C9orf72 repeat expansion disrupts nucleocytoplasmic transport" },
    { pmid := 26308899, year := 2015, kind := .inVitro, note := "GGGGCC repeat expansion in C9orf72 compromises nucleocytoplasmic transport" }
  ]

/-- Run step H4.2: TDP-43 pathology (TDP-43 proteinopathy) inhibits nucleocytoplasmic transport (second half of the compound subject). -/
def H4s2b : Statement where
  id := "H4s2b"
  text := "TDP-43 pathology (TDP-43 proteinopathy) inhibits nucleocytoplasmic transport (second half of the compound subject)"
  claim := .effect tdp43Proteinopathy .neg (.process nct)
  evidence := [
    { pmid := 29311743, year := 2018, kind := .inVitro, note := "TDP-43 pathology disrupts nuclear pore complexes and nucleocytoplasmic transport" }
  ]

/-- Run step H4.3: Reduced mRNA export capacity on an ALS background leads to motor neuron degeneration, so mRNA export (in ALS) lowers motor neuron degeneration. Sign: inverted: the run's subject is 'reduced mRNA export capacity' (leads_to, positive); grounded as mRNA export, so the claim carries sign neg. The step's note limits the result to an ALS background, kept as the condition refinement mrnaExportI. -/
def H4s3 : Statement where
  id := "H4s3"
  text := "Reduced mRNA export capacity on an ALS background leads to motor neuron degeneration, so mRNA export (in ALS) lowers motor neuron degeneration"
  claim := .effect mrnaExportInAls .neg (.phenotype mnDegeneration)
  evidence := []

/-- Run step H6.1: FYTTD1 is required for NXF1-dependent mRNA export (required_for; the NXF1 qualifier is dropped). -/
def H6s1 : Statement where
  id := "H6s1"
  text := "FYTTD1 is required for NXF1-dependent mRNA export (required_for; the NXF1 qualifier is dropped)"
  claim := .effect FYTTD1 .pos (.process mrnaExport)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q96QD9", kind := .curatedDb, note := "Required for mRNA export from the nucleus to the cytoplasm" }
  ]

/-- Run step H5.1: FYTTD1 is required for co-transcriptional mRNA packaging by TREX (required_for). -/
def H5s1 : Statement where
  id := "H5s1"
  text := "FYTTD1 is required for co-transcriptional mRNA packaging by TREX (required_for)"
  claim := .effect FYTTD1 .pos (.process mrnaPackaging)
  evidence := []

/-- Run step H5.2: Loss of TREX function raises R-loops, so TREX lowers R-loops. Sign: inverted: the run's subject is 'loss of TREX function' (increases_amount R-loops, positive); grounded as the TREX complex, so the claim carries sign neg. -/
def H5s2 : Statement where
  id := "H5s2"
  text := "Loss of TREX function raises R-loops, so TREX lowers R-loops"
  claim := .effect trex .neg (.amount rLoop)
  evidence := [
    { pmid := 38331934, year := 2024, kind := .mechanistic, note := "compromised THOC2/TREX function resulting in R-loop accumulation", taxon := some Taxa.mouse }
  ]

/-- Run step H5.3: R-loop-driven DNA damage leads to motor neuron degeneration. -/
def H5s3 : Statement where
  id := "H5s3"
  text := "R-loop-driven DNA damage leads to motor neuron degeneration"
  claim := .effect dnaDamage .pos (.phenotype mnDegeneration)
  evidence := []

/-- Run step H6.2: C9orf72 dipeptide repeat proteins impair membrane-less organelle assembly/function (organelle half of the compound object). -/
def H6s2a : Statement where
  id := "H6s2a"
  text := "C9orf72 dipeptide repeat proteins impair membrane-less organelle assembly/function (organelle half of the compound object)"
  claim := .effect dpr .neg (.process mlOrganelleAssembly)
  evidence := [
    { pmid := 27768896, year := 2016, kind := .inVitro, note := "C9orf72 Dipeptide Repeats Impair the Assembly, Dynamics, and Function of Membrane-Less Organelles" }
  ]

def statements : List Statement := [H1s1a, H1s1b, H1s2, H1s3, H2s1, H2s2, H2s3, H2s4, H3s1a, H3s1b, H3s2, H3s3, H4s1, H4s2a, H4s2b, H4s3, H6s1, H5s1, H5s2, H5s3, H6s2a]

/-- H1, claim 2: FYTTD1/UIF is a candidate effector of the ALS nucleocytoplasmic mRNA-export block, not a risk gene. -/
def h1c2a1 := viaProcess (lit H1s2) (lit H1s3)

/-- H1, claim 2: FYTTD1/UIF is a candidate effector of the ALS nucleocytoplasmic mRNA-export block, not a risk gene. -/
def h1c2a2 := viaProcess (lit H4s1) (lit H1s3)

/-- H1, claim 2: FYTTD1/UIF is a candidate effector of the ALS nucleocytoplasmic mRNA-export block, not a risk gene. -/
def h1c2a3 := viaProcess (lit H6s1) (lit H1s3)

/-- H4, claim 2: FYTTD1 haploinsufficiency lowers mRNA-export capacity and the threshold for ALS. -/
def h4c2a1 := viaProcess (lit H1s2) (lit H1s3)

/-- H4, claim 2: FYTTD1 haploinsufficiency lowers mRNA-export capacity and the threshold for ALS. -/
def h4c2a2 := viaProcess (lit H4s1) (lit H1s3)

/-- H4, claim 2: FYTTD1 haploinsufficiency lowers mRNA-export capacity and the threshold for ALS. -/
def h4c2a3 := viaProcess (lit H6s1) (lit H1s3)

/-- H5, claim 1: FYTTD1 loss leaves RNA unshielded, causing R-loops and DNA damage in motor neurons. -/
def h5c1a1 := viaProcess (lit H1s2) (lit H1s3)

/-- H5, claim 1: FYTTD1 loss leaves RNA unshielded, causing R-loops and DNA damage in motor neurons. -/
def h5c1a2 := viaProcess (lit H4s1) (lit H1s3)

/-- H5, claim 1: FYTTD1 loss leaves RNA unshielded, causing R-loops and DNA damage in motor neurons. -/
def h5c1a3 := viaProcess (lit H6s1) (lit H1s3)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c2a1" h1c2a1,
    arm "H1" "c2a2" h1c2a2,
    arm "H1" "c2a3" h1c2a3,
    arm "H4" "c2a1" h4c2a1,
    arm "H4" "c2a2" h4c2a2,
    arm "H4" "c2a3" h4c2a3,
    arm "H5" "c1a1" h5c1a1,
    arm "H5" "c1a2" h5c1a2,
    arm "H5" "c1a3" h5c1a3]

#eval printRows "fyttd1-elac2-als-or-plus" rows

end BioLean.Lib.IPF.Runs.Rfyttd1_elac2_als_or_plus
