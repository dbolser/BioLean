# BioLean

Formal, evidence-weighted biology in Lean 4.

A paper's claim becomes a typed `Statement` grounded in ontology terms (ChEBI, UniProt,
GO, HP, UBERON) with its PMIDs attached. A `Derivation` chains statements into a
higher-level claim. Lean checks the shape of the argument; a subjective-logic opinion
(belief, disbelief, uncertainty) gives its strength. Named derivations form **biolib**,
reused by new proofs like Mathlib lemmas.

First question answered: *Does semaglutide (Ozempic) reduce hunger?*
See `BioLean/Examples/Ozempic.lean`.

## Layout

| path | what |
|---|---|
| `BioLean/` | the Lean core: `Belief`, `Ontology`, `Claim`, `Evidence`, `Derivation` |
| `BioLean/Lib/` | biolib: grounded entities, statements rendered from curated data, named derivations |
| `BioLean/Examples/` | questions as theorems |
| `biolean/` | Python pipeline: corpus → Claude extraction → CURIE grounding → Lean source |
| `data/demo/` | mined and curated evidence for the GLP-1 demo (66 verified quotes) |
| `scripts/demo/` | how `data/demo/` was built, one step per file |
| `docs/related-work.md` | what exists, what is new, what to reuse |
| `docs/design.md` | framework choice, demo walk-through, known gaps, scope |
| `docs/case-studies.md`, `docs/formalisms/`, `docs/textbook-milestone.md` | worked examples, six-formalism survey, textbook measurement |
| `STATUS.md`, `ROADMAP.md`, `CHANGELOG.md` | where we are, where next, what we learned when |

## Running

```bash
# Lean (needs elan; Mathlib cache is large)
lake exe cache get
lake build
lake env lean BioLean/Examples/Ozempic.lean   # prints the reports

# Python
uv sync
uv run pytest
uv run biolean --help
```

The corpus (28.5M PubMed abstracts, ontologies, UniProt) is not in this repo. Paths are
in `biolean/corpus.py` and `scripts/demo/`.
