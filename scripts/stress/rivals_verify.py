"""Check every identifier program 03 cites: PMIDs on Europe PMC, DOIs on Crossref, CURIEs on OLS4.

Collects identifiers from rivals_spec.py (items, notes, sources) and from the extra list below (the
doc's vocabulary). Raw answers are saved under /tmp/biolean-03/v3/dl/ (untrusted downloads); the
summary goes to data/stress/03/references_checked.tsv and curies_checked.tsv.

Usage (repo root): python3 -I scripts/stress/rivals_verify.py
"""
import csv, json, os, re, sys, time, urllib.error, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from rivals_spec import CASES, ENT

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
DATA = os.path.join(ROOT, "data", "stress", "03")
DL = "/tmp/biolean-03/v3/dl"
EXTRA_CURIES = ["ECO:0000034", "ECO:0000303", "SEPIO:0000101", "SEPIO:0000008", "SEPIO:0000432", "HP:0034345",
                "RO:0002150", "RO:0001000", "RO:0002162", "BFO:0000051", "BFO:0000066",
                "CHEBI:15378", "GO:0022904", "GO:0006119", "CHEBI:167574", "GO:0007631", "UBERON:0001898", "UBERON:0002162"]
EXTRA_DOIS = ["10.1007/978-3-319-42337-1", "10.1016/s0004-3702(02)00259-x", "10.23919/icif.2017.8009820",
              "10.1214/aoms/1177698950", "10.1109/34.55104", "10.1016/0004-3702(94)00041-x",
              "10.1080/19462166.2013.869766", "10.1016/s0004-3702(01)00071-6", "10.1016/j.artmed.2012.09.004",
              "10.1080/01621459.1995.10476572", "10.1038/s41586-024-07691-8", "10.1080/00033793600200111",
              "10.1017/s0022172400031879"]
EXTRA_PMIDS = ["20474956", "20475871", "26261718", "18583197"]


def get(url, name):
    path = os.path.join(DL, name)
    if os.path.exists(path):
        return json.load(open(path))
    req = urllib.request.Request(url, headers={"User-Agent": "BioLean-program03/0.1 (read-only check)"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                data = json.loads(r.read().decode())
            break
        except urllib.error.HTTPError as e:
            if e.code == 404 or attempt == 3: raise
            time.sleep(3 * (attempt + 1))
    json.dump(data, open(path, "w"))
    time.sleep(0.2)
    return data


def collect():
    text = json.dumps(CASES, default=str)
    pmids = {str(i["pmid"]) for c in CASES for v in c["variants"].values() if v[0] in ("rivalry", "stmt")
             for r in v[1] for i in r["ev"] if i["pmid"] > 100}
    pmids |= {str(i["pmid"]) for c in CASES if c.get("frame") for i in c["frame"]["items"] if i["pmid"] > 100}
    pmids |= set(re.findall(r"PMID (\d{5,9})", text)) | set(EXTRA_PMIDS)
    dois = {d.rstrip(").;,:").lower() for d in re.findall(r"doi:(10\.[^\s\"']+)", text, flags=re.I)} | set(EXTRA_DOIS)
    curies = {v[1] for v in ENT.values() if not v[1].startswith("BLN:")} | set(EXTRA_CURIES)
    return sorted(pmids, key=int), sorted(dois), sorted(curies)


def main():
    os.makedirs(DL, exist_ok=True)
    pmids, dois, curies = collect()
    rows = []
    for k in range(0, len(pmids), 40):
        batch = pmids[k:k + 40]
        q = "(" + " OR ".join(f"EXT_ID:{p}" for p in batch) + ") AND SRC:MED"
        url = "https://www.ebi.ac.uk/europepmc/webservices/rest/search?" + urllib.parse.urlencode(
            {"query": q, "format": "json", "resultType": "core", "pageSize": 100})
        res = get(url, f"epmc_{k}.json")
        found = {r["id"]: r for r in res.get("resultList", {}).get("result", [])}
        for p in batch:
            r = found.get(p)
            if not r:
                rows.append(["PMID", p, "", "", "", "NOT FOUND"]); continue
            first = (r.get("authorList", {}).get("author") or [{}])[0].get("fullName", r.get("authorString", "")[:30])
            types = "; ".join(r.get("pubTypeList", {}).get("pubType", []))
            flag = "Retracted Publication" if "Retracted Publication" in types else ""
            rows.append(["PMID", p, r.get("pubYear", ""), first, r.get("title", ""), "found" + (f"; {flag}" if flag else "")])
    for d in dois:
        try:
            m = get("https://api.crossref.org/works/" + urllib.parse.quote(d), "crossref_" + re.sub(r"[^A-Za-z0-9]", "_", d) + ".json")["message"]
            year = (m.get("issued", {}).get("date-parts") or [[""]])[0][0]
            first = (m.get("author") or [{}])[0]
            rows.append(["DOI", d, year, first.get("family", first.get("name", "")), (m.get("title") or [""])[0], "found"])
        except Exception as e:
            rows.append(["DOI", d, "", "", "", f"NOT FOUND ({type(e).__name__})"])
    crow = []
    for cu in curies:
        # Review stage: the search endpoint returned an unlabelled import for the BFO relations; ask
        # /terms, then /properties (RO and BFO relations live there), and prefer the defining ontology.
        hit = None
        for kind in ("terms", "properties"):
            url = f"https://www.ebi.ac.uk/ols4/api/{kind}?" + urllib.parse.urlencode({"obo_id": cu, "size": 50})
            try:
                found = get(url, f"ols_{kind}_" + cu.replace(":", "_") + ".json").get("_embedded", {}).get(kind, [])
            except Exception:
                found = []
            if found:
                hit = next((x for x in found if x.get("is_defining_ontology")), found[0])
                break
        crow.append([cu, hit.get("label", "") if hit else "", hit.get("ontology_name", "") if hit else "",
                     ("obsolete" if hit.get("is_obsolete") else "live") if hit else "NOT FOUND"])
    with open(os.path.join(DATA, "references_checked.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["type", "id", "year", "first author", "title", "status (checked 2026-10-30)"])
        w.writerows(rows)
    with open(os.path.join(DATA, "curies_checked.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["curie", "label", "ontology", "status (OLS4, 2026-10-30)"])
        w.writerows(crow)
    bad = [r for r in rows if not r[5].startswith("found")] + [c for c in crow if c[3] != "live"]
    print(f"{sum(r[0] == 'PMID' for r in rows)} PMIDs, {sum(r[0] == 'DOI' for r in rows)} DOIs, {len(crow)} CURIEs checked; {len(bad)} problems")
    for b in bad: print("  ", b)
    for r in rows:
        if "Retracted" in r[5]: print("   retracted:", r[1], r[3], r[2])


if __name__ == "__main__":
    main()
