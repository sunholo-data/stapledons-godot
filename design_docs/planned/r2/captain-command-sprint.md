# Sprint R2-CAPTAIN-COMMAND: the chair runs the ship

**Status:** Approved 2026-11-09 (Mark, attended: “yep go”); implemented locally, validation and independent review in progress. Visual acceptance remains pending.
**Design:** [captain-command.md](captain-command.md).
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-CAPTAIN-COMMAND.json`.
**Direction:** Mark's attended request of 2026-11-09, recorded as D-149.
**Estimate:** 850 code/test/tool LOC, three focused implementation sessions plus independent evaluation and attended visual review. Contact art replacement, if needed, is a separate estimate after measurement.

## Playable outcome

Sit in the captain's chair, read the ship overview, plot/commit a journey, talk to the crew, handle their holds, listen to Earth and read/ask the Archive without walking between desks. Close the UI to look around; Stand up returns safely to ordinary exploration.

## Rulings and approval

D-149 authorizes this direction and chair clipping repair, amending D-56's per-console walking requirement. It does not approve a finished layout or resolve D-148. This plan is the concrete implementation proposal. **Do not execute until Mark approves this sprint**, per CLAUDE.md's development cycle, step 2. Once approved, do not re-ask for settled product choices. Mark's acceptance of the dev build remains the visual merge gate.

## Preflight

1. Recheck origin/main, the mission PID and open PR hunks. Use a topic clone if required by concurrent work; preserve the current attended design/ledger changes.
2. Use the pinned AILANG v0.56.1 for any sim-running test. This checkout's ignored runtime was v0.54.18 at survey; PATH was v0.57.4 development. Stage the release; do not bump the project pin.
3. Run baseline `captain-chair-test`, `captain-anim-test`, `ship-console-test` and `bridge-operator-test`. Record D-148's inherited failure separately. Do not weaken its assertions or infer authorization for a desk repair.
4. Capture chair poses before choosing a correction. Existing Comms gates are `comms-station-test` and `comms-history-test`; include them when adapting their panel host.

No `.ail` code is planned, so the AILANG syntax/showcase gate is inapplicable. If scope expands into `.ail`, load the pinned release's teaching prompt and update the plan before editing it.

## Registry reuse

On 2026-11-09, `runtime/bin/ailang pkg search crew`, `pkg search relativity`, `pkg info sunholo/crew_core` and `pkg docs sunholo/crew_core` succeeded against the registry. crew_core 0.6.0 supplies the existing pure crew host; relativity search also returns observe. Keep the game's existing pins. The new work is Godot interaction/layout/contact, not a new package capability.

| Milestone | Decision | Reason |
|---|---|---|
| C1 | none | Godot painted-pose/furniture contact and chair lifecycle; no package math. |
| C2 | none | Host existing Godot panels and existing sim queues; do not reproduce package logic. |
| C3 | depend | Exercise the pinned sunholo/crew_core 0.6.0 via the actual game sim for parity; keep pins. |

## C1 — chair contact and lifecycle (200 LOC; session 1)

**Red first:** extend `tests/test_captain_chair.gd` for closing/reopening and safe stand; add `tests/test_captain_command_contact.gd` with a meaningful displaced-anchor negative control. A headless test cannot prove pixel contact: add a capture tool that samples sit, seated and stand, Bow/Astern, close/deck.

**Change:** author measured chair-specific contact data and a helper if needed; adapt `chair_seat`/sit/stand to the physical reference and clip anchors. Keep standing foot placement and other console poses independent. Use the existing painted clips if they fit; do not invent an unmeasured offset or hide the captain. Include `.uid` files with new scripts. When changing a pinned manifest, update the associated asset pin and run its relevant asset/layout checks.

**Acceptance:** design AC1; `make captain-chair-test captain-command-contact-test captain-anim-test`; open baseline/after chair frames. New contact target uses `$(SCRIPT_GATE)` with nonzero counts and a deadline.

**Risk:** the current painted pose may not fit the physical chair. If replacement art is necessary, finish the diagnostic and independent command-UI work; report exactly what asset is needed before expanding the art task.

## C2 — combined command screen (450 LOC; session 2; depends C1)

**Red first:** new `tests/test_captain_command.gd`: real seated authority, all five systems, no avatar move/dolly, deny standing/off-bridge access, selection persistence, duplicate connections/sends, safe disposal, confirmations disarmed on tab/close/stand. Verify mouse, keyboard, controller and nested Esc routing.

**Change:** `ui/captain_command.gd` owns overview/system tabs/attention links and the combined layout. Add explicit interaction origin to `demos/ship_consoles.gd`; reuse action handlers and persistent panel instances. Adapt `demos/ship_geometry_demo.gd` for seated entry/input/exit, keeping chair authority separate from station focus. Add companion helpers instead of growing those large files with another full UI. Keep the ship/sky camera at the chair; support a responsive collapsed overview for wide system panels.

**Acceptance:** design AC2, AC4, AC5; `make captain-command-test captain-chair-test ship-console-test no-twitch-test ui-theme-check comms-station-test comms-history-test`. All panel switching is display-only. Existing irreversible decisions retain their existing confirmation flow.

## C3 — a complete seated playthrough (200 LOC; session 3; depends C2)

**Example:** add a scripted seated journey fixture/harness that selects a real target, commits, checks crew, handles a seeded concern/hold, opens received Earth content and reads the Archive. Use one seed and matched logical tick inputs for chair/station comparison, not wall-clock-driven run lengths. Test an in-flight crew/Archive request during tab switching.

**Change:** `tests/test_captain_command_parity.gd`, fixture under `tests/fixtures/captain_command/`, a responsive/attention capture tool and make targets. Compare actual ordered intents and authoritative world outcomes across chair/station routes. Feed factual overview text through existing bindings; include display-audit coverage for new fields. Update controls/help, design status and changelog fragment.

**Acceptance:** design AC3, AC6–AC9; `make captain-command-parity-test captain-command-test captain-command-capture ui-theme-check uid-guard`; targeted display audit and the baseline physical-console/animation gates. Inspect all rendered frames and report unresolved contact/layout problems honestly.

**Review:** run only touched headless gates locally. Fast CI is required, but do not launch a full `make test`, `make golden` or quiet-host wait as a merge prerequisite. Reuse existing SR/GR views; any changed physics visual gets the required spec case and targeted golden. Publish a dev build after the implementation is reviewable. A different model family evaluates implementation, then Mark reviews the visible result before merge.

## Progress and handoff

**Playtest refinement, 2026-11-09:** C2 reopened after Mark rejected the flat dashboard. Replace it with a first-person seated cockpit, five surrounding physical screens, animated camera selection and actual UI rendered on the active screen. New headless geometry/picking and projected-Control input checks supplement parity and guided-review checks. Mark prohibits GPU use while training; export headlessly and upload directly for laptop verification. The earlier C2 pass remains historical evidence, not acceptance of the new presentation.

The sprint JSON records the current evidence and remaining visual/landing gates. Validate using `/Users/voightkampff/.claude/skills/sprint-executor/scripts/validate_sprint_json.sh R2-CAPTAIN-COMMAND`; this checks plan structure, not game correctness. Do not mark the sprint complete until evaluation and attended visual acceptance are recorded. Land docs/index/changelog and the companion design-repo clarification at completion.

## Execution notes — 2026-11-09

- C1: measured actual cushion/20-degree chair facing and installed the guide-derived contact candidate, with independent displaced-root/furniture tests. Pixel contact remains unaccepted; the painted billboard and actual cushion height need the baseline/candidate render review.
- C2: combined shell and all five real system panels implemented; actual crew-call width tested at 960×540. Chair-only reading viewports preserve existing Archive readers and provide bounded vertical scrolling. Walk to chair arrives and sits automatically. Physical console access retains reach and confirmation rules.
- C3: real chair/station journey parity passes (1,202 flight ticks each, 1,207 journal rows; identical input bytes including dtau and identical worlds). New layout capture covers 18 system/resolution cases headless. Targeted regression and hold checks are recorded in the execution report; no full suite/GPU acceptance is claimed.
