# Deck layout v2: the bridge faces the bow

R2-DECK-LAYOUT ([design](../../design_docs/planned/r2/deck-layout.md), ledger D-95). The bridge is rearranged for the fixed Bow and Astern views (D-91 to D-94): the navigation arc at the bow rail on the centreline, the captain's chair behind it, the Voyage and Crew consoles flanking, each operator stern of the console and facing the bow, and the spawn behind the helm.

## Files

| File | What |
|---|---|
| `bow_a.json` | Layout A, the one Mark approved (D-95): each moved prop group's pivot and yaw in ship metres, the spawn, the stations' `use_m` operator points |
| `bow_b.json`, `spawn_only.json` | The rejected alternative and the control (plan evidence) |
| `shipped.json` | The identity layout: the deck as `assets/ship_demo/` ships it |
| `thresholds.json` | The bow evaluator's §D4 thresholds (`make deck-layout-eval`) |
| `budgets.json` | Pins and per-GLB budgets (`make deck-assets-check`) |
| `baseline.sha256` | The grounded-bridge-v2 export the evaluator's positive control runs on (`make ship-baseline`) |
| `asset-pins.json` | The blockout's provenance: generator sha, layout sha, source and new master |

## How the blockout is made (DL1)

1. **Walk.** `godot --headless --path . --script tools/deck_walk_bake.gd -- --layout res://art/deck-layout-v2/bow_a.json --out <dir>/walk_baked.glb` loads the pinned grounded v2 deck (`make ship-baseline`), applies the layout with `DeckLayout.apply` and writes the rebuilt walk: the shipped walk, clipped out of each moved prop's old and new footprints and re-rastered there on the 0.125 m grid. It is the walk the evaluator measured in-engine.
2. **Master and export.** In `~/dev/blender`: `./blender.sh -b --python scripts/stapledon_deck_layout_v2.py -- --game <this clone> --layout art/deck-layout-v2/bow_a.json --walk <dir>/walk_baked.glb --out <dir> --scene scenes/<new name>.blend`. It opens the grounded v2 master, moves each named group by `new · old⁻¹` (the same rule as `DeckLayout.apply`), puts the baked walk into `WALK_bridge`, writes `SPAWN_captain` and `INTERACT_<station>_use` empties (collection `deck_layout_v2`), checks every other object is unchanged, saves the master and exports `ship.glb` and `walk_bridge.glb`. Its sidecar `deck_layout_v2.json` carries the authored points.
3. **Game.** Copy the two GLBs into `assets/ship_demo/`; the manifest's `spawn_captain` and `stations.<id>.use_m` come from the sidecar (`ShipConsoles` and `bridge_spawn()` read them). Repin `budgets.json` and `asset-pins.json`.
4. **Check.** `make deck-layout-eval` must print `deck-layout: bridge ok`; then the gates in the sprint plan.

Props keep their grounded v2 geometry, materials, UVs and names (a blockout, not art). The master is in the public bucket by sha256 (`asset-pins.json`); the generator is packed inside it. No Python enters the game (design §D6).
