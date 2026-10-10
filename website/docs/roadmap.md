---
title: Roadmap
sidebar_position: 5
description: What is built, being validated and planned for Stapledon's Voyage.
---

# Roadmap

Release 1, **Foundations**, aims for one complete, playable journey: plan it,
commit to it, live through it, and arrive to find home older. This snapshot is
current to **10 October 2026**. The [design roadmap](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md)
and the game's sprint records hold the detailed acceptance criteria.

## What you can see today

| Work | State and remaining work |
|---|---|
| **The relativistic sky (M1)** | Catalogue stars, the Milky Way, aberration, Doppler colour and the forward CMB are built. The final sky acceptance report and performance review remain open. |
| **The journey core (M2)** | Landed: the simulation plans, commits and flies irreversible journeys, tracks both clocks and energy, and replays deterministically on the VM and interpreter. |
| **Black holes (M3)** | Landed: the Sgr A* demo has a physical shadow, gravitational lensing, Einstein rings, hover and orbit modes, with clocks and tides supplied by the simulation. Kerr rotation and the true Galactic-Centre background remain future work; the demo labels its Sol sky. |
| **The painted ship and bridge** | Walkable bridge and Commons, lifts, persistent clocks and contextual HUD cards. Navigation, Voyage and Archive decisions live at the consoles. M opens a read-only chart. Art and external lighting continue to develop. |
| **First complete journey (M4)** | Transit, cruise interludes, arrival, news from home, the legacy record and the physics Archive exist. The remaining console-based playthrough audit and visual acceptance gates still prevent calling the whole slice complete. |
| **Planets and flybys (M5)** | Ephemerides, body navigation and planetary rendering are built, with guided Earth, Sun, Jupiter and Saturn stops. Close Saturn rings are visible. The full system-map/flyby experience, remaining ring and lighting acceptance, and complete M5 gates are still in progress. |
| **Interstellar clouds and dust** | The `lism-1` flight, route planning, wall glow, dust impacts and HUD integration are in final review in [PR #199](https://github.com/sunholo-data/stapledons-godot/pull/199). New source-figure cloud outlines pass the nearby sight-line recovery target. Dense-cloud and Local Leo Cold Cloud work is separate and has unresolved scientific checks. |
| **Optional crew AI** | The foundation and Medic conversation work against a deterministic offline stub. The first attended live run and voice review remain pending; live AI is off by default. |

[See the actual captures and clips in the gallery](/gallery). Progress reports
appear in [News](/news); availability is described in [Try it](/docs/try-it).

## Next to do

1. Finish the ISM review: check the cloud transitions, dust assumptions,
   afterglow comparison and Archive text in the dev build, alongside local and CI gates.
2. Complete the end-to-end journey audit through the bridge consoles, including
   the displayed numbers, commitment refusals, return trip and consequence screens.
3. Close the remaining sky and ship visual/performance acceptance gates.
4. Resolve the dense-cloud scientific mismatches before shipping that dataset,
   and continue the full planet/flyby controls and their acceptance work.
5. Run the first attended crew-AI check and voice auditions when scheduled.

The scheduled mission loop works the approved R1 queue. Its latest attempt is
currently parked because controller lanes were unavailable or out of quota;
its next product work is the remaining first-journey audit. The attended
ISM, bridge and demo work has continued independently.

## After Release 1

The wider [game vision](https://github.com/sunholo-data/stapledons-design/blob/main/vision/game-vision.md)
includes a galaxy that changes while you travel, a finite crew, trade in technology
and ideas, and a contact network you shape. These remain planned. Music is planned
for Release 2 or later.
