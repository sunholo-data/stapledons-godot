# Mission dashboard — Stapledon

Updated 2026-11-11, iteration 86. LANDED: row 7ak (PR #423, merge `016a5be5`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 → 7m-d → D-147); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: `make free-nav-stop-test` (red since #379) is green, `54 passed, 0 failures`. The #379 course monitor stood on the forward line of the test's fixed eye (the lift's landing). The I key was right to refuse a hidden destination; the test's eye was out of date. The test now looks from G-M4-S3's clear captain eye `(11, 82, -4.8)`, and a new check names a blocked eye. Test only; nothing on screen changed.
For Mark (no decision needed): from the lift's landing, the course screen still hides whatever is dead ahead at arrival. That view belongs to the deck-layout row.
Remaining nightly red on main (expected): `bridge-operator-test` (D-148). The 2026-11-11 01:12 nightly on `312b1772` named exactly 2 (`bridge-operator-test`, `free-nav-stop-test`).
Watch: `current-ship-startup` first-run failures (Sonnet, iteration 83) still unexplained. A fresh clone's first Godot run can hit the sim's 30 s bootstrap budget on a loaded rig (warm it with one `hello`).
Next: read the nightly on `016a5be5` (expect 1 red); then 7al, 7am, 7an (all low priority); 7ad parked on iteration 80's Next; 7ac after 7ad; 7ab on its nightly-start predicate.
Critical path: 7m/7m-d parked on D-147 (default A); no routable UNMET-clause row.
Human gates (all OPEN, unchanged): D-128 order; D-129 L4 defaults; D-145 sound ownership; D-146 designer rotation; D-147 7m-d S1; D-148 bridge working-point repair (now the only nightly red).
Action for Mark (not a ledger decision): codex login still reads "quota UNREADABLE" in the driver.
Routing this fire: controller Opus 5.5; designer Opus (Agent); planner kimi-k3 (pi); executor Haiku (Agent); judges Sonnet (Agent) + MiniMax M3 (pi, cross-vendor; attempt 1 killed by the runner's stall bound, ticket filed).
Quorum: r1 BLOCKED 1/3 (designer revision); r2 BLOCKED 2/3 on new surfaces, closed by the narrow-refinement carve-out (reviewers' fixes verbatim).
Review: Sonnet 92 PASS, MiniMax M3 81 PASS; non-blocking findings filed in row 7an.
CI: fast tier green on PR heads `3f047711` and `144a4832`; merge `016a5be5` fast tier in progress at record time; no GPU run waited on.
Cadence: armed six-hour driver.
Metered cost: $1.10 of $5 (quorum $0.47, MiniMax $0.63). Quota: Anthropic subscription (Opus, Haiku, Sonnet), Ollama cloud (kimi-k3).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter86-record`, branch `mission/stapledon-iter86-record`.
Full history: stapledon-mission-log.md, entry 86.
