#!/bin/sh
# Hermetic test of tools/sky_assets.sh fetch (M1.2c, T4 evaluator finding): a file:// fake bucket,
# a fake SHA256SUMS, no network. Checks that
#   1. the real data/sky/SHA256SUMS pins every catalogue input (cns5.dat included: the quick tier
#      and catalogue-verify read it, and catalogue_main.ail records its sha256 in the sidecar);
#   2. fetch keeps going past an object the bucket lacks, fetches the rest, then exits 1, so
#      make's per-file fallback (download_stars.sh / extract.ail) only has the absent files to make;
#   3. the optional path filter fetches only the matching pins;
#   4. a corrupt object is refused and leaves no file.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT=$ROOT/tools/sky_assets.sh
fail() { echo "test_sky_assets: FAIL $*"; exit 1; }

for p in data/raw/cns5.dat data/raw/cns5.csv data/raw/table1c.dat.gz data/raw/gcns.csv; do
  grep -Eq "^[0-9a-f]{64} +input +$p\$" "$ROOT/data/sky/SHA256SUMS" || fail "SHA256SUMS does not pin $p"
done
grep -q '^7e8c1a2ce4a2afcd70cdf40340c9685b1ec90e8e5085a81812dfa98c5c8adbbf input data/raw/cns5.dat$' \
  "$ROOT/data/sky/SHA256SUMS" || fail "cns5.dat pin is not the VizieR J/A+A/670/A19 bytes"

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/w/data/sky" "$T/bucket/sky"
printf 'alpha\n' > "$T/a.dat"; printf 'beta\n' > "$T/b.csv"; printf 'gamma\n' > "$T/c.dat"
sa=$(shasum -a 256 "$T/a.dat" | cut -d' ' -f1); sb=$(shasum -a 256 "$T/b.csv" | cut -d' ' -f1)
sc=$(shasum -a 256 "$T/c.dat" | cut -d' ' -f1)
cat > "$T/w/data/sky/SHA256SUMS" <<PINS
# fake pins
$sa input data/raw/a.dat
$sb input data/raw/b.csv
$sc input data/raw/c.dat
PINS
cp "$T/a.dat" "$T/bucket/sky/$sa.dat"           # b.csv absent from the bucket
cp "$T/c.dat" "$T/bucket/sky/$sc.dat"
export SKY_BASE_URL="file://$T/bucket"

cd "$T/w"
if sh "$SCRIPT" fetch inputs > "$T/out1" 2>&1; then fail "fetch exited 0 with an object absent"; fi
grep -q 'absent .*'"$sb" "$T/out1" || fail "absent object not reported: $(cat "$T/out1")"
cmp -s data/raw/a.dat "$T/a.dat" || fail "a.dat (before the absent one) not fetched"
cmp -s data/raw/c.dat "$T/c.dat" || fail "c.dat (after the absent one) not fetched"
[ ! -e data/raw/b.csv ] && [ ! -e data/raw/b.csv.part ] || fail "absent b.csv left a file"

rm -rf data/raw
sh "$SCRIPT" fetch inputs 'c\.dat' > "$T/out2" 2>&1 || fail "filtered fetch failed: $(cat "$T/out2")"
[ -f data/raw/c.dat ] && [ ! -e data/raw/a.dat ] || fail "filter fetched the wrong set"

printf 'tampered\n' > "$T/bucket/sky/$sa.dat"
if sh "$SCRIPT" fetch inputs 'a\.dat' > "$T/out3" 2>&1; then fail "corrupt object accepted"; fi
grep -q CORRUPT "$T/out3" && [ ! -e data/raw/a.dat ] && [ ! -e data/raw/a.dat.part ] || fail "corrupt object left a file"
echo "test_sky_assets: catalogue inputs pinned (cns5.dat 7e8c1a2c...); fetch continues past absent, filters, refuses corrupt"
