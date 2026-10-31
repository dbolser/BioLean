"""Stress set for decision 7, the IC triviality cut (program 07). Run from the repo root:

    python3 scripts/stress/ic_cases.py            # check the pins, write data/stress/07/cases.tsv
    python3 scripts/stress/ic_cases.py --report   # also print each case

Each case is a derived fact from data/search/closure.json (real) or a key built here (synthetic), never a fact on the
rating sheet (so the sheet stays blind). What BioLean does is computed, not typed in: the IC score (min IC of the two
ends, as closure.py), the cut at 2.5 (kept, dropped, or unjudged when an end has no IC), the rank among the 1,921 scored
facts in closure_ic.json, and path_min. The pins below are the observed values on 2026-10-30. A change to the closure, the
IC table or the cut flips a pin and this script exits non-zero, naming the case.

Marks (from the case discipline): PASS right conclusion; FAIL wrong conclusion; SILENT no conclusion where one is due;
INEXPRESSIBLE the needed verdict has no slot in a one-number cut. For the cut: a level-0 fact should be dropped, a true
level-2 or 3 fact kept; a false fact should be flagged, which the cut cannot do, so a false fact kept is FAIL (shown as a
finding) and a false fact dropped is SILENT (dropped as 'trivial', its falsity unseen). Levels are the rubric's 0 to 3
(data/stress/07/rubric.md) and are my provisional judgement (an LLM), to be replaced by Dan's ratings.
"""
import json, sys
sys.path.insert(0, 'scripts/stress')
from ic_common import IC_MIN, base, bound, ends, key_of, leaves, load_closure, load_ic, path_min, score, templates

