"""Check the extra references used by the rating analysis of program 07 (read-only lookups on Crossref and Europe PMC).

Usage: python3 -I scripts/stress/ic_refs_analysis.py data/stress/07/references_analysis.tsv
Reuses check() from ic_refs.py (same matching rule: the returned title must contain the expected words and the first
author's family name must match; otherwise the row says UNVERIFIED). Raw replies are cached in /tmp/biolean-07/refs/.
"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ic_refs  # noqa: E402

REFS = [
    ('Fleiss1971', 'doi', '10.1037/h0031619', 'Fleiss', 'Measuring nominal scale agreement among many raters'),
    ('Cohen1968', 'doi', '10.1037/h0026256', 'Cohen', 'Weighted kappa'),
    ('HanleyMcNeil1982', 'doi', '10.1148/radiology.143.1.7063747', 'Hanley', 'The meaning and use of the area under a receiver operating characteristic'),
    ('Efron1979', 'doi', '10.1214/aos/1176344552', 'Efron', 'Bootstrap Methods'),
    ('Youden1950', 'cr', 'Youden Index for rating diagnostic tests Cancer 1950', 'Youden', 'Index for rating diagnostic tests'),
    ('Sigel2012', 'epmc', 'TITLE:"Structure, function, and modulation of GABA(A) receptors"', 'Sigel', 'Structure, function, and modulation of GABA'),
    ('Jones2024', 'epmc', 'EXT_ID:39159370 AND SRC:MED', 'Jones', 'Conserved 5-methyluridine tRNA modification modulates ribosome translocation'),
]

if __name__ == '__main__':
    os.makedirs(ic_refs.CACHE, exist_ok=True)
    rows = [('key', 'id', 'year', 'first_author', 'title', 'venue', 'checked')]
    for r in REFS:
        try: rows.append(ic_refs.check(*r))
        except Exception as e: rows.append((r[0], '', '', '', '', '', f'UNVERIFIED: lookup error {type(e).__name__}'))
    with open(sys.argv[1], 'w', encoding='utf-8') as fh:
        for r in rows: fh.write('\t'.join(str(x).replace('\t', ' ') for x in r) + '\n')
    print(f'{len(REFS)} references; checked {sum(1 for r in rows[1:] if r[-1] == "yes")}')
