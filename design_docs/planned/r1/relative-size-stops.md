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
| 7 | Renders at every stop (REALISTIC, sky only, AUTO), opened | `godot --path . --script tools/stops_capture.gd` then `renders/stops/small/*_700.png` |

## Risks and mitigations

- A free-navigation leg can be refused where the tour's is not (Jupiter to Callisto collides through Jupiter; Saturn from Jupiter crosses the rings at some epochs). The refusal is shown in the panel; a re-plan never sends a stale commit.
- Saturn at 1.1 x the F ring is 46 deg across, not the curve's 78 deg: the ring rule wins, as D-54 says.
- Jupiter's stop lies inside its gossamer rings (tau 1e-7): in the REALISTIC view a faint ring sheet (0.01 of white over the night side) gives a second straight edge in `9_jupiter_sky.png`; the AUTO view (`9_jupiter_sky_auto.png`) does not show it. The straight terminator is real: from this stop the ship is nearly in Jupiter's terminator plane (quarter phase), which projects to a line.
- REALISTIC exposure is set for the dark sky, so Earth, Saturn and Aldebaran are white discs in it; the capture also saves the AUTO view (D-38, `*_sky_auto.png`), where Earth, Saturn's bands and rings and Aldebaran's colour show.
- `defaultStopKm` gives every default star body plan the D-54 star curve, whatever `stop_rule` is (the Sun, alpha Cen A/B, Aldebaran, TRAPPIST-1; `checkDefaultStarStops`); the tour's star stops are unchanged because they pass explicit D-47 standoffs.
- `stop_rule`, like `standoff_au`, is a `new_game` override and not in the params echo: a replay carries it in its recorded `new_game` line (the session log), as standoff_au always has.
- The start-inside exemption is the Sun's alone (`f.id == "sun"`, `planFiniteStop` only); `checkStartInside` shows a finite stop from inside the Earth is still refused.

## Open questions for the user

All three are resolved (D-58, Mark attended 2026-10-09): the package release was approved and done, and the ring rule as built (dense rings, tau >= 0.1) is what Mark chose. See "D-58 completion" below.

## D-58 completion: inferred radii, synchronous orbits, the ISCO (2026-10-09)

Packages first (CLAUDE.md gate 3), ailang-packages PR #105, both published:
- `sunholo/relativity` 0.11.0: `bolometricCorrectionV(teffK)` (Pecaut & Mamajek 2022.04.16 BCv, clamped), `luminositySunFromV(v, distancePc, bc)` (M_bol,sun 4.74, IAU 2015 B2), `radiusSunFromLuminosity(lSun, teffK)` (Stefan-Boltzmann, 5772 K); `schwarzschild.isco()` = 3 r_s; the geodesic step-size note corrected. Validated there against measured radii: Sun -0.3 %, alpha Cen A -0.3 %, B -1.6 %, Aldebaran -4.5 %, Arcturus +3.7 %, Barnard's +0.3 %, TRAPPIST-1 about +10 %, Proxima -31 % with Segransan's 3042 K (the M-dwarf limit). Torres 2010 was measured and rejected for M dwarfs.
- `sunholo/celestial` 0.3.0: `semiMajorAxisFromPeriod(gm, periodDays)`.

Game (`feat/inferred-radii`):
- `sim/inferred_stars.ail`: a free-navigation star plan (stop_rule 54) may carry the map's catalogue row `{star: {name, v, teff}}` (protocol 2.7, `stopsMinor`). A star with no cited radius becomes a finite star (status `inferred`, its catalogue id, Teff colour, the inferred `{r_sun, l_sun, bc_v, distance_pc, v}`) and the leg stops at its D-54 distance; the world keeps it (`World.catStars`) while the ship is within 0.1 ly or it is the journey's target. Rows without photometry keep 1,000 AU. The I card says "Radius inferred, not measured" with L, V, distance and BC_V.
- `sim/sync_orbit.ail`: each Sol body's stationary orbit from its WGCCRE rotation rate and GM (Kepler's third law), "none" when tidally locked (rotation within 2 % of the orbital period) or when it lies beyond the Hill sphere (the same law with GM/3 and the orbital period). Earth 35,786 km, Mars 17,031 km, Jupiter 88,517 km, the Sun 24.6 million km; the Moon and every moon here locked; Mercury and Venus too slow. On the wire as `sync_orbit` (2.7); `ui/body_info.gd` formats the line.
- `sim/gr.ail` takes `isco()` from the package. The hello reports relativity 0.11.0 at 2.7; 2.6 keeps 0.10.0.
- Stops at inferred stars (`tools/stops_capture.gd -- --inferred`, `renders/stops/inferred/`): Barnard's Star 0.189 R_sun (measured 0.178-0.187), 4.36 deg at 0.023 AU; Proxima Centauri 0.156 R_sun with the catalogue's 2905 K (measured 0.154), 3.96 deg; 61 Cygni A 0.655 R_sun (measured 0.665), 8.1 deg; Vega 2.62 R_sun (polar 2.36, equatorial 2.82: a fast rotator), 16.1 deg.

| # | Criterion | Command |
|---|---|---|
| 8 | Inferred star stop (Barnard's) and sync orbits on the 2.7 wire; stop_rule 0 or no row keeps 1,000 AU | `cd sim && ailang test stops_test.ail`, `make strict` (stopsVm) |
| 9 | Sync orbits: Earth 35,786, Mars 17,032, Jupiter 88,517 km; locked moons; Mercury and Venus slow | `cd sim && ailang test sync_orbit_test.ail` |
| 10 | Real flow: Barnard's Star arrives finite (0.189 R_sun, 4.37 deg), the I card says inferred; Earth's card 35,786 km, the Moon's none (locked), Venus's none (slow) | `make free-nav-stop-test` |

## Deliverables

`sim/stops.ail`, `sim/stops_test.ail`, the navigation/core/protocol/solar_departure changes, `ui/galaxy_map.gd`, `demos/ship_geometry_demo.gd`, `tests/test_free_nav_stop.gd` (`make free-nav-stop-test`), `tools/stops_capture.gd`, CHANGELOG; D-58: `sim/inferred_stars.ail`, `sim/sync_orbit.ail` (+ tests), `ui/body_info.gd`, protocol 2.7.
