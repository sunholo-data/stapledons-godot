# The Higgs bubble: the one admitted hand-wave, and its exact consequences

**Status:** Normative. Canon from Mark's attended ruling of 2026-10-01 (ledger
D-11; D-13 and D-14 build on it).
**Companion:** [relativity-spec.md](relativity-spec.md) (SR/GR visuals, with
check values RS-n in its §7).
**Package-first:** this document is the source for the bubble functions in
`sunholo/relativity` (§12). New formulas go into the package first, and
GDScript and shaders mirror it.

> "The Higgs bubble is the one hand-wavy non-physics bit which we admit, but
> then be as hard-core physics for the rest as possible." (Mark, 2026-10-01)

**Check values.** Every check value has an ID (HB-n) and appears as one row of
a table with the columns `ID | Quantity | Value | Unit`. Each row holds one
number, so a parser can build a registry from these tables. Tests, the
simulation and the in-game Archive (`lore/archive/`) cite the IDs. The game
repo checks lore numbers against this registry (`make lore-check`). A unit of
`—` means the value is dimensionless.

## 1. Constants and inputs

Physical constants (not check values):

| Symbol | Value |
|---|---|
| c | 299,792,458 m/s |
| G | 6.67430 × 10⁻¹¹ m³ kg⁻¹ s⁻² |
| M☉ | 1.98847 × 10³⁰ kg |
| m_p | 1.67262192 × 10⁻²⁷ kg (m_p c² = 938.272 MeV = 1.50328 × 10⁻¹⁰ J) |
| g | 9.80665 m/s² (standard gravity) |
| ly | 9.4607 × 10¹⁵ m; yr = 365.25 days |
| sun | 1,361 W/m² (the solar constant at 1 AU) |

Inputs (scenario and canon values that the numbers below are computed from):

| ID | Quantity | Value | Unit |
|---|---|---|---|
| HB-1 | Bubble radius R; also the tidal lever arm L (centre to wall) | 100 | m |
| HB-2 | Projected area A = πR² | 31,416 | m² |
| HB-3 | ISM proton density n (Local Bubble; constant in R1) | 0.1 | cm⁻³ |
| HB-4 | Distance Sol → α Centauri, d | 4.37 | ly |
| HB-5 | CMB temperature T_CMB (2.7255 K would raise every CMB temperature by 0.02%) | 2.725 | K |
| HB-6 | Interior gravity held by the generator | 1 | g |
| HB-7 | Slice default cruise speed (D-14) | 0.99 | c |
| HB-8 | Top of the cruise range | 0.999999 | c |
| HB-9 | Share of the proton's mass that comes from the Higgs (its quarks' current masses, about 9 MeV of 938 MeV) | 1 | % |
| HB-10 | Sgr A* mass [cite: GRAVITY Collaboration 2022, A&A 657, L12] | 4.297 × 10⁶ | M☉ |
| HB-11 | Sgr A* distance, R₀ = 8.277 kpc [cite: GRAVITY Collaboration 2022, A&A 657, L12] | 27,000 | ly |
| HB-12 | Gaia BH1 mass | 9.62 | M☉ |
| HB-13 | Example intermediate-mass hole | 1,000 | M☉ |
| HB-14 | Tidal comfort threshold | 0.1 | g |
| HB-15 | Arrival stand-off from the target star (D-14) | 1,000 | AU |
| HB-111 | Wall conversion efficiency ε, the inelastic fraction that becomes glow (D-29 and its follow-up, 2026-10-03; 10⁻⁹ under D-15) | 1 × 10⁻¹⁰ | — |

Speeds use β, γ = 1/√(1−β²) and rapidity φ = atanh β, as in the relativity
spec. Near c, never form 1−β by subtraction. Use the rapidity forms
γ = cosh φ, γβ = sinh φ, γ−1 = 2 sinh²(φ/2) and γ(1+β) = e^φ.

## 2. The hand-wave: three properties

The bubble is a spherical pocket of radius R produced by the spire's generator.
It is defined by exactly three properties. Everything else in this document is
derived from them with ordinary physics.

1. **Wall.** The wall blocks every massive particle, in both directions. It is
   transparent, both ways, to light (photons of every energy) and to
   neutrinos. No massive particle crosses at all. The mass budget is closed.
