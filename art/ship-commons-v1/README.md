# Commons open arcade v3

Current master: `ship_commons_master_v3.blend`. V1/V2 remain historical material and route experiments; the generic barrel pavilion was rejected as the architectural target. V3 follows the approved concept and measured zoning: retained open civic plaza, guarded connection and first curved arcade section. The whole tier is not populated.

Plaza bounds remain ship XY14–36 / −10–20 at structural Z57. Arcade piers use radii43/55m, angles−5°..18°, four open bays and an opaque terrace slab at61.15–61.39m. Local roof/edge overhangs and the outer walking strip remain within the approved43–57m arcade band. A4.5m guarded link connects the plaza. WALK finish is57.025m. The upper terrace is inaccessible. New vertices reach radius82.879m, within95m. Actual spire, seven tiers, lift and4× sky trial are preserved.

## Authoring and assets

Blender-only source commit`ad9123a`: `scripts/stapledon_ship_commons_v3.py` and `scripts/stapledon_ship_commons_paint_v3.py`, in the established authoring workspace. The master embeds these scripts, the expanded self-contained native generator, editable named modules, physical eye cameras and packed atlas. The generator reuses parameterized primitives from v2. Run with that workspace's `./blender.sh`; preserve existing scenes before regeneration. No game Python pipeline is added.

Ship metres/+Z up convert to GLB/Godot `(x,z,-y)`. All derivatives share this frame:

- `commons_painted.glb`:24,528 triangles, one opaque material, one1254×1254 embedded atlas.
- `commons_coarse.glb`:11,380 triangles, directly derived from tagged faces of the exact detailed batch. Major terrace/arcade/rib/rail/link geometry remains; small seating/planting/ink is omitted.
- `collision.glb`: separate additive collision; existing structural floor collision remains.
- `walk.glb`: active Commons WALK limited to plaza, link and first arcade section.
- `full_assembly.glb`: complete ship plus current Commons for external diagnostic review.

`demos/ship_commons.gd.install(demo)` removes exactly the old landing guard and replaces only lower WALK. Detail/coarse selection uses the manifest centre and100m threshold, without changing collision/navigation; both share one atlas resource. Commons-only GLTF loading disables position compression: default per-mesh AABB compression otherwise shifted identical vertices by about0.067mm. Production loading is unchanged. Exported review files stage into `ship_commons_bundle/*.bin`.

## Finish

Existing atlas provenance: imagegen skill/built-in tool,2026-10-04, four flat cream/teal/violet/olive brush-painted swatches; no perspective, objects, lighting, sky, stars or text. Generation`01a1074d-0ba8-7a23-85e1-9fb498eb9124`, selected original`exec-b98066b9-2c16-4f54-a0f7-11f37ae1a41d.png`; project copy`paint-atlas-v1.png`.

Padded local UVs cover opaque undersides/back faces too. Broad terrace strips are subdivided for nominal112texels/m on4m patches, with deterministic sampled variation. Geometry supplies teal grown ribs and thin violet ink around arches/terraces. Atlas drives base colour only, roughness0.82. No sky/SR/viewpoint lighting is baked. This is a compatible draft finish, not finished bridge-quality art; planting, furniture and seams remain art-review items.

## Verification and limits

Run `tests/test_ship_commons.gd`, `tests/test_ship_commons_assets.gd`, `tests/test_ship_commons_arcade.gd` and `tools/validate_ship_commons.gd` with `godot --headless --path . --script`. Validator `-- bad-envelope` must fail. GPU captures use `tools/ship_commons_capture.gd`; arcade gate is wired into `ship-demo-ci`.

The initial actual open-plaza ray failed against the old closed pavilion. The final arcade gate also requires nonempty measured terrace geometry, an opaque roof and real open arch rays, so empty geometry cannot pass. Strict destination checks caught path() snapping a planter-adjacent eye; the eye was relocated before captures. Final runtime checks:39passes including actual capsule clearance from lift to arcade. Exact runtime coarse triangles, roof/shade opacity, UV/material caps, envelope and shaft checks pass. Blender `make inspect SCENE=stapledon_ship_commons_painted_v3` reports no missing files; `make validate-glb SCENE=stapledon_ship_commons_painted_v3 ANIMATED=0` cleanly reimports. Native/painted courtyard Blender renders and actual inside game views were inspected. Logs, capture manifest and SHA256 pins are included.

Nine current captures cover bridge look-down, mid-lift, arrival, plaza, inside/along arcade, reverse toward bridge, planted plaza and an explicitly external diagnostic. Eyes are checked against active WALK; mid-lift is supported by its moving platform. First-hit/FOV/eye and labelled4× display-aid values are recorded. Roofs/floors correctly obstruct views; no clear bridge sightline is invented.

Target MacBook Air M2(2022),24GB at1920×1080 performance remains pending. Studio measurements are separate. No new physics/GR, glass dome, crew AI, engineering certification, accessible upper terrace or completed whole-zone construction is claimed.
