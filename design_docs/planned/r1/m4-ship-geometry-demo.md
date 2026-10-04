# Ship geometry demo: bridge overlook and one-tier lift

**Status:** Approved by Mark in attended session 2026-10-04; execution started.
**Release:** r1 development review build. **Milestone:** M4 geometry smoke test, isolated from the production interior.
**Priority:** Validate physical views and camera feasibility before adding ship architecture.
**Implements:** [ship interior brief](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md) §§3,5,6; [ship exploration](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/ship-exploration.md); [ship structure](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/ship-structure.md). Geometric conventions follow [Higgs bubble](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md). Existing sky physics stays with the pinned relativity package and [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md).
**Depends on:** chosen reference in `art/ship-dimensions-v2`; D-34/D-35; actual bridge-v2 geometry; recovered bridge build source `2899e70` and its parent `9008c5d` (preserved in build/recovery); existing Godot/AILANG v0.52.0.
**Estimate:** 1,560 changed lines including tests/tools; four sequential milestones, approximately 3–5 focused implementation/review sessions. Scheduling estimate, not measured completion time.

## Game vision alignment

| Pillar | Score | Alignment |
|---|---:|---|
| Choices Are Final | 0 | Separate geometry demo, no production journey decisions or save/load changes |
| The Game Doesn't Judge | 0 | Spatial review, no moral scoring |
| Time Has Emotional Weight | 0 | At-rest scene snapshot, not a new pause/fast-travel mechanic in the voyage |
| The Ship Is Home | +2 | Captain can see and visit another part of the shared ship |
| Grounded Strangeness | +2 | Measured sphere, floors, occlusion and real transport route |
| We Are Not Built For This | 0 | No new psychological claims/mechanics in this smoke test |
| **Net** | **+4** | **Go for a bounded demo; not a full exploration milestone** |

## Problem and evidence

The published reference is a seven-tier Blender blockout, not yet an interactive game scene. The production interior still combines an orthographic play camera with an upward perspective sky/panorama camera and a fixed-view painted plate. Those projections do not establish physically coherent arbitrary tilts.

Inspection of recovery source `2899e70` found:
- `interior/interior.gd`: own-world play SubViewport and orthographic camera, projected bridge plate, fixed parallax plates.
- `interior/area_bundle.gd`: GLB runtime loading with `GLTFDocument.append_from_buffer`; editor-import automatic LOD must not be assumed.
- `interior/walk.gd`: `height_at()` chooses the highest XZ-overlapping triangle. A single combined seven-tier WALK surface would incorrectly put a lower-deck captain on an upper floor.
- Actual lift arrival pad and arrival spawn are at glTF local (8,0,-8), corresponding to Blender ship (8,8,82). It is a static arrival pad, not an implemented lift shaft.
- The reference rim eye radius 21.3 m exceeds the current authored walk radius 20.7 m (before capsule margin). A diagnostic camera there does not prove a person can safely stand there.
- Current seven-tier export has about 214k triangles and 3.4 MB GLB, with no buildings/forests yet. File size is not a GPU-memory or frame-time measurement.

## Goals and exclusions

**First useful deliverable:** see the actual bridge and lower decks together through a coherent camera; tilt down, inspect how the floor and rails occlude them, and pull back to the ship overview.

**Second deliverable:** board a short lift, travel 25 m from bridge Z +82 to first lower tier Z +57, step onto a small landing, and return. This is viable if the route has real openings and safe landings. It is not a teleport through solid floors.

Excluded: all-tier free traversal; stairs/ramps between every floor; finished buildings or forests; crew AI; new journey/clock behaviour; a new relativistic/glare implementation; map marker implementation; finished off-axis painted bridge textures. A simple local landing may have a bench/scale marker, not a populated city.

## Design

### 1. Shared geometry and asset sections

Keep Blender metres/+Z ship frame, bubble radius 100 m, actual main bridge radius 22 m at +82 m and needle +98 m. Lower surfaces: +57,+32,+7,−18,−43,−68 m. Fit entire lower floor slabs within the accepted 95 m inner envelope. Existing bridge is the retained exception to a whole-ship 5 m shell buffer; D-35 accepted the lower-floor clearance, not shortening the existing needle.

