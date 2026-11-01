"""Program 10a: tables of checked identifiers.

Reads the Europe PMC metadata (weights_epmc_fetch.py) and the OLS4/Crossref lookups
(weights_ids_fetch.py), and every PMID and CURIE cited in BioLean/Stress/Weights.lean and the program
doc. Writes data/stress/10a/references_checked.tsv and data/stress/10a/curies_checked.tsv. A PMID not
found on Europe PMC is written as UNVERIFIED. Downloads are untrusted data: run with `python3 -I`.

Also collects the PMIDs of the example statements the cases use (GLP1Statements, Context,
Chemiosmosis), since the cases rest on them.

usage: python3 -I scripts/stress/weights_refs.py EPMC.json IDS.json
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEAN = ROOT / "BioLean/Stress/Weights.lean"
DOC = ROOT / "docs/programs/10a-evidence-weights.md"
OUT = ROOT / "data/stress/10a"
SPEC = OUT / "case_spec.json"
EXAMPLES = [ROOT / "BioLean/Lib/GLP1Statements.lean", ROOT / "BioLean/Examples/Context.lean",
            ROOT / "BioLean/Examples/Chemiosmosis.lean"]
SYNTHETIC = re.compile(r"^(70000001|8\d{7}|9\d{7})$")


def cited_pmids():
    lean = LEAN.read_text()
    found = set(re.findall(r"\bev (\d{6,8})\b", lean))
    found |= set(re.findall(r"pmid != (\d{6,8})", lean))
    found |= set(re.findall(r"PMID:(\d{6,8})", lean))
    # side tables: (pmid, ...) pairs and plain lists
    for block in re.findall(r"def (?:retracted|pools|metaOfObs|metaOfAnimal|curatedGroup|autoGroup) :.*?(?=\n\n|\ndef |\n/--)", lean, re.S):
        found |= set(re.findall(r"\b(\d{6,8})\b", block))
    sizes = re.search(r"def sizes :.*?(?=\n\n|\n/--)", lean, re.S)
    if sizes:  # (pmid, participants) pairs: only the first number is a PMID
        found |= set(re.findall(r"\((\d{6,8}), \d+\)", sizes.group(0)))
    if DOC.exists():
        found |= set(re.findall(r"PMID:(\d{6,8})", DOC.read_text()))
        for m in re.findall(r"PMID:\d{6,8}((?:, \d{6,8})+)", DOC.read_text()):
            found |= set(re.findall(r"\d{6,8}", m))
    for f in EXAMPLES:
        found |= set(re.findall(r"pmid := (\d{6,8})", f.read_text()))
    found |= set(re.findall(r"PMID:(\d{6,8})", SPEC.read_text()))
    for m in re.findall(r"PMID:\d{6,8}((?:, \d{6,8})+)", SPEC.read_text()):
        found |= set(re.findall(r"\d{6,8}", m))
    return sorted((p for p in found if not SYNTHETIC.match(p)), key=int)


def cited_curies():
    text = LEAN.read_text() + (DOC.read_text() if DOC.exists() else "") + SPEC.read_text()
    pat = r"\b(?:CHEBI|GO|HP|CL|UBERON|NCBITaxon|PR|PATO|VO|RO|ECO|OBCS|OBI|SEPIO):\d+\b|\bNCIT:C\d+\b"
    return sorted(set(re.findall(pat, text)))


def main():
    if sys.argv[1] == "--lists":  # write the identifiers to look up, one per line
        d = Path(sys.argv[2])
        (d / "pmids.txt").write_text("\n".join(cited_pmids()) + "\n")
        (d / "curies.txt").write_text("\n".join(cited_curies()) + "\n")
        print(f"{len(cited_pmids())} PMIDs, {len(cited_curies())} CURIEs")
        return
    epmc = json.load(open(sys.argv[1]))
    ids = json.load(open(sys.argv[2]))
    OUT.mkdir(parents=True, exist_ok=True)
    rows, missing = [], []
    for p in cited_pmids():
        v = epmc.get(p)
        if not v:
            missing.append(p)
            rows.append([p, "", "", "", "UNVERIFIED: not found on Europe PMC", "", "", "", "no"])
            continue
        au = v.get("authors") or [""]
        pts = v.get("pubtypes") or []
        retr = "yes" if "Retracted Publication" in pts else ""
        rows.append([p, v.get("year") or "", au[0], au[-1], (v.get("title") or "").replace("\t", " "),
                     v.get("journal") or "", "; ".join(pts), retr, "yes"])
    with open(OUT / "references_checked.tsv", "w") as f:
        f.write("pmid\tyear\tfirst_author\tlast_author\ttitle\tjournal\tpublication_types\tretracted\tchecked\n")
        for r in rows:
            f.write("\t".join(str(x) for x in r) + "\n")
        for d, v in ids.get("dois", {}).items():
            f.write("\t".join([f"doi:{d}", str(v.get("year", "")), v.get("first", ""), "", v.get("title", ""),
                               v.get("container", ""), "Crossref", "", "yes" if v.get("found") else "no"]) + "\n")
    cur = ids.get("curies", {})
    bad = []
    with open(OUT / "curies_checked.tsv", "w") as f:
        f.write("curie\tlabel\tontology\tobsolete\tchecked\n")
        for c in cited_curies():
            v = cur.get(c)
            if not v or not v.get("found"):
                bad.append(c)
                f.write(f"{c}\t\t\t\tUNVERIFIED\n")
            else:
                f.write(f"{c}\t{v.get('label')}\t{v.get('ontology')}\t{v.get('obsolete')}\tyes\n")
    print(f"{len(rows)} PMIDs ({len(missing)} not found: {missing}); {len(cited_curies())} CURIEs ({bad} unchecked)")
    print("retracted:", [r[0] for r in rows if r[7] == "yes"])


if __name__ == "__main__":
    main()
