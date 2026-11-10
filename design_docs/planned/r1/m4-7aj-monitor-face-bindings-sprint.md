# Sprint plan: R1-7AJ-MONITOR-BINDINGS — monitor-face bindings in the display audits (row 7aj)

**Design doc:** [m4-7aj-monitor-face-bindings.md](m4-7aj-monitor-face-bindings.md) (revision 2; design-quorum round 1
produced per-sample coverage and the measured r1 prototype; round 2's 2/3 block was answered under the narrow-refinement
carve-out by gpt6-1-sol's M3 execution contract — both subprocesses under `$(SCRIPT_GATE)` deadlines, AC14, V24/V25 — and
oc-glm-5-3's required `orphan` mutant or reverse-branch deletion — AC6b, V23; Open questions: none).
**Sprint JSON:** `.ailang/state/sprints/sprint_R1-7AJ-MONITOR-BINDINGS.json`.
**Approval basis:** D-88 — neutral test-infra hygiene (pillar table net +2, no pillar below 0; test code and make glue
only, nothing a player sees), so the unattended loop proceeds with no attended stop.
**Branch:** `mission/stapledon-iter83-7aj` (HEAD `a802586d`, the revision-2 design commit; the doc's measurements are
against `b974e302`, which is this branch's merge-base with main — `git merge-base origin/main HEAD` → `b974e302` — so
every V-number below applies verbatim).
**Scope:** ~55 LOC, all in test code and make glue, in exactly three files: `tests/m4_playthrough_ship.gd` (+~16: the M1
face refresh in `sample()` and the M3 `PLAYTHROUGH_MONITOR_MUTANT` hook — five mutants plus a test-only `stall` value,
inert unless the variable is set), `tests/display_audit.gd` (+~22: M2 per-sample `monitor-coverage` checks under the
product's own visibility rules, both branches, plus the `display-audit monitors:` diagnostics line, non-`control`
routes only), `mk/earth-link.mk` (+~16: the `display-audit-monitor-controls` target and its `ship-demo-ci` edge, both
subprocesses gated per the M3 execution contract, `MONITOR_AUDIT_S ?= 600` deadline knob). **No product file changes**
(AC7/AC8). Never touched: `Makefile`, `ui/`, `interior/`, `demos/`, `main.gd`, `sim/`, `assets/`, `data/sky`,
`tests/fixtures/display_audit/`, and PR #412's files (`demos/ship_geometry_demo.gd`,
`ui/ship_star_identification.gd`, `mk/captain-anim.mk`, `mk/captain-command.mk`; AC12). The four existing audit
targets' recipes do not change; `scene-session-audits` goes green through `tests/m4_playthrough_ship.gd` alone (V11).
**No GPU step, no `make golden`, no capture, and no full `make test` anywhere in this plan** — the keep-going nightly
(7ag) runs the suite on main post-merge (post-merge check below). The measured prototype is
`/tmp/stap_i83_7aj_prototype_r1.patch` (read-only reference, V19/V20); it used `PROTO_7AJ_MUTANT` where the shipped
name is `PLAYTHROUGH_MONITOR_MUTANT` (design M3, AC9) — do not copy the prototype's variable name.

Every command below is headless, runs from the branch clone with `export PATH=$PWD/runtime/bin:$PATH` (pinned Godot,
AILANG v0.56.1 on PATH), with `T=$(mktemp -d)` created once per session; `perl -e 'alarm N; exec @ARGV'` is the
wall-clock bound used throughout (7ag convention), never a substitute for the recipes' own `$(SCRIPT_GATE)` deadlines.

## Test-first order (mandatory)

