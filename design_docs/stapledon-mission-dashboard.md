# Mission dashboard — Stapledon

Updated 2026-11-12, iteration 90. LANDED: row 7ae (PR #443, merge `3ce93c9d`), D-148 A.
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 re-run under D-147, needs a quiet rig); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: at the Voyage and Crew desks the captain now stands 1.50 m from the desk (0.275 m further back), so his body no longer sits inside the screen frame. Data and test only; no code or model change. `bridge-operator-test` went from 30 passed / 14 failures to 56 / 0, and `make bridge-operator-drills` checks 16 mutations against an expected table.
Visible: Mark sees the new working spots in the next combined dev build (D-148, D-152). That look is separate from the merge; the loop does not publish.
Nightly: main's one known red (`bridge-operator-test`) should clear at the next `rig/full`, and the 129 targets after it will run for the first time since #379. Expect new reds there.
Watch: Ollama cloud's weekly quota is empty (429) for the second fire running: two quorum seats absent, and the planner used the OpenRouter twin ($1.17).
Next: read the nightly on main; then L11 (R3-REASONS: RT2a is attended in #435 and waits on `sunholo/observe` 0.2.0; check RT3a against the registry); then 7m AC1 on a quiet rig (D-147); D-149's one token; L4 (D-129 A). Guard rows 7ao–7aq wait behind these.
Critical path: 7m AC1 (clause 4) is routable on a quiet rig, third in Mark's 2026-11-12 order.
Human gates: none OPEN (157 ledger rows, valid).
Action for Mark (not a ledger decision): codex login still reads "quota UNREADABLE" in the driver; Ollama weekly limit.
Routing this fire: controller Opus 5.5; designer Opus (Agent, one carve-out resume); planner kimi-k3 (pi; Ollama dead → OpenRouter); executor Haiku (Agent); judges Sonnet (Agent) + MiniMax M3 (pi, cross-vendor).
Quorum: r3 BLOCKED at 2 seats (sol: the drill runner's restore did not fail closed; gemini pass); closed by the carve-out with sol's and gemini's fixes as written. glm and kimi absent.
Review: Sonnet 92 PASS, MiniMax M3 94 PASS; non-blocking findings in the charter's iteration-90 backlog line.
CI: fast tier green on PR heads `ce3dda13` and `a0e6e4b2`; merge `3ce93c9d` fast tier green (run 43314012197); camera-test 187/0 on the fix head; no GPU run.
Cadence: armed six-hour driver.
Metered cost: $1.82 of $5 (quorum $0.20, planner $1.17, MiniMax $0.46). Quota: Anthropic subscription (Opus, Haiku, Sonnet); Ollama cloud weekly bucket empty.
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter90-record`.
Full history: stapledon-mission-log.md, entry 90.
