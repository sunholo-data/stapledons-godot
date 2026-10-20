# Sprint R2-STAR-SURFACES: resolved stellar surfaces and eclipse layers

**Design doc:** [star-surfaces.md](star-surfaces.md)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-STAR-SURFACES.json`
**Status:** **Awaiting approval** (D-99 asked for the design; Mark answers OQ1–OQ9 before SS-1). Nothing in this plan has been executed. The spike in `spike/star_surfaces/` is throwaway and is deleted at SS2.
**Branches:** this plan is on `design/star-surfaces` (from `origin/main` 5addab05); execution runs on `feat/star-surfaces` from `origin/main` after approval.
**AILANG:** v0.54.14 (pinned). New AILANG code: the `stellar` module in `sunholo/celestial` (in a scratch clone of `sunholo-data/ailang-packages`) and the sim's star data and protocol section. Syntax gate: `ailang check --package` beside `ailang test --package` (CLAUDE.md: only `check` enforces STRICT_FALLBACK_001). Registry reuse: `sunholo/celestial` 0.4.0 (`reflect` is the pattern: probe → `tests/test_physics.gd`); `sunholo/relativity` 0.12.0 unchanged (Doppler and the blackbody LUT are already mirrored in `Blackbody`).
**Estimate:** about 1,600 LOC, **8.5 working days**, excluding Mark's review at the SS2 pause and the publish go at SS0. That is about 190 LOC a day, under the recent attended rate of about 300.
**Plan review:** one independent Sonnet pass (read-only `claude -p --model sonnet`) scored the first draft 66/100 with seven blocking issues; all seven are folded in (design doc §D2, §D4, §D6, §Acceptance criteria; this plan; the JSON). Review: `.ailang/state/evaluations/eval_R2-STAR-SURFACES_plan_round_1.md`.

## What the survey found

- **The disc shader** (`planets/planet.gdshader`, `star` branch) ray-traces the sphere per sample and, under way, applies Doppler per sample (`bb(temp)` → `bb(temp*d)`), so a per-element temperature fits its optics. At rest it uses one uniform `tint`, and the bb LUT is bound only when moving (`SystemView._draw_disc`): SS2 binds it for every star disc.
- **Limb darkening has no package home** (`Planets.limb_darkened` in GDScript only; the shader mirrors it): a gate-3 gap this sprint closes.
- **Catalogue and destination stars send `limb_u 0`** (`sim/protocol.ail` `starBodyObj`); the Sun sends 0.6 and keeps it (AC5).
- **Apparent sizes at the stops** (measured with `tools/stops_capture.gd`): Aldebaran 60.9°, α Cen A 11.1°, Barnard 4.4°, TRAPPIST-1 3.5°, the Sun from home 0.54°.
- **The Auto fader** brings a star's disc centre to 1.2 pre-tonemap and never brightens; its peak (`SystemView._displayed_peak`) must include the map's maximum and, in an eclipse, switch to the visible peak.
- **Occlusion exists** (`occludes_direction`, `_point_transmission`, `transmission_toward`).
- **The golden count is pinned** at 393 (`Makefile`, `golden:`); `test:` and `ci-fast:` are explicit lists.
- **The spike** proved the gate and the cells at Aldebaran in the real game view; its frame timing was inconclusive (design doc §Spike results).

## Milestones

### SS-1: verify the citations (notes, 0.5 day)
- For every number in design §D1 and §D3: the paper, page or table, and the (Teff, log g) range it covers. In particular: Claret & Bloemen 2011 stops near 3,500 K, so TRAPPIST-1 (2,566 K) and Barnard's Star need a cool-dwarf table (a PHOENIX-based one, e.g. Claret, Hauschildt & Witte 2012), verified, never a clamp.
- Recorded in the sprint JSON (`citations`), and reproduced as named rows in `stellar_test.ail` (AC0).

### SS0: `sunholo/celestial` 0.5.0, module `stellar` (~300 LOC, 1.5 days) ⏸ Mark's go to publish
- **Red first:** `stellar_test.ail` with every check value from SS-1 (page/table in the test name): linear u = 0.6 = today's `Planets.limb_darkened` to 1e-15; each law's closed-form mean vs numeric quadrature to 1e-12; `ldCoeffs` at tabulated points; finite and monotonic in μ over each table's range; `cellSizeKm` = 1,300 km at the Sun; Aldebaran's ratio within 1% of (T/T☉)/(g/g☉); `diffRotation` at 0°, 30°, 60°; `baumbach` at r = 1.5, 2, 4; `lineColour` = the CIE line colour within 0.002 at D = 0.9, 1, 1.1 and exactly black outside 360–830 nm; two calls byte-identical.
- **Build:** the module; `CHANGELOG`; `[release] kind = "minor"`; `ailang pkg quality` with no gates. **Stop before publish** (Mark's go per release).
- **Probe:** `sim/tools/stellar_probe.ail`; `tests/test_physics.gd` asserts its values (`make physics`).
- **Gate:** in the scratch packages clone, `ailang test packages/celestial && ailang check --package packages/celestial && ailang pkg quality packages/celestial`; then `make physics`.

### SS1: sim data, protocol 2.13, wiring (~250 LOC, 1 day)
- **Red first:** `sim/stellar_surface_test.ail`: every finite star has `logg` with provenance; `surface` is a pure function of (seed, star id, t_e) with each field's provenance (`measured`/`inferred`/`chosen`); VM = interpreter; strict. The clock check (AC7): over 200 ticks of a scripted 0.9c approach to a static star, `Δt_e/Δτ` from the sim's own `t − light_age_s` equals D = 4.3589 ± 1e-6 (0.22942 receding). D is never applied again downstream.
- **Build:** `logg` fields (cited; inferred stars marked `inferred`); `surfaceOf(star, seed)` in `sim/core.ail` via the package; protocol 2.13 `surface` object (additive). Pin `sunholo/celestial` 0.5.0 and run `ailang lock`.
- **Wiring:** `mk/star-surfaces.mk` (included from the `Makefile`) defines `stellar-protocol-test`, `star-surface-test`, `star-surface-bench`, `star-surface-capture`. `stellar-protocol-test` and `star-surface-test` join `test:`; `stellar-protocol-test` (pure) joins `ci-fast`. GPU targets stay rig-only.
- **Gate:** `make strict parity replay sim-test stellar-protocol-test` (2.12 and earlier replays byte-identical; a new 2.13 golden recorded).

### SS2: the renderer (~650 LOC, 3.5 days) ⏸ Mark reviews the stops
- **Red first:** `tests/test_star_surface.gd` (`make star-surface-test`): flux (RS-24, β = 0) at every finite star's stop and the four seeded views in `tests/fixtures/star_surface/views.json`, CPU quadrature to 1e-4 against a 4× denser grid, and the single-spot closed form to 1e-6; the gate is exactly zero below threshold; a spot's colour at T_spot within 0.002, at rest and at β = 0.9; float64-reduced phases only (`phase-f64`); fader peak ≤ 1.2. Goldens G-SS-1..5 added first, failing; the golden count pin moves 393 → 398 with its message.
- **Build:** `physics/star_surface.gd` (CPU mirror: LD law, temperature map, gate, normaliser, phases); the normaliser's cache keyed by (star, view quantised to 2°, gate state to 1/16, phase to 1/64 of a lifetime), recomputed at most once a second off the frame path (≤ 50 ms); the shader's `star` branch with the bb LUT bound for every star disc and the per-element colour (design §D2); `SystemView` uniforms from the protocol's `surface`; `_displayed_peak` with the map's maximum; `ray_colour` through the mirror. Delete `spike/star_surfaces/`.
- **Bench, at the midpoint:** `make star-surface-bench`, first reproducing `tools/bh_ship_bench.gd`'s non-zero sky-viewport GPU reading (the spike's short harness read 0), then the Aldebaran stop at 1440p ≤ +0.5 ms. If it misses, switch to a cube map baked at arrival (OQ2) before going on.
- **Captures:** `make star-surface-capture` (Realistic and Auto at TRAPPIST-1, Barnard, α Cen A, Aldebaran, the Sun at home); open every frame; publish to `refs/star_surfaces/after/`.
- **Gate:** `make star-surface-test golden physics` and `make bench SCENE=bridge`.
- **Pause:** a dev build (`make publish-dev`, no `v*` tag) for Mark to visit the stops in Auto; he accepts the look or redirects (a ledger row in the attended session).

### SS3: eclipse layers (~250 LOC, 1.5 days)
- **Red first:** corona = Baumbach to 5% between 1.5 and 4 R in a real-pipeline Auto frame with the photosphere covered, and its displayed luminance at 2 R within [0.1, 0.6]; ≤ 1e-6 of the disc's light uncovered; the global `k` unchanged by the eclipse; Hα through `lineColour` (black ahead at 0.9c).
- **Build:** corona and limb layers in the star's quad (extended to 6 R); prominences from the package's statistics, seeded; occlusion from `SystemView`; `_displayed_peak` = the visible peak (photosphere if any is uncovered, else the corona's inner peak), blended in log space by the uncovered fraction.
- **A real eclipse state:** the Moon stop at a computed alignment, or a free-navigation point on the Sun–Moon line, or a TRAPPIST-1 planet crossing its star (3.5° disc, the size at which the corona reads, design §D6).
- **Gate:** `make star-surface-test golden`; captures opened and published.

### SS4: Archive, report and landing (~150 LOC + text, 0.5 day)
- An Archive entry (canon text, attended with Mark: OQ7); inspector labels from the `surface` provenance ("cells: chosen pattern, real size"); a hand-off note to D-96's framing doc.
- `design_docs/implemented/r2/star-surfaces-report.md`; a changelog fragment; the design-repo PR (RS-24, RS-25, the §2 note, `features/next/star-surfaces.md`) merged.
- `make test` on the rig (`tools/rig_check.sh <PR> --golden`); **the merge waits for `sunholo/celestial` 0.5.0 to be published and locked** (AC13); evaluation by a different model from the executor (`sprint-evaluator`, ≥ 70 to pass).

## Pause points

| After | Mark sees | Mark decides |
|---|---|---|
| Plan | this plan, the spike frames | OQ1–OQ9 |
| SS0 | `ailang pkg quality` output, the check values | go to publish `sunholo/celestial` 0.5.0 |
| SS2 | a dev build; Auto-view frames at each stop | the look (accept, or tune shape and contrast within the cited statistics) |

## Risks

See the design doc §Risks. Sprint-specific: SS1 waits on the SS0 publish; if it slips, SS2 may build against a local package path, but nothing merges until the pin is a published version (AC13).
