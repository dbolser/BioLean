"""Program 04, independent review: re-check every identifier the program cites, without reusing mutants_verify.py.

Run from the repo root:  python3 -I scripts/stress/mutants_review.py {curies|refs|quotes|inherit|counts}
Downloads go to /tmp/biolean-04/review_dl2/ (fresh for the 2026-11-01 pass; treated as untrusted data, parsed as JSON only).
  curies  every CURIE in the program's files (doc, Lean, cases, bases, judgements, live samples, emitted Lean names)
          looked up on OLS4: label, obsolete, replaced_by. Also every "CURIE (label)" or 'CURIE "label"' pair the
          files state is compared with the OLS4 label.                       -> data/stress/04/review_curies.tsv
  refs    every PMID and DOI the program's files cite (plus the doc's reference list), on Europe PMC (EXT_ID
          search) and Crossref: title, first author, year                    -> data/stress/04/review_refs.tsv
  quotes  every textbook statement id the doc and the curated cases cite: does it exist in data/textbook/claims*,
          and is each quoted sentence a substring of its claim or source text   -> data/stress/04/review_quotes.tsv
  inherit option C0: inherit RO rdfs:domain / rdfs:range down rdfs:subPropertyOf -> data/stress/04/review_inherit.tsv
  counts  the ontology-file counts the doc states (uberon.obo taxon axioms, CL terms, disjoint pairs, never_in for
          calcareous tooth)                                                   -> data/stress/04/review_counts.tsv"""
import sys, json, re, glob, time, pathlib, urllib.request, urllib.parse, concurrent.futures
sys.path.insert(0, '/home/danbolser/Build/BioLean/scripts/stress')

REPO = pathlib.Path('/home/danbolser/Build/BioLean')
DL = pathlib.Path('/tmp/biolean-04/review_dl2'); (DL / 'ols').mkdir(parents=True, exist_ok=True); (DL / 'refs').mkdir(parents=True, exist_ok=True)
OUT = REPO / 'data/stress/04'
UA = {'User-Agent': 'BioLean-program04-review/0.1 (read-only lookups)'}
FILES = ['docs/programs/04-annotation-errors.md', 'BioLean/Stress/AnnotationErrors.lean', 'data/stress/04/cases.tsv',
         'data/stress/04/bases.tsv', 'data/stress/04/judgements.tsv', 'data/stress/04/baseline_judged.tsv',
         'data/stress/04/lean/MutantsEmitted.lean']
# NCBITaxon ids can be short (NCBITaxon:2 is Bacteria); the first version needed 4 digits and missed them
PAT = re.compile(r'\b(GO|UBERON|CL|CHEBI|NCBITaxon|RO|PR|BFO|PATO|SO)[:_](\d{4,}|(?<=NCBITaxon[:_])\d{1,3})\b')

def get(url):
    err = None
    for i in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40) as r: return r.read()
        except Exception as e:
            err = e; time.sleep(1 + 2 * i)
    return json.dumps({'error': str(err)}).encode()

def all_curies():
    out = {}
    for f in FILES:
        for m in PAT.finditer((REPO / f).read_text()):
            c = f'{m.group(1)}:{m.group(2)}'
            out.setdefault(c, set()).add(f.split('/')[-1])
    return out

def ols(c):
    p = DL / 'ols' / (c.replace(':', '_') + '.json')
    if p.exists():
        try:
            d = json.loads(p.read_text())
            if '_embedded' in d: return d
        except Exception: pass
    pre = c.split(':')[0]
    o = {'NCBITaxon': 'ncbitaxon', 'BFO': 'ro'}.get(pre, pre.lower())
    kind = 'properties' if pre in ('RO', 'BFO') else 'terms'
    raw = get(f'https://www.ebi.ac.uk/ols4/api/ontologies/{o}/{kind}?obo_id={urllib.parse.quote(c)}')
    if b'_embedded' not in raw and kind == 'properties':
        iri = 'http://purl.obolibrary.org/obo/' + c.replace(':', '_')
        raw = get(f'https://www.ebi.ac.uk/ols4/api/ontologies/ro/properties?iri={urllib.parse.quote(iri, safe="")}')
    p.write_bytes(raw)
    try: return json.loads(raw)
    except Exception: return {}

