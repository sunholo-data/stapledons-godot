# free-nav-stop's I checks: the guard's edges (7an)

**Status:** Planned 2026-11-12 (mission iteration 89, designer Opus 5.5). Measured at `origin/main` `b96b2d60`. **Release:** r1. **Milestone:** none (suite hygiene, queue row **7an**).
**Priority:** low (clause 5 hygiene). Nothing is red: `make free-nav-stop-test` is `54 passed, 0 failures` at the base (V1). The row asks whether the checks that 7ak left behind can fail for the right reason. Measured here: two of them could not.
**Implements:** row 7an of the charter (`design_docs/stapledon-mission.md`, Queue, line 531). The row comes from the design follow-ups F1–F3 and the judge findings of the parent row 7ak ([`design_docs/implemented/r1/m4-7ak-free-nav-stop-eye.md`](../../implemented/r1/m4-7ak-free-nav-stop-eye.md)). It guards R1-SHIP-UI / D-58: the I key offers a free-navigation destination as its finite body, not as the hidden catalogue point. No design-repo feature doc changes, and no physics-spec formula, shader or table is involved.
**Depends on:** nothing.
**Estimated LOC:** 42 lines in two test files (`git apply --stat`: `2 files changed, 40 insertions(+), 2 deletions(-)`, V25), plus a changelog fragment. No product, asset, Makefile, shader, golden or `*.ail` change. Appendix A has the exact patch, so the doc does not depend on `/tmp`.
- `tests/test_free_nav_stop.gd`: +35 −2. That is three helpers (`sky_hides`, `eye_clear`, `catalogue_rows_lit`) and two preloads; the two clear-eye checks call `eye_clear`; and three checks are new (two sky checks, one catalogue-row check).
- `tests/test_ship_star_identification.gd`: +5 (one fixture check for the `pinned_ids` filter).

## Game vision alignment

