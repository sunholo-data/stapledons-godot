---
title: The Higgs bubble
sidebar_position: 3
description: The one invented piece of physics in Stapledon's Voyage, its three defining properties, and the exact consequences derived from them.
---

# The Higgs bubble

> "The Higgs bubble is the one hand-wavy non-physics bit which we admit, but then be as hard-core
> physics for the rest as possible." (Mark, 2026-10-01)

The ship travels inside a spherical pocket, 100 m in radius, made by the ship's generator. The
canon, [`physics/higgs-bubble.md`](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md),
defines it by exactly three properties. Everything else is derived from them with ordinary
physics, and every number has a check value (HB-n) that the tests, the simulation and the
in-game Archive cite.

## The three properties

1. **The wall.** It blocks every massive particle, in both directions. It is transparent, both
   ways, to light of every energy and to neutrinos.
2. **Tunable inertia.** Seen from outside, the whole pocket has an effective inertial mass that
   can be made tiny but **never zero**. A zero-mass pocket would have to move at exactly c, and
   the crew's proper time would stop.
3. **The interior is its own frame.** The pocket's acceleration is not felt inside. The
   generator holds a steady 1 g "down", toward aft. That 1 g is a comfort setting, not a
   consequence of thrust.

The name is a label for the hand-wave. The Higgs field gives a proton only about 1% of its mass,
and zeroing it would dissolve atoms. Inside the bubble physics is normal; "Higgs" names the one
thing that was invented.

## What follows, exactly

| Consequence | Why | A check value |
|---|---|---|
| **Boost, cruise, brake.** Minutes of ship time to reach cruise, no midpoint flip, no zero-g coast | Property 3 hides the acceleration; property 2 makes it cheap | γ at 0.999999c = 707.107 (HB-18) |
| **A photon drive.** Only light leaves the bubble, so momentum goes out as light: E = m_eff c² φ per boost | Property 1 | 2.379 × 10¹⁷ J per kg of m_eff, rest to 0.99c (HB-35) |
| **The interstellar gas is the enemy.** In the ship frame the ISM is a proton beam; the wall reflects it elastically, so there is drag but no heating | Property 1 | Drag energy to α Cen at 0.99c: 1.37 × 10¹⁷ J (HB-53) |
| **No proton may cross.** At γ 707 the ISM would arrive as a 660 GeV beam | Property 1 | 663.5 GeV (HB-59) |
| **The crew sees the true relativistic sky.** Light crosses unchanged, so aberration, Doppler and the forward CMB are exactly what is on the window | Property 1 | Forward CMB at γ 707: 3,853.7 K (HB-63) |
| **Glazing still matters.** Starlight ahead is blueshifted to soft X-rays; the wall passes it, the dome glass and hull absorb it | Property 1 passes light of every energy | |
| **Tides are not shielded.** The wall stops particles, not curvature; near a small black hole the tide across 100 m is lethal | Gravity is geometry | Gaia BH1, at 10 r_s: 1.14 × 10⁶ g (HB-72) |

Not every row runs in the game yet: the planner, the energy ledger and the commit rule do (M2),
the forward CMB renders (M1.8), and black holes are planned (M3). See the
[roadmap](roadmap.md).

## Why the strictness

A hard-SF game earns its strangeness by refusing to cheat anywhere else. Because only one thing
is invented, players can trust everything they see, and learn from it: why the sky crowds ahead,
why sideways stars dim, why the trip costs 0.62 years for you and 4.4 for home. See
[the physics](physics.mdx).
