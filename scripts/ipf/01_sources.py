"""Copy one hypothesis-agent run and the text of everything it cites into data/ipf/.

The run is sealed in the IUK-IPF store; we read it, never write it. Abstracts come from the run's
own Europe PMC responses (what the agent saw), with the local PubMed corpus as fallback. UniProt
entries come from the local corpus. Output: data/ipf/run.json, data/ipf/sources.json.
"""
import glob
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from biolean.corpus import fetch_abstracts, query  # noqa: E402

STORE = Path("/home/danbolser/Work/IUK-IPF/hypothesis-agent/store")
RUN = "20260824T223623Z-4f7d1a"
OUT = ROOT / "data/ipf"


def main() -> None:
    run_dir = STORE / "runs" / RUN
    result = json.loads((run_dir / "result.json").read_text())
    manifest = json.loads((run_dir / "manifest.json").read_text())
    cited = json.dumps(result["hypotheses"])
    pmids = sorted(set(re.findall(r"PMID:(\d+)", cited)), key=int)
    accs = sorted(set(re.findall(r'"([OPQ][0-9][A-Z0-9]{3}[0-9])"', cited)))

    papers = {}
    for bundle in glob.glob(str(run_dir / "bundles/*.json")):
        for a in json.loads(Path(bundle).read_text())["artifacts"]:
            if "europepmc" not in a["adapter"]:
                continue
            for r in json.loads((STORE / a["path"]).read_text()).get("resultList", {}).get("result", []):
                if r.get("pmid") in pmids and r["pmid"] not in papers:
                    papers[r["pmid"]] = {
                        "year": int(r["pubYear"]), "title": r.get("title", ""),
                        "pubtypes": r.get("pubTypeList", {}).get("pubType", []),
                        "abstract": re.sub("<[^>]+>", "", r.get("abstractText", "")),
                        "source": f"europepmc artifact {a['artifact_id']}"}
    for ab in fetch_abstracts([int(p) for p in pmids if p not in papers]):
        papers[str(ab.pmid)] = {"year": ab.year, "title": ab.title, "pubtypes": [],
                                "abstract": ab.abstract, "source": "local PubMed corpus"}

    uniprot = {acc: text for acc, text in query(
        "select record_id, text from records where record_class = 'UniProt' and record_id = any(?)", [accs])}

    (OUT / "run.json").write_text(json.dumps(
        {"run_id": RUN, "model": manifest["question"]["model"], "question": manifest["question"],
         **result}, indent=1, ensure_ascii=False))
    (OUT / "sources.json").write_text(json.dumps(
        {"papers": dict(sorted(papers.items(), key=lambda kv: int(kv[0]))), "uniprot": uniprot},
        indent=1, ensure_ascii=False))
    print(f"{len(pmids)} PMIDs cited, {len(papers)} with text; {len(accs)} UniProt cited, {len(uniprot)} found")


if __name__ == "__main__":
    main()
