"""Program 04: a fixed random sample (seed "04-<detector>") of up to 10 flagged statements per detector from the scan of every live
statement (data/stress/04/baseline_flags.tsv), with the textbook sentence, for hand judgement of precision.
Run from the repo root:  python3 -I scripts/stress/mutants_sample.py   -> data/stress/04/baseline_sample.tsv"""
import json, glob, random, collections, pathlib
REPO = pathlib.Path('/home/danbolser/Build/BioLean'); OUT = REPO / 'data/stress/04'
text = {}
for p in glob.glob(str(REPO / 'data/textbook/claims_m[23]/*.json')):
    for r in json.load(open(p)): text[r['id']] = (r.get('claim') or '', (r.get('source') or '')[:200])
by = collections.defaultdict(dict)
for l in open(OUT / 'baseline_flags.tsv'):
    if l.startswith('#') or not l.strip(): continue
    sid, det, flag, key = l.rstrip('\n').split('\t')
    by[det][sid] = min(by[det].get(sid, (flag, key)), (flag, key))   # first flag in sorted order: stable across runs
out = ['# detector\tstatement\tflag\tclaim key\tclaim\tsentence\tdistinct flagged (this detector)']
for det in sorted(by):
    ids = sorted(by[det]); pick = sorted(random.Random(f"04-{det}").sample(ids, min(10, len(ids))))
    for sid in pick:
        f, k = by[det][sid]; c, s = text.get(sid, ('', ''))
        out.append('\t'.join([det, sid, f, k, c, s, str(len(ids))]))
(OUT / 'baseline_sample.tsv').write_text('\n'.join(out) + '\n')
print({d: len(v) for d, v in by.items()})
