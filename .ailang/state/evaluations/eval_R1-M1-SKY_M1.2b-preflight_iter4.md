# Evaluation: R1-M1-SKY M1.2b-preflight, iteration 4

Reviewed HEAD `c24b5ad2de9dc2a2827f0bb01ef5eb4322f15498` against baseline `06311aa`. Judge: Anthropic Sonnet 5.5 (generator: OpenAI GPT-6.1 Sol).

**Verdict: PASS, 85/100 (threshold 70). No blocking findings.** Scope is M1.2b-preflight only; full M1.2b/AC2 is not complete and the sprint JSON `passes` for M1.2b stays null (verified). No visual/GPU changes (no .gd/.gdshader/.tscn in diff), so GPU gates are N/A.

| Category | Score |
|---|---|
| Tests pass | 20/20 |
| Lint / diff check | 9/10 |
| Acceptance (preflight criteria) | 27/30 |
| Code quality | 10/15 |
| Documentation | 11/15 |
| Design fidelity | 8/10 |

## Commands (mine)
- `make test AILANG=$PWD/runtime/bin/ailang`: rc 0 (sim 19/19, parser 15/15, physics, bridge, parity, off-axis, strict).
- `make catalogue-probe AILANG=$PWD/runtime/bin/ailang`: rc 0, status passed.
- `git diff --check`: clean. Runtime v0.47.2 (e939cba), Godot 4.7.2 confirmed.

## Measurements
- Real 5000 rows: normal 4580, WD 324, missing 96 (my Python recount agrees; WD+missing overlap is 0). Input `gcns.csv` and output hashes equal the executor's.
- VM x5 (strict, pure `render`): 0.646, 0.638, 0.642, 0.643, 0.645 s, mean 0.643 s; interpreter 11.48 s; peak RSS max 139.6 MB. All six outputs byte-identical.
- Scope: process start + args load + render + output, normal photometry only. Excludes FS shell read, WD fit, sort, binary writing. Medium x10 = 6.4 s and large x66.26 = 42.6 s are estimates, not gates.
- Independent numeric check: row 1 (BP-RP 2.8892) interpolates 3270 K to 3210 K in the cached 0.2.0 table to 3229.05 K, matching the pinned diagnostic.
- Changed code/test LOC 218 (cap 250).

## Mutations (each confirmed landed and typechecked before reading test result)
Killed, sole killer named: header (`exact header required`), WD as normal and WD gets main-sequence (`real rows preserve IDs...`), constant Teff, V=G, dropped reverse (`real normal row expected photometry`; the solar-anchor test calls the package directly and does not kill package bypass), WD flag (`invalid WD flag rejected`), finite() (`nonfinite photometry rejected`), dropped WD rows (two tests).
Survived unit tests but killed by the runner: M3 missing=AND (real5k accounting), M9 duplicated row (fixture rows check).
**Survived everything:** M10 WD/missing overlap counting, M12 blank ID, M13 unchecked y.
Runner: parity assert is the sole detector of tampered VM output (control shown both ways); timeout to 3 s fails nonzero, replaces stale report, keeps partial stdout/stderr; missing gcns.csv refuses; fake v0.47.1 runtime refuses.
All files restored from copies; sha256 identical; `gcns.csv` hash verified.

## Findings (all non-blocking)
- **F1** (low): WD-with-missing-photometry overlap is unpinned: mutant M10 survives every test and the runner; the fixture has disjoint WD and missing rows and the first 5000 real rows have zero overlap. Counters are documented as independent but nothing asserts it. Add an overlap row in the later production task.
- **F2** (low): Row validation is only partially pinned: blank ID (M12) and unchecked y (M13) mutants survive; wrong field count and z untested by name. Partial-blank photometry (M3) and duplicate rows (M9) are killed only by the Python runner, not by a named AILANG test.
- **F3** (low): Numeric diagnostics are pinned at exactly one real row (Teff 3229.0499999999997, V 17.1398), which I re-derived independently by linear interpolation of the cached 0.2.0 table between BP-RP 2.78 (3270 K) and 2.94 (3210 K) = 3229.05 K. The runner asserts only structural suffixes for normal rows, so a package bypass on the runner path alone is only caught by the unit test.
- **F4** (low): Retained original acceptance still says 'including the five rows above' but the test table it pointed at was deleted from the sprint doc, along with the old task/D-4/Makefile detail. Dangling reference; the replacement text keeps the encoder correction and dependency split but the deleted checkF32*/checkMediumSelection/checkWDRow specs are no longer written down.
- **F5** (info): Interpreter needs 11.5-12.5 s for 5000 rows (measured); scaled by 10 it is ~115 s for medium, above the runner's 60 s per-run bound, so the same runner design cannot do interpreter parity at medium scale. Later integration must resolve this without silently raising the bound.
- **F6** (info): Strict proof covers only pure render (std/fs readFile and list.reverse have no strict support); main/FS shell parity checked only on the 3-row fixture, not 5000 rows. Documented by the executor; controller owns upstream reports (not touched by me).
- **F7** (info): sim/tools/.ailang/ (cache) is created by test runs and is untracked/not ignored.

## Unmeasured / not claimed
Production WD fit, sort, float32 writer, full-pipeline timing and the >60 s medium fallback threshold. I did not run mutation M11 (field count) or push the constant-Teff mutant through the runner. Human gates (WD passband model, thresholds, Python fallback, upstream reports, render review) are parked, not resolved.

No commits, pushes or messages were made. Artifacts: `.ailang/state/evaluations/eval_R1-M1-SKY_M1.2b-preflight_iter4.{json,md}`.
