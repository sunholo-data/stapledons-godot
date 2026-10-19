# S1 renders and the ship bench on the 3D ship (M4.6rR3)

**Status:** Planned (mission iteration 36, designer). **Release:** r1. **Milestone:** M4.6, gated half, round-3 sub-milestone M4.6rR3 (sprint `R1-M4-JOURNEY`, feature `M4.6_PHYSICS_GATES`). Item class `[LOOP+RENDER]`: the loop builds the headless half, uploads the renders and **parks for Mark's S1 render sign-off** before the PR merges.
**Priority:** P1. Clause 4 of the R1 bar, on the critical path M4.6gR3 → **M4.6rR3** → ⏸ S1 → ⏸ P-land.
**Implements:**
- [m4-first-journey.md](m4-first-journey.md) AC11 and AC12 as amended 2026-10-12: `renders/m4/` captured from the 3D ship, and `make bench SCENE=bridge` on the 3D-ship bridge in live transit.
- [m4-first-journey-sprint.md](m4-first-journey-sprint.md) R3-4 (the `capture-m4` re-point and the `bench SCENE=bridge` driver), R3-7 (the M4.6rR3 row) and R3-8 (⏸ S1, round-3 form).
- [relativity-spec §4](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md#4-test-requirements): "reference renders at 0, 0.5, 0.9, 0.99 … each looking forward". Physics gate 2, third leg: "reference renders you have actually opened and looked at".
- [relativity-spec §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md#2-special-relativity-moving-observer-flat-space): the starbow the forward view shows. [higgs-bubble §6](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md#6-the-glow-and-the-plume): the forward glow in the cruise frame, at the value the sim emits.
- Ledger D-14 (boost → cruise → brake, no flip; the 60 fps bar), D-22/D-66 (the approved plan), D-48 (keep the glow as modelled).
- Feature doc: [02-bridge-interior](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/02-bridge-interior.md).

**Depends on:** M4.6gR3 (landed, `658072a`, PR #257: the renders show what G-M4-S2/S3/S4 pin), the live 3D-ship journey and the R1-SHIP-UI consoles (landed). The GPU window on the rig. No package, sim, physics or scene change.
**Estimated LOC:** about 300 (the sprint said ~200; see Contradictions 6): `tools/m4_ship_capture.gd` ~175, `tools/m4_ship_bench.gd` ~95, `Makefile` ~30 (capture-m4 ~10, bench dispatch ~12, capture-m4-publish ~8), changelog fragment ~10.

**No shipped visual changes.** Both drivers live in `tools/`, which the export excludes (`export_presets.cfg:10`, `exclude_filter=…tools/*…`). Nothing under `demos/`, `interior/`, `ui/`, `sky/`, `bridge/`, `sim/`, `physics/`, `assets/` or `main.gd` changes (AC14). S1 signs off reference renders of the ship that is already in the game.

## Game vision alignment

| Pillar | Score | Notes |
|---|---:|---|
| Choices Are Final | 0 | The capture commits through the helm console's own hold-to-commit (`ShipConsoles.use`), as a player does. Nothing about commit changes. |
| The Game Doesn't Judge | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | The clocks are unchanged. The arrival frames show them as the player sees them: α Cen at ship +224.9 d / Earth +4.36 yr; home at ship +449.8 d / Earth +8.73 yr (spike). |
| The Ship Is Home | 0 | Nothing on the bridge changes. Mark sees the bridge, captain eye, at each stage of the first journey. |
| Grounded Strangeness | 0 | No visual change. The starbow and the glow are shown for sign-off, not altered. |
| We Are Not Built For This | 0 | Not relevant. |
| Hard sci-fi authenticity (spec) | +1 | Physics gate 2's third leg (opened reference renders) for the scene the player actually gets, from real sim states, with every frame's sim world recorded. The bench also puts a number on the D-14 60 fps bar in live transit. |
| **Net** | **+1** | **Go.** This is verification work, so neutral pillars are neutral by nature. No pillar is negative. |

## Problem

The 3D ship has no S1 render set and no bench. Evidence at HEAD `13bcc40` (Verification Log V1–V6):
- `make capture-m4` still drives the `--interior` reference mode (`Makefile:187–189`: `-- --interior-capture=renders/m4`). It renders the iso interior, not the ship the player boards. Its only assertion is `test -s renders/m4/contact_sheet.png`: a stale sheet from an earlier run satisfies it, and nothing counts, de-duplicates or blank-checks the frames.
- `make bench` has no `SCENE` switch (`grep -c SCENE Makefile` = 0). It benches the starfield (`tools/bench.gd`), not the bridge. Its recipe also does not fail on a p99 miss (`Makefile:392–393` greps only `^bench: frame ms` and the limiting-magnitude line).
- `tools/m4_ship_capture.gd` and `tools/m4_ship_bench.gd` do not exist. `tools/m4_ship_golden.gd` does.

**The spike shows that AC12 does not hold at HEAD.** See Spike and Contradictions 1. The bridge in live transit runs at **p50 41.5 ms, p99 85.3 ms** at 2560×1440, medium tier, vsync off. The same scene with journey ticks stopped runs at **p50 8.9 ms, p99 15.4 ms**. The bench this doc designs measures that and fails loudly. Making the number pass is a separate performance item. It is not in this doc's scope, and it touches files this item must not.

## Goals and non-goals

**Goals.**
1. `make capture-m4` produces the S1 set aboard the 3D ship from one real sim session (seed 424242), with the captain at the helm. The set has **7 states × 2 views = 14 frames plus a contact sheet = 15 PNGs**, a `manifest.json` of each frame's sim world, `m4_manifest.sha256` and `worlds.sha256`. The recipe fails loudly on a missing, blank, duplicate or stale frame, on a wrong count, on an unreached state, and on a state whose sim values are not what the frame claims.
2. `make bench SCENE=bridge` benches the 3D-ship bridge in live transit: 30 s from commit, 2560×1440, vsync off, medium tier, the default Metal driver. It reports p50/p95/p99 and exits non-zero when p99 ≥ 16.7 ms (AC12) or when the measurement is structurally invalid (zero frames, wrong size, wrong tier, missing phase). The default `make bench` is byte-identical in its dry run (AC9).
3. `make capture-m4-publish` (maintainers, gcloud; standing approval for the public bucket) uploads the verified set to `gs://stapledons-voyage-assets/refs/m4_ship_s1/`. The PR then links the set on issue #1 and parks.

**Non-goals.**
- Making AC12 pass: the live-transit frame cost (Contradictions 1). Proposed as a separate queue row, below.
- Any scene, HUD, sim or shader change. Pans: the 3D ship has one viewport and no pan composite (R3-4 dropped G-M4-1 for the same reason). 0.999c: the α Cen leg cruises at 0.99c, and spec §4's 0.999c render is M1's.
- Pinning the renders as a regression baseline (the `bh-refs` pattern). That is a P-land follow-up once Mark has signed S1 off.
- `make test`/CI: both targets need the GPU window and stay outside `make test`, like `golden`, `capture-bh` and `bench-bh`.
- Removing the interior set. It stays reachable for developers as `godot --path . -- --interior-capture=DIR` (`main.gd:437`, unchanged; R3-1).

## Design

### 1. `tools/m4_ship_capture.gd` (`extends SceneTree`, run by `--script`)

The pattern follows `tools/bh_ship_capture.gd` (scene setup, `_shot`, `_sheet`, `_manifest`) and `tools/ship_demo_live_capture.gd` (a manifest of real sim worlds). The console route follows `tests/m4_playthrough_ship.gd`.

**Scene.**
- `root.size = SIZE`, with `const SIZE := Vector2i(1600, 900)`, the size of the earlier S1 interior set. It fits the rig's window (the window clamps at 2560×1288, V9).
- `demo = load("res://demos/ship_geometry_demo.tscn").instantiate()`, with `setup_options = {"size": SIZE, "sky_state": "rest", "seed": 424242, "ai": false, "tier": "medium"}`. Stars and the background are on by default. The medium tier makes the set the same on every machine (the default would be `large` wherever `make starmap-assets` has run, `sky/starfield.gd:139–143`). Crew is the default (`consent`), as in play.
- After one `process_frame`: `demo.auto = false`, `demo.journey_auto_tick = false`. Then assert:
  - `demo.ready_ok`;
  - `demo.sky.has_background` (else FAIL "no sky panorama: make sky-assets");
  - `demo.sky.starfield.count >= 60000` (spike: 60,883);
  - `Starfield.last_loaded.tier == "medium"`.
- First, remove `renders/m4/*.png`, `manifest.json`, `m4_manifest.sha256` and `worlds.sha256`, so that a stale frame can never count (drill DC5).

**Route.** These are the player's own controls. There is no decision key and no `sky_states` snapshot.
1. `demo.consoles.walk_to("navigation")`, then `await process_frame` until `consoles.walking.is_empty()`, at most 600 frames. The spike reached the helm at (-6.316, 82, 5.219).
2. Shoot **01 docked**.
3. `consoles.use("navigation","open")`, `use("navigation","select","CNS5:3627")` and `use("navigation","commit")`. Each must return true, else FAIL. `commit` is the map's own hold (`demos/ship_consoles.gd:338–343`).
4. **Tick loop.** At most 4000 ticks per leg (spike: 1202 and 1226). Each tick runs `demo.journey_tick()` and then `demo._process(1.0 / GalaxyMap.TICK_HZ)`.
   - The `_process` call ages the HUD cards in sim time, as `tests/m4_playthrough_ship.gd` `step()` does. Without it the spike's arrival frame stacked four stale cards (Contradictions 5).
   - The loop is synchronous, so every shot lands on a deterministic tick.
   - Every predicate is checked **independently** on every tick, and each state fires once, on the first tick that meets it. A missed state therefore never hides the later ones (DC3 counts exactly one FAIL). The states table is pinned as these lines:
  ```
  const STATES := [
  	{"id": "boost_b05", "phase": "boosting", "beta_min": 0.5},
  	{"id": "boost_b09", "phase": "boosting", "beta_min": 0.9},
  	{"id": "cruise_099", "phase": "cruising"},
  	{"id": "brake_b05", "phase": "braking", "beta_max": 0.5},
  ]
  ```
  Arrival is `journey.state == "arrived"` with no live journey. A state still unfired at arrival prints `capture-m4: FAIL state <id> not reached`.
5. Shoot **06 arrived α Cen** with the arrival card up, then `demo.dismiss_arrival()`.
6. Walk back to the helm, then `use("navigation","open")`, `use("navigation","home")` and **`demo.journey_tick()`**, then `use("navigation","commit")`. The tick is needed: without it the spike's home commit returned false (Contradictions 5). Run the tick loop with only the arrival predicate.
7. Shoot **07 arrived home**.

**States and their asserts.** All values are read from `demo.journey_sim.world`, never computed:

| n | state | predicate | asserted at the shot | spike value |
|---|---|---|---|---|
| 01 | `docked` | before commit | phase `at_rest`, β 0, `glow_pole_w_m2` 0 | 0 / 0 |
| 02 | `boost_b05` | boosting, β ≥ 0.5 | β < 0.51 | β 0.50485233064678 |
| 03 | `boost_b09` | boosting, β ≥ 0.9 | β < 0.91 | β 0.90062310692356 |
| 04 | `cruise_099` | cruising (first tick) | β == 0.99, glow pole > 0, `sky_state == "live"` | β 0.99, pole 3.347105462e-5 W/m² |
| 05 | `brake_b05` | braking, β ≤ 0.5 | β > 0.49 | β 0.49990566742733 |
| 06 | `arrived_acen` | arrived | target `CNS5:3627`, β 0, pole 0 | 1202 ticks |
| 07 | `arrived_home` | arrived | target `Sol`, β 0, pole 0 | 1226 ticks |

**Views (captain eye; pullback 0).** Each state is shot twice:
- `const DECK := [30.0, 0.47] # tilt deg, yaw rad`: the bridge preset's yaw, with the deck rail and the sky (spike frame `docked_a`, opened).
- `const FORWARD := [89.99, 0.0] # tilt deg, yaw rad: the travel pole`: G-M4-S3's pose (`tools/m4_ship_golden.gd`; off the exact zenith, as `tests/m4_playthrough_ship.gd:236`). This is the starbow and glow view.

The HUD stays visible, as the player sees it. Before each shot: `demo.camera.follow(demo.avatar_pos, tilt, yaw, 0.0)` and `demo._sync_observer()`, then 6 `process_frame`s and `RenderingServer.frame_post_draw`, then the pinned read line `\tvar img := root.get_texture().get_image()`. The spike took 0.19–1.06 s per shot.

**File names.** Pinned line: `\tvar path := "%s/%02d_%s_%s.png" % [OUT, n, state, view]`, where `n` is the **state** number. That gives, for example, `04_cruise_099_forward.png`. The sheet is `contact_sheet.png`: 2 rows (deck, forward) × 7 columns, with 320×180 thumbnails and 6 px gaps (2276×366).

**Frame checks** (after saving):
- **Blank:** sample a 64 × 36 grid of the saved PNG (re-loaded from disk). Require lit fraction (Rec.709 luminance > 8/255) ≥ 0.10 **and** ≥ 32 distinct 8-bit luminance levels. Otherwise print `capture-m4: FAIL blank <file> lit %.3f levels %d`. Spike, over 9 real frames: lit 0.450–0.887, levels 128–200. Black: 0.000 and 1. Flat grey: 1.000 and 1. Both controls are rejected (V12).
- **Duplicate:** at the end, `FileAccess.get_sha256` of the file at each of the 14 **recorded shot paths**, in shot order. This is the list, not a directory listing, so an overwritten file shows up as a pair. Each pair with equal hashes prints `capture-m4: FAIL duplicate <a> = <b>`, with `a` the earlier shot. The rule is real: the same state and pose rendered three times gave three byte-identical files (V13), so a pose or state that fails to change is caught.
- **Pass:** each good frame prints `capture-m4: ok frame <file> lit %.3f levels %d phase %s beta %s glow_pole_w_m2 %s`. There are 14 of these.

**Outputs** in `renders/m4/` (git-ignored, `.gitignore:2`):
- 15 PNGs;
- `manifest.json`: per frame, file, state, view, tilt, yaw, tick, `eye_m` (`demo.camera.ship_vector(demo.camera.position)`), the sim fields `ship.{phase, beta, gamma, one_minus_beta, ism.glow_pole_w_m2, ism.glow_pole_k}`, `journey.state`, `journey.plan.target.id` and `clock`, plus `world_sha256`; the top level records seed, tier, size, adapter, the AILANG hello and the run's wall time;
- `m4_manifest.sha256`: 15 lines, `sha  name.png`, sorted;
- `worlds.sha256`: 14 lines, the sha256 of `SimBridge.encode(world)` per frame, the determinism check of AC4.

The last lines are `capture-m4: %d renders in %.1f s to <dir>` and then `capture-m4: OK` if and only if there were no failures, else `capture-m4: FAIL`. The exit code is `1 if failures else 0`.

### 2. `tools/m4_ship_bench.gd` (`extends SceneTree`)

The pattern follows `tools/bh_ship_bench.gd` (statistics, measured render time) and `tools/bench.gd:41–48` (the content-scale trick for a window the screen clamps).

**Pinned lines:**
```
const SIZE := Vector2i(2560, 1440)
const BENCH_S := 30.0
const P99_TARGET_MS := 16.7
const MIN_FRAMES := 300   # 10 fps over 30 s; the spike measured 821
```
In `_run`, in this order:
- `root.size = SIZE`
- `root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT`
- `root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP`
- the pinned line `\troot.content_scale_size = SIZE`
- `DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)`
- `Engine.max_fps = 0`

The tier is `--tier=` from the recipe (default medium).

**Run.**
1. Build the demo exactly as the capture does: `setup_options = {"size": SIZE, "sky_state": "rest", "seed": 424242, "ai": false, "tier": tier}`.
2. **Docked control** (no journey yet): captain eye at `DECK`, 120 warm-up frames, then 300 measured frames. Printed, never gated. Spike: p50 8.5–9.0, p99 14.5–18.9 over 6 runs.
3. Walk to the helm and commit to `CNS5:3627` by the console route. Call `demo.journey_tick()` once (the departure) and wait 30 frames. Captain eye at `DECK`.
4. `demo.journey_auto_tick = true`. This is the live game's own 20 Hz pipelined heartbeat (`demos/ship_geometry_demo.gd` `_process`, `SimBridge.pipelined`); nothing is faked.
5. 120 warm-up frames, then **measure for `BENCH_S` seconds of wall time**: the wall ms between `process_frame`s, the phase at each frame, and the `SimBridge.send_ms_total` delta (the sim wait). Turn on `viewport_set_measure_render_time` for `demo.sky` and `demo.geometry_view`. Metal reports 0 GPU time (V10, as `tools/bench.gd:12` notes), so GPU ms is printed as "n/a on Metal".

**Structural asserts.** Each prints `bench-bridge: FAIL <what>`:
- the frame count is at least `MIN_FRAMES` (`FAIL measured %d frames (want >= 300)`);
- `get_visible_rect().size` equals `SIZE`, printed as one line `FAIL viewport %dx%d (want 2560x1440)`; `demo.geometry_view.size` and `demo.sky.size` also equal `SIZE` (`FAIL subviewport …`);
- the verdict line prints the driver's own `P99_TARGET_MS` (`target p99 < %s: ok|MISS`);
- vsync reads back disabled;
- the tier is the one asked for;
- the journey is `committed` at the start;
- at least 1 frame each in `boosting` and `cruising` (spike: 446 and 375);
- no `SCRIPT ERROR`.

**Lines:**
```
bench-bridge: <adapter>, <method>, viewport 2560x1440 (window WxH), tier medium, N stars, background true, vsync off, host load …
bench-bridge: docked control 300 frames p50 %.2f p95 %.2f p99 %.2f ms (no journey ticks; not gated)
bench-bridge: live transit %d frames in %.1f s (boosting %d, cruising %d), end beta %.4f, sim wait p50 %.2f ms/frame
bench-bridge: frame ms p50 %.3f  p95 %.3f  p99 %.3f  max %.2f; %d of %d frames over 16.7 ms (target p99 < 16.7: ok|MISS)
bench-bridge: OK            (structure valid; printed only when every structural assert passed)
```
It also writes `.godot/tmp/bench-bridge.json` with the frame times, phases and hardware. Percentiles use the nearest-rank rule of `demos/ship_demo_benchmark.gd` `summarize` (`sorted[ceil(n·p) − 1]`).

**Exit:** 1 on any structural FAIL, 2 on a valid run with p99 MISS, 0 on a valid run with p99 ok.

### 3. Makefile

**`capture-m4`.** This replaces `Makefile:187–189`. The help text names the 3D-ship set and that `--interior-capture=DIR` keeps the old one.
```
capture-m4: sky-assets lens-assets ## M4.6rR3 S1 set aboard the 3D ship (GPU window): captain eye at the helm; docked, boost 0.5/0.9, cruise 0.99 with the glow, brake 0.5, arrived alpha Cen, arrived home; deck + forward views + contact sheet -> renders/m4/ (manifest.json, m4_manifest.sha256, worlds.sha256). The interior set: godot --path . -- --interior-capture=DIR
	@mkdir -p $(SCRATCH); $(GODOT_SIM) --path . --script tools/m4_ship_capture.gd > $(SCRATCH)/capture-m4.log 2>&1; rc=$$?; grep '^capture-m4' $(SCRATCH)/capture-m4.log; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/capture-m4.log && grep -q '^capture-m4: OK$$' $(SCRATCH)/capture-m4.log && \
	  test "$$(grep -c '^capture-m4: ok frame' $(SCRATCH)/capture-m4.log)" = 14 && \
	  test "$$(ls renders/m4/*.png | wc -l | tr -d ' ')" = 15 && test "$$(wc -l < renders/m4/m4_manifest.sha256 | tr -d ' ')" = 15 && \
	  test "$$(cut -d' ' -f1 renders/m4/m4_manifest.sha256 | sort -u | wc -l | tr -d ' ')" = 15 && test "$$(wc -l < renders/m4/worlds.sha256 | tr -d ' ')" = 14 && \
	  (cd renders/m4 && shasum -a 256 -c m4_manifest.sha256 > /dev/null) || { echo "capture-m4: FAILED (log $(SCRATCH)/capture-m4.log)"; exit 1; }
```
- `sky-assets` takes 3 s when the textures are present (V8). It makes "on the approved panorama" fail-closed.
- The Metal `ERROR: timeout waiting for fence` lines seen at exit in one spike run are not `SCRIPT ERROR`s and do not fail the recipe (Risks).

**`bench`.** The existing two recipe lines (`Makefile:390–393`) move verbatim into the `else` branch:
```
BRIDGE_TIER = $(if $(filter command line environment,$(origin TIER)),$(TIER),medium)
bench: lens-assets  ## <existing text>; SCENE=bridge: M4.6rR3 AC12, the 3D-ship bridge in live transit (30 s from commit, 2560x1440, vsync off, medium tier, Metal), p99 < 16.7 ms or exit 1
ifeq ($(SCENE),bridge)
	@mkdir -p $(SCRATCH); echo "bench-bridge: host load $$(uptime | sed 's/.*load/load/')"; \
	  $(GODOT_SIM) --path . --script tools/m4_ship_bench.gd -- --tier=$(BRIDGE_TIER) > $(SCRATCH)/bench-bridge.log 2>&1; rc=$$?; grep '^bench-bridge' $(SCRATCH)/bench-bridge.log; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/bench-bridge.log && grep -q '^bench-bridge: OK$$' $(SCRATCH)/bench-bridge.log && \
	  grep -q '^bench-bridge: frame ms .*(target p99 < [0-9.]*: ok)$$' $(SCRATCH)/bench-bridge.log || { echo "bench-bridge: FAILED (exit $$rc: 1 = invalid measurement, 2 = p99 MISS; log $(SCRATCH)/bench-bridge.log)"; exit 1; }
else ifneq ($(SCENE),)
	@echo "bench: unknown SCENE=$(SCENE) (want SCENE=bridge, or none for the starfield bench)"; exit 2
else
	<the existing recipe lines, unchanged>
endif
```
This was dry-run at base on GNU Make 3.81 in a temp copy (V11):
- the default `make -n -o lens-assets bench` output was byte-identical (sha256 `2bd542c8…a465` before and after);
- `SCENE=nope` printed the message and exited 2;
- `SCENE=bridge` selected the bridge branch.

**`capture-m4-publish`.** Maintainers only, gcloud. It mirrors `bh-refs-publish` (`Makefile:413–415`):
- First, every line of `renders/m4/m4_manifest.sha256` must verify (`shasum -a 256 -c`).
- Then it runs `gcloud storage cp --cache-control="public, max-age=300"` on each PNG, `manifest.json`, `m4_manifest.sha256` and `worlds.sha256`, to `gs://stapledons-voyage-assets/refs/m4_ship_s1/`, and prints `capture-m4-publish: uploaded N files`.

### 4. The S1 hand-off (executor, after AC1–AC13 pass)

1. Run `make capture-m4` on the branch. **Open every PNG** (gate 2): the 14 frames and the sheet.
2. Run `make capture-m4-publish`, and confirm the public copies with AC6.
3. Post the sheet and the 14 public URLs to issue #1 with the bench line (MISS at HEAD, Contradictions 1) and a `publish-dev` review build (RB, non-blocking, D-16).
4. **Park** the PR, unmerged, for S1. AC11's `grep "S1 sign-off"` lands at P-land, not here.

## Acceptance criteria

Every mutation runs in a **temp copy** made by the drill wrapper, never in the working tree. The hardened shape:
- an explicit ROOT;
- a cleanup `trap` immediately after `mktemp`;
- `cmp` proof that the mutation changed the file (else exit 3);
- make's rc passed through;
- the count asserted with `test`.

Write the wrapper once:

```sh
cat > /tmp/m46r_drill.sh <<'EOF'
set -u
# usage: bash /tmp/m46r_drill.sh ROOT 'TARGET' FILE PERL LOG PAT WANT_N MODE [PRE]
#   ROOT   the checkout to copy (explicit, never inferred)
#   FILE   '' = no mutation (a control)    MODE  fail = make must exit non-zero; pass = make must exit 0
#   LOG    log path inside the copy        PAT   grep pattern counted in LOG; WANT_N = the count, asserted with test
#   PRE    optional shell run inside the copy before make (e.g. seeding stale frames)
# exit: 0 the drill behaved as stated; 1 it did not; 2 bad ROOT or PRE; 3 the mutation did not change FILE
R=$1; TGT=$2; F=$3; P=$4; LOG=$5; PAT=$6; WANT=$7; MODE=$8; PRE=${9:-}
[ -d "$R/.git" ] || { echo "drill: ROOT $R is not a checkout"; exit 2; }
T=$(mktemp -d /tmp/m46r.XXXXXX); trap 'rm -rf "$T"' EXIT
rsync -a --exclude .git --exclude .godot/tmp --exclude renders --exclude .scratch "$R"/ "$T"/
if [ -n "$F" ]; then
  cp "$T/$F" "$T/.drill.orig"; perl -i -pe "$P" "$T/$F"
  if cmp -s "$T/$F" "$T/.drill.orig"; then echo "drill: mutation did not change $F"; exit 3; fi
fi
[ -z "$PRE" ] || (cd "$T" && sh -c "$PRE") || { echo "drill: PRE failed"; exit 2; }
rc=0; (cd "$T" && perl -e 'alarm 900; exec @ARGV' make $TGT AILANG=runtime/bin/ailang > drill.out 2>&1) || rc=$?
n=$(grep -c -- "$PAT" "$T/$LOG" 2>/dev/null); n=${n:-0}
echo "drill rc=$rc count=$n want=$WANT mode=$MODE"
if [ "$MODE" = pass ]; then test "$rc" = 0; else test "$rc" != 0; fi && test "$n" = "$WANT"
EOF
R=$(git rev-parse --show-toplevel)   # set once, passed explicitly to every drill
```

**Wrapper dry-run at base `13bcc40`** (V14), on the cheap `m4-physics-probe` target:
- control, want 12: `drill rc=0 count=12 want=12 mode=pass`, exit 0;
- control, wrong want 9: exit 1 (the `test` bites);
- the Makefile `diff` → `false && diff` mutant: `drill rc=2 count=12 want=12 mode=fail`, exit 0;
- a no-op mutation: `drill: mutation did not change Makefile`, exit 3;
- a bad ROOT: exit 2;
- no `/tmp/m46r.*` left behind.

The new-file drill expressions (DC1–DC5, DB1–DB3) were dry-run on a fixture holding the pinned lines exactly as written in Design §1–§2. Each changed it (`cmp` differs); the no-op `s/NO_SUCH_TEXT/x/` did not (V15). **The executor must write the pinned lines verbatim.** A drill that exits 3 means a pinned line drifted.

| # | Criterion | Command → expected (rc / asserted count) |
|---|---|---|
| AC1 | The S1 set: 15 PNGs, 14 `ok frame` lines, unique hashes, manifests verify | `make capture-m4 AILANG=runtime/bin/ailang && test "$(grep -c '^capture-m4: ok frame' .godot/tmp/capture-m4.log)" = 14 && test "$(ls renders/m4/*.png \| wc -l \| tr -d ' ')" = 15` → exit 0 |
| AC2 | Every state reached with the sim's own values; the cruise frame carries the glow | `test "$(grep -cE '^capture-m4: ok frame 0[1-7]_[a-z0-9_]+_(deck\|forward)\.png' .godot/tmp/capture-m4.log)" = 14 && test "$(grep -c '^capture-m4: ok frame 04_cruise_099_.* phase cruising beta 0.99 ' .godot/tmp/capture-m4.log)" = 2 && test "$(grep -cE '^capture-m4: ok frame 0[167]_.* glow_pole_w_m2 0(\.0)?$' .godot/tmp/capture-m4.log)" = 6` → exit 0 |
| AC3 | The manifest records real sim worlds for every frame | `test "$(grep -o '"world_sha256"' renders/m4/manifest.json \| wc -l \| tr -d ' ')" = 14 && test "$(grep -c '"CNS5:3627"' renders/m4/manifest.json)" -ge 1` → exit 0 |
| AC4 | Determinism: a second run reaches byte-identical sim worlds at every shot | `cp renders/m4/worlds.sha256 /tmp/m46r_w1 && make capture-m4 AILANG=runtime/bin/ailang && cmp /tmp/m46r_w1 renders/m4/worlds.sha256` → exit 0 |
| AC5 | Opened and looked at (gate 2), for the record | `test "$(grep -c '^| renders/m4/' design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md)" = 15`: the executor's short report lists each PNG with one line on what it shows |
| AC6 | Uploaded and publicly fetchable, byte-equal | `make capture-m4-publish && n=0; while read -r s f; do test "$(curl -fsSL "https://storage.googleapis.com/stapledons-voyage-assets/refs/m4_ship_s1/$f" \| shasum -a 256 \| cut -d' ' -f1)" = "$s" && n=$((n+1)); done < renders/m4/m4_manifest.sha256; test "$n" = 15` → exit 0 |
| AC7 | The bench measures validly; its verdict decides its rc | `make bench SCENE=bridge AILANG=runtime/bin/ailang; rc=$?; L=.godot/tmp/bench-bridge.log; test "$(grep -c '^bench-bridge: OK$' $L)" = 1 && test "$(grep -c '^bench-bridge: FAIL' $L)" = 0 && if grep -q 'target p99 < 16.7: ok)$' $L; then test $rc = 0; else test "$(grep -c 'target p99 < 16.7: MISS)$' $L)" = 1 && test $rc != 0; fi` → exit 0 (at HEAD: the MISS branch, Contradictions 1) |
| AC8 | AC12 itself (P-land condition, **expected red until the perf row lands**) | `make bench SCENE=bridge AILANG=runtime/bin/ailang` → exit 0. Recorded, not required for this item's merge (R3-8 puts AC12 at P-land) |
| AC9 | The default `make bench` is unchanged; an unknown SCENE fails | `T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; git show origin/main:Makefile > "$T/M"; test "$(make -f "$T/M" -n -o lens-assets bench AILANG=runtime/bin/ailang \| shasum -a 256)" = "$(make -n -o lens-assets bench AILANG=runtime/bin/ailang \| shasum -a 256)" && ! make -o lens-assets bench SCENE=nope` → exit 0 |
| AC10 | Capture drills, each killed (wrapper exit 0) | **DC1 blank**: `bash /tmp/m46r_drill.sh "$R" capture-m4 tools/m4_ship_capture.gd 's/^\tvar img := root\.get_texture\(\)\.get_image\(\)$/\tvar img := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)/' .godot/tmp/capture-m4.log '^capture-m4: FAIL blank' 14 fail` · **DC2 duplicate (the forward view does not move)**: `… 's/^const FORWARD := \[89\.99, 0\.0\]/const FORWARD := DECK/' … '^capture-m4: FAIL duplicate 01_docked_deck.png = 01_docked_forward.png$' 1 fail` (the docked pair is the static case V13 proved byte-identical; transit pairs may differ by a card's fade, so they are not counted) · **DC3 state never reached**: `… 's/"beta_min": 0\.9\}/"beta_min": 1.5}/' … '^capture-m4: FAIL state boost_b09' 1 fail` · **DC4 wrong count (views overwrite)**: `… 's/%02d_%s_%s\.png" % \[OUT, n, state, view\]/%02d_%s.png" % [OUT, n, state]/' … '^capture-m4: FAIL duplicate' 7 fail` · each → exit 0 |
| AC11 | Stale frames cannot pass: 15 seeded PNGs plus a matching manifest, and a driver that quits before shooting | `bash /tmp/m46r_drill.sh "$R" capture-m4 tools/m4_ship_capture.gd 's/^(func _run\(\) -> void:)$/$1\n\tquit(0)\n\treturn/' .godot/tmp/capture-m4.log '^capture-m4: OK$' 0 fail 'mkdir -p renders/m4 && for i in $(seq -w 1 15); do echo $i > renders/m4/s$i.png; done && (cd renders/m4 && shasum -a 256 *.png > m4_manifest.sha256)'` → exit 0 |
| AC12 | Bench drills (DB1, DB2 killed; DB3 is the green control) | **DB1 zero frames**: `bash /tmp/m46r_drill.sh "$R" 'bench SCENE=bridge' tools/m4_ship_bench.gd 's/^const BENCH_S := 30\.0$/const BENCH_S := 0.0/' .godot/tmp/bench-bridge.log '^bench-bridge: FAIL measured 0 frames' 1 fail` · **DB2 half-size viewport**: `… 's/^\troot\.content_scale_size = SIZE$/\troot.content_scale_size = SIZE \/ 2/' … '^bench-bridge: FAIL viewport 1280x720' 1 fail` · **DB3 control, the recipe goes green when the verdict is ok**: `… 's/^const P99_TARGET_MS := 16\.7$/const P99_TARGET_MS := 1000.0/' … 'target p99 < 1000.0: ok)$' 1 pass` (the recipe matches `target p99 < [0-9.]*: ok`, so it needs no PRE; the driver prints its own constant) · each → exit 0 |
| AC13 | Every mutation applies (no silent no-op) | `bash /tmp/m46r_drill.sh "$R" capture-m4 tools/m4_ship_capture.gd 's/NO_SUCH_TEXT/x/' x y 0 fail; test $? = 3` → exit 0 |
| AC14 | No shipped or production change | `test "$(git diff --name-only origin/main -- demos interior ui sky bridge sim physics assets data main.gd export_presets.cfg \| wc -l \| tr -d ' ')" = 0` → exit 0 |
| AC15 | The suite, the goldens and the guards stay green | `make test AILANG=runtime/bin/ailang && make golden AILANG=runtime/bin/ailang && make lint-precision python-guard` → exit 0 (no new `*.py`; `golden` still 373 ok) |

AC5 is the one "opened and looked at" record. It counts the 15 rows of a file the executor writes after opening each PNG, so a missing look is a missing row.

## Spike (measured on the rig, 2026-10-16, base `13bcc40`)

**Setup.** The spike ran from this unattended session, which has the GPU window: Apple M4 Max, Metal 4.0, Forward+, Godot 4.7.2.
- Prep: `make sky-assets` rc 0 in 3 s; `make lens-assets` rc 0 in 1 s; `godot --headless --import` rc 0 in 2 s, under a 600 s alarm.
- The spike scripts were throwaway, under `.scratch/`, and are deleted. The core of each is condensed into Design §1–§2.
- Host load averaged 5.0–5.9 throughout. Other agents' `ailang` processes were at 75–117 % CPU.

**Capture** (1600×900, medium tier, 60,883 stars, background on, the console route above):
- The demo was ready in 3.1–5.9 s. The α Cen leg took 1202 ticks and the home leg 1226.
- 2430 ticks took 104.8 s, 43 ms per tick including `demo._process`. Shots took 0.19–1.06 s each (one 4.46 s).
- In-script total 149.7 s. Wall time was 245 s (run 2, with 2 Metal `timeout waiting for fence` errors at exit) and 189 s (run 1).
- PNGs are **0.88–2.33 MB** each: 9 frames come to 16.16 MB, so 14 frames are about 25 MB. The contact sheet's size is UNMEASURED.
- I opened `docked_a` (deck rail, Milky Way), `acenb05` (boost 0.5049c), `acencr` and the forward view (the cruise starbow concentrated at the pole), `arrived_acen` (the arrival card, α Cen A as a disc at 0.059 AU) and `arrived_home` (Near Earth, 24,642 km).
- The tilt-55°/45° deck views are dominated by a pillar at the helm. Hence the 30°, yaw-0.47 deck pose.

**Bench** (2560×1440 through content scale; the window itself clamps at 2560×1288; vsync off; medium tier; Metal):

| measurement | frames | p50 | p95 | p99 | max (ms) |
|---|---:|---:|---:|---:|---:|
| **live transit, 30 s from commit** (run 1) | 821 | **41.45** | 50.61 | **85.32** | 122.28 |
| of which boosting / cruising | 446 / 375 | 41.28 / 42.36 | 49.66 / 72.77 | 52.94 / 107.13 | |
| live transit, 15 s, crew default (runs 2–3) | 420 / 392 | 40.58 / 44.38 | 51.36 / 52.50 | 83.64 / 78.76 | |
| docked control, no journey (6 runs) | 300 each | 8.47–9.01 | 13.0–13.5 | 14.51–18.89 | |
| same transit scene, ticks stopped (4 quiet runs) | 300 each | 8.64–8.86 | 13.8–14.0 | 15.25–15.43 | |

**Where the transit cost is not.** Each item below was isolated in the same run:
- **Not the sim wait:** the `SimBridge.send_ms_total` delta is p50 0.72–0.85 ms per frame.
- **Not the sky renderer:** `sky.apply(world)` alone gives a next frame of p50 6.3 ms.
- **Not the tick's own GDScript:** pipelined `journey_map.tick()` p50 1.6 ms plus `_apply_journey_world()` p50 1.6 ms.
- **Not `GalaxyMap._process`:** turning it off left the next frame at p50 61 ms on a noisy run.

The frame **after** a `journey_map.tick()` costs p50 45.8 ms even with no sky apply. The source is **UNMEASURED** beyond that. Synchronous `journey_tick()` is p50 31.4 ms.

## Verification Log

Every claim above about what HEAD does. The base is `13bcc40` in `/Users/voightkampff/dev/sunholo-data/.stapledon-loop-iter36`.

| # | Claim | Command | Observed |
|---|---|---|---|
| V1 | `capture-m4` drives `--interior` and asserts only the sheet | `sed -n 187,189p Makefile` | `$(GODOT_SIM) --path . -- --interior-capture=renders/m4` / `test -s renders/m4/contact_sheet.png` |
| V2 | No `SCENE` in the Makefile (positive control in the same command) | `echo "SCENE $(grep -c SCENE Makefile) / BENCH_TIER $(grep -c BENCH_TIER Makefile)"` | `SCENE in Makefile: 0 / BENCH_TIER: 2` |
| V3 | The new drivers are absent; the golden driver is present | `ls tools/m4_ship_capture.gd tools/m4_ship_bench.gd tools/m4_ship_golden.gd` | two `No such file or directory`, then `tools/m4_ship_golden.gd` |
| V4 | The default bench does not fail on a p99 miss | `sed -n 389,393p Makefile` | the recipe greps `'^bench: frame ms'` and `'limiting magnitude .*: ok$$'` only |
| V5 | M4.6gR3 landed; golden expects 373 ok | `git log --oneline -8 -- tools/m4_ship_golden.gd Makefile`; `grep -n '= 373' Makefile` | `658072a M4.6gR3: ship goldens …`; `373:… = 373 && \` |
| V6 | Nothing else calls `capture-m4` or `SCENE=bridge` outside docs/state | `git grep -n "capture-m4\|SCENE=bridge" -- ':!design_docs'` | only `.ailang/state/{evaluations,sprints}` JSON text (no Makefile, CI or test caller) |
| V7 | `renders/` is ignored; `tools/*` is not exported | `git check-ignore -v renders/m4/x.png`; `grep -n exclude_filter export_presets.cfg` | `.gitignore:2:renders/`; `10:exclude_filter="…renders/*,…tools/*,spike/*"` |
| V8 | Sky and lens assets fetch fast; a fresh clone imports | `make sky-assets`; `make lens-assets`; `perl -e 'alarm 600; exec @ARGV' godot --headless --path . --import` | `sky rc=0 3s` (`sky-verify: textures match data/sky/SHA256SUMS`), `lens rc=0 1s`, `import rc=0 2s` |
| V9 | The window clamps; content scale gives 2560×1440 | the bench spike's first line | `viewport (2560.0, 1440.0), geometry (2560, 1440), sky (2560, 1440), 60883 stars (tier medium), window (2560, 1288)` |
| V10 | Metal reports no GPU render time (control: the wall time is non-zero) | bench spike: `viewport_get_measured_render_time_gpu` on sky + ship | `gpu p50 0.000` next to `all 821 frames p50 41.45` |
| V11 | The bench dispatch keeps the default dry run identical, rejects unknown SCENE, selects bridge | the temp-copy Makefile edit, `make -f "$T/Makefile.new" -n -o lens-assets bench` vs `make -n -o lens-assets bench`; `SCENE=nope`; `SCENE=bridge -n` | `default bench dry-run identical: 2bd542c8…a465`; `bench: unknown SCENE=nope …`, `nope rc=2`; `echo "bench-bridge: placeholder recipe"` |
| V12 | The blank rule separates real frames from black and grey | `godot --headless --script .scratch/spike_stats.gd -- .scratch/m4` | real frames: lit 0.450–0.887, levels 128–200; `<black> lit 0.000 levels 1`; `<grey> lit 1.000 levels 1` |
| V13 | The same state and pose render byte-identically (the duplicate rule is sound) | spike: 3 captures at rest, tilt 30, yaw 0.47 | `sha ["12f9343f9a84", "12f9343f9a84", "12f9343f9a84"]` |
| V14 | The drill wrapper works (control, wrong count, kill, no-op, bad ROOT, cleanup) | `bash /tmp/m46r_drill.sh $R m4-physics-probe …` (6 runs) | exits 0 / 1 / 0 / 3 / 2; `ls /tmp \| grep -c '^m46r\.'` → `0` |
| V15 | Every DC/DB perl expression changes its pinned line; a no-op does not | `try` over a fixture of the pinned lines with `cmp` | 8 × `changed: …`; `UNCHANGED: s/NO_SUCH_TEXT/x/` |
| V16 | The live glow is on in the ship | `grep -n 'ForwardGlow.pole_of' demos/ship_geometry_demo.gd` | `291: … else ForwardGlow.pole_of(sky_world)` |
| V17 | The helm preselects α Cen A | `grep -n '"CNS5:3627"' demos/ship_geometry_demo.gd` | `643: var acen:=journey_map.index_of("CNS5:3627")` |
| V18 | The home commit needs a tick after `home` (control: the α Cen commit with no tick) | capture spike runs 1 and 2 | run 1: `open true home true commit false` (and `select true` / `commit true` for α Cen); run 2 with `journey_tick()`: `open true home true commit true`, `home arrived after 1226 ticks; target Sol` |
| V19 | Without `_process` the HUD cards do not age (control: with it) | spike run 1 `arrived_acen.png` opened vs run 2's `arrived_home.png` | run 1: Arrived + Braking + Medium boundary + New in the Archive + Transit stacked; run 2: Arrived only |
| V20 | The live cruise glow differs from HB-102 | capture spike `acencr`; `grep -n HB-102 ../stapledons-design/physics/higgs-bubble.md` | `beta 0.99 glow 0.00003347105462` with HUD "Local Interstellar Cloud 0.2474 cm⁻³"; `HB-102 … 9.63 × 10⁻⁶` |
| V21 | Live transit misses AC12; the stopped scene does not | bench spike runs 1–7 | the Spike table (p99 85.32 live vs 15.25–15.43 ticks stopped) |
| V22 | `make` is GNU 3.81 (`else ifneq` supported) | `make --version \| head -1` | `GNU Make 3.81` |

## Sub-milestones and estimates

One step, test-first:
1. Write the `capture-m4` and `bench` recipes with their count asserts, and the AC9 check. Red: no drivers.
2. Write `tools/m4_ship_capture.gd` (about 175 LOC) and get AC1–AC4 green. One capture run takes about 4 minutes of wall time.
3. Write `tools/m4_ship_bench.gd` (about 95 LOC) and run AC7. It shows a MISS at HEAD, and AC8 is recorded red.
4. Run AC10–AC13. There are 9 drills at about 4 minutes each for capture and about 1.5 minutes for bench, roughly 35 minutes in all.
5. Do AC5 (open every frame), AC6 (publish), the S1 post on issue #1, a review build, and park.

The total is about 300 LOC and roughly one loop day.

## Risks and mitigations

- **Host load moves the docked control's p99 across 16.7 ms.** It measured 14.51–18.89 at load 5–6. AC8 is a P-land measurement: take it on a quiet rig, and print the host load on the bench's first line. The gated live-transit number misses by 5× either way.
- **Metal fence timeouts at exit.** One capture run printed 2 `ERROR: timeout waiting for fence` lines and took 95 s longer of wall time. They are not script errors. The recipe keys on rc, `SCRIPT ERROR` and the driver's own lines, and the drill alarm is 900 s.
- **The PNGs are GPU output.** Byte-identity holds within one process (V13). Across runs, across machines or across a Godot bump it is not claimed, so AC4 pins the sim worlds, not the pixels. A pixel baseline is P-land's `bh-refs`-style follow-up.
- **The crew skip cost (#1827).** The capture runs the default consent crew, as play does. Ticks measured 43 ms each, with no hold stops on this route. A future crew hold mid-leg would stall the tick loop. The 4000-tick bound fails it loudly ("state … not reached"), never silently.
- **Shared files with held PRs.** The Do-not-touch line (charter, refreshed 2026-10-15) holds #243 (`Makefile` `crew-perf`), #242 and #246. The `capture-m4`/`bench` hunks do not overlap `crew-perf`. Re-read `git log HEAD..origin/main` before merging (iteration-30 retro).

## Proposed queue row (for the controller's triage; not a question for Mark)

**M4.6pR3: live-transit frame cost.** In live transit the bridge runs at p50 41 ms against 8.9 ms with ticks stopped. The cost lands in the frame after `GalaxyMap.tick()`. It is not in the sim wait, the sky renderer or `GalaxyMap._process`. The row should:
1. profile that frame with the Godot profiler, headless-verifiable via `make bench SCENE=bridge`;
2. fix it;
3. turn AC8 green.

It probably touches `demos/ship_geometry_demo.gd`, `ui/galaxy_map.gd` or `bridge/sim_bridge.gd`. Those files were authored by attended R1-SHIP-UI (R3-6), so route it as the charter's routing rules say. It blocks P-land (AC12), not this item's S1 park.

## Open questions

None. The render set, the views, the bench conditions and the S1 park are all inside the approved plan (D-22, D-66, R3-4, R3-8). The AC12 miss is a measured fact for P-land, handled by the proposed queue row. It is not a choice this item makes.

## Contradictions with the sprint plan (found at HEAD)

1. **AC12 cannot pass at HEAD.** The sprint expects `make bench SCENE=bridge` to show p99 < 16.7 ms. The measured live-transit p99 is 78.8–94.2 ms (p50 40.4–44.9) at 2560×1440, medium tier, vsync off, on the M4 Max. The same scene with ticks stopped is p99 15.25–15.43. This item builds the bench, which fails loudly by design; AC8 stays red until the proposed M4.6pR3 lands.
2. **The state list.** R3-4 lists docked, boost, cruise 0.99 with glow, brake, arrived α Cen and arrived home. This doc shoots **boost twice (β 0.5 and 0.9)**, as the parent design's M4.6 bullet and spec §4 ("0, 0.5, 0.9, 0.99") ask. It shoots each state from two views (deck, forward), for 14 frames plus the sheet. Pans are dropped (no pan composite; see R3-4's G-M4-1). 0.999c is not reachable on the α Cen leg.
3. **The cruise glow is not HB-102.** The live 0.99c cruise emits `glow_pole_w_m2` 3.347 × 10⁻⁵ W/m² in the Local Interstellar Cloud (0.2474 cm⁻³, as the HUD shows). HB-102's 9.63 × 10⁻⁶ is the spec's reference medium. The frame records the sim's value, and G-M4-S4 already pins the renderer to whatever the sim emits.
4. **`make bench` does not gate p99 today.** Only the structure is checked (`Makefile:392–393`). The bridge branch gates both, and the default is unchanged (AC9).
5. **Two route facts the sprint does not state.** (a) Driving `journey_tick()` without `demo._process` leaves the HUD cards un-aged (V19). (b) `home` needs a tick before `commit` (V18). `tests/m4_playthrough_ship.gd` already does both, and this design copies it.
6. **LOC.** About 300, against the sprint's ~200. Of the difference, ~45 is the frame checks (blank, duplicate, state asserts) and the manifest, ~30 is the bench's structural asserts and docked control, and ~8 is the publish target.

## Files

- **New:** `tools/m4_ship_capture.gd`, `tools/m4_ship_bench.gd` (and their `.uid`s); `design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md` (AC5's 15-row look record, the bench lines and the public URLs).
- **Modified:**
  - `Makefile`: `capture-m4`, the `bench` dispatch and `BRIDGE_TIER`, `capture-m4-publish`, `.PHONY`;
  - `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` (progress);
  - `changelogs/unreleased/<date>-m46r-ship-renders-bench.md`.
- **Not modified:** `main.gd`, `demos/*`, `interior/*`, `ui/*`, `sky/*`, `bridge/*`, `sim/*`, `physics/*`, `assets/*`, `tools/interior_capture.gd`, `tools/bench.gd`.
