"""Program 06: read ChEBI has_role (RO:0000087) links for given ChEBI CURIEs from OLS4 v2 (read-only).

  python3 -I scripts/stress/opposes_roles.py [--write] CHEBI:7459 CHEBI:17303
Caches JSON in /tmp/biolean-06/dl2/ols2/. Prints curie, label, and each role CURIE with its label.
With --write, also writes data/stress/06/chebi_roles.tsv (overwriting).
"""
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CACHE = Path("/tmp/biolean-06/dl2/ols2")
BASE = "https://www.ebi.ac.uk/ols4/api/v2/ontologies"
HAS_ROLE = "http://purl.obolibrary.org/obo/RO_0000087"


def get(url, cache):
    if cache.exists():
        return json.loads(cache.read_text())
    req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": "biolean-06"})
    with urllib.request.urlopen(req, timeout=60) as r:
        d = json.loads(r.read().decode())
    cache.write_text(json.dumps(d))
    return d


def entity(ont, curie):
    iri = "http://purl.obolibrary.org/obo/" + curie.replace(":", "_")
    enc = urllib.parse.quote(urllib.parse.quote(iri, safe=""), safe="")
    return get(f"{BASE}/{ont}/entities/{enc}", CACHE / f"{curie.replace(':', '_')}.json")


def roles(d):
    out = []
    refs = d.get("linkedEntities", {})
    for k in ("relatedTo", HAS_ROLE):
        pass
    for v in d.get(HAS_ROLE, []) if isinstance(d.get(HAS_ROLE), list) else ([d[HAS_ROLE]] if HAS_ROLE in d else []):
        iri = v if isinstance(v, str) else v.get("value")
        lab = refs.get(iri, {}).get("label", [""])
        out.append((iri.rsplit("/", 1)[-1].replace("_", ":"), lab[0] if isinstance(lab, list) else lab))
    # restrictions on subClassOf
    for sc in d.get("http://www.w3.org/2000/01/rdf-schema#subClassOf", []):
        if isinstance(sc, dict) and sc.get("http://www.w3.org/2002/07/owl#onProperty") == HAS_ROLE:
            iri = sc.get("http://www.w3.org/2002/07/owl#someValuesFrom")
            lab = refs.get(iri, {}).get("label", [""])
            out.append((iri.rsplit("/", 1)[-1].replace("_", ":"), lab[0] if isinstance(lab, list) else lab))
    return out


def main(argv):
    CACHE.mkdir(parents=True, exist_ok=True)
    write = "--write" in argv
    rows = []
    for c in [a for a in argv if a != "--write"]:
        d = entity("chebi", c)
        lab = d.get("label")
        lab = lab[0] if isinstance(lab, list) else lab
        for r in sorted(set(roles(d))):
            rows.append(f"{c}\t{lab}\thas_role\t{r[0]}\t{r[1]}")
            print(rows[-1])
    if write:
        (ROOT / "data/stress/06/chebi_roles.tsv").write_text(
            "drug\tdrug_label\trelation\trole\trole_label\n" + "".join(r + "\n" for r in rows))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
