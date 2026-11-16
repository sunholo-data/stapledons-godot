# Mission dashboard — Stapledon

Updated 2026-11-16, iteration 93. LANDED: row 7ar (PR #448, merge `ba3be980`), iteration 92's orphaned build, judged and landed.
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 re-run under D-147, needs a quiet rig); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: main's nightly loses two of its three reds. The live guard's five `--entry` call sites clear `AI_LIVE`, a bounded `ai-live-guard-static` joins `ci-fast`, and the monitor-face controls read their sample count from the run (45 since #443). Six files, test and tooling only.
Visible: nothing; no dev build needed for this row.
Nightly: the last `rig/full` (`36f4ab4c`, 2026-11-13 23:13) had 3 reds. Expect 1 at the next run: `ui-theme-check`, from the attended telescope merge #438 (row 7as, handed to its owner).
Watch: iteration 92 died during evaluation, and five fires (2026-11-14 20:25 to 2026-11-16 02:35) found every controller rung spent. The pi cross-vendor judge failed twice in a row (empty, then a wall timeout).
Next: read the nightly on main; L11 waits on attended #435 (RT2a), then RT2b; 7m AC1 on a quiet rig (D-147); L4 (D-129 A). Guard rows 7ao–7aq after these.
Critical path: 7m AC1 (clause 4) is routable only on a quiet rig; at this pick the GPU read 94 % with Screen Sharing active.
Human gates: none OPEN (ledger valid, no row changed this fire).
Action for Mark (not a ledger decision): row 7as (telescope's theme lint, `ui/survey_map_layer.gd:114`); codex login still reads "quota UNREADABLE"; controller rungs were spent for five fires.
Routing this fire: controller Opus 5.5; designer, planner and executor not spawned (iteration 92's work inherited); judges Sonnet (Agent) + MiniMax M3 (pi, cross-vendor, wall_timeout, no verdict).
Quorum: none this fire (iteration 92's design rounds stand).
Review: Sonnet 90 PASS, 0 blocking, 3 non-blocking survivors (charter backlog line, iteration 93). No cross-vendor verdict (FLAG).
CI: fast tier green on PR heads `bb613f79` and `c2e6da50`; merge `ba3be980` fast tier green (run 43844634663); no GPU run.
Cadence: armed six-hour driver.
Metered cost: $0.71 of $5 (MiniMax). Quota: Anthropic subscription (Opus, Sonnet).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter93`.
Full history: stapledon-mission-log.md, entry 93.
