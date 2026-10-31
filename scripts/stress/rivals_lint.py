"""A lint for rivalries (program 03, options A and I). Data only: it reads rivals_spec.py and
changes nothing in the core. Each check is one curation rule from docs/programs/03-rivals-and-hypotheses.md.

  L1 duplicate rival        the same rival (id or claim) listed twice                       (S09)
  L2 double entry           one item (same key) entered on two or more rivals               (rule 1)
  L3 two support votes      one item supporting two rivals: a partial vote forced into a rivalry (rule 2)
  L4 same PMID twice        one statement cites a PMID twice; the core keeps only the first (R01c)
  L5 mixed contexts         rivals with different subject contexts (Entity.inCtx)            (rule 3)
  L6 not one slot           rival claims differ in more than one place: maybe not rivals     (rule 5)
  L7 different agents       effect claims with different agents: possible co-causes          (rule 5)
  L8 empty rival            a rival with no items is refuted by the others and never raised
  L9 P against not-P        a rivalry of a claim and its negation: use one Statement         (rule 4)

Nesting (one rival refines another, R06, R08d) is not checked: 30 of the 34 BLN placeholders in the
set are theory terms with no ontology parents, so there is nothing to test is_a against.

Usage: python3 scripts/stress/rivals_lint.py   (writes data/stress/03/lint.tsv)
"""
import csv, json, os, sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from rivals_spec import CASES, PYEV, A1V

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
DATA = os.path.join(ROOT, "data", "stress", "03")


def ctx(claim):
    return claim[0].partition("@")[2] or None


def base(claim):
    return (claim[0].partition("@")[0].replace("not", "").lower(),) + tuple(claim[1:])


def lint(rivals):
    flags = []
    ids = Counter(r["rid"] for r in rivals)
    claims = Counter(tuple(r["claim"]) for r in rivals)
    if any(v > 1 for v in ids.values()) or any(v > 1 for v in claims.values()):
        flags.append(("L1", "duplicate rival: " + ", ".join(k for k, v in ids.items() if v > 1)))
    where = {}
    for r in rivals:
        for e in r["ev"]:
            where.setdefault(e["key"], []).append((r["rid"], e["pol"], e["kind"]))
    dbl = {k: v for k, v in where.items() if len({x[0] for x in v}) > 1 and any(x[2] != "hypothesis" for x in v)}
    if dbl:
        flags.append(("L2", f"{len(dbl)} item(s) on two or more rivals: " + ", ".join(sorted(dbl)[:6])))
    two = [k for k, v in where.items() if sum(1 for x in v if x[1] == "+" and x[2] != "hypothesis") > 1]
    if two:
        flags.append(("L3", "supports two rivals: " + ", ".join(two[:6])))
    for r in rivals:
        pm = Counter(e["pmid"] for e in r["ev"] if e["pmid"])
        rep = [p for p, n in pm.items() if n > 1]
        if rep:
            pols = {p: {e["pol"] for e in r["ev"] if e["pmid"] == p} for p in rep}
            flags.append(("L4", f"{r['rid']}: PMID {', '.join(str(p) for p in rep)} twice"
                          + (" with opposite polarity" if any(len(v) > 1 for v in pols.values()) else "")))
    cs = {ctx(r["claim"]) for r in rivals}
    if len(cs) > 1:
        flags.append(("L5", "contexts differ: " + ", ".join(sorted(str(c) for c in cs))))
    bs = [base(r["claim"]) for r in rivals]
    if len({b[0] for b in bs}) == 1 and len(bs) == 2 and bs[0] == bs[1] and rivals[0]["claim"][0] != rivals[1]["claim"][0]:
        flags.append(("L9", "a claim and its negation: enter as one Statement"))
    else:
        for i in range(len(bs)):
            for j in range(i + 1, len(bs)):
                if len(bs[i]) == len(bs[j]):
                    diff = sum(1 for a, b in zip(bs[i], bs[j]) if a != b)
                    if diff > 1:
                        flags.append(("L6", f"{rivals[i]['rid']} and {rivals[j]['rid']} differ in {diff} places"))
        eff = [r for r in rivals if r["claim"][0].startswith("effect")]
        if len({r["claim"][1] for r in eff}) > 1:
            flags.append(("L7", "different agents for one effect: " + ", ".join(r["rid"] for r in eff)))
    for r in rivals:
        if not r["ev"]:
            flags.append(("L8", f"{r['rid']} has no items"))
    return flags


def main():
    sc = json.load(open(os.path.join(DATA, "scores.json"))) if os.path.exists(os.path.join(DATA, "scores.json")) else {}
    rows = []
    for c in CASES:
        cid = c["id"]
        for v, spec in c["variants"].items():
            rivals = None
            if spec[0] == "rivalry": rivals = spec[1]
            elif spec[0] == "repo" and (cid, v) in PYEV: rivals = PYEV[(cid, v)]
            elif spec[0] == "glp1" and spec[1] == "rivalry": rivals = PYEV[(cid, v)]
            elif spec[0] == "stmt": rivals = spec[1]
            if rivals is None: continue
            fl = lint(rivals) if spec[0] != "stmt" else [f for f in lint(rivals) if f[0] == "L4"]
            a1 = (v == "split") if cid == "S05" else (v == A1V[cid] or cid == "R01c")
            rows.append((cid, v, "yes" if a1 else "", sc.get(cid, {}).get("A1", ["", ""])[0] if a1 else "",
                         " ".join(f[0] for f in fl), "; ".join(f"{f[0]} {f[1]}" for f in fl)))
    with open(os.path.join(DATA, "lint.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["case", "encoding", "A1 encoding", "A1 mark", "flags", "detail"])
        w.writerows(rows)
    a1 = [r for r in rows if r[2]]
    fails = [r for r in a1 if r[3] == "FAIL"]
    caught = [r for r in fails if r[4]]
    print(f"{len(rows)} encodings linted; {sum(1 for r in rows if r[4])} flagged")
    print(f"A1 FAIL encodings: {len(fails)}; flagged by the lint: {len(caught)}")
    for r in fails: print("  ", r[0], r[1], "->", r[4] or "NOT FLAGGED")
    ok = [r for r in a1 if r[3] == "PASS" and r[4]]
    print(f"A1 PASS encodings that are flagged anyway: {len(ok)}: " + ", ".join(f"{r[0]} ({r[4]})" for r in ok))


if __name__ == "__main__":
    main()