def term(c):
    d = ols(c); ts = [t for k in ('terms', 'properties') for t in (d.get('_embedded') or {}).get(k, [])]
    ts = [t for t in ts if t.get('obo_id') == c or t.get('iri', '').endswith('/' + c.replace(':', '_'))]
    return next((t for t in ts if t.get('is_defining_ontology')), ts[0] if ts else None)

def norm(s): return re.sub(r'[^a-z0-9]+', ' ', (s or '').lower()).strip()

def curies():
    cs = all_curies()
    with concurrent.futures.ThreadPoolExecutor(4) as ex: list(ex.map(ols, sorted(cs)))
    info = {c: term(c) for c in sorted(cs)}
    # stated labels: CURIE (label) and CURIE "label" in the files
    stated = []
    for f in FILES:
        if f.endswith('MutantsEmitted.lean'): continue      # its entity labels are the curies themselves
        txt = (REPO / f).read_text()
        if f.endswith('.lean'):   # Entity literals: ⟨"CURIE", "label"⟩
            pairs = [(m.group(1), m.group(2)) for m in re.finditer(r'⟨"([A-Za-z]+:\d{4,})", "([^"]+)"⟩', txt)]
        else:                     # prose: CURIE (label) or CURIE "label"
            pairs = [(m.group(1), m.group(2) or m.group(3)) for m in
                     re.finditer(r'\b((?:GO|UBERON|CL|CHEBI|NCBITaxon|RO|PR|BFO):\d{4,}) (?:\(([A-Za-z][^(),;=]{1,60})\)|"([A-Za-z][^"]{1,60})")', txt)]
        stated += [(c, lab.strip(), f.split('/')[-1]) for c, lab in pairs]
    out = ['# curie\tOLS4 label\tobsolete\treplaced_by\tontology\tstatus (OLS4, review 2026-10-31)\tcited in']
    bad = []
    for c, t in info.items():
        if not t: out.append(f'{c}\t\t\t\t\tNOT FOUND\t{",".join(sorted(cs[c]))}'); bad.append(c); continue
        rep = (t.get('annotation') or {}).get('term replaced by') or ''
        rep = ','.join(rep) if isinstance(rep, list) else rep
        out.append(f'{c}\t{t.get("label")}\t{t.get("is_obsolete")}\t{rep}\t{t.get("ontology_name")}\t'
                   + ('obsolete' if t.get('is_obsolete') else 'live') + f'\t{",".join(sorted(cs[c]))}')
    out.append('# stated label check: CURIE (label) or CURIE "label" in the program files, against OLS4 label and synonyms')
    seen = set(); nmis = 0
    for c, lab, f in stated:
        if (c, lab) in seen or c not in info or not info[c]: continue
        seen.add((c, lab)); t = info[c]
        names = {norm(t.get('label'))} | {norm(s) for s in (t.get('synonyms') or [])}
        l2 = norm(lab.replace('obsolete ', ''))
        ok = l2 in names or any(l2 in n or n in l2 for n in names if n) or norm(c) == l2
        if not ok:
            nmis += 1; out.append(f'{c}\tstated "{lab}"\t\t\t\tLABEL DIFFERS from OLS4 "{t.get("label")}"\t{f}')
    (OUT / 'review_curies.tsv').write_text('\n'.join(out) + '\n')
    n_obs = sum(1 for t in info.values() if t and t.get('is_obsolete'))
    print(f'curies {len(cs)}; not found {len(bad)} {bad}; obsolete {n_obs}; stated labels checked {len(seen)}, differing {nmis}')

REFS = [('PMID', '19730686'), ('PMID', '20973947'), ('PMID', '22293552'), ('PMID', '15892874'),
        ('PMID', '26467479'), ('PMID', '36699362'), ('DOI', '10.1109/C-M.1978.218136'), ('DOI', '10.1109/TSE.2010.62'),
        ('PMID', '28070906'), ('PMID', '3706773'), ('PMID', '10210685'), ('PMID', '36367380')]   # last four added by the 2026-11-01 review
def cited_ids():
    """Every PMID and DOI written in the program's files, so nothing cited escapes the check."""
    got = set(REFS)
    for f in FILES:
        t = (REPO / f).read_text()
        got |= {('PMID', m) for m in re.findall(r'PMID[: ]?(\d{6,8})\b', t)}
        got |= {('DOI', m.rstrip('.,;)')) for m in re.findall(r'doi:(10\.\d{4,}/[^\s|`]+)', t)}
    return sorted(got)
