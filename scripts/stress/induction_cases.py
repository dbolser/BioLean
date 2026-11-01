"""Program 10c: build data/stress/10c/cases.tsv from the observed runs, and pin the Python-side behaviour.
  python3 scripts/stress/induction_cases.py write   joins tasks_observed.json (induction_tasks.py), popper/results.tsv
                                                    (induction_popper.py) and the Lean test names below; writes cases.tsv
  python3 scripts/stress/induction_cases.py table   prints the summary table in markdown (for the program doc)
  python3 scripts/stress/induction_cases.py check   recomputes every mark from the observation files, and re-runs today's
                                                    closure search on every task (about 15 s), and compares both with
                                                    cases.tsv; exits 1 on any change. The learners are not re-run (rerun
                                                    the two runners to re-observe them; about 10 minutes, mostly AMIE)
`mark_search` is today's closure search. `mark` is today's BioLean: the search mark, except where a Lean pin in
BioLean/Stress/Induction.lean observes a conclusion the search cannot reach (LEAN_MARK: I10 through the round-2
library, I37 through `generalize`); those pins are theorems, so a change flips the Lean file. A conclusion means a
derivation with belief above 0. The learners are not part of BioLean; their marks are
in mark_mine (ontology is_a background), mark_mine_tb (textbook is_a only), mark_amie and mark_popper (exact mode; a
fold FAILs the task, every tested fold must PASS; noisy-mode runs are reported in `observed` only)."""
import sys, os, json, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import induction_tasks as TK

OUT = TK.OUT
S, P = 'BioLean.Stress.Induction', 'BioLean.Proto.Induction'
LEAN = {
    'I01': f'{S}.I01', 'I02': f'{S}.I02', 'I03': f'{S}.I03', 'I04': f'{S}.I04', 'I05': f'{S}.I05', 'I06': f'{S}.I06',
    'I07': f'{S}.I07_tested; #guard i07.verdict', 'I08': f'{S}.ruleName (no inversion rule; #guard RO.inverseOK)',
    'I09': f'{S}.I09_false_established; #guard i09neg', 'I10': f'{S}.I10_R2_false_established',
    'I11': f'{S}: #guard i11pos, i11neg', 'I12': f'{S}: #guard i12pos, i12neg', 'I13': f'{S}: #guard i13neg',
    'I15': f'{S}: #guard i15pos, i15neg, i15neg2', 'I17': f'{S}: #guard i17rbc, i35 clash',
    'I18': f'{S}: #guard RO.chainOK (I18); {P}.calvinCO2', 'I19': f'{S}: #guard RO.chainOK (I19); {P}.mitoPhoto',
    'I20': f'{S}: #guard RO.inverseOK; ruleName', 'I22': f'{S}.I22_sound_form; #guard RO.chainOK (I22)',
    'I23': f'{S}: #guard RO.chainOK (I23); {P}.amygdala_part_of_structure_capable_of_memory, amygdalaMemoryJ',
    'I25': f'{S}.I25_false_established', 'I26': f'{S}.I26', 'I30': f'{S}: #no_lean x4; #guard g1Nearest',
    'I31': f'{P}.muscleMito, muscleMitoT', 'I35': f'{S}: #guard clash i35 = refuted',
    'I37': f'{S}.I37_value, I37_unsupported, I37_one_lineage_no_belief',
}
# Where a Lean theorem observes more than the closure search: (mark, why). The search reads round 3 over round 2 and
# has no `generalize` rule; the Lean core with its built libraries has both.
LEAN_MARK = {
    'I10': ('FAIL', 'round-2 library: I10_R2_false_established (bacterial cell wall has part cellulose, 0.8)'),
    'I37': ('PASS', 'generalize: I37_value (16/27, unsupported) and I37_one_lineage_no_belief (0)'),
}
CORRECT = {
    'I01': 'Frontal lobe part_of brain follows from part_of transitivity.',
    'I02': 'Kidney has_part nephron follows from has_part transitivity.',
    'I03': 'Aneuploidy (a chromosomal disorder) is often lethal.',
    'I04': 'Chlorophyll (a pigment) absorbs light.',
    'I05': 'The light reactions occur in the chloroplast.',
    'I06': 'Statins lower cholesterol by inhibiting HMG-CoA reductase.',
    'I07': 'A class rule over the cerebral lobes recovers frontal lobe part_of cerebral cortex.',
    'I08': 'Thalamus part_of brain; not spinal cord part_of brain.',
    'I09': 'Aspirin lowers inflammation; aldosterone does not (it promotes it).',
    'I10': 'Plant cell walls contain cellulose; bacterial and fungal walls do not.',
    'I11': 'Metaphase is part of mitosis; S phase is not (interphase).',
    'I12': 'Beta cells are in the islets; thyroid follicular cells are not.',
    'I13': 'Meiosis I halves ploidy; fertilisation does not (it restores diploidy).',
    'I14': 'Rb halts the cell cycle; growth hormone does not.',
    'I15': 'Glycolysis makes ATP; glycogen synthesis and gluconeogenesis spend it.',
    'I16': 'HIV enters host cells.',
    'I17': 'Smooth muscle cells have a nucleus; prokaryotes and mature mammalian red cells do not.',
    'I18': 'The Calvin cycle takes in CO2 (the carbon of its sugar product comes from CO2).',
    'I19': 'Mitochondria do not photosynthesise, though they derive from bacteria.',
    'I20': 'Not every phospholipid is part of a mitochondrial membrane.',
    'I21': 'Not every bone is part of the rib cage.',
    'I22': 'The chloroplast performs photosynthesis.',
    'I23': 'The amygdala is involved in memory.',
    'I24': 'The nasal cavity does not raise the amount of oxygen.',
    'I25': 'The bacterial chromosome is in the nucleoid; not in a nucleus; bacterial ribosomes are not in the nucleoid.',
    'I26': 'The eukaryotic chromosome is in the nucleus; eukaryotic ribosomes are not.',
    'I27': 'Plant cell walls contain cellulose.',
    'I28': 'The Calvin cycle makes sugar.',
    'I29': 'Fatty acid synthesis does not raise ATP.',
    'I30': 'Muscle cells have many mitochondria (relative to other cells).',
    'I31': 'Muscle cells have many mitochondria, given the demand rule and the demand facts.',
    'I32': 'A generic cell is not rich in mitochondria.',
    'I33': 'The nucleus does not derive from bacteria.',
    'I34': 'The thyroid does not make insulin.',
    'I35': 'Prokaryotic cells have no nucleus.',
    'I36': 'Two copies of one sentence are one instance: no rule from one instance.',
    'I37': 'Ribosomes are in the cytoplasm in all cellular organisms; not every chromosome of a cellular organism is in a nucleus.',
}
POPPER = {'I18': ('P18',), 'I23': ('P23',), 'I31': ('P31', 'P31b'), 'I32': ('P32',)}


