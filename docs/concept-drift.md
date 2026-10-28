# Concept drift: how much of the textbook's GO vocabulary existed, and what it meant

Task 1c, part B. Dan's worry: biology's concepts change (lipid rafts, epigenetics, senolytics), so a
library that treats a CURIE as fixed will rot. This measures it for the textbook's GO terms.

Code: `scripts/ontology/concept_drift.py`. Output: `data/ontology/concept_drift.json` (per term, per
snapshot), `concept_drift_report.txt` (the printed report), `lipid_raft_history.txt`.

## Short version

- The textbook uses **559 distinct GO CURIEs** (not the "about a thousand" I was told) in 1,171
  statements. With the GO of January 2005, 77% of those statements could have been written, 92% with
  2010, 97% with 2015, 99.7% with 2020.
- Existing is not the same as meaning the same. A third of the 2005 terms have a different name today.
  Of the terms whose name never changed, 63% have different definition text and 29% were rewritten.
- Retirement is rare in the textbook (7 of 559) but it is real: every one was live in 2020 and gone by 2026.
  Across all of GO, 23% of the terms live in 2005 are obsolete or merged today. The textbook number is
  a floor (explained below).
- Lipid raft, GO:0045121, is the clean worked example: same identifier for at least 22 years, two names,
  five parent links and two different definitions. The textbook does not use it; I took it from the archive.

## What I fetched

GO release archive, nearest release on or after 1 January. All four dates exist, so no substitution.

| snapshot | archive release | file | what the file says it is (term stanzas, obsolete ones included) |
|---|---|---|---|
| 2005 | 2005-01-01 | `gene_ontology.obo` (no go-basic yet) | saved 23 Dec 2004, 18,219 terms |
| 2010 | 2010-01-01 | `go.obo` | saved 23 Dec 2009, 30,716 terms |
| 2015 | 2015-01-01 | `go-basic.obo` | `releases/2014-12-22`, 42,329 terms |
| 2020 | 2020-01-01 | `go-basic.obo` | `releases/2020-01-01`, 47,417 terms |
| now | (local) | `go.obo` | `releases/2026-07-26`, 48,340 terms |

So "2005" is really the end of December 2004, and "2010" the end of December 2009. The archive index
lists 250 releases from 2004-03-01 to 2026-08-05. Nothing earlier than March 2004 exists there. Files
are in `/tmp/obo/go-<year>.obo`; the script downloads them if missing and re-downloading gives
byte-identical files and identical output. (The archive's CDN answers 403 to Python's default
User-Agent, curl is fine; the script sends its own.)

Per term and snapshot: **live**, **obsolete** (still listed, retired), **alt** (an old id merged into
another term) or **absent** (not minted yet; GO never reuses ids).

## How many existed

| | 2005 | 2010 | 2015 | 2020 | now |
|---|---|---|---|---|---|
| live (of 559 terms) | 431 | 512 | 545 | 555 | 552 |
| absent | 128 | 47 | 14 | 4 | 0 |
| obsolete / merged | 0 | 0 | 0 | 0 | 6 / 1 |
| live % | 77% | 92% | 97% | 99% | 99% |
| same name as today | 287 | 431 | 478 | 504 | 552 |
| statements fully expressible (of 1,171) | 906 | 1,080 | 1,136 | 1,168 | 1,162 |

A statement is expressible if every GO term in its subject, object and mediator is live in that
snapshot. First snapshot in which each term appears: 431 in 2005, 81 by 2010, 33 by 2015, 10 by 2020,
4 since. The 9 statements that are not expressible "now" rest on retired terms (below).

The most used terms that did not exist in 2005:

| term | first seen | statements |
|---|---|---|
| respiratory electron transport chain GO:0022904 | 2010 | 26 |
| cell division GO:0051301 | 2010 | 17 |
| mitotic nuclear division GO:0140014 | 2020 (created 2017) | 17 |
| meiotic cell cycle GO:0051321 | 2010 | 16 |
| interphase GO:0051325 | 2010 | 12 |
| cardiac muscle contraction GO:0060048 | 2010 | 9 |

"Cell division" and "interphase" are as basic as biology gets and had no GO term at the end of 2004.
The textbook's most common division term, mitotic nuclear division, was minted in 2017.

## Newest ten, with creation dates

Only 59 of 559 terms have a `creation_date` at all (the tag is in `go.obo`, not `go-basic.obo`, and
older terms lack it). It is not always a mint date: for 16 of the 59 a snapshot older than the date
already has the term. "transport" says 2012-12-13, "behavior" 2012-09-20, "transmembrane transport"
2015-10-21, yet all were in the 2010 or 2005 files. The field was back-filled for older terms. The
list below keeps only dates that agree with the snapshots.

