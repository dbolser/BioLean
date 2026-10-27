# CHANGELOG

Findings and decisions, dated. Code history is in `git log`; this records what we learned.

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
