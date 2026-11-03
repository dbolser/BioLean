"""Find ontology and UniProt terms by label, for grounding a curation.

    uv run python scripts/ipf/terms.py "endoplasmic reticulum stress"
    uv run python scripts/ipf/terms.py "ER stress" --kind process
    uv run python scripts/ipf/terms.py endosome --prefix GO      # every ontology in the corpus, by title
    uv run python scripts/ipf/terms.py GO:0034976                # a CURIE: its label and definition

The label table (labels and synonyms of CHEBI, GO processes, HP, PATO, MONDO, UBERON, CL and human
UniProt) is searched first: exact matches, then labels containing every word. Then the titles of
every ontology term in the corpus (GO functions and components, MP, SO, PR, ...), which has no
synonyms. `--prefix` searches only the corpus titles under that prefix.
"""
import argparse
import re
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from biolean.corpus import query  # noqa: E402

LOOKUP = ROOT / "data/lookup/labels.parquet"


def show_curie(curie: str) -> None:
    rid = curie.removeprefix("UniProt:")
    rows = query("select record_type, title, text from records where record_id = ?", [rid])
    if not rows:
        print(f"{curie}: not in the corpus")
        return
    own = {"GO": "go_term", "MONDO": "mondo_disease"}.get(rid.split(":")[0])
    rows.sort(key=lambda r: (r[0] != own, not r[0].endswith(rid.split(":")[0].lower()), -len(r[2])))
    rtype, title, text = rows[0]
    text = "\n".join(line for line in text.splitlines() if "\\1" not in line)  # corpus artefact
    print(f"{curie}  {title}  ({rtype})\n{text[:900]}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("text")
    ap.add_argument("--kind")
    ap.add_argument("--prefix")
    ap.add_argument("-n", type=int, default=15)
    args = ap.parse_args()
    if re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*:\S+", args.text):
        show_curie(args.text)
        return
    words = args.text.lower().split()
    if not args.prefix:
        kind = "cell_type" if args.kind == "cellType" else args.kind
        where = "and kind = ?" if kind else ""
        rows = duckdb.execute(
            f"""select curie, kind, label, method, label_lower = ? exact from '{LOOKUP}'
                where (label_lower = ? or ({' and '.join(['contains(label_lower, ?)'] * len(words))})) {where}
                order by exact desc, method, length(label_lower) limit ?""",
            [args.text.lower(), args.text.lower(), *words, *([kind] if kind else []), args.n]).fetchall()
        for curie, k, label, method, exact in rows:
            print(f"{curie:18} {k:10} {'=' if exact else '~'} {label}  ({method})")
        if args.kind:
            return
    like = f"{args.prefix}:%" if args.prefix else "%"
    rows = query(
        f"""select record_id, any_value(title) t from records where record_class = 'Ontology' and record_id like ?
            and {' and '.join(['contains(lower(title), ?)'] * len(words))}
            group by record_id order by lower(t) = ? desc, length(t) limit ?""",
        [like, *words, args.text.lower(), args.n])
    if rows:
        print("-- ontology titles in the corpus:")
    for rid, title in rows:
        print(f"{rid:18} {'':10} {'=' if title.lower() == args.text.lower() else '~'} {title}")


if __name__ == "__main__":
    main()
