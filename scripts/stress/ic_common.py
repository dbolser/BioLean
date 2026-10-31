"""Shared readers for program 07 (the IC triviality threshold). Read-only over data/search and data/textbook.

Nothing here regenerates the closure. It reads data/search/closure.json (every derived fact with its tree),
data/search/closure_ic.json (the scored ones) and data/search/ic.json (IC per term), and recomputes the two
scores closure.py uses (min IC of the two ends; min IC over every entity in the proof) so they can be checked.
"""
import ast, collections, glob, json, re

ROOT = '.'   # run from the repo root
ISA = ('rdfs', 0, False)
IC_MIN = 2.5   # the threshold in scripts/search/closure.py


def ro_labels():
    src = open(f'{ROOT}/BioLean/RO.lean', encoding='utf-8').read()
    def parse(t):
        m = re.match(r'⟨\.(ro|bfo), (\d+), (true|false)⟩', t); return (m.group(1), int(m.group(2)), m.group(3) == 'true')
    lab = {parse(m.group(1)): m.group(2) for m in re.finditer(r'\((⟨\.(?:ro|bfo), \d+, false⟩), "([^"]+)"\)', src)}
    lab[ISA] = 'is_a'
    return lab


def key_of(f):
    """closure.json stores keys as strings; make them the tuples closure.py uses."""
    k = f['key']
    if k[0] == 'effect': return tuple(k)
    return (k[0], ast.literal_eval(k[1]), k[2], k[3])


def ends(k):
    return (k[3], k[4]) if k[0] == 'effect' else (k[2], k[3])


def base(c):
    return c.split('&')[0]


def load_ic():
    tab = json.load(open(f'{ROOT}/data/search/ic.json'))['terms']
    return {c: v['ic'] for c, v in tab.items() if 'ic' in v}, tab


def ic_of(c, ic):
    """A refined entity takes its base term's IC (closure.py does the same; a lower bound)."""
    return ic.get(c, ic.get(base(c)))


def score(k, ic):
    xs = [ic_of(c, ic) for c in ends(k)]
    return None if any(x is None for x in xs) else min(xs)


def bound(k, ic):
    xs = [x for x in (ic_of(c, ic) for c in ends(k)) if x is not None]
    return min(xs) if xs else None


# --- derivation trees: closure.json keeps them as indented text, two spaces per level
LINE = re.compile(r'^(?P<ind> *)(?P<fact>.*?)   (?:\((?P<rule>[A-Za-z]+), b=(?P<b>[0-9.]+)\)|\[(?P<sid>[^\]]+)\])$')


def parse_tree(text):
    """Nested dicts: {fact, rule or sid, depth_in_tree, children}."""
    root, stack = None, []
    for ln in text.split('\n'):
        m = LINE.match(ln)
        if not m: raise ValueError(f'tree line not parsed: {ln!r}')
        node = {'fact': m.group('fact'), 'rule': m.group('rule'), 'sid': m.group('sid'), 'children': []}
        lvl = len(m.group('ind')) // 2
        stack = stack[:lvl]
        if stack: stack[-1]['children'].append(node)
        else: root = node
        stack.append(node)
    return root


def leaves(node):
    if not node['children']: return [node]
    return [x for ch in node['children'] for x in leaves(ch)]


def nodes(node):
    return [node] + [x for ch in node['children'] for x in nodes(ch)]


CURIE_IN_FACT = re.compile(r'\[([A-Za-z]+:[^\]]+)\]')


def path_min(tree, ic):
    """Min IC over every entity named anywhere in the proof (closure.py's `path_min`)."""
    xs = [ic_of(c, ic) for n in nodes(tree) for c in CURIE_IN_FACT.findall(n['fact'])]
    xs = [x for x in xs if x is not None]
    return min(xs) if xs else None


def strip_curies(s):
    return re.sub(r' \[[A-Za-z]+:[^\]]*\]', '', s)


# --- textbook sentences, by statement id
def sentences():
    out = {}
    for d in ('claims', 'claims_m1', 'claims_m2', 'claims_m3'):
        for p in sorted(glob.glob(f'{ROOT}/data/textbook/{d}/*.json')):
            for r in json.load(open(p)):
                if r.get('source'): out.setdefault(r['id'], r['source'])
    return out


