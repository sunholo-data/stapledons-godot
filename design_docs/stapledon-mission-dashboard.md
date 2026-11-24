# Mission dashboard — Stapledon

Updated 2026-11-24, iteration 113. The overnight CPU recorder (V21) is read: the late-night load spikes are mostly the test suite's own threads, not other work on the machine. **Security incident: this fire published the rig's credentials for about 90 s; rotate them (private message `inbox_1795505042463_90e973b8`).** Metered $0.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 (frames during the live transit must stay under 16.7 ms, judged on the slowest 1 % of frames, the p99) has one counted miss on a valid run, 17.338 ms (iteration 107); row 7av waits on D-172. Clause 5 is ongoing.
What V21 says, in plain words: two nightly test runs fell inside the recording (22:30–00:13 and 04:15–06:07 local). CPU used by everything that is not the test run stayed at or under 4.13 cores (smoothed like the load average), below the rule's limits of 5 and 8, so the nightlies can most likely supply L4's timing baseline at no extra rig time. One 30-s row read 5.03 before smoothing, so the doc's rule, read to the letter, says "co-primary" (nightlies and quiet-window runs both count). The old rule calls both runs `loaded`.
The incident: the evidence pack included two copies of a file the nightly writes (`database.txt`, a `make -p` dump) that holds every environment variable, credentials included. The controller found it, deleted it at 07:22:43Z, alerted you privately, and published a clean pack instead. The six earlier packs are clean. Row 7aw fixes the file; D-174 asks whether the loop builds it next fire (default yes).
Last design: `design_docs/planned/r1/rig-test-speed-ac9-load-rule.md` (revision 3, iteration 113; judged 91 PASS). It waits on D-173.
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no game code change on main since iteration 102's record. Main is `328b01f8` (iteration 112's record), and the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly on `328b01f8`: `rig/full` red on the 2 attended targets, `ui-theme-check` (7as) and `basis-gate` (7at), #392 open; `rig/golden` green.
Lanes: no lane degraded. Controller Opus 5.5; designer Opus 5.5 (Agent tool); judge Sonnet 5.5 (Agent tool). No planner or executor (no code).
Next: row 7aw under D-174's default A, unless you choose B.
Still waiting: D-172 (default record-only on 7av: no publish, no O3).
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0 (latest is v0.1.0).
Package: ailang-packages#206 (social_dynamics 0.4.1) is OPEN, unmerged and unpublished.
Human gates, all OPEN:
- D-174: may the loop fix the credential-bearing dump (row 7aw) next fire? Default A, yes.
- D-173: approve the rule that a timing run counts when the CPU used outside it stays low (OQ1 with OQ3), the baseline source (OQ2, now co-primary on V21's reading), OQ4–OQ5; or choose B, C or D.
- D-172: publish 0.4.1 and crew_core 0.6.1, and is O3 next? Recommendation C.
- D-171: its default A ran; B is open.
- D-170: its default A ran in iteration 108.
- D-169: GPU window.
- D-166: default C applied (same-vendor judge on a tooling doc or record, flagged).
- D-168: C applied; now in its B half (record-only fires).
Action for Mark (not a ledger decision):
- **Rotate the 15 exposed credentials** (names in `inbox_1795505042463_90e973b8`; the 1Password service-account token and the Claude OAuth token first).
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds).
- GPU scheduling.
- D-FLEET-47.
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter113`.
Full history: stapledon-mission-log.md, entry 113.
