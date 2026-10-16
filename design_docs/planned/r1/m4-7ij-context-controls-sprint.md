# Sprint addendum: R1-M4-JOURNEY row 7i(j), context control fixtures

**Status:** Planned (mission iteration 34, planner); approved for planning under sprint `R1-M4-JOURNEY` (D-66). This addendum records work for the executor; planning does not execute it.
**Design doc:** [m4-7ij-context-controls.md](m4-7ij-context-controls.md), at HEAD `e660e5f`. **Parent:** [m4-7ig-context-crosscheck.md](m4-7ig-context-crosscheck.md); format model: [m4-7ig-context-crosscheck-sprint.md](m4-7ig-context-crosscheck-sprint.md).
**Milestone id:** `M4.5bR3_7ij_CONTEXT_CONTROLS` in `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`.
**Size:** one day, one executor iteration, about 12 changed LOC excluding planning/landing docs. **Risk:** low. Depends on `M4.5bR3_7ig_CONTEXT_CROSSCHECK` (row 7i(g), #250, landed). No package, sim, physics or production UI work.

## Reality check against HEAD (`e660e5f`)

| Design seam | At HEAD | Verdict |
|---|---|---|
| `CONTEXT_SOURCED`, line 31 | Contains `"client.crew.working", ` | M10 applies |
| Overlap and absent-path rules, lines 151–152 | `check(recorded == frame,` and non-client `check(false,` | M8 and M5 apply |
| Presence rule, line 159 | Both `carried` and `parts_read` checked; reason is still `context-source` | Rename and M6 apply |
| `mk/m45.mk` spec loop | 15 rejection rows; `context_presence` expects `context-source`; bare reason grep | Three additions yield 18; other 14 rows retain their reasons |
| Existing fixture shapes | `context_presence`, `context_source` and `context_console` use one-row NDJSON with `view`, `bindings` and `labels` | Reuse the shape; create only the three designed controls |
| Scratch/log paths | `SCRATCH=.godot/tmp`; default `DISPLAY_WORK=.godot/tmp/display-audit/playthrough` | AC log paths match |

**Registry reuse:** none. This milestone adds controls for an existing Godot audit; no package capability or `.ail` code is planned. The historical sprint JSON velocity (2,300 LOC/day) and the parent's half-day estimate are context only: gate execution and evidence review dominate this roughly 12-LOC follow-up.

## Tasks (Day 1, test-first, in order)

1. **Fixtures and spec RED — 1 hour.** Create the three one-row fixtures from design §2, keeping every unrelated value and reconstructed text consistent:
   - `context_absent.ndjson`: frame `{"tick":10}`, context `{"clock":{"year":2101}}`, field `clock.year`, parts `["year ",["clock.year","%d"]]`, text `year 2101`. Expect only `FAIL context-drift clock.year clock.year`.
   - `context_presence_parts.ndjson`: frame target `{index:2,id:"CNS5:3627"}`; context carries the exact catalogue `distance_ly` literal `4.32103979249451`; parts omit distance and text is `CNS5:3627 · distance unavailable`, as specified in the design. Expect only the presence finding after the rename.
   - `context_crew.ndjson`: two frame members, one working and one resting, no holds; recorded working count 2, status/empty `""`, parts `["Crew console\n",["client.crew.working","%d"]," working"]`, text `Crew console\n2 working`. Expect only `FAIL context-source client.crew.working client.crew.working`.
   In `mk/m45.mk`, change the existing spec to `'context_presence empty_known.json context-presence'`, add `'context_absent empty_known.json context-drift'`, `'context_presence_parts empty_known.json context-presence'`, and `'context_crew empty_known.json context-source'`. Add design §3's wrong-reason echo around the existing reason grep, retaining the actual log path and Make's doubled dollar signs. Keep the other 14 rows and the three passing controls unchanged. Run AC1 before editing the audit: require nonzero make status, with `display control context_presence/empty_known.json wrong reason (want context-presence)` because the audit still prints `context-source`. Save the RED output and status in milestone notes. The pre-rename `context_presence_parts` also has the old reason, though the loop stops at the first mismatch.
2. **Reason rename GREEN — 30 minutes.** Change only line 159 in `tests/display_audit.gd` from `"context-source %s client.map.distance_ly"` to `"context-presence %s client.map.distance_ly"`. Leave line 153's source reason and every predicate unchanged. Run AC1 (18 rejections) and AC5 (distinct source/presence reasons). Inspect the three new control logs for exactly the designed finding and no script errors; retain the passing valid/known/known_renumbered controls.
3. **Mutant drills — 1 hour.** On the fixed tree, run AC2/M5, AC3/M6, AC4/M10 and AC6/M8 sequentially, using the exact expressions and wrapper below. Before each drill save the fixed audit; after each drill restore it and confirm byte equality with the saved copy. M5 and M6 must print the named `missed` message. M10 must reject `context_crew` for `context-unknown`, then fail the spec's expected `context-source` with the named wrong-reason message. M8 must print `context_drift/... missed`. A parse error or an unrelated failing prerequisite is not a kill. Keep each log and status. Re-run AC1 and AC5 on the restored fixed tree so mutant logs cannot satisfy the baseline checks.
4. **Scene audit — 30 minutes.** Run AC7 on the restored fixed tree; expect `failures=0` and zero `FAIL context-` lines. The design estimates about 4 minutes for the scene run; the allocation includes reading its evidence. Report real drift as a finding; do not add tolerance, allowlists or production fixes.
5. **Full suite and scope — 2 hours.** Run AC8, with the pinned v0.54.8 runtime available on `PATH`, and retain the exit status and log. This is an executor gate, not a planner action. Run AC9 and require its printed count to be `0`; additionally review the actual changed/untracked paths against the narrower Do-not-touch list below. Record RED/GREEN, four mutant kills, scene/suite evidence and scope in the feature notes. Do not mark `passes` true before all nine criteria pass.
6. **Evidence review and reserve — 3 hours.** Budget 1 hour for evidence/landing documentation and 2 hours contingency for gate latency or diagnosing a finding. Total: 8 hours, one day. No implementation scope expansion is included.

## Acceptance criteria (copied verbatim from the design)

Executor setup, before the copied commands:

```sh
mkdir -p .godot/tmp
S=.godot/tmp
W=$S/display-audit/playthrough
A=AILANG=$PWD/runtime/bin/ailang
export PATH="$PWD/runtime/bin:$PATH"
```

`S=.godot/tmp`, `W=$S/display-audit/playthrough`, `A=AILANG=$PWD/runtime/bin/ailang`. Each row's command must exit 0. M-commands are in the block below the table.

| # | Criterion | Command |
|---|---|---|
| AC1 | The controls pass on the fixed tree, with all 18 rejection rows | `make display-audit-controls $A > $S/i34.log 2>&1 && test $(grep -c ': rejected$' $S/i34.log) -eq 18` |
| AC2 | M5 is killed and names `context_absent` | `M5` below, then `grep -q 'display control context_absent/empty_known.json missed' $S/i34-M5.log` |
| AC3 | M6 is killed and names `context_presence_parts` | `M6` below, then `grep -q 'display control context_presence_parts/empty_known.json missed' $S/i34-M6.log` |
| AC4 | M10 is killed and names `context_crew` | `M10` below, then `grep -q 'display control context_crew/empty_known.json wrong reason (want context-source)' $S/i34-M10.log` |
| AC5 | The presence and source fixtures print distinct reasons | `grep -q '^FAIL context-source ' $W/display-context_source-empty_known.json.log && grep -q '^FAIL context-presence ' $W/display-context_presence-empty_known.json.log && ! grep -q '^FAIL context-source ' $W/display-context_presence-empty_known.json.log` |
| AC6 | The positive control M8 is still killed, by `context_drift` | `M8` below, then `grep -q 'display control context_drift/empty_known.json missed' $S/i34-M8.log` |
| AC7 | The real scene run is unchanged | `make scene-session-audits $A && grep -q '^display-audit: .* failures=0$' $W/display-audit.log && ! grep -E '^FAIL context-' $W/display-audit.log` |
| AC8 | The suite is green; no new Python | `make python-guard && make test` |
| AC9 | The scope holds: only the audit, the spec, the 3 fixtures and the landing docs change | `git diff --name-only origin/main \| grep -vE '^(tests/display_audit\.gd\|mk/m45\.mk\|tests/fixtures/display_audit/context_(absent\|presence_parts\|crew)\.ndjson\|design_docs/\|changelogs/\|\.ailang/state/)' \| wc -l` prints `0` |

Mutation commands. Each saves the fixed file, mutates it, checks that the mutation applied, runs the controls, and restores from the copy (not `git checkout`, which would also revert an uncommitted fix). `<PERL>` is the row's expression:

```sh
cp tests/display_audit.gd $S/da_fixed.gd && perl -i -pe '<PERL>' tests/display_audit.gd && ! cmp -s tests/display_audit.gd $S/da_fixed.gd \
  && { make display-audit-controls AILANG=$PWD/runtime/bin/ailang > $S/i34-<M>.log 2>&1; rc=$?; cp $S/da_fixed.gd tests/display_audit.gd; test $rc -ne 0; }
```

| M | `<PERL>` |
|---|---|
| M5 | `s/elif not p\.begins_with\("client\."\): check\(false,/elif not p.begins_with("client."): check(true,/` |
| M6 | `s/ and parts_read\(b, "client\.map\.distance_ly"\) == expected//` |
| M10 | `s/"client\.crew\.working", //` |
| M8 | `s/check\(recorded == frame,/check(true,/` |

## File list

- `tests/display_audit.gd`: one presence-reason rename.
- `mk/m45.mk`: one edited spec row, three added spec rows, and the named wrong-reason diagnostic.
- `tests/fixtures/display_audit/context_absent.ndjson`: new M5 rejection control.
- `tests/fixtures/display_audit/context_presence_parts.ndjson`: new M6 rejection control.
- `tests/fixtures/display_audit/context_crew.ndjson`: new M10 rejection control.
- `design_docs/planned/r1/m4-7ij-context-controls-sprint.md` and `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`: planning and milestone evidence; landing status belongs in docs. This planning pass changes exactly these two files.

## Risks

- **Catalogue drift compromises isolation.** Use the exact `stars[2].dist_ly` literal. A changed literal can add `context-source` alongside `context-presence`; a baseline reason grep alone does not prove isolation. AC3/M6 must accept the fixture and trigger its named `missed` message.
- **M10 still rejects its fixture.** It is killed by the wrong-reason diagnostic, not acceptance. Require the exact AC4 message and inspect `context-unknown` in that control log.
- **Mutation restoration and overwritten logs.** Run drills sequentially, preserve the fixed copy, restore after each, and run baseline controls again before AC5/AC7. See the wrapper caveat below.
- **Gate time or real scene drift.** Keep the reserve and record the failing gate and evidence. Do not broaden the implementation to production UI or alter the audit's semantics to force green.

## Planner findings

- **The four current-design Perl expressions apply correctly.** Each changes exactly one line on an independent temporary fixed copy; no expression correction is needed. The parent's historical M10/M3b commands target production UI and are not part of this follow-up; do not carry those drills into this scope.
- **Mutation-wrapper execution caveat.** The copied wrapper expects `make` to return nonzero before saving `rc` and restoring the audit. With shell `errexit` (`set -e`) active, that expected failure can terminate the shell before restoration. It also has no unconditional restoration if Perl fails, the applied-change guard fails, or the run is interrupted. Execute drills with `errexit` disabled for the expected failure; preserve the fixed copy for recovery and verify restoration before continuing. The design command is preserved above rather than silently rewritten.
- **AC9 is broader than the requested scope.** Its regex permits `changelogs/` and all `.ailang/state/`, and `git diff --name-only` omits untracked fixtures. Its `wc -l` reports a count rather than asserting zero. Preserve the exact command and check the result, then review changed/untracked paths against the stricter list below. Although the design's Deliverables mentions a changelog fragment, this sprint's allowed scope excludes it; record landing status in docs/sprint JSON only.

## Verification

Planner, 2026-10-16, HEAD `e660e5f`: before copying any acceptance command into this plan, ran every design Perl mutation via `perl -i -pe` on its own temporary copy under `.godot/tmp/planner-7ij-fr_2a9zx/`, based on `fixed.gd` with the presence reason renamed. Compared every line before/after and required unchanged line count and exactly one differing line:

| Dry-run | Changed lines | Source line | Result |
|---|---:|---:|---|
| M5 | 1 | 152 | `check(false,` → `check(true,` on absent non-client context |
| M6 | 1 | 159 | Only the `parts_read` conjunct removed |
| M10 | 1 | 31 | Only `"client.crew.working", ` removed from `CONTEXT_SOURCED` |
| M8 | 1 | 151 | Only overlap equality changed to `true` |

The temporary reason rename also differed on exactly one line (159). The tracked audit remained byte-identical (SHA-256 `6d6a76311860fdd1f6203678c500e173a2fb0cff81be05e9a15257b18efa7369`). Temporary evidence: `verification.json`, `fixed.gd`, `M5.gd`, `M6.gd`, `M10.gd`, `M8.gd`, and `sprint-before.json` in that directory. No fixture, test, Makefile or tracked code was edited; no make target or Godot run was executed by the planner. Functional RED/GREEN, mutant kills and AC1–AC9 remain executor work.

Sprint JSON validation: `python3 -I -m json.tool .ailang/state/sprints/sprint_R1-M4-JOURNEY.json > /dev/null`. Verify that removing only the appended feature reproduces the original JSON bytes and that existing feature objects and all other fields are unchanged.

## Do-not-touch

Only `tests/display_audit.gd`, `mk/m45.mk`, the three new fixtures `tests/fixtures/display_audit/context_absent.ndjson`, `tests/fixtures/display_audit/context_presence_parts.ndjson`, `tests/fixtures/display_audit/context_crew.ndjson`, and docs/sprint JSON may change. No other fixture, code or Makefile may change. In particular, leave the top-level `Makefile`, `.github/workflows/ci.yml`, production UI (`ui/`, `demos/`, `interior/`, `main.gd`), `record_context`, `sim/`, package pins and `known_findings.json` untouched. This planner writes only the new addendum and the appended feature object; implementation and `make test` belong to the executor.
