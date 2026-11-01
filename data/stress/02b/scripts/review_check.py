"""Program 02b, second review: an independent re-check of identifiers, fetched fresh (not from the first run's cache).

1. Every CURIE in data/stress/02b/curies.tsv (and the two PATO terms the doc names for E7) on OLS4: exists, not obsolete,
   label. 2. Every reference in the doc's table (section 10) on Europe PMC (PMID) or Crossref (DOI): first author and
   year as the doc states them, and the title as refs.tsv has it.
Downloads go to /tmp/biolean-02b/review/dl/ (untrusted; run with python3 -I). Writes nothing in the repo.
Usage (repo root): python3 -I data/stress/02b/scripts/review_check.py
"""
import json, re, pathlib, urllib.request, urllib.parse, time, csv, html

DL = pathlib.Path('/tmp/biolean-02b/review/dl'); DL.mkdir(parents=True, exist_ok=True)

def get(url, name):
    f = DL / name
    if not f.exists() or f.stat().st_size == 0:
        try:
            with urllib.request.urlopen(url, timeout=40) as r: f.write_bytes(r.read())
        except Exception as e: f.write_text(json.dumps({'error': str(e)}))
        time.sleep(0.12)
    try: return json.loads(f.read_text())
    except Exception as e: return {'error': f'unreadable {e}'}

ONTO = {'NCBITaxon': 'ncbitaxon', 'OBA': 'oba', 'BFO': 'ro'}
def ols(curie):
    pre = curie.split(':')[0]; onto = ONTO.get(pre, pre.lower())
    if pre in ('RO', 'BFO'):
        url = f'https://www.ebi.ac.uk/ols4/api/ontologies/{onto}/properties?' + urllib.parse.urlencode({'iri': 'http://purl.obolibrary.org/obo/' + curie.replace(':', '_')})
    elif pre == 'TEDDY':
        url = f'https://www.ebi.ac.uk/ols4/api/ontologies/teddy/terms?' + urllib.parse.urlencode({'short_form': curie.replace(':', '_')})
    else:
        url = f'https://www.ebi.ac.uk/ols4/api/ontologies/{onto}/terms?' + urllib.parse.urlencode({'obo_id': curie})
    d = get(url, 'ols_' + re.sub(r'[^A-Za-z0-9]', '_', curie) + '.json')
    ts = (d.get('_embedded') or {}).get('terms') or (d.get('_embedded') or {}).get('properties') or []
    if not ts: return None
    t = ([t for t in ts if t.get('is_defining_ontology')] or ts)[0]
    return t.get('label'), bool(t.get('is_obsolete'))

def doc_refs():
    text = pathlib.Path('docs/programs/02b-feedback-loops.md').read_text()
    sec = text.split('## 10. References')[1].split('## 11.')[0]
    out = []
    for m in re.finditer(r'^\| (\S+) \| ([^|]+?),? (\d{4}) \|', sec, re.M):
        out.append((m.group(1), m.group(2).strip(), int(m.group(3))))
    return out

def main():
    bad = 0
    rows = list(csv.DictReader(open('data/stress/02b/curies.tsv'), delimiter='\t'))
    curies = [r['curie'] for r in rows if not r['curie'].startswith('BLN:')] + ['PATO:0000389', 'PATO:0001863']
    for c in curies:
        r = ols(c)
        if r is None or r[1]: print('CURIE', c, 'NOT OK', r); bad += 1
        elif c.startswith('PATO:00003') or c.startswith('PATO:00018'): print('CURIE', c, 'label', repr(r[0]))
    print(f'{len(curies)} CURIEs fetched fresh from OLS4')
    refs = doc_refs()
    for ident, au, year in refs:
        if ident.startswith('10.'):
            d = get('https://api.crossref.org/works/' + urllib.parse.quote(ident), 'cr_' + re.sub(r'[^A-Za-z0-9]', '_', ident) + '.json').get('message', {})
            first = (d.get('author') or [{}])[0].get('family', ''); y = ((d.get('issued') or {}).get('date-parts') or [[None]])[0][0]
            title = (d.get('title') or [''])[0]
        else:
            d = get('https://www.ebi.ac.uk/europepmc/webservices/rest/search?' + urllib.parse.urlencode({'query': f'EXT_ID:{ident} AND SRC:MED', 'format': 'json'}), f'epmc_{ident}.json')
            r = (d.get('resultList', {}).get('result') or [{}])[0]
            first = (r.get('authorString') or '').split(',')[0]; y = int(r['pubYear']) if r.get('pubYear') else None; title = r.get('title', '')
        ok = au.split()[0].lower().replace('-', '') in first.lower().replace('-', '') and y == year
        if not ok: bad += 1
        print('REF', 'OK ' if ok else 'BAD', ident, '| doc:', au, year, '| source:', first, y, '|', title[:90])
    print(f'{len(refs)} references checked; not OK: {bad}')
    # 3. every quote in refs.tsv verbatim in the abstract, fetched fresh
    nq = qbad = 0
    for r in csv.DictReader(open('data/stress/02b/refs.tsv'), delimiter='\t'):
        if r['id'].startswith('10.') or not r['quotes']: continue
        d = get('https://www.ebi.ac.uk/europepmc/webservices/rest/search?' + urllib.parse.urlencode({'query': f"EXT_ID:{r['id']} AND SRC:MED", 'format': 'json', 'resultType': 'core'}), f"core_{r['id']}.json")
        res = (d.get('resultList', {}).get('result') or [{}])[0]
        ab = re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', res.get('abstractText') or ''))).strip()
        for q in r['quotes'].split(' | '):
            nq += 1
            if q not in ab: qbad += 1; print('QUOTE NOT FOUND', r['key'], repr(q))
    print(f'{nq} quotes checked against fresh abstracts; not found: {qbad}')

if __name__ == '__main__': main()
