import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/20260825T001904Z-38b8c6/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `20260825T001904Z-38b8c6`: anthropic:claude-opus-5, restless legs syndrome, genes ACO1, MEIS1, GLIPR1, PTPRD, GABARAPL2, BTBD9. -/

namespace BioLean.Lib.IPF.Runs.R20260825T001904Z_38b8c6

open BioLean BioLean.Lib.IPF Derivation

def rs113851554 : Entity .variant := ⟨"dbSNP:rs113851554", "rs113851554 T allele (MEIS1 intron; the RLS risk allele)"⟩
def rs10947738 : Entity .variant := ⟨"dbSNP:rs10947738", "rs10947738 A allele (BTBD9 intron; the RLS risk allele)"⟩
def MEIS1 : Entity .protein := ⟨"UniProt:O00470", "MEIS1"⟩
def BTBD9 : Entity .protein := ⟨"UniProt:Q96Q07", "BTBD9"⟩
def ACO1 : Entity .protein := ⟨"UniProt:P21399", "ACO1"⟩
def PTPRD : Entity .protein := ⟨"UniProt:P23468", "PTPRD"⟩
def GABARAPL2 : Entity .protein := ⟨"UniProt:P60520", "GABARAPL2"⟩
def IL1RAPL1 : Entity .protein := ⟨"UniProt:Q9NZN1", "IL1RAPL1"⟩
def SLITRK2 : Entity .protein := ⟨"UniProt:Q9H156", "SLITRK2"⟩
def rls : Entity .disease := ⟨"MONDO:0005391", "restless legs syndrome"⟩
def cerebellarOutputInhibition : Entity .process := ⟨"BLN:CerebellarOutputInhibition", "inhibition of cerebellar output (inhibitory control of the cerebellum's output)"⟩
def circadianSleepWakeAbn : Entity .phenotype := ⟨"MP:0020478", "abnormal circadian sleep/wake cycle"⟩
def sleepDisturbance : Entity .phenotype := ⟨"HP:0002360", "Sleep disturbance"⟩
def movementAbn : Entity .phenotype := ⟨"HP:0100022", "Abnormality of movement"⟩
def ire : Entity .variant := ⟨"SO:0001182", "iron_responsive_element"⟩
def ironHomeostasis : Entity .process := ⟨"GO:0006879", "intracellular iron ion homeostasis"⟩
def iron : Entity .chemical := ⟨"CHEBI:18248", "iron atom"⟩
def brain : Entity .anatomy := ⟨"UBERON:0000955", "brain"⟩
def restlessLegs : Entity .phenotype := ⟨"HP:0012452", "Restless legs"⟩
def fcm : Entity .chemical := ⟨"CHEBI:753551", "ferric carboxymaltose"⟩
def presynapseAssembly : Entity .process := ⟨"GO:0099054", "presynapse assembly"⟩
def postsynapseAssembly : Entity .process := ⟨"GO:0099068", "postsynapse assembly"⟩
def ccStructure : Entity .phenotype := ⟨"OBA:0002757", "corpus callosum structure"⟩
def autophagosomeMaturation : Entity .process := ⟨"GO:0097352", "autophagosome maturation"⟩
def mitophagy : Entity .process := ⟨"GO:0000423", "mitophagy"⟩
def tcaCycle : Entity .process := ⟨"GO:0006099", "tricarboxylic acid cycle"⟩
def nadphRegeneration : Entity .process := ⟨"GO:0006740", "NADPH regeneration"⟩
def metabolismAbn : Entity .phenotype := ⟨"MP:0005266", "abnormal metabolism"⟩
def brainPhysiologyAbn : Entity .phenotype := ⟨"MP:0014812", "abnormal brain physiology"⟩
def brainIron : Entity .chemical := iron.inCtx { anatomy := brain }

/-- Run step H1.1: the rs113851554 T allele lowers MEIS1. -/
def S1 : Statement where
  id := "S1"
  text := "the rs113851554 T allele lowers MEIS1"
  claim := .effect rs113851554 .neg (.amount MEIS1)
  evidence := []

