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
  stapledon-mission.md               R1 mission charter (ratified D-1; armed, see live loop status)
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
| [r1/m1-relativistic-sky.md](planned/r1/m1-relativistic-sky.md) | Partly landed (PRs #16 to #89, #145/#147); remaining: M1.5b (AC9 renders, m1-report, landing) |
| [r1/m1.2b-wd-photometry.md](implemented/r1/m1.2b-wd-photometry.md) | Implemented 2026-10-01: `sunholo/relativity` 0.3.0 published (WD-1/2, iteration 5); game pin, `checkWDPackage` and strict-VM `make wd-vm` (WD-3, PR #12, iteration 6) |
| [r1/m2-journey-core.md](implemented/r1/m2-journey-core.md) | Implemented 2026-10-02: sprint `R1-M2-JOURNEY` ([plan](implemented/r1/m2-journey-core-sprint.md)), 10 milestones, PRs #22–#35 and #37, evaluations 89–96/100; `sunholo/relativity` 0.4.0, protocol v2, planner + commit rule, autopilot, SplitMix64, replay harness with 10k-tick parity, galaxy map with commit dialog; bar clause 2 met. Report: [r1/m2-report.md](implemented/r1/m2-report.md) |
| [r1/m3-black-holes.md](implemented/r1/m3-black-holes.md) | Planned 2026-10-01: OQ1–4 resolved (D-13; demo hole Sgr A*); new OQ5 (Galactic-Centre sky) has a default; ready for sprint plan |
| [r1/m4-first-journey.md](planned/r1/m4-first-journey.md) | Partly landed (sprint `R1-M4-JOURNEY`, PRs #92 to #235); remaining: M4.5 AC4 (D-77/D-78), the M4.6 gated half, queue rows 7h/7i |
| [r1/sky-frame-d28.md](implemented/r1/sky-frame-d28.md) | Implemented 2026-10-03 (D-28, PR `fix/sky-mirror`, awaiting Mark's render review): one right-handed galactic → world map (`SkyFrame`), the M1 sky un-mirrored, the interior flip removed, starboard = l 270 |
| [r1/m5-planets.md](planned/r1/m5-planets.md) | Partly landed (7/15: M5.0–M5.2a, M5.5a); remaining: M5.2b, M5.3, M5.4, M5.5b, M5.6–M5.8 |
| [r1/m4-real-time-tour.md](implemented/r1/m4-real-time-tour.md) | Implemented: Sprint A PR #130 (dev.17), Sprint B PRs #139/#146 (dev.19–20) |
| [r1/ism-structure-and-dust.md](implemented/r1/ism-structure-and-dust.md) | **PR A implemented** in [#199](https://github.com/sunholo-data/stapledons-godot/pull/199), P2 accepted D-62; complete local/CI and independent review PASS. Local clouds, dust, HUD and Archive; [report](implemented/r1/ism-local-clouds-report.md). **PR B deferred**, [scientific follow-up](planned/r1/ism-dense-clouds.md). |
| [r1/free-navigation-recovery.md](implemented/r1/free-navigation-recovery.md) | **Implemented** in #199 (D-63): safe rest start, stable body list, real-time idle, Earth arrival, default mouse and pointer ownership, pause and discoverable local clouds. Native OS capture limitation retained; [report](implemented/r1/free-navigation-recovery-report.md). |
| [r1/m4-ship-geometry-demo.md](implemented/r1/m4-ship-geometry-demo.md) | Implemented: PR #117 (dev.4–5), the default ship; M2 Air benchmark waived by Mark 2026-10-15 |
| [r1/title-screen.md](implemented/r1/title-screen.md) | Implemented: PR #160 (dev.22), 2026-10-08 |
| [r1/relative-size-stops.md](implemented/r1/relative-size-stops.md) | Implemented: PRs #182 (dev.25) and #194 (dev.26), 2026-10-09 |
| [r1/lightspeed-loading.md](implemented/r1/lightspeed-loading.md) | Implemented: PR #172 (dev.23), 2026-10-08 |
| [r1/ship-ui-hud-consoles.md](implemented/r1/ship-ui-hud-consoles.md) | Implemented: PRs #193/#195/#196 (dev.26), 2026-10-10 |
| [r1/export-completeness.md](implemented/r1/export-completeness.md) | Implemented 2026-10-12 (mission iteration 26, charter triage L6): `make export-filter-audit` in `make test` classifies every shipped `res://` literal against `export_presets.cfg` (16 in-process mutants, incl. the dev.23 lens-table regression); `spike/` no longer ships (G1); rig-only `export-pack-check` re-measures it on a real `--export-pack` zip, strict in `publish-dev`. Sprint: [R1-L6-EXPORT-COMPLETENESS](implemented/r1/export-completeness-sprint.md); eval Sonnet 84 PASS |
| [r2/crew-integration.md](implemented/r2/crew-integration.md) | **Implemented**: sprint R2-CREW merged in PR #224 (2026-10-14, eval round 2 PASS 88/100) on AILANG v0.54.8 (#226); crew_core pinned at 0.4.0 (#231), 0.4.1 in PR #243. |
| [r2/crew-work.md](planned/r2/crew-work.md) | W1 (the Crew console work cards) **implemented** in PR #239; W2–W5 wait on Mark's OQ1–OQ4. |
| [r2/archive-npc.md](planned/r2/archive-npc.md) | **Proposed** 2026-10-14 (PR #241): the Archive as a special crew member; OQ3 and OQ4 answered 2026-10-15, OQ1 (presence) and OQ2 (console card) open. |
| [r2/crew-population.md](planned/r2/crew-population.md) | **Proposed** 2026-10-13: the wider population as cohort actors with mood buckets. Rulings D-71, D-73 (cohorts approved) and D-75 (~1,000 growing to ~1,500); cohorts in crew_core 0.4.0 (#231); in-game display needs a sprint plan. |
