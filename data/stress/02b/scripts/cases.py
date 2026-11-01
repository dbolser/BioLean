"""Program 02b: build data/stress/02b/cases.tsv from what BioLean actually does.

Runs `lake env lean` on BioLean/Stress/Feedback.lean (OBS lines: today's core) and BioLean/Proto/Feedback.lean (PROTO
lines: the prototypes), saves both outputs in data/stress/02b/lean_*.out, and reads the closure outputs written by
data/stress/02b/scripts/run_closure.sh (run that first). Every case carries the fragment its mark was based on
(`expect`, and `pexpect` for the prototype); if the observed text no longer contains it, the case is written with
check=RECHECK and the script exits 1, so a change to the core, the libraries or the closure flips it visibly.
Usage (repo root): python3 data/stress/02b/scripts/cases.py [--no-lean]   (--no-lean reuses the saved .out files)
"""
import json, pathlib, subprocess, sys, collections

X = pathlib.Path('data/stress/02b')
G = 'the-body-s-systems-'

def run_lean(src, out, tag):
    if '--no-lean' not in sys.argv:
        r = subprocess.run(['lake', 'env', 'lean', src], capture_output=True, text=True, timeout=600)
        (X / out).write_text(r.stdout + r.stderr)
        if r.returncode != 0: sys.exit(f'{src} failed to compile; see {X / out}')
    lines = {}
    for ln in (X / out).read_text().splitlines():
        p = ln.split('\t', 2)
        if len(p) == 3 and p[0] == tag: lines[p[1]] = p[2]
    return lines

OBS = run_lean('BioLean/Stress/Feedback.lean', 'lean_stress.out', 'OBS')
PROTO = run_lean('BioLean/Proto/Feedback.lean', 'lean_proto.out', 'PROTO')

# --- closure outputs
LEFT = {}
def load_loops(mode):
    d = json.load(open(X / f'closure_{mode}' / 'loops.json'))
    LEFT[mode] = set(d.get('sign_clashes_left', []))
    return {f['fact']: f for f in d['facts']}, d['reflexive']
base_facts = {f['fact']: f for f in json.load(open(X / 'closure_base' / 'closure.json'))['facts']}
_, base_refl = load_loops('base_loops')
LOOPMODES = {m: load_loops(m) for m in ('core', 'signed', 'signed_complete', 'core_strict', 'signed_complete_strict')}

def cl_base(fact):
    if fact in base_facts:
        f = base_facts[fact]; fl = [g for g in f.get('flags', []) if g != 'loop']
        return f"derived, b={f['belief']}, {'flagged ' + '+'.join(fl) if fl else 'no flag'}"
    if fact in base_refl: return 'derived and silently dropped (reflexive a -> a)'
    return 'not derived'

def cl_mode(fact, mode):
    facts, refl = LOOPMODES[mode]
    if fact in facts:
        f = facts[fact]; left = ', left as an unexplained sign clash' if fact in LEFT.get(mode, ()) else ''
        return f"{f['reading']} {f['loops'] or ''}".strip() + left
    if fact in refl: return f"reflexive, read as {refl[fact][0]} {refl[fact][1] or ''}".strip()
    return 'not derived'

def closure_case(fact, modes):
    return f"base: {cl_base(fact)}", '; '.join(f"{m}: {cl_mode(fact, m)}" for m in modes)

# --- the cases. mark = today's core (OBS, or the base closure); pmark = the prototype (PROTO, or a loop mode).
# expect / pexpect: a fragment of the observed text the mark rests on.
T = lambda i: G + i
C = []
def case(id, group, probes, input, correct, mark, expect, tests, source, pmark='not run', pexpect=None, fact=None, modes=()):
    C.append(dict(id=id, group=group, probes=probes, input=input, correct=correct, mark=mark, expect=expect, tests=tests,
                  source=source, pmark=pmark, pexpect=pexpect, fact=fact, modes=modes))

# A. negative loops
case('L01', 'negative', 'going once round a negative loop (glucose, insulin)',
     f"R2 {T('m45537-52')} glucose CHEBI:17234 ->+ amount insulin PR:000009054; R3 {T('m45537-53')} insulin ->- amount glucose in blood (UBERON:0000178); loop: homeostasis insulin (blood glucose)",
     'insulin holds blood glucose near a set point by negative feedback; "glucose lowers blood glucose" is not a net effect',
     'FAIL', "→− amount of glucose ⊓ located in (blood)", 'Stress: L01_belief, L01_established, L01_loop_belief; Proto: #guard classify L01',
     f"textbook {T('m45537-52')}, -53, -200, -333", 'PASS', 'round trip of loop glucose')
