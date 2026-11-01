"""Program 08 survey: find textbook sentences on the three schema gaps.

Reads data/textbook/claims*/ (repo data) and the textbook Lean sources and oleans.
Writes only to data/stress/08/. Run from the repo root:

    python3 scripts/stress/gaps_survey.py

Outputs
  data/stress/08/survey_disjunction.tsv   'either ... or' sentences and records binned disjunction
  data/stress/08/survey_approx.tsv        'about n', 'approximately n', 'roughly n', 'around n'
  data/stress/08/survey_context.tsv       round-3 records with two or more context fields, or a
                                          condition, plus sentences with a damaged / mutant state
"""

import collections
import glob
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "stress", "08")

NUM = r"(\d[\d,\.]*|one|two|three|four|five|six|seven|eight|nine|ten|twelve|twenty|thirty|forty|fifty|a (?:few|hundred|thousand|million|billion|third|quarter|half)|half|hundreds?|thousands?|millions?|billions?)"
APPROX = re.compile(r"\b(approximately|about|roughly|around|nearly|almost|an estimated|estimated at|some)\s+" + NUM, re.I)
EITHER = re.compile(r"\beither\b[^.;]*\bor\b", re.I)
STATE = re.compile(r"\b(damaged|mutated|mutant|defective|diseased|infected|starved|deprived|absence of|presence of|exposed to)\b", re.I)


def load(pattern):
    recs = []
    for f in sorted(glob.glob(os.path.join(ROOT, pattern))):
        recs += json.load(open(f))
    return recs


def lean_index():
    """id -> (round, in current source, in built olean)."""
    idx = {}
    for rnd in ("R2", "R3"):
        for src in glob.glob(os.path.join(ROOT, f"BioLean/Lib/TextbookClaims{rnd}/*.lean")):
            name = os.path.basename(src)[:-5]
            olean = os.path.join(ROOT, f".lake/build/lib/lean/BioLean/Lib/TextbookClaims{rnd}/{name}.olean")
            obytes = open(olean, "rb").read() if os.path.exists(olean) else b""
            for m in re.finditer(r'id := "([^"]+)"', open(src).read()):
                i = m.group(1)
                built = i.encode() in obytes
                idx.setdefault(i, []).append(f"{rnd}:{name}{'' if built else '(not built)'}")
    return idx


def main():
    os.makedirs(OUT, exist_ok=True)
    r1 = load("data/textbook/claims/*.json")
    m2 = load("data/textbook/claims_m2/*.json")
    m3 = load("data/textbook/claims_m3/*.json")
    m2by = {r["id"]: r for r in m2}
    m3by = {r["id"]: r for r in m3}
    lean = lean_index()
    bysent = collections.defaultdict(list)
    for r in r1:
        bysent[r["source"]].append(r)
    print("sentences", len(bysent), "records", len(r1), "m3", len(m3))

    def row(sent, recs):
        ids = [r["id"] for r in recs]
        info = []
        for r in recs:
            i = r["id"]
            a = (m2by.get(i, {}).get("m2") or {})
            b = (m3by.get(i, {}).get("m3") or {})
            info.append("|".join([
                i, r.get("bin") or "", r.get("missing_construct") or "",
                f"m2={a.get('ctor')}/{a.get('blocker')}",
                f"m3={b.get('ctor')}/{b.get('blocker')}" if b else "m3=-",
                ";".join(lean.get(i, [])) or "nolean",
                (r["claim"] or "").replace("\t", " ")]))
        return [";".join(ids), sent.replace("\t", " "), " || ".join(info)]

    # 1 disjunction
    rows = []
    for sent, recs in bysent.items():
        binned = any((r.get("missing_construct") == "disjunction") or
                     ((m2by.get(r["id"], {}).get("m2") or {}).get("blocker") == "disjunction") or
                     ((m3by.get(r["id"], {}).get("m3") or {}).get("blocker") == "disjunction") for r in recs)
        hit = EITHER.search(sent)
        if hit or binned:
            rows.append(["either" if hit else "binned"] + row(sent, recs))
    write("survey_disjunction.tsv", ["trigger", "ids", "sentence", "records"], rows)

    # 2 approximate
    rows = []
    for sent, recs in bysent.items():
        m = APPROX.search(sent)
        if m:
            rows.append([m.group(0)] + row(sent, recs))
    write("survey_approx.tsv", ["trigger", "ids", "sentence", "records"], rows)

    # 3 multi-context
    rows = []
    for r in m3:
        c = (r.get("m3") or {}).get("context") or {}
        filled = [k for k, v in c.items() if v]
        cond = c.get("condition")
        if len(filled) >= 2 or cond:
            rows.append(["ctx:" + ",".join(filled)] + row(r["source"], [r]) + [json.dumps(c)])
    seen = set(x[1] for x in rows)
    for sent, recs in bysent.items():
        m = STATE.search(sent)
        if m:
            ids = ";".join(x["id"] for x in recs)
            if ids not in seen:
                rows.append(["state:" + m.group(0)] + row(sent, recs) + [""])
    write("survey_context.tsv", ["trigger", "ids", "sentence", "records", "m3context"], rows)


def write(name, head, rows):
    with open(os.path.join(OUT, name), "w") as f:
        f.write("\t".join(head) + "\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    print(name, len(rows))


if __name__ == "__main__":
    main()
