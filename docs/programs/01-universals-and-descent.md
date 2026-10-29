# Program 01: from instances to universals

Written 2026-10-29, revised the same day after a fact-check and a critique. This is a program of
work, not a decision. Nothing in it is built. Dan decides at the points in section 10.

**Dan's lean, 2026-10-29:** option (k) looks like the best simple solution. His reasons: DNA sequencing
now gives direct evidence for loss, so loss will rarely be in contention, and well-known convergence
examples are few. Not yet decided; E0 to E2 and the scorecard measurements come first.

Sources: three research reports, one data measurement (2026-10-28 and 29), and my own checks on
2026-10-29 (OLS4, QuickGO, NCBI E-utilities, Crossref, Europe PMC, GO's computed taxon constraints,
UBERON `uberon-base` release 2026-10-01). Anything I could not check is marked UNVERIFIED and listed
at the end.

## Summary

- **What I did.** Collected twelve options, built a 33-case test set (9 true, 23 false, 1 mixed),
  scored every option on it by one rule (predicted, not measured), and wrote 14 experiments.
- **The false universals BioLean makes today do not come from `generalize`.** `generalize` is used
  only in the transcription example. They come from textbook universals that narrow for free, and
  from the round 2 emitter dropping taxon context (section 1).
- **Dan's unstated axiom is the missing piece.** Witmer's bracket predicts only because it assumes
  common descent. Stated as a sourced default that a record can defeat (option k), it is right most
  often on the scorecard (26 of 33; in override cases only because the records were entered). Where
  it is wrong, a species changed and nobody recorded it. Those errors are the rat-versus-mouse
  hypotheses (sections 3 and 8).
- **Curated data is exact but mostly silent.** RO even has a "never lost in" relation (RO:0002504).
  Nobody uses it. IBA annotations put the ancestor's mitochondrion into Giardia.
- **Cleaning the evidence makes the coverage flaw worse.** With experimental instances only, "all
  cellular organisms transcribe" stays at 0.96 and "all eukaryotes transcribe" falls to 0.10.
- **What matters now.** E0, E1 and E2 are cheap and need no new code. Run them first.

## Results of E0, E1 and E2 (run 2026-10-29)

**E0. Where the choice matters today.**
- `generalize` is used only in `Examples/Transcription.lean`. Option (c) does no harm outside it.
- 557 of the 2,287 closure facts (24 percent) rested on a taxon or any-cell universal. Of those, 103
  rested on six statements whose context was dropped.

**The context bug, found and fixed.** The round-2 emitter and the closure's round-2 loader read
`m2.subject` and ignored `m2.context`. "Animal cells have a centrosome" (and four more animal and plant
cell sentences) became "cells have X". Round 3 applies context. `scripts/textbook/promote_context_to_m3.py`
copies the 70 round-2 records that carry a taxon, anatomy or cell-type context into `claims_m3`, so
they are emitted with their context. Result: facts resting on a context-dropped statement 103 → 0, and
the closure's one clash (centrosome) is gone, 1 → 0. 28 records carry a "condition" (a string in round 2,
a kind plus curie in round 3) and are not promoted.

**E1. Evidence hygiene.** Confirmed in Lean (`cellularE_value`, `eukaryotaE_value`,
`cellularE_above_eukaryotaE`). Experimental instances only: Euglena, Paramecium and Halobacterium
drop out (0 experimental annotations), Sulfolobus acidocaldarius joins (13). Cellular organisms
24/25 = 0.96, Eukaryota 16/153 = 0.10. The gap widens. Experimental counts, QuickGO 2026-10-29:
E. coli 158, yeast 859, mouse 139, human 644, Arabidopsis 61, Sulfolobus 13.

**E2. False universals in the encoding.** Nine statements are flagged in
`data/textbook/false_as_written.tsv` (universal_false 3, mapping 2, overgeneral 4). The closure now
reports what rests on them: **337 of 2,510 derived facts (13 percent)**. Most rest on "all cells have
ribosomes" (135) and "all cells have DNA" (118), false for mature mammalian red cells. Only two of the
nine are verified against a source; the rest are marked `memory` and need a check. Not yet done: the
exceptions slot (option f), the hedged `most` reading, and the E2 counterexample rule.

---

## Words used here

| word | meaning here |
|---|---|
| clade | an ancestor and all its descendants (Mammalia, Eukaryota) |
| LCA, LUCA, LECA | last common ancestor; of all cellular life; of all eukaryotes |
| bracket | samples on both sides of a split. Together they say something about the ancestor at the split |
| Witmer level | how good a bracket is. I: both outgroups have X. II: one does. III: neither does |
| retention, loss | the trait was kept on the way down; a lineage had it and dropped it |
| convergence, homology | a similar trait arose twice; two traits come from one ancestral trait |
| Dollo default | a complex trait is gained once and may be lost many times |
| coverage | BioLean's number for how much of a clade the samples touch (`Coverage.lean`) |
| coherent | a broad claim is never believed more than a narrower claim it implies |
| verdict | BioLean's reading of an opinion: established (belief ≥ 4/5), refuted (disbelief ≥ 4/5), contested (both ≥ 1/4), else unsupported |
| ECO | the Evidence and Conclusion Ontology. GO evidence codes map to it |
| IEA, IBA | GO annotations made automatically (IEA), or inferred from an ancestor in a gene tree (IBA). Both are already generalisations |
| IKR, IRD | GO "NOT" annotations from a gene tree: key residues lost (IKR), rapid divergence (IRD) |
| PANTHER, PAINT, IBD | PANTHER is a set of gene family trees. PAINT is GO's curation on them. IBD is the ancestral annotation PAINT makes on a tree node, which IBA then copies to genes |
| Bgee | a gene expression database. It also curates which anatomy terms are homologous |
| OMA | an orthology database |
| HOM | an ontology of homology terms (HOM:0000007 historical homology, HOM:0000004 convergence) |
| taxon constraint | a curated rule saying where a GO or UBERON term can apply ("only in T") or cannot ("never in T") |
| R1, R2, R3 | the three rounds of textbook encoding into Lean |

---

## 1. What makes false universals today

This came out of the research. It matters whichever option Dan picks, so it goes first.

- **Textbook universals narrow for free.** "All mammals have teeth" (the-body-s-systems-m45535-39) is
  in R2 as Mammalia has part calcareous tooth (UBERON:0001091). It is false. Baleen whales, pangolins
  and anteaters have no teeth (Meredith 2009). UBERON itself says tooth is never in Mysticeti,
  Tachyglossidae, Ornithorhynchus or Aves.
- **The R2 emitter drops taxon context.** `scripts/textbook/emit_lean_m2.py` reads `m2.context`
  only to block statements. About 40 R2 statements lost their taxon (41 by one recount). The
  research found 232 of the 2,287 novel closure facts rest on them (not re-checked). Example:
  "animal cells also have a centrosome" (m45432-318) became "cell has part centrosome".
- **About 19 R2 statements turned "some" or "most" into "every"** (research count, not re-checked).
- **`generalize` is used only in `Examples/Transcription.lean`.** So option (c) does no harm yet.
  That supports Dan's choice to leave it for now (E0 checks this).
- **Detection exists. Revision does not.** `Derivation.clash` plus free narrowing already catches a
  counterexample locally. The closure's one clash was found this way: the centrosome statement
  against "plant cells lack centrioles" (`docs/closure-search.md`). What is missing is the next
  step: turning "all T have X" into "all T except x1 … xn" or "most T".
- **A correction to the test-set report.** It said has-part claims have "no constructor". That note
  comes from a pre-M1 field in `data/textbook/claims/`. `Claim.rel` with has_part exists. What is
  truly missing is ancestor and loss claims.

---

## 2. The question

We have instances: "transcription makes RNA" in E. coli, yeast, mouse, human, Arabidopsis,
Euglena, Paramecium and Halobacterium. How should these become "in all cellular organisms"?
Today `generalize` fuses the instances and discounts the result by coverage. Lean proves a flaw
(`cellular_above_eukaryota`). From the same instances, "all cellular organisms transcribe" gets
belief 32/33 (0.97) and "all eukaryotes transcribe" gets 16/75 (0.21). The first implies the second,
so this is incoherent. The cause: the top level only asks whether each child lineage holds a
sample, however thin. Capping is coherent, but one sample covers nothing, so the true universal
drops to 0.

**A second problem.** Three of the eight instances rest only on inferred GO annotations.
Paramecium, Euglena and Halobacterium have no experimental GO annotation to transcription. Their
annotations are IEA or IBA, which are inferences by homology. So the current universal counts the
ancestral inference twice. (People have studied transcription in these organisms. GO just has no
experimental annotation for it.)

| taxon | all | IEA | IBA | experimental |
|---|---:|---:|---:|---:|
| Paramecium (5884) | 2,937 | 2,785 | 152 | **0** |
| Euglena (3038) | 20 | 20 | 0 | **0** |
| Halobacterium salinarum (2242) | 98 | 77 | 21 | **0** |
| E. coli (562) | 2,451 | 2,265 | 15 | 158 |
| S. cerevisiae (4932) | 1,650 | 573 | 141 | 859 |
| Sulfolobus acidocaldarius DSM 639 (330779) | | | | 13 IDA |

