#!/bin/sh
# Focused fixture transport checks. Never mutate the active starter or bundle.
set -eu
TMP=$(mktemp -d /tmp/observation-assets-test.XXXXXX)
ID="asset-fixture-$$"
RAW="data/raw/observations/$ID"
TILES="data/raw/observations/tiles/$ID"
cleanup() { rm -rf "$TMP" "$RAW" "$TILES"; }
trap cleanup EXIT INT TERM
mkdir -p "$RAW" "$TILES" "$TMP/bin"
cp data/raw/observations/abell3128-vis/source.fits "$RAW/source.fits"
cp "$RAW/source.fits" "$TMP/source.fits"
cp data/raw/observations/abell3128-vis/detail.png "$TMP/detail.png"
cp data/raw/observations/abell3128-vis/overview.png "$TMP/overview.png"
cp data/raw/observations/abell3128-vis/detail.png "$RAW/detail.png"
cp data/raw/observations/abell3128-vis/overview.png "$RAW/overview.png"
if ! sh tools/script_gate.sh fixture-tiles "$TMP/build.log" 60 '^observation-tiles: [1-9][0-9]* levels, 0 failures$' -- "${GODOT:-godot}" --headless --path . --script tools/observation_tiles.gd -- "res://$RAW/detail.png" "res://$TILES" > "$TMP/build-gate.log" 2>&1; then cat "$TMP/build-gate.log"; exit 1; fi
SUM=$(shasum -a 256 "$TILES/tiles.json" | cut -d' ' -f1)
jq --arg id "$ID" --arg sum "$SUM" '.plates=[.plates[0]] | .plates[0].id=$id | .plates[0].tiles={path:("res://data/raw/observations/tiles/"+$id+"/tiles.json"),sha256:$sum} | .plates[0].levels[].path |= sub("observations/abell3128-vis/"; "observations/"+$id+"/")' data/observations/euclid_dr1/manifest.json > "$TMP/valid.json"
cat > "$TMP/bin/curl" <<EOF
#!/bin/sh
echo unexpected-network >> "$TMP/network"
exit 97
EOF
chmod +x "$TMP/bin/curl"
run() {
    OBSERVATION_MANIFEST="$1" OBSERVATION_SCRATCH="$TMP/log" OBSERVATION_BUNDLE="$TMP/bundle" PATH="$TMP/bin:$PATH" sh tools/observation_assets.sh "$2"
}
passed=0
failed=0
expect() {
    label=$1 want=$2 manifest=$3 mode=$4
    rc=0
    run "$manifest" "$mode" > "$TMP/case.log" 2>&1 || rc=$?
    if { [ "$want" = pass ] && [ "$rc" = 0 ]; } || { [ "$want" = fail ] && [ "$rc" != 0 ]; }; then
        passed=$((passed+1)); echo "ok $label"
    else
        failed=$((failed+1)); echo "FAIL $label"; cat "$TMP/case.log"
    fi
}
expect pinned-real-fixture pass "$TMP/valid.json" verify
expect cached-fetch-with-no-network pass "$TMP/valid.json" fetch
if [ ! -f "$TMP/network" ]; then passed=$((passed+1)); echo "ok no-network-request"; else failed=$((failed+1)); echo "FAIL cached fetch requested network"; fi
# Missing registered display levels should use their immutable PNG objects before
# invoking the offline stretch; the pinned science source remains cached here.
DETAIL_SUM=$(shasum -a 256 "$TMP/detail.png" | cut -d' ' -f1)
OVERVIEW_SUM=$(shasum -a 256 "$TMP/overview.png" | cut -d' ' -f1)
cat > "$TMP/bin/curl" <<EOF
#!/bin/sh
out=
url=
while [ "\$#" -gt 0 ]; do
 case "\$1" in -o) shift; out=\$1 ;; https://*) url=\$1 ;; esac
 shift
done
echo "\$url" >> "$TMP/network"
case "\$url" in
 */$DETAIL_SUM.png) cp "$TMP/detail.png" "\$out" ;;
 */$OVERVIEW_SUM.png) cp "$TMP/overview.png" "\$out" ;;
 *) exit 22 ;;
esac
EOF
rm "$RAW/detail.png" "$RAW/overview.png"
expect immutable-prepared-levels-first pass "$TMP/valid.json" fetch
if [ -f "$TMP/network" ] && [ "$(wc -l < "$TMP/network" | tr -d ' ')" = 2 ] && grep -q "$DETAIL_SUM.png" "$TMP/network" && grep -q "$OVERVIEW_SUM.png" "$TMP/network"; then passed=$((passed+1));echo 'ok registered PNGs fetched by pinned bucket hashes';else failed=$((failed+1));echo 'FAIL registered levels regenerated before trying immutable PNGs';fi
rm -f "$TMP/network"
cat > "$TMP/bin/curl" <<EOF
#!/bin/sh
out=
url=
while [ "\$#" -gt 0 ]; do
 case "\$1" in -o) shift; out=\$1 ;; https://*) url=\$1 ;; esac
 shift
done
echo "\$url" >> "$TMP/network"
case "\$url" in
 https://eas.esac.esa.int/sas-cutout/*) cp "$TMP/source.fits" "\$out"; exit 0 ;;
 *) exit 22 ;;
esac
EOF
rm "$RAW/source.fits" "$RAW/detail.png" "$RAW/overview.png"
rm "$TILES"/*.png "$TILES/tiles.json"
expect official-fallback-and-rebuild pass "$TMP/valid.json" fetch
if [ "$(wc -l < "$TMP/network" | tr -d ' ')" = 5 ]; then passed=$((passed+1)); echo "ok bounded source/index fallback requests"; else failed=$((failed+1)); echo "FAIL unexpected fallback request count"; cat "$TMP/network"; fi
jq '.plates[0].source_sha256="0000000000000000000000000000000000000000000000000000000000000000"' "$TMP/valid.json" > "$TMP/bad-source.json"
expect science-source-hash fail "$TMP/bad-source.json" verify
jq '.plates[0].licence=""' "$TMP/valid.json" > "$TMP/bad-rights.json"
expect missing-rights fail "$TMP/bad-rights.json" verify
jq '.plates[0].levels=[]' "$TMP/valid.json" > "$TMP/no-source-levels.json"
expect missing-source-levels fail "$TMP/no-source-levels.json" verify
jq '.plates[0].tiles.sha256="0000000000000000000000000000000000000000000000000000000000000000"' "$TMP/valid.json" > "$TMP/bad-index.json"
expect tile-index-hash fail "$TMP/bad-index.json" verify
expect isolated-byte-bundle pass "$TMP/valid.json" bundle
if cmp -s "$TILES/tiles.json" "$TMP/bundle/$ID/tiles.json.bin" && cmp -s "$TILES/l0_x0_y0.png" "$TMP/bundle/$ID/l0_x0_y0.png.bin"; then passed=$((passed+1)); echo "ok bundle byte copies"; else failed=$((failed+1)); echo "FAIL bundle byte copies"; fi
printf 'broken fixture' > "$TILES/l0_x0_y0.png"
expect corrupt-tile fail "$TMP/valid.json" verify
echo "observation-assets-test: $passed passed, $failed failures"
[ "$failed" = 0 ]
