# Execution report: social_dynamics 0.4.1 keyed `sortedJson` (row 7av, D-171 A)

**Iteration 109, 2026-11-21 (unattended).** Design: [m4-7av-sortedjson-keyed-sort.md](m4-7av-sortedjson-keyed-sort.md). Sprint: [m4-7av-sortedjson-keyed-sort-sprint.md](m4-7av-sortedjson-keyed-sort-sprint.md), `.ailang/state/sprints/sprint_R1-M4-7AV-SORTEDJSON.json`.
**Package PR:** [sunholo-data/ailang-packages#206](https://github.com/sunholo-data/ailang-packages/pull/206), OPEN and not merged. Branch `fix/social-dynamics-sortedjson-keyed`, three commits on `6991f54`: tests on 0.4.0 (`2a36c86`), the line (`31c23f7`), release metadata (`2935883`). **Nothing was published. The game's pin is unchanged.**

**Who ran what.**
- Executor: codex `gpt-6.2-sol`, sandboxed, workspace-write on the package clone. It did SJ2, SJ1, SJ3 and the mutations, and wrote the Appendix A scripts.
- Controller: re-ran every package gate and the mutations outside the sandbox, and ran AC8–AC13.
- Every number below is the controller's out-of-sandbox reading.

**Toolchain:** AILANG v0.56.1 (`runtime/bin/ailang`). Game base: main `059bad3c`.

**Evidence:** [7av-iter109-evidence.tgz](https://storage.googleapis.com/stapledons-voyage-assets/benchmarks/7av-iter109/7av-iter109-evidence.tgz), `gs://stapledons-voyage-assets/benchmarks/7av-iter109/7av-iter109-evidence.tgz`, 6,646,488 B, sha256 `057f6be98bf8aca9b1ff8c485d6b11a715d357dff12a8f5382329c2a38fd5d79` (re-downloaded and checked). It holds `ctl/` (the controller's logs), the executor's logs, the scripts and the milestone snapshots.

| AC | Reading | Verdict |
|---|---|---|
| AC1 | SJ1's line greps `1` in `wire.ail`. The diff against `origin/main` is only `packages/social-dynamics/{wire.ail,wire_test.ail,ailang.toml,CHANGELOG.md}` (4 files, +34 −4). | PASS |
| AC2 | `test --allow-skips wire.ail`: `13 tests: 8 passed, 0 failed, 5 skipped`, with 6 `sortedJson` tests ✓, including the 120-order tie test. | PASS |
| AC3 | `check --package .`: 18 files, all passed. `test --package .`: `146 tests: 146 passed, 0 failed, 0 skipped`. | PASS |
| AC4 | `pkg quality .` and `--strict .`: rc 0, `quality sunholo/social_dynamics@0.4.1`, `release: kind fix changelog_section true`, `interface: ✓ v2 3d27ec9e9e00… (156 signatures)`, `✓ no gates`. Out of the sandbox the registry overlap check could reach the network; inside, the executor's run was UNINFORMATIVE on it (DNS). | PASS |
| AC5 | `publish --dry-run`: `Interface hash: sha256:9b3a358aa0d8e54d50343eebc1fb0cdea4824749e0110e331ad596545d1d9ed2` and "Tarball ready but not uploaded". The clone has no stray files. `pkg versions` still reads `v0.4.0 ← latest`. The tarball content hash is `sha256:09a86dc2…c688`. It covers the 0.4.1 `ailang.toml`. That makes it a different hash from AC8–AC12's `3fd1ec48…`, which hashes the PR's `wire.ail` in the 0.4.0 slot with 0.4.0's `ailang.toml` (judge N1). The design's V-o and V-q hashes (`533967f1…`, `c81cfc63…`) come from the designer's rehearsal tree, not from this tree. | PASS |
| AC6 | Package and inline failures per mutant: M1 1 package and 6 inline; M2 2 and 6; M3 2 and 6. Each mutant fails the tie test. E1 is an observation only: 146 package passes and 8 inline passes. Before the new tests, M1 survived the 0.4.0 suite (145/145; executor `base_M1-*`). | PASS |
| AC7 | `sed -n 3p CHANGELOG.md` gives `## 0.4.1`. `ailang.toml` has `version = "0.4.1"` and `kind = "fix"`. | PASS |
| AC8 | Locks, each from a path dependency: x0 `3ecabb4a…` (0.4.0), x1 `3fd1ec48…` (PR), xM `8beeaba5…` (M1). Results: `x0 vs x1: same 10 DIFF 0` and `x0 vs xM(M1): same 0 DIFF 10`. | PASS |
| AC9 | PC-A: rc 1, `content changed (locked: …3ecabb4a…, current: …3fd1ec48…)`. PC-B: rc 1, the same message with the two hashes swapped. The slot's `wire.ail` and the PR's `cmp` equal. | PASS |
| AC10 | `ship.ail` under the scratch pin on `h4.req.ndjson` gives 640 lines, sha256 `dd62855ccabb348d227cf2af30ffa978560e60525127813a14934fb40e5f1d04`. | PASS |
| AC11 | See the table below. | MEASURED |
| AC12 | Negative controls (real HOME, edited lock): strict, parity, replay and crew-parity each give rc 2, each with the `content changed (locked: NEW, current: OLD)` line (1, 1, 12 and 1 occurrences). Positive runs (scratch HOME), all rc 0: `strict` in 220 s (`digestScripted … a9a7c96e…`); `parity` in 73 s (`1 cases, all identical`); `replay` in 96 s, within its 1,200 s bound (`12 cases, all identical`); `crew-parity` in 50 s (`ok (6 recordings, VM == interpreter …)`). | PASS |
| AC13 | `git status --porcelain -- sim` in this clone is empty. The scratch clone's diff is only `sim/ailang.lock`. `diff origin/main -- sim/ailang.toml sim/ailang.lock` is empty. | PASS |
| AC14 | #206 reads `OPEN`, with title `social_dynamics 0.4.1: …`. Its body quotes AC4's numbers, AC11's table and §2's #144 sentence. | PASS |

## AC11: the decision-day step (sim tick 460 = request line 462; 50 calls per run; A = 0.4.0, real HOME; B = 0.4.1, scratch HOME; interleaved A B A B A B)

| Pair | A ms/call | B ms/call | A − B | 1-min load A / B |
|---|---|---|---|---|
| 1 | 64.80 | 45.06 | 19.74 | 3.72 / 4.56 |
| 2 | 66.48 | 43.92 | 22.56 | 4.12 / 4.19 |
| 3 | 65.08 | 43.52 | 21.56 | 3.70 / 3.57 |

**Control tick 459:** 16–17 ms per 50 calls (0.32–0.34 ms) in both arms.
**Earlier readings:** iteration 108 measured 64.1–64.8 → 43.6–44.1. The design run's pairs (V-n) were Δ 20.1–21.3.
**This run's verdict:** the keyed sort saves 19.7–22.6 ms of the roughly 65 ms decision-day step.

**AC12 is not cleared.** A decision day is still about 44 ms of step plus about 18 ms of reply diff and encode, about 62 ms against the 50 ms tick window. Only O3 (D-171 B) takes the wait out of the frame, or a decomposition of the remaining 44 ms (F3) might.

## Not done (by design, or follow-ups)

- **F2 (Mark):** publish 0.4.1, then crew_core 0.6.1 pinned to it. crew_core 0.6.0 pins social_dynamics `0.4.0` exactly. Then the game pin.
- **F1:** O3.
- **F3:** decompose the remaining ~44 ms.
- **F4:** the off-cadence bursts.
- **F5:** close #144 (Mark).
- **F6:** the DX report to AILANG about the path dependency silently replaced by a transitive pin. Sent this iteration; see the mission log entry for its message id.
