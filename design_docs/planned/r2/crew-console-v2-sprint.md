# Sprint R2-CREW-CONSOLE-V2: the Crew console as an internal videocom

**Design doc:** [crew-console-v2.md](crew-console-v2.md) (approved 2026-10-16; OQ1–OQ9 answered as recommended)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-CREW-CONSOLE-V2.json`
**Status:** **Approved 2026-10-16** (Mark, attended: "yes continue"; all nine recommendations). In execution: V1–V3 on `feat/crew-console-v2`, then a stop for Mark's render review of the V3 captures (pause point 3). V4 onward wait for that review.
**Scope:** V1 (the sim names the state; protocol minor), V2 (palette and model), V3 (board and call window; bindings), V4–V5 (concern flow; inline Ask/Order), V6 (keyboard and controller), V8 (the crew_core 0.6 rows), and E (evaluate and land).
**Base:** `main` after `feat/interlude-card` (R2-INTERLUDE, protocol 2.10) and `fix/crew-offer-while-paused` merge. Sprint branch `feat/crew-console-v2`; each milestone is one PR.
**AILANG:** v0.54.11 as pinned at execution (`runtime/VERSION`). AILANG prompt version loaded: v0.16.7.
**Protocol minor:** 2.11 (`consoleMinor()`), the next free minor above the interlude branch's 2.10; no other branch claims 11 (checked 2026-10-16).

## What the survey found

- **The page offers what the rules forbid.** `ui/crew_page.gd` `_work_card` shows "Start the work" whenever `work.status == "offered"`, whatever the reply was. On the real sim (seed 1, consent, all five offered), the pilot's concern card shows an enabled Start. Pressing it twice returns `crew:{"host":"personal consent required"}` ("Couldn't do that: personal consent required."). Scratch capture `zz_concern_start_refused.png`, not committed.
- **Decline, concern and defer all open an answerable issue** (crew_core `conversations.register`). The medic's card says "They declined." *and* "raised a concern", with an enabled Start.
- **Captaincy is session-wide.** crew_core `startTask` checks `s.command` at start. `setCommand` applies from the next start, and needs `idle` and `identity` like start does. So `policy orders`, `start_task`, `policy consent` inside one sim step is safe. **No per-offer captaincy exists** in the protocol or crew_core; V1 adds it host-side.
- **Answers come in the same tick** (`crew.ail` `answerPending`). The visible waits are client-side: intents queued with no tick (Mark's dev.31 counselor bug: offer again and again), then the AI words.
- **Insist is never shown.** `suggestions(issue, 1)` returns three approaches without `assert_authority`. crew_core's `validReply` accepts all five.
- **Trust costs are in crew_core** (`codec.traitDelta`): agreed +2; complied 2 − voice; strained lower; refused order −4 to −12 by agreeableness; denied relief −(2 + N/25). `conversations.reaction`: assert_authority raises stress by 2 and moves trust by −2 to +1. These give the cost lines as rules in words.
- **Layout units.** `project.godot` is 960 × 540 with `canvas_items` and `expand`, so 1280 × 720 and 2560 × 1440 show the same logical layout at ×1.333 and ×2.667. Portrait sources are 256 px (`data/crew/portraits`).
- **Sizes.** `ui/crew_page.gd` is 558 lines on the branch, `demos/ship_consoles.gd` about 1,115, `sim/protocol.ail` about 860 and `sim/protocol_crew.ail` 201. The UI splits into new files; the sim's additions go into `protocol_crew.ail` and `crew.ail`, not `protocol.ail`, beyond the minor's chain.
- **Every crew button is `FOCUS_NONE`.** There is no keyboard or controller path today.

## Plan shape

```
(deps) interlude merged + fix/crew-offer-while-paused merged
   └─▶ V1 sim state + intents (minor) ─▶ V2 palette/model ─▶ V3 board + call + bindings ─▶ V4/V5 concern + Ask/Order ─▶ V6 keys/pad ─▶ E
                                                                                        crew_core 0.6 pin ─▶ V8 (any time after V2)
