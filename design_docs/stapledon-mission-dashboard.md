# Stapledon mission dashboard

Updated 2026-11-04, iteration 69.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, and on P-land, which is Mark's.
- **Landed this fire: row 7x, first batch (PR #393, merge `49eb35d9`).** A Godot test script that fails to parse exits 0, and one that hits an error before `quit()` hangs. Until now `make` gates trusted the exit code.
  - Five gates now go through one shared rule, `$(SCRIPT_GATE)`: the run must finish before its deadline with the right exit code, have no `SCRIPT ERROR`, and print its own counted summary. The five are `make sim`'s bridge step, `ui`, `area-test`, `test-bright-audit` and `star-catalogue-test`.
  - `make script-gate-lint` lists all 237 `--script` calls. The 232 not yet migrated sit on a pinned baseline that can only shrink, so a new unchecked gate fails the build.
  - Judges: Sonnet 88 PASS and GLM 5.3 93 PASS (a different model family), zero blocking. Full `make sim` and the Linux fast tier were green.
- **Nightly red: `sound-test` S2 (#392).** It fails on a quiet rig too, so the cause isn't load. Nobody owns it since R2-SOUND landed. Asked as **D-145**.
- **Not run: 7m-d S1.** The GPU was busy at the check (99 %, Ollama).
- **Order:**
  1. 7m-d S1 when `quiet2.sh` holds (four probe runs, taken first in the fire). Then OQ1–OQ5 go to Mark as one decision.
  2. 7x follow-up batch B2 (42 gates in regions no open PR touches), then B3/B4.
  3. D-129 (Mark) unlocks L4 M1b and M2.
- **For attended PRs #379, #384, #380:** new `--script` gates must use `$(SCRIPT_GATE)` after rebase, or `script-gate-lint` fails.
- **Parked on Mark:**
  - D-145: who fixes the nightly `sound-test` red. The recommendation is B (the loop, test side only). Default A (stays attended).
  - D-128: where 7m-d sits in the order. Default A is applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A.
  - The S1 render review of `refs/m4_ship_s1/2026-11-04/`.
- **Backlog (non-blocking):** 7x batches B2–B8 and two judge survivors; the 7w survivor; navigation-map redraws in transit; 7y (NT4); S0 guard variants; Kerr drills.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire ran the full inner loop: designer Opus, planner kimi-k3 (pi), executor Haiku, judges Sonnet and GLM 5.3. Codex was over its ration. Metered spend about $2.34.
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380), R3-TRUE-PROCESSED (#384), comms station v2 (#379).
- **Rig:** shared. The main checkout's `runtime/bin/ailang` is v0.54.18 against the v0.56.1 pin; loop clones use their own.
