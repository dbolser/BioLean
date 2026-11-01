# Program 02b: loops as claims, pushed to the textbook

Written 2026-11-01. Follow-up to decision 2 (Dan, 2026-10-29: a feedback loop is a claim in its own
right, `Claim.homeostasis regulator held`; no dynamics). A program of work, not a decision. Nothing
in the core changed. Dan decides at the points in section 8.

Files:

| file | what | run time |
|---|---|---|
| `BioLean/Stress/Feedback.lean` | 44 cases on today's core and the compiled textbook (R2, R3); 82 pins | about 6 s |
| `BioLean/Proto/Feedback.lean` | prototypes: loop sign, several regulators, set point, loop-aware reading, `close`, `closeT`, arm check; 59 pins | about 6 s |
| `scripts/stress/closure_loops.py` | copy of `scripts/search/closure.py` with asserted loops; writes only `data/stress/02b/` | under 1 s per mode |
| `data/stress/02b/homeostasis_m3.json` | the round-3 proposal for every loop sentence (not applied to `claims_m3`) | |
| `data/stress/02b/cases.tsv` | the 56 cases, observed lines, marks, tests, sources | |
| `data/stress/02b/scripts/` | `make_proposal.py`, `run_closure.sh` (11 modes, 62 pins), `cases.py`, `ols_check.py`, `refs_check.py`, `review_*.py` | |
| `data/stress/02b/curies.tsv`, `refs.tsv` | 133 CURIEs on OLS4 plus 4 placeholders; 48 papers on Europe PMC or Crossref | |

## Summary

- **What I did.** Wrote round-3 annotations for all 85 textbook sentences that state a loop,
  homeostasis or a set point. Built 56 stress cases: 44 in Lean (28 on textbook sentences, 13 on
  papers only, 3 synthetic) and 12 on the closure. Ran prototypes of every option and a loop-aware
  copy of the closure. A second review re-ran everything and fixed 14 problems (section 12).
- **Today: 15 PASS, 15 FAIL, 14 SILENT, 12 INEXPRESSIBLE.** The main FAIL: going once round a
  negative loop derives "glucose lowers blood glucose" at belief 0.64, the same strength as a right
  two-step chain (7 Lean cases, 2 in the closure). `Claim.homeostasis` also accepts a positive loop
  (oxytocin) and a loop with no arms, as it has no sign and no check.
- **Annotating loops makes the closure worse unless it reads them.** With the proposal, flagged
  chains rise from 98 to 125 and sign clashes from 47 to 61. With the loop reading (outside the
  core), 66 chains are reported as the loop they go round, and 58 of 61 sign clashes have a side
  that is a round trip. That is weaker than it sounds: the other side stays an effect, and it can be
  the wrong one (C09 kept, C11 hidden).
- **Prototypes: 34 PASS, 5 FAIL, 1 INEXPRESSIBLE of 40 run.** The FAILs: adrenaline raises insulin
  (twice), a context error, and two cycles with no asserted loop. A label does not fix them. A
  stricter rule fixes one mislabel (P03), but needs loops with several regulators.
- **Side findings.** The closure misses 96 derived effects (a search gap). With both gaps fixed, 6
  sign clashes stay unexplained, not 3. Round 3 has two errors on loop sentences (-m45534-77, -153);
  two book statements are contested (calcitonin -134, T3 in -263).
- **What matters now.** Keep `Claim.homeostasis`. Put the reading and the loop blocks (sign,
  regulators) outside the core. But no option keeps the docstring's promise that rules "must not
  chain an effect through" a loop: the reading changes reports, not proofs. The one core change worth
  deciding is a loop sign with a regulator list (B, C).

## Words used here

| word | meaning here |
|---|---|
| loop | a cycle of signed effects that returns to where it started: glucose raises insulin, insulin lowers glucose |
| arm | one effect of a loop ("glucose raises insulin") |
| negative / positive loop | the product of the arm signs is negative (pushes back) or positive (amplifies) |
| homeostatic | a negative loop that holds a variable near a set point. Not every negative loop is (antibodies clear a virus) |
| set point | the value a homeostatic loop defends (37 °C). Fever moves it |
| round trip | a derivation that goes once (or more) round a loop and concludes "x lowers x" or "x raises x" |
| crosses | a derivation uses an arm of a loop but does not go round it |
| cycle | a round trip with no asserted loop to name it |
| explained clash | a sign clash ("a raises t" and "a lowers t") where one side is a round trip. It says nothing about whether the other side is right |
| asserted loop | a loop stated as a claim (`Claim.homeostasis`) or as a loop block in data |
| loop block | the proposal's record outside the core: sign (TEDDY term), held, regulators with directions |
| base curie | a CURIE with its context stripped: `CHEBI:17234` for glucose in blood |
| core | `BioLean/*.lean`: `Claim`, `Derivation`, `Opinion`, `Entity`. A core change means a new constructor, rule, operator or type |
| closure | `scripts/search/closure.py`, which forward-chains the textbook statements |

