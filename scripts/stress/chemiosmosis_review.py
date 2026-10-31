"""Program 09, independent review: re-check every citation, CURIE and quote from scratch.

Unlike chemiosmosis_verify.py, chemiosmosis_ols.py and chemiosmosis_quotes.py, this script uses a
fresh, empty download directory (/tmp/biolean-09/review/fresh/), so nothing cached by an earlier
run is trusted. It also checks more:

* every PMID cited anywhere in the doc, cases.tsv, record.tsv or the Lean file, on Europe PMC:
  year, first author surname, and the FULL normalised title (not only its first 40 characters);
* every DOI in record.tsv's doi column and in the doc, on Crossref: year, first author, title;
* every CURIE in the doc, cases.tsv, record.tsv and the Lean file, on OLS4: found, not obsolete,
  and the OLS4 label against the label the Lean file gives it;
* every single-quoted phrase of three or more words in cases.tsv's `correct` and `observed`
  columns, against the abstracts of that case's sources (and the 1978 Nobel speech).

Writes data/stress/09/review_checks.tsv. Downloads are untrusted: run with `python3 -I`.

    python3 -I scripts/stress/chemiosmosis_review.py <repo root> [download folder]
"""
import csv
import html
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
# A second argument gives a fresh download folder (the build re-check of 2026-10-31 used
# /tmp/biolean-09/build4/fresh), so nothing cached earlier is trusted.
DL = sys.argv[2] if len(sys.argv) > 2 else "/tmp/biolean-09/review/fresh"
OUT = os.path.join(ROOT, "data/stress/09/review_checks.tsv")
DOC = os.path.join(ROOT, "docs/programs/09-chemiosmosis-real-record.md")
LEAN = os.path.join(ROOT, "BioLean/Stress/ChemiosmosisReal.lean")
CASES = os.path.join(ROOT, "data/stress/09/cases.tsv")
RECORD = os.path.join(ROOT, "data/stress/09/record.tsv")
SPEECH_URL = "https://www.nobelprize.org/prizes/chemistry/1978/ceremony-speech/"
UA = {"User-Agent": "BioLean-stress-09-review (read-only lookup)"}
# Crossref titles that differ from Europe PMC's only in formatting or a Crossref typo (read by eye).
CROSSREF_FORMAT = {
    "10.1016/0003-9861(64)90276-0": "Crossref has 'related to', PubMed 'related'",
    "10.1016/0304-4173(74)90011-1": "Crossref 'electromechanical', PubMed 'electromechanochemical' (Green's term)",
    "10.1038/370621a0": "Crossref mis-encodes the angstrom sign",
    "10.1104/pp.90.4.1513": "Crossref keeps 'Ca<sup>2+</sup>', PubMed 'Ca'",
}
# Single-quoted phrases in cases.tsv that are not quotations of a source.
NOT_QUOTES = {"m is_a C~I", "localised with 5 mM CaCl2, delocalised with 100 mM KCl",
              "phospho-L-histidine is_a C~I"}

# Expected (year, first author surname, title) for PMIDs cited but not in record.tsv.
HISTORIES = {
    "11536297": ("2001", "Harold", "Gleanings of a chemiosmotic eye"),
    "8842371": ("1996", "Prebble", "Successful theory development in biology"),
    "11859886": ("2001", "Prebble", "The philosophical origins of Mitchell's chemiosmotic concepts"),
    "11943549": ("2002", "Prebble", "Peter Mitchell and the ox phos wars"),
    "12068893": ("2002", "Allchin", "To err and win a Nobel Prize"),
    "23104597": ("2013", "Prebble", "Contrasting approaches to a biological problem"),
    "22082452": ("2011", "Mitchell", "Chemiosmotic coupling in oxidative and photosynthetic phosphorylation"),
    "18846415": ("2008", "Rich", "A perspective on Peter Mitchell and the chemiosmotic theory"),
    "4291593": ("1967", "Mitchell", "Chemiosmotic hypothesis of oxidative phosphorylation"),
    # E1 lead added by the review (2026-10-31): cites Tager et al. 1966; free scan in PMC (PMC223899)
    "4170459": ("1967", "van Dam", "A suggested mechanism of uncoupling of respiratory-chain phosphorylation"),
}
# DOIs cited in the doc but not in record.tsv: (year, first author surname, title start).
DOC_DOIS = {
    "10.1207/s15516709cog1104_4": ("1987", "Pollock", "Defeasible Reasoning"),
    "10.1016/0004-3702(94)00041-X": ("1995", "Dung", "On the acceptability of arguments"),
    "10.1007/978-3-319-42337-1": ("2016", "Jøsang", "Subjective Logic"),
}


def norm(s):
    s = html.unescape(re.sub("<[^>]+>", "", s)).lower()
    s = s.replace("ø", "o").replace("å", "a").replace("ö", "o")
    return re.sub(r"[^a-z0-9]", "", s)


