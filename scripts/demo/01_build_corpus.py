"""One full scan of the PubMed/ontology parquet.

Writes
  data/demo/glp1_corpus.parquet        PubMed rows matching GLP-1 / DPP-4 / drug terms
  data/demo/ontology_uniprot.parquet   every non-PubMed row (Ontology + UniProt), for grounding

Run:  uv run --with duckdb python scripts/demo/01_build_corpus.py
"""
import time, duckdb

SRC = "/home/danbolser/Work/IUK-IPF/data/embeddings-catalogue/records/*.parquet"
OUT = "/home/danbolser/Build/BioLean/data/demo"

# Drug / target terms. Appetite terms (appetite, satiety, food intake, gastric
# emptying) are only wanted together with GLP-1 terms, so they add nothing here.
TERMS = r"(?i)semaglutide|ozempic|wegovy|liraglutide|exenatide|tirzepatide|glp-?1\b|glp-?1r|glucagon-like peptide|dpp-?4\b|dpp-?iv\b|dipeptidyl[ -]peptidase|sitagliptin"

con = duckdb.connect()
con.execute("SET threads TO 100")
t0 = time.time()
con.execute(f"""
CREATE TABLE sub AS
SELECT *,
       CASE WHEN record_class = 'PubMed'
            THEN try_cast(json_extract_string(metadata, '$.pmid') AS BIGINT) END AS pmid,
       CASE WHEN record_class = 'PubMed'
            THEN try_cast(json_extract_string(metadata, '$.publication_year') AS INTEGER) END AS publication_year,
       CASE WHEN record_class = 'PubMed'
            THEN json_extract_string(metadata, '$.journal') END AS journal
FROM read_parquet('{SRC}')
WHERE record_class <> 'PubMed'
   OR regexp_matches(title, '{TERMS}')
   OR regexp_matches(text,  '{TERMS}')
""")
print(f"scan done in {time.time()-t0:.0f}s")

con.execute(f"COPY (SELECT * FROM sub WHERE record_class = 'PubMed') TO '{OUT}/glp1_corpus.parquet' (FORMAT PARQUET)")
con.execute(f"COPY (SELECT * EXCLUDE (pmid, publication_year, journal) FROM sub WHERE record_class <> 'PubMed') TO '{OUT}/ontology_uniprot.parquet' (FORMAT PARQUET)")

for row in con.execute("SELECT record_class, count(*) FROM sub GROUP BY 1 ORDER BY 1").fetchall():
    print(*row)
print(f"total {time.time()-t0:.0f}s")
