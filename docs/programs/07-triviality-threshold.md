# Program 07: the IC triviality threshold and a human-rated set

Written 2026-10-30, Dan away; reviewed the same day (what the review changed is at the end). Decision 7 is open ("more
research needed"). This program lays out the options, builds a 100-fact rating sheet, and analyses it with three blind
LLM raters. **The LLM ratings are a stand-in until Dan rates the sheet.** Nothing here touches the Lean core. Model:
[01-universals-and-descent.md](01-universals-and-descent.md).

## Summary

- **What I did.** Three blind LLM raters rated a 100-fact sheet twice. Round 1 used a rubric whose examples primed some
  rows; round 2 used a fixed rubric. `scripts/stress/ic_analysis.py` measures agreement, precision and recall at every
  cut, false facts kept, and 12 other scores. 90 stress cases (58 on the sheet, 32 off it) are pinned. **No human has
  rated anything yet.**
- **2.5 is close, but just too high.** Tried at every IC value on the sheet, the rules put the cut between plasma
  membrane (IC 2.28) and endomembrane system (2.43). 2.4 is a round number in that gap. It removes as many trivial rows
  as 2.5 (29 of 52), loses nothing worth showing (2.5 loses 2 of 6), and keeps 28 more closure facts. Demoting any one
  worth-showing row does not move it; 91 percent of bootstrap resamples agree.
- **The draft's "the ratings cannot place the cut" was a grid artefact.** It tried T only in steps of 0.25. No step
  falls between 2.28 and 2.43, so it could only answer 2.25 or 2.5, and one row flipped it.
- **The cut removes trivia but finds little.** Closure-wide, the trivial share of kept facts falls from 55 to 38
  percent. Precision for "interesting" moves only from 0.14 to 0.16 (0.19 at 2.4). Structural flags first, then the
  cut, keeps 4 trivial rows instead of 23.
- **IC is blind to truth.** The cut keeps 7 of the 12 rows judged false. All 14 rows rated interesting are judged
  false or unsure. Part of this may be the rubric: all three of its level-3 examples are false or unsure.
- **What matters now.** Dan rates the sheet: 2 columns, about 2 hours, one command (below). No option needs a new
  constructor, rule, operator or type. J (discount belief by IC) could reuse `Opinion.discount`; I advise against it.

## Dan: how to rate (3 steps)

From the repo root (`~/Build/BioLean`):

1. `cp data/stress/07/rating_sheet_blind.tsv data/stress/07/rating_dan.tsv`
2. Open `rating_dan.tsv` in LibreOffice (tab-separated), with `data/stress/07/rubric.md` beside it. Fill two columns:
   `interesting` (0 to 3, rated as if the fact were true) and `true` (yes, no or unsure). `note` is optional. About a
   minute a row. Save in the same format. Sittings are fine: empty rows are skipped.
3. Run `python3 scripts/stress/ic_analysis.py`. Read section 0 of `data/stress/07/analysis_report.txt`.

Section 0 shows your agreement with the LLMs, your cut (read the "exact cut points" line) and your AUCs. `y`, `n`,
`?`, `2.0` and a `.csv` save also work.
Optional, 10 minutes: the 9 old facts in `rating_sheet_old9_blind.tsv`, scored by
`python3 scripts/stress/ic_score_ratings.py data/stress/07/rating_dan.tsv --old9 <your rated old9 file>`.

## Words used here

| word | meaning here |
|---|---|
| core | the Lean formal system: `Claim` constructors, `Derivation` rules, opinion operators, types |
| IC | information content of a term: -log(subtree size / ontology size), over is_a plus part_of |
| score | the lower IC of a fact's two ends; the cut uses it |
| path_min | the lowest IC of any entity in the derivation |
| T, cut | keep a fact if its score is T or more; today 2.5 (`IC_MIN` in `scripts/search/closure.py`) |
| grid | T tried at 0, 0.25, 0.5, and so on |
| exact cut points | T tried at every IC value on the sheet. "(2.282, 2.433]" means any T above 2.282 and up to 2.433: on the sheet, all give the same split |
| unjudged | an end has no IC, so no verdict |
| trivial | rated 0 (pooled: mean under 0.5) |
| interesting | rated 2 or 3 (pooled: mean 2 or more) |
| judged false | most raters say `no` |
| worth showing | interesting and not judged false |
| precision, recall | share of kept facts that are interesting; share of interesting facts kept |
| AUC | chance a score ranks a positive above a negative; 0.5 is chance |
| kappa | agreement beyond chance; 0.6 to 0.8 is "substantial" |
| flag | restatement (same fact, narrower context), weakening (weaker than a premise) or entailed (the ontology already gives it) |
| scorer rule | the T that removes most trivial rows while losing at most one worth-showing row |
| primed | near-identical to a rubric example, so the example may steer the rating |

## The question

The closure derives 2,223 facts from the textbook. The cut hides those whose least specific end has IC under 2.5. That
number was set on 42 facts labelled by one LLM (`docs/ic-triviality.md`). So:

1. Is one IC cut the right tool, or only part of one?
2. If it is a cut, is 2.5 the right place?
3. What else could do the job, and which options change the formal system?

| today (observed, pinned) | value |
|---|---|
| kept / dropped / unjudged at 2.5 | 1,219 / 724 / 280 |
| unjudged ends, by ontology | PR 155, NCBITaxon 95, PO 27, MONDO 26, PATO 24, SO 19, HP 3, OBA 3 |
| kept facts with a restatement or weakening flag | 443 of 1,219 (36 percent) |

## The options

Letters follow the research brief; I and J are mine.

| | idea | core change? | needs | right | wrong |
|---|---|---|---|---|---|
| A | one cut on ends-min IC; tune T | no: a constant in `scripts/search` | ratings | simple; removes "cell", "body", "tissue" facts | blind to truth and restatement; near the cut it is a short term list |
| B | cut on path_min | no | nothing new | catches chains through a hub | drops 162 more kept facts; no better than A |
| C1 | gain: IC(conclusion) minus max IC(premise) | no | nothing new | one number for "says less than its premises" | noisy |
| C2 | drop flagged facts, then cut | no, as a script. Later perhaps a predicate over `Derivation` (a definition, not a rule) | the three checks (written: `ic_alternatives.py`) | no threshold; each drop explains itself | a weaker fact is sometimes the useful one; hides false restatements |
| D | surprise: premises far apart (Swanson), or belief change | no, as a proxy. A surprise function on opinions would be new in `Belief.lean`, so keep it outside | chapter ids; later a prior over facts | aims at "interesting" | false chains cross chapters too |
| E | path length | no | nothing | free | no signal, or the wrong way |
| F | ontology distance between the ends | no | graphs (`ic_ontology.py`) | distant terms say more | only when both ends share an ontology |
| G | rank, do not cut; tie-breaks; quotas | no: a report format | a good score | no cliff | raw IC ranks by ChEBI size (89 of the top 100) |
| H | learn to rank from ratings | no | 100+ human ratings, two raters | Dan's taste | 100 ratings support 5 to 7 features |
| I | annotation-frequency IC (GOA) | no: data | a GOA download | closer to "well known" | GO only; measures popularity |
| J | discount belief by IC | **no new operator:** `Opinion.discount` (`Belief.lean`) already scales by a weight in [0, 1], as `generalize` does. A core change only if `Derivation.opinionWith` applied it (an edit to an existing definition) | a map from IC to a weight | one number | mixes "how sure" with "how interesting" |

No option needs a new constructor, rule, operator or type. Only C2 (as a predicate) and J (as above) could later touch
the core.

## The stress set

Two sets. Both are pinned; a change to the closure, the IC table, the cut or the LLM ratings flips a pin.

| set | file | cases | PASS | FAIL | SILENT | INEXPRESSIBLE |
|---|---|---:|---:|---:|---:|---:|
| sheet facts (this program) | `data/stress/07/sheet_cases.tsv` | 58 | 30 | 21 | 7 | 0 |
| off-sheet (earlier step, `ic_cases.py`) | `data/stress/07/cases.tsv` | 32 | 9 | 11 | 8 | 4 |
| **all** | | 90 | 39 | 32 | 15 | 4 |

- Of the 30 sheet PASS marks, 16 are right calls (trivial and dropped, or worth showing and kept). 14 are middle facts
  (mean 0.5 to 2), where any verdict passes. So today's cut is right on 16 of the 44 sheet cases where a verdict is due.
- The off-sheet set covers what the sheet cannot: a synthetic cliff at 2.5, ChEBI crowding a ranking, audience,
  redundancy, "already in the ontology", "suspect". 2 of its 32 cases are synthetic. Re-run today: pins hold.
- C2's flags would express 2 of its 4 INEXPRESSIBLE cases, outside the core: C27 (weakening, entailed) and C28
  (entailed). Audience (C26) and "suspect" (C29) stay out of reach.

**The sheet** (`ic_sheet.py`, unchanged): 100 rows, shuffled, from 10 IC strata plus "no IC", each stratified by rule
then depth. 45 rows lie between IC 2 and 3. At 2.5, 57 are kept, 39 dropped, 4 unjudged. 42 carry a flag (21
restatements, 18 weakenings, 9 entailed). 33 carry an old LLM label from 2026-10-28. The sheet cases are the facts near
the cut (IC 2 to 3), those any rater called untrue, and those with no IC.

**The raters, round 2.** Each says it opened only the blind sheet and the rubric. Round 1 is kept in
`data/stress/07/round1_primed/`.

| rater | interesting 0 / 1 / 2 / 3 | true yes / no / unsure | rated 2+ and true |
|---|---|---|---:|
| llm1 | 53 / 30 / 8 / 9 | 77 / 10 / 13 | 4 |
| llm2 | 59 / 24 / 8 / 9 | 72 / 12 / 16 | 2 |
| llm3 | 55 / 29 / 9 / 7 | 75 / 12 / 13 | 2 |

**Marks** (as `ic_cases.py`). A trivial fact should be dropped; a worth-showing one kept. A false fact should be
flagged, which a cut cannot do: kept is FAIL, dropped is SILENT (hidden as trivial). No IC is SILENT. A middle fact may
go either way: PASS. Truth comes from the checked source where there is one (17 rows), else the LLM pool. No sheet case
is INEXPRESSIBLE: every sheet fact can be stated and scored.

| probe | cases | PASS | FAIL | SILENT |
|---|---:|---:|---:|---:|
| near the cut | 45 | 30 | 14 | 1 |
| rated untrue by any rater | 14 | 0 | 9 | 5 |
| no IC | 4 | 0 | 0 | 4 |
| **all (58 distinct)** | 58 | 30 | 21 | 7 |

**Near the cut: what fails.** 11 kept rows are rated trivial; 9 carry a flag, so C2 would drop them. 6 are "blood
vessel" rows (IC 2.66, e.g. R013 "aorta is next to blood vessel"); the others score on transmembrane transport,
muscle organ and chromosome. The other 3 near-cut FAILs are R016 and R026 (worth showing, dropped) and R074 (false,
kept).

**Four worth-showing rows near the cut.** Each has mean 2 and truth unsure. On the grid, demoting R016 or R026 moved
the cut; on exact cut points, no single row moves it.

| id | fact | IC | cut | biology | source (checked) |
|---|---|---:|---|---|---|
| R016 | Ganglion (in Platyhelminthes) overlaps gray matter | 2.45 | dropped | depends on the reading: UBERON's gray matter is "composed primarily of nerve cell bodies", part of a CNS allowed in any Bilateria (flatworms included); the book means vertebrates | UBERON:0002020; uberon.obo; book m45539-272 |
| R026 | Myofibril is attached to part of endomembrane system | 2.43 | dropped | true in GO's sense, which lists the cell membrane; the book adds it "although not technically within the cell" | GO:0012505; book m45538-241, m45432-89 |
| R031 | Blood vessel promotes the respiratory electron transport chain | 2.66 | kept | true only indirectly: vessels carry the oxygen the chain needs | book m45536-3, m45439-20 |
| R089 | Blood vessel promotes oxidative phosphorylation | 2.66 | kept | as R031 | as R031 |

None is a clean, true, interesting fact. Each is interesting because of a loose premise.

**Judged false** (a majority said `no`), plus R072 (one `no`, two unsure; its checked source says false):

| id | fact (as shown) | IC | cut | mark | why false | source |
|---|---|---:|---|---|---|---|
| R004 | ligand-gated ion channel activity promotes depolarisation | 5.01 | kept | FAIL | GABA-A channels pass chloride and inhibit | Sigel 2012 |
| R008 | not (transfer RNA has part thymine) | 9.04 | kept | FAIL | tRNA has ribothymidine (base: thymine) at position 54 | Jones 2024 |
| R017 | flagellum overlaps mitotic spindle | 4.88 | kept | FAIL | axoneme microtubules are not spindle parts | RO:0002131; book m45461-59 |
| R020 | arteries inhibit erythropoiesis | 3.48 | kept | FAIL | blames the carrier: the kidney makes EPO when oxygen is low | book m45537-238; Haase 2013 |
| R036 | oxygen (in leaf) lowers erythropoietin | none | unjudged | SILENT | leaf context on a kidney hormone | PO:0025034 |
| R043 | organs (in Metazoa) promote digestion | 0.32 | dropped | SILENT | the book says "accessory organs" | book m45535-246 |
| R062 | glucose catabolic process has part biosynthetic process | 2.44 | dropped | SILENT | "metabolism has anabolism" read as every metabolic process | book m45437-31 |
| R068 | leukocytes inhibit digestion | 1.76 | dropped | SILENT | two different bacteria (invaders, gut flora) | book m45427-11, m45535-130 |
| R070 | prokaryotic cell has part chromatin | 3.86 | kept | FAIL | false in the book's sense; GO's definition names no taxon | GO:0000785; book m45432-359 |
| R073 | insulin raises insulin | none | unjudged | SILENT | one path's sign is plus; the loop is negative feedback | book m45537-53, -200 |
| R074 | not (eukaryotic chromosomes surrounded by nuclear envelope) | 3.00 | kept | FAIL | a prokaryote sentence encoded about every chromosome | book m45429-74; GO:0005635 |
| R076 | macrophages inhibit digestion | 3.78 | kept | FAIL | as R068 | as R068 |
| R072 | NADPH overlaps glucose | 9.21 | kept | FAIL | "these atoms" are different atoms; overlaps needs one shared part | book m45452-79, m45439-76 |

Book ids are short forms (m45429-74 is `cell-structure-and-function-m45429-74`). The causes: a premise read as a
universal (R017, R043, R062, R074); a word with two meanings (R068, R072, R076); a context clash (R036); a path sign
read as a regulation (R020, R073).

**Pins.** `ic_analysis.py` pins each case's verdict, IC and mark, plus 59 headline numbers (every computed number in the
Summary among them). Changing one rating (R016, rater 1, 2 to 1) flipped 1 case pin and 21 headline pins, and the
script exited 1. Dan's ratings never break a pin (tested with a synthetic 80-row file).