def fmt(q): return f'{q[0]}({q[1]}, {q[2]})'


def popper_rows():
    p = OUT / 'popper/results.tsv'
    if not p.exists(): return []
    return [dict(zip(p.read_text().splitlines()[0].split('\t'), l.split('\t'))) for l in p.read_text().splitlines()[1:]]


def popper_mark(cid, rows):
    """One mark over a task's folds: FAIL if any fold FAILs, PASS if every fold with a test PASSes, else SILENT."""
    if cid not in POPPER: return '-', ''
    every = [r for r in rows if r['task'] in POPPER[cid]]
    rs = [r for r in every if (r['test_pos'] or r['test_neg']) and 'noisy' not in r['fold']]   # the mark: exact mode
    if not rs: return '-', ''
    ms = [r['mark'] for r in rs]
    m = 'FAIL' if 'FAIL' in ms else ('PASS' if all(x == 'PASS' for x in ms) else 'SILENT')
    return m, '; '.join(f"{r['task']}/{r['fold']}: {r['mark'] if (r['test_pos'] or r['test_neg']) else 'no test'} ({r['solution'][:90]})" for r in every)


def observed(r, prow):
    s = r['systems']; c = s['closure']
    parts = []
    if r['pos']: parts.append('closure pos ' + ','.join(('yes by ' + h) if x else 'no' for x, h in zip(c['pos'], c.get('how', [''] * len(c['pos'])))))
    if r['neg']: parts.append('closure neg ' + ','.join('CONCLUDED' if x else 'no' for x in c['neg']))
    for nm in ('mine', 'mine_tb', 'amie'):
        sy = s[nm]; bits = []
        for lab, key in (('pos', 'pos_info'), ('neg', 'neg_info')):
            for q, i in zip(r[lab], sy.get(key, [])):
                if i: bits.append(f"{lab} by [{i['rule'][:70]}] pca={i['pca']}" + (f" {i.get('judge')}" if nm != 'amie' else ''))
        parts.append(f"{nm} {sy['mark']}" + (': ' + '; '.join(bits) if bits else ''))
    if prow: parts.append('popper ' + prow)
    if r['id'] in LEAN_MARK: parts.insert(0, f"BioLean {LEAN_MARK[r['id']][0]} by Lean ({LEAN_MARK[r['id']][1]}); search {c['mark']}")
    return ' | '.join(parts)


