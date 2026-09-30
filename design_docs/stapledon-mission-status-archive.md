# Stapledon mission: STATUS archive

Older STATUS stamps, moved here from `stapledon-mission.md` by the rotation rule (newest 3 stay in the charter). Newest first.

## STATUS 2026-09-28: iteration 1, M1.6a PARKED on two AILANG VM bugs

- **Mark's attended rulings (08:01) acknowledged:** D-1 bar ratified, D-2
  amendment accepted, D-3 quick+medium tiers in git, D-4 approximate WD fit.
  M1.2 is now unblocked.
- **M1 design doc passed pick-time quorum after revision:** round 1 rejected
  3/3; the designer (Opus 5.5) added a verification log (3 premises false,
  corrected) and rewrote M1.6; round 2 rejected 3/3 on concrete
  non-directional fixes, applied verbatim (narrow-refinement carve-out). New
  open question 5 (Hipparcos bright tier) → D-5.
- **M1.6 re-planned** as M1.6a (sim, protocol v1.1, bridge) and M1.6b (camera,
  golden). **M1.6a built but PARKED upstream** (draft PR #3): `--strict-bytecode`
  GET_FIELD reads the wrong slot for a field name shared across record types
  (ailang#1354); `--bytecode` is nondeterministic on `parity-offaxis`, 6–9/30
  runs (ailang#1355). Both reproduce on v0.45.0 and v0.47. Evaluator Sonnet
  59/100 FAIL, both reds attributed to the toolchain.
- **Resume predicate (M1.6a):** a pinned AILANG on which `make strict` passes
  and 30 runs of `make parity-offaxis` are identical.
- **Clause map:** 1 UNMET (M1.2 routable now; M1.6a parked upstream; M1.6b
  behind it) · 2 UNMET (M2 needs a design doc) · 3 UNMET (M3 needs a design
  doc) · 4 UNMET (blocked: ship-interior decision) · 5 ongoing (two VM
  divergences found and reported this iteration).

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