case('L02', 'negative', 'the glucagon arm, through a refinement edge',
     f"R3 {T('m45537-199')} glucose ->- glucagon PR:P01275 (in blood, alpha cell CL:0000171); R3 -201 glucagon ->+ blood glucose",
     'glucagon defends blood glucose against a fall; "glucose lowers blood glucose" is not a net effect',
     'FAIL', "→− amount of glucose ⊓ located in (blood)", 'Stress: L02_belief; Proto: #guard classify L02', f"textbook {T('m45537-199')}, -201", 'PASS', 'round trip of loop glucose')
case('L03', 'negative', 'calcium and parathyroid hormone',
     f"R3 {T('m45537-141')} calcium CHEBI:29108 ->- PTH PR:000013429; R3 -140 PTH ->+ blood calcium",
     'PTH holds blood calcium by negative feedback; "calcium lowers blood calcium" is not a net effect',
     'FAIL', "calcium [CHEBI:29108] →− amount of calcium", 'Stress: L03_belief; Proto: #guard classify L03', f"textbook {T('m45537-140')}, -141", 'PASS', 'round trip of loop calcium')
case('L04', 'negative', 'a textbook loop that the literature disputes (calcitonin)',
     f"homeostasis calcitonin PR:P01258 (blood calcium) from {T('m45537-134')}; with and without a refuting review",
     'in mammals a physiological role of calcitonin in blood calcium regulation is not accepted; the loop should not be established once the review is counted',
     'PASS', 'with the refuting review: unsupported', 'Stress: L04 examples (verdicts), L04_disbelief', f"Hirsch2001 (PMID 15758481); textbook {T('m45537-134')}")
case('L05', 'negative', 'thermoregulation as compiled in round 3',
     f"R3 {T('m45534-77')}: 'hypothalamus (refined: located in hypothalamus, in taxon NCBITaxon:7742) ->+ temperature PATO:0000146'",
     'the hypothalamus holds body temperature (OBA:VT0005535) near a set point; it does not raise temperature',
     'FAIL', '→+ environmental temperature [PATO:0000146]', 'Stress: #guard on s77 (shape, sign, subject)', 'Morrison2019 (PMID 30256726); textbook -77',
     'PASS (proposal)', None)
case('L06', 'negative', 'osmoregulation by ADH: the loop closes through a process',
     'osmolality OBA:2045426 ->+ ADH CHEBI:34543; ADH ->+ renal water absorption GO:0070295; renal water absorption ->- osmolality (literature statements)',
     'ADH holds plasma osmolality by negative feedback; the half chain "osmolality raises renal water absorption" is right',
     'PASS', 'blood plasma osmolality [OBA:2045426] →+ renal water absorption', 'Stress: L06_belief, #guard chainable', 'Kondo2004 (PMID 14613925), Juul2012, Bourque2008')
case('L07', 'time scale', 'two loops on one variable at different time scales (blood pressure)',
     'homeostasis baroreflex GO:0003025 (pressure OBA:0000143); homeostasis kidney UBERON:0002113 (pressure)',
     'the baroreflex acts within seconds; the kidney-fluid system sets long-term pressure (Guyton 1991)',
     'INEXPRESSIBLE', 'nothing can say seconds vs days', 'Stress: #guard homeoFields L07', 'Guyton1991 (PMID 2063193), Benarroch2008')
case('L08', 'negative', 'the thyroid axis: is the negative arm in the record?',
     f"R3 {T('m45537-129')} TSH PR:P01222 ->+ T3 CHEBI:18258; {T('m45537-258')} and -260 (the 'inhibit further signaling' arms) have no Lean; proposed arm T3 ->- TSH",
     'thyroid hormones feed back to lower TRH and TSH (negative loop); "TSH lowers TSH" is not a net effect',
     'SILENT', 'today no loop: -258 and -260 have no Lean', 'Stress: #fb_no_lean -258, -260; L08_belief; Proto: #guard classify L08',
     'OrtigaCarvalho2016 (PMID 27347897); textbook -258, -260', 'PASS', 'round trip of loop thyroid')
case('L09', 'negative', 'a right conclusion through the loop (goiter raises TSH)',
     f"{T('m45537-263')} goiter MONDO:0005397 ->- T4 CHEBI:30660 (proposed); T4 ->- TSH (proposed -258#T4)",
     'in an iodine-deficient region serum TSH is supranormal and T4 subnormal (Chopra 1975), so the T4 route is right; but T3 is also supranormal there, so the T3 premise (goiter lowers T3) is contradicted. TSH and T3 did not differ between goitrous and non-goitrous subjects: the real subject is iodine deficiency, as the book says',
     'PASS', 'goiter [MONDO:0005397] →+ amount of thyroid-stimulating hormone', 'Stress: L09_belief', 'Chopra1975 (PMID 1117981); textbook -263, -264')