## Results observed

All from `ic_analysis.py`, run 2026-10-30 (`analysis_report.txt`). **LLM stand-ins, not Dan.**

**1. The LLM raters agree well with each other.** Fleiss' kappa 0.77 on "interesting" (0.88 for under 2 against 2+)
and 0.74 on `true`; all three give the same truth call on 84 percent of rows. They are probably one model, so this says
little about two humans.

**2. The first-draft rubric primed round 1.** Same sheet, same kind of rater; only the rubric changed.

| pooled | round 1 (primed) | round 2 |
|---|---:|---:|
| rows interesting and judged true | 4 | **0** |
| scorer-rule T, grid | 2.5 | 2.25 |
| scorer-rule T, exact cut points | (2.433, 2.439] | (2.282, 2.433] |
| highest T losing nothing worth showing, exact | 2.657 | 2.433 |
| best-F1 T, exact | 3.477 | 2.433 |
| AUC of IC, interesting | 0.68 | 0.60 |
| AUC of "no flag", interesting | 0.66 | 0.70 |

- 8 rows were primed (R008, R020, R031, R048, R073, R078, R088, R089). Their truth call changed in 3 of 8; other rows,
  5 of 92. Per rater, weighted kappa between rounds is 0.79 to 0.85.
- Example: R031 and R089 sat next to "capillaries promote aerobic respiration" (level 2, true). Primed: true.
  Unprimed: unsure. On the grid, round 1's cut hung on these two.
