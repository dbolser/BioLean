"""Program 05: print data/stress/05/lineage.tsv as a Lean table (pasted into the stress files).

Only members outside the imported NCBITaxon closure need it; members inside are read with
`Taxa.isA`. Usage: python3 scripts/stress/grade_lineage_lean.py
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
SKIP = {"2", "2157", "2759"}  # the domains themselves

rows = []
for line in open(ROOT / "data/stress/05/lineage.tsv"):
    if line.startswith(("#", "taxid")):
        continue
    tid, name, rank, anc = line.rstrip("\n").split("\t")
    if tid in SKIP:
        continue
    ids = [a.split(":", 1)[0] for a in anc.split("; ") if a]
    rows.append((tid, name, ids))
print("/-- NCBI Taxonomy lineages (efetch 2026-10-31, `data/stress/05/lineage.tsv`): member, ancestors. -/")
print("def ncbiLineage : List (String × List String) := [")
for i, (tid, name, ids) in enumerate(rows):
    sep = "," if i < len(rows) - 1 else ""
    body = ", ".join(f'"NCBITaxon:{x}"' for x in ids)
    print(f'  -- {name}\n  ("NCBITaxon:{tid}", [{body}]){sep}')
print("]")
