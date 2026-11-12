### Added

- The simulation can now work out what is probably at a world when the ship arrives, from what its light showed and how long the light and the journey take, and what a planned leg costs in Earth years, ship years and mass, exactly as the journey plan states them (R3-REASONS RT3b, `sim/finder.ail`, `make finder-test`). Nothing on screen uses it yet.

### Changed

- `sunholo/worlds` is pinned at 0.2.0 (was 0.1.0) for its prediction maths. Every existing world, census and replay is byte-identical.
