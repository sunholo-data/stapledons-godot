# Attended civic playtest assets

The user approved the reviewed appearance for a playable build. This packaging
step does not close S3/S5 or approve a merge or full-level propagation.

`make commons-civic-stage` verifies `source-pins.json`, then generates four
rewritten configs and a byte-hash manifest in ignored
`assets/levels/commons/civic/`. Three raw GLBs, trailing vines and the three floor
pigments go in ignored `ship_commons_bundle/civic/`. GLBs and PNGs receive a `.bin` suffix so Godot does not import them. Neither
staged directory carries `.gdignore`: actual export skipped those directories
entirely despite includes. Explicit `assets/levels/commons/civic/*` and
`ship_commons_bundle/civic/*` includes preserve the original bytes. Runtime GLTF
loads from buffers; PNGs use `Image.load_png_from_buffer`. Staging removes only
its known obsolete raw filenames/import sidecars and old `.gdignore` markers.
No masters, generators, studio images or source archives are staged.

The runtime root is `res://assets/levels/commons/civic/placements.json`.
`base_config`, `base_configs`, `extra_art` and `source_glb` references are rewritten
to staged paths. `vine_texture`, `ground_textures` and the corresponding pigment
hashes point to raw bundled `.png.bin` bytes. Source placement/activity arrays are preserved.

`make export-macos` and `make export-pack-check` always require staging first.
`make commons-civic-assets-check` verifies real raw GLB/PNG decoding and the
transitive export graph, including dropped/corrupt files and an authoring-path
leak with otherwise consistent hashes. The actual export-pack gate also runs
the independent civic closure/hash audit.

Reviewed source changes require an intentional update to the corresponding
`source-pins.json` SHA256 entry before staging. A mismatched or missing input
fails before output is written; an old staged bundle cannot silently substitute
for a failed prebuild. Generated files remain ignored so staging does not dirty
the tracked checkout before the review export's clean-source gate.
