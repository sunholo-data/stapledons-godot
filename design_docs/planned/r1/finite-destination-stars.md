# Finite destination stars: every star you visit has its real size

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | Same commitments. |
| The Game Doesn't Judge | +1 | Every radius and temperature is cited, with its provenance (measured or inferred). |
| Time Has Emotional Weight | 0 | Unchanged clocks. |
| The Ship Is Home | +1 | Each arrival is an event at the window: a real star, at a size that means something. |
| Grounded Strangeness | +2 | A 45 R☉ red giant filling 40° of sky; an ultracool dwarf from its habitable zone. |
| We Are Not Built For This | 0 | No change. |

Net +4: aligned.

**Status:** Approved by Mark, attended 2026-10-07: "yes please fix the stars now". This follows D-47 ("fixed size, but a giant gets a big view") and the glow ruling ("the glow is great, it helps show how it is").
**Release:** R1. This is Sprint B, part 1: finite destination stars. TRAPPIST-1's planets follow in part 2.
**Depends on:** the α Cen finite-star pattern (`sim/alpha_centauri.ail`), timed legs and the final approach (D-46, `sunholo/relativity` 0.9.0), and destination pinning.

## Problem

Only the Sun and α Cen A/B are finite in the sim. TRAPPIST-1 and Aldebaran are catalogue points seen from the 1,000 AU stand-off, so arrivals at stars don't feel like the planets' (Mark, 2026-10-06).

## Design

1. **Data.** `sim/data/stars.ail` holds cited `Field` rows, as in `data/acen.ail`:
   - **Aldebaran (α Tau, CNS5:1142).**
     - Limb-darkened angular diameter 20.58 ± 0.03 mas (Richichi & Roccatagliata 2005, A&A 433, 305), measured.
     - Radius *inferred* from that angle and the catalogue distance, about 45 R☉.
     - Teff 3,927 ± 40 K (Heiter et al. 2015, A&A 582, A49).
     - Luminosity inferred from R and Teff.
     - Class K5 III (giant).
   - **TRAPPIST-1 (Gaia DR3 2635476908753563008).**
     - Radius 0.1192 ± 0.0013 R☉, Teff 2,566 ± 26 K, L 5.53 × 10⁻⁴ L☉ (Agol et al. 2021, PSJ 2, 1).
     - Class M8 V.
   - V at Earth comes from the navigation catalogue row. Positions are static at the catalogue (navigation) position.
2. **Bodies.** `sim/destination_stars.ail` feeds a finite star body for each into the system section. Each one replaces its catalogue point by exact identity, as α Cen does, along with any destination pin. Its illuminance follows from V and distance. Its photosphere is uniform (limb_u 0, stated).
3. **The stop rule (D-47).**
   - Main sequence: stop at the habitable zone, √L AU from the star. TRAPPIST-1: 0.0235 AU (≈ 2.7° across). α Cen A: 1.233 AU (replacing D-37's 1 AU).
   - Giants: stop where the star fills 40°, at R / sin 20°. Aldebaran: about 0.61 AU.
   - The rule is computed in the sim from the data rows.
4. **The rhythm (D-46 applied to stars).** The final hop from the 1,000 AU stand-off to the stop is a timed leg: 30 s boost, ~60 s cruise, then the 25 s final approach.
   - For a star that never reaches 4° (TRAPPIST-1, α Cen A), the approach covers the last stand-off distance.
   - The 1,000 AU hop reaches γ ≈ 7,500, so the guided cap becomes 1 − β = 2 × 10⁻⁹. It still passes the brake-vs-drag check with margin (drag ≈ 1 × 10⁸ N against 2.9 × 10⁸ N of brake).
   - The interstellar crossings are unchanged (interludes).
5. **Navigation.** Within 0.1 ly of a destination star, a stop-only adapter (as for α Cen) plans to the star with its facts. The largest stellar stand-off allowed is 10 AU.
6. **Itinerary.** Earth → Sun → Jupiter → Callisto → Saturn → α Cen (system) → α Cen A (HZ) → TRAPPIST-1 (system) → **TRAPPIST-1 (HZ)** → Aldebaran (system) → **Aldebaran (40°)**.

## Acceptance

| # | Criterion | Command |
|---|---|---|
| S1 | Data rows are cited; inferred values recompute from their inputs; stop rules give 0.0235 AU, 1.233 AU and about 0.61 AU | sim tests |
| S2 | Star bodies are fed with catalogue suppression (no double light); the planner stops at each by the rule | sim tests; `make solar-departure-test` |
| S3 | The full voyage reaches all 11 stops; each star hop has a 30 s boost and a 25 s approach; arrival distances match the rule | `make solar-departure-test` |
| S4 | Renders show each star's arrival (Aldebaran filling ~40°, TRAPPIST-1 a red disc beside its HZ) | capture tool |
| S5 | Gate 1 | `make test`, CI |
