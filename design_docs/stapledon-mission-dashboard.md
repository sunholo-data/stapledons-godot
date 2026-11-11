# Mission dashboard — Stapledon

Updated 2026-11-11, iteration 87. LANDED: row 7al (PR #425, merge `47cf9170`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 → 7m-d → D-147); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: the map, the ship and the loading jump's prefetch all ask one constant, `SimBridge.SESSION_MINOR` (18), and the four test comparisons name it, so the next protocol bump edits one line. A partial bump used to cost 2–5 s per loading jump (the prefetched sim was refused) and surfaced only in the nightly; `session-minor-guard` (19 rejected, 3 accepted) now fails it at the PR, proven on the Ubuntu runner before landing. Nothing on screen changed.
Remaining nightly red on main (expected): `bridge-operator-test` (D-148). No nightly ran on `016a5be5` before this fire.
Watch: `current-ship-startup` first-run failures (Sonnet, iteration 83) still unexplained. A fresh clone's first Godot run can hit the sim's 30 s bootstrap budget on a loaded rig (warm it with one `hello`). A side clone made from the main checkout points `origin/HEAD` at that checkout's branch: run `git remote set-head origin main`.
Next: read the nightly on main (expect 1 red); then 7am, 7an, 7ao (all low priority); 7ad parked on iteration 80's Next; 7ac after 7ad; 7ab on its nightly-start predicate.
Critical path: 7m/7m-d parked on D-147 (default A); no routable UNMET-clause row.
Human gates (all OPEN, unchanged): D-128 order; D-129 L4 defaults; D-145 sound ownership; D-146 designer rotation; D-147 7m-d S1; D-148 bridge working-point repair (the only nightly red).
Action for Mark (not a ledger decision): codex login still reads "quota UNREADABLE" in the driver.
Routing this fire: controller Opus 5.5; designer Opus (Agent); planner kimi-k3 (pi); executor Haiku (Agent); judges Sonnet (Agent) + MiniMax M3 (pi, cross-vendor, `--tool-stall-seconds 1200` per the fleet's fix of iteration 86's ticket).
Quorum: r1 BLOCKED 3/3 (designer revision); r2 BLOCKED 2/3 on new surfaces, closed by the narrow-refinement carve-out (reviewers' fixes as written).
Review: Sonnet 91 PASS, MiniMax M3 98 PASS; non-blocking findings filed in row 7ao.
CI: fast tier green on PR heads `5f85f50a` (with AC19's two lines in the job log) and `90bcca3f`; merge `47cf9170` fast tier in progress at record time; no GPU run waited on.
Cadence: armed six-hour driver.
Metered cost: $1.45 of $5 (quorum $0.94, MiniMax $0.52). Quota: Anthropic subscription (Opus, Haiku, Sonnet), Ollama cloud (kimi-k3).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter87-record`, branch `mission/stapledon-iter87-record`.
Full history: stapledon-mission-log.md, entry 87.
