# Program 10a: evidence weights (M6)

Written 2026-10-31, reviewed the same day (section 4.6). Decision 10, part 1 of 3. This is a program
of work, not a decision. Nothing in the core changed. Dan decides at the points in section 6.

Files: `BioLean/Stress/Weights.lean` (cases, theorems, sensitivity, prototypes, 130 `#guard` pins;
compiles in about 45 s), `data/stress/10a/` (tables; `cases.tsv` is the full case table),
`scripts/stress/weights_*.py` (lookups, checks, pin writer, table writer).

## Summary

- **What I did.** Built 51 evidence scenarios (47 real, 4 synthetic) as Lean statements on today's
  core. Ran them under 32 prototype schemes, one per option or combination. Pinned every observed
  value with `#guard` (130 pins and 2 kernel-checked theorems).
- **What happened today.** 19 PASS, 22 FAIL, 5 SILENT, 5 INEXPRESSIBLE. Proved in Lean that a
  statement's verdict depends on two sums only. Established means S ≥ 4R + 8; refuted means
  R ≥ 4S + 8. So one textbook sentence is exactly enough, and two failed replications can never refute.
- **The M6 exit test passes today, and that is the problem.** No Ozempic sign flips when any kind is
  doubled or halved, and all 13 pseudo-counts are documented. The test cannot see what M6 adds. The
  real fragility is one Ozempic theorem at 0.805, which a 10 percent cut to the review weight breaks.
- **Outside the core, one option is safe.** Dropping retracted papers at import (H1) takes FAIL from
  22 to 19, loses no fair case and flips no example check (it does rewrite the past). Adding the Ioannidis table (H1 + I)
  looked better (FAIL to 15), but it loses the smoking case (W09): it needs 20 observational studies
  to establish anything. No scheme gets below 19 FAIL without losing a fair case.
- **A design claim is false.** design.md says INDRA's belief score is a special case of cumulative
  fusion. It is not: INDRA is noisy-OR (pinned: two items of 1/2 give 3/4, fusion gives 2/3).
- **What matters now.** Replace the exit test with wording B (section 4.4). The safe first step is
  H1. Test anything more on held-out cases (E1) first. If history matters, the one core change to look at first is an
  end year on `Evidence`: it serves dated retraction (H2) and supersession (N1).

## Words used here

| word | meaning here |
|---|---|
| opinion | three numbers: belief b, disbelief d, uncertainty u; they add to 1 |
| reliability r | what one item of a kind is worth, from `EvidenceModel.standard` |
| pseudo-count n | the same weight as a count of observations: n = 2r/(1 − r), so r = n/(n + 2) |
| S, R | a statement's total supporting and total refuting pseudo-counts |
| cumulative fusion | the core's way to combine items: pseudo-counts add |
| averaging fusion | Jøsang's way to combine items from one source: pseudo-counts are averaged |
| verdict | contested if b and d are both ≥ 0.25 (checked first); else established if b ≥ 0.8; refuted if d ≥ 0.8; else unsupported |
| scheme | one way to turn evidence into opinions. The core is one; each prototype is another |
| core change | a new Claim constructor, Derivation rule, opinion operator, type, or field in `BioLean/*.lean` |
| outside the core | data, import rules, a new `EvidenceModel` instance, scripts |
| import rule | the importer changes the evidence once, before Lean sees it. It cannot know the year asked, so it rewrites the past |
| end year | a year after which an item stops counting (retracted, superseded). Not in the core today |
| fair case | a case the core gets right today (PASS); a good option must keep it |
| ECO | Evidence and Conclusion Ontology. GO evidence codes map to ECO terms |
| IBA, IEA, EXP | GO evidence codes: inferred from an ancestor (phylogenetic), electronic, experimental |
| GRADE | a clinical method that rates a body of evidence high, moderate, low or very low |
| PASS / FAIL | the system reaches the right conclusion / a wrong one |
| SILENT | "unsupported" where a conclusion is due |
| INEXPRESSIBLE | the case cannot be stated in the system |

## 1. The question

What should one piece of evidence be worth, and how should several combine?

Today (`Evidence.lean`, `Belief.lean`):

- Each item has one of 13 kinds. Each kind has one fixed reliability.
- Items on one statement combine by cumulative fusion. Repeated PMIDs are dropped first.
- Logical steps take the weaker premise. Mechanistic chains multiply.

ROADMAP M6 names four changes: ECO codes for the enum, per-claim base rates, averaging fusion for
dependent sources, and extraction reliability separate from study strength. Its exit test: "Ozempic
verdicts unchanged in sign; the pseudo-count of every evidence kind documented."

### 1.1 What the core does, in theorems

All in `Weights.lean`, proved for every `EvidenceModel`:

| theorem | says |
|---|---|
| `fuse_ofCounts` | cumulative fusion adds pseudo-counts |
| `statement_opinion_eq` | a statement's opinion is b = S/(S + R + 2), d = R/(S + R + 2) |
| `statement_established_iff` | established exactly when S ≥ 4R + 8 |
| `statement_refuted_iff`, `not_refuted_of_lt_eight` | refuted exactly when R ≥ 4S + 8; so R < 8 never refutes |