/-- Run step H1.2: MEIS1 is required for inhibition of cerebellar output (losing it disinhibits that output). -/
def S2 : Statement where
  id := "S2"
  text := "MEIS1 is required for inhibition of cerebellar output (losing it disinhibits that output)"
  claim := .effect MEIS1 .pos (.process cerebellarOutputInhibition)
  evidence := [
    { pmid := 42309051, year := 2026, kind := .mechanistic, note := "Disinhibition of cerebellar output by loss of restless legs syndrome-associated gene MEIS1", taxon := some Taxa.zebrafish }
  ]

/-- Run step H1.3: MEIS1 loss leads to an abnormal circadian sleep/wake cycle. Sign: inverted: the run's subject is loss of MEIS1. -/
def S3 : Statement where
  id := "S3"
  text := "MEIS1 loss leads to an abnormal circadian sleep/wake cycle"
  claim := .effect MEIS1 .neg (.phenotype circadianSleepWakeAbn)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:104717:MP:0020478", kind := .curatedDb, note := "the genotype Meis1<em1Rihw>/Meis1<em1Rihw> of Meis1 -- the orthologue of human MEIS1 -- shows abnormal circadian sleep/wake cycle", taxon := some Taxa.mouse }
  ]

/-- Run step H1.4, H5.4: BTBD9 loss leads to abnormal sleep (abnormal sleep behaviour). Sign: inverted: the run's subject is loss of BTBD9. -/
def S4 : Statement where
  id := "S4"
  text := "BTBD9 loss leads to abnormal sleep (abnormal sleep behaviour)"
  claim := .effect BTBD9 .neg (.phenotype sleepDisturbance)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1916625:MP:0011396", kind := .curatedDb, note := "the genotype Btbd9<tm1c(EUCOMM)Wtsi>/Btbd9<tm1c(EUCOMM)Wtsi> Tg(Pcp2-cre)2Mpin/0 of Btbd9 -- the orthologue of human BTBD9 -- shows abnormal sleep behavior", taxon := some Taxa.mouse }
  ]

/-- Run step H1.5: sleep disturbance goes with RLS (the sleep half of 'abnormal sleep/motor output'). Sign: the run gives no polarity; direction from PMID:17634447, which says RLS causes sleep disruption: the association runs from the disease to the feature. -/
def S5 : Statement where
  id := "S5"
  text := "sleep disturbance goes with RLS (the sleep half of 'abnormal sleep/motor output')"
  claim := .assoc sleepDisturbance (some .pos) (.disease rls)
  evidence := [
    { pmid := 17634447, year := 2007, kind := .review, note := "restless legs syndrome (RLS) is a common neurologic disorder characterized by an irresistible urge to move the legs. It is a major cause of sleep disruption" }
  ]

/-- Run step H1.5: abnormal movement goes with RLS (the motor half of 'abnormal sleep/motor output'). Sign: the run gives no polarity; direction from PMID:17634447 (periodic limb movements in sleep in most RLS patients), a disease feature. -/
def S6 : Statement where
  id := "S6"
  text := "abnormal movement goes with RLS (the motor half of 'abnormal sleep/motor output')"
  claim := .assoc movementAbn (some .pos) (.disease rls)
  evidence := [
    { pmid := 17634447, year := 2007, kind := .review, note := "Periodic limb movements in sleep are detectable in most patients with RLS" }
  ]

/-- Run step H2.1: ACO1 (IRP1) binds iron-responsive elements. -/
def S7 : Statement where
  id := "S7"
  text := "ACO1 (IRP1) binds iron-responsive elements"
  claim := .rel ⟨.ro, 2436, false⟩ ACO1 ire
  evidence := [
    { pmid := 0, year := 2026, ref := "P21399", kind := .curatedDb, note := "Binds to iron-responsive elements (IRES) in the untranslated region of target mRNAs preventing for instance the translation of ferritin" }
  ]

/-- Run step H2.2: ACO1 is required for iron homeostasis. -/
def S8 : Statement where
  id := "S8"
  text := "ACO1 is required for iron homeostasis"
  claim := .effect ACO1 .pos (.process ironHomeostasis)
  evidence := []

