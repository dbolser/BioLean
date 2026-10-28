"""Hole search: ILP inverse entailment by enumeration, over the facts and rules of closure.py.

A textbook statement C that follows from nothing else is an axiom. For every rule that could conclude C,
find the instantiations where exactly one premise is already known (asserted or derived). The other premise
is then fully determined, and it is a HOLE: a candidate missing premise, the hypothesis that would make C a
theorem. Holes are grouped (one hole can complete several sentences), ranked, and judged.

Rules enumerated (the same as closure.py): relChain, relTrans, isaInherit, isaGeneralise, notRelSub,
viaAmount, viaActivity, and isaInheritEffect. Holes that are already contradicted (notRel, opposite sign,
reversed is_a) are dropped. Ranking: (a) distinct sentences completed, (b) IC of the less specific entity of
the hole (min over the entities that have one, from data/search/ic.json if present), (c) depth of the completed derivation, shallower first.
Filters, each counted and kept in holes.json with its reason: the hole cannot be stated in Lean (RO domain/range
sorts), is_a across kinds, is_a or part_of that GO/UBERON/CL/ChEBI refute (not an ancestor, or the reverse holds),
or a relation/kind pattern never seen in the textbook (Progol-style mode declarations, learned from the data).
Effect holes are screened only for the Lean Target kinds (an activity must be a protein or function).
Judgements are hand-written in data/search/holes_judgement.json (key = hole key) and merged in.

Usage: holes.py <claims_m2_dir> <go.obo> [max_depth] [--no-m3] [--legacy]     (same arguments as closure.py; round 3 loads by default)
Output: data/search/holes.json, docs/holes.md."""
import sys, json, glob, re, collections, pathlib

# --- the facts, the rules' data and the closure: run closure.py up to its report section, unchanged.
CLOSURE = pathlib.Path(__file__).with_name('closure.py').read_text()
MARK = '# --- report'
assert MARK in CLOSURE, 'closure.py lost its report marker'
ns = {'__name__': 'closure_loader'}
exec(compile(CLOSURE[:CLOSURE.index(MARK)], 'closure.py', 'exec'), ns)
facts, asserted, sid_of, labels_e = ns['facts'], ns['asserted'], ns['sid_of'], ns['labels_e']
ISA, flip, lab, SIGN, kind_of, by_label = ns['ISA'], ns['flip'], ns['lab'], ns['SIGN'], ns['kind_of'], ns['by_label']
transitive, go_obo, src_dir = ns['transitive'], ns['go_obo'], ns['src']
chains_by_r3 = collections.defaultdict(list)
for r1, r2, r3 in ns['chains']: chains_by_r3[r3].append((r1, r2))
ALL = facts                                    # asserted plus derived, closed under the rules

# --- indexes over ALL
def index(keys, f):
    d = collections.defaultdict(list)
    for k in keys: d[f(k)].append(k)
    return d
rels = [k for k in ALL if k[0] == 'rel']; effs = [k for k in ALL if k[0] == 'effect']; nrels = [k for k in ALL if k[0] == 'notRel']
rel_s = index(rels, lambda k: (k[1], k[2])); rel_o = index(rels, lambda k: (k[1], k[3]))
eff_s = index(effs, lambda k: (k[2], k[3])); eff_o = index(effs, lambda k: (k[2], k[4])); eff_sto = index(effs, lambda k: (k[1], k[2], k[4]))
nrel_o = index(nrels, lambda k: (k[1], k[3]))

