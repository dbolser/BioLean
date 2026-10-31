"""Check references for program 07 on Crossref (by DOI) and Europe PMC (by query). Read-only lookups.

Usage: python3 -I scripts/stress/ic_refs.py <out.tsv>
Raw replies are cached in /tmp/biolean-07/refs/ and parsed as JSON only. A reference counts as checked when the title
returned contains the expected title words and the first author's family name matches; otherwise the row is blank and
says UNVERIFIED (Resnik 1995, IJCAI, is not in Crossref: cite Resnik 1999 for the measure).
"""
import json, os, re, sys, time, urllib.parse, urllib.request

CACHE = '/tmp/biolean-07/refs'
# (key, how, id or query, expected first-author family name, expected title fragment)
REFS = [
    ('Resnik1999', 'cr', 'Semantic similarity in a taxonomy: an information-based measure and its application to problems of ambiguity in natural language', 'Resnik', 'Semantic Similarity in a Taxonomy'),
    ('Resnik1995', 'cr', 'Using information content to evaluate semantic similarity in a taxonomy', 'Resnik', 'Using information content to evaluate semantic similarity'),
    ('Sanchez2011', 'doi', '10.1016/j.knosys.2010.10.001', 'Sánchez', 'Ontology-based information content computation'),
    ('Lord2003', 'epmc', 'TITLE:"Investigating semantic similarity measures across the Gene Ontology"', 'Lord', 'semantic similarity measures across the Gene Ontology'),
    ('Pesquita2009', 'epmc', 'TITLE:"Semantic similarity in biomedical ontologies"', 'Pesquita', 'Semantic similarity in biomedical ontologies'),
    ('Geng2006', 'doi', '10.1145/1132960.1132963', 'Geng', 'Interestingness measures for data mining'),
    ('Silberschatz1996', 'doi', '10.1109/69.553165', 'Silberschatz', 'What makes patterns interesting'),
    ('Swanson1986', 'epmc', 'TITLE:"Fish oil, Raynaud\'s syndrome, and undiscovered public knowledge"', 'Swanson', 'undiscovered public knowledge'),
    ('Itti2009', 'epmc', 'TITLE:"Bayesian surprise attracts human attention"', 'Itti', 'Bayesian surprise attracts human attention'),
    ('Tsurel2017', 'doi', '10.1145/3018661.3018709', 'Tsurel', 'Fun Facts'),
    ('Galarraga2013', 'doi', '10.1145/2488388.2488425', 'Galárraga', 'AMIE'),
    ('Joachims2002', 'doi', '10.1145/775047.775067', 'Joachims', 'Optimizing search engines using clickthrough data'),
    ('Burges2005', 'doi', '10.1145/1102351.1102363', 'Burges', 'Learning to rank using gradient descent'),
    ('BradleyTerry1952', 'doi', '10.1093/biomet/39.3-4.324', 'Bradley', 'Rank analysis of incomplete block designs'),
    ('Thurstone1927', 'doi', '10.1037/h0070288', 'Thurstone', 'law of comparative judgment'),
    ('McCullagh1980', 'cr', 'McCullagh Regression models for ordinal data 1980', 'McCullagh', 'Regression Models for Ordinal Data'),
    ('Cohen1960', 'doi', '10.1177/001316446002000104', 'Cohen', 'A Coefficient of Agreement for Nominal Scales'),
    ('LandisKoch1977', 'doi', '10.2307/2529310', 'Landis', 'The Measurement of Observer Agreement for Categorical Data'),
    ('Horridge2008', 'doi', '10.1007/978-3-540-88564-1_21', 'Horridge', 'Laconic and Precise Justifications in OWL'),
    ('Stork2008', 'epmc', 'TITLE:"Organization and function of the blood-brain barrier in Drosophila"', 'Stork', 'blood-brain barrier in Drosophila'),
    ('Xu2006', 'epmc', 'TITLE:"Intra-islet insulin suppresses glucagon release via GABA-GABAA receptor system"', 'Xu', 'Intra-islet insulin suppresses glucagon release'),
    ('London2013', 'epmc', 'TITLE:"retina as a window to the brain" AND AUTH:"London A"', 'London', 'retina as a window to the brain'),
]


def get(url, path):
    if not os.path.exists(path):
        req = urllib.request.Request(url, headers={'Accept': 'application/json', 'User-Agent': 'biolean-stress-07 (read-only reference check)'})
        with urllib.request.urlopen(req, timeout=60) as r: data = r.read()
        with open(path, 'wb') as fh: fh.write(data)
        time.sleep(0.3)
    with open(path, 'rb') as fh: return json.loads(fh.read().decode('utf-8'))


def norm(s): return re.sub(r'[^a-z0-9 ]', '', (s or '').lower())


def check(key, how, ident, fam, frag):
    safe = re.sub(r'[^A-Za-z0-9]', '_', key)
    if how == 'doi':
        d = get(f'https://api.crossref.org/works/{urllib.parse.quote(ident)}', f'{CACHE}/{safe}.json')['message']
        title = (d.get('title') or [''])[0]; au = (d.get('author') or [{}])[0].get('family', '')
        year = ((d.get('issued') or {}).get('date-parts') or [[None]])[0][0]
        venue = (d.get('container-title') or [''])[0]; idout = f'doi:{ident}'
    elif how == 'cr':
        d = get(f'https://api.crossref.org/works?query.bibliographic={urllib.parse.quote(ident)}&rows=5', f'{CACHE}/{safe}.json')['message']['items']
        hit = next((h for h in d if norm(frag) in norm((h.get('title') or [''])[0])), d[0] if d else {})
        title = (hit.get('title') or [''])[0]; au = (hit.get('author') or [{}])[0].get('family', '')
        year = ((hit.get('issued') or {}).get('date-parts') or [[None]])[0][0]
        venue = (hit.get('container-title') or [''])[0]; idout = f"doi:{hit.get('DOI', '')}"
    else:
        q = urllib.parse.quote(ident)
        d = get(f'https://www.ebi.ac.uk/europepmc/webservices/rest/search?query={q}&format=json&pageSize=5', f'{CACHE}/{safe}.json')
        hits = d.get('resultList', {}).get('result', [])
        hit = next((h for h in hits if norm(frag) in norm(h.get('title'))), hits[0] if hits else {})
        title = hit.get('title', ''); au = (hit.get('authorString') or '').split(' ')[0].rstrip(',')
        year = hit.get('pubYear'); venue = hit.get('journalTitle', ''); idout = f"PMID:{hit.get('pmid', '')} doi:{hit.get('doi', '')}"
    ok = norm(frag) in norm(title) and norm(fam)[:5] == norm(au)[:5]
    if not ok:   # do not print a near miss as if it were the paper
        return (key, '', '', '', '', '', f'UNVERIFIED: no match on {"Crossref" if how != "epmc" else "Europe PMC"} (best hit: {idout} {title[:60]})')
    return (key, idout, str(year), au, title, venue, 'yes')


if __name__ == '__main__':
    os.makedirs(CACHE, exist_ok=True)
    rows = [('key', 'id', 'year', 'first_author', 'title', 'venue', 'checked')]
    for r in REFS:
        try: rows.append(check(*r))
        except Exception as e: rows.append((r[0], r[2], '', '', '', '', f'error {type(e).__name__}'))
    with open(sys.argv[1], 'w', encoding='utf-8') as fh:
        for r in rows: fh.write('\t'.join(x.replace('\t', ' ') for x in r) + '\n')
    for r in rows[1:]: print(r[6], r[0], r[1], r[2], r[3], '|', r[4][:90])
