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

## HiDPI report follow-up

The requested measurement window remains 1920×1080. Each material condition, phase and longer repeat now also records the actual `Window.size` API value, root viewport `get_visible_rect().size` in viewport coordinate units, and root/ship/sky `ViewportTexture.get_size()` render-target dimensions in texels. These are separate observations: the root texture may differ from the window or logical viewport on a HiDPI display. They do not claim an independently measured macOS compositor framebuffer. `DisplayServer.screen_get_scale()` records the OS-reported display scale, alongside window content scale, screen index and reported DPI; it is not used to infer texture dimensions or alter the measurement resolution.

Validation requires positive finite observed sizes and scale, checks the recorded window against the report resolution, and rejects dimension/scale changes between material conditions or phases. The focused report fixture explicitly accepts a 1920×1080 window with a 3840×2160 root texture, and rejects missing/zero dimensions, missing/zero display scale and inconsistent phase targets. RED: 14 passed, 6 failures before validation; GREEN: **20 passed, 0 failures**, using only `tests/test_ship_finish_report.gd` through `SCRIPT_GATE`. No GPU or native report was generated.

The validator must run against the matching reviewed source/manifest revision for the installed archive: it compares recorded manifests with local file hashes, rather than fetching or reconstructing a historical source tree. Its schema, consistency and fixture checks support attended native review. They are **not cryptographic attestation** of the machine, execution or report author; a deliberately edited JSON file can invent consistent observations. Actual hardware identity, provenance and visual acceptance require the attended session and Mark's verdict.

## Packed runtime entry correction

Parent inspection of the actual combined ZIP found a blocking packaging defect: the release-supported entry dynamically loaded `tools/ship_finish_review.gd`, while `tools/*` is intentionally excluded. The source/headless checks had not proved the runtime module shipped. The implementation and its UID now live at `demos/ship_finish_review.gd`; main, report/route tests and the developer report CLI reference that path. `tools/ship_finish_report_check.gd` remains developer-only, and the tools exclusion is unchanged.

`ExportAudit.PACKED_RUNTIME_SCRIPTS` now requires both the compiled runtime script and its `.gd.remap` entry, independent of the broad dev-tools exemption. The static audit refuses excluding or deleting this runtime module; the normal pack oracle always checks its forms. A focused pack test rejects a missing script or remap, then checks an actual ZIP.

| Check | Result |
|---|---|
| New witness against parent's previous `...integration-20261117/.godot/tmp/export-pack/game.zip` | RED: 4 passed, 1 failure; both `demos/ship_finish_review.gdc` and its remap absent. |
| Headless corrected export | `godot --headless --path . --export-pack macOS .godot/tmp/ship-finish-runtime.zip`, exit 0; **132,384,777 bytes**, SHA-256 `2b181f302e9ae913d7e41a5d94cf9dd1a2758f70a176d589db0375a7e20deb69`. |
| Corrected actual ZIP witness | `make ship-finish-pack-test PACK=.godot/tmp/ship-finish-runtime.zip`: **5 passed, 0 failures**. ZIP lists runtime `.gdc` and `.gd.remap`; excluded tools implementation is absent. |
| Actual packed main/route load | Launching that ZIP with `godot --headless --main-pack ... -- --ship-finish-review=/private/tmp/...` reaches explicit headless refusal, expected exit **2**, no `SCRIPT ERROR`. This proves dynamic packed loading without GPU work. |
| Focused regressions | Profile **15/0**, report **20/0**, source headless refusal expected **2**, static export audit including new exclusion control **18/0**. |

This scoped export proves the runtime entry closure and actual packed loading; it is not a replacement for parent's fully staged strict export pack, application archive or laptop review. This clone did not copy all ignored production bundles. No native appearance/timing or publication is claimed.
