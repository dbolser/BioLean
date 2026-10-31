"""Program 09: compare the year tables Lean prints with the Python mirror, cell by cell.

    lake env lean BioLean/Stress/ChemiosmosisReal.lean > /tmp/biolean-09/build/lean.out
    python3 scripts/stress/chemiosmosis_crosscheck.py /tmp/biolean-09/build/lean.out

The Lean file prints three tables (single entry, dual entry, three rivals). Each cell
"b=... d=... verdict" must equal the mirror's cell for the same rival and year.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from chemiosmosis_mirror import fmt, run, three, two, verdict  # noqa: E402

ENC = {"single entry": two(), "dual entry": two(dual=True), "three rivals": three()}


def main(path):
    text = open(path).read()
    cur, n, bad = None, 0, 0
    for line in text.splitlines():
        if line.strip() in ENC:
            cur = line.strip()
            continue
        m = re.match(r"^(\d{4})  (.*)$", line)
        if not (cur and m):
            continue
        y = int(m.group(1))
        lean_cells = re.findall(r"(b=\d\.\d{3} d=\d\.\d{3} \w+)", m.group(2))
        mirror_cells = [f"{fmt(r)} {verdict(r)}" for _, _, r in run(ENC[cur], y)]
        for a, b in zip(lean_cells, mirror_cells):
            n += 1
            if a != b:
                bad += 1
                print(f"DIFF {cur} {y}: lean {a} | mirror {b}")
    print(f"{n - bad} of {n} cells agree")
    return 1 if bad or n == 0 else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1]))
