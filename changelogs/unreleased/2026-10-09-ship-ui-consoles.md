### Added

- **The bridge consoles decide** (sprint R1-SHIP-UI, U3–U5; D-56, D-57 Q2–Q6). `demos/ship_consoles.gd` (`ShipConsoles`) reads the stations from `ship.glb` node names: the **navigation station** (`console_navigation_0..2`), the **Voyage console** (`console_decision_0`), the **Archive terminal** (`archive_terminal`), and three reserved crew consoles (`console_decision_1..3`, dark and "offline", kept for M6).
  - Walk there (WASD), click a console to walk to it, or use Tab's keyboard **Walk to** list. All three move at 3.5 m/s along `WalkArea.path`, and WASD takes over. The walked paths from the bridge spawn are 15–20 m.
  - The prompt names what **E** will use: the nearest interactable in reach (2.5 m) and facing (60°), with the lift as one of them. On the lower deck it says decisions need the bridge.
  - **E** or a click uses a console. The camera dollies over 0.6 s to a framed panel (D-57 Q4). **E** or **Esc** steps back.
  - Each console carries a live idle screen (display only), for example "Course plotted · commit here", "Guided voyage ready" or "Archive · 3 entries open".
  - On a title-screen launch the Voyage console and the navigation station glow and a hint shows. Both stay until the first console use.
- **The navigation station (helm)**: `GalaxyMap` is embedded in the ship's window over the panel (`force_native` off, its own 3D world and input; the U4a spike's choice). It holds plotting (a star, Sol, a body in this system), cruise speed, commit, cancel, Return to Sol and the Sgr A* entry. At Sgr A* the panel shows the stop ladder with **Approach to the next stop** and **Leave Sgr A\***.
- **M is the read-only star chart** (D-57 Q2): browse, select and read only. It has no slider, commit, cancel, Return to Sol, in-system list or Sgr A* entry. It never plans and never pauses the guided voyage. Its selection carries over to the helm. I-card "Open in map" opens the chart.
- **The Voyage console** shows the itinerary and **Begin guided voyage**. **The Archive terminal** opens the codex with the news and legacy-log line. The free-navigation session now carries the Archive table, so the codex shows what it has unlocked.
- **Confirms** (§C4): commit, Begin guided voyage, Approach and Leave confirm by a 1.5 s hold. Releasing restarts the hold with no penalty. With the accessibility setting they confirm by pressing twice; Esc backs out. No confirm has a deadline.
- `ShipConsoles.use(station, action)` is the single decision entry for the player's panels, the tests and M4.5's bot.
- **Dwell label** (§A3): when the view rests 0.5 s, the star or body at the centre is named with its distance and "I details". It uses the I card's own pick, read only, and can be toggled in Tab.
- `make ship-console-test` and `make no-twitch-test` (in `make test`).
  - The console test covers stations, reach and facing, the dolly, both confirm modes, helm against chart, Voyage, Archive, Sgr A*, Walk to and onboarding.
  - The no-twitch test (NT1) sweeps every key, the mouse buttons and the pan gesture in four states and finds no player decision intent. NT2 shows that a dialog, a panel and an armed confirm survive 600 s of fake time.
- `make ship-ui-window-check` (GPU window, AC15): the helm opens over the console, takes a real click selection and a 1.5 s hold commit.

### Changed

- **N, L and C no longer decide.** N is the guided voyage's Skip dwell (pacing); K stays as skip stage, or finish approach at Sgr A*. Approach and Leave are at the navigation station, and the codex is at the Archive terminal. The interim Tab "Decisions" block is gone.
- Outside the helm the map rests in chart mode and plans nothing. A commit confirmed at the helm still goes out on the next tick.
- A commit now re-plans any plan in its own tick (it used to re-plan body plans only). Before this, a star plan made before the 1.5 s hold was refused `stale_plan`, because a ship at rest moves with its body. The GPU window check found this.
