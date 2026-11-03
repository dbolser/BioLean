import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/study-2026-09-crohn-openrouter-anthropicclaude-opus-5-multi_agent-r2/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `study-2026-09-crohn-openrouter-anthropicclaude-opus-5-multi_agent-r2`: openrouter:anthropic/claude-opus-5, Crohn disease, genes IL12B, IL23R, NOD2, LACC1, GPR35, MEIS1, TRIM4. -/

namespace BioLean.Lib.IPF.Runs.Rstudy_2026_09_crohn_openrouter_anthropicclaude_opus_5_multi_agent_r2

open BioLean BioLean.Lib.IPF Derivation

def il23rRiskHaplotype : Entity .variant := ⟨"BLN:IL23R-risk-haplotype-rs7517847A-rs11465804T", "IL23R risk haplotype (rs7517847-A, rs11465804-T)"⟩
def il12b : Entity .protein := ⟨"UniProt:P29460", "IL12B"⟩
def il23Production : Entity .process := ⟨"GO:0032627", "interleukin-23 production"⟩
def il23Signalling : Entity .process := ⟨"GO:0038155", "interleukin-23-mediated signaling pathway"⟩
def th17Commitment : Entity .process := ⟨"GO:0072540", "T-helper 17 cell lineage commitment"⟩
def il17Production : Entity .process := ⟨"GO:0032620", "interleukin-17 production"⟩
def crohn : Entity .disease := ⟨"MONDO:0005011", "Crohn disease"⟩
def rs2066847 : Entity .variant := ⟨"dbSNP:rs2066847", "NOD2 frameshift variant rs2066847 (T allele)"⟩
def nod2Signalling : Entity .process := ⟨"GO:0070431", "nucleotide-binding oligomerization domain containing 2 signaling pathway"⟩
def autophagy : Entity .process := ⟨"GO:0006914", "autophagy"⟩
def lacc1 : Entity .protein := ⟨"UniProt:Q8IV20", "LACC1"⟩
def colonMacrophage : Entity .cellType := ⟨"CL:0009038", "colon macrophage"⟩
def cytokineProduction : Entity .process := ⟨"GO:0001816", "cytokine production"⟩
def bacterialDefense : Entity .process := ⟨"GO:0042742", "defense response to bacterium"⟩
def rs3749172 : Entity .variant := ⟨"dbSNP:rs3749172", "GPR35 missense variant rs3749172 (A allele)"⟩
def rs34236350 : Entity .variant := ⟨"dbSNP:rs34236350", "GPR35 intron variant rs34236350 (effect allele not reported)"⟩
def gpr35 : Entity .protein := ⟨"UniProt:Q9HC97", "GPR35"⟩
def kynurenicAcid : Entity .chemical := ⟨"CHEBI:18344", "kynurenic acid"⟩
def hiaa : Entity .chemical := ⟨"CHEBI:27823", "(5-hydroxyindol-3-yl)acetic acid"⟩
def lysophosphatidicAcid : Entity .chemical := ⟨"CHEBI:132742", "lysophosphatidic acid"⟩
def epithelialMaintenance : Entity .process := ⟨"GO:0060729", "intestinal epithelial structure maintenance"⟩
def colitis : Entity .disease := ⟨"MONDO:0005292", "colitis"⟩
def crohnColitis : Entity .disease := ⟨"MONDO:0005532", "Crohn's colitis"⟩
def inflammatoryResponse : Entity .process := ⟨"GO:0006954", "inflammatory response"⟩
def mesentery : Entity .anatomy := ⟨"UBERON:0002095", "mesentery"⟩
def lacc1ColonMacrophage : Entity .protein := lacc1.inCtx { cellType := colonMacrophage }
def mesentericInflammation : Entity .process := inflammatoryResponse.inCtx { anatomy := mesentery, condition := some (.organism crohn) }

