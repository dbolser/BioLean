"""Program 10b: write the case table from the spec below and the Lean run.

    python3 -I scripts/stress/literature_cases.py          # runs `lake env lean BioLean/Stress/Literature.lean`

Writes, in data/stress/10b/:
  lean_rows.txt          the ROW lines printed by the Lean file (observed behaviour and mark)
  cases.tsv              id, probes, input, correct, observed, mark, test, source (+ relation, loss, fix, textbook)
  statements.tsv         every curated statement in the stress set, with its mapping loss under importer M0
  evidence_mentions.tsv  does the cited paper's title or abstract name both ends of the edge?
  summary.tsv            counts
The marks are set in the Lean file (section 11); this script only joins and counts.
"""
import collections
import csv
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, 'data', 'stress', '10b')
LEAN = 'BioLean/Stress/Literature.lean'
sys.dont_write_bytecode = True   # no __pycache__ next to other programs' scripts
sys.path.insert(0, HERE)
import literature_epmc  # noqa: E402  (our own script, for cached abstracts)

TB = 'textbook (OpenStax Concepts of Biology)'
TBID = {'m45537': 'the-body-s-systems-', 'm45539': 'the-body-s-systems-', 'm45439': 'how-cells-obtain-energy-',
        'm45452': 'photosynthesis-'}

