# Program 01b: option (k) sketched and measured

Written 2026-11-01; reviewed and corrected the same day. The measured follow-up to decision 1 of
[program 01](01-universals-and-descent.md) (from instances to universals). It runs experiment E10
for real. This is a program of work, not a decision. Nothing in the core changed. Dan decides at the
points in section 7.

**Dan's lean (program 01):** option (k), common descent as a stated, defeasible default. His
reasons: DNA sequencing now gives direct evidence for loss, so loss is rarely in contention, and
well-known convergences are few.

Files:
- `scripts/stress/descent_sketch.py`: the sketch of (b), (b)+(k) and two variants; the lookups; the
  tables; `check`, which re-runs everything and asserts the numbers in this doc (28 checks).
- `BioLean/Stress/Descent.lean`: option (c) and today's core on the same rows, plus four textbook
  routes. 5 group pins, 10 kernel theorems, 2 `#check_failure`, 8 more `#guard`s; about 22 s.
- `data/stress/01b/`: `cases.tsv` (the full table), `scorecard.tsv`, `sketch.tsv`, `coherence.tsv`,
  `sensitivity.tsv`, `tallies.json`, `lineages.tsv` (68 NCBI lineages), `references_checked.tsv`,
  `curies_checked.tsv`, `quickgo_counts.tsv`, `lean_output.txt`.

## Summary

- **What was done.** E10, run. A Python sketch of (b) and (b)+(k) on program 01's 33 cases and 15
  new sourced cases, on real NCBI lineages. Each change was run with its record withheld and given:
  81 rows. Option (c) and today's core ran in Lean on the same rows, plus 4 textbook sentences.
- **The prediction held, partly by luck.** (b)+(k) on the 33 cases: 26 right, 4 wrong, 1 contested,
  2 silent, as predicted. But one "right" (N1) is a sketch artefact. Scored fairly it is 25 right.
- **Every (b)+(k) error is a change with no record.** That is by design: a record decides. 13 of
  the 14 right "given" rows are the record itself. The real finding is that **defeat matters**: if
  records fuse with the default, as today's `clash` does, right answers drop from 26 to 11 and 14
  cases read "contested".
- **It is not ready to build.** A 0.1 drop in one weight sends a third of the rows silent. As
  specified it is incoherent in 5 percent of clade pairs. Program 01's gate D3, written in advance,
  says not to build the Lean prototype on these results. As a predictor it is no better than "agree
  with your relatives" (0.36 precision each).
- **Today's core, 85 rows: 19 PASS, 7 FAIL, 43 SILENT, 16 INEXPRESSIBLE.** 6 of the 7 failures are
  free narrowing (rat gallbladder, human CMAH, Epifagus photosynthesis from a textbook sentence).
  Homology and "no animal has X" can already be stated (RO:0002158 "shares ancestor with"; `notRel`).
  What is missing is rules, not claim shapes.
- **What matters now.** (k) needs three core changes: an ancestor (bracket) rule, a default rule
  with defeat, and a conjunction that keeps disbelief. Convergence records need none. Run E14
  (weights off the knife edge) and E10b (are the losses on record?) first.

## Words used here

| word | meaning here |
|---|---|
| (b) | ancestor rule plus a retention premise. No record means uncertain |
| (k) | common descent as a default. No record means "kept", at (0.9, 0, 0.1) |
| (c) | today's `generalize` with bracketing coverage, then free narrowing |
| record | a sourced observation of one taxon: has, lacks, or lost (absent, with DNA or relic evidence) |
| lookup | a row the record answers by itself, with no inference |
| bracket | the two nearest groups of records around a node: its own branches first, then outgroups |
| Witmer level | I: both bracket groups have the trait (0.9, 0, 0.1). II: one does (0.5, 0, 0.5). III: none does (0, 0.9, 0.1) |
| withheld row (`-`) | the change record is not given. Tests prediction |
| given row (`+`, or no suffix) | the change record is given. Tests the brake |
| defeat | a record replaces the default for its lineage. It does not fuse with it |
| fusion | a record and the default are combined (`Opinion.fuse`); today's `clash` does this |
| conj | an AND of two opinions that keeps disbelief (Jøsang 2005). Not in the core |
| shares ancestor with | RO:0002158, RO's homology relation ("VBO calls this homologous_to"). In the core's RO table |
| coherent | "every member of a clade has X" is never believed more than the same claim for a clade inside it |
| core change | a new Claim constructor, Derivation rule, opinion operator or type in `BioLean/*.lean` |
| PASS, FAIL, SILENT, INEXPRESSIBLE | right; wrong; no conclusion where one is due (contested counts here); cannot be stated |

