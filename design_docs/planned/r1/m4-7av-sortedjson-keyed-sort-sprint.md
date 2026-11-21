# Sprint plan — social_dynamics 0.4.1 keyed `sortedJson`

**Sprint** R1-M4-7AV-SORTEDJSON · **Iteration** 109 · **Release** r1 · **Status** planned. [Approved design](m4-7av-sortedjson-keyed-sort.md) governs AC1–AC14 and Appendix A.

## Summary and baseline

Prepare an open package PR for D-171’s default A with a private keyed sort, byte-identity proofs and fresh decision-day timings. The package clone is based on `6991f54` and its sources match registry 0.4.0 (V-c). The game baseline is `059bad3c`; the mission design head is `ec5dfcfc`. V-d measured 145 passing package tests on 0.4.0. V-p/V-s measured 146 on the rehearsal tree.

**Day 1** The executor runs SJ2 through MUTATIONS, then the controller reruns those gates and proceeds through EXAMPLES to PR. Budget 103 minutes of checks and work across both roles, including about an hour of headless compute per the design. The package change is about 22 LOC. V-q and V-j measured about 7–8 minutes total for the four positive determinism targets, and V-u measured sub-second negative controls. The past week has no commits touching this package or its examples, so estimates use the measured gates and the design’s LOC estimate. Main risks are a silent old-package run, host-load variation, and replay hitting its bound.

**Registry reuse** Contribute SJ2, SJ1, and SJ3 to existing `sunholo/social_dynamics`; the remaining milestones operate on existing tests, evidence and the PR. The pinned CLI’s `pkg search social_dynamics` and `pkg info sunholo/social_dynamics` were blocked by DNS. `pkg docs sunholo/social_dynamics` resolved locally and design V-b/V-c identify the existing 0.4.0 package. AC5 rechecks the registry outside the sandbox.

**AILANG prompt version loaded: v0.16.11** from AILANG v0.56.1 (05c860a). The existing `wire.ail` and `wire_test.ail` are the test surfaces. Example coverage uses the five existing recordings in both engines. Contracts stay on the existing `encodeConfig` export. The helpers are pure, and the plan adds six inline tests and one named export test.

## Execution contract and setup

The executor is a sandboxed Codex run with workspace-write on `$C` (`/Users/voightkampff/dev/sunholo-data/ailang-packages-sd-sortedjson`). It handles package code, tests, package gates and mutations, and writes Appendix A’s `mut.sh`, `examples.sh`, `pin.sh`, and `decision.sh` into `/tmp/sdk-i109` as executable scratch scripts. It preserves the tests-only snapshot and logs there for the controller.

The **controller** reruns **every gate** outside the sandbox, including the tests-only baseline, package gates and mutations, and owns AC8–AC13. In-sandbox verdicts are not evidence. Capture raw logs and exit statuses before filtering output, including the named mutant failures and both hash mismatch controls. The controller handles git writes and opens the package PR.

**Hard stops.** Never run `ailang publish` without `--dry-run`. Never edit `sim/ailang.toml` or `sim/ailang.lock` in the mission clone. Pin edits are confined to the scratch clone. Never merge the package PR. Never close PR #144.

Use the design setup with the assigned scratch path. Verify the evidence archive’s SHA-256 before unpacking. Start with fresh test, pin and example scratch locations within `$W`. The controller uses the real HOME for baseline and negative-control commands. Pass the setup variables to Appendix A’s scripts and record the measured `$NEW` for later steps.

