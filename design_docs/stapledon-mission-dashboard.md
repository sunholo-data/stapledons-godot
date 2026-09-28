# Stapledon mission dashboard (snapshot, overwritten each iteration)

- **Updated:** 2026-09-28, iteration 2.
- **Latest release:** review build `v0.1.0-m0` (M1.0); package `sunholo/relativity@0.2.0`.
- **Sprint:** R1-M1-SKY, 3/12 milestones (M1.0 ✅, M1.1 ✅, M1.2a ✅ PR #5). M1.6a built on
  draft PR #3, parked on AILANG VM bugs ailang#1354 and ailang#1355.
- **Next picks:** M1.2b AILANG catalogue transform (VM stress test) → M1.2c stats and tier
  commits → M1.2d HIP2 bright tier (D-5 accepted) → M1.3. M1.4a stops for Mark. M4 design doc
  is routable (D-6: isometric interior).
- **Bar:** ratified (D-1). Clauses 1–4 UNMET, 5 ongoing.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. Codex is over its daily ration,
  so the planner ran on pi kimi-k3 and the executor on pi deepseek-v4.1-flash; evaluator Sonnet
  (Agent tool).
- **Parked on Mark:** nothing open (D-1..D-6 resolved).
- **Harness tickets:** `mission-base:hardcoded-origin-dev`, `pi-runner:sandbox-extensions-not-wired`,
  `skill:gate0-ledger-provenance-S` (all non-blocking).
- **Toolchain:** rig PATH `ailang` v0.47; CI and the bundled runtime pin v0.45.0. Run local
  gates with `AILANG=$PWD/runtime/bin/ailang` until queue row 6 lands. `make test` now also runs
  the catalogue parser tests (`tools-test`).
