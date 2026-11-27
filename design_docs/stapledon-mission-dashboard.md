# Mission dashboard — Stapledon

Updated 2026-11-27, iteration 123. Another record-only fire (nothing to build until you rule), but with real news: **main's nightly test run has gone red on new tests two nights running, with no code change.** It was red on the 2 known attended tests (7as, 7at) until 2026-11-26. Then it was red on 4 tests on `d2b2d125` and on 7 tests on `468ceb97`, and both runs went over the 2-hour limit. The commits in between only touch the loop's own records, so there is nothing to revert. The failing tests all start a child process: the sim, a fake sim, or the AI guard. Run by hand on the same code, one of them (star identification) passed 3 times for the controller and failed 3 times for the judge, the same way as in the nightly. So it fails on and off, inside the nightly and outside it. The sim on its own answers well inside its time limits even with the Studio busy. Why the start sometimes fails is not yet known: the runs that would have printed the error code all passed. One weak candidate: the global `ailang` on the Studio's PATH was rebuilt as v0.64.1 at 17:42Z on 2026-11-26, between the last passing night and the first failing one. The failing runs used the pinned v0.56.1, though. Row 7ay holds the measurements and the next step.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 (frames during the live transit must stay under 16.7 ms, judged on the slowest 1 % of frames, the p99) has one counted miss on a valid run, 17.338 ms (iteration 107); row 7av waits on D-172. Clause 5 is ongoing. This iteration did not move the goal.
What else was found: (1) one test turns a failed sim start into a 600-second hang (`tests/test_ship_star_identification.gd:84`). That hang is what pushed one night over the limit, because the suite normally needs 96–97 % of it. A small fix is described in 7ay (b), not built. (2) Since the skip fix (7ax), the driver skips a fire when nothing has changed. It does not count a red nightly as a change, so this fire ran only because of an inbox ack. A ticket went to the fleet loop (row 7az).
Last design: `design_docs/implemented/r1/rig-profile-secret-hygiene.md` (iteration 114).
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2). AILANG v0.64.1 is on the rig's PATH; a bump is attended work.
Current: main is `468ceb97` (iteration 122's record). Fast tier green.
Visible: nothing new, so no dev build is needed.
Nightly: red, 7 targets on `468ceb97` (#392, 39 comments); the run hit its 2-hour limit; see 7ay.
Lanes: the driver resolved codex `gpt-6.2-sol` for planner and executor; neither ran. Controller Opus 5.5; judge Sonnet 5.5 (Agent tool).
Next: record-only fires under D-168 B unless you rule; the next fire compares how the controller and the judge launched it, then repeats a throwaway copy of the failing test that prints the sim's error until a run fails (7ay a), with no code change.
Still waiting: D-172 (default record-only on 7av: no publish, no O3).
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0 (latest is v0.1.0).
Package: ailang-packages#206 (social_dynamics 0.4.1) is OPEN, unmerged and unpublished.
Human gates, all OPEN:
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
- **The nightly (7ay):** did anything change on the Studio on 2026-11-26 between about 05:00Z and 21:30Z? The sim-start tests now fail on and off on unchanged code.
- **Rotate the exposed credentials** (names in the private `[SECURITY]` message) and refresh the rig's environment cache. One old dump is left (`328b01f8`); the other aged out.
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds).
- GPU scheduling.
- D-FLEET-47.
Cadence: armed six-hour driver; unchanged fires are skipped (7ax), but a red nightly does not yet count as a change (7az).
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter123`.
Full history: stapledon-mission-log.md, entry 123.
