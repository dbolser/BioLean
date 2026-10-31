"""Program 07 analysis: do ratings support the IC triviality cut at 2.5? Run from the repo root:

    python3 scripts/stress/ic_analysis.py                        # LLM raters, plus Dan's file if it exists
    python3 scripts/stress/ic_analysis.py --dan FILE --out DIR   # test with another rater file; write outputs to DIR
    python3 scripts/stress/ic_analysis.py --print-pins           # print the observed pins (to update them on purpose)

Inputs (all in data/stress/07/, read only):
- rating_sheet.tsv (fact, terms, IC), rating_sheet_key.tsv (closure key, path_min, flags, stratum, old LLM label),
  features.tsv (gain, ontology features; from ic_alternatives.py), sample_strata.tsv (pool sizes),
  sheet_draw_exclusions.tsv (the first-draft rubric examples, used to find the rows they primed).
- Raters: rating_llm_1.tsv, rating_llm_2.tsv, rating_llm_3.tsv (three fresh blind LLM raters, round 3, 2026-10-31,
  made with the current rubric.md: a STAND-IN for Dan), and Dan's file rating_dan.tsv (or rating_dan.csv) when it
  exists. Dan's file can be the blind sheet itself with 'interesting' and 'true' filled; other columns are ignored,
  empty rows are skipped, tab or comma separated both work, y / n / ? are read as yes / no / unsure.
- round2/rating_llm_1..3.tsv: the round-2 LLM ratings (2026-10-30, the same current rubric.md; copied byte for byte
  from git commit 6441d2f, unchanged at c1984b8, before round 3 overwrote the live files). round2/ also keeps that
  run's outputs.
- round1_primed/analysis_rows.tsv: the round-1 LLM ratings (made with the first-draft rubric, rubric_draft1.md, whose
  examples primed some rows). Rounds 1 and 2 are used only for the round comparison (section 2). Optional.

Outputs (data/stress/07/, or --out DIR; all rewritten on every run; deterministic):
- analysis_report.txt            the report as printed
- analysis_summary.tsv           the headline numbers the doc quotes
- analysis_rows.tsv              one row per sheet fact: IC, verdict at 2.5, features, every rating, pooled mean and truth
- analysis_agreement.tsv         Fleiss' kappa on 'interesting' (4 levels; 0 against 1+; under 2 against 2+); Fleiss'
                                 kappa and percent agreement on 'true'; pairwise weighted kappa; old 42 labels against new
- analysis_rounds.tsv            rounds 1 (primed), 2 and 3 (current rubric), per row, with the six-rating pool of
                                 rounds 2 and 3
- analysis_threshold_curve.tsv   T = 0, 0.25, ... up to the largest IC: precision (share of kept facts rated
                                 interesting) and recall (share of interesting facts kept), by rater and pooled
- analysis_alternatives.tsv      AUC of each score (options A to G) with a bootstrap 90 percent interval
- analysis_rules.tsv             whole filters: kept, precision, recall, trivial kept, interesting lost, false kept
- analysis_exit_tests.tsv        the exit tests of the doc's experiments that can be computed from ratings
- analysis_terms_near_cut.tsv    closure facts scored 2 to 3, grouped by the term that sets the score
- sheet_cases.tsv                the stress cases on the sheet (near the cut, rated untrue, no IC), with marks

Definitions. 'interesting': a rating of 2 or 3; for a pool, a mean of 2 or more. 'trivial': a rating of 0; for a pool,
a mean under 0.5. 'judged false': for a pool, a strict majority says 'no'. 'worth showing': interesting and not judged
false. Marks for sheet cases follow scripts/stress/ic_cases.py: a trivial fact should be dropped; a worth-showing fact
kept; a fact judged false should be flagged, which a cut cannot do, so false and kept is FAIL and false and dropped is
SILENT; a fact with no IC is SILENT; a middle fact (mean 0.5 to 2) may go either way (PASS, counted apart as 'either').
The truth a mark uses is the checked source (SOURCE_TRUTH, 20 rows) where there is one, else the LLM pool.

Thresholds. The rules (scorer rule, highest safe T, best F1) are computed twice: on the 0.25 grid (the tables) and on
exact cut points, the sheet's own IC values (review fix: the grid has no point between 2.282, plasma membrane, and
2.433, endomembrane system, so on the grid a rule can only say 2.25 or 2.5). Read the exact ones for where T belongs.
The scorer rule breaks ties by taking the lowest T, so it names one interval. 'Plateau' (added 2026-10-31) is every
exact cut point that ties with it: the whole range of equally good cuts. Read the plateau, not the single interval.

Pins. The marks and headline numbers from the three LLM raters are pinned below. Dan's ratings never break a pin:
they get their own column (mark_dan) and their own lines. A change to the closure, the IC table, the cut or the LLM
rating files flips a pin and the script exits non-zero, naming what moved. Pure Python 3, no dependencies.
"""
import collections, csv, io, json, math, os, random, statistics, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ic_common import base, bound, ends, ic_of, key_of, load_closure, load_ic, path_min, score, templates  # noqa: E402

D = 'data/stress/07'
IC_MIN = 2.5
STEP = 0.25
LLM = [('llm1', f'{D}/rating_llm_1.tsv'), ('llm2', f'{D}/rating_llm_2.tsv'), ('llm3', f'{D}/rating_llm_3.tsv')]
DAN = [f'{D}/rating_dan.tsv', f'{D}/rating_dan.csv']
ROUND1 = f'{D}/round1_primed/analysis_rows.tsv'
ROUND2 = [('llm1', f'{D}/round2/rating_llm_1.tsv'), ('llm2', f'{D}/round2/rating_llm_2.tsv'),
          ('llm3', f'{D}/round2/rating_llm_3.tsv')]
TRUE = {'yes': 'yes', 'y': 'yes', 'true': 'yes', 'no': 'no', 'n': 'no', 'false': 'no',
        'unsure': 'unsure', '?': 'unsure', 'u': 'unsure', 'maybe': 'unsure'}
NBOOT = 2000
# Rows a first-draft example primed without sharing a term: the example 'capillaries promotes aerobic respiration'
# (level 2) and rows R031, R089 ('blood vessel promotes' the electron transport chain, oxidative phosphorylation).
# Capillaries are blood vessels; both processes are parts of aerobic respiration.
PRIMED_BY_HAND = {'R031': 'capillaries promotes aerobic respiration', 'R089': 'capillaries promotes aerobic respiration'}


# ---------------------------------------------------------------- reading
def read_tsv(p):
    lines = open(p, encoding='utf-8').read().splitlines()
    head = lines[0].split('\t')
    return [dict(zip(head, l.split('\t'))) for l in lines[1:] if l.strip()]


def read_ratings(p, ids, bad):
    """A rater's file: needs columns id, interesting, true (any case). Tab or comma separated, quoted or not."""
    text = open(p, encoding='utf-8-sig').read()
    first = text.splitlines()[0] if text else ''
    delim = '\t' if '\t' in first else ','
    rd = csv.DictReader(io.StringIO(text), delimiter=delim)
    rd.fieldnames = [f.strip().lower() for f in rd.fieldnames or []]
    for need in ('id', 'interesting', 'true'):
        if need not in rd.fieldnames: bad.append(f'{os.path.basename(p)}: no column {need!r}')
    out = {}
    for r in rd:
        i = (r.get('id') or '').strip()
        lvl = (r.get('interesting') or '').strip()
        t = (r.get('true') or '').strip().lower()
        if lvl.endswith('.0'): lvl = lvl[:-2]   # a spreadsheet may save 2 as 2.0
        if not i or (lvl == '' and t == ''): continue
        if i not in ids: bad.append(f'{os.path.basename(p)} {i}: id not on the sheet'); continue
        if lvl not in ('0', '1', '2', '3'): bad.append(f'{os.path.basename(p)} {i}: interesting {lvl!r} (row left out)'); continue
        if t not in TRUE: bad.append(f'{os.path.basename(p)} {i}: true {t!r} (read as unsure)'); t = 'unsure'
        out[i] = (int(lvl), TRUE[t])
    return out


def num(v):
    return float(v) if v not in (None, '', 'None') else None


def load():
    key = read_tsv(f'{D}/rating_sheet_key.tsv')
    sheet = {r['id']: r for r in read_tsv(f'{D}/rating_sheet.tsv')}
    feats = {r['fact']: r for r in read_tsv(f'{D}/features.tsv')}
    pools = {r['stratum'].split(' (')[0]: int(r['pool']) for r in read_tsv(f'{D}/sample_strata.tsv')}
    rows = []
    for k in key:
        fx = feats.get(k['formal_fact'], {})
        rows.append(dict(
            id=k['id'], fact=sheet[k['id']]['fact'], terms=sheet[k['id']]['terms'], formal=k['formal_fact'],
            k=key_of({'key': json.loads(k['closure_key'])}),
            ic=num(k['ic']), pm=num(k['path_min']), stratum=k['stratum'], rule=k['rule'], depth=int(k['depth']),
            n_premises=int(k['n_premises']), verdict={'yes': 'kept', 'no': 'dropped'}.get(k['kept_at_2.5'], k['kept_at_2.5']),
            restates=k['restates_refinement'] == 'True', weak=k['weakening'] == 'True', n_chapters=int(k['n_chapters'] or 0),
            entailed=fx.get('entailed') == 'True', gain=num(fx.get('gain')),
            norm_ic=num(fx.get('norm_ic')), mica_ic=num(fx.get('mica_ic')), onto_dist=num(fx.get('onto_dist')),
            old=k['old_llm_label'], flags=k['flags']))
    n_in = collections.Counter(r['stratum'] for r in rows)
    for r in rows:
        r['w'] = pools[r['stratum']] / n_in[r['stratum']]
        r['flag'] = r['restates'] or r['weak'] or r['entailed']
    return rows


def read_round1(ids):
    """Round-1 LLM ratings, kept in round1_primed/analysis_rows.tsv by the earlier run."""
    if not os.path.exists(ROUND1): return {}
    rr = read_tsv(ROUND1); out = {}
    for n, _ in LLM:
        out[n] = {r['id']: (int(r[f'{n}_interesting']), r[f'{n}_true']) for r in rr
                  if r['id'] in ids and r.get(f'{n}_interesting', '') != ''}
    return out


def read_round2(ids, bad):
    """Round-2 LLM ratings (same rubric as round 3), kept in round2/ (copied from git 6441d2f)."""
    if not all(os.path.exists(p) for _, p in ROUND2): return {}
    return {n: read_ratings(p, ids, bad) for n, p in ROUND2}


# ---------------------------------------------------------------- statistics
def auc(pos, neg):
    """Mann-Whitney AUC with average ranks for ties: P(score of a positive > score of a negative), ties count half."""
    if not pos or not neg: return None
    allv = sorted([(v, 1) for v in pos] + [(v, 0) for v in neg])
    ranks, i = [0.0] * len(allv), 0
    while i < len(allv):
        j = i
        while j + 1 < len(allv) and allv[j + 1][0] == allv[i][0]: j += 1
        for k in range(i, j + 1): ranks[k] = (i + j) / 2 + 1
        i = j + 1
    rp = sum(r for r, (_, lab) in zip(ranks, allv) if lab)
    return (rp - len(pos) * (len(pos) + 1) / 2) / (len(pos) * len(neg))


def fleiss(table):
    """table: per-item category counts, the same number of raters per item (Fleiss 1971)."""
    if not table: return None
    n = sum(table[0]); N = len(table)
    if n < 2: return None
    p_i = [(sum(c * c for c in row) - n) / (n * (n - 1)) for row in table]
    pbar = sum(p_i) / N
    pj = [sum(row[j] for row in table) / (N * n) for j in range(len(table[0]))]
    pe = sum(p * p for p in pj)
    return None if pe == 1 else (pbar - pe) / (1 - pe)


def weighted_kappa(a, b, k=4):
    """Cohen's kappa with quadratic weights, for the ordinal 0 to 3 scale (Cohen 1968)."""
    n = len(a)
    if not n: return None
    O = [[0] * k for _ in range(k)]
    for x, y in zip(a, b): O[x][y] += 1
    ra = [sum(O[i]) for i in range(k)]; cb = [sum(O[i][j] for i in range(k)) for j in range(k)]
    w = lambda i, j: (i - j) ** 2 / (k - 1) ** 2
    obs = sum(w(i, j) * O[i][j] for i in range(k) for j in range(k))
    exp = sum(w(i, j) * ra[i] * cb[j] / n for i in range(k) for j in range(k))
    return None if exp == 0 else 1 - obs / exp


def cohen(a, b):
    n = len(a)
    if not n: return None
    po = sum(x == y for x, y in zip(a, b)) / n
    ca, cb = collections.Counter(a), collections.Counter(b)
    pe = sum(ca[c] * cb[c] for c in set(ca) | set(cb)) / (n * n)
    return None if pe == 1 else (po - pe) / (1 - pe)


def band(k):
    """Landis and Koch 1977 bands."""
    if k is None: return 'n/a'
    for lim, name in ((0, 'poor'), (0.2, 'slight'), (0.4, 'fair'), (0.6, 'moderate'), (0.8, 'substantial')):
        if k < lim: return name
    return 'almost perfect'


def pct(a, b): return None if not b else a / b
def f3(x): return '' if x is None else f'{x:.3f}'
def f2(x): return 'n/a' if x is None else f'{x:.2f}'
def pcts(x): return 'n/a' if x is None else f'{100 * x:.0f}%'


# ---------------------------------------------------------------- pooling and labels
def pool(rows, ratings, names):
    """Mean 'interesting' over the named raters who rated the row; truth by strict majority, else unsure."""
    out = {}
    for r in rows:
        got = [ratings[n][r['id']] for n in names if r['id'] in ratings.get(n, {})]
        if not got: continue
        m = sum(l for l, _ in got) / len(got)
        c = collections.Counter(t for _, t in got)
        truth = 'no' if c['no'] * 2 > len(got) else 'yes' if c['yes'] * 2 > len(got) else 'unsure'
        out[r['id']] = (m, truth)
    return out


def labels(rows, view):
    """view: {id: (level or mean, truth)}. Rated rows only, with lvl and truth attached."""
    return [dict(r, lvl=view[r['id']][0], truth=view[r['id']][1]) for r in rows if r['id'] in view]


def ids_sorted(rows): return [r['id'] for r in rows]


def is_int(x): return x >= 2
def is_triv(x): return x < 0.5
def is_worth(r): return r['lvl'] >= 2 and r['truth'] != 'no'


