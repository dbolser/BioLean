"""Second independent re-check of program 03's identifiers (review 2, 2026-10-31).

Collects every PMID, DOI and CURIE from the spec (scripts/stress/rivals_spec.py), the generated
Lean files and the doc, fetches each from its registry into a fresh cache, and writes one row per
identifier with what the registry says next to what the spec says, so a human can read the title
against the claim the spec makes for it.

  PMID   Europe PMC REST search (title, first author, year, journal, publication types)
  DOI    Crossref /works (title, first author family name, year)
  CURIE  OLS4 /api/terms?obo_id= (label in the defining ontology, obsolete flag); /api/properties for relations

Downloads: /tmp/biolean-03/review2/dl/ (untrusted data). Run with: python3 -I scripts/stress/rivals_recheck.py
Writes data/stress/03/recheck_refs.tsv and data/stress/03/recheck_curies.tsv only.
"""
import csv, hashlib, json, os, re, sys, time, urllib.error, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from rivals_spec import CASES, ENT

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
DATA = os.path.join(ROOT, "data", "stress", "03")
DL = "/tmp/biolean-03/review2/dl"
FILES = ["scripts/stress/rivals_spec.py", "BioLean/Stress/Rivals.lean", "BioLean/Proto/Multinomial.lean",
         "docs/programs/03-rivals-and-hypotheses.md", "data/stress/03/cases.tsv"]


