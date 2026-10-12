---
title: "A galaxy map from real catalogues"
date: 2026-10-03T12:00
authors: [sunholo]
tags: [progress, sky, journey]
---

The galaxy map now draws from the same star catalogues as the sky, and stars that belong together
stay together.

{/* truncate */}

## What's new

- **The map on the catalogue tiers** ([#81](https://github.com/sunholo-data/stapledons-godot/pull/81)): 5,687 stars within 25 pc, up from 3,802,
  with full-precision positions. α Centauri A and B are separate stars you can select.
- **Companion stars at their system's distance** ([#89](https://github.com/sunholo-data/stapledons-godot/pull/89)): a companion within 60″ and
  2,000 AU of its primary, agreeing in parallax and proper motion, takes the system's distance
  rather than its own noisier one. That moved 20,524 companions; Sirius B, for one, now sits with
  Sirius A at 8.6 ly.

![The galaxy map planning a trip to Sirius A, 8.60 ly](/img/news/map-sirius.jpg)

## Not yet

Both are in the [walkable bridge demo, v0.4.0-dev.1](/news/2026/10/03/walkable-bridge-demo-v0-4-0-dev-1).
