# Relative-size stops (D-54), Sol in the map, in-system destinations

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | The commit ritual is unchanged (the same hold); body plans are recreated at commit with zero elapsed time, as the guided tour already does. |
| The Game Doesn't Judge | +1 | Every stop says where it is ("At Alpha Centauri A 0.059 AU"); uncited stars say they still stop at 1,000 AU; a refused leg says why (collision, ring_crossing). |
| Time Has Emotional Weight | +1 | Going home is now a choice on the map (click Sol, or Return to Sol), and home is Earth, 30 degrees across, with the Solar System around the ship. |
| The Ship Is Home | 0 | No change to the ship. |
| Grounded Strangeness | +2 | A red dwarf is a 3.5 degree spark, a Sun-like star 11 degrees, Aldebaran 61 degrees: size reads as size. Every planet stop shows the body at a size that grows with its radius (Moon 16, Earth 30, Jupiter 84 degrees). |
| We Are Not Built For This | +1 | Giants loom; the stop never enters the star, the atmosphere or Saturn's rings. |

Net +5: aligned, go.

**Status:** Planned and implemented on `feat/free-nav-stops` 2026-10-08 (D-54 parts 1 and 3 complete; part 2's inferred radii and the synchronous-orbit line blocked on a package release, see Open questions).
**Release:** R1.
**Implements:** ledger D-54 (`design_docs/stapledon-mission.md`, Mark attended 2026-10-08): stops show relative size; Mark's 2026-10-08 requests "select Sol from the map view, we want to go back" and in-system destinations. Keeps D-47 (the guided tour's star stops) and D-46 (even tour legs). Design repo: `features/` navigation and destinations; no physics-spec section changes (no SR/GR visual changes; the stop rule is design geometry).
**Depends on:** `sim/navigation.ail` (the stop solver, `planStop`), `sim/data/acen.ail`, `sim/data/stars.ail` (cited radii), `ui/galaxy_map.gd` (`plan_home`, `HOME`, M4.4), PR #171 (HUD stop line, I at the destination).
**Estimated LOC:** about 600 (sim 140, sim tests 130, Godot 150, Godot tests 120, capture 70).

## Problem

- Free navigation stopped every star at 1,000 AU, so a red dwarf and a supergiant looked the same: a point. Tour planet stops were ad hoc (2 R, 10 R, 1.5 x ring).
- Sol could not be picked on the map (it is drawn at the origin, but `pick()` only picks catalogue rows), and the return trip (M4.4) arrived at Sol's origin, the Sun's centre.
- Once in a system there was no way to go to its planets or its other star except the guided tour.

## Goals and non-goals

Goals:
1. D-54 stops, as design rules in the sim (`sim/stops.ail`): stars theta = 2 atan(tan 5 deg sqrt(R/R_sun)); planets and moons theta = 2 atan(tan 15 deg sqrt(R/R_earth)); d = R / sin(theta/2); planets also above the safety minimum (1.1 R + bubble) and outside dense rings (tau >= 0.1, 1.1 x the outer edge).
2. Free navigation (`stop_rule` 54): a star with a cited finite body (alpha Cen A and B, Aldebaran, TRAPPIST-1) is planned by the stop solver at that body; Sol plans to Earth's D-54 stop.
3. Guided tour: Earth (start), Jupiter, Callisto and Saturn stops use D-54; the Sun keeps 3 R; the star stops keep D-47; D-46 timing still holds.
4. Map: Sol clickable; a Return to Sol button; an "In this system" list of plannable bodies within 2,000 AU, planned with the tour's body planner; body plans recreated at commit.

Non-goals (blocked, see Open questions): radii inferred from catalogue luminosity for uncited stars, finite bodies for every catalogue star, the synchronous-orbit altitude on the I card.

## Design

