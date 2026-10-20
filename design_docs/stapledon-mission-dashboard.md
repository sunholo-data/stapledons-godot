# Stapledon mission dashboard

Updated 2026-10-20, iteration 40.

- **Bar:** clauses 2 and 3 are MET; 1 and 4 are UNMET; 5 is ongoing. Clause 4 moved: M4 AC4 is now MET in code (row 7p LANDED).
- **Outcome:** PR #283 merged as `598c866`. The display audit's five known findings now carry a validated `accepted_by` (D-77 for the folded transit card, D-78 for the four notation captions). The scene run prints `ac4: MET (5 accepted by D-77/D-78)`, and any other known entry keeps AC4 OPEN. The control rows went from 20 to 24, plus a mixed OPEN control. Independent Sonnet eval: 90 PASS, 0 blocking.
- **Gates:** `rig/full` green in 76 min on head `b2212cb`. The fast tier is green on the head and on the merge (39357741522).
- **Clause 4 remaining:** AC12 / row 7m AC1 (quiet-rig p99, which needs a quiet GPU), the AC5 scene golden (7i(c)) and P-land.
- **Key finds:**
  - Four `ruling_valid` pins have no isolating fixture. The evaluator's drills D1–D4 survive, and the controller reproduced D1 (row 7q, about 10 LOC).
  - The quorum's Anthropic seat was absent on quota in both rounds. Both blocks were verification gaps, which the controller measured itself.
- **Next:** row 7m AC1 (quiet GPU) ∥ L9 S0 (minor 13, then S0.1–S0.3) ∥ row 7q; then 7o, 7i(k, l), 7n, 7l, 7k; then L4 → L3 → L5 → L7.
- **Mark:** nothing open. The ledger has 93 rows, 0 OPEN. Attended since iteration 39: D-89 to D-93 (deck layout, camera, R2-CAMERA-FORWARD). #281/#282 are open, and their files are on the Do-not-touch line.
- **Lanes:**
  - Designer, planner and executor: codex gpt-6.1-sol through Agent-tool transports (117k + 77k, 116k and 127k tok).
  - Evaluator: Sonnet through the Agent tool (73k tok).
  - Metered: about $0.63 (quorum only).
- **Workspace:** sibling clones `.stapledon-loop-iter40`, `.stapledon-eval-iter40` and `.stapledon-record-iter40`. The main checkout was only read.
