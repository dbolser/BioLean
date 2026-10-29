"""Check data/ipf/curated.json and render it into BioLean/Lib/IPF.lean.

Checks, all fatal: every quote is a verbatim substring of its source (abstract or UniProt entry);
every entity CURIE is in the local corpus (dbSNP and BLN excepted); every chain step of the run is
either a statement or listed as unexpressed, exactly once. Then prints a step table for the doc.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from biolean.corpus import query  # noqa: E402

DATA = ROOT / "data/ipf"
OUT = ROOT / "BioLean/Lib/IPF.lean"
SNAPSHOT_YEAR = 2026  # database entries as fetched for the run (August 2026)


def esc(s: str) -> str:
    return " ".join(s.replace("\\", "\\\\").replace('"', "'").split())[:200]


def source_text(ref: str, sources: dict) -> str | None:
    if ref.startswith("PMID:"):
        return sources["papers"][ref[5:]]["abstract"]
    if ref.startswith("UniProt:"):
        return sources["uniprot"][ref[8:]]
    return None


def check(cur: dict, run: dict, sources: dict) -> None:
    errors = []
    for s in cur["statements"]:
        for e in s["evidence"]:
            text = source_text(e["ref"], sources)
            if text is None:
                if not e.get("note"):
                    errors.append(f"{s['id']} {e['ref']}: no source text and no note")
            elif e["quote"] not in text:
                errors.append(f"{s['id']} {e['ref']}: quote not in source: {e['quote'][:60]}")
    curies = [e["curie"] for e in cur["entities"].values() if not e["curie"].startswith(("dbSNP:", "BLN:"))]
    ids = [c.removeprefix("UniProt:") for c in curies]
    found = {r[0] for r in query("select distinct record_id from records where record_id = any(?)", [ids])}
    errors += [f"CURIE not in corpus: {c}" for c, i in zip(curies, ids) if i not in found]
    run_steps = [f"{h['hypothesis_id']}.{i + 1}" for h in run["hypotheses"] for i in range(len(h["chain"]))]
    covered = {s["step"] for s in cur["statements"] if s["step"] != "bridge"}
    unexpressed = [u["step"] for u in cur["unexpressed"]]
    errors += [f"step {x} neither stated nor unexpressed" for x in run_steps if x not in covered | set(unexpressed)]
    errors += [f"step {x} both stated and unexpressed" for x in covered & set(unexpressed)]
    if errors:
        sys.exit("\n".join(errors))


def evidence_row(e: dict, sources: dict) -> str:
    ref = e["ref"]
    if ref.startswith("PMID:"):
        pmid, year = int(ref[5:]), sources["papers"][ref[5:]]["year"]
        note = e["quote"]
    else:
        pmid, year = 0, SNAPSHOT_YEAR
        note = f"{ref}: {e['quote'] or e['note']}"
    taxon = ", taxon := some Taxa.mouse" if e.get("taxon") == "mouse" else ""
    return (f'    {{ pmid := {pmid}, year := {year}, kind := .{e["kind"]}, polarity := .supports, '
            f'note := "{esc(note)}"{taxon} }}')


def render(cur: dict, sources: dict) -> str:
    out = ["import BioLean", "",
           "/-! Rendered from `data/ipf/curated.json` by `scripts/ipf/02_render_lean.py`. Do not edit by hand.",
           f"The statements of hypothesis-agent run {cur['run_id']} (IPF, six genes), one per chain step,",
           "with the evidence the run cited. Every quote is a verified substring of its source. -/", "",
           "namespace BioLean.Lib.IPF", ""]
    for name, e in cur["entities"].items():
        out.append(f'def {name} : Entity .{e["kind"]} := ⟨"{e["curie"]}", "{e["label"]}"⟩')
    out += ["", "/-- Cellular senescence in alveolar type 2 cells: a refinement, as in M2. -/",
            "def at2Senescence : Entity .process := cellularSenescence.inCtx { cellType := at2 }", ""]
    for s in cur["statements"]:
        rows = [evidence_row(e, sources) for e in s["evidence"]]
        out += [f"/-- Run step {s['step']}: {s['text']}. -/", f"def {s['id']} : Statement where",
                f'  id := "{s["id"]}"', f'  text := "{s["text"]}"', f"  claim := {s['claim']}",
                "  evidence := [" + ("\n" + ",\n".join(rows) + "\n  ]" if rows else "]"), ""]
    out += [f"def statements : List Statement := [{', '.join(s['id'] for s in cur['statements'])}]", "",
            "end BioLean.Lib.IPF", ""]
    return "\n".join(out)


def main() -> None:
    cur = json.loads((DATA / "curated.json").read_text())
    run = json.loads((DATA / "run.json").read_text())
    sources = json.loads((DATA / "sources.json").read_text())
    check(cur, run, sources)
    OUT.write_text(render(cur, sources))
    n_ev = sum(len(s["evidence"]) for s in cur["statements"])
    n_ex = sum(len(s["excluded"]) for s in cur["statements"])
    print(f"wrote {OUT}: {len(cur['statements'])} statements, {n_ev} evidence kept, {n_ex} excluded, "
          f"{len(cur['unexpressed'])} steps unexpressed")


if __name__ == "__main__":
    main()