QuickGO, 2026-10-29: GO:0006351 and its descendants by is_a, part_of and occurs_in only.
Experimental means EXP, IDA, IPI, IMP, IGI, IEP and the high-throughput codes. The other codes
(TAS, IC, ISS and so on) make up the rest of "all". QuickGO's default also follows "regulates", which
mostly adds regulation-of-transcription annotations (E. coli then has 10,869). The docstring of
`Transcription.lean` uses those default counts.

---

## 3. The axiom nobody states

Dan: "GENERALLY life does evolve by common ancestor (convergence being the exception) ... It's one
of those 'axioms' that people don't state."

- **The axiom.** A trait shared by related lineages comes from their common ancestor and was kept,
  unless shown otherwise.
- **The bracket needs it.** Witmer's levels infer the state of the bracketed taxon by parsimony
  (Witmer 1995; Bryant & Russell 1992). Parsimony, assuming the fewest changes, is this axiom in
  another form. Option (b) as written splits it out
  as a separate "not lost" premise. Without that premise, (b) is silent on every true "all T have X".
- **The book gives the evidence for it.** "Virtually all species use the same genetic code ...
  powerful evidence that all life on Earth shares a common origin" (molbio-m45479-54). And glycolysis
  "probably evolved in very primitive organisms and persisted" (m45438-65).
- **BioLean form: option (k).** A default with a source and a weight. A recorded loss defeats it
  for that lineage. A recorded convergence (HOM:0000004) defeats it for that pair. It is option (e)
  applied to the descent axiom.
- **Its cost.** It is wrong wherever a change happened and nobody recorded it. Those errors are a
  list of candidate hypotheses.
- **No phylogenetic maths.** One ancestor lookup on NCBI Taxonomy and a list of defeaters.

---

## 4. What the textbook itself says

The textbook (OpenStax, A-level floor) states universals and the descent argument. Quotes checked
against `data/textbook/claims/`.

| id | sentence | bin | in Lean? |
|---|---|---|---|
| molbio-m45479-53 | "The genetic code is universal." | missing_construct | no |
| molbio-m45479-54 | "With a few exceptions, virtually all species use the same genetic code ..., which is powerful evidence that all life on Earth shares a common origin." | missing_construct | no |
| molbio-m45480-2 | "All organisms and cells control or regulate the transcription and translation of their DNA into protein." | missing_construct | no |
| how-cells-obtain-energy-m45438-64 | "If glycolysis evolved relatively late, it likely would not be as universal in organisms as it is." | not_claim | no |
| how-cells-obtain-energy-m45438-65 | "It probably evolved in very primitive organisms and persisted, ..." | not_claim | no |
| cell-structure-and-function-m45432-186 | "Because protein synthesis is essential for all cells, ribosomes are found in practically every cell, ..." | missing_construct | partly: -187 is in R2 as "every cell has part ribosome", in R3 as `most` |
| the-body-s-systems-m45539-355 | "Neurons contain organelles common to all cells, such as a nucleus and mitochondria." | missing_construct | partly: "neurons have a nucleus / mitochondria" is in R1 and R2; "common to all cells" was dropped |

### Counts from the audit

The audit read every hit in the 3,723 sentences. The sums add up; the rows were not re-counted.

| category | sentences | key claims | in Lean |
|---|---:|---:|---:|
| universal over organisms, cells or a clade | 45 | 65 | 35 |
| universal over a molecule class | 5 | 7 | 3 |
| near-universal ("most", "nearly all") | 39 | 50 | 25 |
| exception, absence, "only" | 31 | 41 | 30 |
| descent, retention, essentiality | 29 | 42 | 6 |
| convergence, analogy, homology | 10 | 13 | 1 |
| **all** | **159** | **218** | **100** |

Of the 100 in Lean: 65 say what the text says, 14 are weaker, 14 are stronger, and 7 are stronger
in R2 but hedged correctly in R3.

### What this tells us

- **No descent argument reached Lean.** Only the factual halves did.
- **The universals are mostly about cells, not organisms.** "All cells have DNA" is false (mature
  mammalian red cells). "All cellular organisms have DNA" is true.
- **Several stated universals are false as written:** m45479-53, m45429-5 (all cells share DNA and
  ribosomes), m45539-355, m45535-39 (teeth). The book hedges the genetic code in the next sentence.
- **Homology is defined once** (FtsZ and tubulin, m45463-47). **Convergence appears once**, as an
  open question (m45539-31). **Loss is never an event**, only an absence ("lacks").
