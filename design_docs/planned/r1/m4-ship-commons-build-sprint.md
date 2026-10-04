# Sprint: first Commons architecture and multi-angle paint

**ID:** R1-M4-SHIP-COMMONS. **Status:** approved by Mark; execution started.
**Design:** [m4-ship-commons-build.md](m4-ship-commons-build.md).
**Summary:** Establish the whole-ship asset workflow with one useful Commons area visible from the bridge and visitable via the existing lift. Medium risk: material portability and performance.

## Evidence and estimate

The prior geometry sprint estimated 1,560 lines and delivered a reviewable scene/lift, but performance remains unsigned. Recent commit `3898448` was a 61-line control refinement, followed by independent input/camera/lift checks; it is not a useful architecture/art velocity estimate. Generated polygon counts are not development velocity. Budget 1,050 source/check lines and 3–5 focused sessions including art iteration, not a calendar promise. Full ship dressing is outside this estimate.

## Milestones

| ID | Work and example delivery | Authoring/integration | Checks/tools | Dependency |
|---|---|---:|---:|---|
| CB-M1 | Copy measured master to distinct `stapledon_ship_commons_v1.blend`; survey lift/core; block pavilion/courtyard/route; export flat-colour kit and WALK domain. Example `assets/ship_commons/manifest.json` and bounded Commons area in demo. | 220 | 130 | current demo/master |
| CB-M2 | UV and paint one rib/wall/floor sample; verify compatible exported material in Godot, then complete modular kit; add coarse architecture. Example texture sets and detailed/coarse Commons GLBs with multi-angle review captures. | 270 | 100 | CB-M1 scale/view checks |
| CB-M3 | Profile baseline versus new area; reduce costs as necessary; clean export smoke; independent evaluation; publish review webpage/build. Example `art/ship-commons-v1/README.md`, capture/benchmark evidence and installable Mac update. | 180 | 150 | CB-M2 reviewed prototype |
| **Total** | | **670** | **380** | **1,050** |

Each milestone uses the matching CB acceptance criteria from the design, with results in sprint JSON. Planned game tools: `tools/validate_ship_commons.gd`, `tests/test_ship_commons.gd`, `tools/ship_commons_capture.gd` and benchmark extension. Blender generators run only through the Blender workspace launcher and bundled bpy; they belong to that authoring repo, not a new game Python pipeline.

## Session sequence

1. Survey current master, geometry/collision budget and fixed camera captures. Create reproducible flat blockout and walk connection; inspect renders before paint.
2. Test one texture/material set across front/back/overlook/lift cameras in the actual game. Refine colour/ink and export, then build the remaining small kit.
3. Profile and derive coarse representation, check baseline/delta and regressions, obtain independent evaluation, and deliver review build/web evidence. Reserve up to two further sessions for paint/performance iteration. Laptop performance signoff stays pending until actual Air measurements pass.

## Registry reuse

All three milestones: `none` for new package dependencies. They author Blender geometry/materials and Godot presentation/checks; no new package-like math capability is proposed. Reuse local observer, sky, WALK, lift and benchmark code. The geometry sprint's registry audit (`geometry`, `navigation`, `rendering`; celestial/a2ui inspected) found no suitable asset authoring package. Existing pinned relativity package stays unchanged. Any newly discovered simulation/physics requirement triggers a separate package-first design, not a local formula.

## Approval and handoff

Approval covers the bounded Commons area, multi-angle material proof, coarse export and draft delivery. It does not adopt the seven generated images as exact architectural plans or approve full-ship final dressing. After approval, hand off to sprint-executor; a different agent evaluates. No plan commit or modeling before approval, per project workflow.

## Execution checkpoint — 2026-10-04

- [x] CB-M1: measured pavilion/court and separate expanded Commons WALK;21 real route/capsule/inspection-eye checks, actual-mesh envelope/roof/door/shaft checks, Blender scene health and GLB reimport. Asset pin717967a.
- [x] CB-M2: embedded padded-UV paint atlas;8,708 detailed /3,036 coarse triangles, exact major opaque geometry preserved; shared runtime material, distance selection; nine inspected internal/diagnostic views with first-hit audit.
- [ ] CB-M3: Studio paired comparison, independent evaluation, export and draft reference/build publication underway. Actual M2 Air performance remains pending; this sprint is not complete until its performance gate is resolved.

