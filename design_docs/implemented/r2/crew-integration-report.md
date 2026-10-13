# R2-CREW: report

**Status:** C0–C6, C8 and G1 built and evaluated (2026-10-13/14). Evaluation round 1: 74/100, a hard fail (`make ai-test` red through `ai-live-guard`). Round 2: **PASS 88/100** (Claude Sonnet, a separate agent; generator ≠ judge). In review as PR #224, stacked on #226 (AILANG v0.54.8).
Design: [crew-integration.md](crew-integration.md). Plan: [crew-integration-sprint.md](crew-integration-sprint.md). Progress: `.ailang/state/sprints/sprint_R2-CREW.json`. Evaluations: `.ailang/state/evaluations/eval_R2-CREW_round_{1,2}.json`.

## Toolchain

| | |
|---|---|
| AILANG | **v0.54.8** (#226). It fixes ailang#1812, found here: a cold compile of crew_core took ~20 GB RSS on v0.54.6; the whole sim now compiles cold in ~16 s / 0.5 GB |
| `sunholo/crew_core` | **0.3.0**, a registry pin (ailang-packages #138, `82c21dd`), replacing the vendored 0.2.0 at G1 |
| `sunholo/social_dynamics` | 0.4.0 |
| Godot | 4.7.2-stable |
| Machine | Mac Studio, Apple M4 Max (darwin arm64) |

## Acceptance criteria

| # | Check | Result |
|---|---|---|
| AC1 | crew_core 0.3.0, lab validation and evaluation | Upstream: ailang-packages #138 (crew-lab agent) |
| AC2 | `make deps`: the registry pin resolves unchanged | pass |
| AC3 | `make crew-parity`: 4 recordings (consent, orders, shipevent, argument), the game equals standalone crew_core byte for byte, VM == interpreter | pass (a drop-a-line mutation fails all four) |
| AC4 | `make strict`: the crew scripts on the strict VM == the interpreter | pass |
| AC5 | Determinism: `make replay` (11 cases identical), `parity-v2`; crew draws move only the crew stream | pass; no golden was re-recorded (every recording runs at minor ≤ 8, where no crew can be aboard) |
| AC6 | `sim/protocol_crew_test.ail` (10), `make crew-bridge-test` (11) | pass |
| AC7 | `make crew-sync-check` (hashes, regeneration, round trip) and the resource lint against the ship | pass |
| AC8 | `sim/crew_events_test.ail` (8; a world journey raises `drive-1` and `arrive-1` once each), `make crew-events-check` | pass |
| AC9 | `make ai-test` (crew_reply prompt golden, stub results, cache sums), `sim/crew_ai_test.ail` (4: one request per ask, `ai_internal` for engine internals) | pass |
| AC10 | `make crew-console-test` (22 checks on a crew section recorded from the real sim) | pass |
| AC11 | `make crew-perf`: a 10-year skip in **0.46 s** (critical_only; a hold stops auto-run) and **0.88 s** (worst case, no holds), against a 2 s budget | pass |
| AC12 | `make test` locally and in CI | Targeted gates green locally; CI to confirm on #224 |
| AC13 | Auto-run is deterministic, and standing-order decisions use crew_core's journal | pass (`crew_hold_test`) |
| AC14 | Each escalation stops auto-run with a hold; days pass while decisions wait; `crew_resume` | pass (`crew_hold_test`) |
| AC15 | `make crew-hold-test` (9) and no-twitch NT3 (the Crew page and hold card with the crew aboard) | pass (a single-press-policy mutation fails NT3) |

## Measurements

- **Cold compile** (ailang#1812). On v0.54.6 crew_core's `session.ail` alone took 20.4 s / 19.4 GB, and the whole sim 35 s / 20.4 GB. On v0.54.8 they take 4.6 s / 245 MB and 15.7 s / 533 MB.
- **Skips.** Plain crew days are batched between flow points: a yielding task's due tick and each unseen ship event. The result equals one advance a day on every parity script plus a 400-day tail. With archiving on (`keep` 30), the archived event ids are the same set in another order; crew_core 0.4.0 sorts them.
- **Crew view:** about 1.5 KB per state line. crew_core's own trace is about 40 KB.

## Decisions taken in the sprint (Mark, attended)

- **D-70:** one turn per ship-day, role ids with display names, last-messages-home first, the drive mass bill as a readout, consent by default, an ergosphere third heat user.
- **D-72:** the sprint plan approved, starting on vendored 0.2.0, crew off until C4.
- **D-74:** crew names generated from an international name list.
- **D-76:** check-ins monthly on long skips and daily near stars.

## Deviations (documented in the plan)

- **`crew_ask`** joined the intents, because consent needs an ask. **`crew_policy`, `crew_orders` and `crew_resume`** were added in C3 and C8.
- **The ledger is a cap, not the source** (C3). The crew keep the scenario's authored pool, because the lab's claims rest on it. The ship's spare capacity (`sim/data/crew_ship.ail`, partly assumptions) refuses a pack that asks for more. Flagged for Mark.
- **Fallback text.** content_library's starter text is a placeholder, so the game keeps an authored, in-world template line per reaction.
- **`hands_on`** is derived in the game. The crew-lab agent is adding a lab-verified `hands_on.json`, which will be synced instead.
- **Concerns.** Answering a crew concern needs the conversation issues in the view. It's deferred; the hold card handles the moment for now.

## Known issue: the auto-captain stalls on a crew concern (found after evaluation)

A probe after landing (crew_core 0.3.0 and 0.4.0, the synced scenario, keep 30) found that **crew_core's auto-captain never answers a concern**:
- A crew member who answers an offer with `concern` is re-asked and re-offered every decision day.
- crew_core refuses each try (`answer the existing concern before reconsideration` / `... before reoffering this assignment`), so that member is never offered work again.

| Setup | Result over 365 days |
|---|---|
| consent captain, critical_only, daily check-ins (**the game's default near stars**) | 1,805 of 1,837 auto acts are errors, and **no hold is raised**: the crew quietly stall |
| consent captain, critical_only, monthly check-ins | 53 errors from day 30 |
| orders captain, critical_only | a `refusal_under_orders` hold on day 0 |
| consent captain, hands_on | a `breakdown` hold on day 1 |

The game drops crew_core's auto log, so nothing shows these errors. The fix is in crew_core: the auto-captain should answer a concern under its orders or escalate it. It was reported to the crew-lab agent with a repro on 2026-10-14, who is preparing a crew_core patch release.

When that release lands, the game will pin it and add a gate: zero error acts over 365 days at daily and at monthly check-ins, for both captains.

The crew-lab agent also measured that **hands_on** would hold a careful captain about every 3 days (breakdown at stress 70 re-arms on every dip below it; critical_only's 85 never fires). A hysteresis fix is proposed in crew_core. hands_on stays opt-in until then.

## Not done or open

- **Vision score.** The `game-vision-designer` re-score has not been run; the hand score (+8) stands.
- **Art.** The four new cast members have provisional voices and stub portraits (D-7 sets pending).
- **The live AI path** for crew lines (relay → service → accepted text) is wired but was exercised only with the stub provider.
- **Visual review.** Mark reviews `renders/crew_console/` and the live Voyage capture (`make ship-ui-capture`).
