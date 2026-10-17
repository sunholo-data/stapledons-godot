# Sprint R2-INTERLUDE: the crossing review

**Design doc:** [interlude-card.md](interlude-card.md) (proposed 2026-10-16; all seven open questions ruled by Mark the same day, see its Rulings)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-INTERLUDE.json`
**Status:** **Done** 2026-10-17 (PR #264; evaluation 89/100 PASS, `.ailang/state/evaluations/R2-INTERLUDE-eval.md`). **Approved** by Mark (attended 2026-10-16: "yep execute the plan"). The design-doc notes below were applied to the design doc before approval.
**Scope:** I1 (chunked cruise, holds stop the crossing), I2 (the cruise digest in the pure sim), I3 (the Godot review), I4 (the Archive narrates). I3b (swap the moment ranking for crew_core E4's skip report) is blocked on E4 upstream and is listed but not scheduled.
**Base:** branch `feat/crew-core-0.5.0` (crew_core 0.5.0 pinned, AILANG v0.54.11). Sprint branch `feat/r2-interlude` off it once that branch merges; each milestone is one PR to main.
**AILANG:** v0.54.11 (pinned; `runtime/VERSION`). AILANG prompt version loaded: v0.16.7.

## What the survey found

- **The interlude is one step.** `ui/card_interlude.gd` `advance()` hands the whole remaining cruise to the sim in its first frame and is `done()` after `CARD_S = 6.0` s. `demos/solar_departure.gd` `_step_interlude()` (line ~193) sends it; `crew_held()` (line 207) is checked only before each host frame, so a hold raised inside that one step is seen at the braking boundary.
- **Holds don't stop the crew days.** `sim/crew_auto.ail` `autoStep`: after `r.escalated`, `plainDays(... target - c1.turn)` runs the rest of the tick. Every sim step has the fixed 2,000 ms `step_timeout` (`bridge/sim_bridge.gd` lines 245, 305, 333).
- **Nothing accumulates.** `linesMax() = 6` (`sim/crew.ail:44`) and the crew view's `heardMax` is 6. `autoStep` keeps only the auto-captain's `captain_reply` acts (`replyLines`) and drops the rest of `advanceAuto`'s `log: [Act]`.
- **The game crew runs untraced.** `initCrew` calls `initCrewWith(captaincy, false)` (`sim/crew.ail:80-91`), so `CrewStepped.traces` holds empty strings in the game. Digest counts therefore can't be read from traces. They come from three places: crew_core's `Session.archive` counters (`tasks`, `accepted`, `completed: [Tally]`), live `state.tasks` and evidence at the chunk's ends, and the `Act` log. (The design's "Source" column names traces; see Design-doc notes.)
- **Godot computes.** `CardInterlude.lines()` multiplies `Δtau × 365.25` and subtracts Earth years; `TIERS` lives in GDScript; `IsmHud.interlude_text` subtracts grain counts; `InterludeCard.show_interlude` lerps clocks. No display-audit playthrough reaches an interlude: `tests/m4_playthrough_ship.gd` walks free navigation, and `JourneyPacing.interlude_due` needs `guided_approach`.
- **Protocol.** `crewMinor() = 9` (`sim/protocol.ail:115`); `helloFor` and `sessionMinor` chain the minors; the bridge has `CREW_MINOR := 9`. This sprint adds **2.10**.
- **File sizes.** `sim/core.ail` is 983 lines and `sim/protocol.ail` 844. The digest goes in a new `sim/cruise_digest.ail` and its codec in `sim/protocol_interlude.ail`. `core.ail` gains only the `World` field, a reset at commit and one fold call (about 15 lines). New modules are added to `sim/ailang.toml`'s exports list.
- **Ruling 4 is mostly in place already.** `demos/ship_geometry_demo.gd:621` queues `crew_orders {orders, critical_only}` for every game with crew aboard, the guided voyage included. The sim default (`auto: None`) stays `off`. I1 adds a test that pins the guided-voyage default; it changes no code unless the test finds a path that skips the queue.
- **Portraits.** `data/crew/portraits/`: five roles. Only the medic has all eight emotions; the captain has avatar sprites, not portraits. `ui/crew_page.gd` holds `LABEL_EMOTION` and the strained rule. I2 moves both into the sim.

## Plan shape

```
I1 (chunks, holds stop) ─▶ I2 (digest, 2.10) ─▶ I3 (review pages, audit) ─▶ I4 (Archive) ─▶ E (evaluate, land)
                                         E4 upstream ─▶ I3b (blocked; not scheduled)