def curve_point(sc, T, key='ic'):
    kept = [r for r in sc if r[key] >= T]; rem = [r for r in sc if r[key] < T]
    pos = [r for r in sc if is_int(r['lvl'])]; wor = [r for r in sc if is_worth(r)]
    tp = sum(is_int(r['lvl']) for r in kept); tw = sum(is_worth(r) for r in kept)
    p, rc = pct(tp, len(kept)), pct(tp, len(pos))
    f1 = None if not p or not rc else 2 * p * rc / (p + rc)
    wk = sum(r['w'] for r in kept); wtp = sum(r['w'] for r in kept if is_int(r['lvl'])); wpos = sum(r['w'] for r in pos)
    return dict(T=T, n=len(sc), kept=len(kept), pos=len(pos), tp=tp, precision=p, recall=rc, f1=f1,
                worth=len(wor), worth_kept=tw, precision_worth=pct(tw, len(kept)), recall_worth=pct(tw, len(wor)),
                trivial_kept=sum(is_triv(r['lvl']) for r in kept), trivial_removed=sum(is_triv(r['lvl']) for r in rem),
                worth_lost=sum(is_worth(r) for r in rem), false_kept=sum(r['truth'] == 'no' for r in kept),
                precision_w=pct(wtp, wk), recall_w=pct(wtp, wpos),
                trivial_share_w=pct(sum(r['w'] for r in kept if is_triv(r['lvl'])), wk),
                youden=None if not pos or len(sc) == len(pos) else
                rc - sum(not is_int(r['lvl']) for r in kept) / (len(sc) - len(pos)))


def thresholds(maxic):
    ts, t = [], 0.0
    while t <= maxic + 1e-9: ts.append(round(t, 2)); t += STEP
    return ts


def best_f1(sc, ts):
    pts = [p for p in (curve_point(sc, T) for T in ts) if p['f1'] is not None]
    if not pts: return None, None
    b = max(p['f1'] for p in pts)
    return [p['T'] for p in pts if abs(p['f1'] - b) < 1e-12], b


def scorer_rule(sc, ts):
    """The T that removes most trivial rows while losing at most one worth-showing row (lowest such T on ties)."""
    best = None
    for T in ts:
        p = curve_point(sc, T)
        if p['worth_lost'] <= 1 and (best is None or p['trivial_removed'] > best[1]): best = (T, p['trivial_removed'])
    return best


def safe_T(sc, ts):
    """The highest T that loses no worth-showing row."""
    ok = [T for T in ts if curve_point(sc, T)['worth_lost'] == 0]
    return max(ok) if ok else None


# Exact cut points (added in review, 2026-10-30). The 0.25 grid has no point between 2.282 (plasma membrane) and
# 2.433 (endomembrane system), so on the grid the rules can only say 2.25 or 2.5. Every T between two neighbouring sheet
# IC values gives the same split, so the exact candidates are the sheet's own IC values ('keep IC >= T'). A result T
# stands for the interval (the next lower sheet IC, T].
def cut_points(rows):
    return sorted({0.0} | {r['ic'] for r in rows if r['ic'] is not None})


def interval(T, cps):
    lo = max([c for c in cps if c < T], default=None)
    return f'({lo:.3f}, {T:.3f}]' if lo is not None else f'[0, {T:.3f}]'


def plateau(sc, cps):
    """Every exact cut point that ties with the scorer rule's best (most trivial rows removed, at most one worth-showing
    row lost), as a list of runs of neighbouring cut points. Added 2026-10-31: the scorer rule takes the lowest T on
    ties, so on its own it hides a range of equally good cuts."""
    pts = {T: curve_point(sc, T) for T in cps}
    ok = [T for T in cps if pts[T]['worth_lost'] <= 1]
    if not ok: return []
    best = max(pts[T]['trivial_removed'] for T in ok)
    hit = {T for T in ok if pts[T]['trivial_removed'] == best}
    runs, cur = [], []
    for T in cps:
        if T in hit: cur.append(T)
        elif cur: runs.append(cur); cur = []
    if cur: runs.append(cur)
    return runs


def plateau_str(runs, cps):
    out = []
    for run in runs:
        lo = max([c for c in cps if c < run[0]], default=None)
        out.append((f'({lo:.3f}, ' if lo is not None else '[0, ') + f'{run[-1]:.3f}]')
    return ' or '.join(out) if out else 'none'


def split_of(T, cps):
    """The exact cut point that gives the same split as 'keep IC >= T' on the sheet."""
    return min([c for c in cps if c >= T - 1e-12], default=None)


def in_plateau(T, runs, cps):
    s = split_of(T, cps)
    return any(s in run for run in runs)


FEATS = [('ic', 'A', 'ends-min IC (the current score)', lambda r: r['ic']),
         ('pm', 'B', 'path_min: lowest IC anywhere in the proof', lambda r: r['pm']),
         ('gain', 'C1', 'gain: IC(conclusion) minus max IC(premise)', lambda r: r['gain']),
         ('no_flag', 'C2', 'no structural flag (1) or a flag (0)', lambda r: 0.0 if r['flag'] else 1.0),
         ('not_restates', 'C2', 'not a restatement through a refinement', lambda r: 0.0 if r['restates'] else 1.0),
         ('not_weak', 'C2', 'not a weakening of a premise', lambda r: 0.0 if r['weak'] else 1.0),
         ('not_entailed', 'C2', 'not already entailed by the ontology', lambda r: 0.0 if r['entailed'] else 1.0),
         ('n_chapters', 'D', 'premises from how many chapters (cross-topic proxy)', lambda r: float(r['n_chapters'])),
         ('depth', 'E', 'path length: derivation depth', lambda r: float(r['depth'])),
         ('n_premises', 'E', 'path length: number of premises', lambda r: float(r['n_premises'])),
         ('onto_dist', 'F', 'ontology path length between the two ends', lambda r: r['onto_dist']),
         ('mica_ic', 'F', 'Resnik similarity of the two ends', lambda r: r['mica_ic']),
         ('norm_ic', 'G', 'IC divided by ln(ontology size)', lambda r: r['norm_ic'])]


def feat_auc(lab, f, target):
    lab = [r for r in lab if f(r) is not None]
    if target == 'interesting': split = lambda r: is_int(r['lvl'])
    elif target == 'not trivial': split = lambda r: not is_triv(r['lvl'])
    else:
        lab = [r for r in lab if r['truth'] in ('yes', 'no')]; split = lambda r: r['truth'] == 'yes'
    return auc([f(r) for r in lab if split(r)], [f(r) for r in lab if not split(r)]), len(lab)


def boot_auc(lab, f, seed, target='interesting'):
    lab = [r for r in lab if f(r) is not None]
    rng = random.Random(seed); bs = []
    for _ in range(NBOOT):
        s = [lab[rng.randrange(len(lab))] for _ in lab]
        x, _ = feat_auc(s, f, target)
        if x is not None: bs.append(x)
    bs.sort()
    return (bs[int(0.05 * len(bs))], bs[int(0.95 * len(bs)) - 1]) if bs else (None, None)


def key_metrics(rows, view, ts):
    """The numbers compared across rounds and raters."""
    lab = labels(rows, view); sc = [r for r in lab if r['ic'] is not None]
    if len(sc) < 20 or not any(is_int(r['lvl']) for r in sc): return None
    sr = scorer_rule(sc, ts); bt, bf = best_f1(sc, ts)
    cps = cut_points(rows); sx = scorer_rule(sc, cps); bx, _ = best_f1(sc, cps)
    m = dict(n=len(lab), interesting=sum(is_int(r['lvl']) for r in lab), worth=sum(is_worth(r) for r in lab),
             judged_false=sum(r['truth'] == 'no' for r in lab), trivial=sum(is_triv(r['lvl']) for r in lab),
             interesting_and_true=sum(is_int(r['lvl']) and r['truth'] == 'yes' for r in lab),
             scorer_T=sr[0], safe_T=safe_T(sc, ts), best_f1_T=min(bt) if bt else None,
             scorer_T_exact=sx[0], scorer_removed_exact=sx[1], safe_T_exact=safe_T(sc, cps),
             best_f1_T_exact=min(bx) if bx else None,
             f1_25=curve_point(sc, IC_MIN)['f1'], false_kept=sum(r['truth'] == 'no' and r['verdict'] == 'kept' for r in lab))
    runs = plateau(sc, cps)
    m['plateau'] = plateau_str(runs, cps); m['plateau_has_2.5'] = in_plateau(IC_MIN, runs, cps)
    m['plateau_has_2.4'] = in_plateau(2.4, runs, cps)
    m['worth_ids'] = ','.join(sorted(r['id'] for r in lab if is_worth(r)))
    for code, _, _, f in FEATS:
        m[f'auc_{code}'] = feat_auc(lab, f, 'interesting')[0]
        m[f'auc_nt_{code}'] = feat_auc(lab, f, 'not trivial')[0]
    return m


# ---------------------------------------------------------------- sheet cases
def expected_and_mark(m, truth, verdict):
    if truth == 'no':
        exp = 'flag as false'; mk = 'SILENT' if verdict in ('dropped', 'unjudged') else 'FAIL'
    elif verdict == 'unjudged':
        exp = 'drop (trivial)' if is_triv(m) else 'keep' if is_int(m) else 'either'; mk = 'SILENT'
    elif is_triv(m):
        exp = 'drop (trivial)'; mk = 'PASS' if verdict == 'dropped' else 'FAIL'
    elif is_int(m):
        exp = 'keep' + ('' if truth == 'yes' else ', check truth'); mk = 'PASS' if verdict == 'kept' else 'FAIL'
    else:
        exp = 'either (obvious but real)'; mk = 'PASS'
    return exp, mk


# The biology for the facts most raters judged false, and for the worth-showing facts near the cut. Each source is a
# premise sentence of the textbook (data/textbook), an OLS4 record (verify_round2_curies.tsv) or a paper checked on
# Europe PMC or Crossref (verify_round2_refs.tsv).
SOURCES = {
    'R004': 'False as a universal. GABA-A receptors are ligand-gated chloride channels and "the major inhibitory neurotransmitter receptors" (Sigel 2012, PMID:23038269). GO:0015276 covers every ligand-gated channel; the book premise (the-body-s-systems-m45539-158) is about the sodium-passing receptors at one synapse.',
    'R008': 'False. tRNA carries 5-methyluridine (ribothymidine: the base is 5-methyluracil, that is thymine) at position 54, "one of the most highly conserved modifications" (Jones 2024, PMID:39159370). The book premise molbio-m45473-60 simplifies.',
    'R016': 'Depends on the reading. UBERON:0002020 gray matter is "a nervous system structure composed primarily of nerve cell bodies" (OLS4; the definition names no taxon), and part_of central nervous system, which uberon.obo (2026-10-01) puts in_taxon Bilateria; flatworms are Bilateria (NCBI Taxonomy lineage). The book means the vertebrate CNS (the-body-s-systems-m45539-272); the chain reads "cell bodies make up the gray matter" as true of every cell body.',
    'R017': 'False. RO:0002131 overlaps needs a shared part. The chain needs every microtubule to be part of a mitotic spindle; the book (reproduction-at-the-cellular-level-m45461-59) says only that the spindle is made of microtubules. Axonemal microtubules are not spindle parts.',
    'R020': 'True only indirectly, as R031 (changed 2026-10-31 by the review, from false). The kidney releases EPO when oxygen is low (book the-body-s-systems-m45537-238; HIF-2 drives EPO in kidney and liver: Haase 2013, PMID:23291219). The chain is arteries is_a blood vessel, blood vessel raises oxygen (the-body-s-systems-m45536-3, the same premise as R031 and R089), oxygen lowers EPO, EPO raises erythropoiesis (-240): every sign is right, and the core reads an effect as a signed, composable influence (Claim.effect, Derivation.viaAmount). Misleading as a regulation: the vessel is a carrier. The LLM pool calls it false and R031, R089 true; the checked source treats all three alike.',
    'R021': 'False as a universal (added 2026-10-31 by the review). The chain is "other compounds move passively across the membrane" (cell-structure-and-function-m45432-15), encoded as every passive transmembrane transport occurring in the plasma membrane, then plasma membrane part of endomembrane system (-m45432-89). In GO (go.obo 2026-07-26) channel activity (GO:0015267) is_a passive transmembrane transporter activity (GO:0022803), and the uniplex complex (GO:1990246) is "a calcium channel complex in the mitochondrial inner membrane"; GO does not place the mitochondrial inner membrane (GO:0005743), nor the plasma membrane (GO:0005886), under GO:0012505. Only the GO:0012505 definition text names "cell membrane".',
    'R026': 'Depends on the reading. GO:0012505 endomembrane system names "cell membrane" among its main components in its definition text, but GO\'s graph (go.obo 2026-07-26) does not place the plasma membrane (GO:0005886) under it. Myofibrils attach to the sarcolemma at their ends (the-body-s-systems-m45538-241). The book adds the plasma membrane only "although not technically within the cell" (cell-structure-and-function-m45432-89).',
    'R031': 'True only indirectly. Blood vessels supply oxygen (the-body-s-systems-m45536-3) and without oxygen the transfer stops (how-cells-obtain-energy-m45439-20). "Blood vessel promotes the electron transport chain" is a path through a carrier, not a regulation.',
    'R036': 'False: a context clash. Leaf (PO:0025034) is a plant organ; erythropoietin (PR:000007141) is released by kidneys in response to low oxygen (book the-body-s-systems-m45537-238). The refinement "located in leaf" inherited a fact about the body.',
    'R043': 'False universal. The book premise says "Accessory organs play an important role ... during digestion" (the-body-s-systems-m45535-246); it was encoded as true of every organ.',
    'R062': 'False. The book says "metabolism is composed of synthesis (anabolism) and degradation (catabolism)" (how-cells-obtain-energy-m45437-31), encoded as "every metabolic process has part anabolism". Glucose catabolic process (GO:0006007) is a breakdown, not a synthesis.',
    'R068': 'False: an equivocation. "Cells of the immune system fight invading bacteria" (cell-structure-and-function-m45427-11) and "the colon is home to many bacteria ... that aid in the digestive processes" (the-body-s-systems-m45535-130) are about different bacteria.',
    'R070': 'Depends on the reading (changed 2026-10-31 from false). GO:0000785 chromatin is "the ordered and organized complex of DNA, protein, and sometimes RNA, that forms the chromosome" (OLS4, rechecked 2026-10-31; no taxon constraint in its OLS4 record). "Small basic proteins present in most Archaea share a common ancestor with the eukaryotic core histones" and form archaeal chromatin (Mattiroli 2017, PMID:28798133); archaea are prokaryotes. In the book\'s sense (chromatin within the nucleus, cell-structure-and-function-m45432-359) it is false. Round 2: all three raters said false; round 3: one false, two unsure (one citing archaeal histones).',
    'R072': 'False. "For NADPH, it is a hydrogen atom" (photosynthesis-m45452-79) and "these atoms were originally part of a glucose molecule" (how-cells-obtain-energy-m45439-76) are about different atoms; overlaps (RO:0002131) needs one shared part. Round 2 raters split (one no, two unsure); all three round-3 raters said no.',
    'R073': 'False as a net effect. Insulin lowers blood glucose and high blood glucose makes beta cells release insulin (the-body-s-systems-m45537-53, -200): negative feedback. The derivation takes a longer path through glucagon (-336, -201) whose signs multiply to plus. A path sign is not the net effect.',
    'R074': 'False. The premise is "Prokaryotes have a single large chromosome that is not surrounded by a nuclear membrane" (cell-structure-and-function-m45429-74), encoded about every chromosome; notRelSub pushed it to eukaryotic chromosomes, which sit inside the nuclear envelope (GO:0005635).',
    'R076': 'False: the same equivocation as R068 (macrophages are immune cells; the bacteria that aid digestion are not the ones they fight).',
    'R088': 'Depends: true of bacteria and eukaryotes, not shown for every archaeon. The chain is cell has plasma membrane (cell-structure-and-function-m45429-5), membrane has phospholipid (-m45432-8), phospholipid has two fatty acid chains (-m45432-11). Archaeal lipids have "ether-linked isoprenoid chains" (Li 2025, PMID:40243902), not fatty-acid esters, so the last step fails for archaea; yet "certain archaea appear to synthesize and/or metabolize fatty acids" (Dibrova 2014, PMID:24818264). Round 3: two of three raters said false.',
    'R089': 'True only indirectly, as R031: oxygen from the blood is needed for oxidative phosphorylation (GO:0006119); the vessel is a carrier, not a regulator.',
    'R098': 'False as a universal (added 2026-10-31 by the review). The chain is "ions must pass through ion channels that span the membrane" (the-body-s-systems-m45539-57, said of the neuron), encoded as every ion channel part of the plasma membrane, then plasma membrane part of endomembrane system (cell-structure-and-function-m45432-89). In GO (go.obo 2026-07-26) the uniplex complex (GO:1990246) is_a monoatomic ion channel complex (GO:0034702) and part of the mitochondrial inner membrane (GO:0005743, via GO:0098800), which GO does not place under GO:0012505.',
}
# The truth a case's mark uses (review fix, 2026-10-30): the checked source above where there is one, else the LLM pool.
# 'unsure' where the source says it depends on the reading. Section 8 prints the rows where this differs from the LLM
# pool. 2026-10-31: R070 changed from 'no' to 'unsure' (archaeal histone chromatin, Mattiroli 2017) and R088 added
# ('unsure': archaeal lipids, Dibrova 2014); both points were raised by round-3 raters and checked on Europe PMC.
# Review, 2026-10-31: R020 from 'no' to 'unsure' (the same shape and carrier premise as R031 and R089, which were
# already 'unsure'); R021 and R098 added as 'no' (a premise read as a universal; GO's own uniplex complex is a
# counter-example, and GO's graph does not put the plasma membrane under the endomembrane system).
# Dan's own mark (mark_dan) keeps Dan's own truth call.
SOURCE_TRUTH = {'R004': 'no', 'R008': 'no', 'R016': 'unsure', 'R017': 'no', 'R020': 'unsure', 'R021': 'no', 'R026': 'unsure',
                'R031': 'unsure', 'R036': 'no', 'R043': 'no', 'R062': 'no', 'R068': 'no', 'R070': 'unsure', 'R072': 'no',
                'R073': 'no', 'R074': 'no', 'R076': 'no', 'R088': 'unsure', 'R089': 'unsure', 'R098': 'no'}