def get(url, path, tries=3):
    if not os.path.exists(path):
        err = ""
        for i in range(tries):
            req = urllib.request.Request(url, headers=UA)
            try:
                raw = urllib.request.urlopen(req, timeout=90).read()
                break
            except Exception as e:  # noqa: BLE001 - retry, then record the failure
                err = str(e)
                time.sleep(2 * (i + 1))
        else:
            return None, err
        with open(path, "wb") as f:
            f.write(raw)
        time.sleep(0.15)
    with open(path, "rb") as f:
        return f.read(), ""


def epmc(pmid):
    url = ("https://www.ebi.ac.uk/europepmc/webservices/rest/search?" + urllib.parse.urlencode(
        {"query": f"EXT_ID:{pmid} AND SRC:MED", "format": "json", "resultType": "core"}))
    raw, err = get(url, os.path.join(DL, f"epmc_{pmid}.json"))
    if raw is None:
        return None
    rs = json.loads(raw).get("resultList", {}).get("result", [])
    return rs[0] if rs else None


def crossref(doi):
    url = "https://api.crossref.org/works/" + urllib.parse.quote(doi)
    raw, err = get(url, os.path.join(DL, "cr_" + re.sub(r"[^A-Za-z0-9]", "_", doi) + ".json"))
    if raw is None:
        return None
    return json.loads(raw).get("message")


def ols(curie):
    for kind in ("terms", "properties"):
        url = f"https://www.ebi.ac.uk/ols4/api/{kind}?" + urllib.parse.urlencode({"obo_id": curie})
        raw, err = get(url, os.path.join(DL, f"ols_{kind}_" + curie.replace(":", "_") + ".json"))
        if raw is None:
            return {"label": "", "is_obsolete": False, "ontology_name": "FETCH FAILED: " + err[:60]}
        ts = json.loads(raw).get("_embedded", {}).get(kind, [])
        if ts:
            d = [t for t in ts if t.get("is_defining_ontology")] or ts
            return d[0]
    return None


def surname(a):
    parts = a.split()
    return " ".join(parts[:-1]) if len(parts) > 1 and parts[-1].isupper() else a


def title_status(want, got):
    w, g = norm(want), norm(got)
    if w == g:
        return "exact"
    if g.startswith(w) or w.startswith(g):
        return "prefix"
    return "DIFFERENT"


