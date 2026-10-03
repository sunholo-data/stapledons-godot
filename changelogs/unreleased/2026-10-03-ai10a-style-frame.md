### Added

- The Medic conversation (AI.10a, rehearsed on the stub; no live call): `godot --path . res://ui/conversation/conversation.tscn -- --conversation=medic`. A large portrait crossfades between the Medic's accepted portraits as the line's emotion markers change, the subtitle is revealed segment by segment, and the voice line plays. The swaps happen at the voice's exact segment offsets (`segments_ms`), optionally led by 150 ms (`--swap-offset-ms=-150`); the crossfade length is a parameter (`--crossfade-ms`, default 120). A missing emotion falls back along the portrait chain, and a missing voice degrades to text with `missing_blob` logged. The scene reads only the sim's `ai_accepted` events and the cache, either from a replayed log (`--log=`, no AI process) or from a stub rehearsal.
- `data/ai/cast/medic.json`: the Medic's cast entry (departure age 35, persona, voice `Aoede` pending Mark's choice, delivery style, core portrait keys). The relay now takes the cast it sends with each request from `data/ai/cast/`.
- `tests/replays/medic_rehearsal.ndjson` (with per-arch goldens): one Medic line with emotions neutral, loving and grieving, and its voice, recorded on the stub. `make ai-conversation` (in `make test`) re-records it byte for byte and checks the swap timing, crossfade, fallbacks and the no-audio path; `make ai-rehearsal-record` re-records it.
- `make ai-style-frame` (GPU window, never in `make test`): replays a log through the conversation and writes `renders/ai_medic/` (a PNG at each swap, `contact_sheet.png`, `line.ogg`, `line.wav`, `timeline.json`, and `frame.avi` with audio from Godot's movie writer). On the rehearsal it first re-records the stub session to get the blobs.

### Changed

- The AI service's voice index lines now carry `duration_ms` and `segments_ms`, so a voice line already in the player's library is a cache hit instead of being generated (and paid for) again.
- Every voice blob now has a WAV playback copy beside it (the same PCM). Godot 4.7 plays WAV and Ogg Vorbis, not Ogg Opus; the Ogg Opus blob stays the canonical, hashed asset the sim validates.

### Fixed

- The stub voice of a long segment (more than about a thousand tone periods, e.g. a grieving segment of 43 characters) made the service silently drop the request on the bytecode VM: no result, no error. The tone is now built by doubling, which gives the same bytes. Reported upstream.
