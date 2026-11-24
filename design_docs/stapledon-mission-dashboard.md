# Mission dashboard — Stapledon

Updated 2026-11-24, iteration 114. Row 7aw landed: the nightly test profile no longer stores the machine's credentials, and evidence packs are checked for secret values before they can be published. **The 15 credentials exposed in iteration 113 still need rotating** (private message `inbox_1795505042463_90e973b8`), and the deleted pack is still held by the bucket's 7-day soft delete until about 2026-12-01 (private message `inbox_1795532162832_a01c722c`). Metered $0.11.
R1: clauses 1–3 are MET. Clause 4 is UNMET: AC12 (frames during the live transit must stay under 16.7 ms, judged on the slowest 1 % of frames, the p99) has one counted miss on a valid run, 17.338 ms (iteration 107); row 7av waits on D-172. Clause 5 is ongoing. This iteration did not move the goal (tooling security).
What changed, in plain words: the nightly speed profile used to save a full `make` settings dump that included every environment variable, passwords and tokens included. It no longer writes that dump, it drops make's error text (which can also contain them), and it deletes the test run's temporary files when the run ends. A new check, `tools/evidence_secret_guard.sh`, reads the secret values from its own environment without ever printing them and refuses any file, folder or `.tgz` that contains one; `tools/evidence_publish.sh` uploads only when that check passes. In this session the check passed ordinary repo folders and refused a planted copy of a real token by name.
Last design: `design_docs/implemented/r1/rig-profile-secret-hygiene.md` (revision 3; GLM 5.3 designer, two quorum rounds; judged 85 then 92 PASS).
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: main is `0a85fad8` (PR #478, tools only; no game code). Fast tier green on the PR head and on the merge.
Visible: nothing new, so no dev build is needed.
Nightly: #392 still red on the 2 attended targets, `ui-theme-check` (7as) and `basis-gate` (7at). Tonight's `rig/full` is the first to run the new controls.
Lanes: no lane degraded. Controller Opus 5.5; designer GLM 5.3 (pi; the D-146 B rotation, pointer advanced); planner and executor GPT-6.2 Sol (codex); judge Sonnet 5.5 (Agent tool).
Next: record-only fires under D-168 B unless you rule.
Still waiting: D-172 (default record-only on 7av: no publish, no O3).
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0 (latest is v0.1.0).
Package: ailang-packages#206 (social_dynamics 0.4.1) is OPEN, unmerged and unpublished.
Human gates, all OPEN:
- D-175 (new): keep loop evidence in the public bucket behind the new guard (A, default), or move it to the private dev-builds bucket (B)?
- D-174: its default A ran this iteration (7aw landed).
- D-173: approve the rule that a timing run counts when the CPU used outside it stays low (OQ1 with OQ3), the baseline source (OQ2, co-primary on V21's reading), OQ4–OQ5; or choose B, C or D.
- D-172: publish 0.4.1 and crew_core 0.6.1, and is O3 next? Recommendation C.
- D-171: its default A ran; B is open.
- D-170: its default A ran in iteration 108.
- D-169: GPU window.
- D-166: default C applied (same-vendor judge on a tooling doc or record, flagged).
- D-168: C applied; in its B half (record-only fires).
Action for Mark (not a ledger decision):
- **Rotate the 15 exposed credentials** (names in `inbox_1795505042463_90e973b8`; the 1Password service-account token and the Claude OAuth token first).
- Close draft ailang-packages#144; its cause, ailang#1827, is fixed.
- Rows 7as and 7at (attended nightly reds).
- GPU scheduling.
- D-FLEET-47.
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`). This record was written in a clone at `../stapledons-godot-iter114`.
Full history: stapledon-mission-log.md, entry 114.
