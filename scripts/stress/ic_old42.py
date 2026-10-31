"""Recover the 42 LLM-rated facts behind IC_MIN = 2.5 and match them to the current closure.

Sources (both written on 2026-10-28 by the agent that wrote docs/ic-triviality.md, not by a person):
- /tmp/work/sample_key.json: [index, IC band 0-5, ends-min IC then, fact string then], 42 rows, 7 per band.
- the label string that agent used, copied verbatim from its session log (T trivial, S substantive, E wrong or dubious).
Matching: by constructor, relation (or sign and target) and the two CURIEs, read from the old fact string.
Writes data/stress/07/old42_llm_labels.tsv. Run from the repo root: python3 scripts/stress/ic_old42.py [sample_key.json]
"""
import json, re, sys
sys.path.insert(0, 'scripts/stress')
from ic_common import load_closure, load_ic, ro_labels, score, path_min, ends

LABELS = "T S T T S S E T E E S T T T S T E T S E S T T S T T T T S S T S E T T T S T T T T T".split()
key_path = sys.argv[1] if len(sys.argv) > 1 else '/tmp/work/sample_key.json'
old = json.load(open(key_path))
assert len(old) == len(LABELS) == 42

facts = load_closure(); ic, _ = load_ic(); rl = ro_labels()
by_sig = {}
for f in facts:
    k = f['k']
    sig = (k[0], k[1], k[2], k[3], k[4]) if k[0] == 'effect' else (k[0], rl[k[1]], k[2], k[3])
    by_sig[sig] = f
rels = sorted(set(rl.values()), key=len, reverse=True)


def sig_of(s):
    neg = s.startswith('¬'); s = s[1:] if neg else s
    cur = re.findall(r'\[([A-Za-z]+:[^\]]+)\]', s)
    a, b = cur[0], cur[-1]
    rest = s[s.index(f'[{a}] ') + len(a) + 3:]
    m = re.match(r'→([+−]) (\w+)\(', rest)
    if m: return ('effect', 'pos' if m.group(1) == '+' else 'neg', m.group(2), a, b)
    r = next(r for r in rels if rest.startswith(r + ' '))
    return ('notRel' if neg else 'rel', r, a, b)


rows = [('old_index', 'old_band', 'old_ic', 'llm_label', 'old_fact', 'in_current_closure', 'current_fact', 'current_ic', 'current_path_min', 'current_rule', 'current_depth')]
for (i, band, sc, fact), lab in zip(old, LABELS):
    f = by_sig.get(sig_of(fact))
    if f is None:
        rows.append((i, band, sc, lab, fact, 'no', '', '', '', '', '')); continue
    s = score(f['k'], ic); pm = path_min(f['t'], ic)
    rows.append((i, band, sc, lab, fact, 'yes', f['fact'], '' if s is None else round(s, 3), '' if pm is None else round(pm, 3), f['rule'], f['depth']))
with open('data/stress/07/old42_llm_labels.tsv', 'w', encoding='utf-8') as fh:
    for r in rows: fh.write('\t'.join(map(str, r)) + '\n')
found = sum(1 for r in rows[1:] if r[5] == 'yes')
print(f'old 42: {found} found in the current closure; labels T {LABELS.count("T")} S {LABELS.count("S")} E {LABELS.count("E")}')
for r in rows[1:]:
    if r[5] == 'no': print('  missing:', r[3], r[4])
