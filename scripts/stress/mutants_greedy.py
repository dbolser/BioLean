"""Program 04: which detectors to add, in order. Greedy cover of the false mutants left after today's detectors, with
each detector's cost on the live data (statements flagged out of 1,401; precision on the hand-judged sample).
Run from the repo root:  python3 -I scripts/stress/mutants_greedy.py   -> data/stress/04/greedy.tsv"""
import collections, pathlib
OUT = pathlib.Path('/home/danbolser/Build/BioLean/data/stress/04')
rows = [l.rstrip('\n').split('\t') for l in open(OUT / 'mutants.tsv')]
hdr, rows = rows[0], [dict(zip(rows[0], r)) for r in rows[1:]]
mut = [r for r in rows if r['op'] != 'E0_control' and r['judged'] == 'false']
eqv = [r for r in rows if r['op'] != 'E0_control' and r['judged'] in ('equivalent', 'unclear')]
caught = {r['mid'] for r in mut if r['today']}
by = collections.defaultdict(set)
for r in mut + eqv:
    for d in filter(None, r['later'].split(',')): by[d].add(r['mid'])
live = collections.Counter(); prec = collections.defaultdict(collections.Counter)
for l in open(OUT / 'baseline_flags.tsv'):
    if l.startswith('#') or not l.strip(): continue
    sid, det, _, _ = l.split('\t'); live[(det, sid)] = 1
nlive = collections.Counter(d for d, _ in live)
nlive['kinds'] = sum(1 for (d, s) in live if d == 'disjoint')   # is_a across kinds is reported under disjoint in the scan
for l in open(OUT / 'baseline_judged.tsv'):
    if l.startswith('#') or not l.strip(): continue
    f = l.split('\t'); prec['kinds' if f[0] == 'disjoint' else f[0]][f[2]] += 1
ids = {r['mid'] for r in mut}
out = ['# step\tdetector added\tnew false mutants caught\tcumulative (of %d)\tequivalent mutants it also sees\tlive statements flagged (of 1401)\tlive precision (hand sample)' % len(mut)]
out.append(f'0\ttoday (Lean, closure clash, off-loop sign clash, taxon lint)\t{len(caught)}\t{len(caught)}\t0\t-\t-')
left = dict(by); step = 0
while left:
    d, s = max(left.items(), key=lambda kv: (len((kv[1] & ids) - caught), kv[0]))
    gain = (s & ids) - caught
    if not gain: break
    step += 1; caught |= gain
    p = prec.get(d); ptxt = f'{p["TP"]}/{p["TP"] + p["FP"]}' if p else 'no live flags'
    out.append(f'{step}\t{d}\t{len(gain)}\t{len(caught)}\t{len(s - ids)}\t{nlive.get(d, 0)}\t{ptxt}')
    del left[d]
# second order: most precise on the live data first (what to adopt first), same columns
caught = {r['mid'] for r in mut if r['today']}
rate = lambda d: (prec[d]['TP'] / (prec[d]['TP'] + prec[d]['FP'])) if d in prec else -1
out.append('# precision-first order')
for i, d in enumerate(sorted(by, key=lambda d: (-rate(d), -len(by[d] & ids))), 1):
    gain = (by[d] & ids) - caught; caught |= gain
    p = prec.get(d); ptxt = f'{p["TP"]}/{p["TP"] + p["FP"]}' if p else 'no live flags'
    out.append(f'p{i}\t{d}\t{len(gain)}\t{len(caught)}\t{len(by[d] - ids)}\t{nlive.get(d, 0)}\t{ptxt}')
(OUT / 'greedy.tsv').write_text('\n'.join(out) + '\n'); print('\n'.join(out))

# --- per error type: today, the recommended set, everything (data/stress/04/by_type.tsv)
REC = {'sig', 'obsolete', 'go_tax_c', 'onto_refutes'}
bt = collections.defaultdict(collections.Counter)
for r in mut:
    later = set(filter(None, r['later'].split(',')))
    t = bt[r['op']]; t['n'] += 1; t['today'] += bool(r['today']); t['rec'] += bool(r['today'] or later & REC); t['all'] += bool(r['today'] or later)
    t['spreads'] += int(r['damage']) > 0
lines = ['# error type\tfalse mutants\ttoday\trecommended (today + sig, obsolete, go_tax_c, onto_refutes)\tall detectors\tspread into derived facts']
order = sorted(bt, key=lambda o: int(o.split('_')[0][1:]))
for o in order + ['all']:
    t = bt[o] if o != 'all' else sum((bt[x] for x in order), collections.Counter())
    lines.append(f"{o}\t{t['n']}\t{t['today']}\t{t['rec']}\t{t['all']}\t{t['spreads']}")
(OUT / 'by_type.tsv').write_text('\n'.join(lines) + '\n'); print('\n'.join(lines))
