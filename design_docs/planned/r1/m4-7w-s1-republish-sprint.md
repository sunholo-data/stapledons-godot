# Sprint addendum: R1-M4-JOURNEY row 7w, reproducible S1 republish

**Status:** Planned, mission iteration 66 planner, 2026-11-03. One milestone `M4.6rR3_7w_S1_REPUBLISH` inside approved `R1-M4-JOURNEY` (D-22/D-66; D-88 A), `passes: false`. Nine ordered tasks; estimate ~135 changed LOC (design round-1 ~100 plus carve-out ~35), below the 650-LOC milestone cap.
**Design:** [m4-7w-s1-republish.md](m4-7w-s1-republish.md), read in full through the final subsection, **“Quorum round 2 and the controller's carve-out revision (iteration 66)”**. That subsection overrides all earlier disagreements. Format follows [the previous addendum](m4-7l-capture-followups-sprint.md), especially its iteration-64 amendment and controller dispositions. CLAUDE.md was read; its referenced `sprint-planner` skill is absent from the supplied catalog and the bounded project/system skill searches, so this explicit mission contract and the prior addendum supply the planning procedure.
**Budget and reuse:** existing shell harness and Godot capture driver; no package-like capability, new AILANG, Python, dependency or pin change. Runtime is **v0.56.1**, overriding the parent sprint's historical v0.51.0 metadata without editing it.
**Ownership:** planner writes only the two requested artifacts. Executor edits the bounded implementation surface and records evidence. Controller owns all git writes, GPU checks, process/cleanup checks unavailable in the sandbox, rig/full, Linux CI, publication and the S1 handoff. No human approval request is introduced under D-88 A. This planner does not execute the sprint.

## Reality check against HEAD (first-hand)

The source commands ran before either planning artifact was edited, at HEAD `4ab2bab405f950a53d853a98fcb8251a37bd6911`, branch `design/m4-7w-s1-republish`, origin/main `68796623e5d6c9d1830d4008f5450b7d90d8b0a8`. The only HEAD-to-origin change is the approved design, in commits `44f62b2b`, `d0525d9e`, `4ab2bab4`. Implementation bytes equal the base. Publish checks were repeated against that same unedited implementation with all scratch data and TMPDIR under the clone's ignored `.godot/tmp/7w-planner/`. Earlier `/tmp` scratch observations are UNINFORMATIVE UNDER SANDBOX under this mission's outside-file rule; the recorded publish results below are the in-clone repetitions. No real gcloud was invoked.

| Command | Actual base output / implication |
|---|---|
| `git log -4 --oneline; git status --porcelain; git rev-parse HEAD origin/main` | Three design commits above `68796623`; clean working tree; full hashes above. |
| `PATH=$PWD/runtime/bin:$PATH ailang --version` | `AILANG v0.56.1`, commit `05c860a`. All AILANG use in this plan pins `runtime/bin`. |
| `make --version \| head -1; gmake --version \| head -1` | `GNU Make 3.81`; `GNU Make 4.4.1`. |
| `sed -n '322,344p' Makefile` | Capture command has no fixed-fps flag; publish default is `M4_PUBLISH_DIR := renders/m4`; checks all 18 files before one flat-path copy loop. No date, listing, create-only flag or publication deadline. |
| `sed -n '19,30p' tools/test_m4_publish.sh` | Existing `deadline()` body at 19–29, including TERM/INT/HUP forwarding, plus its closing brace at 30; PROBE_S=10, MAKE_S=20 follow at 31. Move the complete function verbatim. |
| `sed -n '14,40p;82,93p;134,148p' tools/m4_ship_capture.gd` | Cruise self-tests exist before early failure return and demo load; helm/dolly still use 30-second wall bounds; no CAPTURE_FPS, arrived settle, alpha helper or walk-count print. |
| `git ls-files tools/m4_ship_capture.gd.uid` | `tools/m4_ship_capture.gd.uid` already tracked. Shell scripts need no UID. |
| `make -n capture-m4 AILANG=$PWD/runtime/bin/ailang` | Dry run prints `godot --path . --script tools/m4_ship_capture.gd`; did not execute capture or dependencies. |
| `for m in make gmake; do $m -pnq test 2>/dev/null \| grep '^test:' \| tr ' ' '\n' \| grep -cx capture-m4-publish-test; done; grep -cE '^ci-fast:.* capture-m4-publish-test( \|$)' Makefile` | `1`, `1`, `1`. Wiring already landed in 7l(a); preserve it once, do not add prerequisites. |
| `grep -n 'Reproducibility' design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md` | Historical paragraph is line 9, directly before `## AC5`; the new W5 paragraph is absent. |
| `pgrep -fx 'stapledon-7w-process-probe-no-match'` | rc **3**, `sysmon request failed with error: sysmond service not found`, `pgrep: Cannot get process list`. Process cleanup evidence is **UNINFORMATIVE UNDER SANDBOX**, never zero processes. |

**PR overlap is doc-recorded only (V15), not a current network claim.** Open PRs recorded: #371, #373, #379, #380, #382–#385. Makefile hunks: #371 at `@@ -33`, `@@ -511`; #373 at `@@ -10,18`, `@@ -225` (capture-m4 only in .PHONY context); #379 at `@@ -480`; #380 at `@@ -251`. None overlaps the capture/publish recipes; none touches capture driver, publish test or report. No gh or network ownership check ran or is required from this sandbox planner. Controller checks for subsequent drift at handoff; historical V15 is not a fresh PR inventory.

### Base gates and RED findings

Commands in AC1–AC12 below were checked at base wherever runnable, with their documented shell setup. Zero-match grep returns 1; reported make rc is captured before greps, not inferred from the last pipeline command. New implementation criteria being RED is expected; unrelated RED stays a finding.

| Gate | First-hand base result |
|---|---|
| AC1 / AC2 | Both make and gmake: substantive `rc=0`, **14** ok lines, **0** INFRASTRUCTURE lines, footer `capture-m4-publish-test: OK (7 cases on 2 makes: GNU Make 3.81, GNU Make 4.4.1)`. Inherited regression control green; **new 15-case expectation RED** (7 != 15, 14 != 30). |
| New W4 test against unchanged base recipe | Copied base Makefile, mk/ and the exact 13-case W4 script into private `red13/`; ran `deadline 400 make -s -C <copy> capture-m4-publish-test`, then gmake. Each outer make: **rc2**, **12 ok**, **14 FAIL**, **0 INFRASTRUCTURE**, `FAILED (14 of 26 cases)`. Each inner GNU version: complete and all six new date/destination/create-only cases fail at **rc0, uploads18, lists0**, well-formed0; six inherited defective fixtures remain ok. This is real test-vs-recipe RED, not missing-target RED. |
| AC3 | Every exact `drill "$PWD" <mutant>` was invoked at base; all thirteen return **2** because `tools/deadline.sh` does not yet exist. No mutation, kill, survivor or cleanup verdict claimed. The final fail-fast AC3 loop stops on the first exit2, as intended. |
| AC4 / AC5 / AC6 | **controller-run (GPU)**; not run, **UNINFORMATIVE UNDER SANDBOX**. V28/V29 are design/controller evidence, not measurements by this planner. |
| AC7 | `0,1,0,0,0,1,0,0,0,0,0`; expected source-level RED for flag, date, dated path, create-only and shared bound. |
| AC8 | `ORDER-BAD` (date/listing absent). Expected RED. |
| AC9 | `0,0,0`, shared script absent (test rc1). Player files untouched; no implementation code yet. |
| AC10 | `0`, grep rc1. Expected RED; report paragraph not yet written. |
| AC11 | **rc2**, no `gates-ok`: three make guards green, then `git diff --check origin/main` reports **17** `space before tab in indent` diagnostics in the committed design doc. Details below; unrelated to future 7w implementation and not worked around. Separate `git diff --check` rc0 at clean planning base. |
| AC12 | Controller rig/network check: **UNINFORMATIVE UNDER SANDBOX**, not run. Source membership in test/ci-fast is the `1/1/1` query above; no suite or remote status inferred. |

