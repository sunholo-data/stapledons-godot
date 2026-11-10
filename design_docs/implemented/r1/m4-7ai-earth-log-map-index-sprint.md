# Sprint plan: R1-7AI-EARTH-LOG-MAP-INDEX — earth_log_voyage plans alpha Cen A at its real map index (row 7ai)

**Design doc:** [m4-7ai-earth-log-map-index.md](m4-7ai-earth-log-map-index.md) (revision 2; quorum round 1 BLOCKED
→ r1's V13 and provenance softening; round 2 BLOCKED 1/3 → r2 by the controller under the narrow-refinement
carve-out: **an x86_64 disagreement BLOCKS landing**, the reviewer's fix verbatim in Risks; no round 3, straight to
planning). **Sprint JSON:** `.ailang/state/sprints/sprint_R1-7AI-EARTH-LOG-MAP-INDEX.json`.
**Approval basis:** pillar table net 0, none below 0 (neutral suite hygiene; unattended loop proceeds).
**Branch:** `mission/stapledon-iter85-7ai` (HEAD `34d96434`, the r2 design commit; merge-base with `origin/main` is
`e0ba4ae7` = the design's `B`; `git diff --name-only e0ba4ae7..HEAD` = the design doc alone, so every V-number
applies verbatim). **Scope:** ~16 LOC, none of it product code: 1 byte in
`tests/replays/earth_log_voyage.ndjson`, 2 re-recorded `.sha256` lines, +7 lines in `tools/test_replay.py`
(allowlisted harness), +4 Makefile lines. **No GPU, no `make golden`, no capture, no full local `make test`**
(merge rule, CLAUDE.md); the nightly `rig/full` runs the suite on main post-merge.

Preamble once per session (every command headless from the clone root; `perl -e 'alarm N; exec @ARGV'` bounds every
long command):

```sh
export AILANG=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang   # pinned v0.56.1, read-only use
$AILANG --version                        # expect "AILANG v0.56.1"; anything else → stop
B=e0ba4ae7                               # design base = merge-base with origin/main
S=$PWD/.godot/tmp/7ai; mkdir -p "$S"     # scratch; .godot/ is gitignored; AC7 writes here instead of /tmp while the
                                         # sandbox blocks /tmp writes (7ah-measured)
```

**AILANG discipline (planner-measured):** this clone has **no `runtime/`**; `Makefile:2` is `AILANG ?= ailang`, and
the `ailang` on PATH is **v0.59.0-92-g24802d854-dirty** — wrong for every replay. Pass `AILANG=$AILANG` on every
`make replay*` command (or run `make runtime` first, Makefile:720, then `AILANG=runtime/bin/ailang`). The
`replay-map-index` target needs no AILANG (pure Python, no subprocess; design M3).

## Plan-time checks (planner, 2026-11-10, HEAD `34d96434`)

Cheap re-verification of the doc's claims against the tree (all read-only, bounded):

- **Base/HEAD.** HEAD = r2 design commit; merge-base = `e0ba4ae7` = `B`; only the design doc differs. Every V-number
  applies at HEAD without checkout.
- **Red premise (AC1).** `tests/replays/earth_log_voyage.ndjson:3` carries `"index":1,"id":"CNS5:3627"`,
  `pos {3.094521, -3.015404, -0.051608}` == stars.json entry 2's pos to all six decimals (V13 re-measured;
  `index.get('CNS5:3627')` = **2** at HEAD).
