"""Program 10b, review pass: is every stress-set record really in its source, with the cited PMID?

    python3 -I scripts/stress/literature_records.py

Reads the extracts the parsers wrote (data/stress/10b/signor_targets.tsv, gocam_facts.tsv,
reactome_reactions.tsv, reactome_participants.tsv) and the untrusted GOA download
(/tmp/biolean-10b/dl/goa/targets.gaf, /tmp/biolean-10b/dl/quickgo/aak2_lifespan.json).
For each record behind a Lean statement in BioLean/Stress/Literature.lean it looks for a source row
with the same ends, the same kind of relation and the same PMID. Writes
data/stress/10b/records_checked.tsv and prints the misses.
"""
import csv
import json
import os
import sys

csv.field_size_limit(10 ** 9)
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'data', 'stress', '10b')
GAF = '/tmp/biolean-10b/dl/goa/targets.gaf'
AAK2 = '/tmp/biolean-10b/dl/quickgo/aak2_lifespan.json'


def tsv(name):
    return list(csv.DictReader(open(os.path.join(OUT, name)), delimiter='\t'))


# (Lean statement, source ends, interaction or relation substring, PMID)
SIGNOR = [
    ('S01s', 'INS', 'INSR', 'up-regulates activity', '2550426'), ('S01s', 'INS', 'INSR', 'up-regulates activity', '16956584'),
    ('S02a', 'INS', 'SLC2A4', 'up-regulates activity', '9415393'), ('S02b', 'SLC2A4', 'glucose', 'up-regulates quantity', '17403369'),
    ('S03', 'calcium(2+)', 'INS', 'up-regulates quantity', '24843404'), ('S04', 'α-D-glucose', 'GCG', 'up-regulates quantity', '31693916'),
    ('S05s', 'GCG', 'GCGR', 'up-regulates', '22863277'), ('S06s', 'PTH', 'PTH1R', 'up-regulates', '18981475'),
    ('S07', 'AVP', 'AVPR2', 'up-regulates', '1560825'), ('S08', 'vasopressin', 'AVPR2', 'up-regulates activity', '31160049'),
    ('S09', 'SCN1A', 'sodium(1+)', 'up-regulates quantity', '27262167'), ('S10', 'ATP synthase', 'ATP', 'up-regulates quantity', '21874297'),
    ('S11', 'hydron', 'ATP synthase', 'up-regulates activity', '31115493'), ('S12', 'metformin', 'G6PC1', 'up-regulates quantity', '17909097'),
    ('S12pck', 'metformin', 'PCK1', 'down-regulates quantity', '17909097'), ('S13', 'INSR', 'FABP4', 'unknown', '1648089'),
    ('S14b', 'AVPR2', 'GNAS', 'up-regulates activity', '31160049'), ('M01', 'metformin', 'PRKAA1', 'up-regulates activity', '11602624'),
    ('M02', 'metformin', 'NDUFS1', 'down-regulates activity', '24843020'),
]
# (Lean statement, model, subject enabler or term, relation, object enabler or term, PMID or ECO)
GOCAM = [
    ('S01g', '6a18a9ba00001280', 'P01308', 'RO:0002629', 'P06213', '14986111'),
    ('S05g', '68d5ebd600000298', 'P01275-PRO_0000011256', 'RO:0002629', 'P47871', '32193322'),
    ('S06g', '69ea894900002023', 'P01270', 'RO:0002629', 'Q03431', '35932760'),
    ('G02a', '6a18a9ba00001280', 'P06213', 'RO:0002629', 'P35568', '38056462'),
    ('G02b', '6a18a9ba00001280', 'P35568', 'RO:0002629', 'P48736', '7493946'),
    ('G02c', '6a18a9ba00001280', 'P48736', 'RO:0002407', 'P14672', '11277933'),
    ('G02d', '6a18a9ba00001280', 'P14672', 'BFO:0000050', 'GO:0042593', '14562105'),
    ('G03a', '69ea894900002023', 'CHEBI:29108', 'RO:0012005', 'P41180', '38632411'),
    ('G03b', '69ea894900002023', 'P41180', 'RO:0002629', 'P63096', '38632411'),
    ('G03c', '69ea894900002023', 'P63096', 'RO:0002409', 'P01270', '15331768'),
    ('G05a', '69ea894900002023', 'Q03431', 'RO:0002629', 'P63092', '19674967'),
    ('G05b', '69ea894900002023', 'P63092', 'RO:0002407', 'P17612', '10200251'),
    ('G06', '69ea894900002023', 'P17612', 'RO:0002629', 'Q9NQA5', '11029056'),
    ('G07g', '67e5e74400004286', 'P01185-PRO_0000020515', 'RO:0002629', 'P30518', '33742150'),
    ('G08', '66b5638000001772', 'P01258', 'RO:0002629', 'P30988', '32296767'),
    ('G09a', '6a18a9ba00001280', 'CHEBI:17234', 'RO:0001025', 'GO:0005737', '19251038'),
    ('G09b', '6a18a9ba00001280', 'CHEBI:17234', 'RO:0001025', 'GO:0005576', '19251038'),
    ('G10', '6a18a9ba00001280', 'GO:0005886', 'BFO:0000050', 'ZFA:0009102', '40811462'),
    ('G11', 'R-HSA-163210', 'GO:0015078', 'RO:0002234', 'CHEBI:30616', 'ECO:0000313'),
    ('G12', 'R-HSA-163210', 'GO:0015078', 'RO:0002411', 'GO:0046933', 'ECO:0000313'),
]
# (Lean statement, reaction, inferred?, GO BP, PMIDs used, participant names that must appear)
REACTOME = [
    ('R01', 'R-HSA-8981570', 'False', 'GO:1904659', ['1756912', '11994746', '1918382', '2656669'], ['Glc [extracellular region]', 'Glc [cytosol]']),
    ('R02', 'R-HSA-450095', 'False', '', ['8457197', '9751501', '9354798'], ['Glc [extracellular region]']),
    ('R03', 'R-HSA-74716', 'False', '', ['11737239', '7781591'], ['Insulin']),
    ('R04', 'R-HSA-164834', 'False', 'GO:0042776', [], ['ATP']),
    ('R05', 'R-HSA-420489', 'False', '', ['8397094'], ['PTH1R,PTH2R ligands']),
    ('R06', 'R-HSA-163625', 'False', '', ['11946536', '15464082', '2826231', '8144028'], ['GCG(53-81)']),
    ('R07', 'R-HSA-265166', 'True', 'GO:0030073', ['12403834', '17900700', '16443778', '12684222', '8997178', '18162464',
                                                    '14514350', '7641683', '11873862'], ['Ca2+ [cytosol]']),
    ('R08', 'R-HSA-5576895', 'False', '', ['21566136', '14500339', '1309946'], ['Na+ [cytosol]']),
]
# (Lean statement, UniProt, qualifier substring, GO, evidence code, reference)
GOA = [
    ('O01', 'P35498', 'enables', 'GO:0005248', 'IMP', 'PMID:14672992'),
    ('O02', 'P01270', 'enables', 'GO:0005179', 'IDA', 'PMID:35932760'),
    ('O04-yes', 'P30988', 'enables', 'GO:0032841', 'IPI', 'PMID:15563840'),
    ('O04-yes', 'P30988', 'enables', 'GO:0032841', 'IDA', 'PMID:8078488'),
    ('O04-yes', 'P30988', 'enables', 'GO:0032841', 'IDA', 'PMID:7769107'),
    ('O04-no', 'P30988', 'NOT|enables', 'GO:0032841', 'IDA', 'PMID:15563840'),
]


