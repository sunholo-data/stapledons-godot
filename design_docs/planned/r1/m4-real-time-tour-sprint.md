# Sprint R1-M4-REAL-TIME-TOUR: real-time guided tour with a labelled interstellar cut

**Design doc:** [m4-real-time-tour.md](m4-real-time-tour.md) (D-39, D-40).
**Status:** Proposed 2026-10-06. Awaiting Mark's approval; no execution before it.
**Estimate:** about 450 LOC, 1.5 days at recent velocity. Recent comparable work was the M4 tour and exposure follow-ups: 300–500 LOC per day, including tests.
**Risk:** low to medium. There are no core or package changes; the main risks are replay bytes and relativistic planet discs at β 0.99.

## Registry reuse

| Milestone | Package | Action | Reason |
|---|---|---|---|
| RT1–RT4 | `sunholo/relativity` (pinned) | depend | `rapidityOfBeta`, plans and Doppler are already in the package. No new formula. |

## Milestones

### RT1: itinerary speeds (AILANG), about 60 LOC. Day 1 morning

- Write the test first in `sim/solar_departure_test.ail`. It checks that the legs' `cruisePhi` equals `rapidityOfBeta(0.99)` for the Solar System and α Cen A legs and `rapidityOfBeta(0.999)` for the star leg, and that all legs plan without refusal under `boostG 3e6`, `capOneMinusBeta 0.001` and `mEffKg 10`.
- Add `solCruiseBeta()` and `starCruiseBeta()` to `sim/solar_departure.ail`, citing D-39/D-40.
- Run `make strict parity`, then the sim tests. If replay bytes change, re-record on arm64 and x86_64 and give the reason in the commit.

**Acceptance:** design AC1.

### RT2: one drive definition (host), about 40 LOC. Day 1 morning, in parallel with RT1

- Add `SolarDeparture.GUIDED_DRIVE` and switch all five callers to it.
- Add a guard test that `git grep '"boost_g":1'` finds no solar_departure caller.

**Acceptance:** design AC2 (`make solar-departure-test`), which covers the full tour, no fallback, peak β per leg and unchanged stand-offs.

### RT3: real-time pacing, cut and card, about 250 LOC. Day 1 afternoon to day 2 morning

- Write the tests first in `tests/test_tour_pacing.gd`:
  - guided `dtau` is exactly 1/20 s per tick across boost, short cruise and braking;
  - the cut happens only when the cruise is over 600 s, after a 10 s hold;
  - after the cut, tau lands on the braking boundary within 1e-12;
  - ordinary map pacing is byte-identical (a golden list of 200 `dtau` values recorded before the change).
- In `ui/journey_pacing.gd`: real-time guided mode, a `cut_state` (`none / hold / card`), and the three default constants.
- Add `ui/cut_card.gd`, an overlay fed only from plan, world and `cq` fields. It shows speed (β, γ), the distance left, the ship and Earth time the cut skips, the light delay from home, and live clocks, with a Continue button and a 6 s timeout. Its test checks that each value is read from a field, by mutating the fields and checking the card follows.
- In `demos/solar_departure.gd`: pause stepping during the card, and update `status_text()`.

**Acceptance:** design AC3 and AC4 (`make tour-pacing-test`, `make ship-demo-live-test`, `make export-smoke`).

### RT4: evidence renders, about 100 LOC. Day 2

- Write `tools/real_time_tour_capture.gd` to take the frames listed in the design doc's RT4 section, and open every frame.
- If the Jupiter discs at D ≈ 14 lack a golden case, add one to `make golden` (gate 2).

**Acceptance:** design AC5.

### Close

- `make test` locally and in CI (AC6).
- Add a changelog entry.
- Evaluate with the sprint-evaluator skill, using a different model from the executor.
- Publish a dev build for laptop review.

## Day plan

| When | Work |
|---|---|
| Day 1 AM | RT1 and RT2, strict/parity, replays |
| Day 1 PM | RT3 tests, then pacing |
| Day 2 AM | RT3 card UI, live and export smoke |
| Day 2 PM | RT4 renders and review, `make test`, PR, evaluation, dev build |

## Open questions (defaults in the design doc)

1. Cut threshold: 600 s.
2. Card: 6 s or Continue.
3. Hold before the cut: 10 s.
