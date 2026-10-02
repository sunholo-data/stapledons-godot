# AI service foundation: a recorded, replayable AI process

**Status:** Planned (design, awaiting Mark's answers to the open questions, then a sprint plan). Written 2026-10-02 after Mark chose "Finish M1 + AI design".
**Release:** r1 · **Milestone:** mission queue row 4 "AI service foundation" (ledger **D-9**), feeds bar clause 4 (M4's news beat) and clause 5 (AILANG)
**Priority:** P1: M4 is fully playable on templates without it (M4 §Depends on: "Soft"), but every later conversation, voice and portrait sits on this protocol, and recording must exist before the first live AI output, or replays break
**Implements:**
- Ledger **D-7** (portraits for the 8 emotions with age stages; emotion markers swap the portrait live; every line spoken in a per-character voice; generate on first use, then cache; every AI output recorded as a sim input; AI calls outside the tick in their own process), **D-8** (the player's own key; pre-generated core; live generation opt-in; model-neutral with Gemini as default; no live voice; text-only always available) and **D-9** (three milestones a/b/c), `design_docs/stapledon-mission.md` §Decision ledger
- [ai-showcase](https://github.com/sunholo-data/stapledons-design/blob/main/features/ai-showcase.md) (`../stapledons-design/features/ai-showcase.md`): §3 the cache key and the pre-generated set, §5 the architecture and replay rule, §7 the operating model, §8 steps 1–3
- [characters brief](https://github.com/sunholo-data/stapledons-design/blob/main/art/characters-blender-brief.md) §3.2–3.3 (8 emotions, up to 4 age stages) and §6 (markers select portraits; one voice per identity, recorded in `manifest.json`)
- [generation-cast-plan](https://github.com/sunholo-data/stapledons-design/blob/main/art/generation-cast-plan.md): descendants are new identities, so `entity_id` is a person, never a role; age stages are years since departure
- [Archive lore](https://github.com/sunholo-data/stapledons-design/tree/main/lore/archive) (`lore/archive/*.md`): canon snippets for prompts by entry id; M4.7's codex vendors them into `data/lore/archive/`
- [ADR 0001](https://github.com/sunholo-data/stapledons-design/blob/main/decisions/0001-engine-and-architecture.md) (NDJSON sidecar; the sim never performs I/O)
- M2 protocol v2 as shipped: the reserved `record` intent (`sim/protocol.ail:168`, `sim/core.ail:80,254`), the bridge's `record_path` tee (`bridge/sim_bridge.gd`), `make replay` ([m2-journey-core.md](../../implemented/r1/m2-journey-core.md) §M2.1, §M2.5; [m2-report.md](../../implemented/r1/m2-report.md))
- M4's "Interfaces assumed: from the AI service foundation" ([m4-first-journey.md](m4-first-journey.md) §Interfaces assumed)
- Ledger **D-18** (the public assets bucket `gs://stapledons-voyage-assets`, content-addressed, builds bundle)

**Depends on:** M2 (landed). Not on M1 or M4. Milestone (c) needs Mark's key or a project key for one attended live call, and Mark's review.
**Estimated:** ~3,150 LOC committed (≈1,900 code + 1,250 tests, tools and fixtures), 3 milestones in 7 sub-milestones. The charter row says ~1,200. The difference is the supervision and relay in Godot, the layered cache, the protocol 2.1 validation in the pure core, and the fault-injection tests that "no key, no spend" and "replay with the service absent" need to be checkable.
**Evidence:** pinned to `origin/main` `6fd48d1`. AILANG pin **v0.51.0** (`sim/ailang.lock`, the staged `runtime/bin/ailang`). Probes in the [Verification log](#verification-log).

## Game vision alignment

Scored against the six pillars (`stapledons-design/vision/core-pillars.md`), as in the M2 doc.

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | + | +1 | A request gets exactly one outcome: the accepted result or the fallback. There is no reroll, and a refused result is final for that request (a retry is a new, recorded request). AI intents never touch the journey, so the commit rule is unchanged in substance |
| The Game Doesn't Judge | + | +1 | Every prompt carries the no-verdict guardrail (ai-showcase §6). Prompt texts are goldens, so a prompt edit is a reviewed diff. Characters may hold opinions; the narrator gets none |
| Time Has Emotional Weight | + | +1 | The portrait's age stage comes from the sim's proper time (years since departure), so faces age with the voyage, not with the menu. M4's news text arrives through this path |
| The Ship Is Home | ++ | +2 | Crew get faces that change with what they say and a voice of their own: the first time a person aboard speaks |
| Grounded Strangeness | + | +1 | Generated text is held to canon: lore snippets by id in the prompt, and `no_numerals` so a model can never state a physics number (numbers come only from the sim and from lore that `make lore-check` vouches for) |
| We Are Not Built For This | 0 | 0 | Frailty and death are R2's crew model; this only makes them speakable later |
| Determinism and replay (constraint, bar clauses 2 and 4) | ++ | +2 | Every AI output enters the session as a recorded input; a replay never starts the service and stays byte-identical on the VM and the interpreter |
| **Net** | | **+8** | **Go.** No pillar at 0 or below. The one tension (AI intents while committed) is an open question with a recommendation |

## Problem

1. **The `record` slot exists but nothing fills it.** Protocol 2.0 decodes
   `record{source, req, kind, sha256, body}` (`sim/protocol.ail:168-169`) and
   refuses it `unsupported` (`sim/core.ail:254`), or `committed` during a
   journey (`:172`). The sim has no notion of an open request, so a result
   cannot be checked against anything: M4 assumes records are "accepted only
   for an open `ai_request_id`" (M4 §M4.1), and nothing provides that.
2. **There is no AI process, relay or cache.** The only child process is the
   sim, read with blocking reads on the frame (`bridge/sim_bridge.gd`
   `_read_state` loops with `OS.delay_msec(2)`). An image generation takes
   tens of seconds, so the same pattern would freeze the game.
3. **AILANG covers text and images, not speech or identity.** On the v0.51.0
   pin (V1–V4): `std/ai` has `call*`, `step(model, ...)`, `stepWithStreamRecorded`
   and `callImage`/`callImageBase64`; `std/audio` turns PCM into WAV or a
   deterministic Ogg Opus; `std/crypto.sha256Hex` runs on the strict VM. There
   is **no TTS call** in `std/ai` (`std/audio` says TTS APIs return PCM, but
   only the `sunholo/gemini_live` package produces it, and live voice is
   deferred by D-8). `callImage` takes **no reference image**, so aged or
   new-emotion portraits cannot be conditioned on the accepted identity.
   `--ai-stub` returns a fixed `{"kind":"Wait"}` and a 1×1 PNG (V3). The Google
   provider **silently falls back to Application Default Credentials** when
   `GOOGLE_API_KEY` is unset (`docs/guides/ai-effect.mdx` §Google Vertex AI),
   which in a player-key game could bill the developer's gcloud account.
4. **The accepted art covers 3 of 8 emotions for one person.** The Medic
   (`~/dev/blender` `assets/stapledon/characters/medic_v2/`) has neutral,
   grieving and loving at departure plus neutral at +50, and a static avatar.
   The other ten identities (`docs/stapledon/cast_marker_v1/`,
   `cast_proposals_v1.zip`) are neutral departure studies only, 1254 px
   rather than the 2048 px target. So milestone (c) must work with a partial
   emotion set.
5. **There is no conversation UI.** ai-showcase §8 step 3 mentions "the
   spike's conversation UI", but no branch has one: `spike/iso-bridge` has
   interiors and a static Medic preview PNG (`fe16790`), not a dialogue
   panel. (c) builds a minimal one.
6. **Marker syntax collides with the provider.** Gemini TTS reads its own
   square-bracket tags (`[sigh]`, `[sad]`, `[excited]`;
   `stapledons-design/reference/ai-capabilities.md` §Emotion Markers). A game
   grammar in square brackets would leak provider behaviour into the text and
   break model neutrality (D-8 (2)).

## Goals and non-goals

**Goals**
- A separate AILANG process, `ai/service.ail`, launched, supervised and
  relayed by Godot. It never talks to the sim.
- Protocol **2.1** (minor bump, additive): the sim opens AI requests, validates
  results against them in the pure core, and closes each request exactly once
  (accepted or fallback). Every AI output reaches the sim as a recorded
  `record` intent, so `make replay` reproduces a session byte for byte with the
  service absent.
- A content-addressed cache with a canonical key
  `(kind, entity_id, emotion, age_stage, variant)`, in three layers: bundled
  core, the player's own library, and the public bucket for maintainers.
- A provider-neutral service with a pure, deterministic **stub provider**. The
  headless tests run it with `--caps IO,FS` only, so they cannot spend money:
  the AI and Net capabilities are absent.
- (b) One emotion-marker grammar, parsed **once, in the sim**. The text check,
  the TTS segmentation and the portrait switcher all consume the sim's parsed
  segments.
- (c) A Medic style frame: one line, spoken in a chosen voice, swapping the
  existing portraits at recorded offsets. **Stop for Mark.**
- Key and cost UX that satisfies D-8: off by default, the player's own key,
  a visible running cost and a hard session ceiling, and text-only always
  available.

**Non-goals**
- Semantic memory, `std/embedding`, `std/sharedindex`, the Archive's degrading
  memory, the narrative orchestrator (ai-showcase §2: R2).
- Live or streaming voice (D-8 (3)). Text is not streamed into the sim either:
  a line is one result. Display streaming is a presentation nicety for later.
- Generating new portraits or emotions from a reference image: AILANG cannot
  condition `callImage` on a reference yet (gap G2). The `portrait` kind is in
  the protocol and the stub, but live portrait generation waits for G2.
- The quality-gate vision check (ai-showcase §3) and the semantic near-match
  reuse: they need G2 and embeddings.
- The news panel itself (M4.4). This doc provides the request M4 assumes.
- Uploading anything a player generates. The player's library stays on their
  machine; only maintainers publish core content.

## Design

### Shape of the system

```
               intents (incl. record, ai_open, ai_cancel)        ┌──────────────────────┐
  ┌────────┐  ─────────────── NDJSON v2.1 ──────────────────────▶│ sim (pure core)      │
  │ Godot  │  ◀── state: events ai_request / ai_accepted /       │ opens, validates,    │
  │        │       ai_fallback, section ai{open...}               │ closes requests      │
  │ AiRelay│                                                      └──────────────────────┘
  │ AiCache│  ── request (NDJSON ai/1) ──▶ ┌───────────────────────────────┐
  │ AiBridge  ◀─ result ───────────────── │ ai/service.ail (own process)  │──▶ provider (stub | gemini)
  └────────┘                               │ writes blobs + index to the   │
       │  reads index, plays blobs         │ player's cache dir            │
       ▼                                   └───────────────────────────────┘
  user://ai_cache/  ·  res://ai_core/ (bundled)  ·  gs://stapledons-voyage-assets/ai/ (maintainers)
```

Three rules hold everywhere:
1. **The sim decides what is asked and what is accepted.** Every request has a
   sim-assigned id; every result is checked by pure code; the text Godot shows
   is the text the sim accepted (it comes back in an event), never the raw
   service output. This is M4's display-audit principle applied to AI text.
2. **Only inputs cross into the sim.** Provider, model, tokens, latency and
   cost are logged beside the session (`usage.ndjson`), never sent to the
   sim, because they are not deterministic.
3. **Media bytes never enter the sim or the log.** A record names an asset by
   its sha256 and describes it (mime, size, duration, segment offsets). The
   sim's state depends only on those fields, so replays need no blobs.

### (a1) Protocol 2.1 in the sim

`helloMsg` answers `proto {major: 2, minor: 1}`. The bridge still requires
major 2. `AiRelay` enables AI only when minor ≥ 1, so an old sim simply runs
on templates.

**New intents** (tagged by `k`, decoded in `sim/protocol.ail`, applied by a
new pure module `sim/ai.ail` that `core.tick` calls):

| `k` | Fields | Accepted when | Effect |
|---|---|---|---|
| `ai_open` | `kind`, `purpose`, `entity_id`, `emotion?`, `age_stage?`, `line_req?`, `emotions?`, `context?` | the fields validate (table below); fewer than `ai_max_open` requests are open | opens a request; emits `ai_request` |
| `record` | `source`, `req`, `kind`, `sha256`, `body` (the reserved 2.0 shape, unchanged) | `req` names an open request | validates; emits `ai_accepted`, or `ai_fallback` with the refusal reason; closes the request |
| `ai_cancel` | `req`, `reason` ∈ `offline`, `no_key`, `text_only`, `timeout`, `service_down`, `budget`, `provider_error` | `req` is open | emits `ai_fallback{req, reason}`; closes the request |

**Validation of `ai_open`** (refusals; nothing is opened, the tick proceeds):

| Reason | Check |
|---|---|
| `ai_kind` | `kind` not one of `text`, `voice`, `portrait`, `avatar`; or `purpose` not one of `line`, `news`, `archive`, `probe` (`probe` in diag only, else `diag_only`) |
| `ai_bad_key` | `entity_id` fails `^[a-z][a-z0-9_]{0,31}$`; `emotion` not one of the 8 (or present for `voice`/`avatar`); `age_stage` not a whole number in [0, 1000]; `emotions` empty or naming an unknown emotion |
| `ai_stale` | `voice`: `line_req` is not among the last 64 accepted lines (`ai.lines`) |
| `ai_too_many` | `ai_max_open` requests are already open (scenario parameter, default 8, range 1–64) |

`context` is an object of at most 8 string or string-list fields (`topic`,
`canon` as lore entry ids, …), copied into the event unchanged; anything else
is `bad_intent`. The sim does not interpret it, and it does not affect state.

The sim also opens requests itself, deterministically, when its own rules call
for one. In this foundation that is only a diag hook (`ai_open` in a diag
session may set `purpose: "probe"`); M4.1 adds the arrival news request, which
takes its template id from the `news` stream as M4 specifies. Both paths
produce the same `ai_request` event.

**Request ids.** `World` gains `ai: AiState = {lastReq: int, open: [OpenReq],
lines: [Line], core: string}`. Ids are `lastReq + 1`, monotonic and never
reused (as plan ids are, `World.lastPlanId`); on the wire `req` is the decimal
string, because the reserved `record.req` is a string. `open` is kept in
opening order. `OpenReq = {req, kind, purpose, key: CacheKey, constraints,
seed, openedTick, expiresTick}`.

**Seeds.** Each opened request draws one value from the existing `ai` PRNG
stream (`sim/rng.ail`, stream id 5, unused until now) and carries it as
`seed` (top 53 bits, an exact JSON integer). Providers that accept a seed get
it; the seed is in the log either way.

**The `ai_request` event** carries everything the relay and the service need,
so neither reads sim state:

```json
{"k":"ai_request","req":"7","kind":"text","purpose":"line",
 "key":{"kind":"text","entity_id":"medic","emotion":"-","age_stage":0,"variant":"-"},
 "seed":123456789012345,
 "constraints":{"max_chars":280,"no_numerals":true,"emotions":["neutral","loving","grieving"]},
 "context":{"topic":"first_night_aboard","canon":["archive.two-clocks"]},
 "expires_tick":3607}
```

**Validation of a `record`** (pure, in `sim/ai.ail`, run on the strict VM).
Each failure is a **refusal**, listed in `refused` with `status: "ok"`, as in
M2's rejection model. It also closes the request with
`ai_fallback{req, reason}`, so the template stands and nothing can retry on
the same id. A record with a missing or mistyped field stays `bad_intent`
(malformed), unchanged from 2.0.

| Reason | Check |
|---|---|
| `ai_source` | `source` ≠ `"ai"` |
| `ai_unknown_req` | `req` is not open: never opened, already closed, or expired. This one does not close anything |
| `ai_kind` | `kind` ≠ the open request's kind |
| `ai_hash` | text kinds: `sha256` ≠ `sha256Hex(body)` (UTF-8, lowercase hex; V2, V5). Media kinds: `sha256` is not 64 lowercase hex characters |
| `ai_length` | text: `std/string.length(display text) > max_chars` (code points; V5) |
| `ai_numeral` | text with `no_numerals`: any ASCII digit `0-9` in the display text |
| `ai_markup` | text: the body fails the marker grammar (b) |
| `ai_emotion` | text: a marker names an emotion not in `constraints.emotions` |
| `ai_descriptor` | media: `body` is not the descriptor JSON for the kind, or its `key` ≠ the request's key, or (voice) its segment count ≠ the line's segment count, or offsets are not strictly increasing from 0 and below `duration_ms` |

**Accepted results.** Text: `ai_accepted{req, kind, sha256, text, segments:
[{emotion, text}]}`, with segments from the parser (b). The sim keeps the
last 64 accepted lines in `ai.lines` (`{req, entity_id, segments}`) so a voice
request can name one (`line_req`); an older one is refused `ai_stale`. Media:
`ai_accepted{req, kind, sha256, descriptor}`. Nothing else in the world
changes in this foundation. M4.1 consumes accepted news text into its news
state.

**Expiry.** `expiresTick = openedTick + ai_ttl_ticks`, a new scenario
parameter (default 3600, range 1–10⁶). A tick that passes it emits
`ai_fallback{req, reason: "expired"}` and closes the request. This is a
deterministic backstop: Godot normally cancels first on its own timeouts.

**Commit rule.** `ai_open`, `record` and `ai_cancel` are accepted while a
journey is committed. They never touch `ship`, `journey`, `ledger` or the
`journey`/`crew`/`events`/`galaxy`/`news` streams. `refuseWhileCommitted`
keeps one arm per constructor and no wildcard: the three AI arms delegate to
`sim/ai.ail` and every journey intent is still refused `committed`. This
changes M2 AC7's wording from "every intent kind" to "every journey intent";
`checkCommittedRefusesAll` keeps sending every constructor, and a new
`checkAiNeverTouchesJourney` asserts that journey, ship and ledger are
byte-identical after any AI intent. It is **open question 1**, because it
touches Pillar 1.

**State.** A new change-set section `ai: {last_req, open: [{req, kind,
expires_tick}], core}` follows M2's rules: whole section, present only when
changed, and always in full states. `new_game` gains an optional `ai_core`,
the sha256 of the bundled core index (below); it is echoed in `ai.core`, so
every log names the asset set its session saw.

**Goldens.** The hello's `minor` and the full state's new `ai` section change
the first lines of every existing golden. `make replay-record LOG=all`
regenerates them as one reviewed diff. `make replay-compat` checks that, apart
from those two fields, every 2.0 golden is unchanged.

### (a2) The AI service process

**Package.** `ai/` is its own AILANG package, `stapledons/ai`, with
`[effects] max = ["IO", "FS", "Env", "Net", "AI"]`. The sim package keeps
`["IO", "FS"]`, and CLAUDE.md's "I/O belongs in `sim/ship.ail` only" stays
true for the sim. The service imports nothing from `sim/`: a local path
dependency writes an absolute path into `ailang.lock`
(`docs/guides/build-a-motoko-extension.md` §Path vs registry), which breaks CI
and the bundled runtime (gap G5). It doesn't need the sim's code anyway: it
receives the sim's parsed segments in the request.

**Modules.**
- `ai/wire.ail` (pure): the request/result codec, with hand-written inverse
  pairs and round-trip tests, as in M2.
- `ai/key.ail` (pure): `CacheKey`, canonical string form, validation.
- `ai/prompt.ail` (pure): prompt building from request + cast manifest + lore
  snippets + guardrails. Prompts are goldens.
- `ai/provider.ail`: `Provider = Stub | Gemini(Models)`. The stub is pure.
  The Gemini adapters: text through `std/ai.step(model, ...)` (per-call
  model); images through `std/ai.callImageBase64`; TTS through
  `std/net.httpRequest` to the Gemini TTS endpoint until gap G1 lands. Each
  adapter is a thin effectful call around a pure `parse…Response` function
  that is tested on committed response fixtures.
- `ai/cache.ail`: blob writes and index appends (FS).
- `ai/spend.ail` (pure): the price table (`data/ai/prices.json`) × reported
  tokens or characters → USD; the session ledger; the ceiling check.
- `ai/service.ail`: the I/O loop (read → decode → handle → print), the only
  code with effects besides the adapters and the cache.

**Wire (protocol `ai/1`).** One JSON object per line, `"v": 1`.

| Direction | `type` | Body |
|---|---|---|
| G→A | `hello` | `want: {major: 1}` |
| A→G | `hello` | `proto: {major: 1, minor: 0}`, `service`, `provider` (`stub` or `gemini`), `models: {text, image, tts}`, `live` (bool), `cache_dir` |
| G→A | `request` | the sim's `ai_request` event fields, plus the cast entry for `entity_id` and, for voice, the line's segments |
| A→G | `result` | `req`, `status: "ok"`, `kind`, `sha256`, `body` (exactly the future `record.body`), `asset?: {path, mime, bytes}`, `meta: {provider, model, input_sha256, ms, usd}` |
| A→G | `result` | `req`, `status: "error"`, `code` ∈ `bad_request`, `no_key`, `budget`, `provider_error`, `bad_output`, `timeout_internal` |
| G→A | `quit` | |

The service handles one request at a time, because `readLine` blocks and
AILANG has no async I/O. Each handler is annotated `! {AI @limit=3}` (one call
and at most two in-handler retries on `bad_output`). The capability budget is
the backstop against a runaway loop; the USD ceiling is `ai/spend.ail`.

**Launch command** (built by `bridge/ai_bridge.gd`, mirroring the sim's
`_run_args` and its bundled-runtime `HOME` trick):

```
# stub (tests, CI, the loop, and any session without opt-in):
ailang run --quiet --bytecode --package-dir ai --caps IO,FS --entry main ai/service.ail \
    -- --provider stub --cache-dir <user://ai_cache>
# live (player opted in, key present):
/bin/sh -c 'GOOGLE_API_KEY="$(cat "$1")" GOOGLE_APPLICATION_CREDENTIALS=/nonexistent exec "$0" "$@"' \
    <ailang> <keyfile> run --quiet --bytecode --package-dir ai --caps IO,FS,Env,Net,AI \
    --ai <text model> --net-allow-domains generativelanguage.googleapis.com \
    --entry main ai/service.ail -- --provider gemini --cache-dir <...> --ceiling-usd <x>
```

The key never appears in argv, only the key file's path (the wrapper's `$1`)
does, so `ps` never shows it. The env override points ADC at a nonexistent
file, and the service refuses `--provider gemini` unless `GOOGLE_API_KEY` is
non-empty (`std/env.hasEnv`). Without that refusal, the silent ADC fallback
(Problem 3) could spend on whatever gcloud identity the machine has. Gap G4
asks AILANG for a first-class switch. Model ids come from
`data/ai/models.json` (`text: gemini-2.5-flash`, `image:
gemini-2.5-flash-image`, `tts: gemini-2.5-flash-preview-tts` at the time of
writing). They are configuration, not code: swapping a model is a data change
plus regenerated prompt and adapter fixtures.

**Stub provider** (pure, deterministic, needs no capability beyond IO and FS
for the cache):
- text: `"{neutral} Stub line <req> for <entity_id>."`, varied by purpose
  and trimmed to `max_chars`. A fixture table `ai/fixtures/stub_text.json`
  (keyed by purpose) adds the negative cases: a digit (`digits`), an
  over-length line, a bad marker, an unlisted emotion.
- image: a committed 64×64 placeholder PNG per emotion
  (`ai/fixtures/stub_portrait_<emotion>.png`).
- voice: deterministic PCM (one tone per segment, its length from the segment's
  text length) through `std/audio.encode(..., OggOpus(24000))`. That encode is
  byte-identical across architectures (std/audio docs §Determinism), so the
  stub's blob hashes are goldens.

`--ai-stub` (AILANG's own stub handler) is a second, narrower lane. It runs
the **Gemini text and image adapters** with the AI capability but no network,
and checks they turn `{"kind":"Wait"}` into `bad_output` and the 1×1 PNG into a
valid descriptor. That lane proves the adapter wiring without spending.

### (a3) Godot: launch, supervision, relay

Three new scripts, none of which touch the sim's blocking path:

- **`bridge/ai_bridge.gd`** (`AiBridge`, a `Node`): launches the service with
  `OS.execute_with_pipe`. It reads **non-blockingly** in `_process` (it polls
  `get_buffer` and never loops on a deadline) and keeps a FIFO with priority
  `text > voice > portrait`, with one request in flight.
  - *Lazy start:* it launches on the first request that misses the cache, and
    only if live AI is on, or always in stub mode (tests).
  - *Handshake:* `hello` within 5 s, and `proto.major == 1`.
  - *Timeouts:* text 30 s, voice 60 s, portrait 120 s. On a timeout it kills
    the child, sends `ai_cancel{reason: "timeout"}` and restarts lazily.
  - *Crash (`child_eof`):* it restarts with backoff 1 s, 4 s, 16 s. After 3
    failures within 10 minutes the service is **disabled for the session**:
    every queued and open request gets `ai_cancel{reason: "service_down"}`
    and the UI shows a one-line toast ("Live voices unavailable: using the
    ship's archive").
  - *Shutdown:* `quit`, then 1 s grace, then kill, as the sim bridge does.
- **`bridge/ai_relay.gd`** (`AiRelay`): subscribes to the sim's `last_events`
  after every `SimBridge.send`. For each `ai_request`:
  1. It resolves the key in the cache (below). A hit queues the `record`
     straight away with the cached sha256 and descriptor; text hits are core
     lines only. A hit costs nothing and is still recorded, so even a
     cache-hit session replays from its log.
  2. Otherwise, if live AI is off or there is no key, it queues
     `ai_cancel{reason: "text_only" | "no_key" | "offline"}`.
  3. Otherwise it forwards to `AiBridge`. An `ok` result becomes a `record`
     intent; an `error` result becomes an `ai_cancel` with the mapped reason.

  Queued intents ride on the **next** `send(intents, dtau)`. The tick never
  waits, and the `record_path` tee writes them into the input log like any
  intent. Text-only mode means `AiRelay` never sends `ai_open` for voice or
  portrait. Text still works, and portraits still swap from the core set.
- **`bridge/ai_cache.gd`** (`AiCache`): reads the index layers and resolves a
  key, then a blob path.

A record arrives a few ticks after its request, at whatever tick Godot sends
it. That tick is in the log, so latency changes the session but never the
replay.

### (a4) Cache layout and the bucket

**Key.** `CacheKey = {kind, entity_id, emotion, age_stage, variant}`, with
canonical string `kind/entity_id/emotion/age_stage/variant`:

| Field | Values |
|---|---|
| `kind` | `text`, `voice`, `portrait`, `avatar` |
| `entity_id` | `^[a-z][a-z0-9_]{0,31}$`, one **person** (a descendant is a new id, never an age variant; cast plan), or `archive` |
| `emotion` | one of the 8 (`neutral happy sad angry fearful curious loving grieving`), or `-` for kinds without one (`avatar`, `voice`) |
| `age_stage` | whole years since departure that the asset depicts (Medic: 0, 50). Lookup takes the greatest stage ≤ the person's current years aboard, from the sim's τ |
| `variant` | images: `"0"`, `"1"`, …; `voice` and `text`: the first 16 hex characters of `sha256(voice_id + "\n" + marked-up text)` or of the prompt, so a voice line is keyed by what is said |

**On disk** (the same layout in every layer):

```
<layer>/index.ndjson        append-only; one line per asset
<layer>/blobs/ab/<sha256>.<ext>
```

Index line:

```json
{"key":{"kind":"portrait","entity_id":"medic","emotion":"grieving","age_stage":0,"variant":"0"},
 "sha256":"…","mime":"image/png","bytes":2287104,"ext":"png","origin":"core",
 "provider":"imagegen","model":"…","input_sha256":"…","seed":null,
 "source":"blender@<commit>:assets/stapledon/characters/medic_v2/portrait_medic_age0_grieving_v2.png"}
```

Voice lines add `duration_ms` and `segments_ms`; images add `width` and
`height`.

**Layers and precedence.**
1. **Core**, `res://ai_core/`, read-only, bundled into builds. The index and
   `SHA256SUMS` are in git under `data/ai/core/`. Blobs are in the public
   bucket as `gs://stapledons-voyage-assets/ai/<sha256>.<ext>`, the same
   content-addressed, immutable scheme as `sky/` (D-18, `infra/gcp/README.md`).
   They are fetched by `make ai-core-assets` (pinned, sha-checked, like
   `make sky-assets`) and staged by `make ai-core-bundle` into the export.
   `make ai-core-publish` (maintainers, gcloud auth) uploads them with
   `--no-clobber`. The sha256 of `index.ndjson` is the `ai_core` value sent in
   `new_game`.
2. **Player library**, `user://ai_cache/`, written only by the service (a
   single writer; Godot reads it and reloads after each result). It also
   holds `usage.ndjson` (per call: req, provider, model, tokens or characters,
   USD, ms). Default cap 2 GB, evicting least-recently-used generated blobs.
   Eviction cannot break a sim replay, because the log holds no bytes.
3. **Bucket**, maintainers only. The game never fetches at run time unless
   Mark chooses that in **open question 2**.

**For the same key, core wins over the library.** Accepted art is canonical;
the library only fills gaps. Within the library, the newest line for a key
wins.

**Pre-generated core content in this foundation.** The Medic set (4
portraits, 1 avatar) from `~/dev/blender` at a pinned commit, imported by
`ai/tools/core_import.ail` (AILANG with FS; it hashes with
`std/crypto.sha256Bytes`, per the Python policy), plus the (c) line's voice
once Mark accepts it. The other ten identities join as the art pipeline
delivers emotion sets.

**Replay with the service absent.** `make replay` already replays any input
log on both runtimes. A 2.1 log contains `ai_open`, `record` and `ai_cancel`
lines, so the sim re-validates the same bodies and emits the same events with
**no service and no cache**. The relay and the service are never started in
replay (`AiBridge.launch_count == 0`, asserted). A *visual* replay through
Godot plays blobs if the layers have them. Otherwise it shows the accepted
text, swaps portraits from core, and skips missing audio, flagging
`missing_blob` in its own log. The sim stream is unaffected either way.

### (a5) Key and cost UX

- **Off by default.** Settings → "Live AI (uses your own Google AI key)". It
  stays off until a key is present **and** the player ticks the opt-in. The
  panel states the per-kind price estimate from `data/ai/prices.json` (text
  line, voice line, portrait) and the session ceiling.
- **Key sources, in order:** the `GOOGLE_API_KEY` environment variable of the
  game process, or a key pasted into Settings and saved to `user://ai_key`
  with mode 0600 (`chmod` via `OS.execute`, as `_unpack_runtime` does).
  Godot has no keychain API; **open question 3** asks whether that is
  acceptable for R1. The key is never logged, never written to the session log
  and never put in argv (above). A test greps for it.
- **Ceiling.** The service keeps a session spend ledger and refuses with
  `budget` once `--ceiling-usd` would be exceeded (default in **open question
  4**). The HUD's AI indicator shows the running cost from the `meta.usd`
  sums. `budget` becomes `ai_cancel{reason: "budget"}`, so the game falls back
  to templates and core.
- **Text-only** (always available, D-8): a Settings toggle, plus a
  `--text-only` launch flag. No voice or portrait requests are made; core
  portraits still swap by marker.
- **Who spends during development.** CI, `make test` and the unattended loop
  always run the stub with `--caps IO,FS`. Live calls happen only in attended
  sessions with `AI_LIVE=1` and a key file. `make ai-live-guard` (in
  `make test`) fails if any target or test can launch the service with
  `--provider gemini` without `AI_LIVE=1`. The project key question is
  **open question 5**.

### (b) The emotion-marker grammar and parser

One grammar, implemented once in `sim/markers.ail` (pure, strict VM), used by
the sim's validation. The service and Godot consume the parsed segments the
sim emits; neither has its own parser.

```
line     = [marker] text { marker text }
marker   = "{" emotion "}"
emotion  = "neutral" | "happy" | "sad" | "angry" | "fearful" | "curious" | "loving" | "grieving"
text     = 1*char-except("{", "}", "[", "]")
```

- A missing leading marker means `neutral`.
- Errors (`ai_markup`): an unknown emotion, an unbalanced or nested brace,
  an empty segment (two markers in a row, or a marker at the end), any `[` or
  `]` (keeps provider tags such as Gemini's `[sigh]` out of game text), more
  than 16 segments.
- Adjacent equal markers merge. Segment text keeps its inner whitespace and is
  trimmed at both ends; the display text is the segment texts joined with
  single spaces.
- Curly braces were chosen over square brackets for Problem 6
  (**open question 6**).
- `printLine(parseLine(x)) == normalise(x)` for every valid fixture, and
  `parseLine(printLine(s)) == s` for every segment list (round trip, as M2's
  codecs).
- **Delivery mapping** lives in data, not code. `data/ai/emotion_styles.json`
  maps each emotion to a provider-neutral style sentence ("Speak softly, with
  the weight of loss") used per TTS segment.
- **Portrait fallback** when a person lacks an emotion: `happy→loving→neutral`,
  `loving→happy→neutral`, `sad→grieving→neutral`, `grieving→sad→neutral`, and
  `angry`, `fearful`, `curious` → `neutral`. Requests list
  `constraints.emotions` as the emotions the person actually has in the
  layers, so a model is told the palette, and the fallback is a safety net
  for core-only replays.

Tests: `sim/markers_test.ail` with every error code, the round-trip
properties over a fixture set (including non-ASCII text and 16-segment
lines), and a strict-VM entry `markersVm` in `make strict`.

### (c) Medic voice and portrait swap style frame ⏸ (stops for Mark)

1. **TTS per segment.** The service synthesises each segment with the Medic's
   voice and that segment's emotion style, concatenates the PCM (24 kHz s16le
   mono), and encodes once with `std/audio.encode(OggOpus(24000))`. The
   segment offsets are exact, from `durationMs` of each PCM prefix, so the
   record's descriptor carries `segments_ms` and the portrait swaps happen at
   those times. The alternative is one call per line with offsets estimated
   from text length; it has better prosody but worse timing. Mark chooses at
   the stop (**open question 7**).
2. **Cast entry.** `data/ai/cast/medic.json`: identity, departure age 35,
   persona text, `voice_id`, `style`, and the core portrait keys. The voice
   choice is recorded back into the Blender `manifest.json` (brief §6) by the
   art pipeline, not by this repo.
3. **Conversation UI.** `ui/conversation/conversation.{tscn,gd}`: a large
   portrait (crossfade length is a parameter, default 120 ms), a subtitle line
   that reveals segment by segment, and the audio player. It reads only the
   sim's `ai_accepted` events and the cache. It opens on `--conversation=medic`.
4. **The line.** It is generated once, live, in an attended session through
   the real path (sim → relay → service → Gemini), with `emotions:
   ["neutral", "loving", "grieving"]` (Problem 4, **open question 8**). The
   session is recorded through the tee to
   `tests/replays/medic_style_frame.ndjson` and committed. Its voice blob
   joins the core layer after Mark accepts it.
5. **Capture for Mark.** `make ai-style-frame` replays that committed log
   through Godot with the blobs. It writes `renders/ai_medic/` (a PNG at each
   swap plus a contact sheet) and `renders/ai_medic/line.ogg`, and records the
   sequence with Godot's movie writer (`--write-movie renders/ai_medic/frame.avi`,
   audio included). A reviewer opens and looks at all of them.
6. **⏸ Stop.** Mark reviews three voice auditions of the same line
   (**open question 9**), the swap timing (at the segment start, or 150 ms
   early), and the crossfade length. Nothing past (c) proceeds before his
   answer.

### Amendment 2026-10-02: both providers

Mark, attended 2026-10-02: "so have both options - the ailang demos use them
all". This narrows D-8 (2) "model-neutral, Gemini as default" for text. The
sprint plan's "Plan change: both providers" section carries the full table;
this section makes the design agree with it. Where it conflicts with the text
above, this section wins.

| Topic | Before | Now |
|---|---|---|
| Providers | `Stub \| Gemini(Models)` | `Stub \| Gemini(Models) \| OpenRouter(Models)` (`ai/provider.ail`). OpenRouter is built into `std/ai` on the v0.51.0 pin for **text** (chat completions) with `openrouter:vendor/model` ids; it refuses image output and has no TTS |
| Routing | one provider per session | `data/ai/routing.json`: per request kind an ordered list of `{provider, model}`, resolved by the pure `ai/route.ail` against the set of keys present. Defaults: `text` → OpenRouter, then Gemini; `portrait`, `avatar` → Gemini only; `voice` → Gemini only. The first entry whose key is present wins; with none the result is `no_key` and the game stays on templates. A config that lists OpenRouter for a media kind, names an unknown provider, gives a model without a provider, or leaves a kind unrouted is refused at start |
| Keys | `GOOGLE_API_KEY` only | Both optional: `GOOGLE_API_KEY` and `OPENROUTER_API_KEY` (env, or one 0600 file each, AI.9). With neither, text-only. Stub mode simulates the key set (`keys_present`); live mode reads it from the env (AI.5) |
| Text-only mode | relay never opens voice/portrait | also enforced by the service: media kinds answer `text_only` |
| Wire `ai/1` | hello carries `models: {text, image, tts}`; result `meta: {provider, model, …}` | hello carries `routes: {<kind>: {route, model} \| {route: "none", reason}}` (it replaces `models`); results carry `meta.route`, the provider the table chose. The stub answers as `provider: "stub"` with `meta.route` set, so the stub goldens show the routing. Error results carry `meta: {provider, route}`; `text_only` joins the error codes; a bad configuration prints one `fatal {code: "config", detail}` line |
| Service configuration | argv flags (`-- --provider stub --cache-dir …`) | the entry argument (`--args-json` / `--args-file`): `{provider, keys_present, text_only, cache_dir, routing, fixtures}`. argv needs the `Env` capability, and the stub runs with `--caps IO,FS` only, so it cannot read a key at all |
| Cost | one price table | `prices.json` keyed by provider and model; per-provider totals in the spend ledger and `usage.ndjson`; the one player-set ceiling (default US$0.50) applies to the sum (AI.5, AI.9) |
| Build keys | `gemini-api-key` | plus `openrouter-api-key` in Secret Manager (project `stapledons-voyage`); either may be missing (AI.8, AI.10b) |
| Network allowlist (live) | `generativelanguage.googleapis.com` | plus `openrouter.ai` |

AI.4 as built (stub only, `--caps IO,FS`): stub text is
`"{e} Stub <purpose> <req> for <entity_id>."` with `e` the first allowed
emotion and the request number **spelled in words** while `no_numerals`
holds, so the stub line itself passes `ai_numeral`; the fixture cases are
chosen by the context field `stub_case`. The library writes text results as
`.txt` blobs too (index line with `origin: "library"`, no clock, no request
id), which is what lets `make ai-stub` check every text hash against
`shasum -a 256`. Stub voice arrives with AI.5; until then a routed voice
request answers `provider_error`.

### Follow-up: the AI model bake-off (after AI.10b)

Mark, attended 2026-10-02: "we may actually run with models and compare their
runs, like an elaborate eval test." This is queued as its own item (charter
queue row 4b) and is **not** part of this sprint's scope; it is recorded here
because the foundation already provides what it needs.

**Idea.** Replay one recorded voyage several times, each time with the text
route pinned to a different model, and compare what each model writes for the
same moments in the game.

**Why the foundation makes this cheap:**

- **Same game for every model.** The sim is deterministic and the AI never
  feeds back into physics, so every run sees byte-identical `ai_req` lines (same
  purpose, entity, context, emotion budget). Only the generated text differs.
- **Swapping models is a config change.** OpenRouter text goes over `std/net`
  (AI.5, ailang#1536), so any `openrouter:vendor/model` id works by naming it in
  `data/ai/models.json` / `routing.json`. Gemini models go through `std/ai`.
- **Results are already labelled.** Every cache index and `usage.ndjson` line
  carries provider, route, model, tokens and nano-dollar cost.
- **Automatic scoring is already written.** The reply screen (`bad_output`) and
  the sim's record validation (length caps 280/280/600, `ai_numeral`,
  `ai_markup`, the marker grammar) give a per-model pass rate with no extra code.

**Shape (to be designed properly when it is picked up):**

- **Input.** A recorded request stream: the `ai_req` lines from a fixed voyage
  replay, plus the context each one carried.
- **Driver.** `make ai-bakeoff MODELS="…"`. For each model it starts the service
  in `live` mode with a routing table that names only that model and writes to its
  own cache directory (`bakeoff/<run>/<model>/`), so runs never mix and never touch
  the game's cache.
- **Scores per model:**
  - pass rate through the screen and the sim's validation, with the reasons
    for each refusal;
  - latency (p50/p95);
  - tokens and cost per voyage;
  - marker-grammar use (are the emotions used, and used sensibly).
- **Quality.** Done blind: a judge model rates tone, lore consistency (against
  `data/ai/lore.json` and the Higgs-bubble canon) and in-character voice, and Mark
  rates a blind sample. The judge model is never one of the contestants.
- **Output.** A side-by-side report (an Artifact page: one row per request, one
  column per model, scores in the header) plus a JSON summary under
  `.ailang/state/evaluations/`.

**Constraints:**

- **Attended only:** `AI_LIVE=1` plus a TTY, as for AI.10b, with Mark present.
  The unattended loop never runs it.
- **Spending caps:** a per-model ceiling and a total ceiling for the whole run,
  enforced by the spend ledger. One voyage across about 5 cheap text models
  should cost cents.
- **Kept out of the game:** bake-off outputs never enter the game's replay
  goldens or the shipped cache.
- **Choosing the default model:** changing the game's default text model is a
  ledger decision for Mark, informed by the report.
- **Text only at first.** Portraits and voice could follow later, at a higher
  cost.

**Estimate.** About 350 LOC: the driver, the scorer, the report generator and
the judge prompt.

## Acceptance criteria

`$A` is the pinned v0.51.0 `ailang` (`AILANG=$A` on every make line).
`$S` is the AI stub suite's scratch directory.

| # | Criterion | Command |
|---|---|---|
| AC1 | Protocol 2.1: `hello` answers minor 1; the bridge still accepts major 2 and refuses any other | `cd sim && $A test --package .` (`checkHello21`) and `godot --headless --path . --script tests/test_sim_bridge.gd` |
| AC2 | `ai_open`, `record` and `ai_cancel` codecs round-trip every fixture; malformed fields stay `bad_intent` | `cd sim && $A test --package .` (`protocol_test.ail`: `checkAiCodecs`) |
| AC3 | Validation: each `record` refusal (`ai_source`, `ai_unknown_req`, `ai_kind`, `ai_hash`, `ai_length`, `ai_numeral`, `ai_markup`, `ai_emotion`, `ai_descriptor`) fires on its fixture and closes the request with `ai_fallback` (except `ai_unknown_req`); each `ai_open` refusal (`ai_kind`, `ai_bad_key`, `ai_stale`, `ai_too_many`, `diag_only`) opens nothing; the tick proceeds in every case | `cd sim && $A test --package .` (`checkAiRefusals`, `checkAiOpenRefusals`) |
| AC4 | One outcome per request: a second record for a closed request is `ai_unknown_req`; expiry at `expires_tick` emits `ai_fallback{expired}`; ids are monotonic and never reused | `cd sim && $A test --package .` (`checkAiOnce`, `checkAiExpiry`, `checkAiIds`) |
| AC5 | AI intents while committed: accepted, and journey, ship and ledger are byte-identical after them; every journey intent is still refused `committed` | `cd sim && $A test --package .` (`checkAiNeverTouchesJourney`, `checkCommittedRefusesAll`) |
| AC6 | Text hashes: the sim's `sha256Hex(body)` equals the service's and an independent reference, including non-ASCII bodies | `cd sim && $A test --package .` (`checkAiHash`) and `make ai-stub AILANG=$A` (the harness compares against `shasum -a 256`) |
| AC7 | The pure modules (`sim/ai.ail`, `sim/markers.ail`, `ai/wire.ail`, `ai/key.ail`, `ai/prompt.ail`, `ai/spend.ail`) run on the strict VM and equal the interpreter | `make strict AILANG=$A` (entries `aiVm`, `markersVm`, `aiWireVm`) |
| AC8 | Stub service, no capability to spend: run with `--caps IO,FS` only over `tests/ai/requests.ndjson`; its stdout equals `tests/ai/results.golden.ndjson` and the written index and blob hashes equal `tests/ai/cache.SHA256SUMS`, identical on VM and interpreter | `make ai-stub AILANG=$A` |
| AC9 | Adapter wiring without network: under `--ai-stub` the Gemini text adapter returns `bad_output` and the image adapter a valid descriptor; the TTS and text parsers decode the committed response fixtures | `make ai-adapter AILANG=$A` |
| AC10 | End to end through Godot: sim + stub service; `ai_open` → `ai_request` → service → `record` → `ai_accepted` for text, voice and portrait; a cache hit records without starting the service; the session log is written by the tee | `godot --headless --path . --script tests/test_ai_relay.gd` |
| AC11 | Supervision: a fake service that hangs, crashes or prints garbage leads to `ai_cancel{timeout}`, restarts with backoff, and `service_down` after 3 failures; the sim tick never waits (each `send` returns within the M2 step deadline) | `godot --headless --path . --script tests/test_ai_relay.gd -- --faults` |
| AC12 | Replay with the service absent: the Godot-recorded AI session and `medic_style_frame.ndjson` replay byte-identically on VM and interpreter against their goldens; the replay starts no AI process | `make replay AILANG=$A` (cases `ai_stub_session`, `medic_style_frame`) and `make replay-noai` (asserts `AiBridge.launch_count == 0`) |
| AC13 | Re-recorded 2.0 goldens differ from the old ones only in the hello `minor` and the full state's `ai` section | `make replay-compat AILANG=$A` |
| AC14 | Key hygiene: with a fixture key file, the key text is absent from the session log, the service stdout, `usage.ndjson` and the child's argv; `--provider gemini` without `GOOGLE_API_KEY` refuses to start | `godot --headless --path . --script tests/test_ai_relay.gd -- --key-hygiene` |
| AC15 | No spend in automation: no target or test can start the service with `--provider gemini` unless `AI_LIVE=1` | `make ai-live-guard` |
| AC16 | Marker grammar: every error code fires; the parse/print round trips hold over the fixtures (non-ASCII, 16 segments, merges) | `cd sim && $A test --package .` (`markers_test.ail`) |
| AC17 | Core layer: the Medic set's index and `SHA256SUMS` match the pinned Blender files; `ai-core-assets` fetches and verifies them; the bundle stage includes them | `make ai-core-verify` |
| AC18 | M4's interface: a `purpose: "news"` request with `no_numerals` and `max_chars` returns through the stub; the `digits` fixture is refused `ai_numeral` and the template stands | `godot --headless --path . --script tests/test_ai_relay.gd -- --news` |
| AC19 | Style frame (c): the capture exists, with a PNG at each swap, the contact sheet, `line.ogg` and `frame.avi`; all opened and looked at; Mark's answer recorded in the ledger | `make ai-style-frame && test -s renders/ai_medic/contact_sheet.png && test -s renders/ai_medic/line.ogg`, then the ledger row |
| AC20 | Whole suite green, with the new targets in `make test` (`ai-stub`, `ai-adapter`, `ai-live-guard`, `replay-compat`, `ai-core-verify`; `ai-style-frame` is attended, not in `make test`) | `make test AILANG=$A` |

## Sub-milestones and estimates

| Sub | Content | LOC (code + tests) | Depends on |
|---|---|---|---|
| (a1) | Protocol 2.1: `sim/ai.ail`, codecs, `AiState`, expiry, commit-rule arms, `ai_core`, goldens re-recorded, `replay-compat` | 300 + 330 | M2 |
| (a2) | `ai/` package: wire, key, prompt, stub, spend, cache writer, service loop, Gemini text/image adapters, TTS adapter skeleton, `ai-stub` and `ai-adapter` targets, fixtures | 560 + 300 | (a1) wire shapes |
| (a3) | `AiBridge`, `AiRelay`, `AiCache`; fake service for faults; `test_ai_relay.gd`; `replay-noai`; key hygiene | 380 + 260 | (a1), (a2) |
| (a4) | Core layer: `core_import.ail`, `data/ai/core/`, `ai-core-assets`/`-bundle`/`-publish`/`-verify`, bucket prefix `ai/` | 120 + 40 | (a2) |
| (a5) | Settings: opt-in, key entry, ceiling, text-only, HUD cost indicator; `ai-live-guard` | 160 + 60 | (a3) |
| (b) | `sim/markers.ail`, `emotion_styles.json`, portrait fallback table, `markers_test.ail`, `markersVm` | 120 + 180 | — (parallel with (a1)) |
| (c) ⏸ | Per-segment TTS and Ogg encoding, Medic cast entry, conversation UI, attended live line, `medic_style_frame` replay, `ai-style-frame` capture | 260 + 80 | (a1)–(a5), (b) |
| **Total** | | **≈1,900 + 1,250 ≈ 3,150** | |

Order: (a1) ∥ (b) → (a2) → (a3) ∥ (a4) → (a5) → (c) ⏸. Milestone (a) in
D-9's sense is (a1)–(a5), (b) is (b), and (c) is (c). (a) and (b) need no key
and spend nothing. (c) needs one attended live session, estimated at well
under US$0.10 for one short line, three voice auditions and a few retries.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Silent ADC fallback spends on a developer's gcloud identity | The wrapper points `GOOGLE_APPLICATION_CREDENTIALS` at a nonexistent file; the service refuses `gemini` without `GOOGLE_API_KEY`; automation runs with `--caps IO,FS` (no AI capability at all); AC14, AC15; gap G4 upstream |
| No TTS in `std/ai`, so the TTS adapter calls the HTTP API directly and bypasses provider routing (D-8 (2)) | Isolated in one adapter with a pure response parser and fixtures; replaced by `std/ai` speech when gap G1 lands; until then "model-neutral" holds for text and images, and TTS swaps by `models.json` plus adapter |
| A sequential service blocks voice and text behind a slow image | Priority queue (text first); per-kind timeouts; a second service instance for images is a later, additive change (the wire carries `req`, so results can come back out of order) |
| Providers change their response shapes | Parsers are pure and tested on committed fixtures; the attended (c) run refreshes the fixtures from real responses (scrubbed) |
| LLM output fails the grammar often | The prompt states the grammar and the allowed palette; up to two in-handler retries on `bad_output`; a refused record falls back to the template, never to a stall |
| Goldens churn when 2.1 lands | One reviewed `replay-record` diff; AC13 proves nothing else moved |
| Pillar 1 wording (AI intents while committed) | Open question 1; AC5 proves no journey effect either way |
| Media missing on another machine in a visual replay | The sim replay needs no bytes; the visual replay degrades to text, core portraits and silence, and says so |
| Cache grows without bound | 2 GB LRU cap on generated blobs; core is immutable |
| Cross-architecture float differences (ailang#1465) | The AI path adds no floats to sim state (`usd` stays out of the sim); per-architecture goldens as in M2 |
| Path dependencies can't share pure code between `sim/` and `ai/` (gap G5) | The design avoids sharing: the sim parses, and the service consumes parsed segments |

## Open questions for Mark

1. **AI intents while a journey is committed.** Talking to the crew in transit
   must work, but M2 refuses every intent kind then.
   **Recommendation:** accept `ai_open`, `record` and `ai_cancel` while
   committed; they cannot touch the journey (AC5). The commit rule becomes
   "every journey intent is refused".
   **Default if unanswered:** that.
2. **Pre-generated core content: bundled or fetched?** Bundling, as the sky
   does under D-18, means git holds the index and `SHA256SUMS`, blobs live in
   `gs://stapledons-voyage-assets/ai/`, and builds bundle them, so the game is
   playable offline. The alternative is to download the core from the public
   bucket on first launch, for a smaller build that needs the network once.
   **Recommendation:** bundle; it is what D-18 chose for the sky and what
   "fully playable without a key" implies.
   **Default:** bundle.
3. **Where the player's key lives.** The `GOOGLE_API_KEY` env var, or a pasted
   key in `user://ai_key` (mode 0600). An OS keychain needs a GDExtension.
   **Recommendation:** env or the 0600 file for R1, with a plain warning in
   Settings; keychain in R2.
   **Default:** that.
4. **Session spend ceiling.**
   **Recommendation:** US$0.50 per session by default, adjustable in Settings,
   with a hard stop and a visible running total.
   **Default:** US$0.50.
5. **Who pays for build-time generation and the (c) live call.**
   **Recommendation:** a Gemini API key in the `stapledons-voyage` GCP project
   (Holosun billing, D-18), stored in Secret Manager, used only in attended
   sessions, with a US$20/month budget alert.
   **Default:** attended sessions use the key Mark provides in that session;
   the loop never spends.
6. **Marker syntax.**
   **Recommendation:** `{grieving}` in curly braces, because Gemini TTS
   already reads square-bracket tags.
   **Default:** curly braces.
7. **TTS granularity.**
   **Recommendation:** per segment, concatenated, for exact swap times and
   per-emotion delivery. Mark judges the prosody at the (c) stop.
   **Default:** per segment until the stop.
8. **The Medic's missing emotions.** She has neutral, loving and grieving.
   **Recommendation:** restrict the style-frame line to those three and
   commission the other five from the art pipeline separately (it can
   reference-condition today; AILANG cannot, gap G2).
   **Default:** restrict.
9. **The Medic's voice.**
   **Recommendation:** audition three Gemini prebuilt voices on the same line:
   Aoede (the 2025 TTS doc's pick for the Medic), Kore and Leda.
   **Default:** Aoede.

## Deliverables

- Sim: protocol 2.1 in `sim/protocol.ail`; `sim/ai.ail`; `sim/markers.ail`;
  `AiState` in `World`; tests `sim/ai_test.ail` and `sim/markers_test.ail`;
  strict entries.
- Service: `ai/ailang.toml`, `ai/{service,wire,key,prompt,provider,cache,spend}.ail`,
  `ai/tools/core_import.ail`, `ai/tools/fake_service.ail`, stub fixtures,
  response fixtures.
- Godot: `bridge/ai_bridge.gd`, `bridge/ai_relay.gd`, `bridge/ai_cache.gd`,
  Settings panel and HUD indicator, `ui/conversation/`,
  `tests/test_ai_relay.gd`.
- Data: `data/ai/{models,prices,emotion_styles}.json`,
  `data/ai/cast/medic.json`, `data/ai/core/{index.ndjson,SHA256SUMS}`.
- Replays: `tests/replays/ai_stub_session.ndjson` and
  `tests/replays/medic_style_frame.ndjson` with per-architecture goldens; all
  2.0 goldens re-recorded.
- Makefile: `ai-stub`, `ai-adapter`, `ai-live-guard`, `replay-compat`,
  `replay-noai`, `ai-core-assets`, `ai-core-bundle`, `ai-core-publish`,
  `ai-core-verify`, `ai-style-frame`; CI picks the first five up through
  `make test`.
- Infra: bucket prefix `ai/` documented in `infra/gcp/README.md` (no new
  resources).
- Upstream (`ailang messages`, inbox `user`, from `stapledons_godot`, gcp
  store): gaps G1–G5 below, filed with this doc.
- Design repo: ai-showcase §8 status and a note that the marker syntax is
  curly braces.
- Report: `design_docs/implemented/r1/ai-service-foundation-report.md`
  (latencies, the real cost of (c), Mark's ruling).

### AILANG: what exists and what must be built (v0.51.0)

| Need | Exists | Built here or requested upstream |
|---|---|---|
| Text generation, per-call model | `std/ai.step(model, messages, tools)`, `callResult`, `stepWithStreamRecorded` | used as is |
| Image generation | `callImage`, `callImageBase64` (no reference image; model bound to the handler) | used for stub and adapter tests; **G2** for reference-conditioned images and a per-call model |
| TTS | none in `std/ai`; `std/audio` encodes PCM (pure, deterministic Ogg Opus) | HTTP adapter here; **G1** for `std/ai` speech |
| Hashing | `std/crypto.sha256Hex`/`sha256Bytes`, pure and strict-VM clean (V2) | used in the sim and the service |
| Stub provider | `--ai-stub` (fixed responses) | our own pure stub; **G3** for fixture-driven stubs |
| Keys and ADC | env `GOOGLE_API_KEY`, silent ADC fallback | wrapper and refusal here; **G4** |
| Effect budgets | `! {AI @limit=N}` | used per handler |
| Shared pure modules across packages | path dependencies, absolute in the lockfile | avoided; **G5** |

Gaps filed 2026-10-02 (`ailang messages`, gcp store, inbox `user`; GitHub issues as noted):
- **G1** (ailang#1495) `std/ai` speech: `callSpeech(text, voice, style, options) -> Result[bytes, AIError]` (PCM), routed through providers, supported by `--ai-stub`.
- **G2** (ailang#1496) reference-conditioned image generation (`images: [ImagePart]` input) and a per-call model for `callImage*`.
- **G3** (ailang#1497) a fixture-driven `--ai-stub` (prompt sha → response, including image and audio bytes) for testing adapters against real response shapes.
- **G4** (ailang#1499) a switch to disable the Google ADC fallback, and a key-file option, so a player-key application cannot bill the developer's credentials and keys stay out of env and argv.
- **G5** (ailang#1498) path dependencies recorded relative to the package in `ailang.lock`, so two packages in one repo can share pure modules in CI and bundled runtimes.

## Verification log

| # | Claim | How checked (2026-10-02) | Result |
|---|---|---|---|
| V1 | `std/ai` surface on the pin | `runtime/bin/ailang docs std/ai` (v0.51.0) | `call*`, `step(model, …)`, `stepWithCache`, `stepWithStream(Recorded)`, `runTools`, `callImage`, `callImageBase64`; no speech call; `docs --all-functions` has no TTS export |
| V2 | `sha256Hex` is pure and strict-VM clean | `run --bytecode --strict-bytecode --entry h --args-json '"abc"'` | `ba7816bf…f20015ad` (the standard vector), same on the interpreter |
| V3 | `--ai-stub` behaviour | probe calling `callResult` and `callImageBase64` with `GOOGLE_API_KEY` unset | text `{"kind":"Wait"}`; image `{"base64":"iVBORw0…","mime_type":"image/png"}` (1×1 PNG) |
| V4 | `std/audio` is pure and deterministic | `docs std/audio`, `docs/docs/reference/std-audio.md` | `wavFromPcm`, `durationMs`, `encode(OggOpus)`; same bytes on amd64, arm64 and WASM |
| V5 | String length and UTF-8 hashing | `length("héllo")` on VM and interpreter; `sha256Hex("héllo")` vs `shasum -a 256` | 5 and 5 (code points); hashes equal (`3c48591d…`) |
| V6 | The reserved `record` and its refusals | `sim/protocol.ail:168-169`, `sim/core.ail:80,172,254` | decoded; refused `unsupported`, or `committed` during a journey |
| V7 | `ai` PRNG stream exists, unused | `sim/rng.ail`, M2 report §M2.4 | stream id 5; no draws outside diag |
| V8 | Accepted Medic art | `ls ~/dev/blender/assets/stapledon/characters/medic_v2` | `portrait_medic_age0_{neutral,loving,grieving}_v2.png`, `portrait_medic_age50_neutral_v2.png`, `avatar_medic_static_v2.png`, `manifest.json`, prompts, `validation.json` |
| V9 | Accepted cast proposals | `ls ~/dev/blender/docs/stapledon/cast_marker_v1`; `unzip -l cast_proposals_v1.zip` | README, marker PNGs, `marker_ship_v1.zip`; the zip holds ten `portrait_<role>_age0_neutral_v1.png` (1254 px), `manifest.json`, `selected_prompts.json`, `validation.json` |
| V10 | No conversation UI exists | `git ls-tree origin/spike/iso-bridge`; repo `ui/` | no dialogue scene; `fe16790` adds only preview PNGs |
| V11 | Gemini TTS uses square-bracket tags | `stapledons-design/reference/ai-capabilities.md` §Emotion Markers | `[sigh] [laugh] [gasp] [whisper] [pause] [excited] [sad] [angry]` |
| V12 | Path dependencies are absolute in the lockfile | `ailang` repo `docs/docs/guides/build-a-motoko-extension.md:104` | "Lockfile bakes in your absolute path; PR/CI clones break" |