**AC11 base outputs:** `uid-guard: ok (405 .uid files)`; `python-guard: ok (19 allowlisted, 0 awaiting AILANG port)`; `lint-precision: ok (positive control matched 6 lines; 3 allowlisted non-computations; no live hand-computed gamma or 1 - beta)`. Whitespace errors occur at design lines **71–73, 78–86, 92–95, 100**. Keep the original AC11 command and report RED until controller disposition; do not exclude the design, change whitespace configuration, or silently repair it here.

### Design defects requiring controller disposition

- **D1, stale walk-line expectation.** Design AC4 says `grep -c '^capture-m4: walk [0-9]* frames$'` expects **`1`**, but the overriding V28 says **“`capture-m4: walk 61 frames`, then `walk 2 frames` (arrived_home)”**. W1 prints at each successful `_helm`, and the base has two call sites. Proposed AC4 correction: count **2** and record both 61 and 2. Do not remove the second walk print to fit the stale gate.
- **D2, required planning artifact omitted.** Design AC9 says **“`0` (nothing outside the list)”**, but its regex does not include this required `m4-7w-s1-republish-sprint.md`. Add that one explicitly authorized planning path alongside the carve-out-mandated `tools/deadline.sh`; retain the original three-code-file control. No optional `tools/m4_publish_upload.sh` is chosen.
- **D3, already-red whitespace gate.** Design AC11 requires **“`git diff --check origin/main && echo gates-ok`”** and expects **“`gates-ok`”**. It cannot pass with the existing 17 whitespace defects. Controller must resolve this within the already-listed design-doc path, or disposition the design; planner does not alter that input. This is a base finding, not a new implementation failure.
- **D4, C3 is not a reference comparison.** The shot6to7 row says **“the post-landing step C3 re-captures and `cmp`s against the dated set's `m4_manifest.sha256`”**, but C3 actually copies the first fresh local capture to `/tmp/7w-c3` and compares a second capture from the same build. A deterministic six-to-seven-frame mutation survives that reproducibility check too. Comparing against a separately retained published reference could catch it; no such additional gate is required here. Keep it a documented survivor and do not claim C3 kills it.

D1/D2 are explicit proposed planning corrections, not changes to the supplied design. D3 remains an unresolved base gate. No GPU, process, network or remote-publication assertion is presented as a sandbox pass.

## Ordered tasks — RED before GREEN

1. **Preflight and dispositions (controller, executor reads).** Record D1/D2/D3 dispositions; preserve AC11 RED evidence. Verify HEAD-to-base implementation equality and V15-only ownership record, then controller re-measures any subsequent branch drift. Run the three base guards and original whitespace gate. Use pinned v0.56.1; no fetch/import/GPU bootstrap in the sandbox. Any unrelated RED is reported, not worked around. No execution dispatch from this planner.
2. **RED: inject W4 date/destination/create-only tests first (executor, shell).** Replace test script with the design's exact W4 13-case script while leaving the old publish recipe untouched. Run AC1 and AC2, requiring the measured RED `rc2 / ok12 / FAIL14`, per-case values above. Do not accept missing-target failure as RED. Keep all six inherited defective-fixture controls. Record both outer runs and two inner versions.
3. **RED: shared deadline and hang controls (executor; cleanup controller-run when sandbox-blocked).** Move existing lines 19–29 verbatim into `tools/deadline.sh` as specified below, without changing deadline behavior; replace the test's local body with a shim calling the shared script. Add `hang-ls` and `hang-cp`, giving 15 cases. Run them against the still-unbounded base recipe before fixing it. `hang-ls` must fail the new assertions (base never lists; returns success, uploads18, no timeout line or pid). `hang-cp` k=5 has no recipe deadline, so the **20 s fixture deadline returns124**, classified **INFRASTRUCTURE**, never a successful test or mutant kill; stop and record that RED before GREEN. Process preflight here is rc3: sandbox cannot certify these observations/cleanup; controller runs this RED outside it. Do not shorten/disable the outer 10/20 s bounds to manufacture a case result.
4. **GREEN: bounded dated create-only publish (executor, ~Makefile +10/−3 plus wrapper).** Apply W3 with the exact inline-child variant below: date and local checks outside, one `sh tools/deadline.sh $(M4_PUBLISH_S) sh -c` covering both listing and all 18 copies, `M4_PUBLISH_S ?= 600`, required command-line date `:=`, exact timeout message, no success on124. Preserve 7l(a) checks, cache-control and test/ci-fast wiring. Run AC1/AC2 for 30 ok, no FAIL/INFRASTRUCTURE and 15-case footer on each; cleanup-dependent evidence remains controller-run if unavailable.
5. **RED: capture checks before timing fix (controller-run GPU; executor prepares only allowed file).** Base source checks for CAPTURE_FPS, ARRIVED_SETTLE_FRAMES, WALK_FRAMES_MAX and fixed-fps flag are absent (AC7 RED). Before W2, add W1's delta guard and run without a fixed flag: expected Godot rc1, exact delta FAIL, zero frames. For settle RED, add `_card_alpha` and the alpha assertion with `ARRIVED_SETTLE_FRAMES := 0`, then run at fixed60: V29's exact two alpha0.125 failures and 14 frames. Base itself has no settle const to mutate (`nosettle` edit would exit3); use this assertion-first RED stage rather than inventing a pre-existing check. `fps30` with the guard is a second rc1/zero-frame rejection. No GPU call from sandbox executor/planner.
6. **GREEN: capture and report (executor).** Finish W1/W2: CAPTURE_FPS60, settle30, `_card_alpha`, both fixed-frame loops with `WALK_FRAMES_MAX := 122 # 2 x the measured 61-frame walk at --fixed-fps 60 (V28); 300 s of wall time is the hang guard`, walk-count line, unchanged six-frame moving-state shot wait; add `--fixed-fps 60` only to capture-m4. Preserve cruise/CA/contact-sheet checks and failure return before demo load. Insert W5's paragraph verbatim after the historical reproducibility paragraph; do not rewrite prior evidence. No scene/UI/physics edits.
7. **Sensitivity and local gates (executor/controller).** Run all thirteen publish drills below through both outer makes, then AC7–AC11. Complete the hang cases outside sandbox as needed; retain all pid/temp/signature assertions. `nopositive` is now killed. Nodeadline's inner timeout is an expected bounded classification, never a successful hang-case verdict. No full make test/ci-fast or real publish from executor. Record every rc and count; a mismatch halts for controller re-measurement.
8. **GPU acceptance in order (controller).** Run AC5 first, then AC4's two good captures last (refused capture empties renders/m4), then AC6 visual inspection. Record load, both walk counts, 15/15 PNG and 14/14 world equality, exact nosettle observations and opened images. On changed walk counts or any unexpected pixel mismatch, halt and re-measure; do not expand scope or accept a tolerance. No cross-machine identity claim.
9. **Evidence and handoff (executor → controller).** Update only this feature's notes with RED/GREEN, gate outputs, timeout/cleanup, loads and GPU receipts; keep passes false. Controller commits, repeats committed-tree scope/restoration checks, obtains independent evaluation (generator != judge), launches rig/full detached and verifies Linux15-case evidence on exact PR head (AC12). After landing only, controller performs bounded C1–C10 publish/verify/comment/park checklist below; S1 remains Mark's review, not an automatic sign-off. Planner stops after the two uncommitted artifacts, no git write.

### Test cases and their RED at base

