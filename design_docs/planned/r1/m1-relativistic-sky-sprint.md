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

### M1.6a: Simulation, protocol v1.1 and bridge (runs in parallel with M1.2)
**Goal:** support deterministic turns at rest, off-axis position and a bounded
v1.1 bridge while preserving the default-heading image and v1.0 messages.
**Estimated:** 250 implementation + 200 tests = 450 LOC · **Session:** 1 ·
**Depends on:** —

**Tasks (test-first)**
- **First, rerun design-doc probe V17** with the pinned v0.45.0 binary:
  `std/json.get` on a nested `heading` object, then `getNumber` on `x`, on both
  VM and interpreter. CI and the exported build pin v0.45.0; rig `PATH`
  resolves `ailang` v0.47, which rejects the lockfile version line in
  `make deps`. Every gate below therefore passes
  `AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`.
  If V17 fails, resolve the pinned-runtime compatibility before implementation.
- `sim/core.ail`: first add named `checkTurnAtRest`, `checkMovingTurnRejected`,
  `checkPositionAfterTurn` and `checkScriptedOffAxis` tests. They kill,
  respectively, a missing φ snap, a turn accepted at β ≥ 1e-9, use of
  `heading * motion.x` without `origin`/`x0`, and a one-leg or non-strict
  implementation. Keep `Motion`, `step(s, thrust, dtau)` and `scripted(n)`
  unchanged; extend `Ship` with `heading`, `origin`, `x0`; add pure
  `turn(s, h) -> TurnResult`. On accepted turn, set `origin := pos`,
  `x0 := motion.x`, and `motion.phi := 0` before applying the step's thrust.
  Compute `pos = origin + heading * (motion.x - x0)` in float64. Add the
  `scriptedOffAxis(n)` strict entry: +X burn/decelerate, turn to +Y at rest,
  repeat, and return `‖pos‖ = sqrt(2) * 2 * (cosh(g*n*0.01)-1)/g` within 1e-9.
- `sim/ship.ail`: first add named `checkHelloProto11`,
  `checkV10StepUnchanged`, `checkBadJson`, `checkBadCmd`, `checkBadStep`,
  `checkBadHeading`, `checkMoving` and `checkRejectedStateUnchanged` tests
  (in `sim/protocol_test.ail` or the existing sim test harness). They kill a
  missing handshake, broken old fields/defaults, loop termination on malformed
  input, wrong reject reason or validation order, and state mutation on reject.
  In AILANG `test` blocks, call named `check…()` functions: whole-number
  float literals are misread as ints there. Reuse `std/json` `decode`, `get`,
  `getNumber`, `getString` and encoding helpers; add no hand-written codec.
  `hello` returns `proto: "1.1"` plus state. Keep v1.0 state fields and
  `step` without `heading`; add `heading`, `pos`, `status`. Reject
  `bad_json`, `bad_cmd`, `bad_step`, `bad_heading`, `moving` in design-doc
  order, with unchanged tick, motion, heading and position; EOF and `quit`
  still stop the loop. Check finite inputs, unit heading within 1e-9, and
  accept an unchanged heading while moving.
- `bridge/sim_bridge.gd`: first add `test_v11_hello_and_round_trip`,
  `test_startup_timeout`, `test_step_timeout`,
  `test_truncated_line_timeout` and `test_forced_child_cleanup` as new
  functions in `tests/test_sim_bridge.gd`. They kill acceptance of old proto,
  loss of float64 heading/position precision, an unbounded silent or partial
  response, and an orphaned shutdown-ignoring child. Leave the existing v1.0
  closed-form checks unmodified. Send `hello` on start and optional heading on
  step; require proto ≥ 1.1. Use monotonic deadlines: 5 s from launch for
  hello, 2 s from send for step. On timeout stop advancement, expose
  `startup_timeout` or `step_timeout`, terminate the child, allow at most 1 s
  for graceful exit, then force termination. Never retry or substitute state.
- `main.gd`: use state `heading` and `pos` for velocity and ship position;
  preserve the default-heading view and all current camera/HUD behavior.
  `tests/test_physics.gd`: add `test_off_axis_cpu_spec_values` for spec §2
  velocity directions ±X, ±Y, (1,1,−1)/√3; this kills a hard-coded −Z axis.
  Defer rolled-camera checks to M1.6b, when the camera exists.
- `Makefile`: add `parity-offaxis` to `make test`, with a fixed NDJSON script
  covering hello, turns, burns and every rejection; compare VM and
  interpreter output byte for byte with `cmp`. Preserve the existing v1.0
  `parity` input. Extend `strict` to compare `scriptedOffAxis` on strict VM,
  interpreter and the closed form. These kill VM/interpreter drift and a
  strict-bytecode fallback.

**Acceptance criteria:** AC4 CPU off-axis part, AC10, AC12. Exact gates:
`make sim AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang AILANG_BIN=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
`make physics AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
`make parity AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
`make parity-offaxis AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
`make strict AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
`make test AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang AILANG_BIN=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
and CI `make test` with pinned v0.45.0.
No default-heading pixels change, so this milestone can merge without human
render review.
**Risks:** v0.45.0 nested `std/json.get` may differ from V17's v0.47 probe;
blocking pipe reads may defeat a deadline; float32 heading normalization may
fail the 1e-9 norm tolerance. *Mitigation:* probe first, use a pollable
non-blocking read and process cleanup, and normalize heading in float64
scalars.

### M1.6b: Free-look camera, HUD and off-axis golden
**Goal:** let the player look independently of ship velocity and verify the
off-axis visual physics before merging it.
**Estimated:** 100 implementation + 50 tests = 150 LOC · **Session:** 2 ·
**Depends on:** M1.6a

