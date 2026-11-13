# Observation: photon budgets, link budgets and check values

**Version:** baseline-2026.11 (2026-11-12). **Status:** draft normative registry for
R3-REASONS milestone RT0. It awaits review in its draft PR. The labels in §3
(Verified, Adopted, Design, Ruling, unverified) are part of the data, not footnotes.
Four rulings (Mark, attended 2026-11-12) are recorded in §6.

## 1. What this registry pins

The ship is an observatory. This registry fixes the numbers that decide what
its instruments can see: how many photons arrive from a star or a planet, how
faint a planet is beside its star, how long a spectrum takes, how far a radio
transmitter can be heard, and how much extra infrared a civilisation's waste
heat adds to a star.

**The rule: an instrument's reach follows from a budget, never from an authored
range.** An instrument is a set of physical parameters (aperture, band,
throughput, noise). A target is a source of photons or radio power. The game
counts what arrives, compares it with the noise, and gets a signal-to-noise
ratio (SNR). No table anywhere says "this telescope sees 60 light-years". If a
distance appears in this file, it is the output of a formula in §2 for stated
inputs.

The package `sunholo/observe` 0.2.0 must reproduce every `OB-n` row in §4.
The functions it needs are named beside each formula. This file extends
[signals-and-instruments §4](../features/next/signals-and-instruments.md) and
obeys [life-and-worlds §5](life-and-worlds.md): "Use S2 photon budgets, never a
literal detection radius." The reach in LW-42 and LW-43 is the radius of a
count model. It is not an instrument range, and nothing here changes it.

This registry lives in its own file, not in `relativity-spec.md` (ruling 4,
§6). The game's `sim/tools/lore_values.ail` must be taught to read this file in
RT1, or `make lore-values` will not list the OB rows.

## 2. Formulas

SI units throughout unless a row states another unit. Angles are in radians
inside formulas.

### 2.1 Constants

| Symbol | Value | Meaning |
|---|---|---|
| h | 6.62607015 × 10⁻³⁴ J s | Planck constant (exact) |
| c | 299792458 m/s | speed of light (exact) |
| k | 1.380649 × 10⁻²³ J/K | Boltzmann constant (exact) |
| AU | 149597870700 m | astronomical unit (exact) |
| pc | 648000/π AU = 3.0856775814913673 × 10¹⁶ m | parsec |
| ly | c × 365.25 × 86400 s = 9.4607304725808 × 10¹⁵ m | Julian light-year |
| Jy | 10⁻²⁶ W m⁻² Hz⁻¹ | jansky, the radio flux-density unit |
| mas | π/(180 × 3600 × 1000) rad | milliarcsecond |
| R☉, T☉ | 6.957 × 10⁸ m, 5772 K | nominal solar radius and effective temperature |
| R⊕, R_J | 6.3781 × 10⁶ m, 7.1492 × 10⁷ m | nominal equatorial radii of Earth and Jupiter |

### 2.2 Photon rate from a star (`photonRate`)

The star is a **blackbody**: a sphere of radius R and temperature T that emits
the Planck spectrum. A **band** is a top hat: every wavelength from λ₁ to λ₂
counts fully, and nothing outside counts.

The photon flux at distance d, in photons s⁻¹ m⁻², is

```
F = π (R/d)² ∫[λ₁..λ₂] 2c / λ⁴ / (exp(hc/(λ k T)) − 1) dλ
```

The integral has an exact series. With x = hc/(λ k T), x_hi = x(λ₁), x_lo = x(λ₂):

```
∫ = 2c (kT/(hc))³ [G(x_lo) − G(x_hi)]
G(x) = Σ[n=1..∞] exp(−n x) (x²/n + 2x/n² + 2/n³)
```

Any method is allowed if it is accurate to a relative 10⁻⁶. The oracle uses
the series and checks it against Simpson's rule.

The **aperture** is an unobscured circle of diameter D, with area A = π D²/4.
The **throughput** τ is the fraction of photons entering the aperture that end
up counted. It includes the optics, the coronagraph and the detector. The
counted rate, in photons s⁻¹, is

```
N = F × (π D²/4) × τ
```

A **spectral resolution element** at wavelength λ₀ and resolving power R is the
band from λ₀ − Δλ/2 to λ₀ + Δλ/2, with Δλ = λ₀/R.

