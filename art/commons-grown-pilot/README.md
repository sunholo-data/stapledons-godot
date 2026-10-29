# Grown civic life preview

D-135: Mark asks for the concept's comic aesthetic, long tendril architecture and
a living, breathing Commons, with fewer blank spaces. Distant small buildings
alone did not meet that direction. This revision builds substantial inhabited
middle ground around the existing court, with linked north-west, southern and
east-arcade gathering places.

The previous D-134 backdrop and D-133 furniture remain in both comparison images.
The new image adds:

- Four long rooted tendril arches and four ribbed asymmetric shade canopies.
- Eight 12 m planted islands with integrated seating, 88 new painted plants and
  28 hanging vine cards attached to real soil anchors on the civic fronts.
- Twenty-eight additional furnishings, six table practicals, curved painted
  lanes and four coloured courts across the formerly plain physical floor.
- Forty-two civilian vignettes: meals, conversation, reading, market tending and
  short strolls. The procedural 3D figures are temporary proxies. D-139 requires
  painted characters in the captain's style, with simpler animation and named
  crew mingled among the residents. Preserve the crew's established portrait
  identities. This replacement has not yet been implemented or reviewed.

`placements.json` is the exact composition; `furniture.json` is its extra kit
layer. `commons_civic_pilot.gd` combines the authored assets, ground pigment and
activity in the visual studies. D-136 subsequently authorizes playable review: normal ship entry now loads the same pinned layers from the staged civic bundle, waits for installation, and enables ambient motion subject to the player setting.
Existing WALK, routes, camera rules, deck dimensions, spire and sky are unchanged.
Remote occupied scenery does not add navigation or population/crew simulation.

Actual player captures include Bow/Astern at rest, cruise and a real guided stop,
the under-terrace clamp and bridge rim: 48 matched frames, zero capture errors.
The short moving study adds 64 frames at 8 fps from the fixed Court Astern view.
Its decorative clock is sampled explicitly; normal reduced-motion preferences
still freeze activity. The gallery plays it only after an explicit button click.

```sh
AILANG=runtime/bin/ailang make commons-grown-check
AILANG=runtime/bin/ailang make commons-grown-capture
make commons-grown-golden
AILANG=runtime/bin/ailang make commons-grown-motion
```

The original geometry, route and head/pole/body thresholds pass: 110 checks,
zero failures. Moving the north arch to the west flank kept the body openings
without weakening those thresholds. The six existing CPU/GPU pole cases pass
at maximum 0.103 px error against the unchanged 0.75 px limit. Activity tests
pass 20/0. See `independent-review.md` for the opened-image review and remaining
composition limits. This is a visual candidate, not S3/S5 or finished-level
acceptance; final production performance and rig/CI gates remain open.

Native Blender sources and packed master are preserved in the Blender workspace
and the local ignored `build/commons-grown-source/` archive. Kit pins and measured
bounds are in `kit-source.json`; new foliage provenance is in `foliage-source.json`.
The earlier downloadable native S3 build contains none of these art layers. D-136 creates a separately labelled native civic playtest containing them.
