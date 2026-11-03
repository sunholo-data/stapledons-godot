# Why the docked bridge's p99 sits above 16.7 ms on a quiet rig (queue row 7m-d)

**Status:** Planned (mission iteration 67, designer). This is a measured attribution, not a fix. Outcome **(a): no product fix indicated**; the docked-control options are open questions for Mark. **Release:** r1. **Milestone:** M4.6, gated half (row 7m AC1, M4 AC12, bar clause 4). Item class `[LOOP]`, measurement only.
**Priority:** P1. Row 7m-d is the only thing between row 7m AC1 and a verdict (D-127 B, D-128 default A).
**Implements:**
- Charter row **7m-d** ([stapledon-mission.md](../../stapledon-mission.md), search `7m-d.`): "Measure why the static docked control in `make bench SCENE=bridge` reads p99 17.62–19.28 ms … frame-time histogram over a longer docked window, per-frame CPU/GPU split, which nodes redraw while docked, with a design doc only if a fix is indicated."
- Charter row **7m** (M4.6pR3) AC1, and its plan's validity rule ([m4-6pr3-live-transit-frame-cost-sprint.md](m4-6pr3-live-transit-frame-cost-sprint.md) lines 105 and 471; design Risks, [m4-6pr3-live-transit-frame-cost.md](m4-6pr3-live-transit-frame-cost.md) "Thin margin": "If the docked control's p99 exceeds 16.7 in the same run, that run measures the rig, not the fix").
- Ledger **D-127** (ANSWERED B, Mark, attended 2026-10-28): the docked-control validity rule stays, AC1 stays open, and the loop measures why. This doc does not change or loosen the rule.
- Ledger **D-128** (OPEN, default A applied): 7m-d runs next whenever the rig is quiet.
- Ledger D-14 (the 60 fps bar, 16.7 ms).
- No physics changes: no SR or GR visual is touched, so physics gate 2 is not triggered.

**Depends on:** nothing. Measured on main `dc4cc3f5`, AILANG v0.56.1 (pinned runtime), Godot 4.7.2.stable.official.ed1daf0bf, Apple M4 Max (40-core GPU), Metal, Forward+.
**Estimated LOC:** 0 of code. This doc only. The probes are in the appendices and are not tracked as tools.

## Game vision alignment

Scored with the `game-vision-designer` skill's feature-validation method against `../stapledons-design/vision/core-pillars.md` (design repo at `586f0eb`), plus this repo's hard-sci-fi spec row. This was an unattended run, so there was no interview. Each pillar was checked for whether the work serves it or conflicts with it.

| Pillar | Score | Notes |
|---|---:|---|
| Choices Are Final | 0 | Nothing in the game changes. |
| The Game Doesn't Judge | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | The sim, the clocks and the pacing are untouched. |
| The Ship Is Home | 0 | The doc measures the bridge's smoothness but does not change it. The open product option (OQ3) would serve this pillar, and it is Mark's call. |
| Grounded Strangeness | 0 | Not relevant. |
| We Are Not Built For This | 0 | Not relevant. |
| Hard sci-fi authenticity (spec) | 0 | Nothing physical changes. |
| **Net** | **0** | **Go, as test and bench hygiene on clause 4.** No pillar is negative. Its value is that clause 4's open AC gets an explanation and Mark gets concrete options. |

## Problem

`make bench SCENE=bridge` (driver `tools/m4_ship_bench.gd`) measures 300 docked frames (after a 120-frame warm-up) as a control, then 30 s of live transit. Under the M4.6pR3 plan, a docked-control p99 above 16.7 ms makes the run invalid. That has happened in every quiet run since iteration 54: in 9 of 9 there (17.62–19.28 ms), in the controller's 2 premise runs today (17.67 and 17.94 ms, `/tmp/iter67_bench_r1.log`, `/tmp/iter67_bench_r2.log`), and in this doc's reference run R3 (18.64 ms). AC1 therefore cannot be cleared by rerunning.

Two hypotheses were on file. Neither was taken as fact:
- **H1** (charter, iteration 63): the display runs at 100 Hz, docked frames sit on the 10 ms period even with vsync off, and a p99 over 16.7 means about 3 frames that slipped a refresh.
- **H2** (controller): the docked control falls just after the scene loads, so warm-up fills its tail.

This doc also tested **H3**: the game does per-frame work while docked (redraws, hidden windows, `_process`). It tested **H4** too: the docked frame is GPU-bound.

## Attribution (the result)

**The docked tail comes from the rig's presentation path: the main thread blocks inside `RenderingServer.draw` waiting for the next frame. On top of that sits about 2.4 ms per frame of ordinary game main-thread work. It is not warm-up, not redraws, and not GPU render cost.**

