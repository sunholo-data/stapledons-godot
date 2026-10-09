# The local interstellar medium: structure, model `lism-1`, and check values

**Status:** Normative for `ism_model = lism-1` (ledger D-60, D-61). Companion to
[higgs-bubble.md](higgs-bubble.md), whose §5 (drag, the drive-hold limit) and
§6b (dust-grain impacts, the wall afterglow) consume the densities defined here.
**Package-first:** the geometry and astrophysics below are `sunholo/celestial`
module `ism` (§7); the bubble physics that uses them is `sunholo/relativity`
(`medium` additions, `dust`). The game's oracle is `tools/ism_dust_ref.py`
(stapledons-godot, role oracle); its source tables are
`data/ism/sources/*.tsv` there, transcribed from the papers' arXiv LaTeX
sources.

**Check values.** As in higgs-bubble.md: every check value has an ID (IS-n),
one number per row, in tables with the columns `ID | Quantity | Value | Unit`.
A unit of `—` means dimensionless. Lengths are parsecs unless stated (the sim
works in light years; 1 pc = 3.26156 ly).

## 1. Why a structured medium

Until R1 the medium was one number, HB-3 = 0.1 cm⁻³ "everywhere". The Sun is
not in the Local Bubble's hot gas but at the edge of the Local Interstellar
Cloud (LIC), whose gas is 2.5× HB-3, and the bubble's hot interior is 25×
thinner than HB-3. Routes to α Cen, TRAPPIST-1 and Aldebaran cross different
clouds. `lism-1` is the cited, deterministic density field; HB-3 survives as
the value of the scenario model `uniform`, which reproduces every R1 number and
recorded stream.

## 2. The model `lism-1`

Frame: heliocentric galactic Cartesian (x toward the Galactic centre, y toward
rotation, z to the north pole), epoch J2000; the clouds do not move (they drift
about 0.03 pc per thousand years, below the model's resolution). Each point
belongs to exactly one medium, first match wins:

1. **Dense clouds (PR B):** the Local Leo Cold Cloud sheets and the
   Edenhofer et al. 2024 clumps beyond 69 pc, δ = IS-23.
2. **The 14 Redfield & Linsky 2008 clouds** (G, Blue, Aql, Eri, Aur, Hyades,
   Mic, Oph, Gem, NGP, Leo, Dor, Vel, Cet), each a **cone shell** (game
   approximation, labelled): apex at the Sun, axis the cloud's centre (l, b)
   from RL08 Table 18, half-angle θ with cos θ = 1 − Ω/2π for the cloud's
   projected area Ω (Table 18). The shell runs from r_in to
   r_out = min(r_in + L, d_near): L = N_med / n_HI,edge is the neutral path of
   the cloud's median sight-line column (RL08 Tables 2–15, members within
   15 pc, n_HI,edge = IS-15), d_near the cloud's nearest member star (Table 18,
   an upper limit on its near side). r_in is the LIC's edge along the cloud's
   axis, except for **G, which starts at the Sun**: the Sun sits at the LIC
   edge facing G, and α Cen's sight line holds G gas and no LIC gas (Linsky
   et al. 2019 §5 and Table 4; RL08 Table 2). n_H = IS-18, δ = IS-22.
3. **The LIC**: the star-shaped surface r(Ω̂) = Σ a_lm Y_lm(Ω̂) about the
   centre (IS-1…IS-3), coefficients IS-4…IS-12. Y_lm are the orthonormal real
   spherical harmonics, l ≤ 2, without the Condon–Shortley phase, m > 0 with
   cos mφ and m < 0 with sin |m|φ, θ the colatitude from the north galactic
   pole and φ the galactic longitude. n_H = IS-18, δ = IS-22.
4. **The Local Bubble's hot gas** everywhere else: n_H = IS-20, δ = IS-22
   (labelled assumption: dust survives in the hot gas, Draine & Salpeter 1979
   sputtering time about 10⁸ yr; the I8 sheet also shows δ = 0.002).

Into the bubble physics goes the **mass-equivalent density**
n = n_H (μ_H + δ) (IS-24, δ in hydrogen masses per H nucleon). The wall
reflects every massive particle (D-11), so drag and the mean glow follow the
whole mass flux, dust included.

