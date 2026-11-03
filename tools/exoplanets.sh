#!/bin/sh
# W2.0 pinned data: fetch never updates the scientific snapshot implicitly.
set -eu
AILANG=${AILANG:-runtime/bin/ailang}
mode=${1:-build}
raw=data/raw/exoplanets_ps_100pc_20261102.csv
pin=data/planets/EXOPLANETS.SHA256
case "$mode" in
fetch|build|check) ;;
*) echo 'usage: tools/exoplanets.sh fetch|build|check' >&2; exit 2 ;;
esac
if [ ! -f "$raw" ]; then
  mkdir -p data/raw
  curl --fail --location --retry 2 'https://storage.googleapis.com/stapledons-voyage-assets/planets/exoplanets_ps_100pc_20261102.csv' -o "$raw"
fi
# Only check this snapshot here; existing curated pins stay owned by their tools.
awk -v path="$raw" '$2==path {print}' "$pin" | shasum -a 256 -c -
[ "$mode" != fetch ] || exit 0
out=data/planets/exoplanets.json
module=sim/data/exoplanets.ail
diffs=data/planets/exoplanets_curated_differences.txt
if [ "$mode" = check ]; then
 scratch=$(mktemp -d "${TMPDIR:-/tmp}/worlds-exoplanets.XXXXXX")
 trap 'rm -f "$scratch/exoplanets.json" "$scratch/exoplanets.ail" "$scratch/differences.txt"; rmdir "$scratch"' EXIT HUP INT TERM
 out="$scratch/exoplanets.json"
 module="$scratch/exoplanets.ail"
 diffs="$scratch/differences.txt"
fi
"$AILANG" run --quiet --bytecode --caps IO,FS --package-dir sim --entry main \
 --args-json "{\"input\":\"$raw\",\"registry\":\"data/starmap/stars.json\",\"output\":\"$out\",\"moduleOut\":\"$module\",\"differences\":\"$diffs\"}" \
 sim/tools/exoplanets.ail
if [ "$mode" = check ]; then
 cmp data/planets/exoplanets.json "$out"
 cmp sim/data/exoplanets.ail "$module"
 cmp data/planets/exoplanets_curated_differences.txt "$diffs"
 echo 'exoplanets-check: JSON, AILANG module and curated differences byte-identical'
fi
