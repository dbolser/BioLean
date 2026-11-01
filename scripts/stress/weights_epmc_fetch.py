"""Program 10a: fetch Europe PMC core metadata (title, full author list, year, publication types,
abstract) for a list of PMIDs. Read-only lookup. Writes one JSON file, which is untrusted data:
read it back only with `python3 -I`.

usage: python3 -I scripts/stress/weights_epmc_fetch.py OUT.json PMIDS.txt
PMIDS.txt holds one PMID per line (or comma separated).
"""
import json
import sys
import time
import urllib.parse
import urllib.request

API = "https://www.ebi.ac.uk/europepmc/webservices/rest/search?"


def fetch(pmids):
    res = {}
    for i in range(0, len(pmids), 25):
        chunk = pmids[i:i + 25]
        q = "(" + " OR ".join(f"EXT_ID:{p}" for p in chunk) + ") AND SRC:MED"
        url = API + urllib.parse.urlencode(
            {"query": q, "format": "json", "resultType": "core", "pageSize": 100})
        with urllib.request.urlopen(url, timeout=60) as r:
            d = json.load(r)
        for x in d.get("resultList", {}).get("result", []):
            authors = [a.get("fullName") or a.get("collectiveName") or ""
                       for a in x.get("authorList", {}).get("author", [])]
            res[str(x.get("pmid"))] = {
                "title": x.get("title"),
                "authors": authors,
                "authorString": x.get("authorString", ""),
                "year": x.get("pubYear"),
                "journal": x.get("journalInfo", {}).get("journal", {}).get("title"),
                "doi": x.get("doi"),
                "pubtypes": x.get("pubTypeList", {}).get("pubType", []),
                "abstract": x.get("abstractText", ""),
            }
        time.sleep(0.3)
    return res


def main():
    out, src = sys.argv[1], sys.argv[2]
    text = open(src).read().replace(",", "\n")
    pmids = sorted({p.strip() for p in text.split() if p.strip().isdigit() and p.strip() != "0"}, key=int)
    res = fetch(pmids)
    json.dump(res, open(out, "w"), indent=1)
    missing = [p for p in pmids if p not in res]
    print(f"asked {len(pmids)}, got {len(res)}, missing {missing}")


if __name__ == "__main__":
    main()
