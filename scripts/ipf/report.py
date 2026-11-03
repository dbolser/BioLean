"""Summarise every curated run: what was expressible, what composed, what Lean computed.

    uv run python scripts/ipf/report.py                 # all runs with a report.jsonl
    uv run python scripts/ipf/report.py --json out.json # ... and the per-hypothesis table as JSON
    uv run python scripts/ipf/report.py --compare data/ipf/runs/<a> data/ipf/runs/<b>

Reads curated.json and report.jsonl (written by `render.py --lean`) in each run dir. Signs,
beliefs and verdicts are Lean's; this only counts them. A `.blind` dir is a calibration copy and
is left out.
"""
import argparse
import collections
import json
import re
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNS = ROOT / "data/ipf/runs"
MODELS = {"opus": "claude-opus-5", "fable": "claude-fable-5-1", "gpt": "gpt-5.6-sol", "gemini": "gemini-3.1-pro",
          "deepseek": "deepseek-v3.2", "kimi": "kimi-k2", "scripted-offline": "scripted-offline"}


def model_of(run: dict) -> str:
    m = str(run.get("model", ""))
    return next((v for k, v in MODELS.items() if k in m), m)


def steps_of(s: dict) -> list[str]:
    return s["step"] if isinstance(s["step"], list) else [s["step"]]


def frac(s: str) -> float:
    return float(Fraction(s))


def source_of(ref: str) -> str:
    if re.fullmatch(r"PMID:\d+", ref):
        return "paper"
    if ref.startswith("PMID:PPR"):
        return "preprint"
    if re.fullmatch(r"(UniProt:)?[OPQ][0-9][A-Z0-9]{3}[0-9]|(UniProt:)?[A-NR-Z][0-9][A-Z][A-Z0-9]{2}[0-9]", ref):
        return "UniProt"
    if ref.startswith("R-HSA") or ref.startswith("Reactome"):
        return "Reactome"
    if ref.startswith("rs") or ref.startswith("GWAS"):
        return "GWAS"
    return ref.split(":")[0]


def load(run_dir: Path) -> dict | None:
    if not (run_dir / "report.jsonl").exists():
        return None
    cur = json.loads((run_dir / "curated.json").read_text())
    run = json.loads((run_dir / "run.json").read_text())
    rows = [json.loads(line) for line in (run_dir / "report.jsonl").read_text().splitlines() if line.strip()]
    return {"dir": run_dir.name, "cur": cur, "run": run, "rows": rows, "model": model_of(run),
            "disease": run["question"].get("disease", "?")}


def entity_curie(cur: dict, name: str) -> str:
    e = cur["entities"].get(name, {})
    if "refines" in e:
        ctx = ",".join(f"{k}={entity_curie(cur, v) if k != 'taxon' else v}" for k, v in sorted(e["refines"].get("ctx", {}).items()))
        return f"{entity_curie(cur, e['refines']['base'])}[{ctx}]"
    return e.get("curie", name)


def ends(c: dict) -> tuple[str, str] | None:
    """(subject, target entity) of an effect or an association."""
    for form in ("effect", "assoc"):
        if form in c:
            t = c[form]["target"]
            return c[form]["subject"], next(v for k, v in t.items() if k != "aspect")
    return None


def links(r: dict) -> tuple[int, int, int]:
    """(possible, linked by the run's labels, linked after grounding) over consecutive steps."""
    by_step = collections.defaultdict(list)
    for s in r["cur"]["statements"]:
        if (e := ends(s["claim"])) and s["step"] != "bridge":
            for step in steps_of(s):
                by_step[step].append(e)
    possible = label = grounded = 0
    for h in r["run"]["hypotheses"]:
        chain = h["chain"]
        for i in range(len(chain) - 1):
            possible += 1
            a, b = chain[i], chain[i + 1]
            label += a["object"]["label"].strip().lower() == b["subject"]["label"].strip().lower()
            objs = {t for _, t in by_step[f"{h['hypothesis_id']}.{i + 1}"]}
            subs = {s for s, _ in by_step[f"{h['hypothesis_id']}.{i + 2}"]}
            grounded += bool(objs & subs)
    return possible, label, grounded


