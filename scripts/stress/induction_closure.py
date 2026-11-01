"""Program 10c: BioLean's closure search, as a function, with statements held out. Writes nothing.

A copy of the loader and the forward chainer of `scripts/search/closure.py` (default mode: round 2 plus round 3,
refinement axioms on, no ontology is_a), restructured so that it can run many times in one process:
`load()` reads the textbook facts once; `chain(base, holdout, extra, maxd)` drops the facts whose source
statement is in `holdout`, adds `extra` facts, and forward-chains with the same rules and the same order of
rule application. The report section of closure.py (and all its json.dump calls) is left out on purpose.
Check: `python3 scripts/stress/induction_closure.py` compares with data/search/closure.json. Observed 2026-11-01:
novel 2223 in both, and the 2,223 derived facts are identical; asserted 1401 here against 1402 there (one statement
with no consequences; not identified), so it prints MISMATCH on the asserted count only.

Fact keys are closure.py's: ('rel', r, a, b), ('notRel', r, a, b), ('effect', sign, target, a, b), with r a
tuple (ns, num, inv) and ISA = ('rdfs', 0, False)."""
import json, glob, re, sys, collections, pathlib, os
from fractions import Fraction as F

REPO = pathlib.Path(__file__).resolve().parents[2]
GO_OBO = '/tmp/obo/go-basic.obo'      # closure.py's docs name /tmp/obo/go.obo; only GO namespaces are read
SRC = 'data/textbook/claims_m2'
ISA = ('rdfs', 0, False)
R_TB = F(4, 5)
SIGN = {('pos', 'pos'): 'pos', ('neg', 'neg'): 'pos', ('pos', 'neg'): 'neg', ('neg', 'pos'): 'neg'}
KIND_BY_NS = {'biological_process': 'process', 'molecular_function': 'function', 'cellular_component': 'component'}
PREFIX_KIND = {'CHEBI': 'chemical', 'PR': 'protein', 'UniProt': 'protein', 'UNIPROT': 'protein', 'UniProtKB': 'protein',
               'HGNC': 'gene', 'NCBIGene': 'gene', 'SO': 'gene', 'MGI': 'gene', 'HP': 'phenotype', 'MP': 'phenotype',
               'PATO': 'phenotype', 'OBA': 'phenotype', 'MONDO': 'disease', 'DOID': 'disease', 'UBERON': 'anatomy',
               'CL': 'cellType', 'NCBITaxon': 'taxon'}


def parse_rel(t):
    m = re.match(r'⟨\.(ro|bfo), (\d+), (true|false)⟩', t)
    return (m.group(1), int(m.group(2)), m.group(3) == 'true')


def flip(r): return (r[0], r[1], not r[2])


def unrefine(c):
    """`e` from the curie of `e.refine r f` ("X&R=(F)", the last top-level '&'), or None if c is not refined."""
    d = 0
    for i in range(len(c) - 1, -1, -1):
        if c[i] in '()': d += 1 if c[i] == ')' else -1
        elif c[i] == '&' and d == 0: return c[:i]


