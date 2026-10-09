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
| [r1/m3-black-holes.md](implemented/r1/m3-black-holes.md) | Planned 2026-10-01: OQ1–4 resolved (D-13; demo hole Sgr A*); new OQ5 (Galactic-Centre sky) has a default; ready for sprint plan |
| [r1/m4-first-journey.md](planned/r1/m4-first-journey.md) | Planned 2026-10-01: OQ1–7 resolved (D-12, D-14); new NQ1/NQ3 have defaults; Track B waits on art stop S2; depends on M2 |
| [r1/sky-frame-d28.md](implemented/r1/sky-frame-d28.md) | Implemented 2026-10-03 (D-28, PR `fix/sky-mirror`, awaiting Mark's render review): one right-handed galactic → world map (`SkyFrame`), the M1 sky un-mirrored, the interior flip removed, starboard = l 270 |
| [r1/m5-planets.md](planned/r1/m5-planets.md) | **Approved** 2026-10-03 (Mark, attended; D-26, queue row 6c): flyby player-facing, new package `sunholo/celestial`, 2k textures, light confirm for short in-system legs; awaiting sprint plan |
| [r1/m4-real-time-tour.md](planned/r1/m4-real-time-tour.md) | **Approved** 2026-10-06 (Mark, attended; D-39 to D-41): real-time voyage Earth → Aldebaran with cruise interludes ([sprint A](planned/r1/m4-real-time-tour-sprint.md)); TRAPPIST-1 stop ([sprint B](planned/r1/m5-trappist1-sprint.md)) |
| [r1/m4-ship-geometry-demo.md](planned/r1/m4-ship-geometry-demo.md) | Approved, implementation in progress: correct bridge overlook, whole-ship pullback and one-tier lift; [sprint](planned/r1/m4-ship-geometry-demo-sprint.md) |
| [r1/title-screen.md](planned/r1/title-screen.md) | Implemented on `feat/title-screen` 2026-10-08 (charter queue row 5b): title screen and launch menu; awaiting review |
| [r1/lightspeed-loading.md](planned/r1/lightspeed-loading.md) | Implemented on `feat/lightspeed-loading` 2026-10-08 (Mark's request): the title routes load behind a jump to 0.99999c on the real sky, with real progress and worker-thread prefetch; awaiting review |
| [r1/ship-ui-hud-consoles.md](planned/r1/ship-ui-hud-consoles.md) | Planned 2026-10-08 (D-56): HUD informs (clocks and distance always), bridge consoles decide, no twitch; [sprint R1-SHIP-UI](planned/r1/ship-ui-hud-consoles-sprint.md) awaiting Mark's approval and Q1–Q6 |
| [r1/ism-structure-and-dust.md](planned/r1/ism-structure-and-dust.md) | Planned 2026-10-09 (D-60): the real interstellar medium (Local Interstellar Cloud, the 15 local clouds, the Local Leo Cold Cloud, the hot Local Bubble, Edenhofer 2024 clouds) drives glow, drag and wall load; dust-grain impact flashes; [sprint R1-ISM-DUST](planned/r1/ism-structure-and-dust-sprint.md) awaiting Mark's approval and Q1–Q7 |
