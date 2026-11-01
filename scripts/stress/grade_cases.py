"""Program 05: run the grade-term stress set and mark every row.

Runs `lake env lean` on BioLean/Stress/GradeTerms.lean (current core, data-only options) and
BioLean/Proto/TaxonUnion.lean (prototype core changes), reads their `ROW` lines, and marks each row
against the biology below (TRUTH, each with a checked source key from references_checked.tsv, an
OLS4-checked ontology definition, or the textbook itself for uncontroversial textbook facts).

Writes data/stress/05/rows.tsv (every row), cases.tsv (one line per case) and option_scores.tsv.
Usage: python3 scripts/stress/grade_cases.py [--cached]   (--cached reads /tmp/biolean-05/*_out.txt)
"""
import collections
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/05"
FILES = {"Stress.GradeTerms": "BioLean/Stress/GradeTerms.lean", "Proto.TaxonUnion": "BioLean/Proto/TaxonUnion.lean"}
CACHE = {"Stress.GradeTerms": "/tmp/biolean-05/stress_out.txt", "Proto.TaxonUnion": "/tmp/biolean-05/proto_out.txt"}

# raw option label -> option letter of docs/programs/05-grade-terms.md
LETTER = {
    "a": "a", "a-r2": "a", "a+": "a+", "a-bact": "a'", "a-embryo": "a'", "a-actino": "a'",
    "b0": "b0", "b": "b", "b-euk": "b", "b-ecocore": "b", "b-ncbi": "b", "g+b": "b", "b-virtualNode": "b", "b-meanParts": "b",
    "b-minParts": "b", "c": "c", "c-partial": "c", "e-v": "e", "c+some": "h", "d": "d", "d-euk": "d",
    "e": "e", "f": "f", "g": "g", "replaced_by": "a'", "a+count": "i", "b+count": "b+i",
}
STATUS_QUO = {"a", "a-r2"}

