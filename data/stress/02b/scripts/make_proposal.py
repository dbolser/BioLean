"""Program 02b: the round-3 annotations that the textbook's loop, homeostasis and set-point sentences would get.

Writes data/stress/02b/homeostasis_m3.json (a proposal; data/textbook/claims_m3 is not touched) and
data/stress/02b/proposal_check.lean (every proposed claim as Lean, to be compiled with `lake env lean`).

Selection: every sentence matching feedback|homeosta|set point|thermostat|equilibrium point, plus the loop
descriptions without those words (listed in EXTRA). Every record of a selected sentence appears once:
'replace' (new m3 for the record), 'add' (a new record from the same sentence, id with ~loop or #n),
'none' (stays ctor none, blocker named) or 'keep' (current annotation is right for this program).
A 'loop' block is the proposal's extension outside the core (sign as TEDDY, regulators with directions,
homeostatic flag); scripts/stress/closure_loops.py reads it. The m3 'ctor' is what the core can hold.
Usage (repo root): python3 data/stress/02b/scripts/make_proposal.py /tmp/obo/go-basic.obo
"""
import json, glob, re, sys, collections, pathlib
sys.path.insert(0, 'scripts/textbook')
import emit_lean_m3 as E

OUT = pathlib.Path('data/stress/02b')
B, EN, PH, CS = 'the-body-s-systems-', 'how-cells-obtain-energy-', 'photosynthesis-', 'cell-structure-and-function-'
WORDS = re.compile(r'feedback|homeosta|set point|thermostat|equilibrium point', re.I)
EXTRA = [B + x for x in ('m45534-23', 'm45534-89', 'm45534-90', 'm45534-188', 'm45534-205', 'm45536-30', 'm45537-19', 'm45537-52',
         'm45537-55', 'm45537-78', 'm45537-82', 'm45537-134', 'm45537-140', 'm45537-149', 'm45537-153', 'm45537-157', 'm45537-198', 'm45537-199',
         'm45537-200', 'm45537-201', 'm45537-225', 'm45537-227', 'm45537-236', 'm45537-237', 'm45537-240', 'm45537-250',
         'm45537-253', 'm45537-256', 'm45537-257', 'm45537-259', 'm45537-262', 'm45537-264', 'm45537-325', 'm45537-328',
         'm45537-333', 'm45539-82', 'm45539-89', 'm45539-95', 'm45539-102')] + \
        [EN + 'm45437-244', EN + 'm45437-247', EN + 'm45444-12', PH + 'm45448-84', CS + 'm45433-63']

NEG, POS = 'TEDDY_0000034', 'TEDDY_0000035'
BG = {'anatomy': 'UBERON:0000178'}
def m3(ctor, subject=None, target=None, obj=None, sign=None, ctx=None, blocker=None, conf='high', relation=None):
    c = {'taxon': None, 'anatomy': None, 'cellType': None, 'component': None, 'stage': None, 'condition': None}
    c.update(ctx or {})
    return {'ctor': ctor, 'quant': None, 'subject': subject, 'relation': relation, 'object': obj, 'sign': sign, 'target': target,
            'mediator': None, 'mediator_target': None, 'n': None, 'lo': None, 'hi': None, 'unit': None, 'quality': None,
            'context': c, 'blocker': blocker, 'curie_changes': [], 'confidence': conf}
def loop(sign, held, regs, homeostatic=True, extra_nodes=()):
    return {'sign': sign, 'teddy': NEG if sign == 'neg' else POS, 'held': held, 'regulators': [list(r) for r in regs],
            'homeostatic': homeostatic, 'extra_nodes': list(extra_nodes)}
H = 'homeostasis'
none = lambda blk, conf='high': m3('none', blocker=blk, conf=conf)
GLU = loop('neg', 'CHEBI:17234', [('PR:000009054', 'neg'), ('PR:P01275', 'pos')])
CA = loop('neg', 'CHEBI:29108', [('PR:000013429', 'pos'), ('PR:P01258', 'neg')])
TEMP = loop('neg', 'OBA:VT0005535', [('UBERON:0001898', 'neg')])

