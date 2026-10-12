#!/bin/sh
# Sky background assets (M1.4d, D-18): content-addressed cache in a public GCS bucket.
#
#   tools/sky_assets.sh verify  inputs|textures|all [re]  check files against data/sky/SHA256SUMS
#   tools/sky_assets.sh fetch   inputs|textures [re]  download missing pinned files from the bucket
#                                                     (anonymous HTTPS, no credentials); only paths
#                                                     matching the extended regex re, if given. Every
#                                                     pin is tried; exit 1 if any is absent there, so
#                                                     make falls back for just the missing files
#   tools/sky_assets.sh publish                       maintainer only (gcloud auth): upload every pinned
#                                                     data/raw file to the bucket; never overwrites
#
# Layout: gs://$SKY_BUCKET/sky/<sha256>.<ext>, the sha256 being the pin in data/sky/SHA256SUMS.
# Objects are immutable (content-addressed, uploaded --no-clobber, Cache-Control immutable).
# hip_v7.tsv is pinned on its data rows (VizieR stamps the query date into the "#" header), so the
# cached object is the header-less rows file; sim/tools/destar.ail skips non-data lines either way.
# Bucket setup: infra/gcp/setup.sh.
set -eu

SUMS=data/sky/SHA256SUMS
BUCKET="${SKY_BUCKET:-stapledons-voyage-assets}"
BASE="${SKY_BASE_URL:-https://storage.googleapis.com/$BUCKET}"
HIP=data/raw/hip_v7.tsv

# pins <kind regex>: "<sha256> <kind> <path>" lines
pins() { grep -E "^[0-9a-f]{64} +($1) " "$SUMS"; }

kinds() {
    case "$1" in
        inputs) echo input ;;
        textures) echo texture ;;
        all) echo 'input|texture' ;;
        *) echo "usage: $0 verify|fetch inputs|textures|all" >&2; exit 2 ;;
    esac
}

# digest <file> <pinned path>: the pinned digest of a file standing for <pinned path>
digest() {
    if [ "$2" = "$HIP" ]; then grep -v '^#' "$1" | shasum -a 256 | cut -d' ' -f1
    else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

object() { echo "sky/$1.${2##*.}"; }

verify() {
    pins "$(kinds "$1")" | awk -v re="${2:-.}" '$3 ~ re' | while read -r sum kind path; do
        if [ -f "$path" ] && [ "$(digest "$path" "$path")" = "$sum" ]; then echo "  ok       $path"
        else echo "  MISMATCH $path (want $sum)"; exit 1; fi
    done
    echo "sky-verify: $1 match $SUMS"
}

fetch() {
    # A here-document, not a pipe, keeps the loop in this shell so the missing count survives it.
    missing=0
    while read -r sum kind path; do
        case "$path" in data/raw/*) ;; *) continue ;; esac   # committed files (stars.json) come from git
        if [ -f "$path" ] && [ "$(digest "$path" "$path")" = "$sum" ]; then echo "  have     $path"; continue; fi
        mkdir -p "$(dirname "$path")"
        url="$BASE/$(object "$sum" "$path")"
        if ! curl -fsSL --max-time "${CURL_MAX_TIME:-900}" -o "$path.part" "$url"; then
            rm -f "$path.part"; echo "  absent   $url ($path)"; missing=$((missing + 1)); continue
        fi
        if [ "$(digest "$path.part" "$path")" != "$sum" ]; then
            rm -f "$path.part"; echo "  CORRUPT  $url (sha256 differs from the pin)"; missing=$((missing + 1)); continue
        fi
        mv "$path.part" "$path"; echo "  fetched  $path  <- $url"
    done <<PINS
$(pins "$(kinds "$1")" | awk -v re="${2:-.}" '$3 ~ re')
PINS
    [ "$missing" -eq 0 ] || { echo "sky-assets: $missing pinned file(s) not fetched from the bucket"; return 1; }
}

publish() {
    command -v gcloud >/dev/null || { echo "sky-publish: needs gcloud (maintainers only)" >&2; exit 1; }
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    pins 'input|texture' | while read -r sum kind path; do
        case "$path" in data/raw/*) ;; *) continue ;; esac
        if ! [ -f "$path" ] || [ "$(digest "$path" "$path")" != "$sum" ]; then
            echo "sky-publish: $path missing or not matching its pin; run make sky-assets first" >&2; exit 1
        fi
        src="$path"
        if [ "$path" = "$HIP" ]; then src="$tmp/hip_rows.tsv"; grep -v '^#' "$path" > "$src"; fi
        obj="gs://$BUCKET/$(object "$sum" "$path")"
        if gcloud storage objects describe "$obj" >/dev/null 2>&1; then echo "  exists   $obj"; continue; fi
        gcloud storage cp --no-clobber --cache-control="public, max-age=31536000, immutable" "$src" "$obj"
        echo "  uploaded $obj  ($path)"
    done
    echo "sky-publish: done; public base $BASE/sky/"
}

case "${1:-}" in
    verify) verify "${2:-all}" "${3:-.}" ;;
    fetch) fetch "${2:-textures}" "${3:-.}" ;;
    publish) publish ;;
    *) echo "usage: $0 verify|fetch inputs|textures|all | publish" >&2; exit 2 ;;
esac
