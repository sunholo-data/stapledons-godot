# Stapledon mission dashboard

Updated 2026-11-06, iteration 75.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. AC1 waits on 7m-d, and 7m-d now waits on **D-147**, which is Mark's. P-land is also Mark's.
- **Done this fire: 7m-d's last measurement (S1).** The Studio was quiet at 17:53 CET for the first time in eight fires, so the loop re-measured why the docked bridge's frame time sits just above the 60 fps line.
  - The earlier answer holds. Docked, the slowest 1 % of frames take 17.4–18.4 ms (4 runs). An empty window with no game in it takes 15.5–16.2 ms (5 of 6 runs; one odd run at 24.9 ms was not explained). No game-side defect was found.
  - The catch: the rule says a run only counts if the GPU looks idle straight after it. After every docked run the first GPU reading still showed the game's own load (28–36 %), and 3 s later it read 0. Under the rule as written, no docked run can count. Mark decides (D-147).
  - New: the real bench passed its own check once. Of two quiet `make bench SCENE=bridge` runs, one had a docked control of 15.18 ms (valid, under 16.7) and a live-transit frame time of 16.22 ms (under the 16.7 target). The other read 17.95 (invalid) and 16.12.
  - New: since the comms station (R3-COMMS-V2), three bridge monitor screens redraw while docked. The frame times did not change.
  - The judge (Sonnet) failed the first write-up, 68: it said one option would complete S1 when it would not. Two more runs fixed that, and the second judgement passed, 86.
- **Order:**
  1. D-147 (Mark). If Q1 B and Q2 OQ6: the loop re-runs row 7m AC1 on quiet rigs, counting only runs with a valid docked control.
  2. 7ad: a timeout runner that also stops the sim, used by `crew-console-test` and `tools/script_gate.sh`. Headless; touches `Makefile`.
  3. 7ac: re-run its checks once 7ad lands, re-review once, then build.
  4. 7ab: the timing ratio on an idle rig, then add `sim-pipeline-test` to the nightly.
  5. 7x B2b, B3b, B4b (64 GPU, golden and authoring gates) when a GPU window is free.
- **Parked on Mark:**
  - **D-147 (new):** what counts for S1, and what happens to AC1. Q1: is the "GPU idle after the run" reading taken at once (A) or 3 s later (B)? Q2 (only under B): which of OQ1–OQ6. Recommendation: Q1 B, Q2 OQ6 (the 16.7 ms rule stays; only runs it already accepts count). Default: Q1 A (7m-d stays open; the loop moves on to 7ad).
  - D-146: should the designer rotation skip codex on this mission? Recommendation B. Default A (as now).
  - D-145: who fixes the nightly `sound-test` red (#392). Attended #405 has since changed that test; the nightly will close issue #392 on its next green run, so this may be moot.
  - D-128: where 7m-d sits in the order. Default A is applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A.
  - The S1 render review of `refs/m4_ship_s1/2026-11-04/`.
- **Backlog (non-blocking):** 7x B2b–B8; judge survivors from 7x/7aa; 14 targets no aggregate runs; the 7w survivor; navigation-map redraws in transit; 7y (NT4); the `design_docs/**` whitespace exemption is wider than needed (7ac r3, glm and kimi).
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire: controller measurement, judge Sonnet (Agent tool, two rounds). No designer, planner or executor was needed. Metered spend $0.
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380).
- **Rig:** quiet from 17:53 to at least 18:09 CET (GPU 0 %, no remote session). The main checkout is clean at `8c570d1e` = origin; loop clones stage their own `runtime/` with `make runtime`.
