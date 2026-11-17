# Sprint plan: PLAYABLE-VOYAGE-ACCEPTANCE

## Execution checkpoint — 2026-11-17

- [x] Approval: Mark authorized PV1–PV3; integration baseline refreshed through `ec415f33` (main `ae5394dd`), shared SF0 `7cde56f5` consumed without duplicating readiness.
- [x] PV2 endpoint contract: unit 14/0; complete route 143640/0; display audit 259146 checks, zero failures/new findings; six bounded rejection controls pass.
- [ ] PV1 final compatibility gate: installed identity and the complete route are verified; 20 compatibility targets pass, with the historical-cache-only `ship-console-test` retry retained by parent.
- [ ] PV3 final combined qualification: executor evidence is in [the report](playable-voyage-acceptance-report.md). Strict, M4 parity and frozen scene replay pass. Parent owns the remaining console retry, combined CI/runtime-path reconciliation, fresh recording comparison and final independent-review conditions.
- [ ] PV4 attended human voyage/native appearance/sound/performance acceptance remains pending and is not claimed.

TDD witnesses: the first contract test failed because the observer was absent; after implementation it passes14/0. Before endpoint integration, the old real-scene driver accepted the route missing home news (143079/0,111s). The new driver rejects that omission for `completion missing home news`, and the other omissions for their declared reasons. The historical synthetic timing divisor and frozen scene input/golden remain unchanged.

Sidecar slot was released after the existing frozen replay passed. No further tests are launched by this strand. Parent reports SF1b live route 18/0 in 24 s and combined `ci-fast` running; neither is substituted for a final pinned parent witness. PV4 remains pending.

**Status:** Executing approved PV1–PV3, Mark attended 2026-11-17: “approved lets go”. PV4 human review remains pending. Headless implementation/checks and scoped commits are authorized; no GPU work, build or publication.
**Design:** [playable-voyage-acceptance.md](playable-voyage-acceptance.md).
**Progress:** `.ailang/state/sprints/sprint_PLAYABLE-VOYAGE-ACCEPTANCE.json`.
**Scope:** qualify one existing Sol → alpha Cen A → Sol trip in the reconciled combined painted ship, including home news and log. No new gameplay or campaign ending.
**Duration:** ~4–6 engineering hours in four small packages, plus actual command runtimes and review scheduling. No calendar completion commitment.
**Risk:** medium: shared startup dependency and native human evidence remain outstanding.

## Current status analysis

The audit pins authoring `f3aa83bf4120fb6f57d858129dd9bada59ed91b4` (dirty), painted candidate `19e4a76338cb72e88e73a22790239691a72ab439` (clean), candidate's local main/base `36f4ab4c4044f2d57f1b532cf298ca21c29346c5`, and canon `c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa`. This is a local snapshot; remote PR/main status could not be fetched. The implementation baseline must be reconciled/refreshed by the combined ship owner before execution.

Already implemented by source inspection: normal New game, consoles, irreversible commitment, outbound/return sim flow, news, log, display audits and replay tools. The clean candidate installs both painted decks/NPCs normally. These observations are **not newly passed tests**. No command in the design's acceptance table was executed during planning.

Remaining work: make the journey harness wait for the shared combined readiness contract; add a complete-voyage fixture with explicit endpoint evidence; qualify that combination and report it; optionally record the newly recommended human product review.

Recent git/CHANGELOG work includes small guard fixes, merges and ledger changes. No reliable elapsed effort sample supports a comparable LOC/day velocity. `target_loc_per_day` is null deliberately. Estimates below are bounded task budgets with contingency, not fabricated historical throughput. No coverage percentage is promised; successful positive flow plus three meaningful endpoint negative controls are the test objective.

## Rulings and approval boundaries

- D-14 already replaces R1's human study with the scripted proxy and defers three new players to R2. It is a ruling, not an open gate.
- D-138 already sets current walking pace to 2.2 m/s. The historical auditor still uses 3.5 m/s; preserve its declared synthetic model here, do not silently change gameplay/auditor thresholds.
- The attended 2026-11-13 paint/playable request is D-165 in the dirty authoring ledger and D-158 at candidate `19e4a763`. Refer to the words/date and pins until tracker reconciliation; never infer acceptance from the label alone.
- Ship-finish owns shared readiness, complete painted integration, current-main combination, packaging and native art/performance acceptance. This sprint consumes its exact candidate/evidence.
- Current no-local-GPU restriction applies. This plan adds no GPU, build or publishing authorization.

