#!/bin/sh
# R3-TELESCOPE: pinned non-commercial observations, offline tiles and export staging.
# Run from the project root. Generated image bytes stay outside git.
set -eu
MANIFEST=${OBSERVATION_MANIFEST:-data/observations/euclid_dr1/manifest.json}
BUCKET=${OBSERVATION_BUCKET:-stapledons-voyage-assets}
BASE=${OBSERVATION_BASE_URL:-https://storage.googleapis.com/$BUCKET}
GODOT=${GODOT:-godot}
SCRATCH=${OBSERVATION_SCRATCH:-.godot/tmp/observations}
BUNDLE=${OBSERVATION_BUNDLE:-observation_bundle}
mkdir -p "$SCRATCH"

fail() { echo "observation-assets: $*" >&2; exit 1; }
hash_ok() { [ -f "$1" ] && [ "$(shasum -a 256 "$1" | cut -d' ' -f1)" = "$2" ]; }
local_path() {
    case "$1" in res://data/raw/observations/*) ;; *) fail "unexpected asset path: $1" ;; esac
    case "$1" in *..*) fail "parent traversal in asset path" ;; esac
    printf '%s\n' "${1#res://}"
}
plate() { jq -r --arg id "$1" ".plates[] | select(.id == \$id) | $2" "$MANIFEST"; }
run_gate() {
    gate_name=$1 gate_log=$2 gate_bound=$3 gate_summary=$4
    shift 4
    if sh tools/script_gate.sh "$gate_name" "$gate_log" "$gate_bound" "$gate_summary" -- "$@" > "$gate_log.gate" 2>&1; then
        echo "observation-assets: $gate_name verified"
    else
        cat "$gate_log.gate"
        return 1
    fi
}

validate_manifest() {
    command -v jq >/dev/null || fail "jq required"
    jq -e '.format_version == 1 and (.plates | type == "array" and length > 0) and all(.plates[];
      (.id | test("^[a-zA-Z0-9_-]+$")) and (.source_url | startswith("https://")) and (.licence | length > 0) and (.credit | length > 0)
      and (.registered | type == "boolean") and (if .registered then (.source_sha256 | test("^[a-f0-9]{64}$")) else true end)
      and (.levels | type == "array" and length > 0) and all(.levels[]; .width > 0 and .height > 0 and (.path | startswith("res://data/raw/observations/")) and (.sha256 | test("^[a-f0-9]{64}$")))
      and (.tiles.path | type == "string") and (.tiles.sha256 | test("^[a-f0-9]{64}$")))' "$MANIFEST" >/dev/null || fail "invalid source/rights/tile manifest"
}

# Immutable bucket object first. The only fallback is the manifest's official source.
fetch_file() {
    path=$1 sum=$2 ext=$3 official=${4:-}
    hash_ok "$path" "$sum" && return 0
    mkdir -p "$(dirname "$path")"
    for url in "$BASE/observations/$sum.$ext" "$official"; do
        [ -n "$url" ] || continue
        if curl -fsSL --connect-timeout 10 --max-time 60 --retry 2 --retry-max-time 130 --max-filesize 33554432 -o "$path.part" "$url"; then
            if hash_ok "$path.part" "$sum"; then mv "$path.part" "$path"; return 0; fi
            echo "observation-assets: corrupt response rejected for $path" >&2
        fi
        rm -f "$path.part"
    done
    return 1
}

source_for() {
    id=$1
    if [ "$(plate "$id" '.registered')" = true ]; then
        raw="data/raw/observations/$id/source.fits"
        fetch_file "$raw" "$(plate "$id" '.source_sha256')" fits "$(plate "$id" '.source_url')" || fail "source unavailable: $id"
        # Only regenerate the fixed source display levels when absent or changed.
        if ! levels_ok "$id"; then
            run_gate observation-prepare "$SCRATCH/prepare-$id.log" 180 '^observation-prepare: 2 images, 0 failures$' "$GODOT" --headless --path . --script tools/observation_prepare.gd -- "$raw" "res://data/raw/observations/$id"
        fi
    else
        ref=$(plate "$id" '.levels | max_by(.width * .height) | .path')
        sum=$(plate "$id" '.levels | max_by(.width * .height) | .sha256')
        path=$(local_path "$ref")
        fetch_file "$path" "$sum" jpg "$(plate "$id" '.source_url')" || fail "source unavailable: $id"
    fi
    levels_ok "$id" || fail "prepared source levels disagree: $id"
}

levels_ok() {
    plate "$1" '.levels[] | [.path, .sha256] | @tsv' | while IFS="$(printf '\t')" read -r ref sum; do
        path=$(local_path "$ref")
        hash_ok "$path" "$sum" || exit 1
    done
}