def hypothesis_rows(r: dict) -> list[dict]:
    """One row per hypothesis claim: its arms, best belief, and how the arms were made."""
    cur = r["cur"]
    stmt = {s["id"]: s for s in cur["statements"]}
    arms = [x for x in r["rows"] if x["row"] == "arm"]
    conf = {h["hypothesis_id"]: h.get("confidence") for h in r["run"]["hypotheses"]}
    out = []
    for hid, h in cur["hypotheses"].items():
        for ci, cl in enumerate(h.get("claims", []), 1):
            mine = [a for a in arms if a["hypothesis"] == hid and a["name"].startswith(f"c{ci}a")]
            best = max(mine, key=lambda a: frac(a["opinion"]["b"]), default=None)

            def borrowed(a: dict) -> bool:
                return any(stmt[i]["step"] != "bridge" and not any(x.startswith(f"{hid}.") for x in steps_of(stmt[i]))
                           for i in a["axioms"])
            out.append({
                "run": r["dir"], "model": r["model"], "disease": r["disease"], "hypothesis": hid,
                "confidence": conf.get(hid), "claim": ci, "sign": cl["sign"],
                "target": "disease" if "disease" in cl.get("target", {"disease": 1}) else "phenotype",
                "arms": len(mine), "best_belief": frac(best["opinion"]["b"]) if best else None,
                "best_verdict": best["verdict"] if best else None,
                "sign_differs": any(a["claim"].get("sign") != cl["sign"] for a in mine),
                "only_borrowed": bool(mine) and all(borrowed(a) for a in mine),
                "needs_bridge": bool(mine) and all(any(stmt[i]["step"] == "bridge" for i in a["axioms"]) for a in mine),
                "via_assoc": bool(mine) and any("assoc" in stmt[i]["claim"] for a in mine for i in a["axioms"]),
            })
    return out


def table(title: str, header: list[str], rows: list[list]) -> None:
    print(f"\n### {title}\n")
    print("| " + " | ".join(header) + " |")
    print("|" + "---|" * len(header))
    for row in rows:
        print("| " + " | ".join(str(x) for x in row) + " |")


