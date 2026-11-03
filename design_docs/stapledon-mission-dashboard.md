# Stapledon mission dashboard

Updated 2026-11-03, iteration 66.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, which runs only on a quiet rig (GPU < 15 %, 1-min load < 5, nobody on the console), and on P-land, which is Mark's. At pick the GPU read 0 % but the 1-min load was 52 (AILANG release builds).
- **Built this fire, landing parked:** row 7w, PR #387 (`b6f84021`).
  - `make capture-m4` runs at a fixed 60 fps step, so the S1 set is byte-reproducible. Two captures gave 15 of 15 PNG and 14 of 14 world hashes equal; before, 0 of 15 PNGs matched. The drift came from wall-clock fades, dust flashes and the star light's easing.
  - `capture-m4-publish` needs `M4_PUBLISH_DATE=YYYY-MM-DD`. It uploads only to a new `refs/m4_ship_s1/<date>/` path, create-only, under a 600 s deadline. The reviewed flat set cannot be touched. The test has 15 cases.
  - Judge: Sonnet in its own clone, 92 PASS with zero blocking findings. Fast tier green.
  - `rig/full` is red at `sound-test` S2 (2 failures). The failure is inherited: main `68796623` and attended #385 fail the same way at load 7. This is row 7z, attended R2-SOUND.
- **Rig:** shared with attended D-144 agents. Main's `rig/full` is currently red at `sound-test` S2, so no PR can land until 7z clears.
- **In flight (loop):** PR #387 waits on 7z. Resume predicate: `make sound-test` green on origin/main (still red after #386, 12:41Z; merge main into #387 first: #386 edits the same `capture-m4` line) → `tools/rig_check.sh 387` → merge → publish the dated S1 set → park for Mark's S1 render review.
- **Order:** land #387 → 7m-d (quiet rig; start from the 100 Hz hypothesis) → 7x. D-129 then unlocks L4 M1b and M2.
- **Backlog (non-blocking):**
  - 7y: NT4 is intermittent; `ReviewDrive.reach` cannot say why it failed.
  - 7w judge survivors: no non-digit date case, no 403 fixture containing "matched", and the cosmetic `printf '%s\n'` quoting inside `sh -c`.
  - S0: the guard misses `.get(&"vector")`, a bare `get("vector")` and whitespace variants.
  - Kerr: drills for the schema and source pins. 7n(f), 7n(a), 7i(h).
- **Parked on Mark:**
  - D-128: where 7m-d sits in the order. Default A is being applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A. If unanswered, M1b and M2 stay parked.
  - After #387 lands: the S1 render review of the republished dated set (the loop will post the link).
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire: designer Opus (Agent tool), planner and executor codex gpt-6.1-sol, judge Sonnet (Agent tool). Metered spend $0.78 (two quorum rounds).
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380), R3-WORLDS (#371), R3-TRUE-PROCESSED (#383, #384), R2-SOUND (#382, #385), comms station v2 (#379). Unread for the Worlds agent: the celestial@0.6.0 validator memory fix ships with the next AILANG release.
- **Watch:**
  - 7m-d has been lane-parked at pick twelve fires running.
  - `sound-test` S2: three trees fail identically after a green run on one of them, which suggests a change in rig state.
