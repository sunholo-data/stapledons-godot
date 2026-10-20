# R2-STAR-SURFACES: resolved stellar surfaces you can see when the disc is dimmed

**Status:** **Approved** 2026-10-20 by Mark, attended ("yeah good continue"), with every recommendation: ledger D-105. Executing on `feat/star-surfaces`. Asked for in D-99. Plan review: one independent Sonnet pass scored the first draft 66/100 with seven blocking issues, all folded in (`.ailang/state/evaluations/eval_R2-STAR-SURFACES_plan_round_1.md`). Nothing is built. The spike in `spike/star_surfaces/` is throwaway: it is outside the export filter and not wired into `make`. Sprint plan: [star-surfaces-sprint.md](star-surfaces-sprint.md).

**Release:** R2. **Milestone:** the look of a star at a stop, and the eclipse framings of D-96.

**Priority:** P2. It is visible at every finite-star stop and costs nothing at a cruise, where every star is a point.

**Mark's direction** (attended, 2026-10-20, verbatim):
> another strand is we could have more impressive textures for the stars/sun - we are dimming them anyway, so we can see structure?

**What this doc takes from that:**
- **He is right that the dimming is already there.** The Auto view (D-38) fades a star's disc until its centre sits at 1.2 (linear, pre-tonemap) so its colour survives; that is a solar filter in all but name. Today there is nothing under the filter: Aldebaran at its stop is a flat 1,125 px disc of one colour (`limb_u 0`, "uniform photosphere").
- **Real stars have structure at exactly the scales our stops show.** Aldebaran's convection cells are about 2.7 solar radii across, so its disc at the stop holds about 33 of them, each about 34 px wide. TRAPPIST-1's spots are a few px across. The Sun from Earth is 10 px and shows nothing but its limb.
- **So the texture must be honest physics, gated by resolution.** A structure appears only when its true size would resolve at the current apparent size; the disc's total light never changes; colour comes from a temperature, so Doppler colours it as it colours the disc.
- **Eclipses are where the rest lives.** The corona, chromosphere and prominences are a millionth of the disc and appear only when something covers the photosphere: they belong to the authored eclipse and transition framings Mark asked for (D-96).

