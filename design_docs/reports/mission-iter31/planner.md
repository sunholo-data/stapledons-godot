# Iteration 31 sprint-planner gate assessment

Role: planner. Requested effective lane: codex:gpt-6.1-sol; resolver `recipe codex:gpt-6.1-sol declared:planner-lane-default-pin`; native sub-agent transport per operator. Read-only gate assessment, not a sprint plan, approval, execution or quorum artifact. No tracked edits or external mutations performed.

## Verdict

**A small, proven, semantics-preserving repair of R2-CREW C4/C8 is already authorized. A timing-budget or measurement-contract amendment is not. Current evidence supports bounded diagnosis, not a specific optimization or an automatic threshold change.** Do not manufacture a formal sprint merely because CI is red. If diagnosis identifies only a runner/environment difference and no covered repair, retain the red and park with evidence; new acceptance criteria require a concrete design/plan amendment and Mark's approval before implementation.

## Authority and dependencies

Read CLAUDE.md, charter Guardrails and attended loop triage, `/Users/voightkampff/.claude/skills/sprint-planner/SKILL.md` (repo skill absent; user symlink resolves to the AILANG skill), existing design, sprint and JSON. CLAUDE.md requires design → sprint → **stop for approval** → execute → independent evaluate, with local and matching CI `make test` green. Sprint-planner requires concrete milestones, registry reuse decisions and syntax gate before a new .ail plan handoff; its generic AILANG-repo executor-test advice does not override this game's CLAUDE.md.

* Design `design_docs/implemented/r2/crew-integration.md:194`: AC11 = ten-year crew interlude **under 2 s**, headless.
* Sprint `design_docs/implemented/r2/crew-integration-sprint.md`: approved revision 1, D-72, 2026-10-13. C4 includes performance/AC11 and C8 includes auto-run, holds, exact idle batching and `make crew-perf`. Its Q1 explicitly chooses the fast path instead of relaxing AC11.
* `.ailang/state/sprints/sprint_R2-CREW.json`: `approved=true`, `status=completed`, C4 and C8 `passes=true`; the sole sprint JSON matching crew-perf. This records historic completion, not current CI green or permission to alter AC11.
* D-70 retains ship-day turns and consent/orders semantics. D-76 requires monthly long-skip check-ins and daily near stars. Neither relaxes the under-2-second requirement.
* Mission gate-3 route says an existing plan routes to executor; gate-3b says small reds may be fixed forward. Charter permits specified headless hygiene. These support narrow repair under the existing approval, not novel product scope.
* Package work belongs upstream, never in runtime/cache. New unrelated package publish requires Mark under current attended triage; any package-release gate must be checked explicitly before treating the game plan as publish permission. Population/cohort implementation and new UI remain distinct scope.
* Read designer assessment `/tmp/stapledon-iter31-designer.md` once it appeared. It independently reaches the same repair/amendment distinction. No new design quorum artifact was observed for this repair proposal; therefore this document creates no formal new plan or handoff.

## Evidence checked

`git rev-parse origin/main` = `d4fa1b9e4c6418f41157675f16c1040e8b3a44b4` at assessment. That merge #241 changes only archive-npc.md; its parent is merge #240 (`3983bcf`). A docs-only newest merge does not identify the cause of timing failure.

All six named local log artifacts were inspected with literal `crew-perf` matches:

| CI run | critical_only | unheld | observed verdict |
|---|---:|---:|---|
| 38618727888 | 0.99 s | 2.04 s | FAIL, budget 2 s |
| 38618715433 | 0.97 s | 2.06 s | FAIL, budget 2 s |
| 38606219597 | 0.96 s | 2.02 s | FAIL, budget 2 s |
| 38606513269 | 0.97 s | 2.05 s | FAIL, budget 2 s |
| 38604097509 | 0.97 s | 2.09 s | FAIL, budget 2 s |
| 38618681277 | 0.62 s | 1.27 s | crew-perf passed; whole-run green is not inferred |

Each unheld output reports `days 3652 holds 0`; each critical_only reports `days 3652 holds 1`. Latest Makefile:74–79 warms each entry with args 1, then wall-times a complete args-10 strict-VM process; rounds elapsed time to 2 decimals and requires strict `<2.0`. These are acceptance failures, not demonstrated wrong-state outputs. Local artifact `/tmp/stapledon-iter31-local-perf.log` reports 0.75/1.16 s with rc=0; designer independently reports 0.71/1.15 s. Neither macOS sample certifies Linux CI.