/-- Run step H1.1: the IL23R risk haplotype raises IL-23 receptor signalling (run relation increases_amount, applied to a process). -/
def H1_1 : Statement where
  id := "H1_1"
  text := "the IL23R risk haplotype raises IL-23 receptor signalling (run relation increases_amount, applied to a process)"
  claim := .effect il23rRiskHaplotype .pos (.process il23Signalling)
  evidence := []

/-- Run step H1.2: IL12B (p40) is required for IL-23 heterodimer formation, grounded as interleukin-23 production (GO: appearance of IL-23 by biosynthesis or secretion) (run relation required_for, read as a positive effect). -/
def H1_2a : Statement where
  id := "H1_2a"
  text := "IL12B (p40) is required for IL-23 heterodimer formation, grounded as interleukin-23 production (GO: appearance of IL-23 by biosynthesis or secretion) (run relation required_for, read as a positive effect)"
  claim := .effect il12b .pos (.process il23Production)
  evidence := []

/-- Run step H1.2: IL12B (p40) is required for T-helper 17 lineage commitment (run relation required_for, read as a positive effect). -/
def H1_2b : Statement where
  id := "H1_2b"
  text := "IL12B (p40) is required for T-helper 17 lineage commitment (run relation required_for, read as a positive effect)"
  claim := .effect il12b .pos (.process th17Commitment)
  evidence := []

/-- Bridge, not in the run: T-helper 17 lineage commitment raises IL-17 production: a Th17 cell is defined as a T cell that produces IL-17. -/
def B1 : Statement where
  id := "B1"
  text := "T-helper 17 lineage commitment raises IL-17 production: a Th17 cell is defined as a T cell that produces IL-17"
  claim := .effect th17Commitment .pos (.process il17Production)
  evidence := [
    { pmid := 0, year := 2026, ref := "GO:0072540", kind := .textbook, note := "becomes committed to becoming a T-helper 17 cell, a CD4-positive, alpha-beta T cell with the phenotype RORgamma-t-positive that produces IL-17" }
  ]

/-- Run step H1.3: IL-23-driven IL-17 production raises the risk of Crohn disease. -/
def H1_3 : Statement where
  id := "H1_3"
  text := "IL-23-driven IL-17 production raises the risk of Crohn disease"
  claim := .effect il17Production .pos (.disease crohn)
  evidence := []

/-- Run step H2.1: the NOD2 frameshift variant rs2066847 lowers NOD2 (MDP-RIPK2-NF-kB) signalling. -/
def H2_1a : Statement where
  id := "H2_1a"
  text := "the NOD2 frameshift variant rs2066847 lowers NOD2 (MDP-RIPK2-NF-kB) signalling"
  claim := .effect rs2066847 .neg (.process nod2Signalling)
  evidence := [
    { pmid := 11385576, year := 2001, kind := .hypothesis, polarity := .refutes, note := "the NOD2 gene product confers susceptibility to Crohn's disease by altering the recognition of these components and/or by over-activating NF-kB in monocytes" }
  ]

/-- Run step H2.1: the NOD2 frameshift variant rs2066847 lowers ATG16L1-dependent autophagy. -/
def H2_1b : Statement where
  id := "H2_1b"
  text := "the NOD2 frameshift variant rs2066847 lowers ATG16L1-dependent autophagy"
  claim := .effect rs2066847 .neg (.process autophagy)
  evidence := []

/-- Run step H2.2: LACC1 is required for optimal NOD2-induced cytokine secretion (run relation required_for, read as a positive effect). -/
def H2_2a : Statement where
  id := "H2_2a"
  text := "LACC1 is required for optimal NOD2-induced cytokine secretion (run relation required_for, read as a positive effect)"
  claim := .effect lacc1 .pos (.process cytokineProduction)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8IV20", kind := .curatedDb, note := "associates with the NOD2-signaling complex and promotes optimal NOD2-induced signaling, cytokine secretion and bacterial clearance" },
    { pmid := 0, year := 2026, ref := "AGR:MGI:2445077:MP:0008642", kind := .curatedDb, note := "of Lacc1 -- the orthologue of human LACC1 -- shows decreased circulating interleukin-1 beta level", taxon := some Taxa.mouse }
  ]

