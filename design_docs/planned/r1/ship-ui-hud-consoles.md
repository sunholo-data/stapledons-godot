# Ship UI: the HUD informs, the bridge consoles decide (D-56)

**Status:** **Approved by Mark, attended 2026-10-09 (ledger D-57)**: as drafted; Q1 = A (this plan absorbs M4.3b's 3D-ship half); Q2 yes (M read-only chart); Q3 instant pacing; Q4 camera dolly to a framed panel; Q5 station layout yes; Q6 accessibility yes. Executes after the free-navigation PRs (#171, #182) merge.
**Release / milestone:** R1, ship UI (`R1-SHIP-UI`). Carries the 3D-ship half of M4.3b if Mark accepts Q1.
**Priority:** high. Every later UI (M4.3b, M4.5's scene half, M3, M6 crew decisions) lands on this framework.
**Implements:** ledger **D-56** (Mark, attended 2026-10-08; `design_docs/stapledon-mission.md`), with D-52 (the 3D painted ship is the playable), D-55 (Auto view is the player default), D-54 (stop distances), D-46 / D-49 (tour pacing, giant approach), D-38 (exposure views), D-12 (both clocks, same size, no pause). Mockups Mark reviewed: <https://claude.ai/artifact/8Ds2EL6oNhfeoZRqwcUpKg> (A: status strip and action bar; B: diegetic consoles; C: hybrid at Sgr A*). Design repo: `vision/core-pillars.md`; `art/ship-interior-blender-brief.md` §3 (the bridge is "the decision hub"), §6 (`INTERACT_` interactables); `features/next/bubble-ship-hud-view.md` (HUD shows galaxy time and ship time). Physics spec: no section changes. No SR or GR visual changes; the HUD shows sim values only.
**Depends on:** `demos/ship_geometry_demo.gd` (today's HUD, buttons and keys), `ui/journey_hud.gd` (M4.3a readouts), `ui/galaxy_map.gd`, `ui/arrival_card.gd`, `ui/interlude_card.gd`, `ui/ship_star_identification.gd` (the I card), `demos/black_hole_visit.gd`, `demos/solar_departure.gd`, `interior/walk.gd` (`WalkArea.path`, `nearest_interactable`), the console meshes already in `assets/ship_demo/ship.glb`. **Lands after** `feat/free-nav-stops` and PRs #171 and #177 (all three edit `ship_geometry_demo.gd`; see Coordination).
**Estimated LOC:** about 2,330 (GDScript 1,480, tests and seams 640, spike 60, capture tool 150). No sim, protocol or package change.

## Game vision alignment

Scored with the `game-vision-designer` skill against `stapledons-design/vision/core-pillars.md`.

| Pillar | Score | Reason |
|---|---:|---|
| Choices Are Final | **+2** | A commitment becomes a place and an act: walk to the navigation station, plot, hold to commit. The HUD can no longer start a voyage, an approach or a departure, so no stray key press commits the ship. The commit ritual (hold, "cannot be undone") is kept and gains an accessible confirm mode. |
| The Game Doesn't Judge | 0 | Readouts stay facts (both clocks, distance, gap). No scoring or advice is added. |
| Time Has Emotional Weight | **+2** | Ship clock and home clock are on screen at all times, the same size (D-12), in every scene: docked, in transit, on the tour and at Sgr A*. Today they show only on some HUD paths. Planning at the console spends host time, as D-12 intends. The read-only chart (Q2) does not pause the voyage. |
| The Ship Is Home | **+2** | Decisions happen in the ship, at its consoles, on the bridge the brief calls "the decision hub". The 3D bridge's existing navigation consoles, decision consoles and Archive terminal become the places where the game is played, instead of set dressing behind a button column. |
| Grounded Strangeness | +1 | Looking around stays fast and rich: the I card, a dwell label on what the captain is looking at, and GR readouts beside the hole. No display control is made harder (Mark's clarification). |
| We Are Not Built For This | +1 | Weighted, slow decisions; no reflex play (D-56: "no twitch gaming ever"). The captain is a person who walks to a console, not a cursor. |

**Net +8: aligned, go.** Tension to watch: walking adds seconds to each decision. That is intended weight, not friction. It is bounded by click-to-walk (§C3) and by M4.5's ten-minute proxy, which already budgets 20 s of walking per interactable.

## Problem

Today, `demos/ship_geometry_demo.gd` `_hud()` (lines 150–209) builds a column of HUD buttons that mixes three kinds of control:

- **Captain decisions as HUD buttons and keys:** "Navigation [M] · select destination and hold to commit"; "New voyage · Earth → … (real time)"; "Visit Sgr A* (black hole)"; and at Sgr A*, "Next stop [N]", "Leave Sgr A* [L]" and "Archive [C]". Any of these is one key away from anywhere on the ship, including from the lower deck.
- **Display controls** (V, J, the brightness grid, H, camera presets 1–4, R, 7/8/9) are mixed in with them.
- **Developer review controls** (B benchmark, the "Show local audit" button, sky snapshots 5/6, G guides) appear in player launches.

The always-on information is uneven. `hud_text()` shows the clocks at Sgr A* and on the live label, but the tour line, the rest snapshot and the docked state each format their own text. Distance appears only on some paths (PR #171 is fixing the stopped case). M4.3a's `JourneyHud` was built for the retired `--interior` scene and is not in the 3D ship (D-52 moved M4.3b here). The bridge geometry already holds 3 navigation consoles, 4 decision consoles, an Archive terminal and a captain's chair (`ship.glb` nodes `console_navigation_0..2`, `console_decision_0..3`, `archive_terminal`, `captain_chair`), and none of them can be used.

## Goals and non-goals

**Goals**
1. **HUD = information only.** Ship and home clocks and the distance are always shown. Contextual cards appear and fade as needed. Rich information appears while looking around. The HUD never sends a decision.
2. **Bridge consoles = every captain decision:** plot and commit a course, set cruise speed, cancel or re-plan, approach or leave a body or the black hole, start the guided voyage, and open the Archive.
3. **Instant display and information controls everywhere:** Auto/Realistic (V), brightness (J), I inspect, Tab help and details, camera views, sky-only, UI scale, main menu, and the read-only star chart (Q2).
4. **No twitch**, as testable constraints (§E).
5. **Migrate** every current control (§F), with tests that fail if a decision key returns.
6. **Absorb M4.3b's 3D-ship half** (journey readouts in the playable ship) if Mark accepts Q1.

**Non-goals**
- In-world interactive render-to-texture screens (Q4 recommends a camera dolly plus a framed panel; in-world screens are display only).
- New art. The consoles exist in `ship.glb`; positions are read from its node names. A later art pass may add `INTERACT_` empties.
- Crew decisions (M6) and the M3 black-hole flow beyond today's Sgr A* demo. `console_decision_1..3` are reserved for them (dark, labelled "offline").
- The title screen's routes (Board the ship, Guided voyage, Galaxy map) are pre-game mode choices, not captain decisions, and are unchanged. The standalone "Galaxy map" route stays the M2 reference map.
- Any sim, protocol or package change. Consoles send the same intents the buttons send today, so replay and parity are unchanged.

## Design

### A. The HUD information model

One component, `ui/ship_hud.gd` (`ShipHud`), replaces `hud_text()` and the button column. Every number in it is a `DisplayBinding` on a sim field (M4.5's display audit rule), and every caption is digit-free.

**A1. Always shown (the status strip, top centre, mockup A/C style).** In every scene state (docked at rest, live journey in any phase, guided tour including dwell and interlude, Sgr A*, and walking on the lower deck):

| Slot | Content | Source |
|---|---|---|
| Ship clock | `Ship +…` (adaptive units: d / yr) | `clock.tau` |
| Home clock | `Earth +…` (at Sgr A*: "home (far-away) +…"), same size as the ship clock (D-12) | `clock.year` / `clock.t` |
| Distance | Committed: `To <target> <d>`. Stopped: `At <body> <d>` plus `from Earth <d>`. At Sgr A*: `r = … r_s` | `consequence.distance_remaining`; the free-nav-stops `distances_text`; `gr.r` |
| Where / phase | `Earth orbit · at rest`, `→ α Cen · CRUISE`, `Sgr A* · hovering` | `ship.phase`, tour leg, BH stop |
| Speed (while moving only) | `β … c · γ …` | `ship.beta`, `ship.gamma`, `ship.one_minus_beta` (never computed in GDScript; this drops the `1.0 - beta` fallback, charter row 7d(a)) |
| View tag | `AUTO` / `REALISTIC` (one word; details in Tab) | `sky.system_view.body_fader` |

The strip never fades, is never covered by a card, and stays visible inside the read-only chart and in console focus (the panel docks below it).

**A2. Contextual cards (right column, a stack of at most two, by priority).** Each card fades in over 0.4 s and out over 0.6 s. No card sits over the centre third of the screen. No card takes a decision, and none has a timer that changes game state.

| Card | Appears | Leaves | Content |
|---|---|---|---|
| Transit (M4.3b) | journey committed | arrival | phase, gap, distance left, arrives-in (Earth-yr), ISM load (W/m² and suns), drag energy, glow on/off, warp (M4.3a `JourneyHud.ROWS`, compact; all rows in Tab) |
| Brake / approach notice | brake phase entry; final approach start (D-46, D-49) | 8 s, or the next notice | "Braking. Up is still the way we are travelling." / "Final approach to <body>" |
| Arrival | `arrived` event | dismissed (Enter / click / Esc), or the next commit | M4.3a arrival card: distance, ship-yr, Earth-yr, gap |
| Cruise interlude (D-41) | tour interlude active | interlude ends or Continue | `InterludeCard` (unchanged) |
| Gravity (mockup C) | Sgr A* session | leaving | `BlackHoleVisit.hud_lines`: r/r_s, time ratio, shadow half-angle, blueshift, tide, hover thrust note, sky caption |
| Tour | guided tour | tour ends | leg, stage, dwell left, PAUSED |
| Archive unlock | `consequence.archive.unlocked` grows (the codex's unlock toast, moved into the stack) | 10 s | "New in the Archive: <title>, at the Archive terminal" |
| Refusal / caption | a console refuses (e.g. "Finish the committed journey first") | 8 s | the reason, verbatim |
| I card | I + click (unchanged) | Close / Esc | `ShipStarIdentification` card; its "Open in map" opens the read-only chart |

Priority (high to low): I card, arrival, refusal, gravity, transit, tour, interlude, notices, unlock. Lower cards collapse to a one-line chip and are never dropped.

**A3. Rich information while looking around.**
- **Dwell label:** when the screen centre (or the mouse in free-look) rests on a known star or resolved body for 0.5 s, its name and distance show beside it, with "I · details". It uses the existing `ShipStarIdentification` pick, read-only. It can be toggled in the Tab display panel (default on).
- **Console proximity prompt (bottom centre):** within 2.5 m of a console and facing it (±60°): "<Station> · E use". From farther away, aiming at a console shows "<Station> · click to walk there".
- **Tab (details and help):** today's `details` block (deck, eye height, view and travel angle, exposure line, star-light line), the full transit rows, the control list grouped as in §F, and "Walk to: Navigation · Voyage · Archive" (§C3).

### B. The consoles

Positions are the `ship.glb` node origins in the play frame (glTF metres, bridge deck y = 82; captain spawn (8, −4.8); spire at the origin).

| Station | Meshes (x, z) | Decisions worked here | In-world idle screen (display only) |
|---|---|---|---|
| **Navigation station** (the helm) | `console_navigation_0..2`: (−9.40, 3.42), (−7.07, 7.07), (−3.42, 9.40), an arc 10 m from the spire; any of the three opens it | plot a course: catalogue star, Sol / Return to Sol, "In this system" bodies (free-nav-stops), Sgr A* (demo); set cruise speed (slider); **commit** (hold); cancel or re-plan in transit; at Sgr A*: approach to the next stop, leave Sgr A* | target, ETA in both clocks, or "No course set" |
| **Voyage console** | `console_decision_0` (−8, −2) | start the guided voyage (Earth → … → Aldebaran, D-46/47/49); the itinerary is shown before the start | "Guided voyage ready" / the current leg |
| **Archive terminal** | `archive_terminal` (−3.03, 2.12), against the spire | open the Archive: codex (M4.7), news and legacy log (M4.4) | count of new entries |
| Reserved | `console_decision_1..3` (−10.5, −6.5), (−13.2, 3), (−12, 9.5) | none in R1 (M6 crew decisions) | dark, "offline" |
| Captain's chair | `captain_chair` (1.88, 5.17) | none (a camera seat, Tab, later) | none |

**Why one navigation station for every "where the ship goes" decision:** it is one place to learn, and approach and leave are course changes. The Voyage console is separate because D-56 lists it, it is the new player's first decision, and its glow is the onboarding cue (§C5).

### C. Console interaction

**C1. Approach.** Walk (WASD) or click a console in view to auto-walk there (§C3). The prompt appears in reach.

**C2. Use (E, or click the console in reach).** The camera dollies over 0.6 s from the captain's eye to a fixed focus pose in front of the console screen, and the station's panel opens framed by the console. The panel is an overlay aligned to the screen rect, at the player's UI scale, so it stays readable and accessible (Q4). The status strip stays on top. Walking is suspended while the panel is focused. Display keys (V, J, I, H, Tab, Esc) still work.

- Navigation: `GalaxyMap` in **helm mode** (§D), embedded in the panel instead of today's native `Window`.
- Voyage: the itinerary list, then "Begin guided voyage" (confirm, §C4).
- Archive: the existing `Codex` panel plus the news and legacy log entries.
- At Sgr A*, the navigation panel shows the hole's stop ladder (10⁶ → 10, 5, 3 r_s, orbit) with "Approach to <next>" and "Leave Sgr A*".

**C3. Click-to-walk and "Walk to…".** Clicking a console mesh, or choosing it in Tab's "Walk to" list (keyboard reachable), walks the captain along `WalkArea.path` to the console's use point at 3.5 m/s. This is the same speed as WASD, so walking keeps its weight and accessibility does not depend on steering. Any WASD input cancels the auto-walk. Use point rule: `WalkArea.closest_walkable(console origin, 2.5)` (the `max_r` argument set to 2.5 m, not the default 6 m), so the captain stands within 2.5 m of the console. A load-time test asserts every active station has a use point within 2.5 m and a non-empty `path` from the bridge spawn, and prints each walked path length. The straight-line spawn distances are 18–22 m; the walked length is longer, is recorded, and has a 40 m ceiling.

**C4. Confirm.** Irreversible decisions (commit, begin guided voyage, leave Sgr A*, cancel a transit) use a confirm step. The default is today's hold (1.5 s, `GalaxyMap.HOLD_S`; releasing restarts it with no penalty). An accessibility setting (title screen Settings, and the Tab display panel) switches every confirm to **press twice** (press, the button relabels "Confirm: <action>", press again; Esc backs out). Neither form has a deadline. Reversible choices (select a star, move the slider, open a codex entry) are a single click.

**C5. Leave.** E, Esc, or a "Step back" button: the camera dollies back to the captain's eye. A panel never closes on a timer.
**Onboarding:** on a menu-launched ship, until the player first uses a console, the Voyage console and the navigation station glow softly (an emissive pulse on the existing meshes; a display cue, not a timer), and the HUD shows one dismissible hint: "Decisions are made at the bridge consoles: the Voyage console begins the guided voyage, the navigation station plots a course. Tab · Walk to."

**C6. Lower deck.** Consoles exist on the bridge only (the shipped geometry). From the lower deck, decisions need the lift (E at the landing), and the HUD prompt says so. Information and display controls work everywhere.

### D. The navigation map: chart mode and helm mode

`GalaxyMap` gains `mode := "chart" | "helm"` (it already has `guided_read_only`).

- **Chart mode (M, anywhere, instant: information).** Browse, select, centre, fit, read the stats panel, and the plan preview's consequence rows (time cost, gap). No speed slider. No Commit, Cancel, Return to Sol, "In this system" or Sgr A* entry. A banner reads "Plot and commit at the navigation station · Walk there". The voyage is **not** paused, because the chart is not a decision. Today, M pauses the tour, which pillar 3 and D-12 exclude. I-card "Open in map" opens chart mode framed on the star.
- **Helm mode (navigation station only):** today's full map plus free-nav-stops' Sol pick, Return to Sol and "In this system" list, plus the Sgr A* entry. The commit dialog and its confirm (§C4) are unchanged. A selection made in chart mode carries over to the helm, so browsing is never wasted.

### E. No twitch: testable constraints

| # | Constraint | How it is checked |
|---|---|---|
| NT1 | **No player decision by key.** With no console focused, no key, mouse button or HUD element sends a **player-originated** decision intent (plan, commit or cancel with a player-chosen target or speed, approach, leave) or starts a session. **Tour-owned** intents are separate: once the captain begins the guided voyage at the Voyage console, the itinerary plans and commits each leg itself (`SolarDeparture.prepare_next` / `commit_prepared`). Tour pacing (N skip dwell, K skip stage) may bring the next itinerary leg forward, but its target and speed are fixed by the itinerary, never by the key. | `tests/test_no_twitch.gd`: sweeps every physical key A–Z, 0–9, F1–F12, Enter, Space, Tab, Esc, arrows, the mouse buttons and the pan gesture, aboard at rest, in transit, on the tour and at Sgr A*. The `SimBridge` record seam tags each sent intent with its source (`player`, `tour`, `tick`). The test asserts that no `player` plan, commit, cancel or approach intent is sent; that every `tour` intent's target equals the itinerary's next leg; that free-navigation `journey.state` and plan are unchanged; and that `black_hole` and `solar_tour` are not created or dropped. Title-screen routes (Guided voyage, Sgr A* via `--scenario`) are pre-game mode choices outside the aboard sweep. |
| NT2 | **No deadlines.** No decision panel, confirm or card changes game state on a timer. An open commit dialog, an open console panel and an unanswered confirm survive 600 s of fake time unchanged (the sim keeps its normal host tick, D-12). | the same test, with a fake clock |
| NT3 | **No timing skill.** The only hold is the 1.5 s confirm. Its release restarts it with no penalty, and the press-twice mode commits with two presses separated by any interval ≥ 0 frames. | `tests/test_ship_consoles.gd` |
| NT4 | **Outcome independent of reaction time.** A commit made 1 s or 60 s after opening the helm sends the same plan intent; only the host clock differs. | same, comparing intent payloads |
| NT5 | **Every decision lives at a console.** `ui/ship_controls.gd` holds the control table (§F) as data. Every key matched in `ship_geometry_demo.gd _unhandled_input` is in it, and none has kind `console`. Every `console` row maps to a station action. | `tests/test_ship_ui.gd` (table ↔ code parity, both directions) |

### F. Migration of today's controls

Kinds: **HUD** = information shown; **display** = instant display/info control; **pacing** = instant real-time pacing that changes no outcome (Q3); **camera** / **move** = instant; **console** = decision, console only; **dev** = developer launch only (hidden from menu launches, still reachable on command-line launches and by tools).

| Today | Where today | Becomes | Kind |
|---|---|---|---|
| Live label (`hud_text`, `journey_label`) | HUD text | status strip + cards (§A) | HUD |
| Navigation [M] button / M | HUD, key | M = read-only **chart**; plotting and commit at the navigation station | display + console |
| "New voyage · Earth → …" button | HUD | Voyage console "Begin guided voyage" | console |
| "Visit Sgr A* (black hole)" button; map "Sgr A* · demo" | HUD; map window | navigation station, helm mode entry | console |
| Next stop [N] (Sgr A*) | HUD, key | navigation station "Approach to <next>" | console |
| Leave Sgr A* [L] | HUD, key | navigation station "Leave Sgr A*" (confirm) | console |
| Archive [C] | HUD, key | Archive terminal; unlocks announced as a card | console |
| Commit… / Hold to commit / Cancel / slider / Return to Sol / In this system | map window | helm mode only | console |
| Finish approach [K] (Sgr A*) | HUD, key | K, unchanged (skips the approach; the sim lands exactly) | pacing |
| Skip stage [K] (tour) | HUD, key | K, unchanged; also a button in the tour card | pacing |
| Pause tour / Resume tour | HUD | P (new) and a button in the tour card | pacing |
| Next stop (tour, skips a dwell) | HUD | the tour card's "Skip dwell" (N) | pacing |
| Warp level (M4.3a `client.warp`) | `--interior` transit harness only (1–3); no warp control exists in the 3D ship | shown on the transit card only; no new warp control in this sprint (Q3 notes the edge: D-56 lists "set speed", which is cruise speed at the helm, while time warp is pacing) | HUD |
| Continue (interlude) / Enter | card, key | unchanged | display |
| View [V] Auto/Realistic | key, Tab panel | unchanged; also the strip's view tag (click toggles) | display |
| Brightness J and the 8-button grid | key, Tab panel | unchanged (Tab display panel) | display |
| I + click, I card, Open in map | key, card | unchanged; Open in map → chart mode | display |
| Tab Controls | key, button | Tab = help and details panel (§A3) | display |
| H Sky only | key, Tab | unchanged | display |
| ⌘/Ctrl +/−/0 UI scale | key | unchanged | display |
| Esc | key | close the top panel or card; otherwise the main menu (menu launch) or quit (command line) | display |
| Main menu button | HUD | unchanged (strip corner) | display |
| 1–4 camera presets, R reset, 7/8/9 look, drag-look, scroll zoom | key, Tab | unchanged | camera |
| WASD, E lift | key | unchanged; E also uses a console in reach. **E priority:** the nearest interactable in reach and facing wins (`WalkArea.nearest_interactable` semantics; the lift landing is one interactable among the stations), and the prompt always names which one E will use | move |
| Pan gesture (trackpad) zoom | gesture | unchanged | camera |
| Map window keys: M / Esc close, ⌘/Ctrl +/− | map window | chart: M / Esc close, +/− zoom; helm: E / Esc steps back from the console, +/− zoom | display |
| 5/6 sky snapshots, G guides, B benchmark, Show local audit, public audit link | key, Tab | developer launches only | dev |

### G. M4.3b, M4.5 and concurrent work

- **M4.3b** (`sprint_R1-M4-JOURNEY.json`, `M4.3b_HUD_IN_INTERIOR`, 70 LOC, art-gated, written for `--interior`) is waiting for a D-52(A) re-plan against the 3D ship. Its substance is the M4.3a readouts, the arrival card and the starbow orientation, live in the playable ship. Under Q1(A), this plan's U2 delivers the readouts and the arrival card. The orientation invariant (forward pole faces the heading in all three phases) is already true of the 3D ship's sky (`InteriorSky`), and G-M4-3 stays with M4.6's gated half. M4.3b's sprint row is then re-pointed to `R1-SHIP-UI` U2 as its deliverable. That change is a charter and ledger edit, made by Mark or an attended session, not by this plan.
- **M4.5's scene half** builds on this plan: its playthrough bot reaches decisions through `ShipConsoles.use(station, action)`, the same entry the player's E press calls, and walks with `WalkArea.path`. Its ten-minute proxy already counts 20 s of walking per interactable. Its display audit reads `ShipHud`'s bindings.
- **`feat/free-nav-stops`** (in progress) adds Sol picking, Return to Sol, the "In this system" list and the stop distance text. U4 makes those helm-only, and U1 reuses `distances_text` for the strip. This plan starts after that branch, #171 and #177 merge. The conflicts are concrete. Free-nav-stops changes `distances_text`'s signature (it adds `names` and `from_name`), `journey_label` and the stop line in `ship_geometry_demo.gd`, and adds `home_button` and the in-system list to `galaxy_map.gd`'s `_build`. #171 edits the same HUD distance path. #177 edits `set_auto_view` and the title view option. U1 and U4 rewrite exactly those functions.

## Acceptance criteria

Each row is a command. `make ship-ui-test`, `make ship-console-test` and `make no-twitch-test` join `ship-demo-ci`, so they run in `make test`. `make ship-ui-window-check` and `make ship-ui-capture` need a GPU window, like `make golden`.

| # | Criterion | Command |
|---|---|---|
| 1 | The strip shows ship clock, home clock and distance in every scene state (rest, boost, cruise, brake, arrived, tour dwell, interlude, Sgr A*, lower deck); each number equals the sim field formatted (DisplayBinding); captions are digit-free | `make ship-ui-test` |
| 2 | Clocks are the same font size (D-12); speed shows only while moving, from `ship.one_minus_beta`, which the sim emits in every phase (asserted per state); the fallback and its row in `tests/fixtures/lint_precision/allowlist.txt` are removed (`grep -n "1.0 - beta" demos/ship_geometry_demo.gd ui/ship_hud.gd tests/fixtures/lint_precision/allowlist.txt` is empty) | `make ship-ui-test && make lint-precision` |
| 3 | Contextual cards appear and leave on their triggers (§A2 table, one case per row); at most two expanded; none overlaps the centre third at 1280×720 or 2560×1440 | `make ship-ui-test` |
| 4 | NT1: the key/mouse sweep sends no decision intent and starts no session in any of the four states | `make no-twitch-test` |
| 5 | NT2: dialog, panel and confirm survive 600 s of fake time unchanged | `make no-twitch-test` |
| 6 | NT3/NT4: hold and press-twice confirms; release restarts with no penalty; the intent payload is independent of delay | `make ship-console-test` |
| 7 | NT5: the control table and `_unhandled_input` match both ways; no `console` kind on a key; every `console` row has a station action | `make ship-ui-test` |
| 8 | All four stations (navigation, voyage, archive, reserved) load from `ship.glb` node names; every active one has a non-empty `WalkArea.path` from the bridge spawn; the prompt shows in reach and facing, not otherwise | `make ship-console-test` |
| 9 | Using each station opens its panel; helm commit sends the same intent as today's map commit; voyage start equals `start_solar_departure()`; Sgr A* approach and leave equal `bh_next_stop()` / `leave_black_hole()`; Archive opens the codex | `make ship-console-test` |
| 10 | Chart mode (M) has no slider, commit, cancel, Return to Sol, in-system list or Sgr A* entry, does not pause the tour, and hands its selection to the helm | `make ship-console-test` |
| 11 | Developer controls (B, G, 5, 6, the audit buttons) are absent on a menu launch and present on a command-line launch | `make ship-ui-test` |
| 12 | Existing suites still pass after migration (tests that sent N/L/C/M keys now call station actions) | `make test` |
| 13 | Replay and parity unchanged (no sim or protocol change). The new tests are deterministic: fixed seed, fake clock (a `now()` seam in `ShipHud`, `ShipConsoles` and the confirm), no wall-clock reads; two runs give identical logs | `make parity && make strict && make no-twitch-test && make no-twitch-test` |
| 14a | The Tab "Walk to" list is keyboard reachable (focus, arrows, Enter) and walks to each station; on the lower deck the prompt says decisions need the bridge (lift) | `make ship-console-test` |
| 14 | Renders, opened and looked at: strip at rest; transit card in cruise; arrival card; prompt at the navigation station; helm panel focused; chart mode; Voyage console; Archive terminal; Sgr A* gravity card; tour interlude; lower deck; 1280×720 and 2560×1440 | `make ship-ui-capture` → `renders/ship_ui/*.png` + contact sheet; the tool fails on a missing or uniform frame (per-frame luminance standard deviation above a floor) |
| 15 | The navigation station's chosen map host (embedded panel or borderless window) opens, takes a click selection and a hold commit in a real GPU window | `make ship-ui-window-check` (GPU window, like `make golden`) |

## Sub-milestones and estimates

| ID | Work | LOC | Depends |
|---|---|---:|---|
| U0 | Tests first: `test_ship_ui.gd`, `test_ship_consoles.gd`, `test_no_twitch.gd` (red), `ui/ship_controls.gd` table, the `SimBridge` source-tagged record seam and the fake-clock seam, Makefile targets | 640 | free-nav-stops, #171, #177 merged |
| U1 | `ui/ship_hud.gd`: status strip, card stack, prompt line, Tab panel; `hud_text` retired; dev controls gated | 330 | U0 |
| U2 | Contextual cards: transit (M4.3a rows), notices, arrival, gravity, tour, unlock, refusal; dwell label (M4.3b's 3D half) | 260 | U1 |
| U3 | `demos/ship_consoles.gd`: stations from GLB, use points, prompt, E/click use, dolly focus, click-to-walk and Walk to, confirm modes, idle screens, onboarding glow | 380 | U0 |
| U4a | Spike: embed `GalaxyMap` vs borderless window; `make ship-ui-window-check` | 60 | U0 |
| U4 | Navigation station: `GalaxyMap` chart/helm modes, the chosen host, M = chart, Sgr A* ladder | 220 | U3, U4a |
| U5 | Voyage console and Archive terminal; remove the decision buttons and keys (N, L, C, tour start, Sgr A* start) | 140 | U3 |
| U6 | Migrate tests and tools that sent decision keys; Tab help text; title Settings confirm-mode option | 150 | U2, U4, U5 |
| U7 | `tools/ship_ui_capture.gd`, `make ship-ui-capture`, contact sheet; inspect renders | 150 | U6 |
| U8 | CHANGELOG, design-doc index, M4.5 hook note | docs | U7 |

Total about 2,330 including tests. See the sprint plan for order and pause points.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A console's use point is not on the `WALK_` surface (the walk mesh was not authored with consoles in mind) | AC8 checks it at load. If one fails, use the nearest walkable point within 2.5 m; if none exists, file an art note and place the use point by data (`consoles.json` override). |
| Embedding `GalaxyMap` (today a native `Window`, `force_native`, `own_world_3d`, its own `window_input`) in a panel breaks its camera or input | A separate spike (U4a) before U4 decides embed vs a borderless window over the console rect; the console contract (`use` / `leave`) does not change. Headless tests never show the window, so AC15 checks the chosen path in a real GPU window. |
| Moving the guided-voyage start off the HUD loses new players | Onboarding glow, hint, and Tab "Walk to". The title's Guided voyage route still starts the tour directly (a mode choice). Mark reviews the dev build at pause P2. |
| Three in-flight branches edit `ship_geometry_demo.gd` | Start after they merge (U0 dependency). U1 moves HUD code out of the 844-line demo into `ui/ship_hud.gd`, which shrinks the conflict surface for M4.5. |
| Walking makes the M4.5 ten-minute budget tight | Click-to-walk at 3.5 m/s. The farthest console is about 22 m from spawn in a straight line; the walked path is measured in AC8 with a 40 m (11 s) ceiling, inside M4.5's 20 s per interactable. |
| Pacing keys read as decisions (Q3) | They are listed in the NT1 allow-list by intent kind; Mark rules in Q3. |

## Open questions for Mark

| # | Question | Recommendation |
|---|---|---|
| Q1 | **How do this plan and M4.3b fit?** (A) This plan absorbs M4.3b's 3D-ship half (U2); the charter's queue row 2 re-points M4.3b to `R1-SHIP-UI` U2, and the loop does not build a journey HUD; M4.5's scene half follows this plan. (B) This plan builds only the framework (U0, U1, U3); the loop's M4.3b fills the cards. (C) The loop builds M4.3b now in today's HUD, and this plan migrates it later. | **A.** One HUD component, one owner, no rework. (B) splits a 260-LOC card set across two agents editing the same file. (C) builds a HUD that D-56 already retires. It needs a ledger row and charter edit (attended) so the unattended loop stops treating M4.3b as its next item. **Consequences under any option:** two approved rows conflict with D-56 as written and must be amended in that attended edit, *before* the loop starts M4.3b or M4.5's scene half. They are M4.3b "shortcuts M, L and K keep the minimum path independent of pathing" (L is removed and M becomes read-only; the minimum path becomes `ShipConsoles.use` plus click-to-walk) and M4.5 "Scripted playthrough bot (tests/playthrough_min.json through Godot's input layer…)" (the bot reaches decisions by walking to a console and pressing E, through the input layer; the 20 s per interactable budget already covers it). |
| Q2 | Should **M stay as an instant, read-only star chart** (browse, inspect, preview consequences; no commit, no pause), with plotting and commit only at the navigation station? | **Yes.** "Get info etc., don't make that hard." The chart is information, and the decision stays at the console. |
| Q3 | Are the **pacing controls** (tour Pause/Resume, Skip dwell, Skip stage K, Sgr A* Finish approach K, transit warp level) instant controls, or console decisions? | **Instant.** They change how fast you watch, not where the ship goes or what the voyage costs in either clock (the sim is stepped exactly to the same boundaries; skip dwell brings forward the itinerary's own next leg). Edge case: the M4.3a time-warp level is pacing too, but no warp control exists in the 3D ship, so this sprint only shows it; cruise speed (the helm slider) is a console decision. |
| Q4 | **Console presentation:** a camera dolly to the console with a framed panel at the player's UI scale (in-world screens show live status only), or fully in-world interactive screens? | **The dolly.** It reads as diegetic, stays readable and accessible, and avoids render-to-texture input work. It can be revisited after a review build. |
| Q5 | **Station layout:** one navigation station for every "where the ship goes" decision (plot, commit, cancel, approach, leave, Sgr A*), the Voyage console for the guided voyage, the Archive terminal for the Archive, and `console_decision_1..3` dark and reserved for M6 crew decisions? | **Yes.** One place to learn per kind of decision, using the consoles the geometry already has. |
| Q6 | **Accessibility:** a "press twice to confirm" setting as an alternative to hold-to-commit, plus click-to-walk and a keyboard "Walk to" list? | **Yes to all three.** None removes a decision's weight, and all three remove a physical-dexterity barrier. |

## Deliverables

- `ui/ship_hud.gd`, `ui/ship_controls.gd`, `demos/ship_consoles.gd`; edits to `demos/ship_geometry_demo.gd`, `ui/galaxy_map.gd`, `ui/title_screen.gd` (confirm-mode setting), `ui/game_settings.gd`.
- `tests/test_ship_ui.gd`, `tests/test_ship_consoles.gd`, `tests/test_no_twitch.gd`; Makefile targets `ship-ui-test`, `ship-console-test`, `no-twitch-test` (in `ship-demo-ci`), `ship-ui-capture`.
- `tools/ship_ui_capture.gd`, `renders/ship_ui/` (inspected).
- CHANGELOG entry; design-doc index row; on landing, this doc moves to `design_docs/implemented/r1/`.

## Execution notes (decisions made while building, for Mark)

Choices the design left open, taken as the option most consistent with D-56 / D-57:

1. **Staging.** Three stacked PRs. Between PR 1 and PR 2 the voyage decisions (navigation map, Begin guided voyage, Visit Sgr A*, and N / L / C at Sgr A*) sit in the Tab panel under "Decisions (move to the bridge consoles)", not on the HUD; PR 2 moves them to the consoles and removes the keys.
2. **The cruise interlude card** (D-41) keeps its content and look but sits in the space left of the card column (it was centred, 620 wide, and covered the column). It still covers the centre of the screen: it is the designed "moment of scale", and the tour and transit cards stay readable beside it. The stack carries an "interlude" chip while it shows.
3. **Session-scoped cards.** When the sim session changes (navigation, the guided voyage, Sgr A*), the arrival, refusal and unlock cards of the old session go, and the new session's opening unlocks are not announced (only growth is news).
4. **Review snapshots** (the rest / cruise sky snapshots, developer-only, and the rest state after leaving Sgr A*) show where the ship is ("from Earth …"), not the snapshot's frozen plan.
5. **Speed digits** are formatted from `ship.beta` itself; the number of nines comes from `ship.one_minus_beta`. Nothing computes 1 − β.
6. **Warp** on the transit card is the live pacing rate (ship-years per real second), shown only.
