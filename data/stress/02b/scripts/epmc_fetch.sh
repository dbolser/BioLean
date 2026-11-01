#!/bin/bash
# usage: epmc_fetch.sh PMID...; Europe PMC core record (with abstract) per PMID into /tmp/biolean-02b/dl/epmc2/<pmid>.json
for p in "$@"; do
  f="/tmp/biolean-02b/dl/epmc2/$p.json"
  [ -s "$f" ] && continue
  curl -s -m 40 -G "https://www.ebi.ac.uk/europepmc/webservices/rest/search" --data-urlencode "query=EXT_ID:$p AND SRC:MED" --data-urlencode "format=json" --data-urlencode "resultType=core" -o "$f"
done
