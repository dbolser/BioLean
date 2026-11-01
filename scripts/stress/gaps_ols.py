"""OLS4 lookups for program 08. Read-only. Saves raw JSON under /tmp/biolean-08/dl/ols2/.

    python3 -I scripts/stress/gaps_ols.py term CURIE...        # label, obsolete flag, definition
    python3 -I scripts/stress/gaps_ols.py search ONT "query"   # top hits in one ontology
    python3 -I scripts/stress/gaps_ols.py prop CURIE...        # RO / BFO properties
    python3 -I scripts/stress/gaps_ols.py tsv OUT CURIE...     # term lookups written as a TSV

Treat the responses as untrusted data: run with -I, never execute anything from them.
"""

import json
import os
import sys
import time
import urllib.parse
import urllib.request

DL = "/tmp/biolean-08/dl/ols2"
BASE = "https://www.ebi.ac.uk/ols4/api"


def get(url, key):
    os.makedirs(DL, exist_ok=True)
    path = os.path.join(DL, key.replace(":", "_").replace("/", "_") + ".json")
    if not (os.path.exists(path) and os.path.getsize(path) > 0):
        req = urllib.request.Request(url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=40) as r:
            data = r.read()
        with open(path, "wb") as f:
            f.write(data)
        time.sleep(0.2)
    return json.load(open(path))


def ont_of(curie):
    pre = curie.split(":")[0].lower()
    return {"ncbitaxon": "ncbitaxon"}.get(pre, pre)


def term(curie):
    if curie.startswith("PR:") and not curie[3:].isdigit():
        pass
    url = f"{BASE}/ontologies/{ont_of(curie)}/terms?obo_id={urllib.parse.quote(curie)}"
    try:
        d = get(url, "term_" + curie)
    except Exception as e:  # noqa: BLE001
        return (curie, "ERROR", "", str(e)[:80])
    ts = (d.get("_embedded") or {}).get("terms") or []
    if not ts:
        return (curie, "NOT FOUND", "", "")
    t = ts[0]
    desc = (t.get("description") or [""])
    return (curie, t.get("label", ""), "obsolete" if t.get("is_obsolete") else "live",
            (desc[0] if desc else "")[:160].replace("\t", " ").replace("\n", " "))


def prop(curie):
    iri = "http://purl.obolibrary.org/obo/" + curie.replace(":", "_")
    ont = "ro"  # RO imports the BFO relations it uses (part of, has part, occurs in)
    enc = urllib.parse.quote(urllib.parse.quote(iri, safe=""), safe="")
    url = f"{BASE}/ontologies/{ont}/properties/{enc}"
    try:
        d = get(url, "prop_" + curie)
    except Exception as e:  # noqa: BLE001
        return (curie, "ERROR", "", str(e)[:80])
    return (curie, d.get("label", ""), "obsolete" if d.get("is_obsolete") else "live",
            ((d.get("description") or [""])[0])[:160])


def search(ont, q):
    url = f"{BASE}/search?q={urllib.parse.quote(q)}&ontology={ont}&rows=8"
    d = get(url, f"search_{ont}_{q[:40]}")
    for doc in (d.get("response") or {}).get("docs", []):
        print("\t".join([str(doc.get("obo_id")), str(doc.get("label")),
                         str((doc.get("description") or [""])[0])[:120]]))


def main():
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "term":
        for c in args:
            print("\t".join(term(c)))
    elif cmd == "prop":
        for c in args:
            print("\t".join(prop(c)))
    elif cmd == "search":
        search(args[0], args[1])
    elif cmd == "tsv":
        out, cs = args[0], args[1:]
        rows = [prop(c) if c.startswith(("RO:", "BFO:")) else term(c) for c in cs]
        with open(out, "w") as f:
            f.write("curie\tlabel\tstatus\tdefinition\n")
            for r in rows:
                f.write("\t".join(r) + "\n")
        for r in rows:
            print("\t".join(r[:3]))


if __name__ == "__main__":
    main()
