# Implementation design docs

**How** each roadmap milestone is built. **What** the game is lives in
[stapledons-design](https://github.com/sunholo-data/stapledons-design). Link to
it; don't copy it.

```
design_docs/
  planned/<release>/<id>.md          design doc (status: Planned)
  planned/<release>/<id>-sprint.md   sprint plan (sprint-planner), approved before execution
  implemented/<release>/<id>.md      moved here when the sprint passes evaluation
  implemented/<release>/<id>-report.md  what shipped: measurements, renders, upstream reports
  stapledon-mission.md               R1 mission charter (DRAFT, not ratified, not armed)
  stapledon-mission-log.md           append-only mission log
.ailang/state/sprints/sprint_<id>.json          sprint progress (sprint-executor)
.ailang/state/evaluations/eval_<id>_round_<n>.json  evaluation (sprint-evaluator)
```

## Design doc format

1. **Header:**
   - Status, release and milestone.
   - Priority.
   - **Implements** (links to design-repo feature docs and physics-spec
     sections).
   - Depends on.
   - Estimated LOC.
2. **Game vision alignment:** the pillar table (the `game-vision-designer`
   skill), with a net score and a go/no-go.
3. **Problem:** what's wrong or missing today, with evidence.
4. **Goals and non-goals.**
5. **Design,** by sub-milestone. Physics goes into `sunholo/relativity`
   first.
6. **Acceptance criteria:** a table, where every row names the command that
   checks it. The evaluator scores these.
7. **Sub-milestones and estimates:** LOC, dependencies, order.
8. **Risks and mitigations.**
9. **Open questions for the user:** decisions the loop must not make alone.
10. **Deliverables.**

## Index

| Doc | Status |
|---|---|
| [r1/m1-relativistic-sky.md](planned/r1/m1-relativistic-sky.md) | Planned: awaiting sprint plan |
| [r1/m1.2b-wd-photometry.md](implemented/r1/m1.2b-wd-photometry.md) | Implemented 2026-10-01: `sunholo/relativity` 0.3.0 published (WD-1/2, iteration 5); game pin, `checkWDPackage` and strict-VM `make wd-vm` (WD-3, PR #12, iteration 6) |
| [r1/m2-journey-core.md](implemented/r1/m2-journey-core.md) | Implemented 2026-10-02: sprint `R1-M2-JOURNEY` ([plan](implemented/r1/m2-journey-core-sprint.md)), 10 milestones, PRs #22–#35 and #37, evaluations 89–96/100; `sunholo/relativity` 0.4.0, protocol v2, planner + commit rule, autopilot, SplitMix64, replay harness with 10k-tick parity, galaxy map with commit dialog; bar clause 2 met. Report: [r1/m2-report.md](implemented/r1/m2-report.md) |
| [r1/m3-black-holes.md](planned/r1/m3-black-holes.md) | Planned 2026-10-01: OQ1–4 resolved (D-13; demo hole Sgr A*); new OQ5 (Galactic-Centre sky) has a default; ready for sprint plan |
| [r1/m4-first-journey.md](planned/r1/m4-first-journey.md) | Planned 2026-10-01: OQ1–7 resolved (D-12, D-14); new NQ1/NQ3 have defaults; Track B waits on art stop S2; depends on M2 |
