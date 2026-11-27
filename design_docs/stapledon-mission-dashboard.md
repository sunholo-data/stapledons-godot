# Mission dashboard — Stapledon

Updated 2026-11-27, iteration 125. Another record-only fire (nothing to build until you rule). Its one input: **the fleet fixed the loop's idle skip so a red nightly now wakes it** (row 7az, sunholo-data/ailang#2481). Until today, a fire with nothing else new was skipped even when the nightly on #392 had gone red. The loop checked that the fix is in the driver it runs on before marking the row resolved. Tonight's nightly report is the first that should wake a fire, and that fire is the chance to catch the intermittent sim-start failure (row 7ay) while it happens.
Still running (row 7ba): **the orphaned nightly test, process 84274, has now run for 14 hours** (since 05:11Z) in a deleted clone, using about a quarter of one core. The loop did not kill it.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 (frames during the live transit must stay under 16.7 ms, judged on the slowest 1 % of frames, the p99) has one counted miss on a valid run, 17.338 ms (iteration 107); row 7av waits on D-172. Clause 5 is ongoing. This iteration did not move the goal.
Last design: `design_docs/implemented/r1/rig-profile-secret-hygiene.md` (iteration 114).
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2). AILANG v0.64.1 is on the rig's PATH; a bump is attended work.
Current: main is `657a356c` (iteration 124's record). Fast tier green.
Visible: nothing new, so no dev build is needed.
Nightly: red, 7 targets on `468ceb97` (#392, 40 comments); no nightly since. Tonight's run is the next chance to catch the failure.
Lanes: the driver resolved codex `gpt-6.2-sol` for planner and executor; neither ran. Controller Opus 5.5; judge Sonnet 5.5 (Agent tool).
Next: record-only fires under D-168 B unless you rule. If a fire follows a nightly with these failures, it re-runs the throwaway copy of the test that prints the sim's error and lists running `godot` and `ailang` processes (7ay a). No code change.
Still waiting: D-172 (default record-only on 7av: no publish, no O3).
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0 (latest is v0.1.0).
Package: ailang-packages#206 (social_dynamics 0.4.1) is OPEN, unmerged and unpublished.
Human gates, all OPEN:
- **D-176**: may the loop build the two small nightly fixes (7ba and 7ay b) ahead of D-168 B? Recommendation A (yes); default B (stay record-only).
- D-175: keep loop evidence in the public bucket behind the guard (A, default), or move it to the private dev-builds bucket (B)?
- D-174: its default A ran in iteration 114 (7aw landed).
- D-173: approve the rule that a timing run counts when the CPU used outside it stays low (OQ1 with OQ3), the baseline source (OQ2), OQ4–OQ5; or choose B, C or D.
- D-172: publish 0.4.1 and crew_core 0.6.1, and is O3 next? Recommendation C.
- D-171: its default A ran; B is open.
- D-170: its default A ran in iteration 108.
- D-169: GPU window.
- D-166: default C applied (same-vendor judge on a tooling doc or record, flagged).
- D-168: C applied; in its B half (record-only fires).
Action for Mark (not a ledger decision):
- **Kill the orphaned test** when convenient: `kill 84274` (row 7ba).
- **Two small fixes ahead of D-168 B? (D-176)** 7ba (the gate passes the watchdog's stop signal on to its test) and 7ay (b) (a failed sim start fails at once instead of hanging for 600 s). Both are headless and a few lines. Together they stop one bad start from taking down the rest of a night.
- **The nightly (7ay):** the failures appear only overnight. Does anything run on the Studio at night but not by day (local-model evals, backups, indexing)?
- **Rotate the exposed credentials** (names in the private `[SECURITY]` message) and refresh the rig's environment cache. One old dump is left (`328b01f8`).
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds).
- GPU scheduling.
- D-FLEET-47.
Cadence: armed six-hour driver; unchanged fires are skipped (7ax), and a new nightly report on #392 now counts as a change (7az).
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter125`.
Full history: stapledon-mission-log.md, entry 125.