## 1. The question

Program 01 predicted a scorecard for twelve options. E10 asked for a sketch of (b) and (b)+(k) on
its 33 cases, with a sensitivity and a coherence check. Three questions:

1. Are the predicted cells right?
2. Where (b)+(k) is wrong, is it always a species that changed without a record?
3. What formal system would we be building, and what must change in the core?

## 2. What the sketch does

All numbers are exact fractions. `fuse` and the verdict thresholds (θ = 4/5, τ = 1/4) are BioLean's.

1. **Ancestor rule (Witmer 1995).** For a node, take the nearest record groups that bracket it: its
   own branches if two or more hold records, else outgroups walking up the NCBI lineage until two
   groups are found. Level I if most groups show the trait, II if one does, III if none.
2. **Dollo default (Farris 1977).** Gained once, lost many times, never regained. An ancestor that
   lacked the trait gives disbelief whatever the retention.
3. **Retention.** "Every member of T has X" = ancestor rule AND retention, by `conj`. A loss record
   inside T replaces retention. (b): no record gives a vacuous retention. (b)+(k): the default.
4. **Own records decide.** A record on T, or on a clade containing T, replaces the inference.
5. **Homology.** "X in A and in B comes from their common ancestor" is the bracket at their common
   ancestor. In (b)+(k) a convergence record (HOM:0000004) replaces it with disbelief.
6. **Narrowing goes through retention.** "S has X" is computed for S, never copied from a clade.

**Data.** NCBI lineages for 68 taxa from E-utilities (the imported `IsA.lean` has 324 taxa). Each
record is one curated item at 4/5 (`curatedDb`). Model-organism presence records are QuickGO
experimental annotation counts, all non-zero.

## 3. The options

Letters as in program 01. (k-f), (k+n), (k-out) and (k-t) are new here.

| option | idea | core change? | measured right | measured wrong |
|---|---|---|---|---|
| (b) | Witmer ancestor plus a retention premise | **yes**: a bracket rule; `conj` | coherent; right on every O case with a loss record | silent on every true universal; wrong on every convergence |
| (b)+(k) | (b) with descent as a default, defeated by a record | **yes**: as (b), plus a default rule with defeat | 26 of 33 (25 fairly); all 14 stateable new cases once the record is given | every change without a record; knife-edge weights; incoherent in 5 percent of pairs |
| (k-f) | (b)+(k) without defeat: records fuse, as `clash` does today | **yes**: as (b); no defeat rule | 11 of 33 | 14 of 33 contested: records cannot win |
| (k+n) | (b)+(k), with narrowing as a logical step | as (b)+(k); narrowing reuses `weakest` | coherent; same verdicts as (b)+(k) | as (b)+(k) |
| (c) | leave `generalize` as is | **no** | U1, U2, RMT1, the cytochrome b case | free narrowing: rat gallbladder, human CMAH; incoherent |
| (k-out) | run (k) outside the core; emit its predictions as `hypothesis` statements (weight 0) | **no**: a script and data | keeps the core sound; gives Dan his candidate list (program 01, E11 bin 3) | no belief, so universals stay with (c) |
| (k-t) | widen `transport` (today: effects only, weight 3/10) to `rel` claims | **yes, small**: an existing rule takes one more claim shape | not run | by arithmetic belief stays at or below 3/10: never established, so always silent |

### What formal system this would be

Checked against the code. "Stateable today" was tested in `Descent.lean`.

| piece | today's core | (b)+(k) needs | core change? |
|---|---|---|---|
| homology claim | `rel` with RO:0002158 (`homolClaim`) | the same | no |
| convergence record | `notRel` with RO:0002158 (`convRec`) | the same | no |
| "no animal has X" (H1) | `notRel` (`h1Claim`) | the same | no |
| "the common ancestor of T had X" | nothing | a new Claim constructor, probably | yes |
| bracket rule | nothing; `generalize` takes positive instances only | a new Derivation rule | yes |
| default with defeat | nothing; `clash` fuses | a new rule over a record set; its side condition "no loss record here" is closed-world, and every rule today is monotone | yes |
| AND that keeps disbelief | `chain` and `weakest` set disbelief to 0 | `conj` (new operator), or a pair of rules, one per sign, read through `clash` | yes |
| narrowing | `relChain` with the is_a law (`weakest`) | the same | no |
| hypotheses kept out of belief | `hypothesis` evidence kind, weight 0 | the same | no |

- **(k+n) keeps free narrowing.** It is safe only because the clade claim already carries every loss
  record inside the clade. Its coherence is by construction: it takes the best clade above.
