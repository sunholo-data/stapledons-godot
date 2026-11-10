# Mission dashboard — Stapledon

Updated 2026-11-10, iteration 84. LANDED: row 7ah (PR #419, merge `4124a84d`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 → 7m-d → D-147); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: `make similar-test` (red since #379) is green. Its main.gd guard now checks that the map session asks a `SimBridge` minor at or above `SIMILAR_MINOR` instead of naming `EARTH_MINOR`, so protocol bumps pass and downgrades fail. `similar-guard-controls` (13 rejected, 3 accepted) and the guard run in `ci-fast`. Test-only; nothing on screen changed.
Remaining nightly reds on main (expected tonight): `bridge-operator-test` (D-148), `tools-test` (7ai), `free-nav-stop-test` (7ak).
Watch: tonight's nightly should list 3 reds; `current-ship-startup` first-run failures (Sonnet, iteration 83) still unexplained.
Next: 7ai (headless); then 7ak (measure the fixed eye first; a visible fix is Mark's); then 7al (one source for the session minors, low priority); 7ad parked on iteration 80's Next; 7ac after 7ad; 7ab on its nightly-start predicate.
Critical path: 7m/7m-d parked on D-147 (default A); no routable UNMET-clause row.
Human gates (all OPEN, unchanged): D-128 order; D-129 L4 defaults; D-145 sound ownership; D-146 designer rotation; D-147 7m-d S1; D-148 bridge working-point repair.
Action for Mark (not a ledger decision): codex login still reads "quota UNREADABLE" in the driver.
Routing this fire: controller Opus 5.5; designer Opus (Agent); planner kimi-k3 (pi); executor Haiku (Agent); judges Sonnet (Agent) + MiniMax M3 (pi, cross-vendor).
Quorum: r1 BLOCKED 2/3 (designer revision); r2 BLOCKED 3/3 on one surface, closed by the narrow-refinement carve-out (controller revision 2; one of the three objections measured false).
Review: Sonnet 88 PASS, MiniMax M3 95 PASS; known lexical limit recorded (row 7al).
CI: landing head `adc65268` fast tier green (the new targets ran on Linux); merge `4124a84d` fast tier green; no GPU run waited on.
Cadence: armed six-hour driver.
Metered cost: $0.99 of $5 (quorum $0.91, MiniMax $0.08). Quota: Anthropic subscription (Opus, Haiku, Sonnet), Ollama cloud (kimi-k3).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter84`, branch `mission/stapledon-iter84-record`.
Full history: stapledon-mission-log.md, entry 84.