**Tasks (test-first)**
- `tests/test_physics.gd`: add `test_rolled_camera_cpu_spec_values` using the
  actual camera object; it kills treating camera roll as a velocity rotation
  or projecting against an unrolled basis. Complete AC4.
- `main.gd`: add yaw, pitch and roll free-look control independent of heading;
  show the view-to-velocity angle in the HUD; feed the starfield velocity
  direction from the sim state at every update. Add a focused HUD/view-angle
  assertion in the Godot test harness (`test_view_velocity_angle`) to kill
  use of a fixed heading or a stale camera forward vector.
- `main.gd` golden path and `Makefile` `golden`: generate 12 star directions
  × 4 speeds × 3 camera orientations, including roll. Compare GPU positions
  against CPU projection through the same camera within 0.75 px
  (`test_off_axis_star_golden`); this kills missing aberration and camera
  transform errors. Produce reference renders, open and inspect them, and
  obtain human render review before any SR visual merge.

**Acceptance criteria:** AC4 complete and AC5 star part. Exact gates:
`make physics AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
`make test AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang AILANG_BIN=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
`make golden AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
`make capture AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang AILANG_BIN=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`;
CI `make test` with pinned v0.45.0, plus human-reviewed reference renders
before merge.
**Risks:** Godot float32 camera transforms and roll may shift subpixel
positions. *Mitigation:* CPU and GPU project through the same camera object;
inspect reference renders before merging.

### M1.2: Catalogue pipeline v2 (the AILANG VM stress test)
**Goal:** quick/medium/large tiers with physics done in AILANG, with measured
VM behaviour.
**Estimated:** 250 (M1.2a) + 250 (M1.2b) + 180 (M1.2c) ≈ 680 LOC ·
**Session:** 2 (M1.2a, M1.2b) and 3 (M1.2c, before M1.2d and M1.3) ·
**Depends on:** M1.1

M1.2 is split into three sub-milestones in dependency order. The old single
500 LOC row exceeded the ~250 LOC cap per executor task, and the seams are
real: downloads and the parser must land before the AILANG transform can be
tested against real fixtures, and stats plus the tier commits gate M1.3.

**Tier definitions** (from the design doc, unchanged):
- quick = CNS5 (5,909)
- medium = the 50,000 **nearest** GCNS members by distance, white dwarfs
  included and flagged
- large = full GCNS (331,312)

**Missing photometry** (quorum rule, verbatim): a row with null BP−RP or G is
never defaulted. It carries flags bit `MISSING_PHOT` with teff = 0 and
v = +99; the medium-tier 50,000-nearest rule extends past such rows to the
next star with complete photometry; `tools/catalogue_stats.py` reports the
per-tier excluded count. Working reading: quick and large write the row
flagged; medium writes only complete rows, and the rows it skipped are the
excluded count (header field `count_excluded`).

**Binary record** (unchanged from the design doc): 24 B, little-endian
float32: `x, y, z, teff, v, flags`. Positions are galactic ly; teff in K;
v is Johnson V at Sol (+99 sentinel). `flags` bits: 1 = `WD` (GCNS
`WDprob > 0.5`; D-4), 2 = `MISSING_PHOT`, 4 = `APPROX_TEFF` (the D-4
blackbody fit), 8 = `BRIGHT` (HIP2 source, M1.2d). Each `stars_<tier>.bin`
ships a sidecar `stars_<tier>.json` header: `tier, count, count_excluded,
source, format_version (1), record_bytes (24), fields, ailang, package,
producer, sha256 {raw inputs, csv, bin}`. The quick tier also keeps a
human-readable `data/starmap/stars.json` (design doc: "JSON stays for CNS5
only"), written by the same AILANG run.

**Runtime pin (measured 2026-09-28):** every make invocation in M1.2 passes
`AILANG=$PWD/runtime/bin/ailang` (v0.45.0, the CI pin). The PATH `ailang` is
v0.47 and `make deps` fails with it: it rewrites the lockfile version line.

**Known AILANG VM bugs (open upstream, sunholo-data/ailang#1354 and #1355).
Consequences for catalogue.ail:**
- `--strict-bytecode` `GET_FIELD` reads the wrong slot when two record types
  share a field name at different positions. So `catalogue.ail` declares **no
  custom record types**: rows are positional `[float]` lists and the header
  is built with `std/json` `jo`/`kv`/`jnum`. Because strictness is ungated by
  bug 1354 and FS effects bridge anyway, `make catalogue-parity` replaces the
  old plan's strict-bytecode gate: VM vs interpreter, `cmp`, 5 VM runs.
- `--bytecode` is nondeterministic on some programs (6–9 of 30 runs diverged
  from the interpreter in the M1.6a probe). Any divergence in the parity
  gate is an upstream report plus the fallback trigger below; never work
  around it silently.

**Probes the planner ran on the pinned v0.45.0 binary (2026-09-28):**
- `ailang run` on a file under `sim/tools/` works by path with
  `--package-dir sim --entry main`, no `[exports]` change needed.
- Use a block-bodied `export func main() { ... }`: an expression-bodied
  effectful main prints nothing and exits 0 (same anomaly the V17 row
  recorded). If it reproduces, report upstream; do not work around.
- FS builtins need `FS` in `sim/ailang.toml` `[effects].max` (IMP010
  otherwise) and `--caps IO,FS` (comma-separated, no spaces).
- Camel-case import names: `std/bytes` `fromInts`, `concatList`;
  `std/fs` `readFile`, `writeFileBytes`; `std/string` `split`,
  `stringToFloat`, `stringToInt`.
- `runtime/bin/ailang test --package sim` discovers `*_test.ail` anywhere in
  the package. In test blocks call named `check…()` functions (whole-number
  float literals are misread as ints there).
- std/fs has **no streaming/line API**: `readFile` loads the whole file as
  one string (old plan's chunked `readLine` assumption was wrong; gcns.csv is
  about 17–25 MB). The M1.2b probe measures whether this is fast enough; the
  fallback trigger covers it if not.

#### M1.2a: Data acquisition and parse (Python, no physics)
**Goal:** real CNS5 and GCNS bytes under gitignored `data/raw/`, parse-only
Python into a compact CSV, unit tests on real-byte fixtures.
**Estimated:** ~250 LOC · **Session:** 2 · **Depends on:** M1.1

**Files:**
- `.claude/skills/starmap-manager/scripts/download_stars.sh` (edited)
- `tools/extract.py` (new, ~130 LOC, stdlib only)
- `tools/test_extract.py` (new, ~90 LOC, `unittest`; no pytest on this
  machine)
- `tools/fixtures/` (new, committed: real bytes cut from `data/raw`, a few KB)

**Tasks (in order)**
1. **Evidence rows first (quorum reviewer kimi, round 2).** Fetch
   `curl -s https://cdsarc.cds.unistra.fr/ftp/J/A+A/670/A19/ReadMe` and
   `.../J/A+A/649/A6/ReadMe`; record in the sprint JSON notes: HTTP status,
   byte size, row counts, and the column layout rows for BP/RP/G and the WD
   probability. `curl -sI` the legacy Gaia Sky URL
   `https://gaia.ari.uni-heidelberg.de/gaiasky/files/catalogs/dr3/cns5-dr3.vot.gz`
   and record the status. Planner-verified values (2026-09-28): A19 ReadMe
   200 / 10,530 B / `cns5.dat Lrecl 761 Records 5909`; A6 ReadMe 200 /
   39,878 B / `table1c.dat Lrecl 760 Records 331312` plus table1r, progwd,
   table3, maglim, missing, hyacomb, distpdf; legacy URL 404. **If any of
   these differ at execution time, stop and re-plan before writing parser
   code.**
