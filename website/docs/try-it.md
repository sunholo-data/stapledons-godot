---
title: Try it
sidebar_position: 6
description: How to run Stapledon's Voyage - the macOS review build or a build from source.
---

# Try it

Stapledon's Voyage is **pre-alpha**. There is no release for players yet. There are review
builds and the source.

## Review build (macOS, Apple Silicon)

The [GitHub releases](https://github.com/sunholo-data/stapledons-godot/releases) page has
review builds of the journey core. The latest opens on the galaxy map: click a star, set the
speed, click **Commit…** and hold for 1.5 s, watch the transit (Cancel is refused), and arrive.

The build is unsigned. On first launch, clear the quarantine flag once, adjusting the path:

```bash
xattr -dr com.apple.quarantine ~/Downloads/"Stapledons Voyage.app"
```

The sky flight (the relativistic voyage in the videos) is in the same app:

```bash
open -a "Stapledons Voyage.app" --args -- --voyage
```

Review builds lag `main`, so they may not have every sky feature shown on this site. Check the
release notes.

## From source

You need Godot 4.7 or later and AILANG on your `PATH` (the version the repo pins; see its
`CLAUDE.md`).

```bash
git clone https://github.com/sunholo-data/stapledons-godot.git
cd stapledons-godot
make import                      # register the scripts once after cloning
make sky-assets                  # the Milky Way textures (~164 MB, from the public bucket)
make catalogue-inputs            # the star catalogues
make catalogue TIER=large        # build the 331k-row tier on the AILANG VM (about a minute)
make run                         # the galaxy map
make voyage                      # the sky flight
```

In the sky flight: **W**/**S** thrust at 1 g, arrows look around, **Q**/**E** roll, **1**–**4**
look forward, starboard, astern and up, **+**/**−** time warp. **F** fixes the exposure and **M**
switches eye and camera metering.

`make test` runs the headless test suite; `make capture` renders the reference images.
