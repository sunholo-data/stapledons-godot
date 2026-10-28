# Stapledon mission dashboard

Updated 2026-10-28, iteration 54.

- **Bar:** Clauses 1/2/3 MET; 4 UNMET; 5 ongoing. Clause 4 waits on row 7m AC1 (now measured, parked on D-127) and P-land (Mark). Goal unmoved this iteration.
- **Measured (not landed):** row 7m AC1, the quiet-rig bench for M4.6pR3 (the hidden-map redraw fix, on main since 2026-10-19).
  - The rig was idle at the fire (GPU 0 % on three samples, 1-min load 1.5), so 7m was the critical-path pick ahead of Kerr a4.
  - `make bench SCENE=bridge` on main `854003c8`: live-transit p99 15.22 / 15.43 / 15.99 ms (loop) and 15.82 / 16.48 / 15.89 ms (judge), 3,209–3,257 frames. AC1–AC3 hold in 6 of 6 quiet runs.
  - DR1 (fix reverted) misses at p99 34.3 / 34.0 ms; DR4 stays green; DR2/DR3 turn `map-ism-test` red; AC4 19 passed.
  - **Why it is parked:** the approved sprint plan says a docked-control p99 above 16.7 ms invalidates a run, and the docked control read 17.6–19.3 ms in 9 of 9 runs.
- **Judge:** a fresh Sonnet in its own clone re-ran the benches and drills and scored 80/100 PASS. It set the docked-control rule aside as a flawed criterion. The controller confirmed that the plan states it as a validity rule, so changing it goes to Mark.
- **Gates:** no code changed. Measured with AILANG v0.54.18 and Godot 4.7.2 on the M4 Max (Metal, 2560×1440, medium tier, vsync off).
- **Next:** D-127 first. Then, per Mark's 2026-10-20 order: K1.1a-a4 → a5 (RK-3/RK-9 owed) → L9 S0.3 → L4 (suite speed) → L3.
- **Open decisions:**
  - D-126 (`rig/full` watchdog): A raise it to 7,200 s, B move L4 up, C both, D neither. Recommendation C; default D.
  - D-127 (7m docked-control rule): A drop it and record AC1 met, B keep it and investigate the docked p99, C use a longer docked control. Recommendation A; default no change.
- **Capacity/ownership parks:** none new. Attended PRs #339 (docs) and #340 (R3 Earth link plan) are open; neither overlaps the loop's files.
- **Lanes:**
  - controller: Opus;
  - evaluator: Sonnet via the Agent tool;
  - designer, planner and executor: not spawned, because the doc, the plan and the fix already existed and the work was a GPU measurement.

  Metered spend: $0.
- **Harness share:** 0/20 over iterations 35–54. Of the last three landings, #341 moved clause 4, while #333 and #327 (Kerr R2) moved none. This iteration landed no code and worked the clause-4 row.