1. **Frames alternate fast and slow; they do not sit on 10 ms.** The docked frame times are bimodal. One mode is about 5 ms (43 % of frames are ≤ 8 ms) and the other is about 14 ms (37 % are ≥ 12 ms). 95 % of slow frames are followed by a fast one, and consecutive pairs sum to a p50 of 19.7 ms [V6 P2, 3,000 frames]. The mean, 9.7–10.1 ms, is close to the 100 Hz period, but the p99 is the upper tail of the slow mode, which holds over a third of all frames. It is not about 3 slipped refreshes. H1 is right that pacing comes from presentation, and wrong about the mechanism.
2. **Warm-up is ruled out (H2 refuted).** The bench already discards 120 frames. Across the window, the frames over 16.7 ms spread evenly over all five fifths, in every run (V3–V9). The p99 does not fall with longer or later windows: 17.49–18.61 ms in 6 of 6 long docked windows of 1,500–3,000 frames, and 16.87–17.03 ms in 3 of 3 static 1,500-frame windows after the transit.
3. **The time of a slow frame goes into waiting in `RenderingServer.draw`, not into game code.** In 3,000 docked frames [V6 P2], fast frames average 2.35 ms of game time and 2.64 ms in `RenderingServer.draw`. Slow frames average 2.03 ms of game time and 12.29 ms in draw. Over 245 sampled frames above 16.7 ms (5 runs), 243 spent more time in draw than in game code (mean 16.29 ms against 2.44 ms). Only 2 were game-side hitches (34.2 and 47.7 ms in game code).
4. **The GPU work is about 2 ms per frame (H4 refuted).** On Metal, Godot measures no GPU time: `viewport_get_measured_render_time_gpu` returns 0.000 for the root, sky and ship viewports in every phase, confirming the bench's "GPU time n/a on Metal". Two other instruments agree. Vulkan (MoltenVK) timestamps put the three viewports at 0.22 + 0.79 + 0.89 ≈ **1.9 ms p50** (≈ 2.2 ms p99) [V5]. During a 30 s Metal docked run, the OS reported `Device Utilization %` at 22–32 % (32 one-second samples, median about 26 %) at about 102 frames/s, which works out to about 2.5 ms of busy GPU per frame (an inference from utilisation × interval) [V6].
5. **The rig's presentation floor is already near the bound with no game at all.** An empty 2560×1440 window with one ColorRect and the bench's flags reads mean 8.4 ms and **p99 15.50–16.28 ms**, with 4–11 frames over 16.7 per 1,500–3,000 frames. It spends 8.5–8.7 ms p50 inside `RenderingServer.draw` doing nothing [V2, V10, V11]. Vsync on and vsync off are indistinguishable (p50 8.71 against 8.78, p99 16.28 against 15.91), and Metal and Vulkan behave the same. `system_profiler SPDisplaysDataType` lists **no display** on the Studio (only the GPU). Godot sees one 2560×1440 screen at 100 Hz and clamps the window to 2560×1288 [V1]. So the bench measures a headless display path. Iteration 63's "100 Hz" reading came from a Screen Sharing session, which is a different presentation path.
6. **Nothing redraws while docked (H3, redraws: refuted).** Over 1,800 docked frames, the 198 CanvasItems in the tree emit **0** `draw` signals, every run. The navigation window and GalaxyMap do not exist yet while docked. They are created at commit, and after the transit the hidden map emits 0 draws over 1,500 static frames [V3, V8, V9]. Six nodes process each frame [V3].
7. **The game's per-frame main-thread work does push the tail up.** Docked game time is 2.4–2.5 ms p50 (3.2–3.9 ms p99). Of that, 1.94 ms is `ShipGeometryDemo._process`, spread over about ten sections with none above 0.53 ms: `director.advance` 0.52, `_update_hud` 0.53, `consoles.advance` 0.20, captain animation 0.17, `star_light.update` 0.13, `_sync_observer` 0.12, the HUD details string 0.11, `sky.finish_exposure_frame` 0.09, the rest ≤ 0.02 each [V7 P5]. The other five processing nodes together take about 0.6 ms (V7 P4 ablation A0: game p50 0.63 ms without the demo's `_process`). With **all** `_process` turned off (game p50 0.07–0.08 ms), the docked p99 drops to **15.21 and 16.12 ms** (2 runs, 1,500 frames each), which is the empty-window floor [V7 P3, P4]. With only the demo's `_process` off, it is 16.51 ms (one run, 600 frames). For comparison, live transit runs at game p50 1.16–1.39 ms and has a better p99 (15.5–16.9 ms) than the docked scene.

**Confidence.**
- High that the tail is not warm-up (8 windows, evenly spread), not a redraw (0 draws, every run), and not GPU render cost (two independent instruments, about 2 ms per frame).
- High that the time of a slow frame is spent blocked inside `RenderingServer.draw` (243 of 245 frames).
- Medium on what exactly it waits for: drawable acquisition or the compositor's cadence. Godot's Metal driver exposes neither, so this is inferred from the empty-window floor and the GPU figures.
- Medium on the size of the game-work effect. Turning all `_process` off was measured twice; the demo-only ablation was measured once over 600 frames.

**Why outcome (a).** No game-side defect was found: nothing redraws, no hidden window does work while docked, and no node costs more than 0.53 ms. What remains is a presentation floor on a headless display (p99 15.5–16.3 ms with an empty window) plus about 2.4 ms of ordinary per-frame work spread across the bridge's update. Even with that work at zero, the docked p99 is 15.2–16.1 ms, which leaves 0.6–1.5 ms of margin and no robust pass. A product trim is therefore a design choice, not a bug fix, and it is listed as OQ3 for Mark rather than designed here.

## Verification Log

All runs are on the Studio, in the clone `stapledons-godot-iter67` at `dc4cc3f5`, with `PATH=$PWD/runtime/bin:$PATH` and `AILANG_BIN=$(command -v ailang)`. The audio driver was always `Dummy`, and one GPU window ran at a time. The quiet predicate was checked immediately before **every** counted run, using the script below: GPU `Device Utilization %` < 15 on 3 samples, 1-min load < 5, and HIDIdleTime > 600 s.

```sh
# quiet.sh (scratch): prints "quiet: HH:MM:SS GPU a/b/c load1 L HIDidle Ns" and exits 0 only if all three hold
g=(); for i in 1 2 3; do g+=$(ioreg -r -d 1 -c IOAccelerator | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2); sleep 1; done
l=$(sysctl -n vm.loadavg | awk '{print $2}')
h=$(ioreg -c IOHIDSystem | grep -o '"HIDIdleTime" = [0-9]*' | head -1 | awk '{printf "%d", $3/1e9}')
```

The probe command is `godot --audio-driver Dummy --path . --script /tmp/iter67_probe/probe_docked.gd -- --tier=medium --out=… [flags]` (Appendix A). Phases: **W** is the bench's 120 warm-up frames, **C** is the bench's 300-frame docked control (the same frames), **L** is the next N docked frames, **T** is the bench's 30 s live transit, and **P** is N static frames after the transit (journey ticks off). Histogram buckets, in ms: ≤8, ≤9, ≤9.5, ≤10.5, ≤11, ≤12, ≤14, ≤16.7, ≤20, ≤25, ≤35, >35.

