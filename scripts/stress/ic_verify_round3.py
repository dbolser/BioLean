"""Program 07, 2026-10-31: check every CURIE and every reference in docs/programs/07-triviality-threshold.md live.
Run from the repo root, isolated, because it parses downloaded JSON:

    python3 -I scripts/stress/ic_verify_round3.py

- CURIEs: each one in the doc is looked up on OLS4 (label, obsolete flag).
- References: each row of the doc's References table ('Surname Year, "Title", Journal | used for | id') is looked up
  on Crossref (doi:) or Europe PMC (PMID:). It matches when the first author's surname is the same, the year is the
  same (or one off, for proceedings), and one title contains the other after folding case, accents and punctuation.
Raw responses are cached in /tmp/biolean-07/live3/ (downloads only; no code there). Outputs, rewritten on each run:
data/stress/07/verify_round3_curies.tsv and data/stress/07/verify_round3_refs.tsv. Exits 1 if anything fails.
Read-only lookups; nothing is posted. Pure Python 3.
"""
import json, os, re, sys, time, unicodedata, urllib.error, urllib.parse, urllib.request

DOC = 'docs/programs/07-triviality-threshold.md'
OUT = 'data/stress/07'
CACHE = '/tmp/biolean-07/live3'
UA = {'User-Agent': 'BioLean-stress-07/1.0 (read-only reference check)'}
CURIE = re.compile(r'\b(GO|UBERON|CL|CHEBI|NCBITaxon|RO|PR|PO|MONDO|PATO|SO|HP|OBA|BFO):(\d+)\b')
REF = re.compile(r'^\| ([^|]+?) (\d{4}), "([^"]+)", ([^|]+?) \| ([^|]+?) \| (doi:\S+|PMID:\d+) \|$')


def fetch(url, name):
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=30) as r: data = r.read()
        with open(path, 'wb') as fh: fh.write(data)
        time.sleep(0.3)
    with open(path, encoding='utf-8') as fh: return json.load(fh)


def fold(s):
    s = unicodedata.normalize('NFKD', s or '')
    s = ''.join(c for c in s if not unicodedata.combining(c)).lower()
    return re.sub(r'[^a-z0-9]+', ' ', s).strip()


def ols(curie):
    pre = curie.split(':')[0].lower()
    ont = {'ncbitaxon': 'ncbitaxon', 'chebi': 'chebi'}.get(pre, pre)
    for kind in ('terms', 'properties'):   # RO relations are object properties in OLS4
        url = f'https://www.ebi.ac.uk/ols4/api/ontologies/{ont}/{kind}?obo_id={urllib.parse.quote(curie)}'
        try: d = fetch(url, f'ols_{kind}_' + curie.replace(':', '_') + '.json')
        except urllib.error.HTTPError: continue
        got = d.get('_embedded', {}).get(kind, [])
        if got: return got[0].get('label'), got[0].get('is_obsolete')
    return None, None


def crossref(doi):
    d = fetch('https://api.crossref.org/works/' + urllib.parse.quote(doi, safe='/()<>:;.-_'),
              'crossref_' + re.sub(r'[^A-Za-z0-9]+', '_', doi) + '.json')['message']
    title = (d.get('title') or [''])[0]
    sub = (d.get('subtitle') or [''])
    if sub and sub[0]: title = f'{title}: {sub[0]}'
    au = (d.get('author') or [{}])[0]
    first = au.get('family') or au.get('name') or ''
    year = None
    for k in ('published-print', 'published', 'issued', 'published-online'):
        dp = (d.get(k) or {}).get('date-parts')
        if dp and dp[0] and dp[0][0]: year = dp[0][0]; break
    return title, first, year


def epmc(pmid):
    q = urllib.parse.quote(f'EXT_ID:{pmid} AND SRC:MED')
    d = fetch(f'https://www.ebi.ac.uk/europepmc/webservices/rest/search?query={q}&format=json&resultType=core',
              f'epmc_{pmid}.json')
    res = d.get('resultList', {}).get('result', [])
    if not res: return None, None, None
    r = res[0]
    al = (r.get('authorList') or {}).get('author') or [{}]
    first = al[0].get('lastName') or al[0].get('collectiveName') or ''
    return r.get('title', ''), first, int(r['pubYear']) if r.get('pubYear') else None


def main():
    os.makedirs(CACHE, exist_ok=True)
    text = open(DOC, encoding='utf-8').read()
    bad = 0
    rows = [('curie', 'ols4_label', 'obsolete', 'found')]
    for c in sorted({m.group(0) for m in CURIE.finditer(text)}):
        try: label, obs = ols(c)
        except Exception as e: label, obs = f'ERROR {e}', None
        ok = label is not None and not str(label).startswith('ERROR')
        bad += not ok
        rows.append((c, label or '', obs, ok))
    with open(f'{OUT}/verify_round3_curies.tsv', 'w', encoding='utf-8') as fh:
        for r in rows: fh.write('\t'.join(map(str, r)) + '\n')
    print(f'CURIEs: {len(rows) - 1} looked up, {sum(r[3] for r in rows[1:])} found')
    refs = [('ref', 'id', 'doc_first_author', 'doc_year', 'doc_title', 'found_first_author', 'found_year', 'found_title',
             'author_ok', 'year_ok', 'title_ok', 'match')]
    for line in text.splitlines():
        m = REF.match(line)
        if not m: continue
        au, yr, title, _, _, rid = m.groups()
        try:
            ft, fa, fy = crossref(rid[4:]) if rid.startswith('doi:') else epmc(rid[5:])
        except Exception as e:
            ft, fa, fy = f'ERROR {e}', '', None
        a_ok = fold(au).split()[-1] == fold(fa).split()[-1] if fa else False
        y_ok = fy is not None and abs(int(yr) - fy) <= 1
        t1, t2 = fold(title), fold(ft)
        t_ok = bool(t1) and bool(t2) and (t1 in t2 or t2 in t1)
        ok = a_ok and y_ok and t_ok
        bad += not ok
        refs.append((f'{au} {yr}', rid, au, yr, title, fa, fy, ft, a_ok, y_ok, t_ok, ok))
        print(f"  {'ok ' if ok else 'BAD'} {au} {yr} {rid}: found {fa} {fy} {ft[:70]!r}")
    with open(f'{OUT}/verify_round3_refs.tsv', 'w', encoding='utf-8') as fh:
        for r in refs: fh.write('\t'.join(str(x).replace('\t', ' ') for x in r) + '\n')
    print(f'references: {len(refs) - 1} checked, {sum(r[-1] for r in refs[1:])} match')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
