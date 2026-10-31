"""Program 09: check every PMID in the chemiosmosis record and the histories on Europe PMC.

For each PMID: fetch the Europe PMC core record (cached in /tmp/biolean-09/dl2/), then compare
year, first author surname and title with data/stress/09/record.tsv. Writes
data/stress/09/references_checked.tsv. Downloads are untrusted: run with `python3 -I`.

    python3 -I scripts/stress/chemiosmosis_verify.py <repo root>
"""
import csv
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
DL = "/tmp/biolean-09/dl2"
OUT = os.path.join(ROOT, "data/stress/09/references_checked.tsv")

# Histories and other sources cited in the program doc but not encoded as evidence.
EXTRA = [
    ("h01", "11536297", "2001", "Harold FM", "Gleanings of a chemiosmotic eye"),
    ("h02", "8842371", "1996", "Prebble J", "Successful theory development in biology"),
    ("h03", "11859886", "2001", "Prebble J", "The philosophical origins of Mitchell's chemiosmotic concepts"),
    ("h04", "11943549", "2002", "Prebble J", "Peter Mitchell and the ox phos wars"),
    ("h05", "12068893", "2002", "Allchin D", "To err and win a Nobel Prize"),
    ("h06", "23104597", "2013", "Prebble JN", "Contrasting approaches to a biological problem"),
    ("h07", "22082452", "2011", "Mitchell P", "Chemiosmotic coupling in oxidative and photosynthetic phosphorylation"),
    ("h08", "18846415", "2008", "Rich PR", "A perspective on Peter Mitchell and the chemiosmotic theory"),
    # Added at build 2026-10-31: a lead for E1. Its reference 1 is Tager et al. 1966 (Nature page).
    ("h09", "4291593", "1967", "Mitchell P", "Chemiosmotic hypothesis of oxidative phosphorylation"),
    ("h10", "4170459", "1967", "van Dam K", "A suggested mechanism of uncoupling of respiratory-chain phosphorylation"),
]

# References with no PMID, checked on Crossref instead: (key, doi, year, first author, title).
CROSSREF = [
    ("w14", "10.1016/0304-4173(85)90005-9", "1985", "Ferguson SJ",
     "Fully delocalised chemiosmotic or localised proton flow pathways in energy coupling?"),
    ("x01", "10.1207/s15516709cog1104_4", "1987", "Pollock JL", "Defeasible Reasoning"),
    ("x02", "10.1016/0004-3702(94)00041-X", "1995", "Dung PM",
     "On the acceptability of arguments and its fundamental role in nonmonotonic reasoning"),
    ("x03", "10.1007/978-3-319-42337-1", "2016", "Josang A", "Subjective Logic"),
    ("c23", "10.1111/j.1432-1033.1967.tb00076.x", "1967", "Slater EC",
     "An evaluation of the Mitchell hypothesis of chemiosmotic coupling"),
]


def norm(s):
    s = s.lower().replace("\u00f8", "o")
    return re.sub(r"[^a-z0-9]", "", s)


def surname(author):
    """'Van der Bend RL' -> 'Van der Bend': drop the trailing initials."""
    parts = author.split()
    return " ".join(parts[:-1]) if len(parts) > 1 and parts[-1].isupper() else author


def fetch(pmid):
    path = os.path.join(DL, f"core_{pmid}.json")
    if not os.path.exists(path):
        url = ("https://www.ebi.ac.uk/europepmc/webservices/rest/search?" + urllib.parse.urlencode(
            {"query": f"EXT_ID:{pmid} AND SRC:MED", "format": "json", "resultType": "core"}))
        raw = urllib.request.urlopen(url, timeout=40).read()
        with open(path, "wb") as f:
            f.write(raw)
        time.sleep(0.2)
    with open(path) as f:
        rs = json.load(f).get("resultList", {}).get("result", [])
    return rs[0] if rs else None


def fetch_doi(doi):
    path = os.path.join(DL, "crossref_" + re.sub(r"[^A-Za-z0-9]", "_", doi) + ".json")
    if not os.path.exists(path):
        url = "https://api.crossref.org/works/" + urllib.parse.quote(doi)
        req = urllib.request.Request(url, headers={"User-Agent": "BioLean-stress-09 (read-only lookup)"})
        try:
            raw = urllib.request.urlopen(req, timeout=40).read()
        except Exception:
            return None
        with open(path, "wb") as f:
            f.write(raw)
        time.sleep(0.2)
    with open(path) as f:
        return json.load(f).get("message")


def main():
    rows = []
    with open(os.path.join(ROOT, "data/stress/09/record.tsv")) as f:
        for r in csv.DictReader(f, delimiter="\t"):
            rows.append((r["key"], r["pmid"], r["year"], r["first_author"], r["title"]))
    rows = [r for r in rows if r[1] not in ("", "0")] + EXTRA
    out = []
    for key, doi, year, author, title in CROSSREF:
        m = fetch_doi(doi)
        if m is None:
            out.append([key, "DOI:" + doi, year, author, title, "", "", "", "NOT FOUND (Crossref)", ""])
            continue
        got_year = str((m.get("issued", {}).get("date-parts") or [[""]])[0][0])
        got_title = (m.get("title") or [""])[0]
        au = m.get("author") or [{}]
        got_author = au[0].get("family", au[0].get("name", ""))
        ok_year = got_year == year
        ok_author = norm(surname(author)) == norm(got_author)
        ok_title = norm(got_title).startswith(norm(title)[:40]) or norm(title).startswith(norm(got_title)[:40])
        status = "OK (Crossref)" if (ok_year and ok_author and ok_title) else "MISMATCH (Crossref) " + ",".join(
            n for n, ok in [("year", ok_year), ("author", ok_author), ("title", ok_title)] if not ok)
        out.append([key, "DOI:" + doi, year, author, title, got_year, got_author, got_title, status, ""])
    for key, pmid, year, author, title in rows:
        r = fetch(pmid)
        if r is None:
            out.append([key, pmid, year, author, title, "", "", "", "NOT FOUND", ""])
            continue
        got_year = str(r.get("pubYear", ""))
        got_title = re.sub("<[^>]+>", "", r.get("title", "")).rstrip(".")
        authors = r.get("authorList", {}).get("author", [])
        got_author = authors[0].get("lastName", authors[0].get("fullName", "")) if authors else ""
        ok_year = got_year == year
        ok_author = norm(surname(author)) == norm(got_author)
        ok_title = norm(got_title).startswith(norm(title)[:40]) or norm(title).startswith(norm(got_title)[:40])
        has_abs = "y" if r.get("abstractText") else "n"
        status = "OK" if (ok_year and ok_author and ok_title) else "MISMATCH " + ",".join(
            n for n, ok in [("year", ok_year), ("author", ok_author), ("title", ok_title)] if not ok)
        out.append([key, pmid, year, author, title, got_year, got_author, got_title, status, has_abs])
    with open(OUT, "w", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["key", "pmid", "year", "first_author", "title", "epmc_year", "epmc_first_author",
                    "epmc_title", "status", "abstract_in_epmc"])
        w.writerows(out)
    bad = [o for o in out if not o[8].startswith("OK")]
    print(f"{len(out)} checked, {len(out) - len(bad)} OK, {len(bad)} not OK")
    for o in bad:
        print("  ", o[0], o[1], o[8], "| record:", o[3], o[2], o[4][:50], "| epmc:", o[6], o[5], o[7][:50])


if __name__ == "__main__":
    main()
