"""Program 06: print the compiled R2 and R3 Lean statements for given textbook ids (or id prefixes).

Usage: python3 scripts/stress/opposes_show.py the-body-s-systems-m45537-199 the-body-s-systems-m45539-3
Read-only.
"""
import glob
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def blocks():
    for rnd in ("R2", "R3"):
        for f in sorted(glob.glob(str(ROOT / f"BioLean/Lib/TextbookClaims{rnd}/*.lean"))):
            text = Path(f).read_text()
            for m in re.finditer(r"def (\S+) : Statement where\n(.*?)(?=\n/--|\n-- |\ndef |\Z)", text, re.S):
                body = m.group(2)
                idm = re.search(r'id := "([^"]+)"', body)
                if idm:
                    yield rnd, Path(f).stem, m.group(1), idm.group(1), body


def main(args):
    for rnd, mod, name, sid, body in blocks():
        if any(sid == a or sid.startswith(a) for a in args):
            claim = re.search(r"claim := (.*)", body)
            print(f"{rnd}\t{mod}.{name}\t{claim.group(1) if claim else '?'}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
