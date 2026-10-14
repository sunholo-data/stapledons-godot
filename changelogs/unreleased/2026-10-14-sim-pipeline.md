### Performance: the sim computes while the game renders

- **The cause:** the main thread blocked on every sim tick, about 20 ms per heartbeat at 20 Hz on a Mac Studio, and more on a laptop.
- **What changes:** the live game now pipelines intent-free heartbeat ticks. `SimBridge.send(..., pipelined_ok)` writes the tick and returns. The sim computes while the frame renders, and `drain()` takes the reply before the next decision.
- **What doesn't change:**
  - ticks that carry intents (player, crew or AI) wait for their own reply as before;
  - tools, captures and tests stay synchronous.
- **Results:**
  - same inputs, same order: `make sim-pipeline-test` checks identical worlds, journals and crew against a synchronous run, including a guided-voyage arrival into its dwell;
  - main-thread cost per heartbeat drops from 19.3 to 0.7 ms;
  - headless frame check: 66 → 132 fps mean, p95 33 → 14 ms, sim share of frame time 44% → 2%.
