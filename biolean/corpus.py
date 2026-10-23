"""Read-only DuckDB access to the local records corpus (PubMed, Ontology, UniProt)."""

import json

import duckdb
from pydantic import BaseModel

RECORDS = "/home/danbolser/Work/IUK-IPF/data/embeddings-catalogue/records/*.parquet"
HEADER_PREFIXES = ("PubMed article:", "Authors:", "Journal:", "Publication year:")


class Abstract(BaseModel):
    pmid: int
    year: int | None
    journal: str | None
    title: str
    abstract: str


def strip_header(text: str) -> str:
    """Drop the leading 'PubMed article: / Authors: / Journal: / Publication year:' lines."""
    lines = text.splitlines()
    while lines and lines[0].startswith(HEADER_PREFIXES):
        lines.pop(0)
    return "\n".join(lines).strip().removeprefix("Abstract:").strip()


def to_abstract(title: str, text: str, metadata: str) -> Abstract:
    meta = json.loads(metadata)
    year = meta.get("publication_year")
    return Abstract(
        pmid=int(meta["pmid"]),
        year=int(year) if year else None,
        journal=meta.get("journal"),
        title=title,
        abstract=strip_header(text),
    )


def query(sql: str, params: list | None = None, records: str = RECORDS) -> list[tuple]:
    """Run one SQL query with `records` bound as a read-only parquet view."""
    con = duckdb.connect()
    con.execute("set enable_progress_bar = false")
    con.execute(f"create view records as select * from read_parquet('{records}')")
    return con.execute(sql, params or []).fetchall()


def fetch_abstracts(pmids: list[int], records: str = RECORDS) -> list[Abstract]:
    ids = [f"PMID:{p}" for p in pmids]
    rows = query(
        "select title, text, metadata from records"
        " where record_class = 'PubMed' and record_id = any(?)",
        [ids],
        records,
    )
    order = {p: i for i, p in enumerate(pmids)}
    return sorted((to_abstract(*r) for r in rows), key=lambda a: order[a.pmid])


def search_abstracts(pattern: str, limit: int = 20, records: str = RECORDS) -> list[Abstract]:
    """Case-insensitive ILIKE search over PubMed text, e.g. '%semaglutide%appetite%'."""
    rows = query(
        "select title, text, metadata from records"
        " where record_class = 'PubMed' and text ilike ? limit ?",
        [pattern, limit],
        records,
    )
    return [to_abstract(*r) for r in rows]
