# Sprint PLAYABLE-SHIP-FINISH: production-scene evidence before repair

**Status:** SF0/SF1a/SF1b approved by Mark in the attended session, 2026-11-17. SF0/SF1a headless gates pass; SF1b implementation and static/report controls pass, with the real-transit fixture queued for serialized integration qualification. SF2 and native/laptop acceptance remain open. No GPU, build or publication performed.
**Design:** [playable-ship-finish.md](playable-ship-finish.md). **Progress:** `.ailang/state/sprints/sprint_PLAYABLE-SHIP-FINISH.json`.
**Goal:** make one combined painted-ship review prove the exact scene, captain and hardware it measured, using the existing native benchmark and existing finish integration.
**Duration:** provisional 2–3 working days (JSON midpoint 2.5), ~390 implementation/test LOC. Human review, archive publication and laptop availability are excluded. This is an effort allowance with ~25% uncertainty, not measured velocity.
**Base:** design audited clean candidate `19e4a76338cb72e88e73a22790239691a72ab439`, main base `36f4ab4c4044f2d57f1b532cf298ca21c29346c5`; rebase/integrate current main at execution without discarding cockpit, AI, telescope or other delivered features. Preserve dirty authoring work in the attended checkout.
**Runtime:** AILANG v0.56.1. No `.ail` edits; syntax/contracts/effects/inline-test gate **skip**, because the work is Godot presentation/harness and glue only.

## Current status and ownership

The painted bridge, Commons, 42 static residents, native resource closure and a 405,329,291-byte local archive already exist. Existing receipts report headless integration and export success; native lighting, laptop frame cost, S3/S5 and full merge evaluation remain open. The archive is packaged, not published. These completed assets are not rebuilt or re-estimated here.

Canonical `make ship-demo-bench` and `make bench SCENE=bridge` construct the demo directly and omit the normal-entry painted installer. Extend `ShipDemoBenchmark.run(demo)` on the installed scene instead. Its existing default uploader behavior remains for existing callers; the proposed local review path must never upload.

This is an evidence overlay of **R2-VIEW-FINISH VF4**, with review rows fed back into **VF2/VF3/VFB**, **R2-LEVELS S3/S5** and **R2-CAPTAIN-ANIMATION**. It does not create another art production lane. Ship owns proposed `ShipReviewReadiness.wait(demo, timeout_ms)`; playable-voyage PV1 consumes it. Main retains civic plus physics readiness ordering.

