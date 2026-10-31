"""Program 09: write the real chemiosmotic record into BioLean/Stress/ChemiosmosisReal.lean.

Reads data/stress/09/record.tsv and replaces the text between the two marker lines
`-- BEGIN GENERATED RECORD` and `-- END GENERATED RECORD` in the Lean file. Everything outside
the markers is hand-written and kept as is.

    python3 scripts/stress/chemiosmosis_emit.py
"""
import csv
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
TSV = os.path.join(ROOT, "data/stress/09/record.tsv")
LEAN = os.path.join(ROOT, "BioLean/Stress/ChemiosmosisReal.lean")
BEGIN, END = "-- BEGIN GENERATED RECORD", "-- END GENERATED RECORD"
SIDE = {"C": ".C", "S": ".S", "W": ".W", "G": ".G", "M": ".M", "none": ".none"}


def s(x):
    return '"' + x.replace("\\", "\\\\").replace('"', '\\"') + '"'


def b(x):
    return "true" if x else "false"


def item(e):
    kind = {"experiment": ".inVitro", "review": ".review", "hypothesis": ".hypothesis"}[e["kind"]]
    pol = ".refutes" if e["direction"] == "refutes" else ".supports"
    ident = f'PMID {e["pmid"]}' if e["pmid"] not in ("", "0") else f'no PMID, DOI {e["doi"]}'
    note = f'{e["first_author"]} {e["year"]}, {e["journal"]} ({ident}): {e["showed"]} [direction from {e["basis"]}]'
    if e["direction"] == "neutral":
        note = "NEUTRAL, not encoded (Polarity has no neutral value). " + note
    title = e["title"].replace("-/", "- /")
    return "\n".join([
        f"/-- {title} -/",
        f'def {e["key"]} : Item :=',
        f'  {{ key := {s(e["key"])}, side := {SIDE[e["rival"]]}, lab := {s(e["lab"])}, '
        f'review := {b(e["kind"] == "review")}, advocate := {b(e["advocacy"] == "y")},',
        f'    dual := {b(e["dual_refutes"] == "S")}, memory := {b(e["basis"] == "memory")},',
        f'    ev := {{ pmid := {int(e["pmid"] or 0)}, year := {int(e["year"])}, kind := {kind}, polarity := {pol},',
        f'            note := {s(note)} }} }}',
    ])


def main():
    with open(TSV) as f:
        rec = list(csv.DictReader(f, delimiter="\t"))
    encoded = [e for e in rec if e["direction"] != "neutral"]
    neutral = [e for e in rec if e["direction"] == "neutral"]
    years = sorted({int(e["year"]) for e in encoded})
    body = [BEGIN + " (scripts/stress/chemiosmosis_emit.py from data/stress/09/record.tsv; do not edit by hand)", ""]
    body += [item(e) + "\n" for e in rec]
    body.append("/-- The encoded record: every item with a direction, in the order of `record.tsv`. -/")
    body.append("def record : List Item := [" + ", ".join(e["key"] for e in encoded) + "]")
    body.append("")
    body.append("/-- Context items with no direction. Kept for the record; no encoding can carry them. -/")
    body.append("def neutralItems : List Item := [" + ", ".join(e["key"] for e in neutral) + "]")
    body.append("")
    body.append("/-- Every year in which an encoded item appeared. -/")
    body.append("def recordYears : List Nat := [" + ", ".join(map(str, years)) + "]")
    body.append(END)
    with open(LEAN) as f:
        text = f.read()
    i, j = text.index(BEGIN), text.index(END) + len(END)
    with open(LEAN, "w") as f:
        f.write(text[:i] + "\n".join(body) + text[j:])
    print(f"wrote {len(encoded)} encoded and {len(neutral)} neutral items, {len(years)} years, into {LEAN}")


if __name__ == "__main__":
    main()
