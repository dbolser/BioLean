"""Program 10a: write the stress-set tables from an observed Lean run.

Runs `lake env lean BioLean/Stress/Weights.lean` (or reads a saved output given as the argument),
parses the lines its printers write (section 8: PC, CASE, EXBASE, SCHEME, SCHEMEEX, EXIT, OBS,
SENSEX, SENSST, MARGIN), joins them with the case descriptions in data/stress/10a/case_spec.json,
and writes into data/stress/10a/:

  cases.tsv          one row per case: probes, input, correct conclusion, observed, mark, test, source
  schemes.tsv        case x scheme: mark and observed value under each scheme (long format)
  scheme_summary.tsv one row per scheme: option, core change or not, tally, fixed and lost cases,
                     example-check flips, Ozempic sign flips, exit-test wordings A and B
  sensitivity.tsv    each pseudo-count x2 and x1/2: flips in the examples and in the stress set
  margins.tsv        per kind: the factor nearest 1 at which an example check first flips
  pseudocounts.tsv   reliability and pseudo-count of every evidence kind

Observed values come only from the Lean output; nothing here computes a belief. The same values
are pinned in Weights.lean (`#guard`, section 7), so the run that writes these tables also checks
them.

usage: uv run python scripts/stress/weights_cases.py [SAVED_LEAN_OUTPUT]
"""
import json
import subprocess
import sys
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/10a"
LEAN = "BioLean/Stress/Weights.lean"
SPEC = OUT / "case_spec.json"

# scheme name -> (option letters, core change?)
SCHEMES = {
    "core": ("core", "today's core"),
    "B1 ECO and design remap": ("B1", "no: the importer maps a GO evidence code or a meta-analysis's pooled design to an existing kind"),
    "C1 GRADE-like cap, whole statement": ("C1", "yes if derivations use it: a certainty on Statement and a change to Statement.opinion"),
    "C2 GRADE-like cap, clinical part of effect claims": ("C2", "yes if derivations use it: as C1"),
    "D curated groups": ("D", "D-core yes: averaging operator and a source key on Evidence; D-import no: one item per group"),
    "D auto groups": ("D (auto key)", "as D; key = shared first or last author"),
    "D curated groups, reviews one source": ("D (reviews one source)", "as D"),
    "E meta replaces its primaries": ("E", "E1 no: import rule with a pools table; E2 yes: a pools field on Evidence"),
    "F extraction factor": ("F", "yes: a reader-precision field on Evidence and a change to Evidence.opinion"),
    "G ceilings, INDRA values": ("G", "yes: a ceiling in EvidenceModel and a change to Statement.opinion"),
    "G ceilings, guessed values": ("G (guessed)", "as G"),
    "H drop retracted": ("H", "H1 no: the importer drops retracted items; H2 yes: status and date on Evidence"),
    "I Ioannidis table": ("I", "no: a new EvidenceModel instance"),
    "J base rate in verdict": ("J", "yes: a base rate on Statement or Claim and a change to the verdict"),
    "K size": ("K", "yes: a size field on Evidence and a change to Evidence.opinion"),
    "M polarity weights (inVitro)": ("M", "yes: a second reliability per kind in EvidenceModel"),
    "M+H polarity weights, drop retracted": ("M+H", "as M"),
    "N1 supersession table": ("N1 (dated)", "yes as run: the year asked must reach the table, a 'superseded in' year on Evidence that Statement.asOf honours"),
    "N2 ageing, half-life 10 years": ("N2", "yes: a half-life in EvidenceModel and a change to Evidence.opinionAt"),
    "H1+I": ("H1+I", "no"),
    "H1+I+N1": ("H1+I+N1 (dated)", "yes for the dated N1; H1 and I need none"),
    "H+E+D hygiene": ("H+E+D", "D needs the core unless groups are curated into one item at import"),
    "H+E+D+B1+G+K+F": ("H+E+D+B1+G+K+F", "yes (G, K, F)"),
    "outside core: H+E+D+B1+I": ("H+E+D+B1+I", "no, with D as one item per group at import"),
    "outside core: H+E+D+B1+I+N1": ("H+E+D+B1+I+N1 (dated)", "no for H, E, D (one item per group), B1, I; the dated N1 is a core change"),
    "outside core: H+E+D+B1+I+N1 at import (undated)": ("H+E+D+B1+I+N1 (import)", "no: every part an import rule or a new EvidenceModel instance; the undated N1 breaks contested_1965 (M2)"),
    "H+E+D+B1+G+K+F+I": ("H+E+D+B1+G+K+F+I", "yes (G, K, F)"),
    "H+E+D+B1+G+K+F+I+N1": ("H+E+D+B1+G+K+F+I+N1", "yes (G, K, F)"),
    "I Errington table": ("I (Errington)", "no: a new EvidenceModel instance"),
    "I both tables": ("I (both)", "no: a new EvidenceModel instance"),
    "reviews weigh 0": ("reviews 0", "no: a new EvidenceModel instance"),
    "N1 at import (undated)": ("N1 (import)", "no: the importer drops listed items once, so they are gone in every year (breaks contested_1965, the M2 exit theorem)"),
    "H1+I+N1 at import (undated)": ("H1+I+N1 (import)", "no; the undated N1 breaks contested_1965 (M2)"),
}

