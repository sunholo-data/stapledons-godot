# Mission dashboard — Stapledon

Updated 2026-11-20, iteration 105. The rig went quiet for a few minutes after the nightly golden, so row 7av was picked and measured. No run counted: both GPU probe runs started quiet and were contended within seconds. Metered $0.76 (design quorum, two rounds). A Sonnet 5.5 judge passed the doc 74, then 80.
R1: clauses 1–3 are MET. Clause 4 is UNMET: 7m AC1 has a measured MISS (iteration 103); 7av now attributes the transit tail but has no counted run. Clause 5 is ongoing. Goal unmoved.
Last result: `design_docs/planned/r1/m4-7av-transit-hitch-attribution.md`. 781 slow transit frames: 86.9 % in the draw bracket, 11.3 % waiting on a sim reply, 0 shader compiles, no memory signature. In p2 the slow frames start when the GPU reaches 100 % mid-run (holder inferred: the local model runner). p1's quiet-looking first 18.8 s read p99 15.59 ms with no fix. No confident game-side fix; options O1–O4.
Evidence bundle: `gs://stapledons-voyage-assets/benchmarks/7av-iter105/7av-iter105-evidence.tgz` (sha256 `34ad9ccf…ddca`).
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no code change on main since iteration 102's record; main is `ad929704` (iteration 104's record) and the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly: `rig/full` red on the 2 attended targets, `ui-theme-check` (7as) and `basis-gate` (7at); `rig/golden` green on `ad929704` (3 min). Issue #392 stays open.
Lanes: codex over its daily ration (probe rc 75); the quorum's codex seat was absent on quota both rounds. Planner and executor were not needed (the doc designs no code).
Next: D-169. Without an answer, the loop stays on D-168 B and, whenever `quiet2.sh` holds, fixes `gate.sh`'s three fail-open edges (doc only), then runs R1 (a counted probe with the in-run sampler), R4 (the hidden-map ablation), R5 (two counted benches).
Owed: the L4 M1b baseline (quiet rig), then M2.
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0; the registry still has 0.1.0.
Watch: the docked control was valid in 2 of 11 runs to date, and the quiet windows now last minutes.
Human gates: D-169 OPEN (NEW: GPU window / O2 / both / neither; recommendation A, a GPU window). D-166 OPEN (default C applied). D-168 OPEN (B applied).
Action for Mark (not a ledger decision): rows 7as and 7at (attended nightly reds). GPU scheduling (local-model work holds the GPU at most picks). D-FLEET-47 (mission codex daemon).
Routing this fire: controller Opus 5.5; designer Opus 5.5 (Agent tool, one revision); evaluator Sonnet 5.5 (Agent tool, two rounds). No planner or executor.
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`); this record was written in a fresh clone of `origin/main` at `../stapledons-godot-iter105`.
Full history: stapledon-mission-log.md, entry 105.
