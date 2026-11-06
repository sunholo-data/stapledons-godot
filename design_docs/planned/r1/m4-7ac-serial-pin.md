# Row 7ac: pin `CrewConsole`'s process-wide `_serial` in `crew-console-test`

**Status:** Planned, mission iteration 74, designer, 2026-11-06; **revision 2** (controller, narrow-refinement carve-out) after design quorum round 2 (see [Quorum r2 response](#quorum-r2-response-revision-2-controller-carve-out)); revision 1 answered round 1. **Release:** r1. **Milestone:** charter queue row **7ac**, inside the approved sprint `R1-M4-JOURNEY` (D-22/D-66), the same home as rows 7x and 7aa.
**Priority:** P2 (follow-up backlog, [LOOP]). Suite hygiene, charter clauses 4/5.
**Implements:** [charter](../../stapledon-mission.md) row 7ac, which is OQ5 of [m4-7aa-sim-pipeline-test.md](../../implemented/r1/m4-7aa-sim-pipeline-test.md) (its V19–V21, drill k7, Appendix A4). The test guards the Crew console of [crew-console-v2.md](../../implemented/r2/crew-console-v2.md) (AC10–AC12 name `make crew-console-test`), which serves the design repo's [crew assignment system](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/crew-assignment-system.md) (Crew console work cards, R2 G1 in [r2-voyage-life.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r2-voyage-life.md)). No feature, [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) section, sim, protocol, scene or sound changes.
**Depends on:** row 7aa landed (PR #402); D-88 A (test hygiene inside an approved sprint, no pillar below 0, does not stop); Godot 4.7.2; AILANG v0.56.1 (`runtime/bin`).
**Estimated LOC:** **+11/−0 in `tests/test_crew_console.gd` and +1/−0 in `.gitattributes`** (`git diff --numstat`, V9, V17) plus an 8-line changelog fragment. No new `.gd`, so no new `.uid`. No production code, no `Makefile`.

**Evidence:** every V-row was run first-hand on 2026-11-06 on `Voights-Mac-Studio.local`, in `stapledons-godot-iter74` (V1–V11 at 10:30–10:55 CET on `b57d279e`; revision 1's V12–V16 and the re-runs at 11:00–11:40 CET on `ffc376ab`, which adds only this doc), with Godot `4.7.2.stable.official.ed1daf0bf` and `runtime/bin/ailang` (`AILANG v0.56.1`). The change was applied, run end to end, drilled, the acceptance criteria run as printed from the blocks of this doc (V11, V16), and the tracked files restored (V10).

## Quorum r2 response (revision 2, controller, carve-out)

Round 2 (`m4-7ac-serial-pin-2026-11-06T10-14-13Z.json`, $0.2946, same seats, `absent_reviewers` empty): **BLOCKED 2/3**, oc-glm-5-3 pass. Neither reject disputes the direction (the +11-line pin, both checks); both give a concrete fix, and both land on surfaces revision 1 introduced (AC5's rescope, the drill supervisor), not on the test. The controller applied them under the narrow-refinement carve-out, with no third designer run, and measured each:

| # | Objection (seat) | Change | V |
|---|---|---|---|
| 1 | AC5 re-scoped `git diff --check` to exclude `design_docs` to buy its own green (oc-kimi-k3, blocking) | Reviewer's fix verbatim: `.gitattributes` gains `design_docs/** whitespace=-space-before-tab`; AC5 is the unscoped `git diff --check origin/main` again, silent. Controls: the attribute removed → 15 hits; a code-path probe (` \tbad` in a scratch `tests/` file) is still flagged | V17 |
| 2 | The bounded runner kills only the make/Godot group; the sim has its own group, so an ordinary timeout does not reap a stuck sim (gpt6-1-sol, blocking) | The drill's supervisor reaps the group and every descendant it recorded before TERM, and does so when signalled too (rc 143 → drill exit 5). New fault-injection drill **ks**: a child spawned by Godot like the sim, outside its group, ignoring TERM/HUP/INT and outliving Godot, is gone 0 s after a 60 s timeout; under the round-1 supervisor the same drill fails (negative control). The reviewer's second half, "use that runner for the actual crew-console-test recipe", is pre-existing at `b57d279e` (the recipe has no deadline; every `$(GODOT_SIM)` gate's sim escapes `script_gate.sh`'s group) and is split to row **7ad** with the objection verbatim (gate-2 rule (c)); see Risks | V18, V19 |
| 3 | The sim check threads `ok`, so an earlier failure would skip both sends and misattribute stale refusals (oc-glm-5-3, pass) | Reviewer's fix verbatim: `var b_ok := us.send(ob, 0.0)`, `var d_ok := us.send(od, 0.0)`, condition `b_ok and d_ok and b_refused.is_empty() and us.last_refused.is_empty()`; still +11/−0. `SimBridge.send` returns true when the tick advanced and reports refusals only in `last_refused` (`bridge/sim_bridge.gd:309-313`), so k1's FAIL text is unchanged | V18 |

## Quorum r1 response (revision 1)

| # | Objection (seat) | Change | V |
|---|---|---|---|
| 1 | AC1 hard-codes the suite-order ordinals `tc0-4-11`/`tc0-4-12` (oc-kimi-k3, blocking; oc-glm-5-3, pass) | AC1 now runs drill d0, which matches `tc0-4-[0-9]+-counselor` twice and requires the two ordinals to differ; 11/12 are illustrative in V6. D1 explains the offset (9 increments before A: 7 `offer_intents`, 2 `reply_intents`), a risk row covers suite churn, and the drill header states the measured warm/cold times. | V13, V16 |
| 2 | The isolation of `tests/test_sim_pipeline.gd:19` was asserted, not shown; placement unjustified (oc-kimi-k3) | V12 cites both recipes (one `godot --script` process each, no cross-reference); Conflict surface covers the 7aa reset and why the pin lives in `test_crew_console.gd`. | V12 |
| 3 | No deadline on the AC and drill runners (gpt6-1-sol, blocking) | Every `make` in the drill runs under a perl supervisor of `tools/script_gate.sh`'s shape (BOUND, default 300 s); a timeout exits 4, never a kill. `script_gate.sh` itself refuses `crew-console: 0 failures` (zero probe, V14), hence the drill-local copy. New drill **kh**: a test that never quits and holds a live sim is stopped at 60 s, fails with rc 4, leaves no process (5 live before, 0 after), and the EXIT trap restores the files. | V14, V15 |

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

- **The id check** (after B is built, before any further send): D is built from `us.crew` (turn 0, revision 4, the same as B) and its offer and ask ids must both differ from B's. The label prints the two task ids, so a red run names the collision (`tc0-4-1-counselor, tc0-4-1-counselor`, V6). Green, the ordinals are a suite-order artifact: the counter is process-wide, and earlier sections of the same process bump it 9 times before console A (7 `offer_intents`, 2 `reply_intents`: `locks` 2, `keys` 2, `real_sim` 5), so A, B and D get 10, 11 and 12 (V13), where 7aa's standalone A4 harness gets 1, 2 and 3 (V4). Only their inequality is pinned (AC1); per-instance, every console starts at 0, so k1's `tc0-4-1` is stable.
- **The sim check** (after the existing re-send-is-refused checks, before `us.stop()`): send B's intents, then D's; neither send may be refused. This pins the consequence the comment at line 44 claims, through the real sim.

Why both, decided by measurement (drills k3, k4): each check alone turns the per-instance mutation red (V7, V15). The id check needs no sim and names the cause; the sim check proves the collision matters today. The id check is the one that survives a future sim that treats a same-body repeat as a silent `Duplicate` (the other branch of `proposals.ail:111`, V3) instead of a refusal. Keeping both costs 4 lines and two sim sends of 2 intents each; the whole target took 13 s on both warm runs (V6; HEAD's test, per-instance, 17 s, V5; one sample each, not a timing claim).

The exact diff (applies to `b57d279e`; `git apply --check` in V9):

```diff 7ac-test
diff --git a/tests/test_crew_console.gd b/tests/test_crew_console.gd
index 9698f8c9..41ecdba4 100644
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
+	var b_ok := us.send(ob, 0.0)
+	var b_refused := us.last_refused.duplicate()
+	var d_ok := us.send(od, 0.0)
+	check("7ac the sim takes both consoles' offers, nothing refused (%s %s)" % [b_refused, us.last_refused], b_ok and d_ok and b_refused.is_empty() and us.last_refused.is_empty())
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
| AC1 | The target is green with the case, twice, under the deadline; value-independent | `mkdir -p .godot/tmp/7ac; x 'sh 7ac-drill' > .godot/tmp/7ac/drill.sh; for i in 1 2; do sh .godot/tmp/7ac/drill.sh "$PWD" d0; echo rc=$?; done` | each time `drill d0: ok (unmodified: rc 0, 0 failures, N ok, ids tc0-4-P tc0-4-Q distinct, sim refused nothing)` with P ≠ Q, then `serial-pin-drill: ok (1 drills: d0)`, `rc=0`. d0 requires rc 0, `crew-console: 0 failures`, no `FAIL` or `SCRIPT ERROR`, the id line matching `^ok 7ac two consoles from one crew, no send between, make different ids \(tc0-4-[0-9]+-counselor, tc0-4-[0-9]+-counselor\)$` with two distinct `tc0-4-[0-9]+`, and `ok 7ac the sim takes both consoles' offers, nothing refused ([] [])`. At `b57d279e` N = 102 (HEAD's 100 + 2), P, Q = 11, 12 (illustrative, V6, V13) |
| AC2 | Per-instance `_serial` is red with the new FAIL lines (drill k1) | `sh .godot/tmp/7ac/drill.sh "$PWD" k1; echo rc=$?` | `drill k1: ok (per-instance _serial: rc 2, the two 7ac FAIL lines, 2 failures)`, `serial-pin-drill: ok (1 drills: k1)`, `rc=0` |
| AC3 | All kill drills including both deadline drills, tree unchanged after | `sh .godot/tmp/7ac/drill.sh "$PWD"; echo rc=$?; git status --porcelain` | the seven `drill … ok` lines of [Kill drills](#kill-drills), `serial-pin-drill: ok (7 drills: d0 k1 k2 k3 k4 kh ks)`, `rc=0`; status lists only the PR's own files (V15, V18); no process matching `sleep 7474740$` left (`pgrep -f` rc 1) |
| AC4 | Scope: one test file and one `.gitattributes` line, no production or `Makefile` change | `git diff --numstat origin/main -- . ':!design_docs' ':!changelogs' ':!.ailang'; git diff --name-only origin/main \| grep -cxE 'Makefile\|ui/crew_console.gd\|bridge/sim_bridge.gd'` | `1	0	.gitattributes` and `11	0	tests/test_crew_console.gd`; `0` |
| AC5 | Hygiene and the gate lint unmoved | `git diff --check origin/main; make --no-print-directory script-gate-lint uid-guard python-guard AILANG=runtime/bin/ailang` | silent; `script-gate-lint: ok (239 --script invocations: 121 through $(SCRIPT_GATE), 118 on the baseline; …)`, `uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)` (V9). Unscoped (quorum r2, oc-kimi-k3): the embedded unified diff's context lines start with a space before a tab, which `.gitattributes` `design_docs/** whitespace=-space-before-tab` exempts for `design_docs` only; code paths stay checked (V17) |
| AC6 | Changelog fragment present | `test -s changelogs/unreleased/2026-11-06-crew-console-serial-pin.md && grep -c '^### ' changelogs/unreleased/2026-11-06-crew-console-serial-pin.md` | `1` |

## Kill drills

`sh 7ac-drill` below. Each drill is one `make crew-console-test`: 13–18 s warm (V6, V7, V15), 54 s cold (the controller's first run in this clone). Every `make` runs under a deadline, `BOUND` s (default 300, about 5× the cold run), through a perl supervisor of `tools/script_gate.sh`'s shape (own process group; TERM, 2 s, KILL; rc 142), extended in revision 2 to reap every descendant it recorded before TERM as well as the group, because the sim runs in its own process group (V15), and to do the same when it is itself signalled (rc 143, drill exit 5). A timeout makes the drill exit 4, an interruption exit 5; neither ever counts as a kill. Every mutation must change its file (else exit 3), and both mutated files are restored and `cmp`-checked by an EXIT trap, which also runs after a timeout (kh, ks). Measured end to end in V18 (rc 0, 194 s):

| Drill | Mutation | Expected (measured) |
|---|---|---|
| d0 | none (negative control; AC1) | rc 0, 0 failures, both 7ac lines with distinct ordinals, 102 `ok` at `b57d279e` |
| k1 | `_serial` per-instance | rc 2, `crew-console: 2 failures`, `FAIL 7ac two consoles … (tc0-4-1-counselor, tc0-4-1-counselor)` and `FAIL 7ac the sim takes both … crew:blocked:altered_duplicate:offer-tc0-4-1-counselor …` |
| k2 | per-instance **and** both 7ac checks deleted | rc 0, `crew-console: 0 failures`: the new case is the sole killer (matches V5 with HEAD's test) |
| k3 | per-instance, only the id check deleted | rc 2, `crew-console: 1 failures`, the sim check's FAIL |
| k4 | per-instance, only the sim check deleted | rc 2, `crew-console: 1 failures`, the id check's FAIL |
| kh | the deadline: `quit(…)` replaced by a member `SimBridge` that is started and never stopped, run by a child drill with `BOUND=60` | the test reaches `crew-console: 0 failures` and then hangs with a live sim; the child exits 4 with `drill: timeout after 60 s`; every process recorded under it before the deadline (5: perl, make, sh, godot, ailang) is gone within 10 s (measured 0 s); both files `cmp`-equal to before (the child's EXIT trap) |
| ks | quorum r2 (gpt6-1-sol): `quit(…)` replaced by a stuck child spawned by Godot through `OS.create_process` (as the sim is), `sh -c "trap '' TERM HUP INT; exec sleep 7474740"`, so it ignores graceful shutdown and outlives Godot; child drill with `BOUND=60` | the child is seen before the deadline in a process group other than Godot's; the child drill exits 4 with `drill: timeout after 60 s`; no `sleep 7474740` survives 10 s after (measured 0 s); both files restored. Negative control (V19): the same drill under the round-1 group-only supervisor fails `drill ks: the stuck child survived the deadline` |

```sh 7ac-drill
#!/bin/sh
# Row 7ac kill drills. Usage: sh drill.sh ROOT [d0 k1 k2 k3 k4 kh]. ROOT is a clone with the 7ac change applied.
# Every make runs under a deadline: BOUND s (default 300; measured 13-18 s warm, 54 s cold), by a perl supervisor of
# tools/script_gate.sh's shape (own process group, TERM, 2 s, KILL, rc 142). A timeout is a failure (exit 4), never
# a kill. Both mutated files are restored and cmp-checked on every exit, a timeout included (EXIT trap; drill kh).
set -u
SELF=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
cd "$1" || exit 2; shift
export PATH="$PWD/runtime/bin:$PATH"
BOUND=${BOUND:-300}
T=$(mktemp -d); LOG=.godot/tmp/crew-console.log
TC=tests/test_crew_console.gd; UI=ui/crew_console.gd
cp "$TC" "$T/tc"; cp "$UI" "$T/ui"
restore() { cp "$T/tc" "$TC"; cp "$T/ui" "$UI"; cmp -s "$T/tc" "$TC" && cmp -s "$T/ui" "$UI" || { echo "drill: restore failed"; exit 3; }; }
trap restore EXIT; trap 'exit 5' INT TERM HUP
mutate() { # FILE PERL: the edit must change the file, or the drill is void
  cp "$1" "$T/pre"; perl -pi -e "$2" "$1"; ! cmp -s "$T/pre" "$1" || { echo "drill: mutation '$2' changed nothing"; exit 3; }; }
bounded() { # SECS cmd...: cmd's rc; 142 when the deadline stopped it, 143 when the supervisor was signalled.
  # Reaps the process group AND every descendant recorded before TERM (the sim runs in its own group, V15),
  # so a child that left the group and ignores TERM/HUP/INT is still KILLed 2 s later (drill ks).
  perl -e 'use POSIX ":sys_wait_h"; my $secs = shift; my $pid = fork; die "fork: $!" unless defined $pid; if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127; } sub tree { my %k; for (`ps -axo pid=,ppid=`) { my ($p, $pp) = split; push @{$k{$pp}}, $p } my @a; my @q = ($_[0]); while (@q) { my $x = shift @q; for my $c (@{$k{$x} || []}) { push @a, $c; push @q, $c } } @a } sub reap { my @t = tree($pid); kill "TERM", -$pid, @t; my $g = time + 2; while (time < $g) { last if waitpid($pid, WNOHANG) == $pid; select(undef, undef, undef, 0.1) } kill "KILL", -$pid, @t, tree($pid); waitpid($pid, 0); kill "KILL", -$pid, @t } $SIG{INT} = $SIG{TERM} = $SIG{HUP} = sub { reap(); exit 143 }; my $end = time + $secs; my $st; while (1) { my $r = waitpid($pid, WNOHANG); if ($r == $pid) { $st = $?; last } if (time >= $end) { reap(); exit 142 } select(undef, undef, undef, 0.1) } exit($st & 127 ? 128 + ($st & 127) : $st >> 8)' "$@"; }
run() { rm -f "$LOG"; bounded "$BOUND" make --no-print-directory crew-console-test AILANG=runtime/bin/ailang >/dev/null 2>&1; RC=$?
  [ "$RC" != 142 ] || { echo "drill: timeout after $BOUND s (a failure, never a kill)"; exit 4; }
  [ "$RC" != 143 ] || { echo "drill: interrupted (a failure, never a kill)"; exit 5; }; }
n() { grep -cE "$1" "$LOG"; }
perinst() { mutate "$UI" 's/^static var _serial := 0 /var _serial := 0 /'; }
d0() { run; test "$RC" = 0 && test "$(n '^crew-console: 0 failures$')" = 1 && test "$(n '^FAIL|SCRIPT ERROR')" = 0 || exit 1
  id=$(grep -E '^ok 7ac two consoles from one crew, no send between, make different ids \(tc0-4-[0-9]+-counselor, tc0-4-[0-9]+-counselor\)$' "$LOG")
  test -n "$id" && test "$(printf '%s\n' "$id" | grep -oE 'tc0-4-[0-9]+' | sort -u | wc -l | tr -d ' ')" = 2 || exit 1
  test "$(n "^ok 7ac the sim takes both consoles' offers, nothing refused \(\[\] \[\]\)$")" = 1 || exit 1
  echo "drill d0: ok (unmodified: rc 0, 0 failures, $(n '^ok ') ok, ids $(printf '%s\n' "$id" | grep -oE 'tc0-4-[0-9]+' | tr '\n' ' ')distinct, sim refused nothing)"; }
k1() { perinst; run; restore; test "$RC" != 0 && test "$(n '^crew-console: 2 failures$')" = 1 \
  && test "$(n '^FAIL 7ac two consoles from one crew, no send between, make different ids \(tc0-4-1-counselor, tc0-4-1-counselor\)$')" = 1 \
  && test "$(n '^FAIL 7ac the sim takes both .*crew:blocked:altered_duplicate:offer-tc0-4-1-counselor')" = 1 || exit 1
  echo "drill k1: ok (per-instance _serial: rc $RC, the two 7ac FAIL lines, 2 failures)"; }
k2() { perinst; mutate "$TC" '$_ = "" if /^\tcheck\("7ac /'; run; restore
  test "$RC" = 0 && test "$(n '^crew-console: 0 failures$')" = 1 && test "$(n '7ac')" = 0 || exit 1
  echo "drill k2: ok (both 7ac checks removed: the per-instance counter is green again, rc 0)"; }
k3() { perinst; mutate "$TC" '$_ = "" if /^\tcheck\("7ac two consoles/'; run; restore
  test "$RC" != 0 && test "$(n '^crew-console: 1 failures$')" = 1 && test "$(n '^FAIL 7ac the sim takes both ')" = 1 || exit 1
  echo "drill k3: ok (id check removed: the sim check alone is red, rc $RC)"; }
k4() { perinst; mutate "$TC" '$_ = "" if /^\tcheck\("7ac the sim/'; run; restore
  test "$RC" != 0 && test "$(n '^crew-console: 1 failures$')" = 1 && test "$(n '^FAIL 7ac two consoles ')" = 1 || exit 1
  echo "drill k4: ok (sim check removed: the id check alone is red, rc $RC)"; }
hang() { # kh's child: the test never quits and holds a live sim; run must time out (exit 4), the EXIT trap restores
  mutate "$TC" 's/^\tquit\(1 if failures else 0\)$/\t_hold = SimBridge.new()\n\t_hold.start()/; s/^var failures := 0$/var failures := 0\nvar _hold: SimBridge/'
  run; echo "drill hang: no timeout (rc $RC)"; exit 1; }
desc() { for c in $(pgrep -P "$1"); do echo "$c"; desc "$c"; done; }
kh() { # the deadline: a hung test is stopped, fails, leaves no process behind, and the files come back
  B=${KH_BOUND:-60}; rm -f "$LOG"; t0=$(date +%s)
  BOUND=$B sh "$SELF" "$PWD" hang > "$T/kh.out" 2>&1 & cp=$!
  pids=""; sim=""
  while [ $(($(date +%s) - t0)) -lt $((B - 5)) ]; do
    pids=$(desc "$cp"); sim=$(for p in $pids; do ps -o comm= -p "$p"; done | grep -c 'ailang$')
    [ -s "$LOG" ] && [ "$(n '^crew-console: 0 failures$')" = 1 ] && [ "$sim" -ge 1 ] && break; sleep 1; done
  live=$(for p in $pids; do kill -0 "$p" 2>/dev/null && echo "$p"; done | wc -l | tr -d ' ')
  god=$(for p in $pids; do ps -o comm= -p "$p"; done | grep -ciE '(^|/)godot$')
  names=$(for p in $pids; do ps -o pgid=,comm= -p "$p" | sed -E "s#^ *([0-9]+) .*/#\1:#; s#^ *([0-9]+) #\1:#"; done | tr "\n" " ")
  wait "$cp"; crc=$?; secs=$(($(date +%s) - t0))
  i=0; left=1; while [ $i -lt 10 ]; do left=$(for p in $pids; do kill -0 "$p" 2>/dev/null && echo "$p"; done | wc -l | tr -d ' '); [ "$left" = 0 ] && break; sleep 1; i=$((i + 1)); done
  cmp -s "$T/tc" "$TC" && cmp -s "$T/ui" "$UI" || { echo "drill kh: files not restored after the timeout"; exit 1; }
  [ "$left" = 0 ] || { for p in $pids; do kill -9 "$p" 2>/dev/null; done; echo "drill kh: $left processes left behind"; exit 1; }
  test "$crc" = 4 && test "$(grep -c "^drill: timeout after $B s" "$T/kh.out")" = 1 && test "$god" = 1 && test "$sim" -ge 1 && test "$live" -ge 4 || { cat "$T/kh.out"; echo "drill kh: crc $crc god $god sim $sim live $live"; exit 1; }
  echo "drill kh: ok (never quits, holds a sim: $live live processes [pgid:name ${names}] before the deadline; rc 4 timeout after ${secs} s of $B; 0 left after ${i} s; files restored)"; }
stub() { # ks's child: the test never quits and leaves a stand-in for a stuck sim: spawned by Godot (OS.create_process,
  # like the sim), outside the supervisor's group, ignoring TERM/HUP/INT (inherited across exec), outliving Godot.
  mutate "$TC" 's#^\tquit\(1 if failures else 0\)$#\t_stub = OS.create_process("/bin/sh", ["-c", "trap \x27\x27 TERM HUP INT; exec sleep 747474\x30"])#; s#^var failures := 0$#var failures := 0\nvar _stub := 0#'
  run; echo "drill stub: no timeout (rc $RC)"; exit 1; }
SP='sleep 7474740$'
ks() { # quorum r2 (gpt6-1-sol): a stuck child outside the group that ignores graceful shutdown is still reaped
  [ "$(pgrep -f "$SP" | wc -l | tr -d ' ')" = 0 ] || { echo "drill ks: a '$SP' process already runs; void"; exit 3; }
  B=${KH_BOUND:-60}; rm -f "$LOG"; t0=$(date +%s)
  BOUND=$B sh "$SELF" "$PWD" stub > "$T/ks.out" 2>&1 & cp=$!
  seen=0; while [ $(($(date +%s) - t0)) -lt $((B - 5)) ]; do seen=$(pgrep -f "$SP" | wc -l | tr -d ' '); [ "$seen" -ge 1 ] && break; sleep 1; done
  sp=$(pgrep -f "$SP" | head -1); sg=$(ps -o pgid= -p "$sp" | tr -d ' '); gg=$(pgrep -f 'test_crew_console.gd' | while read -r p; do ps -o pgid=,comm= -p "$p"; done | grep -iE 'godot$' | awk '{print $1}' | head -1)
  wait "$cp"; crc=$?; secs=$(($(date +%s) - t0))
  i=0; left=1; while [ $i -lt 10 ]; do left=$(pgrep -f "$SP" | wc -l | tr -d ' '); [ "$left" = 0 ] && break; sleep 1; i=$((i + 1)); done
  cmp -s "$T/tc" "$TC" && cmp -s "$T/ui" "$UI" || { echo "drill ks: files not restored after the timeout"; exit 1; }
  [ "$left" = 0 ] || { pkill -9 -f "$SP"; echo "drill ks: the stuck child survived the deadline"; exit 1; }
  test "$crc" = 4 && test "$(grep -c "^drill: timeout after $B s" "$T/ks.out")" = 1 && test "$seen" -ge 1 && test -n "$sg" && test "$sg" != "$gg" || { cat "$T/ks.out"; echo "drill ks: crc $crc seen $seen pgid $sg godot-pgid $gg"; exit 1; }
  echo "drill ks: ok (stuck child ignoring TERM/HUP/INT in pgid $sg, Godot's $gg, seen before the deadline; rc 4 timeout after ${secs} s of $B; 0 left after ${i} s; files restored)"; }
[ $# -gt 0 ] || set -- d0 k1 k2 k3 k4 kh ks
for d; do case $d in d0|k1|k2|k3|k4|kh|ks|hang|stub) "$d" ;; *) echo "drill: unknown $d"; exit 2 ;; esac; done
echo "serial-pin-drill: ok ($# drills: $*)"
```

## Sub-milestones and estimates

| # | Work | LOC | Est. |
|---|---|---:|---|
| M1 | D1 (apply the diff), the `.gitattributes` line, AC1, AC4, AC5 | +12 | 15 min |
| M2 | Drills (AC2, AC3), D2 fragment (AC6) | +8 | 15 min |

One PR, test-only. The targeted gate is `make crew-console-test` run by the executor; the GitHub fast tier does not run it (`ci-fast` in `Makefile:55` and `mk/*.mk` lists no `crew-console-test`, V2), the nightly `make test` does.

## Conflict surface

- **Open PRs: none.** The change touches `tests/test_crew_console.gd`, `.gitattributes` and a new fragment; no open PR (#373, #379, #380, #384) touches either (V8). (`.gitattributes`: 0 hits in all four, controller, iteration 74.) #373, #379 and #380 touch `Makefile`, which this row leaves alone.
- **Existing code that shares the symbol: 7aa's reset.** `tests/test_sim_pipeline.gd:19` writes `CrewConsole._serial = 0` (V1). It cannot perturb or observe this pin: `crew-console-test` (`Makefile:160`) and `sim-pipeline-test` (`Makefile:1340`, through `$(SCRIPT_GATE)`) each start their own `godot --headless --path . --script tests/<file>.gd` process, and neither test file names the other (V12). A GDScript `static var` lives in one process.
- **Why here, not beside 7aa's suite.** The two-console flow (A sends, B is rebuilt, the real sim `us`) already exists in `test_crew_console.gd`'s `real_sim()`, and `make test` runs that target (V2). `test_sim_pipeline.gd` resets the counter at the start of each run, which would mask the property, and `make test` does not run it yet (row 7ab, V12).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A later crew-section change moves turn/revision so ids happen to differ | The id check compares two consoles built from one `us.crew` snapshot with no send between them; it does not depend on the values. k1 pins the current collision text so a drifting drill fails loudly. |
| Suite churn (an `offer_intents` or `reply_intents` call added or removed before `real_sim()`'s console A) shifts the green ordinals (today 11/12, V13) | The test compares, never pins, them; AC1/d0 match `tc0-4-[0-9]+` and require the two to differ. Only k1's per-instance `tc0-4-1` is literal, and it does not move with churn (each console starts at 0). |
| A hung Godot or sim blocks a drill and leaves files mutated or processes behind | Every `make` runs under `BOUND`; a timeout exits 4 and the EXIT trap restores (kh, V15). The sim runs in its own process group (V15: pgid ≠ godot's), so a group kill alone does not reach it; revision 2's supervisor also reaps every descendant recorded before TERM, which ks proves against a child that ignores TERM/HUP/INT and outlives Godot (V18), and whose negative control fails under the round-1 supervisor (V19). |
| The real `crew-console-test` recipe (and every `$(GODOT_SIM)` gate through `tools/script_gate.sh`) has the same hole: `Makefile:160` has no deadline at all, and `script_gate.sh`'s comment says no `--script` gate has a child outside the group, while every `$(GODOT_SIM)` gate does (V15) | **Pre-existing at `b57d279e`, not introduced here**; quorum r2 (gpt6-1-sol) asked for a runner that owns the sim for the recipe too. Split out as charter row **7ad** with that objection verbatim (gate-2 rule (c): a pre-existing defect a reviewer surfaces is a queue row, not a revision); this row changes no recipe and no runner. |
| The extra sends change what later checks see | They are placed after every existing `us` check and before `us.stop()`; the existing 100 `ok` lines are unchanged (102 = 100 + 2, V6). |
| The sim one day treats the repeat as a silent `Duplicate` | The id check still kills (k4) |
| Another test resets `_serial` mid-run | Only `tests/test_sim_pipeline.gd:19` writes it (V1), in its own Godot process (V12). |

## Open questions (defaults apply if unanswered)

- **OQ1. Also migrate `crew-console-test` through `$(SCRIPT_GATE)` here? Default: no; file it as its own row.** It is optional, touches `Makefile` (three open PRs do too, V8) and `tools/script-gate-baseline.txt:37`; the pin works through the raw target, whose recipe already fails on rc, `SCRIPT ERROR` and a non-zero failure count (`Makefile:160`). The migration would also need a summary with a nonzero count: `script_gate.sh`'s zero probe refuses `crew-console: 0 failures` (V14).
- **OQ2. Put `crew-console-test` into `ci-fast`? Default: no.** Out of scope for a hygiene row; the nightly and the executor's targeted run cover it.

## Deliverables

- `tests/test_crew_console.gd`: D1.
- `.gitattributes`: `+design_docs/** whitespace=-space-before-tab` (quorum r2, oc-kimi-k3; V17).
- `changelogs/unreleased/2026-11-06-crew-console-serial-pin.md`: D2.
- On landing: this doc to `implemented/r1/`, charter row 7ac marked landed; row 7ad (the recipe-level deadline and sim reaping, quorum r2 gpt6-1-sol) filed by the controller at iteration 74.

## Verification log

| V | Claim | Command | Observed |
|---|---|---|---|
| V1 | The counter, its id format, and who writes it | `grep -n "_serial" ui/crew_console.gd tests/*.gd`; `git ls-files "*.gd" \| xargs grep -c "_serial" \| grep -v ":0$"` (positive control: the counter's own file) | `ui/crew_console.gd:44:static var _serial := 0 …`, `:264`, `:265` (`var tag := "c%d-%d-%d" % [int(crew.get("turn", 0)), int(crew.get("revision", 0)), _serial]`), `:283`, `:285`; `tests/test_sim_pipeline.gd:19:	CrewConsole._serial = 0`; no other test; the tracked-file count: `tests/test_sim_pipeline.gd:1`, `ui/crew_console.gd:5`, nothing else |
| V2 | Which suites run the target | `grep -n 'crew-console-test' Makefile mk/*.mk .github/workflows/*.yml; grep -n '^ci-fast' Makefile mk/*.mk` | `Makefile:158` (target), `Makefile:161:test: crew-console-test`; no workflow hit; `ci-fast` lines at `Makefile:55`, `mk/script-gates.mk:27`, `mk/star-surfaces.mk:15`, none naming it. Baseline: `tools/script-gate-baseline.txt:37:crew-console-test	tests/test_crew_console.gd	rc,se,sum,-` |
| V3 | The refusal rule and pin | `grep -n 'AlteredDuplicate(p.id)' runtime/cache/registry/sunholo/social_dynamics/0.4.0/proposals.ail; grep -n social_dynamics sim/ailang.toml` | `111:    prior :: _ => if prior.body == body then Ok({… Duplicate, events: []}) else Err(AlteredDuplicate(p.id)),`; `36:"sunholo/social_dynamics" = "0.4.0" …` |
| V4 | Handed facts re-derived: same-crew consoles collide per-instance; A's send moves revision 0 → 4 | 7aa A4 extracted with `awk` to `.godot/tmp/7ac/ids.gd` (29 lines); `godot --headless --path . --script "$PWD/.godot/tmp/7ac/ids.gd" \| grep -E '^K7IDS\|^k7-ids\|SCRIPT ERROR'`, static then with `perl -pi -e 's/^static var _serial := 0 /var _serial := 0 /' ui/crew_console.gd`; file restored, `cmp` ok | Static (3 s): `a=tc0-0-1-counselor b=tc0-4-2-counselor c=tc0-4-3-counselor turn=0.0 revision=4.0`, `b_and_c_same=false`, `b_refused=0`, `c_refused=0`, `k7-ids: done`. Per-instance (3 s): `b=tc0-4-1-counselor c=tc0-4-1-counselor`, `b_and_c_same=true`, `b_refused=0`, `c_refused=2 crew:blocked:altered_duplicate:offer-tc0-4-1-counselor,crew:{"host":"request capacity/id/clock"}`, `k7-ids: done`. No `SCRIPT ERROR` |
| V5 | HEAD's test does not pin it (control) | HEAD's `tests/test_crew_console.gd`, line 44 per-instance; `make --no-print-directory crew-console-test AILANG=runtime/bin/ailang`; `grep -cE '^ok ' …; grep -E '^FAIL\|^crew-console\|rebuilt\|re-sending' .godot/tmp/crew-console.log`; restored | rc 0, 17 s, `100`, `ok a rebuilt console in the same crew turn makes new task and request ids`, `ok re-sending an old id is refused (…)`, `crew-console: 0 failures`, no FAIL. (Controller, same clone: rc 0, 18 s per-instance; rc 0, 54 s static, cold) |
| V6 | D1 end to end: green twice, red per-instance | D1 applied; `make --no-print-directory crew-console-test AILANG=runtime/bin/ailang` ×2; then per-instance; `grep -E '^ok 7ac\|^FAIL\|^crew-console' …; grep -c '^ok ' …; grep -c 'SCRIPT ERROR' …` | Run 1: rc 0, 13 s, `102`, both `ok 7ac …` lines as in AC1, `crew-console: 0 failures`, 0 SCRIPT ERROR. Run 2: rc 0, 13 s, the same. Per-instance: rc 2 (make), 14 s, `100`, `FAIL 7ac two consoles from one crew, no send between, make different ids (tc0-4-1-counselor, tc0-4-1-counselor)`, `FAIL 7ac the sim takes both consoles' offers, nothing refused ([] [{ "i": 0.0, "reason": "crew:blocked:altered_duplicate:offer-tc0-4-1-counselor" }, { "i": 1.0, "reason": "crew:{\"host\":\"request capacity/id/clock\"}" }])`, `crew-console: 2 failures`; the two pre-existing id checks stay `ok`; 0 SCRIPT ERROR |
| V7 | The drills (round 0, unbounded runner; superseded by V15) | D1 applied; `sh drill.sh "$PWD"` (the `sh 7ac-drill` block); `git status --porcelain`; `cmp` of both files against D1-applied / HEAD copies | the five lines of the drill table verbatim (`drill d0: ok (unmodified: rc 0, both 7ac checks ok, 102 ok)` … `drill k4: ok (sim check removed: the id check alone is red, rc 2)`), `serial-pin-drill: ok (5 drills: d0 k1 k2 k3 k4)`, rc 0, 78 s; status ` M tests/test_crew_console.gd` only; `files-as-expected` |
| V8 | Conflict surface; changelog convention | `gh pr diff <n> --repo sunholo-data/stapledons-godot --name-only` for 373, 379, 380, 384, grep for `test_crew_console\|Makefile`; `git log --format='%h %s' -3 -- changelogs/unreleased`; `sed -n 1,5p changelogs/unreleased/README.md` | `Makefile` in #373, #379, #380; not in #384; `tests/test_crew_console.gd` in none (the four lists name `tests/test_physics.gd`, `tests/test_earth_feed.gd` and others). Latest fragment commit `da7afacf … row 7aa M2: … changelog fragment` (`2026-11-06-sim-pipeline-test.md`, a `### Fixed` section); README: one `YYYY-MM-DD-<slug>.md` per change |
| V9 | Size and hygiene | D1 applied: `git diff --numstat; git diff --check; make --no-print-directory script-gate-lint uid-guard python-guard AILANG=runtime/bin/ailang`; D1 from this doc: `x 'diff 7ac-test' > /tmp/7ac.diff; git apply --check /tmp/7ac.diff` on the restored tree | `11	0	tests/test_crew_console.gd`; `--check` silent; lint `ok (239 --script invocations: 121 through $(SCRIPT_GATE), 118 on the baseline; …)`, `script-gate-prereqs: ok (…)`, `uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`; `apply --check` silent, rc 0 |
| V10 | Tree restored | `git status --porcelain; git diff --stat` | round 0: `?? design_docs/planned/r1/m4-7ac-serial-pin.md` only, `git diff --stat` empty. Revision 1 (doc committed as `ffc376ab`): ` M design_docs/planned/r1/m4-7ac-serial-pin.md` only; `--stat` names this doc alone |
| V11 | The ACs as printed, from this doc's blocks (round 0; revision 1 is V16) | `x 'diff 7ac-test'` and `x 'sh 7ac-drill'` `cmp`-identical to the files run in V6/V7 (32 and 34 lines); `git apply` of the extracted diff; AC1–AC5 typed as in the table (bash); then the test file copied back | AC1 twice: `rc=0`, both `ok 7ac` lines, `crew-console: 0 failures`, `102` (30 s for both). AC2: `drill k1: ok …`, `serial-pin-drill: ok (1 drills: k1)`, `rc=0`. AC3: the five drill lines, `serial-pin-drill: ok (5 drills: d0 k1 k2 k3 k4)`, `rc=0`, 80 s; status ` M tests/test_crew_console.gd` and this doc. AC4: `11	0	tests/test_crew_console.gd`, `0`. AC5: silent, then the lint, `uid-guard` and `python-guard` lines of V9. AC6 not run (the fragment is the executor's) |
| V12 | Each suite target is its own Godot process; the two tests share nothing | `sed -n 158,161p Makefile; sed -n 1339,1340p Makefile`; `grep -nE -- '--script tests/test_(crew_console\|sim_pipeline)\.gd' Makefile mk/*.mk`; `grep -nE '^[a-z-]+: .*(sim-pipeline-test\|crew-console-test)' Makefile mk/*.mk`; `grep -c 'test_sim_pipeline\|sim-pipeline' tests/test_crew_console.gd; grep -c 'test_crew_console\|crew-console' tests/test_sim_pipeline.gd` (control: `grep -c CrewConsole tests/test_sim_pipeline.gd`) | `:160` `@$(GODOT_SIM) --headless --path . --script tests/test_crew_console.gd > $(SCRATCH)/crew-console.log 2>&1; …`, `:161 test: crew-console-test`; `:1340` `@$(SCRIPT_GATE) sim-pipeline-test $(SCRATCH)/sim-pipeline.log 600 '^sim-pipeline: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_sim_pipeline.gd`; one `--script` hit per file (`Makefile:160`, `Makefile:1340`); the only aggregate line is `Makefile:161:test: crew-console-test` (no `test: sim-pipeline-test`); cross-references `0` and `0`; control `3` |
| V13 | Where the green ordinals come from | scratch trace (restored, `cmp` ok): `print("SERIAL offer\|reply %d")` after each `_serial += 1` in `ui/crew_console.gd`, `print("SECTION …")` before each section and before A, B, D in the test; `AILANG_BIN="$(command -v runtime/bin/ailang)" godot --headless --path . --script tests/test_crew_console.gd` | rc 0, 12 s; `palette`, `board`, `calls`, `enabled_flags`: none; `locks`: offer 1, 2; `keys`: offer 3, reply 4; `stand_down`: none; `real_sim` before A: offer 5–8, reply 9; A offer 10; B offer 11; D offer 12, 13 (13 is the later `old` console's); `crew-console: 0 failures` |
| V14 | `tools/script_gate.sh` refuses the green summary (why the drill has its own supervisor) | `sh tools/script_gate.sh crew-console-test .godot/tmp/7ac/sg-green.log 600 '^crew-console: 0 failures$' -- AILANG_BIN="$(command -v runtime/bin/ailang)" godot --headless --path . --script tests/test_crew_console.gd; echo rc=$?; grep -c '^crew-console: 0 failures$' .godot/tmp/7ac/sg-green.log` (D1 applied) | `script-gate: crew-console-test FAIL; summary 'crew-console: 0 failures' carries no nonzero count (print one, e.g. N passed, 0 failures) …`, `rc=1`; positive control: the log does hold the line, `1` (and 102 `ok`) |
| V15 | The bounded drills, the deadline drill and its process evidence | D1 applied; the `sh 7ac-drill` block at `.godot/tmp/7ac/drill.sh`; `sh .godot/tmp/7ac/drill.sh "$PWD"`; then `git status --porcelain`, `cmp` of both files; then `sh .godot/tmp/7ac/drill.sh "$PWD" kh` alone (pgid:name listing); exploratory runs before it with `ps -o pid,ppid,pgid,command` | Full set: the six lines of the table (`drill d0: ok (unmodified: rc 0, 0 failures, 102 ok, ids tc0-4-11 tc0-4-12 distinct, sim refused nothing)` … `drill kh: ok (…; rc 4 timeout after 60 s of 60; 0 left after 0 s; files restored)`), `serial-pin-drill: ok (6 drills: d0 k1 k2 k3 k4 kh)`, rc 0, 136 s; status ` M tests/test_crew_console.gd`, `files-as-expected`. kh alone (60 s): `5 live processes [pgid:name 64949:perl 64984:make 64984:sh 64984:godot 65492:ailang ]`: make, sh and godot share the supervisor's group, the sim has its own; all 5 gone 0 s after the child's exit. Exploratory: without a held sim, removing `quit()` and `old.stop()` left only godot hung (the sim had exited with the freed bridge), hence the member `SimBridge` |
| V16 | Revision 1's ACs as printed | the `diff 7ac-test` and `sh 7ac-drill` blocks extracted with `x` and `cmp`-compared to the files run in V15; AC1 (twice), AC2, AC3, AC4, AC5 typed as in the table (bash) on the D1-applied tree; then the test file copied back | Blocks `cmp`-identical (`diff 7ac-test` 32 lines, `sh 7ac-drill` 64). AC1: twice `drill d0: ok (unmodified: rc 0, 0 failures, 102 ok, ids tc0-4-11 tc0-4-12 distinct, sim refused nothing)`, `serial-pin-drill: ok (1 drills: d0)`, `rc=0` (27 s for both). AC2: `drill k1: ok …`, `rc=0`, 14 s. AC3: the six lines (kh: `[pgid:name 68860:perl 71239:make 71239:sh 71239:godot 72434:ailang ]`, `rc 4 timeout after 60 s of 60; 0 left after 0 s; files restored`), `serial-pin-drill: ok (6 drills: d0 k1 k2 k3 k4 kh)`, `rc=0`, 132 s; status: this doc and the test file. AC4: `11	0	tests/test_crew_console.gd`, `0`. AC5: the unscoped `git diff --check origin/main` printed 15 `space before tab in indent` lines, all in this doc's embedded diff (lines 70–96), so AC5 now excludes `design_docs`; scoped, it is silent (rc 0); lint 121/118, `uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)` |
| V17 | Revision 2 (controller): the `.gitattributes` exemption is scoped to `design_docs` | doc and D1 applied, `.gitattributes` + `design_docs/** whitespace=-space-before-tab`; `git diff --check origin/main; echo rc=$?`; control 1: `git show HEAD:.gitattributes > .gitattributes; git diff --check origin/main \| grep -c 'space before tab'`, then restored; control 2: `printf ' \tbad\n' > tests/zz_probe.txt; git add -N tests/zz_probe.txt; git diff --check origin/main \| grep -c zz_probe`, then removed; `grep -rn 'diff --check' .github/ Makefile mk/ tools/*.sh` | rc 0, silent; control 1: `15`; control 2: `1` (`tests/zz_probe.txt:1: space before tab in indent.`); no CI, Makefile or tool runs `git diff --check` (empty; AC5 is the only runner). Open PRs #373, #379, #380, #384 touch neither `.gitattributes` nor the test file (0 hits each) |
| V18 | Revision 2's drills and ACs as printed (controller, 11:35–11:50 CET, tree `8265dc35` + revision 2) | `x 'sh 7ac-drill'` and `x 'diff 7ac-test'` `cmp`-identical to the files run; `sh .godot/tmp/7ac/drill.sh "$PWD"`; then AC1 (twice), AC4, AC5 typed as in the table; `git status --porcelain`; `pgrep -f 'sleep 7474740'` | `drill d0: ok (unmodified: rc 0, 0 failures, 102 ok, ids tc0-4-11 tc0-4-12 distinct, sim refused nothing)`, k1–k4 as the table, `drill kh: ok (never quits, holds a sim: 5 live processes [pgid:name 92518:perl 94519:make 94519:sh 94519:godot 95304:ailang ] before the deadline; rc 4 timeout after 60 s of 60; 0 left after 0 s; files restored)`, `drill ks: ok (stuck child ignoring TERM/HUP/INT in pgid 99585, Godot's 98194, seen before the deadline; rc 4 timeout after 60 s of 60; 0 left after 0 s; files restored)`, `serial-pin-drill: ok (7 drills: d0 k1 k2 k3 k4 kh ks)`, rc 0, 194 s. AC1 twice `drill d0: ok (… 102 ok, ids tc0-4-11 tc0-4-12 distinct …)`, rc 0 (30 s both). AC4 `1	0	.gitattributes`, `11	0	tests/test_crew_console.gd`, `0`. AC5 silent (rc 0), lint 121/118, `uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`. Status: `.gitattributes`, this doc, the test file. pgrep: rc 1 |
| V19 | ks's negative control: the round-1 group-only supervisor leaves the stuck child | the drill with `bounded()` replaced by revision 1's (from `git show 8265dc35:<this doc>`); `sh drill_oldsup.sh "$PWD" ks`; then `pgrep -f 'sleep 7474740' \| wc -l` | rc 1, 71 s, `drill ks: the stuck child survived the deadline` (the drill then `pkill -9`s it); afterwards `0` |