def summary(rs: list[dict]) -> list[dict]:
    hyps = [h for r in rs for h in hypothesis_rows(r)]
    by_model = collections.defaultdict(list)
    for r in rs:
        by_model[r["model"]].append(r)

    rows = []
    for model, group in sorted(by_model.items(), key=lambda kv: -len(kv[1])):
        c = collections.Counter()
        for r in group:
            cur = r["cur"]
            stated = {x for s in cur["statements"] if s["step"] != "bridge" for x in steps_of(s)}
            c["steps"] += sum(len(h["chain"]) for h in r["run"]["hypotheses"])
            c["stated"] += len(stated)
            items = cur["statements"] + cur.get("unexpressed", [])
            c["kept"] += len({(e["ref"], x) for s in items for e in s.get("evidence", []) for x in steps_of(s)})
            c["cited"] += len({(e["ref"], x) for s in items for e in s.get("evidence", []) + s.get("excluded", []) for x in steps_of(s)})
            p, lab, gr = links(r)
            c["possible"] += p
            c["label"] += lab
            c["grounded"] += gr
        mh = [h for h in hyps if h["model"] == model]
        routed = [h for h in mh if h["arms"]]
        rows.append([model, len(group), c["steps"], f"{c['stated']} ({c['stated'] / max(c['steps'], 1):.0%})",
                     f"{c['kept']}/{c['cited']} ({c['kept'] / max(c['cited'], 1):.0%})",
                     f"{c['label']}/{c['possible']}", f"{c['grounded']}/{c['possible']}",
                     f"{len(routed)}/{len(mh)}", sum(h["sign_differs"] for h in mh),
                     f"{sum(h['best_belief'] for h in routed) / len(routed):.2f}" if routed else "n/a",
                     sum(h["best_verdict"] == "established" for h in mh)])
    table("By model", ["model", "runs", "steps", "stated", "citations that state their step", "links by label",
                       "links after grounding", "claims with a route", "sign differs", "mean best belief", "established"], rows)

    src = collections.defaultdict(collections.Counter)
    for r in rs:
        for s in r["cur"]["statements"] + r["cur"].get("unexpressed", []):
            for e in s.get("evidence", []):
                src[source_of(e["ref"])]["kept"] += 1
            for e in s.get("excluded", []):
                src[source_of(e["ref"])]["excluded"] += 1
                src[source_of(e["ref"])][e.get("category", "?")] += 1
    rows = []
    for k, c in sorted(src.items(), key=lambda kv: -(kv[1]["kept"] + kv[1]["excluded"])):
        n = c["kept"] + c["excluded"]
        top = ", ".join(f"{cat} {m}" for cat, m in c.most_common() if cat not in ("kept", "excluded"))[:90]
        rows.append([k, n, f"{c['kept']} ({c['kept'] / n:.0%})", top])
    table("Citations by source: does the record state the step it is cited for?",
          ["source", "citations", "kept", "why excluded"], rows)

    rows = []
    for conf in ("high", "medium", "low", None):
        hs = [h for h in hyps if h["confidence"] == conf]
        if not hs:
            continue
        routed = [h for h in hs if h["arms"]]
        rows.append([conf, len(hs), len(routed), f"{sum(h['best_belief'] for h in routed) / len(routed):.2f}" if routed else "n/a",
                     sum(h["best_verdict"] == "established" for h in hs)])
    table("The run's own confidence against Lean's belief (per claim)",
          ["run said", "claims", "with a route", "mean best belief", "established"], rows)

    routed = [h for h in hyps if h["arms"]]
    print(f"\nClaims: {len(hyps)}; with a route {len(routed)}; only through another hypothesis's steps "
          f"{sum(h['only_borrowed'] for h in hyps)}; only with a bridge {sum(h['needs_bridge'] for h in hyps)}; "
          f"using an association {sum(h['via_assoc'] for h in hyps)}; sign differs {sum(h['sign_differs'] for h in hyps)}; "
          f"phenotype targets {sum(h['target'] == 'phenotype' for h in hyps)}.")
    print("Arm verdicts:", dict(collections.Counter(a["verdict"] for r in rs for a in r["rows"] if a["row"] == "arm")))
    beliefs = [h["best_belief"] for h in routed]
    print("Best belief per routed claim:", {f"{lo:.1f}-{lo + 0.2:.1f}": sum(lo <= b < lo + 0.2 or (lo == 0.8 and b == 1) for b in beliefs)
                                             for lo in (0.0, 0.2, 0.4, 0.6, 0.8)})
    st = [x for r in rs for x in r["rows"] if x["row"] == "statement"]
    print(f"Statements: {len(st)}; forms {dict(collections.Counter(x['claim']['form'] for x in st))}; "
          f"with no evidence {sum(x['evidence'] == 0 for x in st)}; failing the taxon lint {sum(not x['taxonConsistent'] for x in st)}")
    ents = [e for r in rs for e in r["cur"]["entities"].values() if "refines" not in e]
    print(f"Entities: {len(ents)}; local BLN terms {sum(e.get('curie', '').startswith('BLN:') for e in ents)}; "
          f"refinements {sum('refines' in e for r in rs for e in r['cur']['entities'].values())}; "
          f"by prefix {dict(collections.Counter(e.get('curie', '').split(':')[0] for e in ents).most_common(12))}")

    print("\nUnexpressed (steps with no statement) by category:")
    for k, n in collections.Counter(u["category"] for r in rs for u in r["cur"].get("unexpressed", [])
                                    if u["step"] not in {x for s in r["cur"]["statements"] for x in steps_of(s)}).most_common():
        print(f"  {n:4}  {k}")

    claims = collections.defaultdict(set)
    for r in rs:
        for x in r["rows"]:
            if x["row"] == "statement" and x["claim"].get("form") in ("effect", "assoc"):
                cl = x["claim"]
                claims[(cl["form"], cl["subject"], cl["sign"], cl["target"]["kind"], cl["target"]["curie"])].add(r["dir"])
    shared = {k: v for k, v in claims.items() if len(v) > 1}
    print(f"\nDistinct effect and association claims: {len(claims)}; stated in more than one run: {len(shared)}")
    for k, v in sorted(shared.items(), key=lambda kv: -len(kv[1]))[:20]:
        print(f"  {len(v)} runs: {k}")

    print("\nFindings by project and category (top 40):")
    f = collections.Counter((x.get("project"), x.get("category")) for r in rs for x in r["cur"].get("findings", []))
    for (p, k), n in f.most_common(40):
        print(f"  {n:4}  {p:17} {k}")
    print("\nAudit changes by error:")
    for k, n in collections.Counter(x.get("error") for r in rs for x in r["cur"].get("audit", [])).most_common():
        print(f"  {n:4}  {k}")
    return hyps


