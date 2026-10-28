"""Import the is_a ancestor closure of every CURIE biolib uses and emit it as numeric Lean data.

GO, UBERON, CL, ChEBI, PATO, MONDO, HP, SO and PR come from OBO files (asserted is_a lines of the released, reasoned
files; PR is pro_reasoned.obo, 200 MB, about a minute to fetch and parse); NCBITaxon from the OLS4 API, one request per
closure term, cached in data/ontology/ncbitaxon_cache.json (the full file is 2 GB), plus the direct NCBI children of the
generalisation targets (TARGETS), so coverage counts a clade's real children rather than biolib's. PR terms named by a
UniProt accession (PR:P01275) have no numeric code, so they are left out and their numeric ancestors seeded instead; is_a
links to terms outside the closure (another ontology's terms) are dropped.
Seeds are the used CURIEs (data/ontology/used_curies.json, from collect_entities.py) plus the replacements of retired
ones, and the targets' children. The closure is every seed and every is_a ancestor of a seed; the edges are the direct is_a
links among them.
Writes data/ontology/isa.json (terms with label, GO namespace, parents; retired used terms; missing ones) and
BioLean/Ontology/IsA.lean. Standard library only (and `obo.py`).
Usage: uv run python scripts/ontology/import_isa.py [obo_dir]   (default /tmp/obo; missing OBO files are downloaded)"""
import os, re, sys, json, time, pathlib, collections, urllib.parse, urllib.error
sys.path.insert(0, str(pathlib.Path(__file__).parent))
import obo

OBO_DIR = sys.argv[1] if len(sys.argv) > 1 else '/tmp/obo'
USED, CACHE, OUT_JSON, OUT_LEAN = ('data/ontology/used_curies.json', 'data/ontology/ncbitaxon_cache.json',
                                   'data/ontology/isa.json', 'BioLean/Ontology/IsA.lean')
FILES = {'GO': 'go.obo', 'UBERON': 'uberon.obo', 'CL': 'cl-basic.obo', 'CHEBI': 'chebi_lite.obo', 'PATO': 'pato.obo',
         'MONDO': 'mondo.obo', 'HP': 'hp.obo', 'SO': 'so.obo', 'PR': 'pr.obo'}
URLS = {'chebi_lite.obo': 'http://purl.obolibrary.org/obo/chebi/chebi_lite.obo'}
# Ontology codes, fixed: append, never reorder (the codes are in the Lean data).
PREFIXES = ['GO', 'UBERON', 'CL', 'CHEBI', 'NCBITaxon', 'PR', 'HP', 'PATO', 'MONDO', 'SO', 'BFO', 'CARO', 'PO',
            'NCIT', 'ENVO', 'OBA', 'OBI', 'CHMO', 'NBO', 'MAXO', 'COB', 'UO', 'EFO', 'ECOCORE', 'RO', 'CP']
# Generalisation targets (M4 coverage): their direct NCBI children are imported, so `children` of a target in Lean is
# NCBI's list. Children that are bins rather than clades are left out: labels containing "unclassified", "environmental
# samples", "incertae sedis" or "candidat" (candidate phyla; under Bacteria now the provisional "Candidatus" phyla of
# uncultured lineages). Below the targets, children are still only the used terms and their ancestors.
TARGETS = ['NCBITaxon:131567', 'NCBITaxon:2759', 'NCBITaxon:33154', 'NCBITaxon:33208', 'NCBITaxon:2', 'NCBITaxon:2157',
           'NCBITaxon:33090', 'NCBITaxon:40674']  # cellular organisms, Eukaryota, Opisthokonta, Metazoa, Bacteria,
                                                  # Archaea, Viridiplantae, Mammalia
BINS = ('unclassified', 'environmental samples', 'incertae sedis', 'candidat')
used = json.load(open(USED))
prefix = lambda c: c.split(':', 1)[0]
terms, retired, missing, versions, unencodable = {}, {}, [], {}, set()   # terms: curie -> {label, namespace?, parents}


def close(seeds, lookup):
    """Add the is_a ancestor closure of `seeds` to `terms`; `lookup(curie)` gives a term record or None. A term with
    no numeric code is passed through: left out, its parents followed."""
    stack = list(seeds)
    while stack:
        c = stack.pop()
        if c in terms or c in unencodable: continue
        t = lookup(c)
        if t is None: missing.append(c); continue
        if not c.partition(':')[2].isdigit(): unencodable.add(c); stack += t['parents']; continue  # PR:P01275
        terms[c] = t
        stack += t['parents']


