# Program 06: an "opposes" relation

Written 2026-10-31, revised after an independent review. Decision 6. A program of work, not a
decision. Nothing in the core changed. Dan decides at the points in section 8.

Files: `BioLean/Stress/Opposition.lean` (today's core, 35 pins, about 4 s),
`BioLean/Proto/Opposes.lean` (prototypes of the options, 37 pins, about 11 s), `data/stress/06/`
(tables), `scripts/stress/opposes_*.py` (survey, lookups, table writer, quote and review checks).

## Summary

- **What I did.** 47 stress cases: 18 on OpenStax sentences (5 are library-wide runs), 24 on checked
  papers or curated records, 5 synthetic. Ran each on today's core and on prototypes of (b) to (h).
  168 CURIEs, 34 papers and 36 quotes checked.
- **Today: 26 PASS, 4 FAIL, 13 SILENT, 4 INEXPRESSIBLE.** Per-effector effects hold the antagonism
  (option a). Context already states drug antagonism as a conditional effect ("naloxone, in humans
  given morphine, raises breathing"). One FAIL is the book: parasympathetic skin blood flow is false.
- **Two holes are already in the core.** `Target.amount` takes any kind, so "parasympathetic lowers
  the amount of sympathetic" type-checks and derives false claims; a lint outside the core stops it.
  And a drug's plain per-target sign chains through `viaActivity` into "naloxone raises pain" (D07).
- **Rule (c) is right 15 times and wrong 20.** It makes six sentences theorems from "often have
  opposing effects". It also invents effects at sweat glands, adrenal medulla and body temperature,
  says auxin blocks cell division, and accepts `opposes a a`.
- **The per-target rule (f) is circular.** Its facts come from the parasympathetic sentence, so
  three of its six "theorems" rest on their own sentence; (a) gets the other three by annotating one
  more effect. The library already states all six twice.
- **What matters now.** Keep (a). Add the amount lint and a (b) report, both outside the core. No
  (c) or (f) for the six theorems. For drugs, conditional effects first.

## Words used here

| word | meaning here |
|---|---|
| effector | what a nerve or hormone acts on (heart rate, sweat gland) |
| single-branch effector | only one autonomic branch reaches it (sweat glands, adrenal medulla) |
| antagonism, per effector | two agents act on one target with opposite signs |
| neutral antagonist | a drug that blocks an agonist and does little alone (naloxone) |
| conditional effect | an effect stated under a condition: `Ctx.condition`, RO:0002573 has modifier |
| interaction | an effect on an effect: "a lowers b's effect on t" |
| flip | option (c)'s rule: a opposes b, b →s t, so a →(−s) t |
| promoted pair | a pair found by (b) on one target, then treated as a primitive opposition |
| circular | a derivation that rests on the sentence it derives |
| core change | a new Claim constructor, Derivation rule, opinion operator or type in `BioLean/*.lean` |
| outside the core | data, annotations, library definitions, lints, scripts |
| PASS, FAIL | right conclusion; wrong conclusion (I count unsupported conclusions asserted at 0.8 as FAIL) |
| SILENT, INEXPRESSIBLE | no conclusion where one is due; the case cannot be stated |
| R2, R3 | compiled textbook rounds (`BioLean/Lib/TextbookClaimsR2`, `R3`); R3 supersedes R2 |
| A, M, C, X | pair classes: antagonism; inhibitor and its enzyme; coincidence (both statements fair, not a pair); artefact (a statement misreads its sentence) |

## 1. The question

The hole search (`docs/holes.md`, rows 1 and 2, finding 1) found one hypothesis that would make six
textbook sentences theorems: heart rate, blood pressure and digestion, each way round
(`the-body-s-systems-m45539-299`, -300, -371 sympathetic; -306, -307, -308 parasympathetic). It could
only say it as "lowers the amount of", the wrong type. Should BioLean have an "opposes" relation,
and what kind? The provisional answer was "not yet; RO has none; per-effector effects suffice".

Three facts change the picture.
- **RO has antagonism relations**, just not this one: RO:0018027 "is agonist of", RO:0018028 "is
  inverse agonist of", RO:0018029 "is antagonist of", RO:0002568 "has muscle antagonist". All four
  are in `BioLean/RO.lean` and inert (T18). None relates two regulators of one target.
- **The wrong type is accepted.** "Lowers the amount of" type-checks, so the core already derives
  the six through it (T06).
- **The six are stated twice.** R2 holds 306 to 308 again as 374 to 376, and 299, 300 as 370, 372.
  Making them theorems changes the closure's count, not what the library knows.

## 2. What antagonism means, formally

| sense | example | formal shape | today |
|---|---|---|---|
| opposite signs on a shared target | sympathetic raises, parasympathetic lowers heart rate | a →+ t ∧ b →− t | stated, as two effects (a); GO does the same (GO:0003066, GO:0003063) |
| an interaction | naloxone reverses morphine's respiratory depression | a →− (effect of b on t) | the conditional effect is stated (T19b); the link to b's effect is not |
| a pair that licenses sign transfer | "the two divisions have opposing effects" | ∀t. b →s t ⇒ a →(−s) t | not stated; the one safe case I found is ChEBI's inverse agonist |

Rule (c)'s conclusion `a →(−s) t` needs (1) a to act on t at all, (2) an opposite sign there, (3)
the same context. (1) fails at single-branch effectors and off the receptor (morphine's histamine
release). (2) fails where the pair cooperates (salivary glands; calcitonin and PTH on calcitriol).
(3) fails where context flips the sign (GABA in neonatal neurons). (1) and (2) together are a
per-target fact: option (f).

## 3. What the vocabularies have

Checked 2026-10-31 (`data/stress/06/vocabularies.tsv`).

| source | what it has | gap |
|---|---|---|
| RO | agonist, inverse agonist, antagonist (sub-properties of "directly positively/negatively regulates activity of"); has muscle antagonist (not symmetric); "is opposite of" RO:0002604 (annotation property); "innervated by" RO:0002005 | nothing between two regulators of one target |
| GO | per-effector processes (GO:0003063, GO:0003066); "receptor antagonist activity" GO:0048019 is defined relative to an agonist | opposition is never a relation |
| ChEBI | roles antagonist CHEBI:48706, agonist CHEBI:48705, inverse agonist CHEBI:90847, mu-opioid receptor antagonist CHEBI:50137 and agonist CHEBI:55322 | the receptor is named in the label only; naloxone also has role "CNS depressant" (CHEBI:35488) |
| ChEMBL | naloxone ANTAGONIST at opioid receptors (CHEMBL2095181), morphine AGONIST at the mu receptor (CHEMBL233) | per drug and target: option (a) |
| UBERON | no "innervated by" axiom on heart, sweat gland, adrenal medulla, salivary gland or bronchus (OLS4) | dual innervation must be annotated |
| UBERON, GO, PATO, HP | no normal-movement term for elbow flexion or supination (MP:0008909 "supination" is an abnormal phenotype) | muscle effects are INEXPRESSIBLE |
| SIGNOR, IUPHAR GtoPdb | not reached (connection refused; HTTP 401) | UNVERIFIED |

## 4. The options

| option | idea | core change? | needs | right | wrong |
|---|---|---|---|---|---|
| (a) status quo | two signed effects per effector | none | nothing | states every per-effector antagonism the book gives | no "they oppose" fact; a drug's plain sign chains into over-general claims (D07) |
| (b) defined | `OpposesAt a b t` := a →+ t and b →− t, a structure over core derivations | none (library definition) | nothing | sound; finds 6 antagonist pairs on an exact shared target | derives nothing new; misses opposite targets; 7 of 50 pairs found are real |
| (c) primitive, unscoped | `opposes a b`, symmetric; `flip` gives a →(−s) t for every t | new Claim constructor; two Derivation rules (`symm`, `flip`); an a ≠ b guard | one statement per pair | the six theorems from -296, not circular; right at dual-innervation effectors, kinase and phosphatase pairs | invents effects at single-branch effectors, synergy, other contexts; accepts `opposes a a`; promoted pairs give nonsense |
| (c′) (c) discounted | flip discounted for "often", as `generalize` is for coverage | new rule | a rate | wrong conclusions would fall below 0.8 | still asserts them. Not prototyped |
| (f) primitive, per target | `opposesAt a b t`, sign-free; `flipAt` only at t | new Claim constructor; two Derivation rules | one statement per target | 0 new, 0 false in the library run | circular from the book: every book sentence that ties the opposition to a target also gives the sign there; from 374-377 it re-derives the false skin claim |
| (i) flip gated by innervation | (c), plus: the effector is innervated by both (RO:0002005) | new rule | innervation data (UBERON has none; the book has m45536-59, bronchi) | would refuse single-branch effectors (A04, A05, A07, A08) | still flips at salivary glands; needs a target-to-organ map. Not prototyped |
| (d) ChEBI roles | receptor roles bridged to signed effects by a hand table | none (emitter, data) | a role-to-receptor table | the same effects as ChEMBL | all roles would import "naloxone is a CNS depressant"; D07 as for (a) |
| (e) tied to homeostasis | `CounterReg a b held`: both in a `homeostasis` loop on the held quantity, opposite arms | none (library definition) | loop annotations | filters (b) to the two hormone pairs | 0 loops in the library; my 4 annotations pass by construction |
| (g) interaction target | `Target.effectOf b s t`: "a lowers b's effect on t" | new Target constructor | rules, later | states the antagonist-agonist link and accentuated antagonism | context already states the conditional effect, so (g) adds the link only; every match on Target changes |
| (h) opposite targets | "contraction is opposite of relaxation" widens (b) | none for detection; a rule would be core | a table of opposite pairs | finds the bronchi pair | RO:0002604 is not an object property |
| amount lint | anatomy amounts must be is_a UBERON:0000463 "organism substance"; no process, phenotype, function or disease amounts | none as a lint; a side condition on `Target.amount` would be core | the is_a closure | refuses the hole; keeps all 75 library amounts | only as good as UBERON's is_a |

## 5. The stress set

47 cases. Full table with inputs, CURIEs, sources, observed lines and tests:
`data/stress/06/cases.tsv`. Groups: A autonomic, H hormones, D drugs, K kinase and phosphatase, M
muscles, P plants, G neurotransmitters, L library-wide runs, S synthetic.

| id | probe | today | (b) | (c) | other options |
|---|---|---|---|---|---|
| A01 | heart rate | SILENT | PASS | PASS | f PASS in form, circular |
| A02 | blood pressure | SILENT | PASS | PASS | f as A01 |
| A03 | digestion | SILENT | PASS | PASS | f as A01 |
| A04 | skin blood flow (book false) | FAIL | FAIL | FAIL | f FAIL if annotated from 374-377 |
| A05 | temperature, sympathetic only | PASS | PASS | FAIL | |
| A06 | bronchi | PASS | SILENT | PASS | h PASS |
| A07 | sweat glands, sympathetic only | PASS | PASS | FAIL | |
| A08 | adrenal medulla, sympathetic only | PASS | PASS | FAIL | |
| A09 | saliva, both raise it | PASS | PASS | FAIL | |
| A10 | pupil | SILENT | SILENT | PASS | |
| A11 | left ventricle (synthetic input) | SILENT | SILENT | PASS | |
| A12 | accentuated antagonism | INEXPR. | INEXPR. | INEXPR. | g PASS |
| A13 | the hole's typing | FAIL | | | lint PASS |
| H01 | insulin, glucagon | PASS | PASS | PASS | e PASS with loops |
| H02 | glucagon and glucose import | PASS | PASS | FAIL | |
| H03 | hole typing for hormones | FAIL | | | |
| H04 | calcitonin, PTH | PASS | PASS | PASS | e PASS with loops |
| H05 | calcitriol (both raise it) | PASS | PASS | FAIL | |
| H06 | ANP against vasopressin | PASS (conditional) | SILENT | PASS (sign only) | g adds the link |
| H07 | adrenaline and insulin promoted | PASS | PASS | FAIL | |
| H08 | sympathetic and ANP promoted | PASS | PASS | FAIL | |
| H09 | K+ and Na+ at aldosterone | PASS | PASS | | e refuses |
| D01 | morphine, naloxone at the receptor | PASS | PASS | PASS | d PASS |
| D02 | naloxone alone and pain | PASS | PASS | FAIL | |
| D03 | morphine's histamine release | PASS | PASS | FAIL | |
| D04 | reversal of breathing depression | PASS (conditional) | SILENT | FAIL | g adds the link |
| D05 | importing ChEBI roles | PASS | | | d FAIL if all roles |
| D06 | RO antagonist relations | SILENT | | | |
| D07 | antagonist sign through `viaActivity` | FAIL | | | |
| K01 | Wee1, Cdc25 at CDK1 | PASS | PASS | PASS | |
| K02 | PI3K, PTEN at PIP3 | PASS | PASS | PASS | |
| M01 | biceps, triceps | INEXPR. | INEXPR. | INEXPR. | relation inert |
| M02 | biceps supination | INEXPR. | INEXPR. | INEXPR. | |
| P01 | auxin, cytokinin at branching | PASS | PASS | PASS | |
| P02 | auxin, cytokinin at cell division | PASS | PASS | FAIL | |
| P03 | root meristem | SILENT | SILENT | PASS | |
| G01 | GABA, glutamate, adult | SILENT | SILENT | PASS | |
| G02 | GABA, neonatal neurons | PASS | PASS | FAIL | |
| G03 | glutamate is GABA's precursor | PASS | PASS | FAIL | |
| L01 | (b) over the library | SILENT | FAIL as detector | | |
| L02 | (c) with the 3 book pairs | SILENT | | FAIL | |
| L03 | (c) with all 50 pairs promoted | SILENT | | FAIL | |
| L04 | (f) at the 3 book targets | SILENT | | | f PASS in count, circular |
| L05 | (e) as a filter | SILENT | | | e PASS by construction |
| S01 | two flips | PASS | | FAIL | |
| S02 | self-opposition | INEXPR. | | FAIL | |
| S03 | derived plus stated, fused | PASS | PASS | FAIL | f FAIL |

Tallies (`tallies.json`): today 26 PASS, 4 FAIL, 13 SILENT, 4 INEXPRESSIBLE. (c): 15 PASS, 20 FAIL,
3 INEXPRESSIBLE, 9 n/a. (b): 24 PASS, 2 FAIL, 7 SILENT, 3 INEXPRESSIBLE, 11 n/a. Many PASS marks
are "silent where nothing is due".

## 6. Results observed

Every number below is printed by a Lean file and pinned there.

**The six sentences.** (b) needs both sentences, so it makes none a theorem (`b_hr` rests on 299 and
306). (c) derives all six from their mirrors plus -296, at b=0.80 (`c306` and five more; each `def`
type-checks only if its conclusion is the stated claim). The hole route derives them at 0.64 (T06).

**(f) is circular.** Its three `opposesAt` statements cite the 306-308 sentence. So f306 rests on
that sentence and 299: the sentence derives itself. f299, f371 and f300 rest on that sentence alone
(`from306`). It does imply the sympathetic signs ("resets organ function after the sympathetic
nervous system is activated"), but (a) gets those by annotating one more effect. Fusing f306 with
stated 306 gives 0.889 from one sentence; the ids differ, so `sharedAxioms` cannot see it. From the
374-377 sentence instead, (f) re-derives the false skin claim (`f377`, 0.8).

**The book's own error.** "Activation of the parasympathetic nervous system ... increases ...
blood flow to the skin" (-377) is false: skin blood flow is under sympathetic vasoconstrictor and
active vasodilator control (Charkoudian 2003). It is an axiom at 0.8; (c), (f) from 374-377 and the
hole route re-derive it from -373. It is not yet in `data/textbook/false_as_written.tsv`.

**A drug's plain sign is not innocent (D07).** ChEMBL gives morphine →+ and naloxone →− mu receptor
activity. With "mu receptor activity lowers pain" (Matthes 1996), today's `viaActivity` derives
"morphine lowers pain" (right) and "naloxone raises pain" (b=0.56). That holds only where opioids
act: naloxone raised pain in placebo responders (Levine 1978), not in El-Sobky 1976. The GLP-1
library uses the same pattern. So D02's error is not only (c)'s.

**What context already says (T19b).** "Naloxone, in humans given morphine, raises breathing" and
"ANP, in rabbits with vasopressin, lowers renal water absorption" type-check today through
`Ctx.condition`. Missing is only the link to the agonist's own effect, which (g) would add.

**(b) over the library** (`b_pairs.tsv`). 365 plain effect claims give 82 statement pairs and 50
agent pairs with opposite signs on one target.

| class | pairs | examples |
|---|---:|---|
| A antagonism | 6 | autonomic branches; insulin and glucagon; PTH and calcitonin; ATP and ADP; adrenaline and insulin; adrenaline and vagal tone |
| M inhibitor and its enzyme | 1 | statins and HMG-CoA reductase |
| C coincidence | 28 | K+ and Na+ on aldosterone; ANP and the sympathetic system on blood pressure |
| X annotation artefact | 15 | "reabsorbed lowers ATP"; "denature raises kills" |

(b) misses pairs on opposite targets (bronchi), so its recall is not known.

**(c) over the library.** With the three book pairs, one forward step gives 16 conclusions: 12
restate the book (one is the false skin claim), 4 are new. Two new ones are consistent (bronchi).
Two are wrong: "parasympathetic lowers temperature homeostasis" (the principal thermoeffectors are
cutaneous vasoconstriction, shivering and brown fat, Morrison 2019) and "glucagon lowers glucose
import" (no source). With all 50 pairs promoted: 175 conclusions, 69 restate the library, 0 clash,
106 new (pair class A 24, C 59, X 21, M 2). A few A ones are true: insulin lowers lipolysis (Burns
1979); adrenaline lowers skin blood flow (m45537-182, "away from skin"). But the same real pair also
gives "insulin lowers glycolysis in skeletal muscle", which is false (Kelley 1990). Zero clashes is
no comfort: the library rarely states the opposite of an invented claim.

**Clashes the core cannot see.** Fused with (c)'s conclusion, "sympathetic nerves raise saliva
secretion" becomes contested (b=0.375, d=0.375) and "calcitonin raises calcitriol" unsupported
(0.79 to 0.605). Against a `noEffect` claim the core sees no clash.

**(e), (d), (g), (h).** (e): the example loop is on `amount glucose`, the arms on glucose in blood,
so nothing matches (T14); my four loop annotations pass 3 statement pairs, by construction. (d): 2 of
the 12 ChEBI roles of naloxone and morphine are receptor roles. (g): three interaction claims, no
rule uses them. (h): contraction opposite relaxation finds the bronchi pair (2 pairs).

**The typing hole and its lint.** Of 75 `amount` targets, 64 are chemicals or proteins and 11 are
not, all sensible (blood, milk, bacteria, T cells), so a kind-only restriction would break good
statements or let anatomy through. The lint refuses both hole statements and none of the 1,965
library statements.

**Strength.** (c) uses `weakest` (0.80). Fusing derived and stated 306 gives 0.889: the same book
counted twice (S03).

## 7. Experiments for later

Each has its exit test first, then the cost in agent tasks.

| id | experiment | exit test | cost |
|---|---|---|---|
| E1 | Add the amount lint to the closure search and the emitters (outside the core) | hole rows 1 and 2 are screened out of `holes.json`; all 75 library amounts still load | 1 |
| E2 | Add (b) as a report in the closure output, with the pair class column | the 6 A pairs are listed; precision is reported, not hidden | 1 |
| E3 | Add -377 (skin) to `false_as_written.tsv` with Charkoudian 2003 | the closure reports what rests on it | 1 |
| E4 | List sentences that state an opposition at a target without its sign | (f) is worth a core change only if it then derives sentences from other sentences | 1 |
| E5 | Annotate the 7 loops the closure flags; run (e) as a filter on (b) | (e) keeps the counter-regulatory pairs and refuses every C and X pair | 2 |
| E6 | Survey the book for interaction sentences ("blocks the action of", "reverses"); encode each as a conditional effect | (g) is worth a core change only if at least 10 need the link, not just the conditional effect | 1 |
| E7 | Import ChEMBL action types as effects on receptor activity (emitter), antagonists marked | "semaglutide activates GLP1R" comes from ChEMBL; no antagonist chains through `viaActivity` unconditioned (D07 flips) | 2 |
| E8 | Re-run the (b) and (c) scans on SIGNOR or GO-CAM | precision of (b), error rate of (c) off the textbook | 2 |
| E9 | Annotate dual innervation for the effectors in this set, then prototype (i) | (i) keeps (c)'s 15 PASS and drops the FAILs at A04, A05, A07, A08 | 2 |

## 8. What would change the decision

- **For (f):** E4 finding sentences that state per-target opposition without the sign, so that (f)
  derives sentences from other sentences.
- **For (c) or (i):** E9 showing that gating by innervation removes the single-branch errors, and a
  use for the six theorems beyond the closure's count.
- **For (e):** loop annotations made for other reasons (`Claim.homeostasis`); then (e) is free.
- **For (g):** E6 finding many sentences that need the link, or an M8 drug question that needs it.
- **Against all of them:** if the closure never needs one sentence from its mirror, (a) plus the
  (b) report is enough.

Dan decides: (1) whether the amount lint (E1) goes in now; (2) whether the six theorems matter at
all, given that the library states them twice; (3) whether drug antagonism (conditional effects,
then g) is in scope before M8.

## 9. Limits

- Marks and pair classes are judgement, made after reading the observed lines.
- Some FAILs are unsupported, not refuted. No source is not a measured null.
- Several literature inputs are mine, from one abstract sentence. Weights are the default table.
- The (c) library runs are one forward step, done in Lean, not by `closure.py`. A full closure with
  (c) would chain flips and do worse (S01 shows two flips).
- (f), (e) and (h) ran only where I annotated them: upper bounds.
- R3 supersedes R2 by name; R3 records were not checked against their R2 twins.
- Nuances not encoded (see UNVERIFIED): blood pressure, airway innervation.

## 10. References (checked)

34 papers checked on Europe PMC and Crossref (`references_checked.tsv`, `review_refs.tsv`); the 29
used for a mark are below. Lean quotes are verbatim in the title or abstract (`quotes_checked.tsv`).

| PMID | first author, year | used for |
|---|---|---|
| 12744548 | Charkoudian 2003, Mayo Clin Proc | skin blood flow is sympathetic (A04) |
| 30256726 | Morrison 2019, Annu Rev Physiol | principal thermoeffectors (A05) |
| 2282916 | Sugenoya 1990, Eur J Appl Physiol | sudomotor activity and sweating (A07) |
| 18722510 | Schütz 2008, Neuroscience | sweat glands as a sympathetic target, mouse (A07) |
| 12482898 | Wilson 2002, J Physiol | sympathetic preganglionic neurones and adrenal release (A08) |
| 17157080 | Proctor 2007, Auton Neurosci | both branches raise salivary secretion (A09) |
| 28954227 | Liu 2017, Cell Rep | pupil: sympathetic dilator, parasympathetic sphincter (A10) |
| 26940639 | Machhada 2016, J Physiol | vagal control of left ventricular contractility, rat (A11) |
| 10954067 | Uijtdehaage 2000, Clin Auton Res | accentuated antagonism (A12, A01) |
| 25914789 | Gordan 2015, World J Cardiol | autonomic control of the heart (A02) |
| 30860751 | LeBouef 2023, StatPearls | "rest and digest" (A03) |
| 30380405 | Svendsen 2018, Cell Rep | glucagon stimulates insulin secretion (H03) |
| 25815174 | Felsenfeld 2015, Clin Kidney J | calcitonin stimulates 1,25D (H04, H05) |
| 10393981 | Shinki 1999, PNAS | calcitonin raises renal CYP27B1 (H05) |
| 3006248 | Dillingham 1986, Science | ANP inhibits vasopressin action (H06) |
| 2113769 | Kelley 1990, Am J Physiol | insulin raises muscle glycolysis (H07) |
| 226442 | Burns 1979, Diabetes | insulin inhibits lipolysis in human adipocytes (H07) |
| 20461002 | Olofsen 2010, Anesthesiology | naloxone reverses morphine respiratory depression (D04) |
| 186714 | El-Sobky 1976, Nature | no effect of naloxone on pain perception (D02, title only) |
| 80579 | Levine 1978, Lancet | naloxone raises pain in placebo responders (D02, D07) |
| 8893006 | Matthes 1996, Nature | morphine analgesia needs the mu receptor (D07) |
| 7694026 | Barke 1993, Life Sci | opiate histamine release is not via opiate receptors (D03) |
| 17480229 | Perry 2007, Cell Div | Cdc25 and Wee1 (K01) |
| 9593664 | Maehama 1998, J Biol Chem | PTEN dephosphorylates PIP3 (K02) |
| 33497074 | Tomizuka 2021, J Bone Joint Surg Am | biceps and supination (M02) |
| 639790 | van Hoecke 1978, Eur J Appl Physiol | biceps and pronator teres (M02, title only) |
| 21504914 | Müller 2011, Ann Bot | auxin and cytokinin at axillary buds (P01) |
| 19039136 | Dello Ioio 2008, Science | auxin and cytokinin in the root meristem (P02, P03) |
| 12209121 | Ben-Ari 2002, Nat Rev Neurosci | GABA excitatory in immature brain (G01, G02) |

Textbook: OpenStax, *Concepts of Biology*, Rice University, CC BY-NC-SA 4.0. Ontology terms: 168
CURIEs on OLS4 (`review_curies.tsv`; `curies_checked.tsv` has the first pass); one, GO:0036378, is
obsolete and is not used. ChEBI roles and ChEMBL mechanisms: `chebi_roles.tsv`,
`chembl_mechanisms.tsv`.

## 11. UNVERIFIED

- The parasympathetic effect on blood pressure running mainly through heart rate.
- Sparse sympathetic innervation of human airway smooth muscle.
- No source for glucagon lowering glucose uptake, ANP raising digestion, or the sympathetic system
  raising blood Na+: searched, not exhaustively.
- That the adrenal medulla, sweat glands and thermoeffectors have no parasympathetic control: the
  sources show the sympathetic side only.
- That naloxone alone does not raise breathing: no source found either way.
- That triceps has no role in forearm rotation: no source found either way.
- SIGNOR's and GtoPdb's vocabularies: not reached. ChEBI's source for naloxone as a CNS depressant: not found.
