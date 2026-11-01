"""Program 06: check that every `paper PMID YEAR kind "note"` quote in the two Lean files is verbatim in
the Europe PMC title or abstract of that PMID (cached by opposes_refs.py). A note may hold several
fragments joined by " ... "; each must match. A trailing " (title)" means the title only.
Writes data/stress/06/quotes_checked.tsv. Read-only on the Lean files.
"""
import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CACHE = Path("/tmp/biolean-06/dl2/epmc")
FILES = [ROOT / "BioLean/Stress/Opposition.lean", ROOT / "BioLean/Proto/Opposes.lean"]
RX = re.compile(r'paper (\d+) (\d{4}) \.\w+ "([^"]*)"')


def norm(s):
    s = html.unescape(re.sub(r"<[^>]+>", " ", s))
    s = s.replace("—", "-").replace("–", "-")
    return re.sub(r"\s+", " ", s).strip().lower()


def record(pmid):
    p = CACHE / f"p_{pmid}.json"
    if not p.exists():
        return None
    res = json.loads(p.read_text()).get("resultList", {}).get("result", [])
    return res[0] if res else None


TB = re.compile(r'tb "([^"]*)"')


def book_text():
    t = []
    for f in sorted((ROOT / "data/textbook/source").glob("*.json")):
        for mod in json.load(open(f))["modules"]:
            t.extend(mod.get("paragraphs", []))
    return norm(" ".join(t))


def main():
    rows, bad = [], 0
    book = book_text()
    for f in FILES:
        for m in TB.finditer(f.read_text()):
            note = m.group(1)
            if note.startswith(("SYNTHETIC", "PROMOTED", "OpenStax")) or "{" in note:
                continue
            ok = all(norm(x) in book for x in note.split(" ... ") if x.strip())
            bad += not ok
            rows.append((f.name, "textbook", note, "ok" if ok else "NOT VERBATIM"))
    for f in FILES:
        for m in RX.finditer(f.read_text()):
            pmid, year, note = m.groups()
            r = record(pmid)
            if r is None:
                rows.append((f.name, pmid, note, "NO RECORD (run opposes_refs.py check)"))
                bad += 1
                continue
            title_only = note.endswith(" (title)")
            text = norm(r.get("title", "")) if title_only else norm(r.get("title", "") + " " + r.get("abstractText", ""))
            frags = [x for x in note.removesuffix(" (title)").split(" ... ") if x.strip()]
            ok = all(norm(x) in text for x in frags)
            yr = str(r.get("pubYear")) == year
            status = "ok" if ok and yr else ("YEAR MISMATCH" if ok else "NOT VERBATIM")
            bad += status != "ok"
            rows.append((f.name, pmid, note, status))
    with open(ROOT / "data/stress/06/quotes_checked.tsv", "w") as out:
        out.write("file\tpmid\tquote\tstatus\n")
        for r in rows:
            out.write("\t".join(r) + "\n")
    for r in rows:
        if r[3] != "ok":
            print(r)
    print(f"{len(rows)} quotes, {bad} not ok")
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