case('L10', 'negative', 'a three-step round trip (the cortisol axis)',
     'CRH PR:000005867 ->+ ACTH CHEBI:3892; ACTH ->+ cortisol CHEBI:17650; cortisol ->- CRH (literature statements)',
     'glucocorticoids inhibit CRH and the HPA axis by negative feedback; "cortisol lowers cortisol" is not a net effect',
     'FAIL', 'cortisol [CHEBI:17650] →− amount of cortisol', 'Stress: L10_belief; Proto: #guard classify L10', 'Herman2016 (PMID 27065163)', 'PASS', 'round trip of loop HPA')
case('L11', 'negative', 'a right conclusion through the negative arm (dexamethasone suppression)',
     'dexamethasone CHEBI:41879 ->- ACTH; ACTH ->+ cortisol',
     'dexamethasone suppresses cortisol: the principle of the suppression test',
     'PASS', 'dexamethasone [CHEBI:41879] →− amount of cortisol', 'Stress: L11_belief; Proto: #guard classify L11 == crosses HPA',
     'Aouizerate2006 (PMID 16759341), Nieman2008 (PMID 18334580)', 'PASS', 'crosses [HPA]')
case('L12', 'negative', 'erythropoietin and oxygen: the return arm is a process',
     f"R2 {T('m45537-238')} oxygen CHEBI:15379 ->- EPO PR:000007141; R3 -240 EPO ->+ erythropoiesis GO:0030218 in bone marrow",
     'EPO maintains red cell mass; low oxygen raises red cell formation (the half chain is right)',
     'PASS', 'oxygen [CHEBI:15379] →− erythropoiesis', 'Stress: L12_belief, #guard chainable, target is a process', 'Jelkmann2011 (PMID 21078592); textbook -238, -240')
case('L13', 'negative', 'breathing and CO2',
     f"{T('m45536-30')}, -31 (no Lean); blood CO2 CHEBI:16526 ->+ breathing GO:0003016; breathing ->- blood CO2",
     'central chemoreceptors activated by PCO2 stimulate breathing, which stabilises arterial PCO2 (negative loop)',
     'SILENT', 'the core cannot close a loop through breathing', 'Stress: #fb_no_lean -30, -31; #guard !chainable', 'Guyenet2015 (PMID 26335642); textbook -30')
case('L14', 'negative', 'stomata and leaf water',
     'R3 photosynthesis-m45448-84 (rel: plants capable of stomatal closure GO:0090332 on a hot dry day); R2 -85 stomatal closure ->- transpiration GO:0010148',
     'guard cells close stomata in response to local water deficit, conserving water (hydro-active local feedback)',
     'SILENT', 'no water-deficit arm, no loop', 'Stress: #guard shape s84, sign s85', 'Buckley2005 (PMID 16219068); textbook photosynthesis-m45448-84')
case('L15', 'negative', 'atrial natriuretic peptide and blood volume',
     f"{T('m45537-226')} (no Lean; proposed: blood volume OBA:0003648 ->+ ANP PR:P01160); R2 -227 ANP ->- blood volume",
     'ANP released on increased blood volume lowers blood volume (negative loop); "blood volume lowers blood volume" is not a net effect',
     'SILENT', 'with -226 grounded, core derives', 'Stress: #fb_no_lean -226; L15_belief; Proto: #guard classify L15', f"textbook {T('m45537-225')}, -226, -227", 'PASS', 'round trip of loop ANP')
case('L16', 'negative', 'a signless arm ("aldosterone regulates")',
     f"{T('m45537-150')} aldosterone regulates ion concentration (no Lean); R3 -153 sodium CHEBI:29101 ->- aldosterone CHEBI:27584",
     'aldosterone raises Na+ reabsorption and so holds plasma Na+ and volume; the sentence gives no sign',
     'INEXPRESSIBLE', "RO 'regulates' (RO:0002211) takes processes only", 'Stress: #fb_no_lean -150; example Rel.accepts regulates chemical = false', f"textbook {T('m45537-150')}, -153")
case('L17', 'negative', 'a loop that mostly defends one direction (leptin)',
     f"R2 {T('m45537-251')} food intake GO:0042755 ->+ leptin PR:000009758; {T('m45537-254')} (proposed) leptin ->- food intake",
     'leptin is a negative feedback adipostatic signal, but its main physiological role may be signalling starvation when it falls (Ahima 1996)',
     'FAIL', 'food intake [GO:0042755] →− food intake', 'Stress: L17_belief, #guard subject; Proto: #guard classify L17', 'Ahima1996 (PMID 8717038); textbook -251, -254',
     'PASS', 'round trip of loop leptin')
