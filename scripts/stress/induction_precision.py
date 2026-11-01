"""Program 10c: real precision of the rule learners, by judging a random sample of their new predictions.

The cross-validated precision in cv.tsv is a floor: every prediction that is not a held-out textbook fact counts as
wrong, even when it is true biology the book never states. Here each learner (induction_mine.py and AMIE 3.0, both
with textbook is_a only, PCA >= 0.5, support >= 2) is run on the full textbook, its predictions of facts the book does
not state are listed, and a seeded sample of 30 is judged by hand.
  python3 scripts/stress/induction_precision.py sample    writes data/stress/10c/precision_sample.tsv (unjudged)
  python3 scripts/stress/induction_precision.py score     joins data/stress/10c/precision_judged.tsv and prints rates
Judgements are the program author's (an agent), from general biology, not checked against a source per item.
`scope` marks a prediction true only in the book's scope (eukaryotes, mammals), as SCOPE in rule_judgements.tsv; it
does not count as true (three were re-marked from true to scope in review, 2026-11-01)."""
import sys, os, random, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import induction_closure as IC, induction_mine as M, induction_amie as A

OUT = IC.REPO / 'data/stress/10c'
N, SEED, THETA = 30, 10, 0.5


def sample():
    base = IC.load(); facts, asserted = IC.chain(base, maxd=0); L = base['labels_e']
    kb = M.KB([M.triple(base, k) for k in asserted], onto=False)
    closure, _ = IC.chain(base)
    ct = {M.triple(base, k) for k in closure}
    P = {'mine': {t: (r['pca'], r['supp'], M.show(r, L)) for t, r in M.predictions(kb, M.mine(kb, 2, THETA)).items() if r['pca'] >= THETA}}
    AR, _ = A.run(kb, 'precision_full')
    P['amie'] = {t: (r['pca'], r['supp'], r['text']) for t, r in A.predictions(kb, AR).items() if r['pca'] >= THETA}
    rows = ['learner\thead\tsubject\tobject\tpca\tsupport\trule\talso_closure\tn_predictions']
    for name, preds in P.items():
        keys = sorted(preds); random.Random(SEED).shuffle(keys)
        for t in sorted(keys[:N]):
            pca, supp, rule = preds[t]
            rows.append('\t'.join([name, t[0], f'{L.get(t[1], t[1])} [{t[1]}]', f'{L.get(t[2], t[2])} [{t[2]}]', f'{pca:.2f}', str(supp),
                                   rule, 'yes' if t in ct else 'no', str(len(preds))]))
    (OUT / 'precision_sample.tsv').write_text('\n'.join(rows) + '\n')
    print('\n'.join(rows))


def score():
    J = {}
    for line in (OUT / 'precision_judged.tsv').read_text().splitlines()[1:]:
        f = line.split('\t'); J[tuple(f[:4])] = f[4]
    c = collections.defaultdict(collections.Counter)
    for line in (OUT / 'precision_sample.tsv').read_text().splitlines()[1:]:
        f = line.split('\t'); c[f[0]][J.get(tuple(f[:4]), 'unjudged')] += 1
    for name, k in c.items():
        n = sum(k.values()); t = k['true']; sc = k['scope']
        print(f"{name}: {dict(k)}; precision {t}/{n} = {t / n:.2f} (true / sampled); with book-scope truths "
              f"{t + sc}/{n} = {(t + sc) / n:.2f}; excluding unclear {t}/{n - k['unclear']}")


if __name__ == '__main__':
    sample() if sys.argv[1] == 'sample' else score()
