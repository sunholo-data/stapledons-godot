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
| [r1/constellation-inspection.md](implemented/r1/constellation-inspection.md) | Landed in [PR #271](https://github.com/sunholo-data/stapledons-godot/pull/271), 2026-10-19: hold-I guides for four Earth figures; full local suite, GPU, capture, benchmark and packaged smoke pass. Independent review 96/100; Mark explicitly accepted the existing crew-performance CI timing failure; [report](implemented/r1/constellation-inspection-report.md). |
| [r1/m1-relativistic-sky.md](implemented/r1/m1-relativistic-sky.md) | Implemented 2026-10-27: sprints `R1-M1-SKY` and `R1-M1-SKY-2` ([plan](implemented/r1/m1-relativistic-sky-sprint.md), [remaining plan](implemented/r1/m1-remaining-sprint.md)); M1.5b landed the AC9 renders (0 to 0.999c), the AC11 render gate and the AC7 bench; [report](implemented/r1/m1-report.md). Mark approved the renders (R-f) on 2026-10-27: bar clause 1 is met. |
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
| [r1/rig-watchdog-7200.md](implemented/r1/rig-watchdog-7200.md) | **Implemented** 2026-10-28 (mission iteration 55, PR #345, evaluation 95/100 PASS; D-126 C): the `rig/full` watchdog default is 7,200 s, and the rig-check control is hermetic against a caller's `RIG_TEST_S`, with a committed caller-poison case. [Sprint](implemented/r1/rig-watchdog-7200-sprint.md). |
| [r1/title-screen.md](implemented/r1/title-screen.md) | Implemented: PR #160 (dev.22), 2026-10-08 |
| [r1/relative-size-stops.md](implemented/r1/relative-size-stops.md) | Implemented: PRs #182 (dev.25) and #194 (dev.26), 2026-10-09 |
| [r1/lightspeed-loading.md](implemented/r1/lightspeed-loading.md) | Implemented: PR #172 (dev.23), 2026-10-08 |
| [r1/ship-ui-hud-consoles.md](implemented/r1/ship-ui-hud-consoles.md) | Implemented: PRs #193/#195/#196 (dev.26), 2026-10-10 |
| [r1/export-completeness.md](implemented/r1/export-completeness.md) | Implemented 2026-10-12 (mission iteration 26, charter triage L6): `make export-filter-audit` in `make test` classifies every shipped `res://` literal against `export_presets.cfg` (16 in-process mutants, incl. the dev.23 lens-table regression); `spike/` no longer ships (G1); rig-only `export-pack-check` re-measures it on a real `--export-pack` zip, strict in `publish-dev`. Sprint: [R1-L6-EXPORT-COMPLETENESS](implemented/r1/export-completeness-sprint.md); eval Sonnet 84 PASS |
| [r2/crew-integration.md](implemented/r2/crew-integration.md) | **Implemented**: sprint R2-CREW merged in PR #224 (2026-10-14, eval round 2 PASS 88/100) on AILANG v0.54.8 (#226); crew_core pinned at 0.4.0 (#231), 0.4.1 in PR #243. |
| [r2/crew-work.md](planned/r2/crew-work.md) | W1 (the Crew console work cards) **implemented** in PR #239; W2–W5 **approved** 2026-10-27 (OQ1–OQ4, every recommendation); next a sprint plan. |
| [r2/archive-npc.md](planned/r2/archive-npc.md) | **Proposed** 2026-10-14 (PR #241): the Archive as a special crew member; OQ2–OQ4 answered (OQ2 2026-10-27: a special card on the Crew console); OQ1 (presence) waits on the bake-off stills. |
| [r2/semantic-memory-s0.md](planned/r2/semantic-memory-s0.md) | **Planned** 2026-10-19 (mission iteration 38, charter row L9): similar worlds in the sim (S0), protocol 2.12 `similar` section, no package change; awaits a sprint plan and Mark's approval. |
| [r2/crew-population.md](planned/r2/crew-population.md) | **Approved** 2026-10-27 (proposed 2026-10-13): the wider population as cohort actors with mood buckets. Rulings D-71, D-73 (cohorts approved) and D-75 (~1,000 growing to ~1,500); cohorts in crew_core 0.4.0 (#231); in-game display needs a sprint plan. |
| [r2/crew-console-v2.md](implemented/r2/crew-console-v2.md) | **Implemented** 2026-10-17 (PR #267, evaluation 86/100): the Crew console as a two-panel internal videocom; work states named by the sim (protocol 2.11); a concern flow that never offers a forbidden Start; Ask/Order per offer; keyboard and pad; the visual pass; crew_core 0.6 stand-downs; names that fit faces (D-80). [Sprint](implemented/r2/crew-console-v2-sprint.md), [report](implemented/r2/crew-console-v2-report.md). |
| [r2/camera-fixed-views.md](implemented/r2/camera-fixed-views.md) | **Implemented** 2026-10-19 (PR #270, evaluation 79/100 PASS): three fixed zoom levels (Z1 Close, Z2 Deck, Z3 Whole level), third person only, authored sector/ring angles inside the 95 m envelope, sky views (forward, side, astern) and the Sgr A* hole view with cues; under way the default is Sky forward (Mark, 2026-10-17); no player mouse look; developer free camera on F8. [Sprint](implemented/r2/camera-fixed-views-sprint.md). Lower-deck sightlines deferred to the deck-layout pass. |
| [r2/home-tiers.md](implemented/r2/home-tiers.md) | **Implemented** 2026-10-19 (PR #277, evaluation 91/100 PASS): the crossing review's Home page in sixteen home-time tiers (protocol 2.12; 2.10 and 2.11 keep seven), each a pool of picture variants picked from the voyage seed (D-86), 28 pictures; the website shows tiers 0-12. [Sprint](implemented/r2/home-tiers-sprint.md). |
| [r2/camera-forward.md](implemented/r2/camera-forward.md) | **Implemented** 2026-10-20 (PR #282, #286; evaluation 88/100 PASS; D-91–D-94): travel along the deck (one named basis change, no new formula, sim untouched) and a fixed Bow view that slides with the captain and never turns (starbow, destination and deck in one frame); Astern (9) and Console; a guided stop turns the body 30° off the bow, and the Sgr A* hole sits on the bow; level-keyed views.json v2 (Commons legacy). Amends R2-CAMERA; the deck layout (D-90) is re-planned facing the bow. [Sprint](implemented/r2/camera-forward-sprint.md). |
| [r2/bridge-styling-pass.md](implemented/r2/bridge-styling-pass.md) | **Implemented** 2026-10-22 (PR #300, this PR; D-100, D-104, D-106, D-110): the spire keys the bridge in deep space and hands the light to a near star; banded toon and ink on every bridge surface; the props grown (D-104), the deck and mast painted, the lift head authored; the rim fronds as painted cards (D-106); the whole HUD on one theme (ui-theme-check strict at 0). [Sprint](implemented/r2/bridge-styling-pass-sprint.md), [report](implemented/r2/bridge-styling-pass-report.md). |
| [r2/deck-layout.md](planned/r2/deck-layout.md) | **Planned**, awaiting Mark's approval (2026-10-19): bridge and Commons furniture and sightlines rearranged for the fixed views (a measured layout evaluator; Commons clear-line ceilings to 0), then Blender hero assets to the sprites' finish with the spire light baked and the sky live. Pauses: layout pick, style frame. [Sprint](planned/r2/deck-layout-sprint.md); plan review 74 → 86/100. |
| [r2/sound.md](planned/r2/sound.md) | **Approved** 2026-10-20 (D-101; OQ6 home beacon amended 2026-10-27 to play only in Earth's beam): the first sound: a diegetic ship-interior soundscape (nothing heard from space; the teacup rule for the drive; the spire's constant hum), the bridge, the voyage's moments, the dust counter, a mix with voice ducking, AILANG-synthesised tonal sounds and CC0 foley, all tested headless. [Sprint](planned/r2/sound-sprint.md). |
| [r2/sunholo-audio.md](implemented/r2/sunholo-audio.md) | **Implemented** 2026-10-26 (D-119, D-124): the sound synthesis, the review mix and the offline loudness checks as the published `sunholo/audio` package (pinned 0.5.0, on AILANG v0.54.18); all 28 WAVs regenerate byte for byte, `make sound-levels` and `sound-levels-parity` (AILANG = GDScript to the centi-dB) are in `make test`. [Sprint](implemented/r2/sunholo-audio-sprint.md), [report](implemented/r2/sunholo-audio-report.md). |
| [r2/captain-animation.md](planned/r2/captain-animation.md) | **Approved** 2026-10-20 (D-102), executing CA0 and the CA1 pilot: the captain animated as painted frames posed by a rig (spike compared four ways through the Bow view); CA0 state machine with today's stills, a 10-frame pilot before any spend. |
| [r2/star-surfaces.md](implemented/r2/star-surfaces.md) | **Implemented** 2026-10-21 (PRs #302, #315; evaluation 77/100 PASS; D-105, D-111, D-114): resolved stellar surfaces in the Auto view (per-type limb darkening, giant convection cells, spots, faculae and flares as a temperature map, gated by real resolution, flux-preserving), a close pass of Sun-like stars, the helm's telescope, and eclipse layers (Baumbach corona, H-alpha prominences, the diamond-ring sliver); `sunholo/celestial` 0.5.0. [Sprint](implemented/r2/star-surfaces-sprint.md), [report](implemented/r2/star-surfaces-report.md). |
| [r3/earth-link.md](planned/r3/earth-link.md) | **Planned** 2026-10-27, awaiting Mark's approval: R3 S1, K1 and F6. Earth's signal obeys light travel (`sunholo/observe` 0.1.0, protocol 2.16), the live Earth rate, a comms station, Earth's beams on the map. [Sprint](planned/r3/earth-link-sprint.md); plan review 66 then 86 PASS |