What follows, all seen in the cases:

- Kind and count are all the core sees. Ten small items and one big item of the same total are the
  same evidence. Sample size, lab, cohort, age, effect size and retraction are invisible.
- One textbook sentence or one curated row (n = 8) is exactly "established" (T04; theorem
  `textbook_alone_established`).
- Two failed in-vitro replications (R = 4) can never refute anything, whatever supports the claim.
- The base rate exists (`Opinion.prob`) but no verdict reads it.

### 1.2 Pseudo-counts (M6 exit test, part 2)

Prior weight W = 2. Pinned by `#guard pseudoCounts`; table in `pseudocounts.tsv`.

| kind | r | n | reads as |
|---|---|---:|---|
| metaAnalysis | 9/10 | 18 | 9 observational studies |
| ontologyAxiom | 9/10 | 18 | |
| rct | 17/20 | 11.33 | 5.7 observational studies |
| curatedDb | 4/5 | 8 | established alone |
| textbook | 4/5 | 8 | established alone |
| mechanistic | 7/10 | 4.67 | |
| review | 3/5 | 3 | 1.5 observational studies |
| observational | 1/2 | 2 | four establish a claim |
| inVitro | 1/2 | 2 | |
| textMined | 3/10 | 0.86 | 21 make one meta-analysis |
| crossSpecies | 3/10 | 0.86 | |
| hypothesis | 0 | 0 | no weight |
| definitional | 999/1000 | 1998 | near-certain |

## 2. The options

"Core?" says whether the option changes the formal system, and what it would add. All prototypes
live in the namespace `BioLean.Proto.Weights` inside `Weights.lean`, not in the core. Every core
change listed is in `Evidence.lean` unless the row says otherwise.

| | idea | core? (what it adds) | needs |
|---|---|---|---|
| A | publish the pseudo-counts; keep the enum | no | nothing (done, 1.2) |
| B1 | the importer maps a GO evidence code or a meta's pooled design onto an existing kind (IBA to crossSpecies, IEA to textMined, meta of observational studies to observational) | no | ECO code per row; design per meta |
| B2 | ECO and study-design terms on each item | yes: two fields on `Evidence`, or a type replacing `EvidenceKind` | ECO import; a weight per ECO class |
| C | a GRADE-like certainty caps a statement (C1) or only its clinical items on effect claims (C2) | yes: a certainty on `Statement`, read by `Statement.opinion` (`discount` exists) | a rating per statement |
| D | items sharing a source (lab, cohort, trial, pipeline, book) are averaged, not added | D-core yes: a source key on `Evidence` and averaging fusion, a new operator in `Belief.lean`. D-import no: one item per group | a source key |
| E | a meta-analysis replaces the primaries it pools | E1 no (import rule; rewrites the past). E2 yes: a pools list on `Evidence` | inclusion lists |
| F | reader precision discounts an item separately from study strength | yes: a precision on `Evidence`, read by `Evidence.opinion` | precision per reader |
| G | a ceiling per kind for errors that do not average out (INDRA's systematic error) | yes: a ceiling in `EvidenceModel`; `Statement.opinion` caps each kind | a ceiling per kind |
| H | retracted papers weigh nothing | H1 no (import rule; rewrites the past). H2 yes: an end year on `Evidence`, honoured by `asOf` | Europe PMC flag; dates for H2 |
| I | set r per kind from measured replication rates | no: a new `EvidenceModel` instance | measured rates |
| J | per-claim base rate; the verdict reads b + a·u | yes: a base rate on `Statement` or `Claim`; the verdict in `Derivation.lean` reads it | a source of base rates |
| K | pseudo-count grows with sample size (clamped to 1/8 to 8 times) | yes: participants on `Evidence`, read by `Evidence.opinion` | participants per item |
| M | refuting items get their own reliability (nulls replicate more often) | yes: a second reliability in `EvidenceModel` | rates by polarity |
| N1 | a curated "superseded by" table | N1-import no, but it breaks the M2 theorem `contested_1965`. N1-dated yes: the same end year as H2 | supersession links |
| N2 | ageing: pseudo-count times 0.933 per year (half-life 10 years) | yes: a half-life in `EvidenceModel`, read by `opinionAt` | a half-life |
| P | evidence about a weight: "the mouse is a good model for this claim" (A04) | yes: a new Claim constructor in `Claim.lean` | not prototyped |

Notes on the ideas:

- **B.** ECO has only "clinical study evidence" (ECO:0000180, with manual and automatic children)
  for clinical work. Trial, cohort and meta-analysis designs live in OBCS, OBI and NCIT
  (OBCS:0000107 randomized controlled trial design, OBCS:0000106 cohort study design, OBI:0002624
  case-control, OBI:0002674 case series, OBI:0001958 systematic review, NCIT:C17886 meta-analysis).
  So "ECO replaces the enum" needs two vocabularies.
- **D.** With W = 2, averaging fusion is the mean of pseudo-counts. The prototype averages inside
  each group. GO rows are keyed by their GO_REF, the pipeline that made them.
- **G.** INDRA's belief for n items of one source is 1 − (e_syst + e_rand^n (1 − e_syst)) (Bachman
  2023, Methods). With e_syst = 0 that is noisy-OR, not cumulative fusion: two items of 1/2 give 3/4
  under noisy-OR and 2/3 under fusion (pinned). So design.md's "INDRA's belief score is a special
  case" does not hold, with or without the plateau. INDRA's numbers can still be reused as priors.
