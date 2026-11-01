# Program 04: catching annotation errors (after the centrosome)

Written 2026-10-31; reviewed, re-run and corrected 2026-11-01 (section 9). A program of work plus a stress set that
was run. Nothing in the core changed. Dan decides at the points in section 7. Every number here is observed.

## Summary

- **What I did.** I put 10 known error types into copies of 50 real compiled statements (224 mutants, 50
  controls) and ran every check on each. I ran the static checks over all 1,401 live statements and judged 10 flags
  per check. A second agent re-ran it all; every number reproduced.
- **What happened today.** BioLean catches 19 of the 181 false mutants (10 percent): Lean typing 7, the closure's
  clash 10, the sign clash 2, the taxon lint 0. It catches 0 of the 9 controls that are real errors. 109 of the 181
  spread into derived facts.
- **Best by seeded errors: finer relation signatures (C).** 23 more catches; 19 live flags, 10 of 10 sampled real;
  no correct control flagged. The same checks also run as a Lean lint outside the core. A core change would only
  add enforcement: such statements stop compiling.
- **Best by real errors in the live data: GO taxon constraints (D1), outside the core.** About 42 real errors
  against C's 19. Most precise first, C, the obsolete lint, D1 and an is_a check catch 68 of 181. Missed at first:
  inheriting RO's domain and range down sub-properties (C0), 3 more catches.
- **Ontology axioms are not ground truth.** UBERON says no platypus has a tooth; platypuses do grow teeth (Lester
  and Boyde 1986). Read as an axiom at weight 0.9 (D2), it outvotes that paper: the true claim comes out refuted (P3,
  FAIL). "Adult baleen whales have no teeth" cannot be stated at all (I2).
- **What matters now.** Decide C as a lint or a core change; adopt the obsolete and GO lints; use D2 only as a flag
  for a curator. Too general a term (0 of 33 caught) and the wrong term of the right kind (0 of 28) stay nearly
  invisible: only a check of the term against its sentence (F, H) sees them.

---

## Words used here

| word | meaning here |
|---|---|
| mutant | a copy of a real statement with one error put in on purpose |
| equivalent mutant | a mutant that is still true biology ("Bacteria lack a nucleus" made into "Archaea lack a nucleus"). No biology check can object |
| catch | a check flags the mutant and did not flag its control |
| today | checks that already run on statements: Lean typing, the closure's clash and sign clash, `Statement.taxonConsistent` |
| core | the Lean types, constructors, derivation rules and opinion operators in `BioLean/*.lean`, and the data they read (`RO.lean`) |
| lint | a Bool function over a statement, outside the kernel-checked part, like `taxonConsistent` |
| live data | the 1,401 statements the closure loads from rounds 2 and 3 |
| precision | of 10 sampled live flags, how many point at a real error for the reason given |
| BFO sort | continuant (a thing) or occurrent (a process), as OBO relations are typed (Smith et al. 2005). `Rel.accepts` checks only this |
| taxon constraint | a curated rule: a term occurs only in clade T (only_in), or never in T (never_in) |
| ChEBI role | a class under CHEBI:50906 for what a molecule does (pigment, hormone, coenzyme), not what it is (Hastings et al. 2016) |
| prototype row | a case run on a proposed option, not on today's BioLean. Marked "(prototype)", kept out of today's tally |

---

## 1. The question

Decision 4 was the centrosome: "Animal cells also have a centrosome" (cell-structure-and-function-m45432-318)
became "every cell has a centrosome". The closure caught it, because "plant cells lack centrioles" contradicted
it. It is fixed. The general question: how well does BioLean catch annotation errors, and which checks should it
add? That means the catch rate per error type and check, the false alarms on real data, and whether each check
changes the core.

## 2. What each check can see today

Read from the code, confirmed by running, and pinned in `BioLean/Stress/AnnotationErrors.lean`.

