"""Program 05: check every CURIE the stress set cites against OLS4, and list GO's union taxa.

Downloads go to /tmp/biolean-05/ols2/ (untrusted; read back as data only). Run with
`python3 -I scripts/stress/grade_ols.py`. Writes data/stress/05/curies_checked.tsv and
data/stress/05/go_union_taxa.tsv.
"""
import json
import re
import pathlib
import sys
import time
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/05"
DL = pathlib.Path("/tmp/biolean-05/ols2")
DL.mkdir(parents=True, exist_ok=True)
API = "https://www.ebi.ac.uk/ols4/api/v2"

# (curie, ontology to look in, label we expect, or None to just record)
CURIES = [
    # taxa: the grades' building blocks
    ("NCBITaxon:131567", "ncbitaxon", "cellular organisms"), ("NCBITaxon:2", "ncbitaxon", "Bacteria"),
    ("NCBITaxon:2157", "ncbitaxon", "Archaea"), ("NCBITaxon:2759", "ncbitaxon", "Eukaryota"),
    ("NCBITaxon:33208", "ncbitaxon", "Metazoa"), ("NCBITaxon:4751", "ncbitaxon", "Fungi"),
    ("NCBITaxon:33090", "ncbitaxon", "Viridiplantae"), ("NCBITaxon:3193", "ncbitaxon", "Embryophyta"),
    ("NCBITaxon:7742", "ncbitaxon", "Vertebrata"), ("NCBITaxon:32523", "ncbitaxon", "Tetrapoda"),
    ("NCBITaxon:7898", "ncbitaxon", "Actinopterygii"), ("NCBITaxon:7777", "ncbitaxon", "Chondrichthyes"),
    ("NCBITaxon:7711", "ncbitaxon", "Chordata"), ("NCBITaxon:89593", "ncbitaxon", "Craniata"),
    ("NCBITaxon:8509", "ncbitaxon", "Squamata"), ("NCBITaxon:8570", "ncbitaxon", "Serpentes"),
    ("NCBITaxon:3041", "ncbitaxon", "Chlorophyta"), ("NCBITaxon:2763", "ncbitaxon", "Rhodophyta"),
    ("NCBITaxon:2698737", "ncbitaxon", "Sar"), ("NCBITaxon:5794", "ncbitaxon", "Apicomplexa"),
    ("NCBITaxon:1117", "ncbitaxon", "Cyanobacteriota"), ("NCBITaxon:28890", "ncbitaxon", "Methanobacteriota"),
    ("NCBITaxon:1485", "ncbitaxon", "Clostridium"), ("NCBITaxon:6656", "ncbitaxon", "Arthropoda"),
    ("NCBITaxon:6447", "ncbitaxon", "Mollusca"), ("NCBITaxon:6040", "ncbitaxon", "Porifera"),
    ("NCBITaxon:6340", "ncbitaxon", "Annelida"), ("NCBITaxon:2725", "ncbitaxon", None),
    ("NCBITaxon:102750", "ncbitaxon", "Ageratina altissima"),
    # test members
    ("NCBITaxon:562", "ncbitaxon", "Escherichia coli"), ("NCBITaxon:2246", "ncbitaxon", "Haloferax volcanii"),
    ("NCBITaxon:2285", "ncbitaxon", "Sulfolobus acidocaldarius"), ("NCBITaxon:2303", "ncbitaxon", "Thermoplasma acidophilum"),
    ("NCBITaxon:666", "ncbitaxon", "Vibrio cholerae"), ("NCBITaxon:2173", "ncbitaxon", "Methanobrevibacter smithii"),
    ("NCBITaxon:1148", "ncbitaxon", "Synechocystis sp. PCC 6803"), ("NCBITaxon:5833", "ncbitaxon", "Plasmodium falciparum"),
    ("NCBITaxon:3055", "ncbitaxon", "Chlamydomonas reinhardtii"), ("NCBITaxon:400682", "ncbitaxon", "Amphimedon queenslandica"),
    ("NCBITaxon:7830", "ncbitaxon", "Scyliorhinus canicula"), ("NCBITaxon:28377", "ncbitaxon", "Anolis carolinensis"),
    ("NCBITaxon:7227", "ncbitaxon", "Drosophila melanogaster"), ("NCBITaxon:6645", "ncbitaxon", "Octopus vulgaris"),
    ("NCBITaxon:6398", "ncbitaxon", "Lumbricus terrestris"), ("NCBITaxon:79327", "ncbitaxon", "Schmidtea mediterranea"),
    ("NCBITaxon:4932", "ncbitaxon", "Saccharomyces cerevisiae"), ("NCBITaxon:9606", "ncbitaxon", "Homo sapiens"),
    ("NCBITaxon:3702", "ncbitaxon", "Arabidopsis thaliana"), ("NCBITaxon:7955", "ncbitaxon", "Danio rerio"),
    ("NCBITaxon:3039", "ncbitaxon", "Euglena gracilis"), ("NCBITaxon:2880", "ncbitaxon", "Ectocarpus siliculosus"),
    ("NCBITaxon:4177", "ncbitaxon", "Epifagus virginiana"), ("NCBITaxon:2242", "ncbitaxon", "Halobacterium salinarum"),
    # cell types
    ("CL:0000000", "cl", "cell"), ("CL:0000520", "cl", "prokaryotic cell"), ("CL:0000255", "cl", "eukaryotic cell"),
    ("CL:0000521", "cl", "fungal cell"), ("CL:0000548", "cl", None), ("CL:0000610", "cl", None),
    ("PO:0009002", "po", "plant cell"),
    # components, processes
    ("GO:0005634", "go", "nucleus"), ("GO:0005886", "go", "plasma membrane"), ("GO:0005737", "go", "cytoplasm"),
    ("GO:0005840", "go", "ribosome"), ("GO:0005618", "go", "cell wall"), ("GO:0009505", "go", "plant-type cell wall"),
    ("GO:0009277", "go", "fungal-type cell wall"), ("GO:0043231", "go", "intracellular membrane-bounded organelle"),
    ("GO:0043227", "go", "membrane-bounded organelle"), ("GO:0009288", "go", "bacterial-type flagellum"),
    ("GO:0097589", "go", "archaeal-type flagellum"), ("GO:0009289", "go", "pilus"), ("GO:0005694", "go", "chromosome"),
    ("GO:0009295", "go", "nucleoid"), ("GO:0009507", "go", "chloroplast"), ("GO:0020011", "go", "apicoplast"),
    ("GO:0005813", "go", "centrosome"), ("GO:0005764", "go", "lysosome"), ("GO:0005856", "go", "cytoskeleton"),
    ("GO:0022904", "go", "respiratory electron transport chain"), ("GO:0005743", "go", "mitochondrial inner membrane"),
    ("GO:0006351", "go", "DNA-templated transcription"), ("GO:0043093", "go", "FtsZ-dependent cytokinesis"),
    ("GO:0051301", "go", "cell division"), ("GO:0015979", "go", "photosynthesis"), ("GO:0006096", "go", "glycolytic process"),
    ("GO:0009061", "go", "anaerobic respiration"), ("GO:0015948", "go", "methanogenesis"),
    ("GO:0140014", "go", "mitotic nuclear division"), ("GO:0072686", "go", "mitotic spindle"),
    ("GO:0042651", "go", "thylakoid membrane"), ("GO:0009579", "go", "thylakoid"),
    # chemicals, proteins, sequence
    ("CHEBI:8005", "chebi", "peptidoglycan"), ("CHEBI:18246", "chebi", None), ("CHEBI:16991", "chebi", None),
    ("CHEBI:28384", "chebi", None), ("PR:000022726", "pr", None), ("SO:0000296", "so", "origin_of_replication"),
    ("SO:0001026", "so", "genome"), ("SO:0000155", "so", "plasmid"), ("SO:0000958", "so", None),
    ("SO:0000340", "so", "chromosome"),
    # anatomy
    ("UBERON:0009054", "uberon", "open circulatory system"), ("UBERON:0001009", "uberon", "circulatory system"),
    ("UBERON:0007798", "uberon", None), ("UBERON:0000160", "uberon", "intestine"), ("UBERON:0001555", "uberon", "digestive tract"),
    # outside the imported ontologies
    ("NCIT:C14263", "ncit", "Prokaryote"), ("NCIT:C77914", "ncit", None), ("ECOCORE:00000076", "ecocore", "algae"),
    ("ECOCORE:00000023", "ecocore", "autotroph"),
    # relations
    ("RO:0002162", "ro", "in taxon"), ("RO:0002160", "ro", "only in taxon"), ("RO:0002161", "ro", "never in taxon"),
    ("RO:0002175", "ro", "present in taxon"), ("RO:0002504", "ro", None), ("BFO:0000051", "ro", "has part"),
    ("BFO:0000066", "ro", "occurs in"),
    # GO's union taxa
    ("NCBITaxon_Union:0000004", "go", "Prokaryota"), ("NCBITaxon_Union:0000023", "go", None),
    ("NCBITaxon_Union:0000000", "go", None), ("NCBITaxon_Union:0000002", "go", None),
    ("NCBITaxon:5691", "ncbitaxon", "Trypanosoma brucei"), ("NCBITaxon:33072", "ncbitaxon", "Gloeobacter violaceus"),
    ("NCBITaxon:3038", "ncbitaxon", "Euglena"), ("NCBITaxon:5884", "ncbitaxon", "Paramecium"),
    ("NCBITaxon:2283796", "ncbitaxon", "Thermoplasmatota"), ("NCBITaxon:3366610", "ncbitaxon", "Methanobacteriati"),
    ("NCBITaxon:1783275", "ncbitaxon", "Thermoproteati"), ("NCBITaxon:8504", "ncbitaxon", "Lepidosauria"),
    ("GO:0005814", "go", "centriole"), ("GO:0008219", "go", "cell death"), ("CHEBI:15379", "chebi", "dioxygen"),
    ("CHEBI:16646", "chebi", "carbohydrate"), ("GO:0009274", "go", None),
    ("GO:0030115", "go", "S-layer"),
    # added in the second run: members and grade parts used by options d, e, f
    ("NCBITaxon:2022461", "ncbitaxon", "Candidatus Thiomargarita sp. Lot2"),
    ("NCBITaxon:2049356", "ncbitaxon", "Monocercomonoides exilis"), ("NCBITaxon:33682", "ncbitaxon", "Euglenozoa"),
    ("NCBITaxon:2870", "ncbitaxon", "Phaeophyceae"), ("RO:0002215", "ro", "capable of"),
    ("GO:0016020", "go", "membrane"),
    # added in review, 2026-10-31: C03, P18, I03
    ("NCBITaxon:13815", "ncbitaxon", "Marsilea"), ("GO:0020015", "go", "glycosome"), ("GO:0042579", "go", "microbody"),
    ("GO:0005777", "go", "peroxisome"), ("GO:0005829", "go", "cytosol"), ("UBERON:0006314", "uberon", "bodily fluid"),
    ("UBERON:0000062", "uberon", "organ"),
]


