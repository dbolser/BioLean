"""Collect every CURIE biolib uses: Entity literals ⟨"PREFIX:id", "label"⟩ in BioLean/**/*.lean, and the m2 subject,
object, mediator, linked entities and CURIE corrections of data/textbook/claims_m2/*.json (`obo.mentioned_curies`). Refined curies (`A&RO:...=(B)`) are not literals.
Writes data/ontology/used_curies.json ({curie: [sources]}) and prints counts by prefix.
Usage: uv run python scripts/ontology/collect_entities.py [out.json]"""
import re, sys, json, glob, pathlib, collections
sys.path.insert(0, str(pathlib.Path(__file__).parent))
import obo

CURIE = re.compile(r'[A-Za-z][A-Za-z0-9_]*:[A-Za-z0-9_.\-]+')
LIT = re.compile(r'⟨"((?:[^"\\]|\\.)*)",\s*"(?:[^"\\]|\\.)*"\s*⟩')
out = sys.argv[1] if len(sys.argv) > 1 else 'data/ontology/used_curies.json'

used = collections.defaultdict(set)
for p in sorted(glob.glob('BioLean/**/*.lean', recursive=True)):
    if p == 'BioLean/Ontology/IsA.lean': continue  # our own output
    for m in LIT.finditer(open(p, encoding='utf-8').read()):
        if CURIE.fullmatch(m.group(1)): used[m.group(1)].add('lean')
for r in obo.claims('data/textbook/claims_m2'):
    for c in obo.mentioned_curies(r):
        if CURIE.fullmatch(c): used[c].add('claims')

json.dump({c: sorted(s) for c, s in sorted(used.items())}, open(out, 'w'), indent=0)
by = collections.Counter(c.split(':')[0] for c in used)
both = collections.Counter(c.split(':')[0] for c, s in used.items() if len(s) == 2)
print(f'{len(used)} used CURIEs ({sum(1 for s in used.values() if "lean" in s)} in Lean, '
      f'{sum(1 for s in used.values() if "claims" in s)} in claims_m2)')
for pre, n in by.most_common(): print(f'  {pre:12} {n:5}   (both {both[pre]})')
