# Live AI panel v2: see at a glance whether your key works

**Status:** Planned. Mark approved the visual concept on 2026-11-09 (attended: "yeah thats great proceed").
**Release:** r3 · **Milestone:** UI follow-up to the AI service foundation (a5)
**Priority:** P2. Live AI works today, but the player can't tell whether it does: Mark pasted a working Gemini key on 2026-11-09 and asked "its not clear if its working?", then called the panel "a big mess of debug text".
**Implements:**
- [ai-service-foundation.md](../r1/ai-service-foundation.md) §(a5) Key and cost UX: same settings, same rules (opt-in needs a key and the tick; one session ceiling over both providers, US$0.05 to 20; text-only; automation never goes live; keys only ever as 0600 files). This doc changes how they are shown and adds a key check.
- Ledger **D-8** (the player's own key; live generation opt-in; text-only always available) and **D-20** (the player-set spend ceiling, default US$0.50), `design_docs/stapledon-mission.md` §Decision ledger
- [ai-showcase](https://github.com/sunholo-data/stapledons-design/blob/main/features/ai-showcase.md) §7, the operating model (the player pays with their own key)
- Standing order "visual UI, not text" (Mark, 2026-10-28): state as lamps, icons, meters and colour; words last
- [bridge-styling-pass.md](../../implemented/r2/bridge-styling-pass.md) ST4: one HUD theme (`StapledonTheme`), `make ui-theme-check` strict

**Visual concept (approved):** [Live AI panel redesign](https://claude.ai/artifact/4oQ6rbUrWg2ZFK3PXm7DT1), the interactive panel and the badge's five states. The mock-up's colours are stand-ins: the build uses `StapledonTheme` tokens (the table in §V1).
**Depends on:** the AI service foundation (AI.1–AI.9, landed). No sim, physics or protocol-2.x change.
**Estimated:** ~1,050 LOC (≈620 code, 430 tests and the capture tool), 4 sub-milestones.

## Game vision alignment

Scored with the `game-vision-designer` skill against `stapledons-design/vision/core-pillars.md`.

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | 0 | 0 | Settings only; nothing touches the journey or the record |
| The Game Doesn't Judge | 0 | 0 | A failed reply is shown as a fact (an amber dot, the ship's own line used), never as an error scolding the player |
| Time Has Emotional Weight | 0 | 0 | No change |
| The Ship Is Home | + | +1 | The crew and the Archive speaking live is the point of the key; a working lamp and green reply dots make it trustworthy, so players actually turn it on |
| Grounded Strangeness | 0 | 0 | No change |
| We Are Not Built For This | 0 | 0 | No change |
| Standing order: visual UI, not text | ++ | +2 | Replaces about ten lines of sentences and a 70-character badge with lamps, icons, a spend bar, reply dots and a ring |
| Operating model: player's key, player's money (D-8, D-20) | + | +1 | Spend against the ceiling becomes a bar you can read at a glance; the key check spends nothing |
| **Net** | | **+4** | **Go. ALIGNED.** No pillar below 0. Low pillar relevance is expected for a settings surface; the standing order carries it |

## Problem

1. **No proof the key works.** The panel says "Google AI (Gemini): key saved" whether the key is valid, revoked or mistyped. A bad key only shows later as silent fallback to template text (`ai_relay` refuses and the ship's lines play), so a player can't tell "AI is off" from "AI is failing". Evidence: 2026-11-09, Mark with a valid key (`200` from `models.list`) could not tell from the game whether it was in use.
2. **The panel is a wall of text** (`ui/settings/ai_settings_panel.gd`, 132 lines): a title sentence, a two-sentence warning, two "Provider: key saved" labels, two tick boxes with parenthetical sentences, a spin box, and a paragraph of four prices plus a "Live now: …" list. Nothing is a picture.
3. **The badge is a sentence** (`ui/ai_indicator.gd` `text()`): `AI live · Google $0.0000 · OpenRouter $0.0000 · $0.0000 of $0.50`, about 70 characters in the top right of every screen.
4. **What a key powers is hidden** in the key field's placeholder text ("enables text, voice, portrait, feed").

## Goals and non-goals

**Goals**
- G1. A badge that says on / off / working / problem / ceiling reached at a glance, with spend as a ring.
- G2. A panel whose first view is lamps, icons and one bar. Sentences only in tooltips.
- G3. A **Test** button per key: a free, real check with the provider, through AILANG, with a lamp result (working / key rejected / offline).
- G4. A row of recent-reply dots, so a player sees replies arriving (or failing) while they play.
- G5. Every existing AI.9 rule and test still holds (`make ai-settings`, `make ai-live-guard`, `make ai-mutants`).

**Non-goals**
- No change to routing, prices, the ceiling's rules, the cache, recording or replay.
- No key encryption (still a 0600 file, as D-8 and AI.9 decided).
- No in-game spend history beyond this session (the usage log keeps it).
- No new provider.

## Design

### V1. The badge (`ui/ai_indicator.gd`)

A drawn `Control` replaces the text `Button`. It is a pill with a ring (spend over ceiling, 0 to 1), a lamp dot, the word **AI** and a one-word state. Clicking it opens the panel as today. Hovering shows the exact amounts as today's text, moved into the tooltip.

State is a pure function `AiIndicator.state_of(settings, bridge_view) -> String`, so it is testable headless:

| State | When | Lamp and ring (theme token) | Word |
|---|---|---|---|
| `off` | `not settings.live_on()` | `DIM`, ring empty | off |
| `ceiling` | `budget_hit` | `CORAL`, ring full | ceiling |
| `problem` | the last 3 outcomes this session all failed, or the last key check for a present key was `rejected` | `CORAL` outline lamp, ring as spent | key problem / offline |
| `working` | `bridge.pending() > 0` | `TEAL_LIGHT`, pulsing at 1 Hz | thinking |
| `live` | otherwise | `MINT`, ring as spent | live |

Precedence is top to bottom. Colour is never the only carrier: each state has its word, and `problem` and `ceiling` differ in lamp shape (outline against filled). Contrast follows `ui-theme-check` (WCAG 4.5:1 for the word).

### V2. The panel (`ui/settings/ai_settings_panel.gd`)

The layout follows the mock-up, top to bottom:

1. **Header:** the AI glyph, the title "Live AI" (`OCHRE_LIGHT`), one line of state ("On: the crew, the Archive and home write live with your key" / "Off: the ship uses its own lines and pictures"), and a **switch** bound to `opt_in`, disabled without a key.
2. **One card per provider** (`AiSettings.PROVIDERS`):
   - a lamp and word: `none` (no key), `saved` (key present, not checked this run), `checking`, `ok` (Working), `rejected` (Key rejected), `offline`;
   - four **capability tiles** (crew and Archive lines, voices, portraits, pictures from home), drawn icons, not text. A tile is bright when that kind is live now (`live_kinds()` and this provider routes it), dim when this key could serve it but it is off (text-only, or the switch), and faint when this key can never serve it (`kinds_for(p)`);
   - the key as `•••• •••• ` plus its **last 4 characters** (OQ1), or "no key";
   - buttons **Test** (with a key), **Add key** (without), **Replace** and **Remove**. Add and Replace reveal the secret `LineEdit` inline; Remove deletes the file (`save_key(p, "")`).
3. **Spend:** "This session $0.034 of $0.50 ceiling", a bar filled to spent ÷ ceiling, and the ceiling as an `HSlider` on a log scale over US$0.05 to 20 that snaps to `AiSettings.set_ceiling()`'s 0.01 steps. The prices become four small chips from `estimates()`. Without a running session (the title screen) the bar reads "no voyage yet" and is empty.
4. **Recent replies:** up to 8 dots, newest last, from this session's `usage.ndjson` lines (ok = `MINT` check glyph, failed = `CORAL` "!" glyph), and "last reply N s ago". Hidden without a session.
5. **Footer:** a **Voices & pictures** toggle (the inverse of `text_only`; locked while `--text-only` is set), a lock icon whose tooltip is `AiSettings.WARNING`, and Close.

`AiSettings` gains only pure helpers: `masked_key(p)`, `ceiling_to_slider(v)` / `slider_to_ceiling(t)` (log map, round-trip exact on the 0.01 grid), and `tile_states(p) -> Array` (bright / dim / faint per kind). The panel stays a view over `AiSettings`. Every change still goes through `AiSession.settings_changed()` in a game, or `save_settings()` without one.

### V3. The key check (AILANG `ai/check.ail`, `AiBridge.check_plan()`)

**Test** runs a one-shot AILANG process, separate from the session's service, so it works from the title screen too:

```
ailang run --quiet --bytecode --package-dir ai --caps Net,FS,Env --ai-no-adc \
  --net-allow-domains generativelanguage.googleapis.com,openrouter.ai \
  --entry check --args-json '{"provider":"gemini","key_file":"…","base":""}' ai/check.ail
```

- **Gemini:** `GET {base}/v1beta/models?pageSize=1` with header `x-goog-api-key`. 200 → `ok`; 400, 401 or 403 → `rejected`; anything else, or no response → `offline`.
- **OpenRouter:** `GET {base}/api/v1/key` with `Authorization: Bearer`. 200 → `ok`; 401 or 403 → `rejected`; else `offline`.
- Both calls are free and write **no** usage line (the ceiling is untouched).
- It prints exactly one line, `{"check":"gemini","status":"ok"}`, and exits 0. It never prints the key or a response body.
- `base` defaults to the real host. Tests point it at the loopback fixture (`tests/fixtures/ai_loopback.py`, the existing harness), which gains the two GET routes.
- The key reaches the process as a file, the same as live (`LIVE_WRAP` style: env built from the file inside the child, `GOOGLE_APPLICATION_CREDENTIALS=/nonexistent`, `--ai-no-adc`).
- **Guards:** automation runs never offer Test (`AiSettings.automation`), and `check_plan()` returns `{}` without a key file. The result lives in memory for this run only (OQ2) and feeds the card's lamp and the badge's `problem` state.

`AiBridge` runs it with `OS.execute_with_pipe` (non-blocking), with a 10 s timeout that kills it and reports `offline`.

### V4. Capture and review

`tools/ai_panel_capture.gd` (Godot `--script`, the same pattern as the other captures) renders the panel and the badge in fixed states from fixture settings (no key; Gemini ok + OpenRouter none; rejected; offline; text-only; ceiling reached) to `renders/ai_panel/*.png`. It is a review aid, not a merge gate (CLAUDE.md: a merge never waits on the GPU). Mark's OK is on a dev build.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | `state_of` returns each of the five states with the precedence in §V1 (10 fixture cases, including ceiling over problem and problem over working) | `make ai-settings` |
| AC2 | The badge draws no text sentence: its visible label is at most 2 words beside "AI", and the exact amounts are in `tooltip_text` | `make ai-settings` |
| AC3 | Panel cards: no key → lamp `none`, **Add key** shown, **Test** hidden; a saved fixture key → `saved` and masked to the last 4; **Remove** deletes the 0600 file | `make ai-settings` |
| AC4 | Capability tiles: Gemini key only → 4 bright; text-only → text bright, 3 dim; OpenRouter only → text bright, 3 faint; switch off → all dim | `make ai-settings` |
| AC5 | Ceiling slider: `slider_to_ceiling(ceiling_to_slider(v)) == v` on every 0.01 step in 0.05..20, ends exact, monotonic | `make ai-settings` |
| AC6 | Recent-reply dots come from this session's usage lines only (an earlier session's lines are not shown), newest last, at most 8 | `make ai-settings` |
| AC7 | Key check against the loopback: 200 → ok, 403 → rejected, a closed port → offline (both providers); no usage line written; the fake key never appears in stdout, stderr or the log | `make ai-loopback` |
| AC8 | `ai/check.ail` type-checks, and its classifier (`statusOf(code)`) is tested in AILANG | `make ai-pkg-test` |
| AC9 | Automation never offers or runs a check: `check_plan()` is `{}` with `automation`, and no key file → `{}` | `make ai-live-guard` |
| AC10 | Mutants: dropping the no-usage rule, printing the body, or reversing state precedence each fail a named test | `make ai-mutants` |
| AC11 | No hard-coded colour or style outside `StapledonTheme`; contrast passes | `make ui-theme-check STRICT=1` |
| AC12 | No sim, protocol or physics change | `git diff --stat origin/main -- sim/ physics/ \| wc -l` prints 0 |
| AC13 | Review renders exist for the six fixture states | `make ai-panel-capture && ls renders/ai_panel/*.png \| wc -l` ≥ 6 |
| AC14 | Mark's OK on a dev build (visual) | `make publish-dev`, then Mark installs with `tools/install_review_build.sh --dev` |

## Sub-milestones and estimates

| # | Work | LOC (code + tests) | Depends on |
|---|---|---|---|
| P1 | `ai/check.ail` + `statusOf` test, `AiBridge.check_plan()` / run / timeout, loopback GET routes (AC7–AC9) | 90 + 140 | none |
| P2 | Badge: `state_of`, drawn pill and ring, tooltip (AC1, AC2) | 130 + 80 | P1 (`problem` from checks) |
| P3 | Panel rewrite and `AiSettings` helpers (AC3–AC6) | 330 + 150 | P1 |
| P4 | Theme pass, capture tool, mutants, dev build (AC10–AC14) | 70 + 60 | P2, P3 |

Order: P1 → (P2 ∥ P3) → P4. One PR.

## Risks and mitigations

- **A check that leaks the key.** The key only ever travels as a file into the child's env; the check prints only a status word; AC7 greps every stream for the fake key; AC10 has a mutant that prints the body.
- **A "free" endpoint that starts billing.** Both are list/metadata GETs that providers don't bill. The check writes no usage line, so it could never count against the ceiling anyway. If a provider ever changed that, the lamp would still be right and the cost would show on the provider's bill, not in-game. Re-check at each provider change.
- **`problem` false alarms** from one network blip. It needs 3 failed outcomes in a row or an explicit `rejected` check, and the next success clears it.
- **The theme check blocks drawn icons.** Icons draw with theme tokens through `StapledonTheme` constants, the same way `bridge_screens.gd` does; no new hex in `ui/`.
- **The log slider loses exactness.** The map snaps to the 0.01 grid, and AC5 proves the round trip for every step.

## Open questions for the user

- **OQ1. Show the last 4 characters of a saved key?** It helps tell keys apart and is the common practice (Google and OpenRouter show a prefix or suffix). *Recommend yes.*
- **OQ2. Remember the last check result across runs?** *Recommend no:* check once per run when you press Test. A remembered "Working" from last week could be stale after a key is revoked.
- **OQ3. Auto-check on opening the panel?** *Recommend no:* the check is free but still a network call with your key, so it runs only when you press Test.

## Deliverables

- `ai/check.ail` (entry `check`) and its test; `bridge/ai_bridge.gd` `check_plan()` and the async run
- `ui/ai_indicator.gd` (drawn badge, `state_of`), `ui/settings/ai_settings_panel.gd` (rewritten), `ui/settings/ai_settings.gd` (pure helpers)
- `tests/test_ai_settings.gd` cases, loopback GET routes in `tests/fixtures/ai_loopback.py`, mutant rows in `mk/ai.mk`
- `tools/ai_panel_capture.gd` and `make ai-panel-capture`
- CHANGELOG entry; the design doc moved to `implemented/r3/` at landing
