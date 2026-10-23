"""Ontology / UniProt grounding rows (task 3) and human GOA annotations (task 4).

Writes
  data/demo/grounding.json   CHEBI / GO / HP / MONDO / UniProt rows
  data/demo/goa.json         human GAF annotations for GLP1R, DPP4, GCG

Run:  uv run --with duckdb python scripts/demo/02_grounding.py
"""
import gzip, json, re, duckdb

ONT = "/home/danbolser/Build/BioLean/data/demo/ontology_uniprot.parquet"
GAF = "/home/danbolser/Work/IUK-IPF/data/sources/goa/raw/human.gaf.gz"
OUT = "/home/danbolser/Build/BioLean/data/demo"

# record_type -> ids.  Ontologies import each other, so pin the home record_type.
WANT = {
    "ontology_chebi": ["CHEBI:167574", "CHEBI:71193", "CHEBI:40237", "CHEBI:748790", "CHEBI:194186",
                       "CHEBI:80270", "CHEBI:749689", "CHEBI:50507", "CHEBI:71196", "CHEBI:68612", "CHEBI:64088"],
    "ontology_go":    ["GO:0032099", "GO:0032098", "GO:0060259", "GO:0007631", "GO:2000252", "GO:1903999",
                       "GO:0044508", "GO:0004967", "GO:0035483", "GO:0120060", "GO:0120061",
                       "GO:0008233", "GO:0008239", "GO:0070008", "GO:0005179"],
    "ontology_hp":    ["HP:0002018", "HP:0004396", "HP:0002591", "HP:0033842", "HP:0001513", "HP:0002017"],
    "ontology_mondo": ["MONDO:0011122", "MONDO:0005148"],
    "uniprot_human":  ["P43220", "P27487", "P01275", "P01189"],
}
GOA_PROTEINS = ["P43220", "P27487", "P01275"]

con = duckdb.connect()
con.execute("SET threads TO 64")
con.execute(f"CREATE VIEW o AS SELECT * FROM read_parquet('{ONT}')")

def field(text, name):
    m = re.search(rf"^{name}: (.*)$", text, re.M)
    return m.group(1).strip() if m else None

grounding = []
for rtype, ids in WANT.items():
    rows = con.execute(
        "SELECT record_id, record_type, title, text, metadata FROM o WHERE record_type = ? AND record_id IN (SELECT unnest(?))",
        [rtype, ids]).fetchall()
    found = {r[0]: r for r in rows}
    for rid in ids:
        if rid not in found:
            grounding.append({"id": rid, "record_type": rtype, "missing": True})
            continue
        _, _, title, text, meta = found[rid]
        meta = json.loads(meta)
        item = {"id": rid, "record_type": rtype, "label": title}
        if rtype == "uniprot_human":
            item["entry_name"] = meta.get("entry_name")
            item["gene_names"] = meta.get("gene_names")
            fn = field(text, "Function")
            item["function"] = re.sub(r"^FUNCTION: ", "", fn) if fn else None
            item["go_ids"] = meta.get("go_ids")
            item["go_terms"] = field(text, "Gene Ontology")
            item["drugbank"] = meta.get("drugbank")
        else:
            m = re.search(r'Definition: "(.*?)" \[', text, re.S)
            item["definition"] = m.group(1) if m else None
            item["is_a"] = meta.get("is_a", [])
            item["relationships"] = meta.get("relationships", [])
            item["xrefs"] = meta.get("xrefs", [])
            # synonyms in this catalogue are all the literal string '\1' (upstream bug); drop them
            item["synonyms_note"] = "synonyms field in source is corrupt (every value is '\\1'); omitted"
        grounding.append(item)

# labels for is_a / relationship targets, for readability
targets = set()
for g in grounding:
    for x in g.get("is_a", []): targets.add(x)
    for r in g.get("relationships", []):
        parts = r.split()
        if len(parts) >= 2: targets.add(parts[1])
labels = dict(con.execute(
    "SELECT record_id, any_value(title) FROM o WHERE record_id IN (SELECT unnest(?)) GROUP BY 1", [sorted(targets)]).fetchall())
for g in grounding:
    if "is_a" in g:
        g["is_a"] = [{"id": x, "label": labels.get(x)} for x in g["is_a"]]

json.dump(grounding, open(f"{OUT}/grounding.json", "w"), indent=1)
print(f"grounding.json: {len(grounding)} rows, missing: {[g['id'] for g in grounding if g.get('missing')]}")

# ---- GOA ----------------------------------------------------------------
cols = ["db", "db_object_id", "symbol", "qualifier", "go_id", "reference", "evidence", "with_from",
        "aspect", "name", "synonyms", "type", "taxon", "date", "assigned_by", "extension", "gene_product_form"]
go_label = dict(con.execute("SELECT record_id, any_value(title) FROM o WHERE record_type='ontology_go' GROUP BY 1").fetchall())
goa = {p: [] for p in GOA_PROTEINS}
with gzip.open(GAF, "rt") as fh:
    for line in fh:
        if line.startswith("!"): continue
        f = line.rstrip("\n").split("\t")
        if f[1] in goa:
            rec = dict(zip(cols, f))
            goa[f[1]].append({
                "symbol": rec["symbol"], "qualifier": rec["qualifier"], "go_id": rec["go_id"],
                "go_label": go_label.get(rec["go_id"]), "aspect": rec["aspect"],
                "evidence": rec["evidence"], "reference": rec["reference"],
                "pmids": re.findall(r"PMID:(\d+)", rec["reference"]),
                "with_from": rec["with_from"], "assigned_by": rec["assigned_by"], "date": rec["date"],
            })
summary = {p: {"n_annotations": len(v), "n_distinct_go": len({a['go_id'] for a in v}),
               "n_with_pmid": sum(1 for a in v if a["pmids"]),
               "evidence_codes": sorted({a["evidence"] for a in v})} for p, v in goa.items()}
json.dump({"source": GAF, "summary": summary, "annotations": goa}, open(f"{OUT}/goa.json", "w"), indent=1)
print("goa.json:", json.dumps(summary))
