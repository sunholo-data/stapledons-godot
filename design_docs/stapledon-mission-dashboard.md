# Stapledon mission dashboard

Updated 2026-11-02, iteration 64.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, which runs only on a quiet rig with nobody on the console, and on P-land, which is Mark's. At pick the GPU read 67–98 % and the 1-min load 11.8. Goal unmoved.
- **Built and judged this fire, landing parked on the rig:** row 7l(a), PR #376 at `7cb5d07a`. It waits only on `rig/full`: run 1 stopped on an intermittent `no-twitch` NT4 failure (new row 7y; the target passes alone on the same tree) and run 2 on sim startup timeouts at a 1-min load of 63 from attended builds. Resume: 5-min load under 10, then `tools/rig_check.sh 376`, then merge.
  - `capture-m4-publish` now checks all 18 files, their counts (including `worlds.sha256` = 14 lines) and `shasum -c` before its first upload. Before, a missing `worlds.sha256` failed only after 17 public uploads, and a 13-line one was published with rc 0.
  - `capture-m4-publish-test` runs the real recipe against a private fixture, with a fake `gcloud` on a narrowed `PATH`, through every GNU make on `PATH`, each make bounded. It is in `make test` and `ci-fast`, so it runs on Linux on every PR.
  - The judge, Sonnet in its own clone, gave 93 PASS with zero blocking findings.
- **Closed by evidence:** row 6 (L3). `make deps` no longer fails when the PATH `ailang` differs from the pin.
- **Rig:** shared with four attended D-144 agents; the 1-min load reached 68. L4 (parallel lanes) waits on D-129.
- **In flight:** loop PR #376 (7l(a)), merge-ready except `rig/full`.
- **Order:** land #376 when the rig is quiet; 7m-d (quiet rig, nobody on the console; start from the 100 Hz hypothesis) → 7w (republish the S1 set; `[LOOP+RENDER]`, parks for Mark's sign-off) → 7x. D-129 then unlocks L4 M1b and M2.
- **Backlog (non-blocking):**
  - 7y: NT4 intermittent (`ReviewDrive.reach` cannot say why it failed).
  - Publish test: the unique-hash and manifest-count checks have no killing case (judge survivors; both predate 7l(a)).
  - S0: the guard misses `.get(&"vector")`, a bare `get("vector")` and whitespace variants.
  - Kerr: drills for the schema and source pins. 7n(f), 7n(a), 7i(h).
- **Parked on Mark:**
  - D-128: where 7m-d sits in the order. Default A is being applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A. If unanswered, M1b and M2 stay parked.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h.
  - Designer Opus and judge Sonnet ran through the Agent tool; planner and executor were codex gpt-6.1-sol. Metered spend $0.72 (two quorum rounds).
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373), R3-WORLDS (#371), R3-TRUE-PROCESSED (#374), R2-SOUND (#375).
- **Watch:**
  - 7m-d has been lane-parked at pick ten fires running.
  - The codex sandbox cannot run `pgrep`, so process and temp-dir drills belong to the controller (process fix, iteration 64).
