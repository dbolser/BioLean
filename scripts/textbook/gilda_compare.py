"""Compare Gilda groundings with agent-assigned CURIEs over the textbook claims.

Usage: uv run python scripts/textbook/gilda_compare.py
Writes data/textbook/gilda_compare.tsv.
"""
import csv
import glob
import json
import random
from collections import Counter
from pathlib import Path

import gilda

ROOT = Path(__file__).resolve().parents[2]
CLAIMS = ROOT / "data/textbook/claims"
OUT = ROOT / "data/textbook/gilda_compare.tsv"

DB_PREFIX = {"UP": "UniProt"}  # Gilda db -> CURIE prefix where they differ


def gilda_curie(term):
    if ":" in term.id:
        return term.id
    return f"{DB_PREFIX.get(term.db, term.db)}:{term.id}"


def main():
    pairs = Counter()  # (text, curie) -> mention count
    n_mentions = 0
    for f in sorted(glob.glob(str(CLAIMS / "*.json"))):
        for claim in json.load(open(f)):
            for e in claim.get("entities", []):
                n_mentions += 1
                pairs[(e["text"], e.get("curie"))] += 1

    rows = []
    cache = {}
    for (text, agent), n in sorted(pairs.items(), key=lambda kv: -kv[1]):
        if text not in cache:
            m = gilda.ground(text)
            cache[text] = (gilda_curie(m[0].term), m[0].term.entry_name, round(m[0].score, 3)) if m else (None, None, None)
        g_curie, g_name, g_score = cache[text]
        if agent and g_curie:
            status = "agree" if agent == g_curie else "disagree"
        elif g_curie:
            status = "gilda_only"
        elif agent:
            status = "agent_only"
        else:
            status = "neither"
        rows.append(dict(text=text, n=n, agent_curie=agent or "", gilda_curie=g_curie or "",
                         gilda_name=g_name or "", gilda_score=g_score if g_score is not None else "", status=status))

    with open(OUT, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]), delimiter="\t")
        w.writeheader()
        w.writerows(rows)

    counts = Counter(r["status"] for r in rows)
    print("mentions", n_mentions, "distinct (text, curie) pairs", len(rows), "distinct texts", len(cache))
    print("gilda hit", sum(1 for r in rows if r["gilda_curie"]))
    print(dict(counts))
    print("gilda_only by prefix", Counter(r["gilda_curie"].split(":")[0] for r in rows if r["status"] == "gilda_only"))
    print("disagree by prefix pair", Counter((r["agent_curie"].split(":")[0], r["gilda_curie"].split(":")[0]) for r in rows if r["status"] == "disagree").most_common(12))
    random.seed(1)
    dis = [r for r in rows if r["status"] == "disagree"]
    print("\n30 random disagreements:")
    for r in random.sample(dis, min(30, len(dis))):
        print(f"{r['text']!r}\t{r['agent_curie']}\t{r['gilda_curie']} ({r['gilda_name']}, {r['gilda_score']})")


if __name__ == "__main__":
    main()