| # | Date / time (CET, 2026-11-03) | Rig readings before the run (GPU %, 1-min load, HID idle) | Command | Result |
|---|---|---|---|---|
| V0 | 19:56, 19:58 (controller) | 0/0/0; 2.8 and 1.9; ≈ 29,600 s | `make bench SCENE=bridge` | Docked control p99 **17.67, 17.94** ms (p50 10.38, 10.94). Transit p99 15.746 and 15.579 ok. Logs `/tmp/iter67_bench_r{1,2}.log`. |
| V1 | 20:00 | (no window) | `system_profiler SPDisplaysDataType`; the probe's first line | No display listed; the GPU is "Apple M4 Max, Metal 4". Godot: 1 screen, 2560×1440, **100.000 Hz**, window clamped to 2560×1288, thread model 1 (main thread renders), frame queue 2, swapchain 3. |
| V2 | 20:08:30 / 20:08:48 | 0/0/0, 3.42, 30,309 s / 0/0/0, 2.94, 30,327 s | `probe_empty.gd -- --frames=1500` / `--vsync=on` (Appendix B) | **Empty window, vsync off**: mean 8.41, p50 8.78, p95 13.81, **p99 15.91**, max 42.66, 5 frames over 16.7; draw p50 8.68. Histogram (≤2,≤4,≤6,≤8,≤9.5,≤10.5,≤12,≤14,≤16.7,≤20,>20): 77, 42, 132, 318, 603, 96, 74, 90, 63, 1, 4. **Vsync on**: mean 8.40, p50 8.71, **p99 16.28**, 8 over; the same shape. |
| V3 | 20:03:29 (P1) | 0/0/0, 1.26, 30,009 s (after: 41/0/0 at 20:04:46; Ollama `llama-server` then took the GPU to 95–97 % from about 20:05 to 20:07, after the run) | probe `--long=1500 --post=1500` | **C** (300): p50 11.04, p95 15.98, **p99 18.41**, 7 over, at indices 18, 58, 89, 93, 172, 182, 193 (fifths 2/2/1/2/0). Histogram 139, 1, 3, 3, 3, 9, 52, 83, 7, 0, 0, 0. **L** (1,500): **p99 18.25**, 40 over, fifths 8/14/8/5/5. Histogram 652, 22, 20, 47, 117, 56, 215, 331, 35, 3, 0, 2. **T**: p99 16.64, 31 over. **P** (1,500): p99 17.02, 22 over. Docked: 0 draw signals from 198 CanvasItems. P's numbers agree with P6 and P7 within 0.16 ms, so the GPU reading after the run did not show in them. |
| V4 | 20:02:19 (smoke, **not counted**) | 0/0/0, 2.19, 29,938 s | probe, short | It showed that `Performance.TIME_PROCESS` is a one-second maximum, not a per-frame value (it read 18–3,061 ms). The probe therefore times game code itself, from `process_frame` to `frame_pre_draw`. |
| V5 | 20:09:15 (V1, Vulkan) | 0/0/0, 2.45, 30,354 s | probe `--rendering-driver vulkan --long=1500 --skip-transit` | GPU timestamps exist on Vulkan. In C, the root viewport is 0.216 ms p50, sky 0.792, ship 0.893 (p99 0.235 / 0.883 / 1.117), so **about 1.9 ms per frame**. Frames: C p99 16.12 (1 over), L p99 16.89 (19 over in 1,500), still bimodal (fast 602, slow 568). |
| V6 | 20:10:10 (P2) | 0/0/0, 2.39, 30,409 s | probe `--long=3000 --skip-transit`, with `ioreg` sampled every 1 s alongside | **C**: p99 18.28, 9 over, at indices 1, 33, 61, 127, 171, 192, 247, 282, 284. **L (3,000)**: mean 9.74, p50 10.73, p95 15.98, **p99 17.49**, 51 over, fifths 13/9/8/15/6. Histogram **1301, 41, 32, 91, 89, 334, 396, 665, 45, 3, 2, 1**. Fast (≤ 8 ms): 1,301, game 2.35 + draw 2.64 ms. Slow (≥ 12 ms): 1,112, game 2.03 + draw 12.29 ms. 1,056 slow→fast transitions; pair sum p50 19.68. During the run, `Device Utilization %` read 22–32 (median about 26) on 32 samples. |
| V7 | 20:11:21 (P3), 20:12:34 (P4), 20:14:27 (P5) | P3: 0/0/0, **4.88**, 30,481 s. P4: 0/0/0, 2.91, 30,553 s. P5: 0/0/0, 2.61, 30,667 s | P3 `--long=1500 --noproc=1500 --skip-transit`. P4 `--long=300 --ablate=600 --noproc=1500 --skip-transit`. P5 `--long=1500 --skip-transit --timed` (Appendix C subclass) | **All `_process` off (N)**: P3 p99 **16.12** (9 over), P4 p99 **15.21** (7 over); game p50 0.07 / 0.08 ms. Docked with process on, same runs: L p99 18.58 (P3), C p99 18.96 / 18.25. P4 ablation, 600 frames each, one node off at a time. Game p50 / frame p99 / over: without the demo 0.63 / 16.51 / 4; without frame_check 2.46 / 17.32 / 13; without the sky 2.45 / 20.07 / 30; without ShipSound 2.26 / 18.16 / 15; without sound_director 2.36 / 18.05 / 13; without star id 2.47 / 19.20 / 27; all on 2.47 / 17.69 / 17. P5 sections are listed in Attribution 7. Their total is 1.940 ms per frame. Frames: C p99 17.87, L p99 18.16. |
| V8 | 20:15:27 (P6) | 0/0/0, 2.24, 30,727 s | probe `--long=1500 --post=1500` (re-hooks CanvasItems before T and P) | C p99 **17.53**; L p99 **18.01** (43 over, fifths 9/11/7/9/7); T p99 15.54; P p99 16.87 (17 over). Docked and P: **0** draw signals. In T: 7,985 draw signals from 36 CanvasItems (see Side findings). |
| V9 | 20:17:04 (P7) | 0/0/0, 3.85, 30,824 s | the same as V8, also printing the navigation window's visibility at the start and end of T | C p99 **17.04**; L p99 **18.61** (44 over); T p99 15.64; P p99 17.03 (20 over). `navigation_window visible false` at the start and end of T, with no console focused. |
| V10 | 20:20:00 | 0/0/0, 3.68, 31,000 s | `probe_empty.gd -- --frames=3000` | Empty window, Metal: mean 8.40, p50 8.80, **p99 15.86**, max 37.24, 11 over in 3,000. Histogram 188, 82, 237, 576, 1167, 258, 170, 191, 120, 6, 5. |
| V11 | 20:20:31 | 0/0/0, 2.67, 31,031 s | `probe_empty.gd --rendering-driver vulkan -- --frames=1500` | Empty window, Vulkan: mean 8.39, p50 8.66, **p99 15.50**, 4 over. |
| V12 | 20:20:55 (R3) | 0/0/0, 2.36, 31,054 s (after: 0/0/0, 1.94 at 20:21:46) | `make bench SCENE=bridge AILANG=runtime/bin/ailang` | Docked control p50 10.01, p95 16.28, **p99 18.64**. Live transit 3,197 frames, p99 **16.908: MISS** (40 frames over), make rc 2. |