- **Homology needs a rule, not a shape.** The core's only route to RO:0002158 is RO chain 29, from
  "derived by descent from" premises. No record supplies those, so the core is silent.

## 4. The stress set

| group | rows | what it probes |
|---|---:|---|
| program 01, as written (U, O, P) | 33 | the scorecard, measured |
| program 01 O cases, change record withheld | 18 | how much (k) rests on records |
| new cases, record withheld (`-`) and given (`+`) | 30 | Dan's named kinds: amitochondriate, organelle genes, pseudogenes, convergence |
| textbook routes (Lean only) | 4 | free narrowing of real OpenStax claims |
| **all** | **85** | |

Full table: `data/stress/01b/cases.tsv` (id, kind, probes, input, correct, observed, mark, observed
and mark for (b) and (b)+(k), letters, test, source).

### The 15 new cases

| id | claim tested | truth | kind | source |
|---|---|---|---|---|
| D01 | Entamoeba histolytica (NCBITaxon:5759) has a mitochondrion (GO:0005739) | false: mitosome, relic genes | amitochondriate | Clark 1995; Tovar 1999 |
| D02 | Henneguya salminicola (69463) has a mitochondrial chromosome (GO:0000262) | false | animal without mtDNA | Yahalomi 2020 |
| D03 | S. cerevisiae (4932) has complex I (GO:0045271) | false | mitochondrial complex lost | She 2018 |
| D04 | soybean (3847) expresses cox2 from its mtDNA | false: the active copy is nuclear | gene moved to the nucleus | Covello 1992 |
| D05 | chimpanzee (9598) makes vitamin C (GO:0019853) | false: GULO pseudogene | pseudogene, neighbours on record | Ohta 1999 |
| D06 | human (9606) has CMAH activity (GO:0030338) | false: 92-bp deletion | pseudogene | Chou 1998 |
| D07 | chicken (9031) has teeth (UBERON:0001091) | false | pseudogenes | Meredith 2014 |
| D08 | the icefish Chaenocephalus aceratus (36190) has haemoglobin (GO:0005833) | false | globin remnants | Cocca 1995 |
| D09 | Epifagus virginiana (4177) photosynthesises (GO:0015979) | false | plastid genes lost | Wolfe 1992 |
| D10 | coffee and tea caffeine synthase (GO:0102741) share an origin | false | convergence | Denoeud 2014; Huang 2016 |
| D11 | cattle (9913) echolocate (GO:0050959), bracketed by bats and toothed whales | false | convergence, **synthetic** | general knowledge |
| D12 | Typhlomys (687454) echolocates | true | convergent gain | He 2021 |
| D13 | lactase persistence (GO:0000016) has one origin in humans | false | convergence within a species | Tishkoff 2007 |
| D14 | Gastrotheca guentheri (394453) has lower-jaw teeth (UBERON:0003268) | true | re-evolution, Dollo broken | Wiens 2011; Paluh 2021 |
| D15 | mouse (10090) mtDNA encodes cytochrome b | true | retention | Bibb 1981 |

Outgroup records are sourced too (Dictyostelium mtDNA, Ogawa 2000; Candida complex I, She 2018;
alligator teeth, Wu 2013; toothless turtles, Meredith 2014). Each is in `cases.tsv`.

**Fairness.** 12 of the 15 new cases are false, because Dan's named kinds are all changes. Today's
core and (b)+(k) are both right on several rows (section 5). Agreement cases at scale are E11's job.

### The four textbook routes

| id | claim (sentence id; R2 or R3) | narrowed to | correct |
|---|---|---|---|
| TB1 | "plants are capable of photosynthesis" (photosynthesis-m45453-100; R2 only) | Epifagus | false (Wolfe 1992) |
| TB2 | "plants have chloroplasts" (photosynthesis-m45453-72; R3: `most`) | Epifagus | false |
| TB3 | "All mammals have teeth" (the-body-s-systems-m45535-39; R3: `most`) | baleen whales | false (Meredith 2009) |
| TB4 | "plants have mitochondria" (photosynthesis-m45453-71; R2 only) | mistletoe | true (Senkler 2018) |

TB1's source sentence: "Plants are capable of both photosynthesis and cellular respiration, since
they contain both chloroplasts and mitochondria." It is not flagged in
`data/textbook/false_as_written.tsv`.

## 5. Results observed

### 5.1 The scorecard, measured

Same rule as program 01 section 8. Cannot-state counts as S.