All assertions are the W4 contract plus the carve-out. The 15-case list is exactly the 13 W4 names followed by `hang-ls hang-cp`. These expected REDs precede their GREEN fixes; only the 13-case rows were measured in this planner's scratch runs.

| Cases | Expected RED on unchanged recipe | Required GREEN |
|---|---|---|
| complete (strengthened positive control) | Measured rc0/uploads18/lists0, wrong flat dest, well-formed0 => FAIL on each make. | rc0; cp18/good18/uniq18/all19/lsok1; exact dated success once. |
| worlds-missing, worlds-empty, worlds-short, manifest-missing, png-missing, hash-mismatch (inherited) | All six measured **ok** at base; regression controls, not new REDs. | Nonzero rc; all0, exact pre-upload failure once, no success. |
| date-missing | Measured rc0/uploads18/lists0 => FAIL; no date required. | Nonzero rc, all0, pre1, success0. |
| date-malformed | Same measured RED with `2026-11-3`. | Same; shape check, not calendar validation. |
| date-env | Same measured RED with environment-only date. | Same; `M4_PUBLISH_DATE :=` ignores environment default. |
| dest-nonempty | Measured rc0/uploads18/lists0 => FAIL. | Nonzero rc, all1/lsok1/cp0/pre1, success0. |
| ls-error | Same measured RED: listing never consulted. | Same; 403 cannot prove empty. |
| exists-at-cp | Measured rc0/uploads18/lists0 => FAIL, absent create-only flag. | Nonzero rc, cp9/all10/lsok1/pre0, exactly one `FAILED after 8 uploads: 05_brake_b05_deck.png not created at <dated dest> (create-only precondition or gcloud error); this dated set is now partial`, no success. |
| hang-ls | Predicted case FAIL: old recipe never invokes ls, rc0/cp18, no timeout line/pid. **UNINFORMATIVE UNDER SANDBOX** for cleanup; controller RED. | Fake ls logs once, writes its pid then sleeps600. With M4_PUBLISH_S=3, make nonzero within15s, exact timeout line once, no uploaded18 line, hung pid gone. |
| hang-cp | Predicted **outer fixture124 / INFRASTRUCTURE**, at cp5, because old recipe has no deadline. Not an accepted case outcome. Controller RED only. | Fake fifth cp logs, writes pid then sleeps600. Same 3s/15s/message/no-success/pid assertions, exactly5 cp attempts and none after it. |

For hang cases, preserve `PROBE_S=10`, `MAKE_S=20`, reset `$T/hang.pid` and a separate `$T/cp.count` for every fixture, start elapsed timing immediately before make, assert elapsed <=15 (never outer124), and assert nonzero rc. Use a separate cp counter, not the mutable log, so `deadcapture` changes only log visibility. Write `$$` to `$T/hang.pid` in the fake then `exec sleep 600`, keeping its pid. Require the pid file, validate numeric pid, and `kill -0 "$(cat "$T/hang.pid")"` must fail after the bounded make. A permission/process-query failure is UNINFORMATIVE UNDER SANDBOX, not proof of death. Stub keeps its one generic log line with exactly two `>> "$T/log"`; behavior branches add no log writes. Hang assertions deliberately do not add dated-path/lsok/good counts beyond W4; they test deadline/message/cleanup, plus five cp attempts for hang-cp. This preserves the drill signatures below.

## Shared deadline and bounded recipe

New `tools/deadline.sh`: `#!/bin/sh`, then **verbatim** `tools/test_m4_publish.sh:19–29` (the complete `deadline()` definition below), then `deadline "$@"`. Do not use the earlier 7l drill's shorter wrapper: the TERM/INT/HUP forwarding is required. In the test script replace its duplicated function by `deadline() { sh "$ROOT/tools/deadline.sh" "$@"; }`; both probe and fixture makes thereby use the shared body. Keep 124/INFRASTRUCTURE handling and 10/20-second limits unchanged. Before moving it, save its exact base bytes and compare the extracted new function against that snapshot; expected cmp rc0. No new optional upload helper.

The following is the chosen W3 variant (design explicitly permits inline sh-c), preserving the inherited drill anchors. The listing pattern uses double quotes so it nests correctly in the single-quoted child script; the lsany drill below matches that spelling. It is planning text, not an implementation edit:

```make
M4_PUBLISH_DIR := renders/m4
M4_PUBLISH_DATE :=
M4_PUBLISH_S ?= 600
test: capture-m4-publish-test
capture-m4-publish: ## maintainers (gcloud): check the date and all 18 files of the 3D-ship S1 set, then create them (create-only) under a NEW dated path refs/m4_ship_s1/<date>/ (M4_PUBLISH_DATE=YYYY-MM-DD required; never the reviewed flat set)
	@set -eu; d='$(M4_PUBLISH_DIR)'; day='$(M4_PUBLISH_DATE)'; \
	  case "$$day" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) echo "capture-m4-publish: FAILED before any upload: M4_PUBLISH_DATE=YYYY-MM-DD is required on the command line (got '$$day')"; exit 1 ;; esac; \
	  dest="gs://stapledons-voyage-assets/refs/m4_ship_s1/$$day/"; \
	  set -- "$$d"/*.png "$$d/manifest.json" "$$d/m4_manifest.sha256" "$$d/worlds.sha256"; \
	  for f; do test -s "$$f" || { echo "capture-m4-publish: FAILED before any upload: $$f missing or empty"; exit 1; }; done; \
	  test $$# = 18 && test "$$(ls "$$d"/*.png | wc -l | tr -d ' ')" = 15 && \
	  test "$$(wc -l < "$$d/m4_manifest.sha256" | tr -d ' ')" = 15 && \
	  test "$$(cut -d' ' -f1 "$$d/m4_manifest.sha256" | sort -u | wc -l | tr -d ' ')" = 15 && \
	  test "$$(wc -l < "$$d/worlds.sha256" | tr -d ' ')" = 14 && \
	  (cd "$$d" && shasum -a 256 -c m4_manifest.sha256 > /dev/null) || { echo "capture-m4-publish: FAILED before any upload: a count or m4_manifest.sha256 check"; exit 1; }; \
	  prc=0; sh tools/deadline.sh $(M4_PUBLISH_S) sh -c 'set -eu; dest=$$1; shift; \
	  lrc=0; out=$$(gcloud storage ls "$$dest" 2>&1) || lrc=$$?; \
	  if test $$lrc = 0; then echo "capture-m4-publish: FAILED before any upload: $$dest already holds $$(printf '%s\n' "$$out" | grep -c .) objects"; exit 1; fi; \
	  case "$$out" in *"One or more URLs matched no objects"*) ;; *) echo "capture-m4-publish: FAILED before any upload: cannot prove $$dest is empty (gcloud storage ls exit $$lrc)"; exit 1 ;; esac; \
	  n=0; for f; do gcloud storage cp --if-generation-match=0 --cache-control="public, max-age=300" "$$f" "$$dest$${f##*/}" > /dev/null || { echo "capture-m4-publish: FAILED after $$n uploads: $${f##*/} not created at $$dest (create-only precondition or gcloud error); this dated set is now partial"; exit 1; }; n=$$((n+1)); done; \
	  test $$n = 18; echo "capture-m4-publish: uploaded 18 files to $$dest"' sh "$$dest" "$$@" || prc=$$?; \
	  if test $$prc = 124; then echo "capture-m4-publish: publication timed out; destination may be partial; inspect before retry; do not announce"; exit 1; fi; exit $$prc
capture-m4-publish-test: ## rows 7l(a), 7w: the publish checks its date, all 18 files and an empty dated destination before its first upload, and only creates objects (private fixture, fake gcloud, every GNU make on PATH; never uploads)
	@sh tools/test_m4_publish.sh "$(CURDIR)"
.PHONY: capture-m4-publish capture-m4-publish-test
```