2. **download_stars.sh.** quick: fetch
   `https://cdsarc.cds.unistra.fr/ftp/J/A+A/670/A19/cns5.dat` to
   `data/raw/cns5.dat`. medium and large: keep the existing
   `J/A+A/649/A6/table1c.dat.gz` fetch, gunzip to `data/raw/table1c.dat`.
   medium no longer says "filter locally" (selection moved to
   `catalogue.ail`). Every tier also fetches its ReadMe. Every download logs
   byte size and `shasum -a 256` to stdout and appends to
   `data/raw/SHA256SUMS`. Delete the dead Gaia Sky URL and the V/70A votable
   fallback entirely. `data/raw/` is already in `.gitignore`; keep it that
   way.
3. **tools/extract.py.** CLI: `python3 tools/extract.py cns5|gcns`, writing
   `data/raw/cns5.csv` and `data/raw/gcns.csv` with header
   `id,x,y,z,G,BPRP,wd`. All slices below are 0-based half-open Python
   slices, from the verified ReadMe byte columns:
   - `parse_cns5`: id = `line[27:46]` (GaiaDR3; if blank, `CNS5:` +
     `line[0:4]`), ra = `line[54:74]` deg, dec = `line[75:98]` deg, plx =
     `line[129:148]` mas, G = `line[361:371]`, BP = `line[394:404]`, RP =
     `line[427:437]`, epoch = `line[99:108]`. `wd = 0` always (CNS5 carries
     no WD probability column).
   - `parse_gcns`: id = `line[2:21]`, ra = `line[22:36]`, dec =
     `line[45:59]`, plx = `line[68:77]`, G = `line[122:130]`, BP =
     `line[141:149]`, RP = `line[160:168]`, WDprob = `line[245:250]`,
     `wd = 1` iff WDprob parses and is `> 0.5` else 0. (For a test cross-check
     only, the catalogue's own galactic positions are `x50 = line[303:315]`,
     `y50 = line[342:354]`, `z50 = line[381:393]` pc.)
   - `icrs_to_galactic(ra_deg, dec_deg)`: unit vector `(cosδ·cosα,
     cosδ·sinα, sinδ)` times the IAU ICRS→galactic matrix
     `[[−0.0548755604, −0.8734370902, −0.4838350155], [+0.4941094279,
     −0.4448296300, +0.7469822445], [−0.8676661490, −0.1980763734,
     +0.4559837762]]`. Distance pc = 1000/plx (plx null or ≤ 0 skips the row
     and increments a skip counter printed at the end); ly = pc ×
     3.261563777. **No proper-motion propagation** (positions are used at
     catalogue epoch; deep-time motion is M2). No physics: BPRP = BP − RP is
     the only arithmetic beyond coordinates; null G or BP or RP → empty CSV
     field (never a default).
4. **Fixtures.** Cut real bytes, never hand-typed. Commands (record them in
   the `test_extract.py` docstring): `sed -n '1,20p' data/raw/cns5.dat >
   tools/fixtures/cns5_head.dat`; locate α Cen A as GJ 559 with component
   suffix A (`grep -n 559 data/raw/cns5.dat | head` then eyeball) and cut
   that exact line; `sed -n '1,20p' data/raw/table1c.dat >
   tools/fixtures/gcns_head.dat`; a WD row via
   `awk 'substr($0,246,5)+0 > 0.5' data/raw/table1c.dat | head -1`;
   a missing-photometry row via `awk 'substr($0,123,8) ~ /^ *$/'
   data/raw/table1c.dat | head -1`; a WDprob-boundary row if one parses as
   exactly 0.5.
