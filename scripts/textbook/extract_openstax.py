"""Extract chosen chapters of OpenStax Concepts of Biology (CNXML) to plain-text JSON, one file per chapter.
Usage: extract_openstax.py <bundle_dir> <out_dir>"""
import json, re, sys, pathlib, xml.etree.ElementTree as ET
bundle, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
NS = {'col': 'http://cnx.rice.edu/collxml', 'md': 'http://cnx.rice.edu/mdml', 'c': 'http://cnx.rice.edu/cnxml'}
WANT = ["Cell Structure and Function", "How Cells Obtain Energy", "Photosynthesis",
        "Reproduction at the Cellular Level", "The Cellular Basis of Inheritance", "Molecular Biology",
        "The Body’s Systems"]
SKIP_CLASSES = {'exercise', 'references', 'attribution'}
def text_of(el):
    return re.sub(r'\s+', ' ', ''.join(el.itertext())).strip()
def module_text(mid):
    root = ET.parse(bundle / 'modules' / mid / 'index.cnxml').getroot()
    title = root.findtext('c:title', namespaces=NS) or ''
    paras, glossary = [], []
    content = root.find('c:content', NS)
    for sec in content.iter():
        tag = sec.tag.split('}')[-1]
        if tag == 'para' and not any(a.get('class') in SKIP_CLASSES for a in [sec]):
            # skip paras inside exercises or figures
            paras.append(text_of(sec))
    for d in root.iter('{%s}definition' % NS['c']):
        term = d.findtext('c:term', namespaces=NS) or ''
        meaning = ' '.join(text_of(m) for m in d.findall('c:meaning', NS))
        glossary.append({'term': term, 'meaning': meaning})
    return {'id': mid, 'title': title, 'paragraphs': [p for p in paras if len(p) > 40], 'glossary': glossary}
coll = ET.parse(bundle / 'collections' / 'concepts-biology.collection.xml').getroot()
n = 0
for sc in coll.iter('{%s}subcollection' % NS['col']):
    title = sc.find('md:title', NS).text
    if title not in WANT: continue
    mods = [m.get('document') for m in sc.iter('{%s}module' % NS['col'])]
    ch = {'chapter': title, 'modules': [module_text(m) for m in mods]}
    slug = re.sub(r'[^a-z]+', '-', title.lower()).strip('-')
    (out / f'{slug}.json').write_text(json.dumps(ch, indent=1, ensure_ascii=False))
    words = sum(len(p.split()) for m in ch['modules'] for p in m['paragraphs'])
    gl = sum(len(m['glossary']) for m in ch['modules'])
    print(f'{slug:40s} modules={len(mods)} words={words} glossary={gl}')
