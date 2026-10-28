# Information content as a triviality filter

Task 1c, part A. Dan's idea: a conclusion about "cell" or "organism" is trivial; one about "ribosomal
RNA" is not. Score a derived fact by how specific its least specific term is, using the ontologies' own
hierarchies instead of a hand-made hub list.

Code: `scripts/ontology/ic.py` (builds `data/search/ic.json`), `scripts/ontology/obo.py` (reader),
`scripts/search/closure.py --ic` (ranks and compares). Output: `data/search/ic_report.txt`,
`closure_ic.json`, `derivations_ic.json`.

## Short version

- It works as a coarse filter. Facts whose least specific term is "cell", "organ", "tissue",
  "organism", "cytoplasm", "neuron", "nervous system" score under 2 and are almost all vacuous.
- At threshold 2.5 it keeps 837 of the 1,551 derived facts and calls 603 trivial. 111 cannot be judged
  because one end is in an ontology we did not load (NCBITaxon, MONDO, PR, SO, ...).
- It does not find true or interesting facts. High IC is only "specific". The top of the list is
  chemistry ("ATP has part adenine") and a few effect chains through badly linked entities. About one
  in five of the high-IC facts I labelled was wrong or dubious, and IC cannot see that.
- It beats the hub list. 423 of the hub list's 1,175 survivors are IC-trivial, and the hub list
  throws away 183 facts that IC calls non-trivial (everything about ATP, DNA, glucose, the Calvin cycle).
  The hub list measures how often the textbook talks about a thing, not how general it is.
- The hub list is also unstable (below). Retiring it in favour of IC is justified on that alone.

## Method

`IC(t) = -log( (descendants(t) + 1) / N )`. Here `descendants(t) + 1` is the size of the subtree rooted
at t. N is the number of live (non-obsolete) terms in t's ontology. For GO, N is the size of t's
namespace (BP 23,974, MF 10,041, CC 4,077) because the three aspects are separate ontologies, so each
root scores 0. Other N: UBERON 15,047, CL 3,335, ChEBI 219,011.

Sources, all current: `go.obo` 2026-07-26, `uberon.obo` 2026-10-01, `cl-basic.obo` 2026-06-08,
`chebi_lite.obo` release 256 (55 MB, fetched in six seconds, so ChEBI is in).

Choices that matter:

- **Descendants follow is_a and part_of** (GO, UBERON, CL). With is_a alone, "multicellular organism"
  has 39 descendants and scores 5.96 ("specific"), and "anatomical system" scores 5.43. That is
  absurd: the body's parts hang off it by part_of. With is_a plus part_of, both score 0.00. The
  is_a-only number is kept in `ic.json` as `ic_isa`. ChEBI has no part_of so the two agree there.
- **Obsolete terms.** An obsolete term with one `replaced_by` takes the replacement's IC. This
  matters: the textbook's "animal cells" is CL:0000548, obsolete, merged into `cell`, and it appears in
  17 derived facts. Three obsolete terms have no replacement (polysome, mRNA polyadenylation, aging)
  and get no IC.
- **Score of a fact = min IC over subject and object**, only when both ends have an IC. If one end
  has none, the score is an upper bound: enough to call the fact trivial, not enough to call it
  non-trivial. Those facts are counted as "unjudged".

Coverage: the textbook claims use 1,453 CURIEs. 1,079 have an IC (GO, UBERON, CL, ChEBI). 371 are in
ontologies we did not load (NCBITaxon 60 and it is 690 MB, MONDO 53, NCIT 49, SO 42, HP 40, PATO 59,
PR 29, ...) and 3 are obsolete with no replacement. Of the 1,551 derived facts, 1,431 (92%) have both
ends scored, 116 have one end, 4 have none. Of the 1,248 asserted facts, 1,043 (84%) have both ends.

## Distribution: asserted versus derived

Number of facts by min-IC bin (both ends scored). "1 end" and "none" are the unscored remainder.

| | <1 | <2 | <3 | <4 | <5 | <6 | <7 | <8 | <9 | 9+ | 1 end | none | all | median |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| asserted | 61 | 54 | 114 | 105 | 166 | 181 | 142 | 87 | 60 | 73 | 159 | 46 | 1,248 | 5.04 |
| derived | 249 | 248 | 160 | 148 | 175 | 194 | 122 | 60 | 35 | 40 | 116 | 4 | 1,551 | 3.48 |

Derived facts are more generic than the textbook's own sentences: 497 of 1,431 scored derived facts
(35%) have min IC under 2, against 115 of 1,043 (11%) of the asserted ones. That is the closure doing
what it does: chaining up through "cells have X" and "organ has tissue" to general subjects.

## Top 25 derived facts by IC

Ties are broken by derivation depth, then alphabetically. Full ranking: `data/search/closure_ic.json`.

