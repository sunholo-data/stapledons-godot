# R2-CAPTAIN-COMMAND: command the ship from the captain's chair

**Status:** Implemented locally 2026-11-09 under Mark's sprint approval; acceptance/evaluation in progress, rendered contact and dev-build approval pending. Remains planned until landing.
**Release:** r2 · **Milestone:** ship usability; supplements R2-CAPTAIN-ANIMATION CA2 and R1-SHIP-UI.
**Priority:** P1. Make the existing systems practical to play together.
**Implements:** [bridge interior](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/02-bridge-interior.md), the bridge as command centre; [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md); D-149's attended amendment to D-56.
**Depends on:** existing Navigation, Voyage, Crew, Comms and Archive panels; painted chair clips; Godot 4.7+. No package or protocol change anticipated.
**Estimated:** 850 code/test/tool LOC plus measured contact-data corrections; three implementation milestones.
**Evidence:** source survey at `13bc0766`; live GitHub checked 2026-11-09. No runtime or render verdict is claimed by this design.

## Game vision alignment

| Pillar | Relevance | Score | Mechanism |
|---|---|---:|---|
| Choices Are Final | + | +1 | The chair invokes the existing commit and confirmation paths; switching systems never commits anything. |
| The Game Doesn't Judge | + | +1 | Overview reports course, crew and received signals as facts, without performance grades. |
| Time Has Emotional Weight | + | +1 | Ship and home clocks stay visible; opening the command screen does not pause the simulation. |
| The Ship Is Home | ++ | +2 | The captain has a useful place aboard from which to talk to the crew and run the ship. |
| Grounded Strangeness | 0 | 0 | No new world or biology rules. |
| We Are Not Built For This | + | +1 | Crew concerns remain visible and answerable from the seat during a long crossing. |
| Hard sci-fi authenticity (spec) | + | +1 | Existing sim fields and scientific views are reused. No new physics formula. |
| **Net** | | **+7** | **Go**, with the attended D-149 amendment to the previous walk-to-every-console rule. |

## Problem

Mark reports substantial chair clipping and slow, awkward traversal while the animation set remains incomplete. He requests the chair as a place to access all systems through a combined UI.

The chair currently only sits and stands the captain (`demos/ship_geometry_demo.gd:chair_seat`, `sit_chair`, `stand_chair`). `ShipConsoles.use` requires physical proximity to each desk, and `focus` dollies to that desk. This prevents using existing panels from the chair. `tests/test_captain_chair.gd` checks logical position and animation states, without a rendered chair-contact check. These facts establish the missing capability and test gap; the clipping's geometric cause remains to be measured.

## Goals and non-goals

Deliver a seated command screen that can perform every currently available player-facing ship operation, with a persistent overview, quick system switching and correct chair contact. Walking to individual stations remains available. Routine play must not require repeated walking between them.

This sprint does not complete the whole animation set, change walking speed, add new ship systems, or implement crew-work W2–W5. The separate desk-placement decision D-148 stays open; reporting chair clipping does not choose one of its options.

## Design

### C1. Chair contact and interaction

Capture the current sit, seated and stand states through Bow and Astern, at close and deck zoom. Measure the chair's seat, back and arm geometry against the painted pose anchors and actual rendered sprite plane. The current seat function supplies only a horizontal point at deck height; do not infer the correct correction from that fact alone.

Author one chair-specific contact record, including the physical seat reference, per-facing pose anchor where needed, and a safe standing return point. Keep it separate from standing foot anchors and desk-use poses. Correct geometry/placement or pose data based on the measurement; do not conceal overlap by disabling depth testing, making the captain transparent or removing the chair. Preserve intended backrest/arm occlusion. Prefer existing painted frames; if those cannot fit, stop that asset subtask with the measured evidence and a bounded replacement proposal.

E sits from the existing reachable area. The command screen opens once seated. A visible Stand up action closes the command session, disarms decisions, then plays stand before movement. Closing the screen leaves the captain seated; E can reopen it. Movement while the screen is open belongs to the UI; after it is closed, a movement key follows the existing stand-then-walk behaviour. Esc unwinds the active nested dialog, then the command screen. Avoid an uninterruptible animation or camera transition.

### C2. Captain's cockpit (attended playtest refinement, 2026-11-09)

Mark played the flat combined shell and asked for the captain's perspective, with consoles arranged around the seat and view movement between them. This replaces the flat layout below. The approved sprint covers this refinement; no new simulation or system is introduced.

Five physical displays form an inward-facing arc: Archive, Voyage, Navigation, Crew and Comms. Opening the chair places the camera at seated eye height above the measured cushion. Selecting a display turns and moves the view toward it; the avatar stays seated and its own billboard is hidden in first person. This is an explicit chair-only amendment to the earlier third-person rule. Third-person sit/stand contact still needs visual acceptance.

