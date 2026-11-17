# Playable voyage acceptance: executor evidence

**Status:** PV2 implemented and verified headlessly; PV1/PV3 await the parent-owned final qualification items below. PV4 human review remains pending. No GPU, build, publication or external message was performed by this strand.
**Date:** 2026-11-17. **Code checkpoint:** `c34d8869a261eb7fcc10ae233147cbe987fb5cbb`; shared readiness SF0 was cherry-picked as `098f389e`; combined main baseline `ec415f339575a7127f7c9d8643c6067db3011199` includes upstream `ae5394dd8299c3f433891e1b0e1b643a57001139`. Parent make includes are `a03c147e` (original `bdf7df78`); evidence export exclusion is `ff367e28`. Later changes in this strand are evidence/documentation/export policy only, with no gameplay, sim, package or renderer changes.

## What works

The normal title's New game route waits for the shared painted-ship readiness observer before the harness takes control of frames. It verifies installed resources for 141 bridge meshes, 1000 Commons meshes, 42 painted residents and two portrait-bound crew. The new `tests/playthrough_complete_voyage.json` then flies Sol → alpha Centauri A → Sol through the real Navigation and Archive APIs and real AILANG sim.

The completed run contains one new_game and exactly two commitments. Both legs supply boosting, cruising and braking, both arrivals are observed, and it ends at Sol in `arrived`/`at_rest`. Destination news is read at tick 1206; home news and the final voyage log are read at tick 2423. The two home UI reads legitimately share a simulation tick; event order distinguishes them.

The final sim clock reports approximately 1.231442 ship-years and 8.729403 Earth-years, from an initial clock near zero. These are observed catalogue-route values, not replacements for the fixed 4.37 ly HB reference case. Exact values are retained in the manifest. The display audit checks the presented values against sampled sim state.

The new completion contract is test-only. It adds no gameplay decision, lore, save/reload, protocol field or physics formula. The original minimum fixture, scene input/golden and historical timing auditor are byte-identical to the integration baseline; [frozen pins](../../../art/playable-voyage-review/frozen-pins.json) retain their hashes.

## Results

Pinned runtime: AILANG v0.56.1 (`05c860a`), Godot `4.7.2.stable.official.ed1daf0bf`. [Evidence manifest](../../../art/playable-voyage-review/evidence.json) records source, script, lock, runtime and resource hashes. [Qualification results](../../../art/playable-voyage-review/qualification-results.json) retains every command, raw log and observed result.

| Check | Observed result |
|---|---|
| Complete-voyage positive | `playthrough: 143640 passed, 0 failures`; endpoint reports exactly 2 commitments, 2 arrivals and 3 ordered location-bound reads |
| Complete-voyage display audit | 817 samples, 259146 checks; zero mismatches, missing bindings, new findings or failures; existing D-77/D-78 findings remain explicitly accepted |
| Completion observer unit cases | 14 passed, 0 failures |
| Six real-scene rejection controls | 6 passed, 0 failures as a control suite; omitted return/home news/final log each exits 1 for its named reason under a 1200 s deadline; no parse error/timeout counts as a rejection |
| Historical minimum-path proxy | 250.29645164012905 synthetic seconds; legs 60.15 s and 60.75 s, each within 45–120 s; existing ≤ 360 s gate passes |
| Title, live journey, no-twitch, adversarial | Title 111/0; live-sim 17/0 and live-demo 9/0; no-twitch 41/0; adversarial 144639/0, including the expected irreversible refusals |
| Camera/route/chair and existing crew/comms/review |`levels-regress`, `camera-test`, `camera-forward-test`, `comms-walk-test`, `captain-chair-test`, `captain-command-test`, `crew-console-test`, `comms-station-test`, and the crew/comms/interlude display audits pass |
| AI fallback/recording compatibility |`playthrough-ai-modes` passes: stub telling voiced once; digits refused with authored telling retained; no provider key required |
| Strict core |`make strict` passes the VM/interpreter/reference matrix, 258 s |
| Existing M4 parity |`make parity-m4` passes, 194 s, including state-unchanged refusal evidence and positive replay divergence control |
| Frozen scene replay |`make replay-scene` passes, 52 s; VM-only current check, interpreter proof retained at original record time |
| Policy/UID/precision | Python guard, 481 tracked UIDs, silent-audio guard and precision lint pass; script-gate lint passes 284 invocations/39 includes |
| Voyage evidence export scope |Actual Godot export-audit matcher excludes 18 nonhidden evidence files; `art/playable-voyage-review/*` also covers the archived qualification subdirectory |