R, S = 'real', 'synthetic'
CASES = [
    # id, kind, probe, fact (exact closure string, or a synthetic key), level, true, why (biology), source, pinned (obs, score, mark)
    ('C01', R, 'cut: generic subject', 'cells [CL:0000000] has part phospholipid [CHEBI:16247]', 0, 'yes',
     'Every cell has a membrane made of phospholipid; nothing beyond the premises.',
     'premises cell-structure-and-function-m45429-5, -m45432-8', ('dropped', 0.002, 'PASS')),
    ('C02', R, 'cut: generic subject', 'body [UBERON:0000468] has part fatty acid [CHEBI:35366]', 0, 'yes',
     'The body contains fatty acids: vacuous.', 'premises in premise_ids (textbook)', ('dropped', 0.004, 'PASS')),
    ('C03', R, 'cut: obsolete term merged', 'Animal cells [CL:0000548] capable of exocytosis [GO:0006887]', 0, 'yes',
     'Animal cells do exocytosis; restates the cell-level premise. CL:0000548 is obsolete and merged into cell, which is why it scores 0.',
     'OLS4 CL:0000548 obsolete; premise cell-structure-and-function-m45435-76', ('dropped', 0.002, 'PASS')),
    ('C04', R, 'cut: generic subject', 'tissues [UBERON:0000479] has part cytoplasm [GO:0005737]', 0, 'yes',
     'Tissues are made of cells, cells have cytoplasm.', 'premises in premise_ids (textbook)', ('dropped', 1.272, 'PASS')),
    ('C05', R, 'cut: generic subject', 'neuron [CL:0000540] has part ribosomes [GO:0005840]', 0, 'yes',
     'A neuron is a cell; cells have ribosomes.', 'premises in premise_ids (textbook)', ('dropped', 1.392, 'PASS')),
    ('C06', R, 'cut: substantive kept', 'hippocampus [UBERON:0002421] part of cerebral cortex [UBERON:0000956]', 2, 'yes',
     'The hippocampus is cortex (archicortex), not a deep nucleus; many students think otherwise.',
     'OLS4 UBERON:0002421 ancestors include UBERON:0000956; premises the-body-s-systems-m45539-397, -414', ('kept', 3.475, 'PASS')),
    ('C07', R, 'cut: substantive kept',
     'oxygen [CHEBI:15379] →− process(erythropoiesis ⊓ occurs in (bone marrow) [GO:0030218&BFO:0000066=(UBERON:0002371)])', 2, 'yes',
     'Low oxygen raises EPO, EPO drives red cell formation, so oxygen damps erythropoiesis: a cross-sentence link.',
     'premises the-body-s-systems-m45537-238, -240', ('kept', 7.6, 'PASS')),
    ('C08', R, 'cut: substantive lost', 'central nervous system [UBERON:0001017] has part retina [UBERON:0000966]', 2, 'yes',
     'The retina is, anatomically and developmentally, an extension of the CNS; many people find that surprising.',
     'London 2013 (PMID:23165340): the retina is an extension of the CNS. UBERON does not say so (OLS4: retina ancestors are eye and nervous system, not CNS). Premises the-body-s-systems-m45539-162, -181', ('dropped', 1.879, 'FAIL')),
    ('C09', S, 'cut: cliff at 2.5', ('rel', ('bfo', 51, False), 'UBERON:0002101', 'UBERON:0000976'), 1, 'yes',
     'Synthetic: "limb has part humerus" (2.31, dropped) against the real "appendicular skeleton has part humerus" (2.52, kept). '
     'Equally obvious; a 0.21 gap in IC flips the verdict.',
     'OLS4 UBERON:0000976 ancestors include UBERON:0002101 and UBERON:0002091', ('dropped', 2.308, 'FAIL')),
    ('C10', R, 'cut: restatement by refinement',
     'FAD+ ⊓ located in (brain) ⊓ in taxon (NCBITaxon:40674) [CHEBI:16238&RO:0001025=(UBERON:0000955)&RO:0002162=(NCBITaxon:40674)] is_a FAD+ [CHEBI:16238]',
     0, 'yes', '"FAD in the mammalian brain is FAD": two refinement axioms chained. No textbook sentence at all.',
     'both premises are refineAxiom definitions', ('kept', 12.297, 'FAIL')),
    ('C11', R, 'cut: restatement by refinement',
     'kidneys ⊓ in taxon (mammalian systems) [UBERON:0002113&RO:0002162=(NCBITaxon:40674)] has part outer cortex [UBERON:0001225]', 0, 'yes',
     'Restates "kidneys have an outer cortex" for mammalian kidneys.', 'premises in premise_ids: the-body-s-systems-m45534-135 plus a refineAxiom', ('kept', 3.932, 'FAIL')),
    ('C12', R, 'cut: weaker than a premise', 'telomerase [GO:0005697] has part polymer [CHEBI:60027]', 0, 'yes',
     'Telomerase has RNA, RNA is a polymer: strictly weaker than the premise.', 'premises molbio-m45475-135, molbio-m45473-49', ('kept', 6.076, 'FAIL')),
    ('C13', R, 'rank: ChEBI saturation', 'ATP [CHEBI:15422] has part phosphorus atom [CHEBI:28659]', 1, 'yes',
     'Textbook chemistry. Ranked near the top only because ChEBI has 219k terms.',
     'premises photosynthesis-m45452-78, molbio-m45473-164', ('kept', 10.911, 'FAIL')),
    ('C14', R, 'truth: false, kept', 'ATP synthase [GO:0045259] →− process(ATP biosynthetic process [GO:0006754])', 2, 'no',
     'False as stated: ATP synthase makes ATP. Product inhibition (ATP slows its own synthesis) read as a static sign. Not flagged as feedback.',
     'premises how-cells-obtain-energy-m45439-72, -m45437-246', ('kept', 8.293, 'FAIL')),
    ('C15', R, 'truth: false, kept', 'LDL [GO:0034362] →+ process(sense of satiety or fullness [GO:0032098])', 2, 'no',
     'False: rests on "LDL is_a cholesterol" (a lipoprotein particle is not cholesterol) plus "fats promote satiety".',
     'premises cell-structure-and-function-m45435-53, how-cells-obtain-energy-m45444-30, the-body-s-systems-m45535-183', ('kept', 8.313, 'FAIL')),
    ('C16', R, 'truth: false, kept',
     'deoxyribonucleic acid ⊓ in taxon (NCBITaxon:2759) [CHEBI:16991&RO:0002162=(NCBITaxon:2759)] located in saliva [UBERON:0001836]', 1, 'no',
     'False as a universal: "DNA can be retrieved from saliva" was encoded as DNA located_in saliva, then inherited by all eukaryotic DNA.',
     'premise molbio-m45472-2', ('kept', 9.619, 'FAIL')),
    ('C17', R, 'truth: false, kept', 'veins [UBERON:0001638] connected to aorta [UBERON:0000947]', 1, 'no',
     'False: veins return blood to the heart; the aorta leaves it. Existential read as universal ("some vessels join the aorta").',
     'premises the-body-s-systems-m45534-192, -m45536-244', ('kept', 3.632, 'FAIL')),
    ('C18', R, 'truth: false, dropped',
     'glucose ⊓ located in (blood) [CHEBI:17234&RO:0001025=(UBERON:0000178)] located in cytoplasm [GO:0005737]', 0, 'no',
     'False: glucose in blood is not in cytoplasm; the conclusion contradicts its own subject\'s context.',
     'premise cell-structure-and-function-m45432-35 plus a refineAxiom', ('dropped', 1.272, 'SILENT')),
    ('C19', R, 'truth: false, dropped',
     'brain ⊓ in taxon (Insecta) [UBERON:0000955&RO:0002162=(NCBITaxon:50557)] has part retina [UBERON:0000966]', 1, 'no',
     'False: insects have compound eyes, no retina in UBERON\'s sense.',
     'OLS4 UBERON:0000966 "never in taxon" NCBITaxon:6656 (Arthropoda); NCBITaxon:50557 is under 6656', ('dropped', 2.026, 'SILENT')),
    ('C20', R, 'truth: false, dropped',
     'chromosome ⊓ in taxon (prokaryote) [GO:0005694&RO:0002162=(NCBITaxon:2)] located in nucleus [GO:0005634]', 1, 'no',
     'False: prokaryotes have no nucleus; their chromosome sits in the nucleoid.',
     'textbook cell-structure-and-function-m45429-18, -m45429-74', ('dropped', 2.162, 'SILENT')),
    ('C21', R, 'truth: false, dropped',
     'brain ⊓ in taxon (Insecta) [UBERON:0000955&RO:0002162=(NCBITaxon:50557)] surrounded by cerebrospinal fluid [UBERON:0001359]', 1, 'no',
     'False: CSF is the fluid of the subarachnoid space and ventricles (vertebrate structures); the fly brain is sheathed by glial layers and a neural lamella, not meninges.',
     'OLS4 UBERON:0001359 definition; Stork 2008 (PMID:18199760)', ('dropped', 2.026, 'SILENT')),
    ('C22', R, 'coverage: an end outside the IC table', 'plants [NCBITaxon:33090] has part carbon atoms [CHEBI:27594]', 0, 'yes',
     'Vacuous. NCBITaxon has no IC, so no verdict.', 'premises in premise_ids (textbook)', ('unjudged', None, 'SILENT')),
    ('C23', R, 'coverage: an end outside the IC table', 'mismatch repair [GO:0006298] →− phenotype(cancer [HP:0002664])', 2, 'yes',
     'Loss of mismatch repair raises cancer risk (Lynch syndrome); a real link. HP has no IC, so no verdict.',
     'premises molbio-m45475-156, -m45475-120', ('unjudged', None, 'SILENT')),
    ('C24', R, 'coverage: an end outside the IC table', 'Addison disease [MONDO:0100480] disease has location endocrine gland [UBERON:0002368]', 0, 'yes',
     'Weaker than its premise (adrenal gland). MONDO has no IC.', 'premises the-body-s-systems-m45537-47, -23', ('unjudged', None, 'SILENT')),
    ('C25', R, 'coverage: an end outside the IC table, feedback loop',
     'insulin ⊓ located in (blood) [PR:000009054&RO:0001025=(UBERON:0000178)] →+ amount(glucagon ⊓ located in (blood) [PR:P01275&RO:0001025=(UBERON:0000178)])',
     2, 'unsure',
     'Through blood glucose, insulin raises glucagon (true in hypoglycaemia); directly, insulin suppresses glucagon release. Flagged feedback.',
     'premises the-body-s-systems-m45537-53, -336; intra-islet effect: Xu 2006 (PMID:16399504)', ('unjudged', None, 'SILENT')),
    ('C26', R, 'inexpressible: audience', 'messenger RNA [CHEBI:33699] has part guanine [CHEBI:16235]', 1, 'yes',
     'Trivial to a biologist, worth a line to a first-year student. One cut has no audience.', 'premises in premise_ids (textbook)',
     ('kept', 11.198, 'INEXPRESSIBLE')),
    ('C27', R, 'inexpressible: redundant given another kept fact', 'metaphase [GO:0000089] overlaps mitotic phase [GO:0000087]', 0, 'yes',
     '"overlaps" follows from "part of", and "metaphase part of mitotic phase" (C28) is also derived and kept. A per-fact score cannot see the pair.',
     'closure.json holds both facts', ('kept', 8.005, 'INEXPRESSIBLE')),
    ('C28', R, 'inexpressible: already in the ontology', 'metaphase [GO:0000089] part of mitotic phase [GO:0000087]', 1, 'yes',
     'True, and GO already states it (mitotic metaphase part_of mitotic M phase). New to the book\'s graph, not to biology.',
     'OLS4 GO:0000089 ancestors include GO:0000087', ('kept', 8.005, 'INEXPRESSIBLE')),
    ('C29', R, 'inexpressible: worth checking because suspect',
     'deoxyribonucleic acid ⊓ in taxon (NCBITaxon:2759) [CHEBI:16991&RO:0002162=(NCBITaxon:2759)] located in nucleoid [GO:0009295]', 3, 'unsure',
     'Nuclear DNA is not in a nucleoid, but mitochondrial and chloroplast DNA are. A curator should see it as a suspect, not a finding.',
     'OLS4 GO:0009295 definition; premise cell-structure-and-function-m45429-18', ('kept', 5.748, 'INEXPRESSIBLE')),
    ('C30', S, 'coverage: one end unscored, other low', ('rel', ('bfo', 51, False), 'NCBITaxon:9606', 'CL:0000000'), 0, 'yes',
     'Synthetic: "Homo sapiens has part cell". The scored end bounds the fact, enough to call it trivial.', 'none needed',
     ('dropped', 0.002, 'PASS')),
    ('C31', R, 'cut: false and trivial, now gone', 'digestive system [UBERON:0001007] has part plant cell wall [GO:0009505]', 0, 'no',
     'Was in the 42 rated facts (E). No longer derived: fixed upstream by re-annotation, not by the IC cut.',
     'data/stress/07/old42_llm_labels.tsv', ('absent', None, 'PASS')),
    ('C32', R, 'truth: false, kept',
     'binary fission ⊓ in taxon (prokaryote) [GO:0043093&RO:0002162=(NCBITaxon:2)] happens during mitotic phase [GO:0000087]', 1, 'no',
     'False: prokaryotes divide by binary fission and have no mitosis. "Cell division happens during M phase" (said of eukaryotes) was inherited by binary fission.',
     'premises reproduction-at-the-cellular-level-m45463-12, -m45461-9', ('kept', 8.005, 'FAIL')),
]


