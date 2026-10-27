# OAK trial: local lexical grounder vs agent CURIEs

oaklib 0.7.4 (`uv add oaklib`), semsql sqlite builds downloaded into
`~/.data/oaklib`, run over every entity mention in `data/textbook/claims/*.json`,
mirroring the Gilda trial (`docs/gilda-trial.md`). Script:
`scripts/textbook/oak_compare.py`; table: `data/textbook/oak_compare.tsv`.

## Method

- Ontologies: GO, UBERON, CL, PATO, HP, MONDO, CHEBI. ChEBI was in range
  (802 MB download, ~100 s; 4.1 GB on disk). **NCBITaxon skipped**: 2.4 GB
  download.
- `adapter.annotate_text(text)` per ontology on the bare mention text. Keep a
  hit only if its span covers >= 90% of the text.
- Pick: longest span, then predicate (label > exact > related > broad/narrow),
  then a term native to the queried ontology, then ontology order. 62 rows
  had more than one CURIE tied at the top rank.
- Same status classes as Gilda. Runtime ~15 min, dominated by building
  ChEBI's in-memory lexical index; OAK's annotator loops over the whole index
  per call.

## Numbers (OAK vs Gilda)

| | OAK | Gilda |
|---|---|---|
| entity mentions | 12 100 | 12 100 |
| distinct (text, agent CURIE) pairs | 2 803 | 2 803 |
| hit | 1 485 | 1 510 |
| agree | **1 158** | 648 |
| disagree | **290** | 802 |
| oak_only / gilda_only | 37 | 60 |
| agent_only | 1 108 | 1 106 |
| neither | 210 | 187 |

Agreement rate when both answer: OAK 80%, Gilda 45%.

By agent prefix (agree / disagree / agent_only):

| agent prefix | rows | agree | disagree | agent_only |
|---|---|---|---|---|
| GO | 1 026 | 443 | 91 | 492 |
| UBERON | 492 | 301 | 60 | 131 |
| CHEBI | 375 | 184 | 38 | 153 |
| CL | 126 | 54 | 11 | 61 |
| NCBITaxon | 125 | 49 | 13 | 63 |
| PATO | 90 | 45 | 8 | 37 |
| NCIT | 73 | 0 | 20 | 53 |
| MONDO | 63 | 33 | 19 | 11 |
| SO | 58 | 11 | 5 | 42 |
| HP | 45 | 27 | 6 | 12 |
| PR | 39 | 2 | 16 | 21 |

(NCBITaxon, SO and others still get hits through terms the loaded
ontologies import.)

What the numbers say:

1. **Namespace fixed.** The OBO namespaces were Gilda's main problem. With
   them loaded, cross-namespace disagreements drop from 691 to 147. Most
   of the rest are MONDO vs HP for diseases (17), PR vs CHEBI for proteins
   and hormones (15), and GO vs CHEBI (14).
2. **Lexical misses not fixed.** agent_only is unchanged (1 108 vs 1 106).
   897 of those are in ontologies OAK has loaded. 258 are 3+ word
   paraphrases. OAK's annotator does no stemming, so plurals fail
   (`kidneys` covers 86% of `kidney`, below the cut-off) or land on the
   wrong synonym (`lungs` -> pair of lungs).
3. **Synonym noise.** 1 092 of 1 485 picks are label matches. The 182
   related/broad/narrow picks cause most outright errors. Imported foreign
   terms (MBA, DHBA, HGNC, FOODON) and 10 undefined ChEBI 7xxxxx entries
   (`amino acids`, `platelets`, `blood cells, red`: product-like entries
   with only role links) also leak in.
4. **143 same-namespace disagreements** (49 GO, 43 UBERON, 30 CHEBI). The
   pattern is the same as with Gilda: OAK takes the literal term, and the
   agent picks a context-specific child.

## 15 disagreement examples (agent | OAK)

