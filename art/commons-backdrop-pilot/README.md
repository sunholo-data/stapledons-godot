# Wider Commons backdrop pilot

D-134 responds to Mark's review: furniture alone left vast bare areas toward the
ship edge, unlike the richer approved concept. This study adds real architectural
and planted depth across the existing physical Commons disc. It is review-only.

The comparison keeps the D-133 furniture in both images. The proposed image adds
broken civic arcades, planted alcoves, smaller market shades and low garden edges.
There are open cross-passages and broad north/south sky avenues. This uses the
concept's palette and layering; the invisible bubble, narrow inaccessible spire,
seven major tiers and live sky retain their established design.

`placements.json` is the exact layout. Remote background uses the existing physical
floor beyond current WALK; it does not open new navigation or simulated residents.
All substantial modules have explicit structural collision. Soil anchors support
painted foliage, with no additional pots hidden underneath. Source colours use the
existing pigments and shared live toon/ink shading, without painted skies or lights.

Run from the project root with the pinned runtime:

```sh
AILANG_BIN="$PWD/runtime/bin/ailang" godot --headless --path . --script tools/commons_backdrop_validate.gd
AILANG_BIN="$PWD/runtime/bin/ailang" godot --path . --script tools/commons_pilot_review.gd -- --config res://art/commons-backdrop-pilot/placements.json --out res://renders/view-finish/commons-backdrop-pilot
godot --path . --script tools/commons_pilot_golden.gd -- --config res://art/commons-backdrop-pilot/placements.json
```

Inspect matched actual player Bow/Astern frames at rest, cruise and real guided
stop, including the existing under-terrace ceiling clamp and a bridge rim view.
Physical floor rays and every transformed vertex must respect the conservative
95 m architecture envelope. Keep the original head/pole thresholds and routes.
The earlier native download does not include this pilot. S3/S5, propagation,
performance and final landing gates remain open.
