"""Program 09, review addition (2026-10-31): an independent check, in exact fractions, of two
results the Lean file pins.

1. CH-50: the 1978 Nobel presentation speech on both rivals, as `.textbook` items (4/5): "the basic
   postulates ... generally regarded as experimentally proven" for C, and "no experimental evidence
   could be obtained" for the chemical intermediates, entered against S (Lean: `withNobelBoth`).
2. Option D1 with checked dates only: the two phosphohistidine reports retired from 1964 (the 1964
   reassignments), the other five reports from 1978 (the same speech, read as a blanket retirement)
   (Lean: `BioLean.Proto.ChemiosmosisReal.ernsterDates`).

Writes data/stress/09/consensus.tsv (every year 1950 to 2025) and checks every number the Lean
file pins for these two. Nothing here is a core change.

    python3 -B scripts/stress/chemiosmosis_consensus.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from chemiosmosis_mirror import F, PHOSPHO, ROOT, fmt, items, run, spans, verdict  # noqa: E402

YEARS = range(1950, 2026)
NOBEL_C = dict(key="nobel78", pmid=0, year=1978, kind="textbook", lab="Nobel", pol="+")
NOBEL_S = dict(key="ernster78S", pmid=0, year=1978, kind="textbook", lab="Nobel", pol="-")
ERNSTER = dict(PHOSPHO, **{k: 1978 for k in ("s03", "s04", "s05", "s11", "s12")})


def both(dual):
    return [("C", items("C", dual=dual) + [NOBEL_C]), ("S", items("S", dual=dual) + [NOBEL_S])]


def plain(dual, drop_memory=False):
    return [("C", items("C", dual=dual, drop_memory=drop_memory)),
            ("S", items("S", dual=dual, drop_memory=drop_memory))]


def cell(o):
    return f"{fmt(o)} {verdict(o)}"


def at(stmts, year, rules=None):
    return [r for _, _, r in run(stmts, year, rules=rules)]


def years(stmts, i, v, rules=None):
    return [y for y in YEARS if verdict(at(stmts, y, rules)[i]) == v]


def exit78(stmts, rules):
    return verdict(at(stmts, 1965, rules)[0]) == "contested" and \
        [verdict(o) for o in at(stmts, 1978, rules)] == ["established", "refuted"]


def main():
    checks = [
        # CH-50 (Stress part)
        ([cell(o) for o in at(both(False), 1978)], ["b=0.804 d=0.157 established", "b=0.407 d=0.544 contested"]),
        ([cell(o) for o in at(both(False), 2020)], ["b=0.815 d=0.149 established", "b=0.400 d=0.552 contested"]),
        (years(both(False), 0, "established"), list(range(1978, 2026))),
        (years(both(False), 1, "contested"), list(range(1964, 2026))),
        (years(both(False), 1, "refuted") + years(both(True), 1, "refuted"), []),
        (years(both(True), 0, "established"), list(range(1977, 2026))),
        ([cell(o) for o in at(both(True), 1978)], ["b=0.823 d=0.138 established", "b=0.304 d=0.659 contested"]),
        # D1 with checked dates (Proto part)
        ([cell(o) for o in at(plain(True), 1978, ERNSTER)], ["b=0.808 d=0.145 established", "b=0.094 d=0.842 refuted"]),
        (years(plain(True), 0, "established", ERNSTER), list(range(1976, 2026))),
        (years(plain(True), 1, "refuted", ERNSTER), list(range(1978, 2026))),
        ([verdict(o) for o in at(plain(True), 1965, ERNSTER)], ["unsupported", "contested"]),
        ([verdict(o) for o in at(plain(False), 1965, ERNSTER)], ["contested", "contested"]),
        ([cell(o) for o in at(plain(False), 1978, ERNSTER)], ["b=0.795 d=0.159 unsupported", "b=0.169 d=0.718 unsupported"]),
        (years(plain(False), 0, "established", ERNSTER), list(range(2020, 2026))),
        (years(plain(False), 1, "refuted", ERNSTER), []),
        ([exit78(plain(False), ERNSTER), exit78(plain(True), ERNSTER)], [False, False]),
        (exit78(plain(False, True), ERNSTER), True),
        (at(plain(False, True), 1965, ERNSTER)[0][:2], (F(1, 2), F(1, 4))),
        (years(plain(False, True), 0, "established", ERNSTER), [1969] + list(range(1971, 2026))),
        (years(plain(False, True), 1, "refuted", ERNSTER), list(range(1978, 2026))),
        ([verdict(o) for o in at(plain(False, True), 1974, ERNSTER)], ["established", "unsupported"]),
        ([cell(o) for o in at(plain(False, True), 1978, ERNSTER)], ["b=0.882 d=0.058 established", "b=0.000 d=0.904 refuted"]),
        (exit78(plain(True, True), ERNSTER), True),
    ]
    bad = [i for i, (got, want) in enumerate(checks) if got != want]
    rows = []
    for name, stmts, rules in [("K both, single", both(False), None), ("K both, dual", both(True), None),
                               ("D1 checked dates, single", plain(False), ERNSTER),
                               ("D1 checked dates, dual", plain(True), ERNSTER),
                               ("D1 checked dates, single, memory items dropped", plain(False, True), ERNSTER),
                               ("D1 checked dates, dual, memory items dropped", plain(True, True), ERNSTER)]:
        for y in YEARS:
            c, s = at(stmts, y, rules)
            rows.append([name, str(y), cell(c), cell(s)])
    with open(os.path.join(ROOT, "data/stress/09/consensus.tsv"), "w") as f:
        f.write("encoding\tyear\tC under rivalry\tS under rivalry\n")
        f.writelines("\t".join(r) + "\n" for r in rows)
    print(f"{len(checks) - len(bad)} of {len(checks)} pinned values agree"
          + ("" if not bad else f"; DISAGREE at {bad}"))
    print("K both, single: C established", spans(years(both(False), 0, "established")),
          "; S refuted", spans(years(both(False), 1, "refuted")))
    print("D1 checked dates, single, memory dropped: exit restated for 1978 passes;",
          "1965 C (b, d) =", tuple(str(x) for x in at(plain(False, True), 1965, ERNSTER)[0][:2]))
    if bad:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
