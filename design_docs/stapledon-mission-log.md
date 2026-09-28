# Stapledon mission log

Append-only. One entry per iteration, newest at the bottom.

## 2026-09-27: pre-iteration 0 (attended bootstrap)

- **Built:** the M0 spike (AILANG sidecar and the physically accurate
  starfield), published `sunholo/relativity@0.1.0`, and added CI.
- **Process:** set up the design-doc → sprint → execute → evaluate cycle. Wrote
  the M1 design doc and this charter draft.
- **Upstream:** 11 AILANG reports sent through `ailang messages` (gcp store).
- **Next:** Mark ratifies the charter (or chooses to stay attended), then the
  M1 sprint plan.
- **CI:** green on ubuntu (Godot 4.7.2, AILANG v0.45.0). The strict-VM result
  on Linux x64 is bit-identical to darwin arm64 (21.392852753780428).

## 2026-09-27 (late): armed, attended

- **M1.0 review builds ✅:** `v0.1.0-m0` runs on Mark's laptop.
- **Mark's grants:** standing permission to publish `sunholo/relativity` and to
  cut review releases. Arm the loop, with live missions fleet, world and
  stapledon.
- **Registration:** `sunholo-data/ailang#1340`. Dry run OK (own pidfile,
  lanes ok, evaluator provider ≠ executor). Bookkeeping issue #1 created.
- **Driver tests:** 92/92. One timing flake in `test_driver_notify` on the
  first run under load, green on reruns and on `origin/dev`.


## 2026-09-27 (night): iteration 0, M1.1 photometry package LANDED [PRODUCT]

- **Pick:** queue head M1 → sprint R1-M1-SKY milestone M1.1 (`sunholo/relativity@0.2.0`
  photometry). Clause 1, UNMET. Charter iteration-0 ratification filed as D-1 (not
  blocking: Mark armed the loop and granted loop publishing after the draft footer).
- **Outcome:** LANDED. Package PR sunholo-data/ailang-packages#81 (`e40f14b`, `01307ee`),
  published `sunholo/relativity@0.2.0` (content sha256:1af50b9d…); game PR #2 merged
  `b258222`, CI green on the merge commit (strict VM 21.392852753780428, parity 601 lines).
  Evaluator Sonnet **86/100 PASS**, no blocking findings.
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing. M1: 2 of 8 milestones done (M1.0, M1.1).
- **Built:** `photometry.ail` (teffFromBpRp, gMinusV, bpRpInTable, vFromG,
  illuminanceFromV, fluxRatioFromMags), generated `photometry_table.ail` from Mamajek
  v2022.04.16 via `tools/mamajek_to_ail.py`, 7 new tests (47/47 on v0.45.0 and v0.47.0).
- **Premises corrected (measured):** Mamajek BP−RP spans B9V–M9.5V, not O–L, and reverses
  at M9V (2 rows dropped); Mamajek vs Riello G−V differs 0.1015 mag at BP−RP 3.0, so the
  design's 0.05 mag AC was unmeetable → 0.11 over 0.4–3.0 plus 0.05 over 0.4–1.3 (D-2).
  The controller's own first tolerance (0.10, from node values only) was also wrong; the
  executor caught it between nodes. Sirius A and α Cen B are not in Gaia DR3; their test
  inputs are B−V transformed through the same table (disclosed, partly circular).
- **Evaluator findings actioned:** CHANGELOG tolerance (a controller replace had silently not
  matched) and the F–K comment (sweep max 0.048 mag, not 0.034). **Carried to M1.2:**
  interpolation is an O(n²) `nth_or` scan per lookup; 331k rows need Array[float] + binary search.
- **Routing evidence:** base=b2582221142cec2c2dc7808246e4be1cd6bf6424@2026-09-27T21:08:05Z (by hand:
  `mission-base.sh` cannot resolve origin/dev, ticket `mission-base:hardcoded-origin-dev`).
  Controller `claude-opus-5-5` (tok: not reported) · designer not spawned (approved M1 design
  doc exists) · planner not spawned (approved sprint plan exists; resolver said
  `agent-tool opus fail-closed:planner-lane-field-missing`) · executor `codex:gpt-6-sol`
  via recipe, probe rc=0, run rc=0 (66,074 tok) · evaluator `sonnet` via Agent tool
  (127,992 tok), provider ≠ executor.
- **Ruled out:** a Gaia DR3 cone search for Sirius and α Cen A/B (no sources: too bright);
  strict-VM probe of photometry (`println` is Phase 2E, evaluator-only), non-strict VM
  output byte-identical to the interpreter instead.
- **Cost:** metered $0 · quota buckets: codex (executor), sonnet (evaluator), opus (controller).
- **Next:** M1.2 catalogue pipeline (needs D-3/D-4 defaults; plan on v0.47) ∥ M1.6 free motion.

## 2026-09-28: iteration 1, M1.6a built, PARKED on two AILANG VM bugs [PRODUCT]

- **Pick:** M1.6 free motion (clause 1, UNMET). M1.2 was also routable in the
  clause map, but it needed D-3/D-4 (design Open questions 2/3), where the
  guardrail says stop for the user. Mark ruled on both at 08:01, mid-iteration.