## Exact drill functions and invocations

Use fresh `/bin/sh`, not zsh (`$G` in cdrill relies on POSIX word splitting). Define these functions from this plan; no drill runner is committed. The deadline body below is copied verbatim from the base test, including forwarding. Cdrill is copied from the 7w design with only the V29 nosettle expectation narrowed. Publish drill retains the previous addendum's private-copy/trap/count/cmp structure and original mutations, adding the six 7w mutations, nodeadline/nomsg, the shared-script copy and 15-case verdicts. A changed mutation anchor exits3; never weaken it to make a drill run.

```sh
deadline() { # deadline SECONDS CMD...: CMD's rc; 124 on expiry (TERM to its process group, KILL 5 s later)
  perl -e '
    my $s = shift; my $pid = fork; exit 125 unless defined $pid;
    if ($pid == 0) { setpgrp(0, 0); exec @ARGV; exit 127 }
    setpgrp($pid, $pid); my $hit = 0;
    $SIG{$_} = sub { kill "KILL", -$pid; exit 124 } for qw(TERM INT HUP);
    $SIG{ALRM} = sub { kill(($hit++ ? "KILL" : "TERM"), -$pid); alarm 5 };
    alarm $s; waitpid($pid, 0); my $rc = $?; alarm 0;
    exit($rc & 127 ? 128 + ($rc & 127) : $rc >> 8) unless $hit;
    my $t = time + 5; select(undef, undef, undef, 0.2) while kill(0, -$pid) && time < $t;
    kill "KILL", -$pid; exit 124;' "$@" < /dev/null
}
cdrill() (  # exit 0 expected outcome, 1 unexpected, 2 usage, 3 mutation not applied, 4 INFRASTRUCTURE
  set -eu
  ROOT=${1:?explicit checkout ROOT}; mutant=${2:?nofixed, fps30 or nosettle}
  cd "$ROOT" || exit 2; ROOT=$(pwd -P); F=tools/m4_ship_capture.gd; test -f "$F" || exit 2
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7w.XXXXXX") || exit 2
  trap 'if test -f "$T/orig.gd"; then cp "$T/orig.gd" "$ROOT/$F"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  cp "$F" "$T/orig.gd" || exit 2
  S=${DRILL_S:-900}; G="godot --path . --script $F"
  case "$mutant" in
    nofixed) ;;                                   # the recipe's flag dropped: no file mutation
    fps30) G="godot --path . --fixed-fps 30 --script $F" ;;
    nosettle) perl -i -pe '$n += s/^const ARRIVED_SETTLE_FRAMES := 30 /const ARRIVED_SETTLE_FRAMES := 0 /; END { exit($n == 1 ? 0 : 3) }' "$F" || exit 3
              if cmp -s "$T/orig.gd" "$F"; then exit 3; fi
              G="godot --path . --fixed-fps 60 --script $F" ;;
    *) exit 2 ;;
  esac
  set +e
  PATH="$ROOT/runtime/bin:$PATH" AILANG_BIN="$ROOT/runtime/bin/ailang" deadline "$S" $G > "$T/log" 2>&1
  rc=$?
  set -e
  echo "cdrill $mutant: godot rc $rc"
  case "$rc" in 1) ;; 0) echo "cdrill $mutant: SURVIVED"; exit 1 ;; *) echo "cdrill $mutant: INFRASTRUCTURE rc $rc"; exit 4 ;; esac
  test "$(grep -c 'SCRIPT ERROR:' "$T/log")" -eq 0 || exit 1
  test "$(grep -c '^capture-m4: FAIL$' "$T/log")" -eq 1 || exit 1
  case "$mutant" in
    nofixed|fps30)
      test "$(grep -cE '^capture-m4: FAIL process delta [0-9.e-]+ s is not 1/60 s: run it as make capture-m4 \(godot --fixed-fps 60\)$' "$T/log")" -eq 1 || exit 1
      test "$(grep -c '^capture-m4: FAIL ' "$T/log")" -eq 1 || exit 1
      test "$(grep -c '^capture-m4: ok frame' "$T/log")" -eq 0 || exit 1 ;;
    nosettle)
      test "$(grep -cxF 'capture-m4: FAIL arrival card alpha 0.125 at arrived_acen (want 1, after 0 frames)' "$T/log")" -eq 1 || exit 1
      test "$(grep -cxF 'capture-m4: FAIL arrival card alpha 0.125 at arrived_home (want 1, after 0 frames)' "$T/log")" -eq 1 || exit 1
      test "$(grep -c '^capture-m4: FAIL arrival card alpha ' "$T/log")" -eq 2 || exit 1
      test "$(grep -c '^capture-m4: FAIL ' "$T/log")" -eq 2 || exit 1
      test "$(grep -c '^capture-m4: ok frame' "$T/log")" -eq 14 || exit 1 ;;
  esac
  echo "cdrill $mutant: expected outcome"
)
drill() (  # exit 0 expected outcome, 1 unexpected, 2 usage, 3 mutation not applied, 4 INFRASTRUCTURE
  set -eu
  ROOT=${1:?explicit checkout ROOT required}; mutant=${2:?publish mutant required}
  cd "$ROOT" || exit 2; ROOT=$(pwd -P)
  test -f Makefile && test -f tools/test_m4_publish.sh && test -f tools/deadline.sh || exit 2
  case "$mutant" in flat|nodate|nols|lsany|envdate|nogen|inloop|noupload|deadcapture|nopositive|stall|nodeadline|nomsg) ;; *) exit 2 ;; esac
  S=${DRILL_S:-400}
  P=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7w-publish.XXXXXX") || exit 2
  trap 'rm -rf "$P"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  mkdir "$P/w" "$P/w/tools" "$P/tmp" || exit 2
  cp Makefile "$P/w/Makefile" || exit 2; cp -R mk "$P/w/mk" || exit 2
  cp tools/test_m4_publish.sh tools/deadline.sh "$P/w/tools/" || exit 2
  MK=$P/w/Makefile; TS=$P/w/tools/test_m4_publish.sh
  case "$mutant" in
    inloop)  # restore the old shape: no pre-check loop, no worlds count, test -s back inside the upload loop
      perl -i -ne 'if (/^\t  for f; do test -s "\$\$f" \|\| \{ echo "capture-m4-publish: FAILED before any upload: \$\$f missing or empty"; exit 1; \}; done; \\$/) { $a++; next }
        if (/^\t  test "\$\$\(wc -l < "\$\$d\/worlds\.sha256" \| tr -d . .\)" = 14 && \\$/) { $b++; next }
        $c++ if s/^\t  n=0; for f; do gcloud /\t  n=0; for f; do test -s "\$\$f"; gcloud /; print;
        END { exit(($a == 1 && $b == 1 && $c == 1) ? 0 : 3) }' "$MK" || exit 3 ;;
    noupload|nopositive)  # the recipe still says "uploaded 18 files" but uploads nothing
      perl -i -pe '$n += s/^\t  n=0; for f; do gcloud storage cp /\t  n=0; for f; do true storage cp /; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
    deadcapture)  # the fake gcloud logs nowhere
      perl -i -pe '$n += s{>> "\$T/log"}{>> /dev/null}g; END { exit($n == 2 ? 0 : 3) }' "$TS" || exit 3 ;;
    stall)  # the recipe hangs in a child that ignores TERM
      perl -i -pe '$n += s/^\t\@set -eu; d=/\t\@sh -c \x27trap "" TERM; exec sleep 617\x27; set -eu; d=/; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
    flat)
      perl -i -pe '$n += s{dest="gs://stapledons-voyage-assets/refs/m4_ship_s1/\$\$day/"}{dest="gs://stapledons-voyage-assets/refs/m4_ship_s1/"}; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
    nodate)
      perl -i -ne 'if (/^\t  case "\$\$day" in /) { $n++; next } print; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
    nols)
      perl -i -ne 'if (/^\t  (lrc=0; out=|if test \$\$lrc = 0;|case "\$\$out" in )/) { $n++; next } print; END { exit($n == 3 ? 0 : 3) }' "$MK" || exit 3 ;;
    lsany)
      perl -i -pe '$n += s/\*"One or more URLs matched no objects"\*\) ;;/\*\) ;;/; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
    envdate)
      perl -i -pe '$n += s/^M4_PUBLISH_DATE :=$/M4_PUBLISH_DATE ?=/; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
    nogen)
      perl -i -pe '$n += s/gcloud storage cp --if-generation-match=0 /gcloud storage cp /; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
    nodeadline)
      perl -i -pe '$n += s{sh tools/deadline\.sh \$\(M4_PUBLISH_S\) sh -c}{sh -c}; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
    nomsg)
      perl -i -pe '$n += s{echo "capture-m4-publish: publication timed out; destination may be partial; inspect before retry; do not announce"; }{}; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
  esac
  if test "$mutant" = nopositive; then  # and the positive control loses its upload count
    perl -i -pe '$n += s/test "\$rc" = 0 && test "\$n" = 18 && test "\$good" = 18 && test "\$uniq" = 18 && /test "\$rc" = 0 && /; END { exit($n == 1 ? 0 : 3) }' "$TS" || exit 3
  fi
  F=$MK; O=Makefile; if test "$mutant" = deadcapture; then F=$TS; O=tools/test_m4_publish.sh; fi
  if cmp -s "$ROOT/$O" "$F"; then echo "drill: mutation did not change $O"; exit 3; fi
  if test "$mutant" = nopositive; then
    if cmp -s "$ROOT/tools/test_m4_publish.sh" "$TS"; then echo "drill: mutation did not change the test"; exit 3; fi
  fi
  ran=0
  for outer in make gmake; do
    M=$(command -v "$outer" 2>/dev/null) || { echo "drill $mutant: $outer absent, skipped"; continue; }
    test "$(ls -A "$P/tmp" | wc -l)" -eq 0 || exit 1
    t0=$(date +%s)
    rc=0
    deadline "$S" env TMPDIR="$P/tmp" "$M" -C "$P/w" capture-m4-publish-test > "$P/out" 2>&1 || rc=$?
    t1=$(date +%s)
    test "$(ls -A "$P/tmp" | wc -l)" -eq 0 || exit 1
    # Keep process-query errors distinct from a working query with no matches.
    for pattern in "$P/" '^sleep 617$' '^sleep 600$'; do
      prc=0; pgrep -f "$pattern" > "$P/pids" 2> "$P/ps.err" || prc=$?
      case "$prc" in 0|1) ;; *) cat "$P/ps.err"; echo 'UNINFORMATIVE UNDER SANDBOX: process query'; exit 4 ;; esac
      test "$(wc -l < "$P/pids")" -eq 0 || exit 1
    done
    echo "drill $mutant via $outer: make rc $rc in $((t1 - t0)) s"
    case "$rc" in
      0|2) ;;
      124) echo "drill $mutant: INFRASTRUCTURE outer timeout after $S s"; exit 4 ;;
      *) echo "drill $mutant: INFRASTRUCTURE rc $rc"; exit 4 ;;
    esac
    I=$(grep -c '^capture-m4-publish-test: INFRASTRUCTURE timeout after ' "$P/out" || :)
    if test "$mutant" = stall || test "$mutant" = nodeadline; then
      test "$rc" -eq 2 && test "$I" -eq 1 && test "$((t1 - t0))" -le 40 || exit 1
      C=complete; K=0
      if test "$mutant" = nodeadline; then C=hang-ls; K=13; fi
      test "$(grep -c "^capture-m4-publish-test: INFRASTRUCTURE timeout after 20 s: make for case $C " "$P/out")" -eq 1 || exit 1
      test "$(grep -c '^capture-m4-publish-test: ok ' "$P/out" || :)" -eq "$K" || exit 1
      test "$(grep -cE '^capture-m4-publish-test: (FAIL|OK)' "$P/out" || :)" -eq 0 || exit 1
      ran=$((ran + 1)); continue
    fi
    if test "$I" -ne 0; then echo "drill $mutant: INFRASTRUCTURE inner timeout"; exit 4; fi
    test "$rc" -eq 2 || exit 1
    N=$(grep -cE '^capture-m4-publish-test: (ok|FAIL) complete ' "$P/out" || :)
    test "$N" -ge 1 || exit 1
    case "$mutant" in
      flat) bad='complete dest-nonempty ls-error exists-at-cp' ;;
      nodate) bad='date-missing date-malformed date-env' ;;
      nols) bad='complete dest-nonempty ls-error exists-at-cp hang-ls' ;;
      lsany) bad='ls-error' ;;
      envdate) bad='date-env' ;;
      nogen) bad='complete exists-at-cp' ;;
      inloop) bad='worlds-missing worlds-empty worlds-short manifest-missing' ;;
      noupload|nopositive) bad='complete exists-at-cp hang-cp' ;;
      deadcapture) bad='complete dest-nonempty ls-error exists-at-cp hang-cp' ;;
      nomsg) bad='hang-ls hang-cp' ;;
    esac
    for c in complete worlds-missing worlds-empty worlds-short manifest-missing png-missing hash-mismatch date-missing date-malformed date-env dest-nonempty ls-error exists-at-cp hang-ls hang-cp; do
      want=ok; case " $bad " in *" $c "*) want=FAIL ;; esac
      test "$(grep -c "^capture-m4-publish-test: $want $c " "$P/out" || :)" -eq "$N" || exit 1
    done
    F=$(printf '%s\n' "$bad" | wc -w | tr -d ' ')
    test "$(grep -c '^capture-m4-publish-test: FAIL ' "$P/out")" -eq $((F * N)) || exit 1
    test "$(grep -c '^capture-m4-publish-test: ok ' "$P/out")" -eq $(((15 - F) * N)) || exit 1
    if test "$mutant" = inloop; then
      for pair in worlds-missing:2:17 worlds-empty:2:17 worlds-short:0:18 manifest-missing:2:15; do
        c=${pair%%:*}; rest=${pair#*:}; r=${rest%:*}; n=${rest#*:}
        test "$(grep -c "^capture-m4-publish-test: FAIL $c (.*): rc $r, uploads $n, " "$P/out")" -eq "$N" || exit 1
      done
    fi
    echo "drill $mutant via $outer: ok $(((15 - F) * N)) FAIL $((F * N))"
    ran=$((ran + 1))
  done
  test "$ran" -eq 2 || exit 1
  echo "drill $mutant: expected outcome on $ran outer makes"
)

```

