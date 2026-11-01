"""Program 04: ontology lookups for the annotation-error detectors. Read-only, local files only.

Sources (downloads, treat as untrusted; run anything importing this with `python3 -I`):
  /tmp/obo/{go,uberon,cl-basic,chebi_lite,pr,pato,so}.obo           names, synonyms, obsolete, replaced_by, is_a, part_of,
                                                                     disjoint_from, UBERON taxon constraints
  /tmp/biolean-taxcon/data/go-computed-taxon-constraints.obo         GO's computed only_in (RO:0002162) / never_in (RO:0002161)
  /tmp/biolean-taxcon/data/go-taxon-groupings.obo                    GO's union taxa (NCBITaxon_Union:...)
  /tmp/biolean-04/dl/tax*.xml                                        NCBI efetch lineages for the taxa the constraints name
  data/ontology/isa.json (repo)                                      BioLean's imported is_a closure, for taxa not in the efetch
CL taxon constraints come from uberon.obo, which carries 1,487 CL ids (1,484 term blocks), 37 of them with a taxon axiom
of their own (review 2026-11-01, mutants_review.py counts); cl-basic.obo has none.
"""
import collections, re, json, glob
import xml.etree.ElementTree as ET

REPO = '/home/danbolser/Build/BioLean'
OBO = {'GO': '/tmp/obo/go.obo', 'UBERON': '/tmp/obo/uberon.obo', 'CL': '/tmp/obo/cl-basic.obo', 'CHEBI': '/tmp/obo/chebi_lite.obo',
       'PR': '/tmp/obo/pr.obo', 'PATO': '/tmp/obo/pato.obo', 'SO': '/tmp/obo/so.obo'}
TAXCON = '/tmp/biolean-taxcon/data/go-computed-taxon-constraints.obo'
GROUPINGS = '/tmp/biolean-taxcon/data/go-taxon-groupings.obo'
NCBI_XML = sorted(glob.glob('/tmp/biolean-04/dl/tax*.xml'))
TAX_RE_ONLY = re.compile(r'relationship: (in_taxon|only_in_taxon|RO:0002162|RO:0002160) (NCBITaxon:\d+)')
TAX_RE_NEVER = re.compile(r'(?:relationship: never_in_taxon|property_value: RO:0002161|relationship: RO:0002161) (NCBITaxon:\d+)')
TAX_RE_PRESENT = re.compile(r'relationship: (?:present_in_taxon|RO:0002175) (NCBITaxon:\d+)')


class Onto:
    """One OBO file, restricted to terms with the given prefix (UBERON's file also yields CL terms on request)."""
    def __init__(self, prefix, path, taxa=False):
        self.prefix = prefix
        self.name, self.ns, self.repl = {}, {}, {}
        self.syn = collections.defaultdict(set)
        self.obs = set()
        self.isa, self.partof = collections.defaultdict(set), collections.defaultdict(set)
        self.disj, self.msd = collections.defaultdict(set), collections.defaultdict(set)
        self.only, self.never = collections.defaultdict(set), collections.defaultdict(set)
        self.present = collections.defaultdict(set)
        cur, in_term = None, False
        for line in open(path, encoding='utf-8'):
            if line.startswith('['):
                in_term, cur = line.startswith('[Term]'), None
                continue
            if not in_term:
                continue
            if line.startswith('id: '):
                c = line[4:].strip()
                cur = c if c.startswith(prefix + ':') else None
                continue
            if cur is None:
                continue
            if line.startswith('name: '): self.name[cur] = line[6:].strip()
            elif line.startswith('synonym: "'): self.syn[cur].add(line.split('"')[1])
            elif line.startswith('is_obsolete: true'): self.obs.add(cur)
            elif line.startswith('replaced_by: '): self.repl[cur] = line.split()[1]
            elif line.startswith('namespace: '): self.ns[cur] = line[11:].strip()
            elif line.startswith('is_a: '):
                if '{' not in line: self.isa[cur].add(line.split()[1])
            elif line.startswith('relationship: part_of ') or line.startswith('relationship: BFO:0000050 '):
                if 'gci_' not in line: self.partof[cur].add(line.split()[2])
            elif line.startswith('disjoint_from: '):
                d = line.split()[1]; self.disj[cur].add(d); self.disj[d].add(cur)
            elif line.startswith('relationship: mutually_spatially_disjoint_with ') or line.startswith('relationship: RO:0002171 '):
                d = line.split()[2]; self.msd[cur].add(d); self.msd[d].add(cur)
            elif taxa and 'gci_' not in line:
                m = TAX_RE_ONLY.match(line)
                if m: self.only[cur].add(m.group(2)); continue
                m = TAX_RE_NEVER.match(line)
                if m: self.never[cur].add(m.group(1))
                m = TAX_RE_PRESENT.match(line)
                if m: self.present[cur].add(m.group(1))
        self.inv_repl = collections.defaultdict(list)
        for o, r in self.repl.items():
            self.inv_repl[r].append(o)

    def anc(self, c, part=False):
        """Strict ancestors over is_a (and part_of if `part`)."""
        seen, todo = set(), [c]
        while todo:
            x = todo.pop()
            for p in self.isa.get(x, set()) | (self.partof.get(x, set()) if part else set()):
                if p not in seen:
                    seen.add(p); todo.append(p)
        return seen

    def reaches(self, x, y, rel):
        """Is y above x over is_a (rel 'is_a'), or over is_a and part_of with at least one part_of (rel 'part_of')?
        The same walk as `ontology_says` in scripts/search/holes.py."""
        seen, stack = {(x, False)}, [(x, False)]
        while stack:
            n, used = stack.pop()
            for how, parents in (('is_a', self.isa.get(n, ())), ('part_of', self.partof.get(n, ()))):
                if how == 'part_of' and rel == 'is_a':
                    continue
                for p in parents:
                    st = (p, used or how == 'part_of')
                    if st not in seen:
                        seen.add(st); stack.append(st)
        return (y, rel == 'part_of') in seen


