# M5: Planets and flybys

**Status:** Planned (design, awaiting Mark's review; no sprint plan yet).
Created 2026-10-03 from ledger **D-26** (attended 2026-10-03, queue row 6c):
"a new R1 milestone M5 'Planets and flybys': AILANG-driven solar-system data,
Godot planet rendering with rings and relativistic flyby views, Sol's planets
plus the α Cen arrival scene; design doc first." Mark's prompt: "we have that in
the old original stapledon binary: renders of saturn and planet solar system
flybys etc."
**Release:** r1 · **Milestone:** M5 (new; the design repo's roadmap has no M5
row yet, see [§Design-repo changes](#design-repo-changes-m5-needs))
**Priority:** P1. It completes M4's arrival scene and the "3D objects nearby"
row of the relativity spec. It does not block M2, M3 or M4.
**Implements:**
- [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md)
  §2, row "3D objects nearby (planets, ships)": aberration of nearby geometry,
  the Terrell–Penrose question and the check "sphere stays circular in
  outline". §2 Doppler (D = 1/(γ(1 − β cos θ′)) at the apparent angle θ′),
  extended-source brightness (a blackbody at D·T, D⁴ bolometric) and the
  rendering requirements (HDR, float64 γ and 1−β). §4 tests: the CPU
  reference, GPU goldens within 0.75 px, and reference renders.
- Spec §5 audit rows 1–4. The Go flyby's screen-space SR warp had all four
  defects. None of its code is ported ([§Old build](#the-retired-go-build-what-to-keep-what-was-wrong)).
- [features/ailang-planet-ring-moon-data](https://github.com/sunholo-data/stapledons-design/blob/main/features/ailang-planet-ring-moon-data.md):
  the idea that ring and moon data live in AILANG. Its numbers are replaced:
  it has moons at 2.5–4 R♄ and "orbitSpeed (visual, not realistic)".
- [features/phase1-data-models/planet-data-migration](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/planet-data-migration.md):
  the target architecture only (the sim owns planet data; the renderer has
  none). Its circular orbits, `current_angle` and colour-by-type are replaced.
- [features/future/planetary-rings](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/planetary-rings.md):
  all four giants have rings, with the radii table (checked in M5.1). Ring
  shadows move from "stretch" to in scope; opacity becomes optical depth.
- [features/future/planet-rendering-polish](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/planet-rendering-polish.md):
  the atmosphere limb and distance LOD. Its physics basis ("Fresnel effect is
  real physics (Rayleigh scattering)") conflates two things and is replaced by
  a labelled single-scattering model. LOD becomes the photometric point/disc
  crossover.
- [legacy/go-engine-features/ailang-solar-system-demo](https://github.com/sunholo-data/stapledons-design/blob/main/legacy/go-engine-features/ailang-solar-system-demo.md)
  and [tetra3d-planet-rendering](https://github.com/sunholo-data/stapledons-design/blob/main/legacy/go-engine-features/tetra3d-planet-rendering.md):
  the demo's purpose (the sim drives a whole solar system) and nothing else.
  Its layout was in look-units (Sun radius 30, Earth at 80 units).
- [vision/design-decisions](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md)
  "players only see old light … all data labeled with 'last_light_year'"
  (line 178), and "parallax returns as destination system objects become
  resolvable" (line 618). These drive the α Cen honesty rules.
- [roadmap/r1-foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md)
  §M4 item 3 (arrival at a 1,000 AU stand-off; HB-91 to HB-94 in
  [higgs-bubble.md](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md)).
  `features/future/planet-state-transitions.md` (civilisation states) is **not**
  implemented here. It is R2 gameplay.

**Depends on:**
- **M1.5a photometric exposure** (landed, PR #80): scene units are lux and
  cd/m², EYE/CAMERA metering, pre-exposed shaders. Hard: planets use the same
  units and the same single tonemap.
- **M1.2d bright tier** (PR #69): α Cen A, B and Proxima astrometry. Hard for
  M5.4's arrival scene only.
- **M4.1 stand-off** (`sim/consequence.ail`): where the ship stops at α Cen.
  Soft: M5.4 can place the ship at the stand-off by scenario until M4.1 lands.
- **Queue row 6b, forward glare and auto-dimming glazing** (D-27). Soft: the
  solar disc (1.9 × 10⁹ cd/m²) needs the same glare path. Until 6b lands, the
  Sun renders as a clipped disc and the M5 report lists the gap.
- **`sunholo/relativity`**: the release after M4.6a's (whatever `[release] kind`
  assigns) carries M5.0's modules. The sim pin, the lockfile and the bundled
  cache move together.

**Estimated:** ~2,450 LOC (≈1,450 code + 1,000 tests and tools) in 6
sub-milestones. The queue row's ~2,000 was set before the package work
(orbits, reflected-light photometry, the apparent-disc function) was scoped.
**Evidence:** codebase claims are in the [Verification log](#verification-log),
pinned to game `7ac4778` (origin/main), design repo `1ef3bc9`, retired Go build
`930eca1` and `sunholo/relativity` 0.5.2 (the version `sim/ailang.toml` pins).
**Numbers in this doc are oracle estimates.** A throwaway Python script in the
scratchpad (an oracle, never committed) produced them. None is a check value
until the package function exists. M5.0 replaces each one with the package's
output, and the acceptance criteria assert package values.

## Game vision alignment

Scored with the `game-vision-designer` skill against
`stapledons-design/vision/core-pillars.md` and the design-decision log.
Verdict: **ALIGNED**.

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | 0 | 0 | M5 adds no choice. The flyby is a demo scene, like M3's Sgr A* |
| The Game Doesn't Judge | 0 | 0 | |
| Time Has Emotional Weight | + | +1 | Old light made visible: Jupiter from Earth is drawn where it was 35 minutes ago (light-time is real, not hidden). At α Cen every world carries its data source and how old the light was (design decision, line 178). Before departure Earth fills the dome; at α Cen the Sun is a magnitude +0.5 star |
| The Ship Is Home | + | +1 | Planets are seen through the same dome and exposure as everything else, from the bridge at Sol and on arrival. Home is a place you can see |
| Grounded Strangeness | ++ | +2 | Saturn at 0.9c: the disc stays a circle but shrinks, slides forward and turns violet at its leading edge; you see round to the side that faced away. Next to a sunlit planet the eye's stars go out. Strange, and exactly right |
| We Are Not Built For This | 0 | 0 | Hinted at only: the eye cannot hold a lit planet and the stars at once (23 stops apart) |
| Hard sci-fi authenticity (spec) | ++ | +2 | Real ephemerides with a stated validity window, photometry tied to geometric albedo, ring optical depth, Terrell rotation from exact per-pixel aberration. Speculative exoplanets are marked as such, and nothing is invented to fill a gap |
| **Net** | | **+6** | **Go.** One point needs Mark's discussion: how α Cen's uncertain worlds are shown (open question 3) |

## Problem

1. **No planet exists in the rebuild.** M1 lists "planets and nearby 3D
   objects, including Terrell rotation (M4 or later)" as a non-goal
   (`m1-relativistic-sky.md:101`), and M4 lists "planets; Terrell rotation"
   as non-goals (`m4-first-journey.md:122`). The sim has no body except stars
   (V1).
2. **M4's arrival is a pair of points with no system.** M4.3 says only "α Cen
   A and B are overhead or beside the dome" (V2). Proxima, the only confirmed
   planet host in the system, is not mentioned. Nothing tells the player which
   worlds are known and which are guesses.
3. **The package has no orbit or reflected-light maths** (V3). Its 0.5.2
   modules are `optics`, `photometry`, `blackbody_photometry`,
   `schwarzschild`, `kinematics`, `journey`, `medium` and `hyper`. Gate 3
   says that maths goes there first.
4. **The relativity spec's method for nearby objects is under-specified.**
   "Aberrate every vertex" is exact only at the vertices: a straight triangle
   edge between two aberrated vertices is not the aberrated edge, and the spec
   has no check value for an apparent disc. Its one check ("sphere stays
   circular in outline") has no ID (V4).
5. **Planets break the exposure range.** Sunlit Saturn's globe is about
   330 cd/m² (oracle); the deep-space dark sky is 4.3 × 10⁻⁵ cd/m²
   (D-25), 23 stops apart. M1.5a's log-average meter is dominated by the dark
   sky, so a bright planet would clip. The solar disc (1.9 × 10⁹ cd/m²) is above
   half-float range (65,504) unless it is pre-exposed (V5).
6. **The Go build's planets are a reference for the look, not the physics**
   ([§Old build](#the-retired-go-build-what-to-keep-what-was-wrong)): wrong SR
   shader, look-unit scales, moons inside planets, rings tilted without their
   planet.

## Goals and non-goals

- **G1. Sol's system from the sim.** The Sun, 8 planets, 11 moons and 4 ring
  systems. Positions come from published mean orbital elements, and pole and
  spin from the IAU rotation model. All of it is pure, deterministic AILANG,
  in the galactic frame the starfield uses.
- **G2. Physically lit planets in physical units.** Reflected sunlight in
  cd/m², from geometric albedo and a stated phase law, through M1.5a's single
  exposure and tonemap. Sub-pixel bodies are point sources through the
  starfield path, with flux continuous across the crossover.
- **G3. Rings that behave like rings.** A normal optical-depth profile with
  slant-path transmission, lit and unlit faces, the planet's shadow on the
  rings and the rings' shadow on the planet.
- **G4. Relativistic flybys done exactly.** The rest-frame image at the
  observer's event is warped per pixel by inverse aberration and Doppler
  shifted at the apparent angle. Terrell–Penrose rotation follows from that;
  it is not added on. Light-travel time is applied.
- **G5. The α Cen arrival scene.** A and B on their real binary orbit,
  Proxima, and the system's planets with their status (confirmed or
  candidate). Nothing speculative appears as fact.
- **G6. Gate 2 in full** for every SR visual: check values from the package
  in `tests/test_physics.gd`, GPU goldens, and reference renders Mark has looked at.

**Non-goals (R1):**
- In-system travel as gameplay (an orbit or hop between planets inside a
  system). The flyby is a scenario like M3's Sgr A* demo: the ship is placed
  on a line without a journey (open question 1).
- Moving relativistic geometry (another ship passing at 0.9c). Every M5 body
  is at rest in its system frame to 10⁻⁴ c. The Terrell work here is
  observer-motion only.
- N-body integration, perturbation theory, precession beyond the published
  secular rates, the Sun's barycentric wobble (about 1 R☉).
- GR on planets. Light deflection at the solar limb is 1.75″, under 0.02 px at
  a 60° field of view on 2560×1440 (one pixel is about 84″). It is stated and
  not drawn.
- Planet surface states, civilisations, landing, and Earth's night-side city
  lights (a future Earth's lights are a canon question, not data).
- Multiple-scattering atmospheres, cloud animation, ring particle dynamics.
- Exoplanet systems other than α Cen.

## Design

ADR 0001 holds: **the sim owns state and rules; Godot owns presentation.**
Godot computes no orbit, flux or γ.

### M5.0 Package first: `sunholo/relativity` gains `orbits` and `reflect`

Gate 3 says that physics maths lives in `sunholo/relativity`. Orbital
mechanics and reflected-light photometry are not relativity, so a separate
package (`sunholo/celestial`) is also possible. This is open question 5.
**Default:** two new modules in `sunholo/relativity`, so there is one package,
one pin and one quality gate. New functions, all pure float64:

| Module | Function | Formula / source | Check (oracle estimate until M5.0) |
|---|---|---|---|
| `orbits` | `solveKepler(M, e)` | Newton on E − e sin E = M, a fixed 8 iterations from E₀ = M + e sin M (deterministic iteration count; strict-VM safe) | Residual < 1e-14 for e ≤ 0.97; e = 0 gives E = M exactly |
| `orbits` | `elementsAt(el, rates, jdTT)` | JPL "Keplerian Elements for Approximate Positions of the Major Planets" (Standish), Table 2a (3000 BC–3000 AD) with the b, c, s, f terms for Jupiter–Neptune | Jupiter opposition 2023-11-03 (elongation 180° within ±2 d); Mars opposition 2020-10-13 (±2 d) |
| `orbits` | `stateFromElements(el)` | Perifocal → ecliptic J2000 position (AU) and velocity (AU/d) | Circular e = 0 orbit radius = a exactly; vis-viva holds to 1e-12 |
| `orbits` | `eclipticToGalactic(v)` | Constant rotation: ecliptic J2000 → ICRS (obliquity 84381.406″) → galactic (Hipparcos 1997 matrix, the one the starfield frame uses) | The north ecliptic pole maps to galactic (l, b) = (96.38°, 29.81°) within 1e-4° |
| `orbits` | `poleAndSpin(body, jdTDB)` | IAU WGCCRE 2015 (Archinal et al. 2018): α₀, δ₀, W | Saturn's Sun ring-plane crossings (equinoxes) 2009-08-11 and 2025-05-06, within ±10 d (pole + JPL elements together) |
| `orbits` | `retardedTime(src, obs, t)` | Fixed-point t_r = t − ‖x_obs(t) − x_src(t_r)‖/c, 4 iterations (contraction v/c ≤ 2e-4) | Jupiter at opposition from Earth: lag 2,094 s, and the planet is drawn 27,400 km (0.38 R♃) behind its instantaneous position |
| `reflect` | `starIlluminanceAt(vStar1AU, rAU)` | E = `illuminanceFromV`(V at 1 AU) / r²; the Sun's V = −26.74 | E☉(1 AU) = 1.261 × 10⁵ lux (uses 0.5.2's existing `illuminanceFromV`) |
| `reflect` | `lambertPhase(α)`, `lambertRadiance(rho, E, cosI)` | Φ(α) = (sin α + (π − α) cos α)/π; L = ρ E cos i / π | Φ(0) = 1, Φ(π/2) = 1/π, Φ(π) = 0 |
| `reflect` | `minnaertRadiance(rho, k, E, cosI, cosE)` | L = ρ E cosᵏi cosᵏ⁻¹e / π (giants' limb darkening); k = 1 is Lambert | k = 1 equals `lambertRadiance` to 1e-15 |
| `reflect` | `rhoFromGeometricAlbedo(p, k)` | ρ such that the disc-integrated opposition flux of the Minnaert sphere equals p (Lambert: ρ = 3p/2) | Round trip to 1e-12 |
| `reflect` | `discIlluminance(p, R, rAU, d, α, k)` | The body's illuminance at the observer: E☉ p (R/d)² Φ(α) / r² | Jupiter at opposition (r 5.20, Δ 4.20 AU, p_V 0.538): V −2.77 (observed about −2.7 to −2.9) |
| `reflect` | `ringLitRadiance(w0, P, tau, mu0, mu, E)`, `ringUnlitRadiance(...)` | Classical single scattering in a thin layer (Chandrasekhar; as used for Saturn's rings, Cuzzi et al.): lit face I/F = w0 P μ0/(4(μ + μ0)) [1 − e^(−τ(1/μ + 1/μ0))]; unlit face (μ ≠ μ0) w0 P μ0/(4(μ − μ0)) [e^(−τ/μ) − e^(−τ/μ0)] | τ → ∞ lit face equals the Lommel–Seeliger law; τ → 0 both tend to 0; the unlit-face limit at μ → μ0 is finite |
| `optics` | `apparentDisc(cosTheta, alpha, phi)` | A sphere of angular radius α centred at rest angle θ. Aberration is conformal on the sky, so the image is a circle; its edge points are the aberrated θ ± α along the meridian. Returns the apparent centre (not the aberrated centre) and the apparent radius | β 0.9, θ 90°, α 5°: centre 25.928°, radius 2.184° (the aberrated centre is 25.842°). β 0.99: 8.140°, 0.707°. β 0.9, θ 150°: 82.021°, 9.940° (magnified astern) |
| `optics` | (existing) `dopplerApparent`, `deaberrate`, `gammaOf`, `oneMinusBeta` | Reused unchanged | D at the disc centre: 2.2871 (β 0.9, θ 90°), 7.0623 (β 0.99), 0.4981 (β 0.9, θ 150°) |

Each row ships with tests, a CHANGELOG entry, `[release] kind`, and
`ailang pkg quality` with no gates. The package is then published, and the
sim pins the new version. GDScript (`physics/planets.gd`) and the shaders
mirror these functions and are never the only copy. **Precision:** all inputs
are float64 scalars. The near-c branch uses `oneMinusBeta(phi)`, never
`1 - beta`.

### M5.1 Sim: `sim/celestial.ail` (pure) and the `system` change set

**The data is AILANG source, with a citation on every row.** It is small, so
there is no file I/O in the core:
- `sim/data/sol.ail`: Standish Table 2a elements and rates for the 8 planets;
  IAU 2015 poles, W₀ and Ẇ; equatorial radius and flattening; V-band geometric
  albedo p_V (Mallama et al. 2017) and Minnaert k (Jupiter, Saturn, Uranus,
  Neptune; Lambert elsewhere).
  - **Moons (11)**, from JPL SSD planetary-satellite mean elements (a, e, i to
    the Laplace plane, node and periapsis rates): the Moon; Io, Europa,
    Ganymede, Callisto; Mimas, Enceladus, Tethys, Dione, Rhea, Titan; Triton.
    Iapetus and the Uranian moons are an easy follow-up if Mark wants them
    (one data row each).
  - **Rings**: a radial profile per giant, `[(r_inner_km, r_outer_km, tau,
    w0)]` in the planet's equatorial plane. Saturn: D, C, B (inner and core),
    Cassini Division, A (with the Encke gap), F. Uranus: 6, 5, 4, α, β, η, γ,
    δ, ε. Neptune: Galle, Le Verrier, Lassell, Arago, Adams (arcs as an
    azimuthal factor). Jupiter: halo, main, gossamer. τ comes from published
    occultation profiles (Saturn: Cassini UVIS/RSS, Colwell et al. 2009; Uranus:
    French et al. 1991; Neptune and Jupiter: Voyager/Galileo summaries),
    averaged per region. Colour is a rest-frame sRGB tint from imagery,
    labelled as a tint and not a spectrum.
- `sim/data/acen.ail` (see [M5.4](#m54-scenes-the-α-cen-arrival-sol-docked-and-the-flyby-demo)).

**The time base.** `system.jd` = scenario epoch (a JD; D-12 makes the epoch a
scenario parameter) + Earth time t (M2's galaxy clock, years × 365.25 d).
**Validity window:** Table 2a holds for 3000 BC–3000 AD. Outside it,
`elementsAt` freezes the secular rates at the window edge; the bodies keep
moving on their Kepler orbits, so phases still advance. The sim marks
`ephemeris: "mean-orbit"` (as opposed to `"jpl-approx"`), and the codex says
so. The game can run for a million years, and no ephemeris predicts that far.
Saying so is the honest option.

**Pure functions** (`sim/celestial.ail`, no I/O, `--strict-bytecode` clean):
- `systemAt(sys, t, ship)` returns `[BodyView]` for every body:
  - `id`, `name`, `kind` (star, planet, moon or ring host), `status` (see
    [M5.4](#m54-scenes-the-α-cen-arrival-sol-docked-and-the-flyby-demo));
  - `rel_km` (float64[3]): the body at its retarded time minus the ship, in
    the galactic frame;
  - `radius_km`, `flattening`, the pole (unit vector) and `w_deg` at the
    retarded time;
  - `sun_dir` (unit, body → star at the body's retarded time), `r_au`,
    `phase_deg`;
  - `e_v_lux` (`discIlluminance`), `p_v`, `minnaert_k`, `ring_id`;
  - `light_age_s` (t − t_r, shown in the codex and the inspect panel);
  - `source` (a citation key).
- **Frames and precision:** positions are host-star-relative in AU (float64)
  from `stateFromElements`, rotated by `eclipticToGalactic`, then offset by
  the host star's catalogue position (ly) and differenced against `ship.pos`.
  At Sol the origin is the Sun, so precision is about 10⁻⁸ km. At α Cen
  (4.3 ly) a float64 difference keeps about 9 m. Both are far below a pixel.
- **The moving observer needs nothing extra.** The rest-frame image at the
  ship's event (x, t) is fixed by the retarded positions. The ship's velocity
  enters only in the renderer's aberration and Doppler. The doc states this so
  nobody adds a second retardation for the observer.
- **Protocol:** an additive `system{jd, ephemeris, frame: "galactic", bodies:
  [...]}` change set, a minor bump on M2's protocol v2. Bodies whose
  `e_v_lux` is below 10⁻⁴ of the naked-eye threshold, and which subtend less
  than 0.1 px, are culled in Godot, not in the sim (the sim stays
  presentation-free). About 30 bodies per tick is trivially small.
- **The flyby scenario:** `new_game{scenario: "flyby", flyby{body, b_km,
  dir, beta, t_closest_s}}`. The ship starts on M2's coast at constant φ, on
  the straight line through the closest-approach point. **Gravity is
  neglected, and that is quantified:** the deflection 2GM/(b v²) past Saturn at
  b = 10⁵ km is 8 × 10⁻⁵ rad at 0.01c (an 8 km offset) and 3 × 10⁻⁸ rad at 0.5c.
  The scenario therefore requires β ≥ 0.01; a β = 0 "tour" camera exists only
  as a diagnostic free camera. No new kinematics: this is M2's `coast`.
- **Docked at Sol:** `scenario.dock{body: "earth", alt_km}`. The ship holds a
  fixed offset from the body in the galactic frame, so M4's docked bridge sees
  Earth and the Moon. The default altitude is open question 2.

### M5.2 Godot: physically lit planets and rings (rest frame)

Everything renders into **M4's sky SubViewport** (layers 1–2, HDR float) and
is **pre-exposed** the way the starfield already is (`sky/starfield.gdshader`
multiplies by `exposure` = 1/L_white). So there is one tonemap (G-M4-2 holds)
and the solar disc does not overflow half-float. Node: `planets/system_view.gd`,
fed only by `state.system`.

- **Placement (precision gate 5).** Each resolved body group is drawn in a
  local frame. Godot computes the direction `rel_km / |rel_km|` and the
  angular radius asin(R/d) in float64 scalars, then scales the group by
  k = 1/d, so the body sits at about 1 unit with angles preserved exactly.
  float32 `Vector3` never holds a raw km position.
- **Point or disc.** If the angular diameter is < 2 px, the body is a point
  source handed to the starfield instancer with `e_v_lux` and T = 5,772 K (the
  solar colour). The existing band-ratio Doppler then applies unchanged. At
  ≥ 2 px it is a disc. The crossover golden G-M5-6 requires the integrated
  flux to agree within 2 %. That replaces the old "LOD by distance in units".
- **Surface.** Albedo textures from **Solar System Scope (CC BY 4.0)**, at
  2k for R1 (8k is optional, open question 6). They are fetched by sha256 like
  the sky (`make planet-assets`, D-18 pattern; pins in
  `data/planets/SHA256SUMS`) and credited in-game. Each texture is normalised
  so its disc-integrated albedo equals the data's p_V, so the texture sets
  pattern and colour and the data sets brightness. Moons without a free
  texture are uniform albedo spheres (USGS public-domain mosaics are a
  follow-up). The radiance is `minnaertRadiance` (the shader mirrors the
  package), so giants get limb darkening and rocky bodies are Lambert. The
  pole and W come from the sim, and **the whole system (globe, rings, moons)
  shares the pole**, unlike the old build.
- **The Sun.** It lights every body as a point source with
  E = `starIlluminanceAt`. When resolved it draws as a disc (linear limb
  darkening, u = 0.6, flux-normalised) at 1.9 × 10⁹ cd/m². Its luminance goes to
  the glare pass (row 6b) as a uniform, not read back from the clamped buffer.
- **Rings** (`planets/ring.gdshader`): an annulus in the equatorial plane.
  Per pixel it looks up τ(r), takes the lit or unlit face from the sign of the
  sun and view elevations, uses `ringLitRadiance`/`ringUnlitRadiance`, and
  sets alpha = 1 − e^(−τ/|μ|). The ring shadow on the globe and the globe's
  shadow on the rings are analytic: ray–plane and ray–sphere intersections
  toward the Sun, with transmission e^(−τ/μ0) and a penumbra from the Sun's
  angular radius. Moon shadows on their planet (up to 4 sphere occluders) use
  the same code.
- **Atmospheres, honest about approximation.** Earth, Venus and Titan get one
  outer shell with **single-scattering Rayleigh + Mie, exponential density
  (scale heights 8 km and 1.2 km for Earth), and no multiple scattering**. The
  result is a limb that is slightly too dark and too saturated. The code and
  the codex say so. Gas giants get no shell; their texture and Minnaert law
  carry the limb. The Go docs' "Fresnel glow" is not used: Fresnel reflection
  is not what makes Earth's limb blue.
- **CPU mirror:** `physics/planets.gd`, used by the tests and the goldens.

### M5.3 The relativistic flyby: exact per-pixel aberration of the rest-frame image

**What is real.** All M5 bodies are at rest in their system frame (orbital
speeds ≤ 50 km/s, about 2 × 10⁻⁴ c). The ship moves at β. The photons that
reach the ship's event (x, t) are fixed by the retarded positions alone. The
moving observer sees **those same photons**, with directions aberrated and
frequencies multiplied by D. So the exact image is:

1. **Rest-frame tile.** For each resolved body group, render it in the system
   frame from the ship's position at the retarded geometry (M5.1). The camera
   is aimed at the group, with a field of view just covering its apparent disc
   and rings. Tile resolution is scaled by 1/D at the group's centre, capped
   at 4,096², because aberration magnifies linear angles by 1/D: up to
   γ(1 + β) = 14 astern at 0.99c, and compressed ahead.
2. **Warp pass** (in the sky SubViewport, before the one tonemap). For each
   screen pixel with apparent direction n′, compute n = `deaberrate`(n′) and
   sample the tile that contains n. Radiance is Doppler-shifted at the
   apparent angle, with **D = 1/(γ(1 − β cos θ′))**, using γ and 1 − β from
   the sim as float64 uniforms. In the shader, the 1 − β cos θ′ form is
   rewritten as (1 − β) + β(1 − cos θ′) for precision.
3. **Spectrum.** Reflected sunlight is a diluted 5,772 K blackbody. Since
   I_ν/ν³ is invariant, a diluted blackbody at T is seen as the same dilution
   of a blackbody at D·T (spec §2). The warp reuses M1's `bb_lut` to give the
   luminance ratio and chromaticity at D·T, times the texel's rest-frame
   albedo.

**What follows from it, not added to it.** The Terrell–Penrose rotation is
this aberration of the rest-frame view. A sphere's outline stays a circle,
because aberration is a conformal map of the sky. The visible hemisphere is
the one facing the ship's rest-frame position, so on a fast pass you see round
to the side that faced away from you earlier, and a Lorentz-squashed planet
never appears. The apparent disc's centre is **not** the aberrated centre
(25.928° vs 25.842° at β 0.9, θ 90°). The goldens pin both.

**What is approximated, stated.**
- Tile sampling. The tile is at least 1 texel per 0.5 screen px after the
  warp, and the goldens measure the residual.
- **Spectral albedo outside the visible.** Only an sRGB tint is known, so it
  is applied to the shifted illuminant. Real reflectance at λ/D (UV at
  0.99c ahead) is unknown, so the bands are extrapolated as grey. Colour under
  strong Doppler is therefore "true illuminant, assumed grey surface". The
  codex says this.
- The bodies' own Doppler from orbital motion (D − 1 ≈ 2 × 10⁻⁴) is ignored.
- Bodies in separate tiles are composited far to near by distance. Moons in
  front of their planet share its tile, so moon–planet occlusion is exact.

**Why not per-vertex aberration** (the spec's current wording)? Per-vertex
aberration is exact only at vertices: edges and the limb between them are
wrong unless the mesh is tessellated far below a pixel, and depth ordering
breaks near the pole. Per-pixel inverse aberration is exact everywhere and is
already the method of M1's background shader. M5 asks the design repo to
amend the spec row ([§Design-repo changes](#design-repo-changes-m5-needs)).

### M5.4 Scenes: the α Cen arrival, Sol docked, and the flyby demo

**The α Cen system: what is known** (pinned in `sim/data/acen.ail` with
citations; the sprint re-verifies against the NASA Exoplanet Archive snapshot
fetched by `starmap-manager`, pinned by sha256 in `data/raw/`):

| Body | Status | Data (to be re-verified at sprint) | Shown as |
|---|---|---|---|
| α Cen A, B | stars | Binary orbit P ≈ 79.9 yr, a ≈ 17.5″ (≈ 23.4 AU), e ≈ 0.52, i ≈ 79°, Ω, ω and T from Akeson et al. 2021 / Pourbaix & Boffin 2016; masses about 1.08 and 0.91 M☉. Periastron 11.2 AU, apastron 35.6 AU (HB-92, HB-93) | Two points (≈ 1.2″ discs at 1,000 AU, far below a pixel), with the separation from the orbit at the arrival epoch |
| Proxima Cen | star | Catalogue position (M1.2d). It is about 13,000 AU from AB, so from the stand-off it is a V ≈ 4.4 red point (oracle) | Point, from the starfield |
| Proxima b | **confirmed** | P 11.19 d, a 0.0485 AU, m sin i ≈ 1.07 M⊕ (Anglada-Escudé 2016, Faria 2022). Radius unknown (non-transiting) | Point; radius **inferred** (mass–radius relation, labelled); inclination **assumed**, labelled |
| Proxima d | candidate, or confirmed if the sprint's snapshot lists it | P 5.12 d, m sin i ≈ 0.26 M⊕ (Faria 2022) | As the archive says on the snapshot date, never upgraded by us |
| Proxima c | **candidate (disputed)** | P ≈ 5.2 yr (Damasso 2020) | Badge "candidate" |
| α Cen A b | **candidate** | JWST/MIRI direct-imaging candidate (2025): Saturn-mass, about 1–2 AU, orbit poorly constrained | Badge "candidate", with the orbit drawn from one published solution and labelled "one of several fits" |
| α Cen B b | **retracted** (2012 claim, refuted 2015–16) | none | **Not shown** as a body; the codex mentions the retraction |

**Honesty rules (all enforced by data, not by copy):**
- Every body row has `status ∈ {star, confirmed, candidate}` (retracted rows
  are not loaded) and per-field provenance: `measured`, `inferred` (with the
  relation named) or `assumed` (with the value stated). A test fails if any
  α Cen body lacks them.
- **No resolved disc is ever drawn for a body with an inferred radius or an
  assumed albedo** unless it carries an on-screen "modelled" tag. At the
  1,000 AU stand-off this never arises: every planet is a sub-pixel point.
- **What the eye actually sees at the stand-off.** α Cen A is V −12.2
  (HB-91). A and B are about 1.35° apart (HB-94; the exact value comes from the
  orbit at the arrival epoch). The candidate A b would be about V +8 at 0.11°
  from A (oracle). That is below the eye's V 6.9 limit (M1.5a AC8), so it is
  invisible in EYE mode, honestly. In CAMERA mode with a fixed long exposure
  it can appear as a point. Proxima b is about 0.8″ from Proxima at about
  V +22, and is not visible.
- **Navigation inset** (a labelled readability aid, the pattern of
  design-decision line 599 and M1.5a): a schematic orrery card on the arrival
  card. It shows each body's orbit, status badge, provenance and
  `last_light` age ("data from Earth-based observation, light 4.3 yr old at
  departure"). The card is labelled "schematic, not to scale" and never draws
  into the sky.
- **Codex entry** "The worlds of α Centauri": what is confirmed, what is a
  candidate, what was retracted and why. It cites check values (new PL-n rows)
  through M4.7's lore-check.

**Sol docked (M4's bridge before departure).** With `scenario.dock`, Earth and
the Moon appear in the sky SubViewport through the dome. Sunlit Earth (about
2.6 × 10⁴ cd/m² at normal incidence, oracle) light-adapts the EYE meter, and the stars
go out. That is what astronauts report, and the old Saturn screenshot got it
wrong (stars shown around a lit planet).

**The flyby demo** (`scenes/flyby.tscn`, like M3's Sgr A* demo). The scenario
runs past Saturn, Jupiter or Earth at β ∈ {0.01, 0.1, 0.5, 0.9, 0.99}, with a
free look. At 0.5c Saturn's ring system (about 274,000 km across) passes in
1.8 s, so time warp below 1× (a recorded `dtau`, as M4) lets the player watch
it. HUD: β, γ, D at the target centre, light age, apparent vs rest angular
size.

### Exposure interplay (M1.5a and the meter)

- **Units.** Discs are luminance in cd/m² and points are illuminance in lux:
  the same units as the sky and the stars, and the same pre-exposure.
- **The meter must see planets.** M1.5a's log-average meter is dominated by
  the dark sky: with Saturn filling a quarter of the frame it meters about
  2 × 10⁻³ cd/m², and Saturn would sit 14 stops over white. **M5 adds a
  highlight-protecting term to EYE and CAMERA metering**:
  EV_meter = max(log-average EV, EV(P99.5 luminance / headroom)), with
  headroom = AgX's white point. This is the standard histogram-percentile
  auto-exposure. It changes `sky/exposure.gd`, the file M1.5a owns, so it is
  a cross-milestone change and open question 4. EYE stays
  EV = max(EV_dark, EV_meter), as M1.5a defined it.
- **The consequence is physics.** A lit planet and the naked-eye stars are
  23 stops apart, and the eye spans about 14. Next to Saturn the stars vanish
  in EYE mode. **Fixed EV** (F) shows Saturn blown out and the stars back. The
  labelled aids (exposure bias, magnitude floor) behave as in M1.5a and are
  off by default.
- **The Sun** is clipped by the tonemap until row 6b's glare and auto-dimming
  glazing land; it is then handled the same way as the forward CMB disc (D-27).

### M5.5 Physics gates (gate 2) and renders

- **CPU (`tests/test_physics.gd`, `make physics`):** every M5.0 check value
  above, copied from the package probe (not computed in GDScript):
  `apparentDisc` at the three geometries; D at the disc centre; the Lambert
  and Minnaert phase values; the ring single-scattering limits; Jupiter's
  opposition V; Saturn's equinox dates; the retarded lag; the point/disc flux
  ratio at the crossover; finite values for every body at every scenario
  stop, with no NaN at r → 0 (the ship is never inside a body: the sim refuses
  a flyby with b ≤ R + the outer ring radius + the bubble radius).
- **`make lint-precision`** (M4's lint) also covers `planets/`.
- **GPU goldens (`make golden`), within 0.75 px or as stated:**
  - **G-M5-1, apparent disc.** A uniform sphere at β ∈ {0, 0.5, 0.9, 0.99} ×
    θ ∈ {30°, 90°, 150°}: the fitted limb circle's centre and radius (in angle
    space) match `apparentDisc` within 0.75 px.
  - **G-M5-2, the outline stays circular (Terrell).** At β 0.9, θ 90°, the
    RMS of the limb points' angular distance from the fitted centre is
    < 0.5 px.
  - **G-M5-3, Doppler across the disc.** Linear radiance at the leading edge,
    centre and trailing edge matches the CPU blackbody at D(θ′)·5,772 K within
    1 %, in a debug linear float target before exposure.
  - **G-M5-4, photometry at rest.** Jupiter at opposition: the disc's
    integrated illuminance matches `discIlluminance` within 2 %.
  - **G-M5-5, ring shadow geometry.** Saturn at a fixed epoch: the globe's
    shadow edge on the B ring and the ring shadow on the globe are within
    0.75 px of the analytic CPU position; transmission through the shadow
    equals e^(−τ/μ0) within 2 %.
  - **G-M5-6, point/disc crossover.** Integrated flux at 1.9 and 2.1 px
    diameter agrees within 2 %.
  - **G-M5-7, one tonemap and metering.** A sky-only pixel next to a planet
    equals the SubViewport's within 1/255 (G-M4-2 holds); with Saturn
    covering 25 % of the frame, its centre is below the AgX white point.
- **Reference renders (`make capture-m5` → `renders/m5/`):** a Saturn flyby at
  β 0, 0.5, 0.9 and 0.99, looking forward, sideways and astern; a Saturn
  ring-shadow close-up; Jupiter with a Galilean moon's shadow; Earth docked
  (EYE and fixed EV); the α Cen arrival in EYE and CAMERA mode with the
  inset; and a contact sheet. ⏸ **S-M5: Mark looks at them** before M5.3 and
  M5.4 merge. This is the gate-2 "renders you have actually opened".
- **Bench:** `make bench SCENE=flyby`, p99 < 16.7 ms at 2560×1440 on the M4 Max,
  medium star tier, Saturn plus 6 moons in view at β 0.9.

## The retired Go build: what to keep, what was wrong

Surveyed read-only at `930eca1` (V6). **Reference screenshots for Mark**
(they exist; none are copied into this repo):
- `/Users/voightkampff/dev/stapledons_voyage/docs/images/ailang-saturn.png`
  (2214×1696): the Saturn ring demo. Correct C/B/A radii and Cassini gap. But
  the rings are tilted while the globe is level, there is no ring shadow, the
  rings are see-through over the globe, the polar hexagon is at the bottom
  (texture flipped), and stars show around a sunlit planet.
- `/Users/voightkampff/dev/stapledons_voyage/docs/images/solar-flyby.gif`:
  the "flyby". Its frames are washed blue by the fake SR tint and the clamped
  D³ beaming. It is useful as a picture of what M5 must not do.
- `out/screenshots/` holds only `.gitkeep`. No other planet captures exist.

| Keep (the look or the idea) | Wrong (do not port) |
|---|---|
| Saturn's ring-band radii (C 1.24–1.53, B 1.53–1.95, Cassini 1.95–2.03, A 2.03–2.27 R♄; `engine/tetra/ring.go:311-342`), which match the real values | `sr_warp.kage`: aberration runs the wrong way (the forward transform is used as the inverse), Doppler is evaluated at the wrong angle (at θ′ = 90° it gives γ(1+β²) instead of 1/γ), the colour is a fake RGB tint, beaming is D³ clamped to [0.08, 6], the rear view is clamped flat (spec §5 rows 1–4) |
| The textured globe + band + moons + starfield composition, and the camera orbit | Only the ring is tilted (`ring.go:163`); moons orbit in the untilted plane |
| Solar System Scope 2k textures, CC BY 4.0 (`assets/planets/`; licence in the asset-manager script) | `solar_demo.ail`: look-unit layout (Sun radius 20–30, Earth at 80 units); moons inside their planets (Jupiter radius 15, Io at 4); orbits advanced per frame, not per time; a fictional Earth moon "Gemini" |
| Rings for all four giants, plus Haumea, Quaoar and Chariklo | `celestial.ail`: circular coplanar orbits from made-up start angles; `demo-game-saturn` moons at 2.5–4 R♄ (Titan is really at 20.3 R♄) |
| | Point light with "energy 8000" to beat falloff, plus 0.6 ambient: a brightness hack with no units |
| | `earth.jpg` 5400×2700 and the `alien/*.png` set have no stated source or licence; not used |

## Acceptance criteria

Every row is checked by the command named. "Package value" means the
function's output at the pinned release, copied into the test from the probe.

| # | Criterion | Command |
|---|---|---|
| AC1 | `orbits` and `reflect` modules and `optics.apparentDisc` are published with tests for every M5.0 row (Kepler residual, opposition dates, equinox dates, ecliptic pole, Lambert/Minnaert limits, ring single-scattering limits, `apparentDisc` at the three geometries, Jupiter opposition V); `ailang pkg quality` reports no gates; CHANGELOG and `[release] kind` present | `ailang test` and `ailang pkg quality` in `packages/relativity` (ailang-packages) |
| AC2 | The sim pins that release; `sim/ailang.toml`, `sim/ailang.lock` and the bundled runtime cache agree | `make deps test` |
| AC3 | `systemAt` is pure: `sim/celestial.ail` passes `--strict-bytecode`; a 1,000-tick Saturn flyby gives byte-identical `system` output on the VM and the interpreter (per-architecture goldens until ailang#1465) | `make strict parity-v2` (new `flybyRoundTrip` entry) |
| AC4 | Sim positions equal `stateFromElements` ∘ `eclipticToGalactic` to 1e-12 AU; the retarded lag for Jupiter from Earth at opposition equals the package value within 1e-6 s; outside 3000 BC–3000 AD the sim reports `ephemeris: "mean-orbit"` | `make sim` |
| AC5 | Data provenance: every body row has a citation key; every α Cen body has `status` and per-field provenance; no `retracted` row is loaded; ring radii match the design repo's ring table within 1 % of R (Saturn 1.11–2.27, Jupiter 1.29–1.81, Uranus 1.49–1.95, Neptune 1.69–2.54) | `make sim` (`celestial_test.ail`) |
| AC6 | The flyby scenario refuses b ≤ R + outer ring radius + bubble radius, and refuses β < 0.01 | `make sim` |
| AC7 | CPU mirror: `physics/planets.gd` matches every package value in AC1 within 1e-12 relative (1e-9 for angle outputs in degrees); no hand-computed γ or 1 − β | `make physics lint-precision` |
| AC8 | GPU goldens G-M5-1 to G-M5-7 pass | `make golden` |
| AC9 | Reference renders exist under `renders/m5/` with a contact sheet; Mark's S-M5 approval is recorded in the sprint JSON before M5.3/M5.4 merge | `make capture-m5` and `jq '.milestones[] \| select(.id=="M5.5").review' .ailang/state/sprints/sprint_R1-M5-PLANETS.json` |
| AC10 | Planet textures are fetched by sha256 and none is tracked in git; CC BY 4.0 attribution present in the credits file | `make planet-assets && git ls-files assets/planets \| grep -v -E 'SHA256SUMS\|CREDITS'` (empty output) |
| AC11 | The α Cen arrival in EYE mode shows no candidate planet above the display floor, and A and B separated by the orbit's value at the arrival epoch within 0.75 px; the inset card lists every loaded α Cen body with its badge | `make golden` (G-M5-8, arrival case) and `make ui` (inset audit) |
| AC12 | The codex entry's numbers match their PL-n check values | `make lore-check` (M4.7) |
| AC13 | Bench p99 < 16.7 ms at 2560×1440 | `make bench SCENE=flyby` |
| AC14 | Everything above runs without a GPU except AC8, AC9, AC11 (golden part) and AC13; `make test` is green locally and in CI; no new Python outside `tools/python-allowlist.txt` | `make test` (includes `python-guard`) |

## Sub-milestones and estimates

| # | Scope | LOC (code + tests) | Depends on | Art/review gate |
|---|---|---|---|---|
| M5.0 | Package: `orbits`, `reflect`, `optics.apparentDisc`; release; sim pin | 330 + 300 | the package release after M4.6a | no |
| M5.1 | `sim/data/sol.ail`, `sim/data/acen.ail`, `sim/celestial.ail`, `system` change set, flyby and dock scenarios, `flybyRoundTrip` | 330 + 220 | M5.0, M2 protocol | no |
| M5.2 | `system_view.gd`, `planet.gdshader`, `ring.gdshader`, the atmosphere shell, point/disc handoff, `physics/planets.gd`, `make planet-assets` | 380 + 140 | M5.1, M1.5a | no |
| M5.3 | Rest-frame tiles + warp pass, D-shift via `bb_lut`, metering change in `sky/exposure.gd` | 200 + 140 | M5.2 | no |
| M5.4 | Flyby demo scene, Sol docked view, α Cen arrival + inset card + codex entry | 160 + 80 | M5.3; M1.2d (#69); M4.1 stand-off (soft); M4.7 lore-check (for AC12) | S-M5 |
| M5.5 | Goldens G-M5-1 to G-M5-8, `make capture-m5`, bench, report | 50 + 120 | all of the above | S-M5 |
| **Total** | | **≈1,450 + 1,000 = 2,450** | | |

Order: M5.0 → M5.1 → M5.2 → M5.3 → M5.4 → M5.5. M5.0 and M5.1's data
tables can be written in parallel. M5.2 can start against a fixture `system`
message before M5.1 lands. M5 runs in parallel with M3 and M4 and touches
only M4's sky SubViewport (an instanced node) and M1.5a's meter.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Tiles at 1/D resolution cost too much astern at 0.99c (14× magnification) | Cap at 4,096² and measure the residual in G-M5-1; tiles only for resolved groups (rarely more than 2 at once); bench AC13 |
| JPL approximate elements plus IAU poles miss Saturn's equinoxes by more than ±10 d | The tolerance is stated in the check; if missed, take the ring-plane pole at the epoch from the IAU model's higher-order terms (data, not code) |
| The highlight meter changes how the M1 sky looks with no planet in view | The new term is max(log-average, P99.5): with no bright object the P99.5 term is below the log-average for dark skies, so M1.5a's AC8 is unchanged. M1.5a's goldens re-run in `make golden` |
| Exoplanet status changes between design and sprint (Proxima d, α Cen A b) | Status comes from the pinned archive snapshot plus cited candidate rows; a data drop updates it; code never hard-codes a status |
| Texture licence: CC BY 4.0 needs attribution | `CREDITS` file checked by AC10; shown in the credits screen |
| Half-float overflow for the Sun | Pre-exposure (already the starfield pattern); the solar luminance is passed to the glare pass as a uniform |
| AILANG gaps (e.g. ailang#1478 pattern constructors, #1465 cross-arch exp/log) | Workarounds per CLAUDE.md, cited at the site; every VM/interpreter disagreement is reported upstream with a minimal repro |
| Scope creep into in-system gameplay | Non-goal; open question 1 |

## Open questions for Mark

1. **Is the flyby player-facing in R1?** **Default:** a demo scene like M3's
   Sgr A* (scenario, free look, capture), plus Earth seen from the docked
   bridge. A player-facing "system tour" before departure, or in-system hops,
   would be R2 (a journey type at sub-light speed).
2. **Where is the ship docked at Sol?** **Default:** 50,000 km above Earth
   (Earth about 13° across, the Moon in the sky). The alternative is Sun–Earth
   L1, where Earth is 0.5° across and fully lit (the DSCOVR view).
3. **How are α Cen's uncertain worlds shown?** **Default:** as physics alone
   would show them (sub-pixel points, invisible to the eye at the stand-off),
   plus the labelled schematic inset with status badges and provenance.
   Candidates appear with a "candidate" badge; retracted claims appear only
   in the codex. **Alternative:** a close-approach scenario to α Cen A b with
   a "modelled: appearance not observed" tag. Is a speculative world ever
   worth drawing as a disc?
4. **The metering change in `sky/exposure.gd`** (a highlight-protecting term
   in EYE and CAMERA modes). It touches M1.5a's file, and stars going out next
   to a lit planet is the honest consequence. **Default:** do it, with M1.5a's
   goldens as the guard and fixed EV (F) available to the player.
5. **Package home for orbits and reflected light.** **Default:** new modules
   in `sunholo/relativity` (gate 3 names it; one pin). **Alternative:** a new
   `sunholo/celestial` package with its own release cycle.
6. **Texture resolution and size budget.** **Default:** 2k (about 25 MB in the
   bucket). 8k Saturn/Jupiter/Earth adds about 150 MB to the D-18 asset fetch.
7. **The moon list.** **Default:** the 11 above. Add Iapetus (Saturn's
   two-tone moon) and the five large Uranian moons? (Each is a data row.)

## Design-repo changes M5 needs

M5 does not edit the design repo. On landing (or earlier, if Mark wants the
spec first), these changes are needed:
1. **`roadmap/r1-foundations.md`:** an M5 section "Planets and flybys" (goal,
   items M5.0–M5.4, acceptance as above) and a D-26 line under "Decisions";
   the M4 item-3 text gains "the system's worlds are shown with their status
   (M5)".
2. **`physics/relativity-spec.md` §2,** row "3D objects nearby": replace
   "Aberrate every vertex" with "render the rest-frame image at the observer's
   event (retarded positions) and resample it per pixel by inverse
   aberration; Terrell–Penrose rotation follows". Add check values **RS-24 to
   RS-29** (apparent disc centre and radius at β 0.9 and 0.99, θ 90°, α 5°,
   and β 0.9, θ 150°) and qualitative **RS-Q5** "the sphere's outline is a
   circle in angle space; its apparent centre is not the aberrated centre".
3. **A new normative `physics/planets-spec.md`:** the ephemeris source and
   validity window, the mean-orbit fallback, the photometry model (p_V,
   Lambert/Minnaert, phase law), ring single scattering, the atmosphere
   approximation statement, the α Cen honesty rules, and check values
   **PL-1…** (Jupiter's opposition V, Saturn's equinox dates, E☉(1 AU), the
   ring radii, the Jupiter light-time lag, the α Cen AB separation at the
   arrival epoch).
4. **`features/future/planetary-rings.md`, `planet-rendering-polish.md`,
   `features/ailang-planet-ring-moon-data.md`,
   `features/phase1-data-models/planet-data-migration.md`:** a status line
   "Superseded by the M5 design (stapledons-godot)", noting the corrections
   (moon distances, "Fresnel = Rayleigh", ring shadows now in scope).
5. **`lore/archive/`:** entries "The worlds of α Centauri" and "Saturn's
   rings" with `checks:` front matter citing PL-n and RS-n.
6. **`vision/design-decisions.md`:** record D-26 and Mark's answers to the
   open questions above.

## Deliverables

- **Package:** `orbits.ail`, `reflect.ail`, `optics.apparentDisc`, tests,
  CHANGELOG, release.
- **Sim:** `sim/celestial.ail`, `sim/data/sol.ail`, `sim/data/acen.ail`,
  `sim/celestial_test.ail`, the `system` change set and the scenarios in
  `sim/protocol.ail` and `sim/ship.ail`, `flybyRoundTrip`.
- **Godot:** `planets/system_view.gd`, `planets/planet.gdshader`,
  `planets/ring.gdshader`, `planets/atmosphere.gdshader`,
  `planets/flyby_warp.gdshader`, `physics/planets.gd`, `scenes/flyby.tscn`,
  the arrival inset card, the metering change in `sky/exposure.gd`.
- **Data and tools:** `data/planets/SHA256SUMS`, `CREDITS`,
  `make planet-assets`, `make capture-m5`, the α Cen exoplanet snapshot pin.
- **Tests:** `tests/test_physics.gd` additions, goldens G-M5-1 to G-M5-8,
  `renders/m5/`.
- **Docs:** `design_docs/implemented/r1/m5-report.md` on landing; changelog
  entry; the design-repo changes above (made by the landing step, not by
  this doc).

## Verification log

| # | Claim | Command | Result |
|---|---|---|---|
| V1 | No planet or body code in the rebuild; M1 and M4 defer planets and Terrell | `git ls-files \| grep -i -E 'planet\|orbit\|celestial'` at `7ac4778`; `sed -n 101p design_docs/planned/r1/m1-relativistic-sky.md`; `sed -n 122p design_docs/planned/r1/m4-first-journey.md` | Only `.claude/skills/starmap-manager/scripts/download_exoplanets.sh` (a download script, unused by the game);  "Planets and nearby 3D objects, including Terrell rotation (M4 or later)"; "planets; Terrell rotation" in M4's non-goals |
| V2 | M4's arrival scene is two stars at a 1,000 AU stand-off | `grep -n "overhead or" design_docs/planned/r1/m4-first-journey.md`; `grep -n "HB-9[1-4]" ../stapledons-design/physics/higgs-bubble.md` | "α Cen A and B are overhead or beside the dome"; HB-91 −12.2 mag, HB-92 0.64°, HB-93 2.04°, HB-94 1.35° |
| V3 | `sunholo/relativity` 0.5.2 has no orbit or reflected-light function | `ls ~/.ailang/cache/registry/sunholo/relativity/0.5.2/*.ail`; `grep '^export' …/optics.ail …/photometry.ail` | Modules optics, photometry, blackbody_photometry, schwarzschild, kinematics, journey, medium, hyper; `illuminanceFromV`, `dopplerApparent`, `deaberrate` exist; nothing for Kepler, albedo or phase |
| V4 | The spec's nearby-object row says "aberrate every vertex" and its circle check has no ID | `grep -n "3D objects nearby" ../stapledons-design/physics/relativity-spec.md` | "Aberrate every vertex … (Terrell–Penrose rotation) \| Sphere stays circular in outline"; RS-1…RS-23 contain no disc value |
| V5 | M1.5a scene units, metering and pre-exposure | `sed -n 1,60p sky/exposure.gd`; `grep -n exposure sky/starfield.gdshader` | lux / cd/m², EYE = max(EV_dark, EV_meter), log-average CAMERA meter K = 12.5; the starfield multiplies by an `exposure` uniform (1/L_white) |
| V6 | The Go build: Saturn screenshot, SR shader defects, data errors, texture licence | Read-only survey at `930eca1` (bounded finds, maxdepth ≤ 3); `ls -la docs/images out/screenshots` | As in [§Old build](#the-retired-go-build-what-to-keep-what-was-wrong); `out/screenshots/` contains only `.gitkeep` |
| V7 | Oracle numbers (apparent disc, D, Jupiter V, Saturn luminance, light-time, deflection, α Cen visibility) | Throwaway Python in the session scratchpad (not committed; an oracle only) | As quoted. Each becomes a package value in M5.0 |
| V8 | D-26 ruling and queue row 6c; D-27 glare (row 6b) | `git show origin/docs/d26-planets-glare:design_docs/stapledon-mission.md \| grep -n -E 'D-26\|D-27\|6c\|6b'` | D-26 RESOLVED (attended 2026-10-03), row 6c ~2,000 LOC; D-27 glare and auto-dimming glazing, row 6b |