def iri(curie):
    pre, loc = curie.split(":", 1)
    return f"http://purl.obolibrary.org/obo/{pre}_{loc}"


def get(url, path):
    if not path.exists():
        for attempt in range(3):
            try:
                with urllib.request.urlopen(url, timeout=60) as r:
                    path.write_bytes(r.read())
                break
            except Exception as e:  # network trouble: retry, then record
                err = e
                time.sleep(2)
        else:
            return {"_error": str(err)}
    try:
        return json.loads(path.read_text())
    except Exception as e:
        return {"_error": str(e)}


def first(x):
    if isinstance(x, list):
        return x[0] if x else None
    return x


def text(x):
    """OLS4 v2 values may be strings, lists or {'value': ...} dicts."""
    x = first(x)
    if isinstance(x, dict):
        return x.get("value")
    return x


def fetch(curie, onto):
    q = urllib.parse.quote(urllib.parse.quote(iri(curie), safe=""), safe="")
    kind = "properties" if curie.startswith(("RO:", "BFO:")) else "classes"
    return get(f"{API}/ontologies/{onto}/{kind}/{q}", DL / f"{curie.replace(':', '_')}.{onto}.json")


def main():
    rows = []
    bad = 0
    for curie, onto, want in CURIES:
        d = fetch(curie, onto)
        if "_error" in d or not d.get("iri"):
            rows.append((curie, onto, "", "", "", "NOT FOUND", d.get("_error", "")[:80]))
            bad += 1
            continue
        lab = text(d.get("label")) or ""
        obs = d.get("isObsolete")
        defn = text(d.get("definition")) or ""
        eq = d.get("http://www.w3.org/2002/07/owl#equivalentClass")
        repl = text(d.get("http://purl.obolibrary.org/obo/IAO_0100001")) or ""
        ok = "ok" if (want is None or re.sub(r" <[^>]*>$", "", lab).lower().replace("obsolete ", "") == want.lower()) else f"LABEL MISMATCH (want {want})"
        if obs:
            ok += " OBSOLETE"
        note = (defn[:150] + (f" | replaced_by {repl}" if repl else "")).replace("\t", " ").replace("\n", " ")
        if eq:
            note += " | equivalentClass " + json.dumps(eq)[:300]
        rows.append((curie, onto, lab, str(obs), d.get("ontologyId", ""), ok, note))
    with open(OUT / "curies_checked.tsv", "w") as f:
        f.write("# checked on OLS4 (api/v2), 2026-10-31, by scripts/stress/grade_ols.py\n")
        f.write("curie\tontology\tlabel\tobsolete\tsource\tcheck\tnote\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    for r in rows:
        if not r[5].startswith("ok") or "OBSOLETE" in r[5]:
            print(r)
    print(f"{len(rows)} curies, {bad} not found")
    # every NCBITaxon_Union term in GO, with its union members
    s = get(f"https://www.ebi.ac.uk/ols4/api/search?q=NCBITaxon_Union&ontology=go&rows=200&queryFields=short_form,obo_id",
            DL / "search_union_go.json")
    docs = (s.get("response") or {}).get("docs", [])
    out = []
    for doc in docs:
        c = doc.get("obo_id") or ""
        if not c.startswith("NCBITaxon_Union:"):
            continue
        d = fetch(c, "go")
        eq = d.get("http://www.w3.org/2002/07/owl#equivalentClass") or {}
        mem = eq.get("http://www.w3.org/2002/07/owl#unionOf", []) if isinstance(eq, dict) else []
        links = d.get("linkedEntities") or {}
        names = [f"{m.rsplit('/', 1)[-1].replace('_', ':', 1)} {text((links.get(m) or {}).get('label'))}" for m in mem]
        out.append((c, text(d.get("label")) or "", "; ".join(names)))
    out.sort()
    with open(OUT / "go_union_taxa.tsv", "w") as f:
        f.write("# NCBITaxon_Union classes in GO (go-plus via OLS4), 2026-10-31\ncurie\tlabel\tunionOf\n")
        for r in out:
            f.write("\t".join(r) + "\n")
    print(len(out), "GO union taxa")
    for r in out:
        print("  ", r)


GRADE_NAMES = ["prokaryotes", "Prokaryota", "Protista", "protists", "algae", "Invertebrata", "invertebrates",
               "Pisces", "fishes", "Lacertilia", "lizards", "Reptilia", "microorganisms"]


def grade_search():
    """Exact-label search in NCBITaxon for each grade name; record what OLS4 returns."""
    rows = []
    for g in GRADE_NAMES:
        q = urllib.parse.quote(g)
        d = get(f"https://www.ebi.ac.uk/ols4/api/search?q={q}&ontology=ncbitaxon&exact=true&rows=10"
                "&queryFields=label,synonym", DL / f"search_ncbitaxon_{g}.json")
        docs = (d.get("response") or {}).get("docs", [])
        rows.append((g, "; ".join(f"{x.get('obo_id')} {x.get('label')}" for x in docs) or "none"))
    with open(OUT / "ncbitaxon_grade_names.tsv", "w") as f:
        f.write("# exact label or synonym search in NCBITaxon (OLS4), 2026-10-31\nname\thits\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    for r in rows:
        print("  ", r)


if __name__ == "__main__":
    grade_search()
    sys.exit(main())
