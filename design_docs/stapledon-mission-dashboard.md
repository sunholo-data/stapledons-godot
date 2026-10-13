# Stapledon mission dashboard

Updated 2026-10-13, iteration 27.

- **Bar:** clauses 2 and 3 are MET, 1 and 4 UNMET, and clause 5 is ongoing. This iteration did not move the goal; L2 is clause-5 hygiene.
- **Merged, CI pending:** L2 M4.6 follow-ups, PR #216 (merge `8a67df3`). PR CI run 38352228389 `success`; merge CI run 38360264695 was still running at record time, so it is not yet tagged LANDED (row 7d carries the predicate).
  - One `make lint-precision`. It now catches the `b` name and hand γ, `*.gdshaderinc` and `physics/planets.gd`, and it found and fixed two live hand computations (`main.gd:858`, `tools/glow_eps_sheet.gd:164`).
  - `codexUnlocks`' `holds` clause is kept, and `checkHintless` now kills its deletion mutant.
  - The D-52 wording is updated.
  - Items (a), (b) and (d) were closed by evidence.
  - Independent evaluation: Sonnet, 89 PASS.
- **Landed by Mark mid-iteration:** #212 (AILANG v0.54.6) and #213 (D-68: New game, Voyage log).
- **Next for the loop:** the row-7d resume predicate. Then M4.5aR3 ∥ M4.6gR3 (the clause-4 critical path) once the attended Do-not-touch refresh lands; until then, L4, L3, L5, L7 and row 7g.
- **Attended:**
  - Refresh the Do-not-touch line now that D-68 has landed. #214, still open, touches `demos/ship_consoles.gd` and `demos/ship_geometry_demo.gd`.
  - Merge #214.
  - M1.5b renders.
- **Parked on Mark:** none (0 OPEN ledger rows).
- **Routing:** cadence 6 h; codex is over its daily ration.
  - Designer: claude-opus-5-5.
  - Planner: pi kimi-k3.
  - Executor: claude-haiku-5-5.
  - Evaluator: Sonnet via the Agent tool.
  - Quorum: metered $0.51; gpt6-1-sol unreachable in both rounds.
- **Workspace:** the main checkout is stale (about 520 behind) and dirty, and is left alone. The loop works in fresh sibling clones (`.stapledon-loop-iter27`, `.stapledon-eval-iter27`, `.stapledon-record-iter27`).
- **Full detail:** mission log, iteration 27.
