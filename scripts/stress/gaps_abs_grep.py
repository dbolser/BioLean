"""Grep saved Europe PMC abstracts (untrusted; run with python3 -I).

    python3 -I scripts/stress/gaps_abs_grep.py PMID REGEX [PMID REGEX ...]
"""
import json, re, sys
base = "/tmp/biolean-08/dl/abs"
args = sys.argv[1:]
for pmid, pat in zip(args[::2], args[1::2]):
    try:
        r = json.load(open(f"{base}/{pmid}.json"))["resultList"]["result"][0]
    except Exception as e:
        print(pmid, "NO ABSTRACT", e); continue
    ab = r.get("abstractText") or ""
    print(f"== {pmid} {r.get('authorString','')[:40]} {r.get('pubYear')} | {r.get('title','')[:90]}")
    for s in re.split(r"(?<=[.;])\s+", re.sub("<[^>]+>", "", ab)):
        if re.search(pat, s, re.I):
            print("   >", s[:400])
