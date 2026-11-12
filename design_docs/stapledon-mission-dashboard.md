# Mission dashboard — Stapledon

Updated 2026-11-12, iteration 89. LANDED: row 7an (PR #429, merge `e3e4e5ed`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 → 7m-d → D-147); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: the free-navigation stop test's I checks now fail for the right reason. A planet or star drawn over the destination has its own check, the "eye is clear" check refreshes the ship geometry itself, the destination's catalogue dot is checked dark, and the pin path has a real-pin test. Each new check has a mutation that turns it red. Tests only; nothing on screen changed.
Remaining nightly red on main (expected): `bridge-operator-test` (D-148).
Housekeeping: three leftover Godot runs from earlier pi judge and planner sessions were stopped (one had run 26 h at 34 % CPU). Fleet ticket `orphan:pi-runner:own-pgid-children-survive-role-exit` asks the pi runner to clean them up itself.
Watch: Ollama cloud's weekly quota is still empty (429): both Ollama quorum seats were absent and the planner used the OpenRouter twin ($1.74). Inside the pi sandbox `user://` is read-only, so `ship-star-identification-test` hangs there.
Next: read the nightly on main (expect 1 red); then 7ao, 7ap, 7aq (all low priority); 7ad parked on iteration 80's Next; 7ac after 7ad; 7ab on its nightly-start predicate.
Critical path: 7m/7m-d parked on D-147 (default A); no routable UNMET-clause row.
Human gates (all OPEN): D-128 order; D-129 L4 defaults; D-145 sound ownership; D-146 designer rotation; D-147 7m-d S1; D-148 bridge working-point repair (the only nightly red); D-149 earth-link capture index.
Action for Mark (not a ledger decision): codex login still reads "quota UNREADABLE" in the driver.
Routing this fire: controller Opus 5.5; designer Opus (Agent); planner kimi-k3 (pi; Ollama dead → OpenRouter); executor Haiku (Agent); judges Sonnet (Agent) + MiniMax M3 (pi, cross-vendor; one wall_timeout, recovered by a bounded second run).
Quorum: r1 BLOCKED (sol: unbounded test runner; designer revision); r2 BLOCKED (sol: shared scratch path; closed by the carve-out with sol's fix as written). glm and kimi absent both rounds.
Review: Sonnet 94 PASS, MiniMax M3 97 PASS; non-blocking survivors filed in row 7aq.
CI: fast tier green on PR heads `ce34f4f8` and `917c744b`; merge `e3e4e5ed` fast tier green; no GPU run waited on.
Cadence: armed six-hour driver.
Metered cost: $2.65 of $5 (quorum $0.22, planner $1.74, MiniMax $0.68). Quota: Anthropic subscription (Opus, Haiku, Sonnet); Ollama cloud weekly bucket empty.
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter89-7an`, branch `mission/stapledon-iter89-record`.
Full history: stapledon-mission-log.md, entry 89.
