#!/usr/bin/env bash
# Program 02b: run the closure copy (scripts/stress/closure_loops.py) in its eleven modes, with pins.
# Outputs go only to data/stress/02b/closure_<mode>/; data/search is never written.
# Usage (repo root): bash data/stress/02b/scripts/run_closure.sh [mode ...]
# Modes: orig base base_loops core signed complete signed_complete complete_isa signed_complete_isa core_strict
#        signed_complete_strict (default: all).
# 'orig' runs the ORIGINAL scripts/search/closure.py from stdin with its three output paths
# rewritten to /tmp/biolean-02b/out/orig_* (no file is copied or written in the repo), so that
# its printed report can be diffed against the copy's base mode.
set -u
cd "$(dirname "$0")/../../../.."
GO=/tmp/obo/go.obo
ARGS="data/textbook/claims_m2 $GO 4"
P=data/stress/02b/proposal_m3
X=data/stress/02b
export PYTHONHASHSEED=1
modes=("$@"); [ ${#modes[@]} -eq 0 ] && modes=(orig base base_loops core signed complete signed_complete complete_isa signed_complete_isa core_strict signed_complete_strict)
rc=0
for m in "${modes[@]}"; do
  case $m in
    orig)
      mkdir -p /tmp/biolean-02b/out
      sed -e "s#'data/search/closure.json'#'/tmp/biolean-02b/out/orig_closure.json'#" \
          -e "s#'data/search/closure_ic.json'#'/tmp/biolean-02b/out/orig_closure_ic.json'#" \
          -e "s#'data/search/derivations.json' if HUBS else 'data/search/derivations_ic.json'#'/tmp/biolean-02b/out/orig_derivations.json' if HUBS else '/tmp/biolean-02b/out/orig_derivations_ic.json'#" \
          scripts/search/closure.py > /tmp/biolean-02b/out/orig_source.txt
      if grep -n "open('data/search/[a-z_]*.json', 'w')" /tmp/biolean-02b/out/orig_source.txt; then
        echo "orig: a write path into data/search survived the rewrite; not running"; rc=1; continue
      fi
      python3 - $ARGS < /tmp/biolean-02b/out/orig_source.txt > /tmp/biolean-02b/out/orig_report.txt || rc=1
      echo "orig: $(wc -l < /tmp/biolean-02b/out/orig_report.txt) report lines in /tmp/biolean-02b/out/orig_report.txt";;
    base)
      # one run, pins included; the PIN lines are the only lines the original does not print
      python3 scripts/stress/closure_loops.py $ARGS --out=$X/closure_base --expect=$X/closure_expect_base.json > $X/closure_base/report.txt || rc=1
      if [ -f /tmp/biolean-02b/out/orig_report.txt ]; then
        if diff <(grep -v '^PIN' $X/closure_base/report.txt) /tmp/biolean-02b/out/orig_report.txt > /dev/null; then
          echo "base: printed report identical to the original's (PIN lines aside)"
        else echo "base: report DIFFERS from the original's"; rc=1; fi
        for f in closure closure_ic derivations_ic; do
          if cmp -s $X/closure_base/$f.json /tmp/biolean-02b/out/orig_$f.json; then echo "base: $f.json identical"
          else echo "base: $f.json DIFFERS"; rc=1; fi
        done
      fi;;
    base_loops)
      # the original closure with --loops but no proposal: no asserted loops, so every reading is plain or cycle;
      # used only to list the exactly reflexive effects the original drops
      python3 scripts/stress/closure_loops.py $ARGS --loops --light --out=$X/closure_base_loops > $X/closure_base_loops/report.txt || rc=1;;
    core)
      python3 scripts/stress/closure_loops.py $ARGS --proposal=$P --loops --light --out=$X/closure_core --expect=$X/closure_expect_core.json > $X/closure_core/report.txt || rc=1;;
    signed)
      python3 scripts/stress/closure_loops.py $ARGS --proposal=$P --loops --signed --light --out=$X/closure_signed --expect=$X/closure_expect_signed.json > $X/closure_signed/report.txt || rc=1;;
    complete)
      python3 scripts/stress/closure_loops.py $ARGS --complete --light --out=$X/closure_complete --expect=$X/closure_expect_complete.json > $X/closure_complete/report.txt || rc=1;;
    signed_complete)
      python3 scripts/stress/closure_loops.py $ARGS --proposal=$P --loops --signed --complete --light --out=$X/closure_signed_complete --expect=$X/closure_expect_signed_complete.json > $X/closure_signed_complete/report.txt || rc=1;;
    complete_isa)
      # both completeness fixes, plain closure (no proposal): how many effects the original misses
      python3 scripts/stress/closure_loops.py $ARGS --complete --complete-isa --light --out=$X/closure_complete_isa --expect=$X/closure_expect_complete_isa.json > $X/closure_complete_isa/report.txt || rc=1;;
    signed_complete_isa)
      python3 scripts/stress/closure_loops.py $ARGS --proposal=$P --loops --signed --complete --complete-isa --light --out=$X/closure_signed_complete_isa --expect=$X/closure_expect_signed_complete_isa.json > $X/closure_signed_complete_isa/report.txt || rc=1;;
    core_strict)
      python3 scripts/stress/closure_loops.py $ARGS --proposal=$P --loops --strict --light --out=$X/closure_core_strict --expect=$X/closure_expect_core_strict.json > $X/closure_core_strict/report.txt || rc=1;;
    signed_complete_strict)
      python3 scripts/stress/closure_loops.py $ARGS --proposal=$P --loops --signed --complete --strict --light --out=$X/closure_signed_complete_strict --expect=$X/closure_expect_signed_complete_strict.json > $X/closure_signed_complete_strict/report.txt || rc=1;;
    *) echo "unknown mode $m"; rc=1;;
  esac
  echo "mode $m done (rc so far $rc)"
done
exit $rc
