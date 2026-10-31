"""Mark program 03's stress set and write data/stress/03/cases.tsv and friends.

Every mark is computed from what Lean printed (data/stress/03/observed_*.json, written by
rivals_run.py), except D1, which comes from the Python mirror (rivals_mirror.py; it agrees with Lean
on every value Lean prints). A case is marked at every year EXPY lists, plus its special rule:
FAIL if any verdict is wrong, else SILENT if any due verdict is missing (unsupported), else PASS.
INEXPRESSIBLE when the current core cannot state the premise the right answer rests on (INEXPR).

Options scored:
  A1      current core, evidence entered as the worked example does (each item on every rival it bears on)
  A2      current core, best curation today (each item once; contexts split; co-causes kept apart)
  A2H     A2 plus option H (a withdrawal year) emulated outside the core (review stage)
  D1      A1 with a dependence-aware Rivalry (Python only)
  B1 B2 B3  the frame prototype read three ways, on the frame as first written
  B2best  B2 with the same best curation as A2
  E1:w    A2 with the hypothesis kind at weight w (Lean, `hypModel`)

Usage: python3 scripts/stress/rivals_score.py
"""
import csv, json, os, sys
from collections import Counter
from fractions import Fraction as F

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rivals_mirror as M
from rivals_spec import CASES, C, ENT, EXPY, RULE, INEXPR, A1V, FB, PYEV, best_frames, withdrawals

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
DATA = os.path.join(ROOT, "data", "stress", "03")
CUR = json.load(open(os.path.join(DATA, "observed_current.json")))
PRO = json.load(open(os.path.join(DATA, "observed_proto.json")))
RANK = {"PASS": 0, "SILENT": 1, "FAIL": 2, "INEXPRESSIBLE": 3}
E1TAGS = ["h1/10", "h1/5", "h3/10"]
OPTS = ["A1", "A2", "A2H", "D1", "B1", "B2", "B3", "B2best"] + [f"E1:{t[1:]}" for t in E1TAGS]

A1SET = {c["id"]: [A1V[c["id"]]] for c in CASES}
A1SET["R01c"] = ["gen1-first", "gen2-first", "both-findings"]


def rows_core(tag, cid, variant, y):
    return [(r, F(b), F(d), v) for r, b, d, v in CUR[tag][cid][variant][str(y)]]


def a2_variants(cid):
    if cid == "R23": return ["repo-separate:S9c", "repo-separate:S9d"]
    return [v for v in CUR["std"][cid] if v.startswith("A2:") and v != "A2:u"]


def with_negation(cid, rows):
    """A P-against-not-P case encoded as one Statement: not-P is its negation."""
    fr = C[cid].get("frame") or {}
    if fr.get("pair") and len(rows) == 1:
        p, notp = fr["cells"]
        r, b, d, v = rows[0]
        rows = rows + [(notp, d, b, M.verdict(d, b))]
    return rows


def get(opt, cid, y):
    """Rows (rival, belief, disbelief, verdict) for one option, case and year."""
    if opt == "A1" or opt.startswith("A1@"):
        tag = opt.split("@")[1] if "@" in opt else "std"
        return [r for v in A1SET[cid] for r in rows_core(tag, cid, v, y)]
    if opt == "A2" or opt.startswith("E1:"):
        tag = "std" if opt == "A2" else "h" + opt.split(":")[1]
        return with_negation(cid, [r for v in a2_variants(cid) for r in rows_core(tag, cid, v, y)])
    if opt == "A2H":
        hv = [v for v in CUR["std"][cid] if v.startswith("A2H:")]
        if not hv: return get("A2", cid, y)
        return with_negation(cid, [r for v in hv for r in rows_core("std", cid, v, y)])
    if opt == "D1":
        out = []
        for v, kind, rivals in M.encodings(cid):
            if v in A1SET[cid]:
                out += [(r, b, d, vd) for r, b, d, vd in M.core_rows(kind, rivals, y, M.model(), shared_aware=True)]
        return out
    if opt in ("B1", "B2", "B3"):
        if not C[cid].get("frame"): return get("A2", cid, y)      # R23: no frame; separate statements
        return rows_proto(opt, cid, "plain", y)
    if opt == "B2best":
        if not C[cid].get("frame"): return get("A2", cid, y)
        return [r for lab in best_labels(cid) for r in rows_proto("B2", cid, lab, y, solo=lab_is_solo(cid, lab))]
    raise ValueError(opt)