- **I.** "Observational" in the enum covers cohort studies of a treatment and direct observation
  (chromosome counts, brain tissue). Ioannidis's 1 in 6 is about six highly cited non-randomised
  studies of treatments. I applies it to both.
- **N1.** Two entries: Painter's 48 superseded by the 1956 counts of 46, and the ILLUSTRATIVE 1965
  intermediate reports superseded by Racker and Stoeckenius 1974. No live disputes. As an import
  rule it removes the 1965 reports in 1965 too, so `contested_1965` (the M2 exit theorem) fails.
  Kept dated, it needs the year asked, which `Statement.asOf` does not pass on. SEPIO has
  "contradicts" (SEPIO:0000101) but no "supersedes" on OLS4; schema.org has `supersededBy`.

What each prototype did, OBSERVED (cases and numbers in section 4):

| | right | wrong |
|---|---|---|
| A | nothing changes | nothing changes |
| B1 | C04 stateable (PASS); W02 to SILENT | D05 lost (Taylor 2014 becomes observational); C01 still established (0.955) |
| C1 | W01, D02, A02 PASS | flips the Ozempic nausea sign; loses K04, W09, D05, T01, O02 |
| C2 | W01, D02, A02 PASS | loses W09 and D05: no RCT, so "low", though smoking was settled |
| D curated | D02 PASS | loses R05, O02; W03 to FAIL; C02 still established (0.909: 50 rows in 5 pipelines) |
| D auto | W01, W02, D02 PASS | loses K02 (two S2 papers, PMID:38935778 and 40367985, share a last author), K05 (Mitchell 1961 joins Mitchell & Moyle 1967), R05, O02 |
| E | numbers move the right way (D04 0.977 to 0.900; W01 0.923 to 0.916) | no mark changes; as an import rule it drops Madsen 2002 from D06 in 2002 too |
| F | L01 stateable | the 3/5 precision is a placeholder; no verdict changes |
| G (INDRA values) | almost nothing | loses C03 |
| G (guessed) | W06, W07, D02 PASS | the ceilings have no source; loses W09 (observational capped at 0.6); T03 to FAIL |
| H | R03 stateable; FAIL 22 to 19; no fair case lost | R01, R02, D06 only to SILENT (R = 4 < 8); H1 rewrites the past (Wakefield gone in 2002, GFAJ-1 empty in 2011) |
| I (Ioannidis) | W06, D02, A02, CAL02 PASS; FAIL 22 to 17 | loses W09 (b 0.666): ten observational reports give S = 4; T03 to FAIL; O01 to SILENT |
| J | R04 PASS; B01 stateable | T02, T03 to FAIL; 24 FAIL, the most of any scheme |
| K | W03, W04, D06 PASS; no fair case lost | W02 to SILENT; D02 established at 0.954 (big cohorts are still one cohort) |
| M | R02, CAL01 PASS | loses K02, K05 (both use inVitro near 0.8) and R05; O03 to FAIL |
| N1 | O03 PASS; no fair case lost; K05 still PASS (C~I d = 0.9) | O01 only to SILENT (two observational items give 0.667); at import it breaks `contested_1965` |
| N2 | FAIL 22 to 13 | facts decay: loses K02, K05, W08 (beta-carotene RCTs from 1994 age to d = 0.569); breaks the Ozempic 0.8 theorem and chemiosmosis 1974 |

## 3. The stress set

51 cases, 47 real and 4 synthetic (W06, W07, D09, D10). Full table with inputs, CURIEs and sources:
`data/stress/10a/cases.tsv`. Every case is a Lean definition `case_<id>` and has a pin
`#guard pin core case_<id> "<observed>" <mark>`. "Judgement" marks a correct conclusion that is my
reading of the sources, not a quote.

