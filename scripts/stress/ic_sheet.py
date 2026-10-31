"""Build the human rating sheet for the IC triviality threshold (program 07).

Reads (never regenerates): data/search/closure.json, closure_ic.json, ic.json, data/textbook/claims*/,
data/stress/07/old42_llm_labels.tsv (from ic_old42.py).
Writes data/stress/07/: rating_sheet.tsv (with IC), rating_sheet_blind.tsv (no IC), rating_sheet_key.tsv (id to
closure key, scores, stratum, old LLM label), sample_strata.tsv (targets and draws per stratum).

Design: 100 rows. 96 scored facts in 10 IC bins, denser near the 2.5 cut, plus 4 facts with an end that has no IC.
The 33 old LLM-rated facts still in the closure are included first; each bin is topped up at random, stratified by rule
(every rule present in a bin gets a seat while seats last, the rest proportional) and, inside each rule, by derivation
depth (proportional to the bin's pool, counting the old facts already seated), avoiding repeats of the same template
(same rule and subject and relation, or same rule and relation and object) while the pool allows. The facts used as
stress cases and as rubric examples, and their twins (the same fact with a context added or dropped), are kept off the
sheet, so it stays blind and the examples do not prime a row.
The excluded facts are frozen in data/stress/07/sheet_draw_exclusions.tsv (the 30 real stress cases and the 12 examples of
the first rubric draft, as they stood when the sheet was drawn on 2026-10-30). Reading that file, not ic_cases.py, keeps
the draw fixed when the cases or the rubric change later. ic_cases.py checks that the current cases and rubric examples
are off the sheet (and that no rubric example shares a subject, object or pair with a row).
Row order and ids are shuffled with a fixed seed, so IC is not visible from the order.
Run from the repo root: python3 scripts/stress/ic_sheet.py
"""
import collections, json, random, sys
sys.path.insert(0, 'scripts/stress')
from ic_common import (IC_MIN, base, bound, chapters, derivation, ends, leaves, load_closure, load_ic, load_scored, path_min,
                       plain, premise_sentences, rel_label_list, restates_refinement, ro_labels, score, sentences, split_fact,
                       term, weakening, write_tsv)

SEED_SAMPLE, SEED_ORDER = 20261030, 7
BINS = [(0, 1, 8), (1, 2, 9), (2, 2.25, 10), (2.25, 2.5, 12), (2.5, 2.75, 12), (2.75, 3, 11), (3, 4, 10), (4, 6, 10),
        (6, 9, 8), (9, 13, 6)]
N_UNJUDGED = 4
OUT = 'data/stress/07'

facts = load_closure(); ic, tab = load_ic(); scored = load_scored(); rl = ro_labels(); sents = sentences()
RELS = rel_label_list(rl); NAMES = {c: v.get('name') for c, v in tab.items() if v.get('name')}
by_fact = {f['fact']: f for f in facts}; KEYS = {f['k'] for f in facts}
for f in facts:
    f['score'] = score(f['k'], ic); f['pm'] = path_min(f['t'], ic)


def bin_of(s):
    if s is None: return 'no IC'
    for lo, hi, _ in BINS:
        if lo <= s < hi: return f'[{lo},{hi})'
    raise ValueError(s)


def template(f):
    k = f['k']; s, r, o = split_fact(f['fact'], k, rl)
    a, b = ends(k)
    return {(f['rule'], 'S', base(a), r), (f['rule'], 'O', r, base(b))}


# --- old LLM-rated facts still present
old = {}
for ln in open(f'{OUT}/old42_llm_labels.tsv', encoding='utf-8').read().splitlines()[1:]:
    c = ln.split('\t')
    if c[5] == 'yes': old[c[6]] = (c[0], c[3])
chosen, used_templates = [], set()
for fact in old: chosen.append(by_fact[fact]); used_templates |= template(by_fact[fact])

