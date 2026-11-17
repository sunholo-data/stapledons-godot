# Mission dashboard — Stapledon

Updated 2026-11-17, iteration 97. LANDED: row 7ap, the source-literal guard's lexical edges (PR #458, merge `e528c72c`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 re-run under D-147, needs a quiet rig); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: `replay-map-index` (in `ci-fast`) reads single-quoted keys/ids and `&`/`^` id prefixes, pins its negative-index, second-pair and unclosed-brace edges, keeps comment and string pairs failing closed, and a meta test proves its own assertions can fail; `SG_PREREQS` pins 9 pairs; the prerequisite checker no longer prints `printf: I/O error` on the runner. Test-only.
Visible: nothing; no dev build needed.
Nightly: last night (`ae5394dd`) only `ui-theme-check` red (row 7as, attended). Issue #392 stays open on 7as.
Owed: the L4 M1b baseline (three comparable serial gmake runs plus one 3.81 run, each at sampled load ≤ 5), PARKED-ON-LANE on a quiet rig; M2 waits on it.
Watch: no cross-vendor judge this fire (D-166 default C, FLAGGED). Ollama cloud hit its session limit mid-fire (Kimi planner, 429); the OpenRouter fallback finished the plan for $1.53.
Next: 7aq (D-168 C: the last guard row on Mark's 11-12 order), folding in the iteration-96/97 backlog lines; then record-only fires until #435 merges or the rig is quiet.
Critical path: 7m AC1 (clause 4) routable only on a quiet rig; at pick: 1-min load 6.7, GPU 100 %.
Human gates: D-166 OPEN (same-vendor judge when the cross-vendor one has no verdict; default C applied). D-168 OPEN (hygiene-only queue; default C applied: 7ap done, 7aq next, then idle).
Action for Mark (not a ledger decision): row 7as (telescope's theme lint); the designer resolver still returns the Opus seed while D-146 B's rotation names glm (followed the rotation, flagged).
Routing this fire: controller Opus 5.5; designer GLM 5.3 (pi, r0 + r1; D-146 B rotation); planner Kimi K3 (Ollama dead at quota → OpenRouter); executor Haiku 5.5 (claude CLI); judge Sonnet 5.5 (Agent tool).
Quorum: r1 BLOCKED 2/3 (kimi, sonnet; gemini pass) → designer revision 1; r2 BLOCKED 3/3 with concrete fixes → controller revision 2 under the narrow-refinement carve-out.
Review: Sonnet 91 PASS, 0 blocking; 35 diff-anchored mutations, 22 killed. Non-blocking notes in the charter's iteration-97 backlog line.
CI: fast tier green on PR head `3f38b1aa` (run 44171950467) and on merge `e528c72c` (run 44175380580).
Cadence: armed six-hour driver.
Metered cost: $2.36 of $5 (quorum r1 $0.28, r2 $0.55, OpenRouter planner $1.53). Quota: Anthropic subscription (Opus, Haiku, Sonnet); Ollama cloud (GLM, Kimi until 429).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter97-record`.
Full history: stapledon-mission-log.md, entry 97.
