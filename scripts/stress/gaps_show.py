import json, glob, re, sys
ROOT = "/home/danbolser/Build/BioLean"
recs = {}
for d in ["claims", "claims_m2", "claims_m3"]:
    for f in glob.glob(f"{ROOT}/data/textbook/{d}/*.json"):
        for r in json.load(open(f)):
            recs.setdefault(r["id"], {})[d] = r
lean = {}
for rnd in ["R2", "R3"]:
    for f in glob.glob(f"{ROOT}/BioLean/Lib/TextbookClaims{rnd}/*.lean"):
        txt = open(f).read()
        for m in re.finditer(r'id := "([^"]+)"\n  text := "([^"]*)"\n  claim := (.*)\n', txt):
            lean.setdefault(m.group(1), {})[rnd] = m.group(3)
def show(i):
    r = recs.get(i, {})
    base = r.get("claims") or r.get("claims_m2") or r.get("claims_m3") or {}
    print("==", i)
    print("  src:", base.get("source", "")[:300])
    print("  claim:", base.get("claim"))
    c = r.get("claims")
    if c: print("  r1: bin=%s mc=%s" % (c.get("bin"), c.get("missing_construct")))
    m2 = (r.get("claims_m2") or {}).get("m2") or (r.get("claims") or {}).get("m2")
    if m2: print("  m2:", {k: v for k, v in m2.items() if v and k not in ("curie_changes",)})
    m3 = (r.get("claims_m3") or {}).get("m3")
    if m3: print("  m3:", {k: v for k, v in m3.items() if v and k not in ("curie_changes",)})
    for rnd, cl in lean.get(i, {}).items(): print("  lean", rnd, ":", cl[:300])
for i in sys.argv[1:]:
    show(i)
