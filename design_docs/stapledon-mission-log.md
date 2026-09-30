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

## 2026-09-30: iteration 4, M1.2b-preflight LANDED [PRODUCT]

- **Pick:** queue-head M1.2b, clause 1 UNMET; scope-preserving <=250 code/test LOC
  preflight after designer freshness and planner dependency audit. Existing approved
  M1 design/quorum retained; no new design direction or quorum spend.
- **Outcome:** LANDED. PR #9, merge `01fe9ef1a1110638de5b84b54398c1f943b9089b`; remote CI run
  36726580750, push event, complete expected check set 1/1 success on the merge.
  Implementation `c24b5ad`, banked independent review `f649e09`.
  Full M1.2b and AC2 remain incomplete; JSON `passes` stays null.
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing; M1 4/12 milestones complete. Clause 1 moved through a measured catalogue preflight; full M1.2b remains incomplete.
- **Executor result:** 218 changed code/test LOC (187 production, caps 250/200).
  Existing locked-package normal photometry only; preserves CSV IDs/order, counts
  missing and WD independently, no WD fit/default, tier sort, encoder or fallback.
  Real 5k: 5000 input, 4580 normal, 324 WD, 96 missing. Executor VM mean
  0.719015 s; controller 0.644656 s; independent judge 0.6427 s. Interpreter
  11.48–12.50 s. All six complete outputs SHA256
  `7afd4c0920614a5916d9031ca9c725f2dd24938349cd50d6f79aa3f17a33287b`.
  Timings include launch/args load/render/output, exclude FS shell read, WD,
  sort and binary. Medium/large extrapolations are estimates, not acceptance gates.
  Artifacts: `.ailang/state/{designer,planner,executor}_M1.2b_iter4.md` and
  `.ailang/state/probe_M1.2b_iter4.json` (tracked, not only build outputs).
- **Evaluator:** independent Anthropic Sonnet 5.5, **85/100 PASS**, no blockers,
  reviewed `c24b5ad2de9dc2a2827f0bb01ef5eb4322f15498` in a separate detached worktree.
  Canonical make test/probe and hash recount repeated independently. Confirmed
  mutants landed and typechecked, restored files byte-for-byte. Header/WD/package
  calls/order/flags/nonfinite mutants killed; partial missing and duplicates killed
  only by runner; WD+missing overlap, blank ID and y validation mutants survive.
  Runtime-pin/data/timeout/parity refusals exercised. F1–F3/F5 carried explicitly
  into production planning; F4 dangling test-table reference restored in record
  commit with corrected carry rule. F6 strict coverage explicitly pure render;
  fixture FS shell separately interpreted/bridged, never called whole-shell strict.
  F7 generated caches left untracked, not banked. Review JSON/MD under
  `.ailang/state/evaluations/eval_R1-M1-SKY_M1.2b-preflight_iter4.*`.
- **Routing evidence:** base=01fe9ef1a1110638de5b84b54398c1f943b9089b@2026-09-30T14:08:08Z (same origin/main read at Gate 4;
  `mission-base.sh record gate4` refused origin/dev, unchanged helper defect).
  Gate-1 base `06311aa35979af86b100a5f6ecb1e3d47435ee2e`; drift is our reviewed merge.
  Controller `codex:gpt-6.1-sol` (tok: not reported); designer `codex:gpt-6.1-sol`
  (tok: not reported, rotation after claude; pointer advanced); planner
  `codex:gpt-6.1-sol` (tok: not reported, resolver `declared:planner-lane-default-pin`);
  executor `codex:gpt-6.1-sol` (tok: not reported). All three were spawned with
  the Agent tool, as the operator explicitly requested. Evaluator Agent attempt
  failed: `Unknown model 'sonnet' for spawn_agent` (allowed models were OpenAI only).
  Fallback: independent `claude-sub -p --model sonnet` subscription recipe,
  actual provider-reported model `claude-sonnet-5-5`, probe rc=0, judge rc=0.
  Judge usage 1,100,563 tok incl. cache (38 input, 63,414 cache creation,
  1,018,627 cache reads, 18,484 output); probe 22,692 tok. Generator != judge holds.
  No role was silently skipped; no controller-only verdict. Codex quota burn is
  unknown, not zero; subscription CLI list-price $0.642297 is not a metered bill.
