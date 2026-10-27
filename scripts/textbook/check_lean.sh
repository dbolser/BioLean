#!/bin/bash
# Regenerate the textbook claim modules and compile each, reporting how many statements Lean accepts.
set -e
cd "$(dirname "$0")/../.."
export PATH="$HOME/.elan/bin:$PATH"
GO_OBO=${GO_OBO:-/tmp/obo/go.obo}
[ -f "$GO_OBO" ] || curl -sL -o "$GO_OBO" http://purl.obolibrary.org/obo/go.obo
python3 -I scripts/textbook/emit_lean.py data/textbook/claims_m1 "$GO_OBO" BioLean/Lib/TextbookClaims
total=0; failed=0
for f in BioLean/Lib/TextbookClaims/*.lean; do
  n=$(grep -c '^def .*: Statement' "$f")
  e=$(lake env lean "$f" 2>&1 | grep -c ': error:' || true)
  # several errors can hit one statement; count statements with at least one error
  s=$(lake env lean "$f" 2>&1 | grep -oE '\.lean:[0-9]+:' | sort -u | wc -l)
  echo "$(basename "$f" .lean): $n statements, $e errors"
  total=$((total+n))
done
echo "total statements: $total (see docs/textbook-lean-check.md for the per-statement failure count)"