| | (b) predicted | (b) measured | (b)+(k) predicted | (b)+(k) measured | (c) predicted | (c) measured |
|---|---:|---:|---:|---:|---:|---:|
| R | 14 | 16 | 26 | 26 | 4 | 3 |
| W | 4 | 4 | 4 | 4 | 6 | 5 |
| C or ? | 1 | 1 | 1 | 1 | 1 | 0 |
| S | 14 | 12 | 2 | 2 | 22 | 25 |

Cells that moved (`scorecard.tsv`):

| case | column | predicted | measured | why |
|---|---|---|---|---|
| N1 | (b), (b)+(k) | S | R | **artefact**: the sketch treats "mitochondrial code 1" as a plain label. Program 01 predicted S because a compartment slot is missing. That is still true |
| LT3 | (b)+(k) | R | S | the guinea pig's recorded GULO loss is mouse's second outgroup: level II, 0.45 |
| RM4 | (b) | S | R | level III gives disbelief without any retention premise: "no ancestor, so no trait" |
| RM4 | (c) | W | S | only human is a positive instance; one sample brackets nothing (belief 0) |
| NT1 | (c) | R | S (cannot state) | no kind or term for a genetic code |
| L8 | (c) | ? | S | Vertebrata from human and mouse: 0.013 |

- The "exact match" for (b)+(k) is two moves that cancel. Scored fairly (N1 silent), (b)+(k) is
  25 R, 4 W, 1 C, 3 S, and (b) is 15 R, 4 W, 1 C, 13 S.
- (b) is less silent than predicted: a level III ancestor refutes with no retention premise.

### 5.2 Where (b)+(k) is wrong

26 wrong rows of 81. Every one is a change whose record was withheld or, in P mode, hidden by design.

| cause | rows | count |
|---|---|---:|
| loss or changed code, record withheld | N1-, N2-, N4-, L1-, L2-, L3-, D01-, D02-, D03-, D06-, D08-, D09- | 12 |
| gene moved to the nucleus, record withheld | D04- | 1 |
| species changed, record hidden (program 01 P cases) | RM1, RM2, RM3, RM5 | 4 |
| convergence, record withheld | CV1-, CV2-, CV3-, CV4-, D10-, D11- | 6 |
| gain, record withheld (gene transfer; re-evolution) | H1-, D14- | 2 |
| change below the species (cave population) | L6- | 1 |

- **Yes: these are program 01's "changed without a record" cases.** No error occurs once the record
  is given. That half is by design: rule 4 lets a record decide. 13 of the 14 right `+` rows are the
  record itself; only D11+ (synthetic) needs the bracket. (b) gets 12 of the same 15 right.
- **Recorded neighbours make it right.** Chimpanzee vitamin C (D05-) and rat vomiting (RM4): both
  outgroups carry a recorded loss, so the bracket is level III and the answer is "no".
- **Recorded neighbours also make it silent.** Mouse vitamin C (LT3, guinea pig lost), Typhlomys
  (D12-, mouse and rat lack echolocation) and chicken teeth (D07-, turtles lack teeth) get level II.
- **Two errors are gains, not losses.** H1- (aphids took carotenoid genes from fungi) and D14-
  (frogs regained lower teeth after 200 million years). The Dollo default forbids both.
- **Dan's premise.** Every loss with DNA evidence here was citable by hand. Whether a script can
  read them is E10b.

### 5.3 Defeat or fusion

The same sketch, but every record fuses with the inference (`fuse`), as `clash` does in today's
core. Variant (k-f) in `sketch.tsv`.

| rows | (b)+(k), defeat | (k-f), fusion |
|---|---|---|
| program 01's 33 | 26 R, 4 W, 1 C, 2 S | 11 R, 4 W, 14 C, 4 S |
| 15 new `+` rows | 14 R, 1 cannot state | 4 R, 9 C, 1 S, 1 cannot state |

- **Without defeat, (k) cannot be overruled.** Almost every override case reads "contested", even
  the record of regained teeth (D14+).
- **Defeat is the core change that makes (k) work.** (b) barely needs it: it says little, so a
  record has nothing to fight.

### 5.4 Coherence

Every pair of clades on the record and target lineages, for every row (`coherence.tsv`).

| rule | pairs | broad believed more than narrow | of which: record against default | of which: one-sided bracket |
|---|---:|---:|---:|---:|
| (b) | 58,949 | 0 | 0 | 0 |
| (b)+(k), as specified | 58,949 | 2,977 (5.1 percent) | 2,220 | 757 |
| (b)+(k), an agreeing record fuses | 58,949 | 757 | 0 | 757 |
| (k+n), narrowing as a logical step | 58,949 | 0 | 0 | 0 |