1. **MS1 first:** write the mutant hook (`tests/m4_playthrough_ship.gd`) and the full
   `display-audit-monitor-controls` target (`mk/earth-link.mk`, both subprocesses under `$(SCRIPT_GATE)` per the
   design's M3 execution contract, all five mutants and their reason greps already in place) **before any fix**.
   Run the target on the unfixed tree: the playthrough legs pass, the audit legs reject (main's `missing=414 …
   failures=828` signature), but `unrefreshed` and `drop_one` can never reach `: rejected` because their
   `monitor-coverage` greps cannot match anything yet (M2 absent). Record that red; it is the baseline every later
   green is judged against (design sub-milestone M3 note: "Write the control first, see `unrefreshed` and `drop_one`
   red, then confirm M1 green").
2. **MS2 second:** apply M1 — the harness refreshes every monitor face in `sample()` (guarded against the
   `unrefreshed` mutant). AC1–AC4 go green at the M1-only check counts (V8–V11). The controls target stays red in a
   now-diagnostic way: `unbound`/`stale` already reject for their own reasons, `unrefreshed` rejects but misses its
   coverage grep, and `drop_one`/`orphan` survive the audit (rc 0 against WANT_RC 1 → infrastructure-failure path, not
   counted).
3. **MS3 third:** apply M2 — per-sample coverage checks plus the totals line. AC5's per-route totals match V19
   exactly; the controls target goes fully green (`5 rejected`, AC6), the `orphan` leg is measured for AC6b (V23) or
   the sanctioned reverse-branch deletion is taken, and the stalled-run evidence for AC14 (V25) is produced.
4. **MS4 last:** hygiene and scope evidence (AC7–AC13), no new code.
Never present a control as green that never went red; record actuals wherever the plan says "record".

## Milestones

### MS1 — Red controls (test-first): `PLAYTHROUGH_MONITOR_MUTANT` hook + `display-audit-monitor-controls` (~30 LOC: harness +~14, earth-link.mk +~16)

Files: `tests/m4_playthrough_ship.gd`, `mk/earth-link.mk`.

- Hook, in `sample()` immediately after the `frame % 4` early return and before the label walk
  (`tests/m4_playthrough_ship.gd:53-55`), test-only and inert unless the variable is set (AC9):
  - `var mutant := OS.get_environment("PLAYTHROUGH_MONITOR_MUTANT")` (not the prototype's `PROTO_7AJ_MUTANT`), plus a
    sampled-row counter (10th sampled row = frame 36 in the crew voyage; V20, V23).
  - `unrefreshed`: no body — it guards MS2's M1 loop (`mutant != "unrefreshed"`), reproducing today's bug (V12).
  - `drop_one`: on the 10th sampled row only, hide the course face (`face.visible = false`), restore it after the row
    is written (prototype lines 68–75 verbatim in substance).
  - `unbound`: add a plain `Label` named `Mutant`, text `42`, to the clocks face, once.
  - `stale`: `(demo.monitors[0].face as BridgeScreens.ClocksFace).ship.text = "+9 s"` by hand — must run *after* MS2's
    refresh cycle.
  - `orphan`: on the 10th sampled row, after MS2's refresh cycle, clear the course face's source in the row's view
    (`journey.plan = null`) before `samples_store_line`/the row write, restore afterwards — oc-glm-5-3's r2 fix in
    substance; realizability is checked in MS3, the sanctioned alternative lives there.
  - `stall`: a test-only stop inside `sample()` (e.g. an unbounded `OS.delay_msec` loop) so AC14's stalled-playthrough
    leg is a harness change only; never set by any recipe. AC9's grep still sees only the harness and the recipe.
- Target in `mk/earth-link.mk` after the `display-audit-comms` block (`:15-21`), plus `ship-demo-ci:
  display-audit-monitor-controls`. Sketch (the executor finalizes; every rule line stays inside one logical recipe
  line with `\` continuations, `$$` for shell):

  ```make
  .PHONY: display-audit-monitor-controls
  MONITOR_AUDIT_S ?= 600
  display-audit-monitor-controls: import ## 7aj M3 (AC6/AC6b/AC14): monitor-face negative controls — each mutant's crew voyage must pass, the gated audit (WANT_RC 1) must reject for its own measured reasons
  	@mkdir -p $(SCRATCH)/display-audit
  	@set -u; n=0; bad=0; for m in unrefreshed drop_one unbound stale orphan; do \
  	  PLAYTHROUGH_MONITOR_MUTANT=$$m $(MAKE) --no-print-directory AILANG=$(AILANG) playthrough SCRIPT=tests/playthrough_crew.json PLAYTHROUGH_OUT=$(SCRATCH)/playthrough/monitor-$$m > $(SCRATCH)/display-audit/monitor-$$m-playthrough.log 2>&1 || { tail -5 $(SCRATCH)/display-audit/monitor-$$m-playthrough.log; echo "display monitor control $$m: infrastructure failure (playthrough)"; bad=1; continue; }; \
  	  $(SCRIPT_GATE) display-audit-monitor-$$m $(SCRATCH)/display-audit/monitor-$$m.log $(MONITOR_AUDIT_S) '^display-audit: ' 1 -- $(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- $(SCRATCH)/playthrough/monitor-$$m/display_samples.ndjson crew $(DISPLAY_KNOWN) > $(SCRATCH)/display-audit/monitor-$$m-gate.log 2>&1 || { tail -5 $(SCRATCH)/display-audit/monitor-$$m-gate.log; echo "display monitor control $$m: infrastructure failure (audit)"; bad=1; continue; }; \
  	  L=$(SCRATCH)/display-audit/monitor-$$m.log; ok=1; \
  	  case $$m in \
  	    unrefreshed) grep -Eq '^FAIL missing field $$' $$L && grep -Eq '^FAIL binding contract .*/monitor_face_signal/' $$L && grep -Eq '^FAIL monitor-coverage frame=1 clocks$$' $$L || ok=0 ;; \
  	    drop_one) grep -Eq '^FAIL monitor-coverage frame=36 course$$' $$L && grep -Eq '^display-audit: .* failures=1$$' $$L || ok=0 ;; \
  	    unbound) grep -Eq '^FAIL NEW unbound node=.*/monitor_face_clocks/.*/Mutant text="42"$$' $$L || ok=0 ;; \
  	    stale) grep -Eq '^FAIL stale .*/monitor_face_clocks/' $$L && grep -Eq '^FAIL binding contract .*/monitor_face_clocks/' $$L || ok=0 ;; \
  	    orphan) grep -Eq '^FAIL monitor-coverage frame=36 course shown without its source$$' $$L && grep -Eq '^display-audit: .* failures=1$$' $$L || ok=0 ;; \
  	  esac; \
  	  if [ $$ok = 0 ]; then echo "display monitor control $$m: wrong reason (see $$L)"; bad=1; continue; fi; \
  	  n=$$((n + 1)); echo "display monitor control $$m: rejected"; \
  	done; echo "display monitor controls: $$n rejected"; test $$bad = 0 && test $$n -eq 5
  ship-demo-ci: display-audit-monitor-controls
  ```

  Execution contract (design M3, revision 2 — binding): the playthrough leg runs through the existing `playthrough`
  target, already gated at `Makefile:1354` (1200 s); the audit leg is gated per mutant with WANT_RC 1, so only an
  intentional audit rejection passes. Deadline expiry (rc 142 inside the gate), a launch failure, a wrong rc (a
  surviving mutant: rc 0) or a `SCRIPT ERROR` in either subprocess is a **control infrastructure failure**: printed,
  the mutant is never counted, the target fails. `n` increments only after the gated audit passed and every required
  reason line matched. `MONITOR_AUDIT_S ?= 600` is the one knob; its default is the design's 600 verbatim and it
  exists so AC14 can exercise "a short deadline override" without touching the recipe (Makefile is out of scope).
- If MS3 takes the sanctioned alternative (orphan unrealizable): the mutant list drops `orphan`, the check becomes
  `test $$n -eq 4`, and the doc/AC6 wording lands with "4 rejected" — pre-authorized by the design, recorded in Risks.
- Closes: the red half of AC6/AC6b; AC9's confinement shape; AC14's plumbing (both subprocesses gated from the start).
- Expected RED against the unfixed tree (record actuals): baseline first —
  `perl -e 'alarm 600; exec @ARGV' make display-audit-crew` → rc 2, `display-audit: samples=46 … missing=414 …
  failures=828` (V2; ~30–39 s warm) — then the target: every playthrough leg passes (`script-gate: playthrough ok` in
  each `monitor-<m>-playthrough.log`, zero `SCRIPT ERROR`); every audit leg exits 1 with main's signature so the
  WANT_RC-1 gates pass; `unrefreshed` matches its first two greps but not `^FAIL monitor-coverage frame=1 clocks$`
  (M2 absent) → "wrong reason"; `drop_one` matches neither of its greps → "wrong reason"; `unbound`/`stale`/
  `orphan` counts recorded as measured (V13/V14-style reasons exist independent of M2). Hard requirements: rc ≠ 0, and
  neither `unrefreshed` nor `drop_one` is ever printed as `: rejected`.
- Verify (red proof):
  1. `perl -e 'alarm 600; exec @ARGV' make display-audit-crew > $T/ms1-baseline.log 2>&1; echo rc=$?; grep -oE 'display-audit: samples=[0-9]+ .*' .godot/tmp/display-audit/crew/display-audit.log | tail -1`
     → rc 2; `samples=46 … missing=414 … failures=828` (re-measures V2).
  2. `git grep -n PLAYTHROUGH_MONITOR_MUTANT -- Makefile mk tests | grep -cvE '^(tests/m4_playthrough_ship\.gd|mk/earth-link\.mk):'; git grep -l PLAYTHROUGH_MONITOR_MUTANT -- Makefile mk tests`
     → `0`; exactly `tests/m4_playthrough_ship.gd` and `mk/earth-link.mk` (AC9 shape, mutant inert by default).
  3. `perl -e 'alarm 900; exec @ARGV' make display-audit-monitor-controls > $T/ms1-red.log 2>&1; echo rc=$?; grep -E '^display monitor control' $T/ms1-red.log; grep -c 'SCRIPT ERROR' $T/ms1-red.log`
     → rc 2; five mutant legs attempted; `unrefreshed`/`drop_one` absent from `: rejected` lines (`wrong reason`);
     final line `display monitor controls: <N> rejected` with N < 5 (record N); SCRIPT ERROR count 0. This is the
     "see `unrefreshed` and `drop_one` red BEFORE the fix" baseline. (Budget: 5 × ~12–30 s per leg; the alarm is the
     bound on a loaded host.)
  4. `perl -e 'alarm 300; exec @ARGV' make script-gate-lint; echo rc=$?`
     → rc 0 (the new audit `--script` call sits inside `$(SCRIPT_GATE)`; the 118-row baseline pin
     `tools/script-gate-baseline.txt` and `mk/script-gates.mk` stay untouched; V24).

### MS2 — M1: the harness supplies the monitors' frame (~5 LOC)

Files: `tests/m4_playthrough_ship.gd` only.

- Apply design M1 verbatim, integrated with the MS1 hook, in `sample()` right after the `mutant` read and before the
  label walk:

  ```gdscript
  # R3-COMMS-V2 CV6 / 7aj: the harness disables every node's _process (see _run), so it supplies the
  # monitors' frame as it does the map's: each face refreshes from the view the demo gave its monitor,
  # as an on-screen monitor would. No viewport renders.
  for m: BridgeMonitor in demo.monitors:
  	if m.face != null and mutant != "unrefreshed": m.face.refresh(m._view, m._receiver, m._bed)
  ```

  `m._view` is the same dictionary the audit reconstructs from (`ship_hud.update(view)` has exactly one caller,
  `demos/ship_geometry_demo.gd:1337`, and `_refresh_monitors(view)` follows at `:1339` with the same dictionary —
  V21). No `face.step()`, no viewport update; on-screen gating stays covered by `bridge-monitors-test`'s `gated`
  checks. The `stale` and `orphan` mutant blocks must run after this loop (design M3).
- Closes: AC1, AC2, AC3, AC4 (at the M1-only check counts below).
- Verify (the four audit targets go green; ~7½–8½ min total, measured V8–V11 / V19 run times 33/49/168–188/179–205 s):
  1. `grep -n 'm.face.refresh(m._view, m._receiver, m._bed)' tests/m4_playthrough_ship.gd` → the one line in `sample()`.
  2. `perl -e 'alarm 600; exec @ARGV' make display-audit-crew > $T/ms2-crew.log 2>&1; echo rc=$?; grep -E '^(FAIL|display-audit)' .godot/tmp/display-audit/crew/display-audit.log | tail -2; grep -c '^display-audit monitors:' .godot/tmp/display-audit/crew/display-audit.log`
     → rc 0; `display-audit: samples=46 checks=13386 mismatches=0 missing=0 new=0 known=138 stale=0 failures=0` (V8's
     M1-only count — the totals line does not exist yet: last grep `0`); ~33 s.
  3. `perl -e 'alarm 600; exec @ARGV' make display-audit-interlude > $T/ms2-interlude.log 2>&1; echo rc=$?; tail -1 .godot/tmp/display-audit/interlude/display-audit.log`
     → rc 0; `display-audit: samples=127 checks=37766 … missing=0 new=0 known=143 stale=0 failures=0` (V10); ~49 s.
  4. `perl -e 'alarm 900; exec @ARGV' make display-audit-comms > $T/ms2-comms.log 2>&1; echo rc=$?; tail -1 .godot/tmp/display-audit/comms/display-audit.log`
     → rc 0; `display-audit: samples=797 checks=257971 … missing=0 new=0 known=922 stale=0 failures=0` (V9); ~168–188 s.
  5. `perl -e 'alarm 900; exec @ARGV' make scene-session-audits > $T/ms2-scene.log 2>&1; echo rc=$?; grep -E '^ac4:' .godot/tmp/display-audit/playthrough/display-audit.log; tail -1 .godot/tmp/display-audit/playthrough/display-audit.log`
     → rc 0; `ac4: MET (5 accepted by D-77/D-78)`; `display-audit: samples=814 checks=254950 … missing=0 … failures=0`
     (V11); ~179–205 s. No change to `mk/m45.mk` — M1 alone fixes the scene audits (V11).
  6. Intermediate red, now diagnostic: `perl -e 'alarm 900; exec @ARGV' make display-audit-monitor-controls > $T/ms2-controls.log 2>&1; echo rc=$?; grep -E '^display monitor control' $T/ms2-controls.log`
     → rc 2; derived expectations (record actuals): `unbound: rejected` (V13: `new=46 failures=46`) and
     `stale: rejected` (V14: `mismatches=46 failures=92`) counted; `unrefreshed` wrong reason (V12's 414/828, coverage
     grep still unmatchable); `drop_one` and `orphan` survive the audit (rc 0 against WANT_RC 1) →
     `infrastructure failure (audit)` lines, not counted; final `display monitor controls: 2 rejected`.

### MS3 — M2: per-sample coverage + totals; controls green; `orphan` measured (AC6b); stalled-run evidence (AC14) (~22 LOC)

Files: `tests/display_audit.gd` only (plus MS1's target already in place).

- Apply design M2 (the r1 prototype's `tests/display_audit.gd` hunks verbatim in substance, `PROTO_7AJ_MUTANT`
  appears nowhere): the `audit_route`/`MONITOR_KINDS`/`monitor_totals` declarations, `audit_route` set from
  `args[1]` at `_run()` start, and the per-sample block in `audit()` after `root_node.free()` — for every route
  except `control`: collect kinds whose bindings have a non-empty field under `/monitor_face_<kind>/`; require clocks
  and signal always, course iff `GalaxyMap.field_value(view, "journey.plan") is Dictionary` (`CourseFace.refresh`),
  crew iff `earth.crew` is a non-empty Array (`CrewFaces.refresh`); `check(row_faces.has(kind), "monitor-coverage
  frame=%d %s")` when required, else `check(not row_faces.has(kind), "monitor-coverage frame=%d %s shown without its
  source")` — the visibility rules and their framing are V22's (15 interlude frames at rest with no plan must not
  fire). Totals line at the end of `_run()` for non-`control` routes: `display-audit monitors: clocks=%d course=%d
  crew=%d signal=%d`. V18: the line is echoed by the recipes' `^(FAIL|display-audit)` greps and matches no
  `^display-audit: .* failures=0$` gate.
