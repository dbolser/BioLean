#!/bin/bash
# usage: ols_search.sh <ontology|-> <query...>; OLS4 search, saved under /tmp/biolean-02b/dl/search2/, printed short
onto="$1"; shift; q="$*"
slug=$(echo "${onto}_$q" | tr -c 'A-Za-z0-9_' '_')
f="/tmp/biolean-02b/dl/search2/$slug.json"
args=(--data-urlencode "q=$q" --data-urlencode "rows=6" --data-urlencode "fieldList=obo_id,label,ontology_name,is_defining_ontology")
[ "$onto" != "-" ] && args+=(--data-urlencode "ontology=$onto")
[ -s "$f" ] || curl -s -m 30 -G "https://www.ebi.ac.uk/ols4/api/search" "${args[@]}" -o "$f"
python3 -I -c "
import json,sys
d=json.load(open(sys.argv[1]))
for x in d.get('response',{}).get('docs',[]):
    if x.get('is_defining_ontology'): print('   ', x.get('obo_id'), '|', x.get('label'), '|', x.get('ontology_name'))
" "$f"
