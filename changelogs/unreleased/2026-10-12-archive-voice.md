### Added

- **Ask the Archive** (R1-ARCHIVE-VOICE phase 1, D-67/D-68) at the Archive terminal: type a question, press Ask or Enter. With live AI on (switched on in the AI indicator, with a key), the ship's Archive answers as itself, an artificial mind aboard the bubble ship. It answers from its own entries and a live sensor feed (where the ship is, speed, both clocks, the medium outside, the journey, the news). With AI off, an in-world line answers instead.
- **The Archive's persona** (`data/ai/cast/archive.json`): temperament, manner and the confidences it keeps. Its prompt is its own boot record: no game, no player, the captain, no digits (instruments show every number).
- **Reply filter for every AI line:** a reply that steps outside the ship ("game", "player", "simulation", "language model" ...) or hints at the loop ("previous run", "new game", "multiverse" ...) falls back like a numeral does.
- **Frame-break questions** for the attended live check: `data/ai/archive_frame_break.json`.
- Typing at a terminal no longer triggers the I key or walking.

### Fixed

- **The Archive terminal's layout:** the codex no longer covers the reading row, so Read news, Voyage log, Ask the Archive and Ask stay clickable. The codex, news, log and answer panels all fill the terminal below its two rows, laid out with the terminal.
- **A Codex button** returns from news, the log or an answer to the Archive's entries.
- **The Voyage log lists its entries:** the ship now feeds every sim step to the log (the sim's section carries only the entries since the previous step), so it no longer shows "3 entries" over an empty list. Rows read in words ("Archive entry opened · The Bubble", "Arrived · Sol"), never as sim ids.
- Website: news post "The Archive answers" and three gallery captures (Ask the Archive, the Voyage log, New game); `make ship-ui-capture` gains the `archive_question` and `voyage_log` frames.
