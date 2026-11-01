"""Program 08: write the stress-set table from what Lean actually printed.

Runs `lake env lean` on BioLean/Stress/SchemaGaps.lean (today's core, lines `OBS`) and on
BioLean/Proto/SchemaGaps.lean (prototypes, lines `PROTO`), joins them with the case spec below and
the textbook sentences in data/textbook/claims*/, and writes

    data/stress/08/cases.tsv      one row per case
    data/stress/08/marks.tsv      counts of marks per gap, today and under the prototype
    data/stress/08/lean_output.txt the raw OBS and PROTO lines

Marks are mine, made from the observed line (shown next to it). Run from anywhere:

    python3 scripts/stress/gaps_cases.py            # runs Lean (about 30 s)
    python3 scripts/stress/gaps_cases.py --cached   # reuse lean_output.txt
"""

import collections
import glob
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "stress", "08")
FILES = ["BioLean/Stress/SchemaGaps.lean", "BioLean/Proto/SchemaGaps.lean"]

# Option codes (see docs/programs/08-schema-gaps.md, section "The options").
#   D-a split or coarsen at annotation (data)      D-b Claim.or + rules + comultiplication (core)
#   D-c union entity a ⊔ b + axiom schemas (core, small)   D-d frame coarsening for exclusive alternatives (core)
#   A-a tolerance written as an interval in data   A-b about constructor + interval rules (core)
#   A-c every quantity an interval (core)          A-d exact number + approx flag + lint (core, small)
#   C-a emitter nests states on the right filler (data)   C-b list of conditions with slot, canonical (core)
#   C-c one extra subject-state slot (core, small) C-d rules that swap or drop nested refinements (core)
# In `options`: (obs) = observed by running Lean; (pred) = predicted from the code, not run.