The rig was not quiet from 20:05:09 to 20:07:26 (Ollama `llama-server` GPU 95–97 %, 1-min load up to 11.39) or from 20:18:31 to 20:19:29 (load 5.05–6.56; `node` and `ailang` processes). No run was counted in those windows. The raw logs and per-frame JSON are in `/tmp/iter67_probe/` (scratch, not kept).

**Summary across quiet runs (Metal):**
- 300-frame docked control, p99: 17.04–18.96 ms in **10 of 10** windows: V0 ×2, V3, V6, V7 ×3, V8, V9 and V12.
- Long docked windows (1,500–3,000 frames), p99: 17.49–18.61 ms in 6 of 6.
- Static windows after the transit, p99: 16.87–17.03 ms in 3 of 3.
- Live transit, p99: 15.54–16.91 ms in 6 runs, with 1 MISS.
- Empty window, p99: 15.50–16.28 ms in 4 of 4.
- Docked with all `_process` off, p99: 15.21 and 16.12 ms (2 of 2).

## Side findings (out of this row's scope; recorded for the follow-up backlog)

- **The hidden navigation window still redraws during live transit.** With `navigation_window.visible == false` throughout T [V9], the window's GalaxyMap overlay `Control`, its `EarthBeams` child, and the MapDetails labels and progress bar each emit `draw` 599–600 times in 30 s, once per 20 Hz tick [V8, V9]. M4.6pR3 gated only `IsmLayer`. Their cost was not measured. The transit p99 still passed 5 of 6 times, so this is a non-blocking backlog line, not a new row.
- **The live transit's own p99 margin is thin on this rig.** R3 missed at 16.908 ms on a quiet rig [V12], and the other five readings were 15.54–16.64 ms. The same presentation floor limits it.
- **The docked frame does more main-thread work than a transit frame**: game p50 2.4–2.5 ms docked against 1.16–1.39 ms in transit, and ship-viewport CPU 0.48 against 0.15 ms. This is measured, and the cause was not traced.
- **`Performance.TIME_PROCESS` and `TIME_PHYSICS_PROCESS` are one-second maxima in Godot 4.7, not per-frame values** [V4]. Any future bench split should time `process_frame` → `frame_pre_draw` → `frame_post_draw`, as Appendix A does.

## Goals and non-goals

**Goals:**
- Attribute the docked p99, with the command, instrument and raw numbers for each claim (done above).
- Give Mark concrete, checkable options for the docked control.

**Non-goals:**
- Changing the validity rule, the 16.7 ms bound, the bench driver or any game code (D-127 B).
- Deciding between the options.
- Fixing the side findings.

## Acceptance criteria (reproduce the attribution by command)

Before **each** GPU-window command, the quiet predicate must hold (the `quiet.sh` lines above). A failed predicate is an invalid run, not evidence. Extract the probes from this doc first:

