# Case studies: what each example forces

Written 2026-10-27. Four worked examples, each chosen to stress a different part of the
framework. For each: the question, what the framework had to express, the **decisions** it forced
(choices we could make differently), the **gaps** it exposed (missing but buildable), and the
**limits** it hit (not fixable inside the framework; must be stated as assumptions).

Numbers below come from `scripts/case_studies/*.py`, which mirror `Opinion.fuse` in
`BioLean/Belief.lean`. Case 1 is built and checked in Lean; cases 2 to 4 were sketches when written
(case 4 is now built too, with its Lean numbers at the end of its section).

## 1. Semaglutide reduces feeding (built: `BioLean/Examples/Ozempic.lean`)

Question: does a drug reduce hunger? Shape: direct clinical evidence fused with a two-step
mechanistic chain; a rival drug (sitagliptin) whose chain predicts an effect the clinic does not see.

- **Decisions.** Shape in the kernel, strength as a computed opinion. Cumulative fusion for
  independent evidence. Chain as belief product with zero disbelief. Thresholds θ = 4/5, τ = 1/4.
  Eight evidence kinds with hand-set reliabilities.
- **Gaps.** Evidence independence (reviews restating trials). Reading reliability mixed with study
  strength. Chains hide conflict in their links.
- **Limits.** Mechanism is not magnitude: a sign-correct chain says nothing about effect size, so
  sitagliptin's chain and clinic can only be reported as *contested*, never reconciled.

## 2. The chemiosmotic controversy, 1961 to 1994 (`chemiosmotic_timeline.py`)

Question: can the framework show a hypothesis moving from fringe to canon? Shape: one claim,
evidence items dated, opinion recomputed at each year.

| year | b | d | verdict |
|---|---:|---:|---|
| 1961 | 0.70 | 0.00 | unsupported (one theory paper) |
| 1965 | 0.40 | 0.43 | contested |
| 1974 | 0.59 | 0.32 | contested |
| 1994 | 0.70 | 0.24 | **unsupported** |

With plain cumulative fusion the claim never becomes established: 1960s refutations keep voting
forever. Marking them superseded by the 1974 reconstitution gives b = 0.86 in 1974 and 0.91 in 1994.

- **Decisions.** Evidence needs a year and the opinion needs an `opinionAt` cut. Refuting items
  that were later shown wrong must stop counting: either an explicit *supersedes* relation, or
  (better) they are re-read as *support for a rival claim*, and rivals are mutually exclusive so a
  rival's collapse removes its weight. Hypothesis papers need their own evidence kind at weight 0.
- **Gaps.** No `rivals` link, no `hypothesis` kind, no `noEffect` claim (Mitchell & Moyle's
  decisive result is a true null). Reviews that restate the prevailing view count as independent
  refutation at 0.6, which is too generous.
- **Limits.** "Superseded" is a curatorial judgment, not a computation; the framework can record and
  propagate it but not discover it.

Six external formalisms were tried on these papers: see [formalisms/README.md](formalisms/README.md).
Only nanopublications + SEPIO represent the argument structure natively.

## 3. NMN in mice, and in people (`formalisms/`)

Question: can a result in mice be used for a claim about humans? Shape: five papers, four in mice
with different strains, ages, diets and durations, one human RCT.

- **Decisions.** Context (taxon, anatomy, cell type, disease model, stage, exposure) goes *inside
  the claim*, so a mouse claim and a human claim are different claims and never fuse by accident.
  Cross-species transfer is an explicit derivation rule with its own low reliability, calibrated
  from the animal-to-human translation literature, not a free pooling step.
- **Gaps.** No context slot today, so the 2011 mouse, 2016 mouse and 2021 human results fuse into
  one opinion. No field for dose, duration, age, sex or strain in *any* surveyed formalism; no ID for
  C57BL/6N anywhere. Phenotype terms (MP "impaired glucose tolerance") already carry a direction, so
  signs become double negatives. No "restores to normal", "partly via", "augmented by".
- **Limits.** Transfer reliability is one number for a step that depends on the specific
  mechanism's conservation. Pearl and Bareinboim's transportability gives the conditions, but
  filling the selection diagram needs knowledge the literature rarely states.

## 4. DNA is transcribed to RNA: how canon bubbles up (built: `BioLean/Examples/Transcription.lean`; sketch `transcription_generalize.py`)

Question: how do thousands of instance results become one textbook statement in biolib? Shape: a
`generalize` rule taking instance derivations in specific contexts to the claim at a wide context
(NCBITaxon:131567, cellular organisms), with the fused opinion discounted by coverage.

| instances | fused b | coverage (clades of 6) | universal b | verdict |
|---|---:|---:|---:|---|
| E. coli | 0.90 | 1/6 | 0.15 | unsupported |
| + yeast, mouse, human | 0.97 | 1/2 | 0.48 | unsupported |
| + Arabidopsis | 0.97 | 2/3 | 0.65 | unsupported |
| same, target = Metazoa | 0.94 | 1 | 0.94 | established |

