# Sprint plan: R1-D149-EARTH-LINK-ALPHA — the Earth-link capture plans alpha Cen A at its real map index (D-149)

**Design doc:** [m4-d149-earth-link-alpha-index.md](m4-d149-earth-link-alpha-index.md) (revision 2, commit
`a51c1a78`; quorum round 1 BLOCKED (gpt6-1-sol REJECT) → r1: exact-block probe generator; round 2 BLOCKED
(gpt6-1-sol REJECT) → r2 by narrow-refinement carve-out: AC10 is Appendix C with every step under
`tools/deadline.sh`, no round 3). **Sprint JSON:**
`.ailang/state/sprints/sprint_R1-D149-EARTH-LINK-ALPHA.json`.
**Approval basis:** pillar table net 0, none below 0 (neutral correctness fix to a developer review
capture); Mark's attended ruling D-149 (2026-11-12) answers everything — no open questions.
**Branch:** `mission/stapledon-iter91-d149` (HEAD `a51c1a78`, the r2 design commit; merge-base with
`origin/main` is `85ca5470` = `origin/main` = the base every V-number was measured at;
`git diff --name-only 85ca5470..HEAD` = the design doc alone, so every V-number applies verbatim;
`git status --porcelain` empty).
**Scope:** 2 files, +3/−6 (V13, prototype-measured): `tools/earth_link_capture.gd` one token
(`"index": 1` → `"index": 2`, +1/−1); `tools/test_replay.py` `SOURCE_PENDING` and its two-line comment
deleted, the two pending-filter assertions replaced by `self.assertEqual(bad, [])`, one D-149 positive
control added (+2/−5). Nothing else. **No changelog fragment** — the design's Deliverables name only the
two files, and AC8's scope check fails on anything more (see Design ambiguities, A3).
**No GPU, no `make golden`, no `make capture`, no full local `make test`** (merge rule, CLAUDE.md Merges;
7ah–7am precedent; the doc's Gates table shows `capture-earth-link` is in no aggregate target). The
targeted gates are `make replay-map-index` (already in `ci-fast`, `Makefile:482`), `python3
tools/test_replay.py`, `make python-guard`, `make uid-guard`, `make lint-precision`, `git diff --check`,
the Appendix-A drills (AC4/AC5) and Appendix C (AC10). The nightly `rig/full` runs the suite on main
post-merge. AC11 (`make capture-earth-link`, GPU window) is Mark's attended check after merge — **not a
gate** (design; merges never wait on the GPU).

**Role split:** the planner ran no Godot and no make (all plan-time checks were git/grep/sed/awk/python
reads) and runs no git write beyond the plan/JSON commit. The controller commits and lands. The executor
edits the tree and runs everything below; its git writes are exactly **one** code commit (MS2) — see "One
commit" below.

## One commit (binding, from the design)

The design's D2 requires: **both edits land in one commit.** Each half alone fails `replay-map-index`
(V10 `index` mode; V12), and AC8 checks the aggregate diff. Therefore the branch gets exactly one code
commit (MS2). MS1 and MS3 produce **no** code commit: MS1's RED is transient (applied, recorded,
byte-restored in the same milestone); MS3 is evidence-only. This reconciles the mission's "one commit per
milestone" with the design's harder rule — the design is binding (Design ambiguities, A2).

## Environment (executor)

```sh
cd <executor clone>                 # ROOT=$PWD (the design's ROOT; AC10 takes it as $1)
export ROOT=$PWD
B=85ca5470                          # origin/main = merge-base = the design's measured base
S=$PWD/.godot/tmp/d149; mkdir -p "$S"   # scratch; .godot/ is .gitignore'd
D=$(mktemp -d 2>/dev/null || mktemp -d "$S/d149_D.XXXXXX")   # scratch OUTSIDE the repo holding the
                                    # extracted Appendices A/B/C (AC4 names it $D); never committed
```

Preamble once per session (every command headless, from the clone root; `perl -e 'alarm N; exec @ARGV'`
or `tools/deadline.sh` bounds every run):

```sh
runtime/bin/ailang --version   # expect "AILANG v0.56.1" (commit 05c860a); anything else -> run
                               # `perl -e 'alarm 180; exec @ARGV' make runtime` once, then re-check
godot --version                # expect 4.7.2.stable…
python3 --version              # stdlib only; tools/test_replay.py is a listed harness
                               # (tools/python-allowlist.txt:24)
```