def main():
    out, miss = [], []
    sig = tsv('signor_targets.tsv')
    for st, a, b, it, pm in SIGNOR:
        hit = [r for r in sig if r['src_name'] == a and r['tgt_name'] == b and r['interaction'].startswith(it)
               and f'pubmed:{pm}' in r['citation']]
        out.append(['SIGNOR', st, f'{a} {it} {b} PMID {pm}', len(hit) > 0, hit[0]['interaction'] if hit else ''])
    gc = tsv('gocam_facts.tsv')
    for st, m, s, rel, o, ev in GOCAM:
        def has(r, x, side):
            return x in (r[side], r[side + '_enabler']) or r[side + '_enabler'].endswith(':' + x)
        hit = [r for r in gc if r['model'] == 'gomodel:' + m and r['rel'] == rel and has(r, s, 'subj') and has(r, o, 'obj')
               and (ev in r['source'] or ev in r['eco'].split('|'))]
        out.append(['GO-CAM', st, f'{m} {s} {rel} {o} {ev}', len(hit) > 0, hit[0]['class'] + ' ' + hit[0]['eco'] if hit else ''])
    rx = {r['reaction']: r for r in tsv('reactome_reactions.tsv')}
    parts = tsv('reactome_participants.tsv')
    for st, rid, inf, bp, pms, names in REACTOME:
        r = rx.get(rid)
        ok = bool(r) and r['inferred'] == inf and r['go_bp'] == bp and all(p in r['pmids'].split() for p in pms)
        pn = [p['name'] for p in parts if p['reaction'] == rid]
        ok = ok and all(any(n in x for x in pn) for n in names)
        out.append(['Reactome', st, f'{rid} inferred={inf} go={bp or "-"} {len(pms)} PMIDs', ok,
                    f"{r['name']}; {r['n_pmid']} PMIDs" if r else 'reaction not in extract'])
    gaf = [l.rstrip('\n').split('\t') for l in open(GAF) if not l.startswith('!')]
    for st, acc, q, go, code, ref in GOA:
        hit = [g for g in gaf if g[1] == acc and g[3] == q and g[4] == go and g[6] == code and ref in g[5]]
        out.append(['GOA', st, f'{acc} {q} {go} {code} {ref}', len(hit) > 0, hit[0][16] if hit and len(hit[0]) > 16 else ''])
    o2 = [g for g in gaf if g[1] == 'P01270' and g[4] == 'GO:0005179' and 'PMID:35932760' in g[5]]
    ext = o2[0][15] if o2 and len(o2[0]) > 15 else ''
    out.append(['GOA', 'O02', 'extension has_input(UniProtKB:Q03431),part_of(GO:0007189)',
                'has_input(UniProtKB:Q03431)' in ext and 'part_of(GO:0007189)' in ext, ext])
    s12 = [r for r in sig if r['src_name'] == 'metformin' and r['tgt_name'] == 'G6PC1' and 'pubmed:17909097' in r['citation']]
    phrase = 'inhibited the expression of the hepatic gluconeogenic genes pepck and g6pase'
    out.append(['SIGNOR', 'S12', f'stored sentence holds "{phrase}"', bool(s12) and phrase in s12[0]['sentence'],
                s12[0]['interaction'] if s12 else ''])
    a2 = json.load(open(AAK2))
    hit = [x for x in a2.get('results', []) if x.get('goId') == 'GO:0008340' and x.get('reference') == 'PMID:15574588'
           and x.get('goEvidence') == 'IMP']
    out.append(['GOA', 'O03', 'Q95ZQ4 involved_in GO:0008340 IMP PMID:15574588', len(hit) > 0,
                hit[0].get('assignedBy', '') if hit else ''])
    with open(os.path.join(OUT, 'records_checked.tsv'), 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t', lineterminator='\n')
        w.writerow(['source', 'statement', 'record', 'found', 'source_says'])
        w.writerows(out)
    bad = [r for r in out if not r[3]]
    print('records', len(out), 'found', len(out) - len(bad))
    for b in bad:
        print('MISSING', *b, sep='\t')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