# ---------------------------------------------------------------- pins (observed 2026-10-31, round-3 LLM raters only)
# Re-pinned 2026-10-31 after round 3 replaced the live rating files; the round-2 pins are in git 6441d2f.
# id -> (verdict at 2.5, IC, mark from the checked source, else the LLM pool)
PINS = {
    'R002': ('kept', 2.657, 'PASS'),
    'R003': ('unjudged', None, 'SILENT'),
    'R004': ('kept', 5.01, 'FAIL'),
    'R008': ('kept', 9.039, 'FAIL'),
    'R013': ('kept', 2.657, 'FAIL'),
    'R014': ('kept', 2.995, 'PASS'),
    'R016': ('dropped', 2.446, 'PASS'),
    'R017': ('kept', 4.879, 'FAIL'),
    'R018': ('dropped', 2.193, 'PASS'),
    'R019': ('kept', 2.995, 'FAIL'),
    'R020': ('kept', 3.477, 'PASS'),   # review 2026-10-31: source truth 'unsure', as R031 and R089
    'R021': ('dropped', 2.433, 'SILENT'),   # review 2026-10-31: false by checked source
    'R023': ('dropped', 2.282, 'PASS'),
    'R024': ('dropped', 2.026, 'PASS'),
    'R026': ('dropped', 2.433, 'PASS'),
    'R031': ('kept', 2.657, 'PASS'),
    'R032': ('kept', 2.912, 'FAIL'),
    'R033': ('dropped', 2.026, 'PASS'),
    'R034': ('kept', 2.657, 'FAIL'),
    'R036': ('unjudged', None, 'SILENT'),
    'R037': ('kept', 2.606, 'PASS'),
    'R039': ('kept', 2.657, 'FAIL'),
    'R040': ('dropped', 2.193, 'PASS'),
    'R043': ('dropped', 0.322, 'SILENT'),
    'R044': ('kept', 2.657, 'FAIL'),
    'R047': ('kept', 2.516, 'PASS'),
    'R049': ('dropped', 2.282, 'PASS'),
    'R051': ('dropped', 2.014, 'PASS'),
    'R052': ('kept', 2.516, 'PASS'),
    'R053': ('kept', 2.657, 'FAIL'),
    'R056': ('dropped', 2.163, 'PASS'),
    'R058': ('kept', 2.657, 'FAIL'),
    'R059': ('kept', 2.912, 'PASS'),
    'R061': ('dropped', 2.014, 'PASS'),
    'R062': ('dropped', 2.439, 'SILENT'),
    'R064': ('dropped', 2.026, 'PASS'),
    'R065': ('kept', 2.793, 'PASS'),
    'R066': ('dropped', 2.026, 'PASS'),
    'R067': ('unjudged', None, 'SILENT'),
    'R068': ('dropped', 1.761, 'SILENT'),
    'R070': ('kept', 3.859, 'PASS'),
    'R072': ('kept', 9.206, 'FAIL'),
    'R073': ('unjudged', None, 'SILENT'),
    'R074': ('kept', 2.995, 'FAIL'),
    'R075': ('kept', 2.793, 'PASS'),
    'R076': ('kept', 3.781, 'FAIL'),
    'R077': ('kept', 2.995, 'FAIL'),
    'R079': ('dropped', 2.282, 'PASS'),
    'R080': ('kept', 2.793, 'FAIL'),
    'R083': ('dropped', 2.433, 'PASS'),
    'R084': ('dropped', 2.282, 'PASS'),
    'R085': ('dropped', 2.282, 'PASS'),
    'R088': ('dropped', 0.002, 'PASS'),
    'R089': ('kept', 2.657, 'PASS'),
    'R091': ('kept', 2.995, 'FAIL'),
    'R092': ('dropped', 2.282, 'PASS'),
    'R094': ('kept', 2.793, 'FAIL'),
    'R098': ('dropped', 2.433, 'SILENT'),   # review 2026-10-31: false by checked source
    'R100': ('dropped', 2.163, 'PASS'),
}
HEAD_PINS = {
    'fleiss_interesting_llm': 0.8,
    'fleiss_true_llm': 0.716,
    'fleiss_interesting_2plus_llm': 0.906,
    'true_all_agree_llm': 0.84,
    'true_pairwise_agreement_llm': 0.893,
    'old_T_kappa_llm': 0.818,
    'primed_rows': 'R008,R020,R031,R048,R073,R078,R088,R089',
    'primed_change_by_pair': 'r1r2 0.25/0.17 3/5; r1r3 0.12/0.13 2/7; r2r3 0.12/0.10 3/6',
    'rounds_scorer_exact': 'r1 (2.433, 2.439]; r2 (2.282, 2.433]; r3 (2.433, 2.439]; r23 (2.282, 2.433]',
    'rounds_plateau': 'r1 (2.433, 2.657]; r2 (2.282, 2.446]; r3 (2.433, 2.657]; r23 (2.282, 2.657]',
    'rounds_interesting_worth_true_false': 'r1 14/5/4/12; r2 14/6/0/12; r3 15/7/4/13; r23 12/3/0/13',
    'rounds_worth_flip': 'R016,R020,R026,R055,R070,R071,R072,R078,R081,R090',
    'r23_boot_modal_share_2.5_in_plateau': '0.59/0.60',
    'x7_wk_same_interval_pass': '0.853/0.869/0.947; False; False',
    'trivial_removed_of_total_at_2.5_llm': '28/53',
    'precision_0_2.5_2.4_llm': '0.146/0.211/0.206',
    'trivial_share_w_0_2.5_2.4_llm': '0.565/0.426/0.420',
    'scorer_T_llm': 2.5,
    'safe_T_llm': 2.5,
    'best_f1_T_llm': 3.25,
    'f1_at_2.5_llm': 0.338,
    'worth_llm': 7,
    'interesting_and_true_llm': 4,
    'scorer_T_exact_llm': 2.439,
    'scorer_interval_exact_llm': '(2.433, 2.439]',
    'scorer_exact_stable_to_one_row_llm': False,
    'scorer_exact_boot_share_llm': 0.37,
    'safe_T_exact_llm': 2.657,
    'best_f1_T_exact_llm': 3.477,
    'scorer_removed_exact_llm': 28,
    'plateau_llm': '(2.433, 2.657]; 2.5 in it True; 2.4 in it False',
    'false_kept_llm': 7,
    'judged_false_llm': 13,
    'interesting_n_false_unsure_true_llm': '15/8/3/4',
    'auc_ic_llm': 0.7,
    'auc_nt_ic_llm': 0.698,
    'auc_pm_llm': 0.606,
    'auc_nt_pm_llm': 0.621,
    'auc_gain_llm': 0.644,
    'auc_nt_gain_llm': 0.633,
    'auc_no_flag_llm': 0.708,
    'auc_nt_no_flag_llm': 0.774,
    'auc_depth_llm': 0.467,
    'auc_nt_depth_llm': 0.409,
    'auc_n_premises_llm': 0.472,
    'auc_nt_n_premises_llm': 0.408,
    'auc_onto_dist_llm': 0.827,
    'auc_nt_onto_dist_llm': 0.772,
    'a25_kept_trivial_worthlost_falsekept_llm': '57/25/0/7',
    'a24_kept_trivial_worthlost_falsekept_llm': '63/26/0/8',
    'c2_kept_trivial_worthlost_falsekept_llm': '55/17/0/9',
    'c2a_trivial_kept_llm': 5,
    'c2a_worth_lost_llm': 0,
    'c2a225_kept_trivial_worthlost_falsekept_llm': '42/7/0/7',
    'c2a24_kept_trivial_worthlost_falsekept_llm': '40/6/0/7',
    'flagged_trivial_worth_llm': '42/37/0',
    'flag_kinds_n_trivial_llm': 'restatement 21/18; weakening 18/18; entailed 9/7',
    'source_vs_pool_differs': 'R020,R021,R026,R031,R088,R089,R098',
    'case_marks_llm': '32/18/9/0',
    'case_pass_right_either_llm': '19/13',
    # added by the review, 2026-10-31
    'plateau_if_r031_r089_demoted_llm': '(3.674, 3.905]',
    'core_belief_values_auc_tf_auc_int': '0.8 x89, 0.64 x9, 0.512 x1, 0.41 x1; 0.635; 0.210',
    'case_fail_kinds_llm': '6/12/0',
    'case_cut_job_right_llm': '19/31',
    'source_false_kept_dropped_unjudged': '13: 6/5/2',
    'band_2.4_2.5_truth': 'R021 no, R026 unsure, R083 yes, R098 no, R062 no, R016 unsure',
    'closure_pm_drop_top100_chebi': '162/1219; 89',
    'closure_unscored_ends_by_prefix': 'PR 155, NCBITaxon 95, PO 27, MONDO 26, PATO 24, SO 19, HP 3, OBA 3',
    'x4_exact_grid_llm': '1.342/1.25',
    'closure_facts_terms_2.25_to_2.5': '58/5',
    'closure_kept_dropped_unjudged_2.25': '1277/660/286',
    'closure_kept_dropped_unjudged_2.4': '1247/695/281',
    'closure_kept_dropped_unjudged_2.5': '1219/724/280',
    'closure_kept_flagged_2.5': '443/1219',
    'c2_flags_c27_c28': 'weakening+entailed; entailed',
}


def arg(name, default):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default


def write(path, rows):
    with open(path, 'w', encoding='utf-8') as fh:
        for r in rows: fh.write('\t'.join(str(x).replace('\t', ' ').replace('\n', ' ') for x in r) + '\n')