```

V1 can ship alone: the sim's `work_state` and the start/offer envelopes, with today's page reading `work_state` to disable the forbidden Start. That is a small, early fix for Mark's main confusion (pause point 1).

## Milestones

### V1: the sim names the state (~420 LOC, 1.5 days) ✅ done 2026-10-16
- **Done:** protocol 2.11 (`consoleMinor()`); `workState` (table test, one row per value plus ties; a tie found on the real sim, a reconsideration left pending under ordered work, added as a row); `workTerms`; `crewCommandAs`; the offer's `start` (paired with its ask in the tick; a refused start is reported on the offer's index); `consoleScripted`; `crew-parity console_v2`. Gates green: sim tests, strict, crew-parity (6), parity, parity-v2, replay (11 cases identical, no golden re-recorded). The "early fix" to the old page was folded into V3, which replaces that page.
- **Red first:**
  - `sim/protocol_crew_test.ail` gains `workState` table cases, one per value plus the precedence ties (held over concern, relief over working, decline vs concern by the latest label, moot issues ignored).
  - `sim/crew_test.ail` gains:
    - `crewCommandAs`: under consent, an order over a refusal starts the work with terms `refused_order` and leaves `captaincy` consent;
    - a refused start leaves the crew state byte-identical (`encode` equal);
    - `as` matching the session command is today's path.
  - The `crew_offer` `start` cases: `on_accept` starts only on accept; `now` starts under orders on every label.
  - `tests/test_crew_console.gd` gains red real-sim cases for AC3 and AC4.
- **Sim:**
  - `workState(c, id)` and `workTerms(s, task)` in `sim/protocol_crew.ail`, pure.
  - `crewCommandAs(c, seed, rng, line, as)` in `sim/crew.ail` (all or nothing).
  - The `crew_offer` `start` expansion: offer, ask (answered), then a conditional start.
  - The decode of `as` and `start` in `decodeCrewIntent` (envelope fields beside `line`; `bad_intent` below the minor).
- **Protocol:** `consoleMinor()`, the next free minor (2.11, or 2.12 after the crew_core 0.6 migration). It joins `helloFor` and `sessionMinor`. The crew view adds `members[].work_state` and `work.terms` at ≥ consoleMinor only. The bridge gets `CONSOLE_MINOR`, and the game's sessions ask for it.
- **Determinism:** the `make strict` entry `consoleScripted`; the `make crew-parity` case `console_v2`, VM against interpreter and two runs byte-identical.
- **Early fix (pause point 1):** today's `_work_card` disables Start unless `work_state == "agreed"`, and shows the reason. That's about 20 LOC, so V1 is shippable before the redesign.
- **Gate:** `make sim strict crew-parity parity parity-v2 replay crew-console-test`.

### V2: palette and model (~280 LOC, 1 day) ✅ done 2026-10-16
- **Done:** `ui/crew_palette.gd` (tokens, icons, words, edges; contrast and CVD checks, CIEDE2000 verified against Sharma et al.), `ui/crew_console_model.gd`, `ui/crew_chip.gd` (drawn icons). Deviations: three hexes tuned so every neighbouring pair passes (asked `#3d8fd1`, agreed `#7fdcb0`, refused `#e8742a`, refused and free drawn as outlines); "neighbouring" is the explicit pair list `CrewPalette.NEIGHBOURS`. The palette test lives in `tests/test_crew_console.gd` (no separate file). The sending lock reads the console's own emitted intents and the bridge's `last_queued` (no new `queued_crew()` accessor was needed).
- **Red first:** `tests/test_crew_palette.gd` (new; run inside `crew-console-test`) checks:
  - every `work_state` plus `sending` maps one-to-one to a token, an icon and a word;
  - each token's contrast against the panel is ≥ 3:1, and chip text is ≥ 4.5:1;
  - CVD simulation (Machado deutan, protan and tritan at severity 1.0): adjacent pairs stay ΔE2000 ≥ 12, or differ in icon and edge style.
  - Model cases (pure, on recorded crew views): the pending lock (queued intent → all of that member's actions disabled, the others enabled), cleared by the next crew view or by a refusal; the reason words per state; the first-focus action per state.
- **UI (pure, no nodes):**
  - `ui/crew_palette.gd`: tokens, icons, words and edge styles.
  - `ui/crew_console_model.gd`, static functions: `chip(member)`, `actions(member, crew, client)`, `reason(member)`, `first_focus(member)`, `locked(id, client)`. It reads `work_state` from the sim and never derives it. The client overlay is only `sending`.
  - The bridge exposes queued crew intents per actor (`SimBridge.queued_crew()`), building on the fix PR's queue.
- **Gate:** `make crew-console-test`.

### V3: the board, the call window and the bindings (~600 LOC, 2 days) ✅ done; Mark reviewed the renders 2026-10-17 (attended): "yeah they look good - I think the UI is still a bit text heavy so we can have more visual UI but its a big improvement" (his feedback became V7b)
- **Done:** `ui/crew_console.gd` (board and call in one file; no separate `crew_call.gd`), `ui/crew_page.gd` reduced to static helpers, ShipConsoles hosts it full width (`crew_panel_rect`), recorded 2.11 fixtures (`tests/crew/console_v2/`, `make crew-console-fixtures`), NT3 rewritten and NT5 added, `display-audit-crew` with the `crew_unbound` control, the capture at both resolutions. Layout deviation: the call window is 430 wide and the decision panel 470 (936 logical leaves 920 inside the panel); the four answers sit in a two-by-two grid so a concern fits 540 logical. The decision block (V4/V5 UI: Ask or Order inline, disabled Start with its reason, Insist, Make it an order) is built here because the mockup's frames need it; V4's remaining items (reconsideration answered at once, keyboard) wait. The display audit's crew route samples no hold (a hold needs crew days the at-rest playthrough cannot pass); holds are covered by `crew-console-test` and `crew-hold-test`.
- **Red first:**
  - `tests/test_crew_console.gd` rewritten for v2 on recorded fixtures (`tests/crew/console_v2/*.json`, recorded from the real sim by `tools/crew_console_fixture.gd`): the board rows, sort order and quick actions; the call window opening on select, on an incoming concern with nothing open, and pulsing instead when a call or confirm is open; End call; the mini-roster switching calls; the portrait at the sim's `emotion` (a mutation changes the texture); no label under 12 logical.
  - `tests/test_no_twitch.gd` gains NT5: the board, a call and a hold left for 600 s of fake time with the sim ticking. Nothing closes and no intent is emitted.
  - `tests/display_audit.gd` gains a `crew` route; the control fixture is `tests/fixtures/display_audit/crew_unbound.ndjson`.
- **UI:**
  - `ui/crew_console.gd` (the board and the two-panel layout) and `ui/crew_call.gd` (the call window).
  - `ui/crew_page.gd` shrinks to its static helpers (`face`, `face_path`, `words`, `hold_text`, `load_roles`, `work_terms`), which the crossing review and the Voyage summary use.
  - `ship_consoles.gd` `_crew_section` hosts `CrewConsole`, and `panel_rect` takes the full width for `crew`.
  - Every Label is a `DisplayBinding` or `ComposedBinding`. The new formats are `crew_state`, `crew_reason` and `crew_day`, all formatting only. The `client.crew.*` fields join `CONTEXT_SOURCED`.
- **Captures:** `tools/crew_console_capture.gd` is rewritten. It writes six frames at 1280 × 720 and 2560 × 1440 (board, offer with How, concern, working, hold, sending), asserts no clipped node and a portrait ≥ 240 logical, and flags a portrait above 2.6× its source.
- **Gate:** `make crew-console-test no-twitch-test ship-console-test display-audit-crew display-audit-controls`, plus `make crew-console-capture` opened by eye.

### V4–V5: the concern flow and Ask/Order in context (~250 LOC, 1 day) ✅ done 2026-10-17
- **Done:** at 2.11 `crew_reply` carries `start` (`on_accept` | `answer`): they reconsider at once and, on agreement, the work starts (the console always sends `on_accept`, OQ3). Lapse notes on offered and deferred cards (OQ8); relief and stand-down rule lines; Make it an order; the How selector and ship-default strip (built in V3) now under AC11 tests. A pending reconsideration under ordered work is moot in `workState`.
- **Red first** (`tests/test_crew_console.gd`, real sim):
  - AC7: concern, declined and deferred disable Start, with the reason; four answers, Insist last with its cost line; first focus on answer 1.
  - AC8: one pending action per member.
  - AC11: How starts at the ship default, a change emits nothing, and the offer honours it.
  - AC12: free → working in two presses on an accepting member.
  - The real sim accepts `crew_start {as: orders}` from "Make it an order" on a declined card.
- **UI:**
  - The decision block per state (design V4 table).
  - The How selector: Ask/Order per offer and on declined or concern cards; the ship-default strip ("Ship default: Ask ▾", "Auto-run: Off ▾"; both confirmed); the cost lines in words.
  - The Insist reply uses the game's authored text for `assert_authority` (`CrewPalette.INSIST_TEXT`; no digits; ≤ 280 characters).
- **If OQ1 = (b):** `crew_offer {start: now}` is unused, and Order shows only as "Make it an order" (−40 LOC). **If OQ3 = no:** offers send no `start`; AC12 becomes three presses.
- **Gate:** `make crew-console-test no-twitch-test crew-hold-test`.

### V6: keyboard and controller (~150 LOC, 0.5 day) ✅ done 2026-10-17
- **Done:** `CrewConsole.key(event)`: arrows, D-pad and the left stick move the console's own focus ring (2 px in TEXT; the engine's focus stays with the ship); Enter/Space/A press the focused control (a decision arms, the same press sends); 1–4 arm then send an answer; [ ] and LB/RB switch the call; O/Y toggle Ask/Order; ? and Select open the legend; Esc/B disarm, then end the call, then fall through to step back. Routed from the demo before its own keys. Deviation: the buttons stay `FOCUS_NONE`; the console keeps its own focus ring so nothing else on the ship loses focus.
- **Red first:** `tests/test_crew_console.gd` drives the design V6 table with `InputEventKey` and `InputEventJoypadButton`: every action reachable; a decision only on the second press; Esc and B disarm, end the call, then step back, one level per press.
  - `tests/test_no_twitch.gd`: NT1 and NT3 with the crew console focused and the pad connected; no decision from any single key or button.