```sh
D=design_docs/planned/r1/m4-7md-docked-p99-attribution.md; mkdir -p /tmp/iter67_probe
for n in probe_docked probe_empty; do awk -v n="$n" '$0=="```gdscript "n".gd"{f=1;next} f&&/^```$/{f=0} f' $D > /tmp/iter67_probe/$n.gd; done
export PATH=$PWD/runtime/bin:$PATH AILANG_BIN=$(command -v ailang)
P="godot --audio-driver Dummy --path . --script /tmp/iter67_probe"
```

| AC | What it reproduces | Command | Pass |
|---|---|---|---|
| R1 | The premise: the docked control is above 16.7 ms, and Metal reports no GPU time | `make bench SCENE=bridge AILANG=runtime/bin/ailang; jq -e '.docked_control.p99_ms > 16.7 and ([.sky_gpu_ms[], .ship_gpu_ms[]] \| max) == 0' .godot/tmp/bench-bridge.json` | `jq` exits 0. A make rc of 2 from a transit miss does not matter here; the JSON is written either way. |
| R2 | Not warm-up: a long docked window keeps the tail, spread across the window | `$P/probe_docked.gd -- --long=1500 --skip-transit > /tmp/iter67_probe/r2.log 2>&1; grep '^probe: phase L ' /tmp/iter67_probe/r2.log` | The L p99 is > 16.7, and the `frames > 16.7 by fifth` line has every fifth ≥ 1 |
| R3 | Nothing redraws while docked | the same log: `grep -c '^probe: docked\( long\)\? over [0-9]* frames: 0 draw signals' /tmp/iter67_probe/r2.log` | prints `2` |
| R4 | The slow frames' time is in `RenderingServer.draw`, not game code | `grep '^probe:   slow [CL] ' /tmp/iter67_probe/r2.log \| awk '{for(i=1;i<=NF;i++){if($i=="game")g=$(i+1);if($i=="draw")d=$(i+1)} n++; if(d>g)k++} END{print k"/"n; exit !(k>=0.9*n)}'` | exits 0 (at least 90 % of slow frames have draw > game) |
| R5 | Bimodal, alternating frames | `grep '^probe: phase L fast' /tmp/iter67_probe/r2.log` | fast(≤8) ≥ 30 % of frames, slow(≥12) ≥ 25 %, and slow→fast ≥ 80 % of slow |
| R6 | The presentation floor of an empty window, with vsync having no effect | `$P/probe_empty.gd -- --frames=3000 \| grep '^empty: n'; $P/probe_empty.gd -- --frames=1500 --vsync=on \| grep '^empty: n'` | Both: mean 7.5–9.5, p99 ≥ 14.5, draw p50 ≥ 6. The two p50 values within 0.5 ms of each other. |
| R7 | The GPU costs about 2 ms per frame (Vulkan timestamps) | `godot --audio-driver Dummy --rendering-driver vulkan --path . --script /tmp/iter67_probe/probe_docked.gd -- --long=300 --skip-transit \| grep '^probe: phase C vp '` | The three `gpu p50` values sum to < 4 ms |
| R8 | The game work's share: turning all `_process` off lowers the docked p99 to the floor | `$P/probe_docked.gd -- --long=1500 --noproc=1500 --skip-transit \| grep -E '^probe: phase [LN] n'` | N's p99 < L's p99, and N's p99 ≤ the R6 vsync-off p99 + 1.0 |
| R9 | No display is attached (the condition these numbers were measured under) | `system_profiler SPDisplaysDataType \| grep -c Resolution` | prints `0`. If it prints ≥ 1, the rig has changed and R1–R8 describe a different presentation path. Record it. |

## Open questions for Mark

D-127 B stands: none of these loosens the 16.7 ms bound or drops the rule. The loop does not choose among them. The attribution above is the evidence for whichever Mark picks.

- **OQ1: Status quo.** The rule stays as it is, 7m-d closes with this attribution, and row 7m AC1 stays open and is not rerun. Check: the charter's row 7m keeps its D-127 B tag; nothing to run.
- **OQ2: Make the rig a valid environment by attaching a display.** The counted bench runs with a physical display connected and awake, so the presentation path is a real one and not the headless one measured here. The rule and the bound stay. Check: `system_profiler SPDisplaysDataType | grep -q Resolution`, then the quiet predicate, then `make bench SCENE=bridge` twice, then `jq -e '.docked_control.p99_ms <= 16.7' .godot/tmp/bench-bridge.json`. **UNMEASURED** here because no display is attached and the loop cannot attach one. Iteration 63's premise readings came from a Screen Sharing session (docked p99 15.35 and 11.61 ms) and were not counted. That suggests, without proving, that the presentation path is what changes the result. Needs hardware or an attended session.
- **OQ3: Product trim of the docked frame's main-thread work** (a new design and its own row; not designed here). It would cut the 2.4 ms per frame, 1.94 ms of which is `ShipGeometryDemo._process` spread over about ten sections (`director.advance` and `_update_hud` at about 0.5 ms each), toward the transit's 1.2 ms. The measured ceiling of the effect is docked p99 15.21 / 16.12 ms with all `_process` off (V7, 2 runs) and 16.51 ms with only the demo's `_process` off (1 run, 600 frames). The margin is at most 1.5 ms, so this does not guarantee a pass on this rig. Check: as R8, plus the bench's `jq -e '.docked_control.p99_ms <= 16.7'`, on two quiet runs.
- **OQ4: Record the rig's presentation floor beside the docked control** (a bench-driver change, with its own drill). The bench would measure an empty window of the same size and flags (Appendix B, about 15 s) and print `bench-bridge: presentation floor p99 …` with a `presentation_floor` key in `bench-bridge.json`. The 16.7 rule on the docked control does not change. This only gives each run evidence of whether the rig itself is at the bound. Check: `grep -q '^bench-bridge: presentation floor' .godot/tmp/bench-bridge.log && jq -e '.presentation_floor.p99_ms | type=="number"' .godot/tmp/bench-bridge.json`.
- **Measured and not sufficient (listed because D-127 C proposed it):** a longer docked control of 1,500–3,000 frames after warm-up (p99 17.49–18.61 in 6 of 6), or after the transit (16.87–17.03 in 3 of 3). It would still be invalid under the unchanged rule. Running the control on Vulkan instead (16.12 and 16.89, V5) is also not a reliable pass, and it is not the player's driver.

## Risks and mitigations

- **Pacing depends on the rig's display state.** These numbers hold only with no display attached (R9). A display, Screen Sharing or another agent's window changes them. Mitigation: R9 records the state, and every run sits beside its quiet readings.
- **Small samples on two claims.** The demo-only ablation is one 600-frame run, and the all-off result is two runs. They are stated as such, and R8 reproduces the larger effect.
- **The probe perturbs what it measures.** The probe adds two signal handlers and a dictionary per frame. The `--timed` subclass (P5) adds about 15 timer reads per frame. Its docked p99 (C 17.87, L 18.16) sits inside the range of the untimed runs, and the bench driver itself (V0, V12) shows the same premise.

## Deliverables

- This doc, committed on `design/m4-7md-docked-p99`.
- No code, no tools, no tracked probes. The probes are reproducible from Appendices A–C.

## Appendix A: the docked probe (scratch copy of the bench's setup, instrumented)

Flags: `--long=N` (L frames, default 1500), `--post=N` (P frames), `--skip-transit`, `--noproc=N` (after L, turn every `_process` off for N frames), `--ablate=N` (after L, N frames with each processing node off in turn), `--timed` (load Appendix C's subclass from `/tmp/iter67_probe/demo_timed.gd`), `--out=PATH` (per-frame JSON). Per frame it records: `dt`, the wall interval; `proc`, game main-thread time (`process_frame` → `frame_pre_draw`); `draw` (`frame_pre_draw` → `frame_post_draw`); `other` (the rest); the measured CPU and GPU time of the root, sky and ship viewports; draw calls; and CanvasItem `draw` signals.

```gdscript probe_docked.gd
extends SceneTree
## iter67 row 7m-d probe (scratch, untracked). A copy of tools/m4_ship_bench.gd's setup with per-frame
## instrumentation: wall dt, process/physics ms, RenderingServer draw ms (frame_pre_draw..frame_post_draw),
## viewport measured CPU/GPU ms, draw calls, CanvasItem draw-signal counts and the nodes that process.
## Phases: W = the bench's 120 warm-up frames, C = the bench's 300-frame docked control (same frames),
## L = 1,500 further docked frames, T = the bench's 30 s live transit, P = 1,500 static frames after it.
## Args: --tier=medium --out=/tmp/... --long=1500 --post=1500 [--skip-transit]
const SIZE := Vector2i(2560, 1440)
const DECK := [30.0, 0.47]
var demo: Node
var out_path := "/tmp/iter67_probe/out.json"
var long_n := 1500
var post_n := 1500
var skip_transit := false
var noproc_n := 0
var ablate_n := 0
var timed := false
var pre_us := 0
var post_us := 0
var draw_us := 0
var draws := {}      # CanvasItem path -> draw signal count (reset per phase)
var draw_total := 0
var draw_prev := 0
var rows := []       # every frame
var frame_idx := 0
var phase := "pre"
var prev := 0


func _initialize() -> void:
	_run.call_deferred()


func _on_pre() -> void:
	pre_us = Time.get_ticks_usec()


func _on_post() -> void:
	post_us = Time.get_ticks_usec()
	draw_us = post_us - pre_us


func _count_draw(path: String) -> void:
	draws[path] = int(draws.get(path, 0)) + 1
	draw_total += 1


func _vp_ms(vp: Viewport) -> Array:
	var rid := vp.get_viewport_rid()
	return [RenderingServer.viewport_get_measured_render_time_cpu(rid), RenderingServer.viewport_get_measured_render_time_gpu(rid)]