| check | where | what it checks | what it cannot see |
|---|---|---|---|
| Lean typing | `Rel.accepts` in `Claim.lean`, reading `RO.domains` and `RO.ranges` | the BFO sort of subject and object, from each relation's own rdfs:domain and range; `Target.activity` needs a protein or function | part_of, has_part and enables declare no sorts in `RO.lean`, so they accept any kinds. Sorts declared on a parent relation are not inherited. ChEBI roles are `Kind.chemical`. Same-kind swaps, signs, taxa |
| clash | `Derivation.clash`; the closure | the same `a r b` derived both as `rel` and `notRel` | anything without a contrary statement in the corpus |
| sign clash | the closure | `a →+ t` and `a →− t` both derived | 47 on correct data, all flagged by the closure as crossing a named loop |
| taxon lint | `Statement.taxonConsistent` | evidence taxon against claim taxon | textbook evidence carries no taxon, so it is always true |
| core data, unread | `Ontology.retired`, `known`, `label?`, `RO.inverseOK` | nothing: only tests and stress files read them (`isACurie` only through `Taxa.isA`) | |
| holes.py screens | `scripts/search/holes.py` | obsolete terms, ontology refutes is_a or part_of, is_a across kinds, unseen patterns | they run on hypotheses, not on statements |
| not in the repo | cached under `/tmp` only | GO computed taxon constraints, UBERON taxon constraints, disjoint_from | |

## 3. The options

Each says plainly whether it changes the core.

### A. Keep what we have
- **Core change.** None. **Right.** No false alarms on the 41 correct controls. **Wrong.** Catches 19 of 181, and 0
  of the 9 real errors among the controls.

### B. Lints over data the core already imports
- **Idea.** Bool functions next to `taxonConsistent`. L1: a used term is retired (`Ontology.retired`). L2: an
  asserted is_a between two imported terms the ontology does not have. L3: an inverse pair between the same two
  terms (`RO.inverseOK`). Prototypes in §4 of the Lean file.
- **Core change.** No.
- **Needs.** Nothing new. But `Ontology.retired` lists only terms in use when `import_isa.py` last ran, so L1 misses
  a newly introduced obsolete term (all 9 seeded ones) until the import reruns.
- **Right.** Reading the OBO files, the obsolete check catches all 9 obsolete mutants and the 3 real obsolete
  controls. It flags 10 live statements, all real. L1 in Lean catches R6 and all three R7 statements. L2 catches the
  pigment-role error, LDL is_a cholesterol, and the reversed is_a mutant. L3 catches round 1's reversal.
- **Wrong.** L2 trusts is_a only, and the ontologies leave out many true is_a links (5 of 10 sampled flags). L3
  cannot say which of the pair is wrong.

### C0. Inherit RO's domain and range down sub-properties (added by the review)
- **Idea.** In OWL a sub-property inherits its parent's domain and range. `RO.lean` keeps only each relation's own.
  So has_output, has_input's range, involved_in and enables check little or nothing. Inherit them at import.
- **Core change.** Core data only. No new constructor, rule, operator or type. `RO.lean` gains rows, so
  `Rel.accepts` rejects more, and those statements stop compiling.
- **Right.** 3 more false mutants caught ("photosynthesis output_of oxygen", "glycolysis input_of glucose", a
  process as an input). No control flagged. It flags 5 live statements: 3 use has_function to a GO molecular
  function, 2 use involved_in from one. RO's own definitions in `data/ro.owl` rule out both.
- **Wrong.** It exposes a tension in the core. BioLean treats GO molecular functions as occurrents (activities, as GO
  does). RO's has_function points to a BFO function, a continuant. Under inheritance, "X has_function" a GO molecular
  function never compiles. Dan must say which reading wins.

### C. Finer relation signatures
- **Idea.** Check kinds per relation, not only the BFO sort. is_a within one kind. part_of, has_part and overlaps
  within one BFO sort. enables needs a function. has_role needs a role. ChEBI roles apart from chemicals.
- **Two forms.**

| form | core change? | what it buys |
|---|---|---|
| C-lint: `Review.sigLint` in the Lean file | no: a Bool over a claim; roles read from the imported is_a closure (`isACurie _ "CHEBI:50906"`) | every catch below; a report, not a block |
| C-core: a new `Kind.role` constructor, and `Rel.accepts` reads a signature table | **yes**: a new constructor of `Kind`; `Rel.accepts` changes | the same catches, enforced: a statement that breaks it cannot compile |

