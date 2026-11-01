"""Program 06: check references on Europe PMC (read-only).

  python3 -I scripts/stress/opposes_refs.py search "query"        # list hits: pmid, first author, year, title
  python3 -I scripts/stress/opposes_refs.py check PMID [PMID ...]   # fetch and record
  python3 -I scripts/stress/opposes_refs.py abstract PMID           # print the abstract
`check` writes to data/stress/06/references_checked.tsv (pmid, doi, first_author, year, journal,
title, pmcid, checked_on), replacing any earlier row for that PMID, so re-running it does not
duplicate rows. Responses cached in /tmp/biolean-06/dl2/epmc/ (untrusted data).
"""
import datetime
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CACHE = Path("/tmp/biolean-06/dl2/epmc")
OUT = ROOT / "data/stress/06/references_checked.tsv"
BASE = "https://www.ebi.ac.uk/europepmc/webservices/rest/search"


def get(params, name):
    p = CACHE / name
    if p.exists():
        return json.loads(p.read_text())
    url = BASE + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": "biolean-06"})
    with urllib.request.urlopen(req, timeout=60) as r:
        d = json.loads(r.read().decode())
    p.write_text(json.dumps(d))
    return d


def first_author(r):
    a = r.get("authorString", "")
    return a.split(",")[0].strip()


def search(q):
    d = get({"query": q, "format": "json", "pageSize": 12, "resultType": "lite"},
            "s_" + "".join(c if c.isalnum() else "_" for c in q)[:150] + ".json")
    for r in d.get("resultList", {}).get("result", []):
        print(f"{r.get('pmid')}\t{first_author(r)}\t{r.get('pubYear')}\t{r.get('journalTitle')}\t{r.get('title')}")


def fetch(pmid):
    d = get({"query": f"EXT_ID:{pmid} AND SRC:MED", "format": "json", "resultType": "core"}, f"p_{pmid}.json")
    res = d.get("resultList", {}).get("result", [])
    return res[0] if res else None


def check(pmids):
    head = "pmid\tdoi\tfirst_author\tyear\tjournal\ttitle\tpmcid\tchecked_on"
    rows = {}
    if OUT.exists():
        for line in OUT.read_text().splitlines()[1:]:
            if line.strip():
                rows[line.split("\t", 1)[0]] = line
    for p in pmids:
        r = fetch(p)
        if not r:
            print(p, "NOT FOUND")
            continue
        j = (r.get("journalInfo") or {}).get("journal", {}).get("title", r.get("journalTitle", ""))
        row = [p, r.get("doi", ""), first_author(r), str(r.get("pubYear")), j, r.get("title", ""), r.get("pmcid", ""),
               datetime.date.today().isoformat()]
        print("\t".join(row))
        rows[p] = "\t".join(row)
    OUT.write_text(head + "\n" + "".join(r + "\n" for r in rows.values()))


def abstract(p):
    r = fetch(p)
    print(r.get("title"))
    print(r.get("abstractText", "(no abstract)"))


def main(argv):
    CACHE.mkdir(parents=True, exist_ok=True)
    if argv[0] == "search":
        search(argv[1])
    elif argv[0] == "check":
        check(argv[1:])
    elif argv[0] == "abstract":
        abstract(argv[1])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
