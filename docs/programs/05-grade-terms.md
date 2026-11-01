# Program 05: grade terms (prokaryote, protist, algae, invertebrate)

Written 2026-10-31 and reviewed the same day (corrections are listed near the end). A program of work,
not a decision: Dan chose "more research needed" for decision 5. Nothing in the core changed. The
prototype of the core changes is `BioLean/Proto/TaxonUnion.lean`, and nothing imports it.

## Summary

- **What I did.** Built 51 stress cases: 43 textbook claims (from 35 book sentences) and 8 synthetic.
  I ran them on 28 test organisms, on today's core, on data-only options and on a prototype. That
  gives 255 rows, each marked against a checked source (`data/stress/05/cases.tsv`, `rows.tsv`).
- **Today, archaea are lost and the cell-type route reaches nobody.** Of 43 textbook cases: 9 PASS,
  8 FAIL, 17 SILENT, 9 INEXPRESSIBLE. Round 3 encodes "prokaryote" as Bacteria. Round 2 encodes it as
  the cell type CL:0000520, which no organism can reach.
- **The provisional reason holds, and a union fixes it with no core change.** "Cellular organisms" puts
  the prokaryote electron transport chain in human plasma membranes (P02). GO's union class
  `NCBITaxon_Union:0000004` (Bacteria or Archaea) gets P01 to P03 right with three statements.
- **Fixing the grade does not fix the book.** In 5 of 19 prokaryote cases the sentence or its GO term
  is bacterial (peptidoglycan, FtsZ, flagellum, single origin, photosynthesis). The union then says
  false things about archaea. Dropped hedges, losses inside a clade and the missing rule for counts
  cause as many errors as grades do.
- **Protist, invertebrate, fish and lizard exist nowhere as a class.** As "a clade minus clades" they
  need a closed world: with one lineage fact missing, the prototype calls a sponge a protist (S01).
- **What matters now.** A data-only step is cheap and safe: GO's union class, the book's bridge
  sentences, and a per-sentence choice of Bacteria or the union. Core changes are only prototyped (a
  new type, five new rules, a union coverage measure) and wait for the decision.

## Words used here

| word | meaning here |
|---|---|
| clade | a group with one ancestor and all its descendants (NCBITaxon nodes are meant to be clades) |
| grade | a textbook group that is not a clade: a clade minus some descendants (invertebrate, fish, protist, prokaryote), or several clades (algae) |
| union | a grade as "A or B": prokaryote = Bacteria or Archaea |
| complement | a grade as "A minus B": invertebrate = Metazoa minus Vertebrata |
| in-part name | NCBI Taxonomy's name class for a name that covers part of this taxon and part of others: NCBI's own marker for a grade |
| narrowing | from a claim about a group to the same claim about a member (sound if the member is in the group) |
| generalising | from members to the group (induction, so discounted by coverage) |
| coverage | how much of a group the sampled members cover (`BioLean/Coverage.lean`, bracketing by default) |
| member test | "given that E. coli is a bacterium, does BioLean derive the sentence for E. coli?" |
| due | a conclusion is due when the sentence, read as the book means it, entails it for the member. After "some", nothing is due for one member |
| row | one (case, option, member) result; a case has several |
| PASS / FAIL / SILENT / INEXPRESSIBLE | a true conclusion, or rightly silent / a false conclusion / silent where a conclusion is due / cannot be stated |

## The question

Decision 5. "Prokaryote" was annotated as Bacteria (NCBITaxon:2), so archaea are lost. The provisional
answer kept Bacteria, because "cellular organisms" would make "the electron transport chain is in the
plasma membrane" false of eukaryotes. The general problem: textbooks name groups that are not clades.
Which representation should a grade get, and which derivation rules must change?

### What the data say first