```sh
C=/Users/voightkampff/dev/sunholo-data/ailang-packages-sd-sortedjson; P=$C/packages/social-dynamics
G=/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter109; A=$G/runtime/bin/ailang   # v0.56.1 05c860a
W=/tmp/sdk-i109; mkdir -p $W/ev && (cd $W/ev && curl -sfLO https://storage.googleapis.com/stapledons-voyage-assets/benchmarks/7av-iter108/7av-iter108-evidence.tgz && echo "694cd6d3da02c0ec97b77f584877bbb43c932b1aa9e677fe8bdce0917b9fccd3  7av-iter108-evidence.tgz" | shasum -a 256 -c && tar xzf 7av-iter108-evidence.tgz)
OLD=sha256:3ecabb4a58f4ace19cf5ae488551ec3a7462f4a11fc8e13ab9f61386e78013e9
export C P G A W OLD
```

## Milestones in execution order

### SJ2 — Add oracle, tie-permutation, and export tests

**AC2 · Executor, then controller rerun · 20 min · ≈15 LOC** Keep the 0.4.0 implementation in `wire.ail` while adding its private oracle and `agrees040`, all six approved inline cases, and the `flatMap` permutation helpers. The tie case checks all 120 orders against the fixed oracle bytes and each order’s oracle bytes. Add the `wire_test.ail` export test for strain before trust in both orders through `encodeConfig`. Save the tests-only 0.4.0 snapshot so the controller can replay both runs. Apply SJ1’s keyed line and Appendix A’s M1 only in paired scratch copies of the old suite and the tests-only snapshot to show M1 survives before the new tests and fails in both layers after they are added. Preserve the logs for AC6.

```sh
cd $P && $A test --allow-skips wire.ail
cd $P && $A check --package . && $A test --package .
```
**Expected.** AC2 returns 0 with all six `sortedJson …` tests green, including the tie test, and `0 failed`. Five existing inline properties skip. AC3’s package run includes the export test and reports 146 passed, 0 failed, 0 skipped on the tests-only 0.4.0 snapshot. M1 survives the old package suite at 145/145 and is killed after the additions.

### SJ1 — Apply the approved one-line keyed sort

**AC1 · Executor, then controller rerun · 5 min · ≈1 LOC** Replace only `sortedJson`’s implementation with SJ1’s measured line in `packages/social-dynamics/wire.ail`. Keep it private. The export test and existing example recordings cover the public path.

```sh
grep -cF 'ja(map(\p. p.j, sortBy(\a b. if a.k<b.k then 0-1 else if a.k==b.k then 0 else 1, map(\x. {k: encode(x), j: x}, xs))))' $P/wire.ail
git -C $C diff --name-only origin/main
```
**Expected.** The grep prints `1`. The diff is confined to `packages/social-dynamics/{wire.ail,wire_test.ail,ailang.toml,CHANGELOG.md}`. The two release files enter the diff in SJ3. Recheck the four paths on the final tree.

### SJ3 — Update release metadata and run package gates

**AC3, AC4, AC5, AC7 · Executor, then controller rerun · 10 min · ≈6 LOC** Set `version = "0.4.1"`, `[release] kind = "fix"`, and add `## 0.4.1` to `CHANGELOG.md` per §2. Run check, package tests, inline tests, both quality modes, and the dry run in that order from `$P`. Use the existing example recordings in EXAMPLES. The example Makefile’s `validate` target rewrites the example lock, so use the three scratch trees for that check.

```sh
cd $P && $A check --package . && $A test --package .
cd $P && $A test --allow-skips wire.ail
cd $P && $A pkg quality . && $A pkg quality --strict .
cd $P && $A publish --dry-run 2>&1 | grep -E 'Interface hash:|Dry run complete'
git -C $C status --porcelain
$A pkg versions sunholo/social_dynamics | sed -n 3p
sed -n 3p $P/CHANGELOG.md
grep -E '^(version|kind) =' $P/ailang.toml
```
**Expected.** AC3 check passes all 18 files and the package reports 146 passed (or more), 0 failed, 0 skipped for the 146-test run. The inline run repeats AC2. AC4 returns 0 in both modes with `quality sunholo/social_dynamics@0.4.1`, `release: kind fix  changelog_section true`, interface `✓ v2 3d27ec9e9e00…`, `0 failed` and `✓ no gates`. V-s measured 11/48 contracts verified, 0 refuted. AC5 prints interface `sha256:9b3a358aa0d8e54d50343eebc1fb0cdea4824749e0110e331ad596545d1d9ed2` and `Tarball ready but not uploaded`, leaves no untracked tarball, and lists `v0.4.0 ← latest`. AC7 prints `## 0.4.1`, `version = "0.4.1"`, and `kind = "fix"`.