def load():
    """Read RO data and the textbook facts exactly as closure.py does (default flags). Returns a dict `base`."""
    cwd = os.getcwd(); os.chdir(REPO)
    try:
        go_ns = {}; cur = None
        for line in open(GO_OBO, encoding='utf-8'):
            if line.startswith('id: GO:'): cur = line[4:].strip()
            elif cur and line.startswith('namespace: '): go_ns[cur] = line[11:].strip(); cur = None

        def kind_of(c):
            if not c: return None
            p = c.split(':')[0]
            return KIND_BY_NS.get(go_ns.get(c.split('&')[0])) if p == 'GO' else PREFIX_KIND.get(p)
        ro_src = open('BioLean/RO.lean').read()
        labels = {parse_rel(m.group(1)): m.group(2) for m in re.finditer(r'\((⟨\.(?:ro|bfo), \d+, false⟩), "([^"]+)"\)', ro_src)}
        by_label = {v.lower(): k for k, v in labels.items()}; labels[ISA] = 'is_a'

        def rel_of(l):
            if not l: return None
            l = l.strip().lower().replace('_', ' ')
            if l in ('is a', 'isa', 'subclass of'): return ISA
            return by_label.get(l)

        def block(name):
            m = re.search(r'def ' + name + r' : List \(List Rel × Rel\) := \[(.*?)\n\]', ro_src, re.S); return m.group(1) if m else ''
        chains = [tuple(parse_rel(x) for x in re.findall(r'⟨[^⟩]*⟩', ln)) for ln in block('chains').split('\n') if ln.strip().startswith('(')]
        chains = [c for c in chains if len(c) == 3]
        transitive = {parse_rel(x) for x in re.findall(r'⟨[^⟩]*⟩', re.search(r'def transitive : List Rel := \[(.*?)\]', ro_src, re.S).group(1))} | {ISA}
        chain_index = collections.defaultdict(list)
        for r1, r2, r3 in chains: chain_index[r1].append((r2, r3))

        facts, labels_e = {}, {}

        def add(key, deriv, depth, belief, src_id=None):
            if key in facts and facts[key]['depth'] <= depth: return False
            facts[key] = dict(depth=depth, belief=belief, deriv=deriv, src=src_id); return True
        skip = {l.split('\t')[0] for l in open('data/textbook/r2_skip.tsv') if l.strip() and not l.startswith('#')}
        sys.path.insert(0, 'scripts/textbook')
        import emit_lean_m3
        m3_stmts, _, m3_recs = emit_lean_m3.statements(str(pathlib.Path(SRC).with_name('claims_m3')), go_ns)
        m3_quantified = {r['id'] for r in m3_recs if r['m3'].get('quant') in ('some', 'most')}
        m3_facts = {}
        for s in m3_stmts:
            if s['quant']: continue
            if s['ctor'] in ('rel', 'notRel'): m3_facts[s['id']] = ((s['ctor'], s['rel'], s['subj'][0], s['obj'][0]), s)
            elif s['ctor'] == 'effect': m3_facts[s['id']] = (('effect', s['sign'], s['target'], s['subj'][0], s['obj'][0]), s)
        text = {}
        for p in sorted(glob.glob(f'{SRC}/*.json')):
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
                    if m['ctor'] == 'mediatedBy': continue
                    if m.get('sign') not in ('pos', 'neg') or m.get('target') not in ('activity', 'amount', 'process', 'phenotype', 'site'): continue
                    key = ('effect', m['sign'], m['target'], s_, o_)
                if r['id'] in m3_facts or r['id'] in m3_quantified: continue
                text[r['id']] = r.get('claim') or ''
                add(key, ('lit', r['id']), 0, R_TB, r['id'])
        for sid, (key, s) in m3_facts.items():
            for c, (_, l) in s['ents'].items(): labels_e.setdefault(c, l)
            for c, l in (s['subj'], s['obj']): labels_e.setdefault(c, l)
            text[sid] = s['text']
            add(key, ('lit', sid), 0, R_TB, sid)
        todo, seen = [c for k in facts for c in ((k[3], k[4]) if k[0] == 'effect' else (k[2], k[3]))], set()
        while todo:
            c = todo.pop(); b = unrefine(c)
            if b is None or c in seen: continue
            seen.add(c); todo.append(b)
            add(('rel', ISA, c, b), ('refineAxiom', f'refine:{c}'), 0, F(999, 1000))
        return dict(facts=facts, labels_e=labels_e, rel_labels=labels, by_label=by_label, chains=chains,
                    chain_index=chain_index, transitive=transitive, kind_of=kind_of, text=text)
    finally:
        os.chdir(cwd)


