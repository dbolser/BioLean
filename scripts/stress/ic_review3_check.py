"""Program 07, reviewer's independent check (2026-10-31). Run from the repo root, isolated, because it parses downloads:

    python3 -I scripts/stress/ic_review3_check.py

Independent of ic_verify_round3.py: no fuzzy matching. For each reference in the doc's References table it prints
the registry's own title, first author surname and year beside the doc's, and marks a match only when the surname is
equal (case and accents folded), the year is equal, and the doc's title words are all in the registry title.
CURIEs: every CURIE in the doc, in SOURCES of ic_analysis.py and in sheet_cases.tsv is looked up on OLS4 (label,
obsolete). GO:0000785 is also looked up on QuickGO for taxon constraints.
Downloads are cached in /tmp/biolean-07/review3/ (data only). Outputs: data/stress/07/review3_refs.tsv,
data/stress/07/review3_curies.tsv. Read-only GETs; nothing is posted. Exits 1 on any mismatch.
"""
import json, os, re, sys, time, unicodedata, urllib.parse, urllib.request

DOC = 'docs/programs/07-triviality-threshold.md'
CACHE = '/tmp/biolean-07/review3'
OUT = 'data/stress/07'
UA = {'User-Agent': 'BioLean-stress-07-review/1.0 (read-only)', 'Accept': 'application/json'}
CURIE = re.compile(r'\b(GO|UBERON|CL|CHEBI|NCBITaxon|RO|PR|PO|MONDO|PATO|SO|HP|OBA|BFO):(\d+)\b')
REF = re.compile(r'^\| ([^|]+?) (\d{4}), "([^"]+)", ([^|]+?) \| ([^|]+?) \| (doi:\S+|PMID:\d+) \|$')
OLS_ONTO = {'GO': 'go', 'UBERON': 'uberon', 'CL': 'cl', 'CHEBI': 'chebi', 'NCBITaxon': 'ncbitaxon', 'RO': 'ro',
            'PR': 'pr', 'PO': 'po', 'MONDO': 'mondo', 'PATO': 'pato', 'SO': 'so', 'HP': 'hp', 'OBA': 'oba', 'BFO': 'bfo'}


def get(url, name):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, re.sub(r'[^A-Za-z0-9_.-]', '_', name))
    if not os.path.exists(path):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40) as r: data = r.read()
        except Exception as e:  # noqa: BLE001
            data = json.dumps({'_error': str(e)}).encode()
        with open(path, 'wb') as fh: fh.write(data)
        time.sleep(0.25)
    with open(path, encoding='utf-8') as fh:
        try: return json.load(fh)
        except ValueError: return {'_error': 'not json'}


def fold(s):
    s = unicodedata.normalize('NFKD', s or '')
    return re.sub(r'[^a-z0-9]+', ' ', ''.join(c for c in s if not unicodedata.combining(c)).lower()).strip()


def crossref(doi):
    d = get('https://api.crossref.org/works/' + urllib.parse.quote(doi, safe='/'), 'crossref_' + doi).get('message', {})
    au = (d.get('author') or [{}])[0]
    yr = None
    for k in ('published-print', 'published-online', 'issued', 'published'):
        p = (d.get(k) or {}).get('date-parts')
        if p and p[0] and p[0][0]: yr = p[0][0]; break
    title = ': '.join([' '.join(d.get('title') or [])] + [x for x in d.get('subtitle') or [] if x])
    return title, au.get('family', ''), yr, ' '.join(d.get('container-title') or [])


def epmc(pmid):
    q = urllib.parse.quote(f'EXT_ID:{pmid} AND SRC:MED')
    d = get(f'https://www.ebi.ac.uk/europepmc/webservices/rest/search?query={q}&format=json&resultType=core',
            'epmc_' + pmid)
    r = ((d.get('resultList') or {}).get('result') or [{}])[0]
    au = ((r.get('authorList') or {}).get('author') or [{}])[0]
    return r.get('title', ''), au.get('lastName', ''), int(r['pubYear']) if r.get('pubYear') else None, \
        (r.get('journalInfo') or {}).get('journal', {}).get('title', '')