```
12.30  d1 viaActivity   neurotransmitters →+ amount(sodium)
12.30  d1 relTrans      ATP has part adenine
12.30  d1 relTrans      chlorophyll a is_a pigment
11.60  d1 isaInherit    ATP has part 2-deoxy-D-ribose
11.60  d1 isaInherit    adenosine monophosphate (AMP) has part 2-deoxy-D-ribose
11.60  d1 isaInherit    adenosine monophosphate (AMP) has part phosphate group
11.60  d1 relChain      peptidoglycan overlaps food
11.20  d2 relTrans      messenger RNA has part hydroxy group
11.20  d1 notRelSub     not(messenger RNA has part thymine)
11.20  d1 notRelSub     not(messenger RNA has part 2-deoxy-D-ribose)
11.20  d1 relTrans      DNA has part 2-deoxy-D-ribose
11.20  d1 relTrans      DNA has part phosphate group
11.20  d1 isaInherit    messenger RNA has part cytosine / guanine / adenine / uracil   (4 facts)
11.20  d1 isaInherit    NAD+ derives from Vitamins
10.91  d2 relTrans      AMP / DNA / ATP has part phosphorus atom                        (3 facts)
10.51  d2 isaGeneralise NAD+ derives from nutrients
10.51  d1 relTrans      peptidoglycan has part carbon atoms
10.51  d1 relTrans      potassium is_a these molecules / nutrients                      (2 facts)
10.51  d1 isaGeneralise Coenzymes derives from nutrients
```

What this shows, plainly: the top is all ChEBI. ChEBI has 219k terms, so any leaf scores near 12.3 while
the best a GO cellular-component term can reach is 8.3. IC is "fraction of its own ontology", which is
comparable for a threshold (IC 2.5 means a term and its descendants are under 8% of the ontology) but
not for the top of a ranking. Also, most of this list is textbook chemistry a student already knows
("DNA has part phosphate group"). One is junk: "peptidoglycan overlaps food" is a chain through a
loose "sugars part of food" claim. ("these molecules" is only the display label for cofactor,
CHEBI:23357, taken from the first sentence that mentioned it.)

Top derived facts with no ChEBI term, which is more representative of the biology:

```
8.70  d1 viaAmount        food intake →+ process(sense of satiety or fullness)
8.52  d2 isaInherit       superior vena cava connected to inferior vena cava
8.52  d1 isaInherit       inferior vena cava has part valves
8.31  d1 viaAmount        ATP synthase →+ process(glycogen biosynthetic process)
8.29  d1 viaAmount        "broken down" [GO:0006007] →− process(ATP biosynthetic process)
8.01  d1 relTrans         prophase part of mitotic phase
```

Only the prophase fact is plainly right (transitivity of part_of). The vena cava connection is
wrong: the textbook says blood vessels are connected to the inferior vena cava, and the `isaInherit`
rule hands that to every kind of blood vessel, including the superior vena cava. That is the same
existential-read-as-universal flaw that gave "cells have cell walls". The effect chains (ATP synthase
raising glycogen synthesis) go through entities the annotator linked loosely ("broken down" resolved to
glucose catabolic process) and are the least trustworthy facts in the list. High IC finds specific
claims, including specifically wrong ones.

## Bottom 15 (trivial)

All score 0.00 to 0.01. Every one has "cells" (CL:0000000, IC 0.0024) or its obsolete synonym "animal
cells" at one end:

```
 0.00  d1 isaInherit  Animal cells has part nucleus / plasma membrane / organelles / membrane-bound organelle
 0.00  d1 relTrans    Animal cells has part microtubule
 0.00  d1 relTrans    organ has part cells
 0.00  d1 isaInherit  muscle tissue has part cells
 0.00  d1 isaInherit  broken down / nucleotide-excision repair / mismatch repair occurs in cells
 0.00  d1 isaInherit  transfer RNA / messenger RNA located in cells
 0.00  d1 relChain    cells overlaps endomembrane system
 0.00  d1 relChain    cells has part structure that is capable of synthesize proteins / transmembrane transport
```

## Comparison with the hub list

The hub list in `closure.py` drops facts whose subject or object is one of the 25 terms with the
highest asserted degree. The committed 1,175 survivors came from one hash seed (`PYTHONHASHSEED=1`
reproduces them exactly). Counts below are for that run and threshold 2.5.

| | facts | IC-trivial (<2.5) | IC-kept (>=2.5) | unjudged |
|---|---|---|---|---|
| hub list keeps | 1,175 | **423** | 654 | 98 |
| hub list removes | 376 | 180 | **183** | 13 |

- 36% of what the hub list calls interesting is IC-trivial (423 of 1,175).
- Half of what it removes (183 of 376) is specific: facts about ATP, DNA, RNA, glucose, the Calvin
  cycle, chloroplast, mitochondria, heart.
