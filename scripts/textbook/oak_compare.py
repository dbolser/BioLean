"""Compare OAK (oaklib) lexical groundings with agent-assigned CURIEs over the textbook claims.

Usage: uv run python scripts/textbook/oak_compare.py
Writes data/textbook/oak_compare.tsv. First run downloads semsql sqlite files into ~/.data/oaklib.

For each distinct mention text, every ontology is annotated with OAK's annotate_text. A hit
counts only if its span covers >= 90% of the text. Pick: longest span, then predicate
(label > exact > related > broad/narrow), then a term native to the queried ontology,
then ONTOLOGIES order.
"""
import csv
import glob
import json
import random
from collections import Counter
from multiprocessing import Pool
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[2]
CLAIMS = ROOT / "data/textbook/claims"
LABELS = ROOT / "data/lookup/labels.parquet"
OUT = ROOT / "data/textbook/oak_compare.tsv"

# ncbitaxon skipped: 2.4 GB download.
ONTOLOGIES = ["go", "uberon", "cl", "pato", "hp", "mondo", "chebi"]
PRED_RANK = {"rdfs:label": 0, "oio:hasExactSynonym": 1, "oio:hasRelatedSynonym": 2,
             "oio:hasBroadSynonym": 3, "oio:hasNarrowSynonym": 3}
MIN_COVER = 0.9


def annotate(args):
    """Annotate every text against one ontology; keep hits covering >= MIN_COVER of the text."""
    ont, texts, agent_curies = args
    from oaklib import get_adapter
    adapter = get_adapter(f"sqlite:obo:{ont}")
    hits = {}
    for text in texts:
        keep = []
        for a in adapter.annotate_text(text):
            span = a.subject_end - a.subject_start + 1
            if span / len(text) >= MIN_COVER:
                keep.append((span, a.predicate_id, a.object_id, a.object_label, ont))
        if keep:
            hits[text] = keep
    prefix = ont.upper()
    labels = {c: adapter.label(c) for c in agent_curies if c.split(":")[0].upper() == prefix}
    return hits, labels


def rank(hit):
    span, pred, curie, _, ont = hit
    native = curie.split(":")[0].upper() == ont.upper()
    return (-span, PRED_RANK.get(pred, 9), not native, ONTOLOGIES.index(ont))


def main():
    pairs = Counter()  # (text, curie) -> mention count
    n_mentions = 0
    for f in sorted(glob.glob(str(CLAIMS / "*.json"))):
        for claim in json.load(open(f)):
            for e in claim.get("entities", []):
                n_mentions += 1
                pairs[(e["text"], e.get("curie"))] += 1
    texts = sorted({t for t, _ in pairs if t.strip()})
    agent_curies = sorted({c for _, c in pairs if c})

    with Pool(len(ONTOLOGIES)) as pool:
        results = pool.map(annotate, [(o, texts, agent_curies) for o in ONTOLOGIES])
    hits, labels = {}, {}
    for h, lab in results:
        for t, v in h.items():
            hits.setdefault(t, []).extend(v)
        labels.update({c: l for c, l in lab.items() if l})
    for c, l in duckdb.execute(
            f"select curie, any_value(label) from '{LABELS}' where method = 'exact_label' group by curie").fetchall():
        labels.setdefault(c, l)

    rows = []
    for (text, agent), n in sorted(pairs.items(), key=lambda kv: -kv[1]):
        cands = sorted(hits.get(text, []), key=rank)
        if cands:
            best = cands[0]
            o_curie, o_name, o_pred = best[2], labels.get(best[2]) or best[3], best[1]
            n_tied = len({c[2] for c in cands if rank(c)[:3] == rank(best)[:3]})
        else:
            o_curie = o_name = o_pred = ""
            n_tied = 0
        if agent and o_curie:
            status = "agree" if agent == o_curie else "disagree"
        elif o_curie:
            status = "oak_only"
        elif agent:
            status = "agent_only"
        else:
            status = "neither"
        rows.append(dict(text=text, n=n, agent_curie=agent or "", agent_name=labels.get(agent, "") if agent else "",
                         oak_curie=o_curie, oak_name=o_name, oak_pred=o_pred, oak_n_tied=n_tied, status=status))

    with open(OUT, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]), delimiter="\t")
        w.writeheader()
        w.writerows(rows)

    pfx = lambda c: c.split(":")[0] if c else "-"
    counts = Counter(r["status"] for r in rows)
    print("mentions", n_mentions, "distinct (text, curie) pairs", len(rows), "distinct texts", len(texts))
    print("oak hit", sum(1 for r in rows if r["oak_curie"]))
    print(dict(counts))
    print("\nby agent prefix: status counts")
    by = {}
    for r in rows:
        by.setdefault(pfx(r["agent_curie"]), Counter())[r["status"]] += 1
    for p, c in sorted(by.items(), key=lambda kv: -sum(kv[1].values())):
        print(f"  {p:10s} {sum(c.values()):5d} {dict(c)}")
    print("oak_only by prefix", Counter(pfx(r["oak_curie"]) for r in rows if r["status"] == "oak_only"))
    print("disagree by prefix pair", Counter((pfx(r["agent_curie"]), pfx(r["oak_curie"])) for r in rows if r["status"] == "disagree").most_common(15))
    print("disagree same prefix", sum(1 for r in rows if r["status"] == "disagree" and pfx(r["agent_curie"]) == pfx(r["oak_curie"])))
    print("oak_pred of picks", Counter(r["oak_pred"] for r in rows if r["oak_curie"]))
    print("ties (>1 CURIE at top rank)", sum(1 for r in rows if r["oak_n_tied"] > 1))
    random.seed(1)
    dis = [r for r in rows if r["status"] == "disagree"]
    print("\n30 random disagreements:")
    for r in random.sample(dis, min(30, len(dis))):
        print(f"{r['text']!r}\t{r['agent_curie']} ({r['agent_name']})\t{r['oak_curie']} ({r['oak_name']}, {r['oak_pred']}, tied={r['oak_n_tied']})")


if __name__ == "__main__":
    main()