# Worked examples in data/stress/07/rubric.md (level, true): none may be on the rating sheet, and none may share a
# subject, an object or a subject-object pair (base terms, same relation) with a row on either sheet, so no example
# primes a row. Second draft, 2026-10-30: five first-draft examples failed that test (near-twins of rows R008, R020,
# R048, R073, R078, R088) and were replaced; a sixth, 'capillaries promotes aerobic respiration', passed it but was
# replaced too, as capillaries are blood vessels and rows R031 and R089 say 'blood vessel promotes' the electron transport
# chain and oxidative phosphorylation. The sheet draw used the first draft; see data/stress/07/sheet_draw_exclusions.tsv.
RUBRIC = [
    (0, 'yes', 'organ [UBERON:0000062] has part cytoplasm [GO:0005737]'),
    (0, 'yes', 'Telomerase ⊓ part of (adult somatic cells) ⊓ existence overlaps (adult) [GO:0005697&BFO:0000050=(CL:0002371)&RO:0002490=(UBERON:0000113)] is_a telomerase [GO:0005697]'),
    (0, 'yes', 'DNA-templated transcription [GO:0006351] has input polymer [CHEBI:60027]'),
    (1, 'yes', 'axial skeleton [UBERON:0005944] has part cranial bone [UBERON:0004766]'),
    (1, 'yes', 'meiosis II [GO:0007135] part of sexual reproduction [GO:0019953]'),
    (1, 'yes', 'parathyroid gland [UBERON:0001132] located in neck [UBERON:0000974]'),
    (2, 'yes', 'peripheral nervous system [UBERON:0000010] has part structure that is capable of response to stress [GO:0006950]'),
    (2, 'yes', 'glucocorticoid [CHEBI:24261] →− process(inflammation [GO:0006954])'),
    (2, 'yes', 'amygdala [UBERON:0001876] part of structure that is capable of memory [GO:0007613]'),
    (3, 'yes', 'calcitonin ⊓ located in (blood) [PR:P01258&RO:0001025=(UBERON:0000178)] →+ amount(parathyroid hormone ⊓ located in (UBERON:0000178) [PR:000013429&RO:0001025=(UBERON:0000178)])'),
    (3, 'no', 'meiosis ⊓ in taxon (animals) [GO:0051321&RO:0002162=(NCBITaxon:33208)] happens during mitotic phase [GO:0000087]'),
    (3, 'unsure', 'antibodies [GO:0019814] →− amount(antibodies ⊓ located in (immune system) [GO:0019814&RO:0001025=(UBERON:0002405)])'),
]