def sentence_of(sid, sents):
    if sid in sents: return sents[sid]
    m = re.match(r'(.*-\d+)[a-z]$', sid)   # round-3 split sentences carry a letter suffix
    return sents.get(m.group(1)) if m else None


# --- plain English
REL_PHRASE = {
    'is_a': 'is a kind of', 'part of': 'is part of', 'has part': 'has as a part', 'overlaps': 'overlaps (shares a part with)',
    'has part structure that is capable of': 'has a part that can carry out', 'part of structure that is capable of':
    'is part of something that can carry out', 'has part that occurs in': 'has a part that happens in',
    'capable of': 'can carry out', 'capable of part of': 'can carry out part of', 'located in': 'is located in',
    'occurs in': 'happens in', 'has input': 'takes as input', 'has output': 'gives as output', 'produces': 'produces',
    'derives from': 'derives from', 'connected to': 'is connected to', 'has participant': 'has as a participant',
    'disease has location': 'is a disease located in', 'has quality': 'has the quality', 'happens during': 'happens during',
    'surrounded by': 'is surrounded by', 'interacts with': 'interacts with', 'molecularly interacts with':
    'binds or reacts with', 'adjacent to': 'is next to', 'involved in': 'is involved in', 'attached to part of':
    'is attached to part of', 'transcribed to': 'is transcribed to', 'participates in': 'takes part in',
    'attached to': 'is attached to', 'in taxon': 'is found in the taxon', 'enables': 'enables', 'has function':
    'has the function', 'ends with': 'ends with', 'precedes': 'comes before', 'has gene product': 'has the gene product',
    'develops from': 'develops from'}
EFFECT_PHRASE = {('pos', 'amount'): 'raises the amount of', ('neg', 'amount'): 'lowers the amount of',
                 ('pos', 'process'): 'promotes', ('neg', 'process'): 'inhibits',
                 ('pos', 'activity'): 'raises the activity of', ('neg', 'activity'): 'lowers the activity of',
                 ('pos', 'phenotype'): 'raises', ('neg', 'phenotype'): 'lowers',
                 ('pos', 'site'): 'promotes at the site', ('neg', 'site'): 'inhibits at the site'}


def split_fact(f, k, rlab):
    """(subject label, relation label or effect phrase, object label) from closure.py's show() string."""
    s = f[1:] if f.startswith('¬') else f
    a, b = ends(k)
    i = s.index(f' [{a}] '); slab = s[:i]; rest = s[i + len(a) + 4:]
    if k[0] == 'effect':
        m = re.match(r'→[+−] (\w+)\((.*) \[' + re.escape(b) + r'\]\)$', rest)
        return slab, EFFECT_PHRASE[(k[1], k[2])], m.group(2)
    r = rlab[k[1]]
    assert rest.startswith(r + ' ') and rest.endswith(f' [{b}]'), (f, r)
    return slab, r, rest[len(r) + 1:-len(b) - 3]


REFINE_PHRASE = {'in taxon': 'in', 'located in': 'located in', 'part of': 'part of', 'occurs in': 'occurring in',
                 'surrounded by': 'surrounded by', 'existence overlaps': 'existing during', 'happens during': 'during'}


def taxon_names():
    try:
        rows = [l.split('\t') for l in open(f'{ROOT}/data/stress/07/taxon_names.tsv', encoding='utf-8').read().splitlines()[1:]]
        return {r[0]: r[2] for r in rows if len(r) > 4 and r[4] == 'yes'}
    except FileNotFoundError:
        return {}


TAXA = taxon_names()


def id_names():
    """Names for ids that turn up inside labels: the is_a import, the IC table, the taxa above, and
    data/stress/07/term_names.tsv (OLS4 lookups by ic_ols.py, for the two PO terms nothing else names)."""
    out = {}
    for path, field in ((f'{ROOT}/data/ontology/isa.json', 'label'), (f'{ROOT}/data/search/ic.json', 'name')):
        try: out.update({c: v[field] for c, v in json.load(open(path))['terms'].items() if v.get(field)})
        except FileNotFoundError: pass
    out.update(TAXA)
    try:
        rows = [l.split('\t') for l in open(f'{ROOT}/data/stress/07/term_names.tsv', encoding='utf-8').read().splitlines()[1:]]
        out.update({r[0]: r[2] for r in rows if len(r) > 4 and r[4] == 'yes'})
    except FileNotFoundError: pass
    return out


