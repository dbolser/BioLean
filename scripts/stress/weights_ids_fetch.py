"""Program 10a: read-only lookups of CURIEs on OLS4 and DOIs on Crossref. Writes one JSON file,
which is untrusted data: read it back only with `python3 -I`.

usage: python3 -I scripts/stress/weights_ids_fetch.py OUT.json CURIES.txt DOI [DOI ...]
"""
import json
import sys
import time
import urllib.parse
import urllib.request

OLS = "https://www.ebi.ac.uk/ols4/api/terms?"
CROSSREF = "https://api.crossref.org/works/"


def iri(curie):
    pre, num = curie.split(":", 1)
    return f"http://purl.obolibrary.org/obo/{pre}_{num}"


def ols(curie):
    terms = []
    for kind in ("terms", "properties"):  # RO relations and SEPIO "contradicts" are properties
        url = OLS.replace("terms?", kind + "?") + urllib.parse.urlencode({"iri": iri(curie)})
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                d = json.load(r)
        except Exception as e:  # noqa: BLE001 - report and continue
            if kind == "properties":
                return {"found": False, "error": str(e)}
            continue
        terms = d.get("_embedded", {}).get(kind, [])
        if terms:
            break
    if not terms:
        return {"found": False}
    # prefer the defining ontology
    pre = curie.split(":")[0].lower()
    t = next((t for t in terms if t.get("ontology_name") == pre or t.get("is_defining_ontology")), terms[0])
    return {"found": True, "label": t.get("label"), "ontology": t.get("ontology_name"),
            "obsolete": t.get("is_obsolete")}


def crossref(doi):
    try:
        with urllib.request.urlopen(CROSSREF + urllib.parse.quote(doi), timeout=60) as r:
            m = json.load(r)["message"]
    except Exception as e:  # noqa: BLE001
        return {"found": False, "error": str(e)}
    authors = m.get("author", [])
    first = (authors[0].get("family") or authors[0].get("name", "")) if authors else ""
    year = (m.get("issued", {}).get("date-parts") or [[None]])[0][0]
    return {"found": True, "title": (m.get("title") or [""])[0], "first": first, "year": year,
            "container": (m.get("container-title") or [""])[0]}


def main():
    out, curies_file, dois = sys.argv[1], sys.argv[2], sys.argv[3:]
    curies = [c.strip() for c in open(curies_file) if ":" in c and not c.startswith("GO_REF")]
    res = {"curies": {}, "dois": {}}
    for c in curies:
        res["curies"][c] = ols(c)
        time.sleep(0.15)
    for d in dois:
        res["dois"][d] = crossref(d)
        time.sleep(0.3)
    json.dump(res, open(out, "w"), indent=1)
    bad = [c for c, v in res["curies"].items() if not v.get("found") or v.get("obsolete")]
    print(f"{len(curies)} CURIEs, not found or obsolete: {bad}; {len(dois)} DOIs")


if __name__ == "__main__":
    main()
