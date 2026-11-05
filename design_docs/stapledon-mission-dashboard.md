# Stapledon mission dashboard

Updated 2026-11-05, iteration 72.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, and on P-land, which is Mark's.
- **Landed this fire: row 7x batch B4a (PR #400, merge `31a20932`).**
  - 56 more Godot test gates in the top-level `Makefile` (ship demo, ship commons, tour, solar departure and others) now use the shared `$(SCRIPT_GATE)` rule: finish before the deadline, no `SCRIPT ERROR`, print a counted summary. 120 of 239 calls are migrated, and the baseline of unmigrated calls fell from 175 to 119.
  - Real gaps closed: five gates checked nothing at all and passed a broken script; six passed a run where every check crashed (`ship-demo: 0 passed, 0 failures`). Now all of these fail.
  - Found broken in a fresh clone: `ship-console-test` failed because nothing fetched its baseline files. It now fetches them, and the lint guards that link.
  - The baseline download could hang forever on a stalled server. It now gives up in about two minutes, and the test never starts.
  - Iteration 71's judge leftover is closed: dropping an asset prerequisite from the lint's list now fails.
  - Judge: Sonnet 90 PASS against a codex build (a different model family), zero blocking. The fast tier was green on the head and on the merge.
- **Not run: 7m-d S1.** The GPU was busy (87/57/48 %) and a remote-session process was up.
- **Order:**
  1. 7m-d S1 when `quiet2.sh` holds (four probe runs, taken first in the fire). Then OQ1–OQ5 go to Mark as one decision.
  2. 7aa (new): `sim-pipeline-test` fails on every run and nothing runs it. Headless, so it fits a busy rig.
  3. 7x B2b, B3b, B4b (65 GPU, golden and authoring gates) when a GPU window is free and the shared golden helper gets a count.
  4. D-129 (Mark) unlocks L4 M1b and M2.
- **For attended PRs #373, #379, #380, #384:** new `--script` gates must use `$(SCRIPT_GATE)` after rebase, or `script-gate-lint` fails.
- **Parked on Mark:**
  - D-146: should the designer rotation skip codex on this mission? Opus designed again this fire (fourth in a row) because a design must run Godot gates outside codex's sandbox. The recommendation is B. Default A (as now).
  - D-145: who fixes the nightly `sound-test` red (#392). The recommendation is B (the loop, test side only). Default A (stays attended).
  - D-128: where 7m-d sits in the order. Default A is applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A.
  - The S1 render review of `refs/m4_ship_s1/2026-11-04/`.
- **Backlog (non-blocking):** 7x B2b–B8; two judge survivors (a swapped prerequisite pair passes; the download bound has no static check); 14 targets that no aggregate runs (design D8); the 7w survivor; navigation-map redraws in transit; 7y (NT4); S0 guard variants; Kerr drills.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire ran the full inner loop: designer Opus (Agent tool), planner and executor codex gpt-6.1-sol, judge Sonnet (Agent tool). Metered spend about $1.07 (two quorum rounds).
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380), R3-TRUE-PROCESSED (#384), comms station v2 (#379).
- **Rig:** shared; the GPU was busy for most of the fire (Ollama). The main checkout is clean at `78f390c0`, behind origin; loop clones stage their own `runtime/` with `make runtime`.
