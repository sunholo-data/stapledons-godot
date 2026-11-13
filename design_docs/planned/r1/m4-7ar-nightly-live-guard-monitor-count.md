# Main's nightly is green again: the live guard's five call sites, and monitor controls that read their counts from the run (row 7ar)

**Status:** Planned 2026-11-13 (mission iteration 92, designer Opus 5.5). Measured at `origin/main` `36f4ab4c`. **Release:** r1. **Milestone:** none (charter clause 5, suite hygiene: restores main's nightly `rig/full`).
**Priority:** high. Main's nightly `make test` is red on two targets (issue #392, comment of 2026-11-13 06:11 UTC on `85ca5470`: `2 red: ai-live-guard display-audit-monitor-controls`). Both are still red at `36f4ab4c` (V1, V5).
**Implements:** row **7ar** (charter queue). It restores AC15 of [`ai-service-foundation.md`](ai-service-foundation.md) (line 1047: "No spend in automation", checked by `make ai-live-guard`; the rules A–E are in the header of `tools/ai_live_guard.sh`) and AC6/AC14 of [`m4-7aj-monitor-face-bindings.md`](../../implemented/r1/m4-7aj-monitor-face-bindings.md) (four monitor-face mutants, each rejected by the crew audit for its own reason). No design-repo feature doc or physics-spec section applies: nothing the player sees, hears or computes changes.
**Depends on:** nothing. It must merge before the next nightly to stop the red, but no other row waits on it.
**Estimated LOC:** 6 files, +53 / −11 (V17, prototype commit): `mk/lab.mk` 3 lines, `tools/lab_probe.py` +2/−1, `tools/reach_probe.py` +3/−2, `mk/ai.mk` +9, `mk/earth-link.mk` +10/−5, new `tools/monitor_control_check.sh` (26 lines). No product code, no `.gd`, no `.uid`, and no `Makefile` edit (the `Makefile` is held by open PRs #435, #380 and #373, V19).

## Game vision alignment

Scored against `../stapledons-design/vision/core-pillars.md` and `physics/relativity-spec.md`. The run is unattended, so the designer scored the table without the `game-vision-designer` interview, as in the loop's earlier hygiene rows (7ah, 7aj, 7am).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game logic changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | No change. |
| The Ship Is Home | 0 | 0 | No scene, asset or layout change. The 7ae working points (D-148 A) stay as Mark ruled; only a test that pinned their side effect moves. |
| Grounded Strangeness | 0 | 0 | No content changes. |
| We Are Not Built For This | 0 | 0 | No crew or AI behaviour changes. The live-AI guard keeps automation offline: the AI service stays a stub in every test run, as before. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, LUT, golden or render. Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **ALIGNED (neutral): go.** Suite hygiene. Every 0 means "not touched". |

## Problem

### P1. `ai-live-guard`: five call sites can, by the guard's rules, run the AI service live

`sh tools/ai_live_guard.sh .` at `36f4ab4c` prints five rule-A breaches and exits 1 (V1):

| Site | Line | Why rule A fires | Landed in |
|---|---|---|---|
| `mk/lab.mk:62` | `$(LAB_RUN) --bytecode --strict-bytecode --entry $$e --args-json 0 sim/$$f.ail …` | the entry is a shell variable; the sim exception needs `--package-dir sim` **and** a literal `sim/…ail` on the line, and here `--package-dir sim` is hidden in `$(LAB_RUN)` and the program is `sim/$$f.ail` | `5007667a` (UL3a, merged by #445) |
| `mk/lab.mk:63` | `$(LAB_RUN) --entry $$e --args-json 0 sim/$$f.ail …` | same | same |
| `mk/lab.mk:70` | `$(LAB_RUN) --bytecode --strict-bytecode --entry $${spec#*:} … sim/$${spec%%:*}.ail …` | same | same |
| `tools/lab_probe.py:44` | `[ailang(), "run", …, "--package-dir", "sim", "--entry", entry, …, MODULE]` | a Python variable entry; the program is the variable `MODULE`, not a literal `sim/…ail` | `1fd16832` (UL0a, merged by #441 = `85ca5470`) |
| `tools/reach_probe.py:40` | `["--caps", "IO,FS", "--package-dir", "sim", "--entry", entry, …, PROBE]` | the same, with `PROBE` | `442b5694` (RE0, merged by #440 after the nightly, so the nightly listed only four) |

None of these can actually reach a live provider today: each runs a `sim/` program, and the sim has no live entry. But rule A is deliberately syntactic and line-local (AI.9 hardening: the evaluator showed that a looser rule is evaded), so the guard cannot know that `$(LAB_RUN)` names the sim and `MODULE` is `sim/tools/lab_probe.ail`. The repo already has a convention for exactly this case, and every other variable-entry call site follows it (V2):

- make: `env -u AI_LIVE $(MACRO) … --entry $$x sim/$$y.ail` (`mk/worlds.mk:12–13`, the closest analogue: a run macro plus a computed `sim/` path; also `Makefile:287–297`, `:840–841`, `:1484–1485`, `mk/ai.mk:72–74`);
- Python: `["env", "-u", "AI_LIVE", ailang, "run", …]`, with the comment `# env -u AI_LIVE: the entry is a variable, so make ai-live-guard wants AI_LIVE cleared here.` (`tools/rng_ref.py:130–131`, `tools/test_catalogue_bytes.py:28–29`).

**Why it merged red.** `ai-live-guard` runs only in `make test` (through `ai-test`); it is not in `ci-fast` (V4: `make -n ci-fast` names `ai_live_guard` 0 times). Since 2026-11-03 PRs merge on `ci-fast` plus targeted gates, so the attended lab and reach PRs merged without it, and the nightly found them.

### P2. `display-audit-monitor-controls`: two controls pin a sample count that an approved change moved

At `36f4ab4c` the target exits 2 with `display monitor controls: 2 rejected` (V5). `unrefreshed` and `drop_one` are rejected; `unbound` and `stale` fail on a literal:

| Control | Pinned (`mk/earth-link.mk`) | Measured at HEAD |
|---|---|---|
| `unbound` (`:42`) | `'^display-audit: .* new=46 .* failures=46$$'` | `samples=45 … new=45 … failures=45` |
| `stale` (`:43`) | `'^display-audit: .* mismatches=46 .* failures=92$$'` | `samples=45 … mismatches=45 … failures=90` |

Each control still does what it is for: the `unbound` stray label is reported on **every** sampled frame (`new = samples`) and the `stale` text on every frame (`mismatches = samples`, plus a binding-contract failure each, so `failures = 2 × samples`). Only the count moved. The crew playthrough (`tests/playthrough_crew.json`) now samples 45 frames, not 46. The cause is row 7ae's landing (#443, `3ce93c9d`), which moved the Voyage and Crew working points 0.275 m to the D-132 snug point per Mark's ruling D-148 A: the captain's walk is shorter, so one fewer every-fourth-frame sample is taken. The controller bisected this (46 at `0154b7c2`, 45 at `3ce93c9d`); the designer confirmed the cause first-party by restoring only the two `use_m` working points in `assets/ship_demo/manifest.json` to their pre-7ae values on HEAD: the sample count returns to 46 (V6). The product is right. The control is brittle.

The other two controls pin frame numbers by the same mechanism: `unrefreshed` expects `frame=1` (the first sampled frame) and `drop_one` expects `frame=36` (the frame of the tenth sampled row, where the mutant hides the course face). These still match at HEAD, but the next walk-timing change can move `frame=36` the same way.

**No other pin breaks the same way (V7).** `git grep` over `tests`, `mk`, `Makefile` and `tools` for `new=`, `mismatches=`, `failures=`, `samples=` and `frame=` with a value other than 0 or 1 finds only `mk/earth-link.mk:42–43`. The other crew-playthrough consumer, `display-audit-crew` (`mk/m45.mk:181–184`), checks `new=0 … failures=0` and `ac4: MET`, which do not depend on the count. `46`, `92`, `138` and `13708` occur in `mk`/`Makefile` nowhere else (the `46`s in `tests/*.gd` are unrelated: D-46 radio, feed fixtures, a star's declination). The `samples=46`, `known=138`, `checks=13386` readings in the 7aj sprint doc are history, not checks.

## Goals and non-goals

**Goals:**
- `sh tools/ai_live_guard.sh .` exits 0 on main by fixing the five call sites to the repo's existing convention, without weakening any guard rule.
- The class is caught at PR time: the static half of the guard runs in `ci-fast`.
- The monitor controls keep their full discriminating power (each mutant's reason on every frame, or on the right frame) with no pinned count or frame number, and refuse a vacuous run.
- A permanent mutant row proves the lab.mk shape (`$(LAB_RUN) --entry $$e sim/$$e.ail`) stays caught.

**Non-goals:**
- Changing `tools/ai_live_guard.sh` (rule A stays syntactic and line-local; see D1, "Why not widen the sim exception").
- Changing the 7ae working points, the playthrough script, the harness's sampling cadence or `tests/display_audit.gd`.
- Adding the full `ai-live-guard` (mutants plus the Godot launch-builder check) to `ci-fast`: it needs `import`, and the fast tier has no Godot (`Makefile:66–69`).
- Any `Makefile` edit (held, V19).

## Design

### D1. The five call sites, by the existing convention (P1)

- `mk/lab.mk:62`, `:63`, `:70`: prefix `env -u AI_LIVE ` to the line, exactly as `mk/worlds.mk:12–13` does for `$(WORLDS_RUN) --entry $$2 sim/$$1.ail`.
- `tools/lab_probe.py:44`: return `["env", "-u", "AI_LIVE", ailang(), …]`, with the comment line from `tools/rng_ref.py:130` above it.
- `tools/reach_probe.py:39–40`: the command is split over two lines, and rule A is line-local, so `env` on line 39 would not clear line 40. Measured: that two-line form still fails at the `--entry` line (V10, `M-reach-split`). The fix hoists the optional flag into `vm` and puts the whole argv on one line, prefixed by `"env", "-u", "AI_LIVE"`, with the same comment.

`env -u AI_LIVE` execs the child in place, so both probes' `os.wait4` still read the AILANG process (V11: `peak_rss_mb` 304.5 and 106.5 MB, the runtime's, not `env`'s). Its few hundred microseconds cancel in both probes' "full minus base" costs, and the committed probe files are re-judged from recorded runs (`lab-probe-check`), not re-measured. No probe file records the command line (V11).

**Why not widen the sim exception** (for example, accept `$(LAB_RUN)` because it expands to `--package-dir sim`, or a Python `MODULE` constant)? Rule A is line-local by design: AI.9 hardening round 2 added a mutant for "the sim exception without a sim/ program" because a looser exception was evaded. Teaching the guard to expand make macros or resolve Python constants is a larger change to a security guard, for five lines that have a one-token fix. The default stands.

### D2. The static guard in the fast tier (P1, "why it merged red")

New target in `mk/ai.mk` (the AI targets' home; the `Makefile` is held), after `ai-test: ai-live-guard ai-settings` (`mk/ai.mk:445`):

```make
# 7ar: the static rules alone (git, perl, sh; no Godot, no import; about 8 s) run in the GitHub fast tier, so
# a PR that adds a line able to run the service live without clearing AI_LIVE fails before it merges. The
# whole target below (each rule's mutant, the launch builder under Godot) stays in make test.
.PHONY: ai-live-guard-static
ai-live-guard-static: ## AC15 rules A-E over the tracked tree (tools/ai_live_guard.sh); in ci-fast
	@sh tools/ai_live_guard.sh .
ci-fast: ai-live-guard-static
```

**Decision: add it.** Reasons:
1. **Cost.** 8.0 s wall (3.9 s user) on the Studio at 1-min load 3.4 (V1, V8). Against a fast tier of about 10 minutes that is about 1%. It scans 98 make/shell/CI files and 549 scripts.
2. **Dependencies.** `git`, `perl`, `sh`, `mktemp`, `sed`, `grep`. All are on `ubuntu-latest`, and `actions/checkout` gives a work tree, so the guard takes its `git ls-files` branch, as on the Studio. No AILANG, no Godot, no `import`.
3. **It is a policy lint,** like `python-guard`, `audio-silent-guard` and `uid-guard`, which are already in `ci-fast` for the same reason: a merge rule that skips them lets the class back in. Both of 7ar's breaches came from attended PRs that merged green on the fast tier.
4. **It does not duplicate the mutant loop.** The mutants and the Godot launch-builder check stay in `make test` (they need `import`), and `ai-live-guard`'s recipe is unchanged, so `make test` still runs the static half too (8 s, accepted to keep `ai-live-guard` self-contained).

Not verified by the designer: the run on GitHub's Linux runner. The PR's own fast-tier run is that measurement (AC15).

### D3. A permanent mutant row for the lab.mk shape

One row in `ai-live-guard`'s mutant table (`mk/ai.mk:474`, after the `_rogue2` row, before the `include` row):

```make
	  'mk/lab.mk@\z@\nlab-mutant:\n\tfor e in x; do $$(LAB_RUN) --entry $$$$e --args-json 0 sim/$$$$e.ail; done\n@A mk/lab.mk' \
```

It appends a recipe with the exact uncleared shape D1 fixes (run macro, shell-variable entry, computed `sim/` path) to a scratch copy of `mk/lab.mk` and requires `ai-live-guard: A mk/lab.mk`. Measured: `guard mutant caught: mk/lab.mk (A mk/lab.mk)`, 25 caught in all (V9). The row is a single-quoted string with no inner quote, so the guard's own table exemption (`EXEMPT` in `tools/ai_live_guard.sh`) skips it: the static guard stays at rc 0 with the row in place (V8).

### D4. Monitor controls that read their counts from the run (P2)

A small POSIX helper, `tools/monitor_control_check.sh AUDIT_LOG SAMPLES_NDJSON PATTERN...`, replaces the recipe's inline `grep` loop (`mk/earth-link.mk:37`). It:
1. reads `N` from the audit's own summary line `^display-audit: samples=N `; no summary line → refuse;
2. requires `N` to equal the line count of the samples file the playthrough wrote (the audit read every row);
3. requires `N >= MONITOR_MIN_SAMPLES` (default 10). Why 10: `drop_one` hides the course face on the tenth sampled row (`tests/m4_playthrough_ship.gd:70`), so a shorter run cannot exercise it. A vacuous run (`samples=0 … new=0 … failures=0`) would otherwise satisfy `new=N failures=N` as 0 = 0;
4. reads `F1` and `F10`, the `"frame"` of sampled rows 1 and 10 (the encoder writes `{"frame":…` first, V5), and refuses if either is missing;
5. replaces `@N@`, `@2N@`, `@F1@`, `@F10@` in each pattern and greps it as before; on the first miss it prints `missing reason <pattern as substituted>` and exits 1.

The four `ctl` lines change only where a number was pinned:

| Control | Before | After |
|---|---|---|
| `unrefreshed` | `frame=1 clocks` | `frame=@F1@ clocks` |
| `drop_one` | `frame=36 course` | `frame=@F10@ course` (`failures=1` stays literal: exactly one frame is broken) |
| `unbound` | `.* new=46 .* failures=46` | `samples=@N@ .* new=@N@ .* failures=@N@` |
| `stale` | `.* mismatches=46 .* failures=92` | `samples=@N@ .* mismatches=@N@ .* failures=@2N@` |

**Discriminating power is kept, not loosened.** `new=@N@` still demands the stray label on every sampled frame; a mutant that misses one frame gives `new=N−1` and fails (V14, `unbound_row2`: `new=44` with `samples=45`). The same holds for `stale` (`mismatches=44 failures=88`) and for a drop on any row but the tenth (`drop_row11`). A cadence change that moves `N` (every third frame: `samples=60`) keeps all four controls green, where the old pins would fail (V14, `cadence3`).

**A vacuous-run negative control in the recipe.** Before the four playthroughs, the recipe feeds the helper a synthetic `samples=0` log with an empty samples file and requires the refusal `samples=0, fewer than …`. It costs no Godot and about 10 ms, and it fails the target if the floor is ever deleted or the helper is missing (V16). The `grep` for the floor's own message matters. With the floor deleted, step 4 still refuses the empty file, but for the wrong reason, and the control names that (V16).

**Why a helper file rather than inline make shell.** The floor and the skew check must be killable by a test that needs no Godot. A file can be driven by synthetic inputs (Appendix B: six cases, two helper mutants each caught, V15). The inline loop could only be tested by mutating the harness and running four playthroughs. It is shell, the repo's language for glue; Python would be a new pipeline step (CLAUDE.md "Python").

### Gates: where the touched files run

| File | Run by | In `make test` | In `ci-fast` |
|---|---|---|---|
| `mk/lab.mk` (`lab-parity`) | `make strict`, `make parity`, `make test` (via `lab-test`) | yes | yes (strict, parity) |
| `tools/lab_probe.py` | `lab-probe` (attended, minutes; never a gate); `--verify` in `lab-probe-check` does not spawn | `--verify` only | no |
| `tools/reach_probe.py` | `reach-probe`, `reach-probe-io` (attended measurements) | no | no |
| `mk/ai.mk` | `ai-live-guard` (via `ai-test`); new `ai-live-guard-static` | yes | **yes, new** |
| `mk/earth-link.mk`, `tools/monitor_control_check.sh` | `display-audit-monitor-controls` (via `ship-demo-ci`) | yes | no (needs Godot) |

## Exact edits

The edited text of every changed region, copied from the prototype commit measured in V17, is Appendix C. In summary (line numbers at `36f4ab4c`):

| # | File:line | Before | After |
|---|---|---|---|
| E1 | `mk/lab.mk:62` | `\t  $(LAB_RUN) --bytecode --strict-bytecode --entry $$e …` | `\t  env -u AI_LIVE $(LAB_RUN) --bytecode --strict-bytecode --entry $$e …` |
| E2 | `mk/lab.mk:63` | `\t  $(LAB_RUN) --entry $$e …` | `\t  env -u AI_LIVE $(LAB_RUN) --entry $$e …` |
| E3 | `mk/lab.mk:70` | `\t  $(LAB_RUN) --bytecode --strict-bytecode --entry $${spec#*:} …` | `\t  env -u AI_LIVE $(LAB_RUN) --bytecode --strict-bytecode --entry $${spec#*:} …` |
| E4 | `tools/lab_probe.py:44` | `    return [ailang(), "run", …]` | comment line + `    return ["env", "-u", "AI_LIVE", ailang(), "run", …]` |
| E5 | `tools/reach_probe.py:39–40` | two-line `cmd = [a.ailang, "run", "--quiet"] + (["--bytecode"] if bytecode else []) + \` / `["--caps", …, PROBE]` | `vm = ["--bytecode"] if bytecode else []`, comment line, one-line `cmd = ["env", "-u", "AI_LIVE", a.ailang, "run", "--quiet", *vm, "--caps", …, PROBE]` |
| E6 | `mk/ai.mk:446` (after `ai-test:`) | — | the D2 block (8 lines) |
| E7 | `mk/ai.mk:474` (after `_rogue2`) | — | the D3 row |
| E8 | `mk/earth-link.mk:26` (after the 7aj comment) | — | 2 comment lines naming the tokens |
| E9 | `mk/earth-link.mk:29` (first recipe line) | — | the vacuous-run control (3 recipe lines, D4) |
| E10 | `mk/earth-link.mk:37` | `for p in "$$@"; do grep -Eq -- "$$p" $$log.audit.log \|\| { …missing reason $$p…}; done; \` | `if ! why=$$(sh tools/monitor_control_check.sh $$log.audit.log $$log/display_samples.ndjson "$$@"); then echo "display monitor controls: $$m $$why"; bad=$$((bad + 1)); return 0; fi; \` |
| E11 | `mk/earth-link.mk:40–43` | the four `ctl` lines with `1`, `36`, `46`, `46/92` | the tokens in D4's table |
| E12 | `tools/monitor_control_check.sh` (new, mode 100644, run with `sh`) | — | Appendix C |

## Acceptance criteria

Run from the clone root with the pinned runtime: `export PATH=$PWD/runtime/bin:$PATH` (AILANG v0.56.1), after `make import`. `$D` is a scratch directory outside the repo holding Appendix A (`d7ar_drill.sh`) and Appendix B (`d7ar_helper_cases.sh`); `ROOT=$PWD`. Every command is bounded by `tools/deadline.sh` (the repo's process-group deadline). None needs the GPU, `make golden` or the whole of `make test`. "Baseline" is the designer's reading on pristine `36f4ab4c`.

| AC | Checks | Command | Expected (built) | Baseline |
|---|---|---|---|---|
| AC1 | The static guard passes | `sh tools/deadline.sh 120 sh tools/ai_live_guard.sh .` | `ai-live-guard: ok (98 make/shell/CI files, 549 test/tool scripts, launch builder, settings)`, rc 0 | 5 `A` lines (P1 table), rc 1 (V1) |
| AC2 | The static guard is in the fast tier | `test "$(sh tools/deadline.sh 60 make -n ci-fast 2>/dev/null \| grep -cx 'sh tools/ai_live_guard.sh .')" -eq 1` | rc 0 | count 0, rc 1 (V4) |
| AC3 | The new target runs alone | `sh tools/deadline.sh 120 make ai-live-guard-static` | the AC1 line, rc 0 | no such target |
| AC4 | The whole guard, its 25 mutants and the launch builder | `sh tools/deadline.sh 900 make ai-live-guard > $D/alg.log 2>&1; echo rc=$?; grep -c '^guard mutant caught' $D/alg.log; grep -x 'guard mutant caught: mk/lab.mk (A mk/lab.mk)' $D/alg.log; tail -1 $D/alg.log` | `rc=0`; `25`; the lab.mk line; `script-gate: ai-live-guard ok: ai settings: ok (9 passed, 0 failures; launch_default) …` | rc 2 at the static step (V1) |
| AC5 | Killing mutants: each fixed site reverted in a scratch copy is caught | `for m in guard-lab guard-reach guard-labprobe; do sh tools/deadline.sh 300 bash $D/d7ar_drill.sh $m $ROOT \| tail -1; done` | `d7ar-drill: guard-lab KILLED`, `… guard-reach KILLED`, `… guard-labprobe KILLED` | `mutation guard-lab did not apply`, rc 3 (V17) |
| AC6 | The fixed lab lines still run | `sh tools/deadline.sh 600 make lab-parity` | 4 `lab-parity: … (strict VM = interpreter)` lines and `lab-parity: 4 checks NOT on the strict VM …`, rc 0 | the same (unchanged behaviour) (V12) |
| AC7 | The fixed probes still spawn AILANG | `AILANG=ailang sh tools/deadline.sh 120 python3 -I -c 'import sys; sys.path.insert(0, "tools"); import lab_probe as l; p = l.start("draws", 2000); print(p.args[:4]); print(l.finish(p)[0])'` and `sh tools/deadline.sh 120 python3 -I -c 'import sys, types; sys.path.insert(0, "tools"); import reach_probe as r; print(r.ail(types.SimpleNamespace(ailang="ailang"), "drawMain", {"seed": 1, "n": 0})[0])'` | `['env', '-u', 'AI_LIVE', 'ailang']` then `draws n=2000 accepted=91 first=1 mix=6578220370666750`; and `0.0`; both rc 0 | the same values without the `env` prefix (V11) |
| AC8 | The monitor controls are green | `sh tools/deadline.sh 590 make display-audit-monitor-controls > $D/mc.log 2>&1; echo rc=$?; grep '^display monitor' $D/mc.log` | `rc=0`; four `display monitor control <m>: rejected` lines; `display monitor controls: 4 rejected` | rc 2; `unbound missing reason …new=46…`, `stale missing reason …mismatches=46…`, `2 rejected` (V5) |
| AC9 | Killing mutants: each control still rejects only every frame or the right frame, and the floor is live | `for m in unbound-partial stale-partial drop-row floor; do sh tools/deadline.sh 600 bash $D/d7ar_drill.sh $m $ROOT \| tail -1; done` | `d7ar-drill: unbound-partial KILLED`, `stale-partial KILLED`, `drop-row KILLED`, `floor KILLED` (the partial modes also require the other three controls still rejected: `3 rejected`) | not run: the base is already red (V5, `2 rejected`), so the partial modes cannot show `3 rejected` there and would report `SURVIVED` |
| AC10 | Robustness: a count change keeps the controls green | `sh tools/deadline.sh 600 bash $D/d7ar_drill.sh cadence $ROOT \| tail -1` | `d7ar-drill: cadence PASSED (samples=60)` | not run: the pins expect 46, so the base would report `FAILED` |
| AC11 | The helper refuses a vacuous, short, skewed or summary-less run, and a partial one | `sh tools/deadline.sh 60 sh $D/d7ar_helper_cases.sh $ROOT` | six `case …: ok` lines, `d7ar helper cases: 0 wrong`, rc 0 | no helper (V15) |
| AC12 | No pinned count or frame remains | `git grep -nE '(new\|mismatches\|failures)=(4[0-9]\|9[0-9])\|frame=(1\|36) (clocks\|course)' -- mk Makefile tests tools; test $? -eq 1` | no output, rc 0 | the four `mk/earth-link.mk:40–43` hits |
| AC13 | Policy lints on the touched files | `for t in python-guard uid-guard script-gate-lint; do sh tools/deadline.sh 120 make $t \|\| exit 1; done; git diff --check 36f4ab4c HEAD; sh -n tools/monitor_control_check.sh` (and `shellcheck tools/monitor_control_check.sh` where installed) | `python-guard: ok (25 allowlisted, …)`, `uid-guard: ok (470 .uid files)`, `script-gate-prereqs: ok …`; no diff-check output; rc 0 | same counts (V18) |
| AC14 | Scope | `test "$(git diff --name-only 36f4ab4c HEAD -- . ':!design_docs' ':!.ailang' \| tr '\n' ' ')" = "mk/ai.mk mk/earth-link.mk mk/lab.mk tools/lab_probe.py tools/monitor_control_check.sh tools/reach_probe.py "` | rc 0 | empty |
| AC15 | The GitHub fast tier on the PR, including `ai-live-guard-static` on Linux | `gh pr checks <PR>` (bounded: `sh tools/deadline.sh 60 gh pr checks <PR>`) | `fast tier … pass` | not run by the designer |
| AC16 | Tree clean after the drills | `git status --porcelain` | empty | empty (V17) |

The next nightly `rig/full` on main should not name `ai-live-guard` or `display-audit-monitor-controls`. That is the outcome this row is for, but it is not a merge gate (merges never wait on the rig).

## Test plan: what each check kills (measured, V10, V14–V17)

| Check | Mutation | Killed by | Reading |
|---|---|---|---|
| static guard (rule A) | `mk/lab.mk:63` without `env -u AI_LIVE` | AC5 `guard-lab` | `A mk/lab.mk:63: … (--entry $$e; AI_LIVE not cleared on the line)`, rc 1 |
| static guard | `tools/reach_probe.py` without the `env` prefix | AC5 `guard-reach` | `A tools/reach_probe.py:41: …`, rc 1 |
| static guard | `tools/lab_probe.py` without the `env` prefix | AC5 `guard-labprobe` | `A tools/lab_probe.py:45: …`, rc 1 |
| static guard | `reach_probe.py` with `env` on the first of two lines only | V10 `M-reach-split` (why E5 is one line) | `A tools/reach_probe.py:42: …`, rc 1 |
| `ai-live-guard` table (D3) | a new uncleared `$(LAB_RUN) --entry $$e sim/$$e.ail` recipe in `mk/lab.mk` | AC4 | `guard mutant caught: mk/lab.mk (A mk/lab.mk)` |
| `ci-fast` edge (D2) | the `ci-fast: ai-live-guard-static` line removed | AC2 | count 0 |
| `unbound` (`new=@N@ failures=@N@`) | the stray label added on sampled row 2, not 1 (misses one frame) | AC9 `unbound-partial` | `new=44 failures=44` with `samples=45`: `unbound missing reason ^display-audit: samples=45 .* new=45 .* failures=45$`, `3 rejected` |
| `stale` (`mismatches=@N@ failures=@2N@`) | the stale text skipped on the first sampled frame | AC9 `stale-partial` | `mismatches=44 failures=88`: `stale missing reason …mismatches=45 .* failures=90$`, `3 rejected` |
| `drop_one` (`frame=@F10@`) | the face hidden on row 11, not 10 | AC9 `drop-row` | `drop_one missing reason ^FAIL monitor-coverage frame=36 course$`, `3 rejected` |
| vacuous-run control (recipe) | the helper's floor line deleted | AC9 `floor` | `FAIL the vacuous run was not refused by the samples floor: no frame on sampled row 1 or 10 …`, in 2–3 s, before any playthrough |
| vacuous-run control | the helper missing | V16 | `FAIL the vacuous run was not refused by the samples floor: ` (empty reason) |
| helper floor | `samples=0` / `samples=9` | AC11 `vacuous`, `short` | `samples=0, fewer than 10 (a vacuous run)` / `samples=9, …` |
| helper skew | the audit read 11 rows of a 12-row file | AC11 `skew` | `the audit read samples=11 but … has 12 lines` |
| helper | no summary line | AC11 `nosummary` | `no display-audit summary in …` |
| helper | `new=11` with `samples=12` | AC11 `partial` | `missing reason ^display-audit: samples=12 .* new=12 .* failures=12$` |
| AC11 itself | floor deleted / skew check disabled in the helper | V15 | `2 wrong` (vacuous, short) / `1 wrong` (skew) |
| positive | sampling every 3rd frame (`N` 45 → 60) | AC10 `cadence` | all four rejected, rc 0, `samples=60` |

## Sub-milestones and estimates

One milestone, **7ar-1**, one commit (or two: D1–D3 and D4 are independent), 6 files, +53/−11. Order: apply E1–E12; run AC1–AC4, AC6–AC8 and AC11–AC14; then the drills (AC5, AC9, AC10: about 4.5 minutes of headless playthroughs in total); then AC16. Wall time about 15 minutes; the slowest steps are `make ai-live-guard` (≈200 s) and the five control runs (≈52 s each).

## Risks and mitigations

- **The static guard fails on Linux for a portability reason.** It uses only POSIX `sh`, `perl`, `git`, `mktemp`, `sed` and `grep -E`, and the work-tree branch (`git ls-files`). AC15 is the measurement; if it fails, the fix is in the guard's portability, not a removal from `ci-fast`.
- **The fast tier grows by about 8 s.** Accepted (D2). It is about 1% of the tier.
- **A future walk change drops the crew playthrough below 10 samples.** The floor then fails the controls by name (`samples=9, fewer than 10`). That is correct: below 10 rows `drop_one` cannot run. The fix would be in the playthrough script, and the message says so.
- **The samples encoder reorders keys so `"frame"` is not first.** The helper then refuses with `no frame on sampled row 1 or 10` (fails closed, by name); it never passes silently.
- **An open attended PR adds another uncleared variable entry.** It now fails its fast tier (D2). None of the three open PRs adds one today (V19: #435's new `--entry` lines are literal).
- **Running the drills leaves the tree dirty.** The drill restores the harness and the helper with `git checkout` on exit, and refuses (rc 3) if a mutation did not apply. AC16 checks.

## Open questions for the user

None. The loop decided these itself (recorded here):
1. **Fix the call sites, not the guard.** The repo's convention covers all five; widening the sim exception would loosen a security guard that was hardened against exactly this kind of exception (D1).
2. **The static guard goes into `ci-fast`.** It is cheap, Godot-free, and a policy lint like the three already there; both of 7ar's breaches came through fast-tier merges (D2). The target lives in `mk/ai.mk` because the `Makefile` is held.
3. **Derive `frame=1` and `frame=36` too,** although they still pass. They are the same brittleness, and they would break the same way at the next walk-timing change (D4).
4. **Floor 10, not "at least 1".** It is tied to the `drop_one` mutant's row, not to today's 45, so a shorter or longer voyage does not move it.

## Deliverables

- E1–E12 (Appendix C), one PR.
- After the evaluation passes: this doc moves to `design_docs/implemented/r1/`, the README index gains its row, and the charter row 7ar and issue #392 are updated (controller).

## Verification log

All readings are on `/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter92` (`origin/main` `36f4ab4c`), with the pinned runtime on PATH. The host was the shared Studio, 1-min load 2.3–4.7.

| V | What | Command (bounded) | Reading |
|---|---|---|---|
| V1 | Static guard at HEAD | `/usr/bin/time -p sh tools/deadline.sh 120 sh tools/ai_live_guard.sh .` | the five `A` lines of P1 (`mk/lab.mk:62,63,70`, `tools/lab_probe.py:44`, `tools/reach_probe.py:40`), rc 1; `real 7.99 user 3.87 sys 3.39` |
| V2 | The repo's convention for variable entries | `git grep -n -- '-u AI_LIVE' -- '*.py' '*.mk' Makefile '*.sh' '*.gd'`; `git grep -n 'AI_NOKEYS' -- Makefile mk` | make: `mk/worlds.mk:12–13` (`env -u AI_LIVE $(WORLDS_RUN) … --entry $$2 sim/$$1.ail`), `Makefile:287,288,297,840,841,1484,1485`, `mk/ai.mk:72,74`, `mk/ism.mk:4` (macro form, used only with literal entries); Python: `tools/rng_ref.py:130–131`, `tools/test_catalogue_bytes.py:28–29` (`["env", "-u", "AI_LIVE", …]` + the comment). `$(AI_NOKEYS)` is used only for `ai/` runs |
| V3 | Where the five lines came from | `git log -L62,63:mk/lab.mk`; `git log -S… -- tools/lab_probe.py tools/reach_probe.py`; `git log --first-parent 36f4ab4c` | `5007667a` (UL3a, merge #445 `2c84f2c2`), `1fd16832` (UL0a, merge #441 `85ca5470`), `442b5694` (RE0, merge #440 `c7a5815d`, after the nightly) |
| V4 | Fast tier at HEAD | `make -n ci-fast > f; grep -c ai_live_guard f; grep -c -- --import f`; `.github/workflows/ci.yml:59–61`; `Makefile:66–70` | `0`; `0` (no Godot import in the fast tier); ci.yml runs `make ci-fast` on PRs and pushes; ci-fast edges also live in `mk/*.mk` (`mk/observations.mk:22`, `mk/star-surfaces.mk:15`, `mk/script-gates.mk:27`) |
| V5 | Monitor controls at HEAD | `sh tools/deadline.sh 590 make display-audit-monitor-controls` (52 s); then `wc -l` and `sed -n 1p/10p` on each `monitor-<m>/display_samples.ndjson` | rc 2, `2 rejected`; `unbound … samples=45 … new=45 … failures=45`, `stale … mismatches=45 … failures=90`, `drop_one … failures=1` with `FAIL monitor-coverage frame=36 course`; every samples file 45 lines; row 1 `{"frame":1`, row 10 `{"frame":36` |
| V6 | Cause of 46 → 45, first-party | `make playthrough SCRIPT=tests/playthrough_crew.json` at HEAD, then with only `assets/ship_demo/manifest.json` from `3ce93c9d^1` (the two pre-7ae `use_m` points `±12.912, 11.626`), restored after | HEAD: rc 0, 45 lines (11 s); pre-7ae working points: rc 0, **46** lines (9 s); `git status` clean after |
| V7 | Other pins | `git grep -nE '(new\|failures\|mismatches\|samples\|frame)=[0-9]+' -- tests mk Makefile tools` (values ≠ 0, 1); `git grep -nwE '46\|92\|138\|13708' -- mk Makefile tests/*.gd tests/*.sh tests/*.json`; `git grep -n playthrough_crew -- mk Makefile tests tools` | only `mk/earth-link.mk:42,43`; the other hits are unrelated (`Makefile:671` golden help text "D-92", tests' D-92/RS-46/feed fixtures/Proxima's declination); `playthrough_crew` is consumed by `mk/earth-link.mk:33` and `mk/m45.mk:181` (`display-audit-crew`: `new=0 … failures=0`, count-free) |
| V8 | Static guard on the candidate | E1–E7 applied in place: `sh tools/deadline.sh 120 sh tools/ai_live_guard.sh .`; `make -n ci-fast \| grep -n ai_live_guard`; `make ai-live-guard-static` | `ok (97 …, 548 …)`, rc 0, `real 8.03`; the dry run names `sh tools/ai_live_guard.sh .` once; target rc 0. With the helper tracked (V17): `ok (98 make/shell/CI files, 549 test/tool scripts, …)` |
| V9 | Whole guard on the candidate | `sh tools/deadline.sh 900 make ai-live-guard` | rc 0 in 201 s; 25 `guard mutant caught`, including `guard mutant caught: mk/lab.mk (A mk/lab.mk)`; `script-gate: ai-live-guard ok: ai settings: ok (9 passed, 0 failures; launch_default)` (194 s and 24 caught before D3's row) |
| V10 | Guard mutants on scratch copies (the mutant loop's copy recipe) | revert one fixed line in `$G`, `sh tools/ai_live_guard.sh $G` | `M-lab63`: `A mk/lab.mk:63 …`, rc 1. `M-reach`: `A tools/reach_probe.py:41 …`, rc 1. `M-labprobe`: `A tools/lab_probe.py:45 …`, rc 1. `M-reach-split` (env on the first of two lines): `A tools/reach_probe.py:42 …`, rc 1 |
| V11 | The probes after E4/E5 | AC7's two commands; `AI_LIVE=1 sh -c 'env -u AI_LIVE sh -c "echo AI_LIVE=\${AI_LIVE-unset}"'`; `grep -c '"command"\|env' data/lab/probe*.json data/reach/*.json` | `['env', '-u', 'AI_LIVE', 'ailang']`, `('draws n=2000 accepted=91 first=1 mix=6578220370666750', 0.477777, 106.5)`; `('0.0', {… 'cpu_s': 2.465, 'peak_rss_mb': 304.5 …})`; `AI_LIVE=unset`; 0 in every probe file |
| V12 | `lab-parity` with E1–E3 | `sh tools/deadline.sh 600 make lab-parity` | rc 0 in 88 s; `scenarioVm scenario-ok`, `scenarioProbe 18744 bytes`, `statsVm stats-ok`, `statsProbe 10722 bytes`, `4 checks NOT on the strict VM …` |
| V13 | Controls on the candidate | `sh tools/deadline.sh 590 make display-audit-monitor-controls` (twice) | rc 0, 52 s and 50 s; `4 rejected`; the vacuous control's `why.txt`: `samples=0, fewer than 10 (a vacuous run)` |
| V14 | Harness mutants (in place, restored with `git checkout`) | `unbound_row2`, `stale_after1`, `drop_row11`, `cadence3` (Appendix A's perl expressions), each then `make display-audit-monitor-controls` | `unbound_row2`: rc 2, unbound `new=44 failures=44` → `missing reason …samples=45 .* new=45 .* failures=45$`, 3 rejected. `stale_after1`: rc 2, `mismatches=44 failures=88` → `missing reason …failures=90$`, 3 rejected. `drop_row11`: rc 2, `missing reason ^FAIL monitor-coverage frame=36 course$`, 3 rejected. `cadence3`: rc 0, `samples=60`, unbound `new=60 failures=60`, stale `mismatches=60 failures=120`, drop_one `frame=27`, 4 rejected |
| V15 | Helper on synthetic inputs | Appendix B on a copy of the helper; then with the floor line deleted, then with the skew check disabled | `0 wrong`, rc 0 (all six cases). Floor deleted: `2 wrong` (vacuous and short refused for `no frame on sampled row 1 or 10`, the wrong reason). Skew disabled: `1 wrong` (skew accepted, rc 0) |
| V16 | Vacuous-run control mutants | the floor line deleted from the helper, then the helper moved away; `make display-audit-monitor-controls` | floor deleted: `FAIL the vacuous run was not refused by the samples floor: no frame on sampled row 1 or 10 …`, rc 2, 2 s. Helper missing: `FAIL the vacuous run was not refused by the samples floor: ` (empty), rc 2 |
| V17 | Prototype commit and drills | E1–E12 committed on a temporary local branch (`9a3baa47`, `6 files changed, 53 insertions(+), 11 deletions(-)`); Appendix A, every mode; branch deleted afterwards | `guard-lab`, `guard-reach`, `guard-labprobe` KILLED; `floor` KILLED (3 s); `unbound-partial` (52 s), `stale-partial` (53 s), `drop-row` (50 s) KILLED with `3 rejected`; `cadence PASSED (samples=60)` (57 s); `git status --porcelain` empty after each. Pristine tree: `d7ar-drill: mutation guard-lab did not apply`, rc 3 |
| V18 | Lints on the candidate | `git diff --check`; `make script-gate-lint python-guard uid-guard`; `sh -n` and `shellcheck` on the helper | rc 0; `script-gate-prereqs: ok (5 pairs …)`, `python-guard: ok (25 allowlisted, 0 awaiting AILANG port)`, `uid-guard: ok (470 .uid files)`; `sh -n` rc 0; shellcheck clean |
| V19 | Holds | `gh pr list --state open`; `gh pr view N --json files` against the touched files; `gh pr diff 435` for new `--entry` lines | open: #435, #380, #373; each holds `Makefile`, none holds `mk/ai.mk`, `mk/lab.mk`, `mk/earth-link.mk`, `tools/lab_probe.py`, `tools/reach_probe.py` or `tools/ai_live_guard.sh`. #435's added `--entry` lines are literal (`funnel`, `cell`, `equivalence`, `funnelAt`) |

Every tracked file mutated for measurement was restored with `git checkout`; the temporary branch was deleted. At the end, `git status --porcelain`, `git diff --stat` and `git diff --cached --stat` are empty. `make import` left no untracked files in this clone.

**UNVERIFIED:**
- AC15, the GitHub fast tier on Linux with the new step.
- The controller's bisect points other than HEAD and the 7ae working points (V6 confirms the cause directly on HEAD).

## Appendix A: the drill (`d7ar_drill.sh`, sha256 `137537ba34afbb56…`)

```bash
#!/bin/bash
# 7ar killing-mutation drill. usage: bash d7ar_drill.sh MODE ROOT
#   guard-lab | guard-reach | guard-labprobe : the static guard on a scratch copy with one fixed line reverted
#   unbound-partial | stale-partial | drop-row : a monitor mutant that hits fewer frames, or another row
#   floor : the samples floor deleted from tools/monitor_control_check.sh
#   cadence : POSITIVE, the harness samples every 3rd frame (N changes); the controls must stay green
# Prints "d7ar-drill: MODE KILLED" (or "PASSED" for cadence) and exits 0; 1 if the mutant survived;
# 3 if the mutation did not apply. Every tracked file it touches is restored (git checkout) on exit.
MODE=${1:?MODE}; ROOT=${2:?ROOT}
cd "$ROOT" || exit 1
export PATH=$PWD/runtime/bin:$PATH
DL="sh tools/deadline.sh"
H=tests/m4_playthrough_ship.gd; C=tools/monitor_control_check.sh
trap 'git checkout -q -- "$H" "$C" 2>/dev/null' EXIT
mutate() { # FILE PERL-EXPR: apply in place, exit 3 unless the file changed
	cp "$1" "$1.d7ar"; perl -pi -e "$2" "$1"
	if cmp -s "$1" "$1.d7ar"; then rm -f "$1.d7ar"; echo "d7ar-drill: mutation $MODE did not apply"; exit 3; fi
	rm -f "$1.d7ar"
}
guard() { # FILE PERL-EXPR WANT: revert one fixed line in a scratch copy; the guard must fail on WANT
	G=$(mktemp -d)/g; mkdir -p "$G"
	git ls-files Makefile mk .github tests tools bridge ui | grep -v '^tests/replays/\|^tests/ai/\|^tests/fixtures/\|\.uid$' | tar -cf - -T - | tar -xf - -C "$G"
	cp "$G/$1" "$G/$1.orig"; perl -pi -e "$2" "$G/$1"
	cmp -s "$G/$1" "$G/$1.orig" && { echo "d7ar-drill: mutation $MODE did not apply"; exit 3; }
	rm -f "$G/$1.orig"
	$DL 120 sh tools/ai_live_guard.sh "$G" > "$G.out"; rc=$?
	grep -E "$3" "$G.out"
	if [ $rc -eq 1 ] && grep -Eq "$3" "$G.out"; then echo "d7ar-drill: $MODE KILLED"; exit 0; fi
	echo "d7ar-drill: $MODE SURVIVED (guard rc $rc)"; exit 1
}
controls() { # WANT [N]: make display-audit-monitor-controls must fail with WANT, and N controls still rejected
	$DL 590 make display-audit-monitor-controls > "/tmp/d7ar-$MODE.log" 2>&1; rc=$?
	grep -E '^display monitor control' "/tmp/d7ar-$MODE.log"
	if [ $rc -ne 0 ] && grep -Eq "$1" "/tmp/d7ar-$MODE.log" && { [ -z "${2:-}" ] || grep -q "^display monitor controls: $2 rejected$" "/tmp/d7ar-$MODE.log"; }; then echo "d7ar-drill: $MODE KILLED"; exit 0; fi
	echo "d7ar-drill: $MODE SURVIVED (make rc $rc)"; exit 1
}
case $MODE in
guard-lab) guard mk/lab.mk 's/^\t  env -u AI_LIVE (\$\(LAB_RUN\) --entry \$\$e )/\t  $1/' '^ai-live-guard: A mk/lab\.mk:[0-9]+:.*AI_LIVE not cleared on the line' ;;
guard-reach) guard tools/reach_probe.py 's/\["env", "-u", "AI_LIVE", a\.ailang/[a.ailang/' '^ai-live-guard: A tools/reach_probe\.py:[0-9]+:.*AI_LIVE not cleared on the line' ;;
guard-labprobe) guard tools/lab_probe.py 's/\["env", "-u", "AI_LIVE", ailang\(\)/[ailang()/' '^ai-live-guard: A tools/lab_probe\.py:[0-9]+:.*AI_LIVE not cleared on the line' ;;
unbound-partial) mutate $H 's/if mutant == "unbound" and monitor_rows == 1:/if mutant == "unbound" and monitor_rows == 2:/'
	controls '^display monitor controls: unbound missing reason ' 3 ;;
stale-partial) mutate $H 's/^\tif mutant == "stale":$/\tif mutant == "stale" and monitor_rows > 1:/'
	controls '^display monitor controls: stale missing reason ' 3 ;;
drop-row) mutate $H 's/if mutant == "drop_one" and monitor_rows == 10:/if mutant == "drop_one" and monitor_rows == 11:/'
	controls '^display monitor controls: drop_one missing reason ' 3 ;;
floor) mutate $C 'undef $_ if /fewer than \$min/'
	controls '^display monitor controls: FAIL the vacuous run was not refused by the samples floor' ;;
cadence) mutate $H 's/if frame % 4 != 0 and not changed: return/if frame % 3 != 0 and not changed: return/'
	$DL 590 make display-audit-monitor-controls > "/tmp/d7ar-$MODE.log" 2>&1; rc=$?
	grep -E '^display monitor control|unbound ok: display-audit: ' "/tmp/d7ar-$MODE.log" | sed -E 's/ checks=[0-9]+//'
	n=$(sed -nE 's/.*monitor-unbound ok: display-audit: samples=([0-9]+) .*/\1/p' "/tmp/d7ar-$MODE.log")
	if [ $rc -eq 0 ] && grep -q '^display monitor controls: 4 rejected$' "/tmp/d7ar-$MODE.log" && [ -n "$n" ] && [ "$n" != 45 ]; then echo "d7ar-drill: cadence PASSED (samples=$n)"; exit 0; fi
	echo "d7ar-drill: cadence FAILED (make rc $rc, samples=$n)"; exit 1 ;;
*) echo "d7ar-drill: unknown mode $MODE"; exit 2 ;;
esac
```

## Appendix B: the helper cases (`d7ar_helper_cases.sh`, sha256 `9bb22c0192eb52ca…`)

```sh
#!/bin/sh
# 7ar helper cases. usage: sh d7ar_helper_cases.sh ROOT   (no Godot; synthetic inputs in a temp dir)
# Each refused case must exit 1 with its own reason; the accepted case must exit 0.
cd "${1:?ROOT}" || exit 2
H=tools/monitor_control_check.sh; T=$(mktemp -d); bad=0
P='^display-audit: samples=@N@ .* new=@N@ .* failures=@N@$'
rows() { i=1; while [ $i -le "$1" ]; do printf '{"frame":%d,"view":{}}\n' $((i * 4)); i=$((i + 1)); done; }
sum() { printf 'display-audit: samples=%s checks=1 mismatches=0 missing=0 new=%s known=0 stale=0 failures=%s\n' "$1" "$2" "$3"; }
case_() { # NAME WANT_RC WANT_REASON LOG SAMPLES PATTERN...
	name=$1; want=$2; reason=$3; shift 3
	out=$(sh $H "$@"); rc=$?
	if [ $rc -eq "$want" ] && printf '%s\n' "$out" | grep -Eq -- "$reason"; then echo "case $name: ok (rc $rc${out:+: $out})"; else echo "case $name: WRONG (rc $rc: $out)"; bad=$((bad + 1)); fi
}
sum 0 0 0 > $T/zero.log; : > $T/zero.nd
case_ vacuous 1 '^samples=0, fewer than 10 ' $T/zero.log $T/zero.nd "$P"
sum 9 9 9 > $T/nine.log; rows 9 > $T/nine.nd
case_ short 1 '^samples=9, fewer than 10 ' $T/nine.log $T/nine.nd "$P"
sum 11 11 11 > $T/skew.log; rows 12 > $T/skew.nd
case_ skew 1 '^the audit read samples=11 but .* has 12 lines$' $T/skew.log $T/skew.nd "$P"
printf 'FAIL x\n' > $T/none.log
case_ nosummary 1 '^no display-audit summary in ' $T/none.log $T/skew.nd "$P"
sum 12 11 11 > $T/partial.log; rows 12 > $T/partial.nd
case_ partial 1 '^missing reason \^display-audit: samples=12 \.\* new=12 \.\* failures=12\$$' $T/partial.log $T/partial.nd "$P"
sum 12 12 12 > $T/ok.log; rows 12 > $T/ok.nd; printf 'FAIL monitor-coverage frame=40 course\n' >> $T/ok.log
case_ accepted 0 '^$' $T/ok.log $T/ok.nd "$P" '^FAIL monitor-coverage frame=@F10@ course$'
rm -rf "$T"; echo "d7ar helper cases: $bad wrong"; [ $bad -eq 0 ]
```

## Appendix C: the edited text (prototype `9a3baa47`, against `36f4ab4c`)

Each block is the text after the edit, copied from the prototype (V17). Context lines are included where they locate the edit.

### C1. `mk/lab.mk` (lines 62, 63 and 70 after the edit)

```make
	  env -u AI_LIVE $(LAB_RUN) --bytecode --strict-bytecode --entry $$e --args-json 0 sim/$$f.ail > $(SCRATCH)/lab-$$e-vm.txt || { echo "lab-parity: FAIL $$e (strict VM)"; exit 1; }; \
	  env -u AI_LIVE $(LAB_RUN) --entry $$e --args-json 0 sim/$$f.ail > $(SCRATCH)/lab-$$e-interp.txt || { echo "lab-parity: FAIL $$e (interpreter)"; exit 1; }; \
	  env -u AI_LIVE $(LAB_RUN) --bytecode --strict-bytecode --entry $${spec#*:} --args-json 0 sim/$${spec%%:*}.ail >> $(SCRATCH)/lab-not-strict.txt || { echo "lab-parity: FAIL $${spec#*:}"; exit 1; }; \
```

### C2. `tools/lab_probe.py` (lines 42–45)

```python
def command(entry, size, vm=True):
    flags = ["--bytecode", "--strict-bytecode"] if vm else []
    # env -u AI_LIVE: the entry is a variable, so make ai-live-guard wants AI_LIVE cleared here.
    return ["env", "-u", "AI_LIVE", ailang(), "run", "--quiet", *flags, "--package-dir", "sim", "--entry", entry, "--args-json", str(size), MODULE]
```

### C3. `tools/reach_probe.py` (lines 38–42)

```python
def ail(a, entry, args, bytecode=True):
    vm = ["--bytecode"] if bytecode else []
    # env -u AI_LIVE: the entry is a variable, so make ai-live-guard wants AI_LIVE cleared here.
    cmd = ["env", "-u", "AI_LIVE", a.ailang, "run", "--quiet", *vm, "--caps", "IO,FS", "--package-dir", "sim", "--entry", entry, "--args-json", json.dumps(args), PROBE]
    return child(cmd)
```

### C4. `mk/ai.mk`: the D2 block (lines 447–454) and the D3 row (line 483, between the `_rogue2` row and the `include` row)

```make
ai-test: ai-live-guard ai-settings

# 7ar: the static rules alone (git, perl, sh; no Godot, no import; about 8 s) run in the GitHub fast tier, so
# a PR that adds a line able to run the service live without clearing AI_LIVE fails before it merges. The
# whole target below (each rule's mutant, the launch builder under Godot) stays in make test.
.PHONY: ai-live-guard-static
ai-live-guard-static: ## AC15 rules A-E over the tracked tree (tools/ai_live_guard.sh); in ci-fast
	@sh tools/ai_live_guard.sh .
ci-fast: ai-live-guard-static

AI_G := $(SCRATCH)/ai-live-guard
ai_guard_scan = Makefile mk .github tests tools bridge ui
…
	  'ui/ui_scale.gd@\z@\nfunc _rogue2() -> void:\n\tOS.execute("ailang", ["run", "--entry", "live", "ai/service.ail"])\n@A ui/ui_scale.gd' \
	  'mk/lab.mk@\z@\nlab-mutant:\n\tfor e in x; do $$(LAB_RUN) --entry $$$$e --args-json 0 sim/$$$$e.ail; done\n@A mk/lab.mk' \
	  'Makefile@\z@\ninclude infra/live.mk\n@A Makefile: include outside mk/'; do \
```

### C5. `mk/earth-link.mk` (lines 23–50 after the edit: the whole target)

```make
# 7aj M3 (AC6, AC14): four monitor-face mutants (PLAYTHROUGH_MONITOR_MUTANT, tests/m4_playthrough_ship.gd), each played
# through the crew playthrough and rejected by the crew audit for its own reason. Both subprocesses run under a deadline:
# the playthrough target's own $(SCRIPT_GATE), and the audit's gate with WANT_RC 1 (an intentional rejection only). A
# deadline, launch, rc or SCRIPT ERROR fault is an infrastructure failure: it fails the target and is never counted.
# 7ar: counts and frames are read from the run (tools/monitor_control_check.sh: @N@ samples, @2N@, @F1@ and @F10@,
# the frames of sampled rows 1 and 10; N must equal the samples file's lines and be at least 10), never pinned.
MONITOR_AUDIT_S ?= 600
.PHONY: display-audit-monitor-controls
display-audit-monitor-controls: import ## 7aj AC6, AC14: four monitor-face mutants each rejected by the crew audit for its own reason; a stalled run fails closed
	@v=$(SCRATCH)/monitor-vacuous; mkdir -p $$v; printf 'display-audit: samples=0 checks=0 mismatches=0 missing=0 new=0 known=0 stale=0 failures=0\n' > $$v/audit.log; : > $$v/samples.ndjson; \
	  if sh tools/monitor_control_check.sh $$v/audit.log $$v/samples.ndjson '^display-audit: samples=@N@ .* new=@N@ .* failures=@N@$$' > $$v/why.txt; then echo "display monitor controls: FAIL a vacuous run (samples=0) passed the derived check"; exit 1; fi; \
	  grep -q '^samples=0, fewer than ' $$v/why.txt || { echo "display monitor controls: FAIL the vacuous run was not refused by the samples floor: $$(cat $$v/why.txt)"; exit 1; }
	@out=$(SCRATCH)/monitor-controls; rm -rf $$out; mkdir -p $$out; n=0; bad=0; \
	ctl() { \
	  m=$$1; shift; log=$$out/monitor-$$m; \
	  if ! PLAYTHROUGH_MONITOR_MUTANT=$$m $(MAKE) --no-print-directory AILANG=$(AILANG) playthrough SCRIPT=tests/playthrough_crew.json PLAYTHROUGH_OUT=$$log > $$log.play.log 2>&1; then \
	    echo "display monitor controls: $$m infrastructure failure (playthrough, log $$log.play.log)"; bad=$$((bad + 1)); return 0; fi; \
	  if ! $(SCRIPT_GATE) display-audit-monitor-$$m $$log.audit.log $(MONITOR_AUDIT_S) '^display-audit: ' 1 -- $(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- $$log/display_samples.ndjson crew $(DISPLAY_KNOWN); then \
	    echo "display monitor controls: $$m infrastructure failure (audit, log $$log.audit.log)"; bad=$$((bad + 1)); return 0; fi; \
	  if ! why=$$(sh tools/monitor_control_check.sh $$log.audit.log $$log/display_samples.ndjson "$$@"); then echo "display monitor controls: $$m $$why"; bad=$$((bad + 1)); return 0; fi; \
	  n=$$((n + 1)); echo "display monitor control $$m: rejected"; \
	}; \
	ctl unrefreshed '^FAIL missing field $$' '^FAIL binding contract .*/monitor_face_signal/' '^FAIL monitor-coverage frame=@F1@ clocks$$'; \
	ctl drop_one '^FAIL monitor-coverage frame=@F10@ course$$' '^display-audit: .* failures=1$$'; \
	ctl unbound '^FAIL NEW unbound node=.*/monitor_face_clocks/.*/Mutant text="42"$$' '^display-audit: samples=@N@ .* new=@N@ .* failures=@N@$$'; \
	ctl stale '^FAIL stale .*/monitor_face_clocks/' '^FAIL binding contract .*/monitor_face_clocks/' '^display-audit: samples=@N@ .* mismatches=@N@ .* failures=@2N@$$'; \
	echo "display monitor controls: $$n rejected"; test $$bad -eq 0 && test $$n -eq 4
ship-demo-ci: display-audit-monitor-controls
```

### C6. `tools/monitor_control_check.sh` (new, mode 100644; run with `sh`)

```sh
#!/bin/sh
# Row 7ar: the reasons one monitor-face control must show (make display-audit-monitor-controls), with
# its counts read from the run itself, never pinned: a pinned sample count broke when an approved
# layout change (7ae, D-148 A) took the crew playthrough from 46 samples to 45.
# The audit's summary line gives N, the samples it read. N must equal the lines of the samples file
# and be at least MONITOR_MIN_SAMPLES (10: drop_one hides a face on the tenth sampled row, so a
# shorter run cannot exercise it, and a vacuous run, samples=0, cannot pass new=N as 0=0).
# Each PATTERN is an ERE with these tokens replaced first: @N@ and @2N@ (N, 2N); @F1@ and @F10@
# (the frame numbers of sampled rows 1 and 10).
# Usage: tools/monitor_control_check.sh AUDIT_LOG SAMPLES_NDJSON PATTERN...
#   exit 0 silently when every pattern matches; else exit 1 with one line saying why.
set -u
log=$1; samples=$2; shift 2
min=${MONITOR_MIN_SAMPLES:-10}
n=$(sed -nE 's/^display-audit: samples=([0-9]+) .*/\1/p' "$log" | head -n 1)
case "$n" in ''|*[!0-9]*) echo "no display-audit summary in $log"; exit 1;; esac
lines=$(wc -l < "$samples" 2>/dev/null | tr -d ' ')
[ "$n" = "$lines" ] || { echo "the audit read samples=$n but $samples has ${lines:-no} lines"; exit 1; }
[ "$n" -ge "$min" ] || { echo "samples=$n, fewer than $min (a vacuous run)"; exit 1; }
f1=$(sed -n 1p "$samples" | sed -nE 's/^\{"frame":([0-9]+),.*/\1/p')
f10=$(sed -n 10p "$samples" | sed -nE 's/^\{"frame":([0-9]+),.*/\1/p')
[ -n "$f1" ] && [ -n "$f10" ] || { echo "no frame on sampled row 1 or 10 of $samples"; exit 1; }
for p in "$@"; do
	q=$(printf '%s\n' "$p" | sed "s/@2N@/$((2 * n))/g; s/@N@/$n/g; s/@F10@/$f10/g; s/@F1@/$f1/g")
	grep -Eq -- "$q" "$log" || { echo "missing reason $q"; exit 1; }
done
```