- On exact cut points, priming moved the cut by one term: round 1 drops the endomembrane system (2.433), round 2 keeps
  it (24 closure facts). Both rounds put the cut below 2.5.
- So the draft's "2.5 loses nothing worth keeping" was partly priming and partly the grid.

**3. Precision and recall of the cut** (pooled, the 96 rows with an IC: 13 interesting, 6 worth showing, 52 trivial):

| T | kept | precision | recall | trivial kept | worth showing lost | judged false kept |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 96 | 0.14 | 1.00 | 52 | 0 | 10 |
| 2.25 | 69 | 0.17 | 0.92 | 28 | 0 | 8 |
| **2.4** | 63 | 0.19 | 0.92 | 23 | 0 | 8 |
| **2.5** | 57 | 0.16 | 0.69 | 23 | 2 | 7 |
| 3.0 | 34 | 0.18 | 0.46 | 12 | 4 | 6 |
| 4.0 | 24 | 0.13 | 0.23 | 8 | 4 | 3 |

- Precision stays between 0.13 and 0.19 up to T = 4, then falls. Closure-weighted it goes from 0.11 to 0.14 at 2.5.
- The cut removes trivia: closure-weighted, the trivial share of kept facts falls from 55 to 38 percent (37 at 2.4).
- Each rater alone gives the same shape; every T is in `analysis_threshold_curve.tsv`.

