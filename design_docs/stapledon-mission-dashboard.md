# Mission dashboard — Stapledon

Updated 2026-11-18, iteration 100. This was the second record-only fire in a row under D-168 B: no pick, no role spawned, metered $0.
R1: clauses 1–3 are MET. Clause 4 is UNMET (the 7m AC1 re-run under D-147 needs a quiet rig). Clause 5 is ongoing. Goal unmoved.
Latest release: no release tag. Game and runtime pins are unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: no change on main since iteration 99's record (`dd3a7cf7`); the fast tier is green.
Visible: nothing new, so no dev build is needed.
Nightly: last run on `9081260f`, with two reds, both in attended files: `ui-theme-check` (row 7as, telescope UI) and `basis-gate` (row 7at, `demos/ship_finish_review.gd:74`). No commit since touches either. Issue #392 stays open. Golden has not started since: the GPU was at 98–100 %.
Owed: the L4 M1b baseline (three comparable serial gmake runs and one 3.81 run, each at sampled load ≤ 5). It is PARKED-ON-LANE until the rig is quiet, and M2 waits on it.
Blocked: L11 waits on attended #435 (open since 2026-11-12), which needs `sunholo/observe` 0.2.0; the registry still has 0.1.0.
Critical path: 7m AC1 (clause 4) is routable only on a quiet rig. At pick (19:04Z): GPU 100 % ×3 (a local fine-tune, `~/models/finetune`), 1-min load 4.02, console idle 3.9 h, no remote session.
Watch: Gate 0's died-fire check (6a) has read rc 2 for three fires because no watermark file exists until a directive is marked. Fleet ticket `gate0:self-notices-rc2-no-watermark-file` (row 7au) has no reply yet. With it and the 7m AC1 lane park, the idle fingerprint cannot be written, so each idle fire still writes a full record.
Next: record-only fires until #435 merges, the rig is quiet (1-min load < 5, GPU < 15 % ×3, console idle), or D-168 is answered. Then 7m AC1 or L11.
Human gates: D-166 OPEN (whether a same-vendor judge may stand in when the cross-vendor judge gives no verdict; default C applied). D-168 OPEN (the queue is hygiene-only; default C is complete, so the loop now idles under B).
Action for Mark (not a ledger decision): rows 7as and 7at, the two attended nightly reds. GPU scheduling: local-model work (now a fine-tune, before that Ollama) has held the GPU at every recent pick, which blocks both 7m AC1 and the nightly golden.
Routing this fire: controller Opus 5.5 only. The designer, planner and executor did not run because the fire is record-only, and the evaluator did not run because nothing was built.
Harness share: 14/19 tagged over the last 20 entries (above one third; rows 80–88 and 94–98).
Cadence: armed six-hour driver.
Canonical checkout untouched (attended `feat/captain-command`); this record was written from a fresh clone of `origin/main` at `/tmp/stap-iter100`.
Full history: stapledon-mission-log.md, entry 100.
