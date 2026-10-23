# Demo evidence: semaglutide / GLP-1 / DPP-4 / appetite

Built from the local corpus by the scripts in `scripts/demo/`, in order.

| file | made by | what |
|---|---|---|
| `glp1_corpus.parquet` | `01_build_corpus.py` | PubMed records matching GLP-1, DPP-4, semaglutide, appetite terms (one full scan) |
| `grounding.json`, `ontology_uniprot.parquet` | `02_grounding.py` | CHEBI, GO, HP, MONDO, UniProt rows for the entities used |
| `pubtator3_relations.tsv` | `03_pubtator3.sh` | PubTator3 relation rows touching GLP1R (2740), DPP4 (1803), GCG (2641) and the drugs' MeSH ids |
| `goa.json` | `02_grounding.py` | human GOA annotations for P43220, P27487, P01275 with ECO codes and PMIDs |
| `evidence_candidates.tsv`, `evidence.json` | `04_evidence.py` | automatic candidates, about 15 per statement, many off-topic |
| `curated.json` | LLM curation pass, every quote verified as a substring of the abstract | 66 items over 12 statements S1..S9d |
| `../../BioLean/Lib/GLP1Statements.lean` | `05_render_lean.py` | the curated items as Lean `Statement`s |

Notes: PubTator3 has almost no normalised semaglutide concept (one row in the whole
file), so drug-level relations come from the abstracts, not PubTator3. S8 (DPP-4
inhibitors are weight-neutral) is encoded with flipped polarity as refuting evidence
for "sitagliptin reduces feeding". `glp1_corpus.parquet` is gitignored.