| term | book sentences | compiled statements (R2 + R3) | how they are encoded today |
|---|---:|---:|---|
| prokaryote | 88 | 81 | R2: CL:0000520 in 24 of 44; R3: Bacteria in 15 of 37; Archaea once; no union anywhere |
| protist | 8 | 6 | Eukaryota, or dropped |
| algae | 8 | 3 | Eukaryota, or dropped; of 19 records, 6 blocked as ECOCORE (not imported), 9 ungrounded |
| invertebrate | 4 | 1 | dropped; the rest blocked (ungrounded) |
| fish | 4 | 1 | blocked; grounded elsewhere as Actinopterygii |
| microbe | 10 | 7 | Bacteria, or dropped |
| "plant", "animal" | 96, 105 | 80, 64 | Viridiplantae (31 mentions), Embryophyta (9), Metazoa (32) |
| "animal cell", "plant cell" | 35, 36 | 29, 31 | animal cell as CL:0000548 (obsolete); plant cell as PO:0009002 or the wall GO:0009505 (CL:0000610 is obsolete) |

Counts from `scripts/stress/grade_survey.py` over `data/textbook/claims_m2` and `claims_m3`.

| vocabulary | what it has for grades (checked 2026-10-31) |
|---|---|
| NCBITaxon | no node for prokaryote, protist, invertebrate, fish, lizard, microorganism |
| NCBI name classes | "prokaryote", "Prokaryota", "Monera": **in-part** on Bacteria and on Archaea. "algae": in-part on 22 eukaryote taxa, no cyanobacteria. "Reptilia": in-part on Crocodylia, Lepidosauria, Testudines. "fishes": common name of Actinopterygii, Dipnomorpha, Chondrichthyes. Nothing for protist, invertebrate, lizard (`ncbi_inpart.tsv`) |
| GO (go-plus) | 15 union classes for taxon constraints, among them `NCBITaxon_Union:0000004` "Prokaryota" = NCBITaxon:2 or NCBITaxon:2157 (Deegan 2010; `go_union_taxa.tsv`) |
| CL | CL:0000520 prokaryotic cell: no definition, is_a cell, `never_in_taxon` Eukaryota only. CL:0000255 eukaryotic cell and CL:0000521 fungal cell are defined as "cell and in_taxon" the clade. Animal cell and plant cell are obsolete |
| NCIT | C14263 Prokaryote, defined by a character ("without a cell nucleus"); C77914 Protista |
| ECOCORE | 00000076 algae, "includes cyanobacteria": disagrees with NCBI and with the book |

## The options

"Core change" means a change to `BioLean/`: a new `Claim` constructor, `Derivation` rule, opinion
operator or type. "None" means data, annotation or scripts. "Right" and "wrong" list observed rows.

| | idea | core change? | needs | right (cases) | wrong (cases) |
|---|---|---|---|---|---|
| a | one clade per grade (status quo) | none | nothing | A01, A02, I03, L04, M01, M03, P18 | loses archaea (P01 to P03) |
| a+ | the widest clade (cellular organisms) | none | re-annotation | reaches archaea | reaches humans (P01, P02) |
| a' | a better term per sentence (Bacteria where "prokaryote" means bacterium; Embryophyta for land plants) | none | a reader per sentence | P09, L02 | a wrong pick is silent about it: C03 (ferns), F02 (fish as Actinopterygii loses the shark), C02 (CL's `replaced_by`) |
| b0 | GO's union class as a taxon entity, plus two is_a statements | none for narrowing | 3 statements | P01 to P03, P15 | P09; the core's taxon checks cannot see it (S08) |
| b | a union as a taxon expression, membership decided | **new type** `TaxonExpr`, `Grade`; **new rules** `mem`, `unionIntro`, `generalizeG`; **new coverage measure**; no new `Claim` constructor or operator | prototype | P01, P02, R03, A04 | P09; A04 with ECOCORE's list; the virtual-node coverage over-counts (S04, S05) |
| c | a clade minus clades | as b, plus "not is_a" in `mem` | a complete lineage (closed world) | F01, F02, S09 | R02 (Euglena), I01 read as universal, S01 (a sponge becomes a protist) |
| d | the cell type CL:0000520, plus the book's bridge (m45428-13) and CL's definitions | none | 2 bridge statements; CL's `in_taxon` definitions, which the is_a import drops | P05, P06, P14, R04 | exposes P04, P07, P08, P19; no cell type for protist or invertebrate |
| e | a class defined by a character ("protist and capable_of photosynthesis") | **new rule** `refineIntro`; "without" needs a new entity form | a character statement per member | R01 | S07 cannot be formed; the protist variant without green algae is silent for Chlamydomonas (R01) |
| f | local grade entities with membership statements | none | a list per grade | listed clades in R02, I01 | R02 (Euglena), I01 (octopus, sponge); open list (S09) |
| g | split the sentence into one statement per clade | none | re-annotation | P01 | overlapping parts double count (S03) |
| h | restore the dropped hedge ("some", "most") | none (`Claim.quant` exists) | re-annotation | I01 (all three members rightly silent) | says nothing about any member; only fits where the book hedged |
| i | narrow counts (`countSub`: a subclass inherits a count) | **new rule**, not about grades | prototype | P10, P11 for single-origin, single-chromosome bacteria | exposes V. cholerae (P11) and, with b, archaea |
| j | take union lists from NCBI's in-part names | none (data for b, f) | E-utilities | A04 | exists only for prokaryote, algae, Reptilia |

