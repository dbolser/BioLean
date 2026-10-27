"""Aggregate the OpenStax textbook claim files into milestone numbers.

Usage: uv run python scripts/textbook/aggregate.py [--json]
Reads data/textbook/claims/*.json; prints markdown tables (or JSON).
"""
import collections as C
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FILES = [
    "cell-structure-and-function", "how-cells-obtain-energy", "photosynthesis",
    "reproduction-at-the-cellular-level", "the-cellular-basis-of-inheritance",
    "molecular-biology", "the-body-s-systems-a", "the-body-s-systems-b",
]
BINS = ["now", "with_context", "missing_construct", "not_claim"]

# Collapse annotator spellings of the same construct into one family.
FAMILIES = [
    (r"^is_a|^equality|^disjointness", "is_a / identity"),
    (r"^has_input ?/ ?has_output", "has_input / has_output"),
    (r"^has_input", "has_input"),
    (r"^has_output", "has_output"),
    (r"^has_part|^made_of|^contains|^part_of|^covered_by", "has_part / part_of / made_of"),
    (r"^quantit|^comparison|^comparative|^similarity|^quantifier|^variation|^probability|^correlation|^association|^universal|^existential",
     "quantity / comparison / quantifier"),
    (r"^located_in|^occurs_in|^spatial|^adjacent|^geometry", "located_in / occurs_in / spatial"),
    (r"^connects|^continuous_with|^signalling/transport|^transport", "transport / connects"),
    (r"^capable_of|^has_function|^function/role|^capability|^disposition|^enables|^enabled_by|^participates_in|^has_participant",
     "capable_of / has_function / enables"),
    (r"^occurs_during|^sequence|^temporal", "sequence / occurs_during"),
    (r"^necessity", "necessity (requires)"),
    (r"^negation|^quality as agent", "negation / absence"),
    (r"^has_quality|^property", "has_quality"),
    (r"^unsigned|^regulates|^sign unspecified", "unsigned effect / regulation"),
    (r"^procedure|^observability", "procedure / method"),
    (r"^conditional|^counterfactual|^modality|^hypothesis|^intent|^explanation", "conditional / modality"),
    (r"^disjunction", "disjunction"),
    (r"^binds|^binding|^joint action|^specificity", "binding"),
    (r"^derives_from|^develops_from|^evolutionary|^homology|^historical", "derives_from / evolution"),
    (r"^Target.disease|^disease target", "disease target"),
    (r"^variant|^entity kind|^ungroundable", "missing entity kind"),
    (r"^ecological|^energy transfer|^feedback|^mechanism|^encodes", "other"),
]


def family(name):
    for pat, fam in FAMILIES:
        if re.search(pat, name):
            return fam
    return "other"


def load():
    out = {}
    for f in FILES:
        out[f] = json.loads((ROOT / "data/textbook/claims" / f"{f}.json").read_text())
    return out


def stats(recs):
    claims = [r for r in recs if r["bin"] != "not_claim"]
    ents = [e for r in recs for e in r["entities"]]
    s = {
        "records": len(recs),
        "sentences": len({r["source"] for r in recs}),
        "claims": len(claims),
        "by_bin": C.Counter(r["bin"] for r in recs),
        "by_kind": C.Counter(r["kind"] for r in claims),
        "mentions": len(ents),
        "grounded": sum(e["curie"] is not None for e in ents),
        "verified": sum(bool(e["verified"]) for e in ents),
        "by_ont": C.Counter(),
        "by_ont_grounded": C.Counter(),
        "constructs": C.Counter(),
        "families": C.Counter(),
        "family_example": {},
        "with_lean": sum(r["lean"] is not None for r in claims),
        "with_lean_term": sum(bool(r["lean"]) and not r["lean"].lstrip().startswith("--") for r in claims),
        "exact_dups": len(recs) - len({(r["source"], r["claim"]) for r in recs}),
    }
    for e in ents:
        o = e["ontology"] or "none"
        s["by_ont"][o] += 1
        s["by_ont_grounded"][o] += e["curie"] is not None
    for r in recs:
        if r["bin"] == "missing_construct":
            name = r["missing_construct"] or "(unnamed)"
            fam = family(name)
            s["constructs"][name] += 1
            s["families"][fam] += 1
            s["family_example"].setdefault(fam, r["claim"])
    return s


def pct(a, b):
    return f"{100 * a / b:.1f}%" if b else "-"


def main():
    data = load()
    per = {f: stats(r) for f, r in data.items()}
    tot = stats([r for rs in data.values() for r in rs])
    if "--json" in sys.argv:
        print(json.dumps({"total": tot, "per_file": per}, default=dict, indent=1))
        return
    t = tot
    print("## Totals\n")
    print("| measure | value |\n|---|---:|")
    print(f"| records (sentence fragments annotated) | {t['records']} |")
    print(f"| distinct source sentences | {t['sentences']} |")
    print(f"| claims (bin != not_claim) | {t['claims']} |")
    print(f"| exact (source, claim) duplicates | {t['exact_dups']} |")
    print(f"| claims with a lean field | {t['with_lean']} |")
    print(f"| claims whose lean field is a term, not a comment | {t['with_lean_term']} |")
    for b in BINS:
        base = t["records"]
        print(f"| bin {b} | {t['by_bin'][b]} ({pct(t['by_bin'][b], base)} of records, "
              f"{pct(t['by_bin'][b], t['claims']) if b != 'not_claim' else '-'} of claims) |")
    for k, n in t["by_kind"].most_common():
        print(f"| kind {k} | {n} ({pct(n, t['claims'])}) |")
    print(f"| entity mentions | {t['mentions']} |")
    print(f"| grounded (CURIE) | {t['grounded']} ({pct(t['grounded'], t['mentions'])}) |")
    print(f"| verified | {t['verified']} ({pct(t['verified'], t['mentions'])}) |")
    print("\n## Grounding by ontology\n\n| ontology | mentions | grounded | rate |\n|---|---:|---:|---:|")
    for o, n in t["by_ont"].most_common():
        g = t["by_ont_grounded"][o]
        print(f"| {o} | {n} | {g} | {pct(g, n)} |")
    print("\n## Per file\n")
    print("| file | sentences | records | claims | now | with_context | missing | not_claim | grounded |")
    print("|---|---:|---:|---:|---:|---:|---:|---:|---:|")
    for f, s in per.items():
        b = s["by_bin"]
        print(f"| {f} | {s['sentences']} | {s['records']} | {s['claims']} | {b['now']} | {b['with_context']} | "
              f"{b['missing_construct']} | {b['not_claim']} | {pct(s['grounded'], s['mentions'])} |")
    print("\n## Missing construct families\n\n| family | claims | % of missing | example |\n|---|---:|---:|---|")
    m = t["by_bin"]["missing_construct"]
    for fam, n in t["families"].most_common():
        print(f"| {fam} | {n} | {pct(n, m)} | {t['family_example'][fam]} |")
    print(f"\n{len(t['constructs'])} distinct raw construct names.")


if __name__ == "__main__":
    main()
