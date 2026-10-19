# R2-CREW-CONSOLE-V2 evaluation (independent; branch feat/crew-console-v2 at 5fe53f4)

Evaluator: Claude Sonnet 5.5, not the executor. Runtime: runtime/bin/ailang v0.54.11 (runtime/VERSION).

**Score: 86 / 100. PASS (70 to pass).**

| Line | Max | Score |
|---|---|---|
| ACs and behaviour | 35 | 31 |
| Tests and gates | 25 | 22 |
| Protocol, determinism, purity | 15 | 14 |
| Display audit and UX | 15 | 12 |
| Hygiene and docs | 10 | 7 |

## Gates (all run here)
- `make -k test` exit 0.
- Individually rc=0: strict, parity, parity-v2, replay (11 cases identical, session10k), crew-parity (6 recordings), crew-console-test (0 failures, 85 ok lines), crew-hold-test, crew-bridge-test, ship-console-test (the brief's `ship-consoles-test` does not exist), no-twitch-test, display-audit-crew (samples=40, new=0, failures=0), display-audit-controls, crew-faces-check, crew-sync-check, crew-perf.
- Both `make` and `gmake` parse the new targets (`-n`).
- crew-perf: crewSkip 1.08 s; chunked critical_only 3.02 s over 39 chunks, slowest 0.128 s. The new 4.0 s budget is justified by 0.6's monthly check-ins (39 chunks vs 20). The headroom is thin on a loaded machine; the per-chunk ceiling is unchanged.

## Protocol 2.11
- Independent session (crew consent, seed 7, hands_on, ~5 years, offers/start) at minor 9 and 10: output byte-identical between origin/main sim and this branch.
- At minor 10, `as`/`start` on crew intents give status `bad_intent`. At 2.11 two VM runs are cmp-equal and VM == interpreter.
- Replay goldens untouched (no file under tests/replays changed).
- tests/crew/crossing_hold.ndjson was re-recorded. That is the crew_core 0.6 dynamics (the package pin applies at every minor), not a protocol golden. Other crew recordings are unchanged.
- `live()` in protocol_crew.ail (hides `sd-` offers) and the hands_on `stand_down` trigger are ungated, but only reachable with 0.6 stand-downs.

## Rulings and OQs, verified in code and tests
Order starts now (start:"now", applyCmd, sim test killed by mutation); header strip; Ask auto-starts on accept (start:"on_accept"); incoming call opens only when idle, else the row pulses (test AC10); Insist is the fourth answer; decline reads "Needs you: declined, open to talk"; one pending action per member (AC8, killed by mutation). Ship-wide policy/orders presses are not locked (idempotent, minor).

## Mutation probes (scratch copy)
Killed: sim work_state decline->concern; Order not starting (start mode "now" dropped); names ignore presentation; names ignore face region; wrong state colour (working == agreed); UI Start enabled during a concern (two variants); guard against double press removed; sending lock not set; unbound label (killed by both display-audit-crew and crew-console-test).
**Survived (test gaps):**
- `STATES` token mapping for `declined` -> st-working, and `concern` -> st-free (only the neighbour-pair contrast is checked, not the state->token pairing).
- `CrewConsoleModel.actions()` Start `enabled` flag, in the concern and agreed branches. The UI hard-codes `disabled`, so the model flag is decorative and untested.

## D-80
Deterministic (two runs equal), five faces with metadata (crew_faces.ail == SOURCES via crew-faces-check), gated at 2.11, same crew draws. Captures show names fit faces (Farah Khan, Elena Horvat, Mariam Toumi, Hassan Hamdan, Selam Wanjala). The standdown fixture (seed 42) has Meera Menon, also fitting.

## crew_core 0.6 migration
Steps 1-8 are present (pin, lock, digest, templates, emotion, hands_on stand_down, hold card, resolve_stand_down). The dayRem host fix is correct: against the real sim, crew turn stayed 30 across held ticks, and the days catch up after the hold clears, so none are lost. But see D1.

## Renders
Opened: board, offer, concern, declined, hold, standdown, sending, working, resting, board_working at 1280x720, and concern at 2560x1440 (the other 2560 frames were not opened). No clipping or overlap. Palette test passes and its check needs both icon and edge to differ. The bar and term icons are understandable mainly via hover tooltips, which a controller user can't reach.

## Defects
- **D1 (medium) Stand-down call focuses Resume.** `ui/crew_console_model.gd` `actions()` emits `resume:` first (about line 150) and then returns the two stand-down actions. `first_focus()` therefore picks Resume, and the render shows the focus ring on "Resume auto-run". Repro (real sim, seed 42, orders, hands_on, guided crossing, hold h30-stand_down-medic): queue only `crew_resume`. Result: no refusal, the stand-down id is gone, a new hold `refusal_under_orders` appears, and crew_core counts the lapse as a denial (the migration doc says so). Arm + confirm on the default focus silently denies the rest. Answering first works (trust 54 -> 58).
- **D2 (low) Test gaps** above (state->token mapping; model enabled flags).
- **D3 (low) Stale bridge const:** `bridge/sim_bridge.gd:53` `CREW_INTENTS` omits `crew_stand_down` (the const is unused).
- **D4 (low) Docs not landed:** the design doc and sprint plan are still under planned/ and the sprint JSON says paused_for_review. That belongs to landing, E.

## Suggested fixes
1. For a stand_down hold, don't offer Resume until answered (or make the stand-down answers primary and first). Add a test that `first_focus` is a stand-down answer. Consider answering the stand-down and resuming in one confirm.
2. Pin each state's token and icon in a test, and test `actions()` enabled flags. Have the UI read `a.enabled` instead of hard-coding disabled.
3. Add `crew_stand_down` to `CREW_INTENTS` or delete the const.
4. Give the terms/bars icons a visible short label or a "?" legend reachable by keyboard and pad.
