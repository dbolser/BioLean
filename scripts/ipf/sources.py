"""Copy hypothesis-agent runs, and the text of everything they cite, into data/ipf/runs/<run>/.

The store is sealed: we read it, never write it. A citation resolves through the run's own
evidence ledger (bundle item -> artifact -> JSON pointer), so the text is the row the agent saw.
An abstract is its title and abstract; any other record is the ledger's one-sentence statement
plus the row's fields. A PMID or UniProt accession the run never fetched falls back to the local
corpus and is marked `in_ledger: false`; anything else not in the ledger has no text.

    uv run python scripts/ipf/sources.py --all          # every run with chains
    uv run python scripts/ipf/sources.py <run_id> ...
"""
import argparse
import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from biolean.corpus import fetch_abstracts, query  # noqa: E402

STORE = Path("/home/danbolser/Work/IUK-IPF/hypothesis-agent/store")
OUT = ROOT / "data/ipf/runs"


def resolve(payload, pointer: str):
    """RFC 6901, as hypothesis-agent's `resolve_pointer`."""
    for raw in pointer.lstrip("/").split("/") if pointer not in ("", "/") else []:
        token = raw.replace("~1", "/").replace("~0", "~")
        payload = payload[int(token)] if isinstance(payload, list) else payload[token]
    return payload


def flatten(value, prefix: str = "") -> list[str]:
    """`key: value` lines for every scalar in a row, so a quote can name a field."""
    if isinstance(value, dict):
        return [line for k, v in value.items() for line in flatten(v, f"{prefix}{k}.")]
    if isinstance(value, list):
        return [line for v in value for line in flatten(v, prefix)]
    if value in (None, ""):
        return []
    return [f"{prefix.rstrip('.')}: {value}"]


TAG = re.compile(r"</?[A-Za-z][^<>]*>")  # a tag, not the '<' of 'P<0.001'


def plain(text: str) -> str:
    return html.unescape(TAG.sub("", text))


def cited(hypotheses: list[dict]) -> dict[str, str]:
    """accession -> how the run cites it first: on a chain step, as support, or as contradicting."""
    out: dict[str, str] = {}
    for h in hypotheses:
        for s in h["chain"]:
            for e in s.get("evidence") or []:
                out.setdefault(e, "chain")
    for role in ("supporting", "contradicting"):
        for h in hypotheses:
            for e in h.get(f"{role}_evidence") or []:
                if not isinstance(e, str):
                    continue
                # an accession, or free text that names some (older runs)
                for acc in [e] if not re.search(r"\s", e.strip()) else re.findall(r"PMID:\d+", e):
                    out.setdefault(acc.strip(), role)
    return out


def ledger(run_dir: Path) -> dict[str, dict]:
    items: dict[str, dict] = {}
    for path in sorted((run_dir / "bundles").glob("*.json")):
        for item in json.loads(path.read_text())["items"]:
            items.setdefault(item["accession"], item)
    return items


def copy_run(run_id: str) -> str:
    run_dir = STORE / "runs" / run_id
    result = json.loads((run_dir / "result.json").read_text())
    manifest = json.loads((run_dir / "manifest.json").read_text())
    items, payloads, sources = ledger(run_dir), {}, {}
    for acc, role in cited(result["hypotheses"]).items():
        item = items.get(acc)
        if item is None:
            sources[acc] = {"cited_as": role, "in_ledger": False, "source": None, "text": None}
            continue
        entry = {"cited_as": role, "in_ledger": True, "source": item["source"], "statement": item["statement"],
                 "url": item.get("url", ""), "text": None}
        try:
            aid = item["artifact_id"]
            if aid not in payloads:
                hexid = aid.split(":", 1)[1]
                payloads[aid] = json.loads((STORE / "artifacts" / hexid[:2] / hexid[2:4] / f"{hexid}.json").read_text())
            row = resolve(payloads[aid], item["locator"])
        except (OSError, KeyError, IndexError, ValueError) as exc:
            entry["unresolved"] = str(exc)
            row = None
        if item["source"] == "europepmc" and isinstance(row, dict) and row.get("abstractText"):
            entry["text"] = plain(f"{row.get('title', '')}\n\n{row['abstractText']}")
            entry["year"] = int(row["pubYear"]) if row.get("pubYear") else None
            entry["pubtypes"] = row.get("pubTypeList", {}).get("pubType", [])
        elif row is not None:
            entry["text"] = "\n".join([item["statement"], *flatten(row)])
        sources[acc] = entry

    # Fallbacks from the local corpus, for citations the run never fetched or got no text for.
    pmids = [a for a, e in sources.items() if re.fullmatch(r"PMID:\d+", a) and not e["text"]]
    for ab in fetch_abstracts([int(a[5:]) for a in pmids]):
        sources[f"PMID:{ab.pmid}"].update(text=f"{ab.title}\n\n{ab.abstract}", year=ab.year,
                                          text_from="local PubMed corpus")
    accs = [a.removeprefix("UniProt:") for a, e in sources.items()
            if not e["text"] and re.fullmatch(r"(UniProt:)?[OPQ][0-9][A-Z0-9]{3}[0-9]|(UniProt:)?[A-NR-Z][0-9][A-Z][A-Z0-9]{2}[0-9]", a)]
    if accs:
        for acc, text in query("select record_id, text from records where record_class = 'UniProt' and record_id = any(?)", [accs]):
            key = acc if acc in sources else f"UniProt:{acc}"
            sources[key].update(text=text, text_from="local UniProt records")

    out = OUT / run_id
    out.mkdir(parents=True, exist_ok=True)
    (out / "run.json").write_text(json.dumps(
        {"run_id": run_id, "model": manifest["question"]["model"], "question": manifest["question"],
         **result}, indent=1, ensure_ascii=False))
    (out / "sources.json").write_text(json.dumps(sources, indent=1, ensure_ascii=False))
    n_text = sum(bool(e["text"]) for e in sources.values())
    n_ledger = sum(e["in_ledger"] for e in sources.values())
    n_contra = sum(e["cited_as"] == "contradicting" for e in sources.values())
    return f"{run_id}: {len(sources)} cited ({n_contra} only as contradicting), {n_ledger} in the ledger, {n_text} with text"


def runs_with_chains() -> list[str]:
    out = []
    for d in sorted((STORE / "runs").iterdir()):
        try:
            result = json.loads((d / "result.json").read_text())
            model = json.loads((d / "manifest.json").read_text())["question"]["model"]
        except (OSError, ValueError, KeyError):
            continue
        if "FunctionModel" in model:  # test fixtures
            continue
        if any(h.get("chain") for h in result.get("hypotheses") or []):
            out.append(d.name)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("runs", nargs="*")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()
    for run_id in runs_with_chains() if args.all else args.runs:
        print(copy_run(run_id))


if __name__ == "__main__":
    main()