2. **Tunable inertia.** Seen from outside, the whole pocket (wall plus
   contents) has a tunable effective inertial mass m_eff. It can be made tiny
   but **never zero**: a zero-mass pocket would have to move at exactly c, and
   the crew's proper time would stop.
3. **The interior is its own frame.** The pocket's acceleration is not felt
   inside. The generator holds a steady 1 g "down", toward aft. 1 g is a
   comfort setting, not a consequence of thrust.

**What is physical and what is invented.**
- Light crossing is the physical part: photons do not couple directly to the
  Higgs field.
- Neutrinos crossing is part of the rule, not a consequence. Neutrinos have
  small non-zero masses (oscillation experiments), so a strict "blocks
  everything massive" wall would stop them. They pass because they barely
  interact with anything. Physically this changes nothing, since they pass
  through the ship and the crew anyway.
- **The name is a label for the hand-wave.** The Higgs field gives a proton
  only about 1% of its mass (HB-9). The rest is QCD binding energy. Zeroing the
  Higgs field inside the pocket would also dissolve atoms: the electron's mass
  comes from the Higgs, and the Bohr radius a₀ = ħ/(m_e c α) grows without
  limit as m_e → 0. So inside the bubble physics is normal, and "Higgs" names
  the one thing we invented.
- **Low m_eff alone would not hide acceleration.** Felt (proper) acceleration
  does not depend on mass. Reaching 0.999999c at a felt 1 g would take 7.03
  ship-years (HB-24). Property 3 is what makes minutes-long boosts survivable.

## 3. The journey profile

**Boost → cruise → brake.**
- **Boost:** minutes of ship time up to the cruise speed the player chose.
- **Cruise:** coast at that speed, anywhere from 0.9c to 0.999999c, bounded by
  an optional scenario γ cap (no default since D-15; the ISM cost is the brake).
- **Brake:** minutes of ship time down to rest at the target.