for pre, fn in FILES.items():
    path = os.path.join(OBO_DIR, fn)
    if not os.path.exists(path):
        print(f'downloading {fn}', file=sys.stderr)
        with open(path, 'wb') as f: f.write(obo.request(URLS.get(fn, f'http://purl.obolibrary.org/obo/{fn}')).read())
    versions[pre] = f'{fn} {obo.version(path)}'
    T = {t['id']: t for t in obo.terms(path)}
    alt = {a: t['id'] for t in T.values() for a in t['alt_id']}
    seeds = []
    for c in (c for c in used if prefix(c) == pre):
        if c in alt: retired[c] = {'why': 'alt_id', 'replaced_by': [alt[c]], 'consider': []}; seeds.append(alt[c])
        elif c in T and T[c]['obsolete']:
            retired[c] = {'why': 'obsolete', 'replaced_by': T[c]['replaced_by'], 'consider': T[c]['consider']}
            seeds += T[c]['replaced_by']
        else: seeds.append(c)
    def lookup(c, T=T, pre=pre):
        t = T.get(c)
        if t is None or t['obsolete']: return None
        r = {'label': t['name'] or '', 'parents': sorted(set(t['is_a']))}
        if pre == 'GO': r['namespace'] = t['namespace']
        return r
    n0 = len(terms); close(seeds, lookup)
    print(f'{pre}: {len(T)} stanzas in {fn}; closure +{len(terms) - n0} terms', file=sys.stderr)

# NCBITaxon from OLS4, one entity per closure term (label, obsolete, replaced_by, hierarchical parents). The cache
# records the release it was filled from; delete it to refetch against a newer one.
OLS = 'https://www.ebi.ac.uk/ols4/api/v2/ontologies/ncbitaxon/entities/'
cache = (json.load(open(CACHE)) if os.path.exists(CACHE) else
         {'version': json.load(obo.request('https://www.ebi.ac.uk/ols4/api/ontologies/ncbitaxon'))['version'], 'terms': {}})
IRI = 'http://purl.obolibrary.org/obo/'
curie_of = lambda iri: iri.removeprefix(IRI).replace('_', ':', 1)


quote_iri = lambda c: urllib.parse.quote(urllib.parse.quote(IRI + c.replace(':', '_'), safe=''), safe='')


def record(d):
    """The cache record of an OLS4 entity: label, obsolete, replaced_by, hierarchical parents."""
    rb = d.get('term_replaced_by') or []
    return {'label': (d.get('label') or [''])[0], 'obsolete': bool(d.get('isObsolete')),
            'replaced_by': [curie_of(x) for x in (rb if isinstance(rb, list) else [rb])],
            'parents': sorted(curie_of(p) for p in d.get('hierarchicalParent') or [])}


def taxon(c):
    seen = cache['terms']
    if c not in seen:
        try: seen[c] = record(json.load(obo.request(OLS + quote_iri(c))))
        except urllib.error.HTTPError as e:
            if e.code != 404: raise
            seen[c] = None
        json.dump(cache, open(CACHE, 'w'), indent=0, sort_keys=True)
        time.sleep(0.05)
    return seen[c]


def children(c):
    """The direct NCBI children of `c` (OLS4 hierarchicalChildren, one page); each child is cached as a term too."""
    seen = cache.setdefault('children', {})
    if c not in seen:
        url = OLS.replace('/entities/', '/classes/') + quote_iri(c) + '/hierarchicalChildren?size=1000'
        d = json.load(obo.request(url))
        assert d['totalPages'] <= 1, f'{c}: more than one page of children'
        for e in d['elements']: cache['terms'][curie_of(e['iri'])] = record(e)
        seen[c] = sorted(curie_of(e['iri']) for e in d['elements'])
        json.dump(cache, open(CACHE, 'w'), indent=0, sort_keys=True)
    return seen[c]


seeds = []
for c in (c for c in used if prefix(c) == 'NCBITaxon'):
    t = taxon(c)
    if t and t['obsolete']:
        retired[c] = {'why': 'obsolete', 'replaced_by': t['replaced_by'], 'consider': []}; seeds += t['replaced_by']
    else: seeds.append(c)
def taxon_term(c):
    t = taxon(c)
    return None if t is None or t['obsolete'] else {'label': t['label'], 'parents': t['parents']}
n0 = len(terms); close(seeds, taxon_term)
print(f'NCBITaxon: closure +{len(terms) - n0} terms via OLS4', file=sys.stderr)
binned = {}   # target -> children left out as bins
for t in TARGETS:
    kids = children(t)
    binned[t] = [k for k in kids if any(b in cache['terms'][k]['label'].lower() for b in BINS)]
    n0 = len(terms); close([k for k in kids if k not in binned[t]], taxon_term)
    print(f'{t} {taxon(t)["label"]}: {len(kids)} NCBI children, {len(binned[t])} bins left out, '
          f'+{len(terms) - n0} terms', file=sys.stderr)
