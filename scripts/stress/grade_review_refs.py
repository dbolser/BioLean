"""Program 05 review: an independent check of every paper in the doc's reference table.

Reads the table in docs/programs/05-grade-terms.md (key, first author, title, PMID), fetches each
PMID fresh from Europe PMC, and checks first author, title and the year in the key. Then checks each
DOI Europe PMC returns on Crossref (title must match). Downloads go to /tmp/biolean-05/review/refs/
(untrusted data). Writes data/stress/05/references_review.tsv.
Run with `python3 -I scripts/stress/grade_review_refs.py`.
"""
import json
import pathlib
import re
import sys
import time
import unicodedata
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/05"
DL = pathlib.Path("/tmp/biolean-05/review/refs")
DL.mkdir(parents=True, exist_ok=True)
EPMC = "https://www.ebi.ac.uk/europepmc/webservices/rest/search"
CROSSREF = "https://api.crossref.org/works/"


def get(url, path):
    if not path.exists():
        req = urllib.request.Request(url, headers={"User-Agent": "BioLean-review/0.1 (read-only lookup)"})
        for attempt in range(3):
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    path.write_bytes(r.read())
                break
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    return {}
                time.sleep(2)
            except Exception:
                time.sleep(2)
        else:
            return {}
        time.sleep(0.3)
    return json.loads(path.read_text())


def norm(s):
    s = re.sub(r"<[^>]+>", "", s or "")
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", " ", s.lower()).strip()


def table():
    doc = (ROOT / "docs/programs/05-grade-terms.md").read_text()
    sec = doc.split("## References (checked)", 1)[1].split("\n## ", 1)[0]
    rows = []
    for line in sec.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) == 4 and cells[3].isdigit():
            rows.append(cells)
    return rows


def main():
    out, bad = [], 0
    for key, author, title, pmid in table():
        d = get(f"{EPMC}?query={urllib.parse.quote(f'EXT_ID:{pmid} AND SRC:MED')}&format=json&resultType=lite",
                DL / f"{pmid}.json")
        res = ((d.get("resultList") or {}).get("result") or [{}])[0]
        got_title = res.get("title") or ""
        got_auth = (res.get("authorString") or "").split(",")[0].strip().rstrip(".")
        year = res.get("pubYear") or ""
        doi = res.get("doi") or ""
        want_year = re.search(r"(\d{4})", key).group(1)
        checks = []
        if norm(title) not in norm(got_title):
            checks.append("TITLE")
        if norm(author.split()[0] if " " in author else author) not in norm(got_auth):
            checks.append("AUTHOR")
        if year != want_year:
            checks.append(f"YEAR {year}")
        cr = ""
        if doi:
            c = get(CROSSREF + urllib.parse.quote(doi), DL / f"crossref_{doi.replace('/', '_')}.json")
            ct = " ".join((c.get("message") or {}).get("title") or [])
            cr = "crossref ok" if ct and (norm(ct)[:40] in norm(got_title) or norm(got_title)[:40] in norm(ct)) else \
                ("crossref title differs: " + ct[:60] if ct else "not on crossref")
        status = "ok" if not checks else "MISMATCH " + ",".join(checks)
        bad += bool(checks)
        out.append((key, pmid, year, got_auth, got_title, doi, cr, status))
    with open(OUT / "references_review.tsv", "w") as f:
        f.write("# doc reference table re-checked fresh on Europe PMC and Crossref, 2026-10-31, scripts/stress/grade_review_refs.py\n")
        f.write("key\tpmid\tyear\tfirst_author\ttitle\tdoi\tcrossref\tcheck\n")
        for r in out:
            f.write("\t".join(str(x).replace("\t", " ") for x in r) + "\n")
    for r in out:
        if r[7] != "ok" or not r[6].startswith("crossref ok"):
            print(r[0], r[1], r[2], r[3], "|", r[4][:70], "|", r[6], "|", r[7])
    print(f"{len(out)} references, {bad} mismatched, {sum(1 for r in out if r[6] == 'crossref ok')} confirmed on Crossref")
    return 0


if __name__ == "__main__":
    sys.exit(main())