# id: (probes, input, relation to textbook, correct conclusion with source, fix, textbook statement)
SPEC = {
 'S01': ('cross-source agreement', 'SIGNOR INS up-regulates activity INSR (PR:P01308, PR:P06213; PMIDs 2550426, 16956584) and GO-CAM 6a18a9ba00001280 INS hormone activity RO:0002629 INSR activity (PMID 14986111)',
         'adds detail', 'one claim with three PMIDs; belief above either source (insulin binds and activates its receptor: Rafaeloff 1989)', 'none', 'm45537-202'),
 'S02': ('relocalization read as amount', 'SIGNOR INS up-regulates activity SLC2A4 (PMID 9415393) + SLC2A4 up-regulates quantity glucose, relocalization (CHEBI:17234; PMID 17403369)',
         'adds detail', 'insulin moves glucose into muscle and fat via GLUT4 and lowers blood glucose (Huang 2007, PMID 17403369); no claim that insulin raises glucose', 'importer (relocalization as a compartment or a transport process; SIGNOR gives no compartment) or core (a transport target)', 'm45537-53'),
 'S03': ('mediator; BTO context dropped', 'SIGNOR calcium(2+) up-regulates quantity INS, relocalization, BTO:0000783 (CHEBI:29108; PMID 24843404)',
         'adds detail', 'Ca2+ influx triggers insulin granule exocytosis, the step between glucose and insulin release (Seino 2010, PMID 24843404)', 'core (a rule that turns two effects into mediatedBy) + importer (BTO to CL)', 'm45537-200'),
 'S04': ('precursor granularity (GLP-1 vs glucagon)', 'SIGNOR alpha-D-glucose up-regulates quantity GCG (CHEBI:17925, PR:P01275; PMID 31693916)',
         'not comparable', 'the edge is about GLP-1, cut from the same precursor in intestinal L cells (Gasbjerg 2020; Reactome R-HSA-381798); it does not contradict "falling glucose releases glucagon"', 'none (but see Y01)', 'm45537-199'),
 'S05': ('cross-source agreement; chain id to precursor', 'SIGNOR GCG up-regulates GCGR (PMIDs 22863277, 12529935) and GO-CAM 68d5ebd600000298 glucagon (P01275-PRO_0000011256) RO:0002629 GCGR (PMID 32193322)',
         'adds detail', 'one claim (glucagon activates its receptor: Qiao 2020, PMID 32193322)', 'none', 'm45537-201'),
 'S06': ('cross-source agreement; PR class vs human term', 'SIGNOR PTH up-regulates PTH1R (PR:P01270, PR:Q03431; PMID 18981475) and GO-CAM 69ea894900002023 (PMID 35932760)',
         'adds detail', 'one claim (PTH activates PTH1R: Kobayashi 2022, PMID 35932760); it is about the textbook\'s PTH', 'importer (PR:P01270 is_a PR:000013429 as data) + core (a rule from specific to general subject)', 'm45537-140'),
 'S07': ('PMID does not support the edge', 'SIGNOR AVP up-regulates AVPR2 (PR:P01185, PR:P30518; PMID 1560825)',
         'adds detail', 'the claim is true (human V2 receptor cloned and shown to bind AVP: Birnbaumer 1992, PMID 1534149) but PMID 1560825 is "Molecular cloning and expression of a rat V1a arginine vasopressin receptor" (Morel 1992)', 'importer (evidence check against the paper)', 'm45537-99'),
 'S08': ('one hormone, three ids', 'SIGNOR vasopressin (CHEBI:9937) up-regulates activity AVPR2 (PMID 31160049); textbook ADH is CHEBI:34543 argipressin; SIGNOR and GO-CAM AVP is PR:P01185',
         'agrees', 'same fact as S07 (vasopressin activates V2R: Zhou 2021, PMID 33742150); should fuse', 'importer (one entity per hormone)', 'm45537-99'),
 'S09': ('protein vs GO function', 'SIGNOR SCN1A up-regulates quantity sodium(1+) (PR:P35498, CHEBI:29101; PMID 27262167); GOA SCN1A enables GO:0005248 (IMP, PMID 14672992)',
         'agrees', 'Nav1.1 is a voltage-gated sodium channel; the textbook says it of the function (Lossin 2003, PMID 14672992)', 'core (enablesInherit rule)', 'm45539-90'),
 'S10': ('complex with no OBO id', 'SIGNOR ATP synthase (SIGNOR-C264) up-regulates quantity ATP (CHEBI:15422; PMID 21874297)',
         'agrees', 'ATP synthase makes ATP from ADP and phosphate (Jonckheere 2012, PMID 21874297)', 'importer (SIGNOR complex to GO CC map)', 'm45439-72'),
 'S11': ('activity of a complex', 'SIGNOR hydron up-regulates activity ATP synthase (CHEBI:15378, SIGNOR-C264; PMID 31115493)',
         'agrees', 'the proton gradient drives ATP synthase (Zhao 2019 review, PMID 31115493; textbook m45452-91)', 'importer (complex activity to its GO function GO:0046933, as the textbook does)', 'm45452-91'),
 'S12': ('sign error in the source', 'SIGNOR metformin up-regulates quantity by expression G6PC1 (CHEBI:6801, PR:P35575; PMID 17909097)',
         'not comparable', 'metformin lowers G6Pase expression; the SIGNOR sentence from Kim 2008 says it "inhibited the expression of the hepatic gluconeogenic genes pepck and g6pase"; the abstract: metformin "inhibited ... promoter activity of PEPCK and G6Pase"', 'importer (check sign against the stored sentence); PubTator3 items (option I) make it contested', ''),
 'S13': ('no sign', 'SIGNOR INSR unknown (phosphorylation, Tyr20) FABP4 (PR:P06213, PR:P15090; PMID 1648089)',
         'not comparable', 'the insulin receptor phosphorylates FABP4 in vitro, effect not stated (Buelt 1991, PMID 1648089); an unsigned relation is the faithful claim', 'none', ''),
 'S14': ('one paper behind two links', 'SIGNOR vasopressin -> AVPR2 and AVPR2 -> GNAS, both PMID 31160049 (a 148-receptor screen)',
         'adds detail', 'the two links are one experiment; a chain should not treat them as independent (Inoue 2019, PMID 31160049)', 'report (PMID-level lint, prototype sharedPmids)', ''),
 'G02': ('chain reaches the textbook claim?', 'GO-CAM 6a18a9ba00001280: INS -> INSR (14986111) -> IRS1 (38056462) -> PIK3CG (7493946) -> SLC2A4 (11277933, indirect); SLC2A4 activity part_of GO:0042593 glucose homeostasis (14562105)',
         'adds detail', 'the textbook\'s "insulin stimulates glucose uptake" with its mechanism (receptor, IRS1, PI3K, GLUT4: Huang 2007, PMID 17403369)', 'core (a bridge from activity to process; isaInheritEffect exists, widenProcess does not) + data (the model ties GLUT4 to glucose homeostasis; its glucose-transport fact is GLUT1\'s, PMID 18245775)', 'm45537-202'),
 'G03': ('sign algebra through a model', 'GO-CAM 69ea894900002023: calcium(2+) RO:0012005 CASR (38632411) RO:0002629 GNAI1 (38632411) RO:0002409 PTH hormone activity (15331768)',
         'agrees', 'raised extracellular calcium acts on CaSR and lowers PTH (Garrett 1995, PMID 7759551; Zuo 2024, PMID 38632411): sign negative', 'none', 'm45537-141'),
 'G04': ('link of a chain to the textbook', 'the G03 conclusion: calcium -| activity of PR:P01270',
         'agrees', 'same as textbook m45537-141 (low calcium raises PTH), at another granularity', 'core (activity vs amount bridge) + importer (PR class bridge)', 'm45537-141'),
 'G05': ('chain stops short of physiology', 'GO-CAM 69ea894900002023: PTH -> PTH1R (35932760) -> GNAS (19674967) -> PRKACA (10200251) -> TRPV5 (11029056)',
         'adds detail', 'PTH raises renal calcium reabsorption via PKA and TRPV5, one route to higher blood calcium (van Goor 2017, PMID 28534087)', 'importer or core (a bridge from renal absorption to blood amount)', 'm45537-140'),
 'G06': ('PMID does not support the edge', 'GO-CAM 69ea894900002023: PKA activity RO:0002629 TRPV5 calcium channel activity, PMID 11029056',
         'adds detail', 'PKA does regulate TRPV5 (van Goor 2017, PMID 28534087) but PMID 11029056 is "Phosphorylation-dependent localization of microtubule-associated protein MAP2c to the actin cytoskeleton" (Ozer 2000)', 'importer (evidence check)', 'm45537-140'),
 'G07': ('cross-source agreement keeps a bad axiom', 'GO-CAM 67e5e74400004286 AVP hormone activity RO:0002629 AVPR2 (PMID 33742150) with SIGNOR S07',
         'adds detail', 'one claim; the good evidence (Zhou 2021) should carry it, not the V1a paper', 'importer (evidence check)', ''),
 'G08': ('same entity, different level', 'GO-CAM 66b5638000001772 calcitonin (PR:P01258) RO:0002629 CALCR (PMID 32296767); the model ends at cAMP',
         'not comparable', 'calcitonin activates its receptor (Kuestner 1994, PMID 8078488); the model does not reach blood calcium, so it neither supports nor contradicts m45537-135', 'none', 'm45537-135'),
 'G09': ('instance location lifted to class', 'GO-CAM 6a18a9ba00001280: glucose located_in cytoplasm; glucose located_in extracellular region (PMID 19251038)',
         'not comparable', 'in the model these are two glucose individuals; "every glucose is in some cytoplasm" is false for blood glucose (textbook m45537-53 itself is about blood glucose)', 'importer (keep as participant context, not claims)', ''),
 'G10': ('wrong-species anatomy', 'GO-CAM 6a18a9ba00001280: plasma membrane part_of ZFA:0009102 pancreatic B cell (PMID 40811462)',
         'not comparable', 'a human model should use CL:0000169 type B pancreatic cell; ZFA:0009102 is zebrafish anatomy', 'importer (ZFA/EMAPA to CL/UBERON)', 'm45537-200'),
 'G11': ('generic enabler; charge state; no PMID', 'GO-CAM R-HSA-163210 (imported from Reactome): proton transmembrane transporter activity (GO:0015078) enabled_by GO:0032991 has_output ATP(4-) CHEBI:30616; ECO:0000313',
         'agrees', 'ATP synthase makes ATP (textbook m45439-74); CHEBI:30616 is the conjugate base of CHEBI:15422, not a subclass (OLS4); the import puts the ATP output on a proton transporter activity', 'importer (charge-state map)', 'm45439-74'),
 'G12': ('unsigned causal relation', 'GO-CAM R-HSA-163210: proton transmembrane transporter activity RO:0002411 ATP synthase activity',
         'agrees', 'the textbook says the proton stream powers ATP synthase (m45452-91), a positive effect', 'core (unsigned effect, or sign from RO:0002411 children)', 'm45452-91'),
 'R01': ('reaction grounded by its GO cross-reference', 'Reactome R-HSA-8981570 (GO:1904659): has_input Glc [extracellular region], has_output Glc [cytosol] (CHEBI:4167; PMIDs 1756912, 11994746, 1918382, 2656669)',
         'adds detail', 'GLUT4 imports glucose; but "every D-glucose transmembrane transport takes glucose from outside" is false: GLUT2 exports it (Colville 1993, PMID 8457197; Reactome R-HSA-450095)', 'importer (reaction as its own process, is_a the GO term)', 'm45537-202'),
 'R02': ('last step of glucose release', 'Reactome R-HSA-450095: GLUT2 has_output Glc [extracellular region] (PMIDs 8457197, 9751501, 9354798)',
         'adds detail', 'liver glucose leaves via GLUT2, the last step of "glucagon causes release of glucose from the liver" (Colville 1993)', 'core (bridge from has_output to effect on amount)', 'm45537-201'),
 'R03': ('binding reaction vs signed effect', 'Reactome R-HSA-74716 Insulin binds the insulin receptor: inputs two complexes (PMIDs 11737239, 7781591)',
         'agrees', 'same fact as S01 (Van Obberghen 2001, PMID 11737239)', 'importer (complex map) + core (binding as an unsigned relation that meets an effect)', ''),
 'R04': ('charge state; bound product', 'Reactome R-HSA-164834 Enzyme-bound ATP is released (GO:0042776): has_output ATP(4-) [mitochondrial matrix]; no PMID',
         'agrees', 'mitochondrial ATP synthesis makes ATP (textbook m45439-74); GO:0042776 is_a GO:0015986 (OLS4)', 'importer (charge-state map)', 'm45439-74'),
 'R05': ('set of alternatives', 'Reactome R-HSA-420489 PTH receptor can bind PTH: inputs DefinedSets (PTH, PTHrP, TIP39; PTH1R, PTH2R; PMID 8397094 and 9 more)',
         'adds detail', 'PTH binds PTH1R (Schneider 1993, PMID 8397094); the reaction is a union of ligand-receptor pairs', 'core (a union of entities, or the importer expands the set)', 'm45537-140'),
 'R06': ('cleavage product', 'Reactome R-HSA-163625 Glucagon binds glucagon receptor: input GCG(53-81) (PMIDs 11946536, 15464082, 2826231, 8144028)',
         'agrees', 'the ligand is the 29-residue glucagon peptide (Thomsen 1972, PMID 11946536), CHEBI:5391; PR has no mature-glucagon term', 'importer (chain to ChEBI or PR cleavage term)', 'm45537-201'),
 'R07': ('evidence inferred from mouse', 'Reactome R-HSA-265166 Exocytosis of insulin (GO:0030073), inferred from R-MMU-216883: has_input Ca2+ [cytosol]; PMIDs 12403834, 17900700, 16443778, 12684222, 8997178, 18162464, 14514350, 7641683, 11873862',
         'adds detail', 'the human reaction is an orthology inference; on this record alone it is not established in humans', 'importer (inferred reaction as one crossSpecies item)', 'm45537-200'),
 'R08': ('transport kept with compartments', 'Reactome R-HSA-5576895 SCNAs:SCNBs transport Na+ extracellular to cytosol (PMIDs 21566136, 14500339, 1309946; 6 more not used)',
         'agrees', 'sodium enters the cell through Nav channels (textbook m45539-90, which says "amount" only)', 'core (bridge from transport to effect)', 'm45539-90'),
 'O01': ('GOA function annotation', 'GOA SCN1A enables GO:0005248 (IMP, PMID 14672992)',
         'agrees', 'Nav1.1 has voltage-gated sodium channel activity (Lossin 2003)', 'none', 'm45539-90'),
 'O02': ('annotation extension', 'GOA PTH enables GO:0005179 hormone activity, extension has_input(UniProtKB:Q03431), part_of(GO:0007189) (IDA, PMID 35932760)',
         'adds detail', 'PTH binds and activates its receptor PTH1R (Kobayashi 2022, PMID 35932760); the extension is part of the claim', 'none (importer must use refine)', ''),
 'O03': ('unsigned process annotation', 'GOA (WormBase) aak-2 involved_in GO:0008340 determination of adult lifespan (IMP, PMID 15574588)',
         'not comparable', 'AAK-2 links energy levels to lifespan in C. elegans (Apfeld 2004, PMID 15574588); the annotation has no sign', 'none', ''),
 'O04': ('NOT annotation, isoform lost', 'GOA CALCR enables GO:0032841 calcitonin binding (PMIDs 15563840, 8078488, 7769107) and NOT enables GO:0032841 (PMID 15563840)',
         'not comparable', 'the NOT is about two novel isoforms (Beaudreuil 2004, "Molecular characterization of two novel isoforms of the human calcitonin receptor"); the receptor binds calcitonin (Kuestner 1994)', 'importer (keep gene-product form) + data (GOA row has none)', 'm45537-135'),
 'T01': ('textbook grounding: precursor', 'textbook "insulin" = PR:000009054',
         'not comparable', 'OLS4 labels PR:000009054 preproinsulin; the hormone is PR:000050339 insulin hormone, a cleavage product. Preproinsulin is not secreted', 'data (re-ground the textbook)', 'm45537-53'),
 'T02': ('textbook grounding: human precursor', 'textbook "glucagon" = PR:P01275',
         'not comparable', 'OLS4 labels PR:P01275 pro-glucagon (human); it also yields GLP-1 in L cells (Reactome R-HSA-381798). Glucagon is CHEBI:5391', 'data (re-ground the textbook)', 'm45537-201'),
 'Y01': ('SYNTHETIC: opposite sign, same claim', 'SYNTHETIC curated record: glucose raises glucagon in blood from alpha cells (PMID 90000001)',
         'contradicts', 'a contradiction with m45537-199 should be flagged', 'report (an effect sign-clash check from fuse and negate, prototype effectClash)', 'm45537-199'),
 'Y02': ('SYNTHETIC: contradiction routed as refutation', 'the same record entered as refuting evidence on m45537-199 (PMID 90000002)',
         'contradicts', 'contested', 'none', 'm45537-199'),
 'Y03': ('one curie, two labels', 'Taxa.human ("Homo sapiens") and textbook e_NCBITaxon_9606 ("humans")',
         'agrees', 'same taxon; claims about one should meet claims about the other', 'core (Entity equality by curie) or data (one registry)', ''),
 'Y04': ('UniProt-style PR ids and is_a', 'Curie.encode "PR:P01308"; OLS4 PR:P01308 is_a PR:000009054',
         'agrees', 'human preproinsulin is a preproinsulin (OLS4)', 'data (PR is_a as rel isA statements, as insIsa does) or core (Curie.encode for UniProt-style ids)', 'm45537-53'),
 'M01': ('M8 exit: curated mechanism', 'SIGNOR metformin up-regulates activity PRKAA1 (PMID 11602624)',
         'not comparable', 'metformin activates AMPK in hepatocytes and in isolated rat skeletal muscle (Zhou 2001, PMID 11602624)', 'none for the verdict; importer should fill Evidence.taxon (rat), which the core lint taxonConsistent then checks', ''),
 'M02': ('M8 exit: curated mechanism', 'SIGNOR metformin down-regulates activity NDUFS1 (PMID 24843020)',
         'not comparable', 'metformin inhibits mitochondrial complex I (Wheaton 2014, PMID 24843020)', 'none', ''),
 'M03': ('M8 exit: worms, literature only', 'metformin in C. elegans extends life span (PATO:0000050): Onken 2010 (20090912), Cabreiro 2013 (23540700)',
         'not comparable', 'metformin extends median lifespan in worms (Onken 2010); the effect runs through the E. coli they eat and its sign depends on strain and glucose (Cabreiro 2013)', 'none (literature extraction needed: no curated source)', ''),
 'M04': ('M8 exit: mice, conflicting', 'metformin in mice: Martin-Montalvo 2013 (23900241, male mice, supports); Strong 2016 ITP (27312235, UM-HET3, refutes)',
         'not comparable', 'mixed: longer life in male mice at 0.1% (Martin-Montalvo 2013); "Metformin alone, at a dose of 0.1% in the diet, did not significantly extend lifespan" in the ITP (Strong 2016)', 'none', ''),
 'M05': ('M8 exit: humans with diabetes, observational', 'Bannister 2014 (25041462, supports), Campbell 2017 meta-analysis (28802803, supports), Keys 2022 (36287641, refutes)',
         'not comparable', 'not established: Keys 2022 found metformin initiation "was not associated with survival equal or superior to that of the general population"', 'importer (meta-analysis of observational studies as observational, program 10a B1)', ''),
 'M06': ('M8 exit: mouse to human', 'transport of M04 to Homo sapiens with a crossSpecies item (Barzilai 2016, PMID 27304507)',
         'not comparable', 'unsupported: no human lifespan evidence; the TAME trial was proposed (Barzilai 2016)', 'none', ''),
 'M07': ('M8 exit: across a condition', 'M05 (people with T2D) and the human claim',
         'not comparable', 'evidence in people with diabetes bears on people without, with a discount; it should be usable, not ignored', 'core (a condition-transport rule)', ''),
 'M08': ('M8 exit: mechanistic route', 'M01 (human AMPK), O03 (worm aak-2 lifespan, unsigned) and the signed worm step from Apfeld 2004 (PMID 15574588)',
         'not comparable', 'a mechanism is a hypothesis here: no source gives a signed AMPK-to-lifespan step in humans; Apfeld 2004 gives one in worms ("AAK-2 ... functions to extend lifespan")', 'none for the verdict; using the worm step for humans needs a rule across orthologs (core)', ''),
 'M09': ('M8 exit: the answer', 'M06 fused with the TAME proposal (hypothesis, weight 0)',
         'not comparable', 'not established in humans (no trial result; observational evidence conflicts); verdict unsupported or contested, with the axioms listed', 'none', ''),
}

