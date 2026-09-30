# Stapledon mission dashboard (snapshot, overwritten each iteration)

- **Updated:** 2026-09-30, iteration 5.
- **Release / package:** review build `v0.1.0-m0`; `sunholo/relativity@0.3.0`
  published (blackbody WD photometry); game still pins 0.2.0 until WD-3.
  Package PR sunholo-data/ailang-packages#83 awaits a merge (as #81 did).
- **Sprint:** R1-M1-SKY, 4/12 M1 milestones; M1.2b prerequisite WD-1/WD-2 ✅
  (eval MiniMax-M3 98/100 PASS), WD-3 next. Full M1.2b / AC2 still open.
- **Next:** M1.2b-WD3: pin 0.3.0, `checkWDPackage`, VM-run NaN assertion,
  M1 doc version refs (M1.2d `teffFromBV` → 0.4.0), obligations O-1 (renderer
  LUT ceiling ≥ 4.5e6 K for M1.3) and the WD "approximate" UI label. Then the
  bounded catalogue transform/writer/integration. M1.6b camera + golden ready.
  AI service foundation (D-9) routable when M1 pauses.
- **Evidence:** WD Teff ±10 % (median +3.8 % vs GF21, 1,780 WDs), V ±0.1 mag;
  interpreter == strict VM byte-identical on the 401-point digest.
- **Bar:** clauses 1–4 UNMET, 5 ongoing. Harness share 0/6; last three landings move clause 1.
- **Loop:** launchd every 6 h. Controller Opus 5.5; designer Opus 5.5 (Agent);
  planner kimi-k3 (pi/openrouter); executor Sonnet 5.5 (Agent); evaluator
  MiniMax-M3 (pi, generator≠judge reroute). Metered $1.95; codex/ollama over
  ration; OpenAI API key out of credits (gpt6-1-sol quorum seat absent).
- **Parked on Mark:** none open; D-1..D-9 RESOLVED.
- **Upstream:** ailang#1419 (interpreter NaN > x true), ailang#1420 (nested
  cons not compiled for strict VM); both reproduced v0.47.2 + v0.49.
- **Toolchain:** Godot 4.7.2, AILANG v0.47.2 pin. Main checkout
  `runtime/bin/ailang` is stale v0.45.0: run `make runtime` before WD-3.
- **Harness:** `mission-base:hardcoded-origin-dev` refiled (non-blocking).
- **Reports:** live bookkeeping issue #4; full record in stapledon-mission-log.md.