Scored by hand against `../stapledons-design/vision/core-pillars.md` (pillars 1–6) and `physics/relativity-spec.md`, as the 7ak and 7am tables were. The run is unattended, so the `game-vision-designer` skill held no interview.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | Nothing a player sees or hears changes. |
| The Ship Is Home | 0 | 0 | No scene, furniture or asset changes. The course monitor stays where #379 put it. |
| Grounded Strangeness | 0 | 0 | The checks keep guarding the D-58 contract (a stop's star is a finite body with an inferred radius). They protect an existing feature and add nothing. |
| We Are Not Built For This | 0 | 0 | No crew or AI change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, lookup table or render change. Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **Go.** Neutral suite hygiene. Every 0 means "not touched", so there is no stop for a human. |

## Problem

The parent row 7ak made `make free-nav-stop-test` green by moving its I-check eye to G-M4-S3's captain eye `(11, 82, -4.8)`. It also added a clear-eye check after each `update_candidates()`. Each sub-item of the row was re-measured here at `b96b2d60`.

1. **(a) The clear-eye check sees only one of I's two occluders (V2).** `_add_body_candidates` drops a body for one of two reasons. The first is `sv.occludes_direction(dir, b.id, dist)`, the sky renderer's globe and ring test (`ui/ship_star_identification.gd:130`). The second is `occlusion.blocked(...)`, the ship BVH (`:132`). Catalogue stars have the same pair at `:101` and `:103`. The 7ak check asks only the BVH. If a nearer body covers the destination, the I check fails and the only message is `I offers … (N candidates)`. Measured with a mutant: the sky renderer stops skipping the body itself (`planets/system_view.gd:793`, `if b.id == skip_id: continue` → `pass`). On the base, only the two opaque I checks fail (`16 passed, 2 failures`, V10).
   - *Premise correction:* the row (and the controller's check) put these filters at `:96` and `:127`. At `b96b2d60` they are at `:101` and `:130`. Line 96 is `if not sample.visible:continue` and line 127 is a comment (V2).
2. **(b) The clear-eye check is order-dependent (V11).** `StarOcclusion.blocked()` reads the node transforms cached by the last `refresh(camera)` (`ui/star_occlusion.gd:36-43, 71-80`), and only `update_candidates()` calls `refresh` (`ui/ship_star_identification.gd:76`). Measured on the base: the check is moved before `update_candidates()` and the course monitor is shifted +2.418 m onto the eye's line (7ak's R2). The first stop's clear-eye check then passes (`ok the fixed eye looks ahead …`) while `FAIL I offers … (41 candidates)` shows the eye is blocked (`15 passed, 3 failures`). The test has no comment saying where the check must stand (`tests/test_free_nav_stop.gd:60-61`, `:79-80`, V3).
3. **(c) The "not the hidden catalogue point" half guards a mechanism the flow never uses (V4, V5, V12–V14).**
   - At the Barnard stop, `pinned_ids` is empty and `pin_noops` and `pin_fallbacks` are both 0 (V4): `pin_destination` was never called. Outside tests and tools, its only caller is `demos/solar_departure.gd:65` (V26). The free-navigation stop never pins, so the `pinned_ids` filter at `:62` cannot be reached from this test. Dropping it leaves the suite green (`23 passed, 0 failures` on the short copy, V14), as 7ak's F2 found.
   - *Premise correction:* 7ak's F2 guessed that "the per-record duplicate count below it" also keeps the catalogue point out. It does not: exactly one sky row maps to that record (`rows_for_record=1`, V4). What hides the point is the body's **catalogue replacement**. `set_catalogue_replacements` zeroes the flux of the row under its bare Gaia alias (`sky/starfield.gd:110`, `:125-128`). The row is still eligible (`eligible=true`, V4), but it draws no light (`flux=0.0 visible=false`), so `:96` drops it.
   - There is a second layer: the body's own globe covers the point (`:101`, with `skip_id` empty because the bare row has no replacement-source entry). With the bare-alias line removed, the row is lit (`lit ["4472832130942575872"]`) and the I check still passes with 44 candidates (V12). Only with `:101` removed as well does the I check fail, with 46 candidates (V13).
   - So no single product mutant turns that half red. This is defence in depth, and the check cannot be blamed for it. What is missing is a check on each layer.
4. **(d) Other tests on `(8, 82, -4.8)` (V19, V21).** 14 tracked test files use the lift's landing. In 11 of them it is a position (lift, floor, movement, consoles, physics feet), and none asks for a sightline. Three touch I: `test_ship_star_identification.gd` (ship occlusion off, `demo.sky_only = true`), `test_ship_ui.gd` and `test_camera_director.gd`. No test file outside `test_free_nav_stop.gd` calls `occlusion.blocked`. The nightly `rig/full` on `b96b2d60` names one red target, `bridge-operator-test`, which is not one of these. No change is needed. See F3.
5. **(e) A cheap `ci-fast` sightline proxy is not cheap (V16, V17).** `ci-fast` runs no Godot script today. Its only `--headless` text is a printf fixture inside the audio guard. The real lateral clearance of the fixed eye, measured in the ship BVH, is **0.55 m** (the course monitor's first blocking +x shift, frame and face together, in 0.025 m steps). The face rectangle alone first blocks at **0.75 m**. A manifest-only proxy sees only the face rectangle (`FACE_M` 4.0 × 2.25 m), so it would overstate the margin by 0.2 m and miss the frame that actually blocks first. A faithful check needs the frame mesh, which means loading the ship demo in `ci-fast` for the first time. That is a new kind of `ci-fast` step and not test hygiene. See F1.
6. **(f) The 2 s `step_timeout` is product code with a tested contract (V20).** The 2000 ms deadline is a literal in `bridge/sim_bridge.gd:296, 357, 387`. Its bound is asserted by `tests/test_sim_bootstrap.gd:28` and `tests/test_sim_bridge.gd:314`. Here the full target ran in 634 s (base, V1) and 433 s (prototype, V8) at load 6–23, and stayed green. The row's 38/16 and 27/23 figures were measured by MiniMax inside its sandbox at load 30–60. They are not reproduced here and nothing below relies on them. See F2.

## Goals and non-goals

**Goals.**
- **(a)** A sky-renderer occlusion of the destination fails with its own message, at both stops.
- **(b)** The clear-eye check means the same wherever it stands in the test. Moved before `update_candidates()` with the monitor on the eye's line, it fails.
- **(c)** Each layer that hides a stop's catalogue point has a check that a single-layer mutant turns red:
  - the replacement (the row is dark), in `test_free_nav_stop.gd`;
  - the `pinned_ids` filter, in a fixture where a pin really happens (`test_ship_star_identification.gd`).
- The free-navigation check also asserts that this flow did not pin. The statement "the pinned filter is unreachable here" is then a checked premise and not a comment.

**Non-goals.**
- Any change under `ui/`, `demos/`, `sky/`, `planets/`, `interior/`, `bridge/`, `sim/`, `audio/`, `data/`, `assets/`, shaders, captures or goldens, and any `*.ail` or Makefile change. (The mutation ACs edit `ui/`, `sky/` and `planets/` only for one run each, and restore them with `git checkout --`.)
- Moving the course monitor, the landing or the eye. From the lift's landing, the course screen still hides a destination that is dead ahead at arrival. That view belongs to the deck-layout row (D-148's family of #379 placements), not to a test.
- (d), (e) and (f): see Follow-ups.

## Design

### Classification: TEST-ONLY, loop work

Nothing a player sees or hears changes. Every change is a check or a helper in a test file.

### T1 (a). The sky check (`tests/test_free_nav_stop.gd`, after each clear-eye check)

`sky_hides(demo, id)` asks `sv.occludes_direction` exactly as `_add_body_candidates` does. It uses the same `last_system` body, the same `StarLight.apparent_direction`, the body's own id as `skip_id`, and its float64 distance. It returns true when the system view is absent or hidden, because I then offers no body at all. The new checks are `the sky draws the destination with no nearer body over it` (Barnard, body `cat:<id>`) and `the sky draws alpha Cen A with no nearer body over it`.

### T2 (b). The clear-eye check refreshes its own BVH

`eye_clear(demo, ident)` calls `ident.occlusion.refresh(demo.camera)` and then `blocked(...)` on the centre ray. `refresh` rebuilds only the active list from the current transforms (`ui/star_occlusion.gd:36-43`), and `update_candidates()` calls it anyway, so this cannot change any other check. The doc comment says why the refresh is there and cites 7ak V8. Both clear-eye checks keep their 7ak label.

### T3 (c). One check per hiding layer

- **Replacement layer** (`tests/test_free_nav_stop.gd`, after the Barnard I check). `catalogue_rows_lit(demo, id)` finds the destination's rows under each of its aliases (`Starfield.aliases_of`). It reports any row that `StarProjection.sample` still finds visible. The check `its catalogue row is dark, replaced by the body, not pinned (%d rows, lit %s, %d pins)` asserts three things: at least one row, none lit, and `pinned_ids` empty.
- **Pin layer** (`tests/test_ship_star_identification.gd`, after the bare-Gaia check at `:201`). The fixture already holds record `"b"`. A tier row `"b"` is placed, then `Starfield.pin_destination` is called with a position that differs from it. This is the real RT4 fallback: it hides the tier row and appends `"pin:b"`. The check `a pinned destination is offered once, as its pin row (%d candidates)` asserts three things: `"b"` is pinned, there is exactly one candidate, and that candidate's row is `"pin:b"`.
  - Without the `pinned_ids` filter, both rows map to record `"b"`, the duplicate count excludes both, and I offers nothing (`0 candidates`, V14).
  - The pin's `vmag` is −14. `Relativity.illuminance_from_v(-14)` is about 1 lux, the same as the fixture rows' `flux=1`. `vmag` 0 gives 2.6e-6 lux, which is invisible at the fixture's exposure (V9).

### Alternatives considered

| Option | What | Verdict |
|---|---|---|
| (a1) Fold the sky test into the clear-eye check | one check, both occluders | Rejected. One label for two causes is the opacity this row removes. |
| (a2) The clear-eye check uses the destination's projected ray, not the centre ray | match `:131` exactly | Rejected. At arrival they are the same ray (7ak V2: `point=(32, 32)` of 64×64), and "the eye looks ahead" is the meaning 7ak gave it. |
| (b1) A comment only | the row's literal ask | Rejected alone, kept as the doc comment. A comment does not stop the next move. |
| (b2) `eye_clear` refreshes the BVH | placement-independent | **Chosen.** Measured: moved and with the monitor on the line, it fails at both stops (V11). |
| (c1) Make the existing "not the hidden catalogue point" check killable by one mutant | | Impossible without a product change: two independent layers hide the point (V12, V13). |
| (c2) One check per layer, each where its layer acts | T3 | **Chosen.** Killers measured (V12, V14). |
| (c3) Force a pin in the free-navigation flow | | Rejected. The flow never pins (V4), and the fallback is a loud star-truth failure (`make starmap-consistency`). Forcing one tests a picture the game does not ship. |

## Files touched and do-not-touch

- **Touched:** `tests/test_free_nav_stop.gd`, `tests/test_ship_star_identification.gd` (Appendix A), and `changelogs/unreleased/2026-11-12-free-nav-stop-guard-edges.md`. Landing edits (charter row, README index) are routine. No new script, so no new `.uid`.
- **Do not touch:** everything under Non-goals. That includes `ui/ship_star_identification.gd` and `demos/ship_geometry_demo.gd`, both in attended PR #412.

## Conflict surface

Measured with `gh pr view <n> --json headRefOid,files` (V22). #412 is the positive control: it reports the `ui/` file this doc's mutations edit.

| PR | Head | Files | Touches a touched file? | Touches a file a mutation AC edits (`ui/ship_star_identification.gd`, `sky/starfield.gd`, `planets/system_view.gd`)? |
|---|---|---:|---|---|
| #412 `feat/captain-command` (attended) | `3926f4f3` | 48 | no | `ui/ship_star_identification.gd`: one hunk `@@ -237,12 +237,22 @@` (the `typing()` focus helper). Lines 62 and 101, which the mutation ACs edit, are not in it. |
| #380 `feat/r2-kerr-table-preflight` (attended) | `68e4ca6d` | 31 | no | no |
| #373 `feat/r2-kerr` (attended) | `e37b3579` | 57 | no | no |

There is no textual conflict. The mutation ACs find their lines by content (`sed` patterns that match the whole line), not by number. If #412 lands first, its hunk at `:237` moves no line they edit. Whichever lands second reruns AC1 and AC2.

## Acceptance criteria

Headless, in the executor's clone, after `export PATH=$PWD/runtime/bin:$PATH` (AILANG v0.56.1, Godot 4.7.2), with the preamble below sourced. Mutation ACs edit one product file each for one run, run alone (no other Godot run may load the tree meanwhile), and are restored with `git checkout --`. AC12 then checks the tree. Short copies are measured at 104–219 s and the full target at 433–634 s, at load 6–23 on the Studio.

**Preamble** (the `short` helper keeps the test through the alpha Cen A I section and appends the summary line; V24 shows it reproduces the copies measured here byte for byte):

```sh
T=tests/test_free_nav_stop.gd; S=tests/test_ship_star_identification.gd; W=/tmp/7an; mkdir -p $W
run() { AILANG_BIN=$(command -v ailang) godot --headless --path . --script "$1" > "$2" 2>&1; echo rc=$?; }
short() { n=$(grep -nx "$(printf '\t')ident.set_held(false)" "$1" | tail -1 | cut -d: -f1); { head -n "$n" "$1"; printf '\tprint("free-nav-stop: %%d passed, %%d failures" %% [passed, failures]); quit(1 if failures else 0)\n'; } > "$2"; }
short $T $W/short.gd
```

| # | Criterion | Command | Expected (after) | Base (pristine `b96b2d60`) |
|---|---|---|---|---|
| AC1 | The target is green | `make free-nav-stop-test; echo rc=$?` | `rc=0`; `script-gate: free-nav-stop-test ok: free-nav-stop: 57 passed, 0 failures` | `54 passed, 0 failures` (V1) |
| AC2 | The identification target is green | `make ship-star-identification-test; echo rc=$?` | `rc=0`; `ship-star-identification: 60 passed, 0 failures` | `59 passed, 0 failures` (V9) |
| AC3 | The new and changed checks pass, each the measured number of times | `for p in 'the fixed eye looks ahead' 'the sky draws' 'its catalogue row is dark'; do grep -c "^ok $p" .godot/tmp/free-nav-stop.log; done; grep -c '^FAIL' .godot/tmp/free-nav-stop.log` | `2`, `2`, `1`, `0` | `2`, `0`, `0`, `0` (V1) |
| AC4 | Test-only | `git diff --name-only origin/main...HEAD` | only the two test files, the changelog fragment and landing docs/state; nothing under `ui/ demos/ sky/ planets/ interior/ bridge/ sim/ audio/ data/ assets/`, no `Makefile`, `mk/` or `*.ail` | (no diff) |
| AC5 | The clear-eye check reads the BVH only through `eye_clear` | `grep -c 'ident.occlusion.blocked' $T; grep -c 'check(eye_clear(demo, ident)' $T; grep -c 'ident.occlusion.refresh(demo.camera)' $T` | `1`, `2`, `1` | `2`, `0`, `0` |
| AC6 | **(a) killer:** the sky renderer stops skipping the body itself | `sed -i.bak -e 's/^\t\tif b.id == skip_id: continue$/\t\tpass # 7an a/' planets/system_view.gd && rm planets/system_view.gd.bak && run $W/short.gd $W/a.log; git checkout -- planets/system_view.gd; grep -E '^FAIL\|^free-nav' $W/a.log` | `rc=1`; `FAIL the sky draws the destination with no nearer body over it`, `FAIL I offers … (43 candidates)`, `FAIL the sky draws alpha Cen A with no nearer body over it`, `FAIL alpha Cen A is inspectable at its stop`; `free-nav-stop: 17 passed, 4 failures` (V10) | only the two I FAILs; `16 passed, 2 failures` (V10) |
| AC7 | **(b) killer:** the clear-eye check moved before `update_candidates()`, with the course monitor on the eye's line (7ak R2) | the fenced **AC7** block below | `rc=1`; `FAIL the fixed eye looks ahead …` twice, `FAIL I offers … (41 candidates)`, `FAIL alpha Cen A is inspectable at its stop`; `free-nav-stop: 17 passed, 4 failures`. Moved without the shift: `rc=0`, `23 passed, 0 failures` (V11) | the first stop's eye check passes vacuously: one `FAIL the fixed eye …`; `15 passed, 3 failures` (V11) |
| AC8 | **(c) replacement killer:** the bare Gaia alias is not replaced | `sed -i.bak -e 's/^\t\tif bare!=id and not bare in replacements: replacements.append(bare)$/\t\tpass # 7an c1/' sky/starfield.gd && rm sky/starfield.gd.bak && run $W/short.gd $W/c1.log; git checkout -- sky/starfield.gd; grep -E '^FAIL\|^ok I offers\|^free-nav' $W/c1.log` | `rc=1`; `ok I offers … (44 candidates)`; `FAIL its catalogue row is dark, replaced by the body, not pinned (1 rows, lit ["4472832130942575872"], 0 pins)`; `free-nav-stop: 22 passed, 1 failures` (V12) | survives: `20 passed, 0 failures` (V12) |
| AC9 | **(c) pin killer, the row's mutation:** the `pinned_ids` filter dropped | `sed -i.bak -e 's/^\t\tif i >= field.ids.size() or field.ids\[i\] in field.pinned_ids:continue$/\t\tif i >= field.ids.size():continue # 7an c2/' ui/ship_star_identification.gd && rm ui/ship_star_identification.gd.bak && run $S $W/c2s.log; run $W/short.gd $W/c2f.log; git checkout -- ui/ship_star_identification.gd; grep -E 'ERROR: a pinned\|^ship-star' $W/c2s.log; tail -1 $W/c2f.log` | first `rc=1`, `ERROR: a pinned destination is offered once, as its pin row (0 candidates)`, `ship-star-identification: 59 passed, 1 failures`; second `rc=0`, `free-nav-stop: 23 passed, 0 failures` (the flow never pins; V14) | `$S` survives: `59 passed, 0 failures` (V14) |
| AC10 | 7ak's R1 still kills `eye_clear` (the lift's landing eye) | `sed 's/Vector3(11, 82, -4.8)/Vector3(8, 82, -4.8)/' $W/short.gd > $W/r1.gd; run $W/r1.gd $W/r1.log; grep -c '^FAIL the fixed eye' $W/r1.log; tail -1 $W/r1.log` | `rc=1`; `2`; `free-nav-stop: 17 passed, 4 failures` (V15) | `rc=1`; `2`; `14 passed, 4 failures` (V15) |
| AC11 | The short copy is green unmutated (the reference for AC6–AC10) | `run $W/short.gd $W/short.log; tail -1 $W/short.log` | `rc=0`; `free-nav-stop: 23 passed, 0 failures` (V7) | `rc=0`; `free-nav-stop: 20 passed, 0 failures` (V6) |
| AC12 | The tree is clean and every script keeps its `.uid` | `git status --porcelain; make uid-guard` | no status output; `uid-guard: ok (422 .uid files)` (no new script) | same (V23) |

Note on the `grep -E` patterns in AC6, AC8 and AC9: inside the table, `\|` stands for a bare `|`, as in 7ak's round-2 fix. Typed into a shell, the alternation is `'^FAIL|^free-nav'`. With a literal backslash it matches nothing (7ak V17).

**AC7** (perl, measured to produce the same copies as the ones run in V11, V24):

```sh
perl -0pe 's/(\tident\.set_held\(true\); ident\.update_candidates\(\)\n)(\tcheck\(eye_clear\(demo, ident\)[^\n]*\n)/$2$1/g; s/(\tdemo\.avatar_pos = Vector3\(11, 82, -4\.8\)[^\n]*\n)/$1\tdemo.monitor_frames.position.x += 2.418; demo.geometry.find_child("monitor_face_course", true, false).position.x += 2.418\n/' $W/short.gd > $W/b.gd
perl -0pe 's/(\tident\.set_held\(true\); ident\.update_candidates\(\)\n)(\tcheck\(eye_clear\(demo, ident\)[^\n]*\n)/$2$1/g' $W/short.gd > $W/b0.gd
run $W/b.gd $W/b.log; grep -E '^FAIL|^free-nav' $W/b.log
run $W/b0.gd $W/b0.log; tail -1 $W/b0.log
```

## Test plan: each new or changed check and the mutation that kills it

Every row was measured on the prototype in Appendix A: the short copy for `test_free_nav_stop.gd`, the whole file for `test_ship_star_identification.gd`. Each mutation was applied alone, run, and reverted. `git status --porcelain` was empty after every revert.

| Check | Mutation | Prototype (after) | Base | Log |
|---|---|---|---|---|
| `the sky draws the destination …` / `… alpha Cen A …` (T1) | `planets/system_view.gd:793` `if b.id == skip_id: continue` → `pass` | both **FAIL**, plus the two I FAILs; `17 passed, 4 failures` | the checks do not exist; the I checks fail with no cause named; `16 passed, 2 failures` | V10 |
| `the fixed eye looks ahead …` (T2), the row's (b) mutation | check moved before `update_candidates()` + course monitor +2.418 m | both **FAIL**; `17 passed, 4 failures` | first stop **ok** (vacuous), second FAIL; `15 passed, 3 failures` | V11 |
| same (T2), order only | check moved, no shift | `23 passed, 0 failures` (placement-independent) | — | V11 |
| same (T2), 7ak R1 | eye back at `(8, 82, -4.8)` | both **FAIL** (`40 candidates`); `17 passed, 4 failures` | both FAIL; `14 passed, 4 failures` | V15 |
| `its catalogue row is dark …` (T3) | `sky/starfield.gd:110` bare-alias replacement → `pass` | **FAIL** `(1 rows, lit ["4472832130942575872"], 0 pins)`; the I check stays `ok (44 candidates)`; `22 passed, 1 failures` | survives, `20 passed, 0 failures` | V12 |
| (layer 2, not a new check) | `:110` → `pass` **and** `ui/ship_star_identification.gd:101` → `pass` | I check FAIL `(46 candidates)` and the dark-row FAIL; `21 passed, 2 failures` | I check FAIL `(46 candidates)`; `19 passed, 1 failures` | V13 |
| `a pinned destination is offered once …` (T3), the row's (c) mutation | `ui/ship_star_identification.gd:62` `or field.ids[i] in field.pinned_ids` dropped | **FAIL** `(0 candidates)`; `59 passed, 1 failures` | survives, `59 passed, 0 failures` | V14 |
| same mutation against `test_free_nav_stop.gd` | as above | `23 passed, 0 failures` (unreachable in this flow, now asserted: `0 pins`) | — | V14 |

## Sub-milestones and estimates

| Id | Work | Estimate |
|---|---|---|
| S1 | Apply Appendix A; AC1–AC5, AC11 | 10 min + one full run (~8–11 min) and one short run |
| S2 | Mutation ACs AC6–AC10, one at a time (each edits the tree or runs alone) | 6 short runs, ~15–20 min |
| S3 | Changelog fragment; AC12 | 5 min |

## Risks and mitigations

- **The eye's margin is 0.55 m (V16).** If a frame grows by that much, the eye is blocked again. Mitigation: the clear-eye check fails first and names the eye. Moving the eye or the furniture is the deck-layout row's call, not this row's.
- **`sky_hides` could disagree with I if `_add_body_candidates` changes how it asks** (a different direction or skip rule). Mitigation: the helper's comment names the line it mirrors. In AC6 both fail together, so a divergence shows up as one failing without the other.
- **The fixture's `vmag -14`** has no physical meaning beyond brightness. It is a fixture constant, and the comment says why.
- **Host load.** Base 634 s at load up to 20.6, prototype 433 s, inside the 1800 s `SCRIPT_GATE` budget (`Makefile:1252`). Heavier load is F2.
- **#412 lands first.** No textual conflict. Rerun AC1 and AC2 after the rebase.

## Open questions for the user

None. Nothing a player sees or hears changes.

## Follow-ups (new findings, not scope)

- **F1 (row (e)). A `ci-fast` sightline guard: deferred.**
  - `ci-fast` runs no Godot script today (V17).
  - A manifest-only proxy sees only the 4.0 × 2.25 m face rectangle. Its first blocking shift is 0.75 m, against 0.55 m for the real frame (V16), so it would pass a move that blocks the eye.
  - A faithful guard would load the ship demo headless. One option is the `{stars=false, background=false}` setup that `test_ship_star_identification.gd` uses (12 s here, V9). The guard would then put the eye at `(11, 82, -4.8)` and ask `eye_clear`.
  - Whether that runs without the sky and starmap assets, and under `ci-fast`'s missing `make import`, is unmeasured. That is the first measurement for a row of its own.
- **F2 (row (f)). The bridge's 2 s `step_timeout` under heavy load: deferred.** It is product code (`bridge/sim_bridge.gd:296, 357, 387`), with its bound asserted by `tests/test_sim_bootstrap.gd:28` and `tests/test_sim_bridge.gd:314` (V20). A test-side retry would hide real step stalls. MiniMax's cascade at load 30–60 is not reproduced here. If it recurs on the Studio, the first measurement is the time per `journey_tick` step under load.
- **F3 (row (d)). Other tests on `(8, 82, -4.8)`: no action.** They use it as the lift's landing position. None asks the ship BVH for a sightline, and the one that holds I near it, `test_ship_star_identification.gd`, turns ship occlusion off (V21). They are green on tonight's nightly (V19).
- **F4 (new). `bridge-operator-test` is red on the nightly `rig/full` at `b96b2d60`** ("1 red: bridge-operator-test", V19). It is unrelated to this row, and there is no queue row for it yet.

## Deliverables

- `tests/test_free_nav_stop.gd` and `tests/test_ship_star_identification.gd` (Appendix A).
- `changelogs/unreleased/2026-11-12-free-nav-stop-guard-edges.md`.
- Sprint JSON and evaluation per the cycle.

## Verification log

Run 2026-11-12 in `stapledons-godot-iter89-7an` at `b96b2d60` on the Studio (arm64), `PATH=$PWD/runtime/bin:$PATH` (`ailang --version`: `AILANG v0.56.1`), Godot 4.7.2, load 6–34 (noted per run). Scratch copies and probes were in `/tmp/stap_i89_7an/`, run as `AILANG_BIN=$(command -v ailang) godot --headless --path . --script <copy>`. None was committed. "Short copy" means the test cut by the `short` helper; `base_short` is the pristine test, `proto_short` the Appendix A test. Product mutations were `sed -i.bak -e … && rm *.bak`, one at a time, each followed by `git checkout -- <file>` and an empty `git status --porcelain`.

| # | Command | Result |
|---|---|---|
| V1 | controller: `make free-nav-stop-test` at `b96b2d60` → `/tmp/fns_base_iter89_b96b2d60.{log,rc}`; then `grep -E '^(ok\|FAIL) (I offers\|alpha Cen A is inspectable\|a click on A.s centre\|its card says\|the fixed eye looks ahead)' .godot/tmp/free-nav-stop.log`; `grep -c '^FAIL'` | `script-gate: free-nav-stop-test ok: free-nav-stop: 54 passed, 0 failures (rc 0, no SCRIPT ERROR, 634 s of 1800 s)`; rc file `rc=0 secs=638 for b96b2d60`; load at the end 9.16 20.64 17.29; 6 `ok` lines: two `the fixed eye …`, `I offers … (44 candidates)`, `its card says …`, `alpha Cen A is inspectable at its stop`, `a click on A's centre picks A, not B (["body:acen-a"])`; `0` FAIL |
| V2 | `git show b96b2d60:ui/ship_star_identification.gd \| grep -n 'occludes_direction\|pinned_ids'`; `… \| sed -n '96p;127p'` | `62:` the `pinned_ids` filter; `101:` the catalogue-star `occludes_direction`; `130:` the body `occludes_direction`. Line 96 `if not sample.visible:continue`; line 127 `# A planet or moon of a distant system …`. So the row's `:96, :127` is off by 5 and 3 |
| V3 | `grep -n 'update_candidates()\|occlusion.blocked' tests/test_free_nav_stop.gd`; `sed -n 36,43p ui/star_occlusion.gd`; `grep -n 'occlusion.refresh' ui/ship_star_identification.gd` | `60`/`61` and `79`/`80`: `ident.set_held(true); ident.update_candidates()`, then the clear-eye `check(not ident.occlusion.blocked(…))`, no comment; `refresh` fills `active` with `node.global_transform.affine_inverse()`; its only caller is `76: if not demo.sky_only:occlusion.refresh(demo.camera)` |
| V4 | `probe_c.gd`: test lines 1–63 (Barnard leg and I check), then for each `Starfield.aliases_of(barnard)` row print pinned/eligible/record/replacement-source/flux/visible, count the sky rows whose `record_id` is the record, print `pinned_ids`, `pin_noops`, `pin_fallbacks`, the replacement keys | rc 0 in 125 s (load 34); `ok I offers … (44 candidates)`; `PROBE alias=4472832130942575872 k=240771 id=4472832130942575872 pinned=false eligible=true record=Gaia DR3 4472832130942575872 repl=false flux=0.0 visible=false`; `PROBE pinned_ids=[] pin_noops=0 pin_fallbacks=0 rows_for_record=1 repl_keys=["CNS5:3627", "HIP 71681", "CNS5:1142", "Gaia DR3 2635476908753563008", "Gaia DR3 4472832130942575872"]`; `free-nav-stop: 10 passed, 0 failures` |
| V5 | `sed -n 105,129p sky/starfield.gd`; `sed -n 9,16p;33,40p sky/star_projection.gd`; `sed -n 173,190p sky/starfield.gd` | `:110` adds the bare alias to `replacements`; `:117-118` adds `pinned_ids`; `:125-128` sets `custom[4*row+1] = 0.0` for every replaced row. `StarProjection.direction` looks up `catalogue_replacement_sources` by the row's own id (`:15`), and `visible` uses the row's flux (`:35`) unless the sample carries a replacement. `pin_destination` returns early with `pin_noops += 1` when a row already sits at the navigation position, and pins only otherwise |
| V6 | `run base_short.gd` (pristine short copy) | rc 0 in 227 s (load 19.8); `free-nav-stop: 20 passed, 0 failures` |
| V7 | `run proto_short.gd` | rc 0 in 219 s (load 15.6); `free-nav-stop: 23 passed, 0 failures`; `ok the fixed eye …`, `ok the sky draws the destination with no nearer body over it`, `ok I offers … (44 candidates)`, `ok its catalogue row is dark, replaced by the body, not pinned (1 rows, lit [], 0 pins)`, `ok the fixed eye …`, `ok the sky draws alpha Cen A with no nearer body over it`, `ok alpha Cen A is inspectable at its stop` |
| V8 | `run proto_fns.gd` (the full prototype file) | rc 0 in 433 s (load 17.2 at the end); `free-nav-stop: 57 passed, 0 failures` |
| V9 | `make ship-star-identification-test`; `run proto_ssi.gd`. Before the final version: the same check with `vmag=0.` (`n*90.`), then `vmag=0.` at `n*.1`, then `vmag=-14.`, each with a debug print of every row's `StarProjection.sample`; `grep -n 'func illuminance_from_v' -A1 physics/relativity.gd` | base `script-gate: ship-star-identification-test ok: ship-star-identification: 59 passed, 0 failures (rc 0, no SCRIPT ERROR, 12 s of 600 s)`. Prototype rc 0, `60 passed, 0 failures` (7 s). With vmag 0 the pin row was eligible (`elig=[1]`) but `visible: false` at both distances (`59 passed, 1 failures`, `(0 candidates)`); with vmag −14, `visible: true`. `pow(10.0, -0.4 * (v + 13.98))`: v = −14 → 1.02 lux, v = 0 → 2.6e-6 lux |
| V10 | `planets/system_view.gd:793` → `pass`; `run proto_short.gd`; `run base_short.gd`; restore | prototype rc 1 (146 s): `FAIL the sky draws the destination with no nearer body over it`, `FAIL I offers … (43 candidates)`, `FAIL the sky draws alpha Cen A with no nearer body over it`, `FAIL alpha Cen A is inspectable at its stop`, `17 passed, 4 failures`. Base rc 1: `FAIL I offers … (43 candidates)`, `FAIL alpha Cen A is inspectable at its stop`, `16 passed, 2 failures` |
| V11 | `proto_mb.gd`, `base_mb.gd`: each copy's clear-eye check moved above its `update_candidates()` line (both stops), plus 7ak R2's shift line after the first fixed-eye line; `proto_mb_noshift.gd` the move only | prototype rc 1: `FAIL the fixed eye …`, `FAIL I offers … (41 candidates)`, `FAIL the fixed eye …`, `FAIL alpha Cen A is inspectable at its stop`, `17 passed, 4 failures`. Base rc 1: `FAIL I offers … (41 candidates)`, `FAIL the fixed eye …`, `FAIL alpha Cen A …`, `15 passed, 3 failures`, and `ok the fixed eye looks ahead past the ship (no surface on its centre ray)` (the first stop, vacuous). Move only: rc 0, `23 passed, 0 failures` |
| V12 | `sky/starfield.gd:110` → `pass`; `run proto_short.gd`; `run base_short.gd`; restore | prototype rc 1 (139 s): `ok I offers … (44 candidates)`, `FAIL its catalogue row is dark, replaced by the body, not pinned (1 rows, lit ["4472832130942575872"], 0 pins)`, `22 passed, 1 failures`. Base rc 0, `20 passed, 0 failures` |
| V13 | `:110` → `pass` and `ui/ship_star_identification.gd:101` → `pass`; both copies; restore both | prototype rc 1: `FAIL I offers … (46 candidates)`, `FAIL its catalogue row is dark … lit ["4472832130942575872"] …`, `21 passed, 2 failures`. Base rc 1: `FAIL I offers … (46 candidates)`, `19 passed, 1 failures` |
| V14 | `ui/ship_star_identification.gd:62` → `if i >= field.ids.size():continue`; `run proto_ssi.gd` (final version, re-run after its comment edit); `run tests/test_ship_star_identification.gd`; `run proto_short.gd`; restore | prototype `ssi` rc 1: `ERROR: a pinned destination is offered once, as its pin row (0 candidates)`, `59 passed, 1 failures`. Base `ssi` rc 0, `59 passed, 0 failures`. `proto_short` rc 0, `23 passed, 0 failures`, `ok its catalogue row is dark … (1 rows, lit [], 0 pins)` |
| V15 | `sed 's/Vector3(11, 82, -4.8)/Vector3(8, 82, -4.8)/'` on `proto_short.gd` and on `base_short.gd` (2 replacements each) | prototype rc 1: `FAIL the fixed eye …`, `FAIL I offers … (40 candidates)`, `FAIL the fixed eye …`, `FAIL alpha Cen A is inspectable at its stop`, `17 passed, 4 failures`. Base rc 1: the same four, `14 passed, 4 failures` |
| V16 | `probe_clear.gd`: the prototype up to the first clear-eye check, then shift `demo.monitor_frames` and `monitor_face_course` (or the face only) in +x steps of 0.025 m up to 1.0 m, `eye_clear` after each; restore | rc 0 (104 s): `first blocking +x shift 0.550 m` (frame and face), `0.750 m` (face only); `PROBE restored clear=true`. `grep -n FACE_M interior/bridge_monitor.gd`: `17: const FACE_M := Vector2(4.0, 2.25)`; the manifest's `monitors.course` holds only `face`, `bearing_deg`, `screen_ship_m`, `toward_ship_m` |
| V17 | `make -k -n ci-fast > f; wc -l < f; grep -c -- '--headless' f; grep -n -- '--headless' f; grep -c test_free_nav_stop.gd f; grep -c session_minor_guard_controls f` (positive control) | `268`; `1`; the one hit is line 14, a `printf 'bad-capture:…ok-test:\n\t$(GODOT) --headless …' > .godot/tmp/audio-guard-negative.mk` fixture string, not a Godot run; `0`; `1` |
| V18 | `make -n test > f; grep -c test_free_nav_stop.gd f` and the same with `make -k -n test`; `grep -n '^test: ship-demo-ci\|ship-demo-ci: free-nav-stop-test\|ship-demo-ci: ship-star-identification-test' Makefile` | plain `-n`: `0`. An instrument failure: the dry run stops at `make: *** [script-gate-drill] Error 1`. With `-k -n`: `1` each for `test_free_nav_stop.gd`, `test_ship_star_identification.gd`, `test_camera_forward.gd`, `test_camera_director.gd`, `test_dressing.gd`, `tests/test_bridge_operator`. `1229: test: ship-demo-ci`, `1249: …ship-star-identification-test`, `1253: …free-nav-stop-test` |
| V19 | `gh api repos/sunholo-data/stapledons-godot/commits/main/statuses --jq '… select(.context\|startswith("rig/")) …'` | `rig/full failure 2026-11-12T04:59:21Z b96b2d60: make test failed (rc 2; bound 7200s); 1 red: bridge-operator-test` (the positive control is that it names a red target); `rig/full pending … make test running on the Studio` |
| V20 | `git ls-files '*.gd' \| xargs grep -n 'step_timeout'` | `bridge/sim_bridge.gd:296, 357, 387`: `_read_state(Time.get_ticks_msec() + 2000, "step_timeout")`; `tests/test_sim_bootstrap.gd:28` (`elapsed>=1900 and elapsed<3500`); `tests/test_sim_bridge.gd:308-326` (`< 3500`) |
| V21 | `git ls-files '*.gd' \| xargs grep -n 'Vector3(8, *82, *-4.8)'`; for each test file: `grep -c 'update_candidates\|star_identification'`, `grep -c 'occlusion.blocked'`, `grep -c 'sky_only *= *true'` | 14 test files. I users: `test_ship_star_identification.gd` (31, 0, 1), `test_ship_ui.gd` (11, 0, 0; `:518` is the lift ride to the lower deck), `test_camera_director.gd` (1, 0, 0). Every other file is (0, 0, 0). `occlusion.blocked` appears in no test file but `test_free_nav_stop.gd` |
| V22 | for 412, 380, 373: `gh pr view <n> --json headRefOid,files --jq` (file count; `tests/test_free_nav_stop.gd`, `tests/test_ship_star_identification.gd`; the three mutated files); `gh pr diff 412 \| awk` the `ui/ship_star_identification.gd` section | #412 `3926f4f3` 48 files, 0, 0, `ui/ship_star_identification.gd` (positive control), one hunk `@@ -237,12 +237,22 @@` adding `typing()`; #380 `68e4ca6d` 31, 0, 0, none; #373 `e37b3579` 57, 0, 0, none |
| V23 | `make uid-guard; git status --porcelain` (base, after the runs) | `uid-guard: ok (422 .uid files)`; empty |
| V24 | the preamble's `short` under `zsh -c` and `sh -c` on the prototype and on the pristine test, `cmp` against `proto_short.gd`/`base_short.gd`; the AC7 perl lines on `proto_short.gd`, `cmp` against `proto_mb.gd` and `proto_mb_noshift.gd` | `zsh-same`, `sh-same`, `base-same`; `identical-mb`, `identical-noshift` |
| V25 | `diff -u` of each prototype against the tree, concatenated; `git apply --check`; `git apply --stat`; `shasum -a 256`; `wc -l`; `grep -c '^ $'` | applies; `2 files changed, 40 insertions(+), 2 deletions(-)`; sha256 `12880f78a2757838…`; 81 lines; 0 blank context lines. The Appendix A fence, cut out of this doc with `awk`, `cmp`s identical to `proto.patch` |
| V26 | `git ls-files '*.gd' \| xargs grep -n 'pin_destination(' \| grep -v 'func pin_destination\|^tests/\|^tools/'` (positive control: the same without the `grep -v` lists `tests/test_destination_pin.gd:44, 49, 52, 69, 78, 81, 88` and `tools/starmap_consistency.gd:85`) | one line: `demos/solar_departure.gd:65: for id:String in stars:starfield.pin_destination(stars[id])` |

## Appendix A. The patch (`proto.patch`, 81 lines, sha256 `12880f78a2757838…`, against `b96b2d60`)

```diff
--- a/tests/test_free_nav_stop.gd
+++ b/tests/test_free_nav_stop.gd
@@ -1,4 +1,6 @@
 extends SceneTree
+const StarLight = preload("res://demos/ship_star_light.gd")
+const StarProjection = preload("res://sky/star_projection.gd")
 ## Free-navigation stop, the real flow (Mark, 2026-10-08): open navigation, pick a star,
 ## hold to commit, fly the AILANG leg to arrival, then the HUD says where the ship is
 ## and I offers the destination star with its card. Barnard's Star is keyed "Gaia DR3 n"
@@ -11,6 +13,33 @@
 	if ok: passed += 1
 	else: failures += 1
 func _initialize() -> void: _run.call_deferred()
+## 7an (a): I also drops a body that the sky renderer draws behind a nearer one
+## (ui/ship_star_identification.gd _add_body_candidates, occludes_direction). Ask it as I does.
+func sky_hides(demo: Node, id: String) -> bool:
+	var sv: SystemView = demo.sky.system_view
+	if sv == null or not sv.visible: return true
+	for b: Dictionary in sv.last_system.get("bodies", []):
+		if b.id == id: return sv.occludes_direction(StarLight.apparent_direction(sv, b.rel_km, b.radius_km), b.id, Planets.length64(Planets.world_of(b.rel_km)))
+	return true
+## 7an (b): occlusion.blocked() reads the node transforms of the last refresh, so this check
+## refreshes the ship BVH itself; read without it before update_candidates(), it passed while a
+## moved monitor blocked the eye (7ak V8).
+func eye_clear(demo: Node, ident: Control) -> bool:
+	ident.occlusion.refresh(demo.camera)
+	return not ident.occlusion.blocked(demo.camera.global_position, -demo.camera.global_basis.z)
+## 7an (c): a stop's catalogue point is hidden by its body's replacement (the row's flux is zeroed
+## under every alias), not by a pin: this flow never pins, so I's pinned_ids filter is checked in
+## tests/test_ship_star_identification.gd. Returns [rows found, rows still drawn].
+func catalogue_rows_lit(demo: Node, id: String) -> Array:
+	var field: Starfield = demo.sky.starfield
+	var found := 0
+	var lit: Array = []
+	for alias in Starfield.aliases_of(id):
+		var k := field.index_of(alias)
+		if k < 0: continue
+		found += 1
+		if StarProjection.sample(field, k).get("visible", false): lit.append(alias)
+	return [found, lit]
 func fly(demo: Node, id: String, from_name: String) -> void:
 	demo.open_navigation() # the helm (R1-SHIP-UI: outside it the map plans nothing)
 	var map = demo.journey_map
@@ -58,9 +87,12 @@
 	demo.look_direction("forward"); await process_frame
 	var ident = demo.star_identification
 	ident.set_held(true); ident.update_candidates()
-	check(not ident.occlusion.blocked(demo.camera.global_position, -demo.camera.global_basis.z), "the fixed eye looks ahead past the ship (no surface on its centre ray)")
+	check(eye_clear(demo, ident), "the fixed eye looks ahead past the ship (no surface on its centre ray)")
+	check(not sky_hides(demo, "cat:" + barnard), "the sky draws the destination with no nearer body over it")
 	var hit: Array = ident.candidates.filter(func(c): return c.id == "body:cat:" + barnard)
 	check(hit.size() == 1 and ident.candidates.filter(func(c): return c.id == barnard).is_empty(), "I offers the destination as its finite body, not the hidden catalogue point (%d candidates)" % ident.candidates.size())
+	var lit := catalogue_rows_lit(demo, barnard)
+	check(lit[0] >= 1 and lit[1].is_empty() and demo.sky.starfield.pinned_ids.is_empty(), "its catalogue row is dark, replaced by the body, not pinned (%d rows, lit %s, %d pins)" % [lit[0], lit[1], demo.sky.starfield.pinned_ids.size()])
 	if hit.size() == 1:
 		ident.inspect(hit[0].id)
 		var text: String = ident.content.get_child(0).text if ident.content.get_child_count() > 0 else ""
@@ -77,7 +109,8 @@
 	demo.avatar_pos = Vector3(11, 82, -4.8) # the captain eye of G-M4-S3 (tools/m4_ship_golden.gd): the lift's landing (8, 82, -4.8) looks into the course monitor (R3-COMMS-V2 wall R), whose bearing keeps this line clear
 	demo.look_direction("forward"); await process_frame
 	ident.set_held(true); ident.update_candidates()
-	check(not ident.occlusion.blocked(demo.camera.global_position, -demo.camera.global_basis.z), "the fixed eye looks ahead past the ship (no surface on its centre ray)")
+	check(eye_clear(demo, ident), "the fixed eye looks ahead past the ship (no surface on its centre ray)")
+	check(not sky_hides(demo, "acen-a"), "the sky draws alpha Cen A with no nearer body over it")
 	var a_c: Array = ident.candidates.filter(func(c): return c.id == "body:acen-a")
 	check(not a_c.is_empty(), "alpha Cen A is inspectable at its stop")
 	if not a_c.is_empty():
--- a/tests/test_ship_star_identification.gd
+++ b/tests/test_ship_star_identification.gd
@@ -199,6 +199,11 @@
 	check(identify.record_id("123")=="Gaia DR3 123" and identify.record_id("pin:b")=="b" and identify.record_id("999")=="","sky rows map to their catalogue record id")
 	demo.sky.starfield.set_custom_stars([{id="123",pos=n*100.,t=5700.,flux=1.}]);identify.update_candidates()
 	check(identify.candidates.size()==1 and identify.candidates[0].id=="Gaia DR3 123","a bare Gaia row is offered as its catalogue id")
+	# 7an: the RT4 pin fallback hides the tier row and adds "pin:b"; I offers the star once, as the pin row
+	# (vmag -14 is about 1 lux, as bright as the fixture rows' flux 1).
+	var g := SkyFrame.to_galactic(n*90.)
+	demo.sky.starfield.set_custom_stars([{id="b",pos=n*100.,t=5700.,flux=1.}]);demo.sky.starfield.pin_destination({id="b",x=g.x,y=g.y,z=g.z,vmag=-14.,teff=5700.});identify.update_candidates()
+	check("b" in demo.sky.starfield.pinned_ids and identify.candidates.size()==1 and demo.sky.starfield.ids[identify.candidates[0].index]=="pin:b","a pinned destination is offered once, as its pin row (%d candidates)" % identify.candidates.size())
 	demo.sky.starfield.set_custom_stars([{id="b",pos=n*100.,t=5700.,flux=1.}]);identify.update_candidates()
 	identify.info.records.erase("b");identify.reindex();identify.update_candidates();check(identify.candidates.is_empty(),"absent metadata fails closed")
 	demo.queue_free();await process_frame
```
