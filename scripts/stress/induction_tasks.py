"""Program 10c: the stress set. 37 induction tasks over BioLean's textbook facts, run against today's closure search
and two rule learners. Writes data/stress/10c/tasks_observed.json (cases.tsv is built from it by induction_cases.py).

A task holds out some textbook statements, gives the rest, and asks two kinds of question:
  pos  facts that are true (held out, or true but unstated, with a checked source): should be concluded;
  neg  facts that are false (checked source): must not be concluded.
Mark, for each system: FAIL if any neg is concluded; else PASS if every pos is concluded (a task with no pos
passes by staying silent on its negs); else SILENT. INEXPRESSIBLE when the task's predicate is not in the
vocabulary (a synthetic predicate the system was not given).
Systems:
  closure   today's BioLean search (induction_closure.py: the closure.py rules, depth 4) over the remaining facts
  mine      induction_mine.py with the ontology is_a closure as background, support >= 2, PCA >= 0.5
  mine_tb   the same with textbook is_a only
  amie      AMIE 3.0, path rules only, textbook background, PCA >= 0.5
`extra` facts are synthetic (an invented predicate, written by hand from a textbook sentence) and go to the
learners only: the closure has no rule that reads them. Rule judgements (true biology or artefact) are in JUDGE,
written after reading each rule's support and predictions (data/stress/10c/rule_judgements.tsv); they do not change
marks. The miners' heads need at least 4 facts (induction_mine.KB.heads), so has_abundant (3 facts, I31, I32) is never a head."""
import sys, os, json, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import induction_closure as IC, induction_mine as M, induction_amie as A

OUT = IC.REPO / 'data/stress/10c'
THETA = 0.5
CB, S = 'cell-structure-and-function', 'the-body-s-systems'
EN, PH, MB = 'how-cells-obtain-energy', 'photosynthesis', 'molbio'
RE, IN = 'reproduction-at-the-cellular-level', 'the-cellular-basis-of-inheritance'


def T(*task, **kw): return dict(zip(('id', 'family', 'probes'), task), **kw)