5. **Tests.** See the table. `python3 tools/test_extract.py` with
   `unittest.main()` at the bottom.

**Tests and the mutation each kills**
| Test | Mutation it kills |
|---|---|
| `test_alpha_cen_distance`: fixture → 4.370 ± 0.02 ly | sign flip in any rotation-matrix row; pc→ly factor dropped |
| `test_alpha_cen_direction`: galactic l ≈ 315.7°, b ≈ −0.68° (from fixture) within 0.5° | x↔y axis permutation; degrees-vs-radians mix-up |
| `test_gcns_xyz_crosscheck`: our x,y,z vs the row's own `x50,y50,z50` (pc × 3.261563777) within 5% | using −A (galactocentric sign error); pc/ly unit slip (×1000 off) |
| `test_gcns_wd_flag`: WDprob 0.99 row → wd=1; 0.50 row → wd=0 | `>` read as `>=`; WDprob slice off by one byte |
| `test_missing_phot_cns5`: blank BP/RP fixture → empty BPRP field | any default (0.0, or the old skill's 10.0/"K" behaviour) |
| `test_bprp_needs_both`: G present, BP blank → BPRP empty even if RP parses | checking only one side of the pair |
| `test_plx_skip_count`: blank/≤0 plx row skipped and counted | silent division by zero or negative distances |
| `test_csv_schema`: header exactly `id,x,y,z,G,BPRP,wd`, 7 fields per row | column reorder; id value parsed to float and re-formatted |

**Acceptance criteria (one command each):**
- `python3 tools/extract.py cns5 && python3 tools/extract.py gcns` exits 0
  and reports 5,909 and 331,312 parsed rows (minus printed skip counts).
- `python3 tools/test_extract.py` passes.
- `test -s data/raw/SHA256SUMS && [ "$(wc -l < data/raw/SHA256SUMS)" -ge 4 ]`
  (cns5.dat, A19 ReadMe, table1c.dat.gz, A6 ReadMe after quick+medium).
- `grep -rn gaia.ari.uni-heidelberg .claude/skills/starmap-manager/scripts
  || true` prints nothing (control: `grep -c cdsarc
  .claude/skills/starmap-manager/scripts/download_stars.sh` > 0).

#### M1.2b: AILANG catalogue preflight, then bounded production tasks
**Iteration-4 scope correction (2026-09-30, baseline `06311aa`):** the
approved catalogue outcome is unchanged. Execute the prerequisite preflight
below first; do not attempt the old ~250 LOC full pipeline in one task.
The repo pins AILANG **v0.47.2**. Historical v0.45.0 warnings in M1.2 above
are historical evidence, not current constraints: #1354/#1355 are fixed
and independently checked in iteration 3. Do not forbid record types or
assume lack of arrays from those old reports. Reproduce any new failure.

**M1.2b-preflight (routable):** CSV parsing and existing package main-sequence
photometry workload; no production tier or new physics. ~200 LOC total
(~100 AILANG, ~60 tests, ~40 runner/Makefile/config), hard cap **250 changed
code/test LOC**. Depends on completed M1.2a and M1.1. One executor task,
then evaluation by a different agent. `passes` for M1.2b remains null.

**Files:** `sim/tools/catalogue_probe.ail`,
`sim/tools/catalogue_probe_test.ail`, `tools/catalogue_probe.py`,
`sim/ailang.toml` (FS capability), `Makefile` (catalogue-probe target).
Probe output lives under `.godot/tmp/catalogue-probe/`, never
`data/starmap/`. Reuse committed real-byte parser fixtures through
`tools/extract.py`; use available real `data/raw/gcns.csv` for 5,000 rows,
or acquire it via M1.2a's approved download/parser path. Missing real data
is an explicit unmet performance gate, never synthetic timing evidence.

**Tasks:**
1. Verify runtime version and package lock (0.2.0). Parse exact
   `id,x,y,z,G,BPRP,wd` CSV schema. Fail malformed fields; preserve IDs as
   strings. Traverse rows once, avoiding repeated linked-list indexing.
2. Run `teffFromBpRp` and `vFromG` only for complete non-WD rows.
   Count WD and missing-photometry rows separately, do not fit or default
   them. Emit deterministic per-row diagnostic results plus row counters
   so output depends on both package calls and every eligible row.
3. Runner prepares fixture and real 5k input, runs interpreter once and VM
   five times, compares complete outputs with `cmp` semantics, records
   sha256, counts, wall times, peak RSS if available, input provenance,
   runtime and lock versions. Use bounded subprocess timeouts (60 s per
   run), retain stderr and label timeouts. Record medium x10 and large
   x66.2624 extrapolations as estimates; these exclude WD, sort and binary
   writing, and cannot certify final medium performance.
4. Preserve simulation gates. Write evidence and recommend the next bounded
   task; no fallback implementation and no package-cache regex extraction.

**Acceptance commands (new commands are implemented by executor):**
- `python3 tools/test_extract.py` remains 15 tests green (planner baseline).
- `runtime/bin/ailang check --package sim` and
  `runtime/bin/ailang test --package sim` pass including probe tests.
- `make catalogue-probe AILANG=$PWD/runtime/bin/ailang` exits zero only on
  fixture success, real 5k measurement and 5/5 exact parity; writes a report
  in `.godot/tmp/catalogue-probe/report.json`. Timeout/parity failure exits
  nonzero with preserved evidence, then parks the performance gate.
- `make test AILANG=$PWD/runtime/bin/ailang AILANG_BIN=$PWD/runtime/bin/ailang`
  remains green. Executor/evaluator measure actual diff against 250 cap.

**Test / mutation mapping:** schema check rejects a reordered header;
package anchor G2V BP-RP 0.823 / G 0 -> Teff 5770 and V 0.165 within
1e-6 rejects bypassed package calls; blank G and BP-RP cases reject defaults;
WD-complete case rejects main-sequence application to WD; interleaved rows
and exact diagnostic count reject dropped/duplicated rows; a changed VM
output rejects permissive parity. Fixture counters are asserted explicitly,
not merely VM/interpreter agreement.

**Registry reuse (verified 2026-09-30):** `pkg search photometry` and
`pkg search blackbody`, then `pkg info` / `pkg docs sunholo/relativity`,
return latest 0.2.0 with main-sequence photometry and Planck, no WD fit.
Preflight: **depend** on locked 0.2.0. WD production prerequisite:
**contribute** to sunholo/relativity. No new local physics package.

**Remaining dependency split (separate <=250 LOC tasks, replanned after
preflight evidence):** (1) package-first D-4 approximate WD colour/temperature
transform with source-defined band/zero-point convention, independent
reference tests, CHANGELOG, release kind, no-gate quality, publish then pin;
(2) pure CSV/tier transform plus selection/missing/WD tests;
(3) float32 binary writer plus IEEE-754 boundary tests and runner/sidecars;
(4) complete-tier parity/performance integration before M1.2c. None is
silently marked complete by a successful preflight.

**Encoder correction for later writer:** use fractional mantissa
`m = roundTiesToEven((abs(x)/2^e - 1)*2^23)`; carry at `m == 2^23`
sets `m=0,e=e+1`; bits are sign*2^31+(e+127)*2^23+m. The old formula
mixed fractional and full significands. Handle signed zero, subnormals,
finite/range rejection and exponent boundaries explicitly: coordinate
components can be arbitrarily close to zero even when distance is normal.
Use Python `struct.pack('<f', x)` as an independent byte oracle including
half-ULP ties. No custom f32 implementation is authorized in preflight.

**Human gates:** standing authorization covers this scope-preserving probe
and the existing D-4 approximation. No new human decision is needed for
preflight. Any proposed replacement WD passband model, threshold change,
Python production fallback or scope growth is parked for review. Publishing
must follow the package-first release gates and standing mission grant;
visual changes still require human render review. No git writes/push by
planner; executor remains separate from evaluator.

**Production tests retained (F4 documentation repair, not implemented by preflight):**

| Test | Required case and mutation killed |
|---|---|
| `checkF32LEVectors` | 1.0 -> [0,0,128,63]; -2.5 -> [0,0,32,192]; 99.0 -> [0,0,198,66]; zero -> all zeros. Wrong endianness, bias or sign fails. |
| `checkF32LECarry` | Fractional mantissa rounds to 2^23: reset to zero and carry exponent (corrected old 2^24 premise). Require signed-zero, subnormal and half-ULP oracle cases too. |
| `checkMediumSelection` | Five-row input with missing photometry interleaved; take two nearest complete rows, excluded=2. File-order or selection-before-sort fails. |
| `checkMissingPhotEncoding` | Missing G or BP-RP -> Teff 0.0, V +99, flag bit 2. Silent package clamp/default fails. |
| `checkWDRow` | WD with BP-RP 0.30 -> package-approved approximate Teff in [4000,60000], flags bits 1 and 4. Main-sequence transform or flag loss fails. |

**Evaluator follow-up for later bounded production tasks (F1–F3/F5):** pin WD+missing overlap independent counts, partial blanks, blank ID, y/z and wrong field count, exact row membership/order and multiple independently derived numerical diagnostics. The first 5k rows contain no WD+missing overlap, so real-data parity cannot pin it. Medium interpreter parity is estimated >60s; design a bounded integration measurement rather than silently raising the preflight timeout. These are pending obligations, not completed tests.

**Original production acceptance retained unchanged below; these are later full M1.2b gates, not preflight gates.**

**Acceptance criteria (one command each):**
- `make catalogue TIER=quick AILANG=$PWD/runtime/bin/ailang` exits 0;
  `data/starmap/stars_quick.bin` is 5,909 × 24 = 141,816 B plus sidecars.
- `make catalogue TIER=medium AILANG=$PWD/runtime/bin/ailang` exits 0;
  medium bin is exactly 50,000 records (1,200,000 B); header
  `count_excluded` > 0 is printed (record the number in notes).
- `make catalogue TIER=large AILANG=$PWD/runtime/bin/ailang` exits 0 **or**
  the fallback trigger fired and `tools/catalogue_fallback.py` produced it;
  either way the notes name the shipped path and the measured times.
- `make catalogue-parity AILANG=$PWD/runtime/bin/ailang` prints 5/5 VM runs
  identical to the interpreter plus the six wall times.
- `runtime/bin/ailang test --package sim` passes, including the five rows
  above.

Full-medium >60s fallback threshold is retained for the complete pipeline. A fallback is a subsequent bounded task and must reuse package physics for WD too. The WD package designer resolves normalization, weighting, quadrature and tolerances under existing D-4 approximation and publish grant; technical calibration alone does not create a human question.

#### M1.2c: Stats, cleanup and tier commits
**Goal:** AC3's machine check, the old pipeline removed and docs updated, and
quick+medium in git (D-3).
**Estimated:** ~180 LOC · **Session:** 3 · **Depends on:** M1.2b

**Files:**
- `tools/catalogue_stats.py` (new, ~100 LOC, stdlib only; `struct` for the
  24 B records)
- `tools/test_catalogue_stats.py` (new, ~50 LOC, builds a 2-record
  in-memory bin with `struct.pack`; kills stride/endian errors)
- `.claude/skills/starmap-manager/scripts/status.sh` (edited: reads the
  `stars_<tier>.json` sidecar headers and quick's `stars.json`)
- `.claude/skills/starmap-manager/SKILL.md` (edited: tier table per the
  definitions above; sources = VizieR A19 + A6; the G/K/M-filter text
  removed; quick start = `download_stars.sh` + `make catalogue TIER=…`)
- `.claude/skills/starmap-manager/scripts/process_stars.sh` (**removed**,
  −444 lines: superseded by `tools/extract.py` + `sim/tools/catalogue.ail`)
- `.gitignore` (add `data/starmap/stars_large.bin` and its sidecar; D-3:
  large is built locally and never committed)
- `Makefile` (adds `catalogue-verify`)

**Tasks (in order)**
1. Write `catalogue_stats.py` first, test-first with
   `test_catalogue_stats.py`: reads `stars_<tier>.bin` + sidecar. Reports
   per tier: count; M-dwarf share among complete rows (`teff < 3900 K`;
   Mamajek M0V ≈ 3,850 K — boundary stated in a comment); excluded count
   (medium: from the header, re-verified by walking `gcns.csv` up to the
   tier's max distance); **zero defaulted-photometry rows check**: for every
   record, `(teff == 0 and v == 99) ⟺ MISSING_PHOT bit set` — any violation
   exits nonzero (AC2's clause). `--tier <name>` exits 0 iff that tier's
   checks pass.
2. Rebuild all three tiers; record the medium M-dwarf share in the sprint
   notes (AC3 needs ≥ 60%; the 50,000-nearest volume definition is what
   makes this number real).
3. Remove `process_stars.sh`; apply the SKILL.md and status.sh edits;
   status.sh must still describe `stars.json` plus the new binaries.
4. `.gitignore` edit; then `git add` quick + medium binaries, sidecars and
   the rebuilt `stars.json` (~1.4 MB total; D-3). Large stays local.
   The controller commits; the executor stages only.
5. `make catalogue-verify`: rebuild quick and medium into `.godot/tmp/verify/`
   (parameterise the output paths through catalogue.ail's args) and `cmp`
   against the committed files. Byte-identical rebuild is the determinism
   gate (CLAUDE.md rule 6).

**Acceptance criteria (one command each):**
- `tools/catalogue_stats.py --tier medium` prints the M-dwarf share ≥ 60%
  and exits 0 (AC3).
- `tools/catalogue_stats.py` prints every tier's excluded count and finds
  zero defaulted rows (AC2's clause); `python3 tools/test_catalogue_stats.py`
  passes.
- `make catalogue-verify AILANG=$PWD/runtime/bin/ailang` prints
  `quick identical`, `medium identical`.
- `test ! -f .claude/skills/starmap-manager/scripts/process_stars.sh &&
  ! grep -q process_stars .claude/skills/starmap-manager/SKILL.md
  .claude/skills/starmap-manager/scripts/status.sh` (control: after the
  edit, `grep -c catalogue .claude/skills/starmap-manager/SKILL.md` > 0).
- `git ls-files data/starmap` lists `stars.json`, `stars_quick.bin`,
  `stars_medium.bin` + sidecars, and not `stars_large.bin`.

**Acceptance criteria (M1.2 overall):** AC2, AC3.
**Risks:**
- 331k rows through AILANG lists: real O(n)-with-quadratic-traps risk.
  *Mitigation:* probe first (task 1), prepend+reverse idiom, `sortBy`, the
  60 s fallback trigger.
- FS/IO effects bridge to the interpreter. *Expected and measured:* the
  parity gate prints all wall times; the report records them.
- A single-string `readFile` of a ~17–25 MB CSV may be slow or memory-heavy
  on v0.45.0. *Measured by the probe;* covered by the same trigger.

### M1.2d: Bright-star tier (ACCEPTED, D-5: "Yes I accept those stars", 2026-09-28)
**Goal:** the naked-eye sky beyond 100 pc (Rigel, Deneb, Betelgeuse) as real
catalogue stars: HIP2 V < 7, parallax > 0, not already in GCNS or CNS5.
**Estimated:** ~300 LOC, split in two halves — 0.3.0 package work (~120)
then the tier (~180) — because each half stays under the ~250 cap and the
package publish gate is a natural seam. **Session:** 3, after M1.2c ·
**Depends on:** M1.2c (and M1.1's published 0.2.0)

**Source (planner-verified 2026-09-28):** HIP2 new reduction, VizieR
`I/311` (ReadMe 200 / 10,375 B); `hip2.dat` has astrometry in **radians**
at epoch 1991.25 and B−V, but **no Johnson V** — V comes from
`I/239/hip_main.dat` (`Vmag` bytes 42–46; ReadMe 200 / 69,036 B), joined on
the HIP number. Slices (0-based half-open): hip2: HIP `line[0:6]`, RArad
`line[15:28]`, DErad `line[29:42]`, Plx `line[43:50]`, pmRA `line[51:59]`,
pmDE `line[60:68]`, B−V `line[152:158]`; hip_main: HIP `line[8:14]`,
Vmag `line[41:46]`.

**Size estimate:** ~13k HIP2 stars pass V < 7; the within-100-pc matched
subset drops out; expect roughly 5,000–10,000 bright-tier rows (AC11's
5,000–9,100 brighter-than-6.5 range bounds it), a bin under ~0.25 MB. The
D-3 ruling named only quick+medium for git; this plan commits
`stars_bright.bin` too (tiny, and M1.5's AC11 and CI need a stable input) —
flag at the next attended sync if disputed.

**M1.2d first half: `sunholo/relativity` 0.3.0 `teffFromBV` (package-first
rule).**
- **Package repo note (planner-measured):** `packages/relativity` exists on
  `origin/main` of sunholo-data/ailang-packages (files listed via the GitHub
  API today), but the local clone `~/dev/sunholo-data/ailang-packages` is
  stale — on a build branch at 2026-09-19 with no `packages/relativity`. Use
  an updated main checkout.
- Extend the package's `tools/mamajek_to_ail.py` generator (it produced
  `photometry_table.ail`) to also emit `bvNodes()` from the same table's B−V
  column; add `teffFromBV(bv)` next to `teffFromBpRp`, same interpolation
  and clamping. Same-table consistency (the design doc's rule).
- Tests first: fixed-table checks (G2V B−V 0.65 → 5770 K ± 5%; one K dwarf
  and one M dwarf from the table's own rows; endpoint clamping)
  plus known-star dwarfs: Sun, α Cen B, Barnard, Proxima within 5%. Note the
  limit in a comment: the dwarf B−V relation is approximate for the giants in
  this tier (design doc accepts this for M1).
- Gate (CLAUDE.md rule 3): tests, `CHANGELOG ## 0.3.0`, `[release] kind =
  "feature"`, `ailang pkg quality` with no gates, then publish (attended,
  standing permission per M1.1's gate note). Pin in the sim: bump
  `sim/ailang.toml` to `"0.3.0"` and relock with the pinned binary
  (`make deps AILANG=$PWD/runtime/bin/ailang`).

**M1.2d second half: bright extract, cross-match, tier binary.**
- `download_stars.sh` gains case `bright`: fetch
  `https://cdsarc.cds.unistra.fr/ftp/I/311/hip2.dat.gz` and
  `https://cdsarc.cds.unistra.fr/ftp/I/239/hip_main.dat.gz` with the M1.2a
  byte-size + sha256 logging.
- `tools/extract_bright.py` (new, ~120 LOC, stdlib only, parse and geometry
  only): join hip2 × hip_main on HIP; select `Vmag < 7` and `Plx > 0`;
  propagate RA/Dec linearly with the proper motions — α += pmRA·Δt/cosδ,
  δ += pmDE·Δt (pmRA carries cosδ, per both ReadMes) — to **2016.0 for the
  GCNS match** and to **each CNS5 row's own epoch column** for the CNS5
  match (nearby stars move arcminutes between 1991.25 and their epochs).
  Match = within 1″ **and** `|G − V| < 2.0` (a loose guard against wrong
  positional matches, not colour physics). Unmatched survivors →
  `data/raw/bright.csv` with header `id,x,y,z,V,BV,wd` (wd = 0; BV empty if
  blank). Same IAU matrix and ly conversion, reused from
  `tools/extract.py` by import. V-present-but-BV-null rows are kept with
  the quorum encoding (teff = 0, v = +99, `MISSING_PHOT`) and counted in
  the header; V-null rows cannot pass the V < 7 filter.
- `sim/tools/catalogue.ail`: add the bright path (`teff = teffFromBV(bv)`,
  `v = V` verbatim — the flux at Sol is catalogue V itself, unaffected by
  the parallax error that dominates past ~500 pc; state this in a comment).
  Same 24 B record, flags bit 8 (`BRIGHT`); sidecar header, source
  `I/311 + I/239`. `make catalogue TIER=bright` wired like the other tiers.
- `tools/bright_star_audit.py` (~100 LOC): the AC11 auditor. Unit-test it in
  M1.2d on synthetic render data; the full AC11 gate (`make capture &&
  tools/bright_star_audit.py renders/`) needs rendered pixels, i.e. the
  M1.3 loader, so it runs in M1.5. Record that deferral against AC11's
  check column when M1.5 lands.

**Files:** `.claude/skills/starmap-manager/scripts/download_stars.sh`,
`tools/extract_bright.py`, `tools/test_extract_bright.py` (unittest),
`tools/fixtures/hip2_*.dat` + `hip_main_*.dat` (real bytes, same cut rules),
`sim/tools/catalogue.ail` (+~40 LOC), `sim/tools/catalogue_test.ail` (+~30),
`tools/bright_star_audit.py`, `tools/test_bright_star_audit.py`,
package-repo: `tools/mamajek_to_ail.py`, `photometry_table.ail`,
`photometry.ail`, `photometry_test.ail`, `CHANGELOG.md`;
`sim/ailang.toml` + relocked `sim/ailang.lock`, `Makefile`.

**Tests and the mutation each kills**
| Test | Mutation it kills |
|---|---|
| package: `teffFromBV` table/known-star rows above | B−V column mis-sliced in the generator; BP−RP nodes reused by mistake |
| `test_vega_excluded`: HIP 91262 (25.4 ly, V 0.03) real-byte fixture is matched and absent from bright.csv | match radius too wide/narrow; magnitude guard dropped |
| `test_arcturus_pm_match`: HIP 69673 (36.7 ly, pm ≈ 2.3″/yr → ~57″ of motion to 2016.0) matches GCNS **only** with propagation | omitting proper-motion propagation entirely |
| `test_rigel_included`: HIP 24436 (~860 ly) survives, v = catalogue V, flags bit 8 | distance or V filters inverted; v recomputed from anything but V |
| `test_cns5_epoch_match`: a high-pm CNS5 fixture star matches at its per-row epoch | using 2016.0 for CNS5 (CNS5 epochs vary per row, 1991.25–2017.97) |
| `checkBrightRow` (AILANG): teff = teffFromBV(bv), v unchanged, flags bit 8; BV-null row → MISSING_PHOT sentinels | `vFromG` applied to bright rows (double colour correction); sentinel swap |

**Acceptance criteria (one command each):**
- `ailang pkg info sunholo/relativity` shows v0.3.0; `grep '"0.3.0"'
  sim/ailang.toml sim/ailang.lock` matches; `make test AILANG=$PWD/runtime/
  bin/ailang AILANG_BIN=$PWD/runtime/bin/ailang` green.
- `python3 tools/extract_bright.py` exits 0; bright.csv row count in
  [1000, 20000] (record the number; AC11's bound lands inside it).
- `python3 tools/test_extract_bright.py` passes (Vega, Arcturus, Rigel,
  CNS5-epoch rows).
- `make catalogue TIER=bright AILANG=$PWD/runtime/bin/ailang` && `python3
  -c "import os; assert os.path.getsize('data/starmap/stars_bright.bin') %
  24 == 0"`.
- `runtime/bin/ailang test --package sim` passes with the bright rows;
  `make catalogue-parity AILANG=$PWD/runtime/bin/ailang` still 5/5
  identical (regression: bright shares the encoder).
- `python3 tools/test_bright_star_audit.py` passes; the AC11 render gate
  itself is listed in M1.5's checks.

**Acceptance criteria:** AC11 (auditor landed here; render gate runs in
M1.5).
**Risks:** the B−V dwarf relation misfits bright giants (accepted for M1 by
the design); HIP2/hip_main join key drift (caught by the Vega row); the
0.3.0 publish is outward-facing — attended, standing permission.

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
| 1 | **M1.0 review builds** (macOS export and release) · M1.1 package 0.2.0, published · M1.6a simulation, protocol v1.1 and bridge |
| 2 | M1.2 pipeline and VM parity · M1.6b free-look camera, HUD and off-axis golden (human render review before visual merge) |
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

### Iteration-4 executor evidence: preflight only

- Executed only CSV + published normal photometry; full M1.2b `passes` remains null. Production WD fit/tier/sort/float32 writer are untouched. No physics cache/package edits or Python physics fallback.
- Test first: added real-byte fixture tests before module; `ailang test --package sim` failed (12 passed / 4 failed missing module), then green 19/19. Literal fixture is re-derived and byte-checked against existing parser by runner. Added published solar anchor and real normal-row numerical diagnostic.
- Commands: `CURL_MAX_TIME=120 bash .claude/skills/starmap-manager/scripts/download_stars.sh quick`, `CURL_MAX_TIME=240 bash .claude/skills/starmap-manager/scripts/download_stars.sh medium`, `python3 tools/extract.py gcns`: exit 0; GCNS parsed 331312, skipped 0. Download/input hashes in `.ailang/state/probe_M1.2b_iter4.json`.
- `runtime/bin/ailang check --package sim`: exit 0, 6 files pass. `runtime/bin/ailang test --package sim`: exit 0, 19/19 pass. `git diff --check`: exit 0.
- `make catalogue-probe AILANG=$PWD/runtime/bin/ailang`: exit 0; committed real-byte fixture plus real GCNS first 5000 rows, interpreter once / pure strict VM five times each. Complete bytes, source row order, missing/WD status and counts checked; fixture FS shell interpreter and ordinary bridged VM also equal pure output.
- Real 5k counts (input, eligible-normal, WD, missing): 5000,4580,324,96. WD and missing counters are independent and may overlap. VM mean 0.719015 s (0.700720–0.741791); interpreter 12.497095 s; VM RSS max 143458304 bytes. All real outputs SHA256 `7afd4c0920614a5916d9031ca9c725f2dd24938349cd50d6f79aa3f17a33287b`.
- Timing includes process start, args-file load and output; excludes FS shell read, WD fit, sort and binary writing. Medium x10 = 7.190150 s and large x66.2624 = 47.643657 s are estimates, not production gate measurements. No fallback trigger inferred.
- Strict entire FS shell cannot run: `std/fs.readFile` is evaluator-only with no strict interop bridge. Pure `std/list.reverse` also lacks strict support; replaced with linear foldl prepend. Strict proof invokes exported pure render via args-file; normal FS shell is exercised separately. Controller owns upstream reporting (reverse message `inbox_1790776183299_a05dc865`).
- Runner deletes stale report before launch and bounds each workload at 60s with process-group termination and partial stdout/stderr preservation. Version/lock package checks are exact. Every measured run retains stdout/stderr, their SHA256, provenance, wall time and RSS where available.
- Simulation verification: `make -f Makefile -f .godot/tmp/no-deps.mk test AILANG=$PWD/runtime/bin/ailang AILANG_BIN=$PWD/runtime/bin/ailang`: exit 0. This executor override reused controller-verified locked cache to avoid prohibited git checkout in existing deps recipe; all import/physics/sim/parity/offaxis/strict/tools-test targets ran. Controller runs canonical make test. Parser 15/15, sim 19/19, parity601 lines/offaxis17 lines.
- Actual changed code/tests: 218 physical added/modified lines (210 new file lines +4 Makefile +4 manifest); production187 <=200 and total218 <=250. Documentation/artifacts excluded from code cap. No commits/staging performed.
- Next bounded task is package WD specification/calibration/publication prerequisite, then production transform/writer/integration per approved plan. Independent evaluator must assess preflight. Full AC2 and M1.2b remain incomplete.
