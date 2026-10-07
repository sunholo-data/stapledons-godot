# Sprint R1-SHIP-STAR-LIGHT: the ship lit by the real star

**Design doc:** [ship-star-light.md](ship-star-light.md).
**Status:** Approved by Mark for dev.20, 2026-10-07. Executed on branch `sprint/ship-star-light`.
**Estimate:** about 600 LOC, 1.5 days.
**Risk:** low. No new physics, no sim or package change; the renderer's values are reused.

## Registry reuse

| Milestone | Package | Action | Reason |
|---|---|---|---|
| SL1 | `sunholo/relativity` (pinned, mirrored in `physics/planets.gd`) | depend | `apparentDisc`, `doppler`, `pointFluxRatio` already mirrored and audited (M5.3). |

## Milestones

| ID | Work | LOC | Acceptance (design) | Status |
|---|---|---|---|---|
| SL0 | Tests first: `tests/test_ship_star_light.gd` (mapping, colour, direction vs rendered disc and textbook aberration, two-camera pixel check with a negative control, easing, hysteresis, dark cruise, eclipse, labels, demo integration); `make ship-star-light-test` in `ship-demo-ci` | 250 | A1–A7 | done |
| SL1 | `demos/ship_star_light.gd`: emitters, apparent direction, frame transform, colour, compressed energy, easing, hysteresis, key cross-fade, manifest, HUD line | 190 | A1–A7 | done |
| SL2 | Wiring: `ship_lighting.gd` (key base, shadow profile, manifest), `ship_geometry_demo.gd` (install, per-frame update, HUD details) | 20 | A7 | done |
| SL3 | `tools/ship_star_light_capture.gd`: the guided tour, bridge / overlook / Commons at Earth, the departure turn, near Jupiter, Saturn, interstellar cruise, TRAPPIST-1, Aldebaran; inspect renders | 110 | A8 | done |
| SL4 | `tools/ship_star_light_bench.gd`: paired 1920×1080 frame times, ship-only vs star+key vs star | 70 | A9 | done |
| SL5 | Docs: design doc, CHANGELOG, `art/ship-lighting-v1/README.md`; full `make test`; PR | — | A10 | done |

## Order

SL0 → SL1 → SL2 → SL3 ∥ SL4 → SL5. Pause point after SL2: the headless test must be green before renders.
