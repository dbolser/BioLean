"""Check every CURIE used by program 02b on OLS4 and write data/stress/02b/curies.tsv.

Sources scanned: BioLean/Stress/Feedback.lean, BioLean/Proto/Feedback.lean (CURIEs and the textbook entities e_PREFIX_ID they
reuse), data/stress/02b/homeostasis_m3.json (m3 and loop blocks), data/stress/02b/cases.tsv if present. BLN: placeholders
are internal and listed as such. Downloads are cached in /tmp/biolean-02b/dl/ols4 (untrusted data; run with python3 -I).
Usage (repo root): python3 -I data/stress/02b/scripts/ols_check.py
"""
import json, re, pathlib, urllib.request, urllib.parse, collections, time

DL = pathlib.Path('/tmp/biolean-02b/dl/ols4'); DL.mkdir(parents=True, exist_ok=True)
SRC = ['BioLean/Stress/Feedback.lean', 'BioLean/Proto/Feedback.lean', 'data/stress/02b/homeostasis_m3.json', 'data/stress/02b/cases.tsv']
PREFIXES = 'CHEBI|GO|PR|UBERON|CL|NCBITaxon|OBA|PATO|MONDO|PO|NCIT|HP|RO|BFO|TEDDY|BLN'
CUR = re.compile(rf'\b({PREFIXES})[:_]([A-Za-z0-9]+(?:_[a-z]+)*)')
ONTO = {'NCBITaxon': 'ncbitaxon', 'OBA': 'oba', 'BFO': 'ro'}   # BFO relations are served under RO in OLS4

def fetch(curie):
    f = DL / (curie.replace(':', '_') + '.json')
    if not f.exists() or f.stat().st_size == 0:
        pre = curie.split(':')[0]
        onto = ONTO.get(pre, pre.lower())
        q = {'short_form': curie.replace(':', '_')} if pre == 'TEDDY' else {'obo_id': curie}
        kind = 'terms'
        if pre in ('RO', 'BFO'):   # relations are properties in OLS4
            kind, q = 'properties', {'iri': f'http://purl.obolibrary.org/obo/{curie.replace(":", "_")}'}
        url = f'https://www.ebi.ac.uk/ols4/api/ontologies/{onto}/{kind}?' + urllib.parse.urlencode(q)
        try:
            with urllib.request.urlopen(url, timeout=40) as r: f.write_bytes(r.read())
        except Exception as e:
            f.write_text(json.dumps({'error': str(e)}))
        time.sleep(0.1)
    try: d = json.loads(f.read_text())
    except Exception as e: return None, f'unreadable {e}'
    ts = (d.get('_embedded') or {}).get('terms') or (d.get('_embedded') or {}).get('properties') or []
    if not ts: return None, d.get('error') or 'not found'
    defining = [t for t in ts if t.get('is_defining_ontology')] or ts
    return defining[0], None

def main():
    used = collections.defaultdict(set); labels = collections.defaultdict(set)
    for p in SRC:
        path = pathlib.Path(p)
        if not path.exists(): continue
        text = path.read_text()
        for m in CUR.finditer(text):
            pre, loc = m.group(1), m.group(2)
            if pre == 'BLN': used[f'BLN:{loc}'].add(path.name); continue
            if pre in ('RO', 'BFO') and not loc.isdigit(): continue
            used[f'{pre}:{loc}'].add(path.name)
        if p.endswith('.lean'):   # textbook entities reused by name: e_GO_0003016 is GO:0003016 (the pattern above needs a word boundary)
            for m in re.finditer(rf'\be_({PREFIXES})_([A-Za-z0-9]+)', text): used[f'{m.group(1)}:{m.group(2)}'].add(path.name)
            for m in re.finditer(r'⟨"((?:%s):[^"]+)", "([^"]+)"⟩' % PREFIXES, text): labels[m.group(1)].add(m.group(2))
    # labels of reused textbook entities
    for lib in ('BioLean/Lib/TextbookClaimsR2/Entities.lean', 'BioLean/Lib/TextbookClaimsR3/Entities.lean'):
        for m in re.finditer(r'def e_\S+ : Entity \.\w+ := ⟨"([^"]+)", "([^"]*)"⟩', pathlib.Path(lib).read_text()):
            if m.group(1) in used: labels[m.group(1)].add(m.group(2) + ' (textbook entity)')
    rows, bad = [], 0
    for c in sorted(used):
        if c.startswith('BLN:'):
            rows.append([c, '-', '-', '-', 'PLACEHOLDER', '; '.join(sorted(labels[c])), ', '.join(sorted(used[c]))]); continue
        t, err = fetch(c)
        if t is None:
            rows.append([c, '-', '-', '-', 'NOT FOUND' if err == 'not found' else f'ERROR {err}', '; '.join(sorted(labels[c])), ', '.join(sorted(used[c]))]); bad += 1; continue
        status = 'OBSOLETE' if t.get('is_obsolete') else 'OK'
        bad += status != 'OK'
        rows.append([c, t.get('label') or '', t.get('ontology_name') or '', str(bool(t.get('is_obsolete'))), status, '; '.join(sorted(labels[c])), ', '.join(sorted(used[c]))])
    with open('data/stress/02b/curies.tsv', 'w') as f:
        f.write('curie\tols4_label\tontology\tobsolete\tstatus\tlabel_used_here\tused_in\n')
        for r in rows: f.write('\t'.join(r) + '\n')
    print(f'{len(rows)} CURIEs; not OK: {bad}; placeholders: {sum(1 for r in rows if r[4] == "PLACEHOLDER")}')
    for r in rows:
        if r[4] not in ('OK', 'PLACEHOLDER'): print('  ', r[:5])

if __name__ == '__main__': main()
