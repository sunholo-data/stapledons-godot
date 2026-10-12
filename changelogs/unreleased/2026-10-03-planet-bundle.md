### Added

- Planet textures ship in exported builds. `make planet-bundle` fetches the pinned Solar System Scope textures (bucket, else source), checks them against `data/planets/SHA256SUMS`, and stages them as `planet_bundle/<file>.bin`. `make export-macos` (and so the release workflow and `make publish-dev`) depends on it, and the build FAILS if any texture is missing. The export filter now carries `planet_bundle/*` and `data/planets/*` (ALBEDO, CREDITS).
- `SystemView.load_texture_image` reads `assets/planets` in a source checkout and the bundle in an export.
- `--planet-smoke=PNG` (`planets/planet_smoke.gd`) and `make export-smoke-planets` (run by `make publish-dev`): the exported app must load all nine textures from its bundle and draw a textured Jupiter.
- `tests/test_planets.gd` checks the export filter and that a bundled copy decodes like the source.