Use one master Blender assembly, linking bridge and tier collections. Export detailed bridge, a first-tier landing/walk surface, and coarse visual-only lower-tier geometry with transforms recorded in a manifest. Gameplay collision only for active accessible sections; visual background decks never join the active WALK surface. Export pieces share a coordinate frame even if they use local origins.

### 2. One coherent geometry camera

Create a standalone `demos/ship_geometry_demo.tscn` and controller. Render all finite ship geometry in a shared World3D with a perspective camera. Keep live sky/background rays matched to the camera's ship-frame direction and FOV; any separate infinite-distance sky viewport must use the same projection and attitude. Start at rest (beta=0), explicitly labeled geometry demo.

Use the bridge's native GLB materials for diagnostic free-angle views. Preserve the approved production painted plate in its existing renderer; do not stretch or project that one view as though it were finished textures for arbitrary angles. No static foreground/panorama copy of geometry already drawn in 3D. No sphere-wire guides obscuring the normal player view; guides can be toggled for inspection.

Controls: WASD walk on active landing; mouse drag tilt/look; wheel bounded camera pullback; buttons/presets for bridge, overlook and whole-ship view; E board/use lift. Reset resets this isolated scene only. Exact bindings and sensitivities reuse existing conventions where possible.

Two camera purposes are explicit:
- **Player view:** eye/capsule positions must be safely reachable. Survey the bridge for a clear rim approach; do not silently move the captain outside the current walk region.
- **Reference camera:** reproduce the measured interior (16,−8,83.7) and rim (19.0513,−9.52565,83.7) views at down tilts 15,30,45,60°, FOV 78°. Label these diagnostic presets; the rim preset is not certified as a standing location.

Floor/rail blocking is correct behaviour. Camera raycast tests must distinguish a first-hit centre ray from what appears elsewhere in the whole image. Occlusion is not solved by making floors transparent.

### 3. Lift and two separate walk domains

Prefer adapting the existing arrival pad at ship (8,8,82), pending geometry/capsule survey. Its corresponding first-tier landing is (8,8,57). Check the entire swept platform/captain envelope against spire, bridge kit and both floor slabs. If that location cannot accommodate a safe opening, report and relocate the pad in the Blender demo copy before implementing motion.

Model a real guarded opening in the bridge and receiving tier, plus a moving platform and visible guides/support attachment. Update matching collision; guards protect an open landing when the platform is absent. Never cut or edit the production bridge asset in place: create a distinct demo variant for art review.

State machine: `bridge_ready -> boarding -> descending -> lower_ready -> boarding -> ascending -> bridge_ready`. During travel, the captain is attached to the platform, ordinary walking is locked and boarding inputs are ignored. At arrival, activate the destination's separate WALK surface, detach to a verified spawn, and enable movement. Return uses the same route and ordering. Repeated interaction cannot start a second ride or duplicate the avatar.

Target presentation: about 10–12 seconds for the 25 m trip, with gentle ease-in/out. It is a visual transport controller, not a new AILANG motion/energy simulation. Measure route and endpoints exactly; final timing is a demo tuning parameter. A camera may keep looking outward during descent so changing deck occlusion is visible.

### 4. Resource and delivery checks

Start with existing geometry, small landing and no forests. Avoid full-detail distant buildings by retaining coarse visual tiers and separate local assets. Record frame time, draw calls, triangles and video-memory/texture statistics at captain view, downward overlook, mid-lift and whole-ship view. Test on the actual laptop; do not infer performance from the Studio GPU.

Proposed target: 60 fps at 1920×1080 on Mark's laptop, with recorded frame-time distribution after warm-up. If it misses, reduce geometry/material/shadow costs or introduce authored detail levels before dressing the tiers. Verify lower detail preserves the measured silhouette and first-hit occlusion. Any performance claim requires measured hardware/results.

Publish captures, a short bridge-to-tier-and-back recording, measured geometry audit and laptop review build. Keep the overview/reference webpage as the review hub. Production integration and final multi-angle paint remain subsequent work.

## Acceptance criteria

Commands below are planned interfaces added by implementation; they are not claimed to exist/pass today.

