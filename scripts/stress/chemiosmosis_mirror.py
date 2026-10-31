"""Program 09: an exact copy, in Python fractions, of the parts of the BioLean core the
chemiosmosis stress set uses, plus the encodings of the real record.

Mirrored from the Lean core (2026-10-30): `Opinion.ofReliability`, `Opinion.fuse`,
`Opinion.against`, `Opinion.verdict`, `Statement.distinctEvidence`, `Statement.opinion`,
`Statement.asOf`, `Rivalry.opinions`, `EvidenceModel.standard`. The Lean file
`BioLean/Stress/ChemiosmosisReal.lean` is the authority; this copy is for fast sweeps
(every year, every left-out item, 72 encodings). `python3 scripts/stress/chemiosmosis_mirror.py`
runs the self-test: it must reproduce every cell of the example's year table.

Nothing here is a core change. Prototypes of core changes are marked PROTO.
"""
import csv
import os
from fractions import Fraction as F

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
RECORD = os.path.join(ROOT, "data/stress/09/record.tsv")

STD = dict(metaAnalysis=F(9, 10), rct=F(17, 20), curatedDb=F(4, 5), textbook=F(4, 5),
           ontologyAxiom=F(9, 10), mechanistic=F(7, 10), review=F(3, 5), observational=F(1, 2),
           inVitro=F(1, 2), textMined=F(3, 10), hypothesis=F(0), crossSpecies=F(3, 10),
           definitional=F(999, 1000))
VAC = (F(0), F(0), F(1))
TH, TAU = F(4, 5), F(1, 4)


# ---- the core, mirrored -------------------------------------------------------------------
def ofrel(r, pol):
    return (r, F(0), 1 - r) if pol == "+" else (F(0), r, 1 - r)


def fuse(x, y):
    bx, dx, ux = x
    by, dy, uy = y
    k = ux + uy - ux * uy
    return ((bx * uy + by * ux) / k, (dx * uy + dy * ux) / k, ux * uy / k)


def against(o):
    return ofrel(o[0], "-")


def verdict(o, th=TH, tau=TAU):
    b, d, _ = o
    if tau <= b and tau <= d:
        return "contested"
    if th <= b:
        return "established"
    if th <= d:
        return "refuted"
    return "unsupported"


def distinct(items):
    out = []
    for e in items:
        if e["pmid"] != 0 and any(x["pmid"] == e["pmid"] for x in out):
            continue
        out.append(e)
    return out


def stmt_op(items, W=STD, year=None):
    o = VAC
    for e in distinct([e for e in items if year is None or e["year"] <= year]):
        o = fuse(o, ofrel(W[e["kind"]], e["pol"]))
    return o


def rivalry(stmts, W=STD, year=None):
    """stmts: list of (id, items). Returns (id, own opinion, opinion under the rivalry)."""
    own = [(sid, stmt_op(it, W, year)) for sid, it in stmts]
    out = []
    for i, (sid, o) in enumerate(own):
        r = o
        for j, (_, t) in enumerate(own):
            if j != i:
                r = fuse(r, against(t))
        out.append((sid, o, r))
    return out


def dec(q, digits=3):
    """Rat.toDecimal: truncates, as the Lean tables do."""
    q = F(q)
    s = "-" if q < 0 else ""
    q = abs(q)
    n = q.numerator * 10 ** digits // q.denominator
    return f"{s}{n // 10 ** digits}.{str(n % 10 ** digits).zfill(digits)}"


def fmt(o):
    return f"b={dec(o[0])} d={dec(o[1])}"


# ---- the record and its encodings (data, not core) -----------------------------------------
def load():
    with open(RECORD) as f:
        return list(csv.DictReader(f, delimiter="\t"))


REC = load()
MEMORY = tuple(e["key"] for e in REC if e["basis"] == "memory")


def kind_of(e, face=False):
    """Kinds rule: experiments are .inVitro; an advocate's own review is a .hypothesis (weight 0),
    as the example does for reviews63; a survey or joint review is a .review (3/5)."""
    if e["kind"] == "experiment":
        return "inVitro"
    if e["kind"] == "review":
        return "review" if (face or e["advocacy"] == "n") else "hypothesis"
    return "hypothesis"


def items(rival, dual=False, drop=(), face=False, drop_memory=False):
    out = []
    for e in REC:
        if e["key"] in drop or (drop_memory and e["basis"] == "memory") or e["direction"] == "neutral":
            continue
        base = dict(key=e["key"], pmid=int(e["pmid"] or 0), year=int(e["year"]), kind=kind_of(e, face),
                    lab=e["lab"])
        if e["rival"] == rival:
            out.append(dict(base, pol="+" if e["direction"] == "supports" else "-"))
        elif dual and e["dual_refutes"] == rival:
            out.append(dict(base, pol="-"))
    return out


def two(**kw):
    return [("C", items("C", **kw)), ("S", items("S", **kw))]


def three(**kw):
    return [("C", items("C", **kw)), ("S", items("S", **kw)), ("W", items("W", **kw))]


def rivals(sides, **kw):
    """Any list of rivals, e.g. "CSWM"."""
    return [(s, items(s, **kw)) for s in sides]


def scale(W, k, kinds):
    """Multiply the pseudo-count r/(1-r) of each kind in `kinds` by k."""
    out = dict(W)
    for kd in kinds:
        r = W[kd]
        if r == 0:
            continue
        w = r / (1 - r) * k
        out[kd] = w / (1 + w)
    return out