/-- Run step H2.2: LACC1 is required for bacterial clearance by macrophages (run relation required_for, read as a positive effect). -/
def H2_2b : Statement where
  id := "H2_2b"
  text := "LACC1 is required for bacterial clearance by macrophages (run relation required_for, read as a positive effect)"
  claim := .effect lacc1 .pos (.process bacterialDefense)
  evidence := [
    { pmid := 0, year := 2026, ref := "Q8IV20", kind := .curatedDb, note := "associates with the NOD2-signaling complex and promotes optimal NOD2-induced signaling, cytokine secretion and bacterial clearance" },
    { pmid := 27959965, year := 2016, kind := .review, note := "LACC1 function appears to promote fatty-acid oxidation, with concomitant inflammasome activation, reactive oxygen species production, and anti-bacterial responses in macrophages" }
  ]

/-- Run step H2.3: LACC1 in colon macrophages is associated with Crohn disease: detected in more Crohn than normal colon macrophages. Sign: the step is associated_with with unknown polarity; the direction is from the cited CELLxGENE record (LACC1 detected in 17.3% of 872 Crohn vs 12.4% of 12,108 normal colon macrophages); the run's own note warns the two groups come from separa. -/
def H2_3 : Statement where
  id := "H2_3"
  text := "LACC1 in colon macrophages is associated with Crohn disease: detected in more Crohn than normal colon macrophages"
  claim := .assoc lacc1ColonMacrophage (some .pos) (.disease crohn)
  evidence := [
    { pmid := 0, year := 2026, ref := "CXG:ENSG00000179630:CL_0000235:MONDO_0005011", kind := .observational, note := "LACC1 (ENSG00000179630) is detected in 17.3% of 872 cells annotated macrophage (CL:0000235) from donors annotated Crohn disease (MONDO:0005011), against 12.4% of 12,108 such cells from donors annotated normal" }
  ]

/-- Run step H2.4: defective myeloid bacterial handling raises the risk of Crohn disease; written as: bacterial defence lowers it. Sign: inverted: the run's subject is defective (loss of) bacterial handling, which leads_to Crohn disease (+). -/
def H2_4 : Statement where
  id := "H2_4"
  text := "defective myeloid bacterial handling raises the risk of Crohn disease; written as: bacterial defence lowers it"
  claim := .effect bacterialDefense .neg (.disease crohn)
  evidence := []

/-- Run step H3.1: the GPR35 rs3749172 A allele is associated with higher risk of Crohn disease. Sign: the step is associated_with with unknown polarity; the direction is from the cited GWAS row: rs3749172-A, OR 1.45 (1.29-1.61), p=6e-11 (GCST008485). -/
def H3_1a : Statement where
  id := "H3_1a"
  text := "the GPR35 rs3749172 A allele is associated with higher risk of Crohn disease"
  claim := .assoc rs3749172 (some .pos) (.disease crohn)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs3749172", kind := .observational, note := "rs3749172-A is associated with 'Crohn's disease' at p = 6e-11, odds ratio 1.45" }
  ]

/-- Run step H3.1: the GPR35 intron variant rs34236350 is associated with Crohn disease (effect allele not reported, so no direction). Sign: direction none: the GWAS row gives beta 0.1795 (increase), p=1e-32 (GCST90446792), but its effect allele is '?'. -/
def H3_1b : Statement where
  id := "H3_1b"
  text := "the GPR35 intron variant rs34236350 is associated with Crohn disease (effect allele not reported, so no direction)"
  claim := .assoc rs34236350 none (.disease crohn)
  evidence := [
    { pmid := 0, year := 2026, ref := "rs34236350", kind := .observational, note := "rs34236350-? is associated with 'Crohn's disease' at p = 1e-32, beta 0.1795 unit (increase)" }
  ]

