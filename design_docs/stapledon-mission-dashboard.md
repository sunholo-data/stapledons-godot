# Mission dashboard — Stapledon

Updated 2026-11-17, iteration 96. LANDED: row 7ao, the session-minor guard's lexical edges (PR #456, merge `7a011303`); row 7u closed by evidence (solved attended by `c6736bab`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 re-run under D-147, needs a quiet rig); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: `make session-minor-guard` (in `ci-fast`) now refuses a downgrade below an asserted floor, a self-floor, a commented-out floor, constant-first/tab/parenthesised test spellings and a ternary around the loading jump's prefetch; `test_sim_warm` checks each `_adopt_warm` refusal alone; 7ah's `similar-main-guard` reads `_run_map` to the next top-level line. Controls 27 and 15 rejected; 10 meta-drills. Test-only.
Visible: nothing; no dev build needed.
Nightly: last night (`ae5394dd`) only `ui-theme-check` red (row 7as, attended): iteration 95's `rig-check-control` fix is proven on the rig. Issue #392 stays open on 7as.
Owed: the L4 M1b baseline (three comparable serial gmake runs plus one 3.81 run, each at sampled load ≤ 5), PARKED-ON-LANE on a quiet rig; M2 waits on it.
Watch: no cross-vendor judge this fire (D-166 default C, FLAGGED). Executor stopped correctly on a defective AC (AC14's whole-tree `git diff --check` saw the design doc's embedded patch); controller corrected the AC (design V29).
Next: L11 once attended #435 merges (RT2b); 7m AC1 and the M1b baseline on a quiet rig; then guard rows 7ap, 7aq; the iteration-96 backlog line (V27 condition-before-write hole, judge survivors S12/S1).
Critical path: 7m AC1 (clause 4) routable only on a quiet rig; at pick: 1-min load 20.2, GPU 98 %; at 12:20Z load 7.5.
Human gates: D-166 OPEN (may a loop row merge on a same-vendor judge when the cross-vendor judge has no verdict? default C applied).
Action for Mark (not a ledger decision): row 7as (telescope's theme lint); the codex lanes read "quota UNREADABLE" and the quorum's OpenAI seat was absent (quota) twice.
Routing this fire: controller Opus 5.5; designer Opus 5.5 (claude CLI, r0 + r1); planner Kimi K3 (pi); executor Haiku 5.5 (claude CLI); judge Sonnet 5.5 (Agent tool).
Quorum: r1 and r2 BLOCKED 2/3 (kimi, glm reject; gemini pass; sol absent quota); designer revision 1, controller revision 2 under the narrow-refinement carve-out.
Review: Sonnet 91 PASS, 0 blocking; 28 diff-anchored mutations, 20 killed. Non-blocking notes in the charter's iteration-96 backlog line.
CI: fast tier green on PR heads `932bd35f`, `f882f873`; merge `7a011303` polled before record.
Cadence: armed six-hour driver.
Metered cost: $1.10 of $5 (design quorum r1 $0.51, r2 $0.59). Quota: Anthropic subscription (Opus, Haiku, Sonnet); Ollama cloud (Kimi K3).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter96`.
Full history: stapledon-mission-log.md, entry 96.
