# Evaluation: M1.2b-T2_F32_RECORDS (iteration 8, round 1)

**Evaluator:** Claude Sonnet 5.5 (`claude-sonnet-5-5`), independent of generator OpenAI GPT6.1 Sol.
**Commit:** c9cd720 vs base 19f55bf, plan d4e9498. Runtime `runtime/bin/ailang` v0.50.0 (6abe1a5).

## Verdict: PASS, 92/100, 0 blockers
Child T2 only. Parent M1.2b, T3 (sidecars/writer), T4 (full integration, N3 quota, perf) are NOT passed and stay incomplete.

| Category | Pts | Notes |
|---|---|---|
| Tests | 20/20 | check rc0 (86s), test 32/32 (106s), oracle rc0, catalogue-vm/bytes rc0, `make test` rc0 (147s) |
| Lint | 10/10 | no lint target; `ailang check --package sim` clean |
| Acceptance | 30/30 | all 5 criteria verified (last one is this evaluation + LOC 133 <= 250) |
| Quality | 14/15 | -1: sprint JSON `completed` null by design; no TODOs; files small |
| Docs | 13/15 | CHANGELOG ok; no example needed per plan; design doc stays planned (parent open) |
| Fidelity | 9/10 | matches contract; strict-codec N/A per instruction |

## Independent evidence
- LOC: +130/-3 = 133 in Makefile/sim/tools (cap 250).
- Own byte oracle: rows incl. 1e-46 underflow, -0.0, max finite, 1.0000001, flags 31, empty, invalid flags 32/-1, invalid 2nd row, 3.4028235e38; interpreter == `--bytecode` == Python `struct.pack('<6f')`; refusals whole-output `[-1]`. NaN/+-Inf in every field refused on both backends.
- Mutation drills (my own set, SHA256 verified after each; sources identical afterwards): 26 killed, 1 redundant survivor (`v == v`), 1 no-op of mine discarded, 1 initially non-compiling mutant recompiled and killed. Per-field guards, both range bounds, both flag bounds, sticky error, no-prefix, order, flags, final reversal, duplicate all killed by named cases.
- N1/N2: mutants give `transform-BAD` with new strict tests but `transform-ok` against base tests (N1 wrong WD predicate, N2 strip-all-blanks), so the new tests are what kill them.
- Core strict (`make strict`) and parity green inside `make test`; codec strict gate N/A (Phase2E).

## Findings (all P3, none blocking)
1. Oracle transports flags as float and uses `[-1]` refusal sentinel (test-only; CLI cannot decode Row alias, reported upstream).
2. `v == v` guard redundant (equivalent mutant).
3. Conservative range bound refuses 3.4028235e38 (documented; T3/T4 should confirm no real row hits it).
4. Native codec not under strict VM until Phase2E.

Logs: `.ailang/state/evaluations/iteration8-logs/` (commands.txt, check/test/oracle/catvm/make-test logs, mutations_run1/2.log, n1n2_drill.log).

EVALUATION_RESULT: pass
EVALUATION_SCORE: 92/100
