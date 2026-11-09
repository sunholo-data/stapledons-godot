# Sprint plan: R1-RIG-KEEP-GOING — nightly rig/full keeps going past a red target (row 7ag)

**Design doc:** [rig-keep-going.md](rig-keep-going.md) (revision 1; design-quorum round 1 was a 2/3 block, answered by the
+K-more suffix reserved at the count's width, the too-long-first-name cut, and the V24 static plus V23 dynamic nested-make
arms — see its "Quorum round 1"; Open questions: none). **Sprint JSON:** `.ailang/state/sprints/sprint_R1-RIG-KEEP-GOING.json`.
**Approval basis:** D-88 — neutral test-infrastructure hygiene, every pillar 0 (no pillar below 0), so the unattended loop
proceeds with no attended stop. **Branch:** `mission/stapledon-iter82-7ag` (HEAD `3b17468b`; the doc's diffs are against
`0c3f46c8`, and every line they touch still reads the same here).
**Scope:** ~200 LOC: `tools/test_rig_keep_going.sh` (+147, new — the doc's measured appendix verbatim, the file that produced
V16–V18), `tools/rig_check.sh` (+20 −2, doc M1), `tools/rig_nightly.sh` (+5 −1, doc M2), `tools/test_rig_check.sh`
(~15 lines touched, +8 net), plus landing files. **`Makefile` and `mk/*` must not change** — attended PRs #412, #373, #380
and #414 hold them; the new control rides the existing `rig-check-control` target (`mk/m45.mk:54-57`, already a `make test`
prerequisite) as one case of `tools/test_rig_check.sh`, exactly as `suite-profile` does (`test_rig_check.sh:77-82`), so no
make wiring is needed. No `.gd`, `.uid`, `sim/` or `tests/` changes (V21: no `.sh.uid` is tracked). **No GPU step, no
`make golden`, and no full `make test` anywhere in this plan** — the 70+ min suite runs on main's nightly after the merge
(post-merge check below).
**V23 caveat (controller-owned, not an executor milestone):** the doc's V23 — the controller's full `make -k test` on
`0c3f46c8` with `k` inherited by every nested make — is still in flight. The executor never runs `make test`; if V23 finds a
flipped nested target it lands as an extra named red in the first keep-going nightly, and the fix (clear `MAKEFLAGS` in that
target's fixture, per the doc's convention) belongs to the target's owner, not this row.

## Test-first order (mandatory)

1. **MS1 first:** write the new control `tools/test_rig_keep_going.sh` (appendix verbatim) and make all of the
   `tools/test_rig_check.sh` changes (the `keep-going` case, the `-k test` make-call lists, the new failure descriptions,
   the counts, caller-poison `MAKEFLAGS=k`). Run both controls against the **unmodified** `tools/rig_check.sh` /
   `tools/rig_nightly.sh` and record the exact red counts below. That red run is doc sub-milestone 1 and the baseline every
   later green is judged against.
2. **MS2 second:** apply doc M1 to `tools/rig_check.sh`; every case except the two nightly ones goes green
   (intermediate: `rig-keep-going control: 16 cases, 2 failures`).
3. **MS3 third:** apply doc M2 to `tools/rig_nightly.sh`; all green.
Never present a control as green that never went red.

## Milestones

### MS1 — Red controls (test-first): new `tools/test_rig_keep_going.sh` + `tools/test_rig_check.sh` wiring (~157 LOC, 147 of them the verbatim measured appendix)

Files: `tools/test_rig_keep_going.sh` (+147, new; copy the doc's appendix verbatim — measured V16: 16 cases, 0 failures, 6 s
on both makes) and `tools/test_rig_check.sh` (~15 lines touched):