# ---------------------------------------------------------------- the biology
# truth of the conclusion for the member: T true, F false, N nothing to say (outside the group, or
# the sentence is hedged for it), V vacuously true (about an empty class), U not checked.
# A conclusion is marked by its truth (T, V PASS; F, N FAIL). A silence is SILENT only when a
# conclusion is due (T); after a hedge ("some", "most" in the book) nothing is due for one member,
# so those silences get N through TRUTH_OPT (review 2026-10-31: P08 E. coli, I01 option h).
T, F, N, V, U = "T", "F", "N", "V", "U"
TRUTH = {
    ("G05-P01", "Escherichia coli"): (T, "OpenStax m45476-20"), ("G05-P01", "Halobacterium salinarum"): (T, "OpenStax m45476-20; Albers2011"),
    ("G05-P01", "Sulfolobus acidocaldarius"): (T, "OpenStax m45476-20; Albers2011"), ("G05-P01", "Haloferax volcanii"): (T, "OpenStax m45476-20; Albers2011"),
    ("G05-P01", "Homo sapiens"): (F, "OpenStax m45480-85 (transcription in the nucleus)"),
    ("G05-P02", "Escherichia coli"): (T, "OpenStax m45439-48"), ("G05-P02", "Sulfolobus acidocaldarius"): (T, "Albers2011; Schafer1999"),
    ("G05-P02", "Halobacterium salinarum"): (T, "Albers2011; Schafer1999"), ("G05-P02", "Homo sapiens"): (F, "OpenStax m45439-47 (inner mitochondrial membrane)"),
    ("G05-P03", "Escherichia coli"): (T, "OpenStax m45479-20"), ("G05-P03", "Halobacterium salinarum"): (T, "Albers2011 (one membrane, no ER)"),
    ("G05-P03", "Sulfolobus acidocaldarius"): (T, "Albers2011 (one membrane, no ER)"),
    ("G05-P04", "Escherichia coli"): (T, "Liao2021"), ("G05-P04", "Haloferax volcanii"): (T, "Liao2021"),
    ("G05-P04", "Sulfolobus acidocaldarius"): (F, "Lindas2008 (Cdv, not FtsZ)"),
    ("G05-P05", "Escherichia coli"): (T, "OpenStax m45476-18"), ("G05-P05", "Halobacterium salinarum"): (T, "OpenStax m45476-18; Albers2011"),
    ("G05-P05", "Sulfolobus acidocaldarius"): (T, "OpenStax m45476-18; Albers2011"),
    ("G05-P06", "Escherichia coli"): (T, "OpenStax m45429-56 (consensus)"), ("G05-P06", "Halobacterium salinarum"): (T, "OpenStax m45429-56 (consensus)"),
    ("G05-P07", "Escherichia coli"): (T, "Esko2009; GO:0009274"), ("G05-P07", "Halobacterium salinarum"): (T, "Beveridge1996; Albers2011 (S-layer)"),
    ("G05-P07", "Thermoplasma acidophilum"): (F, "Darland1970"),
    ("G05-P08", "Escherichia coli"): (U, "hedged sentence; E. coli flagella not checked"), ("G05-P08", "Halobacterium salinarum"): (F, "Jarrell2012 (archaellum)"),
    ("G05-P19", "Candidatus Thiomargarita sp. Lot2"): (F, "Volland2022"),
    ("G05-P09", "Escherichia coli"): (T, "Esko2009; GO:0009274"), ("G05-P09", "Halobacterium salinarum"): (F, "Beveridge1996"),
    ("G05-P09", "Haloferax volcanii"): (F, "Beveridge1996"), ("G05-P09", "plant-type cell wall"): (F, "GO:0009505 definition (cellulose and pectin)"),
    ("G05-P10", "Escherichia coli"): (T, "Hawkins2013"), ("G05-P10", "Sulfolobus acidocaldarius"): (F, "Lundgren2004"),
    ("G05-P10", "Haloferax volcanii"): (F, "Hawkins2013"),
    ("G05-P11", "Gloeobacter violaceus"): (T, "Nakamura2003b"), ("G05-P11", "Vibrio cholerae"): (F, "Heidelberg2000"),
    ("G05-P11", "Haloferax volcanii"): (F, "Hartman2010"),
    ("G05-P12", "Sulfolobus acidocaldarius"): (F, "Chen2005 (aerobic)"), ("G05-P12", "Halobacterium salinarum"): (T, "Muller2005 (DMSO or TMAO as terminal electron acceptor, strain NRC-1)"),
    ("G05-P12", "Escherichia coli"): (N, "hedged: 'some species of bacteria'"),
    ("G05-P13", "Gloeobacter violaceus"): (T, "Nakamura2003b"), ("G05-P13", "Synechocystis sp. PCC 6803"): (F, "Mullineaux2014 (thylakoids)"),
    ("G05-P17", "Escherichia coli"): (T, "OpenStax m45438-62"), ("G05-P17", "Sulfolobus acidocaldarius"): (T, "Brasen2014 (modified EMP/ED)"),
    ("G05-P17", "Homo sapiens"): (T, "OpenStax m45438-62"),
    ("G05-P18", "Trypanosoma brucei"): (T, "Opperdoes1977 (glycosome); GO:0020015 is_a microbody, part_of GO:0005737; OpenStax glossary m45432-361"), ("G05-P18", "Homo sapiens"): (T, "OpenStax m45438-33"),
    ("G05-P18", "Escherichia coli"): (T, "OpenStax m45438-33"),
    ("G05-R01", "Chlamydomonas reinhardtii"): (T, "Keeling2010"), ("G05-R01", "Euglena"): (T, "Keeling2010; Cholewa2025"),
    ("G05-R01", "Plasmodium falciparum"): (F, "Kohler1997; Keeling2010 (apicoplast, not a chloroplast; GO:0020011)"),
    ("G05-R01", "Homo sapiens"): (F, "OpenStax m45432-241 context (animal cells have no chloroplasts; consensus)"),
    ("G05-R02", "Saccharomyces cerevisiae"): (T, "GO:0009277 definition"), ("G05-R02", "Chlamydomonas reinhardtii"): (T, "Goodenough1985"),
    ("G05-R02", "Euglena"): (F, "Cholewa2025"), ("G05-R02", "Homo sapiens"): (N, "not a protist"),
    ("G05-R03", "Arabidopsis thaliana"): (T, "GO:0009505 definition"), ("G05-R03", "Chlamydomonas reinhardtii"): (T, "Goodenough1985"),
    ("G05-R03", "Saccharomyces cerevisiae"): (T, "GO:0009277 definition"), ("G05-R03", "Escherichia coli"): (T, "Esko2009; GO:0009274"),
    ("G05-R03", "Plasmodium falciparum"): (N, "hedged: 'some protists'"), ("G05-R03", "Thermoplasma acidophilum"): (N, "not in the list (and wall-less, Darland1970)"),
    ("G05-R04", "Plasmodium falciparum"): (T, "CL:0000255 definition; NCBI lineage"), ("G05-R04", "Saccharomyces cerevisiae"): (T, "CL:0000255 definition; NCBI lineage"),
    ("G05-R04", "Homo sapiens"): (T, "CL:0000255 definition; NCBI lineage"),
    ("G05-A01", "chloroplast"): (T, "Keeling2010"),
    ("G05-A02", "Chlamydomonas reinhardtii"): (T, "Keeling2010"), ("G05-A02", "Arabidopsis thaliana"): (T, "Keeling2010"),
    ("G05-A02", "Euglena"): (T, "Keeling2010"), ("G05-A02", "Plasmodium falciparum"): (V, "no photosynthesis in Plasmodium: the class is empty"),
    ("G05-I01", "Drosophila melanogaster"): (T, "Handke2013"), ("G05-I01", "Octopus vulgaris"): (F, "LePabic2014 (cephalopods: closed)"),
    ("G05-I01", "Amphimedon queenslandica"): (F, "MonahanEarley2013 (no blood vascular system before triploblasts)"),
    ("G05-I01", "Scyliorhinus canicula"): (N, "a vertebrate"),
    ("G05-I03", "statement"): (T, "UBERON:0009054 definition"),
    ("G05-L01", "Arabidopsis thaliana"): (T, "Keeling2010"), ("G05-L01", "Chlamydomonas reinhardtii"): (T, "Keeling2010"),
    ("G05-L01", "Epifagus virginiana"): (F, "Wolfe1992"),
    ("G05-L02", "Arabidopsis thaliana"): (T, "GO:0009505 definition"), ("G05-L02", "Chlamydomonas reinhardtii"): (F, "Poulhazan2024; Goodenough1985"),
    ("G05-L03", "Arabidopsis thaliana"): (T, "OpenStax m45437-11"), ("G05-L03", "Synechocystis sp. PCC 6803"): (T, "Mullineaux2014"),
    ("G05-L04", "Arabidopsis thaliana"): (T, "GO:0009505 definition"), ("G05-L04", "Chlamydomonas reinhardtii"): (V, "no plant-type wall: the class is empty"),
    ("G05-C01", "Homo sapiens"): (T, "Azimzadeh2012"), ("G05-C01", "Schmidtea mediterranea"): (F, "Azimzadeh2012"),
    ("G05-C02", "Homo sapiens"): (T, "OpenStax m45461-91 (consensus)"), ("G05-C02", "prokaryotic cell"): (F, "Esko2009; GO:0009274"),
    ("G05-C03", "Arabidopsis thaliana"): (T, "OpenStax m45432-75 (consensus)"), ("G05-C03", "Chlamydomonas reinhardtii"): (F, "Dutcher2003"),
    ("G05-C03", "Marsilea"): (F, "Mizukami1966 (sperm basal bodies are centrioles)"),
    ("G05-M01", "statement"): (T, "Conly1994"), ("G05-M01", "Methanobrevibacter smithii"): (N, "an archaeon; the claim is hedged"),
    ("G05-M02", "Methanobrevibacter smithii"): (T, "Samuel2007"), ("G05-M02", "Halobacterium salinarum"): (F, "Mullakhanbhai1975 (halobacteria need high salt)"),
    ("G05-M02", "Haloferax volcanii"): (F, "Mullakhanbhai1975"),
    ("G05-M03", "Clostridium"): (T, "OpenStax m45440-45 (consensus)"),
    ("G05-S05", "Homo sapiens"): (F, "OpenStax m45480-85"), ("G05-S05", "generalise to cellular organisms"): (F, "OpenStax m45480-85"),
}
# overrides for one option
TRUTH_OPT = {
    ("G05-R02", "c", "Saccharomyces cerevisiae"): (N, "not a protist (the fungal half is a separate statement)"),
    ("G05-P08", "a", "Escherichia coli"): (N, "hedged: 'some prokaryotes'; nothing is due for one member"),
    ("G05-I01", "c+some", "Drosophila melanogaster"): (N, "hedged: 'some invertebrates'; nothing is due for one member"),
    ("G05-S05", "b", "Homo sapiens"): (N, "not a prokaryote"),
}
# membership in the book's group: (member, group) -> (member?, source)
BOOK_GROUP = {"Actinopterygii": "fish", "fish": "fish", "lizard": "lizard", "algae (eukaryotic)": "algae",
              "algae (ECOCORE)": "algae", "algae (NCBI in-part)": "algae", "protist": "protist", "invertebrate": "invertebrate"}
