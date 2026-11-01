"""Program 04: mutation testing of BioLean's annotation-error detectors. Shared harness, operators and detectors.

The real claims are never touched. `ensure_copy()` copies data/textbook/claims_m2 and claims_m3 to /tmp/biolean-04/claims;
each mutant is that copy with one record's annotation changed, written to /tmp/biolean-04/mut/<id>/ (unchanged files are
symlinks to the copy). The closure is scripts/stress/closure_mutants.py (a copy of scripts/search/closure.py with outputs
redirected), run up to its report marker, as scripts/search/holes.py does with closure.py.

Detectors (column names used in data/stress/04/mutants.tsv):
  lean_emit     the round-2/3 emitter refuses the record (no kind for a prefix, relation not in RO)       existing, outside core
  lean          the emitted claim fails to elaborate (`by decide` on Rel.accepts, Target kinds)            existing, core
                (filled in by mutants_lean.py, which compiles every mutant; `lean_mirror` is the Python mirror)
  clash         a new rel/notRel pair in the closure                                                      existing, scripts/search
  sign          a new a →+ t / a →− t pair in the closure                                                 existing, scripts/search
  taxon_lint    Statement.taxonConsistent (evidence taxon vs claim taxon); textbook evidence has no taxon  existing, core lint
  go_tax        GO computed taxon constraints against the claim's stated taxon scope                      data only (cached)
  ub_tax        UBERON / CL taxon constraints (uberon.obo) against the stated scope                       data only
  go_tax_c, ub_tax_c   the same, with an unscoped subject's own constraints as its scope (its 'ceiling')   data only
  disjoint      disjoint_from (is_a claims), mutually_spatially_disjoint_with (parthood), is_a across kinds data; is_a-across-kinds in holes.py
  obsolete      a term is obsolete in its OBO file                                                         holes.py (for holes); Ontology.retired (core data)
  onto_refutes  GO/UBERON/CL/ChEBI refute an is_a or part_of claim (reverse holds, or is_a not an ancestor) holes.py (for holes)
  mode          relation and kinds pattern never seen in the textbook (Progol-style mode declaration)     holes.py (for holes)
  label         mention text shares no content word with the term's label or synonyms                     new (prototype)
"""
import sys, os, json, glob, re, copy, pathlib, collections, shutil, io, contextlib, filecmp

REPO = '/home/danbolser/Build/BioLean'
os.chdir(REPO)
sys.path.insert(0, REPO + '/scripts/stress'); sys.path.insert(0, REPO + '/scripts/textbook')
import mutants_onto as O
import emit_lean_m3

GO_OBO = '/tmp/obo/go.obo'
WORK = pathlib.Path('/tmp/biolean-04')
CLAIMS, MUT = WORK / 'claims', WORK / 'mut'
OUT = pathlib.Path(REPO) / 'data/stress/04'
CLOSURE_SRC = open(REPO + '/scripts/stress/closure_mutants.py').read()
MARK = '# --- statements flagged false as written'   # run the rules, the report and the effect-chain guards (loop flags)
assert MARK in CLOSURE_SRC

def ensure_copy():
    """Copy the real round-2 and round-3 claims to /tmp/biolean-04/claims, if missing or stale."""
    for d in ('claims_m2', 'claims_m3'):
        src, dst = pathlib.Path(REPO) / 'data/textbook' / d, CLAIMS / d
        if dst.exists():
            cmp = filecmp.dircmp(src, dst)
            if not (cmp.diff_files or cmp.left_only or cmp.right_only): continue
            shutil.rmtree(dst)
        shutil.copytree(src, dst)

def run_closure(root):
    """The closure's facts on the claims under `root` (claims_m2 and its sibling claims_m3)."""
    sys.argv = ['closure_mutants', str(root / 'claims_m2'), GO_OBO, '--out=/tmp/biolean-04/out/closure_scratch']
    ns = {'__name__': 'closure_loader'}
    with contextlib.redirect_stdout(io.StringIO()):
        exec(compile(CLOSURE_SRC[:CLOSURE_SRC.index(MARK)], 'closure_mutants.py', 'exec'), ns)
    facts, flags = ns['facts'], ns.get('flags', {})
    clashes = {k for k in facts if k[0] == 'rel' and ('notRel',) + k[1:] in facts}
    # a sign clash with either side crossing a named feedback loop is the closure's known loop artefact, not an error
    loop = lambda k: 'feedback' in flags.get(k, {})
    signs = {k for k in facts if k[0] == 'effect' and k[1] == 'pos' and ('effect', 'neg') + k[2:] in facts
             and not (loop(k) or loop(('effect', 'neg') + k[2:]))}
    ns['sign_loop'] = {k for k in facts if k[0] == 'effect' and k[1] == 'pos' and ('effect', 'neg') + k[2:] in facts} - signs
    return ns, clashes, signs

