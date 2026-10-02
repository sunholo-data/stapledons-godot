# Sprint plan: R1-AI-FOUNDATION, a recorded, replayable AI service

> **APPROVED by Mark, attended 2026-10-02** ("Approve, start wave A1"), running in parallel with R1-M1-SKY-2. Defaults accepted: ceiling range $0.05–20 persisted; Medic set in the public assets bucket; cheapest fixture-passing OpenRouter text model proposed and confirmed at ⏸ C; $5 OpenRouter credit limit on the build key; AI.3 merges before M1.7. The `openrouter-api-key` secret already exists (empty, PR #49).

**Status:** Approved 2026-10-02, executing wave A1. AI.1 (markers) is executed
on `sprint/ai1-markers` and awaits independent evaluation. Planned 2026-10-02 on
`origin/main` `a50bea2`.

## Summary

Build the AI service foundation (ledger D-9): a separate AILANG process
`ai/service.ail` that Godot launches, supervises and relays, routing each
request kind to **OpenRouter or Gemini** (text via OpenRouter by default,
portraits and voice via Gemini; Mark's plan change of 2026-10-02); protocol **2.1**,
in which the pure sim opens AI requests, validates every result and closes
each request exactly once; a layered, content-addressed cache; the
emotion-marker grammar `{emotion}`, parsed once in the sim; key and spend UX
under D-8/D-20; and the Medic style frame, which **stops for Mark**.

Mark approved planning on 2026-10-02 (D-20: "plan the AI foundation sprint now
to run alongside M1"). This sprint is sequenced to share the repo with
`R1-M1-SKY-2` ([m1-remaining-sprint.md](m1-remaining-sprint.md)) with as few
file conflicts as possible: see [Sequencing against M1](#sequencing-against-m1).

**Design doc:** [ai-service-foundation.md](ai-service-foundation.md)
(AC1–AC20; open questions 1–9 resolved by D-20: see the
[ruling table](#d-20-rulings-applied)).
**Sprint ID:** `R1-AI-FOUNDATION` · **Progress file:** `.ailang/state/sprints/sprint_R1-AI-FOUNDATION.json`
**Duration:** 11 milestones in 7 waves, each milestone one iteration. That is
**~14–18 h of attended execution (about 2 working days)** with parallel
executors, or **~4–5 days on the loop**, plus Mark's time at the golden review
(G21) and the style-frame stop (⏸ C). One milestone (AI.10b) can only run
attended, because it spends.
**Dependencies:** M2 (landed). Not M1, not M4. AILANG **v0.51.0** (Makefile
`AILANG_RELEASE`, CI, lockfile). `sunholo/gemini_live@0.5.0` (registry, see the
reuse gate). The build keys in Secret Manager, project `stapledons-voyage`:
`gemini-api-key` (exists, `infra/gcp/setup.sh` §8) and `openrouter-api-key`
(value supplied by Mark), for AI.10b only.
**Risk level:** Medium. The sim side follows M2's patterns exactly. The risks
are the non-blocking pipe in Godot, the golden re-record racing M1.7, the
direct HTTP TTS adapter (no TTS in `std/ai`, ailang#1495), and the first live
spend.

**Command legend** (as in M1/M2).
- `$A` = `/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
  AILANG **v0.51.0**. A fresh worktree runs `make runtime` first. Every make
  line passes `AILANG=$A` (and `AILANG_BIN=$A` where Godot starts a child).
- `godot` = the 4.7.2 binary the Makefile uses (`$(GODOT)`).
- `$S` = the stub suite's scratch dir, `.godot/tmp/ai`.
- **No command in this plan, except those in AI.10b, can spend money.** CI,
  `make test`, the executor and the loop run the stub with `--caps IO,FS`.

## D-20 rulings applied

| Design OQ | Ruling (D-20, Mark attended 2026-10-02) | Where it lands |
|---|---|---|
| 1 AI intents while committed | Accepted; only **journey** intents refused. M2 AC7 narrows to "every journey intent" | AI.2 (code, `checkCommittedRefusesAll` rewrite, `checkAiNeverTouchesJourney`, the M2 doc's AC7 wording) |
| 2 Core content | Bundle (design default accepted) | AI.8, AI.9 (export) |
| 3 Player key | `GOOGLE_API_KEY` env or `user://ai_key` mode 0600 in R1 | AI.9 |
| 4 Spend ceiling | **Player-set** in Settings, default **US$0.50** | AI.5 (`spend.ail`), AI.9 (Settings) |
| 5 Who pays | Project key in Secret Manager `gemini-api-key` (project `stapledons-voyage`), budget alert 140 DKK/month; **the unattended loop never spends** | AI.9 (`ai-live-guard`), AI.10b (`make ai-live`, attended only) |
| 6 Marker syntax | `{emotion}` | AI.1 |
| 7 TTS granularity | Per segment, concatenated | AI.10a |
| 8 Medic emotions | The line is limited to neutral, loving, grieving; the other five are commissioned separately | AI.10b |
| 9 Voice | Aoede after an audition (three voices) | AI.10b, ⏸ C |

### Plan change: both providers (Mark, attended 2026-10-02)

Mark: "so have both options - the ailang demos use them all". Facts on the
v0.51.0 pin (checked in the AILANG source by the coordinator:
`cmd/ailang/ai_handlers.go`, `internal/ai/openrouter`): OpenRouter is built in
for **text** (chat completions) and vision input, with model names
`vendor/model` or `openrouter:vendor/model` and a routing policy. It **refuses
image generation** ("use a Gemini image model"). Nothing in `std/ai` does TTS
(ailang#1495). A feature request for OpenRouter image output has been filed
upstream.

| Change | Where it lands |
|---|---|
| **Provider routing config** `data/ai/routing.json`: per request kind an ordered list of `{provider, model}`. Defaults: `text` (line, news, archive) → OpenRouter first (cost), then Gemini; `portrait` and `avatar` → Gemini only; `voice` → Gemini only (TTS). A kind whose route has no usable key falls back to text-only/templates (`ai_cancel{no_key}`). Both keys are optional | AI.4 (pure `ai/route.ail` + data), AI.5 (adapters), AI.7 (relay uses the resolved route) |
| `Provider = Stub \| Gemini \| OpenRouter`. OpenRouter text goes through `std/ai.step` with an `openrouter:vendor/model` id; the service refuses a provider whose key env var is empty (`OPENROUTER_API_KEY`, `GOOGLE_API_KEY`) before any call | AI.5 |
| **Stub tests cover both routes**: the stub answers as `stub` with `meta.route` = the provider the routing table chose, so `ai-stub` goldens show text routed to OpenRouter, to Gemini (OpenRouter key absent), and to text-only (no keys), and portraits/voice always to Gemini; the `--ai-stub` lane runs the OpenRouter text adapter too | AI.4, AI.5 |
| **Build key** for OpenRouter: Secret Manager `openrouter-api-key` in project `stapledons-voyage`, beside `gemini-api-key`. **Mark supplies the value** (it can't be created with gcloud); the controller creates the empty secret and documents it in `infra/gcp/setup.sh` §8 and `infra/gcp/README.md`. Either secret may be missing; `make ai-live` passes whichever exist | AI.8 (infra doc + secret container, attended), AI.10b |
| **Player settings accept either or both keys**: env `GOOGLE_API_KEY` / `OPENROUTER_API_KEY`, or pasted keys in `user://ai_key_gemini` / `user://ai_key_openrouter` (each 0600). Settings shows which kinds each key enables | AI.9 |
| **Cost per provider**: `prices.json` keyed by provider and model; the spend ledger and `usage.ndjson` keep per-provider totals; the indicator shows the running cost per provider and the total; the **one** player-set ceiling (default US$0.50) applies to the sum | AI.5 (`spend.ail`), AI.9 (indicator) |
| Launch wrapper takes up to two key files; `--net-allow-domains generativelanguage.googleapis.com,openrouter.ai`; ADC guard unchanged; `ai-live-guard` covers every non-stub provider; key hygiene (AC14) covers both keys | AI.5, AI.7, AI.9 |

The design doc's goals ("model-neutral, Gemini as default", D-8 (2)) are
narrowed by this change for text. AI.4's task 0 adds a dated amendment
section to the design doc (docs only; the ACs below already carry the
change), and the ruling should be recorded in the ledger (Q1).

## Current status analysis

### What exists (main at `a50bea2`)
- `sim/protocol.ail` (333 lines): protocol 2.0, `helloMsg` minor 0; the
  reserved `record` intent decodes (`:168-169`). `sim/core.ail` (416 lines):
  `IRecord` refused `unsupported` (`:254`), or `committed` in transit through
  `refuseWhileCommitted` (`:165-174`, one arm per constructor, no wildcard).
- `sim/rng.ail`: stream 5 (`ai`) exists and is unused; the full state already
  prints `rng.ai: 0`.
- `sim/core_test.ail:332` `checkCommittedRefusesAll`, test name at `:658`
  "AC7 committed world refuses every intent kind".
- `bridge/sim_bridge.gd` (300 lines): `execute_with_pipe(..., false)`, the
  `record_path` tee, `last_events`, bundled-runtime `HOME` trick in
  `_run_args`. No M1 milestone touches `bridge/`.
- `tools/replay.py` (harness) + `tools/test_replay.py`; goldens per arch in
  `tests/replays/` (four logs with full goldens, `diag_thrust600` and the
  sessions as sha256). **No replay log contains a `record` intent** (checked:
  `grep '"record"' tests/replays/*.ndjson` and `tools/gen_session.py` are
  empty), so 2.1's new `record` handling cannot move an existing golden.
- No `ai/` package, no `ui/conversation/`, no settings UI. `main.gd` is the
  entry (`run/main_scene`), and the galaxy map is the default launch.
- The Makefile has no `include`; `test:` has prerequisites only, no recipe.

### Velocity (from the M1-SKY-2 plan, verified against the mission log)

| Sprint | Milestones | Wall clock | Evals | Counted LOC |
|---|---|---|---|---|
| R1-M1-SKY iterations 0–8 (unattended loop, 250 cap) | 9 | 5 days | 85–98 | 130–670 each; estimate ratio median ~1.0× |
| R1-M2-JOURNEY (attended, parallel executors, 650 cap) | 10 | ~13.5 h | 89–96 | ~5,000 changed lines vs ~3,400 estimate (~1.5×) |

Planning figures: **cap 650** counted code + test + config LOC per milestone
(fixtures, goldens, generated files, data and docs don't count); every
milestone is planned at ≤ 550, so a 1.15× overrun still fits (AI.4 is the
largest; if it runs over, `ai/route.ail` moves to AI.5). About 2 h per
milestone including independent evaluation, run in waves of disjoint files.

**Total: 3,760 counted LOC** across 11 milestones. The design says ≈3,150.
The +610 is the OpenRouter route (+190: routing, adapter, per-provider spend,
two-key settings and hygiene) plus work the design implies but doesn't count: the replay-compat
harness and frozen 2.0 baselines (AI.3), the SimBridge relay hook and a
separate AI session recorder (AI.7), the game wiring and export bundling of
`ai/` (AI.9), and the attended live-session script (AI.10b). At M2's 1.5×
ratio, expect 5–6k changed lines.

### Registry reuse gate (searched 2026-10-02 with `$A pkg search`, v0.51.0)

Searched: `ai`, `gemini`, `tts`, `speech`, `audio`, `voice`, `ogg`, `opus`,
`image`, `cache`, `blob`, `sha256`, `hash`, `ndjson`, `supervisor`, `process`,
`stub`, `prompt`, `cost`, `pricing`, `spend`, `budget`, `key`, `secret`,
`markup`, `emotion`, `grammar`, `parser`.

| Milestone | Package | Action | Reason |
|---|---|---|---|
| AI.1 | none | none | `markup`/`emotion`/`grammar` found nothing; `parser` found only `gemini_live` (Gemini message parsers) and `external_backend`. The grammar is game-specific and must run in the pure sim on the strict VM |
| AI.2 | std/json, std/crypto (bundled) | depend | Codecs follow M2's hand-written pattern on std/json; seeds from the in-tree `sim/rng.ail` stream 5. No registry package applies (ADR 0001) |
| AI.3 | std/crypto (bundled) | depend | `sha256Hex` is pure and strict-clean (design V2, V5). `sha256`/`hash` found only `sunholo/auth` (constant-time key compare) and `registry_validator` |
| AI.4 | std/json, std/fs, std/crypto (bundled) | depend | Service loop, wire and cache writer; `cache`/`blob`/`ndjson`/`stub` found nothing applicable (`ollama_stream` is an Ollama client) |
| AI.5 | **`sunholo/gemini_live@0.5.0`**; std/ai (built-in OpenRouter and Google providers) | **depend** | OpenRouter text needs no package: `std/ai.step` with an `openrouter:vendor/model` id (built into v0.51.0). Its pure `tts` module (`buildTtsRequest`, `ttsAudioOf`, `outputTokensOf`, `finishReasonOf`, `completeOk`) builds and checks batch TTS `generateContent` bodies, with a provider-enforced `maxOutputTokens` ceiling; we POST it with `std/net.httpRequest` until ailang#1495 lands. Text/image use `std/ai` as designed. Its endpoints are Vertex (ADC) or a Live WebSocket URL carrying the key in the query string, so the AI Studio REST URL (key in an `x-goog-api-key` header) stays local. **Optional contribute** (non-blocking): a `googleAiGenerateContentUrl` helper via the `pkg:gemini_live` inbox |
| AI.6 | none | none | GDScript supervision; `supervisor`/`process` found `duckdb` and `external_backend` (blocking `std/process.exec` wrappers), not applicable to a Godot-owned child |
| AI.7 | none | none | GDScript relay and cache reader |
| AI.8 | std/crypto, std/fs (bundled) | depend | `core_import.ail` hashes with `sha256Bytes` (Python policy); bucket pattern from `make sky-*` (D-18) |
| AI.9 | none | none | Godot UI; `key`/`secret` found `sunholo/auth` (server-side key compare), not key storage |
| AI.10a | std/audio (bundled), `sunholo/gemini_live@0.5.0` | depend | `std/audio.encode(OggOpus(24000))`, `durationMs`; TTS bodies from `gemini_live/tts` (as AI.5) |
| AI.10b | none | none | Attended run, capture and landing |

### Findings made while planning (2026-10-02)

1. **TTS has a registry home today.** `sunholo/gemini_live@0.5.0` (published
   2026-09-26) ships a pure batch-TTS module, measured against Vertex. The
   design's "HTTP adapter until G1" becomes: request body and response checks
   from `gemini_live/tts`, transport by `std/net.httpRequest` to
   `generativelanguage.googleapis.com`. This removes most of the adapter's own
   parsing code and gives a real spend ceiling per call (`maxOutputTokens`).
   The package documents Vertex model ids (`gemini-2.5-flash-tts`, …); the
   AI Studio id in `data/ai/models.json` is verified in AI.10b's attended run.
2. **Full states will change in a third place, not two.** The design says the
   re-recorded 2.0 goldens differ "only in the hello `minor` and the full
   state's `ai` section" (AC13). But `ai_max_open` and `ai_ttl_ticks` are
   scenario parameters, and the full state prints the whole `params` section.
   **Plan:** append them as the last two keys of `params` and the `ai` section
   as the last section of a full state. `replay-compat` strips exactly those
   three things (hello minor → 0, the two `params` keys, the `ai` section)
   and requires byte equality with the frozen 2.0 output. AC13's wording
   gains the two keys. Nothing else may differ.
3. **`replay-compat` needs frozen baselines, not git history.** CI checks out
   with depth 1, and the 10k session golden is a sha256, which can't be
   field-stripped. **Plan:** AI.3 copies today's 2.0 goldens into
   `tests/replays/compat-2.0/` (uncounted fixtures). The harness re-runs each
   log on 2.1, strips the three fields, and compares with `cmp` or, for
   digest goldens, compares `sha256(stripped)` with the 2.0 digest. A log
   whose **input** changed after the freeze (M1.7 re-keys `alpha_cen` and
   `godot_map_voyage`) is reported `skipped: input changed since 2.0 freeze`,
   never silently passed.
4. **Make can add prerequisites without editing the `test:` line.** `test:`
   has no recipe, so `mk/ai.mk` can say `test: ai-test` and the AI suite
   joins `make test` with **one** Makefile edit for the whole sprint:
   `include mk/ai.mk` at the end. Every AI target, including the strict-VM
   entries (`strict-ai`), lives in `mk/ai.mk`. The same works for
   `export-macos: ai-runtime`. This removes the main conflict surface with
   M1, whose every wave edits the Makefile.
5. **Ledger row D-20's text was mangled by shell expansion.** It reads
   "a ~US/month budget alert" and "default US/bin/zsh.50": `$20` expanded to
   empty and `$0` to the shell's name. The ruling's meaning is clear from the
   design doc and `infra/gcp/README.md` (US$20 ≈ 140 DKK; US$0.50), and this
   plan uses those values. The fix is an attended ledger edit (Q1).
6. **The 140 DKK budget is an alert, not a cap.** `gcloud billing budgets`
   notifies; it does not stop spend. The hard stops are the service's
   `--ceiling-usd`, the `@limit=3` AI budget per handler, `maxOutputTokens`
   per TTS call, and the rule that only AI.10b, attended, can ever start a
   paid provider.
7. **The bridge hook goes in `bridge/sim_bridge.gd`, not `main.gd`.** The
   relay has to see `last_events` after each `send` and put queued intents on
   the next one. A ~15-line optional hook in `SimBridge` (`ai_relay`, used
   only when set) does that. `main.gd` gets one small wiring hunk late in the
   sprint (AI.9). M1 edits `main.gd` in waves 1, 4, 5 and 6, but never
   `bridge/`.

## Sequencing against M1

Files M1-SKY-2 touches (from its JSON): `main.gd`, `Makefile`,
`sim/core_test.ail` (M1.6b, M1.7), `tests/test_physics.gd`, `sky/*`,
`physics/blackbody.gd`, `ui/galaxy_map.gd` (M1.7),
`tools/record_godot_session.gd` (M1.7), `tests/replays/*` goldens (M1.7),
`sim/tools/*`, `data/starmap/*`, `data/sky/*`, `sim/ailang.toml`/`.lock`
(M1.P).

| Shared file | AI milestone | Rule |
|---|---|---|
| `Makefile` | AI.1 only | One line, `include mk/ai.mk`, at the end. Everything else is in `mk/ai.mk` (finding 4) |
| `sim/core_test.ail` | AI.2 only | Edit only the body of `checkCommittedRefusesAll` and its test name (`:332`, `:658`). New tests go in `sim/ai_test.ail`. M1.6b and M1.7 append; different hunks |
| `tests/replays/*` goldens | AI.3 | **AI.3 merges before M1.7 starts** (M1 wave 5). AI.3 runs in AI wave 2, while M1 is in waves 2–3, so this holds unless M1 runs far ahead. If M1.7 starts first, AI.3's re-record waits for M1.7's merge (R-c) and re-records on top; the compat baseline is then taken after M1.7 |
| `sim/ailang.toml`/`.lock` | none | The AI service is its own package with its own lock (`ai/ailang.lock`); the sim gains no dependency. M1.P owns the sim lock |
| `main.gd` | AI.9 only | One hunk of ≤ 15 lines next to the existing `sim.record_path = …` lines (`:64`, `:87`), which no M1 milestone edits. Rebase onto whatever M1 has merged; never open while an M1 PR holding `main.gd` is in review, if avoidable |
| `ui/galaxy_map.gd` | none | Settings opens from the AI indicator's own CanvasLayer, not a map button |
| `tools/record_godot_session.gd` | none | AI.7 writes a separate `tools/record_ai_session.gd` |
| `sim/protocol.ail`, `sim/core.ail`, `bridge/*`, `ui/conversation/`, `ui/settings/`, `ai/`, `data/ai/` | AI only | M1 never touches these |

**Wave alignment** (attended, parallel executors; AI waves can slip
relative to M1 freely except where marked):

| AI wave | Milestones | Runs beside M1 wave | Constraint |
|---|---|---|---|
| A1 | AI.1, AI.2 | 1 (T3, M1.6b, M1.P) | AI.2 vs M1.6b in `sim/core_test.ail`: different hunks |
| A2 | AI.3, AI.4 | 2–3 (T4, M1.2c) | **AI.3 merges before M1.7 starts** |
| A3 | AI.5, AI.6 | 3–4 | none |
| A4 | AI.7, AI.8 | 4 (M1.2d, M1.3) | none |
| A5 | AI.9 | 4–5 | `main.gd` hunk rule |
| A6 | AI.10a | 5–6 | none (GPU capture shares the Studio's GPU window with M1's gates: run serially) |
| A7 | AI.10b ⏸ C | any | attended only; Mark's review |

## Execution order and pause points

```
AI.1 markers (b) ──────────────┐
AI.2 protocol 2.1 codecs + ai ─┴── AI.3 record validation, minor 1, goldens ──⏸ G21 (golden review)
        └── AI.4 service + stub ──┬── AI.5 prompt/spend/adapters ─┐
                                  ├── AI.6 AiBridge + faults ─────┼── AI.7 relay + cache + E2E ── AI.9 settings/key/ceiling/wiring ── AI.10a style frame (stub) ── AI.10b live line ──⏸ C (Mark)
                                  └── AI.8 core layer ───────────────────────────────────┘
```

| # | Wave | Milestone | LOC | Depends on | Pause after |
|---|---|---|---|---|---|
| 1 | A1 | AI.1 marker grammar, parser, styles, fallback table, `mk/ai.mk` | 300 | — | — |
| 2 | A1 | AI.2 protocol 2.1 codecs, `sim/ai.ail` (open/cancel/expiry/ids/seeds), commit rule + M2 AC7 change; **no wire change for 2.0 logs** | 430 | — | — |
| 3 | A2 | AI.3 record validation, hello minor 1, full-state `ai`, golden re-record, `replay-compat`, `ai_sim_session` | 400 | AI.1, AI.2 | **⏸ G21** golden review (blocks AI.3 merge) |
| 4 | A2 | AI.4 `ai/` package: wire, key, **provider routing**, stub (text, image) over both routes, cache writer, service loop, `ai-stub` | 550 | AI.2 | — |
| 5 | A3 | AI.5 prompt goldens, per-provider spend + ceiling, OpenRouter text and Gemini text/image/TTS adapters on fixtures, stub voice, `ai-adapter` | 460 | AI.4 | — |
| 6 | A3 | AI.6 `AiBridge`: non-blocking pipe, priority queue, timeouts, backoff, `service_down`; fake service | 340 | AI.4 | — |
| 7 | A4 | AI.7 `AiRelay`, `AiCache`, SimBridge hook, E2E, news interface, key hygiene (both keys), `ai_stub_session`, `replay-noai` | 390 | AI.3 merged, AI.5, AI.6 | — |
| 8 | A4 | AI.8 core layer: `core_import.ail`, `data/ai/core/`, `ai-core-*` targets | 160 | AI.4 | **P-pub** controller publishes the Medic core set (gcloud, attended) |
| 9 | A5 | AI.9 Settings (opt-in, either or both keys, player-set ceiling, text-only), per-provider cost indicator, `ai-live-guard`, game wiring, export bundling | 340 | AI.7, AI.8 | — |
| 10 | A6 | AI.10a per-segment TTS composition, Medic cast entry, conversation UI, stub rehearsal of the style frame, `ai-style-frame` | 280 | AI.9 | — |
| 11 | A7 | AI.10b **attended** live line (Secret Manager keys: text via OpenRouter, voice via Gemini), three auditions, capture, report | 110 | AI.10a, P-live | **⏸ C** STOP for Mark; landing after his answer |
| | | contingency (evaluator FAIL / upstream park) | | | +2 iterations |
| | | **Total** | **3,760** | | |

**Pause points**
- **P0 (now).** This plan stops for Mark's approval. No execution, no
  handoff message, no commit.
- **⏸ G21, golden review (after AI.3), as at M2's P5.** Protocol 2.1
  re-records every replay golden on both architectures (arm64 locally;
  x86_64 from a throwaway CI branch, deleted afterwards, as M2.5 did). The
  re-record is **one reviewed diff** from `make replay-record LOG=all`, never
  regenerated inside `make test`. Before review, `make replay-compat` must
  pass: every 2.0 golden, with hello minor reset, the two new `params` keys
  removed and the `ai` section removed, is byte-identical to its frozen
  copy. The evaluator checks the compat output and reads the diff; **Mark
  approves the goldens** (as he did at P5). The AI.3 merge waits for that;
  AI.4–AI.6 continue, and AI.7 waits for the merge.
- **P-pub, core publish (after AI.8).** `make ai-core-publish` uploads the
  Medic set (4 portraits, 1 avatar) to
  `gs://stapledons-voyage-assets/ai/<sha256>.<ext>` with `--no-clobber`. It
  needs maintainer gcloud auth, so the controller runs it in an attended
  session, as with `sky-publish` (D-18). Public bucket: Q3.
- **P-live (before AI.10b): spending is attended only.** The only command
  that can start a paid provider is `make ai-live`, which:
  1. refuses unless `AI_LIVE=1` **and** stdin is a terminal;
  2. reads whichever build keys exist with
     `gcloud secrets versions access latest --secret=<gemini-api-key|openrouter-api-key> --project=stapledons-voyage`
     into a `mktemp -d` directory, one file per key, mode 0600, deleted by a
     `trap` on exit. A missing `openrouter-api-key` version is not an error:
     the routing table then sends text to Gemini, and the script says so;
  3. starts the game with `--ceiling-usd 1.00` for the session (Q4) and
     prints the session's `usage.ndjson` total per provider on exit.

  The loop never runs AI.10b. If the loop reaches it, it parks the item and
  asks on issue #1. `ai-live-guard` (AI.9, in `make test`) proves no other
  target or test can start a non-stub provider (`gemini` or `openrouter`).
- **⏸ C, the Medic style frame: STOP for Mark (after AI.10b).** Mark reviews
  the three voice auditions (Aoede, Kore, Leda) of the same line, the swap
  timing (segment start vs 150 ms early), the crossfade length, and the
  per-segment prosody (D-20 OQ7). The controller opens a ledger row (the loop
  may ask; only Mark resolves) and posts a private review page with the
  renders, `line.ogg` and `frame.avi`. **Nothing past (c) proceeds before his
  answer:** the accepted voice joins the core layer, and landing follows.

### Upstream gaps: decisions and decision points

| Gap | Issue | Plan without it | Decision point |
|---|---|---|---|
| G1 no TTS in `std/ai` | ailang#1495 | TTS adapter outside `std/ai`: body and checks from `sunholo/gemini_live/tts`, POST via `std/net.httpRequest` with `--net-allow-domains generativelanguage.googleapis.com`. The stub voice is pure (`std/audio`). Model neutrality holds for text and images; TTS swaps by `models.json` + adapter | **At AI.5 start** and again **at AI.10a start**: `$A docs std/ai \| grep -i speech` on the pinned binary. If a pinned release has `callSpeech`, the adapter calls it instead (the pure parsers stay for fixtures). A pin bump moves CI, runtime and lock together and is its own PR, never inside this sprint |
| G2 no reference-conditioned images | ailang#1496 | The `portrait` kind exists in the protocol and the stub only; live portrait generation is out of scope (design non-goal). The Medic's missing five emotions are commissioned from the art pipeline (D-20 OQ8) | None in this sprint |
| G3 no fixture-driven `--ai-stub` | ailang#1497 | Our own pure stub provider, plus the narrow `--ai-stub` lane that checks the adapters turn `{"kind":"Wait"}` into `bad_output` and the 1×1 PNG into a valid descriptor | At AI.5 start: if a pinned release has it, add one adapter test through it (optional, no scope change) |
| G4 silent ADC fallback, no key-file option | ailang#1499 | The `/bin/sh` wrapper (key file → env, `GOOGLE_APPLICATION_CREDENTIALS=/nonexistent`) and the service's refusal without `GOOGLE_API_KEY` (AC14) | At AI.9 start: if a pinned release has the switch, use it in the launch command and keep the refusal test |
| G5 path dependencies absolute in the lock | ailang#1498 | No sharing between `sim/` and `ai/`: the sim parses markers, the service consumes parsed segments | None |
| OpenRouter refuses image output | feature request filed 2026-10-02 (coordinator) | Portraits and avatars route to Gemini only (`routing.json`); OpenRouter carries text | At AI.9 start: if a pinned release supports it, add an OpenRouter entry to the `portrait` route as data plus one stub-route golden; no code path change |

Any new AILANG bug found on the way (VM vs interpreter, std/net header
blocking, std/audio) goes out as `ailang messages send user … --from
stapledons_godot` with `AILANG_STORAGE_MESSAGING=gcp` and
`AILANG_MESSAGES_PROJECT=ailang-multivac`, with a minimal repro and the
version.

## Milestones

### Wave A1

#### AI.1: Emotion-marker grammar and parser (design (b))
**Goal:** one grammar, `{emotion}` (D-20), implemented once in the pure sim,
with round-trip properties and a strict-VM entry.

**Tasks (test first):**
1. `sim/markers_test.ail`: every error code (unknown emotion, unbalanced or
   nested brace, empty segment: two markers in a row or a trailing marker, any
   `[` or `]`, more than 16 segments); the leading-neutral default; adjacent
   equal markers merge; trimming; display text joined with single spaces;
   `printLine(parseLine(x)) == normalise(x)` over the valid fixtures and
   `parseLine(printLine(s)) == s` over segment lists, including non-ASCII
   text (`length` counts code points, design V5) and 16-segment lines.
   Mutation check: drop the `[`/`]` refusal, drop the merge, allow 17 segments;
   each mutant must fail a named test.
2. `sim/markers.ail` (pure): `Segment {emotion, text}`, `parseLine ->
   Result[[Segment], string]` with the `ai_markup` sub-reason, `printLine`,
   `displayText`, `emotions8`, and the portrait fallback table
   (`happy→loving→neutral`, `loving→happy→neutral`, `sad→grieving→neutral`,
   `grieving→sad→neutral`, `angry`/`fearful`/`curious` → `neutral`) as
   `fallbackChain(e)`.
3. `data/ai/emotion_styles.json`: one provider-neutral style sentence per
   emotion (data, uncounted).
4. `mk/ai.mk` (new): `.PHONY`, `test: ai-test`, `ai-test: strict-ai`,
   `strict-ai` with the `markersVm` entry (strict VM == interpreter, last line
   `markers-ok`). `Makefile`: the single line `include mk/ai.mk` at the end.

**Files:** `sim/markers.ail`, `sim/markers_test.ail`,
`data/ai/emotion_styles.json`, `mk/ai.mk`, `Makefile` (one line).
**Estimated:** 120 code + 180 tests = **300** · **Cap:** 650 · **Deps:** — ·
**Registry:** none
**Acceptance:** AC16 `cd sim && $A test --package .` (`markers_test.ail`);
AC7 part `make strict-ai AILANG=$A` (`markersVm`); `make test AILANG=$A`.

#### AI.2: Protocol 2.1 codecs and the pure AI module (design (a1), part 1)
**Goal:** the sim can open, cancel and expire AI requests, with ids and seeds,
and the commit rule admits AI intents, **while every 2.0 log still replays
byte-identically** (hello stays minor 0, and nothing new prints unless an AI
intent arrives).

**Tasks (test first):**
1. `sim/protocol_test.ail` `checkAiCodecs`: `ai_open` (all optional fields,
   `context` ≤ 8 string or string-list fields), `ai_cancel` (the 7 reasons),
   the events `ai_request`, `ai_accepted`, `ai_fallback`, the change-set `ai`
   section; hand-written inverse pairs round-trip every fixture; malformed
   fields stay `bad_intent`.
2. `sim/ai_test.ail`: `checkAiOpenRefusals` (`ai_kind`, `ai_bad_key`
   including the entity-id regex by hand-written scan, `ai_stale` stubbed
   until AI.3 adds `ai.lines`, `ai_too_many`, `diag_only` for `probe`),
   `checkAiIds` (monotonic, never reused, decimal strings), `checkAiExpiry`
   (`ai_fallback{expired}` exactly at `expires_tick`), `checkAiCancel`, seed =
   top 53 bits of one stream-5 draw per open.
3. **Commit rule (D-20, a milestone task).** `refuseWhileCommitted` keeps one
   arm per constructor and no wildcard: the three AI arms delegate to
   `sim/ai.ail`, every journey intent is still refused `committed`.
   - Rewrite `checkCommittedRefusesAll` (`sim/core_test.ail:332`) to send every
     constructor and assert: each journey intent refused `committed`; each AI
     intent accepted. Rename its test (`:658`) to "AC7 committed world
     refuses every journey intent".
   - New `checkAiNeverTouchesJourney` (`sim/ai_test.ail`): `ship`, `journey`,
     `ledger` and the `journey`/`crew`/`events`/`galaxy`/`news` stream
     counters byte-identical (by encoded change set) after every AI intent,
     committed or not.
   - Update `sim/core.ail`'s state-machine comment (`:113`, `:162`), and the
     implemented M2 design doc's AC7 row and reason table
     (`design_docs/implemented/r1/m2-journey-core.md:290`, `:601`) with an
     amendment note: "narrowed to every **journey** intent by D-20,
     2026-10-02". The M4 design doc's §M4.1 interface text is checked for the
     old wording.
4. `sim/ai.ail` (pure): `AiState {lastReq, open, lines, core}`, `OpenReq`,
   `CacheKey`, open/cancel/expire. `World` gains `ai`. `new_game` accepts
   optional `ai_core`. Scenario params `ai_max_open` (default 8, 1–64) and
   `ai_ttl_ticks` (default 3600, 1–10⁶), validated as M2's params are.
5. **No wire change for 2.0 logs.** The params keys and the full-state `ai`
   section are **not** printed yet (AI.3 flips them with the goldens). Proof:
   `make replay AILANG=$A` is green with the goldens untouched.
6. `strict-ai` gains `aiVm` (open, cancel, expiry, ids over a scripted
   sequence; strict VM == interpreter).
7. `IRecord` outside a journey stays `unsupported` until AI.3.

**Files:** `sim/ai.ail` (new), `sim/ai_test.ail` (new), `sim/protocol.ail`,
`sim/protocol_test.ail`, `sim/core.ail`, `sim/core_test.ail` (two hunks only),
`mk/ai.mk` (`aiVm`), `design_docs/implemented/r1/m2-journey-core.md` (AC7
amendment).
**Estimated:** 190 code + 240 tests = **430** · **Cap:** 650 · **Deps:** — ·
**Registry:** depend std/json, std/crypto
**Acceptance:** AC2 `cd sim && $A test --package .` (`checkAiCodecs`); AC3
part (`checkAiOpenRefusals`); AC4 (`checkAiIds`, `checkAiExpiry`); AC5
(`checkAiNeverTouchesJourney`, `checkCommittedRefusesAll`); AC7 part
`make strict-ai AILANG=$A` (`aiVm`); `make replay AILANG=$A` **with no golden
changed** (`git diff --exit-code tests/replays/`); `make test AILANG=$A`;
`! grep -nE "Committed.*=> *(Idle|Planned)" sim/core.ail`.

### Wave A2

#### AI.3: Record validation, protocol 2.1 on the wire, golden re-record → ⏸ G21
**Goal:** every AI result is validated by pure code and closes its request
exactly once; the sim says minor 1; every golden is re-recorded as one
reviewed diff, and `replay-compat` proves nothing else moved.

**Tasks (test first):**
1. `sim/ai_test.ail` `checkAiRefusals`: each `record` refusal fires on its
   fixture (`ai_source`, `ai_unknown_req`, `ai_kind`, `ai_hash` for text and
   media, `ai_length` in code points, `ai_numeral`, `ai_markup`, `ai_emotion`,
   `ai_descriptor` including segment count and offsets strictly increasing from
   0 and below `duration_ms`), closes the request with `ai_fallback`, except
   `ai_unknown_req`; the tick proceeds in every case. `checkAiOnce`: a second
   record for a closed request is `ai_unknown_req`. `checkAiHash`: the sim's
   `sha256Hex(body)` equals a committed `shasum -a 256` vector, including
   non-ASCII bodies. `ai_stale` with `ai.lines` (last 64 accepted lines).
2. `sim/ai.ail`: validation using `sim/markers.ail` (AI.1); `ai_accepted`
   carries the parsed `segments` and the display text; text kinds keep
   `ai.lines`.
3. Protocol 2.1 on the wire: `helloMsg` minor 1; full states print
   `params.ai_max_open`, `params.ai_ttl_ticks` as the **last** keys of
   `params` and the `ai` section as the **last** section (finding 2); the
   bridge still accepts major 2 only (`tests/test_sim_bridge.gd` gains a
   minor-1 case and a major-3 refusal).
4. **Freeze, then re-record.** Before touching the sim's output, copy every
   current 2.0 golden into `tests/replays/compat-2.0/` (uncounted). Then
   `make replay-record LOG=all` on arm64, and the x86_64 goldens from a
   throwaway CI branch (deleted afterwards).
5. `make replay-compat` (in `mk/ai.mk`, harness mode `--compat` in
   `tools/replay.py`, tests in `tools/test_replay.py`, first): for each log
   whose input is unchanged since the freeze, run 2.1 on VM and interpreter,
   strip exactly the three fields, and `cmp` (or compare the sha256 of the
   stripped stream for digest goldens) with `compat-2.0/`. Harness mutations
   that must be caught: stripping a fourth field; comparing parsed JSON
   instead of bytes; passing a log whose input changed. Changed-input logs
   print `skipped` with the reason. `replay-compat` joins `ai-test`.
6. New replay case `ai_sim_session` (`tools/gen_ai_session.py`, harness,
   allowlisted, deterministic): `ai_open` of every kind, every `record` and
   `ai_open` refusal, cancels, an expiry, ids past 64 accepted lines, AI
   intents while committed during the α Cen voyage. Goldens per arch.
7. `strict-ai` `aiVm` extended to validation; `checkHello21`.

**Files:** `sim/ai.ail`, `sim/ai_test.ail`, `sim/protocol.ail`,
`sim/protocol_test.ail`, `sim/core.ail`, `tests/test_sim_bridge.gd`,
`tools/replay.py`, `tools/test_replay.py`, `tools/gen_ai_session.py`,
`tools/python-allowlist.txt`, `mk/ai.mk`, `tests/replays/*` (goldens,
`compat-2.0/`, `ai_sim_session.*`).
**Estimated:** 130 code + 270 tests and harness = **400** (+ goldens) ·
**Cap:** 650 · **Deps:** AI.1, AI.2 · **Registry:** depend std/crypto
**Acceptance:** AC1 `cd sim && $A test --package .` (`checkHello21`) and
`godot --headless --path . --script tests/test_sim_bridge.gd`; AC3
(`checkAiRefusals`); AC4 (`checkAiOnce`); AC6 part (`checkAiHash`); AC12 part
`make replay AILANG=$A` (case `ai_sim_session`); AC13
`make replay-compat AILANG=$A`; `make test AILANG=$A`.
**Pause after:** ⏸ G21. **Merge rule:** before M1.7 starts (see Sequencing).

#### AI.4: The `ai/` package, provider routing, stub provider and service loop (design (a2), part 1)
**Goal:** a separate AILANG process that resolves each request to a provider
route, answers `ai/1` requests from the pure stub, writes the cache, and
cannot spend: it runs with `--caps IO,FS`.

**Task 0 (docs only):** add a dated "Amendment 2026-10-02: both providers"
section to the design doc (routing table, OpenRouter for text, Gemini for
portraits and voice, two optional keys, per-provider cost) so the design and
this plan agree.

**Tasks (test first):**
0. `ai/route_test.ail`: pure route resolution from `data/ai/routing.json`
   and the set of keys present (`{gemini, openrouter}` ⊆ keys): text with
   both keys → OpenRouter; text with only the Gemini key → Gemini; text with
   no key → `no_key` (text-only); portrait/avatar/voice → Gemini or `no_key`,
   never OpenRouter; text-only mode → `text_only` for voice/portrait; an
   unknown provider or a model id without a provider is a config error at
   start. The hello reports the resolved route per kind.
1. `ai/wire_test.ail`, `ai/key_test.ail`, `ai/stub_test.ail`: request/result
   codecs with inverse pairs; `CacheKey` canonical string and validation
   (same regex and emotion set as the sim, duplicated by design: G5);
   stub text (`"{neutral} Stub line <req> for <entity_id>."`, varied by
   purpose, trimmed to `max_chars`), fixture-table negatives
   (`ai/fixtures/stub_text.json`: `digits`, over-length, bad marker,
   unlisted emotion), stub portrait (committed 64×64 PNG per emotion).
2. `ai/ailang.toml` (`stapledons/ai`, `[effects] max = ["IO", "FS", "Env",
   "Net", "AI"]`; imports nothing from `sim/`), `ai/ailang.lock`;
   `ai/{wire,key,route,provider,cache,service}.ail`, `data/ai/routing.json`.
   `provider.ail` has `Provider = Stub | Gemini(Models) | OpenRouter(Models)`,
   the two live ones refusing placeholders until AI.5. The stub answers every
   route and stamps `meta.route` with the provider the routing table chose
   (`meta.provider` stays `stub`). `cache.ail`: blob write to
   `blobs/ab/<sha256>.<ext>`, index append (single writer). `service.ail`:
   hello → read → decode → handle → print, one request at a time; `quit`.
   Service flags `--keys-present gemini,openrouter` (stub mode simulates
   which keys exist; live mode derives it from the env, AI.5).
3. `make ai-stub` (in `mk/ai.mk`): run with `--caps IO,FS` over
   `tests/ai/requests.ndjson` **three times**: keys `gemini,openrouter`,
   keys `gemini` only, no keys. Each run's stdout `cmp` its
   `tests/ai/results.<keys>.golden.ndjson` (text routed to OpenRouter, to
   Gemini, to `no_key`; portraits and voice to Gemini or `no_key`); index and
   blob hashes `shasum -c tests/ai/cache.SHA256SUMS`; VM == interpreter. The
   harness also compares every text `sha256` with `shasum -a 256` (AC6,
   independent reference).
4. `strict-ai` gains `aiWireVm` (wire + key round trips). `deps-ai`: `cd ai
   && $A lock`, diff ignoring `generated_at` (as `make deps`).

**Files:** `ai/ailang.toml`, `ai/ailang.lock`, `ai/{wire,key,route,provider,cache,service}.ail`,
`ai/*_test.ail`, `ai/fixtures/*`, `data/ai/routing.json`, `tests/ai/*`,
`mk/ai.mk`, the design doc (amendment section).
**Estimated:** 340 code + 210 tests = **550** (+ fixtures) · **Cap:** 650 ·
**Deps:** AI.2 (request event shape) · **Registry:** depend std/json, std/fs,
std/crypto
**Acceptance:** AC8 `make ai-stub AILANG=$A` (all three key sets); AC6 part
(harness vs `shasum`); AC7 part `make strict-ai AILANG=$A` (`aiWireVm`,
route resolution); `cd ai && $A test --package .` (`route_test.ail`);
`make test AILANG=$A`.

### Wave A3

#### AI.5: Prompts, per-provider spend, OpenRouter and Gemini adapters on fixtures, stub voice (design (a2), part 2)
**Goal:** the provider adapters for both routes exist and are proven without
a network or a key; the player's ceiling is enforced in pure code over the
sum of both providers.

**Task 0 (probes, recorded in the sprint notes):** on the pinned `$A`:
`docs std/ai | grep -i speech` (G1 decision point); G3 likewise;
`std/net.httpRequest` accepts an `x-goog-api-key` header (not
`InvalidHeader`), probed against a domain outside `--net-allow-domains` so no
request leaves; `std/env.hasEnv`; `sunholo/gemini_live@0.5.0` installs, locks
and type-checks under v0.51.0. **OpenRouter:** the key env var the built-in
provider reads (expected `OPENROUTER_API_KEY`), that `std/ai.step` accepts an
`openrouter:vendor/model` id per call while the handler was started with a
Gemini model (or what `--ai` must be for mixed routing), whether the
provider reports token usage to AILANG code, and what `--ai-stub` returns for
an OpenRouter model. Any surprise is reported upstream and recorded as a
decision before task 3.

**Tasks (test first):**
1. `ai/prompt_test.ail`: prompt goldens for `line`, `news`, `archive`,
   `probe` (`tests/ai/prompts/*.golden.txt`): no-verdict guardrail, the
   grammar and allowed palette, `no_numerals`, lore snippets by id.
2. `ai/spend_test.ail`: `data/ai/prices.json` keyed by provider and model ×
   reported tokens or characters → USD; a session ledger **per provider**
   plus the total; refusal with `budget` once the **total** would exceed
   `--ceiling-usd`; the ceiling is a **player-set** argument, default 0.50
   (D-20); bounds per Q2. `usage.ndjson` lines carry `provider`, `model`,
   `route`.
3. `ai/provider.ail` adapters, each a thin effectful call around a pure
   `parse…Response`, tested on committed, scrubbed response fixtures
   (`ai/fixtures/responses/*.json`, taken from public documentation and
   `gemini_live`'s own measured shapes; refreshed from real responses in
   AI.10b):
   - OpenRouter text: `std/ai.step("openrouter:<vendor/model>", …)`;
     `! {AI @limit=3}`; the service refuses `--provider openrouter` (or any
     route through it) unless `OPENROUTER_API_KEY` is non-empty;
   - Gemini text: `std/ai.step(model, …)`; `! {AI @limit=3}`;
   - image: `std/ai.callImageBase64`;
   - TTS: `gemini_live/tts.buildTtsRequest` (voice, `en-GB`, the emotion's
     style line, `maxOutputTokens`) POSTed by `std/net.httpRequest` to
     `https://generativelanguage.googleapis.com/v1beta/models/<tts>:generateContent`
     with the key in `x-goog-api-key`; `completeOk` before `ttsAudioOf`.
   - The service refuses `--provider gemini` unless `GOOGLE_API_KEY` is
     non-empty (`hasEnv`), before any call.
4. Stub voice: deterministic PCM (one tone per segment, length from the
   segment's text length) → `std/audio.encode(OggOpus(24000))`; blob hashes
   are goldens, added to `tests/ai/cache.SHA256SUMS`.
5. `data/ai/models.json` (Gemini: text `gemini-2.5-flash`, image
   `gemini-2.5-flash-image`, tts `gemini-2.5-flash-preview-tts`; OpenRouter:
   text model per Q7) and the `routing.json` entries that use them; config,
   not code.
6. `make ai-adapter` (in `mk/ai.mk`): the `--ai-stub` lane with the AI
   capability and **no** Net capability: the OpenRouter and Gemini text
   adapters each turn `{"kind":"Wait"}` into `bad_output`, the image adapter
   turns the 1×1 PNG into a valid descriptor; the TTS and both text parsers
   decode the committed fixtures; the refusals without `GOOGLE_API_KEY` and
   without `OPENROUTER_API_KEY` (env cleared) are asserted separately.
   `strict-ai` covers `ai/prompt.ail`, `ai/spend.ail` and `ai/route.ail`.

**Files:** `ai/{prompt,spend,provider}.ail`, `ai/*_test.ail`,
`ai/fixtures/responses/*`, `tests/ai/prompts/*`, `data/ai/{models,prices}.json`,
`ai/ailang.toml`/`.lock` (`gemini_live` dependency), `mk/ai.mk`.
**Estimated:** 280 code + 180 tests = **460** · **Cap:** 650 · **Deps:** AI.4
· **Registry:** depend `sunholo/gemini_live@0.5.0`, std/ai, std/net,
std/audio
**Acceptance:** AC9 `make ai-adapter AILANG=$A` (both text adapters, image,
TTS, both key refusals); AC7 part `make strict-ai AILANG=$A`; AC8
`make ai-stub AILANG=$A` (voice blobs; per-provider `usage` lines);
`make test AILANG=$A`.

#### AI.6: `AiBridge`: launch, non-blocking relay, supervision (design (a3), part 1)
**Goal:** Godot runs the service as a child without ever blocking the frame,
and survives a service that hangs, crashes or lies.

**Tasks (test first):**
1. `ai/tools/fake_service.ail` (AILANG, per the Python policy): modes
   `ok`, `hang`, `crash_after_n`, `garbage`, `slow_hello`, `wrong_major`.
2. `tests/test_ai_bridge.gd --faults`: handshake within 5 s and
   `proto.major == 1`; per-kind timeouts (text 30 s, voice 60 s, portrait
   120 s; overridable in tests to keep the suite short) → kill, `timeout`,
   lazy restart; crash → backoff 1 s, 4 s, 16 s; 3 failures in 10 min →
   disabled for the session, every queued and open request `service_down`,
   toast text; priority `text > voice > portrait`, one in flight; shutdown
   `quit` → 1 s grace → kill. **Frame never blocked:** every `_process` poll
   returns within 2 ms, measured over the hang case.
3. `bridge/ai_bridge.gd` (`AiBridge`, `Node`): `OS.execute_with_pipe(...,
   false)`, polls `get_buffer` in `_process`, line assembly across partial
   reads, launch-argument builder mirroring `SimBridge._run_args` and its
   bundled-runtime `HOME` trick; stub launch `--caps IO,FS`; `launch_count`
   counter.
4. `mk/ai.mk` `ai-godot` target (headless, joins `ai-test`).

**Files:** `bridge/ai_bridge.gd` (new), `ai/tools/fake_service.ail`,
`tests/test_ai_bridge.gd` (new), `mk/ai.mk`.
**Estimated:** 200 code + 140 tests = **340** · **Cap:** 650 · **Deps:** AI.4
· **Registry:** none
**Acceptance:** AC11 `godot --headless --path . --script tests/test_ai_bridge.gd -- --faults`
(the design names `test_ai_relay.gd -- --faults`; the bridge half lives in its
own file and `test_ai_relay.gd --faults` runs it, so the design's command
still works); `make test AILANG=$A`.

### Wave A4

#### AI.7: `AiRelay`, `AiCache`, end to end, key hygiene (design (a3), part 2)
**Goal:** sim → relay → service → `record` → `ai_accepted` works for text,
voice and portrait; a cache hit records without starting the service; a
replay starts no AI process.

**Tasks (test first):**
1. `tests/test_ai_relay.gd`: AC10 (all three kinds through the stub; cache
   hit records with `launch_count == 0`; the tee writes the session log);
   `--news` (AC18: `purpose: "news"`, `no_numerals`, `max_chars`; the
   `digits` fixture refused `ai_numeral`, template stands); `--key-hygiene`
   (AC14: **two** fixture key files, Gemini and OpenRouter, distinct texts;
   neither key text appears in the session log, service stdout,
   `usage.ndjson` or the child's argv, read with `ps -o args` for the child
   pid; a route through a provider whose key env var is empty refuses);
   `--routes` (the relay sends text to the route the service reports for the
   keys present, and the `record`'s session log is identical whichever route
   answered, since provider and cost never enter the sim);
   `--faults` delegates to `test_ai_bridge.gd`.
2. `bridge/ai_relay.gd`: subscribes to `last_events`; cache → record, live
   off or no key for that kind's route → `ai_cancel{text_only|no_key|offline}`,
   else forward; `ok` →
   `record`, `error` → mapped `ai_cancel`; queued intents ride on the next
   `send`. Text-only never opens voice/portrait. Enabled only when the sim's
   hello says minor ≥ 1.
3. `bridge/ai_cache.gd`: index layers (core, then library; newest line per
   key within the library), greatest `age_stage` ≤ years aboard, portrait
   fallback chain mirrored from `sim/markers.ail` (test: same table).
4. `bridge/sim_bridge.gd`: optional `ai_relay` hook (~15 lines; no behaviour
   change when unset; `tests/test_sim_bridge.gd` stays green).
5. `tools/record_ai_session.gd` (new; M1.7 owns `record_godot_session.gd`):
   records `tests/replays/ai_stub_session.ndjson` through the tee with the
   stub; goldens per arch.
6. `make replay-noai`: the visual replay path runs `ai_stub_session` through
   Godot with the relay in replay mode and asserts `AiBridge.launch_count == 0`.

**Files:** `bridge/ai_relay.gd`, `bridge/ai_cache.gd`, `bridge/sim_bridge.gd`
(hook), `tests/test_ai_relay.gd`, `tools/record_ai_session.gd`,
`tests/replays/ai_stub_session.*`, `mk/ai.mk`.
**Estimated:** 205 code + 185 tests = **390** · **Cap:** 650 · **Deps:** AI.3
(merged after G21), AI.5, AI.6 · **Registry:** none
**Acceptance:** AC10 `godot --headless --path . --script tests/test_ai_relay.gd`;
AC14 `… -- --key-hygiene`; AC18 `… -- --news`; AC12 part
`make replay AILANG=$A` (case `ai_stub_session`) and `make replay-noai`;
`make test AILANG=$A`.

#### AI.8: Core layer and the bucket (design (a4)) → P-pub
**Goal:** the accepted Medic set is a pinned, content-addressed core layer
that builds bundle and CI can verify offline.

**Tasks (test first):**
1. `ai/tools/core_import.ail` (FS, `sha256Bytes`): from
   `~/dev/blender/assets/stapledon/characters/medic_v2/` at a **pinned
   commit** (recorded in each index line's `source`), write
   `data/ai/core/index.ndjson` and `data/ai/core/SHA256SUMS`: 4 portraits
   (`age0 neutral/loving/grieving`, `age50 neutral`), 1 avatar, with width,
   height, mime, bytes. A unit test on a fixture directory.
2. `mk/ai.mk`: `ai-core-assets` (fetch from
   `gs://stapledons-voyage-assets/ai/` over public HTTPS, sha-checked, like
   `sky-assets`), `ai-core-bundle` (stage into the export), `ai-core-publish`
   (maintainers, gcloud, `--no-clobber`), `ai-core-verify` (offline in
   `make test`: index ↔ `SHA256SUMS` consistent, keys valid, and blob hashes
   if blobs are present; with `AI_CORE_FETCH=1` it fetches first).
3. `infra/gcp/README.md`: the `ai/` prefix (no new bucket resources). The
   OpenRouter build key: `infra/gcp/setup.sh` §8 gains
   `gcloud secrets create openrouter-api-key --project=stapledons-voyage
   --replication-policy=automatic` (the controller runs it attended, at
   P-pub); **Mark adds the value** (`gcloud secrets versions add
   openrouter-api-key --data-file=-`), since an OpenRouter key can't be
   minted with gcloud. README rows for both secrets; Terraform note as for
   `gemini-api-key`.
4. The `ai_core` value for `new_game` = sha256 of `index.ndjson`, exported
   for AI.9's wiring.

**Files:** `ai/tools/core_import.ail`, `ai/tools/core_import_test.ail`,
`data/ai/core/{index.ndjson,SHA256SUMS}`, `mk/ai.mk`, `infra/gcp/README.md`,
`infra/gcp/setup.sh` (§8, the `openrouter-api-key` container).
**Estimated:** 110 code + 50 tests = **160** · **Cap:** 650 · **Deps:** AI.4
· **Registry:** depend std/crypto, std/fs
**Acceptance:** AC17 `make ai-core-verify` (and `AI_CORE_FETCH=1 make
ai-core-verify` after P-pub); `make test AILANG=$A`.
**Pause after:** P-pub (controller, attended, gcloud: core publish and the
empty `openrouter-api-key` secret; Mark adds its value whenever he likes, and
AI.10b falls back to Gemini text if he hasn't).

### Wave A5

#### AI.9: Key and cost UX, the live guard, game wiring, export (design (a5))
**Goal:** off by default; the player's own keys (either or both); a
player-set ceiling with a visible running cost per provider; text-only always
available; no automation can spend; the shipped game carries the service.

**Tasks (test first):**
1. `make ai-live-guard` (joins `ai-test`): scans `Makefile`, `mk/*.mk`,
   `tests/`, `tools/`, `.github/` and the Godot launch builder; fails if any
   path can launch a non-stub provider (`--provider gemini`, `--provider
   openrouter`, or a routing file naming either) without `AI_LIVE=1`, and runs
   the launch builder with `AI_LIVE` unset to assert it emits `--provider
   stub` and `--caps IO,FS`. Mutations: a test target passing `--provider
   gemini`, and one passing `--provider openrouter`, must each make the
   guard fail.
2. `tests/test_ai_settings.gd`: opt-in requires at least one key **and** the
   tick; each key from its env var first (`GOOGLE_API_KEY`,
   `OPENROUTER_API_KEY`), else `user://ai_key_gemini` /
   `user://ai_key_openrouter` saved with mode 0600 (`chmod` via
   `OS.execute`), plain warning text; the panel lists which kinds each key
   enables (from the routing table: OpenRouter → text; Gemini → text,
   portraits, voice); with only an OpenRouter key, voice and portraits stay
   on the core set; ceiling player-set, default 0.50, bounds per Q2, one
   ceiling over both providers, persisted in `user://ai_settings.cfg`;
   text-only toggle and `--text-only` flag; the indicator shows the running
   `meta.usd` per provider and the total, and `budget` →
   `ai_cancel{budget}`.
3. `ui/settings/ai_settings.{tscn,gd}`, `ui/ai_indicator.{tscn,gd}` (own
   CanvasLayer; clicking it opens Settings; no `ui/galaxy_map.gd` change).
   The launch wrapper takes up to two key files (`GOOGLE_API_KEY="$(cat
   "$1")" OPENROUTER_API_KEY="$(cat "$2")"`, an absent key passed as an empty
   path) and `--net-allow-domains generativelanguage.googleapis.com,openrouter.ai`.
4. **Game wiring:** `main.gd`, one hunk of ≤ 15 lines beside
   `sim.record_path = …`: create `AiRelay`/`AiBridge`/`AiCache`, pass
   `ai_core`, add the indicator. Stub provider unless live AI is on.
5. **Export:** `ai-runtime` locks `ai/` into the bundled package cache
   (`gemini_live`), `export-macos: ai-runtime ai-core-bundle` as extra
   prerequisites in `mk/ai.mk`, and the export preset includes `ai/*.ail`.
   `make export-smoke` gains a stub-mode AI hello check (no AILANG on PATH).

**Files:** `ui/settings/*`, `ui/ai_indicator.*`, `tests/test_ai_settings.gd`,
`main.gd` (one hunk), `export_presets.cfg` (include filter), `mk/ai.mk`.
**Estimated:** 225 code + 115 tests = **340** · **Cap:** 650 · **Deps:** AI.7,
AI.8 · **Registry:** none (G4 decision point at start)
**Acceptance:** AC15 `make ai-live-guard`; AC14 (re-run, wiring path);
`godot --headless --path . --script tests/test_ai_settings.gd`;
`make export-macos && make export-smoke` (Studio); `make test AILANG=$A`.

### Wave A6

#### AI.10a: Style-frame machinery, rehearsed on the stub (design (c), part 1)
**Goal:** everything the Medic style frame needs works end to end on the
stub, so the attended run only swaps the provider.

**Tasks (test first):**
1. Per-segment TTS composition in the service (D-20 OQ7): synthesise each
   segment with the cast voice and the emotion's style line, concatenate PCM
   (24 kHz s16le mono), encode once (`OggOpus(24000)`); `segments_ms` from
   `durationMs` of each PCM prefix; descriptor test on the stub (offsets exact,
   strictly increasing, below `duration_ms`). G1 decision point re-checked.
2. `data/ai/cast/medic.json`: identity, departure age 35, persona,
   `voice_id: "Aoede"` (pending ⏸ C), `style`, core portrait keys.
3. `ui/conversation/conversation.{tscn,gd}`: large portrait, crossfade
   parameter (default 120 ms), subtitle revealing segment by segment, audio
   player; reads only `ai_accepted` events and the cache. Opens with
   `godot --path . res://ui/conversation/conversation.tscn -- --conversation=medic`
   (its own scene: no `main.gd` change). Swap offset parameter (0 or −150 ms).
4. `tests/test_conversation.gd` (headless): the portrait swaps at each
   `segments_ms` offset (± one frame), fallback chain for a missing emotion,
   missing audio degrades to text with `missing_blob` logged.
5. `make ai-style-frame` (GPU window): replays a log through Godot with the
   blobs; writes `renders/ai_medic/` (a PNG at each swap, `contact_sheet.png`,
   `line.ogg`) and `frame.avi` via `--write-movie`. **Rehearsal** on a
   stub-recorded `tests/replays/medic_rehearsal.ndjson` (committed, goldens
   per arch), so the target is proven before any spend. Renders opened and
   looked at by the executor and the evaluator.

**Files:** `ai/service.ail`, `ai/provider.ail`, `ai/*_test.ail`,
`data/ai/cast/medic.json`, `ui/conversation/*`, `tests/test_conversation.gd`,
`tests/replays/medic_rehearsal.*`, `mk/ai.mk`.
**Estimated:** 180 code + 100 tests = **280** · **Cap:** 650 · **Deps:** AI.9
· **Registry:** depend std/audio, `sunholo/gemini_live@0.5.0`
**Acceptance:** `godot --headless --path . --script tests/test_conversation.gd`;
`make ai-style-frame LOG=tests/replays/medic_rehearsal.ndjson && test -s renders/ai_medic/contact_sheet.png && test -s renders/ai_medic/line.ogg`;
`make replay AILANG=$A` (case `medic_rehearsal`); `make test AILANG=$A`.

### Wave A7

#### AI.10b: The live Medic line, attended → ⏸ C (design (c), part 2)
**Goal:** one real line through the real path, three voice auditions, and a
capture Mark can judge. **Attended only; the loop never runs this.**

**Tasks:**
1. `make ai-live` (P-live rules): `AI_LIVE=1`, a terminal, the Secret
   Manager keys (`gemini-api-key`, and `openrouter-api-key` if Mark has added
   its value) into 0600 temp files removed on exit, `--ceiling-usd 1.00`.
2. In the game: `--conversation=medic`, `emotions: ["neutral", "loving",
   "grieving"]` (D-20 OQ8). The line's **text goes through OpenRouter** (the
   default route) and its **voice through Gemini**, so the one attended run
   proves both live providers; if the OpenRouter secret has no value yet,
   the text goes through Gemini and one short OpenRouter `probe` request is
   run later in an attended session. Recorded through the tee to
   `tests/replays/medic_style_frame.ndjson`, plus per-arch goldens. Three
   voice auditions of the **same accepted line** (Aoede, Kore, Leda) as voice
   requests on the same `line_req`, all recorded.
3. Refresh the adapter fixtures from the real responses (scrubbed: no key, no
   auth headers) and re-run `make ai-adapter`.
4. `make ai-style-frame LOG=tests/replays/medic_style_frame.ndjson`; open and
   look at every PNG, the contact sheet, `line.ogg` and `frame.avi`.
5. `design_docs/planned/r1/ai-service-foundation-report.md` (latencies,
   `usage.ndjson` totals per provider, the real cost, the G1–G5 and
   OpenRouter-image status).
6. **⏸ C:** open a ledger row for Mark (voice, swap timing, crossfade,
   prosody) and post the review page. **Stop.**
7. After Mark's answer: the chosen voice blob joins the core layer (`make
   ai-core-publish`, `data/ai/core/` updated), `medic.json` records the voice;
   then landing: design doc and this plan to `design_docs/implemented/r1/`,
   design repo ai-showcase §8 status and the curly-brace note, the mission
   queue row 4 status, a changelog entry.

**Files:** `mk/ai.mk` (`ai-live`), `tools/ai_live.sh` (shell glue),
`tests/replays/medic_style_frame.*`, `ai/fixtures/responses/*`,
`data/ai/cast/medic.json`, `data/ai/core/*`, the report.
**Estimated:** 65 code + 45 tests = **110** (+ fixtures, renders, report) ·
**Cap:** 650 · **Deps:** AI.10a, P-live · **Registry:** none
**Acceptance:** AC12 `make replay AILANG=$A` (case `medic_style_frame`) and
`make replay-noai`; AC19 `make ai-style-frame && test -s renders/ai_medic/contact_sheet.png && test -s renders/ai_medic/line.ogg`,
then the ledger row answered; AC20 `make test AILANG=$A`.
**Pause after:** ⏸ C (STOP for Mark).

## Acceptance criteria → milestone map

| AC | Milestone(s) | Command |
|---|---|---|
| AC1 | AI.3 | `cd sim && $A test --package .` (`checkHello21`); `godot --headless --path . --script tests/test_sim_bridge.gd` |
| AC2 | AI.2 | `cd sim && $A test --package .` (`checkAiCodecs`) |
| AC3 | AI.2 (open), AI.3 (record) | `cd sim && $A test --package .` (`checkAiOpenRefusals`, `checkAiRefusals`) |
| AC4 | AI.2, AI.3 | `cd sim && $A test --package .` (`checkAiIds`, `checkAiExpiry`, `checkAiOnce`) |
| AC5 | AI.2 | `cd sim && $A test --package .` (`checkAiNeverTouchesJourney`, `checkCommittedRefusesAll`) |
| AC6 | AI.3, AI.4 | `cd sim && $A test --package .` (`checkAiHash`); `make ai-stub AILANG=$A` |
| AC7 | AI.1, AI.2, AI.3, AI.4, AI.5 | `make strict-ai AILANG=$A` (`markersVm`, `aiVm`, `aiWireVm`, prompt, spend); the design's `make strict` is satisfied by `strict-ai`, which `make test` runs through `ai-test` |
| AC8 | AI.4, AI.5 | `make ai-stub AILANG=$A` (three key sets: both routes, Gemini only, none) |
| AC9 | AI.5 | `make ai-adapter AILANG=$A` (OpenRouter and Gemini text, image, TTS, both key refusals) |
| AC8b (new, plan change) | AI.4 | `cd ai && $A test --package .` (`route_test.ail`): text → OpenRouter, else Gemini, else `no_key`; portrait/avatar/voice never OpenRouter |
| AC10 | AI.7 | `godot --headless --path . --script tests/test_ai_relay.gd` |
| AC11 | AI.6 | `godot --headless --path . --script tests/test_ai_relay.gd -- --faults` |
| AC12 | AI.3, AI.7, AI.10b | `make replay AILANG=$A` (`ai_sim_session`, `ai_stub_session`, `medic_style_frame`); `make replay-noai` |
| AC13 | AI.3 | `make replay-compat AILANG=$A` (three stripped fields, finding 2) |
| AC14 | AI.7, AI.9 | `godot --headless --path . --script tests/test_ai_relay.gd -- --key-hygiene` (both keys) and `… -- --routes` |
| AC15 | AI.9 | `make ai-live-guard` (any non-stub provider) |
| AC16 | AI.1 | `cd sim && $A test --package .` (`markers_test.ail`) |
| AC17 | AI.8 | `make ai-core-verify` |
| AC18 | AI.7 | `godot --headless --path . --script tests/test_ai_relay.gd -- --news` |
| AC19 | AI.10b | `make ai-style-frame && test -s renders/ai_medic/contact_sheet.png && test -s renders/ai_medic/line.ogg`, then the ledger row |
| AC20 | every milestone; final at AI.10b | `make test AILANG=$A` (with `ai-test` = `strict-ai ai-stub ai-adapter ai-godot ai-live-guard replay-compat ai-core-verify`; `ai-style-frame` and `ai-live` are attended, never in `make test`) |

## Success metrics

- Every AC green with its named command on `$A` v0.51.0, locally and in CI.
- Each milestone's independent evaluation ≥ 70/100 (generator ≠ judge).
  AI.2/AI.3 (the commit rule and determinism) by the strongest available
  evaluator.
- VM == interpreter byte-identical for every new strict entry and replay
  case; `replay-compat` green with nothing skipped except logs M1.7 changed.
- No spend outside AI.10b: `ai-live-guard` green, and the billing console
  shows nothing before the attended run. AI.10b's real cost recorded in the
  report (design estimate: well under US$0.10).
- Renders from `ai-style-frame` (rehearsal and live) opened and looked at;
  Mark's ⏸ C answer in the ledger.
- Only one `Makefile` line changed by this sprint.

## Risks

| Risk | Milestone | Mitigation |
|---|---|---|
| AI.3's golden re-record collides with M1.7's | AI.3 | Merge AI.3 before M1.7 starts; otherwise re-record on top of M1.7; `compat-2.0` frozen at AI.3's branch point; changed-input logs reported `skipped` |
| Godot pipe reads block or split lines | AI.6 | `execute_with_pipe(..., false)` as `SimBridge` already does; line assembly across partial reads; the hang fault case measures each poll at ≤ 2 ms |
| Spend by accident (ADC fallback, a stray target, the loop) | AI.5, AI.9, AI.10b | `--caps IO,FS` everywhere automated (no AI or Net capability at all); env refusal per provider (`GOOGLE_API_KEY`, `OPENROUTER_API_KEY`); `GOOGLE_APPLICATION_CREDENTIALS=/nonexistent`; `ai-live-guard` with a mutation per provider; `make ai-live` needs `AI_LIVE=1` and a terminal; the budget is only an alert (finding 6) so the session ceiling is US$1.00. OpenRouter billing is prepaid credit on Mark's OpenRouter account, outside the GCP budget: Q8 |
| The key leaks (argv, logs, fixtures, error text) | AI.7, AI.10b | Keys only in 0600 files and env; AC14 greps every output and the child's argv for both keys; fixtures scrubbed before commit; a pre-commit grep for the key prefixes `AIza` and `sk-or-` over the diff in AI.10b |
| OpenRouter routing surprises on the pin (key env name, per-call `openrouter:` ids beside a Gemini handler, no usage numbers reported back) | AI.5 | Task 0 probes; if usage isn't reported, cost comes from `prices.json` × a character-based token estimate, flagged `estimated` in `usage.ndjson` and the indicator; mixed-route issues reported upstream; worst case, one service instance per provider (the wire already carries `req`) |
| OpenRouter model choice drifts in price or availability | AI.5, AI.10b | The model id is data (`models.json`, Q7); the route falls back to Gemini when OpenRouter errors with `provider_error` twice in a session |
| The TTS adapter bypasses provider routing (G1) | AI.5 | One adapter, pure body/parse from `gemini_live/tts`; swap to `std/ai` speech at a decision point; text and images stay routed |
| AI Studio TTS model id or response shape differs from the package's Vertex measurements | AI.5, AI.10b | Ids are data (`models.json`); parsers tested on fixtures and refreshed from real responses in AI.10b; `completeOk` judges truncation |
| `std/net` blocks the `x-goog-api-key` header | AI.5 | Task 0 probe without network; if blocked, report upstream and park the TTS adapter (text-only and stub voice still land; AI.10b waits) |
| `gemini_live` 0.5.0 fails to lock or check under v0.51.0 | AI.5 | Task 0 probe; fallback: local body builder (~40 LOC) and `contribute` the fix via `pkg:gemini_live` |
| Exported game lacks `ai/` or its packages | AI.9 | `ai-runtime` + export filter; `export-smoke` checks the stub hello with no AILANG on PATH |
| LLM output often fails the grammar | AI.10b | Prompt states grammar and palette; up to two in-handler retries; a refusal falls back to the template; the attended run may take a few tries within US$1.00 |
| Merge conflicts with M1 in `Makefile`, `main.gd`, `sim/core_test.ail` | all | One `include` line; one late `main.gd` hunk; two hunks in `core_test.ail`; see Sequencing |
| Cross-arch float differences (ailang#1465) | AI.3, AI.7, AI.10b | No floats enter sim state from AI (`usd` stays out); goldens per arch as in M2 |

## Questions for Mark

1. **Ledger hygiene.** D-20's text is mangled ("~US/month", "default
   US/bin/zsh.50", from shell expansion of `$20` and `$0.50`), and the
   both-providers ruling of 2026-10-02 isn't in the ledger yet (it narrows
   D-8 (2)'s "Gemini default" for text). Record both with attended ledger
   edits (single-quoted `--answer`)? **Default:** this plan uses US$20 ≈ 140
   DKK and US$0.50, and treats the both-providers change as ruled.
2. **Player ceiling bounds.** Range and persistence for the player-set
   ceiling. **Default:** US$0.05–20.00 in Settings, default 0.50, kept across
   sessions in `user://ai_settings.cfg`; setting live AI off is the way to
   spend nothing.
3. **The Medic core set in the public bucket.** `ai-core-publish` puts the 4
   portraits and the avatar in `gs://stapledons-voyage-assets/ai/`, which is
   publicly readable (D-18). They ship in builds anyway. **Default:** yes.
4. **The attended live run (AI.10b).** Session ceiling and who must be there.
   **Default:** `--ceiling-usd 1.00`; any attended session on the Studio with
   gcloud auth may run it; you are needed only for ⏸ C.
5. **Scheduling beside M1.** Run AI waves in the same attended sessions as
   M1's waves (parallel executors, as M2 ran), or only when M1 waits on your
   reviews (R-b, R-d)? **Default:** in parallel, per D-20 "alongside", with
   the AI.3-before-M1.7 rule.
6. **Cap and count.** 650 counted LOC per milestone, 11 milestones,
   3,760 LOC (design ≈3,150; the OpenRouter route and the finding list explain the difference).
   **Default:** as planned.
7. **Default OpenRouter text model.** Which `vendor/model` carries dialogue,
   news and the Archive by default? **Default:** the executor proposes the
   cheapest model on OpenRouter that passes the grammar and `no_numerals`
   prompts in AI.5's fixtures, put in `models.json`; you confirm or swap it at
   ⏸ C (a data change).
8. **OpenRouter spend outside GCP.** OpenRouter bills prepaid credit on its
   own account, so the 140 DKK GCP budget doesn't see it. **Default:** the
   build-time OpenRouter key carries a credit limit you set on openrouter.ai
   (suggest US$5); the attended session ceiling (US$1.00) covers both
   providers together.

No design question is open: D-20 settled all nine; the both-providers change
adds Q7 and Q8. The planner wrote no git
objects (branch `plan/ai-foundation` only), sent no handoff, and ran no
executor.
