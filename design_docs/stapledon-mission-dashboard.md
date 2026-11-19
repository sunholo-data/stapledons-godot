# Mission dashboard — Stapledon

Updated 2026-11-19, iteration 103. The rig went quiet three minutes after the pick reading, so the loop re-ran row 7m AC1 under D-147. It MISSED. Metered $0. A Sonnet 5.5 judge checked the record and the measurement (94 then 88, PASS).
R1: clauses 1–3 are MET. Clause 4 is UNMET: 7m AC1 now has a measured MISS, row 7m is reopened, and row 7av is the next step. Clause 5 is ongoing. Goal unmoved.
Key result: of 6 quiet-rig `make bench SCENE=bridge` runs on main `e29a36c0`, 1 counted (docked control 16.60 ≤ 16.7), and its transit p99 was 16.813 ms against 16.7. Iteration 75's base `8c570d1e` gave the same spread (16.24–16.81), so there is no evidence of a regression (n=6 against n=3, overlapping ranges). The hitch tail decides it: 23–47 frames over 16.7 ms per run, max 55–98 ms, with p50 about 10.6 ms. Evidence: `design_docs/reports/7m-ac1-iteration-103.md`.
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no code change on main since iteration 102's record (`e29a36c0`); the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly: no run since `b0c4d751`. Its 2 reds are both in attended files: `ui-theme-check` (row 7as, telescope UI) and `basis-gate` (row 7at, `demos/ship_finish_review.gd:74`). Issue #392 stays open.
Lanes: the fleet says the mission codex daemon (codex-cli 0.162.1) returns `model_not_found` for `gpt-6.2-sol`, so the codex planner and executor lanes are degraded until the rig daemon is upgraded (D-FLEET-47, Mark's). This fire needed neither.
Next: 7av, a design that attributes the transit hitch tail and proposes a fix with headroom (target p99 ≤ 16.2 on valid-control runs). It needs a quiet rig for its measurements, and the codex lane must be probed before routing a planner or executor to it.
Owed: the L4 M1b baseline (three comparable serial gmake runs and one 3.81 run, each at sampled load ≤ 5). It is PARKED-ON-LANE until the rig is quiet, and M2 waits on it.
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0; the registry still has 0.1.0.
Watch: D-147's validity filter accepted the docked control in only 1 of 9 runs, so a countable AC1 run is rare even on a quiet rig.
Human gates: D-166 OPEN (whether a same-vendor judge may stand in when the cross-vendor judge gives no verdict; default C applied). D-168 OPEN (the queue was hygiene-only; under B the loop idles until the rig is quiet or #435 merges, and today the rig was quiet).
Action for Mark (not a ledger decision): rows 7as and 7at, the two attended nightly reds. GPU scheduling: local-model work holds the GPU at most picks, which blocks 7av's measurements and the nightly golden. D-FLEET-47: upgrade the mission codex daemon. AC1 counting: D-147's validity filter accepted 1 of 9 docked controls (7m-d's S1 band is 17–19 ms), so AC1 is rarely countable, and 7av cannot show a pass on valid-control runs unless the controls improve. Say if you want the OQ2/OQ4/OQ5 route reopened (a physical display, the floor recorded beside the control, a relative gate; yours alone).
Routing this fire: controller Opus 5.5 (also ran the measurement, the row's named role), plus a Sonnet 5.5 evaluator (Agent tool). No designer, planner or executor ran.
Harness share: 11/19 tagged as HARNESS over iterations 83–103 (rows 83–88 and 94–98); 99–102 are ADMIN and 103 is REFUTATION.
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`); this record and the bench were run from fresh clones of `origin/main` under `/tmp/stap-iter103/`.
Full history: stapledon-mission-log.md, entry 103.
