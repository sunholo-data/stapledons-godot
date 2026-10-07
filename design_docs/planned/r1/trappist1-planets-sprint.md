# Sprint R1-TRAPPIST1-PLANETS: TRAPPIST-1's seven planets as a real stop

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | Same commitments; the stop is the same leg of the same voyage. |
| The Game Doesn't Judge | +1 | Every planet number is cited from the archive snapshot; assumptions (albedo, sky-plane node, circular orbits) are labelled as such. |
| Time Has Emotional Weight | +1 | The planets are where they really are when the ship arrives, 40.6 years of light-time after the transits we measured. |
| The Ship Is Home | +1 | The habitable-zone stop gets a view: a world beside the window, others as discs around a red star. |
| Grounded Strangeness | +2 | Seven Earth-sized worlds around a star the size of Jupiter, from inside its habitable zone. |
| We Are Not Built For This | 0 | No change. |

Net +5: aligned.

**Design doc:** [m4-real-time-tour.md](m4-real-time-tour.md), Sprint B (D-41); part 1 is [finite-destination-stars.md](finite-destination-stars.md) (D-47/D-48).
**Approved sprint this adapts:** [m5-trappist1-sprint.md](m5-trappist1-sprint.md) (TB1–TB6, Mark, attended 2026-10-06), selected for dev.20 by Mark on 2026-10-07.
**Status:** completed (see `.ailang/state/sprints/sprint_R1-TRAPPIST1-PLANETS.json`).

## What part 1 already delivered (not repeated here)

TRAPPIST-1 is a finite star (Agol 2021 radius, Teff, L) at its navigation catalogue position, its Gaia point suppressed. The guided voyage (10 stops) stops in its habitable zone at √L = 0.0235 AU (D-47), where the star is 2.70° across. So TB3's star half (finite M-dwarf disc, exact suppression) is done. This sprint adds the planets and makes the stop show them.

## Registry reuse

| Milestone | Package | Action | Reason |
|---|---|---|---|
| TB2 | `sunholo/celestial` 0.1.0 (pinned) | depend | `kepler.stateFromElements`, `orbitNormal`; `lighttime.retarded`; `reflect.discIlluminance` |
| TB3 | `sunholo/relativity` 0.9.0 | depend | `photometry.illuminanceFromV` for the star's V illuminance |

No new formula: everything is composition of package functions with cited rows.

## Milestones (adapted)

| ID | Work | Acceptance | Command |
|---|---|---|---|
| TB1 | Snapshot of the NASA Exoplanet Archive `ps` rows for TRAPPIST-1 (40 rows, every published set), fetched with curl from the TAP API (`tools/fetch_trappist1.sh`), committed as `data/planets/trappist1_ps.csv` and pinned by sha256 in `data/planets/EXOPLANETS.SHA256`. Cross-checked against Agol et al. 2021 (arXiv 2010.01074 Table 2; the archive's default set is Agol's). | The pin matches | `tools/fetch_trappist1.sh --verify` |
| TB2 | `sim/data/trappist1.ail`: `Field` rows (`measured` / `assumed`, with citation) for b–h. `sim/trappist1.ail`: circular Kepler orbits in the sky basis about the star, phase from the transit ephemeris less the light time. Tests first. | Rows cited; a recomputes from P (Kepler III) within 0.5 %; the ephemeris predicts JWST 2024 transits within 0.5 h; transit geometry; positions = Python oracle | `make trappist1-test`; `sim/trappist1_test.ail` |
| TB3 | The planets in the system section within 0.1 ly of TRAPPIST-1, b..h after the destination stars (indices = navigation facts); reflected light from the star's V illuminance; on the wire `teff_k` (the host's) and `e1_au_lux`, so `planets/system_view.gd` lights them by TRAPPIST-1, not the Sun. | Feed order and index; discIlluminance recomputed; not fed at Sol | `sim/trappist1_test.ail` (checkFeed, checkWire); `make solar-departure-test` |
| TB4 | Appearance: assumed p_V (0.1 for b and c, dark rock as JWST 15 µm suggests; 0.3 for d–h), Lambert (k = 1), marked `assumed`. The info card from row status (approved TB4) is deferred: no card UI is in the guided demo yet. | Assumed rows are marked | checkRows |
| TB5 | The HZ stop keeps √L AU from the star but is placed beside the planet that is largest there while more than half lit (navigation `planBesidePlanet`). Collision checks include all eight bodies on every leg near TRAPPIST-1; clearance over the stop. | Stop at 0.0235 AU (within 1 km), beside e (0.72°), four planets ≥ 0.25°; every orbit > 30 radii from the resting ship; voyage still 10 stops | checkStop, checkClearance; `make solar-departure-test` |
| TB6 | Renders at the stop (`tools/trappist1_capture.gd`), opened and inspected; `make test`; PR. | Frames show the red star and planets as discs | `godot --path . --script tools/trappist1_capture.gd` |

