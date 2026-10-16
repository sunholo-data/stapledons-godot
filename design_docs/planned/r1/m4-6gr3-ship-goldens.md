# Ship goldens G-M4-S2/S3/S4 (M4.6gR3)

**Status:** Planned (mission iteration 35, designer). **Release:** r1. **Milestone:** M4.6, gated half, round-3 sub-milestone M4.6gR3 (sprint `R1-M4-JOURNEY`, feature `M4.6_PHYSICS_GATES`).
**Priority:** P1. This is clause 4 of the R1 bar, in the form of AC10 for the 3D ship, and physics gate 2 for the scene the player actually gets. It is not a player-visible change.
**Implements:**
- [m4-first-journey.md](m4-first-journey.md) AC10 as amended 2026-10-12: G-M4-S2, G-M4-S3 and G-M4-S4 on the default 3D ship.
- [m4-first-journey-sprint.md](m4-first-journey-sprint.md) R3-4 (M4.6gR3) and the GPU half of R-M4.3b-1 (R3-2).
- [relativity-spec §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md#2-special-relativity-moving-observer-flat-space): "straight ahead … unchanged" (the forward pole), and the rendering requirement "tonemapping happens only at the end".
- [relativity-spec §4](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md#4-test-requirements): the GPU centroid must match the CPU reference within 0.75 px.
- [higgs-bubble §6](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md#6-the-glow-and-the-plume): E(θ) = ε f_in K max(0, cos θ); HB-102 is 9.63 × 10⁻⁶ W/m² at 0.99c.
- Ledger D-14 (boost → cruise → brake, no flip) and D-48 (the guided cap, 1−β = 2 × 10⁻⁹; keep the glow as modelled).
- Feature doc: [02-bridge-interior](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/02-bridge-interior.md).
**Depends on:** M4.6a (`glowEmittanceAt`, landed), the live 3D ship (landed), and the CPU half of R-M4.3b-1 (`tests/m4_playthrough_ship.gd:212–228`, landed). No package, sim or physics change.
**Estimated LOC:** about 160. `tools/m4_ship_golden.gd` is about 150, the Makefile about 8 and `main.gd` 1. There are no fixture files; see Design §1.

## Game vision alignment

| Pillar | Score | Notes |
|---|---:|---|
| Choices Are Final | 0 | No change to commit, plan or refusal. |
| The Game Doesn't Judge | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | The clocks are unchanged. |
| The Ship Is Home | 0 | Nothing changes on the bridge. The goldens read it and never alter it. |
| Grounded Strangeness | 0 | No visual change. The starbow and glow the player sees are pinned, not altered. |
| We Are Not Built For This | 0 | Not relevant. |
| Hard sci-fi authenticity (spec) | +1 | For the first time, gate 2 covers the scene the player gets. The starbow pole, the single tonemap and the glow's absolute value are pinned against the sim on the GPU. |
| **Net** | **+1** | **Go.** This is verification work, so the neutral pillars are neutral by nature; no pillar is negative. |

## Problem

In the default 3D ship no GPU golden pins the forward pole, the tonemap chain or the glow. `make golden` covers these only in `--interior` (`tools/interior_golden.gd`, G-M4-1..6). Dry-run at HEAD `789132c` in temp copies, using the drills in the AC table:
- **D1:** the ship's sky camera is pitched 0.003 rad, which moves the rendered pole 1.000 px (spike, below). `make golden` stays green: `drill rc=0 fails=0 ok=363`.
- **D2b:** `ForwardGlow.pole_of` is scaled by 1.02, so the ship's glow is 2 % off the sim. `make golden` stays green: `rc=0 … ok=363`.
- **D3:** the ship's sky layer is re-transformed in the composite. The worst sky pixel then differs by 0.0078, which is 2/255. `make golden` stays green: `rc=0 … ok=363`.
- **D2a:** the shared shader is scaled by 1.02. The interior G-M4-4 already kills this one: `rc=2 … ok=356`.

**Spike.** A throwaway SceneTree script, outside the repo, ran on the rig's GPU window at 960 × 540 in 4 s. It measured the following on the real ship scene:
- **S3:** the forward pole renders 0.030 px from the captain camera's projection in boost, cruise and brake. The pole pixel is open sky: geometry alpha is 0.
- **S2:** the final frame equals the sky SubViewport exactly (worst 0.0000) over 909 sky-only grid pixels, 89 of them lit, with 51 ship pixels in the frame. The camera was at tilt 30°, yaw 0.47.
- **S4:** the unit-gain target is `FORMAT_RGBAH` (14, half float).
  - At the cap pole, θ 0/45/80° are within 0.032 %, 0.032 % and 0.066 %.
  - The 0.99c pole is within 0.34 %.
  - **The 0.99c profile at 80° is off by 2.4 %.** 1.65 × 10⁻⁶ W/m² is a half-float subnormal: the quantum is 5.96 × 10⁻⁸, about 3.6 % of the value. So the profile is checked at the cap and 0.99c is checked as the absolute pole (§3).
  - Rest is exactly 0.

## Goals and non-goals

**Goals.** Three new GPU cases in the existing `--golden` run, on the default 3D painted ship, at the captain's eye:
- S2: one tonemap;
- S3: the forward pole in boost, cruise and brake;
- S4: the glow profile and absolute pole against the sim's `ship.ism.glow_pole_w_m2`, at 0.99c and the D-48 cap, and 0 at rest.

The new cases are fail-closed, with exact count asserts in the `golden` recipe.

**Non-goals.**
- Not in scope: re-pointing `capture-m4`, `bench SCENE=bridge` and the renders. Those are M4.6rR3.
- No production change.
- No new physics formula. Every reference value is the sim's `ismAt` or a `physics/` mirror.
- The interior G-M4-1..6 stay unchanged as reference-mode gates.

## Design

### 1. Where the sim values come from (float64)

The golden run has no sim. `Makefile:360` runs `$(GODOT)`, not `$(GODOT_SIM)`. Starting one and flying to 0.99c and the cap would be a long run. So both values come from the sim's own function, on both engines.

**The probe.** `golden` gains the prerequisite `m4-physics-probe` (`Makefile:182–186`; 3 s measured; interpreter and VM diffed). It writes `.godot/tmp/m4-physics-probe.txt`. Its `stop` rows call `ismAt` (`sim/tools/m4_physics_probe.ail:36–40`). That is the function behind `ship.ism`: `sim/core.ail:829` `ismNow` → `sim/consequence.ail:98` `ismAt` → `glow_pole_w_m2` in `sim/protocol.ail:293/308`.

The driver parses two rows, failing closed if the file or a row is missing:
- `stop sun … pole 0.000009628776871706523 T 1357.5234659678836`: 0.99c, HB-102.
- `stop guided-cap-2e-9 phi 10.361632917973207 … pole 56.3303485183483 T 66763.66576978598`: the D-48 cap.

It reads them with `ProjectSettings.globalize_path("res://.godot/tmp/…")`, the pattern of `tests/m4_playthrough_ship.gd:21`.

**The worlds.**
- **Base.** `assets/ship_demo/sky_review.json` holds frozen AILANG-sim worlds. It has `rest` and `cruise` only; there are no boost, brake or cap states. `cruise` is β 0.99, `one_minus_beta` 0.01, γ 7.0888 and `ism.glow_pole_w_m2` 9.6287768717e-06. The driver requires the probe's 0.99c pole to equal that field to within 1e-9 relative, or it fails. That ties the probe to a recorded sim world.
- **Phase worlds (S3).** These are `cruise` with `ship.phase` relabelled. For boosting and braking, β, γ and `one_minus_beta` are set from `Relativity.beta_of_rapidity`, `gamma_of_rapidity` and `one_minus_beta_of_rapidity`, applied to `rapidity_of_beta(0.5)` (`physics/relativity.gd:47–69`; the precedent is `tools/interior_golden.gd:198`). Nothing hand-computes γ or 1−β, so `lint-precision` stays clean.
- **Phase and the renderer.** `InteriorSky.apply` never reads `ship.phase` (`interior/interior_sky.gd:196–230`). Its orientation comes from the heading alone, and D-14's "no flip" means the heading is the same in all three phases. So the phases differ to the renderer only in β, which is the claim being pinned.
- **Cap world (S4).** This is `cruise` with `ship.ism.{glow_pole_w_m2, glow_pole_k}` set to the probe's cap row. β, γ and 1−β come from the `*_of_rapidity` mirrors applied to the probe's cap φ. The glow shader reads only `pole`, `t_pole`, `radius`, the ship axes and `cam_ship` (`interior/glow_overlay.gdshader:21–29`).
- **Rest world.** `rest`, unchanged.

The driver injects worlds through the demo's own path: `demo.sky_states[k] = w; demo.set_sky_state(k)` (`demos/ship_geometry_demo.gd:280–286`). This runs `sky.apply` and then `_sync_observer` (`:287–293`), which calls `sky.set_glow(ForwardGlow.pole_of(world), …)`. The pole reaches the GPU uniform by exactly the game's route (`interior/interior_sky.gd:218, 293, 383`).

### 2. The scene and the camera

`tools/m4_ship_golden.gd` (`extends RefCounted`, `run(main) -> int`) builds the ship twice:
- **Build A:** stars and background off, for S3 and S4.
- **Build B:** stars and background on, for S2.

Each build instantiates `res://demos/ship_geometry_demo.tscn`, which `main.gd:99` also uses. It sets `setup_options = {"size": main.get_window().size, "stars": …, "background": …, "sky_state": "cruise"}` (`ship_geometry_demo.gd:120–151`) and adds the demo as a child of `main`. After one frame the driver:
- sets `auto = false` and `journey_auto_tick = false`;
- hides the demo's CanvasLayers with `layer >= 0`: the HUD (10), identification (11) and interlude (12);
- calls `set_process(false)`, so exposure adaptation cannot overwrite the test exposure;
- sets `sky.dust_auto = false` and calls `sky.upload_dust([])`, so no dust flash lands near the pole (`interior/interior_sky.gd:35, 248`).

**Captain eye.** `demo.camera.follow(demo.avatar_pos, tilt, yaw, 0.0)` with pullback 0 (`demos/ship_demo_camera.gd:13`), then `demo._sync_observer()`. This copies the captain camera into the sky camera (`ship_demo_camera.gd:24–40`).

**Readback.** The driver uses the existing pattern (`tools/interior_golden.gd:86–89`): 3 process frames, then `RenderingServer.frame_post_draw`. It reads the final frame (`main.get_viewport()`), `demo.sky` (the sky SubViewport) and `demo.geometry_view`. The centroid follows `_centroid` (`:131`): window 12 px, pixels at or above half the peak, luminance-weighted.

The demo is freed after each build.

### 3. The cases

**G-M4-S3, the forward pole (3 cases: boosting β 0.5, cruising 0.99 from the sim, braking β 0.5).**
- **Pose:** tilt 89.99°, yaw 0. This is the CPU half's pose (`tests/m4_playthrough_ship.gd:236`).
- **CPU pole:** the travel axis projected through the captain's own `Camera3D`: `demo.camera.unproject_position(demo.camera.global_position + Vector3.UP * 1000.0)`. Ship +Z is glTF +Y (`ship_demo_camera.gd:19`). This is independent of the sky camera the GPU uses. It is cross-checked against `AreaBundle.project` of the ship's +Z through `sky.cam` in float64; both gave (480.0000, 269.9418) in the spike.
- **Clear-window check:** a clean frame must have peak < 0.02 in the pole window, and geometry alpha must be 0 at the pole. Otherwise the case FAILs as "covered".
- **Star:** one star at the apparent forward direction. Following `_place` (`tools/interior_golden.gd:113`): `n = Relativity.deaberrate(vw, vw, β)`, Doppler-matched flux, `set_ship_position(0, 0, 0)`, `set_velocity(vw, β, γ)`, `set_exposure(5.0)`.
- **Pass:** the centroid in the **final frame** is within 0.75 px of the CPU pole.

**G-M4-S2, one tonemap (1 case).** This follows G-M4-2 (`tools/interior_golden.gd:210`) and runs on build B.
- **Pose:** the `cruise` world, captain eye at tilt 30°, yaw 0.47.
- **Comparison:** on a 40 × 24 grid, keep the pixels where geometry alpha is 0. Each must satisfy max|final − sky SubViewport| ≤ 1/255 + 1e-6, compared in RGBA8.
- **Floors:** n ≥ 500, lit ≥ 50 (luminance > 2/255) and ship ≥ 20. The spike measured 909, 89 and 51.
- **No panorama:** if `sky.has_background` is false, use the synthetic gradient of `tools/interior_golden.gd:212–219`.

**G-M4-S4, the glow (6 cases).** This runs on build A with `sky.set_debug_unit(true)`, which gives the linear half-float target with unit gain (`interior/interior_sky.gd:413`). The format must be 14, or the case FAILs.
- **Aim:** for each θ the captain's eye is aimed at the wall point P = R (sin θ cos α, sin θ sin α, cos θ), where α = atan2 of the camera's ship-frame y and x. That keeps P in view from the off-centre eye.
- **Pixel read:** the centre pixel (W/2, H/2).
- **CPU reference:**
  - c = `ForwardGlow.wall_cos(cam_ship, AreaBundle.unproject(cam, W/2 + 0.5, H/2 + 0.5), sky.radius_m)` (`interior/forward_glow.gd:107`), where `cam` is `sky.cam` with `fov_vertical_deg` and `resolution` added.
  - want = `ForwardGlow.profile(P_sim, c)` (`:44`).
- **Profile, cap, θ 0/45/80° (3 cases):** |got − want| ≤ 1 % of want, and |c − cos θ| ≤ 0.005. In the spike, c was 1.0000, 0.7059 and 0.1713.
- **Absolute, 0.99c and cap (2 cases):** at θ 0 (c ≥ 0.9999), |got − P_sim| ≤ 1 % of P_sim, with P_sim being the probe's pole.
- **Rest (1 case):** got == 0 exactly.

### 4. Wiring and log format

`main.gd`: one line after `:898`, before the summary print (`:899`): `failures += await load("res://tools/m4_ship_golden.gd").new().run(self) # M4.6gR3: G-M4-S2..S4`. It goes last so that no earlier golden sees ship state. `tools/*` already sits on the export audit's dev-only prefix row.

Driver `ok`/`FAIL` lines. The prefix is `"ok  "` or `"FAIL"`, then two spaces, as in every existing golden:
```
ok    G-M4-S3 forward pole (ship) <phase> beta %.2f: captain eye pole (%.2f, %.2f) rendered (%.2f, %.2f) error %.3f px (limit 0.75)
ok    G-M4-S2 one tonemap (ship): %d sky-only pixels (%d lit, %d ship), worst |final - sky SubViewport| %.4f (limit 1/255 = 0.0039)
ok    G-M4-S4 glow profile (ship) cap theta %2.0f deg: wall cos %.4f, unit-gain target %s W/m^2, CPU profile %s (limit 1 %; format 14)
ok    G-M4-S4 glow absolute (ship) 0.99c: unit-gain pole %s W/m^2, sim ship.ism.glow_pole_w_m2 %s (limit 1 %)
ok    G-M4-S4 glow absolute (ship) cap 1-beta 2e-9: unit-gain pole %s W/m^2, sim ship.ism.glow_pole_w_m2 %s (limit 1 %)
ok    G-M4-S4 glow rest (ship): unit-gain target %s W/m^2 (exactly 0)
m4 ship golden: %d failures
```

`Makefile` `golden` changes:
- The prerequisite becomes `golden: lens-assets m4-physics-probe`.
- The help text gains "M4.6gR3: ship G-M4-S2 one tonemap, S3 pole 3, S4 glow 6".
- These lines are inserted after `grep -q '^interior golden: 0 failures$$' …`:
  ```
  grep -q '^ok    G-M4-S2 one tonemap (ship)' $(SCRATCH)/golden.log && test "$$(grep -c '^ok    G-M4-S3 forward pole (ship)' $(SCRATCH)/golden.log)" = 3 && \
  test "$$(grep -c '^ok    G-M4-S4 glow' $(SCRATCH)/golden.log)" = 6 && grep -q '^m4 ship golden: 0 failures$$' $(SCRATCH)/golden.log && \
  ```
- The failure echo gains "+ M4.6gR3 G-M4-S2, G-M4-S3 3, G-M4-S4 6".

These patterns do not collide with the existing `'^ok    G-M4-4 glow'` (8), `'^ok    G-M4-3 forward pole'` (6) or `'^ok    G-M4-2 one tonemap'`. All the asserts were dry-run on a synthetic log: 373 ok lines PASS, and one S3 line flipped to FAIL is rejected. The `ok` total goes from 363 to 373.

## Acceptance criteria

Every mutation runs in a **temp copy** made by the drill wrapper, never in the working tree. Write the wrapper once:

```sh
cat > /tmp/m46g_drill.sh <<'EOF'
set -eu
# usage: bash /tmp/m46g_drill.sh FILE PERL MARKER FAILPAT   (FILE '' = positive control, no mutation)
R=$(git rev-parse --show-toplevel)
T=$(mktemp -d /tmp/m46g.XXXXXX)
rsync -a --exclude .git --exclude .godot/tmp "$R"/ "$T"/
if [ -n "$1" ]; then
  perl -i -pe "$2" "$T/$1"
  grep -qF -- "$3" "$T/$1" || { echo "drill: mutation did not apply to $1"; rm -rf "$T"; exit 3; }
fi
rc=0
(cd "$T" && perl -e 'alarm 900; exec @ARGV' make golden AILANG=runtime/bin/ailang > golden.out 2>&1) || rc=$?
n=$(grep -c -- "$4" "$T/.godot/tmp/golden.log" || true)
ok=$(grep -c '^ok' "$T/.godot/tmp/golden.log" || true)
echo "drill rc=$rc fails=$n ok=$ok"
rm -rf "$T"
EOF
```

| # | Criterion | Command → expected |
|---|---|---|
| AC1 | `make golden` is green with the new counts | `make golden AILANG=runtime/bin/ailang && grep -c '^ok' .godot/tmp/golden.log` → exit 0, `373` |
| AC2 | S3: the pole is within 0.75 px in all three phases at the captain eye, and every interior G-M4-3 line still passes | `grep -c '^ok    G-M4-S3 forward pole (ship) [a-z]* beta' .godot/tmp/golden.log` → `3`; `grep -c '^ok    G-M4-3 forward pole' .godot/tmp/golden.log` → `6` |
| AC3 | S2: one tonemap over enough sky, lit sky and ship | `grep -c '^ok    G-M4-S2 one tonemap (ship): ' .godot/tmp/golden.log` → `1` (the floors n ≥ 500, lit ≥ 50, ship ≥ 20 are asserted in the driver and printed on the line) |
| AC4 | S4: profile, absolute pole equal to the sim value at 0.99c and the cap, and 0 at rest | `grep -c '^ok    G-M4-S4 glow' .godot/tmp/golden.log` → `6`; `grep -c '^ok    G-M4-S4 glow absolute (ship) cap 1-beta 2e-9: .* sim ship.ism.glow_pole_w_m2 56\.330348' .godot/tmp/golden.log` → `1` |
| AC5 | Positive control in a temp copy | `bash /tmp/m46g_drill.sh '' '' '' '^FAIL'` → `drill rc=0 fails=0 ok=373` |
| AC6 | D1, the pole moved 1 px (the ship's sky camera pitched 0.003 rad), is killed | `bash /tmp/m46g_drill.sh demos/ship_demo_camera.gd 's/^(\tif position.length\(\)>=100\.: sky.set_glow_pole\(0\.\))$/$1\n\tsky.camera.look(sky.camera.yaw,sky.camera.pitch+.003,sky.camera.roll)/' 'sky.camera.pitch+.003' '^FAIL  G-M4-S3 forward pole (ship)'` → `drill rc=2 fails=3` (at HEAD: `rc=0 fails=0 ok=363`) |
| AC7 | D2a, the shared glow shader scaled by 1.02, is killed by S4 | `bash /tmp/m46g_drill.sh interior/glow_overlay.gdshader 's/float e = pole \* ct;/float e = pole * ct * 1.02;/' 'pole * ct * 1.02' '^FAIL  G-M4-S4'` → `drill rc=2 fails=5` (at HEAD: `rc=2 fails=0 ok=356`, from G-M4-4 only) |
| AC8 | D2b, the sim-to-renderer pole scaled by 1.02, is killed | `bash /tmp/m46g_drill.sh interior/forward_glow.gd 's/return _field\(world, POLE_FIELD\)$/return _field(world, POLE_FIELD) * 1.02/' 'POLE_FIELD) * 1.02' '^FAIL  G-M4-S4'` → `drill rc=2 fails=5` (at HEAD: `rc=0 fails=0 ok=363`) |
| AC9 | D3, a broken tonemap chain (the sky layer re-transformed in the composite), is killed | `bash /tmp/m46g_drill.sh demos/ship_geometry_demo.gd 's/_draw_layer\(sky.get_texture\(\),-40\);/_draw_layer(sky.get_texture(),-40);_rects[0].modulate=Color(.98,.98,.98);/' '_rects[0].modulate=Color(.98,.98,.98)' '^FAIL  G-M4-S2'` → `drill rc=2 fails=1` (at HEAD: `rc=0 fails=0 ok=363`) |
| AC10 | The wrapper fails loudly when a mutation does not apply | `bash /tmp/m46g_drill.sh demos/ship_geometry_demo.gd 's/NO_SUCH_TEXT/x/' 'NO_SUCH_MARKER' '^FAIL'; echo $?` → `drill: mutation did not apply …`, `3` |
| AC11 | No production change; the reference gates are untouched | `git diff --name-only origin/main -- demos interior ui sim physics sky bridge tools/interior_golden.gd \| wc -l` → `0` |
| AC12 | The full suite and the precision lint are green, with no new Python | `make test AILANG=runtime/bin/ailang && make lint-precision python-guard` → exit 0 |

**Dry-run at HEAD `789132c`** in this clone on the GPU window: AC5, AC6, AC7, AC8, AC9 and AC10 (the whole wrapper under `set -eu`, with real temp copies, every one removed afterwards), plus the AC1–AC4 grep patterns and the recipe asserts on a synthetic log in the driver's exact line formats (AC1–AC4 printed 373, 3, 6, 1, 6, 1), and AC11 at HEAD, which printed 0. The results are the "at HEAD" values above. AC5 took 27 s end to end.

## Sub-milestones and estimates

One step, test-first:
1. Add the Makefile count asserts (red: no S lines).
2. Add the driver and the `main.gd` hook (green).
3. Run AC5–AC10.

About 160 LOC and roughly half a day of loop time. Each golden run takes about 30 s.

## Risks and mitigations

- **Half-float subnormal at 0.99c.** 9.63 × 10⁻⁶ W/m² sits below half's normal range. The measured error is 0.34 % against the 1 % limit; the cap is used for the profile for this reason. A GPU that flushes half subnormals to 0 would FAIL the 0.99c absolute case loudly, never pass it silently. `make golden` runs only on the rig (Apple GPU).
- **Main's overlays in the final frame.** The driver checks that the pole window is clear before placing the star (S3), and the floor counts guard S2. The spike ran without `main`, so the first real run confirms both.
- **The frozen review world drifts from the sim.** The 0.99c cross-check (probe = `sky_review.json` within 1e-9) fails loudly if either moves.
- **Shared files with held PRs.** None overlap: the `golden` hunk and `main.gd` are untouched by #243, #252, #254 and #255. #255 changes `AILANG_RELEASE` in the Makefile, a different hunk, and so does #243 with `crew-perf`. #252 holds `sprint_R1-M4-JOURNEY.json`, so the executor should re-read `git log HEAD..origin/main` before merging (charter, iteration-30 retro).

## Open questions

None.

## Contradictions with the sprint plan (found at HEAD)

1. **"Fixtures ~15" is not needed.** No sim world exists at HEAD for boost, brake or the cap (`assets/ship_demo/sky_review.json` has only `rest` and `cruise`), and `make golden` runs no sim (`Makefile:360`, `$(GODOT)`). The sim values come from `m4-physics-probe` (the sim's `ismAt`) instead, cross-checked against the recorded cruise world.
2. **`main.gd` needs a 1-line hook** (`main.gd:895–899`). The sprint counted only Makefile wiring.
3. **The interior goldens' "cap" is 1−β = 10⁻⁶** (`tools/interior_golden.gd:24–28`, HB-103), not D-48's 2 × 10⁻⁹. This doc follows the sprint (2 × 10⁻⁹: pole 56.33 W/m², T 66,764 K). The physics spec has no HB row for that value. It is the existing `glowEmittanceAt` at another φ, not a new formula; adding a row is a design-repo follow-up.
4. **The profile at 0.99c, 80° cannot meet 1 % on the half-float debug target** (2.4 % measured). The profile runs at the cap, and 0.99c is the absolute pole.
5. **Stale citations.** The sprint cites `InteriorSky.set_glow` via `demos/ship_geometry_demo.gd:286`; at HEAD the call is in `_sync_observer` at `:293`. Its "G-M4-3 … Makefile:294" is now in the `golden` recipe at `Makefile:358–378`.

## Files

- **New:** `tools/m4_ship_golden.gd` (and its `.uid`).
- **Modified:**
  - `main.gd` (1 line);
  - `Makefile` (the `golden` prerequisite, help text, count asserts and failure echo);
  - `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` (progress);
  - `changelogs/unreleased/<date>-m46g-ship-goldens.md`.
- **Not modified:** `tools/interior_golden.gd`, `demos/*`, `interior/*`, `ui/*`, `sim/*`, `physics/*`.
