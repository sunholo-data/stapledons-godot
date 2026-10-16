# R2-INTERLUDE: the crossing review (the cruise interlude as "what happened while you were away")

**Status:** IMPLEMENTED 2026-10-17 (R2-INTERLUDE, PR #264; evaluation 89/100 PASS). Proposed 2026-10-16; open questions ruled by Mark the same day (see Rulings) (draft for `design_docs/implemented/r2/interlude-card.md`). Mark, attended 2026-10-16: "this interlude card is important and deserves its own design doc ... having a lot of text and pictures to review for the player is maybe a good use of the time".
**Release:** R2 (voyage life). It is roadmap row **G2** ("What happened aboard" in the Archive's voice) for the cruise case, and the game half of **E4** (the skip report).
**Priority:** P1 for R2. The interlude is the only place where a decade of ship life is shown.

**Implements** (design repo):
- [voyage-life-loop.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/voyage-life-loop.md): §2 Interrupts (a hold stops the skip; "the player can resume") and the report "What happened aboard" (Counts, Movement, Moments 3–7, Archive voice).
- [journey-system.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md) "WHAT HAPPENED ABOARD" / Destination Reveal mock (about line 705).
- [guided-voyage-highlights.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/guided-voyage-highlights.md): "one labelled interlude that advances to the authoritative braking boundary" (kept).
- [archive-voice.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/archive-voice.md) and [archive-crew-trust.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/archive-crew-trust.md) (the narrator, §D5).
- [roadmap/r2-voyage-life.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r2-voyage-life.md) rows E4, G2.
- Ledger: D-40, D-41 (the cut is a seam for in-ship gameplay), D-46, D-7 (eight emotions; AI output recorded as sim input), D-20, D-21 (no digits in generated text; caps 280/600), D-67 (in-world voice), D-70, D-76 (monthly check-ins on long skips; "spread across frames with a progress view"), D-80 (names fit faces).
- No physics-spec section: no new SR/GR visual. Physics numbers on the pages are existing sim fields.

**Depends on:**
- R2-CREW (implemented; `sim/crew.ail`, `sim/crew_auto.ail`, `sim/protocol_crew.ail`, `crew_hold`).
- crew-work W1 (#239, the Crew console and `ui/crew_page.gd` portraits/emotion map).
- E4 upstream (crew_core skip report from the journal) for phase I3 only; I1–I2 do not wait on it.
- archive-npc OQ1 (presence) for the narrator art in I4 only.

**Estimated LOC:** about 1,400, the sum of the milestone table (sprint plan: ~1,800 with tests and playthrough steps, 7 days).

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`), 2026-10-16. **ALIGNED.** Pillar 3's point (holds stop ship time) was ruled on: holds stop the crossing (Rulings §3).

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | The review shows what the standing orders and auto-run did on your behalf; nothing can be redone. A hold answered mid-crossing stays answered |
| The Game Doesn't Judge | +2 | It is a report of facts (who changed, what was said, what was lost at home), never a grade. No "good/bad crossing" label (the AC bans scored words) |
| Time Has Emotional Weight | +2 | The core payoff: "You lived 92 days; 66 years passed at home", the people at home tier, news age, beside the crew faces that aged with you. The player reads it at their own pace instead of having it cut away at 6 s |
| The Ship Is Home | +2 | Today the interlude says nothing about the crew. After this, the crossing is told through their moments, faces and emotions |
| Grounded Strangeness | +1 | The medium page (clouds crossed, grains swept, largest impact) keeps the crossing physical |
| We Are Not Built For This | +1 | Strain, refusals, relief requests and breakdown holds are shown as they happened; the review does not soften them |
| **Net** | **+9** | **Go.** No pillar at 0 or below. Pillar 3 caveat: a hold stops ship time while the captain decides (same rule as CI-5 holds today); the review itself is read *after* the time has passed, so it does not pause the universe |

## Problem

| # | Evidence (today) | Consequence |
|---|---|---|
| P1 | `ui/card_interlude.gd`: `advance()` returns the whole remaining cruise in the first frame; `done()` is true after `CARD_S = 6.0` s or Continue | The player gets 6 s for a card that can hold seven blocks of text, then it cuts away mid-read |
| P2 | `CardInterlude.lines()`: title, speed/γ, distance, lived/Earth, news age, tier, ISM, "Cutting to arrival braking." No crew | A decade aboard is invisible. Crew reach the player only through the bridge summary line (`demos/ship_consoles.gd` ~982–1001) and holds |
| P3 | `sim/crew_auto.ail` `autoStep`: an escalation raises a hold, then "the remaining days advance with no decisions" (`plainDays`) to the end of the tick. `demos/solar_departure.gd` checks `crew_held()` only *between* steps | A hold raised in month 2 of a 10-year cruise is presented at the braking boundary, after the remaining ~9.8 years ran without the captain. crew-integration AC15 "the cruise interlude stops at a `crew_hold`" holds only at step granularity, and the step is the whole cruise |
| P4 | `sim/crew.ail` `linesMax() = 6`; the crew view's `heard` is the last 6 (`heardMax`); nothing accumulates across a step | Godot cannot reconstruct a crossing's moments; only the last six lines survive a decade |
| P5 | One step = whole cruise; `bridge/sim_bridge.gd` `step_timeout` is a fixed 2,000 ms. Measured: a decade critical_only ~0.46 s; a busy no-hold decade ~11 s (test-only worst case) | A busier crew or a longer leg times the bridge out. D-76 already ruled skips are "spread across frames with a progress view"; the card does not do that |
| P6 | `CardInterlude.lines()` computes `(after.ship_tau − before.ship_tau) × 365.25` and `after − before` Earth years; `InterludeCard.show_interlude` lerps clocks; `IsmHud.interlude_text` subtracts grain counts; all plain `Label`s | Violates "Godot formats and never computes" (DisplayBinding contract). Not caught because no display-audit playthrough reaches an interlude (no interlude entry in `tests/fixtures/display_audit/known_findings.json`) |

## Goals and non-goals

| Goals | Non-goals |
|---|---|
| G1. A player-paced review: pages the player turns; **no timer ever dismisses content** | A live LLM in the build (no real keys; D-20, project memory) |
| G2. A **cruise digest** computed in the pure sim (strict VM, VM == interpreter, deterministic, in world state) | Live in-ship gameplay during the cruise (Live mode, voyage-life-loop §1); this is the Skip report only |
| G3. The cruise advances in **budgeted chunks** that end exactly at a hold, so the captain answers it *in* the crossing | Changing the braking-boundary contract, pacing thresholds (`CUT_THRESHOLD_S`) or D-40/D-46 rhythm |
| G4. Every number on every page is a DisplayBinding/ComposedBinding over a sim field, audited | Births, deaths, kinship (crew_core life cycle; not in the host yet) |
| G5. Pictures: crew portraits with emotions, Earth/home, the medium, the ship | New physics, new shaders |

## Design

### D1. The sim: chunked cruise and the cruise digest (pure, `sim/cruise_digest.ail`)

**Chunking.** The sim publishes where the next stop is; Godot steps exactly that (it never computes ship time). The published `next_stop_years` must convert through the crew's `dayRem` to **exactly** the stop day: one day short and the hold slips into the next chunk, one day over and plain days run after it. The sim computes it, and a property test over 200 seeds checks it, as does AC5 end to end.

| Field (new, protocol 2.x minor) | Meaning |
|---|---|
| `cruise.next_stop_years` | Ship years from now to the earliest of: the braking boundary; the next auto-run decision day (D-76 cadence 30 on a committed leg, `nextDecision`); a chunk cap `chunkDays()` (365 crew days, Rulings §5) |
| `cruise.stop_kind` | `braking` / `check_in` / `chunk` |

`CruiseInterlude.advance()` returns `min(cruise.next_stop_years, max_years)` per frame (a "Crossing…" progress view between chunks, D-76). Because an escalation can only fire on a decision day and a chunk ends right after it, **a hold is always the last thing in its chunk**: `autoStep` runs zero plain days after it. `crew_held()` (unchanged) then stops the host before the next chunk. Resume continues the crossing. No change to `tick`'s contract (`dtau` fully consumed).

**The digest** is world state (`world.cruise_digest`), reset at commit, folded each tick while the journey is committed. No hidden state: it is in the replay, re-derivable from the inputs.

| Section | Fields (all sim-computed; Godot formats only) | Source |
|---|---|---|
| `time` | `ship_days`, `earth_years`, `earth_year_total`, `news_age_years`, `tier` (0/1/2, thresholds 10/80 moved from `CardInterlude.TIERS` into the sim) | clock, consequence |
| `home` | `tier`, `news_epoch`, last arrival news `template_id` (if any) | consequence (`cq.news`) |
| `medium` | `media` rows crossed, `grains_swept` (delta), `largest_um`, `largest_j` | ISM dust (replaces Godot's subtraction in `IsmHud.interlude_text`) |
| `crew.counts` | `days`, `work_done`, `refusals`, `concerns`, `concerns_auto_answered`, `reliefs_asked/granted/denied`, `holds` | crew_core's archive counters, member-state deltas and the `advanceAuto` Act log (the game crew runs untraced: `initCrew` passes `traced = false`, so `traces` is empty; `autoStep` must keep the Acts it now drops), `autoStep` holds |
| `crew.movement` | per member: `id, name, stress0/1, fatigue0/1, morale0/1, trust0/1` and `d_*` deltas; ranked by \|Δ\| | member indicators at begin/end |
| `crew.moments` | up to `momentsMax() = 7`: `{day, actor, name, label, text, emotion, ai_req, kind}` | every `CrewLine` and hold in the crossing, ranked by a pure salience rule (hold > refusal > relief > concern > accept) until E4 replaces it |
| `waiting` | open requests and reliefs the captain has not answered | crew view (already there) |

**Emotion is chosen in the sim** (`emotionOf(label, stress)`), moving `ui/crew_page.gd`'s `LABEL_EMOTION` / strained rule into one tested copy; Godot keeps only the portrait *fallback* list (a missing face, not a choice).

**Text** is authored: `protocol_crew.templateLine(label)` (no digits, D-21), or the recorded `crew_reply` AI words when an `ai_req` was accepted (D-7 (7): recorded sim input, so replays stay byte-identical). No live call.

### D2. Godot: the review (`ui/crossing_review.gd`, replaces `InterludeCard`; `CardInterlude` keeps the seam)

Pages, turned by the player (Next / Back / arrow keys / Enter on the last page). Dismiss = the last page's "Brake for <target>" button. **No auto-advance; no timeout.** Pages with nothing to say are omitted.

| # | Page | Text (all numbers bound) | Pictures |
|---|---|---|---|
| 1 | **The crossing** | leg, speed/γ, distance, "You lived N days. X years passed on Earth." (the clocks count up once, from sim before/after values, display only) | the live cruise sky behind the panel |
| 2 | **Home** | tier line, Earth year since departure, news age; the latest news from the last arrival in words | the tier's home image (Rulings §2) |
| 3 | **Aboard** | Counts as a sentence ("Your crew did N jobs; two refused; one asked to step back") | crew row: each member's portrait at their end-of-crossing emotion |
| 4…k | **Moments** (one per moment, 3–7) | day in the crossing, who, the line, what auto-run did | that person's portrait at the moment's `emotion` (D-7 eight; fallback list) |
| k+1 | **Who changed** | Movement: top members by \|Δ\| in words plus bound numbers | portraits, before/after emotion |
| k+2 | **The medium** | `IsmHud` rows from `medium.*` | the media strip (existing ISM HUD art) |
| k+3 | **Waiting for you** | open requests/reliefs; "at the Crew console" | portraits |

**Holds mid-crossing.** When a chunk ends on a hold, the review opens at a **Hold page** first: who, what (existing hold-card words from `CrewPage`), their portrait (sad/strained, as `CrewPage` call panel), and the same confirmed actions (answer at the Crew console, or Resume with a confirming press = `crew_resume`). The crossing so far is reviewable behind it ("So far: N days"). Resume continues chunking; the final review covers the whole crossing (the digest is not reset by a hold).

### D3. The Archive as narrator (I4; Rulings §6: with voice)

voyage-life-loop says the report is told "in the Archive's voice through the recorded AI service". I4 (Rulings §6): the Archive's **authored** framing sentences (in-world, D-67, no digits) on pages 1 and 3, keyed by tier and counts, always. With live AI ticked and a key present (D-8), an `ai_open{purpose: archive}` request carries the digest's bound fields as context; the reply passes the existing filter (`ai/reply.ail screen`) and is spoken through `ai/voice.ail` (Gemini TTS), once per crossing, cached by the voice key. The reply is recorded sim input, so replays stay byte-identical. Without a key: the authored lines and the stub voice. Its spire presence/art waits on archive-npc OQ1. Misremembering under low integrity is out of scope until archive-npc A1 ships.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | Digest fields exist and equal hand-computed values on a scripted 1-year crossing (counts, movement deltas, moments ≤ 7, tier thresholds 10/80) | `make sim` (new `sim/cruise_digest_test.ail`) |
| AC2 | Digest code is pure and runs on the strict VM | `make strict` |
| AC3 | VM == interpreter byte for byte over a scripted crossing with a hold, a resume and a refusal | `make crew-parity` (new case `crossing_hold`) and `make parity` |
| AC4 | Same seed and inputs → byte-identical digest (two runs diffed) | `make crew-parity` (repeat-run check) |
| AC5 | A hold raised on a decision day ends its chunk: zero crew days run after it; ship time waits; Resume continues to the braking boundary within 1e-12 of plan | `make crew-hold-test` (extended) |
| AC6 | Every chunk under 1.0 s headless on a busy decade (no `step_timeout`); total decade critical_only under 2 s (AC11 kept) | `make crew-perf` (extended) |
| AC7 | No page is dismissed without input: 600 s of fake time on each page leaves it shown | `make no-twitch-test` (new interlude state) and `make tour-pacing-test` (`test_cruise_interlude.gd` rewritten) |
| AC8 | Every number on every page is a DisplayBinding/ComposedBinding over a sim field; no known-finding entries added | `make display-audit` with a new playthrough script that crosses one interlude with crew aboard |
| AC9 | Generated/authored crew text in the review has no digits and respects 280 chars (D-21); no "good/bad/score" words | `make crew-console-test` (new review cases) |
| AC10 | Portrait per moment matches the sim's `emotion` with the fallback list; mutating `emotion` in the fixture changes the texture | Godot headless `tests/test_crossing_review.gd` (via `make crew-console-test`) |
| AC11 | Renders opened and looked at: each page at 1280×720 and 2560×1440, a hold page, a no-crew crossing, the TRAPPIST-1 and Aldebaran legs | `tools/crossing_review_capture.gd` → `renders/crossing_review/*.png` (new `make crossing-review-capture`) |
| AC12 | `make test` green locally and in CI | `make test` |

## Sub-milestones and estimates

| ID | Scope | LOC | Depends on |
|---|---|---|---|
| I1 | Sim: `cruise.next_stop_years`/`stop_kind`, chunked `CardInterlude.advance`, progress view, hold stops the crossing (AC5, AC6) | 300 | — |
| I2 | Sim: `cruise_digest` (time, home, medium, crew counts/movement/moments, emotion in sim) + protocol + tests on both engines (AC1–AC4) | 450 | I1 |
| I3 | Godot: `CrossingReview` pages, hold page, bindings, captures, display-audit playthrough (AC7–AC11) | 450 | I2 |
| I3b | Swap moment ranking for crew_core E4's report when published | 50 | E4 upstream |
| I4 | Archive narration: authored lines always; live telling + voice with a key (Rulings §6) | 150 | archive-npc OQ1 (presence art only) |

Order: I1 → I2 → I3; I3b and I4 later. I1 alone fixes P3 and P5 and can ship first.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Many chunks make a long crossing slow in wall time | Chunks run back-to-back under the progress view; cap only bounds a single step. Measure in AC6 |
| Moment salience feels arbitrary before E4 | Pure, tested rule; replace with E4 (I3b); Mark reviews renders |
| Only the medic has eight emotions; four roles are neutral-only | Fallback list (exists); generate sets under D-7 as a separate art task |
| Review turns into a wall of text | Pages omitted when empty; moments capped at 7; captures reviewed |
| Display audit misses the review again | AC8 adds a playthrough that reaches it |

## Rulings (Mark, attended 2026-10-16)

All seven open questions were answered in the session ("yeah these are all good lets go with them").

| # | Question | Ruling |
|---|---|---|
| 1 | Pages or one scroll? | **Pages**, with a page-dots strip: "a good place to catch up on news and events". News arrives only at stops, so the Home page shows the last port's news and its present age. |
| 2 | Earth/home picture | **(b)**: one authored/generated "home" image per tier (D-7 generate-and-cache), keyed by the sim's `time.tier`. |
| 3 | Do holds stop the crossing? | **Yes.** A chunk ends on the hold; the review opens on the Hold page; Resume continues the crossing. |
| 4 | Default auto-run during cruises | **`critical_only`** for the guided voyage. Already true: `demos/ship_geometry_demo.gd:621` queues `critical_only` for every game with crew (the earlier "today `off`" was wrong), so this becomes a regression test. |
| 5 | Chunk cap | **365 crew days** as the safety cap. Chunks normally end at the monthly check-in (D-76) or the braking boundary. |
| 6 | Archive narrator | **Yes, with voice.** Authored in-world sentences always (D-67, no digits). With live AI ticked and a key present (D-8), the Archive writes its own telling of the crossing and speaks it through `ai/voice.ail` (Gemini TTS), generated once per crossing and cached; otherwise the stub voice. Its spire presence still waits on archive-npc OQ1. |
| 7 | Home-time wording | Seven tiers, moved into the sim (`time.tier` 0–6). The old third tier's claim ("No one alive on Earth was born when you left") began at 80 years but holds only beyond ~120, so it moves to tier 5. |

Tier lines (`%s` = whole Earth years since departure, from `clock.year`):

| Tier | Earth years | Line |
|---|---|---|
| 0 | < 1 | "Less than a year at home. They are still watching for word from you." |
| 1 | < 10 | "%s years at home. The news you left with is history." (the sim gives "A year at home." when the whole number is 1) |
| 2 | < 30 | "%s years. The children you knew have grown up; your name is a story they half remember." |
| 3 | < 80 | "%s years. Your parents' generation is gone; the friends you left are old." |
| 4 | < 130 | "%s years. Everyone you knew is gone." |
| 5 | < 1000 | "%s years. No one alive on Earth was born when you left. The countries you knew may not exist." |
| 6 | beyond | "%s years. Longer than recorded history before you left. Whatever answers your signal will not be the Earth you left." |

## Deliverables

- `sim/cruise_digest.ail`, `sim/cruise_digest_test.ail` (both added to `[exports].modules` in `sim/ailang.toml`); protocol fields in `sim/protocol*.ail` as **protocol 2.10** (`interludeMinor = 10`); `CHANGELOG` protocol minor.
- Playthrough-driver steps that fly a guided-voyage cruise (`tests/m4_playthrough_ship.gd` walks free navigation only, and interludes happen only in the guided voyage), so the display audit (AC8) samples a real interlude.
- `ui/card_interlude.gd` (chunked), `ui/crossing_review.gd` (replaces `ui/interlude_card.gd`), `tests/test_crossing_review.gd`, `tests/test_cruise_interlude.gd` rewritten, `tests/test_crew_hold.gd` extended.
- `tools/crossing_review_capture.gd`, `renders/crossing_review/`, a display-audit playthrough script.
- Report `design_docs/implemented/r2/interlude-card-report.md` at landing.

## Notes found while researching (corrections to the brief)

- Holds do **not** stop the cruise today: `autoStep` runs the remaining days plain after an escalation; the host stops only after the whole-cruise step (P3).
- No crew "losses" exist in the crew host: the only `loss` is a news-burst major event raised **on arrival** (`sim/crew_events.ail`, templates 8 and 15). No deaths/births until crew_core life cycle.
- News reaches the ship only at arrivals (`sim/core.ail` ~685); during a cruise there is news *age*, not news.
- D-76 already ruled skips are "spread across frames with a progress view"; the one-step card predates it.
- The current card computes deltas and animates in Godot (P6), outside the display audit's reach.
- Portraits: `data/crew/portraits/` (five roles; medic has all eight emotions, others neutral). `assets/characters/medic/` holds the D-7 medic set; the captain has avatar sprites, not portraits.
