"""Program 10b, review pass: re-check every identifier and quote live, with no cache shared with the first pass.

    python3 -I scripts/stress/literature_review.py

Fresh downloads go to /tmp/biolean-10b/review/live/ (untrusted; deleted and refetched on each run).
Checks:
  1. every CURIE the program uses: curies_checked.tsv plus every CURIE found in the Lean file, the doc
     and cases.tsv, on OLS4 (label, obsolete flag). RO relations are object properties, so they are
     looked up on OLS4's properties endpoint; UniProtKB ids on QuickGO's gene-product search;
  2. every PMID in references_checked.tsv and every PMID in the Lean file, on Europe PMC (title, first
     author, year);
  3. the first author and year of every row of the doc's reference table;
  4. every quoted phrase the doc or the case table attributes to an abstract (QUOTES below);
  5. every textbook sentence the Lean file compares against: the Lean note equals the `source` field of
     data/textbook/claims_m3 (or claims_m2) for that id;
  6. every Reactome stable id, on Reactome ContentService (display name).
Writes data/stress/10b/review_checked.tsv (what, id, first pass or expected, live, agree). Prints the
disagreements. Exit status 1 if any.
"""
import csv
import glob
import json
import os
import re
import shutil
import sys
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'data', 'stress', '10b')
DOC = os.path.join(ROOT, 'docs', 'programs', '10b-literature-at-scale.md')
LEAN = os.path.join(ROOT, 'BioLean', 'Stress', 'Literature.lean')
LIVE = '/tmp/biolean-10b/review/live'
OLS = 'https://www.ebi.ac.uk/ols4/api'
EPMC = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search'
QUICKGO = 'https://www.ebi.ac.uk/QuickGO/services/geneproduct/search'
REACTOME = 'https://reactome.org/ContentService/data/query'
UA = {'User-Agent': 'BioLean-stress-10b-review (read-only research)', 'Accept': 'application/json'}
PREFIXES = 'CHEBI|GO|PR|UBERON|CL|NCBITaxon|RO|BFO|PATO|MONDO|ZFA|EMAPA|BTO|ECO|EFO|UniProtKB'
SYNTHETIC = {'90000001', '90000002'}

# (PMID, phrase the doc or cases.tsv puts in quotes or attributes to the paper)
QUOTES = [
    ('17909097', 'promoter activity of PEPCK and G6Pase'),   # the doc's longer quote is SIGNOR's stored sentence (literature_records.py)
    ('27312235', 'did not significantly extend lifespan'),
    ('36287641', 'not associated with survival equal or superior to that of the general population'),
    ('15574588', 'functions to extend lifespan'),
    ('23540700', 'metformin sensitivity and glucose concentration'),
    ('25041462', '15% lower'),
    ('23900241', 'extends healthspan and lifespan in male mice'),
    ('20090912', 'extending median lifespan'),
    ('28802803', 'meta-analysis'),
    ('27304507', 'TAME'),
    ('11602624', 'hepatocytes'),
    ('24843020', 'complex I'),
    ('15563840', 'two novel isoforms'),
    ('35932760', 'PTH'),
    ('19579180', 'metformin'),
    ('14562105', 'GLUT4'),
]


def fetch(url, name):
    path = os.path.join(LIVE, name)
    for attempt in range(3):
        try:
            raw = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60).read()
            open(path, 'wb').write(raw)
            time.sleep(0.1)
            return json.loads(raw)
        except Exception as e:  # noqa: BLE001 (report and retry)
            print('retry', attempt, url, e, file=sys.stderr)
            time.sleep(2)
    return {}


def safe(c):
    return re.sub(r'[^A-Za-z0-9]', '_', c)