### Which derivation rules change

| rule | today (core) | with b or c (prototype) |
|---|---|---|
| narrowing, grade to member | `relChain`, `refineMono`, `notRelSub`, `notRelObj`, `isaInheritEffect` narrow `rel`, `notRel` and `effect` claims once an is_a statement links member to grade; b0, d and f supply it as data | **no new narrowing rule**: `mem` decides membership, the is_a laws do the rest |
| narrowing a count, measure or hedged claim | no rule narrows a `count` or `measure` along is_a, and no rule takes a `quant` premise at all. Pinned by a check on `Derivation`'s constructors (end of `GradeTerms.lean`) | `countSub` (option i); `quant` still never narrows, by design |
| generalising, all parts to the union | none | `unionIntro`: sound, because the union is exactly its parts |
| generalising, members to a grade | refused: `Coverage.admissible` uses `Taxa.isA`, blind to the union class (S05) | `generalizeG` with a grade-aware coverage |
| coverage over a union | none | three readings (S04): virtual node 1, least-covered part 0, mean of parts 1/4, for E. coli, Halobacterium and Sulfolobus |
| coverage over a complement | none | bracketing with excluded clades pruned; for Euglena and Paramecium it equals Eukaryota's (1/9, S06), as the excluded clades sit below the top split |
| `Ctx` | one optional taxon entity | unchanged: the grade's entity goes in `Ctx.taxon`, its expression in a `Grade` |

### What the prototype is

`BioLean/Proto/TaxonUnion.lean` (74 rows). `GDeriv` wraps the core `Derivation`. It adds the type
`TaxonExpr` (clade, union, minus), `Grade`, the rules `mem`, `unionIntro`, `generalizeG`,
`refineIntro`, `countSub`, and `UMeasure`. It restates three core is_a laws over `GDeriv` premises;
they are not new. A theorem shows that union membership only grows as lineage data grows
(`TaxonExpr.union_mono`). Complements have no such theorem; S01 is the counterexample. A check on
`GDeriv`'s constructors pins `countSub` as the only rule that narrows a count.

## The stress set

