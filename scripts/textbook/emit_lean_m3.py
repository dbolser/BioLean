"""Round 3: emit Lean Statements from the `m3` annotations (quantity and context), one module per chapter.

Context follows `BioLean/Context.lean`: taxon, stage and condition refine the subject with `Entity.inCtx`; the site
fields (anatomy, cellType, component) refine the entity they locate, which is the target of an effect on an amount,
process or activity ("insulin lowers blood glucose" refines glucose), and the subject otherwise. A quantifier wraps
the claim. Records with a blocker, ctor `none`, or an id in `data/textbook/r3_skip.tsv` (Lean rejected) are skipped.
`statements()` is the shared reading: `scripts/search/closure.py` loads the same claims, with the same composite curies.
Usage: emit_lean_m3.py <claims_m3_dir> <go.obo> <out_dir>"""
import json, glob, re, sys, collections, pathlib
from fractions import Fraction

R2_ENTITIES = 'BioLean/Lib/TextbookClaimsR2/Entities.lean'
SKIP_TSV = 'data/textbook/r3_skip.tsv'
KIND_BY_NS = {'biological_process': 'process', 'molecular_function': 'function', 'cellular_component': 'component'}
PREFIX_KIND = {'CHEBI': 'chemical', 'PR': 'protein', 'UniProt': 'protein', 'UNIPROT': 'protein', 'UniProtKB': 'protein',
               'HGNC': 'gene', 'NCBIGene': 'gene', 'SO': 'gene', 'MGI': 'gene', 'HP': 'phenotype', 'MP': 'phenotype',
               'PATO': 'phenotype', 'OBA': 'phenotype', 'MONDO': 'disease', 'DOID': 'disease', 'UBERON': 'anatomy',
               'CL': 'cellType', 'NCBITaxon': 'taxon',
               'PO': 'anatomy',       # as in Examples/Context.lean (leaf); only used as a context filler
               'BLN': 'phenotype'}    # condition placeholders, as in Examples/Context.lean
TARGETS = ('activity', 'amount', 'process', 'phenotype', 'site')
QUANTITY = ('count', 'atLeast', 'cardinality', 'measure', 'less', 'produces', 'consumes', 'yield')
OCCURRENT = ('process', 'function')
# context relations, as in Rel.lean
LOCATED_IN, OCCURS_IN, PART_OF = ('ro', 1025, False), ('bfo', 66, False), ('bfo', 50, False)
SURROUNDED_BY, HAPPENS_DURING, IN_TAXON, HAS_MODIFIER = ('ro', 2219, False), ('ro', 2092, False), ('ro', 2162, False), ('ro', 2573, False)
CELLULAR_ORGANISMS = ('NCBITaxon:131567', 'cellular organisms')   # Taxa.cellularOrganisms
ISA = ('rdfs', 0, False)

def go_namespaces(go_obo):
    ns = {}; cur = None
    for line in open(go_obo, encoding='utf-8'):
        if line.startswith('id: GO:'): cur = line[4:].strip()
        elif cur and line.startswith('namespace: '): ns[cur] = line[11:].strip(); cur = None
    return ns

RO_LABELS = {(m.group(1), int(m.group(2)), False): m.group(3)
             for m in re.finditer(r'\(⟨\.(ro|bfo), (\d+), false⟩, "([^"]+)"\)', open('BioLean/RO.lean').read())}
RO_LABELS[ISA] = 'is_a'
BY_LABEL = {v.lower(): k for k, v in RO_LABELS.items()}
def rel_of(l):
    if not l: return None
    l = l.strip().lower().replace('_', ' ')
    return ISA if l in ('is a', 'isa', 'subclass of') else BY_LABEL.get(l)
def rel_curie(r): return 'rdfs:subClassOf' if r[0] == 'rdfs' else f'{r[0].upper()}:{r[1]:07d}'   # Rel.curie
def rel_lean(r): return 'Rel.isA' if r == ISA else f'⟨.{r[0]}, {r[1]}, false⟩'
def ename(c): return 'e_' + re.sub(r'[^A-Za-z0-9]', '_', c)
def q(s): return '"' + (s or '').replace('\\', '\\\\').replace('"', '\\"') + '"'
def num(x):
    f = Fraction(str(x)); s = str(f) if f.denominator == 1 else f'{f.numerator}/{f.denominator}'
    return f'({s})' if f.denominator != 1 or f < 0 else s

class Skip(Exception): pass
def need(ctor, *ok):
    if not all(ok): raise Skip(f'{ctor} without its fields')

