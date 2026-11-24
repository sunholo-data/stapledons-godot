# Sprint plan for row 7aw · Rig profile secret hygiene

**Sprint** R1-7AW-PROFILE-SECRETS · **Iteration** 114 · **Release** r1 · **Status** approved. The iteration-114 controller recorded ledger D-174’s default A as build approval. [Revision 3 of the approved design](rig-profile-secret-hygiene.md) governs the sprint. [Decision ledger](../../stapledon-mission.md#decision-ledger)

## Summary and baseline

Stream the make closure database through the profiler, confine recipe temp files to the run, and check evidence for credential values before publishing. M1–M3 follow the design’s three implementation PRs. M4 adds one changelog entry and verifies the combined change. All four milestones land in **one PR this fire**.

**Day 1** Run M1 and M2 first, then M3 and M4. Allow about 175 minutes for 360 LOC of implementation, tests, and changelog. The latest relevant tool change was `ca5279f6` on November 17, which restored the caller-poison control under long `TMPDIR`. The seven-day path history has no later tool changes. The estimates use the design’s file budgets and fixture timings, plus time to recheck revision 3 on both makes. The main risks are cleanup before the query completes and a guard check that can pass without exercising its canary.

**Registry reuse** `none` for M1–M4. These are local POSIX shell tools, fixture tests and a changelog entry. The harnesses reuse the existing profiler fixture runner, rig-check control and observation publisher’s cloud-stub pattern. There is no package capability to search for or pin.

Baseline at `9ea68b29` on `mission/stapledon-iter114`, with GNU make 3.81 and GNU Make 4.4.1. The planner ran the commands with `env -i`, a scratch `HOME` and `TMPDIR`, and `gsutil` and `gcloud` stubs on `PATH`.

| Command | Label | Observed output |
|---|---|---|
| `sh tools/test_suite_profile.sh` | PASS | rc 0, `suite-profile control: 40 cases, 0 failures` (20 s). Its own load probe stubs were active. |
| `sh tools/test_rig_check.sh tools/rig_check.sh` | UNINFORMATIVE UNDER SANDBOX | rc 1, `rig-check control: 26 cases, 10 failures` (123 s). `suite-profile: ok` and `keep-going: ok`. The nested caller-poison control reported `16 of 25 ok`. |
| `sh -n` on each existing in-scope shell file (`suite_profile.sh`, `test_suite_profile.sh`, `test_rig_check.sh`) | PASS | rc 0, silent. Syntax for the three new scripts is pending implementation. |
| `make python-guard` | PASS | rc 0, `python-guard: ok (25 allowlisted, 0 awaiting AILANG port)` |
| `make uid-guard` | PASS | rc 0, `uid-guard: ok (495 .uid files)` |

Direct `sysctl -n vm.loadavg` and `ps` probes returned `Operation not permitted`. An isolated profiler fixture reproduced `suite-profile: cannot read load (sysctl and /proc/loadavg unavailable)` with rc 1. Scratch directory creation under `/tmp` and `mktemp -t` both worked in this sandbox. Use the four green baseline commands as local gates. For AC8, rerun the unmodified rig control on a host with working load probes before using the patched run as a gate. Report any genuine red at base as a finding and keep it out of the executor gate list. The tested baseline and final fixture runs use stubbed services on that host too.

## Execution contract and setup

- Allocate a private short scratch root `S` with `mktemp -d` and `umask 077`, with its own `HOME`, `TMPDIR` and `bin`. Run fixtures from a scrubbed `env -i` with only the test paths, locale, explicit stub controls and synthetic canaries. Put both cloud stubs first on `PATH`; the recording `gsutil` stub logs argv locally, and `gcloud` fails if called. Use only synthetic `NAME` and `NAME=op://v/i/f` files. Never read `~/.config/op/*`, the rig’s template, or any real `$TMPDIR/rig-check/` profile. Keep checks quiet, report only verdicts, names and fixture paths, and clean scratch logs and temporary copies after recording safe results.
- Save pre-change `tools/` under `$S/base/tools`. For every mutation use a separate scratch root containing its own `tools/` copy of the current milestone. Run from that root so relative script paths resolve within the mutant. Edit only that scratch copy. Record the unmutated result plus the mutant’s exit status and named assertion. A missing executable, syntax error, unrelated failure or timeout cannot count as a kill. Bound background work with a `date +%s` deadline and reap it.
- Treat `/tmp/claude/i114-design-evidence/{proto,wired}/` as reference. Their `query.err` retains raw stderr and their guard includes PEM armour. Apply revision 3 in both places. Use the design’s fixture shapes for fresh runs. Until landing, the AC9 §I copy rule allows only `profile.tsv`, `load.tsv`, `header.txt`, `closure.txt` and `cpu.tsv` from a profile directory. [AC9 §I design](rig-test-speed-ac9-load-rule.md)
- Implementation scope is the seven files named below. Never touch `Makefile`, `mk/*.mk`, `tools/rig_check.sh`, `tools/rig_nightly.sh`, `tools/timed_recipe_shell.sh`, the keep-going scripts, `tools/observation_publish.sh`, `tools/python-allowlist.txt`, any `.gd`, `.uid` or `.py`, or `sim/`. New scripts use POSIX sh. Keep work headless and fixture-only. The approved design leaves bucket policy and credentials with their existing owners.

## Milestones in execution order

### M1 · Instrument the closure query and temp lifecycle

**Files** `tools/suite_profile.sh`, `tools/test_suite_profile.sh` · **45 LOC · 45 min** · **AC1–AC6, AC14**

1. Extend `test_suite_profile.sh` first. Add `secret-no-dump` as case 21 with a fake `SP_FAKE_TOKEN`, a recipe that writes it to `$TMPDIR/suite-left.tmp`, and checks for absent `database.txt`, absent `out/tmp`, and no canary in any profile file. Plant a copy to prove detection, remove it, and repeat the absence check. Verify the nonempty closure and its header hash. Extend `temp-only` to check cleanup and use an explicit `if cmp -s …; then exit 1; fi` for its observation probe. Require explicit failure branches and distinguish a clean grep miss from a grep error. Run AC2 against the base instrument and record the dump assertion failing.
2. Before changing the instrument, write the scratch AC4–AC6 and AC14 fixture checks. Use a fresh output per run and keep process logs outside it. Run the broken, warning and error Makefiles on both makes, check the query status file byte for byte, and use a planted-copy positive control for the profile scan. Exercise early failure cleanup in the broken/error fixtures and the signals while the recipe’s canary file is present. Ensure the profiler can trap INT by running it in the foreground or resetting inherited INT before `exec` as the existing sampler fixture does.
3. Pipe `make -pq` stdout into the existing awk and discard raw query stderr. Write one `query_rc=N` line to `query.err` and validate it after the query pipeline completes. Accept make query statuses 0 and 1, refuse higher statuses with the fixed failure prefix, and refuse missing or malformed status with `suite-profile: closure query status missing or invalid`. Keep the existing closure walker and goal selection. Canonicalize `out`, install cleanup before creating `$out/tmp` or running the closure query, then export it as `TMPDIR`. Reap the existing sampler and child before removing `$out/tmp` on normal completion, EXIT, INT, TERM and HUP.

| AC | Command | Expected reading |
|---|---|---|
| AC1 | `sh tools/test_suite_profile.sh; echo rc=$?` | `suite-profile control: 42 cases, 0 failures`, `rc=0` on the two-make run. |
| AC2 | `sh tools/test_suite_profile.sh secret-no-dump; echo rc=$?` | `suite-profile control secret-no-dump: ok`, `suite-profile control: 2 cases, 0 failures`, `rc=0`. |
| AC3 | Run AC2 from the separate dump and TMPDIR scratch copies below. | `secret-no-dump: FAIL`, `rc=1` for each, with its named diagnostic. |
| AC4–AC5 | `sh "$S/fixture-canary.sh"` using the pre-change and current tools with the design’s `-k test` `alpha`/`beta`/`gamma`/`leak` fixture on gmake. | `closure.txt: byte-identical` and `closure_sha256=24cfa2d68cc92b4c28d95957a368115bd48da829861b05b47b8047c7682616ff` on both sides. Before, `1 hit(s)` in `database.txt` (11 environment blocks in the reference setup), and a canary hit in `suite-left.tmp`. After, canary absent from every profile file, `database.txt` and the recipe temp file absent, and `out/tmp removed at finish`. |
| AC6 | `sh "$S/fixture-query.sh" "$PWD/tools"` runs `suite_profile.sh run --make <make> --out <profile> -- all` with each of the three fresh Makefiles on `make` and `gmake`, then checks `grep -rFq -- "$CANARY" <profile>` and the status file. Repeat on the stderr mutant. | Broken and `$(error …)` runs exit 1, give the fixed `suite-profile: closure query failed` prefix and leave exactly `query_rc=2`. The `$(warning …)` run succeeds and leaves exactly `query_rc=0` or `query_rc=1` according to the make query status. Record each value. All fixed profiles are canary-free and cleaned. The mutant fails the warning and error canary checks on both makes. |
| AC14 | `sh "$S/fixture-signals.sh"` with a slow recipe and a bounded wait for the canary under `out/tmp` before each signal. | `INT: run rc 130`, `TERM: run rc 143`, `HUP: run rc 143`. Each run records mid-run canary presence and post-run absence of `out/tmp`, the recipe temp file and the canary from the profile. |

**Mutation drills.** In three independent scratch copies of `tools/`, edit `suite_profile.sh` as follows.

- Restore §A hunks 1–2 to the database dump and awk file input. AC2 exits 1 with `secret-no-dump: database.txt in the profile dir`.
- Revert §A hunks 3–4 so `TMPDIR="$out"` and the original cleanup runs. AC2 exits 1 with `secret-no-dump: canary in the profile dir`.
- Restore query stderr to `2> "$out/query.err"` and append the numeric status after make for this drill. This preserves the raw bytes and a parseable status, so AC6 fails the canary check for each warning and error fixture on both makes.

### M2 · Implement the evidence secret guard

**File** `tools/evidence_secret_guard.sh` (new) · **138 LOC · 40 min** · **Guard portion of AC7, AC12–AC13** · **Depends on M1**

1. Write the guard-only checks first in a scratch `tools/test_evidence_secret_guard.sh`. Save them for M3. Require the expected 0/1/2 status and safe output. Cover a clean file/dir, a dirty file and archive member, missing/unreadable input and bad tar, zero/short candidates with and without `--require-candidates`, and temp cleanup. Run the dirty-file test against base and save the red result. Add the names-file, split-line and PEM cases before implementing those branches. Use a long second body line in the PEM fixture so the armour-only target proves an exclusion with usable candidates present.
2. Implement §D. Union matching environment names and repeatable `--names-file` names, dropping text after `=` and ignoring comments and blank lines. Fail with rc 2 for a missing/unreadable names file or one with no valid names. Give a names-only stderr hint for an absent environment name. Use `awk` `ENVIRON` to build private fixed-string pattern files, strip CR, trim each value line, skip blank or shorter-than-eight lines and skip `^-----(BEGIN|END) ` armour. Apply the same rule to bulk search and per-name attribution. Keep values out of stdout, stderr and child argv. Trap-clean the private temp tree, including tar extraction. Report a variable name and input path or `pack:member`, with rc 0 clean, 1 found and 2 for instrument failures or zero usable lines when required.

| AC | Command | Expected reading |
|---|---|---|
| AC7 (guard portion) | `sh "$S/guard-only/tools/test_evidence_secret_guard.sh"` with the current guard beside the scratch test. | rc 0 with all direct checks green. The armour-only file succeeds with rc 0 and zero hits. The complete `41 checks, 0 failures` line belongs to M3. |
| AC12 | With only synthetic `PRIVATE_STUFF` set, scan the canary file with `sh tools/evidence_secret_guard.sh "$S/f"`, then repeat with `--names-file "$S/n"` and `--names-file "$S/t"` before the file. Use `PRIVATE_STUFF` in `n` and `PRIVATE_STUFF=op://v/i/f` in `t`. | rc 0, then rc 1 twice with `PRIVATE_STUFF value is in <path>`. Repeat flags work, the names file itself is clean, a listed absent name yields a hint with rc 0, and invalid files yield rc 2. Values stay out of stdout and stderr. |
| AC13 | Set `SP_FAKE_TOKEN` to a synthetic two-line value and plant only line two in `$S/f`. Run `sh tools/evidence_secret_guard.sh "$S/f"`. | rc 1 and `SP_FAKE_TOKEN value is in <path>` with neither value line printed. A blank/short-only value with `--require-candidates` yields rc 2. |

**Mutation drills.** In three independent scratch `tools/` copies, edit `evidence_secret_guard.sh` and rerun the guard-only control. Drop the names-file contribution while still accepting the option (AC12 catches the unexpected rc 0). Drop the split by using only the first line (AC13 catches the missed second line). Drop the PEM skip from pattern generation and attribution (the armour-only case unexpectedly returns 1). Each control exits nonzero on the specific assertion.

### M3 · Complete the guard control and wire it into rig-check

**Files** `tools/test_evidence_secret_guard.sh` (new), `tools/evidence_publish.sh` (new), `tools/test_rig_check.sh` · **171 LOC · 65 min** · **AC7–AC8** · **Depends on M2**

1. Promote the scratch guard checks to the tracked POSIX control first. Add the wrapper cases with a local `gsutil` argv log modeled on `test_observation_publish.sh`’s `gcloud` stub. Check refusal rc 1, instrument failure rc 2 and unsafe remote rc 2, each with zero calls. Check clean rc 0 and exactly one call with `-m cp -r --`, the fixture operands and the destination. Check both paths through `EVIDENCE_GUARD_NAMES_FILE`, using an unrelated eligible value so dropping the names file would let the innocently named canary pass and reach the stub. Run AC7 red with the wrapper absent. Write the AC8 output/count check and show the old wiring has no `evidence-guard: ok` case.
2. Implement the §E wrapper. Validate the remote prefix and check for `gsutil`, invoke the sibling guard with `--require-candidates` and the optional names file, then copy only on rc 0. Pass through rc 1 or 2 with the fixed refusal diagnostic. Add the control beside `suite-profile` in `test_rig_check.sh`, preserving failure propagation. Set nested expectations and diagnostics to 26 and the outer total to 27. Update the caller-poison comment to reflect `$out/tmp`.

| AC | Command | Expected reading |
|---|---|---|
| AC7 | `sh tools/test_evidence_secret_guard.sh; echo rc=$?` | `evidence-guard control: 41 checks, 0 failures`, `rc=0`. Revision 3’s armour check is part of the 41. Stub logs show no calls for any refusal. |
| AC8 | `sh tools/test_rig_check.sh tools/rig_check.sh; echo rc=$?` on the qualified host. | `rig-check control suite-profile: ok`, `rig-check control evidence-guard: ok`, `rig-check control caller-poison: ok`, and `rig-check control: 27 cases, 0 failures`, `rc=0`. The caller-poison assertion counts 26 nested `: ok` lines. |

**Mutation drills.** On separate scratch copies of `tools/`, repeat the three M2 guard edits with the completed AC7 control. The names-file mutant must also fail the wrapper refusal and zero-call checks. The split and PEM mutants must fail their named direct checks. Run AC8 on the qualified host with the names-file mutant to confirm the nested guard failure reaches the outer status and `rig-check control evidence-guard: FAIL (see fixture output)`.

### M4 · Changelog and acceptance sweep

**File** `CHANGELOG.md` · **6 LOC · 25 min** · **AC9–AC11 and final AC1–AC8 replay** · **Depends on M3**

1. Write the changelog presence check first, `grep -Fx '### r1-7aw-rig-profile-secret-hygiene' CHANGELOG.md`, and record rc 1 before editing. Add one entry under Unreleased describing closure and temp hygiene, the guard and its fixture coverage. Rerun and expect the heading and rc 0.
2. Re-run the positive AC1–AC8 commands and the revision-specific AC12–AC14 fixtures on the combined tree. Run syntax checks on each of the six shell files plus `make python-guard` and `make uid-guard`. Record exact command, status and named output for each. AC8 follows the qualified-host rule above. The repository’s GitHub fast tier is a separate merge criterion under `CLAUDE.md`.

| AC | Command | Expected reading |
|---|---|---|
| AC9 | `grep -n '^ci-fast' Makefile \| head -1; grep -n rig-check-control mk/m45.mk` | Fast tier has no `rig-check-control` dependency. `mk/m45.mk` wires `test: rig-check-control`. `make ci-fast` covers none of the new 7aw behavior. |
| AC10 | `git diff --name-only origin/main...HEAD \| grep -c -E '\.py$\|\.gd$'` | Count `0` (grep status 1 for zero matches). `make python-guard` and `make uid-guard` exit 0 with the baseline `ok` lines. |
| AC11 | `git diff --name-only origin/main...HEAD \| grep -c -x -E 'Makefile\|mk/.*\|tools/rig_check\.sh\|tools/rig_nightly\.sh\|tools/timed_recipe_shell\.sh\|tools/test_rig_keep_going\.sh\|tools/rig_check_keep_going\.sh\|tools/python-allowlist\.txt'` | Count `0` (grep status 1 for zero matches). Inspect the full path list for any `.uid`, `sim/` or other out-of-scope implementation file. |

Before committing, also inspect `git diff --name-only HEAD` and `git ls-files --others --exclude-standard` so the path checks cover the working tree and the new scripts. Account for the approved design and sprint artifacts separately when checking the implementation file list.

```sh
for file in tools/suite_profile.sh tools/test_suite_profile.sh tools/evidence_secret_guard.sh \
    tools/test_evidence_secret_guard.sh tools/evidence_publish.sh tools/test_rig_check.sh; do
  sh -n "$file" || exit 1
done
make python-guard && make uid-guard
```

**Mutation drills.** Replay the six named edits on fresh copies of the combined `tools/`: database dump, `TMPDIR="$out"`, raw stderr, names-file contribution, multi-line split and PEM skip. Require the same AC2, AC6 and AC7 failures as above. Run the final positive checks against the unedited implementation.

## Completion

In addition to the five baseline commands as qualified above, success requires all applicable AC1–AC14 results, six killed mutants, and one Unreleased changelog entry. The synthetic Makefiles, evidence packs and stub commands are the runnable examples for this shell tooling. Record results in the sprint JSON during execution and send the combined change through independent cross-family evaluation under `CLAUDE.md` (70/100 minimum) for one PR. There are no human-decision gates. The controller’s optional choice of publisher entry point leaves the guard mandatory before a real evidence upload.
