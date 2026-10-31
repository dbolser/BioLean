"""Program 09: run every sweep of the chemiosmosis stress set through the exact mirror.

    python3 scripts/stress/chemiosmosis_run.py

Writes, in data/stress/09/:
  run_output.txt   every experiment, labelled by case id (CH-nn)
  year_table.tsv   each encoding, each year 1950 to 2025: b, d, verdict and margin per rival
  loo.tsv          leave one out: which single items flip a verdict in 1965, 1974 or 1977
  grid.tsv         the 72 encodings and the M2 exit test on each
The Lean file BioLean/Stress/ChemiosmosisReal.lean pins the same numbers as theorems; where the
two are compared, they agree (see the doc, section Results).
"""
import itertools
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from chemiosmosis_mirror import (ALL_REPORTS, F, MEMORY, PHOSPHO, REC, ROOT, STD, TAU, TH, dec, exit_test,
                                 first, fmt, fuse, items, against, rivalry, rivals, run, scale, self_test, spans,
                                 stmt_op, three, two, verdict, verdicts, years_with)

OUT = os.path.join(ROOT, "data/stress/09")
YEARS = range(1950, 2026)
LINES = []


def say(*a):
    LINES.append(" ".join(str(x) for x in a))


def margin(o):
    b, d, _ = o
    return min(abs(b - TAU), abs(d - TAU), abs(b - TH), abs(d - TH))


def table_rows(label, stmts, W=STD, rules=None):
    rows = []
    for y in YEARS:
        for sid, own, r in run(stmts, y, W, rules):
            rows.append([label, y, sid, dec(r[0], 4), dec(r[1], 4), verdict(r), dec(margin(r), 4),
                         dec(own[0], 4), dec(own[1], 4), verdict(own)])
    return rows


def ex(stmts, W=STD, rules=None):
    r = exit_test(stmts, W, rules)
    return (f"1965 C {r['c65']}, S {r['s65']} | 1974 C {r['c74']}, S {r['s74']} | "
            f"C established from {r['c_est']} | S refuted from {r['s_ref']} | exit {'PASS' if r['passed'] else 'fail'}")


def at(stmts, ys, W=STD, rules=None):
    for y in ys:
        say(f"   {y}  " + "  ".join(f"{s}: {fmt(r)} {verdict(r)}" for s, _, r in run(stmts, y, W, rules)))


def per_lab(it):
    """PROTO (option G, crude): one lab, one vote, per statement and polarity."""
    seen, out = set(), []
    for e in sorted(it, key=lambda e: e["year"]):
        k = (e["lab"], e["pol"], e["kind"] == "hypothesis")
        if k in seen:
            continue
        seen.add(k)
        out.append(e)
    return out


def scoped(stmts, W=STD, year=None):
    """PROTO (option I2): a rival with no evidence of its own (no non-hypothesis item by `year`)
    receives no disbelief from the others. A rival with no belief passes none on already."""
    own = [(sid, stmt_op(it, W, year),
            any(e["kind"] != "hypothesis" and (year is None or e["year"] <= year) for e in it))
           for sid, it in stmts]
    out = []
    for i, (sid, o, has) in enumerate(own):
        r = o
        if has:
            for j, (_, t, _) in enumerate(own):
                if j != i:
                    r = fuse(r, against(t))
        out.append((sid, r))
    return out


def multinomial(stmts, W=STD, year=None, prior=F(1)):
    """PROTO (option H): one Dirichlet pool over the rivals plus 'other'. A supporting item adds
    its pseudo-count r/(1-r) to its rival; a refuting item adds it to 'other'. Each PMID counts
    once in the whole pool. Prior weight 1, as `ofReliability` implies (r = w/(w+1))."""
    counts, seen = {sid: F(0) for sid, _ in stmts}, set()
    counts["other"] = F(0)
    for sid, it in stmts:
        for e in it:
            if year is not None and e["year"] > year:
                continue
            if e["pmid"] in seen:
                continue
            seen.add(e["pmid"])
            r = W[e["kind"]]
            w = r / (1 - r)
            counts[sid if e["pol"] == "+" else "other"] += w
    tot = sum(counts.values()) + prior
    return {k: v / tot for k, v in counts.items()}, prior / tot


