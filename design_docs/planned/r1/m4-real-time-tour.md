# Real-time guided tour: SR you can watch, a labelled cut between the stars

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | Same legs, same commitment rules; only drive parameters and the presentation clock change. |
| The Game Doesn't Judge | +1 | The cut card states the true speed, γ and both clocks; nothing is hidden by a fast-forward. |
| Time Has Emotional Weight | +2 | Ship and Earth clocks visibly part in real time (Earth→Jupiter: 6 ship min, 39 Earth min); the card makes the 4.3 Earth years tangible. |
| The Ship Is Home | +1 | You live through each boost and braking from the ship, at one second per second. |
| Grounded Strangeness | +2 | SR effects are seen at the speeds that make them, not hidden by 1 g and time compression. |
| We Are Not Built For This | 0 | No crew mechanic. The 3,000,000 g drive relies on the existing inertia-damped fiction (m_eff). |

Net +6: aligned.

**Status:** Planned 2026-10-06, from Mark's attended rulings D-39 and D-40.
**Release:** R1. A follow-up to the Solar System departure tour (`m4-ship-lighting-and-solar-departure.md`), whose guided pacing it supersedes.
**Priority:** next demo improvement after dev.16 (the Auto-view Sun fix).
**Implements:** [journey system](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md); [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) aberration and Doppler (existing package paths, no new formulas).
**Depends on:** the existing AILANG journey core, `sim/solar_departure.ail`, `ui/journey_pacing.gd` and the M5.3 relativistic planet path.
**Estimated scope:** about 450 lines: 40 AILANG, 180 GDScript, 230 tests and tools.

## Problem

The guided tour flies at 1 g and caps cruise at 0.002c, then compresses time about 9,000× so a 15-day Earth→Jupiter leg plays in about 2½ minutes. Three things are wrong with that:

- SR effects at 0.002c are invisible: aberration ≤ 0.11° and Doppler under 1%.
- The compression hides the physics the game is about.
- Telling players "the Solar System is too small for SR" is false. That's only true at 1 g, and 1 g is an artificial limit (Mark, D-39).

## Goals

1. **Real time.** The guided tour advances the sim by one ship second per wall second, through every boost and braking phase and every Solar System cruise.
2. **One drive for the whole tour:** `boost_g = 3,000,000`, `cap_one_minus_beta = 0.001`, `m_eff_kg = 10`. Measured with SimBridge plans on v0.52.0:

   | Leg | Cruise | Boost / brake (each) | Ship time | Earth time |
   |---|---|---|---|---|
   | Earth → Jupiter (sample) | 0.99c, γ 7.1 | 27 s | 6.1 min | 39.1 min |
   | Saturn → α Cen system | 0.999c, γ 22.4 | 38.7 s | 70.6 days | 4.33 yr |

   It passes the existing brake-vs-ISM-drag scenario check, which stays enforced.
3. **A labelled cut for long cruises.** A cruise longer than `CUT_THRESHOLD_S = 600` ship seconds is cut, which means the interstellar leg and the 1,000 AU → 1 AU α Cen A hop (about 20 ship hours). The sequence is:
   - A real-time boost.
   - `CRUISE_HOLD_S = 10` s of real-time cruise, so the player sees where the sky ends up.
   - A card for `CARD_S = 6` s, with the sim paused and the cruise sky visible behind it.
   - The sim advanced exactly to the braking boundary.
   - Real-time braking.
4. **Card contents,** all taken from AILANG plan and clock fields and never computed in the host: speed (β and γ), the distance left, the ship time and Earth time the cut skips, and "cutting to arrival braking".
5. **Make the distance felt** (Mark, 2026-10-06: "that's what we want to communicate with this game, how non-trivial interstellar travel is"). The card is a moment of scale, not a loading screen. It says what the skipped time means: for example, "you live 70 days; 4.3 years pass at home", and "light from Earth, and any message, is 4.4 years old when it reaches you". The Earth and ship clocks show on screen as they jump. The light-delay line uses the existing sim field (`cq.news_age_years` or equivalent), not a host calculation.

## Non-goals

- No change to `sim/core.ail`, the package, ISM density or the drag check.
- Ordinary galaxy-map journeys keep their existing pacing.
- No per-leg drive override (not needed once D-40 dropped the 1-minute interstellar leg).
- No new glare model.

## Design

### RT1: itinerary speeds (AILANG)

In `sim/solar_departure.ail`, the Solar System body legs and the α Cen A hop use `rapidityOfBeta(solCruiseBeta())` with `solCruiseBeta() = 0.99`. The interstellar leg uses `rapidityOfBeta(starCruiseBeta())` with `starCruiseBeta() = 0.999`.

