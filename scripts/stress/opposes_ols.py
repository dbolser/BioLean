"""Program 06: look up CURIEs and search terms on OLS4 (read-only GETs).

  python3 -I scripts/stress/opposes_ols.py term CURIE [CURIE ...]   # label, obsolete, definition
  python3 -I scripts/stress/opposes_ols.py search ONTOLOGY "query"  # free-text search in one ontology

Responses are cached as JSON in /tmp/biolean-06/dl2/ols/ (untrusted data). `term` writes one row
per CURIE to data/stress/06/curies_checked.tsv (curie, label, obsolete, ontology, iri, checked_on),
replacing any earlier row for that CURIE, so re-running it does not duplicate rows.
"""
import datetime
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CACHE = Path("/tmp/biolean-06/dl2/ols")
OUT = ROOT / "data/stress/06/curies_checked.tsv"
BASE = "https://www.ebi.ac.uk/ols4/api"

ONT = {"GO": "go", "UBERON": "uberon", "CL": "cl", "CHEBI": "chebi", "NCBITaxon": "ncbitaxon",
       "RO": "ro", "PR": "pr", "PATO": "pato", "OBA": "oba", "HP": "hp", "BFO": "bfo", "MONDO": "mondo",
       "NCIT": "ncit", "PO": "po", "ECO": "eco", "OGMS": "ogms", "MI": "mi"}


def get(url: str, cache: Path):
    if cache.exists():
        return json.loads(cache.read_text())
    req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": "biolean-06"})
    with urllib.request.urlopen(req, timeout=60) as r:
        data = json.loads(r.read().decode())
    cache.write_text(json.dumps(data))
    return data


def iri_of(curie: str) -> str:
    pre, num = curie.split(":", 1)
    if pre == "PR" and not num.isdigit():
        return f"http://purl.obolibrary.org/obo/PR_{num}"
    return f"http://purl.obolibrary.org/obo/{pre}_{num}"


def term(curie: str):
    pre = curie.split(":", 1)[0]
    ont = ONT.get(pre, pre.lower())
    iri = iri_of(curie)
    enc = urllib.parse.quote(urllib.parse.quote(iri, safe=""), safe="")
    kind = "properties" if pre in ("RO", "BFO") else "terms"
    url = f"{BASE}/ontologies/{ont}/{kind}/{enc}"
    cache = CACHE / f"{curie.replace(':', '_')}.json"
    try:
        d = get(url, cache)
    except Exception as e:  # noqa: BLE001
        d = None
        if kind == "properties":
            # BFO relations (BFO:0000066 occurs in) are served by RO, not by the BFO ontology
            for o2, k2 in ((ont, "terms"), ("ro", "properties")):
                try:
                    d = get(f"{BASE}/ontologies/{o2}/{k2}/{enc}", cache)
                    ont = o2
                    break
                except Exception as e2:  # noqa: BLE001
                    err = e2
        if d is None:
            return curie, f"ERROR {err if kind == 'properties' else e}", "", ont, iri
    label = d.get("label", "")
    obs = str(d.get("is_obsolete", d.get("isObsolete", "")))
    desc = d.get("description") or d.get("annotation", {}).get("definition") or [""]
    return curie, label, obs, ont, iri, (desc[0] if desc else "")[:300]


def search(ont: str, q: str):
    url = f"{BASE}/search?q={urllib.parse.quote(q)}&ontology={ont}&rows=25"
    cache = CACHE / f"search_{ont}_{q.replace(' ', '_').replace('/', '_')}.json"
    d = get(url, cache)
    for doc in d.get("response", {}).get("docs", []):
        print(f"{doc.get('obo_id')}\t{doc.get('label')}\t{doc.get('type')}\t{(doc.get('description') or [''])[0][:160]}")


def main(argv):
    CACHE.mkdir(parents=True, exist_ok=True)
    if argv[0] == "term":
        head = "curie\tlabel\tobsolete\tontology\tiri\tchecked_on"
        rows = {}
        if OUT.exists():
            for line in OUT.read_text().splitlines()[1:]:
                if line.strip():
                    rows[line.split("\t", 1)[0]] = line
        for c in argv[1:]:
            row = term(c)
            print("\t".join(row))
            rows[c] = "\t".join(list(row[:5]) + [datetime.date.today().isoformat()])
        OUT.write_text(head + "\n" + "".join(r + "\n" for r in rows.values()))
    elif argv[0] == "search":
        search(argv[1], argv[2])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