def rows_proto(model, cid, label, y, solo=False):
    rows = [(r["cell"], F(r[model][0]), F(r[model][1]), r[model][2]) for r in PRO[cid][label][str(y)]]
    return [r for r in rows if r[0] != "not"] if solo else rows


def best_labels(cid):
    frames = best_frames(cid)
    if cid in FB: return [f"best:{k}" for k in range(len(frames))]
    return ["plain"] + [f"best:{k}" for k, f in enumerate(frames) if k > 0 or f.get("solo")]


def lab_is_solo(cid, lab):
    if not lab.startswith("best:"): return False
    return bool(best_frames(cid)[int(lab.split(":")[1])].get("solo"))


def worse(a, b):
    return a if RANK[a] >= RANK[b] else b


def show(rows):
    return "; ".join(f"{r} {v} ({b}, {d})" for r, b, d, v in rows)


def by_expy(opt, cid):
    mark, notes = "PASS", []
    for y, exp in EXPY.get(cid, {}).items():
        rows = get(opt, cid, y)
        for rid, ok in exp.items():
            hits = [r for r in rows if r[0] == rid] or [(rid, F(0), F(0), "unsupported")]
            for r in hits:
                if r[3] in ok: continue
                m = "SILENT" if r[3] == "unsupported" else "FAIL"
                notes.append(f"{y} {rid}: {r[3]}, want {' or '.join(sorted(ok))}")
                mark = worse(mark, m)
    return mark, notes


def cell(rows, rid):
    return next((r for r in rows if r[0] == rid), (rid, F(0), F(0), "unsupported"))


