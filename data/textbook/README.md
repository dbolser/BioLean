# Textbook claims

`claims/*.json`: atomic claims extracted from seven chapters of OpenStax *Concepts of Biology*,
each with the source sentence, kind, bin against the BioLean schema, grounded entities and a Lean
sketch. Produced by the workflow described in `docs/textbook-milestone.md`; aggregated by
`scripts/textbook/aggregate.py`; source text extracted by `scripts/textbook/extract_openstax.py`
(the extracted prose itself is not committed).

Source sentences are quoted from OpenStax, *Concepts of Biology*, Rice University, licensed
CC BY-NC-SA 4.0 (https://github.com/openstax/osbooks-biology-bundle). Access for free at
https://openstax.org/details/books/concepts-biology. This derived data is shared under the same
licence for non-commercial research use.