**Resolution along a route** is exact, never sampled: cone shells and spheres
have closed-form chords; the LIC's crossings are bracketed on 64 steps along
the segment and refined by 60 bisections. `profile(a, b)` returns the ordered,
gap-free segments [(s₀, s₁, medium)]; the column is Σ n_H Δs.

### Labelled approximations
- The cone shells (Redfield & Linsky give each cloud's outline on the sky and
  an upper limit on its distance, not a 3D shape).
- The LIC coefficients are a refit (§3).
- One dust calibration δ per medium; the same grain-size shape everywhere
  (only the LIC is measured in situ).

## 3. The LIC surface: a refit, and why

Linsky, Redfield & Tilipman 2019 (ApJ 886, 41) Table 3 prints the centre and
nine coefficients of a spherical-harmonic fit to the 62 edge distances of
their Table 2, with a median |d_obs − d_model| of 0.40 pc. **No standard
real-harmonic convention reproduces Table 2 from the printed coefficients**:
orthonormal with or without the √2 on m ≠ 0, with or without the
Condon–Shortley phase, either sin/cos assignment, every sign of every
order, about the printed centre: the best median against the observed edge
distances is 0.648 pc (IS-14) and against the paper's own model column 0.27 pc
(the paper's own model column does reproduce its 0.40 pc, so Table 2 is
self-consistent; the coefficients or their convention are what cannot be
recovered). `lism-1` therefore **refits** the nine coefficients by the
paper's method: σ-weighted linear least squares of |p − c| = Σ a_lm Y_lm
over the edge points p = d_obs Ω̂ of the 63 Table 2 rows that list a σ (the
paper says 62; one row with a σ is presumably excluded in their count), about
the printed centre. The refit reproduces the observed edge distances with a
median |Δ| of 0.378 pc (IS-13), inside the paper's 0.40 pc.

| ID | Quantity | Value | Unit |
|---|---|---|---|
| IS-1 | LIC centre x [cite: Linsky et al. 2019, Table 3] | −0.8 | pc |
| IS-2 | LIC centre y [cite: Linsky et al. 2019, Table 3] | 0.7 | pc |
| IS-3 | LIC centre z [cite: Linsky et al. 2019, Table 3] | −0.4 | pc |
| IS-4 | Refit a₀,₀ | 5.1060 | pc |
| IS-5 | Refit a₁,₋₁ | 0.4380 | pc |
| IS-6 | Refit a₁,₀ | −0.1551 | pc |
| IS-7 | Refit a₁,₁ | 0.2163 | pc |
| IS-8 | Refit a₂,₋₂ | −0.1802 | pc |
| IS-9 | Refit a₂,₋₁ | −0.1596 | pc |
| IS-10 | Refit a₂,₀ | −0.0621 | pc |
| IS-11 | Refit a₂,₁ | −0.5809 | pc |
| IS-12 | Refit a₂,₂ | 0.6815 | pc |
| IS-13 | Median \|d_obs − d_model\| of the refit over the 63 rows (in-sample: the refit is made on these rows) | 0.378 | pc |
| IS-14 | The same for the printed Table 3 coefficients, best standard convention | 0.648 | pc |

The full-precision coefficients are generated by `sim/tools/ism_build.ail`
(stapledons-godot) and pinned in `sim/data/ism.ail`; IS-4…IS-12 are their
printed values.

## 4. Densities, dust and the mass-equivalent density