- **UI:** focus inside the console only (`FOCUS_ALL` on its controls while the crew panel is focused, `FOCUS_NONE` elsewhere); a focus outline in `TEXT`; `[`, `]`, LB and RB switch the call; the number keys 1–4 arm answers.
- **Gate:** `make crew-console-test no-twitch-test ship-console-test`.

### V7b: the visual pass (Mark's V3 review, 2026-10-17: "a bit text heavy … more visual UI") ✅ done 2026-10-17
- **AC-V7b-1** The work card shows its terms as icons: day pips for the duration, each resource it needs as an icon with a pip per unit (amber when used up), each effect on them as an icon with an arrow; the sentence is the row's tooltip; no "Takes … days" sentence is visible in a call (`make crew-console-test`).
- **AC-V7b-2** Rule lines (Ask, Order, Insist, Make it an order, the armed note, the lapse note, relief and stand-down) are one short line each, with the full rule as the tooltip and behind a "?" that opens it (no intent); not shown by default (`make crew-console-test`).
- **AC-V7b-3** The five reply approaches each draw their own icon (`make crew-console-test`).
- **AC-V7b-4** "Waiting on whom" and the mini-roster are faces with their state's colour and icon and a first name (`make crew-console-test`).
- **AC-V7b-5** The stress, fatigue and trust bars carry icons (tooltips name them); "strained" stays a word (`make crew-console-test`).
- **AC-V7b-6** Visible words per state at 1280×720 fall at least 30% in total from the V3 capture (`make crew-console-capture` prints words per frame).
- **AC-V7b-7** D-21 and V7 hold: no digits; every Label a binding; tooltips are authored copy or formats of sim fields (`make crew-console-test`, `make display-audit-crew`).
- **AC-V7b-8** Readable at 1280×720: no label under 12 logical, nothing outside the panel (`make crew-console-capture`).
- **Measured** (visible words, 1280×720, V3 → V7b): board 101 → 87, offer 113 → 69, sending 107 → 55, concern 143 → 101, working 95 → 38, hold 120 → 89; total 679 → 439 (−35%). The legend now waits behind "?" on the board.

