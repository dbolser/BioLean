"""Program 10b: GOA annotations (GAF 2.2 from QuickGO) to BioLean `Claim.rel`, and the mapping loss.

Run with `python3 -I scripts/stress/literature_goa.py`. Reads /tmp/biolean-10b/dl/goa/targets.gaf
(untrusted; the stress-set gene products, human). Writes data/stress/10b/goa_loss.tsv (GO data, CC BY 4.0).

Importer M0: `enables` -> Claim.rel enables P F; `involved_in` -> rel involved_in P BP; `located_in`,
`is_active_in`, `part_of` -> rel located_in / part_of P CC; a NOT qualifier -> Claim.notRel. The
reference becomes Evidence.pmid (GO_REF -> 0) and the GO evidence code picks the kind.
"""
import collections
import csv
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = '/tmp/biolean-10b/dl/goa/targets.gaf'
OUT = os.path.join(ROOT, 'data', 'stress', '10b')
REL_OK = {'enables', 'involved_in', 'located_in', 'is_active_in', 'part_of', 'contributes_to',
          'acts_upstream_of', 'acts_upstream_of_or_within', 'colocalizes_with',
          'acts_upstream_of_positive_effect', 'acts_upstream_of_negative_effect',
          'acts_upstream_of_or_within_positive_effect', 'acts_upstream_of_or_within_negative_effect'}
INFERRED = {'IEA': 'electronic (IEA)', 'IBA': 'phylogenetic (IBA)', 'ISS': 'sequence similarity (ISS)',
            'ISO': 'orthology (ISO)', 'ISA': 'sequence alignment (ISA)', 'ISM': 'sequence model (ISM)',
            'IKR': 'key residues (IKR)', 'RCA': 'computational (RCA)'}


def main():
    rows = [l.rstrip('\n').split('\t') for l in open(SRC) if l.strip() and not l.startswith('!')]
    n = len(rows)
    c = collections.Counter()
    lossless = 0
    for r in rows:
        r += [''] * (17 - len(r))
        qual, ref, code, ext, form = r[3], r[5], r[6], r[15], r[16]
        why = []
        rel = qual.replace('NOT|', '')
        if 'NOT' in qual:
            c['NOT qualifier: Claim.notRel (expressible)'] += 1
        if rel not in REL_OK:
            why.append(f'relation {rel}')
        if not ref.startswith('PMID:'):
            why.append('no PMID (GO_REF or other)')
        if code in INFERRED:
            why.append(f'inferred annotation: {INFERRED[code]}')
        if ext:
            why.append('annotation extension dropped (context: has_input, occurs_in, ...)')
        if form:
            why.append('gene-product form (isoform or cleavage chain) dropped')
        for x in why:
            c[x] += 1
        if not why:
            lossless += 1
    table = [('annotations', n, '100.0'), ('lossless, with PMID, experimental or curator code', lossless,
                                          f'{100 * lossless / n:.1f}')]
    table += [(k, v, f'{100 * v / n:.1f}') for k, v in c.most_common()]
    codes = collections.Counter(r[6] for r in rows)
    table += [(f'evidence code {k}', v, f'{100 * v / n:.1f}') for k, v in codes.most_common()]
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, 'goa_loss.tsv'), 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['measure', 'annotations', 'percent'])
        w.writerows(table)
    for t in table:
        print('\t'.join(map(str, t)))


if __name__ == '__main__':
    main()
