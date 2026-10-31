"""Independent review check (2026-10-30) of program 07: every CURIE and every PMID or DOI the doc and its case files cite.

Usage (from the repo root): python3 -I scripts/stress/ic_review_verify.py
Reads (never writes): docs/programs/07-triviality-threshold.md, data/stress/07/sheet_cases.tsv, cases.tsv,
analysis_terms_near_cut.tsv. Looks each CURIE up on OLS4 (label, obsolete, start of the definition). Looks each PMID up
on Europe PMC and each DOI on Crossref (title, first author, year), and compares them with the doc's reference table.
Raw replies are cached in /tmp/biolean-07/review/cache/ (fresh: not the author's cache) and parsed as JSON only.
Writes data/stress/07/review_curies.tsv and data/stress/07/review_refs.tsv. Exits 1 if a CURIE is not found or a
reference in the doc's table does not match on first author and year (title words checked too).
"""
import json, os, re, sys, time, unicodedata, urllib.error, urllib.parse, urllib.request

D = 'data/stress/07'
DOC = 'docs/programs/07-triviality-threshold.md'
CACHE = '/tmp/biolean-07/review/cache'
UA = {'User-Agent': 'BioLean-review/0.1 (read-only lookups)'}
CURIE = re.compile(r'\b(GO|UBERON|CL|CHEBI|NCBITaxon|RO|BFO|PR|MONDO|SO|PATO|HP|PO|OBA):([A-Za-z0-9_]+)\b')
ONTO = {'NCBITaxon': 'ncbitaxon', 'BFO': 'ro'}   # BFO relations live in RO's import


def fetch(url, name):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, re.sub(r'[^A-Za-z0-9._-]', '_', name)[:180] + '.json')
    if os.path.exists(path):
        return json.load(open(path, encoding='utf-8'))
    for attempt in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
                data = json.loads(r.read().decode('utf-8'))
            json.dump(data, open(path, 'w', encoding='utf-8'))
            time.sleep(0.15)
            return data
        except urllib.error.HTTPError as e:
            if e.code == 404: return None
            time.sleep(1 + attempt)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
            time.sleep(1 + attempt)
    return None


def ols(curie):
    pre, loc = curie.split(':')
    onto = ONTO.get(pre, pre.lower())
    iri = f'http://purl.obolibrary.org/obo/{pre}_{loc}'
    q = urllib.parse.quote(urllib.parse.quote(iri, safe=''), safe='')
    for kind in ('terms', 'properties'):
        d = fetch(f'https://www.ebi.ac.uk/ols4/api/ontologies/{onto}/{kind}/{q}', f'ols_{onto}_{kind}_{curie}')
        if d and d.get('label'):
            desc = d.get('description') or []
            return dict(found='yes', ontology=onto, kind=kind, label=d['label'], obsolete=str(bool(d.get('is_obsolete'))),
                        definition=' | '.join(desc)[:300])
    return dict(found='NO', ontology=onto, kind='', label='', obsolete='', definition='')


def norm(s):
    s = unicodedata.normalize('NFKD', s or '').encode('ascii', 'ignore').decode().lower()
    return re.sub(r'[^a-z0-9 ]', ' ', s)


def epmc(pmid):
    d = fetch('https://www.ebi.ac.uk/europepmc/webservices/rest/search?format=json&resultType=core&query=' +
              urllib.parse.quote(f'EXT_ID:{pmid} AND SRC:MED'), f'epmc_{pmid}')
    res = (d or {}).get('resultList', {}).get('result', [])
    if not res: return None
    r = res[0]
    al = (r.get('authorList') or {}).get('author') or []
    first = al[0].get('lastName') or al[0].get('fullName', '') if al else (r.get('authorString') or '').split(' ')[0]
    return dict(title=r.get('title', ''), first=first, year=str(r.get('pubYear', '')), doi=r.get('doi', ''))


