# Mission dashboard — Stapledon

Updated 2026-11-19, iteration 104. Record-only fire under D-168 B (the fifth completed; 103 began as one and became a measurement): the rig was busy at pick (1-min load over the bound of 5), so row 7av stayed parked. Metered $0. A Sonnet 5.5 judge checked the record.
R1: clauses 1–3 are MET. Clause 4 is UNMET: 7m AC1 has a measured MISS (iteration 103), row 7m is reopened, and row 7av is the next step. Clause 5 is ongoing. Goal unmoved.
Last result: iteration 103's quiet-rig bench. 1 of 6 runs counted (docked control 16.60 ≤ 16.7) and its transit p99 was 16.813 ms against 16.7, with no evidence of a regression against iteration 75's base. Evidence: `design_docs/reports/7m-ac1-iteration-103.md`.
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no code change on main since iteration 102's record; main is `8ac43a1d` (iteration 103's record) and the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly: no run since `b0c4d751`. Its 2 reds are both in attended files: `ui-theme-check` (row 7as, telescope UI) and `basis-gate` (row 7at, `demos/ship_finish_review.gd:74`). Issue #392 stays open.
Lanes: codex was over its daily ration this fire (probe rc 75), so the driver handed the planner to `pi:ollama/kimi-k3:cloud` and the executor to `claude:claude-haiku-5-5`; neither ran. The fleet also reports the mission codex daemon returns `model_not_found` for `gpt-6.2-sol` (D-FLEET-47, Mark's).
Next: 7av, a design that attributes the transit hitch tail and proposes a fix with headroom (target p99 ≤ 16.2 on valid-control runs). It needs `quiet2.sh` YES (GPU < 15 three times, 1-min load < 5, HID idle > 600 s, no remote session) before and 3 s after each measurement. At this pick: NO twice (load 8.23 then 7.44; Ollama holds `qwen3.8:27b-mxfp8` on the GPU).
Owed: the L4 M1b baseline (three comparable serial gmake runs and one 3.81 run, each at sampled load ≤ 5). It is PARKED-ON-LANE until the rig is quiet, and M2 waits on it.
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0; the registry still has 0.1.0.
Watch: D-147's validity filter accepted the docked control in only 1 of 9 runs, so a countable AC1 run is rare even on a quiet rig.
Human gates: D-166 OPEN (whether a same-vendor judge may stand in when the cross-vendor judge gives no verdict; default C applied). D-168 OPEN (the queue was hygiene-only; under B the loop idles until the rig is quiet or #435 merges).
Action for Mark (not a ledger decision): rows 7as and 7at, the two attended nightly reds. GPU scheduling: local-model work holds the GPU or the CPU at most picks, which blocks 7av's measurements and the nightly golden. D-FLEET-47: upgrade the mission codex daemon. AC1 counting: say if you want the OQ2/OQ4/OQ5 route reopened (a physical display, the floor recorded beside the control, a relative gate; yours alone).
Routing this fire: controller Opus 5.5, plus a Sonnet 5.5 evaluator (Agent tool) on the record. No designer, planner or executor ran.
Harness share: 10/19 tagged as HARNESS over iterations 84–104 (rows 84–88 and 94–98; 89 untagged, 92 has no entry); 90, 91 and 93 are PRODUCT, 99–102 and 104 ADMIN, and 103 REFUTATION.
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`); this record was written in a fresh clone of `origin/main` at `/tmp/stap-iter104/repo`.
Full history: stapledon-mission-log.md, entry 104.