| id | probes | correct | today (OBSERVED) | mark |
|---|---|---|---|---|
| K01 | Ozempic main claim | established | b 0.968 | PASS |
| K02 | Ozempic mechanistic route, theorem at 0.8 | established | b 0.805 | PASS |
| K03 | sitagliptin: chain against trials | refuted (judgement) | contested | FAIL |
| K04 | nausea mediates: a real dispute | contested | contested | PASS |
| K05 | chemiosmosis 1974, rivalry | established / refuted | 0.806 / d 0.818 | PASS |
| W01 | HRT and CHD 1997: cohorts plus meta of cohorts | not established | b 0.923 | FAIL |
| W02 | HRT 2003: observational against RCTs | refuted | contested | FAIL |
| W03 | vitamin E 2008: four null RCTs | refuted | d 0.723 | SILENT |
| W04 | IV magnesium 2002: mega-trial against meta | refuted | contested | FAIL |
| W05 | NXY-059: SAINT I against SAINT II | refuted | contested | FAIL |
| W06 | 27 observational against 1 RCT (synthetic) | not established | b 0.801 | FAIL |
| W07 | 10 and 1,000 text-mined items (synthetic) | not established (judgement at 1,000) | b 0.810, 0.997 | FAIL |
| W08 | beta-carotene: two RCTs refute | refuted | d 0.918 | PASS |
| W09 | smoking and lung cancer 1958: ten observational reports | established (judgement) | b 0.909 | PASS |
| D01 | ten papers from one lab, nine retracted | refuted (judgement) | b 0.870 | FAIL |
| D02 | four reports of one cohort | not established | b 0.800 | FAIL |
| D03 | meta plus its own primary (harmless) | established | b 0.972 | PASS |
| D04 | magnesium 1991: meta plus six of its trials | not established | b 0.977 | FAIL |
| D05 | MMR and autism, with meta | refuted | d 0.857 | PASS |
| D06 | MMR and autism, 2002 | refuted | contested | FAIL |
| D07 | three reviews restating primaries | established | b 0.866 | PASS |
| D08 | one book, three sentences | established (verdict only; the missing warning is E8) | b 0.923 | PASS |
| D09 | same PMID, both polarities (synthetic) | order must not matter | order decides | FAIL |
| D10 | same PMID twice (synthetic) | counted once | counted once | PASS |
| R01 | STAP cells: retracted, two failed replications | refuted | contested | FAIL |
| R02 | arsenic DNA in GFAJ-1 | refuted | contested | FAIL |
| R03 | Hwang SCNT after retraction | vacuous | no retraction status | INEXPRESSIBLE |
| R04 | SCNT in three independent labs | established | b 0.750 | SILENT |
| R05 | resveratrol and SIRT1 | contested (judgement) | contested | PASS |
| CAL01 | inVitro weight against Errington 2021, by polarity | within x2 | support yes, refute no | FAIL |
| CAL02 | rct and observational against Ioannidis 2005 | within x2 | rct yes, observational no | FAIL |
| CAL03 | text-mined belief against Reach precision | at most measured + 0.05 | all three bands | PASS |
| A01 | NMN mouse to human | not established | b 0.210 | PASS |
| A02 | NMN: one 10-week RCT | not established | b 0.850 | FAIL |
| A03 | NXY-059: rat meta transported plus human trials | refuted | contested | FAIL |
| A04 | evidence about a weight (mouse models) | statable | no statement targets a weight | INEXPRESSIBLE |
| T01 | neurogenesis 2013: book and papers agree | established | b 0.857 | PASS |
| T02 | neurogenesis March 2018 | contested (judgement) | b 0.750 | SILENT |
| T03 | neurogenesis 2022 | contested (judgement) | b 0.760 | SILENT |
| T04 | "All cells have DNA" (claim of m45429-9), one textbook item | not established | b 0.800 | FAIL |
| C01 | Giardia mitochondrion from 50 GO rows | not established | b 0.995 | FAIL |
| C02 | the same against Tovar 2003 | refuted | b 0.990 | FAIL |
| C03 | Paramecium transcription, inferred rows only | established | 0.800 and 0.969 | PASS |
| C04 | IEA against EXP | different weights | code lives in a note | INEXPRESSIBLE |
| O01 | 46 against 48 chromosomes, 1960 | 46 established | both contested | FAIL |
| O02 | 46 against 48, 2013 | 46 established | b 0.875 | PASS |
| O03 | chemiosmosis as one claim, 1974 | established | b 0.714 | SILENT |
| B01 | per-claim base rate | statable | no base rate on Statement | INEXPRESSIBLE |
| B02 | GFAJ-1 in 2011, paper alone | not established | b 0.500 | PASS |
| L01 | an RCT read by a text-miner | two factors | one kind per item | INEXPRESSIBLE |
| L02 | drop a mis-read item from S8 | verdict unchanged | unchanged | PASS |

## 4. Results observed

All numbers below come from running `lake env lean BioLean/Stress/Weights.lean` on 2026-10-31,
and are pinned. Tables: `scheme_summary.tsv`, `schemes.tsv`, `sensitivity.tsv`, `margins.tsv`.

### 4.1 Tallies