- **Record against default.** A species' own record is 0.8. The default for the clade above it is
  0.9 × 0.9 = 0.81. So "every mammal lactates" (0.81) beats "humans lactate" (0.8).
- **One-sided brackets.** Only in the five rows with a convergence record. "Every protostome has a
  camera eye" is refuted, but "every cellular organism has one" gets 0.45: only one side holds
  records, and nothing records an absence.
- **Both fixes change no verdict.** (k+n) is coherent by construction.
- (b) is coherent only because it believes almost nothing.

### 5.5 Sensitivity

Each value moved by 0.1 (upward moves capped at 0.99); verdict flips over the 81 rows.

| value | base | moved to | (b) flips | (b)+(k) flips | (b)+(k): right going silent | (b)+(k): wrong going silent |
|---|---:|---:|---:|---:|---:|---:|
| level I belief | 0.9 | 0.8 | 0 | 25 | 7 | 18 |
| level II belief | 0.5 | 0.4 or 0.6 | 0 | 0 | | |
| level III disbelief | 0.9 | 0.8 | 0 | 1 | 0 | 1 |
| default retention | 0.9 | 0.8 | 0 | 26 | 7 | 19 |
| record weight | 0.8 | 0.7 | 21 | 26 | 25 | 1 |
| any value | | upward | 0 | 0 | | |

- **Every flip goes to silence.** None turns right into wrong, or wrong into right.
- **The knife edge is the line between "(k) speaks" and "(k) is (b)".** At 0.8, (b)+(k) loses its
  true universals (U1, U2, LT1) and most of its errors.
- **A single record sits exactly at θ.** That holds in today's core too: every lookup PASS in
  `Descent.lean` is 4/5 = θ. Any discount loses it.
- The verdicts are a choice of weights, not a finding.

### 5.6 Prediction against "always agree"

26 predict rows: program 01's 11 P cases and the 15 new withheld rows. 9 are true; D13 cannot be
stated, so 25 are scored.

| rule | right | wrong | silent | precision |
|---|---:|---:|---:|---:|
| (b)+(k) | 8 | 14 | 3 (+1 cannot state) | 8/22 = 0.36 |
| always yes (the target has the trait) | 9 | 16 | 0 | 9/25 = 0.36 |
| nearest recorded relatives (majority at the first node with records) | 9 | 16 | 0 | 9/25 = 0.36 |

- E10's exit test: "(k), if its predict-mode precision is no better than always agree". **On this
  set it is no better**, under either reading of "always agree".
- (b)+(k) and "nearest relatives" are both right on RM4 and D05-. (b)+(k) is silent on LT3 (true),
  D07- and D12-.
- **This set is built from known changes** (17 of 26 rows are false). E11 is the fair test.

### 5.7 Today's core (option c)

On all 85 rows: **19 PASS, 7 FAIL, 43 SILENT, 16 INEXPRESSIBLE.**

| finding | rows | pin |
|---|---|---|
| Free narrowing gives a species what it lost. Mouse and human "establish" Euarchontoglires (biolib knows two children there), then the is_a law passes 8/9 to the rat | RM1, RM2, RM3, RM5, D06- | `rm1_rat_gallbladder`, `d06_human_cmah` |
| The same mechanism is right when nothing changed | RMT1, D15-, TB4 | `d15_mouse_cytb`, `tb4_viscum` |
| A textbook universal narrows to a plant that lost photosynthesis. Round 3's `most` blocks narrowing (silent) | TB1; TB2, TB3 | `tb1_epifagus`; `#check_failure` |
| The seventh failure: no population slot, so the surface-fish record speaks for the cave fish | L6- | group pin |
| Records are fused, not obeyed. With the human CMAH loss entered, `clash` gives contested | D06+ | `d06_clash_contested` |
| A weak narrowed generalisation (belief 0.10 to 0.44) pulls a 0.8 loss record below θ | L1, L2, D01+, D03+, D05+ | group pins; L1 `#guard` |
| The record wins only when nothing else speaks | L4, D02+, D04+, D07+, D08+, D09+, CV1 to CV4, D10+ | group pins |
| A clade's loss record reaches its members through `notRelSub` | D07+ (Aves), D08+ (icefish family) | `d07_inherited_loss` |
| Homology is stateable (RO:0002158) but nothing infers it from shared presence | CV1- to CV4-, CVT1, CVT2, D10- | `homolRow`, `RO.chainOK` pin |
| "No animal makes carotenoids" is stateable; nothing widens or revises it | H1, H1- | `h1Claim` pin |
| (c) is incoherent on ribosomes too, not only on transcription | U2 | `u2_cellular_above_eukaryota` |
| 46 of the 68 case taxa are outside the imported taxonomy, so `admissible` refuses them as instances | many | `outside_import`, `caseTaxa` |
| Cannot be stated: genetic codes (9 rows), "mitochondrion or a related organelle" (2), an ancestor that never had X (2), populations (3) | the 16 INEXPRESSIBLE rows | `kindName`, `shape`, `ctxFields` |

