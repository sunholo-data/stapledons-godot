# R2: Kerr (spinning) black holes

**Status:** Direction and OQ1–OQ5 **approved by D-107 A**, Mark attended 2026-10-21; revised in iteration 45 (2026-10-22). Created 2026-10-21, iteration 43, charter row **R2** of [`design_docs/stapledon-mission.md`](../../stapledon-mission.md). **Pending quorum, not scheduled** (quorum round 3, iteration 45, objection `oc-kimi-k3`): D-107 A requires a re-quorum including an Anthropic or OpenAI reviewer before the headless slices are scheduled, and round 3 had neither seat present (`claude-sonnet-5@claude-p` absent on the mission ration probe, `gpt6-1-sol` benched as the author's vendor). This revision therefore does NOT schedule K1.1a or any later headless slice; the planner entry remains pending until one quorum round closes with that seat present and no outstanding objection surface, or Mark issues an explicit attended waiver recorded as a new D-row. **K1.0 stays parked for Mark; K1.1a is package maths and stops before publish.** This revision performs no implementation, publication or design-repo edit.
**Release:** r2 · **Milestone:** charter row R2. The R1 roadmap lists Kerr as unfinished business twice ([roadmap/r1-foundations.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) line 32's M3 row, "Kerr rotation remain[s] future work", and lines 167–168, "spin (Kerr) and the true Galactic-Centre sky are follow-ups"); the M3 ruling D-53 likewise: "spin (Kerr) is a later milestone". This document is that milestone's design.
**Priority:** P1, queued under D-107 A and the 2026-10-20 order. The spinning-hole requirement is in [premise §1](https://github.com/sunholo-data/stapledons-design/blob/main/vision/premise-and-loop.md); this implementation covers the visit demo only.
**Implements:**
- [Premise §1](https://github.com/sunholo-data/stapledons-design/blob/main/vision/premise-and-loop.md) and the [2026-10-06 decisions](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md), lines 1292–1340: the spinning-hole requirement. This doc specifies its implementation only.
- [features/future/black-holes.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/black-holes.md): the status line "Kerr rotation … remain[s] future work" (line 4) and non-goal "Kerr (rotating) BH ergosphere mechanics — Future expansion" (line 415). This doc plans that future work; the lines stay until landing.
- [features/future/gr-visual-mechanics.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/gr-visual-mechanics.md): non-goals "Kerr (rotating) BH — frame dragging, ergosphere (future expansion)" (lines 569, 595). Release 1 below supersedes the frame-dragging and ergosphere *boundary* parts only; the interior stays out.
- [features/future/earth-fate-home.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/earth-fate-home.md) §4b: the canon's 10 M☉ rogue hole, r_s = 29.5 km (line 135) — the seed for check value RK-18.
- [physics/relativity-spec.md](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) §3: extended by a new **§3b (Kerr)** with check values RK-n, per Definition-of-done gate 2. The amendment is a design-repo PR (K1.0) that must merge before any Kerr *visual* merges. Today the spec has no Kerr content (row V6).
- [features/next/bubble-resources.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/bubble-resources.md) line 343 lists superradiance as a future energy resource; excluded here by D-107 A (resolved OQ4).

**Depends on:** `sunholo/relativity@0.12.0` (the current pin, row V3; Kerr publishes the next free minor, planned **0.14.0**, because 0.13.0 is already taken in source by the unpublished domain-bounds release on ailang-packages main, #126, row V29); M3's landed GR stack (row V10: the `geodesic`/`schwarzschild` package modules, the offline lens tables and their bucket pins, the CPU mirror `physics/schwarzschild.gd`, the sim GR mode at protocol 2.6, the GPU lensed sky, goldens GR1–GR12, the demo `demos/black_hole_visit.gd`); the pinned AILANG v0.54.14 (`runtime/bin/ailang`, row V2); the D-18 large-asset bucket.
**Estimated:** ~3,710 LOC in nine parent milestones, decomposed into the existing plan's 30 executor slices; budget 30 working days (about six weeks), excluding approval and infrastructure waits. Re-estimate if the revised frame/tide/table work exceeds a slice budget. One eventual package publish, separately gated.
**Evidence:** historical rows pin game `8d17f90b` / design `864a4e4`; iteration-45 source review pins game `4dee08e5`, merged with `origin/main` `23928d01`. New independent oracle commands and their complete scratch source are retained below.

## Game vision alignment

Scored against [vision/core-pillars.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md), plus the spec pillar, per the `game-vision-designer` discipline.

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | 0 | 0 | No choices yet: release 1 is a visit demo, all Kerr quantities are scenario data. The emergence scene and its throw home (the choice-laden part) are release 2+ |
| The Game Doesn't Judge | 0 | 0 | Readouts only; the sim reports frame dragging and two ISCOs without flags of right or wrong |
| Time Has Emotional Weight | + | +1 | The ZAMO/static clock and the pro/retro orbit clocks are honest numbers at the hole where the run begins; at the s = 0.998 prograde ISCO dτ/dt = 0.0927 (RK-8b, row V40) — the ship ages a tenth — stated, not exploited |
| The Ship Is Home | + | +1 | The lensed sky is seen from the 3D ship's bridge and decks through `InteriorSky`, as in M3 (D-52); the opening of every run happens aboard |
| Grounded Strangeness | ++ | +2 | The shadow is no longer round: at s = 0.9 seen from the equatorial plane its half-widths are 2.844 M on the pinched prograde side against 6.832 M on the retrograde side (asymmetry 41 %, RK-14/15) and the sky itself twists. Strange, and exactly what a spinning hole does |
| We Are Not Built For This | + | +1 | The HUD says plainly why the first Kerr visit is at a supermassive hole: across the 100 m bubble the tide at the 10 M☉ ergosphere is ≈1.05 × 10⁹ g (V22: 1.030483e10 m/s² / 9.80665), so the canonical emergence is survived, not toured |
| Hard sci-fi authenticity (spec) | ++ | +2 | Kerr maths goes into `sunholo/relativity` first with cited formulas (Bardeen 1972/1973, Carter 1968), check values, and an a = 0 reduction proven against M3's RS-9–RS-13 pins; the spec gains a normative §3b before any visual merges |
| **Net** | | **+7** | **Go** |

**Pillar disposition:** D-107 A approves this direction, including the two zero scores, as D-53 did for M3. Scope is unchanged; the scores remain +7, Go.

## Problem

1. **The canon's hole spins; the shipped hole does not.** `sim/gr.ail:4` declares "A non-spinning hole (D-13, D-53: Sgr A* by default, the mass a scenario parameter)" (row V14). The premise and the 2026-10-06 decisions make the rogue hole spinning with an ergosphere (row V7). The roadmap names Kerr as future work (row V8). Charter row R2 asks for this design.
2. **The package cannot do Kerr.** `sunholo/relativity@0.12.0` has no Kerr symbol; its `AGENT.md:29` says "Do NOT use it for: Rotating (Kerr) black holes" (rows V4, V5). CLAUDE.md gate 3 means no Kerr visual can exist before the package does it.
3. **The spec has no Kerr section or check values.** §3 is Schwarzschild-only and the §7 index ends at RS-23 / RS-Q4 (row V6). Gate 2 requires normative check values before a visual merges.
4. **The hole is already data, spin just is not among the parameters.** `sim/gr.ail:67` notes "another hole (the canon's rogue hole) is data, not code" via `(bh_mass_msun, bh_r)` scenario parameters (row V14); the fixture `sim/gr_test.ail:157` already runs a game with `bh_mass_msun = 10`. Kerr continues that pattern: spin enters as `bh_spin`, a scenario value, never a code constant.

## Goals and non-goals

**Goals — release 1 ("a spinning hole the game can show"):**
- **G1.** A new `kerr` module in `sunholo/relativity` (next free minor, planned 0.14.0): the closed forms below with citations, contracts, tests and check values RK-n; the Carter-form null integrator for offline tables; publish.
- **G2.** An offline, deterministic Kerr lens-table set for one spin and an equatorial observer plane per scenario, generated on the strict VM, finite over its whole range, fetched by sha256 pin like M3's tables (D-18).
- **G3.** A GPU Kerr sky for that observer: the asymmetric, flattened shadow; lensed panorama with the frame-dragging twist; SR composed in the explicitly defined ZAMO table frame below. The Schwarzschild renderer path is untouched and stays bit-identical for s = 0 scenarios.
- **G4.** The sim reports spin-dependent readouts (horizon, ergosphere boundary, prograde/retrograde photon orbits and ISCOs, frame-dragging rate, orbit clocks pro/retro, Kerr tides from the Weyl scalar), as scenario-parameterised protocol fields at the next free minor, additively.
- **G5.** The normative spec amendment (§3b, RK check values, §4 additions) merges **before** any Kerr visual (gate 2), with §4-standard goldens and reference renders a human opens.
- **G6.** A Kerr visit demo aboard the 3D ship, mirroring M3.6: hover, approach, prograde and retrograde orbits outside the ergosphere, HUD from sim fields only.

**Non-goals — release 1 (approved D-107 A):**
- No flight inside the ergosphere and no emergence scene (resolved OQ3): inside the static limit no static observer exists and the table domain needs a separate design.
- No superradiance or energy extraction (D-107 A, resolved OQ4).
- No Kerr star path: catalogue stars keep second images and Einstein rings only at s = 0. With spin on, star splats are drawn *off* in the GR view (never at wrong positions) and the debug line counts them, never silently — see K1.5. The Kerr inverse lens map (2-D, needs Newton solves or a second table) is release 2.
- Polar or off-equator observers (θ_o ≠ 90°), near-extremal tables (s > 0.998), accretion disks, jets, charge, free-fall ship dynamics, Penrose-process mechanics, time-skip gameplay, and the true Galactic-Centre sky (M3's OQ5, still open).

## Design

**Conventions.** As the package's `schwarzschild` module: c = 1; radii in units of r_s = 2GM/c² (the Schwarzschild case puts the horizon at r = 1); angles in radians. Kerr formulas below use u = r/(GM/c²) = 2r_{r_s}. The dimensionless spin is s = Jc/(GM²) ∈ [0, 1); it is a scenario value, default 0. Boyer–Lindquist Δ(u) = u² − 2u + s², Σ(u, θ) = u² + s² cos²θ, A(u, θ) = (u² + s²)² − Δ s² sin²θ.

### The scope cut: what spin changes that a player can see or feel

| Effect (all cited in K1.1) | Player-visible? | Release 1? | Why |
|---|---|---|---|
| Shadow flattens into an asymmetric "D" pinched on the prograde side | Yes — headline visual, maximal for an equatorial observer | **In** | Closed-form critical curve (Bardeen 1973) anchors the far row; table + goldens cover the visit radii |
| Sky twists near the shadow edge (frame dragging) | Yes, near the edge | **In** | Second channel of the same table; golden GR15 |
| Ergosphere boundary; no static observer inside it | Readout + Archive content only; the demo domain [2, 10⁶] r_s never reaches it (the equatorial static limit is r_s, row V18 range) | **In as readout; entry out** | Inside-ergosphere rendering needs new domains and ZAMO-frame compositing |
| Prograde vs retrograde ISCO and photon orbits | Yes — two different "lowest safe orbits", two clocks | **In** | Closed forms; the orbit intent gains a handedness |
| Clock rates: static (outside ergosphere), ZAMO frame | Yes — the time HUD | **In** | Lapse and g_tt closed forms; the a=0 limit is today's staticClockRate |
| Frame-dragging angular velocity ω(u, θ) | Readout + the twist above | **In** | Closed form −g_tφ/g_φφ |
| Tides for a spinning hole | Readout | **In (full Weyl tensor, ZAMO then ship-frame projection); independently verified before shipping** | Numeric package values mandatory; DI-10 STOP if the curvature oracle cannot verify them |
| Superradiance, energy extraction | Not shown, no mechanic | **Out** (D-107 A, OQ4) | Approved scope exclusion |
| Star images/rings around a spinning hole | Their absence is visible | **Out (release 2)** | Kerr inverse map is a 2-D problem; bounded cut, stated on the HUD caption |

**Bit-identical Schwarzschild at s = 0.** (1) Scalar package exports dispatch at zero spin to the existing Schwarzschild exports, including clocks, orbit speeds and tides; exact dispatch is distinct from a numerical small-spin limit test. Other reductions use ±1e-15. (2) Independently generated zero-spin Kerr tables match M3's pinned, fetched bins on M3's probe set within AC-5's 1.2e-4 rad budget. (3) The precise stream comparisons and old decoder refusals are defined in K1.4 below; explicit zero is compared with the previous equivalent **absent-spin** request. (4) GR16 forces the Kerr shader at zero spin within M3's 0.5 px; production zero spin and GR1–GR12 keep the existing path.

### K1.0 Spec amendment §3b (design repo; merges before any visual)

A new `physics/relativity-spec.md` section **§3b GR (Kerr; the spinning hole)** with the §3-style quantity table, Carter-separated method and explicit frame contract, §4 golden/render requirements and §7 registry rows. **Parked for Mark under D-107 A.** Its final values/provenance depend on K1.1a-a's reproducible oracle fixture, so it is not the first execution prerequisite: K1.1a can proceed before it. It must merge before K1.1b-c (as the plan orders) and before any K1.5 work or visual merge. All formulas specified here must first live with citations and tests in `sunholo/relativity`; mirrors cannot be their only code copy.

The following are 17-significant-digit oracle fixtures, **[CPython Decimal, precision 60; V31/V32]**, rather than six-decimal display literals. The spec may round its display values; tests of such text use half a unit in its last printed place, separately from physics assertions.

| ID | Quantity | Value | Unit |
|---|---|---|---|
| RK-1 | Outer horizon u_+ = 1 + √(1 − s²) at s = 0.5, 0.9, 0.998 | 1.8660254037844386 / 1.4358898943540674 / 1.0632139225171164 | GM/c² |
| RK-2 | Inner horizon u_−, same spins | 0.13397459621556135 / 0.56411010564593264 / 0.93678607748288357 | GM/c² |
| RK-3 | Static limit on the equator (identity in s) | 2 (= 1.0 r_s) | GM/c² |
| RK-4 | Equatorial photon orbits, prograde/retrograde, s = 0.9 | 1.5578546274233828 / 3.9102679391030367 | GM/c² |
| RK-5 | Same, s = 0.998 | 1.0739092576799517 / 3.9982218928479460 | GM/c² |
| RK-6 | ISCO prograde/retrograde, s = 0.5 | 4.2330025295308257 / 7.5545847145123584 | GM/c² |
| RK-7 | ISCO prograde/retrograde, s = 0.9 | 2.3208830417618872 / 8.7173522796064893 | GM/c² |
| RK-8 | ISCO prograde clock dτ/dt, s = 0.9 (retrograde) | 0.37086794439864592 (0.79319251811829484) | — |
| RK-9 | Horizon angular velocity Ω_H = s/(2u_+), s = 0.9 | 0.31339450313662925 | c³/GM |
| RK-10 | Frame dragging ω at the equatorial static limit, s = 0.9 | 0.16014234875444840 | c³/GM |
| RK-11 | ZAMO lapse (clock) there, s = 0.9 | 0.37964208654863802 | — |
| RK-12 | ZAMO local speed of the prograde ISCO, s = 0.9 (s = 0.5) | 0.62454869546086524 (0.56164924228192780) | c |
| RK-13 | Static clock → 0 at the static limit; no static observer inside. At zero spin, explicitly call `staticClockRate(u/2)` (V34) | qualitative + byte-exact dispatch | — |
| RK-14 | Shadow endpoints at infinity, s = 0.9, equatorial: α_min, α_max | −2.8444214034761693, +6.8323192304466666 | GM/c² |
| RK-15 | Shadow top half-height β_max, equatorial: η(3) = 27 and λ(3) = −2s, so β_max = 3√3 (Bardeen critical curve) | 5.1961524227066319 | GM/c² |
| RK-16 | Uniform-u discrete diagnostic defined below, s = 0.9 (s = 0.998) | 5.0437368945142949 (4.8770013845209779) | GM/c² |
| RK-17 | Observer at 45°, s = 0.9: visible-arc α_min, α_max, β_max (math test only) | −3.4170599872799702, +6.2964531467076725, 5.0696345295581239 | GM/c² |
| RK-18 | 10 M☉, s = 0.9: r_s; equatorial static limit; horizon; prograde ISCO; prograde-ISCO period; Ω_H (IAU 2015 nominal GM_sun) | 29.532500761002495 km; 29.532500761002495 km; 21.202709698863643 km; 34.270740098515360 km; 1.3727616115380832 ms; 6362.7059001439946 rad/s | SI |
| RK-Q1 | s → 0 reduction: horizon at 1.0 r_s, ISCO at 3 r_s (the package's `isco()`), photon sphere at 1.5 r_s (RS-21), shadow a circle of radius 3√3/2 r_s (RS-9), ω → 0, no ergosphere | qualitative | — |

**RK-16 measure (normative):** N = 200000, u_j = u_pro + j(u_ret−u_pro)/(N−1), j = 0…N−1, with both photon-orbit endpoints included exactly; equal weights 1/N on the upper equatorial critical arc. Report (1/N)Σ√(λ(u_j)²+η(u_j)). This is a reproducible sampling diagnostic, not an angular, perimeter or area mean and not a player-facing radius. No trapezoidal endpoint weights, visible-point filtering or omission of endpoints. V32 recomputes it with polynomial-root endpoints; the old s = 0.998 number and scanned right endpoint are withdrawn.

Tolerances: closed forms including RK-14 endpoints and RK-15/17 root/extremum values assert to 1e-12 relative against these fixtures; RK-16 to 1e-9 absolute for the specified finite sum. Rounded text is tested only at display precision. RK-18 uses nominal GM_sun = 1.3271244e20 m³/s² and c = 299792458 m/s (IAU 2015; `rsPerSolarMassMetres`).

### K1.1 Package: new module `kerr` (package first)

Closed forms, each with `requires` domains and Z3-provable `ensures` where expressible, each citing its source inline (as the M3 modules do):

- `horizonR(s)` = `(1 + √(1−s²))/2` (in `r_s`, so `u_+ / 2`); `horizonInnerR(s)` = `(1 − √(1−s²))/2` (in `r_s`, so `u_− / 2`) — Bardeen, Press & Teukolsky 1972 (ApJ 178, 347; "BPT72"), §II. Domains: `0 ≤ s < 1`.
- `staticLimitR(s, cosTheta)` = (1 + √(1 − s²cos²θ))/2 r_s — the ergosphere boundary, g_tt = 0 (Chandrasekhar 1983, *The Mathematical Theory of Black Holes*, §54). On the equator: r_s, independent of spin (RK-3).
- `frameDragOmega(u, cosTheta, s)` = 2su/A, in c³/GM = −g_tφ/g_φφ (Bardeen 1970, ApJ 162, 71, the locally non-rotating/"ZAMO" frame). `horizonOmega(s)` = s/(2u_+) (BPT72).
- `zamoClockRate(u, cosTheta, s)` = √(ΔΣ/A) (the 3+1 lapse; Bardeen 1973, "Timelike and null geodesics in the Kerr metric", in *Black Holes (Les Astres Occlus)*, eds DeWitt & DeWitt).
- `staticClockRateKerr(u, cosTheta, s)` = √(1 − 2u/Σ), `requires` outside the static limit (BPT72 eqs. 2.1, 2.7). **Evaluation:** if s = 0, call existing `staticClockRate(u/2)` directly; otherwise evaluate the Kerr form. On the equator the nonzero-spin form is explicitly `sqrt(1.0 - 1.0/(u/2.0))`, matching the static clock's operation order, rather than forming `2*u/(u*u)`. V34 records binary64 probes. Domain failure answers `bad_gr`, never NaN.
- `photonOrbitPro(s)`/`photonOrbitRet(s)` = `1 + cos[(2/3) arccos(∓s)]` (in `r_s`, i.e. `u_ph / 2` where BPT72 gives `u_ph = 2{1 + cos[(2/3) arccos(∓s)]}`). At `s = 0` both equal `1.5 r_s = photonSphere()`. ∓: arccos(−s) is prograde (BPT72's equatorial photon orbits; Bardeen 1973's Table II form).
- `iscoPro(s)`/`iscoRet(s)` = `u_ISCO / 2` (in `r_s`), where `Z₁ = 1 + (1−s²)^(1/3)[(1+s)^(1/3) + (1−s)^(1/3)]`, `Z₂ = √(3s² + Z₁²)`, and `u_ISCO = 3 + Z₂ ∓ √((3−Z₁)(3+Z₁+2Z₂))` (in `GM/c²`, BPT72 eq. 2.21). At `s = 0`, `u_ISCO = 6` so both return `3.0 r_s = isco()`. Misner, Thorne & Wheeler 1973 §25.6 carry the a = 0 member.
- Circular equatorial orbits: for handedness k = +1 (pro), −1 (retro), `orbitOmegaKerr` = k/(u^(3/2)+ks), clock dτ/dt = u^(3/4)√(u^(3/2)−3√u+2ks)/(u^(3/2)+ks) (BPT72 §II). **Signed** ZAMO velocity `orbitLocalSpeedKerr` is v_Z = (Ω−ω)√g_φφ/N, where N is the ZAMO lapse below. This fixes the retrograde sign and avoids mixing a speed magnitude with a direction. At zero spin, dispatch to existing clock/speed exports (apply k to the orbit direction, not the legacy speed magnitude). V31 checks ISCO speeds; V33 checks both signs independently from the metric.
- Tides: package tensor from Ψ₂ = −1/(u−is cosθ)³ in M = 1 units (Kinnersley principal tetrad; Chandrasekhar 1983, Kerr Weyl-scalar treatment), transformed with the **full Weyl tensor**, including its magnetic part, to the ZAMO frame and then the ship frame defined below. Diagonalising only the principal-frame scalar is insufficient. Use E_ij = C_i a j b U^a U^b, with geodesic-deviation acceleration −E·separation; state eigenvector/sign conventions in the package tests. Ship-frame stretch/squeeze readouts across the bubble must match today's static/radial/orbit tide semantics at s = 0 by explicit legacy dispatch. ZAMO eigenvalues are intermediate checks, not orbit readouts. **DI-10 STOP:** K1.1b-d and K1.4-b cannot complete, and K1.1p cannot publish, until `tools/kerr_ref.py` independently constructs curvature from metric derivatives, projects it into these frames, and verifies numeric tides over every accepted spin/domain (including s = 0.9, 0.998, the domain edge, both orbit senses and radial motion). Pin literals, trace/sign/unit checks and provenance before package implementation. If that oracle fails, stop for Mark's scope decision; G4/AC-K8 still require numeric package values. No null schema or substitute tide is authorized.
- Shadow critical curve for an observer at infinity, inclination θ_o (Bardeen 1973; Cunningham & Bardeen 1973, ApJ 183, 237): for spherical photon orbits of radius u between the prograde and retrograde photon orbits,
  λ(u) = −[u³ − 3u² + s²u + s²]/[s(u−1)], η(u) = 4u²Δ/(u−1)² − (λ(u) − s)²,
  then α = −λ csc θ_o, β = ±√(η + s² cos²θ_o − λ² cot²θ_o). (Derivation shown: the Kerr radial potential R(u) = [u² + s² − sλ]² − Δ[η + (λ−s)²] with R = 0, dR/du = 0 gives u² + s² − sλ = 2uΔ/(u−1), hence the pair above. Sign convention: with the hole's angular momentum along +z and the observer in the equatorial plane, α < 0 is the prograde side; RK-14's asymmetry pins the sense.) `shadowLambdaEta(u, s)`, `shadowAlphaBeta(u, s, cosThetaObs)`.
- The table integrator implements the complete Carter system below, with observer projection and analytic capture independent of its numerical termination.

**Frame contract (DI-07; package first).** Use signature (−,+,+,+), N = √(ΔΣ/A), ω = 2su/A, h = √g_φφ = √(A/Σ)sinθ. The **ZAMO** table tetrad is e_0 = (∂t+ω∂φ)/N, e_r = √(Δ/Σ)∂u, e_θ = ∂θ/√Σ, e_φ = ∂φ/h ([BPT72 §III, eqs. 3.1–3.3](https://the-center-of-gravity.com/documents/86/Bardeen-Press-Teukolsky_Rotating-Black-Holes-Locally-Nonrotating-Frames.pdf); Chandrasekhar §62). Screen source direction n_Z points toward the source, as spec §1 requires; future incoming photon momentum is p = E_Z(e_0−n_Z^i e_i). Thus E_inf = −p_t = NE_Z+ωL, λ = L/E_inf, and η = (p_θ/E_inf)²+cos²θ(λ²/sin²θ−s²). Constants are computed from this projection, never from a static ray treated as a ZAMO ray.

Static hover has velocity v_S = −ωh/N along e_φ relative to ZAMO. A circular ship has v_Z = (Ω−ω)h/N; a radial approach commanded at signed speed b relative to the **static** observer has ZAMO components v_r = b/γ_S, v_φ = v_S, γ_Z = γ_Sγ_b. In every mode dτ/dt = N/γ_Z. **Boost convention (quorum round 3, `gemini-4-argon`):** the ship's local frame is the **single pure boost** from the ZAMO tetrad along the combined vector v_Z = (v_r, 0, v_φ) in the (e_r, e_θ, e_φ) basis. The two-step composition (ZAMO → static along e_φ, then static → ship along the static radial axis) differs from it by a Wigner rotation in the (r, φ) plane and is not used anywhere. The package, CPU mirror and GPU shader all apply spec §2's inverse aberration to the ship pixel direction, n_Z = aberrate(n_ship, −v_Z) = [n_ship + ((γ_Z − 1)(n_ship·v̂_Z) − γ_Z|v_Z|) v̂_Z] / [γ_Z(1 − n_ship·v_Z)], then index the ZAMO table. (The reviewer's text had the forward form, `+γ_Z v_Z` and `1 + n_ship·v_Z`; spec §2 defines the inverse as aberrate(n′, −β), which flips both signs, row V43.) V33 includes a non-collinear radial-approach ray (b = −0.5, s = 0.9) pinning (n_Z^r, n_Z^φ), and `make kerr-oracle` checks it. Frequency transport is **ray-dependent**: g_Z = (1−ωλ)/N, D_SR = γ_Z(1+v_Z·n_Z), g_total = g_Z D_SR. This follows from −p·U and the conserved Killing energy (BPT72 §§II–III), and reduces for a static ship to 1/√(−g_tt) for every ray. A scalar static blueshift multiplied by a ZAMO orbit Doppler factor is forbidden. Package projection/transport functions own these formulas; CPU/GPU mirror them. V33 pins a nonzero-spin ray in hover/pro/retro, including its direction and shift; `make kerr-oracle` must also check a second ray, inverse-aberration round trips and the zero-spin limit before K1.3/K1.5.

For existing static-frame orbit fields, the same Lorentz boost gives signed v_orbit,S = (v_Z−v_S)/(1−v_Z v_S); `beta_local` is its magnitude and `dir_local` carries the sign. Define the local spatial basis from the orbit-plane normal and radial direction, then map to galactic axes by the proper rotation required by spec §2. Keep components as float64 scalars until hi/lo upload. γ and speed complements come from package clock/rapidity forms (γ_Z = N/(dτ/dt) is a check), never from subtracting a rounded near-unity speed. CPU/shader transport uses spec §2's stable Doppler evaluation near c.

**Carter state and signs (DI-12).** With E_inf = 1, P = u²+s²−sλ, R = P²−Δ[η+(λ−s)²], Θ = η+s²cos²θ−λ²cot²θ. State is `(u, θ, φ, t, σ_r, σ_θ)` plus constant `(λ, η)`. Use Mino parameter ζ, dλ_affine = Σ dζ (equivalent to Carter's affine first integrals): du/dζ = σ_r√R; dθ/dζ = σ_θ√Θ; dφ/dζ = sP/Δ+λ csc²θ−s; dt/dζ = (u²+s²)P/Δ+s(λ−s sin²θ). Sources: Carter 1968, *Phys. Rev.* 174, 1559; BPT72 eqs. 2.8–2.10; Chandrasekhar §62. RK4 evolves **all four coordinates**, φ unwrapped. Trace toward the source by negative ζ from the future incoming momentum above; initialise signs from its radial/polar momentum, not from screen-angle guesses. At each simple R or Θ root, locate the event, split the step there and flip only that component's sign once; continue into the allowed region. A zero at an equatorial constant-θ solution stays there; a double radial root is a critical ray, not a simple reflection. Never take sqrt of a negative potential by unconditional clamping. Clamp only roundoff within a scale-aware tolerance fixed by oracle tests, otherwise fail the ray. Use a regular angular chart through axis rays; coordinate singularities cannot drop probes. Recover the outgoing sky direction from the asymptotic momentum **and accumulated φ**, then compute both map channels. t is retained as a consistency check; frequency uses conserved E_inf/L and local −p·U, not an accumulated time approximation.

**Capture:** classify the past-directed radial branch analytically using the real roots of R, its allowed intervals, initial direction and the outer horizon. Inward rays with an accessible outer turning root return; rays with no such root reach the horizon; outward rays must still be checked for an intervening root. Critical/double-root rays belong to the mask boundary. The classifier does not use step count or integration termination. Tests independently check capture, λ/η conservation and null norm, radial/polar turn events, nonzero-spin φ/twist and refined-step convergence within the AC-5 angular budget. These are execution gates, not claims that this revision ran a solver.

**Domains and precision hazards (DI-05).** Metric/scalar API domain remains finite binary64 `0 ≤ s < 1`; the input is **s only**, including `bh_spin`, with no independent complement promised. The package forms `q = 1.0 - s` once and evaluates √(q(1+s)) and Δ = (u−u_+)(u−u_−). Its reference accuracy contract is relative to that represented s, and the 1e-12 RK/visual accuracy guarantee is restricted to s ≤ **0.998**; no accuracy claim about an unrepresented intended decimal spin or the s → 1 limit is made. Above the cap scalar results are finite/domain-checked but need separate conditioning evidence before use as a new reference fixture. Tables are supported only at exact manifest spins ≤ 0.998. This explicitly replaces the impossible independent-(1−s)-input rule; extending that contract requires a new paired API, never a silent extra scenario parameter. The cap is a rendering choice informed by Thorne 1974's thin-disk equilibrium model, not a universal prohibition on higher astrophysical spins. Guard acos/sqrt domains and NaNs before comparisons; the extremal λ/η 0/0 is excluded.

**Contract/test plan** (`kerr_test.ail` and focused companion tests, written first): precise RK-1…18 fixtures plus exact-dispatch RK-Q1 and small-spin numerical reductions against `schwarzschild`/`geodesic`; the zero-spin circle to 1e-12 absolute in α²+β²; independent Carter vs `deflectionExact` on M3's probes at the AC-5 budget. At photon-orbit roots assert **α_min = −λ(u_pro), α_max = −λ(u_ret)** and β² = η, with |η| ≤ 1e-10 M² for float64 endpoint evaluation and relative 1e-12 on α (DI-11), not η bit-equal to zero. The package handles s = 0 by its nonsingular Schwarzschild branch. Add `kerrDigest(n)` to `_smoke.ail` (strict VM vs interpreter, `cmp`), next to `lensDigest`; the allowlisted independent `tools/kerr_ref.py` reproduces every RK row and frame/tide test. K1.1a stops before publish. Eventual K1.1p requires independent package PASS, `[release] kind = "feature"`, CHANGELOG/AGENT.md updated with the precise domains, quality clean without gates, dry run, then Mark's explicit version/content go before controller publication.

### K1.2 The Kerr lens tables (offline, strict VM, bucket-pinned)

**Why the M3 shape does not transfer.** Schwarzschild lensing is spherically symmetric: a static observer's ray is fixed by one angle ψ, so M3's table is 2-D in (ψ, r) with a 1-D analytic boundary (Synge). Kerr is only axisymmetric: the outgoing direction at infinity depends on the observer's position angle θ_o and on both screen angles (equivalently the photon's two constants λ, η — the Carter constant). This doc fixes the observer to the **equatorial plane** (θ_o = π/2) and fixes one spin per scenario. The map left to tabulate is then 3-D: screen polar angle ψ from the hole direction, screen azimuth χ around it, and observer radius r.

**Three logical artefacts per spin** (generator `sim/tools/kerr_lut.ail` + `kerr_lut_main.ail`, pure AILANG on the bytecode VM, mirroring M3.2's toolchain and the F32 encoder M3's lens tables actually use, `encodeF32LE` from `std/embedding` at `sim/tools/lens_lut_main.ail:42`, row V41; STOP at slice a if the landed toolchain differs from this description). The screen convention is n_Z = −e_r cosψ + sinψ(e_φ cosχ+e_θ sinχ); ψ and χ are **radians**, χ periodic on [0, 2π). Layout/schema, tetrad, spin, inclination, package version/content hash and each bin's sha256 are mandatory header/manifest fields.

1. **Boundary/coefficient table:** 96 azimuths × 64 radius rows, F32 channels `(ψ_b, a_∥, a_⊥)`. ψ_b is an **angle**, found by analytic-capture bisection. At zero spin ψ_b = α_sh = asin[(3√3/2r)√(1−1/r)], not sin α_sh (spec §3); compare in radians at the AC-5 budget. Coefficients below share the boundary grid and periodic interpolation; pins include every channel.
2. **Regularised deflection table:** columns x = ln((ψ−ψ_b)/ψ_b) from ln 10⁻⁸ to ln((π−ψ_b)/ψ_b), 1536 columns × 96 χ × 64 rows y = ln(r−1), with **r in r_s**, r ∈ [2, 10⁶]. Let L = ln(tanh((ψ−ψ_b)/ψ_b)); define the unwrapped deflection angles δ_i ≃ −a_i L+b_i (i = ∥, ⊥). Fit a_i **at each (χ,r)** with refined near-boundary rays (Bozza 2003, strong-deflection expansion), store them in artifact 1, and store channels `(δ_∥+a_∥L, δ_⊥+a_⊥L)` in artifact 2. Reconstruct **δ_i = channel_i−a_iL** in package, CPU and GPU with the same coefficient interpolation. a_⊥ may be zero only if the oracle/refinement demonstrates it, never because twist was assumed finite. Unwrap before fitting/interpolation; wrap only the reconstructed sky direction. Test residual bounds and stability as the near-boundary cutoff shrinks and resolution doubles, plus independent outgoing-direction accuracy at AC-5 budgets; finite samples alone do not demonstrate regularisation. If either channel fails, STOP before pinning; a raw 4096-column schema is only a reviewable fallback requiring new size, convergence and accuracy evidence.
3. **Metadata manifest and JSON headers** like M3's (layout, ranges, generator step, formula/source versions, coefficient fit/cutoff/error provenance, hashes); pins committed in `data/lens/SHA256SUMS`. Bins are pinned, fetched from the public bucket by `make kerr-assets` (D-18), never committed. A missing coefficient channel invalidates the whole set.

**Size and cost.** The two-channel F32 deflection map is ≈75 MB; the three-channel boundary/coefficient map is small beside it. F16/resolution reductions require measured accuracy. V35's arithmetic gives **9,437,184 rays**, **19.2 CPU-hours** using the optimistic 5 s/2048-ray anchor, and **36.0 CPU-hours** using M3's full 40 CPU-min/2048×256 anchor and an assumed 3× ray cost **[CPython arithmetic extrapolation, not a Kerr timing]**. Budget from the latter until K1.2-a measures its bounded 400-ray shard with CPU/wall/memory provenance; root events and coefficient fitting may raise it. No promised sharding wall time. Full regeneration is manual (`make kerr-lut`); tests fetch existing pins and never trigger full generation.

`make kerr-lut-check` follows the plan's exact sample set: χ indices [0,24,48,72], radius rows [0,32,63], columns 0…1535 step 64 plus 1535; assert the count, compare F32 bytes to pins, and compare one full χ=0/rindex=32 row on strict VM and interpreter by `cmp`. Audit every boundary/coefficient/deflection texel for finiteness. Require 0 < ψ_b < π, periodic seam continuity (value and interpolated slope within the stored error budget), and equatorial reflection ψ_b(χ,r) = ψ_b(−χ,r) within that budget. At zero spin it is constant in χ and agrees with Synge. **No strict monotonicity in χ or blanket radial monotonicity:** for nonzero spin compare the radial trend to independent capture probes; only assert a monotone trend where those probes establish one. The range and seam tests load pinned, fetched bins. Regeneration equality, physical accuracy and regularisation convergence are separate gates.

**a = 0 regression.** Independently generate at zero spin and compare to M3's pinned, fetched forward-table values on its probe set within AC-5 (1.2e-4 rad at r ≤ 100; 1e-3 relative above). Carter and Binet are independent derivations; do not implement the test by copying M3 bins. GR16 carries the reduction into the shader.

### K1.3 CPU mirror `physics/kerr.gd`

`class_name Kerr`, float64 scalars; boundary differences use float64 and hi/lo upload. Mirror the package's `load_tables`, `boundary`, coefficient reconstruction, `deflection -> {delta_par, delta_perp, captured}`, frame/frequency `compose`, and Bardeen far anchors. Tests in companion `tests/test_kerr_physics.gd` are invoked by a "Kerr (spec §3b)" delegation from `tests/test_physics.gd` and `make physics`: every RK fixture, far-row Bardeen agreement within 1e-4 rad, whole-range/seam tests, 10,000 deterministic package-integrator probes at AC-5 budgets, independent frame checks V33 and the s = 0 RS reductions. A test-only diagnostic can transform the boundary to a **static** observer for GR13/14; it must not compare a static render directly with unboosted ZAMO angles.

### K1.4 Sim and protocol (pure core; additive)

`GrState` gains `spin: float` and `orbitDir: string` ("pro"|"retro"); **`bh_spin`** joins the hole-only scenario parameters. Absent spin on legacy `sgr_a` remains 0; new `kerr_demo` exists only at the Kerr minor and supplies scenario default 0.9 (D-107 A). At that minor, a numeric spin outside finite [0,1) answers `bad_spin` without state change; a nonnumeric schema value answers `bad_params`. Other scenarios reject hole parameters as `bad_params`. The table cap is separate from the metric domain; no clamping. Preserve the pre-Kerr decoder behind a minor-aware dispatch so even explicit zero is still `bad_params` below Kerr. Modes stay hover/orbit/approach, ship-proper-time driven, package rates only; spin zero branches to **all existing** sim GR arithmetic and encoding before invoking Kerr helpers.
- Hover: `staticClockRateKerr(u, θ, s)` — on the equator this is today's √(1−1/r_{r_s}), so the s = 0 bytes are unchanged. Static hover exists only outside the static limit; release 1's hover domain [2, 10⁶] r_s (row V18) is entirely outside the equatorial static limit (r_s) for every s < 1, so no domain change is needed; the domain check still runs (defence at future polar/equatorial-domain changes) and answers `bad_gr`.
- Orbit (DI-06): at the Kerr minor, **absent `dir` with s = 0 executes legacy `IGrOrbit`**, unchanged; explicit `"pro"` or `"retro"` with zero spin is refused `bad_gr`. With s > 0, omission defaults to pro; either explicit sense is accepted, and any other string/type (including null) answers `bad_gr` without executing that intent. Below the Kerr minor retain the pristine decoder's behavior, including its ignoring extra `dir` keys; do not retroactively validate them. Equatorial circular orbits use package Ω, clock and signed ZAMO velocity. The unchanged [2,10⁶] r_s floor is above both photon orbits (RK-5); `orbit_stable` is r ≥ ISCO(dir), and unstable circular orbits remain commandable. At s = 0.9 the prograde ISCO is only a readout below the floor, all allowed prograde orbits are stable, and the retrograde band below its RK-7 threshold is unstable.
- For **s > 0 only** at the Kerr minor, additive `gr` fields: `spin`, `horizon_r`, `ergosphere_r`, `photon_pro_r`, `photon_ret_r`, `isco_pro_r`, `isco_ret_r`, `frame_drag_s`, `orbit_dir`, `orbit_clock`, `zamo_lapse`, `zamo_omega` (c³/GM), `zamo_h` (GM/c²), `velocity_zamo` (three local tetrad components), `gamma_zamo`, `one_minus_beta_zamo`. Radii are r_s; `frame_drag_s` is rad/s. Each number comes from the package. Existing `beta_local`/`dir_local` keep their **static-observer** meaning (zero hover, static-relative orbit speed, commanded radial approach); never feed them to a ZAMO table. Package boost conversion supplies the new ZAMO fields. Existing `static_clock`/`blueshift` remain static-observer quantities, and `ship_clock` includes motion. Existing numeric tide fields carry ship-frame package values, not null; STOP rule above applies. The asymmetric shadow comes from the tables; the legacy scalar `shadow` is retained as the zero-spin RS reference at the same r for codec compatibility and is not used as the Kerr mask or shown as a Kerr radius.
- **Protocol minor: no hard-coded minor; the next free integer when K1.4 lands.** On `origin/main` `23928d01`, 2.3…2.12 are taken, **13 = surfaceMinor** (#302 merged), **14 reserved for similar-worlds S0.2**, **15 = archiveMinor** (#314 merged; `archiveMinor() == surfaceMinor()+2`). Next free today is **16**, an observation, not a reservation (V12/V13). Only hello from the Kerr minor reports $V; freeze all older hello pins and streams before package-pin/decoder edits (plan K1.4-a).
- **DI-15 stream contract:** let B be the recorded pristine integration-base SHA immediately before K1.4-a edits, P its highest pre-Kerr minor, and K the actual `kerrMinor()`. For every previously supported minor m < K, identical input NDJSON (seed, scenario, params, dtau, intents) must give byte-identical complete output NDJSON between B@m and candidate@m, **including hello and refusals**, not parsed/normalised JSON. This includes `bh_spin:0` being rejected `bad_params`; it does not require that rejected request to start a game. Freeze inputs with absent spin and requests with explicit spin separately, preserving ordering/numeric formatting. For legacy `sgr_a`, candidate@K with absent spin **or explicit `bh_spin:0`** and no new intent fields must equal B@P on the **equivalent request with `bh_spin` removed**, for every output line **except hello**. No other input/line normalization is allowed. Suppress **all** Kerr-only `gr` keys, do not echo `bh_spin`, and use legacy arithmetic/encoder at zero spin. Above-K requests negotiate K; a new `kerr_demo` or explicit handedness is not part of the equivalent-legacy comparison. Test both old decoder refusals and new zero-spin success; never re-record old expected bytes to hide drift.
- A new fixture `tests/fixtures/grk.ndjson` (every new field, both orbit directions, every refusal) under a new `make parity-grk`, VM/interpreter byte-identical.

**Asset availability (DI-09):** before drawing a nonzero-spin GR view, bridge/loader must match the **exact binary64 scenario spin**, equatorial inclination, schema/tetrad version, package version/content hash and all expected sha256 pins to one complete manifest. No nearest spin, rounding of the lookup key, partial set or Schwarzschild fallback. For unsupported/missing/corrupt assets (including s > 0.998), keep numeric sim state/readouts intact and set client state `kerr_visual_state = "unavailable"` with reason `unsupported_spin`, `missing_assets` or `asset_mismatch`; hide the GR sky/star layer and show a view-unavailable HUD state. This is a client asset status, not a nullable sim physics field. Revalidate/clear on scenario exit and restore the normal sky; tests cover all three reasons and a valid exact match. The sim has no filesystem dependency. Numerical fields cannot ship before the tide STOP gate closes.

### K1.5 GPU (`sky/kerr.gdshaderinc`, branch in the existing shaders)

A new include mirrors K1.3; nonzero spin dispatch requires the exact asset match above. Zero spin keeps the existing shader. Inverse-aberrate the ship pixel into **ZAMO** using sim `velocity_zamo`/γ/complement; derive ψ,χ there, bilinear boundary capture, then reconstruct both coefficient-regularised lens channels. Use M3's Catmull-Rom radius and cot(ψ/2) within-column weighting with periodic χ. Sample the sky at the outgoing direction. Compute λ from the same ZAMO ray and use **g_total = γ_Z(1+v_Z·n_Z)(1−ωλ)/N**, not static blueshift × ZAMO Doppler; mirror only the package transport functions. No shader work before the K1.0 frame contract and K1.1b-c oracle pass. **Stars:** suppress both orders and rings for nonzero spin; diagnostic counts are explicit and the HUD indicates catalogue unavailability. The panorama provides the sky. New goldens (`--golden=grk` in `make golden`, Studio GPU):

| # | Case | Expected (CPU reference) | Tolerance |
|---|---|---|---|
| GR13 | Static hover, s = 0.9, equatorial, r = 10/5/3 r_s; sampled black-mask boundary | CPU boundary **boosted from ZAMO to the same static observer** | 0.75 px |
| GR14 | Finite-r half-width asymmetry and pinch sense in GR13; separate infinity/far-row case | At 10/5/3 use finite-r CPU boundary in the same frame/projection. At infinity use 0.41211167869793890 [Decimal60, V32], prograde pinched; far row must converge to it | 0.005 absolute; retain GR13's 0.75 px |
| GR15 | Twist: fixed marker pixels near the prograde edge against the CPU mirror's δ_⊥ | `Kerr.deflection` channel G | ≤ 1 px at the golden scale |
| GR16 | s = 0 through the Kerr path at r = 10, 5, 3 (the a = 0 reduction on the GPU) | f·tan α_sh (M3's GR1–GR3 values) | 0.5 px |
| GR17 | Acting mutants: boundary/capture and its χ seam → GR13; twist coefficient/channel/χ wrapping → GR15; deflection-only within-column, first/last-radius and reconstruction rules → outgoing-direction float probe (also GR15 where it moves the marker) | Each deliberate mutation must fail its named probe, then restore green; a changed mask is not required for a deflection mutant | GR13 0.75 px; GR15 ≤1 px; float probe 1.2e-4 rad at r ≤100, 1e-3 relative above |

No absolute closed form exists for the shadow silhouette at finite r in Kerr; the absolute anchors are RK-14–RK-17 on the far rows (r = 10⁶) checked in `make physics`, RK-Q1 at s = 0 everywhere, and the GPU-vs-CPU goldens in between. That stack is stated honestly here rather than faked with an infinity formula at 3 r_s.

### K1.6 Demo, HUD, renders

- Scenario **`kerr_demo`**: Sgr A* mass (4.297e6 M☉, `sim/gr.ail`), `bh_spin = 0.9` from resolved OQ1 / D-107 A. Enter at 10⁶ r_s, approach to 10/5/3 r_s, hover, orbit prograde then retrograde. The floor stays 2 r_s. RK-7's prograde ISCO lies below it and is a readout only; at r = 3 r_s, prograde is stable and retrograde is unstable. Show retrograde stability by moving above its RK-7 threshold. These comparisons use package radii; rounded captions are not branch thresholds. A second 10 M☉ scenario is far-view data only; this milestone does not implement a close stellar-mass encounter.
- HUD additions (sim fields only, sentinel-tested as today): spin; "ergosphere (equator) at 1.00 r_s — no observer can stand still inside"; frame dragging ω in rad/s; the two ISCO radii with the current orbit's handedness and stability; "1 ship-hour = N home hours" from `orbit_clock`/static clock as today.
- `make capture-bhk`: renders at 10/5/3 r_s toward/side/away in hover and both orbit directions, debug grid and Milky Way sheets, a `bhk_manifest.sha256` pinned in `data/refs/` (the M3.6 pattern), `make bhk-render-diff` (rig), and the report records who opened them.
- Archive events unchanged (`bh_enter`/`bh_hover`/`bh_ring`; the ring event never fires at s > 0 since ring stars are off); lore text edits are a follow-up, not this milestone.

## Acceptance criteria

From the game root set `A="$PWD/runtime/bin/ailang"` **before any cd**; use `"$A"` for every package command. `$PKG` is an absolute separately authorized package checkout's `packages/relativity`; `$D` is the absolute design checkout; `$V` is the approved release (planned **0.14.0**; 0.13.0 is source-only, registry latest 0.12.0, V29). Commands below are **future acceptance gates**, not results of this document revision. NEW targets named in the plan do not exist yet. Controller owns whole-package/full-game, install/lock, GPU, network and publication commands; K1.1a execution uses its named single-file tests and stops before publish. Socket/GPU attempts that fail inside the sandbox are **UNINFORMATIVE UNDER SANDBOX**, never an AC pass/fail.

| # | Criterion | Command |
|---|---|---|
| AC-K1 | Controller package check/tests pass, precise RK fixtures at stated tolerances, display rounding separately, RK-Q1 legacy dispatch | `(cd "$PKG" && "$A" check --package . && "$A" test --package .)` |
| AC-K2 | Quality clean without gates and dry run; **separate** Mark version/content approval then controller publish/export/hash verification | Preapproval: `(cd "$PKG" && "$A" pkg quality . && "$A" publish --dry-run)`. Only after Ppublish: `(cd "$PKG" && "$A" publish)` then `"$A" pkg info sunholo/relativity \| grep -E "$V\|kerr"`; record immutable content hash |
| AC-K3 | `kerrDigest 16` strict VM/interpreter `cmp`; within 1e-9 of independent oracle; every RK, frame transform and verified tide reproduced | `(cd "$PKG" && "$A" run --quiet --bytecode --strict-bytecode --entry kerrDigest --args-json 16 _smoke.ail > /tmp/kerr-strict.txt && "$A" run --quiet --entry kerrDigest --args-json 16 _smoke.ail > /tmp/kerr-interpreter.txt)`; `cmp /tmp/kerr-strict.txt /tmp/kerr-interpreter.txt`; `make kerr-oracle AILANG="$A"` |
| AC-K4 | The game pins $V; lock consistent; the hello reports it from the Kerr minor and keeps older pins frozen | Controller `grep "\"$V\"" sim/ailang.toml && make deps hello-pin AILANG="$A"` |
| AC-K5 | Record merged spec SHA/PR before K1.1b-c/K1.5; precise §3b RK assertions delegated through `tests/test_physics.gd` | With reviewed merged `SPEC_SHA`: `git -C "$D" show "$SPEC_SHA:physics/relativity-spec.md" \| grep -n 'RK-'` and `make physics AILANG="$A"`; grep alone does not prove merge disposition |
| AC-K6 | Specified sample bytes and full-row strict/interpreter cmp, every texel finite, angle/seam/reflection/zero-spin checks, coefficient reconstruction and cutoff/resolution convergence at AC-5 accuracy | `make kerr-lut-check kerr-tables-test physics AILANG="$A"` |
| AC-K7 | Independent s = 0 tables match M3 pinned, fetched bins on M3's probe set within AC-5 | `make physics AILANG="$A"` (RK-Q1 probes) |
| AC-K8 | Numeric package-valued fields/tides, V33 frame probes, omitted/explicit/invalid dir rules; both refusals preserve state; **all DI-15 byte comparisons**; exact-asset/unavailable bridge states | `make kerr-sim-test sim strict parity parity-gr parity-grk AILANG="$A"`; `AILANG_BIN="$A" godot --headless --path . --script tests/test_kerr_bridge.gd` (socket failure: UNINFORMATIVE UNDER SANDBOX) |
| AC-K9 | GR13 frame-correct silhouette, GR14 finite-r CPU asymmetry plus far/infinity RK-14, GR15 twist, GR16 zero spin, GR17 each acting mutant killed by its mapped probe | Controller `make golden AILANG="$A"` (`--golden=grk` included); `make kerr-mutation-test ROOT="$ROOT" AILANG="$A"` on isolated copy |
| AC-K10 | HUD sentinel injection; client guard with positive/negative controls; only package and approved mirrors compute Kerr quantities | `make kerr-hud-test kerr-client-guard AILANG="$A"` |
| AC-K11 | Reference manifest committed, images bucket-pinned, diffed, recorded opened by a person in report | Controller `make capture-bhk bhk-render-diff AILANG="$A"`; `grep -n "opened by" design_docs/implemented/r2/kerr-black-holes-report.md` |
| AC-K12 | Full game/fast tier and rig green; pure strict core; formulas only in package and approved mirrors | Controller `make test ci-fast AILANG="$A"`; `tools/rig_check.sh <PR> --golden`; `make kerr-client-guard AILANG="$A"` |

## Sub-milestones and estimates

| ID | Scope | LOC (code + tests) | Depends on | Order | Duration |
|---|---|---|---|---|---|
| K1.0 | Spec §3b/RK/§4 PR, **parked for Mark**, not autonomous execution | 0 (+~150 doc lines) | P0 disposition and K1.1a-a precise oracle provenance; draft may start earlier | Mark merges before K1.1b-c and any K1.5 work; not first prerequisite for K1.1a | ≤1 active day; review wait excluded |
| K1.1a | Five slices a–e: independent oracle first, closed forms, exact zero dispatch, scalar precision contract; **stop before publish** | 350 + 300 | D-107 A, this revision and re-quorum; no K1.0 merge dependency | 1: K1.1a-a then b/c/d/e | 2–3 active days |
| K1.1b | Five slices a–e: shadow/capture/full Carter/frame transport/tides/digest | 380 + 330 | K1.1a; K1.1b-c also K1.0 merged; DI-10 STOP applies | 2; independent evaluation before K1.1p | 3–4 active days; re-split if needed |
| K1.1p | Release $V (0.14.0 planned): CHANGELOG, AGENT.md, `[release] kind`, quality/dry-run/publish (**Mark's explicit go**, as M3.1p) | 120 | K1.1b evaluated PASS + Mark | 3 | ≤ 1 day |
| K1.2 | Three slices a–c: generator/coefficient schema, byte IO/assets, reproduction/finite audit | 260 + 150 | K1.4-a freeze/published pin first, K1.1b-c, K1.0 | 4 | 3–4 active days + measured generation |
| K1.3 | Four slices a–d: CPU mirror, frame composition, RK delegation, range/probe closure | 230 + 230 | K1.0, K1.2 | 5 | 2–3 active days |
| K1.4 | Four slices a–d: pristine freeze/pin, pure rates, codec/dirs, bridge/parity | 230 + 250 | a after K1.1p and before K1.2; b needs verified K1.1b-d tides; c/d after b | a first, then b/c/d may overlap table generation | 2–3 active days |
| K1.5 | Four slices a–d: harness, shader, star/asset status, mapped mutants/render review | 320 + 240 | K1.0 merged, K1.3 and K1.4 complete | 6; Prender5 before K1.6 | 3–4 active days (GPU half-rate) |
| K1.6 | Three slices a–c: `kerr_demo`/HUD, captures/provenance/diff, report/landing | 190 + 130 | K1.4, K1.5, Prender5; landing after Prender6 | 7 | 2–3 active days |
| | **Total** | **≈2,080 + 1,630 ≈3,710** | Nine parents / 30 plan slices | Headless work only after re-quorum; spec/publish/render gates retained | **30 working days, about six weeks** |

The existing plan is the decomposition: K1.0 one slice, K1.1a five, K1.1b five, K1.1p one, K1.2 three, K1.3 four, K1.4 four, K1.5 four, K1.6 three. Its mutation slices cap at 150 total LOC; other implementation slices stay below 250. Re-split oversized physics work without omitting φ, transformations or tide checks. The six-week budget replaces the optimistic three-to-four-week header; individual table durations are active effort allowances, not a summed calendar promise. P0's direction/OQs are settled by D-107 A; this revision plus the required re-quorum supplies the DI disposition. It is not a fabricated quorum pass. K1.0 remains parked for Mark; Ppublish, Prender5/6 remain separate gates. Plan/JSON state is historical and unchanged by this doc.

**F6 integration risk:** the sprint JSON has `sprint_plan` (a path) and `parent_milestones`, but no top-level `milestones`. Consumers must explicitly validate its actual `features`/`parent_milestones` schema and nonzero counts, or STOP before scheduling; missing-key defaults must not create an empty successful sprint. V37 checks the current shape. Do not rewrite the plan or JSON as part of this revision.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Regularisation coefficient or angle chart fails convergence | Store both channel coefficients, cutoff/fit provenance and the exact reconstruction contract; refine cutoff/resolution and check directions, not only finiteness. STOP before pins on failure; raw 4096 columns requires reviewed schema and accuracy evidence |
| F3: table cost / schedule optimism | V35 extrapolates 19.2–36.0 CPU-h from differing M3 anchors, not measured Kerr performance. Budget 36 CPU-h before fitting overhead, measure 400-ray shard in K1.2-a, and re-estimate the six-week plan if needed. Reduced columns/azimuths/F16 must pass the same probes; full generation stays manual |
| Protocol-minor collision | V12/V13 refresh main through 15 with 14 reserved; 16 is next free today, never hard-coded. Recheck allocations at K1.4-a; freeze pristine source SHA, all old negotiated hellos and streams before edits |
| VM/interpreter divergence in long Carter integrations (the M1/M3 history) | `cmp` gates in AC-K3/K6, no tolerance; shrink and report upstream per CLAUDE.md |
| Sign-convention errors (prograde pinched side, α sign, handedness of Ω) | RK-14's asymmetry magnitude *and* sense are normative; GR14 fails a mirrored implementation; the a = 0 reductions fix every other axis |
| DI-10: spinning tides cannot be independently verified | **STOP for Mark** before completing K1.1b-d/K1.4-b or publishing K1.1p. No null tide, no substituted Schwarzschild number, no relaxation of G4/AC-K8. Keep numeric ship-frame values mandatory; a scope amendment would need an explicit new decision only if this execution gate fails |
| Near-extremal cancellation (Δ, √(1−s²), λ/η) | Scalar s only, accuracy relative to represented input and guaranteed at reference spins ≤0.998, factored forms and endpoint tests; higher-spin metric readouts need domain/finiteness/tide validation and cannot enable mismatched rendering |
| Starless Kerr sky judged thin | Deliberate cut, caption on the HUD; the debug-grid goldens exercise the lensing hard; Kerr star images are release-2 work with their own design |
| Scope creep toward the emergence scene | Held out by the non-goals and OQ3; the inside-ergosphere domain is a different table and a different sim frame (no static observers), not a flag flip |
| A different spin is requested later | Spin is scenario data (`bh_spin`); regenerate and validate an exact matching table set at measured cost. Renderer/HUD never hard-code the demo spin |
| F6: tooling expects nonexistent top-level `milestones` | Validate actual JSON `features`/`parent_milestones` arrays and nonzero counts before scheduling (V37); fail on schema mismatch. Controller handles any later adapter/plan state update; no JSON edits here |
| Frame/asset mismatch produces a plausible but wrong sky | ZAMO tetrad/version is part of manifest identity; V33 plus independent transport checks precede mirrors. Missing/wrong assets show explicit unavailable view; preserve numeric sim state, never substitute another spin |

## Open questions for Mark

All five are **resolved by D-107 A**, Mark attended 2026-10-21 (V36), not unanswered defaults:

1. **OQ1 — Resolved:** spin s = **0.9**, scenario data; keep scalar APIs parametric. Any canon recording remains a separate Mark-owned design-repo change.
2. **OQ2 — Resolved:** equatorial observer only for release 1. RK-17's 45° calculation is a package arithmetic test, not another rendered table set.
3. **OQ3 — Resolved:** visit demo only; no emergence scene yet.
4. **OQ4 — Resolved:** no superradiance or energy extraction.
5. **OQ5 — Superseded by approval:** headless slices become scheduled autonomous work in the 2026-10-20 order after this revision and one re-quorum. K1.0 stays parked for Mark; K1.1a package maths stops before publish. Direction and the two zero pillar scores are approved; the old plan-only recommendation no longer governs this work.

**New open questions: none.** DI-10 is a conditional execution STOP if the tide oracle fails, not an unresolved scope choice today. This pass neither claims a new quorum verdict nor executes package/GPU work.

## Design-repo changes this needs

Separate PRs, none written by this revision: (a) §3b/§4/§7-RK in `physics/relativity-spec.md`, **K1.0 parked for Mark**, final provenance after K1.1a-a, merged before K1.1b-c and visual work; (b) feature/non-goal/roadmap status changes at landing; (c) any recording of D-107 A's spin ruling in the design repo is Mark-owned. This doc adds no lore or canon text.

## Deliverables

- **This doc revision only.** Existing sprint plan and JSON remain unchanged historical artifacts; controller owns their eventual synchronization with D-107 A and this DI disposition.
- On execution: `sunholo/relativity@$V` with module `kerr` (RK test set, `kerrDigest`, CHANGELOG, AGENT.md); the three lens artefacts with pins and `make kerr-assets/kerr-lut/kerr-lut-check`; `physics/kerr.gd` + the spec §3b section of `tests/test_physics.gd`; the sim spin parameter, protocol fields and `tests/fixtures/grk.ndjson` with `make parity-grk`; `sky/kerr.gdshaderinc` and goldens GR13–GR17; the `kerr_demo` scenario, HUD lines, `make capture-bhk` renders with a pinned manifest and a report naming who opened them; the design-repo changes above.
- **Report:** `design_docs/implemented/r2/kerr-black-holes-report.md` at landing.

## Quorum log

- **Round 1 (2026-10-21, author `pi:ollama/kimi-k3:cloud`, its vendor benched): BLOCKED, PROCEED-impossible at N−2.** Present: `gemini-4-argon` REJECT. Absent: `claude-sonnet-5@claude-p` (quota), `gpt6-1-sol` (unreachable), `oc-glm-5-3` (invalid: hit its 65,536-token output cap with no verdict). Objection (one surface, K1.1 units): make every exported radius state `r_s` or `M`; it also claimed `photonOrbitPro/Ret` was off by a factor of 2. **Measured by the controller (row V30): the factor-2 claim is false** (the formula already returns 1.5 r_s at s = 0 and 0.778927 r_s = 1.557855 M at s = 0.9, RK-4), but the requested explicitness is right: `horizonInnerR` had no formula and the ISCO bullet left the `/2` from `GM/c²` implicit. The reviewer's proposed bullets were applied verbatim (they do not dispute the direction).
- **Round 2 (2026-10-21, same seats): BLOCKED.** Present: `gemini-4-argon` REJECT on a different surface (K1.4/K1.6): the s = 0.9 prograde ISCO (1.1604 r_s) lies below the unchanged 2 r_s sim and table floor, so the demo cannot orbit there. Absent again: `claude-sonnet-5@claude-p` (quota), `gpt6-1-sol` (unreachable), `oc-glm-5-3` (invalid a second time at its 65,536-token output cap: a durable named absence, not re-run). **Narrow-refinement carve-out:** the sole remaining objection carries a reviewer-authored fix and does not dispute the direction, so its text was applied verbatim to K1.4 and K1.6 (the demo contrasts pro and retro stability at 3.0 r_s; the prograde ISCO is a readout) and the doc went to the planner without a third round. Effective review: one external reviewer present in both rounds; this doc has had no OpenAI, Anthropic or Z-AI review.
- **Round 3 (2026-10-22, iteration 45, after the D-107 A revision; author `codex:gpt-6.1-sol`, OpenAI benched): BLOCKED.** Seated `claude-sonnet-5@claude-p`, `gemini-4-argon`, `oc-glm-5-3`; reserve `oc-kimi-k3`. Absent: `claude-sonnet-5@claude-p` (`quota`: the mission ration's Anthropic usage probe returned HTTP 429 and its CLI fallback found no session line, so this is a capacity absence, not a review). Present, all REJECT, each with a concrete fix and none disputing the direction; surfaces: `gemini-4-argon` K1.1 frame contract (boost convention, Wigner rotation); `oc-glm-5-3` the pillar table's numbers and K1.2/K1.5 evidence for M3's encoder and interpolation; `oc-kimi-k3` the status header and the round-2 carve-out's source, V2, the 0.0927 clock. **Narrow-refinement carve-out, controller-applied 2nd revision:** glm's three fixes verbatim (V22 tide, RK-8b row V40, rows V41/V42; K1.2 reworded because the encoder is `encodeF32LE` in `lens_lut_main.ail`); kimi's V2 and clock fixes verbatim, its carve-out search as V39, and its status text applied with Mark's D-107 condition named (the round-2 history above is kept as it happened, not rewritten); gemini's single-pure-boost rule and approach ray applied with the inverse-aberration sign taken from spec §2 (its literal formula is the forward form; V43). **D-107 A's reviewer condition is still unmet**, so nothing is scheduled (Status).

## Verification log

Historical rows are from 2026-10-21, game `8d17f90b` / design `864a4e4`; their abbreviated commands are inherited evidence, not newly rerun measurements. V12/V13/V29 are refreshed from **controller verification, iteration 45**, with local source cross-checks at `4dee08e5` / main `23928d01`. V31–V35 are new **independent scratch oracles**, CPython Decimal precision 60 or binary64 as labelled, with no package imports or tracked Python file. Their full source and exact output are below. The design repo and GR code were read only. No game/package suite or GPU test ran. The worktree lacks `runtime/bin/ailang` (`no such file or directory` on local version attempt); the v0.54.14 pin remains controller-verified, not a local runtime result. Network/GPU sandbox failures are UNINFORMATIVE UNDER SANDBOX.

| # | Claim | Command | Observed |
|---|---|---|---|
| V1 | Historical charter R2 was plan-only; D-107 A now governs headless work | `rg -n '^\| R2 \|' design_docs/stapledon-mission.md` | Original row retained in charter; approval supersedes its old parked status (V36) |
| V2 | The pinned binary is v0.54.14 | `runtime/bin/ailang --version` | controller-verified (historical, iteration-43 evidence); local attempt: no such file or directory. Iteration 45 controller, main checkout's staged runtime: `AILANG v0.54.14` |
| V3 | The game pins `sunholo/relativity` 0.12.0 | `grep -n "relativity" sim/ailang.toml` | line 20: `"sunholo/relativity" = "0.12.0"` |
| V4 | The package has no Kerr content (with control) | `R=~/.ailang/cache/registry/sunholo/relativity/0.12.0; grep -ri "kerr" $R/*.ail $R/*.md \| wc -l; grep -ri "schwarzschild" $R/*.ail \| wc -l` | kerr: **1** (the `AGENT.md` exclusion line); schwarzschild: **21** — the search can find things |
| V5 | The package's AGENT.md excludes Kerr | `grep -n "Kerr" $R/AGENT.md` | line 29, under "Do NOT use it for": `- Rotating (Kerr) black holes.` |
| V6 | The spec has no Kerr section (with control) | `grep -ci "kerr" ../stapledons-design/physics/relativity-spec.md; grep -ci "schwarzschild" …; sed -n 63p …; sed -n 149p …` | kerr: **0**; schwarzschild: 1; line 63 `## 3. General relativity (Schwarzschild; the black-hole feature)`; line 149 `## 7. Check-value index` (ends RS-23/RS-Q4) |
| V7 | Canon: every run emerges from the ergosphere of a spinning hole | `sed -n 14p ../stapledons-design/vision/premise-and-loop.md; sed -n 1331,1332p ../stapledons-design/vision/design-decisions.md` | line 14 "emerges violently from the ergosphere of a spinning black hole: the same rogue black hole that is heading for the Solar System"; design-decisions line 1331 "Every run starts at emergence from the rogue black hole …" |
| V8 | The roadmap calls Kerr future work | `grep -n -i "kerr\|spin" ../stapledons-design/roadmap/r1-foundations.md; sed -n 167,168p …` | line 32 (M3 row): "…Kerr rotation remain[s] future work"; lines 167–168: "spin (Kerr) and the true Galactic-Centre sky are follow-ups" |
| V9 | No Kerr code in the game (with control) | `git grep -i "kerr" \| wc -l; git grep -i "schwarzschild" \| wc -l; git grep -i "kerr" -- "*.gd" "*.ail" "*.gdshader"` | 27 vs 247 hits; the only code-tree kerr hits are the substring "kErr" inside "playbac**kErr**or" in `ai/tools/` (an audio verifier, unrelated); the rest are docs/state prose (M3 doc and sprint, mission charter, roadmap, eval JSONs) — no Kerr physics anywhere |
| V10 | M3's GR stack is on main | `ls sim/tools/lens_lut*.ail physics/schwarzschild.gd sky/gr_lens.gd sky/*.gdshader* demos/black_hole_visit.gd tests/test_physics.gd tests/fixtures/gr.ndjson tools/geodesic_ref.py` | all present; also `sky/background.gdshader`, `sky/schwarzschild.gdshaderinc`, `tools/gr_golden.gd` |
| V11 | Goldens GR1–GR12 exist; RS check rows asserted | `grep -n "GR1…GR12" tools/gr_golden.gd; sed -n 1232,1236p tests/test_physics.gd; grep -n "M3.5: GR1-GR11" Makefile` | gr_golden.gd header covers GR1-GR9, GR10, GR11, GR12; test_physics.gd lines 1232–1236 assert Synge RS-10..13 (14.269027328/27.694561451/45.0/90.0); Makefile's golden comment names GR1-GR11 (GR12 is the mutant case in gr_golden.gd) |
| V12 | Current protocol allocations, controller-verified iteration 45 on origin/main 23928d01 | Controller command `grep -n 'Minor() *=' sim/*.ail`; source-signature cross-check `rg -n 'func .*Minor\(\).*=' sim/protocol.ail` | system 3, nav 4, departure 5, GR 6, stops 7, ism 8, crew 9, interlude 10, console 11, homeTiers 12, **surface 13**, **archive 15**; 14 reserved, next free today **16**, selected again at K1.4-a |
| V13 | Refresh inherited PR/minor evidence (F7) | `rg -n 'surfaceMinor|archiveMinor|Minor 14' sim/protocol.ail bridge/sim_bridge.gd sim/archive_health_test.ail`; controller PR source checks for #302/#314 | **VERIFIED BY CONTROLLER, iteration 45:** #302 R2-STAR-SURFACES merged at 13; #314 Archive memory health merged at 15; archive test asserts `archiveMinor() == surfaceMinor()+2`; S0.2 reserves 14 and has not landed. Local files confirm allocations. Historical gh TLS failure was **UNINFORMATIVE UNDER SANDBOX**, not PR-state evidence |
| V14 | The sim GR mode composes the package; holes are scenario data | `sed -n 3,10p sim/gr.ail; sed -n 54p sim/gr.ail; sed -n 67p sim/gr.ail; sed -n 157p sim/gr_test.ail` | lines 4–9 (the module comment): "…A non-spinning hole (D-13, D-53: Sgr A* by default, the mass a scenario parameter)… this module composes them and does no physics of its own"; line 54: `sgrAMassMsun() -> float = 4297000.0`; line 67: "(bh_mass_msun, bh_r), so another hole (the canon's rogue hole) is data, not code"; gr_test.ail:157 runs `"params":{"bh_mass_msun":10,"bh_r":2500}` |
| V15 | The GPU upload layer does no physics | `sed -n 7,13p sky/gr_lens.gd` | "No physics is computed here: the per-r scalars … are the CPU mirror's …, and the shadow angle goes up as a float32 hi/lo pair of the sim's float64 value" |
| V16 | The GR sky lives in a `gr_on` branch of the shipped shaders | `grep -n "gr_on\|schwarzschild.gdshaderinc" sky/background.gdshader sky/starfield.gdshader` | background.gdshader lines 13/28 (`#include`), 108, 146 `if (gr_on)`; starfield.gdshader line 9 documents the same include |
| V17 | M3 table format, pins and cost anchor | `head -3 data/lens/lens_fwd.json; head -5 data/lens/SHA256SUMS; grep -n "15 min on 16 cores" Makefile` | 2048×256×2ch F32, h = 0.0025, generated by the package's `geodesic.lensRegular` v0.10.0, sha256-pinned bin fetched from the public bucket; Makefile line 850: fetched "in seconds, else regenerated on the VM (~15 min on 16 cores)" |
| V18 | The sim's hover range is [2, 10⁶] r_s | `sed -n 83,84p sim/gr.ail` | `grMinR() -> float = 2.0`, `grMaxR() -> float = 1000000.0` (D-13) |
| V19 | The date | `date "+%Y-%m-%d"` | 2026-10-21 |
| V20 | RK closed-form values (RK-1…13, RK-Q1 a = 0 members) | `python3 -c` (formulas as in K1.1: horizon, photon orbits, Z₁Z₂ ISCO, Ω, ZAMO lapse, u^t clocks; printed to 10+ digits) | r_+(s=0/0.5/0.9/0.99/0.998) = 2.0000000000/1.8660254038/1.4358898944/1.1410673598/1.0632139225 M; r_ph pro/ret s=0.9 = 1.5578546274/3.9102679391 M; ISCO pro/ret s=0.9 = 2.3208830418/8.7173522796 M (s=0.5: 4.2330025295/7.5545847145; s=0.998 pro 1.2369706552); Ω_H s=0.9 = 0.3133945031; ω(2M, eq) = 0.1601423488; ZAMO lapse there 0.3796420865; ISCO clocks 0.3708679444/0.7931925181; **a = 0: ISCO exactly 6.0 M, r_ph exactly 3.0 M, u^t at 6 M = √2** (dτ/dt 0.707106781187 = the package's `circularOrbitClockRate(3)`) |
| V21 | Historical shadow scan **superseded by independent V32** | `python3 -I /tmp/kerr45_oracle.py shadow` (full source below) | **Decimal60 polynomial-root endpoints:** s = 0.998 α_max = **6.9966662713999613 M**; RK-16 fixed discrete-u measure = **4.8770013845209779 M**. s = 0.9 endpoints, mean and 45° visible endpoints also recomputed in V32. The old scanned endpoint/mean and RK-17 extrema are withdrawn; no claim of exact endpoints from a grid remains |
| V22 | RK-18 conversions and the emergence tide estimate | `python3 -c` (IAU 2015 nominal GM_sun = 1.3271244e20; the package's `rsPerSolarMassMetres` = 2GM/c²) | 10 M☉: r_s = 29.532501 km (package's per-M☉ 2953.25008 m); s=0.9: r_+ = 21.202710 km; ergosphere equator = r_s = 29.532501 km; prograde ISCO = 34.270740 km, period 1.372762 ms; Ω_H = 6362.705900 rad/s; frame drag at the equatorial static limit 3251.297190 rad/s; **tide across the 100 m bubble at R = r_s, the `tidalAccelSI` form a = c² L r_s/R³ (Schwarzschild estimate at the ergosphere): 1.030483e10 m/s² ≈ 1.0508e9 g**; the v_Z formula's a = 0 member at u = 6 M is exactly 0.5 = the package's `circularOrbitSpeed(3)` |
| V23 | The 10 M☉ canon value this doc links | `grep -n "29.5\|10 M☉" ../stapledons-design/features/future/earth-fate-home.md` | line 135: "For the 10 M☉ rogue hole of premise §1: Schwarzschild radius r_s = 29.5 km; shadow radius (3√3/2) r_s = 76.7 km" (consistent with V22 to the canon's three figures) |
| V24 | Superradiance is parked future work in canon | `grep -n "superradi" ../stapledons-design/features/next/bubble-resources.md` | line 343 lists superradiance ("~4% per pass") as an energy concept needing "a mirror cavity around a black hole" — a future resource row, not a current mechanic |
| V25 | The M3 ruling parks Kerr for a later milestone | `sed -n 167p design_docs/stapledon-mission.md` | D-53 (RESOLVED, Mark 2026-10-08): "…with mass a scenario parameter so the canon's rogue hole reuses it; spin (Kerr) is a later milestone…" |
| V26 | Historical 2026-10-20 order; current authorization in V36 | `rg -n 'Order for the next armed run|^\| D-107' design_docs/stapledon-mission.md` | D-107 A schedules headless work in that order after revision/re-quorum; spec PR parked for Mark; package maths stops before publish |
| V27 | M3's pillar table shipped the same two zeros, and Mark approved | `sed -n 34,45p design_docs/implemented/r1/m3-black-holes.md` | lines 38–39 (Choices Are Final 0, The Game Doesn't Judge 0), line 45 Net **+7 Go**; its approval is the D-53 row (V25) |
| V28 | The M3 table-generation cost anchor | `grep -n "40 CPU-min\|436 s wall" design_docs/implemented/r1/m3-black-holes.md` | line 177 (as-built note): "…the full run is about 40 CPU-minutes at h = 0.0025… 436 s wall with 14 jobs on the Studio under heavy load" |
| V29 | Registry/source distinction refreshed (F7), controller-verified iteration 45 | Set absolute `A="$PWD/runtime/bin/ailang"` first; `"$A" --version`; `"$A" pkg versions sunholo/relativity`; `git -C /Users/voightkampff/dev/sunholo-data/ailang-packages show origin/main:packages/relativity/ailang.toml \| grep -m1 version` | **VERIFIED BY CONTROLLER:** runtime pin **v0.54.14**, registry latest **v0.12.0**, source `version = "0.13.0"` unpublished; Kerr still plans **0.14.0**, subject to fresh release check. Local read-only `git show` confirms source 0.13.0; registry not re-queried here, missing local runtime cannot verify it |
| V30 | K1.1's photon-orbit formula is already in `r_s` (controller, quorum round 1) | `python3 -I -c "import math; [print(s, 1+math.cos(2/3*math.acos(-s)), 1+math.cos(2/3*math.acos(s))) for s in (0.0, 0.9)]"` | `0.0 1.5 1.5`; `0.9 0.7789273137 1.9551339696` (× 2 = 1.557855 / 3.910268 M = RK-4) |
| V31 | DI-01 precise RK closed forms and SI conversions, independent oracle | `python3 -I /tmp/kerr45_oracle.py closed` | Complete output below (V31); all values **Decimal60**, formatted to 17 significant digits. Photon roots solve u(u−3)²−4s² = 0 on [1,3] / [3,4], independently of the acos implementation. RK table contains these fixtures |
| V32 | F1/F2: shadow roots, specified discrete mean, inclination extrema | `python3 -I /tmp/kerr45_oracle.py shadow` | Complete output below (V32), **Decimal60**. RK-16 includes all 200000 endpoints/equal-weight samples; RK-17 finds the visible-arc roots and maximises β², replacing grid truncation. These are independent recalculations, not evaluator digits |
| V33 | DI-07 frame conversion and ray frequency/direction | `python3 -I /tmp/kerr45_oracle.py frames` | Complete output below (V33), **Decimal60**. Equator u = 4, s = 0.9, source n_Z = (0.8,0,0.6) in (r,θ,φ); metric v = (Ω−ω)h/N, incoming photon λ = −hn_φ/(N−ωhn_φ), g = γ(1+vn_φ)(1−ωλ)/N. Static hover gives √2 independently of λ; pro/retro velocities have opposite signs |
| V34 | F4 clock evaluation form and zero-spin delegation | `python3 -I /tmp/kerr45_oracle.py clock` | Complete **CPython math binary64** outputs/hex below (V34); package source `schwarzschild.ail:49` uses `sqrt(1.0 - 1.0/r)`. These probes illustrate operation order; byte identity for all zero-spin calls is required by direct legacy dispatch, not inferred from four samples |
| V35 | F3 generation estimate cross-check | `python3 -I /tmp/kerr45_oracle.py cost` | Complete **CPython arithmetic** output below (V35): 9437184 rays, optimistic 0.00244140625 s/ray, 19.2 versus full-run-anchor 36.0 CPU-h with assumed 3× cost. Neither is a new Kerr timing |
| V36 | D-107 A is attended and resolves OQ1–5 | `rg -n '^\| D-107' design_docs/stapledon-mission.md` | RESOLVED, **ANSWERED — A (Mark, attended 2026-10-21)**: direction/OQs approved, revision and re-quorum required, then headless work scheduled; K1.0 parked for Mark and K1.1a stops before publish. No new quorum performed in this revision |
| V37 | F6 actual sprint schema (read-only) | `jq -e '(has("milestones") \| not) and (.sprint_plan \| type == "string") and (.parent_milestones \| type == "array") and (.parent_milestones \| length == 9) and (.features \| type == "array") and (.features \| length == 30)' .ailang/state/sprints/sprint_R2-KERR.json` | `true`, exit 0; nine parents and 30 features, no top-level milestones; plan/JSON left unchanged |
| V38 | DI-06/DI-15 existing codec and bridge, source-only | `sed -n '610,675p' sim/protocol.ail`; `rg -n 'gr_orbit\|IGrOrbit' sim/protocol.ail`; `sed -n '650,675p' bridge/sim_bridge.gd` | `inRange` knows bh_mass_msun/bh_r then false; decodeOverride → bad_params for bh_spin even 0. `gr_orbit` decodes fieldless IGrOrbit, ignoring extra dir. Bridge requires numeric old GR fields and duplicates the whole dictionary. No protocol run claimed |
| V39 | Source of the narrow-refinement carve-out used in round 2 (quorum r3, `oc-kimi-k3`) | `grep -n 'NARROW-REFINEMENT CARVE-OUT' <ailang>/.claude/skills/mission-control/resources/gate-2-pick.md`; `grep -ci 'carve-out' design_docs/stapledon-mission.md` | Iteration 45 controller: the rule is in the shared `mission-control` skill, `gate-2-pick.md:236` (added V1 iteration 95, first use ratified there). The charter has 5 mentions, all usage records in STATUS/ledger text, and **no** charter row or ledger decision authorising it. D-107 A's own condition (an Anthropic or OpenAI reviewer) is separate and unmet; see Status |
| V40 | RK-8b: prograde-ISCO orbit clock at s = 0.998 (quorum r3, `oc-glm-5-3`, `oc-kimi-k3`) | `python3 -I /tmp/kerr45_oracle.py closed` (source below, line `RK-8b`) | **0.092670308365368573** [CPython Decimal60]; the pillar table's 0.0927 rounds it. Reviewer glm's independent figure ≈0.09267 agrees |
| V41 | M3's lens-table F32 encoder (quorum r3, `oc-glm-5-3`) | `git grep -n 'encodeF32LE' -- sim/tools/lens_lut*.ail` | Iteration 45 controller: `sim/tools/lens_lut_main.ail:16` imports `std/embedding (encodeF32LE)`, `:42` encodes each row; `catalogue_bytes.ail:16` uses the same stdlib function for the star catalogue, so K1.2 now names the lens-table call site, not `catalogue_bytes` |
| V42 | M3's interpolation: Catmull-Rom across rows, cot(ψ/2) within a column (quorum r3, `oc-glm-5-3`) | `grep -n -iE 'catmull\|cot\s*\(' sky/schwarzschild.gdshaderinc` | Iteration 45 controller: rule comments at `sky/schwarzschild.gdshaderinc:14` (weight linear in cot(ψ/2) within a column) and `:15` (Catmull-Rom across rows, linear ghost point); `gr_catmull_rom` at `:70`. K1.5's reuse claim matches the landed shader |
| V43 | Non-collinear approach ray and the boost sign (quorum r3, `gemini-4-argon`) | `python3 -I /tmp/kerr45_oracle.py frames` (lines `approach`); spec §2 rows 5–6 (`aberrate`, inverse = aberrate(n′, −β)) | u = 4, s = 0.9, b = −0.5, n_ship = (0.6, 0, 0.8) in (r, θ, φ): γ_Z = 1.1682043170450399 = γ_Sγ_b; n_Z = (0.78930098917940921, 0, 0.61400647266979697) [CPython Decimal60]; round trip back to n_ship 9e-60. The inverse moves n_r away from the inward velocity, as aberration requires; the reviewer's forward-form signs would move it the other way |

### Exact oracle outputs (iteration 45)

V31 — `python3 -I /tmp/kerr45_oracle.py closed` [CPython Decimal60; radii GM/c², clocks/speeds dimensionless, frequency c³/GM; RK-18 units in its row]:

```text
RK-1/2 .5 1.8660254037844386 0.13397459621556135
RK-1/2 .9 1.4358898943540674 0.56411010564593264
RK-1/2 .998 1.0632139225171164 0.93678607748288357
RK-4/5 .9 1.5578546274233828 3.9102679391030367
RK-4/5 .998 1.0739092576799517 3.9982218928479460
RK-6/7 .5 4.2330025295308257 7.5545847145123584
RK-6/7 .9 2.3208830417618872 8.7173522796064893
RK-8 0.37086794439864592 0.79319251811829484
RK-8b 0.092670308365368573
RK-9 0.31339450313662925
RK-10/11 0.16014234875444840 0.37964208654863802
RK-12 0.62454869546086524 0.56164924228192780
RK-18 29.532500761002495 29.532500761002495 21.202709698863643 34.270740098515360 1.3727616115380832 6362.7059001439946
```

V32 — `python3 -I /tmp/kerr45_oracle.py shadow` [CPython Decimal60; GM/c², asymmetry dimensionless]:

```text
RK-14/V21 .9 -2.8444214034761693 6.8323192304466666
RK-16 discrete-u N=200000 .9 5.0437368945142949
asymmetry 0.41211167869793890
RK-14/V21 .998 -2.1108877945528310 6.9966662713999613
RK-16 discrete-u N=200000 .998 4.8770013845209779
RK-15 5.1961524227066319
RK-17 -3.4170599872799702 6.2964531467076725 5.0696345295581239
```

V33 — `python3 -I /tmp/kerr45_oracle.py frames` [CPython Decimal60; N/clock/g/direction dimensionless, ω c³/GM, h/λ GM/c², velocity in c]:

```text
u=4 s=.9 N omega h lambda(n_phi=.6) 0.71537612301921329 0.026139994191112402 4.1490962871449489 -3.8281581133503123
hover vZ clock g n_ship_phi -0.15160885211907204 0.70710678118654752 1.4142135623730950 0.49326076709798722
pro vZ clock g n_ship_phi 0.50006315517926135 0.61950780908270660 2.3084941047201764 0.84617776221100439
retro vZ clock g n_ship_phi -0.96849348098599701 0.17815648789681010 2.5866181264388675 -0.87966111308696239
approach b=-.5 gamma_Z gamma_S*gamma_b 1.1682043170450399 1.1682043170450399
approach n_ship(r,th,phi)=(.6,0,.8) -> n_Z r phi (theta exactly 0) 0.78930098917940921 0.61400647266979697
approach round-trip max error 9e-60
```

V34 — `python3 -I /tmp/kerr45_oracle.py clock` [CPython math binary64; dimensionless dτ/dt]:

```text
u 4.1 legacy/delegated 0.71567808542054678 0x1.6e6d5ba6b0b69p-1 naive 0.71567808542054678 0x1.6e6d5ba6b0b69p-1
u 6.0 legacy/delegated 0.81649658092772603 0x1.a20bd700c2c3ep-1 naive 0.81649658092772603 0x1.a20bd700c2c3ep-1
u 20.0 legacy/delegated 0.94868329805051377 0x1.e5b9d136c6d96p-1 naive 0.94868329805051377 0x1.e5b9d136c6d96p-1
u 2000000.0 legacy/delegated 0.99999949999987503 0x1.ffffef390818fp-1 naive 0.99999949999987503 0x1.ffffef390818fp-1
```

V35 — `python3 -I /tmp/kerr45_oracle.py cost` [CPython arithmetic; timing extrapolation only]:

```text
rays 9437184 M3 seconds/ray 0.00244140625 3x CPU-hours 19.2
M3 full CPU anchor hours 36.0
```

### Scratch oracle source (reproducible)

Write the following verbatim to `/tmp/kerr45_oracle.py`, then run the five commands above. It uses only the Python standard library and is an independent oracle under CLAUDE.md, never a production pipeline or tracked Python file. Decimal roots use polynomial bisection instead of the package's photon-orbit acos form; the inclination extrema use visible-domain roots and maximisation. The source is retained here so the expected numbers do not depend on an ephemeral scratch file. K1.1a-a must carry reviewed provenance into its actual oracle/fixture before any spec PR uses it.

```python
from decimal import Decimal as D, getcontext
import math, sys
getcontext().prec = 60
# Oracle only: polynomial photon roots and Decimal arithmetic; no package imports.
def f(x): return format(x, '.17g')
def root(fn, a, b):
    a,b=D(a),D(b); fa=fn(a)
    for _ in range(230):
        m=(a+b)/2
        if fn(m)*fa>0: a=m; fa=fn(a)
        else: b=m
    return (a+b)/2
def ph(s):
    fn=lambda u:u*(u-3)**2-4*s*s
    return root(fn,1,3),root(fn,3,4)
def isco(s):
    cb=lambda x:(x.ln()/3).exp()
    z1=1+cb(1-s*s)*(cb(1+s)+cb(1-s)); z2=(3*s*s+z1*z1).sqrt()
    d=((3-z1)*(3+z1+2*z2)).sqrt()
    return 3+z2-d,3+z2+d
pi=D('3.14159265358979323846264338327950288419716939937510582097494459')
def geo(u,s):
    delta=u*u-2*u+s*s; aa=(u*u+s*s)**2-delta*s*s
    return (delta*u*u/aa).sqrt(),2*s*u/aa,(aa/u/u).sqrt()
def orb(u,s,k):
    om=k/(u*u.sqrt()+k*s); n,w,h=geo(u,s)
    return (u**D('1.5')-3*u.sqrt()+2*k*s).sqrt()*u**D('.75')/(u**D('1.5')+k*s),(om-w)*h/n

def le(u,s):
    l=-(u**3-3*u*u+s*s*u+s*s)/(s*(u-1))
    e=4*u*u*(u*u-2*u+s*s)/(u-1)**2-(l-s)**2
    return l,e
mode=sys.argv[1]
if mode=='closed':
    for ss in ('.5','.9','.998'):
        s=D(ss); h=(1-s*s).sqrt(); print('RK-1/2',ss,f(1+h),f(1-h))
    for ss in ('.9','.998'):
        print('RK-4/5',ss,*(f(v) for v in ph(D(ss))))
    for ss in ('.5','.9'):
        print('RK-6/7',ss,*(f(v) for v in isco(D(ss))))
    s=D('.9'); pro,ret=isco(s)
    print('RK-8',f(orb(pro,s,1)[0]),f(orb(ret,s,-1)[0]))
    print('RK-8b', f(orb(isco(D('.998'))[0],D('.998'),1)[0]))
    print('RK-9',f(s/(2*(1+(1-s*s).sqrt()))))
    n,w,h=geo(D(2),s); print('RK-10/11',f(w),f(n))
    print('RK-12',f(orb(pro,s,1)[1]),f(orb(isco(D('.5'))[0],D('.5'),1)[1]))
    c=D(299792458); gm=10*D('1.3271244e20'); rs=2*gm/c**2
    print('RK-18',*(f(v) for v in (rs/1000,rs/1000,rs*(1+(1-s*s).sqrt())/2000,rs*pro/2000,2*pi*(pro**D('1.5')+s)*gm/c**3*1000,s/(2*(1+(1-s*s).sqrt()))*c**3/gm)))
elif mode=='shadow':
    for ss in ('.9','.998'):
        s=D(ss); lo,hi=ph(s); left=-le(lo,s)[0]; right=-le(hi,s)[0]
        # Fixed discrete measure: N=200000 including both exact endpoints, equal weights.
        count=200000; total=D(0)
        for j in range(count):
            u=lo+(hi-lo)*j/(count-1); l,e=le(u,s)
            total+=(l*l+e).sqrt()
        print('RK-14/V21',ss,f(left),f(right))
        print('RK-16 discrete-u N=200000',ss,f(total/count))
        if ss=='.9': print('asymmetry',f((right+left)/(right-left)))
    print('RK-15',f(3*D(3).sqrt()))
    s=D('.9'); lo,hi=ph(s)
    b2=lambda u:le(u,s)[1]+s*s/2-le(u,s)[0]**2
    vl=root(b2,lo,D(3)); vr=root(b2,D(3),hi)
    a,b=vl,vr
    for _ in range(230):
        l=a+(b-a)/3; r=b-(b-a)/3
        if b2(l)<b2(r): a=l
        else: b=r
    print('RK-17',f(-le(vl,s)[0]*D(2).sqrt()),f(-le(vr,s)[0]*D(2).sqrt()),f(b2((a+b)/2).sqrt()))
elif mode=='frames':
    u,s=D(4),D('.9'); n,w,h=geo(u,s); vs=-w*h/n; stat=(1-2/u).sqrt()
    np=D('.6'); lam=-h*np/(n-w*h*np)
    print('u=4 s=.9 N omega h lambda(n_phi=.6)',*(f(v) for v in (n,w,h,lam)))
    for name,v in [('hover',vs),('pro',orb(u,s,1)[1]),('retro',orb(u,s,-1)[1])]:
        gam=1/(1-v*v).sqrt(); shift=gam*(1+v*np)*(1-w*lam)/n
        # Source aberration into ship: n'_phi=(n_phi+v)/(1+v*n_phi).
        print(name,'vZ clock g n_ship_phi',*(f(x) for x in (v,n/gam,shift,(np+v)/(1+v*np))))
    # Non-collinear radial approach (quorum r3, gemini): single pure boost from ZAMO along
    # v_Z = (b/gamma_S) e_r + v_S e_phi; n_Z = aberrate(n_ship, -v_Z) per spec section 2.
    bb=D('-.5'); gs=1/(1-vs*vs).sqrt(); gb=1/(1-bb*bb).sqrt()
    vz=(bb/gs, D(0), vs); vm=sum(x*x for x in vz).sqrt(); gz=1/(1-vm*vm).sqrt()
    def aberr(nn, vv):
        m=sum(x*x for x in vv).sqrt(); g=1/(1-m*m).sqrt(); hat=[x/m for x in vv]
        d=sum(x*y for x,y in zip(nn,hat))
        return [ (x+((g-1)*d+g*m)*hh)/(g*(1+m*d)) for x,hh in zip(nn,hat) ]
    ns=[D('.6'),D(0),D('.8')]
    nz=aberr(ns,[-x for x in vz]); back=aberr(nz,vz)
    print('approach b=-.5 gamma_Z gamma_S*gamma_b',f(gz),f(gs*gb))
    print('approach n_ship(r,th,phi)=(.6,0,.8) -> n_Z r phi (theta exactly 0)',f(nz[0]),f(nz[2]))
    print('approach round-trip max error',f(max(abs(x-y) for x,y in zip(back,ns))))
elif mode=='clock':
    for u in (4.1,6.,20.,2000000.):
        legacy=math.sqrt(1.-1./(u/2.)); naive=math.sqrt(1.-2.*u/(u*u))
        print('u',repr(u),'legacy/delegated',format(legacy,'.17g'),legacy.hex(),'naive',format(naive,'.17g'),naive.hex())
elif mode=='cost':
    rays=1536*96*64; seconds=5/2048
    print('rays',rays,'M3 seconds/ray',seconds,'3x CPU-hours',rays*3*seconds/3600)
    print('M3 full CPU anchor hours',rays/(2048*256)*(40/60)*3)
```

## Revision log (iteration 45)

Verdicts address the planner's proposals and the evaluator's evidence; “adopted-modified” states why the implementation contract differs. No plan or JSON was edited, and none of these rows asserts an unrun execution gate.

| ID | Verdict | Section changed and resolution/reason | Verification |
|---|---|---|---|
| DI-01 | adopted-modified | K1.0 RK table/tolerances: publish precise 17-digit fixtures here; allow separately rounded spec display text instead of testing rounded literals at 1e-12 | V31, V32 |
| DI-02 | adopted | K1.2 boundary: ψ_b = α_sh, radians in header/tests; comparing an angle to its sine was dimensionally wrong | V6, V11; analytic spec §3 |
| DI-03 | adopted-modified | K1.2/K1.3/AC-K6: seam/reflection/range/zero-spin checks replace impossible periodic monotonicity; radial trends asserted only where independently established. Bins are pinned/fetched | V17, V18; no new numerical trend claimed |
| DI-04 | adopted-modified | K1.2 schema/risks/AC-K6: store measured coefficients for both channels, reconstruct consistently, require cutoff/resolution convergence; twist finiteness cannot be assumed | V17 (format baseline); coefficient values remain execution evidence |
| DI-05 | adopted-modified | K1.1 precision/risks: retain scalar s, explicitly narrow reference accuracy to represented s ≤0.998; no impossible independent complement through bh_spin-only API | V31 (cap fixtures), V38 (scalar codec) |
| DI-06 | adopted-modified | K1.4/AC-K8: absent-dir zero spin executes legacy; explicit dir refused only at Kerr minor; old decoder continues ignoring extra dir, preserving its bytes | V38 |
| DI-07 | adopted-modified | K1.1 frame contract/K1.3/K1.4/K1.5/GR13: retain ZAMO tables; specify static/orbit/radial boosts, source-direction convention and ray-dependent Killing-energy frequency shift | V31, V33; BPT72 §§II–III |
| DI-08 | adopted | K1.5 GR14/AC-K9: finite-r ratio uses same-frame CPU boundary; infinity ratio belongs only to far/infinity case | V32 |
| DI-09 | adopted | K1.4 asset availability/K1.5/AC-K8: exact manifest identity or explicit client unavailable view, retaining sim state; no nearest-spin substitution | V17, V38; unsupported path test specified |
| DI-10 | adopted | K1.1 tides/risks/AC-K8: numeric fields mandatory; unverifiable tides STOP K1.1b-d/K1.4-b/publication for Mark, no nullable redesign | V38; no new tide numbers asserted |
| DI-11 | adopted | K1.1 tests: α = −λ with pro/retro endpoint order; β² = η, numerical η residual tolerance rather than exact zero | V32 |
| DI-12 | adopted | K1.1 Carter state: evolve u/θ/φ/t, constants, Mino/affine relation and root-event signs; independent capture and convergence checks | V33 (projection); Carter 1968/BPT72/Chandrasekhar; solver tests pending |
| DI-13 | adopted | Acceptance setup/AC-K1–3/V29: absolute pinned A before cd; every package command uses it, controller publication after explicit version/content go | V2, V29 (controller pin); local runtime absent |
| DI-14 | adopted | K1.5 GR17/AC-K9: boundary mutants → GR13; twist → GR15; deflection-only rules → direction probe, with an acting failure required | V11 (existing golden baseline); new mutants not run |
| DI-15 | adopted | Zero-spin reduction/K1.4/AC-K8: pristine same-minor complete streams frozen; new-minor explicit zero succeeds and equals old absent-spin equivalent except hello; suppress all new zero-spin GR keys | V38 |
| F1 | adopted-modified | K1.0 RK-16/RK-17/V21: independently recompute endpoint/mean; also replace 45° grid-truncated extrema with visible-arc roots | V31, V32 |
| F2 | adopted | K1.0 RK-16: retain only as named uniform-u 200000-point inclusive/equal-weight diagnostic, not a physical mean radius | V32 |
| F3 | adopted | Header/sub-milestones/K1.2/risks: six-week plan budget; 19.2–36.0 CPU-h anchors, budget from 36 plus fitting overhead until bounded timing | V28, V35 |
| F4 | adopted | K1.1 static clock/RK-13: zero-spin direct legacy call and equatorial operation order specified; sampled binary64 hex evidence supplied | V34 |
| F5 | adopted | K1.0/sub-milestones/deliverables: nine parents = 30 slices, oracle precedes final spec provenance; freeze/pin precedes tables, spec remains parked for Mark | V36, V37; existing plan dependencies |
| F6 | adopted-modified | Sub-milestones/risks: actual JSON schema validated, missing milestones key cannot silently yield zero work; controller adapter risk recorded, JSON unchanged | V37 |
| F7 | adopted | K1.4/V12/V13/V29: refresh inherited evidence with controller facts, source 0.13.0 vs registry 0.12.0, surface13/reserved14/archive15, next free16 today | V12, V13, V29 |
| Q3-G | adopted-modified | K1.1 frame contract: single pure boost from ZAMO along v_Z, two-step composition excluded, spec §2 inverse sign; approach ray in V33 | V43 |
| Q3-Z | adopted | Pillar table tide ≈1.05 × 10⁹ g (V22); 0.0927 cited to RK-8b; K1.2 names `encodeF32LE` at `lens_lut_main.ail:42`; K1.5 interpolation pinned | V22, V40, V41, V42 |
| Q3-K | adopted-modified | Status: pending quorum, not scheduled, with D-107 A's Anthropic/OpenAI condition; V2 labelled historical; carve-out source recorded; round-2 history kept | V2, V39, V40 |
