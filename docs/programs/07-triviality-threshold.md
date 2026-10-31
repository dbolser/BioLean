# Program 07: the IC triviality threshold and a human-rated set

Decision 7 is open ("more research needed"). Written 2026-10-30; updated 2026-10-31 with a third rating round and an
adversarial review (changes at the end). **The LLM ratings are a stand-in until Dan rates the sheet.** Nothing here
touches the Lean core.

## Summary

- **What I did.** Three fresh blind LLM raters rated the sheet again (round 3). `ic_analysis.py` compares three
  rounds and pools rounds 2 and 3. A review re-ran everything, re-checked every number, CURIE and reference, and
  fixed three truth calls. **No human has rated.**
- **Round 2's two headlines did not replicate.** "Move the cut to 2.4": raters agree well across rounds (weighted
  kappa 0.85 to 0.95), yet the best cut moved (X7 fails). "The first rubric primed round 1": primed rows change as
  often between two unprimed rounds.
- **Best reading: keep 2.5. It is not robust.** On the six pooled ratings every cut from 2.29 to 2.65 ties, 2.4 and
  2.5 alike. 2.5 is in that range in 60 percent of resamples. The top end rests on two rows of one pattern, which
  the same raters call false in a third row.
- **2.4 would show more false facts.** Of the 6 sheet rows between 2.4 and 2.5, 3 are false by a checked source
  (found by the review). Nothing favours moving.
- **Stable in every round.** The cut removes trivia but finds little (precision 0.16 to 0.21 at 2.5; base rate
  0.15). Flags first, then the cut, is the best filter (4 or 5 trivial rows kept, not 23 or 25). Truth needs its
  own check: IC (AUC 0.43) and the core's own belief (89 of 100 facts at 0.80) both miss most false facts.
- **What matters now.** Dan rates the sheet: 2 columns, about 2 hours, one command (below). No option needs a new
  constructor, rule, operator or type.

## Dan: how to rate (3 steps)

Rate before reading further: the rest of this doc names rows and their IC. From the repo root (`~/Build/BioLean`):

1. `cp data/stress/07/rating_sheet_blind.tsv data/stress/07/rating_dan.tsv`
2. Open `data/stress/07/rating_dan.tsv` in LibreOffice (tab-separated), with `data/stress/07/rubric.md` beside it.
   Fill two columns: `interesting` (0 to 3, rated as if the fact were true) and `true` (yes, no or unsure). `note` is
   optional. About a minute a row, so about 2 hours. Save in the same format. Several sittings are fine: empty rows
   are skipped.
3. Run `python3 scripts/stress/ic_analysis.py`. Read section 0 of `data/stress/07/analysis_report.txt`.

Section 0 shows your agreement with the LLMs, your range of best cuts ("plateau"), and whether 2.4 and 2.5 are in it.
`y`, `n`, `?`, `2.0` and a `.csv` save also work. Optional, 10 minutes: the 9 old facts in
`rating_sheet_old9_blind.tsv`, scored by `python3 scripts/stress/ic_score_ratings.py data/stress/07/rating_dan.tsv
--old9 <your rated old9 file>`.

## Words used here

| word | meaning here |
|---|---|
| core | the Lean formal system: `Claim` constructors, `Derivation` rules, opinion operators, types |
| IC | information content of a term: -log(subtree size / ontology size), over is_a plus part_of |
| score | the lower IC of a fact's two ends; the cut uses it |
| path_min | the lowest IC of any entity in the derivation |
| T, cut | keep a fact if its score is T or more; today 2.5 (`IC_MIN` in `scripts/search/closure.py`) |
| grid; exact cut points | T in steps of 0.25; T at every IC value on the sheet. "(2.282, 2.433]": any T above 2.282, up to 2.433 |
| scorer rule | the T that removes most trivial rows while losing at most one worth-showing row (lowest T on ties) |
| plateau | every T that ties with the scorer rule: the range of equally good cuts |
| round; r23 | one pass of three blind LLM raters (round 1: first-draft rubric; rounds 2 and 3: fixed rubric); r23 pools rounds 2 and 3 |
| trivial; interesting | rated 0 (pooled: mean under 0.5); rated 2 or 3 (pooled: mean 2 or more) |
| judged false; worth showing | most raters say `no`; interesting and not judged false |
| unjudged | an end has no IC, so no verdict |
| precision, recall | share of kept facts that are interesting; share of interesting facts kept |
| AUC; kappa | chance a score ranks a positive above a negative (0.5 is chance); agreement beyond chance (0.6 to 0.8 "substantial") |
| flag | restatement (same fact, narrower context), weakening (weaker than a premise) or entailed (the ontology gives it) |
| primed | near-identical to a first-draft rubric example, so the example might steer the rating |
| checked source | a truth call from a textbook sentence, an ontology record or a paper I checked (20 rows); else the LLM pool |
| belief | the strength the core gives a derived fact (subjective logic; `closure.py` mirrors `Derivation.opinionWith`) |

