"""Program 05 review: an independent OLS4 check of every CURIE in the program's files.

Unlike grade_ols.py (a hand list), this reads every CURIE out of the doc, both Lean files and
cases.tsv, and every `⟨"curie", "label"⟩` pair in the Lean files, then looks each up on OLS4 api/v2
in a fresh download directory. Labels written in Lean must match OLS4 (case-insensitive, NCBI's
`<common name>` suffix ignored). Downloads go to /tmp/biolean-05/review/ols/ (untrusted data).
Writes data/stress/05/curies_review.tsv. Run with `python3 -I scripts/stress/grade_review_ols.py`.
"""
import concurrent.futures
import json
import pathlib
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/05"
DL = pathlib.Path("/tmp/biolean-05/review/ols")
DL.mkdir(parents=True, exist_ok=True)
API = "https://www.ebi.ac.uk/ols4/api/v2"
FILES = ["docs/programs/05-grade-terms.md", "BioLean/Stress/GradeTerms.lean", "BioLean/Proto/TaxonUnion.lean",
         "data/stress/05/cases.tsv"]
ONTO = {"NCBITaxon": "ncbitaxon", "NCBITaxon_Union": "go", "GO": "go", "CL": "cl", "CHEBI": "chebi",
        "UBERON": "uberon", "PR": "pr", "SO": "so", "RO": "ro", "BFO": "ro", "NCIT": "ncit", "ECOCORE": "ecocore",
        "PO": "po"}
CURIE = re.compile(r"\b(NCBITaxon_Union|NCBITaxon|GO|CL|CHEBI|UBERON|PR|SO|RO|BFO|NCIT|ECOCORE|PO):([0-9]+|C[0-9]+)\b")
LIBREF = re.compile(r"\be_(NCBITaxon|GO|CL|CHEBI|UBERON|PR|SO)_([0-9]+)\b")
PAIR = re.compile(r'⟨"((?:NCBITaxon|GO|CL|CHEBI|UBERON|SO|PR):[0-9]+)", "([^"]+)"⟩')


def iri(curie):
    pre, loc = curie.split(":", 1)
    return f"http://purl.obolibrary.org/obo/{pre}_{loc}"


def fetch(curie):
    pre = curie.split(":", 1)[0]
    onto = ONTO[pre]
    kind = "properties" if pre in ("RO", "BFO") else "classes"
    q = urllib.parse.quote(urllib.parse.quote(iri(curie), safe=""), safe="")
    path = DL / f"{curie.replace(':', '_')}.json"
    if not path.exists():
        for attempt in range(4):
            try:
                with urllib.request.urlopen(f"{API}/ontologies/{onto}/{kind}/{q}", timeout=60) as r:
                    path.write_bytes(r.read())
                break
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    return curie, {"_error": "404"}
                time.sleep(2 + attempt * 2)
            except Exception:
                time.sleep(2 + attempt * 2)
        else:
            return curie, {"_error": "network"}
    try:
        return curie, json.loads(path.read_text())
    except Exception as e:
        return curie, {"_error": str(e)[:60]}


def text(x):
    if isinstance(x, list):
        x = x[0] if x else None
    if isinstance(x, dict):
        x = x.get("value")
    return x or ""


def clean(label):
    return re.sub(r" <[^>]*>$", "", label).lower().replace("obsolete ", "").strip()


def main():
    used = {}
    pairs = {}
    for f in FILES:
        s = (ROOT / f).read_text()
        for m in CURIE.finditer(s):
            used.setdefault(f"{m.group(1)}:{m.group(2)}", set()).add(f)
        for m in LIBREF.finditer(s):
            used.setdefault(f"{m.group(1)}:{m.group(2)}", set()).add(f)
        for m in PAIR.finditer(s):
            pairs.setdefault(m.group(1), set()).add(m.group(2))
            used.setdefault(m.group(1), set()).add(f)
    with concurrent.futures.ThreadPoolExecutor(6) as ex:
        got = dict(ex.map(fetch, sorted(used)))
    rows, bad = [], []
    for c in sorted(used):
        d = got[c]
        if "_error" in d or not d.get("iri"):
            rows.append((c, "", "", "NOT FOUND " + d.get("_error", ""), ",".join(sorted(used[c]))))
            bad.append(rows[-1])
            continue
        lab = text(d.get("label"))
        status = "ok"
        if d.get("isObsolete"):
            status += " OBSOLETE"
        for want in sorted(pairs.get(c, ())):
            if clean(want) != clean(lab):
                status = f"LABEL MISMATCH (Lean says {want!r})"
        rows.append((c, lab, str(d.get("isObsolete")), status, ",".join(sorted(used[c]))))
        if not status.startswith("ok") or "OBSOLETE" in status:
            bad.append(rows[-1])
    with open(OUT / "curies_review.tsv", "w") as f:
        f.write("# every CURIE in the program 05 files, OLS4 api/v2, 2026-10-31, scripts/stress/grade_review_ols.py\n")
        f.write("curie\tols4_label\tobsolete\tcheck\tused_in\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    for r in bad:
        print(r)
    print(f"{len(rows)} curies, {sum(1 for r in rows if r[3].startswith('NOT FOUND'))} not found, "
          f"{sum(1 for r in rows if 'MISMATCH' in r[3])} label mismatches, {len(pairs)} labelled in Lean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
