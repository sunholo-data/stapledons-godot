# Commons lived-in kit v1 — bounded art pilot

Mark authorized one lived-in pilot on the current Commons layout. This kit is
review-only. It does not approve full-level propagation, close S3, change the
layout, or introduce new gameplay. Root owns actual placement and player-camera
review; no world placement is embedded in this catalog GLB.

The eight groups supply three purposeful edge activities: shared seated use,
a public reading/notice station, and an occupied arcade work counter. Grown
cream/teal furniture, cushions, cups, rounded books, loose folded cloth, woven
storage, a modest hand cart and empty soil-filled planters reuse the existing
painted bridge pigments. There are no crates, pavilion, emissive displays,
baked sky/light, or geometric leaves. Papers are illustrative marks with no
new lore text or interactive notice feature.

`kit-hero-studio.png` is a neutral Blender authoring diagnostic. It arranges
linked copies for inspection and omits foliage. Sign-off should use actual
Bow/Astern game views with live lighting, existing toon/ink, and painted shrub
cards placed on the exported soil anchors. It is not a proposed lighting or
world composition change.

## Integration contract

`commons_lived_in_kit_v1.glb` has eight top-level prop roots, all identity,
metres, floor-centred. Blender +Z is up and +Y is front; glTF is `(x,z,-y)`.
The roots overlap intentionally. Extract the selected named subtree rather than
instantiating the whole catalog at one point. Exact full bounds, structural
`solid_meshes`, hashes and soil anchors are in `kit-source.json`.

| Root | Triangles | Size in Blender metres (X × Y × Z) |
| --- | ---: | --- |
| civic_bench | 3,256 | 3.251 × 1.354 × 1.010 |
| communal_table | 3,996 | 1.900 × 1.100 × 0.865 |
| storage_baskets | 7,208 | 1.241 × 0.470 × 0.497 |
| notice_read_station | 4,004 | 1.160 × 0.870 × 1.900 |
| maintenance_cart | 3,824 | 1.030 × 0.825 × 1.119 |
| planter_large | 1,632 | 0.860 × 0.860 × 0.663 |
| planter_small | 1,632 | 0.513 × 0.513 × 0.343 |
| arcade_counter | 3,564 | 2.200 × 0.920 × 1.222 |

Total **29,116 triangles**, **1 referenced material**, **1 embedded 1536×1024
atlas**, **3,552,120 bytes**. The cart wheels start 5mm above the local origin;
all other structural feet start at zero. Bench seat is 0.48m (cushions above),
table centre surface 0.70m, counter centre surface 0.95m. No scale multiplier
is intended; captain height remains 1.75m.

Use the explicit structural mesh list for collisions. Small cups, papers,
cloth, books, cart tools, decorative ribs and foliage are collision-free.
`FOLIAGE_planter_large_soil` is glTF `[0,0.616,0]` and
`FOLIAGE_planter_small_soil` is `[0,0.296,0]`. Roots have no foliage so there is
no pot-on-pot silhouette; use the existing plant-only shrub card here.

## Sources and verification

Native authoring remains in the Blender workspace:

- `scripts/stapledon_commons_lived_in_pilot_v1.py`
- `scenes/stapledon_commons_lived_in_pilot_v1.blend` (packed editable master)
- `exports/stapledon_commons_lived_in_pilot_v1.glb`

The generator refuses existing masters. Reproduce through `./blender.sh
--background --factory-startup --python-exit-code 1 --python
scripts/stapledon_commons_lived_in_pilot_v1.py -- --game GAME --out OUT
--scene NEW_DISTINCT_NAME`. The consumed pigment PNG paths and hashes are pinned
in `kit-source.json`. No Python authoring pipeline was added to the game.

The final master opens with no missing external resources. Clean GLB reimport
preserves all roots, identity transforms, named structural meshes, both soil
anchors, the exact per-root triangle counts, and nonblack pigment pixels.
Workspace `make inspect` and `make validate-glb ... ANIMATED=0` pass. The latter
counts unused factory materials as well; the GLB itself references exactly one.
The studio scene contains linked preview copies, so its total triangles are
twice the exported kit plus the diagnostic floor. Metal hero render inspected.

The final generator, packed master and atlas have a recoverable archive under
ignored `build/commons-lived-in-source/`; exact path and hash are in metadata.
This is **local preservation only**, with no off-host backup or publication
claimed. Earlier task-created iterations were preserved in Blender
`scenes/backups/`; all unrelated originals remain untouched.
