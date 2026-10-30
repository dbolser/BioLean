"""Forward-chain over the compiled textbook statements with BioLean's rules and report what follows.

Facts:   rel(r, a, b) / notRel(r, a, b) / effect(a, sign, target, b)
Rules:   RO chains (enabled), transitivity, is_a laws, inverses, viaAmount, viaActivity, notRelSub/Obj
Every derived fact keeps its shortest derivation (rule, premises). Belief: weakest-link for relational
steps, product for effect chains. Output: data/search/closure.json and a printed summary.
Usage: closure.py <claims_m2_dir> <go.obo> [max_depth] [--ic=T] [--hubs] [--no-m3] [--legacy]
Facts come from the m2 claims and from the round-3 claims in the sibling claims_m3 (`emit_lean_m3.statements`, the
same reading the Lean emitter uses; context gives composite curies as in BioLean/Context.lean). For a record round 3
re-annotated, its rel/notRel/effect replaces the m2 fact, and a some/most claim loads nothing, so that neither
annotation acts as a universal. --no-m3 loads m2 alone.
Interesting facts are ranked and filtered by information content: score(fact) = min IC of its subject and object, read
from data/search/ic.json (build it with scripts/ontology/ic.py; a refined entity takes its base term's IC, a lower bound);
keeps score >= T (default IC_MIN). Writes closure_ic.json and derivations_ic.json, and prints the comparison with the
hub list. --hubs filters by the old hub list instead and writes derivations.json (read by emit_closure_lean.py).
Refinement axioms load by default: every refined entity e ⊓ ∃r.f is_a e (`Entity.refineAxiom`, belief 999/1000), so a
context links to its base term. Derived effect facts carry flags, never dropped: feedback (the chain crosses a loop),
parthood (a premise effect between a part and its whole) and shared_cause (a common cause read as a sequence).
--legacy turns both off and reproduces the earlier output byte for byte."""
import json, glob, re, sys, collections, pathlib, itertools
from fractions import Fraction as F
IC_MIN = 2.5   # suggested threshold, see docs/ic-triviality.md
HUBS, M3, LEGACY = '--hubs' in sys.argv, '--no-m3' not in sys.argv, '--legacy' in sys.argv
IC_T = next((float(a.split('=')[1]) for a in sys.argv if a.startswith('--ic=')), IC_MIN)
args = [a for a in sys.argv[1:] if not a.startswith('--')]
src, go_obo = args[0], args[1]; MAXD = int(args[2]) if len(args) > 2 else 4
sys.path.insert(0, 'scripts/textbook')
# --- reuse kind logic from the emitter
go_ns = {}; cur = None
for line in open(go_obo, encoding='utf-8'):
    if line.startswith('id: GO:'): cur = line[4:].strip()
    elif cur and line.startswith('namespace: '): go_ns[cur] = line[11:].strip(); cur = None
KIND_BY_NS = {'biological_process': 'process', 'molecular_function': 'function', 'cellular_component': 'component'}
PREFIX_KIND = {'CHEBI': 'chemical', 'PR': 'protein', 'UniProt': 'protein', 'UNIPROT': 'protein', 'UniProtKB': 'protein', 'HGNC': 'gene', 'NCBIGene': 'gene', 'SO': 'gene', 'MGI': 'gene', 'HP': 'phenotype', 'MP': 'phenotype', 'PATO': 'phenotype', 'OBA': 'phenotype', 'MONDO': 'disease', 'DOID': 'disease', 'UBERON': 'anatomy', 'CL': 'cellType', 'NCBITaxon': 'taxon'}
def kind_of(c):
    if not c: return None
    p = c.split(':')[0]; return KIND_BY_NS.get(go_ns.get(c.split('&')[0])) if p == 'GO' else PREFIX_KIND.get(p)   # a refined entity keeps its kind
