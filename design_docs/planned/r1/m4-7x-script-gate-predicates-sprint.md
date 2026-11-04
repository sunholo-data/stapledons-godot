# Sprint plan: R1-M4-JOURNEY row 7x, script-gate predicates

**Status:** Planned, mission iteration 69 planner, 2026-11-04, HEAD `78f390c041fd02461ad758492813c2354fb51363` (= `origin/main`, same hash; `git status --porcelain` lists only the untracked approved design doc — planner-run, below). One feature `M4.6sR3_7x_SCRIPT_GATE_PREDICATES` under the approved sprint `R1-M4-JOURNEY` (D-22/D-66, D-88 A).
**Design:** [m4-7x-script-gate-predicates.md](m4-7x-script-gate-predicates.md) — the contract, read in full: W1–W6 (every file given in full or diff-ready), the **binding quorum round-2 amendments A1/A2** (they override W1, W3 and W4 wherever they conflict; quote the round as "r2 BLOCKED 1/3 (+1 salvaged), fixes applied under the carve-out", never "quorum passed"), the Acceptance criteria AC1–AC15 plus AC16–AC18, the Verification log (V1–V35) and the Risks.
**Scope:** test and build hygiene only. One shared pass predicate `$(SCRIPT_GATE)` for Godot `--script` gates, the ratchet lint `make script-gate-lint`, the wiring into `test`/`ci-fast`, the `make sim` migration with its RED-then-GREEN drill, four more gate migrations, and the counted summaries in two test files. No sweeping rewrite of the 232 remaining gates (follow-up batches B2–B8, design W6). No design-repo, physics, sim, shader, scene or player-visible change (pillar net 0, D-88 A go).
**Budget:** about **300 hand-written LOC plus a generated 235-line baseline** (design header, measured on the revision-1 scratch clone, V29): `tools/script_gate.sh` 39 (+~12 for the A2 supervisor if inlined), `tools/script_gate_lint.sh` 120, `tools/test_script_gate.sh` 55 (+2 A2 cases), `mk/script-gates.mk` 43, `tests/fixtures/script_gate/` 6 files 47 lines, `Makefile` 6 hunks +14/−5, `tests/test_sim_bridge.gd` +6/−3, `tests/test_galaxy_map.gd` +4/−2. Active work about 2–3 h for a mid-tier model (design §Sub-milestones); `make sim` wall time budgeted separately (V30: the unchanged AILANG steps took 35 min at load 4–7, `ailang test --package .` alone 29 min 17 s; the migrated Godot steps ~2.5 min). Pinned AILANG v0.56.1 (`runtime/bin`), Godot 4.7.2, `perl` (V13; present at `/usr/bin/perl` — planner-run).
**Ownership:** every step here is executor-runnable — all drills are headless and need no GPU window (contrast 7l). `runtime/bin/ailang` is absent in this clone (planner-run `ls`), so first refresh the pinned runtime (`make runtime`) and follow the AC preface: `export PATH="$PWD/runtime/bin:$PATH"` after `make deps import`. The controller alone owns git writes, the PR, the landing comments on the four attended PRs (design Open questions), and AC13 (`gh`, CI — the sandbox has no network, planner-run below). The evaluator reruns every AC first-hand, generator ≠ judge.

## Reality check against HEAD

Every anchor re-measured at `78f390c0` in this clone, planner-run, 2026-11-04 (commands shown with their outputs):

