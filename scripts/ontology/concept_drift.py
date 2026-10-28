"""Concept drift: how much of the textbook's GO vocabulary existed in 2005, 2010, 2015 and 2020, and what happened since.

For every GO CURIE the textbook claims use, in each snapshot: live, obsolete (still listed, retired), alt (an old id
merged into another term) or absent (not minted yet); whether the label matches today's; and today's state
(obsolete? replaced_by? creation_date). Snapshots are the GO release archive's YYYY-01-01 releases (go-basic.obo, or
go.obo / gene_ontology.obo in the early years), saved once as <obo_dir>/go-<year>.obo; "now" is <obo_dir>/go.obo.
Usage: concept_drift.py <claims_m2_dir> <obo_dir> [out.json]
       concept_drift.py --history GO:0045121 2004-03-01,2006-06-01,...    (stream those archive releases, show the term's state)"""
import sys, os, re, json, difflib, collections, urllib.error, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).parent))
import obo
ARCHIVE = 'https://release.geneontology.org'; YEARS = (2005, 2010, 2015, 2020)
REWRITTEN = 0.6   # definitions with a text similarity below this count as rewritten, not touched up
norm = lambda s: re.sub(r'\W+', ' ', s).lower().strip()
NAMES = ('ontology/go-basic.obo', 'ontology/go.obo', 'ontology/gene_ontology.obo')   # the early years have no go-basic

def release_dates():
    return re.findall(r'release\.geneontology\.org/(\d{4}-\d{2}-\d{2})/index\.html', obo.request(ARCHIVE + '/').read().decode())

def open_release(date):
    for name in NAMES:
        try: return obo.request(f'{ARCHIVE}/{date}/{name}'), name
        except urllib.error.HTTPError: pass
    raise SystemExit(f'no OBO file in the {date} release')

def fetch(year, obo_dir):
    path = os.path.join(obo_dir, f'go-{year}.obo')
    if not os.path.exists(path):
        date = min(d for d in release_dates() if d >= f'{year}-01-01')   # nearest release on or after 1 January
        resp, name = open_release(date); open(path, 'wb').write(resp.read()); print(f'fetched {date}/{name} -> {path}')
    return path

def load(path):
    T = {t['id']: t for t in obo.terms(path) if t['id'].startswith('GO:')}
    return T, {a: t['id'] for t in T.values() for a in t['alt_id']}, obo.version(path)

def status(snap, c):
    T, alt, _ = snap
    return ('obsolete' if T[c]['obsolete'] else 'live') if c in T else 'alt' if c in alt else 'absent'

def history(tid, dates):
    prev = None
    for d in dates:
        resp, name = open_release(d); stanza = []
        for line in resp:
            line = line.decode('utf-8', 'replace').rstrip('\n')
            if stanza and not line: break
            if line == f'id: {tid}' or stanza: stanza.append(line)
        parents = ' '.join(re.split(r'[{!]', l, 1)[0].strip() for l in stanza if l.startswith(('is_a:', 'relationship: part_of')))
        state = (next((l[6:] for l in stanza if l.startswith('name: ')), 'ABSENT'), parents, next((l[5:85] for l in stanza if l.startswith('def: ')), ''))
        print(f'{d}  {"(same)" if state == prev else "CHANGE"}  {state[0]!r}  {state[1]}  def: {state[2]}'); prev = state

if sys.argv[1] == '--history': history(sys.argv[2], sys.argv[3].split(',')); sys.exit()
claims_dir, obo_dir = sys.argv[1], sys.argv[2]; out = sys.argv[3] if len(sys.argv) > 3 else 'data/ontology/concept_drift.json'
recs = list(obo.claims(claims_dir))
used = collections.Counter(c for r in recs for c in obo.mentioned_curies(r) if c.startswith('GO:'))
stmt_use = collections.Counter(c for r in recs if (r.get('m2') or {}).get('ctor') not in (None, 'none') for c in obo.statement_curies(r) if c.startswith('GO:'))
snaps = {y: load(fetch(y, obo_dir)) for y in YEARS}; snaps['now'] = load(os.path.join(obo_dir, 'go.obo'))
now_T, now_alt, _ = snaps['now']