/-- Run step H3.2: GPR35 binds kynurenic acid. -/
def H3_2a : Statement where
  id := "H3_2a"
  text := "GPR35 binds kynurenic acid"
  claim := .rel ⟨.ro, 2436, false⟩ gpr35 kynurenicAcid
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC97", kind := .curatedDb, note := "binds to several ligands including the tryptophan metabolite kynurenic acid (KYNA), lysophosphatidic acid (LPA) or 5-hydroxyindoleacetic acid (5-HIAA) with high affinity" },
    { pmid := 0, year := 2026, ref := "OT:GPR35-tractability", kind := .curatedDb, note := "G protein-coupled receptor that binds to several ligands including the tryptophan metabolite kynurenic acid (KYNA), lysophosphatidic acid (LPA) or 5-hydroxyindoleacetic acid (5-HIAA) with high affinity" }
  ]

/-- Run step H3.2: GPR35 binds 5-hydroxyindoleacetic acid (5-HIAA). -/
def H3_2b : Statement where
  id := "H3_2b"
  text := "GPR35 binds 5-hydroxyindoleacetic acid (5-HIAA)"
  claim := .rel ⟨.ro, 2436, false⟩ gpr35 hiaa
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC97", kind := .curatedDb, note := "binds to several ligands including the tryptophan metabolite kynurenic acid (KYNA), lysophosphatidic acid (LPA) or 5-hydroxyindoleacetic acid (5-HIAA) with high affinity" },
    { pmid := 0, year := 2026, ref := "OT:GPR35-tractability", kind := .curatedDb, note := "G protein-coupled receptor that binds to several ligands including the tryptophan metabolite kynurenic acid (KYNA), lysophosphatidic acid (LPA) or 5-hydroxyindoleacetic acid (5-HIAA) with high affinity" }
  ]

/-- Run step H3.2: GPR35 binds lysophosphatidic acid. -/
def H3_2c : Statement where
  id := "H3_2c"
  text := "GPR35 binds lysophosphatidic acid"
  claim := .rel ⟨.ro, 2436, false⟩ gpr35 lysophosphatidicAcid
  evidence := [
    { pmid := 0, year := 2026, ref := "Q9HC97", kind := .curatedDb, note := "binds to several ligands including the tryptophan metabolite kynurenic acid (KYNA), lysophosphatidic acid (LPA) or 5-hydroxyindoleacetic acid (5-HIAA) with high affinity" },
    { pmid := 0, year := 2026, ref := "OT:GPR35-tractability", kind := .curatedDb, note := "G protein-coupled receptor that binds to several ligands including the tryptophan metabolite kynurenic acid (KYNA), lysophosphatidic acid (LPA) or 5-hydroxyindoleacetic acid (5-HIAA) with high affinity" }
  ]

/-- Run step H3.3: GPR35 in colonocytes is required for colonic mucosal integrity (run relation required_for, read as a positive effect; colonocyte qualifier dropped). -/
def H3_3a : Statement where
  id := "H3_3a"
  text := "GPR35 in colonocytes is required for colonic mucosal integrity (run relation required_for, read as a positive effect; colonocyte qualifier dropped)"
  claim := .effect gpr35 .pos (.process epithelialMaintenance)
  evidence := []

/-- Run step H3.3: GPR35 is required for resistance to induced colitis; written as: GPR35 lowers the risk of colitis. Sign: inverted: the run's object is resistance to induced colitis, which GPR35 is required for (+). -/
def H3_3b : Statement where
  id := "H3_3b"
  text := "GPR35 is required for resistance to induced colitis; written as: GPR35 lowers the risk of colitis"
  claim := .effect gpr35 .neg (.disease colitis)
  evidence := [
    { pmid := 0, year := 2026, ref := "AGR:MGI:1929509:MP:0008537", kind := .curatedDb, note := "of Gpr35 -- the orthologue of human GPR35 -- shows increased susceptibility to induced colitis", taxon := some Taxa.mouse },
    { pmid := 0, year := 2026, ref := "AGR:MGI:1929509:MP:0008539", kind := .curatedDb, polarity := .refutes, note := "of Gpr35 -- the orthologue of human GPR35 -- shows decreased susceptibility to induced colitis", taxon := some Taxa.mouse },
    { pmid := 0, year := 2026, ref := "AGR:MGI:1929509:MP:0013299", kind := .curatedDb, polarity := .refutes, note := "of Gpr35 -- the orthologue of human GPR35 -- shows decreased susceptibility to colitis induced morbidity/mortality", taxon := some Taxa.mouse }
  ]