READS_AS = {"metaAnalysis": "9 observational studies", "rct": "5.7 observational studies",
            "curatedDb": "established alone", "textbook": "established alone", "review": "1.5 observational studies",
            "textMined": "21 make one meta-analysis", "hypothesis": "no weight", "definitional": "near-certain"}


def lean_output():
    if len(sys.argv) > 1:
        return Path(sys.argv[1]).read_text()
    r = subprocess.run(["lake", "env", "lean", LEAN], cwd=ROOT, capture_output=True, text=True, timeout=600)
    if r.returncode != 0 or ": error" in r.stdout:
        sys.exit("Lean run failed:\n" + r.stdout[-3000:] + r.stderr[-2000:])
    return r.stdout


def clean(s):
    return str(s).replace("\t", " ").replace("\n", " ")


def write(name, header, rows):
    with open(OUT / name, "w") as f:
        f.write("\t".join(header) + "\n")
        for r in rows:
            f.write("\t".join(clean(x) for x in r) + "\n")


def main():
    rows = [l.split("\t") for l in lean_output().splitlines() if "\t" in l]
    spec = {c["id"]: c for c in json.load(open(SPEC))}
    core = {r[1]: (r[2], r[3]) for r in rows if r[0] == "CASE"}
    order = [r[1] for r in rows if r[0] == "CASE"]
    assert set(core) == set(spec), set(core) ^ set(spec)

    write("cases.tsv",
          ["id", "title", "probes", "input", "correct", "observed", "mark", "test", "source", "synthetic", "judgement"],
          [[cid, spec[cid]["title"], spec[cid]["probes"], spec[cid]["input"], spec[cid]["correct"], core[cid][0],
            core[cid][1], f"BioLean.Stress.Weights.case_{cid}; pinned by `#guard pin core case_{cid}` and per scheme by `pinScheme`",
            "; ".join(spec[cid]["sources"]), "yes" if spec[cid]["synthetic"] else "no",
            "yes" if spec[cid]["judgement"] else "no"] for cid in order])

    schemes = [r for r in rows if r[0] == "SCHEME"]
    obs = {(r[1], r[2]): (r[3], r[4]) for r in rows if r[0] == "OBS"}
    long_rows = []
    for r in schemes:
        for cid in order:
            o, m = obs.get((r[1], cid), core[cid])
            long_rows.append([r[1], SCHEMES[r[1]][0], cid, m, o])
    write("schemes.tsv", ["scheme", "option", "id", "mark", "observed"], long_rows)

    ex = {r[1]: (r[2], r[3], r[4].split()[-1]) for r in rows if r[0] == "SCHEMEEX"}
    exits = {r[1]: (r[4], r[5]) for r in rows if r[0] == "EXIT"}
    summary = []
    for r in schemes:
        n = r[1]
        p, fa, si, ie = (x.strip("() ") for x in r[3].split(","))
        changes = [c.strip() for c in r[4].strip("[]").split(",") if c.strip()]
        fixed = [c for c in changes if c.endswith("->PASS")]
        lost = [c for c in changes if c.split(" ")[1].startswith("PASS->")]
        other = [c for c in changes if c not in fixed and c not in lost]
        summary.append([n, SCHEMES[n][0], SCHEMES[n][1], r[2], p, fa, si, ie, "; ".join(fixed), "; ".join(lost),
                        "; ".join(other), ex[n][0], ex[n][1], ex[n][2], exits[n][0], exits[n][1]])
    write("scheme_summary.tsv",
          ["scheme", "option", "core_change", "marks", "PASS", "FAIL", "SILENT", "INEXPRESSIBLE", "now_PASS",
           "lost_PASS", "other_changes", "example_check_flips", "example_flips", "ozempic_sign_flips",
           "exit_A", "exit_B"], summary)

    sx = {r[1]: (r[2], r[3]) for r in rows if r[0] == "SENSEX"}
    ss = {r[1]: (r[2], r[3]) for r in rows if r[0] == "SENSST"}
    write("sensitivity.tsv", ["run", "example_check_flips", "example_flips", "stress_mark_changes", "stress_changes"],
          [[k, sx[k][0], sx[k][1], ss[k][0], ss[k][1]] for k in sx])
    write("margins.tsv", ["kind", "first_break_below_1", "first_break_above_1", "ozempic_sign_flips_at"],
          [[r[1], r[2], r[3], r[4]] for r in rows if r[0] == "MARGIN"])

    pcs = []
    for r in rows:
        if r[0] == "PC":
            n = Fraction(r[2])
            rel = n / (n + 2)
            pcs.append([r[1], f"{rel.numerator}/{rel.denominator}" if rel.denominator != 1 else str(rel),
                        r[2], f"{float(n):.2f}", READS_AS.get(r[1], "")])
    write("pseudocounts.tsv", ["kind", "reliability_r", "pseudo_count_n", "n_decimal", "reads_as"], pcs)

    tally = [r for r in summary if r[0] == "core"][0]
    print(f"{len(order)} cases; core PASS {tally[4]} FAIL {tally[5]} SILENT {tally[6]} INEXPRESSIBLE {tally[7]}; "
          f"{len(schemes)} schemes; tables in {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