- **Current goldens.** Both `.state.{arm64,x86_64}.sha256` = `e62a9272814e30577001f94dc989130a890236950a744fb501f008bc908cc558
  earth_log_voyage.state.ndjson`, byte-identical (doc's `e62a9272…` ✔). Line format `<sha>  <name>.state.ndjson\n`
  matches `record()` at `tools/replay.py:410` (`"%s  %s.state.ndjson\n"`, no arch) as V9 cited.
- **Makefile anchors.** `replay` :428–429; **`replay-record` recipe :431–433 exactly as cited** ("the replay block");
  `ci-fast:` :55; 7ah's edge at **:115** (`ci-fast: similar-main-guard similar-guard-controls`, the M3 pattern);
  `test:` :57 (plus edges :26, :159 — untouched); `tools-test` :249–252 runs `python3 tools/test_replay.py` first.
  **`replay-map-index` absent at base** (`make -n replay-map-index` → `No rule to make target`, insertion clean);
  `make -n ci-fast | grep -c test_replay.py` = **0** (V7 re-measured on this tree).
- **MapIndex anchors.** `plan_index_mismatches` `tools/test_replay.py:300` (mismatch format `"%s:%d plan %s index %s,
  stars.json %s"` — produces exactly the AC1/AC8 expected line); `class MapIndex` :327; `test_an_unknown_id_fails`
  :347 (the m2.py 7-line block inserts immediately after, before `class AiSession` :355).
- **M2 base-count premise (V10).** `"index":2,"id":"CNS5:3627"` in `logs()`-visible input logs: godot_map_voyage 1,
  m4_adversarial 2, m4_min_path 1, m4_transit_harness 1 = **5** (the `.state.*.ndjson` hits are excluded by `logs()`);
  `"index":1,"id":"CNS5:3627"` in earth_log_voyage only = **1**. So at the AC2 red state `n = 5`, mutated+real
  mismatches = 6 → the assertion is exactly `6 != 5`; after the fixture fix `n = 6` and the mutation yields exactly
  6. Matches the doc.
- **No-golden-leak.** `grep -c earth_log tests/replays/compat-2.0/inputs.sha256` = 0 (V9); `tools/test_replay.py` is
  already allowlisted `harness` in `tools/python-allowlist.txt` (M2 needs no new row).
- **AC4 offset planner-measured.** The line-3 digit sits at 1-indexed byte **200** of the file, so AC4's expected
  `cmp -l` output is exactly one line: `200  61  62`.
- **Environment.** `.godot/` is `.gitignore:1` and `$S` is writable; `perl -e 'alarm N; exec @ARGV'` works; python3
  3.14.5; `make` GNU 3.81 present.

**Discrepancies (record, don't fix mid-sprint):**

- **D1.** The design's Deliverables name the sprint JSON `.ailang/state/sprints/sprint_7ai.json`; the convention
  (7ah) and this plan use `sprint_R1-7AI-EARTH-LOG-MAP-INDEX.json`. Use the latter.
- **D2.** V12's open-PR Makefile-hunk proximity check is **not re-verifiable from this sandbox** (`gh` blocked: TLS
  interception on api.github.com). The design measured it same-day and merge-base == `B` (nothing merged since), so
  it stands; the executor re-checks post-push via `gh pr checks` (AC9).
- **D3.** AC7's doc commands write `/tmp/7ai_?.out`; the 7ah sandbox blocked /tmp, so the executor writes `$S` and
  deletes there. If the executor's sandbox allows /tmp, either root is fine — assert the same three offsets.
- **D4.** AC8's doc text says "then no `git status` output", but the sprint's own edits are still uncommitted at
  that point, so porcelain lists them. Read it as "no porcelain lines beyond the sprint's own files" (7ah AC7's
  precedent) — the check that matters is the fixture restored to its post-MS2 bytes.

## Byte-for-byte rule (binding)

Never retype design-doc text into the tree. Extract the two fences, apply from the extractions, prove with `cmp`:

```sh
D=design_docs/planned/r1/m4-7ai-earth-log-map-index.md
awk '/^### M2\./,/^### M3\./' $D | awk '/^```python$/{f=1;next} /^```$/{if(f){exit}} f' > $S/m2.py
awk '/^### M3\./,/^## Files touched/' $D | awk '/^```make$/{f=1;next} /^```$/{if(f){exit}} f' > $S/m3.mk
wc -l $S/m2.py $S/m3.mk   # expect 7 and 4; m3.mk:3 begins with a literal tab
```

m2.py = the 7-line `def test_the_7ai_index_fails(self)` block (4-space indent preserved). m3.mk = the 4-line
`.PHONY:` / `replay-map-index:` / tab-recipe / `ci-fast: replay-map-index` block. The cmp proofs close at MS1.

## Test-first order (mandatory)

The design's sub-milestones in their fixed order: **T1 → M1 → V** = MS1 → MS2 → MS3. AC1's red baseline is recorded
**before any edit**. MS1 lands the control and the make target and is **seen RED at AC2 with the fixture still
wrong**; never present a control as green that never went red. MS2 then fixes the fixture byte and re-records the
goldens; MS3 verifies. Record actuals wherever a command says "record".

## Milestones

### MS1 — T1: the 7ai control + `replay-map-index` in `ci-fast`, seen RED (`tools/test_replay.py` +7, `Makefile` +4)

Files: `tools/test_replay.py` (insert `$S/m2.py` after `test_an_unknown_id_fails`, i.e. before the blank lines ahead
of `class AiSession`), `Makefile` (insert one blank line + `$S/m3.mk` after the `replay-record` recipe, i.e. after
:433). Closes: AC1 (baseline record), AC2 (red), the byte-for-byte cmp proofs.

1. **AC1 baseline (record, before edits):** `perl -e 'alarm 60; exec @ARGV' python3 tools/test_replay.py MapIndex;
   echo rc=$?` → `Ran 3 tests`, `FAILED (failures=3)`, the line `earth_log_voyage.ndjson:3 plan CNS5:3627 index 1,
   stars.json 2`, `rc=1`. (Equal to running at `$B`: HEAD adds only the design doc.)
2. **Fence extraction** (above) → `7` and `4`.
3. **Apply from the extractions; cmp proofs:** `awk '/def test_the_7ai_index_fails/,/assertIn/' tools/test_replay.py
   | cmp - $S/m2.py && echo m2-ok; n=$(grep -n '^\.PHONY: replay-map-index' Makefile | cut -d: -f1); sed -n
   "${n},$((n+3))p" Makefile | cmp - $S/m3.mk && echo m3-ok` → `m2-ok`, `m3-ok` (assert `n` is one line after a
   blank and that the block sits between `replay-record`'s recipe and `parity:`; `Makefile:55`/`:57` never edited).
4. **AC2 (record actuals):** `perl -e 'alarm 60; exec @ARGV' make replay-map-index > $S/ms1-red.log 2>&1; echo
   rc=$?; cat $S/ms1-red.log` → make rc 2; `Ran 4 tests`; `FAILED (failures=4)`; the 7ai control's assertion `6 !=
   5` (first number may print as `6 != 5` in either order — record the actual); the mismatch line
   `earth_log_voyage.ndjson:3 plan CNS5:3627 index 1, stars.json 2` (from `test_committed_logs_match_the_map`); the
   two inherited controls fail `2 != 1` (fixture still wrong).
5. **Cleanliness:** `git status --porcelain` shows only `Makefile`, `tools/test_replay.py` modified (plus the
   controller's plan/JSON files).

### MS2 — M1: the fixture byte, `replay-record` on arm64, copy to x86_64 (AC3–AC7 green)

Files: `tests/replays/earth_log_voyage.ndjson` (1 byte), `tests/replays/earth_log_voyage.state.arm64.sha256`,
`…state.x86_64.sha256`. Depends on MS1.

1. **The byte:** `perl -pi -e 's/"index":1,"id":"CNS5:3627"/"index":2,"id":"CNS5:3627"/'
   tests/replays/earth_log_voyage.ndjson` (the literal occurs exactly once in the file; planner-measured).
   **AC4 proof:** `git show $B:tests/replays/earth_log_voyage.ndjson | cmp -l -
   tests/replays/earth_log_voyage.ndjson` → exactly one line: `200  61  62`.
2. **Re-record arm64 (bound 15 min; design: ~2 min on the busy Studio):** `time perl -e 'alarm 900; exec @ARGV'
   make replay-record LOG=earth_log_voyage AILANG=$AILANG` → then `cat
   tests/replays/earth_log_voyage.state.arm64.sha256` → **`07dcdfc610228499082996f3753acffa5b385734101a66fff515fa26bce0a454
   earth_log_voyage.state.ndjson`** (two spaces, no arch — V6's measured digest). Never hand-write or adjust a
   digest: a different value is a pause point.
3. **Copy to x86_64 (as `0f5a1175` did):** `cp tests/replays/earth_log_voyage.state.arm64.sha256
   tests/replays/earth_log_voyage.state.x86_64.sha256`. **AC5:** `cat
   tests/replays/earth_log_voyage.state.arm64.sha256; cmp tests/replays/earth_log_voyage.state.arm64.sha256
   tests/replays/earth_log_voyage.state.x86_64.sha256; echo rc=$?` → the `07dcdfc6…` line, `rc=0`.
4. **AC3:** `perl -e 'alarm 60; exec @ARGV' make replay-map-index; echo rc=$?` → `Ran 4 tests`, `OK`, `rc=0`; then
   `perl -e 'alarm 180; exec @ARGV' make tools-test; echo rc=$?` → `Ran 33 tests`, `OK`, then the sky and lens sh
   scripts pass, `rc=0` (~9 s, V11).
5. **AC6 (bound 10 min):** `perl -e 'alarm 600; exec @ARGV' make replay
   SESSION=tests/replays/earth_log_voyage.ndjson AILANG=$AILANG; echo rc=$?` → `ok    earth_log_voyage  45 lines
   1389901 bytes … sha256 07dcdfc610228499 …`, `replay: 1 cases, all identical`, `rc=0`.
6. **AC7 (bound 5 min each; scratch instead of /tmp):** `git show $B:tests/replays/earth_log_voyage.ndjson >
   $S/7ai_base.ndjson; ( perl -e 'alarm 300; exec @ARGV' "$AILANG" run --quiet --bytecode --package-dir sim --caps IO
   --entry main sim/ship.ail ) < $S/7ai_base.ndjson > $S/7ai_b.out; ( perl -e 'alarm 300; exec @ARGV' "$AILANG" run
   --quiet --bytecode --package-dir sim --caps IO --entry main sim/ship.ail ) < tests/replays/earth_log_voyage.ndjson
   > $S/7ai_f.out; cmp -l $S/7ai_b.out $S/7ai_f.out; rm $S/7ai_base.ndjson $S/7ai_b.out $S/7ai_f.out` → exactly
   `56554  61  62`, `60660  61  62`, `1059580  61  62` (the three `journey.plan.target.index` echoes at ticks 1, 2,
   33; V6).

### MS3 — V: AC8–AC11, wiring + hygiene, push, fast tier (no new code)

Depends on MS2.

1. **AC8 re-introduction drill (record):** `sed -i.bak 's/"index":2,"id":"CNS5:3627"/"index":1,"id":"CNS5:3627"/'
   tests/replays/earth_log_voyage.ndjson; perl -e 'alarm 60; exec @ARGV' make replay-map-index; echo rc=$?; mv
   tests/replays/earth_log_voyage.ndjson.bak tests/replays/earth_log_voyage.ndjson; git status --porcelain` → the
   mismatch line `earth_log_voyage.ndjson:3 plan CNS5:3627 index 1, stars.json 2`, `FAILED (failures=…)` (four
   tests red), make rc 2; after `mv` the file is restored and porcelain shows only the sprint's own files. (Post-MS2
   earth_log_voyage carries exactly one index-2 literal, so the sed hits only line 3.)
2. **AC9 wiring:** `make -n ci-fast 2>/dev/null | grep -c 'test_replay.py MapIndex'` → `1`; `grep -nx 'ci-fast:
   replay-map-index' Makefile` → one line. **Post-push tail:** the PR's GitHub `make ci-fast` check green (`gh pr
   checks <PR>`, bounded `perl -e 'alarm 60; …'`) — the ubuntu-latest x86_64 runner's `replay` step confirms the
   copied golden on x86_64.
3. **AC10 cheap:** `time perl -e 'alarm 60; exec @ARGV' make replay-map-index` → real under 2 s (0.28 s measured,
   V11).
4. **AC11 hygiene/scope:** `perl -e 'alarm 300; exec @ARGV' make python-guard uid-guard; echo rc=$?; git diff --check
   $B; git diff --name-only $B` → `python-guard: ok`, `uid-guard: ok`, diff-check silent, and exactly `Makefile`,
   `tests/replays/earth_log_voyage.ndjson`, the two `.state.*.sha256`, `tools/test_replay.py` (plus landing files
   under `changelogs/`, `design_docs/`, `.ailang/state/` and this sprint's plan/JSON).

## Pause points (stop and report; do not improvise)

- Preamble: `$AILANG --version` ≠ v0.56.1 → stop; the evidence chain pins it. Never let `AILANG ?=` fall through to
  PATH's v0.59.0-dev.
- MS1: a fence extraction ≠ 7/4 lines, or a cmp proof fails → re-extract, never retype. AC2 anything but make rc 2 +
  `Ran 4 tests` + `FAILED (failures=4)` with `6 != 5` → tree drift; stop. (If MS1 were green, the control is inert —
  worst case.)
- MS2: AC4 ≠ exactly `200  61  62`, or the recorded arm64 digest ≠ `07dcdfc610228499082996f3753acffa5b385734101a66fff515fa26bce0a454`
  → stop; never hand-edit a digest into agreement. AC6's ok line naming any digest but `07dcdfc6…`, or `replay:`
  counts other than `1 cases, all identical` → stop. AC7 `cmp -l` printing anything but the three named offsets →
  stop: that is effect beyond V6, scope change.
- MS2 timing: `make replay-record` hitting the 900 s bound or `make replay` the 600 s bound → pause, rerun on a
  quieter host; do not bump the bound silently across retries.
- MS3: the AC8 drill leaves a `.bak` behind or porcelain beyond the sprint files → restore (`git checkout --
  tests/replays/earth_log_voyage.ndjson`) and stop.
- Post-push: the x86_64 fast-tier `replay` disagrees with the copied golden → **BLOCKS landing**; apply the
  Risks rule verbatim (below), never regenerate an arch-specific golden to make the check pass.
- Any temptation to touch the do-not-touch list → stop; the fix needs none of it. No merge before the cross-family
  evaluation (generator ≠ judge); landing files wait on it.

## Risks (from the design; mitigations in the bytes)

- **x86_64 differs from arm64** (quorum round 2, gpt6-1-sol, verbatim; the rule that gates landing). "Not measured
  locally. Every replay golden so far has been identical on both arches (CLAUDE.md), and the change is 3 ASCII bytes
  of echo. The fast tier runs `make replay` on x86_64 and decides it (AC9). **If the x86_64 replay disagrees, block
  landing; do not regenerate an architecture-specific golden to make the check pass.** Verify AILANG v0.56.1 on the
  runner, replay both the base and corrected inputs, and compare their state streams with the arm64 outputs. Proceed
  only when both architectures produce the specified corrected digest and the base-to-corrected difference is
  exactly the three target-index bytes. Any remaining divergence requires a separately reviewed diagnosis and scope
  revision."
- **A later stars.json reorder** moves alpha Cen A again: MapIndex now fails at the PR (`ci-fast`) instead of the
  nightly; the fix is a `0f5a1175`-style re-record, intended behaviour unchanged.
- **The M2 control's count depends on how many logs plan CNS5:3627 at 2**: it counts them (`n`) and requires `n >
  0`, so adding or removing a log does not break it (planner re-measured the base counts behind `6 != 5`).
- **AC8 edits a tracked file in place**: it restores from `.bak` and checks `git status --porcelain`; if interrupted,
  `git checkout -- tests/replays/earth_log_voyage.ndjson` restores.
- **Planner-added: the wrong AILANG.** `AILANG ?= ailang` (Makefile:2) + PATH's v0.59.0-dev silently re-records the
  golden with the wrong toolchain if `AILANG=$AILANG` is dropped. The preamble pins it; the pause point enforces it.
- **Doc discrepancies (recorded above; do not 'fix' the doc mid-sprint):** D1 sprint-JSON filename; D2 V12's PR-hunk
  check not re-verifiable here (deferred to AC9's post-push `gh pr checks`); D3 AC7's /tmp → `$S` reroot.

## Do-not-touch (design, verbatim scope)

`data/starmap/*`, `sim/`, `ui/`, `bridge/`, every other replay log or golden; the GDScript and Python `ALPHA`
constants (F1, their own row); `tools/replay.py`; the `ci-fast:` (:55) and `test:` (:57, :26, :159) lines;
attended-PR hunks per V12 (#412 :32, #373 :10/:18/:225, #380 :251 — D2 caveat). No product files, no new Python
file → no allowlist row; scratch under `$S` never committed. Non-goals stay non-goals: no `"star"` row or `dtau`
edit to the fixture (changes the D-58 plan path and the golden beyond the index), no moving the rest of `tools-test`
into `ci-fast` (F2).

## Local PR gates (targeted, headless, bounded)

The GitHub fast tier is `make ci-fast` — after MS1 it carries `replay-map-index` (MapIndex on the runner's clean
Linux) and, via `replay`, the x86_64 confirmation of the copied golden. For this row:

1. MS1 red proofs on record: AC1 (`FAILURES=3`, rc 1, the exact mismatch line) and AC2 (`Ran 4 tests`,
   `FAILED (failures=4)`, `6 != 5`), tree otherwise untouched.
2. Byte-for-byte: both cmp proofs against fresh fence extractions (m2.py = 7 lines, m3.mk = 4 lines, tab recipe).
3. MS2 gates: AC4 one-byte diff; the recorded arm64 golden = `07dcdfc6…` and the x86_64 copy cmp-equal (AC5);
   `make replay-map-index` and `make tools-test` green (AC3: `Ran 4 tests` / `Ran 33 tests`); `make replay` one
   case, VM = interpreter = golden (AC6); `cmp -l` exactly the three offsets (AC7).
4. MS3 evidence: AC8 drill rc 2 then clean restore; AC9 both greps (`1`, one edge line) + post-push `gh pr checks`
   green; AC10 < 2 s; AC11 `python-guard: ok`, `uid-guard: ok`, diff-check silent, exact file set.
5. No GPU gate, no `make golden`, no capture, no full local `make test` anywhere in this sprint (merge rule,
   Mark 2026-11-03/06; 7af/7ag/7ah/7aj precedent) — the keep-going nightly runs `tools-test` on main post-merge,
   which is the whole point of the row (the nightly has been red on MapIndex since PR #379).

## Controller checks (the controller re-runs after the executor)

AC1/AC2 red logs on record (exact lines and rc) · AC4 (`cmp -l` → `200  61  62` only) · arm64 golden digest =
`07dcdfc610228499082996f3753acffa5b385734101a66fff515fa26bce0a454` and `cmp` with the x86_64 copy rc 0 (AC5) ·
AC3 (`Ran 4 tests OK`, `Ran 33 tests OK`) · AC6 (`ok … 45 lines 1389901 bytes … 07dcdfc6 …`, `1 cases, all
identical`) · AC7 (exactly `56554 61 62`, `60660 61 62`, `1059580 61 62`) · AC8 (drill rc 2 with the mismatch line,
restore clean) · AC9 (grep `1`, one edge line, post-push `gh pr checks` green → the x86_64 confirmation; a
disagreement there BLOCKS landing per the verbatim risk) · AC10 (< 2 s) · AC11 (guards rc 0, diff-check silent,
file set exact).

## Landing (controller, after the cross-family evaluation passes) and post-merge check

Changelog fragment naming R1-7AI-EARTH-LOG-MAP-INDEX, row 7ai, PR #379 attribution; `git mv` doc + plan to
`design_docs/implemented/r1/`; README index row; charter row 7ai status; sprint JSON → recorded counts and wall
times, `status: completed`, evaluation block, path moves. Post-merge (observation, not a gate): the next nightly
`rig/full` passes `tools-test` MapIndex and the `nightly-rig` issue sheds exactly it.

## Velocity / estimate

~16 LOC, none product (1 fixture byte + 2 golden lines + 7 python + 4 make). Run-dominated verification: MS1 ~0.2 h
(extractions, edits, one sub-second red run); MS2 ~0.4 h (record + replay + 2 single-VM runs, each bounded; measured
~2 min per full replay on the busy Studio, V1/V6); MS3 ~0.2 h (drill, greps, guards). **One executor session, well
under half a day** (compare 7ah ~180 LOC half a day, 7aj ~55 LOC half a day).
