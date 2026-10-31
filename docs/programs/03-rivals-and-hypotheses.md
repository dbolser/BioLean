# Program 03: rivals double-count; hypotheses weigh 0

Written 2026-10-30; reviewed that day and again on 2026-10-31 (review 2, fixes in 4.8). A program
of work, not a decision. Nothing in the core changed. Prototypes live outside it.

## Summary

- **What I did.** 41 stress cases (32 real rivalries from the history of biology, 9 synthetic), run in
  Lean on today's core (`BioLean/Stress/Rivals.lean`) and on a prototype outside it
  (`BioLean/Proto/Multinomial.lean`). Both compile, no `sorry`, 33 s and 24 s.
- **Most failures come from how evidence is entered, not from the maths.** Each experiment on both
  rivals, as the worked example does (A1): 10 PASS, 14 FAIL, 14 SILENT, 3 INEXPRESSIBLE. Same core,
  each item entered once (A2): 22 PASS, 1 FAIL, 15 SILENT, 3 INEXPRESSIBLE.
- **The M2 exit test leans on the double count.** Entered once, 1974 chemiosmosis is 5/7 for and
  Slater 5/7 against: neither reaches 4/5. The worked example's own docstring already says so.
- **A withdrawal year on an item (H): A2 plus H gives 26 PASS, 0 FAIL.** Only two of its gains rest
  on a dated outside record (Lesné's 2024 retraction; Boyer's 1962 result, re-identified in 1964).
  For the rest a curator picks the year, which puts the answer in by hand.
- **No frame type is needed; hypotheses keep weight 0.** The frame prototype (B2) is one ordinary
  `Statement` per rival and adds nothing to A2 plus H on real cases. Weight above 0 flips verdicts
  away from history. Mendel 1866 has data: enter it as data.
- **What matters now.** Adopt A: five curation rules and a lint, no core change. Then Dan decides on
  H, and whether it goes in the core (a field) or beside it (a withdrawal table). 11 of the 13 cases
  still SILENT are about weights (program 10a), not rivals.

## Words used here

| word | meaning here |
|---|---|
| rival | one of several claims competing for one slot: a mechanism, a cause, a structure |
| `Rivalry` | today's core: each rival's opinion is fused with disbelief (0, b, 1 - b) from each other rival's own belief b |
| double entry | one experiment entered on two rivals: support for one and refutation of the other |
| enter once | each item goes on one rival only; the rivalry carries it to the others |
| frame | a set of exclusive rivals; open (an extra cell "other") or closed (the list is complete) |
| verdict | established (belief at least 4/5), refuted (disbelief at least 4/5), contested (both at least 1/4), unsupported (anything else) |
| timeless | read with no year: `Statement.opinion`, which `Derivation.opinion` and `Rivalry.opinions` use |
| A1, A2, A2H | today's core: with double entry (A1); each item once, contexts split (A2); A2 plus a withdrawal year, emulated (A2H) |
| B1, B2, B3 | three readings of a frame; "B2 best" is B2 with A2's curation plus H |
| emitter | a script outside the core that writes ordinary `Statement`s |
| PASS, FAIL, SILENT, INEXPRESSIBLE | right verdict; wrong verdict; no verdict where one is due; the case cannot be stated |

## 1. The question

The title names two problems in `BioLean/Rivalry.lean`; the core's own theorem adds a third.

1. **Double counting.** `Examples/Chemiosmosis.lean` enters each experiment on both rivals, and the
   rivalry turns support for one into disbelief in the other again. The `Rivalry` docstring says
   "enter it once"; the worked example admits it is "partly counted twice" (else "both 0.714").
2. **Hypotheses weigh 0.** Right for Slater 1953 (no data). Wrong for Mendel 1866 (counts from
   crosses).
3. **The winner is never raised** (`Rivalry.belief_le`). "B is refuted, and A and B are the only
   options" cannot make A established inside a `Rivalry`.

The question for Dan: **which formal system do we want for rivals?** There are six shapes: curation
rules only; a field on `Evidence`; a new type; a new opinion operator; a new claim with a derivation
rule; a layer above the core.

## 2. The options

"Core" means the modules directly in `BioLean/` (`Claim`, `Derivation`, `Belief`, `Evidence`,
`Rivalry` and the rest), not its subfolders.

