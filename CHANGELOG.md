# Changelog

## Unreleased

### Review-build polish, 2026-10-02 (Mark's feedback on `v0.3.1-m2-journey`)

- **Trackpad zoom on the galaxy map:** pinch (magnify gesture) and two-finger
  scroll (pan gesture, one unit = one wheel notch) zoom, clamped like the
  wheel; `+`/`=` and `-` zoom by a notch. Two-finger scroll never orbits.
- **HiDPI and UI size:** `allow_hidpi`, canvas-items stretch (aspect expand)
  so the panel scales while 3D renders at full resolution; on a HiDPI screen
  the window opens at base × screen scale. Cmd/Ctrl `+`/`-`/`0` change the UI
  size (0.75–3.0). Captures and goldens keep the 1:1 window: committed
  `docs/m2.6a`, `docs/m2.6b` PNGs are byte-identical.
- **Footer hint** "Pinch or scroll to zoom · drag to orbit · ⌘+/− UI size"
  (hidden in `--map-capture`).
- **Missing sky background is loud:** the sky flight warns on startup and
  shows "sky background not bundled in this build" when the M1.4 panorama is
  absent (HUD note hidden in `--capture`).

### M2 journey core, 2026-10-01 – 2026-10-02 (sprint R1-M2-JOURNEY, landed; bar clause 2 met)

Ten milestones, PRs #22–#35, each independently evaluated (89–96/100).
Report: `design_docs/implemented/r1/m2-report.md`.

- **M2.0 package (96):** `sunholo/relativity@0.4.0` published (ailang-packages
  #84): boost–cruise–brake and flip-and-burn trip plans, `phaseAt`,
  `motionAt`, `acosh1p`, `rapidityOfOneMinusBeta`, ISM `medium`, forward CMB
  temperature; 101/101 tests.
- **M2.1a protocol codecs (92), M2.1b bridge v2 (93):** protocol v2 with
  hand-written codecs and float-text repairs (−0.0, large/small floats);
  `SimBridge` v2 with a `record_path` tee and bit-exact float64 echo; v1.1
  removed.
- **M2.2 world (94):** `World`, scenario params, clock, ship phases, closed
  energy ledger; game pins relativity 0.4.0.
- **M2.3a planner + commit (95), M2.3b autopilot (96):** planner equals the
  closed form to 1e-9; the sim refuses every intent against a committed
  journey; stepped voyages match `motionAt` at every phase boundary, arrival
  residuals ≤ 4.8e-13 ly.
- **M2.6a galaxy map (89), M2.6b commit ritual (93):** galaxy map with a
  sim-bounded cruise slider and a panel of sim numbers only (review build
  `v0.2.0-m2-map`, R1 accepted by Mark, D-17); commit dialog with both clocks,
  years left and a 1.5 s hold, transit readout, refusal display, 54 common
  star names. Map → plan → commit → transit now runs end to end.
- **M2.4 PRNG (94):** SplitMix64 with six named streams (`splitmix64-1`),
  checked against published vectors and a reference on both runtimes.
- **M2.5 replay (93):** `make replay` / `make replay-record`; a 10,000-tick
  session is byte-identical on the VM and the interpreter and matches its
  golden. Goldens are per architecture (ailang#1465); P5 approved by Mark.
- **Toolchain:** AILANG pinned to v0.50.0 (#18), then v0.51.0 (#30).
  Thirteen AILANG issues filed or tracked during M2 (see the report).

### Fix: mirrored galactic longitudes in stars.json, 2026-10-02

- Every longitude in `data/starmap/stars.json` was mirrored, l = 245.86° − l_true
  (`process_stars.sh` added the IAU atan2 term to l_NCP instead of subtracting
  it). Fixed and regenerated from the same VizieR V/70A votable (the unfixed
  script reproduces the old file byte for byte): same 3,802 rows and order,
  only x, y change. 16 literature (l, b) check values in `tests/test_physics.gd`.
  The M1.4a destar mask (D-10) was built from the mirrored positions and needs
  a rerun.

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

- **M1.2b pure transform (iteration7):** package-backed normal/white-dwarf
  photometry, explicit missing/clamped flags and independent counters; stable
  nearest-complete medium selection with quick/large source order preserved.
  Ten new tests and strict-VM/interpreter anchors run in `make test`.
  Independent Sonnet5.5 review: 88/100 PASS. Binary writer and full-tier
  parity/performance remain pending; full M1.2b is incomplete.

### Catalogue F32 records (M1.2b-T2, iteration 8)

- Pure AILANG Row/list encoding uses the bundled native little-endian F32 codec;
  invalid fields or flags refuse the whole output before any writer is involved.
- Independent Python byte oracle runs interpreter and five ordinary VM passes in
  `make test`; strict T1 tests now pin dwarf clamps and exactly one final newline.
- Filesystem writing, sidecars and production catalogue tiers remain downstream.

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
