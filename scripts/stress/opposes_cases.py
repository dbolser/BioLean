"""Program 06: write the stress-set tables from the Lean outputs.

Reads data/stress/06/lean_output_stress.txt and lean_output_proto.txt (the OBS, BPAIR and CNEW lines
printed by BioLean/Stress/Opposition.lean and BioLean/Proto/Opposes.lean), checks that every case
points at OBS lines that exist, and writes:
  data/stress/06/cases.tsv       one row per case
  data/stress/06/b_pairs.tsv     the 50 agent pairs with opposite signs on one target, with my class
  data/stress/06/c_promoted.tsv  the conclusions rule (c) adds when all 50 pairs are promoted
  data/stress/06/tallies.json    mark counts
Run: python3 scripts/stress/opposes_cases.py   (after running both Lean files into the outputs)
Marks are mine, set after reading the observed lines; the script only joins and counts.
"""
import collections
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
D = ROOT / "data/stress/06"

# ---- the 50 agent pairs: class and reason. A antagonism, M inhibitor and its enzyme,
# C coincidence (both statements are fair readings, nobody calls the agents a pair),
# X annotation artefact (at least one statement misreads its sentence). A process as agent is not
# by itself an artefact: "vasoconstriction lowers blood flow" is C.
PAIR_CLASS = {
    ("UBERON:0000011", "UBERON:0000013"): ("A", "the autonomic branches; the book says they oppose (m45539-296)"),
    ("CHEBI:33568", "UBERON:0000011"): ("A", "adrenaline and vagal tone on heart rate: functional antagonism"),
    ("CHEBI:15422", "CHEBI:16761"): ("A", "ATP and ADP as opposite regulators of glucose catabolism (book)"),
    ("PR:000013429", "PR:P01258"): ("A", "PTH and calcitonin on blood calcium (book)"),
    ("CHEBI:33568", "PR:000009054"): ("A", "adrenaline is a counter-regulatory hormone to insulin on blood glucose"),
    ("PR:000009054", "PR:P01275"): ("A", "insulin and glucagon on blood glucose (book m45537-331, -333)"),
    ("CHEBI:87631", "PR:000008636"): ("M", "a statin inhibits HMG-CoA reductase; one acts on the other"),
    ("MONDO:0005130", "NCBITaxon:12721"): ("C", "celiac disease and HIV both touch immune response"),
    ("CHEBI:35842", "MONDO:0005130"): ("C", "a drug class and a disease"),
    ("GO:0008037", "NCBITaxon:12721"): ("C", "a process and a virus"),
    ("CHEBI:35842", "GO:0008037"): ("C", "a drug class and a process"),
    ("CHEBI:23357", "PATO:0000146"): ("C", "cofactors and temperature on enzyme activity"),
    ("CHEBI:23357", "PATO:0001842"): ("C", "cofactors and pH"),
    ("CHEBI:23357", "CHEBI:23924"): ("C", "activators and inhibitors as classes; not a pair"),
    ("CHEBI:23357", "CHEBI:25212"): ("C", "cofactors and feedback products"),
    ("CHEBI:16761", "PATO:0000146"): ("C", "ADP and temperature"),
    ("CHEBI:16761", "PATO:0001842"): ("C", "ADP and pH"),
    ("CHEBI:16761", "CHEBI:23924"): ("C", "ADP and inhibitors as a class"),
    ("CHEBI:16761", "CHEBI:25212"): ("C", "ADP and products"),
    ("GO:0005886", "GO:0030164"): ("X", "'plasma membrane lowers kills' and 'denature raises kills'"),
    ("CHEBI:15422", "GO:0030164"): ("X", "'ATP lowers kills'"),
    ("GO:0006007", "GO:0070293"): ("X", "'reabsorbed lowers ATP' (renal absorption read into energy text)"),
    ("CHEBI:17514", "CHEBI:17544"): ("C", "cyanide and bicarbonate on pH"),
    ("GO:0045259", "GO:0070293"): ("X", "'reabsorbed lowers ATP'"),
    ("GO:0022904", "MONDO:0018754"): ("C", "electron transport and cyanide poisoning; the poison inhibits the chain"),
    ("CHEBI:10545", "MONDO:0018754"): ("C", "electrons and cyanide poisoning"),
    ("GO:0022904", "GO:0070293"): ("X", "'reabsorbed lowers ATP'"),
    ("GO:0009060", "GO:0070293"): ("X", "'reabsorbed lowers ATP'"),
    ("GO:0006119", "GO:0070293"): ("X", "'reabsorbed lowers ATP'"),
    ("GO:0006096", "GO:0070293"): ("X", "'reabsorbed lowers ATP'"),
    ("GO:0005814", "GO:0051726"): ("X", "'centrioles raise cell division', 'regulation of cell cycle lowers it'"),
    ("GO:0007588", "MONDO:0000001"): ("X", "'excretion raises homeostasis', 'disease lowers it'"),
    ("NCBITaxon:2", "UBERON:0000013"): ("C", "gut bacteria and the sympathetic system on digestion"),
    ("UBERON:0000013", "UBERON:0000062"): ("X", "'organs raise digestion'"),
    ("GO:0042310", "UBERON:0000948"): ("C", "vasoconstriction and the heart on blood flow"),
    ("GO:0042310", "PATO:0001025"): ("C", "vasoconstriction and osmotic pressure on blood flow"),
    ("GO:0042311", "UBERON:0001707"): ("C", "vasodilation and the nasal cavity on temperature"),
    ("GO:0060047", "UBERON:0001637"): ("X", "'pumping raises osmotic pressure'"),
    ("GO:0060047", "UBERON:0001103"): ("X", "'pumping raises osmotic pressure'"),
    ("CHEBI:18258", "CHEBI:25212"): ("C", "thyroid hormone and feedback products on metabolism"),
    ("CHEBI:46195", "MONDO:0008383"): ("C", "a drug and a disease on pain (treatment, not antagonism)"),
    ("CHEBI:23888&RO:0002162=(NCBITaxon:9606&RO:0002573=(MONDO:0008383))", "MONDO:0008383"): ("C", "medication and disease on pain"),
    ("GO:0042310", "GO:0060048"): ("C", "vasoconstriction and heart contraction on blood flow"),
    ("GO:0060048", "PR:P01160"): ("C", "heart contraction and ANP on blood pressure"),
    ("GO:0060048", "UBERON:0000011"): ("C", "heart contraction and the parasympathetic system on blood pressure"),
    ("PR:P01160", "UBERON:0000013"): ("C", "ANP and the sympathetic system on blood pressure; not a named pair"),
    ("CHEBI:15379&RO:0002162=(NCBITaxon:1485)", "GO:0005886"): ("X", "'oxygen raises kills' (anaerobes) and 'plasma membrane lowers kills'"),
    ("CHEBI:15379&RO:0002162=(NCBITaxon:1485)", "CHEBI:15422"): ("X", "'oxygen raises kills', 'ATP lowers kills'"),
    ("GO:0042311", "UBERON:0001898&RO:0001025=(UBERON:0001898)&RO:0002162=(NCBITaxon:7742)"): ("C", "vasodilation and the hypothalamus on temperature"),
    ("CHEBI:29101", "CHEBI:29103"): ("C", "two stimuli of aldosterone release; not antagonists"),
}