MEMBER = {
    ("Scyliorhinus canicula", "fish"): (True, "Bernal2001 ('elasmobranch fishes')"), ("Danio rerio", "fish"): (True, "NCBI lineage"),
    ("Anolis carolinensis", "fish"): (False, "NCBI lineage (Tetrapoda)"), ("Homo sapiens", "fish"): (False, "NCBI lineage (Tetrapoda)"),
    ("Anolis carolinensis", "lizard"): (True, "NCBI lineage (Iguania)"),
    ("Synechocystis sp. PCC 6803", "algae"): (False, "OpenStax m45448-18 ('bacteria and algae')"),
    ("Chlamydomonas reinhardtii", "algae"): (True, "NCBI lineage (Chlorophyta)"), ("Ectocarpus siliculosus", "algae"): (True, "NCBI lineage (Phaeophyceae)"),
    ("Euglena", "algae"): (True, "Cholewa2025 (photoautotroph); NCBI in-part name on Euglenida"),
    ("Plasmodium falciparum", "algae"): (False, "Kohler1997 ('Protozoan parasites')"),
    ("Amphimedon queenslandica", "protist"): (False, "NCBI lineage (Metazoa)"),
    ("Schmidtea mediterranea", "invertebrate"): (True, "NCBI lineage (Metazoa, not Vertebrata)"),
}
# rows that are not member tests: (file, case, option, member) -> (mark, note)
SPECIAL = {
    ("Stress.GradeTerms", "G05-P14", "a", "bridge statements"): ("SILENT", "expressible on the core, but blocked in round 2"),
    ("Stress.GradeTerms", "G05-P14", "d", "Bacteria cell is_a prokaryotic cell"): ("PASS", "OpenStax m45428-13; Woese1990"),
    ("Stress.GradeTerms", "G05-P14", "d", "Archaea cell is_a prokaryotic cell"): ("PASS", "OpenStax m45428-13; Woese1990"),
    ("Stress.GradeTerms", "G05-P15", "a", "membership statements"): ("SILENT", "expressible on the core, but blocked in round 2"),
    ("Stress.GradeTerms", "G05-P15", "b0", "Bacteria is_a Prokaryota"): ("PASS", "GO NCBITaxon_Union:0000004; Woese1990"),
    ("Stress.GradeTerms", "G05-P15", "b0", "Archaea is_a Prokaryota"): ("PASS", "GO NCBITaxon_Union:0000004; Woese1990"),
    ("Stress.GradeTerms", "G05-C02", "replaced_by", "clash with m45429-57"): ("PASS", "clash flags the bad rewrite as contested"),
    ("Stress.GradeTerms", "G05-S03", "g", "Chlamydomonas reinhardtii"): ("FAIL", "right claim, belief 8/9 from one sentence (4/5 due): double count, no warning"),
    ("Stress.GradeTerms", "G05-S05", "b0", "generalise to Prokaryota"): ("SILENT", "the union generalisation is right but refused"),
    ("Stress.GradeTerms", "G05-S08", "b0", "Taxa.known Prokaryota"): ("SILENT", "the union class is invisible to the taxon checks"),
    ("Stress.GradeTerms", "G05-S08", "b0", "taxonConsistent (E. coli evidence)"): ("FAIL", "E. coli evidence for a prokaryote claim is flagged inconsistent"),
    ("Stress.GradeTerms", "G05-S08", "b0", "generalize admissible"): ("SILENT", "generalising to the union is refused"),
    ("Stress.GradeTerms", "G05-S08", "b0", "transport E. coli to Halobacterium"): ("PASS", "siblings, so transport needs evidence: right"),
    ("Stress.GradeTerms", "G05-S09", "f", "Schmidtea mediterranea"): ("SILENT", "an invertebrate (NCBI lineage), but its phylum is not listed"),
    ("Proto.TaxonUnion", "G05-S04", "b", "virtualNode coverage"): ("FAIL", "judgement: one bacterium covers all of Bacteria"),
    ("Proto.TaxonUnion", "G05-S04", "b", "minParts coverage"): ("PASS", "judgement: bracketing's own rule (one sample brackets nothing)"),
    ("Proto.TaxonUnion", "G05-S04", "b", "meanParts coverage"): ("PASS", "judgement: weak but not zero"),
    ("Proto.TaxonUnion", "G05-S05", "b-virtualNode", "generalise to Prokaryota"): ("FAIL", "judgement: 12/13 from three species is over-strong"),
    ("Proto.TaxonUnion", "G05-S05", "b-meanParts", "generalise to Prokaryota"): ("PASS", "judgement: 3/13, weak"),
    ("Proto.TaxonUnion", "G05-S05", "b-minParts", "generalise to Prokaryota"): ("SILENT", "judgement: 0, no credit for two archaea"),
    ("Proto.TaxonUnion", "G05-S06", "c", "pruned bracketing, protist"): ("PASS", "coherent: equals Eukaryota's bracketing"),
    ("Proto.TaxonUnion", "G05-S06", "a", "bracketing, Eukaryota"): ("PASS", "core reference value"),
}