def forgetting(stmts, year, h, W=STD):
    """PROTO (option N): each item's pseudo-count r/(1-r) halves every `h` years of age (step decay),
    then the rivalry is computed in pseudo-counts, which is exact: cumulative fusion adds counts, and
    `against` of belief b adds b/(1-b) to disbelief. With no decay this equals `rivalry`."""
    def counts(it):
        s = r = F(0)
        for e in [e for e in it if e["year"] <= year]:
            if e["pmid"] != 0 and e is not next(x for x in it if x["year"] <= year and x["pmid"] == e["pmid"]):
                continue
            w = W[e["kind"]] / (1 - W[e["kind"]]) * F(1, 2) ** ((year - e["year"]) // h)
            if e["pol"] == "+":
                s += w
            else:
                r += w
        return s, r
    own = [(sid, counts(it)) for sid, it in stmts]
    out = []
    for i, (sid, (s, r)) in enumerate(own):
        extra = F(0)
        for j, (_, (s2, r2)) in enumerate(own):
            if j != i:
                b2 = s2 / (s2 + r2 + 1)
                extra += b2 / (1 - b2)
        n = s + r + extra + 1
        out.append((sid, (s / n, (r + extra) / n, 1 / n)))
    return out


def main():
    bad = self_test()
    say(f"mirror self-test against the example's tables: {'OK' if bad == 0 else f'{bad} cells differ'}")
    rows = []
    s1, s2 = two(), two(dual=True)

    say("\n== counts by 1974 (non-hypothesis items, for / against) ==")
    for s, it in s1:
        pro = sum(1 for e in it if e["year"] <= 1974 and e["kind"] != "hypothesis" and e["pol"] == "+")
        con = sum(1 for e in it if e["year"] <= 1974 and e["kind"] != "hypothesis" and e["pol"] == "-")
        say(f"   {s}: {pro} for, {con} against")

    say("\n== CH-01 to CH-04: single entry (each item on the one rival it bears on) ==")
    at(s1, [1961, 1962, 1963, 1964, 1965, 1966, 1974, 1977, 1978, 2020])
    say("  ", ex(s1))
    say("   C established in:", spans(years_with(s1, "C", "established")))
    say("   C refuted in:", spans(years_with(s1, "C", "refuted")))
    say("   S refuted in:", spans(years_with(s1, "S", "refuted")))
    say("   S contested in:", spans(years_with(s1, "S", "contested")))
    say("   C highest belief under the rivalry:",
        max((dec(run(s1, y)[0][2][0]), y) for y in YEARS))
    rows += table_rows("single", s1)

    say("\n== CH-05: dual entry (discriminating experiments also refute S) ==")
    at(s2, [1965, 1974, 1976, 1977, 1978, 2020])
    say("  ", ex(s2))
    say("   C established in:", spans(years_with(s2, "C", "established")))
    say("   S refuted in:", spans(years_with(s2, "S", "refuted")))
    rows += table_rows("dual", s2)

    say("\n== CH-09, CH-12: own opinions, no rivalry ==")
    for y in [1963, 1965, 1974, 1977, 2020]:
        say(f"   {y}  " + "  ".join(f"{s} own: {fmt(stmt_op(it, STD, y))} {verdict(stmt_op(it, STD, y))}"
                                    for s, it in s1))
    say("   exact 1974: C own b =", stmt_op(s1[0][1], STD, 1974)[0], " S own b =", stmt_op(s1[1][1], STD, 1974)[0])
    o = run(s1, 1974)
    say(f"   margins 1974 single: C d = {float(o[0][2][1]):.4f} against tau 0.25; S b = {float(o[1][2][0]):.4f}")

    say("\n== CH-06: one claim, the chemical reports read as refutations of C ==")
    one = items("C") + [dict(e, pol="-" if e["pol"] == "+" else "+") for e in items("S")]
    for y in [1961, 1965, 1974, 1977, 2020]:
        o = stmt_op(one, STD, y)
        say(f"   {y} {fmt(o)} {verdict(o)}")
    say("   established in:", spans([y for y in YEARS if verdict(stmt_op(one, STD, y)) == "established"]))

    say("\n== CH-02, CH-07: leave one out ==")
    loo_rows = []
    for label, mk in [("single", lambda d: two(drop=d)), ("dual", lambda d: two(drop=d, dual=True))]:
        base = {y: verdicts(mk(()), y) for y in (1965, 1974, 1977)}
        n = 0
        for e in REC:
            if e["direction"] == "neutral" or e["rival"] not in ("C", "S"):
                continue
            out = {y: verdicts(mk((e["key"],)), y) for y in base}
            flips = [f"{y} {s}: {base[y][s]}->{out[y][s]}" for y in base for s in ("C", "S") if out[y][s] != base[y][s]]
            if flips:
                n += 1
                loo_rows.append([label, e["key"], e["pmid"], e["year"], e["first_author"], e["basis"], "; ".join(flips)])
                say(f"   {label}: drop {e['key']} ({e['first_author']} {e['year']}, {e['basis']}): " + "; ".join(flips))
        say(f"   {label}: {n} single items flip a verdict in 1965, 1974 or 1977")
    E = lambda key, pmid, y, k, p="+": dict(key=key, pmid=pmid, year=y, kind=k, pol=p)
    chemi = [E("m61", 13771349, 1961, "hypothesis"), E("j66", 5220864, 1966, "inVitro"),
             E("mm67", 16742541, 1967, "inVitro"), E("h71", 4330063, 1971, "inVitro"), E("r74", 4272126, 1974, "inVitro")]
    chem = [E("s53", 13111237, 1953, "hypothesis"), E("j66", 5220864, 1966, "inVitro", "-"),
            E("mm67", 16742541, 1967, "inVitro", "-"), E("h71", 4330063, 1971, "inVitro", "-"),
            E("r74", 4272126, 1974, "inVitro", "-")]
    say("   the example's six real papers (realCoupling), 1974:")
    for k in [None, "j66", "mm67", "h71", "r74"]:
        st = [("C", [e for e in chemi if e["key"] != k]), ("S", [e for e in chem if e["key"] != k])]
        say(f"     drop {k}: " + "  ".join(f"{s}: {fmt(r)} {verdict(r)}" for s, _, r in rivalry(st, STD, 1974)))
    real = [("C", chemi), ("S", chem)]
    say("     realCoupling S refuted in:", spans(years_with(real, "S", "refuted")),
        "| C 1965:", verdicts(real, 1965)["C"])

    say("\n== CH-08, CH-22: refuted with no evidence of its own ==")
    t3 = three()
    rows += table_rows("three", t3)
    say("   three rivals: C refuted in", spans(years_with(t3, "C", "refuted")),
        "| W refuted in", spans(years_with(t3, "W", "refuted")),
        "| W contested in", spans(years_with(t3, "W", "contested")),
        "| C contested in", spans(years_with(t3, "C", "contested")))
    at(t3, [1965, 1974, 1977, 1994, 2014, 2020])
    t4 = t3 + [("G", items("G"))]
    say("   four rivals: G refuted in", spans(years_with(t4, "G", "refuted")))
    t3d = three(dual=True)
    say("   three rivals, dual: C established in", spans(years_with(t3d, "C", "established")),
        "| C contested in", spans(years_with(t3d, "C", "contested")), "| W refuted in", spans(years_with(t3d, "W", "refuted")))

    say("\n== CH-21: W also counts every proton experiment (no parent claim) ==")
    Ws = items("W") + [dict(e, key=e["key"] + "w") for e in items("C") if e["pol"] == "+" and e["kind"] != "hypothesis"]
    t3s = [("C", items("C")), ("S", items("S")), ("W", Ws)]
    at(t3s, [1965, 1974, 1977, 2020])
    say("   C contested in", spans(years_with(t3s, "C", "contested")), "| W contested in",
        spans(years_with(t3s, "W", "contested")), "| S unsupported in", spans(years_with(t3s, "S", "unsupported")))

    say("\n== CH-10, CH-11, CH-12, CH-28: dated retirement (PROTO, option D1) ==")
    say("   phosphohistidine supports retired from 1964, single:", ex(s1, rules=PHOSPHO))
    at(s1, [1974], rules=PHOSPHO)
    both = dict(PHOSPHO, s09=1964, s10=1964)
    say("   and the two 1964 refutations retired too (CH-11):", ex(s1, rules=both))
    at(s1, [1974], rules=both)
    say("   phosphohistidine, dual:", ex(s2, rules=PHOSPHO))
    say("   all 7 reports retired (1964 and 1974), single:", ex(s1, rules=ALL_REPORTS))
    say("   all 7 reports retired, dual:", ex(s2, rules=ALL_REPORTS))
    at(s2, [1965, 1974], rules=ALL_REPORTS)
    say("   S own belief 2020, no supersession:", fmt(stmt_op(s1[1][1], STD, 2020)))

    say("\n== CH-15, CH-16: reviews ==")
    sf = two(face=True)
    say("   reviews at face value:", ex(sf))
    at(sf, [1962, 1974, 1977])
    rows += table_rows("face", sf)

    say("\n== CH-25 to CH-27: weights ==")
    EXP, REV = ["inVitro"], ["review"]
    for lab, W in [("std", STD), ("exp x2", scale(STD, 2, EXP)), ("exp x1/2", scale(STD, F(1, 2), EXP)),
                   ("review x2", scale(STD, 2, REV)), ("review x1/2", scale(STD, F(1, 2), REV)),
                   ("all x2", scale(STD, 2, EXP + REV)), ("all x1/2", scale(STD, F(1, 2), EXP + REV))]:
        say(f"   {lab:12} single: {ex(s1, W)}")
        say(f"   {'':12} dual:   {ex(s2, W)}")

    def side(kc, ks, dual=False):
        st = two(dual=dual)
        W2 = dict(STD, inVitroC=scale(STD, kc, EXP)["inVitro"], inVitroS=scale(STD, ks, EXP)["inVitro"])
        st = [(s, [dict(e, kind=e["kind"] + s if e["kind"] == "inVitro" else e["kind"]) for e in it]) for s, it in st]
        return st, W2
    for kc, ks in [(2, 1), (1, F(1, 2)), (2, F(1, 2)), (F(1, 2), 2)]:
        for d in (False, True):
            st, W2 = side(kc, ks, d)
            say(f"   C exp x{kc}, S exp x{ks}, {'dual' if d else 'single'}: {ex(st, W2)}; S refuted in "
                f"{spans(years_with(st, 'S', 'refuted', W2))}; S contested in {spans(years_with(st, 'S', 'contested', W2))}")

    say("\n== CH-28: the grid of 72 encodings ==")
    SUP = {"none": None, "phosphoHis": PHOSPHO, "allReports": ALL_REPORTS}
    WTS = {"std": STD, "x2": scale(STD, 2, EXP + REV), "x1/2": scale(STD, F(1, 2), EXP + REV)}
    grid, ok = [], 0
    for dual, face, sup, wt, mem in itertools.product([False, True], [False, True], SUP, WTS, [False, True]):
        st = two(dual=dual, face=face, drop_memory=mem)
        r = exit_test(st, WTS[wt], SUP[sup])
        ok += r["passed"]
        grid.append(["dual" if dual else "single", "face" if face else "advocate=hypothesis", sup, wt,
                     "dropped" if mem else "kept", r["c65"], r["s65"], r["c74"], r["s74"], r["c_est"], r["s_ref"],
                     "PASS" if r["passed"] else "fail"])
    say(f"   M2 exit passes in {ok} of {len(grid)} encodings")
    for g_ in grid:
        if g_[-1] == "PASS":
            say("     PASS:", g_[:5])
    say("   1965 C contested in", sum(g_[5] == "contested" for g_ in grid), "| 1974 C established in",
        sum(g_[7] == "established" for g_ in grid), "| 1974 S refuted in", sum(g_[8] == "refuted" for g_ in grid))
    say("   every PASS retires all reports and drops the memory items:",
        all(g_[2] == "allReports" and g_[4] == "dropped" for g_ in grid if g_[-1] == "PASS"))

    say("\n== E1 aside: memory-direction items dropped ==")
    say("   single:", ex(two(drop_memory=True)))
    say("   dual:  ", ex(two(drop_memory=True, dual=True)))
    say("   items:", MEMORY)
    say("   which memory items decide exit claim 2 (C established in 1974)? Every subset of the 6 C and S ones:")
    cs_mem = [k for k in MEMORY if k[0] in "cs"]
    for dual in (False, True):
        lab = "dual" if dual else "single"
        hits = []
        for n in range(1, len(cs_mem) + 1):
            for sub in itertools.combinations(cs_mem, n):
                if any(set(h) <= set(sub) for h in hits):
                    continue
                st = two(drop=sub, dual=dual)
                if verdicts(st, 1974)["C"] == "established":
                    hits.append(sub)
                    say(f"     {lab}: drop {sub}: 1965 C {verdicts(st, 1965)['C']}; C established in "
                        f"{spans(years_with(st, 'C', 'established'))}; S refuted in {spans(years_with(st, 'S', 'refuted'))}")
        say(f"     {lab}: {len(hits)} smallest subset(s) found")

    say("\n== CH-17: one lab, one vote (PROTO, option G, crude) ==")
    lab1 = [("C", per_lab(items("C"))), ("S", per_lab(items("S")))]
    say("   items kept:", {s: len(it) for s, it in lab1}, "of", {s: len(it) for s, it in s1})
    say("  ", ex(lab1))
    say("   C contested in", spans(years_with(lab1, "C", "contested")), "| S contested in",
        spans(years_with(lab1, "S", "contested")))
    lab2 = [("C", per_lab(items("C", dual=True))), ("S", per_lab(items("S", dual=True)))]
    say("   dual:", ex(lab2))

    say("\n== CH-29: the 2013 textbook sentence added to C ==")
    tb = dict(key="tb", pmid=0, year=2013, kind="textbook", pol="+", lab="OpenStax")
    st = [("C", items("C") + [tb]), ("S", items("S"))]
    at(st, [2012, 2013])

    say("\n== option I2: rival scope by own evidence (PROTO) ==")
    for lab, stm, ys in [("single", s1, [1962, 1963, 1965, 1974]), ("three", t3, [1963, 1965, 1974, 1994]),
                         ("four", t4, [1965, 1974])]:
        for y in ys:
            say(f"   {lab} {y}: " + "  ".join(f"{s}: {fmt(o)} {verdict(o)}" for s, o in scoped(stm, STD, y)))
    say("   the example (illustrative), 1965 and 1974:")
    chemi_x = [E("m61", 13771349, 1961, "hypothesis"), E("p65", 0, 1965, "inVitro")] + chemi[1:]
    chem_x = [E("s53", 13111237, 1953, "hypothesis"), E("r63", 0, 1963, "hypothesis"), E("i65", 0, 1965, "inVitro")] + chem[1:]
    for y in [1965, 1974]:
        say(f"     {y}: " + "  ".join(f"{s}: {fmt(o)} {verdict(o)}" for s, o in scoped([("C", chemi_x), ("S", chem_x)], STD, y)))
        say(f"     {y} realCoupling: " + "  ".join(f"{s}: {fmt(o)} {verdict(o)}" for s, o in scoped(real, STD, y)))

    say("\n== option H: multinomial shares (PROTO) ==")
    for lab, stm in [("C,S", s1), ("C,S,W", t3)]:
        for y in [1965, 1974, 1977, 2020]:
            sh, u = multinomial(stm, STD, y)
            say(f"   {lab} {y}: " + "  ".join(f"{k} {dec(v)}" for k, v in sh.items()) + f"  u {dec(u)}")


    say("\n== CH-19: Williams with his real record (three rivals, single entry) ==")
    for v in ("established", "contested", "refuted", "unsupported"):
        say(f"   C {v}: {spans(years_with(t3, 'C', v))} | W {v}: {spans(years_with(t3, 'W', v))}")
    at(t3, [1965, 1974, 1981, 1982, 1983, 1985, 1989, 1991, 2014, 2020, 2024])
    wi = items("W")
    say("   W own (no rivalry): " + "  ".join(f"{y} {fmt(stmt_op(wi, STD, y))} {verdict(stmt_op(wi, STD, y))}"
                                         for y in (1982, 1985, 1991, 2020, 2024)))
    t3f = three(drop=("w14",))
    say("   Ferguson 1985 (memory) dropped:", " ".join(f"{y} W {fmt(run(t3f, y)[2][2])} {verdict(run(t3f, y)[2][2])}"
                                                  for y in (1985, 1991, 2020)))
    say("   leave one out over W's items, three rivals, years 1985, 1994, 2020:")
    ref3 = {y: verdicts(t3, y) for y in (1985, 1994, 2020)}
    for e in REC:
        if e["rival"] != "W" or e["direction"] == "neutral":
            continue
        t3d_ = three(drop=(e["key"],))
        fl = [f"{y} {s_}: {ref3[y][s_]}->{verdicts(t3d_, y)[s_]}" for y in ref3 for s_ in "CSW"
              if verdicts(t3d_, y)[s_] != ref3[y][s_]]
        if fl:
            say(f"     drop {e['key']} ({e['first_author']} {e['year']}, {e['basis']}): " + "; ".join(fl))
    for lab, W in [("all x2", scale(STD, 2, ["inVitro", "review"])), ("all x1/2", scale(STD, F(1, 2), ["inVitro", "review"]))]:
        say(f"   {lab}: C established {spans(years_with(t3, 'C', 'established', W))}; C contested "
            f"{spans(years_with(t3, 'C', 'contested', W))}; W refuted {spans(years_with(t3, 'W', 'refuted', W))}; "
            f"W contested {spans(years_with(t3, 'W', 'contested', W))}")

    say("\n== CH-43: Nath 2017 as a hypothesis (baseline) or as an ordinary review ==")
    nath = [("C", [dict(e, kind="review") if e["key"] == "c25" else e for e in items("C")]), ("S", items("S"))]
    say("   baseline:"); at(s1, [2016, 2017])
    say("   as review:"); at(nath, [2016, 2017, 2020])

    say("\n== CH-44: Silva 2020 counted as new support ==")
    at(two(drop=("c26",)), [2020]); at(s1, [2020])
    say("   C own 2020 without / with Silva:", fmt(stmt_op(items("C", drop=("c26",)), STD, 2020)),
        fmt(stmt_op(items("C"), STD, 2020)))

    say("\n== CH-45: murburn as a fourth rival ==")
    at(rivals("CSWM"), [2018, 2019, 2020])
    at(rivals("CM"), [2019])

    say("\n== CH-46: Slater 1985 (hypothesis) left out ==")
    say("   identical in 1985 and 2020:", all(run(two(drop=("s13",)), y)[i][2] == run(s1, y)[i][2]
                                              for y in (1985, 2020) for i in (0, 1)))

    say("\n== CH-47: the 1978 Nobel presentation as a .textbook item on C ==")
    nob = dict(key="k01", pmid=0, year=1978, kind="textbook", pol="+", lab="Nobel")
    tb = dict(key="tb", pmid=0, year=2013, kind="textbook", pol="+", lab="OpenStax")
    st = [("C", items("C") + [nob]), ("S", items("S"))]
    say("   single:"); at(st, [1977, 1978, 2020])
    std_ = [("C", items("C", dual=True) + [nob]), ("S", items("S", dual=True))]
    say("   dual:"); at(std_, [1978, 2020])
    say("   dual, C established in:", spans(years_with(std_, "C", "established")))
    st2 = [("C", items("C") + [nob, tb]), ("S", items("S"))]
    say("   single with the 2013 textbook too:"); at(st2, [2013, 2020])

    say("\n== CH-48: thresholds (theta, tau), single entry ==")
    for th, tau in [(TH, TAU), (TH, F(1, 5)), (TH, F(3, 10)), (F(3, 4), TAU), (F(7, 10), TAU), (F(17, 20), TAU)]:
        ys = [y for y in YEARS if verdict(run(s1, y)[0][2], th, tau) == "established"]
        cells = [f"{y} C {verdict(run(s1, y)[0][2], th, tau)} S {verdict(run(s1, y)[1][2], th, tau)}" for y in (1965, 1974)]
        say(f"   theta={th} tau={tau}: " + " | ".join(cells) + f" | C established {spans(ys)}")
    o74 = run(s1, 1974)[0][2]
    say(f"   1974 C: d = {o74[1]} ; tau - d = {TAU - o74[1]}")
    def relevant(o):
        """Distance to the nearest threshold whose crossing changes the verdict (moving b or d alone)."""
        b, d, _ = o
        v, best, eps = verdict(o), F(1), F(1, 10 ** 9)
        for nb, nd in [(TAU, d), (TAU - eps, d), (TH, d), (TH - eps, d), (b, TAU), (b, TAU - eps), (b, TH), (b, TH - eps)]:
            if nb >= 0 and nd >= 0 and nb + nd <= 1 and verdict((nb, nd, 1 - nb - nd)) != v:
                best = min(best, max(abs(nb - b), abs(nd - d)))
        return best
    for lab, stm in [("single", s1), ("dual", s2)]:
        near = [y for y in YEARS if margin(run(stm, y)[0][2]) < F(1, 50)]
        near_rel = [y for y in YEARS if relevant(run(stm, y)[0][2]) < F(1, 50)]
        say(f"   {lab}: C within 0.02 of a threshold in {len(near)} years ({spans(near)}); of a verdict-changing "
            f"threshold in {len(near_rel)} years; same years: {near == near_rel}")

    say("\n== CH-49: the 1966 grey book as a second item (PMID 0) beside the Biol Rev paper ==")
    grey = dict(key="grey", pmid=0, year=1966, kind="review", pol="+", lab="Mitchell")
    for face in (False, True):
        c = items("C", face=face)
        g_ = dict(grey, kind="review" if face else "hypothesis")
        a, b_ = two(face=face), [("C", c + [g_]), ("S", items("S", face=face))]
        say(f"   {'face value' if face else 'baseline'}: 1974 C {fmt(run(a, 1974)[0][2])} -> {fmt(run(b_, 1974)[0][2])}")

    say("\n== option I: rival scope, two variants (PROTO) ==")
    def scoped_from(stmts, year, hyp_counts):
        own = []
        for sid, it in stmts:
            cut = [e for e in it if e["year"] <= year]
            has = any(hyp_counts or e["kind"] != "hypothesis" for e in cut)
            own.append((sid, stmt_op(it, STD, year), has))
        out = []
        for i, (sid, o, has) in enumerate(own):
            r = o
            if has:
                for j, (_, t, _) in enumerate(own):
                    if j != i:
                        r = fuse(r, against(t))
            out.append((sid, r))
        return out
    for lab, hyp in [("I1 proposal year", True), ("I2 own evidence", False)]:
        for nm, stm in [("C,S", s1), ("C,S,W", t3), ("C,S,W,G", t4)]:
            ysW = {sid: [y for y in YEARS if verdict(dict(scoped_from(stm, y, hyp))[sid]) == "refuted"] for sid, _ in stm}
            say(f"   {lab} {nm}: refuted years " + "; ".join(f"{k} {spans(v)}" for k, v in ysW.items()))

    say("\n== option H: multinomial shares coarsened to one rival (PROTO) ==")
    for y in (1965, 1974, 1985, 2020):
        sh, u = multinomial(t4, STD, y)
        say(f"   {y}: " + "  ".join(f"{k} b={dec(v)} d={dec(1 - u - v)} {verdict((v, 1 - u - v, u))}" for k, v in sh.items() if k != "other")
            + f"  other {dec(sh['other'])} u {dec(u)}")

    for lab, stm in [("C,S", s1), ("C,S,W", t3)]:
        best = max((multinomial(stm, STD, y)[0]["C"], y) for y in YEARS)
        say(f"   {lab}: C's highest share over 1950 to 2025: {dec(best[0])} in {best[1]}")

    say("\n== option N: forgetting, each item's pseudo-count halves every h years (PROTO) ==")
    for h in (5, 10, 20):
        for dual, stm in [(False, s1), (True, s2)]:
            vs = {y: [verdict(o) for _, o in forgetting(stm, y, h)] for y in YEARS}
            o20 = forgetting(stm, 2020, h)
            say(f"   h={h:2} {'dual' if dual else 'single'}: 1965 {vs[1965]} | 1974 {vs[1974]} | C established "
                f"{spans([y for y in YEARS if vs[y][0] == 'established'])} | S refuted "
                f"{spans([y for y in YEARS if vs[y][1] == 'refuted'])} | 2020 C {fmt(o20[0][1])} {vs[2020][0]}, "
                f"S {fmt(o20[1][1])} {vs[2020][1]}")
    same = all(forgetting(st_, y, 1000)[i][1] == run(st_, y)[i][2] for st_ in (s1, s2) for y in (1965, 1974, 2020)
               for i in (0, 1))
    say("   check: with h = 1000 (no forgetting) it equals the core's Rivalry in 1965, 1974, 2020:", same)

    say("\n== option J: rival hierarchy as two rivalries (curator encoding) ==")
    child = [("bulk", []), ("W", items("W"))]
    for y in (1974, 1982, 1985, 1991, 2020, 2024):
        say(f"   {y} parent " + "  ".join(f"{sid}: {fmt(r)} {verdict(r)}" for sid, _, r in run(s1, y)) +
            " | child " + "  ".join(f"{sid}: {fmt(r)} {verdict(r)}" for sid, _, r in run(child, y)))
    for v in ("established", "contested", "refuted", "unsupported"):
        say(f"   child W {v}: {spans(years_with(child, 'W', v))}")

    with open(os.path.join(OUT, "run_output.txt"), "w") as f:
        f.write("\n".join(LINES) + "\n")
    hdr = ["encoding", "year", "rival", "b", "d", "verdict", "margin", "own_b", "own_d", "own_verdict"]
    with open(os.path.join(OUT, "year_table.tsv"), "w") as f:
        f.write("\t".join(hdr) + "\n" + "\n".join("\t".join(map(str, r)) for r in rows) + "\n")
    with open(os.path.join(OUT, "loo.tsv"), "w") as f:
        f.write("encoding\tleft_out\tpmid\tyear\tfirst_author\tdirection_basis\tflips\n")
        f.write("\n".join("\t".join(map(str, r)) for r in loo_rows) + "\n")
    with open(os.path.join(OUT, "grid.tsv"), "w") as f:
        f.write("entry\treviews\tsupersession\tweights\tmemory_items\tC_1965\tS_1965\tC_1974\tS_1974\t"
                "C_established_from\tS_refuted_from\texit\n")
        f.write("\n".join("\t".join(map(str, r)) for r in grid) + "\n")
    print("\n".join(LINES))


if __name__ == "__main__":
    main()
