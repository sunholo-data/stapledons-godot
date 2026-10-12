# Ship layers — concept v1

**Status: proposal for art review, 2026-10-04.** This is a whole-ship spatial reference for
Blender builds, not an approved exterior model or a dimensioned drawing. The painted
image must not be used to override the coordinates and constraints below.

## Files

- `ship_layers_concept_v1.png`: full-resolution concept sheet, generated with the built-in image tool.
- `prompt.txt`: the exact generation prompt, including intended geometry and exclusions.
- Website thumbnail: `website/static/img/concept/ship-layers-v1.jpg`.
- Published reference: https://www.sunholo.com/stapledons-godot/docs/ship-layer-reference

## Fixed frame and current bridge anchors

| Constraint | Reference |
|---|---|
| Sphere centred at origin, radius approximately 100 m | Design-repo interior and exterior Blender briefs |
| Blender +Z is forward/up; aft/down is -Z | Same briefs; generator supplies crew gravity |
| Highest occupied deck is the bridge; no occupied deck above it | Interior brief §3 |
| Bridge deck +82 m, radius 22 m | Current Blender bridge build and game bundle `play_origin_ship_m` |
| Needle tip +98 m, one continuous central spire | Bridge validation `needle_tip_ship_m` |
| Spire about 14 m across at base | Interior brief §3 |
| All geometry, gardens, trees and support curves stay inside the sphere | Exterior brief §2 |
| Wide gaps between level rims and bubble; levels widen toward equator, then narrow | Exterior brief §2 and current backdrop generator |

Coordinates are authoring references, not measurements recovered from this illustration.
The generator's 0.55 cross-section fill is a starting point for level radii, not a frozen
whole-ship layout.

## Proposed zoning, still open

The sheet explores major gallery zones with smaller mezzanines: commons, homes, garden
cathedral, workshops and engineering. Their order, counts, heights, widths, routes and
furnishing are proposals. The bridge remains the highest occupied level.

The older sources disagree on level spacing: the interior brief mentions roughly 25 m
between levels and 10–20+ levels, while the older ship-structure feature lists 5–8 m
spacing. A 200 m-diameter sphere cannot contain 10–20 full-height tiers spaced 25 m
apart. Treat broad cathedral-height zones plus closer mezzanines as one concept to review;
do not derive a new canon or exact floor schedule from the generated drawing.

## Foreground and panorama construction

Every foreground frond, rail and support must have a root in shared ship geometry. The
rim detail proposes members attached to the bridge rim or its lower structural gallery,
rising past the deck and curving inward within the boundary. Exact attachment geometry
needs review. A foreground plate changes drawing order and pan speed; it does not exempt
its contents from physical placement.

Render near bridge geometry once in the play layer. Foreground plates represent geometry
actually nearer the camera, with correct attached roots and edge coverage. Panoramas show
structure genuinely beyond the play area, from their exported camera. Do not draw a second
copy of the central spire to make the background interesting. The current up-looking bridge
panorama cannot show lower decks; a rim or lift viewpoint can. Lower-level areas need their
own cameras and the undersides of decks above, rather than inheriting the open-topped
bridge view.

## Blender check before rendering

1. Build in metres, around the shared origin and +Z spire axis.
2. Check that every vertex lies within the 100 m sphere, including canopy and support tips.
3. Keep bridge deck +82 m and needle +98 m when extending the existing bridge.
4. Connect every structural member visibly to its supporting deck or core.
5. Inspect the actual camera: near/play/foreground and far/panorama assignments must follow
   geometry and depth, not the painted image alone.
6. Keep sky and physical bubble glow out of authored assets. The concept's boundary outline
   is a reference aid only; the engine supplies sky and glow live.

## Sources and rights

Design repository: `art/ship-interior-blender-brief.md` §2–5,
`art/ship-exterior-blender-brief.md` §2, and
`features/phase1-data-models/ship-structure.md` (older planned feature; spacing conflict above).
Current Blender backdrop: `scripts/stapledon_ship_backdrop.py`.
Game bundle: `assets/areas/bridge/manifest.json`.

AI-generated concept art under Sunholo art direction. No copyright is claimed, consistent
with attended decision D-33. This is not a game capture or a validated physics rendering.