## The question

The closure derives 2,223 facts from the textbook. The cut hides those whose least specific end has IC under 2.5. That
number was set on 42 facts labelled by one LLM (`docs/ic-triviality.md`). So:

1. Is one IC cut the right tool, or only part of one?
2. If it is a cut, is 2.5 the right place?
3. What else could do the job, and which options change the formal system?

| today (observed, pinned) | value |
|---|---|
| kept / dropped / unjudged at 2.5 | 1,219 / 724 / 280 |
| ends with no IC (facts with no score), by ontology | PR 155, NCBITaxon 95, PO 27, MONDO 26, PATO 24, SO 19, HP 3, OBA 3 |
| kept facts with a restatement or weakening flag | 443 of 1,219 (36 percent) |

## The options

Letters follow the research brief; I and J are mine; the review added K and L.

| | idea | core change? | needs | right | wrong |
|---|---|---|---|---|---|
| A | one cut on ends-min IC; tune T | no: a constant in `scripts/search` | ratings | simple; removes "cell", "body", "tissue" facts | blind to truth; near the cut it is a short term list |
| B | cut on path_min | no | nothing new | catches chains through a hub | drops 162 more kept facts; worse than A in every round |
| C1 | gain: IC(conclusion) minus max IC(premise) | no | nothing new | one number for "says less than its premises" | noisy |
| C2 | drop flagged facts, then cut | no, as a script. Later perhaps a predicate over `Derivation` (a definition, not a rule) | the three checks (`ic_alternatives.py`) | each drop explains itself | a weaker fact is sometimes the useful one; hides false restatements |
| D | surprise: premises far apart (Swanson), or belief change | no, as a proxy. A surprise function on opinions would be a new operator: keep it outside | chapter ids; later a prior over facts | aims at "interesting" | false chains cross chapters too |
| E | path length | no | nothing | free | no signal, or the wrong way |
| F | ontology distance between the ends | no | graphs (`ic_ontology.py`) | distant terms say more | only when both ends share an ontology (38 of 100 rows) |
| G | rank, do not cut; tie-breaks; quotas | no: a report format | a good score | no cliff | raw IC ranks by ChEBI size (89 of the top 100) |
| H | learn to rank from ratings | no | 100+ human ratings, two raters | Dan's taste | 100 ratings support 5 to 7 features |
| I | annotation-frequency IC (GOA) | no: data | a GOA download | closer to "well known" | GO only; measures popularity |
| J | discount belief by IC | **no new operator:** `Opinion.discount` (`Belief.lean`) exists. A core change only if `Derivation.opinionWith` used it (an edit to an existing definition) | a map from IC to a weight | one number | mixes "how sure" with "how interesting", which run opposite ways (L) |
| K | a named list of hub terms instead of T | no: data | Dan marks the 9 terms near the cut (X13) | each drop names its term | the old hub list was unstable (`docs/ic-triviality.md`) |
| L | filter or rank by the core's own belief | no: reads existing opinions | nothing new | already in the core | flat: 89 of 100 sheet facts have belief 0.80; it falls only along effect chains, which are the interesting ones (AUC 0.21) |

No option needs a new constructor, rule, operator or type. Only C2 (as a new definition) and J (as above) could later
touch the core.

## The stress set

Two sets, both pinned. A change to the closure, the IC table, the cut, the truth calls or the LLM rating files flips a
pin.

| set | file | cases | PASS | FAIL | SILENT | INEXPRESSIBLE |
|---|---|---:|---:|---:|---:|---:|
| sheet facts (round 3, after the review) | `data/stress/07/sheet_cases.tsv` | 59 | 32 | 18 | 9 | 0 |
| off-sheet (earlier step, `ic_cases.py`) | `data/stress/07/cases.tsv` | 32 | 9 | 11 | 8 | 4 |
| **all** | | 91 | 41 | 29 | 17 | 4 |

