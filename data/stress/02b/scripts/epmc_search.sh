#!/bin/bash
# usage: epmc_search.sh <key> <query>; Europe PMC lite search into /tmp/biolean-02b/dl/epmc2/s_<key>.json, printed short
k="$1"; q="$2"; f="/tmp/biolean-02b/dl/epmc2/s_$k.json"
[ -s "$f" ] || curl -s -m 40 -G "https://www.ebi.ac.uk/europepmc/webservices/rest/search" --data-urlencode "query=$q" --data-urlencode "format=json" --data-urlencode "resultType=lite" --data-urlencode "pageSize=5" -o "$f"
python3 -I -c "
import json,sys
d=json.load(open(sys.argv[1])); print('==', sys.argv[2], d.get('hitCount'))
for r in d.get('resultList',{}).get('result',[])[:5]:
    print('   ', r.get('pmid'), r.get('pubYear'), (r.get('authorString') or '')[:50], '|', (r.get('title') or '')[:130])
" "$f" "$k"
