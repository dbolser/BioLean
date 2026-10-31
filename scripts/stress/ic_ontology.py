"""Ontology graph helpers for program 07: ancestors, IC of any term, most informative common ancestor, entailment.

Reads the four OBO files data/search/ic.json was built from (same releases): go.obo (releases/2026-07-26; go-basic is
not enough, it drops part_of edges that cross GO's namespaces), uberon.obo, cl-basic.obo, chebi_lite.obo. They are downloads, read as text only; run the caller with
`python3 -I`. IC is recomputed exactly as scripts/ontology/ic.py does (subtree over is_a + part_of, N = live terms of the
ontology, GO by namespace) so that `check_against_ic_json` can confirm the graph is the same one.
"""
import collections, math, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'ontology'))
import obo   # the repo's minimal OBO reader (scripts/ontology/obo.py); it only reads

FILES = {'GO': 'go.obo', 'UBERON': 'uberon.obo', 'CL': 'cl-basic.obo', 'CHEBI': 'chebi_lite.obo'}


class Graph:
    def __init__(self, paths):
        """paths: prefix -> OBO file."""
        self.isa, self.partof, self.ns, self.alt, self.repl, self.version = {}, {}, {}, {}, {}, {}
        self.kids = collections.defaultdict(list); self.size = collections.Counter(); self._sub = {}
        for pre, path in paths.items():
            self.version[pre] = obo.version(path)
            for t in obo.terms(path):
                c = t['id']
                if not c.startswith(pre + ':'): continue
                for a in t['alt_id']: self.alt[a] = c
                if t['obsolete']:
                    if len(t['replaced_by']) == 1: self.repl[c] = t['replaced_by'][0]
                    continue
                self.isa[c] = [p for p in t['is_a'] if p.startswith(pre + ':')]
                self.partof[c] = [p for p in t['part_of'] if p.startswith(pre + ':')]
                self.ns[c] = t['namespace'] if pre == 'GO' else pre
                self.size[self.ns[c]] += 1
        for c in self.isa:
            for p in self.isa[c] + self.partof[c]: self.kids[p].append(c)

    def live(self, c):
        """The live term for an id: itself, its primary id if an alt_id, or its one replacement if obsolete."""
        c = self.alt.get(c, c)
        c = self.repl.get(c, c)
        return self.alt.get(c, c) if self.alt.get(c, c) in self.isa else None

    def ic(self, c):
        c = self.live(c)
        if c is None: return None
        if c not in self._sub:
            seen, stack = {c}, [c]
            while stack:
                for k in self.kids.get(stack.pop(), ()):
                    if k not in seen: seen.add(k); stack.append(k)
            self._sub[c] = len(seen)
        return -math.log(self._sub[c] / self.size[self.ns[c]])

    def ancestors(self, c):
        """{ancestor: (distance, through_part_of)} over is_a + part_of, the term itself at distance 0. distance is the
        shortest path; through_part_of is True when some path to the ancestor uses at least one part_of edge."""
        c = self.live(c)
        if c is None: return {}
        best = {(c, False): 0}; q = collections.deque([(c, False)])
        while q:
            n, po = q.popleft(); d = best[(n, po)]
            for p, step_po in [(p, False) for p in self.isa.get(n, ())] + [(p, True) for p in self.partof.get(n, ())]:
                s = (p, po or step_po)
                if s not in best: best[s] = d + 1; q.append(s)
        out = {}
        for (n, po), d in best.items():
            dd, ppo = out.get(n, (None, False))
            out[n] = (d if dd is None else min(d, dd), ppo or po)
        return out

    def isa_ancestors(self, c):
        c = self.live(c)
        if c is None: return set()
        seen, stack = {c}, [c]
        while stack:
            for p in self.isa.get(stack.pop(), ()):
                if p not in seen: seen.add(p); stack.append(p)
        return seen

    def same_space(self, a, b):
        a, b = self.live(a), self.live(b)
        return a is not None and b is not None and self.ns[a] == self.ns[b]

    def mica(self, a, b):
        """(IC of the most informative common ancestor, its id, path length through it), same ontology only, else None."""
        if not self.same_space(a, b): return None
        A, B = self.ancestors(a), self.ancestors(b)
        common = set(A) & set(B)
        if not common: return (0.0, None, None)
        m = max(common, key=lambda x: (self.ic(x), -(A[x][0] + B[x][0]), x))
        return (self.ic(m), m, min(A[x][0] + B[x][0] for x in common))

    def link(self, a, b):
        """How the ontology itself relates a and b: 'same', 'is_a', 'part_of' (a below b, through some part_of),
        the reverse 'has_subclass' or 'has_part', or None."""
        la, lb = self.live(a), self.live(b)
        if la is None or lb is None: return None
        if la == lb: return 'same'
        if lb in self.isa_ancestors(la): return 'is_a'
        A = self.ancestors(la)
        if lb in A and A[lb][1]: return 'part_of'
        if la in self.isa_ancestors(lb): return 'has_subclass'
        B = self.ancestors(lb)
        if la in B and B[la][1]: return 'has_part'
        return None


def entailed(rel_label, link):
    """Does the ontology's own is_a / part_of graph already give the derived fact? Only for relations it can decide."""
    if link is None: return False
    if rel_label == 'is_a': return link in ('same', 'is_a')
    if rel_label == 'part of': return link == 'part_of'
    if rel_label == 'overlaps': return True   # parthood or subsumption either way implies overlap
    return False


def load(dirs):
    """dirs: list of directories to look in for each file (first hit wins)."""
    paths = {}
    for pre, fn in FILES.items():
        hit = next((os.path.join(d, fn) for d in dirs if os.path.exists(os.path.join(d, fn))), None)
        if hit is None: raise SystemExit(f'missing {fn} in {dirs}')
        paths[pre] = hit
    return Graph(paths), paths


def check_against_ic_json(g, ic_terms):
    """Recompute IC for every scored term of ic.json; return (n compared, n differing by > 1e-3, examples)."""
    n = bad = 0; ex = []
    for c, v in ic_terms.items():
        if 'ic' not in v or c.split(':')[0] not in FILES: continue
        mine = g.ic(c); n += 1
        if mine is None or abs(mine - v['ic']) > 1e-3:
            bad += 1
            if len(ex) < 5: ex.append((c, v['ic'], None if mine is None else round(mine, 4)))
    return n, bad, ex
