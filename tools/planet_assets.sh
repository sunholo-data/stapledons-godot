#!/bin/sh
# Planet albedo textures (M5.2a, D-18 pattern): content-addressed in the public GCS bucket.
#
#   tools/planet_assets.sh verify    check assets/planets/* against data/planets/SHA256SUMS
#   tools/planet_assets.sh fetch     download missing pinned files: the bucket first (anonymous HTTPS),
#                                    else the original source (the SOURCE line of the pins); every
#                                    download must match its sha256 pin or it is discarded
#   tools/planet_assets.sh publish   maintainer only (gcloud auth): upload every pinned file to
#                                    gs://$BUCKET/planets/<sha256>.<ext>; never overwrites
#
# The textures live in assets/planets/ (gitignored, with a .gdignore so the editor does not import
# them; planets/system_view.gd loads them with Image.load_from_file). Bucket setup: infra/gcp/setup.sh.
set -eu

SUMS=data/planets/SHA256SUMS
DIR=assets/planets
BUCKET="${PLANET_BUCKET:-stapledons-voyage-assets}"
BASE="${PLANET_BASE_URL:-https://storage.googleapis.com/$BUCKET}"
SOURCE="${PLANET_SOURCE_URL:-$(sed -n 's/^# SOURCE //p' "$SUMS")}"

pins() { grep -E '^[0-9a-f]{64} +texture ' "$SUMS"; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
object() { echo "planets/$1.${2##*.}"; }

verify() {
    pins | while read -r sum kind path; do
        if [ -f "$path" ] && [ "$(sha "$path")" = "$sum" ]; then echo "  ok       $path"
        else echo "  MISMATCH $path (want $sum)"; exit 1; fi
    done
    echo "planet-verify: $(pins | wc -l | tr -d ' ') textures match $SUMS"
}

# get <url> <path> <sum>: download to path.part, keep it only if the sha256 matches
get() {
    curl -fsSL --max-time "${CURL_MAX_TIME:-300}" -o "$2.part" "$1" 2>/dev/null || { rm -f "$2.part"; return 1; }
    if [ "$(sha "$2.part")" != "$3" ]; then rm -f "$2.part"; echo "  CORRUPT  $1 (sha256 differs from the pin)"; return 1; fi
    mv "$2.part" "$2"
}

fetch() {
    mkdir -p "$DIR"
    [ -f "$DIR/.gdignore" ] || : > "$DIR/.gdignore"
    missing=0
    while read -r sum kind path; do
        if [ -f "$path" ] && [ "$(sha "$path")" = "$sum" ]; then echo "  have     $path"; continue; fi
        if get "$BASE/$(object "$sum" "$path")" "$path" "$sum"; then echo "  fetched  $path  <- bucket"
        elif get "$SOURCE$(basename "$path")" "$path" "$sum"; then echo "  fetched  $path  <- $SOURCE (not in the bucket yet: make planet-publish)"
        else echo "  absent   $path (bucket and source)"; missing=$((missing + 1)); fi
    done <<PINS
$(pins)
PINS
    [ "$missing" -eq 0 ] || { echo "planet-assets: $missing pinned texture(s) not fetched"; return 1; }
}

publish() {
    command -v gcloud >/dev/null || { echo "planet-publish: needs gcloud (maintainers only)" >&2; exit 1; }
    verify >/dev/null || { echo "planet-publish: textures missing or not matching their pins; run make planet-assets first" >&2; exit 1; }
    pins | while read -r sum kind path; do
        obj="gs://$BUCKET/$(object "$sum" "$path")"
        if gcloud storage objects describe "$obj" >/dev/null 2>&1; then echo "  exists   $obj"; continue; fi
        gcloud storage cp --no-clobber --cache-control="public, max-age=31536000, immutable" "$path" "$obj"
        echo "  uploaded $obj  ($path)"
    done
    echo "planet-publish: done; public base $BASE/planets/"
}

case "${1:-}" in
    verify) verify ;;
    fetch) fetch ;;
    publish) publish ;;
    *) echo "usage: $0 verify|fetch|publish" >&2; exit 2 ;;
esac
