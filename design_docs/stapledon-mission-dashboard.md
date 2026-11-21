# Mission dashboard — Stapledon

Updated 2026-11-21, iteration 108. Row 7av, D-170's default A: a headless measurement of where the cruise sim-wait comb goes. No GPU and no code change. Metered $0. A Sonnet 5.5 judge scored it 91 PASS, 0 blocking.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 has one counted valid-control MISS (17.338 ms against 16.7, iteration 107), and its main cause is now attributed. Clause 5 is ongoing. Goal unmoved.
Last result: `design_docs/planned/r1/m4-7av-transit-hitch-attribution.md`, section "Iteration 108". Every 30th crew day (every 53–54 ticks) crew_core's auto-run decision step costs 62.6–64.8 ms on the AILANG VM, against 0.3–1.0 ms on other ticks. The reply then takes 78–91 ms, over the 50 ms tick window, so the frame waits. About 20 ms of that step is one line in `sunholo/social_dynamics` (`sortedJson`); a keyed sort gives byte-identical output. Not the cause: the reply's size, the pipe, or Godot's parse.
Upstream: reported to AILANG (inbox `user`, `inbox_1795230842850_a05aeea5`, repro attached).
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no code change on main since iteration 102's record. Main is `49314f81` (iteration 107's record), and the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly: #392 stays open on the 2 attended reds, `ui-theme-check` (7as) and `basis-gate` (7at).
Lanes: codex was in ration this fire but not needed. The designer was Opus 5.5 and the judge Sonnet 5.5, both through the Agent tool.
Next: D-171. Without an answer, the next fire takes its option A: prepare the `sortedJson` fix in `sunholo/social_dynamics` (ailang-packages PR, tests, `pkg quality`), re-measure against a local pin, and stop before publishing. It skips that if the inbox shows the maintainers have taken the fix. O3 is not built.
Owed: the L4 M1b baseline (quiet rig), then M2.
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0; the registry still has 0.1.0.
Watch: off-cadence bursts of slow replies (42–83 ms, not the sim's compute) are a second tail component, still UNMEASURED.
Human gates: D-171 OPEN (new: next step for AC12; recommendation C, prepare the package fix and then design O3). D-170 OPEN (its default A ran this fire). D-169 OPEN (GPU window). D-166 OPEN (default C applied). D-168 OPEN (B applied).
Action for Mark (not a ledger decision): rows 7as and 7at (attended nightly reds). GPU scheduling. D-FLEET-47 (mission codex daemon). The designer-rotation pointer reads Opus while the rotation would hand the next designer to codex; the driver resolves Opus.
Routing this fire: controller Opus 5.5; designer Opus 5.5 (Agent tool); evaluator Sonnet 5.5 (Agent tool). No planner or executor.
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone branched from `origin/main` at `../stapledons-godot-iter108`.
Full history: stapledon-mission-log.md, entry 108.