def refs():
    out = ['# id\ttitle\tfirst author\tyear\tjournal\tsource (review 2026-11-01, fresh lookups)']
    for kind, x in cited_ids():
        p = DL / 'refs' / (re.sub(r'[^A-Za-z0-9]+', '_', x) + '.json')
        if kind == 'PMID':
            if not p.exists():
                p.write_bytes(get('https://www.ebi.ac.uk/europepmc/webservices/rest/search?format=json&resultType=core&query='
                                  + urllib.parse.quote(f'EXT_ID:{x} AND SRC:MED')))
            res = json.loads(p.read_text()).get('resultList', {}).get('result', [])
            if not res: out.append(f'PMID:{x}\t\t\t\t\tNOT FOUND'); continue
            r = res[0]; fa = ((r.get('authorList') or {}).get('author') or [{}])[0]
            jn = ((r.get('journalInfo') or {}).get('journal') or {}).get('title', '')
            out.append(f'PMID:{x}\t{r.get("title")}\t{fa.get("lastName", fa.get("collectiveName", ""))} {fa.get("initials", "")}\t{r.get("pubYear")}\t{jn}\tEurope PMC')
        else:
            if not p.exists(): p.write_bytes(get('https://api.crossref.org/works/' + urllib.parse.quote(x)))
            try: m = json.loads(p.read_text())['message']
            except Exception: out.append(f'doi:{x}\t\t\t\t\tNOT FOUND'); continue
            a = (m.get('author') or [{}])[0]
            out.append(f'doi:{x}\t{(m.get("title") or [""])[0]}\t{a.get("family", "")} {a.get("given", "")}\t'
                       f'{((m.get("issued") or {}).get("date-parts") or [[""]])[0][0]}\t{(m.get("container-title") or [""])[0]}\tCrossref')
    (OUT / 'review_refs.tsv').write_text('\n'.join(out) + '\n'); print('\n'.join(out))

def quotes():
    recs = {}
    for p in glob.glob(str(REPO / 'data/textbook/claims*/*.json')):
        try: data = json.load(open(p))
        except Exception: continue
        if not isinstance(data, list): continue
        for r in data:
            if isinstance(r, dict) and r.get('id'):
                d = recs.setdefault(r['id'], {'claim': set(), 'source': set()})
                d['claim'].add(r.get('claim') or ''); d['source'].add(r.get('source') or '')
    texts = [(f, (REPO / f).read_text()) for f in ('docs/programs/04-annotation-errors.md', 'BioLean/Stress/AnnotationErrors.lean')]
    hdr, *rows = [l.rstrip('\n').split('\t') for l in open(OUT / 'cases.tsv') if l.strip()]
    texts += [('cases.tsv ' + r[0], r[2]) for r in rows if not re.match(r'B\d\d-', r[0])]
    out = ['# where\tstatement id\tquoted sentence\tfound (claim or source text)']
    idp = re.compile(r'\b((?:cell-structure-and-function|photosynthesis|the-body-s-systems|molbio|how-cells-obtain-energy|'
                     r'reproduction-at-the-cellular-level)-m\d+-\d+|m\d{5}-\d+)\b')
    nbad = 0
    for where, t in texts:
        for m in idp.finditer(t):
            sid = m.group(1)
            full = [k for k in recs if k == sid or k.endswith('-' + sid)]
            # the quoted sentence, if any, right after the id: id "..."  (cases.tsv and the Lean file use this form)
            q = re.match(r'\s*\)?\s*"([^"\n]{5,200})"', t[m.end():])   # no newline: an id's own closing quote is not a quote
            if not full: out.append(f'{where}\t{sid}\t\tID NOT FOUND'); nbad += 1; continue
            if q:
                qs = q.group(1)
                hay = ' '.join(x for k in full for x in recs[k]['claim'] | recs[k]['source']).lower()
                ok = qs.lower().rstrip('.') in hay
                if not ok: nbad += 1
                out.append(f'{where}\t{sid}\t{qs}\t{"yes" if ok else "NOT VERBATIM"}')
            else:
                out.append(f'{where}\t{sid}\t\tid exists')
    # every double-quoted phrase of 3+ words in the doc: verbatim in some textbook claim or source sentence, or not
    # (not = a paraphrase, a synthetic case, a label or an annotation written as words; each is checked by eye)
    hay_all = ' '.join(x for d in recs.values() for x in d['claim'] | d['source']).lower()
    doc = (REPO / 'docs/programs/04-annotation-errors.md').read_text()
    for q in sorted(set(re.findall(r'"([^"\n]{8,200})"', doc))):
        if len(q.split()) < 3: continue
        out.append(f'doc phrase\t\t{q}\t' + ('textbook verbatim' if q.lower().rstrip('.') in hay_all else 'not in the textbook'))
    (OUT / 'review_quotes.tsv').write_text('\n'.join(sorted(set(out), key=lambda l: (not l.startswith('#'), l))) + '\n')
    print(f'quote checks: {len(out) - 1}, problems {nbad}')