- **Outcome:** PARKED. M1.6a (turn at rest, 3D position, protocol v1.1,
  bounded SimBridge) is built on draft PR #3 (`966ba3a`, `f3d6975`), but
  `make test` is red on two AILANG VM defects, reported as ailang#1354 and
  ailang#1355. Landed on `main`: the quorum-revised M1 design doc, the M1.6
  re-plan (M1.6a/M1.6b), the evaluation record, the quorum artifacts and this
  record.
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing. M1: 2 of 9 milestones done
  (M1.6 is now two milestones); M1.6a is built and blocked upstream. Clause 1
  unmoved in landed code; clause 5 moved (two VM divergences found, shrunk and
  reported).
- **Quorum:** the M1 doc had no quorum artifact, so the pick-time quorum ran.
  Round 1 (oc-glm-5-3, oc-kimi-k3, gpt6-astra) rejected 3/3 on three surfaces.
  The designer (claude-opus-5-5, rotation) revised it; the verification log
  found V2, V5 and V6 false and corrected them. Round 2 rejected 3/3 on
  concrete, non-directional fixes (external catalogue rows, bounded
  hello/step waits, a missing-photometry rule), which the controller applied
  verbatim under the narrow-refinement carve-out (first use in this mission).
  One round-2 premise was refuted by measurement: `sunholo/relativity` 0.2.0
  in the cache is the published artifact, not a dev build.
- **VM defect 1 (ailang#1354):** under `--strict-bytecode`, `GET_FIELD`
  compiles `.x` on one record type with another type's slot index when both
  have a field `x` at different positions. It fails 10 of 10 on a 9-line
  repro; the interpreter and plain `--bytecode` both return 13.0; renaming
  the field fixes it. In the game: `Motion.x` (slot 3) is used for `Vec3.x`.
- **VM defect 2 (ailang#1355):** `--bytecode` is nondeterministic. The
  17-line off-axis script diverged from the interpreter in 9 of 30 runs; a
  one-line `step` carrying an unchanged heading diverged in 5 of 25. The
  interpreter was 0 of 40, and the v1.0 600-line input was 0 of 30 on both the
  old and new sim. In a bad run the step's result is lost but the reply says
  `ok`. The bridge's own tick check catches it in play, per the evaluator.
- **Evaluator:** Sonnet (Agent tool, own worktree) **59/100 FAIL**, a hard fail
  on `make test`. It attributed both reds to the toolchain on its own
  measurements: a separate strict repro through the package's `dot`, and two
  stable VM output hashes over 20 runs. It re-ran m1, m3, m5, m6 and m8, all
  killed. Its own mutant (missing `cmd` → `bad_json`) SURVIVED; the
  controller reproduced it (12/12 green with the mutant), added the arm, and
  it now kills (11/12, restore byte-identical).
- **Executor deviation adjudicated:** the executor dropped `git checkout
  sim/ailang.lock` from `deps`/`runtime` (git writes are blocked in its
  sandbox). Measured: without it, every `make test` leaves a churned
  lockfile. The controller restored it.
- **Attended rulings:** D-1..D-4 were RESOLVED by Mark at 08:01 (commits
  `c179be4`..`23c27d7`, attended). Acknowledged; not re-asked.
- **Routing evidence:** base=228452fc9e350a989bfbf1cdf2dc86cad8247209@2026-09-28T06:59:46Z (by hand; `mission-base.sh` cannot
  resolve origin/dev). Controller `claude-opus-5-5` (tok: not reported) ·
  designer `claude:claude-opus-5-5` via `claude-sub` recipe, probe rc=0, run
  rc=0 (31,710 out, 2.28M cache-read; subscription) · planner: resolver said
  `agent-tool opus fail-closed:planner-lane-field-missing`, role pinned
  `codex:gpt-6-sol` → followed the pin (role-spawn-routing §2a), probe rc=0,
  run rc=0 (45,502 tok) · executor `codex:gpt-6-sol` recipe, run rc=0
  (213,661 tok) · evaluator `sonnet` via Agent tool (146,665 tok), provider ≠
  executor · quorum reviewers oc-glm-5-3, oc-kimi-k3, gpt6-astra (2 rounds).
- **Ruled out:** (a) the nondeterminism is not the field-slot bug: renaming the
  colliding `ship` fields still diverged 6/30. (b) It is not `std/json`
  nested `get` alone (standalone probe 25/25 stable), nor turn→step with an
  `ensures` contract alone (30/30). (c) `git log -S'| D-n |'` (the Gate-0
  provenance command) returns the row's creation commit, not the flip; `-G`
  finds the attended commits. Filed as a harness ticket.
- **Baseline gate note:** `make test` with the PATH `ailang` (v0.47) fails
  at `deps` on pristine `main`; with `AILANG=runtime/bin/ailang` (v0.45.0)
  it is green. Queued as row 6. `make golden` baseline: 9 cases, 0 failures
  (the Metal GUI session was available this fire).
- **Cost:** metered $0.61 (quorum: round 1 $0.20, round 2 $0.41) · quota
  buckets: opus (controller, designer), codex (planner, executor), sonnet
  (evaluator).
- **Next:** M1.2 catalogue pipeline (D-3/D-4 resolved) · M1.6a resumes on an
  AILANG fix · D-5 bright-star tier for Mark.
