"""Promote round-2 records that carry a context to round 3, so the context is applied.

The round-2 emitter and the closure's round-2 loader read `m2.subject` and ignore `m2.context`, so "Animal cells
have a centrosome" became "cell has part centrosome" (a false universal; E0/E2 of docs/programs/01). Round 3 applies
context (`Entity.inCtx`). This copies each such record's `m2` into an `m3` block with no quantity, in
`claims_m3/<chapter>.json`. Records with a condition are left out: round 2 holds a string, round 3 wants a kind.
Idempotent. Usage: promote_context_to_m3.py <claims_m2_dir> <claims_m3_dir>"""
import json, glob, re, sys, pathlib

SLOTS = ('taxon', 'anatomy', 'cellType', 'component', 'stage', 'condition')

def main():
    m2dir, m3dir = sys.argv[1:3]
    have = {r['id'] for p in glob.glob(f'{m3dir}/*.json') for r in json.load(open(p)) if r.get('m3')}
    added = {}
    for p in sorted(glob.glob(f'{m2dir}/*.json')):
        slug = re.sub(r'-\d+$', '', pathlib.Path(p).stem)
        for r in json.load(open(p)):
            m = r.get('m2')
            if r.get('bin') == 'not_claim' or not m or m.get('ctor') in (None, 'none') or m.get('blocker') == 'context_required': continue
            ctx = {k: v for k, v in (m.get('context') or {}).items() if v}
            if not ctx or 'condition' in ctx or r['id'] in have: continue
            m3 = {'ctor': m['ctor'], 'quant': None, 'subject': m.get('subject'), 'relation': m.get('relation'), 'object': m.get('object'),
                  'sign': m.get('sign'), 'target': m.get('target'), 'mediator': m.get('mediator'), 'mediator_target': m.get('mediator_target'),
                  'n': None, 'lo': None, 'hi': None, 'unit': None, 'quality': None,
                  'context': {s: ctx.get(s) for s in SLOTS}, 'blocker': m.get('blocker'),
                  'curie_changes': m.get('curie_changes') or [], 'confidence': m.get('confidence'), 'promoted_from': 'm2'}
            added.setdefault(slug, []).append({**{k: v for k, v in r.items() if k in ('id', 'module', 'source', 'claim', 'entities')}, 'm3': m3})
    for slug, recs in added.items():
        f = pathlib.Path(m3dir) / f'{slug}.json'
        cur = json.load(open(f)) if f.exists() else []
        f.write_text(json.dumps(cur + recs, indent=1, ensure_ascii=False) + '\n')
        print(slug, len(recs))
    print('promoted', sum(map(len, added.values())))

if __name__ == '__main__': main()
