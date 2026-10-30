# Low-console contact pilot (VFB, D-121)

**Review proposal only.** The playable game has not changed. Navigation and Archive
contacts remain outside this first low-console pilot. VFB is not complete until
those contacts and the complete bridge finish are assessed and the proposal is
reviewed.

D-121 deferred the accepted held poses' front-facing hand/furniture mismatch.
Read-only Blender inspection measured the authored low-console operator points
1.17 m stern of the existing desk edge. Translating/scaling the approved console
would change the layout and its operator relationship. This pilot adds two narrow,
curved teal return rails to each Voyage/Crew desk, ending in rounded ochre palm
rests. All 183 original Blender objects and transforms are preserved. Existing
WALK, collision, camera, lighting, UI, textures, avatar sprites and operator points
are unchanged. The pilot is loaded only by the review harness.

The additive GLB is 85,212 bytes with two opaque palette materials. Blender source
is the distinct `~/dev/blender/scenes/stapledon_bridge_contact_pilot_v1.blend`,
with embedded generator `stapledon_bridge_contact_pilot_v1.py`; the corresponding
script is in that workspace's `scripts/`. Input/output SHA-256 pins and station
coordinates are in `bridge-contact-pilot.json`. A separate local source snapshot
exists at `build/view-finish-contact-source.tar.gz`; it is not remotely backed up.
No original Blender scene was overwritten.

## Review evidence

GPU harness: `godot --path . --script tools/bridge_contact_review.gd`.
Outputs: `renders/view-finish/contact-pilot/` with 8 matched 1280x720 player frames,
2x enlarged detail crops, a sheet and `review.json` recording the exact feet,
facings and camera transforms. Sheet rows are Voyage then Crew. Columns are
Astern current/proposal, Bow current/proposal. These are actual in-engine images,
not paintovers. The proposed GLB receives the game's existing toon/ink material.

Both front- and back-facing crops were opened and inspected: the palms meet the
new ochre rests, without moving the captain. The rail proportions/materials still
need Mark's visual sign-off. The current lift blocks part of the Crew captain's
lower body from Bow; this is existing baseline composition, not corrected here.
The first pilot is at 1280x720/rest; remaining resolution/light/console coverage
and full performance/evaluation gates are not claimed.

Headless guard: `godot --headless --path . --script tests/test_bridge_contact_pilot.gd`.
It checks content pin, unchanged authored operator points, both paintings' manually
annotated palm landmarks against actual imported rest bounds (within 6 cm), opaque
non-emissive surfaces and a <5k triangle limit. Raising the annotated palms 30 cm
must fail the support predicate. The guard measures physical placement; it does
not substitute for the opened player-camera images.

The first capture returned 0 and 8 frames without script errors. It reported
existing theme-image import warnings and shutdown RID leaks. The review harness
now queues the demo for deletion and drains frames on exit. Its headless sheet
mode (`-- --sheet-only`) avoids taking a GPU slot to regenerate the sheet.

The proposal's larger curved controller loops are a visible style change and are
**optional**, even though the contact improves. Approve or reject their silhouette
on the before/after pairs; they will not be installed automatically. The source
snapshot SHA-256 is
`1ed21ff91448f37e3bbe0c64433540a70c0af567fcb468aa9e127d824bba02d5`.
Frames retain the game's +2-stop (4x) sky display aid, no HUD, frozen rest world.
This affects the sky display, not physics or the matched furniture comparison.

## Targeted verification

- Contact pilot guard: 33 passed, 0 failures, including raised-palm negatives.
- `make deck-assets-check deck-layout-eval style-test dressing-test`: passed;
  bad-pin and emissive-asset controls fail as expected; style 22/22, dressing 10/10.
- Initial `ship-console-test`: 131 passed, one missing-cache prerequisite failure;
  fetched the public content-addressed baseline before rerunning. Final outcome
  is recorded by the coordinator with the integration evidence.
- `godot --headless --path . --check-only --script tools/bridge_contact_review.gd`:
  parsed successfully. Headless sheet assembly ran without errors after converting
  loaded RGB frames to the sheet's RGBA format.

Source-only `.blend` snapshots should be kept under a directory containing
`.gdignore` so Godot does not try to import recovered authoring masters.

Final console rerun: `make ship-baseline ship-console-test` passed, 133 passed and
0 failures after fetching the three pinned baseline files. The master also passed
Blender `make inspect SCENE=stapledon_bridge_contact_pilot_v1` with no missing
external files. Its inherited Cycles setting is CPU; no Blender render was run
(the visual evidence is from the actual Godot player camera). Clean GLB reimport
uses an empty Blender scene, with explicit nonzero assertion exit status.
The clean additive GLB contains 8 mesh components, 2 materials and 3,776 triangles.