def special(opt, cid):
    """(mark, note) from a case's special rule, or None."""
    fam = "A" if opt[0] in "AE" or opt == "D1" else "B"
    if cid == "R03b":
        if fam == "A":
            a, b = get(opt, cid, 2022), get(opt, cid, 2023)
        elif opt == "B2best":
            a, b = get(opt, cid, 2022), get(opt, cid, 2023)
        else:
            a, b = get(opt, cid, 2022), get(opt, cid, 2023)
        same = [(r[1], r[2]) for r in a] == [(r[1], r[2]) for r in b]
        return ("PASS", "2023 equals 2022") if same else ("FAIL", "the ctenophore paper moves the vertebrate numbers")
    if cid == "R11b":
        if fam == "A" and opt != "A2H": return None
        a, b = get(opt, cid, 2023), get(opt, cid, 2025)
        r = cell(b, "amyloid causes AD")
        if r[3] == "contested" and [(x[1], x[2]) for x in a] != [(x[1], x[2]) for x in b]:
            return ("PASS", "Lesne stops counting in 2024; still contested")
        return ("FAIL", "Lesne still counts or the dispute is lost")
    if cid == "R12":
        r = cell(get(opt, cid, 1899), "particulate")
        if r[1] > 0 and r[3] == "unsupported": return ("PASS", f"1899 particulate ({r[1]}, {r[2]}) unsupported")
        if r[1] == 0: return ("SILENT", "1899: Mendel's data count for nothing (belief 0)")
        return ("FAIL", f"1899 particulate {r[3]}")
    if cid == "R22":
        r = cell(get(opt, cid, 2011), "mutational deterministic")
        if r[2] > F(1, 4): return ("FAIL", f"mutation purging gets disbelief {r[2]} from Red Queen support")
        return None
    if cid == "S05":
        if opt == "A2H": opt = "A2"     # S05 has no withdrawal: A2H is A2
        if fam == "A" and opt != "D1":
            tag = "std" if opt in ("A1", "A2") else "h" + opt.split(":")[1]
            if opt == "A1": a, b = rows_core(tag, cid, "unsplit", 2000), rows_core(tag, cid, "split", 2000)
            else: a, b = rows_core(tag, cid, "A2:u", 2000), rows_core(tag, cid, "A2:0", 2000)
        elif opt == "D1":
            enc = {v: (k, r) for v, k, r in M.encodings(cid)}
            a = M.core_rows(*enc["unsplit"], 2000, M.model(), True)
            b = M.core_rows(*enc["split"], 2000, M.model(), True)
        else:
            model = "B2" if opt == "B2best" else opt
            a, b = rows_proto(model, cid, "unsplit", 2000), rows_proto(model, cid, "plain", 2000)
        ra, rb = cell(a, "A"), cell(b, "A")
        if (ra[1], ra[2]) == (rb[1], rb[2]): return ("PASS", f"A unchanged ({ra[1]}, {ra[2]})")
        return ("FAIL", f"A moves from ({ra[1]}, {ra[2]}) to ({rb[1]}, {rb[2]})")
    if cid == "S07":
        if fam == "A": return None
        P = [F(r["B2"][3]) for r in PRO[cid]["plain"]["2000"]]
        return ("PASS", f"P = {', '.join(map(str, P))}") if sum(P) == 1 else ("FAIL", f"P sums to {sum(P)}")
    if cid == "R01c":
        rows = get(opt, cid, 1958)
        bad = [r for r in rows if r[0] == "dispersive" and not (r[1] == 0 and r[2] > 0)]
        if bad: return ("FAIL", "dispersive " + "; ".join(f"({r[1]}, {r[2]}) {r[3]}" for r in bad))
        return ("PASS", "dispersive belief 0, disbelief above 0")
    if cid == "R23":
        # review stage: the pluralism test of R22, applied to both statements against each alone
        tag = "h" + opt.split(":")[1] if opt.startswith("E1:") else "std"
        rows = get(opt, cid, 2026)
        for rid in ("S9c", "S9d"):
            own = rows_core(tag, cid, f"repo-separate:{rid}", 2026)[0]
            r = cell(rows, rid)
            if r[2] - own[2] > F(1, 4):
                return ("FAIL", f"{rid} disbelief rises from {own[2]} to {r[2]} because of the other")
        return None
    if cid == "S11":
        if fam == "A": return None
        r = cell(get(opt, cid, 2000), "A")
        return ("PASS", f"A belief {r[1]}") if r[1] > 0 else ("SILENT", "A belief 0: partial exclusions not combined")
    return None


def score_key_year(opt, cid):
    """The mark when only the case's key year is scored (plus its special rule)."""
    key, saved = C[cid]["key"], EXPY.get(cid, {})
    EXPY[cid] = {y: v for y, v in saved.items() if y == key}
    try:
        return score(opt, cid)[0]
    finally:
        EXPY[cid] = saved


def score(opt, cid):
    if (opt[0] in "AE" or opt == "D1") and cid in INEXPR and not (opt == "A2H" and cid == "R11b"):
        return "INEXPRESSIBLE", [f"cannot state {INEXPR[cid]}"]
    mark, notes = by_expy(opt, cid)
    sp = special(opt, cid)
    if sp:
        mark = worse(mark, sp[0])
        notes.append(sp[1])
    return mark, notes


# ---------------------------------------------------------------- rendering

def curie(n):
    return ENT[n][1]


