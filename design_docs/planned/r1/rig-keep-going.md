# Nightly rig/full keeps going past a red target (7ag)

**Status:** Planned 2026-11-09 (mission iteration 82, designer). **Release:** r1. **Milestone:** none (nightly tooling).
**Priority:** P1. Since at least 2026-11-04 every nightly `rig/full` has stopped at the first red target, about 6 minutes into a 67–71 minute suite. Everything after that target has not run on main for five nights, while PRs keep merging on the fast tier.
**Implements:** queue row **7ag**. It serves Mark's merge rule of 2026-11-03/06 (CLAUDE.md "Merges"): main's nightly `rig/full` is the only place the whole `make test` runs. One known red (D-145, then D-148) must not hide every other red.
**Depends on:** 7af ([rig-golden-setup](../../implemented/r1/rig-golden-setup.md): the `bounded` helper and the `order` cases of `tools/test_rig_check.sh`); the hermetic rig-check control from iteration 55 ([rig-watchdog-7200](../../implemented/r1/rig-watchdog-7200.md)). GNU Make 3.81 (`/usr/bin/make`, the rig's make), and also GNU Make 4.4.1 (`gmake`), because the new control runs on both.
**Estimated LOC:** about 175. That is above the ~150 guide, and the reason is the control: about 120 of the lines are the new fixture control, which runs 6 cases on each GNU make it finds.
- `tools/rig_check.sh`: about 19 (+18 −2). This is `make -k test`, the failing-target list, the 140-character description and a separate golden log.
- `tools/rig_nightly.sh`: about 6 (+5 −1). The issue body gets a "Failing targets" line and a per-target window of failing lines.
- `tools/test_rig_check.sh`: about 26 (+13 −13). Four expected descriptions change, `test` becomes `-k test` in four expected make-call lists, there is one new case (`keep-going`), the counts go 17/18 → 18/19, and the caller-poison run gains `MAKEFLAGS=k`.
- `tools/test_rig_keep_going.sh`: new, about 122. The appendix has the measured prototype.
- Nothing changes in `Makefile`, in `mk/` (`make rig-check-control` already runs `tools/test_rig_check.sh`, at `mk/m45.mk:56`), or in `.gd`/`.uid` files. Shell scripts carry no `.uid` (V21).

## Game vision alignment

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | No clocks. |
| The Ship Is Home | 0 | 0 | No scene. |
| Grounded Strangeness | 0 | 0 | No visuals change. |
| We Are Not Built For This | 0 | 0 | No crew. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No physics maths. The physics checks in `make test` (`physics`, `parity-*`, `kerr-oracle`, the oracles) run every night again instead of hiding behind an unrelated red. |
| **Net** | | **0** | **Go.** This is neutral test-infrastructure hygiene (D-88). No pillar is below 0. |

Physics gates 2 and 3 of the definition of done do not apply: no formula, shader, lookup table or render changes.

## Problem

`tools/rig_check.sh:95` runs `bounded "$TEST_S" make test` with no keep-going (V1). Serial make stops at the first failing target. Since `dec3bd83` the nightly (`tools/rig_nightly.sh:85`, launchd `dev.stapledon.rig-nightly`) runs `rig_check.sh <main sha>` as `rig/full`.

- **The run dies early.** On 2026-11-06, 11-07 and 11-08 each nightly `make test` ended about 6 minutes after it started (22:30:03 → 22:35:53 on 11-08 at `7d26c947`; V4). The 11-07 log (`d9cc170b`) is 1,617 lines and ends at `make: *** [bridge-operator-test] Error 1`. A green `make test` log from 11-03 is 14,719–16,028 lines (V6), so about 89% of the suite's output never appears. A green `make test` took 67–71 min on 2026-11-03 (V7).
- **The report names only the first red.** Issue #392 (label `nightly-rig`) lists `rig_nightly.sh:110`'s `grep … | tail -30` over the log. For 7d26c947 that is 14 `bridge-operator-test` lines and its `make: ***` line (V19). Nothing tells the reader whether anything else is red.
- **The rig/full log is overwritten.** `rig_check.sh:51` sets `log="$dir.log"` for every mode, and `:85`/`:86` truncate it with `>`. The `rig/golden` run on the same commit at 04:16 therefore replaced the `rig/full` log that issue #392 points to. `7d26c947….log` (28,736 bytes) is now the golden run's log, and its only `make: ***` line is `[constellation-golden]` (V5). The controller's "run log is only 28 KB" is that golden log, not the `make test` log. With keep-going, the full log is the main evidence, and it must survive.
- **The other doc already assumes keep-going.** `design_docs/planned/r1/m4-7ae-bridge-operator-contact.md` says the controller uses `make -k test` for the other targets. The nightly never does (V1).

## Goals and non-goals

**Goals.**
1. `rig/full` runs every `make test` target, even after a red one, and still ends red (rc 1, status `failure`) if any target failed. A green suite still ends green.
2. The report names every failing target: in rig_check's stdout, in the `rig/full` commit-status description (within the 140-character limit of row 7o), and in the nightly issue.
3. The `rig/full` log of a commit survives that commit's `rig/golden` run.
4. Local `make test` is unchanged for developers. No `Makefile` or `mk/` edit.

**Non-goals (out of scope).** Fixing D-148 (`bridge-operator-test`) or D-145 (`sound-test` S2); any skip or expected-failure list (D-148 option D is Mark's decision); parallelising the suite (L4/D-129); `make golden` and `rig/golden` (except that its log moves to its own file); the watchdog value (`TEST_S` stays 7,200 s).

## Verification log

Every row was run on 2026-11-09 in this clone at `0c3f46c8` (or in the scratch prototype copy named in the row), on the Studio.

| # | Command | Output |
|---|---|---|
| V1 | `grep -n 'make test\|make -k' tools/rig_check.sh tools/rig_nightly.sh`; control: `grep -c 'make -k' design_docs/planned/r1/m4-7ae-bridge-operator-contact.md` | `rig_check.sh:95: [ $tests = 0 ] \|\| bounded "$TEST_S" make test >> "$log" 2>&1 \|\| fail "make test failed or ran over ${TEST_S}s"`. There is no `make -k` in either script (`grep -c`: 0 and 0). The 7ae doc control prints `6`, for example `:238 The controller runs `make -k test` on the fix head`, so the pattern works. |
| V2 | `sed -n 100,117p tools/rig_nightly.sh` | The issue body is: the run's last stdout line; "Failing lines (log on the Studio: …)"; `grep -nE '(^\|[^a-z])(FAIL\|SCRIPT ERROR\|\*\*\*)' "$rlog" \| grep -vE '=FAIL$\|0 fail' \| tail -30`; `...`; `tail -20 "$rlog"`. `rlog` comes from rig_check's `; log X.log` stdout line (`:92`). |
| V3 | `/bin/zsh -lc 'command -v make; make --version \| head -1; command -v gmake'` (the plist's shell, `tools/launchd/dev.stapledon.rig-nightly.plist:16`) | `/usr/bin/make`, `GNU Make 3.81`, `/opt/homebrew/bin/gmake` (4.4.1). rig_check calls `make` by `PATH` (only `runtime/bin` is prepended, `:91`), so the rig runs **3.81**. |
| V4 | `tail -30 ~/Library/Logs/stapledon-rig-nightly.log` | `2026-11-06 22:30:04 … make test` → `22:36:24 … FAILED`; `11-07 22:30:03` → `22:36:21`; `11-08 22:30:03` → `22:35:53`. Every later launch says `rig/full failure; GPU at 94–100%` or `already has rig/full failure`. |
| V5 | `head -1 $L/7d26c947….log; grep -n '^make: \*\*\*' $L/7d26c947….log; ls -l $L/7d26c947….log` (`L=$TMPDIR/rig-check`) | `rig-check: staging runtime v0.56.1`; `383:make: *** [constellation-golden] Error 1`; 28,736 bytes, mtime `Nov 9 04:18`, which is the time of the `rig/golden` FAIL line in V4 (`04:18:07`). The `rig/full` log of 22:35 is gone. |
| V6 | For each `$L/*.log`: `wc -l`, `grep -c '^make: \*\*\*'`, `grep -c '^make\[[0-9]*\]: \*\*\*'` | Green logs 19b3d362 16,028 / 0 / 0; 3d001539 14,719 / 0 / 0; 7e41edad 14,765 / 0 / 0; c778c0dc 14,766 / 0 / 0. Red: d9cc170b 1,617 / **1** (`[bridge-operator-test] Error 1`); e292a860 1,617 / 1 (same); 13368e16 10,332 / 1 (`[ship-demo-live-test] Terminated: 15`). **A green rig log has no top-level `make: ***` line.** The red logs are the positive control for the pattern. |
| V7 | `gh api repos/sunholo-data/stapledons-godot/commits/<sha>/statuses -q '[.[]\|select(.context=="rig/full")][0] \| .state + " " + .description'` for the four green shas | `success … in 69 min` (19b3d362, test + golden), `67 min`, `68 min`, `71 min`. |
| V8 | A fixture in `mktemp -d`: `test: a b c` + `test: e`; `a` and `c` fail, `b` passes, `e: a`. Run `make -k test`, `make test` and `MAKEFLAGS=k make test` on 3.81 and 4.4.1 (`env -u MAKEFLAGS -u MAKELEVEL`, `alarm 20`) | 3.81 `-k`: `make: *** [a] Error 1`, `b ok`, `make: *** [c] Error 1`, `` make: Target `test' not remade because of errors. ``, rc 2. Plain: stops after `[a]`, rc 2. `MAKEFLAGS=k` behaves exactly like `-k`. 4.4.1: the same, but lines read `gmake: *** [Makefile:4: a] Error 1`. `e` (which depends on the red `a`) is **silently skipped**: no line names it. |
| V9 | A fixture with outer `make -k test` over the nested patterns `pos: $(MAKE) bad`; `mutant: if $(MAKE) bad; then SURVIVED`; `multi: $(MAKE) bad good`; a two-line recipe whose first line fails; `nested-ok`; a missing prerequisite; `killed: kill -TERM $$` (3.81) | Plain: rc 2 after `[pos]`. `-k`: rc 2; `make[1]: *** [bad] Error 1` then `make: *** [pos] Error 2`; `mutant: killed ok` (the expected-failure verdict is unchanged); `multi` runs `good` after `bad` and is still `Error 2`; the recipe's second line does **not** run; ``make: *** No rule to make target `missing-thing', needed by `test'.``; `make: *** [killed] Terminated: 15`. Nested errors carry `make[N]:`, so `^g?make: ` matches top level only. |
| V10 | `make -pq` database (`env -u MAKEFLAGS -u MAKELEVEL /usr/bin/make -pq x`); the closure of `test`; the recipe owners that contain `$(MAKE)`, `MAKE=` or a fixture-make script | `test` has **138** prerequisites and no recipe. 19 recipe targets in the closure run a nested or fixture make: `ai-core-verify capture-m4-publish-test display-audit-comms display-audit-crew display-audit-interlude ism-lore-drafts lens-assets lore-import-check lore-test parity-m4 playthrough-adversarial rig-check-control scene-session-audits script-gate-drill script-gate-lint script-gate-selftest sim starmap-assets starmap-consistency-large`. The control rows outside the closure (`ai-loopback-mutants`, `sky-regen`, …) confirm that the filter discriminates. |
| V11 | Script-level makes: `git ls-files tools tests \| xargs grep -nE 'MAKEFLAGS\|MAKELEVEL\|\$\{MAKE:-make\}\|for candidate in make gmake'` | `test_suite_profile.sh:6`, `test_m4_publish.sh:9` and `suite_profile.sh:130` unset `MAKELEVEL MAKEFLAGS …`; `script_gate_prereqs.sh:13` uses `env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL`; `test_script_gate.sh:72` (case `make-sim-parse`, under `script-gate-drill`) runs `${MAKE:-make} … sim-bridge` and **does not** clear `MAKEFLAGS`. No `.py`/`.gd`/`.ail` file invokes make (the same grep for `"make"`/`'make'` is empty, with the positive control `grep -l 'for candidate in make gmake'` listing two files). |
| V12 | `make-sim-parse` under inherited k: `MAKEFLAGS=$k /usr/bin/make --no-print-directory sim-bridge SIM_BRIDGE_SCRIPT=/nonexistent.gd GODOT_SIM='sh -c "echo SCRIPT ERROR: Parse Error: x; exit 0" --'` for `k` = empty, `k` | rc **2** both times. `script-gate: sim-bridge FAIL; 1 SCRIPT ERROR line(s)` count **1** both times. `sim-bridge` has no prerequisites and one recipe line (`Makefile:384-385`), so `-k` has nothing to continue to. |
| V13 | Three nested-make targets, each run plain and with `-k` (`env -u MAKEFLAGS -u MAKELEVEL /usr/bin/make [-k] T`) | `rig-check-control` rc 0/0, `18 cases, 0 failures` both (221 s / 189 s). `script-gate-lint` rc 0/0, `script-gate-prereqs: ok (4 pairs …)` both. `capture-m4-publish-test` rc 0/0, `OK (15 cases on 2 makes: GNU Make 3.81, GNU Make 4.4.1)` both. |
| V14 | Reverse closure over the V10 database: for each `test` prerequisite, which other `test` prerequisites depend on it | `import` ← 42 (for example `bridge-operator-test`, `captain-anim-test`, `crew-console-test`, `deck-assets-check`, `export-filter-audit` …); `starmap-assets` ← 2; `parity-v2`, `sound-levels`, `lens-assets`, `sound-check`, `lint-precision` ← 1 each. **`bridge-operator-test` ← 0; `sound-test` ← 0.** |
| V15 | Launchd environment: `/bin/zsh -lc 'env \| grep -c "^MAKE\|^MFLAGS\|^GNUMAKEFLAGS"; env \| grep -c "^PATH="'` | `0`, then `1` (the control line proves that env is read). The nightly starts with no make variables. |
| V16 | Prototype (scratch copy `git archive HEAD`, the Design code below): `sh tools/test_rig_keep_going.sh "$P"` | 12 lines `rig-keep-going control <case> [3.81\|4.4.1]: ok` (two-red, golden-log-kept, green, many-red, nightly-two-red, nightly-green), then `rig-keep-going control: 12 cases, 0 failures`, rc 0, **3 s**. |
| V17 | Prototype outputs, from the same run with the cleanup trap disabled and 3.81 only | two-red post: `failure 78 01234567: make test failed (rc 2; bound 7200s); 2 red: alpha-check gamma-check` (78 characters before the log pointer, which `fail` appends only when it fits). many-red post: `failure 113 01234567: make test failed (rc 2; bound 7200s); 12 red: a-rather-long-failing-target-1 a-rather-long-failing-target-2 +10 more`. The nightly body has `Failing targets (2): alpha-check gamma-check`, and its Failing lines hold `alpha: FAIL one`, `make: *** [alpha-check] Error 1`, the gamma window, `make[1]: *** [gamma-sub] Error 1` and `make: *** [gamma-check] Error 2`. |
| V18 | The drill in "Mutation drill" below, `sh drill.sh "$P"` | M1 (no `-k`) 6 FAIL; M2 (first target only) 6; M3 (red posts green) 6; M4 (no target list) 2; M5 (old `tail -30`) 2; M6 (shared log) 2; M7 (M1 under outer `MAKEFLAGS=k MAKELEVEL=1`) 6; M8a (M1, no unset, outer k + level) rc 1; **M8b (M1, no unset, outer `MAKEFLAGS=k` only) rc 0: the mutant survives**. Then `drill: 9 mutant runs as predicted`, rc 0, 90 s. |
| V19 | `gh issue view 392 --json comments -q '.comments[-2].body'` | `Failing lines …` lists `1581:FAIL voyage installed working point …` to `1594:FAIL crew panel …` and `1616:make: *** [bridge-operator-test] Error 1`. No other target is named. |
| V20 | The new nightly extraction and the old one on the real single-red log `d9cc170b….log`, then `cmp` | Both are 15 lines; `cmp` prints nothing (IDENTICAL). On a single red the issue reads exactly as it does today. |
| V21 | `git ls-files tools \| grep -c '\.sh\.uid$'`; control `… \| grep -c '\.gd\.uid$'` | `0`; `158`. |
| V22 | Through the target, on the prototype: `make -C "$P" rig-check-control`, `make -C "$P" -k rig-check-control`, and M1 in a clonefile copy `make -C "$P2" -k rig-check-control` | rc 0 (251 s), rc 0 (249 s), and rc **2** with `rig-check control keep-going: FAIL` and `19 cases, 5 failures` for M1; the details are under "Through-target result". |

## Design

### M1. `tools/rig_check.sh`: keep going, name every red, keep the log

This is the exact code measured in V16–V18 (diff against `0c3f46c8`):

```diff
-log="$dir.log"
+log="$dir.log"; [ $tests = 1 ] || log="$dir.golden.log"   # 7ag: rig/golden must not overwrite the rig/full log of the same commit
@@
 start=$(date +%s)
-[ $tests = 0 ] || bounded "$TEST_S" make test >> "$log" 2>&1 || fail "make test failed or ran over ${TEST_S}s"
+if [ $tests = 1 ]; then
+  # Row 7ag: -k runs every make test target, so one known red cannot hide the rest; make -k still exits 2 if any
+  # target failed. The failing targets are the top-level make error lines this run appended to the log.
+  n0=$(wc -l < "$log"); trc=0
+  bounded "$TEST_S" make -k test >> "$log" 2>&1 || trc=$?
+  if [ "$trc" != 0 ]; then
+    red=$(tail -n +"$((n0 + 1))" "$log" | sed -nE "s/^g?make: \*\*\* \[([^]]*: )?([^]]+)\] .*/\2/p; s/^g?make: \*\*\* No rule to make target .([^']+)'.*/\1/p" | awk '!s[$0]++' | tr '\n' ' ' | sed 's/ $//')
+    n=$(echo $red | wc -w | tr -d ' ')
+    echo "rig-check: failed targets ($n): $red"
+    why="make test failed (rc $trc; bound ${TEST_S}s)"; [ "$trc" = 124 ] && why="make test ran over ${TEST_S}s"
+    [ "$n" != 0 ] || fail "$why; no failing target in the log"
+    budget=$((140 - 10 - ${#why} - 8 - ${#n} - 9)); list=; k=0   # "sha: " why "; N red: " names " +NN more"
+    for t in $red; do [ $((${#list} + ${#t} + 1)) -le $budget ] || break; list="${list:+$list }$t"; k=$((k + 1)); done
+    [ "$k" = "$n" ] || list="$list +$((n - k)) more"
+    fail "$why; $n red: $list"
+  fi
+fi
```

How the pieces behave:
- **Keep going.** `-k` on the command line and `MAKEFLAGS=k` behave identically on 3.81 and 4.4.1 (V8). make still exits 2 when any target failed, and `bounded` passes that rc through, so the run is still red with `rc 1` and a `failure` post. A green suite exits 0 and posts `success` exactly as before. The `rig/full` status semantics do not change.
- **Naming the reds.** The names come from the lines this run appended (`n0` skips the `make runtime` and `sky-assets` output). Only top-level `make:`/`gmake:` error lines are read. That covers `[T] Error N`, `[T] Terminated: 15` (V6, a real rig log), the 4.x form `[file:line: T]`, and `No rule to make target` (V9). Nested `make[N]:` lines are not read, so a red sub-make names its top-level target once (V9, V17). Green rig logs have no such line (V6).
- **Fail closed.** A red make with no named target (for example make killed before it printed anything) still fails, and says `no failing target in the log`. A timeout (`bounded` rc 124) says `ran over ${TEST_S}s` and still names the targets that went red before the kill. The bound stays in the non-timeout text as well (`bound 7200s`). The caller-poison case relies on that to prove that a caller's `RIG_TEST_S` does not leak in (D-126, iteration 52).
- **140 characters.** As many names as fit go into the description, followed by `+K more` (V17: 113 characters for 12 long names). stdout's `rig-check: failed targets (N): …` line carries the whole list for the nightly.
- **The log.** `--golden-only` writes `$dir.golden.log`, so `rig/full`'s `$dir.log` survives (V5). rig_nightly's `; log X.log` parse (`:92`) matches both names.

### M2. `tools/rig_nightly.sh`: list every red in the issue

```diff
     echo "$(tail -1 "$out")"
     echo
+    sed -n "s/^rig-check: failed targets /Failing targets /p" "$out" | head -1   # 7ag: every red target, in run order
+    echo
@@
-      grep -nE '(^|[^a-z])(FAIL|SCRIPT ERROR|\*\*\*)' "$rlog" | grep -vE '=FAIL$|0 fail' | tail -30
+      # 7ag: for each top-level make error line, the up-to-20 matching lines before it (make -k reports many).
+      awk '/^g?make: \*\*\* / { for (i = 1; i <= c; i++) print b[i]; print FNR ":" $0; c = 0; next }
+        /(^|[^a-z])(FAIL|SCRIPT ERROR|\*\*\*)/ && !/=FAIL$|0 fail/ { if (c == 20) { for (i = 1; i < 20; i++) b[i] = b[i + 1]; c-- } b[++c] = FNR ":" $0 }' "$rlog" | cut -c1-300 | head -200
```

**Today.** The body shows rig_check's last line, the last 30 lines in the whole log that match `FAIL`/`SCRIPT ERROR`/`***` (excluding `=FAIL` and `0 fail`), `...`, and the log's last 20 lines (V2). With `-k` that would show only the last red target's lines.

**After.** The body adds `Failing targets (N): t1 t2 …`, the complete list in run order. Its Failing lines become, for every top-level `make: ***` line, the up to 20 matching lines before it (the window resets at each top-level error), then that error line. Each line is cut to 300 characters, and the whole block is capped at 200 lines; a 138-target worst case stays far below GitHub's 65,536-character body limit. The `...` and `tail -20` stay. For a single red the output is byte-identical to today's (V20).

### M3. The control: `tools/test_rig_keep_going.sh ROOT`, wired through `make rig-check-control`

It is a new hermetic fixture control, invoked as one case (`keep-going`) of `tools/test_rig_check.sh`, the same way `suite-profile` is (`test_rig_check.sh:77-82`). So `make rig-check-control` (`mk/m45.mk:54-57`, already a `make test` prerequisite) reaches it, and neither `Makefile` nor `mk/` changes. The appendix has the full prototype that V16–V18 measured.

- It takes an explicit `ROOT` and copies `ROOT/tools/rig_check.sh` and `rig_nightly.sh` side by side into `mktemp -d`, as the launchd job does (plist `:16`). The cleanup trap follows `mktemp` directly.
- It unsets `MAKELEVEL MAKEFLAGS MFLAGS MAKEOVERRIDES GNUMAKEFLAGS MAKE_TERMOUT MAKE_TERMERR`, as `test_suite_profile.sh:6` does. V18 shows this is load-bearing: under the rig's own `make -k test` the outer `k` would keep a no-`-k` mutant going (M8b survives), and an outer `MAKELEVEL` turns every top-level line into `make[2]:` (M8a).
- `gh`, `git` and the setup makes are stubs. The stub `git clone` writes the fixture suite as the clone's `Makefile`. The stub `make` `exec`s the **real** make for `test` only, so the real 3.81/4.4.1 `-k` output is what gets parsed. It runs on every distinct GNU make on `PATH`, like `test_suite_profile.sh`.
- The cases, per make:
  1. `two-red`: `alpha-check` (red), `beta-ok` (green), `gamma-check` (red through a nested make, after 40 `FAIL` lines). Expected: rc 1; stdout `rig-check: failed targets (2): alpha-check gamma-check`; `beta-ok` ran once (keep-going); posts `pending failure`; description `make test failed (rc 2; bound 7200s); 2 red: alpha-check gamma-check`. A positive control proves the log capture is live.
  2. `golden-log-kept`: a `--golden-only` run on the same `RIG_DIR` reports `; log …golden.log`, and the `rig/full` log's `cksum` is unchanged.
  3. `green`: rc 0; posts `pending success`; an `ok` line; no `failed targets` line.
  4. `many-red`: 12 long red names. stdout lists all 12; the description is at most 140 characters and ends `+K more`.
  5. `nightly-two-red`: real `rig_nightly.sh` beside real `rig_check.sh` (`RIG_NIGHTLY_FORCE=1`). Expected: rc 1; the issue body (stub `gh issue create --body-file`) has `Failing targets (2): alpha-check gamma-check`, exactly 2 top-level `make: ***` lines, `alpha: FAIL one` and `gamma: FAIL 40`. The 40 gamma lines make the old `tail -30` drop alpha (M5).
  6. `nightly-green`: rc 0, a `make test green` log line, and no issue body.
- `tools/test_rig_check.sh` changes:
  - Add `HERE=$(cd "$(dirname "$0")/.." && pwd -P)` and the `keep-going` case running `sh "$HERE/tools/test_rig_keep_going.sh" "$HERE"`.
  - The make-call lists `sky-assets test` → `sky-assets -k test` (`golden-setup`, `full-no-setup`, `test-hang`). This also kills a no-`-k` mutant inside the stub control.
  - `make-test-red` → `make test failed \(rc 1; bound 7200s\); no failing target in the log$`; `watchdog-override` → `… \(rc 1; bound 60s\) …`; `test-hang` → `make test ran over 2s; no failing target in the log$`. `failure-refused`'s stdout ERE is unchanged.
  - `n=17` → `18`, the outer `n=18` → `19`, and `nok`/`of 17` → `18`.
  - The caller-poison run adds `MAKEFLAGS=k`.

### Hazards, measured

- **The make the rig uses.** It is `/usr/bin/make`, 3.81 (V3). `-k` prints one `make: *** [T] …` line per failed target and a final ``make: Target `test' not remade because of errors.``, then exits 2 (V8).
- **`-k` reaching nested makes.** 19 targets in `make test` run a nested or fixture make (V10, V11). `-k` never changes a make's exit status (nonzero if and only if something failed) and never continues within a recipe (V9: the second recipe line does not run). So it changes no verdict of the pure `$(MAKE) x` recipes: `sim`, `lens-assets`, `starmap-assets`, `starmap-consistency-large`, `playthrough-adversarial`, `lore-*`, `ism-lore-drafts`, `display-audit-*`, `parity-m4`, `ai-core-verify`. In `scene-session-audits` (`$(MAKE) playthrough-time codex-unlocks display-audit`), a red first goal now lets the other two run, and the result is still red (V9 `multi`). The expected-failure pattern stays correct (V9 `mutant`). The fixture makes clear `MAKEFLAGS` (V11). The one that does not, `make-sim-parse`, keeps rc 2 and its message (V12). The three cheap targets measured both ways have identical verdicts (V13). The heavy ones (playthroughs, `starmap-consistency-large`, `script-gate-drill` with Godot) were not re-run with `-k`; their verdicts follow from V9, and the first keep-going nightly is their live check. **Nothing needs neutralising.**
- **Prerequisite noise.** A target whose prerequisite failed is skipped silently, and nothing names it (V8 `e`). `bridge-operator-test` and `sound-test` have 0 dependents among `test`'s prerequisites (V14), so with today's reds every other target runs. If `import` (42 dependents) or `starmap-assets` (2) went red, its dependents would be skipped exactly as they are today, and the list would name the cause. Undeclared ordering, where a later target reads files an earlier red one should have written, would show up as extra reds listed after the cause. The list is in run order, so the first name is the first suspect.
- **Time.** A green `make test` was 67–71 min (V7) against `TEST_S` 7,200 s. Red targets end at their own script-gate bounds. If a run hits 7,200 s, it posts `make test ran over 7200s; N red: …`, naming every red so far. That is strictly more than today. `RIG_TEST_S` remains the escape hatch, and the controller's separate `make -k test` on `0c3f46c8` will measure the keep-going wall time.
- **Developers.** Local `make test` is unchanged (no `Makefile`/`mk/` edit). A developer who wants keep-going types `make -k test`.

### Mutation drill

The drill is run as `sh drill.sh ROOT`. Extract it with `awk '/^# --- drill begin/,/^# --- drill end/' design_docs/planned/r1/rig-keep-going.md > "$T/drill.sh"`.

```sh
# --- drill begin
#!/bin/sh
# drill ROOT: each mutant of ROOT's rig scripts must turn the keep-going control red on the named cases.
set -u
[ $# = 1 ] && [ -f "$1/tools/test_rig_keep_going.sh" ] || { echo "usage: $0 ROOT"; exit 2; }
ROOT=$(cd "$1" && pwd -P)
W=$(mktemp -d "${TMPDIR:-/tmp}/rig-kg-drill.XXXXXX") || exit 1
trap 'rm -rf "$W"' EXIT
# mutant <name> <file> <perl -0 substitution> <want rc> <want FAIL lines> [env...]
mutant() {
  name=$1 file=$2 sub=$3 want_rc=$4 want_fails=$5; shift 5
  rm -rf "$W/m"; mkdir -p "$W/m/tools" || exit 1
  cp "$ROOT/tools/rig_check.sh" "$ROOT/tools/rig_nightly.sh" "$ROOT/tools/test_rig_keep_going.sh" "$W/m/tools/" || exit 1
  perl -0pi -e "$sub" "$W/m/tools/$file" || exit 1
  if cmp -s "$ROOT/tools/$file" "$W/m/tools/$file"; then echo "drill $name: the mutation did not change $file"; exit 3; fi
  rc=0; env "$@" sh "$W/m/tools/test_rig_keep_going.sh" "$W/m" > "$W/out" 2>&1 || rc=$?
  n=$(grep -c ': FAIL (' "$W/out")
  echo "drill $name: rc $rc, $n FAIL lines: $(grep ': FAIL (' "$W/out" | sed 's/^rig-keep-going control //; s/ (.*//' | sort -u | tr '\n' ' ')"
  test "$rc" = "$want_rc" || exit 1
  test "$n" = "$want_fails" || exit 1
}
mutant M1-no-k rig_check.sh 's/make -k test/make test/' 1 6 || exit 1
mutant M2-first-only rig_check.sh 's/awk \x27!s\[\$0\]\+\+\x27/head -1/' 1 6 || exit 1
mutant M3-red-is-green rig_check.sh 's/^    fail "\$why; \$n red: \$list"$/    :/m' 1 6 || exit 1
mutant M4-no-target-list rig_nightly.sh 's/^    sed -n "s\/\^rig-check: failed targets [^\n]*\n//m' 1 2 || exit 1
mutant M5-old-tail-30 rig_nightly.sh 's/^      awk \x27\/\^g\?make[^\n]*\n[^\n]*head -200$/      grep -nE \x27(^|[^a-z])(FAIL|SCRIPT ERROR|\\*\\*\\*)\x27 "\$rlog" | grep -vE \x27=FAIL\$|0 fail\x27 | tail -30/m' 1 2 || exit 1
mutant M6-shared-log rig_check.sh 's/; \[ \$tests = 1 \] \|\| log="\$dir\.golden\.log"//' 1 2 || exit 1
# Hermeticity: under an outer make's -k, M1 still dies with the control's unset in place...
mutant M7-no-k-under-outer-k rig_check.sh 's/make -k test/make test/' 1 6 MAKEFLAGS=k MAKELEVEL=1 || exit 1
# ...and survives once the unset is gone too (so the unset is what kills it; two files mutated, rig_check first).
rm -rf "$W/m"; mkdir -p "$W/m/tools" || exit 1
cp "$ROOT/tools/rig_check.sh" "$ROOT/tools/rig_nightly.sh" "$ROOT/tools/test_rig_keep_going.sh" "$W/m/tools/" || exit 1
perl -0pi -e 's/make -k test/make test/' "$W/m/tools/rig_check.sh" || exit 1
perl -0pi -e 's/^unset MAKELEVEL MAKEFLAGS [^\n]*\n//m' "$W/m/tools/test_rig_keep_going.sh" || exit 1
cmp -s "$ROOT/tools/rig_check.sh" "$W/m/tools/rig_check.sh" && { echo "drill M8: rig_check unchanged"; exit 3; }
cmp -s "$ROOT/tools/test_rig_keep_going.sh" "$W/m/tools/test_rig_keep_going.sh" && { echo "drill M8: control unchanged"; exit 3; }
# M8a: the outer MAKELEVEL alone turns every top-level line into make[2] (nothing named): red, but for the wrong reason.
rc=0; MAKEFLAGS=k MAKELEVEL=1 sh "$W/m/tools/test_rig_keep_going.sh" "$W/m" > "$W/out" 2>&1 || rc=$?
echo "drill M8a-no-k-no-unset-outer-k-and-level: rc $rc ($(tail -1 "$W/out"))"
test "$rc" = 1 || exit 1
# M8b: the outer -k alone keeps the no-k mutant going: it SURVIVES, so the unset is what kills M1 under make -k test.
rc=0; MAKEFLAGS=k sh "$W/m/tools/test_rig_keep_going.sh" "$W/m" > "$W/out" 2>&1 || rc=$?
echo "drill M8b-no-k-no-unset-outer-k: rc $rc ($(tail -1 "$W/out"))"
test "$rc" = 0 || exit 1
echo "drill: 9 mutant runs as predicted"
# --- drill end
```

The FAIL counts assume both 3.81 and 4.4.1 are on `PATH` (the Studio). On a host with one GNU make, halve every count.

### Through-target result

These runs used `/usr/bin/make` 3.81 on the prototype copy, under `env -u MAKEFLAGS -u MAKELEVEL` and `alarm 900` (V22).

| Run | rc | Time | Result |
|---|---:|---:|---|
| `make -C $P rig-check-control` | 0 | 251 s | `keep-going: ok`, `caller-poison: ok`, `rig-check control: 19 cases, 0 failures` |
| `make -C $P -k rig-check-control` (the rig's own outer `-k`) | 0 | 249 s | the same three lines |
| M1 (`make -k test` → `make test`) in `$P2`, `make -C $P2 -k rig-check-control` | **2** | 249 s | 6 `rig-keep-going control … FAIL` lines (two-red, many-red and nightly-two-red on 3.81 and 4.4.1); `rig-check control keep-going: FAIL`; `caller-poison: FAIL`; `rig-check control: 19 cases, 5 failures` (keep-going, caller-poison, and the three `-k test` make-call cases golden-setup, full-no-setup and test-hang); `make: *** [rig-check-control] Error 1` |

The control adds about 3 s to `rig-check-control`, which took 189–221 s before the change (V13). When `keep-going` fails, the fixture log is printed with `cat`, so caller-poison's `': ok$'` count over-reads (`20 of 18 ok`). The existing `suite-profile` case does the same, and the case is red either way.


## Acceptance criteria

`T=$(mktemp -d) && trap 'rm -rf "$T"' EXIT` before the drill rows. Inside table cells, `\|` is Markdown for a plain `|`.

| # | Criterion | Command | Expected |
|---|---|---|---|
| 1 | The keep-going control is green on both makes | `sh tools/test_rig_keep_going.sh "$PWD" \| tail -1; echo rc=$?` | `rig-keep-going control: 12 cases, 0 failures`, `rc=0` |
| 2 | The rig-check control is green and includes it | `sh tools/test_rig_check.sh tools/rig_check.sh \| grep -E 'keep-going\|caller-poison\|cases'` | `rig-check control keep-going: ok`, `rig-check control caller-poison: ok`, `rig-check control: 19 cases, 0 failures` |
| 3 | Through the target that `make test` uses, plain and under an outer `-k` | `env -u MAKEFLAGS -u MAKELEVEL make rig-check-control \| tail -1; echo rc=$?`, then the same with `make -k rig-check-control` | both `rig-check control: 19 cases, 0 failures`, `rc=0` |
| 4 | Mutants die (and M8b shows the unset is load-bearing) | `awk '/^# --- drill begin/,/^# --- drill end/' design_docs/planned/r1/rig-keep-going.md > $T/drill.sh && sh $T/drill.sh "$PWD"; echo rc=$?` | 9 `drill …` lines as in V18, then `drill: 9 mutant runs as predicted`, `rc=0` |
| 5 | M1 dies through the target under the rig's own `-k` | `git clone -q . $T/c && cp tools/*.sh $T/c/tools/ && perl -pi -e 's/make -k test/make test/' $T/c/tools/rig_check.sh && { cmp -s tools/rig_check.sh $T/c/tools/rig_check.sh && exit 3; true; } && env -u MAKEFLAGS -u MAKELEVEL make -C $T/c -k rig-check-control > $T/m1.out 2>&1; echo rc=$?; grep -c 'keep-going: FAIL' $T/m1.out; grep -c 'caller-poison: FAIL' $T/m1.out` | `rc=2`, `1`, `1` |
| 6 | The rig runs `make -k test` and nothing else changed how `make test` runs | `grep -c 'bounded "\$TEST_S" make -k test' tools/rig_check.sh; git diff --name-only origin/main...HEAD -- Makefile mk \| wc -l` | `1`, `0` |
| 7 | Scope | `git diff --name-only origin/main...HEAD` | `tools/rig_check.sh`, `tools/rig_nightly.sh`, `tools/test_rig_check.sh`, `tools/test_rig_keep_going.sh`, this doc and the landing files only |
| 8 | Shell hygiene | `for f in rig_check rig_nightly test_rig_check test_rig_keep_going; do sh -n tools/$f.sh \|\| echo BAD $f; done; git diff --check origin/main...HEAD` | no output, rc 0 |
| 9 | The python and uid guards are unaffected | `make python-guard uid-guard > /dev/null; echo rc=$?` | `rc=0` |

**Post-merge observation (not a merge gate).** The first nightly `rig/full` after the merge should run about 70 min instead of about 6 (`~/Library/Logs/stapledon-rig-nightly.log`). Its issue comment should open with `Failing targets (N): bridge-operator-test …`, naming every red target, and `$TMPDIR/rig-check/<sha>.log` should still be the `make test` log after that night's `rig/golden` run (`head -1` shows the runtime line, and `grep -c '^make: \*\*\*'` equals N).

## Sub-milestones and estimates

There is one milestone, about 175 LOC, in this order:
1. Add `tools/test_rig_keep_going.sh` (from the appendix) and the `keep-going` case. Record the case **red** against the unmodified `rig_check.sh`/`rig_nightly.sh`: two-red, many-red, nightly-two-red and golden-log-kept fail.
2. Apply M1 and M2, then the `test_rig_check.sh` expectation updates.
3. Run AC1–9.

## Risks and mitigations

- **A heavy nested target behaves differently under inherited `k`.** The analysis (V9) says a verdict cannot flip. If one does, the first keep-going nightly shows it as an extra named red, and the fix is that target clearing `MAKEFLAGS` the way `test_suite_profile.sh:6` does. That edit belongs to whoever owns the target, not to this row.
- **Silently skipped dependents** (V8). With today's reds there are none (V14). A red `import` would hide 42 targets, as it does today. The list names `import`, and that is the thing to fix first.
- **Longer nightly.** A red night now takes the CPU for about 70 min starting at 22:30, the time the nightly was meant to take. The 23:30 launch sees `rig_check.sh` running and exits (`rig_nightly.sh:67`). The golden half starts at a later launch, as it already does after a green night.
- **Many reds overflow the description.** It is capped at 140 characters with `+K more`. The full list is in stdout, in the issue's `Failing targets` line, and in the log.
- **The 4.x message format.** It is handled by the same regular expression and checked by the control on 4.4.1 (V16). The rig itself runs 3.81 (V3).

## Open questions for the user

None. This applies the keep-going behaviour the 7ae doc already assumes to the nightly Mark ruled on (2026-11-03/06). It changes no merge rule, no skip list (D-148 option D stays Mark's) and no local developer behaviour.

## Deliverables

- `tools/rig_check.sh` (M1), `tools/rig_nightly.sh` (M2), `tools/test_rig_check.sh` and the new `tools/test_rig_keep_going.sh` (M3).
- Landing: this doc moves to `design_docs/implemented/r1/`, plus an index row in `design_docs/README.md` and a changelog entry.

## Appendix: the measured prototype of `tools/test_rig_keep_going.sh`

This is the file that produced V16–V18 (in the scratch copy; not committed by this design).

```sh
#!/bin/sh
# Row 7ag control: rig/full keeps going past a red make test target. tools/rig_check.sh runs make -k test, names
# every failing target (stdout and the 140-character status), still exits red; tools/rig_nightly.sh lists them all
# in the nightly issue. Real GNU make on fixture suites (every distinct make on PATH); gh, git and the setup makes
# are stubs, so no network.
#   sh tools/test_rig_keep_going.sh ROOT      (ROOT: the checkout whose tools/rig_check.sh and rig_nightly.sh are tested)
set -u
# An outer make's -k (the rig's own make -k test) must not reach the fixture makes: it would keep a mutant that
# drops -k going (iteration 56: outer MAKEFLAGS/MAKELEVEL reached rig-check fixtures).
unset MAKELEVEL MAKEFLAGS MFLAGS MAKEOVERRIDES GNUMAKEFLAGS MAKE_TERMOUT MAKE_TERMERR
unset RIG_TEST_S RIG_GOLDEN_S RIG_SETUP_S RIG_DL_S RIG_DIR RIG_KEEP RIG_NIGHTLY_FORCE
[ $# = 1 ] && [ -f "$1/tools/rig_check.sh" ] && [ -f "$1/tools/rig_nightly.sh" ] || { echo "usage: $0 ROOT"; exit 2; }
ROOT=$(cd "$1" && pwd -P)
T=$(mktemp -d "${TMPDIR:-/tmp}/rig-keep-going.XXXXXX") || exit 1
trap 'rm -rf "$T"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
mkdir "$T/bin" "$T/n" "$T/tmp"
cp "$ROOT/tools/rig_check.sh" "$ROOT/tools/rig_nightly.sh" "$T/n/"   # side by side, as the launchd job runs them
export STUB_SHA=0123456789abcdef0123456789abcdef01234567 STUB_POSTS="$T/posts" STUB_BODY="$T/body" TMPDIR="$T/tmp"
cat > "$T/bin/gh" <<'STUB'
#!/bin/sh
case "$1 $2" in
  "api repos/sunholo-data/stapledons-godot/commits/$STUB_SHA/statuses") echo " " ;;          # no verdict yet
  "api repos/sunholo-data/stapledons-godot/statuses/$STUB_SHA")
    for a; do case "$a" in state=*) s=${a#state=} ;; description=*) d=${a#description=} ;; esac; done
    echo "$s $(printf %s "$d" | wc -m | tr -d ' ') $d" >> "$STUB_POSTS" ;;
  "api "*) echo "$STUB_SHA" ;;                                                               # commits/main, commits/<sha>
  "pr view") echo "$STUB_SHA" ;;
  "issue list") ;;                                                                           # no open issue
  "issue create"|"issue comment") while [ $# -gt 0 ]; do [ "$1" = --body-file ] && cp "$2" "$STUB_BODY"; shift; done ;;
esac
exit 0
STUB
cat > "$T/bin/git" <<'STUB'
#!/bin/sh
[ "$1" = clone ] || exit 0
for d; do :; done
mkdir -p "$d/runtime/bin"; cp "$STUB_SUITE" "$d/Makefile"
printf '#!/bin/sh\necho "AILANG v0.54.14"\n' > "$d/runtime/bin/ailang"; chmod +x "$d/runtime/bin/ailang"
STUB
# The setup makes are stubbed; make test runs the fixture suite on the real make under test.
cat > "$T/bin/make" <<'STUB'
#!/bin/sh
case " $* " in *" test "*) exec "$REAL_MAKE" "$@" ;; esac
exit 0
STUB
chmod +x "$T/bin/gh" "$T/bin/git" "$T/bin/make"
# Two independent red targets around a green one. gamma fails through a nested make (a make[1] line too) after 40
# FAIL lines, so the old tail -30 of the nightly would drop alpha entirely.
printf '%s\n' 'AILANG_RELEASE ?= v0.54.14' 'test: alpha-check beta-ok gamma-check' \
  'alpha-check: ; @echo "alpha: FAIL one"; exit 1' 'beta-ok: ; @echo "beta: 3 passed, 0 failures"' \
  'gamma-check: ; @$(MAKE) --no-print-directory gamma-sub' 'gamma-sub: ; @i=0; while [ $$i -lt 40 ]; do i=$$((i + 1)); echo "gamma: FAIL $$i"; done; exit 1' > "$T/two.mk"
printf '%s\n' 'AILANG_RELEASE ?= v0.54.14' 'test: alpha-ok beta-ok' 'alpha-ok beta-ok: ; @echo "$@: 1 passed, 0 failures"' > "$T/green.mk"
{ echo 'AILANG_RELEASE ?= v0.54.14'; printf 'test:'; for i in 1 2 3 4 5 6 7 8 9 10 11 12; do printf ' a-rather-long-failing-target-%s' "$i"; done; echo
  echo 'a-rather-long-failing-target-%: ; @echo "$@: FAIL"; exit 1'; } > "$T/many.mk"
fails=0; cases=0
ok() { cases=$((cases + 1)); echo "rig-keep-going control $1 [$V]: ok"; }
no() { cases=$((cases + 1)); fails=$((fails + 1)); echo "rig-keep-going control $1 [$V]: FAIL ($2)"; }
# rig <suite> <RIG_DIR name>: rig_check.sh on the fixture; rc in $rc, stdout in $T/out, posts in $STUB_POSTS
rig() { : > "$STUB_POSTS"; rc=0; STUB_SUITE="$T/$1.mk" RIG_DIR="$T/r/$2" PATH="$T/bin:$PATH" sh "$T/n/rig_check.sh" 7 ${3:+"$3"} > "$T/out" 2>&1 || rc=$?; }
# nightly <suite>: rig_nightly.sh beside rig_check.sh, as launchd runs it; rc in $rc, stdout in $T/out, body in $STUB_BODY
nightly() { : > "$STUB_POSTS"; rm -f "$STUB_BODY"; rc=0; STUB_SUITE="$T/$1.mk" RIG_NIGHTLY_FORCE=1 PATH="$T/bin:$PATH" sh "$T/n/rig_nightly.sh" > "$T/out" 2>&1 || rc=$?; }
makes=; versions=
for c in make gmake; do
  p=$(command -v "$c" 2>/dev/null) || continue; v=$("$p" --version 2>/dev/null | sed -n 1p)
  case "$v" in 'GNU Make '*) ;; *) continue ;; esac
  printf '%s\n' "$versions" | grep -Fqx "$v" && continue
  makes="$makes $p"; versions="$versions$v
"
done
[ -n "$makes" ] || { echo 'rig-keep-going control: FAIL (no GNU make on PATH)'; exit 1; }
for REAL_MAKE in $makes; do
  export REAL_MAKE; V=$("$REAL_MAKE" --version | sed -n '1s/GNU Make //p')
  # two-red: both reds named on stdout and in the one failure post, the green target between them ran, rc 1.
  rig two two-$V; L="$T/r/two-$V.log"
  why=
  grep -q '^alpha: FAIL one$' "$L" || why="log capture is not live"   # positive control for the log reads below
  test "$rc" = 1 || why="$why; rc $rc"
  grep -qx 'rig-check: failed targets (2): alpha-check gamma-check' "$T/out" || why="$why; stdout list"
  test "$(grep -c '^beta: 3 passed, 0 failures$' "$L")" = 1 || why="$why; beta-ok did not run (no keep-going)"
  test "$(cut -d' ' -f1 "$STUB_POSTS" | tr '\n' ' ')" = 'pending failure ' || why="$why; posts"
  grep -Eqx 'failure [0-9]+ 01234567: make test failed \(rc 2; bound 7200s\); 2 red: alpha-check gamma-check( \(log: .*\))?' "$STUB_POSTS" || why="$why; description"
  if [ -z "$why" ]; then ok two-red; else no two-red "$why"; fi
  # golden-log-kept: a later --golden-only run on the same commit writes its own log; the rig/full log survives.
  cksum < "$L" > "$T/before"; rig green two-$V --golden-only; why=
  test "$rc" = 0 || why="rc $rc"
  grep -q "; log $T/r/two-$V.golden.log\$" "$T/out" || why="$why; golden log path"
  cksum < "$L" | cmp -s - "$T/before" || why="$why; the rig/full log changed"
  if [ -z "$why" ]; then ok golden-log-kept; else no golden-log-kept "$why"; fi
  # green: rc 0 and a success post, no failed-targets line (positive: the ok line is there).
  rig green green-$V; why=
  test "$rc" = 0 || why="rc $rc"
  grep -q '^rig-check: ok, 01234567 green (make test' "$T/out" || why="$why; no ok line"
  test "$(grep -c '^rig-check: failed targets' "$T/out")" = 0 || why="$why; a failed-targets line"
  test "$(cut -d' ' -f1 "$STUB_POSTS" | tr '\n' ' ')" = 'pending success ' || why="$why; posts"
  if [ -z "$why" ]; then ok green; else no green "$why"; fi
  # many-red: 12 reds; the post fits 140 characters and says how many it left out; stdout names all 12.
  rig many many-$V; why=
  test "$rc" = 1 || why="rc $rc"
  test "$(sed -n 's/^rig-check: failed targets (12): //p' "$T/out" | wc -w | tr -d ' ')" = 12 || why="$why; stdout list"
  d=$(sed -n 's/^failure \([0-9]*\) .*/\1/p' "$STUB_POSTS")
  test -n "$d" && test "$d" -le 140 || why="$why; description length ${d:-none}"
  grep -Eq '^failure [0-9]+ 01234567: make test failed \(rc 2; bound 7200s\); 12 red: a-rather-long-failing-target-1 .* \+[0-9]+ more$' "$STUB_POSTS" || why="$why; description"
  if [ -z "$why" ]; then ok many-red; else no many-red "$why"; fi
  # nightly-two-red: the issue body names both targets and carries both top-level error lines.
  nightly two; why=
  test -f "$STUB_BODY" || why="no issue body"
  test "$rc" = 1 || why="$why; rc $rc"
  grep -qx 'Failing targets (2): alpha-check gamma-check' "$STUB_BODY" 2>/dev/null || why="$why; no Failing targets line"
  test "$(grep -cE '^[0-9]+:make: \*\*\* \[|^[0-9]+:g?make: \*\*\* \[' "$STUB_BODY" 2>/dev/null)" = 2 || why="$why; top-level error lines"
  grep -q '^[0-9]*:alpha: FAIL one$' "$STUB_BODY" 2>/dev/null && grep -q '^[0-9]*:gamma: FAIL 40$' "$STUB_BODY" 2>/dev/null || why="$why; failing lines"
  if [ -z "$why" ]; then ok nightly-two-red; else no nightly-two-red "$why"; fi
  # nightly-green: rc 0, no issue body (positive: the green log line is there).
  nightly green; why=
  test "$rc" = 0 || why="rc $rc"
  grep -q 'main 01234567 make test green$' "$T/out" || why="$why; no green line"
  test -f "$STUB_BODY" && why="$why; an issue body was written"
  if [ -z "$why" ]; then ok nightly-green; else no nightly-green "$why"; fi
done
echo "rig-keep-going control: $cases cases, $fails failures"
test "$fails" = 0

```
