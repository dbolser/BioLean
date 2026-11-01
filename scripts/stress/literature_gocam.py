"""Program 10b: GO-CAM models (Minerva JSON) to BioLean claims, and the mapping loss.

Run with `python3 -I scripts/stress/literature_gocam.py`. Reads /tmp/biolean-10b/dl/gocam/models/*.json
(untrusted). Writes data/stress/10b/gocam_facts.tsv (one row per fact, CC BY 4.0, GO Consortium) and
data/stress/10b/gocam_loss.tsv.

GO-CAM is activity-centric: a molecular-function individual is `enabled_by` a gene product, and
causal relations join activities. Importer M0 reads:
  activity A enabled_by P, A -[signed causal]-> B enabled_by Q   =>  Claim.effect P s (activity Q)
  chemical C -[RO:0012005/6]-> B enabled_by Q                    =>  Claim.effect C s (activity Q)
  A enabled_by P, A part_of BP                                   =>  Claim.rel involved_in P BP
  A has_input / has_output X                                     =>  Claim.rel has_input (A) X
  A occurs_in CC                                                 =>  Claim.rel occurs_in (A) CC
The model is a set of individuals. Lifting a fact about individuals to a class-level claim ("every
X has some Y") is sound for process and activity facts (GO's own GPAD export does it) and false for
location facts: "this plasma membrane is part of this distal tubule" is not "every plasma membrane
is part of a distal tubule".
"""
import collections
import csv
import glob
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = '/tmp/biolean-10b/dl/gocam/models'
OUT = os.path.join(ROOT, 'data', 'stress', '10b')

SIGNED = {'RO:0002629': '+', 'RO:0002630': '-', 'RO:0002407': '+', 'RO:0002409': '-',
          'RO:0012005': '+', 'RO:0012006': '-', 'RO:0002213': '+', 'RO:0002212': '-',
          'RO:0004046': '-', 'RO:0004047': '+'}
DIRECT = {'RO:0002629', 'RO:0002630'}
UNSIGNED = {'RO:0002411': 'causally upstream of', 'RO:0002413': 'directly provides input for',
            'RO:0002313': 'transports or maintains localization of', 'RO:0002304': 'causally upstream of, positive effect',
            'RO:0002305': 'causally upstream of, negative effect', 'RO:0002418': 'causally upstream of or within'}
TARGET_OBO = ('GO:', 'CHEBI:', 'UniProtKB:', 'CL:', 'UBERON:', 'NCBITaxon:')


def individuals(d):
    ind = {}
    for i in d['individuals']:
        cls = [t for t in i.get('type', []) if t.get('type') == 'class']
        ind[i['id']] = {'cls': cls[0]['id'] if cls else '?', 'label': cls[0].get('label', '') if cls else '',
                        'root': [t.get('id') for t in i.get('root-type', [])],
                        'ann': {a['key']: a['value'] for a in i.get('annotations', [])}}
    return ind


def flatten(path):
    d = json.load(open(path))
    title = next((a['value'] for a in d.get('annotations', []) if a['key'] == 'title'), '')
    ind = individuals(d)
    enabler = {}
    for f in d.get('facts', []):
        if f['property'] == 'RO:0002333':
            enabler[f['subject']] = ind[f['object']]['cls']
    rows = []
    for f in d.get('facts', []):
        evs = [a['value'] for a in f.get('annotations', []) if a['key'] == 'evidence']
        eco = [ind[e]['cls'] for e in evs if e in ind]
        src = [ind[e]['ann'].get('source', '') for e in evs if e in ind]
        s, o = ind[f['subject']], ind[f['object']]
        rows.append({'model': d['id'], 'title': title[:90], 'subj': s['cls'], 'subj_label': s['label'],
                     'subj_root': 'MF' if 'GO:0003674' in s['root'] else ('BP' if 'GO:0008150' in s['root'] else
                                  ('CC' if 'GO:0005575' in s['root'] else 'other')),
                     'subj_enabler': enabler.get(f['subject'], ''), 'rel': f['property'],
                     'obj': o['cls'], 'obj_label': o['label'],
                     'obj_root': 'MF' if 'GO:0003674' in o['root'] else ('BP' if 'GO:0008150' in o['root'] else
                                 ('CC' if 'GO:0005575' in o['root'] else 'other')),
                     'obj_enabler': enabler.get(f['object'], ''), 'eco': '|'.join(eco), 'source': '|'.join(src)})
    return rows