case('L18', 'negative', 'end-product inhibition (isoleucine, threonine deaminase)',
     'isoleucine CHEBI:17191 in E. coli NCBITaxon:562 ->- threonine deaminase activity GO:0004794; that activity ->+ isoleucine',
     'isoleucine inhibits threonine deaminase and so holds its own level (feedback inhibition); "isoleucine lowers isoleucine" is not a net effect',
     'FAIL', 'amount of L-isoleucine', 'Stress: L18_belief, #guard homeoFields L18; Proto: #guard classifyStrict L18', 'Eisenstein1991 (PMID 2005118)', 'PASS', 'round trip of loop isoleucine')
case('L19', 'negative', 'the held quantity is a ratio (energy charge)',
     'R2 how-cells-obtain-energy-m45437-244 ATP CHEBI:15422 ->- glucose catabolism GO:0006007; R2 -247 ADP CHEBI:16761 ->+ catalytic activity GO:0003824',
     'ATP inhibits and ADP activates the same enzymes: the loop holds the ATP/ADP balance (energy charge, Atkinson 1968)',
     'INEXPRESSIBLE', 'no ratio of ATP to ADP', 'Stress: #guard on s244, s247', 'Atkinson1968 (PMID 4972613); textbook how-cells-obtain-energy-m45437-244, -247')
# B. positive loops
case('P01', 'positive', 'a positive loop stated as homeostasis (oxytocin in labour)',
     'homeostasis oxytocin CHEBI:7872 (uterine smooth muscle contraction GO:0070471); arms oxytocin ->+ contraction, contraction ->+ oxytocin',
     'contractions stimulate oxytocin, which stimulates more contractions: a positive loop, not a set point',
     'FAIL', 'a positive loop passes as negative feedback', 'Stress: P01_accepted, #guard !chainable; Proto: #guard oxytocinLoop.toCore.isEmpty', 'Russell2003 (PMID 12609499)',
     'PASS', 'toCore gives nothing')
case('P02', 'positive', 'amplification (thrombin and factor V)',
     'thrombin (PR:000007299, prothrombin, as stand-in) ->+ factor V activity PR:000007300; factor V ->+ thrombin',
     'thrombin activates factor V, which drives more thrombin generation: amplification, so "thrombin raises thrombin" is right',
     'PASS', 'true as a net effect', 'Stress: P02_belief; Proto: #guard classify P02', 'Panteleev2010 (PMID 20441738), Hoffman2001 (PMID 11434702)', 'PASS', 'round trip of loop thrombin+')
case('P03', 'positive', 'the same node also has a negative loop (protein C)',
     'thrombin ->+ protein C activity PR:000013261; protein C ->- factor V activity; factor V ->+ thrombin',
     'activated protein C inactivates factors Va and VIIIa, inhibiting further thrombin generation: a brake on the positive loop',
     'FAIL', "prothrombin [PR:000007299] →− amount of prothrombin", 'Stress: P03_belief; Proto: #guard classify P03 (mislabel), classifyStrict P03', 'Esmon2003 (PMID 12970121)',
     'FAIL (loose); PASS (strict)', 'loose reading: round trip of loop thrombin+')
case('P04', 'positive', "the action potential's sodium channels",
     f"R2 {G}m45539-89 depolarisation GO:0051899 ->+ VGSC activity GO:0005248; -90 VGSC ->+ Na+ CHEBI:29101 entry; -83 Na+ ->+ depolarisation",
     'depolarisation opens Na+ channels, Na+ entry depolarises further: the textbook\'s "positive feedback loop" (-88)',
     'PASS', 'membrane depolarization [GO:0051899] →+ membrane depolarization', 'Stress: P04_belief; Proto: #guard classify P04', f"textbook {G}m45539-87, -88, -89, -90, -83; Hodgkin1952", 'PASS', 'round trip of loop depolarisation+')
case('P05', 'negative', 'the potassium arm that ends the spike',
     f"R2 {G}m45539-95 depolarisation ->+ Kv channel activity GO:0005249; -96 (no Lean) K+ efflux; R2 -97 K+ ->+ repolarisation GO:0086009",
     'depolarisation opens K+ channels and K+ efflux repolarises the membrane: a slower negative loop',
     'SILENT', 'do not join', 'Stress: #fb_no_lean -96; #guard !chainable', f"textbook {G}m45539-95, -96, -97; Hodgkin1952")
case('P06', 'positive', 'an arm that changes sign (estradiol and the LH surge)',
     'estradiol CHEBI:16469 ->- LH PR:P01229; estradiol ->+ LH (sustained high estradiol: placeholder BLN term)',
     'estradiol feedback is normally negative and switches to positive under sustained high estradiol, giving the LH surge',
     'INEXPRESSIBLE', 'no ontology term for', 'Stress: #guard subjectCurie equal / differ; Proto: #guard lhLoop.sign != lhSurge.sign', 'Christian2010 (PMID 20237240)',
     'INEXPRESSIBLE', 'the switch itself is still not a claim')