terms = {}
for c in sorted(used):
    rec = {'claims': used[c], 'statements': stmt_use[c], 'by_snapshot': {}}
    for y, snap in snaps.items():
        s = status(snap, c); e = {'status': s}
        if s in ('live', 'obsolete'): e['name'] = snap[0][c]['name']
        if s == 'alt': e['merged_into'] = snap[1][c]
        rec['by_snapshot'][y] = e
    t = now_T.get(c) or now_T.get(now_alt.get(c))   # an id that is now only an alt_id resolves to its primary
    rec['now'] = dict(name=t['name'], namespace=t['namespace'], obsolete=t['obsolete'], replaced_by=t['replaced_by'], consider=t['consider'], creation_date=t['creation_date'], primary=t['id'] if t['id'] != c else None)
    same = [y for y in YEARS if rec['by_snapshot'][y]['status'] == 'live' and rec['by_snapshot'][y]['name'] == rec['now']['name'] and not rec['now']['obsolete']]   # same name as today
    sim = {y: difflib.SequenceMatcher(None, norm(snaps[y][0][c]['definition']), norm(t['definition'])).ratio() for y in same}
    rec['redefined_since'] = [y for y in same if snaps[y][0][c]['definition'] != t['definition']]   # same name, different definition text
    rec['rewritten_since'] = [y for y in same if sim[y] < REWRITTEN]                                   # ... and little text in common
    rec['renamed_since'] = [y for y in YEARS if rec['by_snapshot'][y]['status'] == 'live' and rec['by_snapshot'][y]['name'] != rec['now']['name']]
    terms[c] = rec

# --- summary
n = len(terms); cols = list(snaps)
count = {y: collections.Counter(t['by_snapshot'][y]['status'] for t in terms.values()) for y in cols}
statements = [r for r in recs if (r.get('m2') or {}).get('ctor') not in (None, 'none') and any(c.startswith('GO:') for c in obo.statement_curies(r))]
writable = {y: sum(1 for r in statements if all(terms[c]['by_snapshot'][y]['status'] == 'live' for c in obo.statement_curies(r) if c.startswith('GO:'))) for y in cols}
labels = {y: sum(1 for t in terms.values() if t['by_snapshot'][y]['status'] == 'live' and t['by_snapshot'][y]['name'] == t['now']['name']) for y in cols}
first = lambda t: next((y for y in cols if t['by_snapshot'][y]['status'] != 'absent'), None)
# creation_date is only a mint date if no snapshot from before that year already had the term; for older terms it is back-filled
dated = sorted(((t['now']['creation_date'], c) for c, t in terms.items() if t['now']['creation_date']), reverse=True)
backfilled = [c for d, c in dated if first(terms[c]) not in (None, 'now') and int(first(terms[c])) < int(d[:4])]
obsolete_now = [c for c, t in terms.items() if t['now']['obsolete']]
merged_now = [c for c, t in terms.items() if t['by_snapshot']['now']['status'] == 'alt']
summary = dict(go_curies=n, releases={str(y): snaps[y][2] for y in cols}, live={str(y): count[y]['live'] for y in cols}, obsolete={str(y): count[y]['obsolete'] for y in cols},
               alt={str(y): count[y]['alt'] for y in cols}, absent={str(y): count[y]['absent'] for y in cols}, same_label_as_now={str(y): labels[y] for y in cols},
               statements_with_go=len(statements), statements_fully_expressible={str(y): writable[y] for y in cols}, with_creation_date=len(dated), creation_date_backfilled=len(backfilled),
               renamed_since_2005=sum(1 for t in terms.values() if t['renamed_since'] and t['renamed_since'][0] == 2005), obsolete_now=obsolete_now, merged_now=merged_now)
# the whole of GO, not just the textbook: the textbook was linked against today's GO, so it under-counts terms retired long ago
whole = {}
for y in YEARS:
    live = [c for c, t in snaps[y][0].items() if not t['obsolete']]; st = collections.Counter(status(snaps['now'], c) for c in live)
    whole[y] = dict(live=len(live), obsolete_now=st['obsolete'], merged_now=st['alt'], gone_now=st['absent'], renamed_now=sum(1 for c in live if c in now_T and not now_T[c]['obsolete'] and now_T[c]['name'] != snaps[y][0][c]['name']))
summary['same_name_definition_text_changed'] = {str(y): sum(1 for t in terms.values() if y in t['redefined_since']) for y in YEARS}
summary['same_name_definition_rewritten'] = {str(y): sum(1 for t in terms.values() if y in t['rewritten_since']) for y in YEARS}
summary['whole_go'] = {str(y): w for y, w in whole.items()}
json.dump({'summary': summary, 'terms': terms}, open(out, 'w'), indent=0)

