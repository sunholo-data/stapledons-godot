# Captain command: local execution checkpoint, 2026-11-09

**Not landed.** Mark approved the sprint in this attended session (“yep go”). The chair command screen is implemented locally; GPU captures, independent evaluation, fast CI and Mark's visual acceptance are tracked separately. No full-suite or final clipping-fix claim.

## Result

- The seated chair hosts the existing Navigation, Voyage, Crew, Comms and Archive controls. A persistent summary and crew-attention links connect the systems. Switching tabs reuses persistent panels, cancels armed decisions and preserves queued requests.
- Physical desk access keeps its reach/approach rules. Chair authority requires a seated captain at the actual chair, and ends immediately when standing or leaving the bridge.
- Walk to includes the chair and sits on arrival. E opens/reopens command, Esc unwinds nested interactions then closes it, and Stand up returns to exploration. Ctrl+Tab and shoulder buttons switch systems.
- The actual cushion/guide measurement supplies a contact candidate and the chair's real 20-degree facing. The painted billboard has a different nominal seat height from the furniture: the 12-frame Bow/Astern baseline/candidate capture must be reviewed before calling clipping fixed. [Measured evidence](../../../art/captain-command/chair-contact.json).
- The original crew call fits at 960×540; chair-only Archive reading viewports scroll real news and long answers without replacing the underlying readers. Physical visits restore original parents/layout.

## Evidence

Runtime: released AILANG **v0.56.1** (`05c860a`), staged at `/tmp/stapledon-ailang-v0561/ailang`. The stale bundled runtime and development PATH binary were not used for acceptance.

| Check | Result | Log |
|---|---|---|
| `captain-command-test` | 33 passed, 0 failures | `.godot/tmp/captain-command-test.log` |
| `captain-command-contact-test` | 15 passed, 0 failures | `.godot/tmp/captain-command-contact-test.log` |
| `captain-chair-test` | 15 passed, 0 failures | `.godot/tmp/captain-chair-test.log` |
| `captain-anim-test` | 87 passed, 0 failures | `.godot/tmp/captain-anim-test.log` |
| `captain-command-parity-test` | 52 passed, 0 failures | `.godot/tmp/captain-command-parity-test.log` |
| `captain-command-layout-test` | 18 system/resolution cases, 0 failures | `.godot/tmp/captain-command-layout-test.log`; `renders/captain_command/layout.json` (geometry only) |
| `chair-reading-viewport-test` | 14 passed, 0 failures | `.godot/tmp/chair-reading-viewport-test.log` |
| `captain-command-guided-test` | 10 passed, 0 failures; actual guided crossing review, crew link and Brake from the seat | `.godot/tmp/captain-command-guided-test.log` |
| `ship-console-test`, `ship-ui-test` | 136 and 288 passed respectively, 0 failures | `.godot/tmp/ship-consoles.log`; `.godot/tmp/ship-ui.log` |
| `comms-station-test`, `comms-history-test` | 42 and 37 passed respectively, 0 failures | `.godot/tmp/comms-station.log`; `.godot/tmp/comms-history.log` |
| `no-twitch-test` | 41 passed, 0 failures | `.godot/tmp/no-twitch.log` |
| `script-gate-lint`, `ui-theme-check`, `uid-guard`, `audio-silent-guard`, `python-guard` | passed, including theme negative controls | `/tmp/stapledon-command-policy.log` |

The real chair and station journeys each fly **1,202 ticks**, with **1,207 recorded input rows**. Their input journals match byte for byte, including dtau, and their authoritative worlds match. The same harness exercises actual crew offers, answers a real seeded concern while the panel is hidden, revisits the same crew instance, and retains an Archive answer. A separate actual orders crew produces a hold; the overview's alert opens that actor and the existing crew confirmations resume the hold from the chair.

The first sandboxed console baseline could not write its user-data recording/offline stub cache. A normal user-data run isolated one intentional copy change (the old onboarding assertion still expected “Voyage console” in the hint); that assertion now checks the new chair direction. The final console/comms/no-twitch regressions pass with normal Godot user-data access, as listed above. The guided review uses the existing CrossingReview in the Voyage tab; its crew route keeps the captain seated and its original Brake continues the same interlude.

Inherited baseline: `bridge-operator-test` still reports **30 passed / 14 failures**, the recorded D-148 desk-placement regression, with no changed assertion. Chair work does not resolve that decision or turn the nightly green.

## Remaining acceptance

The GPU was occupied at the initial contact survey. It was idle at the publication preflight, so the bounded `make captain-command-capture captain-chair-contact-capture` ran: 18 UI frames and 12 baseline/candidate chair frames, with no script errors. The contact sheet and UI frames have been opened. A capture-only logical/physical pixel mismatch was corrected before the final UI captures. Mark's visual review still decides whether the seated fit is acceptable; the headless contact model alone is not a clipping verdict. No broad golden or quiet-host wait ran; no SR/GR shader or package formula changed.

