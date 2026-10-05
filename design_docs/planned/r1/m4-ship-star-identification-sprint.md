# Ship star identification sprint

Status: Approved by Mark,5October2026: “yep continue”; implementation in progress. Design: [m4-ship-star-identification.md](m4-ship-star-identification.md). Bounded deliverable: identify known, visible sky stars from the current ship demo; read existing catalogue facts; explicitly open the existing map on the same ID.

Recent evidence: the live journey implementation and native export/viewport correction completed in one attended iteration; Commons required authoring and separate review. This feature has new identity/projection/occlusion integration, so estimate two focused sessions plus native/GPU evaluation rather than promise a fixed completion time. Estimate450–650implementation/testLOC.

## SI-A: exact identity and shared data (session1)

Inspect AILANG tier/map producers for existing identity association, add hash-pinned row identity sidecars if needed, carry IDs through renderer filters and build a shared read-only metadata lookup. Candidate files: `sim/tools/catalogue.ail`, `sim/tools/bright.ail`, `sky/star_catalogue.gd`, `sky/starfield.gd`, new `ui/star_info.gd`, `tests/test_ship_star_identification.gd`. Dependencies: current pinned catalogue. Checks: SI1; actual Sirius/AlphaCentauri IDs, filtered missing-photometry rows, stale pair and duplicates.150–220LOC.

## SI-B: native identification interaction (sessions1–2)

Add holdI rings/hover, deterministic overlap candidate list, read-only card and exact-ID Open in map. Derive apparent positions from the actual active sky state and camera; preserve rebase precision and perform actual opaque-mesh visibility rejection. Candidate files: new `ui/ship_star_identification.gd`, shared presentation helper, `demos/ship_geometry_demo.gd`, `ui/galaxy_map.gd`, `tests/test_ship_star_identification.gd`. Dependencies: SI-A. Checks: SI2/4/5, pressed/released/focus loss and Option-drag conflicts, no mutation or clock pause.200–280LOC.

## SI-C: physics/native validation and review (session2 + evaluation)

Add GPU capture cases and compare star-centre alignment (<=1px for resolvable sources), occlusion fixtures with visual mesh lacking collider, small native window card/map handoff, real live boost/cruise/brake replay, overlay baseline/on benchmark and packaged runtime-independent smoke. Candidate files: `tools/ship_star_identification_capture.gd`, `tools/ship_star_identification_bench.gd`, `tests/test_ship_star_identification.gd`, `Makefile`, art manifests and reference-page controls. Dependencies: SI-B.100–150LOC.

Run new named Make targets in design, existing `make ui ship-demo-ci`, appropriate full regression and `make golden`. Generator≠judge independent evaluator must assess identity, projected physics, occlusion and actual click interaction. No physics formulas outside the package. Publish the next draft Mac build and reference evidence only after passing source/native/golden/evaluation gates. Actual M2Air performance remains user-hardware signoff; do not merge production before its applicable gates pass.

Approval checkpoint satisfied by Mark’s attended response. Approved plan handed to sprint-executor; separate evaluation follows implementation. Current dev9 remains the deployed build.