- **Needs.** A small hand-checked table of relation signatures.
- **Right.** The Python twin (`finer_sig`) catches 27 of 181, 23 beyond today. It flags 19 live statements; all
  10 sampled are real ("chlorophyll is_a biological pigment", "cytokinesis has part cell plate"). It flags no
  correct control. The Lean lint flags 25 of the 2,071 compiled statements (21 in round 2, 4 in round 3). The 21 I
  read fall into four patterns: a ChEBI role used with is_a, is_a across kinds, parthood between a process and a
  thing, enables to a process. All break the ontologies' own rules.
- **Wrong.** It misses same-kind errors. C-core would stop the 25 compiled statements compiling until fixed (the 19
  live ones, and 6 the closure does not load). Using a role as
  a class of molecules ("the testes secrete androgens") is common: 34 more live statements do it (13 relations, 21
  effects). I left those unchecked: a convention for Dan to decide.

### D. Taxon constraints from GO and UBERON
- **Idea.** D1: a lint. The object's only_in and never_in against the claim's taxon (stated scope) or, for a claim
  with none, where its subject can occur (ceiling scope). Deegan et al. 2010 built this check for GO annotations.
  D2: read each never_in as a negative statement ("no baleen whale has a tooth") with `.ontologyAxiom` evidence;
  the existing is_a law and `clash` do the rest.
- **Core change.** No. D1 is a lint or a script. D2 is data in existing constructors. But D2's effect depends on the
  `.ontologyAxiom` weight (0.9), a value in the core's default `EvidenceModel`.
- **Needs.** GO's computed constraints; UBERON's own (Mungall et al. 2012). uberon.obo carries 1,487 CL ids, but
  only 37 have a taxon axiom of their own. NCBITaxon lineages.
- **Right.** Stated scope: 8 catches (7 beyond today), 0 live flags. Ceiling scope (GO): 17 catches, 52 live flags, 8
  of 10 real: it found the thylakoid and Calvin-cycle errors. D2 in Lean (P1) turns "all mammals have teeth" from
  SILENT to contested.
- **Wrong.** UBERON's ceiling check is noisy (83 flags, 3 of 10 real). Constraints ignore life stage, and some are
  wrong. UBERON says calcareous tooth is never in Ornithorhynchus, citing a paper on electroreception. But living
  platypuses grow enamelled teeth (Lester and Boyde 1986 imaged developing and erupted ones). Under D2 that axiom
  outvotes the paper (P3, FAIL). UBERON also says never in Mysticeti, yet baleen whale fetuses grow tooth germs
  that are "sometimes mineralized" (Thewissen et al. 2017). So P1's axiom is too strong, and the true form, for
  adults only, cannot be stated (I2).

### E. Ontology axioms as checks
- **Idea.** Run holes.py's `ontology_says` and disjoint_from on statements. **Core change.** No.
- **Right.** 4 catches. Disjointness works when it applies: S4 ("the basal ganglia are ganglia") and S5 ("the
  spinal cord is part of the brain") are flagged.
- **Wrong.** Only 29 disjoint pairs exist among the terms the book uses; no mutant hit one. Live precision 5 of 10.

### F. Text against term
- **Idea.** Compare the mention with the term's label and synonyms, or re-ground it with OAK or Gilda (STATUS
  lesson 12a; Gyori et al. 2022). **Core change.** No.
- **Right.** The only check that sees equivalent mutants (20 of 43) and wrong terms of the right kind. My crude lint
  catches 49 of 181 and both insulin controls.
- **Wrong.** 161 live flags, 0 of 10 real: paraphrase, anaphora ("It"), plurals. As built it is noise.

### G. Unseen relation patterns
- **Idea.** holes.py's mode declarations: flag a pattern seen nowhere else. **Core change.** No.
- **Right.** 54 catches, mostly reversals and wrong kinds. **Wrong.** 47 live flags, 2 of 10 real.