def in_ctx(e, k, ctx):
    """`Entity.inCtx` on (lean, curie, label): the same order, relations and curie as BioLean/Context.lean."""
    lean, curie, label = e; fields = []
    def refine(rel, f):
        nonlocal curie, label
        curie, label = f'{curie}&{rel_curie(rel)}=({f[1]})', f'{label} ⊓ {RO_LABELS[rel]} ({f[2]})'
    loc = OCCURS_IN if k in OCCURRENT else LOCATED_IN
    for slot, rel in (('anatomy', loc), ('cellType', OCCURS_IN if k in OCCURRENT else PART_OF), ('component', loc)):
        if slot in ctx: refine(rel, ctx[slot]); fields.append(f'{slot} := {ctx[slot][0]}')
    cond = ctx.get('condition')
    if cond and cond[0] == 'environment': refine(SURROUNDED_BY, cond[1])
    if 'stage' in ctx: refine(HAPPENS_DURING, ctx['stage']); fields.append(f'stage := {ctx["stage"][0]}')
    if 'taxon' in ctx: fields.insert(0, f'taxon := {ctx["taxon"][0]}')
    if cond: fields.append(f'condition := some (.{cond[0]} {cond[1][0]})')
    taxon = ctx.get('taxon')
    if cond and cond[0] == 'organism':
        t = taxon or (None,) + CELLULAR_ORGANISMS
        taxon = (None, f'{t[1]}&{rel_curie(HAS_MODIFIER)}=({cond[1][1]})', f'{t[2]} ⊓ {RO_LABELS[HAS_MODIFIER]} ({cond[1][2]})')
    if taxon: refine(IN_TAXON, taxon)
    return (f'({lean}.inCtx {{ {", ".join(fields)} }})' if fields else lean), curie, label

def statements(src, go_ns):
    """Read every m3 record. Returns (statements, skipped reasons, records) where a statement is a dict with the Lean
    claim and, for the closure, ctor, quant, rel, sign, target and the (composite) subject and object curies."""
    def kind_of(c):
        if not c: return None
        p = c.split(':')[0]
        return KIND_BY_NS.get(go_ns.get(c)) if p == 'GO' else PREFIX_KIND.get(p)
    skip_ids = {l.split('\t')[0].strip() for l in open(SKIP_TSV) if l.strip() and not l.startswith('#')} if pathlib.Path(SKIP_TSV).exists() else set()
    out, skipped, recs = [], collections.Counter(), []
    for p in sorted(glob.glob(f'{src}/*.json')):
        slug = pathlib.Path(p).stem
        for r in json.load(open(p)):
            m = r.get('m3')
            if not m: continue
            recs.append(r)
            labels = {e['curie']: e.get('text') or '' for e in r.get('entities', []) if e.get('curie')}
            labels.update({ch['to']: ch.get('text') or '' for ch in m.get('curie_changes') or [] if ch.get('to')})
            ents = {}
            def ent(c):
                k = kind_of(c)
                if k is None: raise Skip(f'unsupported ontology: {c.split(":")[0]}')
                ents[c] = (k, labels.get(c) or c)
                return (ename(c), c, labels.get(c) or c), k
            try:
                ctor = m.get('ctor')
                if ctor in (None, 'none'): raise Skip(f'ctor none, blocker {m.get("blocker")}')
                if m.get('blocker'): raise Skip(f'blocker {m["blocker"]} (with ctor)')
                if r['id'] in skip_ids: raise Skip('skip list (Lean rejected)')
                c = m.get('context') or {}
                subj_ctx, site_ctx = {}, {}
                for slot in ('taxon', 'stage'):
                    if c.get(slot): subj_ctx[slot] = ent(c[slot])[0]
                for slot in ('anatomy', 'cellType', 'component'):
                    if c.get(slot): site_ctx[slot] = ent(c[slot])[0]
                if c.get('condition'):
                    cd = c['condition']
                    if cd.get('kind') not in ('organism', 'environment'): raise Skip('condition without kind')
                    labels.setdefault(cd['curie'], cd.get('text') or '')
                    subj_ctx['condition'] = (cd['kind'], ent(cd['curie'])[0])
                s_, o_ = m.get('subject'), m.get('object')
                if not s_: raise Skip('no subject')
                S, ks = ent(s_)
                O, ko = ent(o_) if o_ else (None, None)
                tgt = m.get('target')
                site_on_target = O is not None and ctor in ('effect', 'mediatedBy') and tgt in ('amount', 'process', 'activity')
                S = in_ctx(S, ks, {**subj_ctx, **({} if site_on_target else site_ctx)})
                if site_on_target: O = in_ctx(O, ko, site_ctx)
                n, rel = m.get('n'), None
                if ctor in ('rel', 'notRel'):
                    need(ctor, O); rel = rel_of(m.get('relation'))
                    if not rel: raise Skip('relation not in RO')
                    claim = f'.{ctor} {rel_lean(rel)} {S[0]} {O[0]}'
                elif ctor in ('effect', 'mediatedBy'):
                    need(ctor, O, m.get('sign') in ('pos', 'neg'), tgt in TARGETS)
                    claim = f'.effect {S[0]} .{m["sign"]} (.{tgt} {O[0]})'
                    if ctor == 'mediatedBy':
                        need(ctor, m.get('mediator'), m.get('mediator_target') in TARGETS)
                        claim = f'.mediatedBy {S[0]} .{m["sign"]} (.{tgt} {O[0]}) (.{m["mediator_target"]} {ent(m["mediator"])[0][0]})'
                elif ctor in ('count', 'atLeast'):
                    need(ctor, O, n is not None)
                    if rel_of(m.get('relation')) not in (None, BY_LABEL['has part']): raise Skip(f'{ctor} with a relation other than has part')
                    claim = f'.{ctor} {S[0]} {O[0]} {n}'
                elif ctor == 'cardinality': need(ctor, n is not None); claim = f'.cardinality {S[0]} {n}'
                elif ctor in ('produces', 'consumes', 'yield'): need(ctor, O, n is not None); claim = f'.{ctor} {S[0]} {O[0]} {num(n)}'
                elif ctor == 'measure':
                    need(ctor, m.get('quality'))
                    if m.get('lo') is None or m.get('hi') is None: raise Skip('measure with an open end')
                    claim = f'.measure {S[0]} {ent(m["quality"])[0][0]} {num(m["lo"])} {num(m["hi"])} {q(m.get("unit"))}'
                elif ctor == 'less': need(ctor, O, m.get('quality')); claim = f'.less {S[0]} {O[0]} {ent(m["quality"])[0][0]}'
                else: raise Skip(f'unknown ctor {ctor}')
                if m.get('quant') in ('some', 'most'): claim = f'.quant .{m["quant"]} ({claim})'
            except Skip as e:
                skipped[str(e)] += 1; continue
            out.append(dict(id=r['id'], chapter=slug, text=(r.get('claim') or '')[:160], source=r.get('source') or '', claim=claim,
                            ents=ents, ctor=ctor, quant=m.get('quant'), rel=rel, sign=m.get('sign'), target=tgt,
                            subj=S[1:], obj=O[1:] if O else None, context=bool(subj_ctx or site_ctx)))
    return out, skipped, recs