case('P07', 'positive', 'autocatalysis whose return arm is structural (ethylene in ripening)',
     'ethene CHEBI:18153 in tomato NCBITaxon:4081 during climacteric ripening GO:0009836 ->+ ethylene biosynthesis GO:0009693; rel has_output(ethylene biosynthesis, ethene)',
     'climacteric fruit switch to autocatalytic ethylene production during ripening (a positive loop)',
     'SILENT', 'no rule bridges rel to effect', 'Stress: #guard target is a process, #guard shape rel', 'Alexander2002 (PMID 12324528)')
case('P08', 'positive', 'a positive loop made of two negative arms (the toggle switch)',
     'LacI PR:000023070 ->- TetR PR:P04483 (E. coli NCBITaxon:562); TetR ->- LacI (literature statements; an illustrative pair)',
     'two repressors arranged in a mutually inhibitory network make a bistable switch: each state reinforces itself, so "LacI raises LacI" is right as a net effect (Gardner 2000)',
     'PASS', '→+ amount of lactose operon repressor', 'Stress: P08_belief, example neg * neg = pos; Proto: #guard classify P08, closeToggle sign',
     'Gardner2000 (PMID 10659857)', 'PASS', 'round trip of loop toggle+')
# C. two regulators, time scales, set points
case('T01', 'two regulators', 'one loop, two regulators pushing opposite ways (insulin, glucagon)',
     f"{T('m45537-333')}: homeostasis insulin (blood glucose); homeostasis glucagon (blood glucose)",
     'one loop with two regulators: insulin lowers and glucagon raises blood glucose',
     'INEXPRESSIBLE', 'nothing says they are one loop', 'Stress: #fb_no_lean -333, #guard homeoFields equal; Proto: #guard toCore', f"textbook {T('m45537-333')}, -199, -200, -201",
     'PASS', 'regulators [insulin, glucagon]')
case('T02', 'two regulators', 'PTH and calcitonin on blood calcium',
     'homeostasis PTH (blood calcium); homeostasis calcitonin (blood calcium)',
     'two hormones push blood calcium in opposite directions within one loop; modelled as integral feedback (El-Samad 2002)',
     'INEXPRESSIBLE', 'two claims', 'Stress: #guard homeoFields equal', f"textbook {T('m45537-134')}, -140; ElSamad2002 (PMID 11786029)", 'PASS', 'regulators [parathyroid hormone, calcitonin]')
case('T03', 'two regulators', 'several effectors of one loop (thermoregulation)',
     f"homeostasis hypothalamus in Mammalia (body temperature); R2 {T('m45534-61')} vasodilation GO:0042311 ->- temperature; -78, -79 (no Lean)",
     'the hypothalamus drives vasodilation and sweating on one side of the set point, vasoconstriction and shivering on the other',
     'INEXPRESSIBLE', 'cannot be attached', 'Stress: #guard s61; #fb_no_lean -78, -79', 'Morrison2019 (PMID 30256726); textbook -77, -78, -79')
case('T04', 'set point', "a set point moved by another loop's variable",
     'nearest core claim: hypovolemia (placeholder) ->+ ADH',
     'acute hypovolemia lowers the plasma Na threshold for AVP release: the set point moves, not the level (rats)',
     'INEXPRESSIBLE', 'which says something else', 'Proto: LClaim.shiftsSetPoint (adhThreshold)', 'Kondo2004 (PMID 14613925)', 'PASS', 'set point of loop osmolality')
case('T05', 'time scale', 'a slow loop on the gain: receptor down-regulation',
     f"{T('m45537-328')}, -82 (class-level, no Lean); insulin ->- insulin receptor PR:000009064 (literature); chained with R2 -52",
     'insulin lowers its receptor number after hours (5 to 16 hr), not after 0 to 2 hr; the chain "glucose lowers insulin receptors" holds only for a sustained rise',
     'INEXPRESSIBLE', 'no claim carries a time scale', 'Stress: #fb_no_lean -328, -82; T05_belief', 'Gavin1974 (PMID 4359334); textbook -328')
case('S01', 'set point', 'a set point as a measure claim (37 °C)',
     'measure Homo sapiens NCBITaxon:9606 body temperature OBA:VT0005535 [37, 37] °C',
     'the set point exists and is a number; the canonical 37 °C is now too high and has fallen 0.03 °C per birth decade (Protsiv 2020)',
     'INEXPRESSIBLE', 'no field ties it to the loop', 'Stress: #guard shape measure; Proto: #guard thermoLoop.setPoint', 'Protsiv2020 (PMID 31908267)', 'PASS', 'the set point is a core measure claim tied to the loop')