T, P = "Stress", "Proto"   # which Lean file a pin lives in

# Each case: id, group, synthetic, probes, input, curies, correct, source, today (mark, obs ids, test),
# options (text), and per-option marks b, c, other.
CASES = [
 # A. autonomic branches
 dict(id="A01", group="autonomic", syn="", probes="dual innervation: heart rate",
      input="the-body-s-systems-m45539-299 'sympathetic ... accelerated heart rate'; -306 'parasympathetic ... slowing of heart rate'; -296 'often have opposing effects'",
      curies="UBERON:0000013 UBERON:0000011 OBA:1001087",
      correct="both true; the branches oppose at heart rate, so each sentence follows from the other plus the opposition",
      source="textbook; Uijtdehaage 2000 PMID 10954067 (both branches control human heart rate)",
      today="SILENT", obs=["T01", "T03"], test=f"{T}: s306_lit; #no_lean m45539_296; #guard not is_a",
      b="PASS", c="PASS", other="f PASS in form but circular: f306 rests on the 306-308 sentence itself, and f299 on that one sentence alone; hole route FAIL (A13)",
      ptest=f"{P}: b_hr, b_hr_belief, c306, c306_belief, f306, f299, from306", pobs=["PROTO-b-six", "PROTO-c-six", "PROTO-f-book", "PROTO-f-circular"]),
 dict(id="A02", group="autonomic", syn="", probes="dual innervation: blood pressure",
      input="m45539-371 'sympathetic ... increases blood pressure'; -307 'parasympathetic ... lowered blood pressure'",
      curies="UBERON:0000013 UBERON:0000011 OBA:VT0000183",
      correct="both true in sign (the parasympathetic effect on pressure runs mainly through heart rate: UNVERIFIED nuance)",
      source="textbook; Gordan 2015 PMID 25914789 (heart rate and contractility under nervous control)",
      today="SILENT", obs=["T03"], test=f"{T}: s306_lit (same shape)", b="PASS", c="PASS", other="f PASS in form, circular as A01 (f307)",
      ptest=f"{P}: b_bp, c307, c371, f307, f371", pobs=["PROTO-c-six"]),
 dict(id="A03", group="autonomic", syn="", probes="dual innervation: digestion",
      input="m45539-300 'inhibited digestion'; -308 'stimulation of digestion'",
      curies="UBERON:0000013 UBERON:0000011 GO:0007586",
      correct="both true", source="textbook; LeBouef 2023 PMID 30860751 ('rest and digest')",
      today="SILENT", obs=["T03"], test=f"{T}: shape guard on the six", b="PASS", c="PASS", other="f PASS in form, circular as A01 (f308)",
      ptest=f"{P}: b_dig, c308, c300, f308, f300", pobs=["PROTO-c-six"]),
 dict(id="A04", group="autonomic", syn="", probes="a textbook overgeneralisation of 'opposing': skin blood flow",
      input="m45539-373 'sympathetic ... decreases ... blood flow to the skin' (R3); -377 'parasympathetic ... increases ... blood flow to the skin' (R3)",
      curies="UBERON:0000013 UBERON:0000011 GO:0008015 UBERON:0002097",
      correct="373 true; 377 false: skin blood flow is under sympathetic vasoconstrictor and sympathetic active vasodilator control",
      source="Charkoudian 2003 PMID 12744548",
      today="FAIL", obs=["T06"], test=f"{T}: s377 is an axiom at 0.8; h377 (hole route)",
      b="FAIL", c="FAIL", other="f PASS when scoped by the 306-308 sentence (0 new); FAIL when scoped by the 374-377 sentence, which lists skin (f377)",
      ptest=f"{P}: b_skin, c377, c377_belief, f377, f377_belief", pobs=["PROTO-c-skin", "PROTO-f-skin"]),
 dict(id="A05", group="single branch", syn="", probes="a sympathetic-only effector: temperature homeostasis",
      input="the-body-s-systems-m45534-81 'The sympathetic nervous system ... directs the responses that effect the changes in temperature loss or gain'",
      curies="UBERON:0000013 UBERON:0000011 GO:0001659",
      correct="no parasympathetic effect is due: the thermoeffectors are cutaneous vasoconstriction, shivering and brown fat",
      source="Morrison 2019 PMID 30256726",
      today="PASS", obs=["T06"], test=f"{T}: hThermo exists only through the hole", b="PASS", c="FAIL", other="f PASS (not in scope)",
      ptest=f"{P}: cThermo", pobs=["PROTO-c-thermo", "PROTO-c-book"]),
 dict(id="A06", group="autonomic", syn="", probes="opposite processes at one effector: bronchi",
      input="the-body-s-systems-m45536-60 (parasympathetic raises smooth muscle contraction in bronchi), -61 (sympathetic raises relaxation of smooth muscle in bronchi)",
      curies="UBERON:0000011 UBERON:0000013 GO:0006939 GO:0044557 UBERON:0002185",
      correct="both true as the book states them; the two oppose at bronchial tone (human airway sympathetic innervation is sparse: UNVERIFIED nuance)",
      source="textbook m45536-59 to -61",
      today="PASS", obs=["T13"], test=f"{T}: #guard contraction and relaxation differ",
      b="SILENT", c="PASS", other="h PASS (2 pairs once contraction is opposite relaxation); (c) adds 'para lowers relaxation' and 'symp lowers contraction', both consistent",
      ptest=f"{P}: hPairs", pobs=["PROTO-h", "PROTO-c-book"]),
 dict(id="A07", group="single branch", syn="", probes="a sympathetic-only effector: sweat glands",
      input="Sugenoya 1990: sympathetic sudomotor bursts precede sweat expulsion (stated as symp raises GO:0160269)",
      curies="UBERON:0000013 UBERON:0000011 GO:0160269",
      correct="no parasympathetic effect on sweating is due; sweat glands are innervated by sympathetic (cholinergic) neurons",
      source="Sugenoya 1990 PMID 2282916; Schütz 2008 PMID 18722510",
      today="PASS", obs=[], test=f"{T}: no rule takes two agents (ruleName)", b="PASS", c="FAIL", other="f PASS",
      ptest=f"{P}: cSweat", pobs=["PROTO-c-sweat"]),
 dict(id="A08", group="single branch", syn="", probes="a sympathetic-only effector: adrenal medulla",
      input="Wilson 2002: adrenal catecholamine release is mediated by sympathetic preganglionic neurones (stated as symp raises GO:0048242 in UBERON:0001236); docs/holes.md row 591",
      curies="UBERON:0000013 UBERON:0000011 GO:0048242 UBERON:0001236",
      correct="no parasympathetic effect on adrenal secretion is due",
      source="Wilson 2002 PMID 12482898",
      today="PASS", obs=[], test=f"{T}: ruleName", b="PASS", c="FAIL", other="f PASS",
      ptest=f"{P}: cAdrenal", pobs=["PROTO-c-adrenal"]),
 dict(id="A09", group="synergy", syn="", probes="both branches act the same way: salivary glands",
      input="Proctor 2007: parasympathetic nerves evoke saliva secretion; sympathetic nerves evoke protein release; combined stimulation augments it",
      curies="UBERON:0000011 UBERON:0000013 GO:0046541",
      correct="both raise secretion; no opposition",
      source="Proctor 2007 PMID 17157080",
      today="PASS", obs=[], test=f"{T}: (both effects expressible)", b="PASS", c="FAIL",
      other="(c) derives 'symp lowers saliva secretion'; read against the stated sympathetic effect: b=0.375 d=0.375, contested",
      ptest=f"{P}: cSaliva, saliva_contested", pobs=["PROTO-c-saliva"]),
 dict(id="A10", group="autonomic", syn="", probes="dual control through two muscles: pupil",
      input="Liu 2017: 'Pupil size is collectively controlled by the sympathetic dilator and parasympathetic sphincter muscles' (symp raises PATO:0001334 ⊓ characteristic of UBERON:0001771)",
      curies="UBERON:0000013 UBERON:0000011 PATO:0001334 UBERON:0001771 RO:0000052",
      correct="parasympathetic lowers pupil diameter", source="Liu 2017 PMID 28954227",
      today="SILENT", obs=[], test=f"{T}: (no rule)", b="SILENT (one side stated)", c="PASS", other="f would need an opposesAt at the pupil (not run)",
      ptest=f"{P}: cPupil", pobs=["PROTO-c-pupil"]),
 dict(id="A11", group="autonomic", syn="SYNTHETIC input", probes="a contested effector: left ventricular contractility",
      input="SYNTHETIC: textbook m45537-180 (adrenaline raises cardiac contraction) read as a sympathetic effect on the left ventricle",
      curies="UBERON:0000013 UBERON:0000011 GO:0060048 UBERON:0002084",
      correct="parasympathetic (vagal) tone lowers left ventricular contractility; its strength is called controversial",
      source="Machhada 2016 PMID 26940639",
      today="SILENT", obs=[], test=f"{T}: (no rule)", b="SILENT", c="PASS", other="",
      ptest=f"{P}: cLV", pobs=["PROTO-c-LV"]),
 dict(id="A12", group="interaction", syn="", probes="accentuated antagonism: one branch changes the other's effect",
      input="Uijtdehaage 2000: 'vagal effects became progressively stronger with increasing sympathetic background activity'",
      curies="UBERON:0000013 UBERON:0000011 OBA:1001087",
      correct="sympathetic activity raises the size of the vagal effect on heart rate (an effect on an effect)",
      source="Uijtdehaage 2000 PMID 10954067",
      today="INEXPRESSIBLE", obs=["T19"], test=f"{T}: targetShape (5 constructors, none an effect)",
      b="INEXPRESSIBLE", c="INEXPRESSIBLE", other="g PASS (stated as an interaction claim; no rule uses it)",
      ptest=f"{P}: iAccent", pobs=["PROTO-g"]),
 dict(id="A13", group="typing", syn="SYNTHETIC input", probes="the hole search's encoding: 'parasympathetic lowers the amount of sympathetic'",
      input="docs/holes.md rows 1 and 2, as effect claims on Target.amount",
      curies="UBERON:0000011 UBERON:0000013",
      correct="a nervous system has no amount; the claim should not type-check. It is rule (c) in disguise",
      source="docs/holes.md finding 1",
      today="FAIL", obs=["T06", "T22"], test=f"{T}: h306..h300, h377, hThermo, h306_belief; amountLint",
      b="n/a", c="n/a", other="the core accepts it and derives the six, the false skin sentence, and a false thermoregulation claim (b=0.64 each); a lint outside the core (anatomy amounts must be is_a UBERON:0000463) refuses it",
      ptest="", pobs=[]),
 # H. hormones
 dict(id="H01", group="hormones", syn="", probes="counter-regulatory hormones on one target: blood glucose",
      input="R3 m45537-53 'Insulin decreases blood-glucose levels'; R3 -201 'Glucagon causes the release of glucose to the blood'; -331, -333",
      curies="PR:000009054 PR:P01275 CHEBI:17234 UBERON:0000178",
      correct="insulin lowers and glucagon raises blood glucose; they oppose there",
      source="textbook m45537-331, -333", today="PASS", obs=["T08", "T02"], test=f"{T}: #guard same target, opposite signs",
      b="PASS", c="PASS", other="e SILENT on today's loop claim (T14); e PASS with loop annotations (e_glucose)",
      ptest=f"{P}: c53, e_glucose, ePass", pobs=["PROTO-c-glucose", "PROTO-e", "PROTO-e-glucose"]),
 dict(id="H02", group="hormones", syn="", probes="a second insulin target: glucose import",
      input="R2 m45537-202 'insulin facilitates the uptake of glucose by the body's cells' (GO:0098708)",
      curies="PR:000009054 PR:P01275 GO:0098708",
      correct="no glucagon effect on glucose import is stated in the book or in any source I checked; glucagon acts by liver glucose release",
      source="textbook m45537-201 text; no source for the (c) conclusion",
      today="PASS", obs=["T11"], test=f"{T}: #guard s202 target", b="PASS", c="FAIL", other="(c) conclusion unsupported, asserted at 0.8",
      ptest=f"{P}: cImport", pobs=["PROTO-c-import"]),
 dict(id="H03", group="typing", syn="SYNTHETIC input", probes="the hole encoding for a hormone pair",
      input="SYNTHETIC 'glucagon lowers the amount of insulin' + R3 m45537-53",
      curies="PR:P01275 PR:000009054 CHEBI:17234",
      correct="the premise is false: glucagon stimulates insulin secretion (true conclusion, false premise)",
      source="Svendsen 2018 PMID 30380405",
      today="FAIL", obs=["T07"], test=f"{T}: hGlc type-checks", b="n/a", c="n/a", other="", ptest="", pobs=[]),
 dict(id="H04", group="hormones", syn="", probes="counter-regulatory hormones: blood calcium",
      input="R3 m45537-135 'Calcitonin ... has the effect of reducing those levels'; R3 -140 'Parathyroid hormone increases blood calcium'",
      curies="PR:P01258 PR:000013429 CHEBI:29108 UBERON:0000178",
      correct="both true in sign; calcitonin deficiency or excess shows no bone or other abnormality in humans",
      source="textbook; Felsenfeld 2015 PMID 25815174",
      today="PASS", obs=["T09"], test=f"{T}: #guard", b="PASS", c="PASS", other="e PASS with loop annotations",
      ptest=f"{P}: c135, e_calcium", pobs=["PROTO-c-calcium", "PROTO-e"]),
 dict(id="H05", group="hormones", syn="", probes="a hormone pair that cooperates on another target: calcitriol",
      input="PTH raises calcitriol (Felsenfeld 2015); calcitonin raises calcitriol (Felsenfeld 2015; Shinki 1999)",
      curies="PR:000013429 PR:P01258 CHEBI:17823",
      correct="both raise calcitriol (calcitonin at a different tubule site); no opposition here",
      source="Felsenfeld 2015 PMID 25815174; Shinki 1999 PMID 10393981",
      today="PASS", obs=[], test=f"{T}: (both effects expressible)", b="PASS", c="FAIL",
      other="(c) derives 'calcitonin lowers calcitriol'; read against the sourced claim, it drags b 0.79 to 0.605 with d=0.236, verdict unsupported",
      ptest=f"{P}: cCalcitriol, calcitriolClash", pobs=["PROTO-c-calcitriol"]),
 dict(id="H06", group="interaction", syn="", probes="ADH and ANP: antagonism as an interaction",
      input="Dillingham 1986: atriopeptin III inhibits the water-permeability response to arginine vasopressin; book: ANP lowers blood volume and pressure (R2 m45537-299, -300)",
      curies="PR:P01160 CHEBI:34543 GO:0070295",
      correct="ANP lowers vasopressin's effect on collecting-duct water transport (an effect on an effect)",
      source="Dillingham 1986 PMID 3006248",
      today="PASS", obs=["T19", "T19b"], test=f"{T}: anpGivenAvp (a conditional effect, Ctx.condition); targetShape (the interaction itself)", b="SILENT", c="PASS (sign only: 'ANP lowers renal water absorption'; the interaction is lost)",
      other="today states the conditional effect 'ANP, in rabbits with vasopressin, lowers renal water absorption' but not the interaction; g PASS (iAnpAvp) adds the link to vasopressin's own effect",
      ptest=f"{P}: iAnpAvp, cAnpWater", pobs=["PROTO-g", "PROTO-c-water"]),
 dict(id="H07", group="promotion", syn="", probes="a real counter-regulatory pair promoted to a primitive: adrenaline and insulin",
      input="R3 m45537-181 (adrenaline raises blood glucose), -53 (insulin lowers it); then -182 (adrenaline raises glycolysis in skeletal muscle), -183 (adrenaline raises lipolysis in fat)",
      curies="CHEBI:33568 PR:000009054 GO:0006096 UBERON:0014892 GO:0016042 UBERON:0001013",
      correct="they oppose at blood glucose and at adipose lipolysis (insulin inhibits it); not at muscle glycolysis, which insulin raises",
      source="Kelley 1990 PMID 2113769; Burns 1979 PMID 226442",
      today="PASS", obs=[], test=f"{T}: (per-effector statements)", b="PASS", c="FAIL",
      other="(c) gives one true (insulin lowers lipolysis) and one false (insulin lowers muscle glycolysis) conclusion",
      ptest=f"{P}: cGlycolysis, cLipolysis", pobs=["PROTO-c-glycolysis", "PROTO-c-lipolysis"]),
 dict(id="H08", group="promotion", syn="", probes="a coincidental pair promoted: sympathetic system and ANP",
      input="R2 m45539-371 (symp raises blood pressure), R2 m45537-300 (ANP lowers it); then m45539-300 (symp lowers digestion), R3 m45537-301 (ANP lowers blood Na+)",
      curies="UBERON:0000013 PR:P01160 GO:0007586 CHEBI:29101",
      correct="no source says ANP raises digestion or that the sympathetic system raises blood Na+",
      source="none found (unsupported conclusions)",
      today="PASS", obs=[], test=f"{T}: (nothing derived)", b="PASS (definitional; a C pair)", c="FAIL",
      other="(c) asserts 'ANP raises digestion' and 'symp raises blood Na+' at 0.8",
      ptest=f"{P}: cDigANP, cNa1", pobs=["PROTO-c-ANP"]),
 dict(id="H09", group="not antagonists", syn="", probes="two stimuli with opposite signs: K+ and Na+ at aldosterone",
      input="R3 m45537-153 (Na+ lowers aldosterone), -156 (K+ raises it)",
      curies="CHEBI:29101 CHEBI:29103 CHEBI:27584 UBERON:0000178",
      correct="both statements true; nobody calls K+ and Na+ antagonists",
      source="textbook m45537-153 to -156",
      today="PASS", obs=["T12"], test=f"{T}: #guard", b="PASS (definitional; a C pair)", c="n/a",
      other="e PASS: no loop, so not counter-regulators", ptest=f"{P}: ePass", pobs=["PROTO-e"]),
 # D. drugs
 dict(id="D01", group="drugs", syn="", probes="agonist and antagonist at one receptor",
      input="ChEMBL: morphine agonist at mu opioid receptor (CHEMBL70); naloxone antagonist (CHEMBL80); ChEBI roles CHEBI:55322, CHEBI:50137",
      curies="CHEBI:17303 CHEBI:7459 PR:000001612 CHEBI:55322 CHEBI:50137 RO:0018027 RO:0018029",
      correct="morphine raises, naloxone lowers (an agonist's) mu receptor activity",
      source="ChEMBL mechanism records; ChEBI has_role (OLS4); Olofsen 2010 PMID 20461002",
      today="PASS", obs=["T15"], test=f"{T}: (example claims in T15)", b="PASS", c="PASS", other="d PASS (bridge gives the same two effects); the plain sign drops 'relative to an agonist', see D07",
      ptest=f"{P}: b_mor, bridged, cNalMOR", pobs=["PROTO-b-mor", "PROTO-d", "PROTO-c-mor"]),
 dict(id="D02", group="drugs", syn="", probes="a neutral antagonist alone",
      input="ChEBI: morphine has role opioid analgesic (morphine lowers pain perception)",
      curies="CHEBI:7459 CHEBI:17303 GO:0019233 CHEBI:35482",
      correct="it depends on opioid tone: no effect on pain perception in El-Sobky's subjects (title); raised postoperative dental pain in placebo responders, whose analgesia is endorphin-mediated (Levine 1978). As a universal, 'naloxone raises pain' is wrong",
      source="El-Sobky 1976 PMID 186714 (title); Levine 1978 PMID 80579",
      today="PASS", obs=["T15"], test=f"{T}: noEffect example", b="PASS", c="FAIL (over-general, and reached from morphine's analgesia, not from endogenous opioids)",
      other="(c) derives 'naloxone raises pain perception' at 0.8 beside a noEffect claim; the core has no clash for effect against noEffect; today's viaActivity reaches the same claim (D07)",
      ptest=f"{P}: cNalPain", pobs=["PROTO-c-pain"]),
 dict(id="D03", group="drugs", syn="", probes="an agonist effect not through the receptor",
      input="Barke 1993: opiates release histamine from mast cells",
      curies="CHEBI:17303 CHEBI:7459 GO:0002553",
      correct="no naloxone effect is due: the release is not mediated by known opiate receptors",
      source="Barke 1993 PMID 7694026",
      today="PASS", obs=[], test=f"{T}: (nothing derived)", b="PASS", c="FAIL", other="",
      ptest=f"{P}: cNalHist", pobs=["PROTO-c-histamine"]),
 dict(id="D04", group="interaction", syn="", probes="what drug antagonism means: reversal",
      input="Olofsen 2010: 'Opioid-induced respiratory depression is antagonized effectively by the competitive opioid receptor antagonist naloxone'",
      curies="CHEBI:7459 CHEBI:17303 GO:0007585",
      correct="naloxone lowers morphine's (negative) effect on breathing",
      source="Olofsen 2010 PMID 20461002; GO:0048019 definition (antagonist decreases the agonist's ability to activate)",
      today="PASS", obs=["T19", "T19b"], test=f"{T}: nalGivenMorphine (a conditional effect, Ctx.condition); targetShape (the interaction itself)", b="SILENT",
      c="FAIL ('naloxone raises breathing' as a plain effect at 0.8: a sign, not a reversal; no source for naloxone alone)",
      other="today states the conditional effect 'naloxone, in humans given morphine, raises breathing' but not its link to morphine's effect; g PASS (iNalMor) adds the link",
      ptest=f"{P}: iNalMor, cNalBreath", pobs=["PROTO-g", "PROTO-c-breath"]),
 dict(id="D05", group="drugs", syn="", probes="role data quality: importing ChEBI roles",
      input="OLS4 has_role for naloxone: CHEBI:35488 central nervous system depressant, CHEBI:50137, CHEBI:90755",
      curies="CHEBI:7459 CHEBI:35488 RO:0000087",
      correct="naloxone reverses opioid CNS and respiratory depression; I found no source that it is a CNS depressant",
      source="Olofsen 2010 PMID 20461002; ChEBI role list (OLS4, 2026-10-31)",
      today="PASS", obs=[], test=f"{T}: (no roles imported)", b="n/a", c="n/a",
      other="d FAIL if all roles were bridged; PASS with receptor roles only (2 of 12 roles bridged)",
      ptest=f"{P}: chebiRoles, bridged", pobs=["PROTO-d"]),
 dict(id="D06", group="drugs", syn="", probes="RO's own antagonism relations",
      input="RO:0018027 is agonist of, RO:0018028 is inverse agonist of, RO:0018029 is antagonist of (sub-property of RO:0002449 directly negatively regulates activity of); RO:0002568 has muscle antagonist",
      curies="RO:0018027 RO:0018028 RO:0018029 RO:0002568 RO:0002604",
      correct="by RO's definition an antagonist's binding reduces receptor activity to basal level, so a signed effect on receptor activity should follow",
      source="RO definitions on OLS4",
      today="SILENT", obs=["T15", "T18"], test=f"{T}: roUses guard", b="n/a", c="n/a",
      other="a bridge rel(is_antagonist_of) to effect(-, activity) would be an emitter rule (outside) or a Derivation rule (core)",
      ptest="", pobs=[]),
 dict(id="D07", group="drugs", syn="", probes="a per-target antagonist effect, chained by today's viaActivity",
      input="ChEMBL: morphine AGONIST, naloxone ANTAGONIST at the mu receptor, as signed effects on its activity; Matthes 1996: 'a lack of mu receptors abolishes the analgesic effect of morphine' (mu receptor activity lowers pain perception)",
      curies="CHEBI:17303 CHEBI:7459 PR:000001612 GO:0019233",
      correct="morphine lowers pain perception; naloxone raises pain only where opioids are acting (Levine 1978), not in general (El-Sobky 1976)",
      source="Matthes 1996 PMID 8893006; Levine 1978 PMID 80579; El-Sobky 1976 PMID 186714",
      today="FAIL", obs=["T23"], test=f"{T}: dMorPain, dNalPain, dNalPain_belief",
      b="n/a", c="n/a (no opposition needed)",
      other="today's core makes (c)'s naloxone error with no new rule (b=0.56): the plain per-target sign drops 'relative to an agonist'. Morphine's half is right",
      ptest="", pobs=[]),
 # K. kinase/phosphatase
 dict(id="K01", group="enzymes", syn="", probes="kinase and phosphatase with the kinase as inhibitor",
      input="Perry 2007: checkpoints 'inhibit the activators and activate the inhibitors of mitosis, Cdc25 and Wee1'",
      curies="PR:000017403 PR:000005193 PR:000003271",
      correct="Cdc25 (phosphatase) activates and Wee1 (kinase) inhibits CDK1: kinase is not always the activator",
      source="Perry 2007 PMID 17480229",
      today="PASS", obs=[], test=f"{T}: (expressible)", b="PASS", c="PASS", other="",
      ptest=f"{P}: b_cdk1, cWee1", pobs=["PROTO-b-cdk1"]),
 dict(id="K02", group="enzymes", syn="", probes="kinase and phosphatase on a lipid",
      input="Maehama 1998: PTEN dephosphorylates PIP3, reducing insulin-induced PIP3 production",
      curies="PR:000012719 PR:000028746 CHEBI:16618",
      correct="PI3K raises and PTEN lowers PIP3", source="Maehama 1998 PMID 9593664",
      today="PASS", obs=[], test=f"{T}: (expressible)", b="PASS", c="PASS", other="",
      ptest=f"{P}: b_pip3, cPTEN", pobs=["PROTO-b-pip3"]),
 # M. muscles
 dict(id="M01", group="muscles", syn="", probes="antagonistic muscles: biceps and triceps",
      input="RO:0002568 has muscle antagonist (biceps brachii, triceps brachii); textbook m45538-165 'Extension is the opposite of flexion' (no Lean)",
      curies="UBERON:0001507 UBERON:0001509 UBERON:0001490 RO:0002568",
      correct="biceps flexes and triceps extends the elbow; they are antagonists",
      source="UBERON:0001507 definition (OLS4); RO:0002568 definition",
      today="INEXPRESSIBLE", obs=["T20"], test=f"{T}: example rel 2568", b="INEXPRESSIBLE", c="INEXPRESSIBLE",
      other="the relation is expressible and inert; no OBO term for elbow flexion as a normal movement",
      ptest="", pobs=[]),
 dict(id="M02", group="muscles", syn="", probes="a second action of one antagonist: supination",
      input="Tomizuka 2021: biceps avulsion reduces supination force; van Hoecke 1978: biceps and pronator teres in pronation and supination",
      curies="UBERON:0001507 UBERON:0001509 UBERON:0001520",
      correct="biceps supinates; pronation is by pronator teres and quadratus; no source gives triceps a role in forearm rotation",
      source="Tomizuka 2021 PMID 33497074; van Hoecke 1978 PMID 639790; UBERON:0001520 definition",
      today="INEXPRESSIBLE", obs=["T20"], test=f"{T}: (no supination term)", b="INEXPRESSIBLE", c="INEXPRESSIBLE",
      other="(c) would say 'triceps lowers supination' if the term existed", ptest="", pobs=[]),
 # P. plants
 dict(id="P01", group="plants", syn="", probes="auxin and cytokinin at shoot branching",
      input="Müller 2011: 'auxin inhibits the activation of axillary buds ... while cytokinin has the opposite effect'",
      curies="CHEBI:22676 CHEBI:23530 GO:0010223",
      correct="auxin lowers, cytokinin raises shoot branching", source="Müller 2011 PMID 21504914",
      today="PASS", obs=[], test=f"{T}: (expressible)", b="PASS", c="PASS", other="",
      ptest=f"{P}: b_bud, cBud", pobs=["PROTO-b-bud"]),
 dict(id="P02", group="plants", syn="", probes="the same pair cooperating: cell division",
      input="ChEBI CHEBI:23530 definition: cytokinin promotes cell division",
      curies="CHEBI:22676 CHEBI:23530 GO:0051301",
      correct="auxin also sustains cell division (root meristem); no opposition here",
      source="Dello Ioio 2008 PMID 19039136; CHEBI:23530 definition",
      today="PASS", obs=[], test=f"{T}: (nothing derived)", b="PASS", c="FAIL", other="",
      ptest=f"{P}: cAuxDiv", pobs=["PROTO-c-division"]),
 dict(id="P03", group="plants", syn="", probes="the pair at root meristem size",
      input="Dello Ioio 2008: auxin sustains division; cytokinin promotes differentiation, controlling meristem size",
      curies="CHEBI:22676 CHEBI:23530 GO:0010449",
      correct="cytokinin lowers root meristem growth", source="Dello Ioio 2008 PMID 19039136",
      today="SILENT", obs=[], test=f"{T}: (no rule)", b="SILENT (one side stated)", c="PASS", other="",
      ptest=f"{P}: cCkRoot", pobs=["PROTO-c-root"]),
 # G. neurotransmitters
 dict(id="G01", group="transmitters", syn="", probes="GABA and glutamate in adult neurons",
      input="Ben-Ari 2002: GABA becomes inhibitory; glutamatergic excitation",
      curies="CHEBI:16865 CHEBI:29985 GO:0051899 CL:0000540 UBERON:0000113",
      correct="in adult neurons glutamate depolarises and GABA does not (it inhibits)",
      source="Ben-Ari 2002 PMID 12209121",
      today="SILENT", obs=["T21"], test=f"{T}: (expressible with context)", b="SILENT (one side stated)", c="PASS", other="",
      ptest=f"{P}: cGabaAdult", pobs=["PROTO-c-gaba"]),
 dict(id="G02", group="transmitters", syn="", probes="context: neonatal neurons",
      input="Ben-Ari 2002: 'In the immature brain, GABA ... is excitatory'",
      curies="CHEBI:16865 CHEBI:29985 GO:0051899 CL:0000540 UBERON:0007221",
      correct="GABA depolarises neonatal neurons; the pair does not oppose there",
      source="Ben-Ari 2002 PMID 12209121",
      today="PASS", obs=["T21"], test=f"{T}: #guard targets differ by life stage", b="PASS", c="FAIL",
      other="an unscoped opposition ignores context", ptest=f"{P}: cGabaNeo", pobs=["PROTO-c-gaba"]),
 dict(id="G03", group="transmitters", syn="", probes="one member is the other's precursor",
      input="GO:0004351 glutamate decarboxylase: L-glutamate = 4-aminobutanoate + CO2 (glutamate raises GABA)",
      curies="CHEBI:29985 CHEBI:16865 GO:0004351",
      correct="no 'GABA lowers GABA' conclusion is due", source="GO:0004351 definition",
      today="PASS", obs=[], test=f"{T}: (nothing derived)", b="PASS", c="FAIL", other="",
      ptest=f"{P}: cGabaSelf", pobs=["PROTO-c-gaba"]),
 # L. library-wide runs
 dict(id="L01", group="library", syn="", probes="(b) as an antagonist detector over the whole library",
      input="all 1,965 compiled R2/R3 statements (R3 supersedes R2), 365 plain effect claims",
      curies="", correct="the book's antagonist pairs, and few others",
      source="b_pairs.tsv (my labels)",
      today="SILENT", obs=[], test="", b="FAIL (as a detector): 50 agent pairs, 7 real (6 antagonist pairs + 1 inhibitor-enzyme), 28 coincidental, 15 artefacts",
      c="n/a", other="(b) as a definition is right by construction; as a reading of 'opposes' it is mostly wrong",
      ptest=f"{P}: bPairs, bAgentPairs, antagonistPairs", pobs=["PROTO-b-scan"]),
 dict(id="L02", group="library", syn="", probes="(c) with the three book pairs, one forward step",
      input="opposes(para, symp), opposes(insulin, glucagon), opposes(calcitonin, PTH)",
      curies="", correct="the book's per-effector sentences, and nothing at single-branch effectors",
      source="cases A01 to A06, H01, H02, H04",
      today="SILENT", obs=[], test="", b="n/a", c="FAIL (16 conclusions: 12 restate the book, 4 new: 2 consistent (bronchi), 2 wrong (thermoregulation, glucose import); 1 restated sentence is false (skin))",
      other="", ptest=f"{P}: cBook", pobs=["PROTO-c-book"]),
 dict(id="L03", group="library", syn="", probes="(c) with every (b) pair promoted",
      input="all 50 agent pairs as primitive oppositions",
      curies="", correct="nothing beyond what the pairs share",
      source="c_promoted.tsv",
      today="SILENT", obs=[], test="", b="n/a", c="FAIL (175 conclusions: 69 restate the library, 0 clash, 106 new; e.g. 'bacteria lower heart rate', 'ANP raises digestion')",
      other="", ptest=f"{P}: cAll", pobs=["PROTO-c-all"]),
 dict(id="L04", group="library", syn="", probes="(f) scoped to the three book targets",
      input="opposesAt(para, symp, t) for heart rate, blood pressure, digestion",
      curies="", correct="the six sentences, nothing else", source="textbook m45539-306 to -308",
      today="SILENT", obs=[], test="", b="n/a", c="n/a", other="f PASS in count: 11 conclusions, all restate the library, 0 new, 0 clash; but the opposesAt annotations come from the 306-308 sentence, so the restated parasympathetic three rest on their own sentence",
      ptest=f"{P}: fBook, from306", pobs=["PROTO-f-book", "PROTO-f-circular"]),
 dict(id="L05", group="library", syn="", probes="(e) as a filter on (b)'s pairs",
      input="four loop annotations (insulin, glucagon on blood glucose; PTH, calcitonin on blood calcium)",
      curies="", correct="the two hormone pairs; not K+/Na+ nor symp/ANP", source="H01, H04, H09",
      today="SILENT", obs=["T14"], test=f"{T}: #guard loop target mismatch", b="n/a", c="n/a",
      other="e PASS: 3 statement pairs pass, all the two hormone pairs; by construction, since I annotated loops only for those pairs (today 0 loops)",
      ptest=f"{P}: ePass, libLoops", pobs=["PROTO-e"]),
 # S. synthetic edge cases
 dict(id="S01", group="synthetic", syn="SYNTHETIC", probes="two flips: the enemy of my enemy",
      input="promoted opposes(symp, ANP) and book opposes(para, symp); R3 m45537-301 (ANP lowers blood Na+)",
      curies="UBERON:0000011 UBERON:0000013 PR:P01160 CHEBI:29101",
      correct="no parasympathetic effect on blood Na+ is known", source="none (unsupported conclusion)",
      today="PASS", obs=[], test="", b="n/a", c="FAIL ('para lowers blood Na+' at 0.8 through two flips)",
      other="", ptest=f"{P}: cNa2, cNa2_belief", pobs=["PROTO-c-ANP"]),
 dict(id="S02", group="synthetic", syn="SYNTHETIC", probes="self-opposition",
      input="SYNTHETIC opposes(naloxone, naloxone)",
      curies="CHEBI:7459 PR:000001612", correct="should be refused", source="logic",
      today="INEXPRESSIBLE", obs=["T01"], test=f"{T}: coreShapes", b="n/a", c="FAIL (accepted; flips naloxone's own effect)",
      other="needs a guard a ≠ b", ptest=f"{P}: cSelf", pobs=["PROTO-c-self"]),
 dict(id="S03", group="synthetic", syn="", probes="strength: the derived sentence fused with the stated one",
      input="c306 (from 299 and 296) fused with stated 306",
      curies="UBERON:0000011 OBA:1001087",
      correct="one textbook paragraph should count once", source="docs/design.md gap 1 (independence)",
      today="PASS", obs=["T03"], test=f"{T}: s306_lit", b="PASS (weakest, 0.8)", c="FAIL (both gives 0.889: the book counted twice)",
      other="f FAIL too: f306 fused with stated 306 gives 0.889 from one sentence, and the ids differ, so sharedAxioms cannot see it; the hole route gives 0.64 (chain product)",
      ptest=f"{P}: c306_both_belief, f306_both_belief", pobs=["PROTO-c-six", "PROTO-f-circular"]),
]


