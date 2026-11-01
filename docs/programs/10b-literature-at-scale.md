# Program 10b: literature at scale (M8)

Written 2026-11-01, then reviewed and corrected the same day (section 9). Decision 10, part 2 of 3.
This is a program of work, not a decision. Nothing in the core changed. Dan decides at the points in
section 8.

Files: `BioLean/Stress/Literature.lean` (52 cases, prototypes in `BioLean.Proto.Literature`; compiles
in about 8 s), `data/stress/10b/` (`cases.tsv` is the full case table), `scripts/stress/literature_*.py`
(downloads, parsers, loss measures, checks, table writer).

## Summary

- **What I did.** Took 52 curated statements (SIGNOR 18, GO-CAM 20, Reactome 9, GOA 5) about the
  textbook's hormones, ions and ATP synthase. Mapped each to a BioLean statement with its PMID, compiled
  them, and compared them with 13 textbook statements. Measured mapping loss on the whole sources. Ran
  the M8 exit question, "does metformin extend lifespan in humans?", in Lean.
- **What happened.** 18 PASS, 14 FAIL, 19 SILENT, 1 INEXPRESSIBLE. No curated statement fused with a
  textbook one: the textbook talks physiology (blood levels), the sources talk molecules (receptors, G
  proteins), and the ids differ (the textbook's "insulin" is preproinsulin).
- **The core is rarely the blocker.** All 14 FAILs and 9 of the 19 SILENTs have a fix outside the core
  (importer, data, a report check). 11 cases need a core change: bridge rules (protein to function,
  activity to amount, transport to effect), a type for sets (R05), and a rule across organism
  conditions (M07).
- **Curated evidence is weaker than its label.** 5 of 43 cited papers are about another protein (S07:
  a rat V1a receptor paper for the human V2 receptor). SIGNOR has metformin raising G6PC1, against its
  own stored sentence; PubTator3 says the opposite 9 times to 1.
- **Mapping loss.** 25 of the 52 stress-set statements map without loss. Whole sources: SIGNOR 28
  percent of 33,381 human edges, GO-CAM 80 percent of facts (65 percent with a PMID), Reactome 8
  percent of reactions, GOA 49 percent of annotations.
- **What matters now.** The core's M8 answer is "unsupported" (belief 0.12, 3 PMIDs), resting only on
  mouse data. Next: importer M1 and evidence checks, all outside the core (E1 to E3). The review fixed
  3 records that did not match their source and 4 marks (section 9).

## Words used here

| word | meaning here |
|---|---|
| curated source | a database where people enter statements by hand: SIGNOR, GO-CAM, Reactome, GOA |
| importer | a script that turns a source's records into BioLean `Statement`s; outside the core |
| M0 | the plain importer this program runs (rules in the header of `Literature.lean`) |
| M1 | M0 plus fixes that stay outside the core: id maps, evidence-kind rules |
| mapping loss | the BioLean claim says less than, more than, or something other than the source |
| fuse | two statements with the same claim combine their evidence (`Derivation.both`) |
| meets | the curated and the textbook statement have the same subject id |
| bridge rule | a rule that links two levels, e.g. a protein and the GO function it enables |
| precursor | a protein as made (preproinsulin, pro-glucagon), before it is cut into hormones |
| PR, BTO, ECO | Protein Ontology; BRENDA Tissue Ontology (SIGNOR's cell context); Evidence and Conclusion Ontology (GO-CAM's evidence codes) |
| PASS / FAIL | right conclusion / wrong conclusion |
| SILENT | no conclusion where one is due |
| INEXPRESSIBLE | the case cannot be stated in the system |
| core change | a new `Claim` constructor, `Derivation` rule, opinion operator, or type in `BioLean/*.lean` |
| outside the core | data, annotation, importer scripts, report checks (lints) |

## 1. The question

ROADMAP M8: curated sources first, text-mined relations second, LLM extraction aimed at the gaps. Exit
test: "does metformin extend lifespan in humans?", answered end to end with a verdict and an axiom
list. So: what does each source offer, how much is lost in mapping it, does BioLean see when a curated
and a textbook statement are about the same thing, and what would the exit question need?

## 2. What each source offers

| source | what it holds | used here | licence | maps to |
|---|---|---|---|---|
| SIGNOR | signed causal edges (activity or quantity), mechanism, residue, BTO cell context, evidence sentence, PMID | NDEx release 26-Nov-2025: 33,381 human edges; 473 touch the stress entities | CC BY-SA 4.0 (NDEx record) | `Claim.effect a s (activity b)` or `(amount b)` |
| GO-CAM | models: activities `enabled_by` gene products, joined by RO causal relations; ECO code per fact | 29 models for 18 proteins, 847 facts | CC BY 4.0 (GO policy page) | signed facts to `Claim.effect`; others to `Claim.rel` |
| Reactome | reactions with inputs, outputs, compartments; an inferred-from-species flag; PMIDs | release 98: 137 human reactions | CC0 (licence page) | `Claim.rel has_input` / `has_output` |
| GOA | protein to GO term annotations, evidence code, reference, extensions, NOT | 1,705 human annotations for 18 proteins (QuickGO, 2026-11-01) | CC BY 4.0 (GO policy) | `Claim.rel enables / involved_in / located_in`; NOT to `Claim.notRel` |
| PubTator3 | text-mined relations (treat, cause, positive and negative correlate) | local bulk file, release 2026-10-06, 40.4M relations | public domain (NCBI notice) | `textMined` evidence; sign from the relation type |

- **SIGNOR** gives a sign and a sentence. It loses the compartment, often the target type, and the
  species of the experiment (M01: rat muscle on a human protein).
- **GO-CAM** gives the most exact facts. They are about individuals in a model, not classes.
- **Reactome** gives compartments. Most entities are complexes and sets with no OBO id.
- **GOA** gives coverage and evidence codes, but no causal sign.
- **PubTator3** gives size, but no sentence and no lifespan or normal-ageing entity (section 6).

## 3. The options

"Core?" says whether the option changes the formal system. All prototypes live in
`BioLean.Proto.Literature` inside `Literature.lean`, not in `BioLean/`.

| | idea | core? | needs | right | wrong |
|---|---|---|---|---|---|
| A | plain importer M0: reuse biolib entities by curie, one `curatedDb` item per PMID | no | four importers, a curie registry | cross-source fusion (S01, S05, S06); right signs (G03); cheap | 14 FAILs; never meets the textbook; overweights inferred, pooled and wrong-paper evidence (R07, M05, G07) |
| B | importer M1: id maps and evidence rules as data | no | maps for complexes, chains, charge states, BTO, ZFA; "inferred" as `crossSpecies`; `Evidence.taxon` filled | computed: S10, R07, M05 flip; the existing `taxonConsistent` lint flags M01; argued: G09, G10, R01, R06, S08, S11, G11, R04 | hand-made maps keep growing; a charge-state map hides chemistry |
| C | evidence check: does the cited paper state this edge with this sign? | no | abstracts; an LLM or curator pass; this gold set | S07, G06, G07, S12; 3 more wrong papers | abstracts often lack the fact (S03, S08); LLM errors; cost |
| D | bridge rules: `enablesInherit` (P enables F, F →s t ⊢ P →s t), `widenProcess` (a →+ p, p is_a q ⊢ a →+ q), activity to process, `has_output` to amount, two effects to `mediatedBy` | yes: new `Derivation` rules | is_a and enables facts (PR, GO, GOA) | computed: S09 flips; argued: R02, R08, S03 | G02 does not flip; every bridge spreads errors (S02); `widenProcess` is unsound for negative signs |
| E | identity: entities equal by curie | yes for identity (`Entity` drops or looks up its label); no for is_a, which can come in as `rel isA` statements (`insIsa`) | a label registry, or the type change | Y03; Y04 by data | hides mislabels (preproinsulin labelled "insulin") |
| F | sign clash for effects | no: a check from the existing `fuse` and `negate`, like `Derivation.clash` (prototype `effectClash`); yes only if made a rule | nothing | computed: Y01 contested (0.44 / 0.44) | false alarms if context is dropped (S04 against m45537-199); feedback loops (program 02b) |
| G | sets: a union of entities | yes: a new type, maybe a new `Claim` form | Reactome set members | R05, and R03's complexes | "any of" (DefinedSet) and "one of, not known which" (CandidateSet) are different unions |
| H | GO-CAM as models: a model becomes a context, so instance facts stay true | yes (a model slot) or no (import only class-safe facts) | model ids | G09, G10 | a model slot is a second context system next to `Ctx` |
| I | text-mined second: PubTator3 as `textMined` items | no | the local bulk file | computed: S12 from established to contested (0.48 / 0.42) | no Aging or Longevity relations; reviews among the items; no sentence |
| J | LLM extraction aimed at gaps | no | the corpus, grounding by lookup, quote checks | the M8 lifespan outcomes (M03 to M05); the sign GO lacks for the worm AMPK step (M08) | cost; precision; must never write ids itself |
| K | transport across an organism condition (type 2 diabetes to no diabetes) | yes: a rule like `transport` | a cross-condition evidence item | M07 | this is where confounding hides (Keys 2022) |

**The formal system, in short.** A, B, C, F, I and J live outside the core. The candidate core changes
are D (new `Derivation` rules), E (`Entity` identity), G (a type for sets), H (a model slot) and K (a
cross-condition rule). This program recommends none of them yet (section 8).

## 4. The stress set

52 cases: 48 on real records or papers, Y01 and Y02 synthetic, Y03 and Y04 core probes. Letters: S
SIGNOR, G GO-CAM, R Reactome, O GOA, T textbook grounding, Y synthetic or core, M the M8 question. "Fix
in" says where a non-PASS case's fix lives. Every record was found again in its source
(`records_checked.tsv`, 56 of 56). Full table: `data/stress/10b/cases.tsv`.

| id | probes | mark | fix in |
|---|---|---|---|
| S01 | INS activates INSR, two sources, one claim | PASS | |
| S02 | relocalization read as amount: "insulin raises glucose" | FAIL | outside |
| S03 | Ca2+ as the mediator of glucose to insulin | SILENT | core |
| S04 | alpha-D-glucose raises GCG (it is GLP-1, not glucagon) | PASS | |
| S05 | glucagon activates GCGR, two sources | PASS | |
| S06 | PTH activates PTH1R, two sources | PASS | |
| S07 | AVP to V2R backed by a rat V1a paper | FAIL | outside |
| S08 | vasopressin: CHEBI:9937, CHEBI:34543, PR:P01185 | SILENT | outside |
| S09 | SCN1A (protein) vs the textbook's GO function | SILENT | core |
| S10 | ATP synthase as a SIGNOR complex with no OBO id | SILENT | outside |
| S11 | protons activate a complex: M0 drops it | SILENT | outside |
| S12 | metformin raises G6PC1: sign opposite to its own sentence | FAIL | outside |
| S13 | an edge of unknown sign as `Claim.rel` | PASS | |
| S14 | two chain links from one screen paper | SILENT | outside |
| G02 | insulin to GLUT4 chain against the textbook's glucose uptake | SILENT | core |
| G03 | Ca2+ to CaSR to Gi to PTH: the sign | PASS | |
| G04 | the same chain against the textbook's PTH claim | SILENT | core |
| G05 | PTH to TRPV5: stops before blood calcium | SILENT | core |
| G06 | PKA to TRPV5 backed by a MAP2c paper | FAIL | outside |
| G07 | AVP to V2R fused, with S07's wrong paper | FAIL | outside |
| G08 | calcitonin to its receptor; model ends at cAMP | PASS | |
| G09 | "glucose located_in cytoplasm" read as a universal | FAIL | outside |
| G10 | zebrafish anatomy term in a human model | FAIL | outside |
| G11 | ATP(4-) vs ATP; a generic enabler; no PMID | SILENT | outside |
| G12 | unsigned "causally upstream of" vs a signed claim | SILENT | core |
| R01 | GLUT4 reaction read as all D-glucose transport | FAIL | outside |
| R02 | GLUT2 glucose export from the liver | SILENT | core |
| R03 | insulin binds its receptor, as complexes | SILENT | core |
| R04 | ATP(4-) in the matrix vs the textbook's ATP | SILENT | outside |
| R05 | sets of ligands and receptors | INEXPRESSIBLE | core |
| R06 | the glucagon peptide read as pro-glucagon | FAIL | outside |
| R07 | a reaction inferred from mouse counted as nine human records | FAIL | outside |
| R08 | sodium enters the cell, with compartments | SILENT | core |
| O01 | SCN1A enables sodium channel activity | PASS | |
| O02 | PTH hormone activity with an extension, as a refinement | PASS | |
| O03 | worm aak-2 involved in adult lifespan (no sign) | PASS | |
| O04 | CALCR "NOT calcitonin binding" from an isoform paper | FAIL | outside |
| T01 | "insulin" is preproinsulin | FAIL | outside |
| T02 | "glucagon" is human pro-glucagon | FAIL | outside |
| Y01 | same claim, opposite sign | SILENT | outside |
| Y02 | the same record entered as refuting evidence | PASS | |
| Y03 | one curie, two labels (`Taxa.human` vs "humans") | SILENT | outside |
| Y04 | `PR:P01308` cannot be encoded for the core's is_a lookup | SILENT | outside |
| M01 | metformin activates AMPK | PASS | |
| M02 | metformin inhibits complex I | PASS | |
| M03 | metformin and lifespan in worms | PASS | |
| M04 | metformin and lifespan in mice: conflicting | PASS | |
| M05 | metformin and survival in type 2 diabetes | FAIL | outside |
| M06 | mouse to human by `transport` | PASS | |
| M07 | diabetes to no diabetes: no rule | SILENT | core |
| M08 | a mechanistic route to lifespan: no chain, rightly | PASS | |
| M09 | the M8 exit answer | PASS | |

## 5. Results observed

All results come from running `Literature.lean`, each pinned with `#guard` or `example`;
`literature_cases.py` reads the printed rows. Lean's exact rationals are shown to two places.

### 5.1 Marks

| | PASS | FAIL | SILENT | INEXPRESSIBLE |
|---|---:|---:|---:|---:|
| SIGNOR (S) | 5 | 3 | 6 | 0 |
| GO-CAM (G) | 2 | 4 | 5 | 0 |
| Reactome (R) | 0 | 3 | 4 | 1 |
| GOA (O) | 3 | 1 | 0 | 0 |
| textbook, synthetic, core (T, Y) | 1 | 2 | 3 | 0 |
| M8 exit (M) | 7 | 1 | 1 | 0 |
| **all 52** | **18** | **14** | **19** | **1** |
| fix outside the core | | 14 | 9 | 0 |
| fix needs the core | | 0 | 10 | 1 |

### 5.2 Against the textbook

By case: 15 agree, 16 add detail, 2 contradict (both synthetic), 19 not comparable.

- **No real contradiction.** Each apparent one has another cause: a shared precursor (S04), a source
  error (S12), an isoform (O04), or a lossy mapping (S02).
- **No fusion with the textbook under M0.** The nearest, S10, fuses once SIGNOR's complex is mapped to
  GO:0045259 (M1, computed: 0.80 to 0.89).
- **"Adds detail" is the normal case.** Curated chains give the mechanism, with the right signs (G03).
  But four chained links have belief 0.41 (`chain` multiplies), and they end at an activity, while the
  textbook speaks of an amount in blood.
- **Where the core is right.** Cross-source fusion (S01, S05, S06: 0.89 to 0.92). Sign algebra (G03).
  Unsigned and refined annotations (S13, O02, O03). A refutation kept contested (Y02). Mouse, worm and
  diabetic-human claims kept apart (M03 to M07).

### 5.3 Mapping loss

**Stress set (52 curated statements, `statements.tsv`).**

| source | lossless | lossy | dropped or inexpressible |
|---|---:|---:|---:|
| SIGNOR | 6 of 18 | 11 | 1 (S11, dropped by M0) |
| GO-CAM | 13 of 20 | 7 | 0 |
| Reactome | 2 of 9 | 6 | 1 (R05, a set) |
| GOA | 4 of 5 | 1 | 0 |
| **all** | **25 of 52** | **25** | **2** |

Top reasons: BTO context dropped (5), relocalization read as amount (3), bare "up-regulates" read as
activity (3), a chain read as its precursor (3), no PMID (3).

**Whole sources.**

| source | unit | lossless | main reasons for loss |
|---|---|---:|---|
| SIGNOR, all human | 33,381 edges | 28.2% | BTO context dropped 37.7%; an end with no OBO id 28.6%; activity or amount not said 26.1%; unsigned binding 7.0% |
| SIGNOR, stress entities | 473 edges | 19.9% | an end with no OBO id 39.5%; relocalization 14.8% |
| GO-CAM, 29 models | 693 facts | 80.4% (64.5% with a PMID) | no PMID 28.4%; an individual's location read as a universal 11.5%; unsigned causal 6.8% |
| Reactome, release 98 | 137 reactions, 575 participants | 8.0% of reactions | complex with no OBO id 41.0%; set 14.6%; cleavage product 8.2%; inferred 17.5% of reactions |
| GOA, 18 proteins | 1,705 annotations | 48.5% | no PMID 42.2%; electronic (IEA) 20.4%; extension dropped 9.1% |

Files: `signor_loss.tsv`, `gocam_loss.tsv`, `reactome_loss.tsv`, `goa_loss.tsv`.

### 5.4 The evidence behind curated records

BioLean counts each PMID as evidence for its claim. Is each cited paper about the edge?
(`evidence_mentions.tsv`)

- **By title, 5 of 43 (edge, PMID) pairs cite a paper about another protein**: a rat V1a receptor paper
  for AVP to V2R (S07), MAP2c for PKA to TRPV5 (G06), neuromedin U receptors for Gi to PTH (G03), PI4K92
  for PI3K to GLUT4 (G02), adrenomedullin receptors for calcitonin to CALCR (G08).
- **A keyword test catches 3 of the 5**, with 5 false alarms (reviews, screens). It misses S07 and G08,
  whose abstracts name the right words for another receptor. Reading is needed.
- **A sign error.** SIGNOR says metformin up-regulates G6PC1 (S12). Its own stored sentence says
  metformin "inhibited the expression of the hepatic gluconeogenic genes pepck and g6pase". PubTator3
  has the pair as negative_correlate 9 times, positive once. As `textMined` items they make S12
  contested (b 0.48, d 0.42): better than established, not yet right.
- **One PMID, both sides.** GOA has CALCR "enables calcitonin binding" and "NOT enables calcitonin
  binding" from the same paper (PMID 15563840, on two novel isoforms), with no isoform on either row.
  `Derivation.clash` reads this as belief 0.71, disbelief 0.24: unsupported (O04).
- **One PMID, two links or two sources.** S14 and G03 use one paper for two chain links; O02 (GOA) and
  S06g (GO-CAM) cite one PMID. `sharedAxioms` checks statement ids, not PMIDs. A PMID-level lint
  (prototype `sharedPmids`, outside the core) finds S14 and G03.

### 5.5 What would flip

Computed in Lean, all outside the core:

| case | today | with the fix | fix |
|---|---|---|---|
| S10 | SILENT | PASS: fused with the textbook, 0.89 | M1 complex map |
| R07 | FAIL: 0.97 | PASS: unsupported, 0.30 | M1: inferred as one cross-species item |
| M05 | FAIL: established 0.83 | PASS: contested 0.50 / 0.25 | M1: pooled observational as observational |
| S14 | SILENT | PASS: PMID 31160049 found twice | lint `sharedPmids` |
| Y01 | SILENT | PASS: contested 0.44 / 0.44 | check `effectClash` |
| S12 | FAIL: established 0.80 | still FAIL, but contested 0.48 / 0.42 | PubTator3 items |
| S11 | SILENT | still SILENT: stated, but does not meet m45452-91 | M1 map |

Computed in Lean, with prototype rules (core changes):

| case | today | with the prototype |
|---|---|---|
| S09 | SILENT | PASS: `enablesInherit` links SCN1A to GO:0005248, fused 0.89 |
| G02 | SILENT | still SILENT: `widenProcess` turns the textbook claim into "human preproinsulin →+ D-glucose transmembrane transport" (0.80), but the chain ends at GLUT4 activity, which the model ties to glucose homeostasis |

PASS goes from 18 to 23 outside the core, 24 with one core rule. The other FAILs have importer fixes
(B, C), argued but not run.

## 6. The M8 exit question: does metformin extend lifespan in humans?

Claim: `effect (metformin ⊓ in_taxon Homo sapiens) →+ phenotype PATO:0000050 (life span)`. GO's
"aging" (GO:0007568) is obsolete; GO:0008340 "determination of adult lifespan" has no direction, so
the phenotype is the honest target.

| statement needed | source today | case | result |
|---|---|---|---|
| metformin activates AMPK | SIGNOR (Zhou 2001; rat muscle) | M01 | established 0.80 |
| metformin inhibits complex I | SIGNOR (Wheaton 2014) | M02 | established 0.80 |
| AMPK extends lifespan | GOA: worm aak-2 "involved in" adult lifespan, no sign; Apfeld 2004: AAK-2 "functions to extend lifespan" | O03, M08 | the signed worm step can be stated (0.70); no rule links the worm and human proteins |
| worm lifespan | Onken 2010; Cabreiro 2013 (the sign depends on the E. coli strain) | M03 | established 0.82 |
| mouse lifespan | longer in male mice (Martin-Montalvo 2013); "did not significantly extend lifespan" (Strong 2016) | M04 | contested 0.41 / 0.41 |
| survival in type 2 diabetes | Bannister 2014, Campbell 2017 (meta-analysis) for; Keys 2022 ("not associated with survival equal or superior to that of the general population") against | M05 | established 0.83 under M0 (FAIL); contested under M1 |
| mouse to human | a cross-species item (Barzilai 2016) | M06 | unsupported 0.12 |
| diabetes to no diabetes | no rule | M07 | never meet |
| a trial without diabetes | TAME proposed (Barzilai 2016); no result found | M09 | hypothesis, weight 0 |

The core's answer (M09): **unsupported, belief 0.12**, resting on 3 statements and 3 PMIDs (23900241,
27312235, 27304507). That is the right verdict, but it rests only on mouse data: the human evidence is
about people with diabetes and nothing moves it to people without (M07); on its own the core would call
that evidence established (M05); and the mechanism cannot chain from worm to human (M08).