def resting_on(ns, sid):
    """Derived (novel) facts whose derivation uses statement `sid`: the damage a bad statement does."""
    facts, memo = ns['facts'], {}
    def lits(k):
        if k in memo: return memo[k]
        memo[k] = frozenset()
        d = facts[k]['deriv']
        out = {d[1]} if d[0] == 'lit' else set()
        for p in d[1:]:
            if isinstance(p, tuple) and p in facts: out |= lits(p)
        memo[k] = frozenset(out); return memo[k]
    asserted, axioms = ns['asserted'], ns['axioms']
    return [k for k in facts if k not in asserted and k not in axioms and sid in lits(k)]

# --- records
FILES, LOC = {}, {}      # (dir, file) -> records;  (field, id) -> (dir, file, index)
def load_records():
    FILES.clear(); LOC.clear()
    for d in ('claims_m2', 'claims_m3'):
        for p in sorted((CLAIMS / d).glob('*.json')):
            recs = json.load(open(p)); FILES[(d, p.name)] = recs
            for i, r in enumerate(recs): LOC[('m2' if d == 'claims_m2' else 'm3', r['id'])] = (d, p.name, i)
def record(field, rid):
    d, n, i = LOC[(field, rid)]; return FILES[(d, n)][i]
def active(rid):
    """The annotation the closure and Lean read for this id: round 3 if it re-annotated the record as rel, notRel,
    effect or some/most (the closure's supersession rule), else round 2."""
    if ('m3', rid) in LOC:
        m = record('m3', rid)['m3']
        if m.get('ctor') in ('rel', 'notRel', 'effect') or m.get('quant') in ('some', 'most'): return 'm3'
    return 'm2' if ('m2', rid) in LOC else 'm3'

def write_mutant(mid, field, rid, ann):
    root = MUT / mid
    if root.exists(): shutil.rmtree(root)
    for d in ('claims_m2', 'claims_m3'):
        (root / d).mkdir(parents=True)
        for (dd, n), recs in FILES.items():
            if dd != d: continue
            if LOC.get((field, rid), (None, None))[:2] == (d, n):
                recs2 = copy.deepcopy(recs); recs2[LOC[(field, rid)][2]][field] = ann
                json.dump(recs2, open(root / d / n, 'w'))
            else:
                os.symlink(CLAIMS / d / n, root / d / n)
    return root

def texts(r):
    """Mention text per curie, as the annotators recorded it."""
    t = {e['curie']: e.get('text') for e in r.get('entities', []) if e.get('curie')}
    for f in ('m2', 'm3'):
        for ch in (r.get(f) or {}).get('curie_changes') or []:
            if ch.get('to'): t.setdefault(ch['to'], ch.get('text'))
    return t

# --- kinds, relations
GO_NS = emit_lean_m3.go_namespaces(GO_OBO)
KIND_BY_NS = emit_lean_m3.KIND_BY_NS
PREFIX_KIND = emit_lean_m3.PREFIX_KIND
def kind_of(c):
    if not c: return None
    p = c.split(':')[0]
    return KIND_BY_NS.get(GO_NS.get(c.split('&')[0])) if p == 'GO' else PREFIX_KIND.get(p)