There is no midpoint flip, and coasting is not weightless (property 3). This is
consistent with design-decisions 2025-12-02 ("arbitrary γ instantly"; "launch
order = arrival order"). It supersedes the 1 g flip-and-burn as the gameplay
profile, and "1 g from constant thrust" as the source of gravity.

Cruise times for distance d at speed β (the boosts add minutes and are
ignored): Earth time t = d/(βc), ship time τ = t/γ. Felt-1 g comparison:
τ = cφ/g to reach speed φ. Constant proper acceleration a over ship time τ
reaches φ = aτ/c, taking galaxy time (c/a) sinh φ and galaxy distance
(c²/a)(cosh φ − 1).

| ID | Quantity | Value | Unit |
|---|---|---|---|
| HB-16 | γ at 0.99c | 7.0888 | — |
| HB-17 | φ at 0.99c | 2.6467 | — |
| HB-18 | γ at 0.999999c | 707.107 | — |
| HB-19 | φ at 0.999999c | 7.2543 | — |
| HB-20 | Sol → α Cen at 0.99c, Earth time, each way | 4.414 | yr |
| HB-21 | Sol → α Cen at 0.99c, ship time, each way | 0.6227 | yr |
| HB-22 | Sol → α Cen at 0.99c, ship time, each way | 227.4 | days |
| HB-23 | Felt 1 g: ship time to reach 0.99c | 2.56 | yr |
| HB-24 | Felt 1 g: ship time to reach 0.999999c | 7.03 | yr |
| HB-25 | Sol → α Cen at 0.999999c, Earth time | 4.370 | yr |
| HB-26 | Sol → α Cen at 0.999999c, ship time | 2.26 | days |
| HB-27 | Package check value, not the gameplay profile: Sol → α Cen at 1 g to the midpoint, then 1 g braking, ship time | 3.582 | yr |
| HB-28 | Same, Earth time | 6.003 | yr |
| HB-29 | Same, peak speed | 0.9517 | c |
| HB-30 | Example boost: ship time to 0.99c (a design parameter, not fixed) | 10 | min |
| HB-31 | Example boost: proper acceleration a = cφ/τ (unfelt) | 1.32 × 10⁶ | m/s² |
| HB-32 | Example boost: the same acceleration | 1.35 × 10⁵ | g |
| HB-33 | Example boost: galaxy-frame duration | 26.5 | min |
| HB-34 | Example boost: galaxy-frame distance | 2.77 | AU |

## 4. Propulsion: a photon drive

Only light leaves the bubble (property 1), so the drive must be a photon drive,
and momentum is conserved. In the instantaneous rest frame, changing rapidity
by dφ needs photon momentum m_eff c dφ, which carries energy m_eff c² dφ. Summed
over the instantaneous rest frames, one boost (or one brake) from rest to
rapidity φ radiates

  **E_boost = m_eff c² φ** (J; m_eff in kg)

The cost grows only with ln γ (φ ≈ ln 2γ at high speed). The energy source is
inside the closed bubble, and it is the subject of the later energy budget
(§8).

| ID | Quantity | Value | Unit |
|---|---|---|---|
| HB-35 | Boost energy per kg of m_eff, rest → 0.99c | 2.379 × 10¹⁷ | J/kg |
| HB-36 | Boost energy per kg of m_eff, rest → 0.999999c | 6.520 × 10¹⁷ | J/kg |
| HB-37 | Ratio of the two boost energies | 2.741 | — |

## 5. The interstellar medium: an elastic mirror

The ISM, not the stars, is the real enemy of a fast ship (compare Poul
Anderson's *Tau Zero*). In the ship frame the ISM is a beam of protons arriving
at β with density γn.

**The wall is an elastic mirror.** A particle meeting a barrier it cannot
climb reflects elastically. In the ship frame the wall is at rest, so each
proton keeps its energy and reverses the momentum component normal to the
wall. There is drag, but no heating. If the impact energy were thermalised
instead, and the resulting glow came inward through the transparent wall,
every relativistic trip would be lethal (HB-45).

**Fluxes on a face-on surface, ship frame:**
- momentum flux × c: P_mom c = n γ²β² m_p c³ (W/m²). This is the "load
  scale" that the drag follows.
- kinetic-energy flux: K = n γβ (γ−1) m_p c³ (W/m²). This is what would be
  deposited if the impacts were thermalised. At high γ the two converge.

**Drag on the sphere.** For specular reflection off a static sphere, each
proton gives momentum 2p cos²α along the beam (α is the angle between the beam
and the local normal). Averaged over the projected disc, ⟨cos²α⟩ = ½. So the
sphere has half the drag of a flat face-on mirror of the same projected area:

  **F = n γ²β² m_p c² A** (N), for a specular sphere. A flat mirror would give
  twice this.

The force along the motion is the same in the ship and galaxy frames.

**Drag energy per trip.**
- *Ship frame* (what the drive radiates to hold cruise speed): photon energy
  F c per unit proper time, over τ = d/(γβc), gives
  **E_drag = F c τ = n γβ m_p c² A d** (J). This grows as about γ·d.
- *Galaxy frame* (what the reflected protons carry away): W = F d =
  n γ²β² m_p c² A d. Energy is conserved. A proton at rest hit head-on by a
  mirror moving at β leaves with γ_r = γ²(1+β²) = cosh 2φ, gaining
  (γ_r − 1) m_p c² = 2γ²β² m_p c². Summed over the swept volume, this gives
  exactly F·d in the flat-mirror case; the sphere halves both sides.

E_drag is the energy-ledger quantity, because it is measured in the frame
where the generator lives, like E_boost (§4). The 2026-10-01 brief's worked
estimates used a flat face-on mirror, which doubles them. The values below are
for the sphere, which is canon (design-decisions 2026-09-28).

| ID | Quantity (n = 0.1 cm⁻³; A = π(100 m)²; α Cen one way) | Value | Unit |
|---|---|---|---|
| HB-38 | Load scale n γ²β² m_p c³ at 0.5c | 1.50 × 10³ | W/m² |
| HB-39 | Load scale at 0.9c | 1.92 × 10⁴ | W/m² |
| HB-40 | Load scale at 0.99c | 2.22 × 10⁵ | W/m² |
| HB-41 | Load scale at 0.99c, in suns | 163 | sun |
| HB-42 | Load scale at 0.999999c | 2.25 × 10⁹ | W/m² |
| HB-43 | Load scale at 0.999999c, in suns | 1.66 × 10⁶ | sun |
| HB-44 | Kinetic-energy flux K if thermalised, at 0.5c | 403 | W/m² |
| HB-45 | Kinetic-energy flux K if thermalised, at 0.99c | 1.93 × 10⁵ | W/m² |
| HB-46 | Kinetic-energy flux K if thermalised, at 0.999999c | 2.25 × 10⁹ | W/m² |
| HB-47 | Drag force on the sphere at 0.5c | 0.157 | N |
| HB-48 | Drag force on the sphere at 0.9c | 2.01 | N |
| HB-49 | Drag force on the sphere at 0.99c | 23.3 | N |
| HB-50 | Drag force on the sphere at 0.999999c | 2.36 × 10⁵ | N |
| HB-51 | Ship-frame drag energy, α Cen at 0.5c | 1.13 × 10¹⁶ | J |
| HB-52 | Ship-frame drag energy, α Cen at 0.9c | 4.03 × 10¹⁶ | J |
| HB-53 | Ship-frame drag energy, α Cen at 0.99c | 1.37 × 10¹⁷ | J |
| HB-54 | The same, as mass-energy E/c² | 1.52 | kg |
| HB-55 | Ship-frame drag energy, α Cen at 0.999999c | 1.38 × 10¹⁹ | J |
| HB-56 | The same, as mass-energy E/c² | 154 | kg |
| HB-57 | Galaxy-frame energy carried by the plume, α Cen at 0.99c | 9.62 × 10¹⁷ | J |
| HB-58 | Galaxy-frame energy carried by the plume, α Cen at 0.999999c | 9.76 × 10²¹ | J |

**R1 scope:** the simulation computes E_drag and the glow (§6) from the
constant density n, as a *readout*. An enforced energy budget comes later.

## 6. The glow and the plume

**The glow.** The canon boundary glow (design-decisions 2025-12-08) survives,
but it is faint. A small inelastic fraction ε of the incident kinetic-energy
flux becomes light at the wall. ε is a design parameter, canon **10⁻¹⁰**
(HB-111: ledger D-29 and Mark's follow-up of 2026-10-03; it was 10⁻⁹ under
D-15). Glow power, ship frame:

  P_glow = ε K A (W)

A fraction f_in of it shines inward through the transparent wall. Spread over
the inner surface 4πR², the mean inward flux is ε f_in K / 4 (W/m²). A wall
element whose outward normal is at angle θ from the travel direction
intercepts K max(0, cos θ), so its inward emittance is
E(θ) = ε f_in K max(0, cos θ): the glow peaks at the forward pole (4× the
mean) and is zero on the aft hemisphere. It scales with speed and local
density, so it still works as the motion cue.

**The spectrum: a greybody at the impact temperature** (ledger D-30). The
glow is thermal light from the impacts. By Kirchhoff's law a body emits light
exactly as well as it absorbs it, and the wall absorbs almost none (it is
transparent, property 1). So the wall element is a greybody of emissivity ε:
it thermalises ε K cos θ and radiates it as ε σ T⁴, and ε cancels:

  **T(θ) = (K max(0, cos θ) / σ)^¼** (K)

This is the temperature a black surface would reach if it thermalised the
whole forward beam. It sets the colour; ε and f_in set only the brightness.
The inner face emits ε f_in σ T⁴ = E(θ), a Planck spectrum at T dimmed by
the emissivity. The wall is Lambertian, so the radiance is E/π, and the
luminance is (E/π) × η(T). Here η(T) is the luminous efficacy of blackbody
light, π K_m ∫B_λ(T) ȳ dλ / σT⁴ with K_m = 683 lm/W. Off the pole T falls as
cos^¼ θ, so the rim of the glow is redder than its centre.

The temperature climbs with speed:
- below about 0.94c (γ ≈ 2.9, HB-99) it is under the 798 K Draper point,
  so the glow is effectively infrared;
- at 0.99c it is a deep orange-red 1,358 K, with an efficacy of only
  0.023 lm/W;
- at the top of the slider it is a blue-white 14,114 K at 44 lm/W.

**Faint at cruise, a cue at the top, with numbers.** At ε = 10⁻¹⁰ the 0.99c
pole is 1.65 × 10⁻³ of the 23.5 mag/arcsec² dark sky. That is invisible, so
the starbow at the default cruise speed is untouched. The glow rises about
2 × 10⁷-fold from 0.99c to the cap, so ε mainly sets where it appears:
- it reaches 0.3 of the dark sky at γ ≈ 13.5 (β ≈ 0.9972, HB-112) and the
  dark sky itself at γ ≈ 16.2 (β ≈ 0.9981, HB-108);
- at 0.999c it is a dim orange-red veil, about 6 dark skies;
- at 0.9999c it is a warm-white wash, about 560 dark skies;
- at the cap it is a blue-white sky of 1.56 cd/m² (3.6 × 10⁴ dark skies),
  about the luminance of a sky in civil twilight.

It fades out as the ship brakes. Even at the cap the forward CMB disc is
10⁸ times brighter than the glow: its luminance, 2 × 10⁸ cd/m², is the
photopic radiance of a blackbody at HB-63's 3,853.7 K. At that speed it is
the CMB disc, not the glow, that sets the eye's adaptation.

*Game approximation, on top of the bubble's own hand-wave:*
- Real GeV impacts on matter make hadronic cascades, pion-decay gamma rays
  and bremsstrahlung, not a Planck spectrum. The blackbody is a stand-in.
- The emissivity is set equal to the thermalised fraction ε.
- Each wall element is in local radiative equilibrium: no lateral
  conduction and no thermal lag. The glow follows the speed instantly.

The alternative, a temperature from the per-particle energy
(kT ~ (γ−1) m_p c², about 7 × 10¹³ K at 0.99c), is rejected: GeV protons do not
make a thermal gas, and the visible tail of such a body is a fixed
Rayleigh–Jeans blue at every speed. The other alternative, a black wall
(emissivity 1) radiating only the glow flux, T = (E/σ)^¼, gives 3.6 K at 0.99c
and 37 K at the cap. That glow would be invisible at every speed, and it
would contradict the transparent wall.

*Why ε = 10⁻¹⁰.*
- **The history.** Mark first ruled "about 10⁻¹¹" (D-29) after the M4.2
  evaluation found the 0.99c pole 130× the dark sky. That evaluation used the
  placeholder equal-energy white (183 lm/W), and most of the excess came from
  the placeholder, not from ε: with the D-30 spectrum, even ε = 10⁻⁹ puts the
  0.99c pole at 0.016× the dark sky.
- **The follow-up (attended 2026-10-03).** Mark: "the glow can be any value
  right? but I want our star effects to be seen, so just pick a value where
  we get both."
- **The comparison.** Four candidates, 10⁻¹¹, 3 × 10⁻¹¹, 10⁻¹⁰ and
  3 × 10⁻¹⁰, were rendered through the game's own exposure (the dark-adapted
  eye, whose meter sees the glow). Each candidate was shown at 0.99c, 0.995c,
  0.999c, 0.9999c and the cap, and compared with the glow switched off. The
  sheet is `stapledons-godot make glow-eps-sheet`, published at
  `gs://stapledons-voyage-assets/refs/glow/eps_compare.jpg`.

Results at 10⁻¹⁰, counting catalogue stars in the 60° forward view above both
the Crumey threshold against the local background and the display threshold
at the eye's EV:
- **0.99c and 0.995c:** unchanged, with every star kept.
- **0.999c:** 84 % of the stars stay visible. The eye does not move (+0.04 EV)
  and the starbow keeps its blue-shifted colours.
- **0.9999c:** 28 % of the stars stay visible (3 × 10⁻¹¹ gives 31 %, and 10⁻¹¹
  gives 39 %). At this speed every candidate's veil limits the stars, but the
  starbow cluster stays plainly readable. The eye light-adapts
  by +2.2 EV.
- **The cap:** the CMB disc dominates (the eye sits at EV +12.5 with or without
  the glow). The disc stays 1.3 × 10⁸ times brighter than the glow.

3 × 10⁻¹⁰ crosses the line. At 0.9999c it keeps 16 % of the stars and moves the
eye +3.7 EV, and at 0.999c it keeps 68 %. So 10⁻¹⁰ is the brightest candidate
that keeps the starbow, the Doppler colours and the CMB disc readable at every
speed, while the glow is visible as a cue over the widest range, from about
0.997c up.

HB-45, HB-46 and HB-61 do not depend on ε and are unchanged. The canon ε is
36× below HB-61's bound.

**The plume.** The reflected protons form a forward plume of
ultra-relativistic particles. In the ship frame each proton arrives with
energy γ m_p c². In the galaxy frame a head-on reflection leaves it with
γ²(1+β²) m_p c².

| ID | Quantity | Value | Unit |
|---|---|---|---|
| HB-59 | ISM proton energy in the ship frame at 0.999999c | 663.5 | GeV |
| HB-60 | Head-on reflected proton energy, galaxy frame, at 0.999999c | 9.38 × 10⁵ | GeV |
| HB-61 | Design guide: largest ε for a mean inward glow ≤ 1 W/m² at 0.999999c with f_in = ½ | 3.6 × 10⁻⁹ | — |

Glow spectrum and brightness (D-29 and its follow-up, D-30). n = 0.1 cm⁻³, f_in = ½, ε = 10⁻¹⁰
(HB-111), forward pole unless stated. The dark sky is 23.5 mag/arcsec² =
4.33 × 10⁻⁵ cd/m². Oracle: `sunholo/relativity` `tools/glow_spectrum_ref.py`.

| ID | Quantity | Value | Unit |
|---|---|---|---|
| HB-95 | Glow temperature at the pole at 0.5c (infrared) | 290 | K |
| HB-96 | Glow temperature at the pole at 0.99c | 1,358 | K |
| HB-97 | Glow temperature at the pole at 0.999c | 2,482 | K |
| HB-98 | Glow temperature at the pole at 0.999999c | 14,114 | K |
| HB-99 | γ at which the glow pole reaches the Draper point (798 K) | 2.89 | — |
| HB-100 | Luminous efficacy of the glow at the pole at 0.99c | 0.0233 | lm/W |
| HB-101 | Luminous efficacy of the glow at the pole at 0.999999c | 43.7 | lm/W |
| HB-102 | Inward glow emittance at the pole at 0.99c | 9.63 × 10⁻⁶ | W/m² |
| HB-103 | Inward glow emittance at the pole at 0.999999c | 0.1125 | W/m² |
| HB-104 | Glow luminance at the pole at 0.99c | 7.14 × 10⁻⁸ | cd/m² |
| HB-105 | The same, as a fraction of the dark sky | 1.65 × 10⁻³ | — |
| HB-106 | Glow luminance at the pole at 0.999999c | 1.56 | cd/m² |
| HB-107 | The same, in dark skies | 3.61 × 10⁴ | — |
| HB-108 | γ at which the glow pole equals the dark sky | 16.2 | — |
| HB-109 | Mean inward glow at 0.99c (the sim's glow_w_m2) | 2.41 × 10⁻⁶ | W/m² |
| HB-110 | Mean inward glow at 0.999999c | 2.81 × 10⁻² | W/m² |
| HB-112 | γ at which the glow pole reaches 0.3 of the dark sky (the visibility threshold of the ε comparison) | 13.5 | — |

HB-59 is also why no proton may cross: at γ 707 the ISM would arrive inside as
a 660 GeV proton beam. The old "trace hydrogen crosses" canon is removed.

## 7. Light and neutrinos cross: what the crew sees

Light crosses the wall unchanged, so the relativistic sky of M1 (relativity
spec §2: aberration, Doppler, beaming, the starbow) is exactly what the crew
sees.

**The forward CMB.** Straight ahead, the cosmic microwave background is
blueshifted by D = γ(1+β) = e^φ:

  T_fwd = T_CMB · γ(1+β) (K)

Off-axis the temperature falls as D(θ') = 1/(γ(1 − β cos θ')) ≈ 2γ/(1+γ²θ'²),
so it halves at θ' = 1/γ rad from the pole. The result is a glow centred on the
forward pole, not a sharp disc. The 2026-10-01 brief called it "~1/γ rad
across"; 1/γ is the half-temperature *radius*.

**Forward radiation load.** For any isotropic background of energy density u,
the flux on a forward-facing surface at high γ is (4/3) γ² u c. For the CMB
this is (16/3) γ² σ T_CMB⁴. The starlight background (u ≈ 0.5 eV/cm³, an
approximate value, so it has no check value) gives roughly 16 W/m² at γ 707,
blueshifted into soft X-rays of about 1 keV. Soft X-rays are absorbed within
micrometres of glass, so the dome glazing and hull stop them. The wall does
not, because property 1 lets light of every energy through. Ruled by D-15
(2026-10-01): photon shielding is this physical glazing and hull, and the
2025-12-06 "Radiation Shielding Automatic" entry is superseded in part. Massive radiation (cosmic rays,
stellar wind) is blocked by the wall, as before.

| ID | Quantity | Value | Unit |
|---|---|---|---|
| HB-62 | Forward CMB temperature at 0.99c | 38.44 | K |
| HB-63 | Forward CMB temperature at 0.999999c | 3,853.7 | K |
| HB-64 | Draper point: a dull red glow to dark-adapted eyes | 798 | K |
| HB-65 | γ at which the forward CMB reaches the Draper point | 146.4 | — |
| HB-66 | Plainly visible orange glow | 1,500 | K |
| HB-67 | γ at which the forward CMB reaches 1,500 K | 275.2 | — |
| HB-68 | Half-temperature angle from the pole at 0.999999c, 1/γ | 0.0810 | deg |
| HB-69 | The same angle | 1.414 | mrad |
| HB-70 | CMB flux on a forward-facing surface at 0.999999c | 8.34 | W/m² |

**Renderer gap:** the forward CMB glow is not rendered yet (game charter row
6a). It is faintly visible from γ ≈ 146 and plainly from γ ≈ 275 (HB-65,
HB-67). It is tracked as an R1 item in the roadmap.

## 8. The closed mass budget

No massive particle enters or leaves (property 1). The only outflow is light:
the drive (§4, §5) and the glow (§6). The energy for that light comes from
inside the bubble. Its source and the enforced budget belong to the later
energy ledger, tied to the canon "Finite Mass Budget" (design-decisions
2025-12-06). In R1, M2's mass-budget stub becomes an **m_eff plus
energy-ledger readout**: E_boost and E_brake (HB-35, HB-36) and E_drag
(HB-51 to HB-56).

Superseded canon: "Slow Mass Absorption" (no mass enters) and the femtogram
seeds of "Proto-Tech via Information Only" (information still crosses, as
light).

## 9. Tides are not shielded

The wall stops particles, not curvature: tidal gravity is geometry. The radial
tidal acceleration between the centre and the wall is

  **a_tide = 2GM L / r³** (m/s²; L = 100 m)

In units of r_s = 2GM/c², at r = k r_s: a_tide = L c⁶ / (4 G² M² k³). So tides
at a fixed multiple of r_s fall as 1/M².

- **Safe radius** for a_tide ≤ a_max: r_safe = (2GML/a_max)^(1/3).
- **Minimum mass** for a_tide ≤ a_max at k r_s:
  M_min = √(L c⁶ / (4 G² k³ a_max)).

| ID | Quantity (tide across the 100 m radius) | Value | Unit |
|---|---|---|---|
| HB-71 | Gaia BH1: Schwarzschild radius | 28.4 | km |
| HB-72 | Gaia BH1: tide at 10 r_s | 1.14 × 10⁶ | g |
| HB-73 | Gaia BH1: tide at 5 r_s | 9.08 × 10⁶ | g |
| HB-74 | Gaia BH1: tide at 3 r_s | 4.21 × 10⁷ | g |
| HB-75 | Gaia BH1: radius beyond which the tide is ≤ 0.1 g | 2,248 | r_s |
| HB-76 | The same radius | 63,900 | km |
| HB-77 | 1,000 M☉ hole: Schwarzschild radius | 2,953 | km |
| HB-78 | 1,000 M☉ hole: tide at 10 r_s | 105 | g |
| HB-79 | 1,000 M☉ hole: tide at 5 r_s | 841 | g |
| HB-80 | 1,000 M☉ hole: tide at 3 r_s | 3,890 | g |
| HB-81 | 1,000 M☉ hole: radius beyond which the tide is ≤ 0.1 g | 102 | r_s |
| HB-82 | Sgr A*: Schwarzschild radius | 1.269 × 10¹⁰ | m |
| HB-83 | Sgr A*: Schwarzschild radius | 0.0848 | AU |
| HB-84 | Sgr A*: tide at 10 r_s | 5.69 × 10⁻⁶ | g |
| HB-85 | Sgr A*: tide at 5 r_s | 4.55 × 10⁻⁵ | g |
| HB-86 | Sgr A*: tide at 3 r_s | 2.11 × 10⁻⁴ | g |
| HB-87 | Smallest mass with a tide ≤ 0.1 g at 3 r_s | 1.97 × 10⁵ | M☉ |

**Consequence:** stellar and intermediate holes are lethal near the horizon.
Only supermassive holes allow a close approach. This is why the M3 demo hole
is Sgr A* (D-13).

## 10. Hovering and orbiting

A static (hovering) observer at r needs proper acceleration

  a_hover = GM / (r² √(1 − r_s/r)) (m/s²)

By property 3 it is not felt inside. The photon drive must supply the force
F = m_eff a_hover, so the power is

  **P_hover = m_eff a_hover c** (W)

A circular orbit is free fall and needs no power. Stable circular orbits exist
for r ≥ 3 r_s (the ISCO).

| ID | Quantity | Value | Unit |
|---|---|---|---|
| HB-88 | Sgr A*: hover acceleration at 3 r_s | 4.82 × 10⁵ | m/s² |
| HB-89 | The same acceleration | 4.91 × 10⁴ | g |
| HB-90 | Sgr A*: hover power at 3 r_s per kg of m_eff | 1.44 × 10¹⁴ | W/kg |

## 11. The arrival stand-off

The slice parks at 1,000 AU from the target star (HB-15, D-14). α Cen A has
V = 0.01 at 4.37 ly. A and B orbit each other every 79.9 years, between 11.2
and 35.6 AU apart.

| ID | Quantity | Value | Unit |
|---|---|---|---|
| HB-91 | α Cen A seen from 1,000 AU, apparent magnitude | −12.2 | mag |
| HB-92 | A–B separation seen from 1,000 AU, at periastron (11.2 AU) | 0.64 | deg |
| HB-93 | A–B separation seen from 1,000 AU, at apastron (35.6 AU) | 2.04 | deg |
| HB-94 | A–B separation seen from 1,000 AU, at 23.5 AU | 1.35 | deg |

## 12. Proposed `sunholo/relativity` functions

These are proposed names only. Each gets package tests against the check
values above, then a CHANGELOG entry and a release, before the simulation pins
it.

| Function | Formula | Checks |
|---|---|---|
| `photon_drive_energy(m_eff, phi)` | m_eff c² φ | HB-35 … HB-37 |
| `cruise_times(d, phi)` | t = d/(c tanh φ), τ = t / cosh φ | HB-20 … HB-22, HB-25, HB-26 |
| `boost_profile(phi, tau_boost)` | a = cφ/τ; galaxy time (c/a) sinh φ; distance (c²/a)(cosh φ − 1) | HB-30 … HB-34 |
| `ism_load_scale(n, phi)` | n sinh²φ m_p c³ | HB-38 … HB-43 |
| `ism_kinetic_flux(n, phi)` | n sinh φ · 2 sinh²(φ/2) m_p c³ | HB-44 … HB-46 |
| `ism_drag_force(n, phi, radius)` | n sinh²φ m_p c² πR² (sphere) | HB-47 … HB-50 |
| `ism_drag_energy_ship(n, phi, radius, d)` | n sinh φ m_p c² πR² d | HB-51 … HB-56 |
| `ism_plume_energy_galaxy(n, phi, radius, d)` | n sinh²φ m_p c² πR² d | HB-57, HB-58 |
| `reflected_gamma(phi)` | cosh 2φ | HB-60 |
| `cmb_forward_temperature(phi)` | T_CMB e^φ | HB-62 … HB-67 |
| `medium.glowEmittanceAt(n, phi, eps, fIn, cosθ)` (0.6.0) | ε f_in K max(0, cos θ) | HB-102, HB-103, HB-109, HB-110 |
| `medium.glowTemperatureAt(n, phi, cosθ)` (0.8.0) | (K max(0, cos θ)/σ)^¼ | HB-95 … HB-99 |
| `medium.glowRadianceAt(n, phi, eps, fIn, cosθ)` (0.8.0) | E/π | HB-104, HB-106 |
| `medium.glowEfficacyAt(n, phi, cosθ)` (0.8.0), `blackbody.luminousEfficacy(T)` | π K_m ∫B_λ ȳ dλ / σT⁴ | HB-100, HB-101 |
| `medium.glowLuminanceAt(n, phi, eps, fIn, cosθ)` (0.8.0) | (E/π) η(T) | HB-104 … HB-108, HB-112 |
| `tidal_accel(m, r, lever)` | 2GmL/r³ | HB-72 … HB-74, HB-78 … HB-80, HB-84 … HB-86 |
| `tidal_safe_radius(m, lever, a_max)` | (2GmL/a_max)^(1/3) | HB-75, HB-76, HB-81 |
| `tidal_min_mass(lever, k, a_max)` | √(L c⁶/(4G²k³a_max)) | HB-87 |
| `hover_accel(m, r)` | GM/(r²√(1−r_s/r)) | HB-88, HB-89 |
| `hover_power(m_eff, a)` | m_eff a c | HB-90 |

The 1 g flip-and-burn (HB-27 … HB-29) is already the package's `journey` check.
The rapidity forms keep float64 precision at γ 707 without forming 1−β.
