# Sprint R1-M5-TRAPPIST-1 (B): a real exoplanet system as a stop

**Design doc:** [m4-real-time-tour.md](m4-real-time-tour.md), Sprint B section (D-41). It can start after Sprint A's RT1, or alongside it, because it only adds data and bodies.
**Status:** Approved by Mark, attended 2026-10-06.
**Estimate:** about 850 LOC, 3 days.
**Risk:** medium. The open questions are orbit-phase extrapolation and intercept clearance among seven close planets.

## Registry reuse

| Milestone | Package | Action | Reason |
|---|---|---|---|
| TB2, TB5 | `sunholo/celestial` (pinned) | depend | Kepler orbits, light-time and reflected light are already there, as used for α Cen. |
| TB3 | `sunholo/relativity` | depend | Finite star photometry. |

## Milestones

| ID | Work | LOC | Acceptance (design) |
|---|---|---|---|
| TB1 | Use starmap-manager to fetch the TRAPPIST-1 archive rows; add the sha256 pin; re-verify against Agol et al. 2021 | 60 | B1 |
| TB2 | `sim/data/trappist1.ail`: `{value, status, source}` rows for the star and seven planets, and orbit phasing from transit epochs; tests first | 220 | B1 |
| TB3 | Protocol body feed within 0.1 ly; exact suppression of the Gaia point; finite M-dwarf disc | 160 | B2 |
| TB4 | Minnaert appearance from assumed albedo rows; an info card whose label derives from each row's status, with a test that flips a status | 120 | B4 |
| TB5 | Inner-system tour leg between the e and f orbits; intercept and clearance checks for all eight bodies | 170 | B3 |
| TB6 | Goldens for the M-dwarf disc and reflected light, inspected renders, `make test`, PR, evaluation and dev build | 120 | B4, B5 |