# (record id, action, m3 or None, loop or None, note)
P = [
 # --- glucose
 (B+'m45537-333', 'replace', m3(H, 'PR:000009054', 'amount', 'CHEBI:17234', ctx=BG), GLU, 'two regulators: one core claim per regulator; the loop block keeps the pair and the directions'),
 (B+'m45537-333#2', 'add', m3(H, 'PR:P01275', 'amount', 'CHEBI:17234', ctx=BG), GLU, 'second regulator of -333'),
 (B+'m45537-198', 'replace', m3(H, 'PR:000009054', 'amount', 'CHEBI:17234', ctx=BG), GLU, '"these hormones" are insulin and glucagon (-194 to -197)'),
 (B+'m45537-198#2', 'add', m3(H, 'PR:P01275', 'amount', 'CHEBI:17234', ctx=BG), GLU, 'second regulator of -198'),
 (B+'m45537-22', 'replace', m3(H, 'PR:000009054', 'amount', 'CHEBI:17234', ctx=BG), GLU, '"insulin and glucagon regulate blood-glucose levels"'),
 (B+'m45537-22#2', 'add', m3(H, 'PR:P01275', 'amount', 'CHEBI:17234', ctx=BG), GLU, 'second regulator of -22'),
 (B+'m45534-3', 'replace', m3(H, 'GO:0042593', 'amount', 'CHEBI:17234', ctx=BG, conf='medium'), None, 'no regulator named; GO:0042593 glucose homeostasis stands in as the regulator'),
 (B+'m45534-23', 'replace', m3(H, 'GO:0042593', 'amount', 'CHEBI:17234', ctx=BG, conf='medium'), None, 'the book states the round trip ("rise ... adjustments to lower them") with no regulator named'),
 (B+'m45537-157', 'replace', m3(H, 'CHEBI:24261', 'amount', 'CHEBI:17234', ctx=BG, conf='medium'), None, '"maintain proper blood-glucose levels between meals"; arms not stated'),
 (B+'m45537-55', 'none', none('set_point_no_value'), None, '"within a normal range": a set point with no number'),
 # --- calcium
 (B+'m45537-134~loop', 'add', m3(H, 'PR:P01258', 'amount', 'CHEBI:29108', ctx=BG), CA, 'both arms in one sentence (-134, -135); the literature disputes a physiological role (Hirsch 2001, case L04)'),
 (B+'m45537-140~loop', 'add', m3(H, 'PR:000013429', 'amount', 'CHEBI:29108', ctx=BG), CA, 'both arms in one sentence (-140, -141)'),
 (B+'m45534-5', 'replace', m3(H, 'GO:0055074', 'amount', 'CHEBI:29108', ctx=BG, conf='medium'), None, 'no regulator named; GO:0055074 calcium ion homeostasis stands in'),
 # --- temperature
 (B+'m45534-77', 'replace', m3(H, 'UBERON:0001898', 'phenotype', 'OBA:VT0005535', ctx={'taxon': 'NCBITaxon:40674'}), TEMP,
  'was effect pos on PATO:0000146 with the hypothalamus refined by "located in hypothalamus" and taxon Vertebrata: "maintains the set point" is not "raises"; Mammalia because the passage is about endotherms (birds are endotherms too: medium on the taxon)'),
 (B+'m45539-236', 'replace', m3(H, 'UBERON:0001898', 'phenotype', 'OBA:VT0005535'), TEMP, '"the hypothalamus is the body\'s thermostat"'),
 (B+'m45534-4', 'replace', m3(H, 'GO:0001659', 'phenotype', 'OBA:VT0005535', conf='medium'), None, 'no regulator named; GO:0001659 temperature homeostasis stands in'),
 (B+'m45534-13', 'replace', m3(H, 'GO:0001659', 'phenotype', 'OBA:VT0005535', conf='medium'), None, 'as -4'),
 (B+'m45534-14', 'replace', m3(H, 'GO:0050891', 'amount', 'CHEBI:15377', conf='medium'), None, 'water content; GO:0050891 multicellular organismal-level water homeostasis stands in'),
 (B+'m45534-78', 'none', none('disjunction'), None, 'effectors of the temperature loop ("vasodilation or vasoconstriction"); case T03'),
 (B+'m45534-79', 'none', none('disjunction'), None, 'effectors ("shivering or sweating"); case T03'),
 (B+'m45534-82', 'none', none('set_point_shift'), None, 'needs LClaim.shiftsSetPoint (Proto/Feedback.lean, case S02)'),
 (B+'m45534-85', 'none', none('set_point_shift'), None, 'pyrogens reset the set point; NCIT pyrogen is also outside the supported ontologies'),
 (B+'m45534-86', 'none', none('set_point_shift'), None, 'fever as a new equilibrium point'),
 # --- thyroid
 (B+'m45537-258', 'replace', m3('effect', 'CHEBI:60311', 'amount', 'PR:P01222', 'neg'), None, 'negative arm: "these hormones" (thyroid hormones of -257) inhibit pituitary signalling (TSH); hypothalamic TRH arm is #2'),
 (B+'m45537-258#2', 'add', m3('effect', 'CHEBI:60311', 'amount', 'CHEBI:35940', 'neg', conf='medium'), None, 'hypothalamic arm: TRH (CHEBI:35940 protirelin)'),
 (B+'m45537-258~loop', 'add', m3(H, 'UBERON:0002196', 'amount', 'CHEBI:60311', ctx={'anatomy': 'UBERON:0002046'}), loop('neg', 'CHEBI:60311', [('UBERON:0002196', 'pos'), ('PR:P01222', 'pos')]), 'loop closed by -257 and -258'),
 (B+'m45537-260', 'replace', m3('effect', 'CHEBI:18258', 'amount', 'PR:P01222', 'neg'), None, '"these hormones" are T3 and T4 (-259); T4 is #2'),
 (B+'m45537-260#2', 'add', m3('effect', 'CHEBI:30660', 'amount', 'PR:P01222', 'neg'), None, 'T4 arm'),
 (B+'m45537-260~loop', 'add', m3(H, 'PR:P01222', 'amount', 'CHEBI:18258', ctx={'anatomy': 'UBERON:0002046'}), loop('neg', 'CHEBI:18258', [('PR:P01222', 'pos'), ('UBERON:0002196', 'pos')]), 'loop closed by -129 and -260'),
 (B+'m45537-263', 'replace', m3('effect', 'MONDO:0005397', 'amount', 'CHEBI:30660', 'neg'), None, 'goiter: inability to form T4'),
 (B+'m45537-263#2', 'add', m3('effect', 'MONDO:0005397', 'amount', 'CHEBI:18258', 'neg', conf='low'), None, 'as written, but Chopra 1975 (PMID 1117981) finds serum T3 supranormal in endemic goiter: a candidate for false_as_written'),
 (B+'m45537-311', 'replace', m3('effect', 'MONDO:0005397', 'amount', 'CHEBI:30660', 'neg'), None, 'duplicate sentence of -263'),
 (B+'m45537-264', 'replace', m3('effect', 'MONDO:0005397', 'amount', 'PR:P01222', 'pos'), None, 'the loop compensating; also derivable from -263 and -258 (case L09)'),
 (B+'m45537-312', 'replace', m3('effect', 'MONDO:0005397', 'amount', 'PR:P01222', 'pos'), None, 'duplicate sentence of -264'),
 (B+'m45537-262', 'none', none('ungrounded_entity'), None, 'no MONDO class for iodine deficiency found on OLS4 (fetal iodine syndrome is narrower)'),
 (B+'m45537-310', 'none', none('ungrounded_entity'), None, 'duplicate of -262'),
 # --- ANP, EPO, leptin, aldosterone, glucocorticoids
 (B+'m45537-226', 'replace', m3('effect', 'OBA:0003648', 'amount', 'PR:P01160', 'pos'), None, '"a hormone" is the atrial natriuretic peptide that -227 acts with (PR:P01160)'),
 (B+'m45537-226~loop', 'add', m3(H, 'PR:P01160', 'phenotype', 'OBA:0003648'), loop('neg', 'OBA:0003648', [('PR:P01160', 'neg')]), 'loop closed by -226 and -227'),
 (B+'m45537-238~loop', 'add', m3(H, 'PR:000007141', 'amount', 'CHEBI:15379', ctx=BG, conf='medium'), loop('neg', 'CHEBI:15379', [('PR:000007141', 'pos')], extra_nodes=['GO:0030218']), 'sensor arm -238; the return arm (-240) ends on erythropoiesis, a process, so no chain closes (case L12)'),
 (B+'m45537-254', 'replace', m3('effect', 'PR:000009758', 'process', 'GO:0042755', 'neg'), None, '"reducing the urge for further eating"; the R2 entity GO:0042755 is eating behavior'),
 (B+'m45537-251~loop', 'add', m3(H, 'PR:000009758', 'process', 'GO:0042755', conf='medium'), loop('neg', 'GO:0042755', [('PR:000009758', 'neg')]), 'closed by -251 and -254; mostly defends against a fall in leptin (Ahima 1996, case L17)'),
 (B+'m45537-253', 'none', none('ungrounded_entity'), None, 'satiety has no GO process; -254 carries the arm'),
 (B+'m45537-150', 'none', none('signless_regulation'), None, '"aldosterone regulates the concentration of ions": no sign, so no arm and no loop (case L16)'),
 (B+'m45537-236', 'none', none('class_level_loop'), None, '"two of these hormones" are not named'),
 # --- breathing, kidney, stomata, ATP
 (B+'m45536-30', 'replace', m3(H, 'UBERON:0000955', 'amount', 'CHEBI:16526', ctx=BG, conf='medium'), loop('neg', 'CHEBI:16526', [('UBERON:0000955', 'neg')], extra_nodes=['GO:0007585']), '"regulated by the respiratory center in the brain in response to ... carbon dioxide"; no UBERON class for the respiratory centre'),
 (B+'m45536-31', 'replace', m3('effect', 'CHEBI:16526', 'process', 'GO:0007585', 'pos', ctx=BG), None, 'sensor arm: blood CO2 raises breathing; the return arm (breathing lowers CO2) is not in the book'),
 (B+'m45534-190~loop', 'add', m3(H, 'UBERON:0002113', 'amount', 'CHEBI:24870', ctx={'anatomy': 'UBERON:0006314', 'taxon': 'NCBITaxon:40674'}, conf='medium'), None, '"maintain the dissolved ion concentrations of body fluids"'),
 (PH+'m45448-84~loop', 'add', m3(H, 'GO:0090332', 'amount', 'CHEBI:15377', ctx={'taxon': 'NCBITaxon:33090'}, conf='medium'), loop('neg', 'CHEBI:15377', [('GO:0090332', 'neg')], extra_nodes=['GO:0010148']), '"close their stomata to conserve water": the sensor arm is implicit (Buckley 2005, hydro-active local feedback)'),
 (EN+'m45437-244~loop', 'add', m3(H, 'GO:0006007', 'amount', 'CHEBI:15422'), loop('neg', 'CHEBI:15422', [('GO:0006007', 'pos'), ('CHEBI:16761', 'pos')]), 'product inhibition: sugar catabolism makes ATP and ATP inhibits it; the held is really the energy charge, a ratio (case L19)'),
 # --- action potential (positive), class-level and definitions
 (B+'m45539-88', 'none', none('positive_loop'), loop('pos', 'GO:0051899', [('GO:0005248', 'pos'), ('CHEBI:29101', 'pos')], homeostatic=False), 'the one "positive feedback" sentence; the arms are -89, -90, -83; Claim.homeostasis cannot hold a positive loop'),
 (B+'m45539-96', 'none', none('process_description'), None, 'K+ efflux: the missing arm of the negative loop (case P05)'),
 (EN+'m45437-238', 'none', none('class_level_loop'), None, '"products of their own reactions": a bound variable'),
 (EN+'m45437-242', 'none', none('class_level_loop'), None, 'each amino acid inhibits its own synthesis: a bound variable, not "amino acid holds amino acid"'),
 (EN+'m45437-243', 'none', none('class_level_loop'), None, 'as -242 for nucleotides'),
 (EN+'m45444-63', 'none', none('class_level_loop'), None, ''),
 (B+'m45534-6', 'none', none('class_level_loop'), None, ''),
 (B+'m45534-18', 'none', none('class_level_loop'), None, ''),
 (B+'m45534-21', 'none', none('class_level_loop'), None, ''),
 (B+'m45534-217', 'none', none('class_level_loop'), None, ''),
 (B+'m45537-255', 'none', none('class_level_loop'), None, 'hormones in general'),
 (B+'m45537-256', 'none', none('class_level_loop'), None, ''),
 (B+'m45537-268', 'none', none('class_level_loop'), None, ''),
 (B+'m45537-269', 'none', none('class_level_loop'), None, '"rising levels of a hormone inhibit its further release": every hormone x lowers x, a bound variable'),
 (B+'m45537-78', 'none', none('class_level_loop'), None, 'receptor up-regulation: a loop on sensitivity, class-level'),
 (B+'m45537-82', 'none', none('class_level_loop'), None, 'receptor down-regulation'),
 (B+'m45537-325', 'none', none('class_level_loop'), None, ''),
 (B+'m45537-328', 'none', none('class_level_loop'), None, ''),
 (B+'m45539-231', 'none', none('not_homeostasis'), None, 'cortico-thalamic "feedback" is a connection, not a regulated variable (case N03)'),
 (B+'m45539-232', 'none', none('not_homeostasis'), None, 'as -231'),
]
DEF_BLOCKERS = {'definition_only', None}