### MUTATIONS — Kill M1, M2, and M3 in both test layers

**AC6 · Executor, then controller rerun · 10 min** Run the Appendix A mutation loop on copies of the final package. Keep full package and inline test logs to show the named failures and retain `$W/m_M1/wire.ail` for EXAMPLES.

```sh
for m in M1 M2 M3; do rm -rf "${W:?}/m_$m"; cp -R $P $W/m_$m; $W/mut.sh $W/m_$m $m; (cd $W/m_$m && $A test --package . | grep -E '^[0-9]+ tests:'; $A test --allow-skips wire.ail | grep -E '^[0-9]+ tests:'); done
```
**Expected.** M1, M2 and M3 each report at least one failure in both layers and each kills the tie test. V-t measured six `sortedJson` failures per mutant, with two unrelated inline tests passing and five skips. E1 is observation only.

### EXAMPLES — Prove example byte identity with both controls

**AC8 · Controller · 8 min** Run Appendix A’s `examples.sh` with an empty `$W/exhome` and the controller’s regenerated M1. Use the three archives and fresh path locks, then run all five recordings in both VM and interpreter.

**Command.** `$W/examples.sh`
**Expected.** `x0` prints `$OLD` with `path`; `x1` and `xM` each print a hash different from `$OLD` with `path`. `x0 vs x1: same 10 DIFF 0` and `x0 vs xM(M1): same 0 DIFF 10`.

### SJ4 — Establish the scratch pin with PC-A and PC-B

**AC9 · Controller · 6 min** Run Appendix A’s `pin.sh`. Copy the eight locked packages into `$W/home`, overlay the final PR’s `wire.ail` in the 0.4.0 cache slot, and keep that slot’s 0.4.0 manifest. In the detached scratch game at `origin/main`, take `$NEW` from PC-A before changing the scratch lock. Record the full `$NEW` and set it in the controller shell for SJ5.

**Command.** `$W/pin.sh`
**Expected.** Slot-to-PR `cmp` is silent and returns 0. `PC-A ok` shows the scratch HOME and original lock reject `locked: $OLD, current: $NEW`; `PC-B ok` shows the real HOME and edited scratch lock reject `locked: $NEW, current: $OLD`. `$NEW` differs from `$OLD`.

### SESSION-HASH — Verify the recorded session hash

**AC10 · Controller · 4 min** Replay `h4.req.ndjson` through the pinned VM under the scratch HOME. Preserve the reply stream to check its line count alongside the hash.

```sh
cd $W/stap && HOME=$W/home $A run --quiet --bytecode --package-dir sim --caps IO --entry main sim/ship.ail < $W/ev/runs/h4.req.ndjson | shasum -a 256
```
**Expected.** 640 replies and SHA-256 `dd62855ccabb348d227cf2af30ffa978560e60525127813a14934fb40e5f1d04`.

### TIMING — Measure interleaved decision-day timing

**AC11 · Controller · 10 min** Run Appendix A’s `decision.sh` with `uptime` before each of A B A B A B. A uses 0.4.0 and the real HOME. B uses the PR’s 0.4.1 wire code and scratch HOME. Request line 462 (`"at":462`) is tick 460. Enable `Clock` only in each scratch timing copy.

