"""Program 10c: precision and recall on held-out textbook facts, for today's closure search and for two rule
learners (induction_mine.py, AMIE-style with constants; AMIE 3.0 itself, path rules only).

Pool: every textbook statement whose fact is not is_a and not a negation (is_a is background for the learners;
negations are used only as negatives). Five folds by statement id, seed 10. For each fold the fold's statements are
held out; the closure (depth 4, the copy in induction_closure.py) and the learners see the rest.
- closure recall: held-out facts the closure re-derives (they are then theorems of the rest).
- learner recall: held-out facts some rule predicts, with PCA confidence >= theta and support >= 2.
- precision (lower bound): hits / predictions. Every prediction that is not a held-out fact counts as wrong, even
  when it is true biology the book never states, so this is a floor. induction_precision.py judges a sample.
Also leave-one-out for the closure alone: which statements are theorems of all the others.
Writes data/stress/10c/cv.tsv, cv_hits.tsv, loo_closure.tsv."""
import sys, os, random, collections, multiprocessing as mp, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import induction_closure as IC, induction_mine as M, induction_amie as A

OUT = IC.REPO / 'data/stress/10c'
THETAS = (0.1, 0.3, 0.5, 0.8, 1.0)
BASE = None


def pool_ids(base):
    by = collections.defaultdict(list)
    for k, v in base['facts'].items():
        if v['deriv'][0] == 'lit': by[v['src']].append(k)
    return sorted(s for s, ks in by.items() if all(k[0] != 'notRel' and not (k[0] == 'rel' and k[1] == IC.ISA) for k in ks)), by


def fold(test_ids, onto, amie, tag='x'):
    base = BASE
    _, by = pool_ids(base)
    facts, asserted = IC.chain(base, holdout=test_ids)
    test = {M.triple(base, k): k for s in test_ids for k in by[s]}
    out = dict(test=len(test), closure={t for t, k in test.items() if k in facts}, learners={})
    kb = M.KB([M.triple(base, k) for k in asserted], onto=onto)
    R = M.mine(kb, min_supp=2, min_pca=min(THETAS))
    out['learners']['mine'] = {t: (r['pca'], r['supp'], M.category(r, base), M.show(r, base['labels_e'])) for t, r in M.predictions(kb, R).items()}
    if amie:
        AR, _ = A.run(kb, f'cv_{"onto" if onto else "tb"}_fold{tag}')
        out['learners']['amie'] = {t: (r['pca'], r['supp'], 'amie', r['text']) for t, r in A.predictions(kb, AR).items()}
    out['test_triples'] = set(test)
    return out


def loo(sid):
    base = BASE
    _, by = pool_ids(base)
    facts, _ = IC.chain(base, holdout={sid})
    rows = []
    for k in by[sid]:
        if k in facts:
            rows.append((sid, IC.show(base, k), 'yes', facts[k]['deriv'][0], IC.tree(base, facts, k).replace('\n', ' | ')))
        else: rows.append((sid, IC.show(base, k), 'no', '', ''))
    return rows


def main():
    global BASE
    BASE = IC.load()
    ids, by = pool_ids(BASE)
    rnd = random.Random(10); sh = ids[:]; rnd.shuffle(sh)
    folds = [sorted(sh[i::5]) for i in range(5)]
    rows, hits_rows = [], []
    for onto in (False, True):
        agg = collections.Counter()
        for i, f in enumerate(folds):
            t0 = time.time()
            res = fold(f, onto, amie=not onto, tag=str(i))
            T = res['test_triples']
            agg[('test',)] += res['test']; agg[('closure',)] += len(res['closure'])
            for name, P in res['learners'].items():
                for th in THETAS:
                    Pt = {t: v for t, v in P.items() if v[0] >= th}
                    h = set(Pt) & T
                    agg[(name, th, 'pred')] += len(Pt); agg[(name, th, 'hit')] += len(h)
                    agg[(name, th, 'union')] += len(h | res['closure'])
                for t in set(P) & T:
                    v = P[t]
                    hits_rows.append((str(i), 'onto' if onto else 'textbook', name, t[0], f"{BASE['labels_e'].get(t[1], t[1])} [{t[1]}]",
                                      f"{BASE['labels_e'].get(t[2], t[2])} [{t[2]}]", f'{v[0]:.2f}', str(v[1]), v[2], v[3], 'yes' if t in res['closure'] else 'no'))
            print(f'onto={onto} fold {i}: test {res["test"]} closure {len(res["closure"])} '
                  + ' '.join(f"{n}: pred {sum(1 for v in P.values() if v[0] >= .5)} hit {len(set(t for t, v in P.items() if v[0] >= .5) & T)}" for n, P in res['learners'].items())
                  + f' ({time.time() - t0:.0f}s)', flush=True)
        n = agg[('test',)]
        rows.append(('closure (today)', 'onto' if onto else 'textbook', '-', '-', str(agg[('closure',)]), str(n), f"{agg[('closure',)] / n:.3f}", '-', '-'))
        for name in ('mine', 'amie'):
            for th in THETAS:
                p, h, u = agg[(name, th, 'pred')], agg[(name, th, 'hit')], agg[(name, th, 'union')]
                if not p and name == 'amie' and onto: continue
                rows.append((name, 'onto' if onto else 'textbook', f'{th}', str(p), str(h), str(n), f'{h / n:.3f}', f'{h / p:.4f}' if p else '-', f'{u / n:.3f}'))
    hdr = 'method\tbackground\tmin_pca\tpredictions\thits\theld_out\trecall\tprecision_lower_bound\trecall_with_closure'
    (OUT / 'cv.tsv').write_text(hdr + '\n' + '\n'.join('\t'.join(r) for r in rows) + '\n')
    (OUT / 'cv_hits.tsv').write_text('fold\tbackground\tlearner\thead\tsubject\tobject\tpca\tsupport\tcategory\trule\talso_closure\n'
                                     + '\n'.join('\t'.join(r) for r in hits_rows) + '\n')
    for r in rows: print('\t'.join(r))
    with mp.Pool(8) as p:
        L = [r for rs in p.map(loo, ids, chunksize=16) for r in rs]
    (OUT / 'loo_closure.tsv').write_text('statement\tfact\trederived\trule\ttree\n' + '\n'.join('\t'.join(r) for r in L) + '\n')
    print(f"leave-one-out closure: {sum(r[2] == 'yes' for r in L)} of {len(L)} facts ({len(ids)} statements) re-derived")


if __name__ == '__main__':
    main()
