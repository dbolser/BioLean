"""Program 04: score the mutation test. A detector catches a mutant when it raises a flag the unmutated control did not.

Run from the repo root:  python3 -I scripts/stress/mutants_score.py [--check]
Reads   data/stress/04/mutants.json, lean_typing.tsv, judgements.tsv (hand judgement: is the mutated claim false?)
Writes  data/stress/04/mutants.tsv      one row per control and mutant: what each detector said, the mark
        data/stress/04/catch_rates.tsv  catch rate per error type and detector
--check compares the marks with data/stress/04/expected_marks.tsv and exits 1 on any difference, so a change to BioLean
or to a detector that flips a case shows up. (--freeze writes expected_marks.tsv from the current run.)"""
import json, sys, collections, pathlib

OUT = pathlib.Path('/home/danbolser/Build/BioLean/data/stress/04')
# detector -> (group, label). Groups: runs on statements today (core, script), exists only for holes, data only, new.
DETECTORS = {
    'lean':         ('core',  'Lean elaboration (Rel.accepts, Target kinds)'),
    'taxon_lint':   ('core',  'Statement.taxonConsistent'),
    'clash':        ('script', 'closure rel/notRel clash'),
    'sign':         ('script', 'closure sign clash, off any named loop'),
    'sign_loop':    ('loop',  'closure sign clash on a named feedback loop (known artefact)'),
    'obsolete':     ('holes', 'obsolete term (holes.py screen; Ontology.retired)'),
    'onto_refutes': ('holes', 'ontology refutes is_a/part_of (holes.py)'),
    'kinds':        ('holes', 'is_a across kinds (holes.py)'),
    'mode':         ('holes', 'unseen relation pattern (holes.py modes)'),
    'go_tax':       ('data',  'GO taxon constraints, stated scope'),
    'ub_tax':       ('data',  'UBERON/CL taxon constraints, stated scope'),
    'go_tax_c':     ('data',  'GO taxon constraints, ceiling scope'),
    'ub_tax_c':     ('data',  'UBERON/CL taxon constraints, ceiling scope'),
    'disjoint':     ('data',  'disjoint_from / spatially disjoint'),
    'label':        ('new',   'label lint (text vs label/synonyms)'),
    'sig':          ('proto', 'finer relation signatures (prototype of a core change, option C)'),
}
TODAY = ('lean', 'taxon_lint', 'clash', 'sign')

def flags(r, d, lean):
    if d == 'lean': return {lean.get(r['mid'], ('', ''))[1]} if lean.get(r['mid'], ('',))[0] == 'rejected' else set()
    if d == 'taxon_lint': return set()        # textbook evidence has no taxon: the lint is true for every statement
    if d == 'clash': return set(r.get('new_clash') or [])
    if d == 'sign': return set(r.get('new_sign') or [])
    if d == 'sign_loop': return set(r.get('new_sign_loop') or [])
    if d == 'kinds': return {x for x in r.get('disjoint') or [] if x.startswith('is_a across kinds')}
    if d == 'disjoint': return {x for x in r.get('disjoint') or [] if not x.startswith('is_a across kinds')}
    v = r.get(d)
    if not v: return set()
    return {v} if isinstance(v, str) else set(map(str, v))