Publish sensitivity signatures below are **planned**, not fixed-tree measurements by this planner. Original 13-case signatures come from design V27; the new hang-case deltas follow the narrowly defined hang assertions above and require controller verification. N is inner GNU versions (2 on rig). Normal mutants return make rc2; exact per-case verdicts are asserted by drill(), not inferred from an overall failure. Each invocation must run 2 outer makes. On the rig the success counts below are totals per outer make.

| Mutant | Exact FAIL cases on each inner make | With N=2: ok / FAIL |
|---|---|---|
| flat | complete, dest-nonempty, ls-error, exists-at-cp | 22 / 8 |
| nodate | date-missing, date-malformed, date-env | 24 / 6 |
| nols | complete, dest-nonempty, ls-error, exists-at-cp, hang-ls | 20 / 10 |
| lsany | ls-error | 28 / 2 |
| envdate | date-env | 28 / 2 |
| nogen | complete, exists-at-cp | 26 / 4 |
| inloop | worlds-missing, worlds-empty, worlds-short, manifest-missing; uploads17/17/18/15 (short rc0) | 22 / 8 |
| noupload | complete, exists-at-cp, hang-cp | 24 / 6 |
| deadcapture | complete, dest-nonempty, ls-error, exists-at-cp, hang-cp | 20 / 10 |
| nopositive | complete, exists-at-cp, hang-cp; **killed**, no longer a survivor | 24 / 6 |
| nomsg | hang-ls, hang-cp | 26 / 4 |
| stall | No case result; one INFRASTRUCTURE after20s for complete, <=40s, process/tmp empty | 0 / 0, no footer |
| nodeadline | First 13 cases ok, then one INFRASTRUCTURE after20s for hang-ls, <=40s, process/tmp empty | 13 / 0, no hang verdict or footer |

