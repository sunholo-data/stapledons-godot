# Even legs, a gentle final approach, and skip-to-next-stage

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | Same commitments; a skip is labelled and only jumps along the committed leg. |
| The Game Doesn't Judge | +1 | The HUD shows each leg's actual thrust and speed. |
| Time Has Emotional Weight | +1 | Every in-system leg has the same rhythm: you feel the speed rise, hold and fall. |
| The Ship Is Home | +1 | Arrivals become an event watched from the bridge, not a jump cut. |
| Grounded Strangeness | +2 | Faster legs (up to γ ≈ 37 in-system) make SR obvious; the approach is exact constant-acceleration physics. |
| We Are Not Built For This | 0 | No change. |

Net +5: aligned.

**Measured (sim, 2026-10-06):** every in-system leg boosts 30 s, cruises 58–60 s, brakes 15–27 s and approaches for exactly 25 s, about 2¼ minutes each (Sun → Jupiter was 6½). Jupiter's approach starts with it about 4° across.

**Status:** Approved by Mark, attended 2026-10-06 ("All three"), after reviewing dev.17 ("its taking too long to get to jupiter"; "we arrived at jupiter very suddenly"; "cruise at a speed that takes about 1 min to get to each, but we should have the same approximate accel/braking approach for each"; "can we add skip to next stage button").
**Release:** R1, a follow-up to the real-time voyage (`m4-real-time-tour.md`, Sprint A).
**Depends on:** `sunholo/relativity` 0.8.0 `journey` (the closed forms reused); the body-stop navigation (`sim/navigation.ail`); the guided tour (`demos/solar_departure.gd`).
**Estimated scope:** about 900 LOC: package 250, sim 350, host 150, tests and evidence 150.

## Problem (dev.17, measured)

Leg wall times at one drive (3,000,000 g for every leg): Earth → Sun 1.8 min, Sun → Jupiter **6.5 min**, Jupiter → Callisto 0.3 min, Callisto → Saturn 5.7 min. Long in-system legs drag, and boost/brake lengths vary from 8 s to 43 s.

Arrival is abrupt. Under constant braking the remaining distance falls with the square of the time left, so Jupiter grows from about 3° to 60° in the last ~8 s. Light speed sets a floor: even at c, closing from 3° to the stop takes about 10 s.

## Design

### E1. Even legs (sim)

An optional `timing` on a body plan: `{boost_s: 30, cruise_s: 60, approach_s: 25, approach_deg: 4}`.

From the straight distance at planning time, the sim solves the leg's proper acceleration a = c·φ/boost_s and cruise rapidity φ so that the boost takes boost_s and the cruise takes about cruise_s. The equation is d = 2·boost_s·c·(cosh φ − 1)/φ + cruise_s·c·sinh φ, solved by bisection over the package's closed forms. The intercept then uses that thrust and speed, so the cruise is approximately 60 s for moving targets.

Requests with a timing may exceed navigation's in-system cap of 0.99c, up to the session cap (cruisePhiMax). Ordinary body plans keep 0.99c.

The brake-vs-drag check runs per leg, at that leg's thrust and peak rapidity, refusing with `m_eff_too_small`. ISM density is never lowered.

Solved values: Earth → Sun 0.987c at 2.6 M g; Sun → Jupiter 0.99943c (γ 30) at 4.2 M g; Jupiter → Callisto 0.07c at 0.07 M g; Callisto → Saturn 0.99963c (γ 37) at 4.4 M g.

### E2. A gentle final approach (package first)

New profile `planBurnCoastBrakeApproach(distance, a, phiCruise, aApproach, phiApproach)` in `sunholo/relativity/journey`:
1. accelerate at a to φ_cruise;
2. coast;
3. brake at a to φ_approach;
4. brake at a_approach to rest.

`TripPlan` gains `aApproach`, `phiApproach`, `tauApproach` and `dApproach` (zero for the existing profiles, which are unchanged bit for bit). `phaseAt` is unchanged, so existing matches on `TripPhase` stay exhaustive: the approach reports as `Decelerating`, and a new `inApproach(plan, tau)` marks it (the sim maps that to phase index 4). `motionAt` is closed-form in every phase, measured from each phase's own start.

The sim chooses the approach to start where the target is `approach_deg` (4°) across, and to last `approach_s` (25 s):
- x_a = R/sin(2°) − stand-off, at least the stand-off;
- φ_a solves x_a = approach_s·c·(cosh φ − 1)/φ, so a_approach = φ_a·c/approach_s;
- if φ_a ≥ φ_cruise (the Sun, already 4° across before the brake could begin), the approach still lasts approach_s, starting at half the cruise rapidity. For the Sun that's about 0.85c, at roughly 11° across.

Jupiter's approach then begins at 0.46c, about 1.9 million km out, and Jupiter grows over ~25 s instead of ~8. A new ship phase `approaching` appears in the protocol.

### E3. Skip to next stage (host)

A labelled button and key that jumps exactly to the next phase boundary:
- accelerating → cruise;
- cruise → braking (an interlude still runs for long cruises);
- braking or approach → arrival;
- at rest → the next leg (the existing Next stop).

Like the cruise card, it steps the sim by the exact ship time to the boundary, so clocks and consequences stay the sim's.

### E4. HUD

"FINAL APPROACH" for the new phase. The leg's actual thrust (from the plan) replaces the fixed "3,000,000 g" wording.

## Non-goals

- Ordinary map journeys: no timing, no approach; the map-pacing golden stays byte-identical.
- Interstellar legs keep D-40 (boost, hold, interlude card, braking).
- No time compression except an explicit, labelled skip.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| E1 | Package: the new profile's tests (continuity at every boundary, energy, the limits a_approach → a and φ_approach → 0 reproduce planBurnCoastBurn bit for bit, monotonic x(τ)); `ailang pkg quality` has no gates; published as 0.9.0; sim pins it | package `make test` / `ailang test`; `make deps` |
| E2 | Sim: timing solves to boost 30 s ± 1 and cruise 60 s ± 10 on the four in-system legs; refused when drag beats thrust; ordinary body plans unchanged (0.99c cap) | sim tests; `make strict parity` |
| E3 | The voyage runs Earth → Aldebaran with the approach phase on body legs; the approach lasts 25 s ± 2 and starts with the target 4° ± 0.5 across (rendered angular size) | `make solar-departure-test` |
| E4 | Skip lands on each boundary, overshooting by at most 1e-9 of the step (the bridge carries ~12-digit decimals; the sim splits the step exactly at the boundary), and is unavailable when nothing is committed; map pacing is byte-identical | `make tour-pacing-test` |
| E5 | Renders: Jupiter's approach sequence (several frames) and the HUD, opened | capture tool |
| E6 | Gate 1 | `make test` + CI |
