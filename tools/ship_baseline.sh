#!/bin/sh
# R2-DECK-LAYOUT §D4 (the positive control survives DL1): the pinned grounded-bridge-v2 bridge
# export (ship.glb, walk_bridge.glb, manifest.json as shipped before the deck moved), fetched by
# sha256 from the public bucket into an untracked cache the demo loads through its asset_dir hook.
#
#   tools/ship_baseline.sh fetch     download any missing or mismatched file (anonymous HTTPS, curl)
#   tools/ship_baseline.sh publish   maintainer only (gcloud auth): upload the pinned files from
#                                    assets/ship_demo/ (they must still match); never overwrites
#
# Layout: gs://$SHIP_BUCKET/ship/<sha256>.<ext>; pins in art/deck-layout-v2/baseline.sha256.
# Cache: build/ship-baseline/ (gitignored, with a .gdignore so the editor never imports it).
set -eu

PINS=art/deck-layout-v2/baseline.sha256
BUCKET="${SHIP_BUCKET:-stapledons-voyage-assets}"
BASE="${SHIP_BASE_URL:-https://storage.googleapis.com/$BUCKET}"
CACHE=build/ship-baseline

sum() { shasum -a 256 "$1" | cut -d' ' -f1; }

case "${1:-}" in
fetch)
    mkdir -p "$CACHE"
    : > "$CACHE/.gdignore"
    while read -r sha name; do
        f="$CACHE/$name"
        if [ -f "$f" ] && [ "$(sum "$f")" = "$sha" ]; then echo "  ok      $name"; continue; fi
        curl -fsS --retry 3 -o "$f.part" "$BASE/ship/$sha.${name##*.}" || { echo "ship-baseline: FAIL fetch $name ($sha)" >&2; rm -f "$f.part"; exit 1; }
        [ "$(sum "$f.part")" = "$sha" ] || { echo "ship-baseline: FAIL $name sha256 mismatch" >&2; rm -f "$f.part"; exit 1; }
        mv "$f.part" "$f"; echo "  fetched $name"
    done < "$PINS"
    echo "ship-baseline: $CACHE matches $PINS"
    ;;
publish)
    while read -r sha name; do
        src="assets/ship_demo/$name"
        [ "$(sum "$src")" = "$sha" ] || { echo "ship-baseline: $src no longer matches its pin; publish from the pinned commit" >&2; exit 1; }
        gcloud storage cp --no-clobber --cache-control="public, max-age=31536000, immutable" "$src" "gs://$BUCKET/ship/$sha.${name##*.}"
    done < "$PINS"
    ;;
*) echo "usage: $0 fetch|publish" >&2; exit 2 ;;
esac
