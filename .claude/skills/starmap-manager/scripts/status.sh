#!/bin/bash
# Show current starmap asset status: raw catalogue inputs (against data/sky/SHA256SUMS), each
# binary tier's sidecar, the map stars.json and the sky background textures.
# Usage: status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
RAW_DIR="$PROJECT_ROOT/data/raw"
OUTPUT_DIR="$PROJECT_ROOT/data/starmap"
BG_DIR="$RAW_DIR/background"
SUMS="$PROJECT_ROOT/data/sky/SHA256SUMS"

# field <json file> <key>: a top-level scalar from a one-line sidecar (no jq/python needed)
field() { grep -o "\"$2\":[^,}]*" "$1" | head -1 | cut -d: -f2- | tr -d '"'; }

echo "=== Starmap Asset Status ==="
echo "Project: $PROJECT_ROOT"
echo ""

echo "Catalogue inputs ($RAW_DIR, pins in data/sky/SHA256SUMS):"
for name in cns5.dat cns5.csv table1c.dat.gz gcns.csv; do
    pin="$(grep " data/raw/$name\$" "$SUMS" | cut -d' ' -f1)"
    if [ ! -f "$RAW_DIR/$name" ]; then
        echo "  $name: missing"
    elif [ "$(shasum -a 256 "$RAW_DIR/$name" | cut -d' ' -f1)" = "$pin" ]; then
        echo "  $name: $(du -hL "$RAW_DIR/$name" | cut -f1), matches pin"
    else
        echo "  $name: $(du -hL "$RAW_DIR/$name" | cut -f1), DOES NOT match pin $pin"
    fi
done
echo ""

echo "Binary tiers ($OUTPUT_DIR):"
missing_tier=false
for tier in quick medium large; do
    json="$OUTPUT_DIR/stars_$tier.json"; bin="$OUTPUT_DIR/stars_$tier.bin"
    if [ -f "$json" ] && [ -f "$bin" ]; then
        tracked="$(git -C "$PROJECT_ROOT" ls-files --error-unmatch "data/starmap/stars_$tier.bin" >/dev/null 2>&1 && echo committed || echo local)"
        echo "  $tier: $(field "$json" count) stars, $(field "$json" count_excluded) excluded, $(wc -c < "$bin" | tr -d ' ') B ($tracked; ailang $(field "$json" ailang))"
    else
        echo "  $tier: not built"
        [ "$tier" = large ] || missing_tier=true
    fi
done
echo ""

if [ -f "$OUTPUT_DIR/stars.json" ]; then
    echo "Map stars.json: $(du -h "$OUTPUT_DIR/stars.json" | cut -f1) ($(grep -o '"count":[0-9]*' "$OUTPUT_DIR/stars.json" | head -1 | cut -d: -f2) stars within 25 pc, M1.7)"
fi
echo ""

echo "Sky background textures ($BG_DIR):"
for t in noirlab_10k_destarred.png noirlab_10k_skymodel.png; do
    if [ -f "$BG_DIR/$t" ]; then echo "  $t: $(du -hL "$BG_DIR/$t" | cut -f1)"; else echo "  $t: missing"; fi
done
echo ""

echo "Recommendations:"
if [ "$missing_tier" = true ]; then
    echo "  The quick and medium tiers are committed; restore them with git checkout data/starmap"
fi
if [ ! -f "$RAW_DIR/cns5.dat" ] || [ ! -f "$RAW_DIR/table1c.dat.gz" ]; then
    echo "  Fetch the catalogue inputs: make catalogue-inputs AILANG=\$A"
fi
if [ ! -f "$BG_DIR/noirlab_10k_skymodel.png" ]; then
    echo "  Fetch the sky textures: make sky-assets AILANG=\$A"
fi
echo "  Rebuild check: make catalogue-verify AILANG=\$A; stats: make catalogue-stats"