Curated sources give the mechanism and nothing about lifespan. PubTator3 has 92,701 metformin
relations (with PRKAA2 positive_correlate 494, type 2 diabetes "treat" 9,107), but zero with Aging
(MeSH D000375) or Longevity (D008136) and 18 with "Aging, Premature" (`pubtator_metformin.tsv`). So
the lifespan outcomes need LLM extraction (option J), about a dozen papers per taxon, with comparator
and population in the claim.

## 7. Experiments for later

Each has its exit test first, then the cost in agent tasks.

| | exit test | what | cost |
|---|---|---|---|
| E1 | rerun `Literature.lean` with M1 statements: FAIL ≤ 7 (S02, G09, G10, R01, R06, R07, M05 fixed), no PASS lost | write importer M1 for the four sources over the stress entities (option B) | 3 |
| E2 | on the 43 pairs here (my title judgements as gold), catch ≥ 4 of the 5 wrong papers with ≤ 3 false alarms | an LLM evidence check: "does this abstract state this edge?" (option C) | 1 |
| E3 | on SIGNOR's 473 stress-entity edges, find S12 and report the sign-disagreement rate | an LLM sign check of each edge against its own stored sentence | 1 |
| E4 | of the 34 textbook-anchored cases, ≥ 8 link to their textbook statement and no new S02-type FAIL | prototype bridge rules (option D) in a Proto file, run on this set and the closure | 2 |
| E5 | `effectClash` over the closure and imports flags ≤ 2 real contradictions, each explained | the sign-clash check (option F) at scale | 1 |
| E6 | PubTator3 sign agreement reported for each of the 52 curated statements | PubTator3 as `textMined` items (option I); S12 done here | 1 |
| E7 | a Lean theorem that the M8 claim is unsupported or contested, resting on ≥ 10 quote-checked PMIDs | targeted LLM extraction of metformin lifespan outcomes per taxon, with population and comparator | 3 |
| E8 | no closure fact changes sign after re-grounding | re-ground the textbook's hormones (T01, T02: PR:000050339, CHEBI:5391) and rerun the closure (overlaps program 04) | 1 |