- The `orphan` measurement (AC6b, V23 — executor deliverable): the MS1 hook's `orphan` leg. If the mutant proves
  unrealizable (e.g. clearing the plan hides the labels on the very same row, so nothing is recorded), **take the
  design's sanctioned alternative**: delete the reverse branch (`shown without its source`) from M2, drop `orphan`
  from the target's mutant list (`test $$n -eq 4`, `4 rejected`), and record in Risks that over-display is covered
  only by `bridge-monitors-test`'s `gated` checks. Doc/AC6 wording updated at landing (controller). Shipping a gating
  branch whose fail path no run has ever produced is the one unacceptable outcome (r2, oc-glm-5-3).
- Closes: AC5, AC6, AC6b, AC14 (and the re-confirmation of AC1–AC4 at the final V19 counts; deltas vs MS2 are the
  coverage checks themselves: +4 per row → crew +184, interlude +508, comms +3188, scene +3256).
- Verify:
  1. Shape: `grep -c 'monitor-coverage frame=%d' tests/display_audit.gd; grep -n 'display-audit monitors: clocks=%d' tests/display_audit.gd; grep -c 'shown without its source' tests/display_audit.gd`
     → `2` (both branches of one format string pair — record layout), the totals line, and `1` (or `0` under the
     sanctioned alternative — assert consistently with the chosen resolution).
  2. AC5, all four routes at the final measured counts (re-runs of MS2's commands 2–5; ~7½–8½ min):
     `grep '^display-audit monitors:' .godot/tmp/display-audit/{crew,comms,interlude,playthrough}/display-audit.log; grep -h '^FAIL monitor-coverage' .godot/tmp/display-audit/{crew,comms,interlude,playthrough}/display-audit.log | wc -l; for d in crew comms interlude playthrough; do tail -1 .godot/tmp/display-audit/$d/display-audit.log | grep -o 'failures=0'; done`
     → crew `clocks=138 course=138 crew=460 signal=138` and `checks=13570`; comms `clocks=2391 course=3074 crew=7970
     signal=2391` (`checks=261159`); interlude `clocks=381 course=434 crew=1270 signal=381` (`checks=38274`); scene
     `clocks=2442 course=3063 crew=8140 signal=2442` (`checks=258206`, `ac4: MET (5 accepted by D-77/D-78)`); zero
     `FAIL monitor-coverage` lines; four `failures=0` (V19). A totals deviation is a pause point, not an edit hint.
  3. AC6/AC6b, controls green:
     `perl -e 'alarm 900; exec @ARGV' make display-audit-monitor-controls > $T/ms3-controls.log 2>&1; echo rc=$?; grep -E '^display monitor control' $T/ms3-controls.log`
     → rc 0; five `: rejected` lines; `display monitor controls: 5 rejected`. Per-mutant measured evidence (V20; V23
     for `orphan`):
     - `grep -E '^FAIL missing field $|^FAIL binding contract .*/monitor_face_signal/|^FAIL monitor-coverage frame=1 clocks$|failures=1012' .godot/tmp/display-audit/monitor-unrefreshed.log` (three FAIL lines; `missing=414 … failures=1012` = 828 + 46 × 4 coverage),
     - `grep -E '^FAIL monitor-coverage frame=36 course$|^display-audit: .* failures=1$' .godot/tmp/display-audit/monitor-drop_one.log` (both; totals `course=135` against 138 — exactly one frame missing),
     - `grep -E '^FAIL NEW unbound node=.*/monitor_face_clocks/.*/Mutant text="42"$|new=46 ' .godot/tmp/display-audit/monitor-unbound.log`,
     - `grep -E '^FAIL stale .*/monitor_face_clocks/|^FAIL binding contract .*/monitor_face_clocks/|mismatches=46 ' .godot/tmp/display-audit/monitor-stale.log` (`failures=92`),
     - `grep -E '^FAIL monitor-coverage frame=36 course shown without its source$|^display-audit: .* failures=1$' .godot/tmp/display-audit/monitor-orphan.log`
       — **this is AC6b's measured red run of the reverse branch** (V23; absent files under the alternative: then
       `grep -c 'shown without its source' tests/display_audit.gd` → `0` and the Risks note is written instead).
  4. AC14 (V25), fail-closed evidence — a stall is a control infrastructure failure, never a rejection; three legs:
     - **Stalled playthrough, short gate deadline** (uses the hook's `stall` value; the Makefile's own 1200 s gate at
       `:1354` is out of scope, so this leg runs the same gate mechanism directly):
       `PLAYTHROUGH_MONITOR_MUTANT=stall perl -e 'alarm 180; exec @ARGV' sh tools/script_gate.sh stall-playthrough $T/stall-play.log 45 '^playthrough: [1-9][0-9]* passed, 0 failures$$' -- env AILANG_BIN=$(command -v ailang) godot --headless --path . --script tests/m4_playthrough_ship.gd -- tests/playthrough_crew.json $T/stall-out none > $T/stall-play.gate 2>&1; echo rc=$?; tail -1 $T/stall-play.gate`
       → rc 1 inside ~47 s; `script-gate: stall-playthrough FAIL; timeout after 45 s (rc 142): a runtime error before
       quit() leaves Godot running …` (the supervisor kills the whole process group at the deadline;
       `tools/script_gate.sh:35-38,54-56`).
     - **Stalled audit, short gate deadline** (never-EOF input, no test-code change):
       `mkfifo $T/stalled.ndjson; ( exec 9>$T/stalled.ndjson; sleep 300 ) & perl -e 'alarm 180; exec @ARGV' sh tools/script_gate.sh stall-audit $T/stall-audit.log 45 '^display-audit: ' 1 -- env AILANG_BIN=$(command -v ailang) godot --headless --path . --script tests/display_audit.gd -- $T/stalled.ndjson crew tests/fixtures/display_audit/known_findings.json > $T/stall-audit.gate 2>&1; echo rc=$?; tail -1 $T/stall-audit.gate; kill %1 2>/dev/null`
       → rc 1 inside ~47 s; `script-gate: stall-audit FAIL; timeout after 45 s (rc 142): …`.
     - **Target level, deadline override**: `perl -e 'alarm 900; exec @ARGV' make display-audit-monitor-controls MONITOR_AUDIT_S=1 > $T/ms3-stall.log 2>&1; echo rc=$?; grep -E '^display monitor control' $T/ms3-stall.log; grep -c 'timeout after 1 s (rc 142)' $T/ms3-stall.log`
       → rc 2; five `…: infrastructure failure (audit)` lines (no host boots Godot inside 1 s; every audit gate prints
       the rc-142 timeout reason → timeout count 5); final line `display monitor controls: 0 rejected` — **no stalled
       mutant is ever reported as rejected** (AC14). Runs in ≈ 5 × (crew playthrough ~15 s + 1 s) < 2 min; alarm 900
       bounds a loaded host.

