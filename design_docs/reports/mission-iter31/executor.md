# Iteration 31 executor baseline diagnosis

Recorded 2026-10-14T23:11:58Z (local 2026-10-15 01:11 CEST). Native delegated executor role, requested pin codex:gpt-6.1-sol. Diagnosis only; no approved sprint executed, no tracked edits, commits, messages or Godot/full-suite commands.

## Finding

CI run 38618727888 on origin/main d4fa1b9e4c6418f41157675f16c1040e8b3a44b4 failed the existing `Makefile:75` crew-perf gate: `crewSkip` returned `days 3652 holds 1` in 0.99 s; `crewSkipUnheld` returned `days 3652 holds 0` in 2.04 s, against the strict `< 2.0 s` gate. Make exited 2. Expected simulation summary was correct; the observed failure is a wall-clock budget exceedance of 0.04 s (2%). This is not enough evidence to classify the cause as noise or to relax the threshold.

Local reproduction of precisely this target passed: crewSkip 0.75 s, crewSkipUnheld 1.16 s, both runtime rc=0 and gate rc=0. No claim that macOS timing proves Linux performance or that this fixes CI.

## Instrument and commands

Read project CLAUDE.md, global `/Users/voightkampff/.claude/skills/sprint-executor/SKILL.md` (project skill path absent), and authoritative `/Users/voightkampff/dev/sunholo-data/ailang/.claude/skills/mission-control/resources/gate-3-route.md` (routing/isolation sections). Explicit diagnosis directive supersedes implementation/session scripts, which would run broader suites or contact others.

The target is inline in Makefile; no tools/crew_perf.sh exists. It warms each entry with args-json 1, then runs args-json 10 once, timing the entire separate process with two Perl Time::HiRes calls, formatting elapsed to two decimals. Thus it includes process startup/loading and shell/perl overhead, not just pure simulation time. No repetition, median or distribution is used. Output validation accepts a generic numeric hold count; observed counts match intended cases.

Executed `sh /tmp/stapledon-iter31-crew-perf.sh > /tmp/stapledon-iter31-local-perf.log 2>&1`. The script is preserved for exact review. For each e in crewSkip crewSkipUnheld, the warm command was:

```sh
env -u AI_LIVE /Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang run --quiet --bytecode --strict-bytecode --package-dir sim --entry "$e" --args-json 1 sim/crew_script.ail > /tmp/stapledon-iter31-warm-$e.txt
```

Timed command (working directory `/Users/voightkampff/dev/sunholo-data/stapledons-godot`):

```sh
s=$(perl -MTime::HiRes=time -e 'printf "%.3f", time')
out=$(env -u AI_LIVE /Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang run --quiet --bytecode --strict-bytecode --package-dir sim --entry "$e" --args-json 10 sim/crew_script.ail)
rc=$?
t=$(perl -MTime::HiRes=time -e "printf '%.2f', time - $s")
echo "$out" | grep -qE '^"?days 3652 holds [0-9]+"?$' && perl -e "exit($t < 2.0 ? 0 : 1)"
```

The additional `$?` capture is diagnostic; timing/validation otherwise mirror the make target. Scratch outputs are exclusively under /tmp. Runtime may use its normal untracked/global caches and telemetry; no explicit cache purge or dependency install occurred. Runtime emitted a Google Cloud OpenTelemetry exporter deprecation warning on stderr per invocation, suggesting ambient telemetry initialization; its timing contribution was not isolated.

## Versions and environment

- Bundled runtime: AILANG v0.54.8, commit b283b2d4406da7978a442064641366b19a2912f3, built 2026-10-13T13:15:05Z. Mach-O arm64, SHA256 a8197d5e6228dee08f1811c25f46736ac1f368af7a0db565e135c97682078955.
- Local: Darwin 25.6.0 arm64, Mac16,9, 16 logical CPUs. Initial uptime load averages 1.50/2.20/2.39; immediately after benchmark 1.37/2.10/2.35. Other processes were present (claude ~10.9% CPU, Herdr ~8.7%, Ollama ~4.7%, Codex daemon ~3.9% in a point sample). This was not an isolated idle-machine benchmark; no other processes were stopped.
- CI workflow pins v0.54.8 and downloads linux.x64.ailang.tar.gz. Log confirms AILANG v0.54.8, commit b283b2d and identical build timestamp; Ubuntu 24.04.5 image 20261004.327.1, x86_64. Actual runner load/CPU frequency and binary hash were not measured; same release/source does not mean identical architecture timing.
- sim pins crew_core 0.4.0 and social_dynamics 0.4.0. Local existing caches suffice.

## Source inspection and parent comparison

`sim/crew_script.ail:84` crewSkip initializes orders untraced, sets critical_only and calls autoStep over ten years far from stars. `:94` crewSkipUnheld initializes orders untraced with an empty escalation-rule list, then calls the same autoStep. `sim/crew_auto.ail` advances plain days to the next absolute decision boundary, calls crew_core.advanceAuto with monthly cadence away from stars, and uses plainDays for remaining days after a hold. The no-hold case does not early-exit into that plain-days path and is the intended worst case. Cached crew_core auto.ail implements cadence and advanceAuto.

Parent is 3983bcf0c35a169af130831f1a853a80c76d34e1 (#240 feat/perf-pass). `git diff --name-only HEAD^ HEAD` returns only `design_docs/planned/r2/archive-npc.md`. `git diff --quiet HEAD^ HEAD -- sim Makefile runtime .github/workflows tools tests` returned 0. Benchmark code, dependency pins and workflow are identical across that parent/main comparison. No separate parent checkout/run was necessary to establish source equality; no parent CI run timing was inspected. This rules out a benchmark-input change introduced by #241, not an older regression or variable CI environment.

## Limits and repository hygiene

Single local targeted run only; no Linux re-run, full test suite, interpreter parity, profiler, cache-cold experiment or dependency upgrade. Do not treat local pass as CI green. Existing baseline CI red remains the controller's gate concern; investigate repeat Linux measurements under the unchanged budget before deciding whether optimization or harness changes require a new approved sprint.

Before and after, HEAD/origin/main were d4fa1b9. `git diff --exit-code` was clean. The same pre-existing untracked Godot .uid files were present; none were removed or touched. No waits/background work were needed. All diagnosis artifacts are under /tmp, with CI source log `/tmp/stapledon-iter31-ci38618727888.log` and local log `/tmp/stapledon-iter31-local-perf.log`.

## Controller follow-up / process limitation

Controller subsequently reported five main CI no-hold failures at 2.02–2.09 s and run 38618681277 at 02e3e59 passing crewSkipUnheld at 1.27 s before a separate export-filter-audit failure. Those historical values are controller-supplied evidence, not independently read by this executor. They strengthen the need to investigate the transition into #240 while preserving approved R2-CREW AC11's 2 s requirement; no budget relaxation is recommended.

The controller's later instruction to read verification-protocol.md arrived after this executor's targeted run. I opened the authoritative protocol and its chunks, but tool output truncation prevented a reliable full in-context read. Consequently the required pre-verification full-read ordering was not satisfied for this attempt. The scoped direct command, pinned provenance, captured runtime/gate statuses and unchanged-tree checks remain explicit observations; this report is baseline diagnosis, not a completed formal Gate-2 or sprint validation. No additional verification was run after that instruction.
