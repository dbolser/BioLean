"""Program 04: seed known annotation-error types into copies of real compiled statements and run every detector.

Run from the repo root:  python3 -I scripts/stress/mutants_run.py
Reads   data/stress/04/bases.tsv, copies of data/textbook/claims_m2 and claims_m3 under /tmp/biolean-04/claims.
Writes  data/stress/04/mutants.json   every control and mutant, with the claim the emitter reads, its Lean term and
                                       entities (for mutants_lean.py), and what each detector said
        data/stress/04/baseline_flags.tsv   the static detectors run over every statement the closure loads, unmutated
Nothing under data/textbook, data/search or BioLean/Lib is written."""
import sys, json, time, collections, shutil
sys.path.insert(0, '/home/danbolser/Build/BioLean/scripts/stress')
import mutants_lib as L

def main():
    t0 = time.time()
    L.ensure_copy(); L.load_records()
    bases = [l.rstrip('\n').split('\t') for l in open(L.OUT / 'bases.tsv') if l.strip() and not l.startswith('#')]
    ns0, clash0, sign0 = L.run_closure(L.CLAIMS)
    asserted0 = ns0['asserted']
    modes = collections.Counter(L.pattern(k) for k in asserted0 if k[0] != 'effect')
    print(f'baseline: asserted {len(asserted0)}, facts {len(ns0["facts"])}, clashes {len(clash0)}, sign clashes off-loop {len(sign0)}, on a named loop {len(ns0["sign_loop"])}  ({time.time() - t0:.1f}s)')
    rows = []
    for rid, bid, why in bases:
        f = L.active(rid); r0 = L.record(f, rid); txt0 = L.texts(r0)
        key0, lean0, ents0, q0, not0 = L.reading(f, L.CLAIMS, rid, r0)
        self0 = key0 if key0 and key0 in asserted0 else None
        st0 = L.static(key0, q0, txt0, modes, self0) if key0 else {}
        if not key0 and lean0 is None and not0 and not0.startswith('emitter'): st0['lean_emit'] = not0
        dmg0 = len(L.resting_on(ns0, rid)) if key0 and key0 in asserted0 else 0
        rows.append(dict(base=rid, bid=bid, why=why, op='E0_control', mid=f'{bid}-E0', field=f, note='unmutated', ann=r0[f],
                         key=key0, lean_claim=lean0, ents=ents0, quant=q0, not_loaded=not0, loaded=bool(key0 and key0 in asserted0),
                         new_clash=[], new_sign=[], new_sign_loop=[], damage=dmg0, **st0))
        for op in L.OPS:
            x = L.apply(op, rid)
            if not x: continue
            fm, a, note = x
            mid = f'{bid}-{op.split("_")[0]}'
            root = L.write_mutant(mid, fm, rid, a)
            ns, cl, sg = L.run_closure(root)
            rm = dict(r0); rm[fm] = a
            txt = dict(txt0)   # the mention text stays; the curie changed under it
            if op != 'E4_direction_reversed':
                for fld in ('subject', 'object'):
                    if a.get(fld) != r0[fm].get(fld) and r0[fm].get(fld) in txt0: txt[a[fld]] = txt0[r0[fm][fld]]
            key, lean, ents, q, nl = L.reading(fm, root, rid, rm)
            st = L.static(key, q, txt, modes, self0) if key else {}
            if not key and lean is None and nl and nl.startswith('emitter'): st['lean_emit'] = nl
            loaded = bool(key and key in ns['asserted'])
            rows.append(dict(base=rid, bid=bid, why=why, op=op, mid=mid, field=fm, note=note, ann=a, key=key, lean_claim=lean,
                             ents=ents, quant=q, not_loaded=nl, loaded=loaded,
                             new_clash=[str(c) for c in sorted(cl - clash0, key=str)], new_sign=[str(c) for c in sorted(sg - sign0, key=str)],
                             new_sign_loop=[str(c) for c in sorted(ns['sign_loop'] - ns0['sign_loop'], key=str)],
                             damage=len(L.resting_on(ns, rid)) if loaded else 0, **st))
            shutil.rmtree(root)
        print(f'{bid} {rid}: {len(rows)} rows, {time.time() - t0:.1f}s', flush=True)
    for r in rows:
        if r['key']: r['key'] = [list(x) if isinstance(x, tuple) else x for x in r['key']]
    json.dump(rows, open(L.OUT / 'mutants.json', 'w'), indent=1, default=str)
    # --- the static detectors over every loaded statement, unmutated: false positives, or real errors in the data
    texts_by_id = {}
    for (d, n), recs in L.FILES.items():
        for rr in recs: texts_by_id.setdefault(rr['id'], {}).update(L.texts(rr))
    out = ['# statement\tdetector\tflag\tclaim key']
    cnt = collections.Counter()
    for k in sorted(asserted0, key=str):
        sid = ns0['sid_of'].get(k)
        if not sid: continue
        st = L.static(k, None, texts_by_id.get(sid, {}), modes, k)
        for d, v in st.items():
            vs = v if isinstance(v, list) else ([v] if v else [])
            if vs: cnt[d] += 1
            for x in vs: out.append(f'{sid}\t{d}\t{x}\t{k}')
    (L.OUT / 'baseline_flags.tsv').write_text('\n'.join(out) + '\n')
    print('baseline statements flagged, per detector:', dict(cnt), f'of {len(asserted0)} loaded')
    print(f'done: {len(rows)} rows in {time.time() - t0:.1f}s')

if __name__ == '__main__': main()