# Where the fix for a non-PASS case lives: 'outside' (importer, data, report lint) or 'core' (a new rule,
# constructor or type is needed). PASS cases are 'none'.
LAYER = {
    'S02': 'outside', 'S03': 'core', 'S07': 'outside', 'S08': 'outside', 'S09': 'core', 'S10': 'outside',
    'S11': 'outside', 'S12': 'outside', 'S14': 'outside', 'G02': 'core', 'G04': 'core', 'G05': 'core',
    'G06': 'outside', 'G07': 'outside', 'G09': 'outside', 'G10': 'outside', 'G11': 'outside', 'G12': 'core',
    'R01': 'outside', 'R02': 'core', 'R03': 'core', 'R04': 'outside', 'R05': 'core', 'R06': 'outside',
    'R07': 'outside', 'R08': 'core', 'O04': 'outside', 'T01': 'outside', 'T02': 'outside', 'Y01': 'outside',
    'Y03': 'outside', 'Y04': 'outside', 'M05': 'outside', 'M07': 'core',
}

# (edge, PMID) pairs whose paper is about another protein, judged by title (gold set for experiment E2)
WRONG_PAPER = {('S07', '1560825'), ('G02c', '11277933'), ('G03c', '15331768'), ('G06', '11029056'), ('G08', '32296767')}

