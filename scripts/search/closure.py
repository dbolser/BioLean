"""Forward-chain over the compiled textbook statements with BioLean's rules and report what follows.

Facts:   rel(r, a, b) / notRel(r, a, b) / effect(a, sign, target, b)
Rules:   RO chains (enabled), transitivity, is_a laws, inverses, viaAmount, viaActivity, notRelSub/Obj
Every derived fact keeps its shortest derivation (rule, premises). Belief: weakest-link for relational
steps, product for effect chains. Output: data/search/closure.json and a printed summary.
Usage: closure.py <claims_m2_dir> <go.obo> [max_depth] [--ic[=T]]
--ic ranks and filters by information content instead of the hub list: score(fact) = min IC of its subject and
object, read from data/search/ic.json (build it with scripts/ontology/ic.py); keeps score >= T (default IC_MIN).
Writes closure_ic.json and derivations_ic.json beside the defaults, and prints the comparison with the hub list."""
import json, glob, re, sys, collections, pathlib, itertools
from fractions import Fraction as F
IC_MIN = 2.5   # suggested threshold, see docs/ic-triviality.md
IC = next((a for a in sys.argv if a.startswith('--ic')), None); IC_T = float(IC.split('=')[1]) if IC and '=' in IC else IC_MIN
args = [a for a in sys.argv[1:] if not a.startswith('--ic')]
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
    p = c.split(':')[0]; return KIND_BY_NS.get(go_ns.get(c)) if p == 'GO' else PREFIX_KIND.get(p)
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
        if add(key, ('lit', r['id']), 0, R_TB, r['id']): n_stmt += 1; sid_of[key] = r['id']
asserted = set(facts)
print(f'statements loaded: {n_stmt}  (rel {sum(1 for k in facts if k[0]=="rel")}, notRel {sum(1 for k in facts if k[0]=="notRel")}, effect {sum(1 for k in facts if k[0]=="effect")})')

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
novel = {k: v for k, v in facts.items() if k not in asserted}
def show(k):
    if k[0] == 'effect': return f"{labels_e.get(k[3], k[3])} [{k[3]}] →{'+' if k[1]=='pos' else '−'} {k[2]}({labels_e.get(k[4], k[4])} [{k[4]}])"
    return f"{'¬' if k[0]=='notRel' else ''}{labels_e.get(k[2], k[2])} [{k[2]}] {lab(k[1])} {labels_e.get(k[3], k[3])} [{k[3]}]"
def tree(k, ind=''):
    v = facts[k]; d = v['deriv']
    if d[0] == 'lit': return f"{ind}{show(k)}   [{d[1]}]"
    prem = [x for x in d[1:] if isinstance(x, tuple)]
    return f"{ind}{show(k)}   ({d[0]}, b={float(v['belief']):.2f})\n" + "\n".join(tree(p, ind + '  ') for p in prem)
clashes = [k for k in facts if k[0] == 'rel' and ('notRel', k[1], k[2], k[3]) in facts]
print(f"\nasserted {len(asserted)}, derived novel {len(novel)}; by rule {dict(rule_count)}")
print(f"clashes (rel and notRel both derived): {len(clashes)}")
for k in clashes[:5]: print(tree(k)); print(tree(('notRel',) + k[1:])); print()
by_depth = collections.Counter(v['depth'] for v in novel.values()); print('novel by depth', dict(sorted(by_depth.items())))
json.dump({'asserted': len(asserted), 'novel': len(novel), 'rules': dict(rule_count),
           'facts': [{'fact': show(k), 'key': [str(x) for x in k], 'depth': v['depth'], 'belief': float(v['belief']), 'rule': v['deriv'][0], 'tree': tree(k)} for k, v in novel.items()]},
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
# --- --ic: score = min IC over subject and object; a conclusion about "cell" or "organism" scores near 0.
# Scored only when both ends have an IC (GO, UBERON, CL, ChEBI); one scored end gives an upper bound, enough to call a fact trivial.
if IC:
    ic_tab = json.load(open('data/search/ic.json'))['terms']; ic = {c: v['ic'] for c, v in ic_tab.items() if 'ic' in v}
    ends = lambda k: (k[3], k[4]) if k[0] == 'effect' else (k[2], k[3])
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
    json.dump({'threshold': IC_T, 'facts': [{'fact': show(k), 'score': round(score(k), 3), 'path_min': round(pathmin(k), 3), 'depth': facts[k]['depth'], 'rule': facts[k]['deriv'][0], 'hub_survivor': k in inter_hub} for k in scored]}, open('data/search/closure_ic.json', 'w'), indent=0)
    inter = kept
import random; random.seed(7)
sample = random.sample(inter, min(15, len(inter)))
print("\n=== random sample of interesting novel facts ===")
for k in sample: print(tree(k)); print()

# --- structured dump for Lean emission
def deriv_struct(k):
    v = facts[k]; d = v['deriv']
    if d[0] == 'lit': return {'rule': 'lit', 'sid': d[1]}
    prem = [deriv_struct(x) for x in d[1:] if isinstance(x, tuple)]
    out = {'rule': d[0], 'premises': prem, 'fact': show(k), 'key': [list(x) if isinstance(x, tuple) else x for x in k]}
    if d[0] == 'relInv': out['to_rel'] = list(k[1])
    return out
json.dump([deriv_struct(k) for k in sorted(inter, key=(lambda k: (-score(k), str(k))) if IC else (lambda k: (facts[k]['depth'], str(k))))[:400]], open('data/search/derivations_ic.json' if IC else 'data/search/derivations.json', 'w'), indent=0)

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
