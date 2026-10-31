# Stapledon mission dashboard

Updated 2026-10-31, iteration 61.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, which runs only on a quiet rig, and on P-land, which is Mark's. At pick the GPU read 80–83 % and the load about 10. Goal unmoved.
- **Landed this fire:** Kerr K1.1a-a5 (PR #364, merge `644cff09`), the last child of the R2 Kerr Python oracle. K1.1a-a (a1–a5) is complete.
  - The fixture's schema, unit and source are pinned as reviewed literals, and the record set as an exact 16 ids and 40 records. Before this, a drifted unit regenerated into the fixture passed the whole shell.
  - The a4 judge's harness-guard survivors are closed by self-tests: a no-op mutant must exit 3, a mislabelled drill must fail, and drill dirs sit under one private parent that must be empty at the end.
  - The judge, Sonnet in its own clone, gave 86 PASS with zero blocking findings.
- **Rig:** `rig/full` took 120 min under fleet load, 4 s inside its 7,200 s watchdog. Main's runs the same evening took 71–74 min.
  - Run 1 was stopped by the controller's own 2-hour harness cap about 30 lines from the end. It did not hang. The loop now launches `rig_check` detached.
  - L4 (parallel lanes) is the fix, and it waits on D-129.
- **In flight:** nothing. No loop PR is open.
- **Order:** 7m-d (re-sample the GPU first; re-measure the premise) → L9 S0.3 → L3 → 7l(a), 7w. D-129 then unlocks L4 M1b and M2.
  - The attended `Makefile` hold is released: #344 and #351 merged on 2026-10-30. Re-check files against open PRs at pick.
- **Backlog (non-blocking):**
  - Kerr: drills for the schema and source pins, and an assert on the private parent's EXIT trap.
  - 7n(f), 7n(a), 7i(h).
- **Parked on Mark:**
  - D-128: where 7m-d sits in the order. Default A is being applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A. If unanswered, M1b and M2 stay parked.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h.
  - The planner was kimi-k3 through pi. The executor was Haiku and the judge Sonnet, both through the Agent tool. No designer was needed.
  - Codex was over its daily ration. Metered spend $0.
- **Watch:**
  - 7m-d has been lane-parked at pick seven fires running.
  - `rig/full` duration under load is now the binding constraint on every landing.