| scheme | core? | PASS | FAIL | SILENT | INEXPR. | fair cases lost | Ozempic sign flips |
|---|---|---:|---:|---:|---:|---|---:|
| core | | 19 | 22 | 5 | 5 | | 0 |
| H (H1: drop retracted at import) | no | 20 | 19 | 8 | 4 | none | 0 |
| K (size) | yes | 22 | 19 | 5 | 5 | none | 0 |
| I (Ioannidis table) | no | 22 | 17 | 7 | 5 | W09 | 0 |
| H1 + I | no | 23 | 15 | 9 | 4 | W09 | 0 |
| H1 + I + N1, N1 dated | yes (end year) | 24 | 15 | 8 | 4 | W09 | 0 |
| H1 + I + N1, N1 at import | no; breaks `contested_1965` | 24 | 15 | 8 | 4 | W09 | 0 |
| H + E + D + B1 + I (D as one item per group) | no | 24 | 12 | 12 | 3 | W09, D05, R05, O02 | 0 |
| the same + N1 at import | no; breaks `contested_1965` | 26 | 12 | 10 | 3 | W09, D05, R05 | 0 |
| H + E + D + B1 + G + K + F | yes | 25 | 15 | 9 | 2 | R05, C03, O02 | 0 |
| every option except C, J, M, N2 | yes | 29 | 10 | 10 | 2 | W09, D05, R05, C03 | 0 |
| C1 | yes | 17 | 17 | 12 | 5 | K04, W09, D05, T01, O02 | 1 (nausea) |
| N2 | yes | 21 | 13 | 12 | 5 | K02, K05, W08 | 0 |
| I with Errington's table | no | 16 | 21 | 9 | 5 | K02, K05, L02 | 0 |
| reviews weigh 0 | no | 17 | 22 | 7 | 5 | K02, D07 | 1 (hypothalamus to 0) |

Single options are in section 2. Every scheme is in `scheme_summary.tsv`.

The CAL cases test I and M against the data they were fitted to. Without CAL01 to CAL03 (48 cases,
pinned as `noCal`): core 18/20/5/5, H 19/17/8/4, I 20/16/7/5, H1 + I 21/14/9/4, H1 + I + N1
22/14/8/4. The order of the schemes does not change.

### 4.2 What the cases show

- **Volume beats kind.** W06: 27 observational items (54) outvote one RCT (11.3). W07: text-mined
  items have no plateau (1,000 give 0.997). C01: 50 inferred GO rows give 0.995 for a false claim.
- **Observational evidence is right and wrong, and the core cannot tell which.** HRT (W01, D02) had
  cohorts that were wrong; smoking (W09) had cohorts and case-control studies that were right. What
  separates them is effect size and confounding. No option here sees either. Cutting all
  observational weight (I, G guessed, C) fixes the one-cohort HRT case (D02) and breaks smoking.
- **Dependence is invisible.** One lab (D01), one cohort (D02), one book (D08) and a meta with its
  own trials (D04) all count as independent. `sharedAxioms` checks statement ids, so D08 gets no
  warning.
- **Refutation is hard.** Refuted needs R ≥ 4S + 8, the mirror of established. Retracted papers
  keep voting (D01, R01, R02). Once they are dropped (H), two failed replications (R = 4) still
  cannot refute: the bar is four in-vitro items, and few claims get four failed replications.
- **Size is invisible.** ISIS-4 (58,050 patients) and LIMIT-2 (2,316) weigh the same (W04).
  Madsen (537,303 children) weighs as much as Wakefield (12) in 2002 (D06).
- **Old evidence never leaves.** O01, O03: cumulative fusion keeps 1923 and 1965 voting.
- **Fair cases.** 19 PASS: the core gets real disputes right (K04, R05), refutes by RCTs (W08),
  establishes smoking from observational studies (W09), and does not move mouse data to humans (A01).

### 4.3 Sensitivity (each pseudo-count times 2 and times 1/2)

26 runs in Lean, on the examples' own definitions (`sensExample`, `sensStress`, pinned).

- Ozempic sign flips: **0** in all 26 runs. The ROADMAP exit test passes.
- Example checks flipped: 9, all at times 1/2 and all at the 0.8 line: mechanistic (2), review (2),
  inVitro (5). The fragile ones are the Ozempic mechanistic route (0.805) and chemiosmosis in 1974
  (the real-papers rivalry sits at exactly 0.800).
- Margins (`margins`, a grid from 1/16 to 16): the Ozempic 0.8 theorem breaks at review times 9/10,
  mechanistic times 4/5 and inVitro times 4/5. Chemiosmosis 1974 breaks at inVitro times 9/10. The
  first Ozempic sign flips are at mechanistic times 4 (sitagliptin turns positive: b 0.493 against
  d 0.488) and rct times 1/16.
- Nine kinds change no example check at any grid factor: metaAnalysis, curatedDb, textbook,
  ontologyAxiom, observational, textMined, hypothesis, crossSpecies, definitional.
- Stress-set marks move in 14 of 26 runs. The largest moves (four cases each) are observational
  times 1/2 (W06 and D02 to PASS, D06 and O01 to SILENT) and inVitro times 1/2 (K02 and K05 lost,
  R01 and R02 to SILENT).

### 4.4 The M6 exit test, three wordings

| wording | test | today |
|---|---|---|
| ROADMAP | no Ozempic sign flip at x2 or x1/2 of any kind; every pseudo-count documented | passes (pinned) |
| A | fewer FAILs on this set than the core, and no Ozempic sign flip | 23 of 32 schemes pass |
| B | as A, and no fair case lost | H, K, N1 dated, N1 at import |

Wording B is the one that can fail. Of its four passers, only H1 needs no core change and breaks
no example theorem. N1 at import passes B but breaks `contested_1965`, because B looks only at
Ozempic signs. A stricter B would also keep every example theorem, except named fixes (today only
`one_claim_never_established` under N1, which O03 shows is right).