TASKS = [
    # --- A. deduction suffices: the held-out sentence is a theorem of the rest (fair cases for today's core)
    T('I01', 'deduction', 'part_of transitivity', hold=[f'{S}-m45539-202'],
      pos=[('part_of', 'UBERON:0016525', 'UBERON:0000955')], src='OpenStax, the-body-s-systems-m45539-202 (frontal lobe part of brain)'),
    T('I02', 'deduction', 'has_part transitivity', hold=[f'{S}-m45534-128'],
      pos=[('has_part', 'UBERON:0002113', 'UBERON:0001285')], src='OpenStax, the-body-s-systems-m45534-128 (kidney has nephrons)'),
    T('I03', 'deduction', 'is_a inheritance of an effect (isaInheritEffect)', hold=[f'{IN}-m45467-119'],
      pos=[('eff_pos_phenotype', 'MONDO:0700064', 'PATO:0000718')], src='OpenStax, the-cellular-basis-of-inheritance-m45467-119 (aneuploidy is often lethal)'),
    T('I04', 'deduction', 'is_a inheritance of capable_of', hold=[f'{PH}-m45448-90'],
      pos=[('capable_of', 'CHEBI:28966', 'GO:0009765')], src='OpenStax, photosynthesis-m45448-90 (chlorophyll absorbs light)'),
    T('I05', 'deduction', 'RO chain occurs_in o part_of', hold=[f'{PH}-m45453-60'],
      pos=[('occurs_in', 'GO:0019684', 'GO:0009507')], src='OpenStax, photosynthesis-m45453-60 (light reactions in the chloroplast)'),
    T('I06', 'deduction', 'viaActivity chain (drug inhibits enzyme)', hold=[f'{EN}-m45437-202'],
      pos=[('eff_neg_amount', 'CHEBI:87631', 'CHEBI:16113')], src='OpenStax, how-cells-obtain-energy-m45437-202 (statins lower cholesterol)'),
    # --- B. class rules: "every D has r C", i.e. a missing fact about a class
    T('I07', 'class', 'cerebral lobes are parts of the cortex (true class rule)', hold=[f'{S}-m45539-395'],
      pos=[('part_of', 'UBERON:0016525', 'UBERON:0000956')], src='OpenStax, the-body-s-systems-m45539-395 (frontal lobe part of cerebral cortex)'),
    T('I08', 'class', 'brain regions (class broader than the rule)', hold=[f'{S}-m45539-415'],
      pos=[('part_of', 'UBERON:0001897', 'UBERON:0000955')], neg=[('part_of', 'UBERON:0002240', 'UBERON:0000955')],
      src='OpenStax, the-body-s-systems-m45539-415 (thalamus part of brain); spinal cord is connected to, not part of, the brain (the-body-s-systems-m45539-338)'),
    T('I09', 'class', 'anti-inflammatory drugs (class too broad: medications)', hold=[f'{S}-m45538-201'],
      pos=[('eff_neg_process', 'CHEBI:15365', 'GO:0006954')], neg=[('eff_neg_process', 'CHEBI:27584', 'GO:0006954')],
      src='OpenStax, the-body-s-systems-m45538-201 (aspirin reduces inflammation); aldosterone promotes inflammation (Brown 2013, PMID 23774812)'),
    T('I10', 'class', 'cell wall composition by lineage', hold=[f'{CB}-m45432-323'],
      pos=[('has_part', 'GO:0009505', 'CHEBI:18246')],
      neg=[('has_part', 'GO:0005618&RO:0002162=(NCBITaxon:2)', 'CHEBI:18246'), ('has_part', 'GO:0009277', 'CHEBI:18246')],
      src='OpenStax, cell-structure-and-function-m45432-323 (plant cell wall cellulose); bacterial walls are peptidoglycan (m45429-21); fungal walls are chitin (Gow 2017, PMID 28513415)'),
    T('I11', 'class', 'phases of mitosis (ontology shape: the LGG is "cell cycle phase")', hold=[f'{RE}-m45461-202'],
      pos=[('part_of', 'GO:0000089', 'GO:0140014')], neg=[('part_of', 'GO:0051320', 'GO:0140014')],
      src='OpenStax, reproduction-at-the-cellular-level-m45461-202 (metaphase is a stage of mitosis); S phase is part of interphase (m45461-211)'),
    T('I12', 'class', 'islet cell types (class too broad: secretory cell)', hold=[f'{S}-m45537-196'],
      pos=[('part_of', 'CL:0000169', 'UBERON:0000006')], neg=[('part_of', 'CL:0002258', 'UBERON:0000006')],
      src='OpenStax, the-body-s-systems-m45537-196 (beta cells in the islets); thyroid follicular cells make thyroxine in the thyroid (m45537-123)'),
    T('I13', 'class', 'which reproductive processes halve ploidy', hold=[f'{IN}-m45466-202'],
      pos=[('eff_neg_phenotype', 'GO:0007127', 'PATO:0001374')], neg=[('eff_neg_phenotype', 'GO:0009566', 'PATO:0001374')],
      src='OpenStax, the-cellular-basis-of-inheritance-m45466-202 (meiosis I halves the chromosome number); fertilisation restores diploidy (m45465-58)'),
    T('I14', 'class', 'tumour suppressors (needs an invented class)', hold=[f'{RE}-m45462-36'],
      pos=[('eff_neg_process', 'PR:000013773', 'GO:0007049')], neg=[('eff_neg_process', 'PR:000007968', 'GO:0007049')],
      src='OpenStax, reproduction-at-the-cellular-level-m45462-36 (Rb halts the cell cycle; Weinberg 1995, PMID 7736585); growth hormone promotes growth (m45537-110 protein synthesis); GH acts as a cytokine that drives proliferation of immune cells (Jeay 2002, PMID 11911939)'),
    T('I15', 'class', 'which metabolic processes make ATP (catabolic vs anabolic)', hold=[f'{EN}-m45440-75'],
      pos=[('eff_pos_amount', 'GO:0006096', 'CHEBI:15422')], neg=[('eff_pos_amount', 'GO:0005978', 'CHEBI:15422'), ('eff_pos_amount', 'GO:0006094', 'CHEBI:15422')],
      src='OpenStax, how-cells-obtain-energy-m45440-75 (glycolysis makes ATP); anabolic pathways consume energy (how-cells-obtain-energy m45437, anabolism); gluconeogenesis uses ATP and GTP (Reactome R-HSA-70263)'),
    T('I16', 'class', 'a property of a species learned from its own contexts', hold=[f'{CB}-m45433-19'],
      pos=[('capable_of', 'NCBITaxon:12721', 'GO:0046718')], src='OpenStax, cell-structure-and-function-m45433-19 (HIV enters host cells)'),
    T('I17', 'class', 'nucleus: a eukaryote rule with stated and unstated exceptions', hold=[f'{S}-m45538-228'],
      pos=[('has_part', 'CL:0000192', 'GO:0005634')],
      neg=[('has_part', 'CL:0000520', 'GO:0005634'), ('has_part', 'CL:0000232&RO:0002162=(NCBITaxon:40674)', 'GO:0005634')],
      src='OpenStax, the-body-s-systems-m45538-228 (smooth muscle cell has one nucleus); prokaryotes lack a nucleus (m45429-15, stated as a negation); mature mammalian red cells lack a nucleus (Ji 2011, PMID 21592797)'),
    # --- C. path rules (variables only): beyond the core's rules
    T('I18', 'path', 'an output that derives from y means y is an input', hold=[f'{PH}-m45453-20'],
      pos=[('has_input', 'GO:0019253', 'CHEBI:16526')], src='OpenStax, photosynthesis-m45453-20 (the Calvin cycle takes in CO2)'),
    T('I19', 'path', 'descent as analogy: an organelle does what its ancestor does', hold=[],
      pos=[], neg=[('capable_of', 'GO:0005739', 'GO:0015979')],
      src='Mitochondria do not photosynthesise; the textbook gives mitochondria cellular respiration (m45432-313) and chloroplasts photosynthesis (m45432-229)'),
    T('I20', 'path', 'inverting a class-level has_part', hold=[f'{CB}-m45432-112'],
      pos=[], neg=[('part_of', 'CHEBI:16247', 'GO:0031966')],
      src='Not every phospholipid is part of a mitochondrial membrane (STATUS lesson 13); m45432-198 says the reverse direction only'),
    T('I21', 'path', 'upward: a superclass takes a subclass\'s parthood', hold=[],
      pos=[], neg=[('part_of', 'UBERON:0001474', 'UBERON:0003252')],
      src='Not every bone is part of the rib cage: the axial skeleton alone has skull, ear, hyoid, vertebral and rib bones (the-body-s-systems-m45538-267); the rule reads "a rib is a bone, ribs are part of the rib cage" upwards'),
    T('I22', 'path', 'a whole does what its part does', hold=[f'{CB}-m45432-229'],
      pos=[('capable_of', 'GO:0009507', 'GO:0015979')], src='OpenStax, cell-structure-and-function-m45432-229 (chloroplasts do photosynthesis)'),
    T('I23', 'path', 'organ part_of system, system capable_of P => organ involved in P (the brief\'s example)', hold=[],
      pos=[('involved_in', 'UBERON:0001876', 'GO:0007613')],
      src='The amygdala modulates memory consolidation (McGaugh 2004, PMID 15217324); m45539-244 amygdala part of limbic system, m45539-242 limbic system capable of memory'),
    T('I24', 'path', 'parthood read as causation', hold=[],
      pos=[], neg=[('eff_pos_amount', 'UBERON:0001707', 'CHEBI:15379')],
      src='The nasal cavity warms and humidifies air (the-body-s-systems-m45536-38); gas exchange occurs only in the alveoli (m45536-66); docs/holes.md "parthood read as causation"'),
    # --- D. taxon-wise rules
    T('I25', 'taxon', 'bacterial DNA sits in the nucleoid; bacterial ribosomes do not', hold=[f'{MB}-m45473-76'],
      pos=[('located_in', 'GO:0005694&RO:0002162=(NCBITaxon:2)', 'GO:0009295')],
      neg=[('located_in', 'GO:0005840&RO:0002162=(NCBITaxon:2)', 'GO:0009295'), ('located_in', 'GO:0005694&RO:0002162=(NCBITaxon:2)', 'GO:0005634')],
      src='OpenStax, molbio-m45473-76 (prokaryotic chromosome in the nucleoid); in E. coli only 10-15% of ribosomes lie within the dense nucleoid lobes (Bakshi 2012, PMID 22624875), so not every bacterial ribosome is in the nucleoid; prokaryotes have no nucleus (cell-structure-and-function-m45429-15), so their chromosome is not in one'),
    T('I26', 'taxon', 'eukaryotic genetic material sits in the nucleus; eukaryotic ribosomes do not', hold=[f'{RE}-m45455-16'],
      pos=[('located_in', 'GO:0005694&RO:0002162=(NCBITaxon:2759)', 'GO:0005634')],
      neg=[('located_in', 'GO:0005840&RO:0002162=(NCBITaxon:2759)', 'GO:0005634')],
      src='OpenStax, reproduction-at-the-cellular-level-m45455-16 (eukaryotic chromosomes in the nucleus); eukaryotic ribosomes are in the cytoplasm and on the ER (molbio-m45479-21, -22)'),
    T('I27', 'taxon', 'plant parts and the cell wall', hold=[f'{CB}-m45432-355'],
      pos=[('has_part', 'GO:0005618&RO:0002162=(NCBITaxon:33090)', 'CHEBI:18246')],
      src='OpenStax, cell-structure-and-function-m45432-355 (plant cell walls contain cellulose)'),
    # --- E. feature rules: h(x,C) <= b(x,D)
    T('I28', 'feature', 'CO2 in, sugar out', hold=[f'{PH}-m45453-51'],
      pos=[('has_output', 'GO:0019253', 'CHEBI:16646')], src='OpenStax, photosynthesis-m45453-51 (the Calvin cycle makes sugars)'),
    T('I29', 'feature', 'glucose in, ATP up (catabolic only)', hold=[],
      pos=[], neg=[('eff_pos_amount', 'GO:0006633&RO:0002162=(NCBITaxon:131567&RO:0002573=(BLN:glycogen_full))', 'CHEBI:15422')],
      src='Fatty acid synthesis consumes ATP and NADPH (Reactome R-HSA-75105); the textbook says excess glucose is stored as fat (how-cells-obtain-energy)'),
    # --- F. predicate invention: the G1 hole (docs/holes.md)
    T('I30', 'invention', 'G1 organelle abundance, as the core holds it today', hold=[],
      pos=[('has_abundant', 'CL:0000187', 'GO:0005739')], inexpressible=True,
      src='OpenStax, cell-structure-and-function-m45432-203 (muscle cells have a very high concentration of mitochondria); not in Lean (no abundance constructor)'),
    T('I31', 'invention', 'G1 with the two invented predicates given by hand (synthetic facts)', hold=[],
      pos=[('has_abundant', 'CL:0000187', 'GO:0005739')],
      extra=[('has_abundant', 'CL:0000765', 'GO:0005840', 'synthetic: m45432-189 (ribosomes abundant in immature red cells)'),
             ('has_abundant', 'CL:0000151', 'GO:0005794', 'synthetic: m45432-155 (secretory cells have abundant Golgi)'),
             ('high_demand', 'CL:0000765', 'GO:0006412', 'synthetic: m45432-189 (for the synthesis of hemoglobin)'),
             ('high_demand', 'CL:0000151', 'GO:0046903', 'synthetic: m45432-155 (a great deal of secretory activity)'),
             ('high_demand', 'CL:0000187', 'GO:0006754', 'synthetic: m45432-203 (muscle cells need a lot of energy)'),
             ('capable_of', 'GO:0005794', 'GO:0046903', 'synthetic: GO:0005794 definition (packages proteins for secretion)')],
      src='OpenStax, cell-structure-and-function-m45432-155, -189, -203; GO:0005794 definition on OLS4'),
    T('I32', 'invention', 'G1 with capability as a proxy for demand (no invented demand predicate)', hold=[],
      pos=[], neg=[('has_abundant', 'CL:0000000', 'GO:0005739')],
      extra=[('has_abundant', 'CL:0000765', 'GO:0005840', 'synthetic: m45432-189'),
             ('has_abundant', 'CL:0000151', 'GO:0005794', 'synthetic: m45432-155'),
             ('has_abundant', 'CL:0000187', 'GO:0005739', 'synthetic: m45432-203'),
             ('capable_of', 'CL:0000765', 'GO:0006412', 'synthetic: m45432-189'),
             ('capable_of', 'CL:0000151', 'GO:0046903', 'synthetic: m45432-155'),
             ('capable_of', 'GO:0005794', 'GO:0046903', 'synthetic: GO:0005794 definition')],
      src='Abundance is relative: a generic cell is not rich in mitochondria (m45432-203 contrasts muscle cells with others)'),
    T('I33', 'invention', 'endosymbiosis over-generalised (holes.md: organelles derive from bacteria)', hold=[],
      pos=[], neg=[('derives_from', 'GO:0005634', 'NCBITaxon:2')],
      src='Only mitochondria and plastids derive from bacteria (m45432-261, -262); the nucleus does not'),
    # --- G. guards and synthetic edge cases
    T('I34', 'guard', 'one instance is not a rule (pancreas makes insulin)', hold=[],
      pos=[], neg=[('produces', 'UBERON:0002046', 'PR:000009054')],
      src='The thyroid makes thyroid hormone, not insulin (the-body-s-systems-m45537-27); holes.md over-general "endocrine gland produces insulin"'),
    T('I35', 'guard', 'synthetic: a class rule defeated by a stated negation', hold=[], synthetic=True,
      pos=[], neg=[('has_part', 'CL:0000520', 'GO:0005634')],
      extra=[('has_part', 'CL:0000187', 'GO:0005634', 'synthetic: muscle cell has a nucleus'),
             ('has_part', 'CL:0000232', 'GO:0005634', 'synthetic and false for mammals: a stray annotation')],
      src='Prokaryotes lack a nucleus (OpenStax m45429-15, a stated notRel); synthetic support pushes the cell-level class rule over threshold'),
    T('I36', 'guard', 'synthetic: the same sentence twice is one instance', hold=[], synthetic=True,
      pos=[], neg=[('produces', 'UBERON:0002046', 'PR:000009054')],
      extra=[('produces', 'UBERON:0001264', 'PR:000009054', 'synthetic duplicate of m45537-20 under a second id')],
      src='Fact-level deduplication: two copies of "pancreas produces insulin" are one instance'),
    # --- D, continued: the one induction rule the core already has
    T('I37', 'taxon', "widen a taxon rule from instances (the core's own generalize, M4)", hold=[],
      pos=[('located_in', 'GO:0005840&RO:0002162=(NCBITaxon:131567)', 'GO:0005737')],
      neg=[('located_in', 'GO:0005694&RO:0002162=(NCBITaxon:131567)', 'GO:0005634')],
      src='OpenStax, molbio-m45479-20, -21 (ribosomes are located in the cytoplasm in prokaryotes and in eukaryotes, so in all cellular organisms); prokaryotes lack a nucleus (cell-structure-and-function-m45429-15), so not every chromosome of a cellular organism is in a nucleus'),
]

