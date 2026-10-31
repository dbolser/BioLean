"""Independent re-check of program 03's identifiers (review stage, 2026-10-30).

Unlike rivals_verify.py (which only checks that an identifier exists), this compares what the spec
says about each identifier with what the registry says:
  PMID  Europe PMC: publication year against the item year; first author's surname against the first
        name in the spec note (when the note starts with one).
  DOI   Crossref: year and first author's family name, with the title for a human check.
  CURIE OLS4 /api/terms?obo_id=...: the label in the defining ontology against the spec's label.

Downloads go to a fresh cache, /tmp/biolean-03/review/dl/ (untrusted; not the build stage's cache).
Writes data/stress/03/review_refs.tsv and data/stress/03/review_curies.tsv.

Usage (repo root): python3 -I scripts/stress/rivals_review_verify.py
"""
import csv, json, os, re, sys, time, unicodedata, urllib.error, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from rivals_spec import CASES, ENT
from rivals_verify import EXTRA_CURIES, EXTRA_DOIS, EXTRA_PMIDS

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
DATA = os.path.join(ROOT, "data", "stress", "03")
DL = "/tmp/biolean-03/review/dl"


def get(url, name):
    path = os.path.join(DL, name)
    if os.path.exists(path):
        return json.load(open(path))
    req = urllib.request.Request(url, headers={"User-Agent": "BioLean-program03-review/0.1 (read-only check)"})
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


def fold(s):
    return "".join(c for c in unicodedata.normalize("NFKD", s or "") if not unicodedata.combining(c)).lower()


def items():
    """Every evidence item of the spec, current-core and frame, with its case."""
    for c in CASES:
        for v in c["variants"].values():
            if v[0] in ("rivalry", "stmt"):
                for r in v[1]:
                    for e in r["ev"]: yield c["id"], e
        fr = c.get("frame")
        if fr:
            for i in fr["items"]: yield c["id"], i


def expected():
    """PMID -> {years, surname, cases}. The surname is the first word of the first note that starts
    with a capitalised name (not a textbook id, not 'generation')."""
    out = {}
    for cid, e in items():
        p = e["pmid"]
        if p <= 100: continue
        d = out.setdefault(str(p), {"years": set(), "surname": None, "cases": set(), "note": ""})
        d["years"].add(e["year"]); d["cases"].add(cid)
        m = re.match(r"([A-Z][A-Za-zÀ-ſ'\-]+)", e.get("note") or "")
        if m and not d["surname"] and m.group(1) not in ("Generation", "The", "A"):
            d["surname"] = m.group(1); d["note"] = e["note"]
    # PMIDs named in a case's source text: "Name ... YEAR ... (PMID n)"
    for c in CASES:
        for m in re.finditer(r"([A-Z][A-Za-zÀ-ſ'\-]+)[^();]*?(\d{4})[^();]*?\(PMID (\d{5,9})\)", c.get("source", "")):
            d = out.setdefault(m.group(3), {"years": set(), "surname": None, "cases": set(), "note": ""})
            d["cases"].add(c["id"])
            if not d["years"]: d["years"].add(int(m.group(2)))
            if not d["surname"]: d["surname"] = m.group(1); d["note"] = "source: " + m.group(0)[:80]
    for p in EXTRA_PMIDS:
        out.setdefault(p, {"years": set(), "surname": None, "cases": {"doc"}, "note": ""})
    return out


