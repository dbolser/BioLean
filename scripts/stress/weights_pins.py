"""Program 10a: turn an observed run of BioLean/Stress/Weights.lean into `#guard` pins.

Reads the CASE / EXBASE / SCHEME / SCHEMEEX / EXIT / OBS / SENSEX / SENSST / MARGIN lines that the
file's printers (section 8) write, and replaces the block between

    -- BEGIN GENERATED PINS (scripts/stress/weights_pins.py)
    -- END GENERATED PINS

in Weights.lean with one `#guard` per observed fact. Nothing here computes a belief: every value
is copied from the Lean output, and the pins then make Lean re-check it on every compile.

usage: python3 scripts/stress/weights_pins.py LEAN_OUTPUT.txt
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEAN = ROOT / "BioLean/Stress/Weights.lean"
BEGIN = "-- BEGIN GENERATED PINS (scripts/stress/weights_pins.py)"
END = "-- END GENERATED PINS"
MARK = {"PASS": ".pass", "FAIL": ".fail", "SILENT": ".silent", "INEXPRESSIBLE": ".inexpressible"}


def q(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def lean_list(printed):
    """A printed `[a, b]` list of strings (no commas inside items except ', ' separators we control)."""
    inner = printed.strip()[1:-1].strip()
    if not inner:
        return []
    # items are separated by ", " followed by a check name; split on ", " where the next token starts
    # a new item (an example check name or a case id)
    return re.split(r", (?=(?:oz\.|ch\.|thm |[A-Z]+\d+ ))", inner)


def scheme_idents(src):
    """Scheme display name -> Lean identifier, read from the definitions."""
    out = {"core": "core"}
    for ident, name in re.findall(r'def (\w+)\s*(?::\s*Scheme)?\s*:=\s*(?:mkScheme|coreWith)\s+"([^"]+)"', src):
        out.setdefault(name, ident)
    for ident, name in re.findall(r'def (\w+) : Scheme := \{ (?:core with )?name := "([^"]+)"', src):
        out.setdefault(name, ident)
    return out


def rat(s):
    s = s.strip()
    return f"({s} : ℚ)" if "/" in s else f"({s} : ℚ)"


def opt_rat(s):
    s = s.strip()
    if s == "none":
        return "none"
    m = re.fullmatch(r"\(some (.+)\)", s)
    return f"some {rat(m.group(1))}"


def main():
    lines = Path(sys.argv[1]).read_text().splitlines()
    src = LEAN.read_text()
    idents = scheme_idents(src)
    rows = [l.split("\t") for l in lines if "\t" in l]
    pins = []

    pins.append("/-! ### Every case under the core (observed 2026-10-31) -/")
    for r in rows:
        if r[0] == "CASE":
            pins.append(f"#guard pin core case_{r[1]} {q(r[2])} {MARK[r[3]]}")

    pins.append("")
    pins.append("/-! ### The example checks under the core: Ozempic and Chemiosmosis verdicts, signs, theorems -/")
    ex = [f"({q(r[1])}, {q(r[2])})" for r in rows if r[0] == "EXBASE"]
    pins.append("#guard exBase == [" + ",\n    ".join(ex) + "]")

    pins.append("")
    pins.append("/-! ### Every scheme: mark string (one letter per case, in `cases` order), observed values that")
    pins.append("differ from the core's, example-check flips, and exit-test wordings A and B -/")
    schemes = [r for r in rows if r[0] == "SCHEME"]
    exs = {r[1]: r[3] for r in rows if r[0] == "SCHEMEEX"}
    exits = {r[1]: (r[4], r[5]) for r in rows if r[0] == "EXIT"}
    for r in schemes:
        name, marks, tally = r[1], r[2], r[3]
        ident = idents[name]
        base = {x[1]: x[2] for x in rows if x[0] == "CASE"}
        diffs = [(x[2], x[3]) for x in rows if x[0] == "OBS" and x[1] == name and x[3] != base[x[2]]]
        dl = "[" + ", ".join(f"({q(a)}, {q(b)})" for a, b in diffs) + "]"
        el = "[" + ", ".join(q(x) for x in lean_list(exs[name])) + "]"
        a, b = exits[name]
        t = tally.replace("(", "").replace(")", "").replace(" ", "").split(",")
        pins.append(f"-- {name}: PASS {t[0]}, FAIL {t[1]}, SILENT {t[2]}, INEXPRESSIBLE {t[3]}")
        pins.append(f"#guard pinScheme {ident} {q(marks)}\n  {dl}\n  {el} {a} {b}")

    pins.append("")
    pins.append("/-! ### Sensitivity (section 4): each pseudo-count x2 and x1/2 -/")
    sx = [f"({q(r[1])}, [{', '.join(q(x) for x in lean_list(r[3]))}])" for r in rows if r[0] == "SENSEX"]
    pins.append("-- Example-check flips per run.")
    pins.append("#guard sensExample == [" + ",\n    ".join(sx) + "]")
    ss = [f"({q(r[1])}, [{', '.join(q(x) for x in lean_list(r[3]))}])" for r in rows if r[0] == "SENSST"]
    pins.append("-- Stress-set mark changes per run.")
    pins.append("#guard sensStress == [" + ",\n    ".join(ss) + "]")
    mg = []
    for r in rows:
        if r[0] == "MARGIN":
            sg = r[4].strip()[1:-1].strip()
            sgl = "[" + ", ".join(rat(x) for x in sg.split(",") if x.strip()) + "]"
            mg.append(f"({q(r[1])}, {opt_rat(r[2])}, {opt_rat(r[3])}, {sgl})")
    pins.append("-- For each kind: the factor nearest 1 below and above 1 at which an example check first flips,")
    pins.append("-- and the grid factors at which an Ozempic sign flips.")
    pins.append("#guard margins == [" + ",\n    ".join(mg) + "]")

    block = BEGIN + "\n" + "\n".join(pins) + "\n" + END
    new = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END), lambda _: block, src, flags=re.S)
    LEAN.write_text(new)
    n = sum(1 for p in pins if p.startswith("#guard"))
    print(f"wrote {n} generated pins into {LEAN.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
