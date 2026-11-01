"""Program 10c: Popper 5.0 (Cropper and Morel 2021, learning from failures; ILP with predicate invention) on four
induction tasks built from BioLean's textbook facts.

Install (no root; observed 2026-11-01): Popper 5.0 needs Python >= 3.14 and SWI-Prolog (through janus-swi). SWI-Prolog
10.0.0 came from conda-forge with a user-space micromamba into /tmp/biolean-10c/swipl; Popper went into the venv
/tmp/biolean-10c/venv314 with that swipl on PATH.

Usage:
  python3 scripts/stress/induction_popper.py all
      builds data/stress/10c/popper/<task>/<fold>/{bk,exs,bias}.pl from the textbook (system python), runs Popper on
      each with the venv, evaluates the learned program on the held-out facts, writes data/stress/10c/popper/results.tsv
  /tmp/biolean-10c/venv314/bin/python scripts/stress/induction_popper.py run <dir> <timeout> [noisy]
      one Popper run; prints SOLUTION lines (used by `all`)

Tasks (each fold: train on the rest, test on the held-out positives and on the stated negatives):
  P31 G1 abundance with a demand predicate given by hand (synthetic facts from m45432-155, -189, -203). Leave one out.
  P32 G1 with no demand predicate and predicate invention on: can Popper invent 'demand' from capability alone?
  P18 has_input over the textbook (noisy mode), Calvin cycle CO2 (photosynthesis-m45453-20) held out.
  P23 involved_in from the textbook's five involved_in facts plus the amygdala example: does it find the brief's
      rule 'part_of(x,s), capable_of(s,p) => involved_in(x,p)'?
Negatives are stated per task: they are closed-world choices, not textbook statements, and are marked synthetic."""
import sys, os, re, json, subprocess, itertools, collections, pathlib

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[1]
OUT = REPO / 'data/stress/10c/popper'
VENV = '/tmp/biolean-10c/venv314/bin/python'
SWIPL = '/tmp/biolean-10c/swipl/bin'


CONST = {}   # curie -> safe Prolog atom (Popper 5.0 splits atoms on '(' when reading negatives, and refined curies have brackets)


def q(c):
    if c not in CONST: CONST[c] = f'c{len(CONST)}'
    return CONST[c]


def lit(p, a, b): return f"{p}({q(a)},{q(b)})"


# ---------------------------------------------------------------- Popper run (inside the venv)
def run_one(d, timeout, noisy):
    from popper.util import Settings, format_rule, order_prog, order_rule
    from popper.loop import popper
    s = Settings(bk_file=os.path.join(d, 'bk.pl'), ex_file=os.path.join(d, 'exs.pl'), bias_file=os.path.join(d, 'bias.pl'),
                 timeout=float(timeout), noisy=noisy, verbosity=0)
    prog, score = popper(s)
    if prog is None:
        print('NO_SOLUTION'); return
    print('SCORE', *score)
    for rule in order_prog(prog): print('RULE', format_rule(order_rule(rule, s)))


# ---------------------------------------------------------------- tasks (system python)
def textbook_triples():
    sys.path.insert(0, str(HERE))
    import induction_closure as IC, induction_mine as M
    base = IC.load(); facts, asserted = IC.chain(base, maxd=0)
    return base, {M.triple(base, k): facts[k]['src'] for k in asserted}


DEMAND = [('high_demand', 'CL:0000765', 'GO:0006412'), ('high_demand', 'CL:0000151', 'GO:0046903'),
          ('high_demand', 'CL:0000187', 'GO:0006754')]
ABUND = [('has_abundant', 'CL:0000765', 'GO:0005840'), ('has_abundant', 'CL:0000151', 'GO:0005794'),
         ('has_abundant', 'CL:0000187', 'GO:0005739')]
GOLGI = ('capable_of', 'GO:0005794', 'GO:0046903')        # synthetic, from the GO:0005794 definition (OLS4)
CELL_CAP = [('capable_of', 'CL:0000765', 'GO:0006412'), ('capable_of', 'CL:0000151', 'GO:0046903'),
            ('capable_of', 'CL:0000187', 'GO:0006754')]  # synthetic: the demand read as a capability
GENERIC_NEG = [('has_abundant', 'CL:0000000', o) for o in ('GO:0005739', 'GO:0005840', 'GO:0005794')]