OCC = {'BFO_0000015', 'BFO_0000003', 'BFO_0000035', 'GO_0008150', 'GO_0003674', 'BFO_0000144'}
CONT = ('BFO_0000040', 'BFO_0000004', 'BFO_0000002', 'BFO_0000030', 'UBERON', 'CL_', 'CHEBI', 'PR_', 'COB', 'OGMS', 'NCBITaxon', 'PATO',
        'BFO_0000020', 'BFO_0000017', 'BFO_0000031', 'BFO_0000141', 'CARO', 'PO_', 'ENVO')
def ro_sort(c): return 'occurrent' if c in OCC else ('continuant' if c.startswith(CONT) else None)
def inherit():
    """Option C0: what if RO domain and range were inherited down rdfs:subPropertyOf at import (OWL semantics)?
    RO.lean takes only a relation's own rdfs:domain and rdfs:range, so enables (a sub-property of capable_of, which has
    both) gets none, and Rel.accepts lets any kinds through. Counts the live statements and mutants this would reject."""
    import mutants_lib as L
    owl = (REPO / 'data/ro.owl').read_text(encoding='utf-8')
    sup, dom, rng = {}, {}, {}
    for m in re.finditer(r'<owl:ObjectProperty rdf:about="http://purl.obolibrary.org/obo/((?:RO|BFO)_\d+)">(.*?)</owl:ObjectProperty>', owl, re.S):
        rid, body = m.group(1), m.group(2)
        sup[rid] = re.findall(r'<rdfs:subPropertyOf rdf:resource="http://purl.obolibrary.org/obo/((?:RO|BFO)_\d+)"', body)
        d = [ro_sort(x) for x in re.findall(r'<rdfs:domain rdf:resource="http://purl.obolibrary.org/obo/([A-Za-z]+_\d+)"', body)]
        g = [ro_sort(x) for x in re.findall(r'<rdfs:range rdf:resource="http://purl.obolibrary.org/obo/([A-Za-z]+_\d+)"', body)]
        if [x for x in d if x]: dom[rid] = [x for x in d if x][0]
        if [x for x in g if x]: rng[rid] = [x for x in g if x][0]
    def up(rid, tab, seen=()):
        if rid in tab: return tab[rid]
        for p in sup.get(rid, []):
            if p not in seen:
                x = up(p, tab, seen + (rid,))
                if x: return x
        return None
    key = lambda r: f"{r[0].upper()}_{r[1]:07d}"
    # sanity: own sorts as parsed here against RO.lean's
    own_ok = sum(1 for r, v in L.DOMAINS.items() if not r[2] and dom.get(key(r)) == v)
    own_n = sum(1 for r in L.DOMAINS if not r[2])
    def accepts2(r, ks, ko):
        b = key(r); d, g = up(b, dom), up(b, rng)
        if r[2]: d, g = g, d
        return (d is None or d == L.sort_of(ks)) and (g is None or g == L.sort_of(ko))
    L.ensure_copy(); L.load_records(); ns0, _, _ = L.run_closure(L.CLAIMS)
    gained = sorted({key(r) for r in [k[1] for k in ns0['asserted'] if k[0] in ('rel', 'notRel')] if r[0] != 'rdfs'
                     and (key(r) not in dom or key(r) not in rng) and (up(key(r), dom) != dom.get(key(r)) or up(key(r), rng) != rng.get(key(r)))})
    live = [(ns0['sid_of'].get(k), k) for k in ns0['asserted'] if k[0] in ('rel', 'notRel') and k[1][0] != 'rdfs'
            and L.accepts(k[1], L.kind_of(k[2]), L.kind_of(k[3])) and not accepts2(k[1], L.kind_of(k[2]), L.kind_of(k[3]))]
    rows = json.load(open(OUT / 'mutants.json'))
    judge = {l.split('\t')[0]: l.split('\t')[1] for l in open(OUT / 'judgements.tsv') if l.strip() and not l.startswith('#')}
    mut = []
    for r in rows:
        k = r.get('key')
        if not k or k[0] not in ('rel', 'notRel') or k[1][0] == 'rdfs': continue
        rr = tuple(k[1]); ks, ko = L.kind_of(k[2]), L.kind_of(k[3])
        if L.accepts(rr, ks, ko) and not accepts2(rr, ks, ko): mut.append((r['mid'], judge.get(r['mid'], 'false' if r['op'] != 'E0_control' else 'true'), r['note'][:90]))
    out = [f'# option C0: inherit RO rdfs:domain / rdfs:range down rdfs:subPropertyOf (review 2026-11-01)',
           f'# own domains parsed here matching RO.lean: {own_ok} of {own_n}',
           f'# relations used in the live data that gain a sort by inheritance: {len(gained)}: {" ".join(gained)}',
           f'# live statements newly rejected: {len(live)}; mutants and controls newly rejected (beyond Rel.accepts today): {len(mut)}']
    out += [f'live\t{sid}\t{k}' for sid, k in sorted(live, key=str)] + [f'mutant\t{m}\t{j}\t{n}' for m, j, n in mut]
    (OUT / 'review_inherit.tsv').write_text('\n'.join(out) + '\n'); print('\n'.join(out[:4])); print('\n'.join(out[4:30]))

