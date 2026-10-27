# M1 the relativistic sky: report

**Status:** M1.0–M1.8 built and evaluated (2026-09-27 to 2026-10-03); M1.5b (renders, render gate, bench, report, landing) built 2026-10-27 in an attended session. Sprints `R1-M1-SKY` and `R1-M1-SKY-2`. **Bar clause 1 of the R1 charter is met only after Mark's R-f review** of this report and the AC9 renders (below). Design: [m1-relativistic-sky.md](m1-relativistic-sky.md). Plans: [m1-relativistic-sky-sprint.md](m1-relativistic-sky-sprint.md), [m1-remaining-sprint.md](m1-remaining-sprint.md). Progress files: `.ailang/state/sprints/sprint_R1-M1-SKY.json`, `sprint_R1-M1-SKY-2.json`. Evaluations: `.ailang/state/evaluations/eval_R1-M1-SKY*`.

## Toolchain (M1.5b runs)

| | |
|---|---|
| AILANG | v0.54.18, `runtime/bin/ailang` from `make runtime` (the pinned release; CI pins the same) |
| `sunholo/relativity` | 0.12.0 (pinned in `sim/ailang.toml`); photometry since 0.2.0 |
| Godot | 4.7.2-stable |
| Machine | Mac Studio, Apple M4 Max (darwin arm64); Metal and Vulkan (MoltenVK) |
| Base | origin/main `8e742dca` plus this branch |

## Bar clause 1: evidence

Bar clause 1: *M1's acceptance criteria AC1–AC10 are met. The relativistic sky is correct for any velocity or view direction, with a photometric exposure, at 60 fps with 331k stars.* AC11 (D-5) and AC12 are included.

| AC | Check | Command | Result (2026-10-27, v0.54.18) | Milestone |
|---|---|---|---|---|
| AC1 | Photometry published in `sunholo/relativity`; known-star T_eff, G−V, `pkg quality` | `ailang pkg info sunholo/relativity` | v0.12.0, photometry module present since 0.2.0 (published iteration 0, eval 86); later photometry in 0.3.0 (WD, eval 98), 0.5.x (B−V, BC, Crumey, eval 96) | M1.1, M1.2b-WD, M1.P |
| AC2 | Tiers; VM = interpreter bit for bit; zero defaulted photometry | `make test` (`catalogue-vm`, `catalogue-main`, `catalogue-bytes`), `make catalogue-stats TIER=medium` | catalogue-main quick and medium: VM = interpreter, digests match shasum; medium 50,000 rows, 50,000 with photometry, **0 defaulted-photometry violations** | M1.2b-T1…T4, M1.2c |
| AC3 | M-dwarf share of the medium tier ≥ 60 % | `make catalogue-stats TIER=medium` | **74.4 %** (37,200 rows with T_eff < 3,900 K) | M1.2c |
| AC4 | Spec §2 check values on the CPU, including off-axis velocity and a rolled camera | `make test` (`physics`) | **925 passed, 0 failed**; strict off-axis VM 27.637939595105987 = interpreter | M1.6b and every physics milestone |
| AC5 | GPU golden: stars at 12 directions × 4 speeds × 3 orientations within 0.75 px; background marker within 1 px | `make golden` | off-axis golden **144 cases, worst 0.102 px**; 16 background markers, **worst 0.724 px** | M1.6b, M1.4 |
| AC6 | Linear-tonemap colour golden within 0.01 of rgb(D·T) at D ∈ {0.3, 1, 3} | `make golden` | Δxy **0.0001 / 0.0006 / 0.0006** at D 0.3 / 1 / 3 (on a background texel; see Deviations) | M1.4 |
| AC7 | p99 < 16.7 ms at 2560 × 1440, large tier plus background, 30 s flight | `make bench` | **Metal p99 9.685 ms**, **Vulkan p99 11.051 ms**; 335,189 stars drawn, background on, end β 0.99 | M1.3, M1.5b |
| AC8 | Naked-eye limiting magnitude at the default dark-adapted exposure | `make bench` report | **V_lim 6.9** measured in the frame (Crumey F = 2 model 6.897), inside the D-25 window 6.6–7.4 | M1.5a |
| AC9 | Reference renders at 0, 0.5, 0.9, 0.99, 0.999c × forward, starboard, astern, reviewed by a human | `make capture`; `make m1-refs` | 15 frames plus contact sheet, pinned in `data/refs/m1_sky_manifest.sha256`, served from `gs://stapledons-voyage-assets/refs/m1_sky/`; reproduced byte-identical on v0.54.18 (16/16); **R-f review pending** | M1.5b |
| AC10 | `make test` green; strict bytecode; parity | `make test`; GitHub Actions | `make test` **rc 0**; strict VM 21.392852753780428 = interpreter; parity-v2 identical; replay 11 cases identical; CI on the PR | all |
| AC11 | ≥ 95 % of HIP2 V < 2.5 within 1 px; 5,000–9,100 rendered V < 6.5 | `make capture && make bright-audit` | **93/93 within 1 px (100 %)**; **8,107** rendered V < 6.5 | M1.2d, M1.5b |
| AC12 | Protocol v1.1 reason codes and bounded waits | `make test` (`tests/test_sim_bridge.gd`) | sim bridge **0 failures** (the protocol has since moved to 2.x; the v1.1 behaviours are kept) | M1.6a |

## What M1.5b added

