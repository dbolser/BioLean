"""Exact-fraction Python mirror of program 03's Lean code.

It recomputes, from rivals_spec.py alone, every observation that BioLean/Stress/Rivals.lean and
BioLean/Proto/Multinomial.lean print, and checks that the two agree number for number. Agreement is
what licenses the one computation that has no Lean version: option D1 (a dependence-aware Rivalry,
a change to `Rivalry.opinions`, kept out of Lean because it is a core change with no frame form).

  current core   Statement.opinion (PMID dedup, first item kept), Rivalry.opinions (one step, `against`)
  B2             Frame.cellOpinion (per-cell binomial from decisive items)
  B1             Frame.hyper (Josang hyper-opinion coarsened per cell; prior weight 2)
  B3             Frame.tbmCell (Smets' TBM, unnormalised Dempster)
  E2             Frame.prob (uniform base rate over the frame's cells)
  E1             the current core with the hypothesis kind at weight w
  D1             Rivalry where rival i ignores, in rival j, the items i also carries (same key)
  A2H            A2 with option H emulated outside the core: an item stops counting from its `until`
                 year (Stress/Rivals.lean `withdrawAt`; review stage)

Usage: python3 scripts/stress/rivals_mirror.py   (prints the agreement check; writes nothing)
"""
import json, os, sys
from fractions import Fraction as F

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from rivals_spec import CASES, C, PYEV, best_frames, translate, withdrawals

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
DATA = os.path.join(ROOT, "data", "stress", "03")

STD = {"metaAnalysis": F(9, 10), "rct": F(17, 20), "curatedDb": F(4, 5), "textbook": F(4, 5),
       "ontologyAxiom": F(9, 10), "mechanistic": F(7, 10), "review": F(3, 5), "observational": F(1, 2),
       "inVitro": F(1, 2), "textMined": F(3, 10), "hypothesis": F(0), "crossSpecies": F(3, 10),
       "definitional": F(999, 1000)}
W = F(2)


def model(h=F(0)):
    m = dict(STD)
    m["hypothesis"] = F(h)
    return m


def verdict(b, d, th=F(4, 5), tau=F(1, 4)):
    if tau <= b and tau <= d: return "contested"
    if th <= b: return "established"
    if th <= d: return "refuted"
    return "unsupported"


VAC = (F(0), F(0), F(1))


def fuse(x, y):
    bx, dx, ux = x
    by, dy, uy = y
    k = ux + uy - ux * uy
    return ((bx * uy + by * ux) / k, (dx * uy + dy * ux) / k, ux * uy / k)


def item_op(kind, pol, m):
    r = m[kind]
    return (r, F(0), 1 - r) if pol == "+" else (F(0), r, 1 - r)


def distinct(ev):
    """Statement.distinctEvidence: first item per PMID kept; PMID 0 never deduplicated."""
    out, seen = [], set()
    for e in ev:
        if e["pmid"] != 0 and e["pmid"] in seen: continue
        if e["pmid"] != 0: seen.add(e["pmid"])
        out.append(e)
    return out


def stmt_op(ev, year, m, honour_until=False):
    """Statement.opinionAt; with honour_until (A2H), items withdrawn by `year` are dropped first."""
    if honour_until:
        ev = [e for e in ev if not (e.get("until") is not None and e["until"] <= year)]
    o = VAC
    for e in distinct([e for e in ev if e["year"] <= year]):
        o = fuse(o, item_op(e["kind"], e["pol"], m))
    return o


def against(b):
    return (F(0), b, 1 - b)


def rivalry(rivals, year, m, shared_aware=False, honour_until=False):
    """Rivalry.opinions at `year`; with shared_aware (D1), rival i drops from rival j the items it shares;
    with honour_until (A2H), withdrawn items are dropped."""
    out = []
    for i, ri in enumerate(rivals):
        o = stmt_op(ri["ev"], year, m, honour_until)
        mine = {e["key"] for e in ri["ev"] if e["year"] <= year}
        for j, rj in enumerate(rivals):
            if j == i: continue
            ev = [e for e in rj["ev"] if not (shared_aware and e["key"] in mine)]
            o = fuse(o, against(stmt_op(ev, year, m, honour_until)[0]))
        out.append((ri["rid"], o[0], o[1], verdict(o[0], o[1])))
    return out


