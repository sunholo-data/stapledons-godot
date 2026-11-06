# Row 7ac: pin `CrewConsole`'s process-wide `_serial` in `crew-console-test`

**Status:** Planned, mission iteration 74, designer, 2026-11-06. **Release:** r1. **Milestone:** charter queue row **7ac**, inside the approved sprint `R1-M4-JOURNEY` (D-22/D-66), the same home as rows 7x and 7aa.
**Priority:** P2 (follow-up backlog, [LOOP]). Suite hygiene, charter clauses 4/5.
**Implements:** [charter](../../stapledon-mission.md) row 7ac, which is OQ5 of [m4-7aa-sim-pipeline-test.md](../../implemented/r1/m4-7aa-sim-pipeline-test.md) (its V19–V21, drill k7, Appendix A4). The test guards the Crew console of [crew-console-v2.md](../../implemented/r2/crew-console-v2.md) (AC10–AC12 name `make crew-console-test`), which serves the design repo's [crew assignment system](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/crew-assignment-system.md) (Crew console work cards, R2 G1 in [r2-voyage-life.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r2-voyage-life.md)). No feature, [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) section, sim, protocol, scene or sound changes.
**Depends on:** row 7aa landed (PR #402); D-88 A (test hygiene inside an approved sprint, no pillar below 0, does not stop); Godot 4.7.2; AILANG v0.56.1 (`runtime/bin`).
**Estimated LOC:** **+11/−0 in 1 tracked file** (`tests/test_crew_console.gd`, `git diff --numstat`, V9) plus an 8-line changelog fragment. No new `.gd`, so no new `.uid`. No production code, no `Makefile`.

**Evidence:** every V-row was run first-hand on 2026-11-06, 10:30–10:55 CET, on `Voights-Mac-Studio.local`, in `stapledons-godot-iter74` at `b57d279e` (origin/main), with Godot `4.7.2.stable.official.ed1daf0bf` and `runtime/bin/ailang` (`AILANG v0.56.1`). The change was applied, run end to end, drilled, the acceptance criteria run as printed from the blocks of this doc (V11), and the tracked files restored (V10).

## Game vision alignment

Scored by the designer against the [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md) in the `game-vision-designer` skill's feature-validation format (pillar list from its `check_pillars.sh`); the skill's interview was **not invoked** (unattended; no game behaviour changes). **ALIGNED (neutral)**, no conflict.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | low | 0 | No game code changes. The test keeps a captain's offer from being silently refused when the console is rebuilt (the `altered_duplicate` refusal of V4) from coming back unnoticed. |
| The Game Doesn't Judge | 0 | 0 | No text the player sees. |
| Time Has Emotional Weight | 0 | 0 | Sim and clocks untouched. |
| The Ship Is Home | 0 | 0 | No scene change. |
| Grounded Strangeness | 0 | 0 | No visual change. |
| We Are Not Built For This | 0 | 0 | No crew behaviour change. |
| Suite hygiene (charter clauses 4/5) | low | +1 | A regression only an appendix drill caught (7aa k7) now turns a `make test` target red (V5, V6). |
| **Net** | | **+1** | **Go under D-88 A.** Nothing visual or audible; no dev-build review needed. |

## Problem

V-numbers refer to the [Verification log](#verification-log).

1. **The counter is static on purpose and only the drill knows why.** `ui/crew_console.gd:44` is `static var _serial := 0` and `offer_intents` builds `"c%d-%d-%d" % [turn, revision, _serial]` at `:264–265` (V1). Row 7aa (V19–V21 there) showed that a per-console counter makes two consoles built from one crew turn and revision repeat an id.
2. **Re-derived at HEAD (the 7aa harness A4, unchanged):** static, console A offers `tc0-0-1-counselor`; B and C, built after A's accepted send with nothing sent between them, offer `tc0-4-2-counselor` and `tc0-4-3-counselor`, nothing refused. Per-instance, B and C both offer `tc0-4-1-counselor`, and C is refused `crew:blocked:altered_duplicate:offer-tc0-4-1-counselor` plus `crew:{"host":"request capacity/id/clock"}` (V4). The rule is `proposals.ail:111` of the pinned `sunholo/social_dynamics` 0.4.0 (V3).
3. **Nothing `make test` runs pins it.** `crew-console-test` (`Makefile:158–161`, `test: crew-console-test`; V2) builds console A, **sends** A's offer (revision 0 → 4, V4's `a=tc0-0-1` / `b=tc0-4-…`), then builds B. B's ids differ from A's with either counter, so with line 44 made per-instance the target stays green: rc 0, 100 `ok`, `crew-console: 0 failures` (V5; the controller's own run agrees, 18 s). Only drill k7, an appendix of a landed doc, would notice.

## Goals and non-goals

**Goals.** One case in `real_sim()` of `tests/test_crew_console.gd`: a console D built from the same crew as B with no send between them must make different ids from B, and the real sim must take both B's and D's offers with nothing refused. A per-instance `_serial` turns `make crew-console-test` red with that case's FAIL lines.

**Non-goals.**
- No change to `ui/crew_console.gd` (the static counter is right; V4), the bridge or the sim.
- No `Makefile` change. Migrating `crew-console-test` through `$(SCRIPT_GATE)` is left out: three open PRs touch `Makefile` (V8) and the pin does not need it (OQ1).
- No public `reset_ids()` helper (7aa OQ2 stands).

## Design

### D1. The test case (`tests/test_crew_console.gd`, +11/−0)

Two checks, placed so that the existing checks see exactly the sim traffic they see today:

- **The id check** (after B is built, before any further send): D is built from `us.crew` (turn 0, revision 4, the same as B) and its offer and ask ids must both differ from B's. The label prints the two task ids, so a red run names the collision (`tc0-4-1-counselor, tc0-4-1-counselor`, V6).
- **The sim check** (after the existing re-send-is-refused checks, before `us.stop()`): send B's intents, then D's; neither send may be refused. This pins the consequence the comment at line 44 claims, through the real sim.

Why both, decided by measurement (drills k3, k4): each check alone turns the per-instance mutation red (V7). The id check needs no sim and names the cause; the sim check proves the collision matters today. The id check is the one that survives a future sim that treats a same-body repeat as a silent `Duplicate` (the other branch of `proposals.ail:111`, V3) instead of a refusal. Keeping both costs 4 lines and two sim sends of 2 intents each; the whole target took 13 s on both warm runs (V6; HEAD's test, per-instance, 17 s, V5; one sample each, not a timing claim).

The exact diff (applies to `b57d279e`; `git apply --check` in V9):

```diff 7ac-test
diff --git a/tests/test_crew_console.gd b/tests/test_crew_console.gd
index 9698f8c9..85757a5e 100644
--- a/tests/test_crew_console.gd
+++ b/tests/test_crew_console.gd
@@ -479,6 +479,12 @@ func real_sim() -> void:
 	var pb := CrewConsole.new()
 	pb.show_crew(us.crew)
 	var ob := pb.offer_intents("counselor")
+	# Row 7ac: a second console from the same crew with no send between (same turn and revision) must not
+	# repeat B's ids; CrewConsole._serial is static so that it cannot (a repeat is refused altered_duplicate).
+	var pd := CrewConsole.new()
+	pd.show_crew(us.crew)
+	var od := pd.offer_intents("counselor")
+	check("7ac two consoles from one crew, no send between, make different ids (%s, %s)" % [line_of(ob[0]).id, line_of(od[0]).id], line_of(od[0]).id != line_of(ob[0]).id and line_of(od[1]).id != line_of(ob[1]).id)
 	check("a rebuilt console in the same crew turn makes new task and request ids", ok and line_of(ob[0])["id"] != line_of(oa[0])["id"] and line_of(ob[1])["id"] != line_of(oa[1])["id"])
 	ok = ok and us.send(oa, 0.0)
 	var dup: Array = us.last_refused.map(func(r): return str(r.get("reason", "")))
@@ -486,9 +492,14 @@ func real_sim() -> void:
 	for reason in dup:
 		var words := CrewPage.refusal_words(reason, us.crew)
 		check("plain words for %s: %s" % [reason, words], not words.contains("_") and not words.contains("/") and not words.contains("{") and not RegEx.create_from_string("[0-9]").search(words))
+	ok = ok and us.send(ob, 0.0)
+	var b_refused := us.last_refused.duplicate()
+	ok = ok and us.send(od, 0.0)
+	check("7ac the sim takes both consoles' offers, nothing refused (%s %s)" % [b_refused, us.last_refused], ok and b_refused.is_empty() and us.last_refused.is_empty())
 	us.stop()
 	pa.free()
 	pb.free()
+	pd.free()
 	# Below 2.11 the envelope is refused (bad_intent): the console needs the console minor.
 	var old := SimBridge.new()
 	old.want_minor = SimBridge.INTERLUDE_MINOR
```

### D2. Changelog fragment

`changelogs/unreleased/2026-11-06-crew-console-serial-pin.md` (the convention of `changelogs/unreleased/README.md`; row 7aa's is `2026-11-06-sim-pipeline-test.md`, V8):

```markdown
### Changed

`make crew-console-test` now pins why the Crew console's offer-id counter is
process-wide: two consoles built from the same crew turn with nothing sent
between them must offer different ids, and the sim must take both. A
per-console counter repeats `tc0-4-1-counselor` and the sim refuses the second
offer (`altered_duplicate`); before this, only a design-doc drill caught that.
```

## Acceptance criteria

Run in the PR clone with `export PATH=$PWD/runtime/bin:$PATH` and this extractor for the tagged blocks of this doc (after landing, read the `implemented/r1/` path). A `\|` in a table cell is typed as a bare pipe:

```sh
x() { awk -v t="$1" '$0=="```"t{f=1;next} f&&$0=="```"{f=0} f' design_docs/planned/r1/m4-7ac-serial-pin.md; }
```

| # | Criterion | Command | Expected |
|---|---|---|---|
| AC1 | The target is green with the case, twice | `for i in 1 2; do make --no-print-directory crew-console-test AILANG=runtime/bin/ailang >/dev/null 2>&1; echo rc=$?; grep -E '^ok 7ac\|^FAIL\|^crew-console' .godot/tmp/crew-console.log; grep -c '^ok ' .godot/tmp/crew-console.log; done` | each time: `rc=0`; `ok 7ac two consoles from one crew, no send between, make different ids (tc0-4-11-counselor, tc0-4-12-counselor)`; `ok 7ac the sim takes both consoles' offers, nothing refused ([] [])`; `crew-console: 0 failures`; `102` (was 100); no `FAIL` (V6) |
| AC2 | Per-instance `_serial` is red with the new FAIL lines (drill k1) | `mkdir -p .godot/tmp/7ac; x 'sh 7ac-drill' > .godot/tmp/7ac/drill.sh; sh .godot/tmp/7ac/drill.sh "$PWD" k1; echo rc=$?` | `drill k1: ok (per-instance _serial: rc 2, the two 7ac FAIL lines, 2 failures)`, `serial-pin-drill: ok (1 drills: k1)`, `rc=0` |
| AC3 | All kill drills, tree unchanged after | `sh .godot/tmp/7ac/drill.sh "$PWD"; echo rc=$?; git status --porcelain` | the five `drill … ok` lines of [Kill drills](#kill-drills), `serial-pin-drill: ok (5 drills: d0 k1 k2 k3 k4)`, `rc=0`; status lists only the PR's own files (V7) |
| AC4 | Scope: one test file, no production or `Makefile` change | `git diff --numstat origin/main -- . ':!design_docs' ':!changelogs' ':!.ailang'; git diff --name-only origin/main \| grep -cxE 'Makefile\|ui/crew_console.gd\|bridge/sim_bridge.gd'` | `11	0	tests/test_crew_console.gd`; `0` |
| AC5 | Hygiene and the gate lint unmoved | `git diff --check origin/main; make --no-print-directory script-gate-lint uid-guard python-guard AILANG=runtime/bin/ailang` | silent; `script-gate-lint: ok (239 --script invocations: 121 through $(SCRIPT_GATE), 118 on the baseline; …)`, `uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)` (V9) |
| AC6 | Changelog fragment present | `test -s changelogs/unreleased/2026-11-06-crew-console-serial-pin.md && grep -c '^### ' changelogs/unreleased/2026-11-06-crew-console-serial-pin.md` | `1` |

## Kill drills

`sh 7ac-drill` below; each drill is one `make crew-console-test` (13–17 s warm), every mutation must change its file (else exit 3), and both mutated files are restored and `cmp`-checked on exit. Measured end to end in V7 (rc 0, 78 s):

| Drill | Mutation | Expected (measured) |
|---|---|---|
| d0 | none (negative control) | rc 0, both `ok 7ac` lines, 102 `ok`, 0 `FAIL` |
| k1 | `_serial` per-instance | rc 2, `crew-console: 2 failures`, `FAIL 7ac two consoles … (tc0-4-1-counselor, tc0-4-1-counselor)` and `FAIL 7ac the sim takes both … crew:blocked:altered_duplicate:offer-tc0-4-1-counselor …` |
| k2 | per-instance **and** both 7ac checks deleted | rc 0, `crew-console: 0 failures`: the new case is the sole killer (matches V5 with HEAD's test) |
| k3 | per-instance, only the id check deleted | rc 2, `crew-console: 1 failures`, the sim check's FAIL |
| k4 | per-instance, only the sim check deleted | rc 2, `crew-console: 1 failures`, the id check's FAIL |

```sh 7ac-drill
#!/bin/sh
# Row 7ac kill drills. Usage: sh drill.sh ROOT [d0 k1 k2 k3 k4]. ROOT is a clone with the 7ac test change applied.
# Each drill is one `make crew-console-test` (~15-55 s); every mutated file is restored and cmp-checked.
set -u
cd "$1" || exit 2; shift
export PATH="$PWD/runtime/bin:$PATH"
T=$(mktemp -d); LOG=.godot/tmp/crew-console.log
TC=tests/test_crew_console.gd; UI=ui/crew_console.gd
cp "$TC" "$T/tc"; cp "$UI" "$T/ui"
restore() { cp "$T/tc" "$TC"; cp "$T/ui" "$UI"; cmp -s "$T/tc" "$TC" && cmp -s "$T/ui" "$UI" || { echo "drill: restore failed"; exit 3; }; }
trap restore EXIT
mutate() { # FILE PERL: the edit must change the file, or the drill is void
  cp "$1" "$T/pre"; perl -pi -e "$2" "$1"; ! cmp -s "$T/pre" "$1" || { echo "drill: mutation '$2' changed nothing"; exit 3; }; }
run() { make --no-print-directory crew-console-test AILANG=runtime/bin/ailang >/dev/null 2>&1; echo $?; }
n() { grep -cE "$1" "$LOG"; }
perinst() { mutate "$UI" 's/^static var _serial := 0 /var _serial := 0 /'; }
d0() { rc=$(run); test "$rc" = 0 && test "$(n '^ok 7ac ')" = 2 && test "$(n '^FAIL')" = 0 || exit 1
  echo "drill d0: ok (unmodified: rc 0, both 7ac checks ok, $(n '^ok ') ok)"; }
k1() { perinst; rc=$(run); restore; test "$rc" != 0 && test "$(n '^crew-console: 2 failures$')" = 1 \
  && test "$(n '^FAIL 7ac two consoles from one crew, no send between, make different ids \(tc0-4-1-counselor, tc0-4-1-counselor\)$')" = 1 \
  && test "$(n '^FAIL 7ac the sim takes both .*crew:blocked:altered_duplicate:offer-tc0-4-1-counselor')" = 1 || exit 1
  echo "drill k1: ok (per-instance _serial: rc $rc, the two 7ac FAIL lines, 2 failures)"; }
k2() { perinst; mutate "$TC" '$_ = "" if /^\tcheck\("7ac /'; rc=$(run); restore
  test "$rc" = 0 && test "$(n '^crew-console: 0 failures$')" = 1 && test "$(n '7ac')" = 0 || exit 1
  echo "drill k2: ok (both 7ac checks removed: the per-instance counter is green again, rc 0)"; }
k3() { perinst; mutate "$TC" '$_ = "" if /^\tcheck\("7ac two consoles/'; rc=$(run); restore
  test "$rc" != 0 && test "$(n '^crew-console: 1 failures$')" = 1 && test "$(n '^FAIL 7ac the sim takes both ')" = 1 || exit 1
  echo "drill k3: ok (id check removed: the sim check alone is red, rc $rc)"; }
k4() { perinst; mutate "$TC" '$_ = "" if /^\tcheck\("7ac the sim/'; rc=$(run); restore
  test "$rc" != 0 && test "$(n '^crew-console: 1 failures$')" = 1 && test "$(n '^FAIL 7ac two consoles ')" = 1 || exit 1
  echo "drill k4: ok (sim check removed: the id check alone is red, rc $rc)"; }
[ $# -gt 0 ] || set -- d0 k1 k2 k3 k4
for d; do case $d in d0|k1|k2|k3|k4) "$d" ;; *) echo "drill: unknown $d"; exit 2 ;; esac; done
echo "serial-pin-drill: ok ($# drills: $*)"
```

## Sub-milestones and estimates

| # | Work | LOC | Est. |
|---|---|---:|---|
| M1 | D1 (apply the diff), AC1, AC4, AC5 | +11 | 15 min |
| M2 | Drills (AC2, AC3), D2 fragment (AC6) | +8 | 15 min |

One PR, test-only. The targeted gate is `make crew-console-test` run by the executor; the GitHub fast tier does not run it (`ci-fast` in `Makefile:55` and `mk/*.mk` lists no `crew-console-test`, V2), the nightly `make test` does.

## Conflict surface

None. The change touches `tests/test_crew_console.gd` and a new fragment; no open PR (#373, #379, #380, #384) touches either (V8). #373, #379 and #380 touch `Makefile`, which this row leaves alone.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A later crew-section change moves turn/revision so ids happen to differ | The id check compares two consoles built from one `us.crew` snapshot with no send between them; it does not depend on the values. k1 pins the current collision text so a drifting drill fails loudly. |
| The extra sends change what later checks see | They are placed after every existing `us` check and before `us.stop()`; the existing 100 `ok` lines are unchanged (102 = 100 + 2, V6). |
| The sim one day treats the repeat as a silent `Duplicate` | The id check still kills (k4) |
| Another test resets `_serial` mid-run | Only `tests/test_sim_pipeline.gd:19` writes it, in its own process (V1). |

## Open questions (defaults apply if unanswered)

- **OQ1. Also migrate `crew-console-test` through `$(SCRIPT_GATE)` here? Default: no; file it as its own row.** It is optional, touches `Makefile` (three open PRs do too, V8) and `tools/script-gate-baseline.txt:37`; the pin works through the raw target, whose recipe already fails on rc, `SCRIPT ERROR` and a non-zero failure count (`Makefile:160`).
- **OQ2. Put `crew-console-test` into `ci-fast`? Default: no.** Out of scope for a hygiene row; the nightly and the executor's targeted run cover it.

## Deliverables

- `tests/test_crew_console.gd`: D1.
- `changelogs/unreleased/2026-11-06-crew-console-serial-pin.md`: D2.
- On landing: this doc to `implemented/r1/`, charter row 7ac marked landed.

## Verification log

| V | Claim | Command | Observed |
|---|---|---|---|
| V1 | The counter, its id format, and who writes it | `grep -n "_serial" ui/crew_console.gd tests/*.gd`; `git ls-files "*.gd" \| xargs grep -c "_serial" \| grep -v ":0$"` (positive control: the counter's own file) | `ui/crew_console.gd:44:static var _serial := 0 …`, `:264`, `:265` (`var tag := "c%d-%d-%d" % [int(crew.get("turn", 0)), int(crew.get("revision", 0)), _serial]`), `:283`, `:285`; `tests/test_sim_pipeline.gd:19:	CrewConsole._serial = 0`; no other test; the tracked-file count: `tests/test_sim_pipeline.gd:1`, `ui/crew_console.gd:5`, nothing else |
| V2 | Which suites run the target | `grep -n 'crew-console-test' Makefile mk/*.mk .github/workflows/*.yml; grep -n '^ci-fast' Makefile mk/*.mk` | `Makefile:158` (target), `Makefile:161:test: crew-console-test`; no workflow hit; `ci-fast` lines at `Makefile:55`, `mk/script-gates.mk:27`, `mk/star-surfaces.mk:15`, none naming it. Baseline: `tools/script-gate-baseline.txt:37:crew-console-test	tests/test_crew_console.gd	rc,se,sum,-` |
| V3 | The refusal rule and pin | `grep -n 'AlteredDuplicate(p.id)' runtime/cache/registry/sunholo/social_dynamics/0.4.0/proposals.ail; grep -n social_dynamics sim/ailang.toml` | `111:    prior :: _ => if prior.body == body then Ok({… Duplicate, events: []}) else Err(AlteredDuplicate(p.id)),`; `36:"sunholo/social_dynamics" = "0.4.0" …` |
| V4 | Handed facts re-derived: same-crew consoles collide per-instance; A's send moves revision 0 → 4 | 7aa A4 extracted with `awk` to `.godot/tmp/7ac/ids.gd` (29 lines); `godot --headless --path . --script "$PWD/.godot/tmp/7ac/ids.gd" \| grep -E '^K7IDS\|^k7-ids\|SCRIPT ERROR'`, static then with `perl -pi -e 's/^static var _serial := 0 /var _serial := 0 /' ui/crew_console.gd`; file restored, `cmp` ok | Static (3 s): `a=tc0-0-1-counselor b=tc0-4-2-counselor c=tc0-4-3-counselor turn=0.0 revision=4.0`, `b_and_c_same=false`, `b_refused=0`, `c_refused=0`, `k7-ids: done`. Per-instance (3 s): `b=tc0-4-1-counselor c=tc0-4-1-counselor`, `b_and_c_same=true`, `b_refused=0`, `c_refused=2 crew:blocked:altered_duplicate:offer-tc0-4-1-counselor,crew:{"host":"request capacity/id/clock"}`, `k7-ids: done`. No `SCRIPT ERROR` |
| V5 | HEAD's test does not pin it (control) | HEAD's `tests/test_crew_console.gd`, line 44 per-instance; `make --no-print-directory crew-console-test AILANG=runtime/bin/ailang`; `grep -cE '^ok ' …; grep -E '^FAIL\|^crew-console\|rebuilt\|re-sending' .godot/tmp/crew-console.log`; restored | rc 0, 17 s, `100`, `ok a rebuilt console in the same crew turn makes new task and request ids`, `ok re-sending an old id is refused (…)`, `crew-console: 0 failures`, no FAIL. (Controller, same clone: rc 0, 18 s per-instance; rc 0, 54 s static, cold) |
| V6 | D1 end to end: green twice, red per-instance | D1 applied; `make --no-print-directory crew-console-test AILANG=runtime/bin/ailang` ×2; then per-instance; `grep -E '^ok 7ac\|^FAIL\|^crew-console' …; grep -c '^ok ' …; grep -c 'SCRIPT ERROR' …` | Run 1: rc 0, 13 s, `102`, both `ok 7ac …` lines as in AC1, `crew-console: 0 failures`, 0 SCRIPT ERROR. Run 2: rc 0, 13 s, the same. Per-instance: rc 2 (make), 14 s, `100`, `FAIL 7ac two consoles from one crew, no send between, make different ids (tc0-4-1-counselor, tc0-4-1-counselor)`, `FAIL 7ac the sim takes both consoles' offers, nothing refused ([] [{ "i": 0.0, "reason": "crew:blocked:altered_duplicate:offer-tc0-4-1-counselor" }, { "i": 1.0, "reason": "crew:{\"host\":\"request capacity/id/clock\"}" }])`, `crew-console: 2 failures`; the two pre-existing id checks stay `ok`; 0 SCRIPT ERROR |
| V7 | The drills | D1 applied; `sh drill.sh "$PWD"` (the `sh 7ac-drill` block); `git status --porcelain`; `cmp` of both files against D1-applied / HEAD copies | the five lines of the drill table verbatim (`drill d0: ok (unmodified: rc 0, both 7ac checks ok, 102 ok)` … `drill k4: ok (sim check removed: the id check alone is red, rc 2)`), `serial-pin-drill: ok (5 drills: d0 k1 k2 k3 k4)`, rc 0, 78 s; status ` M tests/test_crew_console.gd` only; `files-as-expected` |
| V8 | Conflict surface; changelog convention | `gh pr diff <n> --repo sunholo-data/stapledons-godot --name-only` for 373, 379, 380, 384, grep for `test_crew_console\|Makefile`; `git log --format='%h %s' -3 -- changelogs/unreleased`; `sed -n 1,5p changelogs/unreleased/README.md` | `Makefile` in #373, #379, #380; not in #384; `tests/test_crew_console.gd` in none (the four lists name `tests/test_physics.gd`, `tests/test_earth_feed.gd` and others). Latest fragment commit `da7afacf … row 7aa M2: … changelog fragment` (`2026-11-06-sim-pipeline-test.md`, a `### Fixed` section); README: one `YYYY-MM-DD-<slug>.md` per change |
| V9 | Size and hygiene | D1 applied: `git diff --numstat; git diff --check; make --no-print-directory script-gate-lint uid-guard python-guard AILANG=runtime/bin/ailang`; D1 from this doc: `x 'diff 7ac-test' > /tmp/7ac.diff; git apply --check /tmp/7ac.diff` on the restored tree | `11	0	tests/test_crew_console.gd`; `--check` silent; lint `ok (239 --script invocations: 121 through $(SCRIPT_GATE), 118 on the baseline; …)`, `script-gate-prereqs: ok (…)`, `uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`; `apply --check` silent, rc 0 |
| V10 | Tree restored | `git status --porcelain; git diff --stat` | `?? design_docs/planned/r1/m4-7ac-serial-pin.md` only; `git diff --stat` empty |
| V11 | The ACs as printed, from this doc's blocks | `x 'diff 7ac-test'` and `x 'sh 7ac-drill'` `cmp`-identical to the files run in V6/V7 (32 and 34 lines); `git apply` of the extracted diff; AC1–AC5 typed as in the table (bash); then the test file copied back | AC1 twice: `rc=0`, both `ok 7ac` lines, `crew-console: 0 failures`, `102` (30 s for both). AC2: `drill k1: ok …`, `serial-pin-drill: ok (1 drills: k1)`, `rc=0`. AC3: the five drill lines, `serial-pin-drill: ok (5 drills: d0 k1 k2 k3 k4)`, `rc=0`, 80 s; status ` M tests/test_crew_console.gd` and this doc. AC4: `11	0	tests/test_crew_console.gd`, `0`. AC5: silent, then the lint, `uid-guard` and `python-guard` lines of V9. AC6 not run (the fragment is the executor's) |