### H. A second annotation
- **Idea.** Annotate each sentence twice, independently; flag disagreement. **Core change.** No.
- **Not tested.** It could see equivalent mutants. A model call per statement.

## 4. The stress set

**Bases.** 50 real compiled statements (`data/stress/04/bases.tsv`): 32 relations, 11 negations, 7 effects; 13
carry a context and 9 a quantifier. They include the centrosome, "all mammals have teeth", the derives_from
sentence, the insulin statements, and the somatic-cell statement.

**Operators.** Each makes one change to a copy of the record the emitter reads. Copies live in `/tmp/biolean-04`;
the real claims are untouched. This mix is my error model (DeMillo et al. 1978; Jia and Harman 2011), and it
shapes the ranking: 30 E6 mutants favour C.

| type | how it is seeded | false | equiv. or unclear |
|---|---|---:|---:|
| E1 context dropped | clear every context field (the centrosome bug) | 9 | 2 |
| E2 quantifier strengthened | some or most to every ("all mammals have teeth") | 9 | 0 |
| E3 subject too general | CL term to "cell"; else the nearest is_a ancestor the textbook uses | 33 | 7 |
| E4 direction reversed | the RO inverse in the same order (as round 1 did); else swap | 35 | 8 |
| E5 wrong CURIE, right kind | a live id a few digits away (the area postrema slip) | 28 | 22 |
| E6 wrong kind | a term of another kind named after it (centriole to centriole assembly) | 30 | 0 |
| E7 sign flipped | pos to neg | 7 | 0 |
| E8 taxon swapped | Metazoa and Viridiplantae, Bacteria and Archaea, and so on | 12 | 2 |
| E9 obsolete term | an obsolete id whose replaced_by is the current term | 9 | 0 |
| E10 negation lost | notRel to rel | 9 | 2 |

**Judgement.** I judged each mutant by hand (`judgements.tsv`): false (181), equivalent (36), unclear (7).
Equivalents and unclear ones stay in the case table but out of catch rates, as mutation testing does. Most
negations reversed in direction are vacuously true: "RNA is not part of thymine".

**Curated cases** (`cases.tsv` rows R, I, S, P, C). Today's marks, then prototype rows.

| id | error | today | outside the core | mark |
|---|---|---|---|---|
| R1 | centrosome: context dropped | clash, contested in Lean | GO ceiling | PASS |
| R2 | all mammals have teeth | silent | UBERON never_in; P1 | SILENT |
| R3 | round 1: derives_into for derives_from | silent | mode; L3 | SILENT |
| R4 | PR:000009054 (preproinsulin) for insulin | silent | label lint | SILENT |
| R5 | UBERON:0002163 for area postrema | silent | label lint | SILENT |
| R6 | obsolete CL:0002371 somatic cell | silent | obsolete; L1 | SILENT |
| R7 | obsolete CL:0000548 animal cell, 3 statements | silent | obsolete; L1 | SILENT |
| R8 | every thylakoid part of a chloroplast | silent | GO ceiling | SILENT |
| R9 | the Calvin cycle only in chloroplast stroma (cyanobacteria run it too) | silent | GO ceiling | SILENT |
| R10 | chlorophyll is_a pigment (a role) | silent | L2; C; C-lint | SILENT |
| R11 | "some prokaryotes have pili" as every | silent | GO ceiling | SILENT |
| R12 | a complex part_of a process | silent | mode; C; C-lint | SILENT |
| R13 | RuBisCO enables carbon fixation (a process) | silent | mode; C; C-lint | SILENT |
| R14 | LDL is_a cholesterol (the sentence is loose too) | silent | L2; C; C-lint | SILENT |
| R15 | "sexually reproducing" dropped | silent | mode, for an unrelated reason | SILENT |
| R16 | "before mitosis or meiosis": one disjunct kept | silent | GO ceiling | INEXPRESSIBLE |
| I1 | teeth, except baleen whales and anteaters | cannot be stated | | INEXPRESSIBLE |
| I2 | adult baleen whales have no teeth (fetuses have tooth germs) | cannot be stated | | INEXPRESSIBLE |
| S1 to S3 | taxon lint on literature-style statements (synthetic) | right | | PASS |
| S4, S5 | basal ganglia; spinal cord in brain (synthetic) | silent | disjointness | SILENT |
| S6 | rounds 1 and 2 of m45432-261 side by side | silent, no clash | L3 | SILENT |
| C1 | 47 sign clashes on correct data | all flagged as loop artefacts | | PASS |
| P1 | D2: never_in read as negative statements | | contested (but the axiom is too strong, I2) | PASS (prototype) |
| P2 | C: finer signatures, on the mutants | | 27 of 181 | PASS (prototype) |
| P3 | D2 on a wrong axiom: platypus teeth | | the true claim is refuted | FAIL (prototype) |
| P4 | C0: inherited RO sorts | | 3 catches, 5 live flags | PASS (prototype) |