One 1024×640 SubViewport hosts the actual selected system controls on that screen, including the navigation map, Archive readers and crossing review. Inactive screens carry live summaries. Pointer rays map to screen UV coordinates; the selecting click cannot also activate a control. A small navigation rail supports offscreen displays, keyboard and controller switching. Esc unwinds nested decisions, looks up from the screen, then closes chair command; Stand up restores the normal camera and station UI parents.

Verify geometry/picking with `make chair-cockpit-test`, real projected GUI clicks and camera/lifecycle with `make captain-command-test`, and existing real-sim/guided gates. Mark's training constraint takes precedence over GPU captures: **no GPU, GUI, game-rendering or capture checks in this session**. Export headlessly and upload the macOS app for laptop playtesting; do not invoke `publish-dev`'s rendering prerequisites. No visual-pass claim before Mark plays it.

### Original flat layout (superseded by the playtest refinement above)

The chair hosts an integrated shell, with the ship/sky retained behind it and the existing clock strip above it:

```text
Ship time                       Home time                 Distance
+-----------------------+---------------------------------------+
| Captain's chair       | Navigation  Voyage  Crew  Comms Archive|
|                       |                                       |
| Current course        | Active system, using its existing      |
| Crew at a glance      | real controls and confirmation flow   |
| Signal from Earth     |                                       |
| Needs your attention  |                                       |
|                       |                                       |
| Close      Stand up   |                                       |
+-----------------------+---------------------------------------+
```

The overview opens by default and also has a clear route back from every tab. It shows the active course/phase, crew work/hold summary and received-Earth-signal status from the same world snapshot as the active panel. An attention item opens the relevant system and actual concern/message, without performing its decision. Empty or unavailable systems explain their state.

Use `CrewPalette`/the shared HUD theme: panel `#0b0f17`, text `#dbe6fa`, muted `#9eabc8`, title `#f2d180`, edge `#26324a`, and the existing UI fonts/icons. Reuse state colours with words/icons. Full navigation and crew calls get the available width; collapse the overview into a Summary button when both panes cannot fit. Test the 960×540 logical viewport as well as 1280×720 and 2560×1440. No new font, generic dashboard card grid or automatic tab cycling.

### C3. Reuse the existing systems and decision paths

Separate the interaction origin (`station` or `chair`) from the active system (`navigation`, `voyage`, `crew`, `comms`, `archive`). A chair origin is legal only while the captain is actually seated on the bridge. It bypasses the desk reach/approach and desk camera solely for this origin. Ordinary station access retains its current reach checks.

Route both origins through the existing action handlers and sim queue. Refactor `ShipConsoles` narrowly; put the new shell in `ui/captain_command.gd`, with its own `.uid`, rather than adding another large UI to the demo file. Do not copy navigation, crew, comms or Archive implementations. The command origin must also cover nested navigation/GR controls, Archive reading/asking, crew concerns and incoming holds, not just the top-level open buttons.

One scene owns one instance of each persistent panel and one set of sim signal connections. Switching systems preserves useful selection/history state, clears any armed irreversible action, releases input from the old panel and sends no decision intent. In-flight requests remain owned by the existing system; hiding it cannot duplicate a send or lose its result. Standing, leaving the bridge or returning to the title invalidates chair authority immediately. Returning to a physical console restores its camera and interaction semantics.

Godot owns this interaction state; the AILANG sim remains authoritative for decisions and outcomes. No new simulation, physics maths, NDJSON minor, live AI provider or package release is needed.

## Acceptance criteria

Commands marked **new** are planned gates, not existing pass claims. New `--script` gates use `$(SCRIPT_GATE)`, counted summaries, deadlines and SCRIPT ERROR rejection.

| ID | Check | Command |
|---|---|---|
| AC1 | Sit/stand/reopen lifecycle, safe return, no movement while seated; chair contact metadata matches installed assets | `make captain-chair-test captain-command-contact-test` (**new** second target) |
| AC2 | Five systems accessible from a seated chair, no captain relocation or desk dolly; remote access refused when standing/off-bridge | `make captain-command-test` (**new**) |
| AC3 | Same scripted decisions at chair and station yield identical ordered sim intents and world outcomes, using identical logical tick inputs and seed | `make captain-command-parity-test` (**new**) |
| AC4 | Switching/closing/disconnecting cancels armed confirmations; one signal connection/send; pending replies and selected history survive | `make captain-command-test crew-console-test comms-station-test comms-history-test` |
| AC5 | Mouse, keyboard and pad reach all systems; nested Esc handling; idle screen emits no decision; existing confirmations retained | `make captain-command-test no-twitch-test ship-console-test` |
| AC6 | Ship/home clocks and sim data update while screen is open; attention links open the actual concern; no fresh sim session | `make captain-command-parity-test` (**new**) |
| AC7 | Open and inspect all system panels, attention state and chair poses; no clipped UI or obvious body/furniture penetration in the specified views/sizes | `make captain-command-capture` (**new**, emits a contact sheet and layout report); opened renders plus Mark's dev-build review |
| AC8 | Existing physical-console and animation behaviour preserved; known D-148 failure reported without weakening it | `make captain-chair-test captain-anim-test ship-console-test ui-theme-check uid-guard`; separately `make bridge-operator-test` records inherited result |
| AC9 | Cross-family evaluation passes; fast CI green; visual review accepted before merge | `gh pr checks <PR>`; evaluation JSON; `make publish-dev` and Mark's review |