def observe(c, facts_by, scored_rank, ic):
    fact = c[3]
    if isinstance(fact, tuple):
        k = fact; s = score(k, ic); b = bound(k, ic); pm = None; rank = None
    else:
        f = facts_by.get(fact)
        if f is None: return 'absent', None, None, None, None
        k = f['k']; s = score(k, ic); b = bound(k, ic); pm = path_min(f['t'], ic); rank = scored_rank.get(fact)
    if s is not None: obs = 'kept' if s >= IC_MIN else 'dropped'
    elif b is not None and b < IC_MIN: obs = 'dropped'
    else: obs = 'unjudged'
    return obs, s, b, pm, rank


def mark(c, obs):
    probe, level, true = c[2], c[4], c[5]
    if probe.startswith('inexpressible'): return 'INEXPRESSIBLE'
    if obs == 'absent': return 'PASS' if true == 'no' else 'FAIL'
    if obs == 'unjudged': return 'SILENT'
    if probe.startswith('rank'): return 'FAIL' if level <= 1 else 'PASS'
    if probe.startswith('cut: cliff'): return 'FAIL'
    if true == 'no': return 'FAIL' if obs == 'kept' else 'SILENT'
    if level == 0: return 'PASS' if obs == 'dropped' else 'FAIL'
    if level >= 2: return 'PASS' if obs == 'kept' else 'FAIL'
    return 'PASS'


