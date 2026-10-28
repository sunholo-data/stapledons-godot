# Test-suite speed (L4): measure `make test` per target, run the rig's suite in parallel lanes, shard the sim unit suite

**Status:** Planned (mission iteration 56 design, 2026-10-28). **Release:** r1. **Milestone:** none (merge tooling, charter queue row L4).
**Priority:** P1. `rig/full` gates every merge and has taken 66–117 min (V31); the 117-min run came within 3 min of the 7,200 s watchdog, and run 1 of the same landing went red on a 90 s launch guard under load (V18).
**Implements:** charter row [L4](../../stapledon-mission.md) ("Profile and parallelise without losing coverage, and report before/after") and ledger D-126 answer **C**, the **B half** (Mark, attended 2026-10-28: "move L4 (test-suite speed) ahead of Kerr a4"). The A half (watchdog 7,200 s) landed in iteration 55 ([rig-watchdog-7200.md](../../implemented/r1/rig-watchdog-7200.md), PR #345). CLAUDE.md "Definition of done" gates 1–6 are unchanged: no test is removed, no check value moves.
**Depends on:** PR #345 (merged, `d63b47a4`); AILANG v0.54.18; GNU Make 4.4.1 at `/opt/homebrew/bin/gmake` on the Studio (OQ2). Milestone 3 also depends on PRs #344 and #346 being merged or closed (the `Makefile` hold, below).
**Estimated LOC:** about 630 in three milestones (M1 ≈ 258, M2 ≈ 251, M3 ≈ 120; M1 splits into M1a/M1b if it passes 270). M1 and M2 touch **no** `Makefile` line and no `mk/m45.mk` line; M3 is the only milestone that edits `Makefile` (flagged at each step).

**Provenance key used in every number below.**
- `[rig profile c2e70e15]`: **measured for this design.** The controller's serial `gmake --trace test` on main `c2e70e15` in a fresh clone on the Studio, every output line prefixed with a Unix second (`/tmp/stap56/profile.ts.log`, 14,613 lines, rc 0, **complete**; V29). A target's time is the gap between its `update target` line and the next one, summed per top-level target (sub-make targets are folded into the top-level target that ran them).
- `[CI 38579592710]`, `[CI 38718669155]`: **inherited** from [ci-test-tiers.md](../r2/ci-test-tiers.md) (Superseded, kept for its timing data): GitHub's 2-core Linux runner, 2026-10-14/15. Two weeks old; used only for contrast.
- `[charter]`, `[mission log]`: **inherited** `rig/full` totals recorded by earlier iterations.
- `[static db]`: **measured for this design** from make's database, `gmake -pq --eval='__nop__:' __nop__` (no recipe runs; V3).

## Game vision alignment

Scored with the `game-vision-designer` skill in feature-validation mode against `../stapledons-design/vision/core-pillars.md` (V34).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | No clocks in the game; only the test harness's clock. |
| The Ship Is Home | 0 | 0 | No scene. |
| Grounded Strangeness | 0 | 0 | No visuals; the physics gates (2, 3) keep every check. |
| We Are Not Built For This | 0 | 0 | No crew. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No physics change; every physics check still runs on every `rig/full`. |
| **Net** | | **0** | **Go: ALIGNED, no conflict.** Merge-tooling hygiene that Mark ruled directly (D-126 C). D-88: test and audit hygiene does not stop at a net of 0. |

## Problem

### 1. The suite is long, and the rig's load stretches it further

- `rig/full` totals on record: 66, 77, 84, 90, 99 and 117 min `[mission log]` (V31). The 117-min run was under an attended session's concurrent load; the watchdog is 7,200 s (`tools/rig_check.sh:15`, V25).
- The same suite, serial, on main `c2e70e15`: **4,123 s (68.7 min), rc 0**, 1-min load 2.51 at start and 4.51 at end, about 7.3 mid-run `[rig profile c2e70e15]` (V29). The Studio has 16 cores (12 performance, 4 efficiency) and 128 GB (V2); `rig_check.sh` runs `make test` with no `-j` (V25), so make starts one recipe at a time.

### 2. Where the time goes `[rig profile c2e70e15]`

186 top-level targets ran; 73 of them took 1 s or less. The top 5 hold 43.7 % of the wall time, the top 10 56.1 %, the top 20 71.8 % (V30).

| # | Target | s | Share | What it is (evidence) | Contrast |
|---:|---|---:|---:|---|---|
| 1 | `sim` | **740** | 17.9 % | `ailang check --package sim` 82 s; `cd sim && ailang test --package .` **580 s** (554 tests, 517.7 s inside tests, about 62 s compile; 50 test files, 77 modules); `test_sim_bridge.gd` 59 s; `bh-hud-test` (sub-make) 18 s (V30) | 798 s for the unit suite alone `[CI 38579592710]` |
| 2 | `solar-departure-test` | 437 | 10.6 % | Godot, `tests/test_solar_departure.gd`; the script has 0 `await`s, so it may be bound by the sim child's CPU rather than by real time (V32) | 649 s `[CI 38579592710]` |
| 3 | `free-nav-stop-test` | 248 | 6.0 % | Godot, real flow to Barnard's Star and α Cen A (5 `await`s) | 259 s `[CI]` |
| 4 | `moon-lifecycle-test` | 201 | 4.9 % | Godot; the script says "Guided legs run in real time (D-39)" | 233 s `[CI]` |
| 5 | `no-twitch-test` | 177 | 4.3 % | Godot, "600 s of fake time with the sim ticking" (19 `await`s) | 127 s `[CI]` |
| 6 | `strict` | 130 | 3.1 % | strict VM = interpreter checks | 108 s `[CI]` |
| 7 | `parity-m4` | 104 | 2.5 % | one `--sim-only` replay, refusals, then `replay-positive-control` (sub-make) | 226 s `[CI]` (since trimmed, V33) |
| 8 | `ai-live-guard` | 103 | 2.5 % | policy scan, each rule's mutant, `test_ai_settings.gd --launch-default` | 35 s `[CI]` |
| 9 | `playthrough-adversarial` | 87 | 2.1 % | sub-make `playthrough` (reruns `import`) | 105 s `[CI]` |
| 10 | `playthrough` | 86 | 2.1 % | scripted ship walk (prerequisite of `scene-session-audits`) | 102 s `[CI]` |
| 11 | `ship-demo-live-test` | 83 | 2.0 % | live sim journey | 48–53 s `[CI]` |
| 12 | `lens-lut-check` | 82 | 2.0 % | sampled LUT regeneration = pinned bins | 188 s `[CI]` |
| 13–20 | `ship-console-test` 66, `replay` 65, `sound-synth-check` 63, `ship-ui-test` 63, `camera-test` 63, `free-nav-recovery-test` 54, `destar-test` 54, `crew-parity` 53 | 481 | 11.7 % | | |

**The sum, spelled out (V41):** rows 1–12 = 740 + 437 + 248 + 201 + 177 + 130 + 104 + 103 + 87 + 86 + 83 + 82 = **2,478 s**; rows 13–20 = **481 s**; together **2,959 s = 71.8 %** of 4,123 s.

**The inherited slowest-AILANG-tests table is stale.** In this run the slowest test files are `crew_hold_test.ail` 105.0 s (22 tests), `protocol_interlude_test.ail` 91.0 s (14), `solar_departure_test.ail` 61.8 s, `cruise_digest_test.ail` 43.2 s, `ism_test.ail` 39.3 s and `core_ism_test.ail` 34.1 s (V30). `trappist1_test.ail`, the slowest file on 2026-10-15 (132 s `[CI 38718669155]`), is no longer in the top 15. Any shard plan must be rebalanced from a fresh run, not from the old doc.

**Wall floor or CPU-bound: not yet measured.** The `--trace` instrument records wall time only. The old doc called the three long Godot legs "real-time floors"; the evidence is mixed: `moon-lifecycle` says so in its header, `solar-departure` has no `await` at all (V32). Milestone 1's instrument records the children's CPU seconds per recipe line, so each target is classed by measurement (CPU/wall below 0.3: a floor; 0.9 or more: CPU-bound; above 1: internally parallel). Until then every class in this doc is labelled as a hypothesis.

### 3. Serial order hides missing edges `[static db]`

The `test:` target has **108 direct prerequisites** and a closure of **258** names, 187 of them with a rule (the rest are `sim/*.ail` sources; the replay state file `$(M45_STATE)` = `.godot/tmp/replay/m4_min_path.vm.ndjson` has an **explicit** rule at `mk/m45.mk:118` and is declared as a prerequisite by `codex-unlocks`, V43; a naive awk over the `# Files` section can misclassify it) (V4). `test` itself has **0 recipe lines** (V44), so P1 ∪ P2 ∪ setup executes every recipe line `make test` executes. Serial order is what makes it pass today:

- **The first 27 prerequisites are declared above `Makefile:50`** (`kerr-oracle` at `Makefile:22`, then the `mk/*.mk` files included at lines 26–33: `home-tiers-vm`, … `levels-regress`), so they run before `python-guard` (28th), `deps` and `starmap-assets` (V5). `import` runs 5th, only because `deck-layout-eval-test` happens to declare it; `deps` runs 33rd, `starmap-assets` 34th, `lens-assets` 35th, `deps-ai` 107th, `planet-assets` 126th (V5).
- **35 of the 105 closure targets that start Godot do not reach `import`** through their prerequisites, among them `sim`, `ui`, `physics`, `m4-smoke`, `area-test`, `transit-test`, `codex-test` and the `ship-demo-*` validators (V6).
- **None of the 58 closure targets whose recipe calls `$(AILANG)` reaches `deps`** (a lower bound: recipes that call AILANG through a script are not counted) (V6).
- **`deps` and `deps-ai` rewrite tracked lock files in place** (`ailang lock`, then `git checkout`; `Makefile:39-42`, `mk/ai.mk:37-39`) while any concurrent `ailang run --package-dir sim|ai` would read them (V10).

### 4. Shared state that only serial order makes safe

Every hazard below is backed by a Verification Log row; "absent" claims carry a positive control.

| # | Hazard | Evidence | Treatment |
|---|---|---|---|
| H1 | Lock files rewritten by `deps`, `deps-ai` | V10 | **Setup stage**: both finish before any other target starts (M2). |
| H2 | **`import` reruns inside sub-makes and rewrites `.godot/` while other Godot runs read it.** `playthrough: import` and `display-audit: import display-audit-controls` are re-entered by `$(MAKE)` from `scene-session-audits`, `playthrough-adversarial`, `display-audit-interlude` and `display-audit-crew`; `import` ran **5 times** (1 top-level, 4 nested, 1–8 s each). The last nested run rewrote `.godot/global_script_class_cache.cfg` and `.godot/uid_cache.bin` (mtimes 1793227726/727 = its start), and 7 files outside `.godot/tmp` changed after the first import. | V11, V12 | `-o` does not reach a sub-make (V8), so in M2 these four targets run in the **exclusive phase** (serial, after the parallel phase). M3 removes the cause (a stamped `import`). |
| H3 | Missing `import`/`deps` edges (35 + 58 targets) | V6 | **Setup stage**, run to completion before the parallel phase (M2); the edges are declared in the makefiles in M3. |
| H4 | `home-art-check` and `home-site-check` both write `$(SCRATCH)/home-tiers/counts.txt` with `>` (`mk/home-tiers.mk:22,43`) | V13 | M2 gives each its own file (`mk/home-tiers.mk` is not held). |
| H5 | **The replay family shares `.godot/tmp/replay/`, and two targets silently read `replay`'s output.** `tools/replay.py` writes `<case>.vm.ndjson` for every case into `.godot/tmp/replay` (`replay.py:99,207`), which includes `m4_min_path.vm.ndjson`, the very file `$(M45_STATE)` names (`mk/m45.mk:61,118`). In the serial run **the `$(M45_STATE)` rule never ran** (0 `update target` lines): `replay` (48th) had already written the file, so `parity-m4` (77th, whose sub-make `replay-positive-control` `cmp`s it undeclared, `mk/m45.mk:115`) and `codex-unlocks` (80th; it declares the file as a prerequisite, V43, but the rule found it up to date) read `replay`'s copy. Under `-j` the rule and `replay` could write the same file at once while those two read it. | V14 | **Lane** in serial order, `replay → tools-test → parity-m4 → .godot/tmp/replay/m4_min_path.vm.ndjson → codex-unlocks → replay-compat → replay-scene` (order-only edges, M2); the real edges (`parity-m4: $(M45_STATE)`, and `$(M45_STATE)` after `replay`) land in M3 (`mk/m45.mk` is held by #344). |
| H6 | `ai-live-guard` (`--launch-default`) and `ai-settings` both run `tests/test_ai_settings.gd`, whose `test_launch_default` calls `fresh("default")`: `rm -rf res://.godot/tmp/ai_settings/default`, then uses it | V15 | **Lane** in serial order, `ai-live-guard → ai-settings`. |
| H7 | `ai-relay` and `replay-noai` both run `tests/test_ai_relay.gd`, scratch `res://.godot/tmp/ai_relay` with `rm -rf` per name; disjointness of the names is not proven | V15 | **Lane** `ai-relay → replay-noai` (conservative). |
| H8 | Scripts run by more than one closure target: `tools/validate_ship_demo.gd` (3 targets), `tests/display_audit.gd` (3), `tools/validate_ship_commons.gd` (2), plus H6 and H7. The two validators write no fixed path (grep 0, positive control 1) | V16 | Validators: no lane. `display_audit.gd`: two of its three users are already exclusive (H2). |
| H9 | Godot's `user://` is one directory for every clone and session (`~/Library/Application Support/Godot/app_userdata/Stapledon's Voyage`; no custom user dir in `project.godot`). Tests use 18 distinct literal `user://` paths, **none shared by two test files**; the runtime unpack into `user://runtime-*` runs only in exported builds; Godot's `logs/` rotate there | V17 | No lane. M2 records every `user://` path written during a run (stamp + `find`) as evidence. |
| H10 | **Wall-clock assertions.** `crew-perf` (budgets: critical-only under 2 s, busy no-hold under 30 s, `Makefile:182-188`); `ship-demo-launch-test` (`deadline = ticks + 90000` ms, `tests/test_ship_demo_launch.gd:11`), which went red under load 6–20 in iteration 55. 10 of 101 test scripts read `Time.get_ticks_*` | V18 | `crew-perf` and `ship-demo-launch-test` run in the **exclusive phase** (no contention from the suite's own jobs). The other 8 scripts are watched by M2's repeat runs. |
| H11 | Ports | `ai-loopback`'s fixture server binds an **ephemeral** port and writes it to a file; no Godot test opens a server (V19) | None. |
| H12 | In-place mutation of tracked sources (`ai-loopback-mutants`, `ai-bridge-mutants`, `markers-mutants` copy sources aside and mutate them) | **Not in the `test` closure** (0 of 3; positive control `ai-godot` 1) (V20) | None today; M2's plan check fails if any `*-mutants` target enters the closure. |
| H13 | Fixed `/tmp` paths | One default, `tools/crew_sync.sh:9`, overridden by `Makefile:112` (V21) | None. |
| H14 | `lens-assets` rerun by the `bh-hud-test` sub-make | `tools/lens_assets.sh fetch` skips a file whose sha256 matches, and writes through `.part` + `mv` (V22) | None: read-only after the first run. |
| H15 | The watchdog (`perl alarm` + `exec`) kills only the process it replaced; under `-j` more children would be orphaned | `tools/rig_check.sh:72` (V25) | The M2 runner traps `ALRM`/`TERM` and kills its process group. |

**A side finding, not L4's to fix:** a full `make test` leaves exactly these 5 untracked files (V35, V42):

- `data/planets/trappist1_ps.default.translation`
- `data/planets/trappist1_ps.pl.translation`
- `data/planets/trappist1_ps.rowupdate.translation`
- `data/planets/trappist1_ps.st.translation`
- `data/starmap/truth/positions. 1%) is resolved in the audit.translation`

The last name is literal, not corruption: Godot imported a CSV as a translation table and took a header cell as a locale (V42). So "`git status` clean after the run" is false today. AC8 compares the run's status against this five-line list instead. The loop should file the import itself as its own row.

### 5. Repeated work

`import` 5 runs, `playthrough` 4, `lore-values` 3, `starmap-consistency`, `lore-check`, `lens-assets`, `display-audit-controls` and `codex-unlocks` 2 each (V12). Each repeat is cheap (the `import` reruns are 1–2 s), so this is a hazard (H2), not a cost.

## Goals and non-goals

**Goals.**
- One instrument for before and after: per-target wall time and children's CPU seconds on serial and parallel runs, with a committed before/after report produced by one command from committed raw data. **Before and after both use GNU Make 4.4.1**, so the make version is not confounded with `-j`. The instrument also works on 3.81 (the fallback path), but a 3.81 run never enters the comparison.
- **Every fallback is loud.** A run that falls back to serial says so in the log (`rig-check FALLBACK <reason>`) and in the GitHub status (`SERIAL FALLBACK: <reason>`).
- `rig/full` wall time at most **0.5×** the serial baseline after M2 and at most **0.35×** after M3, both measured by that instrument under the comparability rule (AC9).
- **Coverage invariant:** the set of targets `make test` executes, and the number of recipe lines each executes, never shrink. It is proved mechanically on every parallel run.
- Local `make test` stays serial and unchanged (it is the dev-tag gate, CLAUDE.md "Tags"); `RIG_JOBS=1` restores today's serial `rig/full` in one variable.
- M1 and M2 land without touching `Makefile` or `mk/m45.mk`.

**Non-goals.**
- No test, check or assertion is removed or weakened. Removing a duplicate is a coverage-policy change and is OQ3, for Mark.
- No GitHub CI change (`ci-fast` stays as it is) and no `make golden` change.
- No change to the sim, the package, scenes or the game.
- Not fixing H10's root cause (wall-clock assertions in tests); they are isolated, not rewritten.

## Design

### Milestone 1: the instrument and the baseline (no `Makefile` edit)

**1a. `tools/timed_recipe_shell.sh` (≈ 28 lines).** A `SHELL` wrapper. It runs `/bin/sh "$@"` and then appends one tab-separated row per recipe line to `$SUITE_PROFILE_LOG`. Each row holds:
- start and end, in milliseconds (`perl -MTime::HiRes`);
- children's user + sys CPU seconds, from the shell builtin `times` written to a file in the same shell (a command substitution would run it in a subshell and read 0, V9);
- the exit code and `$MAKELEVEL`;
- the target, `$SUITE_TARGET`;
- the **top-level target**, `$SUITE_TOP_TARGET`.

It exits with the recipe's code. Each TSV row is written by a single `printf` invocation (`printf '%s\t...\n' ... >> "$SUITE_PROFILE_LOG"`), so the `O_APPEND` write is atomic under `-j` and concurrent recipe finishes cannot interleave partial lines (quorum round 2, gemini).

Make is invoked as `make SHELL=$PWD/tools/timed_recipe_shell.sh 'SUITE_TARGET=$@' …`. A command-line variable is exported to recipes and re-expanded per target, sub-makes included, on both makes (V9). Inside a sub-make, `$@` therefore names the sub-make's own target. Under `-j` that alone cannot say which top-level target a nested row belongs to.

**Top-level attribution.** The wrapper sets `SUITE_TOP_TARGET=${SUITE_TOP_TARGET:-$SUITE_TARGET}` and exports it before it runs the recipe. A top-level recipe line starts with the variable unset, so it records its own target. A `$(MAKE)` inside it inherits that value through the environment, and so does every deeper row. The result is deterministic under `-j`. `suite_profile.sh run` unsets `SUITE_TOP_TARGET` before starting make, so a caller's value cannot poison the attribution.

Rows with an empty target come from parse-time `$(shell …)` calls and are reported as `(parse)`.
- **Naming (a defensive rule, not a known failure).** The concern was that GNU Make might exec simple lines directly, bypassing a `SHELL` whose name starts with a shell's name. The controller tested three wrapper names, `timed_recipe_shell.sh`, `wrap.sh` and the deliberately shell-prefixed `shwrap`, over `@true` and `echo hi > /dev/null`. Every name logged 2 of 2 lines on 3.81 and on 4.4.1 (V40), so no bypass was observed. The name stays neutral anyway. The guard is the 1c control: a bare `@true` line must produce a row, on both makes.
- CPU caveats, stated in the report: a process that is not reaped through the chain (a daemon) is not counted, so Godot + sim targets' CPU is a lower bound.

**1b. `tools/suite_profile.sh` (≈ 110 lines, shell + awk; no Python).**
- `run [--make M] [--jobs N] [--out DIR] -- <make args>`: writes `DIR/profile.tsv` (the rows) and `DIR/header.txt` (sha, `M --version`, jobs, `hw.ncpu`, `vm.loadavg` at start and end, start/end epoch, rc) and passes make's rc through. It also starts a background sampler that appends `epoch<TAB>load1` rows to `DIR/load.tsv` every 30 s; the same trap that H15 adds kills it, and the sampler's PID is recorded in `header.txt` (quorum round 2, kimi). Load is therefore sampled during the run, not only at its edges.
- `summary TSV`: per top-level target (rows grouped by `SUITE_TOP_TARGET`, so nested rows fold into their parent): wall, CPU, CPU/wall, class (floor < 0.3 ≤ mixed < 0.9 ≤ cpu), share; the top 20; totals (wall, CPU-seconds, run span); and for a parallel run the busy-jobs histogram. Output is deterministic (sorted, fixed formats), so the committed summary is reproducible byte for byte.
- `targets TSV`: the sorted unique set of targets with at least one row, with their recipe-line counts.
- `compare BEFORE AFTER`: prints `missing=<n> fewer=<n> extra=<n>` and exits 1 if a target of BEFORE is absent from AFTER or runs fewer recipe lines. `extra` (repeats, e.g. a setup target run twice) is reported, not failed.
- `gap TRACELOG`: the `--trace` gap method used for the controller's baseline (this doc's numbers), and `agree TSV TRACELOG`: rc 0 iff every top-20 target's instrument wall is within max(2 s, 2 %) of its gap on the same run (AC3).
- `report BEFORE… -- AFTER…`: the before/after table (each run's span, CPU-seconds, start/end load, comparable or "loaded", medians and the ratio) that becomes the committed report (AC9).

**1c. `tools/test_suite_profile.sh` (≈ 70 lines).** Hermetic control on fixture makefiles under `mktemp -d` (trap right after `mktemp`): rc pass-through (a failing recipe gives make rc 2 and a row with rc 1); a bare `@true` line is logged; a sub-make row carries the child target and MAKELEVEL 2; **`top-target-j2`**: under `-j2`, two top-level targets `p` and `q` each `$(MAKE)` a child that sleeps 1 s, and every nested row carries its own parent (`p`'s child rows say `p`, `q`'s say `q`), even though the children overlap in time; a poisoned caller `SUITE_TOP_TARGET=x` changes nothing; `-j2` rows overlap in time; CPU of a busy loop ≥ 0.5 × its wall and of `sleep 1` ≤ 0.1 s; `compare` reports `missing=1` when one target's rows are deleted; per-line overhead ≤ 50 ms over 200 trivial lines. Run on `/usr/bin/make` and `gmake`.

**1d. `tools/rig_check.sh` (≈ 20 lines).** The serial suite runs as `tools/suite_profile.sh run --make gmake -- test`, still serial, when two things hold: the PR clone has the tool, and `gmake` is on `PATH`.
- `RIG_TRACE=1` adds `--trace`, for the AC3 run.
- The raw rows land beside the log as `<sha>.profile/`, and the log ends with the summary's top 10.
- The watchdog wraps the same command as today.

**Every other branch is a loud fallback.** It writes one line `rig-check FALLBACK <reason>` to the log, and the success status reads `make test green (SERIAL FALLBACK: <reason>) in N min …`, cut to 140 characters as today. The M1 reasons are:
- `RIG_PROFILE=0`: plain `make test`.
- `profile-absent`: an older PR head without the tool; plain `make test`.
- `gmake-missing`: the profiler on 3.81 (`--make make`). In M1 this is a fallback. After M2 it becomes a failure; see 2d and OQ4.

**1e. `tools/test_rig_check.sh` (≈ 25 lines).** Its stub `make` must now be reached through the profiler, and the control gains a stub `gmake` so the real `/opt/homebrew/bin/gmake` is never reached (V26). New cases:
- `profile-on`: the stub `gmake` sees `SHELL=…timed_recipe_shell.sh` and `test`, and the log has no `FALLBACK` line.
- `profile-off`, `profile-absent` and `gmake-missing`: each asserts the right command, the log line `rig-check FALLBACK <reason>`, and a success description that contains `SERIAL FALLBACK: <reason>` and is at most 140 characters.

The caller-poison case gains `RIG_PROFILE`, `RIG_TRACE` and `SUITE_TOP_TARGET`. For `profile-on`, the stub `git clone` copies the real profiler into the fake clone. This control is already in `make test` through `rig-check-control` (`mk/m45.mk:54-57`), so M1 needs no make wiring. `tools/test_suite_profile.sh` is called from it as one more case.

**1f. The baseline (the "before").** The baseline is the median of **at least three comparable serial runs on GNU Make 4.4.1, recorded by the instrument** (`--make gmake`), matching the after side's n = 3 (quorum round 2, kimi: a median of 2 is not a median given the rig's 66–117-min spread). One of them also passes `--trace`, so on that run the gap method and the instrument can be compared (AC3). Using gmake on both sides keeps the make version from being confounded with `-j`, because the after runs use gmake too.

A **3.81 run is kept only as evidence for the fallback path** (`--make make`): it shows the instrument and the serial fallback work on the system make. It never enters the AC9 median.

**Saving rig hours: M1's own `rig/full` runs are the baseline runs.** M1 adds no make target and changes no recipe line, so its closure hash equals main's and `compare` accepts it (Coverage invariant, item 2). The controller runs `tools/rig_check.sh <M1 PR>` from the M1 branch three times:
1. `RIG_TRACE=1` gives `before-gmake-1.tsv` and `before-gmake-1.trace.log` (AC3).
2. The default gives `before-gmake-2.tsv`.
3. The default again gives `before-gmake-3.tsv` (the third baseline run; quorum round 2, kimi).
4. `PATH` without `gmake` gives `fallback-make381.tsv` and exercises the `gmake-missing` fallback end to end.

(So the controller runs it four times, not three.)

Those are the runs M1's landing needs anyway. A run that fails the AC9 load rule is repeated under the same rule.

**Committed outputs:**
- `design_docs/planned/r1/rig-test-speed-report.md`: the `report` output, moved to `implemented/` at landing.
- Per run, under `design_docs/planned/r1/rig-test-speed-data/`: `<name>.tsv`, `<name>.header.txt` and `<name>.summary.txt` (the `summary` output). About 1,500 rows, roughly 120 KB per TSV.

The controller's existing gap-method run (`/tmp/stap56/profile.ts.log`: gmake `--trace`, serial, 4,123 s, `[rig profile c2e70e15]`) is quoted in the report as the independent cross-check. Note for the planner: it is the same make and the same mode as the new baseline, so the two should agree to within load noise.

### Milestone 2: parallel lanes on the rig (no `Makefile` edit)

**2a. `tools/suite_lanes.txt` (≈ 25 lines, committed).** The hand-curated knowledge, one line each:
- `setup: import deps starmap-assets lens-assets deps-ai planet-assets` — in the order serial `make test` first reaches them (V5), so the setup stage does not change which files exist when `import` runs.
- `lane replay: replay tools-test parity-m4 .godot/tmp/replay/m4_min_path.vm.ndjson codex-unlocks replay-compat replay-scene` (H5), `lane ai-settings: ai-live-guard ai-settings` (H6), `lane ai-relay: ai-relay replay-noai` (H7). Every lane lists its members in the order serial `make test` reaches them (V38), so a lane only removes overlap; it never reorders.
- `exclusive: crew-perf ship-demo-launch-test` with the reason (H10). The H2 targets are **computed**, not listed (2b), so #344's new `display-audit-comms` is picked up without an edit.

**2b. `tools/suite_parallel.sh` (≈ 120 lines, shell + awk).**
- `plan`: dumps the database with `gmake -pq --eval='__nop__:' __nop__` (V3; never `make -p` or a bare `make -qp`, which run the default goal's `$(MAKE)` lines, as iteration 55 found), computes `closure(test)`, and derives:
  - `EXCL` = the listed exclusive targets ∪ every closure target with a `$(MAKE)` line whose goals' closure reaches a setup target other than `lens-assets` (today: `scene-session-audits`, `playthrough-adversarial`, `display-audit-interlude`, `display-audit-crew`; V11).
  - `P1` = `test`'s direct prerequisites minus setup minus `EXCL`; `P2` = `EXCL` in serial order.
  - A generated `.godot/tmp/suite/edges.mk` holding only the lane chains (`b: | a`, `c: | b`). Setup needs no edges here, because it runs to completion before P1 starts and is `-o` in P1; M3 declares the real `import`/`deps` edges in the makefiles.
- `check`: fails (rc 1) on a name in `suite_lanes.txt` that is not in the closure (a rename), a `*-mutants` target in the closure (H12), make's "Circular … dependency dropped" warning on the edges, or a closure target with a rule that neither `P1` (minus `-o` subtrees) nor `P2` reaches. "Reaches" includes the generated order-only lane edges in `edges.mk`, so a pattern- or explicitly-ruled prerequisite file covered by a lane (such as `$(M45_STATE)`, V43) counts as reached (quorum round 2, glm). It prints `plan: setup <a>, P1 <b> goals, P2 <c> goals, lanes <d>, closure covered <e> of <e>`.
- `run --jobs N`: setup serially; then **P1**: `gmake -j N --output-sync=target -f Makefile -f .godot/tmp/suite/edges.mk -o <each setup and EXCL target> <P1>`; then **P2**: `gmake -o <each setup target> <P2>`, serial. Both through the M1 instrument (one TSV). It stops at the first red phase with make's rc. `-o` stops a target and its prerequisites from being remade at top level (V8), so an exclusive target reached through an aggregator such as `ship-demo-ci` waits for P2. A trap kills the process group on `ALRM`, `TERM` and `INT` (H15). Before P1 it stamps; after P2 it prints `godot cache writes outside .godot/tmp during P1: <n>` (files under `.godot/` newer than the stamp, excluding `tmp/`, recorded at the P1/P2 boundary) and the `user://` paths written (H9).

**2c. `tools/test_suite_parallel.sh` (≈ 70 lines).** Hermetic fixture makefile: a missing-edge target that fails if setup has not run (passes under the runner, fails under plain `-j`), a lane whose second member reads the first's file, an exclusive target behind an aggregator (must run in P2 only), a lane naming an unknown target (`check` rc 1), a lane cycle (`check` rc 1), and `compare` of the serial and runner TSVs (`missing=0 fewer=0`). Called as a case from `tools/test_rig_check.sh`.

**2d. `tools/rig_check.sh` (≈ 12 lines) and its control (≈ 20).** The script sets `jobs=${RIG_JOBS:-6}`.
- **Parallel path.** When `jobs > 1`, `gmake` is on `PATH` and the clone has `tools/suite_parallel.sh`, it runs `suite_parallel.sh run --jobs $jobs` under the watchdog. The status reads `make test (-j6 lanes) green on the Studio in N min (…)`, cut to 140 characters as today.
- **Loud fallbacks.** Each fallback runs M1's serial path, writes `rig-check FALLBACK <reason>` to the log, and posts `make test green (SERIAL FALLBACK: <reason>) in N min …`:
  - `RIG_JOBS=1`: the operator's explicit opt-out.
  - `parallel-absent`: a PR head that predates M2, i.e. a property of the PR, not of the rig.
- **A missing `gmake` with `RIG_JOBS` unset is a failure, not a fallback.** The script posts `failure` with `gmake not found; set RIG_JOBS=1 to run serial` and exits 1.
  - The reason: on the Studio, a missing `gmake` is a broken rig, not a property of the PR. Falling back silently would quietly bring back the 69–117-min serial suite that L4 exists to remove, and the PR's status would not show it.
  - The explicit `RIG_JOBS=1` keeps every PR mergeable while the rig is repaired.
  - This changes how the merge gate fails, so it is **OQ4**, with this as the default.
- **New control cases** (the stub `gmake` from 1e is reused):
  - `parallel-on`;
  - `serial-jobs1`, `parallel-absent`: each asserts its FALLBACK line and its `SERIAL FALLBACK:` description;
  - `parallel-no-gmake`: no `gmake` stub on `PATH`, `RIG_JOBS` unset; asserts rc 1, a `failure` post naming `RIG_JOBS=1`, and that `make test` was never started;
  - `no-gmake-jobs1`: no `gmake`, `RIG_JOBS=1`; asserts serial 3.81 with the FALLBACK marker.
  - Caller-poison gains `RIG_JOBS`.

**2e. `mk/home-tiers.mk` (4 lines).** H4: `home-art-check` writes `counts-art.txt`, `home-site-check` writes `counts-site.txt`. Same commands, same assertions.

**Why `N = 6` by default.** 12 performance cores; a background 1-min load of 2.5–7 on a normal day (V29); most targets assumed single-threaded until M1 measures CPU/wall; the timing-sensitive targets are already outside P1. M2 measures 6 and 8 (AC9) and sets the default from the measurement. **Estimate:** setup ≈ 15 s; P1 ≥ `sim` 740 s (the longest indivisible target); P2 ≈ 290 s (`playthrough` 86, `playthrough-adversarial` 87, the other three H2 targets 31, `crew-perf` 36, `ship-demo-launch-test` 44, import reruns). Expected ≈ 18–22 min against 68.7 min, which leaves margin under the 0.5× goal.

### Milestone 3: real edges, a sharded sim suite (**edits `Makefile`; held**)

**Resume predicate (a command):** `test "$(gh pr view 344 --json state -q .state)" != OPEN && test "$(gh pr view 346 --json state -q .state)" != OPEN`. Until it holds, M3 is not started. After it holds, M3 rebases, re-runs `suite_parallel.sh check` and re-takes one serial baseline (#344 adds `feed-art-check`, `display-audit-comms`, `comms-station-test` and `earth-feed-test` to the closure; #346 adds `star-names`; V24).

- **3a. Shard `sim`'s unit suite (`Makefile`, ≈ 30 lines).** The target becomes `sim: sim-check sim-unit sim-bridge`, with `sim-unit: sim-unit-1 … sim-unit-K`.
  - **How a shard runs.** Each shard runs `cd sim && ailang test <file> <file> …` over a fixed, committed file list, using **positional file paths, not `--package`**. The controller measured both forms on v0.54.18 (V39):
    - `--package . <file>` is refused: `--package takes one package directory, got 2 paths`.
    - `ailang test rng_test.ail protocol_test.ail` runs: rc 0, `41 tests: 41 passed`, 22.8 s wall, 39.1 s user (173 % CPU). The runner is already partly parallel inside one process.

    No syntax spike is owed.
  - **Still unmeasured:** what each shard pays to compile (the whole suite pays ≈ 62 s, V30), and how the runner's own parallelism interacts with `-j`. The sprint measures both before it fixes K.
  - **Sizing.** K = 4 as a starting point, greedy-balanced from the M1 baseline's per-file times. Today's data gives a 105 s floor from `crew_hold_test.ail` and about 130 s of tests per shard, plus the unmeasured compile.
  - `ailang test` has no `--jobs` option (V27); the sprint sends that to AILANG as a DX request (`ailang messages`, inbox `user`).
  - **What the shards partition: the package's 50 test files** (V39). That is the 34 `sim/*_test.ail` plus the 16 `sim/tools/*_test.ail`, matching the "50 test files" `ailang test --package .` reports (V30). A `sim/`-only listing (34) would silently drop the 16 tool tests.
  - **Coverage check (AC15).** It fails if the shards' `--json` test counts do not sum to the `--package` count (554 today). It also fails unless the union of the shard lists equals both `git ls-files 'sim/*_test.ail' 'sim/tools/*_test.ail'` and the count `--package` reports, with no file in two shards. So a test file that `--package` discovers but no shard lists, such as a new file added later, turns it red. `sim-check` (the `ailang check --package sim` gate kept for STRICT_FALLBACK_001, CLAUDE.md) and `sim-bridge` (`test_sim_bridge.gd` + `bh-hud-test`) are unchanged commands.
- **3b. Declared edges (≈ 45 lines).** A new `mk/test-edges.mk`, included from `Makefile` (one `include` line): `$(GODOT_TESTS): | import`, `$(AILANG_TESTS): | deps`, `$(AI_TESTS): | deps-ai`, with the lists generated once by `suite_parallel.sh plan` and committed, plus, in `mk/m45.mk` (H5), `parity-m4: $(M45_STATE)` and `$(M45_STATE): | replay` (so the rule and `replay` never write the file at once). `suite_parallel.sh check` gains "a closure target that starts Godot without reaching `import` fails".
- **3c. A stamped `import` (≈ 10 lines).** `import` runs Godot once per make run and touches `$(SCRATCH)/import.stamp`; a nested make sees the stamp of its top-level run and skips (keyed on an exported `SUITE_RUN_ID`, so a new run always imports). That removes H2, and the four sub-make targets leave `EXCL`.
- **3d.** `suite_lanes.txt` keeps only the lanes that 3b does not replace; the generated edges file shrinks to the lanes.

## Coverage invariant

1. **Static, every run:** `sh tools/suite_parallel.sh check` proves the plan reaches every closure target with a rule (`closure covered e of e`).
2. **Dynamic, every parallel run:** `sh tools/suite_profile.sh compare <serial baseline TSV> <this run's TSV>` gives `missing=0 fewer=0`. The serial baseline is re-taken whenever the closure changes (the plan prints the closure's sha256; `compare` refuses TSVs whose closure hashes differ, so a stale baseline cannot pass silently).
3. **Unit-test level (M3):** the shard counts sum to the package count, and the shard file lists partition the package's 50 test files (`sim/` and `sim/tools/`).

The closure hash in item 2 is the sha256 of the sorted closure target names, so a tools-only change such as M1 keeps the hash and a new or removed target changes it.

## Acceptance criteria

Run from the implementation root after saving the drill block (below) as `.godot/tmp/suite-drills.sh` (ignored, V36). Load is the 1-min `vm.loadavg`.

| # | Criterion | Command | Expected |
|---|---|---|---|
| AC1 | The instrument's control is green on both makes | `sh tools/test_suite_profile.sh > .godot/tmp/sp.log 2>&1; echo rc=$?; tail -1 .godot/tmp/sp.log` | `rc=0`, `suite-profile control: <k> cases, 0 failures` (k ≥ 8, each run on `make` and `gmake`) |
| AC2 | The committed baseline summaries are reproducible from the committed raw data | `rc=0; for n in before-gmake-1 before-gmake-2 fallback-make381; do sh tools/suite_profile.sh summary design_docs/planned/r1/rig-test-speed-data/$n.tsv \| cmp - design_docs/planned/r1/rig-test-speed-data/$n.summary.txt \|\| rc=1; done; echo rc=$rc` | `rc=0` |
| AC3 | The instrument agrees with the `--trace` gap method on the same gmake run | `sh tools/suite_profile.sh agree design_docs/planned/r1/rig-test-speed-data/before-gmake-1.tsv design_docs/planned/r1/rig-test-speed-data/before-gmake-1.trace.log; echo rc=$?` | `rc=0`; every top-20 target within max(2 s, 2 %). The controller's `/tmp/stap56/profile.ts.log` (4,123 s) is quoted beside it as the cross-check, not asserted. |
| AC4 | The rig-check control is green with the new cases | `env -u RIG_TEST_S -u RIG_GOLDEN_S -u RIG_PROFILE -u RIG_JOBS -u RIG_TRACE -u SUITE_TOP_TARGET sh tools/test_rig_check.sh tools/rig_check.sh \| tail -1; echo rc=$?` | `rig-check control: <n> cases, 0 failures` (n = 8 + the M1/M2 cases), `rc=0` |
| AC5 | The fallbacks are loud, and a missing `gmake` fails | after AC4 with its output saved to `.godot/tmp/rc.log`: after M1: `grep -c -E '^rig-check control (profile-off\|profile-absent\|gmake-missing): ok$' .godot/tmp/rc.log`; after M2 (`gmake-missing` is retired at M2, since 1d makes it a failure; quorum round 2, glm): `grep -c -E '^rig-check control (profile-off\|profile-absent\|serial-jobs1\|parallel-absent\|no-gmake-jobs1\|parallel-no-gmake): ok$' .godot/tmp/rc.log` | `3` after M1; `6` after M2. The cases assert, respectively, the log line `rig-check FALLBACK <reason>` and a ≤ 140-character success description containing `SERIAL FALLBACK: <reason>` (the five fallback cases after M2), and rc 1 with a `failure` post naming `RIG_JOBS=1` and no `make test` started (`parallel-no-gmake`). |
| AC6 | The plan covers the closure, with no unknown lane name, cycle or mutant target | `sh tools/suite_parallel.sh check; echo rc=$?` | `plan: … closure covered <e> of <e>`, `rc=0` |
| AC7 | **Coverage invariant** on each rig run of M2 (and M3) | `sh tools/suite_profile.sh compare design_docs/planned/r1/rig-test-speed-data/before-gmake-1.tsv "$TMPDIR/rig-check/<sha>.profile/profile.tsv"; echo rc=$?` | `missing=0 fewer=0 extra=<x>`, `rc=0` |
| AC8 | No cache or tracked-file side effect from parallelism | the runner's own lines in the rig log: `grep -c '^godot cache writes outside .godot/tmp during P1: 0$' <log>`; `git -C <rig clone> status --porcelain \| sort \| cmp - <baseline status list>` | `1`; `cmp` rc 0 (the 5 known `*.translation` files only, V35) |
| AC9 | **Before/after wall time, comparable, same make** | `sh tools/suite_profile.sh report design_docs/planned/r1/rig-test-speed-data/before-gmake-*.tsv -- design_docs/planned/r1/rig-test-speed-data/after-j6-*.tsv design_docs/planned/r1/rig-test-speed-data/after-j8-*.tsv` | The report prints each run's make version, span, CPU-seconds and start/end load, and refuses (rc 1) any TSV whose header is not GNU Make 4.4.1. A run is **comparable** only if every sampled 1-min load in its `load.tsv` is ≤ 5.0. If the Studio's normal mid-run background makes that unachievable, the rule becomes: sampled median ≤ 5.0 and no sample > 8 (8 sits just above V29's observed 7.3 plateau). The report prints each run's load median and max from `load.tsv`, and refuses (rc 1) any TSV that has no load sample file, so a run made without the instrument cannot be certified (quorum round 2, kimi). A run that fails the rule is repeated, at most twice per slot. **Baseline:** the median of the ≥ 3 comparable serial gmake runs from 1f. **M2:** the median of 3 comparable `-j6` runs must be ≤ **0.5 ×** the baseline, and one `-j8` run is recorded. **M3:** ≤ **0.35 ×**. **Exhaustion:** if fewer than 3 comparable `-j6` runs survive the load rule after the two permitted repeats, M2 does not land. The blockage goes to Mark; it is not certified on excluded runs. CPU-seconds are reported as the load-insensitive second measure. `fallback-make381.tsv` never enters a median. |
| AC10 | `make test` green (gate 1), serial and local, on the M1/M2 tree | `PATH=$PWD/runtime/bin:$PATH make test > .godot/tmp/mt.log 2>&1; echo rc=$?` | `rc=0` |
| AC11 | `rig/full` green on each milestone's PR, three times for M2 (stability) | `tools/rig_check.sh <PR>` (×3 for M2) | three `rig/full` successes, each with AC7 and AC8 holding |
| AC12 | Drills: every new guard kills its mutant | `for m in R C D L E; do sh -c ". .godot/tmp/suite-drills.sh; drillsp \"$PWD\" $m"; echo "$m rc=$?"; done` | `drillsp R: killed`, `C: killed`, `D: killed`, `L: killed`, `E: killed`, each `rc=0` |
| AC13 | Scope: M1 and M2 touch no held file and add no Python | `git diff --name-only origin/main...HEAD \| grep -c -x -E 'Makefile\|mk/m45\.mk\|mk/earth-link\.mk\|tools/import_keep\.txt\|tools/python-allowlist\.txt\|tools/python_guard\.sh'; git diff --name-only origin/main...HEAD \| grep -c '\.py$'` | `0`, `0` |
| AC14 | M3 resume predicate holds before M3 starts | `test "$(gh pr view 344 --json state -q .state)" != OPEN && test "$(gh pr view 346 --json state -q .state)" != OPEN; echo rc=$?` | `rc=0` |
| AC15 | M3: the shards partition the unit suite | `sh tools/suite_parallel.sh shards-check; echo rc=$?` (runs each shard with `--json`, sums the counts, compares against `cd sim && ailang test --package . --json`, and checks the file partition) | `shards: <K> shards, <t> tests = package <t>, files <f> = package <f>`, `rc=0` |
| AC16 | M3: every Godot closure target reaches `import` | `sh tools/suite_parallel.sh check --edges; echo rc=$?` | `godot targets without import: 0`, `rc=0` |

### Drill block (hardened shape)

The drills mutate **scratch copies** only, take an explicit ROOT, set the trap right after `mktemp`, prove the mutation with `cmp` (exit 3 if it did not apply), pass the control's rc through, assert counts with `test`, use no `!`-negated assertion, and give every check its own `|| exit 1`. The executor validates the block verbatim before AC12 and records the RED run (the drill on `origin/main` copies must fail at its baseline because the controls do not exist yet).

```sh
# drillsp ROOT MUTANT, on scratch copies of tools/ (the tree is never edited):
#   R  timed_recipe_shell.sh always exits 0          -> test_suite_profile.sh FAILs case rc-passthrough
#   C  suite_profile.sh compare ignores missing rows -> test_suite_profile.sh FAILs case compare-missing
#   D  rig_check.sh ignores RIG_JOBS=1               -> test_rig_check.sh FAILs case serial-jobs1
#   L  suite_parallel.sh drops the lane edges        -> test_suite_parallel.sh FAILs case lane-order
#   E  suite_parallel.sh puts EXCL into P1           -> test_suite_parallel.sh FAILs case exclusive-p2
drillsp() (
  set -u
  ROOT=${1:?explicit checkout ROOT required}
  mutant=${2:?R, C, D, L or E required}
  cd "$ROOT" || exit 2
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-sp.XXXXXX") || exit 2
  trap 'rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  cp -R tools "$T/tools" || exit 2
  case "$mutant" in
    R) f=tools/timed_recipe_shell.sh; ctl=tools/test_suite_profile.sh; want=rc-passthrough
       sed 's/; exit \$rc$/; exit 0/' "$T/$f" > "$T/m" || exit 2 ;;
    C) f=tools/suite_profile.sh; ctl=tools/test_suite_profile.sh; want=compare-missing
       sed 's/^\( *\)missing=\$((missing + 1))/\1:/' "$T/$f" > "$T/m" || exit 2 ;;
    D) f=tools/rig_check.sh; ctl=tools/test_rig_check.sh; want=serial-jobs1
       sed 's/^jobs=\${RIG_JOBS:-6}/jobs=6/' "$T/$f" > "$T/m" || exit 2 ;;
    L) f=tools/suite_parallel.sh; ctl=tools/test_suite_parallel.sh; want=lane-order
       sed 's/^\( *\)emit_lanes /\1: emit_lanes /' "$T/$f" > "$T/m" || exit 2 ;;
    E) f=tools/suite_parallel.sh; ctl=tools/test_suite_parallel.sh; want=exclusive-p2
       sed 's/^\( *\)p1=\$(minus "\$p1" "\$excl")/\1:/' "$T/$f" > "$T/m" || exit 2 ;;
    *) exit 2 ;;
  esac
  rc=0; (cd "$T" && env -u RIG_TEST_S -u RIG_GOLDEN_S -u RIG_PROFILE -u RIG_JOBS sh "$ctl" > "$T/base.log" 2>&1) || rc=$?
  test "$rc" -eq 0 || exit 1
  cmp -s "$T/$f" "$T/m" && exit 3
  cp "$T/m" "$T/$f" || exit 2
  rc=0; (cd "$T" && env -u RIG_TEST_S -u RIG_GOLDEN_S -u RIG_PROFILE -u RIG_JOBS sh "$ctl" > "$T/mut.log" 2>&1) || rc=$?
  test "$rc" -eq 1 || exit 1
  got=$(sed -n 's/^.* control \([a-z0-9-]*\): FAIL.*/\1/p' "$T/mut.log" | tr '\n' ' ')
  test "$got" = "$want " || exit 1
  echo "drillsp $mutant: killed ($want)"
)
```

The `sed` anchors name the lines the executor writes; if the implementation's lines differ, the executor adjusts the anchor so the `cmp` proof still fires (exit 3 otherwise), and records the change in the sprint JSON. The `test_rig_check.sh` control's own `caller-poison` case re-runs it nested; drill D's expected set therefore includes `caller-poison` if the nested run also fails, and the executor pins the exact set after the RED/GREEN runs, as iteration 55 did.

## Sub-milestones and estimates

| Step | Files | LOC | `Makefile`? | Order |
|---|---|---:|---|---|
| **M1** instrument + baseline | `tools/timed_recipe_shell.sh` (new, 28), `tools/suite_profile.sh` (new, 110), `tools/test_suite_profile.sh` (new, 75), `tools/rig_check.sh` (+20), `tools/test_rig_check.sh` (+25); `design_docs/planned/r1/rig-test-speed-report.md` + `rig-test-speed-data/` (data) | ≈ 258 | **no** | First, as one PR. Its own three `rig/full` runs are the baseline (1f). At ≈ 258 lines it sits at the limit; if the executor's count passes 270, the `rig_check.sh`/control wiring (1d, 1e, ≈ 45) splits off as **M1b**, landing after M1a, and the baseline runs move to M1b's PR. |
| **M2** lanes on the rig | `tools/suite_lanes.txt` (new, 25), `tools/suite_parallel.sh` (new, 120), `tools/test_suite_parallel.sh` (new, 70), `tools/rig_check.sh` (+12), `tools/test_rig_check.sh` (+20), `mk/home-tiers.mk` (4) | ≈ 251 | **no** | After M1 lands. Needs at least 3 comparable `-j6` runs plus 1 `-j8` run (AC9 exhaustion rule applies) and AC11. |
| **M3** edges + shards | `Makefile` (**yes**: `sim` split ≈ 30, one `include`, `import` stamp ≈ 10), `mk/test-edges.mk` (new, ≈ 45), `mk/m45.mk` (**held by #344**, 1 line), `tools/suite_lanes.txt` (−), `tools/suite_parallel.sh` (+ `shards-check`, `check --edges`, ≈ 30) | ≈ 120 | **yes** | only after AC14 holds; one serial re-baseline first |

The `.uid` rule (CLAUDE.md) does not apply: no `.gd` or shader is added. Each new `tools/*.sh` needs no allowlist entry (only `*.py` are listed).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A hidden dependency not found by this audit makes a parallel run flaky (red on a green tree). | Three green `-j6` runs before M2 lands (AC11); `RIG_JOBS=1` restores serial in one variable; any flake is diagnosed from the per-target TSV (which target started when) and fixed with a lane. Iteration 55's `ship-demo-launch` flake is already isolated in P2. |
| A parallel run passes where serial would fail (a test that depends on something another target leaves behind, which parallel order happens to provide). | Local `make test` stays serial (the dev-tag gate); M1's instrument keeps a serial baseline per closure change; AC10 runs serial `make test` on every milestone. |
| The instrument changes behaviour (`SHELL` override). | It execs the same `/bin/sh`; rc pass-through, sub-make naming and `-j` overlap are controlled (AC1); `RIG_PROFILE=0` turns it off. Per-line overhead ≤ 50 ms is asserted; with ≈ 1,500 recipe lines that is ≤ 75 s, about 2 % of a serial run, and it is the same on both sides of the comparison. |
| `gmake` 4.4.1 parses or runs the Makefile differently from 3.81. | `gmake --trace test` is already green on `c2e70e15` (V29), and GitHub's `ci-fast` runs Linux make 4.x. Before and after both use gmake (1f, AC9), so a version effect cannot pose as a `-j` effect. The 3.81 fallback run (`fallback-make381.tsv`) shows the fallback path works. Local `make test` stays on 3.81. |
| The rig's load varies (2.5–20 seen). | The comparability rule (AC9), load sampled every 30 s through the run (`load.tsv`), medians of ≥ 3, and CPU-seconds as a second measure. |
| `-j` raises the rig's load for attended sessions running beside it. | `N` defaults to 6 of 12 performance cores and is a variable; the suite finishes sooner, so the total CPU-seconds are unchanged. |
| #344 or #346 changes the closure before M2 lands. | `suite_parallel.sh` derives everything from the database; `check` fails on a stale lane name; `compare` refuses a baseline from a different closure. |
| The fixed `perl alarm` kills only the top process. | The runner traps and kills its process group (H15). |

## Open questions for Mark

| # | Question | Recommendation | Default if unanswered |
|---|---|---|---|
| OQ1 | May `rig/full` run `make test`'s targets as the parallel runner (setup, then `-j6` lanes, then the exclusive set) instead of one serial `make test`, given the coverage invariant is proved on every run (AC6, AC7) and `RIG_JOBS=1` restores serial? Local `make test` stays serial. | Yes: L4's text asks for parallelisation without losing coverage, and the proof is mechanical. | **Yes.** M2 ships `RIG_JOBS` defaulting to 6, and it cannot land before AC9 and AC11 (three green parallel runs, coverage proved on each) are recorded. A "no" from Mark is a one-line change of the default to 1. |
| OQ2 | Use Homebrew GNU Make 4.4.1 (`gmake`) on the rig instead of the system make 3.81? From M1, the serial instrumented run uses it; from M2, so does the parallel phase. **Cost:** one more tool the rig depends on. It is already installed, and the rig already depends on Homebrew's `shellcheck`, `dash` and `jq`. **Gain:** `--output-sync=target` keeps each target's output in one block, so a red log stays readable; `--eval` gives a safe database dump; and before and after run on the same make (AC9). 3.81 has neither feature, and its interleaved `-j` output would make failures hard to read. | Yes. | **Yes.** In M1 a missing `gmake` falls back, loudly, to 3.81; from M2 it is OQ4. |
| OQ3 | Remove true duplicates? Candidates, re-checked today: `checkN3` runs in `ailang test` **and** in `catalogue-vm quotaVm` on both engines (`sim/tools/catalogue_test.ail:133,148`); the `navigation_test`/`navigationVm`, `trappist1_test`/`trappistVm` and D65/`directHighlightsVm` overlaps listed in the old doc (overlap not re-measured); `playthrough` re-entered 4 times and `import` 5 times (cheap, and M3 fixes `import`). | Keep all of them for L4; decide separately per item after M3's measurements, because each removal is a coverage-policy change. | **Keep everything.** |
| OQ4 | After M2 lands, should a Studio with no `gmake` on `PATH` and no explicit `RIG_JOBS=1` **fail** `rig/full` (`gmake not found; set RIG_JOBS=1 to run serial`) or fall back loudly to serial? | **Fail** (kimi's proposal, adopted). A missing `gmake` is a broken rig, not a property of the PR, and a fallback would quietly bring back the 69–117-min suite. `RIG_JOBS=1` is the explicit, visible way to merge while the rig is repaired. A PR head that predates M2 (`parallel-absent`) still falls back loudly, because that is a property of the PR. | **Fail.** The `parallel-no-gmake` case asserts it (AC5). |

## Deliverables

- M1: `tools/timed_recipe_shell.sh`, `tools/suite_profile.sh`, `tools/test_suite_profile.sh`; the `rig_check.sh` profile path and its control cases; the before report and raw data.
- M2: `tools/suite_lanes.txt`, `tools/suite_parallel.sh`, `tools/test_suite_parallel.sh`; the `RIG_JOBS` path and its control cases; `mk/home-tiers.mk`'s split scratch files; the after report (same command as the before).
- M3 (held): the `sim` shards, `mk/test-edges.mk`, the stamped `import`, `parity-m4`'s declared state file; an updated report.
- An AILANG DX report: `ailang test --jobs N` (or file-parallel package tests), with the per-file timings as evidence.
- A changelog entry per milestone; the report moves to `design_docs/implemented/r1/rig-test-speed-report.md` at landing.

## Verification log

All rows were run by the designer on 2026-10-28 in `/Users/voightkampff/dev/sunholo-data/.stap-iter56-src` at `c2e70e15` (branch `mission/stapledon-iter56-l4`), read-only except scratch probes under `/tmp/stap56-designer/` (fixture makefiles, not the repo), unless the row names the controller's profile clone `$TMPDIR/stap56-profile/c2e70e15…` (read-only `stat`, `find`, `git status`). No `make test`, `make -j` or long target was run while the profile ran.

| # | Claim | Command | Observed |
|---|---|---|---|
| V1 | The rig's makes | `which -a make gmake; make --version \| head -1; gmake --version \| head -1` | `/usr/bin/make`, `/opt/homebrew/bin/gmake`; `GNU Make 3.81`; `GNU Make 4.4.1` |
| V2 | The Studio | `sysctl -n hw.ncpu hw.perflevel0.physicalcpu hw.perflevel1.physicalcpu hw.memsize` | `16`, `12`, `4`, `137438953472` |
| V3 | A safe database dump | `gmake -pq --eval='__nop__:' __nop__ > db.txt; echo rc=$?`; on a fixture whose `x` recipe echoes `x`: `make -pq -f Makefile4 __nop__` and `gmake -pq -f Makefile4 __nop__`, then `grep -c '^agg:'` and `grep -c '^x$'` | rc 0, 5,542 lines; fixture: rc 2 on both, the rule printed (`agg` 1), recipe not run (`x` 0) |
| V4 | `test`'s size | `grep '^test:' db.txt \| tr ' ' '\n' \| sed 1d \| grep -c .`; an awk closure over the `# Files` section | 108 direct prerequisites; closure 258 names; 187 have a rule |
| V5 | Serial order of setup targets | the direct-prerequisite list (V4): `python-guard` is 28th, after 27 `mk/*.mk` targets; in the profile, `grep "update target"` positions | `import` 5, `python-guard` 30, `uid-guard` 31, `deps` 33, `starmap-assets` 34, `lens-assets` 35, `deps-ai` 107, `planet-assets` 126 |
| V6 | Missing edges | awk over the db: closure targets whose recipe matches `$(GODOT)`/`$(GODOT_SIM)`/`godot `, reachability of `import`; same for `$(AILANG)` and `deps` | 105 Godot targets, 35 without `import` (`sim ui physics m4-smoke area-test transit-test codex-test news-test planets-test …`); 58 AILANG targets, 58 without `deps` |
| V7 | Recursive targets in the closure | the same awk, recipes containing `$(MAKE)` | 13: `lore-test lens-assets parity-m4 playthrough-adversarial starmap-consistency-large ism-lore-drafts sim starmap-assets scene-session-audits display-audit-interlude ai-core-verify display-audit-crew lore-import-check` |
| V8 | `-o` and sub-makes | fixture `all: setup a; a: ; $(MAKE) b; b: setup`; `make -o setup all`, `gmake -o setup all`, `MAKEFLAGS='-o setup' gmake all`; fixture `agg: x y; x: p`, `make -o x all` | top-level `setup` skipped, the sub-make's `setup` runs (MAKELEVEL 1) on both; env MAKEFLAGS: same; `-o x` runs only `y` (x's prerequisite `p` skipped) on both |
| V9 | The `SHELL` wrapper prototype | fixture with `a b c`, `c: a; $(MAKE) d`, run `-j3` with `SHELL=$PWD/tsh.sh 'MAKE_TARGET=$@'` on both makes; a busy loop and `sleep 1` with `times > file` (and with `$(times)`) | rows for `a b b d c` with the right names, sub-make `d` included, on 3.81 and 4.4.1 without `--eval`; CPU: busy 0.64 s for 0.64 s wall, sleep 0.01 s for 1.03 s; `$(times)` reads 0.00 (subshell) |
| V10 | Lock rewrites | `git grep -n -E '(\$\(AILANG\)\|ailang) lock' -- Makefile 'mk/*.mk'` with target attribution | `deps` (`Makefile:39,40`, `git checkout` at 42), `deps-ai` (`mk/ai.mk:38`, checkout 39); `glow-probe`, `runtime`, `ai-runtime` not in the closure |
| V11 | `import` re-entered by sub-makes | `grep -m1 '^<t>:' db.txt` for `playthrough display-audit display-audit-interlude display-audit-crew scene-session-audits`; `git grep -n '\$(MAKE)' -- Makefile 'mk/*.mk'` | `playthrough: import`; `display-audit: import display-audit-controls`; `display-audit-interlude: import display-audit-controls`; `display-audit-crew: import display-audit-controls`; `scene-session-audits: playthrough`; `$(MAKE) … playthrough`/`display-audit` at `mk/m45.mk:14,90,94,96,169,181`, `Makefile:1255` |
| V12 | Reruns and their writes | profile: `grep "update target" \| … \| uniq -c`; gap after each `import`; in the profile clone `stat -f %m .godot/{global_script_class_cache.cfg,uid_cache.bin}`; `find .godot -path ./tmp -prune -o -type f -newermt @1793224100 -print \| wc -l`, positive control the same `find` inside `.godot/tmp` | `import` 5, `playthrough` 4, `lore-values` 3, seven targets 2; import gaps 8, 2, 1, 2, 2 s; import starts `1793223822 1793227570 1793227596 1793227709 1793227726`; cache mtimes `1793227726`, `1793227727`; 7 files outside `tmp` (`uid_cache.bin`, `global_script_class_cache.cfg`, `editor/filesystem_cache10`, …); positive control 1,597 |
| V13 | `counts.txt` written twice | `grep -n -E '^[a-z-]+:\|counts\.txt' mk/home-tiers.mk` | `20: home-art-check` writes it at 22, reads at 27; `41: home-site-check` writes it at 43, reads at 44 |
| V14 | The replay family | `grep -n 'scratch =\|vm.ndjson' tools/replay.py`; `sed -n 98,122p mk/m45.mk`; `grep -m1 '^parity-m4:' db.txt`; awk over the db for recipes matching `replay.py\|SCRATCH)/replay\|M45_STATE\|tmp/replay` | `replay.py:99` scratch `.godot/tmp/replay`, `:207` writes `<case>.vm.ndjson`; `M45_STATE := $(SCRATCH)/replay/m4_min_path.vm.ndjson` (61), rule at 118, `cmp $(M45_STATE)` at 115 in `replay-positive-control`; `parity-m4:` (no prerequisites); closure users: `replay replay-compat replay-scene tools-test codex-unlocks parity-m4`, the state file, and `ai-live-guard` (which only scans `replay.py` as text); in the profile, `grep -c "update target '.godot/tmp/replay/m4_min_path.vm.ndjson'"` 0 and `grep -c "update target 'replay'"` 1 (positive control), and line 6658 runs `replay.py --sim-only --case m4_min_path --positive-control` after `replay`'s `ok m4_min_path` at line 5389 |
| V15 | Shared Godot scratch, H6/H7 | `grep -n 'test_ai_settings\|test_ai_relay' mk/ai.mk` with target attribution; `sed -n 18,36p tests/test_ai_settings.gd`; `sed -n 60,75p` and `336,350p`; `sed -n 22,44p tests/test_ai_relay.gd` | `ai-live-guard` (464, `--launch-default`) and `ai-settings` (467); `ai-relay` (299) and `replay-noai` (304); both scripts use a fixed `res://.godot/tmp/<name>` and `fresh()` does `rm -rf`; `test_launch_default` runs in both modes and calls `fresh("default")` |
| V16 | Scripts with several users | awk over the db: `--script <x>.gd` per closure target, counted | `validate_ship_demo.gd` 3, `display_audit.gd` 3, `validate_ship_commons.gd` 2, `test_ai_settings.gd` 2, `test_ai_relay.gd` 2; `grep -c -o 'res://\.godot/tmp/[a-z_]*\|user://[a-z_]*'` on the two validators and `display_audit.gd`: 0, positive control `test_ai_settings.gd`: 1 |
| V17 | `user://` | `grep -n 'use_custom_user_dir\|config/name=' project.godot`; per test file `grep -o '"user://…'`, counted across files; `sed -n 495,513p bridge/sim_bridge.gd`; `find "<user dir>" -maxdepth 2 -newermt @1793223814 ! -newermt @1793227940` grouped | custom dir 0 hits, `config/name="Stapledon's Voyage"` 1 (positive control); 18 distinct paths, each in exactly 1 file; the unpack is behind `OS.has_feature("template")` (export only); written in the window (other sessions share the dir): `test_star_catalogue` 22, `logs` 6, `test_bright_audit` 3, `benchmark-public` 3, … |
| V18 | Wall-clock assertions | `git ls-files 'tests/*.gd' \| xargs grep -l -E 'Time\.get_ticks_(m\|u)sec\(\)' \| wc -l` (positive control: `git ls-files 'tests/*.gd' \| wc -l`); `grep -n deadline tests/test_ship_demo_launch.gd`; `sed -n 181,188p Makefile`; charter line 94 | 10 of 101; `11: var deadline:=Time.get_ticks_msec()+90000`; `crew-perf` compares each run's seconds with `CREW_PERF_BUDGET_*`; "run 1: red at `ship-demo-launch-test` (90 s launch guard, rig load 6–20 …)" |
| V19 | No fixed port | `git grep -n -E 'TCPServer\|UDPServer\|\.listen\(\|127\.0\.0\.1\|localhost' -- '*.gd' 'tools/*.sh' 'tests/*.sh' Makefile 'mk/*.mk' 'tools/*.py'`; `sed -n 4,5p tests/fixtures/ai_loopback.py`; `sed -n 152,160p mk/ai.mk` | No server in any `.gd` (only `Callable.bind` hits); `ai_loopback.py serve DIR: serve on 127.0.0.1 (ephemeral port, written to DIR/port)`; the recipe reads `$(AI_L)/port` (positive control: the grep finds `ai/loopback_lane.ail:6 --net-allow-localhost`) |
| V20 | Mutant targets outside the closure | `grep -c -x -E 'ai-loopback-mutants\|ai-bridge-mutants\|markers-mutants\|ai-godot' closure.txt` and `grep -x` of the same | `1`, and the one hit is `ai-godot` (positive control); `ai-loopback-mutants` copies `ai/adapters.ail` aside at `mk/ai.mk:474-475`; `tests/ai_bridge_mutants.sh:20-22` mutates 7 sources in place |
| V21 | Fixed `/tmp` | `git grep -n -E '(^\|[^A-Za-z_$])/tmp/' -- Makefile 'mk/*.mk' 'tools/*.sh' 'tests/*.sh' 'tests/*.gd' 'tools/*.gd' 'tools/*.py'`; positive control `git grep -c TMPDIR -- Makefile 'mk/*.mk' 'tools/*.sh'` | one hit, `tools/crew_sync.sh:9:SCRATCH=${SCRATCH:-/tmp/stapledon-crew-sync}`, overridden by `Makefile:112` (`SCRATCH="$(SCRATCH)/crew-sync"`); control: 5 files |
| V22 | `lens-assets` is idempotent | `sed -n 25,55p tools/lens_assets.sh` | `fetch` prints `have` and `continue`s when the sha256 matches; otherwise `curl -o "$path.part"`, digest check, `mv` |
| V23 | Held files | `gh api --paginate repos/sunholo-data/stapledons-godot/pulls/{344,346}/files -q '.[].filename'`, then `grep -E '^(Makefile\|mk/\|tools/\|tests/\|\.github/)'`; `gh pr view 344 --json files` | #344: 250 files (the `gh pr view` list stops at 100), among them `Makefile`, **`mk/m45.mk`**, `mk/earth-link.mk` (new), `tools/import_keep.txt` and 30 `tests/*`; #346: `Makefile`, `tests/test_crew_console.gd`, `tools/catalogue_probe.py`, `tools/check_star_names.py`, `tools/python-allowlist.txt`, `tools/python_guard.sh`. Neither touches `tools/rig_check.sh`, `tools/test_rig_check.sh` or `mk/home-tiers.mk`. **The brief's "mk/*.mk not held" is false for `mk/m45.mk`**, so this design never edits it before M3. |
| V24 | The open PRs change the closure | `gh pr diff 344`, `gh pr diff 346`, hunks in `Makefile`/`mk/` | #344: `test: feed-art-check`, `ship-demo-ci: display-audit-comms` (sub-make `playthrough`, so H2-exclusive), `ui: comms-station-test earth-feed-test`, two `strict` checks, display controls 31 → 32; #346: `star-names` in `test:`, `catalogue-probe` removed |
| V25 | `rig_check.sh`'s make calls | `grep -n 'make test\|make sky-assets\|make runtime\|perl -e' tools/rig_check.sh` | `15: TEST_S=${RIG_TEST_S:-7200}`; `64: make runtime`; `69: make sky-assets`; `72: perl -e 'alarm shift; exec @ARGV' "$TEST_S" make test` |
| V26 | The control stubs only `make` | `grep -n 'bin/make\|bin/gmake' tools/test_rig_check.sh` | one stub, `$T/bin/make`; no `gmake` stub (so M2's control must add one) |
| V27 | `ailang test` options | `runtime/bin/ailang test --help` (profile clone, v0.54.18) | `[path...]`, "Run tests in several files (one summary)", `--package`, `--json`; no `--jobs` |
| V28 | Inherited CI numbers | `sed -n 21,61p design_docs/planned/r2/ci-test-tiers.md` | solar-departure 649, free-nav-stop 259, moon-lifecycle 233, unit suite 798, parity-m4 226, lens-lut-check 188, strict 108; slowest file `trappist1` 132 s (run 38718669155) |
| V29 | The baseline profile | `cat /tmp/stap56/profile.sh /tmp/stap56/profile.tlog /tmp/stap56/profile.rc`; `wc -l profile.ts.log`; `sysctl -n vm.loadavg` at 22:16Z | serial `perl alarm 7200 gmake --trace test` in a fresh clone after `make runtime` and `make sky-assets`; `START 1793223814 … load={ 2.51 2.81 3.09 }`, `END 1793227937 rc=0 load={ 4.51 4.08 4.21 }`; `rc=0`; 14,613 lines; mid-run `7.30 6.11 5.79`; AILANG v0.54.18 |
| V30 | Per-target times | `/tmp/stap56-designer/gap.sh profile.ts.log closure.txt \| sort -rn` (the gap method of 1b); the `sim` recipe lines' timestamps; per-file sums of the `ailang test` per-test durations | 186 targets, sum 4,123 s; top 5 1,803 s (43.7 %), top 10 56.1 %, top 20 71.8 %, 73 targets ≤ 1 s; table in Problem 2; `sim`: check 1793224078→160, test 160→740 (`554 tests: 554 passed … (8m37.703930495s)`), bridge 740→799, `bh-hud-test` 800→818; files: `crew_hold_test.ail` 105.0 s (22), `protocol_interlude_test.ail` 91.0 (14), `solar_departure_test.ail` 61.8 (16), `cruise_digest_test.ail` 43.2 (23), `ism_test.ail` 39.3 (19), `core_ism_test.ail` 34.1 (16), sum 517.7 s over 554 tests |
| V31 | Recorded `rig/full` totals | `grep -n -o '… <n> min'` over the charter and mission log | 66 (log 1044), 77 (1013), 84 (949, 967), 90 (868, 1060), 99 (663; charter 402), 117 (1174, 1200) |
| V32 | The long Godot legs | per script: `grep -c -E 'process_frame\|create_timer\|await'`, `grep -c time_scale`, first `real.?time\|fake time` line | `test_solar_departure.gd` 0 awaits; `test_free_nav_stop.gd` 5; `test_moon_lifecycle.gd` 1, "Guided legs run in real time (D-39)"; `test_no_twitch.gd` 19, "600 s of fake time"; `time_scale` 0 in all four |
| V33 | Inherited duplicates, re-checked | `sed -n 101,103p mk/m45.mk`; `grep -n 'checkN3\|quotaVm' sim/tools/catalogue_test.ail Makefile` | `parity-m4` already runs one `--sim-only` case (the old 55 s duplicate is gone); `checkN3` still in both (`catalogue_test.ail:133,148`, `Makefile:663`) |
| V34 | Pillars | `grep -n '^#' ../stapledons-design/vision/core-pillars.md` | the six pillars, headings 5, 22, 40, 57, 75, 93 |
| V35 | `make test` leaves untracked files | profile clone: `git status --porcelain` | 5 `??` lines: four `data/planets/trappist1_ps.*.translation`, one `data/starmap/truth/positions. 1%) is resolved in the audit.translation` (a literal name, V42) |
| V36 | The drill path is ignored | `git check-ignore -v .godot/tmp/x` | `.gitignore:1:.godot/	.godot/tmp/x` |
| V37 | Shared scratch paths, static scan (and its limit) | awk over `Makefile mk/*.mk`: `$(SCRATCH)/…` tokens per rule, paths used by 2+ rules | 31 shared paths; the real in-closure ones are H4, H5 and `v2_vm.txt` (`parity-v2-system: parity-v2`, declared) and `sound/measure.json` (`sound-levels-parity: sound-check sound-levels`, declared); `ai-pkg-test`/`ai-stub` was a **false positive** (the `define ai_stub_runs` block is expanded only by `ai-stub` and the non-test `ai-stub-record`), which is why M1 records the expanded commands' targets at run time instead of trusting a static scan |
| V38 | Serial order of the lane and exclusive members | profile: first `update target` position of each name | `replay` 48, `tools-test` 70, `parity-m4` 77, `codex-unlocks` 80, `crew-perf` 99, `replay-compat` 108, `ai-relay` 110, `replay-noai` 111, `ai-live-guard` 113, `ai-settings` 114, `replay-scene` 126, `ship-demo-launch-test` 140, `playthrough` 176, `scene-session-audits` 177, `display-audit-controls` 179, `playthrough-adversarial` 181, `display-audit-interlude` 183, `display-audit-crew` 184 |
| V39 | Sharding works through positional files, not `--package`; the package has 50 test files | **Controller-measured 2026-10-28** in the profile clone's `sim/` (runtime v0.54.18): `ailang test --package . rng_test.ail`; `ailang test rng_test.ail protocol_test.ail`; `ls sim/*_test.ail \| wc -l`. **Designer:** `git ls-files 'sim/**/*_test.ail' 'sim/*_test.ail'`, counted per directory | `Error: --package takes one package directory, got 2 paths: . rng_test.ail` (refused); rc 0, `41 tests: 41 passed, 0 failed, 0 skipped`, 22.8 s wall, 39.1 s user (173 % CPU); `34`; per directory, `34 sim` and `16 sim/tools`, i.e. 50, which equals `--package`'s "50 test files" (V30) |
| V40 | No fast-path bypass of a `SHELL` wrapper was observed | **Controller-measured 2026-10-28:** wrappers named `timed_recipe_shell.sh`, `wrap.sh` and `shwrap` (deliberately shell-prefixed), each set as `SHELL` over a Makefile with `@true` and `echo hi > /dev/null`, on `/usr/bin/make` 3.81 and `gmake` 4.4.1 | each name logged 2 of 2 lines on both makes; no bypass for any name |
| V41 | The top-20 arithmetic | **Controller-checked 2026-10-28:** the sum of the Problem 2 rows | rows 1–12 = 2,478 s, rows 13–20 = 481 s, total 2,959 s = 71.8 % of 4,123 s (the doc's 71.8 % is right; the reviewer's 67.8 % was not) |
| V42 | The fifth untracked file's name is literal | **Controller-measured 2026-10-28** in the profile clone: `od -c` of the name, `ls data/starmap/truth/` | the file is named `positions. 1%) is resolved in the audit.translation`: Godot took a CSV header cell as a locale. Not corruption. The exact five paths are listed in Problem 4. |
| V43 | The replay state file has an explicit rule | **Controller-measured 2026-10-28** in the profile clone: `sed -n '110,125p' mk/m45.mk`; `gmake -pq --eval='__nop__:' __nop__ > db.txt` (rc 0, 6,174 lines); `grep -n 'M45_STATE\|m4_min_path.vm.ndjson' db.txt` | `$(M45_STATE): tests/replays/m4_min_path.ndjson sim/*.ail` is an explicit rule (`mk/m45.mk:118`; db line 4155); `codex-unlocks: .godot/tmp/replay/m4_min_path.vm.ndjson` (db line 2268) declares it; `replay-positive-control` reads it in a recipe only (db line 3583) |
| V44 | `test` has no recipe lines | **Controller-measured 2026-10-28:** awk over db.txt counting tab-led lines after `^test:`; control the same count for `sim:` | `recipe_lines=0` for `test`; control `sim_recipe_lines=5` |

## Quorum log

- **Round 1 (2026-10-28): BLOCKED.** oc-kimi-k3, gemini-4-argon and oc-glm-5-3 rejected; gpt6-1-sol was absent (unreachable). None disputed the direction.
  - **oc-kimi-k3:** fallbacks were silent, so a serial fallback could pass as a normal green, and AC9 had no rule for when load excludes too many runs. **Changed:**
    - every fallback writes `rig-check FALLBACK <reason>` and posts `SERIAL FALLBACK: <reason>`;
    - the control cases and AC5 assert the marker;
    - a missing `gmake` after M2 now **fails** unless `RIG_JOBS=1` (2d, OQ4, default fail);
    - AC9 gains the exhaustion rule: fewer than 3 comparable `-j6` runs means no landing, and the blockage goes to Mark.
  - **gemini-4-argon:** under `-j`, `SUITE_TARGET=$@` re-expands to a sub-make's own target, so MAKELEVEL > 1 rows lose their parent. It also asked to test the M3a sharding premise. **Changed:**
    - the wrapper exports `SUITE_TOP_TARGET=${SUITE_TOP_TARGET:-$SUITE_TARGET}`, and `summary` groups by it (1a, 1b);
    - new `top-target-j2` control case (1c);
    - 3a is rewritten on the controller's measurement (V39): positional files work and `--package` with files is refused, so no syntax spike is owed; the compile cost per shard stays labelled unmeasured; the shards partition the package's 50 files in `sim/` and `sim/tools/`, and the coverage check catches a discovered-but-unlisted file.
  - **oc-glm-5-3:** §1f contradicted itself (3.81 runs, yet a gmake `--trace` run) and confounded the make version with `-j`. It also challenged the wrapper-name caution, the 71.8 % share and the fifth file name in V35. **Changed:**
    - the baseline is two serial **gmake 4.4.1** runs through the instrument, one with `--trace` for AC3; one 3.81 run is fallback evidence only and never enters a median;
    - AC2, AC3, AC9 and the artifact names were updated (`before-gmake-1/2`, `fallback-make381`), and M1's own `rig/full` runs supply these baselines (1f);
    - the wrapper-name rule is now defensive, backed by V40 (no bypass observed); the bare-`@true` control stays on both makes;
    - the 71.8 % share stands, with the sum spelled out (V41);
    - the five untracked paths are quoted exactly, with the literal-name note (V42).
- **Round 2** (`rig-test-speed-2026-10-28T23-13-04Z.json`): **BLOCKED** at N-1. gemini-4-argon **passed**; oc-kimi-k3 and oc-glm-5-3 rejected; gpt6-1-sol absent (unreachable) in both rounds. Neither reject disputes the direction, and each carried a concrete `proposed_fix`, so the controller applied them under the narrow-refinement carve-out (no third round) after measuring glm's premises first-party:
  - **oc-kimi-k3:** load was recorded only at a run's edges (V29's 7.3 mid-run peak passes that check) and the baseline was a median of 2. **Changed:** `run` samples load every 30 s into `load.tsv` (1b); AC9's rule now reads every sample (fallback: median ≤ 5.0 and no sample > 8), and `report` refuses a TSV with no load file; the baseline is ≥ 3 comparable gmake runs (1f, a fourth M1 rig run).
  - **oc-glm-5-3:** V4 and H5 disagreed about whether the state file has a rule; does `test` have recipe lines?; what does `check` count as reach?; AC5's 7 contradicted 2d/OQ4. **Measured:** an explicit rule, declared by `codex-unlocks` (V43); `test` has 0 recipe lines, control `sim` 5 (V44). **Changed:** V4's parenthetical and H5 corrected; `check` counts the generated lane edges as reach (2b); `gmake-missing` is retired at M2, so AC5 expects 6.
  - **gemini-4-argon (pass, catch):** concurrent appends could interleave. **Changed:** one `printf` per row, an atomic `O_APPEND` write (1a).
