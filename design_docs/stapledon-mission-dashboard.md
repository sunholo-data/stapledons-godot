# Mission dashboard — Stapledon

Updated 2026-11-13, iteration 91. LANDED: D-149 (PR #446, merge `dba1c17c`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 re-run under D-147, needs a quiet rig); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: the Earth-link review capture now plans alpha Cen A at its real map index (2), so its `a_outbound` map frame reads `CNS5:3627  ·  4.32 ly` like the live map. The source-literal guard has no pending list any more: every wrong hand-written `{index, id}` pair fails `replay-map-index`. 2 files, +3/−6.
Visible: one developer review frame (`make capture-earth-link`, GPU window); Mark sees it in the next combined dev build. The loop does not publish.
Nightly: no `rig/full` has run since `b96b2d60`; the next one is the first read of iteration 90's `bridge-operator-test` fix and the 129 targets after it. Expect new reds there.
Watch: Ollama cloud's weekly quota is empty (429) for the third fire running: two quorum seats absent, the planner on the OpenRouter twin ($0.87).
Next: read the nightly on main; L11 waits on attended #435 (RT2a, blocked on `sunholo/observe` 0.2.0), then RT2b; 7m AC1 on a quiet rig (D-147); L4 (D-129 A). Guard rows 7ao–7aq after these.
Critical path: 7m AC1 (clause 4) is routable only on a quiet rig; at this pick the GPU read 100 % with Screen Sharing active.
Human gates: none OPEN (ledger valid, no row changed this fire).
Action for Mark (not a ledger decision): codex login still reads "quota UNREADABLE" in the driver; Ollama weekly limit.
Routing this fire: controller Opus 5.5; designer Opus (Agent, one revision plus one carve-out resume); planner kimi-k3 (pi; Ollama dead → OpenRouter); executor Haiku (Agent); judges Sonnet (Agent) + MiniMax M3 (pi, cross-vendor, one tool_hang retry).
Quorum: r1 and r2 BLOCKED by sol alone (probe fail-closure, then prerequisite deadlines), gemini passed both; r2 closed by the carve-out with sol's fix verbatim. glm and kimi absent.
Review: Sonnet 93 PASS, MiniMax M3 88 PASS; non-blocking findings in the charter's iteration-91 backlog line.
CI: fast tier green on PR heads `97833536` and `cbc3e284`; merge `dba1c17c` fast tier green (run 43373290636); no GPU run.
Cadence: armed six-hour driver.
Metered cost: $1.26 of $5 (quorum $0.13, planner $0.87, MiniMax $0.26). Quota: Anthropic subscription (Opus, Haiku, Sonnet); Ollama cloud weekly bucket empty.
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter91-record`.
Full history: stapledon-mission-log.md, entry 91.
