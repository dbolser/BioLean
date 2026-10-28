# CHANGELOG

Findings and decisions, dated. Code history is in `git log`; this records what we learned.

## 2026-10-28 (overnight: argument layer)
- Built: `EvidenceKind.hypothesis` (weight 0), `Claim.noEffect` (a measured null), `opinionAt year`
  on Statement and Derivation (one recursion, `opinionWith`, behind both), and `Rivalry`: belief in
  one rival is fused as disbelief into the others. `Statement.forall_opinionAt` proves a property
  for every year by checking only the evidence years.
- M2 exit test met (`BioLean/Examples/Chemiosmosis.lean`): in 1965 both rivals are contested
  (b = d = 1/3); by 1974 chemiosmotic is established (b = 0.806) and the chemical intermediate refuted
  (d = 0.818). Read as one claim with refutations, chemiosmotic is never established in any year
  (top b = 0.714), as the Python sketch found.
- Finding, proved (`Rivalry.belief_le`): a rivalry decides losers, not winners. It never raises a
  rival above its own evidence. Chemiosmosis wins because the chemical-intermediate reports become
  support for a rival that the experiments then refute, not refutations of chemiosmosis.
- With the items as the script had them, the theorems are false: 1965 chemiosmotic b = 0 (hypothesis
  weighs 0, nothing else before 1966), 1974 b = 0.727. Changed illustrative items only: the 1963
  review is now `.hypothesis` (it restates, no data); one 1965 pro-chemiosmotic item added (stands for
  Mitchell & Moyle 1965, PMID unchecked). The six real papers alone give the 1974 result
  (b = 0.800 exactly, d = 0.889) but not 1965.
- Limit: each experiment is entered on both rivals (as `docs/formalisms/biolean.md` did), so the
  rivalry partly counts it twice. Without those direct refutations both 1974 numbers are 0.714.
  Multinomial opinions would fix this.

## 2026-10-28 (M2 built)
- Context implemented as entity refinement: `Entity.refine e r f` (the class e ⊓ ∃r.f, RO domain
  checked, bracketed composite curie), `Ctx` and `Entity.inCtx` applying fields in a fixed order so
  one context gives one identifier. Organism state refines the taxon filler; environment refines the
  subject. Rules `refineMono`, `isaInheritEffect`, `transport` (sibling taxa only, needs a
  `crossSpecies` evidence item at 3/10, listed in axioms). Evidence gains dose, duration, strain,
  system, taxon; `Statement.taxonConsistent` lint. Pinned taxon table `BioLean/Taxa.lean`.
- S1 to S5 pass as theorems and `#check_failure`s; 38 of the 40 bake-off claims port (the two left
  are preconditions, now rejected by the domain check). NMN in aged humans from aged mice: belief
  0.21, unsupported, with the transport item as an axiom. (`BioLean/Examples/Context.lean`)
- Known limits: one organism state per `Ctx`; the refinement axiom is 999/1000 not 1 (`lt_one`);
  the lint reads curie strings so it is `#guard`, not kernel `decide`; lineage steps through
  ordinary ontology axioms are still capped at 0.9.

## 2026-10-28 (M2 bake-off)
- Three context designs built in isolated worktrees against the same 40 textbook claims plus NMN
  and chemiosmosis, then judged on soundness first (`docs/m2/`). Wrapper-on-the-claim and
  refinement-on-the-entity both enforce "mouse and human evidence cannot fuse" at the type level;
  evidence-level context passes only by discipline and already failed on real data ("in some
  organisms" became universal). Verdict: refinement, hardened.
- The hybrid hypothesis held with one correction: textbook "conditions" are claim-level 23 of 37
  times, misfiled quantifiers 7, preconditions 7, experiment protocol 0. Conditions are refinable
  entities; Evidence carries only protocol (dose, duration, strain, system). Organism state
  (disease, genotype, age) refines the taxon filler. ~93 percent of the 190 context claims covered.
- All three builders found transport costs exactly 0.7 × 0.3 = 0.21 with a proved ceiling. The
  refinement builder found and fixed a composite-identifier collision ("(NMN in human) aged" vs
  "NMN in (aged human)").

## 2026-10-28 (M3: quantity)
- Claims: `count`, `atLeast`, `cardinality`, `measure` (interval with unit), `less`, `produces`,
  `consumes`, `yield`, and a `quant` wrapper for `some` / `most`. Rules with arithmetic side goals
  discharged at construction: `sequencesOver` (4^3 = 64 codons), `pigeonhole` (61 sense codons onto
  20 amino acids gives SOME amino acid two codons), `perSet` (46 / 2 = 23), `fusionAdds` (haploid +
  haploid = diploid; diploid egg + haploid sperm = triploid), `netYield` (4 − 2 = 2 ATP),
  `compareIntervals` (5 µm < 10 µm), `weaken`. Seven textbook counting sentences are theorems
  (`BioLean/Examples/Quantity.lean`); `cardinality codon 65` fails to build.
- The closure's only clash dissolves: "most neurons have axons" and "some neurons have none" are
  different claims under `quant`; no rule connects them. A universal would still clash.
- Decision (Dan): triviality of conclusions and the caveated-chain discount should come from the
  information content of the ontology term, not a hub list or a flat factor. Not implemented.

## 2026-10-28 (closure search)
- First forward-chaining closure over the compiled textbook: 1,248 statements give 1,551 derived
  facts at depth 4; 60 sampled derivations emitted as Lean and **all 60 certified** by the kernel.
  (`docs/closure-search.md`, `BioLean/Examples/Closure.lean`)
- Found two unsound rules of ours: `relInv` (inverting a class-level existential) and the is_a laws
  applied to is_a itself. Both removed/tightened; tests pin them. The first run had produced "DNA is_a
  messenger RNA" and "salivary glands overlap ganglia".
- Finding: sign chains through a feedback inhibitor (ATP inhibits sugar catabolism) are formally
  correct and biologically misleading; 56 of 73 effect conclusions pass through it. Needs a loop
  construct or a report flag.
- The only clash is a quantifier ("most neurons have axons" vs "some have none"): M3 confirmed next.
- Missing Lean rule found: is_a inherits an effect (56 uses in the closure).
- Cancer-to-energy-metabolism path query: connected only through "cells"; nothing provable here.

## 2026-10-27 (RO issues posted)
- Four issues opened on oborel/obo-relations from Dan's account: #897 (immediately preceded by /
  precedes chains), #898 (spatially coextensive chain), #899 (indirectly negatively regulates sign
  chains and transitivity), #900 (provides input for missing inverse). `docs/ro-issues.md`