def ols(c):
    """(label, obsolete) or None. Classes first; RO relations are properties."""
    pre = c.split(':')[0].lower()
    for kind in ('terms', 'properties'):
        if kind == 'terms' and pre == 'ro':
            continue
        d = fetch(f'{OLS}/{kind}?' + urllib.parse.urlencode({'obo_id': c, 'size': 50}), f'ols_{kind}_{safe(c)}.json')
        ts = d.get('_embedded', {}).get(kind, [])
        if ts:
            t = ([x for x in ts if (x.get('ontology_prefix') or '').lower() == pre or x.get('ontology_name') == pre]
                 or [x for x in ts if x.get('is_defining_ontology')] or ts)[0]
            return t.get('label', ''), t.get('is_obsolete')
    # OLS4 indexes some relations RO imports (BFO:0000050 part of) with a broken obo_id: look up by IRI in RO
    iri = 'http://purl.obolibrary.org/obo/' + c.replace(':', '_')
    d = fetch(f'{OLS}/ontologies/ro/properties?' + urllib.parse.urlencode({'iri': iri}), f'ols_ro_iri_{safe(c)}.json')
    ts = d.get('_embedded', {}).get('properties', [])
    if ts:
        return ts[0].get('label', '') + ' (in RO, by IRI)', ts[0].get('is_obsolete')
    return None


def uniprot(c):
    acc = c.split(':')[1]
    d = fetch(QUICKGO + '?' + urllib.parse.urlencode({'query': acc, 'limit': 5}), f'quickgo_{acc}.json')
    for r in d.get('results', []):
        if r.get('id') == acc:
            return f"{r.get('symbol')} {r.get('name')} (taxon {r.get('taxonId')})", False
    return None


def epmc(pmids, tag, core=False):
    found = {}
    for i in range(0, len(pmids), 40):
        chunk = pmids[i:i + 40]
        q = 'EXT_ID:(' + ' OR '.join(chunk) + ') AND SRC:MED'
        d = fetch(EPMC + '?' + urllib.parse.urlencode({'query': q, 'resultType': 'core' if core else 'lite',
                                                       'format': 'json', 'pageSize': 100}), f'epmc_{tag}_{i}.json')
        for r in d.get('resultList', {}).get('result', []):
            found[r['pmid']] = r
    return found


def norm(s):
    return re.sub(r'[^a-z0-9]', '', (s or '').lower())


def textbook_sources():
    src = {}
    for f in sorted(glob.glob(os.path.join(ROOT, 'data', 'textbook', 'claims_m2', '*.json'))) + \
            sorted(glob.glob(os.path.join(ROOT, 'data', 'textbook', 'claims_m3', '*.json'))):
        for r in json.load(open(f)):
            if isinstance(r, dict) and r.get('id'):
                src[r['id']] = r.get('source', '')
    return src


def lean_textbook_notes(lean):
    """Textbook ids the stress file compares against, and the note of each in the compiled biolib."""
    out = {}
    for rnd, mod, name in re.findall(r'BioLean\.Textbook\.(R\d)\.(\w+)\.(\w+)', lean):
        path = os.path.join(ROOT, 'BioLean', 'Lib', f'TextbookClaims{rnd}', f'{mod}.lean')
        text = open(path).read()
        m = re.search(rf'def {name} : Statement where\n  id := "([^"]+)"\n.*?note := "((?:[^"\\]|\\.)*)"', text, re.S)
        if m:
            out[m.group(1)] = m.group(2)
    return out


