#!/bin/sh
# Bounded publisher tests: fake cloud command, real local pinned starter bytes.
set -eu
TMP=$(mktemp -d /tmp/observation-publish-test.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM
mkdir -p "$TMP/bin" "$TMP/remote"
cat > "$TMP/bin/gcloud" <<'FAKE'
#!/bin/sh
set -eu
if [ "$1" = auth ]; then echo fixture-account; exit 0; fi
printf '%s\n' "$@" > "$PUBLISH_TEST_LOG"
last=
count=0
for arg do
    case "$arg" in */[a-f0-9]*.fits|*/[a-f0-9]*.png|*/[a-f0-9]*.jpg|*/[a-f0-9]*.json|*/[a-f0-9]*.md|*/[a-f0-9]*.csv)
        [ -f "$arg" ] || exit 91
        expected=${arg##*/}; expected=${expected%.*}
        actual=$(shasum -a 256 < "$arg" | awk '{print $1}')
        [ "$actual" = "$expected" ] || exit 92
        cp "$arg" "$PUBLISH_TEST_STORE/${arg##*/}"
        count=$((count+1)) ;;
    esac
    last=$arg
done
printf '%s\n' "$count" > "$PUBLISH_TEST_COUNT"
[ "$last" = gs://stapledons-voyage-assets/observations/ ] || exit 93
FAKE
chmod +x "$TMP/bin/gcloud"
passed=0
failed=0
check() {
    if "$@"; then passed=$((passed+1)); else failed=$((failed+1)); echo "FAIL publisher: $*"; fi
}
run() {
    PUBLISH_TEST_STORE="$TMP/remote" PUBLISH_TEST_LOG="$TMP/cloud.log" PUBLISH_TEST_COUNT="$TMP/count" OBSERVATION_PUBLISH_SCRATCH="$TMP/scratch" PATH="$TMP/bin:$PATH" sh tools/observation_publish.sh "${1:-publish}" > "$TMP/run.log" 2>&1
}
if run; then passed=$((passed+1)); else failed=$((failed+1));cat "$TMP/run.log";fi
check test -f "$TMP/cloud.log"
if [ -f "$TMP/cloud.log" ]; then
    check grep -qx -- --no-clobber "$TMP/cloud.log"
    check grep -qx -- '--cache-control=public, max-age=31536000, immutable' "$TMP/cloud.log"
    check test "$(grep -cx storage "$TMP/cloud.log")" = 1
    check test "$(grep -cx cp "$TMP/cloud.log")" = 1
    check test "$(cat "$TMP/count")" -ge 190
    for ext in fits png jpg json md csv; do check grep -Eq "[a-f0-9]{64}\.$ext$" "$TMP/cloud.log"; done
    for entry in science:1 prepared:2 outreach:3 index:4 tile:176 metadata:7; do
        role=${entry%:*};want=${entry#*:}
        check test "$(awk -F '\t' -v role="$role" '$3==role {n++} END {print n+0}' "$TMP/scratch/published-pins.tsv")" = "$want"
    done
fi
# Simulate a passing outer make gate so this independently tests the uploader's
# own checksum barrier. Neither this fake nor gcloud can contact a network.
cat > "$TMP/bin/make" <<'FAKE'
#!/bin/sh
[ "$1" = observation-assets-check ]
FAKE
chmod +x "$TMP/bin/make"
jq '.plates[0].source_sha256="0000000000000000000000000000000000000000000000000000000000000000"' data/observations/euclid_dr1/manifest.json > "$TMP/bad.json"
rm -f "$TMP/cloud.log"
if OBSERVATION_MANIFEST="$TMP/bad.json" run; then failed=$((failed+1));echo 'FAIL publisher: bad checksum accepted';else passed=$((passed+1));fi
check test ! -f "$TMP/cloud.log"
jq '.plates[0].levels[0].path="res://data/raw/observations/../unexpected.png"' data/observations/euclid_dr1/manifest.json > "$TMP/traversal.json"
if OBSERVATION_MANIFEST="$TMP/traversal.json" run; then failed=$((failed+1));echo 'FAIL publisher: parent traversal accepted';else passed=$((passed+1));fi
check test ! -f "$TMP/cloud.log"
unset OBSERVATION_MANIFEST
cat > "$TMP/bin/curl" <<'FAKE'
#!/bin/sh
set -eu
out=
url=
while [ "$#" -gt 0 ]; do
    case "$1" in -o) shift;out=$1 ;; https://*) url=$1 ;; esac
    shift
done
[ -n "$out" ] && [ -n "$url" ]
cp "$PUBLISH_TEST_STORE/${url##*/}" "$out"
FAKE
chmod +x "$TMP/bin/curl"
if run verify; then passed=$((passed+1));else failed=$((failed+1));cat "$TMP/run.log";fi
check test "$(wc -l < "$TMP/scratch/verified-samples.tsv" | tr -d ' ')" = 12
check test ! -f "$TMP/cloud.log"
credit_sum=$(shasum -a 256 < data/observations/euclid_dr1/credits.md | awk '{print $1}')
printf 'corrupt remote bytes' > "$TMP/remote/$credit_sum.md"
if run verify; then failed=$((failed+1));echo 'FAIL publisher: corrupt anonymous sample accepted';else passed=$((passed+1));fi
check test ! -f "$TMP/cloud.log"
echo "observation-publish-test: $passed passed, $failed failures"
[ "$failed" = 0 ]
