"""Program 10b: read-only downloads for the literature-at-scale stress set.

Everything goes to /tmp/biolean-10b/dl/ (untrusted data). Nothing here parses what it downloads beyond
saving it; the parsers are separate scripts run with `python3 -I`. Existing files are kept unless
--force is given, so a rerun is cheap.

    python3 scripts/stress/literature_fetch.py signor        # SIGNOR human network from NDEx (CX2) + summary
    python3 scripts/stress/literature_fetch.py gocam         # GO-CAM model lists per gene product, then models
    python3 scripts/stress/literature_fetch.py reactome      # Reactome reactions per UniProt, then the stress-set reactions
    python3 scripts/stress/literature_fetch.py reactome_all  # every human reaction mapped to a stress-set protein
    python3 scripts/stress/literature_fetch.py goa           # GOA (QuickGO) annotations for the stress-set gene products
    python3 scripts/stress/literature_fetch.py all

SIGNOR's own server (signor.uniroma2.it) refused connections on 2026-11-01, so SIGNOR comes from its
NDEx release (network 523fff27-afe8-11e9-8bb4-0ac135e8bacf, loaded by ndexsignorloader).
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request

DL = '/tmp/biolean-10b/dl'
FORCE = '--force' in sys.argv
UA = {'User-Agent': 'BioLean-stress-10b (read-only research; dan.bolser@outsee.co.uk)'}

# UniProt accessions of the textbook entities and their receptors, transporters and channels.
TARGETS = {
    'P01308': 'INS', 'P06213': 'INSR', 'P01275': 'GCG', 'P47871': 'GCGR', 'P01270': 'PTH',
    'Q03431': 'PTH1R', 'P41180': 'CASR', 'P01258': 'CALCA', 'P30988': 'CALCR', 'P01185': 'AVP',
    'P30518': 'AVPR2', 'P14672': 'SLC2A4', 'Q14524': 'SCN5A', 'P35498': 'SCN1A', 'P25705': 'ATP5F1A',
    'P06576': 'ATP5F1B', 'P41181': 'AQP2', 'P11168': 'SLC2A2',
}
SIGNOR_NDEX = '523fff27-afe8-11e9-8bb4-0ac135e8bacf'
REACTIONS = ['R-HSA-74716', 'R-HSA-163625', 'R-HSA-164832', 'R-HSA-8981570', 'R-HSA-450095',
             'R-HSA-265166', 'R-HSA-392263', 'R-HSA-419843', 'R-HSA-420489', 'R-HSA-420724',
             'R-HSA-432065', 'R-HSA-432237', 'R-HSA-5576895', 'R-HSA-74730', 'R-HSA-879782',
             'R-HSA-9023196', 'R-HSA-9023633', 'R-HSA-381798', 'R-HSA-383313', 'R-HSA-381612',
             'R-HSA-211289', 'R-HSA-1449574', 'R-HSA-163210']
ENTITIES = ['R-ALL-113592', 'R-ALL-29370', 'R-ALL-70113', 'R-ALL-70115', 'R-ALL-74016', 'R-ALL-74112',
            'R-ALL-74113', 'R-ALL-83910', 'R-ALL-109276', 'R-HSA-163626', 'R-HSA-164835', 'R-HSA-381662',
            'R-HSA-388474', 'R-HSA-419781', 'R-HSA-74674', 'R-HSA-164838']


def get(url, path, accept=None):
    if os.path.exists(path) and not FORCE:
        return open(path, 'rb').read()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    h = dict(UA)
    if accept:
        h['Accept'] = accept
    for attempt in range(3):
        try:
            raw = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=120).read()
            open(path, 'wb').write(raw)
            time.sleep(0.2)
            return raw
        except Exception as e:  # noqa: BLE001 (report and retry)
            print('retry', attempt, url, e, file=sys.stderr)
            time.sleep(2)
    print('FAILED', url, file=sys.stderr)
    return b''


def signor():
    get(f'https://www.ndexbio.org/v2/network/{SIGNOR_NDEX}/summary', f'{DL}/signor/ndex_human_summary.json')
    get(f'https://www.ndexbio.org/v3/networks/{SIGNOR_NDEX}', f'{DL}/signor/signor_human.cx2')


def gocam():
    ids = []
    for acc in TARGETS:
        raw = get(f'https://api.geneontology.org/api/gp/UniProtKB:{acc}/models', f'{DL}/gocam/gp_{acc}.json')
        for m in json.loads(raw or b'[]'):
            mid = m['gocam'].rsplit('/', 1)[-1]
            if mid not in ids:
                ids.append(mid)
    for mid in ['R-HSA-163210', 'R-HSA-381676']:   # Reactome pathways imported into GO-CAM
        if mid not in ids:
            ids.append(mid)
    open(f'{DL}/gocam/model_ids.txt', 'w').write('\n'.join(ids) + '\n')
    for mid in ids:
        get(f'https://api.geneontology.org/api/go-cam/{mid}', f'{DL}/gocam/models/{mid}.json')


def reactome():
    for acc in TARGETS:
        get(f'https://reactome.org/ContentService/data/mapping/UniProt/{acc}/reactions',
            f'{DL}/reactome/map_{acc}.json')
    for st in REACTIONS:
        get(f'https://reactome.org/ContentService/data/query/enhanced/{st}', f'{DL}/reactome/rx/{st}.json')
    for st in ENTITIES:
        get(f'https://reactome.org/ContentService/data/query/enhanced/{st}', f'{DL}/reactome/pe/{st}.json')
    get('https://reactome.org/ContentService/data/database/version', f'{DL}/reactome/version.txt')


def reactome_all():
    """Every human reaction Reactome maps to a stress-set protein (for the loss measure)."""
    import glob
    ids = set()
    for f in glob.glob(f'{DL}/reactome/map_*.json'):
        for r in json.loads(open(f, 'rb').read() or b'[]'):
            if r.get('speciesName') == 'Homo sapiens':
                ids.add(r['stId'])
    for st in sorted(ids):
        get(f'https://reactome.org/ContentService/data/query/enhanced/{st}', f'{DL}/reactome/rx/{st}.json')


def goa():
    q = urllib.parse.urlencode({'geneProductId': ','.join(TARGETS), 'taxonId': '9606',
                                'downloadLimit': 50000})
    get(f'https://www.ebi.ac.uk/QuickGO/services/annotation/downloadSearch?{q}', f'{DL}/goa/targets.gaf',
        accept='text/gaf')


if __name__ == '__main__':
    what = [a for a in sys.argv[1:] if not a.startswith('--')] or ['all']
    for w in (['signor', 'gocam', 'reactome', 'reactome_all', 'goa'] if 'all' in what else what):
        globals()[w]()
        print('done', w)
