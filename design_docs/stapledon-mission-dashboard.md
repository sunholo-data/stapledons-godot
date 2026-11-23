# Mission dashboard — Stapledon

Updated 2026-11-23, iteration 110. The rig was quiet, so the loop took up L4's test-speed baseline (M1b, step 1f), and Gate 2 refuted it before any rig hours were spent. Metered $0. A Sonnet 5.5 judge scored it 92 PASS, 0 blocking.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 has one counted valid-control MISS (17.338 ms against 16.7, iteration 107); row 7av waits on D-172. Clause 5 is ongoing.
Last result: `design_docs/planned/r1/rig-test-speed-1f-load-rule-finding.md`.
- The rule that decides which timing runs count (AC9: load max ≤ 5, or median ≤ 5 and max ≤ 8) rejects every run.
- The nightly's three instrumented serial runs on main span 6,188–6,213 s (within 0.4 %), median load 3.5–4.0, max 10.4–13.3: all `loaded`.
- The suite makes part of that load: `worlds-leak` (four AILANG workers) alone on a quiet rig reads max 8.05–10.86, about 84 % of host CPU its own.
- Every run on main is also refused as `rc=2` while the two attended nightly reds (7as, 7at) stand.
Evidence: `gs://stapledons-voyage-assets/benchmarks/l4-1f-iter110/l4-1f-iter110-evidence.tgz` (sha256 `7d614b67…ff57`).
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no game code change on main since iteration 102's record. Main is `17623c04` (iteration 109's record), and the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly: #392 stays open on the 2 attended reds, `ui-theme-check` (7as) and `basis-gate` (7at); they now also block L4.
Lanes: codex `gpt-6.2-sol` was over its daily ration (probe rc 75); no designer, planner or executor was needed. Controller Opus 5.5; judge Sonnet 5.5 (Agent tool). The four fires before this one (2026-11-22 to 23) parked on controller lanes.
Next: D-173. Without an answer, the loop writes A's design doc and quorum only (no code) and stops for your OK.
Still waiting: D-172 (default record-only on 7av: no publish, no O3).
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0.
Watch: off-cadence bursts of slow replies, and the remaining ~44 ms of the decision step; both UNMEASURED.
Package: ailang-packages#206 (social_dynamics 0.4.1) is OPEN, unmerged and unpublished.
Human gates, all OPEN:
- D-173 (new): change the L4 load rule, wait for a green main, count span agreement only, or shelve L4? Recommendation A.
- D-172: publish 0.4.1 and crew_core 0.6.1, and is O3 next? Recommendation C.
- D-171: its default A ran; B is open.
- D-170: its default A ran in iteration 108.
- D-169: GPU window.
- D-166: default C applied.
- D-168: C applied (its idle ends when the rig is quiet; it was today).
Action for Mark (not a ledger decision):
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds).
- GPU scheduling.
- D-FLEET-47.
Routing this fire: controller Opus 5.5; evaluator Sonnet 5.5 (Agent tool). No designer, planner or executor (Gate 2 refutation).
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter110`.
Full history: stapledon-mission-log.md, entry 110.
