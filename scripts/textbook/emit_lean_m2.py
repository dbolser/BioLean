"""Round 2: emit Lean Statements from the structured `m2` annotations (subject/relation/object CURIEs),
one module per chapter. No string parsing, no positional guessing.
Usage: emit_lean_m2.py <claims_m2_dir> <go.obo> <out_dir>"""
import json, glob, re, sys, collections, pathlib
src, go_obo, out = sys.argv[1], sys.argv[2], pathlib.Path(sys.argv[3])
out.mkdir(parents=True, exist_ok=True)
skip = {l.split('\t')[0].strip() for l in open('data/textbook/r2_skip.tsv') if l.strip() and not l.startswith('#')} if pathlib.Path('data/textbook/r2_skip.tsv').exists() else set()
go_ns = {}; cur = None
for line in open(go_obo, encoding='utf-8'):
    if line.startswith('id: GO:'): cur = line[4:].strip()
    elif cur and line.startswith('namespace: '): go_ns[cur] = line[11:].strip(); cur = None
KIND_BY_NS = {'biological_process': 'process', 'molecular_function': 'function', 'cellular_component': 'component'}
PREFIX_KIND = {'CHEBI': 'chemical', 'PR': 'protein', 'UniProt': 'protein', 'UNIPROT': 'protein', 'UniProtKB': 'protein',
               'HGNC': 'gene', 'NCBIGene': 'gene', 'SO': 'gene', 'MGI': 'gene', 'HP': 'phenotype', 'MP': 'phenotype',
               'PATO': 'phenotype', 'OBA': 'phenotype', 'MONDO': 'disease', 'DOID': 'disease', 'UBERON': 'anatomy',
               'CL': 'cellType', 'NCBITaxon': 'taxon'}
def kind_of(c):
    if not c: return None
    p = c.split(':')[0]
    return KIND_BY_NS.get(go_ns.get(c)) if p == 'GO' else PREFIX_KIND.get(p)
ro = {}
for m in re.finditer(r'\(⟨\.(ro|bfo), (\d+), false⟩, "([^"]+)"\)', open('BioLean/RO.lean').read()):
    ro[m.group(3).lower()] = f'⟨.{m.group(1)}, {m.group(2)}, false⟩'
for k in ('is_a', 'is a', 'subclass of', 'isa'): ro[k] = 'Rel.isA'
def rel_term(l):
    if not l: return None
    l = l.strip().lower().replace('_', ' ')
    return ro.get(l) or ro.get(l.replace(' ', '_')) or ro.get(l.replace('inverse(', '').rstrip(')'))
def ename(c): return 'e_' + re.sub(r'[^A-Za-z0-9]', '_', c)
def q(s): return '"' + (s or '').replace('\\', '\\\\').replace('"', '\\"') + '"'

stats = collections.Counter(); skipped = collections.Counter()
by_file = collections.defaultdict(list)
all_ents = {}   # curie -> (kind, label), shared across chapters
chapter_defs = {}
for p in sorted(glob.glob(f'{src}/*.json')):
    stem = re.sub(r'-[12]$', '', pathlib.Path(p).stem)
    by_file[stem].extend(json.load(open(p)))
for slug, recs in by_file.items():
    mod = ''.join(w.capitalize() for w in re.split(r'[^a-z0-9]+', slug) if w)
    ents, defs = {}, []
    labels = {}
    for r in recs:
        for e in r.get('entities', []):
            if e.get('curie'): labels.setdefault(e['curie'], e.get('text') or '')
        for ch in (r.get('m2') or {}).get('curie_changes', []) or []:
            if ch.get('to'): labels.setdefault(ch['to'], ch.get('text') or '')
    for r in recs:
        m2 = r.get('m2')
        if r.get('bin') == 'not_claim' or not m2: continue
        stats['claims'] += 1
        if r['id'] in skip: skipped['skip list (Lean rejected)'] += 1; continue
        ctor = m2.get('ctor')
        if ctor in (None, 'none'):
            skipped[f'blocker:{m2.get("blocker")}'] += 1; continue
        if m2.get('blocker') == 'context_required':
            skipped['blocker:context_required'] += 1; continue
        s_, o_ = m2.get('subject'), m2.get('object')
        ks, ko = kind_of(s_), kind_of(o_)
        if not (s_ and o_) or ks is None or ko is None:
            skipped['unsupported ontology or missing CURIE'] += 1; continue
        used = [(s_, ks), (o_, ko)]
        if ctor in ('rel', 'notRel'):
            rt = rel_term(m2.get('relation'))
            if not rt: skipped['relation not in RO'] += 1; continue
            claim = f'.{ctor} {rt} {ename(s_)} {ename(o_)}'
        else:
            sign, tgt = m2.get('sign'), m2.get('target')
            if sign not in ('pos', 'neg') or tgt not in ('activity', 'amount', 'process', 'phenotype', 'site'):
                skipped['effect without sign/target'] += 1; continue
            claim = f'.effect {ename(s_)} .{sign} (.{tgt} {ename(o_)})'
            if ctor == 'mediatedBy':
                md, mt = m2.get('mediator'), m2.get('mediator_target')
                km = kind_of(md)
                if not md or km is None or mt not in ('activity', 'amount', 'process', 'phenotype', 'site'):
                    skipped['mediatedBy without mediator'] += 1; continue
                used.append((md, km))
                claim = f'.mediatedBy {ename(s_)} .{sign} (.{tgt} {ename(o_)}) (.{mt} {ename(md)})'
        for c, k in used: ents.setdefault(c, (k, labels.get(c, c))); all_ents.setdefault(c, (k, labels.get(c, c)))
        sid = re.sub(r'[^A-Za-z0-9_]', '_', r['id'])
        text = (r.get('claim') or '')[:160]
        defs.append(f'/-- {text} -/\ndef {sid} : Statement where\n  id := {q(r["id"])}\n  text := {q(text)}\n  claim := {claim}\n'
                    f'  evidence := [{{ pmid := 0, year := 2013, kind := .textbook, note := {q((r.get("source") or "")[:200])} }}]')
        stats['emitted'] += 1
    chapter_defs[mod] = (slug, defs, len(ents))
# shared entities
el = ['import BioLean.Ontology', '', '/-! All textbook entities, round 2. Generated by `scripts/textbook/emit_lean_m2.py`. -/', '',
      'namespace BioLean.Textbook.R2', '']
el += [f'def {ename(c)} : Entity .{k} := ⟨{q(c)}, {q(l[:60])}⟩' for c, (k, l) in sorted(all_ents.items())]
el += ['', 'end BioLean.Textbook.R2', '']
(out / 'Entities.lean').write_text('\n'.join(el))
for mod, (slug, defs, ne) in chapter_defs.items():
    lines = ['import BioLean.Evidence', 'import BioLean.Lib.TextbookClaimsR2.Entities', '',
             f'/-! Textbook claims, chapter `{slug}`, round 2 (structured). Generated by `scripts/textbook/emit_lean_m2.py`. -/', '',
             f'namespace BioLean.Textbook.R2.{mod}', 'open BioLean.Textbook.R2', '', '-- statements'] + defs + ['', f'end BioLean.Textbook.R2.{mod}', '']
    (out / f'{mod}.lean').write_text('\n'.join(lines))
    print(f'{mod:40s} entities={ne} statements={len(defs)}')
print('shared entities', len(all_ents))
print('claims', stats['claims'], 'emitted', stats['emitted'])
print('skipped:', dict(sorted(skipped.items(), key=lambda kv: -kv[1])))
