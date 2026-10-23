"""biolean fetch | extract | ground | emit  -- file-in / file-out JSON."""

import argparse
import json
import sys
from datetime import date
from pathlib import Path

from pydantic import BaseModel, TypeAdapter

from biolean import corpus, emit_lean, extract, ground


def read(path: Path, model: type) -> list:
    return TypeAdapter(list[model]).validate_json(path.read_text())


def write(path: Path, items: list[BaseModel]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps([i.model_dump() for i in items], indent=2, ensure_ascii=False) + "\n")


def cmd_fetch(a: argparse.Namespace) -> None:
    abstracts = corpus.search_abstracts(a.search, a.limit) if a.search else corpus.fetch_abstracts(a.pmids)
    write(a.out, abstracts)
    print(f"{len(abstracts)} abstracts -> {a.out}", file=sys.stderr)


def cmd_extract(a: argparse.Namespace) -> None:
    abstracts = read(a.abstracts, corpus.Abstract)
    if a.dry_run:
        print("\n".join(extract.dry_run(x) for x in abstracts))
        return
    results = []
    for x in abstracts:
        try:
            results.append(extract.extract(x))
        except Exception as e:  # a refusal, truncation or bad JSON on one abstract must not sink the batch
            print(f"skipped: {e}", file=sys.stderr)
        write(a.out, results)
    print(f"{len(results)}/{len(abstracts)} abstracts extracted -> {a.out}", file=sys.stderr)


def cmd_ground(a: argparse.Namespace) -> None:
    if a.rebuild or not ground.LOOKUP.exists():
        print(f"lookup: {ground.build_lookup():,} rows -> {ground.LOOKUP}", file=sys.stderr)
    results = read(a.extractions, extract.ExtractionResult)
    years = {x.pmid: x.year or 0 for x in read(a.abstracts, corpus.Abstract)}
    lookup = ground.load_lookup()
    grounded, log = ground.ground_results(results, years, lookup)
    write(a.out, grounded)
    mentions = [m for r in results for s in r.statements for m in (s.subject, s.object)]
    hits = sum(ground.ground(m, lookup) is not None for m in mentions)
    total = sum(len(r.statements) for r in results)
    print("\n".join(log))
    print(f"mentions grounded:   {hits}/{len(mentions)} ({hits / max(len(mentions), 1):.0%})")
    print(f"statements grounded: {len(grounded)}/{total} ({len(grounded) / max(total, 1):.0%}) -> {a.out}")


def cmd_emit(a: argparse.Namespace) -> None:
    source, log = emit_lean.emit(read(a.grounded, ground.GroundedStatement), date.today(), a.keep_hedged)
    a.out.write_text(source)
    print("\n".join(log + [f"-> {a.out}"]), file=sys.stderr)


def main(argv: list[str] | None = None) -> None:
    p = argparse.ArgumentParser(prog="biolean", description=__doc__)
    sub = p.add_subparsers(required=True)

    f = sub.add_parser("fetch", help="PubMed abstracts from the local corpus")
    f.add_argument("pmids", nargs="*", type=int)
    f.add_argument("--search", help="ILIKE pattern instead of PMIDs, e.g. '%%semaglutide%%appetite%%'")
    f.add_argument("--limit", type=int, default=20)
    f.add_argument("-o", "--out", type=Path, required=True)
    f.set_defaults(func=cmd_fetch)

    e = sub.add_parser("extract", help="abstracts.json -> extractions.json via Claude")
    e.add_argument("abstracts", type=Path)
    e.add_argument("-o", "--out", type=Path)
    e.add_argument("--dry-run", action="store_true", help="print prompts and schema; no API call")
    e.set_defaults(func=cmd_extract)

    g = sub.add_parser("ground", help="extractions.json -> grounded.json")
    g.add_argument("extractions", type=Path)
    g.add_argument("--abstracts", type=Path, required=True, help="fetch output, for publication years")
    g.add_argument("-o", "--out", type=Path, required=True)
    g.add_argument("--rebuild", action="store_true", help="rebuild data/lookup/labels.parquet")
    g.set_defaults(func=cmd_ground)

    m = sub.add_parser("emit", help="grounded.json -> .lean")
    m.add_argument("grounded", type=Path)
    m.add_argument("-o", "--out", type=Path, required=True)
    m.add_argument("--keep-hedged", action="store_true")
    m.set_defaults(func=cmd_emit)

    a = p.parse_args(argv)
    if a.func is cmd_extract and not (a.dry_run or a.out):
        p.error("extract needs -o/--out unless --dry-run")
    a.func(a)
