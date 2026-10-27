# STATUS

Where BioLean stands, what we have learned, and what is open. Updated at milestones, not per
commit. History of findings and decisions: [CHANGELOG.md](CHANGELOG.md). Direction: [ROADMAP.md](ROADMAP.md).

Last updated 2026-10-27.

## What exists

| piece | state | where |
|---|---|---|
| Lean core: opinions over ℚ, fuse, chain, proved laws | built, `lake build` green | `BioLean/Belief.lean` |
| Claim shape: signed effect, mediatedBy, five targets, nine entity kinds | built | `BioLean/Claim.lean`, `Ontology.lean` |
| Statements with PMID evidence, swappable reliability table | built | `BioLean/Evidence.lean` |
| Derivation (lit, viaActivity, viaAmount, both), axioms, verdicts, `Established` | built, `decide +kernel` | `BioLean/Derivation.lean` |
| Demo: semaglutide reduces feeding, 12 statements, 66 verified quotes | built, theorems check | `BioLean/Examples/Ozempic.lean` |
| Python pipeline: corpus → Claude extraction → grounding → Lean | runs; 15 of 22 abstracts extracted | `biolean/` |
| Formalism survey: 11 papers in 6 formalisms | done | `docs/formalisms/` |
| Case studies: chemiosmotic timeline, NMN context, transcription generalisation | sketches in Python | `docs/case-studies.md`, `scripts/case_studies/` |
| Textbook milestone: 4,695 claims from 7 OpenStax chapters, binned and verified | done, data committed | `docs/textbook-milestone.md`, `data/textbook/claims/` |
| Proposed Context extension (Context.lean, inContext, noEffect, gradient, hypothesis kind) | drafted, builds in a scratch copy, not merged | `docs/formalisms/biolean.md` §5 |

## What we have learned

1. **Shape in the kernel, strength outside it works.** Lean certifies the arithmetic, never the
   0.85. The reliability table is a table of pseudo-counts (an RCT at 0.85 is 11 observations),
   which is the honest way to argue about it.
2. **Cumulative fusion never forgets.** The chemiosmotic claim stays "unsupported" in 1994 because
   1960s refutations keep voting. Needs rivals with mutual exclusion, or supersession.
3. **Context must live inside the claim.** Otherwise mouse and human evidence fuse silently. Four of
   six surveyed formalisms make that mistake.
4. **No formalism has dose, duration, age or strain.** Not GO-CAM, INDRA, Biolink, BEL, nanopub,
   nor us. There is no identifier for C57BL/6N anywhere.
5. **Only nanopub + SEPIO represents an argument** (hypothesis vs finding, supporting vs disputing
   evidence, contradicts, supersedes). Borrow that layer.
6. **Ontologies name everything and state almost nothing.** 93 percent of textbook entity mentions
   ground; 15 percent of structural claims are axioms; GO's photosynthesis term has no has_input,
   has_output or occurs_in. Canon is in definition text, not logic.
7. **Signed effects are a dialect.** 8.8 percent of textbook claims fit the current schema, 21
   percent with Context. Six RO relations (is_a, part_of/has_part, located_in/occurs_in,
   capable_of, has_input/has_output, sequence) plus quantity cover most of the rest.
8. **The chain core is right but starved.** 52 textbook sentences are theorems of others; 24 are
   blocked only because structural claims are not constructors. Proofs sharpened two sentences
   (codon degeneracy, tortoiseshell cats) and exposed 8 holes, which are hypotheses in ILP terms.
9. **RO already contains the derivation rules we invented.** `ro.owl` has 711 relations, 336
   property-chain axioms and 45 transitive properties. `occurs_in ∘ part_of ⊑ occurs_in` is the
   rule the derivation study called `occursInLift`. These are machine-readable and importable.
   RO's first-order-logic (CLIF) annotations are sparse (3 in the release) and unchecked; BFO 2020's
   full CLIF axiomatisation is the checked one.
10. **Induction never closes.** `uncertainty_pos` is a type invariant, so a universal is never
    proved, only established. The coverage discount for `generalize` is a stated judgment; clade
    fraction is too harsh, phylogenetic bracketing is what biologists do.

## Open decisions

| decision | options | leaning |
|---|---|---|
| structural claims | new Claim constructors per RO relation vs a generic `Claim.rel (r : RO) a b` | generic, typed by RO domain/range |
| derivation rules for structure | hand-write vs import RO property chains | import, hand-check |
| evidence kinds | keep 8-way enum vs ECO codes with a reliability map | ECO |
| coverage measure for generalize | clade fraction vs phylogenetic bracketing | bracketing |
| base rate per claim | fixed 1/2 vs per-claim prior | per claim, source undecided |
| rivals | id list on Statement vs multinomial opinion over alternatives | start with id list |

## Known limits (not fixable inside the framework; must be stated)

Evidence independence; mechanism is not magnitude; supersession is curation; induction never
closes; transfer reliability is one number for a mechanism-dependent step.
