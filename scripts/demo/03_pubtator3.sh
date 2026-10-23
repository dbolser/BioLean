#!/usr/bin/env bash
# PubTator3 relation rows (task 5) for GLP1R (2740), DPP4 (1803), GCG (2641) and the resolved drug MeSH IDs.
# MeSH: semaglutide D000099194 (older SCR C000592913), tirzepatide D000098860, liraglutide D000069450,
#       exenatide D000077270, sitagliptin D000068900.
# Writes data/demo/pubtator3_relations.tsv (with header).  ~2 min.
set -euo pipefail
SRC=/home/danbolser/Work/IUK-IPF/data/sources/pubtator3/2026-10-06/relation2pubtator3.gz
OUT=/home/danbolser/Build/BioLean/data/demo/pubtator3_relations.tsv
{
  printf 'pmid\trelation\tconcept1\tconcept2\n'
  zcat "$SRC" | grep -E $'\t(Gene\\|(2740|1803|2641)|Chemical\\|MESH:(D000099194|C000592913|D000098860|D000069450|D000077270|D000068900))(\t|$)'
} > "$OUT"
wc -l "$OUT"