| ID | Evidence required | Command |
|---|---|---|
| GEO-1 | Seven surfaces at approved heights; lower vertices ≤95 m, all ship vertices ≤100 m; actual bridge tip preserved | `make validate-ship-demo` |
| VIEW-1 | Perspective eye/FOV/attitude matches reference; centre-ray hits match regenerated geometry; no duplicate spire | `make ship-demo-test` |
| VIEW-2 | Captures reviewed: bridge, interior/rim diagnostic angles, whole ship; sky ray attitude/FOV agrees | `make ship-demo-capture` plus review of listed PNGs and capture manifest |
| WALK-1 | Two overlapping XZ walk regions retain distinct heights; arrival/return spawn fits capsule; safe edges | `make ship-demo-test` |
| LIFT-1 | No floor/spire crossings; platform endpoint error ≤1 cm; captain attaches/detaches once; re-entry ignored; repeat round trips stable | `make ship-demo-test` and `make ship-demo-smoke` |
| PERF-1 | Hardware/resolution recorded; all four representative views profiled; laptop results satisfy target or remaining deficit explicitly blocks performance signoff | `make ship-demo-bench` on laptop |
| COMPAT-1 | Existing game physics/walk/plate checks unchanged and green | `make test AILANG=runtime/bin/ailang`; `make golden AILANG=runtime/bin/ailang` |
| SHIP-1 | Exported app runs demo; manifest/hash/install verified; asset references not temp-only | `make ship-demo-export-smoke`; `make publish-dev` after checks |

## Milestones, order and estimates

| Milestone | Implementation | Tests/tools | Total | Dependency |
|---|---:|---:|---:|---|
| SD1 Geometry/manifest and route survey | 180 | 100 | 280 | chosen reference and recovered bridge source |
| SD2 Perspective overlook/pullback demo | 350 | 150 | 500 | SD1 |
| SD3 Guarded lift and first-tier landing | 280 | 180 | 460 | SD2 visual milestone passes |
| SD4 Laptop profiling, export and review evidence | 180 | 140 | 320 | SD3 |
| **Total** | **990** | **570** | **1,560** | sequential |

SD2 is independently reviewable. If camera/style work needs more iteration, deliver the overlook before SD3; report the lift's remaining work rather than substituting a teleport and calling it complete.

## Risks and mitigations

- Off-axis rendering exposes unfinished paint: diagnostic native materials, separate production renderer; review before promising style parity.
- Existing pad is not a shaft: physical/capsule survey and real guarded openings are SD1 prerequisites.
- Highest-floor walker bug: explicit active walk region and transport attachment, tested with overlapping floor fixtures.
- Unsafe rim point: distinguish diagnostic reference camera from player standing/leaning positions.
- Large transparent bubble/vegetation costs: no opaque bubble hull; postpone vegetation and measure laptop before populating.
- Recovery source not on main: reconstruct a clean implementation branch using preserved commits/bundles and approved art source; do not reset unrelated local work.

## Decisions and deliverables

Mark approved this scope in the attended session on 2026-10-04, adding the explicit requirement for one meaningful perspective across stars, SR/GR, play and background geometry. The recommended default includes the overlook and the one-tier lift, with overlook delivered first. Seven layers and 5 m lower-floor clearance are already decided. Transport layout and final architectural zoning are implementation/art-review proposals, not new ship canon.

Deliver: source design + sprint JSON; master Blender demo copy and derived GLBs; runnable example scene; automated geometry/camera/transport evidence; inspected renders and video; actual laptop benchmark; review-build install link; updated reference hub. An independent evaluator checks the implemented result before production landing, per CLAUDE.md.

## Approved viewpoint clarification (2026-10-04)

One observer defines eye position in ship metres, forward/up, vertical perspective FOV, viewport/aspect and ship-to-galactic frame. Play geometry, finite background decks and real foreground members use that observer. External sky sampling uses its matching rays; velocity remains the sim-owned boost, independent of the direction the camera looks. SR changes external light, not the co-moving ship meshes. Update glow intersection origin during camera movement instead of retaining the old bridge eye.

The first demo is at rest; the existing SR renderer must remain usable through the shared view contract and existing golden checks. Test matching rays at centre/corners after tilt, roll, resize, pullback and lift movement. Do not add independently scaled plate parallax. GR black-hole lensing is not implemented in this checkout (M3 remains planned); provide a documented observer input seam for its future integration, without advertising or faking GR visuals in the demo. Any future GR integration must transform the full external sky consistently, including catalogue stars, and pass its own package-first reference/golden checks. A shared camera is necessary, not sufficient, to certify that future physics.