def instances(C):
    """Yield (rule, A, B): C follows from premises A and B by rule, and at least one of A, B is in ALL."""
    if C[0] == 'rel':
        _, r, a, c = C
        for r1, r2 in chains_by_r3.get(r, ()):
            for k in rel_s.get((r1, a), ()): yield 'relChain', k, ('rel', r2, k[3], c)
            for k in rel_o.get((r2, c), ()): yield 'relChain', ('rel', r1, a, k[2]), k
        if r in transitive:
            for k in rel_s.get((r, a), ()): yield 'relTrans', k, ('rel', r, k[3], c)
            for k in rel_o.get((r, c), ()): yield 'relTrans', ('rel', r, a, k[2]), k
        if r not in (ISA, flip(ISA)):
            for k in rel_s.get((ISA, a), ()): yield 'isaInherit', k, ('rel', r, k[3], c)
            for k in rel_o.get((r, c), ()): yield 'isaInherit', ('rel', ISA, a, k[2]), k
            for k in rel_s.get((r, a), ()): yield 'isaGeneralise', k, ('rel', ISA, k[3], c)
            for k in rel_o.get((ISA, c), ()): yield 'isaGeneralise', ('rel', r, a, k[2]), k
    elif C[0] == 'notRel':
        _, r, a, c = C
        for k in rel_s.get((ISA, a), ()): yield 'notRelSub', k, ('notRel', r, k[3], c)
        for k in nrel_o.get((r, c), ()): yield 'notRelSub', ('rel', ISA, a, k[2]), k
    else:
        _, sg, t2, a, x = C
        for rule, t1 in (('viaAmount', 'amount'), ('viaActivity', 'activity')):
            for k in eff_s.get((t1, a), ()): yield rule, k, ('effect', SIGN[(sg, k[1])], t2, k[4], x)   # sign product is its own inverse
            for k in eff_o.get((t2, x), ()): yield rule, ('effect', SIGN[(sg, k[1])], t1, a, k[3]), k
        for k in rel_s.get((ISA, a), ()): yield 'isaInheritEffect', k, ('effect', sg, t2, k[3], x)
        for k in eff_sto.get((sg, t2, x), ()): yield 'isaInheritEffect', ('rel', ISA, a, k[3]), k

# --- a premise is usable for C if it exists and does not itself rest on C
def leaves_of(k, memo={}):
    if k not in memo:
        d = facts[k]['deriv']
        memo[k] = {k} if d[0] in ('lit', 'refineAxiom') else set().union(*(leaves_of(p) for p in d[1:] if isinstance(p, tuple)))
    return memo[k]
def usable(P, C): return P in ALL and P != C and C not in leaves_of(P)

def subj_obj(k): return (k[3], k[4]) if k[0] == 'effect' else (k[2], k[3])
def reflexive(H):   # a r a, or a context of a against a ("insulin ⊓ located in blood raises insulin"); --legacy: exact curies only
    s, o = subj_obj(H); return s == o or not ns['LEGACY'] and (s.startswith(o + '&') or o.startswith(s + '&'))
def contradicted(H):
    """Why the hole is already refuted by what we know, or None."""
    if H[0] == 'rel':
        if ('notRel',) + H[1:] in ALL: return 'notRel exists'
        if H[1] == ISA and ('rel', ISA, H[3], H[2]) in ALL: return 'reverse is_a exists'
    elif H[0] == 'notRel':
        if ('rel',) + H[1:] in ALL: return 'rel exists'
    elif ('effect', 'neg' if H[1] == 'pos' else 'pos') + H[2:] in ALL: return 'opposite sign exists'

# --- enumerate
derivable = []; opaque = 0                     # asserted facts that follow from others; instantiations skipped as circular
holes = collections.defaultdict(list)          # hole -> [(C, rule, present premise)]
dropped = collections.Counter(); n_inst = collections.Counter()
for C in sorted(asserted, key=str):
    seen = set(); mine = []
    for rule, A, B in instances(C):
        if (rule, A, B) in seen: continue
        seen.add((rule, A, B))
        ua, ub = usable(A, C), usable(B, C)
        if ua and ub: derivable.append(C); break
        if ua != ub and ((A in ALL) != (B in ALL)): mine.append((rule, A, B, ua))
        elif A in ALL and B in ALL: opaque += 1    # the other premise exists only because of C
    else:
        for rule, A, B, a_present in mine:
            H, P = (B, A) if a_present else (A, B)
            if reflexive(H): dropped['reflexive'] += 1; continue
            why = contradicted(H)
            if why: dropped[why] += 1; continue
            holes[H].append((C, rule, P)); n_inst[rule] += 1
print(f'asserted {len(asserted)}: derivable from others {len(derivable)}, axioms {len(asserted) - len(derivable)}')
print(f'{len(holes)} distinct holes from {sum(n_inst.values())} instantiations; dropped {dict(dropped)}; circular skipped {opaque}')

# --- what the type system, the ontologies and the corpus say about a hole
def sort_table(def_name):
    body = re.search(r'def ' + def_name + r' : List \(Rel × RelSort\) := \[(.*?)\n\]', ns['ro_src'], re.S).group(1)
    return {ns['parse_rel'](m.group(1)): m.group(2) for m in re.finditer(r'\((⟨[^⟩]*⟩), \.(continuant|occurrent)\)', body)}
DOMAINS, RANGES = sort_table('domains'), sort_table('ranges')
def sort_of(kind): return 'occurrent' if kind in ('process', 'function') else 'continuant'
def accepts(r, ks, ko):                         # Rel.accepts in Claim.lean
    d, g = (RANGES, DOMAINS) if r[2] else (DOMAINS, RANGES); base = (r[0], r[1], False)
    return d.get(base, sort_of(ks)) == sort_of(ks) and g.get(base, sort_of(ko)) == sort_of(ko)

