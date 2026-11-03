# Stapledon mission dashboard

Updated 2026-11-03, iteration 67.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, and on P-land, which is Mark's.
- **Measured this fire: row 7m-d, PROVISIONAL.** It explains why the docked bridge's p99 (17–19 ms) sits above 16.7 ms on a quiet rig.
  - The tail is not warm-up, not a redraw, and not GPU render cost (about 2 ms per frame). 243 of 245 slow frames spend their time inside the engine's draw step.
  - An empty window with no game reads p99 15.9–16.3 ms on the Studio, which has no physical display. With all game `_process` off, the docked p99 is 15.2–16.1.
  - No game-side defect was found and no product fix is proposed. Doc: `design_docs/planned/r1/m4-7md-docked-p99-attribution.md` (PR `mission/stapledon-iter67-7md`).
  - It is PROVISIONAL because no counted run had the new remote-session check (`quiet2.sh`). AC S1 is four probe runs, about 3 minutes, on a quiet rig. The one session-checked docked control read 17.81, but Ollama took the GPU mid-run, so it counts as evidence only.
  - Judge: Sonnet, 80 and then 78 PASS, zero blocking. The quorum blocked twice; its fixes were applied (a fail-closed R1, a stale-file drill).
- **Merge rule changed (Mark, 2026-11-03, #389):** PRs land on the fast tier, the targeted gates, a cross-family judge and, for visual or audible work, Mark's dev-build OK. `make test` runs nightly on main. `rig/full` and row 7z no longer block PR #387.
- **Order:**
  1. Land #387 (S1 republish tooling): merge main into it (the `capture-m4` line conflict with #386), compare patch-ids, fast tier, the targeted gates, merge, then publish the dated S1 set and park for Mark's review.
  2. 7m-d S1 when `quiet2.sh` holds, then OQ1–OQ5 go to Mark as one decision.
  3. 7x. Then D-129 (Mark) unlocks L4 M1b and M2.
- **Options waiting on S1 (not asked yet):**
  - OQ1: status quo.
  - OQ2: attach a display for counted runs.
  - OQ3: a product trim of the docked frame's work. The best case is p99 15.2–16.1, so it may still fail.
  - OQ4: record the empty-window floor in each bench run.
  - OQ5: a relative gate. None of these loosens 16.7 ms.
- **Rig:** shared. Ollama local-model evals hold the GPU for long stretches (20:28–21:20 and from 21:26 today), and attended D-144 agents run builds.
- **Backlog (non-blocking):**
  - The hidden navigation map still redraws about 600 times per 30 s of transit; the cost is unmeasured.
  - 7y: NT4 is intermittent.
  - The 7w judge's survivors.
  - S0 guard variants.
  - Kerr drills.
- **Parked on Mark:**
  - D-128: where 7m-d sits in the order. Default A is applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A.
  - After #387 lands: the S1 render review.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire: designer Opus and judge Sonnet, both through the Agent tool. No planner or executor ran, because no code was designed. Metered spend $0.60 (two quorum rounds).
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380), R3-TRUE-PROCESSED (#384), comms station v2 (#379).
- **Watch:** quiet windows are short. 7m-d's S1 needs about 3 quiet minutes, with nobody on the console.