versions['NCBITaxon'] = f'OLS4 API ncbitaxon {cache["version"]}'

# encode, check, summarise
def code(c):
    p, _, n = c.partition(':')
    return (PREFIXES.index(p), int(n)) if p in PREFIXES and n.isdigit() else None
dropped = sorted({(c, p) for c, t in terms.items() for p in t['parents'] if p not in terms})
for t in terms.values(): t['parents'] = [p for p in t['parents'] if p in terms]
bad = sorted(c for c in terms if code(c) is None)
assert not bad, f'closure terms with no numeric code (add the prefix to PREFIXES?): {bad[:20]}'
assert len({code(c) for c in terms}) == len(terms), 'two curies share a code'
edges = sorted((code(c), code(p)) for c, t in terms.items() for p in t['parents'])
depth = {}
def d(c): # longest is_a path up from c
    if c not in depth: depth[c] = 1 + max((d(p) for p in terms[c]['parents']), default=-1)
    return depth[c]
max_depth = max(map(d, terms))

json.dump({'versions': versions, 'prefixes': PREFIXES, 'terms': dict(sorted(terms.items())),
           'retired': dict(sorted(retired.items())), 'missing': sorted(set(missing)),
           'unencodable': sorted(unencodable), 'dropped_edges': dropped, 'targets': TARGETS, 'binned_children': binned},
          open(OUT_JSON, 'w'), indent=0)

lean_str = lambda s: s.replace('\\', '\\\\').replace('"', '\\"')
pair = lambda k: f'⟨{k[0]}, {k[1]}⟩'
by_pre = collections.Counter(prefix(c) for c in terms)
kids = collections.defaultdict(list)
for c, t in terms.items():
    for p in t['parents']: kids[p].append(c)
rows = sorted((code(c), t['label'], [code(p) for p in t['parents']], sorted(map(code, kids[c]))) for c, t in terms.items())


def tree(rows, ind):
    """A balanced search tree literal over sorted rows, one node per line."""
    if not rows: return '.leaf'
    m = len(rows) // 2
    k, lab, ps, cs = rows[m]
    sub = lambda r: tree(r, ind + '  ') if len(r) == 0 else f'({tree(r, ind + "  ")})'
    return (f'.node {pair(k)} "{lean_str(lab)}" [{", ".join(map(pair, ps))}] [{", ".join(map(pair, cs))}]\n'
            f'{ind}  {sub(rows[:m])}\n{ind}  {sub(rows[m + 1:])}')


L = ['/-! # Ontology is_a, imported as data', '',
     'Generated by `scripts/ontology/import_isa.py`. Do not edit. The is_a ancestor closure of every CURIE biolib uses',
     '(Entity literals in `BioLean/` and the M2 textbook claims) and of the direct NCBI children of the generalisation',
     f'targets (`targets`): {len(terms)} terms, {len(edges)} direct is_a edges, longest chain {max_depth}. Only these are',
     'present, so `known` is false for anything else.',
     'Sources: ' + '; '.join(f'{p} {v}' for p, v in versions.items()) + '.',
     'Terms per ontology: ' + ', '.join(f'{p} {n}' for p, n in by_pre.most_common()) + '.', '',
     'A CURIE is a `Code`, (ontology, local id), and the terms sit in a balanced search tree keyed on it, so',
     '`decide` follows an is_a step in a dozen number comparisons rather than a scan of every edge. Each term',
     'also lists its direct children, so walking down (`children`, coverage of a clade) is as cheap as up. -/', '',
     'namespace BioLean', '', '/-- A CURIE as (ontology, local id): `GO:0006096` is `⟨0, 6096⟩`. -/',
     'abbrev Code := Nat × Nat', '', 'namespace Curie', '',
     '/-- Ontology prefixes; the code of a prefix is its index. -/',
     'def prefixes : List String := [' + ', '.join(f'"{p}"' for p in PREFIXES) + ']', '',
'''/-- Digits to a number; `none` if empty or any character is not a digit. -/
def digits : List Char → Option Nat
  | [] => none
  | cs => cs.foldl (fun acc ch => acc.bind fun n => if ch.isDigit then some (10 * n + (ch.toNat - 48)) else none) (some 0)

/-- `"GO:0006096"` to `⟨0, 6096⟩`. `none` for unknown prefixes, non-numeric ids and refined curies
(`NCBITaxon:10090&RO:...`). -/
def encode (s : String) : Option Code :=
  match s.toList.span (· != ':') with
  | (p, _ :: id) => do let o ← prefixes.idxOf? (String.ofList p); let n ← digits id; pure (o, n)
  | _ => none

end Curie

namespace Ontology

/-- A binary search tree of terms, ordered on `Code` lexicographically: key, label, direct is_a parents,
direct is_a children (among the imported terms). -/
inductive Tree where
  | leaf
  | node (key : Code) (label : String) (parents children : List Code) (l r : Tree)

def Tree.find? (a : Code) : Tree → Option (String × List Code × List Code)
  | .leaf => none
  | .node k lab ps cs l r =>
    if a.1 < k.1 || (a.1 == k.1 && a.2 < k.2) then l.find? a
    else if a == k then some (lab, ps, cs) else r.find? a

/-- Key, label and parents of every term, in key order. -/
def Tree.toList : Tree → List (Code × String × List Code)
  | .leaf => []
  | .node k lab ps _ l r => l.toList ++ (k, lab, ps) :: r.toList
''',
     'set_option maxRecDepth 100000 in', '/-- The closure. -/', f'def tree : Tree :=\n  {tree(rows, "")}', '']
