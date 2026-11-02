# Stapledon mission dashboard

Updated 2026-11-02, iteration 63.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, which runs only on a quiet rig, and on P-land, which is Mark's. At pick the GPU and load read quiet, but a person was using the Studio over Screen Sharing. Goal unmoved.
- **Landed this fire:** L9 semantic-memory S0 Landing (PR #368, merge `e7806004`). Sprint R2-SIMILAR-S0 is complete.
  - The S0.3 judge's survivors are folded in: the vector guard catches `.get("vector", d)` and `.has("vector")`, `SIMILAR_MINOR` is pinned to 14, an empty `{}` is accepted, and the stored section is its own copy. Bridge test 107 → 110 ok.
  - The design, plan and report are in `design_docs/implemented/r2/`. The design repo records S0 as implemented (stapledons-design#47), with the Jupiter row as measured.
  - The judge, Sonnet in its own clone, gave 92 PASS with zero blocking findings.
- **Found:** the Studio's display runs at 100 Hz, and the docked bench frames sit on its 10 ms period even with vsync off (two premise runs, not counted). A docked p99 above 16.7 ms over 300 frames may just be about 3 frames that slipped one refresh. That is 7m-d's first hypothesis.
- **Rig:** `rig/full` green in 101 min, launched detached. L4 (parallel lanes) is the fix for the duration, and it waits on D-129.
- **In flight:** nothing. No loop PR is open after the record merges.
- **Order:** 7m-d (quiet rig and nobody on the console; start from the 100 Hz hypothesis) → L3 → 7l(a), 7w, 7x. D-129 then unlocks L4 M1b and M2.
- **Backlog (non-blocking):**
  - S0: the guard still misses `.get(&"vector")` and a bare `get("vector")`, and its probe has no whitespace variants; the moved design doc's status lines are stale.
  - Kerr: drills for the schema and source pins, and an assert on the private parent's EXIT trap.
  - 7n(f), 7n(a), 7i(h).
- **Parked on Mark:**
  - D-128: where 7m-d sits in the order. Default A is being applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A. If unanswered, M1b and M2 stay parked.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h.
  - The planner was kimi-k3 through pi. The executor was Haiku and the judge Sonnet, both through the Agent tool. No designer was needed.
  - Codex was over its daily ration. Metered spend $0.
- **Watch:**
  - 7m-d has been lane-parked at pick nine fires running. Its predicate now also requires nobody on the console.
  - A Godot `--script` test that fails to parse exits 0 (row 7x): three instances in two iterations, each caught only by reading the summary line.
