# Real-time voyage: SR you can watch, cruise interludes, and three stars outward

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | Same commitment rules; the legs are guided. |
| The Game Doesn't Judge | +1 | Cards state true speeds, γ and both clocks. Measured and assumed data stay labelled (TRAPPIST-1 appearance). |
| Time Has Emotional Weight | +2 | Ship and Earth clocks part in real time. Earth time grows 4 → 46 → 120 years while you live about 11 months. |
| The Ship Is Home | +2 | Cruises become interludes lived inside the ship; this sprint builds the interface that the crew gameplay will fill. |
| Grounded Strangeness | +2 | SR seen at the speeds that cause it; a real foreign star with seven measured exoplanets. |
| We Are Not Built For This | +1 | The cards name the loss ("everyone you knew is gone"); the interface is where the crew will carry it. |

Net +8: aligned.

**Status:** Approved 2026-10-06 (Mark, attended), from Mark's attended rulings D-39 and D-40 and the rulings recorded with this doc. Two sprints, A and B.
**Release:** R1. It follows the Solar System departure tour (`m4-ship-lighting-and-solar-departure.md`) and replaces that tour's guided pacing.
**Implements:**
- [journey system](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md): boost → cruise → brake, and "crew ages, forms relationships … during the journey";
- [crew assignment](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/crew-assignment-system.md), the future resident of the interface;
- the [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) aberration and Doppler paths, with no new formulas.

**Depends on:**
- the AILANG journey core;
- `sim/solar_departure.ail`;
- `ui/journey_pacing.gd`;
- the M5.3 relativistic planet path;
- the consequence clocks (M4.1);
- for Sprint B, `sunholo/celestial` orbits and the α Cen finite-star pattern.

**Estimated scope:** Sprint A about 650 LOC; Sprint B about 850 LOC.

## Problem

The guided tour flies at 1 g with a 0.002c cap and compresses time about 9,000×. That has three problems:

- SR is invisible at that speed: aberration ≤ 0.11° and Doppler under 1%.
- The compression hides the physics.
- "The Solar System is too small for SR" is only true at the artificial 1 g.

The tour also ends at α Cen, which undersells how far the stars are. Distance and lost time are the game's subject, and the demo should make them felt.

## Goals

1. **Real time.** The guided voyage advances the simulation by one ship second per wall second, through every boost, every braking and every short cruise.
2. **One drive** for the whole voyage, at 3,000,000 g, with a speed cap low enough for the fastest leg. RT0 measures the effective mass needed (see Design).
3. **The itinerary.** Earth time is cumulative since departure; the interstellar figures come from catalogue positions at 3M g.

   | Leg | Distance | Cruise | Boost/brake each | Ship | Earth (cumulative) |
   |---|---|---|---|---|---|
   | Earth → Sun → Jupiter → Callisto → Saturn | 1–9 AU | 0.99c (γ 7.1) | 27 s | 3–6 min per leg | minutes per leg |
   | Saturn → α Cen (system, then 1 AU from A) | 4.3 ly | 0.999c (γ 22.4) | 39 s | 71 d | **4.3 yr** |
   | α Cen → TRAPPIST-1 (`Gaia DR3 2635476908753563008`) | 41.8 ly | 0.9999c (γ 71) | 50 s | 216 d | **46 yr** |
   | TRAPPIST-1 → Aldebaran (`CNS5:1142`) | 74.4 ly | 0.999999c (γ 707) | 74 s | 38 d | **120 yr** |

4. **Cruise interludes.** A cruise longer than `CUT_THRESHOLD_S = 600` ship seconds goes through an interlude. (Solar System cruises are shorter, so they play in real time.) The sequence:
   - a real-time boost;
   - `CRUISE_HOLD_S = 10` s of real-time cruise, so the player sees where the sky ends up;
   - the interlude;
   - real-time braking.

   The interlude is a **seam for in-ship gameplay** (Mark, 2026-10-06: in the real game the cut is "moving to the in-ship gameplay, e.g. talking and relationships within as they deal with the long journeys"). This milestone ships one implementation, the card.
5. **The card communicates scale, not loading.** Its values come only from simulation fields:
   - speed (β, γ) and the distance left;
   - the ship and Earth time this cruise takes;
   - the **total Earth time since departure**;
   - the age of news from home.

   It closes with a line that names what that means. The texts below are drafts for Mark to approve. The tier is chosen from the simulation's cumulative Earth time, never from the leg name:
   - **under 10 years:** "Four years have passed at home. The news you left with is history."
   - **10–80 years:** "Forty-six years at home. Your parents' generation is gone; the friends you left are old."
   - **80 years or more:** "A hundred and twenty years. Everyone you knew is gone. No one alive on Earth was born when you left."
