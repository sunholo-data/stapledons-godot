# Sprint plan: R1-M3-BLACK-HOLES (M3, black holes, bar clause 3)

**Status:** **Approved by Mark, attended 2026-10-08 (ledger D-53)**: as drafted; Sgr A* non-spinning with mass a scenario parameter (spin later); standing go to publish sunholo/relativity 0.10.0 once M3.1b passes its evaluation, a clean `pkg quality` and a dry run; lens tables in the public bucket with sha256 pins. Execution starts with wave 1. Plan review round 1 (Sonnet, `sprint-evaluator`): **84/100 PASS**, 0 blocking. All nine findings are folded in below; see [Review round 1](#review-round-1-what-changed).
**Design doc:** [`m3-black-holes.md`](m3-black-holes.md) (drafted and attended 2026-10-01; open questions ruled by ledger D-13 and D-11; reality-checked against `df7c041` for this plan, see its § "Reality check 2026-10-08").
**Sprint JSON:** `.ailang/state/sprints/sprint_R1-M3-BLACK-HOLES.json`
**Bar clause 3:** the shadow is within 0.5 px of Synge's formula at 10, 5 and 3 r_s. The weak field is within 1 % of 2r_s/b at b = 1000 r_s and within 3e-4 of the second-order series at b = 100 r_s. The Einstein ring is at the predicted angle. The geodesic integrator ships in `sunholo/relativity`.
**Player-facing target (D-52):** the unified 3D painted ship. The lensed sky renders through `InteriorSky` (`interior/interior_sky.gd`), which is the sky the default launch's `demos/ship_geometry_demo.gd` shows, using `sky/background.gdshader` and `sky/starfield.gdshader`. The retired `--interior` composite and the `main.gd` voyage are not targets.

## Summary

Ship null geodesics in `sunholo/relativity` **0.10.0** (package first). Then generate a deterministic 2D lens table on the strict VM, mirror it in GDScript, and add a pure GR mode to the sim (protocol 2.6, scenario `sgr_a`). Lens the per-pixel sky and the catalogue stars on the GPU with goldens, and put the player in the 3D ship hovering and orbiting Sgr A*, with a HUD that only formats the sim's values.

- **Size:** 11 milestones, **≈3,720 LOC** (2,060 code + 1,660 tests and tools), +25 % contingency.
- **Duration:** 12–16 agent sessions, about 6–8 working days of wall clock. Mark is needed at three points: approval, the GPU golden and render inspection (M3.5a, M3.5b, M3.6), and **an explicit go for the irreversible package publish (M3.1p, Q6)**.
- **Risk:** medium-high. The physics is prototyped and its numbers are known. The risk sits in the VM table run, GPU precision near the shadow edge, and performance of the 331k-star second image pass.

## Current status analysis (grounded in `df7c041`)

| Design doc assumption (2026-10-01) | Now | Consequence for the plan |
|---|---|---|
| `sunholo/relativity@0.3.0`; M3 takes "next free minor, planned 0.5.0" | The game pins **0.9.0**. 0.4.0–0.9.0 have shipped. The only open package PR is #95 (0.8.1, a fix). | M3 publishes **0.10.0**. `$V` = 0.10.0 throughout. |
| Package checks numbered check41–check53 in `relativity_test.ail` | Since 0.6.0, tests are named `checkXxx()` functions in per-module test files (`approach_test.ail`, …). Global numbering ended at check40. | `geodesic_test.ail` and `schwarzschild_ext_test.ail` use named checks. The doc's check41–53 survive as labels in the test titles, so lore front matter can cite them. |
| New `hoverPowerPerKg` | `medium.hoverPower(mEffKg, gMs2)` exists (HB-90). | `hoverPowerPerKg(m, r) = hoverPower(1.0, hoverAccelSI(m, r))`: reuse, not a second formula. |
| Protocol "additive to v1.1", `bh_enter` and similar commands | Protocol **v2**, with minors up to 2.5 (`departureMinor`). Games start with `new_game {scenario}`. Actions are `Intent`s. | GR is **protocol 2.6** (`grMinor() = 6`): scenario `sgr_a`, intents `gr_approach`/`gr_hover`/`gr_orbit`, a `gr` state section. Clients below 2.6 see nothing new, so every replay golden is unchanged. |
| Player view is `make run -- --bh` in `main.gd` | D-52 (2026-10-08): the default launch is the 3D ship. Its HUD reads "GR not implemented" (`ship_geometry_demo.gd:296`). | M3.6 builds the demo into the 3D ship: the navigation menu entry and `make run-bh`. `main.gd` gets only the `--golden` hook. |
| M1.4c, M1.6b, M1.3, M1.5 are future dependencies | All have landed (`sprint_R1-M1-SKY-2.json`: M1.3, M1.6b, M1.5a, M1.8 `passes: true`; `background.gdshader` is per-pixel). | Nothing in M3 waits on M1. The debug grid stays as the golden background only. |
| `tools/pack_lens_lut.py`, `tools/render_diff.py` | CLAUDE.md: a Python pipeline step is a defect. `writeFileBytes` plus the F32 encoder exist in AILANG (`sim/tools/catalogue_main.ail`). | The packer is AILANG (`sim/tools/lens_lut_main.ail`). The render diff is Godot (`tools/render_diff.gd`). Python appears only as the oracle `tools/geodesic_ref.py` (role `oracle`, allowlisted). |
| AILANG v0.50.0; WD-2 implementation rules | Pinned to **v0.52.0**. Nested cons and the like are fixed. **#1576** is open: the VM silently drops a service request whose handler builds a list of 1100+ elements by non-tail recursion. | Table rows are built tail-recursively, or with `std/array`, and never by non-tail list building. The 400-ray VM timing is re-measured first (M3.2 task 1). |
| Lens tables committed to git (~8 MB) | D-18: large assets live in the public bucket, pinned by sha256. | Decision Q2 (recommended: bucket and pin, `make lens-assets`). |
| Canon premise | Since 2026-10-06 every run opens at the **rogue spinning stellar-mass hole** (Kerr, ergosphere), not at Sgr A*. | M3 stays Schwarzschild at Sgr A* (D-13; Kerr is a non-goal). The renderer and sim are mass-parametric, so a rogue-hole view at a tidally safe radius is a scenario parameter. Decision Q3. |

**Velocity.** In the last 7 days, 420 non-merge commits touched about 50k lines of `*.gd`/`*.ail`/shaders (much of it generated data and art plumbing, so this overstates it). Comparable physics milestones: PR #151 (M4.6 ungated: check values and lint, +263) took 1 h 20 m to merge including evaluation. PR #92 (M4.1 step 1, sim and protocol, +873) took one session. PR #146 (TRAPPIST-1 planets, renderer and sim, +1,052) took about 2 h. The sustained rate is **one 300–700 LOC milestone per agent session**, including test-first work and an evaluator round. GPU-golden milestones run at about half that rate, because the golden needs the Studio GPU shell and a person to inspect the renders. The plan budgets about 350 LOC per session, with 25 % contingency.

## Registry reuse audit

Searches (`runtime/bin/ailang pkg search`, v0.52.0, 2026-10-08): `geodesic`, `black hole`, `lensing`, `elliptic`, `carlson`, `ode rk4` and `integrator` return nothing. `schwarzschild` returns only `sunholo/relativity@0.9.0`.

| Milestone | Package | Action | Reason |
|---|---|---|---|
| M3.1a | sunholo/relativity | contribute | Closed forms extend its `schwarzschild` module. The hover power reuses `medium.hoverPower`. |
| M3.1p | sunholo/relativity | contribute | Release and publish 0.10.0. |
| M3.1b | sunholo/relativity | contribute | New `geodesic` module. Bar clause 3 requires the integrator to ship in this package. No registry package has an ODE or elliptic integral. |
| M3.1c | sunholo/relativity | depend | Pin 0.10.0. |
| M3.2 | sunholo/relativity | depend | The table generator calls `geodesic`. The F32 writer reuses the in-repo `sim/tools/catalogue_bytes.ail`. |
| M3.3 | sunholo/relativity | depend | GDScript mirror; the values are pinned from the package tests. |
| M3.4a | sunholo/relativity | depend | The sim composes the package's clock, orbit, tide and hover forms. No maths of its own. |
| M3.4b | none | none | The protocol codec is game-specific (`sim/protocol.ail`). The searches above found no protocol package. |
| M3.5a | none | none | Godot shader and include; it mirrors M3.3. |
| M3.5b | none | none | Godot star path; it mirrors M3.3. |
| M3.6 | none | none | Godot scene and HUD wiring, plus Godot render diff. |

## Milestones

Dependency graph: **M3.1a → M3.1b → M3.1p (publish) → M3.1c → {M3.2, M3.4a}**. M3.4a may be *developed* against a local path dependency on the M3.1a forms while M3.1b/M3.1p are under evaluation. It is *pinned and merged* only after M3.1c. Then **M3.2 → M3.3 → M3.5a → M3.5b**, and **M3.4a → M3.4b**. M3.6 needs M3.4b and M3.5b. M3.4a/M3.4b run in parallel with M3.2/M3.3.

`$A` = `runtime/bin/ailang` (v0.52.0). `$PKG` = a fresh `ailang-packages` clone at `packages/relativity`, in the clone's ignored scratch dir.

### M3.1a: package closed forms (schwarzschild additions, tides, hover) ✅ (done 2026-10-08, ailang-packages #103)
- **What:** add to `schwarzschild.ail`: `impactFromStaticAngle`, `turningRadius`, `weakDeflection2`, `weakDeflectionFinite`, `strongDeflectionBbar`, `circularOrbitSpeed`, `circularOrbitClockRate`, `orbitalAngularVelocity`, `movingClockRate`, `radialCoordinateRate`, `hoverAcceleration`, `rsPerSolarMassMetres`, `tidalRadial`, `tidalTransverse`, `tidalRadialOrbit`, `tidalAccelSI`, `hoverAccelSI` and `hoverPowerPerKg` (via `medium.hoverPower`). Each gets `requires` where the domain is restricted. Also `tools/geodesic_ref.py`, written first. It lives in **this game repo**, with role `oracle` in `tools/python-allowlist.txt`, and reproduces design rows V9–V16. The package tests pin its printed values as literals, so the package's own CI never calls Python. Wiring: a `make geodesic-oracle` target runs `--check` and `digest 16`, and is added to `test` and `.PHONY`.
- **Tests first** (`schwarzschild_ext_test.ail`): check49 (clock and orbit), check51 (tides, HB-72…86), check52 (inversions, HB-75, HB-87), check53 (hover, HB-88…90), weakDeflection2 at b = 100.
- **LOC:** 190 + 200 = **390**. **Depends on:** nothing.
- **AC:** `cd $PKG && $A test --package .` passes, including every earlier test. `$A run --bytecode --strict-bytecode` of the new smoke entry equals the interpreter (`cmp`). `make geodesic-oracle` passes (in this repo) and `make python-guard` is green.

### M3.1b: package `geodesic` module and digest ✅ (done 2026-10-08, #103; eval 91/100 PASS)
- **What:** `geodesic.ail`: `binetStep`, `escapeAzimuth` (tail-recursive RK4 with a cubic-Hermite end root; capture decided analytically and asserted), `lensDeflection`, `deflectionFromInfinity`, `carlsonRF` (fixed iteration cap, NaN-guarded), `deflectionExact`, `escapeAzimuthExact`, `lensRegular`, `imageAngle`, `einsteinAngle`, `imageMagnification`, and `inverseRow` (Fritsch–Carlson monotone inversion of a 16k-sample forward row, built as an array). `_smoke.ail` gets `lensDigest(n)`. *(The release work moved to M3.1p.)* The release adds `CHANGELOG ## 0.10.0` (methods, oracle, accuracy, the 1.5 % weak-field fact), `AGENT.md` (the integrator for tools, the exact form for checks, never per frame), `[release] kind = "feature"`, the `[exports]` row and the ai_summary.
- **Tests first** (`geodesic_test.ail`): check41–48 and check50 from the design doc. Python oracle values are pinned to 1e-12, or as tabulated.
- **LOC:** 310 + 260 = **570**. One PR on `ailang-packages` (module + tests + digest). **Depends on:** M3.1a.
- **AC:** AC-1. AC-3: `lensDigest 16` is bit-identical between strict VM and interpreter (`cmp`) and within 1e-9 of `tools/geodesic_ref.py digest 16`. AC-8 (package half): check42 and check43.
### M3.1p: release and publish 0.10.0 ✅ (published 2026-10-08 under D-53)
- **What:** `CHANGELOG ## 0.10.0`, `AGENT.md`, `[release] kind = "feature"`, `[exports]` adds `sunholo/relativity/geodesic`, ai_summary, then the dry run, then the publish.
- **LOC:** 70 + 60 = **130**. **Depends on:** M3.1b evaluated PASS **and Mark's explicit go (Q6)**. The recorded standing approval covers only the public asset bucket, not the package registry, and a publish is irreversible.
- **AC:** AC-2: `$A pkg quality .` exits 0 with no gates; `$A publish --dry-run`; `$A publish`; `ailang pkg info sunholo/relativity | grep -E "0.10.0|geodesic"`.

### M3.1c: pin 0.10.0 in the game ✅ (done 2026-10-08)
- **What:** `sim/ailang.toml` → 0.10.0; `ailang install` then `ailang lock` (the CLAUDE.md workaround); the `make runtime` cache. `relativityPin()` is hardcoded to "0.9.0" today (`sim/protocol.ail:59`) and used in the minor 4 and 5 hellos (`:63–64`). Split it the way the 0.4.0 string already is. A new constant keeps "0.9.0" for minors 4–5. `relativityPin()` returns "0.10.0" only at minor ≥ 6. `make hello-pin` is updated to tie the **highest** minor's string to `sim/ailang.toml`. The literals at `sim/navigation_test.ail:290` and `tests/test_sim_bridge.gd:392` stay "0.9.0", because they test minor 4/5, and the test names say so.
- **LOC:** 20 + 30 = **50**. **Depends on:** M3.1p published.
- **AC:** AC-4: `grep '"0.10.0"' sim/ailang.toml && make deps`. `make hello-pin` passes. `make test` is green with no replay golden changed (`make replay parity parity-v2`).

### M3.2: lens tables on the strict VM (`lens_fwd`, `lens_inv`) ✅ (done 2026-10-08, wave 2A)
- **What:** `sim/tools/lens_lut.ail` (pure, strict) generates the 2048 × 256 forward table (x = ln((ψ−α_sh)/α_sh), y = ln(r−1.5) over [0.5, 10⁶−1.5]; R = `lensRegular`, G = dδ/dx) and the inverse table (F ∈ [−π, π]; R = ψ−α_sh, G = dψ/dF). `sim/tools/lens_lut_main.ail` writes little-endian F32 through the `catalogue_bytes` encoder plus a JSON header (layout, ranges, package version, h, sha256), with rows built tail-recursively because of #1576. Make targets: `lens-lut` (full, manual, timed into the report), `lens-lut-check` (in `make test`: every 64th column of every 32nd row regenerated bit-identically; row 128 cols 0–63 equal on VM and interpreter), and `lens-assets` (per Q2). **Assets (B-1):** `data/lens/SHA256SUMS` pins both binaries and headers. `lens-assets` fetches them from `gs://stapledons-voyage-assets/lens/<sha256>.bin` in seconds. If the bucket lacks them, it regenerates on the VM (about 7 min) and checks the pins; if the regenerated bytes do not match, it fails loudly. `lens-publish` (maintainers, gcloud, never overwrites) uploads them, as `sky-publish` does. `lens-assets` becomes a prerequisite of `test` and `physics`, next to `starmap-assets`. **Wiring (N-8):** `sim/ailang.toml [exports]` gains `stapledons/sim/tools/lens_lut` and `lens_lut_main`; `.PHONY` and `test` gain `lens-lut-check`; `.gitignore` covers `data/lens/*.bin` if Q2 goes to the bucket.
- **Task 1:** re-measure the 400-ray benchmark on the v0.52.0 VM. If the extrapolated full run is over 60 min, swap the generators: `escapeAzimuthExact` generates and the integrator cross-checks (spec §3 as amended by D-13).
- **LOC:** 200 + 110 = **310** (plus about 8 MB of data, not counted). **Depends on:** M3.1c.
- **AC:** AC-6 `make lens-lut-check`. On a clean checkout (`rm -f data/lens/*.bin`), `make lens-assets && make physics` passes. The full-run wall time is recorded. `make strict` still passes. Any VM/interpreter divergence is reported upstream with a repro (CLAUDE.md, GCP store).
- **As built:** ✅ AC-6 `make lens-lut-check` (297 sampled forward texels and 9 whole inverse rows bit-identical; row 128 cols 0–63 strict VM = interpreter = the bin bytes; ~95 s). ✅ Clean checkout `rm -f data/lens/*.bin && make lens-assets && make physics`: fetched in under 1 s, 726 passed. ✅ Wall time: 436 s with 14 parallel VM jobs (`make lens-lut`); task 1: 5 s per 2,048-ray row at h = 0.005, so the integrator stays the generator. ✅ `make strict` green. ✅ No VM/interpreter divergence; one DX report upstream (`std/fs` evaluator-only under `--strict-bytecode`). Deviations, in the design doc's dated note: h = 0.0025 (accuracy at the shadow edge), sharded generation, headers committed and bins in `gs://stapledons-voyage-assets/lens/`.

### M3.3: CPU mirror `physics/schwarzschild.gd` ✅ (done 2026-10-08, wave 2A)
- **What:** `class_name Schwarzschild`, float64 scalars: `shadow_angle`, `static_blueshift` (test-only), `load_tables`, `deflection(r, ψ)` (bilinear in x and Catmull-Rom in y, plus the analytic singular part, with the weak branch beyond 10⁶), `lens_direction`, `star_images`, `compose`. A new "Schwarzschild (spec §3)" section in `tests/test_physics.gd`: RS-9…RS-21, Einstein angles (check46), images and μ (check47), the D-13 weak-field pair on the r → ∞ column, every texel finite, `lens_inv` strictly monotone per row, header sha256, and a 1,000-pair round trip within 2e-4 rad. *(As built: the round trip holds 2e-4 rad in the source plane for images with dψ/dF ≥ 1e-3 and in the image plane for all; the forward table uses h = 0.0025, not 0.005. See the design doc's M3.2 as-built note.)*
- **LOC:** 230 + 230 = **460**. **Depends on:** M3.2.
- **AC:** AC-5 and AC-8 (mirror half) and AC-9 (CPU half) via `make physics`. `make lint-precision` stays clean.
- **As built:** ✅ AC-5 (worst 1.14e-5 rad at r ≤ 100; 1.7e-4 relative above, absolute 1.2e-9 rad near the antipode where δ → 0). ✅ AC-8 mirror half (0.1475 % at b = 1000; 2.690e-4 at b = 100 on the r = 10⁶ row). ✅ AC-9 CPU half (ψ_E at 10, 5, 3, 100, 1000 within 1e-7 rad, exact mirror; within 1.2e-4 rad from `lens_inv`). ✅ RS-9…RS-21, check41–47 pinned. ✅ Round trip (source plane for the 1,531 images with dψ/dF ≥ 1e-3, image plane for all 2,000). ✅ `make lint-precision` clean. The mirror also carries the exact form (Carlson R_F, Gauss–Legendre), pinned to the package's check values, as the oracle for the table.

### M3.4a: pure GR core (`sim/gr.ail`) ✅ (done 2026-10-08, wave 2B; eval 88/100 PASS)
- **Done:** `scriptedApproach(100)` within 1.1e-15 relative of the closed form, strict VM = interpreter; `grVm` in `make strict`; AC grep clean. Eval: `.ailang/state/evaluations/eval_R1-M3-BLACK-HOLES_M3.4_round_1.json`.
- **What:** `GrState` (active, mass, r, mode, betaLocal, phase, holeDir, bubbleRadiusM, mEffKg). Ship-proper-time steps for hover (rate `staticClockRate`), orbit (`circularOrbitClockRate`, phase by `orbitalAngularVelocity`) and approach (RK4 on `radialCoordinateRate`, stopping exactly at the target). `motion.tau` and `motion.t` accumulate. A strict entry `scriptedApproach(n)` checks against the closed form t = [r₁−r₂+ln((r₁−1)/(r₂−1))]/β. The tide and hover readouts compose package functions only. Wiring: `stapledons/sim/gr` and `gr_test` go in `sim/ailang.toml [exports]`, and the `scriptedApproach` row goes in the `strict` target.
- **LOC:** 170 + 140 = **310**. **Depends on:** M3.1c (parallel with M3.2/M3.3).
- **AC:** `make strict` (new `scriptedApproach` row within 1e-9, VM = interpreter). `gr_test.ail` asserts AC-11's numbers (static clock to ±1e-15; tide and power to ±1e-3 relative). `! grep -nE "1\.5 \* u \* u|acos\(-3" sim/*.ail`.

### M3.4b: protocol 2.6, scenario `sgr_a`, archive events, parity ✅ (done 2026-10-08, wave 2B; eval 88/100 PASS)
- **Done:** minor 6; `make parity-gr` (VM = interpreter, bh_enter → bh_hover → bh_ring, mass 4297000); replay goldens unchanged. Added refusal `in_gr` and the client intent `gr_ring`; `bh_mass_msun`/`bh_r` params (D-53).
- **What:** `grMinor() = 6`. The `new_game` scenario `sgr_a` (Sgr A*: 4.297e6 M☉, r = 10⁶, the galactic position of Sgr A*, params `bubble_radius_m` and `m_eff_kg` reused from `Params`). Intents `gr_approach {to_r, beta_local}`, `gr_hover`, `gr_orbit`. Reason codes `bad_radius` (outside [2, 10⁶]), `bad_gr`, `not_in_gr`, `moving`. Each refusal leaves the state unchanged. A `gr` section in the state at ≥ 2.6. Archive events `bh_enter`, `bh_hover` (r ≤ 10) and `bh_ring` (a client-reported intent the first time the ring-star path fires, echoed by the sim so the replay holds it). `tests/fixtures/gr.ndjson` covers every intent and reject. Make target `parity-gr`. `SimBridge.GR_MINOR`, `parse_gr()`.
- **LOC:** 170 + 160 = **330**. **Depends on:** M3.4a.
- **Wiring:** `parity-gr` goes in `test` and `.PHONY`.
- **AC:** AC-11 and **AC-15 (sim half)**: `make sim strict parity parity-offaxis parity-gr replay`. The archive events `bh_enter`, `bh_hover` and `bh_ring` appear in order in the `parity-gr` output (`grep -c '"archive"'`), and the fixture's `sgr_a` game reports mass 4.297e6. The GR fixture is VM = interpreter byte for byte, and all lower-minor goldens are unchanged.

### M3.5a: GPU lensed sky in `InteriorSky` (shadow, debug grid, SR composition) ✅ (done 2026-10-08, wave 3)
- **What:** `sky/schwarzschild.gdshaderinc` mirrors M3.3 function for function. `background.gdshader` gains a `gr_on` branch: de-aberrate to the static frame using the sim's γ and 1−β, then the analytic capture test (black), then the table lens (galaxy-frame n_∞, `SkyFrame`), then the photo or **debug grid** (uniform `grid_on`), then D = D_g·D_SR into the existing LUT path. Mip selection uses dδ/dx. `SkyBackground` and `InteriorSky` get `set_gr(state)`, which uploads only the sim's `gr` fields. `tools/gr_golden.gd` is run by `main.gd --golden` and drives an `InteriorSky` sky-only with a linear tonemapper and glow off at 960 × 540: GR1–GR3 (shadow radius), GR4 (orbit mask; yaw, pitch and the rolled M1.6b orientations), GR7 (black inside), GR8 (chromaticity at 3 r_s).
- **LOC:** 240 + 170 = **410**. **Depends on:** M3.3.
- **Inspection:** `make capture-bh-sky` (this milestone's subset: the debug-grid shadow at 10, 5 and 3 r_s, toward the hole, hover) writes the renders. The person who opens them records `opened by <name> <date>` in the sprint JSON notes for this milestone.
- **AC:** AC-7 and the GR4 and GR8 parts of AC-10 via `make golden`; `jq -r '.features[] | select(.id=="M3.5a_GPU_LENSED_SKY") | .notes' .ailang/state/sprints/sprint_R1-M3-BLACK-HOLES.json | grep 'opened by'`. The Makefile golden grep gains exact counts (`^ok    GR1`… and `gr golden: 0 failures`). With `gr_on = false`, the existing CMB, exposure and G-M4 cases are unchanged (same counts, same results). The precision lint is clean.

- **As built:** ✅ AC-7: `make golden` GR1/GR2/GR3 radius 98.065 / 202.408 / 189.050 px against Synge's 98.066 / 202.398 / 189.056 (errors 0.001 / 0.010 / 0.006 px, limit 0.5); GR7 peak inside the shadow 0.00000 under a ×20 sky with stars behind and astern. ✅ GR4: the orbit mask (r = 5, β_local 0.35355) equals `Schwarzschild.compose`'s capture test pixel for pixel at three orientations (yaw/pitch, off-axis, rolled): 0 mismatches, centroid offset 0.000 px. ✅ GR8: chromaticity 0.0001 from rgb(1.22474 × 5700 K) (the unshifted colour is 0.056 off). ✅ The golden grep carries exact GR counts and `gr golden: 0 failures`; every pre-existing count is unchanged and green (`gr_on = false` default). ✅ CPU test: the hi/lo pair reconstructs α_sh to < 1e-12 (r 2 … 2e6), both halves float32. ✅ `make lint-precision` clean. ✅ Renders: `make capture-bh-sky` → `renders/bh_sky/` (opened; see the sprint JSON notes). Added beyond the plan: **GR10/GR11, the exact table mirror** — a golden-only probe writes the shader's float32 δ, ψ − α, image ψ and F as bits, and the CPU mirror recomputes each pixel: δ within 2e-5 relative (worst 0.33 of that) at r = 2.01, 2.05, 10, 3e5, 9.9e5, toward and away; image ψ likewise (worst 0.02) at r = 2.01, 10, 9.9e5, 2e6. Each of the three wave-2A rules, mutated (x-linear weight; repeated end row at either end), fails GR10 and/or GR11. Deviation (float32 conditioning, found by GR10/11): the per-r column grid goes up as a 2048-texel float64-formed texture of ψ_i − α (`GrLens.column_offsets`), and the column fraction is carried as (i0, f), never i0 + f; lens_inv's fraction is (F − F_i0)·k (the Metal compiler re-associated `(1023.5 − i0) + F k`). Images within the shadow-edge band are checked in the image plane (GR5, GR11), per the M3.3 dated note.

### M3.5b: lensed stars, secondary images, ring stars ✅ (done 2026-10-08, wave 3)
- **What:** `starfield.gdshader` gets one `#include` and an `image_order` branch: β → ψ_k from `lens_inv`, re-aberrate, flux μ·Y(DT)/Y(T)/D_SR². A second `MultiMeshInstance3D` shares the multimesh (order 1) and exists **only while GR is active**. The ring-star path: stretch > 8 sends the star to a uniform array of ≤ 64 Gaussians in the sky pass, evaluated in the source plane. Overflow keeps the brightest 64 and reports the count. Goldens GR5 (two-image centroids at three geometries), GR6 (ring radius at r = 10, 100, 1000) and GR9 (weak-field hand-off at 9e5 and 2e6). A CPU test of the μ = 1, D_g = 1 limit equal to `point_flux_ratio`.
- **LOC:** 220 + 170 = **390**. **Depends on:** M3.5a.
- **AC:** AC-9 (GPU half) and AC-10 via `make golden`. The ring renders (r = 10, 100, 1000) are opened, recorded as `opened by <name> <date>` in this milestone's sprint-JSON notes, and checked by the same jq/grep. `make bench TIER=large` with GR off is within 5 % of the last M1.3 baseline; GR on is recorded (Q4).

- **As built:** ✅ AC-9 GPU half: GR6 ring radius 221.091 / 57.773 / 17.572 px against f·tan ψ_E 221.088 / 57.769 / 17.539 (errors 0.003 / 0.004 / 0.032 px, limit 0.5), ring-star path taken, azimuthally uniform (brightest of 36 bins ≤ 1.19 × the mean; this check caught a lost ring flag when the star set changed, now fixed by tracking `identity_revision`). ✅ AC-10: GR5 both images at β 20/60/120° and r 10/5/3 within 0.083 px; GR9 at r = 9e5 (tables) and 2e6 (weak branch) within 0.158 px. ✅ CPU test: μ = 1, D_g = 1 equals `point_flux_ratio` exactly; ring cones bracket stretch = 8 at r = 3, 10, 1000. ✅ `make bench TIER=large` (Studio M4 Max, load ~3): GR-off flight p50 8.471 / 8.410 ms (Metal / Vulkan) against 8.481 / 8.450 measured on origin/main in the same session (−0.1 % / −0.5 %), p99 10.98 / 11.08 against 10.96 / 10.90; Vulkan star pass p50 0.33 ms. GR on (r = 10, 335,189 stars, both images, ring path; static sweep): frame p50 8.04 / 8.13 ms, p99 9.96 / 10.19 ms, 0 frames over 16.7 ms; viewport GPU p50 1.99 ms against 0.99 ms GR off. No restriction of secondary images is needed (Q4). The ring-star candidate sweep costs 33 ms for the whole tier at once, so in play it runs in 10,000-star slices (~1 ms per frame) only after the hole direction moves 0.5° or the ship or catalogue changes; a new hole's ring set therefore lags by ~34 frames (about 0.6 s), during which its ring stars draw as μ-capped splats. ✅ Ring renders opened (sprint JSON notes). **Evaluation round 1 (Sonnet): 90/100 PASS**, five non-blocking findings, all addressed: F1 `set_gr` was a full ring reselect every frame (2.4–3.1 ms CPU measured by the evaluator) → now a no-op for an unchanged state (bench `set_gr + tick` p50 0.03 ms) and incremental otherwise (approach r 10 → 3 every frame: p50 0.14 ms, p99 5.1 ms when the cones are recomputed, every 1 % of r); `make bench` gained the per-frame and approach sweeps. F2 Mark opened the renders, attended 2026-10-08: "they look great" (refs `gs://stapledons-voyage-assets/refs/m3_bh/`). F3 the mutants are in-tree: `gr_mutant` (golden-only uniform) and **GR12**, which asserts that each broken rule fails GR10 (90×, 2448× and 166× its limit). F4 the hand-off checks are split and the identity is labelled a derivation check. F5 `GrLens.set_gr` refuses r < 2 or a non-finite shadow (GR off, warning); the sweep latency is stated above.


### M3.6: Sgr A* aboard the 3D ship (HUD, keys, renders, report) ✅ (done 2026-10-08)
- **What:** in `ship_geometry_demo.gd`, the navigation menu gets "Sgr A* (black hole)". `_create_navigation("sgr_a")` asks for minor 6, and `make run-bh` launches `--ship-demo --scenario=sgr_a`. Keys run approach 10⁶ → 10 at β 0.1, then hover, then 5 → 3, then orbit (keys documented in the controls hint). The HUD replaces "GR not implemented" with lines formatted **only** from `sim.state["gr"]`: mode, r/r_s, static clock, "1 ship-hour = … home hours", shadow half-angle, blueshift, β_local, tide across the bubble, and hover acceleration "not felt (bubble)" with power per kg, or "free fall: 0 W" in orbit. Also the caption about the sky "as seen from Sol" (design OQ5 default). There is a no-star lighting fallback for the ship geometry (no system section at Sgr A*). The archive events reach the M4.7 codex. `make capture-bh` writes `renders/bh_r{10,5,3}_{toward,side,away}_{hover,orbit}.png` (sky-only, via `look_direction` plus `toggle_sky_only`), two in-ship bridge views, and contact sheets on the debug grid and the Milky Way. `tools/render_diff.gd` (Godot) diffs against the pinned set at a mean of ≤ 1/255. **Baseline (N-3):** the first `make capture-bh` writes `renders/bh_*` and `renders/bh_manifest.sha256`. A person opens them, and a reviewed commit pins the manifest. Later runs diff against that commit's set. **Wiring (N-8):** Makefile targets `run-bh` and `capture-bh` (plus `.PHONY`); `ship_geometry_demo.gd` parses the new `--scenario=sgr_a` user argument, since today `_create_navigation` takes only an internal string; and the golden grep gains the exact GR case counts. The report goes to `design_docs/implemented/r1/m3-report.md`.
- **LOC:** 240 + 130 = **370**. **Depends on:** M3.4b, M3.5b.
- **AC:** AC-12: the HUD sentinel test in `tests/test_ship_demo_live.gd` or a new `tests/test_bh_hud.gd` under `make sim`, plus `! grep -rnE "sqrt\(1(\.0)? *- *1(\.0)? */ *r" demos ui sky bridge interior`. AC-13: `make capture-bh && godot --headless --script tools/render_diff.gd renders/bh_*` and `grep -n "opened by" design_docs/implemented/r1/m3-report.md`. AC-14: `make test` is green locally and in CI. AC-15 (client half): the codex shows the three black-hole Archive entries after the scripted demo (`tests/test_bh_hud.gd` asserts the unlocks).
- **As built:** ✅ AC-12: `make bh-hud-test` (in `make sim`): HUD sentinels (every shown number moves with its `gr` field; no section, no lines), the HUD equals `BlackHoleVisit.hud_lines(sim.gr)` at every stop, and the grep is clean in demos, ui, sky, bridge and interior. The grep caught M3.5's `sqrt(1.0 - 1.0 / r) / r` in `sky/gr_lens.gd`; it now calls the mirror's `Schwarzschild.weak_k(r)` (= 1 / impact(r, π/2), checked in `make physics`; GR9 unchanged at 0.158 px). ✅ Way in: navigation window entry "Sgr A* (black hole) · demo", a HUD button, `make run-bh` (`--ship-demo --scenario=sgr_a`, parsed by `ship_geometry_demo.gd` and `main.gd`); the title screen was left alone (its six-button test pins the menu). ✅ Keys N (next stop: 10⁶ → 10 at β 0.1, 5, 3, orbit at 3, hover), K (finish an approach), C (codex), L (leave; GR off), in the controls hint. ✅ The sky caption "as seen from Sol" (OQ5); stars placed from Sol under GR (`InteriorSky.gr_stars_from_sol`). ✅ No-star lighting: no emitter at Sgr A*, the moody key returns (tested). ✅ AC-13: `make capture-bh` → 40 renders (18 Milky Way, 18 grid, 2 bridge, 2 sheets), opened by Claude (sprint executor, Opus 5.5) 2026-10-08 (see `design_docs/implemented/r1/m3-report.md`); baseline pinned in `data/refs/bh_manifest.sha256`, served from `gs://stapledons-voyage-assets/refs/m3_bh_ship/` (`make bh-refs`); `make bh-render-diff` worst 0.000/255 (two captures byte-identical). Deviation: renders are not committed (`renders/` is ignored; D-18 keeps binaries in the bucket); the manifest is. ✅ AC-15 client half: the codex opens *Tides* and *The Shadow and the Ring* at the first hover; the Archive events arrive bh_enter → bh_hover → bh_ring (the real ring path fires `gr_ring` in `make capture-bh`). The lore has two black-hole entries, so the "three" are the events. ✅ `make bench-bh` (1920 × 1080, large tier): GR on costs ~+2 ms Vulkan sky GPU (2.05 → 3.85–4.23 ms p50); wall p50 8.3–9.1 ms either way; live orbit p99 ~14 ms; Metal reports no GPU time. ✅ `make golden` green; `make test` green locally. Report: `design_docs/implemented/r1/m3-report.md`.

### LOC summary

| ID | What | Code + tests | Depends on |
|---|---|---|---|
| M3.1a | Package closed forms, tides, hover; Python oracle | 190 + 200 = 390 | — |
| M3.1b | Package `geodesic` module, digest | 310 + 260 = 570 | M3.1a |
| M3.1p | Release + publish 0.10.0 (Mark's go, Q6) | 70 + 60 = 130 | M3.1b (eval PASS) |
| M3.1c | Pin 0.10.0, split hello pin | 20 + 30 = 50 | M3.1p (published) |
| M3.2 | Lens tables, VM generator, F32 writer, lut-check | 200 + 110 = 310 | M3.1c |
| M3.3 | CPU mirror + physics section | 230 + 230 = 460 | M3.2 |
| M3.4a | Pure GR core + strict entry | 170 + 140 = 310 | M3.1c |
| M3.4b | Protocol 2.6, `sgr_a`, parity-gr | 170 + 160 = 330 | M3.4a |
| M3.5a | Lensed sky shader + GR1–4, 7, 8 goldens | 240 + 170 = 410 | M3.3 |
| M3.5b | Star images, ring stars + GR5, 6, 9 | 220 + 170 = 390 | M3.5a |
| M3.6 | 3D-ship demo, HUD, renders, report | 240 + 130 = 370 | M3.4b, M3.5b |
| | **Total** | **2,060 + 1,660 = 3,720** | |

With 25 % contingency, about 4,650 LOC in the worst case. The total is above the design doc's 2,700. The difference comes from the AILANG packer replacing Python, the protocol-minor plumbing, the 3D-ship integration and the oracle.

## Bar clause 3: how each check is proven

| Clause | Proof (command) | Milestone |
|---|---|---|
| Shadow within 0.5 px of Synge at 10, 5, 3 r_s | `make golden` → `ok    GR1/GR2/GR3` (black-pixel radius √(N/π) vs f·tan α: 98.066, 202.398, 189.056 px) | M3.5a |
| Weak field: 1 % of 2r_s/b at b = 1000; 3e-4 of the series at b = 100 | `cd $PKG && $A test --package .` (check42, check43) and `make physics` (the mirror's r → ∞ column) | M3.1b, M3.3 |
| Einstein ring at the predicted angle | `make golden` → GR6 (ring radius vs f·tan ψ_E at r = 10, 100, 1000, within 0.5 px); `make physics` ψ_E at 10, 5, 3 vs check46 to 1e-7 rad | M3.5b, M3.3 |
| Geodesic integrator ships in `sunholo/relativity` | `ailang pkg info sunholo/relativity | grep -E "0.10.0|geodesic"`; `grep '"0.10.0"' sim/ailang.toml` | M3.1p, M3.1c |

The CLAUDE.md physics gates are covered: check values in `tests/test_physics.gd` (M3.3), a GPU-vs-CPU golden in `make golden` (M3.5a/b), inspected renders (M3.6), and maths in the package first (M3.1a/b before anything else). The strict core is checked by `make strict` (M3.2, M3.4a), parity by `make parity-gr`, precision by `lint-precision` and the finite-table tests, and determinism by the bit-identical regeneration and replay.

## What the player sees (3D ship)

From the navigation menu (M) or `make run-bh`, the ship starts 10⁶ r_s (1.34 ly) from Sgr A* and closes to 10 r_s. From the bridge, the forward sky shows a black disc 28.5° across ringed by the bright photon ring. The Milky Way-as-seen-from-Sol background is visibly warped into arcs, and a star directly behind the hole spreads into an Einstein ring at 29.8°. At 3 r_s the shadow fills 90° of the sky and incoming light is blueshifted ×1.2247. In orbit the shadow is aberrated sideways. The HUD reads the sim's numbers: "static clock 0.816497 · 1 ship-hour = 1.2247 home hours", "tide 2.11 × 10⁻⁴ g", "hover 4.9 × 10⁴ g, not felt (bubble) · 1.44 × 10¹⁴ W per kg of m_eff". The Archive's black-hole entries unlock.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| The full table on the v0.52.0 VM is slower than 7 min, or #1576-like silent drops appear | M | M3.2 task 1 re-measures. Over 60 min, swap generator and checker (D-13). Rows are tail-recursive or array-built. Divergences are shrunk and reported upstream, never relaxed. |
| Bilinear/Catmull-Rom table error is at the 1.2e-4 rad budget | M | AC-5 measures it. Fallback is 4096 columns (+4 MB). |
| float32 Δψ near the shadow edge on the GPU | M | Godot shader uniforms are float32, so there is no float64 uniform. The CPU passes α_sh as a float32 hi/lo pair formed in float64. Δψ = (atan2(|ĥ×n|, ĥ·n) − α_hi) − α_lo, which keeps Δψ to about 1e-7 rad near the edge. A CPU test asserts the pair reconstructs α_sh to 1e-12. Order ≥ 2 images are a stated non-goal (0.1 px from the edge). GR1–3 test the edge directly. |
| The second star instance doubles the 331k-star pass and costs fps | M | It exists only in GR mode. The bench is recorded. Fallback: order-1 images only for stars with ψ_k within 30° of ĥ (Q4). |
| GR branch regressions in `background.gdshader` break existing goldens | L | `gr_on = false` is the default. The `make golden` counts are unchanged and asserted. |
| The ship geometry's star lighting assumes a nearby star and a `system` section | M | M3.6 adds the no-star fallback, tested headless. |
| Package publish is irreversible | L | M3.1p runs only after the M3.1b eval passes, `pkg quality` is clean, the dry run passes, and Mark gives an explicit go (Q6). |
| Protocol drift between 2.5 and 2.6 work in flight (M4.3b re-plan per D-52) | M | GR fields are the contract. 2.6 is gated by minor, and whichever lands second rebases the minor number. |
| Ring-star PSF approximation where the lens map is non-linear | L | GR6 checks the radius. Total ring flux against Σμ goes in the report. The 64-star cap is logged. |
| Canon drift: the run opens at a rogue Kerr hole, not Sgr A* | M | Q3. The M3 maths and renderer are mass-parametric. Kerr stays a non-goal. |

## Questions for Mark (approval)

1. **Approve the plan** (11 milestones, ≈3,720 LOC, package 0.10.0 first, M3.4 in parallel with M3.2/M3.3)? *Recommended: approve.*
2. **Lens tables (~8 MB): in git, or in the public bucket pinned by sha256 like the sky textures (D-18)?** *Recommended: the bucket, with `make lens-assets` fetching it (or regenerating on the VM in about 7 min) and `lens-lut-check` in `make test`.*
3. **Premise fit:** canon (2026-10-06) opens every run at the rogue spinning stellar-mass hole. M3 is Schwarzschild at Sgr A* per D-13. *Recommended: keep Sgr A* for the bar and the demo. Make mass a scenario parameter so a "rogue hole at ≥ 2,500 r_s" view (tide < 0.1 g for ~10 M☉) is data, not code. Spin and the ergosphere emergence go to the time-skip/New Game+ milestone.*
4. **Performance budget with GR on:** is 60 fps at the large tier required in GR mode, or only with GR off? *Recommended: GR off must hold the M1.3 baseline. GR on is measured and reported; the fallback is to restrict secondary images to stars near the hole.*
5. **Design OQ5, the demo sky:** use the Sol-viewpoint Milky Way with an on-screen caption, and leave the true Galactic-Centre sky for later? *Recommended: yes (the doc's default).*
6. **Package publish:** may M3.1p publish `sunholo/relativity@0.10.0` to the registry once M3.1b's evaluation passes, or do you want to look at the release first? The recorded standing approval covers only the asset bucket. *Recommended: grant it with this approval, conditional on the eval PASS, a clean `pkg quality` and the dry run.*

## Review round 1: what changed

Evaluation `.ailang/state/evaluations/eval_R1-M3-plan_round_1.json` (Sonnet, `sprint-evaluator` plan review): **84/100 PASS**, no blocking findings. Every finding is addressed in this revision:

- **B-1 (near-blocking):** M3.2 now pins `data/lens/SHA256SUMS`, adds `lens-assets` (fetch, else regenerate on the VM, else fail loudly) as a prerequisite of `test` and `physics`, and adds `lens-publish`. A new AC runs it from a clean checkout.
- **N-1:** M3.1c splits the hello pin (0.9.0 for minors 4–5, 0.10.0 at ≥ 6), updates `make hello-pin`, and leaves the two minor-4/5 literals alone.
- **N-2:** the impossible "float64 uniform" is replaced by a float32 hi/lo pair, with a CPU test.
- **N-3:** the render baseline is a pinned manifest written on the first capture. M3.5a and M3.5b get `opened by` notes, each checked by jq/grep.
- **N-4:** the publish is now its own milestone, M3.1p, and needs Mark's explicit go (Q6).
- **N-5:** the oracle lives in this repo, the package pins its values as literals, and `make geodesic-oracle` is in `test`.
- **N-6:** the code subtotal is corrected to 2,060, and M3.1b is split (module 570; release 130).
- **N-7:** AC-15 is split into a sim half (M3.4b) and a client half (M3.6), consistent between the markdown and the JSON. M3.4a may be developed against a local path dependency before the publish.
- **N-8:** wiring is listed per milestone (`[exports]`, `.PHONY`/`test`, golden counts, `run-bh`/`capture-bh`, `--scenario=sgr_a`).

## Notes

- The executor follows CLAUDE.md: test-first, stops at each GPU golden for the attended Studio shell, never edits the decision ledger, and reports AILANG issues upstream.
- The evaluator is a different model from the executor (generator ≠ judge). There is one evaluation per milestone, plus one for the package release before publishing.
- Landing (design-repo edits: the `black-hole-mechanics.md:82` fix, the `black-holes.md` tidal row, the queue-row version note, the roadmap status) is listed in the design doc's Deliverables and runs after M3.6.