51 cases. Full rows (encoding, correct conclusion, source, observed, mark, Lean test names) are in
`data/stress/05/cases.tsv`. "Today" is the compiled library. "Data only" is today's core plus extra
statements (a+, a', b0, d, f, g). "Prototype" is `TaxonUnion.lean`. The 28 test organisms: 5 bacteria
(E. coli, V. cholerae, Gloeobacter, Synechocystis, Ca. Thiomargarita magnifica), 5 archaea
(H. volcanii, Halobacterium, Sulfolobus, Thermoplasma, M. smithii), 6 protists (Plasmodium,
Chlamydomonas, Euglena, Paramecium, T. brucei, Ectocarpus), yeast, Arabidopsis, Epifagus, the fern
Marsilea, 7 animals (sponge, planarian, fly, octopus, shark, zebrafish, anole) and human.

| id | sentence (short) | probes | today | data only | prototype |
|---|---|---|---|---|---|
| P01 | transcription in the cytoplasm of prokaryotes | union true; archaea lost | SILENT | a+ FAIL, b0 PASS, g PASS | b, c PASS |
| P02 | ETC in the plasma membrane of prokaryotes | the provisional decision | SILENT | a+ FAIL, b0 PASS | b PASS |
| P03 | ribosomes in the cytoplasm in prokaryotes | union true | SILENT | b0 PASS | |
| P04 | prokaryotes divide by binary fission | CL route; FtsZ means bacterium | SILENT | d FAIL (Sulfolobus) | |
| P05 | prokaryotes lack a nucleus | CL route | SILENT | d PASS | |
| P06 | all prokaryotes have ribosomes | CL route | SILENT | d PASS | |
| P07 | all prokaryotes have a cell wall | exception inside the group | SILENT | d FAIL (Thermoplasma) | |
| P08 | some prokaryotes have flagella | hedge dropped; bacterial term | PASS by silence | d FAIL (archaellum) | |
| P19 | prokaryotes lack membrane-bound organelles | character versus clade | PASS by silence | d FAIL (T. magnifica) | |
| P09 | prokaryotic walls are peptidoglycan | means bacterium; context dropped | FAIL | a' PASS, b0 FAIL | b FAIL |
| P10 | replication from a single origin | means bacterium; counts | SILENT | b0 PASS (rightly silent) | i PASS, b+i FAIL |
| P11 | a single chromosome | even Bacteria too wide | SILENT | b0 PASS (rightly silent) | i FAIL, b+i FAIL |
| P12 | some bacteria and archaea respire anaerobically | hedge dropped | FAIL (Sulfolobus) | | |
| P13 | photosynthetic prokaryotes: membrane infoldings | character group | INEXPRESSIBLE | | |
| P14 | bacterial and archaeal cells are prokaryotic | the book's own bridge | SILENT (blocked) | d PASS | |
| P15 | prokaryotes include bacteria and archaea | the book's own union | SILENT (blocked) | b0 PASS | |
| P16 | all cells are prokaryotic or eukaryotic | covering axiom | INEXPRESSIBLE | b0, d INEXPRESSIBLE | |
| P17 | prokaryotes and eukaryotes do glycolysis | union that is a clade; "most" added | SILENT | | |
| P18 | glycolysis in the cytoplasm of most prokaryotic, all eukaryotic cells | two quantifiers; context dropped | PASS (the glycosome is cytoplasm) | | |
| R01 | photosynthetic protists have chloroplasts | protist plus character | FAIL (round 2) | | e PASS |
| R02 | fungal and protist cells have walls | protist half dropped | SILENT | d PASS, f FAIL (Euglena) | c FAIL |
| R03 | plants, fungi, bacteria, some protists have walls | union of named clades | SILENT | | b PASS |
| R04 | animal, plant, fungal, protist cells are eukaryotic | clade suffices | SILENT | d PASS | |
| R05 | protists, plants, animals use similar steps | similarity | INEXPRESSIBLE | | |
| A01 | chloroplasts in eukaryotes such as plants and algae | grade dropped rightly | PASS | | |
| A02 | eukaryotic autotrophs such as algae: chloroplasts | grade replaced by clade | PASS | | |
| A03 | certain bacteria and algae are autotrophs | ECOCORE not imported | INEXPRESSIBLE | | |
| A04 | who is an alga? | vocabularies disagree | INEXPRESSIBLE | | ECOCORE FAIL, book and NCBI lists PASS |
| I01 | open circulation in invertebrates | complement; "some" | INEXPRESSIBLE | f FAIL | c FAIL, h PASS |
| I02 | vertebrate nerves more complex than invertebrate | comparison | INEXPRESSIBLE | | |
| I03 | in open systems fluid bathes the organs | grade dropped rightly | PASS | | |
| F01 | countercurrent in sharks, bony fish, ... | fish in a union | INEXPRESSIBLE | | c PASS |
| F02 | polyploidy among fish and lizards | membership | INEXPRESSIBLE | | Actinopterygii FAIL (shark), c PASS |
| L01 | plants turn sunlight into chemical energy | loss inside a clade | FAIL (Epifagus) | | |
| L02 | plant cells have a cell wall | plant means land plant | FAIL (Chlamydomonas) | a' PASS | |
| L03 | photosynthesisers like plants make sugars | plants for a character | SILENT (cyanobacteria) | | |
| L04 | plant cell wall is cellulose | GO term does the work | PASS | | |
| C01 | animal cells have a centrosome | loss inside a clade | FAIL (planarian) | | |
| C02 | animal cells lack walls | obsolete CL term | SILENT | `replaced_by` FAIL | |
| C03 | plant cells lack centrioles | broad "plants" | FAIL (Chlamydomonas, Marsilea) | a' FAIL (Marsilea) | |
| M01 | microbes in the gut make vitamin K | microbe as Bacteria | PASS | | |
| M02 | methanogens live in ruminant guts | character group as a phylum | FAIL (halophiles) | | |
| M03 | oxygen poisons obligate anaerobes | the book's example genus | PASS | | |
| S01 | synthetic: complement with a missing fact | closed world | | | c FAIL with partial data |
| S03 | synthetic: overlapping grades | double counting | FAIL (8/9, no warning) | | |
| S04 | synthetic: coverage over a union | three readings | | | virtual node FAIL |
| S05 | synthetic: generalise prokaryote instances | union versus widest clade | FAIL (reaches humans) | b0 SILENT | mean PASS, virtual node FAIL |
| S06 | synthetic: coverage over a complement | pruned bracketing | | | PASS (equals Eukaryota) |
| S07 | synthetic: "cell without a nucleus" | negative character | | | INEXPRESSIBLE |
| S08 | synthetic: union class in the core's taxon checks | lints, coverage | FAIL (lint) | | |
| S09 | synthetic: is a planarian an invertebrate? | open list | SILENT (f) | | c PASS |

## Results observed

All numbers come from `python3 scripts/stress/grade_cases.py`, which re-runs both Lean files.

### Today (the compiled library, 43 textbook cases)

| mark | cases | ids |
|---|---:|---|
| PASS | 9 | A01, A02, I03, L04, M01, M03, P18; P08 and P19 only by silence |
| FAIL | 8 | P09, P12, R01, L01, L02, C01, C03, M02 |
| SILENT | 17 | P01 to P07, P10, P11, P14, P15, P17, R02, R03, R04, L03, C02 |
| INEXPRESSIBLE | 9 | P13, P16, R05, A03, A04, I01, I02, F01, F02 |

Synthetic cases on the core: S03, S05, S08 FAIL; S09 SILENT.

### Rows per option (on the cases each option was run on)

| option | PASS | FAIL | SILENT | INEXPRESSIBLE |
|---|---:|---:|---:|---:|
| a (today) | 46 | 14 | 34 | 15 |
| a+ widest clade | 4 | 2 | 0 | 0 |
| a' better term per sentence | 9 | 3 | 0 | 0 |
| b0 GO union class (data) | 18 | 2 | 3 | 1 |
| b union (prototype) | 30 | 5 | 1 | 0 |
| c complement (prototype) | 16 | 4 | 0 | 0 |
| d cell type plus bridge | 15 | 4 | 0 | 1 |
| e character class | 4 | 0 | 1 | 1 |
| f local lists | 4 | 3 | 1 | 0 |
| g split sentence | 3 | 1 | 0 | 0 |
| h restore the hedge | 3 | 0 | 0 | 0 |
| i count narrowing (with b: 3 FAIL) | 2 | 1 | 0 | 0 |

One row is UNVERIFIED and not counted (E. coli flagella under d). The options were run on different
cases, so compare within a case, not down a column.

### Findings

1. **The union fixes the lost archaea** (P01 to P03), with no core change (b0) or in the prototype
   (b). Union and complement agree on all 12 prokaryote and eukaryote test members.
2. **The provisional reason is right.** "Cellular organisms" sends P01 and P02 to humans (a+ FAIL).
3. **Round 2's cell-type route reaches no organism.** CL:0000520 has no `in_taxon` axiom, and the
   book's bridge (P14) was blocked. Adding the bridge (d) exposes 4 errors that silence hid: P04, P07,
   P08, P19. Two of today's 9 PASSes are that silence.
4. **"Prokaryote" is often bacterial** in the sentence (P09, P10, P13) or in its GO term (P04 FtsZ,
   P08 bacterial flagellum): 5 of 19 prokaryote cases. The union is right about membership and wrong
   about the biology. Only reading the sentence (a') helps.
5. **Many failures are not about grades**: dropped hedges (P08, P12, R01), dropped context (P09),
   losses inside a clade (L01, C01: program 01), and no rule for counts (P10, P11). Dropped context
   is not always harmful: P18 is right because GO's cytoplasm, like the book's, includes organelles.
6. **Broad "plants" is the commonest wrong clade.** Viridiplantae gives Chlamydomonas a cellulose
   wall (L02) and no centrioles (C03). Embryophyta fixes L02 and the Chlamydomonas row of C03, but
   C03 is still false for the fern Marsilea, whose sperm have centrioles.
7. **Complements need a closed world** (S01). 19 of 28 test organisms are outside the imported
   NCBITaxon closure, so every option here leans on a local lineage table.
8. **The core's taxon checks cannot see a union class** (S08): `Taxa.known` is false, `Curie.encode`
   fails on its prefix, `generalize` refuses it, and `taxonConsistent` flags E. coli evidence as
   inconsistent.
9. **Coverage over a union is an open choice** (S04, S05). From E. coli, Halobacterium and Sulfolobus,
   the virtual node gives belief 12/13, the mean of parts 3/13, the least-covered part 0. The core's
   cellular-organisms route gives 8/13 and reaches humans.
10. **Vocabularies disagree on membership.** ECOCORE's algae include cyanobacteria; the book and NCBI
    do not (A04). As Actinopterygii, "fish" loses the shark (F02).
11. **Character classes work for positive characters** (R01) but cannot say "without" (S07).
12. **Overlapping grades double count silently** (S03: 8/9 from one sentence). This is the known
    evidence-independence limit, met through a grade.

## Experiments for later

Each exit test was written before any result. Cost is in agent tasks.

| | experiment | exit test | cost |
|---|---|---|---:|
| E1 | Data-only prokaryote fix: read each of the 88 sentences; choose Bacteria, the union class (b0) or the cell type with the bridge (d); emit the statements | every archaeal row that is SILENT today for a true claim turns PASS; every new FAIL is one already shown here (P04, P07, P08, P09, P19) | 2 |
| E2 | How often does a grade mean one clade? Classify all 88 prokaryote sentences (and the 96 "plant" ones) as bacterium-only, union, or clade-free | a table with a second reader's agreement above 80 percent, and a number for "prokaryote means bacterium" | 1 |
| E3 | Count narrowing in the core (option i, `countSub`, also for `measure`) | P10 and P11 rows match the prototype exactly; the rule check in `GradeTerms.lean` fails and is re-pinned with `countSub`; no other theorem changes | 1 |
| E4 | Coverage over a union: fix the reading before computing | 10 sample sets with coverage agreed by Dan in writing first; the chosen reading matches all 10 | 1 |
| E5 | Union class in the taxon machinery (`Taxa.known`, `Curie.encode`, `admissible`, `taxonConsistent`) | S08 rows flip to PASS; `Tests/Context.lean` and `Examples/Transcription.lean` unchanged | 2 |
| E6 | Grade lexicon: NCBI in-part names, GO union classes and local lists, one entry per grade term | every grade mention in `survey.tsv` maps to an expression or is flagged; lists checked on OLS4 | 2 |
| E7 | Promote the prototype (only after the decision) | every prototype row reproduces in the core; the S01 hazard is closed by a completeness check on the lineage | 3 |
| E8 | Hedge audit: grade sentences whose "some" or "most" was dropped | a list with counts; each fix re-run through `grade_cases.py` | 1 |

## What would change the decision

- **If most prokaryote sentences mean bacterium** (E2), then a' (Bacteria by default, the union where
  the book names archaea) is enough, and the core needs no union.
- **If the library must generalise to grades** (M4, induction to "all prokaryotes"), data-only b0 is
  not enough: coverage and admissibility must see the union (E4, E5, then b).
- **If NCBI Taxonomy adopts the two-domain tree** (eukaryotes inside Archaea, Williams 2013), "Bacteria
  or Archaea" would include eukaryotes and the union breaks. "Cellular organisms minus Eukaryota" (c)
  survives. That favours the complement for prokaryote, whatever is chosen for protist.
- **If BioLean imports complete lineages** (all of NCBITaxon, not the closure of used terms), the
  closed-world hazard (S01) goes away, and c becomes as safe as b.
- **If Dan prefers cell kinds to organism kinds**, d is a real option for prokaryote and eukaryote. But
  it has no cell type for protist, invertebrate or fish, and CL's "animal cell" is obsolete.

## Limits

- 43 claims chosen to span the axis, not a random sample: these are not book rates. Several cases
  share a book sentence (P01, P05 and P15; P06, P07 and P19; P09 and L04; P14 and R04; A03 and A04;
  I01 and I03).
- 19 of 28 test organisms use a local NCBI lineage table (`lineage.tsv`, efetch 2026-10-31). One
  lineage node, NCBITaxon:3843548 (Anolidae), is on NCBI but not yet on OLS4.
- Marks are mine, against checked sources; six coverage rows are labelled judgement.
- The prototype weights a decided membership at 4/5, like curated data. A guess.
- Where the book is wrong (P07, P11, I01 read as universal), a faithful encoding FAILs. The mark
  judges the conclusion, not the formalism.

## Review corrections (2026-10-31)

An independent review re-ran every file and script and re-checked every source. It changed these.

| what | before | after, and why |
|---|---|---|
| P18 (T. brucei) | FAIL | PASS: the glycosome is part of the cytoplasm in GO (GO:0020015 is_a microbody, part_of GO:0005737) and in the book's glossary (m45432-361) |
| I01, option h | SILENT | PASS: from "some invertebrates" nothing is due for one member |
| P08 (E. coli, today), P12 (Halobacterium) | UNVERIFIED | PASS: the first is hedged, so nothing is due; the second is checked (Müller 2005) |
| C03 | "Embryophyta fixes it", never run | run: Embryophyta still FAILs, for the fern Marsilea (Mizukami 1966) |
| "no rule narrows a count or a hedge" | pinned only by each claim's shape | pinned by a check on the constructors of `Derivation` and `GDeriv`, which flips if a rule is added |
| options table | a', b, c, e, f, g, h listed wrong or unobserved rows | each row now lists observed rows only |

Today's count moved from 8 PASS, 9 FAIL to 9 PASS, 8 FAIL. All 348 CURIEs and all 44 papers were
re-checked fresh: `curies_review.tsv`, `references_review.tsv`.

## References (checked)

All on Europe PMC (title, first author and year match; `references_checked.tsv`, re-checked fresh in
`references_review.tsv`, 42 of 44 also on Crossref). The quote behind each use is in
`quotes_checked.tsv`. OpenStax Concepts of Biology sentences are cited by id from `data/textbook/claims_m2`.

| key | first author | title (start) | PMID |
|---|---|---|---|
| Adl2012 | Adl SM | The revised classification of eukaryotes | 23020233 |
| Albers2011 | Albers SV | The archaeal cell envelope | 21572458 |
| Azimzadeh2012 | Azimzadeh J | Centrosome loss in the evolution of planarians | 22223737 |
| Bernal2001 | Bernal D | Review: Analysis of the evolutionary convergence ... | 11423338 |
| Beveridge1996 | Beveridge TJ | The response of selected members of ... | 8885405 |
| Brasen2014 | Bräsen C | Carbohydrate metabolism in Archaea: current insights ... | 24600042 |
| Burki2020 | Burki F | The New Tree of Eukaryotes | 31606140 |
| Chen2005 | Chen L | The genome of Sulfolobus acidocaldarius, a ... | 15995215 |
| Cholewa2025 | Cholewa D | Variable Bioproduction with Euglena gracilis: A ... | 40990997 |
| Conly1994 | Conly JM | The contribution of vitamin K2 (menaquinones) ... | 8198105 |
| Darland1970 | Darland G | A thermophilic, acidophilic mycoplasma isolated from ... | 5481857 |
| Deegan2010 | Deegan née Clark JI | Formalization of taxon-based constraints to detect ... | 20973947 |
| Dutcher2003 | Dutcher SK | Elucidation of basal body and centriole ... | 12795689 |
| Esko2009 | Esko JD | Eubacteria and Archaea | 20301265 |
| Evans2015 | Evans PN | Methane metabolism in the archaeal phylum ... | 26494757 |
| Goodenough1985 | Goodenough UW | The Chlamydomonas cell wall and its ... | 2864348 |
| Handke2013 | Handke B | The hemolymph proteome of fed and ... | 23840627 |
| Hartman2010 | Hartman AL | The complete genome sequence of Haloferax ... | 20333302 |
| Hawkins2013 | Hawkins M | Accelerated growth in the absence of ... | 24185008 |
| Heidelberg2000 | Heidelberg JF | DNA sequence of both chromosomes of ... | 10952301 |
| Jarrell2012 | Jarrell KF | The archaellum: an old motility structure ... | 22613456 |
| Keeling2010 | Keeling PJ | The endosymbiotic origin, diversification and fate ... | 20124341 |
| Kohler1997 | Köhler S | A plastid of probable green algal ... | 9045615 |
| LePabic2014 | Le Pabic C | Hemocyte morphology and phagocytic activity in ... | 25066968 |
| Liao2021 | Liao Y | Cell division in the archaeon Haloferax ... | 33903747 |
| Lindas2008 | Lindås AC | A unique cell division machinery in ... | 18987308 |
| Lundgren2004 | Lundgren M | Three replication origins in Sulfolobus species ... | 15107501 |
| Mizukami1966 | Mizukami I | Centriole replication. II. Sperm formation in ... | 5950730 |
| MonahanEarley2013 | Monahan-Earley R | Evolutionary origins of the blood vascular ... | 23809110 |
| Mullakhanbhai1975 | Mullakhanbhai MF | Halobacterium volcanii spec. nov., a Dead ... | 1190944 |
| Muller2005 | Müller JA | Genomic analysis of anaerobic respiration in ... | 15716436 |
| Mullineaux2014 | Mullineaux CW | Co-existence of photosynthetic and respiratory activities ... | 24316145 |
| Nakamura2003b | Nakamura Y | Complete genome structure of Gloeobacter violaceus ... | 14621292 |
| Opperdoes1977 | Opperdoes FR | Localization of nine glycolytic enzymes in ... | 142663 |
| Pace2006 | Pace NR | Time for a change | 16710401 |
| Pawlowski2012 | Pawlowski J | CBOL protist working group: barcoding eukaryotic ... | 23139639 |
| Poulhazan2024 | Poulhazan A | Molecular-level architecture of Chlamydomonas reinhardtii's glycoprotein-rich ... | 38307857 |
| Samuel2007 | Samuel BS | Genomic and metabolic adaptations of Methanobrevibacter ... | 17563350 |
| Schafer1999 | Schäfer G | Bioenergetics of the Archaea | 10477309 |
| Volland2022 | Volland JM | A centimeter-long bacterium with DNA contained ... | 35737788 |
| Whitman2009 | Whitman WB | The modern concept of the procaryote | 19168606 |
| Williams2013 | Williams TA | An archaeal origin of eukaryotes supports ... | 24336283 |
| Woese1990 | Woese CR | Towards a natural system of organisms ... | 2112744 |
| Wolfe1992 | Wolfe KH | Function and evolution of a minimal ... | 1332054 |

Ontology terms: 149 CURIEs in `curies_checked.tsv` (OLS4 api/v2, 2026-10-31), and every CURIE in
this program's files, with every label written in Lean, in `curies_review.tsv`. NCBITaxon:2022461 is
labelled "Candidatus Thiomargarita sp. Lot2" on OLS4 and NCBI; NCBI lists "Candidatus Thiomargarita
magnifica" as its unpublished name.

## UNVERIFIED

- E. coli has a bacterial-type flagellum (P08, option d). Not checked; the row is left out.
- Truth from the textbook alone: ribosomes in all prokaryotes (P06); glycolysis in E. coli and human
  cytoplasm (P17, P18); no wall in human cells (C02); no centrioles in Arabidopsis (C03); oxygen kills
  Clostridium (M03); Arabidopsis makes sugars (L03); no chloroplast in human cells (R01).
- Inferred from a checked source, not stated in it: no blood vascular system in sponges
  (Monahan-Earley 2013 dates it to the triploblast ancestor); a closed system in the octopus (Le Pabic
  2014 is on cephalopods, via the cuttlefish); Halobacterium is not a gut resident (Mullakhanbhai 1975,
  on the salt need of halobacteria); the apicoplast does not photosynthesise (Köhler 1997, Keeling
  2010); Sulfolobus acidocaldarius cannot respire anaerobically (Chen 2005 says "aerobic").
- Working definitions: protist as Eukaryota minus Metazoa, Fungi, Embryophyta (in the spirit of
  Pawlowski 2012's title); fish as Vertebrata minus Tetrapoda; lizard as Squamata minus Serpentes.
