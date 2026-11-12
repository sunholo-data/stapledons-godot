#!/bin/sh
# Immutable R3 observation transport. Run from the repository root.
# publish: validate/stage all bytes, one no-clobber batch upload, no aliases.
# verify: anonymous bounded samples of every asset class and all metadata.
set -eu
MANIFEST=${OBSERVATION_MANIFEST:-data/observations/euclid_dr1/manifest.json}
BUCKET=${OBSERVATION_BUCKET:-stapledons-voyage-assets}
BASE=${OBSERVATION_BASE_URL:-https://storage.googleapis.com/$BUCKET}
SCRATCH=${OBSERVATION_PUBLISH_SCRATCH:-.godot/tmp/observations/publish}
MODE=${1:-}
case "$MODE" in publish|verify) ;; *) echo "usage: $0 publish|verify" >&2;exit 2 ;; esac
fail() { echo "observation-publish: $*" >&2;exit 1; }
command -v jq >/dev/null || fail 'jq required'
mkdir -p "$SCRATCH"
STAGE=$(mktemp -d "$SCRATCH/stage.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT INT TERM
mkdir "$STAGE/objects"
PINS="$STAGE/pins.tsv"
: > "$PINS"
digest() { shasum -a 256 < "$1" | awk '{print $1}'; }
local_path() {
    case "$1" in res://data/raw/observations/*) ;; *) fail "unexpected asset path: $1" ;; esac
    case "$1" in *..*) fail 'parent traversal rejected' ;; esac
    printf '%s\n' "$1" | grep -Eq '^res://[A-Za-z0-9_./-]+$' || fail 'unsafe asset path'
    printf '%s\n' "${1#res://}"
}
pin() {
    sum=$1 role=$2 path=$3
    printf '%s\n' "$sum" | grep -Eq '^[a-f0-9]{64}$' || fail 'invalid SHA256 pin'
    [ -f "$path" ] || fail "missing bytes: $path"
    [ "$(digest "$path")" = "$sum" ] || fail "checksum mismatch: $path"
    ext=${path##*.}
    case "$ext" in fits|png|jpg|json|md|csv) ;; *) fail "unsupported asset extension: $ext" ;; esac
    target="$STAGE/objects/$sum.$ext"
    # Copies freeze the validated upload bytes even if another build edits inputs.
    if [ ! -f "$target" ]; then cp "$path" "$target";fi
    [ "$(digest "$target")" = "$sum" ] || fail 'staging checksum mismatch'
    printf '%s\t%s\t%s\t%s\n' "$sum" "$ext" "$role" "$path" >> "$PINS"
}

# The established decoder/tile verifier runs before staging and before cloud auth.
[ -f "$MANIFEST" ] || fail "manifest unavailable"
manifest_sum=$(digest "$MANIFEST")
if ! make observation-assets-check > "$SCRATCH/assets-check.log" 2>&1; then
    cat "$SCRATCH/assets-check.log"
    fail 'asset verification failed; nothing uploaded'
fi
[ "$(digest "$MANIFEST")" = "$manifest_sum" ] || fail "manifest changed during validation"
cp "$MANIFEST" "$STAGE/manifest.json"
[ "$(digest "$STAGE/manifest.json")" = "$manifest_sum" ] || fail "manifest snapshot changed"
SNAPSHOT="$STAGE/manifest.json"
jq -e '.format_version==1 and (.plates|length>0) and all(.plates[];
    (.id|test("^[A-Za-z0-9_-]+$")) and (.registered|type=="boolean") and
    (.licence|type=="string" and length>0) and (.credit|type=="string" and length>0))' "$SNAPSHOT" >/dev/null || fail 'invalid manifest/rights'
jq -r '.plates[] | select(.registered) | [.source_sha256,.id] | @tsv' "$SNAPSHOT" |
while IFS="$(printf '\t')" read -r sum id; do pin "$sum" science "data/raw/observations/$id/source.fits";done
jq -r '.plates[] | .registered as $r | .levels[] | [.sha256,(if $r then "prepared" else "outreach" end),.path] | @tsv' "$SNAPSHOT" |
while IFS="$(printf '\t')" read -r sum role ref; do path=$(local_path "$ref");pin "$sum" "$role" "$path";done
jq -r '.plates[].tiles | [.sha256,.path] | @tsv' "$SNAPSHOT" |
while IFS="$(printf '\t')" read -r sum ref; do
    path=$(local_path "$ref")
    pin "$sum" index "$path"
    jq -r '.levels[].tiles[] | [.sha256,.path] | @tsv' "$path" |
    while IFS="$(printf '\t')" read -r tile_sum tile_ref; do tile_path=$(local_path "$tile_ref");pin "$tile_sum" tile "$tile_path";done
done
# Exact reviewed source/provenance metadata, never editor-generated translations.
for path in "$MANIFEST" data/observations/euclid_dr1/credits.md data/observations/euclid_dr1/objects.json data/observations/euclid_dr1/footprints.json data/observations/euclid_dr1/registration-evidence.json data/observations/euclid_dr1/sources.csv data/observations/euclid_dr1/product.csv; do
    [ -f "$path" ] || fail "missing reviewed metadata: $path"
    if [ "$path" = "$MANIFEST" ]; then sum=$manifest_sum;else sum=$(digest "$path");fi
    pin "$sum" metadata "$path"
done
# One content-addressed object can have several local references.
LC_ALL=C sort -u "$PINS" > "$STAGE/sorted.tsv"
mv "$STAGE/sorted.tsv" "$PINS"
count=0
for file in "$STAGE/objects/"*; do
    name=${file##*/};sum=${name%.*}
    [ "$(digest "$file")" = "$sum" ] || fail 'final upload checksum mismatch'
    count=$((count+1))
done
[ "$count" -gt 0 ] || fail 'empty publication set'
if [ "$MODE" = publish ]; then
    command -v gcloud >/dev/null || fail 'gcloud required (maintainers only)'
    # Do not print account names, credentials or tokens.
    account=$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null) || fail 'cloud authentication unavailable'
    [ -n "$account" ] || fail 'cloud authentication unavailable'
    gcloud storage cp --no-clobber --cache-control='public, max-age=31536000, immutable' "$STAGE/objects/"* "gs://$BUCKET/observations/"
    cp "$PINS" "$SCRATCH/published-pins.tsv"
    echo "observation-publish: $count immutable objects, 0 failures"
else
    # All rights/provenance metadata plus one file from every science/image class.
    awk -F '\t' '$3=="metadata" || !seen[$3]++' "$PINS" > "$STAGE/samples.tsv"
    samples=0
    while IFS="$(printf '\t')" read -r sum ext role path; do
        url="$BASE/observations/$sum.$ext"
        curl -fsSL --connect-timeout 10 --max-time 60 --retry 2 --retry-max-time 130 --max-filesize 33554432 -o "$STAGE/sample" "$url" || fail "anonymous sample unavailable: $role"
        [ "$(digest "$STAGE/sample")" = "$sum" ] || fail "anonymous sample checksum mismatch: $role"
        samples=$((samples+1))
    done < "$STAGE/samples.tsv"
    cp "$STAGE/samples.tsv" "$SCRATCH/verified-samples.tsv"
    echo "observation-publish-verify: $samples anonymous samples, 0 failures"
fi
