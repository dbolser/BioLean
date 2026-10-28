"""Minimal OBO reader, and the textbook-claims CURIE collector, shared by ic.py and concept_drift.py.
`terms(path)` yields one dict per [Term] stanza.
Keeps only what we use: id, name, namespace, def (text only), is_a, part_of, alt_id, synonyms, obsolete, replaced_by,
consider, creation_date. Repeated tags become lists. Standard library only."""
import re, json, glob, urllib.request

LISTED = {'is_a', 'alt_id', 'replaced_by', 'consider', 'synonym', 'relationship'}
KEPT = LISTED | {'id', 'name', 'namespace', 'def', 'is_obsolete', 'creation_date'}
TAG = re.compile(r'^([a-z_]+): (.*)$')


def terms(path):
    cur = None
    for line in open(path, encoding='utf-8', errors='replace'):
        if line.startswith('['):
            if cur and 'id' in cur: yield _finish(cur)
            cur = {} if line.startswith('[Term]') else None
            continue
        if cur is None: continue
        m = TAG.match(line.rstrip('\n'))
        if not m or m.group(1) not in KEPT: continue
        tag, val = m.groups()
        if tag in LISTED: cur.setdefault(tag, []).append(val)
        else: cur[tag] = val
    if cur and 'id' in cur: yield _finish(cur)


def _finish(t):
    first = lambda s: re.split(r'[\s{!]', s, 1)[0]
    rel = [r.split() for r in t.get('relationship', [])]
    return dict(
        id=t['id'], name=t.get('name'), namespace=t.get('namespace'), definition=re.sub(r'\s*\[[^\]]*\]\s*$', '', t.get('def', '')).replace('\\', '').strip('"'),
        is_a=[first(x) for x in t.get('is_a', [])],
        part_of=[r[1] for r in rel if len(r) > 1 and r[0] in ('part_of', 'BFO:0000050')],
        alt_id=[first(x) for x in t.get('alt_id', [])],
        synonyms=[tuple(re.match(r'"(.*)" (\w+)', s).groups()) for s in t.get('synonym', []) if re.match(r'"(.*)" (\w+)', s)],
        obsolete=t.get('is_obsolete') == 'true',
        replaced_by=[first(x) for x in t.get('replaced_by', [])],
        consider=[first(x) for x in t.get('consider', [])],
        creation_date=t.get('creation_date'))


def version(path):
    """The `data-version:` (else `date:`) header line of an OBO file, as a string."""
    head = {}
    for line in open(path, encoding='utf-8', errors='replace'):
        if line.startswith('['): break
        k, _, v = line.partition(': ')
        head.setdefault(k, v.strip())
    return head.get('data-version') or head.get('date') or '?'


def claims(claims_dir):
    for p in sorted(glob.glob(f'{claims_dir}/*.json')): yield from json.load(open(p))


def statement_curies(r):
    """CURIEs of the statement a claim became: m2 subject, object and mediator."""
    m = r.get('m2') or {}
    return {m[k] for k in ('subject', 'object', 'mediator') if m.get(k)}


def mentioned_curies(r):
    """Everything a claim uses: its statement CURIEs, every linked entity, and the targets of CURIE corrections."""
    m = r.get('m2') or {}
    return statement_curies(r) | {e['curie'] for e in r.get('entities') or [] if e.get('curie')} | {c['to'] for c in m.get('curie_changes') or [] if c.get('to')}


def request(url):
    """urlopen with a User-Agent: the GO archive and purl.obolibrary.org answer 403 to urllib's default agent."""
    return urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'biolean'}), timeout=600)
