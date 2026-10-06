# Sprint R1-M4-EVEN-LEGS (approved, Mark attended 2026-10-06)

Design: [m4-even-legs-and-approach.md](m4-even-legs-and-approach.md). About 900 LOC, ~1.5 days.

| ID | Work | Order |
|---|---|---|
| EL1 | Package: `planBurnCoastBrakeApproach`, `TripPlan` approach fields, `Approaching`, `motionAt`/`phaseAt`; tests first; CHANGELOG; quality; publish 0.9.0 | 1 |
| EL2 | Sim: pin 0.9.0; `timing` on body plans (protocol 2.6, optional); the leg solver; the approach chooser; the cap above 0.99c for timed plans; per-leg drag check; the `approaching` phase in core and protocol; tests | 2 |
| EL3 | Host: the itinerary sends timing for in-system body legs; the skip button and key; HUD "FINAL APPROACH" and per-leg thrust; captures and tests | 3 |
| EL4 | Evidence renders; `make test`; PR; evaluation (a different model); dev.18 | 4 |
