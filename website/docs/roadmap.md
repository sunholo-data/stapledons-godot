---
title: Roadmap
sidebar_position: 5
description: Release 1 of Stapledon's Voyage - what is done, what is in review and what is planned.
---

# Roadmap

Release 1, **Foundations**, goes from the architecture spike to one complete, playable journey:
plan it, commit to it, live through it, and arrive to a changed galaxy. The source of truth is
[`roadmap/r1-foundations.md`](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md)
in the design repo. This page is a snapshot as of **3 October 2026**.

<span className="sv-status sv-status--done">Done</span> merged on `main` ·
<span className="sv-status sv-status--review">In review</span> an open pull request ·
<span className="sv-status sv-status--progress">In progress</span> partly merged ·
<span className="sv-status sv-status--planned">Planned</span> designed, not built

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
| Real star colours from Gaia and Hipparcos photometry (M1.2) | <span className="sv-status sv-status--done">Done</span> |
| The big catalogue: 335,157 stars instanced on the GPU, float64 rebasing (M1.3) | <span className="sv-status sv-status--done">Done</span> |
| Milky Way background: NOIRLab panorama, destarred in AILANG, Doppler shifted per texel (M1.4) | <span className="sv-status sv-status--done">Done</span> |
| Photometric exposure: dark-adapted eye, honest HUD, labelled aids (M1.5a) | <span className="sv-status sv-status--done">Done</span> |
| Galaxy map and goldens on the catalogue tiers (M1.7, [PR #81](https://github.com/sunholo-data/stapledons-godot/pull/81)) | <span className="sv-status sv-status--done">Done</span> |
| Forward CMB disc (M1.8, [PR #79](https://github.com/sunholo-data/stapledons-godot/pull/79); ring fix [#88](https://github.com/sunholo-data/stapledons-godot/pull/88)) | <span className="sv-status sv-status--done">Done</span> |
| 60 fps at 1440p with the full catalogue and background, on an M4 Max | Acceptance |

## M2: The journey core <span className="sv-status sv-status--done">Done</span>

Landed 2 October 2026 ([report](https://github.com/sunholo-data/stapledons-godot/blob/main/design_docs/implemented/r1/m2-report.md)).
Ten milestones, each independently evaluated at 89–96 out of 100:

- protocol v2 with hand-written AILANG codecs;
- the world clock and ship phases (boost, cruise, brake) and a closed energy ledger;
- the journey planner, equal to the closed form to 1e-9;
- the commit rule, enforced by the simulation;
- SplitMix64 named random streams;
- `make replay`: a 10,000-tick session byte-identical on the VM and the interpreter;
- the galaxy map with the commit ritual: plan, hold to commit, transit, arrive.

## M3: Black holes <span className="sv-status sv-status--planned">Planned</span>

General relativity: the shadow at its true 2.6 r_s, gravitational lensing and Einstein rings,
checked against the spec's Schwarzschild check values. This is where New Game+ begins, and where
the hard-SF promise is most visible. The design is drafted.

## M4: First playable journey <span className="sv-status sv-status--planned">Planned</span>

One complete journey with a placeholder ship deck: the ship-years against Earth-years gap made
felt. The design has passed review and its sprint plan is proposed.

## After Release 1

The full game from the [vision](https://github.com/sunholo-data/stapledons-design/blob/main/vision/game-vision.md):
a galaxy simulation where civilisations rise, change and die while you travel; a finite crew
that ages, has children and dies; trade in technology and philosophy; a contact network you
shape; and, at the end of your 100 years, a fast-forward to Year 1,000,000 and a legacy report.
None of that is built yet.

Alongside Release 1 there is groundwork for optional, opt-in runtime AI (crew portraits, voice and
text through the player's own API keys, off by default, with a cost ceiling). It is plumbing so
far, not a feature you can play.