RO_SRC = open(REPO + '/BioLean/RO.lean').read()
RO_LAB = {(m.group(1), int(m.group(2)), False): m.group(3) for m in re.finditer(r'\(⟨\.(ro|bfo), (\d+), false⟩, "([^"]+)"\)', RO_SRC)}
ISA = ('rdfs', 0, False); RO_LAB[ISA] = 'is_a'
BY_LAB = {v.lower(): k for k, v in RO_LAB.items()}
def rel_of(l): return emit_lean_m3.rel_of(l)
INV = {}
for _ln in re.search(r'def inverses : List \(Rel × Rel\) := \[(.*?)\n\]', RO_SRC, re.S).group(1).split('\n'):
    _rs = re.findall(r'⟨\.(ro|bfo), (\d+), false⟩', _ln)
    if len(_rs) == 2:
        _a, _b = (_rs[0][0], int(_rs[0][1]), False), (_rs[1][0], int(_rs[1][1]), False); INV[_a] = _b; INV[_b] = _a
def _sorts(name):
    body = re.search(r'def ' + name + r' : List \(Rel × RelSort\) := \[(.*?)\n\]', RO_SRC, re.S).group(1)
    return {(m.group(1), int(m.group(2)), m.group(3) == 'true'): m.group(4)
            for m in re.finditer(r'\(⟨\.(ro|bfo), (\d+), (true|false)⟩, \.(continuant|occurrent)\)', body)}
DOMAINS, RANGES = _sorts('domains'), _sorts('ranges')
def sort_of(k): return 'occurrent' if k in ('process', 'function') else 'continuant'
def accepts(r, ks, ko):
    """Rel.accepts in Claim.lean."""
    d, g = (RANGES, DOMAINS) if r[2] else (DOMAINS, RANGES); b = (r[0], r[1], False)
    return d.get(b, sort_of(ks)) == sort_of(ks) and g.get(b, sort_of(ko)) == sort_of(ko)
TARGET_KINDS = {'activity': ('protein', 'function'), 'process': ('process',), 'phenotype': ('phenotype',), 'site': ('anatomy',)}

# --- the claim a record gives, in closure-key form, plus its Lean term
def m2_reading(r):
    """What emit_lean_m2.py and closure.py read from an m2 record: (key, lean claim, entities, quant, why-not)."""
    m = r.get('m2')
    if r.get('bin') == 'not_claim' or not m or m.get('ctor') in (None, 'none'): return None, None, {}, None, 'no ctor'
    if m.get('blocker') == 'context_required': return None, None, {}, None, 'blocker context_required'
    s_, o_ = m.get('subject'), m.get('object')
    if not (s_ and o_) or kind_of(s_) is None or kind_of(o_) is None:
        return None, None, {}, None, f'emitter: no kind for {s_ if kind_of(s_) is None else o_}'
    ents = {s_: kind_of(s_), o_: kind_of(o_)}
    e = lambda c: 'e_' + re.sub(r'[^A-Za-z0-9]', '_', c)
    if m['ctor'] in ('rel', 'notRel'):
        rr = rel_of(m.get('relation'))
        if not rr: return None, None, ents, None, 'emitter: relation not in RO'
        return (m['ctor'], rr, s_, o_), f'.{m["ctor"]} {emit_lean_m3.rel_lean(rr)} {e(s_)} {e(o_)}', ents, None, None
    if m.get('sign') not in ('pos', 'neg') or m.get('target') not in ('activity', 'amount', 'process', 'phenotype', 'site'):
        return None, None, ents, None, 'emitter: effect without sign/target'
    lean = f'.effect {e(s_)} .{m["sign"]} (.{m["target"]} {e(o_)})'
    if m['ctor'] == 'mediatedBy': return None, lean, ents, None, 'closure: mediatedBy not loaded'
    return ('effect', m['sign'], m['target'], s_, o_), lean, ents, None, None

def m3_reading(root, rid):
    stmts, _, _ = emit_lean_m3.statements(str(root / 'claims_m3'), GO_NS)
    for s in stmts:
        if s['id'] != rid: continue
        ents = {c: k for c, (k, _) in s['ents'].items()}
        if s['ctor'] in ('rel', 'notRel'): key = (s['ctor'], s['rel'], s['subj'][0], s['obj'][0])
        elif s['ctor'] == 'effect': key = ('effect', s['sign'], s['target'], s['subj'][0], s['obj'][0])
        else: return None, s['claim'], ents, s['quant'], f'ctor {s["ctor"]}: not loaded by the closure'
        return key, s['claim'], ents, s['quant'], None
    return None, None, {}, None, 'emitter: skipped (m3)'