### MS4 — Hygiene and scope evidence (no new code; AC7–AC13)

Files: none (evidence only).

- Closes: AC7, AC8, AC9, AC10, AC11, AC12, AC13, and AC14's `script-gate-lint` half.
- Verify (`B=b974e302` — this branch's merge-base with main):
  1. AC7 text identity: `git diff --exit-code $B -- ui interior demos main.gd project.godot assets data sim; echo rc=$?`
     → empty diff, rc 0. Then `perl -e 'alarm 600; exec @ARGV' make bridge-monitors-test 2>&1 | tail -1`
     → `bridge-monitors: 19 passed, 0 failures` (V16): faces still refresh through the product's own path.
  2. AC8 contract not relaxed, no allowlist: `git diff --exit-code $B -- ui/display_binding.gd ui/composed_binding.gd tests/fixtures/display_audit/; echo rc=$?`
     → empty, rc 0; `perl -e 'alarm 900; exec @ARGV' make display-audit-controls > $T/ms4-controls.log 2>&1; echo rc=$?; grep -c 'display control .*: rejected' $T/ms4-controls.log`
     → rc 0; `32` — the existing controls are unchanged and still all reject; the recipe's own `test $$n -eq 32`
     holds, and the M2 block correctly skips the `control` route (`mk/m45.mk:71-85`).
  3. AC9 mutant inert by default: `git grep -l PLAYTHROUGH_MONITOR_MUTANT -- Makefile mk tests`
     → exactly `tests/m4_playthrough_ship.gd` and `mk/earth-link.mk`; `git grep -n PLAYTHROUGH_MONITOR_MUTANT -- Makefile mk tests | grep -cvE '^(tests/m4_playthrough_ship\.gd|mk/earth-link\.mk):'` → `0`.
     Default-path inertness is already measured: MS2's green runs carried the variable unset (and the D-68 text scans
     inside the harness see the same strings pre/post refresh — no new `check` calls fire).
  4. AC10 other harness users: `perl -e 'alarm 900; exec @ARGV' make playthrough-negative playthrough-adversarial > $T/ms4-pn.log 2>&1; echo rc=$?; grep -E '^playthrough-negative: |^playthrough: ' $T/ms4-pn.log | tail -4`
     → rc 0; `playthrough-negative: 3 passed, 0 failures`; adversarial `playthrough: <N> passed, 0 failures` (V16
     measured `142161 passed` with the prototype; assert 0 failures, record N).
  5. AC11 hygiene: `make uid-guard python-guard > /dev/null && echo guards-ok; git diff --check $B; echo diff-check-rc=$?`
     → `guards-ok`, no whitespace errors, rc 0 (no `.py` touched; the three edited files all keep their existing
     `.uid` companions; none is created or deleted).
  6. AC12/scope: `git diff --name-only $B | grep -E '^(Makefile|demos/ship_geometry_demo\.gd|ui/ship_star_identification\.gd|mk/captain-anim\.mk|mk/captain-command\.mk)$'; echo nocollide-rc=$?`
     → no output, grep rc 1 (nothing shared with attended PR #412). And
     `git diff --name-only $B | sort`
     → exactly: `.ailang/state/sprints/sprint_R1-7AJ-MONITOR-BINDINGS.json`,
     `design_docs/planned/r1/m4-7aj-monitor-face-bindings-sprint.md`,
     `design_docs/planned/r1/m4-7aj-monitor-face-bindings.md` (from the design commits), `mk/earth-link.mk`,
     `tests/display_audit.gd`, `tests/m4_playthrough_ship.gd`.
  7. AC13 no GPU + AC14 lint: `git diff $B -- mk/earth-link.mk | grep -E '^\+' | grep -E 'GODOT|godot' | grep -cv 'headless'; git diff $B -- mk/earth-link.mk | grep -E '^\+' | grep -icE 'golden|capture'; perl -e 'alarm 300; exec @ARGV' make script-gate-lint; echo lint-rc=$?`
     → `0`, `0` (every Godot call is `$(GODOT_SIM) --headless`; no `golden`/`capture` target invoked), lint rc 0 with
     the new audit calls gated.

## Local PR gates (targeted, headless, bounded; a merge never waits on the GPU)

1. MS1 red proof on record (target rc 2; `unrefreshed`/`drop_one` never counted) and hook confinement grep (AC9 shape).
2. `make display-audit-crew`, `make display-audit-interlude`, `make display-audit-comms`, `make scene-session-audits`
   all rc 0 at the final V19 summaries, plus the AC5 `display-audit monitors:` totals lines and zero `FAIL
   monitor-coverage` in all four logs (AC1–AC5).
3. `make display-audit-monitor-controls` rc 0 with `display monitor controls: 5 rejected` (or 4 under the sanctioned
   alternative, doc updated), each mutant's required lines present (AC6, AC6b).
4. AC14's three stall legs on record: two direct-gate rc-142 timeout lines and the target-level `MONITOR_AUDIT_S=1`
   run ending `display monitor controls: 0 rejected` with rc 2.
5. `make bridge-monitors-test` (19/19), `make display-audit-controls` (32 rejected), `make playthrough-negative
   playthrough-adversarial` (V16 shape) — AC7, AC8, AC10.
6. `make uid-guard python-guard` rc 0; `git diff --check $B` clean; AC7/AC8 scope diffs empty; the AC12 collision grep
   empty (AC11, AC12).
7. `make script-gate-lint` rc 0 (AC14 second half; also ci-fast member `mk/script-gates.mk:27,32` — the new
   `--script` call must stay inside `$(SCRIPT_GATE)`, and it does).
8. ci-fast membership guard (no mk edit can drift it, but assert): `make -qp 2>/dev/null | grep '^ci-fast:' | tr ' ' '\n' | grep -cxE 'ship-demo-ci|display-audit-monitor-controls|display-audit-crew|display-audit-comms|display-audit-interlude|scene-session-audits'`
   → `0` (V17: ci-fast has no display audit; the new edge rides `ship-demo-ci` in `make test`).
9. No GPU gate, no `make golden`, no capture, no full `make test` anywhere in this sprint (AC13; the 7ag/7af
   precedent — the nightly runs the suite on main post-merge).

## Landing (owner: controller; only after the cross-family evaluation passes, generator ≠ judge)

- `CHANGELOG.md`: one dated entry under `## Unreleased` naming R1-7AJ-MONITOR-BINDINGS, row 7aj and PR #379 (the
  attribution), on the 7af/7ag entry model; `git mv` doc and this plan into `design_docs/implemented/r1/`; one index
  row in `design_docs/README.md`; sprint JSON milestone statuses/notes with the recorded counts and wall times, then
  `progress`/`completed`/`evaluation` and the doc/plan path move; deliverables list the four green audits with logs
  under `.godot/tmp/display-audit/`. If the `orphan` alternative was taken, update the doc and AC6 to the
  4-rejected branch-deleted wording in the same landing commit.

