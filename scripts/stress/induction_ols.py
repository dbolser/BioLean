"""Program 10c: check every CURIE the stress set cites on OLS4. Two steps, so that downloaded data is only ever read
by an isolated interpreter:
  python3 scripts/stress/induction_ols.py list            writes data/stress/10c/curies_cited.txt (from the tasks)
  python3 -I scripts/stress/induction_ols.py fetch <list> <dl_dir> <out_tsv>
                                                          downloads each term's OLS4 JSON to <dl_dir> and writes
                                                          curie, ontology, OLS4 label, obsolete, checked date
BLN: curies are BioLean placeholders for conditions (not an ontology) and are listed as such."""
import sys, json, re, os, urllib.request, urllib.parse, time

ONT = {'GO': 'go', 'UBERON': 'uberon', 'CL': 'cl', 'CHEBI': 'chebi', 'NCBITaxon': 'ncbitaxon', 'PR': 'pr',
       'PATO': 'pato', 'MONDO': 'mondo', 'RO': 'ro', 'BFO': 'bfo', 'SO': 'so', 'OBA': 'oba', 'PO': 'po', 'HP': 'hp',
       'UPHENO': 'upheno', 'MP': 'mp'}
SCAN = ['data/stress/10c/rule_judgements.tsv', 'BioLean/Stress/Induction.lean', 'BioLean/Proto/Induction.lean',
        'scripts/stress/induction_popper.py', 'scripts/stress/induction_tasks.py', 'docs/programs/10c-rule-induction.md',
        'data/stress/10c/cases.tsv', 'data/stress/10c/precision_judged.tsv', 'data/stress/10c/popper/predictions_judged.tsv']
EXTRA = ['UBERON:0016526', 'UBERON:0000073', 'UBERON:0002616', 'CHEBI:23888', 'CHEBI:35472', 'CHEBI:24261', 'CHEBI:25354',
         'GO:0005618', 'GO:0022403', 'CL:0000151', 'GO:0022414', 'PR:000000001', 'GO:0008152', 'CL:0000000', 'CL:0000255',
         'NCBITaxon:10239', 'NCBITaxon:2759', 'NCBITaxon:1117', 'UBERON:0000349', 'GO:0006754', 'GO:0006412', 'GO:0046903',
         'GO:0045333', 'GO:0009058', 'GO:0006099', 'CHEBI:8005', 'GO:0009295', 'UBERON:0001017', 'CL:0000520',
         'BFO:0000050', 'BFO:0000051', 'BFO:0000066', 'RO:0001025', 'RO:0002215', 'RO:0002216', 'RO:0002233', 'RO:0002234',
         'RO:0001000', 'RO:0002162', 'RO:0002331', 'RO:0002131', 'RO:0002504']


def curies_from_tasks():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import induction_tasks as TK
    out = set(EXTRA)
    for t in TK.TASKS:
        for q in t.get('pos', []) + t.get('neg', []) + [e[:3] for e in t.get('extra', [])]:
            for c in q[1:3]: out |= set(re.findall(r'[A-Za-z]+:[A-Za-z0-9_]+', c))
    repo = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../..')
    for f in SCAN + sys.argv[2:]:
        txt = open(os.path.join(repo, f)).read()
        out |= {c for c in re.findall(r'\b(?:GO|UBERON|CL|CHEBI|NCBITaxon|PR|PATO|MONDO|RO|BFO|UPHENO|MP|HP|SO|PO|OBA):[0-9]+', txt)}
        out |= {c[2:].replace('_', ':', 1) for c in re.findall(r'\be_(?:GO|UBERON|CL|CHEBI|NCBITaxon|PR|PATO|MONDO)_[0-9]+', txt)}
    return sorted(out)


def fetch(curie, dl):
    pre = curie.split(':')[0]
    if pre not in ONT: return None
    path = os.path.join(dl, curie.replace(':', '_') + '.json')
    if not os.path.exists(path):
        kind = 'properties' if pre in ('RO', 'BFO') else 'terms'   # relations are object properties, in RO
        url = f'https://www.ebi.ac.uk/ols4/api/ontologies/{"ro" if pre in ("RO", "BFO") else ONT[pre]}/{kind}?' + urllib.parse.urlencode({'obo_id': curie})
        try:
            with urllib.request.urlopen(url, timeout=30) as r: data = r.read()
        except Exception as e:
            iri = 'http://purl.obolibrary.org/obo/' + curie.replace(':', '_')
            url2 = url.split('?')[0] + '?' + urllib.parse.urlencode({'iri': iri})
            try:
                with urllib.request.urlopen(url2, timeout=30) as r: data = r.read()
            except Exception as e2:
                return dict(error=f'{e}; by iri: {e2}')
        open(path, 'wb').write(data); time.sleep(0.1)
    try:
        d = json.load(open(path))
        t = d['_embedded'].get('terms', d['_embedded'].get('properties'))[0]
        return dict(label=t.get('label'), obsolete=t.get('is_obsolete'), iri=t.get('iri'))
    except Exception as e:
        return dict(error=f'parse: {e}')


if __name__ == '__main__':
    if sys.argv[1] == 'list':
        out = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../data/stress/10c/curies_cited.txt')
        open(out, 'w').write('\n'.join(curies_from_tasks()) + '\n'); print(out)
    else:
        lst, dl, out = sys.argv[2:5]
        os.makedirs(dl, exist_ok=True)
        rows = ['curie\tontology\tols4_label\tobsolete\tchecked']
        for c in [l.strip() for l in open(lst) if l.strip()]:
            if c.startswith('BLN:'): rows.append(f'{c}\tBioLean placeholder\t(not an ontology term)\t-\t2026-11-01'); continue
            r = fetch(c, dl)
            if r is None: rows.append(f'{c}\t?\tUNVERIFIED (prefix not on OLS4)\t-\t2026-11-01'); continue
            if 'error' in r: rows.append(f'{c}\t{ONT[c.split(":")[0]]}\tUNVERIFIED ({r["error"][:60]})\t-\t2026-11-01'); continue
            rows.append(f'{c}\t{ONT[c.split(":")[0]]}\t{r["label"]}\t{r["obsolete"]}\t2026-11-01')
        open(out, 'w').write('\n'.join(rows) + '\n')
        print(len(rows) - 1, 'curies;', sum('UNVERIFIED' in r for r in rows), 'unverified;', sum('\tTrue\t' in r for r in rows), 'obsolete')
