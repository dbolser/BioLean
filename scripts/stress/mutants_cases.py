"""Program 04: build data/stress/04/cases.tsv, the full stress set.

Curated cases (real errors R*, synthetic S*, inexpressible I*, a control C*) come first; their observed column is read
from the run outputs (mutants.tsv, baseline_flags.tsv, lean_typing.tsv) or computed here by running the detectors
(S4, S5, S6, R5). Then one row per control and mutant from mutants.tsv.
Run from the repo root:  python3 -I scripts/stress/mutants_cases.py [--check | --freeze]
Needs data/stress/04/review_inherit.tsv (python3 -I scripts/stress/mutants_review.py inherit) for row P4.
--check compares every row's mark, and each curated row's observed text, with data/stress/04/expected_cases.tsv and
exits 1 on any difference (--freeze writes that file). Marks on prototype rows (P*) say "(prototype)": they are what a
proposed option does, not what BioLean does today, and are kept out of today's tally."""
import sys, json, collections, shutil, copy
sys.path.insert(0, '/home/danbolser/Build/BioLean/scripts/stress')
import mutants_lib as L
FLAGS = set(sys.argv[1:])   # read now: run_closure overwrites sys.argv

OUT = L.OUT
BOOK = 'OpenStax Concepts of Biology (2013), local copy data/textbook'
LEANF = 'BioLean/Stress/AnnotationErrors.lean'
CHECK = 'expected_marks.tsv via mutants_score.py --check'

def tsv(path):
    rows = [l.rstrip('\n').split('\t') for l in open(path) if l.strip()]
    return rows[0], rows[1:]

