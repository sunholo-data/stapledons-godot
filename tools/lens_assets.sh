#!/bin/sh
# Schwarzschild lens tables (M3.2 of R1-M3-BLACK-HOLES; D-18, D-53): two 4 MiB float32 tables too
# large for git live content-addressed in the public bucket, pinned in data/lens/SHA256SUMS.
#
#   tools/lens_assets.sh verify    check every pinned file against data/lens/SHA256SUMS
#   tools/lens_assets.sh fetch     download missing or stale pinned files (anonymous HTTPS); exit 1 if
#                                  any is absent there (make lens-assets then regenerates)
#   tools/lens_assets.sh regen     regenerate both tables on the AILANG VM (sim/tools/lens_lut_main.ail),
#                                  sharded over LENS_JOBS processes; the bytes never depend on the sharding
#   tools/lens_assets.sh publish   maintainers (gcloud auth): upload every pinned file; never overwrites
#
# Layout: gs://$LENS_BUCKET/lens/<sha256>.<ext>, the sha256 being the pin. Pins file format:
# "<sha256> table <path>". The headers (lens_*.json) are small and committed; the bins are not.
set -eu

SUMS=data/lens/SHA256SUMS
OUT=data/lens
BUCKET="${LENS_BUCKET:-stapledons-voyage-assets}"
BASE="${LENS_BASE_URL:-https://storage.googleapis.com/$BUCKET}"
AILANG="${AILANG:-ailang}"
SHARDS="${LENS_SHARDS:-32}"
JOBS="${LENS_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}"

pins() { grep -E '^[0-9a-f]{64} +table ' "$SUMS"; }
digest() { shasum -a 256 "$1" | cut -d' ' -f1; }
object() { echo "lens/$1.${2##*.}"; }

verify() {
    bad=0
    while read -r sum kind path; do
        if [ -f "$path" ] && [ "$(digest "$path")" = "$sum" ]; then echo "  ok       $path"
        else echo "  MISMATCH $path (want $sum)"; bad=$((bad + 1)); fi
    done <<PINS
$(pins)
PINS
    [ "$bad" -eq 0 ] && echo "lens-assets: tables match $SUMS"
}

fetch() {
    missing=0
    while read -r sum kind path; do
        if [ -f "$path" ] && [ "$(digest "$path")" = "$sum" ]; then echo "  have     $path"; continue; fi
        url="$BASE/$(object "$sum" "$path")"
        if ! curl -fsSL --max-time "${CURL_MAX_TIME:-300}" -o "$path.part" "$url"; then
            rm -f "$path.part"; echo "  absent   $url ($path)"; missing=$((missing + 1)); continue
        fi
        if [ "$(digest "$path.part")" != "$sum" ]; then
            rm -f "$path.part"; echo "  CORRUPT  $url (sha256 differs from the pin)"; missing=$((missing + 1)); continue
        fi
        mv "$path.part" "$path"; echo "  fetched  $path  <- $url"
    done <<PINS
$(pins)
PINS
    [ "$missing" -eq 0 ] || { echo "lens-assets: $missing pinned table file(s) not fetched from the bucket"; return 1; }
}

regen() {
    mkdir -p "$OUT"
    run="$AILANG run --quiet --bytecode --caps IO,FS --package-dir sim"
    ver=$("$AILANG" --version | sed -n 's/^AILANG \(v[^ ]*\).*/\1/p')
    start=$(date +%s)
    echo "lens-lut: $SHARDS shards per table, $JOBS at a time, ailang $ver"
    # inv shards first: they are uniform (~2 s a row); fwd rows vary (5-7 s a row)
    for t in inv fwd; do k=0; while [ "$k" -lt "$SHARDS" ]; do echo "$t $k"; k=$((k + 1)); done; done \
      | xargs -P "$JOBS" -n 2 sh -c "$run --entry shard --args-json \"{\\\"table\\\":\\\"\$0\\\",\\\"k\\\":\$1,\\\"shards\\\":$SHARDS,\\\"out\\\":\\\"$OUT\\\"}\" sim/tools/lens_lut_main.ail >/dev/null || { echo \"lens-lut: shard \$0 \$1 failed\" >&2; exit 255; }"
    for t in fwd inv; do
        $run --entry assemble --args-json "{\"table\":\"$t\",\"shards\":$SHARDS,\"out\":\"$OUT\",\"lock\":\"sim/ailang.lock\",\"ailang\":\"$ver\"}" sim/tools/lens_lut_main.ail
    done
    echo "lens-lut: generated in $(( $(date +%s) - start )) s (wall, $JOBS parallel jobs)"
}

publish() {
    command -v gcloud >/dev/null || { echo "lens-publish: needs gcloud (maintainers only)" >&2; exit 1; }
    pins | while read -r sum kind path; do
        if ! [ -f "$path" ] || [ "$(digest "$path")" != "$sum" ]; then
            echo "lens-publish: $path missing or not matching its pin; run make lens-lut first" >&2; exit 1
        fi
        obj="gs://$BUCKET/$(object "$sum" "$path")"
        if gcloud storage objects describe "$obj" >/dev/null 2>&1; then echo "  exists   $obj"; continue; fi
        gcloud storage cp --no-clobber --cache-control="public, max-age=31536000, immutable" "$path" "$obj"
        echo "  uploaded $obj  ($path)"
    done
    echo "lens-publish: done; public base $BASE/lens/"
}

case "${1:-}" in
    verify) verify ;;
    fetch) fetch ;;
    regen) regen ;;
    publish) publish ;;
    *) echo "usage: $0 verify|fetch|regen|publish" >&2; exit 2 ;;
esac
