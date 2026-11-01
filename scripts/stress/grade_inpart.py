"""Program 05: which NCBI taxa carry a grade name, and in which name class ('in-part', 'common name').

NCBI marks a name that covers part of this taxon and part of others as 'in-part': a grade. Downloads
go to /tmp/biolean-05/ncbi3/ (untrusted data). Writes data/stress/05/ncbi_inpart.tsv.
Run with `python3 -I scripts/stress/grade_inpart.py`.
"""
import json
import pathlib
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/05"
DL = pathlib.Path("/tmp/biolean-05/ncbi3")
DL.mkdir(parents=True, exist_ok=True)
EU = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
NAMES = ["prokaryote", "Protista", "protists", "algae", "invertebrates", "Invertebrata", "fishes", "Pisces",
         "lizards", "Reptilia", "microorganisms"]


def get(url, path):
    if not path.exists():
        with urllib.request.urlopen(url, timeout=120) as r:
            path.write_bytes(r.read())
        time.sleep(0.4)
    return path.read_bytes()


def main():
    rows = []
    for n in NAMES:
        q = urllib.parse.quote(f'"{n}"[All Names]')
        ids = json.loads(get(f"{EU}/esearch.fcgi?db=taxonomy&term={q}&retmode=json&retmax=100", DL / f"es_{n}.json"))["esearchresult"]["idlist"]
        if not ids:
            rows.append((n, "", "", "none"))
            continue
        root = ET.fromstring(get(f"{EU}/efetch.fcgi?db=taxonomy&id={','.join(ids)}&retmode=xml", DL / f"ef_{n}.xml"))
        for t in root.findall("Taxon"):
            on = t.find("OtherNames")
            cls = sorted({c.tag for c in (on if on is not None else []) if (c.text or "").strip().lower() == n.lower()})
            rows.append((n, f"NCBITaxon:{t.findtext('TaxId')}", t.findtext("ScientificName"), ",".join(cls) or "other"))
    with open(OUT / "ncbi_inpart.tsv", "w") as f:
        f.write("# NCBI Taxonomy taxa carrying a grade name, and its name class; E-utilities 2026-10-31, scripts/stress/grade_inpart.py\n")
        f.write("grade_name\ttaxon\tscientific_name\tname_class\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    for n in NAMES:
        hits = [r for r in rows if r[0] == n and r[1]]
        print(f"{n:15s} {len(hits):3d}", "; ".join(f"{r[2]} ({r[3]})" for r in hits[:8]))


if __name__ == "__main__":
    main()
