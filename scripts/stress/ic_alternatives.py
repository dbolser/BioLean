"""Measure alternatives to one IC cut on the current closure (program 07). Read-only. Run from the repo root:

    python3 -I scripts/stress/ic_alternatives.py [obo_dir ...]    (default /tmp/biolean-07/obo then /tmp/obo)

The OBO files (go.obo, uberon.obo, cl-basic.obo, chebi_lite.obo, the releases ic.json was built from) are needed for
section 6 only; the script checks that it reproduces every IC in ic.json before using them.
Prints, and writes data/stress/07/alternatives_summary.tsv and data/stress/07/features.tsv (one row per derived fact):
1. The old 42 LLM labels re-scored on today's closure (33 still derived): the threshold table, ends-min and path_min.
2. Structural triviality, found from the derivation alone, no IC: restatement through a refinement, weakening by
   isaGeneralise, 'overlaps' implied by a 'part of' or 'has part' between the same ends.
3. Ranking artefacts: share of ChEBI-ended facts in the top 100; the highest-ranked fact with no ChEBI end.
4. Surprise proxies: premises from more than one textbook chapter; derivation depth; kept against dropped.
5. Coverage: facts with an end outside the IC table, by prefix.
6. Features for each alternative, per fact: the conclusion's IC against its premises' (gain); how the ontology itself
   relates the two ends (is_a or part_of either way, and whether that already entails the fact); the most informative
   common ancestor (Resnik similarity) and the path length through it; IC normalised by its ontology's size (for
   ranking across ontologies). Scored against the 33 old LLM labels as a preview only (one LLM rater, n = 29 T or S).
"""
import collections, json, math, sys
sys.path.insert(0, 'scripts/stress')
from ic_common import (CURIE_IN_FACT, IC_MIN, ISA, base, bound, chapters, ends, ic_of, leaves, load_closure, load_ic,
                       path_min, restates_refinement, ro_labels, score, weakening, write_tsv)
import ic_ontology

facts = load_closure(); ic, tab = load_ic(); rl = ro_labels()
for f in facts: f['s'] = score(f['k'], ic); f['pm'] = path_min(f['t'], ic)
keyset = {f['k'] for f in facts}
out = []
def say(section, item, value): out.append((section, item, str(value))); print(f'{section:<12} {item:<70} {value}')

# --- 1. old labels on today's closure
rows = [l.split('\t') for l in open('data/stress/07/old42_llm_labels.tsv', encoding='utf-8').read().splitlines()[1:]]
cur = [(float(r[7]), float(r[8]), r[3]) for r in rows if r[5] == 'yes']
say('old42', 'still derived today', f'{len(cur)} of {len(rows)}')
say('old42', 'labels of those still derived (T/S/E)', '/'.join(str(sum(1 for c in cur if c[2] == x)) for x in 'TSE'))
gone = [r[3] for r in rows if r[5] == 'no']
say('old42', 'labels of those no longer derived (T/S/E)', '/'.join(str(gone.count(x)) for x in 'TSE'))
for name, ix in (('ends-min', 0), ('path_min', 1)):
    for T in (2.0, 2.5, 3.0, 3.5, 4.0):
        lo = collections.Counter(c[2] for c in cur if c[ix] < T); hi = collections.Counter(c[2] for c in cur if c[ix] >= T)
        say('old42', f'{name} T={T}: removed n T/S/E | kept n T/S/E',
            f"{sum(lo.values())} {lo['T']}/{lo['S']}/{lo['E']} | {sum(hi.values())} {hi['T']}/{hi['S']}/{hi['E']}")

# --- 2. structural triviality
def weakening_(f): return weakening(f, keyset, rl)


