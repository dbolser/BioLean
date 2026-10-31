"""Program 09: check every CURIE the chemiosmosis stress file and doc use, on OLS4.

Writes data/stress/09/curies_checked.tsv (curie, label on OLS4, obsolete flag). Downloads are
cached in /tmp/biolean-09/dl2/ and are untrusted: run with `python3 -I`.

    python3 -I scripts/stress/chemiosmosis_ols.py <repo root>
"""
import json
import os
import sys
import urllib.parse
import urllib.request

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
DL = "/tmp/biolean-09/dl2"
CURIES = ["GO:0022904", "GO:0006119", "GO:0015990", "GO:0015986", "GO:0010248", "GO:0009777",
          "GO:0005743", "GO:0004775", "GO:0045259", "CHEBI:15378", "CHEBI:15422", "CHEBI:42017",
          "CHEBI:26048", "CHEBI:18847", "CHEBI:19855", "NCBITaxon:3562", "NCBITaxon:10116", "NCBITaxon:2242",
          "NCBITaxon:9913", "GO:0005758", "GO:0009535", "GO:0009767", "GO:0042717",
          "CHEBI:29108", "CHEBI:32588", "CHEBI:3312", "NCBITaxon:1061", "NCBITaxon:10090",
          "CHEBI:26523", "RO:0001025", "RO:0002219", "SEPIO:0000008", "SEPIO:0000009", "SEPIO:0000101"]


def lookup(curie):
    path = os.path.join(DL, "ols_" + curie.replace(":", "_") + ".json")
    if not os.path.exists(path):
        url = "https://www.ebi.ac.uk/ols4/api/terms?" + urllib.parse.urlencode(
            {"obo_id": curie})
        raw = urllib.request.urlopen(url, timeout=40).read()
        with open(path, "wb") as f:
            f.write(raw)
    with open(path) as f:
        terms = json.load(f).get("_embedded", {}).get("terms", [])
    if not terms:
        # object properties (RO, SEPIO) are not under /terms
        path_p = path.replace("ols_", "olsprop_")
        if not os.path.exists(path_p):
            url = "https://www.ebi.ac.uk/ols4/api/properties?" + urllib.parse.urlencode({"obo_id": curie})
            raw = urllib.request.urlopen(url, timeout=40).read()
            with open(path_p, "wb") as f:
                f.write(raw)
        with open(path_p) as f:
            terms = json.load(f).get("_embedded", {}).get("properties", [])
    defining = [t for t in terms if t.get("is_defining_ontology")] or terms
    return defining[0] if defining else None


def main():
    rows = []
    for c in CURIES:
        t = lookup(c)
        rows.append((c, t.get("label", "") if t else "NOT FOUND",
                     str(t.get("is_obsolete", "")) if t else "", t.get("ontology_name", "") if t else ""))
    with open(os.path.join(ROOT, "data/stress/09/curies_checked.tsv"), "w") as f:
        f.write("curie\tols4_label\tobsolete\tontology\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    for r in rows:
        print("\t".join(r))


if __name__ == "__main__":
    main()
