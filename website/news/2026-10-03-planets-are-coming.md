---
title: "Planets are coming"
date: 2026-10-03T16:00
authors: [sunholo]
tags: [progress, planets]
---

A new milestone, M5, brings planets, moons and flybys inside a star system, with the same rule as
the sky: real data, real physics.

{/* truncate */}

## What's done

- **The design and the sprint plan are approved** ([#84](https://github.com/sunholo-data/stapledons-godot/pull/84), [#86](https://github.com/sunholo-data/stapledons-godot/pull/86)).
- **A new AILANG package, [`sunholo/celestial`](https://github.com/sunholo-data/ailang-packages/tree/main/packages/celestial)
  0.1.0**, published with 93 tests: a Kepler solver, JPL planetary ephemerides for 3000 BC to
  3000 AD plus moons, IAU reference frames, light-time, gravity, reflectance, and planetary rings.
- **`sunholo/relativity` 0.6 and 0.7**: the bubble's forward glow, and the aberrated outline of a
  nearby sphere, which is what a planet looks like as you pass it near light speed.

## What's planned

Start held above Earth, pick a body on a system map (the Sun, 8 planets, 11 moons, 4 ring
systems), choose to stop or fly by at 0.001c to 0.99c, commit, and ride the leg. The views will be
exact: light-time delay, aberration, and the Terrell rotation that makes a passing sphere look
turned. At α Centauri, the known and candidate planets will show as points only, with a badge
saying how sure the astronomy is. The first step, the Sol and α Cen data and the game's package
pins, has merged ([#99](https://github.com/sunholo-data/stapledons-godot/pull/99)).

See the [roadmap](/docs/roadmap).
