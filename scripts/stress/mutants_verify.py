"""Program 04: read-only lookups. OLS4 for every CURIE the doc and cases cite (label, obsolete, synonyms), ChEBI synonyms
for the label lint (chebi_lite.obo has none), and Europe PMC for every paper cited.

Run from the repo root:  python3 -I scripts/stress/mutants_verify.py {chebi|curies|refs}
Downloads go to /tmp/biolean-04/dl/ (cached; treated as untrusted data, parsed as JSON only).
  chebi   fetch OLS4 records for every CHEBI curie in the round-2/3 claims  -> /tmp/biolean-04/dl/ols/
  curies  check every CURIE listed in data/stress/04/curies_cited.txt     -> data/stress/04/curies_checked.tsv
  refs    check every paper in data/stress/04/refs_cited.tsv            -> data/stress/04/refs_checked.tsv"""
import sys, json, re, glob, time, pathlib, urllib.request, urllib.parse, concurrent.futures

REPO = pathlib.Path('/home/danbolser/Build/BioLean')
DL = pathlib.Path('/tmp/biolean-04/dl'); (DL / 'ols').mkdir(parents=True, exist_ok=True); (DL / 'epmc').mkdir(parents=True, exist_ok=True)
OUT = REPO / 'data/stress/04'
OLS = 'https://www.ebi.ac.uk/ols4/api/ontologies/{o}/{kind}?obo_id={c}'
UA = {'User-Agent': 'BioLean-program04/0.1 (read-only lookups)'}

def get(url):
    for i in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r: return r.read()
        except Exception as e:
            err = e; time.sleep(1 + i)
    return json.dumps({'error': str(err)}).encode()

def ols_path(c): return DL / 'ols' / (c.replace(':', '_') + '.json')
def ols_fetch(c, refresh=False):
    p = ols_path(c)
    if p.exists() and not refresh:
        try:
            d = json.loads(p.read_text())
            if '_embedded' in d: return d
        except Exception: pass
    pre = c.split(':')[0]
    kind = 'properties' if pre in ('RO', 'BFO') else 'terms'
    o = {'NCBITaxon': 'ncbitaxon', 'BFO': 'ro'}.get(pre, pre.lower())
    raw = get(OLS.format(o=o, kind=kind, c=urllib.parse.quote(c)))
    if kind == 'properties' and b'_embedded' not in raw:   # some BFO relations resolve only by IRI
        iri = 'http://purl.obolibrary.org/obo/' + c.replace(':', '_')
        raw = get(f'https://www.ebi.ac.uk/ols4/api/ontologies/ro/properties?iri={urllib.parse.quote(iri, safe="")}')
    p.write_bytes(raw)
    try: return json.loads(raw)
    except Exception: return {}

def ols_term(c):
    d = ols_fetch(c)
    for key in ('terms', 'properties'):
        for t in (d.get('_embedded') or {}).get(key, []):
            if t.get('obo_id') == c and t.get('is_defining_ontology', True): return t
        for t in (d.get('_embedded') or {}).get(key, []):
            if t.get('obo_id') == c: return t
        for t in (d.get('_embedded') or {}).get(key, []):
            if t.get('iri', '').endswith('/' + c.replace(':', '_')): return t
    return None

def chebi():
    curies = set()
    for p in glob.glob(str(REPO / 'data/textbook/claims_m[23]/*.json')):
        for r in json.load(open(p)):
            for f in ('m2', 'm3'):
                m = r.get(f) or {}
                for x in (m.get('subject'), m.get('object')):
                    if x and x.startswith('CHEBI:'): curies.add(x)
    rows = json.load(open(OUT / 'mutants.json')) if (OUT / 'mutants.json').exists() else []
    for r in rows: curies |= {c for c in (r.get('ents') or {}) if c.startswith('CHEBI:')}
    with concurrent.futures.ThreadPoolExecutor(4) as ex: list(ex.map(ols_fetch, sorted(curies)))
    syn = {}
    for c in sorted(curies):
        t = ols_term(c)
        if t: syn[c] = sorted(set(t.get('synonyms') or []))
    (DL / 'chebi_synonyms.json').write_text(json.dumps(syn, indent=0))
    print(f'ChEBI curies {len(curies)}, with OLS4 records {len(syn)}, with synonyms {sum(1 for v in syn.values() if v)}')

def curies():
    want = [l.split('\t')[0].strip() for l in open(OUT / 'curies_cited.txt') if l.strip() and not l.startswith('#')]
    with concurrent.futures.ThreadPoolExecutor(4) as ex: list(ex.map(ols_fetch, want))
    out = ['# curie\tOLS4 label\tobsolete\treplaced_by\tontology\tstatus (checked on OLS4 2026-10-31)']
    for c in want:
        t = ols_term(c)
        if not t: out.append(f'{c}\t\t\t\t\tNOT FOUND'); continue
        rep = (t.get('annotation') or {}).get('term replaced by') or ''
        out.append(f'{c}\t{t.get("label")}\t{t.get("is_obsolete")}\t{",".join(rep) if isinstance(rep, list) else rep}\t{t.get("ontology_name")}\t'
                   + ('obsolete' if t.get('is_obsolete') else 'live'))
    (OUT / 'curies_checked.tsv').write_text('\n'.join(out) + '\n')
    print('\n'.join(out))

