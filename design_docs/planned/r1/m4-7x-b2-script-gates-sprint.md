# Sprint plan: R1-M4-JOURNEY row 7x, B2a script gates

**Status:** Planned, mission iteration 70 planner, 2026-11-04. HEAD `8bbc6e585f806745b04641677571f1f9cf613637`, branch `feat/m4-7x-b2-script-gates`; measured below. Feature `M4.6sR3_7x_B2_SCRIPT_GATES`, dependent on landed `M4.6sR3_7x_SCRIPT_GATE_PREDICATES`.
**Design:** [m4-7x-b2-script-gates.md](m4-7x-b2-script-gates.md), approved revision 1 with controller carve-out fixes after round 2 was BLOCKED 2/3. D2's exact recipes, D3's five summary diffs, D4's **per-count** helper diff and six new stub cases, D5's fixture and control, D6's deletion-only baseline, AC1–AC16 and V21 are binding. V12's revision-0 numstat and 16/22 case counts are superseded by V19–V21's 18/24 counts. This is not a claim that quorum passed.
**Scope:** B2a's 28 rows (25 make targets), S1/S2 and the constellation prerequisite. **B2b/D7's 14 rows are out of scope**: no invocation, regex, summary, benchmark, ingest or GPU-window work is planned for them. Preserve their recipes. D3's shared captain print change incidentally reaches ingest, exactly as the design records; do not run ingest. Pillar net 0, D-88 A within D-22/D-66's approved sprint; no physics, gameplay, assertion or audiovisual change.
**Budget:** 116 hand-written changed lines (+71/−45 excluding baseline), plus 28 deleted baseline rows; the captain header comment adds another +1/−1. V21 reconciles 19 files, +71/−73 before that comment. Plan one day, six serial milestones, about 90 min including buffer (design estimates about 60 min; AC8 about 7 min and sim-bridge about 95 s, V20). The milestone totals are 24+6+17+67+2+0 = 116; comment and baseline are separate. The git log and landed parent status below provide recent-work context, not a measured LOC/day throughput claim.
**Ownership:** planning stops at this Markdown file and one appended JSON feature. No implementation or git writes by the planner. Controller owns all git writes, PR operations and AC15; executor owns targeted local checks; independent evaluator reruns evidence (generator ≠ judge). No direct agent handoff is sent: this mission role explicitly requests only these two artifacts.

## Reality check against HEAD

Read-only planner measurements in this clone, 2026-11-04; commands and observed output follow. Tabs in quoted output are displayed as four spaces. The known-positive `CLAUDE.md` listing accompanies the empty initial status, and the tracked design listing controls the diff list. No Godot or make target that launches Godot was run. Such runs are **UNINFORMATIVE UNDER SANDBOX**; all runtime expectations later in this plan are design evidence and executor/controller work, not planner test results.

```sh
git branch --show-current; git rev-parse HEAD origin/main; git status --porcelain; git ls-files --error-unmatch CLAUDE.md
```

Observed:

```text
feat/m4-7x-b2-script-gates
8bbc6e585f806745b04641677571f1f9cf613637
9e4d8231766e93d6a7657859fab2066b4af9fc56
CLAUDE.md
```

```sh
git diff --name-only origin/main; git ls-files --error-unmatch design_docs/planned/r1/m4-7x-b2-script-gates.md
```

Observed:

```text
design_docs/planned/r1/m4-7x-b2-script-gates.md
design_docs/planned/r1/m4-7x-b2-script-gates.md
```

```sh
grep -n -- '--script' mk/ism.mk mk/planet-presentation.mk mk/star-surfaces.mk mk/navigation-usability.mk mk/constellations.mk mk/npc-painted.mk mk/commons-civic.mk mk/captain-anim.mk mk/style.mk | sed -E 's/ >.*$//'
```

Observed:

```text
mk/ism.mk:36:    @env -u AI_LIVE $(GODOT_SIM) --headless --path . --quit-after 3 --script tools/ism_service_bench.gd
mk/ism.mk:42:    @$(GODOT) --headless --path . --script tests/test_dust_flash.gd
mk/ism.mk:47:    @$(GODOT) --headless --path . --script tests/test_ism_layer.gd
mk/ism.mk:76:    @$(GODOT) --headless --path . --script tests/test_bubble_surface.gd
mk/ism.mk:82:    @$(GODOT) --headless --path . --script tests/test_ism_surfaces.gd
mk/planet-presentation.mk:4:    @AILANG_BIN="$$(command -v $(AILANG))" perl -e 'alarm 120; exec @ARGV' $(GODOT) --headless --path . --script tests/test_planet_presentation.gd
mk/planet-presentation.mk:6:    @$(GODOT_SIM) --headless --path . --script tests/test_moon_lifecycle.gd
mk/planet-presentation.mk:8:    @$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/planet_transition_golden.gd
mk/planet-presentation.mk:10:    @$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/planet_bounds_golden.gd
mk/planet-presentation.mk:12:    @$(GODOT_SIM) --headless --path . --script tools/planet_cpu_bench.gd
mk/planet-presentation.mk:17:    @$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/glow_planet_golden.gd
mk/planet-presentation.mk:21:    @AILANG_BIN="$$(command -v $(AILANG))" perl -e 'alarm 120; exec @ARGV' $(GODOT) --headless --path . --script tests/test_exposure_frames.gd
mk/planet-presentation.mk:23:    @$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/exposure_frame_capture.gd
mk/planet-presentation.mk:28:    @AILANG_BIN="$$(command -v $(AILANG))" perl -e 'alarm 120; exec @ARGV' $(GODOT) --headless --path . --script tests/test_manual_exposure.gd
mk/planet-presentation.mk:33:    @$(GODOT_SIM) --headless --path . --script tools/exposure_cpu_bench.gd
mk/star-surfaces.mk:20:    @perl -e 'alarm 900; exec @ARGV' $(GODOT) --headless --path . --script tests/test_star_surface.gd
mk/star-surfaces.mk:29:    @$(GODOT_SIM) $(AUDIO_OFF) --path . --rendering-driver vulkan --script tools/star_surface_bench.gd -- $(if $(BENCH_SIZE),--bench-size=$(BENCH_SIZE))
mk/star-surfaces.mk:35:    @$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/star_surface_capture.gd
mk/navigation-usability.mk:3:    @$(GODOT_SIM) --headless --path . --script tests/test_navigation_usability.gd
mk/constellations.mk:4:    @$(GODOT_SIM) --headless --path . --quit-after 1200 --script tests/test_constellations.gd
mk/constellations.mk:6:    @$(GODOT) $(AUDIO_OFF) --path . --quit-after 5000 --script tools/constellation_capture.gd -- golden
mk/constellations.mk:8:    @$(GODOT) $(AUDIO_OFF) --path . --quit-after 5000 --script tools/constellation_capture.gd -- capture
mk/constellations.mk:10:    @$(GODOT) $(AUDIO_OFF) --path . --quit-after 5000 --script tools/constellation_capture.gd -- bench
mk/npc-painted.mk:4:    @$(GODOT) --headless --path . --log-file $(SCRATCH)/npc-ingest-engine.log --script tools/npc_painted_assets.gd -- --ingest
mk/npc-painted.mk:7:    @$(GODOT) --headless --path . --log-file $(SCRATCH)/npc-assets-engine.log --script tools/npc_painted_assets.gd
mk/npc-painted.mk:10:    @$(GODOT) --headless --path . --log-file $(SCRATCH)/npc-pilot-engine.log --script tests/test_painted_npc_pilot.gd
mk/npc-painted.mk:13:    @$(GODOT) $(AUDIO_OFF) --path . --log-file $(SCRATCH)/npc-capture-engine.log --script tools/npc_painted_capture.gd
mk/commons-civic.mk:4:    @$(GODOT) --headless --path . --script tools/commons_civic_stage.gd
mk/commons-civic.mk:7:    @$(GODOT) --headless --path . --script tests/test_commons_civic_assets.gd
mk/commons-civic.mk:11:    @$(GODOT_SIM) --headless --path . --script tests/test_commons_civic_playtest.gd
mk/captain-anim.mk:6:    @$(GODOT) --headless --path . --script tests/test_captain_anim.gd
mk/captain-anim.mk:11:    @$(GODOT) --headless --path . --script tests/test_bridge_operator_contact.gd -- --installed
mk/captain-anim.mk:16:    @$(GODOT) --headless --path . --script tools/captain_frames.gd -- --json $(SCRATCH)/captain-frames.json
mk/captain-anim.mk:17:    @$(GODOT) --headless --path . --script tools/captain_frames.gd -- --selftest
mk/captain-anim.mk:20:    @$(GODOT) --headless --path . --script tools/captain_frames.gd -- --ingest $(RAW) --guides $(GUIDES) --json $(SCRATCH)/captain-frames-ingest.json
mk/captain-anim.mk:26:    @$(GODOT_SIM) --headless --path . --script tests/test_captain_chair.gd
mk/style.mk:6:    @$(GODOT) --headless --path . --script tests/test_style.gd
mk/style.mk:10:    @$(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --strict
mk/style.mk:11:    @$(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --strict --scan=res://tests/fixtures/ui_theme/seeded_override.gd
mk/style.mk:12:    @$(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --theme-builder=res://tests/fixtures/ui_theme/low_contrast_theme.gd
mk/style.mk:17:    @$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/style_capture.gd -- --tag=$(TAG) $(if $(wildcard renders/style/before/bow_deep.png),--before=res://renders/style/before)
mk/style.mk:21:    @$(GODOT) --headless --path . --script tests/test_dressing.gd
```

