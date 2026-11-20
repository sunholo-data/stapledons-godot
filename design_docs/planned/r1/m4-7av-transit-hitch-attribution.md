# Live transit: what the hitch tail that decides AC12 is made of (queue row 7av)

**Status:** Planned (mission iteration 105, designer). A measured attribution, **not a fix**; it stops at Open questions. **Both probe runs failed their post reading, so no run here is counted** (D-147 Q1 B). Every number below is evidence, with the condition it was taken under stated. **Release:** r1. **Milestone:** M4.6, gated half (row 7m AC1, M4 AC12, bar clause 4). Item class `[LOOP]`, measurement only; the GPU half is PARKED-ON-LANE again (V2, V4). **Revised once** after design quorum round 1 (see "Quorum verification log"): the apparatus is now in the appendices with sha256s and an extraction command, the raw runs are in the public bucket (Raw artifacts), R1's gate fails closed, the codebase premises are quoted (P0–P3), and p1's quiet stretch is labelled inferred-quiet.
**Priority:** P1. Row 7av is clause 4's critical path.
**Implements:**
- Charter row **7av** ([stapledon-mission.md](../../stapledon-mission.md), search `7av.`): attribute the slow frames in live transit (draw vs game; GC, shader compile, sim reply and map work as candidates), then propose a fix with headroom (target p99 ≤ 16.2 ms on valid-control runs), and measure the docked control's validity rate.
- [m4-first-journey.md](m4-first-journey.md) **AC12**: `make bench SCENE=bridge`, live-transit p99 < 16.7 ms at 2560×1440.
- Row **7m** (M4.6pR3) AC1, reopened by [design_docs/reports/7m-ac1-iteration-103.md](../../reports/7m-ac1-iteration-103.md) (9 bench runs, 1 countable, a MISS at 16.813 ms).
- [m4-7md-docked-p99-attribution.md](m4-7md-docked-p99-attribution.md) (row 7m-d): the method this doc extends (`quiet2.sh`, the draw bracket, CanvasItem draw hooks), and its side finding that the hidden navigation window redraws in transit.
- [m4-6pr3-live-transit-frame-cost.md](m4-6pr3-live-transit-frame-cost.md) (row 7m): Risks, "the residual hitches … UNMEASURED". This doc measures them.
- Ledger **D-147** (the 16.7 bound and the docked-control validity rule stay; Mark's alone) and **D-14** (the 60 fps bar). Not changed here.
- No physics changes: no SR or GR visual is touched, so physics gate 2 is not triggered.

**Depends on:** nothing. Measured in a fresh clone of main `ad929704` (2026-11-19), AILANG v0.56.1 (`runtime/bin/ailang`), Godot 4.7.2.stable.official.ed1daf0bf, Apple M4 Max, Metal, Forward+, 2560×1440, medium tier, vsync off.
**Estimated LOC:** 0 of code. This doc only. The probe and its glue are in the appendices, untracked.

## Game vision alignment

Scored with the `game-vision-designer` skill's feature-validation method against `../stapledons-design/vision/core-pillars.md`, plus this repo's hard-sci-fi spec row. Unattended run, no interview: each pillar was checked for whether the work serves it or conflicts with it.

| Pillar | Score | Notes |
|---|---:|---|
| Choices Are Final | 0 | Nothing in the game changes. |
| The Game Doesn't Judge | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | The sim, the clocks and the pacing are untouched. |
| The Ship Is Home | 0 | The doc explains why the bridge stutters in transit on this rig; it does not change it. The options (OQ2, OQ3) would serve this pillar, and they are Mark's call. |
| Grounded Strangeness | 0 | Not relevant. |
| We Are Not Built For This | 0 | Not relevant. |
| Hard sci-fi authenticity (spec) | 0 | Nothing physical changes. |
| **Net** | **0** | **Go, as measurement on clause 4.** No pillar is negative. Its value is that AC12's tail gets a cause, and the next counted run gets a contention check. |

## Problem

On main, `make bench SCENE=bridge` gives a live-transit p50 of about 10.6 ms in every run, but 23–47 of about 3,200 frames per 30 s run exceed 16.7 ms (max 55–98 ms). That tail alone sets the p99 at 16.24–17.17 ms against the 16.7 bound, on HEAD and on iteration 75's base alike (iteration-103 report). The docked control was valid (p99 ≤ 16.7) in 1 of 9 of those runs. Row 6pR3 left the tail's source UNMEASURED; row 7m-d found that the docked tail sits in the draw bracket and named a presentation-pacing contribution as an inference.

## Attribution (the result)

**Measured, in two probe runs (neither counted; both post readings NO): the large majority of slow transit frames fall in intervals when the local Ollama model runner was active, and inside those intervals most of their wall time is in the draw bracket. In p1's **inferred-quiet** stretch (the first 18.76 s of transit, the whole boosting phase: V1 carried no sampler, so the absence of contention is inferred from frame-time steadiness; R1's sampler run is the verification), the transit p99 was 15.59 ms with 5 slow frames in 1,840, all in the draw bracket. Inferred, not verified on a counted run: the 23–47-frame tail of iteration 103's bench runs is mostly in-run contention that a pre-run reading and a reading 3 s after exit cannot see. Not supported by any measurement here: a game-side defect large enough to explain the tail on a quiet rig. The quiet cruising phase is UNMEASURED.**

Slow frames (> 16.7 ms) in the two GPU probe runs, by largest component (Appendix A classifier: the larger of the draw bracket and game time; "sim wait" when the SimBridge send/drain time is over half of game time):

| run | slow frames | draw bracket | game: sim reply wait | game: tick frame, not sim wait | events + physics | pipeline compiles in T | in a contended interval |
|---|---:|---:|---:|---:|---:|---:|---:|
| p1 (V1) | 268 | 234 | 32 | 2 | 0 | 0 | 263 (after 18.8 s; onset inferred, V1) |
| p2 (V5) | 513 | 445 | 56 | 12 | 0 | 0 | 513 (Ollama runner busy throughout T, sampler V5) |
| **both** | **781** | **679 (86.9 %)** | **88 (11.3 %)** | **14 (1.8 %)** | **0** | **0** | **513 of 513 sampler-verified (p2) plus 263 of 268 inferred-onset (p1)** |

