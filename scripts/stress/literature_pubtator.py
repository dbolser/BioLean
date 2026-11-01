"""Program 10b: what PubTator3 (text-mined, public domain) holds for the M8 exit question.

    python3 -I scripts/stress/literature_pubtator.py

Streams the local bulk file (release 2026-10-06, /home/danbolser/Work/IUK-IPF/data/sources/pubtator3/,
40.4M relations; read only) and counts relations with metformin (MESH:D008687) by type and partner.
Writes data/stress/10b/pubtator_metformin.tsv, and data/stress/10b/pubtator_metformin_g6pc1.tsv (every
metformin and G6PC1 relation with its PMID, for the S12 text-mined check in Literature.lean). PubTator3 entity classes are gene, chemical, disease,
species, mutation and cell line: lifespan and ageing are not among them unless the disease tagger
picks them up, so the counts for MESH:D000375 (Aging) and D008136 (Longevity) test that.
"""
import collections
import csv
import gzip
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = '/home/danbolser/Work/IUK-IPF/data/sources/pubtator3/2026-10-06/relation2pubtator3.gz'
OUT = os.path.join(ROOT, 'data', 'stress', '10b', 'pubtator_metformin.tsv')
OUT_G6PC1 = os.path.join(ROOT, 'data', 'stress', '10b', 'pubtator_metformin_g6pc1.tsv')
MET = 'Chemical|MESH:D008687'
PARTNERS = {
    'Disease|MESH:D000375': 'Aging (MeSH)', 'Disease|MESH:D008136': 'Longevity (MeSH)',
    'Disease|MESH:D019588': 'Aging, Premature', 'Disease|MESH:D003643': 'Death',
    'Disease|MESH:D003924': 'Diabetes Mellitus, Type 2', 'Gene|5562': 'PRKAA1 (AMPK alpha-1)',
    'Gene|5563': 'PRKAA2 (AMPK alpha-2)', 'Gene|4719': 'NDUFS1', 'Gene|2538': 'G6PC1',
}


def main():
    total = 0
    met = 0
    kinds = collections.Counter()
    per = collections.defaultdict(collections.Counter)
    g6pc1 = []
    with gzip.open(SRC, 'rt') as fh:
        for line in fh:
            total += 1
            f = line.rstrip('\n').split('\t')
            if len(f) < 4 or MET not in (f[2], f[3]):
                continue
            met += 1
            other = f[3] if f[2] == MET else f[2]
            kinds[other.split('|')[0]] += 1
            if other in PARTNERS:
                per[other][f[1]] += 1
            if other == 'Gene|2538':
                g6pc1.append((f[0], f[1]))
    with open(OUT, 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['partner', 'label', 'relation_type', 'count'])
        w.writerow(['ALL', 'all relations in the file', '', total])
        w.writerow(['ALL', 'relations with metformin', '', met])
        for k, v in kinds.most_common():
            w.writerow([k, 'partner class', '', v])
        for p, lab in PARTNERS.items():
            if not per[p]:
                w.writerow([p, lab, 'none', 0])
            for t, v in per[p].most_common():
                w.writerow([p, lab, t, v])
    with open(OUT_G6PC1, 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['pmid', 'relation_type'])
        w.writerows(sorted(g6pc1, key=lambda x: (x[1], int(x[0]))))
    print(open(OUT).read())
    print(open(OUT_G6PC1).read())


if __name__ == '__main__':
    main()