JUDGE = {}   # rule_id -> (verdict, reason); filled from data/stress/10c/rule_judgements.tsv when present


def load_judgements():
    p = OUT / 'rule_judgements.tsv'
    if p.exists():
        for line in p.read_text().splitlines()[1:]:
            f = line.split('\t')
            if len(f) >= 3: JUDGE[f[0]] = (f[1], f[2])


def mark(pos_hit, neg_hit, n_pos):
    if any(neg_hit): return 'FAIL'
    if n_pos == 0 or all(pos_hit): return 'PASS'
    return 'SILENT'


def run():
    load_judgements()
    base = IC.load()
    L = base['labels_e']
    lits = {k: v['src'] for k, v in base['facts'].items() if v['deriv'][0] == 'lit'}
    by_triple = {M.triple(base, k): k for k in base['facts']}
    results = []
    for t in TASKS:
        hold = set(t.get('hold', []))
        for h in hold: assert h in set(lits.values()), (t['id'], 'no such statement', h)
        for p in t.get('pos', []):
            if p[0] in ('has_abundant',): continue
            if p in by_triple and lits.get(by_triple[p]) not in hold and t['family'] not in ('path',) and not t.get('extra'):
                raise SystemExit(f"{t['id']}: pos {p} is a fact that is not held out")
        facts, asserted = IC.chain(base, holdout=hold)
        closure_triples = {M.triple(base, k) for k in facts}
        train = [M.triple(base, k) for k in asserted] + [e[:3] for e in t.get('extra', [])]
        for n in t.get('neg', []): assert n not in set(train), (t['id'], 'neg is a fact', n)
        res = dict(id=t['id'], family=t['family'], probes=t['probes'], hold=sorted(hold), pos=t.get('pos', []),
                   neg=t.get('neg', []), src=t['src'], synthetic=bool(t.get('synthetic') or t.get('extra')), systems={})
        # closure
        ph = [p in closure_triples for p in res['pos']]; nh = [n in closure_triples for n in res['neg']]
        how = [facts[by_triple[p]]['deriv'][0] if p in closure_triples and p in by_triple and by_triple[p] in facts else '' for p in res['pos']]
        res['systems']['closure'] = dict(pos=ph, neg=nh, mark='INEXPRESSIBLE' if t.get('inexpressible') else mark(ph, nh, len(ph)), how=how)
        for name, onto in (('mine', True), ('mine_tb', False)):
            kb = M.KB(train, onto=onto)
            if t.get('inexpressible') and not any(p[0] in kb.P for p in res['pos']):
                res['systems'][name] = dict(pos=[False] * len(res['pos']), neg=[False] * len(res['neg']), mark='INEXPRESSIBLE', rules=[])
                continue
            R = M.mine(kb, min_supp=2, min_pca=0.1)
            P = M.predictions(kb, R)
            def info(q):
                r = P.get(q)
                if not r: return None
                rid = M.rule_id(r)
                return dict(rule=M.show(r, L), rule_id=rid, pca=round(r['pca'], 3), supp=r['supp'], n=r['n'], cat=M.category(r, base),
                            judge=JUDGE.get(rid, ('unjudged', ''))[0])
            pi = [info(p) for p in res['pos']]; ni = [info(n) for n in res['neg']]
            ph = [bool(i and i['pca'] >= THETA) for i in pi]; nh = [bool(i and i['pca'] >= THETA) for i in ni]
            res['systems'][name] = dict(pos=ph, neg=nh, mark=mark(ph, nh, len(ph)), pos_info=pi, neg_info=ni)
        kb = M.KB(train, onto=False)
        if t.get('inexpressible'):
            res['systems']['amie'] = dict(pos=[False] * len(res['pos']), neg=[False] * len(res['neg']), mark='INEXPRESSIBLE')
        else:
            AR, _ = A.run(kb, f'task_{t["id"]}')
            AP = A.predictions(kb, AR)
            def ainfo(q):
                r = AP.get(q)
                return dict(rule=r['text'], pca=round(r['pca'], 3), supp=r['supp']) if r else None
            pi = [ainfo(p) for p in res['pos']]; ni = [ainfo(n) for n in res['neg']]
            ph = [bool(i and i['pca'] >= THETA) for i in pi]; nh = [bool(i and i['pca'] >= THETA) for i in ni]
            res['systems']['amie'] = dict(pos=ph, neg=nh, mark=mark(ph, nh, len(ph)), pos_info=pi, neg_info=ni, n_rules=len(AR))
        results.append(res)
        s = res['systems']
        print(f"{t['id']} {t['family']:9s} closure {s['closure']['mark']:13s} mine {s['mine']['mark']:13s} mine_tb {s['mine_tb']['mark']:13s} amie {s['amie']['mark']:13s} {t['probes'][:60]}", flush=True)
        for nm in ('mine', 'amie'):
            for lab_, key in (('pos', 'pos_info'), ('neg', 'neg_info')):
                for q, i in zip(res[lab_], s[nm].get(key, [])):
                    if i: print(f"     {nm} {lab_} {q[0]}({L.get(q[1], q[1])}, {L.get(q[2], q[2])}) pca={i['pca']} supp={i['supp']} by {i['rule']}"
                                + (f"  [{i.get('cat')}; {i.get('judge')}]  {i.get('rule_id')}" if nm == 'mine' else ''))
    (OUT / 'tasks_observed.json').write_text(json.dumps(results, indent=1))
    tally = {nm: collections.Counter(r['systems'][nm]['mark'] for r in results) for nm in ('closure', 'mine', 'mine_tb', 'amie')}
    print(json.dumps(tally))
    return results


if __name__ == '__main__':
    run()
