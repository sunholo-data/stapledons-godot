# Approved live journey continuation

Authorization: Mark's attended instruction to add committed acceleration/deceleration to the next demo. Planner/executor workflow applied without another approval gate because scope is already explicitly approved.

1. Test normal simulation paced journey including offset second commit and cancellation refusal.
2. Add opt-in phase pacing to map; preserve fixed capture rates.
3. Isolated demo navigation and live 20 Hz sky/HUD; capture reachable bridge phases.

Validation: test_live_journey, existing ship demo tests, parse import, staged GPU capture, native bundled export smoke. Integration owner runs make test/golden and independent evaluation. Estimated 250 LOC; no physics formulas, package changes, deployment or merge.