func _frame() -> void:
	await process_frame
	var now := Time.get_ticks_usec()
	var r := {"i": frame_idx, "ph": phase, "dt": (now - prev) / 1000.0,
		"proc": (pre_us - prev) / 1000.0, "other": (now - post_us) / 1000.0,
		"phys1s": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw": draw_us / 1000.0, "setup": RenderingServer.get_frame_setup_time_cpu(),
		"calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"root": _vp_ms(root), "sky": _vp_ms(demo.sky), "ship": _vp_ms(demo.geometry_view),
		"canvas": draw_total - draw_prev}
	draw_prev = draw_total
	rows.append(r)
	frame_idx += 1
	prev = now


func _frames(n: int, name: String) -> void:
	phase = name
	for i in n:
		await _frame()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out_path = arg.trim_prefix("--out=")
		if arg.begins_with("--long="): long_n = int(arg.trim_prefix("--long="))
		if arg.begins_with("--post="): post_n = int(arg.trim_prefix("--post="))
		if arg == "--skip-transit": skip_transit = true
		if arg.begins_with("--noproc="): noproc_n = int(arg.trim_prefix("--noproc="))
		if arg.begins_with("--ablate="): ablate_n = int(arg.trim_prefix("--ablate="))
		if arg == "--timed": timed = true
	root.size = SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = SIZE
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var tier := "medium"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tier="): tier = arg.trim_prefix("--tier=")
	var scr := DisplayServer.window_get_current_screen()
	print("probe: screens %d, current %d, size %s, refresh %.3f Hz, scale %.2f, driver %s, adapter %s, thread model %s, frame queue %s, swapchain %s" % [
		DisplayServer.get_screen_count(), scr, DisplayServer.screen_get_size(scr), DisplayServer.screen_get_refresh_rate(scr),
		DisplayServer.screen_get_scale(scr), RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_video_adapter_name(),
		ProjectSettings.get_setting("rendering/driver/threads/thread_model"), ProjectSettings.get_setting("rendering/rendering_device/vsync/frame_queue_size"),
		ProjectSettings.get_setting("rendering/rendering_device/vsync/swapchain_image_count")])
	RenderingServer.frame_pre_draw.connect(_on_pre)
	RenderingServer.frame_post_draw.connect(_on_post)
	await process_frame
	if timed:
		demo = load("/tmp/iter67_probe/demo_timed.gd").new()
		demo.name = "ShipGeometryDemo"
	else:
		demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": SIZE, "sky_state": "rest", "seed": 424242, "ai": false, "tier": tier}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	if not demo.ready_ok:
		print("probe: FAIL demo not ready"); quit(1); return
	for vp: Viewport in [root, demo.sky, demo.geometry_view]:
		RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	_hook()
	_pose()
	prev = Time.get_ticks_usec()
	await _frames(120, "W")
	draws.clear()
	await _frames(300, "C")
	var draws_c := draws.duplicate()
	_inventory("docked", draws_c, 300)
	draws.clear()
	if timed: demo._sec_on = true
	await _frames(long_n, "L")
	if timed:
		demo._sec_on = false
		var tot := 0
		for k in demo._sec: tot += 0 if k == "_start" else demo._sec[k]
		for k in demo._sec: print("probe: timed L %-42s %.3f ms/frame" % [k, demo._sec[k] / 1000.0 / long_n])
		print("probe: timed L total _process %.3f ms/frame" % [tot / 1000.0 / long_n])
	var draws_l := draws.duplicate()
	_inventory_draws("docked long", draws_l, long_n)
	if ablate_n > 0:
		var procs := root.find_children("*", "Node", true, false).filter(func(n): return n.is_processing())
		for k in procs.size():
			procs[k].set_process(false)
			await _frames(ablate_n, "A%d" % k)
			procs[k].set_process(true)
			_summary_short("A%d" % k, "without " + str(root.get_path_to(procs[k])))
		await _frames(ablate_n, "A_all_on")
		_summary_short("A_all_on", "all on")
	if noproc_n > 0:
		var off := 0
		for node: Node in root.find_children("*", "Node", true, false):
			if node.is_processing() or node.is_physics_processing():
				node.set_process(false); node.set_physics_process(false); off += 1
		print("probe: N: disabled _process on %d nodes (the demo, sky, sound, star id, frame check)" % off)
		await _frames(noproc_n, "N")
	if not skip_transit:
		phase = "commit"
		if not await _commit():
			print("probe: FAIL departure"); _finish(); return
		for i in 30: await _frame()
		var deadline := Time.get_ticks_msec() + 30000
		while demo.consoles.dolly_active() and Time.get_ticks_msec() < deadline:
			await _frame()
		_pose()
		demo.journey_auto_tick = true
		for i in 120: await _frame()
		_hook()
		draws.clear()
		print("probe: T start: navigation_window visible %s, focused console \"%s\"" % [demo.navigation_window.visible, demo.consoles.focused])
		phase = "T"
		var started := Time.get_ticks_usec()
		var tn := 0
		while (Time.get_ticks_usec() - started) / 1e6 < 30.0:
			await _frame(); tn += 1
		print("probe: T end: navigation_window visible %s" % demo.navigation_window.visible)
		_inventory_draws("live transit", draws.duplicate(), tn)
		demo.journey_auto_tick = false
		for i in 60: await _frame()  # let a pipelined tick drain
		_hook()
		draws.clear()
		await _frames(post_n, "P")
		_inventory("post-transit static", draws.duplicate(), post_n)
	_finish()


func _inventory(label: String, d: Dictionary, n: int) -> void:
	_inventory_draws(label, d, n)
	var procs := []
	for node: Node in root.find_children("*", "Node", true, false):
		var s: Script = node.get_script()
		if node.is_processing() or node.is_physics_processing():
			procs.append("%s [%s]%s%s" % [root.get_path_to(node), s.resource_path if s else node.get_class(),
				" process" if node.is_processing() else "", " physics" if node.is_physics_processing() else ""])
	print("probe: %s: %d nodes with _process/_physics_process enabled" % [label, procs.size()])
	for p in procs: print("probe:   proc " + p)
	var nav = demo.get("navigation_window")
	if nav != null:
		print("probe: %s: navigation_window visible %s" % [label, nav.visible])