def chain(base, holdout=(), extra=(), maxd=4):
    """Forward-chain as closure.py does. `holdout`: statement ids whose facts are removed first. `extra`: facts
    (key, source id) added as textbook statements. Returns (facts, asserted)."""
    holdout = set(holdout)
    facts = {k: dict(v) for k, v in base['facts'].items() if v['src'] not in holdout}
    for key, sid in extra:
        if key not in facts: facts[key] = dict(depth=0, belief=R_TB, deriv=('lit', sid), src=sid)
    asserted = set(facts)
    chain_index, transitive = base['chain_index'], base['transitive']

    def add(key, deriv, depth, belief):
        if key in facts and facts[key]['depth'] <= depth: return False
        facts[key] = dict(depth=depth, belief=belief, deriv=deriv, src=None); return True
    for depth in range(1, maxd + 1):
        idx_subj = collections.defaultdict(list); idx_obj = collections.defaultdict(list); idx_rel_subj = collections.defaultdict(list)
        eff_by_subj = collections.defaultdict(list); isa_sup = collections.defaultdict(list); notrel_subj = collections.defaultdict(list)
        for k in facts:
            if k[0] == 'rel':
                idx_subj[k[2]].append(k); idx_obj[k[3]].append(k); idx_rel_subj[(k[1], k[2])].append(k)
                if k[1] == ISA: isa_sup[k[2]].append(k)
            elif k[0] == 'effect': eff_by_subj[k[3]].append(k)
            elif k[0] == 'notRel': notrel_subj[k[2]].append(k)
        new = []
        for k, v in list(facts.items()):
            if v['depth'] != depth - 1: continue
            if k[0] == 'rel':
                _, r1, a, b = k
                for r2, r3 in chain_index.get(r1, []):
                    for k2 in idx_rel_subj.get((r2, b), []):
                        new.append((('rel', r3, a, k2[3]), ('relChain', k, k2), min(v['belief'], facts[k2]['belief'])))
                for k1 in idx_obj.get(a, []):
                    for r2, r3 in chain_index.get(k1[1], []):
                        if r2 == r1: new.append((('rel', r3, k1[2], b), ('relChain', k1, k), min(v['belief'], facts[k1]['belief'])))
                if r1 in transitive:
                    for k2 in idx_rel_subj.get((r1, b), []): new.append((('rel', r1, a, k2[3]), ('relTrans', k, k2), min(v['belief'], facts[k2]['belief'])))
                    for k1 in idx_obj.get(a, []):
                        if k1[1] == r1: new.append((('rel', r1, k1[2], b), ('relTrans', k1, k), min(v['belief'], facts[k1]['belief'])))
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
            if key[2 if key[0] != 'effect' else 3] == key[-1]: continue
            if add(key, deriv, depth, bel): added += 1
        if not added: break
    return facts, asserted


def show(base, k):
    L, lab = base['labels_e'], base['rel_labels']
    def rl(r): return ('inverse(' + lab.get((r[0], r[1], False), str(r)) + ')') if r[2] else lab.get(r, str(r))
    if k[0] == 'effect': return f"{L.get(k[3], k[3])} [{k[3]}] →{'+' if k[1] == 'pos' else '−'} {k[2]}({L.get(k[4], k[4])} [{k[4]}])"
    return f"{'¬' if k[0] == 'notRel' else ''}{L.get(k[2], k[2])} [{k[2]}] {rl(k[1])} {L.get(k[3], k[3])} [{k[3]}]"


def tree(base, facts, k, ind=''):
    v = facts[k]; d = v['deriv']
    if d[0] in ('lit', 'refineAxiom'): return f"{ind}{show(base, k)}   [{d[1]}]"
    prem = [x for x in d[1:] if isinstance(x, tuple)]
    return f"{ind}{show(base, k)}   ({d[0]})\n" + "\n".join(tree(base, facts, p, ind + '  ') for p in prem)


if __name__ == '__main__':
    base = load()
    facts, asserted = chain(base)
    lits = [k for k in asserted if facts[k]['deriv'][0] == 'lit']
    axioms = [k for k in asserted if facts[k]['deriv'][0] == 'refineAxiom']
    novel = len(facts) - len(asserted)
    print(f'asserted {len(lits)} statements + {len(axioms)} refinement axioms; novel {novel}')
    ref = json.load(open(REPO / 'data/search/closure.json'))
    print(f"data/search/closure.json: asserted {ref['asserted']} novel {ref['novel']} refine_axioms {ref.get('refine_axioms')}")
    print('MATCH' if (len(lits), novel) == (ref['asserted'], ref['novel']) else 'MISMATCH')
