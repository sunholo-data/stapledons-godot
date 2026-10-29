# Stapledon mission dashboard

Updated 2026-10-29, iteration 57.

- **Bar:** Clauses 1/2/3 MET; 4 UNMET; 5 ongoing. Clause 4 waits on row 7m AC1, which waits on 7m-d (quiet rig only; this fire GPU 99–100 %, load 16), and on P-land (Mark). Goal unmoved.
- **Landed this fire:** L4 M1a, the suite profiler instrument (PR #349, merge `81e240f0`; `rig/full` 87 min; fast tier green on the merge).
- **In flight:** Kerr K1.1a-a4, PR #352 (`2b47456b`): eight in-copy oracle mutation drills, plus RK-3 and RK-9. Judge Sonnet **90 PASS**, zero blocking.
  - `rig/full` was red at `crew-perf`: 5.08 s against a 4.0 s budget at rig load 18–36. Main fails the same check the same way under that load, so it is not the PR.
  - The merge is **PARKED-ON-LANE**. Resume: re-run `rig/full` on `2b47456b` when the 1-min load is below 8, then merge.
- **Order:** land #352 → 7m-d whenever the rig is quiet → D-129 → L4 M1b → M2 → K1.1a-a5 → L9 S0.3 → L3.
- **Parked on Mark:**
  - D-128: the position of 7m-d. Default A is being applied.
  - D-129: L4's OQ1–OQ4. Recommendation A. If unanswered, M1b and M2 stay parked.
- **Held:** `Makefile` (L4 M3, row 7v) waits until attended #344, #346 and #351 merge or close.
- **New row:** 7v, the `crew-perf` wall-clock budget under rig load (gate on CPU, keep the 4.0 s threshold).
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire: executor Haiku 5.5 (Agent), evaluator Sonnet (Agent); no designer or planner. Codex was over its daily ration. Metered $0.00.
- **Watch:** the Studio is heavily shared (ailang backlog builds plus the attended view-finish session, load ~30 on 16 cores). That parks both GPU benches and wall-clock gates.
