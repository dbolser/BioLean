"""Program 10b: Reactome reactions to BioLean `has_input` / `has_output` claims, and the mapping loss.

Run with `python3 -I scripts/stress/literature_reactome.py`. Reads /tmp/biolean-10b/dl/reactome/rx/*.json
(Reactome ContentService 'enhanced' query, release in dl/reactome/version.txt; untrusted). Writes
data/stress/10b/reactome_participants.tsv and data/stress/10b/reactome_loss.tsv (Reactome data, CC0).

Importer M0: a reaction is an `Entity .process`, grounded to its GO biological-process cross-reference
when it has one and to a placeholder `Reactome:R-HSA-...` otherwise. Each input is `Claim.rel has_input`,
each output `Claim.rel has_output`. A participant is grounded by its reference entity: ChEBI for a
SimpleEntity, UniProt (as PR:<acc>) for a whole chain, refined by its compartment with
`Entity.inCtx { component := ... }` (the core can say this). Complexes have no OBO id; sets (DefinedSet,
CandidateSet) are unions of entities, which the core has no type for; a chain with coordinates is a
cleavage product (insulin chains, glucagon 53-81), which needs a PR cleavage-product term.
"""
import collections
import csv
import glob
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = '/tmp/biolean-10b/dl/reactome/rx'
OUT = os.path.join(ROOT, 'data', 'stress', '10b')


def index(d):
    seen = {}

    def walk(x):
        if isinstance(x, dict):
            if 'dbId' in x and 'schemaClass' in x:
                seen.setdefault(x['dbId'], x)
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(d)
    return seen


def participant_class(p):
    sc = p.get('schemaClass', '?')
    if sc == 'ChemicalDrug' or sc == 'ProteinDrug':
        return 'lossless', 'drug with ChEBI or IUPHAR id'
    if sc == 'SimpleEntity':
        return 'lossless', 'chemical (ChEBI) in a compartment: CHEBI.inCtx {component}'
    if sc == 'EntityWithAccessionedSequence':
        name = p.get('displayName', '')
        if ' gene' in name:
            return 'lossless', 'gene (Ensembl reference) as Kind.gene'
        if re.search(r'\(\d+-\d+\)', name) or name.startswith('C Peptide'):
            return 'lossy', 'cleavage product or processed chain (named with coordinates): needs a PR term'
        if re.match(r'^(\d+x)?p-[A-Z]\d+', name) or re.search(r'\bp-[STY]\d+', name):
            return 'lossy', 'modified chain (phospho-site): residue lost'
        return 'lossless', 'whole chain (UniProt as PR) in a compartment'
    if sc == 'Complex':
        return 'lossy', 'Reactome complex: no OBO id (GO CC or ComplexPortal by hand)'
    if sc in ('DefinedSet', 'CandidateSet'):
        return 'inexpressible', 'set of alternatives (union of entities): no type for it'
    if sc in ('GenomeEncodedEntity', 'OtherEntity', 'Polymer'):
        return 'lossy', f'{sc}: no reference id'
    return 'lossy', f'other {sc}'


def main():
    prow, rrow = [], []
    pc, rc = collections.Counter(), collections.Counter()
    for f in sorted(glob.glob(os.path.join(SRC, '*.json'))):
        d = json.load(open(f))
        if d.get('schemaClass') not in ('Reaction', 'BlackBoxEvent', 'Polymerisation', 'Depolymerisation',
                                        'FailedReaction'):
            continue
        seen = index(d)
        pmids = [str(x.get('pubMedIdentifier')) for x in d.get('literatureReference') or []
                 if isinstance(x, dict) and x.get('pubMedIdentifier')]
        gobp = (d.get('goBiologicalProcess') or {}).get('accession', '')
        rr = {'reaction': d['stId'], 'name': d.get('displayName', ''), 'class': d.get('schemaClass'),
              'inferred': d.get('isInferred'), 'go_bp': f'GO:{gobp}' if gobp else '', 'n_pmid': len(pmids),
              'pmids': ' '.join(pmids)}
        rrow.append(rr)
        rc['reactions'] += 1
        rc['inferred from another species'] += bool(d.get('isInferred'))
        rc['no PMID on the reaction'] += not pmids
        rc['has a GO BP cross-reference'] += bool(gobp)
        rc['BlackBoxEvent (steps omitted)'] += d.get('schemaClass') == 'BlackBoxEvent'
        parts = [('input', p) for p in d.get('input') or []] + [('output', p) for p in d.get('output') or []]
        parts += [('catalyst', ca.get('physicalEntity')) for ca in d.get('catalystActivity') or [] if isinstance(ca, dict)]
        parts += [('regulator', rg.get('regulator')) for rg in d.get('regulatedBy') or [] if isinstance(rg, dict)]
        io_ok = True
        for role, p in parts:
            if isinstance(p, int):
                p = seen.get(p, {})
            if not isinstance(p, dict):
                continue
            k, why = participant_class(p)
            if role in ('input', 'output') and k != 'lossless':
                io_ok = False
            pc[(role, k, why)] += 1
            prow.append({'reaction': d['stId'], 'role': role, 'entity': p.get('stId', ''),
                         'name': p.get('displayName', ''), 'schema': p.get('schemaClass', ''),
                         'class': k, 'reason': why})
        rc['every input and output lossless'] += io_ok
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, 'reactome_participants.tsv'), 'w', newline='') as fh:
        w = csv.DictWriter(fh, list(prow[0].keys()), delimiter='\t', lineterminator='\n')
        w.writeheader()
        w.writerows(prow)
    with open(os.path.join(OUT, 'reactome_reactions.tsv'), 'w', newline='') as fh:
        w = csv.DictWriter(fh, list(rrow[0].keys()), delimiter='\t', lineterminator='\n')
        w.writeheader()
        w.writerows(rrow)
    n = rc['reactions']
    table = [('reaction', k, v, f'{100 * v / n:.1f}') for k, v in rc.items()]
    io = [x for x in prow if x['role'] in ('input', 'output')]
    m = len(io)
    tot = collections.Counter(x['class'] for x in io)
    table += [('input/output', 'participants', m, '100.0')]
    table += [('input/output', k, v, f'{100 * v / m:.1f}') for k, v in tot.most_common()]
    why = collections.Counter((x['class'], x['reason']) for x in io)
    table += [('input/output', f'{k}: {r}', v, f'{100 * v / m:.1f}') for (k, r), v in why.most_common()]
    allp = len(prow)
    table += [('all roles', f'{role} {k}: {r}', v, f'{100 * v / allp:.1f}')
              for (role, k, r), v in sorted(pc.items(), key=lambda x: -x[1])]
    with open(os.path.join(OUT, 'reactome_loss.tsv'), 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['level', 'measure', 'count', 'percent'])
        w.writerows(table)
    for t in table:
        print('\t'.join(map(str, t)))


if __name__ == '__main__':
    main()
