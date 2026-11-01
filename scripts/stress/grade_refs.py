"""Program 05: check every cited paper on Europe PMC (title and first author must match).

PMID lookups and title searches go to /tmp/biolean-05/epmc2/ (untrusted data). Writes
data/stress/05/references_checked.tsv. Run with `python3 -I scripts/stress/grade_refs.py`.
"""
import json
import pathlib
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/05"
DL = pathlib.Path("/tmp/biolean-05/epmc2")
DL.mkdir(parents=True, exist_ok=True)
API = "https://www.ebi.ac.uk/europepmc/webservices/rest/search"

# key, PMID (or None to search by title), first author surname, title words that must appear
REFS = [
    ("Whitman2009", 19168606, "Whitman", "modern concept of the procaryote"),
    ("Pace2006", 16710401, "Pace", "Time for a change"),
    ("Woese1990", None, "Woese", "Towards a natural system of organisms"),
    ("Williams2013", None, "Williams", "archaeal origin of eukaryotes supports only two primary domains"),
    ("Adl2019", 30257078, "Adl", "Revisions to the Classification, Nomenclature, and Diversity of Eukaryotes"),
    ("Burki2020", 31606140, "Burki", "The New Tree of Eukaryotes"),
    ("Deegan2010", None, "Deegan", "Formalization of taxon-based constraints"),
    ("Albers2011", 21572458, "Albers", "The archaeal cell envelope"),
    ("Lundgren2004", 15107501, "Lundgren", "Three replication origins in Sulfolobus species"),
    ("Hawkins2013", 24185008, "Hawkins", "Accelerated growth in the absence of DNA replication origins"),
    ("Lindas2008", 18987308, "Lind", "unique cell division machinery in the Archaea"),
    ("Liao2021", 33903747, "Liao", "Haloferax volcanii relies on two FtsZ proteins"),
    ("Jarrell2012", 22613456, "Jarrell", "The archaellum"),
    ("Heidelberg2000", 10952301, "Heidelberg", "both chromosomes of the cholera pathogen"),
    ("Darland1970", 5481857, "Darland", "thermophilic, acidophilic mycoplasma"),
    ("Volland2022", 35737788, "Volland", "centimeter-long bacterium"),
    ("McFadden1996", 8632819, "McFadden", "Plastid in human parasites"),
    ("Goodenough1985", 2864348, "Goodenough", "Chlamydomonas cell wall"),
    ("Azimzadeh2012", 22223737, "Azimzadeh", "Centrosome loss in the evolution of planarians"),
    ("Evans2015", 26494757, "Evans", "Methane metabolism in the archaeal phylum Bathyarchaeota"),
    ("Mullineaux2014", 24316145, "Mullineaux", "cyanobacterial thylakoid membranes"),
    ("Schafer1999", 10477309, "Sch", "Bioenergetics of the Archaea"),
    ("Brasen2014", 24600042, "Br", "Carbohydrate metabolism in Archaea"),
    ("Fraser1997", 9403685, "Fraser", "Borrelia burgdorferi"),
    ("Lutes2010", 20173738, "Lutes", "parthenogenetic lizards"),
    ("Bernal2001", 11423338, "Bernal", "lamnid sharks and tunas"),
    ("Conly1994", 8198105, "Conly", "vitamin K2"),
    ("Leys2015", 25696821, "Leys", "nervous system' in sponges"),
    ("Samuel2007", None, "Samuel", "Methanobrevibacter smithii to the human gut"),
    ("Hartman2010", None, "Hartman", "complete genome sequence of Haloferax volcanii DS2"),
    ("Mullakhanbhai1975", None, "Mullakhanbhai", "Dead Sea halobacterium"),
    ("Wolfe1992", None, "Wolfe", "minimal plastid genome from a nonphotosynthetic parasitic plant"),
    ("Nakamura2003b", None, "Nakamura", "cyanobacterium that lacks thylakoids"),
    ("MonahanEarley2013", None, "Monahan-Earley", "Evolutionary origins of the blood vascular system and endothelium"),
    ("Otto2000", None, "Otto", "Polyploid incidence and evolution"),
    ("Keeling2010", None, "Keeling", "endosymbiotic origin, diversification and fate of plastids"),
    ("Oesterhelt1971", None, "Oesterhelt", "Rhodopsin-like protein from the purple membrane"),
    ("Werner2011", 21233849, "Werner", "multisubunit RNA polymerases"),
    ("Mungall2012", None, "Mungall", "Uberon, an integrative multi-species anatomy ontology"),
    ("Pohlschroder2015", 25852657, "Pohlschroder", "Archaeal type IV pili"),
    ("Kandler1998", None, "Kandler", "Cell wall polymers in Archaea"),
    ("Kohler1997", None, "K", "plastid of probable green algal origin in Apicomplexan parasites"),
    ("Poulhazan2024", 38307857, "Poulhazan", "glycoprotein-rich cell wall"),
    ("Pawlowski2012", None, "Pawlowski", "barcoding eukaryotic richness beyond the animal, plant, and fungal kingdoms"),
    ("Adl2012", None, "Adl", "The revised classification of eukaryotes"),
    ("Beveridge1996", 8885405, "Beveridge", "response of selected members of the archaea to the gram stain"),
    ("LePabic2014", 25066968, "Le Pabic", "Hemocyte morphology and phagocytic activity in the common cuttlefish"),
    ("Handke2013", 23840627, "Handke", "hemolymph proteome of fed and starved Drosophila larvae"),
    ("Esko2009", None, "Esko", "Eubacteria and Archaea"),
    ("Chen2005", 15995215, "Chen", "genome of Sulfolobus acidocaldarius"),
    ("Opperdoes1977", 142663, "Opperdoes", "glycosome"),
    ("Karnkowska2016", None, "Karnkowska", "A Eukaryote without a Mitochondrial Organelle"),
    ("Dutcher2003", 12795689, "Dutcher", "basal body and centriole functions in Chlamydomonas"),
    ("Cholewa2025", 40990997, "Cholewa", "Variable Bioproduction with Euglena gracilis"),
    # added in review, 2026-10-31
    ("Muller2005", 15716436, "Müller", "Genomic analysis of anaerobic respiration in the archaeon Halobacterium"),
    ("Mizukami1966", 5950730, "Mizukami", "Sperm formation in the fern, Marsilea, and the cycad, Zamia"),
]


