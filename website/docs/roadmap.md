---
title: Roadmap
sidebar_position: 5
description: Release 1 of Stapledon's Voyage - what is done, what is in progress and what is planned.
---

# Roadmap

Release 1, **Foundations**, goes from the architecture spike to one complete, playable journey:
plan it, commit to it, live through it, and arrive. The source of truth is
[`roadmap/r1-foundations.md`](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md)
in the design repo, plus the sprint plans in this repo. This page is a snapshot as of
**3 October 2026**. For the rulings behind it, see [Decisions](/decisions); for what changed
when, see [News](/news).

<span className="sv-status sv-status--done">Done</span> merged on `main` ·
<span className="sv-status sv-status--review">In review</span> an open pull request ·
<span className="sv-status sv-status--progress">In progress</span> partly merged ·
<span className="sv-status sv-status--planned">Planned</span> designed, not built

## At a glance

| Milestone | State |
|---|---|
| M0 Spike | <span className="sv-status sv-status--done">Done</span> |
| M1 The relativistic sky | <span className="sv-status sv-status--progress">In progress</span>: everything visible is merged; the final acceptance step (M1.5b) is open |
| M2 The journey core | <span className="sv-status sv-status--done">Done</span> |
| AI foundation (AI.1–AI.10a) | <span className="sv-status sv-status--done">Done</span> on the stub; the first live run (AI.10b) is pending |
| M3 Black holes | <span className="sv-status sv-status--planned">Planned</span> |
| M4 First playable journey | <span className="sv-status sv-status--progress">In progress</span>: M4.0, M4.1 step 1 and bridge v1 merged |
| M5 Planets and flybys | <span className="sv-status sv-status--progress">In progress</span>: design and sprint approved, packages published, the first step (M5.1a) merged |

## M0: Spike <span className="sv-status sv-status--done">Done</span>

Finished 27 September 2026. The AILANG simulation as a child process over NDJSON (about 50 µs per
tick round trip), a Godot starfield with per-star aberration, blackbody Doppler colour and
point-source beaming, 27 physics reference checks and 9 GPU-against-CPU golden cases under 0.1 px.

## M1: The relativistic sky <span className="sv-status sv-status--progress">In progress</span>

Goal: what the player sees out of any window is correct in every direction, at any speed and
orientation.

