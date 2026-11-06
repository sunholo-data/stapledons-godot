# Stapledon mission dashboard

Updated 2026-11-06, iteration 73.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, and on P-land, which is Mark's.
- **Landed this fire: row 7aa (PR #402, merge `5c9f08ce`).**
  - `sim-pipeline-test` checks that the sim's pipelined heartbeats (the sim computes while the game draws) end in exactly the same world as synchronous ones. It had failed on every run since 2026-10-16.
  - The sim was fine. The test played two games in one process, and the Crew console's offer numbers carry on across games on purpose, so the two games sent different offers. The test now restarts the numbering for each game.
  - It can no longer pass by comparing two empty runs, it prints a counted summary, and it goes through the shared `$(SCRIPT_GATE)` rule (121 of 239 calls; baseline 119 → 118).
  - Not yet in the nightly: its timing check (pipelined under a quarter of synchronous) has never been measured on an idle rig, which is the risky case. That is new row 7ab.
  - Judge: Sonnet 93 PASS against a codex build (a different model family), zero blocking. The fast tier was green on the head and on the merge.
- **Not run: 7m-d S1.** The GPU was at 99–100 % and a remote-session process was up.
- **The nightly full suite has not started since 2026-11-04.** Its launchd job waits for the GPU to drop under 25 %, and the GPU has been at 88–100 % at every start time. Main has had no `rig/full` result since the red on `78f390c0` (#392).
- **Order:**
  1. 7m-d S1 when `quiet2.sh` holds (four probe runs, taken first in the fire). Then OQ1–OQ5 go to Mark as one decision.
  2. 7ac (new): make `crew-console-test` catch a per-console offer counter (about 8 lines, headless).
  3. 7ab (new): the timing ratio on an idle rig, then add `sim-pipeline-test` to the nightly.
  4. 7x B2b, B3b, B4b (64 GPU, golden and authoring gates) when a GPU window is free and the shared golden helper gets a count.
  5. D-129 (Mark) unlocks L4 M1b and M2.
- **For attended PRs #373, #379, #380, #384:** new `--script` gates must use `$(SCRIPT_GATE)` after rebase, or `script-gate-lint` fails.
- **Parked on Mark:**
  - D-146: should the designer rotation skip codex on this mission? Opus designed again (fifth fire in a row) because a design must run Godot gates outside codex's sandbox. The recommendation is B. Default A (as now).
  - D-145: who fixes the nightly `sound-test` red (#392). The recommendation is B (the loop, test side only). Default A (stays attended).
  - D-128: where 7m-d sits in the order. Default A is applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A.
  - The S1 render review of `refs/m4_ship_s1/2026-11-04/`.
- **Backlog (non-blocking):** 7x B2b–B8; judge survivors (a swapped prerequisite pair passes; the download bound has no static check; the sent journal does not record the heartbeat step); 14 targets no aggregate runs (design D8); the 7w survivor; navigation-map redraws in transit; 7y (NT4).
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire ran the full inner loop: designer Opus (Agent tool), planner and executor codex gpt-6.1-sol, judge Sonnet (Agent tool). Metered spend about $0.78 (two quorum rounds).
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380), R3-TRUE-PROCESSED (#384), comms station v2 (#379).
- **Rig:** shared; the GPU was busy all fire (Ollama), and macOS `mediaanalysisd` pushed the 1-min load to about 19 for a while. The main checkout is clean at `78f390c0`, behind origin; loop clones stage their own `runtime/` with `make runtime`.