case('S02', 'set point', 'fever: pyrogens move the set point',
     f"{T('m45534-82')}, -85, -86, -92 (no Lean for -85, -92); pyrogen NCIT:C71583 ->+ body temperature",
     'pyrogens reset the hypothalamic set point upward; the loop then defends the higher value (Cabanac 2006; Biddle 2006)',
     'INEXPRESSIBLE', "'reset the thermostat' has no claim", 'Stress: #fb_no_lean -85, -92; Proto: #guard isShift fever', f"textbook {T('m45534-82')}, -85, -86, -92; Cabanac2006 (PMID 16540712)",
     'PASS', 'set point of loop temperature')
case('S03', 'look-alike', 'heat stroke looks like fever',
     'pyrogen ->+ body temperature; hot environment (placeholder) ->+ body temperature',
     'fever differs from hyperthermia in hot environments: one moves the set point, the other overwhelms the loop',
     'INEXPRESSIBLE', 'have the same shape, sign and target', 'Stress: #guard same shape and target; Proto: #guard isShift fever && !isShift heat', 'Biddle2006 (PMID 16617919)',
     'PASS', 'now different claims')
# D. look-alikes
case('N01', 'look-alike', 'antagonists without a loop (sympathetic, parasympathetic)',
     f"R2 {G}m45539-370 sympathetic UBERON:0000013 ->+ heart rate OBA:1001087; R2 -374 parasympathetic UBERON:0000011 ->- heart rate",
     'two opposing inputs to one variable; no loop is stated',
     'PASS', 'do not chain and no loop is claimed', 'Stress: #guard !chainable both ways', f"textbook {G}m45539-370, -374")
case('N02', 'look-alike', 'a negative loop that is not homeostasis (antibodies, virus)',
     'R2 cell-structure-and-function-m45433-65 antibodies GO:0019814 ->- virus NCBITaxon:10239; R3 -63 virus ->+ antibodies (in immune system)',
     'antibodies clear the virus that drives them: a negative loop with no set point; "antibodies lower antibodies" is not a stated or useful effect',
     'FAIL', 'antibodies [GO:0019814] →− amount of antibodies', 'Stress: N02_belief; Proto: #guard classify N02 == cycle',
     'textbook cell-structure-and-function-m45433-63, -65; set point defined in the-body-s-systems-m45534-17', 'FAIL', 'cycle (no asserted loop)')
case('N03', 'look-alike', "the word 'feedback' with no regulated variable",
     f"{G}m45539-230, -231, -232 (thalamus receives feedback from the cortex)",
     'a neural connection, not a loop holding a variable; no loop should be concluded',
     'PASS', 'no loop concluded', 'Stress: #fb_no_lean -231, -232', f"textbook {G}m45539-231, -232")
case('N04', 'look-alike', 'chaining through the loop variable gives a wrong sign (adrenaline and insulin)',
     f"R3 {T('m45537-181')} adrenaline CHEBI:33568 ->+ blood glucose; R3 -200 blood glucose ->+ insulin (refinement edge)",
     'catecholamines inhibit insulin release despite raising glucose (Porte 1966, Kris 1966)',
     'FAIL', 'epinephrine [CHEBI:33568] →+ amount of insulin', 'Stress: N04_belief; Proto: #guard classify N04 == crosses glucose', 'Porte1966 (PMID 5327883), Kris1966 (PMID 4955799)',
     'FAIL', 'now labelled as crossing the glucose loop')
case('N05', 'look-alike', 'chaining through the loop variable gives a right sign (glucagon and insulin)',
     f"R3 {T('m45537-201')} glucagon ->+ blood glucose; R3 -200 blood glucose ->+ insulin",
     'glucagon promotes insulin secretion (Samols 1965)',
     'PASS', 'glucagon [PR:P01275] →+ amount of insulin', 'Stress: N05_belief; Proto: #guard classify N05', 'Samols1965 (PMID 14346763)', 'PASS', "kept (right)")
case('N06', 'look-alike', 'feed-forward, not feedback (cephalic insulin)',
     'taste perception GO:0050909 ->+ insulin; R3 -53 insulin ->- blood glucose',
     'cephalic-phase insulin is anticipatory (feed-forward); the chain never returns to taste, so no loop',
     'PASS', 'which never returns to taste', 'Stress: N06_belief, #guard subject', 'Teff2011 (PMID 21256146)')
# E. synthetic
case('X01', 'synthetic', 'SYNTHETIC: a loop claim with no arms anywhere',
     'homeostasis insulin (blood calcium), asserted at textbook weight',
     'a loop with no arms should be visible as unsupported by arms',
     'SILENT', 'nothing asks for the two arms', 'Stress: X01_accepted; Proto: #guard armsFor X01_claim bookArms is empty (and not empty for the insulin and PTH loops)', 'synthetic', 'PASS', 'visible as unsupported by arms')