| | option | changes the core? | run? |
|---|---|---|---|
| A | keep `Rivalry`; five rules and a lint | no | yes (A2) |
| B1 | frame read as Jøsang's hyper-opinion | yes: a type and an operator | prototype |
| B2 | frame read as one binomial per cell | no: it is one `Statement` per cell | prototype |
| B3 | frame read as Smets' transferable belief model | yes: a type and an operator | prototype |
| C | graded likelihood per item | yes: a field and an operator | not run |
| D1 | `Rivalry` ignores shared items | yes: a changed definition | Python only |
| D2 | averaging fusion for shared sources | yes: an operator | not run |
| E1 | hypothesis weight above 0 | no: data | yes |
| E2 | base rate shared over a frame | small: a field | prototype |
| E3 | a proposal with data entered as data | no: curation | yes |
| F | Bayesian model comparison | yes: a type and an operator | not run |
| G | argumentation layer (Dung, ASPIC+) | yes: new types above `Statement` | not run |
| H | withdrawal year on an item | **yes, one field; or no, a side table** | yes, emulated beside the core |
| J | finding key on an item | yes: one field on `Evidence` | prototype |
| K | "one of these" as a claim, with a rule | yes: a `Claim` constructor and a `Derivation` rule | not run |

The research stage's option I (a frame lint; one rivalry per context) is folded into A.

**A. Keep `Rivalry`; five curation rules and a lint.**
- Idea. (1) Enter an experiment once, on the rival it singles out. (2) Evidence that fits several
  rivals goes in only as a refutation of those it excludes. (3) One rivalry per context
  (`Entity.inCtx`). (4) P against not-P, or any closed pair, is one `Statement`. (5) Co-causes,
  nested and coexisting mechanisms are not rivals.
- Core. No change. The lint has nine checks (`scripts/stress/rivals_lint.py`).
- Needs. Curator discipline.
- Right. A1 to A2: 10 FAILs and 3 SILENTs become PASS (4.2).
- Wrong. The worked example's 1974 theorem fails (5/7); R09 gets worse. R11b, S07, S11 still
  cannot be stated.

**B. A frame; each item entered once, on the cells it favours.**
- Idea. A `Frame` lists exclusive rivals, open or closed. B2, for cell x: an item is support if it
  favours x alone, refutation if it does not favour x, else nothing. So B2 is full double entry with
  no `Rivalry` step. B1: Jøsang's hyper-opinion. B3: Smets' model (empty-set mass is conflict).
- Core. B2: none; cell x is one ordinary `Statement` (`#guard Frame.b2IsStatements` on 55 of 57
  frames; the other two are R01c), so B2 can be an emitter. B1 and B3: a new type and operator.
- Needs. The cells each item favours; a closed flag.
- Right. B2 best: 27 PASS, 0 FAIL. No duplicate rivals (S09); base rates sum to 1 (S07); a closed
  pair's halves mirror each other (proved, `closedPair_mirror`).
- Wrong. Over A2H it adds one synthetic case (S07). A wrong frame is still wrong (plain B2 FAILs six
  cases). A closed frame turns "all false" into a false dispute (`S04_B2_closed_alarm`).

**C. A graded likelihood per item.** Idea: "Büeler 1993 favours protein-only 3 to 1 over virino"; B
is the 0-or-1 case. Core: yes, a vector on the item and an update rule. Needs: one number per item
per rival; no abstract gives one. Right: "favours more" (R06, R13, R21). Wrong: every number is
judgement. Not run.

**D. Dependence-aware fusion.** Idea: D1, rival i ignores items it shares with rival j; D2,
averaging fusion for shared sources (ROADMAP M6). Core: D1 changes `Rivalry.opinions`; D2 is a new
operator. Needs: an item key shared across statements. Right: D1 fixes R01b, S01, S03, S09, R16.
Wrong: D1 scores 14 PASS, 11 FAIL, worse than A. D2 not run.

**E. A positive prior for hypotheses.**
- Idea. E1: hypothesis weight above 0. E2: a base rate of 1/k per rival, in the projected probability
  only. E3: a proposal that reports data is entered as data.
- Core. E1: no (an `EvidenceModel` instance). E2: small. `Opinion.prob` already takes a base rate
  (`S07_prob_told_third`); missing is a place to store 1/k and the closed flag. E3: no.