def counts():
    """The ontology-file numbers the doc states, recomputed from the cached OBO files."""
    import collections
    import mutants_lib as L
    out = ['# what\tcount\tfile (review 2026-11-01)']
    ub = open('/tmp/obo/uberon.obo', encoding='utf-8').read()
    c = collections.Counter(m.group(1) for m in re.finditer(r'^relationship: (in_taxon|RO:0002160|never_in_taxon) NCBITaxon', ub, re.M))
    out += [f'uberon.obo relationship {k}\t{v}\t/tmp/obo/uberon.obo' for k, v in sorted(c.items())]
    blocks = re.split(r'\n\n(?=\[)', ub)
    cl = [b for b in blocks if re.match(r'\[Term\]\nid: CL:\d+', b)]
    cl_tax = [b for b in cl if re.search(r'^relationship: (in_taxon|RO:0002160|never_in_taxon) ', b, re.M)]
    out.append(f'CL terms carried by uberon.obo\t{len(cl)}\t/tmp/obo/uberon.obo')
    out.append(f'of these, with a taxon axiom of their own\t{len(cl_tax)}\t/tmp/obo/uberon.obo')
    tooth = next(b for b in blocks if b.startswith('[Term]\nid: UBERON:0001091\n'))
    for l in tooth.split('\n'):
        if 'never_in_taxon' in l or 'taxon_notes' in l: out.append(f'UBERON:0001091 {l.strip()}\t\t/tmp/obo/uberon.obo')
    L.ensure_copy(); L.load_records(); used = L.used_curies(); pairs = set()
    for p in ('GO', 'UBERON', 'CL', 'CHEBI'):
        on = L.O.onto(p); u = {x for x in used if x and x.startswith(p + ':')}
        pairs |= {tuple(sorted((x, y))) for x in u for y in on.disj.get(x, ()) if y in u}
    out.append(f'disjoint_from pairs with both terms used in rounds 2 and 3\t{len(pairs)}\tOBO files')
    (OUT / 'review_counts.tsv').write_text('\n'.join(out) + '\n'); print('\n'.join(out))

if __name__ == '__main__':
    {'curies': curies, 'refs': refs, 'quotes': quotes, 'inherit': inherit, 'counts': counts}[sys.argv[1]]()