# ---------------------------------------------------------------- frames

def cells_of(fr):
    return list(fr["cells"]) + (["other"] if fr["open"] else [])


def live(fr, y):
    cells = cells_of(fr)
    idx = {x: i for i, x in enumerate(cells)}
    ok = []
    for it in fr["items"]:
        if it["year"] > y: continue
        if it.get("until") is not None and not (y < it["until"]): continue
        fav = [idx[x] for x in it["fav"]]
        if all(i in fav for i in range(len(cells))): continue
        ok.append((it, fav))
    out = []
    for it, fav in ok:
        if it["pmid"] != 0 and any(j["pmid"] == it["pmid"] and j.get("finding", 0) == it.get("finding", 0) for j, _ in out):
            continue
        out.append((it, fav))
    return cells, out


def count(kind, m):
    r = m[kind]
    return 2 * r / (1 - r)


def b2(fr, y, m):
    cells, L = live(fr, y)
    res = []
    for x in range(len(cells)):
        o = VAC
        for it, fav in L:
            if fav == [x]: o = fuse(o, item_op(it["kind"], "+", m))
            elif x in fav: pass
            else: o = fuse(o, item_op(it["kind"], "-", m))
        res.append(o)
    return cells, res


def b1(fr, y, m):
    cells, L = live(fr, y)
    res = []
    for x in range(len(cells)):
        p = n = v = F(0)
        for it, fav in L:
            c = count(it["kind"], m)
            if fav == [x]: p += c
            elif x in fav: v += c
            else: n += c
        t = p + n + v + 2
        res.append((p / t, n / t, (v + 2) / t))
    return cells, res


def prob(fr, y, m):
    cells, L = live(fr, y)
    tot = 2 + sum(count(it["kind"], m) for it, _ in L)
    out = []
    for x in range(len(cells)):
        share = sum(count(it["kind"], m) / len(fav) for it, fav in L if x in fav)
        out.append((share + F(2, len(cells))) / tot)
    return out


def b3(fr, y, m):
    cells, L = live(fr, y)
    full = (1 << len(cells)) - 1
    mass = [(full, F(1))]
    for it, fav in L:
        r = m[it["kind"]]
        if r == 0: continue
        s = 0
        for x in fav: s |= 1 << x
        acc = []
        def add(t, v):
            for k, (u, w) in enumerate(acc):
                if u == t:
                    acc[k] = (u, w + v)
                    return
            acc.append((t, v))
        for t, w in mass:
            add(t & s, w * r)
            add(t, w * (1 - r))
        mass = acc
    res = []
    conflict = sum((w for t, w in mass if t == 0), F(0))
    for x in range(len(cells)):
        bit = 1 << x
        b = sum((w for t, w in mass if t == bit), F(0))
        d = sum((w for t, w in mass if t != 0 and t & bit == 0), F(0))
        res.append((b, d))
    return cells, res, conflict


# ---------------------------------------------------------------- the encodings, as the generator builds them

def encodings(cid):
    """(variant label, 'rivalry'|'stmt', rivals) for every current-core encoding of a case, in Lean's order."""
    c = C[cid]
    out = []
    for v, spec in c["variants"].items():
        if spec[0] in ("rivalry", "stmt"):
            out.append((v, spec[0], spec[1]))
        elif spec[0] == "repo":
            out.append((v, "rivalry", PYEV[(cid, v)]))
        elif spec[0] == "glp1":
            if spec[1] == "separate":
                out.append((v + ":S9c", "stmt", PYEV[(cid, v + ":S9c")]))
                out.append((v + ":S9d", "stmt", PYEV[(cid, v + ":S9d")]))
            else:
                out.append((v, "rivalry", PYEV[(cid, v)]))
    frames = [(str(k), f) for k, f in enumerate(best_frames(cid))]
    if cid == "S05": frames.append(("u", C["S05"]["frame_unsplit"]))
    for k, fr in frames:
        rv = translate(cid, fr)
        out.append((f"A2:{k}", "rivalry" if len(rv) >= 2 else "stmt", rv))
    if withdrawals(cid):
        for k, fr in frames:
            rv = translate(cid, fr)
            out.append((f"A2H:{k}", "rivalryH" if len(rv) >= 2 else "stmtH", rv))
    return out