Before process/cleanup assertions, run `pgrep -fx 'stapledon-7w-process-probe-no-match'` capturing rc: only1 means a working service with no match. Here it returned3, so cleanup-dependent verdicts go to controller. Previous addendum's controller disposition says `xcrun_db` in private TMPDIR is a sandbox artifact; do not adopt the rejected xcrun-path workaround or suppress private-temp checks. Every real timeout, unavailable OS check or unexpected process query is UNINFORMATIVE UNDER SANDBOX here. Only the injected inner stall/nodeadline timeouts are expected classified outcomes; an outer124 is never accepted.

Exact invocations, extending the design's order only for its carve-out deltas (fail-fast so later commands cannot hide a failed drill):

```sh
for m in flat nodate nols lsany envdate nogen inloop noupload deadcapture nopositive stall nodeadline nomsg; do
  drill "$PWD" "$m"; rc=$?; echo "exit=$rc"; test "$rc" -eq 0 || exit "$rc"
done
# controller-run (GPU), before the final good AC4 pair:
for m in nofixed fps30 nosettle; do
  cdrill "$PWD" "$m"; rc=$?; echo "exit=$rc"; test "$rc" -eq 0 || exit "$rc"
done
```

Capture expectations: nofixed/fps30 are rc1 with one exact delta FAIL, zero frames; nosettle is rc1, two exact alpha0.125 FAILs (one per arrival), 14 frames, one summary FAIL. Shot6to7 remains the documented predicted survivor (not run): still reproducible, different pixels; C3's two fresh local captures cannot detect it (D4). Only comparison with a separately retained reference could do so. Invalid calendar dates matching NNNN-NN-NN remain an intentional publish gap, harmless new create-only path; controller supplies UTC date. No reservation object or deletion mechanism is added.

## Exact acceptance gates (AC1–AC12)

Run from implementation root with the definitions above and:

```sh
export PATH="$PWD/runtime/bin:$PATH"
A="AILANG=$PWD/runtime/bin/ailang"
mkdir -p .godot/tmp
# Sandboxed headless checks keep fixture data inside this clone:
mkdir -p .godot/tmp/7w-planner/tmp
export TMPDIR="$PWD/.godot/tmp/7w-planner/tmp"
```

Below are fixed-tree expectations, not planner pass claims. AC4–AC6 are **controller-run (GPU)**. AC1–AC3 child cleanup requires controller evidence when the sandbox cannot query processes. AC9 uses the controller-committed tree because git diff omits untracked scripts; before that, include untracked path accounting and compare saved file hashes across drills. AC12 requires REPO, PR_HEAD, FAST_RUN and PR set by controller for the exact implementation PR. Capture substantive rc immediately. Any unexpected124, INFRASTRUCTURE or exit4 is a rerun/stop, never a pass. D1/D2 corrections need recorded controller disposition; D3 is an unwaived failing gate.

**AC1.** Command:

```sh
deadline 400 make -s capture-m4-publish-test > .godot/tmp/7w-m.out 2>&1; echo rc=$?; grep -c '^capture-m4-publish-test: ok ' .godot/tmp/7w-m.out; grep -c '^capture-m4-publish-test: INFRASTRUCTURE' .godot/tmp/7w-m.out; tail -1 .godot/tmp/7w-m.out
```

Expected: rc=0; 30; 0; capture-m4-publish-test: OK (15 cases on 2 makes: GNU Make 3.81, GNU Make 4.4.1). Each hang case must satisfy its elapsed-time, exact-message, no-success and child-cleanup assertions. Sandbox process/cleanup evidence is UNINFORMATIVE UNDER SANDBOX; controller repeats outside it.

**AC2.** Command:

```sh
deadline 400 gmake -s capture-m4-publish-test > .godot/tmp/7w-g.out 2>&1; echo rc=$?; grep -c '^capture-m4-publish-test: ok ' .godot/tmp/7w-g.out; grep -c '^capture-m4-publish-test: INFRASTRUCTURE' .godot/tmp/7w-g.out; tail -1 .godot/tmp/7w-g.out
```

Expected: rc=0; 30; 0; capture-m4-publish-test: OK (15 cases on 2 makes: GNU Make 3.81, GNU Make 4.4.1). Each hang case must satisfy its elapsed-time, exact-message, no-success and child-cleanup assertions. Sandbox process/cleanup evidence is UNINFORMATIVE UNDER SANDBOX; controller repeats outside it.

**AC3.** Command:

```sh
for m in flat nodate nols lsany envdate nogen inloop noupload deadcapture nopositive stall nodeadline nomsg; do drill "$PWD" "$m"; rc=$?; echo "exit=$rc"; test "$rc" -eq 0 || exit "$rc"; done
```

Expected: 13 exit=0 lines, each expected outcome on 2 outer makes. Ordinary mutant FAIL sets and 15-case counts are in the drill table. stall: one inner INFRASTRUCTURE complete timeout, zero case results, <=40 s per outer make. nodeadline: one inner INFRASTRUCTURE hang-ls timeout, 13 preceding ok lines, no hang case result, <=40 s per outer make. nomsg: both hang cases FAIL, all 13 others ok per inner make. Outer 124 / exit4 is never a kill. Cleanup-dependent verdicts are controller-run if sandbox-blocked.

**AC4.** Command:

```sh
S=$(mktemp -d /tmp/stap-7w-ac4.XXXXXX); deadline 900 make capture-m4 "$A" > "$S/1.out" 2>&1; echo rc1=$?; cp -R renders/m4 "$S/a"; deadline 900 make capture-m4 "$A" > "$S/2.out" 2>&1; echo rc2=$?; cmp "$S/a/m4_manifest.sha256" renders/m4/m4_manifest.sha256 && echo png-15-of-15; cmp "$S/a/worlds.sha256" renders/m4/worlds.sha256 && echo worlds-14-of-14; grep '^capture-m4: walk [0-9]* frames$' .godot/tmp/capture-m4.log; grep -c '^capture-m4: walk [0-9]* frames$' .godot/tmp/capture-m4.log; sysctl -n vm.loadavg
```

Expected: controller-run (GPU). rc1=0; rc2=0; png-15-of-15; worlds-14-of-14; walk 61 frames then walk 2 frames; 2; load recorded. D1: design AC4 says 1 walk line but V28 measures two; this plan proposes 2 with both counts, for controller disposition. Each walk must remain below 122; a changed count is a re-measure, not a silent pass. Preserve both run logs until evidence is recorded.

**AC5.** Command:

```sh
for m in nofixed fps30 nosettle; do cdrill "$PWD" "$m"; rc=$?; echo "exit=$rc"; test "$rc" -eq 0 || exit "$rc"; done
```

Expected: controller-run (GPU). For each: cdrill <m>: godot rc 1; cdrill <m>: expected outcome; exit=0. nofixed/fps30: one delta FAIL, zero frames. nosettle: exactly one alpha 0.125 FAIL at arrived_acen and one at arrived_home, exactly two per-check FAILs, 14 ok frames, one bare FAIL summary (V29). Run before AC4.

