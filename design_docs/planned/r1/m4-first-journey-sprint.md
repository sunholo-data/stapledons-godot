# Sprint plan: R1-M4-JOURNEY, the first journey vertical slice

**Status:** Proposed by mission-stapledon iteration 11; NOT approved — awaiting Mark.

## Summary

Make the game a game: bridge at Sol → galaxy map → commit α Cen → boost →
cruise 0.99c → brake → arrival → light-delayed news → home → legacy log,
played inside the composited iso interior with the live relativistic sky,
the ISM readout and the forward glow, and the Archive codex whose every
number is pinned to `sunholo/relativity` by `make lore-check`.

**Design doc:** [m4-first-journey.md](m4-first-journey.md) (AC1–AC18; passed
the design quorum in round 2 via the narrow-refinement carve-out,
`.ailang/state/mission-quorum/m4-first-journey-2026-10-03T04-12-08Z.json`).
**Sprint ID:** `R1-M4-JOURNEY` · **Progress file:**
`.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`.
**Duration:** 10 milestones in 4 waves, then the S1 gate and landing. That
is **~20–24 h of attended execution (~3 days)**, or **~4–6 days on the
6-hourly loop** (10 + 2 contingency iterations), plus Mark's review time at
S1 and S4 and the external-dependency waits below. Velocity is below.
**Risk level:** Medium. The design is unusually well pinned (every number is
a named package call at a verified 0.5.1 export, V12–V25); the real risks
are the two unlanded sibling sprints, the GPU gates CI can't run, and one
over-cap milestone (F1).

**Quorum note.** The design quorum's round 2 ran with **gpt6-1-sol ABSENT**
(unreachable); the round-2 disposition (the narrow-refinement carve-out)
rests on the three present external reviewers (oc-kimi-k3, gemini-3-1-pro,
oc-glm-5-3) with that seat empty. This first carve-out use is surfaced to
Mark here and again in the M4 report at ⏸ P-land.