def main():
    out_dir = arg('--out', D)
    os.makedirs(out_dir, exist_ok=True)
    rows = load()
    ids = {r['id'] for r in rows}
    byid = {r['id']: r for r in rows}
    bad = []
    ratings = {n: read_ratings(p, ids, bad) for n, p in LLM}
    dan_p = arg('--dan', None) or next((p for p in DAN if os.path.exists(p)), None)
    if dan_p:
        ratings['dan'] = read_ratings(dan_p, ids, bad)
        if not ratings['dan']:
            print(f'{dan_p} has no rated rows yet: running on the LLM raters only')
            del ratings['dan']; dan_p = None
    llm = [n for n, _ in LLM]
    raters = llm + (['dan'] if dan_p else [])
    rep, summ, HEAD, flipped = [], [], {}, []
    say = lambda s='': (rep.append(s), print(s))
    put = lambda sec, item, val: summ.append((sec, item, str(val)))

    views = {n: dict(ratings[n]) for n in raters}
    views['pooled_llm'] = pool(rows, ratings, llm)
    if dan_p: views['pooled_all'] = pool(rows, ratings, raters)
    pooled = 'pooled_all' if dan_p else 'pooled_llm'
    order = raters + ['pooled_llm'] + (['pooled_all'] if dan_p else [])
    maxic = max(r['ic'] for r in rows if r['ic'] is not None)
    ts = thresholds(maxic)
    sc_by = {v: [r for r in labels(rows, views[v]) if r['ic'] is not None] for v in order}
    n_scored = len([r for r in rows if r['ic'] is not None])

    say('Program 07 rating analysis')
    say('Raters: ' + ', '.join(f'{n} ({len(ratings[n])} rows)' for n in raters))
    if not dan_p:
        say('No rating_dan.tsv yet. EVERY NUMBER BELOW IS FROM LLM STAND-INS, NOT A HUMAN.')
    if bad: say(f'Problems in the rating files ({len(bad)}): ' + '; '.join(bad))
    put('raters', 'raters and rows rated', '; '.join(f'{n} {len(ratings[n])}' for n in raters))
    put('raters', 'human rating present', 'yes' if dan_p else 'no')
    km = {v: key_metrics(rows, views[v], ts) for v in order}

    # ---- 0. Dan at a glance
    if dan_p:
        say(f'\n0. Dan at a glance ({os.path.basename(dan_p)}, {len(ratings["dan"])} rows rated)')
        d = km.get('dan')
        common = [i for i in ratings['dan'] if i in views['pooled_llm']]
        wk = weighted_kappa([ratings['dan'][i][0] for i in common],
                            [min(3, max(0, round(views['pooled_llm'][i][0]))) for i in common])
        say(f'  agreement with the LLM mean (rounded), weighted kappa: {f3(wk)} ({band(wk)}), {len(common)} rows')
        if d:
            say(f"  your scorer-rule T: {d['scorer_T']}  (LLM pool: {km['pooled_llm']['scorer_T']}); highest T losing nothing "
                f"worth showing: {d['safe_T']}; best-F1 T: {d['best_f1_T']}  (0.25 grid)")
            cps0 = cut_points(rows)
            say(f"  your scorer-rule T on exact cut points: {interval(d['scorer_T_exact'], cps0)}  (LLM pool: "
                f"{interval(km['pooled_llm']['scorer_T_exact'], cps0)}). Read this one: the grid has no point between 2.28 and 2.43")
            say(f"  your plateau (every T as good as your best): {d['plateau']}; 2.5 in it: {'yes' if d['plateau_has_2.5'] else 'no'}; "
                f"2.4 in it: {'yes' if d['plateau_has_2.4'] else 'no'}  (LLM round 3: {km['pooled_llm']['plateau']})")
            say(f"  your AUC of IC, interesting: {f3(d['auc_ic'])} (LLM {f3(km['pooled_llm']['auc_ic'])}); not trivial: "
                f"{f3(d['auc_nt_ic'])} (LLM {f3(km['pooled_llm']['auc_nt_ic'])})")
            say(f"  your AUC of 'no structural flag', not trivial: {f3(d['auc_nt_no_flag'])} (LLM {f3(km['pooled_llm']['auc_nt_no_flag'])})")
            say(f"  you rated {d['judged_false']} rows false; {d['false_kept']} of them survive the 2.5 cut")
        gap = sorted([r for r in rows if r['ic'] is not None and 2.4 <= r['ic'] < IC_MIN], key=lambda r: (r['ic'], r['id']))
        say(f'  the {len(gap)} rows between 2.4 and 2.5 decide between those two cuts. Yours, then the LLM round-3 mean:')
        for r in gap:
            g = ratings['dan'].get(r['id']); lm = views['pooled_llm'][r['id']]
            say(f"    {r['id']}  IC {r['ic']:.3f}  you {'/'.join(map(str, g)) if g else 'not rated'}  LLM {lm[0]:.2f}/{lm[1]}  {r['fact'][:70]}")
        put('dan', 'weighted kappa with rounded LLM mean; n', f'{f3(wk)}; {len(common)}')
        say('  The exit tests (section 9) are computed for you too.')

    # ---- 1. spread and agreement
    say('\n1. Spread and agreement')
    for n in raters:
        c = collections.Counter(l for l, _ in ratings[n].values()); t = collections.Counter(x for _, x in ratings[n].values())
        it = sum(l >= 2 and x == 'yes' for l, x in ratings[n].values())
        say(f'  {n:<5} interesting 0/1/2/3 = {c[0]}/{c[1]}/{c[2]}/{c[3]}   true yes/no/unsure = {t["yes"]}/{t["no"]}/{t["unsure"]}'
            f'   rated 2 or 3 AND true: {it}')
        put('spread', f'{n} interesting 0/1/2/3; true yes/no/unsure; rated 2+ and true',
            f'{c[0]}/{c[1]}/{c[2]}/{c[3]}; {t["yes"]}/{t["no"]}/{t["unsure"]}; {it}')
    agree = [('group', 'measure', 'n_items', 'value', 'band')]

    def agreement(names, tag):
        common = [r['id'] for r in rows if all(r['id'] in ratings[n] for n in names)]
        if len(names) < 2 or not common: return {}
        res = {}
        for lab, f, k in (('interesting, 4 levels', lambda l: l, 4), ('interesting, 0 against 1+', lambda l: int(l >= 1), 2),
                          ('interesting, under 2 against 2+', lambda l: int(l >= 2), 2)):
            res[lab] = fleiss([[sum(f(ratings[n][i][0]) == c for n in names) for c in range(k)] for i in common])
        cats = ['yes', 'no', 'unsure']
        res['true, 3 values'] = fleiss([[sum(ratings[n][i][1] == c for n in names) for c in cats] for i in common])
        res['true, all raters agree (share)'] = sum(len({ratings[n][i][1] for n in names}) == 1 for i in common) / len(common)
        pairs = [(a, b) for x, a in enumerate(names) for b in names[x + 1:]]
        res['true, mean pairwise agreement (share)'] = statistics.mean(
            sum(ratings[a][i][1] == ratings[b][i][1] for i in common) / len(common) for a, b in pairs)
        res['interesting, all raters agree (share)'] = sum(len({ratings[n][i][0] for n in names}) == 1 for i in common) / len(common)
        for lab, v in res.items():
            isk = 'share' not in lab
            agree.append((tag, ('Fleiss kappa, ' if isk else '') + lab, len(common), f3(v), band(v) if isk else ''))
        for a, b in pairs:
            wk = weighted_kappa([ratings[a][i][0] for i in common], [ratings[b][i][0] for i in common])
            agree.append((tag, f'{a} vs {b}: weighted kappa on interesting (quadratic)', len(common), f3(wk), band(wk)))
            ck = cohen([ratings[a][i][1] for i in common], [ratings[b][i][1] for i in common])
            agree.append((tag, f'{a} vs {b}: Cohen kappa on true', len(common), f3(ck), band(ck)))
            agree.append((tag, f'{a} vs {b}: percent agreement on true', len(common),
                          f3(sum(ratings[a][i][1] == ratings[b][i][1] for i in common) / len(common)), ''))
        res['n'] = len(common)
        return res

    ag = agreement(llm, 'llm raters')
    say(f"  three LLM raters, {ag['n']} rows: Fleiss kappa on interesting (0 to 3) = {ag['interesting, 4 levels']:.3f} "
        f"({band(ag['interesting, 4 levels'])}); 0 against 1+ = {ag['interesting, 0 against 1+']:.3f}; "
        f"under 2 against 2+ = {ag['interesting, under 2 against 2+']:.3f}")
    say(f"  same level from all three: {pcts(ag['interesting, all raters agree (share)'])} of rows")
    say(f"  'true': all three agree on {pcts(ag['true, all raters agree (share)'])} of rows; mean pairwise agreement "
        f"{pcts(ag['true, mean pairwise agreement (share)'])}; Fleiss kappa {ag['true, 3 values']:.3f} ({band(ag['true, 3 values'])})")
    for lab in ('interesting, 4 levels', 'interesting, 0 against 1+', 'interesting, under 2 against 2+', 'true, 3 values'):
        put('agreement', f'llm Fleiss kappa, {lab}', f"{ag[lab]:.3f} ({band(ag[lab])})")
    put('agreement', 'llm true: all three agree; mean pairwise agreement',
        f"{pcts(ag['true, all raters agree (share)'])}; {pcts(ag['true, mean pairwise agreement (share)'])}")
    put('agreement', 'llm interesting: all three give the same level', pcts(ag['interesting, all raters agree (share)']))
    HEAD['fleiss_interesting_llm'] = round(ag['interesting, 4 levels'], 3)
    HEAD['fleiss_true_llm'] = round(ag['true, 3 values'], 3)
    HEAD['fleiss_interesting_2plus_llm'] = round(ag['interesting, under 2 against 2+'], 3)
    HEAD['true_all_agree_llm'] = round(ag['true, all raters agree (share)'], 2)
    HEAD['true_pairwise_agreement_llm'] = round(ag['true, mean pairwise agreement (share)'], 3)
    if dan_p:
        ga = agreement(raters, 'all raters')
        if ga:
            say(f"  all {len(raters)} raters, {ga['n']} rows: Fleiss kappa on interesting = {ga['interesting, 4 levels']:.3f} "
                f"({band(ga['interesting, 4 levels'])}); on true = {ga['true, 3 values']:.3f}; true, mean pairwise agreement "
                f"{pcts(ga['true, mean pairwise agreement (share)'])}")
            put('agreement', 'all raters Fleiss kappa, interesting 4 levels; true',
                f"{ga['interesting, 4 levels']:.3f} ({band(ga['interesting, 4 levels'])}); {ga['true, 3 values']:.3f}")
        for n in llm:
            c2 = [i for i in ratings['dan'] if i in ratings[n]]
            wk = weighted_kappa([ratings['dan'][i][0] for i in c2], [ratings[n][i][0] for i in c2])
            agree.append(('dan', f'dan vs {n}: weighted kappa on interesting (quadratic)', len(c2), f3(wk), band(wk)))
            pa = sum(ratings['dan'][i][1] == ratings[n][i][1] for i in c2) / len(c2) if c2 else None
            agree.append(('dan', f'dan vs {n}: percent agreement on true', len(c2), f3(pa), ''))
    # old 42 LLM labels (2026-10-28, one LLM, T/S/E) against the new ratings, on the 33 rows that carry one
    old = [r for r in rows if r['old'] in ('T', 'S', 'E')]
    say(f'  old LLM labels (2026-10-28, T/S/E) on {len(old)} sheet rows, against round 3 (the live rating files):')
    for v in llm + (['dan'] if dan_p else []) + ['pooled_llm']:
        got = [r for r in old if r['id'] in views[v]]
        if not got: continue
        a = [r['old'] == 'T' for r in got]; b = [is_triv(views[v][r['id']][0]) for r in got]
        k1 = cohen(a, b)
        e_false = sum(r['old'] == 'E' and views[v][r['id']][1] == 'no' for r in got)
        n_e = sum(r['old'] == 'E' for r in got)
        say(f'    {v:<10} T against trivial: agree {pcts(sum(x == y for x, y in zip(a, b)) / len(got))}, Cohen kappa {f3(k1)}; '
            f'old E rows now judged false: {e_false} of {n_e}')
        agree.append(('old 42 labels', f'{v}: old T against trivial, Cohen kappa', len(got), f3(k1), band(k1)))
        put('agreement', f'old labels vs {v}: T against trivial kappa; E judged false', f'{f3(k1)}; {e_false} of {n_e}')
        if v == 'pooled_llm': HEAD['old_T_kappa_llm'] = round(k1, 3)
    write(f'{out_dir}/analysis_agreement.tsv', agree)

    # ---- 2. rounds (rewritten 2026-10-31). Round 1: first-draft rubric (primed). Rounds 2 and 3: the current rubric,
    # fresh blind raters each time. Rounds 2 and 3 measure run-to-run noise, the control for the priming claim (X7).
    r1 = read_round1(ids); r2 = read_round2(ids, bad)
    R = {'r1': r1, 'r2': r2, 'r3': {n: ratings[n] for n in llm}}
    R = {k: v for k, v in R.items() if v and all(len(v.get(n, {})) == len(rows) for n in llm)}
    RNAME = {'r1': 'round 1, first-draft rubric (primed)', 'r2': 'round 2, current rubric',
             'r3': 'round 3, current rubric (the live rating files)', 'r23': 'rounds 2 and 3 pooled (six ratings a row)'}
    x7 = None; cps = cut_points(rows)
    if len(R) >= 2 and 'r3' in R:
        say('\n2. Rounds: the same sheet rated three times by fresh blind LLM raters')
        for k in R: say(f'  {k}: {RNAME[k]}')
        facts = {f['fact']: f for f in load_closure()}
        ex = [x['fact'] for x in read_tsv(f'{D}/sheet_draw_exclusions.tsv') if x['why'].startswith('rubric example, first draft')]
        ex_tpl = {e: templates(facts[e]['k']) for e in ex if e in facts}
        primed = {}
        for r in rows:
            hit = [e for e, t in ex_tpl.items() if t & templates(r['k'])]
            if hit: primed[r['id']] = hit[0].split(' [')[0]
        primed.update({i: v for i, v in PRIMED_BY_HAND.items() if i not in primed})
        P = {k: pool(rows, v, llm) for k, v in R.items()}
        if 'r2' in R:
            six = {f'{k}_{n}': R[k][n] for k in ('r2', 'r3') for n in llm}
            P['r23'] = pool(rows, six, list(six))
        pr = [r['id'] for r in rows if r['id'] in primed]; ot = [r['id'] for r in rows if r['id'] not in primed]
        HEAD['primed_rows'] = ','.join(sorted(pr))
        rd = lambda m: min(3, max(0, round(m)))
        pairs = [(a, b) for a, b in (('r1', 'r2'), ('r1', 'r3'), ('r2', 'r3')) if a in R and b in R]
        prim_pin = []
        for a, b in pairs:
            tag = f'{a} vs {b}' + ('  (control: same rubric)' if a != 'r1' else '  (rubric changed)')
            per = []
            for n in llm:
                x = [R[a][n][r['id']][0] for r in rows]; y = [R[b][n][r['id']][0] for r in rows]
                wk = weighted_kappa(x, y); same = sum(p == q for p, q in zip(x, y)) / len(rows)
                st = sum(R[a][n][r['id']][1] == R[b][n][r['id']][1] for r in rows) / len(rows)
                per.append(f'{n} {f3(wk)}/{pcts(same)}/{pcts(st)}')
                put('rounds', f'{n} {a} vs {b}: weighted kappa; same level; same truth', f'{f3(wk)}; {pcts(same)}; {pcts(st)}')
            wkp = weighted_kappa([rd(P[a][r['id']][0]) for r in rows], [rd(P[b][r['id']][0]) for r in rows])
            ch = {r['id']: P[b][r['id']][0] - P[a][r['id']][0] for r in rows}
            tc = {r['id']: P[a][r['id']][1] != P[b][r['id']][1] for r in rows}
            mp = statistics.mean(abs(ch[i]) for i in pr); mo = statistics.mean(abs(ch[i]) for i in ot)
            tp_, to_ = sum(tc[i] for i in pr), sum(tc[i] for i in ot)
            say(f'  {tag}')
            say(f'    per rater, weighted kappa / same level / same truth: ' + '; '.join(per))
            say(f'    pooled mean (rounded), weighted kappa {f3(wkp)}. Average change of the pooled mean: primed rows '
                f'({len(pr)}) {mp:.2f}, other rows ({len(ot)}) {mo:.2f}. Pooled truth changed: primed {tp_} of {len(pr)}, '
                f'other {to_} of {len(ot)}')
            put('rounds', f'{a} vs {b}: pooled weighted kappa; |change| primed, other; truth changed primed, other',
                f'{f3(wkp)}; {mp:.2f}, {mo:.2f}; {tp_} of {len(pr)}, {to_} of {len(ot)}')
            prim_pin.append(f'{a}{b} {mp:.2f}/{mo:.2f} {tp_}/{to_}')
            big = sorted([i for i in ids_sorted(rows) if abs(ch[i]) >= 0.67 or tc[i]], key=lambda i: (-abs(ch[i]), i))
            say(f'    rows whose pooled mean moved by 0.67 or more, or whose truth changed ({len(big)}): ' +
                '; '.join(f'{i}{"*" if i in primed else ""} {P[a][i][0]:.2f}{P[a][i][1][0]}->{P[b][i][0]:.2f}{P[b][i][1][0]}' for i in big))
            put('rounds', f'{a} vs {b}: rows that moved (0.67+ or truth; * = primed)', ', '.join(i + ('*' if i in primed else '') for i in big))
        HEAD['primed_change_by_pair'] = '; '.join(prim_pin)
        say('  primed rows, pooled mean and truth by round:')
        for i in sorted(pr):
            say(f'    {i}  ' + '   '.join(f'{k} {P[k][i][0]:.2f} {P[k][i][1]:<6}' for k in P) +
                f'  IC {f2(byid[i]["ic"])}  example: {primed[i][:50]}')
        M = {k: key_metrics(rows, P[k], ts) for k in P}
        say('  pooled, by round:' + ''.join(f'{k:>12}' for k in P))
        for lab, k in (('interesting rows', 'interesting'), ('worth showing (interesting, not judged false)', 'worth'),
                       ('interesting and judged true', 'interesting_and_true'), ('judged false', 'judged_false'),
                       ('scorer-rule T, 0.25 grid', 'scorer_T'), ('highest T losing nothing, grid', 'safe_T'),
                       ('best-F1 T, grid', 'best_f1_T'), ('scorer-rule T, exact cut points', 'scorer_T_exact'),
                       ('highest T losing nothing, exact', 'safe_T_exact'), ('best-F1 T, exact', 'best_f1_T_exact'),
                       ('AUC of IC, interesting', 'auc_ic'), ('AUC of IC, not trivial', 'auc_nt_ic'),
                       ('AUC of path_min, interesting', 'auc_pm'), ('AUC of gain, interesting', 'auc_gain'),
                       ('AUC of no flag, interesting', 'auc_no_flag'), ('AUC of no flag, not trivial', 'auc_nt_no_flag'),
                       ('AUC of depth, interesting', 'auc_depth'), ('AUC of ontology distance, interesting', 'auc_onto_dist')):
            vals = [M[x][k] for x in P]
            fv = [f3(v) if k.startswith('auc') else ('' if v is None else f'{v:.3f}' if isinstance(v, float) and 'exact' in k else str(v)) for v in vals]
            say(f'    {lab:<46}' + ''.join(f'{v:>12}' for v in fv))
            put('rounds', f'pooled {lab}: ' + ' / '.join(P), ' / '.join(fv))
        say('  exact cut points by round: the scorer rule (lowest T on ties), and its plateau (every equally good T):')
        for k in P:
            sv = [r for r in labels(rows, P[k]) if r['ic'] is not None]
            x0 = M[k]['scorer_T_exact']
            hinge = [r['id'] for r in sv if is_worth(r) and
                     scorer_rule([dict(x, lvl=1.0) if x['id'] == r['id'] else x for x in sv], cps)[0] != x0]
            say(f"    {k:<4} scorer {interval(x0, cps)}; plateau {M[k]['plateau']}; 2.5 in it: "
                f"{'yes' if M[k]['plateau_has_2.5'] else 'no'}; 2.4 in it: {'yes' if M[k]['plateau_has_2.4'] else 'no'}; "
                f"worth showing {M[k]['worth']} ({M[k]['worth_ids']}); demoting one of these moves the scorer T: {', '.join(hinge) or 'none'}")
            put('rounds', f'{k}: exact scorer interval; plateau; 2.5 in plateau; 2.4 in plateau; hinge rows',
                f"{interval(x0, cps)}; {M[k]['plateau']}; {M[k]['plateau_has_2.5']}; {M[k]['plateau_has_2.4']}; {', '.join(hinge) or 'none'}")
        HEAD['rounds_scorer_exact'] = '; '.join(f"{k} {interval(M[k]['scorer_T_exact'], cps)}" for k in P)
        HEAD['rounds_plateau'] = '; '.join(f"{k} {M[k]['plateau']}" for k in P)
        HEAD['rounds_interesting_worth_true_false'] = '; '.join(
            f"{k} {M[k]['interesting']}/{M[k]['worth']}/{M[k]['interesting_and_true']}/{M[k]['judged_false']}" for k in P)
        ws = {k: {r['id'] for r in labels(rows, P[k]) if is_worth(r)} for k in P}
        flip = sorted(set.union(*[ws[k] for k in R]) - set.intersection(*[ws[k] for k in R]))
        say(f'  rows worth showing in some rounds but not all ({len(flip)}): ' +
            '; '.join(f"{i} (IC {f2(byid[i]['ic'])}: " + ', '.join(f'{k} {P[k][i][0]:.2f}{P[k][i][1][0]}' for k in R) + ')' for i in flip))
        put('rounds', 'rows worth showing in some rounds but not all', ', '.join(flip))
        HEAD['rounds_worth_flip'] = ','.join(flip)
        if 'r23' in P:
            sv = [r for r in labels(rows, P['r23']) if r['ic'] is not None]
            bx = M['r23']['scorer_T_exact']; rng = random.Random(20261031); bs = []; inp = 0
            for _ in range(NBOOT):
                s = [sv[rng.randrange(len(sv))] for _ in sv]
                t = scorer_rule(s, cps)
                if t: bs.append(t[0])
                inp += in_plateau(IC_MIN, plateau(s, cps), cps)
            share_x = sum(b == bx for b in bs) / len(bs)
            say(f'  r23 bootstrap ({NBOOT} resamples): the exact scorer T lands in {interval(bx, cps)} in {pcts(share_x)}; '
                f'2.5 is in the plateau in {pcts(inp / NBOOT)}')
            put('rounds', 'r23 bootstrap: share in the modal exact interval; share with 2.5 in the plateau',
                f'{pcts(share_x)}; {pcts(inp / NBOOT)}')
            HEAD['r23_boot_modal_share_2.5_in_plateau'] = f'{share_x:.2f}/{inp / NBOOT:.2f}'
        if 'r2' in R:
            wks = [weighted_kappa([R['r2'][n][r['id']][0] for r in rows], [R['r3'][n][r['id']][0] for r in rows]) for n in llm]
            same_iv = M['r2']['scorer_T_exact'] == M['r3']['scorer_T_exact']
            x7 = (wks, same_iv, all(w is not None and w >= 0.8 for w in wks) and same_iv)
            HEAD['x7_wk_same_interval_pass'] = '/'.join(f3(w) for w in wks) + f'; {same_iv}; {x7[2]}'
        rh = ['id', 'primed_by', 'fact', 'ic', 'verdict_2.5']
        for k in R: rh += [f'{k}_{n}' for n in llm] + [f'{k}_mean', f'{k}_truth']
        if 'r23' in P: rh += ['r23_mean', 'r23_truth']
        rh += [f'change_{a}_{b}' for a, b in pairs]
        rounds_out = [tuple(rh)]
        for r in rows:
            i = r['id']
            line = [i, primed.get(i, ''), r['fact'], '' if r['ic'] is None else r['ic'], r['verdict']]
            for k in R: line += ['/'.join(map(str, R[k][n][i])) for n in llm] + [f'{P[k][i][0]:.2f}', P[k][i][1]]
            if 'r23' in P: line += [f"{P['r23'][i][0]:.2f}", P['r23'][i][1]]
            line += [f'{P[b][i][0] - P[a][i][0]:+.2f}' for a, b in pairs]
            rounds_out.append(tuple(line))
        write(f'{out_dir}/analysis_rounds.tsv', rounds_out)
    else:
        say('\n2. Round comparison skipped: round1_primed/analysis_rows.tsv or round2/ is missing or incomplete')

    # ---- 3. threshold curve
    curve = [('rater', 'T', 'n_scored', 'kept', 'interesting', 'interesting_kept', 'precision', 'recall', 'f1',
              'precision_closure_weighted', 'recall_closure_weighted', 'worth_showing', 'worth_showing_kept',
              'precision_worth', 'recall_worth', 'trivial_kept', 'trivial_removed', 'worth_showing_lost',
              'judged_false_kept', 'youden_j', 'trivial_share_of_kept_closure_weighted')]
    say(f'\n3. Precision and recall of the cut (T from 0 to {ts[-1]} in steps of {STEP}; the {len(rows) - n_scored} rows '
        f'with no IC left out)')
    say('   Precision = share of kept facts rated interesting (2 or 3; pooled: mean 2 or more).')
    say('   Recall = share of interesting facts kept. Weighted = closure-wide estimate (the sheet over-samples near 2.5).')
    for v in order:
        for T in ts:
            p = curve_point(sc_by[v], T)
            curve.append((v, T, p['n'], p['kept'], p['pos'], p['tp'], f3(p['precision']), f3(p['recall']), f3(p['f1']),
                          f3(p['precision_w']), f3(p['recall_w']), p['worth'], p['worth_kept'], f3(p['precision_worth']),
                          f3(p['recall_worth']), p['trivial_kept'], p['trivial_removed'], p['worth_lost'], p['false_kept'],
                          f3(p['youden']), f3(p['trivial_share_w'])))
    write(f'{out_dir}/analysis_threshold_curve.tsv', curve)
    show = [0.0, 1.0, 2.0, 2.25, 2.5, 2.75, 3.0, 3.25, 3.5, 4.0, 5.0, 6.0, 8.0]
    for v in order:
        p0 = curve_point(sc_by[v], 0)
        say(f'  {v}: interesting {p0["pos"]} of {len(sc_by[v])} scored rows; worth showing {p0["worth"]}; trivial '
            f'{p0["trivial_kept"]}')
        say('      T  kept  precision  recall     F1  weighted P/R  trivial kept  worth showing lost  judged false kept')
        for T in show:
            p = curve_point(sc_by[v], T)
            say(f'   {T:5.2f}  {p["kept"]:4d}     {f3(p["precision"]):>6}  {f3(p["recall"]):>6}  {f3(p["f1"]):>6}  '
                f'{f3(p["precision_w"])}/{f3(p["recall_w"])}  {p["trivial_kept"]:12d}  {p["worth_lost"]:18d}  {p["false_kept"]:17d}')
    p25 = curve_point(sc_by['pooled_llm'], IC_MIN); p0 = curve_point(sc_by['pooled_llm'], 0)
    put('curve', 'pooled_llm at 0: kept; precision; trivial kept; closure-weighted trivial share',
        f"{p0['kept']}; {f3(p0['precision'])}; {p0['trivial_kept']}; {f3(p0['trivial_share_w'])}")
    put('curve', 'pooled_llm at 2.5: kept; precision; recall; trivial kept; worth lost; false kept; closure-weighted trivial share',
        f"{p25['kept']}; {f3(p25['precision'])}; {f3(p25['recall'])}; {p25['trivial_kept']}; {p25['worth_lost']}; "
        f"{p25['false_kept']}; {f3(p25['trivial_share_w'])}")
    p24 = curve_point(sc_by['pooled_llm'], 2.4)
    put('curve', 'pooled_llm at 2.4: kept; precision; recall; trivial kept; worth lost; false kept; closure-weighted trivial share',
        f"{p24['kept']}; {f3(p24['precision'])}; {f3(p24['recall'])}; {p24['trivial_kept']}; {p24['worth_lost']}; "
        f"{p24['false_kept']}; {f3(p24['trivial_share_w'])}")
    HEAD['trivial_removed_of_total_at_2.5_llm'] = f"{p25['trivial_removed']}/{p0['trivial_kept']}"
    HEAD['precision_0_2.5_2.4_llm'] = f"{f3(p0['precision'])}/{f3(p25['precision'])}/{f3(p24['precision'])}"
    HEAD['trivial_share_w_0_2.5_2.4_llm'] = f"{f3(p0['trivial_share_w'])}/{f3(p25['trivial_share_w'])}/{f3(p24['trivial_share_w'])}"

    # ---- 4. is 2.5 a sensible point?
    say('\n4. Is 2.5 a sensible point?')
    for v in order:
        sc = sc_by[v]; m = km[v]
        rng = random.Random(20261030 + sum(map(ord, v)))   # one stream per view: adding Dan does not move the LLM numbers
        if m is None:
            say(f'  {v}: too few rated rows ({len(sc)}) or no interesting row; skipped'); continue
        bt, bf = best_f1(sc, ts)
        near = [T for T in ts if (lambda q: q['f1'] is not None and q['f1'] >= bf - 0.05)(curve_point(sc, T))]
        yj = max(ts, key=lambda T: (curve_point(sc, T)['youden'] or -9))
        sr = scorer_rule(sc, ts)
        say(f'  {v}: F1 at 2.5 = {f3(m["f1_25"])}; best F1 = {f3(bf)} at T = {bt}; T within 0.05 of best F1: '
            f'{near[0]} to {near[-1]}; best Youden J at T = {yj}; scorer rule (most trivial removed, at most one worth-'
            f'showing row lost): T = {sr[0]}; highest T losing nothing worth showing: {m["safe_T"]}')
        put('threshold', f'{v}: F1 at 2.5; best F1 (T); T within 0.05 of best; Youden T; scorer-rule T; safe T',
            f'{f3(m["f1_25"])}; {f3(bf)} ({",".join(map(str, bt))}); {near[0]}-{near[-1]}; {yj}; {sr[0]}; {m["safe_T"]}')
        if v in ('pooled_llm', 'pooled_all', 'dan'):
            bs = []
            for _ in range(NBOOT):
                s = [sc[rng.randrange(len(sc))] for _ in sc]
                b, _ = best_f1(s, ts)
                if b: bs.append(min(b))
            bs.sort()
            lo, med, hi = bs[int(0.05 * len(bs))], bs[len(bs) // 2], bs[int(0.95 * len(bs)) - 1]
            share = sum(2.25 <= b <= 2.75 for b in bs) / len(bs)
            say(f'    bootstrap ({NBOOT} resamples) of the best-F1 T: median {med}, 90% range {lo} to {hi}; '
                f'{pcts(share)} of resamples put it within 0.25 of 2.5')
            put('threshold', f'{v}: bootstrap best-F1 T median; 90% range; share within 0.25 of 2.5', f'{med}; {lo}-{hi}; {pcts(share)}')
    m = km['pooled_llm']
    HEAD.update({'scorer_T_llm': m['scorer_T'], 'safe_T_llm': m['safe_T'], 'best_f1_T_llm': m['best_f1_T'],
                 'f1_at_2.5_llm': round(m['f1_25'], 3), 'worth_llm': m['worth'], 'interesting_and_true_llm': m['interesting_and_true']})
    sc = sc_by[pooled]
    base_t = scorer_rule(sc, ts)[0]
    moves = []
    for r in [r for r in sc if is_worth(r)]:
        t2 = scorer_rule([dict(x, lvl=1.0) if x['id'] == r['id'] else x for x in sc], ts)[0]
        moves.append(f"{r['id']} (IC {r['ic']:.2f}) -> {t2}")
    say(f'  scorer rule on {pooled} gives T = {base_t}. If one worth-showing row were rated 1 instead: ' + '; '.join(moves))
    put('threshold', f'{pooled}: scorer-rule T if one worth-showing row is demoted', '; '.join(moves))

    # exact cut points (review fix): the same rules on every sheet IC value, not only on the 0.25 grid
    cps = cut_points(rows)
    say(f'  Exact cut points ({len(cps)} candidates: the sheet IC values; T = x stands for the interval up to x):')
    for v in order:
        m = km[v]
        if m is None: continue
        say(f"    {v:<10}: scorer rule {interval(m['scorer_T_exact'], cps)} (removes {m['scorer_removed_exact']} trivial); "
            f"plateau {m['plateau']} (2.5 in it: {'yes' if m['plateau_has_2.5'] else 'no'}); "
            f"highest T losing nothing worth showing {interval(m['safe_T_exact'], cps)}; best F1 {interval(m['best_f1_T_exact'], cps)}")
        put('threshold', f'{v}: exact cut points: plateau; 2.5 in plateau', f"{m['plateau']}; {m['plateau_has_2.5']}")
        put('threshold', f'{v}: exact cut points: scorer-rule T; trivial removed; safe T; best-F1 T',
            f"{interval(m['scorer_T_exact'], cps)}; {m['scorer_removed_exact']}; {interval(m['safe_T_exact'], cps)}; "
            f"{interval(m['best_f1_T_exact'], cps)}")
    for v in ['pooled_llm'] + ([pooled] if pooled != 'pooled_llm' else []):
        sv = sc_by[v]
        bx = scorer_rule(sv, cps)[0]
        xmoves = []
        for r in [r for r in sv if is_worth(r)]:
            t2 = scorer_rule([dict(x, lvl=1.0) if x['id'] == r['id'] else x for x in sv], cps)[0]
            xmoves.append(f"{r['id']} -> {t2}")
        say(f'    {v}: exact scorer rule {bx}; if one worth-showing row were rated 1 instead: ' + '; '.join(xmoves))
        put('threshold', f'{v}: exact scorer-rule T if one worth-showing row is demoted', '; '.join(xmoves))
        if v == 'pooled_llm':   # review, 2026-10-31: the ceiling rows R031 and R089 demoted together
            dem = [dict(x, lvl=1.0) if x['id'] in ('R031', 'R089') else x for x in sv]
            pdem = plateau_str(plateau(dem, cps), cps)
            say(f'    {v}: if R031 and R089 (blood vessel, the ceiling) were both rated 1: plateau {pdem}')
            put('threshold', f'{v}: plateau if R031 and R089 are both demoted', pdem)
            HEAD['plateau_if_r031_r089_demoted_llm'] = pdem
        rng = random.Random(20261031)
        bs = []
        for _ in range(NBOOT):
            s = [sv[rng.randrange(len(sv))] for _ in sv]
            t = scorer_rule(s, cps)
            if t: bs.append(t[0])
        bs.sort()
        share_x = sum(b == bx for b in bs) / len(bs)
        say(f'    {v}: bootstrap ({NBOOT} resamples) of the exact scorer-rule T: median {bs[len(bs) // 2]}; '
            f'{pcts(share_x)} land in {interval(bx, cps)}; 90% range {bs[int(0.05 * len(bs))]} to {bs[int(0.95 * len(bs)) - 1]}')
        put('threshold', f'{v}: bootstrap exact scorer-rule T: median; share in the modal interval; 90% range',
            f'{bs[len(bs) // 2]}; {pcts(share_x)}; {bs[int(0.05 * len(bs))]}-{bs[int(0.95 * len(bs)) - 1]}')
        rng = random.Random(20261031); bg = collections.Counter()
        for _ in range(NBOOT):
            s = [sv[rng.randrange(len(sv))] for _ in sv]
            t = scorer_rule(s, ts)
            if t: bg[t[0]] += 1
        say(f'    {v}: the same bootstrap on the 0.25 grid: ' + ', '.join(f'{k} {pcts(n / NBOOT)}' for k, n in bg.most_common(3)))
        put('threshold', f'{v}: bootstrap grid scorer-rule T, top 3', ', '.join(f'{k} {pcts(n / NBOOT)}' for k, n in bg.most_common(3)))
        if v == 'pooled_llm':
            HEAD['scorer_T_exact_llm'] = bx; HEAD['scorer_interval_exact_llm'] = interval(bx, cps)
            HEAD['scorer_exact_stable_to_one_row_llm'] = all(x.endswith(f'-> {bx}') for x in xmoves)
            HEAD['scorer_exact_boot_share_llm'] = round(share_x, 2)
    m = km['pooled_llm']
    HEAD.update({'safe_T_exact_llm': m['safe_T_exact'], 'best_f1_T_exact_llm': m['best_f1_T_exact'],
                 'scorer_removed_exact_llm': m['scorer_removed_exact'],
                 'plateau_llm': f"{m['plateau']}; 2.5 in it {m['plateau_has_2.5']}; 2.4 in it {m['plateau_has_2.4']}"})
    band_rows = sorted([r for r in sc if 2.0 <= r['ic'] < 3.0], key=lambda r: r['ic'])
    say(f'  rows with IC from 2 to 3 ({len(band_rows)}), in IC order, {pooled} mean (* = interesting, x = judged false):')
    say('    ' + ' '.join(f'{r["ic"]:.2f}:{r["lvl"]:.1f}{"*" if is_int(r["lvl"]) else ""}{"x" if r["truth"] == "no" else ""}' for r in band_rows))
    below = [r for r in band_rows if r['ic'] < IC_MIN]; above = [r for r in band_rows if r['ic'] >= IC_MIN]
    mb = statistics.mean(r['lvl'] for r in below); ma = statistics.mean(r['lvl'] for r in above)
    say(f'    mean rating just below 2.5 (2 to 2.5, n={len(below)}): {mb:.2f}; just above (2.5 to 3, n={len(above)}): {ma:.2f}')
    put('threshold', f'{pooled} mean rating, IC 2 to 2.5 against 2.5 to 3', f'{mb:.2f} (n={len(below)}) against {ma:.2f} (n={len(above)})')

    # ---- 5. truth
    say('\n5. Truth: IC does not judge it')
    for v in order:
        lab = labels(rows, views[v])
        fl = [r for r in lab if r['truth'] == 'no']; tr = [r for r in lab if r['truth'] == 'yes']
        k = sum(r['verdict'] == 'kept' for r in fl); d = sum(r['verdict'] == 'dropped' for r in fl); u = sum(r['verdict'] == 'unjudged' for r in fl)
        a = auc([r['ic'] for r in tr if r['ic'] is not None], [r['ic'] for r in fl if r['ic'] is not None])
        mf = statistics.mean(r['lvl'] for r in fl) if fl else None; mt = statistics.mean(r['lvl'] for r in tr) if tr else None
        say(f'  {v}: judged false {len(fl)}: kept at 2.5 {k}, dropped {d}, unjudged {u}. AUC of IC for true against false: '
            f'{f3(a)} (0.5 = IC blind to truth; under 0.5 = false facts score higher). Mean interesting: false {f3(mf)}, true {f3(mt)}')
        put('truth', f'{v}: judged false; kept/dropped/unjudged at 2.5; AUC of IC true vs false; mean interesting false vs true',
            f'{len(fl)}; {k}/{d}/{u}; {f3(a)}; {f3(mf)} vs {f3(mt)}')
        if v == 'pooled_llm': HEAD['false_kept_llm'] = k; HEAD['judged_false_llm'] = len(fl)
    any_no = [r for r in rows if any(ratings[n].get(r['id'], (0, ''))[1] == 'no' for n in llm)]
    say(f'  any LLM rater says false: {len(any_no)} rows; kept at 2.5: {sum(r["verdict"] == "kept" for r in any_no)}')
    put('truth', 'rows any LLM rater calls false; of those kept at 2.5', f'{len(any_no)}; {sum(r["verdict"] == "kept" for r in any_no)}')
    threes = [(n, i) for n in raters for i, (l, t) in ratings[n].items() if l == 3]
    say(f'  ratings of 3 (all raters): {len(threes)}; the same rater called it false: '
        f'{sum(ratings[n][i][1] == "no" for n, i in threes)}, unsure: {sum(ratings[n][i][1] == "unsure" for n, i in threes)}')
    put('truth', 'ratings of 3; same rater says false; unsure', f'{len(threes)}; {sum(ratings[n][i][1] == "no" for n, i in threes)}; '
        f'{sum(ratings[n][i][1] == "unsure" for n, i in threes)}')
    lab = labels(rows, views[pooled])
    lo, hi = boot_auc([r for r in lab if r['ic'] is not None], lambda r: r['ic'], 11, 'true')
    say(f'  {pooled}: AUC of IC for true against false, 90% bootstrap interval {f3(lo)} to {f3(hi)}')
    put('truth', f'{pooled}: AUC of IC true vs false, 90% interval', f'{f3(lo)}-{f3(hi)}')
    pint = [r for r in lab if is_int(r['lvl'])]
    say(f'  {pooled}: the rows rated interesting (mean 2 or more), by IC:')
    for r in sorted(pint, key=lambda r: -(r['ic'] if r['ic'] is not None else 99)):
        icx = 'none ' if r['ic'] is None else f"{r['ic']:5.2f}"
        say(f"    {r['id']}  IC {icx}  {r['verdict']:<8}  mean {r['lvl']:.2f}  truth {r['truth']:<6}  {r['fact'][:90]}")
    say(f'  interesting rows: {len(pint)}; judged false {sum(r["truth"] == "no" for r in pint)}; unsure '
        f'{sum(r["truth"] == "unsure" for r in pint)}; judged true {sum(r["truth"] == "yes" for r in pint)}')
    put('truth', f'{pooled}: interesting rows; judged false; unsure; true',
        f'{len(pint)}; {sum(r["truth"] == "no" for r in pint)}; {sum(r["truth"] == "unsure" for r in pint)}; '
        f'{sum(r["truth"] == "yes" for r in pint)}')
    pli = [r for r in labels(rows, views['pooled_llm']) if is_int(r['lvl'])]
    HEAD['interesting_n_false_unsure_true_llm'] = (f"{len(pli)}/{sum(r['truth'] == 'no' for r in pli)}/"
                                                   f"{sum(r['truth'] == 'unsure' for r in pli)}/{sum(r['truth'] == 'yes' for r in pli)}")
    # Review, 2026-10-31: the core's own strength. closure.py gives each derived fact a belief that mirrors
    # Derivation.opinionWith (a logical step takes the weaker premise; an effect chain multiplies). Can it see the false
    # rows or the interesting ones? Truth as the marks use it: the checked source, else the LLM pool.
    bel_of = {f['fact']: f['belief'] for f in load_closure()}
    plm = views['pooled_llm']
    bel = {r['id']: bel_of.get(r['formal']) for r in rows}
    tmk = {r['id']: SOURCE_TRUTH.get(r['id'], plm[r['id']][1]) for r in rows}
    bt = [bel[i] for i in bel if bel[i] is not None and tmk[i] == 'yes']
    bf = [bel[i] for i in bel if bel[i] is not None and tmk[i] == 'no']
    bi = [bel[r['id']] for r in rows if bel[r['id']] is not None and is_int(plm[r['id']][0])]
    bo = [bel[r['id']] for r in rows if bel[r['id']] is not None and not is_int(plm[r['id']][0])]
    bvals = collections.Counter(round(b, 3) for b in bel.values() if b is not None)
    bfl = sorted(i for i in bel if tmk[i] == 'no' and bel[i] is not None and bel[i] < 0.8)
    say(f"  the core's belief (closure.py, as Derivation.opinionWith): values on the sheet "
        + ', '.join(f'{b} x{n}' for b, n in sorted(bvals.items(), reverse=True))
        + f"; AUC for true ({len(bt)}) above false ({len(bf)}): {f3(auc(bt, bf))}; false rows under 0.8: {', '.join(bfl) or 'none'}; "
        f"AUC for interesting above the rest (pooled_llm): {f3(auc(bi, bo))}")
    put('truth', "core belief: values on the sheet; AUC true above false; false rows under 0.8; AUC interesting above rest",
        ', '.join(f'{b} x{n}' for b, n in sorted(bvals.items(), reverse=True)) + f'; {f3(auc(bt, bf))}; {",".join(bfl)}; {f3(auc(bi, bo))}')
    HEAD['core_belief_values_auc_tf_auc_int'] = (', '.join(f'{b} x{n}' for b, n in sorted(bvals.items(), reverse=True))
                                                 + f'; {f3(auc(bt, bf))}; {f3(auc(bi, bo))}')

    # ---- 6. alternatives
    say('\n6. Alternatives on the same ratings (AUC; 0.5 = chance; 90% bootstrap interval)')
    alt = [('feature', 'option', 'what', 'view', 'n', 'auc_interesting_2plus', 'ci90_low', 'ci90_high',
            'auc_not_trivial', 'nt_ci90_low', 'nt_ci90_high', 'auc_true_vs_false')]
    for x, (code, opt, what, f) in enumerate(FEATS):
        for v in order:
            lab = labels(rows, views[v])
            a2, n = feat_auc(lab, f, 'interesting'); a1, _ = feat_auc(lab, f, 'not trivial'); at, _ = feat_auc(lab, f, 'true')
            lo = hi = lo1 = hi1 = None
            if v == pooled:
                lo, hi = boot_auc(lab, f, 7 + x); lo1, hi1 = boot_auc(lab, f, 107 + x, 'not trivial')
                say(f'  {opt:<3} {what:<52} n={n:3d}  interesting {f3(a2)} [{f3(lo)}, {f3(hi)}]  not trivial {f3(a1)} '
                    f'[{f3(lo1)}, {f3(hi1)}]  true vs false {f3(at)}')
                put('alternatives', f'{pooled} AUC {code} ({opt}): interesting [90% CI]; not trivial [90% CI]; true vs false; n',
                    f'{f3(a2)} [{f3(lo)}, {f3(hi)}]; {f3(a1)} [{f3(lo1)}, {f3(hi1)}]; {f3(at)}; {n}')
            alt.append((code, opt, what, v, n, f3(a2), f3(lo), f3(hi), f3(a1), f3(lo1), f3(hi1), f3(at)))
            if v == 'pooled_llm' and code in ('ic', 'pm', 'gain', 'no_flag', 'depth', 'n_premises', 'onto_dist'):
                HEAD[f'auc_{code}_llm'] = round(a2, 3); HEAD[f'auc_nt_{code}_llm'] = round(a1, 3)
    say('  per rater, AUC for interesting (2 or more) / not trivial (1 or more):')
    for code, opt, what, f in FEATS:
        vals = []
        for v in raters:
            lab = labels(rows, views[v])
            vals.append(f"{v} {f3(feat_auc(lab, f, 'interesting')[0])}/{f3(feat_auc(lab, f, 'not trivial')[0])}")
        say(f'    {code:<13} ' + '  '.join(vals))
    write(f'{out_dir}/analysis_alternatives.tsv', alt)

    # ---- 7. whole filters
    say(f'\n7. Whole filters on the {n_scored} rows with an IC (precision = share kept that are interesting)')
    RULES = [('keep all', '-', lambda r: True),
             ('A: IC >= 2.5 (today)', 'A', lambda r: r['ic'] >= IC_MIN),
             ('A: IC >= 2.25', 'A', lambda r: r['ic'] >= 2.25),
             ('A: IC >= 2.4 (inside the exact interval)', 'A', lambda r: r['ic'] >= 2.4),
             ('A: IC >= 3.25', 'A', lambda r: r['ic'] >= 3.25),
             ('B: path_min >= 2.5', 'B', lambda r: r['pm'] >= IC_MIN),
             ('C1: gain >= 0 (missing gain kept)', 'C1', lambda r: r['gain'] is None or r['gain'] >= 0),
             ('C2: no structural flag', 'C2', lambda r: not r['flag']),
             ('C2 then A: no flag and IC >= 2.5', 'C2+A', lambda r: not r['flag'] and r['ic'] >= IC_MIN),
             ('C2 then A: no flag and IC >= 2.25', 'C2+A', lambda r: not r['flag'] and r['ic'] >= 2.25),
             ('C2 then A: no flag and IC >= 2.4', 'C2+A', lambda r: not r['flag'] and r['ic'] >= 2.4),
             ('C2 then A: no flag and IC >= 2.0', 'C2+A', lambda r: not r['flag'] and r['ic'] >= 2.0),
             ('E: depth 1 only', 'E', lambda r: r['depth'] == 1),
             ('E then A: depth 1 and IC >= 2.5', 'E+A', lambda r: r['depth'] == 1 and r['ic'] >= IC_MIN)]
    rt = [('rule', 'option', 'view', 'n', 'kept', 'precision', 'recall', 'f1', 'trivial_kept', 'trivial_removed',
           'worth_showing_lost', 'judged_false_kept', 'precision_closure_weighted')]
    say('    rule                                   view         kept   prec  recall     F1  trivial kept  worth lost  false kept')
    for name, opt, keep in RULES:
        for v in order:
            sc = sc_by[v]
            kept = [r for r in sc if keep(r)]; rem = [r for r in sc if not keep(r)]
            pos = [r for r in sc if is_int(r['lvl'])]
            tp = sum(is_int(r['lvl']) for r in kept)
            p, rc = pct(tp, len(kept)), pct(tp, len(pos))
            f1 = None if not p or not rc else 2 * p * rc / (p + rc)
            pw = pct(sum(r['w'] for r in kept if is_int(r['lvl'])), sum(r['w'] for r in kept))
            row = (name, opt, v, len(sc), len(kept), f3(p), f3(rc), f3(f1), sum(is_triv(r['lvl']) for r in kept),
                   sum(is_triv(r['lvl']) for r in rem), sum(is_worth(r) for r in rem), sum(r['truth'] == 'no' for r in kept), f3(pw))
            rt.append(row)
            if v == pooled:
                say(f'    {name:<38} {v:<11} {len(kept):4d}  {f3(p)}  {f3(rc)}  {f3(f1)}  {row[8]:12d}  {row[10]:10d}  {row[11]:10d}')
                put('rules', f'{pooled} {name}: kept; precision; recall; F1; trivial kept; worth lost; false kept',
                    f'{len(kept)}; {f3(p)}; {f3(rc)}; {f3(f1)}; {row[8]}; {row[10]}; {row[11]}')
            if v == 'pooled_llm' and name.startswith('C2 then A: no flag and IC >= 2.5'):
                HEAD['c2a_trivial_kept_llm'] = row[8]; HEAD['c2a_worth_lost_llm'] = row[10]
            if v == 'pooled_llm':
                tag = {'A: IC >= 2.5 (today)': 'a25', 'A: IC >= 2.4 (inside the exact interval)': 'a24', 'C2 then A: no flag and IC >= 2.25': 'c2a225',
                       'C2 then A: no flag and IC >= 2.4': 'c2a24', 'C2: no structural flag': 'c2'}.get(name)
                if tag: HEAD[f'{tag}_kept_trivial_worthlost_falsekept_llm'] = f'{len(kept)}/{row[8]}/{row[10]}/{row[11]}'
    write(f'{out_dir}/analysis_rules.tsv', rt)
    lab = labels(rows, views[pooled])
    fl = [r for r in lab if r['flag']]
    say(f'  rows with a structural flag: {len(fl)}; trivial {sum(is_triv(r["lvl"]) for r in fl)}; interesting '
        f'{sum(is_int(r["lvl"]) for r in fl)}; worth showing {sum(is_worth(r) for r in fl)}')
    for nm, key in (('restatement', 'restates'), ('weakening', 'weak'), ('entailed', 'entailed')):
        g = [r for r in lab if r[key]]
        say(f'    {nm:<12} {len(g):3d} rows; trivial {sum(is_triv(r["lvl"]) for r in g)}; mean {statistics.mean(r["lvl"] for r in g):.2f}; '
            f'judged false {sum(r["truth"] == "no" for r in g)}')
    put('rules', f'{pooled}: flagged rows; trivial; interesting; worth showing',
        f'{len(fl)}; {sum(is_triv(r["lvl"]) for r in fl)}; {sum(is_int(r["lvl"]) for r in fl)}; {sum(is_worth(r) for r in fl)}')
    kf = [r for r in fl if r['verdict'] == 'kept']
    say(f'  flagged rows the 2.5 cut keeps: {len(kf)}; of those trivial: {sum(is_triv(r["lvl"]) for r in kf)}')
    put('rules', f'{pooled}: flagged rows kept at 2.5; of those trivial', f'{len(kf)}; {sum(is_triv(r["lvl"]) for r in kf)}')
    fll = [r for r in labels(rows, views['pooled_llm']) if r['flag']]
    HEAD['flagged_trivial_worth_llm'] = f"{len(fll)}/{sum(is_triv(r['lvl']) for r in fll)}/{sum(is_worth(r) for r in fll)}"
    HEAD['flag_kinds_n_trivial_llm'] = '; '.join(
        f"{nm} {sum(r[key] for r in fll)}/{sum(r[key] and is_triv(r['lvl']) for r in fll)}"
        for nm, key in (('restatement', 'restates'), ('weakening', 'weak'), ('entailed', 'entailed')))

    # ---- 8. per-row table and sheet cases
    head = ['id', 'fact', 'ic', 'path_min', 'verdict_2.5', 'rule', 'depth', 'restates', 'weakening', 'entailed', 'gain', 'old_llm_label']
    for n in raters: head += [f'{n}_interesting', f'{n}_true']
    head += ['pooled_llm_mean', 'pooled_llm_truth'] + (['pooled_all_mean', 'pooled_all_truth'] if dan_p else [])
    out = [tuple(head)]
    pl = views['pooled_llm']
    for r in rows:
        x = [r['id'], r['fact'], '' if r['ic'] is None else r['ic'], r['pm'], r['verdict'], r['rule'], r['depth'], r['restates'],
             r['weak'], r['entailed'], '' if r['gain'] is None else r['gain'], r['old']]
        for n in raters:
            g = ratings[n].get(r['id']); x += [g[0], g[1]] if g else ['', '']
        x += [f'{pl[r["id"]][0]:.2f}', pl[r['id']][1]]
        if dan_p:
            pa = views['pooled_all']; x += [f'{pa[r["id"]][0]:.2f}', pa[r['id']][1]]
        out.append(tuple(x))
    write(f'{out_dir}/analysis_rows.tsv', out)

    say(f'\n8. Stress cases on the sheet (near the cut: IC 2 to 3; any LLM rater says false; no IC). Marks use the checked '
        f'source where there is one ({len(SOURCE_TRUTH)} rows), else the LLM pool.')
    dif = [f'{i} (source {t}, pool {pl[i][1]})' for i, t in sorted(SOURCE_TRUTH.items()) if pl[i][1] != t]
    say('  checked source differs from the LLM pool on: ' + ('; '.join(dif) or 'none'))
    put('cases', 'checked source differs from the LLM pool on', '; '.join(dif) or 'none')
    HEAD['source_vs_pool_differs'] = ','.join(sorted(i for i, t in SOURCE_TRUTH.items() if pl[i][1] != t))
    ch = ['id', 'probe', 'fact', 'terms', 'ic', 'verdict_2.5', 'llm1', 'llm2', 'llm3'] + (['dan'] if dan_p else []) + \
         ['llm_mean', 'llm_truth', 'truth_for_mark', 'correct_conclusion', 'source', 'mark_llm'] + (['mark_dan'] if dan_p else [])
    cases = [tuple(ch)]
    tally = collections.Counter(); by_probe = collections.defaultdict(collections.Counter); pass_kind = collections.Counter()
    for r in rows:
        probes = []
        if r['ic'] is not None and 2.0 <= r['ic'] < 3.0: probes.append('near the cut')
        if any(ratings[n].get(r['id'], (0, ''))[1] == 'no' for n in llm): probes.append('rated untrue')
        if r['ic'] is None: probes.append('no IC')
        if not probes: continue
        m, t = pl[r['id']]
        tm = SOURCE_TRUTH.get(r['id'], t)
        exp, mk = expected_and_mark(m, tm, r['verdict'])
        tally[mk] += 1
        if mk == 'PASS': pass_kind['either' if exp.startswith('either') else 'right call'] += 1
        for pr_ in probes: by_probe[pr_][mk] += 1
        rr = lambda n: '/'.join(map(str, ratings[n][r['id']])) if r['id'] in ratings[n] else ''
        src = SOURCES.get(r['id'], 'LLM rating pool (a stand-in for Dan); premise sentences on the sheet')
        line = [r['id'], '; '.join(probes), r['fact'], r['terms'], '' if r['ic'] is None else r['ic'], r['verdict'],
                rr('llm1'), rr('llm2'), rr('llm3')] + ([rr('dan')] if dan_p else []) + \
               [f'{m:.2f}', t, tm + (' (checked source)' if r['id'] in SOURCE_TRUTH else ' (LLM pool)'), exp, src, mk]
        if dan_p:
            g = ratings['dan'].get(r['id'])
            line.append(expected_and_mark(g[0], g[1], r['verdict'])[1] if g else '')
        cases.append(tuple(line))
        pin = PINS.get(r['id'])
        got = (r['verdict'], None if r['ic'] is None else round(r['ic'], 3), mk)
        if pin is None or pin != got: flipped.append(f'{r["id"]}: pinned {pin}, observed {got}')
    write(f'{out_dir}/sheet_cases.tsv', cases)
    say(f'  {len(cases) - 1} cases; marks: ' + ', '.join(f'{k} {tally[k]}' for k in ('PASS', 'FAIL', 'SILENT', 'INEXPRESSIBLE')))
    for pr_ in ('near the cut', 'rated untrue', 'no IC'):
        say(f'    {pr_:<13} {sum(by_probe[pr_].values()):3d}: ' + ', '.join(f'{k} {by_probe[pr_][k]}' for k in ('PASS', 'FAIL', 'SILENT')))
        put('cases', f'{pr_}: n; PASS/FAIL/SILENT', f"{sum(by_probe[pr_].values())}; {by_probe[pr_]['PASS']}/{by_probe[pr_]['FAIL']}/{by_probe[pr_]['SILENT']}")
    put('cases', 'sheet cases; PASS/FAIL/SILENT/INEXPRESSIBLE (checked source, else LLM pool)',
        f"{len(cases) - 1}; {tally['PASS']}/{tally['FAIL']}/{tally['SILENT']}/{tally['INEXPRESSIBLE']}")
    say(f"  PASS by kind: right call {pass_kind['right call']} (trivial and dropped, or worth showing and kept); either "
        f"{pass_kind['either']} (a middle fact, mean 0.5 to 2: any verdict passes)")
    put('cases', 'PASS by kind: right call; either (middle fact)', f"{pass_kind['right call']}; {pass_kind['either']}")
    HEAD['case_marks_llm'] = f"{tally['PASS']}/{tally['FAIL']}/{tally['SILENT']}/{tally['INEXPRESSIBLE']}"
    HEAD['case_pass_right_either_llm'] = f"{pass_kind['right call']}/{pass_kind['either']}"
    # Review, 2026-10-31: which FAILs a cut could ever avoid, and the cut's score on its own job.
    ci = {c: ch.index(c) for c in ('verdict_2.5', 'correct_conclusion', 'mark_llm')}
    fk = collections.Counter()
    for c in cases[1:]:
        if c[ci['mark_llm']] != 'FAIL': continue
        e = c[ci['correct_conclusion']]
        fk['false kept' if e == 'flag as false' else 'trivial kept' if e.startswith('drop') else 'worth showing lost'] += 1
    job = [c for c in cases[1:] if c[ci['verdict_2.5']] != 'unjudged' and c[ci['correct_conclusion']].startswith(('drop', 'keep'))]
    jr = sum(c[ci['mark_llm']] == 'PASS' for c in job)
    say(f"  FAIL by kind: false and kept {fk['false kept']} (no cut can flag these); trivial and kept {fk['trivial kept']}; "
        f"worth showing and dropped {fk['worth showing lost']}. On the job a cut can do (a trivial or worth-showing fact with "
        f"an IC): right on {jr} of {len(job)}")
    put('cases', 'FAIL by kind: false kept; trivial kept; worth showing lost. Cut right on its own job',
        f"{fk['false kept']}/{fk['trivial kept']}/{fk['worth showing lost']}; {jr} of {len(job)}")
    HEAD['case_fail_kinds_llm'] = f"{fk['false kept']}/{fk['trivial kept']}/{fk['worth showing lost']}"
    HEAD['case_cut_job_right_llm'] = f'{jr}/{len(job)}'
    sf = [r for r in rows if SOURCE_TRUTH.get(r['id']) == 'no']
    sfv = collections.Counter(r['verdict'] for r in sf)
    say(f"  false by checked source: {len(sf)} rows; kept at 2.5 {sfv['kept']}, dropped {sfv['dropped']}, unjudged {sfv['unjudged']}")
    put('cases', 'false by checked source: n; kept/dropped/unjudged at 2.5', f"{len(sf)}; {sfv['kept']}/{sfv['dropped']}/{sfv['unjudged']}")
    HEAD['source_false_kept_dropped_unjudged'] = f"{len(sf)}: {sfv['kept']}/{sfv['dropped']}/{sfv['unjudged']}"
    b24 = sorted([r for r in rows if r['ic'] is not None and 2.4 <= r['ic'] < IC_MIN], key=lambda r: (r['ic'], r['id']))
    b24s = ', '.join(f"{r['id']} {SOURCE_TRUTH.get(r['id'], pl[r['id']][1])}" for r in b24)
    say(f'  the {len(b24)} rows between 2.4 and 2.5, with the truth the marks use: {b24s}')
    put('cases', 'rows between 2.4 and 2.5: truth the marks use', b24s)
    HEAD['band_2.4_2.5_truth'] = b24s
    fails = [c for c in cases[1:] if c[ch.index('mark_llm')] == 'FAIL']
    say('  FAIL cases: ' + '; '.join(f"{c[0]} ({c[5]}, IC {c[4] if c[4] != '' else 'none'}, {c[ch.index('correct_conclusion')]})" for c in fails))
    if dan_p:
        dt = collections.Counter(c[-1] for c in cases[1:] if c[-1])
        say('  marks from Dan alone: ' + ', '.join(f'{k} {dt[k]}' for k in ('PASS', 'FAIL', 'SILENT')))
        put('cases', 'marks from Dan alone PASS/FAIL/SILENT', f"{dt['PASS']}/{dt['FAIL']}/{dt['SILENT']}")
    extra = set(PINS) - {c[0] for c in cases[1:]}
    flipped += [f'{i}: pinned but no longer a case' for i in sorted(extra)]

    # ---- 9. exit tests that ratings can decide
    say('\n9. Exit tests of the doc\'s experiments, computed from the ratings present')
    et = [('test', 'view', 'measure', 'value', 'passes')]
    for v in [x for x in ('pooled_llm', 'llm1', 'llm2', 'llm3', 'dan', 'pooled_all') if x in views]:
        lab = labels(rows, views[v]); m = km[v]
        fl = [r for r in lab if r['flag']]
        if fl:
            sh = sum(is_triv(r['lvl']) for r in fl) / len(fl); it = sum(is_int(r['lvl']) and r['truth'] == 'yes' for r in fl)
            ok = sh >= 0.8 and it <= 1
            et.append(('X2 flags first', v, f'share of {len(fl)} flagged rows trivial; flagged rows interesting and true', f'{sh:.2f}; {it}', ok))
            say(f'  X2 flags first, {v}: {pcts(sh)} of {len(fl)} flagged rows trivial (need 80%); {it} flagged and interesting and true (need at most 1): {"PASS" if ok else "not met"}')
        if m:
            d1 = m['auc_nt_pm'] - m['auc_nt_ic']; d2 = m['auc_pm'] - m['auc_ic']
            ok = d1 >= 0.05 and d2 >= 0.05
            et.append(('X3 path_min beats ends-min', v, 'AUC difference, not trivial; interesting', f'{d1:+.3f}; {d2:+.3f}', ok))
            say(f'  X3 path_min beats ends-min by 0.05, {v}: not trivial {d1:+.3f}, interesting {d2:+.3f}: {"PASS" if ok else "not met"}')
            sc = [r for r in lab if r['ic'] is not None]
            t0 = scorer_rule(sc, ts)[0]
            tm = [scorer_rule([dict(x, lvl=1.0) if x['id'] == r['id'] else x for x in sc], ts)[0] for r in sc if is_worth(r)]
            spread = max([abs(t - t0) for t in tm] or [0])
            cps = cut_points(rows); x0 = scorer_rule(sc, cps)[0]
            xm = [scorer_rule([dict(x, lvl=1.0) if x['id'] == r['id'] else x for x in sc], cps)[0] for r in sc if is_worth(r)]
            xspread = max([abs(t - x0) for t in xm] or [0])
            ok = xspread < 0.25
            et.append(('X4 cut is stable', v, 'largest move of the scorer-rule T (exact cut points) when one worth-showing row is demoted', f'{xspread:.3f}', ok))
            et.append(('X4 on the 0.25 grid (for comparison)', v, 'the same on the 0.25 grid', f'{spread:.2f}', spread < 0.25))
            say(f'  X4 cut stable to one row, {v}: largest move {xspread:.3f} on exact cut points (need under 0.25): '
                f'{"PASS" if ok else "not met"}; on the 0.25 grid {spread:.2f}: {"PASS" if spread < 0.25 else "not met"}')
            if v == 'pooled_llm': HEAD['x4_exact_grid_llm'] = f'{xspread:.3f}/{spread:.2f}'
            ok = m['auc_nt_ic'] is not None and m['auc_nt_ic'] >= 0.75
            et.append(('X5 IC separates trivia', v, 'AUC of IC, not trivial', f3(m['auc_nt_ic']), ok))
            say(f'  X5 IC separates trivia (AUC 0.75 or more), {v}: {f3(m["auc_nt_ic"])}: {"PASS" if ok else "not met"}')
    if dan_p:
        common = [i for i in ratings['dan'] if i in views['pooled_llm']]
        wk = weighted_kappa([ratings['dan'][i][0] for i in common], [min(3, max(0, round(views['pooled_llm'][i][0]))) for i in common])
        ok = len(common) >= 90 and wk is not None and wk >= 0.6
        et.append(('X1 Dan agrees with the stand-in', 'dan', 'rows rated; weighted kappa with the rounded LLM mean', f'{len(common)}; {f3(wk)}', ok))
        say(f'  X1 Dan agrees with the stand-in (90+ rows, weighted kappa 0.6 or more): {len(common)} rows, {f3(wk)}: {"PASS" if ok else "not met"}')
    else:
        say('  X1 Dan agrees with the stand-in: needs rating_dan.tsv')
    if x7:
        et.append(('X7 stand-in stable run to run', 'llm r2 vs r3', 'per-rater weighted kappa; same exact scorer interval',
                   '/'.join(f3(w) for w in x7[0]) + f'; {x7[1]}', x7[2]))
        say(f"  X7 stand-in stable run to run (weighted kappa 0.8+ per rater, round 2 against 3, and the same exact scorer "
            f"interval): kappa {', '.join(f3(w) for w in x7[0])}; same interval: {'yes' if x7[1] else 'no'}: {'PASS' if x7[2] else 'not met'}")
    write(f'{out_dir}/analysis_exit_tests.tsv', et)

    # ---- 10. which terms decide the cut
    facts = load_closure(); ic, tab = load_ic()
    by = collections.Counter()
    for f in facts:
        s = score(f['k'], ic)
        if s is None or not (2.0 <= s < 3.0): continue
        e = min(ends(f['k']), key=lambda x: ic_of(x, ic)).split('&')[0]
        by[(e, round(s, 3))] += 1
    tt = [('term', 'name', 'ic', 'closure_facts_scored_by_it', 'side_of_2.5')]
    for (e, s), n in sorted(by.items(), key=lambda x: x[0][1]):
        tt.append((e, tab.get(e, {}).get('name', ''), s, n, 'kept' if s >= IC_MIN else 'dropped'))
    write(f'{out_dir}/analysis_terms_near_cut.tsv', tt)
    near = [(e, s, n) for (e, s), n in by.items() if 2.25 <= s < 2.75]
    say(f'\n10. Which terms decide the cut. Closure facts scored 2 to 3: {sum(by.values())}, set by {len(by)} terms. '
        f'From 2.25 to 2.75: {sum(n for _, _, n in near)} facts, set by {len(near)} terms:')
    for e, s, n in sorted(near, key=lambda x: x[1]):
        say(f"    {s:5.3f}  {n:3d} facts  {e} {tab.get(e, {}).get('name', '')}")
    put('terms', 'closure facts scored 2 to 3; terms that set the score; 2.25 to 2.75: facts, terms',
        f'{sum(by.values())}; {len(by)}; {sum(n for _, _, n in near)}, {len(near)}')
    lo_band = [(e, s_, n) for (e, s_), n in by.items() if 2.25 <= s_ < IC_MIN]
    HEAD['closure_facts_terms_2.25_to_2.5'] = f'{sum(n for _, _, n in lo_band)}/{len(lo_band)}'
    # closure-wide verdicts at three cuts, counted as closure.py does: one scored end under T is enough to drop a fact
    bnd = lambda k: min((x for x in (ic_of(c, ic) for c in ends(k)) if x is not None), default=None)
    say('  closure verdicts (closure.py logic: an end with no IC leaves the fact unjudged unless the other end is under T):')
    for T in (2.25, 2.4, IC_MIN):
        kept = sum(1 for f in facts if score(f['k'], ic) is not None and score(f['k'], ic) >= T)
        drop = sum(1 for f in facts if bnd(f['k']) is not None and bnd(f['k']) < T)
        unj = len(facts) - kept - drop
        say(f'    T = {T}: kept {kept}, dropped {drop}, unjudged {unj} (of {len(facts)})')
        put('terms', f'closure at T = {T}: kept; dropped; unjudged', f'{kept}; {drop}; {unj}')
        HEAD[f'closure_kept_dropped_unjudged_{T}'] = f'{kept}/{drop}/{unj}'
    fx = read_tsv(f'{D}/features.tsv')
    kept_fx = [x for x in fx if x['ic'] not in ('', 'None') and float(x['ic']) >= IC_MIN]
    nflag = sum(x['restates'] == 'True' or x['weakening'] == 'True' for x in kept_fx)
    say(f'  kept at 2.5 with a restatement or weakening flag (features.tsv): {nflag} of {len(kept_fx)}')
    HEAD['closure_kept_flagged_2.5'] = f'{nflag}/{len(kept_fx)}'
    byf = {x['fact']: x for x in fx}
    c27 = byf.get('metaphase [GO:0000089] overlaps mitotic phase [GO:0000087]', {})
    c28 = byf.get('metaphase [GO:0000089] part of mitotic phase [GO:0000087]', {})
    fl_of = lambda x: '+'.join(n for n, k in (('restates', 'restates'), ('weakening', 'weakening'), ('entailed', 'entailed')) if x.get(k) == 'True') or 'none'
    say(f'  off-sheet cases the cut cannot express, as C2 flags them: C27 {fl_of(c27)}; C28 {fl_of(c28)}')
    HEAD['c2_flags_c27_c28'] = f'{fl_of(c27)}; {fl_of(c28)}'
    # Review, 2026-10-31: three figures the doc quotes from ic_alternatives.py, which has no pins; recomputed here the
    # same way so that a change to the closure or the IC table flips them.
    kept_c = [f for f in facts if score(f['k'], ic) is not None and score(f['k'], ic) >= IC_MIN]
    pmd = sum(1 for f in kept_c if (lambda x: x is not None and x < IC_MIN)(path_min(f['t'], ic)))
    by_fact = {f['fact']: f for f in facts}
    top = json.load(open('data/search/closure_ic.json'))['facts'][:100]
    chebi = sum(1 for f in top if any(base(c).startswith('CHEBI:') for c in ends(by_fact[f['fact']]['k'])))
    pre = collections.Counter()
    for f in facts:
        if score(f['k'], ic) is not None: continue
        for c in ends(f['k']):
            if ic.get(c, ic.get(base(c))) is None: pre[base(c).split(':')[0]] += 1
    pres = ', '.join(f'{k} {n}' for k, n in pre.most_common())
    say(f'  kept facts that path_min (B) would also drop: {pmd} of {len(kept_c)}; top 100 by IC with a ChEBI end: {chebi}; '
        f'ends with no IC on unscored facts, by ontology: {pres}')
    put('terms', 'kept facts path_min would drop; top 100 by IC with a ChEBI end; ends with no IC, by ontology',
        f'{pmd} of {len(kept_c)}; {chebi}; {pres}')
    HEAD['closure_pm_drop_top100_chebi'] = f'{pmd}/{len(kept_c)}; {chebi}'
    HEAD['closure_unscored_ends_by_prefix'] = pres

    for k, v in HEAD_PINS.items():
        if HEAD.get(k) != v: flipped.append(f'headline {k}: pinned {v!r}, observed {HEAD.get(k)!r}')
    for k in HEAD:
        if k not in HEAD_PINS: flipped.append(f'headline {k}: not pinned, observed {HEAD[k]!r}')
    write(f'{out_dir}/analysis_summary.tsv', [('section', 'item', 'value')] + summ)
    with open(f'{out_dir}/analysis_report.txt', 'w', encoding='utf-8') as fh: fh.write('\n'.join(rep) + '\n')
    if '--print-pins' in sys.argv:
        mi = ch.index('mark_llm')
        print('PINS = {'); [print(f'    {c[0]!r}: ({c[5]!r}, {None if c[4] == "" else round(float(c[4]), 3)!r}, {c[mi]!r}),') for c in cases[1:]]; print('}')
        print('HEAD_PINS =', HEAD)
    if flipped:
        print('PIN FLIPPED:\n  ' + '\n  '.join(flipped)); sys.exit(1)
    print(f'all pins hold ({len(PINS)} cases, {len(HEAD_PINS)} headline numbers)')


if __name__ == '__main__':
    main()