# --- detectors on one claim
def base(c): return c.split('&')[0]
def ctx_taxon(c):
    m = re.findall(r'&RO:0002162=\((NCBITaxon:\d+)', c); return m[-1] if m else None
def ends(key): return (key[3], key[4]) if key[0] == 'effect' else (key[2], key[3])

def lean_mirror(key):
    if key[0] in ('rel', 'notRel'):
        ks, ko = kind_of(key[2]), kind_of(key[3])
        if not accepts(key[1], ks, ko): return f'Rel.accepts false: {RO_LAB.get((key[1][0], key[1][1], False))} from {ks} to {ko}'
    elif key[0] == 'effect':
        ko = kind_of(key[4])
        if key[2] in TARGET_KINDS and ko not in TARGET_KINDS[key[2]]: return f'Target.{key[2]} needs {TARGET_KINDS[key[2]]}, got {ko}'
    return None

NO_TAXCON_RELS = {('ro', 1000, False), ('ro', 1001, False), ('ro', 2162, False)}   # derives from/into, in taxon: not "has X"
IN_TAXON = ('ro', 2162, False)
def taxon_claim(key, quant, source):
    """A claim about where a term occurs, 'X in_taxon T' or 'not (X in_taxon T)', against X's own constraints:
    X never_in N with T inside N contradicts 'X in_taxon T'; X only_in O, or present_in P, with O or P inside T
    contradicts 'not (X in_taxon T)'."""
    if key[0] not in ('rel', 'notRel') or key[1] != IN_TAXON or not base(key[3]).startswith('NCBITaxon:'): return []
    X, T = base(key[2]), base(key[3])
    if (source == 'GO') != (X.split(':')[0] == 'GO'): return []
    only, never, src = O.taxon_constraints(X)
    out = []
    if key[0] == 'rel' and not quant:
        out += [f'{src} never_in {O.tname(N)}; claim says in {O.tname(T)}' for N in sorted(never) if O.tax_isa(T, N)]
    if key[0] == 'notRel' and not quant:
        out += [f'{src} only_in {O.tname(X_)}; claim says never in {O.tname(T)}' for X_ in sorted(only) if O.tax_isa(X_, T)]
        out += [f'UBERON present_in {O.tname(P)}; claim says never in {O.tname(T)}' for P in sorted(O.present_in(X)) if O.tax_isa(P, T)]
    return out

DOMAINS3 = ('NCBITaxon:2', 'NCBITaxon:2157', 'NCBITaxon:2759')
def spans_scope(s):
    """Does the subject occur throughout its stated taxon? A taxon does, and so do 'cell' and 'multicellular organism';
    "photosynthesis in Eukaryota" does not (fungi do not photosynthesise), so a never_in Fungi object is no conflict."""
    b = base(s)
    return b.startswith('NCBITaxon:') or b in ('CL:0000000', 'UBERON:0000468')
def ceiling(s):
    """Where an unscoped subject can occur: its own deepest only_in (GO computed, UBERON, CL), default cellular
    organisms for GO, CL and UBERON terms, and its never_in set. None for other prefixes (no constraint data)."""
    b = base(s)
    if b.split(':')[0] not in ('GO', 'CL', 'UBERON'): return None
    only, never, _ = O.taxon_constraints(b)
    T = max(sorted(only), key=lambda t: O.tdepth(t) or 0) if only else 'NCBITaxon:131567'
    return T, never

