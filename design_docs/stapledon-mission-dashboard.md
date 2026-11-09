# Mission dashboard — Stapledon

Updated 2026-11-09, iteration 82. LANDED: row 7ag (PR #415, merge `642c4b8c`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 → 7m-d → D-147); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: the nightly `rig/full` runs `make -k test`, names every red target (status + issue), and `rig/golden` keeps its own log.
Found: two reds hidden on main since #379 behind `bridge-operator-test`: `similar-test` (row 7ah) and `tools-test` (row 7ai).
Watch: the first keep-going nightly should list `bridge-operator-test similar-test tools-test`; on a loaded rig the 7,200 s watchdog can stop it near prerequisite 118 of 138.
Next: 7ah and 7ai (headless, from #379); 7ad parked on iteration 80's Next; 7ac after 7ad; 7ab on its nightly-start predicate.
Critical path: 7m/7m-d parked on D-147 (default A); no routable UNMET-clause row.
Human gates (all OPEN, unchanged): D-128 order; D-129 L4 defaults; D-145 sound ownership; D-146 designer rotation; D-147 7m-d S1; D-148 bridge working-point repair.
Action for Mark (not a ledger decision): codex login expired (`refresh token has expired`); the driver shows it as "quota UNREADABLE".
Routing this fire: controller Opus 5.5; designer Opus (Agent); planner kimi-k3 (pi); executor Haiku (Agent); judges Sonnet (Agent) + GLM 5.3 (pi, cross-vendor; MiniMax timed out twice).
Quorum: r1 and r2 BLOCKED 2/3; r2 only on the pending measurement, closed by the narrow-refinement carve-out with the measurement.
Review: Sonnet 86 PASS, GLM 5.3 93 PASS, implementation approved.
CI: PR head `b44a413d`, merged head `a8275144` and merge `642c4b8c` fast tier green; no GPU run waited on.
Cadence: armed six-hour driver.
Metered cost: $2.02 of $5 (quorum $0.61, MiniMax $1.42). Quota: Anthropic subscription (Opus, Haiku, Sonnet), Ollama cloud (kimi-k3, glm-5.3).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter82-record`.
Full history: stapledon-mission-log.md, entry 82.
