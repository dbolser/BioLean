"""Program 10b: print the activity-level causal graph of GO-CAM models, with enablers and evidence.

    python3 -I scripts/stress/literature_gocam_chain.py 69ea894900002023 6a18a9ba00001280

One line per causal fact: subject activity [enabler] -relation-> object activity [enabler], ECO, source.
This is what the stress set's chains (cases G02, G03, G05) were read from.
"""
import json
import sys

SRC = '/tmp/biolean-10b/dl/gocam/models'
CAUSAL = {'RO:0002629', 'RO:0002630', 'RO:0002407', 'RO:0002409', 'RO:0012005', 'RO:0012006',
          'RO:0002411', 'RO:0002413', 'RO:0002304', 'RO:0002305'}

for mid in sys.argv[1:]:
    d = json.load(open(f'{SRC}/{mid}.json'))
    ind = {i['id']: i for i in d['individuals']}

    def lab(x):
        t = [c for c in ind[x].get('type', []) if c.get('type') == 'class']
        return f"{t[0]['id']} {t[0].get('label', '')}" if t else x

    en = {f['subject']: lab(f['object']) for f in d['facts'] if f['property'] == 'RO:0002333'}
    print('##', mid, next((a['value'] for a in d.get('annotations', []) if a['key'] == 'title'), ''))
    for f in d['facts']:
        if f['property'] not in CAUSAL:
            continue
        evs = [a['value'] for a in f.get('annotations', []) if a['key'] == 'evidence']
        ev = '; '.join(f"{lab(e).split(' ')[0]} {next((a['value'] for a in ind[e].get('annotations', []) if a['key'] == 'source'), '')}"
                       for e in evs if e in ind)
        print(f"  {lab(f['subject'])[:45]} [{en.get(f['subject'], '')[:24]}] -{f['property']}-> "
              f"{lab(f['object'])[:45]} [{en.get(f['object'], '')[:24]}] | {ev}")