# --- RO data from the generated Lean
ro_src = open('BioLean/RO.lean').read()
def parse_rel(t):
    m = re.match(r'⟨\.(ro|bfo), (\d+), (true|false)⟩', t); return (m.group(1), int(m.group(2)), m.group(3) == 'true')
labels = {parse_rel(m.group(1)): m.group(2) for m in re.finditer(r'\((⟨\.(?:ro|bfo), \d+, false⟩), "([^"]+)"\)', ro_src)}
by_label = {v.lower(): k for k, v in labels.items()}; ISA = ('rdfs', 0, False); labels[ISA] = 'is_a'
def rel_of(l):
    if not l: return None
    l = l.strip().lower().replace('_', ' ')
    if l in ('is a', 'isa', 'subclass of'): return ISA
    return by_label.get(l)
def flip(r): return (r[0], r[1], not r[2])
def lab(r): return ('inverse(' + labels.get((r[0], r[1], False), str(r)) + ')') if r[2] else labels.get(r, str(r))
def block(name):
    m = re.search(r'def ' + name + r' : List \(List Rel × Rel\) := \[(.*?)\n\]', ro_src, re.S); return m.group(1) if m else ''
chains = [tuple(parse_rel(x) for x in re.findall(r'⟨[^⟩]*⟩', ln)) for ln in block('chains').split('\n') if ln.strip().startswith('(')]
chains = [c for c in chains if len(c) == 3]
transitive = {parse_rel(x) for x in re.findall(r'⟨[^⟩]*⟩', re.search(r'def transitive : List Rel := \[(.*?)\]', ro_src, re.S).group(1))} | {ISA}
inverses = [tuple(parse_rel(x) for x in re.findall(r'⟨[^⟩]*⟩', ln)) for ln in re.search(r'def inverses : List \(Rel × Rel\) := \[(.*?)\n\]', ro_src, re.S).group(1).split('\n') if ln.strip().startswith('(')]
inv_map = collections.defaultdict(set)
for a, b in inverses: inv_map[a].add(b); inv_map[b].add(a)
chain_index = collections.defaultdict(list)   # r1 -> [(r2, r3)]
for r1, r2, r3 in chains: chain_index[r1].append((r2, r3))

# --- load facts
R_TB = F(4, 5)
facts = {}      # key -> dict(kind, args, depth, belief, deriv)
labels_e = {}
def add(key, deriv, depth, belief, src_id=None):
    if key in facts and facts[key]['depth'] <= depth: return False
    facts[key] = dict(depth=depth, belief=belief, deriv=deriv, src=src_id); return True
skip = {l.split('\t')[0] for l in open('data/textbook/r2_skip.tsv') if l.strip() and not l.startswith('#')}
n_stmt = 0; sid_of = {}
m3_facts, m3_quantified = {}, set()   # round 3: record id -> (key, statement); ids marked some/most
if M3:
    import emit_lean_m3
    m3_stmts, _, m3_recs = emit_lean_m3.statements(str(pathlib.Path(src).with_name('claims_m3')), go_ns)
    m3_quantified = {r['id'] for r in m3_recs if r['m3'].get('quant') in ('some', 'most')}
    for s in m3_stmts:
        if s['quant']: continue
        if s['ctor'] in ('rel', 'notRel'): m3_facts[s['id']] = ((s['ctor'], s['rel'], s['subj'][0], s['obj'][0]), s)
        elif s['ctor'] == 'effect': m3_facts[s['id']] = (('effect', s['sign'], s['target'], s['subj'][0], s['obj'][0]), s)