OBO_FILES = {'GO': go_obo, **{pre: str(pathlib.Path(go_obo).parent / fn) for pre, fn in (('UBERON', 'uberon.obo'), ('CL', 'cl-basic.obo'), ('CHEBI', 'chebi_lite.obo'))}}
_onto = {}
def ontology(prefix):
    """(live ids, {id: {'is_a': parents, 'part_of': parents}}, {id: name}) of the OBO file beside go.obo, or None."""
    if prefix not in _onto:
        path = OBO_FILES.get(prefix); _onto[prefix] = None
        if path and pathlib.Path(path).exists():
            up = collections.defaultdict(lambda: {'is_a': set(), 'part_of': set()}); live = set(); names = {}; cur = None
            for line in open(path, encoding='utf-8'):
                if line.startswith('['): cur = None
                elif line.startswith('id: ' + prefix + ':'): cur = line[4:].strip(); live.add(cur)
                elif cur and line.startswith('name: '): names[cur] = line[6:].strip()
                elif cur and line.startswith('is_obsolete: true'): live.discard(cur)
                elif cur and line.startswith('is_a: '): up[cur]['is_a'].add(line.split()[1])
                elif cur and line.startswith('relationship: part_of '): up[cur]['part_of'].add(line.split()[2])
            _onto[prefix] = (live, up, names)
    return _onto[prefix]
def reaches(up, x, y, rel):
    """Is y above x over is_a (rel='is_a'), or over is_a and part_of with at least one part_of (rel='part_of')?"""
    seen = {(x, False)}; stack = [(x, False)]
    while stack:
        n, used = stack.pop()
        for how, parents in up[n].items() if n in up else ():
            if how == 'part_of' and rel == 'is_a': continue
            for p in parents:
                st = (p, used or how == 'part_of')
                if st not in seen: seen.add(st); stack.append(st)
    return (y, rel == 'part_of') in seen
PART_OF, HAS_PART = by_label['part of'], by_label['has part']
def ontology_says(H):
    """'confirmed', 'refuted: ...' or None (the ontology is silent or does not cover both entities)."""
    if H[0] != 'rel' or H[1] not in (ISA, PART_OF, HAS_PART): return None
    x, y = (H[3], H[2]) if H[1] == HAS_PART else (H[2], H[3]); rel = 'is_a' if H[1] == ISA else 'part_of'
    px = x.split(':')[0]; o = ontology(px)
    if o is None or px != y.split(':')[0] or x not in o[0] or y not in o[0]: return None
    if reaches(o[1], x, y, rel): return 'confirmed'
    if reaches(o[1], y, x, rel): return f'refuted (reverse {rel} holds): {px}'
    return f'refuted (not a subclass): {px}' if rel == 'is_a' else None   # part_of is open-world: silence is not refutation
def obsolete(c):
    o = ontology(c.split(':')[0]); return bool(o) and c in o[2] and c not in o[0]
modes = {(k[1], kind_of(k[2]), kind_of(k[3])) for k in asserted if k[0] != 'effect'}
TARGET_KINDS = {'activity': ('protein', 'function'), 'process': ('process',), 'phenotype': ('phenotype',), 'site': ('anatomy',)}   # Target in Claim.lean
def screen(H):
    """Why the hole should not be ranked (cannot be stated, cannot be true, or a pattern the textbook never uses), or None."""
    s, o = subj_obj(H); ks, ko = kind_of(s), kind_of(o)
    for c in (s, o):
        if obsolete(c): return f'obsolete term: {c}'
    if H[0] == 'effect':
        if ko not in TARGET_KINDS.get(H[2], (ko,)): return f'Lean target kind: the {H[2]} of a {ko}'
        return None
    if not accepts(H[1], ks, ko): return f'Lean RO sorts: {lab(H[1])} from {ks} to {ko}'
    if H[:2] == ('rel', ISA) and ks != ko: return f'is_a across kinds: {ks} to {ko}'
    v = ontology_says(H)
    if v and v.startswith('refuted'): return 'ontology ' + v
    if (H[1], ks, ko) not in modes: return f'unseen relation pattern: {lab(H[1])} from {ks} to {ko}'

# --- names and texts
texts = {r['id']: r['source'] for p in sorted(glob.glob(f'{src_dir}/*.json')) for r in json.load(open(p))}
def name(c):
    o = ontology(c.split(':')[0]); return (o[2].get(c) if o else None) or labels_e.get(c) or c
