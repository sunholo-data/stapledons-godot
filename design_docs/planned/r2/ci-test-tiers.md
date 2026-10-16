# CI test tiers: categorise `make test`, run it in parallel, and stop paying for duplicates

**Status:** Draft (proposed 2026-10-15), not yet scored or approved.
**Release:** infra (applies to every release; proposed under `design_docs/planned/r2/ci-test-tiers.md`)
**Milestone:** none (hygiene, triggered by Mark's request on 2026-10-15)
**Priority:** P1. One PR run of CI takes 55 to 85 min today, and a docs-only PR pays the same price (`docs/r1-landing` took 70 min on 2026-10-15).
**Implements:** CLAUDE.md "Definition of done" gates 1 to 6, unchanged. It touches no design-repo feature or physics-spec section. The release policy agreed today is that dev tags (`v*-dev.*`) build without CI and are gated by a local `make test`, and plain `v*` tags run the full suite through `release.yml`, which calls `ci.yml` via `workflow_call`.
**Depends on:** nothing new. It uses GitHub Actions job-level `if:` and `needs:`, plus a shell change detector (glue, so no Python).
**Estimated LOC:** about 250: `ci.yml` about 170, Makefile/`mk/ci.mk` about 60, `tools/ci_changes.sh` about 40.

## Game vision alignment

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | TBD (0?) | No gameplay change. |
| The Game Doesn't Judge | TBD (0?) | No gameplay change. |
| Time Has Emotional Weight | TBD (0?) | No gameplay change. |
| The Ship Is Home | TBD | Faster CI means more review builds reach Mark. |
| Grounded Strangeness | TBD | The physics gate is kept on every `sim/` change. |
| We Are Not Built For This | TBD (0?) | No gameplay change. |

Net: TBD (score with `game-vision-designer`). The expected result is weakly positive hygiene, so go.

## Problem

Evidence comes from two CI runs on GitHub's 2-core `ubuntu-latest` runner:

- **Run 38579592710** (PR, 2026-10-14) passed. The pre-steps took 14.3 min and `make test` took 67.6 min. All durations below come from this run unless marked otherwise.
- **Run 38718669155** (`ci.log`, 2026-10-15) failed at `ship-demo-consolidation-test`. It supplies the crew-target times and the per-test AILANG timings.

The main problems:

1. **The CI pre-steps run their tests twice.** All 18 targets in "Check navigation, input and ISM controls" (9.6 min) and "Check offline presentation and bootstrap" (4.7 min) are already prerequisites of `make test`. Each `make` call starts fresh, so they run again. That wastes 14 min per run, about 25 % of CI time.
2. **Everything runs serially in one job.** `ship-demo-ci` alone takes 31 min and `sim` takes 16 to 17 min.
3. **Three Godot tests fly in real time** (D-39 legs): `solar-departure-test` (649 s), `free-nav-stop-test` (259 s) and `moon-lifecycle-test` (233 s). Together they take 19 min, and wall time is their floor.
4. **The AILANG unit suite is serial.** `cd sim && ailang test --package .` takes 13.3 min wall (581 s of tests plus about 200 s of compile). The `ailang check --package sim` before it adds another 2.0 to 3.6 min.
5. **No path awareness.** A `design_docs/**` PR runs all of it. Only 5 checks read files that a docs PR could touch (table below).
6. **Duplicated checks inside `make test`** (section "Duplicates").

### Biggest time sinks (CI seconds)

| # | Target / part | s | Note |
|---|---|---:|---|
| 1 | CI pre-steps, both (duplicates) | 857 | every target is re-run by `make test` |
| 2 | `sim`: `ailang test --package .` | 798 | 464 tests; 581 s in tests, rest compile |
| 3 | `solar-departure-test` | 649 | real-time legs |
| 4 | `free-nav-stop-test` | 259 | real-time leg to Barnard's Star and α Cen A |
| 5 | `moon-lifecycle-test` | 233 | real-time legs, 900 s/leg bound |
| 6 | `parity-m4` | 226 | 55 s re-replays 3 cases `replay` already ran; 127 s positive control |
| 7 | `sim`: `ailang check --package sim` | 119–218 | possibly redundant with `ailang test --package` (verify) |
| 8 | `lens-lut-check` | 188 | pinned lens tables; only moves with pins or `sim/tools/lens_lut*` |
| 9 | `scene-session-audits` (playthrough + audits) | 128 | |
| 10 | `no-twitch-test` | 127 | 600 s of fake time |
| 11 | `strict` | 108 | |
| 12 | `playthrough-adversarial` | 105 | a second full playthrough |
| 13 | `strict-m5` | 85 | `navigationVm` 74 s repeats `navigation_test.ail` checks |
| 14 | `destar-test` | 80 | offline sky tool |
| 15 | `trappist1-test` | 76 | repeats `trappist1_test.ail` checks on strict VM and interpreter |

### Slowest AILANG tests (run 38718669155; `ailang test --package .`)

| s | File | Test |
|---:|---|---|
| 63.4 | `sim/trappist1_test.ail` | clearance: no planet's orbit comes within 30 radii of the resting ship |
| 54.2 | `sim/tools/catalogue_test.ail` | T4 N3 exact 50000 boundary with intervening missing rows |
| 33.9 | `sim/ism_inverse_test.ail` | all positive LUT knots and near-knot targets solve genuine interior crossings |
| 31.1 | `sim/core_ism_test.ail` | AC10b: every guided-itinerary leg (Sun .. Aldebaran, 10 legs) plans, flies and closes its ledger under lism-1 |
| 30.3 | `sim/ism_test.ail` | visible and bright thresholds match dust.visibleRadius within 0.1 % |
| 24.7 | `sim/solar_departure_test.ail` | destination stars are fed after α Cen in order; illuminance is V at Earth |
| 24.6 | `sim/solar_departure_test.ail` | Earth to Aldebaran: every leg is a true successive commit |
| 23.9 | `sim/solar_departure_test.ail` | the giant (Aldebaran) gets a 90 s final approach |
| 23.0 | `sim/trappist1_test.ail` | at the HZ stop the seven planets follow TRAPPIST-1 in the feed |
| 22.7 | `sim/trappist1_test.ail` | the system section carries each planet with teff_k 2566 and e1_au_lux |
| 22.6 | `sim/trappist1_test.ail` | the TRAPPIST-1 stop keeps the HZ rule and is placed beside e |
| 17.6 | `sim/solar_departure_test.ail` | timed in-system legs: 30 s boost, 50–70 s cruise, 25 s approach |
| 15.3 | `sim/solar_departure_test.ail` | D65 has seven finite highlight arrivals |
| 12.4 | `sim/crew_hold_test.ail` | plain days batched between flow points equal one advance a day |
| 9.1 | `sim/ism_test.ail` | AC6(a): at least 80 % of the 59 RL08 members cross their assigned cloud |

By file: trappist1 132 s, solar_departure 118, ism 58, navigation 57, catalogue 54, core_ism 48, ism_inverse 40, crew_hold 15, stops 14. The other 30 files take under 7 s each. A greedy 3-way shard by file balances at 194 s each.

## Goals and non-goals

**Goals.**

- PR wall time at or under 15 min, and a docs-only PR under 3 min.
- Every gate keeps its trigger. Physics check values (gate 2), the package mirror (3), strict VM and VM = interpreter parity (4), precision (5) and determinism (6) run on every change that touches `sim/`, `ai/`, `physics/`, shaders, package pins or the AILANG version.
- Local `make test` stays the complete headless suite, because the dev-tag gate depends on it.

**Non-goals.**

- No test deletions in this doc. Duplicates are listed for Mark to rule on (OQ3).
- No GPU work in CI: `make golden` and the captures stay local.
- No changes to the tests themselves, apart from splitting `parity-m4`.

## Design

### Path groups (computed once per PR by `tools/ci_changes.sh` → job outputs)

| Group | Paths (globs) |
|---|---|
| `ci` | `.github/**`, `Makefile`, `mk/**`, `tools/*.sh`, `tools/*.py`, `tools/python-allowlist.txt`. **Triggers every group.** |
| `sim` | `sim/**` (incl. `ailang.toml`/`ailang.lock`), `ai/**`, `tests/replays/**`, `tests/fixtures/**`, `tests/ai/**`, `tests/crew/**`, `data/**`, `physics/**` |
| `godot` | `**/*.gd`, `**/*.tscn`, `**/*.tres`, `**/*.gdshader*`, `project.godot`, `export_presets.cfg`, `assets/**`, `ui/**`, `interior/**`, `bridge/**`, `demos/**`, `sky/**`, `planets/**`, `physics/**`, `data/**`, `docs/m1.7/**` (golden read by `ui`), `website/docs/credits.md` (read by `planets-test`), **and everything in `sim`**, because most Godot tests drive the real sim (`GODOT_SIM`) |
| `docs-only` | true when *every* changed file matches `design_docs/**`, `changelogs/**`, `*.md` at root, `art/**/*.md`, `website/**`, `docs/**`, `.ailang/state/**`, `.claude/**`, `.agents/**`, **minus** the doc readers below |

Some docs are read by tests. When one of these files changes, the docs job runs the check that reads it:

| File | Read by | Cost |
|---|---|---:|
| `design_docs/implemented/r1/starmap-truth-audit.md` | `starmap-truth-audit` | <1 s |
| `design_docs/planned/r1/ism-archive-drafts/**` | `ism-lore-drafts` (moving this dir on landing breaks it) | <1 s |
| `data/lore/archive/*.md` (data, not docs) | `lore-check`, `in-world-voice-check`, `codex-test`, `export-filter-audit` | <3 s |
| `website/docs/credits.md` | `planets-test` | 1 s |
| `docs/m1.7/galaxy_map_panel.json` | `ui` | 2 s |

### Tiers

| Tier | When | What |
|---|---|---|
| **F** fast | every PR, including docs-only (docs-only runs the `test-docs` subset) | cheap, broad checks under 2 min |
| **P** path | PR, when its group changed (`sim` or `godot`); always on main and release | the bulk, split into parallel jobs |
| **M** main/nightly | push to main, nightly cron, PR label `ci:full`, and a PR touching the narrow owner paths (OQ1) | real-time flights, second playthrough, positive controls, 10k replay |
| **R** release | `v*` tag (not `v*-dev.*`) via `release.yml` → `workflow_call` | F + P + M with `REPLAY_TICKS=10000` and the lore cross-repo half. That is today's full suite in parallel. |

The dev-tag gate is a local `make test` (the full suite, unchanged).

### Parallel jobs and estimated wall time

Setup per job is about 60 s: checkout, AILANG, Godot, `make deps import` and asset fetches. The `sim-unit` compile overhead per shard is unmeasured (risk R2).

| Job | Tier / trigger | Targets | Measured s | Est. wall |
|---|---|---|---:|---:|
| `changes` | always | `tools/ci_changes.sh` → outputs | – | 0.3 min |
| `fast` | F | python-guard lint-precision deps physics ui lore-test lore-import-check lore-check news-lint news-test codex-test in-world-voice-check export-filter-audit crew-sync-check crew-events-check hello-pin acen-snapshot-verify ai-live-guard ai-core-verify star-catalogue-test catalogue-stats starmap-consistency starmap-consistency-large starmap-truth-audit test-bright-audit tools-test dust-flash-test map-ism-test bubble-surface-test ism-surfaces-test navigation-usability-test ism-lore-drafts wd-vm parity-v2 parity-v2-system parity-gr rng-ref | ~90 | 2.5 min |
| `docs` | docs-only PR | python-guard starmap-truth-audit ism-lore-drafts lore-check in-world-voice-check (+ ai-live-guard if `.github/**`) | ~40 | 1.5 min |
| `sim-unit` ×3 | P:sim | `ailang test` on 3 file shards (balanced 194 s each) | 782–798 total | 5–7 min each |
| `parity-core` | P:sim | strict replay(2k) parity-m4 (trimmed, see below) ism-oracle-check ism-data-verify ism-compat ism-determinism ism-bright-oracle crew-parity crew-perf session-audit-test codex-unlocks geodesic-oracle replay-compat | 315 (380 once crew_core 0.4.1 makes crewSkipUnheld ~71 s) | 6.5–7.5 min |
| `parity-systems` | P:sim | `ailang check --package sim`, strict-m5 trappist1-test guided-highlights-strict strict-ai ai-pkg-test ai-stub ai-adapter ai-loopback ai-playback-verify | 340–440 | 7–8.5 min |
| `pipelines` | P:sim | lens-lut-check destar-test sky-vm catalogue-vm catalogue-main catalogue-bytes extract-test truth-test bright-test companions-test starmap-test | 347 | 7 min |
| `godot-a` | P:godot | sim (bridge + bh-hud half), area-test validate-areas interior-test m4-smoke transit-test crew-bridge-test crew-console-test crew-hold-test ai-godot ai-relay replay-noai ai-settings ai-conversation planets-test planet-textures-check alpha-centauri-test ship-demo-smoke ship-demo-assets-test ship-demo-geometry-negative-test ship-demo-benchmark-test ship-demo-launch-test ship-demo-input-test ship-demo-journey-test ship-commons-* validate-ship-commons ship-demo-live-test ship-star-identification-test ship-demo-consolidation-test | ~285 | 6 min |
| `godot-b` | P:godot | title-screen-test ship-movement-test map-origin-test ship-planets-test ship-star-light-test catalogue-coverage-test flyby-optics-test planet-rings-test ring-protocol-test planet-meter-test ship-attitude-test benchmark-upload-test shadow-contacts-test tour-attitude-test bridge-floor-test planet-presentation-test exposure-frames-test manual-exposure-test sim-bootstrap-test tour-pacing-test ship-ui-test ship-console-test free-nav-recovery-test loading-jump-test | ~250 | 5.5 min |
| `playthrough` | P:godot | no-twitch-test scene-session-audits playthrough-negative | 267 | 5.5 min |
| `realtime-1` | M | solar-departure-test | 649 | 12 min |
| `realtime-2` | M | moon-lifecycle-test free-nav-stop-test | 492 | 9.5 min |
| `controls` | M | playthrough-adversarial replay-positive-control, `replay` at 10k ticks (main/release) | 232 + 10k delta | 6 min |
| `ci-ok` | always (`if: always()`) | aggregator; the only required status check; fails if any needed job failed (skipped = ok) | – | – |

**Resulting wall time (estimates):**

| Event | Jobs | Wall | Runner-min |
|---|---|---:|---:|
| Docs-only PR | changes, fast*, docs | ~2.5 min | ~4 |
| Godot-only PR (`ui/*.gd`) | changes, fast, godot-a/b, playthrough | ~6 min | ~20 |
| `sim/` PR (option B, recommended) | all P | **~8–9 min** (bound by `sim-unit`/`parity-systems`) | ~60 |
| `sim/` PR (option A: M also per PR) | all P + M | ~12.5 min (bound by `solar-departure-test`) | ~88 |
| main push / nightly / release | all | ~12.5 min | ~88 |
| Today | 1 job | 55–85 min | 55–85 |

\* On a docs-only PR `fast` could be skipped too. `docs` is the minimum.

### Duplicates and candidates for removal (OQ3)

| Duplicate | Cost | Proposal |
|---|---:|---|
| CI pre-steps "navigation, input and ISM" and "offline presentation and bootstrap" re-run 18 `make test` targets | 857 s | **delete both steps** (parallel jobs give fail-fast) |
| CI pre-step "transit replay" (`m4_transit_harness`) is also in `replay` and `parity-m4` | 20–42 s | delete |
| `parity-m4` re-replays `m4_min_path m4_adversarial m4_transit_harness` already replayed by `replay`; it only adds the `--sim-only` assertion | 55 s | keep one `--sim-only` case (`m4_transit_harness`), or have `replay` assert sim-only |
| `parity-m4` → `replay-positive-control` (a one-bit golden copy must be detected) is a meta-test of the harness | 127 s | move to `controls` (M) |
| `catalogue_test.ail` "T4 N3 exact 50000" (`checkN3`) runs in `ailang test` (interpreter, 54 s) **and** `catalogue-vm quotaVm` (strict VM + interpreter, 50 s) | ~54 s | drop the `test` wrapper; `quotaVm` already covers it on both engines |
| `navigation_test.ail` tests (57 s) and `strict-m5 navigationVm` → `navigationChecks()` (74 s) | ~57 s | likely the same checks; verify, then keep the VM = interpreter one |
| `trappist1_test.ail` tests (132 s) and `trappist1-test trappistVm` on both engines (76 s) | up to 132 s | verify overlap; keep the parity one |
| `solar_departure_test.ail` "D65 … highlight arrivals" (15 s) and `guided-highlights-strict directHighlightsVm` (20 s) | 15 s | verify, as above |
| `free_nav_test.ail` and `session_audit_test.ail` run under `ailang test` and again under `--strict-bytecode` (in `free-nav-recovery-test`, `session-audit-test`) | ~8 s | keep (the strict run is the point); cheap |
| `ailang check --package sim` before `ailang test --package .` (which reports "65 source modules") | 119–218 s | verify whether `test --package` type-checks every module; if so, drop `check` from CI |
| `validate-ship-demo` runs in `ship-demo-smoke` and `ship-demo-assets-test`; `lore-values` runs 3× (recursive makes); `import` reruns inside `scene-session-audits` | ~15 s | leave alone (cheap) |
| `playthrough` (scene) and `playthrough-adversarial` are two full Godot playthroughs | 105 s | adversarial goes to M |

## Inventory: every target `make test` runs (plus the CI pre-steps)

These are the closure of `test:` and the recursive `$(MAKE)` calls.

Gate key:

- **PHYS**: relativity-spec or package check values (gates 2 and 3).
- **STRICT**: runs on the strict VM (gate 4 purity).
- **PAR**: VM = interpreter (gate 4).
- **PREC**: precision (gate 5).
- **DET**: determinism and goldens (gate 6).
- **EXP**: export or ship audit.
- **DATA**: a pinned data pipeline.
- **UI**, **PLAY** (playthrough), **AI**, **LORE**, **POL** (policy).

Path key:

- **S**: `sim/**` plus package pins.
- **A**: `ai/**`.
- **G**: Godot code (`*.gd`, scenes, shaders, `ui/ interior/ bridge/ demos/ sky/ planets/ physics/`).
- **X**: `assets/**`.
- **D:x**: `data/x`.
- **C**: Makefile, `mk/` or CI.

Times are CI seconds (2-core runner). `<1` means under a second.

| Target | Guards (gate) | Breaks on | s | Tier/job |
|---|---|---|---:|---|
| *CI step: transit replay* (`replay.py --case m4_transit_harness`) | PAR, DET (dup of `replay`) | S, tests/replays | 20–42 | delete |
| *CI step: lore cross-repo* (`lore-import CHECK=1 D=…`) | LORE: `data/lore` = design repo at manifest sha | D:lore, design repo | 1–2 | F (keep; only CI has the clone) |
| *CI step: nav/input/ISM* (10 targets) | dup | – | 575 | delete |
| *CI step: presentation/bootstrap* (8 targets) | dup | – | 281 | delete |
| python-guard | POL: Python allowlist | `*.py`, allowlist | <1 | F, docs |
| lint-precision | PREC: no hand γ / 1−β outside physics/ | G (`*.gd`, shaders) | <1 | F |
| deps | DET: `sim/ailang.lock` resolution stable | S pins | <1 | F (setup) |
| starmap-assets | DATA: large tier sha | D:starmap | <1 | setup |
| lens-assets | DATA: lens tables sha | D:lens | 5 | setup |
| import | Godot class registry | G | 5 | setup |
| physics | **PHYS** CPU reference vs check values (773 asserts) | G physics/, sky shaders mirror, D:lens | 4 | F |
| sim: `ailang check --package sim` | type-check | S | 119–218 | P parity-systems |
| sim: `ailang test --package .` | **PHYS**, DET unit tests (464) | S | 782–798 | P sim-unit ×3 |
| sim: `test_sim_bridge.gd` | sim vs closed-form kinematics over NDJSON (**PHYS**) | S, G bridge/ | 24–37 | P godot-a |
| bh-hud-test | **PHYS** GR HUD sentinels, Sgr A* demo | S, G ui/ demos/ | 8–10 | P godot-a |
| ui | UI: galaxy map + plan panel vs real sim | G ui/, S, docs/m1.7 golden | 2 | F |
| lore-test | PAR, LORE binding (strict VM = interp) | S tools/lore*, D:lore | 1 | F |
| codex-test | LORE/UI: codex, unlocks vs real sim | G ui/, D:lore, S | 2 | F |
| lore-import-check | LORE: manifest hashes | D:lore | <1 | F |
| lore-values | LORE/**PHYS**: HB rows = package values | S pins, D:lore | <1 | F |
| lore-check | LORE: hints, ids, numbers bind | D:lore | <1 | F, docs |
| news-lint | UI/LORE: template lint + fixture | D:news | <1 | F |
| news-test | UI: news panel over real sim | G ui/, D:news, S | 3 | F |
| replay | **PAR**, DET: 11 logs + 2k session, VM = interp = golden | S, tests/replays | 68 | P parity-core |
| parity-v2 | **PAR**: protocol v2 session, silent-until-hello | S protocol/ship | 5 | F |
| strict | **STRICT**, **PAR**, **PHYS** closed forms (core, protocol, world, gr, stops, rng, crew…) | S | 108 | P parity-core |
| rng-ref | DET: SplitMix64 vs Python oracle, chi-square | S rng.ail | 3 | F |
| wd-vm | **PHYS** WD NaN contract, strict VM | S pins, sim/tools | <1 | F |
| catalogue-vm | STRICT, PAR, DATA: transform/selection/quota | S tools/catalogue* | 51 | P pipelines |
| catalogue-main | PAR, DATA: writer bytes | S tools/catalogue* | 1 | P pipelines |
| catalogue-bytes | DATA: F32 bytes vs Python oracle, 5 VM runs | S tools/catalogue* | 2 | P pipelines |
| catalogue-stats | DATA: committed tier stats | D:starmap | 1 | F |
| star-catalogue-test | DATA: Godot binary tier loader | G sky/, D:starmap | 3 | F |
| bright-test | STRICT, PAR, DATA | S tools/bright* | 1 | P pipelines |
| companions-test | STRICT, PAR, DATA | S tools/companions* | 3 | P pipelines |
| starmap-test | STRICT, PAR, DATA | S tools/starmap* | <1 | P pipelines |
| truth-test | STRICT, PAR, DATA | S tools/truth* | 1 | P pipelines |
| starmap-truth-audit | DATA: disagreements listed in **design doc** | D:starmap, `design_docs/implemented/r1/starmap-truth-audit.md` | 1 | F, docs |
| starmap-consistency | DATA: destinations once, ≤1e-9 ly | D:starmap, G sky/ | 1 | F |
| starmap-consistency-large | DATA: large tier 331,311 rows | D:starmap | 2 | F |
| test-bright-audit | DATA: bright-star auditor on synthetic renders | G tools/ | 1 | F |
| sky-vm | STRICT, PAR: sky-model fitter | S tools/sky_model* | 18 | P pipelines |
| extract-test | STRICT, PAR: VizieR parser | S tools/extract* | 1 | P pipelines |
| destar-test | STRICT, PAR: star removal core | S tools/destar* | 80 | P pipelines |
| tools-test | harness: replay unit, star names, asset fetch scripts | tools/ | 2 | F |
| area-test | UI/EXP: bundle loader + positive controls | G interior/, X areas | 20 | P godot-a |
| validate-areas | EXP: area bundle V17 | X areas | 12 | P godot-a |
| interior-test | **PHYS** glow mirror vs package probe, composite | G interior/, S pins | 4 | P godot-a |
| m4-smoke | PLAY: walk to console, commit, cruise (real sim) | G, X, S | 12 | P godot-a |
| transit-test | UI/PLAY: warp, burns, arrival card (real sim) | G, S | 3 | P godot-a |
| trappist1-test | STRICT, PAR, oracle: TRAPPIST-1 | S trappist1*, D:planets | 76 | P parity-systems |
| parity-m4 (replays) | PAR, DET: sim-only (dup of `replay`) | S | 55 | P parity-core (trim) |
| parity-m4 (refusals) | PAR: adversarial refusals, state unchanged | S | 44 | P parity-core |
| replay-positive-control | harness meta-test | tools/replay.py | 127 | M controls |
| session-audit-test | STRICT, PAR: session audit | S tools/session_audit* | 1 | P parity-core |
| codex-unlocks | DET: min-path unlocks | S, D:lore | 2 | P parity-core |
| geodesic-oracle | **PHYS** GR geodesic oracle vs package pins | S pins, tools/geodesic_ref.py | <1 | P parity-core |
| lens-lut-check | **PHYS**, PAR: sampled LUT regen = pinned bins | S pins, sim/tools/lens_lut*, D:lens | 188 | P pipelines |
| parity-gr | **PAR**, **PHYS**: GR session, Sgr A* mass | S | 2 | F |
| ism-oracle-check | **PHYS** dust oracle | tools/ism_dust_ref.py | 3 | P parity-core |
| ism-data-verify | DET: ISM data regen byte-equal | S tools/ism_build*, D:ism | 2 | P parity-core |
| ism-compat | PAR: frozen 2.7 session | S | 3 | P parity-core |
| ism-determinism | **DET**, STRICT: 2 runs = interp | S ism*, protocol | 34 | P parity-core |
| dust-flash-test | **PHYS** CPU mirror vs package, LUT finite (PREC) | G sky/, shaders | <1 | F |
| map-ism-test | UI: map medium layer | G ui/, D:ism | <1 | F |
| ism-lore-drafts | LORE: drafts cite registered ids | `design_docs/planned/r1/ism-archive-drafts/**` | <1 | F, docs |
| in-world-voice-check | LORE/POL: D-67/D-68 wording | D:lore, D:news, D:ai, G ui/ strings | <1 | F, docs |
| crew-sync-check | DATA: crew pack = SYNC | D:crew, S data/crew_pack | <1 | F |
| crew-bridge-test | UI: crew at protocol 2.9 (real sim) | G bridge/, S crew* | 4 | P godot-a |
| crew-events-check | DATA: death templates = lossTemplateIds | D:news, S crew_events | <1 | F |
| crew-console-test | UI: crew page | G ui/, S | 2 | P godot-a |
| crew-hold-test | UI/PLAY: holds | G, S | 2 | P godot-a |
| crew-perf | perf budget (2 s / 150 s ceiling), strict VM | S crew*, pins | 4 (→~71) | P parity-core (OQ4) |
| crew-parity | **PAR**, DET: 4 recordings | S crew*, tests/crew | 10 | P parity-core |
| export-filter-audit | EXP: `res://` reads vs export filters | G, export_presets.cfg | <1 | F |
| deps-ai | DET: `ai/ailang.lock` | A | <1 | P parity-systems |
| strict-ai | STRICT, PAR: markers, ai, wire | S markers/ai | 23 | P parity-systems |
| ai-pkg-test | AI: package tests, no sim import | A | 8 | P parity-systems |
| ai-stub | AI, PAR: 5 key sets, goldens | A, tests/ai | 2 | P parity-systems |
| ai-adapter | AI: adapters, prompt goldens | A, tests/ai | 1 | P parity-systems |
| ai-loopback | AI: POST halves vs loopback | A | 1 | P parity-systems |
| replay-compat | DET: 2.1 minus new = 2.0 goldens | S, tests/replays/compat-2.0 | 15 | P parity-core |
| ai-godot | AI: bridge faults | G bridge/ai_bridge.gd, A | 25 | P godot-a |
| ai-relay | AI: relay, key hygiene | G bridge/, A | 7 | P godot-a |
| replay-noai | AI: no service launch in replay | G, A | <1 | P godot-a |
| ai-core-verify | AI/DATA: core index, fixture import | D:ai | 1 | F |
| ai-live-guard | POL: nothing can start a live provider (scans make/CI/scripts) | C, G bridge/ ui/settings, tools/replay.py | 35 | F (+docs if `.github/**`) |
| ai-settings | AI/UI: settings panel, keys 0600 | G ui/settings/ | 2 | P godot-a |
| ai-conversation | AI/UI: Medic conversation on stub | G, tests/replays/medic_rehearsal | 2 | P godot-a |
| ai-playback-verify | AI/DATA: WAV↔Ogg | A, D:ai | 1 | P parity-systems |
| strict-m5 | STRICT, PAR: sol/acen data, system, navigation | S data/, celestial, navigation | 85 | P parity-systems |
| parity-v2-system | PAR: 2.3 system lines | S protocol | <1 | F |
| hello-pin | **PHYS** pin: protocol relativityPin = toml | S protocol.ail, ailang.toml | <1 | F |
| acen-snapshot-verify | DATA: exoplanet snapshot pin | D:planets | <1 | F |
| planet-assets | DATA: textures sha | D:planets | ~10 | setup (godot-a) |
| planets-test | UI: SystemView, albedo table; reads `website/docs/credits.md` | G planets/, D:planets, website credits | 1 | P godot-a |
| planet-textures-check | DATA: albedo = p_V within 1 % | X planets, D:planets | 8 | P godot-a |
| alpha-centauri-source-test | STRICT, PAR, **PHYS**: α Cen physics + navigation | S alpha_centauri* | 2 | P godot-a |
| alpha-centauri-test | UI: α Cen fixture | G, S | 1 | P godot-a |
| ism-bright-oracle | **PHYS** Python oracle (rapidity integration) | tools/ism_bright_ref.py | 1 | P parity-core |
| bubble-surface-test | UI/**PHYS** mirror | G sky/ shaders | <1 | F |
| ism-surfaces-test | UI | G sky/ | <1 | F |
| navigation-usability-test | UI | G ui/ | 2 | F |
| guided-highlights-strict | STRICT, PAR | S solar_departure | 20 | P parity-systems |
| validate-ship-demo | EXP: ship manifest | X ship_demo | <1 | P godot-a |
| ship-demo-test | UI: ship demo (244) | G demos/ | 1 | P godot-a |
| ship-demo-lift-test | UI | G demos/ | 4 | P godot-a |
| ship-demo-assets-test | EXP + negative fixture | X ship_demo | 1 | P godot-a |
| ship-demo-geometry-negative-test | EXP: mutants fail | X ship_demo | 1 | P godot-a |
| ship-demo-benchmark-test | perf report shape | G demos/ | 2 | P godot-a |
| ship-demo-launch-test | UI: launch | G demos/, main | 41–49 | P godot-a |
| ship-demo-input-test | UI: input | G demos/ ui/ | 2 | P godot-a |
| ship-demo-journey-test | PLAY: journey | G, S | 2 | P godot-a |
| ship-commons-test / -assets-test / validate-ship-commons / ship-commons-arcade-test | EXP/UI: commons | X ship_commons, G | 15 | P godot-a |
| ship-demo-live-test | PLAY: live sim journey, runtime fingerprint | G, S | 48–53 | P godot-a |
| ship-star-identification-test | UI: star identification | G, D:starmap | 3–4 | P godot-a |
| free-nav-stop-test | PLAY, real-time leg | G ui/body_info, S navigation/stops | 223–259 | **M** realtime-2 |
| ship-demo-consolidation-test | PLAY: live rest clock (failed 2026-10-15) | G, S | 3 | P godot-a |
| title-screen-test | UI | G ui/ main | 11 | P godot-b |
| ship-movement-test | UI | G demos/ | 3 | P godot-b |
| map-origin-test | UI | G ui/ | 3 | P godot-b |
| ship-planets-test | UI | G planets/ | 1 | P godot-b |
| ship-star-light-test | UI/**PHYS** star light | G sky/ | 4 | P godot-b |
| catalogue-coverage-test | DATA/UI | D:starmap, G | <1 | P godot-b |
| solar-departure-test | PLAY, real-time legs Earth→Aldebaran | G demos/solar_departure.gd, S solar_departure/stops | 649 | **M** realtime-1 |
| flyby-optics-test | **PHYS** optics checks (1061) | G sky/ planets/ | <1 | P godot-b |
| planet-rings-test / ring-protocol-test / planet-meter-test | UI/**PHYS** | G planets/, S | 3 | P godot-b |
| ship-attitude-test / benchmark-upload-test / shadow-contacts-test / bridge-floor-test | UI | G | 4 | P godot-b |
| tour-attitude-test | UI | G, S | 6 | P godot-b |
| planet-presentation-test | UI (806 checks) | G planets/ | 1–4 | P godot-b |
| moon-lifecycle-test | PLAY, real-time legs | G demos/solar_departure.gd, S | 233 | **M** realtime-2 |
| exposure-frames-test / manual-exposure-test | **PHYS** exposure (1364 + 291 checks) | G sky/ | 10 | P godot-b |
| sim-bootstrap-test | UI: sim launch | G bridge/, S | 8 | P godot-b |
| tour-pacing-test (+ destination-pin, cruise-interlude) | UI | G, D:starmap | 3 | P godot-b |
| ship-ui-test | UI (219) | G ui/ | 56 | P godot-b |
| ship-console-test | UI (120) | G ui/ demos/ | 47 | P godot-b |
| no-twitch-test | UI pillar NT1/NT2, 600 s fake time | G | 127 | P playthrough |
| playthrough (via scene-session-audits) | PLAY: scripted ship walk | G, S | 102 | P playthrough |
| playthrough-time / codex-unlocks / display-audit(-controls) (scene) | DET/UI: audits of the scene session | S tools/session_audit, G | 26 | P playthrough |
| playthrough-adversarial | PLAY: re-plan/cancel/commit in transit | G, S | 105 | **M** controls |
| playthrough-negative | harness: driver failures exit nonzero | tests/test_playthrough.sh | 12 | P playthrough |
| free-nav-recovery-test | UI + strict free_nav + VM = interp fixture | G, S free_nav | 62 | P godot-b |
| loading-jump-test | UI: lightspeed loading | G ui/ | 15–22 | P godot-b |

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | Every target in the `make test` closure is assigned to exactly one CI job (no orphan, no double) | `make ci-manifest-check` (compares `make -pRrq` closure of `test` with the union of `CI_JOB_*` lists) |
| AC2 | Local `make test` covers the same targets as before (dev-tag gate intact) | `make ci-manifest-check BASE=origin/main` (closure diff empty, renames listed) |
| AC3 | The path detector classifies the fixtures correctly: `sim/core.ail` → sim+godot; `ui/x.gd` → godot only; `design_docs/x.md` → docs-only; `design_docs/planned/r1/ism-archive-drafts/a.md` → docs+lore; `.github/workflows/ci.yml` → all | `sh tools/ci_changes.sh --self-test` |
| AC4 | Physics gate: any `sim/**`, `physics/**`, shader or pin change runs `fast` (physics), `sim-unit`, `parity-core`, `parity-systems` and `pipelines` | `sh tools/ci_changes.sh --files sim/gr.ail physics/x.gd sky/s.gdshader sim/ailang.toml` prints `sim=true` for each |
| AC5 | No CI pre-step duplicates `make` targets; each summary line appears once per run | `gh run view <id> --log \| grep -c '^.*free-nav-recovery: .* 0 failures'` = 1 |
| AC6 | PR wall time ≤ 15 min (median of 5 non-docs PRs) | `gh run list --workflow ci.yml --event pull_request --json createdAt,updatedAt,conclusion` |
| AC7 | Docs-only PR ≤ 3 min and runs `docs` | `gh run view <docs PR run> --json jobs` |
| AC8 | main and release runs include `realtime-*`, `controls` and `REPLAY_TICKS=10000` | `gh run view <main run> --json jobs`; log contains `session10k` |
| AC9 | `ci-ok` is the single required check and fails when any needed job fails | a deliberately failing branch: `gh pr checks` |

## Sub-milestones and estimates

| Step | Change | LOC | Order |
|---|---|---:|---|
| T1 | Delete the 3 duplicate pre-steps (keep the lore cross-repo step). This alone saves ~15 min per run. | 10 | first, standalone PR |
| T2 | `mk/ci.mk`: `CI_JOB_*` target lists, `test-fast`, `test-docs`, `test-sim-unit SHARD=k/3`, `test-parity-core`, `test-parity-systems`, `test-pipelines`, `test-godot-a`, `test-godot-b`, `test-playthrough`, `test-realtime-1/2`, `test-controls`, `ci-manifest-check`; `test:` stays the union (`test-full` alias) | 70 | after T1 |
| T3 | Split `sim` into `sim-check`, `sim-unit` (shardable; list the test files per shard, rebalanced from timings) and `sim-bridge` (bridge + bh-hud). Split `parity-m4` into `parity-m4` (one sim-only case + refusals) and `replay-positive-control`. | 30 | with T2 |
| T4 | `tools/ci_changes.sh` (`git diff --name-only base...head` → `$GITHUB_OUTPUT`, `--self-test`, `--files`) | 40 | with T2 |
| T5 | `ci.yml`: `changes` job, matrix/parallel jobs with `if:` on outputs, `ci-ok` aggregator, `schedule:` nightly, `ci:full` label, `REPLAY_TICKS` per event, setup as a composite action (`.github/actions/setup`) | 170 | after T2–T4 |
| T6 | Measure one PR and one main run; rebalance shards; record numbers in the report | – | last |
| T7 | (after OQ3) remove the confirmed duplicate checks | ~20 | separate PR |

### Concrete Makefile/workflow changes (not made)

1. `.github/workflows/ci.yml`: delete the steps "Check transit replay before full suite", "Check navigation, input and ISM controls before full suite" and "Check offline presentation and bootstrap before full suite".
2. `ci.yml`: add `on: schedule: - cron: '17 3 * * *'`, and on `pull_request` add `types: [opened, synchronize, reopened, labeled]` (for `ci:full`).
3. `ci.yml`: add a `changes` job that runs `sh tools/ci_changes.sh "${{ github.event.pull_request.base.sha }}" "${{ github.sha }}"` and outputs `sim`, `godot`, `docs_only`, `ci` and `full`. `full` is true on push, schedule, `workflow_call` and the `ci:full` label.
4. `ci.yml` jobs: `fast`, `docs`, `sim-unit` (`strategy.matrix.shard: [1,2,3]`, `make test-sim-unit SHARD=${{ matrix.shard }}/3`), `parity-core`, `parity-systems`, `pipelines`, `godot-a`, `godot-b`, `playthrough` (`if: needs.changes.outputs.<group> == 'true' || needs.changes.outputs.full == 'true'`), and `realtime-1`, `realtime-2`, `controls` (`if: needs.changes.outputs.full == 'true' || <owner paths>`). Add `ci-ok` (`needs: [all]`, `if: always()`, fail on any `failure`/`cancelled`).
5. Add `.github/actions/setup/action.yml`, which installs AILANG v0.54.8 and Godot 4.7.2, then runs `make deps import starmap-assets lens-assets` (and `planet-assets` where needed). Optionally cache `~/.ailang/cache` and `.godot/` keyed on `sim/ailang.lock`, `ai/ailang.lock` and the Godot version.
6. Add `mk/ci.mk`, included from `Makefile` (`ai-live-guard` requires includes to live under `mk/`). It defines `CI_JOB_FAST := …` and similar lists per job, a `test-<job>: $(CI_JOB_<JOB>)` target per job, `test-full: test`, and `ci-manifest-check`.
7. `Makefile`: split `sim:` into `sim-check`, `sim-unit` and `sim-bridge` (with `sim: sim-check sim-unit sim-bridge` kept). `sim-unit` takes `SHARD=k/n` and runs `cd sim && ailang test <files>` per shard. If `ailang test` takes one file only, loop over the files; the per-call compile cost is unknown, so measure it in T6.
8. `mk/m45.mk`: in `parity-m4`, replace `--case $(M45_CASES)` with `--case m4_transit_harness`, and move `$(MAKE) replay-positive-control` to a `test-controls` target.
9. `release.yml`: unchanged. It calls `ci.yml` via `workflow_call`, where `full=true`. Dev tags keep skipping CI.
10. Branch protection: require only `ci-ok`.

## Risks and mitigations

| # | Risk | Mitigation |
|---|---|---|
| R1 | A real-time regression (solar departure, moons, free-nav stop) merges and is caught only on main | Main runs it within ~12 min of merge. Dev tags are gated by local `make test`. The `ci:full` label and owner-path triggers add coverage, and option A (OQ1) keeps them per PR at ~12.5 min wall. |
| R2 | `sim-unit` shards each pay the full compile (~200 s seen as test overhead, `check` 119–218 s), so the estimate of 5–7 min could be 8–9 | Measure in T6. If compile dominates, use 2 shards plus an AILANG cache, or report a parallel `ailang test --jobs` upstream (DX). |
| R3 | A path filter misses a dependency (e.g. a test reads a new data file) | `sim` triggers Godot jobs. `ci`/Makefile/`mk` changes trigger all. Nightly and main run everything. Docs-only is an allowlist with doc-reader exclusions. |
| R4 | Job lists drift from `make test` (a new `test: foo` line goes unassigned) | `ci-manifest-check` runs in `fast` and fails on orphans (AC1). |
| R5 | ~60 runner-min per `sim/` PR (about the same as today), and ~88 on main | The repo is public, so billing is unchanged (OQ2, resolved). Concurrency is 20 jobs on free plans, and 12 jobs fit. |
| R6 | `crew-perf` timing budgets on shared runners flake when parallel jobs share hosts | Each job has its own VM. Keep the 150 s ceiling (D-82) and watch it after crew_core 0.4.1 (~71 s). |
| R7 | Setup duplicated ×12 (installs, asset fetches from the public bucket) | A composite action plus caches. Bucket fetches are a few seconds each. |

## Open questions for the user

| # | Question | Default if unanswered |
|---|---|---|
| OQ1 | Should the real-time flights (`solar-departure-test` 649 s, `moon-lifecycle-test` 233 s, `free-nav-stop-test` 259 s) and `playthrough-adversarial` run on **every PR** in parallel (option A: ~12.5 min wall), or on **main/nightly/`ci:full`** plus owner paths (option B: ~8–9 min wall)? | B |
| OQ2 | Is the repo public? Runner minutes are free if so, and billed if private. | **Resolved 2026-10-15:** public (`gh repo view`), so the extra minutes are free. |
| OQ3 | May the confirmed duplicates be deleted from one side? These are `checkN3` in `ailang test`, the `navigation_test`/`trappist1_test`/D65 overlaps (once verified), the `parity-m4` re-replays, and `ailang check` if `test --package` covers it. | keep both until ruled |
| OQ4 | Should `crew-perf` (a wall-clock budget) stay in PR CI, or move to main only? | PR (cheap today) |
| OQ5 | Should docs-only PRs skip `fast` too (only `docs`)? | run `docs` only |

## Deliverables

- `ci.yml` (parallel, path-aware), `.github/actions/setup/action.yml`, `mk/ci.mk`, `tools/ci_changes.sh` (+ allowlist entry if any).
- Makefile splits (`sim`, `parity-m4`) and per-job targets.
- A report with the measured PR, main and docs-only wall times, and the rebalanced shards.
- A changelog fragment.

Timing sources: `gh run view 38579592710 --log` (PR, passed, 2026-10-14) and `ci.log` run 38718669155 (PR, failed at `ship-demo-consolidation-test`, 2026-10-15). Times are attributed per target from each target's summary line in the timestamped log. Recipes print their logs on completion, so the gap before a summary line belongs to that target.