S = "synthetic"
SPEC = [
    # id, gap, synthetic?, textbook ids, CURIEs, probes, correct, source, encoding today, lost, mark today, test, mark proto, options
    ("D01", "or", "", "cell-structure-and-function-m45428-11;cell-structure-and-function-m45429-1",
     "CL:0000000 CL:0000520 CL:0000255",
     "exhaustive classification (every cell is one of two kinds)",
     "every cell is prokaryotic or eukaryotic; named cell types are placed by CL",
     "CL:0000520, CL:0000255 definitions (OLS4)",
     "none (no Lean in R1 to R3)", "the classification itself; consequences for unnamed cells",
     "INEXPRESSIBLE", "Stress: #no_lean m45428-11, m45429-1; #guard Ontology.isACurie e_CL_0000232.curie eukCell.curie", "PASS",
     "D-a INEXPRESSIBLE (obs); D-b PASS, needs a claim per disjunct (pred); D-c PASS: cell is_a (prok ⊔ euk), unionSubj gives cell has part plasma membrane (obs); D-d n/a"),
    ("D02", "or", "", "cell-structure-and-function-m45428-11", "CL:0000595 CL:0000520 CL:0000255",
     "a disjunction must not license disjunctive syllogism on a class-level negation",
     "an enucleate erythrocyte is not a prokaryotic cell", "CL:0000595 definition 'An erythrocyte lacking a nucleus' (OLS4)",
     "no Lean for the or", "nothing", "PASS", "Stress: #guard !Ontology.isACurie enucleateRbc.curie prokCell.curie", "PASS",
     "D-a PASS (obs); D-b PASS: no general negation, no syllogism (obs); D-c PASS (obs); a syllogism rule would FAIL (pred)"),
    ("D03", "or", "", "how-cells-obtain-energy-m45439-16;how-cells-obtain-energy-m45439-28;how-cells-obtain-energy-m45439-104",
     "GO:0006099 CHEBI:15422 CHEBI:15996 CHEBI:26398",
     "one disjunct asserted as the whole (weakening refused in R3, kept in R2)",
     "each TCA turn makes one ATP or one GTP; mammals express both succinyl-CoA synthetases",
     "Lambeth 2004 PMID 15234968", "R2: TCA has output ATP (established); R3: refused (blocker disjunction)",
     "that it may be GTP", "FAIL", "Stress: d03_r2_established", "PASS",
     "D-a PASS if coarsened to purine NTP (obs, d03_coarse); D-b PASS: orElim to purine NTP (obs); D-c PASS: has output (ATP ⊔ GTP), unionLub to purine NTP (obs); D-d PASS per turn, exclusive (obs, D16)"),
    ("D04", "or", "", "the-cellular-basis-of-inheritance-m45466-106;the-cellular-basis-of-inheritance-m45466-107",
     "GO:0000910 GO:0032154 GO:0009504 NCBITaxon:33208 NCBITaxon:3193",
     "an or that splits by taxon", "animals: cleavage furrow; plants: cell plate",
     "GO:0032154, GO:0009504 definitions (OLS4)", "R3: two rel claims, split by taxon", "nothing",
     "PASS", "Stress: #guard d04a.claim.subjectCurie", "PASS", "D-a PASS (obs); D-b, D-c: no prototype part applies, so nothing to run (no PROTO line)"),
    ("D05", "or", "", "the-cellular-basis-of-inheritance-m45467-34", "BLN:nondisjunction GO:0007127 GO:0007135 GO:0140013",
     "object-side or between two sibling processes", "nondisjunction happens during meiosis I or meiosis II",
     "GO:0007127, GO:0007135 is_a GO:0140013 (closure, OLS4)", "none (subject ungrounded)",
     "which division; the subject has no term", "INEXPRESSIBLE", "Stress: #no_lean m45467-34; d05_coarse (shape rel)", "PASS",
     "D-a coarsen to meiotic division, stateable (obs); D-c PASS: happens during (MI ⊔ MII), coarsened (obs); subject still BLN"),
    ("D06", "or", "", "cell-structure-and-function-m45432-311;cell-structure-and-function-m45432-183",
     "GO:0005840 GO:0005737 GO:0009898 GO:0098554",
     "a three-way or with one disjunct kept as the whole (review: was 'sound coarsening', PASS)",
     "every ribosome is in the cytoplasm or on the cytoplasmic side of the PM or ER; in GO the PM side (GO:0009898) is part of the plasma membrane, not of the cytoplasm, so 'every ribosome located in cytoplasm' is false for PM-bound ribosomes",
     "GO:0005737, GO:0009898 definitions and GO:0009898, GO:0098554 ancestors (OLS4); Rapoport 2007 PMID 18046402", "R2: ribosome located in cytoplasm, established",
     "the plasma-membrane disjunct", "FAIL", "Stress: d06_r2_established; #guard !isACurie GO:0009898 GO:0005737; #no_lean m45432-183", "PASS",
     "D-a: no useful common ancestor of cytoplasm and the PM side (pred); D-c PASS: located in (cytoplasm ⊔ PM side ⊔ ER side), and 'some located in (PM side ⊔ ER side)' for -183 (obs; review: the first version stated -183's two-way union as a universal, false for free ribosomes)"),
    ("D07", "or", "", "cell-structure-and-function-m45433-53", "CHEBI:16646 CHEBI:17089 CHEBI:33563 CHEBI:63299",
     "exhaustive or on the object", "membrane carbohydrates are in glycoproteins or glycolipids",
     "CHEBI:17089, CHEBI:33563 is_a CHEBI:63299 (closure, OLS4)", "none (refused, blocker disjunction)",
     "the exhaustive reading", "INEXPRESSIBLE", "Stress: #no_lean m45433-53; d07_someProt (shape quant rel)", "PASS",
     "D-a two 'some' claims only (obs); D-b PASS (pred); D-c PASS: part of (glycoprotein ⊔ glycolipid), coarsened (obs)"),
    ("D08", "or", "", "the-body-s-systems-m45534-78;the-body-s-systems-m45534-79",
     "UBERON:0001898 GO:0042311 GO:0042310 GO:0097746 PATO:0001305",
     "an or that is really a split by condition", "heat: cutaneous vasodilation; cold: vasoconstriction and shivering",
     "Charkoudian 2003 PMID 12744548; Morrison 2019 PMID 30256726", "none",
     "the split by condition", "INEXPRESSIBLE", "Stress: #no_lean m45534-78, -79; #guard d08_heat.subjectCurie", "PASS",
     "D-a PASS: split by organism state stateable (obs); D-c union target stateable but weaker, nothing derived (obs)"),
    ("D09", "or", "", "the-body-s-systems-m45534-44", "NCBITaxon:40674 NCBITaxon:8782 UBERON:0001037 UBERON:0001013 UBERON:0000022",
     "or on subject and object (endotherms: mammals or birds)", "mammals have hair, birds feathers; both may have fat",
     "UBERON:0001037, UBERON:0000022 (OLS4)", "none", "the subject class", "INEXPRESSIBLE",
     "Stress: #no_lean m45534-44; d09_mammal, d09_bird (shape rel)", "PASS",
     "D-a split by taxon (obs); D-c PASS: union taxon and union object stateable; union taxon unknown to Taxa, so no transport (obs)"),
    ("D10", "or", "", "the-body-s-systems-m45539-92", "",
     "a tautological or", "nothing follows from the or itself", "logic", "none", "nothing", "PASS",
     "Stress: #no_lean m45539-92 (review: was 'no pin; OBS only')", "PASS", "nothing derived today (obs); no prototype part applies (no PROTO line)"),
    ("D11", "or", "", "how-cells-obtain-energy-m45437-188", "GO:0043085 GO:0043086 GO:0050790",
     "or of two signs: an unsigned regulation", "enzymes are positively and negatively regulated; GO:0050790 covers both",
     "GO:0043085, GO:0043086 is_a GO:0050790 (OLS4 parents)", "none",
     "half the closure: GO:0043085 not imported", "SILENT", "Stress: #no_lean m45437-188; #guard !Ontology.isACurie posRegCatalytic.curie regCatalytic.curie; Proto: #check_failure unionLub",
     "SILENT", "D-c unionLub refused: closure gap, not a schema gap (obs); fix is importing the term (data)"),
    ("D12", "or", "", "cell-structure-and-function-m45434-94", "PO:0009002 PECO:0007404 CHEBI:15377 GO:0006833",
     "or in the antecedent", "drought, or too little water, makes plant cells lose water", "textbook (osmosis); logic: (A or B) then C is two claims",
     "none (round 2: ungrounded)", "the record", "SILENT", "Stress: #no_lean m45434-94; d12_drought, d12_underwatered (shape rel)", "PASS",
     "D-a PASS once annotated: two claims, stateable today (obs); review: was SILENT under the prototype, inconsistent with D08 and with the option table"),
    ("D13", "or", "", "molbio-m45475-4", "GO:0006260 GO:0006279 GO:0140014 GO:0140013 GO:0000280",
     "one disjunct asserted, then inherited by a subclass",
     "DNA replication precedes mitosis or meiosis; premeiotic replication precedes meiosis",
     "GO:0006279 definition 'The replication of DNA that precedes meiotic cell division' (OLS4)",
     "R2: DNA replication precedes mitotic nuclear division", "meiosis; and it derives a false claim",
     "FAIL", "Stress: d13_wrong_established", "PASS",
     "D-a PASS if coarsened to nuclear division (obs, d13_coarse); D-c PASS: precedes (mitotic ⊔ meiotic); premeiotic case true (obs)"),
    ("D17", "or", "", "the-cellular-basis-of-inheritance-m45467-139", "BLN:chromosome_21_gene BLN:chromosome_18_gene",
     "a claim-level or: two hedged explanations (added in review; the survey had it, the first set did not)",
     "the book asserts neither explanation alone, only that one or both hold; chromosome 21 is the smallest autosome, with 225 genes on 21q",
     "the sentence and its context (-135 to -138); Hattori 2000 PMID 10830953",
     "none (round 2 refused it: blocker disjunction)", "the record", "INEXPRESSIBLE",
     "Stress: #no_lean m45467-139; d17_alone_established, d17_rivalry_lowers; Proto: d17_or_established", "PASS",
     "D-a FAIL: asserting either half alone is over-strong (obs, d17_alone_established); core Rivalry: wrong logic, 'at most one' (obs, beliefs 4/9); D-b PASS: Claim.or stated, b 0.8 on the or, nothing on each half (obs); D-c INEXPRESSIBLE (two different predicates)"),
    ("D14", "or", S, "", "",
     "opinion on A or B from evidence on A only", "belief at least A's, no disbelief", "Jøsang 2006 Eq. 37 (comultiplication with a vacuous opinion)",
     "none", "the opinion", "INEXPRESSIBLE", "Proto: d14_or_one_side", "PASS", "D-b PASS: b 0.80 d 0 (obs)"),
    ("D15", "or", S, "", "",
     "two refuted independent disjuncts", "disbelief in A or B is the product, 0.64: not refuted", "Jøsang 2006 Eq. 35, 37",
     "none", "the opinion", "INEXPRESSIBLE", "Proto: d15_two_refuted, d15_not_refuted", "PASS", "D-b PASS: d 0.64, unsupported (obs)"),
    ("D16", "or", S, "how-cells-obtain-energy-m45439-28", "CHEBI:15422 CHEBI:15996",
     "exclusive alternatives in one frame (one turn makes ATP or GTP)", "belief in the union is the sum of the two masses",
     "Jøsang 2006 Eq. 17 (coarsening)", "none", "the opinion", "INEXPRESSIBLE", "Proto: d16_coarsen, d16_comul", "PASS",
     "D-d PASS: 0.9 established (obs); D-b comultiplication would give 0.7 (obs): wrong operator for exclusive alternatives"),
    ("A01", "about", "", "cell-structure-and-function-m45428-20", "CL:0000232 NCBITaxon:9606 PATO:0001334",
     "about n stored as a point", "a typical RBC is 6.2 to 8.2 µm across", "Bandaru and Killeen PMID 32965812",
     "R3: most RBC diameter in [8, 8] µm", "about", "FAIL", "Stress: #guard bounds a01.claim = some (8, 8)", "PASS",
     "A-a PASS: [7.2, 8.8], compareIntervals refuses the overlap (obs); A-b PASS: no clash (obs)"),
    ("A02", "about", "", "cell-structure-and-function-m45433-32", "CL:0000232 PATO:0000915",
     "a wrong textbook number against data", "RBC thickness is 2 to 2.5 µm at most, not 8", "Bandaru and Killeen PMID 32965812",
     "R3: thickness [8, 8] µm, established", "about; and the conflict", "FAIL", "Stress: a02_textbook_established, a02_absurd_belief", "PASS",
     "A-a FAIL in core: absurd less still derived (obs); PASS with the outside lint (obs); A-b PASS: clash flagged, book value unsupported (obs)"),
    ("A03", "about", "", "the-body-s-systems-m45536-45", "UBERON:0003126 NCBITaxon:9606 PATO:0000122",
     "a stated range that is wrong", "adult trachea about 10 cm (10.14 ± 2.04 men, 9.37 ± 1.28 women)", "Kumari 2019 PMID 31828242",
     "R3: length [25, 30] cm, established", "the conflict", "FAIL", "Stress: a03_textbook_established", "PASS",
     "A-a: lint flags it (obs, review: was pred); A-b PASS: clash flagged (obs)"),
    ("A04", "about", "", "molbio-m45473-77;molbio-m45475-94", "SO:0001026 SO:0000028 NCBITaxon:562",
     "rounded count stored exact", "E. coli K-12 genome is 4,639,221 bp, 4.6 million to two figures", "Blattner 1997 PMID 9278503",
     "R3: count 4,600,000 exact", "rounding", "FAIL", "Stress: a04_both_established", "PASS",
     "A-a PASS: countBetween [4.55M, 4.65M] holds it (obs); A-b PASS (obs)"),
    ("A05", "about", "", "molbio-m45475-98;molbio-m45473-77", "SO:0001026 GO:0005657 SO:0000028",
     "exact arithmetic on a rounded count", "about 2.3 million bp per fork; measured genome gives 2,319,610.5", "arithmetic on Blattner 1997",
     "perSet derives exactly 2,300,000; refuses the odd measured count", "about; the measured case", "FAIL", "Stress: a05_half_established, a05_odd", "PASS",
     "A-a SILENT: perSet refuses countBetween (obs); A-b PASS: [2.275M, 2.325M] (obs); A-d SILENT: lint refuses (pred)"),
    ("A06", "about", "", "molbio-m45475-100;molbio-m45475-97", "GO:0006260 NCBITaxon:562 PATO:0001309 PATO:0000161",
     "a rate from a count and a time", "about 900 nt/s per fork from the book's own numbers; consistent with 'approximately 1000'",
     "arithmetic on the book's numbers", "R3: rate [1000, 1000], time [42, 42] min", "the link", "SILENT", "Stress: #guard bounds a06_rate.claim", "PASS",
     "A-a SILENT (pred); A-b PASS: ratioA gives [892, 934], overlaps (obs)"),
    ("A07", "about", "", "the-body-s-systems-m45536-16;the-body-s-systems-m45536-17", "GO:0003016 NCBITaxon:9606 PATO:0000044",
     "unit change on an approximate rate", "15/min is 900/h is 21,600/day", "arithmetic",
     "R3: [15, 15] /min and [900, 900] /h, unlinked", "the link", "SILENT", "Stress: #guard a07_min.claim.subjectCurie = a07_hour.claim.subjectCurie", "PASS",
     "A-a SILENT (pred); A-b PASS: scaleA (obs)"),
    ("A08", "about", "", "the-body-s-systems-m45539-36;the-body-s-systems-m45539-37", "UBERON:0001016 NCBITaxon:7227 NCBITaxon:6705 CL:0000540",
     "'the same number' between two approximations", "about the same order; the fly brain alone has 139,255 neurons", "Dorkenwald 2024 PMID 39358518",
     "R3: both count 100,000 exact, equal", "about; equality is too strong", "FAIL", "Stress: a08_same_exactly", "PASS",
     "A-a PASS: two countBetween, overlap (pred); A-b PASS: overlap; but 139,255 clashes under ±10% and not under the last-digit reading (obs)"),
    ("A09", "about", "", "the-body-s-systems-m45539-40", "UBERON:0000955 NCBITaxon:9606 CL:0000540",
     "about n against a measured spread", "86.1 ± 8.1 billion neurons", "Azevedo 2009 PMID 19226510",
     "R3: count 86,000,000,000 exact", "about", "FAIL", "Stress: #guard countOf a09.claim", "PASS",
     "A-a PASS: countBetween [77.4, 94.6] billion holds 86.1 billion (obs, review: was pred); A-b PASS: overlap (obs)"),
    ("A10", "about", "", "the-body-s-systems-m45539-36;the-body-s-systems-m45539-40", "UBERON:0001016 UBERON:0000955 CL:0000540",
     "comparing two counts", "a fly has far fewer neurons than a human brain", "Azevedo 2009; Dorkenwald 2024",
     "no comparison rule for counts", "the comparison", "SILENT", "Stress: #check_failure compareIntervals", "PASS",
     "A-a SILENT (pred); A-b PASS: fewerA (obs)"),
    ("A11", "about", "", "molbio-m45479-7", "CHEBI:15841 CHEBI:33709",
     "'approximately 50' as a universal lower bound", "a polypeptide has ten or more residues; 50 is typical, not a minimum",
     "CHEBI:15841 definition (OLS4)", "R3: atLeast polypeptide 50 amino acids, established", "typical", "FAIL", "Stress: a11_established", "FAIL",
     "all options FAIL: the problem is 'typical', not 'about' (obs for A-b)"),
    ("A12", "about", "", "the-body-s-systems-m45539-127", "GO:0022008 NCBITaxon:40674 UBERON:0002421",
     "an approximate clade value", "rat about 9,000/day; adult human 700/day or undetectable", "Cameron 2001 PMID 11406822; Spalding 2013 PMID 23746839; Sorrells 2018 PMID 29513649",
     "R3: Mammalia [1000, 1000] neurons/day, established", "about; the taxon spread", "FAIL", "Stress: a12_established", "FAIL",
     "all options FAIL: no clade-to-member rule for measures; and ±10% vs last-digit disagree on 700 (obs)"),
    ("A13", "about", "", "cell-structure-and-function-m45428-22;cell-structure-and-function-m45428-21", "CL:0000232 PATO:0001334",
     "a ratio of two approximations", "about 250 red cells across a pin head (2 mm / 8 µm); the book's 'fit on' read as covering the head would be about 49,000",
     "arithmetic: 2 mm / 8 µm; π/4 × 250²",
     "none (not in Lean)", "the derivation", "SILENT", "Stress: #no_lean m45428-21, -22; example 2000 / 8 = 250", "PASS",
     "A-a SILENT (pred); A-b PASS for the width ratio: ratioA gives [204.5, 305.6] (obs); it cannot tell a width from an area (units are strings)"),
    ("A14", "about", "", "molbio-m45479-46;molbio-m45479-92;molbio-m45479-45", "CHEBI:33709",
     "control: exact counts stay exact", "some amino acid has two or more codons", "textbook (genetic code)",
     "Quantity.degeneracy, established", "nothing", "PASS", "Stress: a14_degeneracy", "PASS", "all options PASS (obs for A-b)"),
    ("A15", "about", "", "reproduction-at-the-cellular-level-m45455-17;reproduction-at-the-cellular-level-m45455-18", "GO:0005694",
     "control: exact division", "23 chromosomes per set", "textbook", "Quantity.perSet23, established", "nothing",
     "PASS", "Stress: a15_perSet", "PASS", "all options PASS (obs for A-b)"),
    ("A16", "about", S, "", "CHEBI:15422",
     "net of two approximations", "made about 100, used about 90: the net is in [-9, 29], sign unknown", "interval arithmetic",
     "netYield gives exactly 10, established", "about", "FAIL", "Stress: a16_net_established", "PASS",
     "A-a FAIL: produces has no interval form (obs); A-b PASS (obs); A-d SILENT (pred)"),
    ("A17", "about", S, "", "",
     "pigeonhole on approximations", "about 22 items, about 20 holes: no conclusion", "interval arithmetic",
     "pigeonhole fires, established", "about", "FAIL", "Stress: a17_established", "PASS",
     "A-a FAIL: cardinality has no interval form (obs); A-b PASS: refused (obs); A-d SILENT (pred)"),
    ("A18", "about", "", "cell-structure-and-function-m45433-33", "GO:0005886 CL:0000232 PATO:0000915",
     "an approximate ratio weakened to an order", "the membrane is thinner than the cell (the 1000x ratio is wrong)", "Bandaru and Killeen PMID 32965812",
     "R3: less (membrane, RBC, thickness)", "the ratio", "PASS", "Stress: #guard toString a18.claim", "PASS", "all options PASS (obs)"),
    ("C01", "context", "", "cell-structure-and-function-m45432-280", "CL:0000115 UBERON:0001981 PATO:0001167 PR:000001940",
     "a state of the subject", "damaged endothelial cells display tissue factor", "Mackman 2007 PMID 17556654",
     "R3: damaged put on the organism", "the bearer", "FAIL", "Stress: #guard c01.claim.subjectCurie", "PASS",
     "C-a PASS: nest on the subject (obs, c01_nested); C-b PASS (obs); C-c PASS (pred)"),
    ("C02", "context", "", "reproduction-at-the-cellular-level-m45461-123", "GO:0051318 CL:0000000 NCBITaxon:9606",
     "a state of the cells, not the organism", "G1 lasts about 11 h in rapidly dividing human cells", "the sentence; RO has_modifier domain (OLS4)",
     "R3: rapidly dividing put on the human", "the bearer", "FAIL", "Stress: #guard c02.claim.subjectCurie", "PASS",
     "C-a PASS: nest on the cell-type filler (obs); C-b PASS (obs); C-c FAIL: a process takes no has_modifier (obs, fits)"),
    ("C03", "context", "", "reproduction-at-the-cellular-level-m45461-122", "GO:0007049 CL:0000000 NCBITaxon:40674",
     "two states of the cells", "the cycle of fast-dividing mammalian cells in culture is about 24 h", "the sentence",
     "none (not emitted)", "the record", "SILENT", "Stress: #no_lean m45461-122; #guard c03_nested.curie", "PASS",
     "C-a PASS by nesting, order-dependent (obs); C-b PASS, one curie either order (obs)"),
    ("C04", "context", "", "molbio-m45475-83", "GO:0003720 NCBITaxon:10090 PATO:0001764 HP:0002180",
     "two organism states and transport", "a mouse result on aged, telomerase-deficient mice can be transported, discounted", "Jaskelioff 2011 PMID 21113150",
     "R3: one state (telomerase-deficient), 'aged' dropped", "a state; transport", "SILENT", "Stress: c04_one_belief, #check_failure transport", "PASS",
     "C-a SILENT: transport refuses a refined taxon (obs); C-b PASS: transport2, b 0.21 (obs)"),
    ("C05", "context", "", "molbio-m45475-83", "NCBITaxon:10090 PATO:0001764",
     "identity of a two-state class", "one class, whatever order the states are written", "description logic: conjunction commutes",
     "two curies for one class", "identity", "FAIL", "Stress: c05_two_curies, c05_env_two_curies", "PASS",
     "C-a FAIL (obs); C-b PASS: sorted (obs); C-d PASS with a swap rule (pred)"),
    ("C06", "context", "", "cell-structure-and-function-m45432-24", "GO:0006955 NCBITaxon:9606 MONDO:0005130",
     "control: one organism state", "the immune response in celiac disease damages microvilli", "textbook",
     "R3: one condition", "nothing", "PASS", "Stress: #guard c06.claim.subjectCurie", "PASS", "C-b same curie as the core (obs)"),
    ("C07", "context", "", "the-cellular-basis-of-inheritance-m45467-58", "GO:0009048 UBERON:0000068 NCBITaxon:40674 PATO:0000383",
     "control: taxon, life stage and a state", "X inactivation in female mammalian embryos", "Lyon 1961 PMID 13764598",
     "R3: three slots", "nothing", "PASS", "Stress: #guard c07.claim.subjectCurie", "PASS", "C-b same curie as the core (obs)"),
    ("C08", "context", "", "cell-structure-and-function-m45434-70", "GO:0098657 CL:0000000 PATO:0001656 CHEBI:15377",
     "surroundings of the cell, not of the process", "in a hypotonic solution water enters the cell", "textbook (osmosis)",
     "R3: solution around the process", "the bearer", "FAIL", "Stress: #guard c08.claim.subjectCurie", "PASS",
     "C-a PASS: Examples/Context nests it (obs); C-b PASS (obs)"),
    ("C09", "context", "", "photosynthesis-m45448-84", "NCBITaxon:33090 GO:0090332 BLN:hot_dry_day",
     "two conditions fused into one term", "nothing about heat alone follows (heat can open stomata)", "Urban 2017 PMID 28338959",
     "R3: one BLN term", "the parts", "PASS", "Stress: #check_failure (dropping the condition)", "PASS", "C-b PASS: no upward rule (obs)"),
    ("C10", "context", "", "photosynthesis-m45448-84", "NCBITaxon:33090 PECO:0007404 PECO:0007173 GO:0090332",
     "specialising a one-condition claim to two", "plants close stomata in drought, so also on a hot dry day", "Liu 2022 PMID 36499153",
     "no link from drought to the BLN term", "the link", "SILENT", "Stress: #check_failure (drought to hot dry)", "PASS",
     "C-a PASS in one nesting order (pred); C-b PASS: dropAxiom, b 0.6 (obs). The move is the monotone one that fails in C11; it lands right here, but heat alone opens stomata (Urban 2017)"),
    ("C11", "context", "", "molbio-m45480-33", "CHEBI:17716 NCBITaxon:562 CHEBI:17234 GO:0005990",
     "monotone inheritance across a second condition", "with glucose present, lactose use is repressed (diauxie)", "Inada 1996 PMID 9133663",
     "derived: lactose in (E. coli surrounded by glucose) ->+ lactose catabolism, established (review: glucose was written as has_modifier, a quality; now surrounded_by on the taxon, nested by hand)", "nothing; a wrong conclusion is added", "FAIL",
     "Stress: c11_established", "FAIL", "all options FAIL (obs for C-b): refinement is monotone, biology is not"),
    ("C12", "context", "", "molbio-m45480-41", "CHEBI:36229 CHEBI:17716 NCBITaxon:562 CHEBI:17234 PR:000023070",
     "the same move where it is right; an environment and a state together", "allolactose still inactivates the repressor on glucose",
     "Inada 1996 PMID 9133663 (inducer exclusion; lacI disruption or IPTG abolishes glucose repression)",
     "derived, but only as a hand-nested subject", "the canonical form", "PASS", "Stress: c12_established", "PASS",
     "C-a PASS, hand-nested (obs); C-b PASS, canonical (obs)"),
    ("C13", "context", "", "the-cellular-basis-of-inheritance-m45467-63", "GO:0009048 NCBITaxon:9685 PATO:0000384 PATO:0001533",
     "two organism states, order of nesting", "male tortoiseshell cats show variegation too", "Centerwall 1973 PMID 4798734",
     "derivable in one nesting order only", "order independence", "SILENT", "Stress: c13_hand_established, #check_failure", "PASS",
     "C-a SILENT in one order (obs); C-b PASS either order (obs); C-d PASS (pred)"),
    ("C14", "context", "", "the-body-s-systems-m45537-199", "CHEBI:17234 PR:P01275 UBERON:0000178 CL:0000171 GO:0070091",
     "source squeezed into a location slot", "alpha cells secrete glucagon when blood glucose falls", "CL:0000171 definition (OLS4)",
     "R3: glucagon located in blood and part of an alpha cell", "the role", "FAIL", "Stress: #guard toString c14.claim", "FAIL",
     "C-a PASS: glucose ->- glucagon secretion in alpha cells, stateable today (obs); C-b unchanged (obs)"),
    ("C15", "context", "", "molbio-m45475-71", "GO:0005697 CL:0002371 UBERON:0000113 GO:0000723",
     "control: two conditions in two core slots", "normal somatic tissues lack telomerase activity", "Kim 1994 PMID 7605428",
     "R3: cell type and life stage", "nothing (CL:0002371 is obsolete)", "PASS", "Stress: #guard c15.claim.subjectCurie", "PASS",
     "all options PASS (obs)"),
]


