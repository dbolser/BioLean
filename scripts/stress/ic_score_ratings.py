"""Score a rated sheet against the IC cut and its alternatives (program 07, experiment E1). Written before any ratings.

Usage: python3 scripts/stress/ic_score_ratings.py <rated_sheet.tsv> [--key data/stress/07/rating_sheet_key.tsv]
                                                  [--old9 <rated rating_sheet_old9_blind.tsv>]
The rated sheet is rating_sheet_blind.tsv (or rating_sheet.tsv) with 'interesting' (0 to 3) and 'true' (yes, no,
unsure; y, n and ? are read too) filled. Rows are joined to the key by id, and to data/stress/07/features.tsv (from
ic_alternatives.py) by the formal fact. Rows with an unreadable 'interesting' are listed and left out. The optional old9
sheet only adds rows to the comparison with the old LLM labels. Pure Python, no dependencies.

Reports:
- how many rows are rated; the spread of 'interesting' and 'true';
- for each score (ends-min IC, path_min, and every numeric column of features.tsv: gain against the premises, Resnik
  similarity of the two ends, ontology path length, normalised IC, depth, premises, chapters) the AUC for telling
  'interesting >= 1' and '>= 2' from the rest (Mann-Whitney; 0.5 is chance), over rows that have the score;
- a threshold table: at each T, level-0 rows removed, rows rated >= 2 and true lost, false rows kept;
- the T that removes most level-0 rows while losing at most one true row rated >= 2;
- mean 'interesting' for the structural flags (restatement through a refinement, weakening, the ontology already
  entails it, the ontology already links the two ends), by rule, by chapters;
- closure-wide share of IC-kept facts rated 0, weighted by stratum (the sheet over-samples near 2.5);
- agreement with the old LLM labels on the rows that have one (T against rated 0; S or E against rated >= 1),
  as raw agreement and Cohen's kappa.
"""
import collections, sys

IC_MIN = 2.5


def read_tsv(p):
    lines = open(p, encoding='utf-8').read().splitlines()
    head = lines[0].split('\t')
    return [dict(zip(head, l.split('\t'))) for l in lines[1:] if l.strip()]


def auc(pos, neg):
    if not pos or not neg: return None
    wins = sum((p > n) + 0.5 * (p == n) for p in pos for n in neg)
    return wins / (len(pos) * len(neg))


def kappa(pairs):
    n = len(pairs)
    if not n: return None, None
    po = sum(a == b for a, b in pairs) / n
    ca, cb = collections.Counter(a for a, _ in pairs), collections.Counter(b for _, b in pairs)
    pe = sum(ca[x] * cb[x] for x in set(ca) | set(cb)) / (n * n)
    return po, (po - pe) / (1 - pe) if pe < 1 else None


TRUE = {'yes': 'yes', 'y': 'yes', 'no': 'no', 'n': 'no', 'unsure': 'unsure', '?': 'unsure', '': ''}
NUMERIC = ('gain', 'mica_ic', 'onto_dist', 'norm_ic', 'depth', 'n_premises', 'n_chapters')


def rated(sheet_p, key, feats, bad):
    out = []
    for r in read_tsv(sheet_p):
        i, t = r.get('interesting', '').strip(), r.get('true', '').strip().lower()
        if i.endswith('.0'): i = i[:-2]   # review fix: a spreadsheet may save 2 as 2.0 (ic_analysis.py does the same)
        if i == '' or r['id'] not in key: continue
        if i not in ('0', '1', '2', '3') or t not in TRUE: bad.append(f"{r['id']}: interesting {i!r}, true {t!r}"); continue
        k = key[r['id']]; fx = feats.get(k['formal_fact'], {})
        num = lambda v: float(v) if v not in (None, '') else None
        out.append(dict(id=r['id'], lvl=int(i), true=TRUE[t], ic=num(k['ic']), pm=num(k['path_min']), rule=k['rule'],
                        stratum=k.get('stratum', ''), restates=k.get('restates_refinement') == 'True',
                        weak=k.get('weakening') == 'True', chapters=int(k.get('n_chapters') or 0), old=k['old_llm_label'],
                        entailed=fx.get('entailed') == 'True', linked=bool(fx.get('ontology_link')),
                        **{n: num(fx.get(n)) for n in NUMERIC}))
    return out