E1 to E3 are cheap, change nothing in the core, and fix most FAILs. Run them first.

## 8. What would change the decision

Decisions for Dan, in order:

1. Build importer M1 and the evidence checks (options B, C), all outside the core, as the first M8
   step? They fix most FAILs here.
2. After E4: which bridge rules (option D) go into the core, if any?
3. For the M8 exit: a rule across organism conditions (option K), or accept that disease evidence
   never informs the healthy-human claim?

What would change them:

- **E2 and E3 work**: curated evidence can be trusted per edge, so import it at scale.
- **E4 links most textbook cases with no new wrong claims**: bridge rules belong in the core. If they
  make S02-type claims, keep them as a search heuristic outside the core.
- **GO-CAM instance facts matter more widely** (11.5 percent here): option H rises.
- **Text-mined signs almost always agree with curated ones** (E6): PubTator3 is a cheap cross-check.

## 9. Review pass (2026-11-01)

An independent review re-ran every script and the Lean file (all outputs reproduced), looked every
record up again in its source, and re-checked every identifier live (`review_checked.tsv`: 141 CURIEs
with the RO relations, 96 PMIDs, 16 quotes, 13 textbook sentences, 13 Reactome ids; all agree).

| problem | fix |
|---|---|
| G02d: the model's "part_of glucose transport" fact (PMID 18245775) is GLUT1's, not GLUT4's | re-read: GLUT4 is part_of glucose homeostasis (PMID 14562105). Wrong papers 6 to 5 |
| G11: the ATP(4-) output is on a proton transporter activity, not ATP synthase | re-read |
| O02: GOA has no "AVP hormone activity, has_input AVPR2" row | replaced by PTH's real row (PMID 35932760) |
| S11, M08 marked INEXPRESSIBLE; both can be stated | pinned; S11 SILENT, M08 PASS |
| Y03 marked FAIL; no wrong claim, just no fusion | SILENT |
| G07 PASS with S07's wrong paper (S07 is a FAIL) | FAIL |
| G02 said to flip; the prototypes never use its chain | stays SILENT |
| F labelled a core change; it uses existing operators | relabelled, prototyped (`effectClash`) |
| "SILENTs come from the core"; 9 of 19 have outside fixes | counted per case (`fix_layer`) |
| PubTator3 "would contest S12" was argued | computed: contested |
| "34 textbook statements"; there are 13 | corrected |
| "needs live E. coli" and strain C57BL/6 are not in the abstracts | rephrased; strain UNVERIFIED |

