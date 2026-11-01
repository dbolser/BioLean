"""Program 08 (review): can D-b's or-elimination be a rule of the core `Derivation`?

The prototype's `XDerivation.orElim` takes two Lean functions `Derivation p → Derivation r`. That
works there only because `XDerivation` is a different type from `Derivation`. Put inside the type
being defined, the same constructor has a non-positive occurrence, which Lean's kernel refuses.

This script writes a small Lean file to /tmp/biolean-08/positivity/ (our own file, not a download),
runs `lake env lean` on it from the repo root, and records the file and Lean's answer in
data/stress/08/orelim_positivity.txt. The file is expected to FAIL; that failure is the result.

    python3 scripts/stress/gaps_positivity.py
"""

import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TMP = "/tmp/biolean-08/positivity"
OUT = os.path.join(ROOT, "data", "stress", "08", "orelim_positivity.txt")

LEAN = """import BioLean.Derivation
open BioLean

/-- D-b's or-elimination written as a rule of a derivation type over the core `Claim`, the way
`XDerivation.orElim` is written in `BioLean/Proto/SchemaGaps.lean`, but recursive in itself. -/
inductive DerivationOr : Claim → Type
  | lit (s : Statement) : DerivationOr s.claim
  | orElim {p q r : Claim} (f : DerivationOr p → DerivationOr r) (g : DerivationOr q → DerivationOr r) :
      DerivationOr r
"""


def main():
    os.makedirs(TMP, exist_ok=True)
    path = os.path.join(TMP, "OrElim.lean")
    with open(path, "w") as f:
        f.write(LEAN)
    r = subprocess.run(["lake", "env", "lean", path], cwd=ROOT, capture_output=True, text=True, timeout=600)
    out = (r.stdout + r.stderr).replace(TMP + "/", "")
    refused = "non positive occurrence" in out or "non-positive occurrence" in out
    with open(OUT, "w") as f:
        f.write("Program 08 review: or-elimination inside the core Derivation type.\n")
        f.write("Written by scripts/stress/gaps_positivity.py. Expected: Lean refuses the declaration.\n\n")
        f.write("--- OrElim.lean ---\n" + LEAN + "\n--- lake env lean (exit code %d) ---\n" % r.returncode + out)
        f.write("\n--- result ---\n" + ("REFUSED: non-positive occurrence (as expected)\n" if refused else "NOT REFUSED (unexpected)\n"))
    print("refused" if refused else "NOT refused", "->", OUT)


if __name__ == "__main__":
    main()
