# The live-transit frame cost on the 3D-ship bridge (M4.6pR3, queue row 7m)

**Status:** Planned (mission iteration 37, designer). **Release:** r1. **Milestone:** M4.6, gated half, round-3 sub-milestone M4.6pR3 (sprint `R1-M4-JOURNEY`, feature `M4.6_PHYSICS_GATES`). Item class `[LOOP]`: the loop can build this one end to end. The fix is headless-testable, and the bench needs the rig's GPU window, which the unattended session has.
**Priority:** P1. It turns AC12 of the R1 bar's clause 4 green. It sits on the path M4.6rR3 → **M4.6pR3** → ⏸ S1 → ⏸ P-land.
**Implements:**
- [m4-first-journey.md](m4-first-journey.md) **AC12** as amended 2026-10-12: "`make bench SCENE=bridge` benches the 3D-ship bridge in live transit", p99 < 16.7 ms at 2560×1440.
- [m4-6rr3-ship-renders-bench.md](m4-6rr3-ship-renders-bench.md) "Contradictions 1" and its Spike section. That spike found the miss and left the cause UNMEASURED. This doc names the cause.
- Ledger D-14: the 60 fps bar.
- Design repo: [02-bridge-interior](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/02-bridge-interior.md) (the bridge is where the player rides out a transit), and [ism-structure-and-dust.md](../../implemented/r1/ism-structure-and-dust.md) I6 (section 7.2, the map medium layer). The galaxy map's medium layer is the code this fix touches, and it must draw identically when the map is open.
- [relativity-spec §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md#2-special-relativity-moving-observer-flat-space): no formula changes. The fix touches no SR or GR visual, so physics gate 2 is not triggered (see Goals).

**Depends on:** M4.6rR3 (loop PR #265, head `175e006`, which adds `tools/m4_ship_bench.gd` and `make bench SCENE=bridge`). It does **not** depend on attended PR #264 (see Held files).
**Estimated LOC:** about 45: `ui/ism_layer.gd` +6, `tests/test_ism_layer.gd` +25, and a changelog fragment of about 10.

## Game vision alignment

Scored with the `game-vision-designer` skill's feature-validation mode against `../stapledons-design/vision/core-pillars.md` (design repo at `a6d2a16`), plus this repo's hard-sci-fi spec row. The run was unattended, so there was no interview: each pillar was checked for whether the change serves it or conflicts with it.

| Pillar | Score | Notes |
|---|---:|---|
| Choices Are Final | 0 | Commit, the sim and the journey are untouched. |
| The Game Doesn't Judge | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | The clocks and the pacing are unchanged. The sim sees the same ticks and the same inputs. |
| The Ship Is Home | +1 | A transit is spent on the bridge: walking the deck and looking out at the starbow. Today that view stutters at p50 13–15 ms / p99 35–36 ms [m4_ship_bench], with about 43 % of frames over 16.7 ms. After the fix it runs at p99 15.5–16.3 ms, with fewer than 1 % of frames over. The ship feels like a place, not a slideshow. |
| Grounded Strangeness | 0 | Not relevant. |
| We Are Not Built For This | 0 | Not relevant. |
| Hard sci-fi authenticity (spec) | 0 | Nothing physical changes. The ISM map layer draws the same data whenever it can be seen. |
| **Net** | **+1** | **Go.** This is performance work. No pillar is negative. |

## Problem

AC12 fails at HEAD. On a quiet rig (GPU idle before the run, host load 1.4–2.3, Apple M4 Max, Metal, Forward+, Godot 4.7.2, 2560×1440, medium tier, vsync off):

| run | frames | p50 | p95 | p99 | over 16.7 ms |
|---|---:|---:|---:|---:|---:|
| `make bench SCENE=bridge` run 2 (07:25) | 1500 | 13.649 | 33.822 | **36.035** | 659 |
| `make bench SCENE=bridge` run 3 (07:26) | 1447 | 14.947 | 34.239 | **36.217** | 685 |
| byte-identical driver copy, ctl5 / ctl6 (07:21) | 1533 / 1501 | 13.26 / 13.44 | 32.7 / 33.4 | **34.59 / 34.95** | 630 / 649 |
| docked control, same runs (no journey) | 300 each | 9.8–10.5 | 14.1–15.2 | 15.85–17.62 | n/a |

Iteration 36's p99 of 85 ms was measured at host load 5–6. Today's first run (06:17) had Ollama holding the GPU at 92–100 % device utilisation. It measured 322 frames, p50 84.2 ms and p99 261.3 ms [m4_ship_bench], with the docked control at p50 30.8 ms. Under contention the live transit spirals: slow frames bank up to 4 catch-up ticks per frame (`_journey_accum` caps at `4/TICK_HZ`), and the extra ticks make the next frame slower. A loaded rig therefore inflates the miss. The cause, below, is the same under both conditions.

### Root cause (measured)

**Every sim tick redraws the galaxy map's overlay in the hidden navigation window, and the overlay's ISM layer then projects and fills 905 surface triangles in GDScript: 23.5–24.8 ms of main-thread CPU per tick [probe overlay `_draw` bracket, p50 over 184 draws].** At 20 Hz the tick lands in most frames, so most frames pay for it.

The chain is in the code (Verification Log V1–V6):
1. `GalaxyMap.tick()` ends with `refresh()` (`ui/galaxy_map.gd:811`). `refresh()` ends with `_overlay.queue_redraw()` (`:1108`).
2. `_overlay.draw` is connected to `_draw_overlay` (`:237`), which calls `ism_layer.draw(_overlay, …)` (`:1424`).
3. The map lives in an embedded `Window` that the bridge keeps hidden (`demos/ship_geometry_demo.gd:625`). The overlay sits under a `CanvasLayer`, so `is_visible_in_tree()` is **true** even though the window is hidden [probe: `overlay visible_in_tree true window visible false`]. Godot runs the queued `_draw` anyway, and throws the result away.
4. `IsmLayer.draw` (`ui/ism_layer.gd:254`) runs `_fills` over the LIC and the 14 cloud surfaces (905 triangles [probe]), with a `Callable` call, `is_position_behind` and `unproject_position` per vertex, then `_lines` and `_label`.

Why iteration 36 saw the cost in "the frame **after** a tick": `queue_redraw` is deferred. `_draw` runs in the message-queue flush **after** every node's `_process` and **before** `RenderingServer` draws. A bench script resumes on `process_frame`, which comes before the nodes' `_process`, so it books the flush into the next interval. The cost really falls in the same Godot frame, between `_process` and `frame_pre_draw`.

**Discriminating measurements** (the same 30 s live-transit driver, back-to-back, ABBA order, quiet GPU; "fix" and "noism" are a one-line runtime toggle in an untracked driver copy, so no tracked file was edited):

| tree | variant | frames | p50 | p95 | p99 | over 16.7 | verdict |
|---|---|---:|---:|---:|---:|---:|---|
| main `175e006` | control (`bench_ctl`, byte-identical to `tools/m4_ship_bench.gd`) | 1533 / 1501 | 13.26 / 13.44 | 32.7 / 33.4 | 34.59 / 34.95 | 630 / 649 | MISS |
| main `175e006` | **noism**: `ism_layer.visible = false` after commit (emulates the fix below) | **3271 / 3227** | 9.95 / 10.02 | 13.7 / 13.0 | **16.08 / 15.75** | 25 / 17 | **ok** |
| main `175e006` | fix-wide: `_overlay.visible = false` (no overlay at all while hidden) | 3375 / 3337 | 9.96 / 10.01 | 13.9 / 13.9 | 16.15 / 15.50 | 19 / 22 | ok |
| #264 `849d867` | control | 1500 / 1480 | 13.30 / 13.73 | 32.9 / 33.9 | 34.90 / 35.70 | 628 / 669 | MISS |
| #264 `849d867` | **noism** | **3270** | 10.04 | 13.8 | **16.18** | 19 | **ok** |
| #264 `849d867` | fix-wide | 3398 | 9.92 | 14.2 | 16.28 | 24 | ok |

Taking out just the ISM layer's draw while the window is hidden takes p99 from 34.6–36.2 to 15.75–16.18 ms and more than doubles the frame count. Taking out the whole overlay gains nothing measurable on top (the rest of the overlay is 1.9–2.0 ms per tick [probe]). So the ISM layer is the cause, and the minimal fix belongs in `ui/ism_layer.gd`.

**Frame segments** (probe, per frame: `nodeproc` from a priority −100000 node's `_process` to a +100000 one; `flush` from that to `RenderingServer.frame_pre_draw`; `draw` from `frame_pre_draw` to `frame_post_draw`). One contended run, all variants of one tree, live transit:

| variant | frames | wall p50 | nodeproc p50 | flush p50 | draw p50 |
|---|---:|---:|---:|---:|---:|
| docked (no journey) | 240 | 18.47 | 0.27 | **0.00** | 18.12 |
| live control | 121 | 107.80 | 47.80 | **52.53** | 8.32 |
| live, frozen afterwards at β 0.9729 | 240 | 19.96 | 0.91 | **0.00** | 18.54 |
| live, navigation window removed from the tree (`nomapwin`) | 434 | 23.92 | 3.80 | **0.03** | 10.79 |
| live, overlay `draw` disconnected (`nooverlay`) | 314 | 39.01 | 4.34 | **0.33** | 31.54 |
| live, ISM layer off (`noism`) | 371 | 23.05 | 4.19 | **2.56** | 11.49 |
| live, overlay hidden (`overlayhide`) | 301 | 43.54 | 4.11 | **0.31** | 33.14 |
| live, all `SimBridge.stepped` handlers disconnected (`nostepped`) | 272 | 41.90 | 4.17 | 33.41 | 4.71 |
| live, ship HUD hidden (`nohud`) | 240 | 49.39 | 4.95 | 39.13 | 4.81 |

`flush` is the only segment that tracks the variable. The `draw` column swings between runs with Ollama's GPU load (20–100 %); it moves with the GPU, not with the variants. On a quiet rig, live `flush` has p50 0.00 (most frames have no tick) and p95 27.2–27.9 ms (the frames that do) [probe c5_none, p4_timeov].

### Re-measured, and not the cause

| Claim from iteration 36 | Re-measured here | Verdict |
|---|---|---|
| Sim wait is 0.8 ms per frame | p50 0.00–0.66 ms/frame quiet [m4_ship_bench]; p95 0.67–0.86 [probe `send`]. Contended: p50 19.70 [bench 06:17], p95 19–52 [probe] | Not the cause on a quiet rig. Under load the tail comes from catch-up ticks (several drains in one frame), which the slow frames themselves cause. |
| The sky renderer costs 6.3 ms | Frozen live scene at β 0.9857 (ticks stopped): wall p50 19.62 vs docked 19.77 in the same run [probe c_frozen] | Not the cause. Rendering at high β costs no more than docked. |
| The tick's own GDScript costs about 3 ms | `nodeproc` p50 0.68–4.3 ms with ticks on [probe] | Confirmed small. |
| `GalaxyMap._process` | Removing the window from the tree removes the cost, but the tick still runs `journey_map.tick()` → `refresh()` there. The deferred `_draw`, not `_process`, carries the cost (`nooverlay` row). | Not the cause. |
| HUD and console relayout, `stepped` fan-out | `nohud` flush 39.13 and `nostepped` flush 33.41 vs control 41.5–52.5 (contended) | Not the cause. |
| Render CPU | `viewport_get_measured_render_time_cpu` root, sky and geometry p50 0.04–0.38 ms in every run [probe] | Not the cause. Metal reports no GPU timestamps (`GPU time n/a on Metal`). |
| Object churn | `OBJECT_COUNT` 3991 → 3981 and nodes 1030 → 1025 over a live run [probe] | No growth. |

Instrument note: `Performance.TIME_PROCESS` read from a `--script` SceneTree gave p50 144 ms docked against a wall p50 of 8.8 ms [probe c_control]. It is not usable here. The frame segments come from `Time.get_ticks_usec()` marks.

### What #264 changes

Attended PR #264 (chunked cruise, cruise digest, crossing review) **does not change AC12** on a quiet rig: control p99 34.90 / 35.70 vs main's 34.59 / 34.95 (and 36.0 / 36.2 through `make`). The root cause **survives it unchanged**: overlay `_draw` with the ISM layer is p50 24.76 ms vs 1.92 ms without [probe p4_timeov], against 23.70 vs 1.91 on main [c5_timeov]. The same fix turns it green on #264 (p99 16.18, 3270 frames). #264 touches `ui/galaxy_map.gd` by 4 added lines in `field_value` only, and touches neither `ui/ism_layer.gd` nor `tests/test_ism_layer.gd` (V7, V10).

## Goals and non-goals

**Goals:**
- AC12 green on a quiet rig: `make bench SCENE=bridge` p99 < 16.7 ms.
- Leave what the player sees unchanged. When the map is open (helm or chart) it draws every medium exactly as today.
- Build it now, without touching a file a held PR touches.

**Non-goals:**
- **The open map's cost.** While the map is open in transit, it still pays about 24 ms per tick (the cost is the `_draw`, whatever the visibility). Making the ISM layer cheap (cache the projected faces and redraw them only when the map camera moves, not on every tick) is a follow-up row. It needs `ui/galaxy_map.gd`, which #264 holds. AC12 benches the bridge with the map closed.
- **The residual hitches.** The fixed runs still show 17–25 frames over 16.7 ms, with a maximum of 67–77 ms [m4_ship_bench]. Their source is **UNMEASURED**. The docked control's own p99 is 15.85–17.62 ms (Risks).
- **Physics gate 2.** No SR or GR visual changes, so no new golden or reference render is needed. `make golden` must simply stay 373 ok.
- **Changes to the sim, the protocol or the packages.** None are needed.

## Design

### M1: the ISM layer draws nothing into a hidden window

In `IsmLayer.draw` (`ui/ism_layer.gd:254`), right after the existing `if not visible or model.is_empty(): return 0`:

```gdscript
	# M4.6pR3: a map in a hidden window (the bridge keeps the navigation window hidden in
	# transit) draws nothing. Each tick's refresh() queues this, and its 905 projected faces
	# cost ~24 ms of main-thread time a tick. Showing the window redraws it.
	var host := overlay.get_window()
	if host != null and not host.visible:
		if not host.visibility_changed.is_connected(overlay.queue_redraw):
			host.visibility_changed.connect(overlay.queue_redraw)
		return 0
```

- `last_drawn` stays `[]` while the window is hidden. Its only readers are `tests/test_ism_layer.gd:86`, which draws into a `SubViewport` under the visible root window, and `tools/ism_map_surface_capture.gd`, which opens the map first (V11).
- **Redraw on show.** Both entry points already redraw: `open_navigation` and `open_chart` call `journey_map.set_mode(…)`, which ends in `refresh()` → `queue_redraw()` (`ui/galaxy_map.gd:754`). The queued draw runs in the same frame's flush, after `navigation_window.show()` (`demos/ship_geometry_demo.gd:568/580/596`). The `visibility_changed` connection is the belt and braces for any other caller that shows the window. The layer makes it once, the first time it skips a draw.
- **Determinism, precision.** Nothing in the sim data flow changes. Intents, ticks, `dtau` and the world are untouched, so CLAUDE.md gates 5 and 6 are not engaged (AC6 still re-checks the sim worlds).

**Test** (`tests/test_ism_layer.gd`, in `make map-ism-test`, which is part of `make test`): add an embedded `Window` (hidden) under `root`, with a `CanvasLayer` and a `Control` overlay inside it, connected the way the map connects it. Then:
1. Hidden: after `queue_redraw()` and two frames, `layer.last_drawn.size() == 0`, and `overlay.is_visible_in_tree()` is still true. That guards the premise.
2. `show()` the window with no explicit `queue_redraw`, and after two frames `last_drawn.size() == 15`.
3. The existing case (an overlay under the visible root's `SubViewport`) still draws 15.

The `passed` count rises from 16 to 19.

### Milestone

One sprint-sized step, M1. It is test-first: write the test (red at HEAD for case 1, which draws 15 today), then the guard, then AC1–AC8.

## Held files

Exact file set: **`ui/ism_layer.gd`, `tests/test_ism_layer.gd`, `changelogs/unreleased/` fragment** (one new file). Checked against `gh pr view {264,267,262} --json files` (V7): **no collision.** None of the three PRs touches `ui/ism_layer.gd`, `tests/test_ism_layer.gd` or `mk/ism.mk` (0 of 84 / 100 / 30 paths). **The fix can be built now on main and does not wait for #264.** It works the same on #264's tree (measured above), so it does not need designing against that tree. The cleaner alternative, the whole overlay skipping its `_draw` in `ui/galaxy_map.gd`, would collide with #264. It gains nothing measurable (fix-wide vs noism rows), so it is not proposed.

## Acceptance criteria

| # | Criterion | Command | Expected |
|---|---|---|---|
| AC1 | AC12 green on a quiet rig. Record the load and GPU state first. | `ioreg -r -d 1 -c IOAccelerator \| grep -o '"Device Utilization %"=[0-9]*'; uptime; make bench SCENE=bridge AILANG=runtime/bin/ailang; echo rc=$?` | utilisation < 15 and 1-min load < 5 before the run; `rc=0`; the log has exactly 1 `^bench-bridge: OK$` and a `(target p99 < 16.7: ok)` line |
| AC2 | Frame-count validity floor (the cost is gone, not hidden) | `L=.godot/tmp/bench-bridge.log; n=$(sed -n 's/^bench-bridge: live transit \([0-9]*\) frames.*/\1/p' $L); test "$n" -ge 2500` | exit 0 (spike: 3227–3398 fixed vs 1447–1533 at HEAD) |
| AC3 | Both phases measured, valid run | `test "$(grep -c '^bench-bridge: FAIL' $L)" = 0 && grep -q 'boosting [1-9][0-9]*, cruising [1-9][0-9]*' $L` | exit 0 |
| AC4 | Hidden-window test, and the layer still draws every medium when visible | `make map-ism-test; grep '^ism-layer:' .godot/tmp/map-ism-test.log` | rc 0; `ism-layer: 19 passed, 0 failures` |
| AC5 | Open map unchanged: the Navigation station's density view draws all 15 media | `AILANG_BIN=$PWD/runtime/bin/ailang godot --path . --script tools/ism_map_surface_capture.gd \| grep '^map-surface-capture:'` | `map-surface-capture: 0 failures, 15 media` (same as HEAD, V12) |
| AC6 | Rendered result unchanged | `make golden AILANG=runtime/bin/ailang` then `make capture-m4 AILANG=runtime/bin/ailang && cp renders/m4/worlds.sha256 /tmp/after.sha && cmp /tmp/before.sha /tmp/after.sha` (`before` from the same command at the base commit) | golden: 373 `^ok`, `golden: 0 failures`; `cmp` exit 0 (14 worlds byte-equal) |
| AC7 | `make test` green (includes `map-ism-test`, V9) | `PATH=$PWD/runtime/bin:$PATH make test; echo rc=$?` | `rc=0` |
| AC8 | No other file changes | `git diff --name-only origin/main...HEAD` | exactly `ui/ism_layer.gd`, `tests/test_ism_layer.gd` and one `changelogs/unreleased/` fragment |

## Mutation drills

One wrapper. ROOT is an explicit argument (a clone at the fix commit). The trap is set right after `mktemp`. `cmp` proves the mutation changed the file. make's rc is passed through, and counts are asserted with `test`.

```bash
#!/bin/bash
# usage: m46pr3_drill.sh ROOT EXPECT(red|green) PERL_EXPR MAKE_ARGS...
set -u
ROOT=${1:?ROOT}; EXPECT=${2:?red|green}; EXPR=${3:?perl}; shift 3
F="$ROOT/ui/ism_layer.gd"; test -f "$F" || { echo "drill: no $F"; exit 2; }
T=$(mktemp -d /tmp/m46pr3.XXXXXX)
trap '[ -f "$T/orig" ] && cp "$T/orig" "$F"; rm -rf "$T"' EXIT
cp "$F" "$T/orig"
perl -0pi -e "$EXPR" "$F"
cmp -s "$T/orig" "$F" && { echo "drill: mutation changed nothing"; exit 3; }
make -C "$ROOT" "$@" AILANG=runtime/bin/ailang > "$T/make.log" 2>&1; rc=$?
L="$ROOT/.godot/tmp/bench-bridge.log"
case "$EXPECT" in
  green) test $rc = 0 || { echo "drill: expected green, make rc $rc"; exit $rc; } ;;
  red)   test $rc != 0 || { echo "drill: expected red, make rc 0"; exit 1; } ;;
esac
case " $* " in *" SCENE=bridge "*)
  test "$(grep -c '^bench-bridge: OK$' "$L")" = 1 || { echo "drill: invalid measurement"; exit 1; }
  if [ "$EXPECT" = red ]; then test "$(grep -c 'target p99 < 16.7: MISS)$' "$L")" = 1 || exit 1
  else test "$(grep -c 'target p99 < 16.7: ok)$' "$L")" = 1 || exit 1; fi ;;
esac
echo "drill: $EXPECT as expected (make rc $rc)"; exit 0
```

| Drill | Mutation (perl on `ui/ism_layer.gd`) | Target | Must |
|---|---|---|---|
| DR1 (root cause back) | `s/if host != null and not host.visible:/if false:/` | `bench SCENE=bridge` | red: valid run, 1 MISS line (spike: p99 34.6–36.2) |
| DR2 (the test catches it headless) | the same expression | `map-ism-test` | red (case 1 draws 15) |
| DR3 (redraw-on-show guard) | `s/host.visibility_changed.connect\(overlay.queue_redraw\)/pass/` | `map-ism-test` | red (case 2 stays 0) |
| DR4 (green control) | `s/(# M4.6pR3: a map)/$1 (drill)/` (a comment only) | `bench SCENE=bridge` | green: 1 `ok` line |
| DR5 (no-op is refused) | `s/NO_SUCH_TEXT/x/` | any | exit 3 |

## Risks and mitigations

- **Thin margin.** The fixed p99 is 15.50–16.28 ms against 16.7, and the docked control's own p99 is 15.85–17.62 ms. The static bridge scene sits near the line by itself. AC1 needs a quiet rig: GPU utilisation < 15 % before the run (Ollama held the GPU at 92–100 % this morning, and the docked control went to p50 17–31 ms), and load < 5. If the docked control's p99 exceeds 16.7 in the same run, that run measures the rig, not the fix: rerun it. The residual frames over 16.7 are UNMEASURED (Non-goals).
- **The open map is still slow in transit** (about 24 ms per tick). A player at the helm or the chart during a transit sees about 30 fps. That is a follow-up after #264 lands: cache the projected ISM faces, keyed by the map camera.
- **A future caller shows the window without a redraw.** The `visibility_changed` connection covers it, and DR3 guards the connection.
- **A headless `Window.visible` quirk.** AC4 case 1 asserts the premise (`is_visible_in_tree()` true while the window is hidden), so a Godot change that alters it fails loudly.

## Open questions for the user

None.

## Deliverables

- `ui/ism_layer.gd`: the hidden-window guard (about 6 lines).
- `tests/test_ism_layer.gd`: three cases (about 25 lines).
- A changelog fragment: "The bridge no longer redraws the hidden star map's gas layer every tick. Live transit p99 drops from about 35 ms to about 16 ms on the M4 Max."
- The AC1–AC3 bench log, recorded with its load and GPU line in the sprint JSON.

## Spike (measured on the rig, 2026-10-17, mission iteration 37)

**Setup.** Apple M4 Max (Apple9), Metal, Forward+, Godot 4.7.2, AILANG v0.54.11 (`runtime/bin/ailang`). Clones: main `/Users/voightkampff/dev/sunholo-data/.stapledon-loop-iter37` at `175e006`, and #264 `/Users/voightkampff/dev/sunholo-data/.stapledon-probe-iter37-264` at `849d867`. The scripts and logs are in `/tmp/stap37/spike/`, outside both clones: `probe.gd`, `run_probe.sh`, `bench_{ctl,noism,fix}.gd`, `run_bench.sh`, `wait_gpu.sh`, and the `probe_*.log`, `bench_*.log`, `gpu_*.txt` and `base_C*.txt` files.
- `probe.gd` repeats the bench's setup (seed 424242, console commit to CNS5:3627, deck pose 30°/0.47). It then samples per frame: wall time, the frame segments above, the `send_ms_total` delta, viewport CPU render times, `OBJECT_COUNT`, draw calls and the tick count. It ends with a frozen phase (ticks stopped at the end β), and one variant per run is applied as a runtime toggle after commit.
- `bench_ctl.gd` is `cmp`-identical to `tools/m4_ship_bench.gd`. `bench_noism.gd` and `bench_fix.gd` each add one line before `demo.journey_auto_tick = true` (`cmp` proved them different).
- GPU state comes from `ioreg -r -d 1 -c IOAccelerator` "Device Utilization %", sampled every 2 s during each bench run. Quiet runs waited for 3 consecutive samples under 15 % (or under 40 % for the later pairs, all of which started at 0 %).
- **Contended period, 06:17–06:48:** `ollama ps` showed `qwen3.8:27b-mxfp8 … 100% GPU`, and utilisation read 92–100 %. Pair A (contended): control 384 frames p99 182.4, fix-wide 1132 frames p99 81.4, docked p50 16.9–19.9. Pair Q1–Q4 (06:48–06:52, GPU mean 15–30 %, ABBA): control 792 / 934 frames p99 129.4 / 109.4; fix-wide 3375 / 3337 frames p99 16.15 / 15.50. The later quiet controls (07:21–07:26) measured p99 34.6–36.2. Interleaving controls this way is why every comparison above is within a pair.
- The #264 clone needed `godot --headless --path . --import` (rc 0) because its class cache was stale. The first try failed with `Could not find type "CrossingReview"` and ran into the 600 s alarm (rc 142). The import created 5 untracked `*.uid` files, which were deleted afterwards (listed in `/tmp/stap37/spike/new_uids_P.txt`).

## Verification Log

The base is `175e006` in the main clone unless stated otherwise.

| # | Claim | Command | Observed |
|---|---|---|---|
| V1 | The overlay's `draw` runs `_draw_overlay` | `grep -n "_overlay.draw.connect\|layer.add_child(_overlay)" ui/galaxy_map.gd` | `237: _overlay.draw.connect(_draw_overlay)`, `238: layer.add_child(_overlay)` |
| V2 | `tick()` calls `refresh()`, and `refresh()` queues the overlay redraw | `awk 'NR>=774 && NR<=812 && /refresh\(\)/' …; awk 'NR>=1044 && NR<=1112 && /_overlay.queue_redraw/' …` | `811: refresh()`; `1108: _overlay.queue_redraw()` |
| V3 | `_draw_overlay` calls the ISM layer | `grep -n "ism_layer.draw(_overlay" ui/galaxy_map.gd` | `1424: ism_layer.draw(_overlay, camera, …` |
| V4 | The bridge's map is an embedded window, created hidden (control: the ship view is also `own_world_3d`) | `grep -n "navigation_window.hide();\|own_world_3d=true" demos/ship_geometry_demo.gd` | `625: navigation_window=Window.new();navigation_window.hide()…`; `629: …own_world_3d=true…`; `128: geometry_view…own_world_3d=true` |
| V5 | The overlay is visible-in-tree inside the hidden window; the map has 52 names and 5685 stars; there are 905 ISM triangles | probe (`probe_c2_none.log`, `probe_c4_timeov.log`) | `map names 52 catalogue 5685 overlay visible_in_tree true window visible false overlay size (2520.0, 1248.0)`; `ism layer … surfaces 905` |
| V6 | The open paths redraw via `set_mode` → `refresh()` before `show()` | `awk 'NR>=742 && NR<=756 && /refresh\(\)/' ui/galaxy_map.gd; grep -n 'set_mode("helm")\|set_mode("chart")\|navigation_window.show()' demos/ship_geometry_demo.gd` | `754: refresh()`; `568: …set_mode("helm")`, `580: …set_mode("chart")`, `596: navigation_window.show()…` |
| V7 | No held PR touches the fix's files (positive control: #264 touches `galaxy_map.gd`) | `gh pr view N --json files --jq '.files[].path' > prN.files`; `grep -c 'ui/ism_layer.gd\|tests/test_ism_layer.gd\|mk/ism.mk'` and `grep -c ui/galaxy_map.gd` | `pr264 0, galaxy_map 1, total 84`; `pr267 0, 0, 100`; `pr262 0, 0, 30` |
| V8 | `make golden` expects 373 ok | `grep -n "= 373" Makefile` | `387: test "$$(grep -c '^ok' $(SCRATCH)/golden.log)" = 373 && \` |
| V9 | `map-ism-test` is part of `make test` | `sed -n 29p Makefile \| tr ' ' '\n' \| grep -c "^map-ism-test$"` | `1` |
| V10 | #264 changes `galaxy_map.gd` by 4 added lines and leaves the ISM files alone | `git -C <264 clone> diff --numstat 13bcc40 849d867 -- ui/galaxy_map.gd ui/ism_layer.gd tests/test_ism_layer.gd` | `4 0 ui/galaxy_map.gd` (the other two absent) |
| V11 | `IsmLayer` is built only by the map and two tests; `last_drawn` has two readers | `git grep -n "IsmLayer.new()" -- '*.gd'`; `git grep -n last_drawn` | `tests/test_ism_layer.gd:26`, `tests/test_ism_surfaces.gd:8`, `ui/galaxy_map.gd:188`; readers `tests/test_ism_layer.gd:86`, `tools/ism_map_surface_capture.gd:23–24` |
| V12 | At HEAD the open map draws 15 media and the ISM test passes 16 | `godot --path . --script tools/ism_map_surface_capture.gd`; `make map-ism-test` | `map-surface-capture: 0 failures, 15 media` (rc 0); `ism-layer: 16 passed, 0 failures` |
| V13 | AC12 misses at HEAD on a quiet rig | `make bench SCENE=bridge AILANG=runtime/bin/ailang` ×2 (07:25, 07:26; GPU 0 % and 21 %, load 1.40 / 2.33) | `1500 frames … p99 36.035 … MISS`; `1447 frames … p99 36.217 … MISS`; make rc 2 |
| V14 | The miss under GPU contention | `make bench SCENE=bridge …` (06:17; GPU 92–100 %, load 1.99–2.81) | `docked control … p50 30.80`; `322 frames … p50 84.232 … p99 261.253 … MISS` |
| V15 | Removing the ISM draw passes on main and on #264 (control: the same driver without the line misses) | `run_bench.sh ROOT TAG bench_{ctl,noism,fix}.gd` | main noism `3271 … p99 16.084 … ok`, `3227 … p99 15.752 … ok`; ctl `1533 … 34.587 MISS`, `1501 … 34.945 MISS`; #264 noism `3270 … 16.178 ok`, ctl `1500 … 34.898 MISS`, `1480 … 35.695 MISS` |
| V16 | The overlay draw costs ~24 ms with the ISM layer and ~2 ms without | probe `timeov` (an ordered `draw` bracket; ISM switched off halfway) | main: `ism on 184 draws p50 23.54` / `23.70`, `ism off 160 draws p50 2.01` / `1.91`; #264: `24.76` / `1.92` |
| V17 | The flush segment carries the tick cost (control: docked and frozen are 0) | probe `c_split` | live `flush p50 52.53`; docked `0.00`; frozen `0.00` |
| V18 | Bisect: the window, the overlay and the ISM remove it; HUD and `stepped` do not | probe variants | flush p50: nomapwin `0.03`, nooverlay `0.33`, overlayhide `0.31`, noism `2.56`, nostepped `33.41`, nohud `39.13` |
| V19 | High-β rendering is not the cost | probe `c_frozen` | `frozen at phase boosting beta 0.9857`, wall p50 `19.62` vs docked `19.77` |
| V20 | `TIME_PROCESS` is unusable from a `--script` tree | probe `c_control` | docked `proc p50 144.53` vs `wall p50 8.81` |
| V21 | Both trees are restored | `git -C <clone> status --porcelain \| diff - status_before_<clone>.txt` | no difference for either clone (31 pre-existing `*.uid` lines each) |