rng = random.Random(SEED_SAMPLE)
strata_rows = [('stratum', 'pool', 'target', 'old_llm_rated', 'new_drawn', 'by_rule_drawn', 'depth_pool', 'depth_sheet')]


def depth_quota(pool, old_in_bin, rule, n_new):
    """Split a rule's new seats across derivation depths, proportional to the bin (pool plus old), minus the old seated."""
    p = collections.Counter(f['depth'] for f in pool if f['rule'] == rule)
    o = collections.Counter(f['depth'] for f in old_in_bin if f['rule'] == rule)
    cnt = p + o; seats = n_new + sum(o.values()); tot = sum(cnt.values())
    share = {d: seats * c / tot for d, c in cnt.items()}; want = {d: int(x) for d, x in share.items()}
    for d in sorted(share, key=lambda d: (-(share[d] - want[d]), d))[:seats - sum(want.values())]: want[d] += 1
    q = {d: min(max(0, want[d] - o[d]), p[d]) for d in cnt}
    while sum(q.values()) > n_new:
        d = max(q, key=lambda d: (q[d] - want[d] + o[d], q[d], -d)); q[d] -= 1
    while sum(q.values()) < n_new:
        d = max((d for d in p if p[d] > q[d]), key=lambda d: (want[d] - o[d] - q[d], p[d] - q[d], -d)); q[d] += 1
    return {d: n for d, n in sorted(q.items()) if n}


def draw(pool, old_in_bin, rule_quota):
    picked = []
    for rule, q in rule_quota.items():
        for d, m in depth_quota(pool, old_in_bin, rule, q).items():
            cand = [f for f in pool if f['rule'] == rule and f['depth'] == d]; rng.shuffle(cand)
            fresh = [f for f in cand if not (template(f) & used_templates)]
            for f in (fresh + [f for f in cand if f not in fresh])[:m]:
                picked.append(f); used_templates.update(template(f))
    return picked


def mix(fs, field): return ' '.join(f'{x}:{n}' for x, n in sorted(collections.Counter(f[field] for f in fs).items()))


def quota(pool, old_in_bin, target):
    """Seats per rule for the whole bin: one each while seats last (commonest rule first), the rest proportional;
    then subtract the old facts already seated."""
    cnt = collections.Counter(f['rule'] for f in pool) + collections.Counter(f['rule'] for f in old_in_bin)
    seats = collections.Counter()
    for r, _ in cnt.most_common():
        if sum(seats.values()) < target: seats[r] += 1
    left = target - sum(seats.values()); tot = sum(cnt.values())
    if left > 0:
        share = {r: left * n / tot for r, n in cnt.items()}
        for r in share: seats[r] += int(share[r])
        for r in sorted(share, key=lambda r: -(share[r] - int(share[r])))[:target - sum(seats.values())]: seats[r] += 1
    for f in old_in_bin: seats[f['rule']] -= 1
    need = target - len(old_in_bin); avail = collections.Counter(f['rule'] for f in pool)
    q = {r: min(max(0, n), avail[r]) for r, n in seats.items()}
    while sum(q.values()) > need:   # the old facts took more seats than their rules' share: trim the largest
        r = max(q, key=lambda r: (q[r], cnt[r])); q[r] -= 1
    while sum(q.values()) < need:   # top up from the rule with most facts left in the pool
        r = max(avail, key=lambda r: (avail[r] - q.get(r, 0), r)); q[r] = q.get(r, 0) + 1
    return {r: n for r, n in q.items() if n}


chosen_set = {f['fact'] for f in chosen}
def signature(k):
    """The fact with each end read as its base term: twins differ only by a context."""
    return (k[0],) + ((k[1], k[2]) if k[0] == 'effect' else (k[1],)) + tuple(base(c) for c in ends(k))


