"""Stage 3: ground a Mention to a CURIE by exact, kind-restricted label lookup over local data."""

from collections import defaultdict
from pathlib import Path
from typing import Literal

import duckdb
from pydantic import BaseModel

from biolean.corpus import RECORDS
from biolean.extract import ExtractionResult, Kind, Mention, Relation

LOOKUP = Path(__file__).resolve().parents[1] / "data" / "lookup" / "labels.parquet"

Method = Literal["exact_label", "exact_synonym"]
Lookup = dict[tuple[str, str], list[tuple[str, str, Method]]]  # (label_lower, kind) -> [(curie, label, method)]

# ontology_* rows hold real titles but their synonyms are all the garbage string "\1";
# go_term / mondo_disease carry the real synonyms (and the GO namespace) for the same CURIEs.
RECORD_TYPES = (
    "ontology_chebi", "ontology_go", "ontology_hp", "ontology_mondo", "ontology_uberon",
    "ontology_cl", "ontology_pato", "go_term", "mondo_disease", "uniprot_human",
)

BUILD_SQL = """
create temp table r as
  select record_id, record_type, title, metadata from records where record_type in ?;

create temp table up_names as
  select unnest(?) curie, unnest(?) name;

create temp table go_bp as
  select record_id curie from r
  where record_type = 'go_term' and json_extract_string(metadata, '$.namespace') = 'biological_process';

create temp table terms as
  select record_id curie, title, metadata,
    case split_part(record_id, ':', 1)
      when 'CHEBI' then 'chemical' when 'GO' then 'process'
      when 'HP' then 'phenotype' when 'PATO' then 'phenotype'
      when 'MONDO' then 'disease' when 'UBERON' then 'anatomy' when 'CL' then 'cell_type'
    end kind
  from r where record_type <> 'uniprot_human';

create temp table names as
  with t as (
    -- kind comes from the CURIE prefix (ontology files import foreign terms) and GO is restricted to processes
    select * from terms where kind is not null and (kind <> 'process' or curie in (select curie from go_bp))
  ),
  lab as (select curie, kind, any_value(title) label from t group by all),
  syn as (
    select curie, unnest(cast(json_extract_string(metadata, '$.synonyms[*]') as varchar[])) name from t
  ),
  up as (
    select 'UniProt:' || record_id curie, 'protein' kind, title,
      string_split(trim(coalesce(json_extract_string(metadata, '$.gene_names'), '')), ' ') genes
    from r where record_type = 'uniprot_human'
  )
  select curie, kind, label, label name, 'exact_label' method from lab
  union all select curie, kind, label, name, 'exact_synonym' from syn join lab using (curie)
  union all select curie, kind, coalesce(nullif(genes[1], ''), title), coalesce(nullif(genes[1], ''), title), 'exact_label' from up
  union all select curie, kind, coalesce(nullif(genes[1], ''), title), unnest(genes[2:]), 'exact_synonym' from up
  union all select curie, kind, coalesce(nullif(genes[1], ''), title), name, 'exact_synonym' from up join up_names using (curie);

copy (
  select lower(trim(name)) label_lower, curie, kind, any_value(label) label, min(method) method
  from names
  where length(trim(name)) >= 3 and name not like '%\\%'
  group by all order by all
) to '{out}' (format parquet);
"""


class Grounding(BaseModel):
    curie: str
    label: str
    kind: Kind
    method: Method
    ambiguous: bool


class GroundedStatement(BaseModel):
    pmid: int
    year: int
    quote: str
    subject: Grounding
    relation: Relation
    object: Grounding
    polarity: Literal["supports", "refutes"]
    evidence_kind: str
    hedged: bool


def uniprot_names(title: str) -> list[str]:
    """'Name (Alt 1) (Alt 2) (EC 1.2.3.4) [Cleaved into: ...]' -> ['Name', 'Alt 1', 'Alt 2']."""
    s, names = title.split(" [")[0].strip(), []
    while s.endswith(")"):
        depth = 0
        for i in range(len(s) - 1, -1, -1):
            depth += {")": 1, "(": -1}.get(s[i], 0)
            if depth == 0:
                break
        if i == 0 or s[i - 1] != " ":
            break  # parenthesis is part of the name, e.g. 'lipoyl(octanoyl) transferase'
        names.append(s[i + 1 : -1])
        s = s[:i].rstrip()
    return [n for n in [s, *reversed(names)] if n and not n.startswith("EC ")]


def build_lookup(out: Path = LOOKUP, records: str = RECORDS) -> int:
    """One scan of the records parquet -> labels.parquet. Returns the row count."""
    out.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect()
    con.execute("set enable_progress_bar = false")
    con.execute(f"create view records as select * from read_parquet('{records}')")
    first, *rest = [s for s in BUILD_SQL.format(out=out).split(";") if s.strip()]
    con.execute(first, [list(RECORD_TYPES)])
    pairs = [
        (f"UniProt:{acc}", name)
        for acc, title in con.execute("select record_id, title from r where record_type = 'uniprot_human'").fetchall()
        for name in uniprot_names(title)
    ]
    con.execute(rest[0], [[c for c, _ in pairs], [n for _, n in pairs]])
    for stmt in rest[1:]:
        con.execute(stmt)
    return con.execute(f"select count(*) from '{out}'").fetchone()[0]


def load_lookup(path: Path = LOOKUP) -> Lookup:
    if not path.exists():
        build_lookup(path)
    table: Lookup = defaultdict(list)
    for label_lower, curie, kind, label, method in duckdb.sql(f"select * from '{path}'").fetchall():
        table[label_lower, kind].append((curie, label, method))
    return dict(table)


def ground(mention: Mention, lookup: Lookup) -> Grounding | None:
    """Exact case-insensitive match within the mention's kind. Labels beat synonyms; never guess."""
    hits = lookup.get((mention.mention.strip().lower(), mention.kind), [])
    best = [h for h in hits if h[2] == "exact_label"] or hits
    if not best:
        return None
    curie, label, method = min(best)
    return Grounding(curie=curie, label=label, kind=mention.kind, method=method,
                     ambiguous=len({h[0] for h in best}) > 1)


def ground_results(
    results: list[ExtractionResult], years: dict[int, int], lookup: Lookup
) -> tuple[list[GroundedStatement], list[str]]:
    """Ground both ends of every statement. Returns statements and a log of misses."""
    grounded, log = [], []
    for r in results:
        for s in r.statements:
            sub, obj = ground(s.subject, lookup), ground(s.object, lookup)
            misses = [f"{m.mention!r} ({m.kind})" for m, g in ((s.subject, sub), (s.object, obj)) if g is None]
            ambiguous = [g.label for g in (sub, obj) if g and g.ambiguous]
            if misses or ambiguous:
                log.append(f"PMID {r.pmid}: ungrounded {', '.join(misses)}" if misses
                           else f"PMID {r.pmid}: ambiguous {', '.join(ambiguous)}")
                continue
            grounded.append(GroundedStatement(
                pmid=r.pmid, year=years[r.pmid], quote=s.quote, subject=sub, relation=s.relation,
                object=obj, polarity=s.polarity, evidence_kind=s.evidence_kind, hedged=s.hedged,
            ))
    return grounded, log