SHORT = {'cell-structure-and-function': 'cell', 'how-cells-obtain-energy': 'energy', 'the-body-s-systems': 'body', 'the-cellular-basis-of-inheritance': 'inherit', 'reproduction-at-the-cellular-level': 'repro'}
def short(sid): chapter, rest = sid.split('-m', 1); return f"{SHORT.get(chapter, chapter)}:m{rest}"
def say(k):
    if k[0] == 'effect': return f"{name(k[3])} {'raises' if k[1] == 'pos' else 'lowers'} the {k[2]} of {name(k[4])}"
    return f"{name(k[2])} {'does NOT ' if k[0] == 'notRel' else ''}{lab(k[1])} {name(k[3])}"
ic = {}
if pathlib.Path('data/search/ic.json').exists():
    ic = {c: t['ic'] for c, t in json.load(open('data/search/ic.json'))['terms'].items() if t.get('ic') is not None}
def ic_of(H):   # a refined entity (context) takes its base term's IC, a lower bound
    v = [ic[c.split('&')[0]] for c in subj_obj(H) if c.split('&')[0] in ic]; return round(min(v), 2) if v else None
print(f'IC loaded for {len(ic)} terms' if ic else 'no data/search/ic.json: ranking without IC')

# --- group, screen, rank
def ids(k): return ' / '.join(subj_obj(k))
def hole_key(H): return '|'.join(['effect', *H[1:]]) if H[0] == 'effect' else '|'.join([H[0], lab(H[1]), H[2], H[3]])
records = []
for H, sup in holes.items():
    sents = sorted({C for C, _, _ in sup}, key=str)
    records.append(dict(
        key=hole_key(H), say=say(H), ids=ids(H), n=len(sents), ic=ic_of(H),
        depth=min(1 + facts[P]['depth'] for _, _, P in sup), rules=sorted({r for _, r, _ in sup}),
        filtered=screen(H), ontology=ontology_says(H),
        completes=[dict(sid=sid_of[C], sentence=say(C), text=texts.get(sid_of[C], '')[:160], rule=r, via=say(P))
                   for C, r, P in sorted(sup, key=lambda t: (str(t[0]), t[1]))]))
open_ = [r for r in records if not r['filtered']]
# Holes that complete exactly the same sentences by the same rule differ only in the free intermediate: alternatives, any one will do.
groups = collections.defaultdict(list)
for r in open_: groups[(tuple(sorted(c['sid'] for c in r['completes'])), tuple(r['rules']))].append(r)
def pick(g): return min(g, key=lambda r: (r['ontology'] != 'confirmed', -(r['ic'] or 0), r['depth'], r['say']))
clusters = sorted(([pick(g)] + sorted((r for r in g if r is not pick(g)), key=lambda r: r['say']) for g in groups.values()),
                  key=lambda g: (-g[0]['n'], -(g[0]['ic'] or 0), g[0]['depth'], g[0]['say']))
for i, g in enumerate(clusters, 1):
    for r in g: r['cluster'] = i
    g[0]['alternatives'] = [dict(key=r['key'], say=r['say'], ids=r['ids'], ic=r['ic'], depth=r['depth'], rules=r['rules']) for r in g[1:]]
records.sort(key=lambda r: (r['filtered'] is not None, r.get('cluster', 0), r.get('alternatives') is None))

# --- judgements (hand-written, keyed by the hole key) and the report
JUDGE = pathlib.Path('data/search/holes_judgement.json')
judged = json.load(open(JUDGE)) if JUDGE.exists() else {}
for r in records: r['judgement'], r['note'] = (judged.get(r['key']) or ['unjudged', ''])[:2]
def tally(rs): return dict(collections.Counter(rule for r in rs for rule in r['rules']))
summary = dict(asserted=len(asserted), derivable_from_others=len(derivable), axioms=len(asserted) - len(derivable),
               holes_before_screening=len(records), instantiations=sum(n_inst.values()), contradicted_dropped=dict(dropped),
               screened_out=dict(collections.Counter(r['filtered'].split(':')[0] for r in records if r['filtered'])),
               holes=len(open_), clusters=len(clusters), holes_by_rule=tally(open_), holes_by_rule_before_screening=tally(records),
               clusters_by_rule=tally(g[0] for g in clusters),
               clusters_by_sentences_completed={(str(k) + ('+' if k == 4 else '')): v for k, v in sorted(collections.Counter(min(g[0]['n'], 4) for g in clusters).items())},
               obsolete_terms_in_facts=sorted({c for k in ALL for c in subj_obj(k) if obsolete(c)}),
               ontology_confirmed=sum(r['ontology'] == 'confirmed' for r in open_), circular_skipped=opaque, ic_used=bool(ic))
