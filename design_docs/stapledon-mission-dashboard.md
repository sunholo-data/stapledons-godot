# Stapledon mission dashboard

Updated 2026-10-29, iteration 56.

- **Bar:** Clauses 1/2/3 MET; 4 UNMET; 5 ongoing. Clause 4 waits on row 7m AC1, which waits on 7m-d (quiet rig only; this fire GPU 99–100 %), and on P-land (Mark). Goal unmoved.
- **In flight:** L4 test-suite speed, PR #349 (`86b96103`), not merged.
  - Design `rig-test-speed.md`; plan `R1-RIG-TEST-SPEED`. The controller's serial baseline: `make test` 4,123 s, `sim` 740 s.
  - M1a, the suite profiler instrument: `tools/suite_profile.sh`, a make `SHELL` wrapper and a 20-case control. Judge Sonnet: 66 FAIL, then **90 PASS** in round 2, and 88 PASS in round 3 on the fix.
  - `rig/full` run 2 was red because the control failed under make. It was fixed in `86b96103`, and run 3 was in flight at record time. **The next iteration merges on green.**
- **Order:** land #349 → D-129 → M1b (rig wiring, three gmake baselines) → M2 (parallel lanes, goal ≤ 0.5× serial). Meanwhile 7m-d whenever the rig is quiet, then K1.1a-a4 → a5 → L9 S0.3 → L3.
- **Parked on Mark:**
  - D-128: the position of 7m-d. Default A is being applied.
  - **D-129** (new): L4's OQ1–OQ4. These are a parallel `rig/full`, gmake on the rig, keeping the duplicate checks, and whether a missing gmake fails. Recommendation A, accepting all the defaults. If unanswered, M1b and M2 stay parked.
- **Held:** M3 (`Makefile`, `mk/m45.mk`) waits until attended #344 and #346 merge or close.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire's roles:
  - designer Opus 5.5 (Agent);
  - planner and executor codex gpt-6.1-sol;
  - evaluator Sonnet (Agent).
  Quorum $1.16 metered.
- **Watch:** gpt6-1-sol was unreachable as a quorum seat in both rounds. The fleet resolved the driver-pin removal (ailang#1999).