/-- Run step H3.4: the kynurenic acid-GPR35 axis lowers the severity of colitis in Crohn disease (subject read as kynurenic acid; GPR35 is the receptor named in passing). Sign: the step is leads_to with unknown polarity; the sign is from PMID:40623474: KYNA alleviated mesenteritis and colitis in IL-10 knockout and TNBS-colitis mice. -/
def H3_4a : Statement where
  id := "H3_4a"
  text := "the kynurenic acid-GPR35 axis lowers the severity of colitis in Crohn disease (subject read as kynurenic acid; GPR35 is the receptor named in passing)"
  claim := .effect kynurenicAcid .neg (.disease crohnColitis .severity)
  evidence := [
    { pmid := 40623474, year := 2025, kind := .mechanistic, note := "KYNA triggered the white-to-beige transformation of MAT in IL-10-/- and TNBS-induced colitis mice, which further alleviated mesenteritis and colitis", taxon := some Taxa.mouse }
  ]

/-- Run step H3.4: the kynurenic acid-GPR35 axis lowers mesenteritis in Crohn disease (mesenteritis grounded as inflammatory response in the mesentery, in Crohn disease). Sign: the step is leads_to with unknown polarity; the sign is from PMID:40623474: KYNA alleviated mesenteritis and colitis in IL-10 knockout and TNBS-colitis mice. -/
def H3_4b : Statement where
  id := "H3_4b"
  text := "the kynurenic acid-GPR35 axis lowers mesenteritis in Crohn disease (mesenteritis grounded as inflammatory response in the mesentery, in Crohn disease)"
  claim := .effect kynurenicAcid .neg (.process mesentericInflammation)
  evidence := [
    { pmid := 40623474, year := 2025, kind := .mechanistic, note := "KYNA triggered the white-to-beige transformation of MAT in IL-10-/- and TNBS-induced colitis mice, which further alleviated mesenteritis and colitis", taxon := some Taxa.mouse }
  ]

def statements : List Statement := [H1_1, H1_2a, H1_2b, B1, H1_3, H2_1a, H2_1b, H2_2a, H2_2b, H2_3, H2_4, H3_1a, H3_1b, H3_2a, H3_2b, H3_2c, H3_3a, H3_3b, H3_4a, H3_4b]

/-- H1, claim 2: IL12B/IL23R risk alleles raise IL-23-driven Th17 signalling in gut mucosa; the only node in this list with a validated drug axis. -/
def h1c2a1 := viaProcess (lit H1_2b) (viaProcess (lit B1) (lit H1_3))

/-- H2, claim 2: NOD2 and LACC1 converge on a myeloid peptidoglycan-sensing/immunometabolic module: impaired NOD2-LACC1 signalling degrades bacterial handling in macrophages. -/
def h2c2a1 := viaProcess (lit H2_2b) (lit H2_4)

/-- H3, claim 1: GPR35 is an epithelium-intrinsic Crohn risk gene: a colonocyte metabolite receptor whose genetics is strong but whose direction of effect is unresolved. -/
def h3c1a1 := fromAssoc (lit H3_1a)

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c2a1" h1c2a1,
    arm "H2" "c2a1" h2c2a1,
    arm "H3" "c1a1" h3c1a1]

#eval printRows "study-2026-09-crohn-openrouter-anthropicclaude-opus-5-multi_agent-r2" rows

end BioLean.Lib.IPF.Runs.Rstudy_2026_09_crohn_openrouter_anthropicclaude_opus_5_multi_agent_r2