| created | term | first in snapshot | statements |
|---|---|---|---|
| 2025-09-29 | GO:0160307 protein biosynthetic process | now | 1 |
| 2025-05-19 | GO:0160269 sweat secretion | now | 1 |
| 2024-04-29 | GO:0160184 paracellular transport | now | 1 |
| 2023-02-23 | GO:0180010 co-transcriptional mRNA 3'-end processing, cleavage and polyadenylation pathway | now | 0 |
| 2019-05-22 | GO:0140352 export from cell | 2020 | 0 |
| 2019-05-20 | GO:0120178 steroid hormone biosynthetic process | 2020 | 1 |
| 2017-03-23 | GO:0140014 mitotic nuclear division | 2020 | 17 |
| 2017-03-23 | GO:0140013 meiotic nuclear division | 2020 | 4 |
| 2015-11-09 | GO:0061744 motor behavior | 2020 | 2 |
| 2015-05-18 | GO:1990748 cellular detoxification | 2020 | 2 |

"protein biosynthetic process" was created in September 2025. The CURIEs were linked during this
project, so against a current GO, and a term that new shows how current.

## Names and definitions

Live in 2005 with a different name today: **144 of 431 (33%)**; for 2010 it is 81 of 512 (16%), 2015
67 of 545 (12%), 2020 51 of 555 (9%). The most used:

| 2005 name | name today | statements |
|---|---|---|
| protein biosynthesis | translation | 27 |
| glycolysis | glycolytic process | 24 |
| glucose catabolism | glucose catabolic process | 12 |
| circulation | blood circulation | 12 |
| metabolism | metabolic process | 12 |
| transcription, DNA-dependent | DNA-templated transcription | 10 |
| nuclear membrane | nuclear envelope | 9 |
| cell soma | neuronal cell body | 9 |
| cell wall (sensu Magnoliophyta) | plant-type cell wall | 8 |
| carbon utilization by fixation of carbon dioxide | carbon fixation | 7 |

Many are cosmetic. Some are not ("circulation" became "blood circulation"; "cell wall (sensu
Magnoliophyta)" became "plant-type cell wall", which a context-aware library would care about).

The label is not the concept. Among terms whose name is the same as today's, the definition text
differs for 181 of 287 (2005), 200 of 431 (2010), 105 of 478 (2015) and 69 of 504 (2020). Counting
only definitions with under 60% text similarity as rewritten: 83, 89, 43 and 30. For example
"nuclear division" was "The partition of the nucleus and its genetic information" and is now "The
division of a cell nucleus into two nuclei, with DNA and other nuclear contents distributed between
the daughter nuclei." I did not judge meaning change term by term; text change is a proxy and a
noisy one.

## Whole GO, for comparison