# every curated statement in the stress set: (Lean name, source, case, loss under M0 or 'none')
STATEMENTS = [
    ('S01s', 'SIGNOR', 'S01', 'none'), ('S01g', 'GO-CAM', 'S01', 'none'),
    ('S02a', 'SIGNOR', 'S02', 'BTO context dropped'), ('S02b', 'SIGNOR', 'S02', 'relocalization read as amount'),
    ('S03', 'SIGNOR', 'S03', 'relocalization read as amount; BTO context dropped'),
    ('S04', 'SIGNOR', 'S04', 'BTO context dropped; precursor for the product (GLP-1)'),
    ('S05s', 'SIGNOR', 'S05', 'bare up-regulates read as activity'), ('S05g', 'GO-CAM', 'S05', 'chain id read as precursor'),
    ('S06s', 'SIGNOR', 'S06', 'bare up-regulates read as activity'), ('S06g', 'GO-CAM', 'S06', 'none'),
    ('S07', 'SIGNOR', 'S07', 'bare up-regulates read as activity; BTO context dropped'),
    ('S08', 'SIGNOR', 'S08', 'BTO context dropped'), ('S09', 'SIGNOR', 'S09', 'relocalization read as amount'),
    ('S10', 'SIGNOR', 'S10', 'complex with no OBO id'), ('S11', 'SIGNOR', 'S11', 'dropped by M0: activity of a complex (the core can state it as GO:0046933)'),
    ('S12', 'SIGNOR', 'S12', 'none'), ('S12pck', 'SIGNOR', 'S12', 'none'), ('S13', 'SIGNOR', 'S13', 'none'),
    ('S14b', 'SIGNOR', 'S14', 'none'), ('M01', 'SIGNOR', 'M01', 'species of the experiment dropped (rat cells, human protein)'), ('M02', 'SIGNOR', 'M02', 'none'),
    ('G02a', 'GO-CAM', 'G02', 'none'), ('G02b', 'GO-CAM', 'G02', 'none'), ('G02c', 'GO-CAM', 'G02', 'none'),
    ('G02d', 'GO-CAM', 'G02', 'none'), ('G03a', 'GO-CAM', 'G03', 'none'), ('G03b', 'GO-CAM', 'G03', 'none'),
    ('G03c', 'GO-CAM', 'G03', 'none'), ('G05a', 'GO-CAM', 'G05', 'none'), ('G05b', 'GO-CAM', 'G05', 'none'),
    ('G06', 'GO-CAM', 'G06', 'none'), ('G07g', 'GO-CAM', 'G07', 'chain id read as precursor'),
    ('G08', 'GO-CAM', 'G08', 'none'), ('G09a', 'GO-CAM', 'G09', 'instance location lifted to class'),
    ('G09b', 'GO-CAM', 'G09', 'instance location lifted to class'), ('G10', 'GO-CAM', 'G10', 'zebrafish term in a human model'),
    ('G11', 'GO-CAM', 'G11', 'no PMID; generic enabler'), ('G12', 'GO-CAM', 'G12', 'no PMID'),
    ('R01in', 'Reactome', 'R01', 'reaction read as its broader GO term'), ('R01out', 'Reactome', 'R01', 'reaction read as its broader GO term'),
    ('R02', 'Reactome', 'R02', 'none'), ('R03', 'Reactome', 'R03', 'complex with no OBO id'),
    ('R04', 'Reactome', 'R04', 'no PMID'), ('R05', 'Reactome', 'R05', 'inexpressible: a set'),
    ('R06', 'Reactome', 'R06', 'chain id read as precursor'), ('R07', 'Reactome', 'R07', 'inferred from mouse, counted as human'),
    ('R08', 'Reactome', 'R08', 'none'),
    ('O01', 'GOA', 'O01', 'none'), ('O02', 'GOA', 'O02', 'none'), ('O03', 'GOA', 'O03', 'none'),
    ('O04yes', 'GOA', 'O04', 'gene-product form dropped (one row, P30988-2)'), ('O04no', 'GOA', 'O04', 'none'),
]