R7 to R16 are real errors this program found. R1 to R6 were known. **Tally of the 303 rows.** Today: 65 PASS, 0
FAIL, 231 SILENT, 3 INEXPRESSIBLE (299 rows). Prototype rows: 3 PASS, 1 FAIL. Today's 65 PASS are the 41 correct
controls, the 19 caught mutants, and R1, S1 to S3 and C1. Today's system never gives a wrong answer here; it is
silent instead.

## 5. Results observed

### Catch rate per error type

False mutants only. "Recommended" is today plus C, the obsolete lint, the GO ceiling check and the ontology check.

| type | false | today | recommended | every check | spread into derived facts |
|---|---:|---:|---:|---:|---:|
| E1 context dropped | 9 | 2 | 3 | 3 | 8 |
| E2 quantifier strengthened | 9 | 2 | 4 | 5 | 5 |
| E3 subject too general | 33 | 0 | 5 | 24 | 24 |
| E4 direction reversed | 35 | 4 | 8 | 32 | 18 |
| E5 wrong CURIE, right kind | 28 | 0 | 3 | 25 | 20 |
| E6 wrong kind | 30 | 3 | 24 | 28 | 13 |
| E7 sign flipped | 7 | 2 | 2 | 2 | 6 |
| E8 taxon swapped | 12 | 3 | 4 | 4 | 5 |
| E9 obsolete term | 9 | 0 | 9 | 9 | 3 |
| E10 negation lost | 9 | 3 | 6 | 7 | 7 |
| **all** | **181** | **19** | **68** | **139** | **109** |

### Per check

| check | catches (of 181) | live flags (of 1,401) | live precision | core change? |
|---|---:|---:|---:|---|
| Lean typing (today) | 7 | - | - | is core |
| closure clash (today) | 10 | 0 | - | no |
| sign clash, off any loop (today) | 2 | 0 | - | no |
| sign clash, on a named loop (not counted) | 11 | 47 | 0 errors | no |
| taxon lint (today) | 0 | 0 | - | no (lint) |
| C finer signatures | 27 | 19 | 10/10 | as a lint no; as `Kind.role` yes |
| C0 inherited RO sorts | 3 | 5 | 5 judged by RO's definitions | core data only |
| B obsolete term | 9 | 10 | 10/10 | no |
| D1 GO, ceiling scope | 17 | 52 | 8/10 | no |
| D1 GO, stated scope | 6 | 0 | - | no |
| E ontology refutes is_a | 4 | 36 | 5/10 | no |
| D1 UBERON, ceiling scope | 3 | 83 | 3/10 | no |
| D1 UBERON, stated scope | 2 | 0 | - | no |
| G unseen pattern | 54 | 47 | 2/10 | no |
| F label lint | 49 | 161 | 0/10 | no |
| E disjoint_from | 0 | 0 | - | no |
| is_a across kinds | 0 | 1 | 1/1 | no |

Order to adopt, most precise first (`greedy.tsv`): C takes today's 19 to 42; the obsolete lint to 51; the GO ceiling
check to 64; the ontology check to 68. C0 is not in that run; its 3 catches are beyond today and beyond C.

### Real errors found in the live data (added by the review)