def tasks(T):
    cap = sorted(t for t in T if t[0] == 'capable_of')
    out = []
    # P31: demand given; leave one positive out
    # P31b: the same with closed-world negatives: each cell is not rich in the other cells' organelle (not stated in the book)
    cross = [('has_abundant', a[1], b[2]) for a in ABUND for b in ABUND if a != b]
    for i, held in enumerate(ABUND):
        out.append(dict(task='P31b', fold=str(i), head=('has_abundant', 2), body=[('high_demand', 2), ('capable_of', 2)],
                        bk=cap + [GOLGI] + DEMAND, pos=[a for a in ABUND if a != held], neg=GENERIC_NEG + cross,
                        test_pos=[held], test_neg=[], pi=False, noisy=False, max_vars=4, max_body=3, timeout=120))
    for i, held in enumerate(ABUND):
        out.append(dict(task='P31', fold=str(i), head=('has_abundant', 2), body=[('high_demand', 2), ('capable_of', 2)],
                        bk=cap + [GOLGI] + DEMAND, pos=[a for a in ABUND if a != held], neg=GENERIC_NEG,
                        test_pos=[held], test_neg=[], pi=False, noisy=False, max_vars=4, max_body=3, timeout=120))
    # P32: no demand predicate; cells' capabilities stand in; predicate invention on. Folds 0-2 train with the generic-cell
    # negatives; fold 'noneg' has all three positives and no negatives, and is tested on the generic-cell negatives.
    for i, held in enumerate(ABUND):
        out.append(dict(task='P32', fold=str(i), head=('has_abundant', 2), body=[('capable_of', 2)],
                        bk=cap + [GOLGI] + CELL_CAP, pos=[a for a in ABUND if a != held], neg=GENERIC_NEG,
                        test_pos=[held], test_neg=[], pi=True, noisy=False, max_vars=4, max_body=3, timeout=120))
    out.append(dict(task='P32', fold='noneg', head=('has_abundant', 2), body=[('capable_of', 2)],
                    bk=cap + [GOLGI] + CELL_CAP, pos=ABUND, neg=[], test_pos=[], test_neg=GENERIC_NEG,
                    pi=True, noisy=False, max_vars=4, max_body=3, timeout=120))
    # P18: has_input over the textbook; negatives: a process's own stated outputs are not its inputs
    preds = ('has_output', 'derives_from', 'has_part', 'part_of', 'occurs_in')
    hi = sorted(t for t in T if t[0] == 'has_input')
    held = ('has_input', 'GO:0019253', 'CHEBI:16526')
    neg = sorted({('has_input', s, o) for p, s, o in T if p == 'has_output' and any(h[1] == s for h in hi)} - set(hi))
    for mode in ('noisy', 'exact'):
        out.append(dict(task='P18', fold=mode, head=('has_input', 2), body=[(p, 2) for p in preds],
                        bk=sorted(t for t in T if t[0] in preds), pos=[h for h in hi if h != held], neg=neg,
                        test_pos=[held], test_neg=[], pi=False, noisy=mode == 'noisy', max_vars=3, max_body=2, timeout=300))
    # P23: involved_in; the amygdala example (McGaugh 2004) is the held-out positive in fold 0 and a training positive in fold 1
    preds = ('part_of', 'capable_of', 'is_a', 'has_part')
    inv = sorted(t for t in T if t[0] == 'involved_in')
    amyg = ('involved_in', 'UBERON:0001876', 'GO:0007613')
    neg = [('involved_in', 'UBERON:0002240', 'GO:0007613')]   # synthetic negative: the spinal cord is not involved in memory
    for (fold, pos, test), mode in itertools.product((('0', inv, [amyg]), ('1', inv + [amyg], [])), ('noisy', 'exact')):
        out.append(dict(task='P23', fold=f'{fold}-{mode}', head=('involved_in', 2), body=[(p, 2) for p in preds],
                        bk=sorted(t for t in T if t[0] in preds), pos=pos, neg=neg, test_pos=test, test_neg=[],
                        pi=False, noisy=mode == 'noisy', max_vars=3, max_body=2, timeout=300))
    return out


def write(t):
    d = OUT / t['task'] / t['fold']; d.mkdir(parents=True, exist_ok=True)
    (d / 'bk.pl').write_text(':- discontiguous(capable_of/2).\n' + ''.join(f'{lit(*f)}.\n' for f in sorted(set(t['bk']))))
    (d / 'exs.pl').write_text(''.join(f'pos({lit(*e)}).\n' for e in t['pos']) + ''.join(f'neg({lit(*e)}).\n' for e in t['neg']))
    b = [f"head_pred({t['head'][0]},{t['head'][1]})."] + [f'body_pred({p},{n}).' for p, n in t['body']]
    b += [f"max_vars({t['max_vars']}).", f"max_body({t['max_body']})."] + (['enable_pi.'] if t['pi'] else [])
    (d / 'bias.pl').write_text('\n'.join(b) + '\n')
    return d


