# R2: Kerr (spinning) black holes

**Status:** Planned (design doc only; created 2026-10-21, mission-loop iteration 43, charter row **R2** of [`design_docs/stapledon-mission.md`](../stapledon-mission.md): "Kerr (spinning) black holes, design doc and sprint plan only (the canon's rogue hole spins); execution needs Mark's approval"). A sprint plan is a separate step after this doc; nothing here is executed without Mark.
**Release:** r2 · **Milestone:** charter row R2. The R1 roadmap lists Kerr as unfinished business twice ([roadmap/r1-foundations.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) line 32's M3 row, "Kerr rotation remain[s] future work", and lines 167–168, "spin (Kerr) and the true Galactic-Centre sky are follow-ups"); the M3 ruling D-53 likewise: "spin (Kerr) is a later milestone". This document is that milestone's design.
**Priority:** P1 by canon weight — [premise-and-loop.md §1](https://github.com/sunholo-data/stapledons-design/blob/main/vision/premise-and-loop.md) line 14 opens every run with emergence "from the ergosphere of a spinning black hole" — but queued work: the armed order runs L9, L4, L3, L5 and L7 before R2, and this charter row is plan-only (see open question 5).
**Implements:**
- [premise-and-loop.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/premise-and-loop.md) §1 (`../stapledons-design/vision/premise-and-loop.md:14`) and the [2026-10-06] decisions "The Premise and Loop Are Canon" / "The Player Brings the News" ([design-decisions.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md) lines 1292–1340: every run starts at emergence from the rogue black hole; the hole is a scenario object labelled "scenario").
- [features/future/black-holes.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/black-holes.md): the status line "Kerr rotation … remain[s] future work" (line 4) and non-goal "Kerr (rotating) BH ergosphere mechanics — Future expansion" (line 415). This doc plans that future work; the lines stay until landing.
- [features/future/gr-visual-mechanics.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/gr-visual-mechanics.md): non-goals "Kerr (rotating) BH — frame dragging, ergosphere (future expansion)" (lines 569, 595). Release 1 below supersedes the frame-dragging and ergosphere *boundary* parts only; the interior stays out.
- [features/future/earth-fate-home.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/earth-fate-home.md) §4b: the canon's 10 M☉ rogue hole, r_s = 29.5 km (line 135) — the seed for check value RK-18.
- [physics/relativity-spec.md](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) §3: extended by a new **§3b (Kerr)** with check values RK-n, per Definition-of-done gate 2. The amendment is a design-repo PR (K1.0) that must merge before any Kerr *visual* merges. Today the spec has no Kerr content (row V6).
- [features/next/bubble-resources.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/bubble-resources.md) line 343 lists superradiance as a *future* energy resource. It stays future: this doc's answer is no (open question 4).

**Depends on:** `sunholo/relativity@0.12.0` (the current pin, row V3; Kerr publishes the next free minor, planned **0.14.0**, because 0.13.0 is already taken in source by the unpublished domain-bounds release on ailang-packages main, #126, row V29); M3's landed GR stack (row V10: the `geodesic`/`schwarzschild` package modules, the offline lens tables and their bucket pins, the CPU mirror `physics/schwarzschild.gd`, the sim GR mode at protocol 2.6, the GPU lensed sky, goldens GR1–GR12, the demo `demos/black_hole_visit.gd`); the pinned AILANG v0.54.14 (`runtime/bin/ailang`, row V2); the D-18 large-asset bucket.
**Estimated:** ~3,700 LOC (≈2,100 code + ≈1,650 tests and tools) in 9 sub-milestones, about 3–4 weeks of wall clock at M3's measured rate (~350 LOC per agent session, GPU-golden milestones at half rate). One package publish.
**Evidence:** every codebase or design-repo claim has a row in the [Verification log](#verification-log), pinned to game `8d17f90b` and design `864a4e4`.

## Game vision alignment

Scored against [vision/core-pillars.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md), plus the spec pillar, per the `game-vision-designer` discipline.

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | 0 | 0 | No choices yet: release 1 is a visit demo, all Kerr quantities are scenario data. The emergence scene and its throw home (the choice-laden part) are release 2+ |
| The Game Doesn't Judge | 0 | 0 | Readouts only; the sim reports frame dragging and two ISCOs without flags of right or wrong |
| Time Has Emotional Weight | + | +1 | The ZAMO/static clock and the pro/retro orbit clocks are honest numbers at the hole where the run begins; at the s = 0.998 prograde ISCO dτ/dt = 0.0927 — the ship ages a tenth — stated, not exploited |
| The Ship Is Home | + | +1 | The lensed sky is seen from the 3D ship's bridge and decks through `InteriorSky`, as in M3 (D-52); the opening of every run happens aboard |
| Grounded Strangeness | ++ | +2 | The shadow is no longer round: at s = 0.9 seen from the equatorial plane its half-widths are 2.844 M on the pinched prograde side against 6.832 M on the retrograde side (asymmetry 41 %, RK-14/15) and the sky itself twists. Strange, and exactly what a spinning hole does |
| We Are Not Built For This | + | +1 | The HUD says plainly why the first Kerr visit is at a supermassive hole: across the 100 m bubble the tide at the 10 M☉ ergosphere is ~1.1 × 10⁹ g, so the canonical emergence is survived, not toured |
| Hard sci-fi authenticity (spec) | ++ | +2 | Kerr maths goes into `sunholo/relativity` first with cited formulas (Bardeen 1972/1973, Carter 1968), check values, and an a = 0 reduction proven against M3's RS-9–RS-13 pins; the spec gains a normative §3b before any visual merges |
| **Net** | | **+7** | **Go** |

**Call-out (the loop stops for Mark here).** Pillars 1 (Choices Are Final) and 2 (The Game Doesn't Judge) score 0: this milestone adds presentation and simulation, not choices or judgements. M3 shipped with the same two zeros (its table, design_docs/implemented/r1/m3-black-holes.md, "Game vision alignment") and Mark approved it (D-53). Confirmation that zeros on those pillars are acceptable again is folded into open question 5.

## Problem

1. **The canon's hole spins; the shipped hole does not.** `sim/gr.ail:4` declares "A non-spinning hole (D-13, D-53: Sgr A* by default, the mass a scenario parameter)" (row V14). The premise and the 2026-10-06 decisions make the rogue hole spinning with an ergosphere (row V7). The roadmap names Kerr as future work (row V8). Charter row R2 asks for this design.
2. **The package cannot do Kerr.** `sunholo/relativity@0.12.0` has no Kerr symbol; its `AGENT.md:29` says "Do NOT use it for: Rotating (Kerr) black holes" (rows V4, V5). CLAUDE.md gate 3 means no Kerr visual can exist before the package does it.
3. **The spec has no Kerr section or check values.** §3 is Schwarzschild-only and the §7 index ends at RS-23 / RS-Q4 (row V6). Gate 2 requires normative check values before a visual merges.
4. **The hole is already data, spin just is not among the parameters.** `sim/gr.ail:67` notes "another hole (the canon's rogue hole) is data, not code" via `(bh_mass_msun, bh_r)` scenario parameters (row V14); the fixture `sim/gr_test.ail:157` already runs a game with `bh_mass_msun = 10`. Kerr continues that pattern: spin enters as `bh_spin`, a scenario value, never a code constant.

## Goals and non-goals

**Goals — release 1 ("a spinning hole the game can show"):**
- **G1.** A new `kerr` module in `sunholo/relativity` (next free minor, planned 0.14.0): the closed forms below with citations, contracts, tests and check values RK-n; the Carter-form null integrator for offline tables; publish.
- **G2.** An offline, deterministic Kerr lens-table set for one spin and an equatorial observer plane per scenario, generated on the strict VM, finite over its whole range, fetched by sha256 pin like M3's tables (D-18).
- **G3.** A GPU Kerr sky for that observer: the asymmetric, flattened shadow; lensed panorama with the frame-dragging twist; SR composed in the local static/ZAMO frame. The Schwarzschild renderer path is untouched and stays bit-identical for s = 0 scenarios.
- **G4.** The sim reports spin-dependent readouts (horizon, ergosphere boundary, prograde/retrograde photon orbits and ISCOs, frame-dragging rate, orbit clocks pro/retro, Kerr tides from the Weyl scalar), as scenario-parameterised protocol fields at the next free minor, additively.
- **G5.** The normative spec amendment (§3b, RK check values, §4 additions) merges **before** any Kerr visual (gate 2), with §4-standard goldens and reference renders a human opens.
- **G6.** A Kerr visit demo aboard the 3D ship, mirroring M3.6: hover, approach, prograde and retrograde orbits outside the ergosphere, HUD from sim fields only.

**Non-goals — release 1 (recommended to Mark as the scope cut):**
- No flight inside the ergosphere and no emergence scene (open question 3): inside the static limit no static observer exists, the lens-table domain changes character, and the throw home is the time-skip/New Game+ milestone's physics.
- No superradiance or energy extraction (open question 4; the canon parks it as future work in bubble-resources.md).
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
| Tides for a spinning hole | Readout | **In (ZAMO frame via Weyl scalar Ψ₂); a≠0 eigenvalues oracle-checked at execution** | Keeps every HUD number package-sourced, no misleading Schwarzschild number on a spinning hole |
| Superradiance, energy extraction | Not shown, no mechanic | **Out** (OQ4) | Canon lists it as future work; recommending no |
| Star images/rings around a spinning hole | Their absence is visible | **Out (release 2)** | Kerr inverse map is a 2-D problem; bounded cut, stated on the HUD caption |

**Bit-identical Schwarzschild at s = 0.** Four tests pin this: (1) package tests of the a → 0 reductions (horizonR(0) = 1.0, photonOrbitPro/Ret(0) = 1.5 = `photonSphere()`, iscoPro(0) = iscoRet(0) = 3.0 = the existing `isco()`, the orbit clock = `circularOrbitClockRate`, the shadow = 3√3/2 r_s = RS-9 — each against the existing exported value, ±1e-15 unless algebraically identical, in which case bit-exact); (2) the Kerr table generated at s = 0 against M3's committed bins on M3's probe set, inside AC-5's 1.2e-4 rad budget; (3) a protocol fixture at the new minor with `bh_spin = 0` (and with the parameter absent) whose wire bytes equal the previous minor's for the same inputs, the hello line excepted — the same freeze discipline the similar-worlds Sprint S0 used for 2.12; (4) golden GR16 repeats GR1–GR3 through the Kerr shader path at s = 0 within M3's 0.5 px, while GR1–GR12 themselves run the untouched M3 path.

### K1.0 Spec amendment §3b (design repo; merges before any visual)

A new `physics/relativity-spec.md` section **§3b GR (Kerr; the spinning hole)** with: the §3-style table (horizon, static limit, photon orbits, ISCOs, shadow shape, frame dragging, clocks), a Method subsection mirroring §3's ("precomputed null geodesics", now Carter-separated, boundary table plus regularised deflection table), additions to §4's test requirements (a GPU-vs-CPU golden for the spin case; reference renders of the Kerr demo), and new §7 registry rows. Everything a visual later depends on must exist here first (gate 2). Proposed rows (values derived in K1.1's test plan; computed as the Verification log records):

| ID | Quantity | Value | Unit |
|---|---|---|---|
| RK-1 | Outer horizon u_+ = 1 + √(1 − s²) at s = 0.5, 0.9, 0.998 | 1.866025 / 1.435890 / 1.063214 | GM/c² |
| RK-2 | Inner horizon u_− | 0.133975 / 0.564110 / 0.936786 | GM/c² |
| RK-3 | Static limit on the equator (identity in s) | 2 (= 1.0 r_s) | GM/c² |
| RK-4 | Equatorial photon orbits, prograde/retrograde, s = 0.9 | 1.557855 / 3.910268 | GM/c² |
| RK-5 | Same, s = 0.998 | 1.073909 / 3.998222 | GM/c² |
| RK-6 | ISCO prograde/retrograde, s = 0.5 | 4.233003 / 7.554585 | GM/c² |
| RK-7 | ISCO prograde/retrograde, s = 0.9 | 2.320883 / 8.717352 | GM/c² |
| RK-8 | ISCO prograde clock dτ/dt, s = 0.9 (retrograde) | 0.370868 (0.793193) | — |
| RK-9 | Horizon angular velocity Ω_H = s/(2u_+), s = 0.9 | 0.313395 | c³/GM |
| RK-10 | Frame dragging ω at the equatorial static limit, s = 0.9 | 0.160142 | c³/GM |
| RK-11 | ZAMO lapse (clock) there, s = 0.9 | 0.379642 | — |
| RK-12 | ZAMO local speed of the prograde ISCO, s = 0.9 (s = 0.5) | 0.624549 (0.561649) | c |
| RK-13 | Static clock → 0 at the static limit; no static observer inside. Reduction: `staticClockRateKerr(u, θ, 0)` = `staticClockRate(u/2)` exactly | qualitative + exact | — |
| RK-14 | Shadow half-widths at infinity, s = 0.9, observer in the equatorial plane: α_min, α_max | −2.844421, +6.832319 | GM/c² |
| RK-15 | Shadow top half-height β_max, equatorial observer (measured equal to 3√3 at s = 0.5, 0.9 and 0.998 to the digits computed) | 5.196152 (= 3√3) | GM/c² |
| RK-16 | Mean shadow radius, s = 0.9, equatorial observer (s = 0.998) | 5.043737 (4.876991) | GM/c² |
| RK-17 | Same, observer at 45° inclination, s = 0.9: α_min, α_max, β_max | −3.417050, +6.296362, 5.069635 | GM/c² |
| RK-18 | The canon's 10 M☉ hole, s = 0.9: r_s; ergosphere radius on the equator; horizon; prograde ISCO radius; prograde-ISCO period; Ω_H | 29.532501 km; 29.532501 km; 21.202710 km; 34.270740 km; 1.372762 ms; 6362.705900 rad/s | SI |
| RK-Q1 | s → 0 reduction: horizon at 1.0 r_s, ISCO at 3 r_s (the package's `isco()`), photon sphere at 1.5 r_s (RS-21), shadow a circle of radius 3√3/2 r_s (RS-9), ω → 0, no ergosphere | qualitative | — |

Tolerances: closed-form rows assert to 1e-12 relative in `tests/test_physics.gd` and in the package tests; RK-14…17 (shadow scan values, 200,000-sample grid, endpoints exact) to 1e-6; RK-18 conversions use the IAU 2015 nominal GM_sun the package already encodes (`rsPerSolarMassMetres`).

### K1.1 Package: new module `kerr` (package first)

Closed forms, each with `requires` domains and Z3-provable `ensures` where expressible, each citing its source inline (as the M3 modules do):

- `horizonR(s)` = `(1 + √(1−s²))/2` (in `r_s`, so `u_+ / 2`); `horizonInnerR(s)` = `(1 − √(1−s²))/2` (in `r_s`, so `u_− / 2`) — Bardeen, Press & Teukolsky 1972 (ApJ 178, 347; "BPT72"), §II. Domains: `0 ≤ s < 1`.
- `staticLimitR(s, cosTheta)` = (1 + √(1 − s²cos²θ))/2 r_s — the ergosphere boundary, g_tt = 0 (Chandrasekhar 1983, *The Mathematical Theory of Black Holes*, §54). On the equator: r_s, independent of spin (RK-3).
- `frameDragOmega(u, cosTheta, s)` = 2su/A, in c³/GM = −g_tφ/g_φφ (Bardeen 1970, ApJ 162, 71, the locally non-rotating/"ZAMO" frame). `horizonOmega(s)` = s/(2u_+) (BPT72).
- `zamoClockRate(u, cosTheta, s)` = √(ΔΣ/A) (the 3+1 lapse; Bardeen 1973, "Timelike and null geodesics in the Kerr metric", in *Black Holes (Les Astres Occlus)*, eds DeWitt & DeWitt).
- `staticClockRateKerr(u, cosTheta, s)` = √(1 − 2u/Σ), `requires` outside the static limit; inside it no static observer exists (RK-13) — the sim's refusal (`bad_gr`) uses this domain check rather than ever printing NaN.
- `photonOrbitPro(s)`/`photonOrbitRet(s)` = `1 + cos[(2/3) arccos(∓s)]` (in `r_s`, i.e. `u_ph / 2` where BPT72 gives `u_ph = 2{1 + cos[(2/3) arccos(∓s)]}`). At `s = 0` both equal `1.5 r_s = photonSphere()`. ∓: arccos(−s) is prograde (BPT72's equatorial photon orbits; Bardeen 1973's Table II form).
- `iscoPro(s)`/`iscoRet(s)` = `u_ISCO / 2` (in `r_s`), where `Z₁ = 1 + (1−s²)^(1/3)[(1+s)^(1/3) + (1−s)^(1/3)]`, `Z₂ = √(3s² + Z₁²)`, and `u_ISCO = 3 + Z₂ ∓ √((3−Z₁)(3+Z₁+2Z₂))` (in `GM/c²`, BPT72 eq. 2.21). At `s = 0`, `u_ISCO = 6` so both return `3.0 r_s = isco()`. Misner, Thorne & Wheeler 1973 §25.6 carry the a = 0 member.
- Circular equatorial orbits: `orbitOmegaKerr(u, s, pro)` = ±1/(u^(3/2) ± s) (c³/GM); the clock `orbitClockRateKerr` from u^t = (u^(3/2) ± s)/[u^(3/4) √(u^(3/2) − 3√u ± 2s)]; the ZAMO local speed v_Z = (u² ∓ 2s√u + s²)/[√Δ (u^(3/2) ± s)] — derived from BPT72's circular-orbit E and L through the ZAMO orthonormal tetrad (the tangential components of u^a). Its a = 0 member reduces to `circularOrbitSpeed` exactly (RK-Q1; the reduction is evaluated in row V22), and RK-12's two values are computed from it there and re-derived by the execution-time Python oracle.
- Tides: the Kerr tidal tensor for a ZAMO, from the Weyl scalar Ψ₂ = −M/(u − i s cosθ)³ (the Kerr metric's only nonzero Weyl scalar in the Kinnersley principal null tetrad; Chandrasekhar 1983's treatment of the Kerr Weyl scalars), transformed to the ZAMO orthonormal frame and diagonalised. Check values: the a = 0 reduction must reproduce `tidalRadial`/`tidalTransverse` **exactly** (±0.0 on the equator where Ψ₂ is real) and RK-Q1; the s = 0.9 equatorial eigenvalues are **TO BE COMPUTED** at execution time by the second-language oracle (the M3 pattern: oracle in `tools/`, literals pinned into the package tests, Python never called at runtime) — they are not stated here because no citable printed value was found during design and inventing digits is worse than saying so.
- Shadow critical curve for an observer at infinity, inclination θ_o (Bardeen 1973; Cunningham & Bardeen 1973, ApJ 183, 237): for spherical photon orbits of radius u between the prograde and retrograde photon orbits,
  λ(u) = −[u³ − 3u² + s²u + s²]/[s(u−1)], η(u) = 4u²Δ/(u−1)² − (λ(u) − s)²,
  then α = −λ csc θ_o, β = ±√(η + s² cos²θ_o − λ² cot²θ_o). (Derivation shown: the Kerr radial potential R(u) = [u² + s² − sλ]² − Δ[η + (λ−s)²] with R = 0, dR/du = 0 gives u² + s² − sλ = 2uΔ/(u−1), hence the pair above. Sign convention: with the hole's angular momentum along +z and the observer in the equatorial plane, α < 0 is the prograde side; RK-14's asymmetry pins the sense.) `shadowLambdaEta(u, s)`, `shadowAlphaBeta(u, s, cosThetaObs)`.
- The table integrator: Carter's separated null geodesics (Carter 1968, Phys. Rev. 174, 1559; Chandrasekhar §62; Riazuelo 2019, IJMP D28, 1950042 for the observer-tetrad projection). Constants (λ, η) per screen direction at the observer's ZAMO tetrad; RK4 on the (u, θ) pair in the affine parameter; **capture is decided analytically** from the radial potential's roots between the observer and u_+ (never by watching the integration), exactly as M3's "capture is decided analytically; a disagreement is a test failure" rule.

**Domains and precision hazards** (the precision gate, CLAUDE.md): 0 ≤ s < 1, with tables capped at s ≤ **0.998** (the thin-disk equilibrium spin limit, Thorne 1974, ApJ 191, 507 — astrophysical holes do not exceed it through thin-disk accretion). As s → 1 the horizon, prograde photon orbit and prograde ISCO all approach u = 1 (they coincide in Boyer–Lindquist radius but stay distinct in proper distance; Bardeen & Horowitz 1999, PRD 60, 104030), so near-extremal cancellation is real: √(1−s²) must be computed as √((1−s)(1+s)) with (1−s) an *input* (never `1.0 - s` near 1 — the same rule as CLAUDE.md's `1.0 - beta`); Δ is evaluated in factored form (u − u_+)(u − u_−); and the λ, η pair has a 0/0 limit at (u = 1, s = 1) (lim λ = 2) that the capped domain never reaches. Table generation additionally never evaluates `turningRadius`-style acos forms off their domains; NaN-guards precede comparisons, per the M3 implementation rules.

**Contract/test plan** (`kerr_test.ail`, written first): check values RK-1…RK-17 plus the RK-Q1 reductions against the existing `schwarzschild` and `geodesic` exports (bit-exact where algebraically identical, else ±1e-15); the a = 0 shadow is the circle α² + β² = 27 (M²) to ±1e-15; integrator vs closed forms at s = 0 against `deflectionExact` on M3's probe radii (AC-5 budget); λ endpoints equal α-extremes at η = 0 exactly; a `kerrDigest(n)` smoke entry added to `_smoke.ail` (strict VM vs interpreter, `cmp`), next to M3's `lensDigest`. The second-language oracle `tools/kerr_ref.py` (role `oracle`, allowlisted, as `tools/geodesic_ref.py`) reproduces every RK row independently. Release: `[release] kind = "feature"`, CHANGELOG, AGENT.md (Kerr joins the "use it for" list; the "Do NOT use it for" line drops "Rotating (Kerr) black holes" and gains "s > 0.998 tables and ergosphere interiors"), `pkg quality` clean without gates, dry run, publish under an explicit go from Mark (as M3.1p).

### K1.2 The Kerr lens tables (offline, strict VM, bucket-pinned)

**Why the M3 shape does not transfer.** Schwarzschild lensing is spherically symmetric: a static observer's ray is fixed by one angle ψ, so M3's table is 2-D in (ψ, r) with a 1-D analytic boundary (Synge). Kerr is only axisymmetric: the outgoing direction at infinity depends on the observer's position angle θ_o and on both screen angles (equivalently the photon's two constants λ, η — the Carter constant). This doc fixes the observer to the **equatorial plane** (θ_o = π/2) and fixes one spin per scenario. The map left to tabulate is then 3-D: screen polar angle ψ from the hole direction, screen azimuth χ around it, and observer radius r.

**Three artefacts per spin** (generator `sim/tools/kerr_lut.ail` + `kerr_lut_main.ail`, pure AILANG on the bytecode VM, mirroring M3.2's toolchain and the `catalogue_bytes` F32 encoder):

1. **Boundary table** ψ_b(χ, r): the capture boundary, traced by bisection in ψ at each (χ, r) with the analytic capture test; 96 azimuths × 64 radius rows, F32 (~24 kB). This replaces Synge's formula as the shadow mask; RK-Q1 asserts its s = 0 row equals sin α_sh within test tolerance.
2. **Regularised deflection table**: columns x = ln((ψ − ψ_b(χ,r))/ψ_b(χ,r)) on [ln 10⁻⁸, ln((π − ψ_b)/ψ_b)] (1536 columns), χ (96), rows y = ln(r − r_s) from r = 2 r_s to 10⁶ r_s (64 rows, end rows pinned). Channel R: the in-plane deflection regularised as in M3 (δ_∥ + ln tanh(Δψ/ψ_b)); Kerr's strong-field divergence stays logarithmic (Bozza 2003, PRD 67, 103006), but the coefficient is **measured per row by the generator, not assumed** — if the residual fails the finite-range gate the build fails loudly, and the documented fallback stores raw δ on 4096 columns. Channel G: the out-of-plane twist δ_⊥ (frame dragging), which is finite everywhere.
3. A JSON header per table like M3's (`data/lens/lens_fwd.json` records layout, ranges, generator h, package version, content hash, sha256); pins committed in `data/lens/SHA256SUMS`; bins fetched from the public bucket by a new `make kerr-assets` (D-18), never committed to git.

**Size and cost.** Table 2 is 1536 × 96 × 64 × 2 channels × 4 B ≈ **75 MB** (table 1 negligible; F16 halves it if the precision test allows — measured, not assumed). One ray costs ~3× an M3 Binet ray (two coupled components, quartic root logic): estimate **~18–25 CPU-hours per spin**, i.e. ~70–100 min wall sharded over 16 jobs the way `make lens-lut` shards (M3 anchor: its doc's as-built note measures 2,048-ray rows at ~5 s each, the full run ~40 CPU-min and 436 s wall with 14 jobs — row V28; the pin comment says ~15 min on 16 cores — row V17). Full regeneration is manual (`make kerr-lut`); `make test` runs only `make kerr-lut-check`: every 64th column of every 32nd row of a sampled set regenerated on the strict VM and compared **bit for bit** against the pinned bins, plus one complete row on strict VM and interpreter compared with `cmp` (the VM/interpreter determinism bar, CLAUDE.md gate 6). Finiteness: a Godot test loads the committed bins and asserts every texel finite across the whole range and ψ_b strictly monotone in χ and r (gate 5's finite-table rule).

**a = 0 regression.** The generator run at s = 0 must reproduce M3's committed forward-table values on M3's probe set within the AC-5 budget (1.2e-4 rad at r ≤ 100; 1e-3 relative above) — the Kerr integrator is *derived* differently (Carter form), so this is a strong independent check, and GR16 carries it into the shader.

### K1.3 CPU mirror `physics/kerr.gd`

`class_name Kerr`, float64 scalars (the float32 hazard note of M3.3 applies: boundary texel differences are formed in float64 and uploaded hi/lo). It mirrors the package and table arithmetic and is never the only copy: `load_tables()`, `boundary(chi, r)`, `deflection(r, psi, chi) -> {delta_par, delta_perp, captured}`, `compose(...)` mirroring the shader's pipeline, plus `shadow_bardeen(alpha_beta of RK-14/15/17)` for the far-row anchor. Tests live in a new "Kerr (spec §3b)" section of `tests/test_physics.gd`: every RK row asserted; the boundary table against the Bardeen curve on the r = 10⁶ r_s rows within 1e-4 rad; the finite/monotone table test; 10k deterministic probes of the mirror against the package integrator (AC-5-style budget, measured in execution); the a = 0 reductions against M3's RS pins (Synge, `deflectionExact` values).

### K1.4 Sim and protocol (pure core; additive)

`GrState` gains `spin: float` and `orbitDir: string` ("pro"|"retro"); scenario parameter **`bh_spin`** joins `bh_mass_msun`/`bh_r` (row V14's data-not-code pattern; default and absent = 0). A spin outside [0, 1) — the metric's domain — is refused with a new reason code `bad_spin` at game start; the 0.998 table cap is a table-generation limit, not a sim refusal. Modes stay hover/orbit/approach, ship-proper-time driven, all rates from the package. Specifics:
- Hover: `staticClockRateKerr(u, θ, s)` — on the equator this is today's √(1−1/r_{r_s}), so the s = 0 bytes are unchanged. Static hover exists only outside the static limit; release 1's hover domain [2, 10⁶] r_s (row V18) is entirely outside the equatorial static limit (r_s) for every s < 1, so no domain change is needed; the domain check still runs (defence at future polar/equatorial-domain changes) and answers `bad_gr`.
- Orbit: the intent gains an optional `dir` (default "pro", refused with `bad_gr` when s = 0 — handedness is meaningless for a non-spinning hole). Equatorial circular orbits use `orbitOmegaKerr`/`orbitClockRateKerr`/`orbitLocalSpeedKerr`; `orbit_stable` becomes r ≥ ISCO(dir), with orbits between the floor and ISCO flagged unstable exactly as today's 2–3 r_s band. The floor itself is unchanged: both handed photon orbits lie below the existing 2 r_s `bad_radius` bound for every s ≤ 0.998 (the retrograde photon orbit approaches 2 r_s only as s → 1; at s = 0.998 it is 1.999111 r_s), so no domain change is needed and no orbit can be commanded inside a photon orbit.
- New fields on the `gr` section at the Kerr minor: `spin`, `horizon_r`, `isco_pro_r`, `isco_ret_r`, `frame_drag_s`, `orbit_dir`, `orbit_clock`, and the tide fields from the K1.1 Weyl module; `hole_id`, static clock and blueshift keep today's names.
- **Protocol minor: the next free minor at implementation time.** Minors 2.3–2.12 are taken on main (row V12); minor 13 is claimed in flight by the similar-worlds S0 sprint (row V13) and by the attended star-surfaces PR #302 (`surfaceMinor() = 13`, verified by the controller, row V13). The Kerr encoder therefore adds `kerrMinor()` returning whatever minor is actually free when K1.4 lands, freezes all pre-Kerr streams byte-for-byte (existing fixtures plus a new literal-bytes test at the previous minor, matching S0's discipline), and at s = 0 emits exactly the previous minor's `gr` bytes. The hello's relativity pin reports $V from the Kerr minor on (the `make hello-pin` pattern; older minors keep their frozen pins).
- A new fixture `tests/fixtures/grk.ndjson` (every new field, both orbit directions, every refusal) under a new `make parity-grk`, VM/interpreter byte-identical.

### K1.5 GPU (`sky/kerr.gdshaderinc`, branch in the existing shaders)

A new include mirrors K1.3 function for function; `sky/background.gdshader`'s `gr_on` block (row V16) gains a spin branch dispatched on the sim's `spin` field (s = 0 keeps today's code path untouched). Per pixel, in the observer's local frame: SR de-aberration first (unchanged, β_loc from the sim: 0 hovering, ±v_Z orbiting, radial approaching); capture from the boundary table (bilinear); otherwise the lens map from table 2, bicubic in r exactly as M3's Catmull-Rom-in-y and cot(ψ/2)-weighted-within-column rules that GR12's mutants guard — the Kerr sprint adds the equivalent mutant cases. The M1.4c sky samples at the outgoing direction; Doppler = D_g·D_SR with D_g = 1/`staticClockRateKerr` from the sim. **Stars:** at s > 0 the starfield's GR image paths are switched off (both orders), the panorama carries the visual, and `GrLens.debug_line()` reports the suppressed star count (never silent, the discipline M3.5 set); the HUD caption says why. New goldens (`--golden=grk` inside `make golden`, needing the Studio GPU as ever):

| # | Case | Expected (CPU reference) | Tolerance |
|---|---|---|---|
| GR13 | Hover, s = 0.9, equatorial, r = 10/5/3 r_s, debug grid: silhouette from the black-pixel mask — sampled boundary points | `Kerr.boundary` at the same points | 0.75 px |
| GR14 | Same renders: half-width ratio (R−L)/(R+L) and the pinched side's sense | 0.412112, prograde side pinched (RK-14 sign convention) | 0.005 absolute |
| GR15 | Twist: fixed marker pixels near the prograde edge against the CPU mirror's δ_⊥ | `Kerr.deflection` channel G | ≤ 1 px at the golden scale |
| GR16 | s = 0 through the Kerr path at r = 10, 5, 3 (the a = 0 reduction on the GPU) | f·tan α_sh (M3's GR1–GR3 values) | 0.5 px |
| GR17 | Mutants: each Kerr interpolation/boundary rule broken in turn fails GR13 where it acts (the GR12 discipline) | failure measured | — |

No absolute closed form exists for the shadow silhouette at finite r in Kerr; the absolute anchors are RK-14–RK-17 on the far rows (r = 10⁶) checked in `make physics`, RK-Q1 at s = 0 everywhere, and the GPU-vs-CPU goldens in between. That stack is stated honestly here rather than faked with an infinity formula at 3 r_s.

### K1.6 Demo, HUD, renders

- Scenario **`kerr_demo`** (naming bikeshed to the sprint): Sgr A* mass (4.297e6 M☉, the values already cited in `sim/gr.ail`) with `bh_spin` per open question 1 (default 0.9). Same dance as M3.6: enter at 10⁶ r_s, approach to 10/5/3 r_s, hover, orbit prograde then retrograde (the two ISCOs differ visibly: 1.16 vs 4.36 r_s at s = 0.9). A second scenario row, the canon's 10 M☉ `bh_mass_msun = 10` at a far radius, is data already (the fixture spins it up today); its close visit stays impossible for the tide reason the HUD states.
- HUD additions (sim fields only, sentinel-tested as today): spin; "ergosphere (equator) at 1.00 r_s — no observer can stand still inside"; frame dragging ω in rad/s; the two ISCO radii with the current orbit's handedness and stability; "1 ship-hour = N home hours" from `orbit_clock`/static clock as today.
- `make capture-bhk`: renders at 10/5/3 r_s toward/side/away in hover and both orbit directions, debug grid and Milky Way sheets, a `bhk_manifest.sha256` pinned in `data/refs/` (the M3.6 pattern), `make bhk-render-diff` (rig), and the report records who opened them.
- Archive events unchanged (`bh_enter`/`bh_hover`/`bh_ring`; the ring event never fires at s > 0 since ring stars are off); lore text edits are a follow-up, not this milestone.

## Acceptance criteria

`$A` is the pinned v0.54.14 binary (`runtime/bin/ailang`); `$PKG` a fresh `ailang-packages` clone at `packages/relativity`; `$V` the package version Kerr publishes (planned **0.14.0**, the next free minor: the game pins 0.12.0, row V3, and 0.13.0 is the unpublished domain-bounds release, row V29).

| # | Criterion | Command |
|---|---|---|
| AC-K1 | Package `kerr` tests pass, including every RK row and the RK-Q1 reductions against existing exports | `cd $PKG && $A test --package .` |
| AC-K2 | Quality clean, no gates; dry run; published with `kerr` exported | `cd $PKG && $A pkg quality . && $A publish --dry-run && $A publish && ailang pkg info sunholo/relativity \| grep -E "$V\|kerr"` |
| AC-K3 | `kerrDigest 16` bit-identical strict VM vs interpreter (`cmp`), within 1e-9 of `tools/kerr_ref.py`; oracle reproduces every RK row | `$A run --quiet --bytecode --strict-bytecode --entry kerrDigest --args-json 16 _smoke.ail` vs interpreter, and `make kerr-oracle` |
| AC-K4 | The game pins $V; lock consistent; the hello reports it from the Kerr minor and keeps older pins frozen | `grep "\"$V\"" sim/ailang.toml && make deps AILANG=$A && make hello-pin` |
| AC-K5 | Spec §3b merged in the design repo **before** K1.5/K1.6 merge, its RK values asserted in `tests/test_physics.gd` | `grep -n "RK-" ../stapledons-design/physics/relativity-spec.md && make physics` |
| AC-K6 | Kerr tables reproduce: sampled strict-VM regeneration bit-identical to the pins; one full row strict VM = interpreter (`cmp`); every texel finite; ψ_b monotone | `make kerr-lut-check` (in `make test`) and the finite-table test in `make physics` |
| AC-K7 | a = 0 reduction of the tables: the s = 0 run matches M3's committed bins within the AC-5 budget on M3's probe set | `make physics` ("Kerr (spec §3b)" section, RK-Q1 probes) |
| AC-K8 | Sim: spin/ISCO/Ω/clock/tide fields equal package values (RK-7–12 at pinned digits); both `bad_spin`/`bad_gr` refusals leave state unchanged; pre-Kerr fixtures byte-identical; new fixture byte-equal on both engines | `make sim strict parity parity-gr parity-grk` |
| AC-K9 | Shadow silhouette GPU vs CPU (GR13), asymmetry 0.412112 with the pinch on the prograde side (GR14), twist mirror (GR15), a = 0 reduction 0.5 px (GR16), mutants fail (GR17) | `make golden` (`--golden=grk`) |
| AC-K10 | The HUD shows sim fields only: sentinel injection green; no client code outside `physics/`/`tests/` computes a Kerr quantity | `make sim` (HUD sentinel test) and a `git grep` guard in the M3 AC-14 style, for example `! git grep -nE "1 \\+ *sqrt\\(1" -- demos ui sky bridge main.gd` |
| AC-K11 | Reference renders committed (bucket-pinned manifest), diffed, and recorded opened by a person in the report | `make capture-bhk && make bhk-render-diff` and `grep -n "opened by" design_docs/implemented/r2/kerr-black-holes-report.md` |
| AC-K12 | `make test` green locally and on the rig; `sim/core.ail` still `--strict-bytecode` clean; no Kerr maths outside the package and its mirrors | GitHub fast tier; `tools/rig_check.sh <PR> --golden`; a grep guard mirroring M3's AC-14 |

## Sub-milestones and estimates

| ID | Scope | LOC (code + tests) | Depends on | Order | Duration |
|---|---|---|---|---|---|
| K1.0 | Design-repo spec amendment §3b + RK registry + §4 rows (a docs PR; no code) | 0 (+~150 doc lines) | this doc approved | 1st; gates K1.5/K1.6 merges | ≤ 1 day |
| K1.1a | Package `kerr` closed forms + `kerr_test.ail` (RK rows, RK-Q1 reductions); oracle `tools/kerr_ref.py` written first (game repo, role oracle) | 350 + 300 | — | 1 | 2–3 days |
| K1.1b | Carter integrator, capture test, shadow-curve functions, `kerrDigest`, Weyl-tide module | 380 + 330 | K1.1a | 2 | 3–4 days |
| K1.1p | Release $V (0.14.0 planned): CHANGELOG, AGENT.md, `[release] kind`, quality/dry-run/publish (**Mark's explicit go**, as M3.1p) | 120 | K1.1b evaluated PASS + Mark | 3 | ≤ 1 day |
| K1.2 | `sim/tools/kerr_lut*.ail`, the three artefacts, pins, `make kerr-lut[-check]`, the s = 0 regression vs M3 bins | 260 + 150 | K1.1p, pin via K1.4's AC-K4 step | 4 | 3–4 days |
| K1.3 | `physics/kerr.gd` mirror, the spec §3b section of `tests/test_physics.gd` | 230 + 230 | K1.0, K1.2 | 5 | 2–3 days |
| K1.4 | Sim spin in the pure core, intents (`gr_orbit dir`), fields, refusals, fixture, `make parity-grk`, byte freezes | 230 + 250 | K1.1a (path dep until publish) | parallel with K1.2/3 | 2–3 days |
| K1.5 | `sky/kerr.gdshaderinc`, the shader branch, star suppression with debug count, GR13–GR17 | 320 + 240 | K1.0 merged, K1.3 | 6 | 3–4 days (GPU half-rate) |
| K1.6 | `kerr_demo` scenario, HUD lines, `make capture-bhk`, manifest + diff, report, landing edits | 190 + 130 | K1.4, K1.5 | 7 | 2–3 days |
| | **Total** | **≈2,080 + 1,630 ≈ 3,710** | | | **~3–4 weeks** |

M3's 250-LOC-per-PR cap applies: K1.1a/K1.1b and K1.5 split along the code/test line. One publish (K1.1p).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The regularisation misfits: Kerr's strong-field log-divergence coefficient per row is not 1, so the M3 subtraction leaves a divergent residual and the finite-range gate fails | The generator *measures* the coefficient per row (Bozza 2003 gives existence, not the value). Failure is loud at build time; the fallback stores raw δ on 4096 columns (+~120 MB). Decided by test, never assumed |
| Table cost overruns the ~25 CPU-h estimate | K1.2 task 1 re-measures ray cost, as M3.2 did; the documented fallbacks are 1024 columns or 48 azimuths, each re-measured against the accuracy probes; full regen stays manual |
| Protocol-minor collision: minor 13 is claimed by two in-flight efforts (row V13) | The doc hard-codes **no** minor; `kerrMinor()` is the next free integer when K1.4 lands. Byte-freeze fixtures pin the previous minor's streams in either order of landing. If both other efforts merge first, Kerr takes 15 — the ACs name semantics, not digits |
| VM/interpreter divergence in long RK4 loops (the M1/M3 history) | `cmp` gates in AC-K3/K6, no tolerance; shrink and report upstream per CLAUDE.md |
| Sign-convention errors (prograde pinched side, α sign, handedness of Ω) | RK-14's asymmetry magnitude *and* sense are normative; GR14 fails a mirrored implementation; the a = 0 reductions fix every other axis |
| The Weyl-tide module slips (tetrad algebra is the hardest part of K1.1b) | Its a = 0 reduction is an exact gate; if the s ≠ 0 eigenvalues cannot be oracle-verified in execution, the tide *fields* go null with the HUD printing "tide: pending for spin" — an honest blank, never the Schwarzschild number on a spinning hole |
| Near-extremal cancellation (Δ, √(1−s²), the 0/0 in λ, η) | Domain cap s ≤ 0.998 (Thorne 1974), factored forms, one-minus-s as an input; tests at 0.998; the extremal limit is out of scope and says so |
| Starless Kerr sky judged thin | Deliberate cut, caption on the HUD; the debug-grid goldens exercise the lensing hard; Kerr star images are release-2 work with their own design |
| Scope creep toward the emergence scene | Held out by the non-goals and OQ3; the inside-ergosphere domain is a different table and a different sim frame (no static observers), not a flag flip |
| Canon fixes a different spin than 0.9 later | Spin is scenario data (`bh_spin`); tables regenerate per spin overnight; no code carries 0.9 (AC-K10's grep helps) |

## Open questions for Mark

1. **The rogue hole's spin s.** Canon fixes that the hole spins (premise §1) but not how fast; this doc's check values use s = 0.9 and the tables cap at 0.998 (Thorne). *Recommendation:* canon sets s = 0.9 — a big, honest "D" (41 % half-width asymmetry, prograde ISCO 2.32 M vs retrograde 8.72 M) without extremal numerics. *Cost of choosing otherwise:* near-extremal (≥ 0.99) raises table cost and risks the cancellation hazards above; lower spins make the asymmetry subtle on screen. *Default if unanswered:* s = 0.9 in the demo, parametric everywhere, canon silent.
2. **Observer inclination(s).** Release 1 fixes the observer in the equatorial plane (one table set per spin; maximal asymmetry; the emergence itself is most natural there, the ergosphere being widest on the equator). *Recommendation:* equatorial only now; a 45° set is a cheap later add (the RK-17 values already exist for it). *Cost of otherwise:* each extra inclination multiplies table memory and build time. *Default:* equatorial only.
3. **Is the emergence scene itself in scope for the first Kerr release, or only the visit demo?** *Recommendation:* visit demo only. Inside-ergosphere flight has no static frame, needs a ZAMO compositor and new table domains, and the canon's emergence (violent, memory-erasing, "thrown clear") is the time-skip/New Game+ milestone's physics; the tide estimate across the bubble at the 10 M☉ ergosphere (~1.1 × 10⁹ g, Schwarzschild estimate shown in the Verification log) underlines that this scene is survived, not toured. *Cost of otherwise:* roughly doubles the table and shader work and forces free-fall trajectories. *Default:* demo only.
4. **Superradiance / energy extraction (bubble-resources.md's listed future resource)?** *Recommendation:* no — no mechanic, no energy ledger change; the Penrose-process reading stays premise flavour text. *Cost of yes:* a new canon-facing simulation of wave amplification in the ergosphere with its own spec section; weeks, and it buys no visual. *Default:* excluded.
5. **Priority against the other R2 rows and the armed order** (the order runs L9 → L4 → L3 → L5 → L7 → R2 → backlog; the charter marks R2 plan-only). *Recommendation:* keep R2 plan-only as the charter says; execute only on Mark's go; when re-prioritisation is next attended, weigh K1.0+K1.1 (package work, no GPU) ahead of the GPU milestones. *Also folded here:* confirmation that zeros on *Choices Are Final* and *The Game Doesn't Judge* are acceptable for this feature (as they were for M3). *Default:* the charter stands; this doc and its sprint plan are the deliverable.

## Design-repo changes this needs

Separate design-repo PRs, none written by this doc: (a) the §3b + §4 + §7-RK amendment in `physics/relativity-spec.md` (K1.0, merges first, gate 2); (b) at landing: the `features/future/black-holes.md` status line and the two `gr-visual-mechanics.md` non-goal lines updated; `roadmap/r1-foundations.md` M3-row wording and the lines 167–168 "follow-ups" wording revised; the roadmap gaining an R2 Kerr row if Mark wants the milestones tracked there; (c) if OQ1 is answered, the spin value recorded where canon lives (premise or earth-fate-home), with provenance.

## Deliverables

- **This doc**, then a sprint plan by the sprint-planner on approval (`design_docs/planned/r2/kerr-black-holes-sprint.md`), both parked for Mark per the charter.
- On execution: `sunholo/relativity@$V` with module `kerr` (RK test set, `kerrDigest`, CHANGELOG, AGENT.md); the three lens artefacts with pins and `make kerr-assets/kerr-lut/kerr-lut-check`; `physics/kerr.gd` + the spec §3b section of `tests/test_physics.gd`; the sim spin parameter, protocol fields and `tests/fixtures/grk.ndjson` with `make parity-grk`; `sky/kerr.gdshaderinc` and goldens GR13–GR17; the `kerr_demo` scenario, HUD lines, `make capture-bhk` renders with a pinned manifest and a report naming who opened them; the design-repo changes above.
- **Report:** `design_docs/implemented/r2/kerr-black-holes-report.md` at landing.

## Quorum log

- **Round 1 (2026-10-21, author `pi:ollama/kimi-k3:cloud`, its vendor benched): BLOCKED, PROCEED-impossible at N−2.** Present: `gemini-4-argon` REJECT. Absent: `claude-sonnet-5@claude-p` (quota), `gpt6-1-sol` (unreachable), `oc-glm-5-3` (invalid: hit its 65,536-token output cap with no verdict). Objection (one surface, K1.1 units): make every exported radius state `r_s` or `M`; it also claimed `photonOrbitPro/Ret` was off by a factor of 2. **Measured by the controller (row V30): the factor-2 claim is false** (the formula already returns 1.5 r_s at s = 0 and 0.778927 r_s = 1.557855 M at s = 0.9, RK-4), but the requested explicitness is right: `horizonInnerR` had no formula and the ISCO bullet left the `/2` from `GM/c²` implicit. The reviewer's proposed bullets were applied verbatim (they do not dispute the direction).

## Verification log

Run 2026-10-21 at game commit `8d17f90b`, design-repo commit `864a4e4`. All searches used the pinned `runtime/bin/ailang` reference only as version evidence; computations used CPython double precision *as an oracle in scratch, committed nowhere* (CLAUDE.md's Python policy), the same role M3 gave `tools/geodesic_ref.py`. The design repo was read, never written.

| # | Claim | Command | Observed |
|---|---|---|---|
| V1 | Charter row R2 exists and is plan-only | `sed -n 367p design_docs/stapledon-mission.md` | `\| R2 \| Kerr (spinning) black holes, design doc and sprint plan only (the canon's rogue hole spins); execution needs Mark's approval. \|` |
| V2 | The pinned binary is v0.54.14 | `runtime/bin/ailang --version` | `AILANG v0.54.14` (commit e1ef33f) |
| V3 | The game pins `sunholo/relativity` 0.12.0 | `grep -n "relativity" sim/ailang.toml` | line 20: `"sunholo/relativity" = "0.12.0"` |
| V4 | The package has no Kerr content (with control) | `R=~/.ailang/cache/registry/sunholo/relativity/0.12.0; grep -ri "kerr" $R/*.ail $R/*.md \| wc -l; grep -ri "schwarzschild" $R/*.ail \| wc -l` | kerr: **1** (the `AGENT.md` exclusion line); schwarzschild: **21** — the search can find things |
| V5 | The package's AGENT.md excludes Kerr | `grep -n "Kerr" $R/AGENT.md` | line 29, under "Do NOT use it for": `- Rotating (Kerr) black holes.` |
| V6 | The spec has no Kerr section (with control) | `grep -ci "kerr" ../stapledons-design/physics/relativity-spec.md; grep -ci "schwarzschild" …; sed -n 63p …; sed -n 149p …` | kerr: **0**; schwarzschild: 1; line 63 `## 3. General relativity (Schwarzschild; the black-hole feature)`; line 149 `## 7. Check-value index` (ends RS-23/RS-Q4) |
| V7 | Canon: every run emerges from the ergosphere of a spinning hole | `sed -n 14p ../stapledons-design/vision/premise-and-loop.md; sed -n 1331,1332p ../stapledons-design/vision/design-decisions.md` | line 14 "emerges violently from the ergosphere of a spinning black hole: the same rogue black hole that is heading for the Solar System"; design-decisions line 1331 "Every run starts at emergence from the rogue black hole …" |
| V8 | The roadmap calls Kerr future work | `grep -n -i "kerr\|spin" ../stapledons-design/roadmap/r1-foundations.md; sed -n 167,168p …` | line 32 (M3 row): "…Kerr rotation remain[s] future work"; lines 167–168: "spin (Kerr) and the true Galactic-Centre sky are follow-ups" |
| V9 | No Kerr code in the game (with control) | `git grep -i "kerr" \| wc -l; git grep -i "schwarzschild" \| wc -l; git grep -i "kerr" -- "*.gd" "*.ail" "*.gdshader"` | 27 vs 247 hits; the only code-tree kerr hits are the substring "kErr" inside "playbac**kErr**or" in `ai/tools/` (an audio verifier, unrelated); the rest are docs/state prose (M3 doc and sprint, mission charter, roadmap, eval JSONs) — no Kerr physics anywhere |
| V10 | M3's GR stack is on main | `ls sim/tools/lens_lut*.ail physics/schwarzschild.gd sky/gr_lens.gd sky/*.gdshader* demos/black_hole_visit.gd tests/test_physics.gd tests/fixtures/gr.ndjson tools/geodesic_ref.py` | all present; also `sky/background.gdshader`, `sky/schwarzschild.gdshaderinc`, `tools/gr_golden.gd` |
| V11 | Goldens GR1–GR12 exist; RS check rows asserted | `grep -n "GR1…GR12" tools/gr_golden.gd; sed -n 1232,1236p tests/test_physics.gd; grep -n "M3.5: GR1-GR11" Makefile` | gr_golden.gd header covers GR1-GR9, GR10, GR11, GR12; test_physics.gd lines 1232–1236 assert Synge RS-10..13 (14.269027328/27.694561451/45.0/90.0); Makefile's golden comment names GR1-GR11 (GR12 is the mutant case in gr_golden.gd) |
| V12 | Protocol minors 3–12 are taken; GR is minor 6 | `grep -n "Minor() -> int" sim/protocol.ail` | system 3, nav 4, departure 5, `grMinor() -> int = 6` (line 98), stops 7, ism 8, crew 9, interlude 10, console 11, homeTiers 12 |
| V13 | Minor 13 is claimed in flight | `grep -n "2.13\|minor 13" .ailang/state/sprints/sprint_R2-SIMILAR-S0.json; gh pr view 302 --json number,title,state` | the similar-worlds S0 sprint plans protocol 2.13 ("Negotiated 2.13…"); `gh` failed: `tls: failed to verify certificate` (sandboxed); **controller re-check outside the sandbox (2026-10-21):** `gh pr diff 302 | grep "surfaceMinor() -> int"` prints `+export pure func surfaceMinor() -> int = 13` (attended R2-STAR-SURFACES, open, paused for Mark's playtest), so both claims on minor 13 are real |
| V14 | The sim GR mode composes the package; holes are scenario data | `sed -n 3,10p sim/gr.ail; sed -n 54p sim/gr.ail; sed -n 67p sim/gr.ail; sed -n 157p sim/gr_test.ail` | lines 4–9 (the module comment): "…A non-spinning hole (D-13, D-53: Sgr A* by default, the mass a scenario parameter)… this module composes them and does no physics of its own"; line 54: `sgrAMassMsun() -> float = 4297000.0`; line 67: "(bh_mass_msun, bh_r), so another hole (the canon's rogue hole) is data, not code"; gr_test.ail:157 runs `"params":{"bh_mass_msun":10,"bh_r":2500}` |
| V15 | The GPU upload layer does no physics | `sed -n 7,13p sky/gr_lens.gd` | "No physics is computed here: the per-r scalars … are the CPU mirror's …, and the shadow angle goes up as a float32 hi/lo pair of the sim's float64 value" |
| V16 | The GR sky lives in a `gr_on` branch of the shipped shaders | `grep -n "gr_on\|schwarzschild.gdshaderinc" sky/background.gdshader sky/starfield.gdshader` | background.gdshader lines 13/28 (`#include`), 108, 146 `if (gr_on)`; starfield.gdshader line 9 documents the same include |
| V17 | M3 table format, pins and cost anchor | `head -3 data/lens/lens_fwd.json; head -5 data/lens/SHA256SUMS; grep -n "15 min on 16 cores" Makefile` | 2048×256×2ch F32, h = 0.0025, generated by the package's `geodesic.lensRegular` v0.10.0, sha256-pinned bin fetched from the public bucket; Makefile line 850: fetched "in seconds, else regenerated on the VM (~15 min on 16 cores)" |
| V18 | The sim's hover range is [2, 10⁶] r_s | `sed -n 83,84p sim/gr.ail` | `grMinR() -> float = 2.0`, `grMaxR() -> float = 1000000.0` (D-13) |
| V19 | The date | `date "+%Y-%m-%d"` | 2026-10-21 |
| V20 | RK closed-form values (RK-1…13, RK-Q1 a = 0 members) | `python3 -c` (formulas as in K1.1: horizon, photon orbits, Z₁Z₂ ISCO, Ω, ZAMO lapse, u^t clocks; printed to 10+ digits) | r_+(s=0/0.5/0.9/0.99/0.998) = 2.0000000000/1.8660254038/1.4358898944/1.1410673598/1.0632139225 M; r_ph pro/ret s=0.9 = 1.5578546274/3.9102679391 M; ISCO pro/ret s=0.9 = 2.3208830418/8.7173522796 M (s=0.5: 4.2330025295/7.5545847145; s=0.998 pro 1.2369706552); Ω_H s=0.9 = 0.3133945031; ω(2M, eq) = 0.1601423488; ZAMO lapse there 0.3796420865; ISCO clocks 0.3708679444/0.7931925181; **a = 0: ISCO exactly 6.0 M, r_ph exactly 3.0 M, u^t at 6 M = √2** (dτ/dt 0.707106781187 = the package's `circularOrbitClockRate(3)`) |
| V21 | RK shadow values (RK-14…17) | `python3 -c` (λ(u), η(u) from the K1.1 derivation; uniform 200,000-sample scan of u ∈ [r_ph,pro, r_ph,ret]; celestial α = −λ csc θ_o, β = ±√(η + s²cos²θ_o − λ²cot²θ_o)) | s=0.9 edge-on: α ∈ [−2.84442140, +6.83231923] M, β_max 5.19615242 M, mean radius 5.04373689 M, half-width asymmetry (R−L)/(R+L) = 0.41211168; s=0.9 at 45°: [−3.41704963, +6.29636224], β_max 5.06963453; s=0.5 edge-on: [−4.09622494, +6.13809295]; s=0.998 edge-on: [−2.11088779, +6.99657841], mean 4.87699079; **a = 0: radius 3√3 = 5.196152422707 M = 2.59807621 r_s, the package's `criticalImpact()` and RS-9** (endpoint α values are exact; means carry the ~1e-6 sample quantisation noted in the tolerances) |
| V22 | RK-18 conversions and the emergence tide estimate | `python3 -c` (IAU 2015 nominal GM_sun = 1.3271244e20; the package's `rsPerSolarMassMetres` = 2GM/c²) | 10 M☉: r_s = 29.532501 km (package's per-M☉ 2953.25008 m); s=0.9: r_+ = 21.202710 km; ergosphere equator = r_s = 29.532501 km; prograde ISCO = 34.270740 km, period 1.372762 ms; Ω_H = 6362.705900 rad/s; frame drag at the equatorial static limit 3251.297190 rad/s; **tide across the 100 m bubble at R = r_s, the `tidalAccelSI` form a = c² L r_s/R³ (Schwarzschild estimate at the ergosphere): 1.030483e10 m/s² ≈ 1.0508e9 g**; the v_Z formula's a = 0 member at u = 6 M is exactly 0.5 = the package's `circularOrbitSpeed(3)` |
| V23 | The 10 M☉ canon value this doc links | `grep -n "29.5\|10 M☉" ../stapledons-design/features/future/earth-fate-home.md` | line 135: "For the 10 M☉ rogue hole of premise §1: Schwarzschild radius r_s = 29.5 km; shadow radius (3√3/2) r_s = 76.7 km" (consistent with V22 to the canon's three figures) |
| V24 | Superradiance is parked future work in canon | `grep -n "superradi" ../stapledons-design/features/next/bubble-resources.md` | line 343 lists superradiance ("~4% per pass") as an energy concept needing "a mirror cavity around a black hole" — a future resource row, not a current mechanic |
| V25 | The M3 ruling parks Kerr for a later milestone | `sed -n 167p design_docs/stapledon-mission.md` | D-53 (RESOLVED, Mark 2026-10-08): "…with mass a scenario parameter so the canon's rogue hole reuses it; spin (Kerr) is a later milestone…" |
| V26 | The armed order puts R2 after L9/L4/L3/L5/L7 and plan-only | `sed -n 376p design_docs/stapledon-mission.md` | "Order for the next armed run (Mark, attended 2026-10-20…): L9 S0 … → L4 … → L3 … → L5 … → L7 … (stop before publish) → **R2** Kerr plan (plan only, park) → row 7m AC1 …" |
| V27 | M3's pillar table shipped the same two zeros, and Mark approved | `sed -n 34,45p design_docs/implemented/r1/m3-black-holes.md` | lines 38–39 (Choices Are Final 0, The Game Doesn't Judge 0), line 45 Net **+7 Go**; its approval is the D-53 row (V25) |
| V28 | The M3 table-generation cost anchor | `grep -n "40 CPU-min\|436 s wall" design_docs/implemented/r1/m3-black-holes.md` | line 177 (as-built note): "…the full run is about 40 CPU-minutes at h = 0.0025… 436 s wall with 14 jobs on the Studio under heavy load" |
| V29 | `sunholo/relativity` 0.13.0 is already taken (controller, outside the sandbox) | `git -C ~/dev/sunholo-data/ailang-packages show origin/main:packages/relativity/ailang.toml \| grep -m1 version; ailang pkg versions sunholo/relativity \| grep latest` | source `version = "0.13.0"` (ailang-packages #126, `7682890`: float64 domain bounds for seven generated properties, `hyper.sinh` saturation fix); registry latest `v0.12.0`. So 0.13.0 is unpublished but claimed; Kerr plans 0.14.0 unless the two ship together |
| V30 | K1.1's photon-orbit formula is already in `r_s` (controller, quorum round 1) | `python3 -I -c "import math; [print(s, 1+math.cos(2/3*math.acos(-s)), 1+math.cos(2/3*math.acos(s))) for s in (0.0, 0.9)]"` | `0.0 1.5 1.5`; `0.9 0.7789273137 1.9551339696` (× 2 = 1.557855 / 3.910268 M = RK-4) |