# ---------------------------------------------------------------- the cases
# id: (kind, probes, input sentence and current encoding, correct conclusion, sources)
CASES = {
    "G05-P01": ("textbook", "prokaryote true of the union; status quo loses archaea",
                "molbio-m45476-20 'transcription occurs in the cytoplasm' of prokaryotes. R3: GO:0006351 ⊓ in_taxon NCBITaxon:2 occurs_in GO:0005737",
                "true of every bacterium and archaeon; false of humans (nucleus)", "OpenStax m45476-20, m45480-85; Albers2011"),
    "G05-P02": ("textbook", "the case behind the provisional decision: widest clade reaches humans",
                "how-cells-obtain-energy-m45439-48 ETC 'in the plasma membrane of prokaryotes'. R3: GO:0022904 ⊓ in_taxon NCBITaxon:2 occurs_in GO:0005886",
                "true of bacteria and archaea; false of humans (inner mitochondrial membrane)", "OpenStax m45439-47; Albers2011; Schafer1999"),
    "G05-P03": ("textbook", "prokaryote true of the union",
                "molbio-m45479-20 ribosomes in the cytoplasm in prokaryotes. R3: GO:0005840 ⊓ in_taxon NCBITaxon:2 located_in GO:0005737",
                "true of bacteria and archaea", "OpenStax m45479-20; Albers2011"),
    "G05-P04": ("textbook", "prokaryote as CL cell type; prokaryote meaning bacterium (FtsZ)",
                "reproduction-at-the-cellular-level-m45463-1 'Prokaryotes such as bacteria propagate by binary fission'. R2: CL:0000520 capable_of GO:0043093 (FtsZ-dependent cytokinesis)",
                "true of E. coli and H. volcanii; false of Sulfolobus (Cdv)", "Liao2021; Lindas2008"),
    "G05-P05": ("textbook", "CL route: no organism reaches CL:0000520",
                "molbio-m45476-18 'The prokaryotes, which include bacteria and archaea, lack membrane-bound nuclei'. R2: ¬(CL:0000520 has_part GO:0005634)",
                "true of bacteria and archaea", "OpenStax m45476-18; Albers2011"),
    "G05-P06": ("textbook", "CL route", "cell-structure-and-function-m45429-56 'All prokaryotes have ... ribosomes'. R2: CL:0000520 has_part GO:0005840",
                "true of every prokaryote", "OpenStax m45429-56 (consensus)"),
    "G05-P07": ("textbook", "CL route; an exception inside the group",
                "cell-structure-and-function-m45429-57 'All prokaryotes have ... a cell wall'. R2: CL:0000520 has_part GO:0005618",
                "true of E. coli and Halobacterium (S-layer); false of Thermoplasma", "Esko2009; Beveridge1996; Darland1970"),
    "G05-P08": ("textbook", "hedge dropped; bacterial term used for archaea",
                "cell-structure-and-function-m45429-29 'Some prokaryotes have flagella'. R2: CL:0000520 has_part GO:0009288 (bacterial-type flagellum), 'some' dropped",
                "hedged; archaea have the archaellum (GO:0097589), not GO:0009288", "Jarrell2012"),
    "G05-P19": ("textbook", "character versus clade: a bacterium with membrane-bound organelles",
                "cell-structure-and-function-m45429-59 'All prokaryotes ... lack membrane-bound organelles'. R2: ¬(CL:0000520 has_part GO:0043231)",
                "false of Ca. Thiomargarita magnifica (NCBITaxon:2022461)", "Volland2022"),
    "G05-P09": ("textbook", "prokaryote meaning bacterium; context dropped",
                "cell-structure-and-function-m45432-224 'the chief component of prokaryotic cell walls is peptidoglycan'. R2: GO:0005618 has_part CHEBI:8005 (no context)",
                "true of bacteria; false of archaea and of plant walls", "Esko2009; Beveridge1996; GO:0009505"),
    "G05-P10": ("textbook", "prokaryote meaning bacterium; no rule narrows a count",
                "molbio-m45475-124 'replication in prokaryotes starts from a single origin'. R3: count (GO:0005694 ⊓ in_taxon NCBITaxon:2) SO:0000296 1",
                "true of E. coli; false of Sulfolobus (3) and H. volcanii (4)", "Hawkins2013; Lundgren2004"),
    "G05-P11": ("textbook", "even Bacteria is too wide; no rule narrows a count",
                "molbio-m45473-130 'Prokaryotes contain a single ... chromosome'. R3: count NCBITaxon:2 GO:0005694 1",
                "true of Gloeobacter; false of V. cholerae (2) and H. volcanii", "Nakamura2003b; Heidelberg2000; Hartman2010"),
    "G05-P12": ("textbook", "hedge dropped; union cut to one part",
                "how-cells-obtain-energy-m45440-37 'Certain prokaryotes, including some species of bacteria and Archaea, use anaerobic respiration'. R2: NCBITaxon:2157 capable_of GO:0009061",
                "hedged; false of Sulfolobus acidocaldarius (aerobic); true of Halobacterium", "Chen2005; Muller2005"),
    "G05-P13": ("textbook", "character-defined group ('photosynthetic prokaryotes'); meaning bacterium",
                "photosynthesis-m45453-64 'Prokaryotic photosynthetic autotrophic organisms have infoldings of the plasma membrane'. Blocked: ungrounded_entity",
                "true of Gloeobacter (no thylakoids); false of Synechocystis (thylakoids)", "Nakamura2003b; Mullineaux2014"),
    "G05-P14": ("textbook", "the book's own bridge from clades to the cell type",
                "cell-structure-and-function-m45428-13 'bacteria and archaea cells are classified as prokaryotic'. Blocked in R2",
                "true: two is_a statements into CL:0000520", "OpenStax m45428-13; Woese1990"),
    "G05-P15": ("textbook", "the book's own membership statement for the union",
                "molbio-m45476-17 'The prokaryotes, which include bacteria and archaea'. Blocked in R2",
                "true: Bacteria and Archaea are prokaryotes", "Woese1990; GO NCBITaxon_Union:0000004"),
    "G05-P16": ("textbook", "covering axiom (a disjunction)",
                "cell-structure-and-function-m45428-11 'all are grouped into one of two broad categories: prokaryotic and eukaryotic'. Not encoded",
                "every cell is prokaryotic or eukaryotic", "OpenStax m45428-11"),
    "G05-P17": ("textbook", "a union that is a clade (cellular organisms); 'most' added",
                "how-cells-obtain-energy-m45438-62 'Both prokaryotic and eukaryotic organisms carry out some form of glycolysis'. R3: most (NCBITaxon:131567 capable_of GO:0006096); R2: NCBITaxon:2759 only",
                "true of E. coli, Sulfolobus (modified pathway), humans", "OpenStax m45438-62; Brasen2014"),
    "G05-P18": ("textbook", "two quantifiers in one sentence; context dropped, harmlessly",
                "how-cells-obtain-energy-m45438-33 'in the cytoplasm of most prokaryotic and all eukaryotic cells'. R2: GO:0006096 occurs_in GO:0005737 (no context)",
                "true of humans, E. coli and T. brucei: its glycosomes are part of the cytoplasm (GO, and the book's glossary)", "Opperdoes1977; GO:0020015; OpenStax m45432-361"),
    "G05-R01": ("textbook", "protist plus a character ('photosynthetic protists')",
                "cell-structure-and-function-m45432-241 'photosynthetic protists also have chloroplasts'. R3: some (NCBITaxon:2759 has_part GO:0009507); R2: no 'some'",
                "true of Chlamydomonas and Euglena; false of Plasmodium (apicoplast) and humans", "Keeling2010; Kohler1997; Cholewa2025"),
    "G05-R02": ("textbook", "protist half dropped; CL fungal cell unreachable",
                "cell-structure-and-function-m45432-223 'Fungal and protist cells also have cell walls'. R2: CL:0000521 has_part GO:0009277",
                "true of yeast and Chlamydomonas; false of Euglena", "GO:0009277; Goodenough1985; Cholewa2025"),
    "G05-R03": ("textbook", "union of named clades plus a hedged grade",
                "cell-structure-and-function-m45434-86 'plants, fungi, bacteria, and some protists, have cell walls'. R2: NCBITaxon:33090 has_part GO:0005618",
                "true of Arabidopsis, Chlamydomonas, yeast, E. coli; nothing due for Plasmodium", "GO:0009505; GO:0009277; Esko2009; Goodenough1985"),
    "G05-R04": ("textbook", "grade not needed: the clade Eukaryota covers it; obsolete CL term",
                "cell-structure-and-function-m45428-12 'Animal cells, plant cells, fungal cells, and protist cells are classified as eukaryotic'. R2: CL:0000548 (obsolete) is_a CL:0000255",
                "true of Plasmodium, yeast and human cells", "CL:0000255 definition"),
    "G05-R05": ("textbook", "similarity across a union", "reproduction-at-the-cellular-level-m45455-4 'protists, plants, and animals employ similar steps'. Not encoded",
                "a comparison, no member conclusion", "OpenStax m45455-4"),
    "G05-A01": ("textbook", "grade dropped rightly ('such as')", "cell-structure-and-function-m45432-230 chloroplasts 'in eukaryotic cells such as plants and algae'. R2: GO:0009507 located_in CL:0000255",
                "true", "Keeling2010"),
    "G05-A02": ("textbook", "grade replaced by the clade it sits in", "photosynthesis-m45448-115 'Eukaryotic autotrophs, such as plants and algae, have ... chloroplasts'. R3: GO:0015979 ⊓ in_taxon NCBITaxon:2759 occurs_in GO:0009507",
                "true of photosynthetic eukaryotes; vacuous for Plasmodium", "Keeling2010"),
    "G05-A03": ("textbook", "algae term outside the imported ontologies", "photosynthesis-m45448-18 'others exist, including certain types of bacteria and algae'. Blocked: unsupported_ontology (ECOCORE:00000076)",
                "some algae are autotrophs", "OpenStax m45448-18"),
    "G05-A04": ("textbook", "who is an alga: vocabularies disagree", "photosynthesis-m45448-18 separates bacteria from algae; ECOCORE:00000076 'includes cyanobacteria'. No algae entity",
                "in the book's sense Synechocystis is not an alga; Chlamydomonas and Ectocarpus are", "OpenStax m45448-18; ECOCORE:00000076"),
    "G05-I01": ("textbook", "invertebrate (a complement); universal versus 'some'",
                "the-body-s-systems-m45536-87 'Open circulatory systems are found in invertebrate animals'. Blocked: ungrounded_entity",
                "the book means 'some' (a restrictive clause), so nothing is due for one member; read as universal it is true of Drosophila, false of octopus and sponge", "Handke2013; LePabic2014; MonahanEarley2013"),
    "G05-I02": ("textbook", "comparison with a grade", "the-body-s-systems-m45539-26 'Compared to invertebrates, vertebrate nervous systems are more complex'. Not encoded",
                "a comparison, no member conclusion", "OpenStax m45539-26"),
    "G05-I03": ("textbook", "grade dropped rightly: the claim is about a structure", "the-body-s-systems-m45536-88 'the circulatory fluid bathes the internal organs directly'. R3: UBERON:0006314 ⊓ located_in UBERON:0009054 adjacent_to UBERON:0000062",
                "true by UBERON's definition", "UBERON:0009054 definition"),
    "G05-F01": ("textbook", "fish (paraphyletic) inside a five-way union, each 'some'", "the-body-s-systems-m45534-71 'countercurrent adaptation is found in dolphins, sharks, bony fish, bees, and hummingbirds'. Blocked",
                "only lamnid sharks among sharks; membership: sharks are fish", "Bernal2001"),
    "G05-F02": ("textbook", "fish and lizards: membership of paraphyletic grades", "the-cellular-basis-of-inheritance-m45467-82 'a few examples among the flatworms, crustaceans, amphibians, fish, and lizards'. Blocked: has_quality",
                "hedged; membership: shark and zebrafish are fish, the anole is a lizard, not a fish", "Bernal2001; NCBI lineage"),
    "G05-L01": ("textbook", "broad 'plants' (Viridiplantae); loss inside a clade (control)", "how-cells-obtain-energy-m45437-59 'Plants ... converting the energy of sunlight to chemical energy'. R3: NCBITaxon:33090 capable_of GO:0015979",
                "true of Arabidopsis and Chlamydomonas; false of Epifagus", "Keeling2010; Wolfe1992"),
    "G05-L02": ("textbook", "'plant cell' meaning land plant", "cell-structure-and-function-m45432-322 'Plant cells have a cell wall, chloroplasts, and a central vacuole'. R3: CL:0000000 ⊓ in_taxon NCBITaxon:33090 has_part GO:0009505",
                "true of Arabidopsis; false of Chlamydomonas (no cellulose wall)", "GO:0009505; Poulhazan2024"),
    "G05-L03": ("textbook", "'plants' standing in for a character (photosynthesisers)", "how-cells-obtain-energy-m45437-11 'photosynthesizing organisms like plants produce these sugars'. R3: GO:0015979 ⊓ in_taxon NCBITaxon:33090 has_output CHEBI:16646",
                "true of Arabidopsis and of cyanobacteria", "Mullineaux2014"),
    "G05-L04": ("textbook", "'plant cell wall' with the GO term doing the work", "cell-structure-and-function-m45432-225 'the major organic molecule in the plant cell wall is cellulose'. R3: GO:0009505 ⊓ in_taxon NCBITaxon:33090 has_part CHEBI:18246",
                "true; vacuous for Chlamydomonas", "GO:0009505"),
    "G05-C01": ("textbook", "'animal cell' as Metazoa; loss inside a clade (control)", "cell-structure-and-function-m45432-318 'Animal cells also have a centrosome and lysosomes'. R3: CL:0000000 ⊓ in_taxon NCBITaxon:33208 has_part GO:0005813",
                "true of human cells; false of planarians", "Azimzadeh2012"),
    "G05-C02": ("textbook", "obsolete 'animal cell' term and its replaced_by", "reproduction-at-the-cellular-level-m45461-91 'animal cells that lack cell walls'. R2: ¬(CL:0000548 has_part GO:0005618), CL:0000548 obsolete",
                "true of human cells; replaced_by CL:0000000 would make it false of bacteria", "OpenStax m45461-91; Esko2009"),
    "G05-C03": ("textbook", "broad 'plants' in a negation", "cell-structure-and-function-m45432-75 'plant cells, which lack centrioles'. R3: ¬(CL:0000000 ⊓ in_taxon NCBITaxon:33090 has_part GO:0005814)",
                "true of Arabidopsis; false of Chlamydomonas and of the fern Marsilea (centrioles in sperm), so Embryophyta does not fix it", "Dutcher2003; Mizukami1966"),
    "G05-M01": ("textbook", "microbe meaning bacterium (right)", "cell-structure-and-function-m45432-253 'Microbes that produce vitamin K live inside the human gut'. R3: some (NCBITaxon:2 ⊓ located_in UBERON:0000160 produces CHEBI:28384)",
                "true", "Conly1994"),
    "G05-M02": ("textbook", "character-defined group (methanogens) as a phylum", "how-cells-obtain-energy-m45440-39 methanogens 'found in soil and in the digestive tracts of ruminants'. R2: NCBITaxon:28890 located_in UBERON:0001555",
                "true of M. smithii; false of halobacteria", "Samuel2007; Woese1990; Mullakhanbhai1975; Evans2015"),
    "G05-M03": ("textbook", "character-defined group (obligate anaerobes) as the book's own example genus", "how-cells-obtain-energy-m45440-47 'Oxygen is a poison to these microorganisms'. R3: Clostridium (NCBITaxon:1485)",
                "true of Clostridium", "OpenStax m45440-45 (consensus)"),
    "G05-S01": ("synthetic", "a complement needs a closed world", "protist = Eukaryota minus Metazoa, Fungi, Embryophyta; sponge lineage cut to 'cellular organisms, Eukaryota'",
                "a sponge is never a protist", "NCBI lineage"),
    "G05-S03": ("synthetic", "overlapping grades double-count", "R03 split into 'plants' and 'protists' statements; Chlamydomonas in both",
                "belief of one sentence (4/5)", "judgement"),
    "G05-S04": ("synthetic", "coverage over a union: three readings", "instances in E. coli, Halobacterium, Sulfolobus; target Prokaryota",
                "one bacterium should not cover Bacteria", "judgement; Coverage.lean bracketing rule"),
    "G05-S05": ("synthetic", "generalising to a union versus to the widest clade", "transcription in the cytoplasm in E. coli, Halobacterium, Sulfolobus",
                "true of prokaryotes; must not reach humans", "OpenStax m45480-85"),
    "G05-S06": ("synthetic", "coverage over a complement", "instances in Euglena and Paramecium; target protist",
                "coherent with bracketing at Eukaryota", "judgement"),
    "G05-S07": ("synthetic", "option e with a negative character", "prokaryote = cell without a nucleus (NCIT:C14263 definition)",
                "should be statable as a class", "NCIT:C14263"),
    "G05-S08": ("synthetic", "what the core's taxon checks do with a union class", "GO NCBITaxon_Union:0000004 used as a taxon",
                "a union class should be known, consistent, generalisable", "judgement"),
    "G05-S09": ("synthetic", "an open membership list (option f)", "invertebrate as a local grade listing Arthropoda, Mollusca, Porifera",
                "Schmidtea is an invertebrate", "NCBI lineage"),
}