def main():
    facts = load_closure(); ic, _ = load_ic()
    facts_by = {f['fact']: f for f in facts}
    ranked = json.load(open('data/search/closure_ic.json'))['facts']
    scored_rank = {f['fact']: i + 1 for i, f in enumerate(ranked)}
    sheet = {l.split('\t')[2] for l in open('data/stress/07/rating_sheet_key.tsv', encoding='utf-8').read().splitlines()[1:]}
    sig = lambda k: (k[0],) + ((k[1], k[2]) if k[0] == 'effect' else (k[1],)) + tuple(base(c) for c in ends(k))
    sheet_sig = {sig(facts_by[x]['k']) for x in sheet}   # a twin (same fact, a context added or dropped) would prime a row
    rows = [('id', 'kind', 'probe', 'fact', 'level_provisional', 'true', 'what a correct system concludes', 'source',
             'premise_ids', 'observed', 'ic', 'path_min', 'rank_of_1921', 'mark')]
    bad = []
    for c in CASES:
        if isinstance(c[3], str) and c[3] in facts_by:
            assert sig(facts_by[c[3]]['k']) not in sheet_sig, f'{c[0]} (or a twin) is on the rating sheet'
        obs, s, b, pm, rank = observe(c, facts_by, scored_rank, ic)
        m = mark(c, obs)
        p_obs, p_s, p_m = c[8]
        shown = s if s is not None else (b if obs == 'dropped' else None)
        if obs != p_obs or m != p_m or (p_s is not None and (shown is None or abs(shown - p_s) > 1e-3)):
            bad.append(f'{c[0]}: pinned {c[8]}, observed ({obs}, {shown}, {m})')
        f = facts_by.get(c[3]) if isinstance(c[3], str) else None
        pids = ' '.join(l['sid'] for l in leaves(f['t'])) if f else ''
        rows.append((c[0], c[1], c[2], c[3] if isinstance(c[3], str) else f'synthetic key {c[3]}', c[4], c[5], c[6], c[7], pids, obs,
                     '' if s is None else round(s, 3), '' if pm is None else round(pm, 3), '' if rank is None else rank, m))
    with open('data/stress/07/cases.tsv', 'w', encoding='utf-8') as fh:
        for r in rows: fh.write('\t'.join(str(x).replace('\t', ' ') for x in r) + '\n')
    old9 = [key_of({'key': json.loads(l.split('\t')[2])}) for l in
            open('data/stress/07/rating_sheet_old9_key.tsv', encoding='utf-8').read().splitlines()[1:]]
    row_tpl = set().union(*(templates(facts_by[x]['k']) for x in sheet), *(templates(k) for k in old9))
    for lvl, t, fact in RUBRIC:
        assert fact in facts_by, f'rubric example not in the closure: {fact[:60]}'
        assert sig(facts_by[fact]['k']) not in sheet_sig, f'rubric example (or a twin) is on the rating sheet: {fact[:60]}'
        assert not templates(facts_by[fact]['k']) & row_tpl, f'rubric example shares a subject, object or pair with a row: {fact[:60]}'
    print(f'{len(RUBRIC)} rubric examples: all in the closure, none (nor a twin) on the sheet, none sharing a subject, '
          f'object or pair with a row on either sheet')
    tally = {}
    for r in rows[1:]: tally[r[-1]] = tally.get(r[-1], 0) + 1
    print(f'{len(CASES)} cases; marks {tally}')
    if '--report' in sys.argv:
        for r in rows[1:]: print(f'{r[0]} {r[13]:<13} {r[9]:<9} ic={r[10]!s:<7} pm={r[11]!s:<7} rank={r[12]!s:<5} {r[2]}')
    if bad:
        print('PIN FLIPPED:\n  ' + '\n  '.join(bad)); sys.exit(1)
    print('all pins hold')


if __name__ == '__main__':
    main()