```sh
grep -n -- '--script' mk/ism.mk mk/planet-presentation.mk mk/star-surfaces.mk mk/navigation-usability.mk mk/constellations.mk mk/npc-painted.mk mk/commons-civic.mk mk/captain-anim.mk mk/style.mk | wc -l; grep -c -- '--script' mk/ism.mk mk/planet-presentation.mk mk/star-surfaces.mk mk/navigation-usability.mk mk/constellations.mk mk/npc-painted.mk mk/commons-civic.mk mk/captain-anim.mk mk/style.mk
```

Observed:

```text
      42
mk/ism.mk:5
mk/planet-presentation.mk:10
mk/star-surfaces.mk:3
mk/navigation-usability.mk:1
mk/constellations.mk:4
mk/npc-painted.mk:4
mk/commons-civic.mk:3
mk/captain-anim.mk:6
mk/style.mk:6
```

```sh
grep -vc '^#' tools/script-gate-baseline.txt; wc -l tools/script-gate-baseline.txt; sed -n '8,12p;30p' mk/script-gates.mk
```

Observed:

```text
232
     235 tools/script-gate-baseline.txt
# Rows of tools/script-gate-baseline.txt: the --script invocations not yet through $(SCRIPT_GATE). A migration
# deletes its rows and lowers this pin with them; script-gate-lint fails on any mismatch, so it never rises
# unseen. 237 at the 7x snapshot (78f390c0), 232 after this sprint's five gates.
SCRIPT_GATE_BASELINE_ROWS := 232
SG_LINT = SCRIPT_GATE_BASELINE_ROWS=$(SCRIPT_GATE_BASELINE_ROWS) sh $(SG_TOOLS)/script_gate_lint.sh
      test "$$(grep -c '^script-gate-lint: unguarded' $$L)" = 2 && grep -q 'not on the baseline: bare-new tests/y.gd$$' $$L && grep -q 'not on the baseline: mixed tests/m2.gd$$' $$L \
```

```sh
grep -n 'print' tests/test_star_surface.gd tools/captain_frames.gd tools/ui_theme_check.gd tools/planet_cpu_bench.gd tools/exposure_cpu_bench.gd
```

Observed:

```text
tests/test_star_surface.gd:11:        print("  ok    %s" % name)
tests/test_star_surface.gd:14:        print("  FAIL  %s %s" % [name, detail])
tests/test_star_surface.gd:22:    print("star-surface test (R2-STAR-SURFACES SS2)")
tests/test_star_surface.gd:35:    print("star-surface: %s (%d failures)" % ["OK" if failures == 0 else "FAIL", failures])
tools/captain_frames.gd:92:        print("captain-frames: selftest ok" if ok else "captain-frames: FAIL selftest")
tools/captain_frames.gd:94:        print("captain-frames: ok" if ok else "captain-frames: FAIL")
tools/captain_frames.gd:203:    print("ingest: %d frames -> %s" % [plan.painted.size(), out_dir])
tools/captain_frames.gd:433:    print("selftest: recoloured %s, wrong pose %s, wrong scale %s, sunk sole %s" % ["fails" if not r1.ok else "PASSES", "fails" if not wrong.ok else "PASSES", "fails" if not r3.ok else "PASSES", "fails" if sunk else "PASSES"])
tools/captain_frames.gd:543:    print("FAIL ", msg)
tools/captain_frames.gd:726:    print("settle: %d frames on the deck line" % moved.size())
tools/ui_theme_check.gd:30:    print("FAIL " + msg)
tools/ui_theme_check.gd:62:        print("leftover %s: %d" % [f, per_file[f]])
tools/ui_theme_check.gd:66:        print("ui-theme-check: leftovers %d in %d files (%s)" % [total, per_file.size(), "strict" if strict else "report until ST4"])
tools/ui_theme_check.gd:98:        print("ui-theme-check: contrast checked for %d text/panel pairs over night and cream" % pairs.size())
tools/ui_theme_check.gd:99:    print("ui-theme-check: %s" % ("FAIL" if fails else "ok"))
tools/planet_cpu_bench.gd:32:    var out:=FileAccess.open("res://renders/perf/planet_cpu.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"  "));print(JSON.stringify(report))
tools/exposure_cpu_bench.gd:8:    if not sim.start() or not sim.new_game(19):print("exposure-cpu-bench: FAIL ",sim.last_error);quit(1);return
tools/exposure_cpu_bench.gd:30:        results.append(record);print(record)
tools/exposure_cpu_bench.gd:34:    print("exposure-cpu-bench: OK");quit(0)
```

```sh
grep -nE '^(GODOT|GODOT_SIM|SCRATCH)' Makefile; sed -n '3p' mk/constellations.mk; grep -n 'mkdir\|dirname' tools/script_gate.sh; grep -nE '^test-script-gate:|^script-gate-(selftest|drill):' Makefile mk/*.mk
```

Observed:

```text
1:GODOT ?= godot
6:GODOT_SIM = AILANG_BIN="$$(command -v $(AILANG))" $(GODOT)
13:SCRATCH := .godot/tmp
constellation-test: import
26:mkdir -p "$(dirname "$log")"
mk/script-gates.mk:42:script-gate-selftest: ## tools/script_gate.sh on stub commands (no Godot): pass, SCRIPT ERROR, hang past the timeout, a command that ignores TERM/ALRM, an orphan child, no summary, a 0 count, wrong rc, env passthrough, bad arguments
mk/script-gates.mk:45:script-gate-drill: ## + real Godot: the premise (a parse error exits 0), parse-error, runtime-error hang and no-summary fixtures, and make sim's own gate on the parse fixture
```

```sh
git log -6 --oneline; jq '.features[-1] | {id,status,estimated_loc}' .ailang/state/sprints/sprint_R1-M4-JOURNEY.json; jq '.features|length' .godot/tmp/iter70-planner/sprint_R1-M4-JOURNEY.before.json
```