Terms live in each snapshot, and what they are today (all of GO, not just the textbook's):

| | 2005 | 2010 | 2015 | 2020 |
|---|---|---|---|---|
| live | 17,250 | 29,290 | 40,470 | 44,700 |
| obsolete today | 2,653 | 4,577 | 6,759 | 7,437 |
| merged (alt id) today | 1,320 | 1,443 | 1,648 | 918 |
| retired % | 23% | 21% | 21% | 19% |
| renamed % | 32% | 13% | 8% | 6% |

Renaming matches the textbook (33% against 32% for 2005). Retirement does not: 23% across GO, under
2% for the textbook. Part of that gap is selection. The textbook's CURIEs were linked and checked on
OLS4 during this project ("verified on OLS4" in `docs/textbook-milestone.md`), which favours live terms,
and a core textbook vocabulary is plausibly more stable than GO's long tail. The check is not perfect:
the only four GO mentions it flagged as unverified are all retired terms (aging, primase, polysome,
polyadenylation), but three other retired terms passed it. I did not find out why. Read the textbook
figure as a floor on what a vocabulary pinned at an old date would lose.

## Obsolete or merged terms the textbook still uses

All seven were live in every snapshot through 2020. None was retired before 2020.

| term | now | replacement | statements |
|---|---|---|---|
| GO:0000003 reproduction | obsolete | replaced_by reproductive process GO:0022414 | 1 ("Conjugation is a type of reproduction") |
| GO:0003896 DNA primase activity | obsolete | replaced_by DNA-directed RNA polymerase activity GO:0003899 | 1 ("Primase synthesizes an RNA primer") |
| GO:0019661 homolactic fermentation | obsolete | replaced_by pyruvate fermentation to lactate GO:0019244 | 6 (lactic acid fermentation) |
| GO:0007050 cell cycle arrest | merged | alt id of regulation of cell cycle GO:0051726 | 1 ("p53 activates genes whose products halt the cell cycle") |
| GO:0005844 polysome | obsolete | none; consider ribosome GO:0005840 | 0 |
| GO:0006378 mRNA polyadenylation | obsolete | none; consider 3 terms | 0 |
| GO:0007568 aging | obsolete | none | 0 |

Three notes. The last three appear only as linked entities, not in a compiled statement. Following
`replaced_by` is right for primase (a primase is an RNA polymerase) but the replacement's name reads
nothing like the original, so a blind remap needs a human glance. "Cell cycle arrest" quietly became
a synonym of the broader "regulation of cell cycle", so p53 halting the cycle now points at a term
that also covers speeding it up.

## Worked example: lipid raft, GO:0045121

Not used by the textbook (an introductory text has no need). I streamed 15 archive releases for the
term (`concept_drift.py --history GO:0045121 <dates>`, output in `lipid_raft_history.txt`):

| from release | name | parent | definition |
|---|---|---|---|
| 2004-03-01 (earliest in the archive) | lipid raft | part_of plasma membrane | "Specialized membrane domains composed mainly of cholesterol and sphingolipids ..." (PMID:11880687, Sedwick 2002, a lymphocyte review) |
| 2006-06-01 | lipid raft | is_a plasma membrane part | same |
| 2008-03-01 | **membrane raft** | is_a membrane part | "Any of the small (10-200 nm), heterogeneous, highly dynamic, sterol- and sphingolipid-enriched membrane domains that compartmentalize cellular processes ..." (PMID:16645198, Pike 2006, the Keystone Symposium report "Rafts defined") |
| 2015-01-01 | membrane raft | is_a membrane region | same |
| 2020-01-01 | membrane raft | is_a membrane microdomain | same; PMID:20044567 (Lingwood 2010) added |

"lipid raft" survives as an EXACT synonym. What changed is the concept. The 2004 term is a
composition: cholesterol and sphingolipids, "relatively poor in" other lipids, a plasma-membrane part.
The 2008 term is a size and dynamics claim: 10 to 200 nm, heterogeneous, highly dynamic, any membrane.
The rename (between the 2008-02-01 and 2008-03-01 releases) came about 20 months after the Keystone
report was published (J Lipid Res, July 2006); the 2008-03 release even carries a typo
("heretogeneous") that was fixed a month later. A 2005 statement "lipid
rafts concentrate protein X" and a 2010 statement "membrane rafts concentrate protein X" share a CURIE
and are not about the same thing. Nothing here says the first was wrong: it was true of its concept.

What I can and cannot say about "minted": it was already in the earliest archived release, so it was
minted before March 2004, and the archive cannot date it more closely. The term has no `creation_date`.

## What this means for versioning biolib

Biolib should be versioned like an ontology, not like Mathlib, and these numbers say which of the
planned mechanisms carry weight. Every **Statement is dated**, because the same sentence means
different things in different years and because 23% of GO's 2005 vocabulary is retired or renamed
today; a 2005 statement cannot be silently re-read with 2026 definitions. Every **Entity carries the
release** its CURIE was read from (for example `go/releases/2026-07-26`), because the CURIE alone does
not pin the meaning: a third of the 2005 terms were renamed and nearly two thirds of the terms that
kept their name have different definition text; the heavier option, pinning an ontology version per
Statement, is not needed while the Entity release is recorded, and can wait for literature at scale.
**Established is indexed by year**, and this experiment gives the rule that goes with it: a statement
can only be established in year y if its entities exist in the release for y (77% of the textbook's
statements pass that check for 2005, 92% for 2010), so the year index should refuse statements that
name a concept minted later, and conversely the concept history (lipid raft before and after 2008)
shows why the same CURIE in two years should not be fused as one body of evidence without a
same-meaning check. **Retired terms** get a `retired` marker read from `replaced_by` and `consider`,
never a silent remap: of the seven retired terms in the textbook, four have a replacement or merge
target (two of them change the surface meaning: primase becomes an RNA polymerase, cell cycle arrest
becomes regulation of cell cycle) and three have none (two `consider` hints, and aging with nothing),
so they need re-annotation. At 1.3% of the vocabulary it
is cheap; at the whole-GO rate of 19 to 23% over a decade or two it would not be, which is the number to
watch when literature arrives.

## Limits, honestly

- **Selection** in the textbook's retirement rate (above). The existence and renaming numbers are less
  exposed: a term that is live today could be any age.
- **Snapshots, not a time series.** Four dates plus now. The lipid raft history used 15; I did not
  bisect anything else. "First seen" is the first of my snapshots, so a term first seen in 2010 was
  minted sometime between December 2004 and December 2009.
- **Name equality is crude.** Case and wording changes count as renames. The definition-text measure is
  a proxy. A term can change meaning with no change in either (its parents move; lipid raft's parent
  changed four times).
- **GO only.** UBERON, CL and ChEBI drift too and I did not look. 62% of the textbook's CURIEs are not GO.
- **"About a thousand" GO terms was wrong**: 558 from the statement and entity fields, 559 once the
  targets of `curie_changes` are included.
- **2005 and 2010 files are `gene_ontology.obo` and `go.obo`**, not `go-basic.obo`. For ids, names and
  definitions they are the same kind of data, but `go.obo` carries cross-product extras that I do
  not use.

## Reproduce

```
python3 -I scripts/ontology/concept_drift.py data/textbook/claims_m2 /tmp/obo data/ontology/concept_drift.json
python3 -I scripts/ontology/concept_drift.py --history GO:0045121 2004-03-01,2004-09-01,2005-01-01,2005-06-01,2006-01-01,2006-05-01,2006-06-01,2007-01-01,2008-02-01,2008-03-01,2008-04-01,2010-01-01,2015-01-01,2020-01-01,2026-08-05
```
