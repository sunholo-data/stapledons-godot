---
title: "dev.32 and dev.33: the crossing review, a crew videocom and a camera that follows you"
date: 2026-10-19
authors: [sunholo]
tags: [release, ai, journey]
release_tag: "v0.4.0-dev.33-fixed-camera"
release_url: "https://github.com/sunholo-data/stapledons-godot/releases/tag/v0.4.0-dev.33-fixed-camera"
---

Two review builds in three days. A long crossing now ends in a review you read at your own pace. Talking to the crew happens on an internal videocom that shows whose move it is. And the camera has left your head: you now see the captain from fixed third-person views that turn to the sky when the ship is under way.

{/* truncate */}

## The crossing, reviewed (dev.32)

![The crossing review: 0.999c, gamma 22.4, 70 days lived aboard while 4.33 years passed on Earth](https://storage.googleapis.com/stapledons-voyage-assets/site/18e329e43fd76c27607ac120bfec203689b91f5bc7dd4306b3bfd06fbe4b3131.png)

A long cruise is crossed in chunks the simulation publishes. A crew hold stops the crossing on the day it happens. Before arrival braking the ship pauses on a review: the crossing itself, home, aboard, the moments that mattered, who changed, the medium you flew through, and who is waiting for you. Every number comes from the simulation's cruise digest. Nothing times out; you read on when you're ready, and you can look around the bridge while it's open.

![The Home page: how long has passed at home, with a picture that changes with the years](https://storage.googleapis.com/stapledons-voyage-assets/site/62b50d7590b7df0cebf6acb6721f464c76334c34054e6622dbd0e5966ce9c1a6.png)

The Home page shows a picture of home that changes with how long you've been gone. All seven pictures are on the [concept art page](/concept-art).

## The crew on the videocom (dev.33)

![A crew concern on the videocom: Start is greyed out until the captain answers](https://storage.googleapis.com/stapledons-voyage-assets/site/7b80a97ae77fb6ec7bc202716deaab231d75335c50ac8d698dc68f07c64b4b6a.png)

The Crew console is now a two-panel internal videocom. The crew member is large on the left, at the emotion the simulation gives them, with their words. On the right are the work and the actions you can take next. If someone raises a concern, **Start** is greyed out and says why until you answer: make the job clearer, ask their advice, explain why it matters, or insist. Asking or ordering is chosen right there on each offer.

![Work under way, with colour-coded chips showing who is waiting on the captain](https://storage.googleapis.com/stapledons-voyage-assets/site/4db90654e12c6799594bb44a95a0beb86c23d7420f544646c3267e317406e0bb.png)

A roster board puts whose move it is first. Colour-coded chips show who is waiting on you (amber), who is working (green) and who is free. The colours are checked for colour-blind separation. Crew can now ask to stand down at a duty check-in (crew_core 0.6), and generated names now suit each portrait.

## A camera that follows you (dev.33)

![The bridge from the Deck view, the default at rest](https://storage.googleapis.com/stapledons-voyage-assets/site/d4bedfeb9853c3ee216cf0dc34e2cdbee12360923d5f87773bfb7bf264f8becd.png)

There is no more free zoom or mouse look. The camera follows the captain from three fixed levels: **Close**, **Deck** (the default) and **Whole level**, chosen with 1/2/3 or one scroll or pinch per level. Its angles are authored around the bridge so the captain stays in view.

![Sky forward under way at 0.99c](https://storage.googleapis.com/stapledons-voyage-assets/site/f723ed56e6e69828849bfb8e861e14f22100317bc89db75d7605d4014772f1bc.png)

Under way the camera turns to **Sky forward** by default and looks past the captain at the starbow gathering ahead. At a guided stop it turns to the side to show the body you've reached. At Sagittarius A* it frames the hole itself:

![Hovering at three horizon radii from Sagittarius A*: the shadow and the lensed sky above the captain](https://storage.googleapis.com/stapledons-voyage-assets/site/364a2723907a14ebcde21ff1253e96d5f6f8907eec8af967abba2e99e7e9e227.png)

The physics is unchanged. New GPU-against-CPU golden cases check that the sky seen through the new views matches the reference.

## What's new

- The crossing review replaces the six-second interlude card ([#264](https://github.com/sunholo-data/stapledons-godot/pull/264)).
- Crew offers get an answer while the guided tour is paused ([#263](https://github.com/sunholo-data/stapledons-godot/pull/263)).
- The Crew console becomes a videocom, with stand-downs and names that fit faces ([#267](https://github.com/sunholo-data/stapledons-godot/pull/267)).
- A fixed third-person camera with sky views, including the black-hole view ([#270](https://github.com/sunholo-data/stapledons-godot/pull/270)).
- Hold **I** to see faint guides for Orion, Cassiopeia, Crux and the Big Dipper ([#271](https://github.com/sunholo-data/stapledons-godot/pull/271)).
- AILANG v0.54.14, with every downstream workaround for its VM removed ([#262](https://github.com/sunholo-data/stapledons-godot/pull/262)).

## Not yet

- Bridge furniture and sightlines rearranged for the new fixed views.
- The wider population aboard, of which these five crew are the voices you know.

**Releases:** [v0.4.0-dev.32-crossing-review](https://github.com/sunholo-data/stapledons-godot/releases/tag/v0.4.0-dev.32-crossing-review), [v0.4.0-dev.33-fixed-camera](https://github.com/sunholo-data/stapledons-godot/releases/tag/v0.4.0-dev.33-fixed-camera)
