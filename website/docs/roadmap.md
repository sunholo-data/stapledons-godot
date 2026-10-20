---
title: Roadmap
sidebar_position: 5
description: What is built, being validated and planned for Stapledon's Voyage.
---

# Roadmap

Release 1, **Foundations**, aims for one complete, playable journey: plan it,
commit to it, live through it, and arrive to find home older. This snapshot is
current to **20 October 2026**. The [design roadmap](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md)
and the game's sprint records hold the detailed acceptance criteria.

## What you can see today

| Work | State and remaining work |
|---|---|
| **The relativistic sky (M1)** | Catalogue stars, the Milky Way, aberration, Doppler colour and the forward CMB are built. The final sky acceptance report and performance review remain open. |
| **The journey core (M2)** | Landed: the simulation plans, commits and flies irreversible journeys, tracks both clocks and energy, and replays deterministically on the VM and interpreter. |
| **Black holes (M3)** | Landed: the Sgr A* demo has a physical shadow, gravitational lensing, Einstein rings, hover and orbit modes, with clocks and tides supplied by the simulation. Kerr rotation and the true Galactic-Centre background remain future work; the demo labels its Sol sky. |
| **The painted ship and bridge** | Walkable bridge and Commons, lifts, persistent clocks and contextual HUD cards. The ship travels toward its bow; a fixed Bow view slides with the captain and never turns, with Astern on a key and a close-up at each console. The bridge is rearranged to face the bow, and the navigation pods and captain's chair have a first painted finish. The spire lights the bridge in deep space and a nearby star's real light takes over. The remaining bridge props, a wider styling pass, and views for the other levels are next. |
| **First complete journey (M4)** | Transit, cruise interludes, arrival, news from home, the legacy record and the physics Archive exist, and a playthrough bot drives the whole journey through the bridge consoles. What remains: the display audit (two copy decisions), the ship reference images and captures, and a recorded scene-session replay. |
| **Planets and flybys (M5)** | Ephemerides, body navigation and planetary rendering are built, with a seven-leg guided trip: Earth → Sun → Jupiter → Callisto → Saturn → close Alpha Centauri A → TRAPPIST-1 → Aldebaran. Sgr A* remains a separately labelled optional demo. Close Saturn rings are visible. Callisto and nine other moons now have their own pinned source mosaics; Titan surface radar/IR imagery remains excluded. The full system-map/flyby experience, remaining ring and lighting acceptance, and complete M5 gates are still in progress. |
| **Interstellar clouds and dust** | The `lism-1` flight, route planning, wall glow, dust impacts and HUD integration landed in [PR #199](https://github.com/sunholo-data/stapledons-godot/pull/199). [PR #201](https://github.com/sunholo-data/stapledons-godot/pull/201) now adds equal-area curved wall marks and false-colour density shading, plus usable manual controls, real moon maps and direct guided arrivals. Complete local and matching CI tests, GPU references, exported-build checks and independent review pass. New source-figure cloud outlines pass the nearby sight-line recovery target. Dense-cloud and Local Leo Cold Cloud work is separate and has unresolved scientific checks. |
| **The crew (Release 2 preview)** | Five crew with names, roles and personalities live at the Voyage and Crew consoles. They take on work, raise concerns, ask for relief, and keep the ship running on long legs until something needs the captain. The Medic has a full set of faces; the others have one each for now. |
| **Optional AI voices** | Ask the Archive and the crew lines can use a live model (opt-in, off by default); a deterministic offline stub is the default. The Medic's live voice audition is still pending. |

[See the actual captures and clips in the gallery](/gallery). Progress reports
appear in [News](/news); availability is described in [Try it](/docs/try-it).

## Next to do

1. Bridge art: the remaining props in the painted finish, then a styling and
   graphics pass over the whole bridge, with the spire as its deep-space light.
2. Finish the first-journey acceptance: the display audit, the ship reference
   images and captures, and the recorded scene-session replay.
3. Close the sky's final acceptance report (M1.5b) and the remaining planet and
   flyby work (M5).
4. Resolve the dense-cloud scientific mismatches before shipping that dataset.
5. Crew: the Archive as a crew member, more crew faces, and long skips back
   under two seconds once an AILANG VM fix lands.
6. Run the attended crew-voice auditions.

The scheduled mission loop works the approved R1 queue alongside attended work;
its iteration records are on [issue #119](https://github.com/sunholo-data/stapledons-godot/issues/119).

## After Release 1

The wider [game vision](https://github.com/sunholo-data/stapledons-design/blob/main/vision/game-vision.md)
includes a galaxy that changes while you travel, a finite crew, trade in technology
and ideas, and a contact network you shape. These remain planned. Music is planned
for Release 2 or later.