### 2.3 Planet contrast in reflected light (`planetContrast`)

**Contrast** is the planet's brightness divided by its star's, at the same
wavelength. For a planet of radius R_p at orbital distance a:

```
C = A_g × Φ(α) × (R_p/a)²
Φ(α) = (sin α + (π − α) cos α) / π
```

A_g is the **geometric albedo**: the planet's brightness at full phase,
relative to a flat, perfectly diffusing disc of the same size. α is the
**phase angle**: the angle star–planet–observer, 0 at full phase and π/2 at
**quadrature** (half lit, widest apart on the sky). Φ is the phase function of
a **Lambert sphere**, a ball that scatters light equally in all directions.
The planet's photon rate is C times the star's rate from §2.2.

### 2.4 Signal-to-noise ratio and integration time (`snr`)

All rates are counted photons per second in one resolution element.

- S: the planet's rate.
- B: the background rate. B = ζ × N★ + Z. ζ is the coronagraph's **raw
  contrast**: the starlight left at the planet's position, as a fraction of
  the star's rate N★ through the same throughput. Z is **zodiacal light**,
  the glow of sunlit dust (below).
- D: the **dark rate**, counts the detector makes with no light.
  D = n_pix × ξ, for n_pix pixels and a dark current ξ per pixel.

After t seconds:

```
SNR(t) = S t / sqrt((S + B + D) t)
t(SNR) = SNR² (S + B + D) / S²
```

**Two thresholds are pinned** (ruling 2, §6). SNR 5 is **a hint**. SNR 10 is
**strong**; it is the LUVOIR study's requirement.

**Zodiacal light.** Dust fills the plane of a planetary system and scatters
its star's light. The telescope looks through two layers: the dust of the
system it sits in (**local zodi**) and the dust around the target star
(**exozodi**). Both are spread over the sky, so their brightness is given per
square arcsecond, in magnitudes. A source 5 magnitudes fainter is 100 times
dimmer; the factor for m magnitudes is 10^(−0.4 m).

```
Z  = N₀ × Ω × (ℓ × 10^(−0.4 z) + n × 10^(−0.4 z₁))
N₀ = N★(10 pc) × 10^(0.4 M_V)
Ω  = π (X × λ₀/D)²           (converted to arcsec²)
```

- N₀ is the counted rate of a star of apparent magnitude 0 with the host
  star's spectrum, through the same instrument and resolution element. M_V is
  the star's **absolute magnitude**: its magnitude as seen from 10 pc.
- Ω is the **photometric aperture**: the patch of sky whose light is added up
  with the planet's. Its radius is X diffraction scales.
- z is the surface brightness of local zodi and ℓ its level. ℓ = 1 is the
  view from 1 AU inside a system like the Sun's.
- z₁ is the surface brightness of one "zodi" of exozodi, and n is how many
  zodis the target system has.

N₀ grows as D² and Ω shrinks as D⁻², so Z does not depend on the aperture. It
does not depend on distance either. A larger telescope collects more planet
light against the same zodiacal rate.
### 2.5 What the coronagraph can reach

Three limits apply before any photon is counted.

- **Diffraction scale:** θ = λ/D radians. Smaller is sharper.
- **Inner working angle (IWA):** the coronagraph cannot see a planet closer to
  its star than θ_IWA = n_IWA × λ/D. A planet at projected separation a and
  distance d sits at angle a/d. It is observable only if a/d ≥ θ_IWA. The
  largest distance is d_max = a / θ_IWA.
- **Noise floor:** a planet whose contrast is below C_floor = 10^(−0.4 Δmag_floor)
  cannot be detected in any integration time.

### 2.6 Radio link budget (`linkSnr`)

A transmitter's **EIRP** (equivalent isotropic radiated power, W) is the power
an all-directions transmitter would need to look as bright as the real,
beamed one does from inside its beam. At distance d the flux is EIRP/(4π d²),
in W m⁻².

A receiver has an **effective area** A_e (m²) and a **system temperature**
T_sys (K), which measures its noise. Its **system equivalent flux density** is

```
SEFD = 2 k T_sys / A_e          (W m⁻² Hz⁻¹; divide by 10⁻²⁶ for Jy)
```