The original C8's 0.89 s historical worst case used crew_core 0.3.0; current dependencies are 0.4.0, so the historic number alone cannot establish a runner flake. A narrow exact-match log search avoids mistaking intentional negative-control FAIL lines elsewhere in CI for unrelated suite failures.

Rule 3m (`mission-control/resources/verification-protocol.md:1262`) requires stating fixed axes and testing the causal axis. Its derived-ratio bound rule is for a bound/stimulus relationship; it does not authorize replacing AC11's absolute user-facing performance requirement with a machine-relative threshold.

## Minimal next scope

1. Preserve AC11, both benchmark cases, ten years/3652 days, D-76 cadence, strict VM, AI_LIVE clearing, default seed/pack and current warm-cache meaning. Gather bounded same-SHA Linux samples and retain every rc/time, plus same-runner pinned known-green baseline. Record runner class, concurrency/CPU load, memory pressure, cache state, runtime/package pins and timing precision. No best-of retries or discarded failures.
2. Name a demonstrated hotspot and exact C4/C8 repair seam before executor routing. If a small game-side optimization preserves semantics, use an isolated worktree and a bounded executor; estimate one focused milestone (roughly 20–100 implementation/evidence LOC, contingent on diagnosis), not a fabricated multi-day feature plan. No actual sprint artifacts were created here.
3. Check changed-path evidence: full session/archive/RNG/hold equivalence against previous behavior over month/day boundaries, active work/yields and events; targeted mutation or reverted optimization must make the claimed regression evidence fail. Existing plainDays comparison alone is insufficient for replacing advanceAuto.
4. Validate unchanged `make crew-perf AILANG=runtime/bin/ailang`, crew hold tests, `make crew-parity strict replay parity-v2 AILANG=runtime/bin/ailang`, then game-required full local `make test` and exact-head CI. Independent evaluator must differ from executor. Changes to formulas/visuals would add physics/render gates and leave this minimal scope.
5. If the proposal raises 2 s, changes the timing envelope, adds warm-ups/retries/subtraction, reduces work/cadence, alters holds or implements cohorts, create a new concrete amendment with acceptance commands, reuse/syntax gates and design quorum; **stop for Mark approval**. Do not resolve a ledger decision unattended.

## Machine-checkable resume predicates

These predicates are conjunctions; no single local green makes CI healthy.

* `git rev-parse origin/main` equals recorded SHA. If different, repeat attribution against the new full SHA before routing.
* Existing-plan repair route: `jq -e '.approved == true and ([.features[] | select(.id == "C4_CREW_ON_PERF_GOLDENS" or .id == "C8_AUTO_RUN_HOLDS")] | length == 2)' .ailang/state/sprints/sprint_R2-CREW.json` succeeds, approved AC11/D-76 are unchanged, diagnosis artifact identifies a small exact seam with same-runner data, and required native executor/evaluator spawns return actual independent deliverables. Quorum at pick must be checked by the controller before new/revised design routing.
* Amendment route: approved revision exists in tracked design + plan + sprint JSON, approval provenance explicitly names the new budget/measurement/cadence contract, design quorum admits that revision, and no open design question blocks it. A proposed document or D-76 alone fails this predicate.
* Current-red clearance: query `gh run view 38618727888 --repo sunholo-data/stapledons-godot --json headSha,status,conclusion,attempt`; require `headSha` = recorded SHA, `status=completed`, `conclusion=success`, retaining attempt. If fixed on a later SHA, select and record that exact SHA/run/attempt instead and require the same fields. The original failure remains failure until an observed newer completed attempt/run supersedes it.
* Benchmark evidence: unchanged target rc=0; two named entries observed, critical_only 3652 days with hold behavior preserved, unheld **exactly 3652 days/0 holds**, both strict `<2 s`; raw sample records present and no failures discarded. Do not rely on the current permissive output regex to prove zero holds in the unheld case.
* Landing: evaluator score >=70 with no blocking findings; required local gates succeed; exact proposed/merged SHA's matching CI completed success. An untracked report, stale sprint `passes=true`, docs-only diff, timeout or partial green cannot satisfy landing.

Assessment outcome: existing repair authorization confirmed, no demonstrated repair selected; no timing amendment approved. Controller can continue bounded diagnosis, or park the red with these predicates when no covered repair is established.
