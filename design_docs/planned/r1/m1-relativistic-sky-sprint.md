# Sprint plan: R1-M1-SKY, the relativistic sky

## Summary

Make the sky out of every window physically correct, at any speed and in any
direction. That means:
- real Gaia colours and brightnesses for all 331k GCNS stars;
- a Milky Way background with correct aberration and Doppler shift;
- photometric exposure;
- free motion and view direction.

All of it verified by the physics spec's check values and GPU golden tests.

**Design doc:** [m1-relativistic-sky.md](m1-relativistic-sky.md) (AC1–AC10)
**Sprint ID:** `R1-M1-SKY` · **Progress file:** `.ailang/state/sprints/sprint_R1-M1-SKY.json`
**Duration:** 5 working sessions (M1.0 folded into session 1), plus a pause for the user's decision after
M1.4a
**Dependencies:** `sunholo/relativity@0.1.0` (published), the M0 spike (CI
green at `9929111`)
**Risk level:** Medium. Two external data pipelines, a first real AILANG VM
workload, and a user decision in the middle.

## Current status analysis

### Completed recently (2026-09-27, one attended session)
- ✅ M0 spike: about 870 LOC of GDScript, shader and AILANG, including 2 test
  suites, 9 golden cases and CI.
- ✅ `sunholo/relativity@0.1.0`: about 780 LOC (6 modules and 40 tests),
  published.
- ✅ Process setup: cycle, CI, M1 design doc, charter draft.

### Velocity
- **Measured:** about 1,650 LOC of code and tests in one attended session.
  About half that session went on debugging and AILANG workarounds: 11
  upstream reports, and 3 of my own bugs caught by tests.
- **Planning figure:** about **700 LOC per session**, roughly half the
  measured rate. M1 adds two data pipelines, a sky shader, performance work and
  human review gates, which the spike didn't have.
- **Capacity:** 5 sessions × 700 ≈ 3,500 LOC against the design estimate of
  2,600, about 35% buffer.

### Pre-planning checks (done while planning)
- The Mamajek dwarf table is reachable. It has **both** `Bp-Rp` and `G-V`
  columns (G2V: 5770 K, 0.823, −0.165). **Design doc updated:** G−V comes from
  the same table, with the Riello cubic as a test-only cross-check.
- GCNS `table1c.dat.gz` (75 MB) is reachable.
- **The CNS5 URL in the old skill is dead (404).** VizieR `J/A+A/670/A19`
  `cns5.dat` (5,909 records, fixed-width, G/BP/RP) is the replacement. Design
  doc updated.
- The NOIRLab `noirlab2430b` panorama is 207 MB at full size. That's
  acceptable for the offline M1.4a spike; it never ships.

## Milestones

