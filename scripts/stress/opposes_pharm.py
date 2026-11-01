"""Program 06: read-only lookups of drug action types in ChEMBL and the IUPHAR Guide to Pharmacology.

  python3 -I scripts/stress/opposes_pharm.py chembl [--write] naloxone morphine   # --write: data/stress/06/chembl_mechanisms.tsv
  python3 -I scripts/stress/opposes_pharm.py gtop 319            # GtoPdb target id: interactions
Caches JSON in /tmp/biolean-06/dl2/pharm/ (untrusted data).
"""
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CACHE = Path("/tmp/biolean-06/dl2/pharm")


def get(url, name):
    p = CACHE / name
    if p.exists():
        return json.loads(p.read_text())
    req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": "biolean-06"})
    with urllib.request.urlopen(req, timeout=60) as r:
        d = json.loads(r.read().decode())
    p.write_text(json.dumps(d))
    return d


def chembl(names, write=False):
    rows = []
    for n in names:
        s = get(f"https://www.ebi.ac.uk/chembl/api/data/molecule.json?pref_name__iexact={urllib.parse.quote(n)}&limit=3",
                f"chembl_name_{n}.json")
        mols = s.get("molecules", [])
        if not mols:
            print(n, "no molecule")
            continue
        m = mols[0]
        cid = m["molecule_chembl_id"]
        mech = get(f"https://www.ebi.ac.uk/chembl/api/data/mechanism.json?parent_molecule_chembl_id={cid}&limit=50",
                   f"chembl_mechp_{cid}.json")
        for x in mech.get("mechanisms", []):
            row = f"{n}\t{cid}\t{m.get('pref_name')}\t{x.get('action_type')}\t{x.get('target_chembl_id')}\t{x.get('mechanism_of_action')}"
            if row not in rows:   # ChEMBL lists some mechanisms twice (one per reference)
                rows.append(row)
                print(row)
    if write:
        (ROOT / "data/stress/06/chembl_mechanisms.tsv").write_text(
            "drug\tchembl_id\tpref_name\taction_type\ttarget_chembl_id\tmechanism\n" + "".join(r + "\n" for r in rows))


def gtop(tid):
    d = get(f"https://www.guidetopharmacology.org/services/targets/{tid}/interactions", f"gtop_{tid}.json")
    for x in d:
        print(f"{tid}\t{x.get('ligandId')}\t{x.get('ligandName') or ''}\t{x.get('type')}\t{x.get('action')}\t{x.get('species')}\t{x.get('endogenous')}")


def main(argv):
    CACHE.mkdir(parents=True, exist_ok=True)
    if argv[0] == "chembl":
        chembl([a for a in argv[1:] if a != "--write"], write="--write" in argv)
    elif argv[0] == "gtop":
        for t in argv[1:]:
            gtop(t)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