def taxcon(key, quant, source, ceiling_scope):
    """Taxon-constraint check of 'every s r some o' against the object's constraints from `source` ('GO' or 'UB').
    Scope of the subject: a stated in_taxon context, or a taxon subject ('stated'); else, if `ceiling_scope`, where the
    subject itself can occur ('ceiling', from its own constraints). Flags: the object is only_in a clade the scope is not
    inside; or never_in a clade that contains the scope, or a sizeable part of it (universal claims only).
    is_a claims are checked on a stated scope only. some/most claims: only a disjoint only_in counts."""
    if key[0] in ('rel', 'notRel') and key[1] == IN_TAXON: return taxon_claim(key, quant, source)
    if key[0] != 'rel' or key[1] in NO_TAXCON_RELS: return []
    _, r, s, o = key
    if base(o).startswith('NCBITaxon:'): return []
    if base(s).startswith('NCBITaxon:') and r == ('ro', 1025, False): return []   # an organism located in a host: two organisms
    if (source == 'GO') != (base(o).split(':')[0] == 'GO'): return []
    o_only, o_never, src = O.taxon_constraints(base(o))
    if not (o_only or o_never): return []
    T = ctx_taxon(s) or (base(s) if base(s).startswith('NCBITaxon:') else None); mode = 'stated'
    Ns = ceiling(s)[1] if ceiling(s) else set()   # where the subject itself never occurs: no conflict there
    if T is None:
        if not ceiling_scope or r == ISA: return []
        c = ceiling(s)
        if c is None: return []
        (T, Ns), mode = c, 'ceiling'
    out = []
    excluded = lambda X: any(O.tax_isa(X, n) for n in Ns)   # the subject itself never occurs there
    for X in sorted(o_only):
        if O.tax_isa(T, X) is False:
            disjoint = O.tax_isa(X, T) is False
            if quant and not disjoint: continue
            if mode == 'ceiling' and T == 'NCBITaxon:131567' and all(excluded(d) or O.tax_isa(d, X) for d in DOMAINS3): continue
            out.append(f'{src} only_in {O.tname(X)}; scope {O.tname(T)} ({mode})' + (' [disjoint]' if disjoint else ''))
    if not quant:
        for N in sorted(o_never):
            if excluded(N): continue
            if O.tax_isa(T, N): out.append(f'{src} never_in {O.tname(N)}; scope {O.tname(T)} ({mode})')
            elif O.tax_isa(N, T) and (mode == 'ceiling' or spans_scope(s)):
                dn, dt = O.tdepth(N), O.tdepth(T)
                if dn is not None and dt is not None and dn - dt <= 4:   # a sizeable part of the scope: a universal is false
                    out.append(f'{src} never_in {O.tname(N)} (part of scope); scope {O.tname(T)} ({mode})')
    return out

PART_RELS = {('bfo', 50, False), ('bfo', 51, False), ('ro', 1025, False)}
def disjoint(key):
    out = []
    if key[0] == 'rel' and key[1] == ISA and kind_of(key[2]) != kind_of(key[3]):
        out.append(f'is_a across kinds: {kind_of(key[2])} to {kind_of(key[3])}')
    if key[0] != 'rel': return out
    s, o = base(key[2]), base(key[3]); p = s.split(':')[0]
    if p != o.split(':')[0]: return out
    on = O.onto(p)
    if on is None: return out
    if key[1] == ISA:
        sa, oa = {s} | on.anc(s), {o} | on.anc(o)
        for x in sorted(sa):
            for y in sorted(on.disj.get(x, ())):
                if y in oa: out.append(f'disjoint_from {x} {y}')
    if key[1] in PART_RELS and o in on.msd.get(s, ()): out.append(f'spatially disjoint {s} {o}')
    return out

def obsolete(key):
    out = []
    for c in ends(key):
        for part in re.findall(r'[A-Za-z]+:\d+', c):
            on = O.onto(part.split(':')[0])
            if on and part in on.obs: out.append(f'obsolete {part} ({on.name.get(part)}), replaced_by {on.repl.get(part)}')
    return out

def onto_refutes(key):
    """ontology_says of scripts/search/holes.py, applied to a statement."""
    if key[0] != 'rel' or key[1] not in (ISA, ('bfo', 50, False), ('bfo', 51, False)): return None
    x, y = (key[3], key[2]) if key[1] == ('bfo', 51, False) else (key[2], key[3]); x, y = base(x), base(y)
    p = x.split(':')[0]
    if p != y.split(':')[0] or p not in ('GO', 'UBERON', 'CL', 'CHEBI'): return None
    on = O.onto(p)
    if x not in on.name or y not in on.name or x in on.obs or y in on.obs: return None
    rel = 'is_a' if key[1] == ISA else 'part_of'
    if on.reaches(x, y, rel): return None
    if on.reaches(y, x, rel): return f'refuted: reverse {rel} holds in {p}'
    return f'refuted: not a subclass in {p}' if rel == 'is_a' else None

