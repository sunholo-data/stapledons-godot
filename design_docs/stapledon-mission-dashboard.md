# Stapledon mission dashboard

Updated 2026-10-27, iteration 53.

- **Bar:** Clauses 1/2/3 MET; 4 UNMET; 5 ongoing. This iteration moved clause 4: M4 AC5, the scene-session golden, is met. Clause 4 now waits on row 7m AC1 (quiet-rig p99, parked on rig load) and P-land (Mark).
- **Landed:** PR #341, merge `fc9e2187e67cd59564ab6aef8d0eb2a646e7d7ad`.
  - The AI=stub ship session is committed in `tests/replays/scene/`: 2,428 lines, sha-pinned, `-text`.
  - Its arm64 golden: 2,427 replies, 83,297,783 bytes, `77f7ec49…`. It was recorded with VM = interpreter (VM 92 s, interpreter 1,149 s).
  - `make replay-scene` (VM only, about 2.5 min) is part of `make test`, so it runs in `rig/full`. It is not in `ci-fast`.
  - `tools/replay.py` gains `--vm-only` and a named x86_64→arm64 comparison line.
- **Judge:** a fresh Sonnet in its own clone scored it 88/100 PASS with zero blocking findings. It killed 21 of 29 drills. Its non-blocking findings went to the follow-up backlog line: the recipe doesn't assert its own control and effect lines.
- **Gates:**
  - `rig/full` green on `c87ee9e8` in **90 min**, which is the 5,400 s watchdog (D-126).
  - Fast tier success on the head (40566702491) and on the merge (40582083418).
  - AILANG v0.54.18 / Godot 4.7.2. GPU gates N/A (no visual change).
- **Controller catch:** the executor's `replay-scene` recipe broke on BSD sed (a `/` delimiter around a path). The sandbox hid it, because the executor had no scene data to run the target on. The controller fixed it in `c87ee9e8`; a drill confirmed the step now fails on a digest mismatch.
- **Next:** K1.1a-a4 → a5 (RK-3/RK-9 owed) → L9 S0.3 → L4 (suite speed) → L3 → 7m AC1 (idle rig only).
- **Open decisions:** D-126 asks about the `rig/full` watchdog: A raise it to 7,200 s, B move L4 up, C both, D neither. Recommendation C; the default is D.
- **Capacity/ownership parks:** row 7m needs GPU < 15 % and load < 5 (load 3–10 today). Attended PRs #339 (docs) and #340 (R3 Earth link plan) are open; neither overlaps the loop's files.
- **Lanes:**
  - controller: Opus;
  - designer: Opus via `claude-sub` (create and one revision);
  - planner and executor: codex gpt-6.1-sol;
  - evaluator: Sonnet via the Agent tool.

  Metered spend was $0.60, all on the design quorum's two rounds. gpt6-1-sol was unreachable as a quorum reviewer twice.
- **Harness share:** 0/20 over iterations 34–53. Of the last three landings, #341 moved clause 4, while #333 and #327 (Kerr R2) moved none.
