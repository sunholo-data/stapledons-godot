# Sprint R1-SHIP-UI: the HUD informs, the bridge consoles decide

**Design doc:** [ship-ui-hud-consoles.md](ship-ui-hud-consoles.md) (D-56).
**Status:** Proposed 2026-10-08. **Stop for Mark's approval before executing**, including his answers to Q1–Q6. Q1 decides whether this sprint carries M4.3b.
**Branch (on approval):** `sprint/ship-ui`, from `origin/main` after `feat/free-nav-stops`, #171 and #177 have merged.
**Estimate:** about 2,330 LOC (code 1,480, tests and seams 640, spike 60, capture 150), **7 working days**. At the observed pace of about 400 LOC/day (R1-SHIP-STAR-LIGHT: 600 LOC in 1.5 days; free-nav-stops: about 600 LOC in a day) the work is 5.8 days; 7 days is about 20% buffer for the map-embedding spike and test migration.
**Risk:** medium. There are no physics, sim, protocol or package changes. The risks are the UI plumbing (embedding `GalaxyMap`'s native window), walk-mesh reachability, and migrating about 14 tests and tools that drive decision keys.

## Registry reuse

| Milestone | Package | Action | Reason |
|---|---|---|---|
| U0–U8 | none | none | Godot UI and input only. Every number shown is a sim field (no new maths); `sunholo/relativity` is not touched. Physics gates 2 and 3 do not apply (no SR/GR visual change). Gate 5 is served by dropping the `1.0 - beta` fallback (charter 7d(a)). |

## Current status (evidence)

- `demos/ship_geometry_demo.gd` (844 lines): `_hud()` builds 13+ buttons, and `_unhandled_input` maps 24 keys, of which N, L, C and M, plus three HUD buttons, are decisions.
- `ship.glb` already has `console_navigation_0..2`, `console_decision_0..3`, `archive_terminal` and `captain_chair` at bridge height (y = 82). `walk_bridge.glb` has only `WALK_bridge` (no `INTERACT_` nodes).
- `interior/walk.gd` already has `path()` (A*) and `nearest_interactable()` from M4.2.
- `ui/journey_hud.gd` (M4.3a) has the transit rows as `DisplayBinding`s, built for `--interior`.
- Tests and tools that call decision paths or keys: `test_bh_hud`, `test_manual_exposure`, `test_planets`, `test_ship_demo_live`, `test_ship_demo_consolidation`, `test_tour_attitude`, and the captures and benches `bh_ship_*`, `inspect_bodies_capture`, `ship_star_identification_capture`, `ship_demo_live_capture`, `ship_star_light_capture` and `solar_departure_*`. Most call the methods directly. Those methods stay as the console actions' targets, so only key-driven cases change.

## Milestones

| ID | Work | LOC | Depends | Acceptance (design AC) |
|---|---|---:|---|---|
| **U0** | **Tests first (red).** The `SimBridge` record seam tags every sent intent with its source (`player`, `tour`, `tick`); a fake-clock `now()` seam for `ShipHud`, `ShipConsoles` and the confirm (no wall-clock reads, two runs give identical logs). `tests/test_ship_ui.gd` (strip in 9 states, bindings, cards, table parity, dev gating), `tests/test_ship_consoles.gd` (stations from GLB, reachability, prompt, use/leave, confirm modes, chart vs helm, intent equality), `tests/test_no_twitch.gd` (key/mouse sweep in 4 states, 600 s fake-clock survival). `ui/ship_controls.gd` (the §F table as data). Makefile: `ship-ui-test`, `ship-console-test`, `no-twitch-test` added to `ship-demo-ci`. Both seams are record-only, with no behaviour change. | 640 | merges above | AC1–11 defined; each fails for the right reason |
| **U1** | **`ui/ship_hud.gd` status strip and frame:** ship and home clocks (same size), distance (reuse `distances_text`), where/phase, speed while moving (from `one_minus_beta`; the `1.0 - beta` fallback removed), view tag. Card stack (priority, two expanded, fades, centre-third exclusion). Prompt line. Tab panel (details, grouped controls, Walk to). `hud_text()` and the button column retired. Dev controls gated on `menu_return`. | 330 | U0 | AC1, AC2, AC3 (frame), AC7, AC11 |
| **U2** | **Contextual cards (M4.3b's 3D half under Q1(A)):** transit card from `JourneyHud.ROWS` (compact, full rows in Tab); brake and final-approach notices; arrival card; gravity card (`BlackHoleVisit.hud_lines`); tour card with the pacing buttons (P, N skip dwell, K); warp level shown only (no new warp control: Q3 edge); Archive-unlock and refusal cards; dwell label on stars and bodies (read-only `ShipStarIdentification` pick). | 260 | U1 | AC3 |
| **U3** | **`demos/ship_consoles.gd` (`ShipConsoles`):** stations from `ship.glb` node names; use points (`closest_walkable(origin, 2.5)`, walked path lengths printed, 40 m ceiling); E priority = nearest interactable in reach and facing (lift included), named by the prompt; reach-and-facing prompt; E or click to use; 0.6 s camera dolly to the focus pose and back; panel host aligned to the console rect; click-to-walk and the Tab "Walk to" list (`WalkArea.path`, 3.5 m/s, WASD cancels); confirm modes (hold 1.5 s / press twice) with the setting in `ui/game_settings.gd`; idle screens (SubViewport label textures on the console screens, display only); onboarding glow and hint; `use(station, action)` as the single entry for player, tests and the M4.5 bot. | 380 | U0 | AC6, AC8, AC14a |
| **U4a** | **Spike (own day):** embed `GalaxyMap` (native `Window`, `force_native`, `own_world_3d`, own `window_input`) in a panel, or fall back to a borderless window over the console rect. `make ship-ui-window-check` runs the chosen host in a real GPU window: open, click-select, hold-commit. | 60 | U0 | AC15 |
| **U4** | **Navigation station.** On the host U4a chose. `GalaxyMap.mode` = chart / helm: chart hides the slider, commit, cancel, Return to Sol, in-system list and Sgr A* entry, and never pauses the tour; selection carries over to the helm. M opens the chart; I-card "Open in map" opens the chart. Helm hosts commit, cancel and the Sgr A* entry; at Sgr A* the helm shows the stop ladder with Approach and Leave (confirm). | 220 | U3, U4a | AC9, AC10, AC15 |
| **U5** | **Voyage console and Archive terminal.** Itinerary and "Begin guided voyage" (confirm) call `start_solar_departure()`. The Archive terminal opens `Codex` plus news and the legacy log. Remove the HUD "New voyage" and "Visit Sgr A*" buttons and the N, L and C decision keys (N becomes the tour's skip dwell, inside the tour card only). Reserved consoles dark and "offline". | 140 | U3 | AC9, NT1 green |
| **U6** | **Migration.** Update the key-driven cases in `test_bh_hud`, `test_ship_demo_live`, `test_ship_demo_consolidation` and `test_tour_attitude`, and in the tools listed above, to call `ShipConsoles.use(...)` or the existing methods. Rewrite the Tab help text. Add the confirm-mode option to title Settings. Full `make test`. | 150 | U2, U4, U5 | AC4, AC5, AC12, AC13 |
| **U7** | **Renders.** `tools/ship_ui_capture.gd` and `make ship-ui-capture` → `renders/ship_ui/` (the 12 frames in AC14 at 1280×720 and 2560×1440) plus a contact sheet; the tool fails on a missing or uniform frame. Open and inspect every frame: strip legibility over a bright Auto sky, no card over the centre third, the prompt and focus pose framing the console, idle screens readable. | 150 | U6 | AC14 |
| **U8** | **Docs.** CHANGELOG; design-doc index row; a note in `m4.5s-inventory.md` on the `ShipConsoles.use` hook for M4.5's bot. | — | U7 | — |

**Total:** 2,330 LOC.

## Order and days

```
Day 1  U0 tests red (incl. the source-tagged intent and fake-clock seams)
Day 2  U4a map-host spike + window check; U1 strip starts
Day 3  U1 strip + card frame  ─┐
Day 4  U2 cards               │  U3 consoles (parallel with U1/U2; different files)
Day 5  U3 finish; U4 helm/chart
Day 6  U5 voyage + archive; U6 migration; make test green
Day 7  U7 renders + inspection; U8 docs; PR
```

Critical path: U0 → U4a → U3 → U4 → U6 → U7. U1 and U2 run beside U3, since they touch `ui/ship_hud.gd` and U3 touches `demos/ship_consoles.gd`. Both meet in `ship_geometry_demo.gd` at U5 and U6.

## Pause points

- **P0 (now):** Mark approves the plan and answers Q1–Q6. If Q1 = A, an attended session records the ruling and re-points M4.3b in the charter, so the unattended loop does not start M4.3b in parallel.
- **P1 (end of day 4, non-blocking):** the strip and card renders from U7's tool, run early on U1/U2, posted for a look. Execution continues.
- **P2 (before merge, blocking):** a dev review build (`make publish-dev`). Mark walks to the Voyage console and the navigation station and commits a voyage. His notes are fixed before landing.

## Tests and evidence per milestone

| Milestone | Test evidence | Renders to inspect |
|---|---|---|
| U0 | the three suites exist and fail for the documented reasons (logged) | — |
| U1 | `make ship-ui-test` AC1, 2, 7, 11 green; `make lint-precision` green | strip at rest and in cruise (P1) |
| U2 | AC3 green (one case per card row) | transit card, arrival card, gravity card (P1) |
| U3 | `make ship-console-test` AC6, 8, 14a green; path lengths logged | prompt at the navigation station; focus pose |
| U4a | `make ship-ui-window-check` (AC15) green in a GPU window | the chosen host over the console |
| U4 | AC9 (helm), AC10 green | helm panel; chart mode |
| U5 | AC9 (voyage, archive); `make no-twitch-test` green | Voyage console; Archive terminal |
| U6 | `make test` green; `make parity && make strict` green; `make no-twitch-test` twice with identical logs (AC13); `make lint-precision` with the allowlist row removed | — |
| U7 | `make ship-ui-capture` writes 24 PNGs and a contact sheet | all of AC14, opened and looked at |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| `GalaxyMap` cannot be embedded (its own 3D world, `force_native` window) | medium | Day-1 spike. Fallback: a borderless window positioned over the console rect; the console contract is unchanged. |
| A console use point is off the walk mesh | low–medium | AC8 at load. Nearest walkable within 2.5 m, otherwise a data override and an art note. |
| Test migration is larger than counted | medium | Methods are kept as action targets, so most tools are untouched; the budget is 150 LOC with buffer. |
| The loop starts M4.3b in parallel | low (needs Q1 recorded) | P0 records Q1 in the charter before execution starts. |
| New players miss the Voyage console | medium | Onboarding glow and hint, Tab Walk to, and P2 review with Mark. |
| A pacing control is challenged as a decision (Q3) | low | The NT1 allow-list is data (`ship_controls.gd`), so moving a row to `console` is a one-line change plus the station action. |

## Coordination

- **M4 loop (charter queue row 2):** see Q1. Under (A), M4.3b's 3D-ship deliverable = U2; M4.5's scene half starts after U6 and drives decisions through `ShipConsoles.use`. Under (B), this sprint skips U2 (left to the loop; about 2,070 LOC). Under every option, the M4.3b row's "shortcuts M, L and K" and M4.5's "bot through Godot's input layer" are amended in the same attended charter edit (design doc Q1), before the loop starts either. Under (C), add a later migration sprint.
- **`feat/free-nav-stops`, #171, #177:** merge first. U1 reuses `distances_text`; U4 makes Sol picking, Return to Sol and "In this system" helm-only.
- **Charter follow-up 7d(a)** (the `1.0 - beta` fallback) closes in U1.

## Plan review

Round 1, an independent Sonnet reviewer: **82/100 PASS, 0 blocking** (`.ailang/state/evaluations/eval_R1-SHIP-UI-plan_round_1.json`). All majors are fixed in this revision:

- **F1:** NT1 now separates player-sourced intents from tour-sourced ones.
- **F2:** there are no new warp keys.
- **F3:** the amendments to the M4.3b and M4.5 rows are named in Q1.
- **F4:** the estimate is 7 days, which gives a real 20% buffer.
- **F5:** the map-host spike is U4a, with a GPU-window check (AC15).

The minors are also fixed (F6–F9, F11, F12). F10, the confirm on cancel and leave, is kept by design.
