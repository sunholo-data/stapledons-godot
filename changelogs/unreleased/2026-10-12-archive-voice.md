### Added

- **Ask the Archive** (R1-ARCHIVE-VOICE phase 1, D-67/D-68) at the Archive terminal: type a question, press Ask or Enter. With live AI on (switched on in the AI indicator, with a key), the ship's Archive answers as itself, an artificial mind aboard the bubble ship. It answers from its own entries and a live sensor feed (where the ship is, speed, both clocks, the medium outside, the journey, the news). With AI off, an in-world line answers instead.
- **The Archive's persona** (`data/ai/cast/archive.json`): temperament, manner and the confidences it keeps. Its prompt is its own boot record: no game, no player, the captain, no digits (instruments show every number).
- **Reply filter for every AI line:** a reply that steps outside the ship ("game", "player", "simulation", "language model" ...) or hints at the loop ("previous run", "new game", "multiverse" ...) falls back like a numeral does.
- **Frame-break questions** for the attended live check: `data/ai/archive_frame_break.json`.
- Typing at a terminal no longer triggers the I key or walking.
