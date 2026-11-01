"""Program 10c: a small AMIE-style rule miner over BioLean's textbook facts. Writes nothing; imported by the
other induction_*.py scripts.

Facts are closure.py's keys (see induction_closure.py), flattened to triples (p, s, o):
  rel     -> p = the RO label with '_' for ' ' (part_of, has_part, capable_of, is_a, ...)
  notRel  -> p = 'not_' + label        (used only as negatives, never as heads)
  effect  -> p = 'eff_pos_amount', 'eff_neg_process', ...
Background predicates, computed, never heads:
  isa*      reflexive-free transitive closure of is_a facts and refinement axioms, plus (onto=True) the ontology
            is_a closure of data/ontology/isa.json
  in_taxon  x in_taxon T when x's curie carries an outermost-or-nested RO:0002162 filler T (a taxon-wise context)
is_a is background only: never a head, and only through isa* in a body.
Rules, closed and connected (Galarraga et al. 2013), body of one or two atoms:
  path   h(x,y) <= b(x,y) | b(y,x) | b1(x|z, z|x), b2(z|y, y|z)
  class  h(x,C) <= isa*(x,D)      "every D has h to C"; with is_a inheritance this is the fact D h C
  feat   h(x,C) <= b(x,D)         "whatever has b to D has h to C" (b may be in_taxon: a taxon-wise rule)
Measures: support (predictions that are facts), head coverage (support / facts of h), standard confidence
(support / predictions), PCA confidence (support / predictions whose subject has some h fact: the partial
completeness assumption). A rule is kept with support >= MIN_SUPP and PCA >= MIN_PCA."""
import collections, json, pathlib, re

REPO = pathlib.Path(__file__).resolve().parents[2]
ISA = ('rdfs', 0, False)
IN_TAXON = 'RO:0002162'


def pname(base, k):
    lab = base['rel_labels']
    if k[0] == 'effect': return f'eff_{k[1]}_{k[2]}'
    r = k[1]
    l = 'is_a' if r == ISA else lab.get((r[0], r[1], False), f'{r[0]}{r[1]}').replace(' ', '_')
    if r[2]: l = 'inv_' + l
    return ('not_' if k[0] == 'notRel' else '') + l


def triple(base, k):
    return (pname(base, k),) + ((k[3], k[4]) if k[0] == 'effect' else (k[2], k[3]))


def key_of(base, t, inverse_index):
    return inverse_index.get(t)


def taxa_of(c):
    """Taxon fillers of in_taxon refinements anywhere in a curie: 'X&RO:0002162=(NCBITaxon:2)' -> {'NCBITaxon:2'}."""
    return set(re.findall(r'&RO:0002162=\(([^()&]+)', c))


class KB:
    def __init__(self, triples, onto=False):
        self.T = set(triples)
        self.P = collections.defaultdict(set)
        for p, s, o in self.T: self.P[p].add((s, o))
        ents = {x for _, s, o in self.T for x in (s, o)}
        up = collections.defaultdict(set)
        for s, o in self.P.get('is_a', ()): up[s].add(o)
        terms = json.load(open(REPO / 'data/ontology/isa.json'))['terms'] if onto else {}

        def anc(e):
            out, todo = set(), [e]
            while todo:
                x = todo.pop()
                for y in list(up.get(x, ())) + (terms[x]['parents'] if x in terms else []):
                    if y not in out: out.add(y); todo.append(y)
            out.discard(e); return out
        self.anc = {e: anc(e) for e in ents}
        self.P['isa*'] = {(e, a) for e, A in self.anc.items() for a in A}
        self.P['in_taxon'] = {(e, t) for e in ents for t in taxa_of(e)}
        self.bs, self.bo = {}, {}
        for p, pairs in self.P.items():
            bs, bo = collections.defaultdict(set), collections.defaultdict(set)
            for s, o in pairs: bs[s].add(o); bo[o].add(s)
            self.bs[p], self.bo[p] = bs, bo
        self.background = {'isa*', 'in_taxon'}

    def heads(self, min_facts=4):
        return [p for p in self.P if p not in self.background and p != 'is_a' and not p.startswith('not_') and len(self.P[p]) >= min_facts]

    def m(self, p, inv):
        """x -> {z} for the atom p(x,z), or p(z,x) if inv."""
        return self.bo[p] if inv else self.bs[p]


def path_preds(kb, body):
    if len(body) == 1:
        p, inv = body[0]
        return {(o, s) for s, o in kb.P[p]} if inv else set(kb.P[p])
    (p1, i1), (p2, i2) = body
    m1, m2 = kb.m(p1, i1), kb.m(p2, i2)
    out = set()
    for x, zs in m1.items():
        for z in zs:
            for y in m2.get(z, ()):
                if x != y: out.add((x, y))
    return out


def score(kb, h, pred):
    H, hs = kb.P[h], kb.bs[h]
    supp = len(pred & H)
    pca_den = sum(1 for x, _ in pred if x in hs)
    return dict(supp=supp, n=len(pred), hc=supp / len(H), std=supp / len(pred) if pred else 0,
                pca=supp / pca_den if pca_den else 0)