tiles_ok() {
    index=$1
    jq -e '.format_version == 1 and .tile_size == 512 and .gutter == 1 and (.levels | length > 0)' "$index" >/dev/null || return 1
    jq -r '.levels[].tiles[] | [.path, .sha256] | @tsv' "$index" | while IFS="$(printf '\t')" read -r ref sum; do
        path=$(local_path "$ref")
        hash_ok "$path" "$sum" || exit 1
    done
}

fetch_pack() {
    jq -r '.plates[].id' "$MANIFEST" | while IFS= read -r id; do
        source_for "$id"
        ref=$(plate "$id" '.tiles.path'); sum=$(plate "$id" '.tiles.sha256')
        index=$(local_path "$ref")
        if ! hash_ok "$index" "$sum"; then fetch_file "$index" "$sum" json || true; fi
        if hash_ok "$index" "$sum"; then
            jq -r '.levels[].tiles[] | [.path, .sha256] | @tsv' "$index" | while IFS="$(printf '\t')" read -r tile_ref tile_sum; do
                tile_path=$(local_path "$tile_ref")
                fetch_file "$tile_path" "$tile_sum" png || exit 1
            done && tiles_ok "$index" && continue
        fi
        input=$(plate "$id" '.levels | max_by(.width * .height) | .path')
        output=${ref%/tiles.json}
        run_gate observation-tiles "$SCRATCH/tiles-$id.log" 180 '^observation-tiles: [1-9][0-9]* levels, 0 failures$' "$GODOT" --headless --path . --script tools/observation_tiles.gd -- "$input" "$output"
        hash_ok "$index" "$sum" && tiles_ok "$index" || fail "regenerated tiles disagree with pins: $id"
    done
    verify_pack
}

verify_pack() {
    size_file="$SCRATCH/asset-sizes-$$.txt"
    : > "$size_file"
    wc -c < "$MANIFEST" >> "$size_file"
    object_ref=$(jq -r '.objects_index' "$MANIFEST")
    case "$object_ref" in res://data/observations/*) wc -c < "${object_ref#res://}" >> "$size_file" ;; *) fail "unexpected object index" ;; esac
    jq -r '.plates[].id' "$MANIFEST" | while IFS= read -r id; do
        levels_ok "$id" || fail "missing/changed source display: $id"
        if [ "$(plate "$id" '.registered')" = true ]; then
            hash_ok "data/raw/observations/$id/source.fits" "$(plate "$id" '.source_sha256')" || fail "missing/changed science source: $id"
        fi
        ref=$(plate "$id" '.tiles.path'); index=$(local_path "$ref")
        hash_ok "$index" "$(plate "$id" '.tiles.sha256')" && tiles_ok "$index" || fail "missing/changed pyramid: $id"
        run_gate observation-tiles-verify "$SCRATCH/verify-$id.log" 180 '^observation-tiles-verify: [1-9][0-9]* tiles, 0 failures$' "$GODOT" --headless --path . --script tools/observation_tiles.gd -- --verify "$ref"
        wc -c < "$index" >> "$size_file"
        jq -r '.levels[].tiles[].path' "$index" | while IFS= read -r tile_ref; do path=$(local_path "$tile_ref"); wc -c < "$path" >> "$size_file"; done
    done
    total=$(awk '{sum += $1} END {printf "%.0f",sum}' "$size_file")
    rm -f "$size_file"
    [ "$total" -le 104857600 ] || fail "starter tile pack exceeds 100 MiB ($total bytes)"
    count=$(jq '.plates | length' "$MANIFEST")
    echo "observation-assets: $count plates, $total bytes, 0 failures"
}

bundle_pack() {
    verify_pack
    mkdir -p "$BUNDLE"
    cp "$MANIFEST" "$BUNDLE/manifest.json.bin"
    objects=$(jq -r '.objects_index' "$MANIFEST")
    case "$objects" in res://data/observations/*) cp "${objects#res://}" "$BUNDLE/objects.json.bin" ;; *) fail "unexpected object index" ;; esac
    jq -r '.plates[].id' "$MANIFEST" | while IFS= read -r id; do
        ref=$(plate "$id" '.tiles.path'); index=$(local_path "$ref")
        mkdir -p "$BUNDLE/$id"
        cp "$index" "$BUNDLE/$id/tiles.json.bin"
        jq -r '.levels[].tiles[] | [.path, .sha256] | @tsv' "$index" | while IFS="$(printf '\t')" read -r tile_ref sum; do
            case "$tile_ref" in "res://data/raw/observations/tiles/$id/"*) ;; *) fail "tile outside plate" ;; esac
            path=$(local_path "$tile_ref")
            target="$BUNDLE/$id/${path##*/}.bin"
            cp "$path" "$target"
            hash_ok "$target" "$sum" || fail "bundle hash changed"
        done
    done
    echo "observation-bundle: $(jq '.plates | length' "$MANIFEST") plates, 0 failures"
}

validate_manifest
case "${1:-}" in
    fetch) fetch_pack ;;
    verify) verify_pack ;;
    bundle) bundle_pack ;;
    *) fail "usage: $0 fetch|verify|bundle" ;;
esac