/-- Run step H2.3: brain iron deficiency produces RLS-like motor behaviour. Sign: inverted: the run's subject is brain iron deficiency. -/
def S9 : Statement where
  id := "S9"
  text := "brain iron deficiency produces RLS-like motor behaviour"
  claim := .effect brainIron .neg (.phenotype restlessLegs)
  evidence := [
    { pmid := 32094092, year := 2020, kind := .mechanistic, note := "strongly support the hypothesis that the biology of RLS BID can produce RLS symptoms", taxon := some Taxa.mouse }
  ]

/-- Run step H2.4: iron repletion with ferric carboxymaltose lessens RLS. -/
def S10 : Statement where
  id := "S10"
  text := "iron repletion with ferric carboxymaltose lessens RLS"
  claim := .effect fcm .neg (.disease rls .severity)
  evidence := []

/-- Run step H3.1: PTPRD binds IL1RAPL1. -/
def S11 : Statement where
  id := "S11"
  text := "PTPRD binds IL1RAPL1"
  claim := .rel ⟨.ro, 2436, false⟩ PTPRD IL1RAPL1
  evidence := [
    { pmid := 0, year := 2026, ref := "P23468", kind := .crossSpecies, note := "Can bidirectionally induce pre- and post-synaptic differentiation of neurons by mediating interaction with IL1RAP and IL1RAPL1 trans-synaptically" }
  ]

/-- Run step H3.1: PTPRD binds SLITRK2. -/
def S12 : Statement where
  id := "S12"
  text := "PTPRD binds SLITRK2"
  claim := .rel ⟨.ro, 2436, false⟩ PTPRD SLITRK2
  evidence := [
    { pmid := 0, year := 2026, ref := "P23468", kind := .crossSpecies, note := "Involved in pre-synaptic differentiation through interaction with SLITRK2" }
  ]

/-- Run step H3.2: PTPRD is required for presynaptic differentiation. -/
def S13 : Statement where
  id := "S13"
  text := "PTPRD is required for presynaptic differentiation"
  claim := .effect PTPRD .pos (.process presynapseAssembly)
  evidence := [
    { pmid := 0, year := 2026, ref := "P23468", kind := .crossSpecies, note := "Can bidirectionally induce pre- and post-synaptic differentiation of neurons" }
  ]

/-- Run step H3.2: PTPRD is required for postsynaptic differentiation. -/
def S14 : Statement where
  id := "S14"
  text := "PTPRD is required for postsynaptic differentiation"
  claim := .effect PTPRD .pos (.process postsynapseAssembly)
  evidence := [
    { pmid := 0, year := 2026, ref := "P23468", kind := .crossSpecies, note := "Can bidirectionally induce pre- and post-synaptic differentiation of neurons" }
  ]

/-- Run step H3.3, H4.3: variation at PTPRD goes with RLS (no single direction). -/
def S15 : Statement where
  id := "S15"
  text := "variation at PTPRD goes with RLS (no single direction)"
  claim := .assoc PTPRD none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs34602324", kind := .observational, note := "rs34602324-G is associated with 'Restless legs syndrome' at p = 5e-162, beta 0.120799 unit (increase) [0.11-0.13] (mapped gene PTPRD" },
    { pmid := 0, year := 2026, ref := "rs1836229", kind := .observational, note := "rs1836229-A is associated with 'Restless legs syndrome' at p = 7e-42, odds ratio 1.1111112 [1.1-1.12] (author-reported gene PTPRD" },
    { pmid := 0, year := 2026, ref := "rs4626664", kind := .observational, note := "rs4626664-A is associated with 'Restless legs syndrome' at p = 6e-10, odds ratio 1.44 [1.31-1.59] (author-reported gene PTPRD" },
    { pmid := 0, year := 2026, ref := "OT:PTPRD-MONDO_0005391", kind := .observational, note := "Open Targets 2026.06 scores the PTPRD-restless legs syndrome association at 0.39 (literature 0.20, genetic_association 0.63)" },
    { pmid := 0, year := 2026, ref := "rs6477358", kind := .observational, note := "rs6477358-T is associated with 'Restless legs syndrome' at p = 9e-110, beta 0.13158695 unit (decrease) [0.12-0.14] (mapped gene PTPRD" },
    { pmid := 0, year := 2026, ref := "rs1975197", kind := .observational, note := "rs1975197-A is associated with 'Restless legs syndrome' at p = 3e-10, odds ratio 1.29 [1.19-1.40] (author-reported gene PTPRD" }
  ]

