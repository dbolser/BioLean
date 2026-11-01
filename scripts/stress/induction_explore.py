"""Program 10c: look at the data. `induction_explore.py rules [onto]` prints the top rules; `induction_explore.py
grep <regex>` prints the textbook facts whose rendering matches, with statement ids; `induction_explore.py rule
<rule_id substring> [onto]` prints a rule's support and its novel predictions. Writes nothing."""
import sys, re, collections
sys.path.insert(0, __import__('os').path.dirname(__file__))
import induction_closure as IC, induction_mine as M

def kb_of(onto):
    base = IC.load(); facts, asserted = IC.chain(base, maxd=0)
    src = {M.triple(base, k): facts[k]['src'] or facts[k]['deriv'][1] for k in asserted}
    return base, M.KB(list(src), onto=onto), src

if __name__ == '__main__':
    cmd = sys.argv[1]; onto = 'onto' in sys.argv[2:]
    base, kb, src = kb_of(onto); L = base['labels_e']
    def lab(c): return f"{L.get(c) or c} [{c}]"
    if cmd == 'grep':
        rx = re.compile(sys.argv[2], re.I)
        for t, s in sorted(src.items()):
            line = f"{t[0]}  {lab(t[1])}  {lab(t[2])}  {s}"
            if rx.search(line): print(line)
    elif cmd == 'rules':
        R = M.mine(kb, min_supp=2, min_pca=0.5)
        R.sort(key=lambda r: (-r['pca'] * min(r['supp'], 10), -r['supp']))
        for r in R[:int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3].isdigit() else 60]:
            print(f"{r['supp']:3d} n={r['n']:4d} pca={r['pca']:.2f} std={r['std']:.2f} {M.category(r, base):18s} {M.show(r, L)}   {M.rule_id(r)}")
    elif cmd == 'rule':
        want = sys.argv[2]
        R = [r for r in M.mine(kb, min_supp=2, min_pca=0.1) if want in M.rule_id(r)]
        for r in R[:5]:
            print(f"== {M.show(r, L)}  supp={r['supp']} n={r['n']} pca={r['pca']:.2f} std={r['std']:.2f} {M.category(r, base)}")
            for x, y in sorted(r['pred']):
                t = (r['head'], x, y)
                print(('  SUPPORT ' + src[t]) if t in kb.T else '  PREDICT', ' ', lab(x), '->', lab(y))