def run(name):
    if "--cached" in sys.argv:
        return open(CACHE[name]).read()
    p = subprocess.run(["lake", "env", "lean", FILES[name]], cwd=ROOT, capture_output=True, text=True, timeout=600)
    if p.returncode != 0:
        sys.exit(f"{FILES[name]} failed:\n{p.stdout[-3000:]}{p.stderr[-2000:]}")
    open(CACHE[name], "w").write(p.stdout)
    return p.stdout


def mark(file, case, opt, member, obs):
    if (file, case, opt, member) in SPECIAL:
        return SPECIAL[(file, case, opt, member)] + ("",)
    if obs.startswith("inexpressible"):
        return "INEXPRESSIBLE", "", ""
    m = re.match(r"(not a member|member) of (.+)$", obs)
    if m:
        grp = BOOK_GROUP[m.group(2)]
        want, src = MEMBER[(member, grp)]
        got = m.group(1) == "member"
        return ("PASS" if got == want else "FAIL"), src, ("member" if want else "not a member") + f" of {grp} (book sense)"
    truth, src = TRUTH_OPT.get((case, opt, member)) or TRUTH.get((case, member), (None, None))
    if truth is None:
        sys.exit(f"no truth for {file} {case} {opt} {member}: {obs}")
    if truth == U:
        return "UNVERIFIED", src, "not checked"
    if obs.startswith("concl"):
        return {T: "PASS", V: "PASS", F: "FAIL", N: "FAIL"}[truth], src, truth
    if obs.startswith("silent"):
        return ("SILENT" if truth == T else "PASS"), src, truth
    sys.exit(f"unreadable row {file} {case} {opt} {member}: {obs}")


