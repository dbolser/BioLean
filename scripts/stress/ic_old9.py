"""An optional extra sheet: the 9 of the 42 old LLM-rated facts that today's closure no longer derives (program 07).

The main sheet (ic_sheet.py) holds the other 33. These 9 cannot be in a sample of today's closure, but rating them as
well lets Dan's ratings be compared with all 42 old labels. Their derivations come from the closure the labels were made
on: data/search/closure.json at commit c0430c5 (2026-10-28, 1,551 derived facts), read with `git show` (read-only).
For each, the key says which premises round 3 re-annotated (a taxon or other context added, a some/most quantifier, or
a narrower subject), which is why the fact is gone.

Reads: git show c0430c5:data/search/closure.json, data/stress/07/old42_llm_labels.tsv, data/textbook/claims_m3/.
Writes data/stress/07/rating_sheet_old9_blind.tsv (no IC, for raters) and rating_sheet_old9_key.tsv.
Run from the repo root: python3 scripts/stress/ic_old9.py
"""
import glob, json, random, subprocess, sys
sys.path.insert(0, 'scripts/stress')
from ic_common import (CURIE_IN_FACT, derivation, ends, key_of, leaves, load_ic, parse_tree, path_min, plain, premise_sentences,
                       rel_label_list, ro_labels, score, sentences, term, write_tsv)

COMMIT, SEED = 'c0430c5', 9
OUT = 'data/stress/07'

old_closure = json.loads(subprocess.run(['git', 'show', f'{COMMIT}:data/search/closure.json'], capture_output=True,
                                        check=True).stdout)['facts']
by_fact = {f['fact']: f for f in old_closure}
ic, tab = load_ic(); rl = ro_labels(); RELS = rel_label_list(rl); sents = sentences()
NAMES = {c: v.get('name') for c, v in tab.items() if v.get('name')}
m3 = {r['id']: r['m3'] for p in sorted(glob.glob('data/textbook/claims_m3/*.json')) for r in json.load(open(p))}


def reannotated(leaf):
    """What round 3 changed about this premise (quantifier, context, a different subject or object), or ''."""
    sid = leaf['sid']; r = m3.get(sid)
    if not r: return ''
    what = []
    ids = CURIE_IN_FACT.findall(leaf['fact'])
    for end, old_id in (('subject', ids[0]), ('object', ids[-1])):
        if r.get(end) and r[end] != old_id: what.append(f'{end} {old_id} now {r[end]}')
    if r.get('quant') in ('some', 'most'): what.append(f"quantifier {r['quant']}")
    ctx = {k: v for k, v in (r.get('context') or {}).items() if v}
    if ctx: what.append('context ' + ', '.join(f'{k} {v}' for k, v in sorted(ctx.items())))
    return f"{sid}: {'; '.join(what)}" if what else ''


rows = [l.split('\t') for l in open(f'{OUT}/old42_llm_labels.tsv', encoding='utf-8').read().splitlines()[1:]]
gone = [r for r in rows if r[5] == 'no']
assert len(gone) == 9, len(gone)
picked = []
for r in gone:
    f = by_fact[r[4]]; f['k'] = key_of(f); f['t'] = parse_tree(f['tree']); picked.append((r, f))
random.Random(SEED).shuffle(picked)

sheet = [('id', 'fact', 'terms', 'derivation', 'premise_sentences', 'rule', 'depth', 'interesting', 'true', 'note')]
key = [('id', 'source', 'closure_key', 'formal_fact', 'ic', 'path_min', 'rule', 'depth', 'n_premises', 'old42_index',
        'old_llm_label', 'premises_reannotated_in_round_3')]
for i, (r, f) in enumerate(picked, 1):
    rid = f'O{i:02d}'; a, b = ends(f['k']); s = score(f['k'], ic); pm = path_min(f['t'], ic)
    sheet.append((rid, plain(f['fact'], f['k'], rl, NAMES), f'subject = {term(a, tab)}; object = {term(b, tab)}',
                  derivation(f['t'], RELS), premise_sentences(f['t'], sents), f['rule'], f['depth'], '', '', ''))
    why = ' | '.join(x for x in (reannotated(l) for l in leaves(f['t'])) if x)
    key.append((rid, f'git {COMMIT}:data/search/closure.json', json.dumps(f['key'], ensure_ascii=False), f['fact'],
                '' if s is None else round(s, 3), '' if pm is None else round(pm, 3), f['rule'], f['depth'],
                len(leaves(f['t'])), r[0], r[3], why))
write_tsv(f'{OUT}/rating_sheet_old9_blind.tsv', sheet)
write_tsv(f'{OUT}/rating_sheet_old9_key.tsv', key)
for k in key[1:]: print(k[0], k[10], k[4], k[3][:70], '<-', k[11][:120])
