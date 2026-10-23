# biolean (Python side)

PubMed abstracts -> typed, quoted statements -> ontology CURIEs -> Lean 4 `Statement`s.
Four stages, one module each, JSON file in / file out.

| Stage | Module | In -> out |
|---|---|---|
| fetch | `corpus.py` | PMIDs or ILIKE pattern -> `abstracts.json` (`list[Abstract]`) |
| extract | `extract.py` | `abstracts.json` -> `extractions.json` (`list[ExtractionResult]`), Claude `claude-opus-5-5`, structured outputs |
| ground | `ground.py` | `extractions.json` -> `grounded.json` (`list[GroundedStatement]`), local lookup only |
| emit | `emit_lean.py` | `grounded.json` -> one `.lean` file in `namespace BioLean.Lib.Generated` |

## Run

```sh
uv sync
uv run biolean fetch 28266779 33184979 34260945 -o abstracts.json   # or: --search '%semaglutide%appetite%'
uv run biolean extract abstracts.json --dry-run                      # prompts + JSON schema, no API call
uv run biolean extract abstracts.json -o extractions.json            # needs ANTHROPIC_API_KEY
uv run biolean ground extractions.json --abstracts abstracts.json -o grounded.json
uv run biolean emit grounded.json -o Generated.lean [--keep-hedged]
uv run pytest
```

The first `ground` builds `data/lookup/labels.parquet` (gitignored; ~574k rows, ~10 s). `--rebuild` forces it.
Corpus: `/home/danbolser/Work/IUK-IPF/data/embeddings-catalogue/records/*.parquet`, read only, one scan per call.

## Schema

- `Abstract {pmid, year, journal, title, abstract}`: abstract is the body, with the `PubMed article/Authors/Journal/Publication year` header and `Abstract:` label stripped.
- `ExtractionResult {pmid, statements: list[Extracted]}`
- `Extracted {quote, subject: Mention, relation, object: Mention, polarity, evidence_kind, species, hedged}`
- `Mention {mention, kind}`. Kind is one of chemical, protein, gene, process, phenotype, disease, anatomy, cell_type.
- `Relation` is `{increases,decreases}_{activity,amount,process,phenotype}`.
- `Grounding {curie, label, kind, method: exact_label|exact_synonym, ambiguous}`
- `GroundedStatement {pmid, year, quote, subject, relation, object, polarity, evidence_kind, hedged}`

## Grounding rules

Exact, case-insensitive match on `(label, kind)`. No fuzzy matching. Labels beat synonyms. Several CURIEs left means `ambiguous`, and the `ground` stage drops it.

- Ontology terms: kind comes from the CURIE prefix. CHEBI is chemical, GO is process, HP and PATO are phenotype, MONDO is disease, UBERON is anatomy, CL is cell_type. The prefix is used because the `ontology_*` files import foreign terms (e.g. `ontology_cl` holds GO and UBERON rows).
- GO is limited to `biological_process`, using the namespace in the `go_term` rows. Molecular-function and cellular-component terms are left out.
- Synonyms: every `ontology_*` synonym in the corpus is the broken string `\1`. Real synonyms come from the `go_term` and `mondo_disease` rows instead. CHEBI, HP, PATO, UBERON and CL have **labels only**.
- UniProt (`uniprot_human`, record_id = accession):
  - label = first gene symbol (`GLP1R`)
  - synonyms = the other gene names, plus the protein names parsed from the title (`Glucagon-like peptide 1 receptor (GLP-1 receptor) (GLP-1R)`), without EC numbers
  - all of these map to `UniProt:<acc>`, kind protein
- `gene` mentions match nothing, because there is no gene table.

## Emit rules

- Group by `(subject, relation, object)`, with one `Evidence` per PMID (the first statement from each PMID wins).
- Hedged statements are dropped unless `--keep-hedged`.
- Object kind must fit the Lean `Target`: activity takes protein; amount takes chemical or protein; process takes process; phenotype takes phenotype. Anything else is skipped and logged, including MONDO diseases as phenotype objects.
- `other` evidence becomes `.observational`.
- Notes are whitespace-collapsed, capped at 300 chars, and escaped.

## What is tested (`tests/`, no API calls, no corpus access)

- `test_emit_lean.py`: the full expected Lean text for a fixture, including:
  - grouping two PMIDs, de-duplicating within one PMID
  - escaping, hedged drop, disease-object skip, kind-mismatch skip
- `test_ground.py`: a tiny in-memory lookup. Covers case-insensitive matching, kind restriction, no fuzzy match, label-over-synonym, ambiguity, and UniProt title parsing.
- `test_corpus.py`: header stripping and metadata parsing.

Not tested:
- `build_lookup` and the DuckDB queries. They were run by hand against the real corpus.
- The `extract` API call. **`extract` has never been run against the API here: there was no key.** Only `--dry-run` has been run.

## Fixtures (`data/fixtures/`)

- `abstracts_sample.json`: real `fetch` output for PMIDs 28266779, 33184979, 34260945.
- `extraction_sample.json`: a **hand-written** stand-in for model output, filled from the real text. Each result carries a `_fixture` note saying so. All quotes are verbatim.
- `grounded_sample.json`, `GeneratedSample.lean`: real `ground` and `emit` output on that fixture.