superseded = 0
for p in sorted(glob.glob(f'{src}/*.json')):
    for r in json.load(open(p)):
        m = r.get('m2')
        if r.get('bin') == 'not_claim' or not m or m.get('ctor') in (None, 'none') or m.get('blocker') == 'context_required' or r['id'] in skip: continue
        s_, o_ = m.get('subject'), m.get('object')
        if not (s_ and o_) or kind_of(s_) is None or kind_of(o_) is None: continue
        for e in r.get('entities', []):
            if e.get('curie'): labels_e.setdefault(e['curie'], e.get('text'))
        for ch in m.get('curie_changes') or []:
            if ch.get('to'): labels_e.setdefault(ch['to'], ch.get('text'))
        if m['ctor'] in ('rel', 'notRel'):
            rr = rel_of(m.get('relation'))
            if not rr: continue
            key = (m['ctor'], rr, s_, o_)
        else:
            if m['ctor'] == 'mediatedBy': continue   # no Lean rule forgets a mediator yet; keep the search honest
            if m.get('sign') not in ('pos', 'neg') or m.get('target') not in ('activity', 'amount', 'process', 'phenotype', 'site'): continue
            key = ('effect', m['sign'], m['target'], s_, o_)
        if r['id'] in m3_facts or r['id'] in m3_quantified: superseded += 1; continue
        if add(key, ('lit', r['id']), 0, R_TB, r['id']): n_stmt += 1; sid_of[key] = r['id']
n_m2 = n_stmt
for sid, (key, s) in m3_facts.items():
    for c, (_, l) in s['ents'].items(): labels_e.setdefault(c, l)
    for c, l in (s['subj'], s['obj']): labels_e.setdefault(c, l)
    if add(key, ('lit', sid), 0, R_TB, sid): n_stmt += 1; sid_of[key] = sid
asserted = set(facts)
if M3: print(f'm2 statements {n_m2} (superseded by round 3: {superseded}), round 3 statements {n_stmt - n_m2} of {len(m3_facts)} rel/notRel/effect (unquantified; {len(m3_quantified)} records some/most)')
print(f'statements loaded: {n_stmt}  (rel {sum(1 for k in facts if k[0]=="rel")}, notRel {sum(1 for k in facts if k[0]=="notRel")}, effect {sum(1 for k in facts if k[0]=="effect")})')
def unrefine(c):
    """`e` from the curie of `e.refine r f` ("X&R=(F)", the last top-level '&'), or None if c is not refined."""
    d = 0
    for i in range(len(c) - 1, -1, -1):
        if c[i] in '()': d += 1 if c[i] == ')' else -1
        elif c[i] == '&' and d == 0: return c[:i]
axioms = set()   # Entity.refineAxiom edges: definitional, not textbook statements
if not LEGACY:
    todo, seen = [c for k in facts for c in ((k[3], k[4]) if k[0] == 'effect' else (k[2], k[3]))], set()
    while todo:
        c = todo.pop(); b = unrefine(c)
        if b is None or c in seen: continue
        seen.add(c); todo.append(b)   # a nested context refines a refined entity: drop one refinement at a time
        if add(('rel', ISA, c, b), ('refineAxiom', f'refine:{c}'), 0, F(999, 1000)): axioms.add(('rel', ISA, c, b))
    print(f'refinement axioms loaded: {len(axioms)} (e ⊓ ∃r.f is_a e, belief 999/1000)')

# --- forward chaining, semi-naive by depth
SIGN = {('pos', 'pos'): 'pos', ('neg', 'neg'): 'pos', ('pos', 'neg'): 'neg', ('neg', 'pos'): 'neg'}
rule_count = collections.Counter()
def rels_from(a):  # rel facts with subject a
    return [k for k in idx_subj.get(a, ())]