| text | agent | OAK (predicate) |
|---|---|---|
| meiosis | GO:0051321 meiotic cell cycle | GO:0140013 meiotic nuclear division (exact) |
| lungs | UBERON:0002048 lung | UBERON:0000170 pair of lungs (exact) |
| humans | NCBITaxon:9606 Homo sapiens | NCBITaxon:9605 Homo (exact) |
| rheumatoid arthritis | MONDO:0008383 rheumatoid arthritis | HP:0001370 Rheumatoid arthritis (label) |
| epinephrine | CHEBI:33568 adrenaline | CHEBI:28918 (R)-adrenaline (related) |
| skeletal muscle | UBERON:0014892 skeletal muscle organ, vertebrate | UBERON:0014895 somatic muscle, invertebrate (related) |
| hippocampus | UBERON:0002421 hippocampal formation | UBERON:0001954 Ammon's horn (related) |
| central vacuole | GO:0000325 plant-type vacuole | GO:0042807 central vacuole (label) |
| sodium | CHEBI:29101 sodium(1+) | CHEBI:26708 sodium atom (exact) |
| p53 | PR:000003035 cellular tumor antigen p53 | CHEBI:135598 tetrofosmin (related) |
| G1 | GO:0051318 G1 phase | MONDO:0024491 tumor grade 1 (exact) |
| red blood cells | CL:0000232 erythrocyte | CHEBI:753202 blood cells, red (related) |
| This | GO:1902600 proton transmembrane transport (coreference) | NCBITaxon:169495 *This* (a genus; label) |
| cilia | GO:0005929 cilium | UBERON:0010168 collection of eyelashes (exact) |
| closed circulatory system | UBERON:0001009 circulatory system | UBERON:0009055 closed circulatory system (label) |

## Who is right? (random 30 disagreements, seed 1)

My judgement:

- **13 agent right.** Ion vs atom (`sodium`). Species vs genus (`humans`).
  Context sense (`medulla` -> renal medulla, where OAK gave MBA mouse-brain
  medulla; `lumen`, `matrix`, `egg`). Plural traps (`lungs` -> pair of
  lungs; `skin` -> zone of skin). Pronouns (`This`, `We` -> Trp-Glu). Junk
  ChEBI entries (`amino acids`, `platelets`).
- **6 OAK right.** In each, the agent dropped to a broader or wrong term
  when an exact term exists: `closed`/`open circulatory system`,
  `central vacuole`, `digestive system organ`, `eukaryotic cell` (the agent
  gave the NCBITaxon Eukaryota taxon), `DNA` (the agent gave plastid
  chromosome).
- **10 both acceptable.** These differ only by namespace (MONDO/HP,
  PR/CHEBI/HGNC) or are literal parent vs context child (`prophase`,
  `growth`, `fermentation`, `cortex`).
- **1 neither.** For `mRNA polyadenylation` the agent gave an obsolete GO
  term, and OAK gave a broader pathway via a related synonym.

## Recommendation

OAK is clearly better than Gilda as BioLean's local grounder. It covers the
OBO namespaces, agrees with the agent on 80% of the rows where both answer
(Gilda: 45%), and runs offline from one sqlite file per ontology. It is
still no replacement for the agent: it misses the same ~1 100 paraphrases
and plurals and has no context sense, so use it as Gilda was proposed: a
cheap check that auto-accepts label/exact-synonym agreements, catches agent
slips (wrong level, obsolete terms), and sends everything else to the agent.

## Caveats

- `uv add oaklib` modified `pyproject.toml` and `uv.lock` (required by step 1).
- Bare mention text, no sentence context. No stop-word list (OAK's
  `token_exclusion_list` was not set), no stemming or synonymizer rules.
- Restricting picks to label + exact synonym, and to native prefixes,
  would remove most noise hits. Not tried here.
- Agent labels for NCBITaxon/PR/NCIT are blank in the TSV: no adapter
  loaded and no exact_label row in `data/lookup/labels.parquet`.
