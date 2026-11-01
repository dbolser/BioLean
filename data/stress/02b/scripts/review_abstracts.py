"""Program 02b review: print Europe PMC abstracts for the PMIDs given, fetched fresh to /tmp/biolean-02b/review/dl/
(untrusted; run with python3 -I). Writes nothing in the repo. Usage: python3 -I review_abstracts.py PMID ..."""
import json, sys, re, html, pathlib, urllib.request, urllib.parse, time
DL = pathlib.Path('/tmp/biolean-02b/review/dl'); DL.mkdir(parents=True, exist_ok=True)
for pmid in sys.argv[1:]:
    f = DL / f'core_{pmid}.json'
    if not f.exists() or f.stat().st_size == 0:
        url = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search?' + urllib.parse.urlencode({'query': f'EXT_ID:{pmid} AND SRC:MED', 'format': 'json', 'resultType': 'core'})
        with urllib.request.urlopen(url, timeout=40) as r: f.write_bytes(r.read())
        time.sleep(0.12)
    r = (json.loads(f.read_text()).get('resultList', {}).get('result') or [{}])[0]
    ab = re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', r.get('abstractText') or ''))).strip()
    print(f"=== {pmid} {(r.get('authorString') or '')[:40]} {r.get('pubYear')} | {r.get('title')}\n{ab}\n")
