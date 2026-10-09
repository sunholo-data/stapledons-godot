# The real interstellar medium and dust-grain impacts

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | +1 | A committed route crosses real clouds whose cost is fixed when you commit: the drag energy, the wall load, and the top speed the drive can still brake from. Going around a cloud, or slowing down for it, is a decision taken at the navigation station (D-56), not a reflex. |
| The Game Doesn't Judge | 0 | Every density is measured and cited; the plan shows costs, never advice. |
| Time Has Emotional Weight | +1 | Slowing to cross a cold cloud, or detouring via another star, costs Earth years; the plan preview shows both clocks for each choice. |
| The Ship Is Home | +1 | The weather between the stars is seen from the decks: the glow brightens in a cloud and dims in the hot bubble, and the forward dome sparkles with grains. The crew's Watch reads it (Archive). |
| Grounded Strangeness | +2 | The clouds are the real ones (the Local Interstellar Cloud the Sun sits in, the G cloud around α Cen, the Hyades cloud on the way to Aldebaran, the Local Leo Cold Cloud), and the sparks are the grains Ulysses and Galileo caught. |
| We Are Not Built For This | +1 | A 10 µm grain carries up to 6.6 × 10⁸ J at the top of the slider; a cold cloud makes the top speeds impossible to brake from. Space is not empty, and the ship only survives it through the one admitted hand-wave. |

**Net +6: aligned (go).** Scored with the `game-vision-designer` pillars (`stapledons-design/vision/core-pillars.md`). It implements canon 2025-12-08 ("the glow scales with velocity and local ISM density: faint in deep space ... intense in nebulae") with measured densities, and it stays inside D-59's white, atmospheric high-speed look.