case('X02', 'synthetic', 'SYNTHETIC: a loop claim whose arms multiply to a positive sign',
     'homeostasis insulin (blood glucose) beside insulin ->+ glucose and glucose ->+ insulin',
     'the asserted negative loop disagrees with its arms; the clash should be reported',
     'SILENT', 'no check of the loop sign', 'Stress: #guard sign product; Proto: #guard closeX02.result agrees = some false, armsFor X02 arms = [(pos, pos)]', 'synthetic', 'PASS', 'disagrees: flagged')
case('X03', 'synthetic', 'SYNTHETIC: a chain through a loop variable that uses no arm',
     'meal ->+ blood glucose; blood glucose ->+ glycogen synthesis GO:0005978',
     'an ordinary chain; nothing to label',
     'PASS', 'nothing to label (right)', 'Stress: X03_belief; Proto: #guard classify X03 == plain', 'synthetic', 'PASS', 'plain')

# F. the closure over the textbook (scripts/stress/closure_loops.py)
F_GLU = 'glucose [CHEBI:17234] →− amount(glucose ⊓ located in (blood) [CHEBI:17234&RO:0001025=(UBERON:0000178)])'
F_GLU_INS = 'glucose [CHEBI:17234] →− amount(insulin ⊓ located in (blood) ⊓ part of (pancreatic beta cell) [PR:000009054&RO:0001025=(UBERON:0000178)&BFO:0000050=(CL:0000169)])'
F_AB = 'antibodies [GO:0019814] →− amount(antibodies ⊓ located in (immune system) [GO:0019814&RO:0001025=(UBERON:0002405)])'
F_EPO = 'lungs [UBERON:0002048] →− amount(erythropoietin [PR:000007141])'
F_GOIT = 'goiter [MONDO:0005397] →+ process(metabolic reactions [GO:0008152])'
F_FOOD = 'food intake [GO:0042755] →− process(food intake [GO:0042755])'
F_AP = 'membrane depolarization [GO:0051899] →+ process(membrane depolarization [GO:0051899])'
F_VGSC = 'voltage-gated sodium channel activity [GO:0005248] →+ process(membrane depolarization [GO:0051899])'
F_ADR = 'epinephrine [CHEBI:33568] →+ amount(insulin [PR:000009054])'
F_GLC = 'glucagon [PR:P01275] →+ amount(insulin [PR:000009054])'
F_ADRN = 'epinephrine [CHEBI:33568] →− amount(insulin [PR:000009054])'
F_ALDO = 'membrane depolarization [GO:0051899] →− amount(aldosterone ⊓ located in (blood) [CHEBI:27584&RO:0001025=(UBERON:0000178)])'
cpin = 'closure pins: data/stress/02b/closure_expect_*.json'
case('C01', 'closure', 'the closure meets the glucose round trip', F_GLU,
     'report the glucose loop, not an effect', 'FAIL', 'derived, b=0.64, flagged feedback', cpin, f"textbook {T('m45537-52')}, -53", 'PASS', 'core: roundTrip', fact=F_GLU, modes=('core', 'signed'))
case('C02', 'closure', 'a sign clash made by winding 1.5 times round the glucose loop', F_GLU_INS,
     'R3 -200 says glucose raises insulin; "glucose lowers insulin" is the loop wound one and a half times, not a second finding', 'FAIL', 'derived', cpin,
     f"textbook {T('m45537-200')}", 'PASS', 'core: roundTrip', fact=F_GLU_INS, modes=('core', 'signed'))
case('C03', 'closure', 'a cycle with no asserted loop (antibodies)', F_AB,
     'not homeostasis; the round trip should not stand as an effect', 'FAIL', 'derived', cpin, 'textbook cell-structure-and-function-m45433-63, -65',
     'FAIL', 'core: cycle', fact=F_AB, modes=('core', 'signed'))
case('C04', 'closure', 'a chain that crosses a loop and is right (lungs and EPO)', F_EPO,
     'lungs supply oxygen and oxygen lowers EPO, so poor lung function raises EPO: right, keep it', 'PASS', 'derived, b=0.64, no flag', cpin,
     f"textbook {T('m45537-238')}; Jelkmann2011", 'PASS', 'crosses', fact=F_EPO, modes=('core', 'signed'))
case('C05', 'closure', 'a chain that crosses a loop and is wrong (goiter and metabolism)', F_GOIT,
     'the book gives both signs (T3/T4 fall, so metabolism falls; TSH rises, so T3 and metabolism rise). The source does not settle it: in iodine deficiency T4 is subnormal but serum and free T3 are supranormal (Chopra 1975). So the clash should be reported, not resolved', 'SILENT', 'not derived', cpin,
     'textbook -263, -264, -129; Chopra1975', 'PASS', 'left as an unexplained sign clash', fact=F_GOIT, modes=('core', 'signed'))
