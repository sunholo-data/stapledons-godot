# Changelog

## Unreleased

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
