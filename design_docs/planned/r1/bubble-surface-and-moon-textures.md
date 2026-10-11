# Bubble surface cues and missing moon textures

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | Route, medium and commitment stay simulation-owned. |
| The Game Doesn't Judge | +1 | Instrument colouring explicitly distinguishes what is visible. |
| Time Has Emotional Weight | 0 | Existing impact timing and decay retained. |
| The Ship Is Home | +1 | Short surface marks communicate the enclosing bubble. |
| Grounded Strangeness | +2 | Actual lunar imagery and source-based map geometry replace generic grey/mesh cues. |
| We Are Not Built For This | 0 | Existing density, flux and energy budget retained. |

**Status:** Approved in Mark's attended 2026-10-11 instruction: implement the proposed restrained surface-smear comparison; investigate original moon textures and fix reported textureless Callisto; improve readable gas-cloud presentation without implying visible nebular fog. Net +4, aligned. R1, priority defect/presentation. Standing main merge/build/gallery instructions apply after technical gates.

## Scope and constraints

1. Keep package-owned event frequencies, energies, temperatures and decay. Change the wall footprint to a restrained equal-area tangent smear, oriented by incidence, with an asymmetric bend and soft antialiased edge. Surface shape is a labelled G-AG presentation approximation. Preserve the legacy circle mode for comparison and frozen reference cases. No lateral diffusion dynamics or new emission formula is claimed. The geometric mapping has unit area determinant; energy/temperature source remains relativity 0.12.0. Shapes stay attached to ray intersections with the spherical wall; bounds and overlap tests must enclose the longer shapes.
2. Trace original-repo images and current pins. Add missing real maps for Callisto and other supported moons where reliable licensed/global imagery exists. Use source attribution, content-addressed pins, existing albedo normalization and export bundle. Do not copy retired physics or reuse another body's texture as authentic. Audit source/export loaders and smoke tests so missing required maps cannot silently pass. Original local checkout is read-only.
3. Render low-opacity filled LIC/source-outline surfaces with restrained boundaries, retaining data geometry and uncertainty. Map colours describe density, not natural eye appearance. Keep D and depth guides, route readability and read-only controls. No invented filaments or newly inferred cloud structure. Warm local clouds and hot Local Bubble gas are distinct from luminous nebular scenes. Flight remains impact-driven wall light; do not add visible ambient fog.

## Checkable acceptance

- S1: Native circle/surface comparison from identical events, energy and camera; normal/glancing/off-centre views, seeded repeated runs; CPU geometry checks and GPU-vs-CPU masks/flux, same event counts and package references. `make dust-flash-test golden` plus `godot --path . --script tools/bubble_surface_capture.gd`.
- S2: Equal-area mapping and conservative bounds/overlap handling, original circle cases pass; strict core/parity unchanged. `make dust-flash-test golden strict parity`.
- M1: Callisto renders with its own pinned attributed real map in source and exported app, with other available supported moon maps audited. `make planet-verify planet-textures-check planets-test export-smoke-planets` plus opened native moon comparison.
- M2: Cold fetch/export bundles contain every declared texture; smoke expectations derive from table, no hard-coded nine-body loophole. `make planet-bundle export-smoke-planets`.
- C1: LIC and warm-cloud filled geometry derives from adopted source model; D/guide controls remain read-only; explicit false-colour/approximate-depth legend and visible stars/routes. `make map-ism-test free-nav-recovery-test` and opened native map capture.
- Q1: Complete local/matching CI, independent evaluator >=70, opened references, changelog/roadmap/report before main landing. `make test`, CI, `make site` if site changes.

## Research evidence

NASA APOD (https://apod.nasa.gov/apod/ap020210.html) describes the local ISM as tenuous with little emitted light and absorption in nearby stars. Gry & Jenkins (https://arxiv.org/abs/1609.02518) use UV absorption toward Regulus; surrounding hot gas emits soft X-rays. These are instrument visualizations, not a claim of eye-visible local nebulae. Published game afterglow is already explicitly G-AG; a new spatial footprint requires that label and equal-area evidence.

## Attended navigation and tour expansion (D-65)

Mark reported the standalone manual map cannot start Mars travel, inaccessible commitment and zoom, missing black-hole discovery, and redundant guided system/inward arrivals. He accepted Earth → Sun → Jupiter → Callisto → Saturn → one close Alpha Centauri arrival → one TRAPPIST-1 arrival → Aldebaran, with an optional labelled Sgr A* separate demo afterward.

- N1: Interactive standalone map uses the actual stationary free_nav scenario, preserving frozen capture/movie Sol sessions. Real Mars selection/commit works; Enter reviews, Space uses the existing hold or press-twice ritual, Esc backs out. Explicit zoom controls and the review footer are reachable at 450/600px heights. All variable content scrolls. Hidden/chart maps must not issue journey intents. Existing separate Sgr A* demo is discoverable, disabled while committed, and available after the guided tour. `make navigation-usability-test title-screen-test free-nav-recovery-test ship-ui-test ship-demo-input-test` plus an opened native navigation capture.
- T1: Guided D-54 finite-star arrivals eliminate the three outer-system/inward-hop duplicates without teleporting or changing formulas. Seven flying legs plus initial Earth remain; legacy stop_rule0 retains its ten-leg metadata/replays. Catalogue identity, physical distances/clocks, beta-zero endpoints, actual clearance, target-looking attitude and approach presentation are checked. No claim of a TRAPPIST habitable-zone planet stop. `make solar-departure-test tour-attitude-test tour-pacing-test strict parity` and opened native arrivals; source and exported native gates must use the same itinerary.

Audit evidence: current outer arrivals are about1,000AU from each star; inward hops are about0.0158ly (~5.77Earth light-days), not coordinate errors. The existing finite-stop planner accepts the interstellar speeds under the session cap; it is distinct from the body-intent0.99c cap. This is authoring and composition of published package math. New design formulas are unnecessary.