Sentence ids are shortened: -52 is `the-body-s-systems-m45537-52` unless another module is named (-m45534-77).

## 1. The question

Decision 2 named the loop. It did not say how the loop is used. Three questions follow.

1. Which textbook sentences state a loop, and what claims should they become?
2. Where does `Claim.homeostasis regulator held` get the biology right, where wrong, and what can
   it not hold? (sign, several regulators, set point, time scale)
3. How should the closure use asserted loops? The decision says a chain that crosses a loop is
   labelled with it, and "x lowers x" through a negative loop is reported as the loop, not as an effect.

No dynamics: gain, delay and stability are left to ODE models (BioModels).

## 2. What the textbook says

`data/stress/02b/homeostasis_m3.json`, built by `make_proposal.py`. Every sentence matching
feedback, homeosta, set point, thermostat or equilibrium point (41), plus 44 loop descriptions found
by reading the chapters ("When blood-glucose levels rise, beta cells release insulin"). The counts
match the brief: "negative feedback" 5, "positive feedback" 1, "homeosta" 16, "set point" 10.

| action | records | what |
|---|---:|---|
| keep | 65 | current annotation is right for this program (most arms are already effects) |
| replace | 22 | new m3 annotation: 13 become `homeostasis`, 9 are fixed arms |
| add | 16 | new record from the same sentence (`~loop`, `#2`): 13 loop claims or second regulators, 3 arms |
| none | 71 | stays unannotated, blocker named |

Result: 26 `homeostasis` claims and 12 new or fixed arms. All 38 compile
(`data/stress/02b/proposal_check.lean`). 19 records also carry a loop block with a sign.

Why 71 stay `none`:

| blocker | n | example |
|---|---:|---|
| class_level_loop | 17 | "rising levels of a hormone inhibit its further release" (-269): every hormone, a bound variable |
| definition_only | 14 | "set point: the target value of a physiological state" (-m45534-232) |
| ungrounded_entity | 12 | "a sensor that detects a deviation" (-m45534-214) |
| other | 10 | "When homeostatic mechanisms fail, the results can be unfavorable" |
| process_description | 7 | "keep the body in dynamic equilibrium by constantly adjusting" |
| set_point_shift | 3 | "pyrogens ... resetting the thermostat to a higher value" (-m45534-85) |
| disjunction | 2 | "vasodilation or vasoconstriction and shivering or sweating" (-m45534-78, -79) |
| not_homeostasis | 2 | cortex to thalamus "feedback" (-m45539-231, -232) |
| set_point_no_value, signless_regulation, positive_loop, sequence | 1 each | "within a normal range" (-55); "aldosterone, which regulates the concentration of ions" (-150); the one positive-feedback sentence (-m45539-88) |

Three things the proposal shows:

- **Most arms were already annotated (65 keep).** Of the 71 `none` records, 23 need something the
  core lacks (class-level loops, set point shifts, sign, positive loops).
- **Two fixes are errors in round 3, not missing schema.** -m45534-77 "The hypothalamus maintains
  the set point for body temperature" compiles as "hypothalamus (located in hypothalamus) raises
  environmental temperature" (case L05). -153 lost "blood" on sodium (case C12).
- **Two regulators need two core claims.** -333 "regulated by ... insulin and glucagon" becomes
  two `homeostasis` claims; the pairing and directions live only in the loop block (T01).

## 3. The options