func _inventory_draws(label: String, d: Dictionary, n: int) -> void:
	var keys := d.keys()
	keys.sort_custom(func(a, b): return d[a] > d[b])
	var total := 0
	for k in keys: total += d[k]
	print("probe: %s over %d frames: %d draw signals from %d CanvasItems" % [label, n, total, keys.size()])
	for k in keys.slice(0, 25):
		var ci: CanvasItem = root.get_node_or_null(NodePath(k))
		print("probe:   draw %5d  %s%s" % [d[k], k, (" [%s] visible_in_tree %s" % [ci.get_class() if ci.get_script() == null else ci.get_script().resource_path, ci.is_visible_in_tree()]) if ci else ""])


func _finish() -> void:
	if demo != null and demo.journey_sim != null:
		demo.journey_sim.stop()
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(rows))
	f.close()
	for ph in ["W", "C", "L", "N", "T", "P"]:
		_summary(ph)
	print("probe: wrote %d rows to %s" % [rows.size(), out_path])
	print("probe: DONE")
	quit(0)


func _pct(sorted: Array, q: float) -> float:
	return sorted[ceili(sorted.size() * q) - 1]


func _summary(ph: String) -> void:
	var sel := rows.filter(func(r): return r.ph == ph)
	if sel.is_empty(): return
	var dts := sel.map(func(r): return r.dt); dts.sort()
	var edges := [8.0, 9.0, 9.5, 10.5, 11.0, 12.0, 14.0, 16.7, 20.0, 25.0, 35.0, 1e9]
	var hist := []; hist.resize(edges.size()); hist.fill(0)
	for v in dts:
		for b in edges.size():
			if v <= edges[b]: hist[b] += 1; break
	var mean := 0.0
	for v in dts: mean += v
	mean /= dts.size()
	print("probe: phase %s n %d mean %.2f p50 %.2f p95 %.2f p99 %.2f max %.2f over16.7 %d" % [ph, dts.size(), mean, _pct(dts, .5), _pct(dts, .95), _pct(dts, .99), dts[-1], dts.filter(func(v): return v > 16.7).size()])
	print("probe: phase %s hist (<=8,<=9,<=9.5,<=10.5,<=11,<=12,<=14,<=16.7,<=20,<=25,<=35,>35) %s" % [ph, hist])
	# 0.5 ms modes from 0 to 25 ms
	var modes := {}
	for v in dts:
		var k := snappedf(floorf(v * 2.0) / 2.0, 0.5)
		modes[k] = int(modes.get(k, 0)) + 1
	var mk := modes.keys(); mk.sort_custom(func(a, b): return modes[a] > modes[b])
	print("probe: phase %s top 0.5ms modes %s" % [ph, mk.slice(0, 6).map(func(k): return "%.1f:%d" % [k, modes[k]])])
	for col in ["proc", "draw", "other", "setup", "calls", "canvas"]:
		var vs := sel.map(func(r): return float(r[col])); vs.sort()
		print("probe: phase %s %s p50 %.2f p99 %.2f max %.2f" % [ph, col, _pct(vs, .5), _pct(vs, .99), vs[-1]])
	for vpn in ["root", "sky", "ship"]:
		var c := sel.map(func(r): return float(r[vpn][0])); c.sort()
		var g := sel.map(func(r): return float(r[vpn][1])); g.sort()
		print("probe: phase %s vp %s cpu p50 %.3f p99 %.3f gpu p50 %.3f p99 %.3f max %.3f" % [ph, vpn, _pct(c, .5), _pct(c, .99), _pct(g, .5), _pct(g, .99), g[-1]])
	var slow := sel.filter(func(r): return r.dt > 16.7)
	var first: int = sel[0].i
	# Bimodality and alternation: fast <= 8 ms, slow >= 12 ms; pair sums of consecutive frames.
	var fast_n := 0; var slow_n := 0; var s_then_f := 0; var f_then_s := 0; var pairs := []
	for j in sel.size():
		var v: float = sel[j].dt
		if v <= 8.0: fast_n += 1
		if v >= 12.0: slow_n += 1
		if j > 0:
			var u: float = sel[j - 1].dt
			if u >= 12.0 and v <= 8.0: s_then_f += 1
			if u <= 8.0 and v >= 12.0: f_then_s += 1
			pairs.append(u + v)
	pairs.sort()
	print("probe: phase %s fast(<=8) %d slow(>=12) %d slow->fast %d fast->slow %d; pair-sum p50 %.2f p99 %.2f" % [ph, fast_n, slow_n, s_then_f, f_then_s, _pct(pairs, .5), _pct(pairs, .99)])
	var quint := [0, 0, 0, 0, 0]
	for r in slow: quint[mini(4, int(5.0 * (r.i - first) / sel.size()))] += 1
	print("probe: phase %s frames > 16.7 by fifth of the window %s; indices %s" % [ph, quint, slow.map(func(r): return r.i - first)])
	for r in slow.slice(0, 40):
		print("probe:   slow %s k=%d dt %.2f game %.2f draw %.2f other %.2f prevdt %.2f calls %d canvas %d" % [ph, r.i - first, r.dt, r.proc, r.draw, r.other, rows[r.i - 1].dt if r.i > 0 else -1.0, r.calls, r.canvas])


func _pose() -> void:
	demo.camera.follow(demo.avatar_pos, DECK[0], DECK[1], 0.0)
	demo._sync_observer()


func _commit() -> bool:
	if not demo.consoles.walk_to("navigation"): return false
	var deadline := Time.get_ticks_msec() + 30000
	while not demo.consoles.walking.is_empty() and Time.get_ticks_msec() < deadline:
		await _frame()
	for action in [["open", null], ["select", "CNS5:3627"], ["commit", null]]:
		if not demo.consoles.use("navigation", action[0], action[1]): return false
	var ok: bool = demo.journey_tick()
	return ok and demo.live_journey and demo.journey_sim.world.journey.state == "committed"


## Hook every CanvasItem's draw signal (all windows and SubViewports); re-run to catch new ones.
func _hook() -> void:
	var items := root.find_children("*", "CanvasItem", true, false)
	var added := 0
	for ci: CanvasItem in items:
		if ci.has_meta("iter67_hooked"): continue
		ci.set_meta("iter67_hooked", true)
		ci.draw.connect(_count_draw.bind(str(root.get_path_to(ci))))
		added += 1
	print("probe: hooked %d new CanvasItems (%d in tree)" % [added, items.size()])