def pattern(key): return None if not key or key[0] == 'effect' else (key[1], kind_of(key[2]), kind_of(key[3]))
def mode(key, modes, self_key=None):
    """Leave-one-out: the pattern must occur in some loaded statement other than the base statement itself."""
    pat = pattern(key)
    if pat is None: return None
    n = modes.get(pat, 0) - (1 if self_key is not None and pattern(self_key) == pat else 0)
    return None if n > 0 else f'unseen pattern: {RO_LAB.get((key[1][0], key[1][1], False))} from {pat[1]} to {pat[2]}'

IRREG = {'mitochondria': 'mitochondrion', 'nuclei': 'nucleus', 'bacteria': 'bacterium', 'cilia': 'cilium', 'flagella': 'flagellum',
         'ganglia': 'ganglion', 'stomata': 'stoma', 'teeth': 'tooth', 'mice': 'mouse', 'vertebrae': 'vertebra', 'alveoli': 'alveolus',
         'villi': 'villus', 'fungi': 'fungus', 'nucleoli': 'nucleolus', 'plasmodesmata': 'plasmodesma', 'leaves': 'leaf'}
STOP = {'the', 'a', 'an', 'of', 'in', 'and', 'or', 'to', 'cell', 'process', 'activity', 'structure', 'type'}
def norm(t):
    t = re.sub(r'[^a-z0-9+ ]', ' ', t.lower().replace('-', ' ').replace('_', ' '))
    out = []
    for w in t.split():
        if w in IRREG: w = IRREG[w]
        elif len(w) > 4 and w.endswith('ies'): w = w[:-3] + 'y'
        elif len(w) > 3 and w.endswith('s') and not w.endswith(('ss', 'us', 'is')): w = w[:-1]
        out.append(w)
    return ' '.join(out)
def label_lint(curie, text):
    """Mention text shares no content word with the label or any synonym (after plural folding)."""
    on = O.onto(curie.split(':')[0])
    if on is None or curie not in on.name or not text: return None
    names = {on.name[curie]} | on.syn.get(curie, set())
    raw_t = set(norm(text).split())
    tw = raw_t - STOP
    nw = set(' '.join(norm(n) for n in names).split()) - STOP
    if not tw or tw & nw: return None
    if not set(norm(on.name[curie]).split()) - STOP and set(norm(on.name[curie]).split()) <= raw_t: return None   # label "cell", text "animal cell"
    return f'text "{text}" vs {curie} "{on.name[curie]}"'

# --- prototype of option C (a core change): finer relation signatures than Rel.accepts' BFO sorts
ROLE = 'CHEBI:50906'
def is_role(c):
    b = base(c); on = O.onto('CHEBI')
    return b.startswith('CHEBI:') and (b == ROLE or ROLE in on.anc(b))
def kind2(c):
    """BioLean's kind, with ChEBI roles split from chemicals (a new Kind constructor in option C)."""
    return 'role' if is_role(c) else kind_of(c)
SAME_SORT = {('bfo', 50, False), ('bfo', 51, False), ('ro', 2131, False)}             # part of, has part, overlaps (BFO)
OBJ_KINDS = {('ro', 2327, False): {'function'},                                       # enables: a molecular function
             ('ro', 2215, False): {'process', 'function'},                            # capable of
             ('ro', 87, False): {'role'},                                             # has role
             ('ro', 2162, False): {'taxon'}}                                          # in taxon
def finer_sig(key):
    """None if the claim fits the finer signature; else why not. Effects are not checked (Target already is)."""
    if key[0] not in ('rel', 'notRel'): return None
    r, s, o = key[1], key[2], key[3]; ks, ko = kind2(s), kind2(o)
    if ks is None or ko is None: return None
    if r == ISA and ks != ko: return f'is_a across kinds: {ks} to {ko}'
    if r in SAME_SORT and sort_of(ks) != sort_of(ko): return f'{RO_LAB.get(r)} joins a {sort_of(ks)} to an {sort_of(ko)}'
    if r in OBJ_KINDS and ko not in OBJ_KINDS[r]: return f'{RO_LAB.get(r)} needs {sorted(OBJ_KINDS[r])}, got {ko}'
    # Not checked: a role used as a class of molecules with other relations ("the testes secrete androgens"). ChEBI's
    # design forbids it, readers accept it; 34 live statements do it beyond the 12 flagged here (13 relations, 21 effects;
    # recounted by the 2026-11-01 review, the first version said 18). A convention to decide, not an error check.
    return None

