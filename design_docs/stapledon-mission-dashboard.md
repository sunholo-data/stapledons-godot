# Stapledon mission dashboard

Updated 2026-11-04, iteration 70.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, and on P-land, which is Mark's.
- **Landed this fire: row 7x batch B2a (PR #395, merge `55de0d8a`).**
  - 28 more Godot test gates in nine `mk/` files now use the shared `$(SCRIPT_GATE)` rule: finish before the deadline, no `SCRIPT ERROR`, print a counted summary. 33 of 237 calls are migrated, and the baseline of unmigrated calls fell from 232 to 204.
  - The gate now rejects a summary pattern that would still match with any one count set to zero. That closes both of the last judges' leftovers.
  - Real gap closed: a dust-flash test with a runtime error used to "pass" with 26 of 29 checks run. Now it fails.
  - `constellation-test` now fetches the star data it needs. Before, it failed in a fresh clone.
  - Judge: Sonnet 92 PASS against a codex build (a different model family), zero blocking. The fast tier was green on the head and on the merge.
- **Not run: 7m-d S1.** The GPU was busy at all three checks (94–99 %, Ollama).
- **Order:**
  1. 7m-d S1 when `quiet2.sh` holds (four probe runs, taken first in the fire). Then OQ1–OQ5 go to Mark as one decision.
  2. 7x B3 (37 gates in `mk/levels.mk`, `mk/m5.mk`, `mk/ai.mk`) and B4 (86 in `Makefile` 1080+). B2b (14 GPU, asset-tool and bench gates) when a GPU window is free.
  3. D-129 (Mark) unlocks L4 M1b and M2.
- **For attended PRs #379, #384, #380:** new `--script` gates must use `$(SCRIPT_GATE)` after rebase, or `script-gate-lint` fails. The gate now also refuses a summary pattern that accepts zero counts.
- **Parked on Mark:**
  - D-145: who fixes the nightly `sound-test` red (#392). The recommendation is B (the loop, test side only). Default A (stays attended).
  - D-128: where 7m-d sits in the order. Default A is applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A.
  - The S1 render review of `refs/m4_ship_s1/2026-11-04/`.
- **Backlog (non-blocking):** 7x B2b–B8; the judge survivor (nothing guards `constellation-test`'s data prerequisite); the 7w survivor; navigation-map redraws in transit; 7y (NT4); S0 guard variants; Kerr drills.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire ran the full inner loop: designer Opus (Agent tool), planner and executor codex gpt-6.1-sol, judge Sonnet (Agent tool). Metered spend about $1.02 (two quorum rounds).
- **Routing note:** the designer rotation has not advanced for two fires (69: codex over ration; 70: the design needed Godot runs that codex's sandbox can't make).
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380), R3-TRUE-PROCESSED (#384), comms station v2 (#379).
- **Rig:** shared. Iteration 69's evaluator left two hung Godot processes for 7.6 h; they were killed this fire. The main checkout's `runtime/bin/ailang` is v0.54.18 against the v0.56.1 pin; loop clones use their own.
