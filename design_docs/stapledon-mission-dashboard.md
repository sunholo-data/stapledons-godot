# Mission dashboard — Stapledon

Updated 2026-11-10, iteration 83. LANDED: row 7aj (PR #417, merge `29bce517`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 → 7m-d → D-147); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: the four display audits red since #379 (`display-audit-crew`, `-comms`, `-interlude`, `scene-session-audits`) are green; the playthrough harness refreshes the bridge monitor faces; `display-audit-monitor-controls` rejects four mutants and fails closed on a stall. Test-only, nothing on screen changed.
Found: the first keep-going nightly on `b974e302` named 8 reds; 7 trace to #379. Remaining: `bridge-operator-test` (D-148), `similar-test` (7ah), `tools-test` (7ai), `free-nav-stop-test` (new 7ak).
Watch: tonight's nightly should list 4 reds; Sonnet saw two first-run `current-ship-startup` failures in a fresh clone (not in the diff, unexplained).
Next: 7ah and 7ai (headless); then 7ak (measure the fixed eye first; a visible fix is Mark's); 7ad parked on iteration 80's Next; 7ac after 7ad; 7ab on its nightly-start predicate.
Critical path: 7m/7m-d parked on D-147 (default A); no routable UNMET-clause row.
Human gates (all OPEN, unchanged): D-128 order; D-129 L4 defaults; D-145 sound ownership; D-146 designer rotation; D-147 7m-d S1; D-148 bridge working-point repair.
Action for Mark (not a ledger decision): codex login still reads expired/"quota UNREADABLE" in the driver.
Routing this fire: controller Opus 5.5; designer Opus (Agent); planner kimi-k3 (pi); executor Haiku (Agent); judges Sonnet (Agent) + MiniMax M3 (pi, cross-vendor).
Quorum: r1 and r2 BLOCKED 2/3; r2 on surfaces revision 1 added, closed by the narrow-refinement carve-out (controller revision 2).
Review: Sonnet 91 PASS, MiniMax M3 88 PASS, implementation approved.
CI: PR head `0919f0e1`, landing head `99f2892c` and merge `29bce517` fast tier green; no GPU run waited on.
Cadence: armed six-hour driver.
Metered cost: $0.37 of $5 (quorum $0.26, MiniMax $0.11). Quota: Anthropic subscription (Opus, Haiku, Sonnet), Ollama cloud (kimi-k3).
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter83-record`.
Full history: stapledon-mission-log.md, entry 83.