def get(url, path):
    if not path.exists():
        with urllib.request.urlopen(url, timeout=60) as r:
            path.write_bytes(r.read())
        time.sleep(0.4)
    return json.loads(path.read_text())


def norm(s):
    return re.sub(r"[^a-z0-9 ]", "", (s or "").lower().replace("-", " "))


def main():
    rows = []
    for key, pmid, author, words in REFS:
        if pmid:
            q = f"EXT_ID:{pmid} AND SRC:MED"
        else:
            q = f'TITLE:"{words}"'
        url = f"{API}?query={urllib.parse.quote(q)}&format=json&resultType=lite&pageSize=5"
        d = get(url, DL / f"{key}.json")
        res = (d.get("resultList") or {}).get("result") or []
        hit = None
        for r in res:
            if norm(words) in norm(r.get("title")) and norm(author) in norm((r.get("authorString") or "").split(",")[0]):
                hit = r
                break
        if hit:
            rows.append((key, hit.get("pmid") or "", hit.get("doi") or "", hit.get("pubYear") or "",
                         (hit.get("authorString") or "").split(",")[0], hit.get("title") or "",
                         hit.get("journalTitle") or "", "ok"))
        else:
            got = res[0] if res else {}
            rows.append((key, str(pmid or ""), "", got.get("pubYear") or "", (got.get("authorString") or "")[:30],
                         got.get("title") or "", got.get("journalTitle") or "", "NOT MATCHED"))
    with open(OUT / "references_checked.tsv", "w") as f:
        f.write("# Europe PMC lookups, 2026-10-31, scripts/stress/grade_refs.py; 'ok' = first author and title words match\n")
        f.write("key\tpmid\tdoi\tyear\tfirst_author\ttitle\tjournal\tcheck\n")
        for r in rows:
            f.write("\t".join(str(x).replace("\t", " ") for x in r) + "\n")
    for r in rows:
        print(r[7], r[0], r[1], r[3], r[4], "|", r[5][:90], "|", r[6])


if __name__ == "__main__":
    sys.exit(main())