- **Ruled out:** (a) Full catalogue pipeline in ~250 LOC: designer and planner
  demonstrated WD package/calibration, float32 and integration dependencies.
  (b) Old f32 formula: independently reproduces 1.0 as 0.5; fractional carry
  corrected for future writer, signed zero/subnormal cases required.
  (c) Old v0.45 VM-defect premises: fixed in pinned v0.47.2, baseline green.
  (d) A 5k probe certifying medium performance or fallback trigger: unmeasured
  remaining stages prohibit that claim. (e) WD physics local to catalogue: package-first
  contribution required. D-4 approximation and publish grant already stand; technical
  calibration does not reopen a resolved human decision. D-9 attended provenance honored.
- **Baseline gate note:** pristine fresh worktree at `06311aa`, runtime staged
  with make runtime: canonical make test rc0. Controller changed-tree canonical
  make test/probe rc0; judge independently rc0. Godot 4.7.2, AILANG v0.47.2
  e939cba, relativity 0.2.0; darwin/arm64 local, Ubuntu remote CI. Physics 42,
  sim 19, parser 15, parity 601, offaxis 17; strict core/offaxis green.
  No .gd/.gdshader/.tscn change: GPU/human render gate N/A for this milestone.
- **Deviations / retro:** base helper failure re-filed to mission-fleet,
  ticket message `inbox_1790775809841_a898f371`, no shared-skill edit or harness repair.
  Manual paired-SHA record fallback disclosed (same pre-existing fallback as iteration 3).
  Gate-2 heartbeat omitted initially, later stamped explicitly delayed; actual
  pick checks preceded Gate 3. Executor's deps override replaced by canonical
  controller/judge gates. Controller moved new changelog fragment into project's
  CHANGELOG.md. Fleet log rotator targets shared main and its parser excludes this
  repo's date-first headings; index regenerated from all local full log headings,
  no rotation needed (7 entries). Shared dirty main left untouched, including brain.db.
  Strict reverse gap reproduced interpreter/VM vs strict and reported via GCP
  `inbox_1790776183299_a05dc865`; not asserted a regression. No human gate reached.
- **Cost:** metered $0.00; quota buckets codex and sonnet. No new quorum/API spend.
  Harness share 0/5 numeric iterations; last three landings M1.2a, M1.6a,
  M1.2b-preflight all move UNMET clause 1, no drift alarm. No routing-policy change.
- **Next:** package-first WD specification/calibration/publication prerequisite,
  then bounded transform/writer/full integration; carry evaluator survivors and
  interpreter medium-scale timeout design explicitly. M1.6b camera + golden ready;
  AI service foundation (D-9) routable when M1 pauses. DECISIONS FOR MARK: none.

## 2026-09-30 (night): iteration 5, M1.2b-WD1/WD2 LANDED, sunholo/relativity 0.3.0 published [PRODUCT]

- **Pick:** queue-head M1.2b next step, package-first WD (clause 1 UNMET). M1.6b
  was routable but cannot land unattended (a human-reviewed render gates its
  merge), so it was not the pick. Not already landed: no WD symbol in
  ailang-packages origin/main `0f5167b`, no matching commit or PR, index clean.
