"""Program 05: fetch abstracts of the checked references and verify quotes as verbatim substrings.

Abstracts go to /tmp/biolean-05/epmc2/abs/ (untrusted data). `--show KEY...` prints abstracts.
Without arguments, checks QUOTES and writes data/stress/05/quotes_checked.tsv.
Run with `python3 -I scripts/stress/grade_quotes.py`.
"""
import csv
import html
import json
import pathlib
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/05"
DL = pathlib.Path("/tmp/biolean-05/epmc2/abs")
DL.mkdir(parents=True, exist_ok=True)
API = "https://www.ebi.ac.uk/europepmc/webservices/rest/search"

# (key, what the quote supports, verbatim fragment of the abstract; "TITLE:" checks the title instead)
QUOTES = [
    ("Woese1990", "three domains; the prokaryote-eukaryote dichotomy rejected", "the eukaryote-prokaryote dichotomy--reflects this primary tripartite division"),
    ("Woese1990", "M02: Euryarchaeota hold methanogens and their relatives", "Euryarchaeota (encompassing the methanogens and their phenotypically diverse relatives)"),
    ("Williams2013", "eukaryotes inside Archaea: two primary domains", "support for only two primary domains of life--Archaea and Bacteria"),
    ("Whitman2009", "the prokaryote concept debated", "TITLE:The modern concept of the procaryote"),
    ("Pace2006", "the prokaryote concept debated", "TITLE:Time for a change"),
    ("Adl2012", "protist is kept as a working grade in eukaryote classification", "retains an emphasis on the protists"),
    ("Burki2020", "most eukaryote lineages are protists", "mostly free-living heterotrophic protists"),
    ("Pawlowski2012", "protists = eukaryotes beyond animals, plants, fungi", "TITLE:barcoding eukaryotic richness beyond the animal, plant, and fungal kingdoms"),
    ("Deegan2010", "GO taxon constraints", "the location 'mitochondrion' is specific to eukaryotes"),
    ("Albers2011", "P01-P03, P05: archaea have one membrane, no nucleus or ER", "all archaea characterized to date have only a single membrane"),
    ("Schafer1999", "P02: chemiosmotic respiration in archaea", "the universal principle of chemiosmotic energy conservation also holds for Archaea"),
    ("Liao2021", "P04: bacteria divide with FtsZ", "In bacteria, the tubulin homologue FtsZ assembles a cytokinetic ring"),
    ("Liao2021", "P04: H. volcanii divides with FtsZ", "Haloferax volcanii cannot divide properly without either or both FtsZ proteins"),
    ("Lindas2008", "P04: Sulfolobus divides with Cdv, not FtsZ", "The cdv genes exhibit a complementary phylogenetic range relative to FtsZ-based archaeal division systems"),
    ("Darland1970", "P07: Thermoplasma has no cell wall", "A thermophilic, acidophilic procaryote lacking a cell wall"),
    ("Beveridge1996", "P07: archaeal S-layer walls", "Some archaea have only a single S-layer as their cell wall"),
    ("Beveridge1996", "P09: archaeal walls lack peptidoglycan", "their cell walls do not contain peptidoglycan"),
    ("Esko2009", "P09: bacterial walls have peptidoglycan", "Bacterial glycans include peptidoglycan"),
    ("Jarrell2012", "P08: the archaellum is not a bacterial flagellum", "the archaellum and the bacterial flagellum are two distinct structures"),
    ("Volland2022", "P19: membrane-bound organelles in a bacterium", "compartmentalization of genomic material and ribosomes in translationally active organelles bound by bioenergetic membranes"),
    ("Hawkins2013", "P10: bacteria have one origin", "Bacteria and some archaea replicate from single origins"),
    ("Hawkins2013", "P10: H. volcanii has four origins", "identify four chromosomal origins of differing activity"),
    ("Lundgren2004", "P10: Sulfolobus has three origins", "initiated in near synchrony from three separate sites in both organisms"),
    ("Heidelberg2000", "P11: V. cholerae has two chromosomes", "The genome consists of two circular chromosomes"),
    ("Hartman2010", "P11: H. volcanii has several chromosomes", "The genome contains a main 2.848 Mb chromosome, three smaller chromosomes"),
    ("Nakamura2003b", "P11: Gloeobacter has one chromosome", "The genome of G. violaceus was a single circular chromosome"),
    ("Nakamura2003b", "P13: Gloeobacter photosynthesises in the plasma membrane", "photosynthesis in G. violaceus takes place not in thylakoid membranes but in the cytoplasmic membrane"),
    ("Mullineaux2014", "P13, L03: cyanobacterial thylakoids", "The thylakoid membranes of cyanobacteria are the major sites of respiratory electron transport as well as photosynthetic light reactions"),
    ("Chen2005", "P12: Sulfolobus is aerobic", "Sulfolobus acidocaldarius is an aerobic thermoacidophilic crenarchaeon"),
    ("Brasen2014", "P17: archaeal glycolysis is a modified form", "unique, modified variants of classical pathways such as the Embden-Meyerhof-Parnas (EMP) pathway"),
    ("Opperdoes1977", "P18: T. brucei glycolysis in glycosomes", "TITLE:Localization of nine glycolytic enzymes in a microbody-like organelle in Trypanosoma brucei: the glycosome"),
    ("Keeling2010", "R01, A02, L01: green algae have plastids", "red algae and green algae (including plants)"),
    ("Keeling2010", "R01: euglenids have green-algal plastids", "Green algal plastids were taken up by euglenids"),
    ("Kohler1997", "R01: Apicomplexa have a secondary plastid", "the Apicomplexa acquired a plastid by secondary endosymbiosis"),
    ("Cholewa2025", "R01: Euglena is a photosynthetic protist", "E. gracilis is a unicellular protist"),
    ("Cholewa2025", "R02: Euglena has no cell wall", "It has no cell wall"),
    ("Goodenough1985", "R02, R03: Chlamydomonas has a cell wall", "we have analyzed the structure of the intact cell wall of Chlamydomonas reinhardi"),
    ("Poulhazan2024", "L02: the Chlamydomonas wall has no cellulose", "cell walls devoid of cellulose"),
    ("Handke2013", "I01: arthropods have an open circulatory system", "In arthropods, which have trachea for gas exchange and an open circulatory system"),
    ("LePabic2014", "I01: cephalopods have a closed system", "a vertebrate-like high-pressure closed circulatory system"),
    ("MonahanEarley2013", "I01: no blood vascular system before triploblasts", "the blood vascular system first appeared in an ancestor of the triploblasts"),
    ("Bernal2001", "F01: only lamnid sharks (and tunas) conserve heat", "Traits separating these two groups from other fishes include"),
    ("Bernal2001", "F02: sharks are fishes", "despite differences between teleost and elasmobranch fishes"),
    ("Wolfe1992", "L01: Epifagus does not photosynthesise", "a nonphotosynthetic parasitic flowering plant, lacks all genes for photosynthesis"),
    ("Azimzadeh2012", "C01: centrosome is a hallmark of animal cells", "is a hallmark of animal cells"),
    ("Azimzadeh2012", "C01: planarians lack centrosomes", "planarians, and possibly other flatworms, lack centrosomes"),
    ("Dutcher2003", "C03: Chlamydomonas has centrioles", "Chlamydomonas reinhardtii provides an excellent model organism for the study of the basal body and centrioles"),
    ("Conly1994", "M01: gut bacteria make vitamin K2", "supporting a definite role for bacterially synthesized vitamin K2"),
    ("Samuel2007", "M02: M. smithii lives in the human gut", "Methanobrevibacter smithii, the dominant archaeon in the human gut ecosystem"),
    ("Mullakhanbhai1975", "M02: halobacteria need high salt", "which is about half of that generally reported for the halobacteria"),
    ("Evans2015", "M02: methanogens outside Euryarchaeota", "no compelling evidence has existed for methane metabolism in archaea outside the phylum Euryarchaeota"),
    # added in review, 2026-10-31
    ("Muller2005", "P12: Halobacterium respires anaerobically", "NRC-1 was found to grow on either dimethyl sulfoxide (DMSO) or trimethylamine N-oxide (TMAO) as the sole terminal electron acceptor"),
    ("Mizukami1966", "C03: a fern (an embryophyte) makes centrioles", "the basal bodies of which have the typical cylindrical structure of centrioles"),
]


