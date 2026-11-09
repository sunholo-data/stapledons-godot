# Nightly rig/golden: the setup make test used to provide (7af)

**Status:** Planned 2026-11-09 (mission iteration 81, designer). **Release:** r1. **Milestone:** none (merge and nightly tooling).
**Priority:** P1. Every nightly `rig/golden` on main is red before any GPU case runs, so the GPU goldens (definition of done, gate 2) are not re-verified on main at all.
**Implements:** queue row **7af**. Restores the nightly split that Mark ruled on 2026-11-03 and 2026-11-06 (CLAUDE.md "Merges"; PR #405, `dec3bd83`): `make test` runs as `rig/full` on an idle CPU, and `make golden` runs as `rig/golden` on an idle GPU.
**Depends on:** PR #405 (`tools/rig_nightly.sh` calls `tools/rig_check.sh <sha> --golden-only`); the hermetic control `tools/test_rig_check.sh` from iteration 55 / PR #345 ([rig-watchdog-7200](../../implemented/r1/rig-watchdog-7200.md)). AILANG v0.56.1, Godot 4.7.2.
**Estimated LOC:** about 45. `tools/rig_check.sh` about 10 (a setup list, a bounded loop, the header). `tools/test_rig_check.sh` about 35 (a make-call log in the stub, an `order` helper, 4 cases, the count 8 → 12). Nothing changes in `Makefile`, `mk/`, `.gd` files or `.uid` files.

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

`import` is already a golden prerequisite, but an indirect one: `true-light-golden: import` (`Makefile:1246`). GNU make runs the recipe rule's prerequisites first, then the other `golden:` lines in the order they are read. `make -n golden` at `7d26c947` shows `lens-assets`, then `m4_physics_probe` (output lines 14-16), then **`constellation_capture.gd` (line 17), and only then `godot --headless --path . --import` (line 18)**. So the Makefile-prerequisite approach has already been tried by accident, and it failed on ordering. Under `-j` there would be no ordering at all.

## Measurement: what else golden silently took from make test

All of this was measured headlessly, on a fresh `git clone` of `7d26c947` (`stapledons-godot-iter81-fresh`, deleted afterwards). Nothing ran on the GPU.

| Input | How golden reads it | Fresh clone | Evidence |
|---|---|---|---|
| Class cache (`import`) | Every golden Godot script | absent | Before `make import`, `--check-only` printed 644 `SCRIPT ERROR` lines over 15 scripts (main.gd 188; tools: constellation_golden 41, true_light 18, comms 36, earth_display 8, cmb 22, earth_link 5, exposure 44, gr 41, interior 68, ism 47, m4_ship 51, m5 50, star_surface 25; constellation_capture 0, because it loads the golden at run time). `make import` took 9 s. Afterwards the count was **0**. |
| Planet textures (`planet-assets`) | `m5_golden.gd:28-31`: textured G-M5-4 prints `ok` only when `assets/planets` exists, and `skip` otherwise | absent (`assets/planets` is gitignored) | The last green golden (rig log `19b3d362…`, 2026-11-03, after `make test`) has **417** `^ok` lines in its golden section (log lines 15342-15983), and one of them is `ok G-M5-4 Jupiter … (normalised texture …)`. The `make golden` recipe asserts `grep -c '^ok' = 417`. Without the textures the count is 416, so **golden is red even after import is fixed**. `make planet-assets`: 5 s, 20 textures verified. |
| Large star tier (`starmap-assets`) | `m4_ship_golden.gd:34` → `_build(true)` → `interior_sky.gd:96` `Starfield.default_tier()`, which is `large` only when `data/starmap/stars_large.bin` exists (`sky/starfield.gd:139-143`) and otherwise falls back to `medium` with a warning | absent | The green baseline has 0 `stars_large.bin is missing` warnings, so the G-M4-S2 and G-CAM-3 cases were measured on the large tier. Without the file, golden draws a different sky from the one it was pinned on. `make starmap-assets`: under 1 s, `tiers match`. |
| AILANG package cache (`deps`) | `m4-physics-probe` runs `ailang run --package-dir sim` against `$HOME/.ailang/cache` | warm on the Studio; empty on a new host | With an empty `HOME`, the pinned `runtime/bin/ailang run … m4_physics_probe.ail` exits 1 with `package resolution setup failed … sunholo/celestial/0.6.0`. After `HOME=<same> make deps` (1 s) it exits 0 and prints 28 lines. The 03:18 nightly passed this step only because the Studio's home cache was warm. |
| Sky textures, lens tables, sim runtime | `sky-assets` and `make runtime` (in `rig_check.sh`), and `lens-assets` (a golden prerequisite) | provided | These steps already run on the golden-only path. `SimBridge` reads `res://runtime/cache` (`bridge/sim_bridge.gd:527`), and `make runtime` stages it. |
| Everything else | All `res://` literals in the 15 scripts | tracked, or written by golden | The untracked `res://` literals are `renders/*` outputs and `.godot/tmp/m4-physics-probe.txt` (written by the `m4-physics-probe` prerequisite). The only other gitignored loader on these paths is the Commons civic art (`ship_geometry_demo.gd:264`). It loads only with `civic_art: true`, which no golden sets. The green baseline's golden section has no `skip`, `missing` or `not fetched` lines. |

Import order among the setup targets does not matter for the fetched files, because `data/raw` and `assets/planets` get a `.gdignore` (`tools/sky_assets.sh:57`, `tools/planet_assets.sh:48`) and the starmap tier is a `.bin` that Godot does not import. `import` still goes last, after everything that could add files. The whole setup costs 16 s on a cold clone and 4 s on a warm one (deps 0, starmap 0, planet 1, import 3), measured on the fresh clone.

**Answer:** golden needs exactly four setup targets that `make test` used to provide: `deps`, `starmap-assets`, `planet-assets` and `import`. The fresh-clone headless measurement confirms `import`, `planet-assets` (as an ok-count failure) and `deps` (on a cold home) as hard failures. `starmap-assets` is a silent change to golden's inputs.

## Design

**One ordered setup step in `tools/rig_check.sh`, run immediately before `make golden` on both golden paths:**

```sh
# make golden reads what make test used to leave behind (7af, measured 2026-11-09): the AILANG package cache
# (deps), the large star tier (starmap-assets), the planet textures (planet-assets) and Godot's class cache
# (import, last). An explicit ordered step, never make prerequisite order (true-light-golden: import ran 4th).
GOLDEN_SETUP="deps starmap-assets planet-assets import"
SETUP_S=1800   # a fixed bound per target (a bucket miss rebuilds); not a RIG_* override, so the control stays hermetic
...
if [ $golden = 1 ]; then
  for t in $GOLDEN_SETUP; do
    perl -e 'alarm shift; exec @ARGV' "$SETUP_S" make "$t" >> "$log" 2>&1 || fail "golden setup: make $t failed or ran over ${SETUP_S}s"
  done
  perl -e 'alarm shift; exec @ARGV' "$GOLDEN_S" make golden >> "$log" 2>&1 || fail "make golden failed or ran over ${GOLDEN_S}s"
fi
```

The step runs after `make test` on `--golden` too. That costs about 4 s and guarantees the state golden sees whatever `make test` did. The `rig/full` path (no flag) does not change, and the header comment gains one line. The longest failure description is `01234567: golden setup: make starmap-assets failed or ran over 1800s` (67 characters), well inside the 140-character limit.

**Control (`tools/test_rig_check.sh`).** The stub `make` also appends `$*` to `$STUB_MAKES`. A new helper is `order <case> <flag> <failing target> <want rc> <want make calls, space-joined> <want final state> <want description ERE>`. The cases (stub runtime on the pin, so `make runtime` is not called):

| Case | Flag | Fails | rc | Make calls, in order | Final post |
|---|---|---|---|---|---|
| `golden-only-setup` | `--golden-only` | none | 0 | `sky-assets deps starmap-assets planet-assets import golden` | success `make golden green` |
| `golden-setup` | `--golden` | none | 0 | `sky-assets test deps starmap-assets planet-assets import golden` | success |
| `golden-setup-red` | `--golden-only` | `import` | 1 | `sky-assets deps starmap-assets planet-assets import` (no `golden`) | failure `01234567: golden setup: make import failed` |
| `full-no-setup` | none | none | 0 | `sky-assets test` | success |

The count goes from 8 to 12, and `caller-poison` expects 12 of 12, so the total is 13 cases. `caller-poison` already sets `RIG_GOLDEN_S=7`, and the top-level `unset` keeps that hermetic now that cases reach the golden path.

**Rejected alternatives.**
1. *Add `deps starmap-assets planet-assets import` to `golden:` in the Makefile.* `import` is already a prerequisite and ran 4th, after the script that needed it (measured above). Serial order depends on rule order across 6 `golden:` lines in 4 files, and `-j` gives no order.
2. *Order-only `| import` on each Godot golden sub-target.* This is correct even under `-j`, but it must be repeated on 5 targets today, and the next golden target forgets it. It also leaves the planets, starmap and deps inputs uncovered.
3. *A `golden-setup` Makefile target.* The hermetic stub would see only one name, so the list would need its own lint, and the same make-ordering caveat applies to its prerequisites.
4. *Run `make test` in the golden-only nightly.* That defeats the split: about 70 min of CPU before the GPU window.
5. *Reuse the `rig/full` clone.* `rig_check.sh` deletes each clone at exit (40 GB once, 2026-11-03), and coupling the two halves' state is what broke here.

A local `make golden` in a fresh clone still expects the documented one-off `make import` (`Makefile:42`, CLAUDE.md). That behaviour is unchanged and out of scope.

## Acceptance criteria

Here `C` is a fresh clone: `C=../stapledons-godot-7af-ac; git clone -q . $C && cd $C`. Delete it afterwards. `S` is the 15 scripts: `main.gd tools/{constellation_capture,constellation_golden,true_light_golden,comms_golden,earth_display_golden,cmb_golden,earth_link_golden,exposure_golden,gr_golden,interior_golden,ism_golden,m4_ship_golden,m5_golden,star_surface_golden}.gd`.
`count` (POSIX `sh`; zsh needs `${=S}`) is `n=0; for s in $S; do n=$((n+$(perl -e 'alarm 120; exec @ARGV' godot --headless --path . --check-only --script $s 2>&1 | grep -c 'SCRIPT ERROR'))); done; echo $n`.

| # | Criterion | Command | Expected |
|---|---|---|---|
| 1 | Positive control: a fresh clone cannot parse the goldens | in `$C` (no `.godot/`): `count` | `> 0` (measured 644) |
| 2 | The rig's own setup list fixes the parse | in `$C`: `make runtime && PATH=$PWD/runtime/bin:$PATH; for t in $(sed -n 's/^GOLDEN_SETUP="\(.*\)"/\1/p' tools/rig_check.sh); do make $t \|\| break; done; count` | every make exits 0, then `0` |
| 3 | The setup provides the textures and the tier golden reads | in `$C` after AC2: `ls assets/planets \| grep -c jpg; test -f data/starmap/stars_large.bin && echo tier` | `20`, then `tier` |
| 4 | The list is exactly the measured four, with import last | `sed -n 's/^GOLDEN_SETUP=//p' tools/rig_check.sh` | `"deps starmap-assets planet-assets import"` |
| 5 | Control green | `sh tools/test_rig_check.sh tools/rig_check.sh \| tail -1` (and `make rig-check-control`) | `rig-check control: 13 cases, 0 failures`, rc 0 |
| 6 | Mutant M1 (no setup) dies | `T=$(mktemp -d); sed 's/^GOLDEN_SETUP=.*/GOLDEN_SETUP=""/' tools/rig_check.sh > $T/m.sh; sh tools/test_rig_check.sh $T/m.sh` | rc 1; `golden-only-setup`, `golden-setup` and `golden-setup-red` FAIL |
| 7 | Mutant M2 (import dropped) dies | as AC6 with `s/^GOLDEN_SETUP=.*/GOLDEN_SETUP="deps starmap-assets planet-assets"/` | rc 1; `golden-only-setup`, `golden-setup` and `golden-setup-red` FAIL |
| 8 | Mutant M3 (planet-assets dropped) dies | as AC6 with `s/^GOLDEN_SETUP=.*/GOLDEN_SETUP="deps starmap-assets import"/` | rc 1; `golden-only-setup`, `golden-setup` and `golden-setup-red` FAIL |
| 9 | Mutant M4 (setup failure ignored) dies | as AC6 with `s/ \|\| fail "golden setup: .*$//` | rc 1; `golden-setup-red` FAIL |
| 10 | Scope | `git diff --name-only origin/main...HEAD` | exactly `tools/rig_check.sh`, `tools/test_rig_check.sh`, this doc, and the landing's `CHANGELOG.md`/README index rows |
| 11 | Shell hygiene | `sh -n tools/rig_check.sh && sh -n tools/test_rig_check.sh && git diff --check origin/main...HEAD` | rc 0, no output |

The post-merge observation is not a merge gate (merges never wait on the GPU). The first nightly `rig/golden` on main after the merge has `grep -c 'SCRIPT ERROR' $TMPDIR/rig-check/<sha>.log` = 0 in its constellation section, and either a `rig/golden` success or a failure whose cause is a GPU case and not setup. That run is the GPU verification of the 417 count.

## Sub-milestones and estimates

One milestone (about 45 LOC). Write the control cases first and record them red against the unmodified `rig_check.sh`: M1 is today's script. Then add the setup loop, then run AC1–11.

## Risks and mitigations

- **A double import on `--golden`.** `make test` imports, then the setup imports again: measured at 3 s warm. The fetch targets verify sha256 and skip downloads. Accepted.
- **Import cost on a clone with sky assets.** No extra cost: `data/raw` and `assets/planets` carry `.gdignore`, so Godot skips them. The measured 9 s cold is without them, and the pre-split nightly paid the same import inside `make test`.
- **A bucket miss starts a rebuild** (`starmap-assets` rebuilds the large tier; `planet-assets` falls back to the source sites). `SETUP_S=1800` bounds each target, and the failure names the target.
- **`deps` fails on lock drift.** `rig/golden` would then be red for a non-GPU reason. `rig/full` is red the same night for the same reason, and the description names `make deps`.
- **The next new golden input.** The comment beside `GOLDEN_SETUP` names the rule. A new golden that reads a generated file adds that file's target to the list, and the green baseline's 417 `ok` count catches a silent skip.

## Open questions for the user

## Deliverables

- `tools/rig_check.sh`: `GOLDEN_SETUP`, `SETUP_S`, the setup loop, and a header line.
- `tools/test_rig_check.sh`: the make-call log, `order`, the 4 cases, and the count 8 → 12.
- At landing: a `CHANGELOG.md` line, this doc moved to `design_docs/implemented/r1/`, and its README index row.
