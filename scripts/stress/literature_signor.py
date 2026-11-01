"""Program 10b: SIGNOR (NDEx CX2) to BioLean claims, and the mapping loss.

Run with `python3 -I scripts/stress/literature_signor.py` (reads untrusted downloads). Inputs:
/tmp/biolean-10b/dl/signor/signor_human.cx2. Outputs:
  /tmp/biolean-10b/work/signor_human_edges.tsv   every human edge, flat (scratch)
  data/stress/10b/signor_targets.tsv             edges touching a stress-set entity (CC BY-SA 4.0, SIGNOR)
  data/stress/10b/signor_loss.tsv                why edges do not map without loss, whole network and subset

Importer M0 (the baseline the stress set runs): protein -> PR:<UniProt>, chemical with ChEBI -> CHEBI,
'up/down-regulates activity' -> Claim.effect a s (activity b), 'quantity' -> (amount b), bare
'up/down-regulates' -> activity (a guess), SIGNOR complex/family/phenotype/stimulus -> no ontology id.
Mechanism, residue, direct flag and BTO cell/tissue go to Evidence.note (text only).

Two levels of loss:
  claim   the BioLean claim says something different from SIGNOR (or cannot be stated)
  strict  the claim is right but SIGNOR facts that BioLean cannot compute with are only in the note
"""
import collections
import csv
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = '/tmp/biolean-10b/dl/signor/signor_human.cx2'
WORK = '/tmp/biolean-10b/work'
OUT = os.path.join(ROOT, 'data', 'stress', '10b')

TARGET_IDS = {'uniprot:P01308', 'uniprot:P06213', 'uniprot:P01275', 'uniprot:P47871', 'uniprot:P01270',
              'uniprot:Q03431', 'uniprot:P41180', 'uniprot:P01258', 'uniprot:P30988', 'uniprot:P01185',
              'uniprot:P30518', 'uniprot:P14672', 'uniprot:Q14524', 'uniprot:P35498', 'CHEBI:17234',
              'CHEBI:17925', 'CHEBI:4167', 'CHEBI:29108', 'CHEBI:9937', 'CHEBI:34543', 'CHEBI:15422',
              'CHEBI:6801', 'signor:SIGNOR-C264', 'signor:SIGNOR-C15'}
COLS = ['src_name', 'src_rep', 'src_type', 'interaction', 'mechanism', 'tgt_name', 'tgt_rep', 'tgt_type',
        'citation', 'direct', 'cell_data', 'tissue_data', 'residue', 'sentence']


def parse():
    d = json.load(open(SRC))
    decl = next(a for a in d if 'attributeDeclarations' in a)['attributeDeclarations'][0]
    nodes_raw = next(a for a in d if 'nodes' in a)['nodes']
    edges_raw = next(a for a in d if 'edges' in a)['edges']

    def expand(v, dec):
        alias = {spec.get('a', k): k for k, spec in dec.items()}
        r = {alias.get(k, k): val for k, val in v.items()}
        for k, spec in dec.items():
            if k not in r and 'v' in spec:
                r[k] = spec['v']
        return r

    nodes = {n['id']: expand(n.get('v', {}), decl['nodes']) for n in nodes_raw}
    rows = []
    for e in edges_raw:
        a = expand(e.get('v', {}), decl['edges'])
        s, t = nodes[e['s']], nodes[e['t']]
        row = {'src_name': s.get('name', ''), 'src_rep': s.get('represents', ''), 'src_type': s.get('type', ''),
               'tgt_name': t.get('name', ''), 'tgt_rep': t.get('represents', ''), 'tgt_type': t.get('type', '')}
        for k in ('interaction', 'mechanism', 'citation', 'direct', 'cell_data', 'tissue_data', 'residue', 'sentence'):
            v = a.get(k, '')
            if isinstance(v, list):
                v = '|'.join(re.sub(r'<[^>]+>', '', str(x)).replace('\t', ' ').replace('\n', ' ').strip() for x in v)
            row[k] = str(v)
        rows.append(row)
    return rows