## Post-merge check (observation, not a merge gate)

The next keep-going nightly `rig/full` on main (`~/Library/Logs/stapledon-rig-nightly.log`): the four formerly red
targets — `display-audit-comms`, `scene-session-audits`, `display-audit-interlude`, `display-audit-crew` — pass, and
the `nightly-rig` issue's `Failing targets (N): …` list sheds exactly them, leaving the other known reds the design
names as non-goals: `bridge-operator-test` (D-148), `similar-test` (7ah), `tools-test` (7ai), `free-nav-stop-test`
(7ak). Any `FAIL monitor-coverage` in a nightly audit log with the mutant unset is a real face/visibility drift
between `tests/display_audit.gd` and `CourseFace.refresh`/`CrewFaces.refresh` — a product finding for its own row,
never an allowlist entry, and never landed silently here.

## Risks (from the doc and this plan; none blocking)

- **The mutant variable must be inert by default (AC9).** The hook reads one environment variable, adds no `check`
  calls, and MS2's greens are measured with it unset. `git grep` confines it to the harness and the recipe. The
  test-only `stall` value rides the same variable and no recipe ever sets it.
- **A stalled control must never read as a rejection (AC14).** The recipe increments `n` only after the gated audit
  passes (WANT_RC 1) *and* every reason line matches; deadline/launch/rc/`SCRIPT ERROR` faults abort the leg as
  `infrastructure failure` and fail the target. The one knob is the audit deadline (`MONITOR_AUDIT_S ?= 600`, design
  value as default); the playthrough leg's own 1200 s gate in `Makefile:1354` is out of scope, so AC14's stalled
  *playthrough* is evidenced at the same gate with a 45 s deadline directly, and the *target's* fail-closed counting
  at the audit deadline of 1 s (both above). If the evaluator insists on a full-fidelity stalled playthrough through
  the target, it costs one bounded run of up to 21 minutes (the playthrough gate expiring) — schedulable, not a merge
  gate.