def ols(curie):
    pre = curie.split(':')[0]
    iri = 'http://purl.obolibrary.org/obo/' + curie.replace(':', '_')
    enc = urllib.parse.quote(urllib.parse.quote(iri, safe=''), safe='')
    for onto in dict.fromkeys([OLS_ONTO[pre], 'ro']):  # BFO relations (part of, occurs in) are served by RO
        for kind in ('terms', 'properties'):
            d = get(f'https://www.ebi.ac.uk/ols4/api/ontologies/{onto}/{kind}/{enc}', f'ols_{onto}_{kind}_{curie}')
            if d.get('label'): return d['label'], d.get('is_obsolete', False)
    return None, None


def main():
    bad = []
    doc = open(DOC, encoding='utf-8').read()
    rows = [['ref', 'id', 'doc_surname', 'doc_year', 'doc_title', 'reg_surname', 'reg_year', 'reg_title', 'reg_journal',
             'match']]
    for line in doc.splitlines():
        m = REF.match(line.strip())
        if not m: continue
        who, yr, title, _, _, ident = m.groups()
        t, sur, y, j = crossref(ident[4:]) if ident.startswith('doi:') else epmc(ident[5:])
        words = set(fold(title).split())
        ok = fold(who) == fold(sur) and y == int(yr) and words <= set(fold(t).split())
        rows.append([f'{who} {yr}', ident, who, yr, title, sur, y, t, j, 'yes' if ok else 'NO'])
        if not ok: bad.append(f'ref {who} {yr} {ident}: registry says {sur} {y} "{t}"')
    with open(os.path.join(OUT, 'review3_refs.tsv'), 'w', encoding='utf-8') as fh:
        for r in rows: fh.write('\t'.join(str(x).replace('\t', ' ') for x in r) + '\n')
    src = open('scripts/stress/ic_analysis.py', encoding='utf-8').read()
    src = src[src.index('SOURCES = {'):src.index('SOURCE_TRUTH = {')]
    sheet = open(os.path.join(OUT, 'sheet_cases.tsv'), encoding='utf-8').read()
    where = {}
    for name, text in (('doc', doc), ('SOURCES', src), ('sheet_cases', sheet)):
        for m in CURIE.finditer(text): where.setdefault(m.group(0), set()).add(name)
    crow = [['curie', 'where', 'ols4_label', 'obsolete']]
    for c in sorted(where):
        lab, obs = ols(c)
        crow.append([c, ','.join(sorted(where[c])), lab or 'NOT FOUND', obs])
        if lab is None: bad.append(f'curie {c} not found on OLS4')
    with open(os.path.join(OUT, 'review3_curies.tsv'), 'w', encoding='utf-8') as fh:
        for r in crow: fh.write('\t'.join(str(x) for x in r) + '\n')
    qg = get('https://www.ebi.ac.uk/QuickGO/services/ontology/go/terms/GO:0000785/constraints', 'quickgo_GO_0000785')
    cons = [(x.get('relationship'), x.get('taxIdType'), x.get('taxId'), x.get('taxName'))
            for r in qg.get('results', []) for x in r.get('taxonConstraints', [])]
    print(f'references: {len(rows) - 1}; match {sum(r[-1] == "yes" for r in rows[1:])}')
    print(f'CURIEs: {len(crow) - 1}; found {sum(r[2] != "NOT FOUND" for r in crow[1:])}; obsolete: '
          + ', '.join(r[0] for r in crow[1:] if r[3] is True))
    print('QuickGO taxon constraints on GO:0000785 chromatin:', cons or qg.get('_error') or 'none listed')
    for b in bad: print('PROBLEM', b)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
