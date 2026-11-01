"""Program 10b: check every CURIE the stress set cites on OLS4 (read-only), and the is_a bridges.

    python3 scripts/stress/literature_ols.py

Raw JSON is cached in /tmp/biolean-10b/dl/ols/. Writes data/stress/10b/curies_checked.tsv (curie, label,
ontology, obsolete, date) and data/stress/10b/isa_checked.tsv (a, b, is b among a's hierarchical
ancestors on OLS4, a's direct parents). A later run reuses the cache; delete it to re-check.
"""
import datetime
import json
import os
import sys
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CACHE = '/tmp/biolean-10b/dl/ols'
OUT = os.path.join(ROOT, 'data', 'stress', '10b')
API = 'https://www.ebi.ac.uk/ols4/api'

CURIES = """
PR:P01308 PR:000009054 PR:000050339 PR:000050340 PR:000045358 PR:P06213 PR:P01275 PR:000019980 PR:P47871
PR:P01270 PR:000013429 PR:Q03431 PR:P41180 PR:P01258 PR:P30988 PR:P01185 PR:P30518 PR:P14672 PR:Q14524
PR:P35498 PR:P48736 PR:P15090 PR:Q95ZQ4 PR:P17612 PR:P35575 PR:P35558 PR:P63092 PR:P63096 PR:Q9NQA5 PR:P35568 PR:Q13131 PR:P54646 PR:P28331 PR:P14735 PR:P43220
CHEBI:17234 CHEBI:17925 CHEBI:4167 CHEBI:17634 CHEBI:29108 CHEBI:29101 CHEBI:15422 CHEBI:30616 CHEBI:456216
CHEBI:16761 CHEBI:9937 CHEBI:34543 CHEBI:5931 CHEBI:6801 CHEBI:80270 CHEBI:15378 CHEBI:6456 CHEBI:5391
GO:0098708 GO:1904659 GO:0030073 GO:0015986 GO:0006754 GO:0005248 GO:0045259 GO:0046933 GO:0070295
GO:0098703 GO:0070293 GO:0005179 GO:0005009 GO:0004991 GO:0004930 GO:0004967 GO:0005000 GO:0004948
GO:0055056 GO:0042593 GO:0051899 GO:0008340 GO:0007568 GO:0005886 GO:0005829 GO:0005576 GO:0005737
GO:0032991 GO:0031588 GO:0046888 GO:0006874 GO:0032841 GO:0042776 GO:0005739 GO:0005759 GO:0003925 GO:0016303 GO:0030159 GO:0004691 GO:0005262 GO:0030070
UBERON:0000178 UBERON:0001264 UBERON:0001132 UBERON:0002046 UBERON:0001898 UBERON:0004135 UBERON:0001134
UBERON:0002113 CL:0000169 CL:0000171 CL:0002279 ZFA:0009102 EMAPA:35988 BTO:0000783 BTO:0000887 BTO:0000007
NCBITaxon:9606 NCBITaxon:10090 NCBITaxon:10116 NCBITaxon:6239 PATO:0000050 MONDO:0005148 EFO:0007796
ECO:0000314 ECO:0000315 ECO:0000303 ECO:0000304 ECO:0000250 ECO:0000313 ECO:0000318
GO:0007189 GO:0015078 BTO:0002524
""".split()

# (a, b): is b an is_a ancestor of a? The bridges an importer would need.
ISA = [('PR:P01308', 'PR:000009054'), ('PR:000050340', 'PR:000050339'), ('PR:P01270', 'PR:000013429'),
       ('PR:P01275', 'PR:000019980'), ('CHEBI:17925', 'CHEBI:17234'), ('CHEBI:4167', 'CHEBI:17234'),
       ('CHEBI:17925', 'CHEBI:4167'), ('CHEBI:30616', 'CHEBI:15422'), ('CHEBI:34543', 'CHEBI:9937'),
       ('CHEBI:5931', 'CHEBI:5931'), ('GO:0098708', 'GO:1904659'), ('GO:0015986', 'GO:0006754'),
       ('GO:0098703', 'GO:0070293'), ('GO:0042776', 'GO:0015986'), ('CL:0000169', 'CL:0000169')]


def iri(c):
    p, l = c.split(':', 1)
    return f'http://purl.obolibrary.org/obo/{p}_{l}'


def fetch(url, path):
    if os.path.exists(path):
        return json.load(open(path))
    for attempt in range(3):
        try:
            raw = urllib.request.urlopen(url, timeout=60).read()
            open(path, 'wb').write(raw)
            time.sleep(0.1)
            return json.loads(raw)
        except Exception as e:  # noqa: BLE001
            print('retry', url, e, file=sys.stderr)
            time.sleep(2)
    return {}


def term(c):
    d = fetch(f'{API}/terms?' + urllib.parse.urlencode({'obo_id': c, 'size': 50}),
              os.path.join(CACHE, c.replace(':', '_') + '.json'))
    ts = d.get('_embedded', {}).get('terms', [])
    if not ts:
        return None
    t = ([x for x in ts if x.get('is_defining_ontology')] or ts)[0]
    return t


def ancestors(c, kind):
    t = term(c)
    if not t:
        return []
    onto = t['ontology_name']
    enc = urllib.parse.quote(urllib.parse.quote(iri(c), safe=''), safe='')
    d = fetch(f'{API}/ontologies/{onto}/terms/{enc}/{kind}?size=500',
              os.path.join(CACHE, f'{kind}_{c.replace(":", "_")}.json'))
    return [(x.get('obo_id'), x.get('label')) for x in d.get('_embedded', {}).get('terms', [])]


def main():
    os.makedirs(CACHE, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    today = datetime.date.today().isoformat()
    bad = 0
    with open(os.path.join(OUT, 'curies_checked.tsv'), 'w') as fh:
        fh.write('curie\tlabel\tontology\tobsolete\tchecked\n')
        for c in CURIES:
            t = term(c)
            if not t:
                fh.write(f'{c}\tNOT FOUND\t\t\t{today}\n')
                bad += 1
                continue
            fh.write(f"{c}\t{t.get('label')}\t{t.get('ontology_name')}\t{t.get('is_obsolete')}\t{today}\n")
            print(c, t.get('label'), t.get('ontology_name'), 'obsolete' if t.get('is_obsolete') else '')
    with open(os.path.join(OUT, 'isa_checked.tsv'), 'w') as fh:
        fh.write('a\tb\tb_is_ancestor_of_a\tparents_of_a\tchecked\n')
        for a, b in ISA:
            anc = ancestors(a, 'hierarchicalAncestors')
            par = ancestors(a, 'hierarchicalParents')
            hit = a == b or any(i == b for i, _ in anc)
            fh.write(f"{a}\t{b}\t{hit}\t{'; '.join(f'{i} {l}' for i, l in par[:6])}\t{today}\n")
            print('isa', a, b, hit, par[:4])
    print('not found:', bad)


if __name__ == '__main__':
    main()