### 4.5 Corrections to the research stage (found by running)

- With all 50 Giardia rows keyed by pipeline, D alone no longer moves C02 (0.909): the 12
  automatic rows come from 4 pipelines.
- The "one experimental mitosome row" on QuickGO is negative: NOT located_in, from an aurora kinase
  paper (Davids 2008, PMID:17964578). GO holds no positive experimental mitosome row for Giardia.
- N2 also loses W08: RCTs age out of a settled refutation. It puts chemiosmosis 1974 at 0.779 alone
  and 0.757 under the rivalry.
- A 10 percent cut to inVitro breaks chemiosmosis 1974, not the Ozempic theorem, which needs 20.

### 4.6 Review corrections (2026-10-31)

An adversarial review re-ran every file and changed these. All are pinned.

| what | before | after |
|---|---|---|
| a fair case resting on observational evidence alone | none in the set | W09 added (smoking, ten reports, 1958). I and every scheme with I lose it |
| outside-core recommendation | H1 + I + N1 (FAIL 15, nothing lost) | H1 only (FAIL 19, nothing lost) |
| N1 "core?" | no | as run, it used the year asked: a core change. At import, no core change, but `contested_1965` fails. Both run |
| INDRA (note G) | "cumulative fusion with zero systematic error" | noisy-OR; design.md's claim is false |
| automatic source key | matched names case-sensitively ("DOLL R" is not "Doll R") | case-folded; now also joins Mitchell 1961 with Mitchell & Moyle 1967, so D auto loses K05 |
| judgement marks | K03, R05, T02, T03 | also D01, W07 (at 1,000), W09 |
| CAL cases | counted with no caveat | tallies without them pinned (4.1) |
| T04 | a weight FAIL | a universals FAIL (program 01): the passes under N2 and textbook x1/2 come from weakening every textbook sentence, true ones too (pinned on m45455-17) |
| counts | 50 cases, 29 prototypes, 100 pins | 51 cases, 32 prototypes, 130 pins |

## 5. Experiments for later

Each has its exit test first, then a cost in agent tasks.

| # | exit test | experiment | cost |
|---|---|---|---:|
| E1 | on at least 30 held-out cases drawn blind (retraction lists, medical reversals, exposures accepted on observational evidence), H1 has fewer FAIL than the core, loses no PASS, flips no Ozempic sign. The same run reports what I does | build the held-out set, run it | 3 |
| E2 | Dan agrees to wording B (with the example-theorem clause) as the M6 exit test | none | 0 |
| E3 | on real GO rows for the program 01 taxa, Giardia mitochondrion is not established and the transcription universal is unchanged | B1 + D on QuickGO rows with ECO and GO_REF | 2 |
| E4 | an automatic source key agrees with a curator on at least 80 of 100 statements | key from authors, cohorts, trial registry ids | 2 |
| E5 | GFAJ-1 asked in 2011 keeps its paper, asked in 2026 it does not; `contested_1965` holds; O03 passes | one end year on `Evidence` for H2 and N1, honoured by `asOf`, in a prototype copy | 1 |
| E6 | R01 and R02 refuted; B02 and R05 unchanged | a refutation rule or a replication kind | 1 |
| E7 | W06 and W01 PASS, D05 still refuted and W09 still established, under one rule | compare ceiling (G) against size (K) | 1 |
| E8 | `chrom46x3` warns "one source" | source tracking across `both`, as a lint | 1 |
| E9 | two agents give GRADE ratings on 20 clinical statements with Cohen's kappa at least 0.6 | GRADE rating protocol, with GRADE's upgrades for large effects | 2 |
| E10 | a table beats the standard on 100 claims with known fate and on E1 | a labelled set; fit r per kind | 5 |
| E11 | two agents agree on at least 18 of 20 supersession links, and the stress set loses no PASS | N1 at scale, from histories such as Gartler 2006 | 2 |
| E12 | I applied only to observational studies of treatments keeps W09 and still passes W06, D02 | B1 with OBCS design terms: split observational into studies of treatments and direct observation | 1 |

## 6. What would change the decision

- **E1 fails for H1** (dropping retracted papers loses fair cases on new data): keep H as a lint
  that warns, not a rule that drops.
- **E12 passes**: I comes back, restricted to studies of treatments. That needs design terms per
  item (B1 at import, or B2 in the core).
- **Dan wants sample size in the strength**: K is the only option that sees it, and it is a core
  change (a size field). It ties with H1 on this set.
- **E6 shows the bar for refutation should differ from the bar for support**: change the verdict
  rule there; M (weights by polarity) is then not needed.
- **History matters** (asking the system what was known in 2011): H2 and dated N1 need one end year
  on `Evidence`. Without it, N1 breaks the M2 theorem.
- **E10 gives a measured table**: I replaces the hand table, and B2 becomes a question of naming,
  not of numbers.

## 7. Limits

- Kind assignments are judgements. Replications are inVitro, cohorts and chromosome counts are
  observational, the Anversa papers are mechanistic. R01, R02, R04, D01 and O01 depend on them.