# ---------------------------------------------------------------- evaluating a learned program (bottom-up Datalog)
ATOM = re.compile(r"(\w+)\(([^()]*)\)")


def parse_rule(s):
    head, body = s.rstrip('.').split(':-') if ':-' in s else (s.rstrip('.'), '')
    def atoms(x): return [(m.group(1), [a.strip() for a in m.group(2).split(',')]) for m in ATOM.finditer(x)]
    return atoms(head)[0], atoms(body)


def evaluate(rules, facts):
    """Fixpoint of the rules over facts (p, a, b); variables are capitalised names, constants quoted."""
    F = set(facts)
    rules = [parse_rule(r) for r in rules]
    while True:
        idx = collections.defaultdict(set)
        for p, a, b in F: idx[p].add((a, b))
        new = set()
        for (hp, hargs), body in rules:
            def go(i, env):
                if i == len(body):
                    vals = [env.get(v, v.strip("'")) for v in hargs]
                    if len(vals) == 2: new.add((hp, vals[0], vals[1]))
                    return
                p, args = body[i]
                for a, b in idx.get(p, ()):
                    e = dict(env); ok = True
                    for v, x in zip(args, (a, b)):
                        if v[0].isupper() or v[0] == '_':
                            if e.get(v, x) != x: ok = False; break
                            e[v] = x
                        elif v.strip("'") != x: ok = False; break
                    if ok: go(i + 1, e)
            go(0, {})
        if new <= F: return F
        F |= new


def main_all():
    base, src = textbook_triples()
    T = set(src)
    rows = ['task\tfold\tpos\tneg\ttest_pos\ttest_neg\tsolution\tscore(tp,fn,tn,fp)\ttest_pos_hit\ttest_neg_hit\tmark']
    env = dict(os.environ, PATH=SWIPL + ':' + os.environ['PATH'], LD_LIBRARY_PATH=SWIPL.replace('/bin', '/lib'))
    for t in tasks(T):
        d = write(t)
        cmd = [VENV, str(HERE / 'induction_popper.py'), 'run', str(d), str(t['timeout'])] + (['noisy'] if t['noisy'] else [])
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=t['timeout'] + 120, env=env, cwd='/tmp')
            outp = r.stdout + ('\nSTDERR ' + r.stderr[-800:] if r.returncode else '')
        except subprocess.TimeoutExpired:
            outp = 'TIMEOUT'
        (d / 'popper_out.txt').write_text(outp)
        rules = [l[5:] for l in outp.splitlines() if l.startswith('RULE ')]
        score = next((l[6:] for l in outp.splitlines() if l.startswith('SCORE ')), '')
        A = lambda f: (f[0], q(f[1]), q(f[2]))
        F = evaluate(rules, [A(f) for f in t['bk']]) if rules else set()
        ph = [A(e) in F for e in t['test_pos']]; nh = [A(e) in F for e in t['test_neg']]
        mark = 'FAIL' if any(nh) else ('PASS' if all(ph) else 'SILENT')
        if not rules: mark = 'SILENT' if 'NO_SOLUTION' in outp or not outp.strip() or 'TIMEOUT' in outp else mark
        sol = ' '.join(rules) if rules else (outp.strip().splitlines() or ['(no output)'])[-1][:200]
        rows.append('\t'.join([t['task'], t['fold'], str(len(t['pos'])), str(len(t['neg'])), ';'.join(lit(*e) for e in t['test_pos']),
                               ';'.join(lit(*e) for e in t['test_neg']), sol, score, ''.join('1' if x else '0' for x in ph),
                               ''.join('1' if x else '0' for x in nh), mark]))
        print(rows[-1], flush=True)
    (OUT / 'results.tsv').write_text('\n'.join(rows) + '\n')
    (OUT / 'constants.tsv').write_text('atom\tcurie\n' + ''.join(f'{a}\t{c}\n' for c, a in CONST.items()))


if __name__ == '__main__':
    if sys.argv[1] == 'run': run_one(sys.argv[2], sys.argv[3], len(sys.argv) > 4 and sys.argv[4] == 'noisy')
    elif sys.argv[1] == 'all': main_all()