def static(key, quant, txt, modes, self_key=None):
    out = {'lean_mirror': lean_mirror(key), 'sig': finer_sig(key),
           'taxon_lint': None,   # Statement.taxonConsistent: textbook evidence carries no taxon, so it is always true
           'go_tax': taxcon(key, quant, 'GO', False), 'ub_tax': taxcon(key, quant, 'UB', False),
           'go_tax_c': taxcon(key, quant, 'GO', True), 'ub_tax_c': taxcon(key, quant, 'UB', True),
           'disjoint': disjoint(key), 'obsolete': obsolete(key), 'onto_refutes': onto_refutes(key), 'mode': mode(key, modes, self_key)}
    lab = []
    for c in ends(key):
        b = base(c)
        if b in txt:
            x = label_lint(b, txt[b])
            if x: lab.append(x)
    out['label'] = lab
    return out

# --- mutation operators
ISA_T = O.ISA_TERMS
def label(c):
    on = O.onto(c.split(':')[0]); return (on.name.get(c) if on else None) or ISA_T.get(c, {}).get('label') or c
SWAP = {'NCBITaxon:33208': 'NCBITaxon:33090', 'NCBITaxon:33090': 'NCBITaxon:33208', 'NCBITaxon:2': 'NCBITaxon:2157',
        'NCBITaxon:2157': 'NCBITaxon:2', 'NCBITaxon:9606': 'NCBITaxon:10090', 'NCBITaxon:10090': 'NCBITaxon:9606',
        'NCBITaxon:40674': 'NCBITaxon:8782', 'NCBITaxon:2759': 'NCBITaxon:2', 'NCBITaxon:1117': 'NCBITaxon:33090',
        'NCBITaxon:6040': 'NCBITaxon:7742', 'NCBITaxon:7742': 'NCBITaxon:6040'}
OPS = ['E1_context_dropped', 'E2_quantifier_strengthened', 'E3_subject_too_general', 'E4_direction_reversed',
       'E5_wrong_curie_same_kind', 'E6_wrong_kind', 'E7_sign_flipped', 'E8_taxon_swapped', 'E9_obsolete_term', 'E10_negation_lost']
_USED = None
def used_curies():
    global _USED
    if _USED is None:
        _USED = set()
        for (d, n), recs in FILES.items():
            for r in recs:
                for f in ('m2', 'm3'):
                    m = r.get(f) or {}
                    _USED |= {m.get('subject'), m.get('object')}
        _USED.discard(None)
    return _USED
def general(c):
    """'cell' for a CL cell type; else the nearest is_a ancestor that the textbook uses elsewhere."""
    if c.startswith('CL:') and c != 'CL:0000000': return 'CL:0000000'
    seen, frontier = {c}, [c]
    while frontier:
        nxt = []
        for x in frontier:
            for p in ISA_T.get(x, {}).get('parents', []):
                if p in seen: continue
                seen.add(p); nxt.append(p)
                if p in used_curies() and p.split(':')[0] == c.split(':')[0]: return p
        frontier = nxt
def adjacent(c):
    """A live id a few digits away, of the same kind: a digit slip (area postrema UBERON:0002162 -> 0002163)."""
    p, n = c.split(':'); on = O.onto(p)
    if not on or not n.isdigit(): return None
    for d in (1, -1, 2, -2, 3, -3, 4, -4, 5, -5):
        x = f'{p}:{int(n) + d:0{len(n)}d}'
        if x in on.name and x not in on.obs and kind_of(x) == kind_of(c): return x
_NAMES = None
def other_kind(c):
    """A term of another kind named after this one: centriole -> centriole assembly."""
    global _NAMES
    if _NAMES is None:
        _NAMES = {}
        for p in ('GO', 'CL', 'UBERON', 'CHEBI'):
            on = O.onto(p)
            for t, nm in on.name.items():
                if t not in on.obs: _NAMES.setdefault(nm.lower(), t)
    L, k = label(c).lower(), kind_of(c)
    for cand in (L, f'{L} organization', f'{L} assembly', f'{L} development', f'{L} formation', f'{L} metabolic process',
                 f'{L} biosynthetic process', f'{L} transport', f'{L} binding', f'{L} activity', f'{L} morphogenesis', f'regulation of {L}'):
        t = _NAMES.get(cand)
        if t and kind_of(t) and kind_of(t) != k: return t