The reached bridge overlook is floor/rail-occluded: centre ray first hits the actual
bridge deck. Arrival/court/interior provide useful views of the Commons. This is
recorded evidence of the geometry, not an excuse to make the floor transparent.

### Draft delivery validation, 2026-10-04

Full `make test` and `make golden` passed. Final `make ship-demo-ci`, packaged
`ship-demo-export-smoke`, bundled simulation/AI smokes and normal `export-smoke`
passed. The review website is live with the same-origin complete assembly model.

Final paired Studio measurements (M4 Max, 1920×1080, 300 frames per view):

| View | Baseline p95 ms | Commons p95 ms | Primitive delta |
|---|---:|---:|---:|
| Bridge | 9.564 | 9.479 | +8,708 |
| Overlook | 10.072 | 9.338 | +8,708 |
| Mid-lift | 26.549 | 9.544 | +8,708 |
| Courtyard | 9.846 | 9.580 | +8,696 |
| Overview | 9.618 | 9.639 | +3,024 |

The courtyard and overview deltas include removal of the old 12-triangle guard.
The reported video-memory delta is 7,421,952 bytes. Texture-counter delta zero
is not evidence that the embedded atlas costs nothing. Presentation/host timing
varies, especially the baseline mid-lift sample; no causal speedup is claimed.
Raw reports remain local under `renders/ship_demo/`. Actual M2 Air performance
is still required: CB-M3 and the sprint remain in progress.

Published Mac review: `v0.4.0-dev.6-commons-sky-review`, source
`447d7cafede916aecf3a15b2f9f2157ab9484768`. The public review hub is
https://www.sunholo.com/stapledons-godot/docs/ship-layer-reference (page and
same-origin model verified HTTP200; Pages deployment37220009708 succeeded).
The private latest build manifest and local ZIP both give SHA256
`694deef81ac070a636ebb4e77328823f32ac9ccf321473ec14e0183aa13ccca5`;
`unzip -tq` passed. Metadata is pinned in `art/ship-commons-v1/review-build.json`.
Remote source CI37220288520 is in progress. No production merge was performed.

## Continuation plan — approved by Mark, 2026-10-04

Authorization: “ok continue - lets alter the star brightness to trial it and build out the area more.”

1. Root: reuse Exposure.bias; baseline/2×/4×/16×/64× labelled controls, initial2×; meaningful
   state/ratio/lock checks and GPU/capture evidence. About80 code/check lines.
2. Commons executor: expand reusable detail within existing playable area; update
   Blender master, detailed/coarse exports, manifest, capsule/opacity checks and captures.
   Authoring estimate300–600 lines; art timing remains iterative, not LOC-predictable.
3. Separate evaluator: inspect both control behaviour and reachable painted area;
   root publishes the next draft build and review-page comparisons after checks.

Registry reuse: each step is rendering/authoring integration using existing Exposure,
asset kit and tests; no new package capability or physics formula. Actual M2 Air
performance still gates completion. Later levels open incrementally when playable.

### Continuation review checkpoint

Assets11b4009 / capture audit01a9be7: canopy, planted terrace, pavilion reading
furniture and reusable detail.13,976 detailed /7,224 coarse triangles, one1254² atlas.
Independent runtime25, extra route27, camera244 and journey47checks pass; GPU goldens
pass with all five known-lux exposure fixtures within1%. Exported demo and normal
simulation/AI/interior smoke checks pass. Final paired Studio profiling (1920×1080,
120warmup/300sample frames, same2×cruise setting):

| View | Baseline p95 ms | Expanded p95 ms | Primitive delta |
|---|---:|---:|---:|
| Bridge | 9.569 | 9.575 | +13,976 |
| Overlook | 9.554 | 9.578 | +13,976 |
| Mid-lift | 9.576 | 9.642 | +13,976 |
| Courtyard | 9.643 | 9.660 | +13,964 |
| Overview | 9.548 | 9.611 | +7,212 |

Video-memory counter delta7,782,400bytes. Raw machine diagnostics remain local.
The CPU-heavy full-suite process was suspended during this pair, then resumed.
This is Studio evidence only; actual Air and full sprint completion remain pending.