def classify(r):
    """(class, reason) by meaning only. class: absorbed, lossless, rel-only, false-as-class, lossy.
    A missing PMID is counted separately (`has_pmid`)."""
    rel, s, o = r['rel'], r['subj'], r['obj']
    ends = [x for x in (s, o, r['subj_enabler'], r['obj_enabler']) if x]
    bad = [x for x in ends if not x.startswith(TARGET_OBO)]
    if rel == 'RO:0002333':
        return 'absorbed', 'enabled_by: names the agent of an activity'
    if bad:
        return 'lossy', f'term outside the target ontologies ({bad[0].split(":")[0]})'
    if rel in SIGNED:
        why = 'signed causal: Claim.effect enabler s (activity enabler)'
        if r['obj_root'] == 'MF' and not r['obj_enabler']:
            why = 'signed causal; object activity has no enabler: Target.activity of a GO function'
        return 'lossless', why + (' (direct flag only in note)' if rel in DIRECT else '')
    if rel in UNSIGNED:
        return 'rel-only', f'unsigned causal ({UNSIGNED[rel]}): Claim.rel, does not chain with effects'
    if rel in ('RO:0002233', 'RO:0002234'):
        return 'lossless', 'has_input / has_output: Claim.rel'
    if rel == 'BFO:0000050' and r['subj_root'] in ('MF', 'BP') and r['obj_root'] == 'BP':
        return 'lossless', 'activity or process part_of process: Claim.rel (involved_in / part_of)'
    if rel == 'BFO:0000066':
        return 'lossless', 'occurs_in: Claim.rel occurs_in (activity in component or cell)'
    if rel in ('BFO:0000050', 'RO:0001025', 'BFO:0000051'):
        return 'false-as-class', ('location of an individual (component in anatomy, chemical in component): '
                                  'true in the model, false as a class-level claim')
    return 'lossy', f'other relation {rel}'


def has_pmid(r):
    return any(x.startswith('PMID:') for x in r['source'].split('|'))


def main():
    rows = []
    for f in sorted(glob.glob(os.path.join(SRC, '*.json'))):
        rows += flatten(f)
    os.makedirs(OUT, exist_ok=True)
    cols = list(rows[0].keys()) + ['class', 'reason', 'has_pmid']
    counts, reasons, ok_pmid = collections.Counter(), collections.Counter(), 0
    for r in rows:
        r['class'], r['reason'] = classify(r)
        r['has_pmid'] = has_pmid(r)
        counts[r['class']] += 1
        reasons[(r['class'], r['reason'])] += 1
        if r['class'] == 'lossless' and r['has_pmid']:
            ok_pmid += 1
    with open(os.path.join(OUT, 'gocam_facts.tsv'), 'w', newline='') as fh:
        w = csv.DictWriter(fh, cols, delimiter='\t', lineterminator='\n')
        w.writeheader()
        w.writerows(rows)
    n = len(rows)
    claims = [r for r in rows if r['class'] != 'absorbed']
    m = len(claims)
    nop = sum(1 for r in claims if not r['has_pmid'])
    table = [('facts', n, ''), ('facts that are claims (not enabled_by)', m, '100.0')]
    for k in ('lossless', 'rel-only', 'false-as-class', 'lossy'):
        table.append((k, counts[k], f'{100 * counts[k] / m:.1f}'))
    table.append(('no PMID on the fact (GO_REF or none)', nop, f'{100 * nop / m:.1f}'))
    table.append(('lossless and with a PMID', ok_pmid, f'{100 * ok_pmid / m:.1f}'))
    for (k, why), v in sorted(reasons.items(), key=lambda x: -x[1]):
        if k != 'absorbed':
            table.append((f'{k}: {why}', v, f'{100 * v / m:.1f}'))
    eco = collections.Counter(e for r in claims for e in r['eco'].split('|') if e)
    table += [(f'evidence {k}', v, '') for k, v in eco.most_common()]
    models = sorted({(r['model'], r['title']) for r in rows})
    table += [(f'model {mm}', 0, t) for mm, t in models]
    with open(os.path.join(OUT, 'gocam_loss.tsv'), 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['measure', 'facts', 'percent_of_claims'])
        w.writerows(table)
    for t in table:
        print('\t'.join(map(str, t)))


if __name__ == '__main__':
    main()