for depth in range(1, MAXD + 1):
    idx_subj = collections.defaultdict(list); idx_obj = collections.defaultdict(list); idx_rel_subj = collections.defaultdict(list); eff_by_subj = collections.defaultdict(list); isa_sub = collections.defaultdict(list); isa_sup = collections.defaultdict(list); notrel_subj = collections.defaultdict(list)
    for k in facts:
        if k[0] == 'rel':
            idx_subj[k[2]].append(k); idx_obj[k[3]].append(k); idx_rel_subj[(k[1], k[2])].append(k)
            if k[1] == ISA: isa_sub[k[3]].append(k); isa_sup[k[2]].append(k)
        elif k[0] == 'effect': eff_by_subj[k[3]].append(k)
        elif k[0] == 'notRel': notrel_subj[k[2]].append(k)
    new = []
    snapshot = list(facts.items())
    for k, v in snapshot:
        if v['depth'] != depth - 1: continue   # semi-naive: only extend facts new at the last depth
        if k[0] == 'rel':
            _, r1, a, b = k
            # inverses
            # NO inverse rule: textbook claims are class-level existentials ('every a has some b'), and
            # inverting an existential is unsound. Inverse-direction facts must be asserted directly.
            # chains r1 o r2 -> r3  (k as first premise)
            for r2, r3 in chain_index.get(r1, []):
                for k2 in idx_rel_subj.get((r2, b), []):
                    new.append((('rel', r3, a, k2[3]), ('relChain', k, k2, lab(r3)), min(v['belief'], facts[k2]['belief'])))
            # k as second premise
            for k1 in idx_obj.get(a, []):
                for r2, r3 in chain_index.get(k1[1], []):
                    if r2 == r1: new.append((('rel', r3, k1[2], b), ('relChain', k1, k, lab(r3)), min(v['belief'], facts[k1]['belief'])))
            # transitivity
            if r1 in transitive:
                for k2 in idx_rel_subj.get((r1, b), []): new.append((('rel', r1, a, k2[3]), ('relTrans', k, k2), min(v['belief'], facts[k2]['belief'])))
                for k1 in idx_obj.get(a, []):
                    if k1[1] == r1: new.append((('rel', r1, k1[2], b), ('relTrans', k1, k), min(v['belief'], facts[k1]['belief'])))
            # is_a laws: a is_a b, b r c  =>  a r c ;  a r b, b is_a c => a r c
            if r1 == ISA:
                for k2 in idx_subj.get(b, []):
                    if k2[1] not in (ISA, flip(ISA)): new.append((('rel', k2[1], a, k2[3]), ('isaInherit', k, k2), min(v['belief'], facts[k2]['belief'])))
                for k2 in notrel_subj.get(b, []): new.append((('notRel', k2[1], a, k2[3]), ('notRelSub', k, k2), min(v['belief'], facts[k2]['belief'])))
                for k2 in eff_by_subj.get(b, []): new.append((('effect', k2[1], k2[2], a, k2[4]), ('isaInheritEffect', k, k2), min(v['belief'], facts[k2]['belief'])))
            if r1 not in (ISA, flip(ISA)):
                for k2 in isa_sup.get(b, []): new.append((('rel', r1, a, k2[3]), ('isaGeneralise', k, k2), min(v['belief'], facts[k2]['belief'])))
        elif k[0] == 'effect':
            _, s1, t1, a, m = k
            if t1 in ('amount', 'activity'):
                for k2 in eff_by_subj.get(m, []):
                    new.append((('effect', SIGN[(s1, k2[1])], k2[2], a, k2[4]), ('viaAmount' if t1 == 'amount' else 'viaActivity', k, k2), v['belief'] * facts[k2]['belief']))
    added = 0
    for key, deriv, bel in new:
        if key[2 if key[0] != 'effect' else 3] == key[-1]: continue   # drop reflexive a r a
        if add(key, deriv, depth, bel): added += 1; rule_count[deriv[0]] += 1
    print(f'depth {depth}: +{added} facts (total {len(facts)})')
    if not added: break

# --- report
novel = {k: v for k, v in facts.items() if k not in asserted and k not in axioms}
def show(k):
    if k[0] == 'effect': return f"{labels_e.get(k[3], k[3])} [{k[3]}] →{'+' if k[1]=='pos' else '−'} {k[2]}({labels_e.get(k[4], k[4])} [{k[4]}])"
    return f"{'¬' if k[0]=='notRel' else ''}{labels_e.get(k[2], k[2])} [{k[2]}] {lab(k[1])} {labels_e.get(k[3], k[3])} [{k[3]}]"