**Implements** (design repo):
- [physics/relativity-spec.md §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md): "a blackbody at T is seen as a blackbody at D·T" applied per surface element, and the extended-source radiance rule. This doc proposes two new check values (RS-24, RS-25, §D7; RS-19 to RS-23 already exist) in a design-repo PR.
- [features/finite-destination-stars](https://github.com/sunholo-data/stapledons-design) as implemented by `design_docs/implemented/r1/relative-size-stops.md` (D-47, D-54): the stop rules that set every apparent size in §Problem.
- **D-96** (eclipse and transition framings, the spire as the deep-space light), **D-38** (Realistic and Auto exposure), **D-59** (the white view at high c stays: no glare pass).
- **Ledger:** D-38, D-47, D-54, D-59, D-96, D-99.

**Depends on:**
- **Package first (CLAUDE.md gate 3).** Stellar limb darkening exists today **only in GDScript** (`Planets.limb_darkened`, `physics/planets.gd:80`) and the shader: no package holds it, which already breaks gate 3. SS0 moves it, with the new laws, into a new `stellar` module of `sunholo/celestial` (0.4.0 → 0.5.0).
- **Protocol 2.13** (one additive section; replays and digests of older minors unchanged, §D5).
- No AILANG change. No change to `sunholo/relativity`.

**Estimated LOC:** about 1,600 in all: about 500 AILANG (package module and tests, sim data, protocol), about 550 GDScript and shader (renderer, CPU mirror, fader), about 550 tests, tools and goldens. The sprint plan schedules 8.5 days.

## Game vision alignment

Scored with the `game-vision-designer` skill in feature-validation mode against `vision/core-pillars.md`, D-38, D-54 and D-96, on 2026-10-20. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | Presentation only; no decision changes |
| The Game Doesn't Judge | 0 | Neutral |
| Time Has Emotional Weight | +1 | A star's surface moves on its own clock as received: granules boil at the stop, and the same surface seen ahead at speed runs √19 times faster at 0.9c (§D4). The universe visibly does not wait |
| The Ship Is Home | 0 | Seen from the bridge; no change to the ship |
| Grounded Strangeness | +2 | Each star type looks like itself for real reasons: a giant's few huge cells, a red dwarf's spots, the Sun's quiet limb. Every pattern's size, contrast and lifetime is a cited number, never decoration |
| We Are Not Built For This | +1 | A giant's single convection cell is three Suns wide; standing off Aldebaran makes the scale felt |
| **Net** | **+4** | **Go.** No pillar is negative |

## Problem

**1. Every star disc is one flat colour.** `planets/planet.gdshader` (the `star` branch) draws a flux-normalised linear limb-darkened disc, `L(μ) = L0 (1 − u (1 − μ))`, with `u = 0.6` for the Sun and `u = 0` for every catalogue and destination star (`sim/protocol.ail` `starBodyObj`: "uniform photosphere"). Measured with `tools/stops_capture.gd` on `origin/main` 5addab05 (720p frames; px below are at 1440p, 18.46 px per degree at the 78° view):

| Stop (free navigation, D-54) | Apparent diameter | Disc across (1440p) | What it shows today |
|---|---|---|---|
| Aldebaran (K5 III giant, 0.415 AU) | 60.93° | 1,125 px | a flat orange disc, no limb darkening |
| α Cen A (G2 V, 0.059 AU) | 11.05° | 204 px | a flat disc |
| Barnard's Star (M4 V, inferred radius) | 4.36° | 80 px | a flat disc |
| TRAPPIST-1 (M8 V, 0.018 AU) | 3.46° | 64 px | a flat disc |
| The Sun from Earth (home) | 0.53° | 10 px | limb-darkened, unresolved |

Evidence: the baseline frames in §Evidence. I opened the Aldebaran, TRAPPIST-1 and Earth frames.

**2. Stellar limb darkening has no package home** (gate 3, above), and one linear coefficient is wrong for a 2,566 K dwarf and a 3,927 K giant alike.

**3. The Auto view already dims each disc for its colour** (`SystemView.FADER_STAR_TARGET`, 1.2), so structure would survive the tone mapper; in the Realistic view the disc is clipped at `clip_max` (1024, pre-tonemap) and stays a white disc, as the eye sees it (D-59).

**4. Nothing can show an eclipse's corona.** A body in front of the Sun draws as a black disc over a black sky.

## Goals and non-goals

**Goals**
- A star's disc shows the structure its real surface would show **at that apparent size**: limb darkening per type, granulation, giant convection cells, spots and faculae; nothing larger, nothing finer than a few px.
- **The disc's total light is unchanged** (CPU quadrature to 1e-4, a closed-form spot check to 1e-6, GPU golden to 0.5%), so photometry, exposure, the Auto fader, the star light on the ship (`demos/ship_star_light.gd`) and every existing golden stay put.
- **Colour comes from temperature:** each surface element is a blackbody at its own T, seen at D·T (spec §2), so a spot is redder and Doppler treats the surface exactly as it treats the disc today.
- **Time is the star's, as received:** the surface evolves on the emission clock; under way, intervals compress by D (§D4).
- **Eclipse layers** (corona, chromosphere, prominences) render whenever a body covers the photosphere, sized and dimmed to cited values, as the substrate for D-96's authored framings.
- **Deterministic:** seeded by the voyage seed and the star's id; no hidden state; byte-identical replays.
- **Cheap:** at most +0.5 ms GPU at the worst stop (Aldebaran, 1440p); zero cost when every star is a point.

**Non-goals**
- No solar glare, bloom or glazing (D-59).
- No hydrodynamics. Patterns are seeded noise whose **statistics** (cell size, contrast, lifetime, spot sizes and latitudes) come from the package; the pattern itself is not a simulation of any real day on any star.
- No rotational Doppler across the disc: at the Sun's 2 km/s it changes D by 7e-6, invisible (it is stated, not modelled).
- No flares in this sprint (OQ6). No supergranulation in white light: its intensity contrast is below 1% (OQ4).
- No authored eclipse shots: those are D-96's later doc; this sprint makes the layers exist and checks them.
- No change to points: a star under `Planets.DISC_PX` (2 px) stays a point source with today's PSF.

## Design

### §D1 What is real, what is chosen, what is not shown

| Feature | Real numbers (to be cited in the package, SS0) | Shown when | In the game |
|---|---|---|---|
| **Limb darkening** | nonlinear laws (quadratic, Claret 4-parameter) per Teff and log g (Claret & Bloemen 2011, A&A 529 A75, for Teff ≥ 3,500 K; for cooler dwarfs a PHOENIX-based table such as Claret, Hauschildt & Witte 2012, A&A 546 A14: coverage to be verified in SS-1; Sun: Neckel & Labs 1994, Sol. Phys. 153 91) | disc ≥ 2 px | every star that sends `limb_u 0` today (catalogue and destination stars); **the Sun keeps linear u = 0.6**, so its pixels stay bit-identical (§D2) |
| **Granulation** (Sun, FGK dwarfs) | cells ≈ 1.0–1.5 Mm, about 1,000 across the Sun; rms contrast ≈ 13–15% at 500 nm at disc centre, falling to the limb; lifetime ≈ 5–10 min | cell ≥ 1.2 px, full at 4 px | never at today's stops (α Cen A's cells are 0.16 px), only on a very close pass |
| **Giant convection cells** | cell size ≈ 10 pressure scale heights, `H_p ∝ T_eff / g` (Freytag, Steffen & Dorch 2002; Trampedach et al. 2013): for Aldebaran (log g 1.11, Heiter et al. 2015) ≈ 1,450 × the Sun's, ≈ 2.7 R☉, ≈ 33 across the disc; higher contrast than the Sun's; lifetime weeks to months | always at the Aldebaran stop (34 px per cell) | the showcase |
| **Supergiants** (future destinations) | a handful of cells across the disc (Schwarzschild 1975, ApJ 195 137; Chiavassa et al. 2009/2010; Montargès et al. 2016 on Betelgeuse) | when a supergiant is a destination | the same law, few cells |
| **Sunspots** | umbra ≈ 0.2–0.3, penumbra ≈ 0.75–0.85 of quiet-Sun intensity (visible continuum); penumbral radius 10–25 Mm; latitudes ±5–35° drifting equatorward over the 11-year cycle; lifetimes days to months | spot ≥ 0.6 px, full at 2 px | α Cen A's big spots at 2–3 px; never on the Sun from 1 AU (0.12 px) |
| **Faculae** | brightening near the limb, up to ≈ +10% at μ ≈ 0.2, ≈ 0 at disc centre, around active regions | with their spots | rim brightening around spot groups |
| **M-dwarf spots and faculae** | large cool spots and bright faculae inferred from TRAPPIST-1's transits (Rackham et al. 2018, ApJ 853 122; Morris et al. 2018, ApJL 863 L32); coverage within the cited range | spot ≥ 0.6 px | TRAPPIST-1 and Barnard's Star: spots 5 px across |
| **Rotation, differential** | Sun: Ω(φ) = A + B sin²φ + C sin⁴φ, A 14.713, B −2.396, C −1.787 °/day sidereal (Snodgrass & Ulrich 1990) | over a long dwell | spots drift with latitude-dependent speed |
| **Corona** | K+F corona radiance ≈ 1e-6 of disc centre, Baumbach (1937): I(r)/I₀ = 1e-6 (0.0532 r^−2.5 + 1.425 r^−7 + 2.565 r^−17), r in R☉ | photosphere covered | eclipses only (§D6) |
| **Chromosphere and prominences** | Hα (656.3 nm) emission; chromosphere ≈ 2 Mm thick (0.003 R☉); prominences 10–100 Mm high | photosphere covered and the limb ≥ a few px | pink limb arcs in eclipses; line colour Doppler-shifted (§D6) |