def run_lean():
    lines = []
    for f in FILES:
        r = subprocess.run(["lake", "env", "lean", f], cwd=ROOT, capture_output=True, text=True, timeout=900)
        errs = [l for l in r.stdout.splitlines() if ": error" in l]
        if errs:
            sys.exit(f"{f} has errors:\n" + "\n".join(errs[:10]))
        lines += [l for l in r.stdout.splitlines() if l.startswith(("OBS\t", "PROTO\t"))]
    with open(os.path.join(OUT, "lean_output.txt"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    return lines


def sentences():
    out = {}
    for d in ["claims", "claims_m2", "claims_m3"]:
        for f in glob.glob(os.path.join(ROOT, "data", "textbook", d, "*.json")):
            for r in json.load(open(f)):
                out.setdefault(r["id"], r.get("source", ""))
    return out


def main():
    if "--cached" in sys.argv:
        lines = open(os.path.join(OUT, "lean_output.txt")).read().splitlines()
    else:
        lines = run_lean()
    obs = collections.defaultdict(list)
    proto = collections.defaultdict(list)
    for l in lines:
        p = l.split("\t")
        if p[0] == "OBS":
            obs[p[1]].append(p[2])
        else:
            proto[p[1]].append(f"[{p[2]}] {p[3]}")
    sent = sentences()
    head = ["id", "gap", "synthetic", "probes", "input", "curies", "correct", "source", "encoding_today",
            "lost", "observed", "mark", "test", "proto_observed", "mark_proto", "options"]
    rows = []
    for (cid, gap, syn, ids, curies, probes, correct, source, enc, lost, mark, test, markp, opts) in SPEC:
        txt = " | ".join(f"{i}: {sent.get(i, '(not found)')}" for i in ids.split(";") if i)
        o = " / ".join(obs.get(cid, [])) or "(no OBS line)"
        if gap == "about" and cid in ("A01", "A02", "A04", "A05", "A16", "A17"):
            o += " / A-a run: " + " ".join(obs.get("Aa", []))
        pr = " / ".join(proto.get(cid, [])) or "(no PROTO line)"
        rows.append([cid, gap, syn, probes, txt or "(synthetic)", curies, correct, source, enc, lost, o, mark, test, pr, markp, opts])
    missing = [r[0] for r in rows if r[10].startswith("(no OBS") and r[2] != S]
    with open(os.path.join(OUT, "cases.tsv"), "w") as fh:
        fh.write("\t".join(head) + "\n")
        for r in rows:
            fh.write("\t".join(x.replace("\t", " ").replace("\n", " ") for x in r) + "\n")
    count = collections.Counter((r[1], r[11]) for r in rows)
    countp = collections.Counter((r[1], r[14]) for r in rows)
    marks = ["PASS", "FAIL", "SILENT", "INEXPRESSIBLE"]
    with open(os.path.join(OUT, "marks.tsv"), "w") as fh:
        fh.write("gap\twhen\t" + "\t".join(marks) + "\ttotal\n")
        for g in ["or", "about", "context"]:
            for when, c in (("today", count), ("best_option", countp)):
                vals = [c[(g, m)] for m in marks]
                fh.write(f"{g}\t{when}\t" + "\t".join(map(str, vals)) + f"\t{sum(vals)}\n")
        for when, c in (("today", count), ("best_option", countp)):
            vals = [sum(c[(g, m)] for g in ["or", "about", "context"]) for m in marks]
            fh.write(f"all\t{when}\t" + "\t".join(map(str, vals)) + f"\t{sum(vals)}\n")
    print(open(os.path.join(OUT, "marks.tsv")).read())
    print(len(rows), "cases;", sum(1 for r in rows if r[2] == S), "synthetic;",
          sum(1 for r in rows if r[4] != "(synthetic)"), "with textbook sentences")
    if missing:
        print("cases with no OBS line:", missing)
    nf = [r[0] for r in rows if "(not found)" in r[4]]
    if nf:
        print("sentence ids not found:", nf)


if __name__ == "__main__":
    main()