- `sim/stops.ail` (pure, strict-VM clean): `starStopKm`, `planetStopKm`, `starViewDeg`, `planetViewDeg`, `viewHalfRad`, `sphereViewKm`; `denseRingTau` 0.1, `ringMargin` 1.1. Composition of `std/math` only (a design rule, not physics maths, so no package release is needed for it).
- `sim/navigation.ail`: `defaultStopKm(id, R, bubble)` replaces `defaultStandoffKm` (stars: `isStarStop`; R_earth and R_sun are the sim's Earth and Sun radii); `denseRingKm(host)`; `finiteStopBody(catalogueId)` and `planFiniteStop(ctx, catalogueId, phi)`, which runs `planStop` up to the session cap and exempts only a body the ship starts inside (the "sol" scenario starts at the Sun's centre; AC15 still refuses that for every other plan).
- `sim/core.ail`: `Params.stopRule` (protocol `stop_rule`, 0 or 54, not echoed); `planIntent` sends a free-navigation star plan with a finite body to `planFiniteIntent` (target keeps its catalogue index and id; pos is the arrival point; `nav` is set, so it is a body plan on the wire with `hold`).
- `sim/solar_departure.ail`: tour standoffs from `defaultStopKm`.
- `ui/galaxy_map.gd`: `pick()` returns `SOL_PICK` for Sol; Return to Sol button; `system_bodies()`, `plan_body(id)` (cruise min(slider, 0.99c = the echo's default)), the list; `_replan_body_commit` recreates a body plan with zero elapsed time before the commit and reports a refusal instead of a stale commit.
- `demos/ship_geometry_demo.gd`: free navigation passes `stop_rule` 54; the HUD names the held body (`plan.hold.body`) and its distance.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| 1 | Star curve 0.1/1/40/700 R_sun = 3.2/10/58/133 deg; planet curve Moon 16, Earth 30, Neptune 55.6, Jupiter 83.8 deg; the stop subtends the curve and is outside any star | `cd sim && ailang test stops_test.ail` |
| 2 | Saturn's stop clears its dense rings (1.1 x 140,612 km); Jupiter's and Neptune's dusty rings do not move their stops; never below the safety minimum | same |
| 3 | Free navigation: alpha Cen A 11.05 deg (0.059 AU), Aldebaran 60.9 deg (0.415 AU), TRAPPIST-1 3.46 deg; stop_rule 0 keeps 1,000 AU; uncited Barnard's Star keeps 1,000 AU; home arrives at Earth's 24,643 km stop with target id Sol | same, and `make strict` (stopsVm, VM = interpreter byte for byte) |
| 4 | Tour: Earth start, Jupiter, Callisto, Saturn stops are D-54; the Sun 3 R; D-47 star stops and D-46 timing unchanged | `make solar-departure-test tour-pacing-test`, `cd sim && ailang test solar_departure_test.ail` |
| 5 | Real flow: Barnard's Star, alpha Cen A (11.05 deg), the map lists A and B, fly to B, click Sol / Return to Sol, arrive at Earth (24,643 km, HUD "At Earth"), the list shows the Solar System, fly to Saturn (clears rings), Jupiter (83.8 deg) | `make free-nav-stop-test` |
| 6 | Everything else still passes (replays, parity, M4.4 news) | `make test` |
| 7 | Renders at every stop, opened | `godot --path . --script tools/stops_capture.gd` then `renders/stops/small/*_700.png` |

## Risks and mitigations

- A free-navigation leg can be refused where the tour's is not (Jupiter to Callisto collides through Jupiter; Saturn from Jupiter crosses the rings at some epochs). The refusal is shown in the panel; a re-plan never sends a stale commit.
- Saturn at 1.1 x the F ring is 46 deg across, not the curve's 78 deg: the ring rule wins, as D-54 says.
- Planet stops inside Jupiter's gossamer rings (tau 1e-7) show a faint ring sheet (0.01 of white on the night side in `9_jupiter_sky.png`).

## Open questions for the user

1. **Package release needed (CLAUDE.md gate 3), not written in game code:** radii for uncited catalogue stars need (a) a bolometric correction BC_V(Teff) table (e.g. Pecaut & Mamajek), (b) luminosity from V, distance and BC (M_bol, L/L_sun), (c) R from L and Teff (Stefan-Boltzmann). A blackbody bolometric correction composed from existing functions (`illuminanceFromV`, `luminousEfficacy`, `stefanBoltzmannSI`) is within 10% for FGK stars but gives M dwarfs a third of their radius (Proxima 0.05 vs 0.154 R_sun), so it was not used. Proposed `sunholo/relativity` (photometry) exports: `bolometricCorrectionV(teffK)`, `luminositySunFromV(v, distancePc, bc)`, `radiusSunFromLuminosity(lSun, teffK)`.
2. **Synchronous orbit** on the I card needs `sunholo/celestial` `semiMajorAxisFromPeriod(gm, periodDays)` (or `synchronousOrbitKm(gm, siderealDays)`); not written.
3. The ring rule (dense = tau >= 0.1) keeps Mark's Jupiter 84 and Neptune 55 deg. Is that the intended reading of "outside rings"?

## Deliverables

`sim/stops.ail`, `sim/stops_test.ail`, the navigation/core/protocol/solar_departure changes, `ui/galaxy_map.gd`, `demos/ship_geometry_demo.gd`, `tests/test_free_nav_stop.gd` (`make free-nav-stop-test`), `tools/stops_capture.gd`, CHANGELOG.