def main():
    hdr, mrows = tsv(OUT / 'mutants.tsv'); M = {r[0]: dict(zip(hdr, r)) for r in mrows}
    base_flags = collections.defaultdict(list)
    for l in open(OUT / 'baseline_flags.tsv'):
        if l.startswith('#') or not l.strip(): continue
        sid, det, flag, key = l.rstrip('\n').split('\t'); base_flags[sid].append(f'{det}: {flag}')
    def bf(sid): return '; '.join(sorted(set(base_flags.get(sid, [])))[:4]) or 'no flag from any detector'
    def mobs(mid):
        r = M[mid]
        today = r['today'] or 'none'
        return f"today: {today}; outside: {r['later'] or 'none'}; flags: {r['flags'][:300] or '-'}; derived facts resting on it: {r['damage']}"
    # --- live runs for the synthetic cases
    L.ensure_copy(); L.load_records()
    ns0, clash0, sign0 = L.run_closure(L.CLAIMS)
    modes = collections.Counter(L.pattern(k) for k in ns0['asserted'] if k[0] != 'effect')
    S4 = ('rel', L.ISA, 'UBERON:0002420', 'UBERON:0000045'); st4 = L.static(S4, None, {'UBERON:0002420': 'basal ganglia', 'UBERON:0000045': 'ganglia'}, modes)
    S5 = ('rel', ('bfo', 50, False), 'UBERON:0002240', 'UBERON:0000955'); st5 = L.static(S5, None, {}, modes)
    lean4 = L.lean_mirror(S4); lean5 = L.lean_mirror(S5)
    r5 = L.label_lint('UBERON:0002163', 'area postrema')
    # S6: round 1's reversed statement added next to round 2's, as an extra record
    rid = 'cell-structure-and-function-m45432-261'
    d, n, i = L.LOC[('m2', rid)]
    root = L.MUT / 'S6'
    if root.exists(): shutil.rmtree(root)
    shutil.copytree(L.CLAIMS, root)
    recs = json.load(open(root / d / n)); extra = copy.deepcopy(recs[i]); extra['id'] = rid + '-r1'
    extra['m2'] = dict(extra['m2'], relation='derives into')
    recs.append(extra); json.dump(recs, open(root / d / n, 'w'))
    ns6, cl6, sg6 = L.run_closure(root); shutil.rmtree(root)
    s6_loaded = sum(1 for k in ns6['asserted'] if ns6['sid_of'].get(k) in (rid, rid + '-r1'))
    s6 = f'both statements load ({s6_loaded} of 2); new clashes {len(cl6 - clash0)}, new sign clashes {len(sg6 - sign0)}'
    ex7 = [s for s, fl in base_flags.items() if any('CL:0000548' in f and f.startswith('obsolete') for f in fl)]
    n_loops = len(ns0['sign_loop']); n_off = len(sign0)   # the first version printed len(sign0), the off-loop count (0)
    inh = [l.rstrip('\n') for l in open(OUT / 'review_inherit.tsv')]
    inh_live = sum(1 for l in inh if l.startswith('live\t')); inh_mut = [l.split('\t') for l in inh if l.startswith('mutant\t')]
    inh_false = sum(1 for x in inh_mut if x[2] == 'false'); inh_ctrl = sum(1 for x in inh_mut if x[1].endswith('-E0'))
    cases = [
        # id, probes, input, correct, observed, mark, test, source
        ('R1', 'context dropped (real, the centrosome)', 'cell-structure-and-function-m45432-318 "Animal cells also have a centrosome", round 2: CL:0000000 has_part (BFO:0000051) GO:0005813, no taxon',
         'false as written for plant cells; flag it (plant cells lack centrioles, m45432-75)', 'closure clash; in Lean the clash derivation gives verdict contested; round 3 restores NCBITaxon:33208 (Metazoa); mutant B01-E1 re-creates it: ' + mobs('B01-E1'),
         'PASS', f'{LEANF}: R1_centrosome_contested; {CHECK}: B01-E1', f'{BOOK} m45432-318, m45432-75, m45432-68'),
        ('R2', 'quantifier strengthened (real, "all mammals have teeth")', 'the-body-s-systems-m45535-39, round 2: NCBITaxon:40674 has_part UBERON:0001091',
         'false: adult baleen whales, anteaters and pangolins have no teeth (Meredith2009 names toothless taxa in Cetacea, Pholidota, Xenarthra); UBERON:0001091 never_in_taxon Mysticeti, Tachyglossidae, Ornithorhynchus, Aves, but the platypus one is wrong (juveniles have teeth, P3) and baleen whale fetuses grow tooth germs (I2)', 'Lean accepts; no clash (no toothless mammal in the textbook); taxon lint true. Mutant B05-E2: ' + mobs('B05-E2'),
         'SILENT', f'{LEANF}: R2 examples; {CHECK}: B05-E2', 'Meredith2009 (refs_checked.tsv); uberon.obo 2026-10-01 never_in_taxon'),
        ('R3', 'relation direction reversed (real, round 1)', 'cell-structure-and-function-m45432-261 "Aerobic bacteria became mitochondria", round 1: GO:0005739 derives_into (RO:0001001) NCBITaxon:2',
         'reversed: mitochondria derive from bacteria (RO:0001000); flag it', 'Lean accepts (derives_into: continuant to continuant); closure silent; mutant B26-E4: ' + mobs('B26-E4'),
         'SILENT', f'{LEANF}: R3 examples, Proto inversePair; {CHECK}: B26-E4', f'{BOOK} m45432-261; RO:0001000/RO:0001001 on OLS4'),
        ('R4', 'term too general (real, PR:000009054 for insulin)', 'the-body-s-systems-m45537-52 and -53: insulin as PR:000009054',
         'PR:000009054 is the gene-level class "preproinsulin"; mature insulin is PR:000050339 "insulin hormone"; flag it', 'Lean accepts; closure silent; label lint flags both: ' + M['B36-E0']['flags'] + ' | ' + M['B42-E0']['flags'],
         'SILENT', f'{LEANF}: R4 examples; {CHECK}: B36-E0, B42-E0', 'OLS4 PR labels (curies_checked.tsv); pr.obo 73.1'),
        ('R5', 'wrong CURIE of the right kind (real, digit slip)', 'area postrema as UBERON:0002163 (was in Lib/Entities.lean, fixed)',
         'UBERON:0002163 is the inferior cerebellar peduncle; area postrema is UBERON:0002162; flag it', f'Lean accepts any anatomy curie; the slip is outside the imported closure (known = false); label lint: {r5}',
         'SILENT', f'{LEANF}: R5 examples (areaPostremaSlip)', 'OLS4 UBERON labels (curies_checked.tsv)'),
        ('R6', 'obsolete term (real, CL:0002371 somatic cell)', 'molbio-m45475-71 "Telomerase is not active in adult somatic cells", context cellType CL:0002371',
         'CL:0002371 is obsolete (replaced_by CL:0000000, which loses the meaning); flag it', 'Lean accepts; Ontology.retired lists it but nothing reads it; obsolete check flags: ' + M['B43-E0']['flags'],
         'SILENT', f'{LEANF}: R6, Proto usesRetired; {CHECK}: B43-E0', 'cl-basic.obo 2026-06-08; OLS4 (curies_checked.tsv)'),
        ('R7', 'obsolete term (real, found here: CL:0000548 animal cell)', f'{len(ex7)} live statements: ' + ', '.join(sorted(ex7)),
         'CL:0000548 is obsolete; use CL:0000000 with a Metazoa context, as round 3 does for m45432-318', 'Lean accepts; closure silent; obsolete check flags all; Proto usesRetired flags all three (m45432-215 in rounds 2 and 3: round 3 kept the obsolete term)',
         'SILENT', f'{LEANF}: R7, Proto usesRetired, Review R7; {CHECK}: B44-E0, B45-E0', 'cl-basic.obo; OLS4'),
        ('R8', 'subject too general (real, found here)', 'photosynthesis-m45448-148 "a thylakoid is a disc-shaped membranous structure inside a chloroplast": GO:0009579 part_of GO:0009507',
         'false as a universal: GO:0009579 includes cyanobacterial thylakoids; the sentence means GO:0009534 chloroplast thylakoid', 'Lean accepts; closure silent; GO ceiling check flags: ' + M['B13-E0']['flags'][:200],
         'SILENT', f'{LEANF}: Review R8; {CHECK}: B13-E0', 'go-computed-taxon-constraints.obo (GO:0009579 never_in Metazoa only; GO:0009507 never_in Bacteria, Archaea)'),
        ('R9', 'context dropped (real, found here)', 'photosynthesis-m45448-95 "the Calvin cycle takes place in the stroma": GO:0019253 occurs_in GO:0009570',
         'false as a universal: cyanobacteria run the Calvin-Benson cycle without chloroplasts, RuBisCO in carboxysomes (Huffine2023); plant context dropped. GO itself defines GO:0019253 as "in the chloroplasts of C3 plants", which its taxon constraints do not enforce', 'Lean accepts; closure silent; GO ceiling check flags: ' + M['B18-E0']['flags'][:200],
         'SILENT', f'{LEANF}: Review R9; {CHECK}: B18-E0', 'go-computed-taxon-constraints.obo (GO:0019253 never_in Metazoa, Saccharomycetes only); go.obo definition; Huffine2023 (PMID 36367380)'),
        ('R10', 'wrong relation (real, found here: ChEBI role as a class)', 'photosynthesis-m45448-71 "chlorophyll is a pigment": CHEBI:28966 is_a CHEBI:26130',
         'CHEBI:26130 biological pigment is a role; the claim should be has_role (RO:0000087); flag the is_a', 'Lean accepts (both Kind.chemical); ontology check flags: ' + M['B24-E0']['flags'] + '; Proto isaNotInOntology flags it',
         'SILENT', f'{LEANF}: R10, Proto isaNotInOntology; {CHECK}: B24-E0', 'chebi_lite.obo 256 (CHEBI:26130 under CHEBI:50906 role); Hastings2016'),
        ('R11', 'quantifier strengthened (real, found here)', 'cell-structure-and-function-m45429-30 "Some prokaryotes have pili": CL:0000520 has_part GO:0009289, no quantifier',
         'the sentence says some; every prokaryotic cell having a pilus is false', 'Lean accepts; closure silent; GO ceiling check: ' + bf('cell-structure-and-function-m45429-30'),
         'SILENT', f'{LEANF}: Review R11; baseline_flags.tsv (mutants_run.py)', f'{BOOK} m45429-30; GO computed constraints'),
        ('R12', 'wrong kind, hidden by part_of having no sorts (real, found here)', 'how-cells-obtain-energy-m45439-53 "Cytochrome c oxidase is a component of the electron transport chain": GO:0045277 (complex) part_of GO:0022904 (process)',
         'a continuant cannot be part of a process; should be participates_in, or part_of the respiratory chain complex', 'Lean accepts (part_of declares no domain or range); mode check: ' + bf('how-cells-obtain-energy-m45439-53'),
         'SILENT', f'{LEANF}: §2 gaps (partOf.accepts), Review R12, Review.sigLint; baseline_flags.tsv', f'{BOOK} m45439-53; BFO part_of sorts'),
        ('R13', 'wrong kind, hidden by the coarse sort check (real, found here)', 'photosynthesis-m45453-23 "RuBisCO catalyzes the reaction between CO2 and RuBP": GO:0048492 enables GO:0015977 (a process)',
         'enables takes a molecular function, not a process; flag it', 'Lean accepts (enables declares no domain or range in RO.lean, so any kinds pass; RO declares them on its parent capable_of); mode check: ' + bf('photosynthesis-m45453-23'),
         'SILENT', f'{LEANF}: §2 gaps (enables.accepts), Review R13, Review.sigLint; baseline_flags.tsv', f'{BOOK} m45453-23; RO:0002327 on OLS4'),
        ('R14', 'wrong kind across ontologies (real, found here)', 'cell-structure-and-function-m45435-53 "LDL (low-density lipoprotein) is a form of cholesterol": GO:0034362 is_a CHEBI:16113',
         'LDL is a lipoprotein particle (a GO component) that carries cholesterol, not a kind of cholesterol; the sentence itself is loose and the annotation follows it; flag the is_a', 'Lean accepts (is_a has no kind check); is_a-across-kinds check (holes.py) flags it: ' + bf('cell-structure-and-function-m45435-53'),
         'SILENT', f'{LEANF}: Review R14, Proto isaNotInOntology, Review.sigLint; baseline_flags.tsv', f'{BOOK} m45435-53'),
        ('R15', 'condition dropped (real, found here)', 'reproduction-at-the-cellular-level-m45454-1 "A sexually reproducing organism develops from a zygote": UBERON:0000468 develops_from CL:0010017',
         '"sexually reproducing" dropped: budding and parthenogenesis give organisms not from a zygote (memory)', 'Lean accepts; closure silent; mode check flags it, but for an unrelated reason: ' + M['B28-E0']['flags'],
         'SILENT', f'{LEANF}: Review R15; {CHECK}: B28-E0', f'{BOOK} m45454-1'),
        ('R16', 'disjunction collapsed to one disjunct (real, found here)', 'molbio-m45475-4 "DNA replication occurs before mitosis or meiosis": GO:0006260 precedes GO:0140014',
         'the sentence is a disjunction; picking one disjunct is stronger, not weaker; the right form needs "or"', 'Lean accepts; GO ceiling check flags it for bacteria: ' + bf('molbio-m45475-4') + '; the correct claim has no constructor',
         'INEXPRESSIBLE', f'{LEANF}: Review R16; baseline_flags.tsv', f'{BOOK} m45475-4; Claim has no disjunction'),
        ('I1', 'exceptions to a universal', '"All mammals have teeth, except baleen whales, anteaters, pangolins" (the right form of R2)',
         'state the clade minus the exceptions', 'Ctx refines a subject (intersection); it cannot subtract a clade. Round 3 uses most, which loses the exceptions',
         'INEXPRESSIBLE', f'{LEANF}: R2 (quantOf r3_39 = most)', 'docs/programs/01-universals-and-descent.md option f; Meredith2009'),
        ('S1', 'taxon swapped (synthetic, literature-style)', 'claim: insulin in human lowers glucose; evidence taxon mouse', 'flag: evidence taxon is not under the claim taxon', 'Statement.taxonConsistent = false',
         'PASS', f'{LEANF}: #guard !s1.taxonConsistent', 'synthetic'),
        ('S2', 'context dropped (synthetic, literature-style)', 'claim: insulin lowers glucose, no context; evidence taxon mouse', 'flag: mouse evidence on a context-free claim', 'Statement.taxonConsistent = false',
         'PASS', f'{LEANF}: #guard !s2.taxonConsistent', 'synthetic'),
        ('S3', 'control for S1 and S2 (synthetic)', 'claim: insulin in mouse lowers glucose; evidence taxon mouse', 'no flag', 'Statement.taxonConsistent = true',
         'PASS', f'{LEANF}: #guard s3.taxonConsistent', 'synthetic'),
        ('S4', 'disjointness (synthetic, a naming trap)', '"the basal ganglia are ganglia": UBERON:0002420 is_a UBERON:0000045',
         'false: UBERON says basal ganglion disjoint_from ganglion (basal ganglia are nuclei of the brain); flag it', f'Lean mirror: {lean4 or "accepts"}; disjoint: {st4["disjoint"]}; ontology check: {st4["onto_refutes"]}; label: {st4["label"] or "none"}',
         'SILENT', 'mutants_cases.py (computed each run)', 'uberon.obo disjoint_from'),
        ('S5', 'spatial disjointness (synthetic)', '"the spinal cord is part of the brain": UBERON:0002240 part_of UBERON:0000955',
         'false: UBERON says spinal cord and brain are mutually spatially disjoint; flag it', f'Lean mirror: {lean5 or "accepts"}; disjoint: {st5["disjoint"]}; ontology check: {st5["onto_refutes"]}',
         'SILENT', 'mutants_cases.py (computed each run)', 'uberon.obo mutually_spatially_disjoint_with'),
        ('S6', 'R1 and R2 forms of m45432-261 side by side (synthetic combination of real records)', 'GO:0005739 derives_from NCBITaxon:2 and GO:0005739 derives_into NCBITaxon:2, both loaded',
         'flag: an inverse pair between the same two terms means one is reversed', f'closure: {s6}; Lean Proto.inversePair flags it',
         'SILENT', f'{LEANF}: Proto inversePair; mutants_cases.py', f'{BOOK} m45432-261'),
        ('P1', 'prototype D2: UBERON never_in_taxon read as a negative statement (data, no core change)', 'R2 round 2 "Mammalia has_part tooth" plus "no Mysticeti has_part tooth" and "Mysticeti is_a Mammalia" (both .ontologyAxiom)',
         'flag R2', 'Lean: relChain (is_a law) then clash gives verdict contested; round 3 (most) cannot enter the chain. Caveat: the axiom is too strong as written (fetal tooth germs, Thewissen2017; see I2)', 'PASS (prototype)', f'{LEANF}: Proto.P1_teeth_contested', 'uberon.obo never_in_taxon; NCBITaxon lineage (NCBI efetch); Meredith2009'),
        ('P2', 'prototype C: finer relation signatures (a core change)', 'R10, R12, R13, R14 and the 181 false mutants',
         'flag is_a to a ChEBI role, parthood across BFO sorts, enables to a process, is_a across kinds', 'catches 27 of 181 false mutants, 23 beyond today; 19 live statements flagged, 10 of 10 sampled are real errors; 0 of 41 correct controls flagged. The same checks as a Lean lint outside the core (Review.sigLint) flag 25 compiled statements (21 in round 2, 4 in round 3)',
         'PASS (prototype)', f'mutants_score.py --check (column sig, prototype); {LEANF}: Review.sigLint scan (#guard_msgs)', 'scripts/stress/mutants_lib.py finer_sig; baseline_judged.tsv'),
        ('C1', 'sign clashes on correct data (control)', 'the unmutated closure', 'no error flagged: the clashes come from feedback loops, which the closure names',
         f'{n_loops} sign clashes on a named loop, {n_off} off any loop; the closure itself prints "sign clashes: 47; with a flagged side 47" (run.log). None is an annotation error. Mutants are scored on new off-loop sign clashes only',
         'PASS', 'data/stress/04/closure_baseline/run.log', 'scripts/stress/closure_mutants.py run on the unmutated copy'),
        # --- added by the independent review, 2026-11-01
        ('P3', 'prototype D2 on a wrong ontology axiom (UBERON never_in_taxon Ornithorhynchus for calcareous tooth)',
         'literature: platypus has_part calcareous tooth (Lester and Boyde 1986, PMID 3706773: "unerupted developing teeth and air-dried erupted teeth of the platypus (Ornithorhynchus anatinus)"); D2 axiom: no Ornithorhynchus has_part calcareous tooth (.ontologyAxiom, 9/10)',
         'platypuses have teeth while young; the never_in_taxon axiom is wrong (UBERON cites PMID:10210685, an electroreception paper); flag the axiom',
         'Lean clash: verdict refuted with the paper as .observational, unsupported as .mechanistic: the wrong axiom outvotes the paper',
         'FAIL (prototype)', f'{LEANF}: Review.P3_platypus_refuted, Review.P3_platypus_unsupported_as_mechanistic', 'Lester1986; uberon.obo 2026-10-01; Pettigrew1999 (PMID 10210685)'),
        ('P4', 'prototype C0: inherit RO domain and range down sub-properties at import (core data change, no new constructor)',
         'every live statement and the 274 controls and mutants, typed with inherited sorts (review_inherit.tsv)',
         'flag only relation uses RO itself rules out',
         f'{inh_live} live statements newly rejected (3 has_function to a GO molecular function, 2 involved_in from one: RO wants a continuant there); {inh_false} false mutants caught beyond today; {inh_ctrl} controls',
         'PASS (prototype)', f'scripts/stress/mutants_review.py inherit; {LEANF}: Review C0 gap pins', 'data/ro.owl rdfs:subPropertyOf, rdfs:domain, rdfs:range'),
        ('I2', 'a life-stage-qualified negation', '"adult baleen whales have no teeth", while fetuses grow tooth germs that are sometimes mineralised (Thewissen et al. 2017, PMID 28070906)',
         'state the negation for the adult stage only',
         'Ctx.lifeStage refines the organism (existence_overlaps adult), not the time of the parthood, so "no tooth as an adult" and "never a tooth" are the same claim',
         'INEXPRESSIBLE', f'{LEANF}: Review I2 (curie of the life-stage refinement)', 'Thewissen2017'),
    ]
    out = ['id\tprobes\tinput\tcorrect\tobserved\tmark\ttest\tsource']
    for c in cases: out.append('\t'.join(x.replace('\t', ' ').replace('\n', ' ') for x in c))
    # --- every control and mutant
    for r in mrows:
        m = dict(zip(hdr, r)); base = m['base']
        if m['op'] == 'E0_control':
            probes = 'control (unmutated)'
            correct = 'no flag' if m['judged'] == 'true' else f'flag: a real error in the live data ({m["judged"]})'
        else:
            probes = m['op'].split('_', 1)[1].replace('_', ' ')
            jw = {'false': 'the mutated claim is false or ill-formed', 'equivalent': 'still true biology (equivalent mutant), but no longer what the sentence says',
                  'unclear': 'unclear whether still true'}[m['judged']]
            correct = f'flag: the annotation no longer matches its sentence; {jw}'
        test = f'{CHECK}: {m["mid"]}; data/stress/04/lean/MutantsEmitted.lean (Lean verdict)'
        lean_pins = {'B15-E6', 'B16-E6', 'B17-E6', 'B19-E4', 'B20-E4', 'B35-E4', 'B43-E4', 'B32-E10', 'B49-E2', 'B12-E6', 'B36-E7', 'B04-E8'}
        if m['mid'] in lean_pins: test += f'; {LEANF}'
        out.append('\t'.join([m['mid'], probes, f'{base}: {m["note"]}; claim {m["key"]}', correct, mobs(m['mid']), m['mark'], test,
                              f'{BOOK} {base}; terms checked on OLS4 (curies_checked.tsv)']))
    (OUT / 'cases.tsv').write_text('\n'.join(out) + '\n')
    exp_rows = ['# id\tmark\tobserved (curated rows only)'] + [f"{l.split(chr(9))[0]}\t{l.split(chr(9))[5]}\t" + (l.split(chr(9))[4] if not l.startswith('B') else '') for l in out[1:]]
    if '--freeze' in FLAGS: (OUT / 'expected_cases.tsv').write_text('\n'.join(exp_rows) + '\n')
    marks = collections.Counter(l.split('\t')[5] for l in out[1:])
    print(f'cases {len(out) - 1}: curated {len(cases)}, controls and mutants {len(mrows)}; marks {dict(marks)}')
    print('curated marks', dict(collections.Counter(c[5] for c in cases)))
    print('S4', st4['disjoint'], st4['onto_refutes'], '| S5', st5['disjoint'], '| S6', s6, '| R5', r5)
    today = collections.Counter(m for m in marks.elements() if '(prototype)' not in m)
    print('today (prototype rows excluded):', dict(today), 'of', sum(today.values()), '| prototype rows:', {m: n for m, n in marks.items() if '(prototype)' in m})
    if '--check' in FLAGS:
        exp = [l.rstrip('\n') for l in open(OUT / 'expected_cases.tsv') if l.strip()]
        diff = sorted(set(exp) ^ set(exp_rows))
        for d in diff: print('CHANGED', d[:240])
        print('check:', 'ok' if not diff else f'{len(diff)} lines differ'); sys.exit(1 if diff else 0)

if __name__ == '__main__': main()
