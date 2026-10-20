#!/bin/sh
# R2-DECK-LAYOUT DL1: rebuild the bridge blockout from a layout (art/deck-layout-v2/README.md).
#   tools/deck_blockout.sh <layout.json> <scene name>   e.g. art/deck-layout-v2/bow_a.json stapledon_bridge_deck_layout_a_v2
# 1. bake the walk in-engine (tools/deck_walk_bake.gd, on the pinned baseline: make ship-baseline);
# 2. the Blender generator (~/dev/blender, BLENDER_WS to override) moves the props, puts the walk in,
#    writes SPAWN_/INTERACT_ empties, saves scenes/<scene name>.blend (never overwrites) and exports;
# 3. copies ship.glb and walk_bridge.glb into assets/ship_demo/ and prints the sidecar's points
#    (the manifest's spawn_captain and stations) and the export pins.
set -eu
LAYOUT=$1; NAME=$2
WS="${BLENDER_WS:-$HOME/dev/blender}"
OUT="${TMPDIR:-/tmp}/deck-blockout-$NAME"
GAME=$(pwd)
mkdir -p "$OUT"
sh tools/ship_baseline.sh fetch >/dev/null
AILANG_BIN="$(command -v ailang)" perl -e 'alarm 600; exec @ARGV' godot --headless --path . --script tools/deck_walk_bake.gd -- --layout "res://$LAYOUT" --out "$OUT/walk_baked.glb" | grep '^deck-walk-bake'
(cd "$WS" && perl -e 'alarm 900; exec @ARGV' ./blender.sh -b --python scripts/stapledon_deck_layout_v2.py -- --game "$GAME" --layout "$LAYOUT" --walk "$OUT/walk_baked.glb" --out "$OUT" --scene "scenes/$NAME.blend" 2>&1 | grep -E '^DECK_LAYOUT_V2_OK|Error|Traceback' | cut -c1-200)
cp "$OUT/ship.glb" "$OUT/walk_bridge.glb" assets/ship_demo/
echo "deck-blockout: exported to assets/ship_demo/; sidecar $OUT/deck_layout_v2.json; master $WS/scenes/$NAME.blend"
