# Sprint plan: R1-RIG-GOLDEN-SETUP — nightly rig/golden setup (row 7af)

**Design doc:** [rig-golden-setup.md](rig-golden-setup.md) (revision 2; approved by two quorum rounds then the
narrow-refinement carve-out; Open questions empty). **Sprint JSON:** `.ailang/state/sprints/sprint_R1-RIG-GOLDEN-SETUP.json`.
**Approval basis:** D-88 — pure test/infra hygiene, every pillar 0 (no pillar below 0), so the unattended loop proceeds with no stop.
**Scope:** ~85 LOC across `tools/rig_check.sh` (~22) and `tools/test_rig_check.sh` (~63), plus landing files. Nothing changes in
`Makefile`, `mk/`, `.gd` or `.uid` files. **No GPU step and no `make golden` run anywhere in this plan** — the fresh-clone ACs use
`godot --headless --check-only` only (CPU parse count). **Why:** every nightly `rig/golden` on main is red before any GPU case
runs, so the definition-of-done gate-2 goldens are not re-verified on main at all.

## Test-first order (mandatory)

1. **MS1 first:** extend `tools/test_rig_check.sh` (stub + 7 cases + counts). Run the control against the **unmodified**
   `tools/rig_check.sh` and record all 7 new cases red — that run is already the AC6/AC10/AC12 mutant evidence of doc
   sub-milestone 1.
2. **MS2 second:** the `tools/rig_check.sh` change; the control goes green.
Never present a control as green that never went red.

## Milestones

### MS1 — Red controls in `tools/test_rig_check.sh`
Stub `make` appends `$*` to `$STUB_MAKES`; for the target named in `$STUB_MAKE_HANG` it runs `sleep 20 & echo $! > "$STUB_CHILD";
wait` (a bound-losing mutant ends red after ~20 s and never hangs). New helper `order <case> <flag> <failing target> <want rc>
<want make calls> <want state> <want description ERE> [RIG_SETUP_S] [RIG_DL_S] [STUB_VERSION]`. Seven new cases:
`golden-only-setup`, `golden-setup`, `golden-setup-red` (pins SETUP_S=600), `full-no-setup`, `setup-hang` (kill-0 reaper poll with
a live-`sleep` positive control), `sky-hang`, `runtime-hang` (stub version off the pin). `unset` gains `RIG_SETUP_S RIG_DL_S`;
caller-poison adds `RIG_SETUP_S=9 RIG_DL_S=9`; counts 8 → 15 and 9 → 16 (all four coupling sites per doc V7). Stub runtime stays
on the pin, so `make runtime` is called only in `runtime-hang`.
- Closes: doc sub-milestone 1; the red half of AC5; red evidence for AC6, AC10, AC12.
- Verify (red proof):
  `T=$(mktemp -d); perl -e 'alarm 300; exec @ARGV' sh tools/test_rig_check.sh tools/rig_check.sh > $T/ms1-red.log 2>&1; echo rc=$?; grep -c 'FAIL' $T/ms1-red.log`
  → rc 1; the 8 base cases `ok`; exactly the 7 new cases FAIL (record the count in the sprint JSON notes).