Observed:

```text
8bbc6e58 design: row 7x B2, quorum round 2 carve-out (V21 revision-1 numstat and gates, reviewer fixes)
2db488f0 design: row 7x B2 revision 1 (quorum round 1: mkdir evidence, B2b out of the normative design, per-count zero probe)
419b6dcb design: row 7x batch B2 (nine mk files through $(SCRIPT_GATE), the two judge survivors)
9e4d8231 Merge pull request #394 from sunholo-data/mission/stapledon-iter69-7x-land
c1bcf5b3 mission: record iteration 69, row 7x landed (#393, 49eb35d9), D-145 for the nightly sound-test red
49eb35d9 Merge pull request #393 from sunholo-data/feat/m4-7x-script-gate-predicates
{
  "id": "M4.6sR3_7x_SCRIPT_GATE_PREDICATES",
  "status": "landed",
  "estimated_loc": 300
}
24
```

```sh
gh pr list --state open --json number --limit 10; echo gh_rc=$?; git log -1 --format='%h %s'
```

Observed:

```text
error connecting to api.github.com
check your internet connection or https://githubstatus.com
gh_rc=1
8bbc6e58 design: row 7x B2, quorum round 2 carve-out (V21 revision-1 numstat and gates, reviewer fixes)
```

```sh
sed -n '20,23p' mk/star-surfaces.mk; sed -n '14,17p' mk/captain-anim.mk; sed -n '10,13p' mk/style.mk; sed -n '33,42p' tools/script_gate.sh; sed -n '39,45p' tools/test_script_gate.sh
```

Observed:

```text
    @perl -e 'alarm 900; exec @ARGV' $(GODOT) --headless --path . --script tests/test_star_surface.gd > $(SCRATCH)/star-surfaces/test.log 2>&1; rc=$$?; \
      grep -E '^  (ok|FAIL)|^star-surface' $(SCRATCH)/star-surfaces/test.log; \
      ! grep -q 'SCRIPT ERROR' $(SCRATCH)/star-surfaces/test.log || { grep -A2 'SCRIPT ERROR' $(SCRATCH)/star-surfaces/test.log | head -20; echo "star-surface: FAIL (script error)"; exit 1; }; \
      test $$rc = 0 && grep -q '^star-surface: OK (0 failures)$$' $(SCRATCH)/star-surfaces/test.log
captain-frames-check: import ## AC4, AC5: every painted frame against its guide (silhouette IoU) and the stage-0 stills (palette dE), scale consistency, cell geometry, disk and GPU budgets; then the seeded defects (recoloured, wrong pose, wrong scale) must fail
    @mkdir -p $(SCRATCH)
    @$(GODOT) --headless --path . --script tools/captain_frames.gd -- --json $(SCRATCH)/captain-frames.json > $(SCRATCH)/captain-frames.log 2>&1; rc=$$?; grep -E '^(FAIL|captain-frames)' $(SCRATCH)/captain-frames.log; test $$rc = 0 && grep -q '^captain-frames: ok$$' $(SCRATCH)/captain-frames.log
    @$(GODOT) --headless --path . --script tools/captain_frames.gd -- --selftest > $(SCRATCH)/captain-frames-selftest.log 2>&1; rc=$$?; grep -E '^(selftest|captain-frames)' $(SCRATCH)/captain-frames-selftest.log; test $$rc = 0 && grep -q '^captain-frames: selftest ok$$' $(SCRATCH)/captain-frames-selftest.log
    @$(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --strict > $(SCRATCH)/ui-theme-check.log 2>&1; rc=$$?; grep -E '^(FAIL|leftover|ui-theme-check)' $(SCRATCH)/ui-theme-check.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/ui-theme-check.log && grep -q '^ui-theme-check: ok$$' $(SCRATCH)/ui-theme-check.log
    @$(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --strict --scan=res://tests/fixtures/ui_theme/seeded_override.gd > $(SCRATCH)/ui-theme-neg-override.log 2>&1; rc=$$?; test $$rc = 1 && grep -q '^FAIL 1 hard-coded panel styles' $(SCRATCH)/ui-theme-neg-override.log || { echo "ui-theme-check: FAIL negative control (seeded StyleBoxFlat) passed"; exit 1; }
    @$(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --theme-builder=res://tests/fixtures/ui_theme/low_contrast_theme.gd > $(SCRATCH)/ui-theme-neg-contrast.log 2>&1; rc=$$?; test $$rc = 1 && grep -q '^FAIL contrast' $(SCRATCH)/ui-theme-neg-contrast.log || { echo "ui-theme-check: FAIL negative control (low contrast) passed"; exit 1; }
    @echo "ui-theme-check: negative controls (seeded StyleBoxFlat, low contrast) fail as they must"
elif [ "$rc" -ne "$want" ]; then why="$why; rc $rc, want $want"; fi
se=$(grep -c 'SCRIPT ERROR' "$log")
[ "$se" -eq 0 ] || why="$why; $se SCRIPT ERROR line(s) (Godot exits 0 on a parse error)"
line=$(grep -E -- "$summary" "$log" | tail -n 1)
[ -n "$line" ] || why="$why; no summary line matching $summary (rc $rc with no summary is a load failure, not a result)"
if [ -n "$why" ]; then
  grep -v -E '^[[:space:]]*ok[[:space:]]' "$log" | tail -n 40
  echo "script-gate: $name FAIL$why (log $log)"
  exit 1
fi
case_ stub-env 0 10 'stub-env ok: AB=7x' sh "$gate" stub-env "$tmp/s8.log" 5 '^AB=7x$' -- AB=7x sh -c 'echo "AB=$AB"'
case_ stub-unanchored 2 10 'SUMMARY_ERE must start with ^' sh "$gate" stub-u "$tmp/s9.log" 5 'drill' -- true
case_ stub-notimeout 2 10 'TIMEOUT_S must be at least 1' sh "$gate" stub-t "$tmp/s10.log" 0 "$S" -- true
# A2: a command that ignores SIGALRM and TERM is still stopped at the deadline (group KILL after the TERM grace)
case_ stub-ignore-alrm 1 6 'timeout after 2 s' sh "$gate" stub-ignore-alrm "$tmp/s11.log" 2 "$S" -- sh -c 'trap "" ALRM TERM; exec sleep 30'
# A2: a child left behind by the command is killed with its group; the control proves pgrep can see a sleep.
# The sleep durations are per run (from this shell's pid), so two drills running at once (make -j) never see
```

The nine-file anchors and the 232-row baseline/pin agree with the approved contract. D3's actual pre-edit summary anchors are star surface 35, captain 92/94, UI theme 99, planet CPU 32 and exposure CPU 34; use diff context rather than D3's older hunk offsets. The helper insertion follows its current no-summary check, preserving its landed supervisor. No substantive design premise was found false by these read-only measurements. Runtime premises (including missing-large-tier behavior) have not been re-tested under the sandbox.

**Network:** the failed `gh` call above is not an empty PR set. Use design **V14**, historically: #373/#379/#380/#384 touched 57/99/31/11 files, zero of the 19 here, with positive control matches 2/3/1/1. Controller repeats `gh pr list --state open` and `gh pr diff <n> --name-only` at pickup before editing; report any overlap. Do not silently treat V14 as a fresh network measurement.

## Sequencing note

M1 → M2 → M3 → M4 → M5 → M6. M1/M2 close the helper and fixture survivors before recipes depend on them. M3 adds counts before M4 wraps those scripts. The old star/captain/theme recipe predicates are end-anchored to the old text (measured above), so those make targets are expected to be red between M3 and M4. Verify M3 independently with direct helper calls on the edited scripts, as given below; do not loosen the old recipes or assert they remain green. M4 is one logical ratchet milestone: all 28 rows migrate, all 28 baseline rows are deleted, and pin 232 → 204 moves with them. Do not leave a milestone boundary with a stale baseline or mismatched pin. Never regenerate or expand the remaining baseline.

