# Live transit: what the hitch tail that decides AC12 is made of (queue row 7av)

**Status:** Planned (mission iteration 105, designer; **R1, R4, R5 run in iteration 107** under D-169's default, see "Iteration 107 counted runs"; **iteration 108 measured where the cruise comb's sim-reply time goes** under D-170's default A, see "Iteration 108": the crew_core monthly decision-day step on the VM). A measured attribution, **not a fix**; it stops at Open questions. **Iteration 107 (2026-11-20, 20:29–20:44 CET): 3 of 6 runs count** (a1, and the bench runs b2 and b3; p3, b1 and the repeat p4 are evidence only). **The one counted bench run with a valid docked control, b3, misses AC12 and 7m AC1 (both bound 16.7 ms; D-147) and row 7av's 16.2 ms headroom target: control p99 16.563 ms (valid), live transit p99 17.338 ms.** That is one valid-control counted run, not two. b2 passes the post reading and the gate, but under D-147 (Q2 OQ6: count only runs whose docked control is valid) its invalid control (18.143 ms) means it does not count toward 7m AC1, so toward AC1 exactly one run (b3) counts. No counted R1 run (p3 contended from T + 0.65 s; p4 sampler-clean but its post reading was NO). `gate.sh`'s three fail-open edges are fixed and drilled (D3). The iteration-105 text below is unchanged: **both iteration-105 probe runs failed their post reading, so no run there is counted** (D-147 Q1 B). Every number below is evidence, with the condition it was taken under stated. **Release:** r1. **Milestone:** M4.6, gated half (row 7m AC1, M4 AC12, bar clause 4). Item class `[LOOP]`, measurement only; the GPU half is PARKED-ON-LANE again (V2, V4). **Revised once** after design quorum round 1 (see "Quorum verification log"): the apparatus is now in the appendices with sha256s and an extraction command, the raw runs are in the public bucket (Raw artifacts), R1's gate fails closed on malformed lines, drilled in D1, the codebase premises are quoted (P0–P4), and p1's quiet stretch is labelled inferred-quiet.
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

**Measured, in two probe runs (neither counted; both post readings NO): the large majority of slow transit frames fall in intervals when the GPU was saturated (p2's in-run sampler: every sample 99–100 % from 9.3 s; the holder is inferred to be the local Ollama model runner, which the sampler cannot prove), and inside those intervals most of their wall time is in the draw bracket. p1's onset coincides with its cruise switch, so p1 alone does not separate contention from a cruise-phase cost (finding 1). In p1's **inferred-quiet** stretch (the first 18.76 s of transit, the whole boosting phase: V1 carried no sampler, so the absence of contention is inferred from frame-time steadiness; R1's sampler run is the verification), the transit p99 was 15.59 ms with 5 slow frames in 1,840, all in the draw bracket. Inferred, not verified on a counted run: the 23–47-frame tail of iteration 103's bench runs is mostly in-run contention that a pre-run reading and a reading 3 s after exit cannot see. Not supported by any measurement here: a game-side defect large enough to explain the tail on a quiet rig. The quiet cruising phase is UNMEASURED.**

Slow frames (> 16.7 ms) in the two GPU probe runs, by largest component (Appendix A classifier: the larger of the draw bracket and game time; "sim wait" when the SimBridge send/drain time is over half of game time):

| run | slow frames | draw bracket | game: sim reply wait | game: tick frame, not sim wait | events + physics | pipeline compiles in T | in a contended interval |
|---|---:|---:|---:|---:|---:|---:|---:|
| p1 (V1) | 268 | 234 | 32 | 2 | 0 | 0 | 263 (after 18.8 s; onset inferred, V1) |
| p2 (V5) | 513 | 445 | 56 | 12 | 0 | 0 | 513 (GPU sample at 100 % from 9.3 s to the end of T, sampler V5; the GPU-holder is not attributed, see finding 1) |
| **both** | **781** | **679 (86.9 %)** | **88 (11.3 %)** | **14 (1.8 %)** | **0** | **0** | **513 of 513 sampler-verified (p2) plus 263 of 268 inferred-onset (p1)** |

1. **The tail is contention-shaped, not steady-state** [V1, V5]. p1's transit ran at 100-frame means of 9.5–10.5 ms with 0–2 slow frames per 100 for 18.4 s, then stepped to means of 30–39 ms and 77–78 slow frames per 100 until the end; its post reading was GPU 100/100/100. **Caveat (controller, from the evaluator's re-derivation): p1's step falls exactly at its boosting → cruising switch (k = 1,839, 18.76 s), so p1 alone cannot separate contention from a cruise-phase cost.** p2 can: its in-run sampler (Appendix B; times relative to `T start unix 1795150384.338`) reads the GPU at 36–98 % and the runner at 15.9–57.1 % CPU over T's first 6 s, the runner at 96–100 % CPU with the GPU at 24–39 % at 6.1–8.0 s, then from 9.3 s to the end the **GPU at 99–100 % on every sample while the runner's own CPU is only 1.6–11.2 %** (plausibly: GPU-resident inference needs little CPU). p2's slow frames per second are 0–7 over 0–7 s (0 of 105 in each of seconds 6 and 7, i.e. while the runner was at 96–100 % CPU but the GPU was not saturated), 16 of 64 in second 8 as the GPU went from 74 to 100 %, and 18–30 per second from 9 s to the end; p2's cruise switch is at 18.88 s (k = 1,168), about 11 s after its slow regime began. So in p2 the slow regime tracks the **GPU reaching 100 %**, not the runner's CPU and not the phase. The sampler cannot say who holds the GPU at 100 %; The sampler never saw Godot alone at that level: the 7 samples before T with the runner under 5 % CPU read GPU 0–1 %, and every sample before T at 21–97 % has the runner at 9.6–60.1 % CPU, which supports the runner as the holder; that attribution is still inferred. Neither run's pre reading (05:26:56 GPU 0/2/11; 05:52:41 GPU 6/11/10) could have predicted this: both runs started in a quiet gap of under a minute between model calls (V2, V4: 66 readings over two 10-minute waits, all NO; 64 had the GPU busy, and the 2 with an idle GPU failed on a 1-min load of 7.1–7.9).
2. **Inferred-quiet, the transit tail is small and draw-bracket only** [V1, first 1,840 frames; inferred-quiet: V1 carried no sampler, so the absence of contention is inferred from frame-time steadiness; R1's sampler run is the verification]. p50 10.66, p95 13.02, **p99 15.59**, max 19.16 ms, 5 slow frames (draw 14.96–17.82 ms, game 1.29–1.79 ms, no tick, no CanvasItem draw, no pipeline compile, static-memory delta −4.3 to +2.1 KB). That is 7m-d's docked shape (243 of 245 slow frames in the draw bracket) and its empty-window floor (p99 15.86–16.28): inferred presentation pacing, mechanism UNVERIFIED without a Metal trace. One run, 1,840 frames: its p99 rests on about 18 frames.
3. **The sim tick costs about 8.7 ms of game time, and the draw bracket absorbs it** [V1 quiet stretch]. 375 tick frames (filter: `dtick > 0` over the first 1,840 T rows; row 1,840 is the first cruising frame and carries a tick): game p50 8.69 ms (p99 11.13), of which SimBridge send/drain p50 1.13 ms, so about **7.6 ms of per-tick main-thread work besides the sim** (p99 9.84); draw p50 1.22 ms; frame p50 10.02, p99 13.56, **0 over 16.7**. The 1,465 frames without a tick: game 1.60, draw 9.74. Game + draw is about 10 ms either way. On a quiet rig the tick's cost is hidden by pacing; under contention it is not: in p2's first 8.3 s, four tick frames read game 18.9–21.1 ms with sim waits of only 1.1–1.4 ms [V5], i.e. the same per-tick work, inflated about 2.5×. Inferred cause of the inflation: memory-bandwidth or CPU contention from the model runner (V3 shows the sim slows under it with no Godot rendering at all).
4. **The per-tick work includes the hidden navigation window's redraw** [V3, V1]. In transit, 36 CanvasItems emit 7,925 `draw` signals per 30 s (V3, headless; 7m-d V8 counted 7,985). The GalaxyMap overlay `Control`, `EarthBeams`, the MapDetails progress bar and labels each redraw 589–590 times, once per 20 Hz tick, while `navigation_window.visible` is false; `GalaxyMap.tick()` → `refresh()` rebuilds the whole hidden panel's text and bindings each tick (`ui/galaxy_map.gd` `refresh`). The rest are visible bridge HUD items (status strip, transit card, console screens). Tick frames carry 13 draw signals at p50 [V1]. **How much of the 7.6 ms is this redraw is UNMEASURED** (the `--ablate-map` run, V6).
5. **Sim reply waits: small when quiet, large under contention, and one hitch at cruise start** [V1, V3, V5, V7]. Inferred-quiet boosting (V1): 374 tick frames (filter: `dtick > 0` and `phase == "boosting"` over the same 1,840 rows, i.e. finding 3's 375 less the one cruising frame; `dsend > 0` gives the same 375 as `dtick > 0`, controller re-derivation from `p1.json`), wait p50 1.13, p99 1.32, max under 5 ms. Under contention: waits of 13–369 ms (p1 cruising p90 19.2, p99 45.4; headless h1 boosting p99 92.3). Within 4–10 frames of the boosting → cruising switch, all four runs show slow replies as the `crew` section starts arriving: 35–53 ms in three (p1 50.5 ms → a 61.3 ms frame; h1 52.8; h2 35.1, on the first `crew` reply, a 40 KB line) and 16–38 ms in p2, which was fully contended by then. In cruise, 128 of 591 replies carry `crew`; under contention their waits run longer (11 of 128 over 20 ms, against 6 of 463 without; max 369 ms) [V7]. All of these were taken under contention, so **whether the cruise-start wait exceeds the 50 ms pipelining window on a quiet rig is UNMEASURED**. It is a plausible source of the iteration-103 maxima of 55–98 ms (one frame per run), not of the 23–47-frame tail.
6. **Ruled out as tail sources, in these runs:** shader or pipeline compilation (the five `Performance.PIPELINE_COMPILATIONS_*` monitors exist in Godot 4.7; 12 compiles in each run, all before transit, 0 in T in both runs); garbage collection (Godot frees by reference count; the slow frames show no static-memory or object-count signature distinct from fast ones: static-memory delta p50 over all T slow frames +144 B against +2,164 B for fast frames in p1, and +1,112 B against +2,544 B in p2; the 5 slow frames of p1's inferred-quiet stretch read −1,180 B); input/event and physics time (p99 0.13 and 0.09 ms).

**Docked-control validity (the precondition)** [V1, V5]. Probe phase C (the bench's 300 docked frames, same setup): p1 **16.774 ms (invalid, by 0.07)**, 6 over, all draw > game; p2 **15.481 ms (valid)**, 1 over. With iteration 103's 1 of 9, that is **2 of 11 valid**, and both of these were taken just before contention arrived. No bench run was taken here (UNMEASURED, V6).

**Why no confident fix.** On the evidence, a game-side change cannot buy a reliable p99 ≤ 16.2 ms on a rig where the model runner returns mid-run: its contention makes 30–40 ms frames regardless of the game's work (p2: 41–59 slow frames per 2 s). And the one inferred-quiet stretch already reads 15.59 ms without any fix. The candidate fixes below would add margin in the contended regime and against the cruise-start hitch, but their effect is UNMEASURED, so they are options for Mark (OQ2), not a design.

**Confidence.**
- High for p2 that the slow regime tracks the GPU reaching 100 %: the slow-frame rate followed the sampler in-run (0–7 per second over 0–7 s with the GPU at 36–98 %, including 0 of 105 in each of seconds 6–7 while the runner was at 96–100 % CPU; 18–30 per second from 9 s, when every GPU sample read 99–100 % and the runner's CPU 1.6–11.2 %); 513 of 513 is base-rate and is not the evidence. Medium that the GPU-holder is the model runner (before T, GPU readings of 21–97 % occur only with the runner at 9.6–60.1 % CPU, and the 7 readings with the runner under 5 % read GPU 0–1 %; the sampler cannot attribute GPU use directly). This round's wording replaces round 2's (corrected by the evaluator's re-derivation, controller-verified against `p2.gpu`).
- Medium for p1: 263 of 268 slow frames fall after an inferred onset (a step in frame times and a GPU 100/100/100 post reading; no sampler), and its 1,840-frame quiet stretch is inferred-quiet, not verified.
- Medium that iteration 103's tail is the same thing: inferred from the shape (p99 tracked pre-run load there; 4 of 9 post readings failed) and from how short the quiet gaps are now; no counted run with an in-run sampler exists.
- High that shader compiles, GC and event/physics time are not the tail (0 in T; no signature).
- Low on the quiet cruise phase: never measured without contention.

## Iteration 107 counted runs (2026-11-20, 20:29–20:44 CET)

Mission iteration 107, designer, unattended. D-169 is unanswered; its default ("takes R1/R4/R5 whenever `quiet2.sh` holds; O2 and O3 are not built") applied. Clone of main `1468cda4`, AILANG v0.56.1 (`runtime/bin/ailang` first on `PATH`), Godot 4.7.2, apparatus extracted by R0 (all 7 sha256 OK before the runs). Order: GPU runs first (R1 `p3`, R5 `b1`, `b2`, R4 `a1`), then two repeats while `quiet2.sh` still held (`b3`, R5 again; `p4`, R1 again), then the gate fix (D3), then this text. Every run used `counted2.sh` exactly as R1/R4/R5 write it (R5's `b3` and R1's `p4` with a 180 s wait instead of 600); `.godot/tmp/bench-bridge.{log,json}` were copied to `runs/bN.bench.{log,json}` before the next run. Rows V8–V13 and D3 in the Verification Log carry the commands and readings.

**Counting rule applied** (D-147 Q1 B plus R1's in-run gate, as R1/R4/R5 write it): a probe run counts only with `PRE YES`, `RC 0`, post `=> YES`, no `SCRIPT ERROR`, `probe: DONE` and the **fixed** `gate.sh` exit 0; a bench run with `bench-bridge.json` present, post `=> YES` and the fixed gate exit 0. A bench run's `RC 2` is the bench's own MISS verdict (`make bench` exits non-zero on a p99 miss), not a failed run, so it does not stop a bench run counting. This doc does not change the AC rule (D-147, OQ1 are Mark's); the gate is applied here because R1–R5 already write it.

| run | PRE YES (local) | pre reading | post reading (+3 s) | RC | old gate (iter 105) | fixed gate | counts? |
|---|---|---|---|---|---|---|---|
| p3 (R1) | 20:29:18 (1st reading) | GPU 0/0/0, load 4.94 | 20:30:21 GPU **96/96/96**, load 8.12: **NO** | 0 | 1 | 1 | **evidence only**: post NO, and in-run contention (below) |
| b1 (R5) | 20:35:57 (18 NO readings 20:30:37–20:35:39 first) | GPU 0/0/0, load 4.13 | 20:36:51 GPU 0/0/0, load **6.28**: **NO** | 0 | 1 | 1 | **evidence only**: post NO (load), and one sample with the second runner at 12.1 % CPU |
| b2 (R5) | 20:38:39 (5 NO readings first, all GPU 0, load 5.25–5.80) | GPU 0/0/0, load 4.61 | 20:39:32 GPU 0/0/0, load 4.73: YES | 2 (MISS) | 0 | 0 | **counts**; docked control **invalid** (18.143) |
| a1 (R4) | 20:39:46 (1st reading) | GPU 0/0/0, load 4.82 | 20:40:38 GPU 0/0/0, load 4.56: YES | 0 | 0 | 0 | **counts** (`ABLATION hid 7`, `probe: DONE`, 0 `SCRIPT ERROR`) |
| b3 (R5 repeat) | 20:41:46 (1st reading) | GPU 0/0/0, load 3.27 | 20:42:38 GPU 0/0/0, load 3.74: YES | 2 (MISS) | 0 | 0 | **counts**; docked control **valid** (16.563) |
| p4 (R1 repeat) | 20:42:48 (1st reading) | GPU 0/0/0, load 3.63 | 20:43:40 GPU **39**/0/0, load 3.70: **NO** | 0 | 0 | 0 | **evidence only**: post NO on one GPU reading; every in-run sample had both runners at 0.0 % CPU |

**R5, the bench** (`grep -E '^bench-bridge: (docked control|frame ms|live transit)'` and `jq -e '.docked_control.p99_ms <= 16.7 and .timing.p99_ms <= 16.2'` on each run's copied files; boosting/cruising split and sim-wait share from the json's `frame_times_ms`, `phases`, `sim_wait_ms`). R5's jq `false` means over 16.2 (row 7av's headroom); AC12 and 7m AC1 themselves are the 16.7 ms bound, which only b1 (evidence only) meets:

| run | counts? | docked control p99 (valid ≤ 16.7) | live transit p99 | over 16.7 / frames | max | R5 `jq -e` | boosting p99 / cruising p99 | slow frames with sim wait > half the frame |
|---|---|---|---|---|---|---|---|---|
| b1 | evidence only | 15.891 (valid) | 16.669 | 31 / 3,195 | 58.10 | **false** (16.669 > 16.2) | 16.290 / 17.460 | 11 of 31 |
| b2 | counts | **18.143 (invalid)** | 16.811 | 38 / 3,164 | 103.73 | **false** | 16.201 / 26.645 | 14 of 38 |
| b3 | counts | 16.563 (valid) | **17.338** | 50 / 3,086 | 153.13 | **false** | 16.934 / 26.209 | 23 of 50 |

**AC12 / 7m AC1, plainly.** Two bench runs pass the post reading and the gate (b2, b3; b1 does not), but only b3 has a valid docked control, so under D-147 (Q2 OQ6) only b3 counts toward 7m AC1. **b3 MISSED** the 16.7 ms bound that AC12 and 7m AC1 share (D-147: "the unchanged 16.7 ms bound"), and row 7av's 16.2 ms headroom target, with a valid control and a sampler-clean run (in-run: GPU column 0–48 %, which is the bench's own rendering, both runner processes 0.0 % CPU in every sample). **b2 is undecidable** (invalid control, 18.143 ms); its transit p99 16.811 would also miss. The evidence-only b1 read 16.669 (under 16.7, over 16.2). So R5's "two counted runs" condition is met only with the repeat b3, and not by two valid-control runs (b1 has a valid control but is evidence only); the one valid-control counted run is a miss. This is one run's evidence, not a spread. R2's prediction (boosting-phase p99 ≤ 16.2) held in only one run, the evidence-only p4 (16.029); b2 missed it by 0.001 (16.201), and a1 (16.500), b1 (16.290) and b3 (16.934) missed it clearly.

**R1/R2/R3, the probe** (R2's and R3's commands on `p3.json`/`p3.log`, and the same on the repeat `p4`):

| run | counts? | transit p99 | docked phase C p99 (valid?) | T slow-frame classes | pc in T | R3 hidden-map lines | tick frames: game (`proc`) p50 |
|---|---|---|---|---|---|---|---|
| p3 | evidence only | 40.474 (73 over of 2,803) | 17.070 (invalid; `false`) | draw 19, sim-wait 44, tick-frame 10 | 0 | 10 | 9.065 ms (592 frames) |
| p4 | evidence only | 16.632 (31 over of 3,184) | 16.429 (valid; `true`) | draw 20, sim-wait 11 | 0 | 10 | 7.593 ms (600 frames) |

- **p3 was contended from 0.65 s into transit.** `T start unix 1795202984.236`; the first sampler line with a runner over 5 % is T + 0.651 s (`45.2,0.0`), the GPU column reads ≥ 90 % from T + 8.47 s (100), 41 of the 46 in-T samples fail the gate, and the runner reached 476–508 % CPU by the end. `ps` at 20:32:11 showed both `llama-server` processes with elapsed times 2:31 and 2:15, i.e. started about 20:29:40 and 20:29:56, around p3's transit start (inferred: a model load; the sampler cannot name the holder). p3's numbers are contended evidence, like p1/p2.
- **p4 is the first probe run whose sampler was clean throughout** (69 samples, every runner field `0.0,0.0`, GPU column 0–42 %, i.e. the probe's own rendering). It is not counted: the post reading's first GPU sample read 39 (then 0, 0); what held the GPU 3 s after Godot exited is UNMEASURED. Boosting p99 **16.029** (11 over of 2,039), cruising p99 **17.297** (20 over of 1,145).
- **R3:** 10 hidden-map CanvasItems emit `draw` in T in both p3 and p4 (not 4): the overlay `Control@378`, `EarthBeams`, `ProgressBar@414`, `Label@403` and `Label@542` at 591–592 draws each (one per tick), `Label@532/534/536` at 371, and `Label@524/528` at 220 (p3's counts). a1 (ablation) shows 0.
- **pc:** 0 pipeline compiles in T in p3, p4 and a1, as predicted.

**R4, the O2 ablation (a1, counted).** `probe: ABLATION hid 7 top-level CanvasItems under the hidden navigation window`. R4's commands: tick-frame game time median **5.39 ms** (595 tick frames) against p3's **9.065** (592; contended) and the repeat p4's **7.593** (600; sampler-clean, not counted); boosting-only 5.406 against 8.746 (p3), 7.555 (p4) and V1's inferred-quiet 8.69. Tick frames' game time less the SimBridge send/drain: 4.29 (a1) against 7.76 (p3). Transit p99 **16.736** (33 over of 3,213; boosting 16.500, cruising 16.932), against p4's 16.632 and p3's 40.474. Slow-frame classes: draw 11, game 1, sim-wait 19, tick-frame 2. Docked phase C p99 17.166 (6 over, max 43.64: the probe's control was invalid in this run). **Reading, bounded to these runs:** hiding the hidden map cuts tick-frame game time by about 2.2 ms (vs p4) to 3.7 ms (vs p3) at the median, and it did **not** lower the transit p99 (16.736 vs p4's 16.632), because tick frames were not where the slow frames were: in the two sampler-clean probe runs, 2 of 33 (a1) and 0 of 31 (p4) slow frames are tick-frame class. One ablation run and one comparator; the p99 difference is inside run-to-run spread (UNMEASURED with more runs).

**What the sampler-clean runs' tail is made of (a1, p4, b3; new in this iteration, bounded to these runs).**
1. **Periodic `crew` replies in cruise.** In a1, p3 and p4 the frames over 40 ms in cruise fall on the same sim ticks: 406 (the cruise switch, k ≈ +10 frames), 460, 513, 566, 620, every 53–54 ticks (about 2.7 s at 20 Hz), and each of those replies carries the `crew` section (`keys` contains `crew`, lines 38.9–42.6 KB). On the sampler-clean runs the SimBridge wait on those frames was: a1 40.1 (tick 406), 30.7 (460), 37.9 (513), 55.2 (566), 37.3 (620) ms; p4 29.5 (406), 55.4 (460), 55.3 (513), 37.3 (566), 55.4 (620) ms. The bench's own `sim_wait_ms` shows the same comb at 19.1, 21.8, 24.4, 27.1, 29.8 s of transit in b1, b2 and b3 (24–81 ms). Each such reply makes 1–3 slow frames; it is why the cruising p99 (16.932 in a1, 17.297 in p4, 26.2–26.6 in b2 and b3) is above the boosting p99.
2. **OQ3:** the first `crew` reply (tick 406) on a sampler-clean rig waited 40.1 ms (a1) and 29.5 ms (p4), under OQ3's 50 ms; later `crew` replies reached 55.2–55.4 ms (a1 tick 566; p4 ticks 460, 513, 620). Whether that is reported upstream (O4) is Mark's (OQ3); nothing was reported in this iteration.
3. **An unattributed boosting-phase sim-wait cluster.** b3 (8.4–9.1 s of transit, 8 frames 45–153 ms, sim wait 33–124 ms) and a1 (5.3–5.8 s, ticks 130–140, 6 frames of 48–153 ms, sim wait 38–118 ms) each had one burst of slow sim replies in boosting while the sampler read both runners at 0.0 % CPU; p3 had one at 4.0–4.8 s (contended), p4 and b1/b2 had none. Its replies carry no `crew` section and are normal size (33.1–33.3 KB). Cause UNMEASURED (not the model runner per the sampler; candidates are the sim process itself or other host load, which the sampler does not record).
4. **Draw-bracket frames at 16.7–17.8 ms** remain the rest (a1 11, p4 20 of the slow frames, classed by their larger component; in a1 their draw bracket is 14.6–16.7 ms and game time 1.0–2.1 ms), the docked/inferred-quiet shape of finding 2.

So on a quiet rig the transit p99 sits at 16.6–17.3 ms in these four sampler-clean runs (a1, b2, b3 counted; p4 evidence only: a1 16.736, p4 16.632, b2 16.811, b3 17.338), with the sim-wait comb and one-off boosting bursts carrying 35–58 % of the slow frames (probe runs use the probe's sim-wait class: a1 19 of 33, p4 11 of 31; bench runs use sim wait over half the frame: b2 14 of 38, b3 23 of 50). **This revises "Predicted headroom" (one inferred-quiet boosting stretch at 15.59): the quiet cruise phase, now measured, is above 16.2 in every run here.** No option is designed or built here (D-169 default); O3 (do not block on a late reply) is the option these numbers bear on, and that choice is Mark's (OQ2).

**Docked-control validity, this iteration:** bench 2 of 3 valid (b1 15.891, b3 16.563; b2 18.143 invalid); probe phase C 1 of 3 (p4 16.429; p3 17.070, a1 17.166 invalid). With iteration 105's 1 of 2 and iteration 103's 1 of 9: 5 of 17.

**Raw evidence:** bundle `7av-iter107-evidence.tgz` (see "Raw artifacts").

## Iteration 108: where the crew reply's time goes (2026-11-21, 03:36–04:20 CET)

Mission iteration 108, designer, unattended, under D-170's default A (measure; headless, no GPU, no code change). Clone of main `49314f81`, AILANG v0.56.1 (`runtime/bin/ailang`, 05c860a), Godot 4.7.2, apparatus extracted by R0 (the iteration-107 probe, sha256 `75eb8bd2…6bdd`). Every figure carries its instrument in brackets and a V-row (V14–V24). Host: 1-min load 2.8–8.4 across the runs (`uptime` beside each), and `ps` read `ollama` and `llama-server` at 0.0 % CPU at every run's start and end (one earlier reading, 03:38, before any run: `ollama` 17.1 %). No GPU run was taken.

**Instruments.** (1) `[tap clock]`: a transparent stdin/stdout tap (`bin/simtap.pl`) between SimBridge and the real sim, put in place through `AILANG_BIN` (`bridge/sim_bridge.gd:163–166` `find_ailang` reads it). It timestamps each request line as it reaches the sim and the reply's first byte and newline as they leave, and saves both streams. (2) `[godot SimBridge wait]`: the probe's per-frame `dsend_ms` (SimBridge `send_ms_total`, drain wait plus the next send's write) on frames whose tick advanced. (3) `[sim-side clock]`: scratch AILANG drivers (`replay/*.ail`) that replay the recorded request stream through the sim's own pure `serve` (`sim/protocol.ail:996`) and time `serve`, `core.tick` (`sim/core.ail:725`) and `crewViewAt` (`sim/protocol_crew.ail:274`) with `std/clock.now` (1 ms resolution; repeated calls to resolve less). They run in a copy of `sim/` under `/tmp` whose only change is `Clock` added to `ailang.toml`'s effect ceiling (`replay/scratch-tree.diff`). (4) `[go pprof]`: `ailang run --cpuprofile` of those drivers. (5) `[godot parse bench]`: `JSON.parse_string` of recorded reply lines in a headless `--script`.

**Determinism check, the premise of the offline split** [V20]. The real sim (`sim/ship.ail main`, bytecode VM) fed run h4's recorded request stream writes 640 replies whose bytes equal the replies the live game received (sha256 `dd62855c…1d04` for both), so an offline replay times exactly the work of the live run.

**The split of one comb reply** (the five monthly ticks 406, 460, 513, 566, 620; "ordinary" is every other cruise tick, most of which also carry `crew`):

| part | instrument | comb reply | ordinary cruise reply | share of the comb reply's sim-side time |
|---|---|---:|---:|---:|
| request in → reply's first byte out (all sim work: step plus reply encoding) | [tap clock], V14 | **77.6–91.4 ms** (15 readings, 3 runs) | p50 19.3–19.5, p90 21.3–26.8 ms | 100 % (about 80 ms) |
| `core.tick`, the world step including crew_core's auto-run | [sim-side clock], V16, V18 | **62.6–62.7 ms** (mean of the 5, runs 1 and 3; run 2 75.9 with one outlier); 64.1–64.8 ms (tick 460, 50 reps × 3) | 0.95–1.02 ms (mean, 3 runs); 0.32–0.34 ms (tick 459, 50 reps × 3) | about 78 % |
| of which: `social_dynamics` `wire.sortedJson`'s per-comparison encodes | [sim-side clock], ablation, V20 | about **20.5 ms** (64.1–64.8 → 43.6–44.1, byte-identical output) | not measured (small: the ordinary tick is 0.3–1.0 ms in all) | about 26 % |
| of which: the rest of the crew_core / social_dynamics work | [sim-side clock], V20 | about 43.3–43.8 ms (ablated tick less the 0.32–0.34 control) | — | about 54 % |
| protocol diff and reply encoding (`serve` − `tick`) | [sim-side clock], V16 | 17.6–18.1 ms (runs 1, 3) | 17.0–17.4 ms (3 runs) | about 22 % |
| of which: `crewViewAt` of the stepped crew | [sim-side clock], V16 | 0.2–0.3 ms | 0.24–0.27 ms | under 0.5 % |
| pipe transfer, sim → tap | [tap clock], V14 | the whole line in one 1 MB read: first byte to newline 0.000 ms in every reply of 3 runs | same | about 0 |
| Godot `JSON.parse_string` of the line (after arrival, outside the 80 ms) | [godot parse bench], V21 | 0.430–0.440 ms p50 (38.9 KB line) | 0.375–0.419 ms p50 (35.0 KB) | 0.5 % of 80 ms |
| what the frame sees: SimBridge drain wait | [godot SimBridge wait], V14, V15 | **11.0–92.5 ms** (20 readings, 4 runs) | p50 1.11–1.16 ms | = sim time less the time already elapsed since the send |

The interpreter does the same work 6.7× slower on the step (decision-day `tick` 422.7 ms against the VM's 62.7; ordinary tick 11.5 against 0.96; reply encoding 406 ms against 18) [V17]. So the VM is not slower than the interpreter here; the cost is the package's work, run on the VM.

**What makes the 53–54-tick cadence** [V23]. It is crew_core's auto-run decision day under D-76's monthly cadence on a committed leg: `sim/crew_auto.ail:13–17` (cadence "monthly on long skips"; "decision days are absolute (tick % cadence == 1)"), `:34` `cadenceLongSkip() -> int = 30`, `:78–79` `nextDecision`. A sim tick advances the crew 0.5622 crew days in this cruise (crew `turn` +1 every 1–2 ticks; `tau` × 365.25 rises 1.1244 per 2 ticks), so 30 crew days are 53.4 ticks. The comb ticks are exactly crew turns 1, 31, 61, 91 and 121, and on each of them the crew section's `revision` jumps by 35–39 (55 → 94, 98 → 134, 138 → 176, 180 → 215) against 0–4 on other turns. **The cost does not follow the crew section's size**: in run h4, 131 of 235 cruise replies carry `crew`, the ordinary ones are 37.6–42.6 KB (the comb's 38.9–42.6 KB) and they took 17.8–28.4 ms sim-side [tap clock] (one more, tick 410, a turn with +8 revisions, read 61.6 live and 31–32 ms in replay). It follows crew_core's work on the decision day.

**Verdict.** The comb reply's time is VM compute in the sim, and the part that pushes it past the 50 ms tick window is the step, not the reply: the decision-day `core.tick` costs 62.6–64.8 ms against 0.32–1.02 ms on other days [sim-side clock], while the reply's diff-and-encode stays at 17.6–18.1 ms against 17.0–17.4 [sim-side clock]. Shares of the comb reply's ~80 ms: the step about 78 % (of which about 26 points are one function, `social_dynamics` 0.4.0 `wire.ail:77` `sortedJson`, which encodes both sides on every comparison; profile: `hofBuiltinListSortBy` 31.5 % cumulative, nearly all of it the comparator's `builtinJsonEncode` 29.8 % [go pprof]), reply encoding about 22 %, pipe transfer about 0, and Godot's parse 0.43 ms after arrival. The tap does not create the comb: the no-tap run h6 shows it at 35.6–80.3 ms [godot SimBridge wait], and the tap's sim-side readings match the offline replay (77.6–91.4 live, 77–93 ms single-shot in replay).

**What it means for O3 and O4.** The measured cost sits in package code on the VM (`sunholo/social_dynamics` 0.4.0 under `sunholo/crew_core` 0.6.0), and one line of it accounts for about a third of the step with output unchanged, so O4 (report upstream, re-measure on a fixed release) is supported by the evidence for that third. The VM itself showed no defect: it is 6.7× faster than the interpreter on this tick, and a hypothesis about its frame pool (`releaseFrame` clears `Regs[:cap]`, 11.7–14.3 % of samples in every profile) did not reproduce in a standalone test (V24). Even with the `sortedJson` change, the decision day would cost about 44 ms of step plus about 18 ms of encoding, about 62 ms, still over the 50 ms window, so O4 alone is not predicted to remove the comb; the remaining ~44 ms is not decomposed (the Go profile cannot name AILANG functions). O3 (do not block the frame on a late reply) would hide whatever is left regardless of its cause. Which to take is Mark's (OQ2, OQ3). An upstream draft with a standalone repro exists (`upstream-draft.md` in the bundle); it was **not sent** in this iteration.

**Also measured, not part of the comb.** (a) Ordinary replies take 19.3–19.5 ms p50 sim-side, of which 17.0–17.4 ms is the protocol's diff and encode (`tickExtras` encodes several sections before and after each tick, `sim/protocol.ail:984–994`, and compares the strings); pipelining hides it on a 50 ms tick. (b) **Bursts of slow replies off the decision days** — h4 ticks 394–401 (boosting, 62–80 ms), h5 ticks 593–602 (cruise, 43–83 ms) — cost 17–19 ms in the deterministic replay of the same requests [V14, V16], so they are not the sim's computation; their cause (host scheduling or the sim process's runtime, e.g. its garbage collector) is UNMEASURED. This is iteration 107's finding 3 shape (an unattributed burst at a different tick in each run).

**Against iteration 107.** Iteration 107's finding 1 tied the comb to "the reply that carries the `crew` section" (lines 38.9–42.6 KB). The ticks are the same, but carrying `crew` is not the cause: most cruise replies carry it at the same size and cost about 19 ms (above). Iteration 107's Godot-side waits (a1 30.7–55.2, p4 29.5–55.4 ms) agree with this iteration's 11.0–92.5 ms [godot SimBridge wait]: the wait is the ~80 ms sim time less whatever part of it overlapped the frame since the send, so it varies run to run.

**UNMEASURED.** The AILANG-level breakdown of the remaining ~44 ms of the decision-day step; the cause of the off-cadence bursts; the comb on a GPU run under this iteration's tap (headless only here; iteration 107 measured it with the GPU); the effect of the `sortedJson` change on AC12's p99.

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
| D1 | revision, about 06:05 (no GPU window) | n/a | the R1 gate (Appendix B `gate.sh`, the round-1 reviewer's awk verbatim; the sampler's columns are `$2` GPU % and `$4` the runner CPU list, as the awk assumes) on five files | — | — | **p2.gpu (V5's sampler, 79 lines): exit 1, contended.** Empty file (0 lines): **exit 1**. Synthetic file with one `?` sample (3 lines, the revised sampler's `BAD ioreg-miss` form): **exit 1**. Synthetic file whose *second* runner process is at 47 % (1 line): exit 1. Positive control, a clean synthetic file (3 lines; GPU 20–31, runners ≤ 4 %, one `-` for no runner): **exit 0**. **Round-2 re-drill (controller, after replacing `gate.sh` with the round-2 reviewer's structure-validating version, B.2):** the same five give exit 1, 1, 1, 1, 0; plus a file whose final line is truncated mid-write (`1763697000.481 45 ollama_cpu`, no `$4`): **exit 1** (the round-1 gate exited **0** on it, which confirms the defect); a clean file whose every runner field is `-`: exit 0; and no argument (`gate.sh < /dev/null` under `alarm 5`): **exit 1, no hang**. |
| D2 | revision (no GPU window) | n/a | Appendix B's extraction command run on this doc in the clone, then `shasum -a 256 -c`, then `.godot/tmp/7av/bin/counted2.sh drill 0 -- true` | — | — | All 7 extracted files matched their listed sha256 (`shasum -c` rc 0; the first attempt caught that the as-run `quiet2.sh` ends in a stray fence-marker line, see B.2). The extracted probe passes `godot --headless --check-only`, and the sampler passes `perl -c`. The wrapper resolved the repo root, read `quiet2.sh` once (06:06:09, GPU 99/100/100, load 6.81: NO) and wrote `.godot/tmp/7av/runs/drill.rec` ending `UNMEASURED: wait expired` / `END`, exit 3, so its paths work from the clone root. `git status` showed only this doc modified (`.godot/` ignored, P0). |
| R0 (it. 107) | 20:29:05, before the runs | n/a | R0's `shasum -a 256 -c` on the already-extracted apparatus | — | — | 7 of 7 OK (gate.sh still the iteration-105 `5c8fb3d6…`). `quiet2.sh` at 20:29:09: GPU 0/0/0, load 4.76: YES. |
| V8 | PRE YES 20:29:18 (1st reading: GPU 0/0/0, load 4.94, HID idle 42,254 s, session clause clean) | YES | R1 verbatim: `rm -f $s/runs/p3.json; $s/bin/counted2.sh p3 600 -- godot --audio-driver Dummy --path . --script $r/$s/probe/probe_transit.gd -- --tier=medium --out=$r/$s/runs/p3.json`, then R1's check line | **NO**: 20:30:21 GPU 96/96/96, load 8.12 | no: `p3 is evidence only` (old gate 1, fixed gate 1) | RC 0, `probe: DONE`, 0 `SCRIPT ERROR`. R2: T p99 **40.474**, C p99 17.070 → `false`, classes `{"draw":19,"game:sim-wait":44,"game:tick-frame":10}`, pc 0; R3: 10. Sampler 85 lines: runner 45.2 % at T + 0.651 s, GPU ≥ 90 from T + 8.47 s; 41 of 46 in-T samples fail. |
| V9 | waits 20:30:37–20:35:39: 18 NO (20:30:37–20:31:52 GPU 95–96/95–97; 20:32:11–20:35:01 GPU 0/0/0 but load 5.90–14.74; 20:35:20, 20:35:39 GPU 88–89); PRE YES 20:35:57 (GPU 0/0/0, load 4.13) | YES | R5: `rm -f .godot/tmp/bench-bridge.{log,json}; $s/bin/counted2.sh b1 600 -- make bench SCENE=bridge AILANG=runtime/bin/ailang`; files copied to `runs/b1.bench.{log,json}` | **NO**: 20:36:51 GPU 0/0/0, load **6.28** | no (old 1, fixed 1) | RC 0, bench `verdict ok exit 0`. Control p99 15.89 (valid); transit p99 **16.669**, 31 over of 3,195, max 58.10; `jq -e` **false**. Sampler 70 lines: one sample (47th) with the second runner at 12.1 % CPU (GPU 41, the bench's own rendering range). |
| V10 | waits 20:37:05–20:38:21: 5 NO (GPU 0/0/0, load 5.25–5.80); PRE YES 20:38:39 (GPU 0/0/0, load 4.61) | YES | R5 as V9, label `b2` | YES: 20:39:32 GPU 0/0/0, load 4.73 | **yes** (old 0, fixed 0) | RC 2 = bench `verdict MISS exit 2` (p99 16.811 against 16.7). Control p99 **18.14 (invalid)**; transit p99 16.811, 38 over of 3,164, max 103.73; `jq -e` **false**. Sampler 69 lines, runners 0.0 throughout, GPU column 0–42. |
| V11 | PRE YES 20:39:46 (1st reading: GPU 0/0/0, load 4.82) | YES | R4 verbatim: `rm -f $s/runs/a1.json; $s/bin/counted2.sh a1 600 -- godot … probe_transit.gd -- --tier=medium --ablate-map --out=$r/$s/runs/a1.json`, then R4's three commands | YES: 20:40:38 GPU 0/0/0, load 4.56 | **yes**: `a1 counts (fixed gate)` (old 0, fixed 0) | RC 0, `ABLATION hid 7`, `probe: DONE`, 0 `SCRIPT ERROR`. Tick-frame game median **5.39** (p3 9.065, p4 7.593); T p99 **16.736**, 33 over of 3,213; C p99 17.166 (invalid); classes `{"draw":11,"game":1,"game:sim-wait":19,"game:tick-frame":2}`; pc 0; R3: 0. Sampler 69 lines, runners 0.0, GPU 0–50. |
| V12 | PRE YES 20:41:46 (1st reading: GPU 0/0/0, load 3.27) | YES | R5 repeat, label `b3`, wait 180: `$s/bin/counted2.sh b3 180 -- make bench SCENE=bridge AILANG=runtime/bin/ailang` | YES: 20:42:38 GPU 0/0/0, load 3.74 | **yes** (old 0, fixed 0) | RC 2 = bench MISS (p99 17.338). Control p99 **16.56 (valid)**; transit p99 **17.338**, 50 over of 3,086, max 153.13; `jq -e` **false**. **AC12 and 7m AC1 MISS on a counted, valid-control, sampler-clean run.** Sampler 69 lines, runners 0.0, GPU 0–48. |
| V13 | PRE YES 20:42:48 (1st reading: GPU 0/0/0, load 3.63) | YES | R1 repeat, label `p4`, wait 180, otherwise R1 verbatim | **NO**: 20:43:40 GPU **39**/0/0, load 3.70 | no: `p4 is evidence only` (old 0, fixed 0) | RC 0, `probe: DONE`, 0 `SCRIPT ERROR`. T p99 **16.632** (boosting 16.029, cruising 17.297), 31 over of 3,184; C p99 16.429 → `true`; classes `{"draw":20,"game:sim-wait":11}`; pc 0; R3: 10. Sampler 69 lines, runners 0.0 throughout, GPU 0–42. |
| D3 | after the runs, 20:44 | n/a | `gate.sh` fixed (B.2, sha256 `db7c09ce…4976`); R0 re-extracted from this doc and `shasum -a 256 -c` (7 of 7 OK, extracted gate byte-identical to the drilled one); `drill107/drill.sh` (in the bundle) runs the iteration-105 gate (`bin/gate.iter105.sh`) and the fixed gate on each file | — | — | **The three fail-open edges now fail** (old → fixed exit): runner field `.` 0 → **1**; `1..2` 0 → **1**; an extra field after `$4` 0 → **1**; a one-line file from a sampler that died after its first line, against p3's real `.rec` 0 → **1**; p3's clean-looking first 34 lines (sampler died at 40 % of the run) 0 → **1**; a 3 s gap between samples 0 → **1**; a numeric line ending `BAD ioreg-miss` (NF 6) 0 → **1**; a `.gpu` with no `.rec` 0 → **1**. **D1's drills keep their verdicts** (old, fixed): p2.gpu 1, 1; empty 1, 1; `?` sample 1, 1; busy second runner 1, 1; clean synthetic 0, 0 (given a matching `.rec`); truncated final line 1, 1; all-`-` 0, 0; no argument 1, 1 (no hang under `alarm 5`). **Real clean sampler files exit 0:** a1, b2, b3, p4 (0, 0 each). Re-applied to this fire: p3 1, 1; b1 1, 1; b2 0, 0; a1 0, 0; b3 0, 0; p4 0, 0; with values zeroed (coverage alone), all six exit 0, so p3's and b1's failures are contention, not coverage. |
| V14 (it. 108) | 03:38, 03:39, 04:04; load 7.23 / 6.54 / 3.22; `ollama`, `llama-server` 0.0 % (`bin/host.sh` before and after) | n/a (headless) | `AILANG_BIN=/tmp/stap108/bin/simtap.sh SIMTAP_REAL=$PWD/runtime/bin/ailang SIMTAP_LOG=/tmp/stap108/runs/hN.tap perl -e 'alarm 300; exec @ARGV' godot --headless --audio-driver Dummy --path . --script $PWD/.godot/tmp/7av/probe/probe_transit.gd -- --tier=medium --out=/tmp/stap108/runs/hN.json` for N = 3, 4, 5; reply n is tick n − 2; `bin/gwait.sh hN.json` for the Godot side | — | no (headless evidence) | rc 0, 45–46 s each. **[tap clock] request → first reply byte on ticks 406, 460, 513, 566, 620:** h3 78.8, 83.0, 82.0, 88.0, 82.5; h4 91.4, 87.9, 80.2, 81.8, 77.6; h5 80.5, 81.6, 80.1, 84.4, 90.4 ms. Other cruise replies p50 19.3 / 19.3 / 19.5, p90 21.3 / 21.5 / 26.8. First byte → newline 0.000 ms for every reply (one read). **[godot SimBridge wait] on the same ticks:** h3 44.8, 60.4, 17.7, 55.4, 24.5; h4 92.5, 35.1, 37.3, 46.1, 36.7; h5 57.2, 11.0, 55.3, 50.4, 43.6 ms; other cruise ticks p50 1.14–1.16. Off-cadence bursts [tap clock]: h4 ticks 394–401 62–80 ms, h5 593–602 43–83 ms, h3 none. |
| V15 (it. 108) | 04:04, load 5.82 | n/a | as V14 without the tap (`AILANG_BIN=$PWD/runtime/bin/ailang`), label h6 | — | no | rc 0, 45 s. [godot SimBridge wait] on the five ticks: 35.6, 55.2, 39.6, 45.7, 80.3 ms; other cruise ticks p50 1.11. The comb is present without the tap (control for V14). |
| V16 (it. 108) | 03:43–03:45, load 8.15 / 8.44 / 7.27 | n/a | in `/tmp/stap108/simcopy` (a copy of `sim/`, `Clock` added to the effect ceiling, `replay/scratch-tree.diff`): `ailang run --quiet --bytecode --package-dir . --caps IO,FS,Clock --entry main --args-json '{"path":"/tmp/stap108/runs/h4.req.ndjson","reps":3,"from":380}' tools/stap108_replay.ail` ×3 → `runs/vm{1,2,3}.txt` | — | — | [sim-side clock], per comb tick (`serve` single-shot; `serve`, `tick`, `crewViewAt` each 3 reps): single-shot 77–93 ms; means over the 5: serve 80.3 / 106.3 / 80.7, tick 62.7 / 75.9 / 62.6 (run 2: tick 620 read 628 ms for 3 serves, an outlier). Other cruise ticks (230): serve 17.96 / 18.43 / 18.13, tick 0.96 / 1.02 / 0.95, crewViewAt 0.24 / 0.27 / 0.27 ms. Ticks 394–405 (V14's h4 burst): serve 16–21 ms. |
| V17 (it. 108) | 03:45–03:55, load 5.51 at start | n/a | as V16 without `--bytecode` (the interpreter), once → `runs/interp1.txt` (609 s; the `perl alarm 500` did not stop it, so the cap did not hold; it ended on its own) | — | — | Comb means: serve 821.5, tick 422.7 ms; other cruise ticks: serve 406.4, tick 11.50, crewViewAt 2.15 ms. Interpreter / VM on the comb tick: 6.7×. |
| V18 (it. 108) | 03:56 and 03:59–04:00, load 2.9–3.9 | n/a | `… --args-json '{"path":"/tmp/stap108/runs/h4.req.ndjson","at":462,"reps":50}' tools/stap108_decision.ail` ×3 (replays to line 461, then times `core.tick` of tick 459 and of tick 460 50 times each); `tools/stap108_encbench.ail` at 462, 200 reps ×3 | — | — | [sim-side clock] decision tick 460: 3,241 / 3,221 / 3,205 ms per 50 = **64.1–64.8 ms**; control tick 459: 16 / 17 / 17 ms per 50 = 0.32–0.34 ms. `encodeConfig` of the live config (6,849 B): 89 / 94 / 95 ms per 200 = 0.44–0.48 ms; `encodeState` (39,737 B): 2.05–2.07 ms (the game's crew is untraced, `sim/crew.ail:80–88`, so `encodeState` is not on its path). |
| V19 (it. 108) | 03:56–04:03 | n/a | `--cpuprofile` on V18's driver: reps 200 and 600 at line 462 (`runs/decision.pprof`, `decision600.pprof`), reps 1 (`prefix.pprof`, the replay alone), and V20's ablated tree at reps 300 (`decision_abl300.pprof`); `go tool pprof -top -cum` and `-peek` (outputs `*.top`, `*.cum`, `*.peek`) | — | — | [go pprof] decision600 (49.7 s, 39.2 s of it decision ticks): `hofBuiltinListSortBy` 31.5 % cum, `builtinJsonEncode` 29.8 % (under the sort's comparator), `vmEscapeString` 16.9 %, `releaseFrame` 11.9 %, `memclrNoHeapPointers` 14.5 % flat. prefix (replay only): `releaseFrame` 11.7 %, no JSON encode in the top 40. Ablated: `builtinJsonEncode` 7.2 %, `NewRecord` 12.0 %, `releaseFrame` 14.3 % (94.8 % of it `memclrHasPointers`). |
| V20 (it. 108) | 04:00–04:03, load 2.8–3.6 | n/a | Ablation: the registry copied to `/tmp/stap108/abl-home/.ailang/cache/registry`, `social_dynamics/0.4.0/wire.ail:77` keyed (`replay/wire.ablation.diff`), lock hash updated in a second sim copy `/tmp/stap108/simabl` only; `HOME=/tmp/stap108/abl-home` V18's command ×3. Positive control that the copy is read: before the lock edit the run failed `dependency sunholo/social_dynamics content changed`. Byte check: `ailang run --quiet --bytecode --package-dir . --caps IO --entry main ship.ail < runs/h4.req.ndjson` in both copies | — | — | Decision tick 460: 2,193 / 2,206 / 2,180 ms per 50 = **43.6–44.1 ms** (from 64.1–64.8); control 0.32–0.42. Outputs: 640 lines each, `cmp` identical, sha256 `dd62855ccabb348d227cf2af30ffa978560e60525127813a14934fb40e5f1d04` for the unmodified copy, the ablated copy and the live game's recorded replies (`runs/h4.tap.rep`). |
| V21 (it. 108) | 03:55, load 3.49 | n/a | `godot --headless --path . --script $PWD/.godot/tmp/stap108/parse_bench.gd` ×3 (`bin/parse_bench.gd`: 300 parses each of the recorded tick-460 and tick-459 reply lines) | — | — | [godot parse bench] `JSON.parse_string` p50 0.430 / 0.431 / 0.440 ms (38,909 B), 0.419 / 0.384 / 0.375 ms (34,966 B); max 0.555 ms; `get_string_from_utf8` + `strip_edges` 0.017–0.019 ms. |
| V22 (it. 108) | 04:03–04:04 | n/a | `repro/sortedjson.ail` (standalone, no packages): `ailang run --quiet --bytecode --caps IO,Clock --entry main --args-json '{"n":12,"reps":2000}'` ×3, `'{"n":40,"reps":500}'` ×3, and n=12 on the interpreter ×3 (`repro/sortedjson.out`) | — | — | VM n=12: per-comparison encode 67 / 68 / 67 ms, keyed 27 / 26 / 27; VM n=40: 101 / 97 / 97 vs 29 / 29 / 28; interpreter n=12: 534 / 488 / 510 vs 392 / 400 / 410; `same_output true` every run. |
| V23 (it. 108) | — | n/a | `jq -r 'select(.changes.crew != null and .tick>300) \| "\(.tick) turn=\(.changes.crew.turn) rev=\(.changes.crew.revision) tau_d=\(.changes.clock.tau*365.25)"' runs/h4.tap.rep`; `jq` key and size counts on the same file; quotes `sim/crew_auto.ail:13–17, 34, 78–79` | — | — | Crew turn 1, 31, 61, 91, 121 at ticks 406, 460, 513, 566, 620; revision 45 at tick 406 (the first `crew` section of cruise), then 55 → 94; 98 → 134; 138 → 176; 180 → 215 on those ticks, 0–4 per turn otherwise (+8 at tick 410). 131 of 235 cruise replies carry `crew`; the ordinary ones 37.6–42.6 KB, 17.8–28.4 ms [tap clock] (tick 410: 61.6). |
| V24 (it. 108) | about 04:02 | n/a | `repro/frameclear.ail` (a 200-`let` function called once, then a 2 M-element `foldl`; `warm` true / false), `--bytecode`, 2 runs each | — | — | **Negative, kept as evidence:** fold 79 / 78 / 82 and 82 / 83 / 77 ms cold, 83 / 83 / 76 and 82 / 83 / 77 ms warm: no difference, so the frame-pool clear (`internal/vm/frame.go:78` at 05c860a, `clear(f.Regs[:cap(f.Regs)])`) is not shown to cost anything here; not claimed and not in the upstream draft. |

**Codebase premises** (quoted from the clone at `ad929704`; each backs a command or an option above):

| # | Premise | Quote (file:line) | Result |
|---|---|---|---|
| P0 | The extracted apparatus lives in an ignored path | `.gitignore:1` `.godot/`; `git check-ignore -v .godot/tmp/7av/x` → `.gitignore:1:.godot/` | Confirmed: nothing under `.godot/tmp/7av/` can be committed by accident, and `make python-guard` (tracked `*.py` only) does not see `analyse.py`. |
| P1 | R5's paths, JSON keys and log prefixes | `Makefile:13` `SCRATCH := .godot/tmp`; `Makefile:732` `… --script tools/m4_ship_bench.gd -- --tier=$(BRIDGE_TIER) > $(SCRATCH)/bench-bridge.log 2>&1`; `tools/m4_ship_bench.gd:132` `FileAccess.open("res://.godot/tmp/bench-bridge.json", FileAccess.WRITE)`; `:138` `"docked_control": control, "timing": timing,`; `demos/ship_demo_benchmark.gd:21` `return {"samples":n,…,"p99_ms":sorted[ceili(n*.99)-1],"maximum_ms":sorted[-1]}`; log lines `tools/m4_ship_bench.gd:66` `"bench-bridge: docked control 300 frames p50 %.2f p95 %.2f p99 %.2f ms …"`, `:121` `"bench-bridge: live transit %d frames in %.1f s …"`, `:127` `"bench-bridge: frame ms p50 %.3f  p95 %.3f  p99 %.3f …"` | Confirmed: R5's `.godot/tmp/bench-bridge.{log,json}`, `.docked_control.p99_ms`, `.timing.p99_ms` and the three grep prefixes match the instrument. R5 unchanged in substance. |
| P2 | O3's "up to 2 s" drain wait | `ui/galaxy_map.gd:985` `if not sim.drain(): # a pipelined heartbeat (SimBridge.pipelined): decide on the current world`; `bridge/sim_bridge.gd:357` `var ok := _read_state(Time.get_ticks_msec() + 2000, "step_timeout") and _finish(tick)`; `:558` `while Time.get_ticks_msec() < deadline:`; `:561` `var chunk := _pipe.get_buffer(4096)`; `:565` `OS.delay_msec(2)`; `:185` `var proc := OS.execute_with_pipe(AiBridge.scrub_shell(), AiBridge.scrubbed(launch), false)` | Confirmed and sharpened: the drain polls a non-blocking pipe every 2 ms for up to 2,000 ms, then fails with `step_timeout`. |
| P3 | O2's tick → refresh path, and whether SimBridge already has a non-blocking readiness API | `ui/galaxy_map.gd:982` `func tick() -> bool:`; `:1020` `refresh()` (the last statement before `return sent`); `:1257` `func refresh() -> void:`; `:1322` `earth_beams.refresh(_last_view)`; `:1323` `_overlay.queue_redraw()`; `demos/ship_geometry_demo.gd:1187` `var ok:bool=solar_tour.step() if solar_tour!=null else journey_map.tick()`. SimBridge's public methods (`grep -n '^func ' bridge/sim_bridge.gd`): `start`, `hello`, `new_game`, `send`, `in_flight`, `drain`, `stop`, `queue`, `queued_refused`, `caller_refused`; `:345–346` `func in_flight() -> bool:` / `return _inflight >= 0`; `:785–790` `func _fail(code: String) -> bool:` … `_cleanup()` | Confirmed: every tick ends in a full `refresh()` of the hidden panel and a queued overlay redraw. **Verified absence:** no public reply-ready check exists; `in_flight()` reports only that a tick is outstanding, and reusing `_read_state` with a zero deadline would end in `_fail` → `_cleanup()`. O3 would add a non-failing try-read over the existing non-blocking pipe. |
| P4 | The probe's scene is the bench's scene (tier, size, content scale, vsync, `max_fps`, setup options) | `Makefile:727` `BRIDGE_TIER = $(if $(filter command line environment,$(origin TIER)),$(TIER),medium)`; `tools/m4_ship_bench.gd:3` `const SIZE := Vector2i(2560, 1440)`; `:19–24` `root.size = SIZE` / `root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT` / `root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP` / `root.content_scale_size = SIZE` / `DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)` / `Engine.max_fps = 0`; `:25` `var tier := "medium"`; `:32` `demo.setup_options = {"size": SIZE, "sky_state": "rest", "seed": 424242, "ai": false, "tier": tier}`. The probe (Appendix A) has the same `SIZE` constant and the same six setup lines, `var tier := "medium"`, and the same `setup_options` literal. | Confirmed: the bench's default scene is medium tier at 2560x1440; the probe's --tier=medium and SIZE const reproduce it, so phase C and R2-R5 measure AC12's scene. (Controller, round 2.) |

Raw files: see "Raw artifacts" below (public bundle, sha256 per file). The third wait (`p2_wait3_aborted.rec`) was stopped after 1 reading so the headless V7 could run without overlapping a GPU window. **Probe revisions per run:** p1 ran the probe without the `T start unix` print and without the per-frame `line`/`keys` fields; h1 had the `T start unix` print only; h2 and p2 ran the final version in Appendix A (the bundle's `probe/probe_transit.gd`). The two additions are output-only.

## Goals and non-goals

**Goals.** Say what the transit's slow frames are made of, with each claim tied to a V-row; say what a fix could buy; give the next counted run a check that can see in-run contention.

**Non-goals.** No tracked code change, no bench change (`tools/m4_ship_bench.gd` stays the instrument; the probe copies its setup). No change to the 16.7 ms bound or the docked-control validity rule (D-147). No change to the GPU schedule (the model runner is not this loop's).

## Design: the options (for Mark; none is built)

**O1. Contention evidence beside each counted run (measurement, no product change).** Run Appendix B's sampler during every counted AC1 run and keep its file beside the bench log. A run whose in-run samples show the model runner above a few percent CPU, or the GPU at 100 %, is read as contended evidence, like a failed post reading today. This adds evidence to D-147's rule; whether it becomes part of the rule is Mark's (OQ1). Cost: none in the tree if it stays in the runner script; a bench-driver change if it is to live in `bench-bridge.json`.

**O2. Stop redrawing the hidden navigation map on every tick (game-side margin).** The same pattern 6pR3 fixed for `IsmLayer`: while `navigation_window` is hidden, `GalaxyMap.refresh()` (called at the end of every `tick()`, `ui/galaxy_map.gd:1020`; it rebuilds the title, subtitle, status, progress bar, clock and the details grid's bindings, then `earth_beams.refresh` and `_overlay.queue_redraw()`, `:1257–1323`; P3) would skip the panel's text and binding rebuild and `_overlay.queue_redraw()`, and `refresh()` once on show. It touches `ui/galaxy_map.gd` and a test that the map draws the same on show. Predicted effect: lower game time on tick frames (now 8.7 ms p50 quiet, 19–23 ms under contention). On a quiet rig tick frames are already 0 of 375 over 16.7 [V1], so the p99 gain there is predicted to be small; the gain is under contention, and **its size is UNMEASURED** (V6's ablation is the measurement). Risk: anything that reads the hidden map's labels between ticks (the read-only star chart, M) must still be current on show.

**O3. Do not block the frame on a late sim reply (game-side margin, design-heavy).** Today `GalaxyMap.tick()` starts with `sim.drain()` (`ui/galaxy_map.gd:985`), which polls the pipe until the reply arrives or 2 s pass (`bridge/sim_bridge.gd:357`, `:558–566`; P2). If the reply is not in yet, the frame could skip that tick and try again next frame, so a 35–53 ms reply (cruise start, `crew` sections, contention) never stalls a frame. This needs a new non-failing reply-ready check in `SimBridge` (verified absent, P3: `in_flight()` only says a tick is outstanding, and a zero-deadline `_read_state` would end in `_fail`, which calls `_cleanup()`; the pipe itself is already non-blocking, so no new I/O path is needed), and it changes how ticks line up with wall time (not the sim's inputs or outputs, so replays stay byte-identical; to be proven). It would remove the sim-wait class (11.3 % of slow frames) and probably the per-run 55–98 ms maximum. Larger blast radius than O2.

**O4. Make the crew section cheaper at cruise start (upstream).** If the quiet-rig measurement (OQ3) shows the cruise-start reply over 50 ms, its cost is in `crew_core` on the AILANG VM and is reported upstream with a repro, per the project rule, not worked around. **Iteration 108 (measured, V14–V23):** the cost is not the `crew` section but crew_core's monthly auto-run decision day (D-76; ticks 406, 460, 513, 566, 620): the step costs 62.6–64.8 ms on the VM against 0.32–1.02 ms on other days, the reply's encoding 17.6–18.1 ms either way. One line, `sunholo/social_dynamics` 0.4.0 `wire.ail:77` `sortedJson`, accounts for about 20.5 ms of the step (keyed sort: 43.6–44.1 ms, output byte-identical). That part is a package change upstream; the rest (~44 ms) is not decomposed, and the decision day would still be about 62 ms with it, over the 50 ms window. A draft report with a standalone repro is in the iteration-108 bundle, not sent.

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
db7c09ce45e89b067ced91672c47f3b25836a965d2514c691ec6139c541a4976  .godot/tmp/7av/bin/gate.sh
21940053253d0afd05ee0325ce987977deff517d2f640ae5446184aef23fe16e  .godot/tmp/7av/bin/gpusampler.pl
75eb8bd224d602491443472ea092f205f157b2165001aa815bf70f1e718f6bdd  .godot/tmp/7av/probe/probe_transit.gd
4135e2b5bf978bf752e22c8c7e12fb667b5e6a3c1a2fee87b583d159cc6f182a  .godot/tmp/7av/probe/analyse.py
SUMS
```

**R1. A run with the in-run sampler, counted only if quiet before, during and 3 s after.** The during-run gate is `gate.sh` (D1: fails closed on malformed lines, drilled in D1 — an empty file, a missing argument, a truncated or malformed line, a `?` sample, any runner process over 5 % CPU, or the GPU at 100 %):

```sh
r=$(git rev-parse --show-toplevel); s=.godot/tmp/7av
rm -f $s/runs/p3.json
$s/bin/counted2.sh p3 600 -- godot --audio-driver Dummy --path . --script $r/$s/probe/probe_transit.gd -- --tier=medium --out=$r/$s/runs/p3.json
test -s $s/runs/p3.json && grep -q '^PRE YES' $s/runs/p3.rec && grep -q '^RC 0$' $s/runs/p3.rec && grep -q '=> YES$' $s/runs/p3.rec \
  && ! grep -q 'SCRIPT ERROR' $s/runs/p3.log && grep -q '^probe: DONE$' $s/runs/p3.log \
  && $s/bin/gate.sh $s/runs/p3.gpu && echo "p3 counts" || echo "p3 is evidence only"
```

**R2. On a counted run, the transit p99, the docked control's validity, the slow-frame split and the compile count** (the attribution predicts boosting-phase p99 <= 16.2 and 0 pipeline compiles in T; the cruise phase is what this counted run measures — its hitch candidates are the cruise-start crew reply and tick-frame draw cost):

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
- **The sampler is coarse and partly ambiguous.** One sample per 0.6–0.7 s. The GPU column cannot say who holds the GPU (in p2 it read 0–1 % whenever the runner was under 5 % CPU before T, and 99–100 % in T while the runner's CPU was 1.6–11.2 %), and the runner CPU column alone misses GPU-resident inference; that is why the gate checks both every runner process and the GPU (D1).
- **The gate may reject runs that were fine.** It covers the whole command, setup included, and the runner can blip above 5 % CPU without using the GPU (V5's first sample read 13.9 % with the GPU at 4 %). That costs runs, not correctness: it fails closed on malformed lines, drilled in D1.
- **Known fail-open edges of `gate.sh` (evaluator round 1; fixed in iteration 107, drilled in D3, B.2 sha256 `db7c09ce…4976`).** As found: It still exits 0 on a runner field of `.` or `1..2` (the number regex is unanchored for those), on an extra field after `$4`, and on a one-line file, so a sampler that died after its first line passes (there is no sample-count or time-coverage check). Fix before R1 is used to count a run: anchor the CPU regex (`^[0-9]+(\.[0-9]+)?$`), require `NF == 4` (or `NF == 6` with `BAD ioreg-miss`, which already fails), and require samples spanning the run (for example at least one per 1 s of the run's wall time). Also the GPU column alone is what catches p2's contended regime (finding 1); the 5 % runner-CPU rule would miss it.
- **Contention onset in p1 is inferred** (no sampler in V1): from the step in frame times and the GPU 100/100/100 post reading. p2 has the sampler.
- **Classifier bias.** The "draw bracket" class is a wall interval; under contention it includes waiting on a GPU shared with the runner. It says where the wall time went, not why (7m-d's caveat; a Metal System Trace is still UNMEASURED).
- **Probe perturbation.** 634 CanvasItem signal connections and per-frame `Performance` reads. The docked phase C agrees with the bench's band (15.48 and 16.77 against 15.18–19.19 in 7m-d and iteration 103).
- **The quiet gaps are short.** Both GPU runs began in gaps of under a minute. A counted run may need a scheduled GPU window (OQ4).

## Open questions for Mark

- **OQ1. In-run contention evidence for AC1.** Should a counted AC1 run also need the in-run gate clean (R1's `gate.sh`), or stay on the pre and +3 s readings (D-147 Q1 B)? Recommendation: keep the sampler file beside the bench log now (no rule change), and decide on the rule after two counted runs.
- **OQ2. Which game-side margin, if any.** O2 (gate the hidden map's per-tick refresh; small, like 6pR3), O3 (non-failing try-read and skip the tick; larger), both, or neither until the quiet cruise phase is measured. Recommendation: measure R4 first; O2 only if it moves tick-frame game time or the p99.
- **OQ3. The cruise-start reply.** If a counted run shows the first `crew` reply over 50 ms on a quiet rig, report it upstream (O4) and cite it in AC12's record. Iteration 108 (headless, V14–V20): the slow replies are the monthly decision days, not the first `crew` reply as such; sim-side they take 77.6–91.4 ms on every decision day of 3 runs (the frame waits 11.0–92.5 ms of it), the excess is the crew_core step on the VM, and about a third of that step is one upstream package function (O4). Whether to send the drafted report, and whether to take O3 for the rest, are Mark's.
- **OQ4. A GPU window for counted runs.** Of the designer's 76 pre-run `quiet2.sh` readings in this fire (plus 2 post readings, both NO), 2 were YES, and both runs that started on them were contended within seconds. A scheduled 10-minute window with the runner paused would make R1–R5 a single sitting.

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

**Iteration 107 bundle:** **https://storage.googleapis.com/stapledons-voyage-assets/benchmarks/7av-iter107/7av-iter107-evidence.tgz** (`gs://stapledons-voyage-assets/benchmarks/7av-iter107/7av-iter107-evidence.tgz`, 456,275 bytes, sha256 `bd19a388c2e403c6c92fad484f5973bd4fd8bcbdabc817d616bb72ee6602c9d9`). It is `tar czf 7av-iter107-evidence.tgz runs probe bin drill107` from `.godot/tmp/7av/` in the iteration-107 clone: every run's `.rec`, `.log`, `.gpu` and output (`pN.json`, `a1.json`, `bN.bench.{log,json}`), the probe and spike as run (R0 sha256s), `bin/` with the fixed `gate.sh` and the iteration-105 `gate.iter105.sh`, and `drill107/` (D3's `drill.sh`, its input files and `drill_output.txt`). Upload checked with `gcloud storage ls -L` (Content-Length 456275, MD5 `gOTB9LWhaOKzzjsI2MGFmA==`, created 2026-11-20T19:44:54Z), and a public re-download by `curl` hashed to the same sha256.

```sh
mkdir -p .godot/tmp/7av/evidence107 && cd .godot/tmp/7av/evidence107
curl -sfLO https://storage.googleapis.com/stapledons-voyage-assets/benchmarks/7av-iter107/7av-iter107-evidence.tgz
echo "bd19a388c2e403c6c92fad484f5973bd4fd8bcbdabc817d616bb72ee6602c9d9  7av-iter107-evidence.tgz" | shasum -a 256 -c && tar xzf 7av-iter107-evidence.tgz
```

| file in the bundle | V-row | sha256 |
|---|---|---|
| `runs/p3.{rec,log,gpu,json}` | V8 | `8b85b3026841a783daf68626b2b5c44bc96e29233964422a1b4893826f81ddd0`, `69447b48d01fc86251f04d6075853e973e337649a9058c5e39002e48ed58cec5`, `2e16a90b7cc9083961e900076da43c8974706ca5fc8e6dbe47362ae389aa0df8`, `7fed06bd1a14254a51cafb5bba1de34b4396c6a64d7153ba34fac5861d22ff4b` |
| `runs/b1.{rec,log,gpu,bench.log,bench.json}` | V9 | `861f94c5337b805c374da473de423d77f3078d5cfbcd6d331b69a045be1f78ef`, `18b6bcb50a46548b0835f41a850d37f67fb2c104b4d63d79354c9d1e6900358d`, `543d1ba9b7ea0b8db66672ccda091d7d9910c87c5ca03c93a085b6a40ee8da40`, `fa228d555f60c502e1a6acf28d0eb07954cd6e07df3c131bdc01e2369c50079d`, `0f089d725ed30c660041ede4a8456c2a9c3bcf4c22018b00782c5419c29b967b` |
| `runs/b2.{rec,log,gpu,bench.log,bench.json}` | V10 | `c3f8c618ba074758ec662693c6c828bc7ad9258dda97045fc12e94e32dcbd0c5`, `8acfff3fe2c15a939eb225ee13c7ef1e0097336b6d1cbb426ffa49bbbdfa49cb`, `35ec7b5529bd5f94c5e0054911ea7c5bec7efbd97d7da0b1a3b85ff90db5bddd`, `aabaa8bfccf74c6eac2e29239710d9c07d7fdfbaa104149b535c6e867f958112`, `dcba6154501144661f6ab0acdf45734a24eb4fadbdab809bdc0ea96a968b75ff` |
| `runs/a1.{rec,log,gpu,json}` | V11 | `5ffd66206b53f8a068039db9d1da973df849e73251f68d72b08183962bc2c6e3`, `465295305148979d50660f7bee8d6c525f07ecee1c1fbf54b4eaa08475daf7ef`, `4a19d7c551e21e5a9cba732c042f485f694607fbce030c37dff9049ff31850d3`, `62dda4f4e494a5ffaa2ce107f99920d0673dcefe6d97dfe3f928b7b1c2edafe9` |
| `runs/b3.{rec,log,gpu,bench.log,bench.json}` | V12 | `7aca75e16a502386bd92178d7f529604598e75032410a784e8c94e4389503fc2`, `dcd0c35aeeb498c7a56b7a9507e718ba56b1161cc55ad1edefab615f5ac769dd`, `db6cd8a781dd4b8dc755d397de46da701b9534c0bff12c4e846ccff67cd854ce`, `9d64f5c2832944d6b75620e313cf7ec3565a0927d58ddb0c15d932b9368452a7`, `8f29951aa9e2a84b3f69b77a9514d2d6e29167eb0c9029bacf704975a73b2007` |
| `runs/p4.{rec,log,gpu,json}` | V13 | `c25d0f25d0b79ee496b212c9c0c9a6338644e642e9bc24b5f6ee5c11ef76e4a1`, `e0fdb870bf1553e6158076ccf8317c1cf5f5f29d69178e081ced71056fc014ca`, `429e87005434281aed291848c1017ab7aa3ffc91f60c009c8a0a8d148be5cd84`, `bef61ced676a17c369207da5a40dadfc4f9a8c6069197145bce3ffcd15c71860` |
| `bin/gate.sh`, `bin/gate.iter105.sh` | D3 (fixed, old) | `db7c09ce45e89b067ced91672c47f3b25836a965d2514c691ec6139c541a4976`, `5c8fb3d6079d8eb06ffc951e986c4317da84b7bc6e998d6ef77d516bb437a036` |
| `drill107/drill.sh`, `drill107/drill_output.txt` | D3 | `ccaf1e3af350f009ca83b0e93d392fcb17dfd2fb1f7909de5bcbcd824959a326`, `f4debd0061e0bc5524e1676b7aed724a88d73fca993e3bd5b1c556498ab7a6ac` |

**Iteration 108 bundle:** **https://storage.googleapis.com/stapledons-voyage-assets/benchmarks/7av-iter108/7av-iter108-evidence.tgz** (`gs://stapledons-voyage-assets/benchmarks/7av-iter108/7av-iter108-evidence.tgz`, 18,641,718 bytes, sha256 `694cd6d3da02c0ec97b77f584877bbb43c932b1aa9e677fe8bdce0917b9fccd3`). It is `tar czf 7av-iter108-evidence.tgz runs bin replay repro probe upstream-draft.md` from `/tmp/stap108`, less two replay outputs that equal `runs/h4.tap.rep` byte for byte (V20's sha256): `runs/` (the tap logs `hN.tap`, the recorded streams `hN.tap.req` / `hN.tap.rep`, probe outputs `hN.{json,log}`, `bin/host.sh` readings `*.host*`, the replay, interpreter, decision, encode, parse and ablation outputs, and the four CPU profiles with their `pprof` text), `bin/` (`simtap.pl`, `simtap.sh`, `gwait.sh`, `host.sh`, `parse_bench.gd`), `replay/` (the scratch drivers, `wire.ablation.diff`, `scratch-tree.diff`), `repro/` (`sortedjson.ail` and its output, the negative `frameclear.ail`, a copy of the draft), `probe/probe_transit.gd` (R0's sha256) and `upstream-draft.md` (not sent). Upload checked with `gcloud storage ls -L` (Content-Length 18641718, MD5 `G2mkxM7aXteHyTd+m8W/NQ==`, created 2026-11-21T03:07:30Z), and a public re-download by `curl` into an empty directory hashed to the same sha256.

```sh
mkdir -p .godot/tmp/7av/evidence108 && cd .godot/tmp/7av/evidence108
curl -sfLO https://storage.googleapis.com/stapledons-voyage-assets/benchmarks/7av-iter108/7av-iter108-evidence.tgz
echo "694cd6d3da02c0ec97b77f584877bbb43c932b1aa9e677fe8bdce0917b9fccd3  7av-iter108-evidence.tgz" | shasum -a 256 -c && tar xzf 7av-iter108-evidence.tgz
```

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

Round 2 (2026-11-20T05:06Z): oc-kimi-k3 **reject**, oc-glm-5-3 **reject**, gemini-4-argon **pass**, codex absent (quota). Again nobody disputed the direction, and both rejects carried a concrete reviewer-authored fix. Under the mission skill's narrow-refinement carve-out the controller applied those fixes verbatim in a bounded second revision (no new measurement claims beyond the premise check and the drills below).

| reviewer | objection | applied |
|---|---|---|
| oc-kimi-k3 | The round-1 gate still failed open on a malformed or truncated sampler line (`$2+0` reads as 0), and with no argument awk read stdin and hung. | `gate.sh` (B.2) is now the reviewer's structure-validating version verbatim, with the `[ -s "$1" ] \|\| exit 1` guard. Re-drilled in D1: truncated final line exit 1 (the round-1 gate exited 0 on it), no argument exit 1 with no hang, the five earlier drills unchanged (1, 1, 1, 1, 0). The R0 SUMS block and B.2 carry the new sha256 `5c8fb3d6…a036`. Wording changed to "fails closed on malformed lines, drilled in D1" in the status line, R1 and Risks. Confidence's p2 bullet reworded as the reviewer wrote it (513 of 513 is base-rate; the in-run rate step is the evidence). |
| oc-glm-5-3 | The probe = bench equivalence was asserted: `BRIDGE_TIER`'s default and the bench's size, content scale, vsync and `max_fps` were not quoted. | New premise row **P4**, quoted from `Makefile:727` and `tools/m4_ship_bench.gd:3, 19–25, 32`: the default tier is medium at 2560x1440 and the probe reproduces every setup line. R2's parenthetical reworded as the reviewer wrote it. The 375 / 374 tick-frame counts are reconciled in findings 3 and 5 by naming each filter (`dtick > 0` over the first 1,840 T rows; the same with `phase == "boosting"`, which drops row 1,840, the first cruising frame), re-derived by the controller from `p1.json`. |
| gemini-4-argon (pass; advisory) | R1's `\|\| echo "… evidence only"` makes the pipeline exit 0 either way; and `analyse.py` computes the first T row's deltas against the previous phase. | Not applied (not blocking). Noted: R1 and R4 report by their printed line, not their exit status. For p1 the first T row's `tick` and `sends` equal the last S row's (29 and 30), so the delta edge changes no count here. |

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

**`gate.sh`** (sha256 `db7c09ce45e89b067ced91672c47f3b25836a965d2514c691ec6139c541a4976`; fixed in iteration 107: anchored CPU regex, `NF == 4`, and sample coverage of the run read from the sibling `.rec`. The iteration-105 gate, sha256 `5c8fb3d6079d8eb06ffc951e986c4317da84b7bc6e998d6ef77d516bb437a036`, is in git history and in the iteration-107 bundle as `bin/gate.iter105.sh`):

```zsh file=.godot/tmp/7av/bin/gate.sh
#!/bin/zsh
# gate.sh FILE.gpu [FILE.rec] (7av R1; fail-open edges fixed in iteration 107): exit 0 only if FILE.gpu is non-empty,
# EVERY line is well-formed (NF==4; $1 a unix time, increasing; $2 an integer GPU % < 100; $3=="ollama_cpu"; $4 '-' or a
# comma list of anchored numbers ^[0-9]+(\.[0-9]+)?$) with no runner > 5 %, AND the samples span the run: FILE.rec
# (default FILE.gpu with .rec) holds `PRE YES HH:MM:SS` and `POST quiet: HH:MM:SS`; the first sample is 0-3 s after PRE,
# the last is at most 10 s before POST (the wrapper's sleep 3 plus quiet2.sh's ~3.5 s), no two samples are > 2 s apart,
# and there is at least one sample per 1 s from PRE to the last sample. A `? ... BAD ioreg-miss` line (NF 6) fails.
[ -s "$1" ] || exit 1
rec=${2:-${1%.gpu}.rec}
[ -s "$rec" ] || exit 1
zmodload zsh/datetime
pre=$(awk '/^PRE YES /{print $3; exit}' "$rec"); post=$(awk '/^POST quiet: /{print $3; exit}' "$rec")
[[ "$pre" == <->:<->:<-> && "$post" == <->:<->:<-> ]] || exit 1
f=$(awk 'NR==1{printf "%d", $1}' "$1"); l=$(awk 'END{printf "%d", $1}' "$1")
[[ "$f" == <-> && "$l" == <-> ]] || exit 1
ep() { local d t; strftime -s d '%Y-%m-%d' $2; t=$(strftime -r '%Y-%m-%d %H:%M:%S' "$d $1") || return 1
  (( t - $2 > 43200 )) && (( t -= 86400 )); (( $2 - t > 43200 )) && (( t += 86400 )); echo $t; }
P=$(ep $pre $f) && Q=$(ep $post $l) || exit 1
awk -v pre=$P -v post=$Q '
  NF!=4 || $1 !~ /^[0-9]+(\.[0-9]+)?$/ || $2 !~ /^[0-9]+$/ || $3!="ollama_cpu" {bad++; next}
  { if ($4 != "-") { n=split($4,c,","); for(i=1;i<=n;i++) { if (c[i] !~ /^[0-9]+(\.[0-9]+)?$/) {bad++; next} if (c[i]+0>5) bad++ } }
    if ($2+0>=100) bad++
    if (k>0 && ($1<prev || $1-prev>2)) bad++
    if (k==0) first=$1; prev=$1; k++ }
  END { if (NR==0 || bad>0) exit 1
        if (first<pre || first>pre+3) exit 1
        if (prev<post-10 || prev>post) exit 1
        if (k < prev-pre) exit 1
        exit 0 }' "$1"
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
