# M3 black holes: report

**Status:** M3.1–M3.6 built and evaluated (2026-10-08). Sprint `R1-M3-BLACK-HOLES`, 11 milestones, approved by Mark
(ledger D-53; D-52: the unified 3D painted ship is the playable). **Bar clause 3 of the R1 charter is met** (table
below). Design: [`../../planned/r1/m3-black-holes.md`](../../planned/r1/m3-black-holes.md). Plan:
[`../../planned/r1/m3-black-holes-sprint.md`](../../planned/r1/m3-black-holes-sprint.md) (both stay in `planned/`
until landing moves them here). Progress file: `.ailang/state/sprints/sprint_R1-M3-BLACK-HOLES.json`. Evaluations:
`.ailang/state/evaluations/eval_R1-M3-*`.

## Toolchain

| | |
|---|---|
| AILANG | v0.52.0, `runtime/bin/ailang` (CI pins the same release) |
| `sunholo/relativity` | **0.10.0**, published 2026-10-08 under D-53 (ailang-packages PR #103): the `schwarzschild` additions and the new `geodesic` module |
| Godot | 4.7.2-stable |
| Machine | Mac Studio, Apple M4 Max (darwin arm64); Metal and Vulkan (MoltenVK) |

## Bar clause 3: evidence

Bar clause 3 (as amended by D-13): *the shadow is within 0.5 px of Synge's formula at 10, 5 and 3 r_s; the weak field is
within 1 % of 2r_s/b at b = 1000 r_s and within 3 × 10⁻⁴ of the second-order series at b = 100 r_s; the Einstein ring is
at the predicted angle; the geodesic integrator ships in `sunholo/relativity`.*

| Clause check | Command | Result (2026-10-08) | Milestone |
|---|---|---|---|
| Shadow at 10 r_s within 0.5 px of Synge | `make golden` → `GR1` | 98.065 px vs f·tan α 98.066 px: **0.001 px** | M3.5a |
| Shadow at 5 r_s | `make golden` → `GR2` | 202.408 vs 202.398 px: **0.010 px** | M3.5a |
| Shadow at 3 r_s | `make golden` → `GR3` | 189.050 vs 189.056 px: **0.006 px** | M3.5a |
| Inside the shadow is black | `make golden` → `GR7` | peak luminance 0.00000 (limit 0.01) under a ×20 sky | M3.5a |
| Weak field, b = 1000: within 1 % of 2r_s/b (package) | `cd $PKG && ailang test --package .` (check42) | **0.14753 %** | M3.1b |
| Weak field, b = 100: within 3e-4 of 2r_s/b + 15π r_s²/16b² (package) | same (check43) | **2.68e-4** | M3.1b |
| Weak field on the game's mirror (r = 10⁶ row) | `make physics` (AC-8 rows RS-14/RS-15) | 0.1475 % at b = 1000; 2.690e-4 at b = 100 | M3.3 |
| Weak-field hand-off on the GPU (tables at 9e5, `weakDeflectionFinite` at 2e6) | `make golden` → `GR9` | both images within **0.158 px** (limit 0.75) | M3.5b |
| Einstein ring at the predicted angle (GPU) | `make golden` → `GR6` | r = 10 / 100 / 1000: 221.091 / 57.773 / 17.572 px vs 221.088 / 57.769 / 17.539: **0.003 / 0.004 / 0.032 px**; azimuthally uniform | M3.5b |
| Einstein angle (CPU) | `make physics` (check46) | ψ_E at 10, 5, 3, 100, 1000 within 1e-7 rad | M3.3 |
| The geodesic integrator ships in the package | `ailang pkg info sunholo/relativity \| grep -E "0.10.0\|geodesic"`; `grep '"0.10.0"' sim/ailang.toml` | `v0.10.0 2026-10-08`, `sunholo/relativity/geodesic`; `"sunholo/relativity" = "0.10.0"` | M3.1p, M3.1c |

### The other acceptance criteria

| AC | Command | Result | Milestone |
|---|---|---|---|
| AC-1 package tests | `cd $PKG && ailang test --package .` | `schwarzschild_ext_test` 23/23, `geodesic_test` 19/19, both engines; 219/219 attested at publish | M3.1a/b |
| AC-2 quality, dry run, publish | `ailang pkg quality .`; `publish --dry-run`; `publish` | no gates; contracts 4/94 verified, 0 refuted; published | M3.1p |
| AC-3 `lensDigest 16` | strict VM vs interpreter `cmp`; oracle | bit-identical; 8.612720147193743 vs oracle 8.612720147193725 (1.8e-14) | M3.1b |
| AC-4 pin | `grep '"0.10.0"' sim/ailang.toml && make deps` | pinned; hello reports 0.10.0 at minor 6, 0.9.0 frozen for minors 4–5 | M3.1c |
| AC-5 table accuracy | `make physics` | worst 1.14e-5 rad at r ≤ 100; 1.7e-4 relative above; 1.2e-9 rad near the antipode | M3.2/M3.3 |
| AC-6 tables reproduce | `make lens-lut-check` (in `make test`) | 297 texels + 9 inverse rows bit-identical; row 128 strict VM = interpreter | M3.2 |
| AC-7 shadow | `make golden` GR1–GR3, GR7 | above | M3.5a |
| AC-8 weak field | package + `make physics` | above | M3.1b/M3.3 |
| AC-9 Einstein ring | `make golden` GR6 + `make physics` | above | M3.5b/M3.3 |
| AC-10 star images, orbit mask, colour | `make golden` GR4, GR5, GR8, GR9 | GR4 0 mismatches at 3 orientations; GR5 0.083 px; GR8 chromaticity 0.0001; GR9 0.158 px | M3.5a/b |
| AC-11 sim values | `make sim strict parity parity-offaxis parity-gr` | static clock and blueshift to 1e-15; tides and hover power to 1e-3; `scriptedApproach` 1.1e-15 of the closed form; GR fixture VM = interpreter | M3.4a/b |
| AC-12 HUD shows the sim's values | `make bh-hud-test` (in `make sim`); `! grep -rnE "sqrt\(1(\.0)? *- *1(\.0)? */ *r" demos ui sky bridge interior` | sentinels: every shown number moves with its gr field; the HUD equals `hud_lines(sim.gr)` at each stop; grep clean (the M3.5 weak factor moved into the mirror as `Schwarzschild.weak_k`) | M3.6 |
| AC-13 renders | `make capture-bh && make bh-render-diff` | 40 renders, diffed against the pinned baseline: worst **0.000/255** (two captures in a row are byte-identical); opened (below) | M3.6 |
| AC-14 `make test`, strict, no GR maths outside the package and mirrors | `make test`; CI; `! grep -rn "1.5 \* u \* u\|acos(-3" sim/*.ail tools/` | green locally (2026-10-08) and in CI on the PR; grep clean | all |
| AC-15 Archive | `make parity-gr` (sim half); `make bh-hud-test` (client half) | bh_enter → bh_hover → bh_ring in order, VM = interpreter; Sgr A* mass 4297000; aboard: the codex opens *Tides* and *The Shadow and the Ring* at the first hover, and the real ring path reports `bh_ring` (`make capture-bh` log) | M3.4b/M3.6 |

AC-15's design wording ("`sim/scenarios/bh_demo.json`") predates protocol 2.6: the scenario is `sgr_a` in the sim
(`sim/gr.ail`, mass and position cited there). There are two black-hole lore entries in `data/lore/archive`
(`tides`, `shadow-ring`, both `first_black_hole`); "the three black-hole Archive entries" are read here as the three
Archive **events**, which the test asserts in order, plus those two codex entries.

## M3.6: Sgr A* aboard the 3D ship

**How the player gets there.** From the ship: the navigation window (M) has **"Sgr A* (black hole) · demo"** (bottom
right), and the HUD has **"Visit Sgr A* (black hole)"** beside the guided voyage. From the shell: `make run-bh`
(`-- --ship-demo --scenario=sgr_a`). The title screen was left alone (its six-button test pins the menu).
The demo is its own sim session (scenario `sgr_a`, protocol 2.6) that replaces the normal navigation session; it is
refused while a committed journey is under way. **L** leaves: back to Sol at rest, GR off, navigation available again.

**The journey.** Start: hovering at 10⁶ r_s (1.34 ly), nose on the hole. **N** takes the next stop: approach to 10 r_s
at β_local 0.1 (each 20 Hz tick asks the sim for 5 % of the remaining ship time, so r falls steadily in log r: 292 ticks,
about 15 s; the sim lands exactly on the target and hovers for whatever is left of the tick), then 5 r_s, 3 r_s, an
orbit at 3 r_s (30 ship-seconds per real second: an orbit in about 46 s), and a hover. **K** finishes an approach at
once (in ≤ 1-ship-year ticks, the protocol's largest). **C** opens the Archive codex.

**HUD.** Only `sim.state["gr"]` fields, formatted (`demos/black_hole_visit.gd hud_lines`): at 3 r_s in orbit it reads
"Sgr A* · 4.297×10⁶ M☉ · r_s 1.27×10¹⁰ m / ORBITING at r = 3.00 r_s · β_local 0.5000 (γ 1.1547) · stable (r ≥ 3, the
ISCO) / static clock 0.816497 · 1 ship-hour = 1.4142 home hours / shadow half-angle 45.00° · incoming light ×1.2247
(blueshift) / tide across the bubble 3.16×10⁻⁴ g radial · … / free fall: 0 W", and hovering at 10 r_s "hover
3.81×10⁹ g · not felt (bubble) · 1.12×10¹³ W per kg of m_eff". The last line is the caption: "Sky: the Milky Way and
stars as seen from Sol, lensed by the hole (the true Galactic-Centre sky is later work)" (design OQ5, D-53). The
details line says "GR on … / GR off" where it said "GR not implemented".

**Known gaps from M3.5, handled.** *Auto-exposure:* the ship demo always uses the fixed manual exposure (J), so the
meter is not in the loop; the details line labels it ("exposure fixed (manual; an auto meter would not see the
shadow)"). *Ring-star latency:* in play the ring set follows a new hole in ~0.6 s of 10k-star slices; left as is
(the captures call `refresh_now`). *Star light:* there is no `system` section at Sgr A*, so `StarLight` finds no
emitter, eases to 0 and the moody ship key returns at its base energy with shadows (tested headless).
*Stars from Sol:* `InteriorSky.apply()` places the catalogue as seen from Sol whenever a `gr` section is present,
matching the photograph (and avoiding a 335k-star CPU rebase to the Galactic Centre).

### Renders (AC-13)

`make capture-bh` drives the real sim through the demo's own controls and writes, at 1280 × 720:
`renders/bh_r{10,5,3}_{toward,side,away}_{hover,orbit}.png` (sky only, HUD hidden), the same 18 on the debug grid
(`bh_grid_*`), `bh_bridge_r10_hover.png` and `bh_bridge_r3_orbit.png` (captain eye, 55° up, with the HUD),
`bh_sheet_milkyway.png`, `bh_sheet_grid.png` and `bh_manifest.sha256`. The reviewed set is pinned in
`data/refs/bh_manifest.sha256` and served from `gs://stapledons-voyage-assets/refs/m3_bh_ship/` (`make bh-refs`);
`make bh-render-diff` diffs a new capture against it with `tools/render_diff.gd` (mean |d| ≤ 1/255 per render).

**Opened by Claude (sprint executor, Opus 5.5) 2026-10-08**, downscaled with `sips -Z 700` into `renders/bh_small/`:
toward the hole the shadow is black and centred, 28.5° across at 10 r_s and 90° at 3 r_s (it fills the frame), ringed
by the photon ring with the Milky Way's bulge (which lies behind Sgr A* as seen from Sol) wrapped into arcs; in orbit
the shadow is aberrated toward the motion and the side view shows the shadow's edge and a stretched band; away from
the hole the sky is only mildly distorted. The grid sheet shows the lines bending into nested arcs round the shadow.
The bridge views show the hole above the bridge railing with the HUD's sim lines. Mark's sign-off on these is pending
(the M3.5 sky renders he opened on 2026-10-08: "they look great").

### Performance with GR on (`make bench-bh`, 1920 × 1080, large tier: 335,189 stars, vsync off)

Mac Studio M4 Max, host load ~3.5 (other agents running). Wall = time between frames (CPU + GPU + presentation).
GPU = `RenderingServer` measured render time; **Metal reports none** (0.00), so GPU numbers are from Vulkan only.

| Case | Metal wall p50 / p99 (ms) | Vulkan wall p50 / p99 | Vulkan GPU sky p50 / p99 | Vulkan GPU ship p50 |
|---|---|---|---|---|
| GR off, Sol at rest, bridge | 8.39 / 9.62 | 8.51 / 9.63 | 2.05 / 6.20 | 1.74 |
| GR off, forward | 8.30 / 10.28 | 8.46 / 9.72 | 2.08 / 6.40 | 0.69 |
| GR on, hover 10 r_s, bridge | 8.46 / 10.80 | 8.58 / 9.47 | 3.85 / 8.43 | 1.67 |
| GR on, hover 10 r_s, forward | 8.31 / 9.74 | 8.50 / 9.67 | 4.23 / 8.09 | 0.66 |
| GR on, live orbit 3 r_s (20 Hz sim ticks), bridge | 9.12 / 14.40 | 8.64 / 14.34 | 4.13 / 8.58 | 1.62 |
| GR on, live orbit 3 r_s, forward | 9.01 / 13.13 | 8.65 / 13.84 | 4.14 / 8.33 | 0.65 |

Reading: GR costs about **+2 ms of GPU** in the sky viewport (second star image pass, ring Gaussians, the lens per
pixel), which the ~8.4 ms frame hides; wall p50 moves by ≤ 0.8 ms. The live orbit raises p99 to ~14 ms (the sim
round trip and `set_gr` on ticks, plus the ring-cone recompute); 1 frame in 300 crossed 16.7 ms on Metal, none on
Vulkan. 60 fps holds with GR on at this size on this machine; laptop numbers remain unmeasured.

## Upstream (AILANG)

Reported during M3 (see the milestone notes): `std/fs` is evaluator-only on the strict VM (M3.2). Nothing new in M3.6:
the demo uses the sim through the bridge only, and the VM and interpreter stayed identical (`make parity-gr`).

## What is left for landing

The design-repo edits listed in the design doc's Deliverables (roadmap status, `black-hole-mechanics.md:82`, the
`black-holes.md` tidal row, the queue-row note), moving the design and plan to `implemented/r1/`, Mark's render
sign-off, and the title-screen entry if wanted.