- **What is missing is not "all".** A bare BioLean claim is already universal over its subject.
  Missing: a universal with named exceptions; ancestor claims; the inference itself ("shared, so
  ancestral"; "essential, so universal"); a cell-versus-organism scope.

---

## 5. The options

The options combine; they are not rivals. (f) to (l) are new.

**(a) Cap.**
- Idea: a clade never scores above any lineage inside it.
- Formula, with `br` today's bracketing:
  `cap(t) = min(br(t), min over covered children c of cap(c))`.
  Unsampled children lower `br(t)` through its denominator. They do not enter the min, or one
  unsampled child would set the cap to 0.
- The base case decides everything. Today a sampled taxon with nothing sampled below it has
  `br = 0`. Then `cap(t) = 0` for every sample, however large: the min always reaches such a taxon.
  With the base case "a sampled taxon covers itself" (`br = 1`), the cap is set by the thinnest
  sampled lineage.
- Right: coherent by construction.
- Wrong: true universals score near 0. It takes positive instances only, so it cannot register an
  exception. Narrowing is still free.

**(b) Ancestor plus retention** (Witmer's extant phylogenetic bracket).
- Idea: samples that bracket a split support "the LCA of T had X". "All T have X" needs a separate
  "not lost in T" premise with its own weight. Narrower claims inherit from broader ones.
- Needs: an ancestor claim shape; a bracket rule; retention premises; a way to state absence.
- Right: separates "the ancestor had it" from "everyone kept it". A recorded loss inside T refutes
  "all T have X", so (b) uses exceptions.
- Wrong: with no retention source it is silent on every true "all T have X". Without a homology
  slot it fuses convergent traits that share a term. It cannot see gene transfer or organelle
  genomes on NCBI Taxonomy. Coherence holds only if retention never rises as the clade grows.

**(c) Leave the current measure, documented** (Dan's choice for now).
- Idea: keep bracketing as is, with its flaw stated.
- Right: cheap, honest, the flaw is a theorem. Used by one example only, so harmless today.
- Wrong: incoherent. Takes positive instances only. Free narrowing passes belief into every
  lineage that lost the trait. Below the target clades biolib under-counts children, so a small
  sample can "establish" a clade (section 8).

**(d) Borrow curated phylogenetic knowledge.**
- Idea: GO and UBERON taxon constraints (Deegan 2010; Mungall 2012), PAINT ancestral annotations
  and losses (Gaudet 2011), Bgee homology (Bastian 2025), NCBI genetic-code tables.
- Needs: four small downloads (E3). biolib's UBERON parser drops the constraints today.
- Right: exact where it exists (NCBI genetic codes; gallbladder never in Rattus).
- Wrong: mostly silent. RO defines "all T have X" (RO:0002504 "always present in taxon", alternative
  label "never lost in"). Neither GO's computed constraints nor UBERON 2026-10-01 asserts it once.
  The constraints in use are ceilings ("only in"), exclusions ("never in") and "present in". Loss
  records are sparse. IBA carries the ancestral state into lineages that lost it. A missing
  annotation is not a NOT.

**(e) Background axioms.**
- Idea: take stated universals as textbook axioms with their source. Use generalisation only to
  generate hypotheses, never to establish.
- Needs: organism-level terms, a cell-or-organism scope, a hedge (`most`).
- Right: how textbooks work. Links to the planned `canonical` evidence kind in
  `docs/case-studies.md` ("bottom-up and top-down should agree").
- Wrong: strict, it imports the book's overstatements. Hedged (m45479-54 as `most`), it is safe
  but cannot narrow to any one taxon. No history. Silent where the book is silent.

**(f) Universal with named exceptions, plus a counterexample rule.**
- Idea: "all T have X, except x1 … xn". One verified negative inside T refutes the strict "all T";
  "T except x" keeps its belief.
- Needs: an exceptions slot; a counterexample rule. Detection already exists (section 1).
- Right: matches the book's wording ("with a few exceptions, virtually all").
- Wrong: it holds exceptions; it cannot predict one.

**(g) Essentiality premise.**
- Idea: the book's own form: X is needed for Y, Y is universal, so X is universal (m45432-186).
- Needs: a "required for" premise and a defeater slot.
- Wrong: fails where a bypass exists. Monocercomonoides replaced its mitochondrial iron-sulphur
  pathway with bacterial genes gained by transfer (Karnkowska 2016).

**(h) Homology as a positive premise.**
- Idea: fusing instances into an ancestor claim needs a homology record (HOM:0000007); convergence
  (HOM:0000004) forbids it (Roux 2010).
- Right: never fuses convergent traits.
- Wrong: it reverses Dan's default. Homology data is thin outside anatomy, so (b)+(h) goes silent
  on most real cases. Near-identical proteins can be convergent (case CV4), so protein similarity
  is not enough.

**(i) Measure retention in genomes.**
- Idea: Witmer checked soft tissue against bone. Here, check the genome: "encodes RNA polymerase
  large subunits" can be checked in every sequenced member of T.
- Needs: reference proteomes or OMA (Altenhoff 2024); one marker set per trait.
- Right: the only route found to positive evidence of retention.
- Wrong: molecular traits only. Orthology is itself an inference. Absence can be an assembly gap.

**(j) Bracket on the bearer's tree.**
- Idea: a mitochondrial gene's history is on the mitochondrion's tree, which sits within or sister
  to Alphaproteobacteria (debated: Martijn 2018; Fan 2020), not on the host's tree.
- Right: the only option that handles organelle genomes and gene transfer.
- Wrong: brings in tree maths. Out of scope (Dan's wish). No experiment here tests it.

**(k) Common descent as a stated, defeasible default** (section 3).
- Idea: retention and homology hold by default, with a source and a weight. A record defeats the
  default for its lineage or pair: a loss, a convergence, a transfer.
- Needs: a default rule with defeat. A record must replace the default for its lineage, not fuse
  with it. With fusion only, every known exception would read as "contested". BioLean has fusion
  only today.
- Right: makes (b) speak on true cases. Predicts. Its errors are a list of candidate changes.
- Wrong: wrong on every unrecorded change. The weight is a choice.

**(l) Curate "never lost in" assertions.**
- Idea: assert RO:0002504 where a source supports it. This gives (b) a positive retention premise.
- Right: citable, standard vocabulary, could be contributed back to UBERON.
- Wrong: RO's own note calls it "a very strong relation". Its examples are the brain and heart in
  vertebrates. Few traits qualify, and each needs a human curator.

**Requirements, not options.** Every option fails without these:
- **Evidence hygiene.** Instances must be experimental, in that organism. IBA and IEA go through the
  ancestor rule. So does IGI on a genome-only taxon (two archaeal "experimental" annotations are IGI
  on *Candidatus* Lokiarchaeum sp. GC14_75, NCBITaxon:1538547).
- **Context below the taxon.** Population (cave fish), cell type (red cells), compartment
  (mitochondrial code), life stage.
- **A way to state absence and loss.** `notRel` exists. Detection exists. Upward revision does not.

---

## 6. Three worked examples

Letters as in the scorecard (section 8): R right, W wrong, S silent, C contested.

### Example 1: loss. Eukaryotes without mitochondria

**The biology.** Giardia and Trichomonas seemed to have no mitochondria. From 1983 this was read as
"they never had them" (the Archezoa idea). Today both are known to have reduced remnants. Giardia
has mitosomes, which make iron-sulphur clusters (Tovar 2003). Trichomonas has hydrogenosomes, which
share an origin with mitochondria (Bui 1996). Monocercomonoides has none at all, yet its ancestors
did: a secondary loss (Karnkowska 2016).

**The claim.** "Giardia has a mitochondrion" (false).

| option | concludes | verdict |
|---|---|---|
| (a) | near 0 for Eukaryota. Giardia's absence cannot enter | S |
| (b) | LECA had a mitochondrion. The mitosome papers, entered as a loss, refute it for Giardia. Needs a class "mitochondrion-related organelle": in GO, mitosome and hydrogenosome sit beside mitochondrion, not under it | R |
| (b)+(k) | as (b). Any eukaryote with no record inherits a mitochondrion | R |
| (c) | fed the same six eukaryote samples as transcription, 0.21 for Eukaryota. Narrowing passes 0.21 to Giardia | S |
| (d) | GO: mitochondrion only in Eukaryota, no never-in for Giardia. IBA puts 38 Giardia proteins in "mitochondrion" | W |
| (e) | m45539-355: "organelles common to all cells, such as a nucleus and mitochondria" | W |
| (e)+(f) | "eukaryotes have mitochondria, except x1 … xn", exceptions from the papers | R |

**Lesson.** Absence must be something we can state. "No recorded loss" is not "kept".

### Example 2: convergence. Echolocation

**The biology.** Some bats and the toothed whales echolocate. Their common ancestor did not. GO
uses one term for both (GO:0050959). The hearing gene prestin shows convergent changes in both (Li
2010; Liu 2010). A claim of genome-wide convergence (Parker 2013) did not survive a proper null
model (Thomas & Hahn 2015; Zou & Zhang 2015). Soft-furred tree mice (*Typhlomys*, NCBITaxon:687454)
echolocate too (He 2021). They are muroid rodents, in the same superfamily as mouse and rat. Inside
bats, "one origin, then loss" against "two origins" is still debated (Teeling 2000).

**The claim.** "Bats and toothed whales inherited echolocation from a common ancestor" (false).

| option | concludes | verdict |
|---|---|---|
| (a), (c) | cannot state "inherited" | S |
| (b) | bats and whales bracket their common ancestor, so "the ancestor echolocated" | W |
| (b)+(k) | the same by default. The convergence papers, entered, defeat it | R |
| (b)+(h) | no homology record, so no fusion. Nothing refutes it either | S |
| (d) | GO: echolocation only in Amniota, never in Mus musculus or Primates. For Primates this is contestable: blind humans learn click echolocation (Thaler 2011). Silent on origin | S |
| (e) | the book has no echolocation sentence | S |

Inside bats, (b) silently picks one side of a live dispute. That hides a controversy.

The camera eye has the same shape. UBERON:0000019 has no direct taxon constraint. It inherits "in
taxon" Bilateria and Eumetazoa, and neither blocks octopus. So nothing formal stops an octopus
annotation from merging two eyes that do not share an origin.

**Lesson.** Same term is not same origin. With (k), convergence is a defeater that must be entered.

### Example 3: mitochondrial genes. A count does not inherit

**The biology.** Mitochondria descend from a bacterium within or sister to Alphaproteobacteria
(debated). The jakobid protists keep the most gene-rich known mitochondrial genomes: Reclinomonas
americana has 97 genes (Lang 1997), Andalucia godoyi 100 (Burger 2013). These include
bacterial-type RNA polymerase genes. (The largest mitochondrial genomes, in bytes, are in flowering
plants; Sloan 2012.) Human mitochondrial DNA has 37 genes: 13 protein, 22 tRNA, 2 rRNA (Anderson
1981). Many genes moved to the nucleus. Others were lost.

**Presence inherits; the count does not.** "The LECA's mitochondrial DNA had at least about 100
genes" is a fair ancestor claim. It says nothing about the count in human. Each lineage lost a
different set. A gene that moved to the nucleus is a third state: gone from the mitochondrial DNA,
not from the cell.

| option | concludes | verdict |
|---|---|---|
| (a), (c) | `generalize` takes a predicate, not a count. As a relation ("mitochondrial DNA has part rpoB"), two jakobids cover one lineage only | S |
| (b) | needs the mitochondrion's own tree (j). For counts it gives only "the ancestor had at least n". Human's gene table, entered, refutes rpoB in human | R for presence; S for the count |
| (d) | GO says nothing. NCBI organelle gene tables are right, but that is measurement | R as data |
| (e) | silent on gene content. Related sentences: m45432-257 ("mitochondria and chloroplasts have their own DNA and ribosomes, just as bacteria do", in R2 as GO:0005739 has_part CHEBI:16991), m45432-228, m45439-96 | S |

One more finding. cell-structure-and-function-m45432-261 ("aerobic bacteria becoming mitochondria")
is in R1 as RO:0001001 "derives into", which reverses the direction. R2 has RO:0001000 "derives
from" Bacteria: the right direction, but an organelle-to-taxon link, and far too broad.

**Lesson.** A rule must know what kind of trait it handles. Present-or-absent traits can inherit
with a retention premise. Counts, gene lists and sequences change by many small losses and must be
measured per lineage.

---

## 7. The test set

33 cases: 9 true, 23 false, 1 mixed. IDs checked in OLS4 and NCBI.

Each case has a **mode**:
- **U, universal.** No single target. Does the option establish the true universal?
- **O, override.** The change is on record, and the record is given to every option. Does the
  record win over the universal? This tests the brake.
- **P, predict.** The target species' own records are hidden. Does the option extend the trait to it
  correctly? This tests the accelerator. Rat-versus-mouse cases are all P.

### Universal and override cases

| id | mode | case | taxa (NCBITaxon) | truth | ref |
|---|---|---|---|---|---|
| U1 | U | all cellular organisms carry out DNA-templated transcription (GO:0006351) | 131567; 2; 2157; 2759 | true | Werner & Grohmann 2011 |
| U2 | U | all cellular organisms have ribosomes (GO:0005840) | 131567 | true per organism | Woese & Fox 1977 |
| LT1 | U | all mammals lactate (GO:0007595) | 40674 | true | Oftedal 2002 |
| N1 | O | vertebrate mitochondria use the standard code | 7742; 9606 | false: code 2 | Barrell 1979 |
| N2 | O | Mycoplasma uses UGA as stop | 2095; 2093 | false: code 4 | Yamao 1985 |
| N3 | O | Paramecium uses UAA/UAG as stop | 5884; 5888 | false: code 6 | Preer 1985 |
| N4 | O | Candida albicans reads CUG as Leu | 5476; 4932 | false: Ser, code 12 | Santos & Tuite 1995 |
| L1 | O | Giardia has a mitochondrion (GO:0005739) | 5741 | false: mitosome | Tovar 2003 |
| L2 | O | Trichomonas has a mitochondrion | 5722 | false: hydrogenosome | Bui 1996 |
| L3 | O | Monocercomonoides has a mitochondrion-related organelle | 2049356 | false: none | Karnkowska 2016 |
| L4 | O | human mtDNA encodes bacterial-type RNA polymerase, as jakobid mtDNA does | 9606; 48483; 505711 | false: 37 vs 97 vs 100 genes | Anderson 1981; Lang 1997; Burger 2013 |
| L5 | O | all mammals make vitamin C (GO:0019853) | 376913; 10141; 376911 | false: Haplorrhini, guinea pig | Pollock & Mullin 1987; Drouin 2011 |
| L6 | O | Astyanax mexicanus has eyes | 7994 | mixed: surface yes, cave no | Yamamoto & Jeffery 2000; Jeffery 2009 |
| L7 | O | all mammalian cells have a nucleus, DNA and ribosomes | 40674 | false: mature red cells (CL:0000595) | Ji 2011 |
| L8 | O | all vertebrates have haemoglobin | 30806; 36190 | false: icefish | Ruud 1954; Cocca 1995 |
| L9 | O | all mammals have teeth (UBERON:0001091) | 40674; 9761; 9971 | false: repeated loss | Meredith 2009 |
| CV1 | O | vertebrate and coleoid camera eyes are homologous (UBERON:0000019) | 7742; 6606 | false | Ogura 2004 |
| CV2 | O | bats and toothed whales inherited echolocation (GO:0050959) | 9397; 9722 | false | Li 2010; Liu 2010; Thomas & Hahn 2015 |
| CV3 | O | C4 photosynthesis (GO:0009760) has one origin | 4577; 4227 | false: 62 lineages | Sage 2011 |
| CV4 | O | Antarctic and Arctic fish antifreeze glycoproteins are homologous | 8205; 8045 | false | Chen 1997; Zhuang 2019 |
| H1 | O | animals cannot make carotenoids (GO:0016117) | 7029 | false: aphids, fungal genes | Moran & Jarvik 2010 |
| A1 | O | amitochondriate eukaryotes never had mitochondria (Archezoa) | 5741; 5722; 5759; 6029 | false | Embley & Martin 2006 |

Notes. CV1 uses Coleoidea (6606): all of Cephalopoda would include Nautilus, whose eye is a lensless
pinhole. CV3 uses Flaveria trinervia (4227), a C4 species; the genus Flaveria also holds C3 species.
L8 says haemoglobin, not red cells: icefish lack haemoglobin, but a few erythrocyte-like cells may
remain (UNVERIFIED).

### Predict cases (target's own records hidden)

| id | case | taxa (NCBITaxon) | truth | ref |
|---|---|---|---|---|
| NT1 | mouse nuclear genes use the standard code, as rat and human do | 10090; 10116; 9606 | true: code 1 | NCBI |
| LT2 | Giardia has actin, as yeast and human do (GO:0015629) | 5741 | true | Paredez 2011 |
| LT3 | mouse makes vitamin C, as rat does | 10090; 10116 | true | Maeda 2000 |
| CVT1 | human and mouse camera eyes are homologous | 9606; 10090 | true | UBERON homology note |
| CVT2 | bat and mouse forelimbs are homologous (UBERON:0002102) | 9397; 10090 | true | — |
| RMT1 | mouse has a liver, as rat and human do (UBERON:0002107) | 10090; 10116; 9606 | true | — |
| RM1 | rat has a gallbladder, as mouse and human do (UBERON:0002110) | 10116; 10090; 9606 | false | Higashiyama 2018 |
| RM2 | mouse activated T cells express MHC class II, as rat and human do | 10090; 10116; 9606 | false | Holling 2004 |
| RM3 | mouse macrophages express CD4, as rat and human do | 10090; 10116; 9606 | false | Crocker 1987 |
| RM4 | rat can vomit, as human can (rat's own data hidden) | 10116; 10090; 10141; 9606 | false | Horn 2013 |
| RM5 | mouse has splenic sinusoids, as rat and human do (UBERON:0003910) | 10090; 10116; 9606 | false | UBERON, citing the JAX "Green Book" |

Notes. LT2 is the twin of L1: Giardia kept actin, yet it lacks every canonical actin-binding
protein (Paredez 2011). RM1 and RM5 were picked from UBERON's never-in list, so (d) is not scored
on its own record there. For RM2, rat is UNVERIFIED (Holling 2004 says "many species, except
mice").

### Findings from the test set

1. **Coverage, (a) or (c), never registers an exception.** It takes positive instances only
   (`Measure.eval_mono`).
2. **Narrowing a claim to a member taxon is free** (`Derivation.lean`: "Specialisation is free
   through the is_a laws"). Belief in "mammals make vitamin C" passes straight to human.
3. **In predict mode, no method gets a changed species right.** The bracket predicts the ancestral
   state. That is the useful part for Dan: departures from the bracket are the hits (E11).
4. **A shared ontology term is not a homology claim** (CV1, CV2).
5. **Borrowed data (d), used naively, puts the ancestral state into lineages that lost it** (L1, L3).
   The same IBA mechanism is right on LT2.
6. **The set is still lopsided:** 9 true of 33. In reality agreement is the common case. E11 adds
   agreement cases from the Alliance until true cases match false ones.

---

## 8. Scorecard (PREDICTED)

**These are predictions, not measurements.** E3, E6 and E10 measure them.

**One rule for every cell.** Read the option's opinion with BioLean's `verdict` (θ = 4/5, τ = 1/4).
- **R** right: established and true, or refuted and false.
- **W** wrong: established and false, or refuted and true.
- **S** silent: unsupported. This includes belief 0, any small belief, and "cannot state".
- **C** contested.
- **?** depends on data not yet checked.

**Inputs.** In O cases every option is given the same records. What each can use:

| column | positive instances | recorded loss, change, convergence | curated files | textbook | default |
|---|---|---|---|---|---|
| (a) | yes | cannot use | instances only | — | none |
| (b) | yes | losses and changes; not convergence | as records | — | none: no record means uncertain |
| (b)+(k) | yes | all | as records | — | descent, defeated by a record |
| (c) | yes | cannot use | instances only | — | free narrowing |
| (d) | — | only if in the files | yes | — | — |
| (e) | — | cannot use | — | strict, as written | free narrowing |
| (e)+(f) | — | as exceptions | as exceptions | yes | the book's universal |

### Universal and override cases

| case | truth | (a) | (b) | (b)+(k) | (c) | (d) | (e) | (e)+(f) |
|---|---|---|---|---|---|---|---|---|
| U1 | T | S | S | R | R | S | R | R |
| U2 | T | S | S | R | R | S | R | R |
| LT1 | T | S | S | R | S | S | S | S |
| N1 | F | S | S | S | S | R | W | R |
| N2 | F | S | R | R | S | R | W | R |
| N3 | F | S | R | R | S | R | W | R |
| N4 | F | S | R | R | S | R | W | R |
| L1 | F | S | R | R | S | W | W | R |
| L2 | F | S | R | R | S | W | W | R |
| L3 | F | S | R | R | S | W | W | R |
| L4 | F | S | R | R | S | R | S | S |
| L5 | F | S | R | R | S | S | S | S |
| L6 | mixed | S | C | C | W | S | S | S |
| L7 | F | S | S | S | S | S | W | R |
| L8 | F | S | R | R | ? | S | S | S |
| L9 | F | S | R | R | S | S | W | R |
| CV1 | F | S | W | R | S | S | S | S |
| CV2 | F | S | W | R | S | S | S | S |
| CV3 | F | S | W | R | S | S | S | S |
| CV4 | F | S | W | R | S | S | S | S |
| H1 | F | S | R | R | S | S | S | S |
| A1 | F | S | R | R | S | S | S | S |

### Predict cases

| case | truth | (a) | (b) | (b)+(k) | (c) | (d) | (e) | (e)+(f) |
|---|---|---|---|---|---|---|---|---|
| NT1 | T | S | S | R | R | S | R | R |
| LT2 | T | S | S | R | S | R | S | S |
| LT3 | T | S | S | R | S | S | S | S |
| CVT1 | T | S | R | R | S | ? | S | S |
| CVT2 | T | S | R | R | S | ? | S | S |
| RMT1 | T | S | S | R | R | S | S | S |
| RM1 | F | S | S | W | W | S | S | S |
| RM2 | F | S | S | W | W | S | S | S |
| RM3 | F | S | S | W | W | S | S | S |
| RM4 | F | S | S | R | W | S | S | S |
| RM5 | F | S | S | W | W | S | S | S |

### Notes on cells

- **U1, (c):** with experimental instances only (E1), 0.96. Right here, but still incoherent.
- **U1, (e):** m45480-2 presupposes transcription in all organisms. It is not in Lean yet.
- **U2, (e):** right per organism. Per cell it is L7, where (e) is wrong.
- **(e) hedged** (m45479-54 as `most`): N1 to N4 go from W to S, and NT1 goes from R to S.
- **LT1 and LT3, (c):** every experimental lactation annotation is in Theria, and every
  experimental vitamin C one is in mouse or rat. One sampled lineage covers almost nothing.
- **N1:** no option but (d) can state it without a compartment slot. With one, (b) and (b)+(k)
  become R.
- **L6:** without a population slot, the surface and cave records fuse into "contested". That is
  the honest answer for now. (c) reads the surface record only.
- **L8, (c):** Vertebrata has two NCBI children. One cyclostome instance would "establish" it and
  make (c) W.
- **CV1 to CV4, (b)+(k):** right only because the convergence papers were entered. With (h) in
  place of (k), all four are S.
- **CVT1 and CVT2, (d):** depends on Bgee's homology rows (E6).
- **RM1 to RM5, (c):** mouse and human "establish" Euarchontoglires, because biolib knows only two
  children there (Glires, Primates). Narrowing then passes the trait to rat. The mechanism is
  generalise and narrow, not `transport`, which only takes effect claims.
- **RM4, (b)+(k):** mouse and guinea pig lack vomiting (Horn 2013, rat hidden). That is Witmer level
  III for rat, so the default predicts "no".
- **(b)+(k) assumes defeat.** If records fuse with the default instead, most O cells become C.

### Tally

| | (a) | (b) | (b)+(k) | (c) | (d) | (e) | (e)+(f) |
|---|---:|---:|---:|---:|---:|---:|---:|
| R | 0 | 14 | 26 | 4 | 6 | 3 | 12 |
| W | 0 | 4 | 4 | 6 | 3 | 9 | 0 |
| C or ? | 0 | 1 | 1 | 1 | 2 | 0 | 0 |
| S | 33 | 14 | 2 | 22 | 22 | 21 | 21 |
| predict cases only: R / W / S | 0 / 0 / 11 | 2 / 0 / 9 | 7 / 4 / 0 | 2 / 5 / 4 | 1 / 0 / 8, 2 ? | 1 / 0 / 10 | 1 / 0 / 10 |

What the tally says, plainly:
- **(a) says nothing on any case.** It is never wrong because it never speaks.
- **(c) is wrong more often than right.** Its errors come from free narrowing after a clade with
  few known children is "established".
- **(b) alone is silent on true cases** and wrong on every convergence case.
- **(b)+(k) is the only option that is mostly right.** In O cases that is because the records were
  entered. Its real test is the predict rows: 7 right, 4 wrong. The 4 wrong are the species that
  changed without a record. Those are Dan's candidates.
- **(d) is exact where it speaks**, and wrong three times through IBA and IEA.
- **(e) is wrong 9 times**: its strict universals. With (f) it is never wrong, but silent on 21.

---

## 9. Experiments

Ordered cheapest and most informative first. Borrow before invent.

| id | one line | cost (agent tasks) | depends on | can show wrong |
|---|---|---:|---|---|
| E0 | where does the choice matter today? | 0.5 | — | (c) as harmless |
| E1 | re-run transcription with experimental instances only | 1 | — | (c); "cleaner data fixes it" |
| E2 | the textbook's universals, their exceptions, and the closure facts on them | 1–2 | E0 | (e) strict and hedged; (f) |
| E3 | score the curated data on all 33 cases, plus a precision check | 1–2 | — | (d) |
| E4 | do curated sources record the known losses? | 1 | E3 | (b)+(d) as automatic; (l) as needed |
| E5 | define cap, prove its base case, count the sample it needs | 1 | E1 | (a) |
| E6 | homology: (k) against (h) | 1 | E3 | (h) as default; (k) |
| E7 | essentiality: test (g) for bypasses | 1 | E2 | (g) |
| E8 | measure retention in genomes, then on known losses | 2 | E1 | (i) |
| E9 | the Archezoa rivalry in `Rivalry` | 2 | — | (b) on a fixed tree; (e); `Rivalry` |
| E10 | sketch (b) and (b)+(k) in Python on all 33 cases | 2 | E3, E4, E6 | (b); (k); coherence |
| E11 | rat versus mouse: three bins and a hold-out test | 2–3 | E1, E10 | (b)+(k) as predictor; (c); (d) as complete |
| E12 | Lean prototype of the chosen rules | 3–5 | decision D3 | coherence by construction |
| E13 | optional: a real tree instead of NCBI Taxonomy | 2 | E10 | NCBI-based brackets |

(j) has no experiment. It needs tree maths, which Dan wants kept out.

### E0. Where the choice matters today

- **Do.** List every output that rests on `generalize` (predicted: only
  `Examples/Transcription.lean`). List every closure fact that rests on a textbook universal narrowed
  to a member taxon.
- **Exit test.** Two counts.
- **Shows wrong.** (c) as harmless, if anything else rests on `generalize`.
- **Cost.** Half a task.

### E1. Evidence hygiene

- **Do.** Apply "experimental, in that organism". Add Sulfolobus acidocaldarius DSM 639
  (NCBITaxon:330779, 13 IDA) to `scripts/ontology/import_isa.py`; it is not in `IsA.lean` today, so
  `Curie.encode` gives no code and it would count for nothing. Re-run the transcription table.
- **Predicted.** Six instances (E. coli, yeast, mouse, human, Arabidopsis, Sulfolobus). Cellular
  organisms: 24/25 = 0.96. Eukaryota, from four: 16/153 = 0.10, already a theorem
  (`eukaryota_bracketing_value`). The gap grows.
- **Shows wrong.** The hope that cleaner instances fix the incoherence.
- **Cost.** 1 task.

### E2. The textbook's universals and their exceptions (options e, f)

- **Do.** Take every audit row with a counterexample. At least: m45479-53 (genetic code), m45429-5
  (all cells share DNA and ribosomes), m45539-355, m45432-187 ("every cell has part ribosome"), "all
  prokaryotes have a cell wall", m45535-39 (teeth), "FtsZ is vital in prokaryotic cytokinesis". For
  each: source the exceptions from curated data (NCBI codes, UBERON never-in, CL:0000595), and verify
  one counter-instance in the literature. Count the closure facts that rest on it.
- **Also.** Encode m45479-54 as `most` and see what it still supports. Compare each universal with
  the bottom-up instances: the `canonical` agreement check from `docs/case-studies.md`.
- **Exit test.** Per sentence: exceptions sourced (yes or no); counterexample rule fires (yes or no);
  closure facts resting on it.
- **Shows wrong.** (e) strict, if the rule fires on many. (e) hedged, if `most` supports nothing
  downstream. (f), if most exceptions cannot be sourced.
- **Cost.** 1–2 tasks.

### E3. The curated data, case by case (option d)

- **Fetch.** GO's computed constraints (1.5 MB; our `isa.json` walk misses constraints that pass
  along part_of); UBERON constraints; PAINT `IBD.gaf` (7.6 MB); Bgee similarity TSV (366 KB); NCBI
  codes; QuickGO IBA, IEA and NOT counts.
- **Exit test 1.** Each of the 33 cases scored. Predicted (d): 6 R, 3 W, 2 ?, 22 S.
- **Exit test 2.** Precision. Draw 30 GO and 30 UBERON never-in constraints at random and check
  each in the literature. Write the bar down first (for example 90 percent).
- **Shows wrong.** (d) as a source, if precision is below the bar. The scorecard, if (d) differs.
- **Cost.** 1–2 tasks.

### E4. Do curated sources record the known losses?

- **Do.** Known losses: Giardia, Trichomonas, Monocercomonoides (mitochondrion); Haplorrhini and
  guinea pig (vitamin C); mammalian red cells; icefish; rat gallbladder; toothless mammals;
  planarian centrosome (Azimzadeh 2012). For each, check GO never-in, UBERON never-in, PAINT IKR and
  IRD, Bgee NOT rows. List every IBA inside a known loss lineage.
- **Already found.**
  - QuickGO has 701 IKR and 0 IRD annotations. None of the IKR are in Giardia, Trichomonas or
    Monocercomonoides.
  - PAINT (research copy of `IBD.gaf`, PANTHER 19.0) has 2,538 IRD rows, all NOT. None of the 34
    taxa on a NOT-mitochondrion node is in Metamonada.
  - GO has centrosome never in Planariidae (27896). Azimzadeh's species, *Schmidtea mediterranea*,
    is in Dugesiidae, so the constraint misses the species studied.
  - RO:0002504 "never lost in" is used 0 times in GO's constraints and in UBERON.
- **Exit test.** Recall: recorded losses over known losses.
- **Shows wrong.** (b)+(d) as an automatic pipeline, if recall is low (predicted). Then (l), or (k),
  is needed for retention.
- **Cost.** 1 task.

### E5. Cap, defined and tested (option a)

- **Do.** Write `cap` as in section 5 next to `bracketing`. Prove `cap_zero`: with today's base
  case, cap is 0 for every sample. Then use the base case "a sampled taxon covers itself" and compute
  the smallest sample that reaches 4/5 for cellular organisms and Eukaryota.
- **Exit test.** That number, against the taxa with experimental data (from E1).
- **Shows wrong.** (a), if it needs more taxa than have experimental data (predicted).
- **Cost.** 1 task. Counting NCBI children, no phylogenetics.

### E6. Homology: (k) against (h)

- **Do.** For CV1 to CV4, CVT1, CVT2, L2 (hydrogenosome) and the salamander Batrachoseps (enucleate
  red cells, convergent with mammals): check Bgee rows, UBERON homology notes, HOM relations, PANTHER
  or OMA orthology. Score (b)+(h) and (b)+(k) on each.
- **Predicted.** (h) is silent on most cases, true or false. (k) is right where the convergence is
  on record.
- **Shows wrong.** (h) as the default, if it is silent on most true homologies. (k), if convergence
  is mostly not on record. (h) from protein similarity, if it licenses CV4.
- **Cost.** 1 task.

### E7. Essentiality (option g)

- **Do.** Test "X is needed for Y, Y is universal, so X is universal" on m45432-186 (ribosomes) and
  on FtsZ. Look for bypasses: prokaryote lineages without FtsZ (UNVERIFIED until checked), and
  Monocercomonoides' swap of its iron-sulphur pathway. Check a few against a database of essential
  genes.
- **Exit test, written first.** (g) is wrong if any tested X has a documented bypass lineage that
  the rule would mark as having X.
- **Cost.** 1 task.

### E8. Measure retention in genomes (option i)

- **Do.** For U1: does every UniProt reference proteome in Bacteria, Archaea and Eukaryota have Pfam
  PF00623 (RNA polymerase Rpb1, domain 2; IPR000722) and PF00562 (Rpb2, domain 6; IPR007120)?
  Absent means no hit at the Pfam gathering threshold. Leave out proteomes that UniProt flags as
  incomplete. Check each remaining absence by hand: real loss, assembly gap or annotation gap.
- **Then the losses.** Run the same check where the loss is known and has a marker: GULO (L5), ENAM
  (L9), alpha-globin in icefish (L8). (i) should find these.
- **Exit test.** Fraction with the marker per domain; a verdict on each absence; known losses found.
- **Shows wrong.** (i), if absences are mostly gaps, or if it misses the known losses.
- **Cost.** 2 tasks. Orthology is still an inference; this moves the step, it does not remove it.

### E9. The Archezoa rivalry

- **Build.** `BioLean/Examples/Archezoa.lean`, modelled on `Examples/Chemiosmosis.lean`. Rivals:
  "LECA lacked a mitochondrion; amitochondriate lineages never had one" against "LECA had one; they
  reduced or lost it". A `BLN:` stand-in for the ancestor, as `C~I` is in Chemiosmosis.
- **Dated evidence.**
  - 1973: hydrogenosome described in *Tritrichomonas foetus* (Lindmark & Müller).
  - 1983: Archezoa proposed, in a book chapter (Cavalier-Smith); entered as `hypothesis`.
  - 1987: Nature note restates it (Cavalier-Smith).
  - 1989: Giardia rRNA branches deepest (Sogin).
  - 1995: Entamoeba carries genes of mitochondrial origin (Clark & Roger).
  - 1996: microsporidian tubulins group with fungi (Keeling & Doolittle). Trichomonas
    hydrogenosomes share an origin with mitochondria (Bui; Germot).
  - 1998: Giardia has a mitochondrial-type chaperonin (Roger).
  - 1999: mitosome named, in Entamoeba (Tovar, Fischer & Clark). Microsporidia are fungi, from RNA
    polymerase II (Hirt).
  - 2002: mitosome in a microsporidian (Williams).
  - 2003: Giardia mitosomes make iron-sulphur clusters (Tovar).
  - 2006: review rejects Archezoa (Embley & Martin).
  - 2016: a real absence, itself a secondary loss (Karnkowska).
- **Exit test, written first.** For example: Archezoa not refuted in 1990; contested by 1999;
  secondary loss established by 2006.
- **Predicted.** The 1989 tree keeps voting for Archezoa after 1999, as the 1960s refutations do in
  Chemiosmosis. A supersession link or a dated tree premise will be needed.
- **Shows wrong.** (b) on a fixed tree (NCBI has only today's tree). (e): no history. `Rivalry`, if
  secondary loss cannot reach "established".
- **Cost.** 2 tasks.

### E10. Sketch (b) and (b)+(k) on all 33 cases

- **Build.** A Python sketch in `scripts/case_studies/` style.
  - Ancestor rule, opinion set by Witmer level. Start values (belief, disbelief, uncertainty), chosen
    not fitted: level I (0.9, 0, 0.1); level II (0.5, 0, 0.5); level III (0, 0.9, 0.1), meaning
    disbelief that the ancestor had X.
  - Dollo default for complex traits (Farris 1977): one ancestor lookup plus a set difference.
  - (b): a recorded loss gives disbelief; no record gives uncertainty.
  - (b)+(k): no record gives the descent default (0.9, 0, 0.1). A record replaces it for that
    lineage.
  - Narrowing goes through retention, not for free.
- **Sensitivity.** Move each value by 0.1 and count verdict flips. Expect many: 0.9 × 0.9 = 0.81,
  just above θ = 0.8.
- **Exit test.** The measured columns against section 8. A coherence check over every pair of
  targets.
- **Shows wrong.** (b), if coherence fails. (k), if its predict-mode precision is no better than
  "always agree".
- **Cost.** 2 tasks.

### E11. Rat versus mouse

"Never seen in mouse" usually means nobody recorded it, not that it was looked for and is absent.
So the output has three bins.

- **Bins.**
  1. Agreement: observed in both, as the bracket predicts.
  2. Verified difference: observed, and departs from the bracket. Known biology.
  3. Unobserved cell filled in by the bracket: for example rat and human have X, mouse has no
     record. This is the hypothesis Dan wants.
- **Hold-out test for bin 3.** Take traits recorded in all three species. Hide mouse, predict it
  with (b)+(k), report precision. Then hide rat.
- **Data.** Alliance of Genome Resources, RGD and MGI (orthology, phenotype, expression). UBERON has
  only 7 rat or mouse never-in rows. Start from RM1 to RM5 and RMT1.
- **Curation bias, measured.** UBERON 2026-10-01 taxon annotations on Rattus and Mus:

  | kind | rat | mouse |
  |---|---:|---:|
  | never in | 1 | 6 |
  | only in | 0 | 1 (adrenal gland X zone) |
  | present in | 3 | 6 |
  | dubious for | 0 | 7 |
  | all | 4 | 20 |

  Splenic sinusoid (RM5) is the one "seen in rat, never in mouse" row.
- **Shows wrong.** (b)+(k) as a predictor, if hold-out precision is low. (c), wrong on every
  difference. (d), as complete.
- **Cost.** 2–3 tasks.

### E12. Lean prototype (only after decision D3)

- **Build.** An ancestor claim shape; a `bracket` rule with Witmer levels; an `inherit` rule that
  needs a retention premise or the (k) default; a defeat rule. New evidence kinds: phylogenetic
  distribution (ECO:0000355), IBA (ECO:0000318), IKR (ECO:0000320), IRD (ECO:0000321).
- **Exit test.** Replace `cellular_above_eukaryota` with a theorem that the narrower claim is never
  below the broader one, or a counterexample showing the extra condition.
- **Cost.** 3–5 tasks.

### E13. Optional: a real tree

- **Why optional.** It brings tree uncertainty, the maths Dan wants kept out. Run it only if E10
  shows NCBI Taxonomy gives wrong brackets.
- **Why it might be needed.** NCBI Taxonomy is not a phylogeny. Eukaryota's 18 NCBI children are a
  flat list. Eukaryotes may sit inside Archaea (Eme 2023).
- **Do.** Swap in the Open Tree of Life (Hinchliff 2015) for the target clades. Re-run E10.
- **Cost.** 2 tasks.

---

## 10. What would change the decision

| point | after | if this | then favour |
|---|---|---|---|
| D1: stop tuning coverage? | E0, E1, E5 | (c) stays high on clean data and (a) is out of reach (predicted) | keep (c) as a documented placeholder; state the bigger gap (0.96 vs 0.10) next to the theorem; do not build (a) |
| | | (c) falls and (a) is out of reach | the same, and mark the transcription universal unsupported |
| | | (a) is reachable with a few dozen taxa | (a) as a cheap coherent fix |
| D2: where does retention come from? | E3, E4, E6 | curated data recalls most known losses | (b) fed by (d) |
| | | recall is low (predicted) | (b)+(k) for prediction, with defeaters entered; (l) for the few traits that qualify; universals from (e)+(f) |
| D3: build (b)+(k) in Lean? | E9, E10 | the sketch is coherent, stable under the sensitivity check, and Archezoa replays | build E12 |
| | | coherence breaks, or verdicts flip with small changes | (b) with a cap on top, or (e)+(f) only |
| D4: molecular traits by genome? | E8 | absences are clean and the known losses are found | (i) as retention for molecular traits |
| | | absences are mostly gaps | retention stays (k) |
| D5: frame for rat versus mouse | E11 | hold-out precision is high | the bracket as a null model; bins 2 and 3 as hypotheses |
| | | bin 3 is mostly curation gaps | get experimental expression and phenotype data first |

---

## 11. Limits

What we cannot achieve, said plainly:

- **Induction never closes.** `uncertainty_pos` makes this a type invariant. At best, established.
- **"All T have X" is almost never recorded.** RO has the relation (RO:0002504); nobody asserts it.
  Retention will mostly rest on the (k) default or on no record at all.
- **NCBI Taxonomy is not a phylogeny.** Brackets near the eukaryote root are approximate.
- **Gene transfer, organelle genomes, reversals and convergence break simple rules.** Aphids took
  carotenoid genes from fungi (Moran & Jarvik 2010). A regain of wings in stick insects was reported
  (Whiting 2003) and disputed (Trueman 2004). Dollo's law is often broken (Collin & Miglietta
  2008). Bats lost vitamin C synthesis recently and stepwise (Cui 2011); one review says some bat
  genes were "reactivated" (Drouin 2011), which rests on that review only.
- **Curation bias.** Rat has 1 UBERON never-in, mouse 6 (2026-10-01). "Seen in rat, never in mouse"
  will partly measure what curators recorded.
- **Context slots do not exist yet** for population, cell type, compartment or life stage.
- **PAINT is about gene families, not organisms.** "The ancestral protein was in the mitochondrion"
  is not "the ancestral organism had a mitochondrion".
- **Witmer's levels give an order, not numbers.** The opinion per level is our choice.
- **Bracketing cannot predict the species that changed.** For rat versus mouse it gives candidates.
- **"Superseded" is curation.** The Archezoa reversal will need a human to say which evidence
  stopped counting.

Whatever wins, we learn: which instances are observations; how sparse curated loss and homology
data are; a 33-case test set; the textbook's false-as-written universals; whether `Rivalry` can
carry a second reversal.

---

## 12. References

DOI, first author, year and title checked on Crossref or Europe PMC on 2026-10-29. Only works cited
above are listed.

### Methods and data sources

- Deegan JI, Dimmer EC, Mungall CJ (2010). Formalization of taxon-based constraints to detect
  inconsistencies in annotation and ontology development. BMC Bioinformatics 11:530.
  doi:10.1186/1471-2105-11-530
- Gaudet P, Livstone MS, Lewis SE, Thomas PD (2011). Phylogenetic-based propagation of functional
  annotations within the Gene Ontology consortium. Brief Bioinform 12:449–462. doi:10.1093/bib/bbr042
- Mungall CJ et al. (2012). Uberon, an integrative multi-species anatomy ontology. Genome Biol 13:R5.
  doi:10.1186/gb-2012-13-1-r5
- Roux J, Robinson-Rechavi M (2010). An ontology to clarify homology-related concepts. Trends Genet
  26:99–102. doi:10.1016/j.tig.2009.12.012
- Bastian FB et al. (2025, online 2024). Bgee in 2024: focus on curated single-cell RNA-seq datasets,
  and query tools. Nucleic Acids Res 53:D878–D885. doi:10.1093/nar/gkae1118
- Altenhoff AM et al. (2024, online 2023). OMA orthology in 2024: improved prokaryote coverage,
  ancestral and extant GO enrichment, a revamped synteny viewer and more in the OMA Ecosystem.
  Nucleic Acids Res 52:D513–D521. doi:10.1093/nar/gkad1020
- Witmer LM (1995). The extant phylogenetic bracket and the importance of reconstructing soft tissues
  in fossils. In Thomason JJ (ed.), Functional Morphology in Vertebrate Paleontology, Cambridge
  University Press, pp. 19–33. No DOI.
- Bryant HN, Russell AP (1992). The role of phylogenetic analysis in the inference of unpreserved
  attributes of extinct taxa. Phil Trans R Soc B 337:405–418. doi:10.1098/rstb.1992.0117
- Farris JS (1977). Phylogenetic analysis under Dollo's law. Syst Zool 26:77–88. doi:10.2307/2412867
- Collin R, Miglietta MP (2008). Reversing opinions on Dollo's Law. Trends Ecol Evol 23:602–609.
  doi:10.1016/j.tree.2008.06.013
- Hinchliff CE et al. (2015). Synthesis of phylogeny and taxonomy into a comprehensive tree of life.
  PNAS 112:12764–12769. doi:10.1073/pnas.1423041112

### Biology

- Anderson S et al. (1981). Sequence and organization of the human mitochondrial genome. Nature
  290:457–465. doi:10.1038/290457a0
- Azimzadeh J et al. (2012). Centrosome loss in the evolution of planarians. Science 335:461–463.
  doi:10.1126/science.1214457
- Barrell BG, Bankier AT, Drouin J (1979). A different genetic code in human mitochondria. Nature
  282:189. doi:10.1038/282189a0
- Bui ET, Bradley PJ, Johnson PJ (1996). A common evolutionary origin for mitochondria and
  hydrogenosomes. PNAS 93:9651–9656. doi:10.1073/pnas.93.18.9651
- Burger G et al. (2013). Strikingly bacteria-like and gene-rich mitochondrial genomes throughout
  jakobid protists. Genome Biol Evol 5:418–438. doi:10.1093/gbe/evt008
- Chen L, DeVries AL, Cheng CHC (1997). Convergent evolution of antifreeze glycoproteins in
  Antarctic notothenioid fish and Arctic cod. PNAS 94:3817–3822. doi:10.1073/pnas.94.8.3817
- Cocca E et al. (1995). Genomic remnants of alpha-globin genes in the hemoglobinless antarctic
  icefishes. PNAS 92:1817–1821. doi:10.1073/pnas.92.6.1817
- Crocker PR et al. (1987). Species heterogeneity in macrophage expression of the CD4 antigen. J Exp
  Med 166:613–618. doi:10.1084/jem.166.2.613
- Cui J, Yuan X, Wang L, Jones G, Zhang S (2011). Recent loss of vitamin C biosynthesis ability in
  bats. PLoS One 6:e27114. doi:10.1371/journal.pone.0027114
- Drouin G, Godin JR, Pagé B (2011). The genetics of vitamin C loss in vertebrates. Curr Genomics
  12:371–378. doi:10.2174/138920211796429736
- Eme L et al. (2023). Inference and reconstruction of the heimdallarchaeial ancestry of eukaryotes.
  Nature 618:992–999. doi:10.1038/s41586-023-06186-2
- Fan L et al. (2020). Phylogenetic analyses with systematic taxon sampling show that mitochondria
  branch within Alphaproteobacteria. Nat Ecol Evol 4:1213–1219. doi:10.1038/s41559-020-1239-x
- He K et al. (2021). Echolocation in soft-furred tree mice. Science 372:eaay1513.
  doi:10.1126/science.aay1513
- Higashiyama H et al. (2018, online 2017). Anatomy and development of the extrahepatic biliary
  system in mouse and rat: a perspective on the evolutionary loss of the gallbladder. J Anat
  232:134–145. doi:10.1111/joa.12707
- Holling TM, Schooten E, van den Elsen PJ (2004). Function and regulation of MHC class II molecules
  in T-lymphocytes: of mice and men. Hum Immunol 65:282–290. doi:10.1016/j.humimm.2004.01.005
- Horn CC et al. (2013). Why can't rodents vomit? A comparative behavioral, anatomical, and
  physiological study. PLoS One 8:e60537. doi:10.1371/journal.pone.0060537
- Jeffery WR (2009). Regressive evolution in Astyanax cavefish. Annu Rev Genet 43:25–47.
  doi:10.1146/annurev-genet-102108-134216
- Ji P, Murata-Hori M, Lodish HF (2011). Formation of mammalian erythrocytes: chromatin
  condensation and enucleation. Trends Cell Biol 21:409–415. doi:10.1016/j.tcb.2011.04.003
- Karnkowska A et al. (2016). A eukaryote without a mitochondrial organelle. Curr Biol
  26:1274–1284. doi:10.1016/j.cub.2016.03.053
- Lang BF et al. (1997). An ancestral mitochondrial DNA resembling a eubacterial genome in
  miniature. Nature 387:493–497. doi:10.1038/387493a0
- Li Y et al. (2010). The hearing gene Prestin unites echolocating bats and whales. Curr Biol
  20:R55–R56. doi:10.1016/j.cub.2009.11.042
- Liu Y et al. (2010). Convergent sequence evolution between echolocating bats and dolphins. Curr
  Biol 20:R53–R54. doi:10.1016/j.cub.2009.11.058
- Maeda N et al. (2000). Aortic wall damage in mice unable to synthesize ascorbic acid. PNAS
  97:841–846. doi:10.1073/pnas.97.2.841
- Martijn J, Vosseberg J, Guy L, Offre P, Ettema TJG (2018). Deep mitochondrial origin outside the
  sampled alphaproteobacteria. Nature 557:101–105. doi:10.1038/s41586-018-0059-5
- Meredith RW, Gatesy J, Murphy WJ, Ryder OA, Springer MS (2009). Molecular decay of the tooth gene
  Enamelin (ENAM) mirrors the loss of enamel in the fossil record of placental mammals. PLoS Genet
  5:e1000634. doi:10.1371/journal.pgen.1000634
- Moran NA, Jarvik T (2010). Lateral transfer of genes from fungi underlies carotenoid production in
  aphids. Science 328:624–627. doi:10.1126/science.1187113
- Oftedal OT (2002). The origin of lactation as a water source for parchment-shelled eggs. J Mammary
  Gland Biol Neoplasia 7:253–266. doi:10.1023/A:1022848632125
- Ogura A, Ikeo K, Gojobori T (2004). Comparative analysis of gene expression for convergent
  evolution of camera eye between octopus and human. Genome Res 14:1555–1561. doi:10.1101/gr.2268104
- Paredez AR et al. (2011). An actin cytoskeleton with evolutionarily conserved functions in the
  absence of canonical actin-binding proteins. PNAS 108:6151–6156. doi:10.1073/pnas.1018593108
- Parker J et al. (2013). Genome-wide signatures of convergent evolution in echolocating mammals.
  Nature 502:228–231. doi:10.1038/nature12511
- Pollock JI, Mullin RJ (1987). Vitamin C biosynthesis in prosimians: evidence for the anthropoid
  affinity of Tarsius. Am J Phys Anthropol 73:65–70. doi:10.1002/ajpa.1330730106
- Preer JR et al. (1985). Deviation from the universal code shown by the gene for surface protein
  51A in Paramecium. Nature 314:188. doi:10.1038/314188a0
- Ruud JT (1954). Vertebrates without erythrocytes and blood pigment. Nature 173:848–850.
  doi:10.1038/173848a0
- Sage RF, Christin PA, Edwards EJ (2011). The C4 plant lineages of planet Earth. J Exp Bot
  62:3155–3169. doi:10.1093/jxb/err048
- Santos MA, Tuite MF (1995). The CUG codon is decoded in vivo as serine and not leucine in Candida
  albicans. Nucleic Acids Res 23:1481. doi:10.1093/nar/23.9.1481
- Sloan DB et al. (2012). Rapid evolution of enormous, multichromosomal genomes in flowering plant
  mitochondria with exceptionally high mutation rates. PLoS Biol 10:e1001241.
  doi:10.1371/journal.pbio.1001241
- Teeling EC et al. (2000). Molecular evidence regarding the origin of echolocation and flight in
  bats. Nature 403:188–192. doi:10.1038/35003188
- Thaler L, Arnott SR, Goodale MA (2011). Neural correlates of natural human echolocation in early
  and late blind echolocation experts. PLoS One 6:e20162. doi:10.1371/journal.pone.0020162
- Thomas GW, Hahn MW (2015). Determining the null model for detecting adaptive convergence from
  genomic data: a case study using echolocating mammals. Mol Biol Evol 32:1232–1236.
  doi:10.1093/molbev/msv013
- Trueman JWH, Pfeil BE, Kelchner SA, Yeates DK (2004). Did stick insects really regain their wings?
  Syst Entomol 29:138–139. doi:10.1111/j.0307-6970.2004.00251.x
- Tovar J et al. (2003). Mitochondrial remnant organelles of Giardia function in iron-sulphur
  protein maturation. Nature 426:172–176. doi:10.1038/nature01945
- Werner F, Grohmann D (2011). Evolution of multisubunit RNA polymerases in the three domains of
  life. Nat Rev Microbiol 9:85–98. doi:10.1038/nrmicro2507
- Whiting MF, Bradler S, Maxwell T (2003). Loss and recovery of wings in stick insects. Nature
  421:264–267. doi:10.1038/nature01313
- Woese CR, Fox GE (1977). Phylogenetic structure of the prokaryotic domain: the primary kingdoms.
  PNAS 74:5088. doi:10.1073/pnas.74.11.5088
- Yamamoto Y, Jeffery WR (2000). Central role for the lens in cave fish eye degeneration. Science
  289:631–633. doi:10.1126/science.289.5479.631
- Yamao F et al. (1985). UGA is read as tryptophan in Mycoplasma capricolum. PNAS 82:2306.
  doi:10.1073/pnas.82.8.2306
- Zhuang X et al. (2019). Molecular mechanism and history of non-sense to sense evolution of
  antifreeze glycoprotein gene in northern gadids. PNAS 116:4400–4405. doi:10.1073/pnas.1817138116
- Zou Z, Zhang J (2015). No genome-wide protein sequence convergence for echolocation. Mol Biol Evol
  32:1237–1241. doi:10.1093/molbev/msv014

### Archezoa timeline (E9)

- Lindmark DG, Müller M (1973). Hydrogenosome, a cytoplasmic organelle of the anaerobic flagellate
  Tritrichomonas foetus, and its role in pyruvate metabolism. J Biol Chem 248:7724–7728.
  doi:10.1016/S0021-9258(19)43249-3
- Cavalier-Smith T (1983). Book chapter in Endocytobiology II. No DOI. The date and the groups
  (Microsporidia, Parabasalia, Metamonada, Archamoebae) are from Hirt 1999.
- Cavalier-Smith T (1987). Eukaryotes with no mitochondria. Nature 326:332–333. doi:10.1038/326332a0
- Sogin ML et al. (1989). Phylogenetic meaning of the kingdom concept: an unusual ribosomal RNA from
  Giardia lamblia. Science 243:75–77. doi:10.1126/science.2911720
- Clark CG, Roger AJ (1995). Direct evidence for secondary loss of mitochondria in Entamoeba
  histolytica. PNAS 92:6518–6521. doi:10.1073/pnas.92.14.6518
- Keeling PJ, Doolittle WF (1996). Alpha-tubulin from early-diverging eukaryotic lineages and the
  evolution of the tubulin family. Mol Biol Evol 13:1297–1305.
  doi:10.1093/oxfordjournals.molbev.a025576
- Germot A, Philippe H, Le Guyader H (1996). Presence of a mitochondrial-type 70-kDa heat shock
  protein in Trichomonas vaginalis suggests a very early mitochondrial endosymbiosis in eukaryotes.
  PNAS 93:14614–14617. doi:10.1073/pnas.93.25.14614
- Roger AJ et al. (1998). A mitochondrial-like chaperonin 60 gene in Giardia lamblia: evidence that
  diplomonads once harbored an endosymbiont related to the progenitor of mitochondria. PNAS
  95:229–234. doi:10.1073/pnas.95.1.229
- Tovar J, Fischer A, Clark CG (1999). The mitosome, a novel organelle related to mitochondria in the
  amitochondrial parasite Entamoeba histolytica. Mol Microbiol 32:1013–1021.
  doi:10.1046/j.1365-2958.1999.01414.x
- Hirt RP et al. (1999). Microsporidia are related to Fungi: evidence from the largest subunit of RNA
  polymerase II and other proteins. PNAS 96:580–585. doi:10.1073/pnas.96.2.580
- Williams BAP et al. (2002). A mitochondrial remnant in the microsporidian Trachipleistophora
  hominis. Nature 418:865–869. doi:10.1038/nature00949
- Embley TM, Martin W (2006). Eukaryotic evolution, changes and challenges. Nature 440:623–630.
  doi:10.1038/nature04546

### IDs checked (OLS4 and NCBI, 2026-10-29)

- RO: RO:0002162 in taxon; RO:0002160 only in taxon (obsolete); RO:0002161 never in taxon;
  RO:0002175 present in taxon; RO:0002174 dubious for taxon; RO:0002173 ambiguous for taxon;
  RO:0002504 always present in taxon ("never lost in"); RO:0001000 derives from; RO:0001001 derives
  into.
- ECO: ECO:0000355 phylogenetic distribution evidence; ECO:0000318 IBA; ECO:0000320 IKR;
  ECO:0000321 IRD.
- Every other GO, UBERON, CL, HOM, Pfam (InterPro) and NCBITaxon ID in the text, including
  330779 Sulfolobus acidocaldarius DSM 639, 687454 Typhlomys, 79327 Schmidtea mediterranea
  (Dugesiidae), 27896 Planariidae and 314146 Euarchontoglires.

**Constraints checked.**
- GO computed constraints: GO:0005739 and GO:0032047 only in Eukaryota; GO:0006351 none; GO:0050959
  only in Amniota, never in Mus musculus and Primates; GO:0019853 never in Ascomycota and Homo
  sapiens; GO:0007595 only in Mammalia; GO:0016117 never in S. pombe and S. cerevisiae, nothing on
  animals; GO:0005813 never in Planariidae, Viridiplantae and Fungi.
- UBERON 2026-10-01: gallbladder never in Rattus, Struthio camelus and Columbidae; calcareous tooth
  never in Aves, Ornithorhynchus, Tachyglossidae and Mysticeti; splenic sinusoid never in Mus,
  Felidae and Sus, present in Rattus; adrenal gland X zone only in Mus.
- NCBI genetic codes (nuclear, mitochondrial): human, rat and mouse 1 and 2; Mycoplasma capricolum
  4; Paramecium 6; Candida albicans 12; S. cerevisiae 1 and 3; E. coli 11.

### UNVERIFIED

- Cavalier-Smith 1983: the chapter's title and pages. Whether the 1987 note still included
  Parabasalia.
- Witmer 1995: that the levels are "only partly ordered" (the PDF is image-only).
- Icefish: whether a few non-functional erythrocyte-like cells remain. Haemoglobin loss is solid.
- Rat activated T cells expressing MHC class II (RM2). Whether wild mice, not just lab strains, lack
  MHC II on T cells and CD4 on macrophages.
- Splenic sinusoids absent in mouse (RM5): from UBERON and the JAX Green Book only.
- Which octopus species Ogura 2004 studied (its abstract does not say).
- Platypus: UBERON says tooth never in Ornithorhynchus, but juveniles are reported to have teeth
  (general knowledge, not checked). This may be a life-stage gap in UBERON.
- Batrachoseps enucleate red cells: secondary mention only.
- Within-bat echolocation history; where the eukaryote root sits.
- That PF00623 and PF00562 catch the bacterial and archaeal subunits as well as the eukaryotic ones;
  that every UniProt reference proteome carries a completeness flag.
- Prokaryote lineages without FtsZ; which essential-gene database to use.
- The bat GULO "reactivation" (Drouin 2011 review only).
- Research counts not re-checked: 232 of 2,287 closure facts; about 19 R2
  statements turned "some/most" into "every"; about 40 R2 statements lost their taxon (41 by one
  recount); the audit's per-category counts.
- PAINT counts (2,538 IRD rows; 10,732 rows with an empty taxon; no NOT-mitochondrion node in
  Metamonada) are on the research copy of `IBD.gaf` (PANTHER 19.0), not a fresh download. The
  meaning of the empty-taxon rows is unknown.
- The 30 *T. vaginalis* IBA annotations to "mitochondrial electron transport" all come from one
  PANTHER node (PTN000393767). They look like a propagation error. The tree was not inspected.
- Every textbook counterexample in E2 (red cells aside): Mycoplasma walls, FtsZ-less prokaryotes and
  so on. E2 must verify them.
- PANTHER's licence; the GOTaxonRange repository has no licence; OMA's licence.
- All scorecard cells. They are predictions.
