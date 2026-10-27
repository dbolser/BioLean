# CHANGELOG

Findings and decisions, dated. Code history is in `git log`; this records what we learned.

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