For a signal narrower than one channel of **bandwidth** B (Hz):

```
linkSnr = EIRP / (4π d² × SEFD × B)
SNR(t)  = linkSnr × sqrt(n_pol × B × t)
d(SNR)  = sqrt( EIRP / (4π × SNR × SEFD) × sqrt(n_pol × t / B) )
```

`linkSnr` is the SNR in one channel after one coherence time, t = 1/B. The
second line is the **radiometer equation**: averaging for t seconds gains
sqrt(B t). n_pol is the number of polarisations summed; every row uses
n_pol = 1. The formulas need B t ≥ 1.

### 2.7 Waste heat in the mid-infrared

A civilisation absorbs a fraction γ of its star's luminosity and re-radiates
it as a blackbody at temperature T_w. The star's own light drops by the same
fraction. At wavelength λ, the waste-heat flux divided by the remaining
starlight is

```
E(λ) = γ/(1 − γ) × K(λ)
K(λ) = (T★/T_w)⁴ × (exp(hc/(λ k T★)) − 1) / (exp(hc/(λ k T_w)) − 1)
```

E is the **excess**: E = 0.1 means the star looks 10 % too bright at λ. E
does not depend on distance. Distance matters only through the photon rate
(§2.2) needed to measure it. γ = 1 is a Kardashev type II civilisation, one
that uses its star's whole output.

## 3. Provenance

"Verified" means the cited location was opened for this registry and the
number read there. "Adopted" means a verified number is used in a simplified
way. "Design" means a game choice with no literature claim. "Ruling" means a
choice Mark made (attended 2026-11-12, §6). "unverified" means the source was
not opened or does not state the number.

