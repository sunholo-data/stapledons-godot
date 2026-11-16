# Mission dashboard — Stapledon

Updated 2026-11-16, iteration 94. LANDED: L4 M1b code half (PR #451, merge `2bb77da7`): the nightly `rig/full` runs `make test` profiled.
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 re-run under D-147, needs a quiet rig); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: `tools/rig_check.sh` runs `make -k test` serially under `tools/suite_profile.sh` with gmake 4.4.1 (D-129 A), keeps raw rows in `<sha>.profile/` beside the log and ends the log with the summary. `RIG_TRACE=1` adds `--trace`. Three loud fallbacks (`profile-off`, `profile-absent`, `gmake-missing`) are marked in the status. The control has 26 cases.
Visible: nothing; no dev build needed.
Nightly: tonight's run on main is the first profiled one. Expect `ui-theme-check` red (row 7as, attended). A loaded test run of the PR also timed out in `sound-test`, `sound-archive-test` and `worlds-leak` (load median 15.9); if those go red on a quiet night, suspect gmake. `RIG_PROFILE=0` restores plain make.
Owed: the M1b baseline: three comparable serial gmake runs (one traced) plus one 3.81 run, each at sampled load ≤ 5. PARKED-ON-LANE on a quiet rig. M2 waits on it.
Watch: the cross-vendor judge (MiniMax M3, pi) has returned no verdict three iterations running (92, 93, 94), so two merges went in on a same-vendor judge (D-166).
Next: read the nightly; L11 waits on attended #435 (RT2a), then RT2b; 7m AC1 and the M1b baseline on a quiet rig; M2 after the baseline. Guard rows 7ao–7aq after these.
Critical path: 7m AC1 (clause 4) is routable only on a quiet rig; at this pick: load 10.6, GPU 35 %, Screen Sharing ×3.
Human gates: D-166 OPEN (may a loop row merge on a same-vendor judge when the cross-vendor judge times out? Recommendation C, the default: yes for test/tooling rows only).
Action for Mark (not a ledger decision): row 7as (telescope's theme lint); codex lanes still read "quota UNREADABLE".
Routing this fire: controller Opus 5.5; executor Haiku 5.5 (claude CLI); judge Sonnet 5.5 (Agent); cross-vendor MiniMax M3 (pi, wall_timeout). Designer and planner not spawned (approved design and plan).
Quorum: none this fire (iteration 56's rounds and D-129 stand).
Review: Sonnet 66 FAIL (round 1, B1: the golden half deleted the profile) → revision 1 → 88 PASS. Non-blocking survivors in the charter's iteration-94 backlog line.
CI: fast tier green on PR heads `58419ddb`, `31f70555`, `a38911b2`, and on the merge `2bb77da7`.
Cadence: armed six-hour driver.
Metered cost: $0.69 of $5 (MiniMax). Quota: Anthropic subscription (Opus, Haiku, Sonnet).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter94-record`.
Full history: stapledon-mission-log.md, entry 94.
