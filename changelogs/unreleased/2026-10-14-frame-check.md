### B is a frame check again

- **What B does:** it measures 10 seconds of whatever the player is doing, in any launch, including from the title screen. It changes no game state.
- **What it records:**
  - frame-time percentiles, and stalls over 25 ms with when they happened;
  - **how much of each frame the main thread spent waiting on the sim** (`SimBridge.send_ms_total`);
  - draw calls, memory and node counts;
  - what the game was doing, and the hardware.
- **Where it goes:**
  - the report and a midpoint screenshot are saved under `user://frame_checks/`;
  - both are uploaded to `gs://stapledons-voyage-assets/benchmarks/play/<id>.json|.png` by the Cloud CLI on a worker thread;
  - the result shows in the ship's log card.
- **The scripted benchmark** moves to the developer panel button. `make frame-check-test` covers the check.