def agg(marks):
    ms = [m for m in marks if m != "UNVERIFIED"]
    if not ms:
        return ""
    for m in ("FAIL", "SILENT", "INEXPRESSIBLE"):
        if m in ms:
            return m
    return "PASS"


def tests():
    """Lean names per case: theorems and row lists whose name starts with the case code."""
    out = collections.defaultdict(list)
    for name, path in FILES.items():
        for m in re.finditer(r"^(theorem|def) (\w+)", open(ROOT / path).read(), re.M):
            kind, n = m.groups()
            if kind == "def" and not n.endswith("_rows"):
                continue
            c = re.match(r"([PRAIFLCMS]\d\d)", n)
            codes = ["F01", "F02"] if n in ("F_rows", "F_members") else ([c.group(1)] if c else [])
            for code in codes:
                out[f"G05-{code}"].append(f"{name}.{n}")
    return out


def main():
    rows = []
    for name in FILES:
        for line in run(name).splitlines():
            if line.startswith("ROW\t"):
                _, f, case, opt, member, obs = line.split("\t")
                mk, src, why = mark(f, case, opt, member, obs)
                rows.append((f, case, opt, LETTER[opt], member, obs, why, mk, src))
    with open(OUT / "rows.tsv", "w") as f:
        f.write("# every row printed by the two Lean files, marked by scripts/stress/grade_cases.py, 2026-10-31\n")
        f.write("file\tcase\toption_raw\toption\tmember\tobserved\ttruth\tmark\tsource\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    names = tests()
    by_case = collections.defaultdict(list)
    for r in rows:
        by_case[r[1]].append(r)
    with open(OUT / "cases.tsv", "w") as f:
        f.write("# program 05 stress set, one line per case; rows in rows.tsv; scripts/stress/grade_cases.py, 2026-10-31\n")
        f.write("id\tkind\tprobes\tinput\tcorrect\tobserved\tmark\tmark_core_data\tmark_proto\ttest\tsource\n")
        for cid, (kind, probes, inp, correct, source) in CASES.items():
            rs = by_case.get(cid, [])
            sq = [r for r in rs if r[2] in STATUS_QUO and r[0] == "Stress.GradeTerms"]
            if not sq:
                sq = [r for r in rs if r[0] == "Stress.GradeTerms"]
            obs = "; ".join(f"{r[4]}: {r[5]}" for r in sq) or "(prototype only)"
            core = [r for r in rs if r[0] == "Stress.GradeTerms" and r[2] not in STATUS_QUO]
            proto = [r for r in rs if r[0] == "Proto.TaxonUnion"]
            cd = "; ".join(f"{o}={agg([r[7] for r in core if r[2] == o])}" for o in dict.fromkeys(r[2] for r in core))
            pr = "; ".join(f"{o}={agg([r[7] for r in proto if r[2] == o])}" for o in dict.fromkeys(r[2] for r in proto))
            f.write("\t".join([cid, kind, probes, inp, correct, obs, agg([r[7] for r in sq]) or "n/a (prototype only)", cd, pr,
                               ", ".join(names.get(cid, [])), source]) + "\n")
    missing = sorted(set(by_case) - set(CASES))
    if missing:
        sys.exit(f"rows for undeclared cases: {missing}")
    score = collections.defaultdict(collections.Counter)
    for r in rows:
        score[r[3]][r[7]] += 1
    order = ["a", "a+", "a'", "b0", "b", "b+i", "c", "d", "e", "f", "g", "h", "i"]
    marks = ["PASS", "FAIL", "SILENT", "INEXPRESSIBLE", "UNVERIFIED"]
    with open(OUT / "option_scores.tsv", "w") as f:
        f.write("# rows per option and mark (rows.tsv); an option is only run on the cases it applies to\n")
        f.write("option\t" + "\t".join(marks) + "\ttotal\n")
        for o in order:
            c = score[o]
            f.write(f"{o}\t" + "\t".join(str(c[m]) for m in marks) + f"\t{sum(c.values())}\n")
    print(f"{len(rows)} rows, {len(CASES)} cases")
    sqm = collections.Counter()
    for cid in CASES:
        sq = [r for r in by_case.get(cid, []) if r[2] in STATUS_QUO and r[0] == "Stress.GradeTerms"] or \
             [r for r in by_case.get(cid, []) if r[0] == "Stress.GradeTerms"]
        sqm[(CASES[cid][0], agg([r[7] for r in sq]) or "proto only")] += 1
    print("case marks today (status quo rows):", dict(sqm))
    for o in order:
        print(f"  {o:4s}", dict(score[o]))


if __name__ == "__main__":
    main()