- **`orphan` may be unrealizable** (the plan cleared and the labels hidden in the same row). The design pre-authorizes
  the alternative: delete the reverse branch, `4 rejected`, Risks records that over-display is then covered only by
  `bridge-monitors-test`'s `gated` checks. What may not ship is an unexercised gating branch.
- **The signal face's waterfall `_follow` touches shared audio taps** (`live=false` erases only its own id): the
  comms playthrough green at AC2/V9/V19 re-measures it.
- **M2 mirrors the product's visibility rules.** A future face-rule change reddens M2 until the mirror is updated —
  intended (the reverse branch catches over-display; AC6b pins its red run or the branch does not exist).
- **The audit now treats faces as always on screen** — stricter than play; a real finding is a product bug for its
  own row, not an allowlist entry.
- **PR #412 edits `demos/ship_geometry_demo.gd`.** M1 reads `demo.monitors` and `BridgeMonitor._view/_receiver/_bed`;
  a rename there needs a one-line follow-up here. AC12 keeps this row out of #412's files.
- **Run time.** Prototype measurements: crew 33 s (39 s at main, both warm, both including the controls), comms
  168–188 s, interlude 49 s, scene 179–205 s; the controls target adds about 5 × 12–30 s (five extra crew
  playthroughs + five gated audits) to `ship-demo-ci`, and the MS2/MS3 verification re-runs the four audits twice
  (~16 min total across the sprint) — all bounded by the alarms above, none GPU.