**4. Where does the cut belong?** Just under 2.5, on these ratings.

| test (pooled unless said) | grid | exact cut points |
|---|---|---|
| scorer rule | 2.25 | (2.282, 2.433], removing 29 trivial rows |
| highest T losing nothing worth showing | 2.25 | (2.282, 2.433] |
| best F1 | 2.25 | (2.282, 2.433] |
| scorer rule, per rater | 2.25, 2.25, 2.5 | (2.282, 2.433]; (2.433, 2.439]; (2.282, 2.433] |
| demote any one worth-showing row | R016 or R026 moves it to 2.5 | nothing moves it |
| bootstrap, 2,000 resamples | 2.25 in 60 percent, 2.5 in 32 percent | (2.282, 2.433] in 91 percent |

- Why: two terms. The 6 plasma-membrane rows (IC 2.28) are rated 0, 0, 0, 0, 0.3 and 1.0. The 4 endomembrane-system
  rows (2.43) are rated 1.0, 2.0, 0.7 and 1.0: obvious but real. So: drop plasma membrane, keep endomembrane system.
  2.5 drops both; 2.25 keeps both; no grid step falls between them.
- On the closure, kept / dropped / unjudged: 1,277 / 660 / 286 at 2.25; 1,247 / 695 / 281 at 2.4; 1,219 / 724 / 280
  at 2.5. The 28 facts 2.4 adds are the endomembrane system (24), biosynthetic process (2) and gray matter (2).
