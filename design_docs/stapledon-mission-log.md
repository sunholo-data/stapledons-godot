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

## 2026-09-28 (afternoon): iteration 2, M1.2a catalogue acquire and parse LANDED [PRODUCT]

- **Pick:** M1.2 catalogue pipeline, queue head (clause 1, UNMET). D-3 and D-4
  were resolved at iteration 1; D-5 and D-6 were resolved by Mark in attended
  sessions before this fire (`1b6a8d5`, `8e2b7dc`, attended identity). M1.6a
  stays parked: ailang#1354 and ailang#1355 are both OPEN (re-read at pick).
- **Outcome:** LANDED M1.2a. PR #5, merge `77d3f04`, CI green on the PR head
  (`5309971`) and on the merge. Also on `main`: the M1.2 re-plan `ca3db91`.
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing. M1: 3 of 12 milestones done
  (M1.2 is now M1.2a/b/c plus M1.2d). Clause 1 moved: the real CNS5 and GCNS
  bytes are acquired and parsed; the AILANG transform (M1.2b) is next.
- **Plan refresh:** the planner split the 500 LOC M1.2 row into M1.2a (~250),
  M1.2b (~250) and M1.2c (~180), and added M1.2d (~300, split 120 + 180 at
  the publish gate). It also recorded D-5 in the M1 design doc (M1.2d, AC11,
  open question 5; mechanical edit only). Planner findings, measured on the
  v0.45.0 pin: std/fs has no streaming API (`readFile` only), std/bytes has
  no float32 pack, `sim/ailang.toml` needs `FS` in `[effects].max`, and the
  package photometry interpolates by a recursive `nth_or` scan.
- **Executor result:** 15 unittest tests; 16 of 16 planned mutations killed.
  The executor found that the plan's WDprob off-by-one mutation SURVIVED the
  planned fixture (an F5.3 field masks the shift) and added two real-byte
  fixtures that kill both directions. It also found that `godot --import`
  turns `data/raw/gcns.csv` into about 70 MB of `.translation` sidecars, and
  added `data/raw/.gdignore` (the evaluator reproduced this by deleting it).
- **AC amendment (rule 3h adjudication):** α Cen distance 4.37 → 4.321 ly.
  CNS5 has one GJ 559 row (`Comp=AB`, line 5103) carrying the HIP2 2007
  parallax 754.8099975585938 mas; the fixture is byte-identical to that line
  (`cmp`). A parse-only tool must reproduce the catalogue, and 4.37 ly is the
  literature figure. The evaluator re-derived 4.3210 ly, l 315.742°,
  b −0.684° by the galactic-pole formulae (a second method).
- **Evaluator:** Sonnet via Agent tool, own worktree, **92/100 PASS**, 0
  blocking. It re-downloaded both tiers (sha256s match), re-ran every gate,
  compared 1,000 GCNS rows with the catalogue's own x50/y50/z50 (median
  relative error 0.012%) and ran 4 new plus 3 plan mutations. Findings: F1 the
  Python suite ran nowhere in CI (FIXED by the controller: `tools-test` in
  `make test`; CI log shows `Ran 15 tests … OK`); F2 a typo in the `SOURCES`
  filename map survives all tests (M1.2c row); F3 the adjudication label had
  no artifact in the repo (this entry is it); F4 the single-row 5% x50
  cross-check can pick an unlucky row (~0.5% of rows exceed 5%); F5
  `actual_loc` 666 counts the whole rewritten script.
- **Routing evidence:** base=8e2b7dcaa083150a57bd7ca50739f1ff7dea42d6@2026-09-28T13:06:21Z (by hand;
  `mission-base.sh` still cannot resolve origin/dev, ticket re-filed).
  Controller `claude-opus-5-5` (tok: not reported) · designer: not needed
  (doc exists, quorum passed iteration 1) · planner: resolver said `agent-tool
  opus fail-closed:planner-lane-field-missing`, role pinned
  `pi:ollama/kimi-k3:cloud` (driver: codex gpt-6-sol over daily ration, rc
  75) → followed the pin (role-spawn-routing §2a), probe rc=0, run verdict ok
  in 844 s (4,467,928 tok: 119,625 in, 59,947 out, 4,288,356 cache-read) ·
  executor `pi:ollama/deepseek-v4.1-flash:cloud` (codex over ration, driver
  fallback), probe rc=0, verdict ok in 468 s (7,296,392 tok: 82,410 in,
  83,486 out, 7,130,496 cache-read) · evaluator `sonnet` via Agent tool
  (140,909 tok), Anthropic ≠ DeepSeek, generator ≠ judge holds. The pi
  runner loads no sandbox or fence extension (ticket
  `pi-runner:sandbox-extensions-not-wired`, stapledon occurrence filed);
  compensated by diffing the main checkout's `git status` before and after
  each run (unchanged both times).
- **Ruled out:** (a) the α Cen mismatch is not a parser bug: the parallax
  field on the one row reproduces 4.321 ly by two methods. (b) The Python
  tests do not need `data/raw`: `make tools-test` passes with it moved
  away. (c) Planner facts re-checked first-party: `table1c.dat` 760 B ×
  331,312 records in the A6 ReadMe; the legacy Gaia Sky URL returns 404.
- **Baseline gate note:** `make test AILANG=$PWD/runtime/bin/ailang` rc=0 on
  pristine `main` before routing. No SR/GR visual changed, so `make golden`
  and `make capture` were not required for this milestone.
- **Cost:** metered $0.00 (ollama-cloud flat rate; no quorum this
  iteration) · quota buckets: opus (controller), sonnet (evaluator),
  ollama-cloud (planner, executor).