def crossref(doi):
    d = fetch('https://api.crossref.org/works/' + urllib.parse.quote(doi, safe=''), f'cr_{doi}')
    m = (d or {}).get('message')
    if not m: return None
    au = m.get('author') or []
    first = (au[0].get('family') or au[0].get('name') or '') if au else ''
    yr = ''
    for k in ('published-print', 'published', 'issued', 'published-online'):
        p = (m.get(k) or {}).get('date-parts')
        if p and p[0] and p[0][0]: yr = str(p[0][0]); break
    title = ': '.join([' '.join(m.get('title') or [])] + (m.get('subtitle') or [])[:1])
    return dict(title=title, first=first, year=yr, doi=m.get('DOI', ''))


def doc_refs():
    """Rows of the doc's 'References (checked)' table: (cited text, first author, year, title, ids)."""
    txt = open(DOC, encoding='utf-8').read()
    sec = txt.split('## References (checked)')[1].split('\n## ')[0]
    out = []
    for ln in sec.splitlines():
        m = re.match(r'\| (?P<au>[^|]+?) (?P<yr>\d{4}), "(?P<ti>[^"]+)", [^|]*\| [^|]*\| (?P<ids>[^|]+) \|', ln)
        if m: out.append((ln.split('|')[1].strip(), m.group('au').split()[0], m.group('yr'), m.group('ti'), m.group('ids').strip()))
    return out


def main():
    texts = [open(DOC, encoding='utf-8').read()]
    for f in ('sheet_cases.tsv', 'cases.tsv', 'analysis_terms_near_cut.tsv'):
        texts.append(open(f'{D}/{f}', encoding='utf-8').read())
    curies = sorted({f'{a}:{b}' for t in texts for a, b in CURIE.findall(t)})
    rows = [('curie', 'found', 'ontology', 'kind', 'label', 'obsolete', 'definition_first_300')]
    bad = []
    for c in curies:
        r = ols(c)
        rows.append((c, r['found'], r['ontology'], r['kind'], r['label'], r['obsolete'], r['definition']))
        if r['found'] != 'yes': bad.append(f'CURIE not found on OLS4: {c}')
    with open(f'{D}/review_curies.tsv', 'w', encoding='utf-8') as fh:
        for r in rows: fh.write('\t'.join(str(x).replace('\t', ' ').replace('\n', ' ') for x in r) + '\n')
    print(f'CURIEs: {len(curies)}; found {sum(r[1] == "yes" for r in rows[1:])}; obsolete '
          f'{", ".join(r[0] for r in rows[1:] if r[5] == "True") or "none"}')

    refs = [('cited', 'id', 'source', 'found_title', 'found_first_author', 'found_year', 'author_ok', 'year_ok', 'title_ok')]
    for cited, au, yr, ti, ids in doc_refs():
        for idv in ids.split():
            if idv.startswith('PMID:'): got, src = epmc(idv[5:]), 'Europe PMC'
            elif idv.startswith('doi:'): got, src = crossref(idv[4:]), 'Crossref'
            else: continue
            if not got:
                refs.append((cited, idv, src, 'NOT FOUND', '', '', False, False, False)); bad.append(f'not found: {idv}'); continue
            a_ok = norm(au).split()[0] in norm(got['first'])
            y_ok = got['year'] == yr
            words = [w for w in norm(ti).split() if len(w) > 3]
            t_ok = sum(w in norm(got['title']) for w in words) >= max(1, int(0.8 * len(words)))
            refs.append((cited, idv, src, got['title'], got['first'], got['year'], a_ok, y_ok, t_ok))
            if not (a_ok and y_ok and t_ok): bad.append(f'mismatch {idv}: doc {au} {yr} "{ti}"; found {got["first"]} {got["year"]} "{got["title"]}"')
    with open(f'{D}/review_refs.tsv', 'w', encoding='utf-8') as fh:
        for r in refs: fh.write('\t'.join(str(x).replace('\t', ' ').replace('\n', ' ') for x in r) + '\n')
    ok = sum(1 for r in refs[1:] if r[6] is True and r[7] is True and r[8] is True)
    print(f'references in the doc table: {len(refs) - 1} ids; all three match: {ok}')
    if bad:
        print('PROBLEMS:\n  ' + '\n  '.join(bad)); sys.exit(1)
    print('all CURIEs found; all references match')


if __name__ == '__main__':
    main()
