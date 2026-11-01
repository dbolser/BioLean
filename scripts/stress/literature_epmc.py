"""Program 10b: check PMIDs on Europe PMC (read-only).

    python3 scripts/stress/literature_epmc.py check            # every PMID in PMIDS below -> references_checked.tsv
    python3 scripts/stress/literature_epmc.py search "query"   # free-text search, prints the top hits
    python3 scripts/stress/literature_epmc.py grep PMID "phrase" ...  # the abstract sentence holding each phrase

Raw JSON is cached in /tmp/biolean-10b/dl/epmc/. `check` writes data/stress/10b/references_checked.tsv
(pmid, year, first author, journal, title, where used, checked date). Title and first author are as
Europe PMC returns them; the role column says why the stress set cites the paper.
"""
import datetime
import json
import os
import sys
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CACHE = '/tmp/biolean-10b/dl/epmc'
OUT = os.path.join(ROOT, 'data', 'stress', '10b')
API = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search'

# pmid: where the stress set uses it
PMIDS = {
    # SIGNOR edges
    '2550426': 'SIGNOR INS -> INSR', '16956584': 'SIGNOR INS -> INSR', '9415393': 'SIGNOR INS -> SLC2A4',
    '17403369': 'SIGNOR SLC2A4 -> glucose (relocalization)', '24843404': 'SIGNOR Ca2+ -> INS (relocalization)',
    '31693916': 'SIGNOR alpha-D-glucose -> GCG', '22863277': 'SIGNOR GCG -> GCGR', '12529935': 'SIGNOR GCG -> GCGR',
    '18981475': 'SIGNOR PTH -> PTH1R', '1560825': 'SIGNOR AVP -> AVPR2', '31160049': 'SIGNOR vasopressin -> AVPR2 (screen)',
    '21874297': 'SIGNOR ATP synthase -> ATP', '31115493': 'SIGNOR hydron -> ATP synthase',
    '27262167': 'SIGNOR SCN1A -> Na+', '11602624': 'SIGNOR metformin -> AMPK', '24843020': 'SIGNOR metformin -| complex I',
    '17909097': 'SIGNOR metformin -> G6PC1 (sign)', '1648089': 'SIGNOR INSR unknown FABP4',
    '29953871': 'SIGNOR shared PMID (many Ca2+ edges)', '11416002': 'SIGNOR INSR -> IRS1',
    # GO-CAM facts
    '14986111': 'GO-CAM INS -> INSR', '38056462': 'GO-CAM INSR -> IRS1', '7493946': 'GO-CAM IRS1 -> PI3K',
    '11277933': 'GO-CAM PI3K -> GLUT4', '18245775': 'GO-CAM GLUT1 (not GLUT4) part_of glucose transport; no longer a stress record', '14562105': 'GO-CAM GLUT4 activity part_of glucose homeostasis (G02d)',
    '19251038': 'GO-CAM glucose located_in cytoplasm', '35932760': 'GO-CAM PTH -> PTH1R',
    '38632411': 'GO-CAM Ca2+ -> CASR', '37963465': 'GO-CAM GPCR -> G protein', '15331768': 'GO-CAM Gi -| PTH',
    '32193322': 'GO-CAM glucagon -> GCGR', '32296767': 'GO-CAM calcitonin -> CALCR', '33742150': 'GO-CAM AVP -> AVPR2',
    '28534087': 'GO-CAM PKA -> TRPV5', '18768590': 'GO-CAM TRPV5 part_of Ca2+ import', '11029056': 'GO-CAM PKA -> Ca channel',
    '40811462': 'GO-CAM ZFA anatomy', '37991948': 'GO-CAM Gq -| PTH', '19674967': 'GO-CAM PTH1R -> Gs',
    '14672992': 'GOA SCN1A enables Nav activity (IMP)', '15563840': 'GOA CALCR NOT calcitonin binding', '8078488': 'GOA CALCR calcitonin binding',
    '7769107': 'GOA CALCR calcitonin binding (isoform 2)', '10200251': 'GO-CAM Gs -> PKA (PTH model)',
    # Reactome reactions
    '1756912': 'Reactome GLUT4 transports Glc', '1534149': 'Reactome AVPR2 binds AVP', '11737239': 'Reactome insulin binds INSR',
    '21566136': 'Reactome SCNA transport Na+', '8397094': 'Reactome PTH receptor binds PTH (set)',
    '12403834': 'Reactome exocytosis of insulin', '2991279': 'Reactome expression of AVP', '11946536': 'Reactome glucagon binds GCGR',
    '7759551': 'Reactome CASR binds Ca2+', '8457197': 'Reactome GLUT2 transports Glc out',
    '11994746': 'Reactome GLUT4 transports Glc', '1918382': 'Reactome GLUT4 transports Glc', '2656669': 'Reactome GLUT4 transports Glc',
    '9751501': 'Reactome GLUT2 transports Glc out', '9354798': 'Reactome GLUT2 transports Glc out', '7781591': 'Reactome insulin binds INSR',
    '15464082': 'Reactome glucagon binds GCGR', '2826231': 'Reactome glucagon binds GCGR', '8144028': 'Reactome glucagon binds GCGR',
    '17900700': 'Reactome exocytosis of insulin', '16443778': 'Reactome exocytosis of insulin', '12684222': 'Reactome exocytosis of insulin',
    '8997178': 'Reactome exocytosis of insulin', '18162464': 'Reactome exocytosis of insulin', '14514350': 'Reactome exocytosis of insulin',
    '7641683': 'Reactome exocytosis of insulin', '11873862': 'Reactome exocytosis of insulin', '14500339': 'Reactome SCNA transport Na+',
    '1309946': 'Reactome SCNA transport Na+',
    # GOA
    '33664408': 'GOA AVPR2 enables vasopressin receptor activity (first pass misread it as AVP; O02 replaced)', '15574588': 'GOA aak-2 determination of adult lifespan',
    # metformin and lifespan (M8 exit sketch)
    '23900241': 'mouse lifespan, supports', '27312235': 'ITP mouse lifespan, no effect', '20090912': 'worm healthspan',
    '23540700': 'worm lifespan via microbes', '25041462': 'human T2D survival, supports', '28802803': 'meta-analysis, supports',
    '36287641': 'human survival reassessed, refutes', '27304507': 'TAME proposal, hypothesis',
    # PubTator3 metformin and G6PC1 relations (S12 text-mined check), from pubtator_metformin_g6pc1.tsv
    '10576523': 'PubTator3 metformin G6PC1 negative_correlate', '19579180': 'PubTator3 metformin G6PC1 negative_correlate',
    '22758368': 'PubTator3 metformin G6PC1 negative_correlate', '24428821': 'PubTator3 metformin G6PC1 negative_correlate',
    '29256045': 'PubTator3 metformin G6PC1 negative_correlate', '30970232': 'PubTator3 metformin G6PC1 negative_correlate',
    '32375255': 'PubTator3 metformin G6PC1 negative_correlate', '39922487': 'PubTator3 metformin G6PC1 negative_correlate',
    '42545322': 'PubTator3 metformin G6PC1 negative_correlate', '42555357': 'PubTator3 metformin G6PC1 positive_correlate',
    '28842730': 'PubTator3 metformin G6PC1 associate', '40211429': 'PubTator3 metformin G6PC1 associate',
}


