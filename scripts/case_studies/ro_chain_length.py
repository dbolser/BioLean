"""How long do RO chains get in real ontologies, and what do they conclude?
Parses OBO files, finds the longest part_of paths, lifts occurs_in along them (RO: occurs_in ∘ part_of ⊑ occurs_in),
and prints the belief a product chain would assign at each depth. Usage: ro_chain_length.py go.obo uberon.obo"""
import sys, re, collections, functools
from fractions import Fraction as F
R_AX = F(9,10)   # ontologyAxiom reliability

def parse(path):
    terms, isa, partof, occurs = {}, collections.defaultdict(list), collections.defaultdict(list), collections.defaultdict(list)
    cur = None; obsolete = False
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if line == '[Term]': cur = None; obsolete = False; continue
        if line.startswith('[') : cur = None; continue
        if line.startswith('id: '): cur = line[4:].strip()
        elif cur and line.startswith('name: '): terms[cur] = line[6:]
        elif cur and line.startswith('is_obsolete: true'): terms.pop(cur, None); cur = None
        elif cur and line.startswith('is_a: '): isa[cur].append(line[6:].split(' ')[0])
        elif cur and line.startswith('relationship: '):
            parts = line[14:].split(' ')
            rel, tgt = parts[0], parts[1]
            if rel in ('part_of', 'BFO:0000050'): partof[cur].append(tgt)
            elif rel in ('occurs_in', 'BFO:0000066'): occurs[cur].append(tgt)
    return terms, isa, partof, occurs

def longest_paths(edges, terms):
    """Longest path (in edges) from each node following `edges`, with memo; returns (depth, path)."""
    sys.setrecursionlimit(10000)
    @functools.lru_cache(maxsize=None)
    def lp(n, seen=()):
        best = (0, (n,))
        for m in edges.get(n, []):
            if m in seen or m not in terms: continue
            d, p = lp(m, seen + (n,)) if len(seen) < 60 else (0, (m,))
            if d + 1 > best[0]: best = (d + 1, (n,) + p)
        return best
    return lp

def belief(n): return R_AX ** n

for path in sys.argv[1:]:
    terms, isa, partof, occurs = parse(path)
    name = lambda t: f"{terms.get(t, '?')} [{t}]"
    lp = longest_paths(partof, terms)
    ranked = sorted(((lp(t)[0], t) for t in partof), reverse=True)[:3]
    print(f"\n==== {path}: {len(terms)} terms, {sum(map(len, partof.values()))} part_of edges, {sum(map(len, occurs.values()))} occurs_in edges")
    for d, t in ranked:
        _, p = lp(t)
        print(f"-- longest part_of chain: depth {d}, product belief {float(belief(d)):.3f}")
        for i, n in enumerate(p): print(f"   {'' if i == 0 else 'part_of '}{name(n)}   (b after {i} steps = {float(belief(i)):.2f})")
    # occurs_in lifted to the top of the partonomy
    if occurs:
        print("-- occurs_in lifted along part_of to the top (RO chain 'occurs_in ∘ part_of ⊑ occurs_in'):")
        shown = 0
        for p_, locs in sorted(occurs.items(), key=lambda kv: -lp(kv[1][0])[0] if kv[1][0] in partof else 0):
            for loc in locs[:1]:
                d, chain = lp(loc)
                if d < 3: continue
                print(f"   {name(p_)} occurs_in {name(loc)} → ... → occurs_in {name(chain[-1])}  (depth {d}, b = {float(belief(d+1)):.2f})")
                shown += 1
            if shown >= 6: break
    print(f"-- belief by chain length under product: " + ", ".join(f"{n}:{float(belief(n)):.2f}" for n in (1,2,3,5,8,12,16)))