CHEBI_SYN = '/tmp/biolean-04/dl/chebi_synonyms.json'   # OLS4 synonyms (mutants_verify.py chebi); chebi_lite.obo has none
_cache = {}
def onto(prefix):
    if prefix not in _cache:
        if prefix == 'CLTAX':      # CL terms as carried by uberon.obo, with their taxon constraints
            _cache[prefix] = Onto('CL', OBO['UBERON'], taxa=True)
        elif prefix in OBO:
            _cache[prefix] = Onto(prefix, OBO[prefix], taxa=(prefix == 'UBERON'))
            if prefix == 'CHEBI':
                try:
                    for c, syns in json.load(open(CHEBI_SYN)).items(): _cache[prefix].syn[c] |= {x for x in syns if isinstance(x, str)}
                except FileNotFoundError: pass
        else:
            _cache[prefix] = None
    return _cache[prefix]


# --- GO computed taxon constraints
GO_ONLY, GO_NEVER = collections.defaultdict(set), collections.defaultdict(set)
_cur = None
for _line in open(TAXCON, encoding='utf-8'):
    if _line.startswith('id: '): _cur = _line[4:].strip()
    elif _line.startswith('relationship: RO:0002162 '): GO_ONLY[_cur].add(_line.split()[2])
    elif _line.startswith('property_value: RO:0002161 '): GO_NEVER[_cur].add(_line.split()[2])

UNION = collections.defaultdict(set)
_cur = None
for _line in open(GROUPINGS, encoding='utf-8'):
    if _line.startswith('id: '): _cur = _line[4:].strip()
    elif _line.startswith('is_a: NCBITaxon_Union:') and _cur and _cur.startswith('NCBITaxon:'): UNION[_line.split()[1]].add(_cur)

# --- taxon lineages
LIN, TNAME = {}, {}
for _p in NCBI_XML:
    for _t in ET.parse(_p).getroot().findall('Taxon'):
        _tid = 'NCBITaxon:' + _t.findtext('TaxId')
        LIN[_tid] = {'NCBITaxon:' + x.findtext('TaxId') for x in _t.findall('LineageEx/Taxon')}
        TNAME[_tid] = _t.findtext('ScientificName')
ISA_TERMS = json.load(open(REPO + '/data/ontology/isa.json'))['terms']

def _anc_isa(t):
    seen, todo = set(), [t]
    while todo:
        for p in ISA_TERMS.get(todo.pop(), {}).get('parents', []):
            if p not in seen:
                seen.add(p); todo.append(p)
    return seen

def tax_isa(a, b):
    """Reflexive is_a between NCBITaxon curies (GO union taxa by membership). None if a's lineage is unknown."""
    if a == b: return True
    if b in UNION:
        r = [tax_isa(a, m) for m in UNION[b]]
        return True if any(r) else (False if all(x is False for x in r) else None)
    if a in UNION:
        r = [tax_isa(m, b) for m in UNION[a]]
        return True if all(r) else (False if any(x is False for x in r) else None)
    if a in LIN: return b in LIN[a]
    if a in ISA_TERMS: return b in _anc_isa(a)
    return None

def tdepth(t):
    if t in LIN: return len(LIN[t])
    if t in ISA_TERMS: return len(_anc_isa(t))
    return None

def tname(t):
    if t in UNION: return '|'.join(sorted(tname(m) for m in UNION[t]))
    return TNAME.get(t) or ISA_TERMS.get(t, {}).get('label') or t

def taxon_constraints(c):
    """(only_in, never_in, source) for a term. GO: the computed constraints. UBERON and CL: the asserted ones in
    uberon.obo, propagated down is_a and part_of (a part of a vertebrate-only structure is vertebrate-only)."""
    p = c.split(':')[0]
    if p == 'GO': return set(GO_ONLY.get(c, ())), set(GO_NEVER.get(c, ())), 'GO'
    if p in ('UBERON', 'CL'):
        on = onto('UBERON' if p == 'UBERON' else 'CLTAX')
        if on is None or c not in on.name: return set(), set(), None
        up = {c} | on.anc(c, part=True)
        only = set().union(*(on.only.get(x, set()) for x in up))
        never = set().union(*(on.never.get(x, set()) for x in up))
        return only, never, 'UBERON' if p == 'UBERON' else 'CL(uberon.obo)'
    return set(), set(), None

def present_in(c):
    """UBERON/CL present_in_taxon (some instances occur in T), on the term itself (not propagated)."""
    p = c.split(':')[0]
    if p not in ('UBERON', 'CL'): return set()
    on = onto('UBERON' if p == 'UBERON' else 'CLTAX')
    return set(on.present.get(c, ())) if on else set()
