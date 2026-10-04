# Sprint: bridge overlook and one-tier lift

**ID:** R1-M4-SHIP-DEMO. **Status:** approved by Mark in attended session 2026-10-04; execution started.
**Design:** [m4-ship-geometry-demo.md](m4-ship-geometry-demo.md).
**Scope:** Seven major tiers, accepted 5 m lower-floor buffer, correct perspective bridge views, one physical lift from +82 to +57 m and back. No full exploration system or finished architectural dressing.
**Risk:** medium, principally camera/paint compatibility and a real lift opening.

## Evidence and estimate

Recent source reviewed: `2899e70` recovery has the painted bridge, faster walking and duplicate-spire fix; art branch `90090b3` selects seven tiers/clearance. Earlier M4 sprint planning recorded ~2,300 LOC/day from attended work, but concurrent large milestones and documentation commits are not reliable velocity for this camera/art spike. Do not treat generated Blender vertices as implementation velocity.

Plan 1,560 code/test/tool lines in four bounded milestones; 3–5 focused working sessions including geometry/GPU and art review, with extra iteration possible for camera/paint. No completion-date promise. The first overlook is a separate reviewable output before the lift.

## Registry reuse gate (checked 2026-10-04)

Searches with pinned AILANG v0.52.0: `pkg search geometry`, `navigation`, `rendering`.
Navigation: no result. Candidates `sunholo/celestial` and `sunholo/a2ui` inspected using `pkg info`/`pkg docs`: celestial handles astronomical orbits, not ship geometry; a2ui is declarative UI JSON, not 3D rendering. No new package is appropriate. Existing sky/physics keeps the project's current `sunholo/relativity` 0.7.0 pin unchanged. Every milestone's new work is Godot presentation, Blender authoring or checks; reuse local frame/walk/avatar/sky helpers where suitable.

## Milestones and concrete work

1. **SD1 — measured assets and lift route (280 LOC).** Derive `assets/ship_demo/manifest.json`, bridge demo GLB, first-tier landing and coarse remaining tier meshes from master Blender collections. Add `tools/validate_ship_demo.gd` and a tiny geometry fixture. Check capsule path and platform openings at the existing pad before committing to motion. Example: `demos/ship_geometry_demo.tscn`, initially geometry-only. Registry: **none**, Blender/Godot asset responsibility.
2. **SD2 — overlook and pullback (500 LOC).** Add `demos/ship_geometry_demo.gd`, `demos/ship_demo_camera.gd`, camera controls and labeled reference presets; match sky projection and expose native materials for off-axis views. Add `tests/test_ship_demo.gd`, `tools/ship_demo_capture.gd`, Makefile `ship-demo-test`, `ship-demo-capture`, `ship-demo-smoke`, `validate-ship-demo`, and `run-ship-demo` targets. Example: captain, correct bridge floor/rail occlusion, all six lower visual tiers, whole-ship pullback. Registry: **none**, reuse existing Godot sky/frame helpers without new package maths.
3. **SD3 — lift and landing (460 LOC).** Add `demos/ship_demo_lift.gd`, guarded openings, platform attachment and state machine. Only active landing contributes walking triangles; add stacked-floor/boarding/re-entry/round-trip tests and scripted capture route. Example: walk to pad, descend 25 m, walk safe landing, return. Registry: **none**, Godot presentation transport; no new simulation protocol.
4. **SD4 — resource review and laptop build (320 LOC).** Add benchmark/export-smoke tooling, capture manifests and demo README; compare four camera states and record actual laptop hardware/frame times. Add `ship-demo-bench`, `ship-demo-export-smoke`. Run current compatibility gates, independent evaluation, then publish development app/captures and reference-hub evidence. Registry: **none**, local Godot instrumentation and existing release scripts.

## Session order

- Session 1: SD1, geometry audit and approved-reference comparison.
- Sessions 2–3: SD2, inspect and present the overlook; keep the current production bridge untouched.
- Session 3–4: SD3 after the viewpoint result is sound; prove openings and safe return.
- Session 4–5: SD4, laptop performance and package/install verification. Do not dress the full ship to hide unresolved geometry/camera problems.

## Completion and handoff

The design's GEO/VIEW/WALK/LIFT/PERF/COMPAT/SHIP criteria define completion. Track actual results, not inferred passes, in `.ailang/state/sprints/sprint_R1-M4-SHIP-DEMO.json`. All gates/commands in this plan are future interfaces except the existing compatibility/release commands. Approval received; use sprint-executor and maintain progress in this implementation tree. Independent evaluation is required before production landing.
