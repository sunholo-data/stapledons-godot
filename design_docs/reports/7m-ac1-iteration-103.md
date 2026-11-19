# Row 7m AC1 under D-147: quiet-rig re-run, mission iteration 103 (2026-11-19)

**What this is.** Row 7m's AC1 (R1 bar clause 4, AC12 of `m4-first-journey.md`) asks for the
bridge to hold p99 < 16.7 ms in live transit at 2560×1440 on a quiet rig. Mark's ruling D-147
(Q1 B, Q2 OQ6, attended 2026-11-12) has the loop re-run it under the unchanged rule. A run
counts only if three things hold: the quiet check passes right before it, the docked control's
own p99 is ≤ 16.7 ms, and the quiet check passes again 3 s after it. The rig was quiet at about
15:42 local for the first time at any pick since iteration 99.

**Result.** 1 of 6 runs on main counts, and it is a **MISS**: transit p99 **16.813 ms** against
16.7 ms (run 3). Under row 7m's own rule ("A MISS on a quiet rig reopens the row"), the row is
reopened. Benching iteration 75's main (`8c570d1e`) the same way gave the same spread (16.24–16.81 ms),
so there is **no evidence of a regression** (HEAD n=6, median 16.67; base n=3, median 16.45; the ranges overlap). The bound sits inside the run-to-run spread on both trees.

## Setup

- Studio (Apple M4 Max, Metal, Forward+), Godot 4.7.2, AILANG v0.56.1 (`runtime/bin/ailang`,
  staged by `make runtime`), `make lens-assets sky-assets` from the pins, `godot --headless --import`.
- HEAD: a fresh clone of `origin/main` at `e29a36c0`. Base: a clone of the same at `8c570d1e`
  (iteration 75's S1 tree).
- Protocol, per run: `quiet2.sh` (verbatim from `design_docs/planned/r1/m4-7md-docked-p99-attribution.md`,
  lines 79–98) must print YES → `rm -f .godot/tmp/bench-bridge.log` →
  `make bench SCENE=bridge AILANG=runtime/bin/ailang` (under `perl alarm 900`) → `sleep 3` →
  `quiet2.sh` again. If the pre-check printed NO, the script waited 15 s and tried again.
  The deadline was 25 min for the first two runs and 15 min for the rest.
- 0 `SCRIPT ERROR` lines in any of the 9 bench logs. Every run measured both phases (boosting
  and cruising), and every run had ≥ 3,040 frames (AC2's floor is 2,500).

## Runs

| tree | run | pre (time, load1) | docked control p99 | valid control | transit frames | transit p50 / p95 / p99 (max) | over 16.7 | verdict | post at +3 s | counts |
|---|---|---|---|---|---|---|---|---|---|---|
| HEAD `e29a36c0` | 1 | 15:44:28 YES, 4.86 | 18.94 | no | 3,040 | 10.79 / 13.40 / **17.169** (97.68) | 47 | MISS | NO (load 5.73) | no |
| HEAD | 2 | 15:46:01 YES, 4.57 | 18.85 | no | 3,150 | 10.54 / 12.79 / **16.914** (83.22) | 35 | MISS | YES | no |
| HEAD | 3 | 15:49:21 YES, 4.53 | **16.60** | **yes** | 3,187 | 10.65 / 13.49 / **16.813** (54.86) | 34 | **MISS** | YES | **yes** |
| HEAD | 4 | 15:50:17 YES, 4.26 | 17.64 | no | 3,200 | 10.65 / 13.26 / **16.526** (62.36) | 26 | ok | YES | no |
| HEAD | 5 | 15:51:12 YES, 2.89 | 17.30 | no | 3,193 | 10.61 / 13.21 / **16.389** (62.88) | 28 | ok | YES | no |
| HEAD | 6 | 15:52:08 YES, 2.28 | 18.84 | no | 3,196 | 10.53 / 12.70 / **16.503** (62.41) | 28 | ok | NO (GPU 35/0/0) | no |
| base `8c570d1e` | 1 | 15:54:05 YES, 4.74 | 17.80 | no | 3,189 | 10.58 / 13.27 / **16.806** (63.28) | 36 | MISS | NO (GPU 37/0/0) | no |
| base | 2 | 15:55:12 YES, 3.78 | 17.84 | no | 3,169 | 10.60 / 12.72 / **16.451** (64.22) | 23 | ok | NO (GPU 35/0/0) | no |
| base | 3 | 15:56:08 YES, 3.81 | 19.19 | no | 3,200 | 10.55 / 12.86 / **16.240** (64.07) | 23 | ok | YES | no |

Pre-checks: GPU 0/0/0, HID idle 84,938–85,638 s, remote-procs 0, vnc 0, launchd control 1 on
every row. Waits (load 5.15–7.34, `quiet2.sh` NO): one at 15:45:42 before run 2, and seven at 15:47:09–15:49:02 before run 3, each retried after 15 s. Run 3 started at load 4.53. The post readings that
failed on the first GPU sample (HEAD 6, base 1 and 2) look the same as the probe-exit GPU
reading recorded in 7m-d V19 and V22, which D-147 Q1 B's 3 s offset was meant to absorb. Here
3 s was not always enough.

## What it says

- **AC1 is not met on main.** The only countable run misses by 0.11 ms.
- **The rule's validity filter rejects most runs.** The docked control was valid in 1 of 9 runs
  (16.60 ms). The others read 17.30–19.19 ms, the same as 7m-d's S1 band (17.35–18.41 ms). So a
  countable run is rare even on a quiet rig, and one run is a thin sample.
- **No evidence of a regression since iteration 75 (n=6 against n=3).** HEAD's transit p99 across all 6
  runs is 16.39–17.17 ms (median 16.67). Base's is 16.24–16.81 ms (median 16.45). Iteration 75's
  two base bench runs read 16.12 and 16.22. The spreads overlap, and 2 of 3 base runs passed
  where 3 of 6 HEAD runs did.
- **p99 tracks the pre-run load.** HEAD, by pre-load: 4.86 → 17.17, 4.57 → 16.91, 4.53 → 16.81 (the countable run), 4.26 → 16.53, 2.89 → 16.39, 2.28 → 16.50. The one countable run sat at load 4.53, close to the predicate's limit of 5. That fits a tail driven by contention, not by steady-state cost, and it is a lead for 7av.
- **The residual is the hitch tail.** In every run, 23–47 frames exceed 16.7 ms, with a max of
  55–98 ms. The 6pR3 design (`design_docs/planned/r1/m4-6pr3-live-transit-frame-cost.md`, Risks)
  already left their source UNMEASURED. p50 is about 10.6 ms everywhere, so the miss comes from
  that tail, not from the steady-state cost.

Raw logs: `.godot/tmp/bench-bridge.log` per run, copied to `/tmp/stap-iter103/ac1/` and
`/tmp/stap-iter103/ac1base/` on the Studio (scratch; the table above is the banked record).
