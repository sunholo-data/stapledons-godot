# Mission dashboard — Stapledon

Updated 2026-11-17, iteration 95. LANDED: the fix for main's nightly `rig-check-control` red (PR #453, merge `afff5571`), iteration 94's own regression.
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 re-run under D-147, needs a quiet rig); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: the profiler (`tools/suite_profile.sh run`) sets `TMPDIR` to its long profile directory; `tools/test_rig_check.sh` now uses the caller's TMPDIR only when its own paths fit the 100-character budget (else `/tmp`), names any precondition failure, and its `caller-poison` case runs under a 110-character TMPDIR. Still 26 cases.
Visible: nothing; no dev build needed.
Nightly: both profiled nights so far (`2bb77da7`, `c69a3bd5`) were red on `rig-check-control` (fixed now) and `ui-theme-check` (row 7as, attended). Tonight's run should show only `ui-theme-check`. Issue #392 stays open until then.
Owed: the M1b baseline: three comparable serial gmake runs (one traced) plus one 3.81 run, each at sampled load ≤ 5. PARKED-ON-LANE on a quiet rig. M2 waits on it.
Watch: no cross-vendor judge ran this fire; D-166's default C (tooling rows on a same-vendor, different-model judge) applied, FLAGGED.
Next: read the nightly; L11 waits on attended #435 (RT2a), then RT2b; 7m AC1 and the M1b baseline on a quiet rig; M2 after the baseline. Guard rows 7ao–7aq after these.
Critical path: 7m AC1 (clause 4) is routable only on a quiet rig; at this pick: 1-min load 51.6, GPU 96 %.
Human gates: D-166 OPEN (may a loop row merge on a same-vendor judge when the cross-vendor judge times out? Recommendation and default C: yes for test/tooling rows only).
Action for Mark (not a ledger decision): row 7as (telescope's theme lint); codex lanes still read "quota UNREADABLE".
Routing this fire: controller Opus 5.5; executor Haiku 5.5 (claude CLI); judge Sonnet 5.5 (Agent). Designer and planner not spawned (approved design and plan).
Quorum: none this fire (iteration 56's rounds and D-129 stand).
Review: Sonnet 90 PASS, 0 blocking. Non-blocking notes in the charter's iteration-95 backlog line.
CI: fast tier green on PR head `99fbd63a` and on the merge `afff5571`.
Cadence: armed six-hour driver.
Metered cost: $0 of $5. Quota: Anthropic subscription (Opus, Haiku, Sonnet).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter95`.
Full history: stapledon-mission-log.md, entry 95.