def main():
    os.makedirs(DL, exist_ok=True)
    exp = expected()
    pmids = sorted(exp, key=int)
    rows = []
    for k in range(0, len(pmids), 40):
        batch = pmids[k:k + 40]
        q = "(" + " OR ".join(f"EXT_ID:{p}" for p in batch) + ") AND SRC:MED"
        url = "https://www.ebi.ac.uk/europepmc/webservices/rest/search?" + urllib.parse.urlencode(
            {"query": q, "format": "json", "resultType": "core", "pageSize": 100})
        found = {r["id"]: r for r in get(url, f"epmc_{k}.json").get("resultList", {}).get("result", [])}
        for p in batch:
            d, r = exp[p], found.get(p)
            if not r:
                rows.append(["PMID", p, "", "", "", "NOT FOUND", ",".join(sorted(d["cases"]))]); continue
            authors = r.get("authorList", {}).get("author") or []
            first = authors[0] if authors else {}
            last = first.get("lastName") or first.get("collectiveName") or (r.get("authorString", "").split(" ")[0])
            year = int(r.get("pubYear") or 0)
            checks = []
            if d["years"]:
                checks.append("year ok" if year in d["years"] else f"YEAR {year} vs spec {sorted(d['years'])}")
            if d["surname"]:
                sur = fold(d["surname"])
                ok = sur in fold(last) or fold(last) in sur or sur in fold(r.get("authorString", "").split(",")[0])
                checks.append("author ok" if ok else f"AUTHOR {last} vs spec {d['surname']}")
            types = "; ".join(r.get("pubTypeList", {}).get("pubType", []))
            if "Retracted Publication" in types: checks.append("RETRACTED")
            rows.append(["PMID", p, year, last, r.get("title", ""), "; ".join(checks) or "found", ",".join(sorted(d["cases"]))])
    text = json.dumps(CASES, default=str)
    dois = sorted({d.rstrip(").;,:").lower() for d in re.findall(r"doi:(10\.[^\s\"']+)", text, flags=re.I)} | set(EXTRA_DOIS))
    for d in dois:
        try:
            m = get("https://api.crossref.org/works/" + urllib.parse.quote(d), "crossref_" + re.sub(r"[^A-Za-z0-9]", "_", d) + ".json")["message"]
            year = (m.get("issued", {}).get("date-parts") or [[""]])[0][0]
            first = (m.get("author") or [{}])[0]
            rows.append(["DOI", d, year, first.get("family", first.get("name", "")), (m.get("title") or [""])[0], "found", ""])
        except Exception as e:
            rows.append(["DOI", d, "", "", "", f"NOT FOUND ({type(e).__name__})", ""])
    labels = {v[1]: v[2] for v in ENT.values()}
    crow = []
    curies = sorted({v[1] for v in ENT.values() if not v[1].startswith("BLN:")} | set(EXTRA_CURIES))
    for cu in curies:
        url = "https://www.ebi.ac.uk/ols4/api/terms?" + urllib.parse.urlencode({"obo_id": cu, "size": 50})
        try:
            terms = get(url, "olsterms_" + cu.replace(":", "_") + ".json").get("_embedded", {}).get("terms", [])
        except Exception as e:
            terms = []
        if not terms:   # properties (RO, BFO relations) are served under /properties
            url = "https://www.ebi.ac.uk/ols4/api/properties?" + urllib.parse.urlencode({"obo_id": cu, "size": 50})
            try:
                terms = get(url, "olsprops_" + cu.replace(":", "_") + ".json").get("_embedded", {}).get("properties", [])
            except Exception:
                terms = []
        defining = [t for t in terms if t.get("is_defining_ontology")] or terms
        t = defining[0] if defining else {}
        lab = t.get("label", "")
        want = labels.get(cu, "")
        ok = (not want) or fold(want).split(" (")[0] in fold(lab) or fold(lab) in fold(want)
        crow.append([cu, lab, t.get("ontology_name", ""), "obsolete" if t.get("is_obsolete") else ("live" if t else "NOT FOUND"),
                     want, "label ok" if ok else "LABEL DIFFERS", ",".join(sorted({x.get("ontology_name", "") for x in terms}))])
    with open(os.path.join(DATA, "review_refs.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["type", "id", "year", "first author", "title", "checks (review, 2026-10-30)", "cases"])
        w.writerows(rows)
    with open(os.path.join(DATA, "review_curies.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["curie", "OLS4 label", "defining ontology", "status", "spec label", "check", "all ontologies"])
        w.writerows(crow)
    np = sum(r[0] == "PMID" for r in rows)
    na = sum(1 for r in rows if r[0] == "PMID" and "author ok" in r[5])
    ny = sum(1 for r in rows if r[0] == "PMID" and "year ok" in r[5])
    print(f"{np} PMIDs: {ny} year ok, {na} author ok; {sum(r[0] == 'DOI' for r in rows)} DOIs; {len(crow)} CURIEs")
    for r in rows:
        if any(x in r[5] for x in ("YEAR", "AUTHOR", "NOT FOUND", "RETRACTED")): print("  ", r[:4], r[5], r[6])
    for c in crow:
        if c[3] != "live" or c[5] != "label ok": print("  ", c)


if __name__ == "__main__":
    main()
