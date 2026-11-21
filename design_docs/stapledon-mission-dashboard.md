# Mission dashboard — Stapledon

Updated 2026-11-21, iteration 109. Row 7av, D-171's default A: the `sortedJson` fix in `sunholo/social_dynamics` is prepared, up to the publish and no further. Metered $0.54 (two quorum rounds). A Sonnet 5.5 judge scored it 93 PASS, 0 blocking.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 has one counted valid-control MISS (17.338 ms against 16.7, iteration 107). Its main cause is attributed, and one part of it is now fixed in a PR. Clause 5 is ongoing.
Last result: [ailang-packages#206](https://github.com/sunholo-data/ailang-packages/pull/206), social_dynamics 0.4.1. It is OPEN, not merged and not published.
- What it does: the sort encodes each element once.
- Byte identity: a scratch pin of main gives the same 640-reply session; replay (12 cases), parity, crew-parity and strict all pass; each fails against the old package, as its control.
- Speed: the decision-day step goes from 64.8–66.5 to 43.5–45.1 ms (3 interleaved pairs).
- Report: `design_docs/planned/r1/m4-7av-sortedjson-keyed-sort-report.md`.
Still over the window: a decision day is about 44 ms of step plus 18 ms of encoding, against 50 ms. Only O3 takes the wait out of the frame.
To reach the game: publish 0.4.1, then crew_core 0.6.1 (0.6.0 pins social_dynamics `0.4.0` exactly), then the game pin and a re-bench.
Upstream: the DX gap (a direct path dependency silently replaced by a transitive registry pin, exit 0) is reported as `inbox_1795259886367_207a73de` and sunholo-data/ailang#2442. The iteration-108 report `inbox_1795230842850_a05aeea5` has no reply yet.
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no game code change on main since iteration 102's record. Main is `059bad3c` (iteration 108's record), and the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly: #392 stays open on the 2 attended reds, `ui-theme-check` (7as) and `basis-gate` (7at).
Lanes: codex `gpt-6.2-sol` probed rc 0 and ran the planner and executor. The designer was Opus 5.5 and the judge Sonnet 5.5, both through the Agent tool.
Next: D-172. Without an answer, the loop runs record-only fires on 7av: no publish and no O3.
Owed: the L4 M1b baseline (quiet rig), then M2.
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0.
Watch: off-cadence bursts of slow replies, and the remaining ~44 ms of the decision step; both UNMEASURED.
Human gates, all OPEN:
- D-172 (new): publish 0.4.1 and crew_core 0.6.1, and is O3 next? Recommendation C.
- D-171: its default A ran; B is open.
- D-170: its default A ran in iteration 108.
- D-169: GPU window.
- D-166: default C applied.
- D-168: B applied.
Action for Mark (not a ledger decision):
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds).
- GPU scheduling.
- D-FLEET-47.
Routing this fire: controller Opus 5.5; designer Opus 5.5 (Agent tool); planner and executor codex `gpt-6.2-sol` (cross-provider recipe); evaluator Sonnet 5.5 (Agent tool).
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter109`. The package clone is `../ailang-packages-sd-sortedjson`, kept until #206 resolves.
Full history: stapledon-mission-log.md, entry 109.
