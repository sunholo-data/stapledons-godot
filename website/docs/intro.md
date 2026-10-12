---
title: The game
sidebar_position: 1
description: Stapledon's Voyage is a hard-SF game about near-light-speed travel and its cost in time, built in Godot 4 with an AILANG simulation.
---

# Stapledon's Voyage

*Travel as fast as you like. Live with the consequences.*

You are the first traveller with a drive that can push a ship arbitrarily close to the speed of
light. There is no faster-than-light travel, no FTL messaging and no time travel: only real
relativistic time dilation. You have **100 subjective years** aboard your ship.

Every journey is a trade. Pick a destination and a cruise speed between 0.9c and 0.999999c. The
faster you go, the less time passes for you, and the more centuries pass for everyone else.
The galaxy you leave is not the galaxy you come back to.

The game is named after [Olaf Stapledon](https://en.wikipedia.org/wiki/Olaf_Stapledon), author
of *Star Maker* and *Last and First Men*: vast timescales, philosophical exploration, and the
feeling that individual choices are tiny against deep time, yet still consequential.

## The pillars

These come from the design repo's [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md).
Every feature has to serve at least one.

| Pillar | In one line |
|---|---|
| **Choices are final** | No saves, no reloads. A committed journey cannot be undone. |
| **The game doesn't judge** | It shows consequences, not morals. You find the meaning. |
| **Time has emotional weight** | Time dilation means loss, isolation and treasuring what remains. |
| **The ship is home** | A crew gives human scale against cosmic alienation. |
| **Grounded strangeness** | Aliens are scientifically plausible and as diverse as possible. |

## Hard SF, with one admitted hand-wave

The ship travels inside a **Higgs bubble**, the one piece of invented physics. It is defined by
three properties, and everything it implies is derived exactly
([the bubble canon](higgs-bubble.md)). Everything else on screen is real special and general
relativity, held to a normative spec with numbered check values ([the physics](physics.mdx)).

That makes the game a physics lesson you can fly. At 0.99c the stars crowd ahead and turn
blue-white, the sky behind goes black, your clock runs 7.09 times slower than Earth's, and the
numbers on the screen are the ones you would compute by hand.

## What exists today, and what is planned

The game is **pre-alpha**. Release 1 builds the foundations, and is partly done:

- **Running today:** the relativistic sky (335,157 real stars over the Milky Way, aberration,
  Doppler colour and beaming, a photometric naked-eye exposure, the forward glow of the cosmic
  background at high γ); the galaxy map on the real catalogues, with companion stars at their
  system's distance; the journey core (the planner, the irreversible commit, the two clocks,
  deterministic replay); and, on a test stub, the crew's optional AI layer with the Medic's
  conversation scene.
- **In progress:** the first playable journey through the ship's interior (M4, its first steps
  merged; you can walk the bridge in the [development build](try-it.mdx)), and planets and flybys inside a star system (M5, a new
  milestone whose physics packages are published).
- **Planned for Release 1:** black holes rendered to general relativity (M3).
- **After Release 1:** the wider game: a galaxy that changes while you travel, a finite crew,
  trade in technology and ideas. None of it is built yet.

Concept art for the captain, the crew and the bridge is on the [concept art](/concept-art) page,
and every release gets a [news](/news) post.

See the [roadmap](roadmap.md) for the detail.

## Built in AILANG and Godot

Godot 4 renders everything you see. The simulation is written in
[AILANG](https://ailang.sunholo.com) and runs as a child process on the AILANG bytecode VM. Given
the same seed and inputs it produces byte-identical output. See
[Built with AILANG](built-with-ailang.md).