ID_NAMES = id_names()
RLAB = ro_labels()
TERM_ID = r'(?:GO|UBERON|CL|CHEBI|PO|PR|MONDO|HP|PATO|SO|NCBITaxon):[A-Za-z0-9]+'
COMPOSITE_ID = re.compile(r'\b' + TERM_ID + r'(?:&(?:RO|BFO):\d+=\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*\))*')


def _split_composite(c):
    """'X&R=(Y)&R2=(Z)' -> ('X', [('R', 'Y'), ('R2', 'Z')]); Y and Z may be composite themselves."""
    head, _, rest = c.partition('&'); parts = []
    while rest:
        r, _, rest = rest.partition('=(')
        depth, j = 1, 0
        while depth: depth += {'(': 1, ')': -1}.get(rest[j], 0); j += 1
        parts.append((r, rest[:j - 1])); rest = rest[j:].lstrip('&')
    return head, parts


def _rel_phrase(r):
    pre, num = r.split(':'); lab = RLAB.get((pre.lower(), int(num), False), r)
    return REFINE_PHRASE.get(lab, lab)


def id_text(c):
    """A bare or composite id in words: 'UBERON:0001898&RO:0001025=(UBERON:0001898)' -> 'hypothalamus (located in hypothalamus)'."""
    head, parts = _split_composite(c)
    return re.sub(r' <[^>]*>$', '', ID_NAMES.get(head, head)) + ''.join(f' ({_rel_phrase(r)} {id_text(y)})' for r, y in parts)


def readable(label):
    """'photosynthesis ⊓ occurs in (chloroplast)' -> 'photosynthesis (occurring in chloroplast)'; ids inside a label (a
    taxon, a bare term id, or a whole composite id the closure had no label for) become names."""
    label = COMPOSITE_ID.sub(lambda m: id_text(m.group(0)), label)
    label = re.sub(r'\b(?:BLN|BIOLEAN):([A-Za-z0-9_]+)', lambda m: m.group(1).replace('_', ' '), label)
    def one(m): return f" ({REFINE_PHRASE.get(m.group(1), m.group(1))} {m.group(2)})"
    prev = None
    while prev != label:
        prev = label; label = re.sub(r' ⊓ ([a-z ]+?) \(((?:[^()]|\([^()]*\))*)\)', one, label)
    return label


def parse_str(s, rels):
    """(neg, kind, subject label, phrase key, object label, subject curie, object curie) from a show() string.
    kind is 'rel' or ('effect', sign, target)."""
    neg = s.startswith('¬'); s = s[1:] if neg else s
    cur = CURIE_IN_FACT.findall(s); a, b = cur[0], cur[-1]
    i = s.index(f' [{a}] '); slab = s[:i]; rest = s[i + len(a) + 4:]
    m = re.match(r'→([+−]) (\w+)\((.*) \[' + re.escape(b) + r'\]\)$', rest)
    if m: return neg, ('effect', 'pos' if m.group(1) == '+' else 'neg', m.group(2)), slab, None, m.group(3), a, b
    r = next(r for r in rels if rest.startswith(r + ' '))
    return neg, 'rel', slab, r, rest[len(r) + 1:-len(b) - 3], a, b


def _name_note(label, curie, names):
    """Add the ontology's own name when the textbook's label says something else ('this transfer' [respiratory ...])."""
    nm = names.get(base(curie)) if names else None
    if not nm: return label
    l, n = label.lower().split(' (')[0].strip(), nm.lower()
    if l == n or l.rstrip('s') == n.rstrip('s') or l in n or n in l: return label
    return f'{label} [{nm}]'


def plain_str(s, rels, names=None):
    neg, kind, sl, r, ol, a, b = parse_str(s, rels)
    sl, ol = _name_note(readable(sl), a, names), _name_note(readable(ol), b, names)
    if kind != 'rel': return f'{sl} {EFFECT_PHRASE[(kind[1], kind[2])]} {ol}'
    ph = REL_PHRASE.get(r, r)
    return f'it is not the case that {sl} {ph} {ol}' if neg else f'{sl} {ph} {ol}'