def refs():
    with open(OUT / "references_checked.tsv") as f:
        rows = [r for r in csv.reader((l for l in f if not l.startswith("#")), delimiter="\t")]
    return {r[0]: r for r in rows[1:] if r[7] == "ok"}


def abstract(pmid):
    path = DL / f"{pmid}.json"
    if not path.exists():
        q = urllib.parse.quote(f"EXT_ID:{pmid} AND SRC:MED")
        with urllib.request.urlopen(f"{API}?query={q}&format=json&resultType=core", timeout=60) as r:
            path.write_bytes(r.read())
        time.sleep(0.4)
    res = (json.loads(path.read_text()).get("resultList") or {}).get("result") or [{}]
    a = res[0].get("abstractText") or ""
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", a))).strip()


def norm(s):
    return re.sub(r"\s+", " ", s).strip()


def main(argv):
    R = refs()
    if argv and argv[0] == "--show":
        for k in argv[1:] or R:
            print(f"== {k} PMID {R[k][1]}\n{abstract(R[k][1])}\n")
        return 0
    rows, bad = [], 0
    for k, use, q in QUOTES:
        if q.startswith("TITLE:"):
            ok = norm(q[6:]).rstrip(".") in norm(R[k][5])
        else:
            ok = norm(q) in abstract(R[k][1])
        bad += not ok
        rows.append((k, R[k][1], "ok" if ok else "NOT FOUND", use, q))
    with open(OUT / "quotes_checked.tsv", "w") as f:
        f.write("# quotes checked as verbatim substrings of the Europe PMC abstract (TITLE: of the title), 2026-10-31\nkey\tpmid\tcheck\tuse\tquote\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    for r in rows:
        if r[2] != "ok":
            print(r)
    print(f"{len(rows)} quotes, {bad} not found")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