- Seven correct conclusions are my judgement from the sources: K03, R05, T02, T03, D01, W07 (at
  1,000 mentions) and W09. W09 holds the ten reports I could check; the 1958 record held more.
- I built the cases and the schemes, so the tallies may flatter them (hence E1). One added case
  (W09) changed the best outside-core scheme. The set leans clinical (17 cases against 11 textbook,
  curated or chromosome cases).
- Calibration samples are small: 6 non-randomised studies in Ioannidis 2005; 15 null effects in
  Errington 2021, whose 39 of 97 "succeeded according to three or more of these five methods".
- W07: INDRA's default Reach priors give 0.665 at one mention and above 0.8 at ten (pinned).
  Bachman measured 0.48 and 0.75. W07 follows the measurement.
- D-import is modelled as the mean pseudo-count of a group. When a group mixes kinds, no single
  item of an existing kind has that weight, so the import version is an approximation.
- Prototypes replace only `Statement.opinion`. Transport items keep the core table.
- Two chemiosmosis items and the N1 entry for them are ILLUSTRATIVE, as in the example.
- T01 to T03 put a textbook sentence with no species or site on a human hippocampal claim.
- W01, W02: the claim is estrogen; HERS and WHI tested estrogen plus progestin. HP:0001677
  (coronary artery atherosclerosis) stands for coronary heart disease events.
- Thresholds (0.8 and 0.25) are unchanged. Program 07 studies them.

## 8. References (checked)

Checked on Europe PMC (PMIDs) or Crossref (DOIs) on 2026-10-31: title, first author and year match.
All 182 PMIDs in the Lean file, this doc, `case_spec.json` and the example statements the cases use
are in `data/stress/10a/references_checked.tsv` (15 flagged Retracted Publication, as expected).
All 60 CURIEs are in `curies_checked.tsv` (OLS4; none obsolete). Every quoted phrase in the case
table and all 29 participant counts in the size table (option K) are found in the cited abstract,
title or textbook sentence (`quotes_checked.tsv`; HOPE as 2,545 women plus 6,996 men; Hammond &
Horn from their titles). Author and year pairs: `review_refs.tsv`.

- Balshem H et al. 2011. GRADE guidelines: 3. Rating the quality of evidence. PMID:21208779
- Bachman JA et al. 2023. Automated assembly of molecular mechanisms at scale from text mining and
  curated databases. PMID:36938926 (Table 2 and the belief formula read in the full text)
- Errington TM et al. 2021. Investigating the replicability of preclinical cancer biology. PMID:34874005
- Ioannidis JP 2005. Contradicted and initially stronger effects in highly cited clinical research. PMID:16014596
- Ioannidis JP 2005. Why most published research findings are false. PMID:16060722
- Skunca N et al. 2012. Quality of computationally inferred gene ontology annotations. PMID:22693439
- Tavtigian SV et al. 2018. Modeling the ACMG/AMP variant classification guidelines as a Bayesian
  classification framework. PMID:29300386
- Tavtigian SV et al. 2020. Fitting a naturally scaled point system to the ACMG/AMP variant
  classification guidelines. PMID:32720330
- Jøsang A 2016. Subjective Logic. doi:10.1007/978-3-319-42337-1 (metadata only)
- Jøsang A, Diaz J, Rifqi M 2010. Cumulative and averaging fusion of beliefs. doi:10.1016/j.inffus.2009.05.005 (metadata only)
- Doll R 1998. Uncovering the effects of smoking: historical perspective. PMID:9654637
- Gartler SM 2006. The chromosome number in humans: a brief history. PMID:16847465
- Davids BJ et al. 2008. Giardia lamblia aurora kinase: a regulator of mitosis in a binucleate parasite. PMID:17964578
- Tovar J et al. 2003. Mitochondrial remnant organelles of Giardia function in iron-sulphur protein maturation. PMID:14614504
- Chia CW, Egan JM 2008. Incretin-based therapies in type 2 diabetes mellitus. PMID:18628530
- Lau J et al. 2015. Discovery of the once-weekly GLP-1 analogue semaglutide. PMID:26308095
- Wilding JPH et al. 2021. Once-weekly semaglutide in adults with overweight or obesity. PMID:33567185
- Clinical cases: Stampfer 1985 PMID:4047106; Stampfer 1991 PMID:1870648; Grodstein 1996
  PMID:8672166; Grodstein 2000 PMID:11119394; Stampfer & Colditz 1991 PMID:1826173; Hulley 1998
  PMID:9718051; Rossouw 2002 PMID:12117397; Manson 2003 PMID:12904517; Stampfer 1993 PMID:8479463;
  Rimm 1993 PMID:8479464; Stephens 1996 PMID:8622332; HOPE 2000 PMID:10639540; Lonn 2005
  PMID:15769967; Lee 2005 PMID:15998891; Sesso 2008 PMID:18997197; Teo 1991 PMID:1838289; Woods 1992
  PMID:1351547; ISIS-4 1995 PMID:7661937; MAGIC 2002 PMID:12401244; Egger & Smith 1995 PMID:7549720;
  Lees 2006 PMID:16467546; Shuaib 2007 PMID:17687131; Macleod 2008 PMID:18635842; Peto 1981
  PMID:7010181; ATBC 1994 PMID:8127329; Omenn 1996 PMID:8602180; Wakefield 1998 PMID:9500320;
  retraction PMID:20137807; Taylor 1999 PMID:10376617; Madsen 2002 PMID:12421889; Taylor 2014
  PMID:24814559; Hviid 2019 PMID:30831578; Yoshino 2021 PMID:33888596; Das 2018 PMID:29570999