def ontology_id(rep, typ):
    """Does M0 have an OBO or UniProt id for this node?"""
    if rep.startswith('uniprot:'):
        return True
    if rep.startswith('CHEBI:'):
        return True
    return False


def reasons(r):
    """(claim-level reasons, strict reasons) for one edge under importer M0."""
    claim, strict = [], []
    it = r['interaction']
    mech = r['mechanism']
    if it == 'unknown':
        claim.append('no sign (unknown)')
    elif it == 'form complex':
        claim.append('unsigned binding (form complex)')
    elif it in ('up-regulates', 'down-regulates'):
        claim.append('activity or amount not said (bare up/down-regulates)')
    for side in ('src', 'tgt'):
        if not ontology_id(r[side + '_rep'], r[side + '_type']):
            claim.append(f'{side}: SIGNOR {r[side + "_type"]} with no ontology id')
    if 'activity' in it and r['tgt_type'] not in ('protein', 'complex', 'proteinfamily', 'fusion protein'):
        claim.append('activity of a non-protein target')
    if 'relocalization' in mech:
        claim.append('relocalization read as amount (compartment lost)')
    if r['cell_data'].strip('|') or r['tissue_data'].strip('|'):
        claim.append('BTO cell or tissue context dropped (claim wider than source)')
    if not r['citation'].strip('|'):
        claim.append('no PMID')
    if r['residue'].strip('|'):
        strict.append('residue or site only in note')
    if mech.strip('|') and mech not in ('binding', 'chemical activation', 'chemical inhibition'):
        strict.append('mechanism only in note')
    if r['direct'] == 'True':
        strict.append('direct flag only in note')
    return claim, strict


def summarise(rows, label):
    n = len(rows)
    claim_ok = strict_ok = 0
    per_claim, per_strict = collections.Counter(), collections.Counter()
    for r in rows:
        c, s = reasons(r)
        if not c:
            claim_ok += 1
            if not s:
                strict_ok += 1
        for x in set(c):
            per_claim[x] += 1
        for x in set(s):
            per_strict[x] += 1
    out = [(label, 'edges', n, '100.0'),
           (label, 'claim-level lossless', claim_ok, f'{100 * claim_ok / n:.1f}'),
           (label, 'strictly lossless', strict_ok, f'{100 * strict_ok / n:.1f}')]
    noid = sum(1 for r in rows if not ontology_id(r['src_rep'], r['src_type']) or not ontology_id(r['tgt_rep'], r['tgt_type']))
    out += [(label, 'claim: either end with no ontology id', noid, f'{100 * noid / n:.1f}')]
    out += [(label, f'claim: {k}', v, f'{100 * v / n:.1f}') for k, v in per_claim.most_common()]
    out += [(label, f'strict: {k}', v, f'{100 * v / n:.1f}') for k, v in per_strict.most_common()]
    return out


def main():
    rows = parse()
    os.makedirs(WORK, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(WORK, 'signor_human_edges.tsv'), 'w', newline='') as fh:
        w = csv.DictWriter(fh, COLS, delimiter='\t', extrasaction='ignore', lineterminator='\n')
        w.writeheader()
        w.writerows(rows)
    sub = [r for r in rows if r['src_rep'] in TARGET_IDS or r['tgt_rep'] in TARGET_IDS]
    with open(os.path.join(OUT, 'signor_targets.tsv'), 'w', newline='') as fh:
        w = csv.DictWriter(fh, COLS, delimiter='\t', extrasaction='ignore', lineterminator='\n')
        w.writeheader()
        for r in sub:
            w.writerow({k: (v[:400] if k == 'sentence' else v) for k, v in r.items()})
    table = summarise(rows, 'all human') + summarise(sub, 'stress entities')
    with open(os.path.join(OUT, 'signor_loss.tsv'), 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['set', 'measure', 'edges', 'percent'])
        w.writerows(table)
    for t in table:
        print('\t'.join(map(str, t)))
    types = collections.Counter(r['src_type'] for r in rows) + collections.Counter(r['tgt_type'] for r in rows)
    print('node types at edge ends:', dict(types.most_common()), file=sys.stderr)


if __name__ == '__main__':
    main()