No sky, SR or GR rendering change is intended. Reuse existing views unchanged; any rendering change discovered during execution needs its applicable spec/golden case. Run only a relevant targeted GPU case if the GPU is immediately free; otherwise use nightly and dev-build review, per CLAUDE.md.

## Sub-milestones and estimates

| ID | Work | Code/test/tool LOC | Depends |
|---|---|---:|---|
| C1 | Measure/fix chair contact and interaction lifecycle; contact regression and pose capture | 200 | approved sprint |
| C2 | Chair authority, combined shell and five hosted systems; lifecycle/input tests | 450 | C1 |
| C3 | Actual decision parity, responsive captures, instructions and review handoff | 200 | C2 |

## Risks and mitigations

- **Existing panels assume a physical station.** Audit all nested routes and queues; parity checks actual intents and outcomes, not just visible tabs.
- **Painted chair contact is view dependent.** Check both player facings and both zooms; numerical anchor checks alone cannot establish visual acceptance.
- **Large existing files.** New shell/contact helpers own new behaviour; narrowly adapt the demo and console dispatcher.
- **Existing nightly red.** Issue #392 currently records the D-148 desk regression; baseline it separately and leave its repair/criteria to that decision.
- **Local toolchain drift.** The bundled runtime here is v0.54.18, while CLAUDE.md and CI pin v0.56.1; PATH is a development build. Stage the pinned release before running real-sim gates. This survey ran no game tests on either mismatched runtime.

## Open questions for Mark

Product direction and sprint are approved (Mark, attended 2026-11-09: “yep go”). Rendered chair contact and the finished UI still need attended visual acceptance. D-148's separate desk repair remains unresolved.

## Design-repo changes this needs

Record D-149 in the bridge/ship UI design: the captain's chair is an additional diegetic command station for all existing systems. This amends D-56's requirement to walk to each individual console; it keeps decisions aboard a physical bridge station. No physics or narrative canon changes. Prepare the companion canon change during execution; do not silently reinterpret the old rule.

## Deliverables

Working chair command UI, corrected chair contact, meaningful interaction/decision tests, inspected captures, dev build and independent evaluation. [Sprint plan](captain-command-sprint.md).

## Verification log

| ID | Claim | Inspection | Result at `13bc0766` |
|---|---|---|---|
| V1 | Chair only sits/stands; its seat function uses deck height and a horizontal manifest point | `sed -n '1845,1867p' demos/ship_geometry_demo.gd`; `jq '.captain_chair' assets/ship_demo/manifest.json` | No system host; height fixed at 82 in the runtime seat reference. Cause of visible clipping unmeasured. |
| V2 | Physical station access enforces reach and desk-specific camera | `sed -n '246,300p' demos/ship_consoles.gd`; `sed -n '427,450p' demos/ship_consoles.gd` | `use` reach/approach; `focus_console` camera. |
| V3 | All five systems already have handlers | `sed -n '30,49p' demos/ship_consoles.gd` | Five active entries and ACTIONS table. |
| V4 | Chair test does not assess rendered contact | `cat tests/test_captain_chair.gd` | State, point, facing and return checks only. |
| V5 | Painted seated/sit/stand assets exist | `sed -n '217,325p' assets/characters/captain/manifest.json` | Stage-0 front/back seated frames, sit frames, reverse stand. No claim of complete animation coverage. |
| V6 | UI instances have persistence/connection concerns | `sed -n '1136,1168p' demos/ship_consoles.gd` | Crew panel reuse and sim binding; Comms has persistent feed/history. |
| V7 | No competing open chair PR found | `gh pr list`; same for design repo, 2026-11-09 | Game #373/#380 and design #49 concern Kerr. |
| V8 | Nightly red differs from the chair report | `gh issue view 392 --json body,comments`; charter D-148 | Desk body/frame contact is recorded; it does not diagnose chair clipping. |