## 2026-10-27 (RO fixes tested)
- Fixing the seven RO chain axioms in a copy changes nothing under ELK or JFact: RO defines no class
  with these properties, so the chains only fire on data. On test instances the wrong conclusions
  vanish and the missing `provides_input_for` appears. UBERON carries 67 false "spatially coextensive"
  entailments from row 79 under a full DL reasoner, and copies three of the bad chains itself.
- The regulation fix needs care: RO_0002409 is also transitive (neg ∘ neg = neg again); the working
  fix moves the three chains to RO_0002407 and drops transitivity, mirroring RO issue #182 (2017).
  No open RO issue covers any of the seven; #818/#821 (2025) introduced the has_output ∘ has_input
  chain and lost the inverse. Drafts in `docs/ro-issues.md`; regression in `docs/ro-fix-regression.md`.
- Test correction: starts_with is RO_0002224 and ends_with RO_0002230; the pinning test now checks
  the real blocked chain.

- All 4,695 textbook claims re-annotated by Sonnet into structured subject/relation/object fields
  with a fixed blocker list; 1,906 judged expressible, 1,594 emitted, **1,591 compile (99.8%)**.
  Round 1's 132 rejections were mostly my parser guessing entity order from Haiku's Lean strings.
- Schema: `Target.activity` now accepts a protein or a GO molecular function (20 of the 22
  remaining rejections); `viaActivity` generalised. Remaining real rejections: no disease target;
  GO functions used as located things (Lean is right).
- Measured expressibility after M1 is 34 percent emitted and compiled, 41 percent with the
  context and unsupported-ontology claims. (`docs/textbook-lean-check.md`)

## 2026-10-27 (OLS tagger)
- OLS text tagger (`POST /ols4/api/v2/tag_text`) tested with ASCII-normalised input: 1,102 hits vs
  OAK's 1,485; 85 percent agreement with agents where it hits; 96 percent agreement with OAK where
  both hit. Labels only, no synonyms, no plurals. Bug confirmed and written up: offsets are UTF-8 byte
  offsets, not character offsets, so each curly quote shifts later matches by two. Keep OAK first.
  (`docs/ols-tagger-trial.md`)

## 2026-10-27 (OAK trial)
- Ontology Access Kit (oaklib) as local grounder, same 2,803 pairs as Gilda: 1,485 hits, agrees with
  the agents on 80 percent where both answer (Gilda 45). Cross-namespace disagreements fall from 691
  to 147. Still misses the ~1,100 paraphrases and plurals. Decision: OAK as the cheap first pass and
  slip-catcher, agents for the rest. (`docs/oak-trial.md`)

## 2026-10-27 (Lean-checking the book)
- Every "now" textbook claim emitted as a Lean `Statement` and compiled: 811 binned, 702 emitted,
  **570 compile**. Lean rejected 132: 115 target-shape errors, 19 RO domain/range violations
  (14 are `capable_of` with a chemical object where `produces` was meant). `docs/textbook-lean-check.md`
- Schema gap found by the compiler: `Target.activity` should also accept a GO molecular function
  ("enzymes" grounds to GO:0003824). 67 claims blocked only by missing `Kind`s (SO, NCIT, EFO, OBA).
- `BioLean/Tests/RO.lean` pins the RO chains, inverses, blocked chains and domain sorts we rely on.
- Glossary: premise, conclusion, rule, instance.

## 2026-10-27 (M1 checks)
- Chain-length experiment over GO and UBERON: longest part_of chains are depth 10 and 12 and
  biologically correct; product belief falls to 0.35 and 0.28. Decision: RO-chain steps are logical
  and use `Opinion.weakest` (min belief, zero disbelief). Textbook derivations now score 0.80.
