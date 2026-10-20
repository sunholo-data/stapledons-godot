---
title: "dev.34 and dev.35: home in sixteen steps, and a bridge that faces the way you're going"
date: 2026-10-20
authors: [sunholo]
tags: [release, journey]
release_tag: "v0.4.0-dev.35-bow-view"
release_url: "https://github.com/sunholo-data/stapledons-godot/releases/tag/v0.4.0-dev.35-bow-view"
---

The camera from dev.33 swung around the spire as you walked, and the controls turned with it. dev.35 fixes that at the root. The ship now travels toward its bow, along the deck. One fixed view looks forward, slides with the captain and never turns. The bridge has been rearranged so every console faces the way you're going. Far from any star, the ship's spire lights the deck.

{/* truncate */}

## Forward, always up the screen (dev.35)

![The Bow view at 0.99c: the starbow gathered ahead, over the helm](https://storage.googleapis.com/stapledons-voyage-assets/site/4cc441d5681b20f5bd2087a7220984e431400ab24f341e119da2d3e02bfef5d9.png)

The direction of travel used to point straight up from the deck, which meant the view ahead and the deck you walk on could not share a frame. Now the ship flies bow first, and the decks stay level under the generator's 1 g. The **Bow** view looks forward over the rail from behind and above the captain. It slides as you walk but never turns, so W always walks up the screen and the starbow always sits ahead. Press **9** to look **Astern**, and **7** or **R** to come back. Using a console zooms in on it, still looking forward. Props that would block the view, such as the spire or the lift, fade out of the way.

![At the first stop of the guided voyage the ship turns so the Sun sits about 30° off the bow](https://storage.googleapis.com/stapledons-voyage-assets/site/e5a057ee50851a5d894d4f3deac69d690174603685e4416fe286886dd10e496f.png)

At a stop, the ship turns itself rather than the camera. The body you've reached sits about 30° off the bow, inside the same view, from every spot on the bridge we measured. No physics changed: the relativity package already took the direction of travel as its one axis, and the sky is still the same live render, checked against the CPU reference in the GPU golden cases.

## The bridge faces the bow (dev.35)

![The captain's chair behind the navigation pods, lit by the spire in deep space](https://storage.googleapis.com/stapledons-voyage-assets/site/46a133e85f5bb40ad4df11bd45846d2e8cfad85054a87d6c21d6d5206cdd8221.png)

The old bridge was laid out for the old camera: three of its four stations had you facing the stern or sideways. A probe that looks through the real Bow and Astern cameras at nearly 4,800 positions on the deck now scores every layout. The new one puts the navigation pods at the bow rail with the captain's chair behind them and the Voyage and Crew consoles either side. You start behind the helm with a clear walk ahead. Every station faces forward, and every console close-up looks out at the sky ahead.

![The same helm near a star: its light and shadows take over from the spire](https://storage.googleapis.com/stapledons-voyage-assets/site/cf5bf0f61a9a6107c9a7c49924034233e023d087f374bdcbdc44f0749fcb687d.png)

The pods and chair have a first painted finish: shading where surfaces meet, ink at the creases and an ink outline. In deep space the bridge is lit by a warm light on the spire. Near a star, its real light takes over: direction, colour and Doppler shift come from the simulation. The handover is gradual.

![The navigation pod close-up, with its new screen on the captain's side](https://storage.googleapis.com/stapledons-voyage-assets/site/ac50e1cd99776bad0390143e93faa04177ca6013f8906e7e2830cbdd6a9871e6.png)

Each navigation pod now has a brass-framed screen on the side facing the captain.

## Home in sixteen steps (dev.34)

The crossing review's Home page now has sixteen steps of time away instead of seven, with more than one picture for many of them, chosen per voyage. The pictures for up to a few thousand years are on the [concept art page](/concept-art).

## What's new

- Travel toward the bow, a fixed Bow view that slides and never turns, Astern on **9**, and stops that turn the ship to the body ([#282](https://github.com/sunholo-data/stapledons-godot/pull/282), [#286](https://github.com/sunholo-data/stapledons-godot/pull/286)).
- The bridge rearranged to face the bow, scored through the real cameras ([#287](https://github.com/sunholo-data/stapledons-godot/pull/287)).
- Painted navigation pods and captain's chair, operator-side screens, and the spire as the bridge's own light ([#290](https://github.com/sunholo-data/stapledons-godot/pull/290)).
- Sixteen home-time steps with picture variants on the crossing review's Home page (dev.34).
- Pull requests now run a fast check tier on GitHub; the full suite runs on the build machine before merge.

## Not yet

- The rest of the bridge props in the painted finish, and a wider styling pass over the whole bridge and its on-screen graphics.
- Views for the Commons and the other levels, each with its own fixed views and set dressing.

**Releases:** [v0.4.0-dev.34-home-tiers](https://github.com/sunholo-data/stapledons-godot/releases/tag/v0.4.0-dev.34-home-tiers), [v0.4.0-dev.35-bow-view](https://github.com/sunholo-data/stapledons-godot/releases/tag/v0.4.0-dev.35-bow-view)