### MS2 — `tools/rig_check.sh`: `bounded` everywhere + the golden setup loop
Add the doc's 9-line `bounded` helper verbatim (measured V5: own process group, stdin `/dev/null`; TERM the group at the deadline,
KILL 2 s later, reap, exit 124, 130 if interrupted). `GOLDEN_SETUP="deps starmap-assets planet-assets import"` with the 7af comment
(import last), `SETUP_S=${RIG_SETUP_S:-600}`, `DL_S=${RIG_DL_S:-3600}` (4× the ~900 s sky regen; runtime fetch 3 s). Switch the two
existing watchdog lines and `make runtime` / `make sky-assets` to `bounded` with fail messages `rig setup: make <t> failed or ran
over ${DL_S}s` (the `make-test-red` and `watchdog-override` messages stay identical). Under `[ $golden = 1 ]`: per-target
`bounded "$SETUP_S" make "$t" || fail "golden setup: make $t failed or ran over ${SETUP_S}s"`, then `bounded "$GOLDEN_S" make golden`.
Plus the header line.
- Closes: AC4, AC5 (green half), AC6–AC12 (mutants M1–M7 below), AC13.
- Verify:
  1. `sh -n tools/rig_check.sh && sh -n tools/test_rig_check.sh` → rc 0
  2. `perl -e 'alarm 300; exec @ARGV' sh tools/test_rig_check.sh tools/rig_check.sh | tail -1` → `rig-check control: 16 cases, 0 failures`
  3. `perl -e 'alarm 300; exec @ARGV' make rig-check-control` → rc 0 (target at `mk/m45.mk:55`; rides `make test`, not ci-fast)
  4. AC4: `sed -n 's/^GOLDEN_SETUP="\([^"]*\)".*/\1/p' tools/rig_check.sh` → `deps starmap-assets planet-assets import`
  5. AC13: `pgrep -f 'sleep 20' | wc -l` before and after (2) — equal (no orphans).

**Mutant drills M1–M7** (each: apply the mutation to `$T/m.sh` for rig_check.sh, or `$T/t.sh` for M6, then run the control;
expect rc 1 and the named red). Commands run bounded: `perl -e 'alarm 300; exec @ARGV' sh tools/test_rig_check.sh $T/m.sh`.

| # | Mutation | Mutant (sed on the named file) | Expected red |
|---|---|---|---|
| M1 / AC6 | No setup | `sed 's/^GOLDEN_SETUP=.*/GOLDEN_SETUP=""/' tools/rig_check.sh > $T/m.sh` | rc 1; `golden-only-setup`, `golden-setup`, `golden-setup-red`, `setup-hang` FAIL |
| M2 / AC7 | import dropped | `sed 's/^GOLDEN_SETUP=.*/GOLDEN_SETUP="deps starmap-assets planet-assets"/' …` | rc 1; `golden-only-setup`, `golden-setup`, `golden-setup-red` FAIL |
| M3 / AC8 | planet-assets dropped | `sed 's/^GOLDEN_SETUP=.*/GOLDEN_SETUP="deps starmap-assets import"/' …` | rc 1; same three FAIL |
| M4 / AC9 | setup failure ignored | `sed 's/ \|\| fail "golden setup: .*$//' …` | rc 1; `golden-setup-red`, `setup-hang` FAIL |
| M5 / AC10 | group kill dropped | `sed 's/-\$pid/$pid/g' …` | rc 1; `setup-hang`, `sky-hang`, `runtime-hang` FAIL with the child alive (V5) |
| M6 / AC11 | hermetic unset dropped | `sed 's/^unset RIG_TEST_S RIG_GOLDEN_S RIG_SETUP_S/unset RIG_TEST_S RIG_GOLDEN_S/' tools/test_rig_check.sh > $T/t.sh; sh $T/t.sh tools/rig_check.sh` | rc 1; `caller-poison` FAILs (nested `golden-setup-red` posts `9s`) |
| M7 / AC12 | sky-assets unbounded | `sed 's/^bounded "$DL_S" make sky-assets/make sky-assets/' …` | rc 1 after ~20 s; `sky-hang` FAILs (V10: rc 0, calls run on to `golden`) |

### MS3 — Fresh-clone ACs, scope, hygiene, landing
- Closes: AC1, AC2, AC3, AC14, AC15, and the doc's Deliverables (landing).
- AC1: `C=../stapledons-godot-7af-ac; git clone -q . $C && cd $C && perl -e 'alarm 900; exec @ARGV' make runtime;
  test ! -f .godot/global_script_class_cache.cfg` then the doc's `count` (over the 15 scripts) → `> 0` (doc measured 644).
