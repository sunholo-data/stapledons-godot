# Stapledon mission dashboard

Updated 2026-10-13, iteration 28.

- **Bar:** clauses 2 and 3 are MET, 1 and 4 UNMET, and clause 5 is ongoing. This iteration moved clause 4.
- **Landed:** M4.5aR3, the scene playthrough bot. PR #225, merge `09c909d`; merge CI `success`.
  - PR CI run 38437285164 `success` on `14f7aad`; merge CI run 38452636061 `success`.
  - `make playthrough` takes the title screen's New game to the 3D ship, walks to the consoles, flies to α Cen A, reads news from home, returns to Sol and ends on the Voyage log. It uses only `walk_to`/`use`, the real sim, a pinned seed and a fake clock.
  - The adversarial script proves that mid-transit re-plan, cancel and commit are refused by the sim with the journey unchanged.
  - Three driver failure controls; CPU forward pole 0.0776 px (limit 0.75).
  - One unplanned seam in `demos/ship_consoles.gd`: the helm now shows the sim's `committed` refusal mid-transit.
  - Independent evaluation: Sonnet, 88 PASS, 9 of 9 mutations red.
- **Landed:** L2 M4.6 follow-ups (PR #216; merge CI `success`).
- **Next for the loop:** M4.6gR3 (GPU goldens on the rig) ∥ M4.5bR3 (display audit, walk schema, scene replay), then row 7h follow-ups, then L9, L4, L3, L5, L7.
- **Attended:**
  - M1.5b renders.
  - R2-CREW (#224, on hold for ailang#1812).
  - The crew_core publish retry (the registry fix shipped in AILANG v0.54.8).
- **Parked on Mark:** none (0 OPEN ledger rows).
- **Routing:** cadence 6 h.
  - Executor: codex gpt-6.1-sol.
  - Evaluator: Sonnet via the Agent tool.
  - No designer or planner this iteration (the plan was approved under D-66).
  - Metered spend: $0.
- **Workspace:** the loop works in fresh sibling clones (`.stapledon-loop-iter28`, `.stapledon-eval-iter28`, `.stapledon-record-iter28`). The main checkout is clean at origin/main.
- **Full detail:** mission log, iteration 28.
