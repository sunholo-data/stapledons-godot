# Title screen and launch menu

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | A launcher; no change to commitments. Quitting mid-voyage is unchanged. |
| The Game Doesn't Judge | +1 | Credits name every dataset and paper the simulation cites, read from the sim's own citation lists; the view setting says what Realistic and Auto do. |
| Time Has Emotional Weight | 0 | No change. |
| The Ship Is Home | +1 | "Board the ship" is the first thing offered; Esc aboard comes home to the menu instead of killing the app. |
| Grounded Strangeness | +1 | The first screen is the real sky: the NOIRLab panorama and the catalogue stars, rendered by the game's own sky stack, not a painting. |
| We Are Not Built For This | 0 | No change. |

Net +3: aligned, go.

**Status:** Requested by Mark 2026-10-08 (charter queue row 5b: "Main menu / title screen ... I guess we need some kind of menu eventually"). PR `feat/title-screen`.
**Release:** R1.
**Implements:** charter queue row 5b (`design_docs/stapledon-mission.md`); D-52 (the 3D ship is the playable) for the default button; D-38 (Realistic / Auto view) and D-8 (text-only AI) as settings; the NOIRLab CC BY 4.0 attribution requirement (M5.2a, L-tex). No physics: the sky is the existing `InteriorSky` at rest.
**Depends on:** `InteriorSky`, `demos/ship_geometry_demo.gd` (`start_solar_departure`), the standalone galaxy map (`main.gd _run_map`), `AiSettings`.
**Estimated LOC:** about 650 (screen 330, settings 55, wiring 90, test 230, capture 40).

## Problem

A double-click on the review build opens straight into the 3D ship (D-52). There is no way to choose the guided tour, the galaxy map, the settings or the credits without knowing command-line flags, and Esc quits the whole app.

## Goals and non-goals

Goals:
1. A plain launch (no user args) opens a title screen over the real rendered sky: title, tagline, buttons **Board the ship**, **Guided voyage**, **Galaxy map**, **Settings**, **Credits**, **Quit**; the build id and "dev build".
2. Mouse and keyboard: Up/Down (wrapping), Enter, Esc closes panels, PageUp/PageDown scroll the credits.
3. Every command-line mode (`--ship-demo`, `--voyage`, `--interior`, `--map`, `--capture`, goldens, benches, movies, every smoke) behaves exactly as before.
4. Esc (and a HUD button) returns to the menu from a ship or map opened from it. Command-line launches keep Esc = quit.
5. Settings persist: the ship view in `user://settings.cfg`; text-only in the existing `user://ai_settings.cfg` (AiSettings' own field, the file the AI session reads).
6. Credits gathered from the repo: `Credits.PLANET_LINE` (checked against `data/planets/CREDITS`), the NOIRLab, CNS5, Gaia, Hipparcos, NASA Exoplanet Archive lines of `website/docs/credits.md`, and every reference in the `*itations()` lists of `sim/data/*.ail`, parsed at runtime so they cannot drift.

Non-goals: new game / continue (there is no save system yet), the sky flight (`--voyage`, a developer reference mode) and the interior reference as menu entries, key rebinding, audio, new art.

## Design

- `ui/title_screen.gd` (`TitleScreen`): builds an `InteriorSky` at rest (camera 20° left of the galactic centre, NGP up, fixed exposure 4 stops over the dark-sky reference, a 0.6°/s pan), a left gradient for legibility, the menu column, the settings and credits panels and a footer (build id; the CC BY sky credit wherever the panorama is shown). It only emits `chosen(route)`.
- `ui/game_settings.gd` (`GameSettings`): view + text-only; corrupt or missing files give defaults; failed saves return false.
- `main.gd`: `launch_route(args)` is `"title"` for no args, `"ship"` for the current-ship flags, `"reference"` otherwise. The title routes: ship = today's `_start_current_ship(true)` plus `{from_menu, auto_view}`; guided = the ship at rest, then `start_solar_departure()`; map = `_run_map({})` with an "Esc main menu" hint; quit.
- `demos/ship_geometry_demo.gd`: `from_menu` makes Esc and a "Main menu [Esc]" HUD button call `return_to_menu()` (`change_scene_to_file("res://main.tscn")`; `_exit_tree` stops the voyage's sim). Without it, Esc still quits.
- Build id: `make export-macos` writes `runtime/build_version.txt` (`git describe`), bundled under `runtime/*`; a source checkout says so. The title font (Montserrat Bold, OFL) is read as data and added to the export include filter with its licence.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| 1 | Plain launch shows the menu; every CLI mode bypasses it; current-ship contract unchanged | `make title-screen-test` (in `make test` via `ship-demo-ci`) |
| 2 | Each button routes: ship (live rest, captain eye), guided (tour running), map (standalone map), settings/credits panels, quit; Esc/HUD button return to the menu | `make title-screen-test` |
| 3 | Keyboard: initial focus, Down, wrap, Esc closes panels, PageDown scrolls credits | `make title-screen-test` |
| 4 | Settings round-trip; AI tick and ceiling preserved; corrupt/unwritable files safe | `make title-screen-test` |
| 5 | Credits contain the required attributions and ≥ 25 references from `sim/data/*.ail`, no assumptions | `make title-screen-test` |
| 6 | Existing entry points unchanged | `make ship-demo-consolidation-test ship-demo-launch-test` and the full `make test` |
| 7 | Exported app: plain launch shows the title over the bundled sky with a real build id; `--ship-demo` still starts the ship | `make export-macos title-export-smoke current-ship-export-smoke` |
| 8 | Reference renders at 1280×720, opened and looked at | `make title-capture` → `renders/title_screen/{title,settings,credits}.png` |

## Risks and mitigations

- A tool launches the app with no args and expects the ship: only `current-ship-export-smoke` did; it now passes `-- --ship-demo`, and `title-export-smoke` covers the plain launch.
- Esc conflict: Esc already reached the ship's handler only when no overlay consumed it (star card, credits, navigation window); the menu takes exactly that case and only when launched from the menu.

## Open questions for Mark

1. Should the sky flight (`--voyage`) or the interior reference get menu entries, or stay developer flags?
2. New game / Continue needs a save system: which milestone?
3. Title exposure is a 4-stop display aid so the Milky Way reads; keep it, or show the calibrated reference sky?

## Deliverables

`ui/title_screen.gd`, `ui/game_settings.gd`, `main.gd` routing, the ship's menu return, `tests/test_title_screen.gd`, `tools/title_screen_capture.gd`, Makefile targets `title-screen-test`, `title-capture`, `title-export-smoke`, renders in `renders/title_screen/`.