def live_search_marks():
    """Re-run today's closure search (the copy in induction_closure.py, over the current textbook data) on every task."""
    base = TK.IC.load(); out = {}
    for t in TK.TASKS:
        facts, _ = TK.IC.chain(base, holdout=set(t.get('hold', [])))
        ct = {TK.M.triple(base, k) for k in facts}
        ph = [p in ct for p in t.get('pos', [])]; nh = [n in ct for n in t.get('neg', [])]
        out[t['id']] = 'INEXPRESSIBLE' if t.get('inexpressible') else TK.mark(ph, nh, len(ph))
    return out


def build():
    R = json.load(open(OUT / 'tasks_observed.json')); prs = popper_rows()
    hdr = ['id', 'probes', 'input', 'correct', 'observed', 'mark', 'test', 'source',
           'family', 'synthetic', 'mark_mine', 'mark_mine_tb', 'mark_amie', 'mark_popper', 'mark_search']
    rows = []
    for r in R:
        t = next(x for x in TK.TASKS if x['id'] == r['id'])
        inp = (f"held out: {', '.join(r['hold'])}; " if r['hold'] else 'nothing held out; ') + 'given: every other textbook statement'
        if t.get('extra'): inp += '; synthetic facts: ' + '; '.join(f'{e[0]}({e[1]}, {e[2]})' for e in t['extra'])
        inp += '; ask pos: ' + ('; '.join(fmt(q) for q in r['pos']) or '-') + '; ask neg: ' + ('; '.join(fmt(q) for q in r['neg']) or '-')
        pm, ptxt = popper_mark(r['id'], prs)
        test = LEAN.get(r['id'], '') + ('; ' if r['id'] in LEAN else '') + f"scripts/stress/induction_tasks.py {r['id']} (check: induction_cases.py check)"
        search = r['systems']['closure']['mark']
        rows.append([r['id'], r['probes'], inp, CORRECT[r['id']], observed(r, ptxt), LEAN_MARK.get(r['id'], (search,))[0], test, r['src'],
                     r['family'], 'yes' if r['synthetic'] else 'no', r['systems']['mine']['mark'], r['systems']['mine_tb']['mark'],
                     r['systems']['amie']['mark'], pm, search])
    return hdr, rows


def main():
    hdr, rows = build()
    if sys.argv[1] == 'table':
        print('| id | family | probes | BioLean | search | mine | mine_tb | AMIE | Popper |')
        print('|---|---|---|---|---|---|---|---|---|')
        for r in rows:
            print(f"| {r[0]} | {r[8]}{' (syn)' if r[9] == 'yes' else ''} | {r[1]} | {r[5]} | {r[14]} | {r[10]} | {r[11]} | {r[12]} | {r[13]} |")
        return
    if sys.argv[1] == 'write':
        (OUT / 'cases.tsv').write_text('\t'.join(hdr) + '\n' + '\n'.join('\t'.join(x.replace('\t', ' ') for x in r) for r in rows) + '\n')
        tally = {k: collections.Counter(r[i] for r in rows) for k, i in (('BioLean', 5), ('search', 14), ('mine', 10), ('mine_tb', 11), ('amie', 12), ('popper', 13))}
        # the null baseline: a system that concludes nothing (PASS on neg-only tasks, SILENT elsewhere)
        tally['null'] = collections.Counter('INEXPRESSIBLE' if t.get('inexpressible') else ('SILENT' if t.get('pos') else 'PASS')
                                            for t in TK.TASKS)
        print(len(rows), 'cases;', json.dumps(tally))
    else:
        old = {l.split('\t')[0]: l.split('\t') for l in (OUT / 'cases.tsv').read_text().splitlines()[1:]}
        bad = [(r[0], hdr[i], old[r[0]][i], r[i]) for r in rows for i in (5, 10, 11, 12, 13, 14) if r[0] not in old or old[r[0]][i] != r[i]]
        live = live_search_marks()
        bad += [(cid, 'mark_search (live re-run)', old[cid][14], m) for cid, m in live.items() if cid not in old or old[cid][14] != m]
        if len(live) != len(old): bad.append(('-', 'case count', str(len(old)), str(len(live))))
        for b in bad: print('CHANGED', *b)
        print('OK: all marks as pinned' if not bad else f'{len(bad)} marks changed'); sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