kept = [f for f in facts if f['s'] is not None and f['s'] >= IC_MIN]
dropped = [f for f in facts if (f['s'] is not None and f['s'] < IC_MIN) or (f['s'] is None and bound(f['k'], ic) is not None and bound(f['k'], ic) < IC_MIN)]
unj = [f for f in facts if f not in kept and f not in dropped]
say('cut', 'derived facts; kept at 2.5; dropped; unjudged', f'{len(facts)}; {len(kept)}; {len(dropped)}; {len(unj)}')
r_k = sum(map(restates_refinement, kept)); w_k = sum(map(weakening_, kept))
both = sum(1 for f in kept if restates_refinement(f) or weakening_(f))
say('structure', 'kept facts that restate a premise through a refinement', f'{r_k} of {len(kept)} ({100*r_k/len(kept):.0f}%)')
say('structure', 'kept facts that weaken a premise (isaGeneralise, or overlaps beside part_of)', f'{w_k} of {len(kept)} ({100*w_k/len(kept):.0f}%)')
say('structure', 'kept facts with either flag', f'{both} of {len(kept)} ({100*both/len(kept):.0f}%)')
r_all = sum(map(restates_refinement, facts)); w_all = sum(map(weakening_, facts))
say('structure', 'all derived facts: restatement / weakening', f'{r_all} / {w_all} of {len(facts)}')
pm_drop = sum(1 for f in kept if f['pm'] is not None and f['pm'] < IC_MIN)
say('structure', 'kept facts the bottleneck (path_min < 2.5) would drop', f'{pm_drop} of {len(kept)}')

# --- 3. ranking
ranked = json.load(open('data/search/closure_ic.json'))['facts']
top = ranked[:100]
by_fact = {f['fact']: f for f in facts}
def has_chebi_end(fs):
    k = by_fact[fs]['k']; return any(base(c).startswith('CHEBI:') for c in ends(k))
say('rank', 'top 100 by IC with a ChEBI end', sum(1 for f in top if has_chebi_end(f['fact'])))
say('rank', 'top 100 that restate a premise through a refinement', sum(1 for f in top if restates_refinement(by_fact[f['fact']])))
first = next(i for i, f in enumerate(ranked, 1) if not has_chebi_end(f['fact']))
say('rank', 'rank of the first fact with no ChEBI end', f"{first}: {ranked[first-1]['fact'][:90]}")
ties = collections.Counter(round(f['score'], 3) for f in ranked)
say('rank', 'distinct scores among 1,921 ranked facts; largest tie', f"{len(ties)}; {ties.most_common(1)[0][1]} facts at {ties.most_common(1)[0][0]}")

# --- 4. surprise proxies
for name, group in (('kept', kept), ('dropped', dropped), ('unjudged', unj)):
    cross = sum(1 for f in group if len(chapters(f)) > 1)
    d = collections.Counter(f['depth'] for f in group)
    say('surprise', f'{name}: premises from more than one chapter', f'{cross} of {len(group)} ({100*cross/max(1,len(group)):.0f}%)')
    say('surprise', f'{name}: depth 1/2/3/4', '/'.join(str(d[i]) for i in (1, 2, 3, 4)))

# --- 5. coverage
pre = collections.Counter()
for f in unj + [f for f in dropped if f['s'] is None]:
    for c in ends(f['k']):
        if ic.get(c, ic.get(base(c))) is None: pre[base(c).split(':')[0]] += 1
say('coverage', 'ends with no IC among unscored facts, by prefix', dict(pre.most_common()))

# --- 6. features
g, paths = ic_ontology.load(sys.argv[1:] or ['/tmp/biolean-07/obo', '/tmp/obo'])
n_cmp, n_bad, ex = ic_ontology.check_against_ic_json(g, tab)
assert n_bad == 0, f'OBO graph differs from ic.json on {n_bad} of {n_cmp} terms, e.g. {ex}'
say('features', 'OBO graph reproduces ic.json', f'{n_cmp} of {n_cmp} terms; ' + ', '.join(f'{p} {v}' for p, v in sorted(g.version.items())))
size = {c: v['n'] for c, v in tab.items() if 'n' in v}


def norm_ic(c):
    x = ic_of(c, ic); n = size.get(c, size.get(base(c)))
    return None if x is None or not n else x / math.log(n)


def leaf_score(l):
    ids = CURIE_IN_FACT.findall(l['fact']); xs = [ic_of(c, ic) for c in (ids[0], ids[-1])]
    return None if None in xs else min(xs)


def features(f):
    k = f['k']; a, b = (base(c) for c in ends(k))
    prem = [l for l in leaves(f['t']) if not l['sid'].startswith('refine:')]
    ps = [x for x in map(leaf_score, prem) if x is not None]
    rel = None if k[0] == 'effect' else ('is_a' if k[1] == ISA else rl.get(k[1]))
    link = g.link(a, b) if k[0] == 'rel' else None
    mica = g.mica(a, b)
    nx = [norm_ic(c) for c in ends(k)]
    return dict(fact=f['fact'], ic=f['s'], path_min=f['pm'], depth=f['depth'], n_premises=len(prem), n_chapters=len(chapters(f)),
                restates=restates_refinement(f), weakening=weakening_(f),
                gain=None if f['s'] is None or not ps else f['s'] - max(ps),
                same_ontology=g.same_space(a, b), ontology_link=link or '', entailed=ic_ontology.entailed(rel, link),
                mica_ic=None if mica is None else mica[0], mica=None if mica is None else mica[1],
                onto_dist=None if mica is None else mica[2], norm_ic=None if None in nx else min(nx))


