# Sprint plan: R1-M1-SKY-2, the rest of the relativistic sky

**Status:** Approved by Mark 2026-10-02 (ledger D-19). In execution:
M1.6b executed (PR "M1.6b: camera with roll, HUD angle, off-axis golden (R-a)"),
awaiting checkpoint R-a before merge. M1.2b-T4 executed (PR "M1.2b-T4: all
tiers from real data, linear accumulators, 5-run parity") and awaiting
evaluation. If it passes, the parent `M1.2b_AILANG_CATALOGUE` closes.

## Summary

Finish M1 so bar clause 1 can be met. The work, in order:

1. The 331k-star catalogue lands as committed binary tiers, with a bright
   Hipparcos tier.
2. Every star is drawn as an instanced splat, in physical units, under a
   photometric exposure.
3. The camera can look anywhere, and the off-axis goldens prove it.
4. The galaxy map and the starfield move off the CNS3 `stars.json` onto the
   tiers.
5. The forward CMB glow (D-11) is rendered.
6. The M1 report closes the milestone with reference renders Mark has seen.

Mark chose this on 2026-10-02 ("Finish M1 + AI design").

**Design doc:** [m1-relativistic-sky.md](m1-relativistic-sky.md) (AC1–AC12).
**Parent sprint:** `R1-M1-SKY` ([plan](m1-relativistic-sky-sprint.md),
`.ailang/state/sprints/sprint_R1-M1-SKY.json`).
**Sprint ID:** `R1-M1-SKY-2` · **Progress file:**
`.ailang/state/sprints/sprint_R1-M1-SKY-2.json`.
**Duration:** 11 milestones in 7 waves. That is **~16–20 h of attended
execution (2 days)**, or **~4–6 days on the 6-hourly loop**, plus Mark's
review time at five checkpoints. Velocity is below.
**Risk level:** Medium-high. Data-source gaps were found while planning (F1
to F3). There are three Mark decisions on the critical path, one open PR to
depend on (#43), and GPU and perf gates that CI can't run.

### Why a new sprint ID rather than extending R1-M1-SKY

The executor contract only lets the executor change `passes`, `started`,
`completed` and `notes`. `R1-M1-SKY`'s remaining rows (`M1.2b`, `M1.2c`,
`M1.2d`, `M1.3`, `M1.5`, `M1.6b`) carry obsolete premises:
- the 250 LOC cap;
- the v0.45 workarounds;
- the Python fallback and Python stats/audit tools, which the Python policy
  (#34) now forbids;
- `teffFromBV` in 0.4.0;
- quick-tier `stars.json` written by T3.

Rewriting them in place would break that contract and lose the iteration
history. So `R1-M1-SKY` stays as the record of what landed:
M1.0, M1.1, M1.6a, M1.2a, the M1.2b children and M1.4a/b/c. This sprint
re-plans the rest. **At approval** the controller sets `R1-M1-SKY.status` to
`superseded_by: R1-M1-SKY-2` for the open rows (one-line JSON edit, not done
here). The parent row `M1.2b_AILANG_CATALOGUE` closes when M1.2b-T4 passes.

**Command legend.**
- `$A` = `/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
  AILANG **v0.51.0** (Makefile `AILANG_RELEASE`, CI and the lockfile; a fresh
  worktree runs `make runtime` first). Every make line passes `AILANG=$A`
  (and `AILANG_BIN=$A` where the target drives Godot).
- `$PKG` = a **fresh clone** of `sunholo-data/ailang-packages` at
  `origin/main`, `packages/relativity`. Never the dirty local copy, as in the
  M1.2b-WD and M2.0 precedents.
- GPU gates (`make golden`, `make capture`, `make bench`) run on the Studio's
  GPU window and not in CI. Their logs and renders are attached to the sprint
  notes for the evaluator.

## Current status (verified against git and GitHub, main at `6fd48d1`)

| Item | State | Evidence |
|---|---|---|
| M1.0 review builds, M1.1 photometry 0.2.0, M1.6a protocol | ✅ | PR #3; `R1-M1-SKY` JSON |
| M1.2a acquire + parse; M1.2b-preflight | ✅ | PRs #5, #9 |
| M1.2b-WD1/2/3 (relativity 0.3.0, game pin) | ✅ | ailang-packages #83; PR #12 |
| M1.2b-T1 pure transform/selection | ✅ eval 88 | PR #14 `f4dd9bc` |
| M1.2b-T2 F32 records, **N1/N2 closed** | ✅ eval 92 | PR #19 `6efcf53`. N1/N2 were closed here, not in T3. Still open: N3 (exact 50,000 boundary), tier-name validation, safe squared-distance range, and the F32 bound checked on real rows |
| M1.4a/b/c NOIRLab sky + AILANG colour model | ✅ eval 91 | PR #16 `8e46c17` |
| Catalogue mirror fix | ✅ | PR #37 |
| M1.4d sky rebuilt on the corrected catalogue, bundled via GCS | ✅ | PRs #45, #46 (D-18) |
| M1.6b free-look camera with roll, HUD angle, off-axis golden, rest-tolerance pin | executed, ⏸ R-a | 144 off-axis golden cases, worst 0.102 px; renders in `docs/m1.6b/` |
| AILANG pin | v0.51.0 | `Makefile:8`, PR #30 |
| `sunholo/relativity` | 0.4.0 latest, pinned | `ailang pkg info`; `sim/ailang.toml:17`. `optics.cmbForwardTemperature` exists; `teffFromBV` does not |
| Open PRs | **#43** (destar → AILANG, contains **#36** extract → AILANG), both CI green | `gh pr list` |

**Code that exists for the remaining work:**
- `sim/tools/catalogue.ail` (63 lines: `transform`, `selectMedium`,
  `selectTier`).
- `sim/tools/catalogue_bytes.ail` (22 lines: `encodeRow(s)`).
- `make catalogue-vm` and `make catalogue-bytes`.
- No FS writer, sidecars, tier binaries or stats.
- `sky/starfield.gd` (82 lines) loads `stars.json` (CNS3, 3,802 stars).
- `physics/blackbody.gd`: `LUT_T_MAX = 1e6`, so obligation O-1 is still
  open.
- `main.gd`: `EXPOSURE := 5.0` and `BG_EXPOSURE := 0.075` are hand-set; the
  camera has yaw and pitch, no roll.
- `sim/core.ail:24`: `restTolerance()` = 1e-9, with no test pinning it.

### Velocity (this repo)

| Sprint | Milestones | Wall clock | Evals | Counted LOC |
|---|---|---|---|---|
| R1-M1-SKY iterations 0–8 (unattended loop, 250 cap) | 9 items | 5 days | 85–98 | 130–670 each; estimate ratio 0.6–2.7× (median ~1.0) |
| **R1-M2-JOURNEY** (attended, parallel executors, 650 cap) | **10** | **~13.5 h** (2026-10-01 18:40 → 10-02 08:07) | **89–96** | ~5,000 lines against a ~3,400 estimate (~1.5×) |

Planning figures:
- **Cap:** 650 counted code + test + config LOC per milestone. Fixtures,
  goldens, generated tables, docs and data don't count. Every milestone is
  planned at ≤ 600, so a 1.1× overrun still fits.
- **Pace:** about 2 h per milestone including independent evaluation, run in
  waves where files don't overlap. M1 has a longer serial spine than M2,
  plus long compute (full-tier VM parity ~20 min, sky regeneration ~30 min)
  and GPU gates. The 7 waves therefore set the duration, not the milestone
  count.
- **Total:** 4,590 counted LOC planned. M2's 1.5× actual-to-estimate ratio
  suggests 5–7k changed lines.

## Findings made while planning (2026-10-02)

These change the plan. F1–F3 need Mark (questions Q1–Q3).

**F1. CNS5 has no Gaia photometry for 770 of its 5,908 rows, and they include
the brightest nearby stars.**
- `awk` over `data/raw/cns5.csv` finds G or BP−RP blank on 770 rows. Among
  them: CNS5:3627 at 4.32 ly (α Cen AB), CNS5:1676 at 8.60 ly (Sirius),
  CNS5:1895 at 11.46 ly (Procyon) and CNS5:4912 at 16.73 ly (Altair).
- Gaia saturates on them. GCNS doesn't have them either.
- Under the quorum rule they become `MISSING_PHOT` (teff 0, V 99), so they
  are **invisible** in the starfield and photometry-less on the map.
- D-5's literal rule ("HIP2 V < 7 not matched to GCNS or CNS5") is
  ambiguous for them. A position match to a CNS5 row with no G fails the
  `|G − V| < 2` guard, so the HIP row ships *and* the dead CNS5 row stays: a
  duplicate destination on the map.
- But the CNS5 fixed-width file carries a **HIP column** (`cns5_alpha_cen.dat`:
  `3627 559 AB … 71683`), so an exact id match is available.

**F2. CNS5 does not separate α Cen A and B, and HIP2's B parallax is poor.**
- CNS5 has a single row, "Gl 559 AB" (HIP 71683, parallax 754.81 mas from
  van Leeuwen 2007, 4.321 ly).
- HIP2 (VizieR `I/311`, fetched today) has A = HIP 71683 at 754.81 ± 4.11 mas
  and **B = HIP 71681 at 796.92 ± 25.90 mas (4.09 ly)**. Taken at face value,
  that puts B 0.23 ly in front of A, for a pair ~23 AU apart.
- D-17 expected "α Cen A ~4.365 ly" from the tiers. That is Kervella 2016
  (747.17 mas), which **no shipped catalogue contains**: the tiers give
  4.321 ly.
- M4 needs A and B as two stars at ~23 AU separation (M4 Problem 5, the
  1,000 AU stand-off and the finite-flux test).

**F3. The Python fallback in the design doc is obsolete.**
- M1.2's "if the AILANG path takes more than ~60 s, convert in Python"
  conflicts with the Python policy (#34): a new Python pipeline step is a
  defect.
- The preflight extrapolation puts the full-medium VM run at ~50–60 s before
  WD fitting and sorting, so the trigger would likely fire.
- The same policy rules out the planned `tools/catalogue_stats.py` and
  `tools/bright_star_audit.py`. This plan puts both in Godot headless, which
  reads the binaries through the same loader the game uses. That makes it a
  genuine second implementation of the reader, not an AILANG self-check.
  AC2, AC3 and AC11's commands change accordingly, and the change is recorded
  as a design-doc deviation at landing.

**F4. The forward CMB is not a small disc at the speed cap.**
- In the ship frame the CMB is a blackbody at T₀·D(θ′):
  - 3,853.7 K dead ahead at γ 707 (HB-63);
  - γT₀ = 1,927 K at θ′ = 90°;
  - 38.44 K ahead at 0.99c (HB-62, invisible).
- So near the cap it is a sky-filling glow that brightens toward the pole.
  Its apparent "disc" size depends on exposure.
- Rendering it needs **absolute** photopic radiance (cd/m²). The package's
  `luminance` is relative, and `surfaceBrightnessRatio(2.725 K, D)` divides
  by ~0, which would break the finite-LUT gate.
- So the CMB needs a package function first (0.5.0, M1.P).

**F5 (CORRECTED 2026-10-02). The sideways sky at speed is darker. That is real physics, not an exposure effect.**
- The original F5 was wrong: it came from the controller's brief, which put a
  ship-frame angle into the rest-frame Doppler formula. M1.P's evaluator-grade
  check caught it.
- For an observer, with θ′ the apparent (ship-frame) angle from the
  direction of travel, D = 1/(γ(1 − β cos θ′)). With θ the rest-frame angle,
  D = γ(1 + β cos θ).
- At θ′ = 90°, D = 1/γ: at 0.99c, 0.141 (redshifted, with stars per steradian
  ×1/50). Sources are blueshifted only within cos θ′ > (1 − 1/γ)/β: 29.8° of
  forward at 0.99c, 3.0° at the cap.
- The rest-frame 90° direction appears at cos θ′ = β (8.1° at 0.99c), where
  D = γ.
- So D-6's canon wording ("the sky … goes dark sideways at speed") is
  **correct physics**, and no canon edit is needed (Q5 withdrawn).
- M1.5a still adds the fixed-EV toggle, so exposure isn't mistaken for the
  physics. Its test now asserts that the sideways patch is darker.

**F6. The catalogue switch touches more than the map.**
- `stars.json` (CNS3) feeds:
  - `sky/starfield.gd`, `ui/galaxy_map.gd` and `names.json`, which is keyed
    by **index** because CNS3's α Cen A and B share id "Gl 559";
  - `tests/test_physics.gd` (literature directions) and
    `tests/test_galaxy_map.gd` (`ALPHA_CEN_A := 1`);
  - `sim/core_test.ail` (catalogue doubles, `Gl 559` d = 4.35667304258651);
  - `tools/record_godot_session.gd`, the replay goldens `alpha_cen` and
    `godot_map_voyage`, and the destar mask (`make destar`).
- Switching means re-keying names by catalogue id, re-recording the goldens
  (a reviewed diff, as at P5), and regenerating, re-publishing and
  re-bundling the sky textures (D-18). Hence its own milestone, M1.7.

**F7. PR #43 (with #36) is a dependency, not just a risk.**
- M1.2d needs a fixed-width VizieR parser for `I/311` and `I/239`. Under the
  Python policy it must be AILANG, and `sim/tools/extract.ail` (#36) is that
  parser.
- M1.7's destar rerun should use `sim/tools/destar.ail` (#43). The D-10 rule
  masks stars cross-matched to the *shipped* point layers (CNS5, GCNS,
  HIP2).
- #43 also edits `Makefile`, `sim/ailang.toml` and
  `data/sky/sky_model_report.json`, so it conflicts with T3/T4 and M1.2c.
- Recommendation (Q6): merge #43 (which lands #36) before wave 1.

## Milestones

Each milestone is one iteration, test-first, evaluated by a different agent
or model from the executor (generator ≠ judge). Each lands as its own PR.
`passes` starts as `null`.

### Wave 1 (parallel: disjoint files)

#### M1.2b-T3: Tier writer, validation and sidecars
**Status (2026-10-02):** executed on `sprint/m1.2b-t3`, eval round 1 88/100
(pass). Round-1 findings fixed on the same PR: the commit is all-or-nothing
(old bin set aside as `.bak` and restored if the sidecar rename fails; the bin
temp write is checked; every `.tmp` is removed; `make catalogue-main` forces
each failure), the 50,000 medium quota is pinned by `checkMediumQuota`
(`quotaVm`; the 49,999 and 50,001 mutants die), and generated tiers are
gitignored. SHA-256 comes from the bundled `std/crypto` (`sha256Bytes`), so
there is no `shasum` glue in the writer; `make catalogue-main` (in `make test`)
checks every digest against `shasum` on committed fixtures. `make
catalogue-scan` scans every CNS5 and GCNS row: 0 refusals. The full GCNS scan
takes 7 min 46 s on the VM because T1's cons accumulators are quadratic
(ailang#1501). That is T4's performance work.

**Scope:**
- **Tier validation:**
  - Only the names `quick`, `medium`, `large` are accepted (T1 residual).
  - Coordinates are validated before the medium squared-distance sort.
  - Refuse if |x|, |y| or |z| > 1e6 ly, so x² + y² + z² can't overflow
    binary64 and the order stays exact (T1 residual).
  - The conservative F32 bound from T2 is asserted on **every real row** of
    CNS5 and GCNS, with any refusal parked for review (T2 residual).
- **FS shell** (`sim/tools/catalogue_main.ail`, block-bodied `main`):
  - reads `data/raw/<src>.csv`, runs `transform`, `selectTier` and
    `encodeRows`;
  - writes `stars_<tier>.bin` and the sidecar `stars_<tier>.json`. Header
    fields: `tier, count, count_excluded, source, format_version 1,
    record_bytes 24, fields, ailang, package, producer, sha256{raw, csv,
    bin}`;
  - output paths are parameterised (`--args-json`), so the same entry can
    write to `.godot/tmp/`;
  - writes atomically: temp file then rename, so a refusal leaves no partial
    shipped file.
- **SHA-256:** the executor probes for a std hash first. If there is none,
  the Makefile computes the hashes with `shasum` (shell glue, allowed) and
  passes them in, and the gap is reported upstream.
- **`make catalogue TIER=…`.**
- Does **not** write `data/starmap/stars.json`. That moves to M1.7 (F6).

**Files:**
- `sim/tools/catalogue.ail` (validation);
- new `sim/tools/catalogue_main.ail` and `sim/tools/catalogue_main_test.ail`;
- `sim/tools/catalogue_test.ail`;
- `Makefile` (`catalogue`);
- `tools/test_catalogue_bytes.py` (oracle) only if the sidecar field order
  needs an oracle row.

**Estimated:** 380 LOC · **Deps:** none (main) · **Registry:** depend
`sunholo/relativity@0.4.0` (photometry already locked), bundled `std/fs`,
`std/json`, `std/embedding`. `pkg search catalogue|binary|float` found only
`duckdb` (a DB client), so nothing to reuse.

**Acceptance (commands):**
- `$A check --package sim && $A test --package sim`. New named checks:
  `checkTierNameRefused` ("Medium", "", "huge"), `checkHugeCoordRefused`
  (x = 1e200 refused before the sort), `checkSidecarFields` (exact key set
  and order) and `checkAtomicRefusal` (no output file after an invalid row).
- `make catalogue TIER=quick AILANG=$A`: exit 0;
  `stat -f %z data/starmap/stars_quick.bin` = 5,908 × 24 = 141,792 B (CSV
  row count; the design's 5,909 includes the Sun's null-parallax row, which
  M1.2a skips). The sidecar `count` equals that. A real-row F32 bound scan
  of CNS5 and GCNS reports 0 refusals.
- `make catalogue-vm catalogue-bytes AILANG=$A` stay green.
- `make test AILANG=$A AILANG_BIN=$A` is green.
- No pixels change, so there's no render gate.

**Mutations it must kill:** an unknown tier passing through; sorting before
validation; dropping the bin sha from the sidecar; a partial file left on
refusal.

#### M1.6b: Free-look camera with roll, HUD angle and off-axis golden
**Status (2026-10-02):** executed, awaiting ⏸ R-a. `make golden`: 144
off-axis/rolled star cases, worst 0.102 px, plus a pitched-and-rolled
background-marker view (16 markers); renders in `docs/m1.6b/`. The camera is
its own class, `ui/free_look_camera.gd` (`FreeLookCamera`), so the physics
test drives the same object `main.gd` flies; that file is the one addition to
the file list.

**Scope:**
- **Camera:** yaw, pitch and **roll**, independent of the velocity; the
  camera never goes to the sim.
- **HUD:** the view-to-velocity angle.
- **`tests/test_physics.gd`:**
  - `test_rolled_camera_cpu_spec_values` uses the real camera object, which
    completes AC4;
  - `test_view_velocity_angle`.
- **Golden:** 12 star directions × 4 speeds × 3 camera orientations
  (including a roll), GPU vs CPU through the same camera within 0.75 px
  (AC5, star part), generated in `main.gd` `_run_golden`.
- **M1.6a follow-up:** pin `restTolerance()`:
  - `checkRestToleranceEdge` in `sim/core_test.ail`: a turn at φ = 0.9e-9 is
    accepted and at 1.1e-9 is refused `moving`, so a mutation that raises the
    tolerance to 0.5 fails;
  - a v2 protocol case in `make parity-v2`.

**Files:** `main.gd` (camera, HUD, golden only), `tests/test_physics.gd`,
`sim/core_test.ail`, `Makefile` (`golden` case count).

**Estimated:** 300 LOC · **Deps:** none · **Registry:** none. Godot camera
code; package `optics` is mirrored, not changed.

**Acceptance:**
- `make physics AILANG=$A`: the new cases pass.
- `make golden AILANG=$A`: 144 off-axis cases plus the existing ones, worst
  error ≤ 0.75 px printed, 0 failures.
- `$A test --package sim`: `checkRestToleranceEdge` passes. `make strict`
  and `make test AILANG=$A AILANG_BIN=$A` are green.
- `make capture AILANG=$A AILANG_BIN=$A`: rolled and off-axis renders opened
  by the executor.
- **⏸ R-a (Mark, physics gate 2):** off-axis and rolled renders, plus
  `make publish-dev` → `tools/install_review_build.sh --dev` to try the
  roll control. The merge waits for the review; wave 2 doesn't.

#### M1.P: `sunholo/relativity` 0.5.0, photometry for M1's remaining physics (package first)
**Scope (in `$PKG`):**
- **`photometry.teffFromBV(bv)`** and `bvNodes()`, emitted by the existing
  Mamajek generator from the **same table's B−V column**, with the same
  monotone interpolation, clamping and in-range flag (D-5). A comment states
  the dwarf relation is approximate for the giants in the bright tier.
- **`photometry.luminanceFromSurfaceMag(mu)`:** cd/m² from V mag/arcsec²,
  using the package's own zero point (V = −13.98 at 1 lux), so no new
  constant. Check: μ = 22 → 1.726×10⁻⁴ cd/m², the design's 1.7×10⁻⁴.
- **`blackbody.photopicRadiance(kelvin)`:** absolute cd/m²
  (683 lm/W × ∫B_λ ȳ dλ on the package's CIE table), finite and ≥ 0 down to
  T → 0, which kills the 2.725 K divide-by-zero (F4).
- **`optics.cmbSeenTemperature(n, bh, phi)`** = T₀ · doppler(n, bh, phi).
  Checks: 3,853.7 K ahead at the cap (HB-63), γT₀ = 1,926.9 K at 90°, and
  38.44 K at 0.99c (HB-62).
- **`photometry.pointThresholdIlluminance(lb)`:** the naked-eye point-source
  threshold against background luminance, from a published model (Crumey
  2014, cited with its equation number). AC8's limiting magnitude then comes
  from the literature, not from a tuned constant.
- **Tests:** known-star dwarfs (Sun B−V 0.65 → 5770 K, α Cen B, Barnard,
  Proxima within 5%), endpoint clamping, a 1e4-point finite sweep of every
  new function, and an independent Python oracle for `photopicRadiance` at
  2856 K, 5772 K and 3853.7 K.
- **Release:** CHANGELOG `## 0.5.0`, `[release] kind = "feature"`,
  AGENT.md, `pkg quality` with no gates, `publish --dry-run`. The
  **controller publishes** under the standing grant after an independent
  physics PASS (the strongest available evaluator), then pins `0.5.0` in
  `sim/ailang.toml` and relocks (`make deps AILANG=$A`).
- **Version rule:** the next free minor. It's 0.5.0 unless M3 publishes
  first, in which case this becomes 0.6.0 and the docs follow (M3 doc
  §Version).

**Estimated:** 450 LOC · **Deps:** none · **Registry:** **contribute** to
`sunholo/relativity@0.4.0`, the single physics package (CLAUDE.md gate 3).
`pkg search photometry|cmb|exposure` returns only this package.

**Acceptance:**
- `cd $PKG && $A test --package . && $A pkg quality .` (no gates).
- Strict VM equals the interpreter on a new `_smoke.ail` entry
  `photometryDigest` (`cmp`).
- `$A pkg info sunholo/relativity` shows v0.5.0.
- `grep '"0.5.0"' sim/ailang.toml sim/ailang.lock`, then
  `make test AILANG=$A AILANG_BIN=$A` is green.
- **⏸ P1:** controller publish after the independent evaluation.

### Wave 2

#### M1.2b-T4: Full-tier integration, VM parity and performance
**Status (2026-10-02):** executed on `sprint/m1.2b-t4`, awaiting independent
evaluation. The T3 risk (ailang#1501) is fixed. The transform, `selectMedium`,
`encodeRows`, `count` and `checkRow` now build every list with linear builtins
(map, filter, flatMap, take, length, one stable sort), and foldl remains only
for scalar tallies. `findIndex` and `any` are avoided: they recurse, are
quadratic on the VM and overflow the interpreter's depth limit (ailang#1518,
filed). The output bytes match the old code on all three tiers. On the VM,
medium went from 383 s to 61 s and large from 536 s to 55 s; the interpreter
is dominated by per-row cost (about 4 ms a row), so it barely moves. All three
tiers build from the real CSVs: quick 141,792 B; medium 1,200,000 B with 965
excluded; large 331,312 × 24 = 7,951,488 B, with 0 skipped. `make
catalogue-parity` (medium) prints `5/5 identical`. N3 (`quotaVm`) replaces
T3's `checkMediumQuota`. Mutations: 19 of 19 killed. The timing table is in
the PR.
**Scope:**
- Build all three tiers from the real CSVs.
- N3: an exact 50,000 boundary fixture (50,001 eligible plus intervening
  missing rows, so a 49,999 mutant fails).
- Independent excluded counts.
- `make catalogue-parity`: the medium tier on the interpreter once and the
  ordinary VM five times, `cmp` of the bins and sidecars, printing the six
  wall times and peak RSS.
- The timing is reported, not used as a Python trigger (F3, Q3). Any
  VM/interpreter divergence is an upstream report and blocks the milestone.
- Closes the parent row `M1.2b_AILANG_CATALOGUE` (AC2's pipeline part).

**Files:** `Makefile` (`catalogue-parity`), `sim/tools/catalogue_test.ail`
(N3), a runner script in shell (no new Python; `tools/catalogue_probe.py` is
already allowlisted as a harness and may be extended instead).

**Estimated:** 260 LOC · **Deps:** M1.2b-T3 · **Registry:** none (the
harness).

**Acceptance:**
- `make catalogue TIER=medium AILANG=$A`: 1,200,000 B, `count_excluded` > 0
  printed.
- `make catalogue TIER=large AILANG=$A`: (331,312 − skipped) × 24 B; time
  recorded.
- `make catalogue-parity AILANG=$A` prints `5/5 identical` plus the times.
- `$A test --package sim` passes N3.

### Wave 3

#### M1.2c: Stats, determinism, cleanup and tier commits (D-3)
**Status (2026-10-02):** executed on `sprint/m1.2c-tiers`, awaiting
independent evaluation. The loader, stats, verify, cleanup and tier commits are
done. Stats on the committed tiers: quick has 5,908 stars, 0 excluded and a
76.8 % M-dwarf share; medium has 50,000 stars, 965 excluded and a 74.4 %
share. Both have 0 defaulted-photometry violations and no unknown flags. The
large tier, built locally and not committed, has 331,312 stars and a 73.4 %
share, also with 0 violations. `make catalogue-verify` prints `quick
identical` and `medium identical`.
The T4 evaluator's finding is fixed. `data/raw/cns5.dat` is pinned in
`data/sky/SHA256SUMS`. A new `make catalogue-inputs` fetches the four
catalogue inputs from the bucket and falls back to VizieR and `extract.ail`
(`sky-inputs` depends on it). `tools/sky_assets.sh fetch` now tries every pin
before it exits 1 (tested hermetically by `tools/test_sky_assets.sh` in
`tools-test`).
`whiteDwarf` is guarded. `catalogue_stats.gd` fails any tier that holds a flags
value outside {0,2,3,5,16,21}, and a comment in `catalogue.ail` says why.
**Scope:**
- **`sky/star_catalogue.gd`:** the binary-tier loader, which M1.3 reuses.
  - `FileAccess.get_buffer` → `PackedFloat32Array`;
  - checks the sidecar `format_version`, `record_bytes`, `count` and bin
    sha256.
- **`tools/catalogue_stats.gd`** (Godot headless; replaces the planned
  `catalogue_stats.py`, F3). For each tier it reports:
  - the count;
  - the M-dwarf share of complete rows (teff < 3,900 K; the Mamajek M0V
    boundary, stated in a comment);
  - the excluded count;
  - the zero-defaulted-photometry check: (teff == 0 ∧ v == 99) ⇔
    MISSING_PHOT, for every record.
  - `--tier medium` exits 0 iff AC3 and AC2's clause hold.
- **`make catalogue-stats`** (on the committed quick and medium bins, so it
  runs **in CI** inside `make test`).
- **`make catalogue-verify`:** rebuilds quick and medium into
  `.godot/tmp/verify/` and `cmp`s them against the committed files (the
  CLAUDE.md determinism rule).
- **Cleanup:**
  - remove `process_stars.sh`;
  - `starmap-manager` SKILL.md and `status.sh` get the tier table, the
    sources (VizieR A19 + A6) and `make catalogue TIER=…`;
  - `.gitignore` already ignores every `data/starmap/stars_*` tier (T3 round 2),
    so the commit below force-adds quick and medium (`add -f`); large stays
    ignored.
- **Commits:** stage the quick and medium bins and sidecars (~1.4 MB, D-3).
  The controller commits.

**Files:** `sky/star_catalogue.gd`, `tools/catalogue_stats.gd`,
`tests/test_star_catalogue.gd` (stride/endianness on a 2-record bin built in
GDScript), `Makefile`, `.gitignore`, starmap-manager skill files,
`data/starmap/stars_{quick,medium}.{bin,json}` (data, not counted).

**Estimated:** 320 LOC · **Deps:** M1.2b-T4 · **Registry:** none.

**Acceptance:**
- ✅ `make catalogue-stats TIER=medium` prints an M-dwarf share ≥ 60% and
  exits 0 (**AC3**, amended command). It prints 74.4 % and exits 0.
- ✅ `make catalogue-stats` prints every tier's excluded count and finds 0
  defaulted rows (AC2's clause). quick: 0 excluded; medium: 965 excluded.
- ✅ `make catalogue-verify AILANG=$A` prints `quick identical` and
  `medium identical`.
- ✅ `test ! -f .claude/skills/starmap-manager/scripts/process_stars.sh`.
- ✅ `git ls-files data/starmap` shows the quick and medium bins and sidecars,
  and not large.
- ✅ (locally) `make test` (now including `catalogue-stats` and
  `test_star_catalogue`, as the `star-catalogue-test` target) is green; CI runs
  on the PR. **AC2 is met.**

### Wave 4 (parallel)

#### M1.2d: Bright tier (D-5), HIP photometry fill and binary components
**Status (2026-10-02):** executed on `sprint/m1.2d-bright`; awaiting independent evaluation.
Results:
- [x] Named checks pass under `ailang test` and `make bright-test` (strict VM = interpreter;
  real-byte fixtures VM = interpreter). Checks: checkVegaExcluded, checkArcturusPmMatch,
  checkRigelIncluded, checkCns5EpochMatch, checkSiriusFilled, checkAlphaCenComponents, plus
  checkSharedHipGuard, checkCuts, checkOverrideRefused and checkFillQuickOnly. 17 mutants are
  all killed.
- [x] `make catalogue TIER=bright`: 10,713 rows, 257,112 B (a multiple of 24), 7 excluded (no
  B−V). 463 matched CNS5 and 4,120 matched GCNS. About 7 s on the VM.
- [x] `make catalogue-parity` is 5/5 for bright, quick and medium. `make catalogue-stats` finds
  0 defaulted-photometry violations in every tier. The quick tier has 137 HIP-filled rows;
  633 rows stay MISSING_PHOT because they have no HIP id, or share one, or have no B−V.
- [x] `make test` includes `test-bright-audit` and `bright-test`.

Deviations:
- Sirius gets hip_main V **−1.44** (the I/239 value, verbatim), not the −1.46 written above.
- The fill extends to CNS5 rows that share a HIP id with another row, under the |G − V| < 2
  guard. Aldebaran A, ε Sco, ε Cyg and 84709 AB are filled; faint companions are not.
- Bright-tier rows sit at J2016.0 (HIP2 propagated). α Cen B sits at the system row's epoch
  (1991.25).
- V < 7 stars without B−V (7) are excluded and counted in `count_excluded`. They are not kept
  as MISSING_PHOT rows.
- The fill and bright entries live in a new `sim/tools/bright_main.ail`, not in
  `catalogue_main.ail`. Importing extract.ail into catalogue_main made the v0.51.0 VM run
  extract's `main` for `--entry main` (reported upstream).
- `catalogue.ail` changed only for the shared `Fill` type and a rename (ailang#1461). The fill
  is applied by `catalogue_main.planFill`.

**Scope:**
- **Downloads.** `download_stars.sh bright` fetches HIP2 `I/311` `hip2.dat`
  and `I/239` `hip_main.dat`, with byte-size and sha256 logging. The
  existing `hip` case (I/239 V < 7.5 TSV, used by destar) stays.
- **Parsing.** `sim/tools/bright.ail` uses the `extract.ail` fixed-width
  helpers (#36). It:
  - joins hip2 × hip_main on HIP;
  - keeps V < 7 and Plx > 0;
  - propagates proper motion to 2016.0 for GCNS and to each CNS5 row's own
    epoch;
  - matches GCNS within 1″ with |G − V| < 2;
  - matches CNS5 **by its HIP column** (exact, F1).
- **Rules (subject to Q1 and Q2; the defaults are the recommendations):**
  - (a) A HIP2 star with no GCNS or CNS5 match goes into `stars_bright.bin`:
    `teff = teffFromBV(bv)`, `v = V` verbatim, flag 8.
  - (b) A CNS5 row with missing Gaia photometry and a HIP id gets HIP
    photometry (`teffFromBV`, V) and flag 8, in place, so there is no
    duplicate row.
  - (c) The components of a CNS5 multiple that HIP lists separately (α Cen
    B = HIP 71681) take **the CNS5 system parallax**, at their HIP2 relative
    position propagated to epoch. They do not take their own HIP2 parallax
    (F2). The rule is written as data in
    `data/starmap/bright_overrides.json` with a citation per row.
- **Godot side.** `tools/bright_star_audit.gd` (AC11 auditor; Godot
  replaces the planned Python) is unit-tested here on synthetic renders. The
  full render gate runs in M1.5b.
- **Commit.** `stars_bright.bin` (~0.25 MB) and its sidecar are committed
  (Q4; CI and AC11 need a stable input).

**Files:**
- `sim/tools/bright.ail` and `sim/tools/bright_test.ail`;
- `sim/tools/catalogue.ail` (+ the bright path and fill rule);
- `.claude/skills/starmap-manager/scripts/download_stars.sh`;
- `tools/fixtures/hip2_*.dat` and `hip_main_*.dat` (real bytes: Vega,
  Arcturus, Rigel, α Cen A/B, a high-proper-motion CNS5 star);
- `tools/bright_star_audit.gd` and `tests/test_bright_audit.gd`;
- `data/starmap/bright_overrides.json`, `Makefile`.

**Estimated:** 560 LOC · **Deps:** M1.2c, M1.P (published and pinned),
**#43/#36 merged** · **Registry:** depend `sunholo/relativity@0.5.0`
(`teffFromBV`); depend on the in-repo `extract.ail` helpers; `none` for the
cross-match (`pkg search hipparcos|crossmatch` returned nothing).

**Acceptance:**
- `$A test --package sim` passes the named checks:
  - `checkVegaExcluded` (matched, absent from bright);
  - `checkArcturusPmMatch` (matches only with propagation);
  - `checkRigelIncluded` (v = catalogue V, flag 8);
  - `checkCns5EpochMatch`;
  - `checkSiriusFilled` (CNS5:1676 gets HIP V −1.46 and flag 8, with no
    bright duplicate);
  - `checkAlphaCenComponents` (A and B both present, B at the CNS5 system
    distance ± separation, not 4.09 ly).
- `make catalogue TIER=bright AILANG=$A`: the size is a multiple of 24; the
  row count lies in [1,000, 20,000] and is recorded.
- `make catalogue-parity AILANG=$A` is still 5/5. `make catalogue-stats`
  finds 0 defaulted rows in quick after the fill.
- `make test` includes `test_bright_audit` and is green.

#### M1.3: Star rendering v2 (331k instanced, physical brightness)
**Scope:**
- **`sky/starfield.gd`:** loads binary tiers through `star_catalogue.gd`.
  The bright tier is always loaded on top. The JSON path is removed for the
  starfield.
- **Instances:** a MultiMesh with 331k instances. Custom data =
  (T_eff, E_v at Sol in lux via `illuminanceFromV` mirrored from the
  package, flags).
- **Rebasing** (precision gate 5):
  - positions are held as float64 on the CPU and rebased on the ship when it
    moves > 0.01 ly;
  - the sub-0.01 ly offset goes to the vertex shader as a uniform, so the
    destination star stays exact at the 1,000 AU stand-off.
  - Measure the CPU rebase: if > 4 ms, compute direction and 1/r² fully in
    the vertex shader (design plan B).
- **Brightness:** splat energy ∝ E_v × `pointFluxRatio(T, D)`.
- **O-1:** raise `LUT_T_MAX` to 1e7 (`LUT_SIZE` 1024 → 1320). Extend the
  finite-LUT test, and add a golden case at 60 kK, D = 44.7.
- **`make bench`:** a scripted 30 s flight at 2560×1440 logging p50/p99
  frame time and a GPU timestamp for the star pass. Targets:
  - star pass < 2 ms/frame;
  - CPU rebase < 4 ms;
  - p99 < 16.7 ms with the background (AC7).

**Files:** `sky/starfield.gd`, `sky/starfield.gdshader`,
`physics/blackbody.gd`, `tests/test_physics.gd`, `main.gd` (starfield load
plus a bench entry; minimal, after M1.6b merges), `Makefile` (`bench`),
`tools/bench.gd`.

**Estimated:** 600 LOC · **Deps:** M1.2c (loader and committed tiers),
M1.6b merged (`main.gd`) · **Registry:** depend `sunholo/relativity@0.4.0`
(mirrored functions `pointFluxRatio` and `illuminanceFromV`); Godot
otherwise.

**Acceptance:**
- `make physics`: the brightness ∝ E_v test, the LUT finite to 1e7 test
  (gate 5), and a rebasing precision test (the α Cen direction at a
  1,000 AU stand-off within 1e-9 rad, float64).
- `make golden AILANG=$A`: the 60 kK case plus all existing cases, 0
  failures.
- `make bench TIER=large`: the star-pass GPU time and the p99 are printed
  (AC7, stars-only part); the numbers are recorded.
- `make capture AILANG=$A AILANG_BIN=$A`: renders at 0, 0.9 and 0.99c ×
  forward and astern with the large tier, opened.
- **⏸ R-b (Mark, gate 2):** renders, bench numbers, and a dev build via
  `make publish-dev` / `tools/install_review_build.sh --dev`. The merge
  waits for the review.

### Wave 5 (parallel)

#### M1.7: Catalogue switch: map, names and goldens on the tiers (F6)
**Scope:**
- **Map JSON.** The AILANG catalogue run writes the human-readable map
  catalogue `data/starmap/stars.json` from quick + bright within 25 pc. It
  replaces CNS3, as the design intends ("JSON stays for CNS5"). Map content
  is per Q7.
- **Names.** `names.json` is re-keyed by **stable catalogue id** (Gaia DR3
  source_id, `CNS5:n` or `HIP n`) instead of by index, so α Cen A and B are
  separate rows.
  - `tools/check_star_names.py` (the oracle) is updated against SIMBAD
    references.
  - D-17: the subtitle is the catalogue id, and the distance shown is the
    catalogue's own.
- **Code and tests.** Update `ui/galaxy_map.gd`, `tests/test_galaxy_map.gd`
  (no more `ALPHA_CEN_A := 1`), the `tests/test_physics.gd` catalogue
  directions, `sim/core_test.ail` catalogue doubles and
  `tools/record_godot_session.gd`.
- **Goldens.** Re-record the `alpha_cen` and `godot_map_voyage` replay
  goldens per architecture with `make replay-record` (a reviewed diff, as at
  P5).
- **Destar rerun** against the shipped layers (CNS5 + GCNS + HIP2, per
  D-10) with `sim/tools/destar.ail` (#43): `make sky-regen`, a new
  `data/sky/SHA256SUMS`, `make sky-publish` (D-18) and a re-bundle.

**Files:** `ui/galaxy_map.gd`, `main.gd` (map load line only),
`data/starmap/{stars,names}.json`, `tools/check_star_names.py`,
`tests/test_galaxy_map.gd`, `tests/test_physics.gd`, `sim/core_test.ail`,
`tests/replays/*` goldens, `data/sky/*`, `sim/tools/catalogue_main.ail`
(JSON writer).

**Estimated:** 520 LOC · **Deps:** M1.2d, M1.3 merged (starfield already on
tiers), #43 · **Registry:** none (UI and data).

**Acceptance:**
- `make ui AILANG=$A AILANG_BIN=$A`: names load with 0 mismatches; α Cen A
  and B are two selectable stars; the map shows the catalogue distance
  (4.32 ly under the Q2 default).
- `python3 tools/check_star_names.py`: every named id within tolerance of
  its SIMBAD reference.
- `make replay AILANG=$A`: green against the re-recorded goldens.
- `make sky-verify`: the textures match the new `SHA256SUMS`.
- `make test` is green in CI.
- **⏸ R-c (Mark):** the map review build, the golden diff approval (as at
  P5), and destar before/after crops (gate 2 for the background). This
  satisfies M4's dependency "M1.2 tiers (α Cen A/B real astrometry)".

#### M1.5a: Photometric exposure, and honesty about it (F5)
**Scope:**
- **Scene units:**
  - stars integrate to their E_v in lux;
  - the background is in cd/m², calibrated so a dark-sky patch reads
    22 mag/arcsec² through `luminanceFromSurfaceMag` (0.5.0).
  - Remove `EXPOSURE` and `BG_EXPOSURE` from `main.gd`.
- **Camera:** EV exposure, log-average auto-exposure, and a player clamp and
  bias. The readability aids (magnitude floor, exposure bias) are labelled
  and **off** by default. The default exposure follows Q8.
- **Limiting magnitude** comes from `pointThresholdIlluminance(L_bg)` at the
  default dark-adapted EV. It's measured on a synthetic star ladder,
  V 5.0–7.5, in the rendered frame (AC8).
- **Exposure honesty** (Mark's 2026-10-02 note):
  - the HUD shows the EV and the metering mode;
  - a "fixed EV" toggle locks exposure at the rest value;
  - `tests/test_physics.gd` asserts that the mean seen luminance of a
    θ′ = 90° patch at β = 0.99 is BELOW the same patch at rest (D = 1/γ =
    0.141), that a θ′ = 8.1° patch (rest-frame 90°) is brighter (D = γ), and
    that the D = 1 boundary sits at cos θ′ = (1 − 1/γ)/β (29.8° at 0.99c);
  - `make capture` adds a fixed-EV pair (rest and 0.99c starboard) beside
    the auto-exposed pair, so the report shows the sideways darkening at a
    fixed exposure, as physics and not as metering (corrected F5).

**Files:** `main.gd` (exposure only), `sky/starfield.gdshader`,
`sky/background.gd(shader)`, new `sky/exposure.gd`, `tests/test_physics.gd`,
`Makefile` (`capture` cases).

**Estimated:** 550 LOC · **Deps:** M1.3, M1.P · **Registry:** depend
`sunholo/relativity@0.5.0` (`luminanceFromSurfaceMag`,
`pointThresholdIlluminance`, mirrored in GDScript per gate 3).

**Acceptance:**
- `make physics`: the scene-unit tests, the sideways-darker test (corrected F5) and the
  D = 1 boundary test.
- `make bench`: the report prints the limiting magnitude, 6.0 ≤ V_lim ≤ 6.8
  (**AC8**).
- `make golden AILANG=$A`: an exposure golden (a known-lux star reaches its
  expected linear pixel value within 1%).
- `make capture AILANG=$A AILANG_BIN=$A`: the fixed-EV and auto pairs,
  opened.
- **⏸ R-d (Mark, gate 2):** exposure renders and a dev build. Q8 must be
  answered before merge.

### Wave 6

#### M1.8: Forward CMB glow (queue row 6a, D-11)
**Scope:**
- Add a CMB term to `sky/background.gdshader`: per pixel,
  radiance += `photopicRadiance(T₀ · D(n′))` in cd/m². It is drawn under the
  stars and on top of the galaxy, in the same exposure.
- A GDScript mirror of `cmbSeenTemperature` and `photopicRadiance`, with a
  finite lookup over T ∈ [0, 5,000 K] (gate 5).
- The planner text "forward CMB not yet rendered" (M4 default) is never
  needed.

**Files:** `sky/background.gdshader`, `sky/background.gd`,
`physics/blackbody.gd`, `tests/test_physics.gd`, `main.gd` golden cases.

**Estimated:** 300 LOC · **Deps:** M1.5a (shares the background shader and
the exposure units), M1.P · **Registry:** depend
`sunholo/relativity@0.5.0`.

**Acceptance:**
- `make physics`: T ahead at the cap 3,853.7 K (HB-63); 1,926.9 K at
  θ′ = 90°; 38.44 K at 0.99c (HB-62); radiance at β = 0 is below 10⁻³⁰ of
  the dark-sky level; LUT finite.
- `make golden AILANG=$A`: a CMB pixel at θ′ = 0°, 45° and 90° at γ = 707
  matches the CPU radiance within 1% (linear tonemap); exactly 0 at β = 0.
- `make capture`: γ 275 and γ 707, forward and starboard, auto and fixed EV.
- **⏸ R-e (Mark, gate 2).**

### Wave 7

#### M1.5b: Reference renders, bright-star audit, bench, M1 report and landing
**Scope:**
- **AC9:** `make capture` at 0, 0.5, 0.9, 0.99 and 0.999c × forward,
  starboard and astern, with the large tier, the background and the CMB.
- **AC11:** the audit gate,
  `make capture && godot --headless --script tools/bright_star_audit.gd renders/`.
- **AC7:** `make bench TIER=large` with the background.
- **Report:** `design_docs/implemented/r1/m1-report.md` covering renders,
  bench numbers, pipeline VM measurements, the AILANG issues filed,
  deviations (AC2/AC3/AC11 commands; the Python fallback retired; the CMB
  added) and residual limits (the panorama is valid to ~50 ly; the HIP
  giants' B−V relation).
- **Landing:**
  - move the design doc and both sprint plans to `implemented/r1/`;
  - add a CHANGELOG fragment;
  - update the design repo's roadmap M1 status;
  - update the charter queue (clause 1);
  - cut a review build tag.

**Estimated:** 350 LOC · **Deps:** all above · **Registry:** none.

**Acceptance:**
- `make capture AILANG=$A AILANG_BIN=$A`: 15 renders plus a contact sheet,
  committed (**AC9**).
- Bright-star audit: ≥ 95% of HIP2 stars with V < 2.5 within 1 px; rendered
  stars with V < 6.5 between 5,000 and 9,100 (**AC11**).
- `make bench TIER=large`: p99 < 16.7 ms at 2560×1440 on the M4 Max (**AC7**).
- `make test` is green in CI; `make strict` and the parity targets are green
  (**AC10**).
- **⏸ R-f (Mark):** reviews the M1 report and the AC9 renders. **Bar clause
  1 is met** only after this sign-off.

## Milestone table

| ID | Scope | LOC | Deps | Wave |
|---|---|---|---|---|
| M1.2b-T3 | Tier writer, validation, sidecars, `make catalogue` | 380 | — | 1 |
| M1.6b | Free-look camera with roll, HUD angle, 144-case off-axis golden, rest-tolerance pin | 300 | — | 1 |
| M1.P | relativity 0.5.0: `teffFromBV`, surface-mag → cd/m², absolute photopic radiance, `cmbSeenTemperature`, point threshold; publish + pin | 450 | — | 1 |
| M1.2b-T4 | Full-tier integration, N3, 5-run VM parity, timings | 260 | T3 | 2 |
| M1.2c | Godot loader, stats (AC2/AC3 in CI), verify, cleanup, commit quick + medium | 320 | T4 | 3 |
| M1.2d | HIP2 bright tier, CNS5 HIP-photometry fill, α Cen A/B components, audit unit | 560 | M1.2c, M1.P, #43 | 4 |
| M1.3 | Starfield v2: 331k MultiMesh, float64 rebasing, O-1 LUT 1e7, `make bench` | 600 | M1.2c, M1.6b | 4 |
| M1.7 | Catalogue switch: map JSON, names by id, tests, goldens, destar rerun + sky publish | 520 | M1.2d, M1.3, #43 | 5 |
| M1.5a | Photometric exposure, AC8, exposure honesty (fixed EV, sideways test) | 550 | M1.3, M1.P | 5 |
| M1.8 | Forward CMB glow with golden | 300 | M1.5a, M1.P | 6 |
| M1.5b | AC9 renders, AC11 audit, AC7 bench, M1 report, landing | 350 | all | 7 |
| | **Total** | **4,590** | | **7 waves** |

**Critical path:** T3 → T4 → M1.2c → M1.3 → M1.5a → M1.8 → M1.5b (7
iterations). The catalogue chain (M1.2c → M1.2d → M1.7) runs beside it.

**Duration:**
- **Attended** (as in M2): 7 waves × ~2 h, plus ~2 h of long compute and GPU
  gates. That is **~16–20 h, two working days**, if Mark reviews R-b and R-d
  the same day. Those two gate merges on the critical path.
- **Unattended loop** (one item per 6 h iteration): 11 items plus ~2
  contingency = 13 iterations, **~4–6 days** including review waits.

## Review checkpoints (physics gate 2)

Each sends Mark a review page and a dev build: `make publish-dev`, then he
runs `tools/install_review_build.sh --dev`.

| ID | After | What Mark sees | Blocks |
|---|---|---|---|
| ⏸ P1 | M1.P | (controller) independent physics PASS → publish 0.5.0 | M1.2d, M1.5a, M1.8 |
| ⏸ R-a | M1.6b | off-axis + rolled renders; roll in the dev build | M1.6b merge only |
| ⏸ R-b | M1.3 | 331k-star sky at 0/0.9/0.99c, bench numbers | M1.3 merge → M1.5a |
| ⏸ R-c | M1.7 | the map on CNS5/HIP with α Cen A/B separate; replay golden diff; destar crops | M1.7 merge; M4 unblocked on tiers |
| ⏸ R-d | M1.5a | exposure renders incl. the fixed-EV sideways pair; **Q8 needed** | M1.5a merge → M1.8 |
| ⏸ R-e | M1.8 | CMB at γ 275/707 | M1.8 merge |
| ⏸ R-f | M1.5b | M1 report, AC9 set → bar clause 1 | landing |

## Registry reuse gate (searched 2026-10-02, `ailang pkg search`)

Searches: relativity, photometry and cmb return only
`sunholo/relativity@0.4.0`. Hipparcos, catalogue and exposure return
nothing. Binary returns only `sunholo/duckdb@0.2.1` (a DB client, not a
float codec). Star returns relativity and `gemini_agents` (unrelated).

| Milestone | Package | Action | Reason |
|---|---|---|---|
| M1.2b-T3 | sunholo/relativity@0.4.0; std/fs, std/json, std/embedding | depend | Photometry already locked; native F32 codec reused (T2); no catalogue/binary package exists |
| M1.6b | none | none | Godot camera code; package `optics` mirrored, not changed |
| M1.P | sunholo/relativity@0.4.0 | contribute | The single physics package (gate 3); publish the next free minor (0.5.0) |
| M1.2b-T4 | none | none | Parity/timing harness (Makefile + shell) |
| M1.2c | none | none | Godot loader and stats; no AILANG package applies |
| M1.2d | sunholo/relativity@0.5.0 | depend | `teffFromBV`; HIP cross-match is game-specific (`pkg search hipparcos` empty) |
| M1.3 | sunholo/relativity@0.4.0 | depend | GDScript/shader mirror `pointFluxRatio`, `illuminanceFromV` |
| M1.7 | none | none | UI, names data, goldens |
| M1.5a | sunholo/relativity@0.5.0 | depend | `luminanceFromSurfaceMag`, `pointThresholdIlluminance` |
| M1.8 | sunholo/relativity@0.5.0 | depend | `cmbSeenTemperature`, `photopicRadiance` |
| M1.5b | none | none | Renders, audit, report |

## Risks

| Risk | Mitigation |
|---|---|
| **F1/F2 data gaps:** without HIP fill, Sirius/α Cen/Procyon/Altair are invisible in the tiers; HIP2's α Cen B parallax puts B 0.23 ly from A | Rules (b)/(c) in M1.2d with named checks; Q1/Q2 decide; overrides are cited data, not code |
| **#43 not merged, or merged late:** M1.2d has no AILANG fixed-width parser; destar rerun has no AILANG tool; Makefile conflicts with T3/T4/M1.2c | Q6: merge #43 first. Fallback: M1.2d vendors the parser helpers from #36's branch, M1.7 reruns the allowlisted `m14a_destar.py` (role `port`) |
| Full-medium VM run > 60 s (preflight extrapolation ~50–60 s before WD/sort) | Report it upstream as a data point; no Python fallback (F3, Q3); budget ≤ 10 min/tier offline |
| VM/interpreter divergence on 331k rows | Blocks T4; minimal repro to `ailang messages` (gcp store); never worked around |
| 331k instances miss < 2 ms star pass / p99 16.7 ms | Vertex-shader rebasing (plan B); medium tier as the in-game default if large misses, recorded in the report |
| Float32 precision at the 1,000 AU stand-off (M4) | float64 CPU rebasing + sub-0.01 ly shader offset; CPU precision test in M1.3 |
| Exposure model circular (limit tuned to pass AC8) | Threshold from a cited model in the package (Crumey 2014), measured in the rendered frame, not computed from the same constant |
| CMB term saturates the frame at the cap and hides the stars | That is the physics (F4); fixed-EV and auto renders both reviewed at R-e; the report states it |
| Catalogue switch breaks goldens and names silently | Names keyed by stable id with the SIMBAD oracle; goldens re-recorded only via reviewed `make replay-record` |
| Sky textures change after M1.5a calibrates them | Calibrate on the dark-sky reference patch, not on texture bytes; re-run the exposure golden after M1.7's regen |
| M3 publishes 0.5.0 first | M1.P takes 0.6.0; docs and pins follow (M3 doc §Version) |
| Mark review latency at R-b/R-d (critical path) | Build the next wave on the reviewed branch; only merges wait |

## Questions for Mark

1. **Q1: HIP photometry for CNS5 rows Gaia can't measure (F1).** For CNS5
   rows with no Gaia photometry and a HIP id, take V and B−V from
   Hipparcos (flag 8) in place, so Sirius, α Cen, Procyon and Altair are
   visible and appear once on the map? **Recommendation: yes.** Default if
   unanswered: yes. It extends D-5 rather than reversing it.
2. **Q2: α Cen A/B distance (F2).**
   - (a) Both components at the CNS5/HIP2 system parallax (754.81 mas,
     **4.32 ly**), B offset by the HIP2 relative position. This is the
     catalogue's own number, per D-17.
   - (b) A small cited literature override table (Kervella 2016, 747.17 mas,
     **4.365 ly**) for α Cen and other named systems.

   **Recommendation: (a) for R1**, with (b) as a later polish. Default: (a).
   Either way B never takes its own HIP2 parallax (4.09 ly).
3. **Q3: retire the design doc's Python fallback (F3)?** The AILANG catalogue
   path ships however long it takes, measured and reported upstream (budget
   ≤ 10 min per tier). Stats and the audit move to Godot (amended AC2, AC3
   and AC11 commands). **Recommendation: yes.** Default: yes, citing the
   Python policy.
4. **Q4: commit `stars_bright.bin` (~0.25 MB) too?** D-3 named only quick
   and medium. **Recommendation: yes** (CI and AC11 need it). Default: yes.
5. **Q5: WITHDRAWN (2026-10-02).** D-6's "goes dark sideways at speed" is correct physics (corrected F5). No canon edit.
6. **Q6: merge PR #43 (which lands #36) before wave 1?** M1.2d and M1.7
   depend on it. **Recommendation: yes,** after your look at its destar
   crops. Default: M1.2d/M1.7 wait for it; waves 1–3 proceed.
7. **Q7: map content after the switch.**
   - CNS5 + bright within 25 pc (~6k stars; α Cen is the R1 destination).
   - Or also the medium tier (50k stars to ~170 ly).

   **Recommendation: 25 pc for R1.** Default: that.
8. **Q8: default exposure (design open question 4, still open).**
   Dark-adapted naked eye (physically faithful; AC8 applies to it), or
   camera-like? It is needed at R-d. **Recommendation: dark-adapted naked
   eye, with camera-like as a labelled setting.**
9. **Q9: forward CMB in M1 or after?** **Recommendation: in M1 (M1.8),**
   because D-11 says it must be rendered, the planner allows γ 707, and M4
   then needs no "not yet rendered" text. It doesn't gate bar clause 1's
   AC1–AC10, so if time presses it can land after M1.5b. Default: in M1, as
   wave 6.

## Notes

- The executor updates only `passes`, `started`, `completed` and `notes` in
  the JSON. Evaluations go to `.ailang/state/evaluations/`.
- Every AILANG bug or DX papercut goes to `ailang messages` inbox `user`,
  `--from stapledons_godot`, with `AILANG_STORAGE_MESSAGING=gcp` and
  `AILANG_MESSAGES_PROJECT=ailang-multivac`.
- Unrelated hygiene noticed while planning, not in this sprint: the
  `R1-M1-SKY` JSON still says `teffFromBV` ships in 0.4.0; the design doc's
  M1.2d text says "next free minor" (correct).