/-- Run step H3.4: variation at PTPRD goes with corpus callosum microstructure. -/
def S16 : Statement where
  id := "S16"
  text := "variation at PTPRD goes with corpus callosum microstructure"
  claim := .assoc PTPRD none (.phenotype ccStructure)
  evidence := []

/-- Run step H4.1: GABARAPL2 is required for autophagosome maturation. -/
def S17 : Statement where
  id := "S17"
  text := "GABARAPL2 is required for autophagosome maturation"
  claim := .effect GABARAPL2 .pos (.process autophagosomeMaturation)
  evidence := [
    { pmid := 0, year := 2026, ref := "P60520", kind := .curatedDb, note := "the GABARAP/GATE-16 subfamily is essential for a later stage in autophagosome maturation" }
  ]

/-- Run step H4.1: GABARAPL2 is required for mitophagy. -/
def S18 : Statement where
  id := "S18"
  text := "GABARAPL2 is required for mitophagy"
  claim := .effect GABARAPL2 .pos (.process mitophagy)
  evidence := []

/-- Run step H4.2: ACO1 goes with the TCA cycle. -/
def S19 : Statement where
  id := "S19"
  text := "ACO1 goes with the TCA cycle"
  claim := .assoc ACO1 none (.process tcaCycle)
  evidence := []

/-- Run step H4.2: ACO1 goes with NADPH regeneration. -/
def S20 : Statement where
  id := "S20"
  text := "ACO1 goes with NADPH regeneration"
  claim := .assoc ACO1 none (.process nadphRegeneration)
  evidence := []

/-- Run step H4.3: MEIS1 goes with RLS (no single direction). -/
def S21 : Statement where
  id := "S21"
  text := "MEIS1 goes with RLS (no single direction)"
  claim := .assoc MEIS1 none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs113851554", kind := .observational, note := "rs113851554-T is associated with 'Restless legs syndrome' at p = 1e-1371, beta 0.668701 unit (increase) [0.65-0.69] (mapped gene MEIS1" },
    { pmid := 0, year := 2026, ref := "OT:MEIS1-MONDO_0005391", kind := .observational, note := "Open Targets 2026.06 scores the MEIS1-restless legs syndrome association at 0.55 (literature 0.18, genetic_association 0.82, genetic_literature 0.30)" },
    { pmid := 17637780, year := 2007, kind := .observational, note := "we found highly significant associations between RLS and intronic variants in the homeobox gene MEIS1, the BTBD9 gene" }
  ]

/-- Run step H4.3: BTBD9 goes with RLS (no single direction). -/
def S22 : Statement where
  id := "S22"
  text := "BTBD9 goes with RLS (no single direction)"
  claim := .assoc BTBD9 none (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs10947738", kind := .observational, note := "rs10947738-A is associated with 'Restless legs syndrome' at p = 1e-688, beta 0.282407 unit (increase) [0.27-0.29] (mapped gene BTBD9" },
    { pmid := 0, year := 2026, ref := "OT:BTBD9-MONDO_0005391", kind := .observational, note := "Open Targets 2026.06 scores the BTBD9-restless legs syndrome association at 0.48 (literature 0.16, genetic_association 0.72, genetic_literature 0.30)" },
    { pmid := 0, year := 2026, ref := "rs61192259", kind := .observational, note := "rs61192259-A is associated with 'Restless legs syndrome' at p = 4e-202, odds ratio 1.26 [1.25-1.28] (author-reported gene BTBD9" },
    { pmid := 0, year := 2026, ref := "rs9296249", kind := .observational, note := "rs9296249-T is associated with 'Restless legs syndrome' at p = 4e-18, odds ratio 1.67 [1.49-1.89] (author-reported gene BTBD9" },
    { pmid := 17637780, year := 2007, kind := .observational, note := "we found highly significant associations between RLS and intronic variants in the homeobox gene MEIS1, the BTBD9 gene" },
    { pmid := 17634447, year := 2007, kind := .observational, note := "In an Icelandic discovery sample of patients with RLS and periodic limb movements in sleep, we observed a genomewide significant association with a common variant in an intron of BTBD9 on chromosome 6p21.2 (odds ratio, 1.8; P=2x10(-9))" }
  ]

/-- Run step H5.1: BTBD9 binds ACO1. -/
def S23 : Statement where
  id := "S23"
  text := "BTBD9 binds ACO1"
  claim := .rel ⟨.ro, 2436, false⟩ BTBD9 ACO1
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:ACO1-BTBD9", kind := .curatedDb, note := "STRING links ACO1 and BTBD9 with combined score 0.45 (experimental 0.41, database 0.00, text-mining 0.09)" }
  ]