func _summary_short(ph: String, label: String) -> void:
	var sel := rows.filter(func(r): return r.ph == ph)
	var dts := sel.map(func(r): return r.dt); dts.sort()
	var g := sel.map(func(r): return r.proc); g.sort()
	var mean := 0.0
	for v in g: mean += v
	print("probe: ablate %s (%s): n %d game ms mean %.3f p50 %.3f p99 %.3f; frame p50 %.2f p99 %.2f over16.7 %d" % [ph, label, dts.size(), mean / g.size(), _pct(g, .5), _pct(g, .99), _pct(dts, .5), _pct(dts, .99), dts.filter(func(v): return v > 16.7).size()])
```

## Appendix B: the empty-window probe (presentation floor)

Flags: `--frames=N` (default 1500), `--vsync=on`. It uses the same window setup as the bench (2560×1440, content scale, `max_fps` 0) and one ColorRect.

```gdscript probe_empty.gd
extends SceneTree
## iter67 row 7m-d baseline (scratch): the bench's window setup (2560x1440, content scale, vsync off,
## max_fps 0) with NO game scene, only a ColorRect, so frame pacing = presentation + engine floor.
## Args: --frames=1500 [--vsync=on]
const SIZE := Vector2i(2560, 1440)
var pre_us := 0
var post_us := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var n := 1500
	var vs := DisplayServer.VSYNC_DISABLED
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frames="): n = int(arg.trim_prefix("--frames="))
		if arg == "--vsync=on": vs = DisplayServer.VSYNC_ENABLED
	root.size = SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = SIZE
	DisplayServer.window_set_vsync_mode(vs)
	Engine.max_fps = 0
	var rect := ColorRect.new(); rect.color = Color(0.1, 0.1, 0.2); rect.size = Vector2(SIZE)
	root.add_child(rect)
	RenderingServer.frame_pre_draw.connect(func(): pre_us = Time.get_ticks_usec())
	RenderingServer.frame_post_draw.connect(func(): post_us = Time.get_ticks_usec())
	var scr := DisplayServer.window_get_current_screen()
	print("empty: driver %s, refresh %.3f Hz, window %s, vsync mode %d" % [RenderingServer.get_current_rendering_driver_name(), DisplayServer.screen_get_refresh_rate(scr), root.size, DisplayServer.window_get_vsync_mode()])
	for i in 120: await process_frame
	var dts := []; var draws := []
	var prev := Time.get_ticks_usec()
	for i in n:
		await process_frame
		var now := Time.get_ticks_usec()
		dts.append((now - prev) / 1000.0); draws.append((post_us - pre_us) / 1000.0)
		prev = now
	var s := dts.duplicate(); s.sort()
	var mean := 0.0
	for v in s: mean += v
	mean /= s.size()
	var edges := [2.0, 4.0, 6.0, 8.0, 9.5, 10.5, 12.0, 14.0, 16.7, 20.0, 1e9]
	var hist := []; hist.resize(edges.size()); hist.fill(0)
	for v in s:
		for b in edges.size():
			if v <= edges[b]: hist[b] += 1; break
	var d := draws.duplicate(); d.sort()
	print("empty: n %d mean %.2f p50 %.2f p95 %.2f p99 %.2f max %.2f over16.7 %d; draw p50 %.2f p99 %.2f" % [s.size(), mean, s[ceili(n * .5) - 1], s[ceili(n * .95) - 1], s[ceili(n * .99) - 1], s[-1], s.filter(func(v): return v > 16.7).size(), d[ceili(n * .5) - 1], d[ceili(n * .99) - 1]])
	print("empty: hist (<=2,<=4,<=6,<=8,<=9.5,<=10.5,<=12,<=14,<=16.7,<=20,>20) %s" % [hist])
	print("empty: first 24 frame ms %s" % [dts.slice(0, 24).map(func(v): return "%.1f" % v)])
	print("empty: DONE")
	quit(0)
```

## Appendix C: the timed demo subclass (V7 P5)

This generates `/tmp/iter67_probe/demo_timed.gd`: `ShipGeometryDemo._process`, copied verbatim from the tree, with a section timer inserted at each mark. Run it from the repo root, then pass `--timed` to the Appendix A probe. If the body of `_process` changes, check that all 15 marks still land (`grep -c "_mark(" /tmp/iter67_probe/demo_timed.gd` prints 17).

```sh
end=$(awk 'NR>476 && /^func /{print NR-1; exit}' demos/ship_geometry_demo.gd)  # _process starts at line 476 on dc4cc3f5
{ cat <<'EOF'
extends "res://demos/ship_geometry_demo.gd"
## iter67 scratch: the demo's _process body copied verbatim (main dc4cc3f5) with section timers.
var _sec := {}
var _sec_t := 0
var _sec_on := false
func _mark(name: String) -> void:
	var now := Time.get_ticks_usec()
	if _sec_on: _sec[name] = int(_sec.get(name, 0)) + (now - _sec_t)
	_sec_t = now
EOF
sed -n "476,${end}p" demos/ship_geometry_demo.gd | awk '
NR==1 {print; print "\t_mark(\"_start\")"; next}
/^\tif not ready_ok:return/ {print "\t_mark(\"a telescope+upload poll\")"; print; next}
/^\t_update_tour_attitude\(delta\)/ {print; print "\t_mark(\"b pointer+exposure flag+tour attitude\")"; next}
/^\tconsoles.advance\(delta\)/ {print "\t_mark(\"c ticks+walk\")"; print; print "\t_mark(\"d consoles.advance\")"; next}
/^\tif dressing!=null:dressing.update/ {print "\t_mark(\"e aim+lift+level+avatar\")"; print; print "\t_mark(\"f dressing.update\")"; next}
/^\tcaptain_ring.visible=/ {print "\t_mark(\"g director\")"; print; next}
/^\t_sync_observer\(\)/ {print "\t_mark(\"h ring+fade+shadow+animate captain\")"; print; print "\t_mark(\"i _sync_observer\")"; next}
/^\tsky.finish_exposure_frame\(delta\)/ {print; print "\t_mark(\"j sky.finish_exposure_frame\")"; next}
/^\tstar_light.update\(lighting,sky,delta\)/ {print; print "\t_mark(\"k star_light.update\")"; next}
/^\t_update_hud\(delta,details\)/ {print "\t_mark(\"l view_name+details string\")"; print; print "\t_mark(\"m _update_hud\")"; next}
/^\t_update_wait_hint\(\)/ {print; print "\t_mark(\"n _update_wait_hint\")"; next}
/^\t_update_dwell\(delta\)/ {print; print "\t_mark(\"o _update_dwell\")"; next}
{print}'; } > /tmp/iter67_probe/demo_timed.gd
```