| option | idea | core change? | needs | right | wrong |
|---|---|---|---|---|---|
| (A) as decided | `Claim.homeostasis regulator held`; arms are effects | none | annotations (section 2) | names the loop; 26 textbook claims compile; the L04 calcitonin dispute works by plain fusion | no sign (P01 accepts a positive loop); one regulator per claim (T01, T02); nothing uses the claim; no check against arms (X01, X02) |
| (B) loop sign | a sign field, TEDDY:0000034 negative or TEDDY:0000035 positive feedback loop | yes: a field on `Claim.homeostasis`, or a new `Claim.loop` | the sign in each annotation (the proposal has it) | positive loops become statable (P01, P04, C07); a sign check is possible (X02) | a negative sign is not homeostasis (N02); Thomas 1998: a negative circuit is needed, not enough |
| (C) several regulators | regulators as a list, each with the sign of its arm on the held variable | yes: same constructor change as (B) | the directions (the proposal has them) | T01, T02 as one loop; with it the strict reading keeps all 124 round trips (signed + complete); without it, core mode loses 6 | effectors are not regulators (T03); the LH switch (P06) still needs a condition |
| (D1) set point as data | a loop block points to a `Claim.measure` statement | none | measure statements | S01: 37 °C tied to its loop | most book set points have no number (-55 "within a normal range") |
| (D2) set point in the core | `shiftsSetPoint agent sign loop` | yes: a new Claim constructor | (B) or a loop id | fever (S02), heat stroke vs fever (S03), threshold shift (T04) become different claims | set points drift (Protsiv 2020) and are argued about (Cabanac 2006); 3 book sentences are blocked on it |
| (E) loop-aware reading | a chain that crosses an asserted loop is labelled; a round trip is reported as the loop | none (library function; closure flag). It changes reports, not proofs: `L01_established` still holds | asserted loops | 10 Lean and 66 closure round trips named; clashes with no round-trip side 61 to 3 (6 with both gaps fixed) | leaves wrong chains across a loop (N04, C09, C12); can keep the wrong side of a clash (C09); P03 mislabelled |
| (E') strict reading | (E), but every node on the cycle must be a node of the loop | none | (C) to keep all round trips | fixes P03 | without (C), 6 textbook round trips through both insulin and glucagon fall to "cycle" |
| (F) close a loop | a Derivation rule: two arms that end on each other's agent give a loop of sign s1 * s2 | yes: a new Derivation rule, and the claim of (B) | (B) | the loop is derived, not asserted; X02's arms disagree with its claim; two negative arms give a positive loop (P08). `closeT` is kernel-checked (unification plus an is_a premise) | concludes a loop, never homeostasis. The base-curie `close` puts no condition in its type; only `closeT` is fit for the core |
| (G) block round trips | a side condition on `viaAmount`/`viaActivity`: no revisits | yes: changes two Derivation rules | nothing | stops L01, L10 | also stops true positive loops (P02, P04, P08) and leaves N04 alone. Rejected |
| (G') block round trips through an asserted loop | as (G), but only where an asserted negative loop covers the revisit | yes: `Derivation` gets an index, the asserted loops | asserted loops ((A) claims count as negative) | the only option that makes the core keep the `Claim.homeostasis` docstring | non-monotone: asserting a loop removes proofs. Not prototyped |
| (H) dynamics | ODE or qualitative simulation (Kuipers 1986, Forbus 1984) | a new layer | rate laws | time scale (L07, T05), asymmetry (L17), order (P03), the LH switch (P06) | out of scope by decision 2. Not prototyped |

Vocabularies checked: GO has the processes (GO:0042592 homeostatic process, GO:0042593 glucose
homeostasis, GO:0003025 baroreceptor feedback) but no loop object with a sign. TEDDY has
"negative feedback loop" and "positive feedback loop" (Courtot 2011). RO:0002211 "regulates" takes
processes only, so it cannot hold aldosterone's "regulates the concentration of ions" (L16).

## 4. The stress set

56 cases. Inputs with CURIEs, correct conclusion, observed line, tests and sources are in
`data/stress/02b/cases.tsv`, written by `cases.py` from live runs. Groups: L negative, P positive,
T regulators and time scales, S set points, N look-alikes, X synthetic, C closure. "not run": no
option targets the case.

| id | probe | today | prototype |
|---|---|---|---|
| L01 | glucose and insulin: going once round | FAIL | PASS (E) |
| L02 | glucose and glucagon, through a refinement edge | FAIL | PASS (E) |
| L03 | calcium and PTH | FAIL | PASS (E) |
| L04 | calcitonin: book loop, disputed (Hirsch 2001) | PASS | not run |
| L05 | thermoregulation as compiled in R3 (-m45534-77) | FAIL | PASS (proposal) |
| L06 | ADH and osmolality: the loop closes through a process | PASS | not run |
| L07 | blood pressure: seconds (baroreflex) and days (kidney) | INEXPRESSIBLE | not run |
| L08 | thyroid axis: the negative arm has no Lean | SILENT | PASS (E) |
| L09 | goiter raises TSH through the loop (Chopra 1975) | PASS | not run |
| L10 | cortisol axis: a three-step round trip | FAIL | PASS (E) |
| L11 | dexamethasone suppression | PASS | PASS (E) |
| L12 | EPO and oxygen: the return arm is a process | PASS | not run |
| L13 | breathing and CO2 | SILENT | not run |
| L14 | stomata and leaf water | SILENT | not run |
| L15 | ANP and blood volume | SILENT | PASS (E) |
| L16 | aldosterone "regulates the concentration of ions": a signless arm | INEXPRESSIBLE | not run |
| L17 | leptin: a loop that mostly defends one direction | FAIL | PASS (E) |
| L18 | end-product inhibition (isoleucine, E. coli) | FAIL | PASS (E') |
| L19 | energy charge: the held quantity is a ratio | INEXPRESSIBLE | not run |
| P01 | oxytocin in labour stated as homeostasis | FAIL | PASS (B) |
| P02 | thrombin and factor V: amplification | PASS | PASS (E) |
| P03 | thrombin's protein C brake on the same node | FAIL | FAIL (E); PASS (E') |
| P04 | action potential sodium channels | PASS | PASS (E) |
| P05 | the potassium arm that ends the spike | SILENT | not run |
| P06 | estradiol and the LH surge: an arm changes sign | INEXPRESSIBLE | INEXPRESSIBLE |
| P07 | ethylene in ripening: return arm is structural | SILENT | not run |
| P08 | toggle switch: a positive loop of two negative arms (Gardner 2000) | PASS | PASS (E, F) |
| T01 | insulin and glucagon: one loop, two regulators | INEXPRESSIBLE | PASS (C) |
| T02 | PTH and calcitonin | INEXPRESSIBLE | PASS (C) |
| T03 | several effectors of thermoregulation | INEXPRESSIBLE | not run |
| T04 | hypovolaemia lowers the ADH threshold | INEXPRESSIBLE | PASS (D2) |
| T05 | receptor down-regulation: a slow loop on the gain | INEXPRESSIBLE | not run |
| S01 | the set point as a measure (37 °C) | INEXPRESSIBLE | PASS (D1) |
| S02 | fever: pyrogens move the set point | INEXPRESSIBLE | PASS (D2) |
| S03 | heat stroke looks like fever | INEXPRESSIBLE | PASS (D2) |
| N01 | sympathetic and parasympathetic: no loop | PASS | not run |
| N02 | antibodies and virus: negative, not homeostasis | FAIL | FAIL (E) |
| N03 | "feedback" from cortex to thalamus | PASS | not run |
| N04 | adrenaline raises glucose, so "raises insulin" | FAIL | FAIL (E) |
| N05 | glucagon raises glucose, so "raises insulin" | PASS | PASS (E) |
| N06 | cephalic insulin: feed-forward | PASS | not run |
| X01 | SYNTHETIC: a loop claim with no arms | SILENT | PASS (E5 arm check) |
| X02 | SYNTHETIC: a loop claim whose arms make a positive loop | SILENT | PASS (B, F) |
| X03 | SYNTHETIC: a chain through the loop variable, no arm | PASS | PASS (E) |
| C01 | closure: the glucose round trip | FAIL | PASS (E) |
| C02 | closure: "glucose lowers insulin", a 1.5-turn sign clash | FAIL | PASS (E) |
| C03 | closure: antibodies cycle, no asserted loop | FAIL | FAIL (E) |
| C04 | closure: lungs lower EPO, crosses a loop, right | PASS | PASS (E) |
| C05 | closure: goiter and metabolism, a clash the sources do not settle | SILENT | PASS (E) |
| C06 | closure: food intake lowers food intake (reflexive) | SILENT | PASS (E) |
| C07 | closure: depolarisation raises depolarisation | SILENT | PASS (B+E) |
| C08 | closure: sodium channels raise depolarisation | PASS | PASS (E) |
| C09 | closure: adrenaline raises insulin, unreachable today | SILENT | FAIL (E) |
| C10 | closure: glucagon raises insulin, unreachable today | SILENT | PASS (E) |
| C11 | closure: adrenaline lowers insulin, only by winding | SILENT | PASS (E) |
| C12 | closure: neuronal Na+ read as blood Na+ | FAIL | FAIL (E) |

The mark rule for round trips. Once round a negative loop gives "x lowers x". As a net effect that
is false: more glucose does not lower blood glucose; the loop only pushes back. So it is FAIL as an
effect. Once round a positive loop gives "x raises x", which is true (amplification), so PASS. A
sign clash the sources do not settle (C05) is PASS when it is reported, not resolved.

## 5. How the closure should use asserted loops

The specification, as built in `closure_loops.py --loops` and `classify` / `classifyStrict` in
`Proto/Feedback.lean`. All of it lives outside the core.

1. **Loops.** One asserted loop per `homeostasis` record, nodes {regulator, held}, merged when the
   node sets are equal (core mode). Or one per loop block: held, every regulator, extra nodes, sign
   (signed mode). Nodes are base curies, as the closure's feedback guard already does.
2. **Crosses.** A derived effect whose effect premises include an arm of loop L (both ends nodes
   of L) crosses L. It stays an effect and is labelled with L.
3. **Round trip.** A derived effect whose base-curie path revisits a node is a round trip of L if
   it crosses L and every node from the first to the last revisit is a node of L (strict; the loose
   rule asks this of the revisited nodes only). It is reported as L, not as an effect.
4. **Reflexive.** An exactly reflexive "a lowers a" is read by the same rule. Today the closure
   drops it silently.
5. **Cycle.** A revisit no asserted loop covers stays a flagged effect, labelled "cycle". It is
   never called homeostasis.
6. **Sign clashes.** A clash with a round-trip side is explained by the loop. The rest are reported.
   Explained means only that: the other side stays an effect and is not checked (see 6.3).
7. **Positive loops.** Round trips of a positive loop are reported as the loop too (they are true
   as effects, but the loop is the better report). Only possible in signed mode.

Not specified: what "reported as the loop" does downstream (holes, IC ranking, Lean emission).
The copy only reads and counts.

## 6. Results observed

### 6.1 Today's core (Lean, 44 cases)

| mark | n | cases |
|---|---:|---|
| PASS | 13 | L04, L06, L09, L11, L12, P02, P04, P08, N01, N03, N05, N06, X03 |
| FAIL | 11 | L01, L02, L03, L05, L10, L17, L18, P01, P03, N02, N04 |
| SILENT | 8 | L08, L13, L14, L15, P05, P07, X01, X02 (L08 and L15 become FAIL once the proposal's arms exist) |
| INEXPRESSIBLE | 12 | L07, L16, L19, P06, T01 to T05, S01 to S03 |

What the runs show:

- **Round trips look like any chain.** L01 "glucose lowers blood glucose" has belief 0.64:
  `Established` at 3/5 (`L01_established`), default verdict `unsupported`. The right chain N05 gets
  exactly the same. L10 (three steps) 0.216; L17 (exactly reflexive) 0.64.
- **The core breaks its own docstring.** `Claim.homeostasis` says rules "must not chain an effect
  through" a loop. `viaAmount` does, and asserting the loop (L01_loop) changes nothing.
- **The core is often right.** Chains through a loop variable: goiter raises TSH (L09),
  dexamethasone lowers cortisol (L11), glucagon raises insulin (N05). Positive round trips (P02,
  P04), including two negative arms (P08: neg * neg = pos). Calcitonin by plain fusion: textbook
  alone `established`, with Hirsch 2001 `unsupported` (b 0.615, d 0.23).
- **Processes stop loops closing.** ADH (L06), EPO (L12), breathing (L13) and the potassium arm
  (P05) end on a process, and no rule chains a process. This hides the loop and the round trip.
- **What `homeostasis` cannot hold, pinned** (`homeoFields` has the constructor's exact arity): no
  sign (P01 at 0.7), one regulator (T01, T02), no set point (S01) or shift (S02, S03, T04), no time
  scale (L07, T05), no ratio (L19), no effectors (T03), no sign switch (P06).
- **Same shape, different biology.** Fever and heat stroke are both "x raises body temperature"
  (S03); one moved the set point, the other overwhelms the loop (Biddle 2006).

### 6.2 Prototypes (Lean)

| prototype | what it showed |
|---|---|
| `Loop` with sign, regulators, set point | P01, T01, T02, S01 stated; `toCore` maps a loop to today's claims and loses the sign and directions |
| `shiftsSetPoint` | fever, heat stroke and the ADH threshold become different claims (S02, S03, T04) |
| `classify` (E) | 10 round trips named, 3 crossings labelled, N02 a cycle, X03 plain. N04 still derives "adrenaline raises insulin", now labelled |
| `classifyStrict` (E') | P03: the loose rule reports thrombin's negative protein C round trip as the positive loop `thrombin+`; strict reports a cycle, and the protein C loop once asserted. Keeps the other 10 |
| `close` (F) | glucose arms: a negative loop at 0.8; thrombin arms and the toggle's two negative arms: positive loops. X02's built loop disagrees with X02's claim. Unrelated arms also build a "loop" (the check is a separate Bool) |
| `closeT` (F, kernel) | the glucose loop from -52, -53 and "blood glucose is_a glucose", linked by unification; unrelated arms fail to typecheck (pinned) |
| `armsFor` (E5 lint) | finds 0 textbook arm pairs behind X01 ("insulin holds blood calcium"), 2 behind the insulin loop, 1 behind PTH; X02's arms give (pos, pos) |
| `blockedByG` (G) | blocks L01 and L10 (false) and P02, P04 and P08 (true) alike; misses N04 |

### 6.3 The closure on the textbook

`run_closure.sh` runs 11 modes. Base mode reproduces the original byte for byte (report and all
three JSON files, checked by diff in the same run). Numbers, from the reports:

| mode | derived effects | flagged | round trips | crosses | cycles | sign clashes (explained) |
|---|---:|---:|---:|---:|---:|---:|
| base (= original) | 363 | 98 | - | - | - | 47 |
| core: proposal + loops | 402 | 125 | 66 | 94 | 3 | 61 (58) |
| signed: loop blocks | 402 | 125 | 66 | 112 | 3 | 61 (58) |
| core, strict | 402 | 125 | 60 | 94 | 9 | 61 (58) |
| complete (no proposal) | 459 | 168 | - | - | - | 92 |
| signed + complete | 508 | 203 | 124 | 142 | 3 | 112 (109) |
| signed + complete, strict | 508 | 203 | 124 | 142 | 3 | 112 (109) |
| signed + complete + isa | 510 | 204 | 123 | 144 | 4 | 114 (108) |

- **The proposal alone makes it worse.** 12 new arms add 39 derived effects and 27 flagged chains.
- **The reading sorts the 125 flagged:** 66 round trips (reported as the loop), 51 crossings (kept,
  labelled), 3 cycles, 5 touching only the positive action-potential loop (labelled in signed mode).
- **Explained is not resolved.** The side of an explained clash that is not a round trip stays an
  effect. In core mode the 58 kept sides are 35 chains across a loop, 12 book statements, 8 where
  both sides are round trips, 3 plain. The 35 are the N04 kind, not checked by hand. C09 and C11
  show the bad case: the wrong side is kept, the right one hidden as a loop.
- **3 clashes left; 6 with both gaps fixed.** Antibodies (two, C03) and goiter and metabolism
  (C05: the book gives both signs, the source does not settle it, so reporting it is right).
  `--complete-isa` adds anterior pituitary against T3 and metabolism, and a third antibodies one.
- **Strict needs several regulators.** In core mode strict loses 6 round trips, each through both
  insulin and glucagon (each core loop has one). In signed mode it loses none.
- **Reflexive effects.** The original silently drops 17 "a raises a" or "a lowers a" effects. With
  loops, 18 of 20 are read as round trips (core), 24 of 26 (signed + complete).
- **The closure misses 96 effects.** A new effect fact is only extended as the first premise of
  `viaAmount`/`viaActivity`. `--complete` adds the second: 363 to 459 effects, 47 to 92 clashes. It
  hid right chains (C10) and wrong ones (C09). A second gap (`isaInheritEffect` never fed by a new
  effect) adds 1 more (`--complete-isa`, 460).

### 6.4 Things found on the way

| finding | where | for |
|---|---|---|
| -m45534-77 compiles as "hypothalamus (located in hypothalamus) raises environmental temperature" | L05 | round-3 fix (in the proposal) |
| -153 sodium lost its blood context, so neuronal depolarisation "lowers aldosterone" | C12 | program 04 (annotation errors) |
| -263 says goiter stops T3 and T4 forming; in iodine deficiency serum T4 is subnormal but T3 supranormal, and neither TSH nor T3 differs by goiter status (Chopra 1975) | L09, C05 | contested for T3 (the T4 half holds) |
| -134/-135 calcitonin lowers blood calcium; not accepted as physiological in mammals (Hirsch 2001) | L04 | contested, not false |
| PR has no thrombin class; prothrombin PR:000007299 stands in | P02, P03 | label mismatch, stated |

## 7. Experiments for later

Each has its exit test first, then the cost in agent tasks.

| id | experiment | exit test | cost |
|---|---|---|---|
| E1 | Port the loop reading (rules 1 to 7, strict) into `scripts/search/closure.py` behind a flag | `closure_expect_core.json` and `_strict` pins reproduce on `data/search`; no PASS case flips; at most 3 unexplained sign clashes (6 once E2 is in) | 1 |
| E2 | Fix the closure's search gap (`--complete`, `--complete-isa`) in the original | `emit_closure_lean.py` certifies the new derivations; C09 and C10 move from SILENT; the 6 unexplained clashes of `signed_complete_isa` are listed | 1 |
| E3 | Apply the proposal to `claims_m3` and regenerate R3 (needs Dan's OK: it edits shared data) | the 26 `homeostasis` claims and 12 arms compile in `TextbookClaimsR3`; the `#fb_no_lean` pins for -258, -260, -226, -254, -333, -m45536-30, -31 break; L08 and L15 move to FAIL in the core, PASS in the reading | 2 |
| E4 | Prototype (B)+(C) as a core change on a scratch copy of `Claim.lean` | only the arity pins (`shape`, `homeoFields`) and P01, T01, T02, X02 change; every library still compiles | 2 |
| E5 | A loop-sign lint outside the core: asserted loop sign against the product of its stated arms (`armsFor` is the prototype) | X01 and X02 flagged; all 19 proposal loop blocks pass | 1 |
| E6 | Set points as data (D1): a `set_point` field in loop blocks pointing to measure statements | S01 attached; -55 recorded as a set point with no value | 1 |
| E7 | Time scale as context: PATO:0000389 acute and PATO:0001863 chronic as an organism condition (has_modifier, not surrounded_by) | T05's chronic arm and an acute null do not fuse; L01 unchanged | 1 |
| E8 | Run the reading on a curated source with explicit loops (GO-CAM or Reactome) | round-trip precision reported on 20 curated loops | 2 |
| E9 | Send -m45534-77 and -153 to program 04 (annotation errors), and -263 (T3) as contested | listed there with the sources above | 1 |
| E10 | Check the kept side of every explained clash by hand (58 in core mode) | each kept side marked right or wrong with a checked source; if more than 5 are wrong, the reading must flag kept sides too, not only drop round trips | 2 |

## 8. What would change the decision

- **For (B) loop sign, a core change:** Dan wants positive loops stated as Lean claims (oxytocin,
  clotting, the action potential, ethylene). The closure does not need it: signed mode gets the same
  66 round trips from loop blocks in data.
- **For (C) regulators:** E1 shows the strict rule is needed beyond P03. Then core mode's 6 lost
  round trips argue for (C), or for keeping loop blocks in data.
- **For (D2) set points:** the second textbook (ROADMAP M7) turns out to have many set-point
  sentences with numbers (not checked yet). This book has 3 blocked on a shift, and most "set
  point" sentences are definitions.
- **For (F) close:** a use for derived loops in Lean proofs. Today no theorem needs one. If one
  does, use `closeT` (kernel-checked), not the base-curie `close`.
- **For (G'):** Dan wants the core itself to stop "glucose lowers blood glucose", as the docstring
  promises. Cost: an index on `Derivation` and non-monotone proofs. Otherwise the docstring should
  say the closure's reading enforces it, not the core.
- **Against all core changes:** if E1 and E3 together leave at most a few unexplained sign
  clashes, and E10 finds few wrong kept sides, (A) plus the reading is enough.

Dan decides: (1) whether the reading goes into the closure now (E1); (2) whether the proposal is
applied to round 3 (E3); (3) whether positive loops must be Lean claims, which is the only core
change recommended (B, with C at the same cost). (F), (D2) and (G') are core changes too, not
recommended now.

## 9. Limits

- Marks are my judgement, made after reading the observed lines. The "correct" column is the
  biology from the source named, sometimes in one sentence.
- Many prototype PASSes are by construction: I wrote the loop with both regulators (T01) or the
  shift (S02). They show the claim can be stated, not that annotators would state it.
- Literature statements are mine, from one abstract each, at the default weights.
- 6 cases (L08, L09, L13, L15, L17, S02) rest on my encodings of real sentences that have no Lean
  yet, marked SYNTHETIC in the Lean.
- Thomas 1998 and Ozbudak 2004: a negative loop is needed for homeostasis but not enough; a
  positive loop is needed for bistability but not enough. Sign is a weak predictor of behaviour.
  Sterling 2012 argues much regulation is predictive (allostasis), which feed-forward (N06) hints at.
- The reading compares base curies. "Glucose in blood" and "glucose" are one node. That is what makes
  round trips visible, and also why C12 (neuronal Na+ against blood Na+) slips through.
- The closure keeps one derivation per fact (the first found), and the reading looks only at that
  one. A fact with a second, honest derivation can still be reported as a loop.
- Missing case types: a loop whose sign depends on dose (P06 is a state), and integral feedback
  (Yi 2000, El-Samad 2002) as a case, not a citation.
- Human-specific PR terms (P01275 pro-glucagon, P01222 TSH beta) come from the textbook libraries.

## 10. References (checked)

48 papers, checked on Europe PMC (title, first author, every quote verbatim in the abstract) or
Crossref (title, author). Titles and quotes: `data/stress/02b/refs.tsv` (`refs_check.py`). The
review re-fetched all 48 fresh and checked first author and year as written below
(`review_check.py`), and the 54 quotes against the fresh abstracts.

| PMID or DOI | first author, year | used for |
|---|---|---|
| 15758481 | Hirsch 2001 | L04 |
| 30256726 | Morrison 2019 | L05, T03 |
| 14613925 | Kondo 2004 | L06, T04 |
| 22374125 | Juul 2012 | L06 |
| 18509340 | Bourque 2008 | L06 |
| 2063193 | Guyton 1991 | L07 |
| 19015490 | Benarroch 2008 | L07 |
| 27347897 | Ortiga-Carvalho 2016 | L08, L09 |
| 1117981 | Chopra 1975 | L09 |
| 27065163 | Herman 2016 | L10 |
| 16759341 | Aouizerate 2006 | L11 |
| 18334580 | Nieman 2008 | L11 |
| 21078592 | Jelkmann 2011 | L12 |
| 26335642 | Guyenet 2015 | L13 |
| 16219068 | Buckley 2005 | L14 |
| 8717038 | Ahima 1996 | L17 |
| 2005118 | Eisenstein 1991 | L18 |
| 4972613 | Atkinson 1968 | L19 |
| 12609499 | Russell 2003 | P01 |
| 20441738 | Panteleev 2010 | P02 |
| 11434702 | Hoffman 2001 | P02 |
| 12970121 | Esmon 2003 | P03 |
| 12991237 | Hodgkin 1952 | P04, P05 |
| 20237240 | Christian 2010 | P06 |
| 12324528 | Alexander 2002 | P07 |
| 11786029 | El-Samad 2002 | T02 |
| 4359334 | Gavin 1974 | T05 |
| 31908267 | Protsiv 2020 | S01 |
| 16540712 | Cabanac 2006 | S02 |
| 16617919 | Biddle 2006 | S03 |
| 5327883 | Porte 1966 | N04 |
| 4955799 | Kris 1966 | N04 |
| 6018752 | Porte 1967 | C11 |
| 10659857 | Gardner 2000 | P08 |
| 14346763 | Samols 1965 | N05 |
| 21256146 | Teff 2011 | N06 |
| 9654035 | Thomas 1998 | option F, limits |
| 14973486 | Ozbudak 2004 | limits |
| 10781070 | Yi 2000 | limits |
| 21684297 | Sterling 2012 | limits |
| 22027554 | Courtot 2011 | options |
| 3297890 | Argoud 1987 | survey |
| 17510665 | Alon 2007 | survey |
| 25723161 | Kotas 2015 | survey |
| 26628646 | Modell 2015 | survey |
| 10.1152/physrev.1929.9.3.399 | Cannon 1929 | survey |
| 10.1016/0004-3702(86)90073-1 | Kuipers 1986 | option H |
| 10.1016/0004-3702(84)90038-9 | Forbus 1984 | option H |

Textbook: OpenStax, *Concepts of Biology*, CC BY-NC-SA 4.0 (chapters as compiled in R2 and R3).
Every quoted sentence and id was checked against `data/textbook/claims*`. Ontology terms: 133
CURIEs on OLS4, none obsolete (`curies.tsv`), plus PATO:0000389 acute and PATO:0001863 chronic for
E7. Four internal placeholders, marked `BLN:`, are not ontology terms: hot_dry_day (from R3),
hot_environment, hypovolemia, sustained_high_estradiol.

## 11. UNVERIFIED

- That "antibodies lower antibodies" is false as a net effect (N02, C03). It is my reading of the
  loop; no source was sought.
- The net effect of iodine-deficiency goiter on metabolic rate (C05). Chopra 1975 shows T3 kept
  up; no paper on metabolic rate was checked. The C05 mark rests on the effect being unsettled.
- That neuronal Na+ entry has no effect on aldosterone (C12). Not checked; the mark rests on the
  two sentences being about different compartments.
- The time scales in L07 and T05 come from the abstracts quoted; no other source was checked.
- PR may have a thrombin class under another label; three OLS4 searches found none.
- Which two repressors Gardner 2000 used. P08 uses LacI and TetR as an illustrative pair; the
  abstract names none.

## 12. Second review (2026-11-01)

Every Lean file and script re-run; all numbers above are from the re-run. Fixed:

| problem | fix |
|---|---|
| "explained" clashes read as resolved; the kept side can be wrong | kept sides counted and pinned; E10 |
| signed + complete + isa run but not reported (6 clashes left, not 3) | row added; E1, E2 fixed |
| "established" in the Summary; the default verdict is `unsupported` | reworded (same belief as N05) |
| C05 called "goiter lowers metabolism" right; Chopra 1975 has T3 raised | restated as unsettled; PASS when reported |
| L09 and -263 overstated Chopra 1975 | reworded; -263 contested, not false |
| X01 pin was vacuous (an empty list); X02 pin ignored `close` | `armsFor`; X02 read off `closeX02` |
| `close` puts no condition on its arms | `closeT`, kernel-checked |
| no option keeps the docstring; no neg * neg loop | (G') added; P08 added |
| P06 used surrounded_by for an organism state | `organism` condition |
| C11's alpha receptor unsourced; two wrong case pointers; CURIE count | Porte 1967; N02, PROTO C02; 133 + 4 |