/-- Run step H5.2: BTBD9 lowers ACO1 (as a CUL3 substrate adaptor). -/
def S24 : Statement where
  id := "S24"
  text := "BTBD9 lowers ACO1 (as a CUL3 substrate adaptor)"
  claim := .effect BTBD9 .neg (.amount ACO1)
  evidence := []

/-- Run step H5.3: BTBD9 loss leads to abnormal metabolism. Sign: inverted: the run's subject is loss of BTBD9. -/
def S25 : Statement where
  id := "S25"
  text := "BTBD9 loss leads to abnormal metabolism"
  claim := .effect BTBD9 .neg (.phenotype metabolismAbn)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1916625:MP:0005266", kind := .curatedDb, note := "the genotype Btbd9<Gt(RRE078)Byg>/Btbd9<Gt(RRE078)Byg> of Btbd9 -- the orthologue of human BTBD9 -- shows abnormal metabolism", taxon := some Taxa.mouse }
  ]

/-- Run step H5.3: BTBD9 loss leads to abnormal brain physiology. Sign: inverted: the run's subject is loss of BTBD9. -/
def S26 : Statement where
  id := "S26"
  text := "BTBD9 loss leads to abnormal brain physiology"
  claim := .effect BTBD9 .neg (.phenotype brainPhysiologyAbn)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1916625:MP:0014812", kind := .curatedDb, note := "the genotype Btbd9<Gt(RRE078)Byg>/Btbd9<Gt(RRE078)Byg> of Btbd9 -- the orthologue of human BTBD9 -- shows abnormal brain physiology", taxon := some Taxa.mouse }
  ]

/-- Run step H5.5: the rs10947738 A allele goes with higher RLS risk. Sign: the run gives no polarity; direction from the GWAS row: rs10947738-A, beta increase. -/
def S27 : Statement where
  id := "S27"
  text := "the rs10947738 A allele goes with higher RLS risk"
  claim := .assoc rs10947738 (some .pos) (.disease rls)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs10947738", kind := .observational, note := "rs10947738-A is associated with 'Restless legs syndrome' at p = 1e-688, beta 0.282407 unit (increase) [0.27-0.29] (mapped gene BTBD9" }
  ]

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20, S21, S22, S23, S24, S25, S26, S27]

/-- H1, claim 2: MEIS1 and BTBD9 hypofunction produces the RLS phenotype through disinhibited motor output and disturbed sleep-wake architecture, not through a shared protein co. -/
def h1c2a1 := viaPhenotype (lit S4) (fromAssoc (lit S5))

/-- H5, claim 1: Convergence hypothesis: BTBD9 is the node where the iron set-point and the sleep/motor circuit arms meet. -/
def h5c1a1 := viaPhenotype (lit S4) (fromAssoc (lit S5))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c2a1" h1c2a1,
    arm "H5" "c1a1" h5c1a1]

#eval printRows "20260825T001904Z-38b8c6" rows

end BioLean.Lib.IPF.Runs.R20260825T001904Z_38b8c6