def main(argv):
    sheet_p = argv[1]
    key_p = argv[argv.index('--key') + 1] if '--key' in argv else 'data/stress/07/rating_sheet_key.tsv'
    strata_p = key_p.replace('rating_sheet_key.tsv', 'sample_strata.tsv')
    feats_p = key_p.replace('rating_sheet_key.tsv', 'features.tsv')
    key = {r['id']: r for r in read_tsv(key_p)}
    try: feats = {r['fact']: r for r in read_tsv(feats_p)}
    except FileNotFoundError: feats = {}; print(f'no {feats_p}: run ic_alternatives.py for the feature AUCs')
    bad = []
    rows = rated(sheet_p, key, feats, bad)
    extra = []
    if '--old9' in argv:
        key9_p = key_p.replace('rating_sheet_key.tsv', 'rating_sheet_old9_key.tsv')
        extra = rated(argv[argv.index('--old9') + 1], {r['id']: r for r in read_tsv(key9_p)}, {}, bad)
    if bad: print(f'left out, unreadable ({len(bad)}):', '; '.join(bad))
    print(f"rated rows: {len(rows)} of {len(key)}" + (f'; old9 rows: {len(extra)}' if extra else ''))
    if not rows: return
    print('interesting:', dict(sorted(collections.Counter(r['lvl'] for r in rows).items())),
          ' true:', dict(collections.Counter(r['true'] for r in rows)))
    label = {'ic': 'ends-min IC', 'pm': 'path_min', 'gain': 'gain against premises', 'mica_ic': 'Resnik similarity of ends',
             'onto_dist': 'ontology path length', 'norm_ic': 'normalised IC'}
    for name in ('ic', 'pm') + NUMERIC:
        sc = [r for r in rows if r[name] is not None]
        for cut in (1, 2):
            a = auc([r[name] for r in sc if r['lvl'] >= cut], [r[name] for r in sc if r['lvl'] < cut])
            print(f"AUC of {label.get(name, name):<26} for interesting >= {cut}: {'n/a' if a is None else f'{a:.3f}'}  (n={len(sc)})")
    print('\nthreshold table (ends-min IC; unjudged rows left out)')
    print('   T  removed  level-0 removed  worth lost (>=2, true)  false kept')
    sc = [r for r in rows if r['ic'] is not None]
    best = None
    for T in [x / 4 for x in range(0, 33)]:
        rem = [r for r in sc if r['ic'] < T]; kept = [r for r in sc if r['ic'] >= T]
        z = sum(r['lvl'] == 0 for r in rem); lost = sum(r['lvl'] >= 2 and r['true'] == 'yes' for r in rem)
        fk = sum(r['true'] == 'no' for r in kept)
        if T in (1.0, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0, 6.0): print(f'{T:4.2f}  {len(rem):7d}  {z:15d}  {lost:22d}  {fk:10d}')
        if lost <= 1 and (best is None or z > best[1]): best = (T, z, lost)
    print(f'suggested T (most level-0 removed, at most one true >=2 lost): {best[0]} (removes {best[1]} level-0 rows)')
    print('\nmean interesting by group')
    groups = {'restates a premise through a refinement': [r for r in rows if r['restates']],
              'weakens a premise': [r for r in rows if r['weak']],
              'neither flag': [r for r in rows if not r['restates'] and not r['weak']],
              'the ontology already entails it': [r for r in rows if r['entailed']],
              'the ontology already links the two ends': [r for r in rows if r['linked']],
              'premises from 2+ chapters': [r for r in rows if r['chapters'] > 1],
              'premises from 1 chapter': [r for r in rows if r['chapters'] <= 1]}
    for rule in sorted({r['rule'] for r in rows}): groups[f'rule {rule}'] = [r for r in rows if r['rule'] == rule]
    for g, rs in groups.items():
        if rs: print(f'  {g:<45} n={len(rs):3d}  mean {sum(r["lvl"] for r in rs) / len(rs):.2f}  rated 0: {sum(r["lvl"] == 0 for r in rs)}')
    strata = {r['stratum']: int(r['pool']) for r in read_tsv(strata_p)} if strata_p else {}
    num = den = 0.0
    for s, pool in strata.items():
        rs = [r for r in rows if r['stratum'] == s and r['ic'] is not None and r['ic'] >= IC_MIN]
        allin = [r for r in rows if r['stratum'] == s]
        if not rs or not allin: continue
        w = pool / len(allin); num += w * sum(r['lvl'] == 0 for r in rs); den += w * len(rs)
    if den: print(f'\nclosure-wide share of IC-kept facts rated 0 (weighted by stratum): {num / den:.2f}')
    pairs = [('trivial' if r['old'] == 'T' else 'not', 'trivial' if r['lvl'] == 0 else 'not') for r in rows + extra if r['old']]
    po, k = kappa(pairs)
    if po is not None: print(f'old LLM labels against these ratings: n={len(pairs)} agreement {po:.2f} kappa {"n/a" if k is None else f"{k:.2f}"}')
    e = [(r['old'] == 'E', r['true'] == 'no') for r in rows + extra if r['old']]
    if e: print(f'old E against true=no: both {sum(a and b for a, b in e)}, E only {sum(a and not b for a, b in e)}, no only {sum(b and not a for a, b in e)}')


if __name__ == '__main__':
    main(sys.argv)
