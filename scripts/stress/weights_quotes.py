"""Program 10a, review: check every quoted phrase and every stated number in the case table against
Europe PMC titles and abstracts.

For each case in data/stress/10a/case_spec.json, every phrase in single quotes in `correct` or
`input` is looked up (case- and space-insensitive) in the title and abstract of the case's source
PMIDs, then of every PMID in the metadata. Textbook phrases are looked up in data/textbook/claims*.
A fixed list of numbers the doc and the Lean file state (participants, replication counts) is
checked the same way. Writes data/stress/10a/quotes_checked.tsv.

Europe PMC metadata (weights_epmc_fetch.py output) is untrusted data: run with `python3 -I`.

usage: python3 -I scripts/stress/weights_quotes.py EPMC.json
"""
import glob
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/10a"
SPEC = OUT / "case_spec.json"

# (PMID, phrase as it should appear in the title or abstract, what it supports). Every entry of the
# Lean `sizes` table (option K) is added to these by `size_rows`.
NUMBERS = [
    ("34874005", "39/97", "CAL01, option M: original positive effects replicated"),
    ("34874005", "12/15", "CAL01, option M: original null effects replicated"),
    ("16014596", "five of 6 highly-cited nonrandomized studies", "CAL02, W06"),
    ("16014596", "9 of 39 randomized controlled trials", "CAL02, W06"),
    ("24814559", "1,256,407 children", "D05"),
    ("24814559", "five cohort studies", "D05"),
    ("1838289", "seven", "W04: number of trials in the overview"),
    ("36188627", "eight studies", "D03: studies pooled by Gao 2022"),
]
LEAN = ROOT / "BioLean/Stress/Weights.lean"
# a quote opens after a space or bracket and closes before a space or punctuation, so that
# apostrophes ("O'Neil", "annotations' reliability") are not read as quote marks
QUOTE = re.compile(r"(?:^|(?<=[\s(]))'(.{4,}?)'(?=[\s,.;:)]|$)")
# phrases in single quotes that name a label or a column, not a quotation
LABELS = {"not established", "Complete", "number correct (total curated)", "IEA ECO:0000501", "EXP ECO:0000269"}
# sizes that are a sum of numbers the abstract gives separately
SIZE_PARTS = {"10639540": "2545 women and 6996 men"}


def size_rows():
    """(PMID, participants) of the Lean `sizes` table, as phrases to find: the number with or
    without a thousands separator (comma, space, thin space)."""
    block = re.search(r"def sizes :.*?(?=\n\n|\n/--)", LEAN.read_text(), re.S).group(0)
    return [(p, int(n)) for p, n in re.findall(r"\((\d{6,8}), (\d+)\)", block)]


def norm(s):
    s = re.sub(r"<[^>]+>", "", s or "")
    return re.sub(r"\s+", " ", s).strip().lower().replace(" ", " ").replace(" ", " ")


def textbook():
    out = {}
    for f in glob.glob(str(ROOT / "data/textbook/claims*/*.json")):
        try:
            data = json.load(open(f))
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue
        items = data if isinstance(data, list) else data.get("claims", [])
        for c in items:
            if isinstance(c, dict) and "id" in c:
                out[c["id"]] = norm(c.get("source", "")) + " | " + norm(c.get("claim", ""))
    return out


def main():
    meta = json.load(open(sys.argv[1]))
    text = {p: norm(v.get("title")) + " | " + norm(v.get("abstract")) for p, v in meta.items()}
    book = textbook()
    rows = []
    for c in json.load(open(SPEC)):
        src = [s.split(":", 1)[1] for s in c["sources"] if s.startswith("PMID:")]
        for field in ("correct", "input"):
            for q in QUOTE.findall(c[field]):
                if q in LABELS:
                    rows.append([c["id"], field, q, "label, not a quotation"])
                    continue
                parts = [norm(x) for x in q.split("...") if x.strip()]  # an elided quotation
                hit = lambda t: all(x in t for x in parts)  # noqa: E731
                where = [p for p in src if hit(text.get(p, ""))]
                if not where:
                    where = [p for p, t in text.items() if hit(t)]
                if not where:
                    where = ["textbook:" + i for i, t in book.items() if hit(t)][:3]
                rows.append([c["id"], field, q, ", ".join(where) or "NOT FOUND"])
    for p, q, what in NUMBERS:
        rows.append([what, "number", q, p if norm(q) in text.get(p, "") else f"NOT FOUND in {p}"])
    for p, n in size_rows():
        forms = [str(n), f"{n:,}", f"{n:,}".replace(",", " ")]
        if p in SIZE_PARTS:
            a, b = (int(x) for x in re.findall(r"\d+", SIZE_PARTS[p]))
            forms = [SIZE_PARTS[p]] if a + b == n else []
        hit = [f for f in forms if f in text.get(p, "")]
        rows.append(["size table (option K)", "number", str(n), p if hit else f"NOT FOUND in {p}"])
    with open(OUT / "quotes_checked.tsv", "w") as f:
        f.write("case\tfield\tphrase\tfound_in\n")
        for r in rows:
            f.write("\t".join(x.replace("\t", " ") for x in r) + "\n")
    bad = [r for r in rows if r[3].startswith("NOT FOUND")]
    print(f"{len(rows)} phrases checked, {len(bad)} not found")
    for r in bad:
        print("\t".join(r))


if __name__ == "__main__":
    main()