| ID | Quantity | Value | Unit |
|---|---|---|---|
| IS-15 | n_HI used to turn H I columns into path lengths [cite: Linsky et al. 2019 §4; Redfield & Linsky 2008] | 0.2 | cm⁻³ |
| IS-16 | Warm-cloud n_HI [cite: Slavin & Frisch 2008, model 26, solar location] | 0.192 | cm⁻³ |
| IS-17 | Warm-cloud n_p [cite: Slavin & Frisch 2008, model 26] | 0.0554 | cm⁻³ |
| IS-18 | Warm-cloud n_H = n_HI + n_p | 0.2474 | cm⁻³ |
| IS-19 | Hot-gas n_e [cite: Snowden et al. 2014, ApJ 791, L14] | 4.68 × 10⁻³ | cm⁻³ |
| IS-20 | Hot-gas n_H = n_e / 1.2 (fully ionised H and He) | 3.9 × 10⁻³ | cm⁻³ |
| IS-21 | Local dust mass density ρ_d [cite: Krüger et al. 2015, ApJ 812, 139, §5.3] | 2.1 × 10⁻²⁴ | kg m⁻³ |
| IS-22 | Local dust mass per H nucleon δ = ρ_d / (n_H m_H) (warm clouds and hot gas) | 0.00507 | — |
| IS-23 | Dense-cloud δ [cite: Draine 2011, M_dust/M_H] | 0.010 | — |
| IS-24 | Gas mass per H nucleon μ_H [cite: Draine 2011, Table 1.4] | 1.4 | — |
| IS-25 | Mass-equivalent density n_H(μ_H + δ), warm clouds | 3.476 × 10⁵ | m⁻³ |
| IS-26 | Mass-equivalent density, hot gas | 5.480 × 10³ | m⁻³ |
| IS-27 | N_H / E(B−V) [cite: Bohlin, Savage & Drake 1978] | 5.8 × 10²¹ | cm⁻² mag⁻¹ |
| IS-28 | R_V | 3.1 | — |
| IS-29 | n_H per unit A_V gradient, IS-27 / (IS-28 pc) | 606.3 | cm⁻³ per mag pc⁻¹ |

## 5. What the routes cross