**AC6.** Command:

```sh
open renders/m4/contact_sheet.png renders/m4/06_arrived_acen_deck.png renders/m4/06_arrived_acen_forward.png
```

Expected: controller-run (GPU). rc=0 and the three images open. Controller visually checks fully opaque arrival cards in both arrived columns, every frame lit and posed, no blank frames; records opened filenames and observations in this feature notes. Launch success alone is not visual acceptance.

**AC7.** Command:

```sh
grep -c -- '--path . --fixed-fps 60 --script tools/m4_ship_capture.gd' Makefile; grep -cF 'refs/m4_ship_s1/$${f##*/}' Makefile; grep -c '^M4_PUBLISH_DATE :=$' Makefile; grep -cF 'refs/m4_ship_s1/$$day/' Makefile; grep -cF -- 'gcloud storage cp --if-generation-match=0 --cache-control="public, max-age=300" "$$f" "$$dest$${f##*/}"' Makefile; R=$(awk '/^capture-m4-publish:/,/^\.PHONY: capture-m4-publish/' Makefile); echo "$R" | grep -c 'gcloud storage cp'; echo "$R" | grep -c 'gcloud storage cp --if-generation-match=0 '; echo "$R" | grep -cF 'tools/deadline.sh'; grep -cF 'M4_PUBLISH_S ?= 600' Makefile; echo "$R" | grep -cF '$(M4_PUBLISH_S)'; echo "$R" | grep -cF 'capture-m4-publish: publication timed out; destination may be partial; inspect before retry; do not announce'
```

Expected: 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1. The recipe has one create-only copy, one shared deadline invocation with the configured 600-second default, and one exact timeout message.

**AC8.** Command:

```sh
awk '/^capture-m4-publish:/,/^\.PHONY: capture-m4-publish/' Makefile | awk '/case "\$\$day"/ && !a {a=NR} /test -s/ && !t {t=NR} /shasum -a 256 -c/ {s=NR} /gcloud storage ls/ {l=NR} /gcloud storage cp/ {g=NR} END {print (a<t && t<s && s<l && l<g) ? "date-files-ls-then-cp" : "ORDER-BAD"}'
```

Expected: date-files-ls-then-cp. Date and local checks remain before the bounded ls-plus-cp child.

**AC9.** Command:

```sh
git diff origin/main -- demos ui interior sky sim bridge '*.gdshader' | wc -l; git diff --name-only origin/main | grep -cvxE 'Makefile|tools/m4_ship_capture\.gd|tools/test_m4_publish\.sh|tools/deadline\.sh|design_docs/planned/r1/m4-6rr3-ship-renders-bench-report\.md|design_docs/planned/r1/m4-7w-s1-republish\.md|design_docs/planned/r1/m4-7w-s1-republish-sprint\.md|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'; git diff --name-only origin/main | grep -cxE 'Makefile|tools/m4_ship_capture\.gd|tools/test_m4_publish\.sh'; test -s tools/deadline.sh && echo shared-deadline-present
```

Expected: 0, 0, 3, shared-deadline-present on the controller-committed implementation tree. D2: add the explicitly requested sprint addendum to the design allowlist; new deadline path is mandated by the carve-out. Before commit, include git ls-files --others --exclude-standard in path accounting; git diff alone omits untracked files. No optional upload helper is chosen.

**AC10.** Command:

```sh
grep -cF 'Reproducible since row 7w (iteration 66)' design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md
```

Expected: 1; the W5 paragraph is inserted verbatim after the historical 7l reproducibility paragraph.

**AC11.** Command:

```sh
make uid-guard python-guard lint-precision "$A" && git diff --check origin/main && echo gates-ok
```

Expected: gates-ok, rc0. BASE FINDING: rc2 today from git diff --check origin/main, with 17 space-before-tab diagnostics in the existing design doc (lines 71-73, 78-86, 92-95, 100). The three make guards pass (405 UIDs, Python19/0, precision6/3). Do not waive or work around this gate; controller must dispose of the pre-existing whitespace defect before final acceptance.

**AC12.** Command:

```sh
gh api "repos/$REPO/commits/$PR_HEAD/status" --jq '.statuses[] | select(.context=="rig/full") | .state' | head -1; grep -c '^capture-m4-publish-test: OK (15 cases on 2 makes' "${RIG_DIR:-${TMPDIR:-/tmp}/rig-check/$PR_HEAD}.log"; gh run view "$FAST_RUN" --json conclusion --jq .conclusion; gh run view "$FAST_RUN" --log > .godot/tmp/7w-fast.log && grep -c 'capture-m4-publish-test: OK (15 cases on 1 makes' .godot/tmp/7w-fast.log
```

Expected: controller-run (rig/network). success, 1, success, 1 on the exact PR head. Controller launches tools/rig_check.sh "$PR" detached after executor handoff; rig/full runs make test, Linux fast tier runs ci-fast. Require successful API/log retrieval, zero test FAIL/INFRASTRUCTURE, and record head, run ID and actual log path. Not executed by this planner: UNINFORMATIVE UNDER SANDBOX.


For AC12, controller runs `tools/rig_check.sh "$PR"` detached after this bounded planning/executor job ends, records the launch and waits for completion separately. Require rig/full success and fast-tier success on PR_HEAD, successful log retrieval and zero FAIL/INFRASTRUCTURE lines for this test. The full suite is not a planner/executor local gate. No GPU golden is added because production visuals and physics remain unchanged; S1 evidence itself is reviewed after publication.

## Controller-only post-landing publication

The design C1–C10 checklist remains controlling; the executor never uploads. Use a fresh full clone of landed main and pinned runtime, controller obtains assets/imports outside sandbox. C2 captures and verifies15 PNG hashes; C3 re-captures and requires both manifest cmp calls plus `repro`; C4 opens contact sheet and all14 images. These were not run here and are UNINFORMATIVE UNDER SANDBOX.

Apply the carve-out bound to **every** remote gcloud command in C5/C7/C8 (and any added cat):

```sh
# Controller only, after C1-C4 have passed:
D=$(date -u +%F)
sh tools/deadline.sh 300 gcloud storage ls "gs://stapledons-voyage-assets/refs/m4_ship_s1/$D/"
# Expect rc1 and exactly the 'One or more URLs matched no objects' diagnostic;
# rc124, auth/network/other diagnostic is failed verification, never empty.
make capture-m4-publish M4_PUBLISH_DATE="$D"
# Expect: capture-m4-publish: uploaded 18 files to gs://stapledons-voyage-assets/refs/m4_ship_s1/$D/
V=$(mktemp -d /tmp/7w-c7.XXXXXX)
sh tools/deadline.sh 300 gcloud storage ls "gs://stapledons-voyage-assets/refs/m4_ship_s1/$D/" > "$V/list"; rc=$?
test "$rc" -eq 0 || exit "$rc"
wc -l < "$V/list"
sh tools/deadline.sh 300 gcloud storage cp "gs://stapledons-voyage-assets/refs/m4_ship_s1/$D/*" "$V/"; rc=$?
test "$rc" -eq 0 || exit "$rc"
(cd "$V" && shasum -a 256 -c m4_manifest.sha256) > "$V/hash-check"; rc=$?
test "$rc" -eq 0 || exit "$rc"
grep -c ': OK$' "$V/hash-check"
for f in m4_manifest.sha256 worlds.sha256 manifest.json; do
  cmp "$V/$f" "renders/m4/$f" && echo "same $f" || exit 1
done
curl --max-time 300 -sI "https://storage.googleapis.com/stapledons-voyage-assets/refs/m4_ship_s1/$D/contact_sheet.png" > "$V/http"; rc=$?
test "$rc" -eq 0 || exit "$rc"
head -1 "$V/http"
sh tools/deadline.sh 300 gcloud storage ls -l gs://stapledons-voyage-assets/refs/m4_ship_s1/manifest.json; rc=$?
test "$rc" -eq 0 || exit "$rc"
sh tools/deadline.sh 300 gcloud storage ls gs://stapledons-voyage-assets/refs/m4_ship_s1/ > "$V/old-list"; rc=$?
test "$rc" -eq 0 || exit "$rc"
grep -vc '/$' "$V/old-list"
```

