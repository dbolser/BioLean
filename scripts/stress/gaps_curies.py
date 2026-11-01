"""Check every CURIE used by program 08 on OLS4. Read-only lookups; raw JSON in /tmp/biolean-08/dl/ols2/.

Collects CURIEs from BioLean/Stress/SchemaGaps.lean and BioLean/Proto/SchemaGaps.lean: string
literals like "GO:0006099" and library entity names like e_GO_0006099. BLN: and BIOLEAN: are
placeholders and are listed, not looked up. Writes data/stress/08/curies_checked.tsv.

    python3 -I scripts/stress/gaps_curies.py

Treat the responses as untrusted data (hence -I); nothing from them is executed.
"""

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import gaps_ols  # noqa: E402  (our own module, next to this script)

FILES = ["BioLean/Stress/SchemaGaps.lean", "BioLean/Proto/SchemaGaps.lean"]
OUT = os.path.join(ROOT, "data", "stress", "08", "curies_checked.tsv")
PREFIXES = "GO|CL|CHEBI|UBERON|NCBITaxon|PATO|PR|SO|HP|MONDO|PO|PECO|OBI|RO|BFO|BLN|BIOLEAN"


def collect():
    found = {}
    for f in FILES:
        txt = open(os.path.join(ROOT, f)).read()
        for m in re.finditer(rf'\b({PREFIXES}):([A-Za-z0-9_]+)', txt):
            found.setdefault(f"{m.group(1)}:{m.group(2)}", set()).add(os.path.basename(os.path.dirname(f)))
        for m in re.finditer(rf'\be_({PREFIXES})_([A-Za-z0-9]+)\b', txt):
            found.setdefault(f"{m.group(1)}:{m.group(2)}", set()).add(os.path.basename(os.path.dirname(f)))
    # Rel values written as ⟨.ro, 2215, false⟩ in the stress file are RO ids too
    return found


def main():
    found = collect()
    rows = []
    for c in sorted(found):
        pre = c.split(":")[0]
        if pre in ("BLN", "BIOLEAN"):
            rows.append((c, "(placeholder, no ontology term)", "placeholder", ""))
            continue
        if pre in ("RO", "BFO"):
            rows.append(gaps_ols.prop(c))
        else:
            rows.append(gaps_ols.term(c))
    with open(OUT, "w") as f:
        f.write("curie\tlabel\tstatus\tdefinition\tused_in\n")
        for r in rows:
            f.write("\t".join(list(r) + [",".join(sorted(found[r[0]]))]) + "\n")
    bad = [r for r in rows if r[2] not in ("live", "placeholder")]
    print(f"{len(rows)} curies, {sum(r[2] == 'live' for r in rows)} live, "
          f"{sum(r[2] == 'placeholder' for r in rows)} placeholders, {len(bad)} other")
    for r in bad:
        print("  ", "\t".join(r[:3]))


if __name__ == "__main__":
    main()
