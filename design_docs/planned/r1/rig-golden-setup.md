# Nightly rig/golden: the setup make test used to provide (7af)

**Status:** Planned 2026-11-09 (mission iteration 81, designer). Revision 1 follows design-quorum round 1 and revision 2 follows round 2 (each 3/3 reject); revision 2 is the narrow-refinement carve-out. See "Quorum round 1" and "Quorum round 2 and the carve-out" below. **Release:** r1. **Milestone:** none (merge and nightly tooling).
**Priority:** P1. Every nightly `rig/golden` on main is red before any GPU case runs, so the GPU goldens (definition of done, gate 2) are not re-verified on main at all.
**Implements:** queue row **7af**. It restores the nightly split that Mark ruled on 2026-11-03 and 2026-11-06 (CLAUDE.md "Merges"; PR #405, `dec3bd83`): `make test` runs as `rig/full` on an idle CPU, and `make golden` runs as `rig/golden` on an idle GPU.
**Depends on:** PR #405 (`tools/rig_nightly.sh` calls `tools/rig_check.sh <sha> --golden-only`); the hermetic control `tools/test_rig_check.sh` from iteration 55 / PR #345 ([rig-watchdog-7200](../../implemented/r1/rig-watchdog-7200.md)). AILANG v0.56.1, Godot 4.7.2.
**Estimated LOC:** about 85.
- `tools/rig_check.sh`: about 22. The setup list, `SETUP_S`, `DL_S`, the 9-line `bounded` helper, the setup loop, `make runtime`, `sky-assets` and the two existing watchdog lines switched to `bounded`, and the header.
- `tools/test_rig_check.sh`: about 63. A make-call log and a hang mode in the stub, an `order` helper, 7 cases, the `unset` and poison additions, and the counts 8 → 15.
- Nothing changes in `Makefile`, `mk/`, `.gd` files or `.uid` files.

## Game vision alignment

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | No clocks. |
| The Ship Is Home | 0 | 0 | No scene. |
| Grounded Strangeness | 0 | 0 | No visuals change. |
| We Are Not Built For This | 0 | 0 | No crew. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No physics maths. The fix restores the nightly that re-checks the GPU-vs-CPU physics goldens on main. |
| **Net** | | **0** | **Go.** This is nightly-rig hygiene under Mark's ruling of 2026-11-06. No pillar is below 0, so D-88 lets the loop proceed. |

Physics gates 2 and 3 of the definition of done do not apply. No formula, shader, lookup table or render changes, and nothing moves into or out of `sunholo/relativity`. The change only restores the run that re-verifies the existing gate-2 goldens (bar clauses 1 and 3) every night.

## Problem

Since `dec3bd83`, the nightly's GPU half is `tools/rig_check.sh <sha> --golden-only`. In a fresh clone it runs `make runtime` (when needed), then `make sky-assets`, then `make golden` alone (`tools/rig_check.sh:69-83`). Before the split, `--golden` ran `make test` first in the same clone. `make test` (`Makefile:57`) lists `deps`, `starmap-assets` and `import` among its prerequisites, and its closure fetches `planet-assets` for `planets-test`. `make golden` lists none of these as its own prerequisites.

The first nightly `rig/golden`, on main `7d26c947` (2026-11-09 03:18 UTC, posted on issue #392), failed in `constellation-golden`. The errors were `SCRIPT ERROR: Parse Error: Identifier "Relativity" not declared in the current scope`, the same for `SkyFrame`, `ShipFrame` and `ShipCamera`, `Could not find type "Starfield"`, and then `Nonexistent function 'new' in base 'GDScript'` at `res://tools/constellation_capture.gd:7`. The log is `/var/folders/kr/h0wr2sj94vd6ljtmsxv8jkt00000gn/T/rig-check/7d26c947d276903ebb996bbf388aa6dc8c85d8c3.log`. Lines 176 to 211 show `lens-assets` and `m4-physics-probe` passing, and then the Godot parse errors begin.

## Root cause

A fresh clone has no `.godot/global_script_class_cache.cfg`, so no `class_name` resolves until `godot --import` runs. Godot's `--check-only` exits 0 even on parse errors, so the instrument here is a count of `SCRIPT ERROR` lines.

GNU make collects the prerequisites of `golden` from every rule that names it and builds them depth-first. `import` reaches `golden` only through `true-light-golden` (`Makefile:1246`), and that target comes after constellation's target in the merged list. So `make -n golden` at 7d26c947 runs `constellation_capture.gd` (line 17) before `godot --import` (line 18).

Serial make honours this order deterministically, so the failure is not a make-ordering limitation. The one existing `import` edge simply sits behind the wrong sub-target.

The merged list is not in plain definition order, which corrects the reviewer's wording. On the rig's GNU Make 3.81 (`/usr/bin/make`), `make -pn golden` prints the merged list as `golden: lens-assets m4-physics-probe constellation-golden true-light-golden comms-golden earth-link-golden` (V3). The recipe rule's prerequisites (`Makefile:582`) come first, even though `mk/constellations.mk:12` is read earlier (it is included at `Makefile:30`). The other rules follow in the order they are read.

## Measurement: what else golden silently took from make test

All of this was measured headlessly, on fresh `git clone`s of `7d26c947` (deleted afterwards). Nothing ran on the GPU.

| Input | How golden reads it | Fresh clone | Evidence |
|---|---|---|---|
| Class cache (`import`) | Every golden Godot script | absent | Before `make import`, `--check-only` printed 644 `SCRIPT ERROR` lines over 15 scripts (main.gd 188; tools: constellation_golden 41, true_light 18, comms 36, earth_display 8, cmb 22, earth_link 5, exposure 44, gr 41, interior 68, ism 47, m4_ship 51, m5 50, star_surface 25; constellation_capture 0, because it loads the golden at run time). `make import` took 9 s. Afterwards the count was **0**. |
| Planet textures (`planet-assets`) | `m5_golden.gd:28-31`: textured G-M5-4 prints `ok` only when `assets/planets` exists, and `skip` otherwise | absent (gitignored) | The last green golden (rig log `19b3d362…`, 2026-11-03, after `make test`) has **417** `^ok` lines in its golden section (log lines 15342-15983), and one of them is `ok G-M5-4 Jupiter … (normalised texture …)`. The recipe asserts `grep -c '^ok' = 417`. Without the textures the count is 416, so **golden is red even after import is fixed**. `make planet-assets`: 5 s, 20 textures verified. |
| Large star tier (`starmap-assets`) | `m4_ship_golden.gd:34` → `_build(true)` → `interior_sky.gd:96` `Starfield.default_tier()`, which is `large` only when `data/starmap/stars_large.bin` exists (`sky/starfield.gd:139-143`) and otherwise falls back to `medium` with a warning | absent | The green baseline has 0 `stars_large.bin is missing` warnings, so G-M4-S2 and G-CAM-3 were pinned on the large tier. Without the file, golden draws a different sky. `make starmap-assets`: under 1 s, `tiers match`. |
| AILANG package cache (`deps`) | `m4-physics-probe` runs `ailang run --package-dir sim` against `$HOME/.ailang/cache` | warm on the Studio; empty on a new host | With an empty `HOME`, the pinned `runtime/bin/ailang run … m4_physics_probe.ail` exits 1 with `package resolution setup failed … sunholo/celestial/0.6.0`. After `HOME=<same> make deps` (1 s) it exits 0 and prints 28 lines. The 03:18 nightly passed only because the Studio's home cache was warm. |
| Sky textures, lens tables, sim runtime | `sky-assets` and `make runtime` (in `rig_check.sh`), and `lens-assets` (a golden prerequisite) | provided | These already run on the golden-only path. `SimBridge` reads `res://runtime/cache` (`bridge/sim_bridge.gd:527`), which `make runtime` stages. |
| Everything else | The three-part audit in V9: the `res://` literals, the existence and environment probes over the 148-file closure, and the green baseline | tracked, written by golden, or machine state | V9 records the commands and outputs. No fifth make-test-provided input was found. |

Import order among the setup targets does not matter for the fetched files. `data/raw` and `assets/planets` get a `.gdignore` (`tools/sky_assets.sh:57`, `tools/planet_assets.sh:48`), and the starmap tier is a `.bin` that Godot does not import. `import` still goes last. The whole setup costs 16 s on a cold clone and 4 s on a warm one (deps 0, starmap 0, planet 1, import 3).

**Answer:** golden needs the four inputs found by the audit recorded in V9; the first nightly rig/golden is the completeness re-check. The four are `deps`, `starmap-assets`, `planet-assets` and `import`. The measurements confirm three of them as hard failures: `import`, `planet-assets` (as an ok-count failure) and `deps` (on a cold home). `starmap-assets` is a silent change to golden's inputs.

## Verification log (revisions 1 and 2)

| # | Command | Output (measured 2026-11-09) |
|---|---|---|
| V1 | `grep -n 'GOLDEN_S\|TEST_S\|7200\|1800' tools/rig_check.sh tools/test_rig_check.sh tools/rig_nightly.sh` | `rig_check.sh:20 TEST_S=${RIG_TEST_S:-7200}` and `:21 GOLDEN_S=${RIG_GOLDEN_S:-1800}`. `:80`: the 7200 s watchdog wraps **`make test` only**. `:82`: 1800 s wraps `make golden` only. `test_rig_check.sh:8` unset, `:48` pins 7200s, `:77` poison. `rig_nightly.sh`: no match. |
| V2 | `grep -n 'alarm\|timeout\|kill' tools/rig_nightly.sh`; `grep -n 'TimeOut' tools/launchd/*.plist` | Both empty. `rig_nightly.sh:85,89` run `rig_check.sh` with no bound, and the plist has only `StartCalendarInterval`. **No outer watchdog exists on the golden-only path.** |
| V3 | `make -pn golden \| grep '^golden:'` (GNU Make 3.81) | `golden: lens-assets m4-physics-probe constellation-golden true-light-golden comms-golden earth-link-golden` |
| V4 | `make -n golden \| grep -c 'godot --headless'`; `… \| grep -c 'godot --audio-driver'` | `1`, which is the `--import` line itself (line 18), so that instrument counts no golden target. `5` Godot processes: lines 17 (constellation), 19 (true-light), 21 (comms, via `script_gate.sh`), 23 (earth-link) and 25 (golden's own recipe, `main.gd --golden`, which loads the 10 `tools/*_golden.gd` scripts). That is **4 Godot-invoking sub-targets** plus the recipe, covering the 15 scripts. |
| V5 | Process tree, prototype in `mktemp -d`: a stub that runs `sleep 300 &`, writes `$!` and `wait`s, under each wrapper with 2 s | Today's `perl -e 'alarm shift; exec @ARGV' 2 …`: rc 142, **child alive** afterwards. `bounded 2 …` (below): rc 124 after 4 s, child dead. Mutant `-$pid → $pid`: rc 124, **child alive**. Passthrough: `exit 3` gives 3, `kill -9 $$` gives 137. `read` from stdin gets EOF. Positive control: a live `sleep 30 &` is seen by `kill -0`. |
| V6 | AC1 precondition: fresh clone, then `make runtime`, then `find .godot -maxdepth 2` | `make runtime` creates only `.godot/tmp/ailang-rel` (its `$(SCRATCH)` download), with no class cache. The count is still **644**. After the four setup targets (pinned `PATH`, all rc 0) it is **0**; then `20` jpgs and the large tier are present. |
| V7 | `grep -n 'n=8\|n=9\|nok\|of 8\|unset' tools/test_rig_check.sh` | `:8 unset RIG_TEST_S RIG_GOLDEN_S`. The caller-poison coupling is at `:74 n=8`, `:76 n=9`, and `:79` (`[ "$nok" = 8 ]` and `of 8 ok`). `:77` runs the nested pass with `RIG_TEST_S=1234 RIG_GOLDEN_S=7`. Revision 2 edits: `:74` 8 → 15, `:76` 9 → 16, and both counts on `:79` 8 → 15. `RIG_SETUP_S` and `RIG_DL_S` join the `:8` unset, and `RIG_SETUP_S=9 RIG_DL_S=9` join the `:77` poison. |
| V8 | `sh tools/test_rig_check.sh tools/rig_check.sh` at 7d26c947 | `rig-check control: 9 cases, 0 failures`, 46 s. |
| V9 | Input audit, three parts | **(1)** `grep -hoE 'res://[^" ]+' $S \| sort -u` over the 15 scripts gives 38 literals. Cross-checked with `git ls-files` and `git check-ignore`: 33 are tracked, and 5 are untracked and gitignored. `res://.godot/tmp/m4-physics-probe.txt` is written by the `m4-physics-probe` golden prerequisite. `res://renders/{constellations,earth_link_golden,true_light_golden,levels/physics}` are golden's own output directories (`constellation_golden.gd:5`, `earth_display_golden.gd:9`, `true_light_golden.gd:26`, `m4_ship_golden.gd:353,383`). **(2)** `grep -nE 'file_exists\|dir_exists\|get_environment\|ConfigFile'` over the golden closure: the 15 scripts plus every `res://….gd/.tscn` they load and every `class_name` they name (resolved through `.godot/global_script_class_cache.cfg`, 101 classes), iterated to a fixpoint. That is 148 files (140 `.gd`, 8 `.tscn`): the 15 scripts, `sky/`, `physics/`, `planets/`, `bridge/`, `interior/`, `demos/`, `ui/` and `audio/` classes. It gives 64 hits in 31 files, classified as below. **Provided by a setup step (9):** `starfield.gd:141` (starmap-assets); `system_view.gd:168` and `planet_smoke.gd:13` (planet-assets); `captain_avatar.gd:310,342` (`*.import` files, gitignored and written by `import`); `background.gd:89` (sky-assets); `schwarzschild.gd:210,223` (lens-assets, a golden prerequisite); `m4_ship_golden.gd:99` (the probe file from `m4-physics-probe`; `sky_review.json` tracked). **Tracked (17):** `starfield.gd:217,282` (`stars_bright.bin`, `stars.json`), `system_view.gd:108` (`data/planets/ALBEDO`), `ship_geometry_demo.gd:223`, `area_bundle.gd:145`, `camera_director.gd:126,138`, `ship_demo_lift.gd:48`, `ship_level_runtime.gd:10`, `sound_data.gd:92,199`, `sound_director.gd:354`, `comms_waterfall.gd:143` and `main.gd:1331` (45 tracked `assets/audio` files), `crew_page.gd:59` (`data/crew/scenario.json`), `ai_bridge.gd:369` (`ai/service.ail`), `crossing_review.gd:190`. **Tracked source with an option or a gitignored export-bundle fallback (9):** `system_view.gd:171`, `ship_geometry_demo.gd:165,167`, `ship_commons.gd:5`, `area_bundle.gd:245,249,251`, `commons_civic_pilot.gd:79,103`. **Gitignored, off the golden path (4):** `ship_geometry_demo.gd:265`, `commons_civic_pilot.gd:6` and `commons_art_pilot.gd:14,22`, which load only with `civic_art: true`, and no golden sets that. **Environment- or machine-dependent, the same before and after the split (25):** `sim_bridge.gd:159,162,164` (`AILANG_BIN`/`PATH`: rig_check puts `runtime/bin` first, and comms-golden sets `AILANG_BIN`), `sim_bridge.gd:525` (export-only `user://` unpack), `ai_bridge.gd:288,436,581,589`, `ai_cache.gd:74,84,103`, `earth_feed.gd:128`, `ai_settings.gd` ×6 and `game_settings.gd` ×2 (`user://` and key env, per machine, never written by a make-test prerequisite), `benchmark_upload.gd` ×2, `frame_check.gd:202`, `gr_golden.gd:50` (`GR_ONLY`) and `star_surface_golden.gd:246` (`SS_OUT`), development knobs unset in the rig. **No fifth input.** **(3)** Over rig log `19b3d362…`: `grep -c 'stars_large.bin is missing'` gives **0** for the whole log and for the golden section (lines 14754-15983, from the last `lens-assets: tables match` to `golden: 0 failures`). `grep -cE 'skip\|missing\|not fetched'` over that section gives **0**. `main --golden` (from line 15342) has **417** `^ok` lines, 1 of them the textured G-M5-4. |
| V10 | Prototype of revision 2's flow in `mktemp -d`: the V5 `bounded` with a 2 s bound on `make runtime` and `make sky-assets`, and a stub make that hangs the named target with a `sleep 20 &` child | runtime hang: rc 1 after 5 s, calls `runtime`, `rig setup: make runtime failed or ran over 2s`, child dead. sky-assets hang: rc 1 after 4 s, calls `runtime sky-assets`, `rig setup: make sky-assets failed or ran over 2s`, child dead. **Mutant: sky-assets on the plain call**: rc 0 after 20 s, calls continue to `deps starmap-assets planet-assets import golden`, so `sky-hang` goes red. Positive control: a live `sleep 30 &` is visible to `kill -0`. |

## Design

**One ordered setup step in `tools/rig_check.sh`, run immediately before `make golden` on both golden paths, each target bounded as a process group:**

```sh
GOLDEN_SETUP="deps starmap-assets planet-assets import"   # 7af: what make golden read from make test; import last
SETUP_S=${RIG_SETUP_S:-600}                               # per target; slowest measured 9 s
DL_S=${RIG_DL_S:-3600}   # runtime fetch + sky regen; measured regen ~900 s
# bounded SECS cmd...: cmd in its own process group, stdin from /dev/null; at SECS (or on INT/TERM/HUP) TERM the
# whole group, KILL it 2 s later, exit 124 (130 if interrupted). A plain alarm+exec signals make, not its recipes.
bounded() {
  perl -e 'my $s = shift; my $pid = fork; defined $pid or die "bounded: fork: $!\n";
    if (!$pid) { setpgrp(0, 0); open STDIN, "<", "/dev/null"; exec @ARGV or exit 127 }
    setpgrp($pid, $pid);
    for my $sig (qw(ALRM INT TERM HUP)) { $SIG{$sig} = sub { kill "TERM", -$pid; sleep 2; kill "KILL", -$pid;
      waitpid($pid, 0); exit($sig eq "ALRM" ? 124 : 130) } }
    alarm $s; waitpid($pid, 0); exit($? & 127 ? 128 + ($? & 127) : $? >> 8)' "$@"
}
...
     bounded "$DL_S" make runtime >> "$log" 2>&1 || fail "rig setup: make runtime failed or ran over ${DL_S}s" ;;
...
bounded "$DL_S" make sky-assets >> "$log" 2>&1 || fail "rig setup: make sky-assets failed or ran over ${DL_S}s"
...
[ $tests = 0 ] || bounded "$TEST_S" make test >> "$log" 2>&1 || fail "make test failed or ran over ${TEST_S}s"
if [ $golden = 1 ]; then
  for t in $GOLDEN_SETUP; do
    bounded "$SETUP_S" make "$t" >> "$log" 2>&1 || fail "golden setup: make $t failed or ran over ${SETUP_S}s"
  done
  bounded "$GOLDEN_S" make golden >> "$log" 2>&1 || fail "make golden failed or ran over ${GOLDEN_S}s"
fi
```

The helper body is the exact code measured in V5. When the deadline passes, every descendant in the group is TERMed, then KILLed, and reaped before `fail` runs. Only then does the EXIT trap delete the clone. Swapping the two existing watchdog lines to `bounded` is the same call with the same messages, so `make-test-red` and `watchdog-override` keep their expectations. `make runtime` (the staging branch at `rig_check.sh:72`) and `make sky-assets` (`:77`) are bounded by `DL_S`. 3600 s is 4 times the about 900 s sky regeneration (the `sky-assets` help text, `Makefile:979`: "regenerate … ~15 min"), and the runtime fetch measured 3 s.

**Budget.** Every `make` call on the golden path is bounded. A timeout ends the run (`fail` exits), so at most one bounded call ever hits its deadline. The TERM→KILL cleanup allowance is therefore 2 s once per run, plus the reap.
- `--golden-only`: `make runtime` 3600 + `sky-assets` 3600 + setup 4 × 600 + `make golden` 1800 = **11400 s**, plus 2 s of cleanup = **11402 s**.
- `--golden`: the same plus `make test` 7200 = **18600 s**, plus 2 s = **18602 s**.
- Per call, the bound plus 2 s is the most that call can take.
- V1 and V2 show that nothing wraps `rig_check.sh` from outside, so each named failure (`rig setup: …`, `golden setup: …`, `make golden …`) is the first deadline to fire for its step.
- The 600 s per setup target is about 66 times the slowest measured target (import, 9 s cold). A bucket miss on `starmap-assets` or `planet-assets` becomes a rebuild or source fetch whose length is unmeasured; past 600 s it becomes a loud, named failure.
- Outside `make`, the clone's `git clone`/`git fetch` (`:60-62`) and the `gh` status posts remain plain network calls. This revision does not change them.

The longest failure description is `01234567: golden setup: make starmap-assets failed or ran over 600s` (67 characters, recounted with `wc -m`). The new `rig setup` descriptions are 61 characters (sky-assets) and 58 (runtime). All are within the 140-character limit.

**Control (`tools/test_rig_check.sh`).**
- The stub `make` appends `$*` to `$STUB_MAKES`. For the target named in `$STUB_MAKE_HANG`, it runs `sleep 20 & echo $! > "$STUB_CHILD"; wait`. A 20 s child means a mutant that loses a bound ends red after about 20 s; it never hangs the control.
- The top-level `unset` gains `RIG_SETUP_S RIG_DL_S`, and the caller-poison pass adds `RIG_SETUP_S=9 RIG_DL_S=9`.
- A new helper is `order <case> <flag> <failing target> <want rc> <want make calls> <want state> <want description ERE> [RIG_SETUP_S] [RIG_DL_S] [STUB_VERSION]`.
- The stub runtime is on the pin, so `make runtime` is not called, except in `runtime-hang`, which sets the stub version off the pin.

| Case | Flag | Stub | rc | Make calls, in order | Final post |
|---|---|---|---|---|---|
| `golden-only-setup` | `--golden-only` | — | 0 | `sky-assets deps starmap-assets planet-assets import golden` | success `make golden green` |
| `golden-setup` | `--golden` | — | 0 | `sky-assets test deps starmap-assets planet-assets import golden` | success |
| `golden-setup-red` | `--golden-only` | `import` fails | 1 | `sky-assets deps starmap-assets planet-assets import` | failure `01234567: golden setup: make import failed or ran over 600s$` (this pins the default) |
| `full-no-setup` | none | — | 0 | `sky-assets test` | success |
| `setup-hang` | `--golden-only`, `RIG_SETUP_S=2` | `deps` hangs with a child | 1 | `sky-assets deps` (no later setup, no `golden`) | failure `…make deps failed or ran over 2s$`. The child PID is dead within a 3 s `kill -0` poll. A positive control first shows that the same probe sees a live `sleep 30 &`. |
| `sky-hang` | `--golden-only`, `RIG_DL_S=2` | `STUB_MAKE_HANG=sky-assets`, which hangs with a child | 1 | `sky-assets` (no setup, no `golden`) | failure `01234567: rig setup: make sky-assets failed or ran over 2s$`. The child is reaped (the same `kill -0` poll and positive control). |
| `runtime-hang` | `--golden-only`, `RIG_DL_S=2`, stub version off the pin | `STUB_MAKE_HANG=runtime`, which hangs with a child | 1 | `runtime` (no `sky-assets`, no setup, no `golden`) | failure `01234567: rig setup: make runtime failed or ran over 2s$`. The child is reaped (the same poll and positive control). |

The base count goes from 8 to 15 (8 existing, 7 new), and caller-poison expects 15 of 15, so the total is 16 cases. Every site of the count coupling is listed in V7. No case pins the 3600 s default, so `RIG_DL_S` in the unset is prophylactic, as `RIG_GOLDEN_S` was in iteration 55. `RIG_SETUP_S` is pinned by `golden-setup-red` (AC11).

**Rejected alternatives.**
1. *A `golden-setup` stamp as the first prerequisite of golden.* This is deterministic for the serial nightly: V3 shows the recipe rule's prerequisites lead the merged list. But the stamp's target list would then live in the Makefile, where the hermetic control (`tools/test_rig_check.sh` with a stub make) sees only one name and cannot assert per-target order without a new lint. The ordering also silently evaporates under `make -j golden`, which nothing in `rig_check.sh` forbids today.
2. *Order-only `| golden-setup` on each Godot-invoking golden target.* This is correct under `-j`, but `make -n golden` at 7d26c947 shows **4** such sub-targets (V4: constellation, true-light, comms and earth-link, plus golden's own recipe, 5 Godot processes covering the 15 scripts). The edge would have to be repeated on each, and the next golden target forgets it. It also leaves planets, starmap and deps uncovered. (The reviewer's "13" counts scripts, not targets. V4 measures the targets.)
3. We keep the explicit ordered `GOLDEN_SETUP` list in `tools/rig_check.sh` because it is a single, per-target-bounded sequence on which the stub control can assert call order.
4. *Run `make test` in the golden-only nightly.* That defeats the split: about 70 min of CPU before the GPU window.
5. *Reuse the `rig/full` clone.* `rig_check.sh` deletes each clone at exit (40 GB once, 2026-11-03), and coupling the two halves' state is what broke here.
6. *A general supervisor.* That is row 7ad (bounded script supervisor). This row needs one helper and one control.

A local `make golden` in a fresh clone still expects the documented one-off `make import` (`Makefile:42`, CLAUDE.md). That behaviour is unchanged.

## Acceptance criteria

Set up a fresh clone: `C=../stapledons-godot-7af-ac; git clone -q . $C && cd $C && make runtime`. `make runtime` creates only `.godot/tmp/ailang-rel` and no class cache (V6); check that with `test ! -f .godot/global_script_class_cache.cfg`. Delete `$C` afterwards.

`S` is the 15 scripts: `main.gd tools/{constellation_capture,constellation_golden,true_light_golden,comms_golden,earth_display_golden,cmb_golden,earth_link_golden,exposure_golden,gr_golden,interior_golden,ism_golden,m4_ship_golden,m5_golden,star_surface_golden}.gd`.

`count` (POSIX `sh`; zsh needs `${=S}`) is `n=0; for s in $S; do n=$((n+$(perl -e 'alarm 120; exec @ARGV' godot --headless --path . --check-only --script $s 2>&1 | grep -c 'SCRIPT ERROR'))); done; echo $n`.

For each mutant: `T=$(mktemp -d)`, write the mutant to `$T/m.sh`, then run `sh tools/test_rig_check.sh $T/m.sh`. Inside table cells, `\|` is Markdown for a plain `|`.

| # | Criterion | Command | Expected |
|---|---|---|---|
| 1 | Positive control: a fresh clone cannot parse the goldens | in `$C` after `make runtime`: `test ! -f .godot/global_script_class_cache.cfg && count` | `> 0` (measured 644) |
| 2 | The rig's own setup list fixes the parse | in `$C`: `PATH=$PWD/runtime/bin:$PATH; for t in $(sed -n 's/^GOLDEN_SETUP="\([^"]*\)".*/\1/p' tools/rig_check.sh); do make $t \|\| break; done; count` | every make exits 0, then `0` |
| 3 | The setup provides the textures and the tier | in `$C` after AC2: `ls assets/planets \| grep -c jpg; test -f data/starmap/stars_large.bin && echo tier` | `20`, then `tier` |
| 4 | The list is exactly the measured four, with import last | `sed -n 's/^GOLDEN_SETUP="\([^"]*\)".*/\1/p' tools/rig_check.sh` | `deps starmap-assets planet-assets import` |
| 5 | Control green | `sh tools/test_rig_check.sh tools/rig_check.sh \| tail -1`; `make rig-check-control` | `rig-check control: 16 cases, 0 failures`, rc 0 |
| 6 | M1, no setup, dies | `sed 's/^GOLDEN_SETUP=.*/GOLDEN_SETUP=""/' tools/rig_check.sh` | rc 1; `golden-only-setup`, `golden-setup`, `golden-setup-red` and `setup-hang` FAIL |
| 7 | M2, import dropped, dies | `sed 's/^GOLDEN_SETUP=.*/GOLDEN_SETUP="deps starmap-assets planet-assets"/' tools/rig_check.sh` | rc 1; `golden-only-setup`, `golden-setup` and `golden-setup-red` FAIL |
| 8 | M3, planet-assets dropped, dies | `sed 's/^GOLDEN_SETUP=.*/GOLDEN_SETUP="deps starmap-assets import"/' tools/rig_check.sh` | rc 1; `golden-only-setup`, `golden-setup` and `golden-setup-red` FAIL |
| 9 | M4, setup failure ignored, dies | `sed 's/ \|\| fail "golden setup: .*$//' tools/rig_check.sh` | rc 1; `golden-setup-red` and `setup-hang` FAIL |
| 10 | M5, group kill dropped, dies | `sed 's/-\$pid/$pid/g' tools/rig_check.sh` | rc 1; `setup-hang`, `sky-hang` and `runtime-hang` FAIL with the child alive (V5: that mutant leaves the child alive) |
| 11 | M6, hermetic unset dropped, dies | `sed 's/^unset RIG_TEST_S RIG_GOLDEN_S RIG_SETUP_S/unset RIG_TEST_S RIG_GOLDEN_S/' tools/test_rig_check.sh > $T/t.sh; sh $T/t.sh tools/rig_check.sh` | rc 1; `caller-poison` FAILs (the nested `golden-setup-red` posts `9s`) |
| 12 | M7, sky-assets back on the plain call, dies | `sed 's/^bounded "$DL_S" make sky-assets/make sky-assets/' tools/rig_check.sh` | rc 1 after about 20 s; `sky-hang` FAILs (V10: rc 0, calls run on to `golden`) |
| 13 | No orphan after the control | `pgrep -f 'sleep 20' \| wc -l` before and after AC5 | equal |
| 14 | Scope | `git diff --name-only origin/main...HEAD` | `tools/rig_check.sh`, `tools/test_rig_check.sh`, this doc and the landing files only |
| 15 | Shell hygiene | `sh -n tools/rig_check.sh && sh -n tools/test_rig_check.sh && git diff --check origin/main...HEAD` | rc 0, no output |

The post-merge observation is not a merge gate, because merges never wait on the GPU. The first nightly `rig/golden` after the merge should have `grep -c 'SCRIPT ERROR' $TMPDIR/rig-check/<sha>.log` = 0 in its constellation section, and either succeed or fail on a GPU case rather than on setup. That run is the GPU verification of the 417 count and of `make golden` running in its own process group.

## Sub-milestones and estimates

There is one milestone, about 85 LOC.
1. Write the 7 control cases first, and record them red against the unmodified `rig_check.sh` (that is M1, M5 and M7 at once).
2. Add the helper and the loop.
3. Run AC1–15.

## Risks and mitigations

- **A double import on `--golden`.** `make test` imports, then setup imports again, measured at 3 s warm. The fetch targets verify sha256 and skip downloads. This is accepted.
- **Import cost with sky assets.** There is none extra: `data/raw` and `assets/planets` carry `.gdignore`. The measured 9 s cold matches the import the pre-split nightly paid inside `make test`.
- **A bucket miss starts a rebuild.** `bounded` stops it at 600 s per target, kills its whole process tree (V5), and posts the target's name. The budget above has no outer bound that could pre-empt that message. A sky regeneration or a runtime fetch is stopped the same way at `DL_S` (3600 s), with `rig setup: make <t>` named.
- **Process group and terminal.** When `rig_check.sh` is run by hand, the group is a background job. Its stdin is `/dev/null`, so a read cannot stop it with SIGTTIN (V5: `read` gets EOF), and Ctrl-C reaches the `perl` parent, which TERMs the group (rc 130). A process group stays in the same session, so Godot's window-server access should not change, but this is not measured on the GPU. The first nightly is the check, and if it is red for that reason, the fallback is to revert only the `make golden` line to the old alarm.
- **`deps` fails on lock drift.** `rig/golden` is then red for a non-GPU reason. `rig/full` is red the same night, and the description names `make deps`.
- **The next new golden input.** The comment on `GOLDEN_SETUP` names the rule, and the 417 `ok` count catches a silent skip.

## Quorum round 1 (2026-11-09, 3/3 reject) and how revision 1 resolves it

| Reviewer | Objection | Resolution (measured) |
|---|---|---|
| GLM | The 1800 s per-target bound was never reconciled with GOLDEN_S or the 7200 s watchdog; no total; the outer watchdog might pre-empt the named failure; AC1 lacked `make runtime`; the `unset` and caller-poison coupling were unconfirmed | V1/V2: 7200 s wraps `make test` only, 1800 s wraps `make golden` only, and nothing wraps `rig_check.sh`. Took option (a), `SETUP_S=600`: 2400 s of setup, 4200 s total with golden-only and 11400 s with `--golden`, with the named failure always first (round 2 supersedes these totals: 11400 s and 18600 s once runtime and sky-assets are bounded). V6: AC1 now runs `make runtime` first, which creates only `.godot/tmp/ailang-rel` (count still 644). V7: all four count sites and both env sites are named; AC11 (M6) proves the new unset. |
| Kimi | The make-order model was wrong, and the alternatives 1–3 rationale used an unverified "5 targets" | Kimi's root-cause text and alternatives are adopted, with the placeholders measured. V3 corrects one clause of Kimi's text: the merged list puts the recipe rule's prerequisites first, not plain definition order. V4: `grep -c 'godot --headless'` = 1 (the import line, not a target), and there are 4 Godot-invoking sub-targets plus the recipe (5 processes, 15 scripts). |
| Sol | `perl alarm; exec make` signals make, not its recipe children | Option (A): the 9-line `bounded` helper, a process group with TERM, a 2 s grace, then KILL and reap, used for setup, `make test` and `make golden`. V5 measures today's wrapper leaving the child alive and `bounded` killing it. The `setup-hang` control has a positive liveness check, and AC10 (the M5 mutant) and AC12 (no orphan) cover it. Not row 7ad: one helper and one control. |

## Quorum round 2 and the carve-out (2026-11-09, 3/3 reject)

This is the narrow-refinement carve-out (gate 2), the second use in this mission after iteration 74. There is no round 3. No reviewer disputed the direction, and each fix below is applied verbatim and is checkable.

| Reviewer | Objection | Fix applied verbatim | Checked by |
|---|---|---|---|
| GLM | The membership ("exactly four") was asserted, not measured. The `res://` scan cannot see existence or environment probes, and the baseline claims were unrecorded. | V9 runs the three-part audit: (1) the `res://` scan with `git ls-files`/`git check-ignore` and each untracked entry's disposition; (2) the `file_exists\|dir_exists\|get_environment\|ConfigFile` grep over the 148-file closure, all 64 hits classified; (3) the two baseline greps over log `19b3d362…`. The Answer now reads "golden needs the four inputs found by the audit recorded in V9; the first nightly rig/golden is the completeness re-check". The character count is fixed: 66 → 67. | V9; AC4; post-merge nightly |
| Kimi | `make runtime` and `make sky-assets` are still unbounded with no outer watchdog, so the Budget totals were false. | `DL_S=${RIG_DL_S:-3600}   # runtime fetch + sky regen; measured regen ~900 s`; `bounded "$DL_S" make runtime ... \|\| fail "rig setup: make runtime failed or ran over ${DL_S}s"`, and the same for sky-assets. Budget: golden-only 3600+3600+2400+1800 = 11400 s, `--golden` 7200+3600+3600+2400+1800 = 18600 s (each +2 s cleanup). The `sky-hang` case, `RIG_DL_S` in the V7 coupling sites, and the counts are updated (15 base, 16 total). | AC5, AC12 (M7), V10 |
| Sol | The same two unbounded waits; extend the bounded wrapper with explicitly justified budgets, include every prerequisite and the cleanup allowance, and add hermetic runtime-hang and sky-assets-hang cases. | The same `DL_S` bound (3600 s = 4 × the measured ~900 s regeneration; the runtime fetch is 3 s). The Budget lists every `make` prerequisite plus the 2 s TERM→KILL allowance. `runtime-hang` (stub off the pin) and `sky-hang` each assert rc 1, a make-call list that ends at the hung target, the named failure, and a reaped child, using the same `kill -0` poll and positive control. Kimi's "defer to 7ad" branch was not taken. | AC5, AC10, AC12, AC13, V10 |

## Open questions for the user

## Deliverables

- `tools/rig_check.sh`: `GOLDEN_SETUP`, `SETUP_S`, `DL_S`, `bounded`, the setup loop, `make runtime`, `make sky-assets` and the two watchdog lines on `bounded`, and a header line.
- `tools/test_rig_check.sh`: the make-call log and hang stub, `order`, 7 cases, `RIG_SETUP_S` and `RIG_DL_S` in the unset and the poison, and the counts 8 → 15 / 9 → 16.
- At landing: a `CHANGELOG.md` line, this doc moved to `design_docs/implemented/r1/`, and its README index row.
