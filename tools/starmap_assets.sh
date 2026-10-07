#!/bin/sh
# Starmap tier assets (D-18, starmap-large-tier-and-reach.md L1): tiers too large for git (the large
# tier, 331,311 GCNS rows: 7.9 MB bin + 7.2 MB sidecar) live content-addressed in the public bucket.
#
#   tools/starmap_assets.sh verify            check every pinned file against data/starmap/SHA256SUMS
#   tools/starmap_assets.sh fetch             download missing or stale pinned files (anonymous HTTPS);
#                                             exit 1 if any is absent there (make starmap-assets then
#                                             rebuilds from the pinned inputs)
#   tools/starmap_assets.sh publish           maintainers (gcloud auth): upload every pinned file; never
#                                             overwrites (objects are immutable)
#
# Layout: gs://$SKY_BUCKET/starmap/<sha256>.<ext>, the sha256 being the pin. Format of the pins file:
# "<sha256> tier <path>". The build is deterministic (make catalogue TIER=large; VM = interpreter), so a
# rebuild from the pinned inputs reproduces the pinned bytes.
set -eu

SUMS=data/starmap/SHA256SUMS
BUCKET="${SKY_BUCKET:-stapledons-voyage-assets}"
BASE="${SKY_BASE_URL:-https://storage.googleapis.com/$BUCKET}"

pins() { grep -E '^[0-9a-f]{64} +tier ' "$SUMS"; }
digest() { shasum -a 256 "$1" | cut -d' ' -f1; }
object() { echo "starmap/$1.${2##*.}"; }

verify() {
    bad=0
    while read -r sum kind path; do
        if [ -f "$path" ] && [ "$(digest "$path")" = "$sum" ]; then echo "  ok       $path"
        else echo "  MISMATCH $path (want $sum)"; bad=$((bad + 1)); fi
    done <<PINS
$(pins)
PINS
    [ "$bad" -eq 0 ] && echo "starmap-assets: tiers match $SUMS"
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
    [ "$missing" -eq 0 ] || { echo "starmap-assets: $missing pinned tier file(s) not fetched from the bucket"; return 1; }
}

publish() {
    command -v gcloud >/dev/null || { echo "starmap-publish: needs gcloud (maintainers only)" >&2; exit 1; }
    pins | while read -r sum kind path; do
        if ! [ -f "$path" ] || [ "$(digest "$path")" != "$sum" ]; then
            echo "starmap-publish: $path missing or not matching its pin; build it first (make catalogue TIER=large)" >&2; exit 1
        fi
        obj="gs://$BUCKET/$(object "$sum" "$path")"
        if gcloud storage objects describe "$obj" >/dev/null 2>&1; then echo "  exists   $obj"; continue; fi
        gcloud storage cp --no-clobber --cache-control="public, max-age=31536000, immutable" "$path" "$obj"
        echo "  uploaded $obj  ($path)"
    done
    echo "starmap-publish: done; public base $BASE/starmap/"
}

case "${1:-}" in
    verify) verify ;;
    fetch) fetch ;;
    publish) publish ;;
    *) echo "usage: $0 verify|fetch|publish" >&2; exit 2 ;;
esac
