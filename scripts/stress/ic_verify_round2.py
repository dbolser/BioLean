"""Live re-check, 2026-10-30, of every CURIE and reference the round-2 analysis of program 07 cites. Read-only lookups.

Usage (from the repo root): python3 -I scripts/stress/ic_verify_round2.py
Reads the sheet cases (data/stress/07/sheet_cases.tsv, written by ic_analysis.py) and the terms near the cut
(analysis_terms_near_cut.tsv) for CURIEs, plus the fixed list EXTRA below. Looks each up on OLS4 (label, obsolete,
first line of the definition). Re-checks each reference in data/stress/07/references_checked.tsv and
references_analysis.tsv, plus the new ones in NEW_REFS, on Crossref or Europe PMC with ic_refs.check (title words and
first author must match, otherwise UNVERIFIED).

A fresh cache, /tmp/biolean-07/round2/, holds the raw replies, so every answer here is from today's lookups and not
from the earlier cache. Replies are parsed as JSON only. Writes data/stress/07/verify_round2_curies.tsv and
data/stress/07/verify_round2_refs.tsv.
"""
import json, os, re, sys, urllib.error, urllib.parse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ic_ols, ic_refs  # noqa: E402

D = 'data/stress/07'
CACHE = '/tmp/biolean-07/round2'
ic_ols.CACHE = f'{CACHE}/ols'
ic_refs.CACHE = f'{CACHE}/refs'
CURIE = re.compile(r'\b(?:GO|UBERON|CL|CHEBI|NCBITaxon|RO|BFO|PR|MONDO|SO|PATO|HP|PO):[A-Za-z0-9]+\b')
# Terms the doc names that are not in a sheet case's terms column.
EXTRA = ['GO:0006119', 'CHEBI:64909', 'GO:0050801', 'UBERON:0002371', 'GO:0012505', 'UBERON:0002020', 'GO:0005886',
         'UBERON:0001009', 'GO:0009058', 'UBERON:0002091', 'GO:0005856', 'UBERON:0013765', 'UBERON:0001981',
         'GO:0055085', 'UBERON:0001630', 'GO:0005694', 'CL:0000548']
# References new in round 2 (key, how, id or query, first-author family name, title fragment).
NEW_REFS = [
    ('Haase2013', 'epmc', 'EXT_ID:23291219 AND SRC:MED', 'Haase', 'Regulation of erythropoiesis by hypoxia-inducible factors'),
]
# How each earlier reference was looked up (same arguments as ic_refs.py and ic_refs_analysis.py).
HOW = {r[0]: r for r in ic_refs.REFS}
import ic_refs_analysis  # noqa: E402
HOW.update({r[0]: r for r in ic_refs_analysis.REFS})


def read_tsv(p):
    lines = open(p, encoding='utf-8').read().splitlines()
    head = lines[0].split('\t')
    return [dict(zip(head, l.split('\t'))) for l in lines[1:] if l.strip()]


def definition(curie):
    """First definition line from the cached OLS4 reply that ic_ols.lookup fetched."""
    p = f"{ic_ols.CACHE}/{curie.replace(':', '_')}.json"
    if not os.path.exists(p): return ''
    d = json.load(open(p, encoding='utf-8'))
    terms = (d.get('_embedded') or {}).get('terms') or []
    if not terms: return ''
    desc = terms[0].get('description') or ['']
    return (desc[0] or '')[:300]


def lookup(c):
    """ic_ols.lookup with two retries on a timeout; relations whose obo_id query fails are looked up by IRI."""
    for attempt in range(3):
        try: return ic_ols.lookup(c)
        except urllib.error.HTTPError:
            if c.split(':')[0] not in ('RO', 'BFO'): raise
            iri = urllib.parse.quote(urllib.parse.quote('http://purl.obolibrary.org/obo/' + c.replace(':', '_'), safe=''), safe='')
            d = ic_ols.get(f'{ic_ols.API}/ontologies/ro/properties/{iri}', f"{ic_ols.CACHE}/{c.replace(':', '_')}.iri.json")
            return (c, 'ro', d.get('label', ''), str(d.get('is_obsolete', '')), 'yes (looked up by IRI)')
        except (TimeoutError, urllib.error.URLError):
            if attempt == 2: raise


def main():
    os.makedirs(ic_ols.CACHE, exist_ok=True); os.makedirs(ic_refs.CACHE, exist_ok=True)
    cur = set(EXTRA)
    for r in read_tsv(f'{D}/sheet_cases.tsv'): cur |= set(CURIE.findall(r['terms']))
    for r in read_tsv(f'{D}/analysis_terms_near_cut.tsv'): cur.add(r['term'])
    rows = [('curie', 'ontology', 'label', 'obsolete', 'found', 'definition_first_300_chars')]
    for c in sorted(cur):
        try: x = lookup(c)
        except Exception as e: x = (c, '', '', '', f'error {type(e).__name__}', '')
        rows.append(x[:5] + (definition(c),))
    with open(f'{D}/verify_round2_curies.tsv', 'w', encoding='utf-8') as fh:
        for r in rows: fh.write('\t'.join(str(v).replace('\t', ' ').replace('\n', ' ') for v in r) + '\n')
    found = sum(r[4].startswith('yes') for r in rows[1:])
    print(f'CURIEs: {len(rows) - 1} looked up on OLS4; found {found}; obsolete {sum(r[3] == "True" for r in rows[1:])}')
    for r in rows[1:]:
        if not r[4].startswith('yes'): print('  NOT FOUND', r)
    keys = [r['key'] for r in read_tsv(f'{D}/references_checked.tsv') + read_tsv(f'{D}/references_analysis.tsv')]
    out = [('key', 'id', 'year', 'first_author', 'title', 'venue', 'checked')]
    for k in keys + [r[0] for r in NEW_REFS]:
        spec = HOW.get(k) or next((r for r in NEW_REFS if r[0] == k), None)
        if spec is None: out.append((k, '', '', '', '', '', 'UNVERIFIED: no lookup recipe')); continue
        try: out.append(ic_refs.check(*spec))
        except (urllib.error.URLError, OSError, ValueError, KeyError) as e:
            out.append((k, '', '', '', '', '', f'UNVERIFIED: lookup error {type(e).__name__}'))
    with open(f'{D}/verify_round2_refs.tsv', 'w', encoding='utf-8') as fh:
        for r in out: fh.write('\t'.join(str(v).replace('\t', ' ') for v in r) + '\n')
    ok = sum(r[-1] == 'yes' for r in out[1:])
    print(f'references: {len(out) - 1} re-checked live; matched {ok}')
    for r in out[1:]:
        if r[-1] != 'yes': print('  ', r[0], r[-1])


if __name__ == '__main__':
    main()
