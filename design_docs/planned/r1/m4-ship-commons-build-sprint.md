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
