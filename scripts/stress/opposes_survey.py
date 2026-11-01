"""Program 06: find textbook sentences about opposing or antagonistic pairs.

Reads the OpenStax source text (data/textbook/source/*.json) and the round 2 and round 3 claim
records (data/textbook/claims_m2, claims_m3), and lists every sentence that mentions an opposition
word or one of the candidate pairs, with whether R2 or R3 compiled a statement for it.
Writes data/stress/06/survey.tsv. Read-only on everything else.
"""
import glob
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/06/survey.tsv"

WORDS = [
    r"oppos", r"antagon", r"counteract", r"counterbalanc", r"\bagonist", r"glucagon", r"calcitonin",
    r"parathyroid", r"antidiuretic|\bADH\b", r"natriuretic|\bANP\b", r"auxin", r"cytokinin",
    r"gibberellin", r"abscisic", r"\bGABA\b", r"glutamate", r"phosphatase", r"biceps", r"triceps",
    r"sympathetic", r"sweat gland", r"insulin", r"aldosterone", r"vasoconstrict|vasodilat",
    r"flexor|extensor", r"inhibitory", r"excitatory", r"naloxone|morphine|opioid",
]
RX = re.compile("|".join(WORDS), re.I)


def sentences(text: str):
    return [s.strip() for s in re.split(r"(?<=[.!?])\s+(?=[A-Z])", text) if s.strip()]


def main() -> int:
    # compiled statement ids in R2 and R3 Lean
    lean_ids = {}
    for rnd in ("R2", "R3"):
        for f in glob.glob(str(ROOT / f"BioLean/Lib/TextbookClaims{rnd}/*.lean")):
            for m in re.finditer(r'id := "([^"]+)"', Path(f).read_text()):
                lean_ids.setdefault(m.group(1), []).append(rnd)
    rows = []
    for f in sorted(glob.glob(str(ROOT / "data/textbook/source/*.json"))):
        d = json.load(open(f))
        chap = Path(f).stem
        for mod in d["modules"]:
            for p in mod.get("paragraphs", []):
                for s in sentences(p):
                    hits = sorted({h.group(0).lower() for h in RX.finditer(s)})
                    if hits:
                        rows.append((chap, mod["id"], ",".join(hits), s))
    # claim ids whose source sentence matches, R2 and R3 records
    recs = {}
    for f in sorted(glob.glob(str(ROOT / "data/textbook/claims*/*.json"))):
        data = json.load(open(f))
        items = data if isinstance(data, list) else data.get("claims", data.get("records", []))
        for r in items:
            if not isinstance(r, dict):
                continue
            sent = r.get("source") or r.get("sentence") or ""
            cid = r.get("id") or r.get("claim_id") or ""
            if sent and cid:
                recs.setdefault(sent.strip(), set()).add(cid)
    with open(OUT, "w") as out:
        out.write("chapter\tmodule\thits\tclaim_ids\tin_lean\tsentence\n")
        for chap, mod, hits, s in rows:
            ids = sorted(recs.get(s, []))
            inl = sorted({f"{i}:{'+'.join(lean_ids[i])}" for i in ids if i in lean_ids})
            out.write(f"{chap}\t{mod}\t{hits}\t{' '.join(ids)}\t{' '.join(inl)}\t{s}\n")
    print(f"{len(rows)} sentences -> {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
