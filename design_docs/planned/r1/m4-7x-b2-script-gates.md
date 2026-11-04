# Row 7x batch B2: the nine `mk` files through `$(SCRIPT_GATE)`, and the two judge survivors

**Status:** Planned, mission iteration 70, designer, 2026-11-04. **Release:** r1. **Milestone:** charter queue row **7x**, follow-up batch **B2** (W6 of the landed 7x design), inside the approved sprint `R1-M4-JOURNEY` (D-22/D-66).
**Priority:** P2 (follow-up backlog, [LOOP]). Test and build hygiene only.
**Implements:** [charter](../../stapledon-mission.md) row 7x (its "Remaining" clause: batches B2–B8 and the two iteration-69 judge survivors), and batch B2 of [m4-7x-script-gate-predicates.md](m4-7x-script-gate-predicates.md) §W6. No design-repo feature or [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) section changes: no formula, sim, protocol, shader, scene or player-visible change.
**Depends on:** the landed 7x helper, lint and baseline (PR #393, merge `49eb35d9`); D-88 A (test or audit hygiene inside an approved sprint, no pillar below 0, does not stop); Godot 4.7.2, AILANG v0.56.1 (`runtime/bin`).
**Estimated LOC:** about **105 hand-written lines changed** (+60/−45, excluding the baseline), plus **28 deleted baseline rows**. Per file in [Estimated LOC per file](#estimated-loc-per-file).

**Evidence:** the [Verification log](#verification-log), run first-hand in `/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter70` at `9e4d8231` on 2026-11-04, about 21:20–21:50 local (Godot 4.7.2, AILANG v0.56.1 from the clone's `runtime/bin`, 1-min load 2.1–7.4). The whole B2a change set was applied to the working clone's tracked files, run end to end, captured, and then restored with `git checkout -- mk tools tests`. `git status --porcelain` was empty afterwards (V12). Scratch went to `/tmp/iter70_designer/` and the ignored `.godot/tmp/`.

**The split, in one line.** **B2a: 28 rows**, every one measured green at base and again through its migrated `$(SCRIPT_GATE)` line. **B2b: 14 rows**: 11 need a GPU window, 2 are authoring tools that write tracked assets, and 1 is a performance bench that was red at base on a loaded host. The pin `SCRIPT_GATE_BASELINE_ROWS` goes from **232 to 204**.

## Game vision alignment

Scored against [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code touched. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | Sim and clocks untouched. |
| The Ship Is Home | 0 | 0 | No scene change. |
| Grounded Strangeness | 0 | 0 | No visual change. |
| We Are Not Built For This | 0 | 0 | No crew or consequence change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | Physics tests (`star-surface-test`, the exposure, planet and dust tests) keep every assert. They now count only when the script actually ran. |
| **Net** | | **0** | **Go under D-88 A.** Suite hygiene inside the approved sprint, no pillar negative. Nothing visual or audible changes (five summary lines gain a count; no render, sound or scene edit), so no dev-build review is needed. |

## Problem

The V-numbers are rows of the [Verification log](#verification-log).

1. **42 B2 rows are still unguarded.** At `9e4d8231`, `make script-gate-lint` reads `237 --script invocations: 5 through $(SCRIPT_GATE), 232 on the baseline` (V1). Of the 232, exactly **42** are in the nine B2 files (V2): `mk/ism.mk` 5, `mk/planet-presentation.mk` 10, `mk/star-surfaces.mk` 3, `mk/navigation-usability.mk` 1, `mk/constellations.mk` 4, `mk/npc-painted.mk` 4, `mk/commons-civic.mk` 3, `mk/captain-anim.mk` 6, `mk/style.mk` 6.
2. **Their inline predicates are hand-copied and uneven** (V2, V3):
   - **Fifteen rows check no `SCRIPT ERROR`** although they read a summary (flags `rc,-,sum,-`): `ism-bench`, `dust-flash-test`, `map-ism-test`, `bubble-surface-test`, `ism-surfaces-test`, `moon-lifecycle-test`, `planet-transition-golden`, `planet-bounds-golden`, `star-surface-bench`, `commons-civic-stage`, `commons-civic-assets-check`, both `captain-frames-check` runs and both `ui-theme-check` negative controls.
   - **Four rows check nothing at all:** `planet-cpu-bench` and `exposure-cpu-bench` (a bare `$(GODOT_SIM) … --script …`), and the two ingest tools.
   - **Thirteen summary regexes accept a zero count** (`[0-9]*`), for example `^captain-anim: [0-9]* passed, 0 failures$$`.
   - **Only four rows have a timeout:** the three `perl -e 'alarm 120'` in `mk/planet-presentation.mk` and `alarm 900` on `star-surface-test`.
   - `style-capture` checks rc and `SCRIPT ERROR` but no summary line.
3. **The gap is live, not theoretical.** A copy of `tests/test_dust_flash.gd` with one runtime error inside `_overlap_masks()` logs `SCRIPT ERROR: Invalid access to property or key 'no_such_member_b2' …`, exits **rc 0**, and prints `dust-flash: 26 passed, 0 failures`, three checks fewer than the real 29. Today's `dust-flash-test` predicate (`test $$rc = 0 && grep -q '^dust-flash: [1-9][0-9]* passed, 0 failures$$'`) **passes** it. `$(SCRIPT_GATE)` with the same summary regex fails it: `script-gate: c5 FAIL; 1 SCRIPT ERROR line(s)` (V9).
4. **Five scripts print no counted summary** (V3, V4):
   - `tests/test_star_surface.gd`: `star-surface: OK (0 failures)`;
   - `tools/captain_frames.gd`: `captain-frames: ok`, and `captain-frames: selftest ok` with `--selftest`;
   - `tools/ui_theme_check.gd`: `ui-theme-check: ok`;
   - `tools/exposure_cpu_bench.gd`: `exposure-cpu-bench: OK`;
   - `tools/planet_cpu_bench.gd`: only a JSON blob, with no summary line.
5. **The two iteration-69 judge survivors** (`.ailang/state/evaluations/eval_R1-M4-JOURNEY_7x_round_1.json`, mutants list; V10, V11):
   - **(S1)** The lint mutant "SCRIPT_GATE anywhere in the segment, even after `$(GODOT)`" survives, because no fixture puts `$(SCRIPT_GATE)` between the Godot token and `--script`. Measured: the landed lint classes such a line `ungated`, so the lint is correct. The mutant (`(sg && sg < g + 1)` replaced with `sg`) classes it `gated`, and the landed negative control still passes, because it counts only 2 unguarded rows (V11).
   - **(S2)** The helper accepts the summary regex `^.`. On a log line `x: 0 passed, 5 failures` with rc 0, the landed helper exits 0, and so do `[0-9]* passed` and an uncounted `^v: ok$` (V10, the four new cases run against the landed helper: `FAIL 4 of 16 cases`). The helper checks only that the regex starts with `^`.
6. **Two rows are not green at base, and both are findings, not things to work around:**
   - **`constellation-test` is red in a fresh clone.** `make constellation-test` gives **rc 2** with `constellations: 34 passed, 1 failures` (`ERROR: all 23 source identities resolve uniquely`), because `data/starmap/stars_large.bin` is missing and the sky falls back to the medium tier. Its prerequisites are `import` only. `make test` lists `starmap-assets` (`Makefile:57`), so the nightly suite is unaffected. After `make starmap-assets` (a public-bucket read, 0 s), it is green: `constellations: 35 passed, 0 failures` (V6).
   - **`ism-bench` is red on a loaded host.** `make ism-bench` gives **rc 2** after 203 s at load 3.3. `service-benchmark.json` has `passes: false`: `boost.delta_median_ms` is 0.72 against a 0.5 ms limit, while the plan (3.67 ≤ 20), tick (0.32) and brake (0.04) deltas pass. It logs 0 `SCRIPT ERROR` (V5). This is a performance bench, not in `make test` (V13). Its migration moves to B2b.

**Brief premises re-checked.**
- "No open PR touches these nine files" is **true**. None of the 19 files this batch edits appears in `gh pr diff <n> --name-only` for #373, #379, #380 or #384. The known-positive control (`Makefile`/`mk/earth-link.mk`/`mk/m45.mk`/`mk/deck-layout.mk`) matches 2, 3, 1 and 1 of them (V14).
- The brief names **`make test-script-gate`**. **No such target exists.** The landed targets are `script-gate-selftest` (`mk/script-gates.mk:42`) and `script-gate-drill` (`:45`) (V15). The acceptance criteria use those two.
- The W6 count of 42 for B2 is **true** (V2).

## Goals and non-goals

**Goals.**
1. **B2a: migrate 28 rows** (25 make targets) in the nine files to one `$(SCRIPT_GATE)` line each. Every one of them was measured green at base and through its migrated line (V5, V7).
2. **Add a counted summary** to the five scripts that print none (Problem 4). Each count was measured equal to the base run's own `ok` total or table size (V8).
3. **Close survivor S2 in the helper:** a zero probe in `tools/script_gate.sh`, with four new stub cases.
4. **Close survivor S1 in the lint's negative control:** one fixture row, with the control's expected count going from 2 to 3.
5. **Fix `constellation-test`'s prerequisite:** add `starmap-assets` (Problem 6).
6. **Delete the 28 baseline rows and set the pin from 232 to 204.**
7. **Design B2b's 14 rows** (invocations and the summary edits they need) and state what blocks each one.

**Non-goals.**
- No edit to `mk/sound.mk`, `Makefile`, `mk/m45.mk`, `mk/deck-layout.mk` or `mk/earth-link.mk`.
- No assert changes. The five summary edits only count what the scripts already check.
- No static lint check of the summary regex text. The runtime zero probe covers every gate the same way; see Open question 1.
- No change to how `ism-bench` judges performance.

## Design

### D1. The migration rule

Each migrated row's recipe line or lines become one line:

```
@$(SCRIPT_GATE) NAME LOG DEADLINE 'SUMMARY_ERE' [WANT_RC] -- <the row's own Godot command, unchanged>
```

- **NAME** is the make target. The second `captain-frames-check` run is named `captain-frames-selftest`. The two `ui-theme-check` negative controls are named `ui-theme-neg-override` and `ui-theme-neg-contrast`. The lint keys on target and script, not NAME (7x W2), so all of them still match their target's rows.
- **LOG** is the row's existing log path, so nothing that reads it moves.
- **DEADLINE** is 600 s by default. It is 900 s for `star-surface-test`, which keeps its own `alarm 900`, and 1,800 s for `moon-lifecycle-test`, which measured 215 s and 220 s (V5, V7). Every other B2a row measured 0–24 s at base (`navigation-usability-test` 24 s, 5 s when migrated), so 600 s is at least 25× the measurement. 1,800 s is 8.2× and 900 s is 28×. The 7x gate `sim-bridge` runs at 7.6× (119 s of 900 s).
- **The Godot command is unchanged.** It keeps `$(GODOT)` or `$(GODOT_SIM)`, `--log-file`, `--quit-after 1200` and its user arguments. The three `AILANG_BIN="$$(command -v $(AILANG))" perl -e 'alarm 120; exec @ARGV' $(GODOT)` prefixes become `$(GODOT_SIM)`, which expands to the same `AILANG_BIN=… $(GODOT)` (`Makefile:6`, V3). The helper's process-group deadline replaces the alarm.
- **Dropped:** the `> LOG 2>&1; rc=$$?; cat|grep …; test … && grep -q …` tails. The helper writes LOG and checks rc, `SCRIPT ERROR` and the summary. In `dust-flash-test` and `map-ism-test`, the now-redundant `@mkdir -p $(SCRATCH)` also goes, because the helper creates the log's directory.
- **Regexes:** every `[0-9]*` count becomes `[1-9][0-9]*`. Exact pinned literals stay (`5 identities, 25 poses`; `4 configs, 3 raw GLBs, 4 raw PNGs`).
- **Behaviour change, deliberate (as in 7x W5).** A pass prints one `script-gate: NAME ok: <summary> (rc, no SCRIPT ERROR, s of DEADLINE s)` line instead of the full log, or the `ok`/`FAIL` lines. A failure prints the log's non-`ok` lines and every reason. The full log stays at LOG.

### D2. The per-gate table: all 42 B2 rows

Line numbers are at `9e4d8231` (V2). **Today** is the inventory flag set: `rc` rc checked, `se` a `SCRIPT ERROR` check, `sum` a summary grep, `to` a timeout; `-` means absent (7x W2's heuristic). **Base** is `make <target>` at base: the make rc, the wall time, and the last summary line read from the row's own log (V5, V6). **After** is the migrated line's own output (V7). A row of the form "1 (`foo`)" means the row's script needs the summary edit in D3.

| # | Target (file:line) | Script | Today | Base: rc, s, summary line (measured) | Proposed: NAME, DEADLINE, WANT_RC, SUMMARY_ERE | Summary edit | Batch |
|---:|---|---|---|---|---|---|---|
| 1 | `ism-bench` (`mk/ism.mk:36`) | `tools/ism_service_bench.gd` | rc,-,sum,- (+ `jq .passes`) | rc 2, 203 s; `ism-service-bench: {"boost":{"delta_median_ms":0.7206…` (JSON); `passes: false` | `ism-bench`, 1800, 0, `'^ism-service-bench: OK \([1-9][0-9]* plan pairs, [1-9][0-9]* tick pairs\)$$'`, then `&& jq -e '.passes == true' …` kept | yes: add `print("ism-service-bench: %s (%d plan pairs, %d tick pairs)" % ["OK" if report.passes else "FAIL", plan_delta.size(), tick_delta.size()])` after the JSON line | **B2b** (red at base under load) |
| 2 | `dust-flash-test` (`mk/ism.mk:42`) | `tests/test_dust_flash.gd` | rc,-,sum,- | rc 0, 1 s; `dust-flash: 29 passed, 0 failures` | `dust-flash-test`, 600, 0, `'^dust-flash: [1-9][0-9]* passed, 0 failures$$'` | no | B2a |
| 3 | `map-ism-test` (`mk/ism.mk:47`) | `tests/test_ism_layer.gd` | rc,-,sum,- | rc 0, 0 s; `ism-layer: 22 passed, 0 failures` | `map-ism-test`, 600, 0, `'^ism-layer: [1-9][0-9]* passed, 0 failures$$'` | no | B2a |
| 4 | `bubble-surface-test` (`mk/ism.mk:76`) | `tests/test_bubble_surface.gd` | rc,-,sum,- | rc 0, 1 s; `bubble-surface: 16 checks 0 failures` | `bubble-surface-test`, 600, 0, `'^bubble-surface: [1-9][0-9]* checks 0 failures$$'` | no | B2a |
| 5 | `ism-surfaces-test` (`mk/ism.mk:82`) | `tests/test_ism_surfaces.gd` | rc,-,sum,- | rc 0, 0 s; `ism-surfaces: 18 checks 0 failures` | `ism-surfaces-test`, 600, 0, `'^ism-surfaces: [1-9][0-9]* checks 0 failures$$'` | no | B2a |
| 6 | `planet-presentation-test` (`mk/planet-presentation.mk:4`) | `tests/test_planet_presentation.gd` | rc,se,sum,to | rc 0, 6 s; `planet-presentation: 806 checks 0 failures` | `planet-presentation-test`, 600, 0, `'^planet-presentation: [1-9][0-9]* checks 0 failures$$'` (`$(GODOT_SIM)`) | no | B2a |
| 7 | `moon-lifecycle-test` (`:6`) | `tests/test_moon_lifecycle.gd` | rc,-,sum,- | rc 0, 215 s; `moon-lifecycle: 71 checks 0 failures` | `moon-lifecycle-test`, 1800, 0, `'^moon-lifecycle: [1-9][0-9]* checks 0 failures$$'` | no | B2a |
| 8 | `planet-transition-golden` (`:8`) | `tools/planet_transition_golden.gd` | rc,-,sum,- (windowed) | not run (GPU window); source prints `planet-transition-golden: %d failures;86 samples max flux error …` (86 is a literal) | `planet-transition-golden`, 1800, 0, `'^planet-transition-golden: 0 failures; [1-9][0-9]* samples '` | yes: print `samples.size()` in place of the literal 86 (`"%d failures; %d samples max flux error …"`) | **B2b** |
| 9 | `planet-bounds-golden` (`:10`) | `tools/planet_bounds_golden.gd` | rc,-,sum,- (windowed) | not run; source prints `planet-bounds-golden: %d failures` | `planet-bounds-golden`, 1800, 0, `'^planet-bounds-golden: [1-9][0-9]* checks, 0 failures$$'` | yes: count the checks (`N checks, 0 failures`) | **B2b** |
| 10 | `planet-cpu-bench` (`:12`) | `tools/planet_cpu_bench.gd` | -,-,-,- (bare) | rc 0, 2 s; no summary line (JSON only; 0 `SCRIPT ERROR`) | `planet-cpu-bench`, 600, 0, `'^planet-cpu-bench: [1-9][0-9]* rows, renders/perf/planet_cpu.json$$'` | **yes** (D3) | B2a |
| 11 | `glow-planet-golden` (`:17`) | `tools/glow_planet_golden.gd` | rc,se,sum,- (windowed) | not run; source prints `glow-planet-golden: %d failures` | `glow-planet-golden`, 1800, 0, `'^glow-planet-golden: [1-9][0-9]* passed, 0 failures$$'` | yes: count in `check()` (line 7) | **B2b** |
| 12 | `exposure-frames-test` (`:21`) | `tests/test_exposure_frames.gd` | rc,se,sum,to | rc 0, 8 s; `exposure-frames: 1364 checks 0 failures` | `exposure-frames-test`, 600, 0, `'^exposure-frames: [1-9][0-9]* checks 0 failures$$'` (`$(GODOT_SIM)`) | no | B2a |
| 13 | `exposure-frame-capture` (`:23`) | `tools/exposure_frame_capture.gd` | rc,se,sum,- (windowed) | not run; source prints `exposure-frame-capture: %d failures` | `exposure-frame-capture`, 1800, 0, `'^exposure-frame-capture: [1-9][0-9]* frames, 0 failures$$'` | yes: count the frames written | **B2b** |
| 14 | `manual-exposure-test` (`:28`) | `tests/test_manual_exposure.gd` | rc,se,sum,to | rc 0, 17 s; `manual-exposure: 291 checks 0 failures` | `manual-exposure-test`, 600, 0, `'^manual-exposure: [1-9][0-9]* checks 0 failures$$'` (`$(GODOT_SIM)`) | no | B2a |
| 15 | `exposure-cpu-bench` (`:33`) | `tools/exposure_cpu_bench.gd` | -,-,-,- (bare) | rc 0, 4 s; `exposure-cpu-bench: OK` (uncounted) | `exposure-cpu-bench`, 600, 0, `'^exposure-cpu-bench: OK [1-9][0-9]* profiles, renders/perf/exposure_cpu.json$$'` | **yes** (D3) | B2a |
| 16 | `star-surface-test` (`mk/star-surfaces.mk:20`) | `tests/test_star_surface.gd` | rc,se,sum,to | rc 0, 29 s; `star-surface: OK (0 failures)` (uncounted) | `star-surface-test`, 900, 0, `'^star-surface: OK \([1-9][0-9]* passed, 0 failures\)$$'` | **yes** (D3) | B2a |
| 17 | `star-surface-bench` (`:29`) | `tools/star_surface_bench.gd` | rc,-,sum,- (Vulkan) | not run (GPU bench); source prints `star-surface-bench: sky GPU p50 off %.3f ms, on %.3f ms, delta %+.3f ms (limit +%.2f): OK` | `star-surface-bench`, 1800, 0, `'^star-surface-bench: sky GPU p50 .*: OK \([1-9][0-9]* frames\)$$'` | yes: append the sampled frame count (the zero probe refuses a timing line with no count) | **B2b** |
| 18 | `star-surface-capture` (`:35`) | `tools/star_surface_capture.gd` | rc,se,sum,- (windowed) | not run; source prints `star-surface-capture: OK %d frames` | `star-surface-capture`, 1800, 0, `'^star-surface-capture: OK [1-9][0-9]* frames$$'` | no | **B2b** |
| 19 | `navigation-usability-test` (`mk/navigation-usability.mk:3`) | `tests/test_navigation_usability.gd` | rc,se,sum,- | rc 0, 24 s; `navigation-usability: 17 checks 0 failures` | `navigation-usability-test`, 600, 0, `'^navigation-usability: [1-9][0-9]* checks 0 failures$$'` | no | B2a |
| 20 | `constellation-test` (`mk/constellations.mk:4`) | `tests/test_constellations.gd` | rc,se,sum,- | **rc 2**, 5 s; `constellations: 34 passed, 1 failures` (no large tier); after `make starmap-assets`: rc 0, 5 s, `constellations: 35 passed, 0 failures` | `constellation-test`, 600, 0, `'^constellations: [1-9][0-9]* passed, 0 failures$$'`; prerequisites `import starmap-assets` | no | B2a |
| 21 | `constellation-golden` (`:6`) | `tools/constellation_capture.gd` (`-- golden`) | rc,se,sum,- (windowed) | not run; source prints `constellation golden: %d cases, %d failures` | `constellation-golden`, 1800, 0, `'^constellation golden: 33 cases, 0 failures$$'`, then `&& test "$$(grep -c '^ok    G-CONST' $(SCRATCH)/constellation-golden.log)" = 33` kept | no | **B2b** |
| 22 | `constellation-capture` (`:8`) | `tools/constellation_capture.gd` (`-- capture`) | rc,se,sum,- (windowed) | not run; `constellation capture: %d images, %d failures` | `constellation-capture`, 1800, 0, `'^constellation capture: 32 images, 0 failures$$'` | no | **B2b** |
| 23 | `constellation-bench` (`:10`) | `tools/constellation_capture.gd` (`-- bench`) | rc,se,sum,- (windowed) | not run; `constellation bench: %d pairs, %d failures` | `constellation-bench`, 1800, 0, `'^constellation bench: 2 pairs, 0 failures$$'` | no | **B2b** |
| 24 | `npc-painted-ingest` (`mk/npc-painted.mk:4`) | `tools/npc_painted_assets.gd -- --ingest` | -,-,-,- (bare) | not run: writes the tracked `assets/characters/npcs/*.png` and `manifest.json`. The ingest also runs `_check()` and prints the same `painted-npc-assets: 5 identities, 25 poses, %d failures` | `npc-painted-ingest`, 1800, 0, `'^painted-npc-assets: 5 identities, 25 poses, 0 failures$$'` | no | **B2b** (authoring tool) |
| 25 | `npc-painted-assets-check` (`:7`) | `tools/npc_painted_assets.gd` | rc,se,sum,- | rc 0, 1 s; `painted-npc-assets: 5 identities, 25 poses, 0 failures` | `npc-painted-assets-check`, 600, 0, `'^painted-npc-assets: 5 identities, 25 poses, 0 failures$$'` | no (literal counts: Open question 2) | B2a |
| 26 | `npc-painted-test` (`:10`) | `tests/test_painted_npc_pilot.gd` | rc,se,sum,- | rc 0, 0 s; `painted-npc-pilot: 23 passed, 0 failures` | `npc-painted-test`, 600, 0, `'^painted-npc-pilot: [1-9][0-9]* passed, 0 failures$$'` | no | B2a |
| 27 | `npc-painted-capture` (`:13`) | `tools/npc_painted_capture.gd` | rc,se,sum,- (windowed) | not run; `painted-npc-capture: %d frames, %d failures` | `npc-painted-capture`, 1800, 0, `'^painted-npc-capture: 8 frames, 0 failures$$'` | no | **B2b** |
| 28 | `commons-civic-stage` (`mk/commons-civic.mk:4`) | `tools/commons_civic_stage.gd` | rc,-,sum,- | rc 0, 3 s; `commons-civic-stage: 4 configs, 3 raw GLBs, 4 raw PNGs, 0 failures` (writes the ignored `ship_commons_bundle/`) | `commons-civic-stage`, 600, 0, `'^commons-civic-stage: 4 configs, 3 raw GLBs, 4 raw PNGs, 0 failures$$'` | no (literal counts: Open question 2) | B2a |
| 29 | `commons-civic-assets-check` (`:7`) | `tests/test_commons_civic_assets.gd` | rc,-,sum,- | rc 0, 6 s; `commons-civic-assets: 21 passed, 0 failures` | `commons-civic-assets-check`, 600, 0, `'^commons-civic-assets: [1-9][0-9]* passed, 0 failures$$'` | no | B2a |
| 30 | `commons-civic-playtest-test` (`:11`) | `tests/test_commons_civic_playtest.gd` | rc,se,sum,- | rc 0, 9 s; `commons-civic-playtest: 18 passed, 0 failures` | `commons-civic-playtest-test`, 600, 0, `'^commons-civic-playtest: [1-9][0-9]* passed, 0 failures$$'` | no | B2a |
| 31 | `captain-anim-test` (`mk/captain-anim.mk:6`) | `tests/test_captain_anim.gd` | rc,se,sum,- | rc 0, 4 s; `captain-anim: 87 passed, 0 failures` | `captain-anim-test`, 600, 0, `'^captain-anim: [1-9][0-9]* passed, 0 failures$$'` | no | B2a |
| 32 | `bridge-operator-test` (`:11`) | `tests/test_bridge_operator_contact.gd -- --installed` | rc,se,sum,- | rc 0, 5 s; `bridge-operator-contact: 44 passed, 0 failures` | `bridge-operator-test`, 600, 0, `'^bridge-operator-contact: [1-9][0-9]* passed, 0 failures$$'` | no | B2a |
| 33 | `captain-frames-check` (`:16`) | `tools/captain_frames.gd -- --json …` | rc,-,sum,- | rc 0, 8 s (both runs); `captain-frames: ok` (uncounted) | `captain-frames-check`, 600, 0, `'^captain-frames: ok \([1-9][0-9]* frames\)$$'` | **yes** (D3) | B2a |
| 34 | `captain-frames-check` (`:17`) | `tools/captain_frames.gd -- --selftest` | rc,-,sum,- | (same target) `captain-frames: selftest ok` (uncounted) | `captain-frames-selftest`, 600, 0, `'^captain-frames: selftest ok \([1-9][0-9]* frames\)$$'` | **yes** (D3) | B2a |
| 35 | `captain-frames-ingest` (`:20`) | `tools/captain_frames.gd -- --ingest $(RAW) --guides $(GUIDES)` | -,-,-,- (bare) | not run: needs `RAW=` and `GUIDES=`, and writes `assets/characters/captain/anim/y0/*.webp` and the manifest (tracked). Its final line becomes `captain-frames: ok (N frames)` with D3 | `captain-frames-ingest`, 1800, 0, `'^captain-frames: ok \([1-9][0-9]* frames\)$$'` | (D3 covers it) | **B2b** (authoring tool) |
| 36 | `captain-chair-test` (`:26`) | `tests/test_captain_chair.gd` | rc,se,sum,- | rc 0, 4 s; `captain-chair: 12 passed, 0 failures` | `captain-chair-test`, 600, 0, `'^captain-chair: [1-9][0-9]* passed, 0 failures$$'` | no | B2a |
| 37 | `style-test` (`mk/style.mk:6`) | `tests/test_style.gd` | rc,se,sum,- | rc 0, 5 s; `style-test: 22 passed, 0 failures` | `style-test`, 600, 0, `'^style-test: [1-9][0-9]* passed, 0 failures$$'` | no | B2a |
| 38 | `ui-theme-check` (`:10`) | `tools/ui_theme_check.gd -- --strict` | rc,se,sum,- | rc 0, 4 s (all three runs); `ui-theme-check: ok` (uncounted; the earlier line is `ui-theme-check: contrast checked for 65 text/panel pairs over night and cream`) | `ui-theme-check`, 600, 0, `'^ui-theme-check: ok \([1-9][0-9]* files, [1-9][0-9]* text/panel pairs\)$$'` | **yes** (D3) | B2a |
| 39 | `ui-theme-check` (`:11`) | `… -- --strict --scan=res://tests/fixtures/ui_theme/seeded_override.gd` | rc,-,sum,- (wants rc 1) | (same target) `FAIL 1 hard-coded panel styles or colour overrides outside the theme (--strict)`, 0 `SCRIPT ERROR` | `ui-theme-neg-override`, 600, **1**, `'^FAIL 1 hard-coded panel styles'` | no (negative control: the zero probe exempts it) | B2a |
| 40 | `ui-theme-check` (`:12`) | `… -- --theme-builder=res://tests/fixtures/ui_theme/low_contrast_theme.gd` | rc,-,sum,- (wants rc 1) | (same target) `FAIL contrast 1.33:1 < 4.5 for HUDLabel.font_color on HUDPanel over efe3c8`, 0 `SCRIPT ERROR` | `ui-theme-neg-contrast`, 600, **1**, `'^FAIL contrast'` | no (negative control) | B2a |
| 41 | `style-capture` (`:17`) | `tools/style_capture.gd -- --tag=$(TAG)` | rc,se,-,- (windowed; **no summary check**) | not run (GPU window; needs `TAG=`); source prints `style-capture: %d frames, %d failures` | `style-capture`, 1800, 0, `'^style-capture: [1-9][0-9]* frames, 0 failures$$'` | no | **B2b** |
| 42 | `dressing-test` (`:21`) | `tests/test_dressing.gd` | rc,se,sum,- | rc 0, 6 s; `dressing-test: 10 passed, 0 failures` | `dressing-test`, 600, 0, `'^dressing-test: [1-9][0-9]* passed, 0 failures$$'` | no | B2a |

**Counts:** 28 rows in B2a (rows 2–7, 10, 12, 14–16, 19, 20, 25, 26, 28–34, 36–40, 42) and 14 in B2b (rows 1, 8, 9, 11, 13, 17, 18, 21–24, 27, 35, 41). The total is 42.

**The exact B2a recipe lines** (from the measured working tree, V7; recipe tabs shown as four spaces). Each replaces the row's Godot line and its check tail at the line given. The two multi-line removals are noted.

```make
# mk/ism.mk: dust-flash-test and map-ism-test each lose 3 lines (@mkdir, the Godot line, the test tail) for one
mk/ism.mk:41:    @$(SCRIPT_GATE) dust-flash-test $(SCRATCH)/dust-flash-test.log 600 '^dust-flash: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_dust_flash.gd
mk/ism.mk:44:    @$(SCRIPT_GATE) map-ism-test $(SCRATCH)/map-ism-test.log 600 '^ism-layer: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_ism_layer.gd
mk/ism.mk:72:    @$(SCRIPT_GATE) bubble-surface-test $(SCRATCH)/bubble-surface.log 600 '^bubble-surface: [1-9][0-9]* checks 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_bubble_surface.gd
mk/ism.mk:78:    @$(SCRIPT_GATE) ism-surfaces-test $(SCRATCH)/ism-surfaces.log 600 '^ism-surfaces: [1-9][0-9]* checks 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_ism_surfaces.gd
mk/planet-presentation.mk:4:    @$(SCRIPT_GATE) planet-presentation-test $(SCRATCH)/planet-presentation.log 600 '^planet-presentation: [1-9][0-9]* checks 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_planet_presentation.gd
mk/planet-presentation.mk:6:    @$(SCRIPT_GATE) moon-lifecycle-test $(SCRATCH)/moon-lifecycle.log 1800 '^moon-lifecycle: [1-9][0-9]* checks 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_moon_lifecycle.gd
mk/planet-presentation.mk:12:    @$(SCRIPT_GATE) planet-cpu-bench $(SCRATCH)/planet-cpu-bench.log 600 '^planet-cpu-bench: [1-9][0-9]* rows, renders/perf/planet_cpu.json$$' -- $(GODOT_SIM) --headless --path . --script tools/planet_cpu_bench.gd
mk/planet-presentation.mk:21:    @$(SCRIPT_GATE) exposure-frames-test $(SCRATCH)/exposure-frames.log 600 '^exposure-frames: [1-9][0-9]* checks 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_exposure_frames.gd
mk/planet-presentation.mk:28:    @$(SCRIPT_GATE) manual-exposure-test $(SCRATCH)/manual-exposure.log 600 '^manual-exposure: [1-9][0-9]* checks 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_manual_exposure.gd
mk/planet-presentation.mk:33:    @$(SCRIPT_GATE) exposure-cpu-bench $(SCRATCH)/exposure-cpu-bench.log 600 '^exposure-cpu-bench: OK [1-9][0-9]* profiles, renders/perf/exposure_cpu.json$$' -- $(GODOT_SIM) --headless --path . --script tools/exposure_cpu_bench.gd
# mk/star-surfaces.mk: the 4-line star-surface-test recipe (alarm 900, ok/FAIL grep, SCRIPT ERROR block, test tail) becomes one line
mk/star-surfaces.mk:20:    @$(SCRIPT_GATE) star-surface-test $(SCRATCH)/star-surfaces/test.log 900 '^star-surface: OK \([1-9][0-9]* passed, 0 failures\)$$' -- $(GODOT) --headless --path . --script tests/test_star_surface.gd
mk/navigation-usability.mk:3:    @$(SCRIPT_GATE) navigation-usability-test $(SCRATCH)/navigation-usability.log 600 '^navigation-usability: [1-9][0-9]* checks 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_navigation_usability.gd
mk/constellations.mk:3:constellation-test: import starmap-assets
mk/constellations.mk:4:    @$(SCRIPT_GATE) constellation-test $(SCRATCH)/constellations.log 600 '^constellations: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --quit-after 1200 --script tests/test_constellations.gd
mk/npc-painted.mk:7:    @$(SCRIPT_GATE) npc-painted-assets-check $(SCRATCH)/npc-assets.log 600 '^painted-npc-assets: 5 identities, 25 poses, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/npc-assets-engine.log --script tools/npc_painted_assets.gd
mk/npc-painted.mk:10:    @$(SCRIPT_GATE) npc-painted-test $(SCRATCH)/npc-pilot.log 600 '^painted-npc-pilot: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/npc-pilot-engine.log --script tests/test_painted_npc_pilot.gd
mk/commons-civic.mk:4:    @$(SCRIPT_GATE) commons-civic-stage $(SCRATCH)/commons-civic-stage.log 600 '^commons-civic-stage: 4 configs, 3 raw GLBs, 4 raw PNGs, 0 failures$$' -- $(GODOT) --headless --path . --script tools/commons_civic_stage.gd
mk/commons-civic.mk:7:    @$(SCRIPT_GATE) commons-civic-assets-check $(SCRATCH)/commons-civic-assets.log 600 '^commons-civic-assets: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_commons_civic_assets.gd
mk/commons-civic.mk:11:    @$(SCRIPT_GATE) commons-civic-playtest-test $(SCRATCH)/commons-civic-playtest.log 600 '^commons-civic-playtest: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_commons_civic_playtest.gd
mk/captain-anim.mk:6:    @$(SCRIPT_GATE) captain-anim-test $(SCRATCH)/captain-anim-test.log 600 '^captain-anim: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_captain_anim.gd
mk/captain-anim.mk:11:    @$(SCRIPT_GATE) bridge-operator-test $(SCRATCH)/bridge-operator-test.log 600 '^bridge-operator-contact: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_bridge_operator_contact.gd -- --installed
mk/captain-anim.mk:16:    @$(SCRIPT_GATE) captain-frames-check $(SCRATCH)/captain-frames.log 600 '^captain-frames: ok \([1-9][0-9]* frames\)$$' -- $(GODOT) --headless --path . --script tools/captain_frames.gd -- --json $(SCRATCH)/captain-frames.json
mk/captain-anim.mk:17:    @$(SCRIPT_GATE) captain-frames-selftest $(SCRATCH)/captain-frames-selftest.log 600 '^captain-frames: selftest ok \([1-9][0-9]* frames\)$$' -- $(GODOT) --headless --path . --script tools/captain_frames.gd -- --selftest
mk/captain-anim.mk:26:    @$(SCRIPT_GATE) captain-chair-test $(SCRATCH)/captain-chair-test.log 600 '^captain-chair: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_captain_chair.gd
mk/style.mk:6:    @$(SCRIPT_GATE) style-test $(SCRATCH)/style-test.log 600 '^style-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_style.gd
mk/style.mk:10:    @$(SCRIPT_GATE) ui-theme-check $(SCRATCH)/ui-theme-check.log 600 '^ui-theme-check: ok \([1-9][0-9]* files, [1-9][0-9]* text/panel pairs\)$$' -- $(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --strict
mk/style.mk:11:    @$(SCRIPT_GATE) ui-theme-neg-override $(SCRATCH)/ui-theme-neg-override.log 600 '^FAIL 1 hard-coded panel styles' 1 -- $(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --strict --scan=res://tests/fixtures/ui_theme/seeded_override.gd
mk/style.mk:12:    @$(SCRIPT_GATE) ui-theme-neg-contrast $(SCRATCH)/ui-theme-neg-contrast.log 600 '^FAIL contrast' 1 -- $(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --theme-builder=res://tests/fixtures/ui_theme/low_contrast_theme.gd
mk/style.mk:21:    @$(SCRIPT_GATE) dressing-test $(SCRATCH)/dressing-test.log 600 '^dressing-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_dressing.gd
```

Line numbers on the left are on the migrated tree. All other lines of the nine files are unchanged: `.PHONY`, `test:`/`ship-demo-ci:`/`golden:` joins, `@mkdir` lines outside `mk/ism.mk`, the `ui-theme-check` closing `@echo`, and every B2b row. `git diff --numstat` of the measured tree is in V12.

### D3. The five counted summaries (scripts)

These are the measured edits (V7, V8). Tabs are shown as four spaces, and blank context lines are empty. The blocks are a record; the executor types them, and they were run as shown.

```diff
--- a/tests/test_star_surface.gd
+++ b/tests/test_star_surface.gd
@@ -4,10 +4,12 @@ extends SceneTree
 var failures := 0
+var passes := 0

 func check(name: String, ok: bool, detail := "") -> void:
     if ok:
+        passes += 1
         print("  ok    %s" % name)
@@ -32,7 +34,7 @@ func _initialize() -> void:
-    print("star-surface: %s (%d failures)" % ["OK" if failures == 0 else "FAIL", failures])
+    print("star-surface: %s (%d passed, %d failures)" % ["OK" if failures == 0 else "FAIL", passes, failures])
--- a/tools/captain_frames.gd
+++ b/tools/captain_frames.gd
@@ -89,9 +89,9 @@ func _initialize() -> void:
     if mode == "selftest":
-        print("captain-frames: selftest ok" if ok else "captain-frames: FAIL selftest")
+        print("captain-frames: selftest ok (%d frames)" % report.frames.size() if ok else "captain-frames: FAIL selftest")
     else:
-        print("captain-frames: ok" if ok else "captain-frames: FAIL")
+        print("captain-frames: ok (%d frames)" % report.frames.size() if ok else "captain-frames: FAIL")
--- a/tools/ui_theme_check.gd
+++ b/tools/ui_theme_check.gd
@@ -45,11 +45,14 @@ func _run() -> void:
     var total := 0
+    var scanned := 0
+    var pair_count := 0
     var per_file := {}
     for root_path: String in scan:
         for f: String in _gd_files(root_path):
             if f == builder or f in allow.get("files", []):
                 continue
+            scanned += 1
@@ -84,6 +87,7 @@ func _run() -> void:
         var pairs: Array = b.text_pairs()
+        pair_count = pairs.size()
@@ -96,7 +100,7 @@ func _run() -> void:
-    print("ui-theme-check: %s" % ("FAIL" if fails else "ok"))
+    print("ui-theme-check: FAIL" if fails else "ui-theme-check: ok (%d files, %d text/panel pairs)" % [scanned, pair_count])
--- a/tools/exposure_cpu_bench.gd
+++ b/tools/exposure_cpu_bench.gd
@@ -31,4 +31,4 @@ func run()->void:
-    print("exposure-cpu-bench: OK");quit(0)
+    print("exposure-cpu-bench: OK %d profiles, renders/perf/exposure_cpu.json" % results.size());quit(0)
--- a/tools/planet_cpu_bench.gd
+++ b/tools/planet_cpu_bench.gd
@@ -30,4 +30,5 @@ func run()->void:
     var out:=FileAccess.open("res://renders/perf/planet_cpu.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"  "));print(JSON.stringify(report))
+    print("planet-cpu-bench: %d rows, renders/perf/planet_cpu.json" % rows.size())
     sky.queue_free();await process_frame;quit()
```

Also update the header comment at `tools/captain_frames.gd:19` (`Prints "captain-frames: ok" or FAIL lines.`) to `Prints "captain-frames: ok (N frames)" or FAIL lines.`. The measured run did not include this comment edit; it is comment-only.

Measured counts, each against an independent reading of the same run (V8):
- `star-surface: OK (54 passed, 0 failures)`: 54 = the base log's `^  ok` lines.
- `captain-frames: ok (50 frames)`: 50 = `jq '.frames | length' .godot/tmp/captain-frames.json`.
- `ui-theme-check: ok (49 files, 65 text/panel pairs)`: 65 = the script's own `contrast checked for 65 text/panel pairs` line.
- `exposure-cpu-bench: OK 2 profiles, …`: 2 records printed.
- `planet-cpu-bench: 6 rows, …`: 3 scenes × 2 cache modes.

No other tracked file reads any of the five old lines (V16).

### D4. Survivor S2: the zero probe in `tools/script_gate.sh`

**Rule.** A positive gate (`WANT_RC` 0) passes only if both hold:
- its matched summary line carries at least one nonzero standalone number;
- `SUMMARY_ERE` does **not** match the same line with every standalone number zeroed.

"Standalone" means a digit run that starts the line or follows a character outside `[A-Za-z0-9_.-]`. So target names such as `m4-smoke`, versions such as `v4.7` and hex such as `efe3c8` are never zeroed. Negative controls (`WANT_RC` > 0) are exempt, because their summary is a failure line by design.

What it refuses:
- `^.` on `x: 0 passed, 5 failures`;
- `[0-9]* passed` on `drill: 3 passed, 0 failures`;
- an uncounted `^v: ok$`;
- `^m4-smoke: [0-9]* passed$` on `m4-smoke: 0 passed`.

What it accepts:
- `[1-9][0-9]* passed`;
- an exact pinned count such as `33 cases`, which the zeroed `0 cases` does not match;
- `^AB=7x$` (zeroed `AB=0x`).

```diff
--- a/tools/script_gate.sh
+++ b/tools/script_gate.sh
@@ -35,6 +35,14 @@ se=$(grep -c 'SCRIPT ERROR' "$log")
 line=$(grep -E -- "$summary" "$log" | tail -n 1)
 [ -n "$line" ] || why="$why; no summary line matching $summary (rc $rc with no summary is a load failure, not a result)"
+# Zero probe (row 7x B2, judge survivor 2): a positive gate (WANT_RC 0) passes only on a summary that carries
+# a nonzero standalone number, and only when SUMMARY_ERE refuses the same line with every such number zeroed,
+# so a loose ERE (^. or [0-9]* passed) cannot pass a failing or empty run. Negative controls (WANT_RC > 0) are exempt.
+if [ -n "$line" ] && [ "$want" -eq 0 ]; then
+  zero=$(printf '%s\n' "$line" | sed -E 's/(^|[^A-Za-z0-9_.-])[0-9]+/\10/g')
+  if [ "$zero" = "$line" ]; then why="$why; summary '$line' carries no nonzero count (print one, e.g. N passed, 0 failures)"
+  elif printf '%s\n' "$zero" | grep -qE -- "$summary"; then why="$why; SUMMARY_ERE also matches the zeroed line '$zero' (bind the count: [1-9][0-9]*)"; fi
+fi
 if [ -n "$why" ]; then
--- a/tools/test_script_gate.sh
+++ b/tools/test_script_gate.sh
@@ -39,6 +39,11 @@
 case_ stub-notimeout 2 10 'TIMEOUT_S must be at least 1' sh "$gate" stub-t "$tmp/s10.log" 0 "$S" -- true
+# B2 zero probe (judge survivor 2): a loose ERE, a [0-9]* count and an uncounted summary all fail; a negative control is exempt
+case_ stub-loose 1 10 'SUMMARY_ERE also matches the zeroed line' sh "$gate" stub-loose "$tmp/s13.log" 5 '^.' -- sh -c 'echo "x: 0 passed, 5 failures"'
+case_ stub-weakcount 1 10 'SUMMARY_ERE also matches the zeroed line' sh "$gate" stub-weak "$tmp/s14.log" 5 '^drill: [0-9]* passed, 0 failures$' -- sh -c 'echo "drill: 3 passed, 0 failures"'
+case_ stub-uncounted 1 10 'carries no nonzero count' sh "$gate" stub-unc "$tmp/s15.log" 5 '^v: ok$' -- sh -c 'echo "v: ok"'
+case_ stub-namedigit 1 10 'carries no nonzero count' sh "$gate" stub-nd "$tmp/s16.log" 5 '^m4-smoke: [0-9]* passed$' -- sh -c 'echo "m4-smoke: 0 passed"'
```

The existing `stub-want1` (WANT_RC 1, `^v: FAIL$`) and `stub-env` (`^AB=7x$`) cases still pass. They are the exemption's and the name-digit rule's positive controls (V10). The probe also keeps every existing gate green: the five 7x gates re-ran ok under it (`sim-bridge` 110, `ui` 205, `area-test` 80, `test-bright-audit` 16, `star-catalogue-test` 40; V7b), and the 16 stub plus 6 Godot drill cases pass (`test-script-gate: ok (22 cases: 16 stub, 6 Godot)`, V7). `shellcheck -s sh` is clean, and the probe runs the same under `/bin/dash` (V10).

### D5. Survivor S1: one lint fixture row

The fix is to the negative control, not the lint. The lint already classes the line correctly (V11). Add to `tests/fixtures/script_gate/lint_negative.mk.txt`, after `quoted-separators`:

```make
gate-after:
    @$(GODOT) --headless --path . $(SCRIPT_GATE) --script tests/after.gd
```

The header says "three unguarded rows (bare-new, gate-after, the second command of mixed)". In `mk/script-gates.mk`, the control's `test "$$(grep -c '^script-gate-lint: unguarded' $$L)" = 2` becomes `= 3 && grep -q 'not on the baseline: gate-after tests/after.gd$$' $$L`. With the mutant lint, the inventory reads `gate-after tests/after.gd gated`. The control then counts 2 and fails: the mutant is killed (V11). The `$(SCRIPT_GATE)` must sit **between** the Godot token and `--script`. The lint reads only the text before each occurrence, so a `$(SCRIPT_GATE)` after `--script` never reaches it, and a first draft that put it at the line's end did not kill the mutant (V11). AC15 of the 7x doc now lists 7 fixture rows, not 6.

### D6. Baseline and pin

Delete the 28 B2a rows from `tools/script-gate-baseline.txt`. These are every row whose target is one of the 25 B2a targets. Each target's rows all migrate together: both `captain-frames-check` rows and all three `ui-theme-check` rows. Then set `SCRIPT_GATE_BASELINE_ROWS := 204` with the comment `… 232 after its five gates, 204 after B2a (28 rows in nine mk files).`. The command, run on the measured tree, is:

```sh
awk -F'\t' 'FNR==NR{d[$1]=1;next} /^#/ || !($1 in d)' b2a-targets.txt tools/script-gate-baseline.txt > b.new && mv b.new tools/script-gate-baseline.txt
grep -vc '^#' tools/script-gate-baseline.txt   # 204 (232 - 28; V12)
```

Here `b2a-targets.txt` holds the 25 target names of D2's B2a rows, one per line. `make script-gate-lint` then reads `ok (237 --script invocations: 33 through $(SCRIPT_GATE), 204 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)` (V12).

### D7. B2b: the 14 rows, and what blocks each

The invocations in D2 are designed but **not measured**. B2b's own sprint re-measures each row at its base before landing. That sprint is the next 7x row after B2a, or folded into B4/B5.

| Rows (D2 #) | Block | How B2b measures it |
|---|---|---|
| 8, 9, 11, 13 (`planet-*-golden`, `glow-planet-golden`, `exposure-frame-capture`), 18, 21–23, 27, 41 | A GPU window (`$(AUDIO_OFF)`, no `--headless`). The Studio GPU is shared with Ollama, which was at 94–99 % this iteration. CLAUDE.md asks for at most one GPU window at a time, and 10 windowed runs did not fit this iteration's budget. `style-capture` also needs `TAG=`. | One window at a time on a quiet rig (the iteration-63 quiet predicate: GPU idle and no one on the console), each bounded by the helper's own deadline. Four scripts need their count first (D2 rows 8, 9, 11, 13). Open each render the run writes, per CLAUDE.md. |
| 17 (`star-surface-bench`) | A Vulkan GPU bench that needs a quiet GPU to mean anything. Its timing line has no count, so the zero probe would refuse it. | Add the frame count to the summary, then run it on a quiet GPU. |
| 1 (`ism-bench`) | **Red at base on a loaded host**: boost delta 0.72 ms against the 0.5 ms limit, at load 3.3 (V5). Migrating it is harmless, because it is red either way, but its acceptance run cannot be made green on demand. | Run it on a quiet rig. If it is still red there, that is a performance finding for R1-ISM-DUST (AC19), not for 7x. |
| 24, 35 (`npc-painted-ingest`, `captain-frames-ingest`) | Authoring tools that **write tracked assets** (`assets/characters/npcs/`, `assets/characters/captain/anim/y0/`). `captain-frames-ingest` also needs `RAW=` and `GUIDES=` source directories. | In a throwaway clone (inside `.godot/tmp/`), never the working clone. Run, then show that `git status --porcelain` lists only the expected assets. Or wrap them without a run, and classify them as tools in B8. Recommendation: wrap them; their check already prints the summary the wrap needs. |

## Acceptance criteria

Run from the implementation root with `export PATH="$PWD/runtime/bin:$PATH"`, after `make deps import`. The expected values are as measured at `9e4d8231` plus this change (V7–V12). Counts may only grow. If the base has moved, the relations must still hold: the pin equals the pre-migration rows minus 28, and the lint is ok. Every command writes only inside the clone (`.godot/tmp/`, ignored `renders/perf/`, ignored `ship_commons_bundle/`). None uploads.

| # | Criterion and command | Expected output |
|---|---|---|
| AC1 | The ratchet: `make script-gate-lint; echo rc=$?` | `script-gate-lint: ok (237 --script invocations: 33 through $(SCRIPT_GATE), 204 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`, `rc=0` (V12) |
| AC2 | The pin bites: `make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=205 2>&1 \| tail -2` | `the baseline has 204 rows but SCRIPT_GATE_BASELINE_ROWS is 205: the pin moves with the rows, and only down`, `make: *** [script-gate-lint] Error 1` (V12) |
| AC3 | Helper stubs (the zero probe): `make script-gate-selftest 2>&1 \| grep -E 'stub-(loose\|weakcount\|uncounted\|namedigit\|want1\|env)\|cases'; echo rc=$?` | `ok   stub-loose (exit 1 …: SUMMARY_ERE also matches the zeroed line)`, `ok   stub-weakcount (…)`, `ok   stub-uncounted (exit 1 …: carries no nonzero count)`, `ok   stub-namedigit (…)`, `ok   stub-want1 …`, `ok   stub-env …`, `test-script-gate: ok (16 cases: 16 stub, 0 Godot)` (V10) |
| AC4 | The landed helper fails the new cases (S2 mutant, i.e. today's helper): `git show origin/main:tools/script_gate.sh > .godot/tmp/b2-old-gate.sh; SCRIPT_GATE_SH=.godot/tmp/b2-old-gate.sh SCRIPT_GATE_TMP=.godot/tmp/b2-ac4 sh tools/test_script_gate.sh > .godot/tmp/b2-ac4.out 2>&1; echo rc=$?; grep -c '^test-script-gate: FAIL stub-' .godot/tmp/b2-ac4.out` | `rc=1`, `4` (`FAIL 4 of 16 cases`; V10) |
| AC5 | Godot drills: `make script-gate-drill 2>&1 \| tail -1; echo rc=$?` | `test-script-gate: ok (22 cases: 16 stub, 6 Godot)`, `rc=0` (V7) |
| AC6 | Lint S1 fixture: `SCRIPT_GATE_FILES=tests/fixtures/script_gate/lint_negative.mk.txt SCRIPT_GATE_BASELINE_ROWS=0 sh tools/script_gate_lint.sh --inventory \| cut -f2-4 \| grep -c .; SCRIPT_GATE_FILES=tests/fixtures/script_gate/lint_negative.mk.txt SCRIPT_GATE_BASELINE_ROWS=0 sh tools/script_gate_lint.sh --inventory \| cut -f2-4 \| grep after; grep -c '^script-gate-lint: unguarded' .godot/tmp/script-gate/lint-negative.log` (after AC1) | `7`; `gate-after tests/after.gd ungated` (tab-separated); `3` (V11, V12) |
| AC7 | The lint mutant is killed: `sed 's/(sg \&\& sg < g + 1) ? "gated"/sg ? "gated"/' tools/script_gate_lint.sh > .godot/tmp/b2-lint-mut.sh; SCRIPT_GATE_FILES=tests/fixtures/script_gate/lint_negative.mk.txt SCRIPT_GATE_BASELINE=tests/fixtures/script_gate/lint_negative_baseline.txt SCRIPT_GATE_BASELINE_ROWS=2 SCRIPT_GATE_ALL_MAKEFILES="tests/fixtures/script_gate/lint_negative.mk.txt tools/stray.mk" sh .godot/tmp/b2-lint-mut.sh \| grep -c '^script-gate-lint: unguarded'` | `2` (the control in `make script-gate-lint` requires 3, so this mutant fails it; V11) |
| AC8 | **Every B2a target green:** `make dust-flash-test map-ism-test bubble-surface-test ism-surfaces-test planet-presentation-test moon-lifecycle-test planet-cpu-bench exposure-frames-test manual-exposure-test exposure-cpu-bench star-surface-test navigation-usability-test constellation-test npc-painted-assets-check npc-painted-test commons-civic-stage commons-civic-assets-check commons-civic-playtest-test captain-anim-test bridge-operator-test captain-frames-check captain-chair-test style-test ui-theme-check dressing-test > .godot/tmp/b2-ac8.out 2>&1; echo rc=$?; grep '^script-gate:' .godot/tmp/b2-ac8.out \| sort -u -t: -k2,2 \| wc -l; grep -c 'script-gate: [^ ]* FAIL' .godot/tmp/b2-ac8.out` | `rc=0`; `28` distinct gate names, one `ok` line each (`commons-civic-stage` also runs as a prerequisite; `sort -u` keeps one), with the counts of V7: `dust-flash: 29 passed`, `ism-layer: 22`, `bubble-surface: 16 checks`, `ism-surfaces: 18 checks`, `planet-presentation: 806 checks`, `moon-lifecycle: 71 checks`, `planet-cpu-bench: 6 rows`, `exposure-frames: 1364 checks`, `manual-exposure: 291 checks`, `exposure-cpu-bench: OK 2 profiles`, `star-surface: OK (54 passed`, `navigation-usability: 17 checks`, `constellations: 35 passed`, `painted-npc-assets: 5 identities, 25 poses`, `painted-npc-pilot: 23`, `commons-civic-stage: 4 configs …`, `commons-civic-assets: 21`, `commons-civic-playtest: 18`, `captain-anim: 87`, `bridge-operator-contact: 44`, `captain-frames: ok (50 frames)`, `captain-frames: selftest ok (50 frames)`, `captain-chair: 12`, `style-test: 22`, `ui-theme-check: ok (49 files, 65 text/panel pairs)`, `ui-theme-neg-override ok: FAIL 1 hard-coded …` (rc 1), `ui-theme-neg-contrast ok: FAIL contrast …` (rc 1), `dressing-test: 10`; then `0`. Budget about 7 min wall; `moon-lifecycle-test` alone is about 220 s. |
| AC9 | The five 7x gates still pass under the probe: `make ui area-test test-bright-audit star-catalogue-test sim-bridge 2>&1 \| grep '^script-gate:'` | 5 `ok` lines: `galaxy map: 205 passed`, `80 passed, 0 failed`, `test_bright_audit: 16 passed`, `test_star_catalogue: 40 passed`, `sim bridge: 110 passed` (V7b) |
| AC10 | **Parse-error drill, one per script class.** Classes: (c1) a plain `$(GODOT)` test; (c2) a `$(GODOT_SIM)` test; (c3) a tool with user arguments; (c4) a `WANT_RC 1` negative control. Each copy gets `var _b2_drill: int = undefined_name_b2` after its `extends` line: `d=.godot/tmp/b2drill; mkdir -p $d; for p in tests/test_dust_flash.gd:c1 tests/test_navigation_usability.gd:c2 tools/captain_frames.gd:c3 tools/ui_theme_check.gd:c4; do awk 'NR==1{print; print "var _b2_drill: int = undefined_name_b2"; next} {print}' ${p%%:*} > $d/${p##*:}.gd; done; AB="AILANG_BIN=$(command -v ailang)"; sh tools/script_gate.sh c1 $d/c1.log 600 '^dust-flash: [1-9][0-9]* passed, 0 failures$' -- godot --headless --path . --script $d/c1.gd; echo rc=$?; sh tools/script_gate.sh c2 $d/c2.log 600 '^navigation-usability: [1-9][0-9]* checks 0 failures$' -- "$AB" godot --headless --path . --script $d/c2.gd; echo rc=$?; sh tools/script_gate.sh c3 $d/c3.log 600 '^captain-frames: selftest ok \([1-9][0-9]* frames\)$' -- godot --headless --path . --script $d/c3.gd -- --selftest; echo rc=$?; sh tools/script_gate.sh c4 $d/c4.log 600 '^FAIL contrast' 1 -- godot --headless --path . --script $d/c4.gd -- --theme-builder=res://tests/fixtures/ui_theme/low_contrast_theme.gd; echo rc=$?` | each prints `script-gate: cN FAIL; … 1 SCRIPT ERROR line(s) (Godot exits 0 on a parse error); no summary line matching …` and then `rc=1`; c4 also says `rc 0, want 1`. Raw Godot on each copy exits `rc 0` with 1 `SCRIPT ERROR` and no summary (V9) |
| AC11 | **Runtime-error drill (the gap B2 closes, Problem 3):** `d=.godot/tmp/b2drill; mkdir -p $d; awk '{print} /^func _overlap_masks\(\) -> void:$/{print "\tprint(self.no_such_member_b2)"}' tests/test_dust_flash.gd > $d/c5.gd; godot --headless --path . --script $d/c5.gd > $d/c5.base.log 2>&1; rc=$?; test $rc = 0 && grep -q '^dust-flash: [1-9][0-9]* passed, 0 failures$' $d/c5.base.log && echo "old predicate: PASS"; sh tools/script_gate.sh c5 $d/c5.log 600 '^dust-flash: [1-9][0-9]* passed, 0 failures$' -- godot --headless --path . --script $d/c5.gd; echo rc=$?` | `old predicate: PASS` (the base `dust-flash-test` check passes a run that skipped 3 checks: `dust-flash: 26 passed, 0 failures`), then `script-gate: c5 FAIL; 1 SCRIPT ERROR line(s) …`, `rc=1` (V9) |
| AC12 | Counted summaries reject zero: `for e in '^star-surface: OK \([1-9][0-9]* passed, 0 failures\)$' '^captain-frames: ok \([1-9][0-9]* frames\)$' '^ui-theme-check: ok \([1-9][0-9]* files, [1-9][0-9]* text/panel pairs\)$' '^exposure-cpu-bench: OK [1-9][0-9]* profiles, renders/perf/exposure_cpu.json$' '^planet-cpu-bench: [1-9][0-9]* rows, renders/perf/planet_cpu.json$'; do printf '%s\n' 'star-surface: OK (0 passed, 0 failures)' 'captain-frames: ok (0 frames)' 'ui-theme-check: ok (0 files, 0 text/panel pairs)' 'exposure-cpu-bench: OK 0 profiles, renders/perf/exposure_cpu.json' 'planet-cpu-bench: 0 rows, renders/perf/planet_cpu.json' \| grep -cE -- "$e"; done` | five lines of `0` |
| AC13 | Policy gates and hygiene: `make uid-guard python-guard audio-silent-guard lint-precision && git diff --check origin/main && shellcheck -s sh tools/script_gate.sh tools/test_script_gate.sh tools/script_gate_lint.sh && echo gates-ok` | `gates-ok` (`uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, …)`, `audio-silent-guard: ok (79 windowed godot invocations; 5 allowlisted to keep sound)`, `lint-precision: ok …`; V12) |
| AC14 | Scope: `git diff --name-only origin/main \| grep -cvxE 'mk/(ism\|planet-presentation\|star-surfaces\|navigation-usability\|constellations\|npc-painted\|commons-civic\|captain-anim\|style\|script-gates)\.mk\|tools/(script_gate\.sh\|test_script_gate\.sh\|script-gate-baseline\.txt\|captain_frames\.gd\|ui_theme_check\.gd\|planet_cpu_bench\.gd\|exposure_cpu_bench\.gd)\|tests/test_star_surface\.gd\|tests/fixtures/script_gate/lint_negative\.mk\.txt\|design_docs/planned/r1/m4-7x-b2-script-gates.*\.md\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'; git diff --name-only origin/main -- Makefile mk/sound.mk mk/m45.mk mk/deck-layout.mk mk/earth-link.mk \| wc -l` | `0`, `0` |
| AC15 | The PR's GitHub fast tier: `gh pr checks <PR>`; `gh run view <run> --log \| grep -cE 'script-gate-lint: ok \(237 --script invocations: 33 through\|test-script-gate: ok \(16 cases: 16 stub, 0 Godot\)'` | `success`; `2`. This is the probe's first Linux, `dash` and GNU `sed -E` run. |

## Conflict surface

**Files touched (19):**
- `mk/ism.mk`, `mk/planet-presentation.mk`, `mk/star-surfaces.mk`, `mk/navigation-usability.mk`, `mk/constellations.mk`, `mk/npc-painted.mk`, `mk/commons-civic.mk`, `mk/captain-anim.mk`, `mk/style.mk`;
- `mk/script-gates.mk`;
- `tools/script_gate.sh`, `tools/test_script_gate.sh`, `tools/script-gate-baseline.txt`;
- `tests/fixtures/script_gate/lint_negative.mk.txt`;
- `tests/test_star_surface.gd`, `tools/captain_frames.gd`, `tools/ui_theme_check.gd`, `tools/planet_cpu_bench.gd`, `tools/exposure_cpu_bench.gd`;
- plus this doc and the sprint JSON.

No new `.gd`, so no new `.uid`. No `.py`.

**Open PRs** (V14, `gh pr diff <n> --name-only`; control: the files each PR is known to touch):

| PR | Files | Of ours | Control (`Makefile`, `mk/earth-link.mk`, `mk/m45.mk`, `mk/deck-layout.mk`) |
|---|---:|---:|---:|
| #373 | 57 | 0 | 2 |
| #379 | 99 | 0 | 3 |
| #380 | 31 | 0 | 1 |
| #384 | 11 | 0 | 1 |

**Not touched:** `Makefile`, `mk/sound.mk` (attended-only), `mk/m45.mk`, `mk/deck-layout.mk`, `mk/earth-link.mk`.

**Indirect conflict: the zero probe.** The open PRs add raw `--script` gates (#379 9, #384 2, #380 1; 7x V11). They already have to wrap them on rebase after 7x, and the probe adds one rule to that wrap: the summary regex must bind a nonzero count. The helper's failure message names the fix (`bind the count: [1-9][0-9]*`).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The zero probe reds a future healthy gate whose summary has no count (for example `foo: ok`). | That is the point: an uncounted summary cannot tell a full run from an empty one. The message names the fix. Negative controls are exempt. Exact pinned counts (`33 cases`) pass. |
| The probe's "standalone number" rule mis-zeroes a number that is part of a name, or fails to zero one. | Digits glued to `[A-Za-z0-9_.-]` are never zeroed (`m4-smoke`, `v4.7`, `x86_64`), and that is tested (`stub-namedigit`). A mis-zeroed name can only make the probe stricter: the ERE stops matching the zeroed line, and the gate passes as before. It cannot make a loose ERE pass. |
| GNU `sed -E` on CI behaves differently from macOS `sed -E` with `\1` in the replacement. | Both are POSIX ERE with back-references. `dash` was run here (V10). AC15 is the first Linux run and is a merge gate. |
| `moon-lifecycle-test` takes about 220 s, and the deadline is 1,800 s (8.2×). | Its base had no deadline at all. 1,800 s bounds a hang at 30 min instead of `rig_check`'s 7,200 s. If a loaded night pushes it past 1,800 s, raise it in one place. |
| Literal counts (`5 identities, 25 poses`; `4 configs, 3 raw GLBs, 4 raw PNGs`) pass the probe without counting anything at run time. | Their regexes pin exact text, and the scripts fail on any missing file (they list errors and quit 1). Open question 2 records the residue. |
| `constellation-test` gains `starmap-assets`, a network fetch (public bucket read, sha-checked). | `make test` already has that prerequisite (`Makefile:57`). Once the tier is present, the fetch is a no-op `tiers match` (0 s, V6). It never uploads. |
| The quieter output (one line per gate) hides bench numbers that `cat` used to show (`planet-cpu-bench`, `exposure-cpu-bench`). | The numbers stay in each log and in `renders/perf/*.json`, and the summary line names the JSON. |

## Open questions

None blocks the sprint.
- **OQ1. Where to enforce a counted regex: runtime probe or static lint? Default: the runtime probe (D4).**
  - The alternative is a lint rule that every `$(SCRIPT_GATE)` ERE with `WANT_RC` 0 contains `[1-9]`.
  - That rule is text-only and simple, but it would refuse the valid exact pins (`33 cases`, `5 identities`), and it needs an allowlist.
  - The runtime probe judges the actual line on every run, including gates added later.
- **OQ2. Literal counts in two scripts. Default: leave them in B2, and name them for B4.**
  - `tools/npc_painted_assets.gd` prints `5 identities, 25 poses` from a format string, and `tools/commons_civic_stage.gd` prints `4 configs, 3 raw GLBs, 4 raw PNGs`. Neither is computed.
  - Computing them (`POSES.size() × identities found`; the staged file counts) is a two-line edit each. It is deferred so that B2a stays exactly as measured.
- **OQ3. Should the B2b authoring tools be wrapped without a run? Default: wrap them in B2b with the same regexes, measured in a throwaway clone (D7).**
  - The alternative is to keep them on the baseline as permanent tool rows until B8 classifies tools.
- **OQ4. Should `ism-bench` be judged at all on a shared rig? Default: B2b migrates it unchanged. Its red is R1-ISM-DUST's performance question (AC19), not 7x's.**

## Estimated LOC per file

Measured with `git diff --numstat` on the applied tree (V12), as added/removed lines:

| File | + | − |
|---|---:|---:|
| `mk/ism.mk` | 4 | 8 |
| `mk/planet-presentation.mk` | 6 | 6 |
| `mk/star-surfaces.mk` | 1 | 4 |
| `mk/navigation-usability.mk` | 1 | 1 |
| `mk/constellations.mk` | 2 | 2 |
| `mk/npc-painted.mk` | 2 | 2 |
| `mk/commons-civic.mk` | 3 | 3 |
| `mk/captain-anim.mk` | 5 | 5 |
| `mk/style.mk` | 5 | 5 |
| `mk/script-gates.mk` | 3 | 3 |
| `tools/script_gate.sh` | 8 | 0 |
| `tools/test_script_gate.sh` | 5 | 0 |
| `tools/script-gate-baseline.txt` | 0 | 28 |
| `tests/fixtures/script_gate/lint_negative.mk.txt` | 3 | 1 |
| `tests/test_star_surface.gd` | 3 | 1 |
| `tools/captain_frames.gd` | 2 (+1 comment) | 2 (+1) |
| `tools/ui_theme_check.gd` | 5 | 1 |
| `tools/planet_cpu_bench.gd` | 1 | 0 |
| `tools/exposure_cpu_bench.gd` | 1 | 1 |
| **Total** | **60 (+1)** | **73 (+1)** |

About an hour of work for a mid-tier model. Every line above was applied and run once. The wall time is dominated by AC8 (about 7 min) and AC9 (`sim-bridge` about 95 s).

## Verification log

Run at `9e4d8231` on 2026-11-04, about 21:20–21:50 local, in `/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter70`, on the Apple Studio:
- Godot `4.7.2.stable.official.ed1daf0bf`; AILANG v0.56.1 (`runtime/bin`; `PATH=$PWD/runtime/bin:$PATH`); `/bin/dash`, `/opt/homebrew/bin/shellcheck`.
- 1-min load 2.1 at the start and 7.4 at the end (other agents and the mission loop on the host).
- Every `make` run sat under a process-group supervisor: the perl from `tools/script_gate.sh`, copied to `/tmp/iter70_designer/sup.pl`, with 900–2,400 s ceilings. The runs went serially in background loops, polled in bounded `date +%s` loops.
- The **windowed rows were not run** (B2b; GPU shared), nor the **ingest targets** (they write tracked assets). Nothing that uploads was run. `make starmap-assets` is a public-bucket **read** into the ignored `data/starmap/`.

| # | Claim | Command | Observed |
|---|---|---|---|
| V1 | The lint at base | `make script-gate-lint` (before and after the measurement round) | `script-gate-lint: ok (237 --script invocations: 5 through $(SCRIPT_GATE), 232 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`, both times |
| V2 | 42 B2 rows, their lines and flags | `make script-gate-inventory > inv.tsv; wc -l < inv.tsv; grep -E '^mk/(ism\|planet-presentation\|star-surfaces\|navigation-usability\|constellations\|npc-painted\|commons-civic\|captain-anim\|style)\.mk:' inv.tsv \| wc -l` | `237` (control: the whole inventory); `42`. Every row is `ungated`, with the file:line and flags in D2's "Today" column (for example `mk/ism.mk:42 dust-flash-test tests/test_dust_flash.gd ungated rc,-,sum,-`; `mk/planet-presentation.mk:12 planet-cpu-bench tools/planet_cpu_bench.gd ungated -,-,-,-`) |
| V3 | The current recipes and the variables | `cat -n mk/{ism,planet-presentation,star-surfaces,navigation-usability,constellations,npc-painted,commons-civic,captain-anim,style}.mk`; `grep -nE '^(GODOT\|GODOT_SIM\|AUDIO_OFF\|SCRATCH)\b' Makefile` | as summarized in Problem 2 and D2 ("Today"); `GODOT ?= godot` (1), `GODOT_SIM = AILANG_BIN="$$(command -v $(AILANG))" $(GODOT)` (6), `AUDIO_OFF := --audio-driver Dummy` (10), `SCRATCH := .godot/tmp` (13) |
| V4 | What each script prints | `grep -nE 'print…(fail\|passed\|checks\|ok\|OK)' <each B2 script>`; `cat tools/constellation_capture.gd`; `grep -n print tools/{ism_service_bench,planet_cpu_bench,exposure_cpu_bench,star_surface_bench,ui_theme_check,captain_frames}.gd` | the format strings quoted in D2. `planet_cpu_bench.gd` prints only `JSON.stringify(report)`. `constellation_capture.gd` delegates to `tools/constellation_golden.gd` (`constellation golden: %d cases, %d failures`, `capture: %d images`, `bench: %d pairs`). `planet_transition_golden.gd:59` prints the literal `86 samples`. Write targets: `renders/…` (ignored, `.gitignore:2`), `.godot/tmp/ism`, `ship_commons_bundle/` (ignored, `.gitignore:32`, `git check-ignore -v` confirms). The ingests write `res://assets/characters/npcs` and `…/captain/anim/y0` (tracked) |
| V5 | Base runs: every headless B2 make target | `sh run_base.sh <26 targets>` (each `perl sup.pl 900 make --no-print-directory $t`, rc and wall time to `results.tsv`); then per row `grep -c 'SCRIPT ERROR' <log>` and the last summary line from the row's own log; for `ism-bench`, `jq '.passes, .plan_delta_median_ms, .tick_delta_median_ms, .boost.delta_median_ms, .brake.delta_median_ms' .godot/tmp/ism/service-benchmark.json` | every target **rc 0** except `constellation-test` **rc 2** (5 s) and `ism-bench` **rc 2** (203 s); wall times and summary lines as in D2's "Base" column; **0 `SCRIPT ERROR`** in every log (including both negative-control logs and the two bench outputs). `ism-bench`: `false`, `3.669`, `0.3238…`, `0.7206…`, `0.0381…` (limits 20, 0.5, 0.5, 0.5); load 3.28 |
| V6 | `constellation-test` red for a missing tier, green with it | `sed -n 1,14p .godot/tmp/constellations.log`; `grep -n 'resolve uniquely' tests/test_constellations.gd`; `make starmap-assets`; `make constellation-test`; `grep -nE 'starmap-assets\|ship-demo-ci' Makefile` | `WARNING: starfield: res://data/starmap/stars_large.bin is missing (make starmap-assets); the sky uses the medium tier …`, `ERROR: all 23 source identities resolve uniquely` (`test_constellations.gd:21`); fetch `rc=0 0 s`, `fetched data/starmap/stars_large.bin <- https://storage.googleapis.com/stapledons-voyage-assets/starmap/0c706d9b….bin`, `starmap-assets: tiers match data/starmap/SHA256SUMS`; then `rc=0 5 s`, `constellations: 35 passed, 0 failures`, 0 `SCRIPT ERROR`; `Makefile:57 test: … deps starmap-assets import …`, `Makefile:1151 test: ship-demo-ci` |
| V7 | The migrated tree, end to end | the D2/D3/D4/D5/D6 edits applied to the working clone's tracked files (`/tmp/iter70_designer/mig/apply.sh`, then the helper, test, fixture, baseline and pin edits); `sh run_mig.sh <25 B2a targets> script-gate-drill`; `grep -h '^script-gate:' <each>.out` | all 26 runs **rc 0**. The 28 gate lines, verbatim: `dust-flash-test ok: dust-flash: 29 passed, 0 failures (rc 0, no SCRIPT ERROR, 1 s of 600 s)`; `map-ism-test ok: ism-layer: 22 passed, 0 failures (… 1 s …)`; `bubble-surface-test ok: bubble-surface: 16 checks 0 failures (… 0 s …)`; `ism-surfaces-test ok: ism-surfaces: 18 checks 0 failures (… 1 s …)`; `planet-presentation-test ok: planet-presentation: 806 checks 0 failures (… 4 s …)`; `moon-lifecycle-test ok: moon-lifecycle: 71 checks 0 failures (… 220 s of 1800 s)`; `planet-cpu-bench ok: planet-cpu-bench: 6 rows, renders/perf/planet_cpu.json (… 2 s …)`; `exposure-frames-test ok: exposure-frames: 1364 checks 0 failures (… 4 s …)`; `manual-exposure-test ok: manual-exposure: 291 checks 0 failures (… 9 s …)`; `exposure-cpu-bench ok: exposure-cpu-bench: OK 2 profiles, renders/perf/exposure_cpu.json (… 5 s …)`; `star-surface-test ok: star-surface: OK (54 passed, 0 failures) (… 30 s of 900 s)`; `navigation-usability-test ok: navigation-usability: 17 checks 0 failures (… 5 s …)`; `constellation-test ok: constellations: 35 passed, 0 failures (… 3 s …)`; `npc-painted-assets-check ok: painted-npc-assets: 5 identities, 25 poses, 0 failures (… 1 s …)`; `npc-painted-test ok: painted-npc-pilot: 23 passed, 0 failures (… 0 s …)`; `commons-civic-stage ok: commons-civic-stage: 4 configs, 3 raw GLBs, 4 raw PNGs, 0 failures` (3 runs, two as prerequisites); `commons-civic-assets-check ok: commons-civic-assets: 21 passed, 0 failures (… 2 s …)`; `commons-civic-playtest-test ok: commons-civic-playtest: 18 passed, 0 failures (… 5 s …)`; `captain-anim-test ok: captain-anim: 87 passed, 0 failures (… 1 s …)`; `bridge-operator-test ok: bridge-operator-contact: 44 passed, 0 failures (… 2 s …)`; `captain-frames-check ok: captain-frames: ok (50 frames) (… 3 s …)`; `captain-frames-selftest ok: captain-frames: selftest ok (50 frames) (… 5 s …)`; `captain-chair-test ok: captain-chair: 12 passed, 0 failures (… 3 s …)`; `style-test ok: style-test: 22 passed, 0 failures (… 4 s …)`; `ui-theme-check ok: ui-theme-check: ok (49 files, 65 text/panel pairs) (… 1 s …)`; `ui-theme-neg-override ok: FAIL 1 hard-coded panel styles or colour overrides outside the theme (--strict) (rc 1, no SCRIPT ERROR, 1 s of 600 s)`; `ui-theme-neg-contrast ok: FAIL contrast 1.33:1 < 4.5 for HUDLabel.font_color on HUDPanel over efe3c8 (rc 1, …)`; `dressing-test ok: dressing-test: 10 passed, 0 failures (… 4 s …)`. Drill: `ok   make-sim-parse (exit 2 in 1 s: …)`, `test-script-gate: ok (22 cases: 16 stub, 6 Godot)`, 23 s |
| V7b | The 7x gates under the probe | `sh run_mig2.sh ui area-test test-bright-audit star-catalogue-test sim-bridge` (migrated tree) | all rc 0: `ui ok: galaxy map: 205 passed, 0 failures (… 6 s …)`, `area-test ok: 80 passed, 0 failed (… 23 s …)`, `test-bright-audit ok: test_bright_audit: 16 passed, 0 failed`, `star-catalogue-test ok: test_star_catalogue: 40 passed, 0 failed`, `sim-bridge ok: sim bridge: 110 passed, 0 failures (rc 0, no SCRIPT ERROR, 94 s of 900 s)` |
| V8 | The new counts equal an independent reading | `grep -c '^  ok' base/star-surface-test.out`; `jq '.frames \| length' .godot/tmp/captain-frames.json`; `grep 'contrast checked' .godot/tmp/ui-theme-check.log` | `54`; `50`; `ui-theme-check: contrast checked for 65 text/panel pairs over night and cream` (base and migrated) |
| V9 | Parse-error drills per class (raw and gated); the runtime-error gap | `/tmp/iter70_designer/drill/drill.sh` (AC10's copies and commands); AC11's commands | c1 `raw: rc 0 SCRIPT ERROR 1, summary lines 0`, `c1: exit 1 …: script-gate: c1 FAIL; 1 SCRIPT ERROR line(s) (Godot exits 0 on a parse error); no summary line matching ^dust-flash: …`; c2, c3 the same (c2 with `AILANG_BIN=…`, c3 `-- --selftest`); c4 `raw: rc 0 SCRIPT ERROR 1`, `c4: exit 1 …: FAIL; rc 0, want 1; 1 SCRIPT ERROR line(s) …; no summary line matching ^FAIL contrast`. c5: `base recipe shape: rc 0, SCRIPT ERROR 1, summary: dust-flash: 26 passed, 0 failures`, `base dust-flash-test predicate: PASS (the gap)`, `SCRIPT ERROR: Invalid access to property or key 'no_such_member_b2' on a base object of type 'SceneTree (c5_runtime_body.gd)'.`, `script-gate: c5 FAIL; 1 SCRIPT ERROR line(s) …` |
| V10 | The zero probe: new cases, mutant, dash, shellcheck | scratch copies: the probe added to `script_gate.sh`, the 4 cases to `test_script_gate.sh`; `SCRIPT_GATE_SH=<new> … sh <new test>`; `SCRIPT_GATE_SH=tools/script_gate.sh` (landed) with the new test; `dash script_gate.sh d1 … '^.' -- sh -c 'echo "x: 0 passed, 5 failures"'`, d2 `[1-9]` on `drill: 3 passed`, d3 `^AB=7x$`; `shellcheck -s sh` | new: 16 of 16 `ok` (`stub-loose (exit 1 in 0 s: SUMMARY_ERE also matches the zeroed line)`, `stub-weakcount (…)`, `stub-uncounted (exit 1 in 1 s: carries no nonzero count)`, `stub-namedigit (…)`, `stub-want1 … ok: v: FAIL (rc 1`, `stub-env … AB=7x`), `test-script-gate: ok (16 cases: 16 stub, 0 Godot)` in 11 s. Landed helper: exactly `FAIL stub-loose`, `FAIL stub-weakcount`, `FAIL stub-uncounted`, `FAIL stub-namedigit` (`exit 0`), `FAIL 4 of 16 cases`. dash: d1 `rc=1`, `SUMMARY_ERE also matches the zeroed line 'x: 0 passed, 0 failures'`; d2 `rc=0`; d3 `rc=0`; the whole test under dash: 16 cases ok. shellcheck `sc=0`. Base selftest for contrast: `test-script-gate: ok (12 cases: 12 stub, 0 Godot)`. Its `Terminated: 15 sleep "$c"` line is printed at base too: it is the A2 control's own kill |
| V11 | S1: the lint is right, the mutant survives today, the fixture kills it | a fixture copy with `gate-after:` / `@$(GODOT) --headless --path . $(SCRIPT_GATE) --script tests/after.gd`; `--inventory \| cut -f2-4` and the full negative run with the landed lint and with the mutant (`sed 's/(sg \&\& sg < g + 1) ? "gated"/sg ? "gated"/'`, 1 line changed); the landed fixture under the mutant | landed lint: `gate-after tests/after.gd ungated`; the negative run `rc=1`, `3` unguarded including `not on the baseline: gate-after tests/after.gd`. Mutant: `gate-after tests/after.gd gated`, `2` unguarded (the control's `= 3` fails). The landed fixture under the mutant: `2` (today's control passes: the survivor). A first draft with `$(SCRIPT_GATE)` at the line's end stayed `ungated` under the mutant too, because the lint reads only the text before `--script`; hence D5's placement |
| V12 | The applied tree: lint, pin, hygiene, size; then restored | on the migrated tree: `make script-gate-lint`; `make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=205 \| tail -2`; `grep -vc '^#' tools/script-gate-baseline.txt`; `make uid-guard python-guard audio-silent-guard lint-precision`; `git diff --check`; `shellcheck -s sh tools/script_gate.sh tools/test_script_gate.sh tools/script_gate_lint.sh`; `git diff --numstat`; then `git checkout -- mk tools tests; git status --porcelain \| wc -l`; `ps` for leftover Godot or `ailang run` from this clone | `script-gate-lint: ok (237 --script invocations: 33 through $(SCRIPT_GATE), 204 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`; `the baseline has 204 rows but SCRIPT_GATE_BASELINE_ROWS is 205: …`, `make: *** [script-gate-lint] Error 1`; `204`; `uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`, `audio-silent-guard: ok (79 windowed godot invocations; 5 allowlisted to keep sound)`, `lint-precision: ok (positive control matched 6 lines; …)`; diff check clean; shellcheck `0`; numstat as in [Estimated LOC per file](#estimated-loc-per-file) (19 files, `60 insertions(+), 73 deletions(-)`); restore: `0` status lines, `0` leftover processes |
| V13 | Which B2 targets are in `test`, `ship-demo-ci`, `golden` | for each B2 target, `grep -hE "^(test\|ci-fast\|ship-demo-ci\|golden\|capture\|sim\|ui)[a-z-]*:.*(^\|[ ])$t( \|$)" Makefile mk/*.mk` | `test`: every B2a test except the `ship-demo-ci` ones and the two benches (it also holds `dust-flash-test` and `map-ism-test`); `ship-demo-ci`: `planet-presentation-test`, `moon-lifecycle-test`, `exposure-frames-test`, `manual-exposure-test`, `constellation-test`; `golden`: `constellation-golden`; none: `ism-bench`, `planet-cpu-bench`, `exposure-cpu-bench`, the captures, the goldens other than `constellation-golden`, the ingests (control: `star-surface-test` → `test`) |
| V14 | No open PR touches a file of this batch | `gh pr list --state open`; for #373 #379 #380 #384: `gh pr diff <n> --name-only > prN.txt; grep -cxE '<the 19 files>' prN.txt; grep -cxE 'Makefile\|mk/earth-link.mk\|mk/m45.mk\|mk/deck-layout.mk' prN.txt` | open: 384, 380, 379, 373. Files 57/99/31/11; ours `0` each; control `2`, `3`, `1`, `1` |
| V15 | No `test-script-gate` target | `grep -nE '^test-script-gate:\|^script-gate-(selftest\|drill):' Makefile mk/*.mk` | only `mk/script-gates.mk:42:script-gate-selftest:` and `:45:script-gate-drill:` (the known positives); no `test-script-gate:` |
| V16 | No other consumer of the five old summary lines | `git ls-files \| grep -vE '^\.ailang/\|^design_docs/\|^changelogs/' \| xargs grep -nE "captain-frames: (selftest )?ok\|star-surface: OK\|ui-theme-check: ok\|exposure-cpu-bench: OK\|planet-cpu-bench:"` on the migrated tree | only the new recipe lines and the scripts' own print lines, plus the comment `tools/captain_frames.gd:19` (updated in D3). Control: `git ls-files tools/captain_frames.gd tools/ui_theme_check.gd \| wc -l` = `2` |