case('C06', 'closure', 'an exactly reflexive round trip (leptin)', F_FOOD,
     'report the leptin loop', 'SILENT', 'not derived', cpin, f"textbook {T('m45537-251')}, -254", 'PASS', 'core: reflexive, read as roundTrip', fact=F_FOOD, modes=('core', 'signed'))
case('C07', 'closure', 'a positive round trip (action potential)', F_AP,
     'report the positive loop of -88', 'SILENT', 'silently dropped', cpin, f"textbook {G}m45539-88",
     'INEXPRESSIBLE (core: no positive homeostasis); PASS (signed)', 'signed: reflexive, read as roundTrip', fact=F_AP, modes=('core', 'signed'))
case('C08', 'closure', 'an arm into a positive loop (VGSC and depolarisation)', F_VGSC,
     'right as an effect; may be labelled with the loop', 'PASS', 'derived', cpin, f"textbook {G}m45539-89, -90, -83", 'PASS', 'signed: crosses', fact=F_VGSC, modes=('core', 'signed'))
case('C09', 'closure', 'a wrong chain the original closure cannot reach (adrenaline raises insulin)', F_ADR,
     'catecholamines inhibit insulin release (Porte 1966, Kris 1966): the chain is wrong; a label does not make it right', 'SILENT', 'not derived', cpin,
     'Porte1966, Kris1966', 'FAIL', 'signed_complete: crosses', fact=F_ADR, modes=('signed_complete',))
case('C10', 'closure', 'a right chain the original closure cannot reach (glucagon raises insulin)', F_GLC,
     'glucagon promotes insulin secretion (Samols 1965)', 'SILENT', 'not derived', cpin, 'Samols1965', 'PASS', 'signed_complete: crosses', fact=F_GLC, modes=('signed_complete',))
case('C11', 'closure', 'a true effect whose only derivation winds round the loop (adrenaline lowers insulin)', F_ADRN,
     'adrenaline does lower insulin, but through an alpha receptor mechanism (Porte 1967; not in the book), not round the glucose loop; the winding is not evidence. Its clash with C09 counts as explained, yet the side kept as an effect (C09) is the wrong one', 'SILENT', 'not derived', cpin,
     'Porte1966, Kris1966, Porte1967 (PMID 6018752)', 'PASS', 'signed_complete: roundTrip', fact=F_ADRN, modes=('signed_complete',))
case('C12', 'closure', 'a context error a loop label cannot fix (neuronal Na+ read as blood Na+)', F_ALDO,
     'neuronal depolarisation does not lower aldosterone: -83 is Na+ entering a neuron, -153 is blood Na+; the sodium in -153 lost its blood context', 'FAIL', 'flagged feedback', cpin,
     f"textbook {G}m45539-83, {T('m45537-153')}", 'FAIL', 'signed: crosses', fact=F_ALDO, modes=('core', 'signed'))

# --- observe, check, write
rows, bad = [], []
for c in C:
    if c['fact']:
        obs, pobs = closure_case(c['fact'], c['modes'])
    else:
        obs, pobs = OBS.get(c['id'], 'NO OBS LINE'), PROTO.get(c['id'], '')
        if c['pmark'] == 'PASS (proposal)': pobs = 'the proposal (homeostasis_m3.json) replaces -77 by homeostasis UBERON:0001898 (OBA:VT0005535); compiles in proposal_check.lean'
    ok = c['expect'] in obs and (c['pexpect'] is None or c['pexpect'] in pobs)
    if not ok: bad.append(c['id'])
    rows.append([c['id'], c['probes'], c['input'], c['correct'], obs, c['mark'], c['tests'], c['source'], c['group'], pobs or '-', c['pmark'], 'OK' if ok else 'RECHECK'])
missing = sorted(set(OBS) - {c['id'] for c in C})
with open(X / 'cases.tsv', 'w') as f:
    f.write('id\tprobes\tinput\tcorrect\tobserved\tmark\ttest\tsource\tgroup\tproto_observed\tproto_mark\tcheck\n')
    for r in rows: f.write('\t'.join(x.replace('\t', ' ').replace('\n', ' ') for x in r) + '\n')
marks = collections.Counter(r[5] for r in rows)
pm = collections.Counter(r[10].split(';')[-1].strip().split(' ')[0] for r in rows)   # the last option named (strict, signed) where there are two
print(f'{len(rows)} cases ({sum(1 for r in rows if r[0][0] != "C")} Lean, {sum(1 for r in rows if r[0][0] == "C")} closure); today: {dict(marks)}')
print(f'prototype: {dict(pm)}')
print('by group:', dict(collections.Counter((r[8], r[5]) for r in rows)))
if missing: print('OBS lines with no case:', missing)
if bad: print('RECHECK (observed text no longer contains what the mark rests on):', bad); sys.exit(1)
