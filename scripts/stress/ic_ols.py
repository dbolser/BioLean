"""Check CURIEs on OLS4 (read-only lookups). Program 07.

Usage: python3 -I scripts/stress/ic_ols.py <curies.txt> <out.tsv> [--ancestors]
Raw OLS4 replies are cached in /tmp/biolean-07/ols/ and treated as untrusted data (parsed as JSON only).
Writes one row per CURIE: curie, ontology, label, obsolete, found; with --ancestors also the defining ontology's
hierarchical ancestors (is_a plus part_of and other hierarchical properties) as a ';'-joined CURIE list.
"""
import json, os, sys, time, urllib.error, urllib.parse, urllib.request

CACHE = '/tmp/biolean-07/ols'
API = 'https://www.ebi.ac.uk/ols4/api'
ONT = {'GO': 'go', 'UBERON': 'uberon', 'CL': 'cl', 'CHEBI': 'chebi', 'NCBITaxon': 'ncbitaxon', 'RO': 'ro', 'BFO': 'bfo',
       'PR': 'pr', 'MONDO': 'mondo', 'SO': 'so', 'PATO': 'pato', 'HP': 'hp', 'PO': 'po'}


def get(url, path):
    if not os.path.exists(path):
        req = urllib.request.Request(url, headers={'Accept': 'application/json', 'User-Agent': 'biolean-stress-07'})
        with urllib.request.urlopen(req, timeout=60) as r: data = r.read()
        with open(path, 'wb') as fh: fh.write(data)
        time.sleep(0.2)
    with open(path, 'rb') as fh: return json.loads(fh.read().decode('utf-8'))


def lookup(curie, ancestors=False):
    pre = curie.split(':')[0]; ont = ONT.get(pre)
    if not ont: return (curie, '', '', '', 'no ontology mapped', '')
    safe = curie.replace(':', '_')
    try: d = get(f'{API}/ontologies/{ont}/terms?obo_id={urllib.parse.quote(curie)}', f'{CACHE}/{safe}.json')
    except urllib.error.HTTPError:
        if pre not in ('RO', 'BFO'): raise
        d = {}
    terms = (d.get('_embedded') or {}).get('terms') or []
    if not terms and pre in ('RO', 'BFO'):   # relations are properties, not classes
        d = get(f'{API}/ontologies/ro/properties?obo_id={urllib.parse.quote(curie)}', f'{CACHE}/{safe}.prop.json')
        terms = (d.get('_embedded') or {}).get('properties') or []
        if terms: return (curie, 'ro', terms[0].get('label', ''), str(terms[0].get('is_obsolete', '')), 'yes', '')
    if not terms: return (curie, ont, '', '', 'not found', '')
    t = terms[0]; anc = ''
    if ancestors:
        iri = urllib.parse.quote(urllib.parse.quote(t['iri'], safe=''), safe='')
        a = get(f'{API}/ontologies/{ont}/terms/{iri}/hierarchicalAncestors?size=500', f'{CACHE}/{safe}.anc.json')
        anc = ';'.join(sorted(x.get('obo_id') or x['iri'] for x in (a.get('_embedded') or {}).get('terms', [])))
    return (curie, ont, t.get('label', ''), str(t.get('is_obsolete', '')), 'yes', anc)


if __name__ == '__main__':
    os.makedirs(CACHE, exist_ok=True)
    src, out = sys.argv[1], sys.argv[2]; anc = '--ancestors' in sys.argv
    curies = [l.strip() for l in open(src, encoding='utf-8') if l.strip() and not l.startswith('#')]
    rows = [('curie', 'ontology', 'label', 'obsolete', 'found', 'hierarchical_ancestors' if anc else '')]
    for c in curies:
        try: rows.append(lookup(c, anc))
        except Exception as e: rows.append((c, '', '', '', f'error {type(e).__name__}', ''))
    with open(out, 'w', encoding='utf-8') as fh:
        for r in rows: fh.write('\t'.join(r) + '\n')
    print(f'{len(curies)} looked up; found {sum(1 for r in rows[1:] if r[4] == "yes")}')