- Of the 18 sheet FAILs, 6 are false facts the cut keeps. No cut can flag a false fact: these say IC is the wrong
  tool for truth, not that T is wrong. The other 12 are trivial facts kept.
- Of the 32 sheet PASS marks, 19 are right calls and 13 are middle facts, where any verdict passes.
- **On the job a cut can do** (a trivial or worth-showing fact with an IC) it is right on 19 of 31.
- The off-sheet set covers a synthetic cliff at 2.5, ChEBI crowding a ranking, audience, redundancy, "already in the
  ontology", "suspect". 2 of 32 are synthetic. All pins hold. C2's flags would express 2 of its 4 INEXPRESSIBLE cases
  (C27, C28), outside the core.

**The sheet** (`ic_sheet.py`): 100 rows from 10 IC strata plus "no IC". 45 lie between IC 2 and 3. At 2.5: 57
kept, 39 dropped, 4 unjudged. 42 carry a flag.

**Marks** (as `ic_cases.py`). Trivial should be dropped; worth showing, kept. False should be flagged, which a cut
cannot do: kept is FAIL, dropped is SILENT. No IC is SILENT. A middle fact passes either way. Truth is the checked
source where there is one (20 rows), else the LLM pool. Every sheet fact can be stated: none is INEXPRESSIBLE.

| probe | cases | PASS | FAIL | SILENT |
|---|---:|---:|---:|---:|
| near the cut (IC 2 to 3) | 45 | 29 | 13 | 3 |
| rated untrue by any round-3 rater | 15 | 4 | 6 | 5 |
| no IC | 4 | 0 | 0 | 4 |
| **all (59 distinct)** | 59 | 32 | 18 | 9 |