- Needs. A weight; a frame; a check of each hypothesis item (ECO:0000034 is the "no data" kind).
- Right. E3 fixes Mendel (R12). E2 makes S07 statable. Wrong. E1 breaks more than it fixes (4.6).

**F. Bayesian model comparison** (Kass and Raftery 1995). Core: yes, a probability vector over a
frame. Needs: likelihoods (as C) and priors (as E2). Right: the standard method. Wrong: no
uncertainty mass, so "contested" and "no data yet" look alike (against `docs/design.md` section 2).
Not run.

**G. An argumentation layer (Dung 1995; ASPIC+).** Idea: rivals rebut; a retraction undercuts.
Core: yes, new types above `Statement`. Needs: dated attack edges (SEPIO:0000101 "contradicts",
SEPIO:0000008 "has_disputing_evidence_line"). Right: it names undercut (R08c, R09, R11b, S06).
Wrong: no strengths of its own; a second formalism. Not run.

**H. A withdrawal year on an item.**
- Idea. From that year the item stops counting: a retraction, or support superseded.
- Core, two routes. (a) In it: `withdrawn : Option Nat` on `Evidence`, read by `Statement.asOf`
  and by the timeless `Statement.opinion`. Read by `asOf` alone, a retracted paper still counts in
  every timeless derivation (`R11b_timeless_still_counts`). `opinionAt_of_le` and
  `forall_opinionAt` must be restated. (b) Beside it: a withdrawal table and a wrapper, as emulated
  here (`withdrawAt`); core theorems and timeless derivations do not see it. Program 10a's H1 and
  H2 are the same split.