| Quantity | Adopted value | Evidence and precise location | Status |
|---|---|---|---|
| h, c, k, AU, pc | §2.1 | SI 2019 definitions; IAU 2012 Resolution B2 (AU); IAU 2015 Resolution B2 (pc) | Adopted, exact by definition; the resolutions were not re-opened for this pass |
| R☉, T☉, R⊕, R_J | 6.957 × 10⁸ m, 5772 K, 6.3781 × 10⁶ m, 7.1492 × 10⁷ m | [IAU 2015 Resolution B3](https://arxiv.org/abs/1510.07674), recommendation 3 (the list of nominal values) | Verified |
| Star spectrum | Blackbody at T☉ and R☉ | Game model. Its luminosity 4π R☉² σ T☉⁴ equals the nominal 3.828 × 10²⁶ W of the same resolution | Design; a game approximation (§5) |
| Earth-twin geometric albedo; phase function | A_g = 0.2; Lambert | [Stark et al. 2019](https://arxiv.org/abs/1904.11988), Table 1 (rows A_G and Φ) and the text above it | Verified |
| Raw contrast ζ | 10⁻¹⁰ | [LUVOIR Final Report 2019](https://arxiv.org/abs/1912.06219), Table 1-8 and Table 8-7 (1 × 10⁻¹⁰); Stark et al. 2019, Table 2 (ζ_floor = 10⁻¹⁰); [HabEx Final Report 2019](https://arxiv.org/abs/2001.06683), fact sheet (coronagraph 2.5 × 10⁻¹⁰ at the IWA, starshade 1 × 10⁻¹⁰) | Verified |
| Inner working angle | n_IWA = 3.5 | LUVOIR Final Report, Table 1-8 and Table 8-7: visible channel 3.5 λ/D. HabEx fact sheet: 2.4 λ/D = 62 mas at 0.5 µm for a 4 m. Stark et al. 2019, §4.1: useful throughput exists inside the classical IWA | Verified; adopted as a hard edge, a game approximation |
| Resolving power; O₂ A band | R = 140 at λ₀ = 0.76 µm | LUVOIR Final Report, §1 instrument overview beside Table 1-8: the visible spectrograph has "R=140, chosen for optimal study of the narrow O2 absorption band at 760 nm" | Verified |
| Detection thresholds | SNR 5 per resolution element is "a hint"; SNR 10 is "strong" | LUVOIR Final Report, §3.4.2 step 7, asks SNR ~ 10 at R = 140. Stark et al. 2019, Table 2, uses S/N 5 per spectral bin in the continuum, at R = 70 | Sources verified; both thresholds pinned by Ruling 2 (Mark, attended 2026-11-12) |
| Dark current ξ | 3 × 10⁻⁵ counts pixel⁻¹ s⁻¹ | Stark et al. 2019, Table 2 | Verified |
| Pixels per resolution element n_pix | 192 | Stark et al. 2019, Table 2 and the text after Eq. 14: 192 pixels per spectral bin at R = 70 and 1 µm | Verified there; used here at R = 140 and 0.76 µm, Adopted |
| Throughput τ | 0.04, the same at all wavelengths | Stark et al. 2019, Eq. 16 and Table 2: 0.95 (contamination) × 0.21 (optics, low case at 1 µm) × 0.9 (detector) × 0.75 (read-out) = 0.135. A coronagraph core throughput of 0.30 gives 0.0404, rounded to 0.04 | Components verified; the core throughput 0.30 is **unverified** (Stark gives it only as curves in figures); the product is Design |
| Noise floor | Δmag_floor = 26.5 | Stark et al. 2019, Table 2; HabEx fact sheet (Δmag limit 26.5) | Verified |
| Zodiacal light | z = 23 mag arcsec⁻² (local, V band), z₁ = 22 mag arcsec⁻² (one zodi of exozodi, V band, solar twin), n = 4.5 zodis | Stark et al. 2019, Table 1 (rows z, z′ and n; n is the median of the LBTI HOSTS best-fit distribution) and Eq. 8–9 for the count rates | Verified; included by Ruling 1 (Mark, attended 2026-11-12). Used at 0.76 µm and for every star, Adopted (§5) |
| Local zodi level | ℓ = 1 in every row | Game choice: the view from 1 AU in a Sun-like system, as the studies assume. A ship in interstellar space would have ℓ = 0 | Design |
| Photometric aperture | radius X = 0.7 λ/D | Stark et al. 2019, Table 2 (rows X and Ω). Stark measures it in units of the Lyot-stop diameter; this registry uses the full aperture D | Verified; Adopted |
| Sun's absolute V magnitude | M_V = 4.81 | [Willmer 2018](https://arxiv.org/abs/1804.07788), abstract and Table 3, Johnson V, Vega system | Verified |
| Integration-time formula | t = SNR² (S + B + D)/S² | Stark et al. 2019, Eq. 5, uses (S + 2B')/S², where B' is all background and the 2 pays for background subtraction | Verified; this registry keeps plain Poisson noise and drops the factor 2, a game approximation (confirmed, Mark, attended 2026-11-12) |
| Reference aperture | 10 m; also 4 m and 100 m | Game ruling (sprint R3-REASONS, OQ1). The studies span 4 m (HabEx), 8 m and 15 m (LUVOIR Final Report, fact sheet) | Design |
| V-like band | top hat, centre 0.551 µm, width 0.088 µm | Game band. Willmer 2018, Table 4, gives Johnson V a pivot wavelength of 0.5511 µm and a bandwidth of 0.0871 µm | Design; the comparison values are Verified |
| Jupiter-twin albedo; hot-Jupiter albedo | 0.5; 0.1 | Game values for two comparison rows | Design; **unverified** against measurements |
| Radiometer equation | §2.6 | [Sheikh et al. 2025](https://arxiv.org/abs/2502.02614), Eq. 1–3, which cite Enriquez et al. 2017 | Verified in Sheikh; Enriquez not opened |
| Radar EIRP | 2 × 10¹³ W | Sheikh et al. 2025, §2 case 1: Arecibo's S-band EIRP "is 20 TW (Ekers et al. 2002)" | Verified in the secondary source; Ekers not opened |
| Large-array SEFD | 1.5 Jy | Sheikh et al. 2025, §2: SKA1-Mid with MeerKAT, from Braun et al. 2017 Table 4 | Verified in Sheikh; Braun not opened. Used only in OB-33 |
| Radar reach, published | 12000 ly | Sheikh et al. 2025, §2 result list, case 1: SNR 5, 0.01 Hz, 1 hour | Verified; OB-33 reproduces it (11930 ly). The same formula also reproduces their case 4 (0.97 ly). It gives 83 ly for case 2 (they print 65 ly) and 0.80 ly for case 3 (they print 4.0 ly, in both §2 and Table 2). A second reading of §2 found one SEFD, one SNR and one integration time stated for all four cases, so no stated input explains the two. Case 3's printed value is 5 times the formula's, the size of the SNR factor; that is an observation, not a finding about the paper. No row uses cases 2 or 3 |
| TV station power and carrier | ERP 1000 kW; 0.4 of it in the video carrier; EIRP = 1.64 × ERP; carrier width 0.1 Hz | [Sullivan & Knowles 1985](https://doi.org/10.1017/S0074180900146662), IAU Symposium 112, pp. 327–334, §2: carriers "of width 0.1–1.0 Hz", effective radiated power "typically 100–1000 kw", the factors 1.64 and 0.4 | Verified; the top of the power range and the narrowest width are Adopted |
| Leakage reach, published | about 30 ly for an Arecibo-like antenna, about 500 ly for a Cyclops-like array (radars) | Sullivan & Knowles 1985, §1, summarising [Sullivan, Brown & Wetherill 1978](https://doi.org/10.1126/science.199.4327.377) | Verified in the 1985 paper. The 1978 paper's own tables are **unverified**: only its abstract was opened. Context only; no row uses it |
| Reference dish | 100 m, aperture efficiency 0.70, T_sys 25 K | The ship's starting radio receiver | Ruling 3 (Mark, attended 2026-11-12) |
| Square-kilometre receiver | A_e = 10⁶ m², T_sys 25 K | The later, large radio receiver | Ruling 3 (Mark, attended 2026-11-12) |
| Waste-heat model | §2.7 | [Wright et al. 2014](https://arxiv.org/abs/1408.1134) (the Ĝ search, paper II), §2.2 Eq. 2 and Eq. 5–6 with α = γ and ε = ν = 0; Table 1 defines γ and T_waste | Verified |
| Waste-heat temperature | 300 K | Wright et al. 2014, Table 1, gives about 285 K for humanity and §2.2 gives about 250 K for a classical Dyson sphere | Design, inside the verified range |
| Infrared excess threshold | E = 0.1 | Game threshold for OB-40 | Design |
| NO₂ as a technosignature | no number adopted | [Kopparapu et al. 2021](https://arxiv.org/abs/2102.05027), abstract: present Earth-level NO₂ at 10 pc, SNR ~ 5 in ~ 400 hours with a 15 m telescope, cloud-free | Verified; context for the likelihood work in RT1b |
| CFCs as a technosignature | no number adopted | [Lin, Gonzalez Abad & Loeb 2014](https://arxiv.org/abs/1406.3025), abstract: JWST, a planet transiting a white dwarf, about 1.2 days (CCl₃F) and 1.7 days (CF₄) for 10 times the terrestrial level | Verified; the paper covers white-dwarf hosts only and states no reach in light-years |
| Vegetation red edge | no number adopted | [Kiang et al. 2007](https://arxiv.org/abs/astro-ph/0701391) (paper II), introduction: the edge is a steep rise in reflectance over about 700–850 nm, and may sit in the near-infrared for M stars | Verified; context only |

## 4. OB check-value registry

Each row is one scalar. A row passes when the computed value, rounded to the
row's printed significant figures, equals the printed value. Trailing zeros
count as significant figures. Unless a row says otherwise:

- the star is the Sun of §2.1 as a blackbody;
- the "Earth twin" has R⊕, A_g = 0.2, a = 1 AU, and is at quadrature;
- the "reference instrument" has D = 10 m, τ = 0.04, ζ = 10⁻¹⁰, n_IWA = 3.5,
  n_pix = 192, ξ = 3 × 10⁻⁵ s⁻¹;
- zodiacal light is included: ℓ = 1, z = 23, n = 4.5, z₁ = 22, X = 0.7,
  M_V = 4.81;
- "O₂ A element" is one resolution element at λ₀ = 0.76 µm, R = 140;
- "reference dish" is the ship's starting receiver: 100 m across, aperture
  efficiency 0.70, T_sys = 25 K. "Large array" is A_e = 10⁶ m² at
  T_sys = 25 K. Radio rows use n_pol = 1.

| ID | Quantity | Value | Unit |
|---|---|---|---|
| OB-1 | Lambert phase function at quadrature, Φ(π/2) = 1/π | 0.3183 | — |
| OB-2 | Lambert phase function at phase angle 60° | 0.6090 | — |
| OB-3 | Contrast of the Earth twin | 1.157 × 10⁻¹⁰ | — |
| OB-4 | Contrast of a Jupiter twin: R_J, A_g = 0.5, a = 5.2 AU, quadrature | 1.344 × 10⁻⁹ | — |
| OB-5 | Contrast of a hot Jupiter in reflected light: R_J, A_g = 0.1, a = 0.05 AU, quadrature | 2.908 × 10⁻⁶ | — |
| OB-6 | Noise-floor contrast for Δmag_floor = 26.5 | 2.512 × 10⁻¹¹ | — |
| OB-7 | Photon flux from the Sun at 10 pc in the V-like band | 9.975 × 10⁷ | photons s⁻¹ m⁻² |
| OB-8 | Photon rate from the Sun at 10 pc in the V-like band into a 10 m aperture, τ = 1 | 7.834 × 10⁹ | photons s⁻¹ |
| OB-9 | Counted rate from the Sun at 10 pc, O₂ A element, reference instrument | 1.914 × 10⁷ | photons s⁻¹ |
| OB-10 | Counted rate S from the Earth twin at 10 pc, O₂ A element, reference instrument | 2.215 × 10⁻³ | photons s⁻¹ |
| OB-11 | The same at 10 ly | 2.356 × 10⁻² | photons s⁻¹ |
| OB-12 | Residual starlight ζ × N★ for OB-10 (ζ × OB-9) | 1.914 × 10⁻³ | photons s⁻¹ |
| OB-13 | Dark rate D of the reference instrument (192 × 3 × 10⁻⁵) | 5.760 × 10⁻³ | counts s⁻¹ |
| OB-14 | SNR on the Earth twin at 10 pc after 10 hours (36000 s), O₂ A element | 3.477 | — |
| OB-15 | Time to a hint (SNR 5) on the Earth twin at 10 pc, O₂ A element, reference instrument | 20.68 | hours |
| OB-16 | The same to strong (SNR 10) | 82.70 | hours |
| OB-17 | Time to a hint (SNR 5) at 10 ly, reference instrument (strong: OB-49) | 0.6805 | hours |
| OB-18 | Time to SNR 5 at 10 ly with D = 4 m | 8.554 | hours |
| OB-19 | Time to SNR 5 at 10 pc with D = 4 m. Photon budget only: OB-25 puts this planet inside the inner working angle, so it is not observable | 615.9 | hours |
| OB-20 | Time to SNR 5 at 10 pc with D = 100 m | 0.05993 | hours |
| OB-21 | Diffraction scale λ/D at 0.76 µm for D = 10 m | 15.68 | mas |
| OB-22 | Inner working angle 3.5 λ/D at 0.76 µm for D = 10 m | 54.87 | mas |
| OB-23 | Angular separation of 1 AU at 10 pc | 100.0 | mas |
| OB-24 | Largest distance at which 1 AU clears the inner working angle at 0.76 µm, D = 10 m | 59.45 | ly |
| OB-25 | The same for D = 4 m | 23.78 | ly |
| OB-26 | The same for D = 100 m | 594.5 | ly |
| OB-27 | Time to a hint (SNR 5) on the Earth twin at the distance of OB-24, reference instrument (strong: OB-50) | 183.1 | hours |
| OB-28 | Effective area of the reference dish, 0.70 × π × 100²/4 | 5498 | m² |
| OB-29 | SEFD of the reference dish | 12.56 | Jy |
| OB-30 | `linkSnr` for EIRP 2 × 10¹³ W at 100 ly, reference dish, B = 1 Hz | 14.16 | — |
| OB-31 | Distance at which EIRP 2 × 10¹³ W gives SNR 1: reference dish, B = 1 Hz, t = 1 s | 376.3 | ly |
| OB-32 | The same at SNR 10 | 119.0 | ly |
| OB-33 | Distance at which EIRP 2 × 10¹³ W gives SNR 5: SEFD 1.5 Jy, B = 0.01 Hz, t = 3600 s (Sheikh et al. 2025 print 12000 ly) | 1.193 × 10⁴ | ly |
| OB-34 | EIRP of a TV video carrier: 1.64 × 0.4 × 1000 kW | 6.560 × 10⁵ | W |
| OB-35 | Distance at which OB-34 gives SNR 1: reference dish, B = 0.1 Hz, t = 3600 s | 0.9388 | ly |
| OB-36 | The same with the large array | 12.66 | ly |
| OB-37 | The same as OB-36 at SNR 10 | 4.004 | ly |
| OB-38 | Waste-heat spectral factor K at 10 µm, T_w = 300 K, Sun-like star | 323.2 | — |
| OB-39 | Excess E at 10 µm for γ = 0.01 (1 % of a Kardashev type II), T_w = 300 K | 3.265 | — |
| OB-40 | Smallest γ whose excess at 10 µm reaches E = 0.1, T_w = 300 K | 3.093 × 10⁻⁴ | — |
| OB-41 | Threshold SNR for "a hint" | 5 | — |
| OB-42 | Threshold SNR for "strong" | 10 | — |
| OB-43 | Photometric aperture Ω at 0.76 µm for D = 10 m, X = 0.7 | 3.783 × 10⁻⁴ | arcsec² |
| OB-44 | Zero-magnitude rate N₀: Sun's spectrum, O₂ A element, reference instrument | 1.607 × 10⁹ | photons s⁻¹ |
| OB-45 | Local zodi rate (ℓ = 1, z = 23) for OB-10; the same for any aperture and distance | 3.835 × 10⁻⁴ | photons s⁻¹ |
| OB-46 | Exozodi rate (n = 4.5, z₁ = 22) for OB-10; the same for any aperture and distance | 4.335 × 10⁻³ | photons s⁻¹ |
| OB-47 | Total background B for OB-10 (OB-12 + OB-45 + OB-46) | 6.633 × 10⁻³ | photons s⁻¹ |
| OB-48 | OB-15 with no zodiacal light (Z = 0), for comparison | 14.00 | hours |
| OB-49 | Time to strong (SNR 10) at 10 ly, reference instrument | 2.722 | hours |
| OB-50 | Time to strong (SNR 10) at the distance of OB-24, reference instrument | 732.3 | hours |
| OB-51 | Distance at which EIRP 2 × 10¹³ W gives a hint (SNR 5): reference dish, B = 1 Hz, t = 1 s | 168.3 | ly |
| OB-52 | Distance at which OB-34 gives a hint (SNR 5): large array, B = 0.1 Hz, t = 3600 s | 5.662 | ly |

### What the rows say about reach

These are outputs, not rules. They are stated so a reviewer can compare them
with the feature document.

- **Life is a tens-of-light-years question at 10 m, and the angle sets it.**
  The reference instrument takes 21 hours for a hint and 83 hours for a
  strong reading of an Earth twin at 10 pc (OB-15, OB-16). Beyond 59 ly
  (OB-24) the planet is too close to its star to separate at 0.76 µm, however
  long the exposure. At that edge a hint takes 183 hours and a strong reading
  732 hours, a month (OB-27, OB-50). A 4 m aperture stops at 24 ly (OB-25); a
  100 m aperture reaches 594 ly (OB-26). This agrees with
  signals-and-instruments §4.2.
- **Zodiacal light costs about half again at 10 pc.** Without it OB-15 would
  be 14 hours (OB-48), not 21. Most of it is the target system's own dust
  (OB-46 against OB-45). It matters most where the planet is faint: at 10 ly
  the cost is a tenth (OB-17), at the 59 ly edge it is two thirds.
- **Radar-like leakage reaches further than the feature document says.**
  §4.3 there says "up to hundreds of light-years ... with a large receiver".
  The ship's 100 m dish hears a 2 × 10¹³ W radar at 376 ly in one second at
  1 Hz (OB-31; 168 ly for a hint, OB-51), and a large array hears it at about
  12000 ly in an hour at 0.01 Hz (OB-33). This PR corrects that cell. The budget is not what hides a radar. Its beam covers a tiny part
  of the sky for a short time. That chance belongs to the likelihood model
  (RT1b), not to this file.
- **TV-like leakage is a light-years signal** (OB-35 to OB-37), as §4.3 says.
- **Waste heat is a question of fraction, not distance.** One percent of a
  star's output at 300 K makes the star more than four times brighter at 10 µm
  (OB-39: the excess alone is 3.3 times the starlight). A fraction below
  3 × 10⁻⁴ hides under a 10 % threshold (OB-40). Humanity's fraction of the
  Sun's output is far below that.

## 5. Scope: what is simplified on purpose

Each item is a **game approximation**. None is a claim about a real mission.

1. **The star is a blackbody.** Real stars have absorption lines and are not
   Planck curves. For the Sun in V the blackbody gives 0.955 of the photon
   flux that Willmer 2018's magnitude and zero point give (4.81; Table 4:
   3.62701 × 10⁻⁹ erg s⁻¹ cm⁻² Å⁻¹, bandwidth 0.0871 µm). Other bands are not
   checked.
2. **Bands are top hats, and throughput is grey.** One τ applies at every
   wavelength. Real optics and detectors vary with wavelength.
3. **Zodiacal light is smooth and has the star's colour.** The V-band
   surface brightnesses are used at 0.76 µm. Every target system has the
   median 4.5 zodis at 22 mag arcsec⁻², whatever its star and wherever the
   planet sits. Real systems differ by orders of magnitude. The local level
   is fixed at ℓ = 1, as if the ship observed from 1 AU in a system like the
   Sun's. The photometric aperture uses the full aperture D.
4. **No factor 2 for background subtraction**, no read noise, and no
   clock-induced charge. The dark rate uses a pixel count taken from a
   different resolving power and wavelength.
5. **SNR is on the continuum in one resolution element.** It is the SNR of the
   planet's light at 0.76 µm, not of the O₂ absorption itself. Detecting the
   band needs the neighbouring elements too. The chance that a given spectrum
   means oxygen, and that oxygen means life, belongs to RT1b's likelihoods.
6. **The inner working angle is a hard edge and one number.** Real coronagraphs
   lose throughput gradually, and the angle depends on the design.
7. **The albedo is the same at all wavelengths, and the planet is a Lambert
   sphere.** No clouds, glint, rings or thermal emission. A real hot Jupiter
   glows in the infrared far more brightly than OB-5's reflected light.
8. **Circular orbit seen at quadrature**, so the projected separation equals
   the orbital distance.
9. **Radio:** one polarisation, a signal narrower than one channel, no Doppler
   drift, no interstellar scattering, and a transmitter that points at the
   receiver for the whole integration.
10. **Waste heat is one blackbody at one temperature**, and the star keeps its
    spectrum's shape while it dims. OB-40's threshold is a game number, not a
    survey's calibration limit.

## 6. Rulings and remaining evidence

**Unverified:** the coronagraph core throughput of 0.30 inside τ; the two
giant-planet albedos; the
tables of Sullivan, Brown & Wetherill 1978 (abstract only); Sheikh et al.
2025's cases 2 and 3, which the formula does not reproduce (§3). The primary
sources behind three secondary citations were not opened: Ekers et al. 2002
(radar EIRP), Enriquez et al. 2017 (radiometer equation) and Braun et al.
2017 (array SEFD). No Habitable Worlds Observatory document was opened; the
6 m class figure in signals-and-instruments §4.2 is not checked here.

**Rulings (Mark, attended 2026-11-12).**

1. Zodiacal light is included: local zodi and exozodi enter the background
   (§2.4). OB-48 keeps the Z = 0 value of OB-15 for comparison.
2. Two detection thresholds are pinned: SNR 5 is "a hint" and SNR 10 is
   "strong" (OB-41, OB-42).
3. The 100 m dish (efficiency 0.70, 25 K) is the ship's starting radio
   receiver. The 10⁶ m² array is the later large case.
4. The registry stays in this file. `sim/tools/lore_values.ail` must be
   taught to read it in RT1.

The same session confirmed the plain Poisson SNR formula, without the factor
2 for background subtraction, as a game approximation.

**Open for review:** the local zodi level ℓ for a ship that is not inside a
planetary system; the core throughput inside τ.

**Oracle.** An independent Python script (standard library only) recomputes
every row from §2 and compares it with the table above at the printed
significant figures. The design repo has no tools directory, so the script
and its output are in the draft PR's description.
