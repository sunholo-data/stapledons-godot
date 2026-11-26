# Mission dashboard — Stapledon

Updated 2026-11-26, iteration 119. A record-only fire (nothing to build without a ruling), about 6.5 hours after the last one. Two things came in, neither of them work the loop can take: last night's test run was clean on the credentials fix, and the fleet loop finished its general fix for publishing evidence safely. **The credentials exposed in iteration 113 still need rotating:** the secret check still finds 13 of the exposed values in this fire's environment on the Studio (either not rotated yet, or the rig's environment cache not refreshed after rotating), and the private `[SECURITY] … rotate` message is still unread. Metered $0.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 (frames during the live transit must stay under 16.7 ms, judged on the slowest 1 % of frames, the p99) has one counted miss on a valid run, 17.338 ms (iteration 107); row 7av waits on D-172. Clause 5 is ongoing. This iteration did not move the goal.
What was checked, in plain words: whether you had ruled on anything (no), whether the blocked work had unblocked (no: #435 and the package PR are still open, and the packages they wait on are unchanged), and whether last night's test run left any credentials on disk (no: the third night in a row with nothing written). The two older folders that still hold the settings dump are still there. They are on the Studio: `rm $TMPDIR/rig-check/{328b01f8,d8b7baf9}*.profile/database.txt`, or let them age out (likely by about 27 November, if the pattern holds). Either way the values in them stay live until rotated.
New from the fleet loop: every mission now scans anything it is about to make public (a pushed record, an issue comment, an evidence pack) for the rig's secret values first, and refuses if one is found. This record and its report went through that scan.
Why the loop keeps firing when nothing changes: the driver's skip for unchanged fires cannot work for this mission yet (row 7ax, ticketed to the fleet loop).
Last design: `design_docs/implemented/r1/rig-profile-secret-hygiene.md` (iteration 114).
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2). AILANG v0.61.x is out; a bump is attended work.
Current: main is `518a56b3` (iteration 118's record). Fast tier green.
Visible: nothing new, so no dev build is needed.
Nightly: #392 still red on the 2 attended targets, `ui-theme-check` (7as) and `basis-gate` (7at); last night's run (6,894 s) printed `ok` for both new checks.
Lanes: no lane degraded. Controller Opus 5.5; judge Sonnet 5.5 (Agent tool). No designer, planner or executor ran (D-168 B).
Next: record-only fires under D-168 B unless you rule.
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
- **Rotate the exposed credentials** (names in the private `[SECURITY]` message), refresh the rig's environment cache, then delete the two old dumps left (or let them age out).
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds).
- GPU scheduling.
- D-FLEET-47.
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter119`.
Full history: stapledon-mission-log.md, entry 119.