def tree(k, ind=''):
    v = facts[k]; d = v['deriv']
    if d[0] in ('lit', 'refineAxiom'): return f"{ind}{show(k)}   [{d[1]}]"
    prem = [x for x in d[1:] if isinstance(x, tuple)]
    return f"{ind}{show(k)}   ({d[0]}, b={float(v['belief']):.2f})\n" + "\n".join(tree(p, ind + '  ') for p in prem)
clashes = [k for k in facts if k[0] == 'rel' and ('notRel', k[1], k[2], k[3]) in facts]
print(f"\nasserted {len(asserted)}, derived novel {len(novel)}; by rule {dict(rule_count)}")
print(f"clashes (rel and notRel both derived): {len(clashes)}")
for k in clashes[:5]: print(tree(k)); print(tree(('notRel',) + k[1:])); print()
by_depth = collections.Counter(v['depth'] for v in novel.values()); print('novel by depth', dict(sorted(by_depth.items())))

# --- guards on effect chains: each one flags a derived effect fact, none drops it (docs/closure-search.md, phase 4)
flags = {}   # derived effect fact -> {flag: the fact that raised it}
if not LEGACY:
    PARTS = (by_label['part of'], by_label['has part'])
    parthood, eff_out, direct = {}, collections.defaultdict(dict), collections.defaultdict(dict)
    for k in asserted:
        if k[0] == 'rel' and k[1] in PARTS: parthood.setdefault((k[2], k[3]), k); parthood.setdefault((k[3], k[2]), k)
    for k in facts:
        if k[0] == 'effect':
            eff_out[k[3]].setdefault(k[4], k)                     # y -> {z: y → z}, asserted or derived
            if k in asserted: direct[k[3]].setdefault(k[4], k)    # a -> {t: a → t}, stated directly
    def chain(k):
        """The nodes an effect's chain passes through, in order; its asserted effect premises, each with the position of
        its subject among the nodes; and its steps (a → m, m → t). An inherited effect puts the subclass before the class."""
        d = facts[k]['deriv']
        if d[0] in ('viaAmount', 'viaActivity'):
            (n1, p1, s1), (n2, p2, s2) = chain(d[1]), chain(d[2])
            return n1 + n2[1:], p1 + [(i + len(n1) - 1, e) for i, e in p2], s1 + s2 + [(d[1], d[2])]
        if d[0] == 'isaInheritEffect':
            n2, p2, s2 = chain(d[2]); return [k[3]] + n2, [(i + 1, e) for i, e in p2], s2
        return [k[3], k[4]], [(0, k)], []
    def guards(k):
        nodes, prem, steps = chain(k); f = {}
        for i, (_, _, _, x, y) in prem:
            back = [z for z in nodes[:i + 1] if z in eff_out[y]]
            if back and len(prem) > 1:
                f.setdefault('feedback', eff_out[y][back[0]])   # y acts back on x or upstream; one inherited statement is not a chain
                f.setdefault('loop', tuple(sorted((y.split('&')[0], back[0].split('&')[0]))))   # the loop, named by the pair of base terms it joins
            if (x, y) in parthood: f.setdefault('parthood', parthood[(x, y)])   # a part acting on its whole, or the reverse
        for (_, _, _, a, m), (_, _, _, _, t) in steps:
            if m in direct[a] and t in direct[a]: f.setdefault('shared_cause', direct[a][t])   # a → m and a → t both stated
        return f
    flags = {k: guards(k) for k in novel if k[0] == 'effect'}
    by_flag = collections.Counter(g for f in flags.values() for g in f if g != 'loop')
    by_loop = collections.Counter(f['loop'] for f in flags.values() if 'loop' in f)
    chained = [k for k in flags if facts[k]['deriv'][0] in ('viaAmount', 'viaActivity')]
    print(f"\n=== guards on effect chains (flags; nothing is dropped) ===\nderived effect facts {len(flags)}, flagged {sum(map(bool, flags.values()))}; "
          f"chain conclusions (viaAmount, viaActivity) {len(chained)}, flagged {sum(bool(flags[k]) for k in chained)}")
    print('by flag', dict(by_flag), '; by combination', dict(collections.Counter('+'.join(sorted(g for g in f if g != 'loop')) or 'none' for f in flags.values()).most_common()))
    print('named loops (chains crossing each):', '; '.join(f"{labels_e.get(a, a)} / {labels_e.get(b, b)} {n}" for (a, b), n in by_loop.most_common()))
    opp = [(k, ('effect', 'neg') + k[2:]) for k in facts if k[0] == 'effect' and k[1] == 'pos' and ('effect', 'neg') + k[2:] in facts]
    print(f"sign clashes (a →+ t and a →− t both in the closure): {len(opp)}; with a flagged side {sum(any(flags.get(x) for x in p) for p in opp)}")
    for g in ('feedback', 'parthood', 'shared_cause'):
        ex = sorted((k for k in flags if g in flags[k]), key=lambda k: (facts[k]['depth'], str(k)))
        print(f"\n--- {g}: {len(ex)} (first five, shallowest) ---")
        for k in ex[:5]: print(tree(k)); print(f"  {g} because: {show(flags[k][g])}"); print()