def main():
    src, go_obo, out = sys.argv[1], sys.argv[2], pathlib.Path(sys.argv[3])
    out.mkdir(parents=True, exist_ok=True)
    stmts, skipped, recs = statements(src, go_namespaces(go_obo))
    r2 = {m.group(2): m.group(1) for m in re.finditer(r'^def e_\S+ : Entity \.(\w+) := ⟨"([^"]+)"', open(R2_ENTITIES).read(), re.M)}
    new = {}
    for s in stmts:
        for c, (k, l) in s['ents'].items():
            if c in r2: assert r2[c] == k, f'{c}: kind {k} here, {r2[c]} in R2'
            else: new.setdefault(c, (k, l))
    el = ['import BioLean.Lib.TextbookClaimsR2.Entities', '',
          '/-! Textbook entities new in round 3 (quantity and context, including context fillers). Generated by',
          '`scripts/textbook/emit_lean_m3.py`. Entities already in round 2 are reused from `BioLean.Textbook.R2`. -/', '',
          'namespace BioLean.Textbook.R3', '']
    el += [f'def {ename(c)} : Entity .{k} := ⟨{q(c)}, {q(l[:60])}⟩' for c, (k, l) in sorted(new.items())]
    (out / 'Entities.lean').write_text('\n'.join(el + ['', 'end BioLean.Textbook.R3', '']))
    by_ch = collections.defaultdict(list)
    for s in stmts: by_ch[s['chapter']].append(s)
    doc = lambda t: t.replace('-/', '- /').replace('/-', '/ -')
    for slug in sorted({pathlib.Path(p).stem for p in glob.glob(f'{src}/*.json')}):
        mod = ''.join(w.capitalize() for w in re.split(r'[^a-z0-9]+', slug) if w)
        defs = [f'/-- {doc(s["text"])} -/\ndef {re.sub(r"[^A-Za-z0-9_]", "_", s["id"])} : Statement where\n  id := {q(s["id"])}\n'
                f'  text := {q(s["text"])}\n  claim := {s["claim"]}\n'
                f'  evidence := [{{ pmid := 0, year := 2013, kind := .textbook, note := {q(s["source"][:200])} }}]' for s in by_ch[slug]]
        lines = ['import BioLean.Evidence', 'import BioLean.Lib.TextbookClaimsR3.Entities', '',
                 f'/-! Textbook claims, chapter `{slug}`, round 3 (quantity and context). Generated by `scripts/textbook/emit_lean_m3.py`. -/', '',
                 f'namespace BioLean.Textbook.R3.{mod}', 'open BioLean BioLean.Textbook.R2 BioLean.Textbook.R3', '', '-- statements'] + defs + ['', f'end BioLean.Textbook.R3.{mod}', '']
        (out / f'{mod}.lean').write_text('\n'.join(lines))
        print(f'{mod:40s} statements={len(defs)}')
    print('records', len(recs), 'emitted', len(stmts), '; new entities', len(new))
    print('by ctor', dict(collections.Counter(s['ctor'] for s in stmts).most_common()),
          '; quantified', sum(1 for s in stmts if s['quant']), '; with context', sum(s['context'] for s in stmts))
    print('skipped:', dict(sorted(skipped.items(), key=lambda kv: -kv[1])))

if __name__ == '__main__': main()