**Command.** `$W/decision.sh`
**Expected.** Each run prints `control tick 459 … total_ms` and `decision tick 460 reps 50 total_ms N`. Report each arm’s load and N/50 ms per call, and A − B for each adjacent pair (PC-C). Put these alongside iteration 108 (64.1–64.8 → 43.6–44.1 ms) and V-n (Δ 20.1–21.3 ms). AC11 has no timing bound. A decision day still takes about 62 ms against the 50 ms window.

### SJ5 — Prove determinism with four per-target negative controls

**AC12 · Controller · 20 min** Run all four real-HOME negative controls on the same scratch lock before the positive loop. The first line is AC12 verbatim. The second expands its prescribed scratch-HOME loop and records elapsed time.

```sh
cd $W/stap && for t in strict parity replay crew-parity; do perl -e 'alarm 300; exec @ARGV' make $t AILANG=$A > $W/neg_$t.log 2>&1; echo "$t rc=$?"; grep -c "content changed (locked: $NEW, current: $OLD)" $W/neg_$t.log; done
cd $W/stap && for t in strict parity replay crew-parity; do alarm_code='alarm 600; exec @ARGV'; if [ "$t" = replay ]; then alarm_code='alarm 1200; exec @ARGV'; fi; (time HOME=$W/home perl -e "$alarm_code" make $t AILANG=$A) > $W/pos_$t.log 2>&1; echo "$t rc=$?"; done
```
**Expected.** Each negative `strict`, `parity`, `replay`, and `crew-parity` returns nonzero within 300 s with at least one matching hash diagnostic in its own log. With the scratch HOME, expect rc 0 for each and `strict digestScripted: …`, `1 cases, all identical`, `replay: 12 cases, all identical`, and `crew-parity: ok (6 recordings…`. Allow 1,200 s for replay and 600 s per other positive. If replay exceeds its bound or fails, record rc, elapsed time, and the first `FAIL` line (or its absence) as an observation. State in the PR that replay was not proven. The other three positive targets and all four negative controls still decide AC12.

### NO-PIN — Verify that no game pin was committed

**AC13 · Controller · 2 min** Check the mission and scratch clones after determinism. Record the exact outputs.

```sh
git -C $G status --porcelain -- sim
git -C $W/stap diff --name-only
git -C $G diff origin/main --stat -- sim/ailang.toml sim/ailang.lock
```
**Expected.** The mission `sim` status and manifest/lock diff are empty. The scratch diff lists only `sim/ailang.lock`.

### PR — Open and verify the unmerged package PR

**AC14 · Controller · 8 min** After the controller accepts AC1–AC13 using AC12’s documented fallback if applicable, the controller commits the package changes and opens its PR from `fix/social-dynamics-sortedjson-keyed` against `sunholo-data/ailang-packages` `main`. Inspect the full body in addition to the state/title check.

```sh
gh pr view fix/social-dynamics-sortedjson-keyed --repo sunholo-data/ailang-packages --json state,title,body --jq '.state,.title'
```
**Expected.** `OPEN`, title starts `social_dynamics 0.4.1:`, and the body quotes AC4’s report numbers, AC11’s table, and the exact §2 sentence about #144. Include the replay disclosure if the fallback applied.

Use the §2 wording verbatim. "Takes the 0.4.1 number that draft #144 proposed. #144 is held under the 2026-10-15 ruling, and its cause (ailang#1827) is fixed in v0.54.10. If it is revived, it rebases onto the next number."

## Completion

Keep outputs and AC11’s three-pair table in the execution report beside the design. The design’s Deliverables also lists the F6 resolver DX report. The controller routes it with the V-a repro and AILANG version via the project’s inbox convention. The mission tree’s execution artifact is the report.

Before execution, the controller checks D-171’s upstream-taken exception and stops if the inbox shows that maintainers have taken the fix. There are no additional human-decision gates for this PR. After outside-sandbox verification, record the evidence in the sprint JSON and route the work to an independent evaluator under `CLAUDE.md` (70/100 minimum). The controller leaves the verified package PR open.
