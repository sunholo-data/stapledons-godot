# Mission dashboard — Stapledon

Updated 2026-11-19, iteration 101. This was the third record-only fire in a row under D-168 B: no pick, no role spawned, metered $0.
R1: clauses 1–3 are MET. Clause 4 is UNMET (the 7m AC1 re-run under D-147 needs a quiet rig). Clause 5 is ongoing. Goal unmoved.
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no change on main since iteration 100's record (`dbdd20a0`); the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly: last run on `dbdd20a0` (2026-11-19 00:26 CET), with 4 reds. The two long-standing ones are in attended files: `ui-theme-check` (row 7as, telescope UI) and `basis-gate` (row 7at, `demos/ship_finish_review.gd:74`). The two new ones are environmental. `ai-key-check` saw one stray `GET /` on its loopback port and passes 3 of 3 on re-run. `display-audit-comms` was killed by a SIGTERM and passes on re-run (`failures=0`). Both re-runs were in a fresh clone of `dbdd20a0` with the pinned v0.56.1; the verdict is posted on #392. Issue #392 stays open. Golden did not start: the GPU was at 27 %, above the 25 % gate.
Owed: the L4 M1b baseline (three comparable serial gmake runs and one 3.81 run, each at sampled load ≤ 5). It is PARKED-ON-LANE until the rig is quiet, and M2 waits on it.
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0; the registry still has 0.1.0.
Critical path: 7m AC1 (clause 4) is routable only on a quiet rig. At pick (01:29Z): GPU 100 % ×3 (Ollama `qwen3.8:27b-mxfp8`, 48 GB), 1-min load 3.15, console idle 10.3 h, no remote session.
Watch: Gate 0's died-fire check (6a) has read rc 2 for four fires because no watermark file exists until a directive is marked. Fleet ticket `gate0:self-notices-rc2-no-watermark-file` (row 7au) has no reply yet. With it and the 7m AC1 lane park, the idle fingerprint cannot be written, so each idle fire still writes a full record.
Next: record-only fires until #435 merges, the rig is quiet (1-min load < 5, GPU < 15 % ×3, console idle), or D-168 is answered. Then 7m AC1 or L11.
Human gates: D-166 OPEN (whether a same-vendor judge may stand in when the cross-vendor judge gives no verdict; default C applied). D-168 OPEN (the queue is hygiene-only; default C is complete, so the loop now idles under B).
Action for Mark (not a ledger decision): rows 7as and 7at, the two attended nightly reds. GPU scheduling: local-model work (Ollama, and on 11-18 a fine-tune) has held the GPU at every recent pick, which blocks both 7m AC1 and the nightly golden. Optional: `ai-key-check` counts every GET its loopback receives, so a stray localhost client can turn it red (AI-panel owner's file, `mk/ai.mk`).
Routing this fire: controller Opus 5.5 only. The designer, planner and executor did not run because the fire is record-only, and the evaluator did not run because nothing was built.
Harness share: 13/19 tagged as HARNESS over the last 20 entries (rows 81–88 and 94–98); 99–101 are ADMIN.
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`); this record was written from a fresh clone of `origin/main` at `/tmp/stap-iter101/repo`.
Full history: stapledon-mission-log.md, entry 101.