- AC2: in `$C`, `PATH=$PWD/runtime/bin:$PATH; for t in $(sed -n 's/^GOLDEN_SETUP="\([^"]*\)".*/\1/p' tools/rig_check.sh); do
  perl -e 'alarm 300; exec @ARGV' make $t || break; done; count` → every make rc 0, then `0`.
- AC3: in `$C`: `ls assets/planets | grep -c jpg` → `20`; `test -f data/starmap/stars_large.bin && echo tier` → `tier`. Delete `$C`.
- AC14: `git diff --name-only origin/main...HEAD` → `tools/rig_check.sh`, `tools/test_rig_check.sh`, the doc, this plan, the sprint
  JSON and the landing files only.
- AC15: `sh -n` both scripts rc 0; `git diff --check origin/main...HEAD` rc 0, no output.
- Landing (only after the evaluator passes, generator ≠ judge): one `CHANGELOG.md` line;
  `git mv design_docs/planned/r1/rig-golden-setup.md design_docs/implemented/r1/` (this plan and the sprint JSON get the repo's
  usual landing state updates); one index row in `design_docs/README.md`.

## Local PR gates (targeted, headless; a merge never waits on the GPU)

1. `sh -n tools/rig_check.sh && sh -n tools/test_rig_check.sh`
2. `perl -e 'alarm 300; exec @ARGV' sh tools/test_rig_check.sh tools/rig_check.sh | tail -1` → `rig-check control: 16 cases, 0 failures`
3. `perl -e 'alarm 300; exec @ARGV' make rig-check-control` → rc 0
4. `git diff --check` → rc 0, no output
5. ci-fast: the GitHub fast tier runs the full `make ci-fast` (`deps python-guard audio-silent-guard uid-guard lint-precision
   strict parity-v2 parity parity-gr replay crew-sync-check crew-parity lore-import-check capture-m4-publish-test`, `Makefile:55`).
   **None of these targets reads `tools/rig_check.sh` or `tools/test_rig_check.sh`** (only `rig-check-control` does, and it belongs
   to `make test`, not ci-fast), so this tools/*.sh change affects no ci-fast target; gate 1 runs it on GitHub regardless. Membership
   guard, since no Makefile/mk edit is allowed: `make -qp 2>/dev/null | grep '^ci-fast:' | tr ' ' '\n' | grep -cx rig-check-control` → `0`.

## Post-merge check (observation, not a merge gate)

The first nightly `rig/golden` on main after the merge: `grep -c 'SCRIPT ERROR' $TMPDIR/rig-check/<sha>.log` over the constellation
section → 0; the run either succeeds or fails on a real GPU case, never on setup. That night is also the GPU check of `make golden`
in its own process group (risk R2). If it is red for the process-group reason, the fallback is to revert only the `make golden`
line to the old alarm (per the doc).

## Risks (from the doc; none blocking)

- **R1 Double import on `--golden`:** accepted; ~3 s warm, fetches verify sha256 and skip.
- **R2 Process group vs Godot window-server:** unmeasured on the GPU; the first nightly is the check; fallback as above.
- **R3 Bucket miss starts a rebuild:** `bounded` stops it at 600 s per target (DL_S 3600 s for runtime/sky), posts the target's name.
- **R4 `deps` lock drift:** `rig/golden` red for a non-GPU reason; `rig/full` red the same night; the description names `make deps`.
- **R5 Next new golden input:** the `GOLDEN_SETUP` comment names the rule; the 417 `ok` count catches a silent skip.
- **R6 Control runtime:** ~46 s at 9 cases (V8); the three hang cases add ~5 s each; budget 5 min via the alarm bounds above.

## Velocity / estimate

~85 LOC total (22 + 63) plus landing files. Comparison: `rig-watchdog-7200` (same two files, 8-case control) landed in one day.
Estimate **0.5 day, one executor session**: MS1 red ~20 min, MS2 + the M1–M7 drills ~1 h (control ~2 min per run), MS3 fresh-clone
ACs ~30 min plus landing. No GPU, no `make golden`, no full `make test` anywhere in the plan.