def get(url, name):
    path = os.path.join(DL, name)
    if os.path.exists(path):
        return json.load(open(path))
    req = urllib.request.Request(url, headers={"User-Agent": "BioLean-program03-review2/0.1 (read-only check)"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                data = json.loads(r.read().decode())
            break
        except urllib.error.HTTPError as e:
            if e.code == 404:
                data = {"_status": 404}
                break
            if attempt == 3: raise
            time.sleep(3 * (attempt + 1))
    json.dump(data, open(path, "w"))
    time.sleep(0.15)
    return data


def spec_notes():
    """PMID -> (years, notes, cases) from every evidence item and source string of the spec."""
    out = {}
    def add(p, y, note, cid):
        d = out.setdefault(str(p), {"years": set(), "notes": [], "cases": set()})
        if y: d["years"].add(y)
        if note and note not in d["notes"]: d["notes"].append(note)
        d["cases"].add(cid)
    for c in CASES:
        for v in c["variants"].values():
            if v[0] in ("rivalry", "stmt"):
                for r in v[1]:
                    for e in r["ev"]:
                        if e["pmid"] > 100: add(e["pmid"], e["year"], e.get("note"), c["id"])
        for fr in [c.get("frame")] + [f for _, f in c.get("frames_extra", [])]:
            if fr:
                for i in fr["items"]:
                    if i["pmid"] > 100: add(i["pmid"], i["year"], i.get("note"), c["id"])
        for m in re.finditer(r"PMID (\d{5,9})", c.get("source", "")):
            add(m.group(1), None, "source: " + c["source"], c["id"])
    return out


def scan(pattern):
    found = {}
    for f in FILES:
        for m in re.finditer(pattern, open(os.path.join(ROOT, f)).read()):
            found.setdefault(m.group(1).rstrip(".,;:)"), set()).add(f.split("/")[-1])
    return found


def main():
    os.makedirs(DL, exist_ok=True)
    notes = spec_notes()
    for p, fs in scan(r"PMID[ :](\d{5,9})").items():
        notes.setdefault(p, {"years": set(), "notes": [], "cases": set()})["cases"].update(fs)
    for p, fs in scan(r"pmid := (\d{5,9})").items():
        notes.setdefault(p, {"years": set(), "notes": [], "cases": set()})["cases"].update(fs)
    rows = []
    pmids = sorted(notes, key=int)
    for k in range(0, len(pmids), 20):
        chunk = pmids[k:k + 20]
        q = "(" + " OR ".join(f"EXT_ID:{p}" for p in chunk) + ") AND SRC:MED"
        url = ("https://www.ebi.ac.uk/europepmc/webservices/rest/search?" +
               urllib.parse.urlencode({"query": q, "format": "json", "resultType": "core", "pageSize": 100}))
        name = "epmc_" + hashlib.sha1(" ".join(chunk).encode()).hexdigest()[:12] + ".json"
        res = {r.get("id"): r for r in get(url, name).get("resultList", {}).get("result", [])}
        for p in chunk:
            r = res.get(p)
            d = notes[p]
            if not r:
                rows.append(["PMID", p, "", "", "NOT FOUND", "", "", ";".join(sorted(map(str, d["years"]))),
                             " || ".join(d["notes"]), " ".join(sorted(d["cases"]))])
                continue
            auth = (r.get("authorList", {}).get("author") or [{}])[0]
            first = auth.get("lastName") or auth.get("collectiveName") or ""
            types = r.get("pubTypeList", {}).get("pubType", [])
            rows.append(["PMID", p, r.get("pubYear", ""), first, r.get("title", ""),
                         r.get("journalInfo", {}).get("journal", {}).get("medlineAbbreviation", ""),
                         "; ".join(types) if isinstance(types, list) else str(types),
                         ";".join(sorted(map(str, d["years"]))), " || ".join(d["notes"]), " ".join(sorted(d["cases"]))])
    dois = scan(r"doi:(10\.\d{4,9}/[^\s\"`|]+)")
    for doi, fs in sorted(dois.items()):
        j = get("https://api.crossref.org/works/" + urllib.parse.quote(doi), "cr_" + re.sub(r"[^A-Za-z0-9]", "_", doi) + ".json")
        if j.get("_status") == 404:
            rows.append(["DOI", doi, "", "", "NOT FOUND", "", "", "", "", " ".join(sorted(fs))]); continue
        m = j["message"]
        a = (m.get("author") or [{}])[0]
        yr = (m.get("issued", {}).get("date-parts") or [[None]])[0][0]
        rows.append(["DOI", doi, yr or "", a.get("family") or a.get("name", ""), (m.get("title") or [""])[0],
                     (m.get("container-title") or [""])[0], m.get("type", ""), "", "", " ".join(sorted(fs))])
    with open(os.path.join(DATA, "recheck_refs.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["type", "id", "registry year", "registry first author", "registry title", "journal",
                    "publication types", "spec years", "spec notes", "where"])
        w.writerows(rows)
    curies = {v[1]: v[2] for v in ENT.values() if not v[1].startswith("BLN:")}
    for c, fs in scan(r"\b((?:GO|CHEBI|CL|UBERON|NCBITaxon|PR|HP|RO|BFO|ECO|SEPIO|GENO):\d+)").items():
        curies.setdefault(c, "")
    crow = []
    for c in sorted(curies):
        j = get("https://www.ebi.ac.uk/ols4/api/terms?" + urllib.parse.urlencode({"obo_id": c}),
                "ols_" + c.replace(":", "_") + ".json")
        terms = j.get("_embedded", {}).get("terms", [])
        if not terms:   # relations (RO, BFO, SEPIO) are OLS4 properties, not terms
            j = get("https://www.ebi.ac.uk/ols4/api/properties?" + urllib.parse.urlencode({"obo_id": c}),
                    "olsprop_" + c.replace(":", "_") + ".json")
            terms = j.get("_embedded", {}).get("properties", [])
        prefix = c.split(":")[0].lower()
        defining = [t for t in terms if t.get("is_defining_ontology")] or [t for t in terms if t.get("ontology_name") == prefix] or terms
        if not defining:
            crow.append([c, "NOT FOUND", "", "", curies[c]]); continue
        t = defining[0]
        crow.append([c, t.get("label", ""), t.get("ontology_name", ""), "obsolete" if t.get("is_obsolete") else "live", curies[c]])
    with open(os.path.join(DATA, "recheck_curies.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["curie", "OLS4 label", "ontology", "status", "spec label"])
        w.writerows(crow)
    print(f"{sum(r[0] == 'PMID' for r in rows)} PMIDs ({sum(r[0] == 'PMID' and r[4] == 'NOT FOUND' for r in rows)} not found), "
          f"{sum(r[0] == 'DOI' for r in rows)} DOIs ({sum(r[0] == 'DOI' and r[4] == 'NOT FOUND' for r in rows)} not found), "
          f"{len(crow)} CURIEs ({sum(r[1] == 'NOT FOUND' for r in crow)} not found, {sum(r[3] == 'obsolete' for r in crow)} obsolete)")


if __name__ == "__main__":
    main()
