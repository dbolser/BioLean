"""Program 09, option E (added at build, 2026-10-31): an independent check of the Lean prototype
`BioLean.Proto.ChemiosmosisReal.liftAt`, in exact fractions, from the mirror's core functions.

Option E moves the four phosphohistidine items (Boyer 1962, Peter 1963 for; Mitchell RA 1964,
Kreil 1964 against) from S to a narrower claim, "via phospho-L-histidine", and lifts that claim
to S with `Opinion.weakest` against a definitional is_a (999/1000): belief passes up, disbelief
does not. The lifted opinion is fused into S's own opinion; then the two-rival rivalry step.

Writes data/stress/09/lift.tsv (every year 1950 to 2025, single and dual entry) and checks the
numbers the Lean file pins.

    python3 scripts/stress/chemiosmosis_lift.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from chemiosmosis_mirror import F, ROOT, STD, against, fmt, fuse, items, stmt_op, verdict  # noqa: E402

PH = {14014715, 13942705, 5871845, 5332854}
ISA = (STD["definitional"], F(0), 1 - STD["definitional"])


def weakest(x, y):
    b = min(x[0], y[0])
    return (b, F(0), 1 - b)


def lift_at(year, dual=False):
    c_items = items("C", dual=dual)
    s_items = items("S", dual=dual)
    ph = [e for e in s_items if e["pmid"] in PH]
    rest = [e for e in s_items if e["pmid"] not in PH]
    lifted = weakest(stmt_op(ph, year=year), ISA)
    c = stmt_op(c_items, year=year)
    s = fuse(stmt_op(rest, year=year), lifted)
    return fuse(c, against(s)), fuse(s, against(c)), s, lifted


def cell(o):
    return f"{fmt(o)} {verdict(o)}"


def main():
    pins = {  # the strings the Lean file pins with #guard
        ("single", 1963): ["b=0.000 d=0.866 refuted", "b=0.866 d=0.000 established"],
        ("single", 1965): ["b=0.327 d=0.563 contested", "b=0.563 d=0.327 contested"],
        ("single", 1974): ["b=0.586 d=0.368 contested", "b=0.536 d=0.376 contested"],
        ("dual", 1974): ["b=0.763 d=0.177 unsupported", "b=0.373 d=0.565 contested"],
    }
    rows, bad = [], 0
    for enc, dual in (("single", False), ("dual", True)):
        for y in range(1950, 2026):
            c, s, s_own, lifted = lift_at(y, dual)
            rows.append([enc, str(y), cell(c), cell(s), cell(s_own), fmt(lifted)])
            if (enc, y) in pins and [cell(c), cell(s)] != pins[(enc, y)]:
                bad += 1
                print(f"DIFF {enc} {y}: mirror {[cell(c), cell(s)]} | lean {pins[(enc, y)]}")
    _, _, s_own, lifted = lift_at(1974)
    assert cell(s_own) == "b=0.860 d=0.000 established" and fmt(lifted) == "b=0.400 d=0.000", (s_own, lifted)
    single_c = [r for r in rows if r[0] == "single"]
    contested = [int(r[1]) for r in single_c if r[2].endswith("contested")]
    established = [int(r[1]) for r in rows if r[0] == "dual" and r[2].endswith("established")]
    assert contested == list(range(1965, 2026)), contested
    assert established == [1977], established
    assert not any(r[3].endswith("refuted") for r in rows), "S refuted somewhere"
    with open(os.path.join(ROOT, "data/stress/09/lift.tsv"), "w") as f:
        f.write("encoding\tyear\tC under rivalry\tS under rivalry\tS own (with lift)\tlifted opinion\n")
        f.writelines("\t".join(r) + "\n" for r in rows)
    print(f"option E: {len(pins) - bad} of {len(pins)} pinned rows agree; single entry C contested 1965 to 2025, "
          f"dual entry C established {established}; S never refuted")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