def core_rows(kind, rivals, y, m, shared_aware=False):
    if kind in ("rivalry", "rivalryH"):
        return rivalry(rivals, y, m, shared_aware, honour_until=kind == "rivalryH")
    o = stmt_op(rivals[0]["ev"], y, m, honour_until=kind == "stmtH")
    return [(rivals[0]["rid"], o[0], o[1], verdict(o[0], o[1]))]


def proto_frames(cid):
    """(label, frame) for every prototype frame of a case, in Lean's order (mirrors rivals_gen.proto_frames)."""
    from rivals_spec import FB
    c = C[cid]
    out = []
    if c.get("frame"): out.append(("plain", c["frame"]))
    if c.get("frame_closed"): out.append(("closed", c["frame_closed"]))
    if c.get("frame_unsplit"): out.append(("unsplit", c["frame_unsplit"]))
    for label, fr in c.get("frames_extra", []): out.append((label, fr))
    for k, fr in enumerate(best_frames(cid)):
        if k == 0 and cid not in FB and not fr.get("solo"): continue
        out.append((f"best:{k}", fr))
    return out


TAGS = [("std", F(0)), ("h1/10", F(1, 10)), ("h1/5", F(1, 5)), ("h3/10", F(3, 10))]


def check():
    cur = json.load(open(os.path.join(DATA, "observed_current.json")))
    pro = json.load(open(os.path.join(DATA, "observed_proto.json")))
    n = bad = 0
    for tag, h in TAGS:
        m = model(h)
        for c in CASES:
            cid = c["id"]
            for v, kind, rivals in encodings(cid):
                for y in c["years"]:
                    got = core_rows(kind, rivals, y, m)
                    lean = cur[tag][cid][v][str(y)]
                    for (rid, b, d, vd), (lr, lb, ld, lv) in zip(got, lean):
                        n += 1
                        if (rid, b, d, vd) != (lr, F(lb), F(ld), lv):
                            bad += 1
                            if bad < 15: print("MISMATCH core", tag, cid, v, y, (rid, b, d, vd), (lr, lb, ld, lv))
                    if len(got) != len(lean):
                        bad += 1
                        print("MISMATCH length", tag, cid, v, y)
    m = model()
    for c in CASES:
        cid = c["id"]
        for label, fr in proto_frames(cid):
            for y in c["years"]:
                cells, o2 = b2(fr, y, m)
                _, o1 = b1(fr, y, m)
                _, o3, conf = b3(fr, y, m)
                P = prob(fr, y, m)
                lean = pro[cid][label][str(y)]
                for x, row in enumerate(lean):
                    exp = {"B2": [o2[x][0], o2[x][1], verdict(o2[x][0], o2[x][1]), P[x]],
                           "B1": [o1[x][0], o1[x][1], verdict(o1[x][0], o1[x][1]), P[x]],
                           "B3": [o3[x][0], o3[x][1], verdict(o3[x][0], o3[x][1]), conf]}
                    for k in ("B2", "B1", "B3"):
                        n += 1
                        lb, ld, lv, lx = row[k]
                        if [F(lb), F(ld), lv, F(lx)] != exp[k] or row["cell"] != cells[x]:
                            bad += 1
                            if bad < 30: print("MISMATCH", k, cid, label, y, row["cell"], row[k], exp[k])
    return n, bad


if __name__ == "__main__":
    n, bad = check()
    print(f"mirror check: {n} Lean values recomputed in Python, {bad} disagree")