### D-80: names fit faces ✅ done 2026-10-17
- Each face records its presentation and naming regions (`sim/data/crew_faces.ail`, mirrored in `data/crew/portraits/SOURCES`, checked by `make crew-faces-check`); `nameCrewFit` draws within them with the same crew-stream draws. Gated at 2.11 so older streams keep their names. Moved: the 2.11 console fixtures' names (`tests/crew/console_v2/*.json`); nothing at 2.10 or below.

### V8: the crew_core 0.6 rows (~50 LOC, 0.5 day; after the 0.6 pin) ✅ done 2026-10-17
- **Done:** crew_core 0.6.0 pinned here (main had 0.5.0); pack re-synced at ailang-packages ee58b27; the migration steps 1–8 (template lines, emotion, hold words, digest counts at 2.11, stand-down moments). Host change found against the real sim: a stand-down escalation's duty lapses at the next crew day, so the tick's remaining crew days and any while the stand-down hold is open wait in `dayRem` (`crew_auto.autoStep`) until it is answered. Fixtures `standdown.json`/`resting.json` recorded from the guided crossing (seed 42, orders, hands_on). Re-recorded: `tests/crew/crossing_hold.ndjson` (one hold now, a stand-down; two runs identical, VM == interpreter) and the scripted-crossing pins. AILANG v0.54.14 (#262) has not merged, so `scriptedCrossing` still uses `initCrewWith` (no generated names).
- **Red first:** a recorded 0.6 stand-down fixture: `stand_down_asked` (a hands_on hold) and `resting` (granted) appear, and the answers emit `resolve_stand_down`, confirmed. The test skips with a printed reason below 0.6.
- **Sim:** the two `workState` rows read the 0.6 fields; `templateLine` gains `stand_down` and `carry_on` (migration step 3, if the migration hasn't already added them).
- **Gate:** `make sim crew-console-test crew-parity`.

### E: evaluate and land (0.5 day)
- **Full run:** `make test` locally (attended), then CI (AC17).
- **Evaluation:** the `sprint-evaluator` runs on a **different model** from the executor and scores 100, with 70 to pass. Output goes to `.ailang/state/evaluations/eval_R2-CREW-CONSOLE-V2_round_<n>.json`.
- **Landing:**
  - Move the design doc and this plan to `design_docs/implemented/r2/`.
  - Write `crew-console-v2-report.md` (captures, measurements, upstream asks).
  - Add a changelog fragment `changelogs/unreleased/2026-10-xx-crew-console-v2.md` naming the protocol minor.
  - Update crew-work.md (W5's concern note superseded) and the design repo's roadmap row.

## Estimates and velocity

| Milestone | LOC (impl + tests) | Days | Depends |
|---|---|---|---|
| V1 | 420 | 1.5 | interlude merged |
| V2 | 280 | 1.0 | V1, fix PR merged |
| V3 | 600 | 2.0 | V2 |
| V4–V5 | 250 | 1.0 | V3 |
| V6 | 150 | 0.5 | V3 |
| V8 | 50 | 0.5 | V2, crew_core 0.6 pin |
| E | 0 | 0.5 | all |
| **Total** | **1,750** | **7.0** | |

- **Velocity.** R2-CREW planned 2,490 LOC at 350 LOC a day and landed in about two calendar days. R2-INTERLUDE planned 1,800 LOC over 7 days and built I1–I4 on 2026-10-16. Recent git stats are dominated by assets and recordings, so they aren't a usable LOC rate.
- **Assumption.** 350 LOC a day, plus about 25% for the Godot layout iterations and two attended render reviews (mockup, V3 captures). That gives 7 working days. At R2-INTERLUDE's pace the calendar time is likely 2–3 days.

## Gates from CLAUDE.md, per milestone

| Gate | How this sprint meets it |
|---|---|
| 1 `make test` | Focused gates per milestone; full `make test` once at E (attended), then CI |
| 2 Physics | No SR or GR visual. No physics numbers on the console |
| 3 Maths in package | No formulas. The crew rules stay in crew_core; the costs are worded from its rules, not recomputed. Upstream asks (OQ6 concern catalogue, OQ8 withdraw) go to the crew lab |
| 4 Pure core | `workState`, `workTerms`, `crewCommandAs` and the offer expansion are pure; the strict entry is `consoleScripted`; VM equals interpreter (`crew-parity console_v2`, `parity`) |
| 5 Precision | No floats in the new logic. Day k of n are integers from the sim |
| 6 Determinism | All new state is sim state or client display state. Per-offer orders are journalled crew_core lines; repeat-run byte identity in `crew-parity` |
| Display contract | Every Label is a binding; `display-audit-crew` plus the negative control `crew_unbound` |

## Protocol version handling

- **`consoleMinor()`**: the next free minor at execution, read from `sim/protocol.ail`, never a literal in tests (F4). It joins `helloFor` and `sessionMinor`, and the bridge gets `CONSOLE_MINOR`.
- **At ≥ consoleMinor:**
  - `crew.members[].work_state`;
  - `crew.members[].work.terms` (working only);
  - the `crew_start` envelope field `as` (`consent` or `orders`);
  - the `crew_offer` envelope field `start` (`on_accept` or `now`).
- **Below it:** every stream is byte-identical, and `as` or `start` is `bad_intent`. `make parity-v2 replay` runs at every milestone gate. If a golden moves, stop (pause point 2).
- **Changelog:** a fragment names the minor.

## Registry reuse

| Milestone | Package | Decision |
|---|---|---|
| V1 | `sunholo/crew_core` (pinned: `session.startTask`, `setCommand`, `moot`, `conversations.Issue`, `codec` outcome codes) | **depend** |
| V1 | per-offer captaincy | **none** (host-side composition of existing commands) |
| V4 | a game concern catalogue keyed by recipe (OQ6) and `withdraw_offer` (OQ8) | **contribute** (upstream request to the crew lab; not blocking) |
| V2–V6 | — | **none** (Godot UI) |
| V8 | `sunholo/crew_core` 0.6.0 (stand-down) | **depend** |

## AILANG syntax gate (new or changed `.ail`)

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `sim/protocol_crew.ail` (`workState`, `workTerms`) | include: `workState` ensures `contains(workStates(), result)` | include: pure | include: `protocol_crew_test` table, one row per value and precedence ties |
| `sim/crew.ail` (`crewCommandAs`, the offer expansion) | include: ensures that on refusal `result.crew == c` and the rng is unchanged | include: pure | include: `crew_test` cases (order over refusal, refused start unchanged, `on_accept`, `now`) |
| `sim/protocol.ail` (the minor chain) | skip: a constant and its chain, covered by parity and replay | include: pure | skip: `make parity-v2 replay` |
| `sim/crew_script.ail` (`consoleScripted`) | skip: script data | include: pure | include: `make strict` entry and the `crew-parity` case |

## New make targets

- `display-audit-crew`: a playthrough at the Crew console (board, each call state, a hold), plus `display-audit` with `DISPLAY_KNOWN` unchanged. It goes in `ship-demo-ci`.
- `crew-console-fixtures`: re-records `tests/crew/console_v2/*.json` from the real sim (a reviewed diff; never in `make test`).
- **Extended:** `crew-console-test` (the palette, the model, v2 layout, keys and pad), `crew-console-capture` (six frames × two resolutions), `crew-parity` (`console_v2`), `strict` (`consoleScripted`), `no-twitch-test` (NT5).

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| The two-panel layout doesn't fit 936 × 424 logical with long work text | Medium | The decision block comes first; the terms collapse to one line with "more"; the capture asserts nothing clipped |
| The fix PR's queue shape differs from what V2 assumes | Medium | V2 reads one bridge accessor (`queued_crew()`); adapt it, not the model |
| Below-minor goldens move | Low | All new fields and envelopes are gated; `parity-v2 replay` at every gate |
| A per-offer order miscounted as a captaincy switch in the crossing digest | Low | A digest test: switches count only `crew_policy` intents |
| The palette reads as judgement (Pillar 2) | Medium | Mark reviews the mockup before V2; the words name states, not virtues |
| Portraits soft at 1440p (256 px sources) | Certain until art | OQ7; the capture flags it; attended art outside the sprint |
| An AILANG VM bug in the new pure functions | Low | Report upstream with a repro; cite it at the gate; no downstream workaround (project rule) |

## Pause points

1. **After V1:** the sim's `work_state`, plus today's page disabling a forbidden Start, can merge alone. That fixes Mark's main confusion before the redesign.
2. **Any replay golden below consoleMinor moving:** stop. Mark reviews the listed diff.
3. **V3 captures:** Mark opens `renders/crew_console/*` at both resolutions before merge (a visible feature, attended).
4. **V8:** waits on the crew_core 0.6 pin. It is not on the critical path.

## Questions for Mark (from the design doc)

OQ1 Order semantics (recommend: start now) · OQ2 keep the global default and auto-run (recommend: keep both, in the header) · OQ3 start on agreement (recommend: yes) · OQ4 incoming calls (recommend: open only when nothing is open or armed) · OQ5 Insist as a fourth answer (recommend: yes) · OQ6 the concern catalogue upstream (recommend: ask the crew lab) · OQ7 portraits at 1024 px (recommend: yes, attended art) · OQ8 `withdraw_offer` upstream (recommend: ask; show the lapse note meanwhile) · OQ9 declined means open to talk (recommend: yes).
