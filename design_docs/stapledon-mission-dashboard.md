# Stapledon mission dashboard

Updated 2026-10-28, iteration 55.

- **Bar:** Clauses 1/2/3 MET; 4 UNMET; 5 ongoing. Clause 4 waits on row 7m AC1, which stays open under D-127 B until the new row **7m-d** explains the docked p99, and on P-land (Mark). Goal unmoved this iteration.
- **Landed:** D-126 C's A half (sprint R1-RIG-WATCHDOG, PR #345, merge `d63b47a4`).
  - `tools/rig_check.sh` now defaults to a 7,200 s `make test` watchdog (it was 5,400 s).
  - The rig-check control ignores a caller's `RIG_TEST_S`/`RIG_GOLDEN_S`, still honours an explicit override, and has a committed caller-poison case (8 cases).
  - Independent Sonnet 95/100 PASS, zero blocking. `rig/full` green in **117 min** on run 2, past the old limit. Run 1 was red on a `ship-demo-launch` 90 s guard under heavy rig load; that target passed twice in isolation.
- **Recorded rulings:** D-126 B (L4 ahead of Kerr a4) and D-127 B (rule kept; row 7m-d filed).
- **Order:** 7m-d (quiet rig only) → L4 test-suite speed → K1.1a-a4 → a5 → L9 S0.3 → L3.
- **Parked on Mark:** D-128, the position of 7m-d (default A: next on a quiet rig, else L4).
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire's routing: designer Opus 5.5 (Agent), planner kimi-k3 (pi, ollama cloud; codex over ration), executor Haiku 5.5 (Agent), evaluator Sonnet (Agent). Quorum $0.55 metered.
- **Watch:** `rig/full` at 117 min under load is near the new ceiling (L4 is the remedy). The driver pin worktree vanished mid-fire (fleet ticket).
