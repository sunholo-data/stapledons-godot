# Sprint plan: R1-7AH-SIMILAR-GUARD — the similar-test main.gd guard checks a property, not a constant name (row 7ah)

**Design doc:** [m4-7ah-similar-guard-minor.md](m4-7ah-similar-guard-minor.md) (revision 2; quorum round 1 BLOCKED →
r1's fail-closed grammar, D8–D11, M6–M8; round 2 BLOCKED → r2 by the controller under the narrow-refinement
carve-out: the broad `want_minor` count, D12/D13, M9 — the reviewers' own fixes, V22; no round 3, straight to
planning). **Sprint JSON:** `.ailang/state/sprints/sprint_R1-7AH-SIMILAR-GUARD.json`.
**Approval basis:** pillar table net 0, none below 0 (neutral suite hygiene; unattended loop proceeds).
**Branch:** `mission/stapledon-iter84-7ah` (HEAD `ea9ced49`, the r2 design commit; merge-base with `origin/main` is
`79eadb49` = the design's `B`; `git diff 79eadb49..HEAD` is empty for `Makefile`, `main.gd`, `bridge/sim_bridge.gd`,
so every V-number applies verbatim). **Scope:** ~180 LOC (V22 r2: `Makefile` +31/−3 within lines 96–133;
`tools/similar_guard_controls.sh` new, 147 lines). No product files. **No GPU, no `make golden`, no capture, no full
local `make test`** (merge rule, CLAUDE.md); the nightly `rig/full` runs the suite on main post-merge.

Preamble once per session (every command headless from the clone root; `perl -e 'alarm N; exec @ARGV'` bounds every
long command):

```sh
export PATH=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin:$PATH
S=$PWD/.godot/tmp/7ah; mkdir -p "$S"; export TMPDIR="$S"   # only while the sandbox blocks /tmp (planner-measured);
                                                           # both scripts honour ${TMPDIR:-/tmp}; .godot/ is gitignored
```

## Plan verification (planner, 2026-11-10, HEAD `ea9ced49`)

- `sed -n 96,110p Makefile`: :96–103 the vector-read zsh block, **:103 ends `fi; \`** (edit 1); **:104** = the
  `git grep -q "SimBridge.EARTH_MINOR" … lost EARTH_MINOR …; \` line, **:105** = the `SIMILAR_MINOR … fi'` line
  (edit 2 deletes exactly these). **`Makefile:55`** = `ci-fast:`, **`:57`** = `test:` — both as cited.