1. **The tail is contention-shaped, not steady-state** [V1, V5]. p1's transit ran at 100-frame means of 9.5–10.5 ms with 0–2 slow frames per 100 for 18.4 s, then stepped to means of 30–39 ms and 77–78 slow frames per 100 until the end; its post reading was GPU 100/100/100. p2's in-run sampler (Appendix B) shows the Ollama runner at 16–60 % CPU from 1.6 s before T, 96–100 % from 6.1 s, and the GPU at 100 % from 9.3 s to the end; p2's frames go from 19 slow in the first 8.3 s (844 frames) to 41–59 slow per 2 s from 8 s on. Neither run's pre reading (05:26:56 GPU 0/2/11; 05:52:41 GPU 6/11/10) could have predicted this: both runs started in a quiet gap of under a minute between model calls (V2, V4: 66 readings over two 10-minute waits, all NO; 64 had the GPU busy, and the 2 with an idle GPU failed on a 1-min load of 7.1–7.9).
2. **Inferred-quiet, the transit tail is small and draw-bracket only** [V1, first 1,840 frames; inferred-quiet: V1 carried no sampler, so the absence of contention is inferred from frame-time steadiness; R1's sampler run is the verification]. p50 10.66, p95 13.02, **p99 15.59**, max 19.16 ms, 5 slow frames (draw 14.96–17.82 ms, game 1.29–1.79 ms, no tick, no CanvasItem draw, no pipeline compile, static-memory delta −4.3 to +2.1 KB). That is 7m-d's docked shape (243 of 245 slow frames in the draw bracket) and its empty-window floor (p99 15.86–16.28): inferred presentation pacing, mechanism UNVERIFIED without a Metal trace. One run, 1,840 frames: its p99 rests on about 18 frames.
3. **The sim tick costs about 8.7 ms of game time, and the draw bracket absorbs it** [V1 quiet stretch]. 375 tick frames: game p50 8.69 ms (p99 11.13), of which SimBridge send/drain p50 1.13 ms, so about **7.6 ms of per-tick main-thread work besides the sim** (p99 9.84); draw p50 1.22 ms; frame p50 10.02, p99 13.56, **0 over 16.7**. The 1,465 frames without a tick: game 1.60, draw 9.74. Game + draw is about 10 ms either way. On a quiet rig the tick's cost is hidden by pacing; under contention it is not: in p2's first 8.3 s, four tick frames read game 18.9–21.1 ms with sim waits of only 1.1–1.4 ms [V5], i.e. the same per-tick work, inflated about 2.5×. Inferred cause of the inflation: memory-bandwidth or CPU contention from the model runner (V3 shows the sim slows under it with no Godot rendering at all).
4. **The per-tick work includes the hidden navigation window's redraw** [V3, V1]. In transit, 36 CanvasItems emit 7,925 `draw` signals per 30 s (V3, headless; 7m-d V8 counted 7,985). The GalaxyMap overlay `Control`, `EarthBeams`, the MapDetails progress bar and labels each redraw 589–590 times, once per 20 Hz tick, while `navigation_window.visible` is false; `GalaxyMap.tick()` → `refresh()` rebuilds the whole hidden panel's text and bindings each tick (`ui/galaxy_map.gd` `refresh`). The rest are visible bridge HUD items (status strip, transit card, console screens). Tick frames carry 13 draw signals at p50 [V1]. **How much of the 7.6 ms is this redraw is UNMEASURED** (the `--ablate-map` run, V6).
5. **Sim reply waits: small when quiet, large under contention, and one hitch at cruise start** [V1, V3, V5, V7]. Inferred-quiet boosting (V1): 374 tick frames, wait p50 1.13, p99 1.32, max under 5 ms. Under contention: waits of 13–369 ms (p1 cruising p90 19.2, p99 45.4; headless h1 boosting p99 92.3). Within 4–10 frames of the boosting → cruising switch, all four runs show slow replies as the `crew` section starts arriving: 35–53 ms in three (p1 50.5 ms → a 61.3 ms frame; h1 52.8; h2 35.1, on the first `crew` reply, a 40 KB line) and 16–38 ms in p2, which was fully contended by then. In cruise, 128 of 591 replies carry `crew`; under contention their waits run longer (11 of 128 over 20 ms, against 6 of 463 without; max 369 ms) [V7]. All of these were taken under contention, so **whether the cruise-start wait exceeds the 50 ms pipelining window on a quiet rig is UNMEASURED**. It is a plausible source of the iteration-103 maxima of 55–98 ms (one frame per run), not of the 23–47-frame tail.
6. **Ruled out as tail sources, in these runs:** shader or pipeline compilation (the five `Performance.PIPELINE_COMPILATIONS_*` monitors exist in Godot 4.7; 12 compiles in each run, all before transit, 0 in T in both runs); garbage collection (Godot frees by reference count; the slow frames show no static-memory or object-count signature distinct from fast ones: p1 slow-frame static-memory delta p50 −1.2 KB against +2.2 KB for fast frames); input/event and physics time (p99 0.13 and 0.09 ms).

**Docked-control validity (the precondition)** [V1, V5]. Probe phase C (the bench's 300 docked frames, same setup): p1 **16.774 ms (invalid, by 0.07)**, 6 over, all draw > game; p2 **15.481 ms (valid)**, 1 over. With iteration 103's 1 of 9, that is **2 of 11 valid**, and both of these were taken just before contention arrived. No bench run was taken here (UNMEASURED, V6).

**Why no confident fix.** On the evidence, a game-side change cannot buy a reliable p99 ≤ 16.2 ms on a rig where the model runner returns mid-run: its contention makes 30–40 ms frames regardless of the game's work (p2: 41–59 slow frames per 2 s). And the one inferred-quiet stretch already reads 15.59 ms without any fix. The candidate fixes below would add margin in the contended regime and against the cruise-start hitch, but their effect is UNMEASURED, so they are options for Mark (OQ2), not a design.

**Confidence.**
- High for p2: 513 of 513 slow frames fall in a sampler-verified contended interval (the runner at 16–100 % CPU throughout T, V5).
- Medium for p1: 263 of 268 slow frames fall after an inferred onset (a step in frame times and a GPU 100/100/100 post reading; no sampler), and its 1,840-frame quiet stretch is inferred-quiet, not verified.
- Medium that iteration 103's tail is the same thing: inferred from the shape (p99 tracked pre-run load there; 4 of 9 post readings failed) and from how short the quiet gaps are now; no counted run with an in-run sampler exists.
- High that shader compiles, GC and event/physics time are not the tail (0 in T; no signature).
- Low on the quiet cruise phase: never measured without contention.

## Verification Log

Predicate: `quiet2.sh` (7m-d lines 79–98; verbatim in Appendix B with its sha256). Every GPU run went through the as-run wrappers in Appendix B (`counted.sh` for V1, `counted2.sh` with the sampler for V5; their paths were `/tmp/stap_i105/…` then; the revised, repo-relative copies are what R1–R5 use): `quiet2.sh` YES first (bounded wait, 15 s retries), the run under `perl alarm 600`, `sleep 3`, `quiet2.sh` again. A run counts only if both readings are YES. Each run's output JSON was deleted before it and listed after it (fresh mtime). All times CET, 2026-11-20. 0 `SCRIPT ERROR` lines in every log.

| # | Time | Pre reading (GPU %, 1-min load, HID idle) | Command | Post reading (+3 s) | Counts | Result |
|---|---|---|---|---|---|---|
| V1 | 05:26:56 (3 NO readings 05:26:00–05:26:37 first, GPU 99–100) | YES: 0/2/11, 3.24, 134,286 s | `counted.sh p1 600 -- godot --audio-driver Dummy --path . --script /tmp/stap_i105/probe/probe_transit.gd -- --tier=medium --out=/tmp/stap_i105/runs/p1.json` (no sampler) | **NO**: 05:28:04 GPU 100/100/100, 2.93 | no (evidence) | C p99 **16.774** (6 over, invalid). T: 2,213 frames, p99 63.02, 268 over, max 91.66. **First 1,840 frames (0–18.76 s, all of boosting): p50 10.66, p95 13.02, p99 15.59, max 19.16, 5 over, all draw.** From k = 1,849 (18.84 s, 10 frames into cruising): a 50.5 ms sim wait (61.3 ms frame), then 100-frame means 30–39 ms to the end. Classes over T in the table above. |
| V2 | 05:29:06–05:39:11 | 33 readings, all NO: 31 with a GPU sample of 80–100 %; 2 (05:30:43, 05:31:03) with the GPU idle (0/0/0, 4/6/0) but a 1-min load of 7.87 and 7.08; load 1.61–11.10 overall; HID idle > 134,000 s; session clause clean | `counted2.sh p2 600 …` (wait only) | — | — | **UNMEASURED**: bounded wait expired. Ollama runner `qwen3.8:27b-mxfp8` (up 4 h) and a `llama-server` were resident. |
| V3 | 05:39:27 | NO: 99/100/100, 2.04 (headless: no GPU window, recorded as evidence only) | `godot --headless --audio-driver Dummy --path . --script …/probe_transit.gd -- --tier=medium --out=…/h1.json` | — | no | Headless: no draw bracket (dummy renderer). **7,925 draw signals from 36 CanvasItems** in T; the hidden map's overlay, `EarthBeams`, progress bar and labels 589–590 each; `navigation_window visible false`. Sim waits under the model runner, no Godot rendering: boosting p90 15.7, p99 92.3 (41 of 354 > 5 ms); cruising p90 18.5, p99 55.4. Cruise switch at k = 1,216; +7 frames a 52.8 ms wait. |
| V4 | 05:40:40–05:50:40 | 33 readings, all NO, each with a GPU sample of 91–100 %; load 1.24–3.12 | `counted2.sh p2 600 …` (wait only) | — | — | **UNMEASURED**: bounded wait expired. |
| V7 | 05:51:28 | NO: 99/100/100, 3.36 (headless, evidence only; V5 below was taken after) | as V3, plus the reply's line length and change keys per frame (`--out=…/h2.json`) | — | no | Replies are 33.0–42.6 KB. The first `crew` section arrives +10 frames after the cruise switch (k = 1,196), a 35.1 ms wait on a 40.1 KB line. In T, 128 of 591 replies carry `crew`: waits p50 1.3, p90 19.2, max 369.1, 11 > 20 ms; without `crew`: p50 1.1, p90 2.3, max 84.7, 6 > 20 ms. |
| V5 | 05:52:41 (third wait, started 05:51:44) | YES: 6/11/10, 3.37, 135,830 s | `counted2.sh p2 480 -- godot … probe_transit.gd -- --tier=medium --out=/tmp/stap_i105/runs/p2.json` with the in-run sampler (Appendix B) | **NO**: 05:53:41 GPU 100/99/99, 4.20 | no (evidence) | C p99 **15.481** (1 over, valid). T: 1,514 frames, p99 86.71, 513 over, max 94.26. Sampler (one sample per 0.6–0.7 s): during setup and the docked control the GPU read 0–54 % and the runner 1–47 % CPU; the runner 16–60 % CPU from −1.6 s, 96–100 % from 6.1 s, GPU 100 % from 9.3 s to the end. First 8.3 s: 844 frames, 19 over: 12 draw-dominant, 7 game-dominant (tick frames with game 9.5–22.8 ms; one of them a 14.0 ms sim wait). 8–30 s: 41–59 over per 2 s, 100-frame means 26–38 ms. |
| V6 | — | — | `counted2.sh a1 … --ablate-map` (the hidden-map ablation), and `make bench SCENE=bridge AILANG=runtime/bin/ailang` ×2 | — | — | **UNMEASURED**: this designer's time bound ended with the GPU at 99–100 % (V5 post reading). |
| D1 | revision, about 06:05 (no GPU window) | n/a | the R1 gate (Appendix B `gate.sh`, the round-1 reviewer's awk verbatim; the sampler's columns are `$2` GPU % and `$4` the runner CPU list, as the awk assumes) on five files | — | — | **p2.gpu (V5's sampler, 79 lines): exit 1, contended.** Empty file (0 lines): **exit 1**. Synthetic file with one `?` sample (3 lines, the revised sampler's `BAD ioreg-miss` form): **exit 1**. Synthetic file whose *second* runner process is at 47 % (1 line): exit 1. Positive control, a clean synthetic file (3 lines; GPU 20–31, runners ≤ 4 %, one `-` for no runner): **exit 0**. |
| D2 | revision (no GPU window) | n/a | Appendix B's extraction command run on this doc in the clone, then `shasum -a 256 -c`, then `.godot/tmp/7av/bin/counted2.sh drill 0 -- true` | — | — | All 7 extracted files matched their listed sha256 (`shasum -c` rc 0; the first attempt caught that the as-run `quiet2.sh` ends in a stray fence-marker line, see B.2). The extracted probe passes `godot --headless --check-only`, and the sampler passes `perl -c`. The wrapper resolved the repo root, read `quiet2.sh` once (06:06:09, GPU 99/100/100, load 6.81: NO) and wrote `.godot/tmp/7av/runs/drill.rec` ending `UNMEASURED: wait expired` / `END`, exit 3, so its paths work from the clone root. `git status` showed only this doc modified (`.godot/` ignored, P0). |

**Codebase premises** (quoted from the clone at `ad929704`; each backs a command or an option above):

| # | Premise | Quote (file:line) | Result |
|---|---|---|---|
| P0 | The extracted apparatus lives in an ignored path | `.gitignore:1` `.godot/`; `git check-ignore -v .godot/tmp/7av/x` → `.gitignore:1:.godot/` | Confirmed: nothing under `.godot/tmp/7av/` can be committed by accident, and `make python-guard` (tracked `*.py` only) does not see `analyse.py`. |
| P1 | R5's paths, JSON keys and log prefixes | `Makefile:13` `SCRATCH := .godot/tmp`; `Makefile:732` `… --script tools/m4_ship_bench.gd -- --tier=$(BRIDGE_TIER) > $(SCRATCH)/bench-bridge.log 2>&1`; `tools/m4_ship_bench.gd:132` `FileAccess.open("res://.godot/tmp/bench-bridge.json", FileAccess.WRITE)`; `:138` `"docked_control": control, "timing": timing,`; `demos/ship_demo_benchmark.gd:21` `return {"samples":n,…,"p99_ms":sorted[ceili(n*.99)-1],"maximum_ms":sorted[-1]}`; log lines `tools/m4_ship_bench.gd:66` `"bench-bridge: docked control 300 frames p50 %.2f p95 %.2f p99 %.2f ms …"`, `:121` `"bench-bridge: live transit %d frames in %.1f s …"`, `:127` `"bench-bridge: frame ms p50 %.3f  p95 %.3f  p99 %.3f …"` | Confirmed: R5's `.godot/tmp/bench-bridge.{log,json}`, `.docked_control.p99_ms`, `.timing.p99_ms` and the three grep prefixes match the instrument. R5 unchanged in substance. |
| P2 | O3's "up to 2 s" drain wait | `ui/galaxy_map.gd:985` `if not sim.drain(): # a pipelined heartbeat (SimBridge.pipelined): decide on the current world`; `bridge/sim_bridge.gd:357` `var ok := _read_state(Time.get_ticks_msec() + 2000, "step_timeout") and _finish(tick)`; `:558` `while Time.get_ticks_msec() < deadline:`; `:561` `var chunk := _pipe.get_buffer(4096)`; `:565` `OS.delay_msec(2)`; `:185` `var proc := OS.execute_with_pipe(AiBridge.scrub_shell(), AiBridge.scrubbed(launch), false)` | Confirmed and sharpened: the drain polls a non-blocking pipe every 2 ms for up to 2,000 ms, then fails with `step_timeout`. |
| P3 | O2's tick → refresh path, and whether SimBridge already has a non-blocking readiness API | `ui/galaxy_map.gd:982` `func tick() -> bool:`; `:1020` `refresh()` (the last statement before `return sent`); `:1257` `func refresh() -> void:`; `:1322` `earth_beams.refresh(_last_view)`; `:1323` `_overlay.queue_redraw()`; `demos/ship_geometry_demo.gd:1187` `var ok:bool=solar_tour.step() if solar_tour!=null else journey_map.tick()`. SimBridge's public methods (`grep -n '^func ' bridge/sim_bridge.gd`): `start`, `hello`, `new_game`, `send`, `in_flight`, `drain`, `stop`, `queue`, `queued_refused`, `caller_refused`; `:345–346` `func in_flight() -> bool:` / `return _inflight >= 0`; `:785–790` `func _fail(code: String) -> bool:` … `_cleanup()` | Confirmed: every tick ends in a full `refresh()` of the hidden panel and a queued overlay redraw. **Verified absence:** no public reply-ready check exists; `in_flight()` reports only that a tick is outstanding, and reusing `_read_state` with a zero deadline would end in `_fail` → `_cleanup()`. O3 would add a non-failing try-read over the existing non-blocking pipe. |

Raw files: see "Raw artifacts" below (public bundle, sha256 per file). The third wait (`p2_wait3_aborted.rec`) was stopped after 1 reading so the headless V7 could run without overlapping a GPU window. **Probe revisions per run:** p1 ran the probe without the `T start unix` print and without the per-frame `line`/`keys` fields; h1 had the `T start unix` print only; h2 and p2 ran the final version in Appendix A (the bundle's `probe/probe_transit.gd`). The two additions are output-only.

## Goals and non-goals

**Goals.** Say what the transit's slow frames are made of, with each claim tied to a V-row; say what a fix could buy; give the next counted run a check that can see in-run contention.

**Non-goals.** No tracked code change, no bench change (`tools/m4_ship_bench.gd` stays the instrument; the probe copies its setup). No change to the 16.7 ms bound or the docked-control validity rule (D-147). No change to the GPU schedule (the model runner is not this loop's).

## Design: the options (for Mark; none is built)

**O1. Contention evidence beside each counted run (measurement, no product change).** Run Appendix B's sampler during every counted AC1 run and keep its file beside the bench log. A run whose in-run samples show the model runner above a few percent CPU, or the GPU at 100 %, is read as contended evidence, like a failed post reading today. This adds evidence to D-147's rule; whether it becomes part of the rule is Mark's (OQ1). Cost: none in the tree if it stays in the runner script; a bench-driver change if it is to live in `bench-bridge.json`.

**O2. Stop redrawing the hidden navigation map on every tick (game-side margin).** The same pattern 6pR3 fixed for `IsmLayer`: while `navigation_window` is hidden, `GalaxyMap.refresh()` (called at the end of every `tick()`, `ui/galaxy_map.gd:1020`; it rebuilds the title, subtitle, status, progress bar, clock and the details grid's bindings, then `earth_beams.refresh` and `_overlay.queue_redraw()`, `:1257–1323`; P3) would skip the panel's text and binding rebuild and `_overlay.queue_redraw()`, and `refresh()` once on show. It touches `ui/galaxy_map.gd` and a test that the map draws the same on show. Predicted effect: lower game time on tick frames (now 8.7 ms p50 quiet, 19–23 ms under contention). On a quiet rig tick frames are already 0 of 375 over 16.7 [V1], so the p99 gain there is predicted to be small; the gain is under contention, and **its size is UNMEASURED** (V6's ablation is the measurement). Risk: anything that reads the hidden map's labels between ticks (the read-only star chart, M) must still be current on show.

**O3. Do not block the frame on a late sim reply (game-side margin, design-heavy).** Today `GalaxyMap.tick()` starts with `sim.drain()` (`ui/galaxy_map.gd:985`), which polls the pipe until the reply arrives or 2 s pass (`bridge/sim_bridge.gd:357`, `:558–566`; P2). If the reply is not in yet, the frame could skip that tick and try again next frame, so a 35–53 ms reply (cruise start, `crew` sections, contention) never stalls a frame. This needs a new non-failing reply-ready check in `SimBridge` (verified absent, P3: `in_flight()` only says a tick is outstanding, and a zero-deadline `_read_state` would end in `_fail`, which calls `_cleanup()`; the pipe itself is already non-blocking, so no new I/O path is needed), and it changes how ticks line up with wall time (not the sim's inputs or outputs, so replays stay byte-identical; to be proven). It would remove the sim-wait class (11.3 % of slow frames) and probably the per-run 55–98 ms maximum. Larger blast radius than O2.

**O4. Make the crew section cheaper at cruise start (upstream).** If the quiet-rig measurement (OQ3) shows the cruise-start reply over 50 ms, its cost is in `crew_core` on the AILANG VM and is reported upstream with a repro, per the project rule, not worked around.

**Predicted headroom.** The inferred-quiet boosting stretch reads p99 15.59 ms with no fix (0.61 ms under 16.2, one run, no sampler). No option is predicted to bring a contended run under 16.2 ms. Valid-control runs with no in-run contention (R1's gate) are therefore the condition under which AC12 is decidable at all; O2 and O3 add margin there only to the extent the quiet cruise phase has tick-frame or sim-wait hitches, which is UNMEASURED.

## Acceptance criteria (each a command, run from the repo root of any clone)

**R0. Recreate the apparatus from this doc** (no `/tmp` paths; `.godot/` is gitignored, P0). Every fenced block below whose info string carries `file=` is extracted to that path, then checked against the listed sha256:

```sh
doc=design_docs/planned/r1/m4-7av-transit-hitch-attribution.md
awk '/^```[a-z]+ file=/{f=substr($2,6); system("mkdir -p \"$(dirname " f ")\""); next} /^```$/{if(f){close(f); f=""}; next} f{print > f}' "$doc"
chmod +x .godot/tmp/7av/bin/*.sh
shasum -a 256 -c <<'SUMS'
5e6fce6b57d6e299658be37b5c796ebf24bdadaf473db1d3fffbf36f6685c518  .godot/tmp/7av/bin/quiet2.sh
2b22eece1166f700bde2f2a1dc2d6d22bc75111e5287bdfb7fd211d8e42b4b22  .godot/tmp/7av/bin/counted.sh
c7c76f67d577ccc08a1bed78aabc60236505ff74feeaff2ae32097cfa6c7fb5f  .godot/tmp/7av/bin/counted2.sh
ceafaa2cbd835e14687aceb9b61fbb8355bcab05d880b7fd5d6471874e99c125  .godot/tmp/7av/bin/gate.sh
21940053253d0afd05ee0325ce987977deff517d2f640ae5446184aef23fe16e  .godot/tmp/7av/bin/gpusampler.pl
75eb8bd224d602491443472ea092f205f157b2165001aa815bf70f1e718f6bdd  .godot/tmp/7av/probe/probe_transit.gd
4135e2b5bf978bf752e22c8c7e12fb667b5e6a3c1a2fee87b583d159cc6f182a  .godot/tmp/7av/probe/analyse.py
SUMS
```

**R1. A run with the in-run sampler, counted only if quiet before, during and 3 s after.** The during-run gate is `gate.sh` (D1: fails closed on an empty file, a `?` sample, any runner process over 5 % CPU, or the GPU at 100 %):

```sh
r=$(git rev-parse --show-toplevel); s=.godot/tmp/7av
rm -f $s/runs/p3.json
$s/bin/counted2.sh p3 600 -- godot --audio-driver Dummy --path . --script $r/$s/probe/probe_transit.gd -- --tier=medium --out=$r/$s/runs/p3.json
test -s $s/runs/p3.json && grep -q '^PRE YES' $s/runs/p3.rec && grep -q '^RC 0$' $s/runs/p3.rec && grep -q '=> YES$' $s/runs/p3.rec \
  && ! grep -q 'SCRIPT ERROR' $s/runs/p3.log && grep -q '^probe: DONE$' $s/runs/p3.log \
  && $s/bin/gate.sh $s/runs/p3.gpu && echo "p3 counts" || echo "p3 is evidence only"
```

**R2. On a counted run, the transit p99, the docked control's validity, the slow-frame split and the compile count** (the attribution predicts transit p99 ≤ 16.2, slow frames in the draw bracket bar at most the cruise-start sim wait, and 0 compiles in T):

```sh
s=.godot/tmp/7av
jq '[.rows[]|select(.ph=="T")|.dt]|sort|.[(length*0.99|ceil)-1]' $s/runs/p3.json
jq '[.rows[]|select(.ph=="C")|.dt]|sort|.[(length*0.99|ceil)-1] <= 16.7' $s/runs/p3.json
grep '^probe: T slow-frame classes' $s/runs/p3.log
jq '[.rows[]|select(.ph=="T")|.pc]|add' $s/runs/p3.json
```

**R3. The hidden map's redraws** (the O2 lead; 4 hidden-map items at about 590 each today, V3):

```sh
grep '^probe:   draw' .godot/tmp/7av/runs/p3.log | grep -c 'Window@.*/GalaxyMap/'
```

**R4. The O2 ablation, counted the same way:** the hidden map's top-level CanvasItems hidden for T; compare the median tick-frame game time and the p99 with R2's run.

```sh
r=$(git rev-parse --show-toplevel); s=.godot/tmp/7av
rm -f $s/runs/a1.json
$s/bin/counted2.sh a1 600 -- godot --audio-driver Dummy --path . --script $r/$s/probe/probe_transit.gd -- --tier=medium --ablate-map --out=$r/$s/runs/a1.json
grep -q 'ABLATION hid' $s/runs/a1.log && grep -q '=> YES$' $s/runs/a1.rec && $s/bin/gate.sh $s/runs/a1.gpu && echo "a1 counts"
jq '[.rows[]|select(.ph=="T")] as $r | [range(1; $r|length) | select($r[.].tick > $r[.-1].tick) | $r[.].proc] | sort | .[(length/2|floor)]' $s/runs/a1.json
jq '[.rows[]|select(.ph=="T")|.dt]|sort|.[(length*0.99|ceil)-1]' $s/runs/a1.json
```

**R5. Two counted bench runs, with the sampler beside them** (paths, keys and prefixes quoted in P1):

```sh
s=.godot/tmp/7av
rm -f .godot/tmp/bench-bridge.log .godot/tmp/bench-bridge.json
$s/bin/counted2.sh b1 600 -- make bench SCENE=bridge AILANG=runtime/bin/ailang
test -s .godot/tmp/bench-bridge.json && grep -q '=> YES$' $s/runs/b1.rec && $s/bin/gate.sh $s/runs/b1.gpu && echo "b1 counts"
grep -E '^bench-bridge: (docked control|frame ms|live transit)' .godot/tmp/bench-bridge.log
jq -e '.docked_control.p99_ms <= 16.7 and .timing.p99_ms <= 16.2' .godot/tmp/bench-bridge.json
```

Repeat R5 as `b2`.

## Risks and mitigations

- **No counted run.** Every number is from a run whose post reading failed or from a headless run. Mitigation: the claims are bounded to "in these runs"; the quiet stretch is labelled inferred-quiet; R1–R5 are the counted repeat.
- **The sampler is coarse and partly ambiguous.** One sample per 0.6–0.7 s. Godot's own load reads 21–54 % on the GPU counter, so the GPU column alone cannot separate Godot from the model runner; the runner CPU column can, which is why the gate checks every runner process and the GPU (D1).
- **The gate may reject runs that were fine.** It covers the whole command, setup included, and the runner can blip above 5 % CPU without using the GPU (V5's first sample read 13.9 % with the GPU at 4 %). That costs runs, not correctness: it fails closed by design.
- **Contention onset in p1 is inferred** (no sampler in V1): from the step in frame times and the GPU 100/100/100 post reading. p2 has the sampler.
- **Classifier bias.** The "draw bracket" class is a wall interval; under contention it includes waiting on a GPU shared with the runner. It says where the wall time went, not why (7m-d's caveat; a Metal System Trace is still UNMEASURED).
- **Probe perturbation.** 634 CanvasItem signal connections and per-frame `Performance` reads. The docked phase C agrees with the bench's band (15.48 and 16.77 against 15.18–19.19 in 7m-d and iteration 103).
- **The quiet gaps are short.** Both GPU runs began in gaps of under a minute. A counted run may need a scheduled GPU window (OQ4).

## Open questions for Mark

- **OQ1. In-run contention evidence for AC1.** Should a counted AC1 run also need the in-run gate clean (R1's `gate.sh`), or stay on the pre and +3 s readings (D-147 Q1 B)? Recommendation: keep the sampler file beside the bench log now (no rule change), and decide on the rule after two counted runs.
- **OQ2. Which game-side margin, if any.** O2 (gate the hidden map's per-tick refresh; small, like 6pR3), O3 (non-failing try-read and skip the tick; larger), both, or neither until the quiet cruise phase is measured. Recommendation: measure R4 first; O2 only if it moves tick-frame game time or the p99.
- **OQ3. The cruise-start reply.** If a counted run shows the first `crew` reply over 50 ms on a quiet rig, report it upstream (O4) and cite it in AC12's record.
- **OQ4. A GPU window for counted runs.** Of 77 `quiet2.sh` readings in this fire, 2 were YES, and both runs that started on them were contended within seconds. A scheduled 10-minute window with the runner paused would make R1–R5 a single sitting.

## Deliverables

This doc. The apparatus in the appendices (extracted by R0, untracked under `.godot/tmp/7av/`). The raw runs in the public bucket (Raw artifacts). No tracked code.

## Raw artifacts

Bundle: **https://storage.googleapis.com/stapledons-voyage-assets/benchmarks/7av-iter105/7av-iter105-evidence.tgz** (`gs://stapledons-voyage-assets/benchmarks/7av-iter105/7av-iter105-evidence.tgz`, 413,344 bytes, sha256 `34ad9ccfa03f2bc0146a87da5c1f46bbdd9a8ef67c56e4ee3775a93265b3ddca`). It is `tar czf 7av-iter105-evidence.tgz -C /tmp/stap_i105 runs probe bin`, the files exactly as the runs used and wrote them (the as-run scripts, not the revised ones). Upload checked with `gcloud storage ls -L` (Content-Length 413344, MD5 `2+Tf4VAqJdQZJAThS/2mtQ==`, created 2026-11-20T05:02:12Z), and a public re-download by `curl` hashed to the same sha256.

```sh
mkdir -p .godot/tmp/7av/evidence && cd .godot/tmp/7av/evidence
curl -sfLO https://storage.googleapis.com/stapledons-voyage-assets/benchmarks/7av-iter105/7av-iter105-evidence.tgz
echo "34ad9ccfa03f2bc0146a87da5c1f46bbdd9a8ef67c56e4ee3775a93265b3ddca  7av-iter105-evidence.tgz" | shasum -a 256 -c && tar xzf 7av-iter105-evidence.tgz
```

| file in the bundle | V-row | sha256 |
|---|---|---|
| `runs/h1.json` | V3 | `66f72427d6408dd8e2a002ea2b858e63c8496912d20844437abc788af8e85279` |
| `runs/h1.log` | V3 | `7b45a22119ef3ddd6d7e939b0b7ac8d938e84c5d502b7f77eb4ce642561ef38a` |
| `runs/h1.rec` | V3 | `ccfd9903c21810ccd29097832adc1ef3232869f6b4e42019d374fcf81b15aef2` |
| `runs/h2.json` | V7 | `671d1c31a773542f50e192777d5052151948b116d4e33049f9ef8ff679ce04cf` |
| `runs/h2.log` | V7 | `6ca7e21401084b5c4d81383c1684a2adcaa7f42c0d054f60babfb28fccaf70c1` |
| `runs/h2.rec` | V7 | `50994c5db12f740f8e2ab733b4f17394f6fd59203e801f15467cd7c12b645127` |
| `runs/p1.json` | V1 | `3267a507aaaf9cf5c06c5600e83cdd2c79a4f09dc8e18b6d71f99f1085a23925` |
| `runs/p1.log` | V1 | `9888ba66e9d604c24b3d59a01078786649dba2140bab84aafd9d54826294fb90` |
| `runs/p1.rec` | V1 | `ec3cd1969e52de3fb953d7e00cfa0dfcd22c2c03992446eecc4162fa38debe71` |
| `runs/p2.gpu` | V5 | `54958725396324de0b17e943bf5c8873b7a00e33ca8552b8e6f030fc6e257d11` |
| `runs/p2.json` | V5 | `5fa7e9250073bfbb04ec982f484a918d2c2b25ced01c2441ac05ca585e42e144` |
| `runs/p2.log` | V5 | `92b32432219e6a876761e91fb93c77752346ed84b7087102af58f12f77dea6eb` |
| `runs/p2.rec` | V5 | `fed15afa178a90e9d52660c30084c483b0fcbe2ce585e37dab5a1c7af595f5ed` |
| `runs/p2_wait1.rec` | V2 | `47a5aaf06c986f1323148e3c864ba7da411a9e8228be5ae725251b9d872f7105` |
| `runs/p2_wait2.rec` | V4 | `bd69bd88feb67f13e4c5aa3f548a2134b8a78a186f7156ea79d743242476a0d0` |
| `runs/p2_wait3_aborted.rec` | V4–V7 (stopped wait) | `d1d9ebed253474f47aaa25f8f335fe73ab842f483511e6d42ccbb2d3f1285fa4` |
| `probe/analyse.py` | findings 1–6 (spike) | `4135e2b5bf978bf752e22c8c7e12fb667b5e6a3c1a2fee87b583d159cc6f182a` |
| `probe/probe_transit.gd` | V5, V7 (final probe; V1, V3 ran it less two output-only additions) | `75eb8bd224d602491443472ea092f205f157b2165001aa815bf70f1e718f6bdd` |
| `bin/counted.sh` | V1 wrapper (as run) | `f388a62b8929914b6a3b6df18bec916ac4805b3d712b417fa7caaae40a768595` |
| `bin/counted2.sh` | V2, V4, V5 wrapper (as run) | `cdffc9a744146e03c95366ca1571bc769ea7821cf54e5745f747048b3331ba21` |
| `bin/gpusampler.pl` | V5 sampler (as run) | `5c048473fe193b2d261f9572034aad5cf7a74abbb69ea28e6a4d545375b15079` |
| `bin/quiet2.sh` | every reading | `e95226d0648437c24f839f5ad0b895a769565ee1e46ff4913ef413bcb93b3df1` |

## Quorum verification log

Round 1 (2026-11-20T04:58Z): oc-kimi-k3 **reject**, oc-glm-5-3 **reject**, gemini-4-argon **pass**, codex absent (quota). Nobody disputed the direction. One revision, applied as follows.

| reviewer | objection | applied |
|---|---|---|
| oc-kimi-k3 | The evidence and the apparatus lived only in `/tmp/stap_i105`; R1–R5 ran against `/tmp` paths; `counted.sh` (V1's wrapper) and `quiet2.sh` were not printed. | Every script is verbatim in Appendix B with its sha256: the as-run `counted.sh`, `counted2.sh`, `gpusampler.pl` (B.1), and the extractable `quiet2.sh`, revised `counted.sh`, `counted2.sh`, `gpusampler.pl`, new `gate.sh` (B.2), plus Appendix A's probe and Appendix D's spike. R0 extracts them to the gitignored `.godot/tmp/7av/` (P0) and checks the sha256s (D2); R1–R5 now run against those repo-relative paths. No tracked code was added (a tracked `.gd` needs a `.uid` and review; a tracked `.py` would fail `make python-guard`). The raw runs are a public bundle with a per-file sha256 table tied to the V-rows (Raw artifacts). |
| oc-kimi-k3, oc-glm-5-3 | p1's "contention-free" stretch is circular (no sampler in V1); the 99.4 % aggregate inherits p2's confidence. | p1's first 1,840 frames are relabelled **inferred-quiet** everywhere (the summary, finding 2, finding 5, predicted headroom), with R1's sampler run named as the verification. The aggregate now reads "513 of 513 sampler-verified (p2) plus 263 of 268 inferred-onset (p1)", and the confidence list splits them (High for p2, Medium for p1). |
| oc-kimi-k3, oc-glm-5-3 | O3's "drain waits up to 2 s" and O2's "refresh rebuilds every tick" were unquoted. | Quoted in P2 and P3 (`ui/galaxy_map.gd:982–1020, 1257–1323`; `bridge/sim_bridge.gd:185, 345–357, 558–566, 785–790`). The 2 s bound is confirmed (a 2 ms poll of a non-blocking pipe, then `step_timeout`). The absence of a non-blocking readiness API is verified, and O3 now says what it would add. |
| oc-glm-5-3 | R1's gate failed open: only the first runner process was checked, a `?` GPU sample read as 0, and an empty sampler file passed. | `gate.sh` uses the reviewer's awk verbatim (the sampler's columns match it: `$2` GPU %, `$4` the runner CPU list). The revised sampler writes `?` and `BAD ioreg-miss` when the ioreg regex misses, and `-` when no runner exists. Drilled in D1: p2.gpu → exit 1 (contended), empty → exit 1, a `?` sample → exit 1, a busy second runner → exit 1, a clean control → exit 0. |
| oc-glm-5-3 | R5's paths, JSON keys and log prefixes were not quoted from the instrument. | Quoted in P1 (`Makefile:13, 732`; `tools/m4_ship_bench.gd:66, 121, 127, 132, 138`; `demos/ship_demo_benchmark.gd:21`). They matched; R5 keeps them and now also gates the sampler file. |
| gemini-4-argon | `counted2.sh` hard-coded the clone's absolute path. | The revised `counted.sh` and `counted2.sh` start with `cd "$(git rev-parse --show-toplevel)"` and use `.godot/tmp/7av/{bin,runs}` (D2). The as-run copies keep their original lines, verbatim, as the record of what ran. |

## Appendix A: the transit probe (`.godot/tmp/7av/probe/probe_transit.gd`, sha256 `
75eb8bd224d602491443472ea092f205f157b2165001aa815bf70f1e718f6bdd`)

A copy of `tools/m4_ship_bench.gd`'s `_run` setup (window and content scale, vsync off, `max_fps` 0, the demo's `setup_options`, the pose, 120 + 300 docked frames, the commit, 30 frames, the dolly wait, the pose, auto tick on, 120 frames, then 30 s of transit), instrumented per frame. `dt` is the bench's sample: the wall interval between `process_frame` emissions, with the first transit frame measured from the start of T as in the bench. This is the final version (V5, V7); V1 and V3 ran it without two output-only additions (Verification Log). It is byte-identical to the bundle's `probe/probe_transit.gd`. Its default `--out` is a `/tmp` path; every command here passes `--out`.

```gdscript file=.godot/tmp/7av/probe/probe_transit.gd
extends SceneTree
## iter105 row 7av probe (scratch, untracked). A copy of tools/m4_ship_bench.gd's setup (window, content
## scale, vsync off, max_fps 0, setup_options, pose, 120 + 300 docked frames, commit, 30 frames, dolly,
## pose, auto tick, 120 frames, 30 s live transit) with per-frame instrumentation of the transit (T):
##   dt     wall interval between process_frame emissions (the bench's sample)
##   proc   game time: process_frame -> frame_pre_draw (nodes' _process, deferred calls, sim ticks)
##   draw   frame_pre_draw -> frame_post_draw (RenderingServer.draw)
##   other  frame_post_draw -> next process_frame, split at the first physics_frame:
##          ev = post_draw -> physics_frame (OS events, input), phys = physics_frame -> process_frame
##   sends/send_ms  SimBridge.send_count / send_ms_total deltas (sim write + blocking drain)
##   ticks  world.tick delta (replies applied); stepped = stepped-signal count
##   canvas per-frame CanvasItem draw signals; items = their indices (paths printed at the end)
##   mem/obj/res/vmem/tex/buf  Performance static-memory, object, resource, video/texture/buffer deltas
##   pc     pipeline compilations this frame (Performance PIPELINE_COMPILATIONS_* if present)
## Args: --tier=medium --out=PATH [--ablate-map] (hide every top-level CanvasItem in the hidden
##       navigation window during T, so its map/overlay/details stop redrawing)
const SIZE := Vector2i(2560, 1440)
const DECK := [30.0, 0.47]
var demo: Node
var out_path := "/tmp/stap_i105/runs/transit.json"
var ablate_map := false
var pre_us := 0
var post_us := 0
var phys_us := 0
var draw_us := 0
var item_ids := {}
var item_paths := []
var frame_items := []
var draw_total := 0
var draw_prev := 0
var stepped_n := 0
var rows := []
var prev := 0
var mon := {}
var pc_ids := []
var last_mon := {}


func _initialize() -> void:
	_run.call_deferred()


func _on_pre() -> void:
	pre_us = Time.get_ticks_usec()


func _on_post() -> void:
	post_us = Time.get_ticks_usec()
	draw_us = post_us - pre_us
	phys_us = 0


func _on_phys() -> void:
	if phys_us == 0:
		phys_us = Time.get_ticks_usec()


func _count_draw(path: String) -> void:
	var id: int = item_ids.get(path, -1)
	if id < 0:
		id = item_paths.size(); item_ids[path] = id; item_paths.append(path)
	frame_items.append(id)
	draw_total += 1


func _monitors() -> Dictionary:
	var m := {"mem": Performance.get_monitor(Performance.MEMORY_STATIC), "obj": Performance.get_monitor(Performance.OBJECT_COUNT),
		"res": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), "vmem": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"tex": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED), "buf": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)}
	var pc := 0.0
	for id in pc_ids: pc += Performance.get_monitor(id)
	m["pc"] = pc
	return m


func _frame(ph: String) -> void:
	await process_frame
	var now := Time.get_ticks_usec()
	var m := _monitors()
	var sim = demo.journey_sim
	var r := {"ph": ph, "dt": (now - prev) / 1000.0, "proc": (pre_us - prev) / 1000.0, "draw": draw_us / 1000.0,
		"ev": ((phys_us if phys_us > 0 else now) - post_us) / 1000.0, "phys": ((now - phys_us) if phys_us > 0 else 0) / 1000.0,
		"calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"objs": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"canvas": draw_total - draw_prev, "items": frame_items.duplicate(), "stepped": stepped_n}
	for k in m: r[k] = m[k] - float(last_mon.get(k, m[k]))
	last_mon = m
	if sim != null:
		r["sends"] = sim.send_count; r["send_ms"] = sim.send_ms_total; r["tick"] = int(sim.world.get("tick", 0))
		r["phase"] = str(sim.world.get("ship", {}).get("phase", ""))
		r["line"] = sim.last_line.length(); r["keys"] = ",".join(sim.state.get("changes", {}).keys()) if sim.state.get("changes") is Dictionary else ""
	frame_items.clear()
	stepped_n = 0
	draw_prev = draw_total
	rows.append(r)
	prev = now


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out_path = arg.trim_prefix("--out=")
		if arg == "--ablate-map": ablate_map = true
	for name in ["PIPELINE_COMPILATIONS_CANVAS", "PIPELINE_COMPILATIONS_MESH", "PIPELINE_COMPILATIONS_SURFACE", "PIPELINE_COMPILATIONS_DRAW", "PIPELINE_COMPILATIONS_SPECIALIZATION"]:
		if ClassDB.class_has_integer_constant("Performance", name): pc_ids.append(ClassDB.class_get_integer_constant("Performance", name))
	print("probe: pipeline-compilation monitors available: %d" % pc_ids.size())
	root.size = SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = SIZE
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var tier := "medium"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tier="): tier = arg.trim_prefix("--tier=")
	RenderingServer.frame_pre_draw.connect(_on_pre)
	RenderingServer.frame_post_draw.connect(_on_post)
	physics_frame.connect(_on_phys)
	await process_frame
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": SIZE, "sky_state": "rest", "seed": 424242, "ai": false, "tier": tier}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	if not demo.ready_ok:
		print("probe: FAIL demo not ready"); quit(1); return
	print("probe: stars %d tier %s driver %s" % [demo.sky.starfield.count, Starfield.last_loaded.get("tier"), RenderingServer.get_current_rendering_driver_name()])
	_pose()
	prev = Time.get_ticks_usec()
	for i in 120: await _frame("W")
	for i in 300: await _frame("C")
	if not await _commit():
		print("probe: FAIL departure"); _finish(); return
	demo.journey_sim.stepped.connect(func(_e): stepped_n += 1)
	for i in 30: await _frame("commit")
	var deadline := Time.get_ticks_msec() + 30000
	while demo.consoles.dolly_active() and Time.get_ticks_msec() < deadline:
		await _frame("dolly")
	_pose()
	demo.journey_auto_tick = true
	for i in 120: await _frame("S")
	_hook()
	if ablate_map:
		var hid := 0
		for ci: CanvasItem in demo.navigation_window.find_children("*", "CanvasItem", true, false):
			var p := ci.get_parent()
			if not (p is CanvasItem) and ci.visible:
				ci.visible = false; hid += 1
		print("probe: ABLATION hid %d top-level CanvasItems under the hidden navigation window" % hid)
	print("probe: T start unix %.3f" % Time.get_unix_time_from_system())
	print("probe: T start: navigation_window visible %s, committed %s" % [demo.navigation_window.visible, demo.journey_sim.world.journey.state])
	frame_items.clear(); draw_prev = draw_total; stepped_n = 0
	var started := Time.get_ticks_usec()
	prev = started
	while (Time.get_ticks_usec() - started) / 1e6 < 30.0:
		await _frame("T")
	demo.journey_auto_tick = false
	_finish()


func _finish() -> void:
	if demo != null and demo.journey_sim != null:
		demo.journey_sim.stop()
	_summary("C")
	_analyse()
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"rows": rows, "items": item_paths}))
	f.close()
	print("probe: wrote %d rows to %s" % [rows.size(), out_path])
	print("probe: DONE")
	quit(0)


func _pct(sorted: Array, q: float) -> float:
	return sorted[ceili(sorted.size() * q) - 1]


func _summary(ph: String) -> Array:
	var sel := rows.filter(func(r): return r.ph == ph)
	if sel.is_empty(): return sel
	var dts := sel.map(func(r): return r.dt); dts.sort()
	print("probe: phase %s n %d p50 %.2f p95 %.2f p99 %.3f max %.2f over16.7 %d" % [ph, dts.size(), _pct(dts, .5), _pct(dts, .95), _pct(dts, .99), dts[-1], dts.filter(func(v): return v > 16.7).size()])
	for col in ["proc", "draw", "ev", "phys", "canvas", "calls"]:
		var vs := sel.map(func(r): return float(r[col])); vs.sort()
		print("probe: phase %s %s p50 %.2f p99 %.2f max %.2f" % [ph, col, _pct(vs, .5), _pct(vs, .99), vs[-1]])
	return sel


func _analyse() -> void:
	var sel := _summary("T")
	if sel.is_empty(): return
	# Per-frame sim deltas.
	for j in sel.size():
		var r: Dictionary = sel[j]
		var p: Dictionary = sel[j - 1] if j > 0 else r
		r["dsend"] = int(r.sends) - int(p.sends); r["dsend_ms"] = float(r.send_ms) - float(p.send_ms); r["dtick"] = int(r.tick) - int(p.tick)
	var slow := sel.filter(func(r): return r.dt > 16.7)
	var fast := sel.filter(func(r): return r.dt <= 16.7)
	for pair in [["slow", slow], ["fast", fast]]:
		var s: Array = pair[1]
		if s.is_empty(): continue
		var acc := {}
		for col in ["dt", "proc", "draw", "ev", "phys", "dsend_ms", "canvas", "mem", "obj", "pc", "vmem"]:
			var t := 0.0
			for r in s: t += float(r[col])
			acc[col] = t / s.size()
		var tick_share := s.filter(func(r): return r.dtick > 0).size()
		var canvas_share := s.filter(func(r): return r.canvas > 0).size()
		print("probe: T %s n %d means %s; frames with a tick applied %d, with canvas draws %d" % [pair[0], s.size(), JSON.stringify(acc), tick_share, canvas_share])
	# Classify each slow frame by its largest component.
	var cls := {}
	for r in slow:
		var parts := {"draw": float(r.draw), "game": float(r.proc), "events": float(r.ev), "physics": float(r.phys)}
		var top := "draw"
		for k in parts: if parts[k] > parts[top]: top = k
		var c: String = top
		if top == "game" and float(r.dsend_ms) > 0.5 * float(r.proc): c = "game:sim-wait"
		elif top == "game" and r.dtick > 0: c = "game:tick-frame"
		if float(r.pc) > 0: c += "+pipeline"
		cls[c] = int(cls.get(c, 0)) + 1
	print("probe: T slow-frame classes %s" % JSON.stringify(cls))
	var idx := sel.map(func(r): return r)
	for j in sel.size():
		var r: Dictionary = sel[j]
		if r.dt <= 16.7: continue
		var names := {}
		for id in r.items: names[item_paths[id].get_file()] = 1
		print("probe:   slow k=%d dt %.2f game %.2f draw %.2f ev %.2f phys %.2f sends %d send_ms %.2f ticks %d canvas %d mem %+d obj %+d pc %d prevdt %.2f nextdt %.2f items %s" % [
			j, r.dt, r.proc, r.draw, r.ev, r.phys, r.dsend, r.dsend_ms, r.dtick, r.canvas, int(r.mem), int(r.obj), int(r.pc),
			sel[j - 1].dt if j > 0 else -1.0, sel[j + 1].dt if j + 1 < sel.size() else -1.0, names.keys()])
	# Draw-signal inventory over T.
	var counts := {}
	for r in sel:
		for id in r.items: counts[id] = int(counts.get(id, 0)) + 1
	var ks := counts.keys(); ks.sort_custom(func(a, b): return counts[a] > counts[b])
	var tot := 0
	for k in ks: tot += counts[k]
	print("probe: T %d draw signals from %d CanvasItems" % [tot, ks.size()])
	for k in ks.slice(0, 40): print("probe:   draw %5d  %s" % [counts[k], item_paths[k]])


func _pose() -> void:
	demo.camera.follow(demo.avatar_pos, DECK[0], DECK[1], 0.0)
	demo._sync_observer()


func _commit() -> bool:
	if not demo.consoles.walk_to("navigation"): return false
	var deadline := Time.get_ticks_msec() + 30000
	while not demo.consoles.walking.is_empty() and Time.get_ticks_msec() < deadline:
		await _frame("walk")
	for action in [["open", null], ["select", "CNS5:3627"], ["commit", null]]:
		if not demo.consoles.use("navigation", action[0], action[1]): return false
	var ok: bool = demo.journey_tick()
	return ok and demo.live_journey and demo.journey_sim.world.journey.state == "committed"


func _hook() -> void:
	var items := root.find_children("*", "CanvasItem", true, false)
	var added := 0
	for ci: CanvasItem in items:
		if ci.has_meta("i105_hooked"): continue
		ci.set_meta("i105_hooked", true)
		ci.draw.connect(_count_draw.bind(str(root.get_path_to(ci))))
		added += 1
	print("probe: hooked %d new CanvasItems (%d in tree)" % [added, items.size()])
```

## Appendix B: the wrappers, the predicate, the sampler and the gate

### B.1 As run (verbatim; not extracted; in the bundle under `bin/`)

**`counted.sh` as run** (sha256 `f388a62b8929914b6a3b6df18bec916ac4805b3d712b417fa7caaae40a768595`):

```zsh
#!/bin/zsh
# counted.sh LABEL WAIT_S -- CMD...  : wait (bounded) for quiet2 YES, run CMD under alarm 600, sleep 3, quiet2 again.
label=$1; waits=$2; shift 3
d=/tmp/stap_i105/runs; rec=$d/$label.rec; log=$d/$label.log
rm -f $rec $log
cd /Users/voightkampff/dev/sunholo-data/stapledons-godot-iter105
deadline=$(( $(date +%s) + waits ))
while true; do
  q=$(/tmp/stap_i105/bin/quiet2.sh); rc=$?
  echo "$q" | head -1 >> $rec
  [ $rc = 0 ] && break
  if [ $(date +%s) -ge $deadline ]; then echo "UNMEASURED: wait expired $(date '+%H:%M:%S')" >> $rec; echo "END" >> $rec; exit 3; fi
  sleep 15
done
echo "PRE YES $(date '+%H:%M:%S')" >> $rec
echo "CMD $*" >> $rec
PATH=$PWD/runtime/bin:$PATH AILANG=runtime/bin/ailang AILANG_BIN=$PWD/runtime/bin/ailang perl -e 'alarm 600; exec @ARGV' "$@" > $log 2>&1
echo "RC $?" >> $rec
sleep 3
q=$(/tmp/stap_i105/bin/quiet2.sh); rc=$?
echo "POST $(echo "$q" | head -1) => $([ $rc = 0 ] && echo YES || echo NO)" >> $rec
echo "END" >> $rec
```

**`counted2.sh` as run** (sha256 `cdffc9a744146e03c95366ca1571bc769ea7821cf54e5745f747048b3331ba21`):

```zsh
#!/bin/zsh
# counted.sh LABEL WAIT_S -- CMD...  : wait (bounded) for quiet2 YES, run CMD under alarm 600, sleep 3, quiet2 again.
label=$1; waits=$2; shift 3
d=/tmp/stap_i105/runs; rec=$d/$label.rec; log=$d/$label.log
rm -f $rec $log
cd /Users/voightkampff/dev/sunholo-data/stapledons-godot-iter105
deadline=$(( $(date +%s) + waits ))
while true; do
  q=$(/tmp/stap_i105/bin/quiet2.sh); rc=$?
  echo "$q" | head -1 >> $rec
  [ $rc = 0 ] && break
  if [ $(date +%s) -ge $deadline ]; then echo "UNMEASURED: wait expired $(date '+%H:%M:%S')" >> $rec; echo "END" >> $rec; exit 3; fi
  sleep 15
done
echo "PRE YES $(date '+%H:%M:%S')" >> $rec
echo "CMD $*" >> $rec
perl /tmp/stap_i105/bin/gpusampler.pl > $d/$label.gpu & smp=$!
PATH=$PWD/runtime/bin:$PATH AILANG=runtime/bin/ailang AILANG_BIN=$PWD/runtime/bin/ailang perl -e 'alarm 600; exec @ARGV' "$@" > $log 2>&1
rc=$?; kill $smp; echo "RC $rc" >> $rec
sleep 3
q=$(/tmp/stap_i105/bin/quiet2.sh); rc=$?
echo "POST $(echo "$q" | head -1) => $([ $rc = 0 ] && echo YES || echo NO)" >> $rec
echo "END" >> $rec
```

**`gpusampler.pl` as run** (sha256 `5c048473fe193b2d261f9572034aad5cf7a74abbb69ea28e6a4d545375b15079`):

```perl
use Time::HiRes qw(time sleep); $| = 1;
while (1) {
  my $g = `ioreg -r -d 1 -c IOAccelerator`; my ($u) = $g =~ /"Device Utilization %"=(\d+)/;
  my @c = map { (split ' ', $_)[0] } grep { /ollama runner|llama-server/ } `ps -axo pcpu,args`;
  printf "%.3f %s ollama_cpu %s\n", time, $u // '?', join(',', @c);
  sleep 0.5;
}
```

### B.2 For R0–R5 (extracted by R0)

The revised wrappers differ from B.1 only in: `cd "$(git rev-parse --show-toplevel)"` instead of a hard-coded clone path; `.godot/tmp/7av/{bin,runs}` instead of `/tmp/stap_i105/{bin,runs}`; the sampler output named `LABEL.gpu` and removed before each run. The revised sampler adds the `?` / `BAD ioreg-miss` line and `-` for no runner. `quiet2.sh` is verbatim from the 7m-d doc, lines 79–98, and identical to the as-run copy except for its last two lines: the as-run file (bundle `bin/quiet2.sh`, sha256 `e95226d0648437c24f839f5ad0b895a769565ee1e46ff4913ef413bcb93b3df1`) ends with a stray fence-marker line copied out of the 7m-d doc's code block, and a blank line, after the final `exit`. They are unreachable, and they were dropped here so the script can sit inside a fence.

**`quiet2.sh`** (sha256 `5e6fce6b57d6e299658be37b5c796ebf24bdadaf473db1d3fffbf36f6685c518`):

```zsh file=.godot/tmp/7av/bin/quiet2.sh
#!/bin/zsh
# quiet2.sh: prints one line of readings; exit 0 only if every reading is present and passes.
g=()
for i in 1 2 3; do g+=$(ioreg -r -d 1 -c IOAccelerator | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2); sleep 1; done
l=$(sysctl -n vm.loadavg | awk '{print $2}')
h=$(ioreg -c IOHIDSystem | grep -o '"HIDIdleTime" = [0-9]*' | head -1 | awk '{printf "%d", $3/1e9}')
rs=$(ps -axo comm | grep -ciE 'screensharingd|ScreenSharingSubscriber|ARDAgent')
ctl=$(ps -axo comm | grep -cx /sbin/launchd)
vnc=$(netstat -an -p tcp | grep -cE '\.5900 .*ESTABLISHED')
echo "quiet: $(date '+%H:%M:%S') GPU ${g[1]:-?}/${g[2]:-?}/${g[3]:-?} load1 ${l:-?} HIDidle ${h:-?}s remote-procs ${rs} (launchd control ${ctl}) vnc-established ${vnc}"
ok=1
[ ${#g} -eq 3 ] || ok=0                                   # three GPU readings present
for x in $g; do [[ "$x" == <-> ]] && [ "$x" -lt 15 ] || ok=0; done
[ -n "$l" ] && awk -v l="$l" 'BEGIN{exit !(l<5)}' || ok=0
[[ "$h" == <-> ]] && [ "$h" -gt 600 ] || ok=0
[ "$ctl" = 1 ] || ok=0   # positive control: the ps|grep pipeline sees launchd
[ "$rs" = 0 ] || ok=0    # no Screen Sharing / Remote Desktop agent
[ "$vnc" = 0 ] || ok=0   # no ESTABLISHED VNC; 5900 in LISTEN alone is launchd socket activation, not a session
if [ $ok = 1 ]; then echo "quiet: YES"; exit 0; else echo "quiet: NO"; exit 1; fi
```

**`counted.sh`** (sha256 `2b22eece1166f700bde2f2a1dc2d6d22bc75111e5287bdfb7fd211d8e42b4b22`):

```zsh file=.godot/tmp/7av/bin/counted.sh
#!/bin/zsh
# counted.sh LABEL WAIT_S -- CMD... (7av, revised; V1's wrapper without the sampler): from the repo root, wait (bounded)
# for quiet2.sh YES, run CMD under alarm 600, sleep 3, quiet2.sh again. Files: .godot/tmp/7av/runs/LABEL.{rec,log}
label=$1; waits=$2; shift 3
cd "$(git rev-parse --show-toplevel)" || exit 2
b=.godot/tmp/7av/bin; d=.godot/tmp/7av/runs; mkdir -p $d
rec=$d/$label.rec; log=$d/$label.log
rm -f $rec $log
deadline=$(( $(date +%s) + waits ))
while true; do
  q=$($b/quiet2.sh); rc=$?
  echo "$q" | head -1 >> $rec
  [ $rc = 0 ] && break
  if [ $(date +%s) -ge $deadline ]; then echo "UNMEASURED: wait expired $(date '+%H:%M:%S')" >> $rec; echo "END" >> $rec; exit 3; fi
  sleep 15
done
echo "PRE YES $(date '+%H:%M:%S')" >> $rec
echo "CMD $*" >> $rec
PATH=$PWD/runtime/bin:$PATH AILANG=runtime/bin/ailang AILANG_BIN=$PWD/runtime/bin/ailang perl -e 'alarm 600; exec @ARGV' "$@" > $log 2>&1
echo "RC $?" >> $rec
sleep 3
q=$($b/quiet2.sh); rc=$?
echo "POST $(echo "$q" | head -1) => $([ $rc = 0 ] && echo YES || echo NO)" >> $rec
echo "END" >> $rec
```

**`counted2.sh`** (sha256 `c7c76f67d577ccc08a1bed78aabc60236505ff74feeaff2ae32097cfa6c7fb5f`):

```zsh file=.godot/tmp/7av/bin/counted2.sh
#!/bin/zsh
# counted2.sh LABEL WAIT_S -- CMD... (7av, revised): from the repo root, wait (bounded by WAIT_S) for quiet2.sh YES,
# run CMD under alarm 600 with the in-run sampler writing LABEL.gpu, sleep 3, quiet2.sh again. Files: .godot/tmp/7av/runs/LABEL.{rec,log,gpu}
label=$1; waits=$2; shift 3
cd "$(git rev-parse --show-toplevel)" || exit 2
b=.godot/tmp/7av/bin; d=.godot/tmp/7av/runs; mkdir -p $d
rec=$d/$label.rec; log=$d/$label.log; gpu=$d/$label.gpu
rm -f $rec $log $gpu
deadline=$(( $(date +%s) + waits ))
while true; do
  q=$($b/quiet2.sh); rc=$?
  echo "$q" | head -1 >> $rec
  [ $rc = 0 ] && break
  if [ $(date +%s) -ge $deadline ]; then echo "UNMEASURED: wait expired $(date '+%H:%M:%S')" >> $rec; echo "END" >> $rec; exit 3; fi
  sleep 15
done
echo "PRE YES $(date '+%H:%M:%S')" >> $rec
echo "CMD $*" >> $rec
perl $b/gpusampler.pl > $gpu & smp=$!
PATH=$PWD/runtime/bin:$PATH AILANG=runtime/bin/ailang AILANG_BIN=$PWD/runtime/bin/ailang perl -e 'alarm 600; exec @ARGV' "$@" > $log 2>&1
rc=$?; kill $smp; echo "RC $rc" >> $rec
sleep 3
q=$($b/quiet2.sh); rc=$?
echo "POST $(echo "$q" | head -1) => $([ $rc = 0 ] && echo YES || echo NO)" >> $rec
echo "END" >> $rec
```

**`gate.sh`** (sha256 `ceafaa2cbd835e14687aceb9b61fbb8355bcab05d880b7fd5d6471874e99c125`):

```zsh file=.godot/tmp/7av/bin/gate.sh
#!/bin/zsh
# gate.sh FILE.gpu (7av R1): exit 0 only if the in-run sampler file has at least one line and every line shows
# the GPU < 100 %, a readable GPU value (not "?"), and every matched runner process at <= 5 % CPU.
# The awk is the round-1 reviewer's (oc-glm-5-3) verbatim; the sampler columns are $2 GPU %, $4 runner CPU list.
awk '{n=split($4,c,","); m=0; for(i=1;i<=n;i++) if(c[i]+0>m) m=c[i]+0; if(m>5 || $2=="?" || $2+0>=100) bad++} END {exit (bad>0)||(NR==0)}' "$1"
```

**`gpusampler.pl`** (sha256 `21940053253d0afd05ee0325ce987977deff517d2f640ae5446184aef23fe16e`):

```perl file=.godot/tmp/7av/bin/gpusampler.pl
# gpusampler.pl (7av, revised): one line per ~0.6 s: unix time, GPU "Device Utilization %", "ollama_cpu",
# then the CPU % of every `ollama runner` / `llama-server` process (comma-separated; "-" if none).
# If the ioreg regex misses, the GPU column is "?" and the line ends "BAD ioreg-miss", so R1's gate fails closed.
use Time::HiRes qw(time sleep); $| = 1;
while (1) {
  my $g = `ioreg -r -d 1 -c IOAccelerator`; my ($u) = $g =~ /"Device Utilization %"=(\d+)/;
  my @c = map { (split ' ', $_)[0] } grep { /ollama runner|llama-server/ } `ps -axo pcpu,args`;
  my $cpu = @c ? join(',', @c) : '-';
  if (defined $u) { printf "%.3f %s ollama_cpu %s\n", time, $u, $cpu }
  else { printf "%.3f ? ollama_cpu %s BAD ioreg-miss\n", time, $cpu }
  sleep 0.5;
}
```

## Appendix D: the summary script (spike, untracked; sha256 `4135e2b5bf978bf752e22c8c7e12fb667b5e6a3c1a2fee87b583d159cc6f182a`)

The numbers in findings 1–6 were read from the probe JSON with this throwaway script (role: spike; not a pipeline step, not tracked, so `make python-guard` is unaffected). R2–R4 use `jq` instead.

```python file=.godot/tmp/7av/probe/analyse.py
# spike (untracked): summarise a probe_transit.gd JSON. usage: python3 -I analyse.py FILE [FIRST_N]
import json, sys
d = json.load(open(sys.argv[1])); rows = [r for r in d["rows"] if r["ph"] == "T"]; items = d["items"]
if len(sys.argv) > 2: rows = rows[:int(sys.argv[2])]
def pct(v, q):
    v = sorted(v); import math; return v[math.ceil(len(v) * q) - 1]
for j, r in enumerate(rows):
    p = rows[j - 1] if j else r
    r["dtick"] = r["tick"] - p["tick"]; r["dsend_ms"] = r["send_ms"] - p["send_ms"]; r["dsend"] = r["sends"] - p["sends"]
dts = [r["dt"] for r in rows]
slow = [r for r in rows if r["dt"] > 16.7]
print("T n %d p50 %.2f p95 %.2f p99 %.3f max %.2f over %d" % (len(rows), pct(dts, .5), pct(dts, .95), pct(dts, .99), max(dts), len(slow)))
tickf = [r for r in rows if r["dtick"] > 0]; notick = [r for r in rows if r["dtick"] == 0]
for name, s in (("tick frames", tickf), ("no-tick frames", notick)):
    if not s: continue
    print("%s n %d: dt p50 %.2f p99 %.2f; game p50 %.2f p99 %.2f; draw p50 %.2f p99 %.2f; over16.7 %d; send_ms p50 %.2f p99 %.2f" % (name, len(s),
        pct([r["dt"] for r in s], .5), pct([r["dt"] for r in s], .99), pct([r["proc"] for r in s], .5), pct([r["proc"] for r in s], .99),
        pct([r["draw"] for r in s], .5), pct([r["draw"] for r in s], .99), sum(r["dt"] > 16.7 for r in s),
        pct([r["dsend_ms"] for r in s], .5), pct([r["dsend_ms"] for r in s], .99)))
# classify slow frames
cls = {}
for r in slow:
    parts = {"draw": r["draw"], "game": r["proc"], "other": r["ev"] + r["phys"]}
    top = max(parts, key=parts.get)
    if top == "game":
        if r["dsend_ms"] > 0.5 * r["proc"]: top = "game: sim reply wait"
        elif r["dtick"] > 0: top = "game: tick frame (not sim wait)"
        else: top = "game: no tick"
    else:
        top = "draw" + (" (tick frame)" if r["dtick"] > 0 else "") + (" (canvas>0)" if r["canvas"] > 0 else "")
    if r["pc"] > 0: top += " +pipeline compile"
    cls[top] = cls.get(top, 0) + 1
print("slow classes", cls)
print("slow frames with pipeline compiles", sum(r["pc"] > 0 for r in slow), "; all T frames with compiles", sum(r["pc"] > 0 for r in rows))
q = [0] * 5
for j, r in enumerate(rows):
    if r["dt"] > 16.7: q[min(4, 5 * j // len(rows))] += 1
print("slow by fifth", q)
# runs (consecutive or near-consecutive slow frames)
idx = [j for j, r in enumerate(rows) if r["dt"] > 16.7]
clusters = []; 
for j in idx:
    if clusters and j - clusters[-1][-1] <= 3: clusters[-1].append(j)
    else: clusters.append([j])
print("clusters (gap<=3)", len(clusters), "sizes", sorted([len(c) for c in clusters], reverse=True)[:10])
for c in clusters:
    if len(c) >= 3: print("  cluster at k=%d..%d (%d slow) t=%.2fs" % (c[0], c[-1], len(c), sum(r["dt"] for r in rows[:c[0]]) / 1000))
for r in slow[:0]: pass
mem_slow = [r["mem"] for r in slow]; 
print("slow mem delta p50 %.0f; fast mem p50 %.0f" % (pct(mem_slow, .5) if slow else 0, pct([r["mem"] for r in rows if r["dt"] <= 16.7], .5)))
for j in idx[:60]:
    r = rows[j]
    print("  k=%d dt %.2f game %.2f draw %.2f oth %.2f tick %d send_ms %.2f canvas %d calls %d pc %d mem %+d prev %.2f next %.2f" % (j, r["dt"], r["proc"], r["draw"], r["ev"] + r["phys"], r["dtick"], r["dsend_ms"], r["canvas"], r["calls"], r["pc"], r["mem"], rows[j-1]["dt"] if j else -1, rows[j+1]["dt"] if j + 1 < len(rows) else -1))
```