Independent cross-family review: **Claude Sonnet 4.6, 86/100 checkpoint PASS**, [verbatim report](../../../.ailang/state/evaluations/eval_R2-CAPTAIN-COMMAND_round_1.json). No blocking code issue; landing_ready is false. Mark authorized the draft PR and private macOS dev build in this attended session on 2026-11-09 (“yep let me play it”). Fast CI/PR landing and Mark's review remain pending; do not mark the sprint complete or move these docs to implemented yet.

## Evaluation response

- The judge read the sprint JSON/report before the executor's final progress/results update. The current JSON records C2's completed headless acceptance and all test evidence; the report now includes every final regression result. C1 and C3 remain incomplete because their approved visual/landing criteria remain unmet. The suggestion to mark the whole sprint completed is deliberately not applied: that would contradict the approved plan and CLAUDE.md's definition of done. The original 86-point report is retained unchanged.
- The chair's five-centimetre authority threshold is retained and documented: the presentation-only seated avatar is frozen, and no sim integration drifts it. Repeated real journeys preserved authority; a larger threshold is not needed to cover float32 rounding.
- The optional destroyed-parent reading-wrapper cleanup suggestion is retained as a low-priority lifecycle follow-up. In the installed ownership tree the original parent also owns the wrapper and frees it with its reader. No abandoned wrapper was reproduced by the repeated restore/re-wrap test. This is not counted as a new pass or a silently applied fix.
- Companion canon clarification and GPU/dev-build/CI acceptance remain explicit landing work, not claims made by this local checkpoint.

## Attended cockpit refinement and laptop candidate — 2026-11-09

**Combined-build direction (D-151):** Mark requests one app containing both cockpit and AI-panel work. Merged current main `28d0ee23` (final AI-panel PR #414, including `204c7943`) into this branch without conflicts. Both feature histories are ancestors of the combined candidate. The normal `--dev` channel replaces the existing `~/Applications/Stapledons Voyage.app`; pinned feature-install instructions are superseded for everyday play. No additional app installation is created.

Resolved the cockpit judge's drag-state finding: selection/close reset drag and pointer state. New regressions check both resets and Esc disarm → look up → close. Combined-source cockpit checks **44/0** and AI settings **105/0** pass headlessly; menu/guided checks and headless packaging are in progress. No live-provider calls or GPU work are part of these checks. The previous independent reviews remain recorded (cockpit Claude 92; AI panel Codex 80); no source conflict or simulation edit was introduced by integration.

**Delivery correction:** the shared dev manifest was subsequently overwritten by unrelated AI-panel candidate `0a315767`, which does not contain `ui/captain_command.gd`. Mark's `--dev` install therefore did not necessarily install this PR. Copied the exact existing `4ce91d33` archive to the immutable private prefix `reviews/4ce91d33`, with a matching manifest. Install the cockpit using `DEV_BUCKET=stapledons-voyage-dev-builds/reviews/4ce91d33 tools/install_review_build.sh --dev`; this works with the existing laptop installer. No rebuild, GPU check or game launch was required. Mark's visual acceptance remains pending.

Fresh cross-family cockpit checkpoint: Claude Sonnet 4.6 **92/100 PASS**, [verbatim report](../../../.ailang/state/evaluations/eval_R2-CAPTAIN-COMMAND_round_2.json), landing_ready false. Reset drag state on system changes/close before merge; Esc-chain coverage and avoiding an unused overview viewport render are noted follow-ups. This does not validate a build without the chair source.

Mark rejected the flat dashboard during playtesting and requested seated first person, consoles around the chair and camera movement between them (D-150). The replacement uses five physical displays and one reusable SubViewport for the existing system controls. Navigation's real map and the Archive/crossing reader layers are hosted there and restored on exit. The captain remains seated; first person hides its own painted billboard. Third-person contact acceptance remains pending.

Fresh targeted headless results: command **39/0** (including a projected display click reaching a real GUI button exactly once), physical cockpit **101/0**, layout **18/0 cases**, guided review/Brake **10/0**, real-sim parity/hold **52/0**. Theme/UID guards pass. No GPU, GUI, app rendering or capture checks ran for this refinement: Mark expressly reserved the GPU for training and chose laptop playtesting.

Headless export succeeded from clean source **4ce91d338af566e046aef16be41a411902baf1c7**. CPU zip/hash/upload published **v0.4.0-dev.37-living-bridge-458-g4ce91d33** to the existing private macOS dev channel; `latest.json` was read back and its installer-compatible path verified. Archive SHA256: `9a6054252ac79c48f349f688a92bab71223e84b2ec4dc12ef562f01cdc01fbea`. Laptop install/launch: `tools/install_review_build.sh --dev`. Draft PR #412 updated; fresh read-only cross-family review is running. No merge or visual acceptance is claimed.