# evidence mention check: (statement, pmid, names for the subject, names for the object)
MENTIONS = [
    ('S01s', '2550426', ['insulin'], ['insulin receptor']), ('S01s', '16956584', ['insulin'], ['insulin receptor']),
    ('S01g', '14986111', ['insulin'], ['receptor']), ('S02a', '9415393', ['insulin'], ['GLUT4']),
    ('S02b', '17403369', ['GLUT4'], ['glucose']), ('S03', '24843404', ['Ca2+', 'calcium'], ['insulin']),
    ('S04', '31693916', ['glucose'], ['GLP-1', 'glucagon']), ('S05s', '22863277', ['glucagon'], ['receptor']),
    ('S05s', '12529935', ['glucagon'], ['receptor']), ('S05g', '32193322', ['glucagon'], ['receptor']),
    ('S06s', '18981475', ['parathyroid hormone', 'PTH'], ['receptor', 'PTH1R']), ('S06g', '35932760', ['PTH'], ['receptor']),
    ('S07', '1560825', ['vasopressin'], ['V2']), ('S08', '31160049', ['vasopressin'], ['V2', 'AVPR2']),
    ('S09', '27262167', ['sodium channel', 'NaV'], ['Na']), ('S10', '21874297', ['ATP synthase'], ['ATP']),
    ('S12', '17909097', ['metformin'], ['g6pase', 'G6Pase', 'glucose-6-phosphatase']), ('S13', '1648089', ['insulin receptor'], ['lipid-binding protein', 'p15']),
    ('S14b', '31160049', ['V2', 'AVPR2'], ['Gs', 'G alpha', 'Gα']),
    ('G02a', '38056462', ['insulin receptor', 'INSR'], ['IRS1', 'insulin receptor substrate']),
    ('G02b', '7493946', ['insulin receptor substrate', 'IRS-1'], ['phosphatidylinositol 3-kinase', 'PI3']),
    ('G02c', '11277933', ['phosphatidylinositol 3-kinase', 'PI3K', 'PI 3-kinase'], ['GLUT4', 'glucose transport']),
    ('G02d', '14562105', ['GLUT4'], ['glucose homeostasis', 'glucose uptake', 'glucose']), ('G03a', '38632411', ['calcium', 'Ca2+'], ['calcium-sensing receptor', 'CaSR']),
    ('G03b', '38632411', ['calcium-sensing receptor', 'CaSR'], ['Gi', 'G-protein', 'G protein']),
    ('G03c', '15331768', ['Gi', 'Galphai', 'G(i)'], ['parathyroid', 'PTH']), ('G05a', '19674967', ['parathyroid hormone receptor', 'PTH receptor', 'PTHR'], ['Gs', 'G protein', 'G(s)']),
    ('G05b', '10200251', ['Gs', 'G(s)', 'stimulatory'], ['protein kinase A', 'PKA', 'cAMP-dependent']),
    ('G06', '11029056', ['protein kinase A', 'PKA', 'cAMP-dependent'], ['TRPV5', 'calcium channel']),
    ('G07g', '33742150', ['vasopressin', 'AVP'], ['V2']), ('G08', '32296767', ['calcitonin'], ['calcitonin receptor', 'CTR']),
    ('G10', '40811462', ['membrane', 'GLUT'], ['beta cell', 'β-cell', 'islet']),
    ('R01in', '1756912', ['GLUT4', 'glucose transporter'], ['glucose']), ('R02', '8457197', ['GLUT2'], ['glucose']),
    ('R03', '11737239', ['insulin'], ['receptor']), ('R06', '11946536', ['glucagon'], ['receptor']),
    ('R08', '21566136', ['sodium channel', 'Nav'], ['Na']), ('O01', '14672992', ['SCN1A'], ['sodium channel']),
    ('O02', '35932760', ['PTH', 'parathyroid hormone'], ['PTH1R', 'receptor']), ('O03', '15574588', ['AAK-2', 'aak-2'], ['lifespan', 'life span']),
    ('O04no', '15563840', ['calcitonin receptor'], ['calcitonin']), ('M01', '11602624', ['metformin'], ['AMPK', 'AMP-activated']),
    ('M02', '24843020', ['metformin'], ['complex I']),
]


