"""Print sentences of cached Europe PMC abstracts that match a regex. Usage: epmc_grep.py <regex> PMID..."""
import json, sys, re
pat = re.compile(sys.argv[1], re.I)
for p in sys.argv[2:]:
    r = json.load(open(f'/tmp/biolean-02b/dl/epmc2/{p}.json'))['resultList']['result'][0]
    a = re.sub(r'<[^>]+>', '', r.get('abstractText') or '')
    for s in re.split(r'(?<=[.;])\s+', a):
        if pat.search(s): print(f'{p}: {s}')