C7 expects18 names,15 hash OKs, `same m4_manifest.sha256`, `same worlds.sha256`, `same manifest.json`, HTTP/2 200. C8 expects original manifest timestamp2026-10-16T20:59:44Z and18 flat objects. Check each rc before counting: a failed read cannot become a zero count or an empty-prefix claim. On timeout or partial upload, **do not announce**. Inspect partial dated destination; controller follows design C6's next-date/manual disposition, never automatic deletion or flat-set changes. After all verification, controller uses C9's exact picture-first comment template on recorded issue370 (bookkeeping issue per V16) with `gh issue comment 370 --body-file <file>`, expected comment URL; C10 records `PARKED for Mark's S1 render review: refs/m4_ship_s1/$D/`. No controller network action is attempted by this planner. Mark's answer is the S1 gate; parent clause4 and P-land remain separate.

## Files allowed / do not touch

Planner output is **only** this sprint addendum and one appended feature in `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`. All22 pre-existing features and every other top-level value stay identical; no updated parent pin/status/order/findings/pause points.

Executor implementation allowlist:

- `tools/m4_ship_capture.gd`: W1 guard/settle/helper/frame bounds/walk log only.
- `Makefile`: W2 single capture flag and W3 bounded dated create-only publish block; existing test/ci-fast membership preserved once. No other recipe edits.
- `tools/test_m4_publish.sh`: W4 plus shared deadline call and two hang cases.
- `tools/deadline.sh`: new shell entry point, base deadline body verbatim.
- `design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md`: W5 paragraph only.
- `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`: only new feature notes/progress; passes stays false until controller acceptance.

Branch planning/disposition paths are the existing design and this new addendum. The existing design is controller-owned for D3 disposition; the executor does not silently repair it. No upload helper is selected. No changelog outside this bounded file list; any later landing housekeeping is controller scope, not a reason to add a ninth path here.

Do not touch `demos/`, `ui/`, `interior/`, `sky/`, `sim/`, `bridge/`, any shader, scene, art, package/runtime/cache/pin/lock, `.github/workflows/`, `mk/`, other tools (including bench/goldens), Python or AILANG sources, normative physics/design canon, translation files or public render objects. Reading those seams is permitted. Generated local renders/logs are controller capture outputs only. No git add/commit/stash/checkout/reset, GPU capture, make capture-m4 execution, real gcloud or network from this planner; no git writes attempted.

## Pause points

- Stop planner after the two reviewable artifacts; controller owns handoff and commits. This is an approved-sprint hygiene addendum under D-88 A, no new human permission request.
- Controller disposes D1/D2 before dependent fixed-tree acceptance, D3 before claiming AC11 green. Preserve the measured unrelated failure; no whitespace exclusions or weakened allowlists.
- Halt execution on source drift/overlap, wrong RED signature, mutation count !=1 (or specified3/2), missing cmp change, missing make/version or any unexpected fixed-tree failure. Do not broaden scope to fix adjacent work.
- Sandbox inability to verify processes, temporary files outside clone, sockets, GPU or network is **UNINFORMATIVE UNDER SANDBOX**, never pass/fail. Preserve assertions and transfer to controller. Do not treat pgrep rc3 or kill permission errors as zero processes. Nodeadline/stall only accept their specified injected inner classification with cleanup and timing, never an outer timeout.
- Changed walk/settle/pixel results or cdrill exit1 require controller design re-measurement, not adjusted expectations. Exit3 is mutation setup failure, exit4 is infrastructure.
- After evidence, controller commits and runs independent evaluation, rig/full and Linux tier on exact head. Publication follows landing and full remote verification only. Then park for Mark's S1; loop takes no S1 action until his answer. No automatic sign-off, merge or announcement from executor.

## Planning artifact checks

Run these after writing the two artifacts. The same JSON/schema/source/whitespace checks were also run where meaningful before writing: base JSON valid,22 features; new feature absent; implementation diff empty; working-tree `git diff --check` rc0. Original origin/main whitespace gate is separately RED as recorded; these checks do not replace it.

```sh
jq -e . .ailang/state/sprints/sprint_R1-M4-JOURNEY.json > /dev/null && echo json-valid
(
  S=.ailang/state/sprints/sprint_R1-M4-JOURNEY.json
  Q=$(mktemp -d .godot/tmp/iter66-state-check.XXXXXX) || exit 2
  trap 'rm -rf "$Q"' EXIT
  git show "HEAD:$S" | jq -S . > "$Q/before" || exit 1
  jq -S 'del(.features[] | select(.id=="M4.6rR3_7w_S1_REPUBLISH"))' "$S" > "$Q/after" || exit 1
  cmp "$Q/before" "$Q/after" || exit 1
  jq -e '.features|length==23' "$S" > /dev/null || exit 1
  jq -e '[.features[]|select(.id=="M4.6rR3_7w_S1_REPUBLISH")]|length==1' "$S" > /dev/null || exit 1
  jq -e '.features[-1] | .id=="M4.6rR3_7w_S1_REPUBLISH" and .passes==false and .depends_on==[] and (.acceptance_criteria|length==12)' "$S" > /dev/null || exit 1
  echo existing-state-identical-22-plus-1
)
git diff --quiet HEAD -- Makefile tools/m4_ship_capture.gd tools/test_m4_publish.sh design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md && test ! -e tools/deadline.sh && echo implementation-untouched
git diff --check && echo planning-whitespace-ok
```

Expected: `json-valid`, `existing-state-identical-22-plus-1`, `implementation-untouched`, `planning-whitespace-ok`, rc0. Enumerate both tracked and untracked files with `{ git diff --name-only HEAD; git ls-files --others --exclude-standard; } | sort -u`; exactly the two requested paths. Compare its two-path allowlist, expected outside0, and feature commands against AC1–AC12 in this Markdown. Extract the function/setup/command shell blocks and run `sh -n`/`bash -n`; expected rc0, no output. Do not syntax-check the Makefile block as shell.

D2's original design allowlist with untracked paths included must report1 (this required addendum); the proposed corrected allowlist reports0. Three-code-file control stays0 at planning and becomes3 after implementation; new deadline must be present then. No implementation GREEN or fixed-tree cleanup verdict is claimed by these artifact checks.

Measured final artifact checks (2026-11-03): `json-valid`, `existing-state-identical-22-plus-1`, `implementation-untouched`, `planning-whitespace-ok`, all rc0. Canonical `jq -S` comparison confirms all22 old features and every other top-level value unchanged; exactly one new feature, false, empty dependencies,12 ACs matching the Markdown commands. Both tracked-plus-untracked path enumeration and status show only the two requested artifacts. D2 original outside count1 (required addendum), corrected count0; core code count remains0 at planning. All17 shell blocks pass `sh -n` and `bash -n`. The copied deadline function is byte-identical to base including its closing brace. All13 mutation expressions apply with exact counts and cmp differences on private copies inside the clone; these are setup checks, not mutant kills or cleanup claims. A private 13-case smoke run of the proposed inline recipe through make and gmake returns rc0 / ok26 / 13-case footer, validating the nested quoting and existing cases only; it is **not** 15-case GREEN, hang cleanup, GPU, rig or Linux evidence. Original AC11 remains rc2 from the17 pre-existing design whitespace defects; no input fix, waiver or workaround was made. No git write operation was attempted.