6. **TRAPPIST-1 as a real stop (Sprint B).** It has seven transiting planets with measured radii, masses and orbits (Agol et al. 2021, PSJ 2, 1), around a finite 2,566 K star. Appearance isn't measured: the planets render untextured, with a stated assumed albedo, and are labelled "appearance assumed" wherever they're inspected.
7. **Living data** (Mark, 2026-10-06: "as we learn more about real planets in real life we can add it to this game"). Every exoplanet property has a status, measured or assumed, plus a citation or stated default. A new measurement, such as a JWST albedo, an atmosphere or a newly confirmed planet, enters the game as a data refresh: re-pin the archive snapshot and update the cited row. The label shown in game ("measured" or "assumed") is derived from that status, never written as text. Adding another real system later reuses the TB1–TB4 pipeline unchanged.

## Non-goals

- No change to `sim/core.ail`'s rules, the package, ISM density or the drag check.
- Ordinary map journeys keep their pacing.
- No crew, dialogue or relationship mechanics in this work; the interface leaves room for them.
- No finite Aldebaran disc: it is arrived at the catalogue stand-off as a point. A close approach to a 44 R☉ giant is separate work.
- No textures or invented surface detail for exoplanets.
- No per-leg drive override.

## Design (Sprint A)

### RT0: drive measurement

Drag scales as γ² and grows with the bubble's area. Using real `new_game` and `plan` calls, find the smallest `m_eff_kg` (from 10 upward, by decades, then refined) for which 3M g holds against drag at the γ-707 cap. Record it with its consequence: the energy ledger scales with m_eff, and surfacing that cost is welcome.

If no plausible m_eff passes, raise the drive's thrust for the whole voyage. Never lower ISM density. The result fills in `GUIDED_DRIVE`.

### RT1: itinerary (AILANG)

Changes in `sim/solar_departure.ail`:
- Add the exported constants `solCruiseBeta() = 0.99`, `acenCruiseBeta() = 0.999`, `trappistCruiseBeta() = 0.9999` and `aldebaranCruiseBeta() = 0.999999`, citing D-39 to D-41.
- Add the legs `Gaia DR3 2635476908753563008` and `CNS5:1142`, as star kind at the catalogue stand-off.

Update `sim/solar_departure_test.ail`. Run `make strict` and `make parity`, and re-record any replays whose bytes change, with the reason.

### RT2: one drive definition (host)

Add `SolarDeparture.GUIDED_DRIVE` and switch all five callers to it, removing the 1 g literals.

### RT3: real-time pacing and the interface

- **Pacing.** In `ui/journey_pacing.gd`, guided mode returns `dtau = 1/tick_hz` seconds every tick, clamped at phase boundaries. The 30/20/90 s budgets, the boost easing and the quadratic braking go.
- **The interface.** `ui/cruise_interlude.gd` defines:
  - `begin(facts: Dictionary)`, where `facts` is built from plan, world and `cq` fields only;
  - `advance(max_dtau_years) -> float`, which says how much ship time to consume this step (any amount up to the remaining cruise);
  - `done() -> bool`.

  The host steps the simulation by exactly what `advance` returns. When `done()` is true, it asserts that the clock sits on the braking boundary, then resumes real time. Consequences, news ageing and clocks therefore stay correct, however the interlude spends the time.
- **The demo implementation.** `ui/interlude_card.gd` consumes the whole cruise in one step after `CARD_S = 6` s or a Continue press. It shows the goal-5 contents, with both clocks animating to their new values.

Future crew gameplay spends the same time in chunks of conversations, events and days. The time each activity consumes is its own design.

### RT4: evidence

`tools/real_time_tour_capture.gd` runs one real session and saves:
- Earth → Jupiter boost at β ≈ 0.5 and 0.99;
- Jupiter at cruise, approaching and mid-braking;
- each interstellar boost at its peak β, forward and side (including γ 707 with the visible CMB glow ahead);
- each card;
- each braking arrival.

The renders are opened and looked at before merge.

## Design (Sprint B: TRAPPIST-1 system)

- **TB1. Data.** Use the starmap-manager skill to fetch the NASA Exoplanet Archive rows for TRAPPIST-1 and pin them by sha256 in `data/planets/EXOPLANETS.SHA256`, alongside the α Cen rows. Re-verify against Agol et al. 2021:
  - the star: R = 0.1192 R☉, T_eff = 2,566 K, M = 0.0898 M☉;
  - the planets: radii, masses, periods, transit epochs and inclinations.
