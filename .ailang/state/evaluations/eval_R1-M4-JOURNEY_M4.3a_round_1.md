# Evaluation Report: M4.3a_TRANSIT_WARP_HUD

**Sprint**: R1-M4-JOURNEY · **Milestone**: M4.3a  
**Result**: PASS — **95 / 100**  
**Evaluator**: claude-sonnet-4-6 (iter14-eval, independent judge)  
**Generator**: claude-sonnet-5-5 (iter13-executor)  
**Date**: 2026-10-05  
**Worktree**: `.wt-stapledon-iter14-eval` @ commit 4b92429 (PR #115)

---

## Score Breakdown

| Category | Earned | Max |
|---|---|---|
| Tests Pass | 19 | 20 |
| Lint Clean | 10 | 10 |
| Acceptance Criteria | 30 | 30 |
| Code Quality | 12 | 15 |
| Documentation | 15 | 15 |
| Design Fidelity | 9 | 10 |
| **Total** | **95** | **100** |

Threshold: 70. **PASS**.

---

## Automated Gate Results

| Gate | Result |
|---|---|
| `make transit-test` | PASS — 39/39 |
| `make strict` (transitVm) | PASS — VM = interpreter |
| `make replay` (arm64) | PASS — sha256 e1a8a7818d5278d5 matches golden |
| `make test` | TIMEOUT — 1609 lines, no failures seen; sub-targets all green |
| `make golden` / `make capture` | UNMEASURED — no display server in eval env |

---

## Acceptance Criteria

All 10 M4.3a acceptance criteria met:

- **Transit loop** on sky-only harness: `TransitHarness.run_session()` drives boost→cruise→brake→arrived
- **Warp as intent**: `IWarp(float)` accepted while committed, refused otherwise; 0.002/0.01/0.05 only
- **3s burn pacing**: `BURN_REAL_S=3.0`; dtau = `phase_remaining_yr * real_dt / 3.0` (deterministic, no wall-clock)
- **HUD via DisplayBinding**: all 12 readout rows + 2 clocks are `DisplayBinding` instances; `audit()` positive-control passes
- **Arrival card**: binds `journey.plan.*` and `consequence.gap_years`; visible on `journey.state == "arrived"`
- **Protocol 2.2 additive**: 5 new consequence fields; digest `e701da00be0a7012` unchanged
- **standoff_au 1000**: `Transit.STANDOFF_AU = 1000.0`; sent in `new_game_params()`; replay log confirms; M4.1 finding 4 satisfied
- **Warp levels 0.002/0.01/0.05**: `isWarpLevel()` in core.ail; bad level → `bad_intent` on wire
- **Replay byte-identical** (arm64): 429-line input log; arm64 golden passes
- **Solar constant 1361 W/m²** (IAU 2015): `solarConstantWM2() = 1361.0`; executor mutation 1360 killed

---

## Mutation Drills (unlisted by executor)

| # | Mutation | File | Result |
|---|---|---|---|
| E-1 | `ArrivalCard` gap → `clock.tau` instead of `consequence.gap_years` | `ui/arrival_card.gd` | **KILLED** |
| E-2 | Glow format: `"onoff"` → `"sci W/m2"` | `ui/journey_hud.gd` | **KILLED** |
| E-3 | `settle()`: `for r in refused` → `for r in []` | `bridge/transit.gd` | **SURVIVED** |

E-3 surviving is a minor finding (see below). E-1 and E-2 confirm the test suite exercises both the arrival card and the HUD format specifiers.

---

## Findings

### F1 — Minor: `Transit.settle()` dead code path (no blocking)

`settle()` in `bridge/transit.gd` (line ~58) iterates `refused` to find a refused `IWarp` that was included by `step()`. This can never trigger in practice: `step()` only emits `IWarp` while committed, and committed `IWarp` is never refused by the sim. The mutation `for r in []:` SURVIVED all 39 tests.

The behavior is correct (the code does the right thing if it were ever reached), but the path is untestable without constructing an impossible sim state.

**Recommendation**: Add a comment explaining the defensive intent, or remove the dead branch. If kept, add a unit test that directly invokes `settle()` with a synthetic refused list.

### F2 — Informational: x86_64 replay golden not committed

Known ailang#1465 (exp/log differ 1 ulp arm64 vs x86_64). The arm64 golden is committed and passes. x86_64 golden is being recorded in draft PR #118. No M4.3a code change needed.

### F3 — Informational: GPU visual capture not performed in eval

`make capture` and `make golden` require a display server. Not available in the eval session. Maintainer should run `make capture` and open `renders/*.png` before final merge.

---

## Summary

The M4.3a implementation is solid. All test-first acceptance criteria are met, the physics constants are correct (1361 W/m², deterministic dtau, no 1.0-beta in GDScript), the HUD uses DisplayBinding throughout, protocol 2.2 is additive, and the replay is byte-identical on arm64. The one finding of note (settle() dead code) is defensive code that doesn't cause incorrect behavior. **0 blocking findings.**