# screened-out holes keep their reason and counts but not the sentence detail (the file would be 3 times larger)
json.dump(dict(summary=summary, holes=[r if not r['filtered'] else {k: v for k, v in r.items() if k != 'completes'} for r in records]),
          open('data/search/holes.json', 'w'), indent=0, ensure_ascii=False)
print(json.dumps(summary, indent=1))

def cell(s): return s.replace('|', '/').replace('\n', ' ')
def row(g):
    r = g[0]; alts = r['alternatives']
    done = '<br>'.join(cell(f"{c['sentence']} ({short(c['sid'])})") for c in r['completes'][:4]) + (f"<br>... {r['n'] - 4} more" if r['n'] > 4 else '')
    hole = cell(r['say']) + (f"<br>(or any of {len(alts)} alternatives: {cell('; '.join(a['say'] for a in alts[:3]))}{'; ...' if len(alts) > 3 else ''})" if alts else '')
    return f"| {r['cluster']} | {hole} | {done} | {', '.join(r['rules'])} | {r['n']} | {r['ic'] if r['ic'] is not None else ''} | {r['judgement']}{': ' + cell(r['note']) if r['note'] else ''} |"
HEAD = ['| # | if this were known ... | ... these sentences become theorems | rule | n | IC | judgement |', '|---|---|---|---|---|---|---|']
notes = pathlib.Path('data/search/holes_notes.md')
top = clusters[:40]
lines = ['# Holes: single missing premises that would make textbook sentences theorems', '',
         'Generated by `scripts/search/holes.py` from `data/search/holes.json`; judgements are in `data/search/holes_judgement.json` '
         'and the notes below in `data/search/holes_notes.md`. Edit those, not this file.', '',
         f"{summary['axioms']} of {summary['asserted']} textbook statements follow from nothing else. For each, every rule of `closure.py` was run "
         f"backwards with one premise known; the other premise is then fixed, and is a hole. That gave {summary['holes_before_screening']} distinct holes. "
         f"{summary['holes_before_screening'] - summary['holes']} were screened out (cannot be stated in Lean, cannot be true, or a pattern the textbook never uses), "
         f"leaving {summary['holes']}. Holes that complete exactly the same sentences by the same rule differ only in the free intermediate; they are grouped as alternatives: {summary['clusters']} hypotheses. "
         f"Ranked by sentences completed (n), then IC of the less specific entity{'' if ic else ' (IC not available)'}, then derivation depth. "
         'Each row reads: if the hole were a known fact, the listed textbook sentences would follow from it and one other fact already in the corpus.', '',
         '## Numbers', '', '| rule | holes found | after screening | hypotheses (grouped) |', '|---|---:|---:|---:|'] + \
         [f"| {rule} | {summary['holes_by_rule_before_screening'].get(rule, 0)} | {summary['holes_by_rule'].get(rule, 0)} | {summary['clusters_by_rule'].get(rule, 0)} |"
          for rule in sorted(summary['holes_by_rule_before_screening'], key=lambda x: -summary['holes_by_rule_before_screening'][x])] + \
         ['', 'Screened out: ' + '; '.join(f'{k} {v}' for k, v in sorted(summary['screened_out'].items(), key=lambda kv: -kv[1])) + '. '
          f"Dropped before counting as already contradicted: {', '.join(f'{k} {v}' for k, v in summary['contradicted_dropped'].items())}. "
          f"{summary['ontology_confirmed']} of the remaining holes are confirmed by an ontology (true but unstated). A hole can belong to more than one rule, so the columns do not add up. "
          'Judgement of the top 40: ' + ', '.join(f'{k} {v}' for k, v in collections.Counter(g[0]['judgement'] for g in clusters[:40]).most_common()) + '.', '',
         '## The top 40', ''] + HEAD + [row(g) for g in top] + ['', '## Beyond the top 40', '',
         'Sentences completed is dominated by transitivity holes, so the rules that need a mechanism (effect chains, inheritance of effects, negation) rarely reach the top 40. '
         'These were picked by reading the other rule families, then judged. Everything else is in `holes.json`.', ''] + HEAD
lines += [row(g) for g in clusters[40:] if g[0]['judgement'] != 'unjudged']
pathlib.Path('docs/holes.md').write_text('\n'.join(lines) + '\n' + (('\n' + notes.read_text()) if notes.exists() else ''))
print('wrote data/search/holes.json, docs/holes.md')