- Cost of 2.4 on the sheet: one more false row kept (R062, IC 2.44).
- Caution: this rests on 10 rows at two terms, rated by LLMs. It says where two terms fall, not a law about IC.

**5. Truth.** IC does not judge it.

- 12 rows judged false: 7 kept, 3 dropped, 2 unjudged.
- AUC of IC for true against false: 0.40 (90 percent interval 0.24 to 0.57). If anything, false facts score higher.
- Of 25 ratings of 3, 21 went to facts the same rater called false.
- All 14 interesting rows are judged false (8) or unsure (6). So "not trivial" is the fairer target for a filter.
- Part of this may be the rubric. Raters rate "as if true", and its three level-3 examples are all false or unsure.
  One ("meiosis happens during mitotic phase") is a "true of every X" error, like R017, R043, R062 and R074. X12
  tests this.

**6. Alternatives on the same ratings** (pooled; `analysis_alternatives.tsv`):

| option | score | n | AUC interesting (90 percent) | AUC not trivial (90 percent) |
|---|---|---:|---|---|
| A | ends-min IC | 96 | 0.60 (0.48 to 0.72) | 0.73 (0.65 to 0.81) |
| B | path_min | 100 | 0.55 (0.42 to 0.68) | 0.67 (0.58 to 0.76) |
| C1 | gain against premises | 94 | 0.62 (0.44 to 0.80) | 0.61 (0.51 to 0.70) |
| C2 | no flag | 100 | **0.70 (0.63 to 0.77)** | **0.79 (0.72 to 0.85)** |
| D | chapters of the premises | 100 | 0.61 (0.50 to 0.73) | 0.52 (0.45 to 0.60) |
| E | depth | 100 | 0.50 (0.39 to 0.62) | 0.42 (0.34 to 0.49) |
| F | ontology path length of the ends | 38 | 0.70 (0.54 to 0.85) | 0.80 (0.67 to 0.91) |
| F | Resnik similarity of the ends | 39 | 0.32 (0.19 to 0.45) | 0.21 (0.09 to 0.34) |
| G | IC / ln(ontology size) | 96 | 0.61 (0.48 to 0.73) | 0.75 (0.66 to 0.83) |

- Gain (C1) is no better than IC. Path length (E) is chance, or the wrong way: long chains climb through "cell".
- C2 is the best single signal. But the rubric's level 0 names restatements and weakenings, so C2 partly measures how
  well raters follow the rubric.
- F is strong where defined, on 38 rows only.

**7. Whole filters** (pooled; `analysis_rules.tsv`):

| filter | option | kept | precision | recall | trivial kept | worth lost | false kept |
|---|---|---:|---:|---:|---:|---:|---:|
| keep all | | 96 | 0.14 | 1.00 | 52 | 0 | 10 |
| IC 2.5 or more (today) | A | 57 | 0.16 | 0.69 | 23 | 2 | 7 |
| IC 2.4 or more | A | 63 | 0.19 | 0.92 | 23 | 0 | 8 |
| IC 2.25 or more | A | 69 | 0.17 | 0.92 | 28 | 0 | 8 |
| no flag | C2 | 55 | 0.22 | 0.92 | 15 | 0 | 8 |
| no flag, then IC 2.5 | C2+A | 34 | 0.24 | 0.62 | 4 | 2 | 6 |
| no flag, then IC 2.4 | C2+A | 40 | **0.28** | 0.85 | **4** | **0** | 7 |
| no flag, then IC 2.25 | C2+A | 42 | 0.26 | 0.85 | 5 | 0 | 7 |

