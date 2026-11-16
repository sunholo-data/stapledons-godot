# Sprint plan: R1-7AR-NIGHTLY-LIVE-GUARD-MONITOR-COUNT — main's nightly green again: the live guard's five call sites, and monitor controls that read their counts from the run

**Design doc:** [m4-7ar-nightly-live-guard-monitor-count.md](m4-7ar-nightly-live-guard-monitor-count.md)
(revision 2, commit `5572504b`; quorum round 1 BLOCKED (gpt6-1-sol REJECT) → r1: `ai-live-guard-static`
under `$(SCRIPT_GATE)` with `AI_GUARD_S ?= 120`, stall drill AC17; round 2 BLOCKED (gpt6-1-sol REJECT) →
r2 by narrow-refinement carve-out: every mutant-loop and rule-E guard run under
`tools/deadline.sh $(AI_GUARD_RUN_S)` with `AI_GUARD_RUN_S ?= 60`, a mutant caught only on rc 1 with its
rule's line, drills AC19/AC20; no round 3). **Sprint JSON:**
`.ailang/state/sprints/sprint_R1-7AR-NIGHTLY-LIVE-GUARD-MONITOR-COUNT.json`.
**Approval basis:** pillar table net 0, none below 0 (suite hygiene: restores main's nightly `rig/full`,
issue #392); both quorum dispositions applied; the design's "Open questions for the user: None".
**Branch:** `mission/stapledon-iter92-7ar` (HEAD `5572504b`, the r2 design commit; merge-base with
`origin/main` is `36f4ab4c` = `origin/main` = the base every V-number was measured at;
`git diff --name-only 36f4ab4c..HEAD` = the design doc alone, so every V-number applies verbatim;
`git status --porcelain` empty).

**Scope:** exactly the design's six files (AC14): `mk/ai.mk`, `mk/earth-link.mk`, `mk/lab.mk`,
`tools/lab_probe.py`, `tools/reach_probe.py`, and new `tools/monitor_control_check.sh` (shell, mode
100644, run with `sh`; **no `.uid`** — it is not a Godot script). Prototype-measured +81/−17 over the
six files (V25, `5cd79549`). **No `.gd`, no `Makefile`** (held, V19), **no GPU, no `make golden`, no
full `make test`** (the nightly covers it; AC15 is the PR's fast tier). **No changelog fragment** — the
design's Deliverables name only E1–E12, and AC14's scope check fails on anything more.

## Environment

- `ROOT` = this clone's root. `export PATH=$PWD/runtime/bin:$PATH` (AILANG **v0.56.1**, provisioned and
  planner-verified). Godot **4.7.2.stable**, headless only. `runtime/` is untracked and present.
- `.godot` is imported in this clone; in a fresh executor clone run `sh tools/deadline.sh 600 make import`
  first (AC4 and AC8 need `import`).
- **Every command is bounded** with `sh tools/deadline.sh <s>` (macOS has no `timeout`).
- `$D` is a scratch directory **outside the repo** (e.g. `/tmp/i92_7ar`) holding the extracted
  `d7ar_drill.sh` (Appendix A) and `d7ar_helper_cases.sh` (Appendix B). Sandbox note (7am D1 precedent,
  re-verified by this planner: `/tmp` writes are refused in a sandboxed pi role): if `/tmp` refuses
  writes, reroot `$D` and the appendix scripts' hardcoded `mktemp -d` / `/tmp/d7ar-$MODE.log` templates
  1:1 under `$ROOT/.godot/tmp/7ar` (untracked); expectations unchanged. Never retype design text to
  work around a path problem.
- All timings cited below are the design's Verification Log readings on the shared Studio; do not
  re-derive them.

## Milestones (test-first; two code commits — the design: "one commit (or two: D1–D3 and D4 are independent)")

MS1 and MS4 commit nothing. No milestone exceeds ~250 changed lines (MS2 ≈ +70/−15, MS3 ≈ +11/−2 plus
the 33-line new helper, of the prototype's +81/−17, V25).

### MS1 — RED (no commit): extract the drills; record the pristine baselines

1. Extract Appendix A (fence lines 369–477 of the design) byte-for-byte to `$D/d7ar_drill.sh` and
   Appendix B (lines 483–518) to `$D/d7ar_helper_cases.sh`. Verify:
   - `shasum -a 256 $D/d7ar_drill.sh | cut -c1-16` = `e55b79e3e52d828b`
   - `shasum -a 256 $D/d7ar_helper_cases.sh | cut -c1-16` = `af21a44e875e5c88`
   On a mismatch, re-extract; still mismatched → **stop** (never retype design text).
2. Record the Baseline column on the pristine tree (the six files are untouched at `36f4ab4c`):
   - **AC1 baseline (V1):** `sh tools/deadline.sh 120 sh tools/ai_live_guard.sh .` → the five rule-A
     lines (`mk/lab.mk:62`, `:63`, `:70`, `tools/lab_probe.py:44`, `tools/reach_probe.py:40`), **rc 1**.
   - **AC12 baseline (V7):** `git grep -nE '(new\|mismatches\|failures)=(4[0-9]\|9[0-9])\|frame=(1\|36) (clocks\|course)' -- mk Makefile tests tools`
     → exactly the four `mk/earth-link.mk:40–43` hits.
   - **AC8 baseline (V5):** `sh tools/deadline.sh 590 make display-audit-monitor-controls` → **rc 2**,
     `unbound missing reason …new=46…`, `stale missing reason …mismatches=46…`,
     `display monitor controls: 2 rejected`.
   - **Drill RED reads (the AC table's Baseline column):** `sh tools/deadline.sh 300 bash $D/d7ar_drill.sh guard-lab $ROOT | tail -1`
     → `d7ar-drill: mutation guard-lab did not apply`, rc 3 (V17); same for `static-breach` (AC18 baseline).
3. No edits, **no commit**. `git status --porcelain` empty at milestone end.

Estimated 0 committed lines (the two extracted scripts live outside the repo).

### MS2 — GREEN part 1: the live guard (D1–D3; E1–E7 with E6b, E6c). ONE commit.

Text byte-for-byte from Appendix C1–C4:

- **E1–E3** `mk/lab.mk:62,63,70`: prefix `env -u AI_LIVE ` to the three `$(LAB_RUN) --entry $$…` lines (C1).
- **E4** `tools/lab_probe.py:44`: the comment line plus `return ["env", "-u", "AI_LIVE", ailang(), "run", …]` (C2).
- **E5** `tools/reach_probe.py:39–40`: hoist the optional flag into `vm`, one-line
  `cmd = ["env", "-u", "AI_LIVE", a.ailang, "run", "--quiet", *vm, "--caps", …, PROBE]` with the comment (C3)
  (the two-line form still fails rule A at the `--entry` line — V10 `M-reach-split`).
- **E6** `mk/ai.mk`, after `ai-test: ai-live-guard ai-settings`: the D2 block — comment,
  `AI_GUARD_S ?= 120`, `AI_GUARD_RUN_S ?= 60`, the `ai-live-guard-static` target under
  `$(SCRIPT_GATE) … $(AI_GUARD_S) '^ai-live-guard: ok \([1-9][0-9]* make/shell/CI files, [1-9][0-9]* test/tool scripts, launch builder, settings\)$$' -- sh tools/ai_live_guard.sh .`,
  and the `ci-fast: ai-live-guard-static` edge (C4).
- **E6b** `mk/ai.mk` `ai-live-guard` header: `ai-live-guard: import ai-live-guard-static`; the old first
  recipe line `@sh tools/ai_live_guard.sh .` is removed.
- **E6c** the mutant loop's guard run and the rule-E setup plus its two guard runs each go through
  `sh tools/deadline.sh $(AI_GUARD_RUN_S)` with the rc classified (0 / 1 / 124 / other; only rc 1 plus the
  `grep -qF "ai-live-guard: $$want"` line counts as caught) and the setup chain ends
  `|| { …setup … failed; exit 1; }` (C4).
- **E7** the D3 mutant row for the `$(LAB_RUN) --entry $$e sim/$$e.ail` shape, after the `_rogue2` row (C4).

Run pre-commit: **AC1, AC2, AC3, AC4, AC6, AC7**. Commit:

`git add mk/ai.mk mk/lab.mk tools/lab_probe.py tools/reach_probe.py` (named files only; never `git add -A`).
Message names row 7ar and D1–D3 and ends with `Co-Authored-By: Claude Haiku 5.5 <noreply@anthropic.com>`.

Run post-commit on the committed tree: **AC5, AC17, AC18, AC19, AC20** (the drills need the fixed lines
in place; they restore themselves — prove `git status --porcelain` empty after each).

Acceptance (commands and expected output verbatim from the design's AC table):

- **AC1** `sh tools/deadline.sh 120 sh tools/ai_live_guard.sh .` →
  `ai-live-guard: ok (98 make/shell/CI files, 549 test/tool scripts, launch builder, settings)`, rc 0.
- **AC2** `test "$(sh tools/deadline.sh 60 make -n ci-fast 2>/dev/null | grep -c '^sh tools/script_gate.sh ai-live-guard-static .* 120 .* -- sh tools/ai_live_guard.sh \.$')" -eq 1` → rc 0.
- **AC3** `sh tools/deadline.sh 200 make ai-live-guard-static` →
  `script-gate: ai-live-guard-static ok: ai-live-guard: ok (98 make/shell/CI files, 549 test/tool scripts, launch builder, settings) (rc 0, no SCRIPT ERROR, 6 s of 120 s)` (seconds vary), rc 0.
- **AC4** `sh tools/deadline.sh 900 make ai-live-guard > $D/alg.log 2>&1; echo rc=$?; grep -c '^guard mutant caught' $D/alg.log; grep -x 'guard mutant caught: mk/lab.mk (A mk/lab.mk)' $D/alg.log; tail -1 $D/alg.log` →
  `rc=0`; `25`; the lab.mk line; `guard: rule E reads git ls-files (…)`;
  `script-gate: ai-live-guard ok: ai settings: ok (9 passed, 0 failures; launch_default) …`; about 4 minutes (239 s at load 5.4, V25).
- **AC5** `for m in guard-lab guard-reach guard-labprobe; do sh tools/deadline.sh 300 bash $D/d7ar_drill.sh $m $ROOT | tail -1; done` →
  `d7ar-drill: guard-lab KILLED`, `… guard-reach KILLED`, `… guard-labprobe KILLED`.
- **AC6** `sh tools/deadline.sh 600 make lab-parity` → 4 `lab-parity: … (strict VM = interpreter)` lines
  and `lab-parity: 4 checks NOT on the strict VM …`, rc 0.
- **AC7** `AILANG=ailang sh tools/deadline.sh 120 python3 -I -c 'import sys; sys.path.insert(0, "tools"); import lab_probe as l; p = l.start("draws", 2000); print(p.args[:4]); print(l.finish(p)[0])'`
  and `sh tools/deadline.sh 120 python3 -I -c 'import sys, types; sys.path.insert(0, "tools"); import reach_probe as r; print(r.ail(types.SimpleNamespace(ailang="ailang"), "drawMain", {"seed": 1, "n": 0})[0])'` →
  `['env', '-u', 'AI_LIVE', 'ailang']` then `draws n=2000 accepted=91 first=1 mix=6578220370666750`; and `0.0`; both rc 0.
- **AC17** `sh tools/deadline.sh 120 bash $D/d7ar_drill.sh stall $ROOT` →
  `script-gate: ai-live-guard-static FAIL; timeout after 3 s (rc 142)…`;
  `d7ar-drill: stall before=0 control_seen=1 control_cleared=0 make_rc=2 secs=5 survivors=0` (secs below 30);
  `d7ar-drill: stall KILLED`, rc 0.
- **AC18** `sh tools/deadline.sh 400 bash $D/d7ar_drill.sh static-breach $ROOT` →
  `ai-live-guard: A mk/lab.mk:63: …`; `script-gate: ai-live-guard-static FAIL; rc 1, want 0; no summary line …`;
  `d7ar-drill: static-breach KILLED`, rc 0.
- **AC19** `sh tools/deadline.sh 120 bash $D/d7ar_drill.sh mutant-stall $ROOT` →
  `script-gate: ai-live-guard-static ok: …`;
  `guard mutant infrastructure failure: mk/ai.mk: the guard did not finish in 3 s (deadline, rc 124)`;
  `d7ar-drill: mutant-stall before=0 control_seen=1 control_cleared=0 make_rc=2 secs=14 survivors=0 caught=0` (secs below 60);
  `mutant-stall KILLED`, rc 0.
- **AC20** `sh tools/deadline.sh 120 bash $D/d7ar_drill.sh mutant-exit2 $ROOT` →
  `guard mutant infrastructure failure: mk/ai.mk: the guard exited 2, want 1:`;
  `… make_rc=2 secs=6 survivors=0 caught=0`; `mutant-exit2 KILLED`, rc 0.

### MS3 — GREEN part 2: the monitor controls (D4; E8–E12). ONE commit.

Text byte-for-byte from Appendix C5 (`mk/earth-link.mk`, the whole target after the edit) and C6 (the new
helper):

- **E8** `mk/earth-link.mk:26`: the 2 comment lines naming the tokens (`@N@`, `@2N@`, `@F1@`, `@F10@`).
- **E9** `mk/earth-link.mk:29`: the vacuous-run negative control (3 recipe lines; feeds the helper a
  synthetic `samples=0` log and requires the refusal `samples=0, fewer than …`).
- **E10** `mk/earth-link.mk:37`: the inline `grep` loop replaced by
  `if ! why=$$(sh tools/monitor_control_check.sh $$log.audit.log $$log/display_samples.ndjson "$$@"); then echo "display monitor controls: $$m $$why"; bad=$$((bad + 1)); return 0; fi; \`.
- **E11** `mk/earth-link.mk:40–43`: the four `ctl` lines with tokens — `frame=@F1@ clocks`,
  `frame=@F10@ course` (`failures=1` stays literal), `samples=@N@ .* new=@N@ .* failures=@N@`,
  `samples=@N@ .* mismatches=@N@ .* failures=@2N@`.
- **E12** new `tools/monitor_control_check.sh`, mode 100644, run with `sh`, byte-for-byte from Appendix C6.
  After writing: `shasum -a 256 tools/monitor_control_check.sh | cut -c1-16` = `aecd62112b67616a`;
  `sh -n tools/monitor_control_check.sh` rc 0. Shell script — **no `.uid`**.

Run pre-commit: **AC8, AC11, AC12**. Commit:

`git add mk/earth-link.mk tools/monitor_control_check.sh` (named files only). Message names row 7ar and
D4 and ends with `Co-Authored-By: Claude Haiku 5.5 <noreply@anthropic.com>`.

Run post-commit: **AC9, AC10**. Ordering matters: the drill's trap restores `tools/monitor_control_check.sh`
with `git checkout`, so the helper must be **tracked at HEAD** before AC9's `floor` mode deletes a line
from it.

Acceptance (verbatim from the design's AC table):

- **AC8** `sh tools/deadline.sh 590 make display-audit-monitor-controls > $D/mc.log 2>&1; echo rc=$?; grep '^display monitor' $D/mc.log` →
  `rc=0`; four `display monitor control <m>: rejected` lines; `display monitor controls: 4 rejected`.
- **AC9** `for m in unbound-partial stale-partial drop-row floor; do sh tools/deadline.sh 600 bash $D/d7ar_drill.sh $m $ROOT | tail -1; done` →
  `d7ar-drill: unbound-partial KILLED`, `stale-partial KILLED`, `drop-row KILLED`, `floor KILLED`
  (the partial modes also require the other three controls still rejected: `3 rejected`; `floor` reads
  `…not refused by the samples floor: sampled row 1 of … has 0 integer "frame" keys, want 1`).
- **AC10** `sh tools/deadline.sh 600 bash $D/d7ar_drill.sh cadence $ROOT | tail -1` →
  `d7ar-drill: cadence PASSED (samples=60)`.
- **AC11** `sh tools/deadline.sh 60 sh $D/d7ar_helper_cases.sh $ROOT` →
  nine `case …: ok` lines (vacuous, short, skew, nosummary, partial, accepted, keyorder, ambiguous,
  noframe), `d7ar helper cases: 0 wrong`, rc 0.
- **AC12** `git grep -nE '(new\|mismatches\|failures)=(4[0-9]\|9[0-9])\|frame=(1\|36) (clocks\|course)' -- mk Makefile tests tools; test $? -eq 1` → no output, rc 0.

### MS4 — evidence (no code commit)

Run and record each output in the sprint JSON's `notes`:

- **AC13** `for t in python-guard uid-guard script-gate-lint; do sh tools/deadline.sh 120 make $t || exit 1; done; git diff --check 36f4ab4c HEAD; sh -n tools/monitor_control_check.sh`
  (and `shellcheck tools/monitor_control_check.sh` where installed) →
  `python-guard: ok (25 allowlisted, …)`, `uid-guard: ok (470 .uid files)`, `script-gate-prereqs: ok …`;
  no diff-check output; rc 0.
- **AC14** `test "$(git diff --name-only 36f4ab4c HEAD -- . ':!design_docs' ':!.ailang' | tr '\n' ' ')" = "mk/ai.mk mk/earth-link.mk mk/lab.mk tools/lab_probe.py tools/monitor_control_check.sh tools/reach_probe.py "` → rc 0.
- **AC16** `git status --porcelain` → empty (after every drill, and finally).

The executor appends measured outputs to the JSON `notes`; the controller sets `passes`/`started`/`completed`.

## Controller steps (NOT executor steps)

- **AC15** — the GitHub fast tier on the PR, including `ai-live-guard-static` on Linux:
  `sh tools/deadline.sh 60 gh pr checks <PR>` → `fast tier … pass`. **The executor does not push.** This
  is the measurement the designer explicitly left unverified ("Not verified by the designer: the run on
  GitHub's Linux runner. The PR's own fast-tier run is that measurement").
- Confirm `git log --oneline 36f4ab4c..HEAD` shows exactly the two code commits (shapes V25/V20: MS2 =
  `mk/ai.mk mk/lab.mk tools/lab_probe.py tools/reach_probe.py`; MS3 = `mk/earth-link.mk
  tools/monitor_control_check.sh`) plus the planner's plan/JSON commit; re-run AC13/AC14/AC16; set
  `passes`/`started`/`completed` per milestone.
- After the cross-family evaluation passes and the merge: move the design doc to
  `design_docs/implemented/r1/`, update the README index, charter row 7ar and issue #392 (design
  Deliverables). The next nightly `rig/full` on main should not name `ai-live-guard` or
  `display-audit-monitor-controls` — that is the outcome, not a merge gate.

## Commit rules for the executor

- One commit per code milestone (MS2, MS3); MS1 and MS4 commit nothing.
- Stage **named files only**; never `git add -A`.
- `tools/monitor_control_check.sh` is a shell script: **no `.uid` file** (`.uid` is for Godot
  scripts/shaders only).
- Every commit message ends with `Co-Authored-By: Claude Haiku 5.5 <noreply@anthropic.com>`.
- Restore every drill mutation: the drills restore themselves via their `git checkout` trap and refuse
  (rc 3) if a mutation did not apply; prove `git status --porcelain` empty after each drill and at each
  milestone end (AC16).

## Pause points (stop; do not fix forward)

- `runtime/bin/ailang` ≠ v0.56.1 or Godot ≠ 4.7.2 → stop.
- An appendix sha256 prefix mismatches → re-extract once; still mismatched → stop, never retype.
- A pristine baseline differs from the Baseline column (the five A lines / rc 1; the four pinned hits;
  `2 rejected`; drill rc 3) → tree drift, stop.
- Any drill prints `SURVIVED`, or `git status --porcelain` is non-empty after a drill → stop; do not
  hand-edit the drill's mutations.
- AC1/AC3's `98/549` counts, AC13's `25 allowlisted` / `470 .uid files`, or AC4's `25` caught count
  differ → main moved under the sprint; stop — do not edit the expectations (the counts are main-plus-
  this-change: 98 = 97 + the newly tracked helper, V8).
- AC19/AC20 show `caught` ≠ 0, a survivor sleeper (`pgrep -f '^sleep 319[13]$'` non-empty), or
  `make_rc=124` → the bound or the rc classification is wrong; stop — never widen the catch to a
  non-1 rc, never bump `AI_GUARD_S`/`AI_GUARD_RUN_S` silently.
- `make ai-live-guard` runs far past 239 s (V25) without finishing → the 900 s deadline will fire;
  report the log, do not re-run with a longer deadline.
- The scope check AC14 fails on an extra file (e.g. a changelog fragment, a `.uid`, a `Makefile`
  edit) → stop; the design's Deliverables name E1–E12 only.

## Risks (from the design, with the executor's handling)

- **Static guard fails on Linux for portability** — AC15 is the measurement; the fix is in the guard's
  portability, never a removal from `ci-fast` (design Risks).
- **Fast tier grows ~8 s** (~1%): accepted (D2).
- **60 s per mutant-loop run too tight on a loaded host** — it fails by name as an infrastructure
  failure, never as a catch; 60 s = 7.5× the slowest measured scan (V24). Do not bump it silently.
- **120 s too tight on a slow runner** — fails loudly (`timeout after 120 s (rc 142)`); the fix would be
  a measured new `AI_GUARD_S`, not gate removal.
- **The gate's Godot wording on timeout** (`tools/script_gate.sh`'s fixed hint) is wrong for this shell
  guard — follow-up F3, not this row; the target name and `timeout after N s (rc 142)` are unambiguous.
- **Drill leftovers** — the drills restore with `git checkout` on exit and refuse rc 3 on a
  non-applying mutation; AC16 checks.

## Plan verification (planner, 2026-11-13)

HEAD `5572504b` (r2 design commit) on branch `mission/stapledon-iter92-7ar`; merge-base with
`origin/main` = `36f4ab4c` = `origin/main` = the design's measured base; `git diff --name-only
36f4ab4c..HEAD` = the design doc alone, so every V-number applies verbatim; `git status --porcelain`
empty. Appendix fences extracted read-only by piping: A sha256 `e55b79e3e52d828b…` ✓, B
`af21a44e875e5c88…` ✓, C6 helper `aecd62112b67616a…` ✓ — all match the doc's pinned prefixes. Edit
anchors verified verbatim: `mk/lab.mk:62,63,70` the three `$(LAB_RUN) --entry $$…` lines;
`tools/lab_probe.py:44` `return [ailang(), "run", …]`; `tools/reach_probe.py:39–40` the two-line `cmd`;
`mk/ai.mk:445` `ai-test:`, `:449–450` `ai-live-guard: import` + `@sh tools/ai_live_guard.sh .`, the
`_rogue2` row and `Makefile include` row, the mutant-loop guard run and the rule-E chain exactly as
E6c's "before"; `mk/earth-link.mk:29,37,40–43` the inline grep loop and the four pinned `ctl` lines.
Environment: `runtime/bin/ailang` v0.56.1; Godot 4.7.2.stable; `.godot` imported; `tools/deadline.sh`
present; `/tmp` writes refused in the planner sandbox (7am D1 precedent). The planner ran no `make`
target and no Godot (sandbox hard rule); every number above is a V-row citation.