pct = lambda a, b: f'{100 * a / b:.0f}%'
print(f'{n} GO CURIEs in the textbook claims; {len(statements)} statements use one or more')
print('releases:', {str(y): snaps[y][2] for y in cols})
print(f'\n{"snapshot":<10}' + ''.join(f'{str(y):>9}' for y in cols))
for lab, k in (('live', 'live'), ('obsolete', 'obsolete'), ('alt id', 'alt'), ('absent', 'absent')): print(f'{lab:<10}' + ''.join(f'{count[y][k]:>9}' for y in cols))
print(f'{"live %":<10}' + ''.join(f'{pct(count[y]["live"], n):>9}' for y in cols))
print(f'{"same name":<10}' + ''.join(f'{labels[y]:>9}' for y in cols))
print(f'{"stmts ok":<10}' + ''.join(f'{writable[y]:>9}' for y in cols) + f'   (of {len(statements)}: every GO term live in that snapshot)')
print('\nwhole GO, terms live in the snapshot and what they are today:'); print(f'{"":<10}' + ''.join(f'{str(y):>9}' for y in YEARS))
for lab, k in (('live', 'live'), ('obsolete', 'obsolete_now'), ('merged', 'merged_now'), ('renamed', 'renamed_now')): print(f'{lab:<10}' + ''.join(f'{whole[y][k]:>9}' for y in YEARS))
print(f'{"retired %":<10}' + ''.join(f'{pct(whole[y]["obsolete_now"] + whole[y]["merged_now"], whole[y]["live"]):>9}' for y in YEARS) + f'{"renamed %":>12}' + ''.join(f' {pct(whole[y]["renamed_now"], whole[y]["live"]):>5}' for y in YEARS))
print('same name as now but different definition text (of those, rewritten: text similarity < %s): ' % REWRITTEN + ', '.join(f'{y}: {summary["same_name_definition_text_changed"][str(y)]} ({summary["same_name_definition_rewritten"][str(y)]}) of {labels[y]}' for y in YEARS))
print(f'\nrenamed since 2005 (live in 2005 with another name than now): {summary["renamed_since_2005"]}')
print(f'\nnewest ten by creation_date ({len(dated)} of {n} have one; {len(backfilled)} of those are back-filled: a snapshot older than the date already has the term):')
for d, c in [x for x in dated if x[1] not in backfilled][:10]: print(f'  {d[:10]}  {c}  {terms[c]["now"]["name"]}  (first seen {first(terms[c])}, {terms[c]["statements"]} statements)')
print(f'\nmost used terms that did not exist in the 2005 snapshot ({count[2005]["absent"]} in all):')
for c in sorted((c for c, t in terms.items() if t['by_snapshot'][2005]['status'] == 'absent'), key=lambda c: -terms[c]['statements'])[:10]: print(f'  {c}  {terms[c]["now"]["name"]}  (first seen {first(terms[c])}, {terms[c]["statements"]} statements)')
print(f'\nrenamed since 2005, most used first ({summary["renamed_since_2005"]} in all):')
ren = sorted((c for c, t in terms.items() if t['renamed_since'] and t['renamed_since'][0] == 2005), key=lambda c: -terms[c]['statements'])
for c in ren[:12]: print(f'  {c}  {terms[c]["by_snapshot"][2005]["name"]!r} -> {terms[c]["now"]["name"]!r}  ({terms[c]["statements"]} statements)')
print(f'\nmerged into another term (now an alt_id): {[(c, terms[c]["by_snapshot"][2020].get("name"), "->", terms[c]["now"]["primary"], terms[c]["now"]["name"]) for c in merged_now]}')
print(f'\nobsolete now ({len(obsolete_now)}):')
for c in obsolete_now:
    t = terms[c]; rep = ', '.join(f'{r} {now_T[r]["name"]}' for r in t['now']['replaced_by'] if r in now_T) or 'none'
    print(f'  {c}  {t["now"]["name"]}  | replaced_by: {rep} | consider: {", ".join(t["now"]["consider"]) or "none"} | live in: {[str(y) for y in cols if t["by_snapshot"][y]["status"] == "live"]} | {t["statements"]} statements')
print(f'\nfirst snapshot in which each term is known: {dict(collections.Counter(str(first(t)) for t in terms.values()))}')
