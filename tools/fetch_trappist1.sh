#!/bin/sh
# TRAPPIST-1 planets b-h from the NASA Exoplanet Archive `ps` table (every
# published parameter set, default first), as a raw snapshot. The committed
# snapshot data/planets/trappist1_ps.csv (retrieved 2026-10-07) is pinned by
# sha256 in data/planets/EXOPLANETS.SHA256 and transcribed, with citations, into
# sim/data/trappist1.ail. The archive is living: a re-fetch that differs is a
# data update (new rows or rowupdate dates), reviewed, re-pinned and re-transcribed.
#   tools/fetch_trappist1.sh [out.csv]     fetch (default: a scratch file) and diff against the pin
#   tools/fetch_trappist1.sh --verify      check the committed snapshot against its pin (no network)
set -eu
cd "$(dirname "$0")/.."
PIN=data/planets/EXOPLANETS.SHA256
SNAP=data/planets/trappist1_ps.csv
if [ "${1:-}" = "--verify" ]; then
  grep " $SNAP\$" "$PIN" | shasum -a 256 -c -
  exit $?
fi
OUT=${1:-${TMPDIR:-/tmp}/trappist1_ps.csv}
COLS="pl_name,pl_letter,default_flag,pl_refname,pl_orbper,pl_orbpererr1,pl_orbsmax,pl_orbsmaxerr1,pl_rade,pl_radeerr1,pl_masse,pl_masseerr1,pl_orbincl,pl_orbinclerr1,pl_tranmid,pl_tranmiderr1,pl_orbeccen,pl_imppar,st_rad,st_teff,st_lum,st_mass,sy_dist,rowupdate"
Q="select+${COLS}+from+ps+where+hostname='TRAPPIST-1'+order+by+pl_letter,default_flag+desc"
curl -sL --fail -o "$OUT" "https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=${Q}&format=csv"
echo "fetched $(($(wc -l < "$OUT") - 1)) rows -> $OUT"
if cmp -s "$OUT" "$SNAP"; then echo "identical to the pinned snapshot"; else echo "DIFFERS from the pinned snapshot $SNAP (review, re-pin, re-transcribe)"; fi