def rel_label_list(rlab):
    return sorted(set(rlab.values()), key=len, reverse=True)


def plain(f, k, rlab, names=None):
    t = plain_str(f, rel_label_list(rlab), names)
    return t[0].upper() + t[1:] + '.'


def restates_refinement(f):
    """The conclusion says nothing beyond a premise once each refined end is read as its base term: 'X in context is_a X',
    or an inheritance step whose is_a premise is a refinement axiom."""
    k = f['k']; a, b = ends(k)
    if '&' not in a and '&' not in b: return False
    if k[0] != 'effect' and k[1] == ISA and base(a) == base(b): return True
    if f['rule'] in ('isaInherit', 'isaInheritEffect', 'notRelSub', 'relTrans'):
        return any(ch['sid'] and ch['sid'].startswith('refine:') for ch in f['t']['children'])
    return False


def weakening(f, keyset, rlab):
    """The conclusion is strictly weaker than something already there: isaGeneralise lifts the object to a parent, or an
    'overlaps' sits beside a 'part of' or 'has part' between the same two ends."""
    k = f['k']
    if f['rule'] == 'isaGeneralise': return True
    if k[0] == 'rel' and rlab.get(k[1]) == 'overlaps':
        parts = [r for r, v in rlab.items() if v in ('part of', 'has part')]
        return any(('rel', p, k[2], k[3]) in keyset for p in parts)
    return False


def chapters(f):
    """Textbook chapters the premises come from (the id before '-m<module>')."""
    return {l['sid'].rsplit('-m', 1)[0] for l in leaves(f['t']) if l['sid'] and not l['sid'].startswith('refine:')}


def templates(k):
    """What a reader would carry from one fact to another: (subject, relation), (relation, object) and (subject, object),
    on base terms; a negated fact counts as its positive. Two facts sharing one of these are near-twins (a rubric example
    must share none with a sheet row)."""
    a, b = ends(k); r = (k[1], k[2]) if k[0] == 'effect' else k[1]
    return {('S', base(a), r), ('O', r, base(b)), ('P', base(a), base(b))}


def load_closure():
    facts = json.load(open(f'{ROOT}/data/search/closure.json'))['facts']
    for f in facts:
        f['k'] = key_of(f); f['t'] = parse_tree(f['tree'])
    return facts


def load_scored():
    return {f['fact']: f for f in json.load(open(f'{ROOT}/data/search/closure_ic.json'))['facts']}


# --- sheet rendering, shared by ic_sheet.py (the 100 rows) and ic_old9.py (the old facts no longer derived)
def term(c, tab):
    b = base(c); nm = (tab.get(b) or {}).get('name')
    return f'{c} ({nm})' if nm else c


def derivation(tree, rels):
    """The proof on one line: numbered premises with their textbook ids, then the steps."""
    prem, steps = [], []
    def walk(n):
        if not n['children']:
            src = 'definition: a refined term is a kind of its base term' if n['sid'].startswith('refine:') else n['sid']
            prem.append(f"({len(prem) + 1}) {plain_str(n['fact'], rels)} [{src}]")
            return f'({len(prem)})'
        parts = [walk(ch) for ch in n['children']]
        out = f"step {len(steps) + 1}" if n is not tree else 'the fact'
        steps.append(f"{' + '.join(parts)} gives {out} by {n['rule']}" + ('' if n is tree else f": {plain_str(n['fact'], rels)}"))
        return f'[{out}]'
    walk(tree)
    return 'Premises: ' + '; '.join(prem) + '. Steps: ' + '; '.join(steps) + '.'


def premise_sentences(tree, sents):
    """The textbook sentence behind each premise, numbered as in `derivation` (definitions left out)."""
    return ' | '.join(f"({i}) {l['sid']}: {sentence_of(l['sid'], sents)}"
                      for i, l in enumerate(leaves(tree), 1) if not l['sid'].startswith('refine:'))


def clean(x): return str(x).replace('\t', ' ').replace('\n', ' ')


def write_tsv(path, rows):
    with open(path, 'w', encoding='utf-8') as fh:
        for r in rows: fh.write('\t'.join(map(clean, r)) + '\n')