- **Next:** M1.2b (`sim/tools/catalogue.ail`, 5k-row VM probe first, 5-run
  VM parity, Python fallback on the 60 s trigger) · M1.2c · M1.2d · M4
  design doc now routable (D-6).

## 2026-09-30: iteration 3, M1.6a LANDED after predicate flip [PRODUCT]

- **Pick:** M1.6a verify-and-land, over the tagged [NEXT] M1.2b. M1.6a's
  resume predicate ("a pinned AILANG on which `make strict` passes and 30
  runs of `make parity-offaxis` are identical") flipped: ailang#1354 and
  ailang#1355 closed 2026-09-28 (upstream PR #1371, released v0.47.2, the
  repo's pin since `07d44e6`). Verified FIRST-PARTY this fire before
  unparking: `make strict` green incl. strict off-axis; 30/30
  `parity-offaxis` byte-identical (single sha256); full `make test` rc=0 on
  the branch. A row whose ordering was computed under a now-false fact
  returns to its position (Gate 2 predicate rule); M1.2b stays [NEXT].
- **Outcome:** LANDED. PR #3 marked ready, merged `5218160`; CI green on the
  merge (`5218160a4`, workflow "CI", checks=1/1 green, run started
  01:21:36Z). Landing bookkeeping committed on the branch (`6998f9d`):
  CHANGELOG entries for M1.1/M1.2a/M1.6a, a design-doc toolchain amendment
  (the two reds, their evidence, the V17 supersession), sprint-JSON
  close-out, and the round-2 eval JSON.
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing. M1: 4 of 12 milestones
  done. Clause 1 moved: the sim now takes turns at rest under protocol v1.1
  with bounded bridge waits, on a strict-VM-green pinned toolchain.
- **Executor result:** none spawned — verify-and-land of iteration 1's
  inherited work (generator pi/deepseek; its round-1 evaluation explicitly
  said do NOT rework). Load-bearing counts re-derived first-party before
  routing (physics 42, 12 AILANG tests, bridge 0 failures, parity 601
  identical — all matched the iteration-1 notes).
- **Evaluator:** sonnet round 2, **87/100 PASS**, 0 blocking (own worktree
  at `91879a2`, v0.47.2 runtime staged, all gates re-run, 6 mutations — 5
  killed, 1 minor survivor: no test pins the 1e-9 at-rest tolerance, carried
  to M1.6b). Round-1 findings re-adjudicated by name: tests_pass closed
  (20/20), AC closed (27/30), reporting duty closed (verified #1354/#1355
  upstream), bad_cmd test found already fixed at `f3d6975`, CHANGELOG +
  design-doc amendment closed by the landing commit, sprint JSON closed.
  GPU gates judged out of scope (no visual change in the diff; v1.0 parity
  byte-identical; M1.6b owns camera + golden).
- **Routing evidence:** base=a5e43943fa5e8f1ae61539e43613f70655b591b0@2026-09-30T01:03:10Z
  (by hand; `mission-base.sh` still cannot resolve this repo's `origin/main`,
  ticket `mission-base:hardcoded-origin-dev` re-filed, non-blocking).
  Controller `pi:openrouter/z-ai/glm-5.3` (Anthropic+codex over ration; pi
  fallback rung; tok: not reported) · designer: not spawned (approved M1
  design doc exists, quorum passed iteration 1) · planner: not spawned
  (approved sprint plan exists; M1.6a planned and AC-complete in the sprint
  JSON) · executor: not spawned (verify-and-land; no rework owed) ·
  evaluator `claude:sonnet` via the `claude-sub` recipe (driver lane
  `sonnet`, agent-tool path — the Agent tool does not exist in this pi
  harness; fallback per the operator's standing instruction, recorded here).
  Probed rc=0, run rc=0 in ~135 s (tok: not reported by the CLI).
  generator≠judge holds: deepseek work, sonnet judge. Harness tickets
  `pi-runner:sandbox-extensions-not-wired` and
  `rig:aqua-session-lost:windowserver-watchdog` acknowledged to mission-fleet
  (both resolved at `eec86ca4`; no stapledon queue rows to unpark).
- **Ruled out:** (a) M1.2b as this iteration's pick — its [NEXT] position was
  computed while M1.6a was parked on a defect now fixed; M1.6a's work was
  complete, reviewed (modulo toolchain), and mergeable. (b) The toolchain
  reds persisting on v0.47.2 — refuted first-party (strict green,
  30/30 deterministic parity, full `make test` rc=0), consistent with
  upstream's verification on this game's own branch. (c) A redundant
  re-execution of M1.6a — the round-1 evaluator's explicit recommendation
  against rework was followed.
- **Baseline gate note:** `make test` rc=0 on a pristine worktree at the
  base `a5e4394` (v0.47.2 runtime staged fresh via `make runtime`) before
  routing; `make strict` and `make parity-offaxis` also green at base. No
  SR/GR visual changed (evaluator: diff reduces to the old formula along
  the default heading); `make golden`/`make capture` not required for this
  milestone, M1.6b carries them.
- **Cost:** metered $0.00 · quota buckets: openrouter/z-ai (controller),
  anthropic (evaluator sonnet; ollama/codex blocked this fire, lanes
  degraded per the controlplane notice).
- **Next:** M1.2b (`sim/tools/catalogue.ail`, 5k-row VM probe first, 5-run
  VM parity, Python fallback on the 60 s trigger; note its plan still
  carries the ailang#1354/#1355 workarounds — NO custom record types and
  the 5-run parity cap — which are now unnecessary on v0.47.2 but harmless;
  the planner may relax them when M1.2b is next planned) · M1.6b (camera +
  golden, now unblocked).