- **TB2. AILANG data module.** `sim/data/trappist1.ail` holds every value with its citation. Positions come from `sunholo/celestial` Kepler orbits phased from the transit epochs, with light-time as for α Cen. Transit-timing drift over the decades is stated in the module.
- **TB3. Body feed.** Add the TRAPPIST-1 bodies to the protocol system section within 0.1 ly of the star, as `alphaBodies` does now:
  - exact catalogue suppression of the Gaia point;
  - a finite limb-darkened star (u from a cited M-dwarf value, or 0 with a note);
  - no candidate or unconfirmed planets.
- **TB4. Appearance.** Each property is a `{value, status, source}` row (goal 7). An untextured Minnaert disc with an assumed geometric albedo, low for b and c following JWST (Greene 2023, Zieba 2023), and a stated default for the rest. The star-info card shows "radius measured · appearance assumed".
- **TB5. Tour stop.** After the catalogue stand-off, add a body leg into the inner system at a vantage where several planets show as discs. That needs package intercept and collision checks against all seven planets and the star.
- **TB6. Evidence.** Golden and physics checks for the finite M-dwarf disc and the planets' reflected light (gate 2), plus inspected renders.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| A1 | The measured m_eff passes `scenarioError` at the γ-707 cap with 3M g, and the value is recorded | `make solar-departure-test` (asserts `GUIDED_DRIVE` starts) |
| A2 | Itinerary β per leg as in goal 3; strict VM and parity hold | `make strict parity`; sim tests in `make test` |
| A3 | A full voyage on `GUIDED_DRIVE`, Earth → Aldebaran: no refusal or fallback, peak β per leg, stand-offs unchanged, cumulative Earth time within 1% of goal 3 | `make solar-departure-test` |
| A4 | Pacing: `dtau` is 1/20 s per tick outside interludes; an interlude happens only when the cruise is over 600 s, after a 10 s hold; the host steps exactly the time the interface returns; the clock lands on the braking boundary within 1e-12 of the leg; map pacing is byte-identical | `make tour-pacing-test` |
| A5 | The card follows the fields (mutation test); the tier text is chosen from cumulative Earth time | `make tour-pacing-test` |
| A6 | Live and export smoke through to Aldebaran | `make ship-demo-live-test`, `make export-smoke` |
| A7 | RT4 renders exist and were inspected; the sky and planets stay finite at γ 707 (no NaN, no black) | `tools/real_time_tour_capture.gd` (GPU), `make golden` |
| A8 | Gate 1 | `make test` locally and in CI |
| B1 | The snapshot is pinned and every value carries its citation | `make planet-verify`; `sim/data/trappist1_test.ail` |
| B2 | Bodies are fed near the star, the catalogue point is suppressed, and there are no candidates | `make solar-departure-test` |
| B3 | The stop clears all seven planets and the star | sim tests |
| B4 | M-dwarf disc and reflected-light goldens; the measured/assumed label is derived from each row's status (a test flips a status and checks the label follows) | `make golden`; `make physics` |
| B5 | TB6 renders inspected | capture tool |

## Sprints

| Sprint | Milestones | LOC | Days |
|---|---|---|---|
| A: `R1-M4-REAL-TIME-TOUR` | RT0 (20), RT1 (90), RT2 (40), RT3 (370), RT4 (130) | 650 | 2 |
| B: `R1-M5-TRAPPIST-1` | TB1 (60), TB2 (220), TB3 (160), TB4 (120), TB5 (170), TB6 (120) | 850 | 3 |

Sprint A ships without B. Until B lands, the voyage arrives at TRAPPIST-1's catalogue stand-off as a point.

## Risks

- **m_eff at γ 707 may need to be large.** Mitigation: RT0 runs first; the cost is shown, not hidden; ISM is never lowered.
- **Replay bytes change.** Mitigation: re-record on arm64 and x86_64 with the reason.
- **Rendering at γ 707:** the CMB was verified to γ 707, but the forward glow and starfield LUTs need checking at the same time. Mitigation: A7 and the CLAUDE.md finite-LUT rule.
- **TRAPPIST-1 orbit phases drift over decades of extrapolation.** Mitigation: state the uncertainty in TB2; clearance margins well above it.
- **Exoplanet data changes.** Mitigation: the pinned snapshot, and statuses never hard-coded.

## Open questions (defaults chosen; Mark may override)

1. Cut threshold 600 s; hold 10 s; card 6 s or Continue. Default: yes.
2. Card wording for the three tiers. Default: the drafts in goal 5, for Mark to edit.
3. TRAPPIST-1 vantage: the default is between the e and f orbits, with several planets as discs.
4. Aldebaran arrival is a point at the stand-off. Default: yes; a finite giant comes later.

## Deliverables

- Sprint A and Sprint B code;
- the sprint JSONs;
- changelog entries;
- dev builds for laptop review after each sprint.
