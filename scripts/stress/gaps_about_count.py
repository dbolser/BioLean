"""Program 08 (review): how round 3 stores the numbers of the "about" sentences.

Reads data/stress/08/survey_approx.tsv (written by gaps_survey.py) and the round 3 Lean sources in
BioLean/Lib/TextbookClaimsR3/ (read only). For every round 3 record of an "about" sentence it says
whether the claim is a quantity, and if so whether it holds one number (a point measure, an exact
count, an exact bound) or a range. Writes data/stress/08/about_quantities.tsv and prints the counts
that the program doc quotes.

    python3 scripts/stress/gaps_about_count.py
"""

import collections
import csv
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "stress", "08")

# Records whose number is exact by nature, not rounded (checked by hand against the sentence).
EXACT_BY_NATURE = {
    "molbio-m45475-95": "a single circular chromosome",
    "molbio-m45475-98": "a single origin of replication",
}


def r3_claims():
    out = {}
    for f in glob.glob(os.path.join(ROOT, "BioLean/Lib/TextbookClaimsR3/*.lean")):
        txt = open(f).read()
        for m in re.finditer(r'id := "([^"]+)"\n  text := "[^"]*"\n  claim := (.*)\n', txt):
            out[m.group(1)] = m.group(2)
    return out


def classify(claim):
    c = claim
    if re.match(r"^\.quant \.\w+ \(", c):
        c = re.sub(r"^\.quant \.\w+ \(", "", c)[:-1]
    if c.startswith(".measure"):
        nums = re.findall(r'\s(\(?-?[\d/]+\)?)\s(\(?-?[\d/]+\)?)\s"[^"]*"$', c)
        if nums:
            lo, hi = nums[-1]
            return ("one number" if lo == hi else "range"), f"[{lo}, {hi}]"
        return "measure (unparsed)", ""
    if c.startswith(".countBetween") or c.startswith(".atLeastMeasure"):
        return "range", ""
    if c.startswith((".count", ".atLeast", ".cardinality")):
        return "one number", c.split()[-1]
    return "not a quantity", c.split()[0]


def main():
    csv.field_size_limit(10 ** 8)
    rows = list(csv.DictReader(open(os.path.join(OUT, "survey_approx.tsv")), delimiter="\t"))
    lean = r3_claims()
    table = []
    for r in rows:
        for rec in r["records"].split(" || "):
            rid = rec.split("|")[0]
            if rid not in lean:
                continue
            kind, val = classify(lean[rid])
            nature = EXACT_BY_NATURE.get(rid, "")
            table.append((rid, r["trigger"], kind, val, nature, lean[rid][:160]))
    with open(os.path.join(OUT, "about_quantities.tsv"), "w") as f:
        f.write("id\ttrigger\tkind\tvalue\texact_by_nature\tr3_claim\n")
        for t in table:
            f.write("\t".join(t) + "\n")
    n = len(table)
    k = collections.Counter(t[2] for t in table)
    quant = n - k["not a quantity"]
    one = k["one number"]
    nature = sum(1 for t in table if t[2] == "one number" and t[4])
    print(f"round 3 records from 'about' sentences: {n}")
    print(f"  quantities: {quant}; one number: {one}; range: {k['range']}; not a quantity: {k['not a quantity']}")
    print(f"  of the {one} single numbers, {nature} are exact by nature; {one - nature} are rounded numbers stored exactly")
    for t in table:
        if t[2] != "one number":
            print("  ", t[0], t[2], t[3])


if __name__ == "__main__":
    main()