- **Decisions.** The coverage measure. Clade fraction (above) is too harsh: five model organisms
  spanning Bacteria and three eukaryote kingdoms leave transcription "unsupported" as a universal.
  The alternative is phylogenetic bracketing: if sampled taxa sit on both sides of the deepest
  split, the trait is inferred for the common ancestor and the discount applies only to the chance
  of loss in unsampled lineages. Bracketing is what biologists actually do; it needs the taxonomy
  tree, which the ontology supplies. Second decision: canon also comes top-down, as a `canonical`
  evidence kind citing a textbook or a GO definition, and bottom-up and top-down should agree.
  Third: promotion to biolib is a threshold on belief *and* coverage, after which `axioms` stops
  expanding, like a Mathlib lemma.
- **Gaps.** `Context`, `generalize`, a coverage function over NCBITaxon and UBERON/CL, a
  `canonical` evidence kind. The first three are built for NCBITaxon (`Ctx`, `Derivation.generalize`,
  `BioLean/Coverage.lean`); UBERON/CL coverage and the `canonical` kind are not.
- **Limits.** Induction. No finite set of instances proves a universal; `uncertainty_pos` makes
  this a type invariant, so a universal is never proved, only established. The coverage discount is
  a stated judgment, not a theorem. Exceptions are handled by context, not by weight: retroviral
  reverse transcription refutes "information flows only DNA → RNA → protein" and does not touch
  "DNA is transcribed to RNA in cellular organisms", because viruses lie outside the context.

**Built in Lean** (`BioLean/Examples/Transcription.lean`, 2026-10-29). Each instance is one curated-
database item (QuickGO annotation counts), belief 0.8. Children are NCBI's (bins such as
"unclassified" left out), leaves are biolib's. Bracketing recurses into a lone sampled child,
scaled by that child's share. Every number is a theorem or `#eval` in the file.

| target | sampled | children covered / NCBI | bracketing | b | leaves covered / known | clade fraction | b |
|---|---:|---|---:|---:|---|---:|---:|
| *five model organisms* | | | | | | | |
| cellular organisms | 5 | 2 / 3 | 2/3 | 0.63 | 5 / 71 | 5/71 | 0.07 |
| Eukaryota | 4 | 2 / 18 | 1/9 | 0.10 | 4 / 60 | 1/15 | 0.06 |
| Opisthokonta | 3 | 2 / 6 | 1/3 | 0.31 | 3 / 36 | 1/12 | 0.08 |
| Metazoa | 2 | 1 / 2 | 1/512 | 0.002 | 2 / 31 | 2/31 | 0.06 |
| *plus Euglena, Paramecium, Halobacterium* | | | | | | | |
| cellular organisms | 8 | 3 / 3 | 1 | 0.97 | 8 / 71 | 8/71 | 0.11 |
| Eukaryota | 6 | 4 / 18 | 2/9 | 0.21 | 6 / 60 | 1/10 | 0.10 |

What it says: bracketing establishes a universal (belief 4/5) only once about four fifths of the
clade's NCBI children hold a sample, since the fused belief is always below 1. That means all 3 for
cellular organisms, 5 of 6 for Opisthokonta (with at least six instances), and 15 of 18 for
Eukaryota. Five model organisms touch 2 of Eukaryota's 18 lineages, so they say almost nothing about
eukaryotes as a whole (0.10). Adding Euglena and Paramecium only doubles that (0.21). Samples inside
a single child can never establish anything: they get at most one share (`bracketing_single`).
Recursing into that child turns the old cliff into a steep slope: mouse plus human gave Metazoa 0,
and now give 1/512. A sharp edge remains at the top level, where a sampled child counts as covered
however thinly it is sampled. So with all eight instances, "in cellular organisms" is established
(0.97) while "in Eukaryota", which it entails, sits at 0.21 (`cellular_above_eukaryota`). Clade
fraction stays near 0.1 throughout, because 31 of biolib's 71 known cellular leaves are animals.

## Consolidated

| item | kind | surfaced by | status |
|---|---|---|---|
| shape in kernel, strength computed | decision | 1 | built |
| cumulative fusion; chain as product | decision | 1 | built; chain hides conflict |
| evidence year + `opinionAt` | decision | 2 | sketch |
| `hypothesis` evidence kind, weight 0 | gap | 2 | proposed in formalisms/biolean.md |
| `Statement.rivals`, mutual exclusion | gap | 2 | proposed |
| `Claim.noEffect` (true null) | gap | 2, 3 | proposed |
| `Context` inside the claim | decision | 3, 4 | proposed; builds in scratch copy |
| explicit `transport` rule, low reliability | decision | 3 | not started |
| dose / duration / age / strain slot | gap | 3 | no formalism has it |
| `generalize` with coverage discount | decision | 4 | sketch; measure undecided |
| `canonical` evidence kind | gap | 4 | not started |
| promotion threshold for biolib | decision | 4 | not started |
| ECO codes in place of 8 kinds | gap | 1, 3 | not started |
| base rate per claim (`prob` uses 1/2) | gap | all | not started |
| independence of evidence | limit | 1, 2 | partial (PMID dedupe) |
| mechanism ≠ magnitude | limit | 1 | stated |
| supersession is curation | limit | 2 | stated |
| induction never closes | limit | 4 | encoded as `uncertainty_pos` |