def main():
    os.makedirs(DL, exist_ok=True)
    rows = []
    record = list(csv.DictReader(open(RECORD), delimiter="\t"))
    expected = {r["pmid"]: (r["year"], surname(r["first_author"]), r["title"], r["key"])
                for r in record if r["pmid"] not in ("", "0")}
    for p, (y, a, t) in HISTORIES.items():
        expected.setdefault(p, (y, a, t, "history"))
    texts = {p: open(p).read() for p in (DOC, LEAN, CASES)}
    cited = set()
    for t in texts.values():
        cited |= set(re.findall(r"PMID[: ]+(\d+)", t))
    cited.discard("0")
    abstracts = {}
    has_abstract = {}  # fixed at build 2026-10-31: the flag used to test abstract + title, so was always 'y'
    for p in sorted(cited | set(expected), key=int):
        r = epmc(p)
        if p not in expected:
            rows.append(["pmid", p, "", "", "", "", "NO EXPECTED VALUE (cited, not in record)"])
            continue
        y, a, t, key = expected[p]
        if r is None:
            rows.append(["pmid", p, key, f"{a} {y}", "", "", "NOT FOUND"])
            continue
        abstracts[p] = (r.get("abstractText", "") or "") + " " + r.get("title", "")
        has_abstract[p] = bool((r.get("abstractText", "") or "").strip())
        gy = str(r.get("pubYear", ""))
        au = (r.get("authorList", {}).get("author") or [{}])[0]
        ga = au.get("lastName", au.get("fullName", au.get("collectiveName", "")))
        gt = re.sub("<[^>]+>", "", r.get("title", ""))
        ts = title_status(t, gt) if key != "history" else ("prefix" if norm(gt).startswith(norm(t)) else "DIFFERENT")
        ok = gy == y and norm(ga) == norm(a) and ts != "DIFFERENT"
        rows.append(["pmid", p, key, f"{a} {y}", f"{ga} {gy}", gt[:120],
                     ("OK" if ok else "MISMATCH") + f" (title {ts}; abstract {'y' if has_abstract[p] else 'n'})"])
    # DOIs
    dois = {r["doi"]: (r["year"], surname(r["first_author"]), r["title"], r["key"]) for r in record if r["doi"]}
    for d, (y, a, t) in DOC_DOIS.items():
        dois.setdefault(d, (y, a, t, "doc"))
    for d, (y, a, t, key) in sorted(dois.items()):
        m = crossref(d)
        if m is None:
            rows.append(["doi", d, key, f"{a} {y}", "", "", "NOT FOUND (Crossref)"])
            continue
        gy = str(((m.get("issued", {}).get("date-parts") or [[""]])[0] or [""])[0])
        au = (m.get("author") or [{}])[0]
        ga = au.get("family", au.get("name", ""))
        gt = (m.get("title") or [""])[0]
        ts = title_status(t, gt)
        if key == "doc":
            ts = "prefix" if norm(gt).startswith(norm(t)) else "DIFFERENT"
        ok_year = gy == y
        ok = ok_year and norm(ga) == norm(a) and ts != "DIFFERENT"
        status = ("OK" if ok else "MISMATCH") + f" (title {ts})"
        if not ok and ok_year and norm(ga) == norm(a) and d in CROSSREF_FORMAT:
            status = "OK (title formatting: " + CROSSREF_FORMAT[d] + ")"
        rows.append(["doi", d, key, f"{a} {y}", f"{ga} {gy}", gt[:120], status])
    # CURIEs: label the Lean file gives each (if any)
    lean_labels = dict(re.findall(r'⟨"([A-Za-z]+:\d+)", "([^"]*)"⟩', texts[LEAN]))
    curies = set()
    for path in (DOC, LEAN, CASES, RECORD, os.path.join(ROOT, "data/stress/09/curies_checked.tsv")):
        curies |= set(re.findall(r"\b((?:GO|CHEBI|NCBITaxon|RO|SEPIO|UBERON|CL|PR|ECO|BFO):\d+)", open(path).read()))
    for c in sorted(curies):
        t = ols(c)
        if t is None or t.get("ontology_name", "").startswith("FETCH FAILED"):
            rows.append(["curie", c, (t or {}).get("ontology_name", ""), lean_labels.get(c, ""), "", "",
                         "FETCH FAILED" if t else "NOT FOUND"])
            continue
        lab = t.get("label", "")
        obs = t.get("is_obsolete", False)
        ll = lean_labels.get(c, "")
        lab_ok = (not ll) or norm(ll) == norm(lab)
        rows.append(["curie", c, t.get("ontology_name", ""), ll, lab, "",
                     ("OBSOLETE" if obs else "OK") + ("" if lab_ok else " (Lean label differs)")])
    # quotes in cases.tsv
    raw, err = get(SPEECH_URL, os.path.join(DL, "nobel_speech.html"))
    speech = re.sub(r"\s+", " ", html.unescape(re.sub("<[^>]+>", " ", raw.decode("utf-8", "replace")))).lower() if raw else ""
    for r in csv.DictReader(open(CASES), delimiter="\t"):
        pm = re.findall(r"PMID:(\d+)", r["source"])
        pool = " ".join(re.sub(r"\s+", " ", html.unescape(re.sub("<[^>]+>", " ", abstracts.get(p, "")))).lower() for p in pm)
        if "nobelprize" in r["source"]:
            pool += " " + speech
        for col in ("correct", "observed"):
            for q in re.findall(r"(?<![A-Za-z])'([^']{8,}?)'(?![A-Za-z])", r[col]):
                if len(q.split()) < 3 or q in NOT_QUOTES:
                    continue
                qn = re.sub(r"\s+", " ", q).lower()
                parts = [x.strip() for x in qn.split("...") if x.strip()]
                found = all(x in pool for x in parts)
                rows.append(["quote", r["id"], col, q[:100], "", "", "FOUND" if found else "NOT FOUND in case sources"])
    # the three OpenStax sentences the stress set quotes, against the textbook source
    src = open(os.path.join(ROOT, "data/textbook/source/how-cells-obtain-energy.json")).read()
    for sid, sent in [("how-cells-obtain-energy-m45439-73",
                       "This flow of hydrogen ions across the membrane through ATP synthase is called chemiosmosis"),
                      ("how-cells-obtain-energy-m45439-37", "The potential energy of this gradient is used to generate ATP"),
                      ("how-cells-obtain-energy-m45439-36",
                       "used to generate an electrochemical gradient across the inner mitochondrial membrane")]:
        rows.append(["textbook", sid, "", sent, "", "", "FOUND" if sent in src else "NOT FOUND in data/textbook/source"])
    with open(OUT, "w", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["what", "id", "key_or_ontology", "expected", "got", "got_title", "status"])
        w.writerows(rows)
    bad = [r for r in rows if not (r[6].startswith("OK") or r[6] == "FOUND")]
    by = {}
    for r in rows:
        by.setdefault(r[0], [0, 0])
        by[r[0]][0] += 1
        by[r[0]][1] += r in bad
    print({k: f"{v[0] - v[1]} of {v[0]} OK" for k, v in by.items()})
    for r in bad:
        print("  ", r)


if __name__ == "__main__":
    main()