- **Outcome:** LANDED. `sunholo/relativity@0.3.0` published from
  ailang-packages commit `2f1cef8` (branch `relativity-0.3.0-wd`, PR #83 left
  for Mark to merge, following 0.2.0's precedent). Tarball sha256 `8c596f4f…`
  is identical in the dry run, the evaluated tree and the upload. Game-side
  design doc, sprint plan, sprint JSON (WD1/WD2 `passes: true`), evaluation
  and quorum artifacts land in stapledons-godot PR (this record).
- **Progress:** R1 clauses 1–4 UNMET, 5 ongoing; M1 4/12 milestones, plus the
  M1.2b WD prerequisite now 2/3 (WD-3 game pin next). Clause 1 moved: WDs
  (21,848 GCNS rows, 6.6 %) now have package physics for Teff and V.
- **Design:** `design_docs/planned/r1/m1.2b-wd-photometry.md` (787 lines).
  Gaia EDR3 photon-weighted passbands, Z_BPRP = ZP_BP − ZP_RP = 0.5906467146
  from the published VEGAMAG zero points, and a 61-node ln-T table. Accuracy
  measured on 1,780 GF21 WDs: median 1.038, 99.2 % within 10 %. Controller
  re-ran the Appendix A reference first-party: every check value reproduced.
  Quorum rounds:
  - R1 blocked at N−1 (3 rejects on unmeasured premises: Z3 ensures,
    temperature consumers, VM bit-parity). The designer measured all three
    (Z3 skips the table ensures, so the contract moved to a proved
    `bbClampTeff`; the renderer LUT ceiling of 10⁶ K becomes obligation O-1 on
    M1.3; a prototype digest was bit-identical).
  - R2 blocked at N−1 (2 rejects: missing rows for the dwarf 10.7 kK ceiling,
    the flag bits and the fixture). The controller measured all three and
    applied the reviewers' fixes verbatim (narrow-refinement carve-out).
  - Absent seats re-run alone: `gpt6-1-sol` still ABSENT (OpenAI 429, no
    credits). `oc-glm-5-3` rejected on the package-`planck` premise, which
    the controller measured (drift ≤ 4.4e-16 mag, rows K5/K6), adding a
    NaN-first rule for `bbGMinusVFromBpRp`. Quote the verdict as "PROCEED by
    carve-out at N−1, gpt6-1-sol absent (no credits)", not "quorum passed".
- **Executor result:** WD-1 208 hand-written LOC + 137 generated; WD-2 ~195
  (caps 250). AC-W1–W6 plus the dry run green; 4-mutant drill all killed and
  restored byte-identical.
- **Controller re-run (outside the executor):** test 59/59; `pkg quality`
  rc 0, no gates, contracts 3/43; `wdDigest 400` interpreter == strict VM
  byte-identical `4.6104818060721e+06` (4.7e-9 from Python); smoke OK.
- **Evaluator:** MiniMax-M3 (pi, openrouter) **98/100 PASS**, 0 blocking,
  reviewed `2f1cef8d1499d1f735a097acfad7e412cc448cd5` in a detached worktree.
  Session-protocol handshake acked. Its 8 own mutants: 6 killed; M2/M8 (NaN
  guards) survived. The controller reproduced before acting:
  - NB-3 **refuted**: check11:124 covers interior BP−RP 0.30.
  - NB-2 real. A candidate check13 (`bbTeffFromBpRpExact(NaN) == 3000.0`) was
    written and **did not kill M8 under `ailang test`**: the interpreter's
    ailang#1419 makes `NaN >= x` true, so the mutant still returns 3000.0.
    On the strict VM the mutant gives 3000.0000000000136, so only a VM-run
    assertion kills it. The judge's premise ("NaN comparisons false on both
    engines") is false for the interpreter. check13 was reverted, not landed;
    carried to WD-3 as a VM-run NaN assertion.
  - Reports: `.ailang/state/evaluations/eval_R1-M1-SKY_M1.2b-WD12_iter5.{json,md}`.
- **Routing evidence:** Gate-1 base `origin/main b2a630806643a4bbb884ea7d21db33540a92ca98`
  (recorded by hand; `mission-base.sh` still refuses origin/dev, ticket
  refiled `inbox_1790804583680_48de71e0`). Main checkout was 15 behind and
  was fast-forwarded (clean tree apart from the untracked `brain.db`).
  - Controller `claude-opus-5-5` (tok: not reported).
  - Designer `claude:claude-opus-5-5`, spawned with the Agent tool
    (`model=opus`, same model as the pin). Rotation: last-used
    `codex:gpt-6.1-sol` → glm/kimi skipped (ollama over ration) → claude;
    pointer advanced. Tokens 227,407 + 273,468 (revision).
  - Planner `pi:openrouter/moonshotai/kimi-k3`, the provider pin via
    `mission_pi_run.sh`, verdict ok (1,138,456 tok, $0.944). Resolver said
    `agent-tool opus fail-closed:no-doc` before the doc existed and
    `recipe … declared:planner-lane-default-pin` after; the pin was followed.
  - Executor `claude:claude-sonnet-5-5`, spawned with the Agent tool
    (`model=sonnet`, 120,114 tok).
  - Evaluator `pi:openrouter/minimax/minimax-m3`: the resolver's
    `reroute … generator-equals-judge` (the pinned sonnet evaluator equals the
    executor), via `mission_pi_run.sh`, verdict ok (3,447,190 tok, $0.280).
    The Agent tool could not carry this role: it is a pi lane.
  - generator≠judge holds at provider level (Anthropic vs MiniMax). No role
    was skipped and nothing ran on the controller's own verdict.
- **Ruled out:**
  - (a) M1.6b as the pick: it can't merge without a human-reviewed render.
  - (b) The old sprint's rectangular BP 505–680 / RP 640–1050 bands: they
    have the wrong slope (1.38 vs 2.00 mag span).
  - (c) Energy weighting: it shifts BP−RP by 0.39–0.50 mag.
  - (d) Per-row bisection in production: it would take about 12 minutes on
    the interpreter for the medium tier.
  - (e) An empirical correction of the +3.8 % bias: that goes beyond D-4.
  - (f) check13 as an NB-2 fix: it kills nothing on the interpreter test
    runner.
  - (g) The executor's reporting duty for #1419/#1420: the controller filed
    both.
- **Baseline gate note:** pristine clone `0f5167b` on v0.47.2: test rc 0,
  quality rc 0 (2/40, 25 PUB016), smoke needs `--package-dir .` (MOD010;
  AC-W5/W6 amended in the directives). ailang-packages has no CI (0 checks
  on main), so the Gate-3b remote-CI half is N/A for the package. Evidence
  is the controller re-run plus the independent judge. The game-side PR is
  docs/state only; its CI is polled at landing. No .gd/.gdshader/.tscn
  change, so the GPU/human render gate is N/A.
- **Deviations / retro:**
  - The main checkout's `runtime/bin/ailang` is v0.45.0 (stale vs the
    v0.47.2 pin; `make runtime` not re-run in the shared tree). All gates
    used the v0.47.2 binary at `.stapledon-wt-iter4/runtime`.
  - The evaluator worktree got the game's CLAUDE.md copied in for the
    handshake, because the package repo has none.
  - One shared-skill friction to note, not edit (charter guardrail):
    `ailang test` runs on the interpreter only, so any NaN-guard mutant is
    masked by #1419. A mutation drill on a guard needs a strict-VM arm.
- **Cost:** metered $1.95 (quorum $0.73 incl. the glm re-run, planner $0.94,
  evaluator $0.28). Quota buckets: anthropic (controller, designer, executor).
  Harness share 0/6.
- **Next:** M1.2b-WD3 (pin 0.3.0 + relock, `checkWDPackage` fixture values
  5202.556030832587 / 20.89920219434688, VM-run NaN assertion, M1 doc/sprint
  version references and obligations O-1/UI label). Then the bounded
  catalogue transform/writer/integration. M1.6b ready. D-9 routable when M1
  pauses. DECISIONS FOR MARK: none (package PR #83 awaits a merge, as #81 did).
