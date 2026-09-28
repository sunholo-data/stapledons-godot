# Stapledon mission dashboard (snapshot, overwritten each iteration)

- **Updated:** 2026-09-28, iteration 1.
- **Latest release:** review build `v0.1.0-m0` (M1.0); package `sunholo/relativity@0.2.0`.
- **Sprint:** R1-M1-SKY, 2/9 milestones (M1.0 ✅, M1.1 ✅). M1.6a built on draft PR #3,
  parked on AILANG VM bugs ailang#1354 and ailang#1355.
- **Next picks:** M1.2 catalogue pipeline (D-3, D-4 resolved); then M1.3; M1.4a stops for
  Mark. M1.6a resumes when a pinned AILANG passes `make strict` and 30× `parity-offaxis`.
- **Bar:** ratified (D-1). Clauses 1–4 UNMET, 5 ongoing.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. Designer rotation (Opus 5.5
  last), planner and executor codex gpt-6-sol, evaluator Sonnet (Agent tool).
- **Parked on Mark:** D-5 Hipparcos bright-star tier (default: M1.2 ships without it).
- **Harness tickets:** `mission-base:hardcoded-origin-dev`, `skill:gate0-ledger-provenance-S`
  (both non-blocking).
- **Toolchain:** rig PATH `ailang` v0.47; CI and the bundled runtime pin v0.45.0. Run local
  gates with `AILANG=runtime/bin/ailang` until queue row 6 lands.
