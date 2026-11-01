"""Print title, first author, year, journal and abstract head for cached Europe PMC core records. Reads /tmp only."""
import json, sys, re
for p in sys.argv[1:]:
    d = json.load(open(f'/tmp/biolean-02b/dl/epmc2/{p}.json'))
    rs = d.get('resultList', {}).get('result', [])
    if not rs: print(p, 'NOT FOUND'); continue
    r = rs[0]
    a = re.sub(r'<[^>]+>', '', r.get('abstractText') or '')
    print(f"{p} | {r.get('authorString','')[:60]} | {r.get('pubYear')} | {r.get('title')} | {r.get('journalInfo',{}).get('journal',{}).get('title')}")
    print('   ', a[:int(sys.argv[0] and 900)])