### M1.0: Review builds (added at the user's request, 2026-09-27)
**Goal:** the user reviews on their own Mac laptop, with no remote desktop and
no Tailscale (Tailscale is in use for Daneel's video avatars).
**Estimated:** about 150 LOC (config, CI, a runtime path shim) · **Session:** 1
(first) · **Depends on:** —

**Tasks**
- Install the Godot 4.7.2 export templates on the Studio, and check them.
- `export_presets.cfg`: a macOS preset (universal). The bundle includes the
  `ailang` binary and the `sim/` package sources and lockfile, placed under
  `Contents/Resources/`.
- `bridge/sim_bridge.gd`: in exported builds, resolve `ailang` and the
  simulation from the bundle, and fall back to `PATH` in the editor. The
  AILANG package cache must be available offline, so bundle a pre-fetched
  cache and set the cache directory (or `HOME`) for the child process.
- `make export-macos`: a local build, with a smoke test that launches the
  exported app with `--capture` and checks that the PNGs appear.
- CI job `macos-build`: on a `v*` tag, build on `macos-latest`, zip it, and
  attach it to a GitHub Release.
- **Review page** per milestone: a private claude.ai artifact with renders,
  golden results, bench numbers and the decisions needed, plus the images sent
  to the user's device. A GitHub PR per milestone.

**Acceptance criteria:**
- `make export-macos` produces an `.app`. Launched on the Studio with no
  `ailang` on `PATH`, its capture run produces the reference renders.
- A tagged pre-release (`v0.1.0-m0`) carries the zipped `.app`, downloadable by
  the user.
- The user launches it on their laptop and confirms (they're told about the
  unsigned first launch: right-click → Open).

### M1.1: Package photometry, `sunholo/relativity@0.2.0`
**Goal:** Gaia BP−RP → T_eff, G → V, V → lux, with one source of truth.
**Estimated:** 250 implementation + 250 tests = 500 LOC · **Session:** 1 · **Depends on:** —

**Tasks**
- `tools/mamajek_to_ail.py`: download the Mamajek table (URL and version date
  go into the output header), extract (Bp−Rp, Teff, G−V) for the dwarf
  sequence, and emit `photometry_table.ail` as a sorted literal array. It's
  generated, never hand-edited.
- `photometry.ail`:
  - `teffFromBpRp` and `gMinusV`, using monotone piecewise-linear interpolation
    with clamping and an in-range flag;
  - `vFromG`, `illuminanceFromV` and `fluxRatioFromMags`.
- Tests:
  - the known-star table (Sun, Sirius A, Proxima, α Cen B, Barnard's Star)
    within 5%;
  - interpolation monotonicity and endpoint clamping;
  - the Riello cubic agreeing within 0.05 mag over 0.4–3.0;
  - V = 0 → 2.56 µlx.
- `CHANGELOG ## 0.2.0`, `[release] kind = "feature"`, AGENT.md section,
  `pkg quality` with no gates, dry run, then **publish (attended)**. Pin 0.2.0
  in the sim.

**Acceptance criteria:** AC1.
**Risks:** transcription errors in the table. *Mitigation:* the table is
generated from the source file by a script; known-star tests; the URL is
recorded.

### M1.6: Free motion and orientation (runs in parallel with M1.2)
**Goal:** any heading and any view direction, with golden tests off-axis.
**Estimated:** 200 + 250 = 450 LOC · **Sessions:** 1–2 · **Depends on:** —

**Tasks**
- `sim/core.ail`:
  - the ship gets a `heading: Vec3` and a 3D position; thrust acts along the
    heading;
  - `setHeading` works only at rest (β < 1e-9) and is rejected otherwise, with
    a reason code in the state output;
  - `scripted` gains a heading argument.

  It stays pure, and `make strict` stays green.
- `sim/ship.ail`: protocol v1.1 with `hello`/`version`, optional `heading` on
  `step`, and `heading` and `pos` in the state output. Round-trip codec tests
  go in `sim/protocol_test.ail`, using named `check…()` functions because of
  the test-block float bug.
- Godot:
  - a free-look camera (yaw, pitch, roll);
  - the HUD shows the angle between view and velocity;
  - the starfield takes the velocity direction from the simulation.
- `tests/test_physics.gd`: the §2 check values repeated for off-axis
  velocities (±X, ±Y, (1,1,−1)/√3) and a rolled camera.
- `make golden`: 12 directions × 4 speeds × 3 camera orientations.

**Acceptance criteria:** AC4 and AC5 (star part), plus AC10 (strict and
parity stay green).
**Risks:** combining a Godot camera roll with float32 transforms.
*Mitigation:* the golden tests compare against CPU projection through the same
camera object.

### M1.2: Catalogue pipeline v2 (the AILANG VM stress test)
**Goal:** quick/medium/large tiers with physics done in AILANG, with measured
VM behaviour.
**Estimated:** 350 + 150 = 500 LOC · **Session:** 2 · **Depends on:** M1.1

**Tasks**
- Fix the `starmap-manager` scripts: CNS5 from VizieR and GCNS from VizieR,
  with the download size and checksum logged.
- `tools/extract.py`: parse the fixed-width CNS5 and GCNS files into a compact
  CSV (`id,x,y,z,G,BPRP,wd`, galactic, ly). Parse only, no physics. For CNS5,
  convert RA/Dec/parallax to galactic XYZ using the IAU rotation matrix, with a
  test on known stars (α Cen at 4.37 ly).
- `sim/tools/catalogue.ail`: read the CSV, apply the package's photometry, and
  write binary float32 records plus a JSON header (IO/FS effects only in the
  shell; the transform is pure). `make catalogue TIER=…`.
- `make catalogue-parity`:
  - VM vs interpreter output compared with `cmp` on medium;
  - timing on both;
  - `--strict-bytecode` on the pure transform.

  Any divergence or bridged hot call becomes an upstream report.
- `tools/catalogue_stats.py`: class demographics; AC3 requires M dwarfs to be
  at least 60%.
- **Fallback trigger:** medium takes more than 60 s on the VM, or a blocking VM
  bug. Then compute in Python from a package-exported table, with a
  1,000-sample package cross-check. Record which path shipped.

**Acceptance criteria:** AC2, AC3.
**Risks:**
- 331k rows as an AILANG list is O(n) with quadratic traps. *Mitigation:*
  stream with a `readLine` loop, chunked, never building the whole list.
- The FS/IO effects fall back to the interpreter. *Expected:* the report
  measures it.

### M1.3: Star rendering v2
**Goal:** 331k stars at 60 fps, with physical brightness.
**Estimated:** 250 + 150 = 400 LOC · **Session:** 3 · **Depends on:** M1.2

**Tasks**
- Binary tier loader (`FileAccess.get_buffer` → `PackedFloat32Array`),
  checking the header version and checksum.
- MultiMesh with 331k instances. Custom data carries T_eff, E_v at Sol and
  flags.
- Rebasing: measure the CPU update. If it takes more than 4 ms, move direction
  and 1/r² into the vertex shader (ship position as a uniform).
- `make bench`: a scripted 30 s flight at 2560×1440, logging p50/p99 frame
  times.
- Update the starfield-shader test to check brightness scaling with E_v.

**Acceptance criteria:** AC7 (stars only, at this point).
**Risk:** the CPU rebasing cost. *Mitigation:* plan B is already designed.

### M1.4a: Background data spike (timeboxed) → ⏸ USER DECISION
**Goal:** choose the diffuse Milky Way source.
**Estimated:** about 150 LOC of throwaway tooling · **Session:** 3 (second half)

**Tasks**
- **Option A:** download `noirlab2430b` to `data/raw`, detect and mask point
  sources, and inpaint with a median filter.
- **Option B:** a synthetic diffuse map from the GCNS-independent Gaia density
  plus a dust map. Find the source during the spike, with URLs checked.
- Comparison renders at 0, 0.9 and 0.99c, plus a residual-artefact crop, in
  `design_docs/planned/r1/m1-4a-background-options.md`.
- **STOP:** the user picks A or B, recorded in the design doc.

### M1.4b/c: Spectral sky model and sky shader
**Goal:** a background with correct aberration and Doppler colour and
brightness.
**Estimated:** 400 + 200 = 600 LOC · **Session:** 4 · **Depends on:** M1.4a
decision, M1.1

**Tasks**
- `tools/sky_model.py`: fit a colour temperature T_c per texel, store
  (log T_c, log L_v) in a float EXR, and a residual map with its median
  reported.
- `sky/background.gdshader` (`shader_type sky`), per pixel:
  1. deaberrate the view direction;
  2. sample the texture;
  3. compute D with `dopplerApparent`;
  4. radiance = L_v × `surfaceBrightnessRatio`;
  5. colour = rgb(D·T_c).
- CPU reference in `physics/relativity.gd` for the background sample direction.
- Golden cases:
  - a synthetic background with a single-texel marker must land within 1 px of
    `deaberrate`'s prediction (AC5, background part);
  - a colour golden with the linear tonemapper (AC6).

**Acceptance criteria:** AC5, AC6.
**Risk:** the median fit residual exceeds 0.02 Δxy. *Mitigation:* the design
doc's two-component escalation, flagged to the user.

### M1.5: Photometric exposure, bench and report
**Goal:** a physically anchored exposure, then close M1.
**Estimated:** 150 + 100 = 250 LOC · **Session:** 5 · **Depends on:** M1.3,
M1.4

**Tasks**
- Scene units: stars in lux, background in cd/m² (calibrated at
  22 mag/arcsec² → 1.7×10⁻⁴ cd/m²).
- EV exposure and log-average auto exposure with player clamp and bias.
  "Readability" settings are labelled and off by default.
- Naked-eye limiting magnitude test (AC8: 6.0–6.8).
- `make bench` with the large tier plus the background (AC7).
- `make capture` reference renders at 5 speeds × 3 views (AC9), **human
  review**.
- `design_docs/implemented/r1/m1-report.md`: renders, bench numbers, pipeline
  VM measurements and upstream reports. Move the design doc to
  `implemented/`, and add CHANGELOG entries.

**Acceptance criteria:** AC7, AC8, AC9, AC10.

## Schedule

| Session | Work |
|---|---|
| 1 | **M1.0 review builds** (macOS export and release) · M1.1 package 0.2.0, published · M1.6 simulation and protocol |
| 2 | M1.2 pipeline and VM parity · M1.6 camera and golden tests |
| 3 | M1.3 rendering v2 and bench · M1.4a spike → **⏸ decision** |
| 4 | M1.4b/c sky model and shader and golden tests |
| 5 | M1.5 exposure, bench, renders, report → **sprint-evaluator** (a different model from the executor) |

## Success metrics

- AC1–AC10 all met; the evaluator scores at least 70 out of 100, with no
  hard fails.
- `make test` is green in CI after every milestone. `make golden` output and
  renders are attached to the sprint JSON notes.
- **Test counts:**
  - package: 40 → about 60;
  - `test_physics.gd`: 27 → about 45;
  - golden: 9 → about 150 cases (generated);
  - protocol codecs: new, about 12.
- **Docs to update:**
  - `CLAUDE.md` (new make targets);
  - `README.md` (layout, tiers);
  - the `starmap-manager` skill (sources);
  - the design repo's roadmap status;
  - the package's AGENT.md.
- **Upstream:** every AILANG issue hit is reported, and the count goes in the
  report.

## Dependencies

- Network access to Rochester (Mamajek), CDS VizieR and NOIRLab. All checked
  2026-09-27.
- Publishing `sunholo/relativity@0.2.0` is outward-facing and attended.
- `make golden`, `make bench` and `make capture` need the Studio's GPU window.

## Open questions

1. **(M1.4a) Background source, option A or B.** Decided at the pause.
2. **Tier data in git:** commit quick (about 150 KB) and medium (about 1.2 MB)
   binaries, and build large (about 8 MB) locally and in the bench? Proposal:
   yes. CI uses medium.
3. **White dwarfs:** an approximate blackbody for M1 (proposal), or a Gaia
   passband model now?
4. **Default exposure:** dark-adapted naked eye (proposal) or camera-like?

## Notes

- **Estimates use half the measured velocity on purpose.** If the first two
  sessions come in fast, sessions 4 and 5 may merge.
- The sprint executor updates only the `passes`, `started`, `completed` and
  `notes` fields in the JSON. The evaluator writes to
  `.ailang/state/evaluations/`.
