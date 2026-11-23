# Mission dashboard — Stapledon

Updated 2026-11-23, iteration 111. D-173's default ran: the loop wrote option A's design for L4's timing-run rule, put it through two quorum rounds and an independent judge (Sonnet 5.5, 85 PASS, 0 blocking), and stopped for your OK. No code. Metered $0.65.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 has one counted valid-control MISS (17.338 ms against 16.7, iteration 107); row 7av waits on D-172. Clause 5 is ongoing.
Last result: `design_docs/planned/r1/rig-test-speed-ac9-load-rule.md`.
- A timing run counts when the CPU used by everything outside it stays under the same limits (5, or median 5 and max 8). Outside CPU = the machine's busy CPU minus the run's own.
- On a quiet rig `worlds-leak` now reads outside 2.40–2.73 (counts); today's rule reads 7.0–7.4 (rejected). Injected outside load still reads 7.6–10 (rejected).
- A red run counts only if it ran with `-k` and every run names the same red targets (today: `basis-gate`, `ui-theme-check`).
- The old nightly profiles cannot be re-used (no CPU samples); each nightly writes them once the code lands.
Evidence: `gs://stapledons-voyage-assets/benchmarks/ac9-design-iter111/ac9-design-iter111-evidence.tgz` (sha256 `65db9910…b773`).
In flight: an overnight host-CPU sampler (pid 31503, stops by itself after 13 h, `/tmp/i111-overnight-data/`) to see whether tonight's late spikes are outside CPU. The next fire reads it.
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no game code change on main since iteration 102's record. Main is `e20175b5` (iteration 110's record), and the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly: #392 stays open on the 2 attended reds, `ui-theme-check` (7as) and `basis-gate` (7at).
Lanes: codex `gpt-6.2-sol` over its daily ration (probe rc 75). Designer Opus 5.5 and judge Sonnet 5.5 (Agent tool); quorum seats gemini, glm, codex, kimi.
Next: D-173. The doc's OQ1–OQ5 are the approval package. Until you answer, L4 stays parked and nothing is built.
Still waiting: D-172 (default record-only on 7av: no publish, no O3).
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0.
Package: ailang-packages#206 (social_dynamics 0.4.1) is OPEN, unmerged and unpublished.
Human gates, all OPEN:
- D-173: approve the outside-CPU rule (OQ1 with OQ3), baseline paths (OQ2), OQ4–OQ5; or B, C, D.
- D-172: publish 0.4.1 and crew_core 0.6.1, and is O3 next? Recommendation C.
- D-171: its default A ran; B is open.
- D-170: its default A ran in iteration 108.
- D-169: GPU window.
- D-166: default C applied (same-vendor judge on a tooling doc, flagged).
- D-168: C applied.
Action for Mark (not a ledger decision):
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds).
- GPU scheduling.
- D-FLEET-47.
Routing this fire: controller Opus 5.5; designer Opus 5.5 and evaluator Sonnet 5.5 (Agent tool). No planner or executor (design only).
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter111`.
Full history: stapledon-mission-log.md, entry 111.