def main():
    rows = json.load(open(OUT / 'mutants.json'))
    lean = {}
    for l in open(OUT / 'lean_typing.tsv'):
        if l.startswith('#') or not l.strip(): continue
        mid, res, det = (l.rstrip('\n').split('\t') + [''])[:3]
        lean[mid] = (res, det)
    judge = {}
    jp = OUT / 'judgements.tsv'
    if jp.exists():
        for l in open(jp):
            if l.startswith('#') or not l.strip(): continue
            f = l.rstrip('\n').split('\t'); judge[f[0]] = (f[1], f[2] if len(f) > 2 else '')
    ctrl = {r['base']: r for r in rows if r['op'] == 'E0_control'}
    table, rates = [], collections.defaultdict(lambda: collections.Counter())
    for r in rows:
        c = ctrl[r['base']]
        hit = {}
        for d in DETECTORS:
            fm, fc = flags(r, d, lean), flags(c, d, lean)
            hit[d] = sorted(fm if r['op'] == 'E0_control' else fm - fc)
        j, jwhy = judge.get(r['mid'], ('false' if r['op'] != 'E0_control' else 'true', 'default'))
        today = [d for d in TODAY if hit[d]]
        later = [d for d in DETECTORS if d not in TODAY and DETECTORS[d][0] != 'loop' and hit[d]]
        if r['op'] == 'E0_control':
            # a control is right as written unless judged otherwise (the real errors B43-B45)
            if j == 'true': mark = 'FAIL' if today else 'PASS'
            else: mark = 'PASS' if today else 'SILENT'
        else:
            # equivalent mutants (still true biology) are still annotation errors: the annotation no longer matches the
            # sentence. Marked like the rest, but kept out of the catch rates (mutation-testing convention).
            mark = 'PASS' if today else 'SILENT'
        table.append(dict(mid=r['mid'], base=r['base'], op=r['op'], note=r['note'], key=str(r['key']), loaded=r['loaded'],
                          quant=r.get('quant'), damage=r['damage'], judged=j, judged_why=jwhy, mark=mark,
                          today=today, later=later, hit=hit))
        if r['op'] != 'E0_control' and j not in ('equivalent', 'unclear'):
            rr = rates[r['op']]; rr['n'] += 1; rr['loaded'] += r['loaded']; rr['spreads'] += r['damage'] > 0
            for d in DETECTORS:
                rr[d] += bool(hit[d])
            rr['any_today'] += bool(today); rr['any_holes'] += bool(today or any(hit[d] for d in DETECTORS if DETECTORS[d][0] == 'holes'))
            rr['any_data'] += bool(today or any(hit[d] for d in DETECTORS if DETECTORS[d][0] in ('holes', 'data') and not d.endswith('_c')))
            rr['any_all'] += bool(today or later)
    with open(OUT / 'mutants.tsv', 'w') as f:
        cols = ['mid', 'base', 'op', 'note', 'key', 'loaded', 'quant', 'damage', 'judged', 'mark', 'today', 'later']
        f.write('\t'.join(cols + ['flags']) + '\n')
        for t in table:
            fl = '; '.join(f'{d}: {" | ".join(v)[:160]}' for d, v in t['hit'].items() if v)
            f.write('\t'.join(str(t[c]) if not isinstance(t[c], list) else ','.join(t[c]) for c in cols) + '\t' + fl + '\n')
    ops = sorted(rates, key=lambda o: int(o.split('_')[0][1:]))
    det = list(DETECTORS)
    with open(OUT / 'catch_rates.tsv', 'w') as f:
        f.write('\t'.join(['error type', 'mutants', 'loaded', 'spreads'] + det + ['any today', 'today+holes.py', 'today+holes+data(stated)', 'any incl. new']) + '\n')
        tot = collections.Counter()
        for o in ops:
            rr = rates[o]; tot.update(rr)
            f.write('\t'.join([o, str(rr['n']), str(rr['loaded']), str(rr['spreads'])] + [str(rr[d]) for d in det] +
                              [str(rr['any_today']), str(rr['any_holes']), str(rr['any_data']), str(rr['any_all'])]) + '\n')
        f.write('\t'.join(['all', str(tot['n']), str(tot['loaded']), str(tot['spreads'])] + [str(tot[d]) for d in det] +
                          [str(tot['any_today']), str(tot['any_holes']), str(tot['any_data']), str(tot['any_all'])]) + '\n')
    # controls: false positives per detector (on correct controls), true positives on the real-error controls
    cfp = collections.Counter(); ctp = collections.Counter(); nc = nr = 0
    for t in table:
        if t['op'] != 'E0_control': continue
        if t['judged'] == 'true':
            nc += 1
            for d in det: cfp[d] += bool(t['hit'][d])
        else:
            nr += 1
            for d in det: ctp[d] += bool(t['hit'][d])
    with open(OUT / 'catch_rates.tsv', 'a') as f:
        f.write('\t'.join(['controls flagged (correct, false positive)', str(nc), '', ''] + [str(cfp[d]) for d in det]) + '\n')
        f.write('\t'.join(['controls flagged (real errors, true positive)', str(nr), '', ''] + [str(ctp[d]) for d in det]) + '\n')
    eq = [t for t in table if t['op'] != 'E0_control' and t['judged'] in ('equivalent', 'unclear')]
    with open(OUT / 'catch_rates.tsv', 'a') as f:
        f.write('\t'.join(['equivalent or unclear mutants (excluded above)', str(len(eq)), '', ''] + [str(sum(bool(t['hit'][d]) for t in eq)) for d in det]) + '\n')
    marks = collections.Counter(t['mark'] for t in table)
    print('marks', dict(marks))
    print(open(OUT / 'catch_rates.tsv').read())
    if '--freeze' in sys.argv:
        (OUT / 'expected_marks.tsv').write_text('# mid\tmark\ttoday detectors\n' + '\n'.join(f'{t["mid"]}\t{t["mark"]}\t{",".join(t["today"])}' for t in table) + '\n')
    if '--check' in sys.argv:
        exp = {l.split('\t')[0]: l.rstrip('\n').split('\t')[1:] for l in open(OUT / 'expected_marks.tsv') if l.strip() and not l.startswith('#')}
        diff = [(t['mid'], exp.get(t['mid']), [t['mark'], ','.join(t['today'])]) for t in table if exp.get(t['mid'], [None, ''])[:2] != [t['mark'], ','.join(t['today'])]]
        for d in diff: print('CHANGED', d)
        print('check:', 'ok' if not diff else f'{len(diff)} changed'); sys.exit(1 if diff else 0)

if __name__ == '__main__': main()