OFF = {ln.split('\t')[0] for ln in open(f'{OUT}/sheet_draw_exclusions.tsv', encoding='utf-8').read().splitlines()[1:]}   # some cases are facts the closure does not derive
OFF_SIG = {signature(by_fact[x]['k']) for x in OFF if x in by_fact}
OFF_SHEET = {f['fact'] for f in facts if signature(f['k']) in OFF_SIG}   # the cases, the examples and their twins
assert not OFF_SHEET & chosen_set, 'a stress case or rubric example (or a twin) is an old rated fact'
for lo, hi, target in BINS:
    name = f'[{lo},{hi})'
    in_bin = [f for f in facts if f['score'] is not None and lo <= f['score'] < hi]
    old_in = [f for f in in_bin if f['fact'] in chosen_set]
    pool = [f for f in in_bin if f['fact'] not in chosen_set | OFF_SHEET]
    q = quota(pool, old_in, target)
    got = draw(pool, old_in, q)
    chosen += got; chosen_set |= {f['fact'] for f in got}
    strata_rows.append((name, len(in_bin), target, len(old_in), len(got), mix(got, 'rule'), mix(in_bin, 'depth'), mix(old_in + got, 'depth')))
unj = [f for f in facts if f['score'] is None]
pool = [f for f in unj if f['fact'] not in chosen_set | OFF_SHEET]
q = quota(pool, [], N_UNJUDGED)
got = draw(pool, [], q); chosen += got
strata_rows.append(('no IC (an end outside GO, UBERON, CL, ChEBI)', len(unj), N_UNJUDGED, 0, len(got), mix(got, 'rule'), mix(unj, 'depth'), mix(got, 'depth')))
assert len(chosen) == 100 and len({f['fact'] for f in chosen}) == 100, len(chosen)

# --- render
rng_o = random.Random(SEED_ORDER); order = chosen[:]; rng_o.shuffle(order)
sheet = [('id', 'fact', 'terms', 'derivation', 'premise_sentences', 'ic', 'rule', 'depth', 'interesting', 'true', 'note')]
key = [('id', 'closure_key', 'formal_fact', 'ic', 'path_min', 'stratum', 'rule', 'depth', 'n_premises', 'kept_at_2.5',
        'hub_survivor', 'flags', 'restates_refinement', 'weakening', 'n_chapters', 'old42_index', 'old_llm_label')]
for i, f in enumerate(order, 1):
    rid = f'R{i:03d}'; a, b = ends(f['k']); s = f['score']
    sheet.append((rid, plain(f['fact'], f['k'], rl, NAMES), f'subject = {term(a, tab)}; object = {term(b, tab)}', derivation(f['t'], RELS),
                  premise_sentences(f['t'], sents), '' if s is None else f'{s:.2f}', f['rule'], f['depth'], '', '', ''))
    sc = scored.get(f['fact'], {})
    kept = 'unjudged' if s is None and (bound(f['k'], ic) is None or bound(f['k'], ic) >= IC_MIN) else ('no' if (bound(f['k'], ic) if s is None else s) < IC_MIN else 'yes')
    o = old.get(f['fact'], ('', ''))
    key.append((rid, json.dumps(f['key'], ensure_ascii=False), f['fact'], '' if s is None else round(s, 3),
                '' if f['pm'] is None else round(f['pm'], 3), bin_of(s), f['rule'], f['depth'], len(leaves(f['t'])), kept,
                sc.get('hub_survivor', ''), ','.join(f.get('flags', [])), restates_refinement(f), weakening(f, KEYS, rl),
                len(chapters(f)), o[0], o[1]))
for name, rows in (('rating_sheet.tsv', sheet), ('rating_sheet_blind.tsv', [r[:5] + r[6:] for r in sheet]),
                   ('rating_sheet_key.tsv', key), ('sample_strata.tsv', strata_rows)):
    write_tsv(f'{OUT}/{name}', rows)
print('\n'.join('\t'.join(map(str, r)) for r in strata_rows))
print('rules in sheet', dict(collections.Counter(f['rule'] for f in chosen)))
print('depths in sheet', dict(sorted(collections.Counter(f['depth'] for f in chosen).items())))
print('kept at 2.5:', collections.Counter(r[9] for r in key[1:]))