**Near the cut, 13 FAILs:** 12 trivial rows kept (6 are "blood vessel" rows such as R013 "aorta is next to blood
vessel"; C2 would drop 9 of the 12) and R074 (false, kept).

**The rows that decide the cut** (pooled mean and truth, round 3; round 2 in brackets). The first four lines sit
between 2.4 and 2.5; R031 and R089 set the ceiling.

| id | fact | IC | round 3 (round 2) | biology (checked) |
|---|---|---:|---|---|
| R021, R098 | passive transport occurs in, ion channel part of, the endomembrane system | 2.43 | 1.0, 1.0 (1.0, 1.0) | **false** as universals: GO's uniplex complex (GO:1990246) is an ion channel in the mitochondrial inner membrane, outside GO:0012505 |
| R083 | endomembrane system has part phospholipid | 2.43 | 0.3 (0.7) | true |
| R026 | myofibril is attached to part of endomembrane system | 2.43 | 1.0 yes (2.0 unsure) | depends: the book adds the plasma membrane "although not technically within the cell" (m45432-89); GO's definition names it, GO's graph does not |
| R062 | glucose catabolic process has part biosynthetic process | 2.44 | 3.0 false (3.0 false) | false: "metabolism has anabolism" read as every metabolic process (m45437-31) |
| R016 | ganglion (in Platyhelminthes) overlaps gray matter | 2.45 | 1.7 unsure (2.0 unsure) | depends: the book means vertebrates (m45539-272); in uberon.obo gray matter is part of a CNS that is in_taxon Bilateria |
| R031 | blood vessel promotes the respiratory electron transport chain | 2.66 | 2.0 yes (2.0 unsure) | true only indirectly: vessels carry the oxygen the chain needs (m45536-3, m45439-20) |
| R089 | blood vessel promotes oxidative phosphorylation | 2.66 | 2.0 yes (2.0 unsure) | as R031 |

Book ids are short forms: m45432-89 is `cell-structure-and-function-m45432-89`.

**Judged false by a checked source** (13 rows; kept 6, dropped 5, unjudged 2):

| id | fact (as shown) | IC | cut | mark | why false | source |
|---|---|---:|---|---|---|---|
| R004 | ligand-gated ion channel activity promotes depolarisation | 5.01 | kept | FAIL | GABA-A channels pass chloride | Sigel 2012 |
| R008 | not (transfer RNA has part thymine) | 9.04 | kept | FAIL | tRNA has ribothymidine at position 54 | Jones 2024 |
| R017 | flagellum overlaps mitotic spindle | 4.88 | kept | FAIL | axoneme microtubules are not spindle parts | RO:0002131; m45461-59 |
| R021 | passive transport occurs in endomembrane system | 2.43 | dropped | SILENT | mitochondrial channels | GO:1990246; m45432-15 |
| R036 | oxygen (in leaf) lowers erythropoietin | none | unjudged | SILENT | leaf context on a kidney hormone | PO:0025034 |
| R043 | organs (in Metazoa) promote digestion | 0.32 | dropped | SILENT | the book says "accessory organs" | m45535-246 |
| R062 | glucose catabolic process has part biosynthetic process | 2.44 | dropped | SILENT | as above | m45437-31 |
| R068 | leukocytes inhibit digestion | 1.76 | dropped | SILENT | two different bacteria (invaders, gut flora) | m45427-11, m45535-130 |
| R072 | NADPH overlaps glucose | 9.21 | kept | FAIL | "these atoms" are different atoms | m45452-79, m45439-76 |
| R073 | insulin raises insulin | none | unjudged | SILENT | a path sign, not the net effect (negative feedback) | m45537-53, -200 |
| R074 | not (eukaryotic chromosomes surrounded by nuclear envelope) | 3.00 | kept | FAIL | a prokaryote sentence made universal | m45429-74; GO:0005635 |
| R076 | macrophages inhibit digestion | 3.78 | kept | FAIL | as R068 | as R068 |
| R098 | ion channel part of endomembrane system | 2.43 | dropped | SILENT | as R021 | GO:1990246; m45539-57 |

Causes: a premise read as a universal (R004, R008, R017, R021, R043, R062, R074, R098: 8 of 13, program 01's
territory); a word with two meanings (R068, R072, R076); a context clash (R036); a path sign read as the net effect
(R073).

**Truth calls changed on 2026-10-31** (each flips a pin):

| id | from, to | why | mark |
|---|---|---|---|
| R070 prokaryotic cell has part chromatin | false, depends | archaeal histones form chromatin (Mattiroli 2017); QuickGO limits GO:0000785 only to cellular organisms | FAIL to PASS |
| R088 cells have part fatty acid | (none), depends | archaeal lipids are isoprenoid ethers (Li 2025), yet "certain archaea appear to synthesize and/or metabolize fatty acids" (Dibrova 2014) | PASS |
| R020 arteries inhibit erythropoiesis | false, depends (review) | the same shape (`effect` by `viaAmount`) and carrier premise (m45536-3) as R031 and R089 | FAIL to PASS |
| R021, R098 | (none), false (review) | above | PASS to SILENT |

## Results observed

All from `ic_analysis.py`, run 2026-10-31 (`analysis_report.txt`). **LLM stand-ins, not Dan.**

**1. The raters agree well.** Round 3: Fleiss' kappa 0.80 on "interesting" (0.91 for under 2 against 2+) and 0.72 on
`true`. Same truth call from all three on 84 percent of rows; pairwise, 89 percent. Probably one model, so this says
little about two humans.

**2. Three rounds: the cut moved between two runs of the same rubric.**

| pooled, all 100 rows | round 1 (primed) | round 2 | round 3 | r23 (six ratings) |
|---|---:|---:|---:|---:|
| interesting / worth showing | 14 / 5 | 14 / 6 | 15 / 7 | 12 / 3 |
| interesting and judged true | 4 | 0 | 4 | 0 |
| plateau (equally good cuts) | (2.433, 2.657] | (2.282, 2.446] | (2.433, 2.657] | (2.282, 2.657] |
| 2.5 in the plateau | yes | **no** | yes | yes |
| 2.4 in the plateau | no | yes | no | yes |
| AUC of IC, interesting | 0.68 | 0.60 | 0.70 | 0.64 |

- **X7 fails.** Its exit test (written 2026-10-30): per-rater weighted kappa 0.8+ between rounds 2 and 3 (passes:
  0.85, 0.87, 0.95) and the same exact scorer interval (fails).
- Why: R016 and R026 had mean 2.0 in round 2, so 2.5 "lost" two worth-showing rows. Round 3: 1.7 and 1.0.
- Pooling six ratings, 2.5 is in the plateau in 60 percent of 2,000 bootstrap resamples.
- **Fragile.** One rating (R031, rater 1, 2 to 1) moves the round-3 scorer cut from 2.44 to 3.78 (pinned; on a copy
  it flipped 31 pins). The rule may lose one worth-showing row, and there are only 3 to 7. Read the plateau.

**Priming, rechecked.** Rounds 2 and 3 share a rubric, so their difference is the noise floor.

| pair | average change of pooled mean: primed (8) / other (92) | truth changed: primed / other |
|---|---|---|
| round 1 to 2 (rubric changed) | 0.25 / 0.17 | 3 of 8 / 5 of 92 |
| round 1 to 3 (rubric changed) | 0.12 / 0.13 | 2 of 8 / 7 of 92 |
| round 2 to 3 (same rubric) | 0.12 / 0.10 | 3 of 8 / 6 of 92 |

Primed rows change as much with no rubric change. They are borderline rows; priming is not shown.

**3. Precision and recall of the cut** (round 3 pooled, the 96 rows with an IC: 14 interesting, 7 worth showing, 53
trivial):

| T | kept | precision | recall | trivial kept | worth showing lost | judged false kept |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 96 | 0.15 | 1.00 | 53 | 0 | 11 |
| 2.25 | 69 | 0.19 | 0.93 | 30 | 0 | 8 |
| 2.4 | 63 | 0.21 | 0.93 | 26 | 0 | 8 |
| **2.5** | 57 | 0.21 | 0.86 | 25 | 0 | 7 |
| 3.0 | 34 | 0.26 | 0.64 | 13 | 2 | 6 |
| 4.0 | 24 | 0.21 | 0.36 | 9 | 4 | 4 |

- Precision peaks at 0.30 (T = 3.75). At 2.5: 0.18, 0.16, 0.21 in rounds 1, 2, 3.
- Closure-weighted, the trivial share of kept facts falls from 57 to 43 percent (round 2: 55 to 38). Each rater
  alone gives the same shape (`analysis_threshold_curve.tsv`).

**4. Where the cut belongs: a band, not a point.** 90 closure facts score 2.25 to 2.75, set by 9 terms
(`analysis_terms_near_cut.tsv`). Choosing T there is choosing terms: the old hub list again, picked by a number.

| side of 2.5 | term (IC; closure facts it scores) | sheet evidence, every round |
|---|---|---|
| dropped | circulatory system (2.25; 4) | |
| dropped: the floor | plasma membrane (2.28; 26) | below it, 23 or 24 of 27 rows trivial; at it, 4 or 5 of 6. Every plateau starts above 2.28 |
| dropped: inside the band | endomembrane system (2.43; 24), biosynthetic process (2.44; 2), gray matter (2.45; 2) | 6 rows: 3 false by checked source (R021, R062, R098), 2 depend (R016, R026), 1 true (R083) |
| kept | appendicular skeleton (2.52; 6), cytoskeleton (2.61; 1) | 3 rows, all middle facts |
| kept: the ceiling | blood vessel (2.66; 23) | 6 of 9 rows trivial (all flagged), but R031 and R089 are rated 2. Any T above 2.66 loses both |
| kept | digestive system element (2.70; 2) | |

- Closure, kept / dropped / unjudged: 1,247 / 695 / 281 at 2.4; 1,219 / 724 / 280 at 2.5.
- The ceiling is one pattern, a carrier credited with an effect. R020 ("arteries inhibit erythropoiesis") has it
  too: the LLM pool calls R020 false and R031, R089 true; the checked source calls all three "depends". With R031 and
  R089 below 2, or false, the plateau moves to (3.674, 3.905] (pinned).
- Caution: 21 rows at five terms, rated by LLMs. Not a law about IC.

**5. Truth.** IC does not judge it, in any round.

- By checked source, 13 rows are false: 6 kept, 5 dropped, 2 unjudged.
- AUC of IC for true against false: 0.43 in round 3 (90 percent interval 0.25 to 0.62); 0.40 in round 2.
- Of 21 ratings of 3 in round 3, 18 went to facts the same rater called false. "Surprising" mostly means "wrong".
  So "not trivial" is the fairer target for a filter, and truth needs its own check (X11).
- **The core's belief misses them too** (review, pinned). On the sheet: 0.80 for 89 facts, 0.64 for 9, then 0.51,
  0.41. A logical step keeps the weaker premise, so relational facts stay at 0.80; only `viaAmount` chains fall. AUC
  true above false is 0.64, all from 4 false chains (R004, R068, R073, R076); 9 false rows sit at 0.80. Belief
  measures evidence, not encoding errors. Interesting facts are mostly those chains (AUC for interesting 0.21).

**6. Alternatives on the same ratings** (pooled AUC, round 3 then round 2; 90 percent interval for round 3;
`analysis_alternatives.tsv`):

| option | score | n | interesting | not trivial |
|---|---|---:|---|---|
| A | ends-min IC | 96 | 0.70 (0.58 to 0.81); 0.60 | 0.70 (0.61 to 0.78); 0.73 |
| B | path_min | 100 | 0.61 (0.47 to 0.74); 0.55 | 0.62 (0.53 to 0.71); 0.67 |
| C1 | gain against premises | 94 | 0.64 (0.47 to 0.80); 0.62 | 0.63 (0.53 to 0.73); 0.61 |
| C2 | no flag | 100 | 0.71 (0.64 to 0.77); 0.70 | **0.77 (0.71 to 0.84); 0.79** |
| D | chapters of the premises | 100 | 0.59 (0.49 to 0.71); 0.61 | 0.51 (0.44 to 0.59); 0.52 |
| E | depth | 100 | 0.47 (0.36 to 0.59); 0.50 | 0.41 (0.33 to 0.49); 0.42 |
| F | ontology path length of the ends | 38 | 0.83 (0.69 to 0.96); 0.70 | 0.77 (0.64 to 0.89); 0.80 |
| G | IC / ln(ontology size) | 96 | 0.70 (0.58 to 0.82); 0.61 | 0.70 (0.61 to 0.79); 0.75 |

- C2 is the most stable signal (partly built in; see Limits).
- Gain (C1) is no better than IC; B never beats A (X3 fails); path length (E) is chance or worse.
- F is strong where defined, on 38 rows only, and moved 0.13 between rounds.

**7. Whole filters** (pooled; `analysis_rules.tsv`). Round 3, with round 2 in brackets where it differs:

| filter | option | kept | precision | trivial kept | worth lost | false kept |
|---|---|---:|---:|---:|---:|---:|
| keep all | | 96 | 0.15 (0.14) | 53 (52) | 0 | 11 (10) |
| IC 2.5 or more (today) | A | 57 | 0.21 (0.16) | 25 (23) | 0 (2) | 7 |
| IC 2.4 or more | A | 63 | 0.21 (0.19) | 26 (23) | 0 | 8 |
| no flag | C2 | 55 | 0.24 (0.22) | 17 (15) | 0 | 9 (8) |
| no flag, then IC 2.5 | C2+A | 34 | **0.32** (0.24) | **5** (4) | 0 (2) | 6 |
| no flag, then IC 2.4 | C2+A | 40 | 0.30 (0.28) | 6 (4) | 0 | 7 |

- C2 then A is the best filter in both rounds: 4 to 6 trivial rows kept instead of 23 to 26.
- Trivial, round 3: 18 of 18 weakenings, 18 of 21 restatements, 7 of 9 entailed. No flagged row is worth showing.
- 3 restatements are false (R036, R043, R074): a clashing context, which program 01 would read as a truth signal.
  C2 would hide them. No filter removes false facts: 5 to 9 survive each.

## Experiments for later

Exit test first, then cost in agent tasks. Section 9 of the report recomputes X1 to X5 and X7 when ratings change.

| id | question | exit test | today (stand-in) | cost |
|---|---|---|---|---|
| X1 | does Dan agree with the stand-in? | 90+ rows; weighted kappa with the rounded LLM mean 0.6 or more | needs Dan | Dan 2 h |
| X2 | flags before the cut? | on Dan's ratings, 80 percent+ of the 42 flagged rows rated 0; at most 1 rated 2+ and true | passes, rounds 2 and 3 (88 percent; 0) | 1: a `closure.py` copy writing to `data/stress/07/` |
| X3 | path_min instead of ends-min? | path_min AUC 0.05 above ends-min, both targets | fails, rounds 2 and 3 | 0 |
| X4 | is the cut stable to one row? | demoting any one worth-showing row moves the exact scorer T by under 0.25 | round 2 passes; round 3 fails (to 3.78) | 0 |
| X5 | does IC separate trivia? | AUC of IC for "not trivial" 0.75+ | fails: 0.73, 0.70 | 0 |
| X6 | is "trivial" stable between humans? | a second human: weighted kappa with Dan 0.4+ | LLMs: Fleiss 0.77 to 0.80 | a colleague, 2 h |
| X7 | is the stand-in stable run to run? | weighted kappa 0.8+ with round 2 per rater, and the same exact scorer interval | **done: fails** (kappa passes; interval moves) | done |
| X8 | can ontology distance cover more facts? | defined for 80+ of 100 rows; AUC 0.75+ on Dan's ratings | 0.70 to 0.83 on 38 rows | 2 |
| X9 | does a learned ranker (H) beat one score? | ordinal model, 6 features; leave-one-out AUC 0.05 above IC and 0.75+ (after X1, X6) | n/a | 1 to 2 |
| X10 | can the unjudged be scored? | IC for PR, PO, MONDO, PATO, SO, NCBITaxon (a copy of `scripts/ontology/ic.py` writing to `data/stress/07/`); unjudged from 280 to under 50 | n/a | 1 to 2 |
| X11 | can a check catch false facts (with program 01)? | flags 7+ of the 13 false rows, and at most 2 of the 71 rows all round-3 raters call true | IC: 6 of 13 kept; belief: 9 of 13 at 0.80 | 2 |
| X12 | do false level-3 examples steer "interesting" to "false"? | a round with true level-3 examples: 3+ rows interesting and true | weakened: round 3 already has 4. Low priority | 4 |
| X13 | can a named term list replace T? (K) | Dan marks the 9 terms in item 4 as hub or not; the list does at least as well as 2.5 on trivial and worth-showing rows | n/a | Dan 10 min; 1 |
| X14 | are the facts 2.4 would add sound? (review) | read all 28 closure facts scored 2.4 to 2.5 against the GO and UBERON graphs; if 9+ are false as universals, rule out 2.4 | sheet: 3 of 6 false | 1 |

## What would change the decision

| if Dan's ratings show | then |
|---|---|
| his plateau contains 2.5 | keep 2.5, as the six-rating pool says |
| his plateau excludes 2.5, contains 2.4 | run X14 first. 2.4 adds 28 closure facts, 24 about the endomembrane system; 3 of the 6 sheet rows there are false |
| R031 and R089 rated below 2 | the ceiling lifts; test a cut near 3.8 |
| X4 fails on his ratings too | stop tuning T on ratings; name the terms (X13) or rank (G) |
| X2 passes | put C2 before A (round 3: 48 of 53 trivial rows go, none worth showing lost) |
| AUC of IC for "not trivial" under 0.65 | IC is the wrong axis: C2 plus ranking (G) |
| X3 passes | switch A to B |
| X1 or X6 fails | LLM stand-ins cannot pre-screen, or "trivial" is ill-defined: rank and fold only (G) |
| in every case | a truth check apart from IC and belief (X11, program 01): 6 of 13 false rows pass the cut; 9 of 13 keep full belief |

J would need a reason to make interest part of belief. I see none, and on the sheet they run opposite ways (L).

Roadmap: M8 (literature at scale) needs a filter between the closure and a human; C2+A is the best measured. M5
(ontologies as biolib) supplies the "entailed" flag. Program 01's false universals are the facts this sheet calls
"surprising".

## Limits

- **The ratings are LLM stand-ins**: three a round, probably one model. Their agreement is not human agreement.
- **One round is not enough.** Round 2's headline and its priming story did not survive round 3. One round of 100
  ratings moves the cut by a term. Dan's single round has the same limit; X6 is the remedy.
- Only 3 to 7 rows are worth showing, so every curve is coarse.
- The band (2.28 to 2.66) rests on 21 rows at five terms. It says nothing about terms off the sheet.
- The rubric defines restatements and weakenings as 0, so C2's success is partly built in.
- The checked source treats R020, R031 and R089 alike ("depends"); the LLM pool does not. The plateau's ceiling rests
  on that split.
- 20 rows have a checked source; other truth calls are the raters'. Three were changed by the reviewer, not a domain
  expert: each is one line in `SOURCE_TRUTH` in `ic_analysis.py`, for Dan to overrule. Closure-weighted numbers rest
  on 6 to 12 rows per stratum.
- No Lean file, by design: nothing here is in the core.

## Files

| path | what |
|---|---|
| `scripts/stress/ic_analysis.py` | the analysis; 59 case and 75 headline pins. Reads `rating_dan.tsv` or `.csv`; `--dan FILE --out DIR` for tests |
| `scripts/stress/ic_verify_round3.py` | live check of every CURIE and reference in this doc (`python3 -I`); writes `verify_round3_*.tsv` |
| `scripts/stress/ic_review3_check.py` | the review's independent check: exact surname and year, every title word; CURIEs in the doc, `SOURCES` and `sheet_cases.tsv`; QuickGO taxon constraint. Writes `review3_*.tsv` |
| `data/stress/07/analysis_*`, `sheet_cases.tsv` | outputs of `ic_analysis.py`, round 3 |
| `data/stress/07/rating_llm_1..3.tsv` | round-3 ratings, with each rater's notes |
| `data/stress/07/round2/`, `round1_primed/` | earlier rounds: ratings and outputs (round 2 copied from git 6441d2f) |
| other `scripts/stress/ic_*.py` | earlier steps; `ic_cases.py` re-run 2026-10-31, output byte-identical |

Rerun: `python3 scripts/stress/ic_cases.py && python3 scripts/stress/ic_analysis.py`. Both are deterministic: two hash
seeds gave byte-identical files.

## References (checked)

All match on Crossref or Europe PMC on title, first author and year, checked live on 2026-10-31 twice
(`verify_round3_refs.tsv`; the review's stricter `review3_refs.tsv`). The review read the abstracts of the six papers
used for rows, and of London 2013, Stork 2008 and Xu 2006 (cited in `cases.tsv`): each supports its use.

| ref | used for | id |
|---|---|---|
| Resnik 1999, "Semantic similarity in a taxonomy", J Artif Intell Res | IC; F | doi:10.1613/jair.514 |
| Sánchez 2011, "Ontology-based information content computation", Knowl-Based Syst | IC | doi:10.1016/j.knosys.2010.10.001 |
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
| Hanley 1982, "The meaning and use of the area under a receiver operating characteristic (ROC) curve", Radiology | AUC | doi:10.1148/radiology.143.1.7063747 |
| Efron 1979, "Bootstrap methods: another look at the jackknife", Ann Stat | intervals | doi:10.1214/aos/1176344552 |
| Sigel 2012, "Structure, function, and modulation of GABA(A) receptors", J Biol Chem | R004 | PMID:23038269 |
| Jones 2024, "Conserved 5-methyluridine tRNA modification modulates ribosome translocation", PNAS | R008 | PMID:39159370 |
| Haase 2013, "Regulation of erythropoiesis by hypoxia-inducible factors", Blood Rev | R020 | PMID:23291219 |
| Mattiroli 2017, "Structure of histone-based chromatin in Archaea", Science | R070 | PMID:28798133 |
| Dibrova 2014, "Phylogenomic reconstruction of archaeal fatty acid metabolism", Environ Microbiol | R088 | PMID:24818264 |
| Li 2025, "Archaeal lipids: extraction, separation, and identification via natural product chemistry perspective", Int J Mol Sci | R088 | PMID:40243902 |

CURIEs: all 98 in this doc, the `SOURCES` text and `sheet_cases.tsv` found live on OLS4 (`review3_curies.tsv`);
CL:0000548 is obsolete, as the sheet says. GO graph facts are from `go.obo` 2026-07-26 (the release behind `ic.json`);
UBERON's from `uberon.obo` 2026-10-01. QuickGO: GO:0000785 is only in cellular organisms (NCBITaxon:131567). Every
textbook sentence quoted here or in `SOURCES` matches `data/textbook/claims*` word for word.

## UNVERIFIED

- Resnik 1995 (IJCAI): not on Crossref; Resnik 1999 is cited instead.
- Which model the LLM raters ran on, and that they were blind: both rest on their own notes.
- The rubric's example levels, the old 42 labels and all ratings: LLM judgements, not facts.
- The truth of rows outside the 20 with a checked source.
- UBERON's OWL axioms beyond `uberon.obo`: not loaded.

## What changed on 2026-10-31

- Round 3 rated the sheet. Round 2 is kept in `round2/` (copied from git); the live `rating_llm_*.tsv` are round 3.
- Retracted from round 2: "use 2.4, not 2.5", "no single row moves the cut", "91 percent of resamples agree", "the
  first-draft rubric primed round 1". "All interesting rows are false or unsure" holds in round 2 and the pool, not
  in round 3: borderline.
- Added: the plateau, three rounds, the six-rating pool, X7 (run), X13, the fragility test. R070 and R088 changed.
- Review: three truth calls (R020, R021, R098); pinned the core's belief, FAIL by kind, the cut on its own job, the
  2.4 to 2.5 rows, both ceiling rows demoted, and three figures once quoted unpinned from `ic_alternatives.py`;
  options K and L; X14. Pins: 59 case, 75 headline (round 2's are in git 6441d2f).