def mine_paths(kb, heads, min_supp=2, min_pca=0.1, max_body=2):
    atoms = [(p, inv) for p in kb.P if not p.startswith('not_') and p != 'is_a' and len(kb.P[p]) >= 2 for inv in (False, True)]
    rules = []
    for h in heads:
        bodies = [[a] for a in atoms if a != (h, False)]
        if max_body >= 2: bodies += [[a, b] for a in atoms for b in atoms]
        for body in bodies:
            pred = path_preds(kb, body)
            if not pred: continue
            s = score(kb, h, pred)
            if s['supp'] >= min_supp and s['pca'] >= min_pca:
                rules.append(dict(type='path', head=h, body=body, pred=pred, **s))
    return rules


def mine_consts(kb, heads, min_supp=2, min_pca=0.5):
    """class rules h(x,C) <= isa*(x,D) and feature rules h(x,C) <= b(x,D), with support counted on subjects."""
    rules = []
    for h in heads:
        hs = kb.bs[h]
        for c, xs in kb.bo[h].items():
            if len(xs) < min_supp: continue
            for b in kb.P:
                if b.startswith('not_') or b in (h, 'is_a'): continue
                cands = collections.Counter(d for x in xs for d in kb.bs[b].get(x, ()))
                for d, n in cands.items():
                    if n < min_supp or d == c: continue
                    S = kb.bo[b][d]
                    pred = {(x, c) for x in S}
                    pca_den = sum(1 for x in S if x in hs)
                    pca = n / pca_den if pca_den else 0
                    if pca >= min_pca:
                        rules.append(dict(type='class' if b == 'isa*' else ('taxon' if b == 'in_taxon' else 'feat'),
                                          head=h, const=c, body_pred=b, body_const=d, pred=pred, supp=n, n=len(S),
                                          hc=n / len(kb.P[h]), std=n / len(S), pca=pca))
    return rules


def most_specific(rules):
    """Class rules with the same head and constant: drop a rule when another covers at least as much support with a
    class no larger, one of the two strictly (Pareto on support and class size). What is left is, for each support
    set, its least general class (Plotkin's least general generalisation, over the is_a lattice)."""
    out, groups = [], collections.defaultdict(list)
    for r in rules:
        if r['type'] == 'class': groups[(r['head'], r['const'])].append(r)
        else: out.append(r)
    for rs in groups.values():
        for r in rs:
            if not any((o['supp'] >= r['supp'] and o['n'] <= r['n']) and (o['supp'] > r['supp'] or o['n'] < r['n'])
                       for o in rs):
                if not any(o is not r and o['supp'] == r['supp'] and o['n'] == r['n'] and o['body_const'] < r['body_const'] for o in rs):
                    out.append(r)
    return out


def mine(kb, min_supp=2, min_pca=0.5, min_head=4, max_body=2):
    heads = kb.heads(min_head)
    return most_specific(mine_paths(kb, heads, min_supp, min_pca, max_body) + mine_consts(kb, heads, min_supp, min_pca))


def predictions(kb, rules):
    """(h, x, y) not in the KB -> the best rule predicting it (highest PCA, then support)."""
    best = {}
    for r in rules:
        for x, y in r['pred']:
            t = (r['head'], x, y)
            if t in kb.T or x == y: continue
            if t not in best or (r['pca'], r['supp']) > (best[t]['pca'], best[t]['supp']): best[t] = r
    return best


def category(r, base):
    """Is the rule one BioLean already has (a core rule), one it refuses (inverse, a blocked RO chain), or new?"""
    if r['type'] != 'path': return r['type']
    h, b = r['head'], r['body']
    lab = {v.replace(' ', '_'): k for k, v in base['rel_labels'].items()}
    trans = {base['rel_labels'].get(t, '').replace(' ', '_') for t in base['transitive']} | {'is_a'}
    chains = {(base['rel_labels'].get(a, '').replace(' ', '_'), base['rel_labels'].get(c, '').replace(' ', '_'),
               base['rel_labels'].get(d, '').replace(' ', '_')) for a, c, d in base['chains']}
    if len(b) == 1: return 'inverse' if b[0][1] else 'implication'
    (p1, i1), (p2, i2) = b
    isa = ('is_a', 'isa*')
    if p1 in isa and not i1 and p2 == h and not i2: return 'core:isaInherit'
    if p1 == h and not i1 and p2 in isa and not i2: return 'core:isaGeneralise'
    if p1 == p2 == h and not i1 and not i2 and h in trans: return 'core:transitive'
    if not i1 and not i2 and (p1, p2, h) in chains: return 'core:ROchain'
    if p1 in isa and i1 and p2 == h and not i2: return 'upward'
    return 'new path'


def show(r, L=None):
    L = L or {}
    def n(c): return L.get(c) or c
    if r['type'] == 'path':
        def at(a, v1, v2):
            p, inv = a; return f'{p}({v2},{v1})' if inv else f'{p}({v1},{v2})'
        b = at(r['body'][0], 'x', 'y') if len(r['body']) == 1 else at(r['body'][0], 'x', 'z') + ', ' + at(r['body'][1], 'z', 'y')
        return f"{r['head']}(x,y) <= {b}"
    return f"{r['head']}(x,{n(r['const'])}) <= {r['body_pred']}(x,{n(r['body_const'])})"


def rule_id(r):
    if r['type'] == 'path': return f"{r['head']}<=" + ','.join(('~' if i else '') + p for p, i in r['body'])
    return f"{r['head']}(x,{r['const']})<={r['body_pred']}(x,{r['body_const']})"