The mutants are one error model. The live flags are the other measure. Estimate = flags times sampled precision;
the range is the 95 percent Wilson interval on 10 samples. The sets barely overlap: C and the ontology check
share 12 statements; any other pair shares at most 4.

| check | live flags | real errors (estimate) | range | false alarms (estimate) |
|---|---:|---:|---:|---:|
| D1 GO, ceiling scope | 52 | 42 | 25 to 49 | 10 |
| D1 UBERON, ceiling scope | 83 | 25 | 9 to 50 | 58 |
| C finer signatures | 19 | 19 | 14 to 19 | 0 |
| E ontology refutes is_a | 36 | 18 | 9 to 27 | 18 |
| B obsolete term | 10 | 10 | all judged | 0 |
| G unseen pattern | 47 | 9 | 3 to 24 | 38 |

So on real data D1 (outside the core) finds the most. Its errors are softer: mostly a generic GO term where the book
means the eukaryote one, or a dropped "some". C's are hard kind errors.

### Controls

- The 41 correct controls: no check flagged any of them.
- The 9 real-error controls (insulin twice, three obsolete terms, thylakoid, Calvin cycle, the pigment role, the
  zygote condition): today 0 of 9. Outside checks flag all 9, but 8 for the right reason: the zygote one is flagged
  by the mode check for an unrelated reason.

### What I learned

1. **Lean typing is precise but coarse.** It rejected 7 of 274 compiled claims, all real errors. It lets through
   any kinds on part_of, has_part and enables, because `RO.lean` declares no sorts for them and does not inherit a
   parent's.
2. **The clash needs a contrary sentence.** It caught the centrosome because the book also says plant cells lack
   centrioles. Most errors have no contrary sentence. Taxon constraints can supply one (P1), and can be wrong (P3).
3. **Most sign-clash catches were loop artefacts.** 11 of the 13 mutants caught by a new sign clash caught it only
   through a named loop. A correct new statement in that loop would do the same. I count only off-loop clashes.
4. **Errors spread.** 109 of 181 false mutants feed derived facts. "All cells have ribosomes" feeds 135.
5. **Generic GO terms make many sentences false.** GO:0009579 thylakoid includes cyanobacteria; GO:0005694
   chromosome includes bacterial ones. The book means the eukaryote term.
6. **Ontology constraints are evidence, not truth** (review). Of UBERON's three never_in_taxon constraints on
   calcareous tooth within mammals, two are contradicted at some life stage (platypus, baleen whale). D2 at weight
   0.9 lets one wrong axiom refute a true claim.

## 6. Experiments for later

Each exit test is written first. Cost is in agent tasks.

| id | option | exit test | cost |
|---|---|---|---|
| X1 | B | A Lean lint over every R2 and R3 statement flags exactly the 10 live obsolete-term statements; each gets a fix | 1 |
| X2 | C | Start from `Review.sigLint`: judge all 25 flagged statements, at least 90 percent real. Only then, in `BioLean/Proto/`, a `Kind.role` and a signature table: the 7 current rejections stay; at least 20 of the 30 E6 mutants rejected | 2 to 3 |
| X3 | D1 | A GO taxon-constraint lint script: catches R8, R9, R11; precision at least 70 percent on a fresh sample of 30 live flags | 1 to 2 |
| X4 | D2 | never_in for the used GO and UBERON terms loaded as negative statements: round 2's teeth claim clashes; round 3 adds no clash; every new clash judged, with the ontology side checked against a paper (P3 is the first) | 2 |
| X5 | F | Re-ground each mention with OAK, then Gilda; flag same-namespace disagreements: at least half of the E3 and E5 mutants caught, live precision at least 50 percent on 20 flags | 2 |
| X6 | H | A second annotation of the 50 bases disagrees with at least 80 percent of mutants and at most 10 percent of controls | 2 to 3 |
| X7 | any | Rerun this harness on the next annotation round with no code change | 1 |
| X8 | C0 | `scripts/ro/` inherits domain and range in a copy of `RO.lean` under `BioLean/Proto/`; the 5 live statements and 3 mutants are rejected and nothing else; Dan rules on has_function to GO molecular functions | 1 |