| Item | State |
|---|---|
| Full 3D motion: arbitrary heading and a free camera (M1.6b) | <span className="sv-status sv-status--done">Done</span> |
| Real star colours and catalogue tiers from CNS5, Gaia GCNS and Hipparcos, built in AILANG (M1.2b–M1.2d) | <span className="sv-status sv-status--done">Done</span> |
| Starfield v2: 335,157 stars instanced on the GPU, float64 rebasing (M1.3, [#67](https://github.com/sunholo-data/stapledons-godot/pull/67)) | <span className="sv-status sv-status--done">Done</span> |
| Milky Way background: NOIRLab panorama, destarred in AILANG, Doppler shifted per texel (M1.4) | <span className="sv-status sv-status--done">Done</span> |
| Photometric naked-eye exposure: stars in lux, sky in cd/m², honest HUD, labelled aids (M1.5a, [#75](https://github.com/sunholo-data/stapledons-godot/pull/75), [#80](https://github.com/sunholo-data/stapledons-godot/pull/80)) | <span className="sv-status sv-status--done">Done</span> |
| Galaxy map on the catalogue tiers: 5,687 stars within 25 pc, α Cen A and B separately selectable (M1.7, [#81](https://github.com/sunholo-data/stapledons-godot/pull/81)) | <span className="sv-status sv-status--done">Done</span> |
| Companion stars at their system's distance: 20,524 companions; Sirius B now sits with Sirius A ([#89](https://github.com/sunholo-data/stapledons-godot/pull/89)) | <span className="sv-status sv-status--done">Done</span> |
| Forward CMB glow, 3,853.7 K at γ 707 (M1.8, [#79](https://github.com/sunholo-data/stapledons-godot/pull/79); ring fix [#88](https://github.com/sunholo-data/stapledons-godot/pull/88)) | <span className="sv-status sv-status--done">Done</span> |
| Acceptance (M1.5b): reference renders at 0, 0.5, 0.9, 0.99 and 0.999c, the 60 fps at 1440p bench with the full catalogue and background, the M1 report | <span className="sv-status sv-status--progress">Open</span> |

## M2: The journey core <span className="sv-status sv-status--done">Done</span>

Landed 2 October 2026 ([report](https://github.com/sunholo-data/stapledons-godot/blob/main/design_docs/implemented/r1/m2-report.md)).
Ten milestones, each independently evaluated at 89–96 out of 100: protocol v2 with hand-written
AILANG codecs; the world clock and ship phases (boost, cruise, brake) with a closed energy ledger;
the journey planner, equal to the closed form to 1e-9; the commit rule, enforced by the
simulation; SplitMix64 named random streams; `make replay` (a 10,000-tick session byte-identical
on the VM and the interpreter); and the galaxy map with the commit ritual.

## AI foundation <span className="sv-status sv-status--done">Done on the stub</span>

Optional, opt-in runtime AI for the crew: portraits, voice and text, using the player's own API
keys, off by default and capped by a cost ceiling the player sets (US$0.50 by default). Every
piece runs end to end against a deterministic stub, so tests and replays never spend money.

| Step | What it delivers | State |
|---|---|---|
| AI.1–AI.3 | `{emotion}` markers in lines, protocol 2.1, validated AI records | <span className="sv-status sv-status--done">Done</span> |
| AI.4–AI.7 | The AI service (provider routing, cache, stub), adapters, a non-blocking bridge, the relay, key hygiene | <span className="sv-status sv-status--done">Done</span> |
| AI.8 | The accepted Medic portrait set, pinned and content-addressed | <span className="sv-status sv-status--done">Done</span> |
| AI.9 | Key settings, the cost ceiling and indicator, a guard so automation never goes live | <span className="sv-status sv-status--done">Done</span> |
| AI.10a | The Medic conversation scene: portrait cross-fades on emotion markers, subtitles, voice ([#91](https://github.com/sunholo-data/stapledons-godot/pull/91)) | <span className="sv-status sv-status--done">Done</span> |
| AI.10b | The first live run, attended: one real Medic line and voice auditions under a US$1 ceiling | <span className="sv-status sv-status--planned">Pending</span> |

## M3: Black holes <span className="sv-status sv-status--planned">Planned</span>

General relativity: the shadow at its true 2.6 r_s, gravitational lensing and Einstein rings,
checked against the spec's Schwarzschild check values. The design is
drafted; it has no sprint plan yet.

## M4: First playable journey <span className="sv-status sv-status--progress">In progress</span>

One complete journey with the ship's interior: the ship-years against Earth-years gap made felt.

| Step | What | State |
|---|---|---|
| M4.0 | Area bundles: the interior loader, the art contract checks (`make validate-areas`), the ship frame; art swaps become data drops ([#95](https://github.com/sunholo-data/stapledons-godot/pull/95)) | <span className="sv-status sv-status--done">Done</span> |
| M4.1 step 1 | Consequence in the simulation: the Earth clock running on while you travel, the years gap, the 1,000 AU arrival stand-off, light-delayed news from home, live interstellar-medium readouts (protocol 2.2, [#92](https://github.com/sunholo-data/stapledons-godot/pull/92)) | <span className="sv-status sv-status--done">Done</span> |
| Bridge v1 interior art | Demo art, replacing the blockout ([#97](https://github.com/sunholo-data/stapledons-godot/pull/97)) | <span className="sv-status sv-status--done">Done</span> |
| Bridge v2 final art | A quality study is done; the final art is being made ([concept art](/concept-art)) | <span className="sv-status sv-status--progress">In progress</span> |
| M4.2 | The interior composite: deck, panorama and live sky in one image | <span className="sv-status sv-status--planned">Planned</span> |
| M4.3a, M4.3b | Transit, time warp and the HUD | <span className="sv-status sv-status--planned">Planned</span> |
| M4.4 | The news-from-home and journey-record screens | <span className="sv-status sv-status--planned">Planned</span> |
| M4.5–M4.7 | A full playthrough audit, the physics gates, the in-game Archive of physics explainers | <span className="sv-status sv-status--planned">Planned</span> |

## M5: Planets and flybys <span className="sv-status sv-status--progress">In progress</span>

A new milestone: player-facing flight inside a star system. The design
([#84](https://github.com/sunholo-data/stapledons-godot/pull/84)) and the sprint plan
([#86](https://github.com/sunholo-data/stapledons-godot/pull/86)) are approved. The planned loop:
start held above Earth, pick a body on a system map (the Sun, the 8 planets, 11 moons, 4 ring
systems), choose to stop or fly by at anywhere from 0.001c to 0.99c, commit, and ride the leg with
exactly relativistic views: light-time delay, aberration, and the Terrell rotation that makes a
passing sphere look turned. Planets are lit physically and rings cast shadows. At α Centauri the
known and candidate planets show as points only, with badges that say how sure the astronomy is.

| Step | State |
|---|---|
| Package work: [`sunholo/celestial`](https://github.com/sunholo-data/ailang-packages/tree/main/packages/celestial) 0.1.0 (Kepler solver, JPL planetary ephemerides for 3000 BC–3000 AD and moons, IAU frames, light-time, gravity, reflectance, rings) and `sunholo/relativity` 0.6 and 0.7 (the bubble's forward glow, the aberrated outline of a nearby sphere) | <span className="sv-status sv-status--done">Published</span> |
| M5.1a: Sol and α Cen data, and the game pinning the new packages ([#99](https://github.com/sunholo-data/stapledons-godot/pull/99)) | <span className="sv-status sv-status--done">Done</span> |
| M5.1b–M5.8: the system map, lighting, rings, flyby flight and views | <span className="sv-status sv-status--planned">Planned</span> |

## After Release 1

The wider game from the [vision](https://github.com/sunholo-data/stapledons-design/blob/main/vision/game-vision.md):
a galaxy that changes while you travel, a finite crew, trade in technology and ideas, and a contact
network you shape. None of that is built yet, and the site will not describe how it plays out.
Music is planned for Release 2 or later.