## Velocity / estimate

~55 LOC total (harness +~16, audit +~22, mk +~16), all test code and make glue; no product change. Verification is
run-dominated: MS1 ~1.0 h of writing + ~0.4 h of red runs (baseline ~39 s warm, controls ~3–5 min, lint < 1 min);
MS2 ~0.6 h (apply + four audits ~7½–8½ min + one intermediate controls run); MS3 ~1.0 h (apply + four audits again
+ controls green ~3–5 min + three stall legs ~5 min); MS4 ~0.5 h (guards, 32-control fixture run ~2–3 min,
bridge-monitors ~1 min, harness users ~2–4 min, greps). **Estimate: one executor session, about half a day** —
compare 7ag rig-keep-going (~200 LOC, one day) and 7af rig-golden-setup (same control family, one day on a
0.5-day estimate).

Pause points (also in the sprint JSON):

- MS1: any playthrough leg failing, any `SCRIPT ERROR`, or an audit summary that departs from the V2/V12 signature
  (`missing = 9 × samples`, `failures = 2 × missing` before M2): stop and report — the hook is not inert/shadowing as
  designed.
- MS2: any of AC1–AC4 not matching the V8–V11 summaries exactly, or the intermediate controls run contradicting the
  derived `2 rejected` shape (e.g. `drop_one` counted): stop and report — a face or the sampler drifted.
- MS3: AC5 totals not matching V19 exactly, any `FAIL monitor-coverage` with the mutant unset, or `orphan`
  unrealizable *and* the alternative not cleanly taken — stop and report. (Taking the sanctioned alternative itself
  is pre-authorized; record it, don't pause.)
- AC14: a stall counted as a rejection, or either direct gate not terminating inside its deadline: stop and report —
  the execution contract failed; do not widen a deadline to make it pass.
- Any temptation to touch `Makefile`, `ui/`, `interior/`, `demos/`, `sim/`, `assets/`, `main.gd`,
  `tests/fixtures/display_audit/`, or a PR #412 file: stop — M1 needs none of them.
- No merge before the cross-family evaluation; landing files wait on it.
