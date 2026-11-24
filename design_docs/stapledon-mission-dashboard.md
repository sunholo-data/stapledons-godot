# Mission dashboard — Stapledon

Updated 2026-11-24, iteration 112. Record-only fire under D-168 B: no pick, nothing built, metered $0. Every row that could move the bar waits on a ruling of yours, and the one loop task left (reading the overnight CPU sampler, V21) waits for the sampler to finish at about 06:27Z.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 (frames during the live transit must stay under 16.7 ms, judged on the slowest 1 % of frames, the p99) has one counted miss on a valid run, 17.338 ms (iteration 107); row 7av waits on D-172. Clause 5 is ongoing.
In flight: V21, a recorder of the whole machine's CPU every 30 s, started by iteration 111 at 17:27Z on 11-23 (pid 31503, `/tmp/i111-overnight-data/`); it stops by itself about 06:27Z. Tonight's nightly ran inside it (`make test` 22:30–00:13 local, `make golden` 00:31–00:34 local). The first fire after 06:27Z reads it, publishes it, and adds it to the L4 design's §I. It answers OQ3: are the late-night load spikes the test suite itself or something else on the machine?
Last design: `design_docs/planned/r1/rig-test-speed-ac9-load-rule.md` (iteration 111; judged 85 PASS). It waits on D-173.
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no game code change on main since iteration 102's record. Main is `d8b7baf9` (iteration 111's record), and the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly on `d8b7baf9`: `rig/full` red on the 2 attended targets, `ui-theme-check` (7as) and `basis-gate` (7at), #392 open; `rig/golden` green.
Lanes: no lane degraded this fire. Controller Opus 5.5; judge Sonnet 5.5 (Agent tool). No designer, planner or executor (nothing picked).
Next: V21 reading (after 06:27Z). Then nothing routable until a ruling lands.
Still waiting: D-172 (default record-only on 7av: no publish, no O3).
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0 (latest is v0.1.0).
Package: ailang-packages#206 (social_dynamics 0.4.1) is OPEN, unmerged and unpublished.
Human gates, all OPEN:
- D-173: approve the rule that a timing run counts when the CPU used outside it stays low (OQ1, with V21's answer to OQ3), the baseline paths (OQ2), OQ4–OQ5; or choose B, C or D.
- D-172: publish 0.4.1 and crew_core 0.6.1, and is O3 next? Recommendation C.
- D-171: its default A ran; B is open.
- D-170: its default A ran in iteration 108.
- D-169: GPU window.
- D-166: default C applied (same-vendor judge on a tooling doc or record, flagged).
- D-168: C applied; now in its B half (record-only fires).
Action for Mark (not a ledger decision):
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds).
- GPU scheduling.
- D-FLEET-47.
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter112`.
Full history: stapledon-mission-log.md, entry 112.
