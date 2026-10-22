# Stapledon mission dashboard

Updated 2026-10-22, iteration 46.

- **Bar:** clauses 2 and 3 are MET; 1 and 4 are UNMET; 5 is ongoing. Goal moved: L9 S0.2 is R2 sim work, in Mark's 2026-10-20 order.
- **Landed this iteration:**
  - **L9 S0.2** (PR #323, merge `db54e525`). Protocol minor 14 sits between surface (13) and archive (15). Every new_game at minor 14 or more carries a top-level `similar` section (15 worlds, vectors, 3 nearest), just before `archive`. 2.13 bytes are unchanged; a 2.15 stream minus `similar` equals the pristine bytes. Live 2.15 games receive it now; the bridge copies unknown sections. Sonnet eval 93 PASS, 0 blocking, 7 of 7 drills killed.
  - **Rows 7o + 7s** (PR #309, merge `2272527d`). `rig/full` went green in 65 min on an idle rig.
  - **Row 7r.** The log is rotated with a binary built from the driver pin. The rig's `~/go/bin/ailang` predates fix #1912 (fleet D-FLEET-29).
- **Mark (attended, mid-run):** D-116 A (the Sonnet review counts for Kerr), D-117 (S1 sounds approved, footsteps softer), D-118 (captain walk: fix the feet), D-119 (sunholo/audio plan approved).
- **Resume first:** the R2 Kerr planner pass (D-116 A), folding in the Sonnet eval's 8 findings, then K1.1a (stop before publish). After that, L9 S0.3 (bridge parse, `SIMILAR_MINOR := 14`).
- **Open decisions:** none.
- **Lanes:**
  - Planner and executor: codex gpt-6.1-sol (156k and 145k tok).
  - Evaluator: Sonnet via the Agent tool (69k tok).
  - Designer: not needed (approved plan).
  - Quorum: one $0 seat probe (Claude seat absent, quota).
- **Rig:** GPU 80 to 90 %, so 7m AC1 still needs an idle rig. 7i(c) is held by attended #318, #319 and #322.
