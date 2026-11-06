# Stapledon mission dashboard

Updated 2026-11-06, iteration 74.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, and on P-land, which is Mark's.
- **Landed this fire: nothing built.** Row 7ac is designed and measured, but it is parked behind a new prerequisite, row 7ad.
  - 7ac makes `crew-console-test` catch a Crew console that numbers its offers per console instead of across the whole game. With that numbering, two consoles repeat an offer id and the sim refuses the second offer. The fix is 11 test lines; seven drills prove it, including two that stop a hung run.
  - Three review rounds. In round 3 two reviewers passed it. The third (GPT-6.1 Sol) blocked it: the real `crew-console-test` has no time limit, and the sim it starts escapes the timeout's process group. That is true of every Godot `--script` gate today, not just this one. It becomes row 7ad, and 7ac waits for it.
  - No judge ran, because nothing was built.
- **Not run: 7m-d S1** (seventh fire in a row). The GPU was at 26–80 % and three Screen Sharing processes were up on the Studio.
- **The nightly full suite has not started since 2026-11-04** (it waits for the GPU to drop under 25 %). Main has had no `rig/full` result since the red on `78f390c0` (#392).
- **Order:**
  1. 7m-d S1 when `quiet2.sh` holds (four probe runs, taken first in the fire). Then OQ1–OQ5 go to Mark as one decision.
  2. 7ad (new): a timeout runner that also stops the sim, used by `crew-console-test` and `tools/script_gate.sh`. Headless; touches `Makefile`.
  3. 7ac: re-run its checks once 7ad lands, re-review once, then build.
  4. 7ab: the timing ratio on an idle rig, then add `sim-pipeline-test` to the nightly.
  5. 7x B2b, B3b, B4b (64 GPU, golden and authoring gates) when a GPU window is free.
- **For attended PRs #373, #379, #380, #384:** new `--script` gates must use `$(SCRIPT_GATE)` after rebase, or `script-gate-lint` fails.
- **Parked on Mark:**
  - D-146: should the designer rotation skip codex on this mission? Opus designed again (sixth fire in a row). The recommendation is B. Default A (as now).
  - D-145: who fixes the nightly `sound-test` red (#392). The recommendation is B. Default A (stays attended).
  - D-128: where 7m-d sits in the order. Default A is applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A.
  - The S1 render review of `refs/m4_ship_s1/2026-11-04/`.
- **Backlog (non-blocking):** 7x B2b–B8; judge survivors from 7x/7aa; 14 targets no aggregate runs; the 7w survivor; navigation-map redraws in transit; 7y (NT4); the `design_docs/**` whitespace exemption is wider than needed (7ac r3, glm and kimi).
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire: designer Opus (Agent tool), three quorum rounds; planner, executor and judge not reached. Metered spend about $1.15.
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380), R3-TRUE-PROCESSED (#384), comms station v2 (#379).
- **Rig:** shared; the GPU was busy most of the fire and Screen Sharing sessions were open. The main checkout is clean at `78f390c0`, behind origin; loop clones stage their own `runtime/` with `make runtime`.
