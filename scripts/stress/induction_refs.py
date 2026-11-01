"""Program 10c: check every reference the program cites. Two steps, so downloaded data is read only by an isolated
interpreter:
  python3 scripts/stress/induction_refs.py fetch <dl_dir>              downloads Crossref (DOI), Europe PMC (PMID) and
                                                                       Reactome (stable id) records
  python3 -I scripts/stress/induction_refs.py show <dl_dir> <out_tsv>  writes key, source, first author, year, title
The claimed author and title are in REFS; `show` marks a row OK when the first author's family name and the start of
the title match the record, else CHECK."""
import sys, os, json, urllib.request, urllib.parse, time, re, unicodedata

REFS = [  # (key, kind, id, claimed first-author family name, claimed title start)
    ('Galarraga2013', 'doi', '10.1145/2488388.2488425', 'Galárraga', 'AMIE: association rule mining under incomplete evidence'),
    ('Galarraga2015', 'doi', '10.1007/s00778-015-0394-1', 'Galárraga', 'Fast rule mining in ontological knowledge bases with AMIE'),
    ('Lajus2020', 'doi', '10.1007/978-3-030-49461-2_3', 'Lajus', 'Fast and exact rule mining with AMIE 3'),
    ('Cropper2021', 'doi', '10.1007/s10994-020-05934-z', 'Cropper', 'Learning programs by learning from failures'),
    ('Cropper2022', 'doi', '10.1007/s10994-021-06089-1', 'Cropper', 'Inductive logic programming at 30'),
    ('CropperMorel2021pi', 'datacite', '10.48550/arXiv.2104.14426', 'Cropper', 'Predicate invention by learning from failures'),
    ('Muggleton2015', 'doi', '10.1007/s10994-014-5471-y', 'Muggleton', 'Meta-interpretive learning of higher-order dyadic datalog'),
    ('Muggleton1995', 'doi', '10.1007/BF03037227', 'Muggleton', 'Inverse entailment and progol'),
    ('MuggletonBuntine1988', 'doi', '10.1016/B978-0-934613-64-4.50040-2', 'Muggleton', 'Machine invention of first-order predicates'),
    ('Gentner1983', 'doi', '10.1207/s15516709cog0702_3', 'Gentner', 'Structure-mapping: a theoretical framework for analogy'),
    ('King2004', 'doi', '10.1038/nature02236', 'King', 'Functional genomic hypothesis generation and experimentation by a robot scientist'),
    ('Muggleton1992', 'doi', '10.1093/protein/5.7.647', 'Muggleton', 'Protein secondary structure prediction using logic-based machine learning'),
    ('Meilicke2019', 'doi', '10.24963/ijcai.2019/435', 'Meilicke', 'Anytime bottom-up rule learning for knowledge graph completion'),
    ('Brown2013', 'pmid', '23774812', 'Brown', 'Contribution of aldosterone to cardiovascular and renal inflammation and fibrosis'),
    ('Gow2017', 'pmid', '28513415', 'Gow', 'The fungal cell wall: structure, biosynthesis, and function'),
    ('Jeay2002', 'pmid', '11911939', 'Jeay', 'Growth hormone can act as a cytokine controlling survival and proliferation of immune cells'),
    ('Weinberg1995', 'pmid', '7736585', 'Weinberg', 'The retinoblastoma protein and cell cycle control'),
    ('Ji2011', 'pmid', '21592797', 'Ji', 'Formation of mammalian erythrocytes: chromatin condensation and enucleation'),
    ('McGaugh2004', 'pmid', '15217324', 'McGaugh', 'The amygdala modulates the consolidation of memories of emotionally arousing experiences'),
    ('Bakshi2012', 'pmid', '22624875', 'Bakshi', 'Superresolution imaging of ribosomes and RNA polymerase in live Escherichia coli cells'),
    ('Reactome-gluconeogenesis', 'reactome', 'R-HSA-70263', '', 'Gluconeogenesis'),
    ('Reactome-fatty-acyl-CoA', 'reactome', 'R-HSA-75105', '', 'Fatty acyl-CoA biosynthesis'),
]


def url(kind, i):
    if kind == 'doi': return 'https://api.crossref.org/works/' + urllib.parse.quote(i, safe='')
    if kind == 'pmid': return 'https://www.ebi.ac.uk/europepmc/webservices/rest/search?' + urllib.parse.urlencode(
        {'query': f'EXT_ID:{i} AND SRC:MED', 'format': 'json', 'resultType': 'core'})
    if kind == 'datacite': return 'https://api.datacite.org/dois/' + urllib.parse.quote(i, safe='')
    return f'https://reactome.org/ContentService/data/query/{i}'


def fname(dl, kind, i): return os.path.join(dl, f'{kind}_' + re.sub(r'[^A-Za-z0-9._-]', '_', i) + '.json')


def fetch(dl):
    os.makedirs(dl, exist_ok=True)
    for key, kind, i, *_ in REFS:
        p = fname(dl, kind, i)
        if os.path.exists(p): continue
        req = urllib.request.Request(url(kind, i), headers={'User-Agent': 'BioLean-stress/0.1 (read-only reference check)'})
        try:
            with urllib.request.urlopen(req, timeout=40) as r: open(p, 'wb').write(r.read())
            print('ok', key)
        except Exception as e:
            print('FAILED', key, e)
        time.sleep(0.3)


def norm(s): return re.sub(r'[^a-z0-9 ]', '', unicodedata.normalize('NFKD', (s or '').replace('\u2010', '-')).encode('ascii', 'ignore').decode().lower().replace('-', ' '))


def show(dl, out):
    rows = ['key\tsource\tid\tfirst_author\tyear\ttitle\tcheck']
    for key, kind, i, au, ti in REFS:
        p = fname(dl, kind, i)
        try:
            d = json.load(open(p))
            if kind == 'doi':
                m = d['message']; a = (m.get('author') or [{}])[0]
                fa = a.get('family') or a.get('name') or ''
                yr = str(((m.get('issued') or {}).get('date-parts') or [[None]])[0][0])
                title = ': '.join(x for x in [(m.get('title') or [''])[0], (m.get('subtitle') or [''])[0]] if x); src = 'Crossref'
            elif kind == 'pmid':
                r = d['resultList']['result'][0]
                fa = ((r.get('authorList') or {}).get('author') or [{}])[0].get('lastName', '')
                yr = r.get('pubYear', ''); title = r.get('title', ''); src = 'Europe PMC'
            elif kind == 'datacite':
                a = d['data']['attributes']; c = (a.get('creators') or [{}])[0]
                fa = c.get('familyName') or c.get('name', '').split(',')[0]; yr = str(a.get('publicationYear', ''))
                title = (a.get('titles') or [{}])[0].get('title', ''); src = 'DataCite'
            else:
                fa, yr, title, src = '', '', d.get('displayName', ''), 'Reactome'
        except Exception as e:
            rows.append(f'{key}\t{kind}\t{i}\t\t\tUNVERIFIED ({str(e)[:60]})\tCHECK'); continue
        ok = norm(fa) == norm(au) and norm(re.sub(r'<[^>]+>', '', title)).startswith(norm(ti)[:40])
        title = re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', '', title)).strip()
        rows.append(f'{key}\t{src}\t{i}\t{fa}\t{yr}\t{title}\t{"OK" if ok else "CHECK"}')
    open(out, 'w').write('\n'.join(rows) + '\n')
    print('\n'.join(rows))


if __name__ == '__main__':
    if sys.argv[1] == 'fetch': fetch(sys.argv[2])
    else: show(sys.argv[2], sys.argv[3])
