# Stapledon mission: STATUS archive

Older STATUS stamps, moved here from `stapledon-mission.md` by the rotation rule (newest 3 stay in the charter). Newest first.

## STATUS 2026-09-27 (late): ARMED, iteration 0 next

- Registration: `sunholo-data/ailang#1340` (registry, env, boot offset,
  `godot-game` profile). Dry run OK. Bookkeeping issue #1.
- Sprint R1-M1-SKY is in progress. **M1.0 review builds ✅**: `v0.1.0-m0`
  runs on Mark's laptop. Next is M1.1 (`sunholo/relativity@0.2.0`
  photometry).
- AILANG `origin/dev` is now v0.47.0, with unboxed `Array[float]` and VM-native
  binary/JSON ingest. Re-plan M1.2's pipeline on it (the rig binary is still
  v0.45.0; pin the upgrade deliberately).

## STATUS 2026-09-27: PRE-ITERATION-0, charter drafted, awaiting ratification

- M0 spike landed: `stapledons-godot` `e6315cf`, `sunholo/relativity@0.1.0`
  published.
- M1 design doc written: `design_docs/planned/r1/m1-relativistic-sky.md`. The
  next step is a sprint plan, attended.
- Not armed. No bookkeeping issue. The `godot-game` verify profile has not been
  added to the shared skill.

## STATUS 2026-09-27 (night): iteration 0, M1.1 LANDED

- **M1.1 ✅** `sunholo/relativity@0.2.0` published (photometry: BP−RP → T_eff,
  G−V, V → lux); package PR sunholo-data/ailang-packages#81; game pin PR #2,
  merge `b258222`, CI green. Executor codex gpt-6-sol; evaluator Sonnet 86/100.
- **Amended AC1** (measured on the source table, D-2): the Riello G−V check is
  0.11 mag over 0.4–3.0 (the data differ by 0.1015 at 3.0), 0.05 over 0.4–1.3;
  BP−RP coverage is B9V–M8.5V, not O–L.
- **Clause map:** 1 UNMET (M1.2 ∥ M1.6 routable) · 2 UNMET (M2 needs a design
  doc) · 3 UNMET (M3 needs a design doc) · 4 UNMET (blocked: ship-interior
  decision) · 5 ongoing (strict VM green at this landing).
- **M1.2 risk:** the photometry interpolation is an `nth_or` list scan
  (O(n²) per lookup); plan M1.2 on AILANG v0.47 `Array[float]` + binary search.
  The rig's PATH binary is now v0.47.0; CI and the bundled runtime pin v0.45.0.
- Harness ticket `mission-base:hardcoded-origin-dev` filed (this repo has no
  `dev` branch).
