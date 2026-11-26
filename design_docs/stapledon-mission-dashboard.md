# Mission dashboard — Stapledon

Updated 2026-11-26, iteration 122. Another record-only fire (there is nothing to build until you rule), about 6.8 hours after the last one. One thing came in: the fleet loop fixed the driver's skip for fires where nothing has changed (row 7ax, ailang#2473). Until now every unchanged fire ran in full, at a cost of a controller and a judge each time. Unchanged fires should now be skipped, so the next fire that runs should bring something new. Nothing else changed: no ruling, no blocked work unblocked, and tonight's test run is still going. The Studio was lightly loaded (load about 5). **The credentials exposed in iteration 113 still need rotating:** the secret check still finds 13 of the exposed values in this fire's environment on the Studio (either they have not been rotated yet, or the rig's environment cache was not refreshed after rotating), and the private `[SECURITY] … rotate` message is still unread. Metered $0.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 (frames during the live transit must stay under 16.7 ms, judged on the slowest 1 % of frames, the p99) has one counted miss on a valid run, 17.338 ms (iteration 107); row 7av waits on D-172. Clause 5 is ongoing. This iteration did not move the goal.
What was checked, in plain words: whether you had ruled on anything (no); whether the blocked work had unblocked (no: #435 and the package PR are still open, and the packages they wait on are unchanged); whether the fleet's fix really landed (yes: merged, and in the copy of the driver that runs); and whether the two older folders that still hold the settings dump are still there (yes). The folders are on the Studio: `rm $TMPDIR/rig-check/{328b01f8,d8b7baf9}*.profile/database.txt`, or let them age out. Either way the values in them stay live until they are rotated.
Last design: `design_docs/implemented/r1/rig-profile-secret-hygiene.md` (iteration 114).
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2). AILANG v0.64.x is on the rig; a bump is attended work.
Current: main is `d2b2d125` (iteration 121's record). Fast tier green.
Visible: nothing new, so no dev build is needed.
Nightly: tonight's `rig/full` on `d2b2d125` started about 21:29Z and is still running. The latest finished run (#392) is still red only on the 2 attended targets, `ui-theme-check` (7as) and `basis-gate` (7at).
Lanes: the driver found codex rationed for the planner and executor (handed to kimi-k3 and Haiku). Neither role ran, so this cost nothing. Controller Opus 5.5; judge Sonnet 5.5 (Agent tool).
Next: record-only fires under D-168 B unless you rule; the next real input is tonight's nightly.
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
- **Rotate the exposed credentials** (names in the private `[SECURITY]` message), refresh the rig's environment cache, then delete the two old dumps (or let them age out).
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds).
- GPU scheduling.
- D-FLEET-47.
Cadence: armed six-hour driver; unchanged fires should now be skipped (7ax).
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter122`.
Full history: stapledon-mission-log.md, entry 122.