Program 01 said "Detection exists. Revision does not." Measured, it is sharper: the core detects a
recorded loss only as a contested reading, and a universal is never revised by it.

## 6. Experiments for later

Exit tests are written before the run.

| id | what | exit test | cost (agent tasks) |
|---|---|---|---:|
| E14 | Take the weights off the knife edge: derive them from pseudo-counts, as program 10a does for evidence kinds | zero verdict flips under ±0.05 on all 81 rows, and the same letters as today | 1 |
| E10b | Are the losses machine-readable? For the 13 losses and code changes in 5.2, look for a record in a gene-loss resource (TOGA, Kirilenko 2023; Sharma 2018), GO NOT annotations, UBERON never-in | if 9 or more of 13 have a record a script can read, Dan's premise holds for these kinds; if 4 or fewer, (k) rests on hand curation | 1–2 |
| E11 | Rat against mouse hold-out (program 01), now on the sketch | (b)+(k) precision on hidden species, where all three species are recorded, beats "nearest relatives" by at least 0.1 | 2–3 |
| E16 | Convergence records at scale: Bgee and HOM rows for the six convergence cases | if fewer than half have a record, convergence defeat rests on hand curation | 1 |
| E17 | Import the 46 missing taxa (a data change by the owner of `import_isa.py`) and rerun `Descent.lean` | (c) letters on the 33 cases. Predicted: more FAIL, since better-covered clades establish more | 0.5 |
| E12 | Lean prototype of (k+n): a bracket rule, a default rule with defeat, `conj`. **Only after E14 passes** (program 01's D3 gate) | a theorem that a narrower claim is never below a broader one, and the 81 rows reproduce the sketch's letters | 3–5 |

## 7. What would change the decision

Program 01's gate D3 (section 10 there): build (b)+(k) in Lean only if "the sketch is coherent,
stable under the sensitivity check, and Archezoa replays". Else "(b) with a cap on top, or (e)+(f)
only". E10 result: Archezoa replays (A1, A1-). Coherent only with (k+n). **Not stable.** So, by the
rule written in advance, E12 waits for E14.

| finding | then favour |
|---|---|
| E14: stable weights exist | apply D3 again; if it passes, (k+n) with defeat; build E12 |
| E14: no weights are stable | (k-out): run (k) outside the core as a hypothesis generator; report brackets as levels, not numbers |
| E10b: most losses are machine-readable | (k+n) for universals and prediction (after E14) |
| E10b: most are not | (k-out); keep (c) documented |
| E11: no better than nearest relatives | (k) is not a predictor; use it for universals with records only |
| E16: convergence mostly unrecorded | (b)+(k) on present-or-absent traits only; homology claims stay silent |

## 8. Limits

- **A sketch, not a proof.** The grouping rules are design choices: majority at a polytomy;
  Fitch-style tie break with the first outgroup when inner sides disagree (not when outgroups do,
  hence LT3); the most specific own record wins; one group alone counts as a bracket (H1-).
- **NCBI Taxonomy is today's tree.** A1 (Archezoa) is refuted even with every relic withheld,
  because the tree already puts those lineages inside the eukaryotes. A 1989 tree would not.
- **The set is built from changes.** Both baselines are weak here.
- **Stand-ins against "cannot state".** D04, L4 and D15 run with `BLN:` stand-in genes. N1 to N4
  and NT1 could run the same way, but are kept INEXPRESSIBLE: a codon assignment has no kind. The
  line is a judgement.
- **`conj` drops Jøsang's base-rate terms.** That is conservative: belief comes out lower.
- **Every record weighs 4/5.** Papers of different designs would weigh differently (program 10a).
- **Out of scope:** organelle trees (option j), populations, life stages, counts.
- **"General" records** are facts not cited (listed in section 10).

## 9. References (checked)

All checked on Europe PMC on 2026-11-01 (title, first author, year, DOI), except where marked
Crossref. Re-checked independently in review: all 69 checkable keys in `references_checked.tsv`
matched.

Methods and background:
- Farris JS (1977). Phylogenetic analysis under Dollo's law. Systematic Zoology. doi:10.2307/2412867 (Crossref)
- Jøsang A (2005). Multiplication and comultiplication of beliefs. International Journal of Approximate Reasoning. doi:10.1016/j.ijar.2004.03.003 (Crossref)
- Collin R (2008). Reversing opinions on Dollo's Law. Trends Ecol Evol. PMID 18814933. doi:10.1016/j.tree.2008.06.013
- Albalat R (2016). Evolution by gene loss. Nat Rev Genet. PMID 27087500. doi:10.1038/nrg.2016.39
- Kirilenko BM (2023). Integrating gene annotation with orthology inference at scale. Science. PMID 37104600. doi:10.1126/science.abn3107
- Sharma V (2018). A genomics approach reveals insights into the importance of gene losses for mammalian adaptations. Nat Commun. PMID 29572503. doi:10.1038/s41467-018-03667-1

New cases and their outgroup records:
- Clark CG (1995). Direct evidence for secondary loss of mitochondria in Entamoeba histolytica. PNAS. PMID 7604025. doi:10.1073/pnas.92.14.6518
- Tovar J (1999). The mitosome, a novel organelle related to mitochondria in the amitochondrial parasite Entamoeba histolytica. Mol Microbiol. PMID 10361303. doi:10.1046/j.1365-2958.1999.01414.x
- Ogawa S (2000). The mitochondrial DNA of Dictyostelium discoideum: complete sequence, gene content and genome organization. Mol Gen Genet. PMID 10821186. doi:10.1007/pl00008685
- Yahalomi D (2020). A cnidarian parasite of salmon (Myxozoa: Henneguya) lacks a mitochondrial genome. PNAS. PMID 32094163. doi:10.1073/pnas.1909907117
- She X (2018). A mitochondrial proteomics view of complex I deficiency in Candida albicans. Mitochondrion. PMID 28801230. doi:10.1016/j.mito.2017.08.003
- Videira A (1998). Complex I from the fungus Neurospora crassa. Biochim Biophys Acta. PMID 9593837. doi:10.1016/s0005-2728(98)00020-6
- Senkler J (2018). Absence of Complex I implicates rearrangement of the respiratory chain in European mistletoe. Curr Biol. PMID 29731306. doi:10.1016/j.cub.2018.03.050
- Maclean AE (2018). Absence of Complex I is associated with diminished respiratory chain function in European mistletoe. Curr Biol. PMID 29731304. doi:10.1016/j.cub.2018.03.036
- Covello PS (1992). Silent mitochondrial and active nuclear genes for subunit 2 of cytochrome c oxidase (cox2) in soybean: evidence for RNA-mediated gene transfer. EMBO J. PMID 1382979. doi:10.1002/j.1460-2075.1992.tb05473.x
- Nugent JM (1991). RNA-mediated transfer of the gene coxII from the mitochondrion to the nucleus during flowering plant evolution. Cell. PMID 1714355. doi:10.1016/0092-8674(81)90011-8 (the registered DOI has "(81)"; Crossref resolves it to this 1991 paper)
- Ohta Y (1999). Random nucleotide substitutions in primate nonfunctional gene for L-gulono-gamma-lactone oxidase. Biochim Biophys Acta. PMID 10572964. doi:10.1016/s0304-4165(99)00123-3
- Nishikimi M (1994). Cloning and chromosomal mapping of the human nonfunctional gene for L-gulono-gamma-lactone oxidase. J Biol Chem. PMID 8175804. doi:10.1016/s0021-9258(17)36884-9
- Nishikimi M (1992). Guinea pigs possess a highly mutated gene for L-gulono-gamma-lactone oxidase. J Biol Chem. PMID 1400507. doi:10.1016/s0021-9258(19)36707-9
- Koshizaka T (1988). Isolation and sequence analysis of a complementary DNA encoding rat liver L-gulono-gamma-lactone oxidase. J Biol Chem. PMID 3338984. doi:10.1016/s0021-9258(19)77923-x
- Pollock JI (1987). Vitamin C biosynthesis in prosimians: evidence for the anthropoid affinity of Tarsius. Am J Phys Anthropol. PMID 3113259. doi:10.1002/ajpa.1330730106
- Maeda N (2000). Aortic wall damage in mice unable to synthesize ascorbic acid. PNAS. PMID 10639167. doi:10.1073/pnas.97.2.841
- Chou HH (1998). A mutation in human CMP-sialic acid hydroxylase occurred after the Homo-Pan divergence. PNAS. PMID 9751737. doi:10.1073/pnas.95.20.11751
- Meredith RW (2014). Evidence for a single loss of mineralized teeth in the common avian ancestor. Science. PMID 25504730. doi:10.1126/science.1254390
- Wu P (2013). Specialized stem cell niche enables repetitive renewal of alligator teeth. PNAS. PMID 23671090. doi:10.1073/pnas.1213202110
- Cocca E (1995). Genomic remnants of alpha-globin genes in the hemoglobinless antarctic icefishes. PNAS. PMID 7892183. doi:10.1073/pnas.92.6.1817
- Wolfe KH (1992). Function and evolution of a minimal plastid genome from a nonphotosynthetic parasitic plant. PNAS. PMID 1332054. doi:10.1073/pnas.89.22.10648
- Shinozaki K (1986). The complete nucleotide sequence of the tobacco chloroplast genome: its gene organization and expression. EMBO J. PMID 16453699. doi:10.1002/j.1460-2075.1986.tb04464.x
- Denoeud F (2014). The coffee genome provides insight into the convergent evolution of caffeine biosynthesis. Science. PMID 25190796. doi:10.1126/science.1255274
- Huang R (2016). Convergent evolution of caffeine in plants by co-option of exapted ancestral enzymes. PNAS. PMID 27638206. doi:10.1073/pnas.1602575113
- Tishkoff SA (2007). Convergent adaptation of human lactase persistence in Africa and Europe. Nat Genet. PMID 17159977. doi:10.1038/ng1946
- He K (2021). Echolocation in soft-furred tree mice. Science. PMID 34140356. doi:10.1126/science.aay1513
- Li Y (2010). The hearing gene Prestin unites echolocating bats and whales. Curr Biol. PMID 20129037. doi:10.1016/j.cub.2009.11.042
- Liu Y (2010). Convergent sequence evolution between echolocating bats and dolphins. Curr Biol. PMID 20129036. doi:10.1016/j.cub.2009.11.058
- Wiens JJ (2011). Re-evolution of lost mandibular teeth in frogs after more than 200 million years, and re-evaluating Dollo's law. Evolution. PMID 21521189. doi:10.1111/j.1558-5646.2011.01221.x
- Paluh DJ (2021). Re-evaluating the morphological evidence for the re-evolution of lost mandibular teeth in frogs. Evolution. PMID 34674263. doi:10.1111/evo.14379
- Bibb MJ (1981). Sequence and gene organization of mouse mitochondrial DNA. Cell. PMID 7332926. doi:10.1016/0092-8674(81)90300-7
- Anderson S (1981). Sequence and organization of the human mitochondrial genome. Nature. PMID 7219534. doi:10.1038/290457a0
- Anderson S (1982). Complete sequence of bovine mitochondrial DNA. J Mol Biol. PMID 7120390. doi:10.1016/0022-2836(82)90137-1

Program 01's sources used in the cases (Werner 2011 to Horn 2013) are in `references_checked.tsv`
and program 01 section 12.

**IDs checked.** Every NCBITaxon id against NCBI E-utilities (`lineages.tsv`; names match; re-checked
in review with esummary). Every GO, UBERON, CL, PR, HP, HOM, ECO and RO id on OLS4
(`curies_checked.tsv`, now with RO:0002156, RO:0002157 and RO:0002158, added in review). BFO:0000051
"has part" is on OLS4 only through another ontology's import.

## 10. UNVERIFIED

- Witmer 1995: a book chapter with no DOI (as in program 01).
- "General" records, not cited: cattle lactate and have teeth; human and mouse have teeth; human and
  zebrafish have eyes; zebrafish has haemoglobin; mouse, rat and cattle do not echolocate (D11 is
  synthetic for this reason); human and mouse camera eyes are homologous (CVT1); bat and mouse
  forelimbs are homologous (CVT2); mouse, rat and human have livers (RMT1).
- The axolotl's mandibular teeth (D14 outgroup) are cited to Wiens 2011, whose abstract does not
  name salamanders. Treat as general knowledge.
- Splenic sinusoids absent in mouse (RM5): from UBERON and the JAX Green Book only, as program 01.
- Rat activated T cells expressing MHC class II (RM2): as program 01.
- Tarsius "lacks" vitamin C synthesis is enzyme activity (Pollock 1987), not DNA evidence.
- `BLN:mt_cox2`, `BLN:mt_rpoB`, `BLN:mt_cytb` in `Descent.lean` are stand-ins: no ontology term for
  "gene X encoded by the mitochondrial chromosome". The T cell activation state in RM2 is not
  expressed (CL:0000084 is "T cell").
- Reading RO:0002158 at class level ("every X in A shares ancestor with some X in B") as historical
  homology of the structure is this program's reading, not RO's stated intent.
