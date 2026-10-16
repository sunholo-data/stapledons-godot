# Display audit: control fixtures for the surviving context mutants (row 7i(j))

**Status:** Planned (mission iteration 34, designer). **Release:** r1. **Milestone:** M4.5, a follow-up row under the approved D-66 plan; it is charter queue row 7i(j).
**Priority:** P3. This is test hygiene for the clause-4 display gate. It is not a player-visible change.
**Implements:** the parent [m4-7ig-context-crosscheck.md](m4-7ig-context-crosscheck.md), which in turn implements [m4-first-journey.md](m4-first-journey.md) §M4.5 "Display audit" (AC4 and AC5 as amended on 2026-10-12) and the [R1 roadmap](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) clause 4. The sprint is `R1-M4-JOURNEY`. The source is the iteration-33 independent evaluation, `.ailang/state/evaluations/eval_R1-M4-JOURNEY_7ig_round_1.json`, mutants M5, M6 and M10.
**Depends on:** row 7i(g) (#250, which introduced `check_context`). No package, sim, physics or production UI change.
**Estimated LOC:** about 12: 3 one-line fixtures, 1 changed line in `tests/display_audit.gd`, and about 3 changed lines in `mk/m45.mk`.

## Game vision alignment

| Pillar | Score | Notes |
|---|---:|---|
| Choices Are Final | 0 | No change to commit, plan or refusal. |
| The Game Doesn't Judge | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | No clock or display change. |
| The Ship Is Home | 0 | No UI or interior change. |
| Grounded Strangeness | 0 | No visual change. |
| We Are Not Built For This | 0 | Not relevant. |
| Hard sci-fi authenticity (spec) | 0 | Indirect at most. Three rules that already guard "every number is the sim's value" (parent, §Design 1–2) gain controls that prove they still run. The audit's behaviour on real scenes does not change. |
| **Net** | **0** | **Go.** This is pure test hygiene, so a zero score is the honest one. No pillar is negative, and the work keeps a gate's mutation score from hiding three dead rules. |

## Problem

Three rules in `tests/display_audit.gd` `check_context` have no control fixture. If any one were deleted, `make display-audit-controls` would stay green. The controller re-measured all three first-party at `e40d418`. Each mutant was applied, then `make display-audit-controls AILANG=$PWD/runtime/bin/ailang` returned rc 0 (survives):

- **M5** (line 152): a non-client context path that is absent from the frame is made non-fatal (`check(false,` → `check(true,`). Every existing fixture's non-client path (`context_drift`'s `tick`) is present in its frame, so that branch is never reached.
- **M6** (line 159): ` and parts_read(b, "client.map.distance_ly") == expected` is deleted from the presence rule. The only presence fixture (`context_presence`) omits `distance_ly` from both the context and `parts`, so the `carried` half alone rejects it.
- **M10** (line 31): `"client.crew.working", ` is dropped from `CONTEXT_SOURCED`. No fixture records `client.crew.working`.

A fourth gap is diagnostic. The source rule (line 153) and the presence rule (line 159) both print `FAIL context-source <node> client.map.distance_ly`. The reason grep in the `mk/m45.mk` spec loop cannot tell which rule rejected a fixture. Also, when a fixture is rejected for the *wrong* reason, the loop's bare `grep -E` fails under `set -e` without naming the fixture. That is how M7 is killed today (eval, "reason grep in m45.mk catches it"), and it is how M10 will be killed.

**Measured by this designer at `e40d418`.** I wrote the three fixtures below to `.godot/tmp/i34/` and ran `godot --headless --path . --script <variant> -- <fixture> control tests/fixtures/display_audit/empty_known.json` for the tree as it stands, the fixed variant (the presence reason renamed) and the four mutants applied to the fixed variant. Each fixture was rejected by every variant except its own mutant. Every other fixture/variant pair kept its reason. The full matrix is in the Verification log.

## Goals and non-goals

**Goals.**
- Each of M5, M6 and M10 is killed by `make display-audit-controls`, and the failure names the fixture.
- The presence rule prints its own reason, `context-presence`.

**Non-goals.**
- No change to what the audit accepts or rejects; only the presence rule's reason text changes. `make display-audit` on real scenes stays `failures=0`.
- No change to production UI, `record_context`, the top-level `Makefile` or `ci.yml`.
- No new "valid" rows. Every new fixture is a rejection control.

## Design

