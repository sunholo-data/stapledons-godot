# Playable game completion tracker

Updated 2026-11-17. Owner: Mark; coordinator: Codex. Scope: finish the existing ship, make content addition repeatable, and prove a complete voyage.

## Authorization and baseline

Mark requested an audit first, then authorized tracking documents and Sol sub-agents. Three `gpt-6.1-sol` agents are preparing bounded implementation designs. Feature execution awaits review of concrete sprint plans under CLAUDE.md; this authorization does not imply publication or visual acceptance.

Audit checkout: `f3aa83bf4120fb6f57d858129dd9bada59ed91b4`, with substantial pre-existing uncommitted art and planning work. Combined painted candidate checkout: `../stapledons-godot-painted-levels`, commit `19e4a76338cb72e88e73a22790239691a72ab439`. Neither is asserted to be current remote main. Remote PR inspection failed during the initial audit; reconcile remote state before execution.

## Workstreams

| Priority | Strand and plan | Owner | Current state | Completion evidence |
|---|---|---|---|---|
| 1 | [Ship finish and laptop performance](../planned/r2/playable-ship-finish.md) · [Sprint](../planned/r2/playable-ship-finish-sprint.md) | Sol: ship_finish_plan | Proposed; awaiting approval | One combined native build; captain scope explicit; both decks playable; laptop baseline and measured improvements; Mark's acceptance |
| 2 | [Content pipeline consolidation](../planned/r2/content-pipeline-consolidation.md) · [Sprint](../planned/r2/content-pipeline-consolidation-sprint.md) | Sol: asset_pipeline_plan | Proposed; awaiting approval | Existing contracts consolidated; a further asset reaches the packaged game through reusable validation and installation |
| 3 | [Playable voyage acceptance](../planned/r1/playable-voyage-acceptance.md) · [Sprint](../planned/r1/playable-voyage-acceptance-sprint.md) | Sol: playable_voyage_plan | Proposed; awaiting approval | Existing deterministic journey checks and recorded human review of planning, commitment, transit, arrival and consequences |

Each sprint has a matching JSON tracker under `.ailang/state/sprints/`, named `sprint_PLAYABLE-SHIP-FINISH.json`, `sprint_CONTENT-PIPELINE-CONSOLIDATION.json` and `sprint_PLAYABLE-VOYAGE-ACCEPTANCE.json`. All feature results remain null. JSON parsing and whitespace checks passed during planning; runtime tests were not run.

### Recommended first execution batch

Approve SF0–SF1b (production readiness and local-only benchmark evidence), CP1–CP3 (bounded catalog/validation fixture), and PV1–PV3 (complete-voyage harness), with ship-owned SF0 preceding voyage PV1. Native review SF2/PV4 follows when the candidate and laptop are available. These slices prepare trustworthy evidence; performance repairs will follow measured bottlenecks rather than an assumed optimisation.

Ship owns proposed `demos/ship_review_readiness.gd`; voyage consumes it. Content owns new contract helpers/catalog and coordinates shared staging/Makefile edits. Use isolated execution checkouts and reconcile the candidate before integration.

### Audit findings to preserve

- Existing standalone ship benchmarks bypass normal-entry painted installation.
- The normal-entry voyage harness waits one frame; the candidate's painted installation waits for civic readiness and physics frames. This is a source-level race risk, not a reproduced failure.
- Historical voyage proxy uses 3.5 m/s while current walking is 2.2 m/s; preserve the historical contract and record real human timing separately.
- A later content-agent read-only remote inventory succeeded (game PRs #435, #380, #373; canon #49); refresh before execution. Earlier failure logs remain accurate for those attempts.

## Dependencies and integration

1. Identify the exact combined candidate and compare with the installed app and remote main.
2. Review the native ship and collect laptop performance evidence; select fixes from measurements.
3. Consolidate content contracts alongside ship completion; avoid competing edits to the ship orchestrator.
4. Run the complete voyage in the accepted combined candidate and address observed interaction/pacing gaps.

Designs extend the existing captain, view-finish and first-journey plans; they do not declare those sprints complete or replace their evidence. The 3D captain stays parked. No new physics, destinations, or save/undo mechanics are proposed.

## Evidence rules

- Distinguish authoring checks, runtime integration, packaged smoke, native visual acceptance and actual delivery.
- Record commit, build hash, command, environment and date with each result.
- Performance results identify hardware, resolution, renderer, workload, percentiles and memory. Rig measurements do not certify laptop performance.
- CPU material studies do not certify native lighting or frame cost.
- Preserve historical decisions with their checkout context: prototype decision numbering differs between the authoring and combined candidate notes.
- Apply current CLAUDE.md gates rather than obsolete full-suite requirements copied into older sprint text.

## Next review

Review the three designs and proposed sprint plans together, resolving shared ownership and targeted checks. The sprint-planner skill was located in the sibling AILANG repository at `.agents/skills/sprint-planner/SKILL.md`; agents use it to prepare unapproved plans and progress JSON. Do not treat these designs as approved executable sprints. Cross-family evaluation remains required after implementation; another Sol agent alone does not satisfy that requirement.

## Deferred until evidence or an explicit decision

- Laptop target/settings: propose after identifying hardware and measuring the candidate.
- Newer directional captain frames and older-age coverage: classify required versus deferred for the selected voyage.
- Broader art generation, 3D character revival and unrelated feature expansion.
- Publication and merge: separate from preparing and validating a candidate.
