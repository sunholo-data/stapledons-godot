# Stapledon mission dashboard

Updated 2026-11-03, iteration 65.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, which runs only on a quiet rig with nobody on the console, and on P-land, which is Mark's. At pick the GPU read 85–89 % (an attended `rig_check` was running), the 1-min load was 3.4, and nobody was on the console. Goal unmoved.
- **Landed this fire:** row 7l(a), PR #376, merge `812625ed`. Row 7l is complete.
  - `capture-m4-publish` checks all 18 files, their counts (including `worlds.sha256` = 14 lines) and `shasum -c` before its first upload. `capture-m4-publish-test` runs in `make test` and `ci-fast`.
  - Main (AILANG v0.56.1, #377) was merged into the branch first (`c871984c`). The PR's stable patch-id was unchanged.
  - `rig/full` was green on `c871984c` in 96 min, with `no-twitch` 41 passed and 0 failures. The fast tier was green on the head and on the merge.
  - The judge, Sonnet in its own clone, gave the landing candidate 88 PASS with zero blocking findings (93 PASS on the build in iteration 64).
- **Rig:** shared with attended D-144 agents. Two `rig_check` runs overlapped at a 1-min load of 3–7 without trouble; iteration 64's failures came at 56–68. L4 (parallel lanes) waits on D-129.
- **In flight (loop):** none.
- **Order:** 7m-d (quiet GPU, nobody on the console; start from the 100 Hz hypothesis) → 7w (republish the S1 set, now that the publish is atomic; `[LOOP+RENDER]`, needs the GPU, parks for Mark's sign-off) → 7x. D-129 then unlocks L4 M1b and M2.
- **Backlog (non-blocking):**
  - 7y: NT4 is intermittent (it passed this fire); `ReviewDrive.reach` still cannot say why it failed.
  - Publish test: the unique-hash and manifest-count checks have no killing case (two judges found it).
  - S0: the guard misses `.get(&"vector")`, a bare `get("vector")` and whitespace variants.
  - Kerr: drills for the schema and source pins. 7n(f), 7n(a), 7i(h).
- **Parked on Mark:**
  - D-128: where 7m-d sits in the order. Default A is being applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A. If unanswered, M1b and M2 stay parked.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h.
  - This fire was a landing only, so the only role spawned was the judge (Sonnet, Agent tool). Metered spend $0.00.
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380), R3-WORLDS (#371), R3-TRUE-PROCESSED (#374), R2-SOUND (#375). Unread for the Worlds agent: the celestial@0.6.0 validator memory fix ships with the next AILANG release.
- **Watch:**
  - 7m-d has been lane-parked at pick eleven fires running.
  - A parked landing goes stale when main moves. Compare stable patch-ids of the judged diff and the merged diff before re-running the rig.