- C2 then A at 2.4 is the best filter measured: it removes 48 of 52 trivial rows and loses nothing worth showing.
- By flag, trivial: 18 of 18 weakenings, 18 of 21 restatements, 7 of 9 entailed.
- 3 restatements are false (R036, R043, R074): a fact restated onto a context it clashes with. C2 would hide them. For
  program 01, restatement plus context clash is a truth signal.
- No filter removes the false facts: 5 to 9 survive each filter in `analysis_rules.tsv`.

**8. Which terms decide the cut.** Closure facts scored 2.25 to 2.75: 90, set by 9 terms (`analysis_terms_near_cut.tsv`).

| side of 2.5 | term (IC; closure facts it scores) |
|---|---|
| dropped | circulatory system (2.25; 4), plasma membrane (2.28; 26), endomembrane system (2.43; 24), biosynthetic process (2.44; 2), gray matter (2.45; 2) |
| kept | appendicular skeleton (2.52; 6), cytoskeleton (2.61; 1), blood vessel (2.66; 23), digestive system element (2.70; 2) |

Near the cut, choosing T is choosing a handful of terms: the old hub list again, picked by a number. Between 2.25 and
2.5 sit 58 closure facts set by 5 terms. 6 of the 9 "blood vessel" rows on the sheet are trivial, and all 6 are flagged.

## Experiments for later

Exit test first, then cost in agent tasks. Section 9 of the report recomputes X1 to X5 whenever ratings change.

