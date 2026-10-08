# Stapledon mission dashboard

Updated 2026-10-07, iteration 20.

- origin main `1d127ca` (PR #151 merged, M4.6 ungated half); merge CI green (run `37694167694`). Latest attended train: dev.20 (#149).
- Bar: clause 2 MET; clauses 1/3/4 UNMET; clause 5 ongoing. Clause 4 moved: M4.6 ungated half landed.
- M4 in: M4.0, M4.1 (both steps), M4.2, M4.3a, M4.4, M4.6a, M4.7, M4.6 ungated. Open: M4.3b, M4.5, M4.6 gated half (S1).
- **Parked on Mark: D-52**, which ship scene clause 4's journey runs in. The approved plan uses the isometric `--interior`; since 2026-10-05 the default launch is the unified 3D ship. Recommendation A (the unified ship). Default: no M4.3b; the loop works the scene-independent rows and M3.
- Banked next: M4.5 scene-independent halves (replay, parity-m4, the `session_audit` time proxy, codex unlocks), or M3 quorum and plan (clause 3).
- Follow-ups (queue 7d): `1.0 - beta` fallback in `demos/ship_geometry_demo.gd`; a `ForwardGlow.temperature` shape check; fold the m5 lint; the `ai-godot` 2 ms poll flake (iterations 17, 19, 20).
- New gates in `make test`: `lint-precision` (no hand-computed 1 − β outside physics/ and tests/; content-keyed allowlist of 4); `physics` now needs its summary line.
- Loop cadence: 6 h launchd. Roles this fire: executor Sonnet 5.5 (claude CLI), evaluator minimax-m3 (pi, rerouted for generator ≠ judge); metered $1.25 of $5.
- CI duration re-measured: ~80 min (Repo Profile updated).
- Harness share: 1/20 indexed iterations; the last 3 landings (16, 19, 20) moved clause 4, so no drift.
- Detail: mission log iteration 20; evals `.ailang/state/evaluations/eval_R1-M4-JOURNEY_M4.6u_round_{1,2}.json`.