- 164 RO chains hand-checked by 8 Haiku agents and reviewed by Opus: 44 / 76 / 25 / 19 sound /
  caveat / suspicious / wrong. Seven chains are faithful imports of RO axioms that look wrong
  (rows 14, 16, 79, 87, 88, 89, 90 in `docs/ro-chains.md`); verified against ro.owl. 38 chains
  blocked by default via `scripts/ro/blocked_chains.tsv`; the importer asserts they still match.
- Measured re-annotation against the M1 schema (8 Haiku agents, 3,730 records): now 17.3 percent,
  with context 30 percent. The construct-name heuristic (62.6) over-counted 3.6x. Top remaining
  blockers: compound sentences, ungrounded entities, quantities. Relations used most: has_part 117,
  is_a 67, produces 32, located_in 28, has_input 25.
- Gilda trial on 2,803 (text, CURIE) pairs: 1,510 hits, 648 agree, 802 disagree of which 691 are
  namespace-only. Verdict: use as a GO/ChEBI checker. (`docs/gilda-trial.md`)
- Glossary written (`docs/glossary.md`). RO release pinned in the generated file (2026-09-04).

## 2026-10-27 (M1)
- Built relational claims: `Claim.rel` / `Claim.notRel` over RO relations, with RO's rdfs:domain
  and range checked by `decide`. RO imported from ro.owl as Lean data (642 relations, 164 chains,
  124 inverses, 45 transitive). Rules: `relChain` (chains, transitivity, is_a inheritance both
  ways), `relInv`, `notRelSub`, `notRelObj`, and `clash` for a positive vs a negated derivation.
- "The gonads produce steroid hormones" is a theorem: `inverse(occurs_in) ∘ has_output ⊑ produces`
  (RO:0003000) applied to "steroidogenesis occurs in gonad" and GO's has_output. Glycolysis in the
  cell, ascending colon in the large intestine, hepatocytes have nuclei, heterocysts lack nuclei
  all check; a text-mined "heterocyst has a nucleus" clashes with the inherited negation and
  loses (d = 0.64).
- Correction: RO has 164 property-chain axioms, not 336 (the earlier count doubled open/close tags).
- Finding: a two-step chain of a textbook sentence (0.8) and an ontology axiom (0.9) scores 0.72,
  below θ. Logical steps dilute like evidential ones. Open decision for M6.
- Re-bin estimate: expressible-now rises from 8.8 to 62.6 percent of textbook claims once RO
  relations are claims (by construct name, not re-annotation).
- Added evidence kinds `textbook` (0.8) and `ontologyAxiom` (0.9); PMID 0 marks non-paper evidence
  and is not deduplicated. Added kinds `component` (GO CC) and `taxon`.

## 2026-10-27
- Textbook milestone run: 4,695 claims from 7 OpenStax chapters. Entities ground at 93 percent;
  8.8 percent of claims fit the signed-effect schema, 21 percent with Context, 79 percent need
  structural constructors. 52 sentences derivable; 4 type-check today. 15 percent of structural
  claims are already ontology axioms. (`docs/textbook-milestone.md`)
- Decision: next core change is relational claims over RO, not more effect machinery.
- Finding: RO ships 336 property-chain axioms and 45 transitive properties; they are the
  structural derivation rules. Its CLIF annotations are sparse and unchecked.
- Notes written on subjective logic as pseudo-counts, canon bubbling up via `generalize`, ILP as the
  inverse of a Derivation, formal systems for conditioning. (`docs/notes-2026-10-27.md`)
- Case studies collected with decisions/gaps/limits per example. (`docs/case-studies.md`)
- Finding: linear clade-fraction coverage leaves transcription "unsupported" as a universal;
  bracketing preferred.

## 2026-10-26
- Chemiosmotic replay: cumulative fusion never reaches *established* because old refutations keep
  voting; supersession or rivals needed.
- Formalism survey: 11 papers in GO-CAM, INDRA, Biolink, BEL, nanopub, BioLean. Only nanopub+SEPIO
  holds argument structure; no formalism has dose, duration, age or strain; four of six merge mouse
  and human evidence silently. (`docs/formalisms/`)
- Context extension drafted (Context.lean, inContext, noEffect, gradient, hypothesis kind); builds
  in a scratch copy. (`docs/formalisms/biolean.md` §5)
- Explainer written for NotebookLM. (`docs/explainer.md`)

## 2026-10-23
- Project started. Related-work sweep (25 projects), framework choice (Lean 4 + subjective logic),
  core built, Ozempic demo: semaglutide reduces feeding established at b = 0.968; sitagliptin and
  nausea-mediation contested. (`docs/related-work.md`, `docs/design.md`)
- Decision: `decide +kernel` on ℚ for strength theorems; statements rendered from curated JSON,
  never hand-edited.
- Pipeline run on 22 abstracts: 5 refused by the safety classifier, 2 JSON failures, 18 Lean
  statements emitted.