| id | question | exit test | today (stand-in) | cost |
|---|---|---|---|---|
| X1 | does Dan agree with the stand-in? | 90+ rated rows; weighted kappa with the rounded LLM mean 0.6 or more | needs Dan | Dan 2 h; 0 tasks |
| X2 | flags before the cut (C2+A)? | on Dan's ratings, 80 percent or more of the 42 flagged rows rated 0, and at most 1 flagged row rated 2+ and true | passes (83 to 88 percent; 0) | 1: a copy of `closure.py` writing to `data/stress/07/` |
| X3 | path_min instead of ends-min? | path_min AUC 0.05 above ends-min, for "interesting" and "not trivial" | fails (-0.05; -0.06) | 0 |
| X4 | can ratings place T? | demoting any one worth-showing row moves the scorer-rule T (exact cut points) by under 0.25 | passes: no move. On the grid it failed (the grid's fault) | 0 |
| X5 | does IC separate trivia? | AUC of IC for "not trivial" 0.75 or more | 0.73, just fails (round 1: 0.75) | 0 |
| X6 | is "trivial" stable between humans? | a second human: weighted kappa with Dan 0.4 or more | LLMs: Fleiss 0.77 | a colleague, 2 h |
| X7 | is the stand-in stable run to run? | a third LLM round, same rubric: weighted kappa 0.8+ with round 2 per rater, and the same exact scorer-rule interval | n/a | 3 rater tasks |
| X8 | can ontology distance cover more facts? | defined for 80+ of 100 rows (cross-ontology links), AUC 0.75+ on Dan's ratings | 0.70 on 38 rows | 2 |
| X9 | does a learned ranker (H) beat one score? | ordinal model on 6 features; leave-one-out AUC 0.05 above IC and 0.75+. Only after X1 and X6 | n/a | 1 to 2 |
| X10 | can the unjudged be scored? | IC for PR, PO, MONDO, PATO, SO, NCBITaxon (a copy of `ic.py`); unjudged from 280 to under 50 | n/a | 1 to 2 |
| X11 | can a check catch false facts (with program 01)? | flags 6+ of the 13 false rows and at most 2 of the 70 rows all raters call true | n/a | 2 |
| X12 | does the rubric's level 3 steer "interesting" towards "false"? | a round whose level-3 examples are true: 3 or more rows interesting and judged true by the pool (today 0) | n/a | 3 rater tasks, 1 to write the examples |

## What would change the decision

| if Dan's ratings show | then |
|---|---|
| X4 passes and his cut is in (2.282, 2.433] | set T to 2.4: 28 more closure facts, nearly all about the endomembrane system |
| X4 passes and his cut is elsewhere | set T there; it moves a handful of terms (item 8) |
| X4 fails | stop tuning T on ratings. Fix T by naming the terms on each side (item 8), or rank (G) |
| X2 passes | put C2 before A (today: 48 of 52 trivial rows go, nothing worth showing lost) |
| AUC of IC for "not trivial" under 0.65 | IC is the wrong axis: C2 plus ranking (G) |
| X3 passes | switch A to B |
| X1 fails | LLM stand-ins cannot pre-screen; later thresholds need human ratings |
| X6 fails | "trivial" is not well defined; rank and fold only (G) |
| in every case | a truth check apart from IC (X11, program 01): 7 of 12 false rows pass the cut |

J would need a reason to make interest part of belief. I see none.

Roadmap: M8 (literature at scale) needs a filter between the closure and a human; C2+A is the best measured. M5
(ontologies as biolib) supplies the "entailed" flag. Program 01's false universals are the facts this sheet calls
"surprising".

## Limits

- **The ratings are LLM stand-ins**: three raters, probably one model. Their agreement is not human agreement.
- Round 2's rubric passes a shared-term check, but an example can still prime by analogy. "Capillaries" did it for
  "blood vessel" in round 1. In round 2, the level-3 examples (all false or unsure) may steer "interesting" towards
  "false". No check catches that.
- Only 6 rows are worth showing; one row is a sixth of recall. Every curve is coarse.
- The exact cut rests on 10 rows at two terms. It fits the sheet; it says nothing about terms not on it.
- The rubric defines restatements and weakenings as 0, so C2's success is partly built in.
- 14 of the 30 sheet PASS marks are free: a middle fact passes whatever the cut does.
- R020 and R031/R089 share one pattern: a carrier credited with an effect. The raters called R020 false and the
  others unsure, so their marks differ (FAIL against PASS). Marks for this pattern rest on rater judgement.
- Closure-weighted numbers rest on 6 to 12 rows per stratum.
- 17 rows have a checked source (the 12 judged false, R072, the four worth-showing rows). Other truth calls are the raters'.
- No Lean file, by design: nothing here is in the core.

## Files

| path | what |
|---|---|
| `scripts/stress/ic_analysis.py` | the analysis; 58 case and 59 headline pins. Reads `rating_dan.tsv` or `.csv`; `--dan FILE --out DIR` for tests |
| `scripts/stress/ic_verify_round2.py` | the author's live OLS4, Crossref and Europe PMC check (`python3 -I`) |
| `scripts/stress/ic_review_verify.py` | the review's own live check, fresh cache: every CURIE in the doc and case files, every PMID and DOI (`python3 -I`) |
| `data/stress/07/analysis_*`, `sheet_cases.tsv` | outputs of `ic_analysis.py` |
| `data/stress/07/round1_primed/` | copies of the round-1 outputs |
| `data/stress/07/verify_round2_*.tsv`, `review_*.tsv` | CURIE and reference checks (author; review) |
| other `scripts/stress/ic_*.py` | earlier steps; re-run in review, outputs byte-identical |

Rerun: `python3 scripts/stress/ic_cases.py && python3 scripts/stress/ic_analysis.py`. Both are deterministic: two hash
seeds gave byte-identical files.

## References (checked)

Re-checked live in review on Crossref or Europe PMC: 26 of 26 match on title, first author and year
(`review_refs.tsv`). The abstracts of Sigel 2012, Jones 2024 and Haase 2013 were read and support the use made of them.

| ref | used for | id |
|---|---|---|
| Resnik 1999, "Semantic similarity in a taxonomy", J Artif Intell Res | IC; similarity (F) | doi:10.1613/jair.514 |
| Sánchez 2011, "Ontology-based information content computation", Knowl-Based Syst | intrinsic IC | doi:10.1016/j.knosys.2010.10.001 |
| Lord 2003, "Investigating semantic similarity measures across the Gene Ontology", Bioinformatics | I | PMID:12835272 |
| Pesquita 2009, "Semantic similarity in biomedical ontologies", PLoS Comput Biol | F | PMID:19649320 |
| Geng 2006, "Interestingness measures for data mining", ACM Comput Surv | D | doi:10.1145/1132960.1132963 |
| Silberschatz 1996, "What makes patterns interesting in knowledge discovery systems", IEEE TKDE | D | doi:10.1109/69.553165 |
| Swanson 1986, "Fish oil, Raynaud's syndrome, and undiscovered public knowledge", Perspect Biol Med | D | PMID:3797213 |
| Itti 2009, "Bayesian surprise attracts human attention", Vision Res | D | PMID:18834898 |
| Horridge 2008, "Laconic and precise justifications in OWL", ISWC | C2 | doi:10.1007/978-3-540-88564-1_21 |
| Tsurel 2017, "Fun Facts: automatic trivia fact extraction from Wikipedia", WSDM | H | doi:10.1145/3018661.3018709 |
| Galárraga 2013, "AMIE", WWW | H | doi:10.1145/2488388.2488425 |
| Joachims 2002, "Optimizing search engines using clickthrough data", KDD | H | doi:10.1145/775047.775067 |
| Burges 2005, "Learning to rank using gradient descent", ICML | H | doi:10.1145/1102351.1102363 |
| Bradley 1952, "Rank analysis of incomplete block designs", Biometrika | H | doi:10.1093/biomet/39.3-4.324 |
| Thurstone 1927, "A law of comparative judgment", Psychol Rev | H | doi:10.1037/h0070288 |
| McCullagh 1980, "Regression models for ordinal data", J R Stat Soc B | X9 | doi:10.1111/j.2517-6161.1980.tb01109.x |
| Fleiss 1971, "Measuring nominal scale agreement among many raters", Psychol Bull | kappa | doi:10.1037/h0031619 |
| Cohen 1960, "A coefficient of agreement for nominal scales", Educ Psychol Meas | kappa | doi:10.1177/001316446002000104 |
| Cohen 1968, "Weighted kappa", Psychol Bull | weighted kappa | doi:10.1037/h0026256 |
| Landis 1977, "The measurement of observer agreement for categorical data", Biometrics | kappa bands | doi:10.2307/2529310 |
| Hanley 1982, "The meaning and use of the area under a ROC curve", Radiology | AUC | doi:10.1148/radiology.143.1.7063747 |
| Efron 1979, "Bootstrap methods: another look at the jackknife", Ann Stat | intervals | doi:10.1214/aos/1176344552 |
| Youden 1950, "Index for rating diagnostic tests", Cancer | Youden's J | doi:10.1002/1097-0142(1950)3:1<32::aid-cncr2820030106>3.0.co;2-3 |
| Sigel 2012, "Structure, function, and modulation of GABA(A) receptors", J Biol Chem | R004 | PMID:23038269 |
| Jones 2024, "Conserved 5-methyluridine tRNA modification modulates ribosome translocation", PNAS | R008 | PMID:39159370 |
| Haase 2013, "Regulation of erythropoiesis by hypoxia-inducible factors", Blood Rev | R020 | PMID:23291219 |

CURIEs: the review looked up all 136 in this doc, `sheet_cases.tsv`, `cases.tsv` and `analysis_terms_near_cut.tsv` on
OLS4 (`review_curies.tsv`); all found. CL:0000548 ("animal cell") is obsolete, as the sheet says. BFO:0000050 is an RO
property. Platyhelminthes is in Bilateria (NCBI Taxonomy lineage, read in review). Every textbook sentence quoted
here was checked against `data/textbook/claims*` and matches (with the elisions shown).

## UNVERIFIED

- Resnik 1995 (IJCAI): not on Crossref; Resnik 1999 is cited instead.
- Which model the LLM raters ran on, and that they were blind: both rest on their own notes.
- The rubric's example levels, the old 42 labels and all ratings: LLM judgements, not facts.
- The truth of the rows outside the 17 with a checked source.
- Whether GO:0000785 (chromatin) carries a taxon constraint: `go.obo` has none at all; GO keeps them in files I did
  not load. For gray matter, `uberon.obo` has no taxon line; its parent, central nervous system, is `in_taxon`
  Bilateria. I did not load the OWL.

## What the review changed (2026-10-30)

- Added exact cut points beside the 0.25 grid. They reverse the draft's headline: the ratings do place the cut.
- R072's mark now follows its checked source (false): PASS to FAIL. Sheet marks went from 31 / 20 / 7 to 30 / 21 / 7.
- Split PASS into right calls (16) and free passes for middle facts (14).
- J relabelled: `Opinion.discount` exists, so J needs no new operator.
- Pinned the Summary numbers (29 to 59 headline pins), the closure verdicts at 2.25, 2.4 and 2.5, and C2's flags on C27
  and C28.
- Added the rubric's level-3 examples as a possible cause of "interesting means false", with an experiment (X12).
- Fixed: precision "0.13 to 0.18" (it reaches 0.19). X11 now counts 13 false rows (with R072).
- Fixed `ic_score_ratings.py` (the optional old-9 step): it dropped every `2.0`-style rating as unreadable.
