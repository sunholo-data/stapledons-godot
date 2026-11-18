# Mission dashboard — Stapledon

Updated 2026-11-18, iteration 98. LANDED: row 7aq, the guard survivors (PR #460, merge `12e54a67`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 re-run under D-147, needs a quiet rig); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: free-nav-stop proves `eye_clear`'s own occlusion refresh is load-bearing (a test blocker on the eye's centre ray, with a precondition line); the source-literal guard pins five more lexical edges and its meta test runs a healthy case; `session-minor-guard-controls` refuses 29 forms; `script-gate-lint` pins first-match-wins; the loading-jump warm-override minor is pinned. Test-only.
Visible: nothing; no dev build needed.
Nightly: last night (`9081260f`) two reds, both attended territory: `ui-theme-check` (row 7as, telescope UI) and `basis-gate` (row 7at, NEW: `demos/ship_finish_review.gd:74` from attended #455; red since `e528c72c`). Issue #392 stays open.
Owed: the L4 M1b baseline (three comparable serial gmake runs plus one 3.81 run, each at sampled load ≤ 5), PARKED-ON-LANE on a quiet rig; M2 waits on it.
Watch: the Ollama cloud session limit (429) killed a role two fires running (97 planner; 98 designer and planner) and also takes the oc-glm quorum seat: a routing signal for Mark. The quorum's OpenAI seat could not be filled (6.2 not allowlisted by the CLI, 6.1 quota): fleet ticket `quorum:codex-gpt-6.2-sol-not-allowlisted`.
Next: record-only fires (D-168 C is complete) until #435 merges or the rig is quiet (1-min load < 5, GPU < 15 % ×3, console idle); then 7m AC1 or L11.
Critical path: 7m AC1 (clause 4) routable only on a quiet rig; at pick: 1-min load 3.6, GPU 100 %.
Human gates: D-166 OPEN (same-vendor judge when the cross-vendor one has no verdict; default C applied). D-168 OPEN (hygiene-only queue; default C applied and now complete: 7ap and 7aq done, idle next).
Action for Mark (not a ledger decision): rows 7as and 7at (the two attended nightly reds); the designer resolver still returns the Opus seed while D-146 B's rotation moves on (followed the rotation, flagged).
Routing this fire: controller Opus 5.5; designer Kimi K3 (pi, Ollama; died on quota after drafting the patch) → Opus 5.5 takeover (claude CLI); planner Kimi K3 (Ollama dead → OpenRouter); executor Haiku 5.5 (claude CLI); judge Sonnet 5.5 (Agent tool).
Quorum: r1 PROCEED at N−2 (gemini pass; oc-glm-5-3 unreachable, OpenAI seat absent).
Review: Sonnet 90 PASS, 0 blocking; 19 mutations killed, 0 survived. Non-blocking notes in the charter's iteration-98 backlog line.
CI: fast tier green on PR heads `d74ba13e` (run 44242406169) and `62f64d7a` (run 44246106764); merge `12e54a67` (run 44248166020): success.
Cadence: armed six-hour driver.
Metered cost: $1.66 of $5 (quorum gemini $0.09, OpenRouter planner $1.58). Quota: Anthropic subscription (Opus, Haiku, Sonnet); Ollama cloud (Kimi until 429).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter98`.
Full history: stapledon-mission-log.md, entry 98.