## 7. What would change the decision

- **For C.** If X2 shows more than 10 percent of `sigLint` flags are correct statements, keep C as a lint only.
- **For C0.** If Dan reads GO molecular functions as BFO functions, change `Kind.function`'s sort instead; that is a
  core change and touches every function claim.
- **For D.** If X4's clashes are often the ontology's fault (like P3), keep D1 as a lint and drop D2, or let a D2
  clash raise a flag for a curator and never fuse.
- **For F.** If X5 cannot reach 50 percent precision, E3 and E5 errors need H, not F.
- **For the order.** If the next round makes fewer kind errors, C is worth less and D1 more. The live-data table
  already ranks D1 first.

### Where this sits on the roadmap

- **M5.** Its exit asks for one inconsistency a curator confirms. P3 is a candidate (UBERON's platypus constraint
  against Lester and Boyde 1986). So is GO:0019253: GO defines the Calvin cycle as "in the chloroplasts of C3
  plants", but its taxon constraints allow bacteria, and cyanobacteria run it (Huffine et al. 2023). Nothing was
  sent anywhere.
- **M6.** P3 is a weights question: should one ontology axiom outweigh a direct observation?
- **M8.** Imports at scale need this harness as a gate. X7 makes it one.

## 8. Limits

- The mutants are my error model; the live-data table is the check on it.
- Hand judgements are one judge's; those from memory are under UNVERIFIED. Samples are 10 flags per check.
- The closure copy reproduces the committed closure's 2,223 derived facts. It loads 1,401 statements where the
  committed `data/search/closure.json` says 1,402. Run on the unmodified claims, the copy also gives 1,401, so the
  difference is in the committed file, not the copy.
- Calling R4 an error is a judgement: PR's gene-level class covers mature insulin too, so it is too general, not
  wrong.
- The taxon-constraint check is mine; how I read scope is not curated. The ceiling flags for R8 list some wrong
  reasons (Archaea, Amoebozoa) next to the right one (Bacteria).
- The scripts read ontology files cached outside this program's directory (`/tmp/obo`, `/tmp/biolean-taxcon`). If
  those go, the run cannot be repeated without new downloads.
- RO has obsoleted only_in_taxon (RO:0002160, replaced by RO:0002162), but uberon.obo still has 208 such axioms next
  to 4,979 in_taxon ones. My reader treats both as only-in.
- Pins: Lean's verdict on all 274 claims (`MutantsEmitted.lean`); 88 in `AnnotationErrors.lean`; every row's mark
  in `expected_cases.tsv` and `expected_marks.tsv` (the `--check` runs).

## 9. Review (2026-11-01)

An independent agent re-ran both Lean files and every script. All numbers above reproduce. What it changed:

| problem found | fix |
|---|---|
| R8, R9, R11 to R16 and one R7 statement were not pinned | Lean pins (§5 of the Lean file); `--check` on every case row |
| "C is the best addition, and a core change" | C also runs as a lint outside the core; D1 finds more real errors |
| option C0 was missing; the enables gap was misexplained | added; enables declares no sorts at all |
| P1's axiom is false for fetuses; D2 untested on a wrong axiom | caveat; I2 (INEXPRESSIBLE), P3 (FAIL) |
| prototype rows counted as today's PASS; the C1 row said "0 sign clashes" | marked "(prototype)"; 47 on loops, 0 off |
| five wrong small numbers or quotes (equivalents, 9 of 9, role count, CL count, R14 quote); one unused reference | corrected; dropped |

## 10. Files

| file | what |
|---|---|
| `BioLean/Stress/AnnotationErrors.lean` | the Lean half, 88 pins, about 9 s |
| `data/stress/04/lean/MutantsEmitted.lean` | every control and mutant as emitted; Lean's verdict pinned |
| `scripts/stress/closure_mutants.py` | copy of `scripts/search/closure.py`, writing to `--out` |
| `scripts/stress/mutants_*.py` | ontology data and checks (`onto`, `lib`), run, compile, score, sample, order, cases, checks of ids (`verify`, `review`) |
| `data/stress/04/cases.tsv` | 303 cases: 29 curated, 50 controls, 224 mutants |
| `data/stress/04/` other files | results, live scan and judgements, expected marks, review checks |