- `git rev-parse HEAD` → `78f390c041fd02461ad758492813c2354fb51363`; `git rev-parse origin/main` → identical. `git log -1 --format='%h %s'` → `78f390c0 Merge pull request #391 from sunholo-data/mission/stapledon-iter68-7w-land`. `git status --porcelain` → `?? design_docs/planned/r1/m4-7x-script-gate-predicates.md` and nothing else.
- `sed -n '376p' Makefile` → `	$(GODOT_SIM) --headless --path . --script tests/test_sim_bridge.gd` (the bare line, V6/M3 premise; still bare here). `sed -n '386p;294p;835p;863p' Makefile` → the bare `ui`, `area-test`, `test-bright-audit`, `star-catalogue-test` recipe lines exactly as W5's diff context shows them.
- `sed -n '372,383p' Makefile` → the `sim` and `bh-hud-test` recipes byte-matching the doc's verbatim block (V26).
- `sed -n '1078p' Makefile` → `include mk/navigation-usability.mk`. `grep -n 'include'` over `Makefile mk/*.mk` → 21 directives, all naming `mk/<name>.mk` (19 in `Makefile` at lines 30–40, 1073–1078, 1307–1308; 2 in `mk/worlds.mk` at 5–6), and 21 files from both `ls mk/*.mk` and `git ls-files -co --exclude-standard 'mk/*.mk'` (V27's 22 makefiles = `Makefile` + these 21).
- `grep -c -- '--script' Makefile` → 122; same over `mk/*.mk` → 113; total 235 recipe lines with `--script` (V7). The 237-occurrence form is continuation-aware (V8; the 3-occurrence `audio-silent-guard` printf fixture at `Makefile:1049` is the difference).
- `grep -n 'alarm' Makefile mk/*.mk` → 7 perl-alarm lines in 6 targets: `mk/m5.mk:97,103,123`, `mk/planet-presentation.mk:4,21,28`, `mk/star-surfaces.mk:20` — the count A1 restates ("7 alarm lines (6 targets)").
- New files all absent (`ls`): `tools/script_gate.sh`, `tools/script_gate_lint.sh`, `tools/test_script_gate.sh`, `tools/script-gate-baseline.txt`, `mk/script-gates.mk`, `tests/fixtures/script_gate/`. `grep -n 'SCRIPT_GATE\|script-gate' Makefile mk/*.mk` → no hits (no name clash).
- Old summaries still uncounted: `grep -c 'print("sim bridge: %d failures" % failures)' tests/test_sim_bridge.gd` → 1; `grep -c 'print("galaxy map: %d failures" % failures)' tests/test_galaxy_map.gd` → 1.
- AC9's RED state: `for t in test ci-fast; do echo "$t: $(make -pn 2>/dev/null | grep -E "^$t:" | tr ' ' '\n' | grep -E '^script-gate-(lint|selftest|drill)$' | sort -u | tr '\n' ' ')"; done` → `test: ` and `ci-fast: ` (empty). `SCRATCH := .godot/tmp` at `Makefile:13`.
- Tools present: `which perl shellcheck godot` → `/usr/bin/perl`, `/opt/homebrew/bin/shellcheck`, `/opt/homebrew/bin/godot` (AC10's shellcheck skip is not needed on this machine; AC10 records it if absent elsewhere). `make -pn` on `ci-fast` keeps Godot out (ci.yml installs it only under `inputs.full`, V12; planner-run `grep -n 'inputs.full' .github/workflows/ci.yml` → lines 7, 17, 20).
- **Network absent in this sandbox:** `gh pr view 380 …` → `tls: failed to verify certificate: x509: OSStatus -26276`; `git ls-remote origin HEAD` fails. The four attended PRs' hunk regions are therefore cited from the design's V11 (2026-11-04), not re-measured; this matches the sprint JSON's recorded limitation (finding F3 there). Controller re-checks the PR set at kickoff with `gh` or `git ls-remote refs/pull/<n>/head` (F3's fallback).

**No design premise proved false on this tree.** The plan's counts are the doc's expected values at `78f390c0`; HEAD is that base, so no recount is needed. The relations the AC preface states must still hold at execution: pre-migration rows = post + 5, and lint ok.

## Sequencing note (dependency order and the two interim states)

The mission orders the milestones helper → lint → wiring → sim → other gates → drills. Two consequences are engineered deliberately, both using the design's own mechanisms:

1. **The baseline is generated before any migration lands**, so at M2 it holds **237 rows (pin 237)** — the interim state the design's S1 anticipates ("pin temporarily equal to the generated count"). M4's migration deletes the `sim<TAB>tests/test_sim_bridge.gd` row (pin 236); M5's four migrations delete their rows (pin 232). That is the ratchet's intended operation (W2: "a migration deletes its row … lowers SCRIPT_GATE_BASELINE_ROWS with it"), and it lands the final `mk/script-gates.mk` text exactly as W3 writes it. AC6's doc-literal expected line (`237 --script invocations: 5 through $(SCRIPT_GATE), 232 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned`, V29) is therefore asserted as the **final form at M5/M6**; M2/M3 assert and record the interim forms (`0 through $(SCRIPT_GATE), 237 on the baseline; 21 includes …; 22 makefiles scanned` at M2 before the include exists, rising to `22 includes; 23 makefiles` once M3's include and file exist).
2. **Some AC literal forms need the make targets, which M3 creates.** `script-gate-lint`, `script-gate-selftest`, `script-gate-drill`, `script-gate-inventory` are defined in `mk/script-gates.mk` (W3) and included at M3. So M2 validates the lint **directly** (`SCRIPT_GATE_BASELINE_ROWS=<n> sh tools/script_gate_lint.sh` — the substance of AC6, AC7(c), AC14, AC15), and the **make-invocable forms** (AC6, AC7(a), AC7(b), AC14(a),(b) with make's rc=2 framing) run at the top of M3 against the just-created targets, then again where stated. Direct sh runs exit 1 where the make target exits 2; the flagged-row lines are identical.

Two pre-amendment AC texts are superseded by the binding round-2 amendments and are reconciled, not silently edited:

- **Case counts +2 (A2):** the A2 drill cases `stub-ignore-alrm` and `stub-orphan-child` raise the stub total to 12 (AC16: "the cases total goes up by 2 (12 stub)"). So AC1's footer reads `test-script-gate: ok (12 cases: 12 stub, 0 Godot)` and AC2's `… (18 cases: 12 stub, 6 Godot)`; AC13's CI-log grep keeps its first alternative (`237 --script invocations: 5 through`) and its second alternative must match the 12-stub footer at PR time — record the adjusted pattern in the sprint JSON notes.
- **AC8's no-alarm sed mutant targets the W1 exec-alarm line that A2 deletes.** With the supervisor in place, that sed matches nothing and the mutant would pass — the half is stale by construction. AC17 is the A2-era discharge of the same check (mutate a scratch copy's supervisor back to `perl -e 'alarm shift; exec @ARGV'`; it must fail `stub-ignore-alrm`). AC8's first half (the rc-only mutant) is unchanged: under the 12-case selftest it still exits 1 with the four counted FAILs (plus two uncounted FAILs from the A2 cases and a ~60 s wall time inside the 120 s outer deadline; record the actual footer in notes).

