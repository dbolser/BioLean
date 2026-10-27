"""Compare the EBI OLS text tagger (api/v2/tag_text) with agent CURIEs, and with OAK.

Usage: uv run python scripts/textbook/ols_compare.py
Needs data/textbook/oak_compare.tsv (from oak_compare.py). Writes data/textbook/ols_compare.tsv.

Same rules as oak_compare.py: every distinct mention text is tagged, a hit counts only if its
span covers >= 90% of the text; pick longest span, then string type (label > exact > related >
broad/narrow), then ONTOLOGIES order. Same 7 ontologies as the OAK run, for a fair comparison.
Texts are ASCII-normalised first. The service returns UTF-8 BYTE offsets, so we slice bytes.
"""
import csv
import re
import time
from collections import Counter
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "data/textbook/oak_compare.tsv"
OUT = ROOT / "data/textbook/ols_compare.tsv"
URL = "https://www.ebi.ac.uk/ols4/api/v2/tag_text"
ONTOLOGIES = ["go", "uberon", "cl", "pato", "hp", "mondo", "chebi"]
TYPE_RANK = {"LABEL": 0, "EXACT": 1, "RELATED": 2, "BROAD": 3, "NARROW": 3}
MIN_COVER = 0.9
BATCH = 150
DELIMS = " ,.;:!?\t\n()[]{}\"'/\\-"
ASCII = str.maketrans({"’": "'", "‘": "'", "“": '"', "”": '"', "–": "-", "—": "-"})


def curie(iri):
    m = re.search(r"/obo/([A-Za-z]+)_(\w+)$", iri)
    return f"{m[1].upper()}:{m[2]}" if m else iri


def tag(texts):
    """Tag texts joined by newlines. Return {text: [(span, type_rank, ont_rank, curie, label)]}."""
    body = "\n".join(texts)
    raw = body.encode()
    params = [("ontologyId", o) for o in ONTOLOGIES] + [
        ("minLength", "3"), ("includeSubstrings", "false"), ("delimiters", DELIMS)]
    for attempt in range(5):
        r = requests.post(URL, params=params, json={"text": body}, timeout=300)
        if r.ok:
            break
        time.sleep(5 * (attempt + 1))
    r.raise_for_status()
    starts, pos = [], 0
    for t in texts:
        starts.append((pos, pos + len(t.encode()), t))
        pos += len(t.encode()) + 1
    import bisect
    begs = [s[0] for s in starts]
    out = {}
    for e in r.json()["entities"]:
        i = bisect.bisect_right(begs, e["start"]) - 1
        b0, b1, t = starts[i]
        if e["end"] > b1:
            continue  # crosses a line boundary
        span = e["end"] - e["start"]
        if span / max(1, b1 - b0) >= MIN_COVER:
            out.setdefault(t, []).append((span, TYPE_RANK.get(e["string_type"], 9),
                                          ONTOLOGIES.index(e["ontology_id"]) if e["ontology_id"] in ONTOLOGIES else 99,
                                          curie(e["term_iri"]), e["term_label"]))
    return out


def main():
    rows = list(csv.DictReader(open(SRC), delimiter="\t"))
    norm = {r["text"]: r["text"].translate(ASCII).replace("\n", " ").strip() for r in rows}
    texts = sorted({t for t in norm.values() if t})
    hits = {}
    for i in range(0, len(texts), BATCH):
        hits.update(tag(texts[i:i + BATCH]))
        print(f"tagged {min(i + BATCH, len(texts))}/{len(texts)}", flush=True)
        time.sleep(2)

    out = []
    for r in rows:
        c = sorted(hits.get(norm[r["text"]], []), key=lambda h: (-h[0], h[1], h[2]))
        best = c[0] if c else None
        ols = best[3] if best else ""
        agent, oak = r["agent_curie"], r["oak_curie"]
        if agent and ols:
            status = "agree" if agent == ols else "disagree"
        elif ols:
            status = "ols_only"
        elif agent:
            status = "agent_only"
        else:
            status = "neither"
        out.append(dict(text=r["text"], n=r["n"], agent_curie=agent, agent_name=r["agent_name"],
                        oak_curie=oak, oak_status=r["status"], ols_curie=ols,
                        ols_name=best[4] if best else "", ols_type=best[1] if best else "",
                        ols_n_tied=len({h[3] for h in c if h[:3] == best[:3]}) if best else 0,
                        status=status, ols_vs_oak=("agree" if ols == oak else "differ") if ols and oak else "",
                        ))
    with open(OUT, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(out[0]), delimiter="\t")
        w.writeheader()
        w.writerows(out)

    pfx = lambda c: c.split(":")[0] if c else "-"
    print("pairs", len(out), "distinct texts", len(texts))
    print("ols hit", sum(1 for r in out if r["ols_curie"]), "oak hit", sum(1 for r in out if r["oak_curie"]))
    print("OLS status", dict(Counter(r["status"] for r in out)))
    print("OAK status", dict(Counter(r["oak_status"] for r in out)))
    by = {}
    for r in out:
        by.setdefault(pfx(r["agent_curie"]), Counter())[r["status"]] += 1
    for p, c in sorted(by.items(), key=lambda kv: -sum(kv[1].values())):
        print(f"  {p:10s} {sum(c.values()):5d} {dict(c)}")
    print("ols_only by prefix", Counter(pfx(r["ols_curie"]) for r in out if r["status"] == "ols_only"))
    both = [r for r in out if r["ols_curie"] and r["oak_curie"]]
    print("both hit", len(both), "OLS==OAK", sum(r["ols_vs_oak"] == "agree" for r in both))
    print("ols ties", sum(r["ols_n_tied"] > 1 for r in out))


if __name__ == "__main__":
    main()