Anything in the right-hand column that is "chosen" (seeded layout of cells and spots, a spot's exact shape) is labelled as such in the Archive and the inspector. Everything sized or timed comes from the package with a citation.

### §D2 Surface as a temperature map, not an intensity map

The surface is a **map of local effective temperature** `T(x) = T_eff · (1 + δ(x))` over the stellar sphere, where δ is the sum of the seeded layers (granulation or cells, spots, faculae). The shader already computes, per sample, the radiance of a blackbody at `T` and its Doppler-shifted look at `D·T` (`bb(temp)`, `bb(temp*d)`). It now uses the local T instead of one T:

```
L(x)  = L_mean · LD(μ) / ⟨LD⟩ · Y(T(x)) / Y(T_eff) / N          (rest frame, cd/m²)
seen  = L(x) · [Y(D·T(x)) / Y(T(x))] · D-scaling as today          (spec §2)
```

- `Y(T)` is the CIE luminance of the Planck spectrum (the existing blackbody LUT, `Blackbody`), so a temperature contrast becomes the right visible contrast for that star: `d ln I / d ln T` at 550 nm is 4.6 for the Sun, 6.7 for Aldebaran and 10.2 for TRAPPIST-1, which is why cool stars' spots are so dark.
- `N` is the flux normaliser: the disc integral of `LD(μ)·Y(T(x))/Y(T_eff)·gate` over the visible hemisphere, so `∫ L dΩ` equals the sim's `e_v_lux`. It is computed on the CPU in float64 by a stratified quadrature (64 × 64 in (μ, φ), the same function as the shader through the mirror), **cached** by (star, view direction quantised to 2°, gate state quantised to 1/16, phase quantised to 1/64 of a lifetime), and recomputed at most once a second, off the frame path; budget ≤ 50 ms per recompute. The convergence check is against a 4× denser grid to 1e-4; an independent closed-form check uses a single circular spot of known temperature at disc centre. This holds **at β = 0**; under way, D varies across the disc and the disc's flux follows the existing Doppler rule, which is unchanged. Real stars do change their light with their spots (by ≈ 0.1% for the Sun); we choose not to, so that every photometric number stays the sim's (OQ3).
- Contrast parameters are stated as temperature fluctuations derived from the cited intensity contrasts (13–15% at 500 nm for the Sun → σ_T ≈ 3%).

**Which stars change.** The Sun keeps today's linear law (u = 0.6, a fair V-band fit), so every Sun pixel stays bit-identical (AC5). Every star that sends `limb_u 0` today gets its per-type law from `ldCoeffs`; their discs change at every size above 2 px, by design, with the flux unchanged (the law is normalised by its closed-form mean). The existing `star lux` and `sky cd/m²` goldens measure flux and sky radiance, not a star's disc profile, and must stay byte-identical (AC4).

**The exact colour expression.** Today, under way only, the shader multiplies the rest radiance by `(seen.rgb / rest.rgb) · 10^(seen.a − rest.a)` with `rest = bb(emitter_temp_k)`, `seen = bb(emitter_temp_k · d)`, and at rest uses the uniform `tint` (`Blackbody.rgb_unit_luminance(teff)`). With a map, `emitter_temp_k` becomes `T(x)` in both terms, and at rest the colour is `bb(T(x)).rgb` normalised to unit luminance instead of the uniform `tint`, so **the bb LUT is bound for every star disc, moving or not** (today it is bound only when `moving`, `SystemView._draw_disc`). Spec §2's band rule (RS-5 to RS-8) is unchanged; it is applied per element.

**Resolution gate.** Each layer's amplitude is multiplied by `smoothstep(lo, hi, s_px)`, where `s_px` is that layer's feature size in pixels on screen (cell or spot angular size × px per radian, foreshortened by μ). `lo/hi` = 1.2/4 px for cells and 0.6/2 px for spots. Below `lo` the layer is exactly zero, so a 10 px Sun is today's disc bit for bit, and so is every point. The same gate stops shimmer when the camera or the stop changes size. The supersampling (`ss`) stays.

**Where the pattern lives.** Procedural in the shader (3D Worley cells on the unit sphere, seeded), driven by uniforms from the sim's numbers. No texture assets, no VRAM, no pipeline step. A CPU mirror in GDScript (`physics/star_surface.gd`) evaluates the same function for the flux normaliser, the golden and the eye meter. (Alternative: a baked cube map per star at arrival; recommended only if SS2's frame-time check fails, OQ2.)