## Milestones (test-first, in dependency order)

### M1 — the helper and the stub drills (AC1, AC8; A2 discharged by AC16, AC17)

**Files (~100–120 LOC):** `tools/script_gate.sh` (W1's text **with the A2 supervisor**: replace the exec-only alarm line with the verbatim perl supervisor from A2 — inline it; only if a separate `tools/script_gate_supervise.pl` is used must AC11's scope regex gain it and this plan's file list widen, so prefer inline — V35 is the measured prototype, rc 142 preserved), `tools/test_script_gate.sh` (W4's text **with A1/A2**: `tmp=${SCRIPT_GATE_TMP:-.godot/tmp/script-gate}`; new cases `stub-ignore-alrm` and `stub-orphan-child` with their stated exit 1 / `timeout` reason / ≤6 s ceiling / `pgrep -f 'sleep 977'` zero plus its `sleep 978` known-positive control), `tests/fixtures/script_gate/{good,parse_error,runtime_error,no_summary}.gd.txt` (W4's table, real tabs; inert until the --godot half runs in M6).

**Test-first steps:**
1. Write `tools/test_script_gate.sh` first. RED: `sh tools/test_script_gate.sh` with no helper — twelve cases FAIL, `FAIL 12 of 12 cases`; record rc in the sprint JSON notes.
2. Write `tools/script_gate.sh` (supervisor per A2, comment must state the setsid/setpgrp limit, A2). GREEN: AC1 below.
3. AC8 rc-only mutant; AC17 exec-alarm mutant (the A2 discharge of AC8's stale half — see the sequencing note); AC16's `pgrep` count.

**Acceptance (exact commands from the doc):**

- **AC1:** `make script-gate-selftest; echo rc=$?` — runs after M3 creates the target; at M1 the same content is exercised directly as `sh tools/test_script_gate.sh` with the same exit contract (rc 0). Expected (post-A2 form, see the sequencing note): twelve `test-script-gate: ok   stub-…` lines, then `test-script-gate: ok (12 cases: 12 stub, 0 Godot)`, `rc=0` (V17 for the 10-case form; AC16 for the +2).
- **AC8 (first half):** `printf '#!/bin/sh\nwhile [ "$1" != -- ]; do shift; done; shift\nexec env "$@"\n' > .godot/tmp/7x-rc-only.sh; SCRIPT_GATE_SH=.godot/tmp/7x-rc-only.sh sh tools/test_script_gate.sh > .godot/tmp/7x-m1.out 2>&1; echo rc=$?; grep -cE 'FAIL stub-(parse\|hang\|nosummary\|zero): exit 0' .godot/tmp/7x-m1.out` — Expected: `rc=1`, `4` (V18). The doc's second half (the no-alarm sed mutant expecting `FAIL stub-hang: exit 1 in 30 s`) is superseded by A2/AC17 (sequencing note).
- **AC16:** `make script-gate-selftest 2>&1 \| grep -E 'stub-ignore-alrm\|stub-orphan-child\|cases'; pgrep -f 'sleep 977' \| wc -l` — Expected (doc): `ok   stub-ignore-alrm (exit 1 in [2-6] s: timeout …)`, `ok   stub-orphan-child (exit 1 …: timeout …)`, the cases total up by 2 (12 stub), then `0`. At M1 run the grep half against the direct `sh` output; the literal `make` form re-runs at M3.
- **AC17:** replace the supervisor call in a scratch copy of `tools/script_gate.sh` with `perl -e 'alarm shift; exec @ARGV'` and run `SCRIPT_GATE_SH=<copy> sh tools/test_script_gate.sh` — Expected (doc): `rc` non-zero, and `FAIL stub-ignore-alrm` appears (the case overruns its wall-time ceiling or exits 0).

**Estimate:** ~100–120 LOC, ~40 min (design S1 partially; W1/W4 given in full, V17–V19 measured).
**Pause point:** if the supervisor cannot bound the TERM/ALRM-ignoring stub within ceiling on this machine (V35 measured macOS only; Linux is AC13), stop — do not weaken the contract or raise ceilings; report as an infra finding. Any leftover `sleep 977`/`sleep 978` or Godot child after the drills is investigated, never accepted (AC16's count must be 0).

### M2 — the ratchet lint, the baseline, include closure, per-occurrence classes (AC6, AC7, AC14, AC15)

**Files (~140 LOC + generated):** `tests/fixtures/script_gate/lint_negative.mk.txt` and `tests/fixtures/script_gate/lint_negative_baseline.txt` (W4, verbatim — `.txt` so they are not makefiles and cannot trip the every-makefile check), `tools/script_gate_lint.sh` (W2, verbatim), `tools/script-gate-baseline.txt` (generated with W2's command, interim 237 rows + 3 header lines).

**Test-first steps:**
1. Write the two lint fixtures first. RED: the AC15 inventory command with the lint absent (command not found) — record.
2. Write `tools/script_gate_lint.sh`; run AC15's inventory on the fixture: must print **exactly the doc's six rows** — `gated-ok tests/x.gd gated`, `bare-new tests/y.gd ungated`, `baselined tests/z.gd ungated`, `mixed tests/m1.gd gated`, **`mixed tests/m2.gd ungated`**, `quoted-separators tests/q.gd gated` (V28; the round-0 lint wrongly marked `m2` gated).
3. Generate the baseline (W2's command block, verbatim) and set the interim count; run the lint directly with the completeness known-positive (`got` == `grep -o --script` count, V29's control).
4. AC7(c) stale-row, AC14(a),(b) direct forms; record direct-run rc 1s.

**Acceptance (exact commands from the doc):**

- **AC15:** `SCRIPT_GATE_FILES=tests/fixtures/script_gate/lint_negative.mk.txt SCRIPT_GATE_BASELINE_ROWS=0 sh tools/script_gate_lint.sh --inventory \| cut -f2-4; grep -c 'not on the baseline: mixed tests/m2.gd$' .godot/tmp/script-gate/lint-negative.log` — Expected: exactly the six rows above (tab-separated); then `1` (V28). (The lint-negative.log half runs inside `make script-gate-lint`'s embedded control; at M2 run the fixture directly with `SCRIPT_GATE_FILES=…lint_negative.mk.txt SCRIPT_GATE_BASELINE=…lint_negative_baseline.txt SCRIPT_GATE_BASELINE_ROWS=2 SCRIPT_GATE_ALL_MAKEFILES="tests/fixtures/script_gate/lint_negative.mk.txt tools/stray.mk"` and assert the same counts — 2 unguarded incl. `mixed tests/m2.gd`, 1 stale, 3 include-outside, 1 not-scanned, V28.)
- **AC14 (direct form):** (a) `printf 'include ../outside.mk\n' > mk/zz-inc.mk; …` and (b) `mkdir -p tools/zz && printf 'a:\n\ttrue\n' > tools/zz/stray.mk; …` with the direct lint runs (the doc's make commands are quoted in M3 where the target exists). Expected lines (doc): `script-gate-lint: include outside the scanned set (mk/*.mk): mk/zz-inc.mk:1 ../outside.mk` plus `script-gate-lint: mk/zz-inc.mk is not included by any scanned makefile` (a); `script-gate-lint: makefile not scanned: tools/zz/stray.mk (add it to the scanned set or move it under mk/)` (b); direct rc 1. Fixtures removed afterwards (the doc's `rm mk/zz-inc.mk`, `rm -r tools/zz`).
- **AC7(c) (direct):** `cp tools/script-gate-baseline.txt .godot/tmp/7x-b.txt; printf 'sim\ttests/test_sim_bridge.gd\tx\n' >> .godot/tmp/7x-b.txt; SCRIPT_GATE_BASELINE=.godot/tmp/7x-b.txt SCRIPT_GATE_BASELINE_ROWS=238 sh tools/script_gate_lint.sh; echo rc=$?` — Expected: the doc's `stale baseline row (no longer unguarded): delete it and lower SCRIPT_GATE_BASELINE_ROWS: sim tests/test_sim_bridge.gd` only once the `sim` row is no longer live-unguarded — **so (c) runs in final form after M4**. At M2 run the same shape with a self-appended bogus row (e.g. `zz<TAB>tests/zz.gd`) and expect `stale baseline row …: zz tests/zz.gd`, `rc=1` — the substance; the doc-literal invocation (rows 233) holds after M5 (V31).
- **AC6 (interim, direct):** `SCRIPT_GATE_BASELINE_ROWS=237 sh tools/script_gate_lint.sh; echo rc=$?` — Expected interim: `script-gate-lint: ok (237 --script invocations: 0 through $(SCRIPT_GATE), 237 on the baseline; 21 includes, all in mk/*.mk; 22 makefiles scanned)`, `rc=0`. The doc-literal line (5 through, 232 rows, 22 includes, 23 makefiles; V29) is the M5/M6 assertion.

**Estimate:** ~140 LOC + the generated 235-line file (3 headers + 232 rows at final; V29), ~50 min. Lint is POSIX sh + awk glue — no Python, same class as `tools/audio_silent_guard.sh` and `lint-precision` (design §Language; CLAUDE.md "Python"; V12).
**Pause point:** if the completeness control mismatches (`the inventory found … and grep finds …`), or the live inventory shows any row outside the doc's 237-occurrence baseline shape (base moved), stop and recount against the live tree — never hand-edit the baseline to make it fit.

### M3 — wiring: `mk/script-gates.mk` and the one `include` (AC9)

**Files (~45 LOC):** `mk/script-gates.mk` (W3's text **with A1/A2 applied**: `script-gate-selftest` passes `SCRIPT_GATE_TMP=$(SCRATCH)/script-gate/selftest`, `script-gate-drill` passes `SCRIPT_GATE_TMP=$(SCRATCH)/script-gate/drill` — disjoint roots, V22/A1 — and both targets wrap `tools/test_script_gate.sh` in the same supervisor with a ceiling, 120 s stubs / 600 s `--godot`, A2; interim `SCRIPT_GATE_BASELINE_ROWS := 237`), `Makefile` one hunk: `include mk/script-gates.mk` directly after `include mk/navigation-usability.mk` (`Makefile:1078`, W3; verified above; no open-PR hunk within 25 lines, V11).

**Test-first steps:**
1. RED verified already (reality check): `test:`/`ci-fast:` show no script-gate deps. Land `mk/script-gates.mk`, then the include; AC9.
2. Re-run the make forms now reachable: AC6 (interim counts: `22 includes, all in mk/*.mk; 23 makefiles scanned`, pin 237), AC7(a), AC7(b) (interim wording: `the baseline has 237 rows but SCRIPT_GATE_BASELINE_ROWS is 231: the pin moves with the rows, and only down` + `make: *** [script-gate-lint] Error 1`), AC14(a),(b) (now `rc=2`), and AC1/AC16's literal `make script-gate-selftest` form. The recipe's embedded negative control and pin control run on every invocation (W3) — that is the doc's AC14(c) control, expected counts `3` and `1` in `.godot/tmp/script-gate/lint-negative.log` (V31).

**Acceptance (exact command from the doc):**
`for t in test ci-fast; do echo "$t: $(make -pn 2>/dev/null \| grep -E "^$t:" \| tr ' ' '\n' \| grep -E '^script-gate-(lint\|selftest\|drill)$' \| sort -u \| tr '\n' ' ')"; done` — Expected: `test: script-gate-drill script-gate-lint script-gate-selftest`, `ci-fast: script-gate-lint script-gate-selftest` (V19).

**Estimate:** ~45 LOC, ~25 min.
**Pause point:** if `make -pn` does not show the three deps joined onto `test`/`ci-fast` (the W3 precedent is `mk/star-surfaces.mk:14–15`, V12), or a freshly merged PR moved the include site, pause for rebase/recheck before any `Makefile` edit elsewhere.

### M4 — `make sim` migration, RED-then-GREEN drill first (AC3, AC4, AC12)

**Files (~35 LOC):** `Makefile` hunk @@ -373 (the doc's diff-ready block: `sim` keeps `check`/`test`; its old line 376 becomes `@$(MAKE) --no-print-directory sim-bridge AILANG=$(AILANG) GODOT=$(GODOT)`; new `sim-bridge` target with `SIM_BRIDGE_SCRIPT ?=` and `SIM_BRIDGE_LOG ?=` hooks, W5), `tests/test_sim_bridge.gd` +6/−3 (counted summary, the doc's verbatim edit), baseline: delete the `sim<TAB>tests/test_sim_bridge.gd` row and pin 237 → 236 in `mk/script-gates.mk` (same logical step: the stale-row lint bites otherwise, W2).

**Test-first steps:**
1. **AC3 RED first, before any M4 edit, recorded in the sprint JSON.** The doc dates RED "on the base commit before any edit"; the mission orders it at the head of M4, which is sound: the RED command drives raw Godot on a scratch script and reads nothing that M1–M3 added (they touch no recipe and no Godot behavior), so it measures the same premise V3 measured at base. Verbatim:
   `mkdir -p .godot/tmp/script-gate && printf 'extends SceneTree\nfunc _init() -> void:\n\tvar a: int = undefined_name_7x\n\tquit(0)\n' > .godot/tmp/script-gate/p.gd; AILANG_BIN="$(command -v ailang)" perl -e 'alarm shift; exec @ARGV' 120 godot --headless --path . --script .godot/tmp/script-gate/p.gd > .godot/tmp/7x-red.log 2>&1; echo rc=$?; grep -c 'SCRIPT ERROR' .godot/tmp/7x-red.log` — Expected RED (doc): `rc=0`, `1` (the command `make sim` ran passes a script that never parsed; V3).
2. GREEN: apply the sim hunk and the `tests/test_sim_bridge.gd` edit, then the doc's GREEN: `make sim-bridge SIM_BRIDGE_SCRIPT=.godot/tmp/script-gate/p.gd SIM_BRIDGE_LOG=.godot/tmp/7x-green.log; echo rc=$?` — Expected (doc): `script-gate: sim-bridge FAIL; 1 SCRIPT ERROR line(s) (Godot exits 0 on a parse error); no summary line matching …`, `rc=2` (V19).
3. AC12 greps; start **AC4 in the background early and poll in a bounded loop** (design §Sub-milestones; an outer alarm around `make` kills make, not children — V30/Risks).
4. Ratchet step: delete the baseline row, pin 236, re-run `make script-gate-lint` (interim ok: `1 through $(SCRIPT_GATE), 236 on the baseline`), then AC7(c)'s doc-literal form (`SCRIPT_GATE_BASELINE_ROWS=238` on the appended-`sim`-row copy — now that `sim` is no longer live-unguarded, expect the doc's stale line and rc 1).

**Acceptance (exact commands from the doc):**

- **AC4:** `make sim AILANG=$PWD/runtime/bin/ailang > .godot/tmp/7x-ac4.out 2>&1; echo rc=$?; grep -E '^script-gate: sim-bridge\|^bh-hud: \|^bh-hud-test: \|^lens-assets: ' .godot/tmp/7x-ac4.out` — Expected (doc): `rc=0`, then in this order: `script-gate: sim-bridge ok: sim bridge: 1[0-9][0-9] passed, 0 failures (rc 0, no SCRIPT ERROR, … s of 900 s)` (110 measured, V19/V30); `lens-assets: tables match data/lens/SHA256SUMS`; `bh-hud: 64 passed, 0 failures`; `bh-hud-test: no hand-written sqrt(1 - 1/r) in demos ui sky bridge interior` (V26, V30). Before the sim-bridge line, `ailang check --package sim` (`✓ 161 files checked, all passed!`) and `ailang test --package .` run unchanged (slow on a loaded rig, V30).
- **AC12:** `grep -c 'print("sim bridge: %d passed, %d failures" % \[passes, failures\])' tests/test_sim_bridge.gd; grep -c 'print("galaxy map: %d passed, %d failures" % \[passes, failures\])' tests/test_galaxy_map.gd; grep -c 'if not ok: failures += 1' tests/test_sim_bridge.gd` — Expected: `1`, `1`, `0`. (The galaxy-map edit lands in M5; run AC12 after M5 or expect the interim middle `0` and record it.)

**Estimate:** ~35 LOC, ~20 min active; **wall ~40 min** dominated by AC4's unchanged AILANG steps (29 min 17 s for `ailang test --package .` at load 4–7, V30) + ~2.5 min Godot (sim-bridge 119 s, bh-hud ~20 s, V30).
**Pause point:** RED is recorded before any edit; if RED does not reproduce (`rc≠0` or no `SCRIPT ERROR`), Godot's premise changed — stop and revisit row 7x, per the drill's own note. If `git diff` on `Makefile` shows anything but the one hunk, stop.

### M5 — the four other gate migrations (AC5; AC6/AC7(b) final forms)

**Files (~15 LOC + baseline −4 rows):** `Makefile` hunks @@ -291 (`area-test`), @@ -383 (`ui`), @@ -832 (`test-bright-audit`), @@ -860 (`star-catalogue-test`) — the doc's diff-ready lines, verbatim; `tests/test_galaxy_map.gd` +4/−2 (counted summary, verbatim); delete the four baseline rows; pin 236 → **232** (the final W3 text). Apply with `git apply` of the doc's block or by hand; offsets verified above at 294/386/835/863.

**Test-first steps:** each gate's new shape exists only after its hunk — pre-state RED is the reality check (bare lines at those lines today). After all four: AC5; then the doc-literal **AC6** and **AC7(b)** re-runs (final counts hold now).

**Acceptance (exact commands from the doc):**

- **AC5:** `make ui area-test test-bright-audit star-catalogue-test 2>&1 \| grep '^script-gate:'` — Expected (doc): exactly 4 lines: `ui ok: galaxy map: 205 passed, 0 failures`, `area-test ok: 80 passed, 0 failed`, `test-bright-audit ok: test_bright_audit: 16 passed, 0 failed`, `star-catalogue-test ok: test_star_catalogue: 40 passed, 0 failed` (V19; **counts may only grow** — a lower count is a failure, not a recount).
- **AC6 (final, doc-literal):** `make script-gate-lint; echo rc=$?` — Expected (doc): `script-gate-lint: ok (237 --script invocations: 5 through $(SCRIPT_GATE), 232 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`, `rc=0` (V29).
- **AC7(b) (final, doc-literal):** `make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=231 2>&1 \| tail -2` — Expected (doc): `the baseline has 232 rows but SCRIPT_GATE_BASELINE_ROWS is 231: the pin moves with the rows, and only down` and `make: *** [script-gate-lint] Error 1`.
- **AC7(a) re-run (make form):** `printf 'x7x:\n\t$(GODOT) --headless --path . --script tests/x7x.gd\n' > mk/zz-7x-probe.mk; make script-gate-lint > .godot/tmp/7x-ac7.out 2>&1; echo rc=$?; grep -c 'not on the baseline: x7x tests/x7x.gd' .godot/tmp/7x-ac7.out; rm mk/zz-7x-probe.mk` — Expected (doc): `rc=2`, `1`; the log also says `mk/zz-7x-probe.mk is not included by any scanned makefile` (V31).

**Estimate:** ~15 LOC, ~25 min (gates measure 6 s/16 s/1 s/3 s, V9/V10).
**Pause point:** if any migrated gate's counted pass number fell below the doc's (205/80/16/40), or #379/#380/#373 merged and moved a hunk, pause — re-measure the base, never edit around it silently.

### M6 — Godot drills, policy gates, scope (AC2, AC10, AC11; AC18; AC14(c) evidence)

**Files:** none new (0 LOC). **Acceptance (exact commands from the doc):**

- **AC2:** `s=$(date +%s); make script-gate-drill > .godot/tmp/7x-ac2.out 2>&1; echo rc=$? secs=$(( $(date +%s)-s )); grep -E 'raw-parse-rc0\|godot-hang\|make-sim-parse\|cases' .godot/tmp/7x-ac2.out` — Expected (doc, post-A2 counts per the sequencing note): `rc=0`, secs under 120; `ok   raw-parse-rc0 (exit 0 …: SCRIPT ERROR: Parse Error)`, `ok   godot-hang (exit 1 in 1[0-9] s: timeout after 10 s (rc 142))`, `ok   make-sim-parse (exit 2 …)`, `test-script-gate: ok (18 cases: 12 stub, 6 Godot)` (V19: 14 s).
- **AC18:** `make -j2 script-gate-selftest script-gate-drill > .godot/tmp/7x-ac18.out 2>&1; echo rc=$?; ls -d .godot/tmp/script-gate/selftest .godot/tmp/script-gate/drill` (doc writes `$(SCRATCH)` expanded to its value, `.godot/tmp` — verified `SCRATCH := .godot/tmp` at `Makefile:13`) — Expected (doc): `rc=0`, both directories exist. V34 is the premise (nothing runs `test`/`ci-fast` with `-j` today; planner-run grep not repeated — V34); A1 makes it safe anyway.
- **AC10:** `make uid-guard python-guard audio-silent-guard lint-precision && git diff --check origin/main && shellcheck -s sh tools/script_gate.sh tools/script_gate_lint.sh tools/test_script_gate.sh && echo gates-ok` — Expected (doc): `gates-ok` (shellcheck verified present at `/opt/homebrew/bin/shellcheck`, planner-run; if absent elsewhere, record and skip only that part).
- **AC11:** `git diff --name-only origin/main \| grep -cvxE 'Makefile\|mk/script-gates\.mk\|tools/script_gate\.sh\|tools/script_gate_lint\.sh\|tools/test_script_gate\.sh\|tools/script-gate-baseline\.txt\|tests/fixtures/script_gate/[a-z_]+\.(gd\.txt\|mk\.txt\|txt)\|tests/test_sim_bridge\.gd\|tests/test_galaxy_map\.gd\|design_docs/planned/r1/m4-7x-script-gate-predicates.*\.md\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'; git diff --name-only origin/main -- mk/sound.mk mk/deck-layout.mk mk/earth-link.mk mk/m45.mk audio data/audio assets/audio ui/earth_feed.gd data/ui/comms_feed.json \| wc -l; git diff origin/main -- Makefile \| grep -c '^@@'` — Expected (doc): `0`, `0`, `6` (the six W5 hunks; V25, V29). If M1 used a separate `tools/script_gate_supervise.pl`, its filename must be added to AC11's allowed regex (A2) and to the sprint JSON notes before AC11 runs.
- **AC14(c) evidence (from AC6's run):** `grep -c '^script-gate-lint: include outside' .godot/tmp/script-gate/lint-negative.log; grep -c '^script-gate-lint: makefile not scanned: tools/stray.mk ' .godot/tmp/script-gate/lint-negative.log` — Expected (doc): `3`, `1` (V31).
- **Close-out:** append the dated row-7x note (RED/GREEN outputs, AC table results, interim→final pin sequence) to this feature's `notes` in the sprint JSON; leave `passes: false` for the evaluator ("No feature marks passes=true on an AC whose command has not run" is the sprint JSON's own F4 discipline).

**Estimate:** 0 LOC, ~25 min (AC2 measured 14 s, V19; the rest are greps and the four policy gates).
**Pause point:** any survivor from `pgrep` checks, a missing drill directory, or an AC11 count ≠ `0 0 6` → stop; the drill leftovers and the scope list are the release boundary, not a nudge.

## Conflict surface

Four attended draft PRs (design V11, 2026-11-04; network is down in this sandbox so the controller re-checks at kickoff — reality check):

| PR | Touches (V11) | Distance to this sprint |
|---|---|---|
| #373 | `Makefile` hunks at old lines 10–27 and 225–233; `mk/m45.mk` | ≥25 lines from every edit here |
| #380 | `Makefile` 251–263 | ≥25 lines |
| #379 | `Makefile` 485–494; `mk/deck-layout.mk`; `mk/earth-link.mk` | ≥25 lines |
| #384 | `mk/earth-link.mk` only | no `Makefile` overlap |

This sprint's `Makefile` hunks sit at old lines 291–294, 373–391, 832–840, 860–868 and the include after 1078 (verified above: 294/386/835/863 recipe lines, include site 1078). **The sprint must not edit `mk/m45.mk`, `mk/deck-layout.mk`, `mk/earth-link.mk`, or any region inside those five `Makefile` PR ranges.** Fallout is by design, not defect: after this lands, linters on those PRs will name their new unguarded gates and print the one-line fix (#379 adds 9, #384 adds 2, #380 adds 1, #373 adds 0 — V11; design Risks and Open question 1/OQ1 default: wrap, do not basline-and-raise). The controller posts the pattern on those PRs at landing.

## Files / do-not-touch (D-144)

Executor allowlist — exactly: `tools/script_gate.sh`, `tools/script_gate_lint.sh`, `tools/test_script_gate.sh`, `tools/script-gate-baseline.txt` (generated by the W2 command only), `mk/script-gates.mk`, `tests/fixtures/script_gate/{good,parse_error,runtime_error,no_summary}.gd.txt`, `tests/fixtures/script_gate/lint_negative.mk.txt`, `tests/fixtures/script_gate/lint_negative_baseline.txt`, `Makefile` (only the doc's six diff-ready hunks), `tests/test_sim_bridge.gd`, `tests/test_galaxy_map.gd` (counted summaries only), `design_docs/planned/r1/m4-7x-script-gate-predicates-sprint.md` (this plan), `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` (this feature's progress/notes only). Optional: `tools/script_gate_supervise.pl` only if the supervisor is not inlined (A2; then extend AC11).

**Do not touch:** `audio/`, `data/audio/`, `assets/audio/`, and `mk/sound.mk` (D-144; **read-only** — the migrations never open it; its 12 rows stay on the baseline until batch B7, design W6). Also: `mk/deck-layout.mk`, `mk/earth-link.mk`, `mk/m45.mk` and the PR-touched `Makefile` regions (table above); `ui/earth_feed.gd`; `data/ui/comms_feed.json`; the R2-KERR and R3-WORLDS files (design Deliverables). AC11's second count (`0`) is the enforcement. No `.gd` is tracked (fixtures are `.txt`, copied to scratch at run time), so no new `.uid` (`uid-guard` unaffected, W3). No Python anywhere (design §Language; CLAUDE.md "Python" — glue in POSIX sh/awk, the `audio_silent_guard.sh` class).

## Gates

- **Executor-local (part of `make test`/`ci-fast` after M3, so green before the PR):** `make script-gate-lint script-gate-selftest script-gate-drill`; AC1, AC2, AC5, AC12; the policy gates (AC10).
- **PR/merge (controller):** the GitHub fast tier = AC13 (`gh pr checks <PR>` → `success`; `gh run view <run> --log \| grep -cE '…'` → `2`, with the post-A2 case-count alternative per the sequencing note); targeted gates AC1–AC7, AC14, AC15, AC16–AC18 (design, after the round-2 amendments); main's nightly `rig/full` (`make test` picks the new targets up through the M3 wiring) stays green after landing (CLAUDE.md, Definition of done 1; merges of 2026-11-03).
- **Physics/pillar gates:** none engaged — net 0 pillar table, no formula, scene, shader or player-visible change (design header; DoD 2–5 not applicable; suite hygiene under D-88 A).
- **Evaluation (controller):** independent evaluator, generator ≠ judge, 100 points / 70 to pass, output in `.ailang/state/evaluations/`; the evaluator reruns the drills and ACs first-hand, including the interim→final pin sequence recorded in the sprint JSON.

## Pause points (global)

- The planner stops at these two artifacts. The executor must not commit; the controller owns all git writes, the PR, the landing comments on #379/#380/#384/#373, and AC13.
- Sandbox has no network (planner-run; sprint JSON F3 precedent): anything `gh`- or PR-shaped re-verifies at controller kickoff before the first `Makefile` edit.
- If `origin/main` moved past `78f390c0` at pickup: re-run the reality-check block, apply the AC preface ("If the base has moved, record the base's own counts. The relations must still hold: pre-migration rows = post + 5, and lint ok"), and pause if any hunk offset or inventory count moved.
- `make sim`'s AILANG steps are slow on a loaded rig (V30): poll in a bounded loop; never wrap `make` in a bare `perl` alarm expecting children to die (V30, Risks).