# --- statements flagged false as written (data/textbook/false_as_written.tsv): what rests on each?
flag_file = pathlib.Path('data/textbook/false_as_written.tsv')
if flag_file.exists() and not LEGACY:
    rows = [l.split('\t') for l in flag_file.read_text().splitlines() if l.strip() and not l.startswith('#')]
    bad = {f[0]: f[1] for f in rows if len(f) < 6 or not f[5]}   # rows with an m3_edit are corrected in round 3 (apply_false_as_written.py)
    def uses(k): return {x for x in re.findall(r'\[([a-z0-9-]+-m\d+-\d+[a-z]?)\]', tree(k))}
    rest = collections.Counter(); on_any = 0
    for k in novel:
        hit = uses(k) & set(bad)
        on_any += bool(hit)
        for b in hit: rest[b] += 1
    print(f"\n=== statements flagged false as written: {len(rows)}, corrected {len(rows) - len(bad)}, open {len(bad)}; derived facts resting on at least one: {on_any} of {len(novel)} ===")
    for b, n in rest.most_common(): print(f"  {n:4d}  {b}  ({bad[b]})")
json.dump({'asserted': len(asserted), 'novel': len(novel), 'rules': dict(rule_count),
           **({'refine_axioms': len(axioms), 'clashes': len(clashes), 'sign_clashes': len(opp), 'flags': dict(by_flag)} if not LEGACY else {}),
           'facts': [{'fact': show(k), 'key': [str(x) for x in k], 'depth': v['depth'], 'belief': float(v['belief']), 'rule': v['deriv'][0], 'tree': tree(k),
                      **({'flags': sorted(flags[k])} if k in flags else {})} for k, v in novel.items()]},
          open('data/search/closure.json', 'w'), indent=0)
# samples: deepest non-inverse novel facts
deep = sorted([k for k, v in novel.items() if v['deriv'][0] not in ('relInv',)], key=lambda k: -facts[k]['depth'])
print('\n=== deepest novel facts (excluding plain inverses) ===')
for k in deep[:12]: print(tree(k)); print()

# --- interestingness: drop inverses, drop lifts to generic hubs, prefer depth >= 2
indeg = collections.Counter(k[-1] for k in asserted); outdeg = collections.Counter(k[2] if k[0] != 'effect' else k[3] for k in asserted)
hubs = {c for c, n in (indeg + outdeg).most_common(25)}
def is_inverse_only(k):
    v = facts[k]; d = v['deriv']
    while d[0] == 'relInv':
        k = d[1]; d = facts[k]['deriv']
    return k in asserted
def interesting(k):
    v = facts[k]
    if v['deriv'][0] == 'relInv' and is_inverse_only(k): return False
    obj = k[-1]; subj = k[2] if k[0] != 'effect' else k[3]
    if obj in hubs or subj in hubs: return False
    return True