**The `ailang` on PATH is a dev build (planner-measured: v0.60.0-46-g6d28e1ad5a-dirty) and is never used
for a gate reading.** AC10 uses the pinned runtime by construction (Appendix C sets
`AILANG_BIN="$ROOT/runtime/bin/ailang"` and puts `runtime/bin` first on PATH for `make import`).

**Sandbox note (planner-measured, as 7am D1):** this sandbox refuses `/tmp` writes (`touch
/tmp/d149_plan_probe` → `Operation not permitted`). Appendices A/C hardcode `mktemp -d
/tmp/d149_*.XXXXXX`. If the executor's sandbox allows `/tmp`, run the extracted scripts as written. If
not, reroot the two mktemp templates 1:1 under `$S` (e.g. `mktemp -d "$S/d149_drill.XXXXXX"`) — the only
change to the extracted scripts, expectations byte-identical. Check first: `touch /tmp/d149_probe && rm
/tmp/d149_probe`.

## Plan-time checks (planner, 2026-11-13, HEAD `a51c1a78`)

Cheap re-verification of the doc's claims against the tree (all read-only, bounded):

- **Base/HEAD.** HEAD = r2 design commit `a51c1a78`; merge-base with `origin/main` = `85ca5470` =
  `origin/main` = the design's "Measured at" base; only the design doc differs. `git status --porcelain`
  empty.