def claim_text(cl):
    op = cl[0]
    base, _, ctx = op.partition("@")
    sub = lambda n: curie(n) + (f" in_taxon {curie(ctx)}" if ctx else "")
    if base == "chemio":
        return "GO:0022904 ->+ GO:0006119 via " + {"cm": "CHEBI:15378", "ci": "BLN:C~I", "cc": "BLN:conformational-coupling"}[cl[1]]
    if base == "glp1":
        return "CHEBI:167574 ->- GO:0007631 via site " + {"c": "UBERON:0001898", "d": "UBERON:0002162"}[cl[1]]
    rel = {"isA": "is_a", "notIsA": "NOT is_a", "rel2150": "RO:0002150", "notRel2150": "NOT RO:0002150",
           "rel1000": "RO:0001000", "hasPart": "BFO:0000051", "occursIn": "BFO:0000066", "notOccursIn": "NOT BFO:0000066"}
    if base in rel:
        if base in ("occursIn", "notOccursIn"):
            return f"{curie(cl[1])} {rel[base]} {curie(cl[2])}" + (f" (subject in_taxon {curie(ctx)})" if ctx else "")
        return f"{sub(cl[1])} {rel[base]} {curie(cl[2])}"
    if base == "effect+": return f"{curie(cl[1])} ->+ {curie(cl[2])}"
    if base in ("medBy", "medByAct"): return f"{curie(cl[1])} ->+ {curie(cl[2])} via {curie(cl[3])}"
    return str(cl)


def ev_text(e):
    who = str(e["pmid"]) if e["pmid"] else e["key"]
    return f"{who} {e['year']} {e['kind']}{'' if e['pol'] == '+' else ' -'}"


def input_text(cid):
    parts = []
    enc = {v: r for v, k, r in M.encodings(cid)}
    for v in A1SET[cid]:
        rivals = enc[v]
        parts.append(f"[{v}] " + "; ".join(f"{r['rid']} = {claim_text(r['claim'])} {{{', '.join(ev_text(e) for e in r['ev'])}}}" for r in rivals))
    fr = C[cid].get("frame")
    if fr:
        parts.append(f"[frame, {'open' if fr['open'] else 'closed'}] " + "; ".join(
            f"{(it['pmid'] or it['key'])}{'#' + str(it['finding']) if it.get('finding') else ''} {it['year']} {it['kind']} favours {{{', '.join(it['fav'])}}}"
            + (f" withdrawn {it['until']}" if it.get("until") else "") for it in fr["items"]))
    return " | ".join(parts)


def correct_text(cid):
    exp = "; ".join(f"{y}: " + ", ".join(f"{r} {' or '.join(sorted(v))}" for r, v in d.items()) for y, d in EXPY.get(cid, {}).items())
    extra = RULE.get(cid)
    return (exp + ("; rule: " + extra if extra else "")).strip("; ")


def observed_text(cid):
    out = []
    ys = sorted({int(y) for y in EXPY.get(cid, {})} | ({C[cid]["key"]}))
    opts = ("A1", "A2", "A2H", "B2best") if withdrawals(cid) else ("A1", "A2", "B2best")
    for opt in opts:
        for y in ys:
            out.append(f"{opt} {y}: {show(get(opt, cid, y))}")
    return " | ".join(out)


def tests_text(cid):
    from rivals_gen import ident
    t = []
    hv = [v for v in CUR["std"][cid] if v.startswith("A2H:")]
    for v in list(A1SET[cid]) + [v for v in a2_variants(cid) if v not in A1SET[cid]] + hv:
        for y in C[cid]["years"]:
            t.append(f"Stress.Rivals.{ident(cid)}_{ident(v)}_{y}")
    if C[cid].get("frame"):
        for y in C[cid]["years"]:
            t.append(f"Proto.Multinomial.{ident(cid)}_plain_B2_{y}")
    return "; ".join(t)


