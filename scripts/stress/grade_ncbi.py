"""Program 05: NCBI Taxonomy lineages for the stress-set test members.

Fetches efetch XML (db=taxonomy) into /tmp/biolean-05/ncbi2/ and writes
data/stress/05/lineage.tsv: taxid, scientific name, rank, ancestor taxids (root first).
Run with `python3 -I scripts/stress/grade_ncbi.py`.
"""
import pathlib
import time
import urllib.request
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/05"
DL = pathlib.Path("/tmp/biolean-05/ncbi2")
DL.mkdir(parents=True, exist_ok=True)

IDS = [562, 2246, 2242, 2285, 2303, 666, 2173, 1148, 5833, 3055, 400682, 7830, 28377, 7227, 6645, 33072, 5691,
       6398, 79327, 4932, 9606, 3702, 7955, 3039, 2880, 4177, 2022461, 2049356, 2759, 2157, 2,
       13815]  # 13815 Marsilea: added in review, case C03


def main():
    path = DL / f"efetch_{len(IDS)}.xml"
    if not path.exists():
        url = ("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=taxonomy&id="
               + ",".join(map(str, IDS)))
        with urllib.request.urlopen(url, timeout=120) as r:
            path.write_bytes(r.read())
        time.sleep(1)
    root = ET.fromstring(path.read_bytes())
    rows = []
    for t in root.findall("Taxon"):
        tid = t.findtext("TaxId")
        name = t.findtext("ScientificName")
        rank = t.findtext("Rank")
        lin = [(x.findtext("TaxId"), x.findtext("ScientificName"), x.findtext("Rank"))
               for x in t.findall("LineageEx/Taxon")]
        rows.append((tid, name, rank, lin))
    with open(OUT / "lineage.tsv", "w") as f:
        f.write("# NCBI Taxonomy efetch, 2026-10-31, scripts/stress/grade_ncbi.py\n")
        f.write("taxid\tname\trank\tancestors (taxid:name, root first)\n")
        for tid, name, rank, lin in rows:
            f.write(f"{tid}\t{name}\t{rank}\t" + "; ".join(f"{a}:{b}" for a, b, _ in lin) + "\n")
    for tid, name, rank, lin in rows:
        keep = [f"{a}:{b}" for a, b, r in lin if r in ("domain", "superkingdom", "kingdom", "phylum", "class", "order") or a in ("2759", "33208", "7742", "32523", "33090", "3193", "4751", "89593", "7711", "2698737", "5794", "3041", "7777", "7898", "8509", "1117", "28890")]
        print(tid, name, rank, "|", " > ".join(keep))


if __name__ == "__main__":
    main()
