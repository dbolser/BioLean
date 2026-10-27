# Gilda trial: local grounder vs agent CURIEs

Gilda 1.6.1 (`uv add gilda`, ~60 MB resource download on first use) run over
every entity mention in `data/textbook/claims/*.json`. Script:
`scripts/textbook/gilda_compare.py`; table: `data/textbook/gilda_compare.tsv`.

## Numbers

| | count |
|---|---|
| entity mentions | 12 100 |
| distinct (text, agent CURIE) pairs | 2 803 (2 656 distinct texts) |
| Gilda returned a hit | 1 510 |
| agree (same CURIE) | 648 |
| disagree (both grounded, different) | 802 |
| gilda_only (agent null) | 60 |
| agent_only (Gilda no hit) | 1 106 |
| neither | 187 |

Two things explain most of the disagreement and the agent_only pile:

1. **Namespace coverage.** Gilda's lexicon is GO, CHEBI, MESH, HGNC, UniProt,
   FamPlex, EFO, HP, DOID. It has no UBERON, CL, NCBITaxon, PATO, SO, NCIT,
   MONDO, PR. The agent used those for ~40% of mentions. So 691 of the 802
   "disagreements" are Gilda returning MESH/HGNC/FPLX/EFO for a term the agent
   put in an OBO ontology (`kidney`: UBERON:0002113 vs MESH:D007668). Both are
   right; only one is in BioLean's target set.
2. **Lexical matching.** Gilda does not ground paraphrases (`acidic digestive
   juices`, `replicates itself`, `non-protein helper molecules`). 282 of the
   1 106 agent_only rows are 3+ word phrases; 591 are in namespaces Gilda does
   cover (GO/CHEBI/HP) but Gilda still had no string match.

The informative subset is the **80 same-namespace disagreements** (56 GO,
24 CHEBI). Pattern: Gilda returns the term whose label literally matches; the
agent returns a more specific child chosen from sentence context.

## 15 disagreement examples (agent | Gilda)

| text | agent | Gilda |
|---|---|---|
| prophase | GO:0000088 mitotic prophase | GO:0051324 prophase |
| electron transport chain | GO:0022904 respiratory electron transport chain | GO:0022900 electron transport chain |
| central vacuole | GO:0000325 plant-type vacuole | GO:0042807 central vacuole |
| tight junction | GO:0005923 bicellular tight junction | GO:0070160 tight junction |
| membranes | GO:0005886 plasma membrane | GO:0016020 membrane |
| ribosomes | GO:0005761 mitochondrial ribosome | GO:0005840 ribosome |
| import into cell | GO:0006833 water transport | GO:0098657 import into cell |
| growth | GO:0008283 cell population proliferation | GO:0040007 growth |
| flagellum | GO:0031514 motile cilium | GO:0005929 cilium |
| sodium | CHEBI:29101 sodium(1+) | CHEBI:26708 sodium atom |
| protons | CHEBI:15378 hydron | CHEBI:24636 proton |
| alcohol | CHEBI:30879 alcohol | CHEBI:16236 ethanol |
| A / G / C (DNA bases) | CHEBI:16708 adenine etc. | CHEBI:13193 hydrogen acceptor / glycine / cysteine |
| enzymes | GO:0003678 DNA helicase activity | MESH:D004798 Enzymes |
| fat | UBERON:0001013 adipose tissue | HGNC:1663 CD36 |

## Who is right? (random 30 disagreements, seed 1)

My judgement, with labels resolved from `data/lookup/labels.parquet`:

- 25: both acceptable, differ only by namespace (UBERON/CL/MONDO/NCBITaxon vs
  MESH). The agent's pick is the one BioLean wants.
- 2: agent clearly wrong (`nervous tissue` -> UBERON nervous system;
  `enzymes` -> GO DNA helicase activity). Gilda right.
- 2: Gilda clearly wrong (`fat` -> HGNC CD36; `Jacobsen syndrome` -> HGNC JBS,
  a gene symbol collision). Agent right.
- 1: Gilda's literal parent term is the safer grounding (`tight junction`).

On the 80 same-namespace rows the split is similar: Gilda is the better
*literal* grounder (~50 rows where the agent chose a context-specific child,
e.g. mitotic prophase for "prophase"), the agent is better on biology-context
sense (ions vs atoms, hydron vs proton, single-letter base codes, "alcohol" in
a fermentation passage is ethanol, where Gilda happened to agree), and each
side has a handful of outright errors (agent: `import into cell` -> water
transport, `growth` -> proliferation; Gilda: 6/6 single-letter codes wrong).

## Recommendation

Gilda alone cannot be the first-pass grounder for BioLean: it lacks the
anatomy, cell, taxon, sequence and phenotype-quality namespaces the agent
uses for ~40% of mentions, and it misses every paraphrase. For GO and CHEBI
it is a cheap, deterministic literal-label matcher that catches agent
hallucinations (`enzymes` -> helicase), so the useful arrangement is Gilda as
a *check*: run it on every mention, auto-accept where it agrees, and send
GO/CHEBI mismatches plus Gilda misses to the agent for arbitration with the
sentence context (which is exactly where the agent wins).

## Caveats

- `uv add gilda` modified `pyproject.toml` and `uv.lock` (required by step 1).
- Gilda was run on the bare mention text, no sentence context; Gilda's
  `context=` disambiguation was not tried.
- 115 texts carry more than one agent CURIE across claims; each (text, CURIE)
  pair is a row.