def statement_key(cur: dict, s: dict) -> tuple:
    c = s["claim"]
    for form in ("effect", "assoc"):
        if form in c:
            x = c[form]
            (tk, ent), = [(k, v) for k, v in x["target"].items() if k != "aspect"]
            return (form, entity_curie(cur, x["subject"]), x.get("sign", x.get("direction")), tk,
                    entity_curie(cur, ent), x["target"].get("aspect", "risk"))
    r = c["rel"]
    return ("rel", r["relation"], entity_curie(cur, r["a"]), entity_curie(cur, r["b"]))


def compare(a_dir: Path, b_dir: Path) -> None:
    """Agreement between two curations of the same run, step by step."""
    a, b = (json.loads((d / "curated.json").read_text()) for d in (a_dir, b_dir))
    run = json.loads((a_dir / "run.json").read_text())
    agree = collections.Counter()
    for h in run["hypotheses"]:
        for i in range(len(h["chain"])):
            step = f"{h['hypothesis_id']}.{i + 1}"
            sa = [s for s in a["statements"] if step in steps_of(s)]
            sb = [s for s in b["statements"] if step in steps_of(s)]
            ka, kb = {statement_key(a, s) for s in sa}, {statement_key(b, s) for s in sb}
            ua = next((u["category"] for u in a.get("unexpressed", []) if u["step"] == step), None)
            ub = next((u["category"] for u in b.get("unexpressed", []) if u["step"] == step), None)
            ea = {e["ref"].removeprefix("UniProt:") for s in sa for e in s.get("evidence", [])}
            eb = {e["ref"].removeprefix("UniProt:") for s in sb for e in s.get("evidence", [])}
            agree["steps"] += 1
            agree["expressed_same"] += bool(sa) == bool(sb)
            agree["claims_same"] += ka == kb
            agree["evidence_same"] += ea == eb
            print(f"{step:8} {'=' if ka == kb else '≠'} claims  {'=' if ea == eb else '≠'} evidence"
                  f"  A: {sorted(ka) or ua}  {sorted(ea)}\n{'':8}                     B: {sorted(kb) or ub}  {sorted(eb)}")
    print(dict(agree))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--compare", nargs=2, type=Path)
    ap.add_argument("--json", type=Path)
    args = ap.parse_args()
    if args.compare:
        compare(*args.compare)
        return
    rs = [r for d in sorted(RUNS.iterdir()) if not d.name.endswith(".blind") and (r := load(d))]
    hyps = summary(rs)
    if args.json:
        args.json.write_text(json.dumps(hyps, indent=1))


if __name__ == "__main__":
    main()