Implementation gate **OQ1 is resolved** by Mark's attended approval of PV1–PV3; see [design §Open questions for Mark, question 1](playable-voyage-acceptance.md#open-questions-for-mark). Integration baseline `ec415f33` plus shared SF0 supplies the combined source. OQ2 is the newly proposed human owner review, not an old R1 requirement.

Before approval: **STOP: report `BLOCKED: OQ1 sprint approval` and end the run; do not execute.** After approval, if the shared candidate/readiness dependency is unavailable, **STOP: commit only owned task work if any, report `BLOCKED: combined ship readiness dependency`, and end the run.** If OQ2 is unanswered at PV4, **STOP: commit only owned completed work, report `BLOCKED: OQ2 human product review decision`, and end the run.** These are terminal gates, not open-ended polling. This planning task does not itself commit anything.

## Registry reuse audit

| Package | Decision | Searches / reason |
|---|---|---|
| PV1 | none | Test startup orchestration and provenance only. Reuse the ship plan's shared `ShipReviewReadiness.wait(demo, timeout_ms)`; no new package-like capability, no registry query needed. |
| PV2 | none | Reuse repository JSON playthrough driver, console API and session evidence. Completion assertions are game-specific tests, not new maths or library behavior; no registry query needed. |
| PV3 | none | Invoke existing make/replay/display tools and record evidence; no new package capability or dependency change. |
| PV4 | none | Human checklist and verdict record only; no executable package capability. |

No `.ail` file is created or edited. The planner's AILANG syntax/showcase gate is therefore inapplicable. Existing `.ail` tools are run through pinned v0.56.1; package-first and pure-core requirements remain intact. The generic AILANG planner's `make test-changed`/`make test-core` commands are not this game's commands; CLAUDE.md and the actual Makefile determine the targeted gates here.

## Proposed milestones

### PV1: reconcile candidate and consume shared readiness

**Budget:** 40 test/harness lines + 20 manifest/report lines = 60; 60–90 min including contingency. **Dependency:** ship strand's proposed helper and reconciled candidate.

Files: `tests/m4_playthrough_ship.gd` (consume readiness, no startup duplication), companion `.uid` only if a new script is necessary, `art/playable-voyage-review/evidence.json` (new provenance record).

Tasks:

1. Refresh current main/PR overlap through the combined owner; record exact source/base hashes and clean status. Preserve dirty authoring work.
2. After title New game, await proposed `ShipReviewReadiness.wait(demo, timeout_ms)` and require `{ok:true}` before disabling processes/sampling. Main owns actual civic/two-physics-frame initialization.
3. Record installation identity, runtime/script/lock/painted manifest hashes and intended checks. Missing readiness fails explicitly and within the existing outer script deadline.

Validation: design AC1 and AC8 targeted checks on the selected pin. An unfinished helper is a dependency stop, not permission to disable painting or restore the one-frame assumption. A real implementation failure becomes a bounded fix proposal rather than a workaround hidden in the test.

### PV2: complete-voyage fixture and endpoint checks

**Budget:** 55 harness/completion lines + 35 fixture lines + 60 negative/control lines = 150; 60–90 min coding plus bounded run duration. **Dependency:** PV1.

Files: new `tests/playthrough_complete_voyage.json`; `tests/m4_playthrough_ship.gd`, or new small `tests/playthrough_completion.gd` + `.uid` for completion accumulation; `tests/test_playthrough.sh`; three named fixtures under `tests/fixtures/playthrough/`.

Tasks:

1. Duplicate the existing route's actions into the explicitly named new fixture, adding home news before the final log. Do not alter historical min fixture or scene golden.
2. Record read location/tick and assert exactly two commits, outbound/home arrivals, boost/cruise/brake on both legs, destination news then home news then home log, final Sol/rest with no active committed leg.
3. Add missing-return, missing-home-news and missing-log controls. Each must fail with its explicit completion reason; parser errors/timeouts do not count.

Validation: design AC3–AC5; existing `make playthrough-negative` remains green after it proves all declared controls. Preserve the script gate's exit/status/deadline rules. The new fixture is the working example; no new gameplay demo or provider key is required.

