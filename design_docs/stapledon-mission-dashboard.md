# Stapledon mission dashboard

Updated 2026-11-04, iteration 68.

- **Bar:** clauses 1, 2 and 3 are MET, clause 4 is UNMET and clause 5 is ongoing. Clause 4 waits on row 7m AC1. That row waits on 7m-d, and on P-land, which is Mark's.
- **Landed this fire: row 7w (PR #387, merge `59fd8293`).** `make capture-m4` now makes the same pictures every time, and `capture-m4-publish` uploads only to a new dated folder and never overwrites.
  - Main was merged into the PR first. The one conflict was the capture command line, and it keeps both changes (`$(AUDIO_OFF)` and `--fixed-fps 60`).
  - Two captures on the merged code were byte-identical (15 of 15 pictures, 14 of 14 world states).
  - Judge: Sonnet, 91 PASS, zero blocking. The fast tier was green on the PR head and on the merge.
- **Published for Mark's S1 render review:** https://storage.googleapis.com/stapledons-voyage-assets/refs/m4_ship_s1/2026-11-04/contact_sheet.png (18 files, hashes re-checked after upload). The 2026-10-16 set is untouched. Posted on #370. The loop leaves S1 alone until Mark answers.
- **Not run: 7m-d S1.** The rig was busy at both checks (GPU 100 %, Screen Sharing connected). It has parked on the rig in 12 of the 13 fires since iteration 56.
- **Order:**
  1. 7m-d S1 when `quiet2.sh` holds (four probe runs, about 3 minutes, taken first in the fire). Then OQ1–OQ5 go to Mark as one decision.
  2. 7x. Then D-129 (Mark) unlocks L4 M1b and M2.
- **Options waiting on S1 (not asked yet):**
  - OQ1: status quo.
  - OQ2: attach a display for counted runs.
  - OQ3: a product trim of the docked frame's work. The best case is p99 15.2–16.1, so it may still fail.
  - OQ4: record the empty-window floor in each bench run.
  - OQ5: a relative gate. None of these loosens 16.7 ms.
- **Rig:** shared. Local-model work and remote sessions hold the GPU for long stretches. The main checkout's staged `runtime/bin/ailang` is v0.54.18, against the v0.56.1 pin. Loop clones stage their own, so the loop is not affected.
- **Backlog (non-blocking):**
  - The 7w landing judge's survivor: the "already holds objects" branch is shadowed by the earlier guard.
  - The hidden navigation map still redraws about 600 times per 30 s of transit; the cost is unmeasured.
  - 7y: NT4 is intermittent.
  - S0 guard variants.
  - Kerr drills.
- **Parked on Mark:**
  - D-128: where 7m-d sits in the order. Default A is applied.
  - D-129: L4's OQ1–OQ4. The recommendation is A.
  - The S1 render review of `refs/m4_ship_s1/2026-11-04/`.
- **Loop:** launchd `dev.ailang.mission-stapledon`, every 6 h. This fire: a landing, so only the judge ran (Sonnet, through the Agent tool). Metered spend $0.
- **Attended in parallel (D-144, do not touch):** R2-KERR (#373, #380), R3-TRUE-PROCESSED (#384), comms station v2 (#379).
- **Watch:** quiet windows are short. 7m-d's S1 needs about 3 quiet minutes, with nobody on the console.
