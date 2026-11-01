"""Program 02b review: Europe PMC search, results fetched to /tmp/biolean-02b/review/dl/ (untrusted; run with python3 -I).
Prints PMID, first author, year, title. Writes nothing in the repo. Usage: python3 -I review_search.py 'query' [n]"""
import json, sys, re, pathlib, urllib.request, urllib.parse, time, hashlib
DL = pathlib.Path('/tmp/biolean-02b/review/dl'); DL.mkdir(parents=True, exist_ok=True)
q = sys.argv[1]; n = int(sys.argv[2]) if len(sys.argv) > 2 else 8
f = DL / ('search_' + hashlib.md5(q.encode()).hexdigest() + '.json')
if not f.exists() or f.stat().st_size == 0:
    url = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search?' + urllib.parse.urlencode({'query': q, 'format': 'json', 'pageSize': n})
    with urllib.request.urlopen(url, timeout=40) as r: f.write_bytes(r.read())
for r in json.loads(f.read_text()).get('resultList', {}).get('result', []):
    print(r.get('pmid'), '|', (r.get('authorString') or '')[:30], '|', r.get('pubYear'), '|', r.get('title'))