Twenty of the 21 planned compatibility targets pass. `ship-console-test` initially stopped before its assertions because the ignored historical baseline cache was absent and DNS was unavailable. The locally available baseline was then copied and all three published pins verified. Its targeted retry remains parent-owned; the direct complete voyage already exercised the current Navigation/Archive flow successfully. No threshold or test expectation was weakened.

## Test-first witnesses

1. The initial observer test failed because the completion contract did not exist. After implementation, 14 focused cases pass, including duplicate away news, stale read ticks, extra commitments, a restart, missing return phases and missing endpoints.
2. Before integrating the observer into the real harness, the old driver accepted the missing-home-news route (`143079/0`, 111 s). Its [raw witness](../../../art/playable-voyage-review/old-driver-missing-home-news.log) is retained.
3. With the observer enabled, the real incomplete routes fail for `completion missing return to Sol at rest`, `completion missing home news` and `completion missing final home log`. [Control summary](../../../art/playable-voyage-review/negative-controls.log) links to the individual logs through the manifest.

The implementation checkpoint changed 14 files, adding 452 lines and removing 35, including verbose JSON fixtures and progress/changelog documentation. This exceeded the 310-line planning estimate without adding gameplay scope. Evidence logs/data are separate from that implementation count.

## Evidence interpretation and friction

- **Synthetic time:** the historical auditor still charges walking at 3.5 m/s; actual movement remains D-138's 2.2 m/s. 250.3 s is the declared proxy's result, not measured human play time. No divisor, limit or frozen recording was changed.
- **Source identity:** readiness reports `packed:false`. The runtime directory copied from integration carried a historical `build_version.txt` label; that label is not the tested source commit or proof of an installed review build. Source and resource hashes are recorded separately. The ship strand owns the source-label correction.
- **Batch wrapper:** an outer Godot-only script guard misread nested successful make output containing the literal `no SCRIPT ERROR`. Individual raw make results retain an `&& qualification` success sentinel; stripping that exact success phrase leaves no actual SCRIPT ERROR. The manifest preserves wrapper status separately, and does not turn a failing make into a pass. No green behavioral target was repeated for this logging mistake.
- **Export policy:** child `export-filter-audit` predates the parent's CP2 closure and reports three inherited unclassified painter-directory literals. The narrow evidence exclusion itself passes the existing Godot matcher. The parent reported a green combined CP2 closure and must retain both its `art/content-pipeline/*` exclusion and this strand's evidence exclusion when integrating the single preset line.
- **No native verdict:** source/headless tests do not certify painted appearance, audible mix, frame pacing or human discovery. The human/native states in the manifest remain pending.

## Remaining parent-owned qualification

1. Retry `ship-console-test` with the pin-verified baseline cache available. In this clone it is `build/ship-baseline/`; preserve the published pin checks.
2. The parent reports SF1b live route 18/0 in 24 s; its final pinned witness remains parent-owned. Combined `ci-fast` is running at parent `ab17b45d`, and the parent is reconciling runtime-path fix `f4b3f307` before final acceptance. This strand released its sidecar slot after the planned batch and starts no further strict/parity repetitions.
3. The new complete recording's direct VM/interpreter comparison has **not** been run. Existing M4 parity and the frozen scene replay above are separate evidence. The preserved input is [complete-session.ndjson](../../../art/playable-voyage-review/complete-session.ndjson), SHA256 `461f705102a7d160b22f4f211616adca737fbfd99fbd9ac232f5dfad3f9a1375`; use design AC6's direct producers/`cmp` if this criterion is retained. `make replay SESSION=...` requires an existing golden and must not be presented as a passing new-session comparison.
4. Finalize independent evaluation against the combined tree. The parent reported a conditional 82 with no blocking code defect; that is not recorded here as unconditional landing approval.
5. PV4 remains the separately proposed attended owner review. No new fresh-player R1 gate is asserted: D-14's scripted proxy remains the historical R1 requirement and its three-new-player study remains R2 work.

No design/sprint document is moved to `implemented/` and no whole-sprint completion is claimed while these conditions remain. The parent integrates the scoped commits and records the final disposition.
