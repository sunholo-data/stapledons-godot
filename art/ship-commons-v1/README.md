# Commons local kit v1

Draft architecture and UV material proof, derived from `art/ship-demo-v1/ship_geometry_demo_v1.blend`. Blender ship coordinates are metres, +Z up; exported game coordinates are `(x,z,-y)`. The original production bridge and seven-tier assets are unchanged.

`ship_commons_master_v1.blend` contains the complete measured ship plus editable modular Commons objects, navigation, physical inside-eye cameras, packed atlas, and embedded generator scripts. Authoring scripts live exclusively in the established Blender workspace, commit `b7731c3`: `scripts/stapledon_ship_commons_v1.py` and `scripts/stapledon_ship_commons_paint_v1.py`; run through its launcher. Before regeneration, preserve existing output scenes; generators refuse to overwrite them.

The bounded court occupies ship XY14–36 / −10–20 at Z57. New paving is Z57.025 to avoid overlapping the structural floor. The pavilion is14×12m with3.3m eaves,8.1m roof rise above the deck (rib tops65.42m). Its doorway is3.5×2.7m. Benches have0.46m seats; reference figures are1.7m. Architecture fits within radius73m, inside the approved95m envelope. The four-metre east landing guard opening leads into this area; the spire remains inaccessible. The real lift shaft remains open.

## Runtime derivatives

- `commons_painted.glb`:8,708 triangles, one opaque material, one1254×1254 embedded atlas.
- `commons_coarse.glb`:3,036 triangles; exactly preserves major floor/roof/wall/rib/rail/door/Archive triangles, omits small props and engraving.
- `collision.glb`: additive collision surfaces; existing structural floors continue providing collision.
- `walk.glb`: separate active Commons WALK, replacing only the lower review area's walk domain.
- `full_assembly.glb`: full ship plus Commons for external website review; diagnostic representation, not a player eye.

`demos/ship_commons.gd.install(demo)` adds the kit after base WALK setup. `update_detail(kit,eye)` selects detail within100m of the pavilion centre and coarse beyond, without changing collision or navigation. Review assets stage into `ship_commons_bundle/*.bin` for exported apps.

## Paint proof and provenance

The atlas was generated with the imagegen skill and built-in image tool on2026-10-04. Prompt: four equal flat cream limestone, muted teal, violet and olive brush-painted material swatches; no perspective, objects, baked shadows, gradients, sky, stars, text or labels. Source generation ID`01a1074d-0ba8-7a23-85e1-9fb498eb9124`; selected original`exec-b98066b9-2c16-4f54-a0f7-11f37ae1a41d.png` is retained in the tool's generated-images folder. Project copy is `paint-atlas-v1.png`.

Every face, including hidden back and interior surfaces, receives face-local UVs inside the appropriate padded quadrant. The atlas drives base colour only; roughness is0.82, opacity is solid. No scene lighting, SR, stars or glow is baked. Actual game captures cover courtyard/front, side, back, interior, arrival, mid-lift, bridge look-down, reverse bridge underside and an explicitly external whole-ship review. Side/back views are close surface inspections constrained by the reachable court, rather than impossible external beauty cameras. This is a material proof, not finished Commons art: broad roof panels have lower texel density than small wall modules and the structural floor/underside is still native diagnostic material.

## Validation

Headless commands: `godot --headless --path . --script tests/test_ship_commons.gd`, `tests/test_ship_commons_assets.gd`, and `tools/validate_ship_commons.gd`. Negative control: validator `-- bad-envelope` must fail. GPU captures: `tools/ship_commons_capture.gd`. Blender `make inspect SCENE=stapledon_ship_commons_painted_v1` reports no missing external files; `make validate-glb SCENE=stapledon_ship_commons_painted_v1 ANIMATED=0` reimports the full assembly successfully.

Initial missing assets failed before authoring. Navigation first exposed an unsafe lift-landing margin; that failed check was corrected. Actual runtime capsule sweeps now clear the connected lift-to-court/pavilion/Archive routes. Visual inspection found the default Blender cube UV map overriding the new atlas; the generator now removes default maps before export, with padded-UV regression checks. Exported-geometry tests verify actual envelope/extrema, shaft and doorway clearance, roof/wall opacity, and exact coarse triangle preservation.

Performance on the target MacBook Air M2 (2022),24GB at1920×1080 remains pending. Studio profiling is separate evidence and must not be described as a laptop pass. No GR implementation, crew AI, forest, full-tier population, engineering certification or glass bubble is included.

The reachable bridge eye `(19,83.7,-7)` looks toward the pavilion roof, but its centre ray hits the bridge floor at `(20.27272,82,-7.818181)`: floor and rail correctly obstruct the direct look-down. This capture verifies the obstruction; it does not prove a clear Commons view from the bridge. Side/back/courtyard views and their routes have actual capsule-clearance checks. The mid-lift eye is supported by the moving platform, so it is correctly outside the stationary WALK domain. The external review capture selects the runtime coarse derivative.
