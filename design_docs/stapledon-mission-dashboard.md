# Stapledon mission dashboard

Updated 2026-11-05, iteration 71.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, and on P-land, which is Mark's.
- **Landed this fire: row 7x batch B3a (PR #397, merge `b34fd1ef`).**
  - 29 more Godot test gates (levels, planets, AI) now use the shared `$(SCRIPT_GATE)` rule: finish before the deadline, no `SCRIPT ERROR`, print a counted summary. 63 of 238 calls are migrated, and the baseline of unmigrated calls fell from 204 to 175.
  - Real gaps closed: the planets test used to "pass" a broken script, and a run that skipped 42 of its 121 checks. Three AI tests passed a script that didn't load. Now all of these fail.
  - Found broken on main: `alpha-centauri-golden` failed on every run because its pattern rejected its own output, and nothing ran it. Now it passes.
  - A new check in the lint notices when a test loses the asset download it needs (star data, planet textures). That closes iteration 70's judge leftover.
  - Judge: Sonnet 91 PASS against a codex build (a different model family), zero blocking. The fast tier was green on the head and on the merge.
- **Not run: 7m-d S1.** The GPU was at 100 % at both checks.
- **Order:**
  1. 7m-d S1 when `quiet2.sh` holds (four probe runs, taken first in the fire). Then OQ1–OQ5 go to Mark as one decision.
  2. 7x B4 (86 gates in `Makefile` lines 1080+). B2b and B3b (22 GPU, golden and asset-tool gates) when a GPU window is free and the shared golden helper gets a count.
  3. D-129 (Mark) unlocks L4 M1b and M2.
- **For attended PRs #379, #384, #380:** new `--script` gates must use `$(SCRIPT_GATE)` after rebase, or `script-gate-lint` fails.
- **Parked on Mark:**
  - **D-146 (new):** should the designer rotation skip codex on this mission? Codex's sandbox can't run the Godot gates a design must measure, so the loop has kept Opus for three fires. The recommendation is B (skip codex as designer; keep it as planner and executor). Default A (as now).
  - D-145: who fixes the nightly `sound-test` red (#392). The recommendation is B (the loop, test side only). Default A (stays attended).
  - D-128: where 7m-d sits in the order. Default A is applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A.
  - The S1 render review of `refs/m4_ship_s1/2026-11-04/`.
- **Backlog (non-blocking):** 7x B2b–B8; the judge survivor (nothing checks the prerequisite list itself); the 7w survivor; navigation-map redraws in transit; 7y (NT4); S0 guard variants; Kerr drills.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire ran the full inner loop: designer Opus (Agent tool), planner and executor codex gpt-6.1-sol, judge Sonnet (Agent tool). Metered spend about $0.90 (two quorum rounds).
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380), R3-TRUE-PROCESSED (#384), comms station v2 (#379).
- **Rig:** shared; the GPU was at 100 % all fire. The main checkout's `runtime/bin/ailang` is v0.54.18 against the v0.56.1 pin, and a fresh clone has no `runtime/` until `make runtime`; loop clones stage their own.