def get(params, path):
    if os.path.exists(path):
        return json.load(open(path))
    url = API + '?' + urllib.parse.urlencode(params)
    for attempt in range(3):
        try:
            raw = urllib.request.urlopen(url, timeout=60).read()
            open(path, 'wb').write(raw)
            time.sleep(0.2)
            return json.loads(raw)
        except Exception as e:  # noqa: BLE001
            print('retry', url, e, file=sys.stderr)
            time.sleep(2)
    return {}


def check():
    os.makedirs(CACHE, exist_ok=True)
    found = {}
    ids = list(PMIDS)
    for i in range(0, len(ids), 40):
        chunk = ids[i:i + 40]
        q = 'EXT_ID:(' + ' OR '.join(chunk) + ') AND SRC:MED'
        d = get({'query': q, 'resultType': 'lite', 'format': 'json', 'pageSize': 100},
                os.path.join(CACHE, f'check_{i}_{len(ids)}.json'))
        for r in d.get('resultList', {}).get('result', []):
            found[r['pmid']] = r
    today = datetime.date.today().isoformat()
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, 'references_checked.tsv'), 'w') as fh:
        fh.write('pmid\tyear\tfirst_author\tjournal\ttitle\tused_for\tchecked\n')
        for p in ids:
            r = found.get(p)
            if not r:
                fh.write(f'{p}\t\tNOT FOUND\t\t\t{PMIDS[p]}\t{today}\n')
                print(p, 'NOT FOUND')
                continue
            first = (r.get('authorString') or '').split(',')[0]
            title = (r.get('title') or '').replace('\t', ' ')
            fh.write(f"{p}\t{r.get('pubYear')}\t{first}\t{r.get('journalTitle', '')}\t{title}\t{PMIDS[p]}\t{today}\n")
            print(p, r.get('pubYear'), first, '|', title[:110])


def abstract(pmid):
    d = get({'query': f'EXT_ID:{pmid} AND SRC:MED', 'resultType': 'core', 'format': 'json'},
            os.path.join(CACHE, f'core_{pmid}.json'))
    r = (d.get('resultList', {}).get('result') or [{}])[0]
    return (r.get('title') or '') + ' ' + (r.get('abstractText') or '')


def grep(pmid, *phrases):
    """Print each phrase's sentence in the abstract (a quote check)."""
    import re
    text = re.sub(r'<[^>]+>', '', abstract(pmid))
    for ph in phrases:
        hits = [x.strip() for x in re.split(r'(?<=[.;])\s+', text) if ph.lower() in x.lower()]
        print(pmid, repr(ph), '->', hits[0][:300] if hits else 'NOT IN ABSTRACT')


def search(q):
    os.makedirs(CACHE, exist_ok=True)
    d = get({'query': q, 'resultType': 'lite', 'format': 'json', 'pageSize': 5},
            os.path.join(CACHE, 'search_' + ''.join(ch if ch.isalnum() else '_' for ch in q)[:80] + '.json'))
    for r in d.get('resultList', {}).get('result', []):
        print(r.get('pmid'), r.get('pubYear'), (r.get('authorString') or '').split(',')[0], '|',
              r.get('journalTitle', ''), '|', (r.get('title') or '')[:120])


if __name__ == '__main__':
    if sys.argv[1] == 'check':
        check()
    elif sys.argv[1] == 'grep':
        grep(sys.argv[2], *sys.argv[3:])
    else:
        for q in sys.argv[2:]:
            print('==', q)
            search(q)
