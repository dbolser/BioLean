# STATUS

Where BioLean stands, what we have learned, and what is open. Updated at milestones, not per
commit. History of findings and decisions: [CHANGELOG.md](CHANGELOG.md). Direction: [ROADMAP.md](ROADMAP.md).

Last updated 2026-10-28 (after M3).

## What exists

| piece | state | where |
|---|---|---|
| Lean core: opinions over ℚ, fuse, chain, proved laws | built, `lake build` green | `BioLean/Belief.lean` |
| Claim shape: signed effect, mediatedBy, five targets, eleven entity kinds | built | `BioLean/Claim.lean`, `Ontology.lean` |
| Relational claims `Claim.rel` / `Claim.notRel` over RO, typed by RO domain and range | built (M1) | `BioLean/Rel.lean`, `Claim.lean` |
| RO imported as data: 642 relations, 164 property chains (126 enabled, 38 blocked after hand-check), 124 inverses, 45 transitive; release pinned | generated from ro.owl | `BioLean/RO.lean`, `scripts/ro/`, `docs/ro-chain-check.md` |
| Ontology is_a imported as data: ancestor closure of the 1,158 used GO, UBERON, CL, ChEBI and NCBITaxon CURIEs (of 1,493 used), 2,911 terms and 4,060 edges, NCBITaxon via OLS4; search tree for fast `decide`; 9 retired used terms | generated | `BioLean/Ontology/IsA.lean`, `scripts/ontology/import_isa.py`, `Tests/IsA.lean` |
| Derivation rules `relChain` (RO chains, transitivity, is_a laws), `relInv`, `notRelSub/Obj`, `clash` | built | `BioLean/Derivation.lean` |
| Textbook example: produces, occurs_in lift, part_of transitivity, is_a inheritance, inherited negation | built, theorems check | `BioLean/Examples/Textbook.lean` |
| The textbook as Lean, round 2 (Sonnet, structured): 1,594 emitted, 1,591 compile | generated, outside the lib build | `BioLean/Lib/TextbookClaimsR2/`, `docs/textbook-lean-check.md` |
| RO pinning tests | built, pass | `BioLean/Tests/RO.lean` |
| Context (M2): entity refinement, `Ctx`/`inCtx`, transport between sibling taxa, protocol on Evidence; S1-S5 pass | built | `BioLean/Context.lean`, `Taxa.lean`, `Examples/Context.lean`, `Tests/Context.lean` |
| Argument layer (M2): `hypothesis` kind, `noEffect`, `opinionAt` by year, `Rivalry`; chemiosmotic timeline as theorems | built | `BioLean/Rivalry.lean`, `Examples/Chemiosmosis.lean` |
| Quantity (M3): counts, cardinalities, intervals, yields, some/most; 6 arithmetic rules; 7 theorems | built | `BioLean/Examples/Quantity.lean` |
| Closure search over the textbook; 60 derived facts certified | built | `scripts/search/`, `BioLean/Examples/Closure.lean`, `docs/closure-search.md` |
| Statements with PMID evidence, swappable reliability table | built | `BioLean/Evidence.lean` |
| Derivation (lit, viaActivity, viaAmount, both), axioms, verdicts, `Established` | built, `decide +kernel` | `BioLean/Derivation.lean` |
| Demo: semaglutide reduces feeding, 12 statements, 66 verified quotes | built, theorems check | `BioLean/Examples/Ozempic.lean` |
| Python pipeline: corpus → Claude extraction → grounding → Lean | runs; 15 of 22 abstracts extracted | `biolean/` |
| Formalism survey: 11 papers in 6 formalisms | done | `docs/formalisms/` |
| Case studies: chemiosmotic timeline, NMN context, transcription generalisation | sketches in Python | `docs/case-studies.md`, `scripts/case_studies/` |
| Textbook milestone: 4,695 claims from 7 OpenStax chapters, binned and verified | done, data committed | `docs/textbook-milestone.md`, `data/textbook/claims/` |
| Proposed Context extension (Context.lean, inContext, noEffect, gradient, hypothesis kind) | superseded: context by refinement, `noEffect` and `hypothesis` merged; `gradient` not | `docs/formalisms/biolean.md` §5 |

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
9. **RO already contains the derivation rules we invented.** `ro.owl` has 711 object properties
   (642 RO/BFO), 164 property-chain axioms, 124 inverse pairs and 45 transitive properties. `occurs_in ∘ part_of ⊑ occurs_in` is the
   rule the derivation study called `occursInLift`. These are machine-readable and importable.
   RO's first-order-logic (CLIF) annotations are sparse (3 in the release) and unchecked; BFO 2020's
   full CLIF axiomatisation is the checked one.
