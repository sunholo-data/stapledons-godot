#!/bin/sh
# Hermetic test of tools/lens_assets.sh fetch/verify (M3.2): a file:// fake bucket, fake pins, no
# network. Checks that
#   1. the real data/lens/SHA256SUMS pins all four table files (both bins and both headers);
#   2. fetch keeps going past an object the bucket lacks, fetches the rest, then exits 1 (so make
#      lens-assets falls back to regenerating on the VM);
#   3. a corrupt object is refused and leaves no file; verify then fails loudly.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT=$ROOT/tools/lens_assets.sh
fail() { echo "test_lens_assets: FAIL $*"; exit 1; }

for p in data/lens/lens_fwd.bin data/lens/lens_fwd.json data/lens/lens_inv.bin data/lens/lens_inv.json; do
  grep -Eq "^[0-9a-f]{64} +table +$p\$" "$ROOT/data/lens/SHA256SUMS" || fail "SHA256SUMS does not pin $p"
done

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/w/data/lens" "$T/bucket/lens"
printf 'fwd\n' > "$T/f.bin"; printf 'inv\n' > "$T/i.bin"
sf=$(shasum -a 256 "$T/f.bin" | cut -d' ' -f1); si=$(shasum -a 256 "$T/i.bin" | cut -d' ' -f1)
cat > "$T/w/data/lens/SHA256SUMS" <<PINS
# fake pins
$sf table data/lens/lens_fwd.bin
$si table data/lens/lens_inv.bin
PINS
cp "$T/i.bin" "$T/bucket/lens/$si.bin"          # lens_fwd.bin absent from the bucket
export LENS_BASE_URL="file://$T/bucket"

cd "$T/w"
if sh "$SCRIPT" fetch > "$T/out1" 2>&1; then fail "fetch exited 0 with an object absent"; fi
grep -q "absent .*$sf" "$T/out1" || fail "absent object not reported: $(cat "$T/out1")"
cmp -s data/lens/lens_inv.bin "$T/i.bin" || fail "lens_inv.bin (after the absent one) not fetched"
[ ! -e data/lens/lens_fwd.bin ] && [ ! -e data/lens/lens_fwd.bin.part ] || fail "absent lens_fwd.bin left a file"
if sh "$SCRIPT" verify > "$T/out2" 2>&1; then fail "verify passed with a table missing"; fi

printf 'tampered\n' > "$T/bucket/lens/$sf.bin"
if sh "$SCRIPT" fetch > "$T/out3" 2>&1; then fail "corrupt object accepted"; fi
grep -q CORRUPT "$T/out3" && [ ! -e data/lens/lens_fwd.bin ] && [ ! -e data/lens/lens_fwd.bin.part ] || fail "corrupt object left a file"
cp "$T/f.bin" "$T/bucket/lens/$sf.bin"
sh "$SCRIPT" fetch > "$T/out4" 2>&1 && sh "$SCRIPT" verify > "$T/out5" 2>&1 || fail "fetch + verify of a good bucket failed: $(cat "$T/out4" "$T/out5")"
echo "test_lens_assets: all four tables pinned; fetch continues past absent, refuses corrupt; verify fails on a missing table"