def main(go_obo):
    recs, order = {}, []
    for p in sorted(glob.glob('data/textbook/claims_m2/*.json')):
        for r in json.load(open(p)): recs[r['id']] = r; order.append(r['id'])
    cur3 = {}
    for p in sorted(glob.glob('data/textbook/claims_m3/*.json')):
        for r in json.load(open(p)): cur3[r['id']] = r.get('m3')
    by_src = collections.defaultdict(list)
    for i in order: by_src[recs[i]['source']].append(i)
    chosen = [s for s, ids in by_src.items() if WORDS.search(s) or any(i in EXTRA for i in ids)]
    chosen.sort(key=lambda s: order.index(by_src[s][0]))
    planned = collections.defaultdict(list)
    for rid, act, m, lp, note in P:
        base = rid.split('~')[0].split('#')[0]
        assert base in recs, f'unknown record {rid}'
        planned[base].append((rid, act, m, lp, note))
    sentences, missing = [], set(planned)
    for s in chosen:
        rows = []
        for i in by_src[s]:
            m2 = recs[i].get('m2') or {}
            cur = cur3.get(i) or m2
            def short(m): return None if not m else {k: m.get(k) for k in ('ctor', 'subject', 'relation', 'sign', 'target', 'object', 'blocker')} | {'context': {k: v for k, v in (m.get('context') or {}).items() if v}}
            entries = planned.get(i) or [(i, 'keep' if (cur.get('ctor') not in (None, 'none') or recs[i]['bin'] == 'not_claim') else 'none', None, None, '')]
            missing.discard(i)
            for rid, act, m, lp, note in entries:
                if act == 'none' and m is None: m = none(cur.get('blocker') or 'definition_only')
                rows.append({'id': rid, 'action': act, 'claim': recs[i]['claim'], 'current': short(cur), 'current_round': 'm3' if i in cur3 else 'm2',
                             'm3': m, 'loop': lp, 'note': note})
        sentences.append({'first_id': by_src[s][0], 'source': s, 'words': sorted({w.lower() for w in WORDS.findall(s)}), 'records': rows})
    assert not missing, f'planned but not in a chosen sentence: {missing}'
    allrows = [r for s in sentences for r in s['records']]
    summary = {'sentences': len(sentences), 'with_loop_words': sum(1 for s in sentences if s['words']),
               'records': len(allrows), 'by_action': dict(collections.Counter(r['action'] for r in allrows)),
               'homeostasis_claims': sum(1 for r in allrows if r['m3'] and r['m3']['ctor'] == H),
               'new_or_fixed_arms': sum(1 for r in allrows if r['m3'] and r['m3']['ctor'] == 'effect' and r['action'] in ('replace', 'add')),
               'blockers': dict(collections.Counter(r['m3']['blocker'] for r in allrows if r['m3'] and r['m3']['ctor'] == 'none')),
               'loops_with_sign': sum(1 for r in allrows if r['loop'])}
    for w in ('negative feedback', 'positive feedback', 'homeosta', 'set point'):
        summary[f'sentences matching "{w}"'] = sum(1 for s in sentences if re.search(w, s['source'], re.I))
    json.dump({'about': 'Program 02b proposal: round-3 annotations for the loop sentences. Not applied to claims_m3. The m3 block is what the core can hold; the loop block is outside the core.',
               'summary': summary, 'sentences': sentences}, open(OUT / 'homeostasis_m3.json', 'w'), indent=1, ensure_ascii=False)
    print(json.dumps(summary, indent=1))
    # --- the same records in claims_m3 format, for scripts/stress/closure_loops.py --proposal (an overlay, never claims_m3)
    ov = []
    for s in sentences:
        for r in s['records']:
            if r['action'] in ('replace', 'add', 'none') and r['m3']:
                src = recs[r['id'].split('~')[0].split('#')[0]]
                ov.append({'id': r['id'], 'module': src['module'], 'source': src['source'], 'claim': r['claim'], 'entities': src.get('entities', []),
                           'm3': r['m3'], 'loop': r['loop'], 'action': r['action']})
    (OUT / 'proposal_m3').mkdir(exist_ok=True)
    json.dump(ov, open(OUT / 'proposal_m3' / 'homeostasis.json', 'w'), indent=1, ensure_ascii=False)
    print('overlay records:', len(ov))
    # --- Lean check: every proposed homeostasis or effect claim, through the emitter's own context logic
    go_ns = E.go_namespaces(go_obo)
    def kind(c):
        p = c.split(':')[0]
        return E.KIND_BY_NS.get(go_ns.get(c)) if p == 'GO' else E.PREFIX_KIND.get(p)
    ents, defs = {}, []
    def ent(c):
        k = kind(c); assert k, f'no kind for {c}'
        ents[c] = k; return (E.ename(c), c, c), k
    for r in allrows:
        m = r['m3']
        if not m or m['ctor'] not in (H, 'effect') or r['action'] == 'keep': continue
        c = m['context']; subj_ctx, site_ctx = {}, {}
        if c.get('taxon'): subj_ctx['taxon'] = ent(c['taxon'])[0]
        for slot in ('anatomy', 'cellType', 'component'):
            if c.get(slot): site_ctx[slot] = ent(c[slot])[0]
        S, ks = ent(m['subject']); O, ko = ent(m['object'])
        on_target = m['target'] in ('amount', 'process', 'activity')
        S = E.in_ctx(S, ks, {**subj_ctx, **({} if on_target else site_ctx)})
        if on_target: O = E.in_ctx(O, ko, site_ctx)
        claim = f'.homeostasis {S[0]} (.{m["target"]} {O[0]})' if m['ctor'] == H else f'.effect {S[0]} .{m["sign"]} (.{m["target"]} {O[0]})'
        name = re.sub(r'[^A-Za-z0-9_]', '_', r['id'])
        defs.append(f'def {name} : Claim := {claim}\n#eval IO.println s!"LEAN\\t{r["id"]}\\t{{{name}}}"')
    lines = ['import BioLean.Claim', 'import BioLean.Context', '', '/-! Generated by data/stress/02b/scripts/make_proposal.py: every proposed homeostasis and effect',
             'claim of homeostasis_m3.json, built with the emitter\'s context logic. Compile with `lake env lean`. -/', '',
             'namespace BioLean.Stress.FeedbackProposal', 'open BioLean', '']
    lines += [f'def {E.ename(c)} : Entity .{k} := ⟨{E.q(c)}, {E.q(c)}⟩' for c, k in sorted(ents.items())] + [''] + defs + ['', 'end BioLean.Stress.FeedbackProposal', '']
    (OUT / 'proposal_check.lean').write_text('\n'.join(lines))
    print('Lean check claims:', len(defs))

if __name__ == '__main__': main(sys.argv[1])