| ID | Quantity | Value | Unit |
|---|---|---|---|
| IS-30 | Model H I column toward α Cen (the G shell, IS-15 density) | 17.70 | log cm⁻² |
| IS-31 | Measured, for comparison [cite: Linsky et al. 2019, Table 4] | 17.6 | log cm⁻² |
| IS-32 | Distance from the Sun to the nearest point of the LIC surface (HEALPix Nside 8 directions) | 0.20 | pc |
| IS-33 | Sol → Aldebaran: start of the Hyades shell along the leg | 1.77 | pc |
| IS-34 | Sol → Aldebaran: end of the Hyades shell along the leg | 2.69 | pc |
| IS-35 | RL08 members within 15 pc whose model sight line crosses their assigned cloud | 42 | of 59 |
| IS-36 | The same, as a fraction (the design's target is 0.80; see §6) | 0.712 | — |

Sol → TRAPPIST-1 leaves the LIC into the hot gas and meets no named cloud
(the Eri cap ends about 12° away). Sol → α Cen is G for its first 0.81 pc,
then hot gas.

## 6. Source verification (milestone I0, plan review F7)

Each quoted number was checked against the paper. The arXiv LaTeX sources were
used (they carry the tables verbatim); journal page numbers were not checked,
so the table or section is given instead.

| Number | Source | Where | Verified | Note |
|---|---|---|---|---|
| LIC centre (−0.8, +0.7, −0.4) pc, 9 coefficients, 62 lines, median 0.40 pc, χ²_ν 8.3 | Linsky, Redfield & Tilipman 2019, ApJ 886, 41 | Table 3 (arXiv:1910.01243v1) | yes | **Coefficients do not reproduce Table 2 (§3); refit used** |
| 74 LIC sight lines with d_obs, σ and d_model | same | Table 2 | yes, every row transcribed | 63 rows list σ (Table 3 says 62) |
| α Cen: G cloud, log N(H I) 17.6, neutral path 0.70 pc | same | Table 4 | yes | |
| "Outside the hydrogen hole ... lines of sight pass through the G or other clouds rather than the LIC" | same | §5 (hydrogen hole) | yes | The basis of the G start rule |
| 15 clouds: centre (l, b), closest star, area, ⟨T⟩ | Redfield & Linsky 2008, ApJ 673, 283 | Table 18 (arXiv:0709.4480v1) | yes | Centres are rounded to 5–10° |
| Cloud velocity vectors V₀, l₀, b₀ | same | Table 16 | yes | Archive and legend only (no moving clouds) |
| Member sight lines (star, HD, d, log N(H I)) | same | Tables 1–15 | yes, every row | log N(H I) is the sight-line total |
| Member positions | SIMBAD (sim-tap, 2026-10-09) | ICRS ra, dec by HD | yes | 38 stars within 15 pc |
| n_HI 0.192, n_p 0.0554, T 6320 K (model 26) | Slavin & Frisch 2008, A&A 491, 53 | "Model Results for Solar Location" table (arXiv:0704.0657) | yes | The design's n_p 0.055 is 0.0554 |
| ρ_d (2.1 ± 0.6) × 10⁻²⁴ kg m⁻³; gas-to-dust 193 (+85/−57) with model 26 | Krüger et al. 2015, ApJ 812, 139 | §5.2–5.3 (arXiv:1510.06180v1) | yes | |
| Grain bulk density | same | §6 | **3,300 kg m⁻³** (astronomical silicates) | **The design said 2,500; 3,300 used** (a_max 8.98 µm, not 9.85) |
| Upper mass about 10⁻¹¹ kg, set by the detector size | same | §5.1 | yes | |
| Flux of 10⁻¹³ kg grains "on the order of 10⁻⁷ m⁻² s⁻¹"; the cumulative flux table | same | §5.4, Table 6 | yes | Table 6 transcribed in the oracle's notes |
| 987 interstellar grains, 1992–2007 | same | §4, abstract | yes | |
| Inflow speed 26 km/s (earlier analyses), 23.2 km/s (IBEX) | same | §2 | yes | The flux check uses 26 km/s as the design says |
| n_e 4.68 × 10⁻³ cm⁻³ | Snowden et al. 2014, ApJ 791, L14 | — | **secondary only**: quoted by Liu et al. 2017, ApJ 834, 33 (arXiv:1611.05133) §4 | Primary not on arXiv; not opened |
| LLCC 11.3–24.3 pc; 15–30 K | Peek et al. 2011, ApJ 735, 129 | abstract, §3 (arXiv:1104.5232) | yes | PR B |
| LLCC P/k 60,000 cm⁻³ K, n_HI ≈ 3,000 cm⁻³, thickness ≈ 200 AU | Meyer et al. 2012, ApJ 752, 119 | abstract, §5 (arXiv:1204.5980) | yes | PR B |
| Edenhofer `mean_and_std_healpix.fits`, 3,252,715,200 bytes, CC BY 4.0 | Zenodo 10.5281/zenodo.8187943 | file list (API, 2026-10-09) | yes | md5 10c823a5fcf81b47b6e15530bcdf54dc; PR B |
| N_H/E(B−V) 5.8 × 10²¹ | Bohlin, Savage & Drake 1978 | — | not reopened (standard value) | 606.3, not the design's 606.1 |
| μ_H 1.4; M_dust/M_H 0.010 | Draine 2011 | Table 1.4 | not reopened (textbook) | |

**Not reproduced, and what was done:** the LIC coefficients (refit, §3); the
grain density (3,300 used); AC6(a) membership is 0.712, below the design's
0.80: no start rule for the cone shells reaches 0.80 with Table 18's centres
and areas (the best, every cloud starting at the LIC edge, is 0.746 but puts
0.28 pc of LIC gas on α Cen's line, giving 17.83 against the measured
17.6 ± 0.15). The G start rule keeps the α Cen column right and the route
media the papers describe; the membership shortfall is a property of the cone
approximation and is listed for Mark.

## 7. `sunholo/celestial` module `ism` (0.4.0)

| Function | What | Check |
|---|---|---|
| `realSphericalHarmonic(l, m, theta, phi)` | Y_lm as in §2 | Orthonormal by quadrature |
| `starSurfaceRadius(coeffs, dir)` | Σ a_lm Y_lm(dir) | IS-13 against Table 2 |
| `starSurfaceChords(centre, coeffs, a, b)` | Crossings of a segment, 64-step bracket, 60 bisections | Sun inside; α Cen leg |
| `ellipsoidChord`, `coneShellChord`, `slabChord` | Closed-form parameter intervals of a segment inside each shape | Oracle to 1e-12 |
| `nHFromExtinction(avPerPc, nhPerEbv, rV)` | (N_H/E(B−V)) A_V′ / (R_V pc) | IS-29 |
| `healpixRingVec(nside, pix)` | HEALPix RING pixel centre | healpy 1.20.1 to 1e-14 on 11,433 pixels |
| `grainDist`, `grainsAbove`, `grainRadiusAt`, `grainMass` | Broken power law (higgs-bubble §6b) | HB-113…HB-123 |
| `poissonDraw(mean, u, v)` | Inversion below 30, rounded normal above | Mean over a fixed grid |