10. **RO has errors, and the import found them.** The hand-check of 164 chains gave 44 sound, 76
    sound with caveat, 25 suspicious, 19 wrong. Seven are faithful imports of bad RO axioms:
    `starts_with ∘ ends_with ⊑ immediately_preceded_by` makes a process preceded by its own part;
    `located_in ∘ inverse(located_in) ⊑ spatially_coextensive_with` makes two things in one room
    coextensive; three chains on `indirectly negatively regulates` give neg ∘ neg = neg, contradicting
    RO's own neg ∘ neg = pos. 38 chains are blocked by default (`RO.chainsBlocked`). Fixing the seven changes nothing else
    under a reasoner (`docs/ro-fix-regression.md`); issues posted as obo-relations #897 to #900 (`docs/ro-issues.md`).
11. **Re-annotation, not heuristics, and Sonnet, not Haiku.** Measured expressibility after M1 is
    34 percent emitted and compiled (1,591 of 4,695), 41 percent counting context-needing and
    unsupported-ontology claims. Haiku's round gave 17 percent with a noisy parser; the construct-name
    heuristic said 63. Structured output compiles at 99.8 percent, so the compile rate now measures
    the biology and the schema.
12. **OAK beats Gilda as the local grounder.** 80 percent agreement with agents where both answer
    (Gilda 45), covers the OBO ontologies offline; neither handles paraphrase or plurals, so agents
    stay for the ~1,100 long-tail mentions.
12a. **Gilda is a checker, not a grounder, for us.** It covers GO, ChEBI, UniProt, MeSH, HGNC; not
    UBERON, CL, NCBITaxon, MONDO. 691 of 802 disagreements with the agents were namespace-only; on
    same-namespace disagreements it picks the literal label where agents picked a context-specific
    child. Use it to catch hallucinated GO/ChEBI ids.
13. **Rules valid for individuals are not valid for class-level claims.** The closure search derived
    "DNA is_a messenger RNA" and "salivary glands overlap ganglia" through inverse and is_a rules
    that hold for instances. Our claims are existentials ("every A has some B"); forward chains,
    transitivity and is_a inheritance compose them soundly, inversion does not. `relInv` is gone.
14. **Static sign algebra cannot hold a loop.** Chaining through "ATP inhibits sugar catabolism" turns
    every ATP-producing process into an inhibitor of catabolism. Formally right, biologically
    misleading. 56 of 73 effect conclusions in the closure go through it.
15. **Induction never closes.** `uncertainty_pos` is a type invariant, so a universal is never
    proved, only established. The coverage discount for `generalize` is a stated judgment; clade
    fraction is too harsh, phylogenetic bracketing is what biologists do.

## Open decisions

| decision | options | leaning |
|---|---|---|
| structural claims | decided: generic `Claim.rel r a b`, typed by RO domain/range (M1) | done |
| derivation rules for structure | decided: RO chains imported as data, `RO.chainOK` decides (M1) | done; hand-check pending |
| weight of logical steps | decided: RO-chain steps use `Opinion.weakest` (min belief), after the chain-length experiment showed sound 12-step partonomies falling to 0.28 under product | done |
| feedback loops | flag chains through self-inhibiting nodes, or add `Claim.loop` | open |
| `isaInheritEffect` rule | a is_a b, b →s t ⊢ a →s t; sound, 56 uses in the closure; added in M2 (`Derivation.isaInheritEffect`, opinion `weakest`) | done |
| `Target.disease` | one textbook claim (obesity causes T2D) needs a disease target | open, small |
| caveated chains / trivial conclusions | decided in principle (Dan, 2026-10-28): use information content of the ontology term (Resnik: -log p from descendant count or annotation frequency) as the triviality threshold for conclusions, replacing the hub list in the closure search and the flat discount idea. Not implemented | open |
| evidence kinds | keep 8-way enum vs ECO codes with a reliability map | ECO |
| coverage measure for generalize | clade fraction vs phylogenetic bracketing | bracketing |
| base rate per claim | fixed 1/2 vs per-claim prior | per claim, source undecided |
| rivals | id list on Statement vs multinomial opinion over alternatives | built as `Rivalry` (one step, own beliefs); double counts evidence entered on both rivals; multinomial later |

## Known limits (not fixable inside the framework; must be stated)

Evidence independence; mechanism is not magnitude; supersession is curation; induction never
closes; transfer reliability is one number for a mechanism-dependent step.