def obsolete_alias(c):
    on = O.onto(c.split(':')[0])
    if not on: return None
    olds = sorted(o for o in on.inv_repl.get(c, []) if o in on.obs)
    return olds[0] if olds else None

def apply(op, rid):
    """(field, mutated annotation, note) or None if the operator does not apply to this record."""
    f = active(rid); r = record(f, rid); a = copy.deepcopy(r[f]); ctx = a.get('context') or {}
    if not isinstance(ctx, dict): ctx = {}
    s, o, ctor = a.get('subject'), a.get('object'), a.get('ctor')
    if op == 'E1_context_dropped':
        live = {k: v for k, v in ctx.items() if v and not (k == 'taxon' and v == s)}
        if f != 'm3' or not live: return None
        a['context'] = {k: None for k in ctx}; return f, a, f'context {live} dropped'
    if op == 'E2_quantifier_strengthened':
        if a.get('quant') not in ('some', 'most'): return None
        note = f"quantifier {a['quant']} dropped (now every)"; a['quant'] = None; return f, a, note
    if op == 'E3_subject_too_general':
        g = general(s) if s else None
        if not g or g == s: return None
        a['subject'] = g; return f, a, f'subject {s} ({label(s)}) -> {g} ({label(g)})'
    if op == 'E4_direction_reversed':
        if ctor not in ('rel', 'notRel'): return None
        rr = rel_of(a.get('relation'))
        if rr and rr in INV:
            old = a['relation']; a['relation'] = RO_LAB[INV[rr]]
            return f, a, f"relation {old} -> {a['relation']}, same order (as round 1 did for m45432-261)"
        a['subject'], a['object'] = o, s; return f, a, f"subject and object swapped ({a.get('relation')})"
    if op == 'E5_wrong_curie_same_kind':
        tgt = 'object' if o and not o.startswith('NCBITaxon') else 'subject'
        x = adjacent(a[tgt]) if a.get(tgt) else None
        if not x: return None
        note = f'{tgt} {a[tgt]} ({label(a[tgt])}) -> {x} ({label(x)})'; a[tgt] = x; return f, a, note
    if op == 'E6_wrong_kind':
        tgt = 'object' if o and not o.startswith('NCBITaxon') else 'subject'
        x = other_kind(a[tgt]) if a.get(tgt) else None
        if not x: return None
        note = f'{tgt} {a[tgt]} ({label(a[tgt])}, {kind_of(a[tgt])}) -> {x} ({label(x)}, {kind_of(x)})'; a[tgt] = x; return f, a, note
    if op == 'E7_sign_flipped':
        if ctor not in ('effect', 'mediatedBy') or a.get('sign') not in ('pos', 'neg'): return None
        a['sign'] = 'neg' if a['sign'] == 'pos' else 'pos'; return f, a, f"sign -> {a['sign']}"
    if op == 'E8_taxon_swapped':
        t = ctx.get('taxon')
        if t and t in SWAP:
            a['context'] = dict(ctx, taxon=SWAP[t])
            if s == t: a['subject'] = SWAP[t]
            return f, a, f'context taxon {t} ({O.tname(t)}) -> {SWAP[t]} ({O.tname(SWAP[t])})'
        for tgt in ('subject', 'object'):
            if a.get(tgt) in SWAP:
                note = f'{tgt} {a[tgt]} ({O.tname(a[tgt])}) -> {SWAP[a[tgt]]} ({O.tname(SWAP[a[tgt]])})'; a[tgt] = SWAP[a[tgt]]
                return f, a, note
        return None
    if op == 'E9_obsolete_term':
        for tgt in ('object', 'subject'):
            x = obsolete_alias(a.get(tgt) or '')
            if x:
                note = f'{tgt} {a[tgt]} ({label(a[tgt])}) -> obsolete {x} ({label(x)})'; a[tgt] = x; return f, a, note
        return None
    if op == 'E10_negation_lost':
        if ctor != 'notRel': return None
        a['ctor'] = 'rel'; return f, a, 'notRel -> rel'
    raise ValueError(op)

def reading(field, root, rid, rec):
    return m3_reading(root, rid) if field == 'm3' else m2_reading(rec)