# PROTO (option C): an item stops counting from a curated year. Keys are record keys.
PHOSPHO = {"s06": 1964, "s08": 1964}
ALL_REPORTS = dict(PHOSPHO, **{k: 1974 for k in ("s03", "s04", "s05", "s11", "s12")})


def supersede(its, rules, year):
    return [e for e in its if not (e["key"] in rules and year >= rules[e["key"]])]


def run(stmts, year, W=STD, rules=None):
    if rules:
        stmts = [(s, supersede(it, rules, year)) for s, it in stmts]
    return rivalry(stmts, W, year)


def verdicts(stmts, year, W=STD, rules=None):
    return {s: verdict(r) for s, _, r in run(stmts, year, W, rules)}


def first(stmts, sid, v, W=STD, rules=None, years=range(1950, 2026)):
    for y in years:
        if verdicts(stmts, y, W, rules).get(sid) == v:
            return y
    return None


def years_with(stmts, sid, v, W=STD, rules=None, years=range(1950, 2026)):
    return [y for y in years if verdicts(stmts, y, W, rules).get(sid) == v]


def spans(ys):
    """[1962, 1963, 1965] -> '1962-1963, 1965'."""
    out, start, prev = [], None, None
    for y in ys:
        if start is None:
            start = prev = y
        elif y == prev + 1:
            prev = y
        else:
            out.append(f"{start}-{prev}" if start != prev else str(start))
            start = prev = y
    if start is not None:
        out.append(f"{start}-{prev}" if start != prev else str(start))
    return ", ".join(out) if out else "never"


def exit_test(stmts, W=STD, rules=None):
    a, b = verdicts(stmts, 1965, W, rules), verdicts(stmts, 1974, W, rules)
    return dict(c65=a["C"], s65=a["S"], c74=b["C"], s74=b["S"],
                c_est=first(stmts, "C", "established", W, rules),
                s_ref=first(stmts, "S", "refuted", W, rules),
                passed=a["C"] == "contested" and b["C"] == "established" and b["S"] == "refuted")


# ---- self-test: the example's own table ---------------------------------------------------
def _example():
    E = lambda pmid, y, k, p="+": dict(key=str(pmid) + k + p, pmid=pmid, year=y, kind=k, pol=p)
    chemi = [E(13771349, 1961, "hypothesis"), E(0, 1965, "inVitro"), E(5220864, 1966, "inVitro"),
             E(16742541, 1967, "inVitro"), E(4330063, 1971, "inVitro"), E(4272126, 1974, "inVitro")]
    chem = [E(13111237, 1953, "hypothesis"), E(0, 1963, "hypothesis"), E(0, 1965, "inVitro"),
            E(5220864, 1966, "inVitro", "-"), E(16742541, 1967, "inVitro", "-"),
            E(4330063, 1971, "inVitro", "-"), E(4272126, 1974, "inVitro", "-")]
    return chemi, chem


# Copied from `lake env lean BioLean/Examples/Chemiosmosis.lean` output, 2026-10-30.
EXPECTED = {
    1953: ("b=0.000 d=0.000", "b=0.000 d=0.000", "b=0.000 d=0.000"),
    1961: ("b=0.000 d=0.000", "b=0.000 d=0.000", "b=0.000 d=0.000"),
    1963: ("b=0.000 d=0.000", "b=0.000 d=0.000", "b=0.000 d=0.000"),
    1965: ("b=0.333 d=0.333", "b=0.333 d=0.333", "b=0.333 d=0.333"),
    1966: ("b=0.500 d=0.250", "b=0.571 d=0.142", "b=0.200 d=0.600"),
    1967: ("b=0.600 d=0.200", "b=0.692 d=0.076", "b=0.142 d=0.714"),
    1971: ("b=0.666 d=0.166", "b=0.761 d=0.047", "b=0.111 d=0.777"),
    1974: ("b=0.714 d=0.142", "b=0.806 d=0.032", "b=0.090 d=0.818"),
}
EXPECTED_REAL = {1965: ("b=0.000 d=0.000", "b=0.000 d=0.000"), 1966: ("b=0.500 d=0.000", "b=0.000 d=0.666"),
                 1967: ("b=0.666 d=0.000", "b=0.000 d=0.800"), 1971: ("b=0.750 d=0.000", "b=0.000 d=0.857"),
                 1974: ("b=0.800 d=0.000", "b=0.000 d=0.888")}


def self_test():
    chemi, chem = _example()
    one = chemi + [dict(e, pol="-") for e in chem if e["pmid"] == 0]
    bad = 0
    for y, exp in EXPECTED.items():
        res = rivalry([("C", chemi), ("S", chem)], year=y)
        got = (fmt(stmt_op(one, year=y)), fmt(res[0][2]), fmt(res[1][2]))
        bad += got != exp
    real = lambda it: [e for e in it if e["pmid"] != 0]
    for y, exp in EXPECTED_REAL.items():
        res = rivalry([("C", real(chemi)), ("S", real(chem))], year=y)
        bad += (fmt(res[0][2]), fmt(res[1][2])) != exp
    return bad


if __name__ == "__main__":
    n = len(EXPECTED) * 3 + len(EXPECTED_REAL) * 2
    bad = self_test()
    print(f"self-test: {n - bad} of {n} cells of the example's tables reproduced")
    raise SystemExit(1 if bad else 0)