def run_lean():
    r = subprocess.run(['lake', 'env', 'lean', LEAN], cwd=ROOT, capture_output=True, text=True, timeout=600)
    out = r.stdout + r.stderr
    if 'error' in out.lower() and 'ROW' not in out:
        sys.exit('Lean failed:\n' + out[:3000])
    lines = [l for l in out.splitlines() if l.startswith('ROW\t')]
    open(os.path.join(OUT, 'lean_rows.txt'), 'w').write('\n'.join(lines) + '\n')
    return {l.split('\t')[1]: l.split('\t')[2:] for l in lines}


def main():
    os.makedirs(OUT, exist_ok=True)
    rows = run_lean()
    missing = set(SPEC) ^ set(rows)
    if missing:
        sys.exit(f'spec and Lean rows differ: {sorted(missing)}')
    refs = {r['pmid']: r for r in csv.DictReader(open(os.path.join(OUT, 'references_checked.tsv')), delimiter='\t', lineterminator='\n')}
    marks = collections.Counter()
    layers = collections.Counter()
    with open(os.path.join(OUT, 'cases.tsv'), 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['id', 'probes', 'input', 'correct', 'observed', 'mark', 'test', 'source',
                    'relation_to_textbook', 'textbook_statement', 'fix', 'fix_layer'])
        for cid in SPEC:
            probes, inp, rel, correct, fix, tbs = SPEC[cid]
            mark, observed, test = rows[cid]
            pm = sorted(set(re.findall(r'(?<![\w:-])(\d{6,8})(?![\w-])', inp + ' ' + correct)) & set(refs))
            src = '; '.join(f"PMID {p} ({refs[p]['first_author']} {refs[p]['year']})" for p in pm)
            if cid.startswith('Y'):
                src = 'SYNTHETIC or core probe' + (f'; {src}' if src else '')
            if tbs:
                src = (src + '; ' if src else '') + 'OpenStax Concepts of Biology ' + TBID[tbs.split('-')[0]] + tbs
            layer = LAYER.get(cid, 'none')
            if (mark == 'PASS') != (layer == 'none'):
                sys.exit(f'{cid}: mark {mark} but fix layer {layer}')
            w.writerow([cid, probes, inp, correct, observed, mark, f'{LEAN}: {test}', src, rel,
                        tbs, fix, layer])
            marks[mark] += 1
            layers[(mark, layer)] += 1
    # statements and their loss
    loss = collections.Counter()
    per_src = collections.defaultdict(collections.Counter)
    with open(os.path.join(OUT, 'statements.tsv'), 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['statement', 'source', 'case', 'loss_under_M0'])
        for name, src, case, why in STATEMENTS:
            w.writerow([name, src, case, why])
            k = ('lossless' if why == 'none' else 'inexpressible' if why.startswith('inexpressible')
                 else 'dropped' if why.startswith('dropped') else 'lossy')
            loss[k] += 1
            per_src[src][k] += 1
            for part in why.split('; '):
                if why != 'none':
                    loss['reason: ' + part] += 1
    # evidence mentions
    mention_ok = 0
    flag = collections.Counter()
    with open(os.path.join(OUT, 'evidence_mentions.tsv'), 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['statement', 'pmid', 'title', 'subject_named', 'object_named', 'both',
                    'about_another_protein_by_title'])
        for name, pmid, subj, obj in MENTIONS:
            text = re.sub(r'<[^>]+>', '', literature_epmc.abstract(pmid))
            low = text.lower()
            a = any(x.lower() in low for x in subj)
            b = any(x.lower() in low for x in obj)
            wrong = (name, pmid) in WRONG_PAPER
            mention_ok += a and b
            flag[('flagged' if not (a and b) else 'passed', wrong)] += 1
            w.writerow([name, pmid, refs.get(pmid, {}).get('title', '')[:120], a, b, a and b, wrong])
    if len(WRONG_PAPER - {(m[0], m[1]) for m in MENTIONS}):
        sys.exit('a wrong-paper pair is not in MENTIONS')
    n = len(STATEMENTS)
    with open(os.path.join(OUT, 'summary.tsv'), 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['measure', 'count', 'of'])
        for k in ('PASS', 'FAIL', 'SILENT', 'INEXPRESSIBLE'):
            w.writerow([f'cases {k}', marks[k], len(SPEC)])
        for k, v in sorted(loss.items(), key=lambda x: (not x[0].startswith('reason'), -x[1])):
            w.writerow([f'statements {k}', v, n])
        for src, c in per_src.items():
            w.writerow([f'{src} statements lossless', c['lossless'], sum(c.values())])
        w.writerow(['cited paper names both ends (title or abstract)', mention_ok, len(MENTIONS)])
        w.writerow(['cited paper about another protein (title judgement)', len(WRONG_PAPER), len(MENTIONS)])
        w.writerow(['keyword test flags a wrong paper', flag[('flagged', True)], len(WRONG_PAPER)])
        w.writerow(['keyword test misses a wrong paper', flag[('passed', True)], len(WRONG_PAPER)])
        w.writerow(['keyword test flags a pair that is not a wrong paper', flag[('flagged', False)], len(MENTIONS) - len(WRONG_PAPER)])
        for (mk, ly), v in sorted(layers.items()):
            w.writerow([f'cases {mk} with fix layer {ly}', v, marks[mk]])
    print('cases', len(SPEC), dict(marks))
    print('statements', n, {k: v for k, v in loss.items() if not k.startswith('reason')})
    print({s: dict(c) for s, c in per_src.items()})
    print('evidence mentions both ends', mention_ok, 'of', len(MENTIONS), dict(flag))
    print('fix layers', dict(layers))


if __name__ == '__main__':
    main()