## Data provenance

| Field | Source | Status |
|---|---|---|
| radius, mass, a, inclination, period | Agol et al. 2021, PSJ 2:1 (archive default set) | measured |
| transit epoch T0, mean period | Ducrot et al. 2020, A&A 640:A112, Table 4 (archive rows) | measured |
| JWST epochs of b, c (check only) | Rathcke et al. 2025, ApJL 979:L19 | measured |
| stellar mass (Kepler III check) | Agol et al. 2021 | measured |
| e = 0 | Agol's TTV fit: e < 0.01 | assumed (stated) |
| sky-plane node | not measurable by transits | assumed 0 |
| p_V, Minnaert k | no V albedo measured; b, c dark per JWST 15 µm | assumed |

Why two papers for the orbit: Agol's archive rows have no transit epoch, and its Table 2 P and t0 are osculating Jacobi elements at BJD 2457257.93. Extrapolated over decades they drift by hours (they miss the JWST 2024 transits of b and c by 2.7 h and 4.2 h). Ducrot's mean linear ephemeris hits them within 15 minutes, so it phases the orbits.

**Phase and light time.** A transit epoch is when the transit's light reached the Solar System. The star is at rest in the game's Sol frame, so at local coordinate time `jd` the phase is the ephemeris's at `jd + D/c` (D = 40.62 ly). The voyage arrives at Sol-frame JD 2468377.8 (2045.9), which is observed-equivalent 2086. Over the 25,000 days from the 2016 epochs, the formal period errors move the phases by 0.003–0.025 d (under 0.2 % of an orbit). TTVs (minutes to about an hour) are not modelled.

## The stop (TB5)

Without placement, the HZ stop (on the approach line, Earth side) arrives with the planets mostly beyond the star: largest b at 0.23°, the rest 0.04–0.16°, at most 2 px. The stop keeps the D-47 rule, but chooses where on the √L sphere to sit.

- The planner places a stop s short of planet P on the line from the ship. That point lies on the sphere when s² − 2s(p·u) + |p|² − r² = 0.
- Among planets that are more than half lit from there (p·u > 0), it takes the one that would look largest.
- The arrival time comes from the planner: three rounds starting from the plain star stop.
- The plan is reported as the stop at TRAPPIST-1 with stand-off r (`hold.body` = `trappist-1`, `offset_km` = √L AU).

At the voyage's epoch the stop is beside e:

| Planet | Distance (AU) | Across (°) | Phase (°) |
|---|---:|---:|---:|
| e | 0.0062 | 0.72 | 21 |
| c | 0.0129 | 0.41 | 109 |
| d | 0.0117 | 0.33 | 81 |
| f | 0.0162 | 0.31 | 18 |
| b | 0.0320 | 0.17 | 35 |
| g | 0.0590 | 0.09 | 22 |
| h | 0.0408 | 0.09 | 12 |

The ship rests 0.023515952 AU from the star, 0.04 km from the rule.

The final leg passes the star at 0.0103 AU (18.6 stellar radii), 3.2 million km before the stop (`passProbe` in `sim/trappist1_test.ail`). Only collision clearance is checked; thermal hazards are not simulated, as for every stop.

Clearance: the √L sphere is just outside d's orbit (0.0223 AU), so d is the nearest planet over time: about 192,000 km (38 radii) at its closest. The others stay beyond 140 radii, and the star is 42 stellar radii away.

## Deviations from the approved TB1–TB6

- TB3's star half and the 0.1 ly activation landed in part 1. The planets use the same 0.1 ly rule as navigation, and come last in the feed so no other index moves.
- TB5 is not an extra "between e and f" leg. The D-47 HZ stop is kept and placed beside a planet, so the voyage stays 10 stops and leg indices don't move (the parallel Aldebaran track keeps its leg 8/9).
- TB4's info card is deferred. TB6's GPU golden for reflected light is not added: planets reuse the existing Minnaert disc shader and its goldens; only the illuminant colour and e1 are new inputs.
- The planets aren't plan targets (visitable false): their albedos are assumed.

## Acceptance commands

```sh
tools/fetch_trappist1.sh --verify
make trappist1-test AILANG=runtime/bin/ailang      # strict VM = interpreter, Python oracle
cd sim && ../runtime/bin/ailang test trappist1_test.ail
make solar-departure-test AILANG=runtime/bin/ailang
godot --path . --script tools/trappist1_capture.gd  # renders/trappist1/*.png, GPU window
make test AILANG=runtime/bin/ailang
```
