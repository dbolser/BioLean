"""Program 06, independent review: re-check every CURIE and paper the program uses, from fresh downloads.

  python3 -I scripts/stress/opposes_review.py curies   # OLS4: label and obsolete flag for every CURIE
  python3 -I scripts/stress/opposes_review.py refs     # Europe PMC and Crossref: title, first author, year

CURIEs are read from the doc, both Lean files and the program's tables; papers from the doc, both Lean
files and references_checked.tsv. Downloads are cached in /tmp/biolean-06/review/dl/ (untrusted data;
this script lives outside it). Writes data/stress/06/review_curies.tsv and review_refs.tsv, overwriting.
A Lean entity whose label differs from OLS4's is listed (a label is ours to choose; an id is not).
"""
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
D = ROOT / "data/stress/06"
CACHE = Path("/tmp/biolean-06/review/dl")
DOC = ROOT / "docs/programs/06-opposition.md"
LEAN = [ROOT / "BioLean/Stress/Opposition.lean", ROOT / "BioLean/Proto/Opposes.lean"]
TABLES = [D / f for f in ("cases.tsv", "b_pairs.tsv", "vocabularies.tsv", "chebi_roles.tsv")]
PRE = r"(?:GO|UBERON|CL|CHEBI|NCBITaxon|RO|PR|PATO|OBA|HP|BFO|MONDO|PO)"
RX_CURIE = re.compile(rf"(?<![A-Za-z0-9]){PRE}:[A-Z]*[0-9]+")
RX_E = re.compile(rf"\be_({PRE})_([A-Z]*[0-9]+)")
RX_ENT = re.compile(rf'⟨"({PRE}:[A-Z]*[0-9]+)", "([^"]+)"⟩')
ONT = {"GO": "go", "UBERON": "uberon", "CL": "cl", "CHEBI": "chebi", "NCBITaxon": "ncbitaxon", "RO": "ro",
       "PR": "pr", "PATO": "pato", "OBA": "oba", "HP": "hp", "BFO": "bfo", "MONDO": "mondo", "PO": "po"}


def get(url: str, name: str):
    p = CACHE / name
    if p.exists():
        return json.loads(p.read_text())
    req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": "biolean-06-review"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.loads(r.read().decode())
            p.write_text(json.dumps(d))
            return d
        except Exception as e:  # noqa: BLE001
            err = e
            time.sleep(2)
    raise err


def curies():
    texts = [DOC.read_text()] + [f.read_text() for f in LEAN] + [f.read_text() for f in TABLES if f.exists()]
    found = set()
    for t in texts:
        found.update(RX_CURIE.findall(t))
        found.update(f"{a}:{b}" for a, b in RX_E.findall(t))
    used_labels = {}
    for f in LEAN:
        for c, lab in RX_ENT.findall(f.read_text()):
            used_labels.setdefault(c, set()).add(lab)
    rows, bad = [], []
    for c in sorted(found):
        pre, num = c.split(":", 1)
        iri = f"http://purl.obolibrary.org/obo/{pre}_{num}"
        ont = ONT[pre]
        enc = urllib.parse.quote(urllib.parse.quote(iri, safe=""), safe="")
        # BFO relations (BFO:0000066 occurs in) are served by RO
        tries = [(ont, "properties"), (ont, "terms"), ("ro", "properties")] if pre in ("RO", "BFO") else [(ont, "terms")]
        d, status = None, "NOT FOUND"
        for o, k in tries:
            try:
                d = get(f"https://www.ebi.ac.uk/ols4/api/ontologies/{o}/{k}/{enc}", f"ols_{o}_{k}_{c.replace(':', '_')}.json")
                status = "ok"
                break
            except Exception as e:  # noqa: BLE001
                status = f"ERROR {e}"
        label = (d or {}).get("label", "")
        obsolete = str((d or {}).get("is_obsolete", ""))
        ours = "; ".join(sorted(used_labels.get(c, [])))
        note = ""
        if status != "ok":
            note = status
        elif obsolete == "True":
            note = "OBSOLETE"
        elif ours and label.lower() not in {x.lower() for x in used_labels[c]}:
            note = "label differs"
        rows.append((c, label, obsolete, ours, note))
        if note and note != "label differs":
            bad.append((c, note))
    with open(D / "review_curies.tsv", "w") as f:
        f.write("curie\tols4_label\tobsolete\tlabel_in_lean\tnote\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    print(f"{len(rows)} CURIEs; problems: {bad}")
    for r in rows:
        if r[4]:
            print("\t".join(r))


def epmc(pmid: str):
    d = get("https://www.ebi.ac.uk/europepmc/webservices/rest/search?" + urllib.parse.urlencode(
        {"query": f"EXT_ID:{pmid} AND SRC:MED", "format": "json", "resultType": "core"}), f"epmc_{pmid}.json")
    res = d.get("resultList", {}).get("result", [])
    return res[0] if res else None


def crossref(doi: str):
    try:
        d = get(f"https://api.crossref.org/works/{urllib.parse.quote(doi)}", "cr_" + re.sub(r"\W", "_", doi) + ".json")
    except Exception as e:  # noqa: BLE001
        return None, str(e)
    m = d.get("message", {})
    au = (m.get("author") or [{}])[0]
    yr = ((m.get("issued") or {}).get("date-parts") or [[None]])[0][0]
    return (m.get("title") or [""])[0], f"{au.get('family', '')}|{yr}"


def refs():
    pm = set()
    for t in [DOC.read_text()] + [f.read_text() for f in LEAN]:
        pm.update(re.findall(r"PMID[: ]+(\d{5,9})", t))
        pm.update(re.findall(r"paper (\d{5,9}) ", t))
        pm.update(re.findall(r"^\| (\d{5,9}) \|", t, re.M))
    rec = {}
    for line in (D / "references_checked.tsv").read_text().splitlines()[1:]:
        x = line.split("\t")
        rec[x[0]] = x
        pm.add(x[0])
    rows = []
    for p in sorted(pm, key=int):
        r = epmc(p)
        if not r:
            rows.append((p, "", "", "", "", "", "NOT FOUND on Europe PMC"))
            continue
        fa = (r.get("authorString", "").split(",")[0]).strip()
        yr = str(r.get("pubYear", ""))
        title = r.get("title", "")
        doi = r.get("doi", "")
        note = []
        if p in rec:
            if rec[p][2].rstrip(".") != fa.rstrip("."):
                note.append(f"first author recorded {rec[p][2]!r}")
            if rec[p][3] != yr:
                note.append(f"year recorded {rec[p][3]}")
            if rec[p][5].rstrip(".") != title.rstrip("."):
                note.append("title differs from record")
        else:
            note.append("not in references_checked.tsv")
        cr = ""
        if doi:
            t, ay = crossref(doi)
            cr = ay if t is not None else f"crossref error {ay}"
        rows.append((p, doi, fa, yr, title, cr, "; ".join(note)))
    with open(D / "review_refs.tsv", "w") as f:
        f.write("pmid\tdoi\tfirst_author_epmc\tyear_epmc\ttitle_epmc\tcrossref_first_family|year\tnote\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    for r in rows:
        print("\t".join(r))


def main(argv):
    CACHE.mkdir(parents=True, exist_ok=True)
    {"curies": curies, "refs": refs}[argv[0]]()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
