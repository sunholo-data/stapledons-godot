### Changed

- Display audit cross-checks each recorded binding context (row 7i(g)): a shared path that
  disagrees with the frame view fails `context-drift`; a context-only `client.*` path must match
  its producer (`context-source`: target id, catalogue distance with required presence, star
  count and radius, zoom rate, hold time, Archive and Crew counts); anything else fails
  `context-unknown`. The only allowlisted path is `client.map.target_name`. Six new control
  fixtures, three edited.

### Fixed

- The galaxy map's clock line could stay one or two ticks behind the frame after a pipelined
  heartbeat or a console send advanced the world without a refresh (the AI-stub playthrough
  caught it). `GalaxyMap._process` now refreshes when its tick differs from the world's.