rt = [(c, r) for c, r in sorted(retired.items()) if code(c)]
L += ['/-- Used terms their ontology has retired: obsolete, or merged into another term (an alt_id), with',
      'the `replaced_by` targets (none if the ontology only says `consider`). -/',
      'def retired : List (Code × List Code) := [']
L += [f'  ({pair(code(c))}, [{", ".join(pair(code(x)) for x in r["replaced_by"])}]),  -- {c} {r["why"]}' for c, r in rt]
L[-1] = re.sub(r'\),(\s+--)', r')\1', L[-1])
L += [']', '', '/-- The generalisation targets: taxa whose `children` are all of their NCBI children, bins (unclassified,',
      'environmental samples, incertae sedis, candidate phyla) left out. -/',
      'def targets : List Code := [' + ', '.join(pair(code(t)) for t in TARGETS) + ']', '',
      f'/-- The longest is_a chain; fuel for `isA`. -/', f'def maxDepth : Nat := {max_depth}', '',
'''/-- Direct is_a edges `(term, parent)`. -/
def edges : List (Code × Code) := tree.toList.flatMap fun (c, _, ps) => ps.map (c, ·)

def labels : List (Code × String) := tree.toList.map fun (c, lab, _) => (c, lab)

def label? (a : Code) : Option String := (tree.find? a).map (·.1)

def parents (a : Code) : List Code := ((tree.find? a).map (·.2.1)).getD []

/-- Direct is_a children among the imported terms. For a taxon in `targets` these are its NCBI
children; elsewhere only used terms and their ancestors are imported, so this under-counts. -/
def children (a : Code) : List Code := ((tree.find? a).map (·.2.2)).getD []

/-- Is the term in the imported closure? -/
def known (a : Code) : Bool := (tree.find? a).isSome

/-- Reflexive-transitive is_a, at most `fuel` steps. (Matching on `fuel` first, not after `a == b ||`,
keeps elaborator-side `decide` fast when `a` comes from `Curie.encode`.) -/
def isA (a b : Code) : (fuel : Nat := maxDepth) → Bool
  | 0 => a == b
  | n + 1 => a == b || (parents a).any fun p => isA p b n

/-- Two known terms, neither is_a the other. -/
def siblings (a b : Code) : Bool := known a && known b && !isA a b && !isA b a

/-- `isA` on curie strings, for `Entity.curie`: equal strings, or both encode and `isA` holds. -/
def isACurie (a b : String) : Bool :=
  a == b || match Curie.encode a, Curie.encode b with
    | some x, some y => isA x y
    | _, _ => false

end Ontology
end BioLean
''']
os.makedirs(os.path.dirname(OUT_LEAN), exist_ok=True)
open(OUT_LEAN, 'w').write('\n'.join(L))

print(f'terms {len(terms)}, edges {len(edges)}, max depth {max_depth}; by prefix: ' +
      ', '.join(f'{p} {n}' for p, n in by_pre.most_common()))
print(f'retired used terms {len(retired)}:')
for c, r in sorted(retired.items()): print(f'  {c} {r["why"]}: replaced_by {r["replaced_by"]}, consider {r["consider"]}')
print(f'missing (not in source) {len(set(missing))}: {sorted(set(missing))}')
print(f'terms with no numeric code, left out (parents followed) {len(unencodable)}: {sorted(unencodable)}')
print(f'is_a links out of the closure, dropped {len(dropped)}: {dropped[:10]}')