## 10. Limits

- I chose the 52 cases: failures, but also agreements and places where the core is right (18 PASS).
- The loss classes are my rules. GO-CAM `occurs_in` facts count as lossless, though they too are
  locations of individuals.
- "Wrong paper" is judged by title and abstract. SIGNOR came from NDEx, which collapses edges. GO-CAM:
  29 models, not all.
- A "not comparable" case where the core says nothing is a PASS (S04, G08, M08). That is generous.
- Weights are the core's defaults (program 10a owns them).
- M05's claim cannot carry the comparator; M03 carries no bacterial context.
- Only S12 tests text-mined evidence; only O02 with S06g tests one paper in two sources.
- biolib labels GO:0005576 "extracellular fluid" (OLS4: "extracellular region"): a Y03-type mismatch.
- `cases.tsv` shows Lean's truncated decimals (8/9 as 0.88); this doc rounds (0.89).

## 11. References (checked)

Papers, checked on Europe PMC on 2026-11-01 (title, first author and year match). All 96 are in
`data/stress/10b/references_checked.tsv`.

| PMID | first author, year | about | used for |
|---|---|---|---|
| 1560825 | Morel A, 1992 | rat V1a vasopressin receptor cloning | S07, G07 (wrong paper) |
| 1534149 | Birnbaumer M, 1992 | human antidiuretic hormone receptor cloning | S07 (right paper) |
| 11029056 | Ozer RS, 2000 | MAP2c localisation | G06 (wrong paper) |
| 28534087 | van Goor MK, 2017 | PTH, PKA and TRPV5 | G05, G06 |
| 11277933 | Suer S, 2001 | PI4K92, a PI 4-kinase | G02 (wrong paper) |
| 18245775 | Mueckler M, 2008 | the GLUT1 transporter | G02 (the GLUT1 fact) |
| 14562105 | Bogan JS, 2003 | TUG and GLUT4 trafficking | G02 |
| 17909097 | Kim YD, 2008 | metformin and gluconeogenesis | S12 |
| 17403369 | Huang S, 2007 | the GLUT4 transporter (review) | S02, G02 |
| 24843404 | Seino Y, 2010 | GIP and GLP-1 (review) | S03 |
| 31693916 | Gasbjerg LS, 2020 | the incretin effect in humans | S04 |
| 31160049 | Inoue A, 2019 | G-protein coupling of 148 GPCRs | S08, S14 |
| 33742150 | Zhou F, 2021 | human V2 receptor ligand recognition | G07 |
| 38632411 | Zuo H, 2024 | CaSR G-protein activation | G03 |
| 15331768 | Brighton PJ, 2004 | neuromedin U receptors | G03 (wrong paper) |
| 7759551 | Garrett JE, 1995 | human parathyroid calcium receptor cloning | G03 |
| 32296767 | Liang YL, 2020 | adrenomedullin receptors | G08 (wrong paper) |
| 8078488 | Kuestner RE, 1994 | human calcitonin receptor cloning | G08, O04 |
| 15563840 | Beaudreuil J, 2004 | two novel calcitonin receptor isoforms | O04 |
| 35932760 | Kobayashi K, 2022 | PTH and its receptor, structure | S06, O02 |
| 8457197 | Colville CA, 1993 | GLUT2 and GLUT3 kinetics | R01, R02 |
| 11946536 | Thomsen J, 1972 | human glucagon sequence | R06 |
| 14672992 | Lossin C, 2003 | SCN1A dysfunction in epilepsy | S09, O01 |
| 15574588 | Apfeld J, 2004 | AAK-2 and lifespan in C. elegans | O03, M08 |
| 11602624 | Zhou G, 2001 | AMPK in metformin action | M01 |
| 24843020 | Wheaton WW, 2014 | metformin inhibits complex I | M02 |
| 20090912 | Onken B, 2010 | worm healthspan | M03 |
| 23540700 | Cabreiro F, 2013 | worms, microbes | M03 |
| 23900241 | Martin-Montalvo A, 2013 | mouse lifespan | M04 |
| 27312235 | Strong R, 2016 | ITP mouse lifespan | M04 |
| 25041462 | Bannister CA, 2014 | survival on metformin | M05 |
| 28802803 | Campbell JM, 2017 | mortality, meta-analysis | M05 |
| 36287641 | Keys MT, 2022 | survival advantage reassessed (cohort) | M05 |
| 27304507 | Barzilai N, 2016 | TAME proposal | M06, M09 |

