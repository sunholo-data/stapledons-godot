# Mission dashboard — Stapledon

Updated 2026-11-20, iteration 107. The rig went quiet at 20:24 local, so row 7av was the pick under D-169's default. Six GPU runs, three counted. **AC12 has a counted MISS on a valid control**: bench run b3 read live-transit p99 17.338 ms against the 16.7 bound, with a valid docked control (16.563). Metered $0. A Sonnet 5.5 judge scored 89, then 94 PASS.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 now has one counted valid-control MISS (iteration 107), after 7m AC1's MISS (iteration 103). Clause 5 is ongoing. Goal unmoved.
Last result: `design_docs/planned/r1/m4-7av-transit-hitch-attribution.md`, section "Iteration 107 counted runs". On a quiet rig most slow frames are the game waiting 30–55 ms for the sim's `crew` reply, every 53–54 ticks. Hiding the hidden map (O2) cut game time per tick but not the p99 (one run).
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no code change on main since iteration 102's record; main is `1468cda4` (iteration 106's record), and the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly: the last run, on `ad929704`, had `rig/full` red on the 2 attended targets, `ui-theme-check` (7as) and `basis-gate` (7at); `rig/golden` was green. #392 stays open.
Lanes: codex is over its daily ration (probe rc 75). The designer was Opus 5.5 and the judge Sonnet 5.5, both through the Agent tool.
Next: D-170. Without an answer, the next fire takes its option A: one headless designer run that measures where the 30–55 ms `crew` reply goes (VM compute or encode and parse), with no GPU and no code. If the time is the VM's, it gets reported upstream.
Owed: the L4 M1b baseline (quiet rig), then M2.
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0; the registry still has 0.1.0.
Watch: quiet windows are short. This one opened at about 20:24, and p3 was contended within a minute of starting at 20:29. Prepare the clone before polling.
Human gates: D-170 OPEN (new: next step for AC12; recommendation A). D-169 OPEN (GPU window; its R1/R4/R5 step ran under its default). D-166 OPEN (default C applied). D-168 OPEN (B applied).
Action for Mark (not a ledger decision): rows 7as and 7at (attended nightly reds). GPU scheduling (local-model work holds the GPU at most picks). D-FLEET-47 (mission codex daemon).
Routing this fire: controller Opus 5.5; designer Opus 5.5 (Agent tool); evaluator Sonnet 5.5 (Agent tool). No planner or executor.
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone branched from `origin/main` at `../stapledons-godot-iter107`.
Full history: stapledon-mission-log.md, entry 107.
