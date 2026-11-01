"""Program 02b copy of scripts/search/closure.py: the same closure, plus asserted loops (docs/programs/02b-feedback-loops.md).

Every output goes to data/stress/02b/<--out> (default closure_base); data/search is never written. With no 02b flag the
closure is byte for byte the original's (checked by diffing the printed reports). The 02b flags:
  --proposal=DIR  overlay the round-3 proposal records in DIR (claims_m3 format, data/stress/02b/proposal_m3): a record
                  with the id of an m2 or m3 record supersedes it; new ids (~loop, #2) are added. Homeostasis records
                  load no fact (no rule uses them); they are the asserted loops.
  --loops         read derived effects against the asserted loops. Core loops: one per Claim.homeostasis record, nodes
                  = {regulator, held} by base curie. A chain whose effect premises include an arm (both ends nodes of a
                  loop) crosses that loop and is labelled with it. A chain whose base-curie path revisits a node, every
                  revisited node in a loop it crosses, is that loop going round: it is reported as the loop, not as an
                  effect ("x lowers x" through a negative loop, and the sign clashes made by winding round it).
  --signed        use the proposal's loop blocks instead (sign, several regulators, extra nodes such as an effector
                  process): positive loops become assertable and two-regulator loops are one loop.
  --complete      also extend a new effect fact as the SECOND premise of viaAmount/viaActivity. The original extends it
                  only as the first, so a chain whose second link is derived at a later depth is never formed
                  (adrenaline raises blood glucose, blood glucose raises insulin by the refinement edge: missed).
  --complete-isa  also use a new effect fact as the effect premise of isaInheritEffect. The original fires that rule only
                  from a new is_a fact, so an effect derived at depth d is never inherited by the subclasses of its agent.
  --strict        a chain is a round trip of loop L only if every node from its first to its last revisited node is a
                  node of L (the default asks this of the revisited nodes only, which lets a negative brake that
                  shares a node with a positive loop pass as that loop: case P03 in BioLean/Proto/Feedback.lean).
  --light         do not write closure.json, closure_ic.json or derivations_ic.json (the report and loops.json are kept)
  --expect=FILE   compare the readings of named facts with FILE (JSON) and exit 1 on a difference: the closure pins.
Exactly reflexive derived effects (a → a) are still dropped as in the original; in --loops mode they are also read and
reported, because "depolarisation raises depolarisation" is the loop itself.

Original docstring follows.
Forward-chain over the compiled textbook statements with BioLean's rules and report what follows.

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
OUT = next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--out=')), 'data/stress/02b/closure_base')   # program 02b: never data/search
assert pathlib.Path(OUT).resolve().is_relative_to(pathlib.Path('data/stress/02b').resolve()), 'outputs must stay in data/stress/02b'
pathlib.Path(OUT).mkdir(parents=True, exist_ok=True)
PROPOSAL = next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--proposal=')), None)
LOOPS, SIGNED = '--loops' in sys.argv, '--signed' in sys.argv
STRICT = '--strict' in sys.argv   # 02b: a round trip needs every node on its cycle (first to last revisit) in the loop, not just the revisited ones
LIGHT = '--light' in sys.argv   # 02b: skip the three large JSON dumps (closure, closure_ic, derivations); the printed report is unchanged
COMPLETE = '--complete' in sys.argv   # 02b: also extend a new effect fact as the second premise (the original only extends it as the first)
COMPLETE_ISA = '--complete-isa' in sys.argv   # 02b: also use a new effect fact as the effect premise of isaInheritEffect (the original only fires the rule from a new is_a fact)
EXPECT = next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--expect=')), None)
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
prop_ids, prop_recs = set(), []   # 02b: the proposal overlay
if PROPOSAL:
    prop_recs = [r for p in sorted(glob.glob(f'{PROPOSAL}/*.json')) for r in json.load(open(p))]
    prop_ids = {r['id'] for r in prop_recs}
    for i in prop_ids: m3_facts.pop(i, None)
    m3_quantified -= prop_ids
    p_stmts, p_skipped, _ = emit_lean_m3.statements(PROPOSAL, go_ns)
    for s in p_stmts:
        if s['quant']: continue
        if s['ctor'] in ('rel', 'notRel'): m3_facts[s['id']] = ((s['ctor'], s['rel'], s['subj'][0], s['obj'][0]), s)
        elif s['ctor'] == 'effect': m3_facts[s['id']] = (('effect', s['sign'], s['target'], s['subj'][0], s['obj'][0]), s)
    print(f'proposal overlay: {len(prop_recs)} records, {sum(1 for s in p_stmts if s["ctor"] in ("rel", "notRel", "effect"))} load a fact; not loaded: {dict(p_skipped)}')
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
        if r['id'] in m3_facts or r['id'] in m3_quantified or r['id'] in prop_ids: superseded += 1; continue
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
reflexive = {}   # 02b: exactly reflexive derived effects, dropped as in the original
def rels_from(a):  # rel facts with subject a
    return [k for k in idx_subj.get(a, ())]
for depth in range(1, MAXD + 1):
    idx_subj = collections.defaultdict(list); idx_obj = collections.defaultdict(list); idx_rel_subj = collections.defaultdict(list); eff_by_subj = collections.defaultdict(list); eff_by_obj = collections.defaultdict(list); isa_sub = collections.defaultdict(list); isa_sup = collections.defaultdict(list); notrel_subj = collections.defaultdict(list)
    for k in facts:
        if k[0] == 'rel':
            idx_subj[k[2]].append(k); idx_obj[k[3]].append(k); idx_rel_subj[(k[1], k[2])].append(k)
            if k[1] == ISA: isa_sub[k[3]].append(k); isa_sup[k[2]].append(k)
        elif k[0] == 'effect':
            eff_by_subj[k[3]].append(k)
            if k[2] in ('amount', 'activity'): eff_by_obj[k[4]].append(k)
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
            if COMPLETE:   # k as the second premise: k1 = x → amount/activity(a), then k
                for k1 in eff_by_obj.get(a, []):
                    new.append((('effect', SIGN[(k1[1], s1)], t1, k1[3], m), ('viaAmount' if k1[2] == 'amount' else 'viaActivity', k1, k), facts[k1]['belief'] * v['belief']))
            if COMPLETE_ISA:   # k as the effect premise of isaInheritEffect: x is_a a (old or new), a → t  =>  x → t
                for k1 in isa_sub.get(a, []):
                    new.append((('effect', s1, t1, k1[2], m), ('isaInheritEffect', k1, k), min(facts[k1]['belief'], v['belief'])))
    added = 0
    for key, deriv, bel in new:
        if key[2 if key[0] != 'effect' else 3] == key[-1]:   # drop reflexive a r a
            if key[0] == 'effect': reflexive.setdefault(key, deriv)   # 02b: kept aside, read in --loops mode
            continue
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
    def chain(k, d=None):
        """The nodes an effect's chain passes through, in order; its asserted effect premises, each with the position of
        its subject among the nodes; and its steps (a → m, m → t). An inherited effect puts the subclass before the class."""
        d = d or facts[k]['deriv']
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
# --- 02b: read derived effects against the asserted loops
readings, loop_report = {}, {}
if LOOPS and not LEGACY:
    base = lambda c: c.split('&')[0]
    groups = {}   # frozenset of nodes -> loop
    for r in prop_recs:
        m, lp = r.get('m3') or {}, r.get('loop')
        if SIGNED and lp: nodes, sign = {lp['held'], *(g[0] for g in lp['regulators']), *lp.get('extra_nodes', [])}, lp['sign']
        elif not SIGNED and m.get('ctor') == 'homeostasis': nodes, sign = {base(m['subject']), base(m['object'])}, 'neg'
        else: continue
        L = groups.setdefault(frozenset(nodes), {'id': r['id'], 'nodes': frozenset(nodes), 'sign': sign, 'records': []}); L['records'].append(r['id'])
    loops = list(groups.values())
    def bpath(nodes):
        out = []
        for n in nodes:
            if not out or out[-1] != base(n): out.append(base(n))
        return out
    def reading(k, d=None):
        nodes, prem, _ = chain(k, d)
        p = bpath(nodes)
        arms = [(base(e[3]), base(e[4])) for _, e in prem]
        crossed = [L for L in loops if any(a != b and a in L['nodes'] and b in L['nodes'] for a, b in arms)]
        dup = {n for n in p if p.count(n) > 1}
        if dup:
            idx = [i for i, n in enumerate(p) if n in dup]
            need = set(p[min(idx):max(idx) + 1]) if STRICT else dup   # strict: the whole cycle, not only the revisited nodes
            for L in crossed:
                if need <= L['nodes']: return ('roundTrip', L['id'])
            return ('cycle', None)
        return ('crosses', tuple(sorted(L['id'] for L in crossed))) if crossed else ('plain', None)
    readings = {k: reading(k) for k in flags}
    refl = {k: reading(k, d) for k, d in reflexive.items()}
    kinds = collections.Counter(r[0] for r in readings.values())
    print(f"\n=== 02b loops ({'signed loop blocks' if SIGNED else 'core homeostasis claims'}): {len(loops)} asserted loops from {sum(len(L['records']) for L in loops)} records ===")
    for L in sorted(loops, key=lambda L: L['id']): print(f"  {L['id']}: {L['sign']} {sorted(L['nodes'])} ({len(L['records'])} records)")
    print(f"derived effect facts {len(readings)}: {dict(kinds)}")
    fb = [k for k in flags if 'feedback' in flags[k]]
    print(f"of the {len(fb)} feedback-flagged: {dict(collections.Counter(readings[k][0] for k in fb))}; not flagged but labelled: {sum(1 for k in readings if k not in fb and readings[k][0] != 'plain')}")
    by_rt = collections.Counter(r[1] for r in readings.values() if r[0] == 'roundTrip')
    by_cross = collections.Counter(i for r in readings.values() if r[0] == 'crosses' for i in r[1])
    print('round trips reported as the loop:', dict(by_rt.most_common()))
    print('chains labelled as crossing a loop (kept as effects):', dict(by_cross.most_common()))
    expl = [pr for pr in opp if any(readings.get(x, ('',))[0] == 'roundTrip' for x in pr)]
    print(f"sign clashes {len(opp)}: a side is a round trip (reported as the loop) {len(expl)}; left {len(opp) - len(expl)}")
    # 02b review: 'explained' only means one side is reported as the loop; the other side stays an effect, and it can be the
    # wrong one (C09 kept, C11 hidden). How the kept side is read: asserted (a book statement), plain, crosses, or both round trips.
    def kept(pr):
        rs = [readings.get(x, ('asserted',))[0] for x in pr]
        return 'both round trips' if rs == ['roundTrip', 'roundTrip'] else next(r for r in rs if r != 'roundTrip')
    kept_by = collections.Counter(kept(pr) for pr in expl)
    print(f"explained clashes, the side kept as an effect: {dict(kept_by.most_common())}")
    for pr in opp:
        if pr not in expl: print('   left:', show(pr[0]), '|', readings.get(pr[0]), '/', readings.get(pr[1]))
    print(f"exactly reflexive derived effects (dropped by the original): {len(refl)}; read as: {dict(collections.Counter(r[0] for r in refl.values()))}")
    for k, r in sorted(refl.items(), key=lambda kv: show(kv[0])): print(f"   {show(k)}  ->  {r}")
    print("cycles left (no asserted loop covers them):")
    for k in sorted((k for k, r in readings.items() if r[0] == 'cycle'), key=lambda k: (facts[k]['depth'], show(k)))[:12]: print('   ', show(k))
    loop_report = {'loops': [{'id': L['id'], 'sign': L['sign'], 'nodes': sorted(L['nodes']), 'records': L['records']} for L in loops],
                   'readings': dict(kinds), 'round_trips': dict(by_rt), 'crossings': dict(by_cross), 'sign_clashes': len(opp),
                   'sign_clashes_explained': len(expl), 'explained_kept_side': dict(kept_by),
                   'sign_clashes_left': [show(pr[0]) for pr in opp if pr not in expl], 'reflexive': {show(k): list(r) if r[1] is None or isinstance(r[1], str) else [r[0], list(r[1])] for k, r in refl.items()},
                   'facts': [{'fact': show(k), 'reading': r[0], 'loops': ([r[1]] if isinstance(r[1], str) else list(r[1] or [])), 'flags': sorted(g for g in flags[k] if g != 'loop')} for k, r in readings.items()]}
    json.dump(loop_report, open(OUT + '/loops.json', 'w'), indent=1, ensure_ascii=False)
# --- 02b pins: summary counts (any mode) and, with --loops, the readings of named facts
if EXPECT and not LEGACY:
    exp = json.load(open(EXPECT)); bad = 0
    summ = {'#derived_effects': len(flags), '#flagged': sum(1 for f in flags.values() if 'feedback' in f), '#loop_pairs': len(by_loop),
            '#sign_clashes': len(opp), '#reflexive_dropped': len(reflexive)}
    got = {}
    if LOOPS:
        got = {show(k): r for k, r in readings.items()} | {show(k): r for k, r in refl.items()}
        summ |= {'#round_trips': sum(1 for r in readings.values() if r[0] == 'roundTrip'), '#sign_clashes_explained': len(expl),
                 '#explained_kept_crosses': kept_by.get('crosses', 0)}
    for f, e in exp.items():
        if f.startswith('#'): g = summ.get(f)
        else:
            g = got.get(f); g = None if g is None else [g[0], g[1] if g[1] is None or isinstance(g[1], str) else list(g[1])]
        ok = g == e; bad += not ok
        print(f"PIN {'ok  ' if ok else 'FAIL'} {f} -> {g}" + ('' if ok else f'  (expected {e})'))
    if bad: print(f'{bad} pins failed'); sys.exit(1)
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
          open(OUT + '/closure.json', 'w'), indent=0) if not LIGHT else None
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
    json.dump({'threshold': IC_T, 'facts': [{'fact': show(k), 'score': round(score(k), 3), 'path_min': round(pathmin(k), 3), 'depth': facts[k]['depth'], 'rule': facts[k]['deriv'][0], 'hub_survivor': k in inter_hub, **({'flags': sorted(flags[k])} if k in flags else {})} for k in scored]}, open(OUT + '/closure_ic.json', 'w'), indent=0) if not LIGHT else None
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
json.dump([deriv_struct(k) for k in sorted(inter, key=(lambda k: (facts[k]['depth'], str(k))) if HUBS else (lambda k: (-score(k), str(k))))[:400]], open(OUT + ('/derivations.json' if HUBS else '/derivations_ic.json'), 'w'), indent=0) if not LIGHT else None

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