Rerun, from the repo root: `python3 -I scripts/stress/mutants_run.py`, then `mutants_lean.py`,
`mutants_score.py --check`, `mutants_sample.py`, `mutants_greedy.py`, `mutants_review.py inherit`,
`mutants_cases.py --check`; and `lake env lean` on both Lean files.

## 11. References

Papers, checked on Europe PMC or Crossref on 2026-11-01 (`review_refs.tsv`; title, first author and year match):

- Meredith RW et al. 2009. Molecular decay of the tooth gene Enamelin (ENAM) mirrors the loss of enamel in the
  fossil record of placental mammals. PLoS Genet. PMID 19730686.
- Thewissen JG et al. 2017. Evolutionary aspects of the development of teeth and baleen in the bowhead whale. J
  Anat. PMID 28070906.
- Lester KS, Boyde A. 1986. Scanning microscopy of platypus teeth. Anat Embryol. PMID 3706773.
- Huffine CA et al. 2023. Role of carboxysomes in cyanobacterial CO2 assimilation: CO2 concentrating mechanisms and
  metabolon implications. Environ Microbiol. PMID 36367380.
- Pettigrew JD. 1999. Electroreception in monotremes. J Exp Biol. PMID 10210685 (the source UBERON cites for its
  platypus constraint).
- Deegan (née Clark) JI et al. 2010. Formalization of taxon-based constraints to detect inconsistencies in
  annotation and ontology development. BMC Bioinformatics. PMID 20973947.
- Mungall CJ et al. 2012. Uberon, an integrative multi-species anatomy ontology. Genome Biol. PMID 22293552.
- Smith B et al. 2005. Relations in biomedical ontologies. Genome Biol. PMID 15892874.
- Hastings J et al. 2016. ChEBI in 2016: improved services and an expanding collection of metabolites. Nucleic Acids
  Res. PMID 26467479.
- Gyori BM et al. 2022. Gilda: biomedical entity text normalization with machine-learned disambiguation as a
  service. Bioinform Adv. PMID 36699362.
- DeMillo RA et al. 1978. Hints on test data selection: help for the practicing programmer. Computer.
  doi:10.1109/C-M.1978.218136.
- Jia Y, Harman M. 2011. An analysis and survey of the development of mutation testing. IEEE Trans Softw Eng.
  doi:10.1109/TSE.2010.62.

Data: OpenStax Concepts of Biology (2013), local copy in `data/textbook`. go.obo 2026-07-26; uberon.obo
2026-10-01; cl-basic.obo 2026-06-08; chebi_lite.obo 256; pr.obo 73.1 (versions as recorded in
`data/ontology/isa.json`); GO computed taxon constraints and groupings (cached 2026-10-28); NCBI taxonomy by
E-utilities efetch (2026-10-30). Every CURIE in the program's files was re-checked on OLS4 on 2026-11-01
(`review_curies.tsv`): all found; the 9 obsolete ones are obsolete on purpose (seeded mutants, or real errors found).

## 12. UNVERIFIED

- Judgements from my own knowledge, not a source: Mycoplasma lacks a cell wall; red blood cells also carry carbon
  dioxide (B19-E5 equivalent); most archaea have a cell wall (B47-E8); budding and parthenogenesis give organisms
  not from a zygote (R15); centrioles in animal male meiosis (B41-E5, left unclear).
- That the 5 C0 flags are relation misuse rests on RO's definitions as read in `data/ro.owl`, not on a curator.
- That echidnas never have a true tooth (UBERON's Tachyglossidae constraint) was not checked.
- Meredith 2009's abstract names only the orders with toothless or enamelless taxa (Tubulidentata, Pholidota,
  Cetacea, Xenarthra). That these are baleen whales, pangolins and anteaters is from memory.
- The cached GO and UBERON taxon-constraint files carry no release date in their headers. I used the cache from
  2026-10-28 as found.
