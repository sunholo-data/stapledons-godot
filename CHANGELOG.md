# Changelog

## Unreleased

### M1 sky, 2026-09-27 – 2026-09-30 (in progress; 3 of 12 milestones)

- **M1.1 photometry (iteration 0):** `sunholo/relativity@0.2.0`
  (BP−RP → T_eff, G−V, V → lux); game pin `b258222`.
- **M1.2a catalogue (iteration 2):** CNS5 + GCNS acquired from VizieR and
  parsed to galactic CSV (5,908 + 331,312 rows), 15 real-byte-fixture tests
  in `make test`; merge `77d3f04`.
- **M1.6a turns at rest (iteration 3):** pure ship turns at rest with phi
  snap and `origin + heading*(x−x0)`; `std/json` protocol v1.1 with reason
  codes; bounded bridge waits (5 s hello, 2 s step, 1 s graceful exit);
  off-axis parity and strict `scriptedOffAxis`; default-heading render
  unchanged (601-line v1.0 parity byte-identical). Requires AILANG v0.47.2
  (fixes the two VM bugs that parked this milestone; see the design doc's
  toolchain amendment).

- **M1.2b preflight (iteration 4):** bounded AILANG CSV and published normal
  photometry probe, real-byte fixture checks, strict VM/interpreter parity
  and real 5,000-row timing. WD fitting, production tiers and binary
  writing remain incomplete and depend on the package prerequisite.

- **M1.2b white-dwarf photometry (iterations 5–6):** `sunholo/relativity@0.3.0`
  published (blackbody WD Teff and V from Gaia BP−RP); the game pins it,
  `checkWDPackage` pins the fixture WD row, and `make wd-vm` checks the
  package's NaN contract on the strict VM (ailang#1419 hides NaN-guard
  mutants from the interpreter-only `ailang test`). PR #12, merge `68575d9`.

### M0 spike, 2026-09-27 (~1,900 LOC including tests)

- **Simulation:** AILANG sidecar over NDJSON stdio, about 50 µs per tick
  round trip.
  - Pure core on the bytecode VM, checked under `--strict-bytecode`.
  - I/O shell bridged to the interpreter.
- **Physics:**
  - GDScript reference: 27 checks.
  - GPU starfield: aberration, blackbody Doppler colour, point-source beaming,
    HDR.
  - 9 golden cases at under 0.1 px.
- **`sunholo/relativity@0.1.0`:** published (about 600 LOC, 40 tests); the
  simulation depends on it.
- **Tooling:** `make test` (physics, sim, parity, strict) and CI.
- **Process:** the design-doc → sprint → execute → evaluate cycle, the
  `game-vision-designer` and `starmap-manager` skills, and the M1 design doc.
- **Upstream reports:** 11 AILANG bug and DX reports.