The recipe for `constellation-test` moves in M4; its prerequisite moves in M5. M4 may explicitly provision `starmap-assets` to exercise that recipe (D2/V6), recording the known prerequisite defect. Full literal AC8 runs after M5, so standalone behavior is verified with the prerequisite fixed. AC6's last count is read only after `make script-gate-lint` has refreshed the fixture log; at M2 its interim lint totals remain 5 gated / 232 baseline. Final AC1/AC2 require M4.

Before any executor runtime check, follow the design preface: `export PATH="$PWD/runtime/bin:$PATH"`, then `make deps import`. These commands, and every Godot-bearing command below, are executor/controller-only outside the planner sandbox (**UNINFORMATIVE UNDER SANDBOX**). Keep long runs serial and poll within bounded loops under a process-group supervisor (landed helper pattern). A bare alarm around make does not reliably clean up children (parent V30/A2). Keep all temporary scripts, mutants and logs under `.godot/tmp/`.

Every milestone has `registry_reuse: none` in the new feature: this work maintains repo-specific build glue and existing GDScript summaries, with no package-like capability. No `.ail` is written, so the skill's AILANG syntax gate is inapplicable. No new example program is needed; the named stub and fixture cases are the runnable examples.

## Milestones (test-first, in dependency order)

### M1 — Helper per-count zero probe and six stub cases, RED before GREEN

**Files/estimate:** `tools/test_script_gate.sh` +7/−0; `tools/script_gate.sh` +17/−0; 24 changed lines, 15 min. Depends on landed parent only.

1. Add all **six** D4 cases verbatim first: loose, weakcount, uncounted, namedigit, twocount and twobound. “Four new cases” in the design's older Goal 3 wording means the original four; revision 1 adds the two-count pair. Keep `stub-want1`, `stub-env`, supervisor and orphan controls intact.
2. RED, before touching the helper: run AC4(a) below against the frozen landed helper and also `make script-gate-selftest > .godot/tmp/b2-m1-red.out 2>&1; echo rc=$?; grep '^test-script-gate: FAIL' .godot/tmp/b2-m1-red.out`. Expected `rc=1`, five failed new cases (loose/weakcount/uncounted/namedigit/twocount), `FAIL 5 of 18 cases`; twobound passes (V19). Record RED in this feature's execution notes.
3. Insert D4's per-count block immediately after the existing no-summary check. Keep usage, log creation, rc/timeout/SCRIPT ERROR checks and supervisor untouched. GREEN: run AC3 verbatim from the acceptance catalogue: eight named control lines, 18/18 stubs and rc 0. AC4(a) must still fail five cases; AC4(b) must fail only twocount, proving why all-at-once is insufficient.
4. Portability supplement (V19): `dash tools/script_gate.sh d5 .godot/tmp/b2-d5.log 5 '^t: [1-9][0-9]* files, [0-9]* pairs$' -- sh -c 'echo "t: 3 files, 4 pairs"'; echo rc=$?` → `SUMMARY_ERE also matches 't: 3 files, 0 pairs' (count 2 zeroed; bind it: [1-9][0-9]*)`, `rc=1`. `dash tools/script_gate.sh d6 .godot/tmp/b2-d6.log 5 '^AB=7x$' -- AB=7x sh -c 'echo "AB=$AB"'; echo rc=$?` → `d6 ok: AB=7x`, `rc=0`. `shellcheck -s sh tools/script_gate.sh tools/test_script_gate.sh; echo rc=$?` → `rc=0`.

**Milestone ACs:** AC3 and AC4. **Pause:** RED/GREEN mismatch, missing positive control or changed supervisor → stop and report; never relax a case or deadline.

### M2 — Lint S1 gate-after fixture and negative-control count 2 to 3

**Files/estimate:** `tests/fixtures/script_gate/lint_negative.mk.txt` +3/−1; `mk/script-gates.mk` control +1/−1; 6 changed lines, 8 min. Depends on M1. The lint implementation is not edited.

1. Add D5's `gate-after` row after quoted-separators, with `$(SCRIPT_GATE)` strictly **between** `$(GODOT)` and `--script`. Update the fixture header to three unguarded rows. RED: `make script-gate-lint; echo rc=$?` while the control still expects 2 → `script-gate-lint: FAIL the negative control flagged the wrong rows`, `rc=2` (the new fixture has 3 unguarded; D5/V11).
2. Update only the control count to 3 and add the exact `gate-after tests/after.gd$$` grep; retain all existing fixture checks. GREEN: `make script-gate-lint; echo rc=$?` → interim `ok (237 --script invocations: 5 through $(SCRIPT_GATE), 232 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`, `rc=0` (base V1 plus D5 fixture). Run AC6 → `7`, `gate-after<TAB>tests/after.gd<TAB>ungated`, `3`; run AC7 → `2`, so the new `=3` control refuses the mutant (V11).

**Milestone ACs:** AC6/AC7 and interim AC1 shape. **Pause:** wrong class/count or a required lint code edit → stop; S1 is a fixture defect.

### M3 — Five counted summaries from D3, including the captain header comment

**Files/estimate:** `tests/test_star_surface.gd` +3/−1; `tools/captain_frames.gd` +2/−2 plus +1/−1 header comment; `tools/ui_theme_check.gd` +5/−1; `tools/planet_cpu_bench.gd` +1/−0; `tools/exposure_cpu_bench.gd` +1/−1. 17 changed code lines plus 2 comment lines, 10 min. Depends on M1/M2.

Use D3's diffs exactly, at the contexts measured above: count successful star checks, `report.frames.size()` for both captain modes, `scanned` after exclusions and `pairs.size()` for UI theme, `rows.size()` for planet CPU and `results.size()` for exposure CPU. Update captain's “Prints” comment too. No checks, thresholds, loop bodies beyond increments, JSON layout or failure behavior change.

**Test-first/verification:** the read-only pre-edit print lines above establish the absent counts. Before the edits, these D2 direct helper calls reject the old uncounted summaries (missing-summary failure); after D3, each returns rc 0 and prints its new counted summary. These calls validate M3 without depending on M4's recipe replacements. Executor/controller only:

```sh
sh tools/script_gate.sh star-surface-test .godot/tmp/star-surfaces/test.log 900 '^star-surface: OK \([1-9][0-9]* passed, 0 failures\)$' -- godot --headless --path . --script tests/test_star_surface.gd; echo rc=$?
sh tools/script_gate.sh captain-frames-check .godot/tmp/captain-frames.log 600 '^captain-frames: ok \([1-9][0-9]* frames\)$' -- godot --headless --path . --script tools/captain_frames.gd -- --json .godot/tmp/captain-frames.json; echo rc=$?
sh tools/script_gate.sh captain-frames-selftest .godot/tmp/captain-frames-selftest.log 600 '^captain-frames: selftest ok \([1-9][0-9]* frames\)$' -- godot --headless --path . --script tools/captain_frames.gd -- --selftest; echo rc=$?
sh tools/script_gate.sh ui-theme-check .godot/tmp/ui-theme-check.log 600 '^ui-theme-check: ok \([1-9][0-9]* files, [1-9][0-9]* text/panel pairs\)$' -- godot --headless --path . --script tools/ui_theme_check.gd -- --strict; echo rc=$?
sh tools/script_gate.sh planet-cpu-bench .godot/tmp/planet-cpu-bench.log 600 '^planet-cpu-bench: [1-9][0-9]* rows, renders/perf/planet_cpu.json$' -- "AILANG_BIN=$(command -v ailang)" godot --headless --path . --script tools/planet_cpu_bench.gd; echo rc=$?
sh tools/script_gate.sh exposure-cpu-bench .godot/tmp/exposure-cpu-bench.log 600 '^exposure-cpu-bench: OK [1-9][0-9]* profiles, renders/perf/exposure_cpu.json$' -- "AILANG_BIN=$(command -v ailang)" godot --headless --path . --script tools/exposure_cpu_bench.gd; echo rc=$?
```