### PV3: qualify one pin and publish a report to the repository

**Budget:** 60 manifest/report lines; 60–90 min preparation plus measured command durations. **Dependency:** PV2 and shared ship checks.

Files: `art/playable-voyage-review/evidence.json`, `design_docs/implemented/r1/playable-voyage-acceptance-report.md` at eventual landing; task logs go under `.godot/tmp/playthrough/` and are linked/archived with hashes. No landing file is written during this planning task.

Run design AC1–AC9 with pinned runtime, separate minimal and complete outputs. Report each check as passed, failed or not run; no blanket pass inferred from another clone. Existing `replay-scene` proves its pinned historical session; replay the newly recorded complete session separately without recording a new golden. Run crew/comms/review/stub/digits checks to protect the already combined features.

Retain source/base/script/runtime/lock/assets and log hashes, command, platform, result and any accepted limitation. Independent cross-family evaluator checks the completion contract, controls and evidence before landing. Main's nightly full-suite result is linked separately; it is not triggered here. Runtime blockers stop qualification with a reproduction and a separate proposed fix scope. Do not weaken checks, silently alter known-findings, change physics or regenerate goldens to finish the report.

### PV4: attended product-review disposition

**Budget:** 40 checklist/report lines; 30–45 min session plus scheduling. **Dependency:** PV3; ship owner's review artifact; OQ2 answered.

Files: the existing evidence manifest/report, with reviewer/build/date/display/input, beats completed, intervention and defect list, observed elapsed time and separate voyage/native-art/sound/performance verdicts.

Use normal controls from New game through home news/log, then a Commons/lift round trip and access to Crew/comms. Design AC10 records the explicit outcome. No stopwatch pass threshold is introduced. If review is declined, record `not_requested`; technical completion may be reported but human acceptance remains unclaimed. A three-new-player study remains its own R2 work.

## Suggested execution sequence

| Session | Work | Exit artifact |
|---|---|---|
| First approved session | PV1; begin PV2 only when ready seam is landed | Reconciled pin/readiness witness; owned changes only |
| Next bounded session | PV2 + positive/negative runs | Working new fixture and explicit rejected incomplete routes |
| Qualification session(s) | PV3 check groups, one at a time; preserve completed evidence between runs | Exact logs/manifest and independent evaluation |
| Attended review slot | PV4, only if adopted | Human disposition at exact artifact hash |

No claimed day-by-day delivery date: external combined integration, command runtime and Mark's availability determine the calendar. Each coding package stays within 60–90 min; if it overruns or needs product changes, stop and re-scope.

## Validation commands

Use the exact commands in design AC1–AC10. Most important new positive flow, after PV2 exists:

```sh
export PATH="$PWD/runtime/bin:$PATH"
export AILANG_BIN="$PWD/runtime/bin/ailang"
env -u AI_LIVE make playthrough AI=none SCRIPT=tests/playthrough_complete_voyage.json PLAYTHROUGH_OUT=.godot/tmp/playthrough/voyage-complete
make display-audit DISPLAY_SAMPLES=.godot/tmp/playthrough/voyage-complete/display_samples.ndjson
make playthrough-negative
```

For the newly recorded complete session, use the design's AC6 direct VM/interpreter producer/`cmp` block. `make replay SESSION=...` also requires a frozen golden, so it is deliberately not the new-session parity command. Keep `make replay-scene` for the existing pinned historical recording.

These are proposed execution commands, **not a planning-run transcript**. Existing targets may take longer than one coding package; record actual time and pending portions rather than claiming an unrun suite. No GPU command appears in this sprint. Current ship-plan native acceptance evidence is linked, not replaced by a headless result.

## Success and handoff

Success: implemented completion fixture; same-pin checks and meaningful negative controls pass; frozen replay unchanged; evidence levels explicit; human outcome recorded accurately if adopted. All four `passes` fields begin null; approval begins false. PV4 may be marked technically complete with `not_requested` only after an explicit OQ2 decline, never from silence.

This plan remains in `planned/` through independent evaluation. Mark has approved execution of PV1–PV3; do not send an external handoff, tag, build or publish as a side effect. Parent-owned tracker links design, sprint and JSON. The normal project execute/evaluate/landing cycle applies, with PV4 left pending.
