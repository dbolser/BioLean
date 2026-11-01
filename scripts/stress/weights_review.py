"""Program 10a, review: check every "Author YEAR ... PMID" pair the program writes against Europe PMC.

Reads the Europe PMC metadata written by weights_epmc_fetch.py (untrusted data: run with
`python3 -I`), then

  1. the doc's reference list (lines like "Stampfer 1985 PMID:4047106" or "Balshem H et al. 2011. ...
     PMID:21208779"),
  2. the notes of `ev PMID YEAR ... "Author YEAR..."` items in BioLean/Stress/Weights.lean,

and prints, for each pair, whether the cited surname is among the paper's authors (first author for
the doc) and whether the cited year matches the Europe PMC year (or the item year in Lean). It also
checks the item year in Lean against Europe PMC. Writes data/stress/10a/review_refs.tsv.

usage: python3 -I scripts/stress/weights_review.py EPMC.json
"""
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEAN = ROOT / "BioLean/Stress/Weights.lean"
DOC = ROOT / "docs/programs/10a-evidence-weights.md"
OUT = ROOT / "data/stress/10a/review_refs.tsv"

# names used for trials or cohorts rather than authors
GROUP_NAMES = {"HOPE", "HOPE-TOO", "ISIS-4", "MAGIC", "ATBC", "CARET", "LIMIT-2", "CHAOS", "WHS", "PHS",
               "SAINT", "HERS", "WHI", "NHS", "HPFS", "retraction"}


def fold(s):
    s = unicodedata.normalize("NFKD", s)
    return "".join(c for c in s if not unicodedata.combining(c)).lower().replace("'", "").replace("-", " ")


def surnames(authors):
    out = []
    for a in authors:
        a = fold(a)
        out.append(a.split(" ")[0] if a else "")
        out.append(a)
    return out


def main():
    meta = json.load(open(sys.argv[1]))
    rows = []
    doc = DOC.read_text()
    # 1. doc references: "Name[ & Name] YEAR PMID:n" or "Name X et al. YEAR. title. PMID:n"
    for m in re.finditer(r"([A-Z][A-Za-z'\-]+(?: [A-Z][A-Za-z'\-]+)?)(?: [A-Z]{1,3})?(?: et al\.)?(?: & [A-Za-z\-]+)?"
                         r"(?:, [A-Z][A-Za-z ,&]+?)? (\d{4})\.?[^\n;]*?PMID:(\d{6,8})", doc):
        name, year, pmid = m.group(1).split(" ")[-1] if m.group(1).split(" ")[0] in ("Clinical", "Laboratory") else m.group(1).split(" ")[0], m.group(2), m.group(3)
        v = meta.get(pmid)
        if not v:
            rows.append(["doc", pmid, name, year, "", "", "NOT FOUND"])
            continue
        au = v.get("authors") or []
        first = fold(au[0]).split(" ")[0] if au else ""
        ok_name = name in GROUP_NAMES or fold(name) == first or fold(name) in fold(au[0] if au else "")
        ok_year = str(v.get("year")) == year
        rows.append(["doc", pmid, name, year, au[0] if au else "", v.get("year"),
                     "ok" if ok_name and ok_year else ("NAME" if not ok_name else "") + (" YEAR" if not ok_year else "")])
    # 2. Lean notes
    lean = LEAN.read_text()
    for m in re.finditer(r"ev (\d{6,8}) (\d{4}) \.\w+(?: \.\w+)?(?: \"([^\"]*)\")?", lean):
        pmid, iyear, note = m.group(1), m.group(2), m.group(3) or ""
        v = meta.get(pmid)
        if not v:
            if not re.match(r"^(70000001|8\d{7}|9\d{7})$", pmid):
                rows.append(["lean", pmid, note, iyear, "", "", "NOT FOUND"])
            continue
        au = v.get("authors") or []
        status = []
        if str(v.get("year")) != iyear:
            status.append(f"ITEM YEAR {iyear} vs {v.get('year')}")
        nm = re.match(r"([A-Z][A-Za-z0-9'\-]+(?: [A-Z][a-z]+)?)", note)  # digits: trial names (ISIS-4)
        if nm and nm.group(1).split(" ")[0] not in GROUP_NAMES:
            n0 = fold(nm.group(1).split(" ")[0])
            if n0 not in ("obokata", "de", "van") and not any(s == n0 for s in surnames(au)):
                if not any(n0 in fold(a) for a in au):
                    status.append(f"NAME {nm.group(1)} not in authors")
        rows.append(["lean", pmid, note[:60], iyear, au[0] if au else "", v.get("year"), "; ".join(status) or "ok"])
    with open(OUT, "w") as f:
        f.write("where\tpmid\tcited\tcited_year\tepmc_first_author\tepmc_year\tstatus\n")
        for r in rows:
            f.write("\t".join(str(x) for x in r) + "\n")
    bad = [r for r in rows if r[-1] != "ok"]
    print(f"{len(rows)} pairs checked, {len(bad)} not ok")
    for r in bad:
        print("\t".join(str(x) for x in r))


if __name__ == "__main__":
    main()
