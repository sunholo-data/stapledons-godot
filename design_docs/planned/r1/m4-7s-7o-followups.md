# Follow-up batch: ruling-guard controls and a spec-row count (row 7s), rig_check failure status (row 7o)

**Status:** Planned (mission iteration 44, designer, 2026-10-21). **Release:** r1. **Milestone:** M4.5, follow-up backlog rows **7s** (clause 4 hygiene, test-only, under approved sprint `R1-M4-JOURNEY`, D-22/D-66) and **7o** (clause 5 tooling), batched into one PR as Mark ordered on 2026-10-20 ("batch several small items into one PR"). The same row-count change also closes backlog row **7i(l)**.
**Priority:** P2 (backlog). 7o first: a red rig run currently reads as a run still in flight.
**Implements:** [charter](../../stapledon-mission.md) queue rows 7o and 7s and backlog row 7i(l); the parent [m4-7q-ruling-pin-controls.md](m4-7q-ruling-pin-controls.md) and its evaluation [`eval_R1-M4-JOURNEY_7q_round_1.json`](../../../.ailang/state/evaluations/eval_R1-M4-JOURNEY_7q_round_1.json) (N2, N3, N4); [m4-first-journey.md](m4-first-journey.md) AC4 as amended by D-77 A and D-78 A, unchanged. The rig-first merge rule (Mark, 2026-10-19; attended #278, merge `ff13700`) is the 7o context. The [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) is untouched.
**Depends on:** 7q landed (PR #288, merge `9fe354d`, 28 control rows); D-88 A; AILANG v0.54.14, Godot 4.7.2. No package, sim, protocol, physics, scene or player-visible change.
**Estimated LOC:** about **85**, all test or tooling: `tools/rig_check.sh` 2 changed lines plus 1 comment line (the only behaviour change: the status description, plus the failure reason and log path now always reaching stdout); the new `tools/test_rig_check.sh` (~53); `mk/m45.mk` 4 changed loop lines plus a 7-line target; three compact fixtures (~21 data lines). Zero lines in `tests/display_audit.gd` and `Makefile`.
**Evidence:** the Verification log below. I ran every row first-hand in this clone at `4bf95435` (origin/main), using throwaway copies under `mktemp -d` and EXIT-trap restores. After every run, `git status --porcelain` listed only the untracked Godot `*.uid` files.

## Game vision alignment

Scored against [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No journey input or commit path changes. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | Clocks and timing untouched. |
| The Ship Is Home | 0 | 0 | No scene, card or UI change. |
| Grounded Strangeness | 0 | 0 | No world or visual change. |
| We Are Not Built For This | 0 | 0 | No crew or consequence change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | The D-77/D-78 tuples stay pinned exactly as ruled. Three more controls prove the kind pins load-bearing, which is a stricter ratchet over the same acceptance. |
| **Net** | | **0** | **Go.** 7s is test/audit hygiene inside the approved `R1-M4-JOURNEY` sprint with no pillar below 0, so D-88 A applies. 7o is merge-tooling hygiene that Mark named in the loop's follow-up backlog himself (2026-10-20 order) and asked to be batched. No pillar is negative. |

## Problem

**7o: a red rig run looks pending forever.** `fail()` (`tools/rig_check.sh:42`) posts `"$1 (log on the Studio: $log)"`. On the Studio, `$TMPDIR` is 49 characters and ends in `/`, so `log` is 104 characters (V1). That puts every failure description except `clone failed` over GitHub's 140-character limit; `make test failed or ran over 5400s` comes to 160 (V2). The script runs under `set -eu`, and `fail` is the last command of its AND-OR list, so the refused `gh api` call aborts `fail()` before its `echo`. The script then exits 1 with no `rig-check: FAIL:` line, and `rig/full` stays at the `pending` it posted first. A stub `gh` that refuses like GitHub reproduces the 160 and the stuck `pending` exactly (V3). Two further holes:

- The runtime-mismatch reason embeds `$have`, the output of `ailang --version`, so its length is unbounded.
- The success description also embeds that version line. It fits today (57 and 71 characters, V2), but nothing caps it.

**7s(a): three `ruling_valid` guards have no control.** On the clean tree, deleting the D-77 kind pin (E1), deleting the D-78 kind pin (E2), deleting the `accepted_by is String` guard (E5), or flipping that guard to `return true` (E5b, not in the eval) each leaves `make display-audit-controls` at rc 0 with 28 rows (V9).

**7s(b) and 7i(l): nothing in make counts the spec rows.** Deleting any row stays green (eval E7; 7i(l) E5).

**7s(c): the D-78 caption list.** Covered below; the premise is false.

**7s(d): a record overstates coverage.** The title of `080b4f7` claims "each ruling_valid pin has an isolating control". E1 and E2 show that is not yet true.

**Found while measuring: the loop's script-error guard is dead.** At `mk/m45.mk:26`, `! grep -q 'SCRIPT ERROR:' …;` is a standalone command inside `set -e`. POSIX exempts `!` pipelines from `set -e`, so the guard can never fail (V13). Mutant S1 injects a GDScript runtime error on the known-ruling path. Today it leaves 8 per-row logs containing `SCRIPT ERROR:`, and make still reports rc 0 with 28 rows "rejected". The hardened drill shape that 7q copied inherits the same dead line, twice over. Its `! grep -q 'SCRIPT ERROR:' "$T/mutant.log"` is exempt from `set -e` in the same way. It also greps make's stdout, which never contains Godot output because each row's output goes to its own log.

### Measured verdicts and premise corrections

- **E1 is killable by a one-field fixture.** Change the D-77 entry's `kind` to `unbound`. Unmutated, the loader rejects it with `known-ruling`. Under E1 it loads, but the matcher's kind equality then fails it as `NEW transit-ISM` plus `stale-known`. The make signature is `wrong reason (want known-ruling)`, the same class as 7q's D2–D4 (V10, V14). The pin is partly redundant with the matcher, as the row suspected, but it is not equivalent: the mutant is observably different.
- **E2 is killable, but not by a one field.** A D-78 entry whose only change is `kind: transit-ISM` fails the loader's field check (`known-file invalid entry fields`) both before and after E2, because a transit-ISM entry needs `folding_card` and `accompanying_card` (V10). Adding the two card fields the loader requires, with the pinned D-77 values, gives a fixture that only the D-78 kind pin rejects. Under E2 it loads, and the matcher then fails it as `NEW unbound` plus `stale-known` (V14).
- **E5 is an equivalent mutant.** `match entry.accepted_by:` compares against String patterns only. GDScript's `match` never matches a value of another type, so any non-String value falls through to the final `return false` (`tests/display_audit.gd:64`) with or without the guard. Measured with five JSON types (number, null, bool, array, object): every one gives an identical result under E5, which is rc 1, `FAIL known-ruling invalid acceptance` and no `SCRIPT ERROR` (V11). It is recorded as equivalent and the guard stays, as documentation. The guard's behaviour is still pinned, though: the **flip** E5b is killed by a non-String fixture as `missed` (V14).
- **7s(c)'s premise is false.** All four D-78 captions are already exercised, positively. `known_findings.json` accepts all four against the four labels in `known.ndjson`, and the positive control (`mk/m45.mk:18`) needs rc 0 and `failures=0`. Dropping any one caption from the accepted list (C1–C4) fails make at that line, before the loop (V12, V15). The one negative fixture (`known_wrong_caption.json`) already kills deletion of the whole text clause (eval E4). Swapping the other three texts would kill no further mutant, because every swap hits the same `in [...]` clause. So no new caption fixture is added; C1–C4 become recorded drills.
- **7o's numbers are confirmed exactly.** Log path 104 and description 160 (V1–V3). One addition: on this rig, **every** failure reason except `clone failed` (138) is over the limit (V2).

## Goals and non-goals

**Goals.**
- 7o: `rig_check.sh` never posts a description over 140 characters, and always prints the failure reason and log path, even when the post is refused. A network-free control inside `make test` proves it.
- 7s: E1, E2 and E5b are killed with exact signatures, and E5 is recorded as equivalent with evidence.
- 7s(b) and 7i(l): the loop asserts its own row count, 31.
- The loop's script-error guard is made live.
- The 7q coverage claim is corrected on the record.

**Non-goals.**
- No `ruling_valid`, matcher or `tests/display_audit.gd` change.
- No new caption fixture (the 7s(c) measurement above).
- No `Makefile`, `ci-fast` or `tools-test` edit; those are held (Deferred).
- No change to `rig_check.sh`'s flow, timeouts, clone, runtime pin or pending/success wording, beyond the length cap.
- No Python.

## Design

### 1. Row 7o: cap every description, report before posting

Two edits in `tools/rig_check.sh`, measured on a copy (V5):

```diff
 status() {
   [ "${RIG_NO_STATUS:-0}" = 1 ] && return 0
-  gh api "repos/$REPO/statuses/$sha" -f state="$1" -f context=rig/full -f description="$2" > /dev/null
+  # GitHub refuses a description over 140 characters (row 7o): cut every post to fit.
+  gh api "repos/$REPO/statuses/$sha" -f state="$1" -f context=rig/full -f description="$(printf %s "$2" | cut -c1-140)" > /dev/null
 }
@@
-fail() { status failure "$1 (log on the Studio: $log)"; echo "rig-check: FAIL: $1"; exit 1; }
+fail() { echo "rig-check: FAIL: $1 (log: $log)"; status failure "$short: $1" || echo "rig-check: could not post the failure status"; exit 1; }
```

- **Where the cap lives.** It is in `status()`, so pending, success and failure are all covered, including the unbounded `$have` and version-line cases.
- **What the description holds.** The failure description becomes `<short sha>: <reason>`, with the sha first so the cut keeps it. `4bf95435: make test failed or ran over 5400s` is 44 characters. `short` is the script's existing 8-character variable, `short=$(printf %s "$sha" | cut -c1-8)` at `tools/rig_check.sh:29`. It is set before `fail()` is defined (:42) and before the first `fail` call (:45), so `set -u` cannot trip on it inside `fail()` (V19). No other line of the script changes: the diff is exactly the two lines shown plus one comment line (V20).
- **Where the log path goes.** It moves to stdout. The start line already prints it, and the controller reads stdout.
- **Order of the failure path.** `fail()` echoes first. Then a refused post (an outage, say) is reported, not fatal, and the exit stays 1.
- **The pending post.** It is unchanged: if `pending` cannot post, the script still aborts before posting anything, so there is no stuck status to leave behind.

### 2. Row 7o control: `tools/test_rig_check.sh` in `make test`

**Home.** `tools/test_rig_check.sh` sits beside its precedents `tools/test_sky_assets.sh` and `tools/test_lens_assets.sh`, the hermetic tests of `tools/` scripts. It is wired from `mk/m45.mk`:

```make

# Row 7o: tools/rig_check.sh posts only status descriptions GitHub accepts (at most 140 characters)
# and still reports a failure when a post is refused; stubs only (gh, git, make), no network.
# Lives here while the Makefile is held; it belongs in tools-test and ci-fast (deferred).
.PHONY: rig-check-control
rig-check-control: ## Row 7o: rig_check.sh status descriptions fit GitHub's 140-character limit
	@sh tools/test_rig_check.sh tools/rig_check.sh
test: rig-check-control
```

**Why `mk/m45.mk`.** The natural homes are `tools-test` and `ci-fast`, and both are defined in the held `Makefile`. A new `mk/*.mk` would need an `include` line in the `Makefile`. So the choice is among the already-included, unheld mk files, and `m45.mk` is the least surprising of them:

- It is already the home of the suite's negative and positive controls (`display-audit-controls`, `replay-positive-control`).
- This PR touches it anyway, so the batch's make surface is one file.
- The other candidates are each owned by a feature: `ai.mk`, `site.mk`, `ism.mk`, `m5.mk`, `constellations.mk`, `home-tiers.mk`, `deck-layout.mk`, `navigation-usability.mk` and `planet-presentation.mk`. Rig tooling would be a stranger there.
- The comment says where it belongs.

**What the control does.** It is POSIX `sh`, about 2 s, and touches no network (V5). It puts stubs on `PATH` for `rig_check.sh` only:

| Stub | Behaviour |
|---|---|
| `gh` | `pr view` prints a 40-character sha. `api …/statuses` appends `state length description` to a log and refuses any description over 140 characters with exit 1 and `Validation failed: Description is too long (maximum is 140 characters) (HTTP 422)`, the way GitHub does. It also refuses one named state on request. |
| `git` | `clone` creates the directory with a one-line `Makefile` pin and a stub `runtime/bin/ailang` that prints `$STUB_VERSION`; every other `git` call succeeds. |
| `make` | Fails only for the named target. |

It runs four cases, each counted, and the script exits nonzero if any case fails:

| Case | Set-up | Asserts |
|---|---|---|
| `make-test-red` | `RIG_DIR` padded so `log` is the rig's 104 characters, `make test` fails | rc 1; posts `pending`, then an accepted `failure` whose stub-log line matches `^failure <n> 01234567: make test failed`, so the description must **begin** with the 8-character sha (`long-reason` anchors the same way); stdout `rig-check: FAIL: make test failed … (log: ….log)`. This is the #252 scenario; the pre-fix script posts 160. |
| `long-reason` | a 207-character version line, so the reason alone is over 140 | rc 1; accepted `failure`; stdout has the reason |
| `long-success` | the version line carries the pin plus 200 characters, every make succeeds | rc 0; accepted `success`; `rig-check: ok, 01234567 green` |
| `failure-refused` | the stub refuses every `failure` post | rc 1; stdout has `rig-check: FAIL: …` and `rig-check: could not post the failure status` |

The full script as measured (V4, V5) follows. Copy it verbatim, changing only the header comment's path:

```sh
#!/bin/sh
# Row 7o control: tools/rig_check.sh must post only descriptions GitHub accepts (at most 140
# characters) and must report a failure even when a post is refused. No network: gh, git and
# make are stubs on PATH; the stub gh refuses a long description the way GitHub does (HTTP 422).
#   sh tools/test_rig_check.sh [path/to/rig_check.sh]
set -eu
RIG=$(cd "$(dirname "${1:-tools/rig_check.sh}")" && pwd -P)/$(basename "${1:-tools/rig_check.sh}")
T=$(mktemp -d "${TMPDIR:-/tmp}/rig-check-control.XXXXXX")
trap 'rm -rf "$T"' EXIT
export STUB_POSTS="$T/posts" STUB_SHA=0123456789abcdef0123456789abcdef01234567
mkdir "$T/bin"
cat > "$T/bin/gh" <<'STUB'
#!/bin/sh
[ "$1" = pr ] && { echo "$STUB_SHA"; exit 0; }
for a; do case "$a" in state=*) s=${a#state=} ;; description=*) d=${a#description=} ;; esac; done
n=$(printf %s "$d" | wc -m | tr -d ' ')
[ "$n" -le 140 ] && [ "$s" != "${STUB_REFUSE:-}" ] || { echo "$s $n refused" >> "$STUB_POSTS"; echo 'Validation failed: Description is too long (maximum is 140 characters) (HTTP 422)' >&2; exit 1; }
echo "$s $n $d" >> "$STUB_POSTS"
STUB
cat > "$T/bin/git" <<'STUB'
#!/bin/sh
[ "$1" = clone ] || exit 0
for d; do :; done
mkdir -p "$d/runtime/bin"; echo 'AILANG_RELEASE ?= v0.54.14' > "$d/Makefile"
printf '#!/bin/sh\necho "%s"\n' "$STUB_VERSION" > "$d/runtime/bin/ailang"; chmod +x "$d/runtime/bin/ailang"
STUB
printf '#!/bin/sh\ncase " $* " in *" $STUB_MAKE_FAIL "*) exit 1 ;; esac\n' > "$T/bin/make"
chmod +x "$T/bin/gh" "$T/bin/git" "$T/bin/make"
long=$(printf '%0200d' 0)
pad="$T/rig-check/"; while [ ${#pad} -lt 100 ]; do pad="${pad}x"; done   # the rig's 104-character log path
# run <case> <want rc> <want final state> <want description (ERE)> <want stdout (ERE)> <version> <failing make target> <RIG_DIR>
fails=0
run() {
  : > "$STUB_POSTS"; why=
  rc=0; STUB_VERSION=$6 STUB_MAKE_FAIL=$7 RIG_DIR=$8 RIG_NO_STATUS=0 PATH="$T/bin:$PATH" sh "$RIG" 7 > "$T/out" 2>&1 || rc=$?
  test "$rc" = "$2" || why="rc $rc, want $2"
  if grep -q refused "$STUB_POSTS"; then why="$why; refused: $(grep refused "$STUB_POSTS" | tr '\n' ' ')"; fi
  test "$(cut -d' ' -f1 "$STUB_POSTS" | tr '\n' ' ')" = "pending $3 " || why="$why; posts: $(cut -d' ' -f1-2 "$STUB_POSTS" | tr '\n' ' ')"
  grep -Eq "^$3 [0-9]+ $4" "$STUB_POSTS" || why="$why; no $3 description /$4/"
  grep -Eq "$5" "$T/out" || why="$why; no stdout /$5/"
  if [ -z "$why" ]; then echo "rig-check control $1: ok"; else echo "rig-check control $1: FAIL ($why)"; fails=$((fails + 1)); fi
}
run make-test-red 1 failure '01234567: make test failed' '^rig-check: FAIL: make test failed.*\.log\)$' 'AILANG v0.54.14' test "$pad"
run long-reason 1 failure "01234567: runtime is 'AILANG 0{100}" '^rig-check: FAIL: runtime is ' "AILANG $long" none "$T/r2"
run long-success 0 success 'make test green on the Studio' '^rig-check: ok, 01234567 green' "AILANG v0.54.14 $long" none "$T/r3"
# A refused failure post (GitHub down, say) still prints the reason and the log, and exits 1.
: > "$STUB_POSTS"; rc=0
STUB_REFUSE=failure STUB_VERSION='AILANG v0.54.14' STUB_MAKE_FAIL=test RIG_DIR="$T/r4" RIG_NO_STATUS=0 PATH="$T/bin:$PATH" sh "$RIG" 7 > "$T/out" 2>&1 || rc=$?
if test "$rc" = 1 && grep -Eq '^rig-check: FAIL: make test failed.*\.log\)$' "$T/out" && grep -qx 'rig-check: could not post the failure status' "$T/out"; then
  echo 'rig-check control failure-refused: ok'
else echo "rig-check control failure-refused: FAIL (rc $rc)"; fails=$((fails + 1)); fi
echo "rig-check control: 4 cases, $fails failures"
test "$fails" = 0
```

No `!` assertion appears anywhere in this script, nor in the drill functions below. The refused-post check is an `if grep -q refused …; then why=…; fi` (quorum r1, gemini-4-argon). That keeps the new code free of the `!`-pipeline footgun this doc removes from `mk/m45.mk`. Every assertion feeds `why` or `fails`, and the last command is `test`.

### 3. Row 7s: three fixtures, three spec rows, a row count, a live script-error guard

**Fixtures.** Each is a copy of `known_findings.json` in the compact one-entry-per-line style of `known_wrong_kind.json`, with the D-77 entry's `accepted_by` set to `"D-77"`. Each changes exactly the fields named, and every other byte stays as in `known_findings.json`:

| Fixture | Entry | Change | Unmutated result | Kills |
|---|---|---|---|---|
| `known_wrong_transit_kind.json` | transit-ISM (D-77) | `"kind": "unbound"`; all other fields kept, including both card fields | `FAIL known-ruling invalid acceptance` + `FAIL NEW transit-ISM` | E1 |
| `known_wrong_caption_kind.json` | `Cruise N - beta` (D-78) | `"kind": "transit-ISM"`, plus `"folding_card": "/root/ShipGeometryDemo/@CanvasLayer/@Control/Cards/Card_medium_notice", "accompanying_card": "/root/ShipGeometryDemo/@CanvasLayer/@Control/Cards/Card_notice"` after `observed_samples`. The loader requires both fields for that kind; without them the only rejection is `known-file invalid entry fields`, before and after E2 (V10). | `FAIL known-ruling invalid acceptance` + `FAIL NEW unbound` | E2 |
| `known_nonstring_ruling.json` | transit-ISM (D-77) | `"accepted_by": 77` (a JSON number, the plausible typo; all five non-String types behave alike, V11) | `FAIL known-ruling invalid acceptance` + `FAIL NEW transit-ISM` | E5b |

**`mk/m45.mk` loop**, rehearsed as written (V14). There are four line edits:

1. The `for` line becomes `@set -e; n=0; for spec in …`.
2. Append `'known known_wrong_transit_kind.json known-ruling' 'known known_wrong_caption_kind.json known-ruling' 'known known_nonstring_ruling.json known-ruling'` after the `known_wrong_caption_node.json` triple. Row order is kill order: under each mutant, the first failing row is the new one.
3. The body's first line becomes `n=$$((n + 1)); set -- $$spec; …`.
4. The dead guard is replaced. The old text:

   ```make
   ! grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-$$case-$$known.log;
   ```

   becomes:

   ```make
   if grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-$$case-$$known.log; then echo "display control $$case/$$known script error"; exit 1; fi;
   ```

   Then `done` becomes:

   ```make
   done; test $$n -eq 31 || { echo "display control rows: $$n, want 31"; exit 1; }
   ```

The count is a self-count, so adding a row means bumping 31 in the same diff. That is intended: a deletion now has to be a visible edit (7i(l)). The four non-loop controls (lines 17–21) already chain `&& ! grep …` inside AND lists. Those guards are live and stay unchanged.

**Correcting the record (7s(d)).** The executor's sprint-JSON note and the landing commit body state, citing `080b4f7`:

> `080b4f7`'s title overstated coverage. E1 and E2 survived until this row. E5 (deleting the type guard) is an equivalent mutant (V11), and its flip E5b is now controlled.

History is not rewritten.

## Acceptance criteria

Run these from the implementation root with `PATH="$PWD/runtime/bin:$PATH"` and `AILANG="$PWD/runtime/bin/ailang"`. First save the Test-plan block as `.godot/tmp/iter44-drills.sh`.

| # | Command | Expected output |
|---|---|---|
| AC1 | `make rig-check-control > .godot/tmp/7o.log 2>&1; echo "rc=$? $(tail -1 .godot/tmp/7o.log)"` | `rc=0 rig-check control: 4 cases, 0 failures` |
| AC2 | `git show 4bf95435:tools/rig_check.sh > .godot/tmp/rig_check.4bf95435.sh; sh tools/test_rig_check.sh .godot/tmp/rig_check.4bf95435.sh \| tail -1` | `rig-check control: 4 cases, 4 failures` (RED on the pre-fix script, V4) |
| AC3 | `make -qp AILANG="$AILANG" 2>/dev/null \| grep '^test:' \| tr ' ' '\n' \| grep -cx rig-check-control` | `1` (inside `make test`) |
| AC4 | `sh -c '. .godot/tmp/iter44-drills.sh; for d in R1 R2 R3; do drill7o "$PWD" $d \|\| exit 1; done' && git diff --quiet -- tools/rig_check.sh && echo killed` | `killed` |
| AC5 | `make display-audit-controls AILANG="$AILANG" > .godot/tmp/7s-controls.log 2>&1 && grep -c ': rejected$' .godot/tmp/7s-controls.log && (cd .godot/tmp/display-audit/playthrough && grep -lx 'FAIL known-ruling invalid acceptance' display-known-known_wrong_transit_kind.json.log display-known-known_wrong_caption_kind.json.log display-known-known_nonstring_ruling.json.log \| wc -l \| tr -d ' ')` | `31`, then `3` |
| AC6 | `sh -c '. .godot/tmp/iter44-drills.sh; for d in E1 E2 E5 E5b E7 E7b S1 C1 C2 C3 C4; do drill7s "$PWD" $d \|\| exit 1; done' && git diff --quiet -- tests/display_audit.gd mk/m45.mk && echo killed` | `killed`. Each kill signature is as in the Test plan; E5 is asserted equivalent. About 7 minutes. |
| AC7 | `grep -c "^[[:space:]]*! grep -q 'SCRIPT ERROR:'" mk/m45.mk` | `0` (the dead guard is gone; S1 in AC6 proves its replacement live) |
| AC8 | `git diff --name-only origin/main...HEAD \| grep -cvE '^(tools/rig_check\.sh\|tools/test_rig_check\.sh\|mk/m45\.mk\|tests/fixtures/display_audit/known_(wrong_transit_kind\|wrong_caption_kind\|nonstring_ruling)\.json\|design_docs/planned/r1/m4-7s-7o-followups(-sprint)?\.md\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json)$'` | `0` (no `Makefile`, no `tests/display_audit.gd`, no production path) |
| AC9 | `shellcheck -s sh -S warning tools/rig_check.sh tools/test_rig_check.sh && dash tools/test_rig_check.sh tools/rig_check.sh \| tail -1` | `rig-check control: 4 cases, 0 failures` (warning-clean; portable to dash, which is Linux's `sh`) |
| AC10 | `make python-guard AILANG="$AILANG" > /dev/null 2>&1; echo rc=$?` | `rc=0` |
| AC11 | `tools/rig_check.sh <PR>` (controller) | `rig/full` success on the PR head. The fixed script posts its own pending and success statuses. |

## Test plan with mutation drills

**Order.** Test-first:

1. RED: `drill7s "$PWD" E1 28` and `drill7s "$PWD" E7b 28` on the pre-change tree each exit 1, because the mutant survives (V16). AC2 is 7o's RED.
2. GREEN: land the fixtures, loop edits, script fix and control. Then run AC1–AC9.

**Drill shape.** Both functions use the hardened shape:

- an explicit `ROOT`;
- a cleanup trap right after `mktemp`;
- a `cmp` proof that the mutation applied (else exit 3);
- make's rc passed through;
- counts asserted with `test`, never printed.

They also make two corrections to the shape 7q used:

- No mid-function `!` or `&&` assertion is used. Under `set -e` those can fail without stopping the script. Every mid-function check is a bare `test` or `grep`.
- Script errors are counted in the per-row logs under `$T/scratch`, not in make's stdout, where Godot's output never appears.

The patterns go through the environment, because inline Perl interpolates `$(` and `@`. Run the drills sequentially (they share the import cache) under `sh`. They were validated as written in a rehearsal of the GREEN tree (V15).

```sh
# Row 7o drills: R1 (no cut), R2 (the old fail line), R3 (a refused failure post aborts).
drill7o() (
  set -eu
  ROOT=${1:?explicit checkout ROOT required}
  mutant=${2:?R1, R2 or R3 required}
  cd "$ROOT"; ROOT=$(pwd -P)
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7o.XXXXXX")
  trap 'if test -f "$T/orig"; then cp "$T/orig" "$ROOT/tools/rig_check.sh"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  sh tools/test_rig_check.sh tools/rig_check.sh > "$T/baseline.log" 2>&1
  test "$(grep -c ': ok$' "$T/baseline.log")" -eq 4
  cp tools/rig_check.sh "$T/orig"
  case "$mutant" in   # patterns via env: inline Perl interpolates $( and @ (iteration-41 lesson)
    R1) PAT='"$(printf %s "$2" | cut -c1-140)"' REP='"$2"' ;;
    R2) PAT='fail() { echo "rig-check: FAIL: $1 (log: $log)"; status failure "$short: $1" || echo "rig-check: could not post the failure status"; exit 1; }'
        REP='fail() { status failure "$1 (log on the Studio: $log)"; echo "rig-check: FAIL: $1"; exit 1; }' ;;
    R3) PAT=' || echo "rig-check: could not post the failure status"' REP='' ;;
    *) exit 2 ;;
  esac
  PAT=$PAT REP=$REP perl -0pi -e 's{\Q$ENV{PAT}\E}{$ENV{REP}}' tools/rig_check.sh
  cmp -s "$T/orig" tools/rig_check.sh && exit 3
  rc=0; sh tools/test_rig_check.sh tools/rig_check.sh > "$T/mutant.log" 2>&1 || rc=$?
  test "$rc" -ne 0
  case "$mutant" in
    R1) grep -q '^rig-check control long-reason: FAIL' "$T/mutant.log" && grep -q '^rig-check control long-success: FAIL' "$T/mutant.log" ;;
    R2) grep -q '^rig-check control make-test-red: FAIL' "$T/mutant.log" ;;
    R3) grep -q '^rig-check control failure-refused: FAIL' "$T/mutant.log" ;;
  esac
)

# Row 7s drills: E1/E2 (kind pins), E5 (type guard deleted: equivalent), E5b (type guard flipped),
# E7/E7b (a spec row deleted, new and old), S1 (a script error on the known-ruling path),
# C1-C4 (one D-78 caption dropped from the accepted list: the positive control already kills it).
drill7s() (
  set -eu
  ROOT=${1:?explicit checkout ROOT required}
  mutant=${2:?E1, E2, E5, E5b, E7, E7b, S1 or C1-C4 required}
  expected=${3:-31}
  cd "$ROOT"; ROOT=$(pwd -P)
  case "$mutant" in E7|E7b) F=mk/m45.mk ;; *) F=tests/display_audit.gd ;; esac
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7s.XXXXXX")
  trap 'if test -f "$T/orig"; then cp "$T/orig" "$ROOT/$F"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  PATH="$ROOT/runtime/bin:$PATH" make display-audit-controls \
    SCRATCH="$T/scratch" AILANG="$ROOT/runtime/bin/ailang" > "$T/baseline.log" 2>&1
  test "$(grep -c ': rejected$' "$T/baseline.log")" -eq "$expected"
  cp "$F" "$T/orig"
  case "$mutant" in
    E1) PAT='entry.kind == "transit-ISM" and ' REP='' ;;
    E2) PAT='entry.kind == "unbound" and ' REP='' ;;
    E5) PAT='	if not entry.accepted_by is String: return false
' REP='' ;;
    E5b) PAT='if not entry.accepted_by is String: return false' REP='if not entry.accepted_by is String: return true' ;;
    E7) PAT="'known known_wrong_accompanying.json known-ruling' " REP='' ;;
    E7b) PAT="'review_unbound empty_known.json NEW.unbound' " REP='' ;;
    C1) PAT='"Cruise N - beta", ' REP='' ;;
    C2) PAT=', "N - beta", ' REP=', ' ;;
    C3) PAT='"  its N - beta", ' REP='' ;;
    C4) PAT=', "Grains swept (>= N um)"]' REP=']' ;;
    S1) PAT='check(false, "known-ruling invalid acceptance"); continue'
        REP='check(false, "known-ruling invalid acceptance"); var probe: Array = []; print(probe[0]); continue' ;;
    *) exit 2 ;;
  esac
  PAT=$PAT REP=$REP perl -0pi -e 's{\Q$ENV{PAT}\E}{$ENV{REP}}' "$F"
  cmp -s "$T/orig" "$F" && exit 3
  rc=0; PATH="$ROOT/runtime/bin:$PATH" make display-audit-controls \
    SCRATCH="$T/scratch" AILANG="$ROOT/runtime/bin/ailang" > "$T/mutant.log" 2>&1 || rc=$?
  errs=$(grep -l 'SCRIPT ERROR:' "$T"/scratch/display-audit/*/*.log 2>/dev/null | wc -l | tr -d ' ')
  if [ "$mutant" = E5 ]; then   # equivalent: same rows, the non-String fixture still rejected for the ruling
    test "$rc" -eq 0
    test "$errs" -eq 0
    test "$(grep -c ': rejected$' "$T/mutant.log")" -eq "$expected"
    grep -qx 'FAIL known-ruling invalid acceptance' "$T"/scratch/display-audit/*/display-known-known_nonstring_ruling.json.log
    exit 0
  fi
  test "$rc" -ne 0
  if [ "$mutant" = S1 ]; then test "$errs" -gt 0; else test "$errs" -eq 0; fi
  case "$mutant" in
    E1) grep -qx 'display control known/known_wrong_transit_kind.json wrong reason (want known-ruling)' "$T/mutant.log" ;;
    E2) grep -qx 'display control known/known_wrong_caption_kind.json wrong reason (want known-ruling)' "$T/mutant.log" ;;
    E5b) grep -qx 'display control known/known_nonstring_ruling.json missed' "$T/mutant.log" ;;
    E7|E7b) grep -qx "display control rows: $((expected - 1)), want $expected" "$T/mutant.log" ;;
    S1) grep -qx 'display control known/known_bad_ruling.json script error' "$T/mutant.log" ;;
    C[1-4]) test "$(grep -c ': rejected$' "$T/mutant.log")" -eq 0 && grep -qx 'FAIL known-ruling invalid acceptance' "$T"/scratch/display-audit/*/display-known.log ;;
  esac
)
```

**Expected outcomes, all measured (V14–V16):**

| Drill | Mutation | Expected outcome |
|---|---|---|
| R1 | no cut | `long-reason` and `long-success` FAIL (340 and 257 refused) |
| R2 | the old `fail` line | `make-test-red` FAIL |
| R3 | no `\|\| echo` | `failure-refused` FAIL |
| R4 | echo after the post | **Equivalent** while R3's `\|\|` stands: order matters only if the post can abort `fail()`. Measured surviving; no drill. |
| E1 | D-77 kind pin deleted | `known/known_wrong_transit_kind.json wrong reason (want known-ruling)` |
| E2 | D-78 kind pin deleted | `known/known_wrong_caption_kind.json wrong reason (want known-ruling)` |
| E5 | type guard deleted | **Equivalent**: green, 31 rows, non-String fixture rejected for the ruling |
| E5b | type guard flipped | `known/known_nonstring_ruling.json missed` |
| E7 | new row deleted | `rows: 30, want 31` |
| E7b | old row deleted | `rows: 30, want 31` |
| S1 | script error on the known-ruling path | `known/known_bad_ruling.json script error` |
| C1–C4 | one D-78 caption dropped | positive control fails, 0 rows reached |

## Files

| File | Executor change |
|---|---|
| `tools/rig_check.sh` | The two edits in §1 (cap in `status()`; `fail()` reports first, posts `<short>: <reason>`). |
| `tools/test_rig_check.sh` | New; §2, verbatim. |
| `mk/m45.mk` | The four loop edits in §3; the `rig-check-control` target and `test: rig-check-control`. |
| `tests/fixtures/display_audit/known_wrong_transit_kind.json` | New; §3. |
| `tests/fixtures/display_audit/known_wrong_caption_kind.json` | New; §3. |
| `tests/fixtures/display_audit/known_nonstring_ruling.json` | New; §3. |
| `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | A dated note on milestone `M4.5bR3_7q_RULING_PIN_CONTROLS` (or a sibling `…_7s_7o_FOLLOWUPS`). It records: the commands; 31 rows; the drill verdicts (E5 and R4 equivalent); the `080b4f7` correction; 7i(l) closed; the Deferred list. Aggregate gates untouched. |
| `design_docs/planned/r1/m4-7s-7o-followups.md` | This doc. |

**Not touched:** `Makefile`, `tests/display_audit.gd`, `sim/*`, `bridge/*`, `main.gd`, `demos/*`, `ui/*`, `sim/ailang.lock`, `sim/ailang.toml`. Open-PR check (V17): #298, #300, #301, #302, #303 and #304 hold the `Makefile` and their own `mk/*.mk` files (sound, style, levels, star-surfaces, captain-anim). None of them, nor #299 or #307, lists any file in the table above. Before AC1 the executor re-runs `git log 4bf95435..origin/main -- tools/rig_check.sh mk/m45.mk tests/display_audit.gd tests/fixtures/display_audit/`, and rebases if it is non-empty.

## Deferred (recorded, not changed here)

1. **Move `rig-check-control`** into `tools-test`, next to `tools/test_sky_assets.sh`, and into `ci-fast`, once the `Makefile` is free. It is hermetic, takes about 2 s and runs under dash (V5), so it suits the clean-Linux fast tier. Adding it there needs a `Makefile` edit, which is held.
2. **`Makefile:778`** has the same dead standalone guard, `; ! grep -q "nothing written" $$d/mid.txt;`, in `catalogue-main`. The `Makefile` is held, so this is one backlog line.
3. **The four non-loop control lines** of `display-audit-controls` (`mk/m45.mk:17–21`) end in unconditional `echo '… PASS'` lines (28–31), so deleting a whole positive-control line is not counted. This is a sibling of 7i(l); it gets one backlog line.

## Risks and mitigations

- **`cut -c` counts bytes on GNU.** Bytes are never fewer than characters, so the cut never exceeds 140 characters. The only external text in a description is the `ailang --version` line, measured pure ASCII (V2). A future multibyte version string could be cut mid-character; the control would then still pass, and GitHub tolerating that tail is the residual risk.
- **Stub `make` on `PATH`.** It shadows make only for the `rig_check.sh` child. The outer `make` is already running (V7).
- **Self-count friction.** Every new spec row must bump 31 in the same diff. The failure message names both numbers.
- **S1 depends on Godot's runtime-error semantics.** The erroring function returns and the run continues (V13). If a Godot bump made this a hard abort, S1 would change signature. Re-measure on any Godot bump.
- **Fixture drift.** As with 7q: a later change to a pinned value turns a copy into a multi-field fixture. The drills are the evaluator's gate.
- **Sandbox false kills.** Socket or write failures under a sandbox are UNINFORMATIVE; re-run the drills on the rig.

## Open questions

None. 7s is D-88 A hygiene inside the approved sprint, and 7o is backlog tooling Mark ordered batched (2026-10-20); no pillar is below 0. Three things are measured, design-internal corrections, not scope or canon questions: the E5 equivalence, the 7s(c) correction, and the dead-guard fix.

## Sub-milestones and estimate

Single milestone, one PR, in this order:

1. 7o fix, control and target (AC1–AC4, AC9).
2. 7s fixtures, rows, count and guard (AC5–AC7).
3. Record (sprint JSON).
4. AC8, AC10 and the rig (AC11).

About 85 LOC. Executor work is about 2 h, including about 8 min of drills. Rig `make test` is 70–100 min.

## Verification log

Measured first-hand on 2026-10-21 in `/Users/voightkampff/dev/sunholo-data/.stapledon-loop-iter44` at `4bf95435`, with runtime v0.54.14 and Godot 4.7.2. Scratch went under `mktemp -d` in `$TMPDIR`. After every row, `git status --porcelain` (ignoring `*.uid`) was empty.

| # | Claim | Instrument | Result |
|---|---|---|---|
| V1 | Rig paths | `echo ${#TMPDIR}`; `log=${TMPDIR:-/tmp}/rig-check/$(git rev-parse HEAD).log; echo ${#log}` | TMPDIR 49 characters (ends in `/`, so `T//rig-check`); log 104 |
| V2 | Description lengths at `4bf95435` | Shell loop over each `fail` reason: `d="$r (log on the Studio: $log)"; echo ${#d}` | `clone failed` 138; `checkout of 4bf95435 failed` 153; `no AILANG_RELEASE pin in the Makefile` 163; `make runtime failed` 145; `runtime is 'ailang v0.54.11', pin is v0.54.14` 171 (unbounded: embeds `$have`); `make sky-assets failed` 148; `make test failed or ran over 5400s` **160**; `make golden failed or ran over 1800s` 162. Pending 31 / 45; success 57 / 71 with `AILANG v0.54.14`; `LC_ALL=C grep -c '[^ -~]'` on the version line gives 0 |
| V3 | `set -e` aborts `fail()` and leaves `pending` | Pre-fix `tools/rig_check.sh 7` with V4's stubs, `RIG_DIR` padded to a 104-character log, `make test` failing | rc 1; output is only the start line and the stub's `Validation failed: Description is too long (maximum is 140 characters) (HTTP 422)`; no `rig-check: FAIL:` line; posts `pending 31` accepted, `failure 160 refused`, so the status stays pending |
| V4 | Control RED on the pre-fix script | `sh test_rig_check.sh tools/rig_check.sh` | `4 cases, 4 failures`: 160, 340 and 257 refused; failure-refused has no FAIL line; rc 1 |
| V5 | Control GREEN on the fixed copy | Same script against a copy with the §1 diff; `dash …`; `shellcheck -s sh -S warning` | `4 cases, 0 failures`, rc 0, 2.0 s wall; dash rc 0; shellcheck warning-clean (info-level only: the pre-existing SC2015 at the `git fetch` line, and the intentional SC2016 on the quoted make stub) |
| V6 | 7o drills | `drill7o` on a scratch ROOT with the fix | R1, R2 and R3 killed (drill rc 0); R4 (echo moved after the post) survived, equivalent while `\|\|` stands; an unapplied pattern exits 3 (seen while tuning) |
| V7 | Make wiring | Rehearsal: target appended to `mk/m45.mk`, files restored by trap | `make -qp \| grep '^test:' … -cx rig-check-control` is `1`; `make rig-check-control` gives rc 2 on the pre-fix script (4 failures) and rc 0 on the fix |
| V8 | Controls baseline | `make display-audit-controls AILANG=$PWD/runtime/bin/ailang > .godot/tmp/iter44-baseline.log 2>&1` | rc 0, 37 s (including import), 28 `: rejected`, ending `display control known_unaccepted: OPEN (PASS)` |
| V9 | E1, E2, E5 and E5b survive today | `survive7s` (hardened: ROOT, trap, `cmp`, rc passed through), `SCRATCH=$T/scratch` | Each make rc 0 with 28 rows. C2 on the same tree: make rc 2, 0 rows |
| V10 | Fixture probes, audit level | `godot --headless --path . --script tests/display_audit.gd -- tests/fixtures/display_audit/known.ndjson control <fixture>` under `perl alarm 120`, pristine and mutated | transit_kind: pristine rc 1 known-ruling + NEW transit-ISM; under E1 rc 1 NEW + stale-known (no known-ruling). caption_kind (3 fields): pristine known-ruling; under E2 NEW unbound + stale-known. Kind-only caption fixture: `known-file invalid entry` both pristine and under E2. Base copy rc 0 under every mutant. 0 `SCRIPT ERROR` throughout |
| V11 | E5 equivalence | Same probe; `accepted_by` set to `77`, `null`, `true`, `["D-77"]` and `{"id": "D-77"}` | Pristine and under E5: identical for all five (rc 1, `known-ruling invalid acceptance` + NEW transit-ISM, 0 script errors). Under E5b: all five rc 0 with no FAIL (loads and matches). Code: `tests/display_audit.gd:57–64`, where `match` on a non-String falls through to `return false` |
| V12 | Captions C1–C4 | Same probe with `known_findings.json` under C1–C4 | Each rc 1 with `known-ruling invalid acceptance` + NEW unbound at that caption's label, so the positive control (`mk/m45.mk:18`) fails |
| V13 | Dead script-error guard | `/bin/sh -c 'set -e; ! grep -q "SCRIPT ERROR:" f; echo reached'` on a log containing it; a probe makefile copying line 26's shape; S1 via make on the clean tree | `reached`, rc 0; the probe make echoes `rejected`, rc 0; S1: make rc 0, 28 rows, 8 per-row logs contain `SCRIPT ERROR: Out of bounds get index '0'`. With the `if grep … exit 1` form the probe make fails (rc 2) |
| V14 | GREEN rehearsal | The §3 edits and fixtures applied in the clone, then make, then a trap restore | Baseline rc 0, 31. E1 rc 2 `known/known_wrong_transit_kind.json wrong reason (want known-ruling)` (28 before it). E2 rc 2 `…caption_kind… wrong reason` (29 before). E5 rc 0, 31. E5b rc 2 `known/known_nonstring_ruling.json missed` (30 before). E7 rc 2 `display control rows: 30, want 31`. S1 rc 2 `known/known_bad_ruling.json script error` (20 before) |
| V15 | Final drill functions | The Test-plan block, in a restored GREEN rehearsal | drill7o R1–R3 and drill7s E1, E2, E5, E5b, E7, E7b, S1, C1–C4 all drill rc 0; each drill7s takes 25–52 s |
| V16 | Drills are not vacuous | `drill7s "$PWD" E1 28` and `drill7s "$PWD" E7b 28` on the clean tree | Both rc 1 (the mutant survives, so the drill fails) |
| V17 | Open-PR surface | `gh pr diff <n> --repo sunholo-data/stapledons-godot --name-only` for 298–304 and 307 | No PR lists `tools/rig_check.sh`, `tools/test_rig_check.sh`, `mk/m45.mk`, `tests/display_audit.gd` or `tests/fixtures/display_audit/*`. #298, #300–#304 hold `Makefile`; #298 `mk/sound.mk`, #300 `mk/style.mk`, #301 `mk/levels.mk`, #302 `mk/star-surfaces.mk`, #304 `mk/captain-anim.mk` |
| V18 | Standalone `!` guards | `grep -nE '^[[:space:]]*! grep' mk/*.mk Makefile`; `git grep -nE '(;\|then\|do) *! grep' -- mk Makefile` | `mk/m45.mk:26` (fixed here) and `Makefile:778` (held, Deferred 2). `mk/m5.mk:68` sits at the end of an `if` body's AND list, so it is live |
| V19 | `short` is defined before `fail()` can run (quorum r1, kimi-k3; controller measured first) | `grep -n '^short=\|^fail()\|fail "' tools/rig_check.sh \| head -3` | `29:short=$(printf %s "$sha" \| cut -c1-8)`, then `42:fail() { …`, then `45:git clone … \|\| fail "clone failed"` (the first call). It is set unconditionally after `sha` resolves and is checked non-empty (:24–28), so `set -u` cannot abort `fail()` on it |
| V20 | Revision r1 re-measure | The control extracted verbatim from §2 after the `if grep` edit; a copy of `tools/rig_check.sh` with exactly the §1 edits (`diff \| grep -c '^>'` gives `2`); two extra mutants of that copy: post `"$1"` without the sha, and `$shortx` for `$short` | Pre-fix script: `4 cases, 4 failures`. Fixed copy: `4 cases, 0 failures`, rc 0 (also under dash); `shellcheck -s sh -S warning` clean. No-sha mutant: make-test-red and long-reason FAIL (`no failure description /01234567: …/`). Unset-`short` mutant: `set -u` aborts `fail()` after its echo, leaving `posts: pending 31`, so make-test-red, long-reason and failure-refused FAIL (3 failures). The control catches exactly the stuck-pending symptom kimi-k3 described |

## Quorum log

- **Round 1** (2026-10-21, artifact `m4-7s-7o-followups-2026-10-21T12-17-08Z.json`): **BLOCKED.**
  - oc-kimi-k3: REJECT. Blocking: the doc never showed that `short`, used by the new `fail()`, is defined. Under `set -u` an unset `short` would recreate the stuck pending.
  - gemini-4-argon: PASS. Non-blocking: the control's `! grep -q refused … || why=…` carries the `!` footgun the doc removes elsewhere.
  - gpt6-1-sol and oc-glm-5-3: absent (unreachable).
  - Controller: pass. It measured `short` at `tools/rig_check.sh:29`, before `fail()`, so the premise is false, though the completeness gap was real.
- **Revision pass 1** (designer):
  - §1 now names `short` as the existing 8-character variable and cites its line order (V19). The LOC claim stands: the diff is 2 changed lines plus 1 comment (V20).
  - The `make-test-red` row now states that the control's description regex is anchored, so the failure description must begin with the 8-character sha. It already did; V20 shows the no-sha and unset-`short` mutants are both caught.
  - The control's refused check became an `if grep …; then …; fi`, and the doc now states that no planned script uses a `!` assertion.
  - The control was re-measured after the edit (V20).
  - The design direction is unchanged.
