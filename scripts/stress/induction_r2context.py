"""Program 10c (review): round-2 Lean statements whose annotation has a context that the Lean claim dropped.

I10's FAIL comes from one of these: m45432-355 is annotated with taxon Viridiplantae in data/textbook/claims_m2, but
BioLean/Lib/TextbookClaimsR2 states it for every cell wall, so the refinement axiom carries it to bacteria. This lists
every such statement: an m2 record with a rel/notRel/effect constructor and a non-empty context whose R2 Lean claim has
no `inCtx`, and whether round 3 (data/textbook/claims_m3) has a record for it (the closure search then reads round 3).
  python3 scripts/stress/induction_r2context.py     writes data/stress/10c/r2_context_dropped.tsv and prints counts
Reads only repository files."""
import json, glob, re, pathlib

REPO = pathlib.Path(__file__).resolve().parents[2]
OUT = REPO / 'data/stress/10c/r2_context_dropped.tsv'


def main():
    m2, m3 = {}, set()
    for p in sorted(glob.glob(str(REPO / 'data/textbook/claims_m2/*.json'))):
        for r in json.load(open(p)): m2[r['id']] = r
    for p in sorted(glob.glob(str(REPO / 'data/textbook/claims_m3/*.json'))):
        for r in json.load(open(p)): m3.add(r['id'])
    claim = {}
    for p in sorted(glob.glob(str(REPO / 'BioLean/Lib/TextbookClaimsR2/*.lean'))):
        for m in re.finditer(r'def \w+ : Statement where\n  id := "([^"]+)"\n  text := "(?:[^"\\]|\\.)*"\n  claim := (.*)\n', open(p).read()):
            claim[m.group(1)] = m.group(2)
    rows = ['id\tcontext\tr2_claim\tin_round_3']
    for i, r in sorted(m2.items()):
        a = r.get('m2') or {}
        ctx = {k: v for k, v in (a.get('context') or {}).items() if v}
        if a.get('ctor') not in ('rel', 'notRel', 'effect') or not ctx or i not in claim or 'inCtx' in claim[i]: continue
        rows.append('\t'.join([i, ';'.join(f'{k}={v}' for k, v in sorted(ctx.items())), claim[i], 'yes' if i in m3 else 'no']))
    OUT.write_text('\n'.join(rows) + '\n')
    n = len(rows) - 1; n3 = sum(r.endswith('\tyes') for r in rows[1:])
    print(f'{n} round-2 Lean statements dropped their annotated context; {n3} have a round-3 record, {n - n3} do not')


if __name__ == '__main__':
    main()