- The 25 hubs: only 6 score under 2.5 (brain 2.0, cells 0.0, plasma membrane 2.3, nucleus 2.2,
  cytoplasm 1.3, neuron 1.4). The other 19 are specific and score high (ATP 12.3, DNA 11.2, oxygen 11.2,
  Calvin cycle 10.1, glucose 9.2, RNA 7.8, photosynthesis 7.0, proteins 7.0, mitochondria 4.1,
  heart 4.1). The hub list mostly removes popular topics, not general ones.
- **The hub list is not deterministic.** Ties at rank 25 are broken by set iteration order, so the
  survivors vary with the hash seed. Across seeds 0 to 15 the count is 1,159, 1,175, 1,182, 1,186 or
  1,187. The IC-trivial count among survivors stays at 423 to 430, so the conclusion does not move.
  I did not fix this because IC replaces the hub list.

## Threshold

Suggested: **2.5** (`IC_MIN` in `closure.py`; `--ic=T` to sweep). A term at 2.5 and its descendants
are under 8% of its ontology. On the terms themselves: everything at "level of organisation" is below
2.0 (cell, organ, anatomical system, organism, organelle, tissue, cytoplasm, neuron, lipid, nervous
system) and so are, just above, the big compartments (brain 2.0, nucleus 2.2, plasma membrane 2.3,
digestive system 2.2, endomembrane system 2.4). The first specific parts come right after
(cytoskeleton 2.6, blood vessel 2.7, transmembrane transport 2.8, chromosome 3.0, mitochondrion 4.1).
There is no clean gap in the term distribution, so the value is a judgement.

Check against labels. I drew 42 derived facts at random, 7 from each of six IC bands, hid the scores,
and labelled each trivial (T: adds nothing a student does not already have), substantive (S) or
wrong or dubious (E). 24 T, 12 S, 6 E. One rater, and that rater is an LLM. Treat it as a sanity
check, not calibration.

| threshold | removed (n: T/S/E) | kept (n: T/S/E) | S lost |
|---|---|---|---|
| 2.0 | 14: 13/1/0 | 28: 11/11/6 | 1 of 12 |
| **2.5** | 19: 16/2/1 | 23: 8/10/5 | 2 of 12 |
| 3.0 | 21: 16/4/1 | 21: 8/8/5 | 4 of 12 |
| 3.5 | 24: 17/6/1 | 18: 7/6/5 | 6 of 12 |
| 4.0 | 28: 18/6/4 | 14: 6/6/2 | 6 of 12 |

Raising the threshold from 2.5 to 3.0 removes no extra trivial facts and loses two substantive ones.
Raising it past 3.0 only loses substantive ones. 2.0 to 2.5 gains three trivial removals for one lost
substantive fact. Hence 2.5.

What the sample also shows: 8 of 23 facts kept at 2.5 are still trivial. They are chains that pass
through a generic hub even though both ends are specific ("stomach has part microtubule" goes through
"tissue has part cells"; "mitochondria has part polymer"). So I also compute the **derivation
bottleneck**: the min IC over every entity in the proof, not just the two ends. It is stored as
`path_min` in `closure_ic.json`. On the same 42 labels it does better (at 2.5: removes 29, of which 20 T,
5 S, 4 E; keeps 13, of which 7 S and 2 E) but it also loses 5 of 12 substantive facts. With 42 labels I
would not choose between them. Of the 837 ends-min keepers, 606 also pass the bottleneck test.

## Limits

- Intrinsic IC measures how specific a term is in its ontology, not how rarely it is discussed.
  Annotation-frequency IC (GOA counts) is the alternative kept open in the plan. It would put DNA and
  ATP lower.
- IC says nothing about truth. Wrong facts ("digestive system has part plant cell wall", from
  "cells have cell walls") score 2.2 to 5.2 and survive. The sample had 5 wrong or dubious among the
  23 kept at 2.5.
- Unjudged facts (111) involve NCBITaxon, MONDO, PR, SO, HP or PATO. Loading MONDO (53 MB), HP
  (11 MB), SO and PATO (1 MB each) is cheap; NCBITaxon (690 MB) is not worth it for 63 facts.
- Obsolete-term merging (animal cell becomes cell) makes some conclusions look more trivial than the
  author meant. That is the ontology's judgement, not ours.

## Reproduce

```
python3 -I scripts/ontology/ic.py data/textbook/claims_m2 /tmp/obo data/search/ic.json
PYTHONHASHSEED=1 python3 scripts/search/closure.py data/textbook/claims_m2 /tmp/obo/go.obo 4 --ic > data/search/ic_report.txt
```

Without `--ic`, `closure.py` behaves as before and writes the same files.