def refs():
    out = ['# key\tquery\tfound title\tfirst author\tyear\tjournal\tpmid\tdoi\tstatus (Europe PMC 2026-10-31)']
    for l in open(OUT / 'refs_cited.tsv'):
        if not l.strip() or l.startswith('#'): continue
        key, query, want_title, want_author = (l.rstrip('\n').split('\t') + ['', '', ''])[:4]
        if query.startswith('doi:'):   # Crossref, for papers outside Europe PMC
            doi = query[4:]; p = DL / 'epmc' / ('crossref_' + re.sub(r'[^A-Za-z0-9]+', '_', doi) + '.json')
            if not p.exists(): p.write_bytes(get('https://api.crossref.org/works/' + urllib.parse.quote(doi)))
            try: m = json.loads(p.read_text())['message']
            except Exception: out.append(f'{key}\t{query}\t\t\t\t\t\t{doi}\tNOT FOUND'); continue
            title = (m.get('title') or [''])[0]; fa = ((m.get('author') or [{}])[0]).get('family', '')
            yr = str(((m.get('issued') or {}).get('date-parts') or [['']])[0][0]); jn = (m.get('container-title') or [''])[0]
            ok = want_title.lower()[:40] in title.lower() and (not want_author or want_author.lower() == fa.lower())
            out.append('\t'.join([key, query, title, fa, yr, jn, '', doi, 'verified (Crossref)' if ok else 'MISMATCH'])); continue
        p = DL / 'epmc' / (re.sub(r'[^A-Za-z0-9]+', '_', key) + '.json')
        if not p.exists():
            p.write_bytes(get('https://www.ebi.ac.uk/europepmc/webservices/rest/search?format=json&resultType=core&pageSize=5&query=' + urllib.parse.quote(query)))
        try: res = json.loads(p.read_text()).get('resultList', {}).get('result', [])
        except Exception: res = []
        hit = None
        for r in res:
            t = (r.get('title') or '').lower()
            if want_title and want_title.lower()[:40] in t: hit = r; break
        hit = hit or (res[0] if res else None)
        if not hit: out.append(f'{key}\t{query}\t\t\t\t\t\t\tNOT FOUND'); continue
        fa = ((hit.get('authorList') or {}).get('author') or [{}])[0].get('lastName', '')
        ok = (not want_title or want_title.lower()[:40] in (hit.get('title') or '').lower()) and (not want_author or want_author.lower() == fa.lower())
        out.append('\t'.join([key, query, hit.get('title', ''), fa, str(hit.get('pubYear', '')), (hit.get('journalInfo') or {}).get('journal', {}).get('title', '') if isinstance(hit.get('journalInfo'), dict) else '',
                              str(hit.get('pmid', '')), hit.get('doi', ''), 'verified' if ok else 'MISMATCH']))
    (OUT / 'refs_checked.tsv').write_text('\n'.join(out) + '\n')
    print('\n'.join(out))

DOC_CURIES = """GO:0005813 GO:0005814 CL:0000000 NCBITaxon:33208 NCBITaxon:33090 NCBITaxon:40674 UBERON:0001091 NCBITaxon:9761
NCBITaxon:9259 NCBITaxon:9257 NCBITaxon:8782 RO:0001000 RO:0001001 GO:0005739 NCBITaxon:2 PR:000009054 PR:000050339 PR:000020310
UBERON:0002162 UBERON:0002163 CL:0002371 CL:0000548 CL:0000003 GO:0009579 GO:0009534 GO:0009507 GO:0019253 GO:0009570 CHEBI:28966
CHEBI:26130 CHEBI:50906 RO:0000087 GO:0009289 CL:0000520 GO:0045277 GO:0022904 GO:0048492 GO:0015977 RO:0002327 GO:0034362
CHEBI:16113 UBERON:0000468 CL:0010017 BFO:0000050 BFO:0000051 UBERON:0002420 UBERON:0000045 UBERON:0000955 UBERON:0002240
NCBITaxon:2157 NCBITaxon:2759 NCBITaxon:131567 NCBITaxon:1117 NCBITaxon:9606 NCBITaxon:10090 RO:0002162 RO:0002160 RO:0002161
RO:0002175 RO:0001025 BFO:0000066 RO:0002215 GO:0000228 GO:0005694 GO:0006260 GO:0140014 UBERON:0000113 GO:0035639""".split()

def collect():
    """Every curie in the mutation test (entities of every control and mutant) plus the ones the doc cites."""
    rows = json.load(open(OUT / 'mutants.json'))
    cs = set(DOC_CURIES)
    for r in rows: cs |= {c for c in (r.get('ents') or {}) if re.match(r'^[A-Za-z]+:\d+$', c)}
    cs = {c for c in cs if c.split(':')[0] in ('GO', 'CL', 'UBERON', 'CHEBI', 'PR', 'NCBITaxon', 'RO', 'BFO', 'PATO', 'SO', 'PO')}
    (OUT / 'curies_cited.txt').write_text('# every CURIE program 04 cites (mutants.json entities and the doc); checked by mutants_verify.py curies\n' + '\n'.join(sorted(cs)) + '\n')
    print(len(cs), 'curies')

if __name__ == '__main__':
    {'chebi': chebi, 'collect': collect, 'curies': curies, 'refs': refs}[sys.argv[1]]()
