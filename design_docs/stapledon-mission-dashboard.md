# Stapledon mission dashboard (snapshot, overwritten each iteration)

- **Updated:** 2026-09-30, iteration 3.
- **Latest release:** review build `v0.1.0-m0` (M1.0); package `sunholo/relativity@0.2.0`.
- **Sprint:** R1-M1-SKY, 4/12 milestones (M1.0 ✅, M1.1 ✅, M1.2a ✅, M1.6a ✅ PR #3
  `5218160`, eval 87). The two AILANG VM bugs that parked M1.6a are fixed in the
  pinned v0.47.2; resume predicate verified first-party.
- **Next picks:** M1.2b AILANG catalogue transform (VM stress test) → M1.2c stats and
  tier commits → M1.2d HIP2 bright tier (D-5 accepted) → M1.3. M1.4a stops for Mark.
  M1.6b (camera + golden) unblocked behind M1.2b. AI service foundation (row 2, D-9)
  is routable when M1 pauses on Mark; M4 design doc routable (D-6).
- **Bar:** ratified (D-1). Clauses 1–4 UNMET, 5 ongoing.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire: codex and
  ollama over ration; controller pi glm-5.3, evaluator Sonnet (claude-sub recipe —
  the pi harness has no Agent tool). Three slots burned between iterations 2 and 3
  (watchdog kill, gate-2 crash, session-protocol deadlock); none landed.
- **Parked on Mark:** nothing open (D-1..D-9 all RESOLVED).
- **Harness tickets:** `mission-base:hardcoded-origin-dev` (repeat, non-blocking),
  `skill:gate0-ledger-provenance-S` (non-blocking); `pi-runner:sandbox-extensions-not-wired`
  and `rig:aqua-session-lost` resolved by the fleet (`eec86ca4`), acked.
- **Toolchain:** CI and the bundled runtime pin v0.47.2 (repin `07d44e6`); rig PATH
  `ailang` v0.48.0 differs, so run local gates with `AILANG=$PWD/runtime/bin/ailang`
  (queue row 6 still open). Local `runtime/` in the main checkout was stale at
  v0.45.0 this fire; `make runtime` in a fresh worktree stages v0.47.2.
