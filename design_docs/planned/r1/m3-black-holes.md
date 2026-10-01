# M3: Black holes (GR foundation)

**Status:** Planned (design, awaiting sprint plan)
**Release:** r1 · **Milestone:** M3 of [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) (queue row 4, bar clause 3)
**Priority:** P1. New Game+ begins at a black hole, and this is where the hard-SF promise is most visible. It does not block M2 or M4.
**Implements:**
- [relativity spec §3](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) (Schwarzschild: the table, the three-step Method, the check values) and §4 (test requirements: CPU reference, GPU golden within 0.75 px, renders at 10, 5 and 3 r_s).
- Spec §5 audit rows 6, 7 and 8: the Go version drew the shadow at r_s, lensed by a UV shift with opposite CPU/GPU signs, and took redshift from screen distance. None of that code is ported.
- [gr-visual-mechanics](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/gr-visual-mechanics.md): lensing, gravitational blueshift and the time-dilation HUD only. Its "full ray tracing is a non-goal / approximations that look right" line is superseded by spec §3. Danger zones, tidal stress and neutron stars are out of scope.
- [black-holes](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/black-holes.md) §"Time Dilation Formula" and [black-hole-mechanics](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/black-hole-mechanics.md) §"Near-BH Time Skip": the sim computes the clock rate. Crew psychology, the time-skip choice and New Game+ are not in M3.
- [open-questions](https://github.com/sunholo-data/stapledons-design/blob/main/vision/open-questions.md) "How should GR lensing near black holes interact with SR effects?" M3 answers it with physics rather than a style choice: SR is applied in the local static frame, then the GR lens map (Option 2, "unified", in one shader pass).

**Depends on:** `sunholo/relativity@0.3.0` (published). M1.6b (free camera and the off-axis golden harness) and M1.4c (the Milky Way sky shader, `sky/background.gdshader`, landed 2026-10-01 in PR #16) are needed only for parts of M3.5 and M3.6. See [What can start now](#what-can-start-now).
**Estimated:** ~2,600 LOC (≈1,450 code + 1,150 tests and tools), 6 sub-milestones. The mission queue's ~1,800 was a guess made before the finite-observer lens map, the ring-star path and the sim GR mode were scoped.
**Evidence:** every codebase claim has a row in the [Verification log](#verification-log), pinned to `e9d35c5`. Every number quoted below comes from the prototype run in row V9, which uses two independent methods that agree to 3 × 10⁻¹³.

## Game vision alignment

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | 0 | 0 | M3 has no choices. The time-skip choice near the hole comes later; M3 supplies its numbers |
| The Game Doesn't Judge | 0 | 0 | |
| Time Has Emotional Weight | + | +1 | The HUD shows the sim's √(1 − r_s/r): at 3 r_s, a ship-year is 1.2247 years at home. That is the first time-skip lever |
| The Ship Is Home | 0 | 0 | No interior yet. The windows (M4) will show this sky |
| Grounded Strangeness | ++ | +2 | The shadow is 2.6 r_s, not r_s. Einstein rings and a photon ring appear. At 3 r_s the shadow spans 90° of sky: strange, and exactly right |
| We Are Not Built For This | + | +1 | The HUD states honestly that hovering at 3 r_s of a 10 M☉ hole needs ~2 × 10¹⁰ g (the bubble, not the drive) |
| Hard sci-fi authenticity (spec) | ++ | +2 | Exact null geodesics, a normative spec, closed-form check values, and two independent integrators |
| **Net** | | **+6** | **Go** |

## Problem

1. **No GR exists in the rebuild.** `grep` for Schwarzschild, lens or geodesic code finds nothing in `physics/`, `sky/`, `tests/`, `main.gd`, `sim/` or `bridge/` (row V1). The only GR anywhere is the package's closed forms.
2. **The package has closed forms but no geodesics.** `sunholo/relativity@0.3.0` `schwarzschild.ail` exports seven functions: `pi`, `photonSphere`, `criticalImpact`, `shadowAngularRadius` (Synge), `weakDeflection` (2/b), `staticObserverBlueshift` and `staticClockRate`. They are tested by check36–check40 (`relativity_test.ail:247–277`). Nothing integrates d²u/dφ², and bar clause 3 requires that "the geodesic integrator ships in `sunholo/relativity`" (row V2).
3. **The spec's weak-field check value cannot be met as written.** Spec §3, roadmap M3 and bar clause 3 all say "Δφ matches 2r_s/b to 1% at b = 100 r_s". The exact deflection at b = 100 r_s is **0.0202999662395 rad, which is 1.500% above 2/b = 0.02**. The second-order term (15π/16)(r_s/b)² is exactly that size. Both integrators agree to 1.7 × 10⁻¹³ (row V9). No correct implementation can pass the literal check. This is open question 1.
4. **The spec's Method step 1 assumes an observer at infinity.** "Store Δφ(b) in a 1D texture" is exact only for a distant observer. A ship hovering at 3 r_s sees a sky that also depends on r: the Einstein-ring angle for a source directly behind the hole is 61.889° at 3 r_s, but 29.828° at 10 r_s and 2.604° at 1000 r_s (row V9). M3 needs a 2D (ψ, r) table. The 1D Δφ(b) table is its r → ∞ limit, and that is what the weak-field check measures. This is open question 2.
5. **The renderer has no GR hook.** The star shader aberrates in its vertex stage (`sky/starfield.gdshader:26–44`) and projects one image per star (`:52–67`). The golden harness checks only SR star centroids (`main.gd:173–215`) with `HEADING` fixed (`main.gd:11`). `make capture` photographs only speeds 0–0.99c (`main.gd:139`). There is no per-pixel sky in `main`: the background is `BG_COLOR` black (`main.gd:52–53`). The per-pixel panorama shader exists only on the M1.4a spike branch (`spike/panorama_sky.gdshader`, row V5).
6. **A design-repo time-dilation table is wrong.** `black-hole-mechanics.md:82` gives "1.5 rs | 2x". The correct value is 1/√(1 − 1/1.5) = √3 = 1.732×, which `black-holes.md` gets right. M3's sim value is the authority. The landing commit fixes the table in the design repo (row V7).

## Goals and non-goals

**Goals**
- **G1.** Null geodesics in `sunholo/relativity` (the next free minor, planned as **0.5.0**). This includes a Binet RK4 integrator from a finite static observer and an independent closed-form oracle (Darwin's elliptic form via Carlson R_F), with tests, `pkg quality` passing with no gates, and a publish.
- **G2.** An offline, deterministic deflection lookup table generated by the strict VM. It is finite across its whole range, handles the near-critical band, and comes with a test.
- **G3.** A per-pixel lensed background. Per star, primary and secondary images with magnification. Stars near alignment draw as true Einstein rings. The shadow edge comes from b_c analytically, not from the table.
- **G4.** SR composed in the local static frame: hover or orbit velocity applied as aberration and Doppler, times the static observer's blueshift 1/√(1 − r_s/r).
- **G5.** A sim GR mode (approach, hover, orbit) whose state carries √(1 − r_s/r), computed in AILANG and shown on the HUD.
- **G6.** CPU check values, GPU golden cases, and reference renders at 10, 5 and 3 r_s that a person has opened.

**Non-goals**
- Kerr (spin), charge, accretion disks (spec §3 "later" row), jets, and neutron stars or white dwarfs as lenses.
- Observers inside r = 2 r_s, including the photon sphere and near-horizon dives. See open question 3.
- The black hole's own motion through the galaxy: in M3 the hole is at rest in the galaxy frame.
- Free fall and geodesic motion of the ship. The approach is kinematic, at a commanded local speed.
- Images of order ≥ 2 as separate splats. They lie within 0.1 px of the shadow edge at 10 r_s (14.2831° against 14.2690°, row V9). They appear as the photon ring through the per-pixel pass.
- Time-skip gameplay, crew reactions, New Game+.

## Design

**Conventions** (spec §1 plus the package's). Radii and impact parameters are in units of r_s = 1, and angles are in radians. ĥ is the unit vector from the observer **toward the hole**. ψ is a ray's angle from ĥ, measured in the static observer's orthonormal frame. The ray's impact parameter is b = r sin ψ / √(1 − 1/r). The shadow half-angle α_sh(r) comes from Synge's formula (existing `shadowAngularRadius`).

### M3.1 Geodesics in `sunholo/relativity` 0.5.0 (package first)

**Version.** 0.3.0 is the WD photometry release, and 0.4.0 is earmarked for M1.2d's `teffFromBV` (M1 doc §M1.2d; mission queue row 1). M3 therefore takes **the next free minor at publish time, planned 0.5.0**. M2.0's journey functions also target "the next minor after 0.4.0": whichever of M2.0 and M3.1 publishes first takes 0.5.0 and the other takes 0.6.0. Below, `$V` is the version M3.1 actually publishes, and `0.5.0` in the text means `$V`. If M1.2d has not published 0.4.0 by then, M3 still publishes 0.5.0 and leaves 0.4.0 to `teffFromBV`, so that the earmark in two docs stays true. The mission log records this. Queue row 4's "0.3 (Binet integrator)" is stale, and the landing record updates it.

**`schwarzschild` additions (closed forms; each has `requires`/`ensures` where Z3 can prove them):**

```
impactFromStaticAngle(r, psi) -> float     -- r sin(psi) / sqrt(1 - 1/r)
turningRadius(b) -> float                  -- (2b/sqrt3) cos(acos(-3sqrt3/(2b))/3), requires b > b_c
weakDeflection2(b) -> float                -- 2/b + 15pi/(16 b^2)  (second-order series)
weakDeflectionFinite(r, psi) -> float      -- (1 + cos psi)/b, first order, finite observer, source at infinity
strongDeflectionBbar() -> float            -- ln(216(7 - 4sqrt3)) - pi = -0.400230039755 (Bozza 2002)
circularOrbitSpeed(r) -> float             -- local speed seen by static observers: sqrt(1/(2(r-1))), requires r > 1.5
circularOrbitClockRate(r) -> float         -- sqrt(1 - 1.5/r), requires r > 1.5
orbitalAngularVelocity(r) -> float         -- dphi/dt = sqrt(1/(2 r^3)), in c/r_s
movingClockRate(r, betaLocal) -> float     -- sqrt(1 - 1/r) sqrt(1 - beta^2)
radialCoordinateRate(r, betaLocal) -> float -- dr/dt = betaLocal (1 - 1/r)
hoverAcceleration(r) -> float              -- 1/(2 r^2 sqrt(1 - 1/r)), in c^2/r_s
rsPerSolarMassMetres() -> float            -- 2 GM_sun / c^2 = 2953.25008 (IAU 2015 nominal GM_sun)
```

**New module `sunholo/relativity/geodesic`:**

```
export type Ray = { escaped: bool, dphi: float }   -- dphi: azimuth swept from the observer to infinity
binetStep(u, v, h) -> {u, v}                 -- one RK4 step of u'' = -u + (3/2)u^2 (spec §3, r_s = 1)
escapeAzimuth(r, psi, h) -> Ray              -- THE integrator: start at u = 1/r, u' = +-sqrt(1/b^2 - u^2 + u^3)
                                             --   (+ ingoing, psi < pi/2), step until u <= 0 (escape, cubic-Hermite
                                             --   root on the last step) or u >= 1 (captured)
lensDeflection(r, psi, h) -> float           -- delta = dphi - (pi - psi); requires the ray to escape
deflectionFromInfinity(b, h) -> float        -- observer at infinity: alpha(b), the spec's Delta-phi(b)
carlsonRF(x, y, z) -> float                  -- duplication algorithm, fixed iteration cap, no tolerance loop on NaN
deflectionExact(b) -> float                  -- oracle: Darwin's elliptic form, 2 I(0, u0) - pi, via carlsonRF
escapeAzimuthExact(r, psi) -> Ray            -- oracle: 2I(0,u0) - I(0,1/r) (ingoing), I(0,1/r) (outgoing, Carlson when
                                             --   three real roots, else 64-point Gauss-Legendre: no singularity there)
lensRegular(r, psi, h) -> float              -- delta + ln(tanh((psi - alpha_sh)/alpha_sh)): the quantity the table stores
imageAngle(r, beta, order) -> float          -- solve psi - delta(psi) = beta (order 0) or -beta (order 1); bisection
einsteinAngle(r) -> float                    -- imageAngle(r, 0, 0)
imageMagnification(r, psi) -> float          -- (sin psi / |sin F|) |dpsi/dF|, F = psi - delta, central difference
```

**Capture is decided analytically. The integrator never decides it.** A ray escapes iff it is outgoing, or it is ingoing with b > b_c (for r ≥ 2, which is the M3 domain). `escapeAzimuth` asserts that the integration agrees. A disagreement is a test failure, not a fallback.

**Why both methods ship.** The Binet ODE has no singularity at the turning point. A quadrature of du/√P(u) does, so the integrator is the robust general method, and it is the one the spec and bar clause 3 name. The elliptic form is exact and about 50× cheaper. It is the oracle that pins the integrator. Measured in Python (row V9) with h = 10⁻³, the two agree to 3 × 10⁻¹³ away from b_c, and to 2.7 × 10⁻⁹ at b/b_c − 1 = 10⁻⁶. The table uses **h = 0.005**, which gives a worst case of 5.3 × 10⁻⁷ rad over the probe set (row V10). That is 1/400 of the 1.2 × 10⁻⁴ rad table budget.

**Implementation rules** (carried over from WD-2, all measured on v0.47.2): no nested cons patterns; recursion carries state as arguments; `c == c` guards come before any comparison that could see NaN; test blocks call named `checkNN()` functions. The step loop is tail-recursive. A 400-ray prototype ran on `--strict-bytecode` (row V11).

**Tests** (`geodesic_test.ail`, written first; the values come from row V9):

| Check | Assertion | Kills |
|---|---|---|
| `check41` | `deflectionExact(100)` = 0.0202999662395031 (±1e-12); `deflectionFromInfinity(100, 0.001)` within 1e-11 of it | wrong roots, a wrong R_F argument order, an RK4 coefficient |
| `check42` | `deflectionExact(1000)` = 0.00200295058718769; ratio to `weakDeflection(1000)` − 1 = 0.0014753 (±1e-6) | a first-order-only implementation |
| `check43` | At b = 100: \|exact/`weakDeflection2` − 1\| ≤ 3e-4 (measured 2.68e-4) | a second-order series typo |
| `check44` | Near-critical: at b = b_c(1+ε) for ε = 1e-4, 1e-6, 1e-8, exact = 8.8104863550, 13.4152855579, 18.0204507723 (±1e-9); within 4e-4, 6e-6, 1e-7 of −ln ε + b̄ | log-divergence handling, b̄ |
| `check45` | `escapeAzimuth` vs `escapeAzimuthExact` at (r, ψ) = (10, 0.5), (3, 1.0), (5, 2.0), (10, 0.26): \|Δ\| ≤ 1e-9 at h = 0.001, ≤ 1e-5 at h = 0.005 near the edge | ingoing/outgoing sign, the end-root interpolation |
| `check46` | `einsteinAngle` at r = 10, 5, 3, 100, 1000 = 29.828317906°, 44.874561077°, 61.888756430°, 8.520443413°, 2.604361342° (±1e-7 rad) | the finite-observer geometry (an infinity-only table gives 25.6° at r = 10) |
| `check47` | Images: r = 10, β = 20°: 39.837659068° / 23.543122070°, μ = 1.118821 / 0.276451; r = 1000, β = 1°: 3.144406661° / 2.160968686°, μ = 1.847367 / 0.856138 (positions ±1e-7 rad, μ ±1e-4 relative) | image order, parity, magnification |
| `check48` | Capture rule: ingoing b < b_c → `escaped = false`; outgoing at r = 3 → `true`; agrees with the integrator on a 200-ray sweep across the edge | analytic/integrator disagreement |
| `check49` | Clock and orbit forms at r = 10, 5, 3: `staticClockRate` 0.948683298050514, 0.894427190999916, 0.816496580927726; `circularOrbitSpeed` 0.235702260395516, 0.353553390593274, 0.5; `circularOrbitClockRate` 0.921954445729289, 0.836660026534076, 0.707106781186548; identity movingClockRate(r, circularOrbitSpeed r) = circularOrbitClockRate r (±1e-15) | orbit-speed frame confusion |
| `check50` | `lensRegular` is finite at ψ − α_sh = 1e-8 α_sh and at ψ = π − 1e-12 for r ∈ {2, 3, 10, 10⁶} | a singular-part mismatch, the spec's finite-table rule |

**Smoke and parity.** `_smoke.ail` gains `export pure func lensDigest(n: int) -> float` = Σ over an n × n (r, ψ) grid of `lensRegular` + `einsteinAngle(10)`. The strict VM and the interpreter must agree bit for bit (`cmp`), and both must be within 1e-9 of the Python reference (AC-3). **Release:** `[release] kind = "feature"`, add the module to `[exports]`, `CHANGELOG ## 0.5.0` (methods, oracle, accuracy, the 1.5 % weak-field fact), `AGENT.md` (use `escapeAzimuth` for tools and the exact form for checks; neither belongs in a per-frame loop), `pkg quality` passing with no gates, a dry run, then publish under the standing grant.

### M3.2 The deflection table (offline, strict VM, committed)

**Two tables, one header.** `sim/tools/lens_lut.ail` (AILANG, pure, `--strict-bytecode`) calls the package and prints `%.17g` rows. `tools/pack_lens_lut.py` only packs them: little-endian float32, a JSON header with layout, ranges, package version, the generator's h and a sha256, written to `data/lens/lens_fwd.bin` and `lens_inv.bin`. Python does no physics, as in M1.2.

| Table | Size | Column coordinate | Row coordinate | Channels |
|---|---|---|---|---|
| `lens_fwd` (per-pixel sky) | 2048 × 256 | x = ln((ψ − α_sh)/α_sh), uniform on [ln 10⁻⁸, ln((π − α_sh)/α_sh)] | y = ln(r − 1.5), uniform on [ln 0.5, ln(10⁶ − 1.5)] | R: `lensRegular`; G: dδ/dx (for mip selection) |
| `lens_inv` (star images) | 2048 × 256 | F = ψ − δ, uniform on [−π, π] (orders 0 and 1) | same as above | R: ψ − α_sh; G: dψ/dF |

- **Near-critical handling (spec: "dense near b_c").** δ diverges like −ln(b/b_c − 1) at the shadow edge. The table stores the *regular part*, δ + ln tanh(Δψ/α_sh), which is finite at both ends (`check50`). The shader adds the singular part back analytically. The column coordinate is logarithmic in Δψ/α_sh, so 2048 columns span 10⁻⁸ to the antipode at every r. Below the first column, the singular term carries the divergence exactly and the regular part is clamped. Δψ is formed in float32 as `atan2(|ĥ × n|, ĥ·n) − α_sh`, where α_sh is a float64 uniform. That makes Δψ good to about 10⁻⁷ rad, which is enough for order-1 images (b/b_c − 1 ≈ 2 × 10⁻³).
- **Why these coordinates (row V10).** Measured with bilinear interpolation on the exact function: 1024 × 64 rows in ln r gives 1.3 × 10⁻³ rad (2.5 px). 2048 × 256 rows in ln(r − 1.5), with the α_sh-scaled column, gives **1.0 × 10⁻⁴ rad (0.2 px at the golden scale)**. This is at the budget, so the shader uses bicubic (Catmull-Rom) interpolation in y, and M3.2's accuracy test (AC-5) decides. If AC-5 fails, the fallback is 4096 columns. Interpolation error is common to the CPU mirror and the GPU, so it never shows in the golden comparison. It is bounded only by AC-5.
- **Beyond the table.** For r > 10⁶ r_s, δ = `weakDeflectionFinite` (θ_E ≤ 0.08°). At r = 10⁶ the series and the table agree to 10⁻³ relative, so the hand-off is seamless (AC-5). For r < 2 the sim refuses (`bad_radius`).
- **Inverse table.** It is built in the package by monotone (Fritsch–Carlson) inversion of a 16k-sample forward row. F(ψ) is strictly increasing on (α_sh, π], and the test asserts that per row. Orders 0 and 1 use F = +β and −β.
- **Cost (row V11).** On the strict VM, 400 rays take 0.30 s against 37.7 s on the interpreter, with bit-identical output. That is ~0.6 µs per RK4 step. The full forward table (524k rays) is estimated at **~7 min on the strict VM** and ~15 h on the interpreter. So: `make lens-lut` regenerates everything (manual, recorded in the report). `make lens-lut-check` (in `make test`) regenerates every 64th column of every 32nd row on the strict VM and compares it to the committed binary bit for bit. It also runs row 128, columns 0–63, on both engines and compares them with `cmp`. That is the M3 VM stress test; divergences go upstream. **Fallback** if the full run exceeds 60 min on the VM: generate with `escapeAzimuthExact` and keep `make lens-lut-check` on the integrator (open question 2).
- **Finite-range test (CLAUDE.md precision rule).** `tests/test_physics.gd` loads both binaries and asserts that every texel is finite, that F is strictly monotone in every row of `lens_inv`, and that the header sha256 matches.

### M3.3 CPU reference `physics/schwarzschild.gd`

`class_name Schwarzschild`, float64 scalars throughout. It mirrors the package and **is never the only copy**:
- `shadow_angle(r)` (Synge), `static_blueshift(r)`, for tests only. The HUD never calls them.
- `load_tables()`, plus `deflection(r, psi)`: bilinear in x, Catmull-Rom in y, regular part plus the analytic singular part, and the weak branch beyond 10⁶. This is the same arithmetic as the shader, including the float32 texel values.
- `lens_direction(n_static, h, r) -> Dictionary {captured, n_inf}`: the map for the per-pixel sky. n_∞ = cos(ψ − δ) ĥ + sin(ψ − δ) ê⊥, with ê⊥ = normalize(n − (n·ĥ)ĥ). This holds for any δ, including multiple windings.
- `star_images(n_src, h, r) -> Array[{dir_static, mu, order}]`: the inverse map for stars. β = ∠(n_src, ĥ). Order 0 uses ê⊥ and order 1 uses −ê⊥.
- `compose(n_ship_view, h, r, bh, b) -> {captured, n_inf, D}`: the full pipeline in [M3.5](#m35-gpu-lensed-sky-star-images-sr-composition).

New `tests/test_physics.gd` section, "Schwarzschild (spec §3)". It covers the closed forms at r = 10, 5, 3 (shadow 14.269027328°, 27.694561451°, 45° exactly; blueshift 1.05409255338946, 1.11803398874989, 1.22474487139159), and the mirror against package-pinned values from M3.1's tests (δ, Einstein angles, images, μ, within 1.2 × 10⁻⁴ rad and 1 % in μ). It checks weak-field values on the r → ∞ column (open question 1), the table finite and monotone tests, and a round trip: for 1,000 deterministic (r, β) pairs, lens_direction(star_images(n)) returns n within 2 × 10⁻⁴ rad.

### M3.4 Sim GR mode (pure core, additive protocol)

**Core (`sim/core.ail`, pure, strict VM).** The ship record gains `gr: GrState = { active: bool, mass: float (M☉), r: float (r_s), mode: string, betaLocal: float, phase: float, holeDir: Vec3 }`. Steps stay **ship-proper-time driven**, as everywhere else in the sim. For a step of dτ years, with t_s = r_s/c in years from `rsPerSolarMassMetres`, the coordinate time is dt = dτ / rate, where:
- hover: rate = `staticClockRate(r)`;
- orbit: rate = `circularOrbitClockRate(r)`, and the phase advances by `orbitalAngularVelocity(r)`·dt/t_s;
- approach: rate = `movingClockRate(r, β)`, and r advances by RK4 on `radialCoordinateRate`, stopping exactly at the target radius.

`motion.tau` and `motion.t` accumulate dτ and dt, so home time keeps its meaning. Closed form for `make strict`: at constant β, t(r₁ → r₂) = [r₁ − r₂ + ln((r₁ − 1)/(r₂ − 1))]/β (in t_s). A new strict entry, `scriptedApproach(n)`, must match it within 1e-9.

**Protocol (additive to v1.1, `std/json`, the same reason-code discipline).** New commands: `{"cmd":"bh_enter","mass":9.62,"r":1e6,"hole":{x,y,z}}`, `bh_approach {to_r, beta_local}`, `bh_hover`, `bh_orbit` and `bh_leave`. New reason codes: `bad_radius` (r < 2 or r > 10⁶, open question 3), `bad_gr` (malformed), `not_in_gr`, `moving` (enter or leave while β ≥ 1e-9, as for turns). While GR mode is active, every state line gains:

```
"gr": {"r": 10.0, "mode": "hover", "static_clock": 0.948683298050514, "ship_clock": 0.948683298050514,
       "blueshift": 1.05409255338946, "shadow": 0.249041507929, "beta_local": 0.0,
       "dir_local": {x,y,z}, "hole_dir": {x,y,z}, "hover_accel_g": 2.19e10, "orbit_stable": true}
```

`static_clock` is √(1 − r_s/r), **computed by the sim** (`staticClockRate`). `ship_clock` includes the local motion. `orbit_stable` is r ≥ 3 (the ISCO); orbits between 2 and 3 r_s are allowed and flagged. The v1.0 and v1.1 fields are unchanged, and `make parity` and `parity-offaxis` keep their inputs. A new fixture, `tests/fixtures/gr.ndjson`, covers every command and every reject. `make parity-gr` must be byte-identical between the VM and the interpreter.

**M2 coordination.** M2 rewrites the protocol (versioned handshake, `input`/`state`). Whichever of M2 and M3.4 lands second folds the GR commands into the other's framing **with the same field names**, so the GR fields are the stable contract. If M2's protocol has landed when M3.4 starts, M3.4 is written against it directly.

### M3.5 GPU: lensed sky, star images, SR composition

**Shared include `sky/schwarzschild.gdshaderinc`.** It mirrors M3.3 function for function and is included by both shaders. M1.3 rewrites `starfield.gdshader`, so M3's change to that file is a single `#include` and an `image_order` branch. That keeps the merge conflict small.

**The per-pixel pipeline (`sky/lensed_sky.gdshader`, `shader_type sky`), for view direction n′ in the ship frame:**
1. **SR, static → ship.** n_s = deaberrate(n′, β̂_loc, β_loc), and D_SR = 1/(γ(1 − β n′·β̂)) (existing `optics` forms; spec §2). β_loc is the ship's velocity *relative to the local static observer* (0 when hovering, tangential `circularOrbitSpeed` in orbit, radial in approach). γ and 1 − β come from the sim, never `1.0 - beta` (CLAUDE.md).
2. **Capture.** If ψ = ∠(n_s, ĥ) < α_sh, the pixel is black (exact Synge; no table).
3. **Lens.** δ = table(ψ, r) + singular part, giving n_∞ in the galaxy frame (the hole is at rest).
4. **Sample.** The M1.4c sky at n_∞ uses `textureGrad`, with derivatives from dδ/dx so the photon ring does not sparkle. Until M1.4c lands, a procedural **debug grid sky** is used instead: lat/long lines every 10°, analytic anti-aliasing, constant surface brightness. That is the classic lensing visual and the golden background.
5. **Frequency and brightness.** D = D_g · D_SR, with D_g = `blueshift` from the sim state. Extended radiance is Y(D·T)/Y(T) times the texel radiance. Surface brightness is conserved, so no μ appears here (spec §3 row "Observer gravitational shift"; spec §2 "Colour"). The colour is rgb(D·T) from the existing LUT. Under high D, M1's obligation O-1 (`LUT_T_MAX` ≥ 4.5 × 10⁶ K) applies here too.

**Stars (`starfield.gdshader` + include).** A second `MultiMeshInstance3D` shares the same multimesh with `image_order = 1`. Per instance:
- β = ∠(n_src, ĥ); ψ_k from `lens_inv`; the static direction n_s,k;
- aberrate to the ship frame (step 1, run forwards), D_SR,k = γ(1 + β n_s,k·β̂);
- flux factor μ_k · Y(D_k T)/Y(T) / D_SR,k², with D_k = D_g·D_SR,k. In the limit μ = 1, D_g = 1, this reduces to M1's `point_flux_ratio` exactly, and that limit is a CPU test.

**Ring stars (near alignment).** A point splat cannot draw an arc. When the tangential stretch sin ψ / |sin F| of either image exceeds **8**, which happens near β → 0 (the Einstein ring) and β → π (the order-1 ring of a star directly astern), the star leaves the splat path. It goes to a uniform array of up to **64 ring stars** in the per-pixel pass. There each star is a Gaussian of the PSF's angular size *in the source plane*, evaluated at n_∞(pixel). Lensing then draws the arcs and rings itself. Above 64, the brightest 64 are kept, the rest are drawn as splats with μ capped at 8, and the overflow count goes into the HUD's debug line (finite, never silent).

**Golden cases (`main.gd`, `--golden=gr`, which `make golden` runs after the SR set).** The viewport is 960 × 540, glow is off, and the tonemapper is linear, as in M1 AC6. With vertical FOV 70°, f = 385.600 px.

| # | Case | Expected (CPU reference) | Tolerance |
|---|---|---|---|
| GR1 | Hover at r = 10, looking at the hole, uniform sky: shadow radius from the black-pixel count, √(N/π) | f·tan α_sh = 98.066 px | 0.5 px |
| GR2 | Hover at r = 5 | 202.398 px | 0.5 px |
| GR3 | Hover at r = 3, FOV 110° (f = 189.056) | 189.056 px | 0.5 px |
| GR4 | Orbit at r = 5 (β_loc = 0.35355, tangential): the aberrated shadow mask, compared per pixel with `Schwarzschild.compose` | mismatches only in the 1-px edge band; mask centroid | 0.5 px |
| GR5 | Synthetic star at β = 20° / 60° / 120° from ĥ at r = 10 / 5 / 3: centroids of both images | `star_images` + projection | 0.75 px each |
| GR6 | Star exactly behind the hole at r = 10, 100, 1000 (ring-star path): flux-weighted mean ring radius | 221.088 / 57.769 / 17.539 px (ψ_E) | 0.5 px |
| GR7 | Pixels inside the shadow, with a bright sky and a star directly behind | peak luminance | < 0.01 |
| GR8 | Hover at r = 3, a 5700 K star far from ĥ: chromaticity | rgb(1.22474 × 5700 K) | 0.01 |
| GR9 | Weak field across the hand-off: r = 9 × 10⁵ (table) and r = 2 × 10⁶ (`weakDeflectionFinite`), star at β = 0.2° | `star_images` | 0.75 px |

GR1–GR3, GR6 and GR7 are the [Acceptance](#acceptance-criteria) shadow and ring rows. Rolled and off-axis cameras (GR4 and GR5 repeated at three camera orientations) need M1.6b's camera; until then they run with yaw/pitch only (`main.gd:96`).

### M3.6 Demo scene, HUD, reference renders

- **`make run -- --bh`**: `bh_enter` at r = 10⁶ (open question 4: which hole), then `bh_approach` to 10 r_s at β_loc 0.1, `bh_hover`, then on keys `bh_approach` 5 → 3 and `bh_orbit`. The HUD shows mode, r/r_s, **static clock √(1 − r_s/r) = 0.948683 (sim)**, "1 ship-hour = 1.0541 home hours", shadow half-angle, local blueshift, local β, and the hover acceleration in g with "bubble only" when it exceeds 1 g. The HUD formats *only* fields from `sim.state["gr"]`. A unit test injects a sentinel state and checks that the text shows it.
- **`make capture-bh`** writes `renders/bh_r{10,5,3}_{toward,side,away}_{hover,orbit}.png` and a contact sheet with the debug grid. With M1.4c in place it adds the same set with the Milky Way and catalogue stars. Spec §4 says these are "diffed in CI", but CI has no GPU (as in M1). They are diffed locally by `tools/render_diff.py` against the committed set (mean absolute difference ≤ 1/255), and a person opens them.
- **Report** `design_docs/implemented/r1/m3-report.md`: the renders (with who opened them and when), golden output, the table generation time on the VM, parity results, and upstream AILANG reports.

### What can start now

| Sub-milestone | Needs | Can start |
|---|---|---|
| M3.1 package | nothing | **now** |
| M3.2 table | M3.1 published | **now** (after M3.1) |
| M3.3 CPU mirror | M3.2 | **now** (after M3.2) |
| M3.4 sim GR mode | M3.1; M2 protocol framing if it has landed | **now** (additive to v1.1) |
| M3.5 GPU, debug grid, GR1–GR3/GR5–GR9 yaw/pitch | M3.3 | after M3.3; **not** blocked by M1.4 or M1.6b |
| M3.5 rolled/off-axis GR4/GR5 repeats | M1.6b | after M1.6b |
| M3.5 star path on the binary catalogue | M1.3 (star shader rewrite) | after M1.3, via the include |
| M3.6 Milky Way renders + photometric exposure | M1.4c, M1.5 | after M1.4c/M1.5; debug-grid renders before |

## Acceptance criteria

`$A` is the pinned v0.50.0 `ailang` (`runtime/bin/ailang` after `make runtime`; PR #18 bumped the pin). `$PKG` is a fresh clone of `ailang-packages` at `packages/relativity`.

| # | Criterion | Command |
|---|---|---|
| AC-1 | check41–check50 and all earlier package tests pass | `cd $PKG && $A test --package .` |
| AC-2 | Quality is clean (exit 0, no PUB gates); the dry run passes; the next free minor (planned 0.5.0) is published with `geodesic` exported | `cd $PKG && $A pkg quality . && $A publish --dry-run && $A publish && ailang pkg info sunholo/relativity \| grep -E "v$V\|geodesic"` |
| AC-3 | `lensDigest 16` is bit-identical on the strict VM and the interpreter, and within 1e-9 of the Python reference | `$A run --quiet --bytecode --strict-bytecode --entry lensDigest --args-json 16 _smoke.ail` vs the same without the flags, `cmp` + `python3 -c` tolerance |
| AC-4 | The game pins the new version; the lock is consistent | `grep "\"$V\"" sim/ailang.toml && make deps AILANG=$A` |
| AC-5 | Table accuracy: on a deterministic 10k-point (r, ψ) probe set, \|δ_table − δ_exact\| ≤ 1.2e-4 rad for r ≤ 100, ≤ 1e-3 relative above; the r = 10⁶ row and `weakDeflectionFinite` agree to 1e-3 relative; every texel finite; `lens_inv` strictly monotone in every row; header sha256 matches | `make physics` (section "Schwarzschild (spec §3)") |
| AC-6 | The committed table reproduces: sampled regeneration on the strict VM is bit-identical; row 128 cols 0–63 are identical on VM and interpreter | `make lens-lut-check` (in `make test`) |
| AC-7 | Shadow: GPU radius within **0.5 px** of f·tan α, sin α = (b_c/r)√(1 − r_s/r), at r = 10, 5, 3 (GR1–GR3); pixels inside the shadow are black (GR7) | `make golden` |
| AC-8 | Weak field, per open question 1 (default): \|α(1000)/(2r_s/b) − 1\| ≤ 1 % (measured 0.148 %) **and** \|α(100)/(2r_s/b + 15π r_s²/16b²) − 1\| ≤ 3e-4 (measured 2.68e-4), on the package and on the mirror's r → ∞ column | `cd $PKG && $A test --package .` (check42, check43) and `make physics` |
| AC-9 | Einstein ring: GPU ring radius for a star directly behind the hole within 0.5 px of f·tan ψ_E at r = 10, 100, 1000 (GR6); CPU ψ_E at r = 10, 5, 3 matches check46 within 1e-7 rad | `make golden` and `make physics` |
| AC-10 | Star images (primary + secondary) within 0.75 px of the CPU reference (GR5, GR9); orbit shadow mask (GR4); blueshift chromaticity within 0.01 (GR8) | `make golden` |
| AC-11 | GR sim: hover at 10/5/3 reports `static_clock` = 0.948683298050514 / 0.894427190999916 / 0.816496580927726 (±1e-15) and `blueshift` likewise; each reason code leaves the state unchanged; `scriptedApproach` matches the closed form within 1e-9 under `--strict-bytecode`; the GR fixture is VM/interpreter identical; the v1.0/v1.1 tests pass unmodified | `make sim strict parity parity-offaxis parity-gr` |
| AC-12 | The HUD shows the sim's value, not its own: a sentinel injection test passes, and no client code outside `physics/` and `tests/` computes the clock rate | `make sim` (HUD test in `test_sim_bridge.gd`) and `! grep -rnE "sqrt\(1(\.0)? *- *1(\.0)? */ *r" main.gd sky bridge ui` |
| AC-13 | Reference renders at 10, 5 and 3 r_s (toward, side and away from the hole; hover and orbit) are committed, match the local diff, and the report records who opened them | `make capture-bh && python3 tools/render_diff.py renders/bh_* && grep -n "opened by" design_docs/implemented/r1/m3-report.md` |
| AC-14 | `make test` is green locally and in CI; `sim/core.ail` still passes `--strict-bytecode`; no GR maths outside the package and its mirrors | GitHub Actions `CI`; `! grep -rn "1.5 \* u \* u\|acos(-3" sim/*.ail tools/` |

## Sub-milestones and estimates

| ID | Scope | LOC (code + tests) | Depends on | Order |
|---|---|---|---|---|
| M3.1 | Package: `schwarzschild` additions, `geodesic` (integrator, Carlson oracle, images), check41–50, smoke digest, CHANGELOG/AGENT.md, publish | 330 + 300 | — | 1 |
| M3.2 | `sim/tools/lens_lut.ail`, `tools/pack_lens_lut.py`, `data/lens/*.bin` + header, `make lens-lut`, `make lens-lut-check` | 180 + 80 | M3.1 | 2 |
| M3.3 | `physics/schwarzschild.gd`, the "Schwarzschild" section of `test_physics.gd` | 230 + 220 | M3.2 | 3 |
| M3.4 | Sim GR mode (core + ship), protocol commands and reason codes, `scriptedApproach`, `gr.ndjson`, `make parity-gr`, bridge tests | 220 + 230 | M3.1 (parallel with M3.2/3.3) | 2′ |
| M3.5 | `schwarzschild.gdshaderinc`, `lensed_sky.gdshader`, debug grid sky, star image orders and ring-star path, golden GR1–GR9 | 330 + 220 | M3.3; M1.6b for the rolled repeats; M1.3 for catalogue stars | 4 |
| M3.6 | Demo scene and HUD, `make capture-bh`, `tools/render_diff.py`, report | 160 + 100 | M3.4, M3.5; M1.4c/M1.5 for the Milky Way set | 5 |
| | **Total** | **1,450 + 1,150 ≈ 2,600** | | |

Every sub-milestone stays under the 250-LOC-per-PR cap by splitting along the code/test line where needed (M3.1 and M3.5 are two PRs each). There is one package publish, at the end of M3.1.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Full table generation on the VM is slower than the 7 min estimate (measured on a v0.50.0 dev build; row V11) | Re-measure on the v0.50.0 release pin as the first M3.2 task. Over 60 min, use the open-question-2 fallback (the exact form generates; the integrator checks). `make test` only regenerates a sample |
| VM/interpreter divergence in long float loops (the M1.6a history: ailang#1354/#1355) | AC-3 and AC-6 compare with `cmp`. Shrink and report upstream (CLAUDE.md, GCP store). Do not relax to a tolerance |
| Bilinear table error is at the 1.2e-4 rad budget (row V10) | Catmull-Rom in y; AC-5 measures; 4096-column fallback (+4 MB) |
| float32 Δψ near the edge loses order ≥ 2 images | Accepted and stated: they are within 0.1 px of the edge at 10 r_s and appear through the per-pixel photon ring (non-goal) |
| Ring stars: the source-plane PSF is an approximation where the lens map is strongly non-linear | GR6 checks the ring radius. The total ring flux is reported against Σμ in the M3 report. The 64-star cap is finite and logged |
| Conflict with M1.3's star-shader rewrite | A single `#include` and one branch; M3.5's star path is sequenced after M1.3 |
| M2 changes the protocol framing at the same time | GR field names are the contract; the second to land does the fold (M3.4) |
| Godot glow and AgX tonemapping blur the shadow edge | GR cases use a linear tonemapper with glow off (as M1 AC6) |
| The bar's weak-field clause cannot be met literally | Open question 1; AC-8 builds to the corrected pair; landing waits for the ruling |
| Hover is physically absurd for stellar holes (~10¹⁰ g) | Shown on the HUD (Pillar 6); orbit mode is the drive-free alternative |
| The local runtime drifts from the pin (row V8: it was v0.45.0 when this doc was drafted) | `make runtime` first; the ACs name `$A` (v0.50.0) explicitly |

## Open questions for the user

1. **The weak-field check value (bar clause 3, spec §3, roadmap M3).** The exact deflection at b = 100 r_s is 1.50 % above 2r_s/b (Problem 3; the second-order term is that size). The literal "within 1 % of 2r_s/b at b = 100 r_s" fails for any correct code. If b is read as the closest approach r₀ = 99.496 r_s, the result is 0.97 %, which passes, but only by accident. **Recommendation:** amend to "within 1 % of 2r_s/b at b = 1000 r_s (0.148 %), and within 3 × 10⁻⁴ of the second-order series 2r_s/b + (15π/16)(r_s/b)² at b = 100 r_s". Record it in the ledger, then edit the spec, roadmap and bar. **Default if unanswered:** M3 builds and tests to that pair (AC-8), and bar clause 3 is not marked met until you rule. The loop does not edit the bar.
2. **Spec §3 Method step 1 for a finite observer.** The 1D Δφ(b) table is exact only at r = ∞. M3 needs the 2D (ψ, r) table, of which the 1D table is a limit, and it may need to generate the table from the exact elliptic form if the VM run is too slow. **Recommendation:** accept both. The spec gains "for an observer at r, tabulate δ(ψ, r); tables may be generated by the integrator or the exact form, provided the other cross-checks them". **Default:** a 2D table generated by the Binet integrator (literal), with the spec amendment proposed at landing.
3. **The hover-radius domain in M3: r ∈ [2, 10⁶] r_s.** Below 2 r_s, approaching the photon sphere, the near-edge structure changes character, and the table would need a different singular treatment (Design M3.2). **Recommendation:** M3 covers [2, 10⁶]. Near-horizon dives (1.01 r_s → 10×, the big time skips) belong to the time-skip/New Game+ milestone, which extends the table. **Default:** as recommended; the sim answers `bad_radius` below 2.
4. **Which hole the demo uses.** **Recommendation:** Gaia BH1, the nearest known black hole (≈ 9.6 M☉ at ≈ 480 pc, El-Badry et al. 2023; values re-verified at M3.4). The ship is placed at 10⁶ r_s from it without a journey, so the lensed sky is the real sky in that direction. **Default:** Gaia BH1. The alternative is a synthetic 10 M☉ hole one light-year from Sol, which is simpler but contradicts the real sky.

## Deliverables

- **Package** `sunholo/relativity@0.5.0` (next free minor): `schwarzschild` additions, the new `geodesic` module, check41–check50, `lensDigest`, CHANGELOG, AGENT.md.
- **Game:** `sim/tools/lens_lut.ail`, `tools/pack_lens_lut.py`, `data/lens/lens_fwd.bin`, `lens_inv.bin` (with headers), `physics/schwarzschild.gd`, `sky/schwarzschild.gdshaderinc`, `sky/lensed_sky.gdshader`, the star image orders and ring-star path, the sim GR mode and protocol commands, `tests/fixtures/gr.ndjson`, `tools/render_diff.py`, new tests, and the Makefile targets `lens-lut`, `lens-lut-check`, `parity-gr`, `capture-bh` (plus `--golden=gr`).
- **Renders:** `renders/bh_*.png` and the contact sheet, opened by a person.
- **Report:** `design_docs/implemented/r1/m3-report.md`.
- **At landing:** design-repo roadmap status; the `black-hole-mechanics.md:82` fix; the spec amendments if questions 1 and 2 are accepted; the queue row 4 version note; the changelog entry.

## Verification log

Run 2026-10-01 at `e9d35c5a49f7658ffb17dfa84420f67b712bbc3c`. `R=~/.ailang/cache/registry/sunholo/relativity/0.3.0`. The prototype scripts are in the session scratchpad (`geo.py`, `lut*.py`, `img.py`, `binet/probe.ail`). The M3.1 tests re-derive every number from them.

| # | Claim | Command | Observed | Verdict |
|---|---|---|---|---|
| V1 | No GR code in the game | `grep -rniE "schwarz\|lens\|geodesic\|r_s" physics sky tests main.gd sim/*.ail bridge` | only unrelated hits (`xyz_to_linear_srgb`, `r_sol`) | True |
| V2 | The package has 7 closed forms and no integrator | `grep -c "export pure func" $R/schwarzschild.ail`; `grep -rn "binet\|geodesic" $R/*.ail` | `7`; no hits (only `blackbody.ail` `integrate` over λ) | True |
| V3 | The existing GR tests | `sed -n 245,280p $R/relativity_test.ail` | check36 π/4 at r = 3; check37 0.249041507929 at r = 10; check38 r = 1.2; check39 `weakDeflection(100)` = 0.02; check40 blueshift 2/√3 at r = 4 | True; check39 tests the formula, not the physics |
| V4 | The star shader and golden harness are SR-only | `cat -n sky/starfield.gdshader main.gd` | aberration `:26–44`, a single projection `:52–67`; golden `:173–215`; `HEADING` `:11`; capture targets `:139`; `BG_COLOR` `:52–53` | True |
| V5 | The per-pixel sky is only on a branch | `git ls-tree -r --name-only m1.4a-background-spike \| grep shader` | `spike/panorama_sky.gdshader` (inverse aberration + Doppler); not on `main` | True |
| V6 | The sprint state of the dependencies | `python3` over `sprint_R1-M1-SKY.json` | M1.6b, M1.3, M1.4bc, M1.5 `passes: None`; M1.4a closed on its branch (D-10, NOIRLab) | True |
| V7 | The design-repo dilation table error | `grep -n "1.5 rs" ../stapledons-design/features/future/black-hole-mechanics.md` | `:82 \| 1.5 rs \| 2x \|`; the correct value is √3 = 1.732 | True |
| V8 | Toolchains on this machine | `runtime/bin/ailang --version`; `ailang --version` | v0.45.0 (stale); v0.50.0-6 dev on PATH; the pin is v0.47.2 | True; the ACs name `$A` |
| V9 | Check values | `python3 geo.py` (Binet RK4 h = 10⁻³ against Carlson R_F, independent) | α(100) = 0.0202999662395031 (1.49983 % over 2/b); α(1000) 0.147 %; ε = 10⁻⁶: 13.4152855579; b̄ = −0.400230039755; ψ_E(10, 5, 3, 100, 1000) = 29.828317906°, 44.874561077°, 61.888756430°, 8.520443413°, 2.604361342°; order-2 ring at r = 10: 14.283091260° against a shadow of 14.269027328°; method difference ≤ 3 × 10⁻¹³ (2.7 × 10⁻⁹ at ε = 10⁻⁶) | True |
| V10 | Table layout accuracy | `python3 lut.py lut2.py lut3.py lut4.py` | h = 0.01: 8.5e-6, h = 0.005: 5.3e-7 rad worst; bilinear 1024 × 64 ln r: 1.3e-3; 2048 × 256 ln(r − 1.5), scaled column: 1.0e-4 rad | Layout chosen; AC-5 re-measures |
| V11 | VM cost and parity of the integrator loop | `ailang run --quiet [--bytecode --strict-bytecode] --entry bench --args-json 400 probe.ail` (v0.50 dev) | strict VM 0.30 s, interpreter 37.66 s, both `372.11356643394237` | True on dev; re-measure on v0.47.2 (Risks) |
| V12 | Image positions and magnifications | `python3 img.py` | r = 10, β = 20°: 39.837659068° / 23.543122070°, μ 1.118821 / 0.276451; r = 1000, β = 1°: 3.144406661° / 2.160968686°, μ 1.847367 / 0.856138 | True |
| V13 | Pixel scale of the golden harness | `grep viewport project.godot`; `camera.fov = 70.0` (`main.gd:61`) | 960 × 540, f = 270/tan 35° = 385.600 px; shadow 98.066 / 202.398 px; r = 3 at FOV 110°: 189.056 px | True |