feats = [features(f) for f in facts]
cols = list(feats[0])
r3 = lambda x: round(x, 3) if isinstance(x, float) else ('' if x is None else x)
write_tsv('data/stress/07/features.tsv', [cols] + [[r3(x[c]) for c in cols] for x in feats])
F = {x['fact']: x for x in feats}
kf = [F[f['fact']] for f in kept]
say('features', 'kept: the ontology already relates the two ends (is_a or part_of, either way)',
    f"{sum(1 for x in kf if x['ontology_link'])} of {len(kf)}; by kind {dict(collections.Counter(x['ontology_link'] for x in kf if x['ontology_link']))}")
say('features', 'kept: the ontology already entails the fact (is_a, part of, overlaps)', f"{sum(x['entailed'] for x in kf)} of {len(kf)}")
say('features', 'all derived: the ontology already entails the fact', f"{sum(x['entailed'] for x in feats)} of {len(feats)}")
say('features', 'kept: both ends in the same ontology (GO by namespace)', f"{sum(x['same_ontology'] for x in kf)} of {len(kf)}")
gk = [x['gain'] for x in kf if x['gain'] is not None]
say('features', 'kept: gain = IC(conclusion) - max IC(premise): below 0 / 0 / above 0',
    f"{sum(1 for x in gk if x < -1e-9)} / {sum(1 for x in gk if abs(x) <= 1e-9)} / {sum(1 for x in gk if x > 1e-9)} of {len(gk)}")
ga = [x['gain'] for x in feats if x['gain'] is not None]
say('features', 'all scored: gain below 0 / 0 / above 0', f"{sum(1 for x in ga if x < -1e-9)} / {sum(1 for x in ga if abs(x) <= 1e-9)} / {sum(1 for x in ga if x > 1e-9)} of {len(ga)}")
rn = sorted((x for x in feats if x['norm_ic'] is not None), key=lambda x: (-x['norm_ic'], x['fact']))
say('rank', 'normalised IC (IC / ln N of its ontology): top 100 with a ChEBI end', sum(1 for x in rn[:100] if has_chebi_end(x['fact'])))
fn = next(i for i, x in enumerate(rn, 1) if not has_chebi_end(x['fact']))
say('rank', 'normalised IC: rank of the first fact with no ChEBI end', f"{fn}: {rn[fn-1]['fact'][:90]}")
say('rank', 'normalised IC: number of facts at or above the value that 2.5 has in GO BP', 
    f"{sum(1 for x in rn if x['norm_ic'] >= 2.5 / math.log(23974))} (raw IC >= 2.5: {len(kept)})")


def auc(pos, neg):
    if not pos or not neg: return None
    return sum((p > q) + 0.5 * (p == q) for p in pos for q in neg) / (len(pos) * len(neg))


lab = {r[6]: r[3] for r in rows if r[5] == 'yes'}
for name in ('ic', 'path_min', 'gain', 'mica_ic', 'onto_dist', 'norm_ic', 'depth', 'n_premises', 'n_chapters'):
    xs = [(F[fa][name], l) for fa, l in lab.items() if F[fa][name] is not None and l in 'TS']
    a = auc([x for x, l in xs if l == 'S'], [x for x, l in xs if l == 'T'])
    say('old42', f'AUC of {name} for S against T (0.5 is chance; LLM labels)', f"{'n/a' if a is None else f'{a:.2f}'} (n={len(xs)})")
for name in ('restates', 'weakening', 'entailed', 'same_ontology'):
    c = collections.Counter(l for fa, l in lab.items() if F[fa][name])
    say('old42', f'labels T/S/E of facts with {name}', f"{c['T']}/{c['S']}/{c['E']}")

with open('data/stress/07/alternatives_summary.tsv', 'w', encoding='utf-8') as fh:
    fh.write('section\titem\tvalue\n')
    for r in out: fh.write('\t'.join(r) + '\n')