inter = [k for k in novel if interesting(k)]
print(f"\nhubs excluded: {[labels_e.get(h, h) for h in list(hubs)[:12]]} ...")
print(f"novel facts after dropping inverses-of-asserted and hub lifts: {len(inter)}; by rule {dict(collections.Counter(facts[k]['deriv'][0] for k in inter))}")
# --- IC (the default filter): score = min IC over subject and object; a conclusion about "cell" or "organism" scores near 0.
# Scored only when both ends have an IC (GO, UBERON, CL, ChEBI); one scored end gives an upper bound, enough to call a fact trivial.
if not HUBS:
    ic_tab = json.load(open('data/search/ic.json'))['terms']; ic = {c: v['ic'] for c, v in ic_tab.items() if 'ic' in v}
    ends = lambda k: (k[3], k[4]) if k[0] == 'effect' else (k[2], k[3])
    ic.update({c: ic[c.split('&')[0]] for k in facts for c in ends(k) if c.split('&')[0] in ic})   # refined: base IC, a lower bound
    bound = lambda k: min((ic[c] for c in ends(k) if c in ic), default=None)
    score = lambda k: bound(k) if all(c in ic for c in ends(k)) else None
    name = lambda c: labels_e.get(c) or (ic_tab.get(c) or {}).get('name') or c
    def used(k): return set(ends(k)).union(*[used(p) for p in facts[k]['deriv'][1:] if isinstance(p, tuple)])   # every entity in the derivation
    pathmin = lambda k: min((ic[c] for c in used(k) if c in ic), default=None)   # bottleneck: the most generic entity the proof passes through
    def hist(keys):
        sc = sorted(x for x in map(score, keys) if x is not None); n = len(keys); part = sum(1 for k in keys if score(k) is None and bound(k) is not None)
        return ' '.join(f"{sum(1 for x in sc if min(int(x), 9) == b):5d}" for b in range(10)) + f" {part:5d} {n - len(sc) - part:5d} {n:5d}   median {sc[len(sc)//2]:.2f}  mean {sum(sc)/len(sc):.2f}"
    print(f"\n=== information content (threshold {IC_T}) ===\nmin-IC bin:      " + ' '.join(f"{b:>5}" for b in ['<1', '<2', '<3', '<4', '<5', '<6', '<7', '<8', '<9', '9+', '1 end', 'none']) + '   all')
    print('asserted        ', hist(list(asserted))); print('derived (novel) ', hist(list(novel)))
    fmt = lambda k: f"{score(k):5.2f}  d{facts[k]['depth']} {facts[k]['deriv'][0]:<16} {show(k)}"
    scored = sorted((k for k in novel if score(k) is not None), key=lambda k: (-score(k), -facts[k]['depth'], str(k)))
    print('\n--- top 25 derived by min IC (non-trivial) ---'); [print(fmt(k)) for k in scored[:25]]
    print('\n--- bottom 15 derived by min IC (trivial) ---'); [print(fmt(k)) for k in scored[-15:]]
    inter_hub = set(inter); kept = [k for k in scored if score(k) >= IC_T]; ics = set(kept)
    low = lambda k: bound(k) is not None and bound(k) < IC_T; unjudged = lambda k: not low(k) and score(k) is None
    print(f"\nIC >= {IC_T} keeps {len(kept)} of {len(novel)}; trivial (<{IC_T}) {sum(low(k) for k in novel)}; unjudged (an end has no IC, bound >= {IC_T}) {sum(unjudged(k) for k in novel)}")
    print(f"of the {len(kept)} ends-min keepers, {sum(1 for k in kept if pathmin(k) >= IC_T)} also pass on the derivation bottleneck (min IC over every entity in the proof)")
    print(f"hub list keeps {len(inter_hub)}: of those IC-trivial {sum(low(k) for k in inter_hub)}, IC-kept {len(inter_hub & ics)}, unjudged {sum(unjudged(k) for k in inter_hub)}")
    print(f"hub list removes {len(novel) - len(inter_hub)}: of those IC-kept {len(ics - inter_hub)}, IC-trivial {sum(low(k) for k in novel if k not in inter_hub)}, unjudged {sum(unjudged(k) for k in novel if k not in inter_hub)}")
    print(f"hub terms with IC >= {IC_T}: {sum(1 for h in hubs if ic.get(h, 0) >= IC_T)} of {len(hubs)}; with no IC: {sum(1 for h in hubs if h not in ic)}")
    print('hub terms (degree, IC):', ', '.join(f"{name(h)} ({(indeg + outdeg)[h]}, {ic[h]:.1f})" if h in ic else f"{name(h)} ({(indeg + outdeg)[h]}, -)" for h in sorted(hubs, key=lambda h: (-(indeg + outdeg)[h], h))))
    json.dump({'threshold': IC_T, 'facts': [{'fact': show(k), 'score': round(score(k), 3), 'path_min': round(pathmin(k), 3), 'depth': facts[k]['depth'], 'rule': facts[k]['deriv'][0], 'hub_survivor': k in inter_hub, **({'flags': sorted(flags[k])} if k in flags else {})} for k in scored]}, open('data/search/closure_ic.json', 'w'), indent=0)
    inter = kept