def main():
    table = {}
    for c in CASES:
        cid = c["id"]
        table[cid] = {o: score(o, cid) for o in OPTS}
    # E1 verdict flips against std over every encoding and dated year
    flips = []
    for c in CASES:
        cid = c["id"]
        for v in CUR["std"][cid]:
            if v.startswith("A2H:"): continue      # E1 is studied on A1 and A2 only
            for y in c["years"]:
                base = CUR["std"][cid][v][str(y)]
                for tag in E1TAGS:
                    for (r, b, d, vd), (r2, b2, d2, vd2) in zip(base, CUR[tag][cid][v][str(y)]):
                        if vd == vd2: continue
                        exp = EXPY.get(cid, {}).get(y, {}).get(r)
                        kind = "unscored" if exp is None else ("towards history" if vd2 in exp and vd not in exp
                               else "away from history" if vd in exp and vd2 not in exp else "both wrong")
                        flips.append((tag, cid, v, y, r, vd, vd2, kind))
    with open(os.path.join(DATA, "e1_flips.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["weight", "case", "encoding", "year", "rival", "verdict at weight 0", "verdict at weight", "against history"])
        for row in flips: w.writerow([row[0][1:], *row[1:]])
    with open(os.path.join(DATA, "scores.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["id", "kind"] + OPTS)
        for c in CASES: w.writerow([c["id"], c["kind"]] + [table[c["id"]][o][0] for o in OPTS])
    with open(os.path.join(DATA, "cases.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["id", "kind", "title", "probes", "input", "correct", "observed", "mark", "mark_A2", "mark_A2H", "mark_D1",
                    "mark_B1", "mark_B2", "mark_B3", "mark_B2best", "mark_E1_1_10", "mark_E1_1_5", "mark_E1_3_10",
                    "why", "test", "source"])
        for c in CASES:
            cid = c["id"]
            t = table[cid]
            why = " / ".join(f"{o}: {'; '.join(t[o][1])}" for o in ("A1", "A2", "A2H", "B2", "B2best") if t[o][1])
            w.writerow([cid, c["kind"], c["title"], c["probe"], input_text(cid), correct_text(cid), observed_text(cid),
                        t["A1"][0], t["A2"][0], t["A2H"][0], t["D1"][0], t["B1"][0], t["B2"][0], t["B3"][0], t["B2best"][0],
                        t["E1:1/10"][0], t["E1:1/5"][0], t["E1:3/10"][0], why, tests_text(cid), c["source"]])
    json.dump({cid: {o: list(v) for o, v in t.items()} for cid, t in table.items()},
              open(os.path.join(DATA, "scores.json"), "w"), indent=1)
    # print
    print("case  " + " ".join(f"{o:>8}" for o in OPTS))
    for c in CASES:
        print(f"{c['id']:5} " + " ".join(f"{table[c['id']][o][0][:8]:>8}" for o in OPTS))
    tallies = {}
    for o in OPTS:
        cnt = Counter(table[c][o][0] for c in table)
        tallies[o] = cnt
        print(f"{o:8} " + ", ".join(f"{k} {cnt[k]}" for k in ("PASS", "FAIL", "SILENT", "INEXPRESSIBLE")))
    real = [c["id"] for c in CASES if c["kind"] == "real"]
    for o in ("A1", "A2", "A2H", "B2best"):
        cnt = Counter(table[c][o][0] for c in real)
        print(f"real only {o}: " + ", ".join(f"{k} {cnt[k]}" for k in ("PASS", "FAIL", "SILENT", "INEXPRESSIBLE")))
    e1sum = {}
    for fam, pick in (("A1", lambda cid, v: v in A1SET[cid] or (cid == "S05" and v == "split")),
                      ("A2", lambda cid, v: v in a2_variants(cid))):
        for tag in E1TAGS:
            sel = [r for r in flips if r[0] == tag and pick(r[1], r[2])]
            cnt = Counter(r[7] for r in sel)
            e1sum[f"{fam} {tag[1:]}"] = {"flips": len(sel), **cnt, "cases": sorted({r[1] for r in sel})}
            print(f"E1 {tag[1:]} on {fam}: {len(sel)} verdict flips; " + ", ".join(f"{k} {v}" for k, v in sorted(cnt.items()))
                  + "; cases " + " ".join(sorted({r[1] for r in sel})))
    json.dump(e1sum, open(os.path.join(DATA, "e1_summary.json"), "w"), indent=1)
    # key-year marks (the research stage marked only each case's key year; review stage: computed here)
    for o in ("A1", "A2", "A2H", "B2best"):
        cnt = Counter(score_key_year(o, c["id"]) for c in CASES)
        tallies[f"key-year {o}"] = cnt
        print(f"key year only {o}: " + ", ".join(f"{k} {cnt[k]}" for k in ("PASS", "FAIL", "SILENT", "INEXPRESSIBLE")))
    json.dump({o: dict(v) for o, v in tallies.items()}, open(os.path.join(DATA, "tallies.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