Recent history (`git log --since='2026-11-10'`, CHANGELOG and candidate's three finish/export commits) does not expose comparable measured agent hours or art throughput. LOC/day is **unknown**. Do not turn merge dates into a velocity rate.

## Registry reuse audit

| Milestone | Decision | Evidence / reason |
|---|---|---|
| SF0 | none | No package-like capability; reuse repo-native finish installer, normal-entry metadata and existing integration test. |
| SF1a | none | Extend repo-native `ShipDemoBenchmark`/uploader boundary, no new numerical or reusable package API. |
| SF1b | none | Reuse authored views, journey inputs and profiler; Godot CLI/report glue only. |
| SF2 | none | Evidence matrix and review preparation, no package capability. |

No registry searches are needed for these non-package tasks. A newly discovered maths/simulation capability returns to design and the mandatory package reuse audit first.

## Proposed milestones

### SF0: normal-entry readiness and identity (~60 implementation + 60 tests LOC)

**Time box:** one 60–90 minute executor session, with follow-up only if explicitly resliced. **Depends on:** plan approval and clean current-main-based candidate.

- Extend `tests/test_painted_levels.gd`, add shared `demos/ship_review_readiness.gd` plus its tracked `.uid`, and wire proposed `make ship-finish-test` through `SCRIPT_GATE` in a small `mk/ship-finish.mk` include.
- Use actual main startup; wait for `painted_levels_pending` to clear, then require valid `painted_levels_result`, 141 bridge meshes, 1,000 Commons meshes and 42 residents. Return bounded `{ok, errors, identity}`; include build/closure/captain pins and source-versus-packed identity.
- Reuse rollback/restoration, body/WALK/camera and lift-round-trip checks. Add only missing normal-entry/receipt controls: stalled readiness, missing/failed closure, mismatched build/hash and premature completion. Do not sleep a guessed number of frames.
- **Acceptance:** design AC1; `make ship-finish-test` has a nonempty counted pass summary, rejects parse/runtime errors and all named negative controls. Voyage PV1 can consume the shared seam.

### SF1a: local-only profiling and trustworthy report (~70 + 60 LOC)

**Time box:** one 60–90 minute session. **Depends on:** SF0.

- Extend `demos/ship_demo_benchmark.gd` and meaningful controls in `tests/test_ship_demo_benchmark.gd` (or a companion if size merits it).
- Make local-only mode explicit; no `upload.start()` call for that path. Preserve current default-path upload behavior for existing callers and prove both with an uploader spy.
- Add production identity from SF0, actual viewport/driver/vsync/hardware, raw samples, finite counter validation and distinct validity/budget fields. Unsupported Metal timestamps are unavailable. Keep source results distinct from packed ones.
- **Acceptance:** design AC2; new `make ship-finish-profile-test` rejects absent closure, fake/insufficient samples and invalid report data; local writes trigger zero uploader calls, existing default behavior remains covered.

### SF1b: packaged review entry and reproducible phases (~80 + 60 LOC)

**Time box:** one 60–90 minute session; if route integration exceeds it, stop and reslice rather than adding repair work. **Depends on:** SF1a.

- Add proposed `--ship-finish-review=<absolute-output-directory>` routing in `main.gd` through the real normal-entry installer and shared readiness helper. Put runtime route/report detail in companion `demos/ship_finish_review.gd`, avoiding growth of `main.gd` with a second benchmark implementation; developer-only validation remains under `tools/`. Commit `.uid` companions with scripts.
- Reuse the existing profiler for disposable seeded bridge, Commons, lift, chair and real-transit phases. Assert phase/finish state; record input/camera metadata. Original-versus-painted runs use exact resource restoration and unchanged geometry. Reject headless timing as native performance evidence.
- Add proposed `make ship-finish-review-report REPORT=<path>` validation for recorded identities, windows, required phases and repeat data for misses. It reports missing laptop/Mark evidence explicitly, and cannot produce an acceptance verdict from an empty template.
- **Acceptance:** AC2 plus headless route/report controls. A valid fixture passes; incomplete closure, missing phase and fake hardware confirmation fail. Native laptop commands are prepared, not executed on the training host.

### SF2: evidence matrix and independent evaluation (0 code LOC)

**Allowance:** 0.5–1 day preparation/evaluation, with review availability outside the estimate. **Depends on:** SF1b.

- Prepare one unfilled, build-pinned native review matrix covering existing S3/S5, VF2/VF3/VFB and captain contact/facing/reduced-motion rows. Inventory the production captain manifest/stage; do not infer installation from v5–v7 art folders or resume the parked rig.
- Document exact laptop command, expected local outputs and original/painted conditions. Keep prior archive, new code-bearing candidate and remote channel state separate. No automatic upload, publication or full GPU rerun belongs to this milestone.
- Run focused regression commands below and obtain the required different-family evaluation. Record native/laptop and publication gates as pending unless actual evidence arrives separately.
- **Acceptance:** plan produces review-ready artifacts and independent evaluation, not automatic S3/S5 or laptop acceptance. Every conditional defect is assigned to the original owner; no speculative fix or more than one proposed ~200 implementation + ~100 test LOC follow-up per diagnosed cause.

## Sequence and validation

| Working slot | Work | Stop condition |
|---|---|---|
| 1 | SF0 readiness/closure | Passing focused gate and real negative controls; hand shared seam to PV1. |
| 2 | SF1a local report boundary | No-uploader and preserved-default behavior verified. |
| 3 | SF1b packaged route/report | Prepared native command plus headless route/validator controls; no GPU measurement. |
| 4 | SF2 focused regression, evidence matrix, independent evaluation | Review-ready handoff with unresolved laptop/Mark/publication rows explicit. |

Focused executor gates (not run in this planning session):

```sh
PATH="$PWD/runtime/bin:$PATH" make ship-finish-test ship-finish-profile-test
PATH="$PWD/runtime/bin:$PATH" make captain-anim-test captain-frames-check captain-chair-test bridge-operator-test
PATH="$PWD/runtime/bin:$PATH" make camera-test camera-forward-test level-runtime-test commons-civic-playtest-test ship-demo-lift-test
make uid-guard
git diff --check
```

The first two targets are **new deliverables**. Gate names must be wired before claiming these commands exist. GitHub owns `make ci-fast`; inspect main nightly status separately. No full `make test`/`make golden` rerun is a milestone quick gate. No new SR/GR visual is proposed; a later physics/lighting repair must add its own spec/golden/opened-reference evidence under CLAUDE.md.

Prepared **future laptop** command, after a separately authorized code-bearing archive exists:

```sh
SHIP_BINARY_NAME=$(defaults read "$APP/Contents/Info.plist" CFBundleExecutable)
SHIP_EXE="$APP/Contents/MacOS/$SHIP_BINARY_NAME"
"$SHIP_EXE" -- --ship-finish-review="$REVIEW_OUT"
make ship-finish-review-report REPORT="$REVIEW_OUT/report.json"
```

`APP` and `REVIEW_OUT` denote the actual installed archive path and a writable local output directory. This new argument is not present in the current archive. Existing `./tools/install_review_build.sh --dev` remains the installation workflow once publication is separately resolved. Do not run an in-app button that auto-uploads as a substitute for the local-only path.

## Human gates, dependencies and cut line

**Approval recorded:** Mark approved SF0/SF1a/SF1b in the attended session on 2026-11-17. These implementation slices proceed without another milestone approval. SF2's independent evaluation and native acceptance are not claimed complete.

The native laptop session is design OQ1; actual appearance verdicts are OQ2 and original S3/S5/CA review gates; outstanding external publication is OQ3. They do not block independently useful headless harness work **after** sprint approval. At their boundary, STOP: commit only approved current task work under project policy, report `BLOCKED: <specific pending native review or delivery action>`, and end the executor run. Do not mark those acceptance rows complete or retry an external action rejected by automatic approval review without resolved authorization.

Settled rulings are retained, not reopened: one combined app (shared D-152), no local GPU while training (D-151), painted candidate review (shared D-158), unchanged D-127/D-147 budget/control rules, existing 2.2 m/s pace and reduced-motion behavior. Dirty art prototype decision labels are provenance, not replacements for shared main's decision IDs.

**Cut line:** no asset generation, geometry optimization, shader repair, captain production replacement, new stage/age art, population simulation or upload. A measured defect produces a bounded proposal under its existing sprint; exceeding a session/LOC cap causes reslicing, not silent expansion. No canon change or AILANG code is planned.

## Success metrics and deliverables

The sprint succeeds when the actual production scene is identified before profiling, local review cannot upload, validators reject incomplete/stale evidence, focused regressions and independent evaluation pass, and Mark receives a single concrete native review package. Laptop performance and S3/S5 completion remain separate evidence-dependent outcomes. The representative working example is the packaged normal-entry review argument, with a deterministic headless report fixture and failure controls; no artificial example module is needed.

At execution, update existing sprint progress/evidence links rather than duplicating completed art milestones. Maintain this sprint JSON, the design verification log and a concise execution report. Planning approval is required before all implementation work.

## Execution evidence, 2026-11-17

- [x] SF0: shared bounded readiness and counted normal-entry/geometry tests; final readiness **14/0**, existing invariants **1,168/0**.
- [x] SF1a: local-only file writes/no-uploader controls **15/0**; legacy benchmark **3/0**.
- [ ] SF1b: implemented main review argument, same-scene original/painted sampler reuse, phase inputs, longer miss repeats and report validator. Report controls **14/0**, static actual-world phase wiring **17/0**, real main headless refusal returns expected **2**. `ship-finish-route-live-test` remains to qualify the real sidecar sequence after the voyage agent releases the serialized slot; `passes` remains null until that check.
- [ ] SF2: independent evaluation, laptop/native review, Mark's S3/S5/CA verdicts and publication remain open.

Exact commands, red-to-green evidence and limits: [execution report](playable-ship-finish-execution-report.md). Parent integration must include `mk/ship-finish.mk`; until then invoke these targets with `make -f Makefile -f mk/ship-finish.mk ...`.
