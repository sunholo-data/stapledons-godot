# M5: Planets and flybys

**Status:** **Approved** (Mark, attended 2026-10-03); awaiting the sprint plan
(sprint-planner, run separately). Created 2026-10-03 from ledger **D-26** (attended 2026-10-03, queue
row 6c): "a new R1 milestone M5 'Planets and flybys': AILANG-driven
solar-system data, Godot planet rendering with rings and relativistic flyby
views, Sol's planets plus the α Cen arrival scene; design doc first." Mark's
prompt: "we have that in the old original stapledon binary: renders of saturn
and planet solar system flybys etc."
**Revised 2026-10-03** for Mark's answers to the first draft's open questions
(attended; see [§Open questions](#open-questions-for-mark)). **The flyby is
player-facing in R1:** the player flies through the solar system with M2's
plan → commit → boost → cruise → brake. That adds in-system navigation
(M5.5), its UX (M5.6) and a second package, **`sunholo/celestial`**, for
orbits and reflected light (M5.0a).
**Approved 2026-10-03** (Mark, attended), with his answers to N1–N3: a
lighter confirm for short in-system legs (defined in
[M5.6](#m56-in-system-ux-system-map-plan-transit)), 0.001c–0.99c in-system,
and stops and flybys at all 11 moons with ring planes refused.
**Release:** r1 · **Milestone:** M5 (new; the design repo's roadmap has no M5
row yet, see [§Design-repo changes](#design-repo-changes-m5-needs))
**Priority:** P1. It completes M4's arrival scene and the "3D objects nearby"
row of the relativity spec, and it gives the player somewhere to go before
the first interstellar commit. It does not block M2, M3 or M4.
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
- [journey-system](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md)
  and M2's journey core
  ([m2-journey-core.md](../../implemented/r1/m2-journey-core.md)), extended
  from stars to bodies: the same planner, commit rule, energy ledger and
  replay, with in-system targets (M5.5).
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
  (line 178); "DEPARTURE (rich local parallax from planets/moons …)" and
  "parallax returns as destination system objects become resolvable"
  (line 618). These drive the in-system views and the α Cen honesty rules.
- [roadmap/r1-foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md)
  §M4 item 3 (arrival at a 1,000 AU stand-off; HB-91 to HB-94 in
  [higgs-bubble.md](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md)),
  and higgs-bubble property 3 (the pocket's acceleration is not felt), which
  M5.5 uses to hold a straight line against planetary gravity.
  `features/future/planet-state-transitions.md` (civilisation states) is **not**
  implemented here. It is R2 gameplay.

**Depends on:**
- **M2 journey core** (landed): `planIntent`, `planBurnCoastBurn` with its
  flip-and-burn fallback for short legs, the commit rule, the energy ledger,
  named RNG streams, `make replay`, the galaxy map. Hard: M5.5 extends it.
- **M1.5a photometric exposure** (landed, PR #80): scene units are lux and
  cd/m², EYE/CAMERA metering, pre-exposed shaders. Hard: planets use the same
  units and the same single tonemap.
- **M4.3a HUD, time warp and `DisplayBinding`** (M4 sprint). Soft: M5.6
  extends them. If M4.3a has not landed, M5.6 builds them on the sky-only
  harness and M4 adopts them.
- **M1.2d bright tier** (PR #69): α Cen A, B and Proxima astrometry. Hard for
  M5.7's arrival scene only.
- **M4.1 stand-off** (`sim/consequence.ail`): where the ship stops at α Cen.
  Soft: M5.7 can place the ship at the stand-off by scenario until M4.1 lands.
- **Queue row 6b, forward glare and auto-dimming glazing** (D-27). Soft: the
  solar disc (1.9 × 10⁹ cd/m²) needs the same glare path. Until 6b lands, the
  Sun renders as a clipped disc and the M5 report lists the gap.
- **Packages:** the new `sunholo/celestial` 0.1.0 (M5.0a). The
  `sunholo/relativity` release after M4.6a's carries `optics.apparentDisc`
  (M5.0b). The sim pins both; the lockfile and the bundled cache move
  together.

**Estimated:** ~3,750 LOC (≈2,210 code + 1,540 tests and tools) in 9
sub-milestones. The first draft's ~2,450 assumed a demo scene. Making the
flyby player-facing adds in-system navigation in the sim (~700) and its UX
(~450), and the separate package adds its scaffolding and quality work
(~150). The queue row's ~2,000 was set before any of this was scoped.
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
Verdict: **ALIGNED**. Re-scored for the player-facing scope: Choices Are Final
moves from 0 to +1, so the net moves from +6 to +7.

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | + | +1 | Every in-system leg is a committed M2 journey: no cancel mid-leg, and a flyby you set up is the flyby you get, at the speed you chose. The stakes are small next to the interstellar commit, and that is deliberate: the solar system is where the player learns the ritual |
| The Game Doesn't Judge | 0 | 0 | |
| Time Has Emotional Weight | + | +1 | Old light made visible: Jupiter is drawn where it was 35 minutes ago. A Saturn tour costs hours of Earth time, and the HUD shows both clocks. At α Cen every world carries its data source and how old the light was (design decision, line 178). Before departure Earth fills the dome; from α Cen the Sun is a magnitude +0.5 star |
| The Ship Is Home | + | +1 | Planets are seen through the same dome and exposure as everything else, from the bridge at Earth, on a Saturn pass and on arrival. Home is a place you can see, and then can't |
| Grounded Strangeness | ++ | +2 | Saturn at 0.9c: the disc stays a circle but shrinks, slides forward and turns violet at its leading edge; you see round to the side that faced away. Next to a sunlit planet the eye's stars go out. Strange, and exactly right |
| We Are Not Built For This | 0 | 0 | Hinted at only: the eye cannot hold a lit planet and the stars at once (23 stops apart) |
| Hard sci-fi authenticity (spec) | ++ | +2 | Real ephemerides with a stated validity window, intercepts of moving planets, gravity held off by the drive and costed, photometry tied to geometric albedo, ring optical depth, Terrell rotation from exact per-pixel aberration. Speculative exoplanets are marked as such and are never drawn as discs |
| **Net** | | **+7** | **Go** |

## Problem

1. **No planet exists in the rebuild.** M1 lists "planets and nearby 3D
   objects, including Terrell rotation (M4 or later)" as a non-goal
   (`m1-relativistic-sky.md:101`), and M4 lists "planets; Terrell rotation"
   as non-goals (`m4-first-journey.md:122`). The sim has no body except stars
   (V1).
2. **There is nowhere to go but other stars.** M2's planner targets catalogue
   stars only: `Target = { index, id, pos }` with the position supplied by the
   client (`sim/core.ail:73`, `sim/protocol.ail:184`; V9). A planet moves, so
   it needs an intercept, which the client cannot compute under ADR 0001.
3. **M4's arrival is a pair of points with no system.** M4.3 says only "α Cen
   A and B are overhead or beside the dome" (V2). Proxima, the only confirmed
   planet host in the system, is not mentioned. Nothing tells the player which
   worlds are known and which are guesses.
4. **No package has orbit or reflected-light maths** (V3). `sunholo/relativity`
   0.5.2's modules are `optics`, `photometry`, `blackbody_photometry`,
   `schwarzschild`, `kinematics`, `journey`, `medium` and `hyper`. Gate 3
   says that maths goes into a package first.
5. **The relativity spec's method for nearby objects is under-specified.**
   "Aberrate every vertex" is exact only at the vertices: a straight triangle
   edge between two aberrated vertices is not the aberrated edge, and the spec
   has no check value for an apparent disc. Its one check ("sphere stays
   circular in outline") has no ID (V4).
6. **Planets break the exposure range.** Sunlit Saturn's globe is about
   330 cd/m² (oracle); the deep-space dark sky is 4.3 × 10⁻⁵ cd/m²
   (D-25), 23 stops apart. M1.5a's log-average meter is dominated by the dark
   sky, so a bright planet would clip. The solar disc (1.9 × 10⁹ cd/m²) is above
   half-float range (65,504) unless it is pre-exposed (V5).
7. **The Go build's planets are a reference for the look, not the physics**
   ([§Old build](#the-retired-go-build-what-to-keep-what-was-wrong)): wrong SR
   shader, look-unit scales, moons inside planets, rings tilted without their
   planet.

## Goals and non-goals

- **G1. Sol's system from the sim.** The Sun, 8 planets, 11 moons and 4 ring
  systems. Positions come from published mean orbital elements, and pole and
  spin from the IAU rotation model. All of it is pure, deterministic AILANG,
  in the galactic frame the starfield uses.
- **G2. Fly through it.** From the start (held 50,000 km above Earth), the
  player picks a body on the system map, chooses to **stop** near it or **fly
  by** it (closest distance and side), sets a cruise speed from 0.001c to
  0.99c, sees the plan (both clocks, β and D at the pass), commits, and rides
  the leg. Legs chain. From any stop the galaxy map still plans the
  interstellar journey. The whole session replays byte-identically.
- **G3. Physically lit planets in physical units.** Reflected sunlight in
  cd/m², from geometric albedo and a stated phase law, through M1.5a's single
  exposure and tonemap. Sub-pixel bodies are point sources through the
  starfield path, with flux continuous across the crossover.
- **G4. Rings that behave like rings.** A normal optical-depth profile with
  slant-path transmission, lit and unlit faces, the planet's shadow on the
  rings and the rings' shadow on the planet.
- **G5. Relativistic flybys done exactly.** The rest-frame image at the
  observer's event is warped per pixel by inverse aberration and Doppler
  shifted at the apparent angle. Terrell–Penrose rotation follows from that;
  it is not added on. Light-travel time is applied.
- **G6. The α Cen arrival scene.** A and B on their real binary orbit,
  Proxima, and the system's planets with their status (confirmed or
  candidate), shown as physics shows them, plus a labelled inset. Nothing
  speculative is drawn as a disc.
- **G7. Gate 2 in full** for every SR visual: check values from the packages
  in `tests/test_physics.gd`, GPU goldens, and reference renders Mark has
  looked at.

**Non-goals (R1):**
- In-system travel at α Cen. Its planets have no measured radius or albedo,
  and Mark ruled out modelled discs (Q3), so no α Cen planet is a visitable
  target. Approaching α Cen A or B themselves would need stellar-disc and
  glare rendering (row 6b), so the system map there is view-only in R1.
- Orbits as a flight mode (Keplerian coasting, gravity assists, orbital
  insertion). Legs are straight lines held by the drive (M5.5); a stop is a
  station-keeping hold, not an orbit.
- Moving relativistic geometry (another ship passing at 0.9c). Every M5 body
  is at rest in its system frame to 2 × 10⁻⁴ c. The Terrell work here is
  observer motion only.
- N-body integration, perturbation theory, precession beyond the published
  secular rates, the Sun's barycentric wobble (about 1 R☉).
- GR on planets. Light deflection at the solar limb is 1.75″, under 0.02 px at
  a 60° field of view on 2560×1440 (one pixel is about 84″). It is stated and
  not drawn.
- Landing, planet surface states, civilisations, and Earth's night-side city
  lights (a future Earth's lights are a canon question, not data).
- Multiple-scattering atmospheres, cloud animation, ring particle dynamics.
- Exoplanet systems other than α Cen.

## Design

ADR 0001 holds: **the sim owns state and rules; Godot owns presentation.**
Godot computes no orbit, intercept, flux or γ.

### M5.0 Packages first

Gate 3 says that physics maths lives in a package before the game uses it.
Mark ruled (Q5) that orbits and reflected light go into **a new, separate
package, `sunholo/celestial`**, and that `sunholo/relativity` stays
relativity-only.

#### M5.0a `sunholo/celestial` 0.1.0 (new package)

**No dependency on `sunholo/relativity`.** Where celestial needs a photometric
input, it takes it as a parameter (for example the star's illuminance at
1 AU), and the sim passes the value from relativity's `illuminanceFromV`. So
the two packages release independently, and neither imports the other. Units
are float64 SI-astronomical: AU, days (TDB), km, radians, lux, cd/m².

| Module | Function | Formula / source | Check (oracle estimate until M5.0a) |
|---|---|---|---|
| `kepler` | `solveKepler(M, e)` | Newton on E − e sin E = M, a fixed 8 iterations from E₀ = M + e sin M (deterministic iteration count; strict-VM safe) | Residual < 1e-14 for e ≤ 0.97; e = 0 gives E = M exactly |
| `kepler` | `stateFromElements(el)` | Perifocal → ecliptic J2000 position (AU) and velocity (AU/d) | Circular e = 0 orbit radius = a exactly; vis-viva holds to 1e-12 |
| `ephemeris` | `elementsAt(el, rates, jdTDB)` | JPL "Keplerian Elements for Approximate Positions of the Major Planets" (Standish), Table 2a (3000 BC–3000 AD) with the b, c, s, f terms for Jupiter–Neptune; secular rates frozen at the window edge outside it | Jupiter opposition 2023-11-03 (elongation 180° within ±2 d); Mars opposition 2020-10-13 (±2 d) |
| `ephemeris` | `satelliteAt(el, jdTDB)` | JPL SSD mean satellite elements referred to the Laplace plane, with node and periapsis rates | The Moon's distance within the published perigee–apogee range; Io's period 1.769 d within 1e-4 d |
| `frames` | `eclipticToGalactic(v)` | Constant rotation: ecliptic J2000 → ICRS (obliquity 84381.406″) → galactic (Hipparcos 1997 matrix, the one the starfield frame uses) | The north ecliptic pole maps to galactic (l, b) = (96.38°, 29.81°) within 1e-4° |
| `frames` | `poleAndSpin(body, jdTDB)` | IAU WGCCRE 2015 (Archinal et al. 2018): α₀, δ₀, W | Saturn's Sun ring-plane crossings (equinoxes) 2009-08-11 and 2025-05-06, within ±10 d (pole + JPL elements together) |
| `lighttime` | `retardedTime(srcFn, obs, t)` | Fixed-point t_r = t − ‖x_obs(t) − x_src(t_r)‖/c, 4 iterations (contraction v/c ≤ 2e-4) | Jupiter at opposition from Earth: lag 2,094 s; the planet is drawn 27,400 km (0.38 R♃) behind its instantaneous position |
| `gravity` | `accelerationAt(bodies, x, jdTDB)` | Newtonian sum Σ GMᵢ (xᵢ − x)/‖xᵢ − x‖³ with IAU 2015 nominal GM values; refuses (returns `inside`) within any body's radius | At 50,000 km altitude above Earth: 0.1254 m/s²; at 1.5 R♃ from Jupiter: 11.0 m/s² |
| `reflect` | `starIlluminanceAt(e1AU, rAU)` | E = e1AU / r² (inverse square from a point source) | E☉(1 AU) = 1.2706 × 10⁵ lux when the sim passes relativity's `illuminanceFromV(−26.74)` (relativity 0.7.0's V = 0 zero point, 2.56 × 10⁻⁶ lux; the draft's 1.261 × 10⁵ used 2.54 × 10⁻⁶. The package is the single copy, so this row follows it; updated after M5.1b's evaluation) |
| `reflect` | `lambertPhase(α)`, `lambertRadiance(rho, E, cosI)` | Φ(α) = (sin α + (π − α) cos α)/π; L = ρ E cos i / π | Φ(0) = 1, Φ(π/2) = 1/π, Φ(π) = 0 |
| `reflect` | `minnaertRadiance(rho, k, E, cosI, cosE)` | L = ρ E cosᵏi cosᵏ⁻¹e / π (giants' limb darkening); k = 1 is Lambert | k = 1 equals `lambertRadiance` to 1e-15 |
| `reflect` | `rhoFromGeometricAlbedo(p, k)` | ρ such that the disc-integrated opposition flux of the Minnaert sphere equals p (Lambert: ρ = 3p/2) | Round trip to 1e-12 |
| `reflect` | `discIlluminance(e1AU, p, R, rAU, d, α, k)` | The body's illuminance at the observer: e1AU p (R/d)² Φ(α) / r² | Jupiter at opposition (r 5.20, Δ 4.20 AU, p_V 0.538): V −2.77 (observed about −2.7 to −2.9) |
| `rings` | `ringLitRadiance(w0, P, tau, mu0, mu, E)`, `ringUnlitRadiance(...)` | Classical single scattering in a thin layer (Chandrasekhar; as used for Saturn's rings, Cuzzi et al.): lit face I/F = w0 P μ0/(4(μ + μ0)) [1 − e^(−τ(1/μ + 1/μ0))]; unlit face (μ ≠ μ0) w0 P μ0/(4(μ − μ0)) [e^(−τ/μ) − e^(−τ/μ0)] | τ → ∞ lit face equals the Lommel–Seeliger law; τ → 0 both tend to 0; the unlit-face limit at μ → μ0 is finite |
| `rings` | `ringTransmission(tau, mu)` | e^(−τ/|μ|) | τ = 0 gives 1; μ = 1 gives e^(−τ) |

**Package-first procedure (Mark, Q5):** `ailang pkg init` for the new package,
then tests for every row, CHANGELOG, `[release] kind`, `ailang pkg quality`
with no gates, **an independent evaluation** (a different agent or model from
the author, as for sprints: generator ≠ judge), and only then publish. The
sim pins 0.1.0. GDScript (`physics/planets.gd`) and the shaders mirror these
functions and are never the only copy.

#### M5.0b `sunholo/relativity`: `optics.apparentDisc`

**Decision: `apparentDisc` stays in relativity.** It is genuinely optics: its
inputs are a direction, an angular radius and a rapidity, and its whole
content is the aberration map applied to a circle on the sky (built on the
existing `cosSeen`). It knows nothing about orbits or planets, and its check
values are the new SR spec rows RS-24 to RS-29. Moving it to celestial would
make celestial depend on relativity for no gain.

| Function | Formula | Check (oracle estimate until M5.0b) |
|---|---|---|
| `optics.apparentDisc(cosTheta, alpha, phi)` | A sphere of angular radius α centred at rest angle θ. Aberration is conformal on the sky, so the image is a circle; its edge points are the aberrated θ ± α along the meridian. Returns the apparent centre (not the aberrated centre) and the apparent radius | β 0.9, θ 90°, α 5°: centre 25.928°, radius 2.184° (the aberrated centre is 25.842°). β 0.99: 8.140°, 0.707°. β 0.9, θ 150°: 82.021°, 9.940° (magnified astern) |
| (existing) `dopplerApparent`, `deaberrate`, `gammaOf`, `oneMinusBeta`, `journey.planBurnCoastBurn`, `journey.motionAt` | Reused unchanged | D at the disc centre: 2.2871 (β 0.9, θ 90°), 7.0623 (β 0.99), 0.4981 (β 0.9, θ 150°) |

Same release rules as M4.6a (tests, CHANGELOG, `[release] kind`, quality with
no gates), in whichever release follows M4.6a's. If M3's `hover_power`
(m_eff a c, HB-90) has not been released by then, it ships here, because
M5.5's hold ledger uses it and it is bubble physics, not celestial mechanics.
**Precision:** the near-c branch uses `oneMinusBeta(phi)`, never `1 - beta`.

### M5.1 Sim: `sim/celestial.ail` (pure) and the `system` change set

**The data is AILANG source, with a citation on every row.** It is small, so
there is no file I/O in the core:
- `sim/data/sol.ail`: Standish Table 2a elements and rates for the 8 planets;
  IAU 2015 poles, W₀ and Ẇ; equatorial radius and flattening; GM (IAU 2015
  nominal); V-band geometric albedo p_V (Mallama et al. 2017) and Minnaert k
  (Jupiter, Saturn, Uranus, Neptune; Lambert elsewhere).
  - **Moons (11; Mark's default, Q7)**, from JPL SSD planetary-satellite mean
    elements: the Moon; Io, Europa, Ganymede, Callisto; Mimas, Enceladus,
    Tethys, Dione, Rhea, Titan; Triton.
  - **Rings**: a radial profile per giant, `[(r_inner_km, r_outer_km, tau,
    w0)]` in the planet's equatorial plane. Saturn: D, C, B (inner and core),
    Cassini Division, A (with the Encke gap), F. Uranus: 6, 5, 4, α, β, η, γ,
    δ, ε. Neptune: Galle, Le Verrier, Lassell, Arago, Adams (arcs as an
    azimuthal factor). Jupiter: halo, main, gossamer. τ comes from published
    occultation profiles (Saturn: Cassini UVIS/RSS, Colwell et al. 2009; Uranus:
    French et al. 1991; Neptune and Jupiter: Voyager/Galileo summaries),
    averaged per region. Colour is a rest-frame sRGB tint from imagery,
    labelled as a tint and not a spectrum.
- `sim/data/acen.ail` (see [M5.7](#m57-scenes-the-α-cen-arrival-and-the-start-at-earth)).

**The time base.** `system.jd` = scenario epoch (a JD; D-12 makes the epoch a
scenario parameter) + Earth time t (M2's galaxy clock, years × 365.25 d).
**Validity window:** Table 2a holds for 3000 BC–3000 AD. Outside it,
`elementsAt` freezes the secular rates at the window edge; the bodies keep
moving on their Kepler orbits, so phases still advance. The sim marks
`ephemeris: "mean-orbit"` (as opposed to `"jpl-approx"`), and the codex says
so. The game can run for a million years, and no ephemeris predicts that far.
Saying so is the honest option.

**Pure functions** (`sim/celestial.ail`, no I/O, `--strict-bytecode` clean):
- `bodyAt(sys, id, jd)`: the body's position and velocity in the galactic
  frame (km, km/s, float64) and its pole and W. This is what the planner
  intercepts (M5.5).
- `systemAt(sys, jd, shipLy)` (as landed in M5.1b: the caller passes
  jd = epoch_jd + t × 365.25 and the ship's galactic position in ly) returns
  `[BodyView]` for every body:
  - `id`, `name`, `kind` (star, planet or moon; a ring host is a planet with
    a non-empty `ring_id`), `host`, `status` (see
    [M5.7](#m57-scenes-the-α-cen-arrival-and-the-start-at-earth));
  - `rel_km` (float64[3]): the body at its retarded time minus the ship, in
    the galactic frame;
  - `radius_km`, `flattening`, the pole (unit vector) and `w_deg` at the
    retarded time;
  - `sun_dir` (unit, body → star at the body's retarded time; the zero
    vector for the star itself, so a renderer never normalises a star's
    `sun_dir`), `r_au`, `phase_deg`;
  - `e_v_lux` (`discIlluminance`), `p_v`, `minnaert_k`, `ring_id`;
  - `light_age_s` (t − t_r, shown in the inspect panel and the codex);
  - `visitable` (bool: measured radius and albedo; M5.5 refuses others);
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

### M5.2 Godot: physically lit planets and rings (rest frame)

Everything renders into **M4's sky SubViewport** (layers 1–2, HDR float) and
is **pre-exposed** the way the starfield already is (`sky/starfield.gdshader`
multiplies by `exposure` = 1/L_white). So there is one tonemap (G-M4-2 holds)
and the solar disc does not overflow half-float. Node: `planets/system_view.gd`,
fed only by `SimBridge.system` (the bridge's field-checked copy of the
`system` section, M5.1b; the raw section also lands in `SimBridge.world`).

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
- **Surface (Mark, Q6).** Albedo textures from **Solar System Scope (CC BY
  4.0) at 2k, about 25 MB**, served from the **public bucket**
  `gs://stapledons-voyage-assets/planets/` and fetched by sha256 like the sky
  (`make planet-assets`, the D-18 pattern; pins in `data/planets/SHA256SUMS`;
  `make planet-publish` for maintainers). They are credited in-game. Each
  texture is normalised so its disc-integrated albedo equals the data's p_V,
  so the texture sets pattern and colour and the data sets brightness. Moons
  without a free texture are uniform albedo spheres (USGS public-domain
  mosaics are a follow-up). The radiance is `minnaertRadiance` (the shader
  mirrors the package), so giants get limb darkening and rocky bodies are
  Lambert. The pole and W come from the sim, and **the whole system (globe,
  rings, moons) shares the pole**, unlike the old build.
- **The Sun.** It lights every body as a point source with
  E = `starIlluminanceAt`. When resolved it draws as a disc (linear limb
  darkening, u = 0.6, flux-normalised) at 1.9 × 10⁹ cd/m². Its luminance goes to
  the glare pass (row 6b) as a uniform, not read back from the clamped buffer.
- **Rings** (`planets/ring.gdshader`): an annulus in the equatorial plane.
  Per pixel it looks up τ(r), takes the lit or unlit face from the sign of the
  sun and view elevations, uses `ringLitRadiance`/`ringUnlitRadiance`, and
  sets alpha = 1 − `ringTransmission`. The ring shadow on the globe and the
  globe's shadow on the rings are analytic: ray–plane and ray–sphere
  intersections toward the Sun, with transmission e^(−τ/μ0) and a penumbra
  from the Sun's angular radius. Moon shadows on their planet (up to 4 sphere
  occluders) use the same code.
- **Atmospheres, honest about approximation.** Earth, Venus and Titan get one
  outer shell with **single-scattering Rayleigh + Mie, exponential density
  (scale heights 8 km and 1.2 km for Earth), and no multiple scattering**. The
  result is a limb that is slightly too dark and too saturated. The code and
  the codex say so. Gas giants get no shell; their texture and Minnaert law
  carry the limb. The Go docs' "Fresnel glow" is not used: Fresnel reflection
  is not what makes Earth's limb blue.
- **CPU mirror:** `physics/planets.gd`, used by the tests and the goldens.

### M5.3 The relativistic view: exact per-pixel aberration of the rest-frame image

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
   the sim as float64 uniforms. In the shader, 1 − β cos θ′ is rewritten as
   (1 − β) + β(1 − cos θ′) for precision.
3. **Spectrum.** Reflected sunlight is a diluted 5,772 K blackbody. Since
   I_ν/ν³ is invariant, a diluted blackbody at T is seen as the same dilution
   of a blackbody at D·T (spec §2). The warp reuses M1's `bb_lut` to give the
   luminance ratio and chromaticity at D·T, times the texel's rest-frame
   albedo.

At β = 0 (a hold, or a slow leg below β 10⁻⁴) the warp is the identity and
D = 1; G-M5-1 includes β = 0 to pin that.

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

### M5.4 Exposure interplay (M1.5a and the meter)

- **Units.** Discs are luminance in cd/m² and points are illuminance in lux:
  the same units as the sky and the stars, and the same pre-exposure.
- **The meter must see planets (Mark's default, Q4).** M1.5a's log-average
  meter is dominated by the dark sky: with Saturn filling a quarter of the
  frame it meters about 2 × 10⁻³ cd/m², and Saturn would sit 14 stops over
  white. M5 adds a **highlight-protecting term** to EYE and CAMERA metering in
  `sky/exposure.gd`: EV_meter = max(log-average EV, EV(P99.5 luminance /
  headroom)), with headroom = AgX's white point. This is the standard
  histogram-percentile auto-exposure. EYE stays EV = max(EV_dark, EV_meter),
  as M1.5a defined it. **M1.5a's goldens guard it** and must pass unchanged:
  with no bright object in view, the P99.5 term is below the log-average.
- **The consequence is physics.** A lit planet and the naked-eye stars are
  23 stops apart, and the eye spans about 14. Next to Saturn the stars vanish
  in EYE mode. **Fixed EV** (F) shows Saturn blown out and the stars back. The
  labelled aids (exposure bias, magnitude floor) behave as in M1.5a and are
  off by default.
- **Metering in motion.** On a fast pass the planet crosses the frame in
  seconds. The eye adapts with M1.5a's time constant, so a pass at 0.5c
  shows the stars fading in and out around it. That is the eye, not a bug,
  and fixed EV removes it.
- **The Sun** is clipped by the tonemap until row 6b's glare and auto-dimming
  glazing land; it is then handled the same way as the forward CMB disc (D-27).

### M5.5 In-system navigation in the sim (M2's journey core, extended to bodies)

**One journey model.** An in-system leg is an M2 journey: plan → commit →
boost → cruise → brake, through the same `planBurnCoastBurn` (with its
flip-and-burn fallback when the leg is too short to reach the cruise speed),
the same commit rule (no cancel until arrival), the same energy ledger, the
same clocks and the same replay. What changes is the target and the
geometry.

**Scale check, so nothing new is needed in the kinematics.** At D-15's
7.5 × 10⁵ g a boost to 0.99c covers about 0.49 AU in 1.8 min of ship time, and
a boost to 0.5c covers about 0.013 AU. Earth → Saturn (about 9 AU) at 0.5c takes
about 2.5 h of Earth time. Earth → Moon at 0.01c takes 128 s. The closed-form
`motionAt(plan, τ)` gives the ship's state at every tick exactly, so a pass
that lasts one second at 0.5c needs no integration and no small step.

**The plan intent, extended.** M2's `Target` (`{index, id, pos}`, with the
position from the client) gains a body form. For a body, the sim ignores any
client position and computes the target itself:

```
plan{ target: {kind: "body", id: "saturn"},
      profile: {cruise_beta},                      -- 0.001 ≤ β ≤ 0.99 in-system
      approach: {mode: "stop",  standoff_km}
              | {mode: "flyby", b_km, clock_deg, run_out_km} }
```

- **Stop.** The arrival point is `standoff_km` from the body's centre on the
  approach line, at the body's position **at the arrival time**. The default
  stand-off is the larger of 10 R and 1.5 × the outer ring radius; the player
  can set it between the safety minimum and 0.1 AU.
- **Flyby.** The ship passes the body at closest distance `b_km`, on the side
  given by `clock_deg` (0° = the body's north, measured around the approach
  line). It cruises on to a stop point `run_out_km` beyond the pass (default:
  the braking distance plus 10⁶ km), so the pass happens at cruise speed. The
  leg is one burn–coast–burn from the start to that stop point, along a
  straight line through the pass point. If the player sets a short run-out,
  the pass falls in the brake phase; that is allowed, and the plan reports β
  at the pass.
- **Intercept (planets move).** Saturn moves about 87,000 km (1.4 R♄) during a
  2.5 h leg, so the planner aims at where the body will be. It iterates
  t_a ← t₀ + `planBurnCoastBurn`(‖aim(t_a) − x₀‖, a, φ).galaxyTime, 12 fixed
  iterations. The contraction factor is v_body/v_ship ≤ 50 km/s ÷ 0.001c =
  0.17, so 12 iterations leave less than 10⁻⁹ of the leg. The intercept is a
  composition of a celestial function (`bodyAt`) and a relativity function
  (`planBurnCoastBurn`), so it is game logic in the sim, not new maths for a
  package. The residual is asserted (AC17).
- **Safety refusals** (M2's `refused: [{i, reason}]`): `collision` (the line
  passes within R + bubble radius of any body over the leg, checked at the
  closest-approach time of each body); `ring_crossing` (the line crosses a
  ring plane inside the outer ring radius: at 0.5c a ring particle on the
  wall would carry the ISM-mirror load many times over); `too_close`
  (b or stand-off below the safety minimum); `not_visitable` (the body lacks
  a measured radius or albedo: all α Cen planets in R1); `committed` (M2's
  rule).
- **As landed in M5.5a** (`sim/navigation.ail`; the choices this section left open):
  the **safety minimum** is 1.1 R + the bubble radius (a 10 % margin over every
  atmosphere in Sol); a stand-off below it, or a b below it, is `too_close`,
  and a stand-off above 0.1 AU is clamped to 0.1 AU. **clock_deg** 0 is the
  body's pole projected across the approach line, 90 is to its right as seen
  from the ship (clockwise on the sky), so at 90 the pass point lies in the ring
  plane. The **pass point** is the foot of the perpendicular from the body's
  centre at t_p, so the closest distance is exactly `b_km`; the pass time is
  read from the package's `motionAt` by bisection on distance (no trip formula
  restated). **collision** and **ring_crossing** take each body at the ship's
  nearest approach to it (two refinements of that time). An id outside the
  system (α Cen worlds, unknown ids) and the Sun are `not_visitable`.
  `out_of_range` covers a cruise speed outside 0.001c–0.99c, an unknown mode,
  a run-out ≤ 0, and a ship already inside the stand-off. A body plan is
  **stale** (`stale_plan` at commit) once the Earth clock has moved, because
  the body has moved on; plan and commit in one tick. Protocol **2.4** carries
  it (`journey.plan` gains `target_kind`, `intercept{t, pos}` and
  `pass{t, b_km, beta, d_at_pass}` or `hold{body, offset_km}`); below minor 4
  a body plan is `bad_intent`.

**Gravity is handled, not ignored.** The first draft neglected gravity
because a fast flyby barely bends: the deflection 2GM/(b v²) past Saturn at
b = 10⁵ km is 3 × 10⁻⁸ rad at 0.5c. Player-facing legs now go as slow as
0.001c and stop near planets, where gravity matters. M5 therefore makes the
**drive hold the planned straight line**:
- **During boost and brake** the drive's 7.5 × 10⁵ g exceeds any planetary
  gravity on a permitted path by at least 10⁵ (Jupiter's cloud tops are
  24.8 m/s²), so the error is well below a metre.
- **During cruise** the drive cancels the local gravity
  (`celestial.gravity.accelerationAt`) so the ship stays on the line. The
  pocket's acceleration is not felt (higgs-bubble property 3, the same
  property M3 uses for hovering at Sgr A*). The cost is real and costed: the
  ledger gains `hold_j` += `hover_power`(m_eff, |g|) dτ per tick (m_eff |g| c;
  HB-90's formula), shown on the HUD. Example (oracle): a pass at 1.5 R♃ at
  0.01c takes about 71 s near closest approach, needs about 780 m/s of
  cancelled impulse, and costs about 2 × 10¹¹ J per kg of m_eff.
- **At a stop** the ship holds station, co-moving with the body at the chosen
  offset, and the drive cancels the body's gravity: 0.125 m/s² at the start
  position 50,000 km above Earth, about 3.8 × 10⁷ W per kg of m_eff. Matching
  the body's velocity on arrival (at most about 2 × 10⁻⁴ c) takes under 10 ms of
  ship time at boost_g; it is applied in one tick and ledgered.
- The interstellar departure is unchanged from M2: the Sun's pull at 1 AU is
  0.006 m/s², against 7.5 × 10⁵ g.

**State and protocol** (additive, a minor bump): `journey.plan` gains
`target_kind`, `intercept{t, pos}`, `pass{t, b_km, beta, d_at_pass}` for
flybys and `hold{body, offset_km}` for stops. `ship` gains `hold{body,
offset_km, g_m_s2, hold_w}` while holding, and the ledger gains `hold_j`.
The `docked` phase becomes "holding at a body". The game starts holding
50,000 km above Earth (Mark's default, Q2), which is also M4's docked bridge
view. M2's old-message tests stay green, unmodified.

**Determinism and replay.** Every new choice is an intent in M2's input log:
plans, commits and time-warp `dtau` (including the automatic slow-down near a
pass, M5.6). The camera and free look are presentation and are not logged,
as M4 does for the avatar. A scripted **Sol tour** (start at Earth → stop at
the Moon at 0.01c → Saturn flyby at 0.5c, b = 3 R♄, north side → stop at
Jupiter at 0.1c → plan and commit α Cen) replays byte-identically on the VM
and the interpreter (`make replay SESSION=sol_tour`, per-architecture goldens
until ailang#1465), and is a `make strict` entry (`solTourRoundTrip`).

### M5.6 In-system UX: system map, plan, transit

- **System map** (`ui/system_map.tscn`, a zoom level of M2's galaxy map;
  selecting Sol opens it). An orrery of the real positions at the current
  Earth time, with a **log-radius toggle labelled "log scale"** (a linear map
  makes the inner planets a dot). Bodies show name, distance, light age and a
  status badge. It is a navigation display: it never draws into the sky.
- **Planning panel.** Choose a body, then **Stop** or **Fly by**:
  - Stop: a stand-off slider (in R and km, starting at the safety minimum).
  - Fly by: a closest-distance slider (in R; the minimum is set by the sim's
    `too_close` and `ring_crossing` rules, shown greyed out) and a
    clock-angle dial (which side, with a small preview of the body and its
    rings from the approach direction).
  - Cruise speed: 0.001c–0.99c, log slider.
  - The plan readout (every number through M4's `DisplayBinding`): ship time,
    Earth time, β and γ at cruise, β and D at the pass, apparent size at the
    pass, time to the pass, hold power at the stop, `hold_j` for the leg. The
    planned line is drawn on the map with the intercept point.
  - Refusals show the sim's reason in words (a fixed reason → phrase table,
    as M4's news fallback).
- **Commit: two dialogs, one rule (Mark, N1).** The sim's commit rule is the
  same for every leg (no cancel until arrival). Only the dialog differs, and
  **the sim, not the UI, decides which one**: every plan carries
  `confirm ∈ {"full", "light"}`.
  - **Threshold.** `confirm = "light"` when the target is a body in the
    current system **and** the plan's Earth time is at most **24 hours**
    (`plan.earth_years ≤ 1/365.25`). Everything else is `"full"`: every
    interstellar journey (a star target), and any in-system leg longer than a
    day (for example Earth → Neptune at 0.001c, about 173 days). Time, not
    distance, is the threshold because Earth time is the cost the full ritual
    exists to show. A day covers nearly every useful in-system leg at
    0.01c and above (Earth → Saturn at 0.1c is about 12.5 h). The threshold is
    a scenario parameter, `light_confirm_max_earth_s` = 86,400, so it can be
    tuned as data.
  - **The light confirm** is a one-line strip over the planning panel: the
    target and mode ("Fly by Saturn, 3 R♄, north side" or "Stop at the Moon,
    20,000 km"), cruise β, ship time and Earth time side by side, and the
    fixed line "No cancel once committed". Confirm is one press (Enter or
    click), with no 1.5 s hold; Esc returns to planning. Every number goes
    through `DisplayBinding`.
  - **The full dialog** is M4's D-12 dialog unchanged: both clocks, years left
    at home, the 1.5 s hold.
  - **Logged and replayed the same way.** Both dialogs emit the same
    `commit{plan_id}` intent into M2's input log; the dialog type is not an
    input. Replay re-derives `confirm` from the plan, and the sim refuses a
    commit only for M2's reasons, never by dialog type. The Sol tour (M5.5)
    contains both kinds: its Moon, Saturn and Jupiter legs are light, and the
    α Cen leg is full.
- **Transit.**
  - The bridge interior (M4.2) with the dome, up = direction of travel
    (D-14), or the sky-only harness if M4.2 has not landed.
  - A **window view** (V): the sky camera full screen with free look
    (`ui/free_look_camera.gd`), for watching a pass.
  - HUD additions: target distance, time to pass or arrival, β, D at the
    target, the target's apparent size, `hold_j`.
  - **In-system time warp** in ship-seconds per real second: 1, 10, 100,
    10³, 10⁴, 10⁵ (M4's ship-years-per-second levels are for interstellar
    legs). Godot steps the warp down to 1× from 30 s of ship time before the
    pass and back up after it. Each step is a logged `dtau`, so it replays.
- **At a stop.** The planet in the dome and the window view; warp runs the
  hold, so the player can watch it turn. The galaxy map is available, and an
  interstellar plan starts from the current position.

### M5.7 Scenes: the α Cen arrival and the start at Earth

**The α Cen system: what is known** (pinned in `sim/data/acen.ail` with
citations; the sprint re-verifies against the NASA Exoplanet Archive snapshot
fetched by `starmap-manager`, pinned by sha256 in `data/raw/`):

| Body | Status | Data (to be re-verified at sprint) | Shown as |
|---|---|---|---|
| α Cen A, B | stars | Binary orbit P ≈ 79.9 yr, a ≈ 17.5″ (≈ 23.4 AU), e ≈ 0.52, i ≈ 79°, Ω, ω and T from Akeson et al. 2021 / Pourbaix & Boffin 2016; masses about 1.08 and 0.91 M☉. Periastron 11.2 AU, apastron 35.6 AU (HB-92, HB-93) | Two points (≈ 1.2″ discs at 1,000 AU, far below a pixel), with the separation from the orbit at the arrival epoch |
| Proxima Cen | star | Catalogue position (M1.2d). It is about 13,000 AU from AB, so from the stand-off it is a V ≈ 4.4 red point (oracle) | Point, from the starfield |
| Proxima b | **confirmed** | P 11.19 d, a 0.0485 AU, m sin i ≈ 1.07 M⊕ (Anglada-Escudé 2016, Faria 2022). Radius unknown (non-transiting) | Point; reflected flux uses a radius **inferred** from a mass–radius relation and an **assumed** albedo and inclination, all labelled in the inset |
| Proxima d | candidate, or confirmed if the sprint's snapshot lists it | P 5.12 d, m sin i ≈ 0.26 M⊕ (Faria 2022) | As the archive says on the snapshot date, never upgraded by us |
| Proxima c | **candidate (disputed)** | P ≈ 5.2 yr (Damasso 2020) | Point, badge "candidate" |
| α Cen A b | **candidate** | JWST/MIRI direct-imaging candidate (2025): Saturn-mass, about 1–2 AU, orbit poorly constrained | Point, badge "candidate", with the orbit from one published solution, labelled "one of several fits" |
| α Cen B b | **retracted** (2012 claim, refuted 2015–16) | none | **Not loaded**; the codex mentions the retraction |

**Honesty rules (Mark, Q3; enforced by data, not by copy):**
- Every body row has `status ∈ {star, confirmed, candidate}` (retracted rows
  are not loaded) and per-field provenance: `measured`, `inferred` (with the
  relation named) or `assumed` (with the value stated). A test fails if any
  α Cen body lacks them.
- **No modelled discs.** A body with an inferred radius or an assumed albedo
  is never drawn as a resolved disc and is never a visitable target
  (`visitable = false`, refusal `not_visitable`). At the 1,000 AU stand-off
  every α Cen planet is a sub-pixel point anyway.
- **What the eye actually sees at the stand-off.** α Cen A is V −12.2
  (HB-91). A and B are about 1.35° apart (HB-94; the exact value comes from the
  orbit at the arrival epoch). The candidate A b would be about V +8 at 0.11°
  from A (oracle). That is below the eye's V 6.9 limit (M1.5a AC8), so it is
  invisible in EYE mode, honestly. In CAMERA mode with a fixed long exposure
  it can appear as a point. Proxima b is about 0.8″ from Proxima at about
  V +22, and is not visible.
- **Navigation inset** (a labelled readability aid, the pattern of
  design-decision line 599 and M1.5a): a schematic orrery card on the arrival
  card, the same widget as M5.6's system map in view-only mode. It shows each
  body's orbit, status badge, provenance and `last_light` age ("data from
  Earth-based observation, light 4.3 yr old at departure"). The card is
  labelled "schematic, not to scale" and never draws into the sky.
- **Codex entry** "The worlds of α Centauri": what is confirmed, what is a
  candidate, what was retracted and why. It cites check values (new PL-n rows)
  through M4.7's lore-check.

**The start at Earth.** The game begins holding 50,000 km above Earth (Earth
about 13° across, the Moon in the sky). Sunlit Earth (about 2.6 × 10⁴ cd/m² at
normal incidence, oracle) light-adapts the EYE meter, and the stars go out.
That is what astronauts report, and the old Saturn screenshot got it wrong
(stars shown around a lit planet).

### M5.8 Physics gates (gate 2), renders and bench

- **CPU (`tests/test_physics.gd`, `make physics`):** every M5.0 check value
  above, copied from the package probes (not computed in GDScript):
  `apparentDisc` at the three geometries; D at the disc centre; the Lambert
  and Minnaert phase values; the ring single-scattering limits; Jupiter's
  opposition V; Saturn's equinox dates; the retarded lag; the gravity values;
  the point/disc flux ratio at the crossover; finite values for every body at
  every tick of the Sol tour, with no NaN near a body (the sim refuses any
  leg that would enter one).
- **`make lint-precision`** (M4's lint) also covers `planets/` and
  `ui/system_map*`.
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
    covering 25 % of the frame, its centre is below the AgX white point;
    M1.5a's exposure goldens pass unchanged.
  - **G-M5-8, α Cen arrival.** In EYE mode no candidate planet is above the
    display floor, and A and B are separated by the orbit's value at the
    arrival epoch within 0.75 px.
  - **G-M5-9, the pass on screen.** At the Saturn pass of the Sol tour, the
    planet's rendered centre at the sim's pass tick is within 0.75 px of the
    CPU projection of `pass.b_km` through the ship basis.
- **Reference renders (`make capture-m5` → `renders/m5/`):** the Sol tour at
  fixed ticks (the start at Earth in EYE and fixed EV; the Moon stop; the
  Saturn pass at 0.5c before, at and after closest approach, forward,
  sideways and astern; the Jupiter stop with a Galilean moon's shadow); a
  Saturn flyby at β 0, 0.5, 0.9 and 0.99; a ring-shadow close-up; the α Cen
  arrival in EYE and CAMERA mode with the inset; the system map and planning
  panel; and a contact sheet. ⏸ **S-M5: Mark looks at them** before M5.3,
  M5.6 and M5.7 merge. This is the gate-2 "renders you have actually opened".
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
| AC1 | `sunholo/celestial` 0.1.0 is published with tests for every M5.0a row (Kepler residual, opposition dates, satellite periods, ecliptic pole, equinox dates, light-time lag, gravity values, Lambert/Minnaert limits, ring single-scattering limits, Jupiter opposition V); `ailang pkg quality` reports no gates; CHANGELOG and `[release] kind` present; an independent evaluation (not the author) scores it ≥ 70/100 before publish, saved under `.ailang/state/evaluations/` | `ailang test` and `ailang pkg quality` in `packages/celestial` (ailang-packages); `ls .ailang/state/evaluations/eval_R1-M5-PLANETS-M5.0a_*` |
| AC2 | `optics.apparentDisc` is released in `sunholo/relativity` with tests at the three geometries (and `hover_power` if M3 has not released it); quality with no gates | `ailang test` and `ailang pkg quality` in `packages/relativity` |
| AC3 | The sim pins both packages; `sim/ailang.toml`, `sim/ailang.lock` and the bundled runtime cache agree | `make deps test` |
| AC4 | `systemAt` and the in-system planner are pure: `sim/celestial.ail` and the planner pass `--strict-bytecode`; the Sol tour's `system` and `journey` output is byte-identical on the VM and the interpreter (per-architecture goldens until ailang#1465) | `make strict parity-v2` (`solTourRoundTrip`) |
| AC5 | Sim positions equal `stateFromElements` ∘ `eclipticToGalactic` to 1e-12 AU; the retarded lag for Jupiter from Earth at opposition equals the package value within 1e-6 s; outside 3000 BC–3000 AD the sim reports `ephemeris: "mean-orbit"` | `make sim` |
| AC6 | Data provenance: every body row has a citation key; every α Cen body has `status` and per-field provenance; no `retracted` row is loaded; ring radii match the design repo's ring table within 1 % of R (Saturn 1.11–2.27, Jupiter 1.29–1.81, Uranus 1.49–1.95, Neptune 1.69–2.54) | `make sim` (`celestial_test.ail`) |
| AC7 | CPU mirror: `physics/planets.gd` matches every package value in AC1–AC2 within 1e-12 relative (1e-9 for angle outputs in degrees); no hand-computed γ or 1 − β | `make physics lint-precision` |
| AC8 | GPU goldens G-M5-1 to G-M5-9 pass | `make golden` |
| AC9 | Reference renders exist under `renders/m5/` with a contact sheet; Mark's S-M5 approval is recorded in the sprint JSON before M5.3, M5.6 and M5.7 merge | `make capture-m5` and `jq '.milestones[] \| select(.id=="M5.8").review' .ailang/state/sprints/sprint_R1-M5-PLANETS.json` |
| AC10 | Planet textures (2k, about 25 MB) are fetched by sha256 from `gs://stapledons-voyage-assets/planets/` and none is tracked in git; CC BY 4.0 attribution is present in the credits file | `make planet-assets && git ls-files assets/planets \| grep -v -E 'SHA256SUMS\|CREDITS'` (empty output) |
| AC11 | The α Cen inset lists every loaded α Cen body with its badge and provenance; no α Cen planet is drawn as a disc or accepted as a plan target (`not_visitable`) | `make ui` (inset audit) and `make sim` (refusal fixture) |
| AC12 | The codex entry's numbers match their PL-n check values | `make lore-check` (M4.7) |
| AC13 | Bench p99 < 16.7 ms at 2560×1440 | `make bench SCENE=flyby` |
| AC14 | Planning a body: the sim computes the target (client `pos` ignored for `kind: "body"`); stop and flyby plans equal `planBurnCoastBurn` on the computed leg length to 1e-9; short legs fall back to flip-and-burn exactly as M2 does | `make sim` (`navigation_test.ail`) |
| AC15 | Refusals: `collision`, `ring_crossing`, `too_close`, `not_visitable` and `committed` each have a fixture that triggers them and one that just passes | `make sim` |
| AC16 | Gravity: during cruise and holds the ship stays on the planned line or offset to 1e-6 km; the leg's `hold_j` equals the tick sum of `hover_power(m_eff, ‖accelerationAt‖)` dτ to 1e-9 relative; at the start position ‖g‖ equals the package value (0.1254 m/s², oracle) | `make sim` |
| AC17 | Intercept: at the Sol tour's Saturn pass tick, the ship–Saturn distance equals the planned `b_km` within 1 km, and the intercept iteration's residual is < 1e-9 of the leg | `make sim` and `make replay SESSION=sol_tour` |
| AC18 | Replay: the Sol tour's input log (plans, commits, warp `dtau`, including the automatic step-down) replays to byte-identical state; camera input is not in the log | `make replay SESSION=sol_tour` and `make journey-replay` |
| AC19a | Confirm class: the sim sets `confirm = "light"` for a body target with Earth time ≤ `light_confirm_max_earth_s` and `"full"` otherwise, including every star target; boundary fixtures at 86,399 s, 86,400 s and 86,401 s; both dialogs emit the same `commit{plan_id}` intent, and the Sol tour replays with both kinds | `make sim` (confirm fixtures), `make ui` (dialog audit), `make replay SESSION=sol_tour` |
| AC19 | Display audit: every number on the system map, the planning panel and the in-system HUD is a formatted sim field (M4's `DisplayBinding` audit) | `make ui` |
| AC20 | Everything above runs without a GPU except AC8, AC9 and AC13; `make test` is green locally and in CI; no new Python outside `tools/python-allowlist.txt` | `make test` (includes `python-guard`) |

## Sub-milestones and estimates

| # | Scope | LOC (code + tests) | Depends on | Review gate |
|---|---|---|---|---|
| M5.0a | **New package `sunholo/celestial` 0.1.0:** `kepler`, `ephemeris`, `frames`, `lighttime`, `gravity`, `reflect`, `rings`; scaffolding, CHANGELOG, quality, independent eval, publish | 400 + 360 | none | independent package eval |
| M5.0b | `sunholo/relativity`: `optics.apparentDisc` (+ `hover_power` if not yet released) | 40 + 60 | the relativity release after M4.6a | no |
| M5.1 | `sim/data/sol.ail`, `sim/data/acen.ail`, `sim/celestial.ail` (`bodyAt`, `systemAt`), the `system` change set; sim pins both packages | 330 + 220 | M5.0a, M5.0b, M2 protocol | no |
| M5.2 | `system_view.gd`, `planet.gdshader`, `ring.gdshader`, the atmosphere shell, point/disc handoff, `physics/planets.gd`, `make planet-assets` / `planet-publish` | 380 + 140 | M5.1, M1.5a | no |
| M5.3 | Rest-frame tiles + warp pass, D shift via `bb_lut` | 160 + 110 | M5.2 | S-M5 |
| M5.4 | The highlight-protecting meter in `sky/exposure.gd` | 40 + 30 | M1.5a | no (M1.5a goldens guard) |
| M5.5 | **In-system navigation in the sim:** body targets, stop/flyby geometry, intercept, refusals, gravity hold and `hold_j`, holding state, start at Earth, protocol, `solTourRoundTrip`, `sol_tour` replay | 380 + 320 | M5.1, M2 | no |
| M5.6 | **In-system UX:** system map (log toggle), planning panel (stop/flyby, b and clock dial, speed), commit dialog reuse, window view, HUD additions, in-system warp with automatic step-down | 330 + 120 | M5.5; M4.3a HUD/`DisplayBinding` (soft) | S-M5 |
| M5.7 | α Cen arrival + inset + codex entry; the start-at-Earth view | 100 + 50 | M5.3, M5.6 (widget); M1.2d (#69); M4.1 stand-off (soft); M4.7 lore-check (for AC12) | S-M5 |
| M5.8 | Goldens G-M5-1 to G-M5-9, `make capture-m5`, bench, report | 50 + 130 | all of the above | S-M5 |
| **Total** | | **≈2,210 + 1,540 = 3,750** | | |

**Order and parallelism.** M5.0a and M5.0b run in parallel (different
packages). M5.1 follows both. Then two tracks: **render** (M5.2 → M5.3, with
M5.4 at any time) and **navigation** (M5.5 → M5.6). M5.7 and M5.8 join them.
M5.2 can start against a fixture `system` message before M5.1 lands, and M5.6
against fixture plans before M5.5 lands. M5 runs in parallel with M3 and M4;
it touches M4's sky SubViewport (an instanced node), M4's HUD (additions) and
M1.5a's meter.

**If R1 needs a cut**, the natural line is between M5.5–M5.6 and the rest:
without them M5 is the first draft's scope (rendering, flyby as a scripted
scenario, α Cen arrival), about 2,600 LOC. That would contradict Mark's Q1
ruling, so it is listed only as a fallback for his decision.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| In-system navigation pulls in orbital-mechanics gameplay (orbits, assists, insertion) | Non-goal: straight legs held by the drive; stops are holds. The design says why (higgs-bubble property 3) and costs it (`hold_j`) |
| A flyby set up at 0.9c lasts a fraction of a second and the player misses it | Automatic warp step-down to 1× before the pass (logged); the window view; the plan shows "pass lasts N s"; slower cruise is the player's choice |
| Intercept fails to converge for a slow ship chasing a fast moon | The minimum in-system β 0.001 keeps the contraction ≤ 0.17 for planets; moons as targets are checked against their orbital speed (Io 17 km/s), and the residual is asserted (AC17); a non-converging plan is refused, not approximated |
| Tiles at 1/D resolution cost too much astern at 0.99c (14× magnification) | Cap at 4,096² and measure the residual in G-M5-1; tiles only for resolved groups (rarely more than 2 at once); bench AC13 |
| JPL approximate elements plus IAU poles miss Saturn's equinoxes by more than ±10 d | The tolerance is stated in the check; if missed, take the ring-plane pole at the epoch from the IAU model's higher-order terms (data, not code) |
| The highlight meter changes how the M1 sky looks with no planet in view | The P99.5 term is below the log-average for dark skies, so M1.5a's AC8 is unchanged; M1.5a's goldens re-run in `make golden` (G-M5-7) |
| A new package adds release overhead and a second pin | No dependency between celestial and relativity; one lockfile bump moves both; the independent eval is part of the plan, not an afterthought |
| Exoplanet status changes between design and sprint (Proxima d, α Cen A b) | Status comes from the pinned archive snapshot plus cited candidate rows; a data drop updates it; code never hard-codes a status |
| Texture licence: CC BY 4.0 needs attribution | `CREDITS` file checked by AC10; shown in the credits screen |
| Half-float overflow for the Sun | Pre-exposure (already the starfield pattern); the solar luminance is passed to the glare pass as a uniform |
| AILANG gaps (e.g. ailang#1478 pattern constructors, #1465 cross-arch exp/log) | Workarounds per CLAUDE.md, cited at the site; every VM/interpreter disagreement is reported upstream with a minimal repro |
| Scope: 3,750 LOC is large for one R1 milestone | Two independent tracks after M5.1; the fallback cut line is stated above for Mark |

## Open questions for Mark

**Answered (Mark, attended 2026-10-03):**
1. **Is the flyby player-facing in R1?** **ANSWERED — PLAYER-FACING in R1**
   (Mark, attended 2026-10-03). The player flies through the solar system.
   Re-scoped: M5.5 in-system navigation through M2's journey core, M5.6 its
   UX, gravity held off by the drive and costed, the Sol tour replay.
2. **Where is the ship docked at Sol?** **DEFAULT TAKEN — holding 50,000 km
   above Earth** (Mark, attended 2026-10-03; not asked, the default stands).
3. **How are α Cen's uncertain worlds shown?** **ANSWERED — as defaulted**
   (Mark, attended 2026-10-03): physics alone (invisible points at the
   stand-off) plus the labelled inset with status badges; **no "modelled"
   discs**. Consequence: no α Cen planet is a visitable target in R1
   (`not_visitable`).
4. **The metering change in `sky/exposure.gd`.** **DEFAULT TAKEN — the
   highlight-protecting meter, guarded by M1.5a's goldens** (Mark, attended
   2026-10-03; not asked, the default stands). M5.4.
5. **Package home for orbits and reflected light.** **ANSWERED — a new,
   separate package, `sunholo/celestial`** (Mark, attended 2026-10-03);
   relativity stays relativity-only. Package-first rules apply: tests,
   CHANGELOG, quality, an independent eval, then publish. Decided here:
   `optics.apparentDisc` stays in relativity, because it is pure aberration
   optics (M5.0b).
6. **Texture resolution and size budget.** **ANSWERED — 2k Solar System Scope
   (CC BY 4.0), about 25 MB, served from the public bucket** (Mark, attended
   2026-10-03).
7. **The moon list.** **DEFAULT TAKEN — the 11 moons** (Mark, attended
   2026-10-03; not asked, the default stands).

**Questions raised by the re-scope, answered (Mark, attended 2026-10-03,
with the design's approval):**

- **N1. A lighter commit for short in-system legs?** **ANSWERED — YES, a
  lighter confirm for short in-system legs; interstellar journeys keep the
  full commit dialog** (Mark, attended 2026-10-03). Defined in M5.6: the sim
  sets `confirm = "light"` for a body target whose Earth time is ≤ 24 h
  (scenario parameter `light_confirm_max_earth_s` = 86,400), otherwise
  `"full"`. The light confirm is a one-line strip (target, mode, β, both
  times, "No cancel once committed"), one press, no hold. Both emit the same
  logged `commit{plan_id}` and replay identically. AC19a checks it.
- **N2. The in-system speed range.** **ANSWERED — the default, 0.001c–0.99c**
  (Mark, attended 2026-10-03). Lower speeds
  make Earth → Mars take days of ship time, which the warp levels cover.
  Higher speeds, up to the interstellar slider's 0.999999c, cover the boost
  distance (tens of AU) and are pointless inside the system.
- **N3. Can the player stop near a moon, and fly by inside a ring gap
  (Cassini Division)?** **ANSWERED — as proposed** (Mark, attended
  2026-10-03): stops and flybys at all 11 moons; ring
  planes are refused inside the outer ring radius, gaps included, because at
  cruise speed the bubble wall meets ring particles. A slow (≤ 0.001c) gap
  transit is R2 material if Mark wants it.

## Design-repo changes M5 needs

M5 does not edit the design repo. On landing (or earlier, if Mark wants the
spec first), these changes are needed:
1. **`roadmap/r1-foundations.md`:** an M5 section "Planets and flybys" (goal,
   items M5.0–M5.7, acceptance as above, including player-facing in-system
   travel) and a D-26 line under "Decisions"; the M4 item-3 text gains "the
   system's worlds are shown with their status (M5)"; the M2 section notes
   that bodies are journey targets from M5.
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
   approximation statement, the in-system navigation physics (intercept,
   gravity held by the drive and its cost), the α Cen honesty rules, and check
   values **PL-1…** (Jupiter's opposition V, Saturn's equinox dates,
   E☉(1 AU), the ring radii, the Jupiter light-time lag, g at 50,000 km above
   Earth, the hold power there, the α Cen AB separation at the arrival epoch).
   The `sunholo/celestial` package cites it the way relativity cites the
   relativity spec.
4. **`physics/higgs-bubble.md`:** a note under property 3 that holding a
   straight line or a station against planetary gravity uses the same unfelt
   acceleration as hovering, costed by `hover_power` (HB-90's formula).
5. **`features/future/planetary-rings.md`, `planet-rendering-polish.md`,
   `features/ailang-planet-ring-moon-data.md`,
   `features/phase1-data-models/planet-data-migration.md`:** a status line
   "Superseded by the M5 design (stapledons-godot)", noting the corrections
   (moon distances, "Fresnel = Rayleigh", ring shadows now in scope).
6. **`lore/archive/`:** entries "The worlds of α Centauri", "Saturn's rings"
   and "Holding a line near a planet" with `checks:` front matter citing PL-n
   and RS-n.
7. **`vision/design-decisions.md`:** record D-26 and Mark's answers above.

## Deliverables

- **Packages:** `sunholo/celestial` 0.1.0 (`kepler`, `ephemeris`, `frames`,
  `lighttime`, `gravity`, `reflect`, `rings`, tests, CHANGELOG, independent
  eval); `sunholo/relativity` `optics.apparentDisc` (+ `hover_power` if
  needed).
- **Sim:** `sim/celestial.ail`, `sim/data/sol.ail`, `sim/data/acen.ail`,
  `sim/celestial_test.ail`, `sim/navigation_test.ail`, the body-target planner
  and holding state in `sim/core.ail`, the `system` change set and the new
  plan fields in `sim/protocol.ail` and `sim/ship.ail`, `solTourRoundTrip`,
  the `sol_tour` replay session.
- **Godot:** `planets/system_view.gd`, `planets/planet.gdshader`,
  `planets/ring.gdshader`, `planets/atmosphere.gdshader`,
  `planets/flyby_warp.gdshader`, `physics/planets.gd`, `ui/system_map.tscn`
  and the planning panel, the window view, HUD additions, in-system warp, the
  arrival inset card, the metering change in `sky/exposure.gd`.
- **Data and tools:** `data/planets/SHA256SUMS`, `CREDITS`,
  `make planet-assets`, `make planet-publish`, `make capture-m5`, the α Cen
  exoplanet snapshot pin.
- **Tests:** `tests/test_physics.gd` additions, goldens G-M5-1 to G-M5-9,
  `renders/m5/`.
- **Docs:** `design_docs/implemented/r1/m5-report.md` on landing; changelog
  entry; the design-repo changes above (made by the landing step, not by
  this doc).

## Verification log

| # | Claim | Command | Result |
|---|---|---|---|
| V1 | No planet or body code in the rebuild; M1 and M4 defer planets and Terrell | `git ls-files \| grep -i -E 'planet\|orbit\|celestial'` at `7ac4778`; `sed -n 101p design_docs/planned/r1/m1-relativistic-sky.md`; `sed -n 122p design_docs/planned/r1/m4-first-journey.md` | Only `.claude/skills/starmap-manager/scripts/download_exoplanets.sh` (a download script, unused by the game); "Planets and nearby 3D objects, including Terrell rotation (M4 or later)"; "planets; Terrell rotation" in M4's non-goals |
| V2 | M4's arrival scene is two stars at a 1,000 AU stand-off | `grep -n "overhead or" design_docs/planned/r1/m4-first-journey.md`; `grep -n "HB-9[1-4]" ../stapledons-design/physics/higgs-bubble.md` | "α Cen A and B are overhead or beside the dome"; HB-91 −12.2 mag, HB-92 0.64°, HB-93 2.04°, HB-94 1.35° |
| V3 | No package has orbit or reflected-light functions | `ls ~/.ailang/cache/registry/sunholo/relativity/0.5.2/*.ail`; `grep '^export' …/optics.ail …/photometry.ail`; `ls ~/.ailang/cache/registry/sunholo/` | Relativity modules: optics, photometry, blackbody_photometry, schwarzschild, kinematics, journey, medium, hyper; `illuminanceFromV`, `dopplerApparent`, `deaberrate` exist; nothing for Kepler, albedo or phase; no `celestial` package in the registry cache |
| V4 | The spec's nearby-object row says "aberrate every vertex" and its circle check has no ID | `grep -n "3D objects nearby" ../stapledons-design/physics/relativity-spec.md` | "Aberrate every vertex … (Terrell–Penrose rotation) \| Sphere stays circular in outline"; RS-1…RS-23 contain no disc value |
| V5 | M1.5a scene units, metering and pre-exposure | `sed -n 1,60p sky/exposure.gd`; `grep -n exposure sky/starfield.gdshader` | lux / cd/m², EYE = max(EV_dark, EV_meter), log-average CAMERA meter K = 12.5; the starfield multiplies by an `exposure` uniform (1/L_white) |
| V6 | The Go build: Saturn screenshot, SR shader defects, data errors, texture licence | Read-only survey at `930eca1` (bounded finds, maxdepth ≤ 3); `ls -la docs/images out/screenshots` | As in [§Old build](#the-retired-go-build-what-to-keep-what-was-wrong); `out/screenshots/` contains only `.gitkeep` |
| V7 | Oracle numbers (apparent disc, D, Jupiter V, Saturn and Earth luminance, light-time, deflection, gravity, α Cen visibility) | Throwaway Python in the session scratchpad (not committed; an oracle only) | As quoted. Each becomes a package value in M5.0 |
| V8 | D-26 ruling and queue row 6c; D-27 glare (row 6b) | `git show origin/docs/d26-planets-glare:design_docs/stapledon-mission.md \| grep -n -E 'D-26\|D-27\|6c\|6b'` | D-26 RESOLVED (attended 2026-10-03), row 6c ~2,000 LOC; D-27 glare and auto-dimming glazing, row 6b |
| V9 | M2's plan target is a star with a client-supplied position; the planner falls back to flip-and-burn on short legs | `sed -n 73,74p sim/core.ail`; `sed -n 184,192p sim/protocol.ail`; `sed -n 71,79p ~/.ailang/cache/registry/sunholo/relativity/0.5.2/journey.ail` | `Target = { index: int, id: string, pos: Vec3 }`; `targetOf` reads `pos` from the intent; `if not (2.0 * dBurn < distance) then { planFlipAndBurn(distance, a) \| fellBack: true }` |
