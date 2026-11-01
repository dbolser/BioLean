"""Print what was downloaded into /tmp/biolean-08/dl (untrusted data: run with python3 -I).

    python3 -I scripts/stress/gaps_show_dl.py epmc|abs|crossref|ols|olsprop [DIR]
"""

import glob
import json
import os
import sys

kind = sys.argv[1]
base = sys.argv[2] if len(sys.argv) > 2 else "/tmp/biolean-08/dl"


def safe(s, n=160):
    return str(s or "").replace("\n", " ").replace("\t", " ")[:n]


for f in sorted(glob.glob(os.path.join(base, kind, "*.json"))):
    key = os.path.basename(f)[:-5]
    try:
        d = json.load(open(f))
    except Exception as e:  # noqa: BLE001
        print(key, "UNREADABLE", e)
        continue
    if kind in ("epmc", "abs"):
        res = (d.get("resultList") or {}).get("result") or []
        if not res:
            print(f"{key}\t(no hits)")
        for r in res[:5]:
            print("\t".join([key, safe(r.get("pmid")), safe(r.get("doi")), safe(r.get("pubYear")),
                             safe(r.get("authorString"), 50), safe(r.get("title"), 150),
                             safe(r.get("journalTitle"), 40)]))
    elif kind == "crossref":
        m = d.get("message") or {}
        items = m.get("items") if isinstance(m.get("items"), list) else [m]
        for it in items[:3]:
            au = it.get("author") or [{}]
            print("\t".join([key, safe(it.get("DOI")), safe((it.get("issued") or {}).get("date-parts")),
                             safe(au[0].get("family")), safe((it.get("title") or [""])[0], 150),
                             safe((it.get("container-title") or [""])[0], 50)]))
    else:
        terms = ((d.get("_embedded") or {}).get("terms")) or []
        if not terms:
            print(f"{key}\t(no term)")
        for t in terms[:1]:
            print("\t".join([key, safe(t.get("obo_id")), safe(t.get("label"), 80),
                             "obsolete" if t.get("is_obsolete") else "live",
                             safe((t.get("description") or [""])[0], 120)]))