1. **`tests/display_audit.gd` line 159:** change the presence rule's reason from `"context-source %s client.map.distance_ly"` to `"context-presence %s client.map.distance_ly"`. The source rule (line 153) keeps `context-source`.
2. **Three new fixtures** in `tests/fixtures/display_audit/`. Each is one NDJSON row, in the shape of the existing `context_*.ndjson`. Each is otherwise valid: the text rebuilds from the context, and every part is present.
   - **`context_absent.ndjson`** kills M5. View `{"tick":10}`. One binding, `field clock.year`, parts `["year ",["clock.year","%d"]]`, text `year 2101`, context `{"clock":{"year":2101}}`. `clock` is not in the frame, so line 152 is the only rule that can fire. Expected: `FAIL context-drift clock.year clock.year`.
   - **`context_presence_parts.ndjson`** kills M6. View target `{"index":2,"id":"CNS5:3627"}`, the same as `context_presence`. The context carries the *correct* `distance_ly`, `4.32103979249451`: that is the exact `stars.json` text for `stars[2].dist_ly`, so the source rule passes. The `parts` omit it (`[["client.map.target_id","%s"]," · distance unavailable",["client.map.empty","text"]]`), with text `CNS5:3627 · distance unavailable`. Only the `parts_read` half of line 159 can fire. Expected: `FAIL context-presence client.map.target_id client.map.distance_ly`.
   - **`context_crew.ndjson`** kills M10. View `crew.members` has two members, one with `work.status` `working` and one `resting`, and no holds. The binding mirrors `ship_consoles.gd:773`: parts `["Crew console\n",["client.crew.working","%d"]," working"]`, text `Crew console\n2 working`, context `{"client":{"crew":{"working":2,"status":"","empty":""}}}`. `status` and `empty` are correct, so `working` (2 against 1) is the only finding. Expected: `FAIL context-source client.crew.working client.crew.working`. Under M10 the same fixture fails `context-unknown` instead, and the reason grep catches it.
3. **`mk/m45.mk` `display-audit-controls` spec loop:**
   - Change the `'context_presence empty_known.json context-source'` row to `context-presence`.
   - Add three rows: `'context_absent empty_known.json context-drift'`, `'context_presence_parts empty_known.json context-presence'` and `'context_crew empty_known.json context-source'`.
   - Name the fixture when the reason is wrong: `grep -E "^FAIL $$reason([ :]|$$)" <log> || { echo "display control $$case/$$known wrong reason (want $$reason)"; exit 1; }`. An accepted fixture already prints `display control <case>/<known> missed`.

The other 14 rows and their reasons are unchanged.

## Acceptance criteria

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

## Sub-milestones and estimates

One step, test-first. Add the fixtures and spec rows first: red, because `context_presence` and `context_presence_parts` print `context-source`. Then rename the reason: green. Then run AC2–AC8. That is about 12 LOC; the controls take about a minute and the scene run about 4 minutes.

## Risks and mitigations

- **The `dist_ly` literal drifts if `stars.json` is regenerated.** Then `context_presence_parts` also fails the source rule (`context-source`), so the grep for `context-presence` still passes, but M6 would no longer be isolated. Mitigation: the fixture uses the exact JSON text. AC3 re-proves the isolation, and `data/starmap` is pinned by `starmap-assets`.
- **The wrong-reason echo changes how the loop exits.** It still exits 1, and the only change is the message. M7 (hold_s) gets the same named failure for free.

## Open questions

None.

## Deliverables

- `tests/display_audit.gd`: 1 line (the presence reason).
- `tests/fixtures/display_audit/`: `context_absent.ndjson`, `context_presence_parts.ndjson` and `context_crew.ndjson` (new).
- `mk/m45.mk`: 1 edited spec row, 3 new rows, and the wrong-reason echo.
- On landing, the row 7i(j) status goes in the charter queue and a changelog fragment is added.

## Verification log (designer, 2026-10-16, `e40d418`)

- **Dry runs** on a temp copy (`.godot/tmp/i34/fixed.gd`, the presence reason renamed). For each `<PERL>` above I ran `perl -i -pe` on its own copy, then `diff fixed.gd M.gd`. Each diff was non-empty and exactly one line:
  - M5: line 152, `check(false,` → `check(true,`.
  - M6: line 159, now `check(carried == expected, "context-presence …")`.
  - M10: line 31, `CONTEXT_SOURCED` without `"client.crew.working", `.
  - M8: line 151, `check(recorded == frame,` → `check(true,`.
  - The rename itself: line 159 only.
- **The fixture matrix** (godot headless, `control` mode):
  - The tree as it stands rejects all three new fixtures (`context-drift`, `context-source`, `context-source`). The new fixtures cover the gap; they do not expose a bug.
  - The fixed variant rejects them with `context-drift`, `context-presence` and `context-source`, and `context_presence` now prints `context-presence`.
  - M5 accepts `context_absent` (`failures=0`), M6 accepts `context_presence_parts` (`failures=0`), and M10 turns `context_crew` into `context-unknown`. Each mutant leaves the other fixtures' reasons as they were.
  - M8 accepts `context_drift`, the positive control.
- **Not yet run:** the full `make display-audit-controls` with the new spec rows, and the scene run (AC1 and AC7). Both need the in-tree change; the executor runs them.