import random; random.seed(7)
sample = random.sample(inter, min(15, len(inter)))
print("\n=== random sample of interesting novel facts ===")
for k in sample: print(tree(k)); print()

# --- structured dump for Lean emission
def deriv_struct(k):
    v = facts[k]; d = v['deriv']
    if d[0] in ('lit', 'refineAxiom'): return {'rule': d[0], 'sid': d[1]}
    prem = [deriv_struct(x) for x in d[1:] if isinstance(x, tuple)]
    out = {'rule': d[0], 'premises': prem, 'fact': show(k), 'key': [list(x) if isinstance(x, tuple) else x for x in k]}
    if d[0] == 'relInv': out['to_rel'] = list(k[1])
    return out
json.dump([deriv_struct(k) for k in sorted(inter, key=(lambda k: (facts[k]['depth'], str(k))) if HUBS else (lambda k: (-score(k), str(k))))[:400]], open('data/search/derivations.json' if HUBS else 'data/search/derivations_ic.json', 'w'), indent=0)

# --- path query: Dan's question, "cancer is a disease of energy metabolism"
G = collections.defaultdict(list)
for k in asserted:
    s_, o_ = (k[2], k[3]) if k[0] != 'effect' else (k[3], k[4])
    G[s_].append((o_, show(k))); G[o_].append((s_, show(k)))
def nodes_matching(pat): return [c for c, l in labels_e.items() if l and re.search(pat, l, re.I)] + [c for c in G if re.search(pat, c)]
def bfs(srcs, tgts, maxlen=6):
    tg = set(tgts); seen = {s: None for s in srcs}; q = collections.deque(srcs); paths = []
    while q and len(paths) < 5:
        n = q.popleft()
        if n in tg and seen[n] is not None:
            p = []; x = n
            while seen[x]: x, lbl = seen[x]; p.append(lbl)
            paths.append(list(reversed(p))); continue
        for m, lbl in G.get(n, []):
            if m not in seen and len(seen) < 200000: seen[m] = (n, lbl); q.append(m)
    return paths
cancer = [c for c in nodes_matching(r'cancer|tumor|tumour|carcinoma|neoplasm') if c in G]
energy = [c for c in nodes_matching(r'^(cellular respiration|glycolysis|glycolytic|ATP|energy|oxidative phosphorylation|metabolic|catabolism|TCA|citric)') if c in G]
print(f"\n=== path query: cancer nodes {len(cancer)} -> energy-metabolism nodes {len(energy)} ===")
for p in bfs(cancer, energy): print(' -> '.join(p)); print()
