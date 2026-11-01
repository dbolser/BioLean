"""Program 05: find textbook sentences that use grade terms and show their current encoding.

Reads data/textbook/claims_m2 and claims_m3 (read only) and the compiled Lean names in
BioLean/Lib/TextbookClaimsR2 and R3 (read only). Writes data/stress/05/survey.tsv and prints counts.
"""
import collections
import glob
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/05"

TERMS = {
    "prokaryote": r"prokaryo",
    "protist": r"protist|protozo",
    "algae": r"\balga[el]?\b|\balgal\b",
    "invertebrate": r"invertebrat",
    "microbe": r"microb|micro-organism|microorganism",
    "fish": r"\bfish(es)?\b",
    "reptile": r"\breptil",
    "plant": r"\bplants?\b",
    "animal": r"\banimals?\b",
    "animal cell": r"animal cells?\b",
    "plant cell": r"plant cells?\b",
}


def load(d):
    recs = {}
    for f in sorted(glob.glob(str(ROOT / f"data/textbook/{d}/*.json"))):
        for r in json.load(open(f)):
            recs[r["id"]] = r
    return recs


def lean_names():
    """Statement ids defined in compiled R2 and R3 Lean, with their claim line."""
    out = {}
    for rnd in ("R2", "R3"):
        for f in sorted(glob.glob(str(ROOT / f"BioLean/Lib/TextbookClaims{rnd}/*.lean"))):
            if f.endswith("Entities.lean"):
                continue
            mod = pathlib.Path(f).stem
            txt = open(f).read()
            for m in re.finditer(r'def (\w+) : Statement where\n  id := "([^"]+)"\n  text := "((?:[^"\\]|\\.)*)"\n  claim := (.*)\n', txt):
                out.setdefault(m.group(2), []).append((rnd, mod, m.group(1), m.group(4)))
    return out


def main():
    m2 = load("claims_m2")
    m3 = load("claims_m3")
    lean = lean_names()
    sent_hits = collections.defaultdict(set)
    rows = []
    for i, r in m2.items():
        src = r["source"]
        hit = [t for t, p in TERMS.items() if re.search(p, src, re.I)]
        if not hit:
            continue
        for t in hit:
            sent_hits[t].add(src)
        enc = (m3.get(i) or {}).get("m3") or r.get("m2") or {}
        ctx = enc.get("context") or {}
        ents = ";".join(f"{e.get('text')}={e.get('curie')}" for e in r["entities"])
        L = lean.get(i, [])
        rows.append({
            "id": i, "terms": ",".join(hit), "source": src, "claim": r["claim"],
            "ctor": enc.get("ctor"), "subject": enc.get("subject"), "relation": enc.get("relation"),
            "object": enc.get("object"), "taxon": ctx.get("taxon"), "cellType": ctx.get("cellType"),
            "quant": enc.get("quant"), "blocker": enc.get("blocker"),
            "round": "m3" if i in m3 and m3[i].get("m3") else "m2",
            "lean": ";".join(f"{a}.{b}.{c}" for a, b, c, _ in L),
            "lean_claim": " | ".join(d for *_, d in L), "entities": ents,
        })
    keys = list(rows[0].keys())
    with open(OUT / "survey.tsv", "w") as f:
        f.write("\t".join(keys) + "\n")
        for row in rows:
            f.write("\t".join(str(row[k] or "").replace("\t", " ").replace("\n", " ") for k in keys) + "\n")
    print("distinct sentences in book:", len({r["source"] for r in m2.values()}))
    for t in TERMS:
        recs = [r for r in rows if t in r["terms"].split(",")]
        lean_n = sum(1 for r in recs if r["lean"])
        print(f"{t:14s} sentences {len(sent_hits[t]):4d}  records {len(recs):4d}  compiled {lean_n:4d}")
    # how is 'prokaryote' grounded?
    ground = collections.Counter()
    for r in rows:
        for e in m2[r["id"]]["entities"]:
            tx = (e.get("text") or "").lower()
            for t, p in TERMS.items():
                if re.search(p, tx, re.I):
                    ground[(t, e.get("curie"))] += 1
    print("\ngrounding of the mention itself (entity text -> curie):")
    for (t, c), n in sorted(ground.items(), key=lambda x: (x[0][0], -x[1])):
        print(f"  {t:14s} {str(c):22s} {n}")
    # what taxon/cellType the encoding used when a grade term is in the sentence
    used = collections.Counter()
    for r in rows:
        for t in r["terms"].split(","):
            used[(t, r["subject"] if (r["subject"] or "").startswith(("CL:", "NCBITaxon:")) else None, r["taxon"], r["cellType"])] += 1
    print("\nencoding (term, CL/taxon subject, ctx taxon, ctx cellType) for grade sentences:")
    for k, n in used.most_common(60):
        print(" ", k, n)


if __name__ == "__main__":
    main()
