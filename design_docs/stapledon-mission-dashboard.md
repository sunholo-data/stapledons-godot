# Mission dashboard — Stapledon

Updated 2026-11-28, iteration 126. Another record-only fire: nothing is built until you rule. **Last night's nightly was cut off at its 2-hour limit for the third night running, and this time no test was stuck** (row 7bc). Since the evening of 2026-11-26, short `ailang run` steps that take 2–3 s at other times take 30–50 s overnight, with the same CPU time (the judge also caught one at 24 s outside the nightly). Something makes them wait, and about 40 targets now never run. The cause is not yet known. The night's one new red, `rig-check-control`, is a flaky check in the loop's own profiler (row 7bb): it wants two 0.1 s sleeps to overlap, and it fails about 1 run in 35. **D-177** asks whether the loop may raise the limit and fix that check.
The sim-start failures (7ay) did not recur: all their targets passed last night.
Still running (row 7ba): the orphaned nightly test, process 84274, now 21 hours old. The loop did not kill it.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 (frames during the live transit must stay under 16.7 ms, judged on the slowest 1 % of frames, the p99) has one counted miss on a valid run, 17.338 ms (iteration 107); row 7av waits on D-172. Clause 5 is ongoing. This iteration did not move the goal.
Last design: `design_docs/implemented/r1/rig-profile-secret-hygiene.md` (iteration 114).
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2). AILANG v0.64.1 is on the rig's PATH; a bump is attended work.
Current: main is `db394a2d` (iteration 125's record). Fast tier green.
Visible: nothing new, so no dev build is needed.
Nightly: red, 3 targets on `db394a2d` (#392, 41 comments): `ui-theme-check` (7as), `rig-check-control` (7bb), `solar-departure-test` (cut by the limit, 7bc).
Lanes: the driver resolved codex `gpt-6.2-sol` for planner and executor; neither ran. Controller Opus 5.5; judge Sonnet 5.5 (Agent tool).
Next: record-only fires under D-168 B unless you rule. A fire during a nightly takes one sample of a stalled step to see where it waits (7bc). No code change.
Still waiting: D-172 (default record-only on 7av: no publish, no O3).
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0 (latest is v0.1.0).
Package: ailang-packages#206 (social_dynamics 0.4.1) is OPEN, unmerged and unpublished.
Human gates, all OPEN:
- **D-177**: raise the nightly limit to 9,000 s (7bc) and fix the flaky check (7bb)? A both (recommended), B neither (default), C the check only.
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
- **What changed on the Studio between 2026-11-26 05:12Z and 21:29Z?** The overnight stalls (7bc) start in that window: a new overnight job, a backup, an indexer, a security tool?
- **Kill the orphaned test** when convenient: `kill 84274` (row 7ba).
- **Rotate the exposed credentials** (names in the private `[SECURITY]` message) and refresh the rig's environment cache. One old dump is left (`328b01f8`).
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds); GPU scheduling; D-FLEET-47.
Cadence: armed six-hour driver; unchanged fires are skipped (7ax), and a new nightly report on #392 counts as a change (7az).
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter126`.
Full history: stapledon-mission-log.md, entry 126.