The ten PubTator3 PMIDs behind S12's text-mined items are listed in `pubtator_metformin_g6pc1.tsv` and
checked in `references_checked.tsv`.

Data: SIGNOR on NDEx (network 523fff27-afe8-11e9-8bb4-0ac135e8bacf, "Signor Complete - Human",
26-Nov-2025; Perfetto L et al., NAR 2016, from the NDEx record); GO-CAM via `api.geneontology.org`;
Reactome ContentService release 98; GOA via QuickGO; PubTator3 release 2026-10-06. The extracts
`signor_targets.tsv` and `gocam_facts.tsv` keep their sources' licences. Identifiers: OLS4
(`curies_checked.tsv`, `isa_checked.tsv`, `review_checked.tsv`), NCBI E-utilities
(`ids_ncbi_checked.tsv`), QuickGO for UniProtKB ids. Textbook: OpenStax *Concepts of Biology*, the 13
sentences named in section 4's cases (the-body-s-systems-m45537-53, -99, -135, -140, -141, -199 to
-202, m45539-90; how-cells-obtain-energy-m45439-72, -74; photosynthesis-m45452-91), as compiled in
`BioLean/Lib/TextbookClaimsR2` and `R3`; their notes match `data/textbook/claims_m2` and `claims_m3`.

## 12. UNVERIFIED

- SIGNOR's own licence, TSV and API (its server refused connections); GOA's own licence page.
- That GO-CAM attaches "has this activity" evidence to causal facts as a pattern (4 of the 5 wrong papers).
- That GO's GPAD export lifts "activity part_of process" to "involved_in".
- TAME results: none found by one Europe PMC search. That does not show none exist.
- That PR has no mature-glucagon term (one OLS4 label search).
- Mouse strains C57BL/6 (Martin-Montalvo 2013) and UM-HET3 (Strong 2016): not in the abstracts; the
  full text returned a server error.
- PubTator3's "metformin cause Death" (40 rows): not read. PMIDs the sources cite that the set does not use.
