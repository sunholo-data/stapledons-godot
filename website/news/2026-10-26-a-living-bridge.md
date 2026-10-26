---
title: "dev.36 and dev.37: a painted bridge, a captain who lives on it, and its first sounds"
date: 2026-10-26
authors: [sunholo]
tags: [release, art]
release_tag: "v0.4.0-dev.37-living-bridge"
release_url: "https://github.com/sunholo-data/stapledons-godot/releases/tag/v0.4.0-dev.37-living-bridge"
---

The bridge is now one illustrated world: a painted deck, grown and curved furniture, painted plants and one look for every panel on screen. The captain walks it calmly in painted frames, uses the stations, sits in the chair and looks up when the ship arrives. For the first time you can hear the bridge too: the spire's hum, the consoles and soft footsteps, placed around the captain.

{/* truncate */}

## One illustrated bridge (dev.37)

![The Bow view at 0.99c over the restyled bridge: the starbow ahead, the navigation pods at the rail](https://storage.googleapis.com/stapledons-voyage-assets/site/1a1b1966cf02ae0277985eb6e70bd3139b4c711f31332ab905ebc3367875c5ae.jpg)

dev.35 gave the navigation pods and the captain's chair a first painted finish. Now the whole bridge has it. Every surface uses banded toon shading with an ink line. The deck and the spire are painted. The desks, the chair, the Archive terminal, the benches, the guardrails and the lift are grown, curved forms, with no straight boxes left. Around the rim stand painted potted plants of three kinds, with no two neighbours alike.

![Looking Astern: the painted spire at the centre of the deck, the lift, the chair and the potted plants around the rim, with a star low on the left](https://storage.googleapis.com/stapledons-voyage-assets/site/01ecfbd8ff3ec9d79d847d6d78b085c6f57ccdf8bdff1ed618ac100441163434.jpg)

In deep space the spire lights the deck and casts soft shadows outward from the mast. Near a star, the star's real light takes over, and the shadows harden and swing round with it.

![The same Bow view near a star: hard shadows from the captain, the chair and the desks fall across the deck](https://storage.googleapis.com/stapledons-voyage-assets/site/48ad479a6dbf85a845cdccbbcd7b0d488dd524e10b128f21a757fd3f8b4614ec.jpg)

The HUD now has one look as well. Every panel, card, button and console screen uses the same ink panels, palette and typefaces (Josefin Sans and Nunito, both SIL OFL), and text is coloured by what it means.

![The arrival card in the new HUD theme: distance, ship years, Earth years and the gap between them](https://storage.googleapis.com/stapledons-voyage-assets/site/d37b65b6d5b0130ff06681b61a9a63a448f8fc46b9c925e621580e02fea8ca37.jpg)

![The Voyage console close-up: a grown desk, its brass-framed screen in the same theme](https://storage.googleapis.com/stapledons-voyage-assets/site/ac57edbd063a13c7cbc22b430565f3a8096187f6296707015b6a148e8ef73018.jpg)

## The captain at work (dev.37)

![The captain walking across the painted deck in profile, with a faint echo of the previous step](https://storage.googleapis.com/stapledons-voyage-assets/site/c28b898abbb39afe3354aede8b26cc1c44c856f281c8fc6819c32eef3deb1a1a.webp)

The captain now walks at a calm 1.3 m/s instead of a jog. Each facing has twelve painted frames per step, from heel strike to toe off, with the coat hanging and the planted foot staying put. Between frames, a soft echo of the previous step fades behind the captain for 60 ms. It is switched off under reduced motion.

The captain also uses the bridge. At a station she reaches and holds, then steps back. Press **E** at the captain's chair to sit, and **E** or a move key to stand. She looks up when the ship arrives at a stop or the starbow forms, takes a pose for the lift, and leans slightly when she starts and stops. None of these motions play under reduced motion.

## The bridge has sound (dev.36 and dev.37)

dev.36 brought the game's first sound system. Seventeen sounds are synthesised by an AILANG tool, byte-identical on every machine, and the mix has separate volume settings for each bus. Nothing is heard from space. dev.37 puts these sounds on the bridge, placed in 3D around the captain, so a sound on the left of the screen is heard on the left in both Bow and Astern. The spire's hum leads, over a barely-there room tone. The consoles wake and sleep where they stand, and the lift has its latch, motor and bell. Footsteps are a soft, dark padding under the hum, each step a little different from the last. The sound tools now come from the shared `sunholo/audio` AILANG package, and every sound stayed byte-identical in the move.

## Also new

- **Stars show their surfaces.** Giant convection cells on Aldebaran, starspots on red dwarfs and each star's own limb darkening, wherever they would really resolve. In dev.37, **T** at the navigation console shows the stop's star through the ship's telescope, with its true magnification labelled, and when a body covers part of a star its corona and prominences appear.
- **The captain faces the way she moves**, in eight directions, so a sideways walk no longer shows her back.

## What's new

- The whole bridge in the painted finish: painted deck and spire, grown props, painted plants in three kinds, and one HUD theme ([#300](https://github.com/sunholo-data/stapledons-godot/pull/300), [#322](https://github.com/sunholo-data/stapledons-godot/pull/322)).
- The captain's calm painted walk with the step echo ([#318](https://github.com/sunholo-data/stapledons-godot/pull/318)), facing by motion ([#304](https://github.com/sunholo-data/stapledons-godot/pull/304)), and held poses at the stations, the chair and the lift, plus the look-up ([#330](https://github.com/sunholo-data/stapledons-godot/pull/330)).
- Sound: the sound director and seventeen synthesised sounds ([#298](https://github.com/sunholo-data/stapledons-godot/pull/298), [#311](https://github.com/sunholo-data/stapledons-godot/pull/311)), placed around the captain on the bridge with soft footsteps ([#319](https://github.com/sunholo-data/stapledons-godot/pull/319)).
- Resolved star surfaces, the helm's telescope and eclipses ([#302](https://github.com/sunholo-data/stapledons-godot/pull/302), [#315](https://github.com/sunholo-data/stapledons-godot/pull/315), [#316](https://github.com/sunholo-data/stapledons-godot/pull/316)).
- The sound tools on the published `sunholo/audio` package (0.5.0), and AILANG v0.54.18 ([#331](https://github.com/sunholo-data/stapledons-godot/pull/331)).

## Not yet

- Sound for the voyage itself (the drive, arrivals and the rest of the journey's cues) beyond the bridge.
- More of the ship: the decks below the bridge, each with its own fixed views, set dressing and a wider foliage library.

**Releases:** [v0.4.0-dev.36-styled-bridge](https://github.com/sunholo-data/stapledons-godot/releases/tag/v0.4.0-dev.36-styled-bridge), [v0.4.0-dev.37-living-bridge](https://github.com/sunholo-data/stapledons-godot/releases/tag/v0.4.0-dev.37-living-bridge)