Expected after D3: six rc 0s and ok lines carrying `star-surface: OK (54 passed, 0 failures)`, captain `ok (50 frames)` and `selftest ok (50 frames)`, UI `ok (49 files, 65 text/panel pairs)`, exposure `OK 2 profiles, renders/perf/exposure_cpu.json`, planet `6 rows, renders/perf/planet_cpu.json` (D3/V7/V8). Run AC12 → five zero lines (the final grep's rc 1 is expected for a rejected match). Compare `grep -c '^  ok' .godot/tmp/star-surfaces/test.log` → 54, `jq '.frames | length' .godot/tmp/captain-frames.json` → 50, and `grep 'contrast checked' .godot/tmp/ui-theme-check.log` → 65 pairs, the independent controls from V8. Counts may only grow; a smaller value is a finding.

**Milestone AC:** AC12 plus the five live summary controls. **Pause:** a count needs an assertion, data or B2b recipe change → stop and report.

### M4 — 28 B2a recipe migrations in nine files, baseline minus 28 and pin 232 to 204

**Files/estimate:** the nine mk files, `tools/script-gate-baseline.txt`, `mk/script-gates.mk` pin/comment; 67 hand-written changed lines plus 28 deleted rows, 25 min. Depends on M1–M3. The constellation prerequisite hunk is reserved for M5; this milestone owns its recipe.

Copy **only** D2's 28 exact recipe lines, preserving real recipe tabs. Preserve command token, flags, arguments, log paths, outer mkdir lines except the two explicit ism removals, .PHONY/dependency joins, style closing echo and every B2b line. The three `alarm 120` prefixes become `$(GODOT_SIM)` exactly as D1/D2 specify. Replace the star recipe's entire four-line alarm/check block; its helper deadline is 900. Moon's deadline is 1800; all other rows 600. Only the two UI negative controls use WANT_RC 1.

File-by-file edit and targeted runtime verification (all commands are executor/controller work). Each command ends `> .godot/tmp/b2-m4-N.out 2>&1; echo rc=$?; grep '^script-gate:' .godot/tmp/b2-m4-N.out`, substituting the numbered N below. Expected rc 0, the named gate lines with AC8's summaries, and no failed gate. These are subsets of AC8, whose complete command/output is in the catalogue.

| N | File; old recipe line anchors | Exact make command before the common capture/check tail | Expected own gate names/counts (AC8/V7/V20) |
|---|---|---|---|
| 1 | `mk/ism.mk`: 42,47,76,82 | `make dust-flash-test map-ism-test bubble-surface-test ism-surfaces-test` | 4: dust 29, ism-layer 22, bubble 16, surfaces 18 |
| 2 | `mk/planet-presentation.mk`: 4,6,12,21,28,33 | `make planet-presentation-test moon-lifecycle-test planet-cpu-bench exposure-frames-test manual-exposure-test exposure-cpu-bench` | 6: 806 checks, 71 checks, 6 rows, 1364 checks, 291 checks, 2 profiles |
| 3 | `mk/star-surfaces.mk`: 20–23 | `make star-surface-test` | 1: 54 passed |
| 4 | `mk/navigation-usability.mk`: 3 | `make navigation-usability-test` | 1: 17 checks |
| 5 | `mk/constellations.mk`: 4 | `make starmap-assets constellation-test` | 1: 35 passed; explicit tier provisioning is D2/V6's known pre-M5 condition |
| 6 | `mk/npc-painted.mk`: 7,10 | `make npc-painted-assets-check npc-painted-test` | 2: 5 identities/25 poses; 23 passed; keep both --log-file flags |
| 7 | `mk/commons-civic.mk`: 4,7,11 | `make commons-civic-stage commons-civic-assets-check commons-civic-playtest-test` | 3 distinct: 4 configs/3 raw GLBs/4 raw PNGs; 21; 18; prerequisite stage may repeat |
| 8 | `mk/captain-anim.mk`: 6,11,16,17,26 | `make captain-anim-test bridge-operator-test captain-frames-check captain-chair-test` | 5: 87; 44 (--installed retained); 50 frames each under check/selftest names; 12 |
| 9 | `mk/style.mk`: 6,10,11,12,21 | `make style-test ui-theme-check dressing-test` | 5: 22; 49 files/65 pairs; negative override and contrast ok at rc 1; 10 |

Baseline operation, in this same milestone: create `.godot/tmp/b2a-targets.txt` with exactly these 25 names (one per line):

```text
dust-flash-test
map-ism-test
bubble-surface-test
ism-surfaces-test
planet-presentation-test
moon-lifecycle-test
planet-cpu-bench
exposure-frames-test
manual-exposure-test
exposure-cpu-bench
star-surface-test
navigation-usability-test
constellation-test
npc-painted-assets-check
npc-painted-test
commons-civic-stage
commons-civic-assets-check
commons-civic-playtest-test
captain-anim-test
bridge-operator-test
captain-frames-check
captain-chair-test
style-test
ui-theme-check
dressing-test
```

```sh
wc -l .godot/tmp/b2a-targets.txt
awk -F'\t' 'FNR==NR{d[$1]=1;next} !/^#/ && ($1 in d)' .godot/tmp/b2a-targets.txt tools/script-gate-baseline.txt | wc -l
awk -F'\t' 'FNR==NR{d[$1]=1;next} /^#/ || !($1 in d)' .godot/tmp/b2a-targets.txt tools/script-gate-baseline.txt > .godot/tmp/b2-baseline.new
mv .godot/tmp/b2-baseline.new tools/script-gate-baseline.txt
grep -vc '^#' tools/script-gate-baseline.txt
```

Expected `25`, `28` before deletion, then `204` (D6). Delete **all** rows of captain-frames-check and ui-theme-check (2 and 3), keyed on target/script, not helper NAME. Set `SCRIPT_GATE_BASELINE_ROWS := 204` and the D6 comment `… 232 after its five gates, 204 after B2a (28 rows in nine mk files).` Run AC1 and AC2 verbatim → 237 total, 33 gated, 204 baseline, 22 includes, 23 makefiles, rc 0; pin 205 refuses the mismatch with Error 1. Run `git diff --numstat -- tools/script-gate-baseline.txt` → `0 28 tools/script-gate-baseline.txt` and `git diff -- mk/script-gates.mk` → only D5 control plus D6 comment/pin changes.

**Milestone ACs:** AC1/AC2 and AC8's per-file subsets. Full literal AC8 follows M5. **Pause:** wrong row arithmetic, changed Godot command, changed B2b recipe or lower live count → stop, report drift, do not invent a wider migration or increase the pin.

### M5 — Constellation starmap-assets prerequisite and AC16 fresh-SCRATCH run

**Files/estimate:** `mk/constellations.mk` prerequisite +1/−1; 2 changed lines, 7 min. Depends on M4.

RED premise is the measured `constellation-test: import` above and the design's V6 fresh-clone rc 2/34 passed/1 failure without the large tier. Do not remove an existing tier or fake this defect away. Change only the prerequisite to D2's `constellation-test: import starmap-assets`. `grep -n '^constellation-test:' mk/constellations.mk` → `3:constellation-test: import starmap-assets`. Executor runs `make constellation-test > .godot/tmp/b2-m5-constellation.out 2>&1; echo rc=$?; grep -E '^starmap-assets:|^script-gate: constellation-test' .godot/tmp/b2-m5-constellation.out` → `rc=0`, `starmap-assets: tiers match data/starmap/SHA256SUMS`, `constellation-test ok: constellations: 35 passed, 0 failures` (V6/V20). A missing tier fetch is a public-bucket read, never upload; retain the sha check.

Run literal AC16 from the catalogue with a fresh `F` → `absent`, all three ok lines (29/22/54), rc 0 and the three logs including nested `star-surfaces/test.log`. Save the same run unfiltered as well and record the make rc, so the pipeline's grep rc cannot hide failure. An `exists` first line invalidates the fresh-directory control; choose another absent path, without deleting an unrelated directory. Helper `mkdir -p "$(dirname "$log")"` is the reason D1's two mkdir removals are safe, verified in V17/V18; this is mandatory evidence.

Run full literal AC8 now → rc 0, 28 distinct names, zero FAIL, every summary at least the AC8 count. **Milestone ACs:** AC8 and AC16. **Pause:** missing asset/fetch, nonfresh control or missing nested log → stop and report, never lower a count or restore redundant mkdir as a workaround.

### M6 — Complete AC1-AC16 evidence, Godot drills, policy gates and controller fast tier

**Files/estimate:** no implementation edits, 0 LOC, 25 min. Depends on M5. Append command/rc/key output evidence only to this feature's execution notes; keep passes false until independent evaluation. Do not modify the previous 24 features.

Run the catalogue in this order: AC1/AC2 → AC3/AC4 → AC6/AC7 → AC12 → AC8/AC16 evidence review → AC9 → AC5/AC10/AC11 → AC13/AC14 → controller AC15. Reuse complete earlier passing logs where nothing relevant changed; rerun after changes. AC3/AC5 literal pipelines report the last filter's rc: additionally save full unfiltered make output and its rc; require both the footer and rc 0. AC10's four parse-error classes and AC11's runtime gap must be reproduced; the intended drill FAIL lines are required successes of the guard, not a reason to discard output. AC8's zero FAIL count must be paired with its 28-name positive control.

The numbered acceptance catalogue below is part of this milestone and is the exact command/expected contract for every earlier milestone too. AC4 includes the concrete scratch construction for its prose-defined second mutant. AC15 stays pending for the controller until GitHub checks succeed; no feature is marked passed on an unrun AC. No full `make test` is required from the executor: targeted gates here, GitHub `ci-fast` on the PR, nightly main `rig/full` per CLAUDE.md. No dev-build/visual review is engaged by this nonvisual hygiene change.

## Acceptance catalogue (design AC1-AC16)

These are future executor/controller checks, **not planner-run results**. Pipe characters escaped in the Markdown design table are rendered as executable pipes below. Expected counts may grow, but may not shrink; changes to the 237/33/204 relation require reporting base drift. Keep the command's full output and true make rc alongside filtered views.

### AC1

```sh
make script-gate-lint; echo rc=$?
```

Expected: script-gate-lint: ok (237 --script invocations: 33 through $(SCRIPT_GATE), 204 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned), rc=0 (V12 on revision 0; V21 on revision 1)

### AC2

```sh
make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=205 2>&1 | tail -2
```

Expected: the baseline has 204 rows but SCRIPT_GATE_BASELINE_ROWS is 205: the pin moves with the rows, and only down, make: *** [script-gate-lint] Error 1 (V12; V21)

### AC3

```sh
make script-gate-selftest 2>&1 | grep -E 'stub-(loose|weakcount|uncounted|namedigit|twocount|twobound|want1|env)|cases'; echo rc=$?
```

Expected: ok   stub-loose (exit 1 …: SUMMARY_ERE also matches), ok   stub-weakcount (…), ok   stub-uncounted (exit 1 …: carries no nonzero count), ok   stub-namedigit (…), ok   stub-twocount (exit 1 …: count 2 zeroed), ok   stub-twobound (exit 0 …: stub-twobound ok: t: 3 files, 4 pairs), ok   stub-want1 …, ok   stub-env …, test-script-gate: ok (18 cases: 18 stub, 0 Godot) (V19)

### AC4

```sh
git show origin/main:tools/script_gate.sh > .godot/tmp/b2-old-gate.sh; SCRIPT_GATE_SH=.godot/tmp/b2-old-gate.sh SCRIPT_GATE_TMP=.godot/tmp/b2-ac4 sh tools/test_script_gate.sh > .godot/tmp/b2-ac4.out 2>&1; echo rc=$?; grep -c '^test-script-gate: FAIL stub-' .godot/tmp/b2-ac4.out
cat > .godot/tmp/b2-zero-block.txt <<'B2ZERO'
if [ -n "$line" ] && [ "$want" -eq 0 ]; then
  zero=$(printf '%s\n' "$line" | sed -E 's/(^|[^A-Za-z0-9_.-])[0-9]+/\10/g')
  if [ "$zero" = "$line" ]; then why="$why; carries no nonzero count"
  elif printf '%s\n' "$zero" | grep -qE -- "$summary"; then why="$why; SUMMARY_ERE also matches the zeroed line"; fi
fi
B2ZERO
awk '
  /^# Zero probe/ { skip=1 }
  skip && /^if \[ -n "\$why" \]; then/ { skip=0 }
  !skip && /^if \[ -n "\$why" \]; then/ { while ((getline extra < ".godot/tmp/b2-zero-block.txt") > 0) print extra }
  !skip { print }
' tools/script_gate.sh > .godot/tmp/b2-all-at-once.sh
SCRIPT_GATE_SH=.godot/tmp/b2-all-at-once.sh SCRIPT_GATE_TMP=.godot/tmp/b2-ac4b sh tools/test_script_gate.sh > .godot/tmp/b2-ac4b.out 2>&1
echo rc=$?
grep '^test-script-gate: FAIL' .godot/tmp/b2-ac4b.out
```

Expected: (a) rc=1, 5 (loose, weakcount, uncounted, namedigit, twocount). (b) rc=1, exactly FAIL stub-twocount: exit 0 … and FAIL 1 of 18 cases (V19)

### AC5

```sh
make script-gate-drill 2>&1 | tail -1; echo rc=$?
```

Expected: test-script-gate: ok (24 cases: 18 stub, 6 Godot), rc=0 (V20)

### AC6

```sh
SCRIPT_GATE_FILES=tests/fixtures/script_gate/lint_negative.mk.txt SCRIPT_GATE_BASELINE_ROWS=0 sh tools/script_gate_lint.sh --inventory | cut -f2-4 | grep -c .; SCRIPT_GATE_FILES=tests/fixtures/script_gate/lint_negative.mk.txt SCRIPT_GATE_BASELINE_ROWS=0 sh tools/script_gate_lint.sh --inventory | cut -f2-4 | grep after; grep -c '^script-gate-lint: unguarded' .godot/tmp/script-gate/lint-negative.log
```

Expected: 7; gate-after tests/after.gd ungated (tab-separated); 3 (V11, V12)

### AC7

```sh
sed 's/(sg \&\& sg < g + 1) ? "gated"/sg ? "gated"/' tools/script_gate_lint.sh > .godot/tmp/b2-lint-mut.sh; SCRIPT_GATE_FILES=tests/fixtures/script_gate/lint_negative.mk.txt SCRIPT_GATE_BASELINE=tests/fixtures/script_gate/lint_negative_baseline.txt SCRIPT_GATE_BASELINE_ROWS=2 SCRIPT_GATE_ALL_MAKEFILES="tests/fixtures/script_gate/lint_negative.mk.txt tools/stray.mk" sh .godot/tmp/b2-lint-mut.sh | grep -c '^script-gate-lint: unguarded'
```

Expected: 2 (the control in make script-gate-lint requires 3, so this mutant fails it; V11)

### AC8

```sh
make dust-flash-test map-ism-test bubble-surface-test ism-surfaces-test planet-presentation-test moon-lifecycle-test planet-cpu-bench exposure-frames-test manual-exposure-test exposure-cpu-bench star-surface-test navigation-usability-test constellation-test npc-painted-assets-check npc-painted-test commons-civic-stage commons-civic-assets-check commons-civic-playtest-test captain-anim-test bridge-operator-test captain-frames-check captain-chair-test style-test ui-theme-check dressing-test > .godot/tmp/b2-ac8.out 2>&1; echo rc=$?; grep '^script-gate:' .godot/tmp/b2-ac8.out | sort -u -t: -k2,2 | wc -l; grep -c 'script-gate: [^ ]* FAIL' .godot/tmp/b2-ac8.out
```

Expected: rc=0; 28 distinct gate names, one ok line each (commons-civic-stage also runs as a prerequisite; sort -u keeps one), with the counts of V7: dust-flash: 29 passed, ism-layer: 22, bubble-surface: 16 checks, ism-surfaces: 18 checks, planet-presentation: 806 checks, moon-lifecycle: 71 checks, planet-cpu-bench: 6 rows, exposure-frames: 1364 checks, manual-exposure: 291 checks, exposure-cpu-bench: OK 2 profiles, star-surface: OK (54 passed, navigation-usability: 17 checks, constellations: 35 passed, painted-npc-assets: 5 identities, 25 poses, painted-npc-pilot: 23, commons-civic-stage: 4 configs …, commons-civic-assets: 21, commons-civic-playtest: 18, captain-anim: 87, bridge-operator-contact: 44, captain-frames: ok (50 frames), captain-frames: selftest ok (50 frames), captain-chair: 12, style-test: 22, ui-theme-check: ok (49 files, 65 text/panel pairs), ui-theme-neg-override ok: FAIL 1 hard-coded … (rc 1), ui-theme-neg-contrast ok: FAIL contrast … (rc 1), dressing-test: 10; then 0. Budget about 7 min wall; moon-lifecycle-test alone is about 220 s.

### AC9

```sh
make ui area-test test-bright-audit star-catalogue-test sim-bridge 2>&1 | grep '^script-gate:'
```

Expected: 5 ok lines: galaxy map: 205 passed, 80 passed, 0 failed, test_bright_audit: 16 passed, test_star_catalogue: 40 passed, sim bridge: 110 passed (V7b)

### AC10

```sh
d=.godot/tmp/b2drill; mkdir -p $d; for p in tests/test_dust_flash.gd:c1 tests/test_navigation_usability.gd:c2 tools/captain_frames.gd:c3 tools/ui_theme_check.gd:c4; do awk 'NR==1{print; print "var _b2_drill: int = undefined_name_b2"; next} {print}' ${p%%:*} > $d/${p##*:}.gd; done; AB="AILANG_BIN=$(command -v ailang)"; sh tools/script_gate.sh c1 $d/c1.log 600 '^dust-flash: [1-9][0-9]* passed, 0 failures$' -- godot --headless --path . --script $d/c1.gd; echo rc=$?; sh tools/script_gate.sh c2 $d/c2.log 600 '^navigation-usability: [1-9][0-9]* checks 0 failures$' -- "$AB" godot --headless --path . --script $d/c2.gd; echo rc=$?; sh tools/script_gate.sh c3 $d/c3.log 600 '^captain-frames: selftest ok \([1-9][0-9]* frames\)$' -- godot --headless --path . --script $d/c3.gd -- --selftest; echo rc=$?; sh tools/script_gate.sh c4 $d/c4.log 600 '^FAIL contrast' 1 -- godot --headless --path . --script $d/c4.gd -- --theme-builder=res://tests/fixtures/ui_theme/low_contrast_theme.gd; echo rc=$?
```

Expected: each prints script-gate: cN FAIL; … 1 SCRIPT ERROR line(s) (Godot exits 0 on a parse error); no summary line matching … and then rc=1; c4 also says rc 0, want 1. Raw Godot on each copy exits rc 0 with 1 SCRIPT ERROR and no summary (V9)

### AC11

```sh
d=.godot/tmp/b2drill; mkdir -p $d; awk '{print} /^func _overlap_masks\(\) -> void:$/{print "\tprint(self.no_such_member_b2)"}' tests/test_dust_flash.gd > $d/c5.gd; godot --headless --path . --script $d/c5.gd > $d/c5.base.log 2>&1; rc=$?; test $rc = 0 && grep -q '^dust-flash: [1-9][0-9]* passed, 0 failures$' $d/c5.base.log && echo "old predicate: PASS"; sh tools/script_gate.sh c5 $d/c5.log 600 '^dust-flash: [1-9][0-9]* passed, 0 failures$' -- godot --headless --path . --script $d/c5.gd; echo rc=$?
```

Expected: old predicate: PASS (the base dust-flash-test check passes a run that skipped 3 checks: dust-flash: 26 passed, 0 failures), then script-gate: c5 FAIL; 1 SCRIPT ERROR line(s) …, rc=1 (V9)

### AC12

```sh
for e in '^star-surface: OK \([1-9][0-9]* passed, 0 failures\)$' '^captain-frames: ok \([1-9][0-9]* frames\)$' '^ui-theme-check: ok \([1-9][0-9]* files, [1-9][0-9]* text/panel pairs\)$' '^exposure-cpu-bench: OK [1-9][0-9]* profiles, renders/perf/exposure_cpu.json$' '^planet-cpu-bench: [1-9][0-9]* rows, renders/perf/planet_cpu.json$'; do printf '%s\n' 'star-surface: OK (0 passed, 0 failures)' 'captain-frames: ok (0 frames)' 'ui-theme-check: ok (0 files, 0 text/panel pairs)' 'exposure-cpu-bench: OK 0 profiles, renders/perf/exposure_cpu.json' 'planet-cpu-bench: 0 rows, renders/perf/planet_cpu.json' | grep -cE -- "$e"; done
```

Expected: five lines of 0

### AC13

```sh
make uid-guard python-guard audio-silent-guard lint-precision && git diff --check origin/main && shellcheck -s sh tools/script_gate.sh tools/test_script_gate.sh tools/script_gate_lint.sh && echo gates-ok
```

Expected: gates-ok (uid-guard: ok (406 .uid files), python-guard: ok (21 allowlisted, …), audio-silent-guard: ok (79 windowed godot invocations; 5 allowlisted to keep sound), lint-precision: ok …; V12; V21)

### AC14

```sh
git diff --name-only origin/main | grep -cvxE 'mk/(ism|planet-presentation|star-surfaces|navigation-usability|constellations|npc-painted|commons-civic|captain-anim|style|script-gates)\.mk|tools/(script_gate\.sh|test_script_gate\.sh|script-gate-baseline\.txt|captain_frames\.gd|ui_theme_check\.gd|planet_cpu_bench\.gd|exposure_cpu_bench\.gd)|tests/test_star_surface\.gd|tests/fixtures/script_gate/lint_negative\.mk\.txt|design_docs/planned/r1/m4-7x-b2-script-gates.*\.md|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'; git diff --name-only origin/main -- Makefile mk/sound.mk mk/m45.mk mk/deck-layout.mk mk/earth-link.mk | wc -l
```

Expected: 0, 0

### AC15

```sh
gh pr checks <PR>; gh run view <run> --log | grep -cE 'script-gate-lint: ok \(237 --script invocations: 33 through|test-script-gate: ok \(18 cases: 18 stub, 0 Godot\)'
```

Expected: success; 2. This is the probe's first Linux, dash and GNU sed -E run.

### AC16

```sh
F=.godot/tmp/b2-fresh-$$; test -e $F && echo exists || echo absent; make dust-flash-test map-ism-test star-surface-test SCRATCH=$F/s 2>&1 | grep '^script-gate:'; echo rc=$?; ls $F/s $F/s/star-surfaces
```

Expected: absent; script-gate: dust-flash-test ok: dust-flash: 29 passed, 0 failures (…), script-gate: map-ism-test ok: ism-layer: 22 passed, 0 failures (…), script-gate: star-surface-test ok: star-surface: OK (54 passed, 0 failures) (…); rc=0; $F/s lists dust-flash-test.log, map-ism-test.log and star-surfaces, and $F/s/star-surfaces lists test.log (V18)

### AC4(b) concrete scratch mutant and execution

AC4(a)'s `git show origin/main:tools/script_gate.sh` is valid at this measured base; if origin/main advances to include B2, freeze the documented pre-B2 `9e4d8231` helper instead and record the base change. Do not mutate tracked files for either mutant.

The AC4 command above first tests the landed helper, then writes an all-at-once block to scratch and substitutes it for the D4 block in a scratch copy. Expected AC4(b)/V19: `rc=1`, exactly `FAIL stub-twocount: exit 0 …` and `FAIL 1 of 18 cases`. Run under the same independent outer supervisor as the make selftest if testing any timeout mutant; no bare exec-alarm substitution here. The normal helper's AC3 is the positive control. This algorithm is intentionally revision 0; it is never an implementation alternative.

## Conflict surface / files / do-not-touch

The implementation allowlist is exactly the design's 19-file Estimated LOC table:

- `mk/ism.mk`
- `mk/planet-presentation.mk`
- `mk/star-surfaces.mk`
- `mk/navigation-usability.mk`
- `mk/constellations.mk`
- `mk/npc-painted.mk`
- `mk/commons-civic.mk`
- `mk/captain-anim.mk`
- `mk/style.mk`
- `mk/script-gates.mk`
- `tools/script_gate.sh`
- `tools/test_script_gate.sh`
- `tools/script-gate-baseline.txt`
- `tests/fixtures/script_gate/lint_negative.mk.txt`
- `tests/test_star_surface.gd`
- `tools/captain_frames.gd`
- `tools/ui_theme_check.gd`
- `tools/planet_cpu_bench.gd`
- `tools/exposure_cpu_bench.gd`

Planning/progress artifacts are this plan and this new feature in `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`. The approved design stays read-only in this mission. Do not edit `tools/script_gate_lint.sh` (AC13 may check it), `Makefile`, `mk/sound.mk`, `mk/m45.mk`, `mk/deck-layout.mk`, `mk/earth-link.mk`, audio/data/assets, scenes, shaders, other tests, `.uid` files or B2b recipes. No new tracked script or Python file. No changelog/roadmap/landing edits by this planner; controller owns the later landing cycle.

## Risks, gates and pause points

- **Runtime evidence under sandbox:** Godot import and all Godot-bearing checks are UNINFORMATIVE UNDER SANDBOX. Executor/controller run outside it and record real output; never declare success from a sandbox failure or from historical V rows alone.
- **Base drift:** remeasure the reality-check commands at executor pickup. Stop if a recipe, row count or PR overlap has changed; report a false design premise rather than work around it. The invariant is pre-baseline minus 28 = post-baseline and lint green. Parent target names are `script-gate-selftest`/`script-gate-drill`, not `test-script-gate` (positive-controlled grep above).
- **Probe semantics:** preserve the exact standalone-number rule and WANT_RC exemption. Probe each nonzero number separately; zero failures remains legal. Identifiers/versions are skipped, `AB=7x` remains a counted positive, and each literal count must remain bound. AC3/AC4 kill the weak and all-at-once alternatives. Decimals/timings are outside these positive summaries; B2b benches stay deferred (D4/D7).
- **Portability:** V21 measured replacement index 11 on macOS sed and under dash; GNU sed on Linux is first covered by AC15. Keep this a merge gate; never copy the rejected “only single-digit k works” claim.
- **Literal-count residue:** painted NPC and commons stage literals stay exact as designed; runtime-derived counts are deferred OQ2/B4. No inferred improvement here.
- **Host load and cleanup:** allow moon 1800 s and star 900 s, other B2a gates 600 s; moon measured 215–220 s. Use the existing process-group supervisor for long make orchestration, with bounded polling and child cleanup. Preserve A1's separate scratch roots and A2's per-run orphan controls. A child that changes its process group is outside the landed supervisor guarantee; do not expand that helper in this sprint.
- **Network:** constellation fetch is a sha-checked public read; a failed fetch is reported, not hidden by accepting the medium tier. GitHub overlap uses historical V14 until controller refresh. Only controller runs AC15 and any PR operation.
- **Scope and evaluation:** AC13 hygiene and AC14's two zeros are required. Pair empty-match checks with their known-positive controls (inventory 237/fixture 7/gate names 28, tracked allowed files for scope). Controller obtains the independent evaluator (100 points, 70 pass under CLAUDE.md); planner does not implement or auto-start execution. Stop on any missing/unrun acceptance evidence at close-out.

## Planner artifact validation

Original sprint JSON is saved under `.godot/tmp/iter70-planner/sprint_R1-M4-JOURNEY.before.json`; its initial `.features|length` was 24 (measurement above). Validate after appending:

```sh
jq -e . .ailang/state/sprints/sprint_R1-M4-JOURNEY.json > .godot/tmp/iter70-planner/validated.json; echo jq_rc=$?
jq '.features|length' .ailang/state/sprints/sprint_R1-M4-JOURNEY.json
jq '.features[:24]' .ailang/state/sprints/sprint_R1-M4-JOURNEY.json > .godot/tmp/iter70-planner/features-after.json
cmp .godot/tmp/iter70-planner/features-before.json .godot/tmp/iter70-planner/features-after.json; echo first24_cmp_rc=$?
jq 'del(.features)' .godot/tmp/iter70-planner/sprint_R1-M4-JOURNEY.before.json > .godot/tmp/iter70-planner/rest-before.json
jq 'del(.features)' .ailang/state/sprints/sprint_R1-M4-JOURNEY.json > .godot/tmp/iter70-planner/rest-after.json
cmp .godot/tmp/iter70-planner/rest-before.json .godot/tmp/iter70-planner/rest-after.json; echo other_fields_cmp_rc=$?
git diff --check
git diff --name-only
git ls-files --others --exclude-standard
```

Expected `jq_rc=0`, `25`, `first24_cmp_rc=0`, `other_fields_cmp_rc=0`; diff check clean. Tracked diff is only the sprint JSON; untracked list is only this plan. The saved original also permits a byte-level insertion-only check, beyond the required byte-identical jq projections. No git writes, Godot runs, implementation edits or network changes belong to this planner's deliverables.

**Observed planner validation (2026-11-04):** the commands above returned:

```text
jq_rc=0
25
first24_cmp_rc=0
other_fields_cmp_rc=0
```

The before-copy command `jq '.features|length' .godot/tmp/iter70-planner/sprint_R1-M4-JOURNEY.before.json` returned `24`. `git diff --check; echo diff_check_rc=$?` returned `diff_check_rc=0`. `git diff --name-only` returned `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`; `git ls-files --others --exclude-standard` returned `design_docs/planned/r1/m4-7x-b2-script-gates-sprint.md`. These two positive filenames control the claim that no other deliverable changed. Additional scratch-only validation parsed every AC command with `sh -n` (replacing PR/run placeholders with numeric stand-ins): 16/16 syntactically valid, no commands executed; confirmed the same feature keys, 19 files, 16 ACs, six matching milestone titles, planned/false and empty notes; and removing only the appended feature's byte span reconstructed the entire original JSON byte-for-byte.