### §D3 Package, sim and protocol

**`sunholo/celestial` 0.5.0, new module `stellar`** (package first; tests, CHANGELOG, `[release] kind = "minor"`, `ailang pkg quality` with no gates; Mark's go to publish, D-ruling per release):
- `limbDarkening(law, coeffs, mu)` for `linear`, `quadratic`, `claret4`; `ldMean(law, coeffs)` (the disc mean, closed form for each law); check values: the Sun's linear u = 0.6 reproduces today's `Planets.limb_darkened` to 1e-15; Claret quadratic tables at two (Teff, log g) points.
- `ldCoeffs(teff, logg)`: a cited table (Claret & Bloemen 2011, V band), bilinear in (Teff, log g), clamped and finite across the whole range (CLAUDE.md precision rule: every lookup table is finite across its range, with a test).
- `scaleHeightRatio(teff, logg)` = (T/T☉)/(g/g☉) and `cellSizeKm(teff, logg)` = 1,300 km × ratio (Sun anchor cited); `granContrastT(teff, logg)` (σ_T, cited anchors: Sun, a K giant from a 3D grid; interpolated in log g).
- `spotContrastT(teff)` (spot temperature deficit: Sun umbra ≈ 1,500–2,000 K below; M dwarfs a few hundred K; cited) and `spotLatitudeBand(cyclePhase)`.
- `diffRotation(latDeg)` (Snodgrass & Ulrich 1990).
- `baumbach(r)` (corona) and `prominenceRadiance` (a cited fraction).
- Probe values go to `tests/test_physics.gd` through `sim/tools/stellar_probe.ail`, as `planets_probe.ail` does for `reflect`.

**Sim (`sim/data/stars.ail`, the Sun in `sim/data/sol.ail`):** each finite star gets `logg` (Aldebaran: Heiter et al. 2015, 1.11 ± 0.19; TRAPPIST-1: Agol et al. 2021; α Cen A and B: cited; inferred stars: from R and an assumed mass, provenance `inferred`), and a `surface` record computed in `sim/core.ail` by the package: law and coefficients, cell size, σ_T, spot list (seeded: voyage seed ⊕ star id, positions in the star's own frame using the star's pole where known), rotation law, corona on/off. Pure, strict-VM, VM = interpreter.

**Protocol 2.13:** a `surface` object on each finite star in the system section (additive; 2.12 and earlier byte-identical; replay goldens re-recorded only for 2.13 sessions, with the old ones kept). The renderer never invents a stellar number; it maps these fields to uniforms.

### §D4 Time: the star's clock, as received

- The surface's phase is the **emission time** of the light arriving now: `t_e = t_sim − light_age_s`, both already in the protocol, so it is deterministic and replays exactly.
- At a stop (β ≈ 0) the surface evolves at its real rate: the Sun's granules turn over in about 8 minutes of game time; Aldebaran's cells over weeks.
- **D enters only through `light_age_s`, never as an extra factor.** For a ship closing on a static source, light age shrinks as it closes, so `dt_e/dτ = γ(1 + β) = D` follows from the sim's own `t_e`; multiplying by D again would double-count. Seen ahead at 0.9c, a surface runs √19 = 4.36 times faster (proposed check value RS-25), and AC7 measures it from the sim's `t_e` series, not from a renderer formula. In practice every star under way is a point, so this matters only for the eclipse and arrival framings, and for honesty.
- **Precision.** `t_e` reaches 10⁹–10¹⁰ s over a voyage; as a float32 uniform its step would be 64–1,024 s, coarser than a granule's life. The CPU reduces it in float64 to one phase per layer, `fract(t_e / lifetime)`, and passes only those (CLAUDE.md gate 5: float64 scalars where precision matters).
- Spot evolution (days) and the activity cycle (11 years for the Sun) advance with `t_e` too, so a star revisited decades later has different spots, and the Sun seen at home after a long voyage is at a different point of its cycle (pillar 3).

### §D5 Renderer

- `planets/planet.gdshader` `star` branch: the LD law and the temperature map (§D2); uniforms set by `SystemView._draw_disc` from the protocol's `surface` record; `surf_norm` from the CPU mirror.
- `SystemView._displayed_peak` uses the brightest displayed surface (centre × the map's maximum), so the Auto fader keeps the hottest cell under 1.2.
- `ray_colour` (the eye meter and the CPU goldens) samples the same map through the mirror.
- The point/disc handoff (G-M5-6) is unchanged: below 2 px every layer's gate is zero.
- `ship_star_light.gd` reads `e_v_lux` and the eclipse transmission as today; the corona adds 1e-6 of the light and is ignored there (stated).

### §D6 Eclipse layers (the substrate for D-96)

- **When:** a body's disc covers part or all of the star's photosphere (`SystemView` already knows occlusion: `occludes_direction`, `_point_transmission`, `transmission_toward`).
- **Corona:** drawn by the star's own quad, extended to 6 R, Baumbach radiance × a seeded streamer modulation (chosen, labelled), colour = the photosphere's (it is scattered photospheric light), Doppler as the disc.
- **Chromosphere and prominences:** Hα line emission, not a blackbody. Their colour is the line's colour at λ = 656.3 nm / D (a new package function `lineColour(lambda0, D)`: the CIE colour of a monochromatic line). It is defined for every D and is **black outside 360–830 nm**: seen ahead at 0.9c Hα lands at 151 nm and the prominences vanish, which is what an eye would see. At a stop it is the familiar pink. Heights and counts from the package, seeded. The spike's prominences (3e-5 of the disc) were lost in the bright inner corona; SS3 checks they read in the eye-adapted frame.
- **Exposure (the mechanism).** The global exposure `k` is unchanged by any of this. In the **Realistic** view the corona is drawn at the physical `k`: at the star-friendly exposure a 10³ cd/m² corona saturates near the limb, as the spike's first pass showed, which is what a dark-adapted eye at totality would also call blinding near the limb. In the **Auto** view the per-body fader (`fader_gain`, never a brightening) decides: `_displayed_peak` becomes the **visible** peak, the photosphere's when any of it is uncovered, else the corona's inner peak (r = 1.05 R), blended in log space by the uncovered photospheric fraction through partial phases. So at totality the star's gain dims the corona's limb to the fader target instead of dimming the (hidden) photosphere's, and the outer corona falls off as Baumbach says. No global `k` change, no brightening; other bodies in the frame keep their own gains. AC9 checks a real-game eclipse frame through the whole pipeline.
- **Size matters (spike finding).** The corona falls as r⁻⁷ near the limb: at the eye-adapted exposure it reads from about 1.1 to 2.5 R and is gone by 3 R. With the Sun 10 px across (home, 1 AU) the whole corona is a 10–25 px ring, unreadable at the 78° view; with a 3.5° disc (TRAPPIST-1 at its stop, or the Sun from 0.15 AU) it is the classic crown (§Spike results). So an eclipse is a set piece only when the star is big: at a stop, from a planet near a dwarf star (TRAPPIST-1's planets cross its 3.5° disc), or in a D-96 framing that narrows the view. This is input for D-96's doc, not a camera change here.
- **The diamond ring needs glare.** The last sliver of photosphere is a bead a few px wide; the real "ring" is glare, which D-59 ruled out for the forward view. OQ8 asks whether a point-spread bloom (the starfield's existing PSF, `Exposure.psf_sigma_angle`) may apply to an occulted sliver only.
- **Not here:** authored framings, cameras or timing of eclipses (D-96's later doc).

### §D7 Spec additions (design-repo PR [#37](https://github.com/sunholo-data/stapledons-design/pull/37))

- **RS-24:** the disc-integrated V luminance of a temperature-mapped stellar disc equals the uniform disc's at β = 0 (flux preservation), tolerance 1e-4 (CPU quadrature), 1e-6 (closed-form single spot) and 0.5% (GPU).
- **RS-25:** the apparent rate of a source's surface evolution, seen straight ahead at 0.9c, is D = √19 = 4.3589 times its proper rate (and 0.22942 straight astern).
- A short **§2 note**: "A resolved emitter with surface structure is a map of local temperature; each element is a blackbody at T(x) seen at D·T(x)."
- A feature doc `features/next/star-surfaces.md` (what the player sees per star type; the eclipse layers; no spoilers).

## Acceptance criteria

New targets are defined in `mk/star-surfaces.mk` (included from the `Makefile`). `star-surface-test` and `stellar-protocol-test` join the `test:` list; `stellar-protocol-test` is pure and also joins `ci-fast`; the GPU targets (`golden`, `star-surface-bench`, `star-surface-capture`) stay rig-only, as today. Nothing here is Python (`python-guard` unchanged), except an optional quadrature **oracle** for AC3, listed in `tools/python-allowlist.txt` with role `oracle` if used.

| AC | What | Command (log line) |
|---|---|---|
| AC0 | Every cited number pinned: a table of (value, source, page/table, Teff and log g range) in `stellar_test.ail`; LD coverage for TRAPPIST-1's 2,566 K verified, not clamped from a hotter table | the AC1 command; the SS-1 verification note in the sprint JSON lists each source |
| AC1 | `sunholo/celestial` 0.5.0 `stellar`: every check value passes; linear u = 0.6 equals today's `Planets.limb_darkened` to 1e-15; each law's closed-form mean equals a numeric quadrature to 1e-12; the LD tables are finite and monotonic in μ over their whole (Teff, log g) range | In a scratch clone of `sunholo-data/ailang-packages`: `ailang test packages/celestial && ailang check --package packages/celestial && ailang pkg quality packages/celestial` (0 failures, no gates); after Mark's go, `ailang pkg info sunholo/celestial` shows 0.5.0 |
| AC2 | The sim emits `surface` for every finite star (protocol 2.13), each field with provenance; deterministic: two runs byte-identical; VM = interpreter; strict; replays of 2.12 and earlier byte-identical | `make strict parity replay sim-test stellar-protocol-test` (`stellar-protocol: OK n stars`) |
| AC3 | Flux (RS-24, at β = 0): for every finite star at its stop and at the four fixed views in `tests/fixtures/star_surface/views.json` (seeded directions), the CPU quadrature of the mapped disc equals `e_v_lux` to 1e-4 against a 4× denser grid; a single circular spot at disc centre matches its closed form to 1e-6 | `make star-surface-test` (`star-surface: flux OK n/n`, `spot-oracle: OK`) |
| AC4 | GPU = CPU: the mapped disc's pixel sum matches the CPU integral to 0.5% at Aldebaran, α Cen A and TRAPPIST-1; the centroid within 0.75 px; the `star lux` and `sky cd/m²` cases and every other existing line byte-identical; the golden count pin moves 393 → 398 (G-SS-1..5) with its message | `make golden` (`G-SS-1..4 ok`, 398 `ok` lines) |
| AC5 | The Sun (linear u = 0.6 kept) and every point source render **bit-identical** to `origin/main` at home; at α Cen A the granulation layer contributes exactly 0 | `make golden` (`G-SS-5 ok: identical to main`); `make star-surface-test` (`gate: OK`) |
| AC6 | Colour from temperature: a spot's rendered chromaticity is the blackbody's at T_spot within 0.002 (RS-5 method), at rest (LUT bound) and at β = 0.9 ahead (D·T_spot) | `make star-surface-test` (`colour: OK`) |
| AC7 | Time (RS-25): measured from the sim's own `t_e = t − light_age_s` over 200 ticks of a scripted approach at 0.9c toward a static star, `Δt_e/Δτ` = 4.3589 ± 1e-6 (and 0.22942 receding); the renderer receives only float64-reduced phases | `make stellar-protocol-test` (`clock: OK`); `make star-surface-test` (`phase-f64: OK`) |
| AC8 | Auto fader: the brightest displayed texel ≤ 1.2 pre-tonemap at every stop; Realistic frames unchanged where the disc clips | `make star-surface-test` (`fader: OK`); `make golden` |
| AC9 | Eclipse through the real pipeline: from a sim state where a body covers the photosphere (SS3 finds or scripts one), in the Auto view the corona's displayed luminance at 2 R is within [0.1, 0.6] pre-tonemap and its profile follows Baumbach to 5% between 1.5 and 4 R; uncovered, the corona adds ≤ 1e-6 of the disc's light; the global `k` is the same with and without the eclipse | `make star-surface-test` (`corona: OK`, `eclipse-frame: OK`) |
| AC10 | Hα colour: `lineColour(656.3 nm, D)` equals the CIE chromaticity of the line at λ/D within 0.002 at D = 0.9, 1, 1.1, and is exactly black for λ/D outside 360–830 nm (ahead at 0.9c: 151 nm) | AC1 command; `make star-surface-test` (`line: OK`) |
| AC11 | Frame time: sky viewport GPU time at the Aldebaran stop, 1440p, rises ≤ 0.5 ms, read the way `tools/bh_ship_bench.gd` reads it (`viewport_get_measured_render_time_gpu(demo.sky.get_viewport_rid())`, which read 0 in the spike's short harness: SS2 first reproduces bh_ship_bench's non-zero reading); ship scene p99 < 16.7 ms on a quiet rig | `make star-surface-bench` (`star-surface-bench: +x.xx ms ≤ 0.50`); `make bench SCENE=bridge` |
| AC12 | Renders opened and published: Realistic and Auto at TRAPPIST-1, Barnard, α Cen A, Aldebaran, the Sun at home; an eclipse partial and total from the AC9 state | `make star-surface-capture` (`star-surface-capture: OK 12 frames`), frames at `gs://stapledons-voyage-assets/refs/star_surfaces/after/` |
| AC13 | `make test` green on the rig with the new targets in it; `rig/full` on the PR head; **the merge is blocked until `sunholo/celestial` 0.5.0 is a published, locked version** (no local-path pin on main) | `tools/rig_check.sh <PR> --golden`; `grep 'sunholo/celestial' ailang.lock` shows 0.5.0 from the registry |

## Sub-milestones and estimates

| Id | What | LOC | Days | Depends |
|---|---|---|---|---|
| SS-1 | Verify and pin every cited number (papers, pages, tables, Teff and log g coverage); record in the sprint JSON | 0 (notes) | 0.5 | approval |
| SS0 | `sunholo/celestial` 0.5.0 `stellar` module, tests, probe; **stop before publish** (Mark's go) | 300 | 1.5 | SS-1 |
| SS1 | Sim data (log g, surface record with provenance), protocol 2.13, determinism, parity, the clock check; `mk/star-surfaces.mk` and the `test:`/`ci-fast` wiring | 250 | 1 | SS0 published |
| SS2 | Renderer: LUT always bound, LD laws, temperature map, resolution gate, CPU mirror and cached normaliser, float64 phases, fader peak; goldens G-SS-1..5 and the count pin; bench (decide procedural vs baked at the SS2 midpoint) ⏸ Mark reviews the stops | 650 | 3.5 | SS1 |
| SS3 | Eclipse layers: corona, Hα chromosphere and prominences, line colour, the visible-peak fader rule; a real eclipse state; captures | 250 | 1.5 | SS2 |
| SS4 | Archive entry (canon text, attended), inspector labels, report, evaluation, landing | 150 | 0.5 | SS3 |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A citation's number differs from my memory in this doc | SS0 pins every value from the paper, with the page or table, before any code uses it; the doc's numbers are marked "≈" and are design targets, not check values |
| Frame cost at Aldebaran (a 1,125 px disc, 9 samples per px) | Spike measurement (§Evidence); evaluate the pattern once per pixel and supersample only at the limb; fall back to a cube map baked at arrival (OQ2) |
| Auto fader brightens or dims differently | AC8; the peak includes the map's maximum |
| Goldens drift | The gate is exactly zero below threshold; AC5 demands bit identity for unresolved discs and points |
| A protocol bump ripples into replays | Additive section; old minors unchanged; replay goldens only for 2.13 |
| Spots read as dirt at 2–3 px | The gate's upper edge (2 px) and Mark's frame review at the SS2 pause |

## Open questions for Mark (with recommendations)

**All resolved by D-105 (2026-10-20): every recommendation approved.** OQ1 honest gate; OQ2 procedural, cube-map fallback past +0.5 ms; OQ3 total light fixed; OQ4 no supergranulation; OQ5 eclipse layers now; OQ6 flares later with sound; OQ7 one Archive entry, attended; OQ8 PSF bloom on an occulted sliver only; OQ9 structure in Auto only.

| OQ | Question | Recommendation |
|---|---|---|
| OQ1 | Show structure only where it would really resolve at the stop's size (Aldebaran's cells, red dwarfs' spots; the Sun from home stays smooth), or exaggerate it everywhere? | **Honest gate.** It is what makes the giant feel giant; exaggeration would make every star look the same |
| OQ2 | Procedural in the shader, or a texture baked per star at arrival? | **Procedural**, unless the bench at the SS2 midpoint misses +0.5 ms; then a cube map baked at arrival, decided before the pause |
| OQ3 | Keep each star's total light fixed (spots never dim the star), or let spots change it by the real ≈ 0.1%? | **Fixed.** Every exposure, photometry and lighting number stays the sim's |
| OQ4 | Supergranulation (invisible in white light): leave out, or show the chromospheric network faintly as an artistic layer? | **Leave out** |
| OQ5 | Eclipse layers now (SS3), or with D-96's framing doc? | **Now**, so the framing doc can compose real shots |
| OQ6 | Red-dwarf flares (TRAPPIST-1 flares about every 2 days, Vida et al. 2017): in this sprint or later? | **Later**, with sound (a flare is an event, not a texture) |
| OQ7 | Should the Archive explain what the player is seeing (cells three Suns wide; spots; why the corona needs an eclipse)? | **Yes**, one canon entry, attended (SS4) |
| OQ8 | The diamond ring: allow the starfield's existing point-spread bloom on an occulted photospheric sliver only (D-59 stays for the forward view), or leave the sliver as a bare bead? | **Allow it for the sliver only**; it is the same PSF the stars already use, applied to a source that is momentarily point-like |
| OQ9 | Structure shows in the Auto view only; Realistic stays a clipped white disc, as an eye sees it (D-59). Is Auto-only right? | **Yes.** Auto is the labelled "filter" view Mark described ("we are dimming them anyway"); Realistic stays honest |

## Evidence

- **Baseline (today):** `tools/stops_capture.gd` on 5addab05, 720p: [Aldebaran](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/baseline_aldebaran_sky_auto_720p.png), [TRAPPIST-1](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/baseline_trappist1_sky_auto_720p.png).
- **Spike:** `spike/star_surfaces/star_surface_spike.gd` (throwaway). It flies the real sim to each stop by free navigation (as `stops_capture` does), switches each star disc's material to `star_surface_spike.gdshader` (today's disc shader plus a surface modulation, the resolution gate, a Baumbach corona and prominences), and shoots the sky in Auto with the surface off and on, and in Realistic with it on. The window was 2560×1288 (the display clamps 1440); px below are in that frame.

## Spike results

**[Contact sheet](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/contact_sheet.png)**: rows TRAPPIST-1, α Cen A, Aldebaran, the eclipses. Columns: Auto today, Auto with the surface, Realistic with the surface. I opened every frame on the sheet and the full frames below.

| Stop | Disc across | Cell size on screen | What the honest gate shows | Frames |
|---|---|---|---|---|
| Aldebaran | 1,006 px | 30 px | about 33 convection cells across, limb darkening, the whole disc alive | [Auto, full](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/aldebaran_auto_on.png) · [crop](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/aldebaran_auto_on_crop.png) · [today](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/aldebaran_auto_off_crop.png) · [Realistic](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/aldebaran_realistic_on_crop.png) |
| α Cen A | 183 px | 0.15 px (gated off) | limb darkening; one spot group at the edge of visibility; otherwise as today | [crop](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/acen_a_auto_on_crop.png) · [today](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/acen_a_auto_off_crop.png) |
| TRAPPIST-1 | 57 px | 0.01 px (gated off) | a starspot with a facular halo (the others are on the far hemisphere) | [crop](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/trappist1_auto_on_crop.png) · [today](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/trappist1_auto_off_crop.png) |
| The Sun from home | 8.9 px | 0.009 px | nothing (every layer gated to zero); it is also outside the forward frame at the Earth stop | — |

- **Realistic is unchanged**: every disc clips to white, as today ([Aldebaran](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/aldebaran_realistic_on_crop.png)). The structure is an Auto-view feature, which is what Mark described.
- **The honest gate is selective.** Only the giant is transformed; α Cen A barely changes. This is the decision OQ1 asks for.
- **The spike's cells read as a cracked glaze**, too regular and too fine-laned for convection. The statistics are right (count, size, contrast); the shape is for SS2 to tune within the cited statistics, with Mark at the SS2 pause.
- **The eclipse** ([total](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/eclipse_total_crop.png), [diamond ring](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/eclipse_diamond_ring_crop.png); full frames [total](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/eclipse_total.png), [ring](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/eclipse_diamond_ring.png)) is synthetic geometry with the game's shader: a 3.5° Sun-like star, an occulter 4% larger, exposure eye-adapted so the corona at 2 R sits at 0.3 pre-tonemap. The crown and streamers read; the prominences (seeded, 3e-5 of the disc) are lost in the bright inner corona and need their own check; the diamond ring is only a bead (OQ8). A first pass at the Sun's real size from 1 AU (8.9 px) and the star-friendly exposure gave a saturated white blob, then a 3-px sparkle: the finding recorded in §D6.
- **Frame time: inconclusive.** The window stayed locked to 120 Hz (8.33 ms) on Metal even with vsync set off, and Godot's per-viewport GPU timer returned 0 for both the root and the sky viewport. With the surface on, TRAPPIST-1, α Cen A and the Sun held 8.33 ms. Aldebaran's three runs were 15.95 (surface off), 12.13 (on) and 8.33 ms (off again): rig noise larger than any effect. SS2's `star-surface-bench` must use a GPU timestamp method that works here (the `make bench` route), and AC11 stands as written.
- **Numbers:** [spike.json](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/spike.json), [spike_eclipse.json](https://storage.googleapis.com/stapledons-voyage-assets/refs/star_surfaces/spike_eclipse.json).

## Deliverables

- `sunholo/celestial` 0.5.0 (`stellar`), published on Mark's go.
- Protocol 2.13 `surface`; sim data with citations.
- Renderer changes in `planets/planet.gdshader`, `planets/system_view.gd`, `physics/star_surface.gd` (CPU mirror).
- `make star-surface-test`, `star-surface-bench`, `star-surface-capture`; goldens G-SS-1..5.
- Design-repo PR: RS-24, RS-25, the §2 note, `features/next/star-surfaces.md`.
- `design_docs/implemented/r2/star-surfaces-report.md`, a changelog fragment, an Archive entry.