- **Edit anchors (planner-verified verbatim).** `tools/earth_link_capture.gd:16` =
  `const ALPHA := {"index": 1, "id": "CNS5:3627", "pos": …}` (D1 target). `tools/test_replay.py:340–342` =
  the two-line `SOURCE_PENDING` comment + `SOURCE_PENDING = ("tools/earth_link_capture.gd:16",)`;
  `:462–463` = the two pending-filter assertions; `:464` = the existing
  `assertIn("ui/transit_harness.gd:10", checked)` positive control (kept; the D-149 control goes after
  it). `git grep -n SOURCE_PENDING -- tools` = exactly `:342,:462,:463` (V4's 3 hits).
- **stars.json (planner-measured):** 5685 stars; index 1 = `HIP 71681`, index 2 = `CNS5:3627`,
  `CNS5:3627` at `[2]` only (V1 confirmed).
- **Makefile anchors (never edited).** `replay-map-index` at `:479–480`
  (`python3 tools/test_replay.py MapIndex`); `ci-fast: replay-map-index` at `:482`; `tools-test` at
  `:293` (runs the whole harness); `test:` includes `tools-test` (`:60`). `capture-earth-link` only at
  `mk/earth-link.mk:106–107` and the baseline row `tools/script-gate-baseline.txt:24` (unaffected).
- **Fence extraction (Byte-extraction rule) planner-measured:** Appendix A = **37 lines**, sha256
  `ae32d0e1cabb93c66561…` — matches the doc's `ae32d0e1cabb93c6…`; Appendix B = **52 lines**, sha256
  `596b20d6fef7073a5f14…` — matches `596b20d6fef7073a…`; Appendix C = **35 lines**, sha256
  `a2c2693abc8144162ba9…` — matches `a2c2693abc814416…`. The doc has 10 fence markers / 4 appendix
  sections; the awk ranges below isolate exactly one fence each.
- **Clone state.** `runtime/bin/ailang` = v0.56.1 (commit 05c860a) already provisioned (`make runtime`
  is idempotent, 2–3 s warm — V17); `.godot/` already imported; `godot` 4.7.2.stable on PATH; python3
  3.14.5; `tools/deadline.sh` present (process-group runner, TERM then KILL after 5 s, rc 124).

**Discrepancies (record, don't fix mid-sprint):**

- **D1. `/tmp` blocked** in the planner sandbox — see Environment; 1:1 mktemp reroot if the executor's
  sandbox matches.

## Byte-extraction rule (binding)

Never retype appendix text. Extract the fences, verify sha256, then use:

```sh
DD=design_docs/planned/r1/m4-d149-earth-link-alpha-index.md
awk '/^## Appendix A/,/^## Appendix B/' $DD | awk '/^```bash$/{f=1;next} /^```$/{if(f){exit}} f' > "$D/d149_drill.sh"
awk '/^## Appendix B/,/^## Appendix C/' $DD | awk '/^```perl$/{f=1;next} /^```$/{if(f){exit}} f' > "$D/elc_probe_gen.pl"
awk '/^## Appendix C/,/^## Appendix D/' $DD | awk '/^```bash$/{f=1;next} /^```$/{if(f){exit}} f' > "$D/d149_ac10.sh"
wc -l "$D/d149_drill.sh" "$D/elc_probe_gen.pl" "$D/d149_ac10.sh"   # expect 37, 52, 35 (planner-measured)
shasum -a 256 "$D/d149_drill.sh" "$D/elc_probe_gen.pl" "$D/d149_ac10.sh"
# expect ae32d0e1cabb93c6…, 596b20d6fef7073a…, a2c2693abc814416… (the doc's pinned prefixes)
```

A mismatch means re-extract, never retype. `$D` is outside the repo (AC4); the scripts are never
committed.

## Test-first order (mandatory)

**MS1** records the pristine baselines and the two half-applied REDs **transiently** (each restored
byte-identical in the same step; the tree ends clean, no commit — One commit). **MS2** lands both edits
in **one** commit and turns AC1–AC3, AC6–AC9 GREEN. **MS3** is the evidence milestone: the killing
drills AC4/AC5 on the committed tree, AC10 (Appendix C, every step deadline-bounded), the final gate
re-run. Never present a control as green that never went red:

| New/changed line | Killing control (proves it can fail) | Exact red evidence |
|---|---|---|
| `tools/earth_link_capture.gd:16` `"index": 2` (D1) | **AC4** (`index` drill: ALPHA back at 1 on the committed tree); MS1 half-B (V12) | AC4: `d149-drill: index make_rc=2`, `fail_lines=1 want_hits=3 summary=1`, `KILLED`, rc 0. V12: rc 1, `AssertionError: Lists differ: ['tools/earth_link_capture.gd:16'] != []` |
| `self.assertEqual(bad, [])` (D2) | MS1 half-A (guard change alone on the pristine `.gd`); **AC4** | half-A: make rc 2, `AssertionError: Lists differ: ['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2'] != []` (by construction from V2's message format; **sprint-measured** — record the actual line) |
| `assertIn("tools/earth_link_capture.gd:16", checked)` (D2's new positive control) | **AC5** (`blind` drill: the `"id"` key renamed → the scan no longer sees the pair) | `d149-drill: blind make_rc=2`, `fail_lines=1 want_hits=1 summary=1` (`'tools/earth_link_capture.gd:16' not found in`), `KILLED`, rc 0 |
| the drills themselves | **V11** on the pristine tree (MS1 step 3) | `d149-drill: mutation index did not apply` rc 3; `mutation blind did not apply` rc 3; tree clean |
| AC10's frame check | AC10's pristine reading (V17: `a_outbound_4.32ly=0` → rc 1) — not re-run in the sprint; the drills above are the sprint's reds | `subtitle=[CNS5:3627]`, rc 1 (design-recorded) |

Green expectation after MS2 (AC3): `Ran 9 tests`, `OK`, rc 0.

## Milestones

### MS1 — RED: pristine baselines, drill fail-closed (V11), the two half-applied REDs (transient, no commit)

Files: none committed. Transient edits to `tools/test_replay.py` and `tools/earth_link_capture.gd`,
byte-restored in the same step. Scratch: `$D/d149_drill.sh` (extracted). Closes: nothing green — this
milestone's deliverable is the RED record (test-first table above).

1. **Preamble + anchor assert (cheap; stop on any mismatch):** the Environment block; then
   `sed -n '16p' tools/earth_link_capture.gd`, `sed -n '340,342p;462,464p' tools/test_replay.py` → the
   planner-verified lines above; `git grep -c SOURCE_PENDING -- tools` → `3`.
2. **Pristine baselines (V3, AC3/AC6/AC7 baseline column):**
   `perl -e 'alarm 120; exec @ARGV' make replay-map-index` → rc 0, `Ran 9 tests`, `OK` (**passes only
   through the pending entry** — the whole point of D-149);
   `perl -e 'alarm 300; exec @ARGV' python3 tools/test_replay.py` → `Ran 38 tests`, `OK`, rc 0;
   `perl -e 'alarm 30; exec @ARGV' git diff --check $B HEAD` → no output, rc 0.
3. **Extract Appendix A** (Byte-extraction rule; 37 lines, sha `ae32d0e1…`). **V11 fail-closed on the
   pristine tree:** `perl -e 'alarm 240; exec @ARGV' bash "$D/d149_drill.sh" index "$ROOT"` →
   `d149-drill: mutation index did not apply`, rc 3; `perl -e 'alarm 240; exec @ARGV' bash
   "$D/d149_drill.sh" blind "$ROOT"` → `d149-drill: mutation blind did not apply`, rc 3; `git status
   --porcelain` empty after each (the drill restores).
4. **Half-A RED (the guard change alone, transient):** `cp tools/test_replay.py $S/test_replay.orig`;
   apply the D2 edit only (delete `:340–342`; replace `:462–463` with `        self.assertEqual(bad, [])`;
   add the D-149 `assertIn` after the `ui/transit_harness.gd:10` line); `perl -e 'alarm 120; exec @ARGV'
   make replay-map-index` → **make rc 2**, `FAIL: test_source_literals_match_the_map`,
   `AssertionError: Lists differ: ['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2'] !=
   []` (**sprint-measured**: this exact message has no V-number; record the actual), `FAILED
   (failures=1)`. Then `cp $S/test_replay.orig tools/test_replay.py && cmp $S/test_replay.orig
   tools/test_replay.py && echo restored` → `restored`.
5. **Half-B RED (V12 verbatim, the `.gd` token alone, transient):** `cp tools/earth_link_capture.gd
   $S/elc.orig`; `perl -pi -e 's/^const ALPHA := \{"index": 1, "id": "CNS5:3627"/const ALPHA :=
   {"index": 2, "id": "CNS5:3627"/' tools/earth_link_capture.gd`; `perl -e 'alarm 120; exec @ARGV'
   python3 tools/test_replay.py MapIndex` → **rc 1**, `FAIL: test_source_literals_match_the_map`,
   `AssertionError: Lists differ: ['tools/earth_link_capture.gd:16'] != []` (V12), `FAILED
   (failures=1)`. Then `cp $S/elc.orig tools/earth_link_capture.gd && cmp $S/elc.orig
   tools/earth_link_capture.gd && echo restored` → `restored`.
6. **Cleanliness:** `git status --porcelain` empty (only the controller's plan/JSON may appear); no
   `.orig` in the tree. **No commit** (One commit). Record in the sprint JSON `measured` for MS1: the
   three baseline lines, both rc-3 drill lines, both half-RED assertion lines verbatim, both `restored`.

### MS2 — GREEN: D1 + D2 in ONE commit; AC1, AC2, AC3, AC6, AC7, AC8, AC9

Files: `tools/earth_link_capture.gd` (+1/−1), `tools/test_replay.py` (+2/−5). **Nothing else.** Depends
on MS1's RED record. Closes: **AC1, AC2, AC3, AC6, AC7, AC8, AC9**.

1. **D1 (the token):** at `tools/earth_link_capture.gd:16`, `"index": 1` → `"index": 2`. The `.uid` file
   does not change (design).
2. **D2 (the guard):** in `tools/test_replay.py`: delete `:340–342` (the two-line comment and
   `SOURCE_PENDING = ("tools/earth_link_capture.gd:16",)`); replace the two assertions at `:462–463` with
   `        self.assertEqual(bad, [])`; after the existing
   `        self.assertIn("ui/transit_harness.gd:10", checked)  # known positive: the scan sees a real pair`
   add exactly the design's line:
   `        self.assertIn("tools/earth_link_capture.gd:16", checked)  # D-149: the pair held pending until Mark ruled is seen, and now matches`
   The synthetic controls (`test_the_7am_literals_fail`, `_escaped_ids_fail`,
   `_intervening_fields_fail`) are untouched.
3. **Diff shape (V13):** `git diff --shortstat $B -- tools/` → ` 2 files changed, 3 insertions(+),
   6 deletions(-)`; `git diff $B -- tools/earth_link_capture.gd` = the single `"index": 1`→`2` hunk;
   `git diff $B -- tools/test_replay.py` = exactly the D2 hunks (no stray whitespace).
4. **AC1 (the one token):** `test "$(grep -c '^const ALPHA := {"index": 2, "id": "CNS5:3627", '
   tools/earth_link_capture.gd)" -eq 1 || exit 1` → rc 0.
5. **AC2 (the mechanism is gone):** `test "$(git grep -n SOURCE_PENDING -- tools | wc -l)" -eq 0 ||
   exit 1` → rc 0 (baseline: 3 hits → rc 1).
6. **AC3 (the guard passes, GREEN — the milestone's required end state):** `perl -e 'alarm 120; exec
   @ARGV' make replay-map-index` → rc 0, `Ran 9 tests`, `OK` (the count stays 9: no test method is
   added or removed — assertions only).
7. **AC6 (the whole harness):** `perl -e 'alarm 300; exec @ARGV' python3 tools/test_replay.py` →
   `Ran 38 tests`, `OK`, rc 0.
8. **THE COMMIT (both edits, one commit):** `git add tools/earth_link_capture.gd
   tools/test_replay.py` and commit with a message naming D-149 and both halves, ending with the
   executor's `Co-Authored-By:` trailer. The executor never sets `passes` (the controller does).
9. **AC7 (whitespace, post-commit):** `perl -e 'alarm 30; exec @ARGV' git diff --check $B HEAD` → no
   output, rc 0.
10. **AC8 (scope, post-commit):** `test "$(git diff --name-only $B HEAD -- . ':!design_docs' ':!.ailang'
    | tr '\n' ' ')" = "tools/earth_link_capture.gd tools/test_replay.py " || exit 1` → rc 0.
11. **AC9 (policy gates):** `for t in python-guard uid-guard lint-precision; do perl -e 'alarm 120;
    exec @ARGV' make $t || exit 1; done` → each `…: ok`, rc 0 (V9: `python-guard: ok (23 allowlisted, 0
    awaiting AILANG port)`, `uid-guard: ok (438 .uid files)` — counts may drift with main; record the
    actuals).
12. **Record** the AC1/AC2/AC3/AC6 outputs and the shortstat in the sprint JSON `measured` for MS2.

### MS3 — Evidence: the killing drills (AC4, AC5), AC10 via Appendix C, final gate re-run (no commit)

Files: none committed (executor appends `measured` evidence to the sprint JSON working tree; the
controller sets `passes` and commits). Scratch: `$D` (extracted Appendices A–C). Depends on MS2's
commit. Closes: **AC4, AC5, AC10** (executor); **AC11** is Mark's, attended, after merge — not a gate.

1. **Extract Appendices B and C** (Byte-extraction rule; 52 and 35 lines, shas `596b20d6…`,
   `a2c2693a…`). Appendix A is already extracted from MS1 — re-verify its sha.
2. **AC4 (`index` killing mutation, on the committed tree):** `perl -e 'alarm 240; exec @ARGV' bash
   "$D/d149_drill.sh" index "$ROOT"` → `d149-drill: index make_rc=2`; `d149-drill: index fail_lines=1
   want_hits=3 summary=1` (the want text is `tools/earth_link_capture.gd:16 CNS5:3627 index 1,
   stars.json 2` — the `FAIL:` line, the `AssertionError:` line and the drill's own grep target make 3);
   `d149-drill: index KILLED`; rc 0; `git status --porcelain` empty afterwards.
3. **AC5 (`blind` killing mutation):** `perl -e 'alarm 240; exec @ARGV' bash "$D/d149_drill.sh" blind
   "$ROOT"` → `d149-drill: blind make_rc=2`; `d149-drill: blind fail_lines=1 want_hits=1 summary=1`
   (want: `'tools/earth_link_capture.gd:16' not found in`); `d149-drill: blind KILLED`; rc 0; tree clean.
4. **AC10 (the frame change, headless, every step deadline-bounded):** `sh "$ROOT/tools/deadline.sh"
   1200 bash "$D/d149_ac10.sh" "$ROOT" "$D"` →
   `d149-ac10: make runtime rc=0`, `d149-ac10: make import rc=0`, `d149-ac10: generator rc=0`,
   `d149-ac10: probe rc=0`; the line
   `elc-probe a_outbound title=[En route to CNS5:3627] subtitle=[CNS5:3627  ·  4.32 ly] …`;
   `d149-ac10: a_outbound_4.32ly=1 summary=1 script_errors=0`; `d149-ac10: PASS`; rc 0 (V17). Step exit
   codes 10/11/12/13 name the failing step; 124 means a deadline fired — **stop, do not retry with a
   longer deadline** (Pause points). Note the subtitle's spacing is exactly `CNS5:3627  ·  4.32 ly`
   (two spaces each side of the middle dot — from the doc's AC table).
5. **V7/V8 cross-check (from AC10's expected text):** the probe's b–e `elc-` lines equal the design's
   measured lines: `b_top title=[En route to waypoint C (60 ly)] subtitle=[waypoint C (60 ly)]`,
   `c_replan title=[port B (a 30 ly turn)]`, `d_stale title=[En route to port B (a 30 ly turn)]`,
   `e_home title=[En route to Sol] subtitle=[Sol]`; `a_outbound` station line
   `labels_sha=c4b3e05190254f4f nlabels=20 view_sans_index_sha=9ffd74fe7d35b829` with
   `index_values=['"index":2.0']` (the echo moves; V8). Record the actuals; a mismatch is a pause point,
   not a fix.
6. **Final gate re-run (the landing record):** AC3, AC6, AC7, AC8, AC9 once more, verbatim commands
   from MS2; all green.
7. **Evidence (per the mission):** append the `measured` fields to
   `.ailang/state/sprints/sprint_R1-D149-EARTH-LINK-ALPHA.json` (MS1: baselines, V11 rc-3s, both
   half-RED lines; MS2: shortstat, AC1/AC2/AC3/AC6/AC9 actuals; MS3: the AC4/AC5 drill lines, AC10's
   full line set with wall-clock times, the b–e lines, the final gate re-run). **The executor never
   sets `passes`, `started` or `completed`** — the controller does. No code commit from this milestone.

## Pause points (stop and report; do not improvise)

- Preamble: `runtime/bin/ailang --version` ≠ v0.56.1 after `make runtime`, `godot --version` ≠ 4.7.2 →
  stop. Never substitute the PATH `ailang` (v0.60.0-dev) for a gate reading.
- MS1: a pristine baseline differs from V3 (`Ran 9 tests`, `OK` / `Ran 38 tests`, `OK`) → tree drift,
  stop. A drill extraction sha mismatches → re-extract; still mismatched → stop, never retype. V11 not
  rc 3 with the `did not apply` line → the drill or the tree drifted, stop. Either half-RED message
  differs from the expected assertion → record verbatim, stop.
- MS2: the shortstat is not `2 files changed, 3 insertions(+), 6 deletions(-)` → stop (wrong hunk
  landed). AC3 not `Ran 9 tests` → the test set drifted, stop. Any gate red → stop; never weaken the
  guard, never re-add `SOURCE_PENDING`, never split the commit.
- MS3: a drill line differs (`make_rc` not 2, a count off, no `KILLED`) → stop with the drill log. AC10
  exits 10/11/12/13 → stop with `$T`'s log for the named step. AC10 or a drill returns 124/142 → a
  deadline fired or a signal landed → stop; never re-run with a longer deadline, never bump a limit
  silently. `git status --porcelain` non-empty after any drill → the restore failed (drill exit 4) —
  stop; restore from `$T/orig` is the drill's own job, do not hand-edit.
- The `elc-probe a_outbound` subtitle is anything but `CNS5:3627  ·  4.32 ly` → stop (that is the
  ruling's exact string).

## Risks (from the design; planner additions marked)

- **Landing one edit without the other** (design): impossible under One commit; AC8 re-checks the
  aggregate; `ci-fast` runs `replay-map-index` on the PR head.
- **Removing the mechanism hides a future wrong pair** (design): it does not — `assertEqual(bad, [])` is
  stricter; the synthetic controls and AC4 prove it.
- **The positive control names a line number** (design, quorum r1 gemini note): kept as designed; a
  harmless line shift fails loudly with the shifted entry listed; AC4/AC5 unchanged.
- **Probe drift** (design, r1 sol fix): the generator fails closed (exit 255, empty output) on any
  missing/changed/duplicated/truncated block; AC10's generator step (exit 12) surfaces it before the
  probe runs.
- **(planner) `make runtime`/`make import` on a loaded host:** both already warm in this clone
  (runtime present, `.godot` imported); V17 measured 2–3 s / 6–7 s warm against deadlines of 180/300 s.
  A cold clone still fits (24 s cold import, 12× headroom). Network loss during `make runtime`'s
  `gh release download` is the only plausible stall — deadline 180 s bounds it (V18 proves the kill).
- **(planner) `/tmp` blocked:** Environment / D1 reroot; expectations unchanged.

## Files allowed and do-not-touch (design, verbatim scope)

Allowed: `tools/earth_link_capture.gd` (one token), `tools/test_replay.py` (the D2 hunks only).
Do-not-touch: everything else, including the `.uid` files, `data/starmap/stars.json`, `Makefile`,
`mk/*`, `tools/script-gate-baseline.txt` (its `capture-earth-link` row is unaffected), the synthetic
control tests, `tools/deadline.sh` (reused, not edited). No changelog fragment (A3). Transient MS1/MS3
mutations are byte-restored in the same step.

## Local PR gates (targeted, headless, bounded)

`make replay-map-index` (alarm 120) · `python3 tools/test_replay.py` (alarm 300) · `make python-guard`,
`make uid-guard`, `make lint-precision` (alarm 120 each) · `git diff --check 85ca5470 HEAD` (alarm 30) ·
the two Appendix-A drills (alarm 240 each) · Appendix C AC10 (`tools/deadline.sh` 1200 outer;
180/300/30/600 inner). **No `make test`, no `make golden`, no GPU capture, no rig run** — the nightly
covers `make test`; AC11 is attended.

## Controller checks (the controller re-runs after the executor, before landing)

- `git log --oneline $B..HEAD` shows exactly one code commit touching exactly the two files
  (`git show --stat` = V13's shape) plus the planner's plan/JSON commit.
- Re-run AC2, AC3, AC8 verbatim; confirm the sprint JSON's `measured` fields hold both half-RED lines
  and the AC10 `PASS`; set `passes` per milestone (the executor never does).
- The PR fires the ci.yml fast tier (`make ci-fast` ⊃ `replay-map-index`, `Makefile:482`) — confirm it
  green with `Ran 9 tests` / `OK` before leaving draft (the 7am/7al API-log pipeline).
- After the cross-family evaluation passes and the merge: move the design doc to
  `design_docs/implemented/r1/` and update the charter rows (design Deliverables — controller, not the
  executor). AC11 is Mark's attended `make capture-earth-link` in a GPU window when the GPU is free
  (expected: `earth-link-capture: 10 frames, 0 failures`; the `a_outbound` map subtitle reads
  `CNS5:3627  ·  4.32 ly`).

## Design ambiguities (listed, not resolved by guessing)

- **A1. The mission's MS1 parenthetical vs V12.** The mission brief says "apply the guard change alone
  and record the expected failure named in the doc's V12", but V12 is the *other* half (fixed `.gd` +
  old guard → `['tools/earth_link_capture.gd:16'] != []`). The guard-alone half has no V-numbered exact
  message. **Plan:** MS1 records *both* halves transiently (steps 4–5); half-A's expected message is
  derived from V2's format and marked sprint-measured.
- **A2. "One commit per milestone" vs "Both edits must land in one commit."** A strict per-milestone
  code commit would either commit a half (forbidden — each half alone fails `replay-map-index`) or
  require amending. **Plan:** the design's rule is binding — one code commit (MS2); MS1/MS3 commit
  nothing (evidence goes to the sprint JSON via the controller). If the mission loop requires a commit
  per milestone, that is a controller call, not executor improvisation.
- **A3. Changelog fragment.** The design's Deliverables name only the two files, and AC8's scope check
  (`git diff --name-only` must equal exactly the two paths outside `design_docs`/`.ailang`) fails on any
  additional tracked file — so the plan ships **no** fragment. Read as resolved by AC8; listed because
  recent sprints (7am, 7ae) shipped one.
- **A4. `/tmp` in the appendices.** Appendices A/C hardcode `mktemp -d /tmp/d149_*.XXXXXX`; the planner
  sandbox refuses `/tmp` (7am D1 precedent). **Plan:** executor probes `/tmp` first; if blocked, reroot
  the two templates 1:1 under `$S`. Not pre-resolved because the executor's sandbox may differ.
- **A5. `Ran 9 tests` stability.** AC3 expects 9 both before and after (D2 touches assertions, not test
  methods). If main lands another MapIndex test before execution, the count drifts — the pause point
  covers it; do not edit the expectation.

## Velocity / estimate

+3/−6 across 2 files (V13). MS1 ≈ 10–15 min (baselines run in seconds; two transient edits + restores).
MS2 ≈ 15–20 min (the edits, the gates, the commit). MS3 ≈ 15–25 min on this host: drills < 2 min each
(V10), AC10 ≈ 100 s warm (V17: runtime 2–3 s, import 6–7 s warm, probe 37–46 s; cold ≈ 2–3 min), final
gate re-run in seconds. Recent rows of this size each took one iteration (7ak ~4 LOC; 7ai ~16): the same
is planned here — one iteration, three executor runs, no day-count estimated.
