"""Intrinsic information content (Resnik, from descendant counts) for every ontology term the textbook claims use.

IC(t) = -log( (descendants(t) + 1) / N ),  where descendants(t) counts the proper descendants of t, so
(descendants + 1) is the size of the subtree rooted at t, and N is the number of live terms in t's ontology
(for GO, in t's namespace: the three aspects are separate ontologies, each root has IC 0).
Descendants are followed over is_a and part_of (GO, UBERON, CL) because an anatomy or cell-component term
that is only a part of something is still a more specific term; `ic_isa` is the is_a-only figure for comparison.
ChEBI has no part_of, so both figures agree there. An obsolete term with exactly one `replaced_by` takes the
replacement's IC (`via`); other obsolete terms get none. Ontologies we do not load (NCBITaxon is 690 MB, PR, SO, MONDO,
PATO, HP, ...) are counted in `no_ic_for_prefixes`.
Usage: ic.py <claims_m2_dir> <obo_dir> [out.json]    (downloads missing OBO files from purl.obolibrary.org)"""
import sys, os, json, math, collections, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).parent))
import obo
claims_dir, obo_dir = sys.argv[1], sys.argv[2]; out = sys.argv[3] if len(sys.argv) > 3 else 'data/search/ic.json'
FILES = {'GO': 'go.obo', 'UBERON': 'uberon.obo', 'CL': 'cl-basic.obo', 'CHEBI': 'chebi_lite.obo'}
URLS = {'chebi_lite.obo': 'http://purl.obolibrary.org/obo/chebi/chebi_lite.obo'}

used = set().union(*map(obo.mentioned_curies, obo.claims(claims_dir)))
table = {}; version = {}
for pre, fn in FILES.items():
    path = os.path.join(obo_dir, fn)
    if not os.path.exists(path):
        open(path, 'wb').write(obo.request(URLS.get(fn, f'http://purl.obolibrary.org/obo/{fn}')).read())
    T = {t['id']: t for t in obo.terms(path) if t['id'].startswith(pre + ':')}
    version[pre] = f'{fn} {obo.version(path)}'
    alt = {a: t['id'] for t in T.values() for a in t['alt_id']}
    live = [t for t in T.values() if not t['obsolete']]
    size = collections.Counter(t['namespace'] if pre == 'GO' else pre for t in live)
    kids = {'isa+partof': collections.defaultdict(list), 'isa': collections.defaultdict(list)}
    for t in live:
        for p in t['is_a']: kids['isa'][p].append(t['id']); kids['isa+partof'][p].append(t['id'])
        for p in t['part_of']: kids['isa+partof'][p].append(t['id'])
    def subtree(root, ch):
        seen = {root}; stack = [root]
        while stack:
            for c in ch.get(stack.pop(), ()):
                if c not in seen: seen.add(c); stack.append(c)
        return len(seen)
    def measure(t):
        n = size[t['namespace'] if pre == 'GO' else pre]; rec = {'n': n}
        for key, mode in (('', 'isa+partof'), ('_isa', 'isa')):
            d = subtree(t['id'], kids[mode]); rec['subtree' + key] = d; rec['ic' + key] = round(-math.log(d / n), 4)
        return rec
    for c in sorted(used):
        if not c.startswith(pre + ':'): continue
        t = T.get(alt.get(c, c))
        if t is None: table[c] = {'missing': True}; continue
        rec = {'name': t['name'], 'id': t['id']}
        if not t['obsolete']: rec.update(measure(t))
        else:   # an obsolete term with one live replacement inherits the replacement's IC (flagged in `via`)
            rec.update(obsolete=True, replaced_by=t['replaced_by'], consider=t['consider'])
            r = T.get(t['replaced_by'][0]) if len(t['replaced_by']) == 1 else None
            if r and not r['obsolete']: rec.update(measure(r), via=r['id'])
        table[c] = rec
other = collections.Counter(c.split(':')[0] for c in used if c.split(':')[0] not in FILES)
json.dump({'definition': 'IC = -log(subtree/N); subtree = the term plus its descendants over is_a+part_of (ic) or is_a (ic_isa); N = live terms in the ontology (GO: namespace)',
           'sources': version, 'no_ic_for_prefixes': dict(other), 'terms': table}, open(out, 'w'), indent=0, sort_keys=True)
scored = [v for v in table.values() if 'ic' in v]
print(f'{len(used)} CURIEs used; IC for {len(scored)}; obsolete {sum(1 for v in table.values() if v.get("obsolete"))}; missing {sum(1 for v in table.values() if v.get("missing"))}; no ontology file for {dict(other)}')
print('sources:', version)