- `HERE=$(cd "$(dirname "$0")/.." && pwd -P)` and a `keep-going` case right after the `suite-profile` block (`:77-82`), on its
  exact model:

  ```sh
  if sh "$HERE/tools/test_rig_keep_going.sh" "$HERE" > "$T/keep-going.log" 2>&1; then
    echo 'rig-check control keep-going: ok'
  else
    cat "$T/keep-going.log"
    echo 'rig-check control keep-going: FAIL (see fixture output)'; fails=$((fails + 1))
  fi
  ```

  The `cat` makes the nested caller-poison `: ok$` count over-read when keep-going is red (the doc pins this — "the existing
  `suite-profile` case does the same, and the case is red either way"); record actuals.
- Make-call lists `sky-assets test` → `sky-assets -k test` in `golden-setup` (`:127`), `full-no-setup` (`:131`) and
  `test-hang` (`:138`). This also kills a no-`-k` mutant inside the stub control.
- Description EREs: `make-test-red` (`:58`) → `01234567: make test failed \(rc 1; bound 7200s\); no failing target in the log$`;
  `watchdog-override` (`:64`) → the same with `\(rc 1; bound 60s\)`; `test-hang` (`:138`) →
  `01234567: make test ran over 2s; no failing target in the log$`. `failure-refused`'s stdout ERE stays unchanged (doc M3).
  Why these hold: the stub make exits 1 (or hangs to its 124 bound) without printing a `make: *** [T]` line, so the new
  code's fail-closed branch fires with `no failing target in the log`.
- Counts, all coupling sites together: `n=17` → `n=18` (`:141`), the outer `n=18` → `n=19` (`:143`), `nok = 17` → `18` and
  `of 17` → `of 18` (`:146`).
- The caller-poison nested run adds `MAKEFLAGS=k` (`:144`):
  `RIG_CHECK_NESTED=1 MAKEFLAGS=k RIG_TEST_S=1234 RIG_GOLDEN_S=7 RIG_SETUP_S=9 RIG_DL_S=9 sh "$0" "$RIG"`.
- Closes: doc sub-milestone 1; the red half of AC1 and AC2.
- Expected RED against the unmodified rig scripts (counts assume two GNU makes on `PATH` — the Studio has 3.81 and 4.4.1;
  halve the fixture counts on a one-make host):
  - The fixture control: rc 1, `rig-keep-going control: 16 cases, 12 failures` — exactly two-red, golden-log-kept, many-red,
    hundred-red, longname-red and nightly-two-red FAIL **on each make**; green and nightly-green stay ok (this is doc
    sub-milestone 1's named fail set).
  - The rig-check control: rc 1, `rig-check control: 19 cases, 7 failures` — the outer FAIL lines are keep-going,
    make-test-red, watchdog-override, golden-setup, full-no-setup, test-hang and caller-poison; the other 12 cases stay ok.
    Caller-poison reports `(rc 1, 16 of 18 ok)`: 12 real ok lines plus the 4 fixture `: ok` lines (green and nightly-green on
    both makes) that the failing keep-going case cats.
- Verify (red proof):
  1. `sh -n tools/test_rig_keep_going.sh && sh -n tools/test_rig_check.sh` → rc 0 (the red must be behavioural, not syntax).
  2. `T=$(mktemp -d); perl -e 'alarm 120; exec @ARGV' sh tools/test_rig_keep_going.sh "$PWD" > $T/ms1-kg.log 2>&1; echo rc=$?; tail -1 $T/ms1-kg.log`
     → rc 1; `rig-keep-going control: 16 cases, 12 failures`.
  3. `perl -e 'alarm 400; exec @ARGV' sh tools/test_rig_check.sh tools/rig_check.sh > $T/ms1-red.log 2>&1; echo rc=$?; tail -1 $T/ms1-red.log; grep -c '^rig-check control .*: FAIL' $T/ms1-red.log`
     → rc 1; `rig-check control: 19 cases, 7 failures`; 7 outer FAIL lines (the catted fixture FAIL lines are indented
     differently — `rig-keep-going control …: FAIL` — and are not outer cases).

### MS2 — `tools/rig_check.sh` (doc M1): `make -k test`, failing-target list, 140-char description, separate golden log (~22 LOC, +20 −2)

Apply the doc's M1 diff verbatim: the `log="$dir.log"; [ $tests = 1 ] || log="$dir.golden.log"` split at `:51` (with the 7ag
comment), and at `:95` the `if [ $tests = 1 ]` block — `n0` line count so only this run's appended lines are read,
`bounded "$TEST_S" make -k test >> "$log" 2>&1 || trc=$?`, top-level-only extraction (`sed` over `[T] Error/Terminated` /
4.x `[file:line: T]` / `No rule to make target`, de-duped `awk '!s[$0]++'`), the stdout `rig-check: failed targets (N): …`
list, the reason wording (`rc`, `bound ${TEST_S}s` in the non-timeout text, `ran over ${TEST_S}s` on 124), the fail-closed
`no failing target in the log`, and the 140-character budget with the suffix reserved at N's width and the
too-long-first-name cut to `budget − 3` plus `...`.
- Closes: the rig_check half of AC1/AC2; AC6's first grep; the fix side of drill rows M1–M3, M6, M9, M10.
- Verify:
  1. `sh -n tools/rig_check.sh` → rc 0.
  2. `grep -c 'bounded "\$TEST_S" make -k test' tools/rig_check.sh` → `1` (AC6, first half).
  3. `grep -n 'golden\.log' tools/rig_check.sh` → the one conditional line at the old `:51`.
  4. Intermediate red (rig_nightly not yet changed — expected and required):
     `perl -e 'alarm 120; exec @ARGV' sh tools/test_rig_keep_going.sh "$PWD" | tail -1` →
     `rig-keep-going control: 16 cases, 2 failures` (nightly-two-red on each make only), and
     `perl -e 'alarm 400; exec @ARGV' sh tools/test_rig_check.sh tools/rig_check.sh | tail -1` →
     `rig-check control: 19 cases, 2 failures` (keep-going and caller-poison; the nested count over-reads the 14 catted
     fixture ok lines — record actual). Every case MS1 showed red that MS2 owns is now ok.

### MS3 — `tools/rig_nightly.sh` (doc M2): every red named in the nightly issue (~6 LOC, +5 −1)

Apply the doc's M2 diff verbatim at the issue-body block (`:100-117`): after the run's last stdout line add the
`sed -n "s/^rig-check: failed targets /Failing targets /p" "$out" | head -1` line (with the 7ag comment and its `echo`), and
replace the single `tail -30` failing-lines filter with the awk window — for every top-level `make: ***` line, the up to 20
matching lines before it, the window resetting at each top-level error — then `cut -c1-300 | head -200`. The `...` and
`tail -20` stay; the `; log X.log` parse (`:92`) already matches the new `.golden.log` name. Single-red bodies stay
byte-identical to today's: doc V20 measured that on the real `d9cc170b` log (`cmp` silent); not re-run here.
- Closes: the green half of AC1 and AC2; the fix side of drill rows M4/M5.
- Verify:
  1. `sh -n tools/rig_nightly.sh` → rc 0.
  2. `perl -e 'alarm 120; exec @ARGV' sh tools/test_rig_keep_going.sh "$PWD" | tail -1; echo rc=$?` →
     `rig-keep-going control: 16 cases, 0 failures`, rc 0 (AC1).
  3. `perl -e 'alarm 400; exec @ARGV' sh tools/test_rig_check.sh tools/rig_check.sh | grep -E 'keep-going|caller-poison|cases'` →
     `rig-check control keep-going: ok`, `rig-check control caller-poison: ok`, `rig-check control: 19 cases, 0 failures` (AC2).

### MS4 — Mutation drill, through-target checks, scope and hygiene (no new code; evidence)

- Closes: AC3, AC4, AC5, AC6 (second half), AC7, AC8 and AC9.
- AC4, the doc's drill:
  `awk '/^# --- drill begin/,/^# --- drill end/' design_docs/planned/r1/rig-keep-going.md > $T/drill.sh && perl -e 'alarm 300; exec @ARGV' sh $T/drill.sh "$PWD"; echo rc=$?`
  → the 11 `drill …` lines with the V18 counts and the named red cases (M1-no-k 10, M2-first-only 10, M3-red-is-green 10,
  M4-no-target-list 2, M5-old-tail-30 2, M6-shared-log 2, M9-fixed-9 4, M10-no-cut 2, M7-no-k-under-outer-k 10,
  M8a rc 1, M8b rc 0 — the mutant **survives**, proving the control's unset is what kills M1 under `make -k test`), then
  `drill: 11 mutant runs as predicted`, rc 0 (V18 measured 67 s; the alarm bounds a loaded host; counts assume both makes).
- AC3, through the target `make test` uses, plain and under the rig's own outer `-k`:
  `env -u MAKEFLAGS -u MAKELEVEL perl -e 'alarm 900; exec @ARGV' make rig-check-control | tail -1; echo rc=$?`, then the same
  with `make -k rig-check-control` → both rc 0, `rig-check control: 19 cases, 0 failures` (V22 measured ~192 s each on the
  prototype; the alarm is the bound). Record both counts and wall times.
- AC5, M1 dies through the target under the outer `-k` (the doc's command, bounded):
  `git clone -q . $T/c && cp tools/*.sh $T/c/tools/ && perl -pi -e 's/make -k test/make test/' $T/c/tools/rig_check.sh && { cmp -s tools/rig_check.sh $T/c/tools/rig_check.sh && exit 3; true; } && env -u MAKEFLAGS -u MAKELEVEL perl -e 'alarm 900; exec @ARGV' make -C $T/c -k rig-check-control > $T/m1.out 2>&1; echo rc=$?; grep -c 'keep-going: FAIL' $T/m1.out; grep -c 'caller-poison: FAIL' $T/m1.out`
  → `rc=2`, `1`, `1` (V22: also `rig-keep-going control: 16 cases, 10 failures`, the three `-k test` make-call cases —
  golden-setup, full-no-setup, test-hang — red, `rig-check control: 19 cases, 5 failures`). Delete `$T/c` afterwards.
- AC6: `grep -c 'bounded "\$TEST_S" make -k test' tools/rig_check.sh` → `1`;
  `git diff --name-only origin/main...HEAD -- Makefile mk | wc -l` → `0` (Makefile and mk/* untouched — they are held by
  attended PRs #412, #373, #380, #414).
- AC7 scope: `git diff --name-only origin/main...HEAD` → `tools/rig_check.sh`, `tools/rig_nightly.sh`,
  `tools/test_rig_check.sh`, `tools/test_rig_keep_going.sh`, the doc, this plan and the sprint JSON only (landing files
  appear only after MS5).
- AC8: `for f in rig_check rig_nightly test_rig_check test_rig_keep_going; do sh -n tools/$f.sh || echo BAD $f; done; git diff --check origin/main...HEAD`
  → no output, rc 0.
- AC9: `make python-guard uid-guard > /dev/null; echo rc=$?` → rc 0 (no `.py` touched; V21: no `.sh.uid` is tracked).

### MS5 — Landing files (owner: controller; only after the cross-family evaluation passes, generator ≠ judge)

- Files: `CHANGELOG.md`, the doc and this plan move, one `design_docs/README.md` row, the sprint JSON.
- `CHANGELOG.md`, under `## Unreleased`: one new dated section `### rig-keep-going (2026-11-…)` with its own `#### Added`/
  `#### Fixed` group, on the exact model of the 7af entry (`### rig-golden-setup (2026-11-09)`, `CHANGELOG.md:5`, landed in
  `612afa7c` `land(7af)`; the same trail the previous sprint plan cites, `git log --stat -3 -- tools/rig_check.sh` →
  `404daa36` MS2 `+22 −4`). Name R1-RIG-KEEP-GOING, row 7ag and issue #392 in the entry, as 7af did.
- `git mv design_docs/planned/r1/rig-keep-going.md design_docs/implemented/r1/` and the same for this sprint plan (as 7af:
  `design_docs/implemented/r1/rig-golden-setup{,-sprint}.md`).
- One index row in `design_docs/README.md` (model: `:57`, the rig-golden-setup row), with the evaluation scores once known.
- Sprint JSON: milestone statuses and per-milestone notes with the actual recorded counts and wall times, `progress`,
  `completed`, the `evaluation` block; move this file's `design_doc`/`sprint_plan` paths to `implemented/`.
- Verify: `git diff --check` rc 0, no output; `grep -n '^### rig-keep-going' CHANGELOG.md` finds the one section;
  `grep -c 'rig-keep-going' design_docs/README.md` → ≥ 1.

## Local PR gates (targeted, headless, bounded; a merge never waits on the GPU)

1. `for f in rig_check rig_nightly test_rig_check test_rig_keep_going; do sh -n tools/$f.sh || echo BAD $f; done` → rc 0, no BAD lines (AC8).
2. `perl -e 'alarm 120; exec @ARGV' sh tools/test_rig_keep_going.sh "$PWD" | tail -1` → `rig-keep-going control: 16 cases, 0 failures` (AC1).
3. `perl -e 'alarm 400; exec @ARGV' sh tools/test_rig_check.sh tools/rig_check.sh | tail -1` → `rig-check control: 19 cases, 0 failures` (AC2).
4. `env -u MAKEFLAGS -u MAKELEVEL perl -e 'alarm 900; exec @ARGV' make rig-check-control | tail -1` → rc 0,
   `rig-check control: 19 cases, 0 failures`, and the same again under `make -k rig-check-control` (AC3 — through the target
   `make test` uses, plain and under the rig's own outer `-k`).
5. The doc's drill (AC4; 11 mutant runs as predicted, rc 0) and AC5's M1-through-target check (`rc=2`, one
   `keep-going: FAIL`, one `caller-poison: FAIL`).
6. `git diff --check` → rc 0, no output (AC8).
7. `make python-guard` and `make uid-guard` → rc 0 (AC9).
8. ci.yml `run:` make targets (`.github/workflows/ci.yml`) — every one assessed:
   - **`make ci-fast`** (the GitHub fast tier; runs on every PR regardless, merge-rule gate 1): no ci-fast target reads any
     of the four touched files — only `rig-check-control` does, and it rides `make test` (`mk/m45.mk:57`), not ci-fast
     (`Makefile:55`). Membership guard, and since no Makefile/mk edit is allowed it cannot drift:
     `make -qp 2>/dev/null | grep '^ci-fast:' | tr ' ' '\n' | grep -cx rig-check-control` → `0`.
   - **`make test`** (the release `workflow_call` path only): its only coupling to this change is the `rig-check-control`
     prerequisite, which gate 4 runs directly, both plain and under `-k`. The full 70+ min suite is **not** a local gate —
     the nightly runs it on main (post-merge check).
   - Excluded with justification: `make deps` and `make lore-import CHECK=1 …` (the lore step) read the runtime pin,
     `data/lore` and the design repo — none of the touched files; `Install AILANG` / `Install Godot` contain no make target.
9. No GPU gate, no `make golden`, no full `make test` anywhere in this sprint (Mark, 2026-11-03/06; the 7af precedent).

## Post-merge check (observation, not a merge gate)

The next nightly `rig/full` on main after the merge (`~/Library/Logs/stapledon-rig-nightly.log`): about 70 minutes instead of
about 6; it still ends red today, but its `nightly-rig` issue comment opens with `Failing targets (N): bridge-operator-test …`
naming **every** red target — expected today `bridge-operator-test` (D-148), plus whatever the in-flight V23 controller
measurement surfaces; and `$TMPDIR/rig-check/<sha>.log` is still the `make test` log after that night's `rig/golden` run
(`head -1` shows the runtime line; `grep -c '^make: \*\*\*'` equals N). If a nested target flipped under inherited `k` (against
V24), it shows up there as an extra named red and its owner adds the `MAKEFLAGS` clear per the doc's convention.

## Risks (from the doc; none blocking)

- **Nested make flipping under inherited `k`:** static V24 says none can (15 of 16 closure lines expect success; the one
  expected-failure case, `make-sim-parse`, keeps its verdict — V12); dynamic V23 is controller-owned and in flight; the first
  keep-going nightly is the final check. Fix belongs to the target's owner, not this row.
- **Silently skipped dependents (V8):** none with today's reds (V14: `bridge-operator-test` and `sound-test` have 0
  dependents); a red `import` would be named first in run order.
- **Longer red nightlies** (~70 min CPU from 22:30): the nightly was meant to take that; the 23:30 launch already defers
  (`rig_nightly.sh:67`), and the golden half starts at a later launch as it does after green nights.
- **Many reds overflowing the description:** the suffix is reserved at the count's width and a too-long first name is cut
  (V25); hundred-red and longname-red assert the bound with `test`, and drill M9/M10 prove those cases bite.
- **GNU make 4.x message format (`[file:line: T]`):** handled by the same ERE and checked on 4.4.1 by the control (V16);
  the rig itself runs 3.81 (V3).

## Velocity / estimate

~200 LOC total, of which ~147 are the doc's verbatim measured control and ~10 are authored wiring expectations; the executable
change is ~28 lines across the two rig scripts. Comparison: 7af rig-golden-setup (same control family, ~85 LOC) landed in one
day on a 0.5-day estimate; rig-watchdog-7200 (the same two rig scripts, 8-case control) also landed in one day. Estimate
**1 day, one executor session**: MS1 red ~30 min (fixture run 6 s plus two ~4 min control runs), MS2+MS3 ~45 min with the
intermediate-red check, MS4 ~35 min (drill 67 s, two through-target runs ~3.5 min each, AC5 ~3.5 min, hygiene greps), then the
cross-family evaluation and MS5 landing. No GPU, no `make golden`, no `make test` run anywhere.

Pause points (also in the sprint JSON):

- Any red outside the exact MS1 fail sets, or a different count (in particular a base case such as failure-refused,
  success-refused or suite-profile turning red): stop and report — an expectation edit hit more than intended.
- A drill mutant not going the way V18 predicts (any of M1–M7/M9/M10 surviving, M8a green, or M8b red): stop and report — the
  hermetic-unset story changed.
- Either through-target run not printing `rig-check control: 19 cases, 0 failures` with rc 0: stop and report.
- Any temptation to touch `Makefile` or `mk/*`: stop — attended PRs #412, #373, #380 and #414 hold them; `rig-check-control`
  already wires the new control.
- No merge before the cross-family evaluation; MS5 landing waits on it.