- Discrepancy 1: `similar-test` is the **20th** prerequisite of `test` (count :57's words); the design says
  19; reachability unaffected. `tools/similar_guard_controls.sh` is **absent**; `make -n similar-main-guard` /
  `similar-guard-controls` → `No rule to make target` (MS1's RED precondition). Base red re-measured: `make -s
  similar-test` rc 2, last line `similar-test guard: main.gd lost EARTH_MINOR` (~40 s warm; V1 holds).
- `main.gd:304` = `if not capture:sim.want_minor=SimBridge.EARTH_LOG_MINOR # R3-COMMS-V2: …` (trailing `#` comment —
  V22's pristine premise). `bridge/sim_bridge.gd`: `SIMILAR_MINOR := 14` (:60), `SURFACE_MINOR := 13` (:57),
  `EARTH_LOG_MINOR := 18` (:77, the max) → the `future` control computes `next` = 19 today.
- `mk/script-gates.mk:27` = `ci-fast: script-gate-lint script-gate-selftest` — the edge pattern M3 copies. At base,
  `make -n ci-fast | grep -c '_run_map\|similar_guard_controls.sh'` = **0** (AC10's edges absent). ci.yml run:
  steps invoke exactly four make targets: `make deps`, `make lore-import CHECK=1 …` (all events), `make ci-fast`
  (push/PR fast tier), `make test` (release `workflow_call`).
- Fence extraction planner-measured (commands below): A = 29 lines (16 tab-recipe lines), B = 147 (line 79 carries
  the promised literal tab), C = 51. Discrepancy 2: the design header's "~165 LOC / script 135 / Makefile 27 new"
  are r1 numbers; r2's V22 measured `Makefile` 31+/3−, script 147, and the fences match V22. Sandbox: this
  planner's bash blocks /tmp writes and bare `mktemp`; `.godot/tmp/` is writable and gitignored.

## Byte-for-byte rule (binding)

Never retype appendix text. Extract, build the tree from the extractions, prove with `cmp`:

```sh
D=design_docs/planned/r1/m4-7ah-similar-guard-minor.md
awk '/^## Appendix A\./,/^## Appendix B\./' $D | awk '/^```make$/{f=1;next} /^```$/{if(f){exit}} f' > $S/A.mk
awk '/^## Appendix B\./,/^## Appendix C\./' $D | awk '/^```sh$/{f=1;next}  /^```$/{if(f){exit}} f' > $S/B.sh
awk '/^## Appendix C\./,0'                  $D | awk '/^```sh$/{f=1;next}  /^```$/{if(f){exit}} f' > $S/7ah_meta.sh
wc -l $S/A.mk $S/B.sh $S/7ah_meta.sh    # expect 29, 147, 51
```

The proof closes in MS3: `cmp $S/B.sh tools/similar_guard_controls.sh`, and the Makefile's inserted region (`# Row
7ah:` through the `@MAKE=` recipe line) `cmp`-equal to `$S/A.mk`. Tabs survive awk (planner-measured: A's 16 recipe
lines, B:79); AC11's `git diff --check` and AC12's scope greps independently catch whitespace/path drift.

## Test-first order (mandatory)

The design's sub-milestones in their fixed order: **T1 → M1 → M3 → V** = MS1 → MS2 → MS3 → MS4 below. The controls
are written before the guard target exists (seen RED at base, since `similar-main-guard` does not exist yet); never
present a control as green that never went red; record actuals wherever a command says "record".

## Milestones

### MS1 — T1: controls first, seen RED (`tools/similar_guard_controls.sh` +147, `Makefile` +2)

Files: `tools/similar_guard_controls.sh` (new, `cp $S/B.sh`), `Makefile` (+2: `A.mk`'s last two lines — the
`similar-guard-controls` target — after `Makefile:105`; position normalized in MS2). Closes: the red half of AC3.
- RED proof (record actuals): `perl -e 'alarm 120; exec @ARGV' make similar-guard-controls > $S/ms1-red.log 2>&1;
  echo rc=$?; cat $S/ms1-red.log` → make rc 2; `similar-guard-controls: pristine: make rc 2, want 0` (inner make:
  `No rule to make target 'similar-main-guard'`); no `: rejected` line; the totals never print.
- Cleanliness: `git status --porcelain` shows only the two intended files; `find $S -maxdepth 1 -name
  'similar-guard.*' | wc -l` → `0` (mutations happen on copies; trap removes them).

### MS2 — M1: `similar-main-guard`; old literal guard deleted (`Makefile` net +29/−3 in-region)

Files: `Makefile` only — exactly the design's three edits: :103 `fi; \` → `fi'`; delete :104–105; insert one blank
line plus `$S/A.mk` minus its two edge lines after :103 (MS1's temporary 2-line target is absorbed — simplest
faithful route: remove it, insert the block, keep exact bytes). Closes: AC2, AC3, AC4.

- AC2: `perl -e 'alarm 60; exec @ARGV' make similar-main-guard; echo rc=$?` → `similar-test guard: ok, main.gd
  _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)`, rc 0 (V4).
- AC3/AC4: `time perl -e 'alarm 120; exec @ARGV' make similar-guard-controls > $S/ms2-controls.log 2>&1; echo rc=$?;
  grep -E '^similar-guard-controls: ' $S/ms2-controls.log; tail -1 $S/ms2-controls.log` → rc 0; the 16 case lines in
  the M2-table order (`pristine below exact removed literal twice unknown nofloor ternary arith exprconst exprfloor
  comparison compound future comment`); final `similar-guard-controls: 13 rejected, 3 accepted`; under 2 s (V5). The
  drills are AC4 by line: `below` rc 2 below-floor, `exact` rc 2 the S0.3 line, `removed` rc 2 at 0 mentions,
  `future` accepted `FUTURE_MINOR (19)`, `exprconst` rc 2 `FOO_MINOR unresolved…`, `arith`/`ternary` rc 2 `not one
  bare SimBridge minor`, `comparison`/`compound` `mentions want_minor 2 times, want 1`.
- Still unwired (AC10 base): `make -n ci-fast 2>/dev/null | grep -c '_run_map\|similar_guard_controls.sh'` → `0`.

### MS3 — M3: the two edge lines (`Makefile` +2)

Files: `Makefile` (+2: `similar-test: similar-main-guard similar-guard-controls` and `ci-fast: similar-main-guard
similar-guard-controls`, between the new `.PHONY:` line and the `similar-main-guard:` rule — the
mk/script-gates.mk:27 pattern; `Makefile:55`/`:57` never edited). Closes: AC1, AC10; the cmp proof completes here.

- Byte-for-byte: `cmp $S/B.sh tools/similar_guard_controls.sh && echo B-ok; b=$(grep -n '^# Row 7ah:' Makefile |
  cut -d: -f1); sed -n "${b},$((b+28))p" Makefile > $S/A.tree.mk; cmp $S/A.mk $S/A.tree.mk && echo A-ok` → both ok
  (assert `b` is the comment line and the 29-line block ends on the `@MAKE=` recipe line first).
- AC1: `perl -e 'alarm 300; exec @ARGV' make similar-test > $S/ms3-similar.log 2>&1; echo rc=$?; grep -cx
  'similar-test guard: ok, main.gd _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)' $S/ms3-similar.log;
  grep -cx 'similar-guard-controls: 13 rejected, 3 accepted' $S/ms3-similar.log; grep -c 'lost EARTH_MINOR'
  $S/ms3-similar.log; tail -1 $S/ms3-similar.log` → rc 0, then `1`, `1`, `0`; every pre-existing ranking/session/
  oracle/sha step still runs; log ends with `a64e9634…  …session-215-strict.ndjson` (V6/V22; ~30–53 s).
- AC10: `make -n ci-fast 2>/dev/null | grep -c '_run_map\|similar_guard_controls.sh'; grep -nE
  '^(similar-test|ci-fast): similar-main-guard similar-guard-controls$' Makefile` → count ≥ 2 (V22 measured 12);
  exactly two edge lines. Post-push tail: the PR's GitHub `make ci-fast` check green (`gh pr checks`).

### MS4 — V: meta-drills + AC5–AC9, AC11–AC13 (no new code; `$S/7ah_meta.sh` from the Appendix C fence, never committed)

Closes AC5, AC6, AC7, AC8, AC9, AC11, AC12, AC13.

- AC5: `perl -e 'alarm 300; exec @ARGV' sh $S/7ah_meta.sh "$PWD" > $S/ms4-meta.log 2>&1; echo rc=$?; grep -E '^meta'
  $S/ms4-meta.log` → rc 0; `meta base: rc 0 :: …13 rejected, 3 accepted`; M1_nofloor → `below: make rc 0, want 2`;
  M2_noexact → `exact: …`; M3_nocount → `removed: missing reason:`; M4_oldguard → `pristine: make rc 2, want 0`
  **and** its log carries `main.gd lost EARTH_MINOR`; M5_noop → `below: mutation left main.gd unchanged`; M6 →
  `exprconst: make rc 0, want 2`; M7 → `exprfloor: missing reason:`; M8 → `ternary: …`; M9 → `comparison: …`;
  finally `meta: 9 weakenings caught` (V8/V21/V22).
- AC6 no-op sentinel: `sed '/^mutate below/s/want_minor \*= \*SimBridge/NOPE_NOPE/' tools/similar_guard_controls.sh
  > $S/7ah_noop.sh; perl -e 'alarm 120; exec @ARGV' env MAKE=make sh $S/7ah_noop.sh .; echo rc=$?` →
  `similar-guard-controls: below: mutation left main.gd unchanged`, rc 3 (V9).
- AC7: `h=$(shasum main.gd bridge/sim_bridge.gd Makefile); perl -e 'alarm 120; exec @ARGV' make
  similar-guard-controls >/dev/null && perl -e 'alarm 300; exec @ARGV' sh $S/7ah_meta.sh "$PWD" >/dev/null; test
  "$h" = "$(shasum main.gd bridge/sim_bridge.gd Makefile)" && git status --porcelain; find "$S" -maxdepth 1 \(
  -name 'similar-guard.*' -o -name 'stap7ah-meta.*' \) | wc -l` → hashes equal, no porcelain lines beyond the
  sprint's own files, `0` leftovers (V10; checked under `$S` since TMPDIR redirects there).
- AC8: `for c in e151c903 523d96f9 8ba1e3c8 79eadb49; do d=$S/heads/$c; mkdir -p $d/bridge; git show $c:main.gd >
  $d/main.gd; git show $c:bridge/sim_bridge.gd > $d/bridge/sim_bridge.gd; perl -e 'alarm 60; exec @ARGV' make -s
  similar-main-guard SIMILAR_GUARD_ROOT=$d; echo "$c rc=$?"; done` → rc 0 ×4; `EARTH_MINOR (16)`, `EARTH_MINOR
  (16)`, `EARTH_LOG_MINOR (18)`, `EARTH_LOG_MINOR (18)` (V7).
- AC9 (skip and record absent tools): `for m in make gmake; do command -v $m >/dev/null || continue; for f in '' -n
  -j4 -k; do perl -e 'alarm 120; exec @ARGV' $m $f similar-guard-controls 2>&1 | tail -1; done; done` → every line
  `similar-guard-controls: 13 rejected, 3 accepted`, no `warning`/`jobserver` (V11); `command -v dash >/dev/null &&
  perl -e 'alarm 60; exec @ARGV' gmake SHELL=/bin/dash similar-main-guard` rc 0 (V12); `command -v shellcheck
  >/dev/null && shellcheck tools/similar_guard_controls.sh && shellcheck -s dash tools/similar_guard_controls.sh`
  silent (V12/V22).
- AC11: `perl -e 'alarm 300; exec @ARGV' make uid-guard python-guard script-gate-lint audio-silent-guard; echo rc=$?;
  git diff --check 79eadb49` → `uid-guard: ok`, `python-guard: ok`, `script-gate-lint` rc 0 (no `--script` added,
  118-row baseline pin untouched), `audio-silent-guard: ok`; diff-check rc 0 (V13). No `.uid`, no allowlist row.
- AC12: `git diff --name-only 79eadb49 | grep -vE '^(design_docs/|\.ailang/state/|changelogs/)' | sort` → exactly
  `Makefile` and `tools/similar_guard_controls.sh` (nothing in `main.gd`, `bridge/`, `demos/`, `ui/`, `sim/`,
  `tests/`).
- AC13: `git diff -U0 79eadb49 -- Makefile | grep '^@@'` → hunks only within lines 96–136 (#412 at 32–38; #373 at
  10, 18, 225; #380 at 251 — V17).

## Pause points (stop and report; do not improvise)

- MS1: anything but make rc 2 with `pristine: make rc 2, want 0` (a pass implies a `similar-main-guard` target
  already exists → tree drift), or a surviving `similar-guard.*` dir.
- MS2: AC2's ok line or any AC3 case line deviates from V4/V5 in any token, or totals ≠ `13 rejected, 3 accepted`.
- MS3: AC1's log misses a pre-existing step, ok/controls lines not exactly-once, final sha ≠ `a64e9634…`, or the cmp
  proof fails — pause; never hand-tune the region away from the appendix bytes.
- MS4: any meta-drill not caught, `meta: 9 weakenings caught` absent, the no-op sentinel not rc 3, shellcheck
  non-silent, dash red, or any AC8 head failing.
- Post-push: the GitHub `make ci-fast` check red for an environment reason — stop for the controller; the design
  pre-authorizes only dropping the one `ci-fast:` edge line, never a weaker guard.
- Any temptation to touch the do-not-touch list: stop — the fix needs none of it. No merge before the cross-family
  evaluation (generator ≠ judge); landing files wait on it.

## Risks (from the design; mitigations already in the bytes)

- `_run_map` renamed/split later → loud failure (`mentions want_minor 0 times`), never silent; one-word RANGE edit.
- Expression-valued constants fail closed (`unresolved`; D10/D11, round 1's blocking objection, V19) — extend the
  resolver then, never loosen the grammar. A ternary/arithmetic/literal RHS fails `not one bare SimBridge minor`
  (D4/D8/D9); a second mention of any kind fails the count (D5/D12/D13).
- `make -n` executes the controls line (`$(MAKE)` semantics): read-only, < 1 s; `MAKEFLAGS=''` keeps the inner make
  real (V11); no tool in the repo dry-runs these targets.
- GitHub's clean-Linux runner (dash, GNU make 4.4.1) is unmeasured there: AC9's dash/gmake variants plus AC10's
  post-push `gh pr checks` close the gap.
- Sandbox /tmp (planner-measured): the `TMPDIR=$S` preamble redirects both scripts' temp roots into the gitignored
  repo scratch; if the executor's sandbox allows /tmp, leave TMPDIR unset and run AC7's check against it.
- Doc discrepancies (recorded in Plan verification; record, don't fix mid-sprint): prerequisite 19 vs 20; header r1
  LOC estimates vs V22's r2 numbers.

## Do-not-touch (design, verbatim scope)

`main.gd`, `bridge/sim_bridge.gd`, `demos/`, `ui/`, `sim/`, `tests/fixtures/protocol_*`; the vector-read guard's
logic (`Makefile:96–103`) beyond closing its zsh string at :103; the `ci-fast:` (:55) and `test:` (:57) lines;
attended PRs #412 (`@@ -32,6 +32,7 @@`), #373 (10, 18, 225), #380 (251). No product files, no Python, no `.gd` →
no `.uid`, no allowlist row. `$S/7ah_meta.sh` / `$S/7ah_noop.sh` are scratch, never committed.

## Local PR gates (targeted, headless, bounded)

ci.yml's run: steps invoke exactly `make deps`, `make lore-import CHECK=1 …` (all events), `make ci-fast` (push/PR
fast tier — the GitHub merge gate this row rides), `make test` (release only). For this row:

1. MS1 red proof on record (rc 2 at `pristine`; tree untouched).
2. `make similar-main-guard` and `make similar-guard-controls` rc 0 at the exact V4/V5 output (AC2–AC4).
3. `make similar-test` rc 0 — the targeted gate for the only target this row repairs — guard + controls reached
   through it, all pre-existing steps intact, final sha `a64e9634…` (AC1).
4. Meta-evidence: `9 weakenings caught` with M4's `lost EARTH_MINOR` line (AC5); no-op sentinel rc 3 (AC6); AC7
   tree-clean; AC8 heads 16/16/18/18; AC9 make/gmake/dash/shellcheck as installed.
5. Wiring: AC10's two greps (count ≥ 2, exactly two edge lines); post-push `gh pr checks` green on `make ci-fast`,
   which now runs both new targets on clean Linux.
6. Hygiene (ci-fast members): `make uid-guard python-guard script-gate-lint audio-silent-guard` rc 0; `git diff
   --check 79eadb49` clean; AC12 exactly `{Makefile, tools/similar_guard_controls.sh}` outside docs/state/changelog;
   AC13 hunks within 96–136.
7. Byte-for-byte: both cmp proofs against fresh fence extractions (A=29, B=147, C=51). No GPU gate, no
   `make golden`, no capture, no full local `make test` (merge rule; 7af/7ag/7aj precedent).

## Controller checks (the controller re-runs after the executor)

AC1 (`make similar-test` rc 0; ok line and `13 rejected, 3 accepted` exactly once; `lost EARTH_MINOR` ×0; final sha
`a64e9634…`) · AC3 (controls rc 0, 16 case lines, < 2 s) · AC5 (meta-drill log: base rc 0, all nine M-lines red at
the named cases, M4 carries `main.gd lost EARTH_MINOR`, `meta: 9 weakenings caught`) · AC8 (four heads rc 0,
16/16/18/18) · AC11 (four hygiene guards rc 0; `git diff --check` rc 0) · AC12 (diff scope exactly `Makefile` + the
script + docs/state/changelog) · AC13 (Makefile hunks within 96–136).

## Landing (controller, after the cross-family evaluation passes) and post-merge check

Changelog fragment naming R1-7AH-SIMILAR-GUARD, row 7ah, PR #379 attribution; `git mv` doc + plan to
`design_docs/implemented/r1/`; README index row; charter row 7ah status; sprint JSON → recorded counts and wall
times, `status: completed`, evaluation block, path moves. Post-merge (observation, not a gate): the next nightly
`rig/full` passes `similar-test` and the `nightly-rig` issue sheds exactly it, leaving the design's non-goals
(`bridge-operator-test` D-148, `tools-test` 7ai, `free-nav-stop-test` 7ak); a `similar-test guard:` failure on an
unmutated tree is a product finding for its own row, never an allowlist entry.

## Velocity / estimate

~180 LOC at r2 (`Makefile` +31/−3, script 147), make glue + one POSIX shell script. MS1/MS2 ~0.3 h each (guard and
controls run in < 1 s each); MS3 ~0.7 h (one `similar-test` 30–53 s, bound 300, + cmp proof); MS4 ~0.7 h
(meta-drills, four heads, eight make variants, hygiene). **One executor session, well under half a day.**
