### Added

- Live AI settings, the cost indicator and the game wiring (sprint R1-AI-FOUNDATION AI.9, design (a5)):
  - `AiSettings` (`ui/settings/ai_settings.gd`): live AI stays off until at least one key is present **and** the player ticks the opt-in. Each key comes from `GOOGLE_API_KEY` / `OPENROUTER_API_KEY`, else a pasted key saved to `user://ai_key_gemini` / `user://ai_key_openrouter` with mode 0600. There is one player-set ceiling over both providers (default US$0.50, bounds 0.05 to 20), a text-only toggle and a `--text-only` flag, all persisted in `user://ai_settings.cfg` (never a key). Automation runs (`--capture`, `--map-capture`, `--golden`, `--bench`, `--ai-hello`) never go live.
  - The settings panel (`ui/settings/ai_settings.tscn`) shows which kinds each key enables (OpenRouter: text; Gemini: text, portraits, voice), a price estimate per kind and a plain warning.
  - `AiIndicator` (`ui/ai_indicator.tscn`, its own CanvasLayer) shows the session's running cost per provider and in total against the ceiling, taken from the service's usage lines (charged failures included), and says when the ceiling stops a request. Clicking it opens the settings.
  - `AiSession` (`bridge/ai_session.gd`) wires the settings, `AiBridge`, `AiCache`, `AiRelay` and the indicator into the galaxy map (one `main.gd` hunk), and sends `ai_core` in `new_game`.
- `make ai-live-guard` (part of `make test`, AC15): static rules that no Makefile target, test, CI job or launch path can start a live provider with AI_LIVE=1 (the one exception is `tests/test_ai_relay.gd`'s cleared AI_LIVE), plus 10 guard mutants, and the launch builder run with AI_LIVE unset (stub, `--caps IO,FS`).
- `make ai-settings` (part of `make test`) runs `tests/test_ai_settings.gd`. It covers the opt-in rules, the 0600 key files, the kinds per key, the ceiling, text-only, the panel, the indicator with a `budget` refusal on the stub, and AC14 re-run through the wired path.
- Export: `make ai-runtime` adds `ai/`'s packages (sunholo/gemini_live) to the bundled runtime. `export-macos` also depends on `ai-runtime` and `ai-core-bundle`. The preset bundles `ai/`, `data/ai/` and `ai_core/`. `make export-smoke` gains a stub AI hello from the bundled runtime, with no ailang on PATH (`ai-export-smoke`).

### Fixed

- Live Gemini can no longer bill a gcloud project. On AILANG v0.51 and later, gcloud Application Default Credentials in HOME beat `GOOGLE_API_KEY`. The live launch now binds Gemini with `--ai-key-file <key file>`, and every live launch passes `--ai-no-adc`.
- The live service runs under a minimal environment. The wrapper execs `env -i` with only PATH, HOME, `GOOGLE_APPLICATION_CREDENTIALS=/nonexistent`, the keys read from their files and, only when allowed, AI_LIVE=1. Other `*_API_KEY` variables no longer reach the child.
- A billed reply that fails to parse is now charged. This covers an OpenRouter reply with usage but no content, and TTS speech over its token cap: the call and its reported tokens reach the ledger and `usage.ndjson`. Previously such a reply was dropped. `make ai-loopback` checks both cases, and `make ai-mutants` gains `ai-loopback-mutants`.
- `ai/tools/core_import_test.ail` adds a non-square PNG, so a width/height swap fails a test. It also adds refusals for 0 bytes, height 0, a short source and a commit that is not 40 lowercase hex characters, with 6 new mutants.