**Status:** Planned 2026-10-09, awaiting Mark's approval (ledger **D-60**). Sprint plan: [ism-structure-and-dust-sprint.md](ism-structure-and-dust-sprint.md), `.ailang/state/sprints/sprint_R1-ISM-DUST.json`. Independent plan review round 1: 78/100, pass; all eleven findings addressed (sprint plan, "Plan review").
**Release:** R1 follow-up. **Priority:** P1 (Mark's ruling D-60).
**Implements:** D-60 (this feature), within D-11 (the bubble: elastic mirror, ε glow), D-15, D-29/D-30 (ε = 10⁻¹⁰, greybody glow), D-48 (keep the glow as modelled), D-59 (the white view at high c stays; no dimming), D-56/D-57 (HUD informs, consoles decide, no twitch). Physics spec: `stapledons-design/physics/higgs-bubble.md` §5 (ISM drag, HB-3 density "constant in R1"), §6 (glow and its check values HB-95…HB-112), §1 (ε, HB-111); `physics/relativity-spec.md` (rapidity forms, never 1 − β by subtraction). Design-repo features: `features/next/bubble-ship-hud-view.md`, `features/phase2-core-views/galaxy-map.md`; canon 2025-12-08 ("Boundary glow").
**Depends on:** `sunholo/relativity` (pinned 0.10.0; 0.11.0 on main), `sunholo/celestial` (pinned 0.1.0; 0.3.0 on main); R1-SHIP-UI (PR #181, approved D-57) for the HUD cards (milestone I7 only); the free-navigation PRs (#171, #182) for routes that start away from Sol and for "via a star" detours.
**Estimated LOC:** about 3,840 in two PRs (pin bump 20, oracle 180, package 960, data 740, sim 720, renderer 400, map 360, HUD 180, captures 220, docs and lore drafts 60); PR A about 3,320, PR B (Edenhofer clouds, LLCC) about 520.

## 1. Problem

Today the medium is one number. `Params.ismNCm3 = 0.1` (HB-3, "Local Bubble; constant in R1") feeds `ismAt` (`sim/consequence.ail`), the trip ledger (`sim/core.ail` `ledgerAfter`, `pieceLedger`, `tripEnergy`) and the brake-hold check (`brakeHoldsAgainstDrag`). The glow shader (`interior/glow_overlay.gdshader`) draws whatever pole emittance and temperature the sim sends, so it only ever changes with speed. Consequences:

- The route makes no difference. α Cen, TRAPPIST-1 and Aldebaran cost the same per light year, though the real lines of sight cross different clouds (the G cloud around α Cen; the Hyades cloud toward Aldebaran).
- The Sun is not in the Local Bubble's hot gas but at the edge of the Local Interstellar Cloud (n_H ≈ 0.25 cm⁻³, 2.5× HB-3; Slavin & Frisch 2008). The Local Bubble's hot interior is 25× thinner than HB-3 (n_e ≈ 4.7 × 10⁻³ cm⁻³; Snowden et al. 2014). Its gas has no single "density".
- Nothing on the galaxy map shows the medium, and the Archive (`data/lore/archive/ism-glow.md`) states "about one hydrogen atom in every ten cubic centimetres" everywhere.
- Dust is absent, though the interstellar grains streaming through the Solar System were measured in situ for 16 years (Ulysses; Krüger et al. 2015).

## 2. Goals and non-goals

**Goals**
1. A cited, deterministic density field n_H(x) for everywhere the ship can fly (the 100 pc catalogue reach plus margin), with named media: the Local Interstellar Cloud (LIC), the 14 other Redfield & Linsky clouds, the Local Leo Cold Cloud (LLCC), the Local Bubble's hot gas, and the dense clouds of a Gaia 3D dust map beyond 69 pc.
2. That field drives everything that used n: glow (pole emittance and temperature), drag force, wall load, the drag energy ledger, and the brake-hold limit. Integration along the route is exact (piecewise constant on analytic segment boundaries), so the arrival ledger still closes.
3. In flight the player sees the medium: the glow brightens and dims as the ship crosses clouds, the HUD transit card names the medium and its density, and a notice marks each boundary.
4. On the galaxy map the clouds are drawn, the planned route is coloured by medium, and the plan preview lists the media crossed with each one's length, the peak load, the drag energy and the top speed the drive can brake from on that route. Route and speed choices through or around clouds are decisions at the navigation station.
5. Individual dust-grain impacts: each is a flash at a point on the forward wall, drawn from a cited grain-size distribution scaled by the local gas, with energies from the package, rendered through the same photometric exposure as the glow. Seeded and replayable.
6. Package first: all maths in `sunholo/relativity` and `sunholo/celestial`, with check values in a design-repo spec PR before the sim pins them.

**Non-goals**
- No magnetic shaping of the flow or the plume (not physical at these energies, D-60).
- No glare, saturation or auto-dimming glazing (D-59 ruled it out). Flashes only add light.
- No moving clouds. The Local clouds move at 15–60 km/s relative to the Sun (Redfield & Linsky 2008, Table 16), about 0.03 pc per thousand years, which is below the model's resolution for any R1 voyage. The field is fixed at epoch J2000.
- No stellar winds or astrospheres near stars (canon "bright near stars" stays a later item; listed in the risks).
- No free-space waypoints. A detour goes via a star (Q6).
- No enforced energy budget (still a readout, higgs-bubble.md §5 "R1 scope").

## 3. Data sources, and why each one

| Region | Source | What we take | Why this one | Licence / size |
|---|---|---|---|---|
| The LIC, the cloud the Sun is in | Linsky, Redfield & Tilipman 2019, ApJ 886, 41 (arXiv:1910.01243), Table 3 | Centre (−0.8, +0.7, −0.4) pc and nine real spherical-harmonic coefficients (l ≤ 2) of the distance to the LIC's edge, fitted to 62 HST sight lines at n_HI = 0.2 cm⁻³ | The only published 3D shape of the LIC. It supersedes Redfield & Linsky 2000 (which assumed n_HI = 0.1). It is 12 numbers, and its own Table 2 (62 edge distances) is a ready-made test | Numbers cited from the paper (12 values) |
| The other 14 nearby clouds (G, Blue, Aql, Eri, Aur, Hyades, Mic, Oph, Gem, NGP, Leo, Dor, Vel, Cet) | Redfield & Linsky 2008, ApJ 673, 283 (arXiv:0709.4480), Tables 1–15, 16, 18 | Each cloud's sky centre (l, b), projected area, nearest star (an upper limit on its distance), temperature, and the typical H I column of its sight lines | The standard kinematic model of the cluster of local clouds within 15 pc, built from 270 velocity components toward about 160 stars | Numbers cited (about 100 values) |
| Warm-cloud density | Slavin & Frisch 2008, A&A 491, 53 (model 26, as adopted by Krüger et al. 2015) | n_HI = 0.192, n_p = 0.055, so n_H = 0.247 cm⁻³, applied to every warm local cloud | The radiative-transfer model that fits the in-situ helium and the LIC's ionisation; Krüger 2015 uses the same value, so the dust normalisation is consistent | Cited |
| Local Bubble hot gas (between clouds, out to the bubble wall) | Snowden et al. 2014, ApJ 791, L14 | n_e = 4.68 × 10⁻³ cm⁻³ at about 10⁶ K, fully ionised, so n_H = n_e / 1.2 ≈ 3.9 × 10⁻³ cm⁻³ | The DXL sounding-rocket measurement with solar-wind charge exchange removed | Cited |
| The Local Leo Cold Cloud | Peek et al. 2011, ApJ 735, 129; Meyer et al. 2012, ApJ 752, 119 | Between 11.3 and 24.3 pc, 15–30 K, n_HI ≈ 3,000 cm⁻³ (P/k ≈ 60,000 K cm⁻³), about 0.2 M☉ of H I in thin, elongated sheets | The closest cold neutral cloud, well inside the reach of the catalogue (toward Leo). The sky outline and sheet thickness are digitised from the papers' maps in I3 (with page and figure cited) | Cited |
| Dense clouds 69–150 pc | Edenhofer et al. 2024, A&A 685, A82 (arXiv:2308.01295); data Zenodo 10.5281/zenodo.8187943 | Posterior-mean differential extinction (`mean_and_std_healpix.fits`, Nside 256, 516 log-spaced shells, 69–1,250 pc); only the shells inside 160 pc are read | The newest parsec-scale Gaia map, 14′ and about 0.4 pc distance discretisation near its inner edge, compact clouds, and it is what Zucker et al. built on. Lallement/Vergely 2022 (10–25 pc cells) is too coarse for 1 pc clouds; Leike, Glatzle & Enßlin 2020 is close but older | **CC BY 4.0**, credited on the credits screen. 3.25 GB raw (fetched once into `data/raw/`, sha256-pinned, never in git); the derived clump list is about 50 KB (in git, generated) |
| Inside 69 pc | none from dust maps | — | Gaia dust maps cannot see the local clouds (N_H ≈ 10¹⁸ cm⁻², A_V ≈ 5 × 10⁻⁴ mag); Edenhofer removes the inner 69 pc. Inside it the absorption-line models above are the truth | — |
| Extinction to gas | Bohlin, Savage & Drake 1978, ApJ 224, 132; Edenhofer 2024 §6 (A_V = 2.8 × E_ZGR23; Zhang, Green & Rix 2023) | N_H / E(B−V) = 5.8 × 10²¹ cm⁻² mag⁻¹ with R_V = 3.1, so n_H = 606 cm⁻³ per (mag pc⁻¹) of A_V | The classic Copernicus ratio. Lenz, Hensley & Doré 2017 (8.8 × 10²¹ at low column) is the alternative, a scenario parameter | Cited |
| The Local Bubble, for the map legend | Zucker et al. 2022, Nature 601, 334; Pelgrims et al. 2020, A&A 636, A17 | The bubble's name, age (about 14 Myr) and shell, as context in the legend and the Archive | The shell itself is the dense clumps from Edenhofer at 100–150 pc; no second model | Cited |
| Gas mass per hydrogen | Draine 2011, *Physics of the Interstellar and Intergalactic Medium*, Table 1.4 | 1.4 m_H per H nucleon (helium and metals) | Drag and glow follow mass flux, not proton count | Cited |
| Grain sizes, small grains | Mathis, Rumpl & Nordsieck 1977, ApJ 217, 425 (MRN); Weingartner & Draine 2001, ApJ 548, 296 | dn/da ∝ a⁻³·⁵ from 5 nm to 0.25 µm | The standard distribution behind extinction curves. WD01 refines it (bumps, an exponential cutoff) without changing the energetics that matter here | Cited |
| Grain sizes, the large-grain tail and the local dust density | Krüger et al. 2015, ApJ 812, 139 (987 Ulysses impacts, 1992–2007); Landgraf et al. 2000, JGR 105, 10343; Frisch et al. 1999, ApJ 525, 492 | Dust mass density (2.1 ± 0.6) × 10⁻²⁴ kg m⁻³ in the LIC, so a gas-to-dust ratio of 193 (+85/−57); grains up to about 10⁻¹³ kg (2 µm) measured, the detector-size limit near 10⁻¹¹ kg (10 µm); a flux of about 10⁻⁷ m⁻² s⁻¹ for grains of 10⁻¹³ kg and above; grain density 2,500 kg m⁻³ | The only in-situ measurement of interstellar grains. It is what makes visible flashes possible at all (§6.4) | Cited |
| Dust-to-gas elsewhere | Draine 2011 (M_dust / M_H ≈ 0.010) | Dust mass per H nucleon δ = 0.010 m_H in the Edenhofer clouds and the LLCC (the LIC's δ = 0.0051 is from Krüger's density, §4.1) | The standard Milky Way value | Cited |
| Grain survival in hot gas | Draine & Salpeter 1979, ApJ 231, 77 | Sputtering lifetime of a 0.1 µm grain at n_H 0.004, 10⁶ K is about 10⁸ yr, longer than the bubble's age | Justifies keeping the local δ in the hot gas (an assumption, shown with an alternative in I8) | Cited |
| Relativistic dust impacts, context | Hoang, Lazarian, Burkhart & Loeb 2017, ApJ 837, 5 | Cross-check of grain rates and energies for a relativistic craft | Independent literature on exactly this problem (Starshot) | Cited |
| Alternatives considered | Gry & Jenkins 2014, A&A 567, A58 (one continuous cloud, not 15); Baggaley 2000, JGR 105, 10353 (radar interstellar meteoroids to 40 µm, disputed: Musci et al. 2012, ApJ 745, 161) | Not used by default; Q3 asks about the radar tail | Gry & Jenkins changes velocity assignments, not the total columns that drive drag and glow | — |

**Bundling.** Only derived products go into the game: `sim/data/ism.ail` and `data/ism/ism.json` (generated by one AILANG tool from the cited tables and the Edenhofer crop, about 60 KB together, in git like `sim/data/stars.ail`) and the attribution line. The raw Edenhofer FITS is fetched by `make ism-raw` into `data/raw/edenhofer2024/` with a sha256 pin in `data/ism/SHA256SUMS`. If a 2 pc density texture is used for a soft map haze (optional, I6), it goes to the public bucket under `gs://stapledons-voyage-assets/ism/` with a sha256 pin (Mark's standing approval).

## 4. The density field

### 4.1 The model, `lism-1`

Frame: heliocentric galactic Cartesian, the same as `data/starmap` (x toward the Galactic centre, y toward rotation, z to the north pole), in light years in the sim and parsecs in the data tables. Each point belongs to exactly one medium, by fixed precedence (first match wins):

1. **LLCC sheets** (n_H 3,000, δ = 0.010), thin slabs digitised from Peek 2011 / Meyer 2012.
2. **Edenhofer clumps** (69–150 pc): ellipsoids, each with its mean n_H (from extinction) and δ = 0.010.
3. **The 14 Redfield & Linsky clouds** (named): each is a cone shell. Its axis is the cloud's centre (l, b); its half-angle gives a cap with the cloud's projected area (Ω = A_sky, so cos θ = 1 − Ω/2π); it starts at the LIC edge along that direction and is as deep as the median H I column of its sight lines divided by n_HI = 0.2 cm⁻³, but never beyond its nearest star. n_H = 0.247 cm⁻³, δ = 0.0051.
4. **The LIC**: inside the surface r(Ω̂) = Σ a_lm Y_lm(Ω̂) about the Table 3 centre. n_H = 0.247 cm⁻³, δ = 0.0051.
5. **Local Bubble hot gas** everywhere else: n_H = 3.9 × 10⁻³ cm⁻³, δ = 0.0051 (a labelled assumption; the I8 sheet also shows 0.002).

The cone shells are a game approximation and are labelled so: Redfield & Linsky give each cloud's outline on the sky and an upper limit on its distance, not a 3D shape. The column along each cloud's own sight lines is preserved by construction (tested, §8 AC6).

Into the bubble physics goes the **mass-equivalent proton density** n = n_H (μ_H + δ), with μ_H = 1.4 (gas mass per H nucleon, in m_H) and δ the dust mass per H nucleon (in m_H). δ is an absolute calibration, not a ratio to an assumed gas mass, so it cannot drift with the helium bookkeeping (plan review F3): in the local warm clouds and the hot gas δ = ρ_d / (n_H m_H) = 2.1 × 10⁻²⁴ / (0.247 × 10⁶ × 1.6735 × 10⁻²⁷) = 0.0051 (Krüger et al. 2015's measured dust density over Slavin & Frisch's n_H, the same pair Krüger used; their quoted ratio of 193 is not used directly); in the Edenhofer clouds and the LLCC δ = 0.010 (Draine 2011, M_dust/M_H). The wall reflects every massive particle (D-11), so drag and the mean glow follow the whole mass flux, dust included. The resolved flashes (§6) add their light on top; that double-counts at most δ/μ_H ≈ 0.4 % of the glow's energy (accepted and stated, rather than subtracting the resolved grains from the mean).

`uniform` stays as a scenario model: n = `ism_n_cm3` everywhere, which reproduces every HB value and every recorded stream byte for byte.

### 4.2 Resolution along a route

There is no sampling. Every medium is a region with an analytic or bracketed boundary:
- ellipsoid and cone (half-angle plus two spheres): closed-form chord intersections;
- the LIC: a star-shaped surface about its centre, so a line enters and leaves where r(direction) = |x − c|. The crossings are bracketed on a fixed grid of 64 steps along the segment, then refined by 60 bisections (well below a metre);
- LLCC slabs: plane intersections.

`profile(a, b)` returns the ordered segments [(s₀, s₁, medium, n_H, δ)] along a straight leg; `column(a, b)` = Σ n_H Δs. Both are pure, deterministic, and the same function is used by the plan, the per-tick ledger and the map. Per tick the sim integrates over the piece it actually flew (at γ 707 one 20 Hz transit tick covers up to 3.5 ly, so point sampling would miss whole clouds).

### 4.3 What the routes cross (to be confirmed by I4's tests)

- **Sol → α Cen (1.32 pc).** The Sun is just inside the LIC edge; the line leaves the LIC within about 0.1 pc and crosses the G cloud. Linsky 2019 Table 4: log N(H I) = 17.6 toward α Cen, 0.70 pc neutral path. Check: the model's H I column toward α Cen is 10^17.6±0.15 cm⁻².
- **Sol → Aldebaran (20 pc, l 181°, b −20°).** The LIC, then the Hyades cloud (centre l 180°, b −20°, 1,810 sq deg, nearest star 5 pc), then the hot gas. The guided voyage crosses a named cloud on its last leg.
- **Sol → TRAPPIST-1 (12.4 pc, l 70°, b −57°).** The LIC, then hot gas (the Eri cloud's cap ends about 12° away).
- **Toward Leo (e.g. Regulus, 24 pc, l 226°, b +49°).** Whether the line crosses an LLCC sheet is decided by the digitised outline in I3. If it does, Regulus at 0.999999c is refused (§5) and becomes the showcase choice.

## 5. Consequences in the sim

All through package calls with n from §4.1 (rapidity forms throughout; never 1 − β by subtraction):

- **Live** (`ismNow`): the ship's medium at its position, n_H, n, and the existing `load_w_m2`, `drag_n`, `glow_w_m2`, `glow_pole_w_m2`, `glow_pole_k`, now at the local n.
- **Ledger:** the cruise drag energy over each flown piece is `columnDragEnergy(N, φ, R)` = N_eff sinh φ m_p c² πR², with N_eff the mass-equivalent column of that piece. For a uniform medium it equals today's `cruiseDragEnergy(n, φ, R, d)` exactly (a tested identity), so the "ledger equals plan at arrival" invariant carries over.
- **Plan:** the route profile, the medium list with lengths, the peak n, the trip energy by column, and the **drive-hold limit**: the largest rapidity whose drag at the peak density the drive can still overcome, φ_hold = asinh √(m_eff a / (n_peak m_p c² πR²)). The rule uses the peak over the **whole cruise**, not only the braking stretch (plan review F10): holding a constant cruise speed needs thrust equal to the drag everywhere along it, and the drive's force is capped at m_eff a, so in a denser patch the ship could neither hold its speed nor, on the far side, brake. (Letting the ship coast down through a cloud is a later design.) A plan above the limit is refused (`m_eff_too_small`, as today) and the plan preview shows the highest accepted speed for that route. Under `lism-1` the scenario-level check (`scenarioError`: brake against drag at the cap) uses the hot-gas floor, so a cap is valid if it can be flown somewhere; each plan is then checked against its own route. With canon m_eff = 1 kg and boost 7.5 × 10⁵ g (spike estimates, to be replaced by package check values):

| Medium (peak n_H) | Highest cruise the brake holds | 1 − β |
|---|---|---|
| Local Bubble hot gas (0.0039) | γ ≈ 16,700 | 1.8 × 10⁻⁹ |
| LIC / G and the other warm clouds (0.247) | γ ≈ 2,100 | 1.1 × 10⁻⁷ |
| A diffuse Edenhofer cloud (10) | γ ≈ 334 (0.9999955c) | 4.5 × 10⁻⁶ |
| A denser clump (100) | γ ≈ 105 | 4.5 × 10⁻⁵ |
| The LLCC (3,000) | γ ≈ 19 (0.9987c) | 1.3 × 10⁻³ |

So the slider's top (0.999999c, γ 707) is fine through the local warm clouds and the bubble, and is refused through any cloud denser than about 2 cm⁻³.

**The guided voyage (plan review F1).** It flies m_eff = 10 kg at 3 × 10⁶ g (`demos/solar_departure.gd` `GUIDED_DRIVE`), a brake of 2.94 × 10⁸ N, with cap 1 − β = 2 × 10⁻⁹ (γ 15,811). Its hold limit is γ ≈ 13,300 in the LIC, G and Hyades clouds and γ ≈ 107,000 in the hot gas. Its fastest legs, the 1,000 AU timed hops, peak at γ ≈ 7,500 (finite-destination-stars.md), below the warm-cloud limit, so they plan; the cap itself is checked against the hot-gas floor (above). AC10b requires that every guided-itinerary plan (Sol departure, α Cen, TRAPPIST-1, Aldebaran and each stop) is accepted under `lism-1`; if one is not, the sprint stops and asks Mark (Q8), with no silent change to the guided drive. That is the strategic choice: slow down for the cloud, or go around it via another star (two commitments at the navigation station), and pay the Earth years.

- **Glow at the local density.** The canon ε = 10⁻¹⁰ was chosen at n = 0.1 (HB-111). In the LIC the mass-equivalent n is 0.35, so the pole is about 3.5× brighter than the HB values; in the hot gas it is about 64× dimmer. The glow becomes the density gauge Mark asked for. Spike estimates at the forward pole (HB method, n_eff = 1.4 n_H):

| | Hot gas | LIC / G | Cloud n_H 10 | Cold cloud n_H 1,000 |
|---|---|---|---|---|
| 0.999c: T, luminance | 1,207 K, 2 × 10⁻⁴ dark skies | 3,384 K, 91 dark skies | 8,537 K, 9.5 × 10³ | 27,000 K, 1.2 × 10⁵ |
| 0.999999c: T, luminance | 6,866 K, 4.4 × 10³ | 19,247 K, 6.7 × 10⁴ | 48,500 K, 2.7 × 10⁵ | (refused) |

Within D-59: denser media make the high-speed view whiter, never darker; no glazing dims it.

## 6. Dust-grain impacts

### 6.1 The grain population

A broken power law in radius, normalised to the medium's dust mass density ρ_d = δ n_H m_H (§4.1; ρ_d = 2.1 × 10⁻²⁴ kg m⁻³ in the LIC exactly, by construction):
- dn/da ∝ a⁻³·⁵ for 5 nm ≤ a ≤ 0.25 µm (MRN);
- dn/da ∝ a⁻q for 0.25 µm < a ≤ a_max (the measured big-grain tail), continuous at 0.25 µm;
- a_max = 9.85 µm (10⁻¹¹ kg at 2,500 kg m⁻³). This is Krüger 2015's detector-limited upper mass, not a physical edge, so it is a scenario parameter and the brightest-flash rates are sensitive to it (plan review F4): I8's sheet shows a_max 5, 10 and 20 µm, and δ in the hot gas 0.0051 vs 0.002 (some sputtering), both labelled assumptions in the legend and the Archive;
- q is fitted once (in the package test, against the cited numbers): with ρ_d = 2.1 × 10⁻²⁴ kg m⁻³ at n_H = 0.247 it gives q ≈ 3.1, and a flux of grains of 10⁻¹³ kg and above at 26 km/s of 5.5 × 10⁻⁸ m⁻² s⁻¹ (measured: about 10⁻⁷). 94 % of the dust mass is in the tail, as Krüger 2015 and Landgraf 2000 find for the local cloud (in conflict with extinction-based models; Draine 2009). The same shape is assumed in every medium (labelled assumption: only the LIC is measured in situ).

### 6.2 How many hit, and how hard

- **Count.** The grains swept are the grains in the swept volume, A ∫ n_gr ds, the same in every frame. A light year of LIC holds about 5 × 10¹¹ grains of 0.1 µm and above, 3.2 × 10⁹ of 1 µm and above, 2.9 × 10⁸ of 3 µm and above and 5 × 10⁶ of 9 µm and above for our 100 m bubble. **The number of impacts on a route does not depend on speed; their energy and their rate per ship second do.** Rate per ship second = A n_gr γβc.
- **Energy.** A grain of mass m arrives at the wall (ship frame) with kinetic energy (γ − 1) m c² = 2 sinh²(φ/2) m c². Like every massive particle it is reflected (D-11); an ε fraction of its kinetic energy becomes light, as for the gas.

Rates over the whole wall per ship second (spike estimates; the package replaces them):

| | ≥ 0.1 µm | ≥ 0.3 µm | ≥ 1 µm | ≥ 3 µm | ≥ 9.8 µm |
|---|---|---|---|---|---|
| Kinetic energy at 0.999c (γ 22.4) | 20 J | 540 J | 2.0 × 10⁴ J | 5.4 × 10⁵ J | 1.9 × 10⁷ J |
| Kinetic energy at 0.999999c (γ 707) | 660 J | 1.8 × 10⁴ J | 6.6 × 10⁵ J | 1.8 × 10⁷ J | 6.3 × 10⁸ J |
| Rate, hot gas, 0.999c | 5,700 /s | 460 /s | 36 /s | 3.3 /s | 0.003 /s |
| Rate, LIC / G, 0.999c | 3.5 × 10⁵ /s | 2.8 × 10⁴ /s | 2,200 /s | 210 /s | 0.19 /s |
| Rate, hot gas, 0.999999c | 1.8 × 10⁵ /s | 1.5 × 10⁴ /s | 1,200 /s | 110 /s | 0.1 /s |
| Rate, LIC / G, 0.999999c | 1.1 × 10⁷ /s | 9 × 10⁵ /s | 7.1 × 10⁴ /s | 6,500 /s | 6 /s |

(In an Edenhofer cloud at n_H 10, multiply the LIC rates by about 79 (n_H ratio 40 × δ ratio 1.96); the top speeds are refused there anyway, §5. The spike behind these tables normalised the clouds with gas-to-dust 193/100, within 2 % of the δ calibration; the package's values replace them.)

### 6.3 The flash: an afterglow at the wall (game approximation, labelled)

Applied literally, the glow's own rule (local radiative equilibrium, no lateral conduction, no thermal lag) makes a grain impact a femtosecond hot spot the size of the grain, at around 10⁸ K: X-rays, with no visible light at all. So a visible flash needs one more stated approximation, which D-60 anticipated ("a wall afterglow, if used, is labelled a game approximation"):

> **Wall afterglow (game approximation G-AG).** The ε fraction of a grain's kinetic energy is released as light from a disc of radius r_s on the wall around the impact point, decaying as e^(−t/τ). Each instant the disc is a greybody of emissivity ε, exactly as the glow is (D-30), so ε cancels in its temperature: T(t) = (KE / (σ π r_s² τ))^¼ e^(−t/4τ). The inward emittance is ε f_in KE e^(−t/τ) / (π r_s² τ). The total light is ε f_in KE, set by physics and the canon ε; r_s and τ only shape it.

Defaults r_s = 0.5 m, τ = 0.2 s (the eye integrates flashes over about 0.1 s, Bloch's law), chosen by a render-comparison sheet as ε was (Q2). The spectrum is a blackbody at T(t) through the existing `Blackbody` lookup, and the luminance goes through `Exposure.k()`, so a flash is exactly as visible as its light is against the glow and the CMB disc.

### 6.4 What the player sees (spike estimates)

The thresholds are physical (luminance against the physical background); the player's Auto/Realistic exposure (D-38, D-56 display controls) only changes how the renderer maps that light through `Exposure.k()`, never which grains are drawn. A flash is drawn when its peak luminance is at least 5 % of the local background (the glow there plus the dark sky; 5 % is a perceptual floor for a half-degree spot, Blackwell 1946). A "bright" flash outshines the background (contrast ≥ 1); a "brilliant" one is ten times it (contrast ≥ 10). Rates are over the whole forward wall per ship second; a 60° forward view sees about a quarter of them.

| | Smallest visible grain | Visible (≥ 5 %) | Bright (≥ 1×) | Brilliant (≥ 10×) |
|---|---|---|---|---|
| Hot gas, 0.99c | 3.1 µm | about 1 /s | — | 4.2 µm and up: 0.5 /s |
| LIC / G, 0.99c | 3.2 µm | about 56 /s | — | 4.3 µm and up: 27 /s |
| Hot gas, 0.999c | 1.5 µm | about 15 /s | 2.1 µm and up: 8 /s | 2.7 µm and up: 4 /s (a 9.8 µm grain is 4,000× the background) |
| LIC / G, 0.999c | 2.5 µm | about 315 /s | 3.9 µm and up: 110 /s | 6.3 µm and up: 28 /s |
| Hot gas, 0.9999c | 1.5 µm | about 46 /s | — | 2.1 µm and up: 23 /s |
| LIC / G, 0.9999c | 5.8 µm | about 120 /s | — | none |
| Hot gas, 0.999999c | 1.4 µm | about 540 /s | 3.1 µm and up: 96 /s | 9.3 µm and up: 1.3 /s |
| LIC / G, 0.999999c | 2.9 µm | about 7,300 /s, all fainter than the glow | none | none |
| Cloud n_H 10, 0.999c | 5.4 µm | about 3,700 /s, all fainter than the glow | none | none |

So:
- Without the measured big-grain tail no flash is ever visible (MRN grains stop at 0.25 µm; at γ 707 a 0.25 µm grain's afterglow is only about 1,100 K). The sparks exist because Ulysses caught big grains, which is the Archive's story.
- In the warm local clouds at 0.99–0.999c the forward dome sparkles steadily (tens of brilliant flashes per second). Crossing into the hot bubble the glow dims and the sparks thin out to a few per second, but each one stands out more.
- More grains hit inside clouds, yet the brighter glow there swallows all but the largest, so at the top speeds a cloud is a white glow with a faint glitter (D-59), while the hot bubble still shows the occasional brilliant flash (about one a second at 0.999999c).

This is an honest, physical outcome, and Mark should see it before execution (Q1, Q3).

### 6.5 Determinism and the two tiers

- **Bright tier (individual events, sim-owned).** Totals first: for every flown piece the sim adds the expected and the drawn number of grains above the bright threshold a_b(φ, medium), Poisson(A N_gr(>a_b)), to the leg's readouts, exactly, at any pacing. Individual events are drawn only inside the piece's **display window** w = min(dτ, w_rt), where w_rt = 0.05 ship seconds is what one 20 Hz tick holds at real time (a sim parameter, so the sim never reads a wall clock). At real-time pacing w = dτ and every bright grain is an event; under compression the events are a true sample of the real-time rate and the totals stay exact. For each event the sim draws a size (inverse CDF of the truncated power law), a wall point (uniform on the projected disc, so cos θ-weighted on the wall) and a time within the window. Random numbers come from a **stateless** stream, `splitmix64(seed ⊕ dust_salt, tick · 1024 + j)` with a fixed layout: j = 0–1 the window's Poisson draw, then 4 per event (size, two for the disc point, time), k < 32 events, so at most 130 of the 1,024 slots are used (plan review F2). The existing `Rng` streams are not consumed, so nothing else in a replay moves. At most 32 events per window are emitted (the brightest kept first) with the dropped count; at the real-time rate the expected bright count per window is at most about 6 (LIC at 0.999c, 110 /s × 0.05 s), so more than 32 has a probability below 10⁻¹², and a test asserts 0 dropped in every real-time-paced stream, and for compressed streams that the window count stays at or under the cap while the totals match their expectation within 3σ.
- **Glitter tier (statistical, renderer-drawn).** The faint flashes (5 % ≤ contrast < 1) are too many to send. The sim sends their rate per ship second, the size range, q, the afterglow parameters and a per-tick seed. The renderer draws them with a GDScript mirror of the package's sampler (tested against the package on fixed seeds), so the same seed and inputs give the same picture.
- **Time compression.** Flashes are physical at one ship second per wall second (the guided tour's real-time cruise, D-39). Under compression (interludes, map transit) the sim still integrates every count and energy exactly, but the renderer shows the real-time rate and the HUD labels the readout "per ship second". The interlude card reports the totals for the cruise it skipped.
- **Readouts:** grains swept on this leg, visible flashes, the largest grain and its energy, the total impact energy (it is part of the drag ledger already, through δ in n).

## 7. Presentation

### 7.1 In flight (D-56: the HUD informs, it never decides)

Built on R1-SHIP-UI's ShipHud (milestone I7 waits for its U2):
- **Transit card**, new rows after "ISM load": *Medium* (e.g. "G cloud · warm, partly ionised"), *Density* (n_H in cm⁻³ and atoms per litre), *Dust impacts* (visible flashes per ship second; the largest this leg and its energy). The existing load and glow rows now vary along the route.
- **Medium notice** (a notice card, 8 s, priority with the brake notices): "Entering the Hyades cloud · n_H 0.25 cm⁻³ · 64× the bubble's gas", "Leaving the Local Interstellar Cloud".
- **Interlude card**: the media crossed during the skipped cruise, with lengths, grains swept and the brightest impact.
- The glow brightens and dims by itself (sim fields); the flashes are additive sprites in the sky SubViewport, before the one tonemap, beside `glow_overlay.gdshader`.
- Display controls stay instant (D-56 clarification): Tab shows the medium details; the I key on empty forward sky shows the "medium here" card.

### 7.2 On the galaxy map (the read-only chart and the helm)

- **ISM layer** (instant display toggle, key `D` for dust and gas, in the chart and the helm): the LIC surface as a translucent mesh from its harmonic model, the 14 cloud shells (labelled, coloured by n_H on one logarithmic scale), the LLCC sheets, the Edenhofer clumps as ellipsoids, and a legend line: "Everything else: the Local Bubble's hot gas, n_H ≈ 0.004 cm⁻³ (Snowden 2014). Sources: Redfield & Linsky 2008; Linsky et al. 2019; Peek et al. 2011; Edenhofer et al. 2024 (CC BY 4.0)."
- **The planned route** is drawn in segments coloured by medium.
- **Plan rows** (after "Drag energy"): *Media crossed* (one line per medium: name, length in ly), *Peak density*, *Peak load* (suns), *Top speed the brake can hold on this route* (β and 1 − β), *Grains swept* and *Expected visible flashes*. Above the limit the plan is refused with that reason, as today.
- Everything shown is a sim field or the generated `data/ism/ism.json`, from the same generator as `sim/data/ism.ail` (one truth, as `starmap-single-truth`). The map code lives in a new `ui/ism_layer.gd` with a few hook lines in `galaxy_map.gd`, to stay clear of R1-SHIP-UI's chart/helm work.

### 7.3 Lore (drafts for Mark; canon text is his call)

`archive.ism-glow` is corrected ("one atom in every ten cubic centimetres" becomes the measured range), and a new entry, "Weather between the stars", explains the clouds, the hot bubble and the Ulysses grains. Both cite the new check-value IDs (`make lore-check`).

## 8. Performance

- Per tick: one `medium` lookup (about 30 analytic region tests) and one `profile` over the flown piece; target under 0.5 ms on the strict VM (`make ism-bench`). Plan profile under 20 ms.
- NDJSON: at most 32 bright events per tick (about 2 KB) plus the glitter descriptor; nothing at rest.
- GPU: one extra additive pass (or the glow pass extended) with up to 64 flash sprites and a glitter field drawn by hash in the shader; target under 0.3 ms at 1440p on the Studio (`make bench`).
- Offline: `make ism-data` reads about 380 MB of the 3.25 GB FITS (the shells inside 160 pc); target under 10 minutes.

## 9. Package functions (package first; check values in the spec PR, milestone I0)

**`sunholo/celestial` → next minor (0.4.0 if free), new module `celestial/ism`** (geometry and astrophysics of the medium; no relativity):

| Function | What | Check |
|---|---|---|
| `realSphericalHarmonic(l: int, m: int, theta: float, phi: float) -> float` | Real Y_lm, l ≤ 2, in the Redfield & Linsky 2000 convention | Normalisation tested by quadrature; the convention is fixed by the next row |
| `starSurfaceRadius(coeffs: [float], dir: Vec3) -> float` | r(Ω̂) = Σ a_lm Y_lm | Reproduces Linsky 2019 Table 2's 62 edge distances with median \|Δ\| ≤ 0.40 pc (their Table 3) |
| `starSurfaceChords(centre, coeffs, a: Vec3, b: Vec3) -> [Interval]` | Bracket (64 steps) and bisect (60) the crossings | Sun inside the LIC; α Cen leg leaves it within 0.2 pc |
| `ellipsoidChord`, `coneShellChord`, `slabChord` | Closed-form intervals of a segment inside each shape | Oracle (NumPy) to 1e-12 |
| `nHFromExtinction(avPerPc: float, nhPerEbv: float, rV: float) -> float` | n_H = (N_H/E(B−V)) A_V′ / (R_V pc) | 606.1 cm⁻³ per mag pc⁻¹ at Bohlin, R_V 3.1 |
| `healpixRingVec(nside: int, pix: int) -> Vec3` | HEALPix RING pixel centres (Górski et al. 2005) | healpy oracle on 10⁴ pixels to 1e-15 |
| `grainDist(rhoDust, aMin, aBreak, aMax, q, rhoGrain) -> GrainDist` | Broken power-law normalisation | ρ_d recovered to 1e-12; the LIC flux of ≥ 10⁻¹³ kg grains at 26 km/s within a factor of 2 of 10⁻⁷ m⁻² s⁻¹ (Krüger 2015) |
| `grainsAbove(d: GrainDist, a: float) -> float`, `grainRadiusAt(d, a0: float, u: float) -> float` | Number density above a; inverse-CDF sample above a0 | LIC grains per ly above 1 µm: 3.17 × 10⁹ (spike value, to be fixed) |
| `poissonDraw(mean: float, u: float, v: float) -> int` | Inversion below 30, rounded normal above | χ² test over 10⁴ fixed seeds |

**`sunholo/relativity` → next minor (0.12.0 if free): `medium` additions and a new module `relativity/dust`:**

| Function | Formula | Check |
|---|---|---|
| `medium.massEquivalentDensity(nH: float, muH: float, deltaDust: float) -> float` | n_H (μ_H + δ) (m⁻³) | 0.247 cm⁻³, 1.4, 0.0051 → 3.4706 × 10⁵ m⁻³ |
| `medium.columnDragEnergy(nCol: float, phi: float, r: float) -> float` | N sinh φ m_p c² πR² | Equals `cruiseDragEnergy(n, φ, R, d)` when N = n d (HB-51…HB-56) |
| `medium.tripEnergyColumn(p: TripPlan, mEff: float, nColCoast: float, r: float) -> TripEnergy` | As `tripEnergy`, drag by column | Equals `tripEnergy` for a uniform medium |
| `medium.driveHoldMaxPhi(mEff: float, a: float, n: float, r: float) -> float` | asinh √(m_eff a / (n m_p c² πR²)) | `brakeHoldsAgainstDrag` is true just below it and false just above; γ ≈ 19.3 at n_eff = 4,200 cm⁻³ |
| `dust.grainKinetic(m: float, phi: float) -> float` | 2 sinh²(φ/2) m c² | 1 µm, 2,500 kg m⁻³: 2.011 × 10⁴ J at 0.999c; 6.646 × 10⁵ J at 0.999999c |
| `dust.sweptCount(nGrainCol: float, r: float) -> float` | πR² N_gr | Frame-independent (tested at three φ) |
| `dust.grainRate(nGrain: float, phi: float, r: float) -> float` | n_gr sinh φ c πR² (per ship second) | Consistent with `sweptCount` over a cruise |
| `dust.afterglowTemperature(ke: float, rSpot: float, tau: float, t: float) -> float` | (KE/(σ π r_s² τ))^¼ e^(−t/4τ) | 5 µm at 0.999c, r_s 0.5 m, τ 0.2 s |
| `dust.afterglowEmittance(ke, eps, fIn, rSpot, tau, t) -> float` | ε f_in KE e^(−t/τ)/(π r_s² τ) | Time integral × area = ε f_in KE (1e-12) |
| `dust.afterglowLuminance(ke, eps, fIn, rSpot, tau, t) -> float` | (E/π) η(T) via `blackbody.luminousEfficacy` | Spike values in §6.4 |
| `dust.visibleRadius(d: GrainDist, phi, eps, fIn, rSpot, tau, bgLuminance, contrast) -> float` | Smallest a whose peak afterglow luminance ≥ contrast × background (bisection, 60 steps; a_max+ if none) | §6.4 rows |

Every function: float64, rapidity forms, NaN in gives NaN out (`x == x` guards), tests against an independent Python oracle (`tools/ism_dust_ref.py`, role oracle), CHANGELOG, `[release] kind = "minor"`, `ailang pkg quality` with no gates, then publish. The sim pins the new versions; GDScript and shaders mirror only the shapes (the afterglow decay, the samplers) and are tested against package values.

## 10. Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | `celestial/ism` tests pass, including the Linsky 2019 Table 2 reproduction (median \|Δ\| ≤ 0.40 pc) and the healpy and NumPy oracle rows; quality has no gates; the version is published | In a scratch clone of `sunholo-data/ailang-packages` (under this repo's ignored `scratch/`): `ailang test packages/celestial && ailang pkg quality packages/celestial`; then `ailang pkg info sunholo/celestial` shows the new version |
| AC2 | `relativity/dust` and the `medium` additions pass every check in §9; the uniform-medium identities hold to 1e-12; published | Same clone: `ailang test packages/relativity && ailang pkg quality packages/relativity`; `ailang pkg info sunholo/relativity` |
| AC3 | The design-repo spec PR (its number recorded in the sprint JSON as `spec_pr` when I0 opens it) holds the new check values (IS-n for structure, HB-113+ for grains and the afterglow), each source number with its table and page (the I0 source-verification list), and is merged before the sim pins | `gh pr view $(jq -r .spec_pr .ailang/state/sprints/sprint_R1-ISM-DUST.json) -R sunholo-data/stapledons-design --json state` = MERGED |
| AC4 | `make ism-data` is reproducible: two runs give byte-identical `sim/data/ism.ail` and `data/ism/ism.json`, matching the pins | `make ism-data && make ism-data-verify` |
| AC5 | The Edenhofer crop and its unit conversion are right, checked against independent anchors: (a) the near-side distances of Taurus (about 130–140 pc) and the Ophiuchus/Lupus clouds (about 120–150 pc) from Zucker et al. 2019/2020 cloud distances fall within ±15 pc of the first clump on those rays; (b) the integrated E(B−V) to 150 pc along 20 fixed directions agrees with Leike, Glatzle & Enßlin 2020 (an independent map) within a factor of 2; (c) a unit test feeds `fits_slice.gd` a synthetic FITS with known values in both axis orders | `make ism-oracle` |
| AC6 | Independent of how the clouds are built: (a) for the stars in Redfield & Linsky 2008 Tables 1–15 within 15 pc, the model's sight line crosses the cloud the paper assigns to that star for at least 80 % of them (membership, not depth); (b) α Cen's H I column (built from RL08 medians) matches Linsky 2019 Table 4, 10^(17.6±0.15) cm⁻², a different paper's measurement; (c) the digitised LLCC outline puts the stars Peek 2011 / Meyer 2012 list with LLCC absorption inside it and their listed non-detections outside it; a route through the LLCC at 0.999999c is refused and at 0.998c accepted | `make ism-test` |
| AC7 | Media along the routes: Sol is in the LIC; Sol → α Cen crosses G; Sol → Aldebaran crosses Hyades; profiles are ordered, gap-free and cover the leg exactly | `make ism-test` |
| AC8 | `ism_model = uniform` reproduces every recorded stream and every HB value byte for byte; the re-recorded `lism-1` baselines (named in the sprint JSON `rerecorded`) are listed in the PR and approved at P2 | `make replay && make test` |
| AC9 | The ledger closes: at arrival `ledger.drag_j` equals the plan's column drag energy to 1e-9 relative, at every transit rate and tour pacing, including the whole guided tour under `lism-1` | `make ism-test` |
| AC10 | The drive-hold limit: a plan above `driveHoldMaxPhi` at the route's peak density is refused `m_eff_too_small`; at the limit minus 1e-9 in φ it is accepted; the plan shows the limit | `make ism-test` |
| AC10b | Every guided-itinerary plan (Sol departure, α Cen, TRAPPIST-1, Aldebaran and each stop, `GUIDED_DRIVE`) is accepted under `lism-1`, or the sprint has stopped for Q8 | `make ism-test` |
| AC11 | Impacts are deterministic: two runs with the same seed and intents give byte-identical streams; a replay reproduces them; the existing `Rng` streams are unchanged | `make ism-determinism && make replay` |
| AC12 | Impact statistics on a fixed seed: the bright-tier totals over a long LIC leg match A N_gr(>a_b) within 3σ at real-time and at compressed pacing; wall points pass a KS test against cos θ; no impacts at rest; 0 events dropped in every real-time-paced stream, and the window count ≤ 32 in compressed streams; the stream layout uses at most 130 of 1,024 slots per tick | `make ism-test` |
| AC13 | The sim core stays pure: `sim/ism.ail` passes `--strict-bytecode`; the VM and the interpreter agree bit for bit on the ISM streams | `make strict && make parity` |
| AC14 | GPU vs CPU: the flash sprite (peak and decay), the afterglow colour ramp and the glitter count match the CPU reference sub-pixel | `make golden` (cases G-ISM-1…3) |
| AC15 | Every lookup is finite over its whole range (afterglow temperature to 10⁷ K, glitter sampler at u ∈ {0, 1}) | `make test` (`tests/test_dust_flash.gd`) |
| AC16 | The map: the ISM layer draws every medium in `ism.json`; the route is segmented by medium; the plan rows show the sim's fields; the layer key is a display control (no intent is sent) | `make map-ism-test`; `make no-twitch-test` |
| AC17 | The HUD: the transit card's medium rows, the medium notice on each boundary and the interlude summary appear from sim fields | `make ship-ui-test` (new cases) |
| AC18 | Renders exist and were opened: flight frames in hot gas, the LIC/G, a cloud and the Hyades cloud at 0.99c, 0.999c, 0.9999c and 0.999999c; a flash close-up; the afterglow comparison sheet; map views of the local clouds and the 100 pc clumps; no uniform or NaN frame | `make ism-capture` → `renders/ism/*.png` + contact sheet |
| AC19 | Performance within §8's budgets | `make ism-bench` |
| AC20 | New Python files are listed with role `oracle` | `make python-guard` |
| AC21 | The Archive drafts cite registered IDs only | `make lore-check` |
| AC22 | Everything above runs in CI | `make test` green locally and in CI |

AC5 and AC6(c) belong to PR B (the Edenhofer clouds and the LLCC); PR A must pass every other row.

## 11. Sub-milestones (two PRs; plan review F6)

**PR A** (the medium that matters for the tour, and the grains): I-1, I0, I1, I2, I3a, I4, I5, I6, I7, I8, I9. **PR B** (the dense clouds): I3b and its map and test additions, landing after PR A on the same sim interfaces. Splitting keeps the 3.25 GB pipeline and the hand digitisation off the critical path of the first merge.

| ID | What | LOC | Depends | PR |
|---|---|---:|---|---|
| I-1 | Bump the pins to the latest published `sunholo/relativity` and `sunholo/celestial` (no new functions yet); `make test`, `make parity`; separate commit (plan review F11) | 20 | approval | A |
| I0 | Spec PR (design repo): new `physics/ism-structure.md` (IS-n) and higgs-bubble.md §5/§6 amendments (HB-3 becomes the `uniform` value; HB-113+ for grains and the afterglow, G-AG labelled); a **source-verification list** recording table and page for every quoted number, flagging any it cannot reproduce (F7); the Python oracle that computes the values | 180 (oracle) | approval | A |
| I1 | `sunholo/celestial` `ism` module, oracle, publish | 520 | I0 | A |
| I2 | `sunholo/relativity` `dust` module and `medium` additions, oracle, publish | 440 | I0 | A |
| I3a | The cited LISM tables (LIC harmonics, the 14 clouds, warm and hot densities, δ) as provenance `Field`s → `sim/data/ism.ail`, `data/ism/ism.json`; `make ism-data`, `make ism-data-verify` | 220 | I1 | A |
| I3b | Edenhofer pipeline (`make ism-raw`, `tools/fits_slice.gd` handling either axis order, HEALPix → grid → clumps in `sim/tools/ism_build.ail`) and the LLCC digitisation; `make ism-oracle`; their map shapes and tests | 520 | I1, PR A | B |
| I4 | Sim: `sim/ism.ail` (medium, profile, column), the `lism-1`/`uniform` parameter, ledger by column, plan profile and hold limit, impacts (two tiers), protocol minor bump, determinism and replay | 720 | I2, I3a | A |
| I5 | Renderer: `interior/dust_flash.gd` (CPU reference) and the shader, goldens | 400 | I4 | A |
| I6 | Galaxy map: `ui/ism_layer.gd`, route segments, plan rows, toggle | 360 | I3a, I4 | A |
| I7 | HUD: transit rows, medium notice, interlude summary | 180 | I4, R1-SHIP-UI U2 | A (or follow-up) |
| I8 | Captures, the afterglow and sensitivity sheets (a_max, hot-gas δ, MRN-only), the per-medium ε sheet, inspection | 220 | I5, I6 | A |
| I9 | Archive drafts, CHANGELOG, index row, design-repo roadmap status | 60 | I8 | A |

Total about 3,840 LOC (PR A about 3,320, PR B about 520).

## 12. Risks and mitigations

| Risk | Mitigation |
|---|---|
| The LIC coefficients' normalisation convention is not stated in the paper | AC1 fixes it empirically: only the convention that reproduces Table 2 (median 0.40 pc) passes; both common conventions are tried in I1 |
| The cone-shell clouds are crude | Labelled as a game approximation; AC6 holds the columns that matter for drag and glow to the measurements |
| The 3.25 GB FITS strains AILANG I/O | Godot headless reads it with seeks (file I/O is Godot's job); AILANG gets only the 160 pc slice; if std/bytes lacks a big-endian float decode, Godot converts and the gap is reported upstream |
| Clump extraction on a 2 pc grid (3.4 M voxels) is slow in AILANG | Threshold first (n_H > 1: a sparse few per cent), union-find on the sparse list; runs offline once in the interpreter; a VM parity run on a small crop |
| The flash looks wrong or too busy | r_s and τ come from a comparison sheet Mark picks from (Q2), like ε; the brightness is fixed by physics |
| Visible flashes depend on a debated big-grain tail | Cited (Krüger 2015, Landgraf 2000) and labelled; the MRN-only alternative is one parameter and is in the comparison sheet |
| The glow near Sol changes (3.5× the HB values in the LIC) | Intended (D-60); the ε sheet is re-rendered for each medium (I8) for Mark; `uniform` keeps every old golden |
| Conflicts with R1-SHIP-UI and the free-nav PRs in `galaxy_map.gd` and the HUD | Map code in a new file with hooks; I7 waits for U2; rebase points in the sprint plan |
| Protocol minor collides with another branch | Take the next free minor at execution; tests read it from `protocol.ail`, never a literal |
| Stellar winds near stars (canon "bright near stars") are missing | Out of scope; noted for a later item |

## 13. Open questions for Mark

| # | Question | Recommendation |
|---|---|---|
| Q1 | Should grain flashes use the **same ε (10⁻¹⁰)** as the glow (one hand-wave constant; flashes visible from about 1.5–3 µm up; a steady sparkle in the warm clouds at 0.99–0.999c, sparser but starker flashes in the hot bubble, a faint glitter under the white glow at the top speeds), or a **separate grain fraction ε_g** tuned for more flashes? | **Same ε.** It keeps the one admitted hand-wave to one number, and the outcome (§6.4) is honest and readable. |
| Q2 | Pick the **afterglow shape** (r_s, τ) from a comparison sheet (defaults 0.5 m, 0.2 s; candidates 0.25/0.5/1 m × 0.1/0.2/0.4 s), labelled a game approximation? | **Yes,** reviewed at pause P2, as ε was. |
| Q3 | Include the **disputed radar-meteor tail** (grains to about 40 µm, Baggaley 2000), which would add very rare, very bright flashes everywhere? | **No by default.** Keep a_max at the Ulysses limit (10 µm); offer it as a scenario parameter. |
| Q4 | Make **`lism-1` the default** for new games (the glow near Sol 3.5× today's, much dimmer in the hot bubble), keeping `uniform` for scenarios and old replays, with ε unchanged? | **Yes.** It is the point of D-60; the per-medium ε sheet confirms the stars stay readable. |
| Q5 | The **drive-hold limit** makes the slider's top speed impossible through clouds denser than about 2 cm⁻³ (the LLCC caps it at 0.9987c). Show it as a refusal with the limit in the plan (today's rule), rather than auto-capping the speed? | **Refusal plus the limit shown.** The captain chooses: slow down or go around. |
| Q6 | Going around a cloud is done **via a star** (two commitments) for now; free-space waypoints later? | **Via a star now;** waypoints as a separate design after free navigation lands. |
| Q7 | Approve the **Archive drafts** (the corrected ism-glow entry and "Weather between the stars") at pause P2? | **Yes,** text reviewed at P2. |
| Q8 | Only if AC10b fails: if a guided-voyage leg would cross a cloud above its hold limit, should the guided drive change (m_eff or boost), that leg's speed drop, or the itinerary route around? | **Lower that leg's speed** (the drive stays one definition); expected not to arise (§5). |

## 14. Deliverables

- Package releases: `sunholo/celestial` (ism), `sunholo/relativity` (dust, medium additions), each with tests, oracle, CHANGELOG, published.
- Design-repo spec PR (IS-n, HB-113+).
- `make ism-raw`, `make ism-data`, `make ism-data-verify`, `make ism-oracle`, `make ism-test`, `make ism-determinism`, `make ism-bench`, `make map-ism-test`, `make ism-capture`; `sim/ism.ail`, `sim/data/ism.ail`, `data/ism/ism.json`, `data/ism/SHA256SUMS`; `interior/dust_flash.gd` and its shader; `ui/ism_layer.gd`; HUD rows; `renders/ism/`; Archive drafts; CHANGELOG entry.
