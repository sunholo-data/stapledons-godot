# PLAYABLE-SHIP-FINISH: headless execution evidence

**Date:** 2026-11-17. **Scope:** approved SF0, SF1a, SF1b only. **Branch:** `sprint/playable-ship`, isolated clone `/private/tmp/stapledons-playable-ship-20261117`. Based on candidate `19e4a763`, approved planning integration `7b00bf6b`, then current-main integration `ec415f33`. No GPU, archive build, external send, push or publication performed.

SF0 and SF1a pass their focused headless gates. SF1b's code and static/report controls pass; its real-transit wiring fixture is explicitly pending the serialized simulation slot. SF2 is not complete. No laptop/native timing, screenshots, lighting or S3/S5/CA visual acceptance is claimed.

## What changed

`ShipReviewReadiness.wait(demo, timeout_ms)` observes main's existing civic/physics/paint sequence and fails closed on missing/stalled/failed closure. It validates installed counts, meshes and production manifest/captain identity. Source/editor runs always identify as unexported; a copied runtime build stamp is retained separately as historical metadata. The voyage harness consumes the same helper.

`ShipDemoBenchmark` now has an explicit local-only persistence boundary and reusable sampler. Local mode never calls the uploader, including for the existing default filename; existing callers keep their default upload behavior. The writer injection seam lets tests execute real scratch-file I/O while preserving the player's `user://` directory. Raw-sample validation rejects nonfinite data, insufficient counts and summaries inconsistent with samples. Metal GPU timing is unavailable, not a zero-cost measurement.

The new `--ship-finish-review=<absolute-output-directory>` route enters the actual normal game installation twice with seed 424242, producing original-material and painted-material conditions. It uses authored Commons stage spawns, normal lift/chair/console APIs and the existing walk/open/select/commit navigation sequence. Both conditions restore painted resources and retain pinned identity. Each required phase records inputs, camera, state and samples; a p99 miss requests two 1,500-frame repeats. The validator refuses stale/mixed identities, missing phases/conditions and synthetic target confirmation. Fixtures are explicitly labelled and rejected by the normal report CLI. `make ship-finish-review-report REPORT=<path>` validates the report structure; it does not manufacture Mark's verdict.

## Focused evidence

Fresh clone prep: `godot --headless --path . --log-file /private/tmp/ship-import-engine.log --import`; no source `.godot` cache copied (fresh import about 72 MB). Godot 4.7.2; no `.ail` edits. All added test gates use `SCRIPT_GATE` with counted nonempty summaries and no `SCRIPT ERROR`.

| Check | Command (before parent includes mk fragment) | Result |
|---|---|---|
| SF0 RED | `godot --headless --path . --script tests/test_ship_review_readiness.gd` before helper | Missing shared helper: 0 passed, 1 failure, exit 1. |
| Readiness + source stamp | `make -f Makefile -f mk/ship-finish.mk ship-finish-test` | 14 passed, 0 failures; real normal-entry coroutine, stalled/missing/error/incomplete closure, wrong expected pins and restored-source controls. |
| Existing geometry/lift/restoration | same target | 1,168 passed, 0 failures. |
| SF1a RED | profile test before persistence boundary | Missing save method: 0 passed, 1 failure, exit 1. |
| Persistence/samples | `make -f Makefile -f mk/ship-finish.mk ship-finish-profile-test` | 15 passed, 0 failures; real scratch writes, uploader spy, default behavior, invalid path, raw count/summary/nonfinite controls. |
| SF1b RED | report test before native route module | Missing module: 0 passed, 1 failure, exit 1. |
| Report schema/control | same profile target | 14 passed, 0 failures, including actual JSON roundtrip (caught and fixed JSON numeric-array/dictionary comparison), fixture rejection, stale/mixed pins, missing phase/condition, target-confirmation and repeat controls. |
| Real main headless guard | same profile target | Expected exit 2 and explicit headless-refusal summary before any ship/sim is started. |
| Static route wiring | `make -f Makefile -f mk/ship-finish.mk ship-finish-route-test` | 17 passed, 0 failures with actual production scene. The headless fixture caught and fixed `auto=false` freezing lift movement; lift phase enables normal controller advancement. No fixture frame times are native evidence. |
| Legacy benchmark | `make ship-demo-benchmark-test` | 3 passed, 0 failures. |
| Whitespace | `git diff --check` | Pass. |
| Export classification | `make export-filter-audit` | Three pre-existing candidate literals unclassified: bridge/Commons authoring ROOT constants and painted resource directory. No new review literal flagged. Parent content agent owns the narrow classification fix; this strand did not change asset policy. |

No repeated full suite or GPU run was used. Existing resource-load warnings and Dummy-renderer exit leaks are present in scene tests; no `SCRIPT ERROR` was accepted by a gate. The live route's real sidecar qualification is prepared as `make -f Makefile -f mk/ship-finish.mk ship-finish-route-live-test AILANG=<pinned-runtime-path>`. It is held while the voyage batch owns the shared expensive-run slot, and must pass before SF1b's JSON `passes` becomes true.

## Handoff and limits

Parent integration adds `include mk/ship-finish.mk` and applies its own `bdf7df78` gate-audit compatibility change. The report validator compares resource pins with the source checkout in which it runs; use matching reviewed source for a packaged report. Normal `--dev` installation remains unchanged.

The native route has not been executed on a GPU or exported archive. Real-transit phase wiring still requires the headless live target above; actual presentation timing, window-clamp behavior, native scene lighting, reduced-motion review, process peak-memory attribution and manual acceptance remain open. The new route reports engine video/texture counters and OS memory metadata; it does not claim a measured process peak-RSS trace. The existing external publication rejection remains outside this implementation scope.