def main():
    shutil.rmtree(LIVE, ignore_errors=True)
    os.makedirs(LIVE)
    rows, bad = [], []

    def add(what, ident, expected, live, ok):
        rows.append([what, ident, expected, live, ok])
        if not ok:
            bad.append(rows[-1])

    lean, doc = open(LEAN).read(), open(DOC).read()
    cases = open(os.path.join(OUT, 'cases.tsv')).read()
    # 1. CURIEs
    cur = {r['curie']: r['label'] for r in csv.DictReader(open(os.path.join(OUT, 'curies_checked.tsv')), delimiter='\t')}
    rx = re.compile(r'\b(?:%s):[A-Z]?[0-9A-Z]{4,10}\b' % PREFIXES)
    used = set(rx.findall(lean)) | set(rx.findall(doc)) | set(rx.findall(cases))
    used |= {'RO:%07d' % int(x) for x in re.findall(r'⟨\.ro, (\d+), (?:false|true)⟩', lean)}
    for c in sorted(set(cur) | used):
        t = uniprot(c) if c.startswith('UniProtKB:') else ols(c)
        live = 'NOT FOUND' if t is None else t[0]
        if c in cur:
            ok = t is not None and (live == cur[c] or (cur[c].startswith('NOT FOUND')))
            exp = cur[c]
        else:
            ok, exp = t is not None, '(not in curies_checked.tsv)'
        if c == 'PR:Q95ZQ4':          # known: not in PR; the doc says so and uses UniProtKB:Q95ZQ4
            ok = t is None
        add('curie', c, exp, f'{live} (obsolete {None if t is None else t[1]})', ok)
    # 2. PMIDs
    refs = {r['pmid']: r for r in csv.DictReader(open(os.path.join(OUT, 'references_checked.tsv')), delimiter='\t')}
    lean_pm = set(re.findall(r'(?:cdb|item) (\d{6,8}) ', lean)) | set(re.findall(r'\((\d{7,8}), \d{4}\)', lean))
    for p in sorted(lean_pm - set(refs) - SYNTHETIC):
        add('pmid', p, 'used in Literature.lean', 'not in references_checked.tsv', False)
    found = epmc(sorted(set(refs) | (lean_pm - SYNTHETIC)), 'all')
    for p, r in refs.items():
        x = found.get(p)
        if not x:
            add('pmid', p, r['title'][:80], 'NOT FOUND', False)
            continue
        first = (x.get('authorString') or '').split(',')[0]
        ok = norm(x.get('title')) == norm(r['title']) and first == r['first_author'] and x.get('pubYear') == r['year']
        add('pmid', p, f"{r['first_author']} {r['year']} {r['title'][:60]}",
            f"{first} {x.get('pubYear')} {(x.get('title') or '')[:60]}", ok)
    # 3. the doc's reference table: | PMID | first author, year | ...
    for pmid, fa, yr in re.findall(r'^\| (\d{6,8}) \| ([^,|]+), (\d{4}) \|', doc, re.M):
        x = found.get(pmid) or epmc([pmid], f'doc_{pmid}').get(pmid)
        first = (x or {}).get('authorString', '').split(',')[0] if x else 'NOT FOUND'
        add('doc reference', pmid, f'{fa.strip()} {yr}', f"{first} {(x or {}).get('pubYear')}",
            bool(x) and first == fa.strip() and x.get('pubYear') == yr)
    # 4. quotes against abstracts
    core = epmc(sorted({p for p, _ in QUOTES}), 'quotes', core=True)
    for p, phrase in QUOTES:
        text = re.sub(r'<[^>]+>', '', (core.get(p, {}).get('title') or '') + ' ' + (core.get(p, {}).get('abstractText') or ''))
        hit = [s.strip() for s in re.split(r'(?<=[.;])\s+', text) if phrase.lower() in s.lower()]
        add('quote', p, phrase, hit[0][:200] if hit else 'NOT IN TITLE OR ABSTRACT', bool(hit))
    # 5. textbook sentences
    src = textbook_sources()
    for tid, note in lean_textbook_notes(lean).items():
        live = src.get(tid, 'NOT IN data/textbook/claims_m2 or claims_m3')
        add('textbook', tid, note[:100], live[:100], norm(live) == norm(note.replace('\\"', '"')))
    # 6. Reactome stable ids
    for rid in sorted(set(re.findall(r'R-(?:HSA|MMU)-\d+', lean + cases + doc))):
        d = fetch(f'{REACTOME}/{rid}', f'reactome_{rid}.json')
        name = d.get('displayName') if isinstance(d, dict) else None
        add('reactome', rid, '', f"{name} ({d.get('schemaClass') if isinstance(d, dict) else ''})", bool(name))

    with open(os.path.join(OUT, 'review_checked.tsv'), 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['what', 'id', 'first_pass_or_expected', 'live_2026_11_01', 'agree'])
        w.writerows(rows)
    kinds = {}
    for r in rows:
        kinds.setdefault(r[0], [0, 0])[0] += 1
        kinds[r[0]][1] += bool(r[4])
    print('checked', len(rows), {k: f'{v[1]}/{v[0]} agree' for k, v in kinds.items()}, 'disagreements', len(bad))
    for b in bad:
        print('\t'.join(map(str, b)))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