Both are exported constants with a provenance comment citing D-39/D-40. Update `sim/solar_departure_test.ail`. Run `make strict` and `make parity`, and re-record any replay whose bytes change, with the reason in its commit.

### RT2: one drive definition (host)

`demos/solar_departure.gd` exports `GUIDED_DRIVE := {"boost_g": 3e6, "m_eff_kg": 10.0, "cap_one_minus_beta": 0.001}`. These all switch to it:

- `ship_geometry_demo.gd`
- `tests/test_solar_departure.gd`
- `tests/test_moon_lifecycle.gd`
- `tools/exposure_*_view.gd` and `tools/exposure_*_recovery.gd`

That removes the five copies of the 1 g literal.

### RT3: the real-time clock and the cut (host)

In `ui/journey_pacing.gd`, guided mode returns `dtau = 1/tick_hz` seconds (in years) every tick, clamped to the next phase boundary using the existing ulp nudge. It drops the 30/20/90-second budgets, the boost easing and the quadratic braking. Real time makes all three unnecessary.

A new `cut_state` cycles through `none → hold → card → none`. When the cruise is longer than the threshold:

- Once `CRUISE_HOLD_S` of cruise has elapsed, pacing enters `card` and the host stops stepping the sim.
- After `CARD_S` seconds, or when the player presses Continue, pacing returns the exact `dtau` to the braking boundary (`total - burn - elapsed`).

The card is a `ui/` overlay fed only from the plan and world fields (`cruise_beta`, `cruise_gamma`, `cruise_one_minus_beta`, `ship_years`, `earth_years`, `clock.tau`, `clock.year`). `SolarDeparture.status_text()` drops the old compression wording.

### RT4: evidence

`tools/real_time_tour_capture.gd` drives one real session and saves:

- the Earth → Jupiter boost at β ≈ 0.5 and 0.99;
- Jupiter at cruise, approaching, and mid-braking;
- the interstellar boost at β 0.9, 0.99 and 0.999, forward and side;
- the card frame;
- braking into α Cen.

The renders are opened and looked at before merge.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | Itinerary cruise β: 0.99 for Solar System and α Cen A legs, 0.999 for the interstellar leg; strict VM and VM/interpreter parity hold | `make strict parity` and the sim tests in `make test` |
| AC2 | A full tour on `GUIDED_DRIVE` gives no refusals and no fallback, peak cruise β matches AC1, and stand-offs are unchanged (1 AU from moving A, companion clearance, ring clearance) | `make solar-departure-test` |
| AC3 | Guided `dtau` is exactly 1/20 s per tick in boost, cruise ≤ 600 s and braking. A cut happens only for cruise > 600 s, after 10 s of hold; tau after the cut equals the braking boundary within 1e-12 of the leg; the card values equal the plan and clock fields; ordinary map pacing is byte-identical to today | `make tour-pacing-test` |
| AC4 | The live demo smoke runs the new drive, including the card, through to arrival | `make ship-demo-live-test`, `make export-smoke` |
| AC5 | RT4 renders exist and have been inspected; the relativistic planet path stays finite at β 0.99 near Jupiter (no NaN, no black discs) | `godot --path . --script tools/real_time_tour_capture.gd` (GPU) |
| AC6 | Gate 1 | `make test` locally and in CI |

## Sub-milestones

| ID | Scope | LOC | Order |
|---|---|---|---|
| RT1 | AILANG itinerary speeds and tests | 60 | 1 |
| RT2 | `GUIDED_DRIVE`, callers switched | 40 | 1 (parallel) |
| RT3 | Real-time pacing, cut state, card UI, pacing tests | 250 | 2 |
| RT4 | Capture tool, renders, review | 100 | 3 |

## Risks

- **Replays change bytes** because the leg metadata is encoded in the world. Mitigation: re-record with the reason, and compare the arm64 and x86_64 replays.
- **The relativistic planet path at β 0.99 on approach is less exercised than the sky.** Mitigation: the AC5 renders; if a golden case is missing for discs at D ≈ 14, add it to `make golden` (gate 2).
- **A real-time 20 Hz host tick crossing short phases** (the 27 s boosts are fine). Mitigation: the existing boundary clamp.

## Open questions (defaults chosen; Mark may override)

1. The cut threshold is 600 ship seconds. Default: yes.
2. The card stays for 6 s or until Continue. Default: both.
3. The cruise hold before the cut is 10 s. Default: yes.

## Deliverables

- The RT1–RT4 code.
- The sprint JSON.
- A changelog entry.
- A dev build for laptop review.
