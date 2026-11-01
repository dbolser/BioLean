"""Program 10c: run AMIE 3 (Lajus, Galarraga and Suchanek 2020; release 3.0 'amie-milestone-intKB.jar' from
github.com/dig-team/AMIE, the newest release that runs on the local Java 11) over the same triples as
induction_mine.py, parse its rules, and apply them to predict facts.

AMIE reads a TSV of subject, relation, object. We give it the textbook facts (not notRel), the background isa*
(materialised: AMIE has no transitive closure) and in_taxon, and ask for closed path rules with up to 3 atoms
(2 in the body), support >= 2, head coverage >= 0.01, PCA >= 0.1, heads as in induction_mine.KB.heads. `-pm support`
is needed: AMIE 3.0 prunes on head coverage by default and then ignores -mins (observed 2026-11-01: support-1 rules). Without
constants: with `-const` AMIE 3.0 did not finish in 100 s on these 1,716 triples even at 2 atoms (observed
2026-11-01), so constant rules (class, feature, taxon) come from induction_mine.py only. Output goes only to
data/stress/10c/amie/ and the jar is run from /tmp, with the paths as arguments."""
import subprocess, re, collections, pathlib, os

JAR = '/tmp/biolean-10c/dl/amie/amie-milestone-intKB.jar'
REPO = pathlib.Path(__file__).resolve().parents[2]
OUT = REPO / 'data/stress/10c/amie'


def enc(x): return '<' + x.replace(' ', '_').replace('\t', '_') + '>'


def write_tsv(kb, path):
    rows = []
    for p, pairs in kb.P.items():
        if p.startswith('not_') or p == 'is_a': continue
        for s, o in pairs: rows.append(f'{enc(s)}\t{enc(p)}\t{enc(o)}')
    path.write_text('\n'.join(sorted(rows)) + '\n')
    return len(rows)


def run(kb, tag, const=False, mins=2, minpca=0.1, maxad=3, timeout=600):
    OUT.mkdir(parents=True, exist_ok=True)
    tsv = OUT / f'{tag}.tsv'; n = write_tsv(kb, tsv)
    heads = ','.join(enc(h) for h in kb.heads())
    cmd = ['java', '-Xmx4g', '-jar', JAR, '-pm', 'support', '-mins', str(mins), '-minis', str(mins), '-minhc', '0.01',
           '-minpca', str(minpca), '-maxad', str(maxad), '-htr', heads]
    if const: cmd.append('-const')
    cmd.append(str(tsv))
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd='/tmp')
    (OUT / f'{tag}.rules.txt').write_text(res.stdout)
    return parse(res.stdout), n


ATOM = re.compile(r'(\?\w+|<[^>]*>)\s+(<[^>]*>)\s+(\?\w+|<[^>]*>)')


def dec(x): return x[1:-1] if x.startswith('<') else x


def parse(text):
    """AMIE's output lines: 'body atoms => head atom<TAB>head coverage<TAB>std conf<TAB>PCA conf<TAB>support ...'."""
    rules = []
    for line in text.splitlines():
        if '=>' not in line or '\t' not in line: continue
        parts = line.split('\t')
        rule = parts[0]
        try: hc, std, pca, supp = float(parts[1]), float(parts[2]), float(parts[3]), float(parts[4])
        except (ValueError, IndexError): continue
        body_s, head_s = rule.split('=>')
        body = [(dec(p), dec(s), dec(o)) for s, p, o in ATOM.findall(body_s)]
        head = [(dec(p), dec(s), dec(o)) for s, p, o in ATOM.findall(head_s)]
        if len(head) != 1 or not body: continue
        rules.append(dict(text=rule.strip(), body=body, head=head[0], hc=hc, std=std, pca=pca, supp=int(supp)))
    return rules


def apply(kb, rule):
    """All (head, x, y) the rule derives over kb (a backtracking join; variables start with '?')."""
    P = {p: pairs for p, pairs in kb.P.items()}
    P = {p.replace(' ', '_'): v for p, v in P.items()}
    bs = {p.replace(' ', '_'): kb.bs[p] for p in kb.P}; bo = {p.replace(' ', '_'): kb.bo[p] for p in kb.P}
    out = set()

    def val(t, env): return env.get(t, None) if t.startswith('?') else t

    def go(i, env):
        if i == len(rule['body']):
            hp, hs, ho = rule['head']
            x, y = val(hs, env), val(ho, env)
            if x is not None and y is not None and x != y: out.add((hp, x, y))
            return
        p, s, o = rule['body'][i]
        sv, ov = val(s, env), val(o, env)
        if p not in P: return
        if sv is not None and ov is not None:
            if (sv, ov) in P[p]: go(i + 1, env)
        elif sv is not None:
            for y in bs[p].get(sv, ()): go(i + 1, {**env, o: y})
        elif ov is not None:
            for x in bo[p].get(ov, ()): go(i + 1, {**env, s: x})
        else:
            for x, y in P[p]:
                if s == o and x != y: continue
                go(i + 1, {**env, s: x, o: y})
    go(0, {})
    return out


def predictions(kb, rules):
    best = {}
    for r in rules:
        for t in apply(kb, r):
            t = (t[0], t[1].replace('_', ' ') if False else t[1], t[2])
            if t in kb.T: continue
            if t not in best or (r['pca'], r['supp']) > (best[t]['pca'], best[t]['supp']): best[t] = r
    return best