**Command legend.**
- `$A` = `/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
  AILANG **v0.51.0** (Makefile `AILANG_RELEASE`, CI and the lockfile move
  together; a fresh worktree runs `make runtime` first). Every make line
  passes `AILANG=$A` (and `AILANG_BIN=$A` where the target drives Godot).
- `$PKG` = a **fresh clone** of `sunholo-data/ailang-packages` at
  `origin/main`, `packages/relativity`. Never the dirty local copy (the
  M1.2b-WD / M2.0 / M1.P precedent).
- `$D` = the sibling checkout `../stapledons-design` (private), pinned at
  `1ef3bc9` for the lore import (V16, V22).
- `$(SCRATCH)` = the session scratch dir the playthrough targets write to.
- GPU gates (`make golden`, `make capture-m4`, `make bench`) run on the
  Studio's GPU window, not in CI. Logs and renders attach to the sprint
  notes for the evaluator.

## Current status (verified against git and the sprint JSONs, worktree HEAD `8a20112`)

| Item | State | Evidence |
|---|---|---|
| M2 journey core (protocol v2, planner, commit rule, replay, galaxy map, drag ledger) | ✅ landed | `design_docs/implemented/r1/m2-journey-core.md`; `sprint_R1-M2-JOURNEY.json` all 10 `passes: true` |
| `sunholo/relativity` 0.5.1 (all trip/ISM/mean-glow functions by name) | ✅ pinned | `sim/ailang.toml:17`; V12/V15 exports |
| M1.4 background sky | ✅ landed 2026-10-01 | PR #16 (V20) |
| M1.6b free-look camera + off-axis golden | ✅ eval passed; merge awaits Mark's R-a | `sprint_R1-M1-SKY-2.json` `passes: true` (F2) |
| M1.3 star rendering v2 (rebase) | ⏳ open PR **#67** | `git ls-remote origin refs/pull/67/head` = `257d8cf` "M1.3 eval round 1 fixes" (F3) |
| M1.2d bright tier (α Cen A/B astrometry, D-19) | ⏳ open PR **#69** | `refs/pull/69/head` = `e42d660` "eval: M1.2d round 1 — 88/100" |
| M1.5a photometric exposure | ⏳ not started (wave 5 of R1-M1-SKY-2) | `sprint_R1-M1-SKY-2.json` `passes: null` |
| AI foundation AI.1–AI.6 | ✅ passed | `sprint_R1-AI-FOUNDATION.json` |
| AI.7 relay/cache e2e | ⏳ open PR **#68** | `refs/pull/68/head` = `50b1c8f` "eval: AI.7 round 1 — 90/100" |
| AI.8, AI.9, AI.10a, AI.10b | ⏳ open | `sprint_R1-AI-FOUNDATION.json` `passes: null` |
| Bridge style frame v1 | ✅ approved for build-out (D-16); **S2 satisfied** | design doc §M4.2 |
| Bridge v1 Blender bundle | ⏳ not delivered; a Blender agent builds it (brief §7 step 2) | design doc §Order |
| Design-repo lore at `1ef3bc9` | ✅ sibling present (10 entries + README) | `ls $D/lore/archive`; V16, V22 |
| AILANG pin | v0.51.0 | `$A version` |

### What can start NOW vs what waits

**Startable now (the doc's Track A, plus M4.0 and M4.6a):** M4.6a, M4.0,
M4.1 — all three have no unlanded dependency (M2 is landed). M4.1's
`glow_pole_w_m2` is **step 2**, a separate later step gated on M4.6a's
publish (⏸ P-pkg); it is not part of what starts now. M4.6a and M4.1 are
**not** file-disjoint — M4.6a bumps `sim/ailang.toml`, `sim/ailang.lock`
and the bundled `runtime/cache` that M4.1 builds against — so they land in
sequence: M4.1's PR (step 1, at pin 0.5.1) merges **first** and touches
none of those three; the pin bump lands in its own commit after ⏸ P-pkg;
M4.1 step 2 follows as a small follow-up on the bumped pin. After them:
M4.3a → M4.4 ∥ M4.7 → M4.5, and M4.6's **ungated** half (CPU physics tests,
`lint-precision`) once M4.0 + M4.1 + M4.6a exist.

**Must wait:** M4.2 needs M1.3 (PR #67) and M1.5a (not started) — the
composite's starfield layer and the glow's photometric exposure. M4.3b
needs M4.2. M4.6's **gated** half (G-M4-1..4, `capture-m4`, bench) needs
M4.2/M4.3b and M1.6b's merge. Track B's start date is therefore set by
R1-M1-SKY-2, not by M4 (F5). The AI path (M4.4) is soft under D-8: if
R1-AI-FOUNDATION slips, M4 ships with no AI process and AC6's `digits` case
uses an injected fixture.

### Velocity (this repo)

| Sprint | Milestones | Wall clock | Evals | Counted LOC |
|---|---|---|---|---|
| R1-M1-SKY iterations 0–8 (unattended loop) | 9 items | 5 days | 85–98 | 130–670 each; estimate ratio 0.6–2.7× (median ~1.0) |
| **R1-M2-JOURNEY** (attended, parallel executors, 650 cap) | **10** | **~13.5 h** (2026-10-01 18:40 → 10-02 08:07 UTC) | **89–96** | ~5,000 lines vs ~3,400 estimate (~1.5×) |
| R1-M1-SKY-2 / R1-AI-FOUNDATION (in flight) | — | — | 88–90 so far | — |

Planning figures:
- **Cap:** 650 counted code + test + config LOC per milestone (fixtures,
  goldens, vendored lore, renders and generated data don't count). **One
  exception: M4.1 is estimated at 700** (F1) — approval of this plan
  includes the waiver-or-split note there.
- **Pace:** ~2 h per milestone including independent evaluation
  (generator ≠ judge), in waves of mostly disjoint files. M4 adds GPU gates and a
  package publish the loop already knows how to do (M1.P, M2.0 precedent).
- **Total:** 3,220 counted LOC planned (1,900 code + 1,320 tests). M2's 1.5×
  ratio suggests ~4,800 changed lines actual.

## Findings made while planning (2026-10-03)

**F1. M4.1 is over the 650 LOC cap (380 + 320 = 700).** The design doc owns
the estimate and the sub-milestone structure (one feature per
sub-milestone, 10 rows), so this plan does **not** pre-split it — a
pre-split into M4.1a/M4.1b would add an 11th milestone the design doc does
not define. The risk is real: M2's actual/estimate ratio was ~1.5×, so a
realistic M4.1 is ~1,000 changed lines. The **named split point** is the
`ship.ism` seam the doc itself defines — step 1: everything at pin 0.5.1
(`ship.ism{load_w_m2, drag_n, glow_w_m2}`, `drag_energy_j`, clocks, news,
legacy log, archive predicates, `record`, `scriptedRoundTrip`); step 2:
`glow_pole_w_m2` only, already scheduled as a separate step gated on
M4.6a's publish (⏸ P-pkg). If execution overruns, the executor cuts the
milestone at that seam: step 1 lands as M4.1, step 2 becomes follow-up
milestone M4.1b (it is gated on ⏸ P-pkg anyway, so no critical-path
change). The approval ask (Q3) includes this waiver.

**F2. M1.6b's merge state is ambiguous in the data.** Its JSON row is
`passes: true`, but the R1-M1-SKY-2 plan records its merge as waiting on
Mark's ⏸ R-a render review. M4.6's golden work needs the merged camera;
treat M1.6b as *available on its branch now, on main pending R-a*.

**F3. `gh` is unusable in this environment (TLS x509 failure on
api.github.com), and the registry index fetch is Forbidden.** PR states were
verified with `git ls-remote origin refs/pull/{67,68,69}/head` (all three
heads exist, commit subjects match M1.3, AI.7, M1.2d). The `ailang pkg
search` audit could not be re-run; the registry table below reuses
R1-M1-SKY-2's 2026-10-02 audit plus the doc's V15 export grep of the
installed 0.5.1 package, and the executor re-runs `pkg search` at kickoff.

**F4. Six of the eighteen ACs ride on M4.5's playthrough bot**
(AC3, AC4, AC5, AC6, AC7, AC16). AC6 is assigned to M4.5 itself (its
command needs the bot); the other five are "Feeds" rows on the feature
whose scope they check, with the explicit note that the *command* runs once
M4.5's harness exists. No feature may mark `passes: true` on an AC whose
command has not been run — the feeding features pass on their own interim
gates (sim tests, greps, harness replays), each with a runnable command in
its own milestone.

**F5. Track B's critical input is R1-M1-SKY-2 — approved by Mark per ledger
D-19 (attended, 2026-10-02: "start wave 1"); only its sprint JSON's
`approved` flag is stale (still `false`, `status: planned`) — with two open
PRs.** M4 Track A is
fully unblocked; M4 landing is not. This plan does not re-plan that sprint;
it records the dependency.

**F6. M4 adds no Python, by design and by AC18.** The five tools the first
draft named in Python are AILANG (`sim/tools/{lore_import, lore_values,
lore_check, session_audit}.ail`) or Godot headless
(`tools/validate_area.gd`, `tests/display_audit.gd`); the lore file copy is
shell glue. `make python-guard` must stay green with zero new `*.py`.

## Milestones

Each milestone is one iteration, test-first, evaluated by a different agent
or model from the executor (generator ≠ judge). Track A milestones (M4.6a,
M4.0, M4.1, M4.3a, M4.4, M4.7, M4.5 — and M4.6's ungated half) each land as
their own PR to main. The Track B train (M4.2 → M4.3b → M4.6's gated half)
lands as **stacked PRs into the integration branch `m4-track-b`**, which
merges to main only after ⏸ S1 sign-off (see the pause-points table).
`passes` starts as `null`. Tracks follow the design doc's §Order: **Track A**
(sim and UI) and **Track B** (interior), with review builds published at
every sub-milestone.

### Wave 1 (all startable NOW; concurrent branches, sequenced merges — M4.6a and M4.1 share the pin files, see the pin-bump note under M4.6a)

#### M4.6a: `medium.glowEmittanceAt` in `sunholo/relativity` (package first, gate 3)
**Scope (in `$PKG`):** the one new formula in M4 —
`medium.glowEmittanceAt(n, phi, eps, fIn, cosTheta)` = ε f_in K max(0, cosθ),
the glow's angular profile. Tests: value at cosθ = 1 equals
4 × `glowInwardFlux`; the sphere mean equals `glowInwardFlux`; zero at
φ = 0; finite sweep; VM = interpreter. CHANGELOG entry, `[release] kind`,
AGENT.md touch, `ailang pkg quality` with **no gates**, `publish --dry-run`.
The release number is whatever `kind` assigns after 0.5.1. The
**controller publishes** under the loop's standing publish grant *for this
package only* after an independent physics PASS; then `sim/ailang.toml`,
`sim/ailang.lock` and the bundled `runtime/cache` are bumped **together**
(V23 closes). The pin bump lands in **its own commit on main** after
⏸ P-pkg: M4.1's PR (step 1, at pin 0.5.1) merges **before** it and touches
none of the three; M4.1 step 2 (`glow_pole_w_m2`) then lands as a small
follow-up on the bumped pin.

**Files:** `$PKG/packages/relativity/medium.ail`,
`$PKG/packages/relativity/medium_test.ail`, `$PKG` CHANGELOG + `ailang.toml`;
then `sim/ailang.toml`, `sim/ailang.lock`, `runtime/cache/registry/sunholo/relativity/`.

**Estimated:** 20 + 40 = 60 LOC · **Deps:** none · **Art-gated:** no ·
**Registry:** contribute `sunholo/relativity` (gate 3: physics maths lives
in the package first; the sim, GDScript and shaders only mirror it).

**Acceptance (commands):**
- Package: `cd $PKG && $A test --package relativity` — the sphere-mean and
  pole = 4 × mean checks pass; `$A pkg quality` reports no gates;
  `$A pkg publish --dry-run` clean. (CLAUDE.md gate 3 sequence: tests,
  CHANGELOG, `[release] kind`, quality, dry run, publish.)
- Pin: `grep -n relativity sim/ailang.toml` shows the new version;
  `ailang lock` (`make deps`) relocks; the bundled cache holds the new
  version.
- V23 (the doc's PENDING row): re-run the V12 probe extended with
  `glowEmittanceAt(n, phi, 1e-9, 0.5, 1.0)` — equals
  4 × `glowInwardFlux(n, phi, 1e-9, 0.5)` (interim hand-derived
  9.62878e-5 at 0.99c), sphere mean = `glowInwardFlux`, VM = interpreter;
  `grep -n '^export' $P/medium.ail` at the new version shows it.

**Test-first:**
- `glowEmittanceAt(n, φ, ε, f_in, 1.0) == 4 × glowInwardFlux(n, φ, ε, f_in)` (0.99c and 0.999999c).
- Sphere mean of `glowEmittanceAt` over cosθ == `glowInwardFlux` (mean of max(0, cosθ) = ¼).
- `glowEmittanceAt(…, 0, …) == 0` at φ = 0 and at cosθ ≤ 0.
- Finite and ≥ 0 over a φ sweep to the 0.999999c cap.

#### M4.0: Area bundles and the frame contract
**Scope:** `interior/area_bundle.gd` — loads brief §9 bundles from
`assets/areas/<area>/` (`manifest.json`, `cam_`, `pano_`, `play_`, `fg_`),
schema field-for-field per V17, refuses a missing layer, keeps and ignores
unknown keys, optional `placeholder` bool (HUD tag). Blockout **test
fixture** copied from `origin/spike/iso-bridge` into
`tests/fixtures/areas/bridge_blockout/` with a hand-written manifest
(parallax 0.15 / 1.6, pitch −14, yaw 45, size 16 m, focus [−8, 1, 9],
`placeholder: true`); `assets/areas/bridge/` holds the current bundle
(blockout until bridge v1 arrives). `make validate-areas`
(`tools/validate_area.gd`, Godot headless `--script`): alpha exactly 0 where
space shows, manifest + camera schema, camera round trip ≤ 1 px, GLB Y-up
metres with `WALK_`/`SPAWN_`/`INTERACT_`. `interior/ship_frame.gd`
(float64): ship +Z = direction of travel, up = direction of travel all
journey (D-14, no flip), `ship_basis(heading)` with galactic-pole roll
fallback within 1e-6 of a pole.

**Files:** `interior/area_bundle.gd`, `interior/ship_frame.gd`,
`tools/validate_area.gd`, `tests/fixtures/areas/bridge_blockout/`,
`assets/areas/bridge/`, `Makefile` (`validate-areas`, `m4-smoke` stub),
`tests/test_area_bundle.gd`.

**Estimated:** 250 + 150 = 400 LOC · **Deps:** none · **Art-gated:** no ·
**Registry:** none (Godot I/O; no package applies — F3 audit deferred to
executor kickoff).

**Acceptance (AC ids, commands from the design doc):**
- **AC13** — `make validate-areas` — bundles valid (fixture and delivered):
  alpha, camera round trip ≤ 1 px, GLB metres/Y-up.
- **AC14 (validation half)** — `make validate-areas BUNDLE=tests/fixtures/areas/bridge_blockout && make validate-areas BUNDLE=assets/areas/bridge`
  (the smoke half lands with M4.2).
- `make test AILANG=$A AILANG_BIN=$A` green (AC18 applies to every
  milestone).

**Test-first:**
- Loader refuses a bundle with a missing layer; accepts the fixture; keeps
  unknown keys; `placeholder: true` surfaces the HUD tag.
- `ship_basis` CPU tests: orthonormal to 1e-12, heading → +Z, pole fallback
  (these move into `tests/test_physics.gd`; M4.6 extends them, AC9).
- `validate_area.gd` fixture pass + positive-control failure (a broken
  alpha or camera JSON must fail).

#### M4.1: Sim consequence stub and session extensions (pure core)
**Scope:** `sim/consequence.ail` beside M2's journey state; I/O stays in
`sim/ship.ail`. Earth clock at rest (D-12, no pause); the 1,000 AU
**stand-off** (M4 owns it — M2 plans to the star itself, V18); light-delayed
news epoch (t_e = t − |p − p_Sol|, 0.043984 yr at α Cen with the
`planBurnCoastBurn` arrival 4.398171, V24); news tier + seeded template id
from PCG stream `"news"`; displayed quantities as sim fields (`gap_years`,
`news_epoch`, `news_age_years`, progress, `one_minus_beta`); live
`ship.ism{load_w_m2, drag_n, glow_w_m2}` at current rapidity (package calls
at pin 0.5.1) plus `drag_energy_j` = ledger `drag_j` since commit (M2
semantics F·c, V24 — **no new ledger scope**) — that is **step 1**, landing
at pin 0.5.1; **step 2** (separate, later, gated on ⏸ P-pkg) adds
`glow_pole_w_m2` from the post-M4.6a release (the sim never computes 4 ×
`glowInwardFlux` itself);
`news{…, body_source ∈ template | ai | fallback, fallback_reason}` on the
existing `ai_fallback` event (V21); legacy log (append-only change set);
archive hint predicates (the six README hints, V16); `record` validation
(`ai_numeral`, `ai_length` 280, D-21); `make strict` gains
`scriptedRoundTrip`. Protocol: additive minor bump; M2's old-message tests
stay green **unmodified**.

**Files:** `sim/consequence.ail`, `sim/consequence_test.ail`, `sim/ship.ail`,
`sim/protocol.ail`, `sim/ai.ail`, `sim/core_test.ail` (stand-off,
scriptedRoundTrip), `Makefile`.

**Estimated:** 380 + 320 = **700** LOC (**over the 650 cap — F1 waiver**)
· **Deps:** M2 protocol and planner (landed); **no milestone dependency** —
step 2 (`glow_pole_w_m2`) is a separate later step gated on M4.6a's publish
(⏸ P-pkg); step 1 touches none of `sim/ailang.toml`, `sim/ailang.lock`,
`runtime/cache` · **Art-gated:** no · **Registry:** depend
`sunholo/relativity@0.5.1` (`planBurnCoastBurn`, `coastAt`, `gammaOf`,
`oneMinusBeta`, `rapidityOfBeta`, `loadScale`, `kineticFlux`,
`mirrorDragForce`, `cruiseDragEnergy`, `glowInwardFlux` — V15).

**Acceptance (AC ids, commands from the design doc):**
- **AC1** — `make sim strict` (`scriptedRoundTrip`) — round trip Sol ⇄ α Cen
  (scripted 4.37 ly target, 1,000 AU stand-off, zero dwell, default
  boost_g): Earth 2 × `planBurnCoastBurn(d − s, a, φ).trip.galaxyTime`
  (8.796343), ship 2 × `.shipTime` (1.240885) within 1e-9, and within 1e-4
  of 2 × `coastAt(d − s, 0.99)` (τ_b ≤ 19 min clause); news epoch =
  t − (d−s) within 1e-9; `gap_years` = t − tau exactly; strict VM =
  interpreter.
- **AC2** — `make sim tools-test` — news tiers: fixtures hit all five; α Cen
  `<1`, return `5–15`; template choice seeded and replayable; numerals only
  in slots.
- **AC8 (sim half)** — `make sim` (ISM fixture) — live and plan ISM at 0.99c
  on the scripted target: `load_w_m2` 2.21961e5, `drag_n` 23.2598,
  `glow_w_m2` 2.40719e-5 (ε 1e-9, f_in 0.5), each within 1e-3 of the
  package; `drag_energy_j` 1.36530e17 within 1e-3 and the ledger integral =
  `cruiseDragEnergy` within 1e-9; `glow_pole_w_m2` =
  `glowEmittanceAt(n, φ, ε, f_in, 1.0)` after M4.6a; all zero at β = 0.
  (The `make lore-values` half lands with M4.7.)
- Feeds AC5, AC16 (commands run under M4.5).

**Test-first:**
- `scriptedRoundTrip` red against the unmodified sim (no Earth clock), then
  green at the V12 numbers.
- News-epoch and tier fixtures (all five tiers; α Cen arrival t_e 0.043984).
- Stand-off: plan distance = d − 1,000 AU on the same heading.
- Live `ship.ism` at 0.99c equals the package values; relaxes through the
  brake; zero at rest.
- `record` refusals: digits → `ai_numeral`, > 280 chars → `ai_length`, no
  open request → refused; each closes with `ai_fallback` and sets
  `body_source`/`fallback_reason`.
- Legacy log append-only (no rewrite mutation), archive predicates fire
  once, in order.
- Protocol minor bump: every M2 old-message test unmodified and green.

### Wave 2 (parallel)

#### M4.3a: Transit loop, time warp, HUD and arrival (sky-only harness) — Track A
**Scope:** the transit loop on a sky-only harness scene (no interior):
boost → cruise → brake pacing (fixed 3 s real per burn phase, `dtau`
chosen and **logged** so it replays); time warp as a recorded intent
(0.002 / **0.01 default** / 0.05 ship-yr/s; a 0.99c leg = 62.0 s); no pause
while docked/planning (D-12); `ui/journey_hud.tscn` with **every** value
through `DisplayBinding` — τ and t side by side same size, `gap_years`,
phase, β (4 dp), γ (3 dp), distance remaining, Earth-yr to arrival, the
ISM readout (load W/m² and suns, drag energy J and kg, glow on/off), warp
level; the arrival card (distance, ship years, Earth years, gap); the brake
is a legacy entry + one-line HUD notice, no turnover. Velocity from the sim
only.

**Files:** `ui/journey_hud.tscn`, `ui/display_binding.gd`, arrival card
scene, harness scene + warp/`dtau` wiring (bridge), `Makefile` as needed.

**Estimated:** 200 + 80 = 280 LOC · **Deps:** M4.1, M2 map (landed) ·
**Art-gated:** no · **Registry:** none (Godot UI; formats mirror sim
fields, no arithmetic on physics values).

**Acceptance (AC ids, commands from the design doc):**
- Feeds **AC3** — `make playthrough SCRIPT=adversarial`;
  `! grep -rniE "save_game\|load_game\|ResourceSaver" interior ui`
  (the grep half runs in this milestone; the adversarial run needs M4.5).
- Feeds **AC7** — `make playthrough playthrough-time` (runs under M4.5;
  the warp rates and 3 s burns are set here and are what the proxy
  measures).
- Interim gate: `make test AILANG=$A AILANG_BIN=$A` green; a scripted
  harness session replays byte-identically with `make replay SESSION=…`
  (warp intents in the input log).

**Test-first:**
- Warp intent logged and replayed (0.01 default; level change only while
  committed).
- `dtau` pacing: each burn phase spans 3 s real regardless of τ_b.
- HUD fixtures: every numeric label is a `DisplayBinding`; a hand-set
  number fails the audit's positive control (M4.5 runs it).
- Phase sequence boost → cruise → brake with no flip event.

#### M4.2: The iso interior with the live sky — Track B (art-gated)
**Scope:** the five-layer composite (M1 background + starfield in an HDR
`SubViewport`, panorama 0.15, play GLB 1, foreground 1.6, HUD), **one
tonemap** (AgX + M1.5 exposure in the SubViewport; the parent must not
tonemap or glow again, G-M4-2); sky camera = cam JSON × `ship_basis`;
velocity from sim fields only (the spike's `_set_speed` and painted band
are not ported); the **forward glow** dome overlay (additive, before the
tonemap) driven by `ship.ism.glow_pole_w_m2`, profile
`glow_profile(glow_pole_w_m2, cos θ)` = `glowEmittanceAt` mirrored, W/m² →
scene radiance through M1.5's photometric exposure — no hand-tuned gain;
walking on the bundle's `WALK_` navmesh (static captain); interactables
(nav console → M2 galaxy map; Archive terminal → news/log/codex; shortcuts
M, L, K). **Art is swappable data (D-16):** built and merged against
whatever bundle is current — blockout first; a bundle swap is a data drop
validated by `make validate-areas`, never a code change.

**Files:** `interior/interior.tscn`, `interior/glow_overlay.gdshader` +
toon/outline shaders, `interior/walk.gd`, `main.gd` wiring, `Makefile`
(`m4-smoke`).

**Estimated:** 380 + 100 = 480 LOC · **Deps:** M4.0; **external: M1.3
(PR #67) and M1.5a (not started)** — any valid bundle unblocks the scene
mechanics, but the composited sky needs the v2 starfield, and the glow's
exposure needs M1.5a · **Art-gated:** **yes** (lands on the blockout;
approved bundle when delivered) · **Registry:** depend
`sunholo/relativity` (post-M4.6a release) for the glow profile mirror.
**Merge:** PR into the Track-B integration branch `m4-track-b` (not main);
merges to main with the stacked train after ⏸ S1 sign-off.

**Acceptance (AC ids, commands from the design doc):**
- **AC14** — `make validate-areas BUNDLE=tests/fixtures/areas/bridge_blockout && make validate-areas BUNDLE=assets/areas/bridge && make m4-smoke BUNDLE=tests/fixtures/areas/bridge_blockout`
  — the swap needs no code change and the slice runs on each bundle.
- Feeds **AC10** (G-M4-1..4), **AC11** (`make capture-m4`), **AC12**
  (`make bench SCENE=bridge`) — commands run under M4.6.
- Interim gate: composite order and one-tonemap asserted in the CPU
  harness before the GPU golden exists.

**Test-first:**
- Layer order and parallax factors pinned (0 / 0.15 / 1 / 1.6).
- One-tonemap: parent viewport applies no second tonemap/glow (CPU-side
  assertion; GPU proof is G-M4-2).
- `glow_profile` CPU mirror equals the package within 1e-12 relative at
  θ = 0°, 45°, 80°, 90°, 120° (extends into M4.6's `test_physics.gd`).
- Placeholder bundle shows the "placeholder art" HUD tag.
- Avatar constrained to `WALK_`; avatar position never enters the sim.

### Wave 3 (parallel)

#### M4.4: News from home, the AI path, return trip and the legacy screen — Track A
**Scope:** the news beat as an Archive-terminal text panel only (D-14):
"Transmission received", header from fields (*"Latest news from Earth:
Earth-year +0.04, already 4.35 years old."*), one template paragraph from
`data/news/templates.json` (numerals only in slots; tiers set the tone,
facts only — ⏸ **S4** copy review); calendar relative ("Earth +4.40 yr"),
epoch and `start_age` (30) as scenario parameters; **the AI path**: results
return as `record` intents, the panel shows what `news.body_source` names —
`fallback` shows the template under the visible notice *"Live transmission
unavailable: archived text shown"* plus the fixed reason→phrase table (no
digits) and a diagnostics entry on the news tab; `template` shows no
notice; `ai` shows a small "generated" tag; all three labels are fixed copy
through `DisplayBinding`. Return trip: map opens with Sol highlighted, the
D-12 commit ritual again. Legacy screen: entries, closing line from fields
("You were away 1.24 years. Home is 8.80 years older."), "Begin again"
(new voyage, new seed, no reload).

**Files:** `ui/news_panel.tscn`, `data/news/templates.json`, the AI relay
wiring (bridge), Archive-terminal news tab + diagnostics list, legacy
screen scene.

**Estimated:** 250 + 100 = 350 LOC · **Deps:** M4.1, M4.3a ·
**Art-gated:** no · **Registry:** none (UI + JSON data; the AI transport is
R1-AI-FOUNDATION's, soft dep).

**Acceptance (AC ids, commands from the design doc):**
- Sim-test gate (this milestone's runnable gate) — `make sim`
  (`$A test --package sim`) — asserts `news.body_source` and
  `fallback_reason` for all three paths: `template` (no request made; no
  notice), `ai` (an accepted `record`; the "generated" tag is bound copy),
  `fallback` (a digits fixture closes with `ai_fallback{reason:
  "ai_numeral"}`; the reason→phrase table entry exists and is digit-free);
  plus a scripted bridge session snapshotting the three panel renderings.
- Feeds **AC6** — `make playthrough AI=none|stub|digits` needs M4.5's bot,
  so **M4.5 owns AC6**; M4.4 passes on the sim-test gate above (F4).
- Feeds AC3 (no save/load on "Begin again"), AC4 (the three labels are
  bound copy).
- Interim gate: template lint (numerals only in slots; reason phrases
  contain no digits) in `make test`.

**Test-first:**
- Template fixtures for all five tiers; numeral lint fails on a digit
  outside a slot.
- The three `body_source` renderings, each snapshot-tested.
- Reason→phrase table: every known reason code has a digit-free phrase; an
  unknown reason fails loudly, never silently.
- Return-trip commit ritual refuses nothing new but re-arms (M2 commit
  rule still enforced by the sim).
- Legacy closing line computed from sim fields only (a GDScript
  subtraction mutation must fail the audit).

#### M4.7: The Archive codex — physics as in-game lore — Track A
**Scope:** `make lore-import` (shell copy of `$D/lore/archive/*.md`,
`physics/higgs-bubble.md`, `physics/relativity-spec.md` into `data/lore/`;
manifest by `sim/tools/lore_import.ail` with the design-repo sha and a
sha256 per file); `CHECK=1` fail-closed self-consistency **everywhere
including CI**, cross-repo half wherever the sibling exists (skipped with a
notice in CI — Q2); the **check-value registry** (`make lore-values` →
`data/lore/check_values.json`): source (a) `sim/tools/lore_values.ail`
evaluating the package's exported functions as `pkg:<function>(<args>)`
ids (no `rel:check` registry exists, V24) plus the M4 values
(`m4:glow_eps` 1e-9, `m4:glow_f_in` 0.5, `m4:glow_099`), seeded by the V12
probe; (b) HB rows; (b′) RS rows; (c) `tests/test_physics.gd`'s `CHECKS`;
(a) vs (b) agree at printed precision; ε ≤ HB-61 asserted. **`make
lore-check`** (`sim/tools/lore_check.ail`, strict VM = interpreter, in
`make test`): valid front matter, every `checks` id resolves, `unlock`
names a known hint (the six of V16), and **every body number binds** to a
listed check by shown significant figures + the README's textual unit-alias
table; the drifted fixture must fail. Codex UI (`ui/archive/codex.tscn`,
`lore_loader.gd`): third Archive tab, locked entries greyed, Markdown
subset into `RichTextLabel`, unlock toasts; unlocks come only from the
sim's `archive.unlocked`.

**Files:** `sim/tools/lore_import.ail`, `sim/tools/lore_values.ail`,
`sim/tools/lore_check.ail` (+ tests), `data/lore/`,
`ui/archive/codex.tscn`, `interior/lore_loader.gd`,
`tests/fixtures/lore/drifted.md`, `tests/expected_unlocks.json`,
`Makefile` (`lore-import`, `lore-values`, `lore-check`).

**Estimated:** 180 + 140 = 320 LOC · **Deps:** M4.1 (hint predicates);
design repo `lore/archive/`, `higgs-bubble.md`, `relativity-spec.md` §7 at
`1ef3bc9` (sibling present) · **Art-gated:** no · **Registry:** depend
`sunholo/relativity@0.5.1` (+ the M4.6a release once pinned); no markdown
package — the renderer subset is game code (F3 audit deferred).

**Acceptance (AC ids, commands from the design doc):**
- **AC15** — `make lore-values lore-check` and
  `make lore-check LORE=tests/fixtures/lore/drifted.md` exits non-zero —
  every `unlock` a known hint; every number binds; HB rows with package
  functions agree with the package; `m4:glow_eps` ≤ HB-61; strict VM =
  interpreter.
- **AC17** — `make lore-import CHECK=1` — vendored lore hash-equals its
  manifest (fail-closed, CI included) and, where the sibling exists, the
  design repo at the manifest's sha.
- **AC8 (registry half)** — `make lore-values` — the ISM/glow rows
  registered and equal to their HB rows at printed s.f.
- Feeds **AC16** (`make playthrough codex-unlocks`, runs under M4.5).

**Test-first:**
- `drifted.md` (one number off in its last digit) fails; an unknown hint
  fails; an unresolvable `checks` id fails.
- Number binding: shown s.f. rounding + unit aliases (yr ↔ years, min ↔
  minutes, deg ↔ °, sun ↔ suns, M☉ ↔ solar masses, r_s ↔ horizon radii,
  K ↔ kelvin, trailing c, — ↔ no unit); a number needing *numeric*
  conversion does not bind (the old conversion table is withdrawn).
- Registry: (a) vs (b) agreement for HB-16, HB-17, HB-35, HB-40, HB-41,
  HB-45, HB-49, HB-53, HB-54, HB-61; ε ≤ HB-61.
- `expected_unlocks.json`: the seven minimum-path entries in order
  (`always`, `first_commit`, `first_boost`, `cruise_above_0.9c` at the
  0.99c default; `cmb-forward` does **not** unlock at γ 7.09).

#### M4.3b: HUD and transit moved into the interior — Track B (art-gated)
**Scope:** M4.3a's HUD, warp and arrival card run inside M4.2's composite;
the starbow forms overhead during boost, holds in cruise, relaxes through
the brake to the rest-frame sky (up = direction of travel throughout,
D-14); shortcuts M, L and K keep the minimum path independent of pathing.

**Files:** `interior/interior.tscn`, `ui/journey_hud.tscn` (reparenting),
wiring only.

**Estimated:** 40 + 30 = 70 LOC · **Deps:** M4.2, M4.3a · **Art-gated:**
**yes** · **Registry:** none. **Merge:** stacks on M4.2's branch in
`m4-track-b`; merges to main with the train after ⏸ S1 sign-off.

**Acceptance (AC ids, commands from the design doc):**
- Feeds **AC4** (audit runs on the composited scene), **AC10** G-M4-3
  (forward pole during boost, cruise and brake — `make golden` under
  M4.6), **AC11** (`make capture-m4`).
- Interim gate: `make m4-smoke BUNDLE=assets/areas/bridge` green; the
  harness-session replay from M4.3a still replays inside the interior.

**Test-first:**
- Same HUD audit fixtures as M4.3a, run against the composited scene.
- Orientation invariant: forward pole faces the heading in all three
  phases (CPU assertion; GPU proof is G-M4-3).

### Wave 4 (parallel; then the S1 gate)

#### M4.5: Verification harness — playthrough, display audit, replay, timing — Track A
**Scope:** the scripted playthrough bot (`tests/playthrough_min.json`, the
minimum path through Godot's input layer, headless, real sim) writing
`$(SCRATCH)/session.ndjson` and `display_samples.ndjson` — on the fixture
bundle until S2's bundle arrives, on the approved bundle for landing; the
**display audit** (`tests/display_audit.gd`, Godot headless, `make
display-audit`): every numeric label a `DisplayBinding{node_path, field,
format}`, fails on a number ≠ `format(state[field])`, an unbound digit, or
a missing field; codex bodies hash-equal via `LoreBinding`; **replay**:
`make replay SESSION=…` (`cmp` on state streams), `make parity-m4` (VM =
interpreter, AI process never spawned); the **ten-minute proxy**
(`sim/tools/session_audit.ail` entry `playthroughTime`, AILANG with FS
caps): sim ticks at default warp + 1.5 s per click/key + 200 wpm reading +
20 s walking per interactable (budget ≤ 330 s, limit 360; each leg 45–120 s
at default warp); entry `codexUnlocks` against `tests/expected_unlocks.json`;
`tests/adversarial.json` (re-plan, cancel and Commit mid-transit).

**Files:** `tests/playthrough_min.json`, `tests/adversarial.json`,
`tests/display_audit.gd`, `sim/tools/session_audit.ail` (+ test),
`Makefile` (`playthrough`, `display-audit`, `replay`, `parity-m4`,
`playthrough-time`, `codex-unlocks`).

**Estimated:** 120 + 230 = 350 LOC · **Deps:** M4.3a, M4.4, M4.7, M2
replay (landed), **M4.2 and M4.3b** (AC4's audit and the final run are on
the composited interior; AC7's proxy includes the 20 s walking per
interactable) · **Art-gated:** no — but the **final** run is on the
approved bundle · **Registry:** none (harness; AILANG FS caps for the
proxy, Godot for the audit — F6, no Python).

**Acceptance (AC ids, commands from the design doc):**
- **AC3** — `make playthrough SCRIPT=adversarial`;
  `! grep -rniE "save_game\|load_game\|ResourceSaver" interior ui` —
  re-plan, cancel and Commit mid-transit each get `committed`, state
  unchanged; no save/load path.
- **AC4** — `make playthrough display-audit` — 0 mismatches, 0 unbound
  numerals, ≥ 500 samples, both clocks and the ISM readout on every
  transit sample, codex bodies hash-equal (on the approved bundle).
- **AC5** — `make replay SESSION=$(SCRATCH)/session.ndjson && make parity-m4`
  — byte-identical incl. `record` intents and archive unlocks; AI process
  count during replay 0.
- **AC6** — `make playthrough AI=none`, `AI=stub`, `AI=digits` (each
  followed by `make display-audit`) — `AI=digits`: session log holds
  `ai_fallback{reason: "ai_numeral"}`, `body_source` = `fallback`, the
  notice shows the `ai_numeral` phrase; `AI=none`: `body_source` =
  `template`, no notice; `AI=stub`: `ai` with the "generated" tag. (If
  R1-AI-FOUNDATION slips, `AI=stub`/`AI=digits` use the injected fixture,
  per the design doc's Interfaces.)
- **AC7** — `make playthrough playthrough-time` — proxy ≤ 360 s; each leg
  45–120 s (expected 62.0).
- **AC16** — `make playthrough codex-unlocks` — the seven expected entries
  at their hints, in order; codex shows only unlocked entries.

**Test-first:**
- Audit positive controls: an unbound numeral fixture and a stale-format
  fixture both fail.
- Proxy model checked against a synthetic session log (fixture), incl. the
  1.5 s commit holds.
- `codexUnlocks` against a fixture stream with a wrong order → fails.
- Replay harness proves `cmp` detects an injected one-bit divergence.

#### M4.6: Physics gates, goldens, renders and bench — both tracks (partly gated)
**Scope:** **ungated half (can start in wave 2, after M4.0 + M4.1 +
M4.6a):** `tests/test_physics.gd` — `ship_basis` cases; projection of a
galactic direction through `cam_bridge.json` × ship basis; the α Cen cruise
mirror (γ(0.99) = 7.088812050083356 from `gammaOf`; `coastAt`
4.398169 / 0.620438; the sim's `planBurnCoastBurn` 4.398171 / 0.620443);
ISM load 2.21961e5 (HB-40 at 3 s.f.); glow values (ε 1e-9, 2.40719e-5 at
0.99c, 0.281271 at 0.999999c ≤ 1 W/m² HB-61) and the profile against
`glowEmittanceAt` within 1e-12 at θ = 0°/45°/80°/90°/120°; finite flux at
every stop point (gate 5) — every expected value copied from the V12 probe,
never computed in GDScript; `make lint-precision` (in `make test`) with a
positive-control fixture. **Gated half:** `make golden` G-M4-1 (composite
position ≤ 0.75 px, pan-invariant), G-M4-2 (one tonemap ≤ 1/255), G-M4-3
(forward pole ≤ 0.75 px in all three phases), G-M4-4 (profile within 1 %
at 0°/45°/80°, exactly 0 at rest; **absolute** pole value in a debug linear
float target = `glow_pole_w_m2` within 1 % at 0.99c and 0.999999c);
`make capture-m4` → `renders/m4/` (docked; boost β 0.5, 0.9; cruise 0.99
with glow; brake β 0.5; arrived α Cen; arrived home; pans −5/0/+5, contact
sheet, on the approved bundle) — ⏸ **S1**; `make bench SCENE=bridge`
(p99 < 16.7 ms at 2560×1440, M4 Max, medium tier, 30 s scripted transit).

**Files:** `tests/test_physics.gd`, `Makefile` (`lint-precision`, `golden`
cases, `capture-m4`, `bench`), `renders/m4/`, lint positive-control
fixture.

**Estimated:** 80 + 130 = 210 LOC · **Deps:** M4.2 (gated half), M4.6a
(glow profile), **external: M1.6b camera golden** (passed; merge pending
R-a — F2), **M1.2d bright tier (PR #69, soft)** — the "arrived at α Cen"
render and the arrival view need the A/B astrometry; no golden pins the
separation, so nothing blocks · **Art-gated:** **partly** (CPU tests and
lint are not; goldens,
renders and bench are) · **Registry:** depend `sunholo/relativity`
(post-M4.6a release). **Merge:** the ungated half (CPU tests,
`lint-precision`) lands on main as its own PR; the gated half stacks on
M4.3b in `m4-track-b`, and ⏸ S1's `make capture-m4` runs on that branch.

**Acceptance (AC ids, commands from the design doc):**
- **AC9** — `make test` (`physics`, `lint-precision`) — CPU physics; no
  hand-computed γ or 1−β.
- **AC10** — `make golden` — G-M4-1 (≤ 0.75 px, pan-invariant), G-M4-2
  (≤ 1/255), G-M4-3 (≤ 0.75 px, all three phases), G-M4-4 (profile and
  absolute pole ≤ 1 %, 0 at rest).
- **AC11** — `make capture-m4`;
  `grep -n "S1 sign-off" design_docs/implemented/r1/m4-report.md` —
  renders on the approved bundle, reviewed by Mark (⏸ S1).
- **AC12** — `make bench SCENE=bridge` — p99 < 16.7 ms at 2560×1440.
- **AC18** — GitHub Actions `CI` green — `make test` incl. `lore-check`,
  `lint-precision`, `python-guard` (no new `*.py`); `make strict` and
  every parity target; M2's old-message tests unmodified.

**Test-first:**
- `test_physics.gd` rows written from the V12 probe output *before* the
  composite exists (they fail on `main`).
- `lint-precision` positive control (a planted `1.0 - beta` outside
  `physics/`/`tests/`) fails.
- G-M4-4's debug float target reads back W/m² before exposure — a
  hand-tuned gain mutation fails the absolute gate.

## Milestone table

| ID | Scope | LOC (code+tests) | Deps | Art-gated | Wave |
|---|---|---|---|---|---|
| M4.6a | `medium.glowEmittanceAt` in `sunholo/relativity` + tests/CHANGELOG/release; sim pin + lock + cache | 60 | — | no | 1 |
| M4.0 | Bundle loader, blockout fixture, `validate-areas`, `ship_frame` | 400 | — | no | 1 |
| M4.1 | `consequence.ail`: Earth clock, stand-off, news epoch/tier, display fields, live `ship.ism`, `body_source`, legacy log, archive predicates, `record`, `scriptedRoundTrip` | **700** (cap waiver F1) | M2 (landed); step 2 (glow_pole) gated on M4.6a/⏸ P-pkg | no | 1 |
| M4.3a | Transit loop, warp, boost/brake pacing, HUD (incl. ISM), arrival card, sky-only harness | 280 | M4.1, M2 map | no | 2 |
| M4.2 | Interior scene, composite, glow overlay, walking, interactables | 480 | M4.0; **ext M1.3 (#67), M1.5a** | **yes** | 2 |
| M4.4 | News panel, templates, AI relay + fallback notice, return trip, legacy screen ⏸ S4 | 350 | M4.1, M4.3a; soft ext AI foundation | no | 3 |
| M4.7 | Lore import, codex UI, unlocks, registry, `lore-check` (AILANG) | 320 | M4.1; design repo at `1ef3bc9` | no | 3 |
| M4.3b | HUD and transit moved into the interior | 70 | M4.2, M4.3a | **yes** | 3 |
| M4.5 | Playthrough bot, display audit, replay/parity, time proxy, codex-unlocks | 350 | M4.3a, M4.4, M4.7, M2 replay, M4.2, M4.3b | no (final run on approved bundle) | 4 |
| M4.6 | CPU tests + `lint-precision` (ungated); G-M4-1..4, `capture-m4`, bench (gated) ⏸ S1 | 210 | M4.2, M4.6a; ext M1.6b, M1.2d (#69, soft) | partly | 4 (ungated half from wave 2) |
| | **Total** | **1,900 + 1,320 = 3,220** | | | **4 waves** |

**Critical path:** two chains converge at wave 4 —
Track A: M4.1 → M4.3a → M4.4 → M4.5 (M4.6a runs beside it: publish at
⏸ P-pkg, then M4.1 step 2 and M4.2's glow profile); Track B: M4.0 → M4.2 →
M4.3b → M4.6(gated) → ⏸ S1, landing as stacked PRs on `m4-track-b` until
S1. M4 lands when both tracks, M4.5's final approved-bundle
run and S1 are done; if bridge v1 hasn't arrived, M4 lands on the latest
delivered bundle and the swap follows as a data change (design doc
§Critical-path effect).

**Duration:**
- **Attended** (M2 style): 4 waves × ~2 h per milestone pair + GPU gates
  and the package publish ≈ **20–24 h, about 3 working days**, if Mark
  reviews S1/S4 promptly and Track B's externals land.
- **Unattended loop** (one item per 6 h iteration): 10 + ~2 contingency =
  12 iterations, **~4–6 days** including review and dependency waits. Track
  B cannot finish before R1-M1-SKY-2's wave 5 (M1.5a) regardless.

## Review checkpoints (pause points)

| ID | After | What Mark (or the controller) sees | Blocks |
|---|---|---|---|
| ⏸ P0 | — | **this plan** | everything (approval ask Q3) |
| ⏸ P-pkg | M4.6a | controller publishes the `sunholo/relativity` release under the **standing publish grant (this package only)**: independent physics PASS → `ailang pkg quality` no gates → CHANGELOG + `[release] kind` → dry run → publish; then pin + relock + bundled cache (V23) | M4.1's `glow_pole_w_m2`, M4.2's glow, M4.6's G-M4-4 |
| ⏸ RB-1 | M4.0 + M4.2 end-to-end on the blockout | first review build: `make publish-dev` → `tools/install_review_build.sh --dev`, plus captures; **non-blocking**, repeated at every sub-milestone (D-16 "get something up so I can review it") | nothing |
| ⏸ S1 | M4.6's `make capture-m4`, run on `m4-track-b` | composited reference renders `renders/m4/` (physics gate 2), incl. the cruise frame with the glow at ε = 1e-9; AC11's `grep "S1 sign-off"` | the merge of `m4-track-b` (the stacked M4.2 → M4.3b → M4.6-gated train) to main, and landing |
| ⏸ S2 | each delivered bundle | recurring art review of each area bundle drop | **satisfied for the style frame (D-16)**; recurring reviews are non-blocking |
| ⏸ S4 | M4.4 | news template copy ("the game doesn't judge": facts only) | M4.4 merge |
| ⏸ P-land | wave 4 + S1 | `design_docs/implemented/r1/m4-report.md` (S1/S2 sign-offs, renders, bench, proxy time, lore-check output, upstream AILANG reports); R2 roadmap gains the human playtest; design-repo roadmap status; changelog | landing |

**S1 mechanism (executable ordering).** M4.2, M4.3b and M4.6's gated half
land as **stacked PRs into the integration branch `m4-track-b`** (M4.3b is
built on M4.2's branch, M4.6's gated half on M4.3b's), so each is
reviewable in order without merging M4.2 to main early. ⏸ S1's renders are
produced by `make capture-m4` **on `m4-track-b`** and reviewed there; on
sign-off the branch merges to main as one merge. Track A milestones and
M4.6's ungated half merge to main independently as their own PRs.

## Registry reuse gate

`ailang pkg search` could not run from the planning worktree (registry
index fetch Forbidden — F3). Reused: R1-M1-SKY-2's 2026-10-02 audit
(`relativity`, `photometry`, `cmb` → only `sunholo/relativity`;
`hipparcos`, `catalogue`, `exposure` → nothing; `binary` → only
`sunholo/duckdb`; `star` → relativity + an unrelated agents package) and
the design doc's V15 export grep of the installed 0.5.1 package. The
executor re-runs `pkg search relativity|markdown|lore|news|audit` at
kickoff and records any change here before writing code. No placeholder
decisions:

| Milestone | Package | Action | Reason |
|---|---|---|---|
| M4.6a | sunholo/relativity | **contribute** | Gate 3: the one new formula goes into the single physics package first |
| M4.0 | none | none | Godot scene/GLB/JSON I/O; no package applies |
| M4.1 | sunholo/relativity@0.5.1 | depend | Trip, kinematics and medium functions by name (V15); sim stays pure |
| M4.3a | none | none | Godot UI bound to sim fields; no physics arithmetic |
| M4.2 | sunholo/relativity (post-M4.6a) | depend | Glow profile mirrors `glowEmittanceAt`; exposure mirror from M1.5a |
| M4.4 | none | none | Templates and fixed copy; AI transport is the AI foundation's |
| M4.7 | sunholo/relativity@0.5.1 (+ M4.6a release) | depend | Registry source (a) evaluates exported package functions (V24) |
| M4.3b | none | none | Reparenting and wiring |
| M4.5 | none | none | Harness (AILANG FS + Godot headless); no logic worth packaging |
| M4.6 | sunholo/relativity (post-M4.6a) | depend | Check values copied from the package probe (V12), never recomputed |

## Risks

| Risk | Mitigation |
|---|---|
| R1-M1-SKY-2 slips (approved per D-19 — only its JSON `approved` flag is stale; #67/#69 open; M1.5a not started), stalling Track B | Track A proceeds to completion; Track B starts on the blockout the day M1.3/M1.5a land; blocker logged in the sprint JSON |
| R1-AI-FOUNDATION slips | Soft by D-8: ship with no AI process; AC6's `digits` case uses the injected fixture; `template` is the designed default |
| M4.1 overruns its 700 LOC (over cap; M2's ratio was ~1.5×, so ~1,000 changed lines is realistic) | Split at the named `ship.ism` seam (F1): step 1 (pin 0.5.1 fields) lands as M4.1, step 2 (`glow_pole_w_m2`) becomes follow-up M4.1b — it is gated on ⏸ P-pkg anyway, so no critical-path change |
| Bridge v1 bundle late | M4 lands on the latest delivered bundle; swap is a data change (AC14); blockout fixture keeps CI honest |
| Glow too faint to read, or reads as a heat bloom | ε = 1e-9 is a scenario parameter (D-15); G-M4-4 pins profile, absolute pole value and zero-at-rest by gate, not by eye; S1 looks at the cruise frame; a different look is a scenario ε, never a hidden gain |
| Double tonemap dims the starbow / starbow in the wrong place | G-M4-2 single-tonemap golden; one `ship_basis` with CPU tests; G-M4-3 in every phase |
| Destination star blows up (1/r²) or A/B coincide | 1,000 AU stand-off (D-14), M1.2 tiers (#69), finite-flux test (AC9) |
| AI text slips a number on screen | `ai_numeral` refusal + AC6 `digits` case + display audit over bound copy |
| Lore drifts after import | Vendored with sha; `lore-import CHECK=1` fail-closed; `lore-check` in `make test`; drifted fixture is the positive control |
| Headless rendering / 60 fps with the medium tier + toon | Audits use labels and state only; window-resolution sky; AC12 bench on M4 Max |
| VM/interpreter divergence | Never worked around: minimal repro to `ailang messages` (gcp store); `make parity-m4` gates M4.5 |
| New AILANG gaps (e.g. superscript parsing in `lore_check`) | Report upstream per CLAUDE.md; no Python fallback (F6) |

## Questions for Mark

1. **Q1 (design open question 4): α Cen distance — HB-4 (4.37 ly) vs the
   catalogue after D-19 (4.32 ly).** The HB journey rows and the Archive's
   `two-clocks` and `ism-glow` entries are computed at 4.37 ly with no
   stand-off; once M1.2 lands D-19 the HUD shows ~1 % less. Both honest,
   but a player can see both. **Recommendation:** a design-repo change that
   sets HB-4 to the catalogue value and regenerates the dependent HB rows
   and entries from the package, with `lore-check` proving the entries.
   **Default (M4 proceeds):** AC1 and AC8 assert on the scripted 4.37 ly
   target, the catalogue playthrough asserts only the package relation, and
   the M4 report lists the gap. This is a canon change in the normative
   physics doc, so it is Mark's call; the loop does not edit it.
2. **Q2 (design open question 5): CI access to the private design repo**
   for `lore-import CHECK=1` half (ii). **Recommendation:** a read-only
   deploy key for `sunholo-data/stapledons-design`, stored as a CI secret
   and recorded in `infra/gcp/setup.sh`. **Default:** CI runs the
   fail-closed self-consistency half only; the cross-repo half runs in
   every loop iteration and attended session, where the sibling exists.
   Adding a credential is an infrastructure decision, so it is Mark's.
3. **Q3: approve sprint R1-M4-JOURNEY as written?** Including: the M4.1
   LOC-cap waiver (700 > 650, split at the `ship.ism` seam on overrun —
   F1); the wave plan that starts Track A (M4.6a ∥ M4.0 ∥ M4.1)
   immediately on approval while Track B waits on R1-M1-SKY-2; and the
   pause points P-pkg, RB-1, S1, S4 above. **Recommendation: approve.**
   Default: no execution until approved (gate: sprint plans stop for
   approval).

## Notes

- The executor updates only `passes`, `started`, `completed` and `notes` in
  the JSON. Evaluations go to `.ailang/state/evaluations/`, run by a
  different agent or model from the executor.
- Every AILANG bug or DX papercut goes to `ailang messages` inbox `user`,
  `--from stapledons_godot`, with `AILANG_STORAGE_MESSAGING=gcp` and
  `AILANG_MESSAGES_PROJECT=ailang-multivac`.
- No new Python (F6): `make python-guard` stays green with zero new
  `*.py`; any AILANG gap is an upstream report, not a fallback.
- The V12 probe (`probe.ail` in the design doc) lands as the seed of
  `sim/tools/lore_values.ail`; `probe2.ail` covers the V24 ledger
  semantics. Both are AILANG; the Python oracle V13 was a provenance
  instrument only and is not ported.
- Resolved open questions 1–3 of the design doc (warp units, forward CMB
  renderer, lore vendoring) stand as the doc's recommendations: fixed
  ship-time warp rates (0.002/0.01/0.05), no forward CMB disc in M4
  (planner note above γ 275; M1 follow-up — and R1-M1-SKY-2's M1.8 already
  plans it), vendored lore in `data/lore/`.
- At landing: move the design doc to `design_docs/implemented/r1/`, write
  `m4-report.md`, update the design repo's roadmap status, add the
  changelog entry, and put the human playtest (protocol from the design
  doc's first draft) on the R2 roadmap (D-14).

## Revision round 2 (2026-10-03, planner; eval round 1 = 85/100 PASS with 3 blocking)

Fixes to `.ailang/state/evaluations/eval_stapledon_iter11_m4_plan_round1.json`,
applied to this plan and `sprint_R1-M4-JOURNEY.json` only:

| # | Defect | Fix and where it landed |
|---|---|---|
| B1 | M4.1 dependency contradiction (markdown "startable now, glow_pole only" vs JSON `depends_on: [M4.6a]`; false "disjoint files / parallel" wave 1) | JSON `M4.1_CONSEQUENCE_STUB.depends_on` → `[]`; step 2 (`glow_pole_w_m2`) stated as a separate later step gated on M4.6a's publish (⏸ P-pkg); the sim never computes 4 × `glowInwardFlux`. "Disjoint/parallel" wording removed (wave-1 heading, "Startable now", pace bullet). Pin-bump merge order stated under M4.6a and P-pkg: M4.1's PR (step 1, pin 0.5.1) merges first and touches none of `sim/ailang.toml`/`sim/ailang.lock`/`runtime/cache`; the pin bump lands in its own commit after P-pkg; step 2 follows on the bumped pin. `critical_path` no longer starts with M4.6a. Milestone table M4.1 Deps cell updated. |
| B2 | AC6 unsatisfiable by M4.4 under rule F4 (its command needs M4.5, which depends on M4.4) | AC6's playthrough command moved to **M4.5** (markdown M4.5 acceptance + JSON `M4.5_PLAYTHROUGH_AUDIT.acceptance_criteria`). M4.4 keeps a sim-test gate — `make sim` (`$A test --package sim`) asserting `news.body_source`/`fallback_reason` for the template, ai and fallback paths plus a scripted bridge session — and a "Feeds AC6" row. F4 (both files) reworded. |
| B3 | S1 ordering not executable (S1 blocked merges whose inputs land later; no stacking mechanism) | Mechanism chosen and stated: M4.2, M4.3b and M4.6's gated half land as **stacked PRs into integration branch `m4-track-b`**; `make capture-m4` runs on `m4-track-b` and S1 is shown from that branch; the branch merges to main after S1 sign-off. Stated in the pause-points table (S1 row + "S1 mechanism" note), the Milestones intro, the critical-path paragraph, and the M4.2 / M4.3b / M4.6 notes (markdown **Merge:** lines; JSON descriptions and `pause_points[S1]`). |
| NB1 | R1-M1-SKY-2 called "unapproved" — it was APPROVED by Mark (ledger D-19, attended 2026-10-02); only its JSON `approved` flag is stale | Reworded in F5 (both files), the Risks table, and JSON `external_dependencies[0]`. |
| NB2 | M4.5 `depends_on` omitted M4.2/M4.3b although AC4's audit/final run and AC7's walking proxy exercise the interior | Added to M4.5's Deps (markdown section + milestone table) and JSON `depends_on`. |
| NB3 | M1.2d (PR #69, α Cen A/B astrometry) missing from M4.6 although the "arrived at α Cen" render/arrival view use the bright tier | Checked the doc: no G-M4 golden pins the A/B separation, so it is **soft**; added to M4.6's Deps (markdown + milestone table), JSON `M4.6_PHYSICS_GATES.depends_on` and `external_dependencies[1].needed_by`. |
| NB4 | gpt6-1-sol's round-2 absence not recorded as a named hole | "Quorum note" added to the Summary (round 2 ran with that seat ABSENT; disposition on the 3 present external reviewers); JSON finding F7; surfaced to Mark in Q3 and again at ⏸ P-land. |
| NB5 | M4.1 size risk (700 LOC vs the 650 cap; M2 overran ~1.5×) | Not pre-split: the design doc owns the sub-milestone structure and estimates (10 rows), and it cannot be changed here, so an M4.1a/M4.1b pre-split would add an 11th milestone the doc does not define. Risk stated (realistic ~1,000 changed lines) with the **named split point** (the `ship.ism` seam): on overrun step 1 lands as M4.1 and step 2 becomes follow-up M4.1b, already gated on ⏸ P-pkg (F1, Risks table, JSON `loc_cap_exceptions`). |

Not actionable here (design-doc file, out of this revision's scope): the
design doc's "9 sub-milestones" status line vs its 10-row table, and AC1's
19-minute τ_b bound being a 0.3 % margin (consider a `scriptedRoundTrip`
assertion). Left for the design doc's owner.

Totals unchanged: **10 milestones, 4 waves, 3,220 counted LOC (1,900 code +
1,320 tests)**; `approved: null`, every `passes: null`.
