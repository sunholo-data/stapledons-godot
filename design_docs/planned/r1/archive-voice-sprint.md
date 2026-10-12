# Sprint R1-ARCHIVE-VOICE (phase 1): plan

Design: [archive-voice.md](archive-voice.md). Approved for execution by Mark on 2026-10-12, in the same request that asked for the design. Target: tonight's dev build, for Mark to test in the morning.

| Milestone | What | Files | ~LOC | Check |
|---|---|---|---|---|
| AV1 | Persona file, canon entries, relay passes persona/style/secrets | data/ai/cast/archive.json, data/ai/lore.json, bridge/ai_relay.gd | 60 | ai-godot, ai-relay |
| AV2 | In-world archive prompt (boot record) + tests + goldens | ai/prompt.ail, ai/prompt_test.ail, tests/ai/prompts/archive.golden.txt | 80 | ai-pkg-test, ai-adapter |
| AV3 | Reply filter: out-of-world and loop words to bad_output + tests + mutant | ai/reply.ail, ai/reply_test.ail, mk/ai.mk | 70 | ai-pkg-test, ai-mutants |
| AV4 | AiSession in the ship journey session | demos/ship_geometry_demo.gd | 20 | ship-console-test, title-screen-test |
| AV5 | Ask the Archive at the terminal: field, Ask, sensor feed, answer, in-world fallback + tests | demos/ship_consoles.gd, tests/test_ship_consoles.gd | 140 | ship-console-test |
| AV6 | Frame-break question set (data, for the attended run), voice check scans the archive golden, changelog | data/ai/archive_frame_break.json, Makefile, changelogs | 40 | in-world-voice-check |

Order: AV1 → AV2 → AV3 (AILANG side), then AV4 → AV5 (Godot side), then AV6. Then a full `make test` and an independent evaluation (Sonnet), then the PR and the dev build.

Risks: re-recorded AI goldens (stub results carry a prompt-length cost); the ship session gains `ai_core`, which may change recorded ship sessions (check `parity-m4`, `session-audit-test`).