- **0.999c in the capture.** `_run_capture` stopped at 0.99c, so AC9's last row was never shot (the γ 275 and 707 frames come from M1.8's CMB capture). `main.gd` now flies on to 0.999c (β 0.999007581, γ 22.45 when captured).
- **The AC11 render gate on real renders.** M1.2d built and tested the auditor on synthetic frames; the capture side was never written. `make capture` now also shoots six 90° cube faces at rest with the HUD hidden, and writes beside each a `<face>.audit.json` with the predicted pixel of every V < 6.5 star, projected by the same camera (`_capture_bright_audit`). `make bright-audit` runs the auditor on them.
- **Pinned references.** `make m1-refs` fetches the reviewed set from the public bucket and checks every sha256; `make m1-refs-publish` uploads it (maintainers). This follows M3's `bh-refs` pattern, because `renders/` is not tracked.
- **Landing.** The design doc and both plans move to `design_docs/implemented/r1/`; live links updated; a changelog fragment.

## Renders (AC9)

`renders/sky_b{00,05,09,099,0999}_{forward,starboard,astern}.png` (plus port, off-axis and rolled per speed) and `contact_sheet.png`, at the dark-adapted eye exposure. The reviewed set is pinned in `data/refs/m1_sky_manifest.sha256`.

**Opened by Claude (attended session, Opus 5.5) 2026-10-27**, downscaled with `sips -Z 640`:
- **At rest:** a dark-adapted sky with the Milky Way band forward and stars evenly spread in every view.
- **0.5c and 0.9c:** stars crowd towards the direction of travel and blueshift; the band compresses forward; starboard and astern dim and redden.
- **0.99c:** a bright blue-white forward cone; most of the sky has moved into it.
- **0.999c (γ 22.45):** a compact forward cone. Starboard is black: a source seen at 90° has D = 1/γ ≈ 0.045, redshifted out of sight. Astern is black (D ≈ 0.022). Faint pink arcs at the cone's edge are Milky Way emission regions in the background compressed by aberration; flagged for Mark's look.

**R-f (Mark): pending.** Bar clause 1 is met only after this sign-off.

## Deviations from the design

| Item | Design | As built | Why |
|---|---|---|---|
| AC2/AC3 commands | `make catalogue-parity`, `tools/catalogue_stats.py` | `catalogue-vm`, `catalogue-main`, `catalogue-bytes` (in `make test`), `make catalogue-stats` (Godot) | The Python fallback was retired; the pipeline is AILANG, the stats are Godot (the Python policy) |
| AC6 | a synthetic star's chromaticity | a background texel's chromaticity through the same colour path (M1.4) | Built with the sky model. Star colour is covered as well: the 60 kK white dwarf at D 44.71 (Δxy 0.0007) and the GR8 star colour (0.0001) |
| AC8 window | 6.0–6.8 | 6.6–7.4 | D-25 (Mark, 2026-10-03): the dark sky moved to the deep-space value, ~23.5 mag/arcsec², moving the naked-eye window to ~6.9 |
| AC11 command | `tools/bright_star_audit.py renders/` | `tools/bright_star_audit.gd` via `make bright-audit` on `renders/bright_audit/` | Plan F3 replaced the Python auditor with Godot |
| AC9 "committed" | renders committed | pinned by sha256 and served from the public bucket | `renders/` is untracked; the M3 pattern |
| Scope | — | the forward CMB disc (M1.8) | Added by D-11 |

## Residual limits

- **The panorama is valid to about 50 ly** from Sol; beyond that the background's parallax error grows (M1.4).
- **HIP giants' B−V relation:** the bright tier's T_eff from B−V is a main-sequence relation; giants are approximate (M1.2d).
- **Bench host load:** the executor's bench ran at load 1.2–3.1 (p99 9.685 / 11.051 ms); the evaluator's at load 5–7.5 still gave 9.701 / 10.040 ms, well inside 16.7.
- **`make golden` needs `make planet-assets`** first: without the planet textures G-M5-4 is skipped and the run reports a failure (pre-existing; the M1.5b run had them).
- **The AC11 gate is lenient by design:** a hit is any detected peak within 1 px of a predicted star, not an identity match; 8,107 of the 8,773 predicted V < 6.5 stars (92 %) are detected. Positive controls fail as they should (evaluator: a 1.5 px shift gives 0/93; a 3 % scale error gives 16/93).

## Upstream (AILANG)

Issues filed during M1 and cited in its rows: ailang#1354 and #1355 (fixed in v0.47.2; M1.6a parked on them), #1419, #1461 (test-runner clash; the package renamed a private lookup), #1501, #1518. All fixed or worked around at the time; the CLAUDE.md workaround list tracks what is still in the tree.

## Evaluations

| Milestone | Score | Evaluator |
|---|---|---|
| M1.1 | 86 | Sonnet |
| M1.2a | 92 | Sonnet |
| M1.2b-preflight | 85 | Sonnet |
| M1.2b-WD1/2, WD3 | 98, 98 | MiniMax M3 |
| M1.2b-T1, T2, T3, T4 | 88, 92, 88, 94 | independent |
| M1.2c, M1.2d | 94, 88 | independent |
| M1.3 | 92 | independent |
| M1.4 | 91 | Sonnet |
| M1.5a | 90 | independent |
| M1.6a, M1.6b | 87, 97 | independent; Fable 5.1 |
| M1.7, M1.8, M1.P | 91, 90, 96 | Sonnet 5.5; Fable 5.1 |
| M1.5b | 87 | Sonnet 5.5, independent; `eval_R1-M1-SKY-2-M1.5b_round_1.json` (no blocking findings) |
