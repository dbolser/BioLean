"""Correct the statements flagged in data/textbook/false_as_written.tsv.

Each row has an `m3_edit` (quant=most|some, subject=CURIE). The record's round-2 (or existing round-3) annotation is
copied into `claims_m3/<chapter>.json` with the edit applied, so round 3 supersedes the false-as-written round-2
statement: a `most` or `some` claim loads nothing into the closure, and a changed subject is emitted as such.
Idempotent. Usage: apply_false_as_written.py <claims_m2_dir> <claims_m3_dir>"""
import json, glob, re, sys, pathlib

def main():
    m2dir, m3dir = sys.argv[1:3]
    edits = {}
    for l in open('data/textbook/false_as_written.tsv'):
        if l.strip() and not l.startswith('#'):
            f = l.rstrip('\n').split('\t')
            edits[f[0]] = dict(kv.split('=', 1) for kv in f[5].split(';'))
    m3 = {}
    for p in glob.glob(f'{m3dir}/*.json'):
        m3[pathlib.Path(p).stem] = json.load(open(p))
    done = 0
    for p in sorted(glob.glob(f'{m2dir}/*.json')):
        slug = re.sub(r'-\d+$', '', pathlib.Path(p).stem)
        for r in json.load(open(p)):
            if r['id'] not in edits: continue
            recs = m3.setdefault(slug, [])
            cur = next((x for x in recs if x['id'] == r['id']), None)
            if cur is None:
                m = r['m2']
                base = {'ctor': m['ctor'], 'quant': None, 'subject': m.get('subject'), 'relation': m.get('relation'), 'object': m.get('object'),
                        'sign': m.get('sign'), 'target': m.get('target'), 'mediator': m.get('mediator'), 'mediator_target': m.get('mediator_target'),
                        'n': None, 'lo': None, 'hi': None, 'unit': None, 'quality': None,
                        'context': {s: (m.get('context') or {}).get(s) for s in ('taxon', 'anatomy', 'cellType', 'component', 'stage', 'condition')},
                        'blocker': m.get('blocker'), 'curie_changes': m.get('curie_changes') or [], 'confidence': m.get('confidence')}
                cur = {**{k: v for k, v in r.items() if k in ('id', 'module', 'source', 'claim', 'entities')}, 'm3': base}
                recs.append(cur)
            cur['m3'].update(edits[r['id']]); cur['m3']['edited_from'] = 'false_as_written.tsv'
            done += 1
    for slug, recs in m3.items():
        pathlib.Path(m3dir, f'{slug}.json').write_text(json.dumps(recs, indent=1, ensure_ascii=False) + '\n')
    print('corrected', done, 'of', len(edits))

if __name__ == '__main__': main()