- Smoking (W09): Wynder 1950 PMID:15415260; Doll 1950 PMID:14772469; Levin 1950 PMID:15415261;
  Mills 1950 PMID:14772728; Schrek 1950 PMID:15398042; Doll 1952 PMID:12997741; Hammond 1954
  PMID:13174399; Doll 1954 PMID:13160495; Doll 1956 PMID:13364389; Hammond 1958 PMID:12308037
- Laboratory cases: Beltrami 2003 PMID:14505575; van Berlo 2014 PMID:24805242; Obokata 2014
  PMID:24476887, 24476891, retraction PMID:24990753; De Los Angeles 2015 PMID:26399835; Konno 2015
  PMID:26399834; Wolfe-Simon 2011 PMID:21127214; Redfield 2011 PMID:21622706; Reaves 2012
  PMID:22773140; Erb 2012 PMID:22773139; Hwang 2004 PMID:14963337; Hwang 2005 PMID:15905366;
  Tachibana 2013 PMID:23683578; Yamada 2014 PMID:24776804; Chung 2014 PMID:24746675; Howitz 2003
  PMID:12939617; Kaeberlein 2005 PMID:15684413; Borra 2005 PMID:15749705; Pacholec 2010
  PMID:20061378; Hubbard 2013 PMID:23471411; Seok 2013 PMID:23401516; Takao 2015 PMID:25092317;
  Gao 2022 PMID:36188627; O'Neil 2018 PMID:30122305
- Neurogenesis: Eriksson 1998 PMID:9809557; Spalding 2013 PMID:23746839; Sorrells 2018
  PMID:29513649; Boldrini 2018 PMID:29625071; Kempermann 2018 PMID:29681514; Moreno-Jimenez 2019
  PMID:30911133; Franjic 2022 PMID:34798047
- Chromosomes: Ford & Hamerton 1956 PMID:13378517; Tjio & Levan 1956 doi:10.1111/j.1601-5223.1956.tb03010.x;
  Painter 1923 doi:10.1002/jez.1400370303
- Chemiosmosis: Slater 1953 PMID:13111237; Mitchell 1961 PMID:13771349; Jagendorf & Uribe 1966
  PMID:5220864; Mitchell & Moyle 1967 PMID:16742541; Hinkle & Horstman 1971 PMID:4330063; Racker 1974
  PMID:4272126 (Racker and Stoeckenius)
- Vocabularies (OLS4): ECO:0000180, ECO:0000256, ECO:0000269, ECO:0000318, ECO:0000364,
  ECO:0000501, ECO:0007322; OBCS:0000106, OBCS:0000107; OBI:0001958, OBI:0002624, OBI:0002674;
  NCIT:C17886; NCIT:C829 (tobacco smoke, typed as chemical); SEPIO:0000101 (a property,
  "contradicts"); GO:0032047 (mitosome; its OLS4 ancestors do not include mitochondrion)
- Data: QuickGO, 2026-10-30 and 2026-10-31 (re-queried in review), Giardia lamblia ATCC 50803
  (NCBITaxon:184922) and GO:0005739 exact: 50 rows (38 IBA, 12 IEA), 0 experimental; mitosome: one
  row, IDA, NOT located_in. INDRA `default_belief_probs.json`, GitHub master, fetched 2026-10-31.

## 9. UNVERIFIED

- The averaging-fusion formula b = (b1 u2 + b2 u1)/(u1 + u2). From memory of Jøsang; the book and
  the 2010 paper were checked for metadata only. "Averaging is the mean of pseudo-counts at W = 2"
  follows from that formula, checked by hand.
- Jøsang's ageing (forgetting) factor behind N2. From memory of the Beta reputation system (Jøsang
  and Ismail 2002), not found on Crossref. The half-life of 10 years is my choice.
- ACMG/AMP numbers (odds per strength level, points 1/2/4/8, prior 0.1). The abstracts confirm only
  four exponentially scaled levels and additive points.
- Pooled-study lists come from Europe PMC reference lists, not inclusion tables: Teo 1991 (six
  trials), Taylor 2014 (Madsen 2002), Stampfer & Colditz 1991 (NHS 1985). Gao 2022 is the exception.
- Painter's count of 48 and the 1956 count of 46 are not in the checked abstracts; 46 is confirmed
  by the textbook sentences m45455-17, -46 and -60.
- Lab, cohort and trial membership for the curated source key: from author lists and titles.
- That the five 1950 case-control studies in W09 are the five Doll 1998 counts: matched by year and
  topic, not named in his abstract.
- INDRA belief priors come from the GitHub master branch, not a tagged release.