- Needs. A dated record per item. Europe PMC flags retractions (PMID 16541076).
- Right. On top of A2: R08a, R08c, R11b, S06 become PASS; R09 FAIL becomes SILENT. No new FAIL.
- Wrong. Only R11b (a retraction notice) and R08c (a 1964 paper re-identifying Boyer's result) have
  an outside dated record. For R08a (illustrative), R09 (Needham) and S06 (synthetic) the curator
  picks a year near the expected verdict's: the answer goes in by hand. Done to Golgi 1873, it would
  add R03a (`R03a_golgi_withdrawn_1955`).

**J. A finding key on an item.** Idea: `Statement.distinctEvidence` keys on (PMID, finding). Core:
yes, one field on `Evidence`. Needs: a finding label. Right: R01c gives one answer in either order.
Wrong: rare (1 case in 41); rule 2 already avoids it.

**K. "One of these" as a claim, with a rule.** Idea: "A, B and C are the only options" is a claim
with evidence; a rule derives A from "one of A, B" and "not B", no stronger than the weaker premise.
Core: yes, a `Claim` constructor and a `Derivation` rule. Needs: evidence for closure, which
historical frames rarely have. Right: it raises the winner (S10, S11) inside the formal system,
and closure has a strength, so it can be wrong (S04). Wrong: the winner is capped by the closure
claim and by the loser's disbelief. Not run.

## 3. The stress set

Full table: `data/stress/03/cases.tsv` (input with CURIEs, correct conclusion and source, observed
numbers, marks under every option, Lean test names).

Marks. Expected verdicts at dated years come from a checked source (`EXPY` in
`scripts/stress/rivals_spec.py`). A wrong verdict is FAIL; else a missing due verdict is SILENT.
Nine cases add a rule (in R03b, 2023 must equal 2022). R11b is INEXPRESSIBLE under A because its
rule needs Lesné to stop counting; R08c, R09 and S06 miss the same premise but are scored, since
their verdicts could be reached without it.

| id | rivalry | probes | A1 | A2 | A2H | B2 best |
|---|---|---|---|---|---|---|
| R01a | Meselson and Stahl: semi, conservative, dispersive | one experiment refutes two | PASS | PASS | PASS | PASS |
| R01b | the same, generation 1 only | evidence fits two rivals | FAIL | PASS | PASS | PASS |
| R01c | the same, two findings of one paper | the PMID rule keeps the first | FAIL | PASS | PASS | PASS |
| R02a | DNA against protein (Avery; Hershey and Chase) | consensus lags evidence | PASS | PASS | PASS | PASS |
| R02b | DNA, protein, RNA (TMV) | exclusive only within a context | FAIL | SILENT | SILENT | SILENT |
| R03a | reticular theory against neuron doctrine | winner never raised | SILENT | SILENT | SILENT | SILENT |
| R03b | ctenophore syncytium (2023) | evidence from another context | FAIL | PASS | PASS | PASS |
| R04 | soup against sparks | context (crayfish) | SILENT | SILENT | SILENT | SILENT |
| R05 | Helicobacter, stress-driven acid, NSAIDs | co-causes as rivals | FAIL | PASS | PASS | PASS |
| R06 | lock-and-key, induced fit, selection | nested and coexisting | SILENT | SILENT | SILENT | SILENT |
| R07 | instructive against clonal selection | three rivals, weak items | SILENT | SILENT | SILENT | SILENT |
| R08a | chemiosmosis, the worked example | the M2 exit test | PASS | SILENT | PASS | PASS |
| R08c | chemiosmosis with Boyer 1962 and 1964 | an undercut | FAIL | SILENT | PASS | PASS |
| R08d | conformational coupling as a third rival | a nested rival | FAIL | SILENT | SILENT | SILENT |
| R09 | spontaneous generation against biogenesis | superseded evidence | SILENT | FAIL | SILENT | SILENT |
| R10 | neutral theory against selection | a live dispute | PASS | PASS | PASS | PASS |
| R11a | the amyloid hypothesis | a live dispute | PASS | PASS | PASS | PASS |
| R11b | Lesné 2006, retracted 2024 | a retraction | INEXPR | INEXPR | PASS | PASS |
| R12 | Mendel 1866, ignored until 1900 | a proposal with data | SILENT | PASS | PASS | PASS |
| R13 | Archezoa against secondary loss | many weak items | PASS | PASS | PASS | PASS |
| R14 | endosymbiotic against autogenous origin | the winner comes late | SILENT | SILENT | SILENT | SILENT |
| R15 | fluid mosaic against Davson-Danielli | evidence for the whole frame | SILENT | SILENT | SILENT | SILENT |
| R16 | adult human neurogenesis | P against not-P | SILENT | PASS | PASS | PASS |
| R16b | a textbook sentence on R16 | a consensus source votes | SILENT | SILENT | SILENT | SILENT |
| R17 | the genetic code: three readings | partial exclusions | SILENT | SILENT | SILENT | SILENT |
| R18 | double, triple, side-by-side helix | three rivals | SILENT | SILENT | SILENT | SILENT |
| R19 | two domains against three | P against not-P | PASS | PASS | PASS | PASS |
| R20 | Temin's provirus | a decisive pair | PASS | PASS | PASS | PASS |
| R21 | prion: protein only, virus, virino | evidence for two rivals | FAIL | SILENT | SILENT | SILENT |
| R22 | Red Queen against mutation purging | pluralism | FAIL | PASS | PASS | PASS |
| R23 | semaglutide: central or vagal (repo S9c, S9d) | same shape, both true | FAIL | PASS | PASS | PASS |
| R24 | dorsoventral inversion (Geoffroy) | an old proposal confirmed | PASS | PASS | PASS | PASS |
| S01 | synthetic: one experiment on both sides | the double count alone | FAIL | PASS | PASS | PASS |
| S03 | synthetic: one item rules out C only | a partial vote | FAIL | PASS | PASS | PASS |
| S04 | synthetic: all rivals false | an open frame | PASS | PASS | PASS | PASS |
| S05 | synthetic: one rival split in two | split invariance | FAIL | PASS | PASS | PASS |
| S06 | synthetic: an artefact withdrawn | supersession | SILENT | SILENT | PASS | PASS |
| S07 | synthetic: three bare proposals | base rates | INEXPR | INEXPR | INEXPR | PASS |
| S09 | synthetic: a rival listed twice | duplicates | FAIL | PASS | PASS | PASS |
| S10 | synthetic: an exhaustive pair | raise the winner | SILENT | PASS | PASS | PASS |
| S11 | synthetic: two partial exclusions | combine exclusions | INEXPR | INEXPR | INEXPR | SILENT |

R23 has no frame, so its B2 best repeats A2: the best curation is two separate statements.

## 4. Results observed

### 4.1 Tallies (41 cases)

| option | PASS | FAIL | SILENT | INEXPR | how observed |
|---|---:|---:|---:|---:|---|
| A1 today's core, double entry | 10 | 14 | 14 | 3 | Lean |
| A2 today's core, entered once | 22 | 1 | 15 | 3 | Lean |
| **A2H** A2 plus a withdrawal year | **26** | **0** | **13** | **2** | Lean (H emulated) |
| D1 dependence-aware `Rivalry` | 14 | 11 | 13 | 3 | Python mirror |
| B1 hyper-opinion | 23 | 3 | 15 | 0 | Lean |
| B2 per-cell binomial | 24 | 6 | 11 | 0 | Lean |
| B3 transferable belief model | 20 | 6 | 15 | 0 | Lean |
| **B2 best** (A2's curation plus H) | **27** | **0** | **14** | **0** | Lean |
| E1 at 1/10 (on A2) | 22 | 0 | 16 | 3 | Lean |
| E1 at 1/5 (on A2) | 21 | 0 | 17 | 3 | Lean |
| E1 at 3/10 (on A2) | 21 | 0 | 17 | 3 | Lean |

Real cases only (32), PASS, FAIL, SILENT, INEXPR: A1 9, 10, 12, 1; A2 16, 1, 14, 1; A2H and B2 best
both 19, 0, 13, 0.

### 4.2 Where the double count lives (A1 to A2)

- 10 FAILs become PASS: R01b, R01c, R03b, R05, R22, R23, S01, S03, S05, S09.
- 4 FAILs become SILENT: R02b, R08c, R08d, R21.
- 3 SILENTs become PASS: R12, R16, S10.
- **R08a gets worse, PASS to SILENT.** See 4.3.
- **R09 gets worse, SILENT to FAIL.** Entered once, Needham's broths keep voting, so 1877 reads
  "contested" for both rivals (1/2, 1/4 and 1/4, 1/2). The double entry was hiding a supersession
  problem.

8 of the 10 A1 PASS encodings use double entry; only R08a needs it. In R13 it settles the case in
1999, four years early (`R13_both_1999`); entered once, in 2003, as historians say (Tovar 2003;
Embley and Martin 2006). Caveat: A's rules were written after seeing these failures (X2 tests them
blind).

### 4.3 The worked example (R08a)

| encoding | 1965 chemiosmotic | 1965 C~I | 1974 chemiosmotic | 1974 C~I |
|---|---|---|---|---|
| repo (double entry) | contested (1/3, 1/3) | contested | established (25/31, 1/31) | refuted (1/11, 9/11) |
| entered once (A2) | contested | contested | unsupported (5/7, 1/7) | unsupported (1/7, 5/7) |
| entered once, the repo's real papers only | unsupported (0, 0) | unsupported | established (4/5, 0) | refuted (0, 4/5) |
| entered once, the 1965 report withdrawn in 1967 (A2H; B2) | contested | contested | established (5/6, 0) | refuted (0, 5/6) |
| repo, hypothesis weight 1/5 | contested (1/3, 2/5) | contested | established (105/131, 6/131) | unsupported (6/47, 37/47) |

Pinned: `R08a_once_1974_num`, `R08a_A2H_0_1974`, `R08a_B2_rests_on_withdrawal`,
`R08a_repo_1974_E1_hyp5_num`.

So, entered once, the M2 exit test holds only if an illustrative item is withdrawn, in a year chosen
by hand. The repo's real papers settle 1974 at exactly 4/5 only because the repo holds none of the
real reports of an intermediate. Program 09, with 62 real papers, finds Slater never refuted.

### 4.4 What H does, and what a frame adds on top

A2 to A2H (H only, no frame):
- R08a, R08c and S06 become PASS: the withdrawn support stops counting.
- R11b becomes PASS: Lesné 2006 stops counting in 2024; 2025 is still contested (46/95, 43/95).
  Read timeless, it still counts (60/109, 43/109; `R11b_timeless_still_counts`).
- R09 goes from FAIL to SILENT: with Needham withdrawn, 1877 is (2/3, 0), not yet established.

On these cases the numbers equal B2 best's (pins `{case}_A2H_*`). Adding the frame moves only two
synthetic cases. **S07**: three bare proposals get P = 1/3 each (`S07_E2_prob`); today 1/2 each,
summing to 3/2 (`S07_prob_sum`). **S11**: the closed triple can be stated, but B2 still gives A
belief 0; only B3 combines the two exclusions (289/400, `S11_B3_A_survives`). S10 is not a frame
win: a closed pair is one `Statement` today (`S10_A2_states_it`).

Not fixed by anything here:
- **A wrong frame.** Plain B2 FAILs R02b, R03b, R05, R06, R08d and R22. A's rules fix them.
- **Weights.** 11 of the 13 A2H SILENTs have items too weak to reach 4/5 by the year historians
  name: R02b, R04, R06, R07, R08d, R09, R14, R15, R17, R18, R21.
- **R03a**: Golgi 1873 still votes, holding the neuron doctrine at (2/3, 1/6) in 1955. Withdrawn
  then, it passes at exactly 4/5 (`R03a_golgi_withdrawn_1955`); a hand choice, so not scored.
- **R16b** is the "contested" rule (4.7).

### 4.5 B1 and B3 against B2

- **B1** dilutes: mass on several cells counts as uncertainty. It turns 3 B2 FAILs into SILENT
  (R05, R06, R08d) and misses S04 (17/37 disbelief each, `S04_B1_misses`).
- **B3** gets S11 and R14 right, but its conflict mass erases live disputes: R10, R11a, R16, R19
  fall to unsupported (amyloid at 0.06, 0.01: `R11a_B3_erases_dispute`). It FAILs R11b.

### 4.6 Hypotheses (option E)

E1, hypothesis weight above 0. Verdict flips at scored years, on A2:

| weight | flips | towards history | away from history | wrong before and after |
|---|---:|---:|---:|---:|
| 1/10 | 5 | 1 (R21) | 2 (R13) | 2 (R09) |
| 1/5 | 7 | 1 (R21) | 4 (R01a, R13) | 2 (R09) |
| 3/10 | 8 | 1 (R21) | 4 (R01a, R13) | 2 (R09) |

At 3/10 one more flip falls in a year with no expected verdict. On A1 every scored flip goes away
from history. Full list: `data/stress/03/e1_flips.tsv`.

Why: cumulative fusion never forgets, so a losing proposal votes for ever. At 1/5, Slater's 1953
proposal and the illustrative 1963 reviews (both `hypothesis`) hold C~I at 37/47 disbelief in 1974,
so `settled_1974` breaks. The one gain, R21, is a threshold accident (0.797 to 0.801 in 2010).

E3, Mendel entered as data: 1899 is (0.7, 0), unsupported, which is right; 1900 established
(28/31). As a hypothesis, 1899 is (0, 0).

### 4.7 Smaller findings

- **R01c.** `Statement.distinctEvidence` keeps the first item with a given PMID. Meselson and
  Stahl's two generations, in the two orders, give "dispersive" (0.7, 0) or (0, 0.7)
  (`R01c_order_decides`). Keyed by (PMID, finding), it is (0, 0.7) either way (option J).
- **R16.** P against not-P as a `Rivalry` is lopsided: "none in adults" reads unsupported (6/29,
  20/29). As one `Statement`, both halves read contested.
- **R16b.** One OpenStax sentence (the-body-s-systems-m45539-123, no taxon) turns a live dispute into
  "unsupported" (3/4, 1/6) in 2022: a weights problem, not a rivalry one.
- **R23.** Both semaglutide pathways act (Gabery 2020). As a `Rivalry`, S9c's disbelief rises from
  23/61 to 83/121 (`R23_rivalry_moves_S9c`). By R22's pluralism rule, a FAIL.
- **R05.** Acid is a co-factor of peptic ulcer, not refuted: anti-secretory drugs cut ulcer rates
  (Lanas and Chan 2017). Helicobacter displaced stress-driven acid as the primary cause, which has
  no ontology term, so the loser is a placeholder.
- **The lint** flags 15 of the 16 failing A1 encodings and 8 passing ones; it misses R23.

### 4.8 Corrections

| said before | observed |
|---|---|
| research stage: A1 12, 14, 11, 4; A2 21, 4, 12, 4 | A1 10, 14, 14, 3; A2 22, 1, 15, 3 (every dated year marked) |
| research stage: B2 is the best alternative | plain B2 24 PASS, 6 FAIL; its real gains all come from H |
| research stage: S10 INEXPRESSIBLE | A2 PASS: a closed pair is one `Statement` |
| review 1: H is one field read by `Statement.asOf` | also by the timeless `Statement.opinion`; or beside the core |
| review 1: H's gains count as evidence for H | 2 rest on an outside record (R08c, R11b); the rest on years picked by hand |
| review 1: 12 of 13 SILENTs are weights | 11; R03a is Golgi 1873 still voting |
| review 1: R05's loser, GO:0001696 gastric acid secretion, is refuted | acid is a co-factor; the loser is stress-driven acid (a placeholder) |
| review 1: double entry props up 8 PASSes; Slater alone holds C~I at 37/47 | only R08a needs it; Slater and the 1963 reviews |

Review 2 re-ran both Lean files, the generator, the mirror, the scorer and the lint: all matched the
saved outputs. Its fixes add three pins and change no number or mark.

## 5. Experiments for later

Costs are in agent tasks. Each exit test is written before the work.

| id | experiment | exit test, written first | core change? | cost |
|---|---|---|---|---|
| X1 | Re-express `Examples/Chemiosmosis.lean` with each item once (needs Dan: an existing file) | both M2 theorems hold with no item on two rivals, or the docstring names the withdrawal they need | no | 1 |
| X2 | Fair test of the rules and lint: 12 new rivalries written blind to them | the lint flags at least 4 in 5 FAIL encodings and at most 1 in 5 PASS ones (not counting double entry) | no | 2 |
| X3 | Option J in the core | R01c PASS on the core; no other pin in `Stress/Rivals.lean` changes | yes, a field | 1 |
| X4 | Option H in the core | every `A2H` pin holds with `withdrawAt` replaced by the field; `R11b_timeless_still_counts` flips; the two `opinionAt` theorems restated and proved | yes, a field | 2 |
| X5 | A frame emitter: one `Statement` per cell from a frame table | all 55 `b2IsStatements` frames reproduce; no B2 best pin changes | no | 1 |
| X6 | Combine partial exclusions without B3's conflict | S11 PASS; R10, R11a, R16, R19 stay contested | yes, an operator | 2 |
| X7 | Rerun A2H under program 10a's candidate weights | count the 11 weight SILENTs that pass; no new FAIL | no | 1 |
| X8 | Graded likelihoods (C) on R06, R13, R21 | no A2H PASS changes; R21 established by 2010 | yes | 2 |
| X9 | Rivalries from the textbook: R2 and R3 sentences stating a superseded view (m45437-163) | at least 10 found, each encoded and marked | no | 2 |
| X10 | Withdrawals from outside records only (Europe PMC retraction flags, re-identification papers) | every withdrawal year cites a dated record; count the A2H gains that survive | no | 1 |
| X11 | Option K on S10 and S11 | S11 PASS; S10 PASS without rule 4; S04 stays PASS; no A2H PASS changes | yes, a constructor and a rule | 2 |

Towards the roadmap: X1 makes the M2 exit honest. X4, X7 and X10 feed M6 (dated evidence and
weights). X6, X11 and G are the first steps of the argumentation layer in `docs/design.md` section 2.

## 6. What would change the decision

- **Shared items are rare in practice.** Then the lint is enough.
- **Most withdrawals have an outside record** (X10). Then the core field for H is worth it.
- **Dan wants base rates over rivals.** Then E2 is the one reason for a frame; a field may do.
- **Closed frames of three or more rivals are common.** Then S11 matters, and X6 or K earns a core
  change.
- **Program 10a raises weights.** Then most SILENTs pass, and double entry pushes verdicts early (as
  in R13): the rules matter more.
- **An argumentation layer is built anyway.** Then H is one kind of attack edge in it.

## 7. Limits

- Expected verdicts rest on review abstracts; the years are coarse. Evidence kinds for old papers
  are judgement calls; weights are `EvidenceModel.standard`.
- 34 placeholders (BLN:...) stand for theories with no ontology term, so nesting between rivals
  cannot be checked. GO has no term for semi-conservative replication or induced fit.
- A's rules and best frames were written after seeing the failures: A2 and A2H are best cases.
- Which items are withdrawn, and when, is judgement except in R08c and R11b.
- R23's expected verdicts are the repo's own, so A2's PASS there is by construction.
- Marks depend on the thresholds 4/5 and 1/4; R20 passes at exactly 4/5. D1 runs only in Python.
- The synthetic cases were designed to break the core. The 32 real cases are the fair test.

## 8. Files

- Lean: `BioLean/Stress/Rivals.lean` (today's core, plus H emulated: 501 theorems, 33 s) and
  `BioLean/Proto/Multinomial.lean` (prototype: 522 theorems, 57 `#guard`s, 24 s). Not imported by
  `BioLean.lean`; check with `lake env lean <file>`.
- Scripts: `scripts/stress/rivals_spec.py` (the cases), `rivals_gen.py` and `rivals_run.py`
  (generate, run, pin), `rivals_mirror.py`, `rivals_score.py`, `rivals_lint.py`, `rivals_verify.py`,
  `rivals_review_verify.py`, `rivals_recheck.py` (review 2).
- Data: `data/stress/03/cases.tsv`, `scores.tsv`, `tallies.json`, `e1_flips.tsv`, `lint.tsv`,
  `recheck_refs.tsv`, `recheck_curies.tsv` (review 2), the earlier checks, the raw Lean output and
  `run_log.txt`.

## 9. References (checked)

Rechecked 2026-10-31 by `scripts/stress/rivals_recheck.py` from a fresh download: 127 PMIDs on
Europe PMC, 28 DOIs on Crossref, 63 CURIEs on OLS4 (relations under `/properties`); none missing or
obsolete. Every registry title was read against the spec's claim for it. Years match for all PMIDs
but Burnet; all CURIE labels match. Lists: `data/stress/03/recheck_refs.tsv`, `recheck_curies.tsv`;
each case's sources are in `cases.tsv`.

Methods:
- Jøsang A 2016, Subjective Logic, doi:10.1007/978-3-319-42337-1. Jøsang A 2002, the consensus
  operator, doi:10.1016/s0004-3702(02)00259-x. Jøsang A 2017, multi-source fusion,
  doi:10.23919/icif.2017.8009820.
- Dempster AP 1967, doi:10.1214/aoms/1177698950. Smets P 1990, the transferable belief model,
  doi:10.1109/34.55104. Kass RE 1995, Bayes factors, doi:10.1080/01621459.1995.10476572.
- Dung PM 1995, doi:10.1016/0004-3702(94)00041-x. Modgil S 2014, ASPIC+,
  doi:10.1080/19462166.2013.869766. Besnard P 2001, doi:10.1016/s0004-3702(01)00071-6. Hunter A
  2012, doi:10.1016/j.artmed.2012.09.004.
- Clark T 2014, micropublications, PMID 26261718. Ciccarese P 2008, SWAN, PMID 18583197.

Papers named in this doc:
- Meselson M 1958, PMID 16590258. Griffith F 1928, PMID 20474956. Slater EC 1953, PMID 13111237.
- Mitchell P 1961, PMID 13771349. Boyer PD 1962, PMID 14014715. Mitchell RA 1964, PMID 5871845.
  Needham JT 1748, doi:10.1098/rstl.1748.0072. Mendel G 1866, doi:10.5962/bhl.title.61004.
- Lesné S 2006, PMID 16541076 (Retracted Publication); Retraction Note 2024, doi:10.1038/s41586-024-07691-8.
- Tovar J 2003, PMID 14614504. Embley TM 2006, PMID 16572163. Büeler H 1993, PMID 8100741.
  Gabery S 2020, PMID 32213703. Lanas A 2017, PMID 28242110.
- Textbook sentences (OpenStax Concepts of Biology, checked in `data/textbook/claims_m1`):
  how-cells-obtain-energy-m45437-163, the-body-s-systems-m45539-123; the rest are in `cases.tsv`.
- Vocabulary (OLS4): ECO:0000034, SEPIO:0000101, SEPIO:0000008; all 63 CURIEs in `recheck_curies.tsv`.

## 10. UNVERIFIED

- Golgi 1873 (golgi73), Ramón y Cajal 1888 (cajal88), Pasteur 1861 (pasteur61): no DOI or PMID
  found. Geoffroy Saint-Hilaire 1822 (geoffroy22): not checked.
- Burnet 1957, Aust J Sci 20:67: only the 1976 reprint (PMID 816431) is checked. The item is dated
  1957 from the reprint's title.
- Van Valen 1973, "A new evolutionary law" (cited by textbook m45465-33): not on Crossref.
- That prior weight 2 is Jøsang's default for multinomial opinions: from memory.
- When electrical synapses were first shown in vertebrates (R04 allows "unsupported" in 1959).
- R12's 1900 verdicts (particulate established, blending refuted): neither cited source speaks to
  the 1900 consensus, and the dispute with the biometricians ran on for years (from memory).
- The NIH 1994 consensus (PMID 8007082) has no abstract on Europe PMC; its content is not checked.
