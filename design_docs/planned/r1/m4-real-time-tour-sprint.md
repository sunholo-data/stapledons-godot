# Sprint R1-M4-REAL-TIME-TOUR (A): real-time voyage, cruise interludes, Earth → Aldebaran

**Design doc:** [m4-real-time-tour.md](m4-real-time-tour.md) (D-39 to D-41). Sprint B (TRAPPIST-1) is planned separately in [m5-trappist1-sprint.md](m5-trappist1-sprint.md).
**Status:** Approved by Mark, attended 2026-10-06 ("yes lets go ahead with this demo expansion").
**Estimate:** about 650 LOC, 2 days at recent velocity. Recent comparable work, the M4 tour and exposure follow-ups, ran at 300–500 LOC per day including tests.
**Risk:** medium. The two unknowns are the γ-707 m_eff (RT0, measured first) and rendering at γ 707.

## Registry reuse

| Milestone | Package | Action | Reason |
|---|---|---|---|
| RT0–RT4 | `sunholo/relativity` (pinned) | depend | `rapidityOfBeta`, plans, drag check and Doppler already exist. No new formula. |

## Milestones

### RT0: drive measurement, about 20 LOC. Day 1, first hour

- Use real `new_game` calls to find the smallest `m_eff_kg` that passes `scenarioError` with 3M g at the γ-707 cap (cap 1−β = 5e-7).
- Record it, with the energy-ledger consequence, in the sprint JSON and the design doc.
- If no plausible value passes, stop and ask Mark: higher thrust or a slower final leg. Never lower ISM density.

**Acceptance:** design A1.

### RT1: itinerary (AILANG), about 90 LOC. Day 1 morning

- Test first in `sim/solar_departure_test.ail`: per-leg β (0.99, 0.999, 0.9999 and 0.999999), the two new star legs by exact catalogue ID, and refusal-free plans under `GUIDED_DRIVE`.
- Add the constants and legs to `sim/solar_departure.ail`.
- Run `make strict parity`; re-record replays with the reason if their bytes change.

**Acceptance:** design A2.

### RT2: `GUIDED_DRIVE`, about 40 LOC. Day 1 morning, in parallel with RT1

- Make it the single definition and switch all five callers.
- Add a guard so that no `solar_departure` caller keeps `boost_g` at 1.

**Acceptance:** design A3, the full voyage to Aldebaran with cumulative Earth time within 1%.

### RT3: real-time pacing and the cruise interlude, about 370 LOC. Day 1 afternoon to day 2 morning

- Tests first in `tests/test_tour_pacing.gd`:
  - `dtau` is 1/20 s per tick;
  - the 600 s rule and the 10 s hold;
  - the host steps exactly the time `advance()` returns, checked with a fake interlude that consumes time in three uneven chunks;
  - the clock lands on the braking boundary within 1e-12;
  - map pacing is byte-identical, against 200 recorded `dtau` values.
- Real-time guided mode in `ui/journey_pacing.gd`.
- The `ui/cruise_interlude.gd` interface (`begin`, `advance`, `done`) and its host loop in `demos/solar_departure.gd`.
- `ui/interlude_card.gd`: the goal-5 contents and the three tier texts, chosen from cumulative Earth time, with animated clocks and Continue or a 6 s timeout. A mutation test checks that every number follows its field.
- Update `status_text()`.

**Acceptance:** design A4, A5 and A6.

### RT4: evidence, about 130 LOC. Day 2

- `tools/real_time_tour_capture.gd`: the Solar System frames, every interstellar boost peak (forward and side), every card and every braking arrival.
- Open them all. Check that the sky stays finite at γ 707, and add a `make golden` case if the γ-707 forward glow or LUT edge isn't covered.

**Acceptance:** design A7.

### Close

- `make test` locally and in CI (A8).
- Changelog entry.
- Evaluation by the sprint-evaluator skill, using a different model from the executor.
- A dev build for laptop review.

## Day plan

| When | Work |
|---|---|
| Day 1 AM | RT0, then RT1 and RT2; strict and parity; replays |
| Day 1 PM | RT3 tests and pacing |
| Day 2 AM | RT3 interface and card; live and export smoke |
| Day 2 PM | RT4 renders and review; `make test`; PR; evaluation; dev build |
