# Playable voyage acceptance: one complete journey in the combined ship

**Status:** Approved PV1–PV3 implemented and locally qualified, 2026-11-17. PV4 human acceptance and remote landing remain open.
**Release:** r1 acceptance · **Milestone:** new; the roadmap has no separate row.
**Priority:** P1. Establishes what “playable” means for the combined painted review candidate.
**Implements:**
- [R1 foundations, M4 acceptance](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md#m4-first-journey-a-vertical-slice), as implemented by [m4-first-journey.md](m4-first-journey.md): an irreversible outbound and return journey, clocks, news and voyage log.
- [Core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md), [journey system](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md) and [ADR 0001](https://github.com/sunholo-data/stapledons-design/blob/main/decisions/0001-engine-and-architecture.md).
- Existing [relativity specification §2/§4](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) and [Higgs bubble §3/§11](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md); no new maths, physics visuals or package API.
**Depends on:** the reconciled combined painted ship, including cockpit/AI-panel work and current main; the ship-finish plan owns normal-entry readiness, native appearance, art and packaging. AILANG v0.56.1; current sim pins include relativity 0.12.0, observe 0.1.0 and crew_core 0.6.0. No dependency bump proposed (V1–V4).
**Estimated:** ~310 changed lines of test/fixture/report work, four bounded work packages; no gameplay code budget. See [sprint](playable-voyage-acceptance-sprint.md).
**Planning evidence:** read-only audit on 2026-11-17. Game authoring checkout `f3aa83bf4120fb6f57d858129dd9bada59ed91b4` is dirty; clean painted candidate `19e4a76338cb72e88e73a22790239691a72ab439`; local canon `c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa`. No runtime tests, GPU work, builds or publication were performed during that planning audit. Subsequent approved execution is tracked in the sprint and its separate report; code presence alone is not a green test result.

## Game vision alignment

Feature validation uses `game-vision-designer` and the canon's six pillars.

| Pillar | Relevance | Score | Concrete contribution |
|---|---|---:|---|
| Choices Are Final | ++ | +2 | Exactly two committed legs in one session; attempted re-plan/cancel in transit must be refused. No save, reload or undo. |
| The Game Doesn't Judge | + | +1 | Home news and the voyage log present elapsed time and events; no success score, moral label or invented ending. |
| Time Has Emotional Weight | ++ | +2 | Read both clocks before departure, news away, and news/log after returning to an older home. |
| The Ship Is Home | + | +1 | Complete the trip through the actual combined bridge consoles; separately visit painted Commons and return by lift during human review. |
| Grounded Strangeness | + | +1 | Retain catalogue destination, live sky and existing checked physics; no artificial journey spectacle. |
| We Are Not Built For This | 0 | 0 | Existing crew remains present, but this short slice makes no new psychology or emotional-effect claim. |
| Hard sci-fi authenticity (spec) | ++ | +2 | Sim owns clocks and commitment; display audit and replay provide independent evidence of their presentation and determinism. |
| **Net** | | **+9** | **Go for planning. Execution awaits plan approval; human acceptance remains a separate recorded result.** |

## Problem

The round trip is designed and substantially implemented already. `tests/playthrough_min.json` walks to Navigation, commits to alpha Cen A, reads news there, commits home and reads the log (V5). Writing another journey system would duplicate M4.

The missing deliverable is a single, current evidence chain from an identified combined candidate to a completed voyage and an honest product verdict:

1. Existing headless playthroughs press the title's New game button and use real consoles/sim, but disable sky/background/AI, control frames and invoke console actions through methods. They demonstrate integration, not player discovery, native appearance, sound quality or actual elapsed human time (V6).
2. The historical minimal script reads no news after returning home. Add an explicitly named complete-voyage fixture and final-state evidence without silently rewriting the frozen scene replay or its SHA (V5/V8).
3. The clean painted candidate installs both finishes in normal entry. Its startup awaits civic art and two physics frames; the existing journey harness waits only one process frame after New game. This is a source-level readiness risk, not a reproduced failure. The harness must consume the ship plan's shared ready contract before disabling processes or recording evidence (V7).
4. The proxy uses walking distance / 3.5 m/s; actual shared movement is 2.2 m/s under D-138. The historical M4 amendment explicitly used 3.5. Preserve and label that synthetic result; do not describe it as current human duration (V9).
5. The authoring checkout and candidate have different ledger numbering: the same 2026-11-13 “looks geat … playable demo … other deck” ruling is D-165 in the dirty checkout and D-158 in candidate `19e4a763`. Cite the words/date and source pin until the attended tracker reconciles them (V3/V10).

Historical R1 did **not** require a successful fresh-player test: D-14 replaced it with a scripted minimum-path proxy and moved the three-new-player exercise to R2. A human product review below is a **new recommendation**, not a retroactive gate or an allegation that M4 failed its original contract (V11).

## Goals and non-goals

**Goal:** one bounded, reproducible Sol → alpha Cen A (`CNS5:3627`) → Sol voyage, from normal New game to home news and the voyage log, on the same combined ship that Mark can review.

Completion means a round trip and its consequences are visible. It does not mean the captain's 100-year story, Earth's ultimate fate, the opening black-hole sequence, a civilisation campaign or the million-year epilogue is complete. The [canonical premise and loop](https://github.com/sunholo-data/stapledons-design/blob/main/vision/premise-and-loop.md) remains larger than this slice.

No new story, lore, destination, route, economy, resource enforcement, dialogue requirement, camera system, movement mechanic or save/reload. Live providers are optional; the baseline works offline on authored text. Crew, comms and guided-voyage checks are compatibility checks on already implemented features, not extra steps in the six-minute minimum route. No local GPU work while the standing training restriction applies.

## Design

Use the existing sim and console flow, strengthen only the acceptance evidence, and hand the same candidate to human review.

### 1. Preserve the established boundaries

Package maths, pure sim, NDJSON protocol and renderer remain unchanged. Physics remains package-first, float64 where required, with sim-provided gamma and one-minus-beta; no test helper computes substitute physics. Keep `sim/core.ail` pure, I/O in `sim/ship.ail`, and replayed AI outputs recorded as inputs (D-7). No new protocol field or `.ail` edit is planned.

Existing RS/HB checks and golden evidence remain the physics gates for the features they cover; headless voyage evidence does not certify a rendered sky. Any later SR/GR change needs the existing check-value, GPU comparison and inspected-reference requirements under CLAUDE.md. This plan does not authorize such a change or a GPU run.

### 2. Reconcile and identify the candidate (PV1)

Start execution from a clean integration checkout after its owner incorporates current main and the agreed combined ship changes. The audited clean candidate descends from local `origin/main` `36f4ab4c4044f2d57f1b532cf298ca21c29346c5`; this is a local ancestry observation, not proof of current remote main (V2). Refresh PR overlap and remote ancestry before selecting the execution pin.

Record source SHA, base SHA, clean/dirty status, runtime version, sim lock hash, painted manifests, chosen script hash and platform. Never transplant or clean up another agent's dirty art tree. A later source/asset change invalidates corresponding old evidence; retain it as historical.

The ship-finish work owns the proposed `demos/ship_review_readiness.gd` helper, `ShipReviewReadiness.wait(demo, timeout_ms)`, returning `{ok, errors, identity}` after normal-entry pending clears and the installed result/production closure validate. This is a proposed API, not existing code. The journey harness consumes it and asserts successful combined installation before disabling engine-driven updates, starting controlled traversal and collecting its first accepted frame. Use a bounded wait with an explicit failure reason. Main keeps ownership of civic/two-physics-frame ordering. Avoid a second independent startup implementation. PV1 stops if the combined dependency is unavailable.

### 3. A small, explicit complete-voyage fixture (PV2)

Create `tests/playthrough_complete_voyage.json`, preserving `tests/playthrough_min.json` and `tests/replays/scene/m4_scene_session*`. Reuse every existing console action:

| Beat | Player-facing result | Automated witness |
|---|---|---|
| Title → New game | Combined ship at rest, existing live clocks | Normal-entry readiness and painted installation metadata; one new_game |
| Navigation → alpha Cen A | Plan shows cruise and both clock costs; hold commits | Console intent and accepted sim plan; first commit |
| Boost → cruise → brake → arrival | Ship reaches the chosen star | Existing phase, target and pole checks; final sim state |
| Archive → News | Read delayed news from home | Visible header/body read event at destination |
| Navigation → Home → hold | Return is a second irreversible decision | Home-plan intent and second commit |
| Boost → cruise → brake → Sol | Return completes | Arrival at Sol; current sim state at rest |
| Archive → News → Voyage log | Home has aged; this voyage's entries and closing line are readable | Second news read at Sol, log read at Sol, nonempty entries/closing line |

Add test-only completion assertions, enabled by the new fixture: exactly two commits in the sole session; required reads in order at the expected locations; final arrival at Sol with no committed leg; all three phases on each leg. Record location/tick on read witnesses so two reads at the same destination cannot masquerade as return-home news. Use existing sim fields and event evidence, not hard-coded catalogue distance or elapsed years.

Extend the existing negative harness with three named failures: missing return, missing home news, missing final log. Each must fail for its completion reason, not a parse error, timeout or missing resource. These checks validate the advertised endpoint; they do not test the implementation line by line. If `m4_playthrough_ship.gd` approaches the project size limit, put the completion accumulator in a test companion file with its `.uid`.

### 4. Evidence levels and compatibility (PV3)

| Level | Meaning | Current audit status |
|---|---|---|
| Implemented | Source and fixtures exist at a named pin | Existing round trip and clean candidate's painted normal entry inspected; new completion contract not implemented |
| Verified | Named commands passed at the exact candidate pin, with retained logs/artifact hashes | **Not established by this planning audit**; historical reports remain historical |
| Human accepted | Named person used that exact build and accepted the stated experience/surfaces | **Not established**; neither CPU studies, earlier art direction approval nor a passing headless test implies this |

Run the minimal route once in AI=none and audit its session, then the new complete fixture. Keep the two outputs separate. Existing adversarial, no-twitch, crew, comms and guided-review checks protect already delivered features; stub/digits checks prove fallback and recording without requiring keys. Run targeted checks on the reconciled candidate, not separately on each feature branch and then assume the combination passes.

Record proxy timing as synthetic: `sceneTime` currently sums transit ticks at 0.05 s, 200-word/min reading, console/hold allowances and path length / 3.5 m/s; it requires total ≤360 s and each leg 45–120 s. Do not change thresholds, walking divisor or the historical golden in this work. Human elapsed time is observed independently, with no proposed pass threshold (OQ2).

### 5. Proposed human product review (PV4; OQ2)

After technical qualification and the ship plan's review build, recommend one attended laptop session by Mark. Start from the normal title and complete the table above through normal controls, with live sky/sound and usual settings. Read the two clocks before commitment; describe what changed at home after return. Then visit Commons, recognise painted residents/crew, use the lift back to the bridge, and verify Navigation, Archive, Crew and comms remain accessible. This brief exploratory appendix is outside the minimum-path timing proxy.

Record build/source/archive hashes, reviewer, date, display/scaling, input mode, completed beats, observed elapsed time, interventions/blockers, and separate verdicts for voyage usability, native painted appearance, sound and performance. “Accepted with named limitations” must list those limitations; silence leaves human acceptance pending. No general assertion of three-new-player acceptance or emotional impact follows from one owner's session.

Existing visual/audible dev-build approval and S3/S5 art approvals remain owned by their current plans. This recommendation does not supersede them. The new voyage review does not authorize a build, publication or installation during this planning turn.

## Acceptance criteria

All commands below are **future execution checks**, not results of this audit. Run in the reconciled candidate, with `export PATH="$PWD/runtime/bin:$PATH"` and `export AILANG_BIN="$PWD/runtime/bin/ailang"`. Godot version follows the selected candidate. Separate logs must identify source SHA and command; an interrupted/missing run is pending.

| # | Criterion | Exact command / witness |
|---|---|---|
| AC1 | Existing title/console flow, live navigation and irreversible controls remain green | `make title-screen-test ship-console-test ship-demo-live-test no-twitch-test playthrough-adversarial playthrough-negative` |
| AC2 | Historical minimal session and its original timing/unlocks/display audit remain green | `env -u AI_LIVE make scene-session-audits AI=none SCRIPT=tests/playthrough_min.json PLAYTHROUGH_OUT=.godot/tmp/playthrough/voyage-min DISPLAY_SAMPLES=.godot/tmp/playthrough/voyage-min/display_samples.ndjson` |
| AC3 | Complete fixture includes installed painted ship, both arrivals, all phases per leg, home news and log in one session | **After PV2 exists:** `env -u AI_LIVE make playthrough AI=none SCRIPT=tests/playthrough_complete_voyage.json PLAYTHROUGH_OUT=.godot/tmp/playthrough/voyage-complete`; positive summary and explicit completion assertion line |
| AC4 | New endpoint assertions reject the three incomplete routes for their declared reasons | **After PV2 extends it:** `make playthrough-negative`; retain named missing-return/home-news/log failures and final positive controls summary |
| AC5 | New complete session's visible bindings agree with sampled sim state | `make display-audit DISPLAY_SAMPLES=.godot/tmp/playthrough/voyage-complete/display_samples.ndjson` after AC3; no unaccepted additions to known-findings |
| AC6 | Existing replay remains pinned and deterministic; strict core/parity remain green | `env -u AI_LIVE make replay-scene strict parity-m4`; new AC3 log compared with the fresh-recording parity block below (no golden recording) |
| AC7 | Already delivered crew/comms/review and authored/AI fallback paths survive combination | `env -u AI_LIVE make crew-console-test comms-station-test display-audit-crew display-audit-comms display-audit-interlude playthrough-ai-modes` |
| AC8 | Combined ship readiness, lift, camera and route checks pass at the same SHA | Ship plan's shared readiness check plus `make levels-regress camera-test camera-forward-test comms-walk-test captain-chair-test captain-command-test`; painted install and export evidence linked from ship plan, not re-created here |
| AC9 | Evidence records distinguish implementation, verification and human acceptance | **After report exists:** `jq -e '.source_commit and .base_commit and .runtime_version and .script_sha256 and .automated_checks and .human_review.status' art/playable-voyage-review/evidence.json`; inspect linked logs/hashes; validation of a record is not validation of a person's judgement |
| AC10 | Recommended product review has an explicit disposition if adopted | Normal-launch review command `make run`; report links the exact installed ship-plan artifact and attended notes. `jq -e '.human_review.status == "accepted" or .human_review.status == "accepted_with_limitations"' art/playable-voyage-review/evidence.json` checks recorded disposition only; Mark supplies the judgement. If declined, record `not_requested` and do not claim human acceptance |

Fresh-recording parity for AC6 uses the current sim shell on the new input log; `make replay SESSION=...` requires an existing golden and is not suitable for an unrecorded fixture. Run these commands sequentially and require both producer exits and `cmp` to succeed:

```sh
set -eu
mkdir -p .godot/tmp/playthrough/voyage-replay
env -u AI_LIVE runtime/bin/ailang run --quiet --bytecode --package-dir sim --caps IO --entry main sim/ship.ail < .godot/tmp/playthrough/voyage-complete/session.ndjson > .godot/tmp/playthrough/voyage-replay/vm.ndjson
env -u AI_LIVE runtime/bin/ailang run --quiet --package-dir sim --caps IO --entry main sim/ship.ail < .godot/tmp/playthrough/voyage-complete/session.ndjson > .godot/tmp/playthrough/voyage-replay/interpreter.ndjson
cmp .godot/tmp/playthrough/voyage-replay/vm.ndjson .godot/tmp/playthrough/voyage-replay/interpreter.ndjson
```

Follow CLAUDE.md for landing: GitHub `ci-fast`, changed-area targeted gates and cross-family evaluation; main's nightly full suite remains authoritative. No per-PR full GPU suite or loaded-host reruns. Publishing rules belong to the ship integration/build owner; any dev tag still requires its prescribed local full-test precondition. This plan does not waive it.

## Sub-milestones and estimates

| Package | Concrete work / likely files | Estimate | Dependency |
|---|---|---:|---|
| PV1: candidate and startup witness | Pin baseline; consume shared ready seam in `tests/m4_playthrough_ship.gd`; initial evidence manifest | 60 lines; 60–90 min | Combined ship readiness available; OQ1 |
| PV2: complete-voyage contract | New JSON fixture, test completion companion if needed, read witnesses, three negative fixtures, `tests/test_playthrough.sh` | 150 lines; 60–90 min coding + bounded run time | PV1 |
| PV3: qualify and report | AC1–9 logs, hash manifest and concise report; compatibility checks; independent evaluation | 60 lines report; 60–90 min preparation plus actual command durations | PV2; shared ship checks |
| PV4: human disposition | Recorded review checklist/findings; no runtime change | 40 lines; 30–45 min session plus review scheduling | PV3, ship review artifact; OQ2 |
| **Total** | No new gameplay or art production | **310 lines; ~4–6 engineering hours plus test/review waits** | No calendar completion promise |

Stop this acceptance sprint on a runtime blocker, capture reproduction/source/command and create a separately reviewed bounded fix proposal. Do not turn a qualification task into an open-ended polish sprint. Resume only after the fix lands and the affected evidence is rerun.

## Risks and mitigations

- **Ready-state race:** consume the ship plan's shared readiness contract, verify installed finishes before first accepted frame, and retain bounded failure output. Source inspection has not proved this race occurs in practice.
- **Candidate drift:** all command/build/manual evidence must use the reconciled pin; do not mark `19e4a763` as current remote main or as already accepted.
- **Proxy misread as usability:** preserve D-14's synthetic gate, expose the 3.5/2.2 difference, record actual human time separately. Updating the auditor is a separate scoped change if requested.
- **Test load:** existing script gate supplies deadlines; report a timeout as unverified. No unbounded retries, weakened thresholds or ignored failures.
- **Frozen replay churn:** new fixture and output directory; no `replay-scene-record` or fixture regeneration in this sprint.
- **Native/GPU uncertainty:** source/headless tests cannot settle appearance, frame pacing or sound. Existing ship-plan and attended laptop evidence own those conclusions; no local GPU work is authorized here.
- **Open PR overlap:** both `gh pr list` calls failed to connect during audit. Refresh before implementation; do not invent a clean PR inventory.

## Open questions for Mark

1. **OQ1 — RESOLVED: PV1–PV3 approved**, Mark, attended 2026-11-17: “approved lets go”. The combined baseline is reconciled through integration `ec415f33` (upstream main `ae5394dd`) plus shared ship readiness SF0. This ruling authorizes the bounded headless execution; it is not a fresh permission gate and does not accept PV4/native appearance or authorize publication.
2. **OQ2 — Adopt one attended complete-voyage product review of the combined laptop build?** Recommendation: yes, as a new owner review with observed timing and named limitations; keep D-14's R1 proxy and defer the three-new-player study to its existing R2 scope. Requiring three fresh players now adds recruitment and a distinct study; declining leaves human voyage acceptance unclaimed. **Default if unanswered:** recommendation pending; no claim of acceptance and no added historical R1 gate.

No design-repo change is required for this acceptance overlay. An amendment to R1's bar, a new timing threshold or campaign completion would require an explicit canon/roadmap decision and is outside this proposal.

## Deliverables

- This design, matching sprint and `sprint_PLAYABLE-VOYAGE-ACCEPTANCE.json`: PV1–PV3 approved; PV4 pending.
- After approval: new complete-voyage test fixture and completion checks, targeted evidence manifest/report, linked shared ship/build evidence, independent evaluation and explicit human disposition.
- Landing updates belong to execution after review; no README index, ledger, changelog, existing sprint or canon file is changed in this planning task.

## Verification log

Source reads only unless stated. `G` = authoring HEAD `f3aa83bf4120fb6f57d858129dd9bada59ed91b4`; `P` = clean painted candidate `19e4a76338cb72e88e73a22790239691a72ab439`; `C` = canon `c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa`. Uncommitted authoring facts are explicitly separated below.

| # | Claim | Command run | Result |
|---|---|---|---|
| V1 | Audited authoring checkout and package pins | `git rev-parse HEAD`; `git status --short`; `cat sim/ailang.toml`; `sed -n '1,20p' Makefile` | G, branch `feat/captain-command`, dirty tracked sprints/ledger plus untracked art/helpers; AILANG 0.56.1 and package pins named above. Read only, no versions executed. |
| V2 | Separate candidate is clean, integrates newer local main and installs paints normally | `git -C ../stapledons-godot-painted-levels status --short`; `git -C ../stapledons-godot-painted-levels rev-parse HEAD`; `git -C ../stapledons-godot-painted-levels merge-base HEAD origin/main`; `sed -n '97,124p' ../stapledons-godot-painted-levels/main.gd` | Clean P; merge base and local main `36f4ab4c4044f2d57f1b532cf298ca21c29346c5`; normal entry installs and stores painted result after civic readiness/two physics frames. No run performed. |
| V3 | Dirty authoring facts must not stand in for candidate facts | `rg -n 'D-165' design_docs/stapledon-mission.md`; `git ls-files demos/painted_levels_finish.gd assets/levels/painted`; `shasum -a 256 design_docs/stapledon-mission.md demos/painted_levels_finish.gd` | Authoring helper/assets untracked; dirty ledger SHA `b510dacf568a3388e5c9b90f5b564fd5222032c7bb396612b94aacbe54f6fae2`; helper SHA `2d28fb308e7225b4eae5f805c36b20f7cbec6f902e4831a90903ceaf559397a0`. G alone does not identify those contents. |
| V4 | Architecture/physics constraints | Read `CLAUDE.md`, design skill, README, C's ADR 0001, relativity spec and Higgs-bubble spec | Godot presents, pure AILANG sim owns rules; maths package-first; no formula change needed. |
| V5 | Existing minimal/adversarial paths | `cat tests/playthrough_min.json tests/adversarial.json`; `rg -n 'func use|func read|func session_check' tests/m4_playthrough_ship.gd` | Outbound alpha Cen, news, return Sol, log; no return-home news step. Adversarial selects another target/cancels/recommits during cruise expecting `committed`. Source exists, not newly verified. |
| V6 | Harness is controlled integration evidence | `sed -n '433,520p' tests/m4_playthrough_ship.gd`; `sed -n '126,224p' tests/m4_playthrough_ship.gd` | Seed 424242; title button emitted; stars/background/AI disabled; process updates disabled then controlled frames; API walk/use; visible read assertions. No native viewport proof. |
| V7 | Candidate startup and harness readiness mismatch | `rg -n 'painted|pending|await_civic|ready_ok' ../stapledons-godot-painted-levels/main.gd ../stapledons-godot-painted-levels/tests/m4_playthrough_ship.gd` | P startup sets pending and clears it after successful install. Harness still waits one process frame and checks ready_ok only. Possible race not executed/reproduced. |
| V8 | Existing checks and frozen scene provenance | `cat mk/m45.mk`; `sed -n '1415,1436p' Makefile`; `cat tests/test_playthrough.sh`; `sed -n '466,479p' Makefile`; `rg -n 'session\|golden' tools/replay.py` | Named playthrough/audit/replay targets, bounded script gate, separate frozen scene fixture/SHA; three existing negative fixtures. `make replay SESSION=` still requires a golden; new-log parity uses direct producers/compare. No targets run. |
| V9 | Synthetic time differs from current movement pace | `sed -n '20,75p' sim/tools/session_audit.ail`; `rg -n 'WALK_SPEED_MPS' demos/ship_consoles.gd`; `rg -n 'AC7|3.5' design_docs/planned/r1/m4-first-journey.md`; ledger D-138 | Auditor divides distance by 3.5, current movement 2.2; total ≤360 and leg 45–120 checks. Historical design explicitly charges 3.5. No duration measured. |
| V10 | Same attended paint request has different labels | `rg -n 'looks geat|playable review' design_docs/stapledon-mission.md ../stapledons-godot-painted-levels/design_docs/stapledon-mission.md` | 2026-11-13 request is dirty D-165 and P's D-158; both preserve strict physics/routes/live lighting and no local GPU use. |
| V11 | Human test historical scope | Ledger D-14; C's `roadmap/r1-foundations.md` M4 acceptance; `m4-first-journey.md` Goals/non-goals | R1 scripted proxy; three-new-player study moved to R2. New human review is recommendation OQ2. |
| V12 | Art/manual approvals remain distinct | Read dirty `bridge-commons-finish-sprint.md` and implemented `m4-unified-painted-ship.md`, `m4-ship-live-journey-review-report.md` | Prior art direction, technical checks and historical native reports exist; pending S3/S5/native performance are not completed by this audit. |
| V13 | Open PR inventory unavailable | `gh pr list --repo sunholo-data/stapledons-godot`; `gh pr list --repo sunholo-data/stapledons-design` | Both failed connecting to api.github.com. No current PR status asserted. |
| V14 | Estimates have no measured team velocity | `git log -10 --date=short --format='%h %ad %s'`; `git log --since=2026-11-10 --until=2026-11-18 --no-merges --format='%h %ad %s' --date=short -- tests tools mk`; read recent CHANGELOG | Recent work contains merges, ledger changes and small guard fixes; no comparable elapsed engineering-time sample. Estimates are work-package budgets, not LOC/day extrapolation. |