```

I1 can ship alone: it fixes P3 (holds) and P5 (step timeout) without any new view. Every milestone starts with red tests and keeps their log in the sprint JSON notes.

## Milestones

### I1: the chunked cruise; a hold stops the crossing (~380 LOC, 1.5 days) ✅ 2026-10-16

> **Done** (branch `feat/interlude-card`). What changed from the plan:
> - `nextStop` takes the crew and the ship years to braking (`nextStop(crew, brake)`); the world-level `cruiseStop(w)` lives in `sim/protocol_interlude.ail`, so `cruise_digest.ail` never imports `core.ail` (I2's fold call from `core.ail` would otherwise be an import cycle).
> - `crewSkipChunked` is an IO entry in `sim/tools/crew_perf.ail` (one line per chunk; `make crew-perf` times each line's arrival), with the pure `chunkStep` in `sim/crew_script.ail`: the sim has no clock (gate 6) and the package's effect ceiling is IO/FS. Its critical_only case is the game's default (consent captaincy) with holds left open, as the host leaves them.
> - A refusal under orders is handed over *before* its day's advance (crew_core), so that one day still runs after the hold; the crossing still ends on the decision day (`turn == 61`).
> - The host re-reads the stop from the world before each chunk (`_step_interlude` observes first): the held zero tick that carries `crew_resume` changes the next stop from the cap back to a check-in.
> - `skip_stage()` during an interlude runs the chunks to the boundary, stopping at a hold.
> - The game's sessions (ship, map, loading-jump prefetch) all ask for 2.10, so the prefetch is still adopted.
- **Red first.** Write these before any code:
  - `sim/crew_hold_test.ail` gains cases. On a 10-year committed leg under critical_only with a scripted escalation on a day-61 decision day, the tick ends with `turn == 61` (zero plain days after the hold). The `next_stop` arithmetic is exact over 200 seeded `dayRem` values in [0, 1/365.25). The cap returns 365 days with auto-run off.
  - `tests/test_cruise_interlude.gd` is rewritten red: `advance()` never returns more than `next_stop_years`.
  - `tests/test_crew_hold.gd` gains a guided-voyage case where a hold in month 2 stops the crossing in month 2.
- **Sim** (`sim/cruise_digest.ail`, the stop half; pure):
  - `nextStop(w) -> { years: float, kind: string }`. It returns the earliest of: the braking boundary (`braking`); the next auto-run decision day, `nextDecision(turn, cadenceLongSkip())`, when auto-run is on and no hold is open (`check_in`); and `chunkDays() = 365` (`chunk`).
  - **Exactness rule:** `years` is the smallest float such that `daysIn(dayRem, years).days` equals the day distance. It is computed from `dayRem` in the sim, with a property test, so that floating rounding can't land one day short or one day over.
  - `crew_auto.autoStep` is unchanged except that it returns the full `Act` log (`AutoStepped.log`) for I2.
- **Protocol 2.10.**
  - `interludeMinor() = 10` joins `helloFor` and `sessionMinor`.
  - At ≥ 10, a committed journey's state carries `cruise {next_stop_years, stop_kind}`. Below 10 every stream is byte-identical (`make parity-v2 replay`).
  - Bridge: `INTERLUDE_MINOR := 10`, the parse, and `ship_geometry_demo.gd` asks for 10.
- **Godot.**
  - `CardInterlude.advance()` returns `min(cruise.next_stop_years, max_years)` per frame and keeps the 6 s card for now; I3 replaces the card.
  - A "Crossing…" progress line (D-76) shows between chunks, bound to `cruise.stop_kind`.
  - `solar_departure.gd` is unchanged in shape. `crew_held()` already returns before `_step_interlude`, so a hold that ends a chunk stops the next one.
  - Resume continues the crossing. The braking-boundary check (1e-12 × plan) stays.
- **Guided default (ruling 4).** A test asserts that a new guided voyage with crew sends `critical_only` before its first commit.
- **Performance.**
  - `make crew-perf` gains the entry `crewSkipChunked` (`sim/crew_script.ail`): a busy decade stepped as the host steps it. It asserts every chunk is under 1.0 s and the critical_only total is under 2 s (AC6).
  - A chunk over 1.0 s fails, and the log names the chunk.
- **Gate:** `make sim strict parity parity-v2 replay crew-hold-test crew-perf tour-pacing-test`.

### I2: the cruise digest (~550 LOC, 2 days) ✅ 2026-10-16

> **Done** (branch `feat/interlude-card`, ~650 LOC with tests). What changed from the plan:
> - `emotionOf` and `strainedAt` live in `sim/protocol_crew.ail` (beside `templateLine`), not `cruise_digest.ail`: the crew view needs them and `cruise_digest` imports `protocol_crew`. At 2.10 the crew view's members and lines carry `emotion`; `CrewPage.emotion_of` reads it and `LABEL_EMOTION`/`STRAINED_LABELS`/`WARM_LABELS` are gone (Godot keeps `FALLBACK`). The console fixture gained the sim's emotions.
> - The digest is begun from the world *before* the commit tick (`core.digestAfter`), so the commit tick's own crew days are folded, and it is folded on the arrival tick too. `cruise` carries `digest` on every committed tick; the arrival tick sends `{digest}` alone (frozen afterwards, nothing more is sent). `SimBridge.parse_cruise` accepts both shapes.
> - `core.ail` grew 28 lines, not 15: `digestSnap` (the clocks, news and dust as plain values, since `cruise_digest` cannot import `core`), `digestAfter`, and the accepted console lines. `crewLines` now also returns the lines it noted (with their AI request ids) for the moments.
> - Counts: `refusals`, `concerns` and `reliefs_asked` come from reply labels (auto-run `reply` acts and the captain's answered lines); `concerns_auto_answered` from `captain_reply` acts; reliefs granted/denied from `relief_decision` acts and the captain's accepted `resolve_relief` lines; `work_done` from crew_core's completed tallies plus live completed work, rest excluded.
> - The scripted crossing (`crew_script.scriptedCrossing`, seed 3) has no relief: crew_core 0.5.0's auto-captain checks in with working crew only on even turns (`auto.ail checkIn`), and on the game's monthly schedule every decision turn is odd, so **no relief is ever asked on a long skip**. Flagged for crew_core (E4). Relief counting is covered by the hand-computed unit cases. The scripted crossing's counts are pinned from the run; every count's source is checked by hand in the unit cases.
> - The scripted crossing brings the crew aboard with `initCrewWith`, not `core.withCrew`: the generated names table (`sim/data/crew_names` `nameRegions`) is evaluator-only under `--strict-bytecode` (register allocator, ailang#1736), and the crossing runs in `make strict`.
> - `tests/crew/crossing_hold.ndjson` is the encoded digest after each chunk (15 lines), not crew_core lines: auto-run's own host calls are not returned by `advanceAuto`, so a standalone crew_core replay is not possible for this case. AC3/AC4 hold through VM == interpreter and the repeat-run comparison.
> - `CardInterlude.TIERS` and `lines()` stay until I3 deletes them; the sim's `time.tier_line` and `years_at_home` are ready for the review.
- **Red first.**
  - `sim/cruise_digest_test.ail` (new) runs a scripted one-year crossing (crew_script: an offer, a refusal, a relief asked and granted, a concern auto-answered, one hold and its resume). Its expected digest is written by hand before the code (AC1).
  - `tests/crew/crossing_hold.ndjson` is added as an empty recording.
- **State.** `World.cruiseDigest: Option[Digest]`.
  - It is reset at commit (begin snapshot: clock, members' indicators, archive counters, dust totals).
  - It is folded each tick while the journey is committed, and kept through a hold (not reset). It is frozen at arrival until the next commit.
  - It is world state, so it is in the replay and has no hidden state (gate 6).
- **Sections** (design D1):
  - `time`: `ship_days`, `earth_years`, `earth_year_total`, `news_age_years`, and `tier` 0–6 with thresholds 1/10/30/80/130/1000 (ruling 7). The tier table moves from GDScript to the sim.
  - `home`: `tier`, `news_epoch`, the last arrival's news `template_id`.
  - `medium`: media crossed, `grains_swept` delta, `largest_um`, `largest_j`. This replaces `IsmHud.interlude_text`'s subtraction.
  - `crew.counts`: computed from archive-counter and state deltas plus the `Act` log (not traces).
  - `crew.movement`: begin and end indicators with deltas, ranked by |Δ| with a deterministic tie-break on member id.
  - `crew.moments` (≤ `momentsMax() = 7`): every answered line, act and hold of the crossing, ranked by the pure salience rule hold > refusal > relief > concern > accept, then by day, then by actor. A bounded fold keeps the top 7 so state stays O(1) per tick.
  - `waiting`: from the crew view.
- **Emotion in the sim.** `emotionOf(label, stress)` ports `crew_page.gd`'s `LABEL_EMOTION` and the strained rule, with a table test. Godot keeps only the portrait fallback list.
- **Text.** A moment carries the `templateLine(label)` key (no digits, D-21) and, when an `ai_req` was accepted, the recorded `crew_reply` words. Both are recorded sim input, and nothing is live.
- **Codec.** `sim/protocol_interlude.ail` emits `cruise.digest` at ≥ 10 with a round-trip test.
- **Parity and determinism.**
  - `make crew-parity` gains case `crossing_hold`: VM == interpreter, and the same seed run twice gives a byte-identical digest (AC3, AC4).
  - `make strict` gains entry `digestScripted` (AC2).
  - `make parity` stays green.
- **Gate:** `make sim strict crew-parity parity parity-v2 replay`.

### I3: the crossing review in Godot (~650 LOC, 2 days) ✅ 2026-10-16

> **Done** (branch `feat/interlude-card`). What changed from the plan:
> - **One source for hold words (lead's decision).** `holdLine` moved from `cruise_digest.ail` to `protocol_crew.ail`; at 2.10 each `crew.holds[]` carries `line`. `CrewPage.HOLD_WORDS` is gone: the Crew page, the Voyage console summary and the Hold page all read the sim's words (`CrewPage.hold_text`). Below 2.10 a hold shows the name only. Replay goldens below 2.10 unchanged (`make replay` 11 cases identical, `parity-v2` identical).
> - **`CardInterlude` keeps the seam** with `awaits_reader`: the live demo (`SolarDeparture.reviewed = true`) waits at the braking boundary until the player brakes; a host with no view (headless drivers, the existing tests) ends at the boundary as before. `CARD_S`, `TIERS`, `tier_text`, `lines()`, `shown()`, `InterludeCard` and `IsmHud.interlude_text`/`skipped_media` are deleted. Skip stage [K] no longer dismisses a review (it crosses to the boundary and stops). The HUD chip lost its "Continue [Enter]" button; Enter and the arrows are the review's while it is shown.
> - **Fixtures are recorded from the real sim** by `tools/crossing_review_fixture.gd` (`make crossing-review-fixtures`): Alpha Centauri (an orders crew under critical_only, seed 42: three holds, then the crossing), TRAPPIST-1 chained to Aldebaran (Earth years add up: tiers 3 then 4), and a crossing with no crew.
> - **Bindings.** `GalaxyMap.field_value` indexes sim arrays by a whole-number segment (`cruise.digest.crew.moments.2.day`). New `DisplayBinding` formats, formatting only: `words`, `days` (singular at one), `days_into` (0 is "the day the crossing began"), `tier_line` (the sim's line, its `%s` the sim's whole years) and `speed_c` (the plan's exact 1 − β). The leg name is the HUD view's `review.leg` (TRAPPIST-1 has a digit, so it is a binding).
> - **Home image (ruling 2).** Until `data/interlude/home/tier<n>.png` lands, the live cruise sky (the demo's sky texture, dimmed, captioned) stands in beside the tier line; `crossing-review-capture` prints `PLACEHOLDER` for every home frame. At 0.999999c the sky ahead is near white, so the stand-in is a pale square on the Aldebaran leg.
> - **Who changed** shows the sim's top three movers (one line of indicators each). The medium page is text rows only (no media-strip picture).
> - **Display audit (AC8).** `tests/display_audit.gd` has an `interlude` route: every frame audited against the unchanged `known_findings.json` (a new finding fails), at least 50 samples, cruising sampled, and every review page plus the Hold page sampled; the known entries belong to other screens, so they are not required here (not stale). The negative control `review_unbound` (an unbound review label) is in `display-audit-controls`. The playthrough driver gained `{"start": "guided", "leg": n}` (the Voyage console's Begin; the evidence restarts with the guided session), `{"until": "review"}` (holds answered with the review's confirmed Resume) and `{"review": "all" | "next" | "last"}`; script keys `crew`, `commits_min`, `poles`. `tests/review_drive.gd` drives the live demo to the review for the no-twitch test, the playthrough and the capture.
> - **AC7** is NT4 in `tests/test_no_twitch.gd` (the Hold page and every page through 600 s of fake time with the sim ticking; ship time waits; the last page's Brake ends it) and `test_cruise_interlude.gd` (600 s at the boundary leave a read review open).
> - **Export.** `data/interlude/*` ships (`export_presets.cfg`; `tests/export_audit.gd` row with the witness `data/interlude/home/SOURCES`), so the tier images will ship when they land. Full local `make -k test` (attended clone, 2026-10-16): exit 0.
- **Red first.**
  - `tests/test_crossing_review.gd` (new) runs on a recorded 2.10 state stream (`tests/fixtures/crossing_review/*.ndjson`). It covers which pages appear, page order, empty pages omitted, the Hold page first, portrait per moment, mutation of `emotion` changing the texture (AC10), no digits or scored words in crew text (AC9), and every Label a DisplayBinding or ComposedBinding.
  - `tests/test_no_twitch.gd` gains an interlude state: 600 s of fake time on each page leaves it shown (AC7).
- **UI.**
  - `ui/crossing_review.gd` replaces `ui/interlude_card.gd`; `CardInterlude` keeps the seam.
  - The pages follow design D2: Crossing, Home, Aboard, Moments 3–7, Who changed, The medium, Waiting.
  - Next, Back, the arrow keys, Enter and the page dots turn pages. The only dismissal is "Brake for <target>" on the last page. There is no timer: `CARD_S` and the clock lerp are removed, and the clocks show the sim's before and after values.
  - `CardInterlude.lines()` is deleted. Every number is bound to a sim field.
- **Home image (ruling 2).** Seven `data/interlude/home/tier<n>.png`, keyed by `time.tier`, under D-7 generate-and-cache. **This is an attended art task.** Until it lands, a placeholder per tier (the cruise sky with the tier line) is used, and the capture flags it.
- **Hold page.** It shows who, the `CrewPage` hold words and the portrait, with the same confirmed actions: Crew console, or Resume (confirmed press → `crew_resume`). "So far: N days" is bound to `time.ship_days`.
- **Display audit (AC8).**
  - `tests/m4_playthrough_ship.gd` gains steps `{"start": "guided"}`, `{"until": "interlude"}` and `{"review": "next"|"last"}`.
  - The new script `tests/playthrough_interlude.json` crosses one interlude with crew aboard and turns every page.
  - The new target **`make display-audit-interlude`** runs that playthrough plus `display-audit` with `DISPLAY_KNOWN` unchanged. It is wired into `ship-demo-ci`.
- **Renders (AC11).** The new target **`make crossing-review-capture`** runs `tools/crossing_review_capture.gd` → `renders/crossing_review/*.png`. It covers each page at 1280×720 and 2560×1440, a Hold page, a no-crew crossing, and the TRAPPIST-1 and Aldebaran legs. **Open every frame.** It is a GPU window, so it stays attended.
- **Tests target.** The new target **`make crossing-review-test`** (in `make test`) runs `tests/test_crossing_review.gd`. `crew-console-test` stays as it is.
- **Gate:** `make crossing-review-test no-twitch-test tour-pacing-test crew-hold-test display-audit-interlude display-audit-controls`, plus `make crossing-review-capture` opened by eye.

#### I3 polish (after Mark's render review, 2026-10-16) ✅
- **A1 Home art lands (ruling 2).** The seven approved pictures (1536×1024 RGB, bytes unchanged) are `data/interlude/home/tier<n>.png`, with `generation_notes.md` and a sha256 `SOURCES` (also on the website's concept-art page, PR #259). The Home page is redesigned: the tier's picture is a 3:2 cover over the whole review panel (behind the title, the page and the buttons; `CrossingReview.HomeBackdrop`), and the words sit in a column over its calm left 40 % with a dark gradient scrim (plus soft bands under the title row and the buttons). The panel is 3:2 on every page (`CrossingReview.WIDTH`/`ASPECT`, `_place_interlude`), so the cover is never cropped through the figures. The stand-in sky, its caption and the `PLACEHOLDER` flag are gone; a missing tier file falls back to the words alone (tested). `crossing-review-capture` fails a Home frame without its picture, off 3:2, or with words past the panel's left half.
- **A2 one day count.** Cause: `time.ship_days` floored the proper time from the commit, while `crew.counts.days` counted the crew's turns, which carry the crew's fraction of a day (and the chunks stop exactly on crew days). One definition now (`cruise_digest.shipDays`): with a crew aboard, the crew's day clock (turns since the commit); without one, whole days of proper time. Both fields are that function. Tests: `cruise_digest_test` (the scripted crossing: 391 = turns, was 390), `protocol_interlude_test` (both on the wire), `test_crossing_review` (every recorded frame). Re-recorded 2.10 data only: `tests/crew/crossing_hold.ndjson` (`ship_days` +1 per line, plus I4's `narration`) and `tests/fixtures/crossing_review/*.ndjson`; replay goldens below 2.10 untouched.
- **A3 the Braking notice waits for the player.** The sim's phase reads `braking` at the boundary while the review waits; the HUD notes the phase change only once the interlude is over (the review's Brake), so the "Braking" notice shows after the player brakes. NT4 in `test_no_twitch.gd` checks both.

### I4: the Archive narrates (~220 LOC, 1 day) ✅ 2026-10-16

> **Done** (branch `feat/interlude-card`). What changed from the plan:
> - **Sim.** `cruise_digest.narrationFor(tier, band)` / `narrationOf` / `narrationKey`: the key is the tier in words and the counts band (`launch|years|decades|generation|lifetimes|centuries|ages` . `empty|quiet|restless|strained|held`; 35 keys, no digits). Two authored lines: `crossing` by tier (page 1), `aboard` by band (page 3); in-world, no digits, ≤ 280, checked for every key in `cruise_digest_test`. At 2.10 the digest carries `narration {key, crossing, aboard}` (codec test). `sim/cruise_digest.ail` joins `in-world-voice-check`'s scanned files.
> - **Who opens.** The host (`ui/archive_narration.gd`, like `ArchiveAsk`): one `ai_open{text, purpose archive, entity archive}` per crossing, once the crossing is over, only when the relay can reach a text provider (live with a key, or the tests' stub; never off or replay: D-8). Context (8 fields): the question, the narration key, the crossing, home (the tier line), crew counts, moments, media, canon. `archive_narration.gd` is in `SANDBOX_SEEN` (the model is told no lore mechanics). `ArchiveAsk` ignores the telling's request.
> - **"Recorded `ai_result`"** is the existing path: the relay's `record` intent → the sim's validation → `ai_accepted` (or `ai_fallback`), in the session log, so a replay needs no service. The service screens the reply (`ai/reply.ail screen`); `reply_test` covers a telling (digits, frame breaks, palette, length) and `prompt_test` its prompt.
> - **Pages.** Page 1 shows "The Archive: …" with the accepted telling, else the authored crossing line; page 3 always shows the authored aboard line (one telling per crossing, so it replaces page 1's line only; design D3's "authored framing always" kept on page 3).
> - **Voice.** The accepted telling is voiced once (`ai_open{voice}` naming its line; the relay's cache is keyed by the voice key) and played once per crossing from the cache. With no key the game starts no AI service (AiSettings: relay "off"), so the authored lines stand silent; the stub voice is what the stub service speaks (tests, `playthrough-ai-modes`).
> - **Gate evidence.** `make playthrough-ai-modes` also crosses the guided Alpha Centauri leg with the playthrough's stub relay: stub mode is told and voiced (`narration: stub state=told voiced=1`), digits mode is refused by the sim (`ai_numeral`) and the authored line stands. `crossing-review-test` covers the open rule, once per crossing, the event flow, the fallback, a later live switch-on and the pages.
- **Red first.** `ai/` tests cover an authored narration key per tier × counts band (no digits, D-67 in-world, ≤ 280), and an `ai_open {purpose: archive, context: digest}` that is opened only with live AI ticked and a key present (D-8). They also check that the reply passes `ai/reply.ail screen`, and that the voice is requested once per crossing with the cache keyed by the voice key.
- **Sim.** The authored framing lines are chosen in the pure sim (`cruise_digest.narrationKey`). The live telling is a recorded `ai_result`, so replays stay byte-identical.
- **Godot.** Pages 1 and 3 show the authored line, or the accepted telling once it arrives. `ai/voice.ail` (Gemini TTS) speaks with a key; without a key the stub voice is used. No live call in tests or CI (`ai-live-guard`).
- **Gate:** `make ai-test in-world-voice-check crossing-review-test` and `make playthrough-ai-modes` (stub/digits).

### E: evaluate and land (0.5 day) ✅ 2026-10-17

> **Done.** Independent evaluation round 1: **89/100 PASS** (`.ailang/state/evaluations/R2-INTERLUDE-eval.md`). Its six defects were fixed before merge, test-first; see [interlude-card-report.md](interlude-card-report.md) "Evaluation fixes". Landed: this plan and the design in `design_docs/implemented/r2/`, the report, `changelogs/unreleased/2026-10-17-crossing-review.md`, and design-repo PR sunholo-data/stapledons-design#26 (G2 and E4's game half).
- **Full run.** `make test` locally (attended), then CI (AC12).
- **Evaluation.** The `sprint-evaluator` runs on a **different model** from the executor and scores 100, with 70 to pass. Output goes to `.ailang/state/evaluations/`.
- **Landing.**
  - Move the design doc and this plan to `design_docs/implemented/r2/`.
  - Write `interlude-card-report.md`.
  - Add a changelog fragment `changelogs/unreleased/2026-10-xx-crossing-review.md` (protocol 2.10).
  - Set roadmap rows G2 and E4 (game half) in the design repo.

### I3b (blocked, not scheduled): E4 skip report
- Swap the local salience rule for crew_core's skip report from the journal once E4 publishes. Expected size is about 50 LOC plus re-recorded `crossing_hold`.

## Estimates and velocity

| Milestone | LOC (impl + tests) | Days | Depends |
|---|---|---|---|
| I1 | 380 | 1.5 | — |
| I2 | 550 | 2.0 | I1 |
| I3 | 650 | 2.0 | I2 (home art attended, in parallel) |
| I4 | 220 | 1.0 | I3 |
| E | 0 | 0.5 | I4 |
| **Total** | **1,800** | **7.0** | |

- **Velocity.** R2-CREW planned 2,490 LOC over 7 days at 350 LOC a day and landed in about two calendar days (2026-10-13 to 10-14, eval 88). The last 14 days on main show about 380 k insertions, mostly assets and recordings, so they aren't usable as a LOC rate.
- **Assumption.** We keep 350 LOC a day and add about 25% buffer for the Godot UI and the attended render reviews. That gives 7 working days.
- **Size versus the design.** The total is above the design's 1,300 for three reasons:
  - the design's own milestone table sums to 1,400;
  - the plan adds the playthrough-driver steps;
  - the plan adds the perf entry and the fixtures.

## Gates from CLAUDE.md, per milestone

| Gate | How this sprint meets it |
|---|---|
| 1 `make test` | Focused gates per milestone; full `make test` once at E (attended), then CI |
| 2 Physics | No new SR/GR visual. Physics numbers on the pages are existing sim fields; no new golden needed. The evaluator checks that no γ/β is recomputed in Godot (`speed_text` reads `cruise_one_minus_beta` from the sim) |
| 3 Maths in package | No new physics formulas. Crew logic stays in crew_core; ranking moves there with E4 (I3b) |
| 4 Pure core | `sim/cruise_digest.ail` and `sim/protocol_interlude.ail` are pure; `make strict` entry `digestScripted`; VM == interpreter (`crew-parity crossing_hold`, `parity`) |
| 5 Precision | Chunk years computed in float64 in the sim with the exactness property test; boundary check stays 1e-12 × plan; tier thresholds are in the sim, with a test at each edge |
| 6 Determinism | Digest is world state; `crew-parity` repeat-run diff; replay goldens below 2.10 unchanged |
| Display contract | Godot formats only; `display-audit-interlude` samples the review; no new known findings |

## Protocol version handling

- `interludeMinor() = 10` in `sim/protocol.ail`, added to `helloFor` and `sessionMinor` (the hello reports `relativityPin()`).
- **Fields at ≥ 10.** `cruise.next_stop_years` and `cruise.stop_kind` while committed; `cruise.digest` while committed and after arrival until the next commit.
- **Below 10.** Every 2.9-and-older stream is byte-identical. `make parity-v2` and `make replay` prove it, and no golden is re-recorded. If a golden does move, stop and list it for Mark (pause point 2).
- **Bridge.** `SimBridge.INTERLUDE_MINOR := 10`; the guided voyage and the live demo ask for it; tests read the minor from the sim, never a literal (F4).
- **Changelog.** A fragment names protocol 2.10.

## Registry reuse

| Milestone | Package | Decision |
|---|---|---|
| I1–I2 | `sunholo/crew_core` 0.5.0 (`auto.advanceAuto`, `Act`, `session.Archive`) | **depend** |
| I2 | moment salience / skip report | **none** now (local pure rule); **contribute** later via E4 upstream (I3b) |
| I2 | `sunholo/relativity` | **none** (no new formulas; existing sim fields) |
| I3 | — | **none** (Godot UI) |
| I4 | `ai/` service, `ai/voice.ail` | **none** (in-repo) |

## AILANG syntax gate (new or changed `.ail` modules)

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `sim/cruise_digest.ail` | include: `nextStop` requires `dayRem >= 0.0`, ensures `result.years >= 0.0`; `foldMoments` ensures `length(result) <= momentsMax()` | include: pure (strict VM) | include: `sim/cruise_digest_test.ail` (scripted crossing, tiers at each edge, exactness property, salience order) |
| `sim/protocol_interlude.ail` | skip: codecs, covered by round-trip tests | include: pure | include: round-trip and below-10 byte identity |
| `sim/crew_auto.ail` (changed) | include: `autoStep` ensures zero turns after an escalation | include: pure | include: `sim/crew_hold_test.ail` new cases |
| `sim/crew_script.ail` (changed) | skip: perf entries | include: pure | skip: exercised by `make crew-perf` |

## New make targets

- `crossing-review-test`: `tests/test_crossing_review.gd`, headless, in `make test`.
- `display-audit-interlude`: a guided playthrough that crosses one interlude, plus `display-audit`; in `ship-demo-ci`.
- `crossing-review-capture`: GPU window → `renders/crossing_review/`; attended, not in `make test`.
- **Extended:** `crew-perf` (`crewSkipChunked`), `crew-parity` (`crossing_hold` + repeat run), `strict` (`digestScripted`), `crew-hold-test`, `no-twitch-test`, `tour-pacing-test`.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| **Chunk-to-day exactness** (riskiest): a `next_stop_years` that converts to one day short makes the hold fall in the next chunk; one day over runs plain days after the hold | Medium | Computed in the sim from `dayRem` with a 200-seed property test; AC5 asserts zero days after the hold on the guided voyage end to end |
| Digest counts can't use traces (game is untraced) | Certain (known) | Counts from archive counters, state deltas and the `Act` log; the scripted crossing's expected values are hand-written first |
| Many chunks (about 120 per decade under monthly check-ins) slow the crossing in wall time or flood the pipelined heartbeat | Medium | One chunk per frame (≈2 s per decade at 60 Hz); measured in `crewSkipChunked`; the progress view covers it |
| Below-2.10 replay goldens move (World gains a field) | Low | Field emitted only at ≥ 10; `make replay` at every milestone gate; pause point 2 if one moves |
| `ship_consoles.gd` (1,115 lines) or `crew_page.gd` grows | Medium | The review is a new file; emotion leaves `crew_page.gd` (net shrink) |
| Home images (7 tiers) and four roles' emotion sets are attended art | Certain | Placeholders, plus the fallback list; captures flag placeholders; art is outside the sprint |
| The display audit misses the review again | Low after I3 | `display-audit-interlude` in `ship-demo-ci`, plus a negative control (an unbound Label on a page fails the audit) |
| AILANG VM bug in the digest fold | Low–medium | Report upstream with a repro and cite it at the gate; no downstream workaround (project rule) |

## Pause points

1. **After I1:** the chunked crossing with holds can ship alone. Report to Mark, who can merge it ahead of I2.
2. **Any replay golden below 2.10 moving:** stop; Mark reviews the listed diff.
3. **I3 renders:** Mark opens `renders/crossing_review/` before merge (a visible feature, attended).
4. **I4 live voice:** spend stays attended (D-8); CI and the loop run stub only.

## Design-doc notes (to fix in the design doc before or at approval)

1. **The D1 "Source" column says counts come from `CrewStepped.traces`.** The game crew is untraced, so traces are empty. The source should be the archive counters, state deltas and `advanceAuto`'s `Act` log (which `autoStep` must start returning).
2. **Ruling 4 says the guided voyage default is "today `off`".** `ship_geometry_demo.gd:621` already queues `critical_only` for every crew game. The ruling becomes a pinning test, not a change.
3. **AC8's playthrough** needs new driver steps (`m4_playthrough_ship.gd` walks free navigation only; interludes are guided-only). This is not in the Deliverables list.
4. **The protocol minor** should be named: 2.10 (`interludeMinor() = 10`). The new modules must join `sim/ailang.toml`'s exports.
5. **Tier lines** say "%s years" for n = 1 (tier 1 starts at 1 year: "1 years at home"). The singular needs specifying, or tier 1 should start at 2.
6. **The LOC header** says about 1,300; the milestone table sums to 1,400.
7. **D1 doesn't state the `next_stop_years` exactness rule** (crew days ↔ ship years through `dayRem`). It should, because AC5 depends on it.