def read_obs(path):
    out = {}
    for line in open(path):
        if line.startswith("OBS\t"):
            _, k, v = line.rstrip("\n").split("\t", 2)
            out[k] = v
    return out


def main():
    so = read_obs(D / "lean_output_stress.txt")
    po = read_obs(D / "lean_output_proto.txt")
    missing = []
    for c in CASES:
        for k in c["obs"]:
            if k not in so:
                missing.append((c["id"], k))
        for k in c["pobs"]:
            if k not in po:
                missing.append((c["id"], k))
    if missing:
        print("missing OBS:", missing)
        return 1
    import re
    proto = (ROOT / "BioLean/Proto/Opposes.lean").read_text()
    stress = (ROOT / "BioLean/Stress/Opposition.lean").read_text()
    absent = []
    for c in CASES:
        for field, text in (("ptest", proto), ("test", stress)):
            body = c[field].split(":", 1)[1] if ":" in c[field] else ""
            for tok in re.split(r"[,;]", body):
                tok = re.sub(r"\(.*?\)", "", tok).strip()
                if re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", tok) and not re.search(rf"\b{tok}\b", text):
                    absent.append((c["id"], field, tok))
    if absent:
        print("test names not found in the Lean files:", absent)
        return 1
    cols = ["id", "group", "synthetic", "probes", "input", "curies", "correct", "source",
            "observed_today", "mark", "test", "observed_proto", "mark_b", "mark_c", "other_options", "test_proto"]
    with open(D / "cases.tsv", "w") as f:
        f.write("\t".join(cols) + "\n")
        for c in CASES:
            ot = " | ".join(f"[{k}] {so[k]}" for k in c["obs"]) or "nothing derived (no rule takes two agents; see T03 ruleName)"
            op = " | ".join(f"[{k}] {po[k]}" for k in c["pobs"])
            row = [c["id"], c["group"], c["syn"], c["probes"], c["input"], c["curies"], c["correct"], c["source"],
                   ot, c["today"], c["test"], op, c["b"], c["c"], c["other"], c["ptest"]]
            f.write("\t".join(x.replace("\t", " ").replace("\n", " ") for x in row) + "\n")
    # b pairs
    pairs = collections.OrderedDict()
    cnew = []
    for line in open(D / "lean_output_proto.txt"):
        if line.startswith("BPAIR\t"):
            _, a, al, ai, b, bl, bi, t = line.rstrip("\n").split("\t")
            k = tuple(sorted([a, b]))
            lab = {a: al, b: bl}
            e = pairs.setdefault(k, {"labels": (lab[k[0]], lab[k[1]]), "targets": set(), "ids": set()})
            e["targets"].add(t)
            e["ids"].update([ai, bi])
        elif line.startswith("CNEW\t"):
            cnew.append(line.rstrip("\n").split("\t", 1)[1])
    unl = [k for k in pairs if k not in PAIR_CLASS]
    if unl:
        print("unlabelled pairs:", unl)
        return 1
    with open(D / "b_pairs.tsv", "w") as f:
        f.write("agent_1\tlabel_1\tagent_2\tlabel_2\tclass\treason\ttargets\tstatements\n")
        for k, e in pairs.items():
            cl, why = PAIR_CLASS[k]
            f.write(f"{k[0]}\t{e['labels'][0]}\t{k[1]}\t{e['labels'][1]}\t{cl}\t{why}\t{'; '.join(sorted(e['targets']))}\t{' '.join(sorted(e['ids']))}\n")
    cls = collections.Counter(PAIR_CLASS[k][0] for k in pairs)
    # promoted conclusions by pair class
    by = collections.Counter()
    with open(D / "c_promoted.tsv", "w") as f:
        f.write("conclusion\tpair_class\n")
        for c in cnew:
            agent = c.split(" [", 1)[1].split("]", 1)[0] if " [" in c else ""
            src = c.rsplit("agent ", 1)[1].rsplit("): ", 1)[0]
            # the agent curie is the last [..] before the sign; read it robustly
            import re
            m = re.match(r"^(.*?) \[(.+?)\] [+-] ", c)
            agent = m.group(2) if m else agent
            k = tuple(sorted([agent, src]))
            cl = PAIR_CLASS.get(k, ("?", ""))[0]
            by[cl] += 1
            f.write(f"{c}\t{cl}\n")
    tallies = {
        "cases": len(CASES),
        "today": dict(collections.Counter(c["today"] for c in CASES)),
        "c_first_word": dict(collections.Counter(c["c"].split(" ")[0] for c in CASES)),
        "b_first_word": dict(collections.Counter(c["b"].split(" ")[0] for c in CASES)),
        "pairs_by_class": dict(cls),
        "promoted_new_by_pair_class": dict(by),
        "synthetic_cases": sum(1 for c in CASES if c["syn"]),
    }
    json.dump(tallies, open(D / "tallies.json", "w"), indent=1)
    print(json.dumps(tallies, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
