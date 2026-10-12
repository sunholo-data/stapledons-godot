# Relativity visuals: accuracy spec

**Status:** Normative. Every SR/GR visual must meet this spec and ship with tests.
**Pillar:** Hard Sci-Fi Authenticity, which the design docs call "SR effects
must be accurate in all directions".

## 1. Conventions

- **n:** unit vector from the observer toward the source, in the galaxy (rest)
  frame.
- **n':** unit vector toward where the source *appears* in the ship frame.
- **Velocity:** a unit direction β̂ plus a speed β, with c = 1.
  - γ = 1/√(1−β²)
  - Rapidity φ = atanh β; the simulation integrates φ.
- **D:** Doppler factor, ν_observed/ν_emitted. D > 1 means blueshift.

## 2. Special relativity (moving observer, flat space)

| Effect | Formula | Check values (must pass) |
|---|---|---|
| Aberration | n' = (n + ((γ−1)(n·β̂) + γβ) β̂) / (γ(1 + β n·β̂)); scalar form cos θ' = (cos θ + β)/(1 + β cos θ) | 90° at 0.9c → 25.842°. 90° at 0.5c → 60°. Straight ahead and straight behind are unchanged. Result is unit length. |
| Inverse aberration (sky sampling) | n = aberrate(n', −β) | Round trip error < 1e-6 |
| Doppler | D = γ(1 + β cos θ) = 1/(γ(1 − β cos θ')) | Ahead at 0.9c: √19 = 4.3589. Astern: 0.22942. Appearing at 90°: 1/γ |
| Spectrum | A blackbody at T is seen as a blackbody at D·T (because I_ν/ν³ is invariant) | |
| Point-source brightness | F'_band/F_band = (Y(D·T)/Y(T)) / D², where Y is CIE luminance of the Planck spectrum | Bolometric total = D² |
| Extended-source brightness (sky, nebulae) | Radiance I' = D⁴ I bolometric; in a band, the radiance of a blackbody at D·T | |
| Colour | Planck × CIE 1931 2° observer → XYZ → linear sRGB (D65). Out-of-gamut colours are desaturated at constant Y | 2856 K → (0.4476, 0.4074) ±0.002. 6500 K → (0.3135, 0.3236). |
| 3D objects nearby (planets, ships) | Aberrate every vertex. For rapidly moving geometry, use retarded-time positions (Terrell–Penrose rotation) | Sphere stays circular in outline |

**Rendering requirements**

- **HDR everywhere.** Use float render targets. Tonemapping happens only at the
  end, and no 8-bit clamp may come before it. At 0.99c, D reaches 14, and the
  forward "headlight" is a real effect that has to survive.
- **float64 for γ and 1−β.** Compute them on the CPU and pass them in.
  - In a shader, 1+β cos θ must be rewritten as (1−β) + β(1+cos θ) when
    cos θ < 0.
  - Godot's `Vector3` is float32. Keep physics that needs precision in scalar
    float64 values.
- **Stars behind the camera must be culled before projection.** Otherwise
  clip-space w ≤ 0 mirrors them back into view (a bug found in the spike).
- **Temperature lookup tables must be finite and monotonic** across the whole
  range the Doppler factor can reach. In the spike, a float32 underflow at
  300 K produced NaN, which rendered as an infinitely bright blob.

**Frames**

- **Directions are galactic Cartesian (IAU):** x toward the galactic centre
  (l 0°, b 0°), y toward l 90°, z toward the north galactic pole (NGP). Galactic
  longitude increases to the *left* for an observer facing the centre with the
  NGP up.
- **Any map into an engine frame must be a proper rotation (det +1), defined in
  one place.** A reflection keeps every angle, so aberration, Doppler and
  brightness checks still pass, and a GPU-vs-CPU golden that shares the map
  cannot catch it. The Godot build fell into exactly this: its first map,
  (x, y, z) → (y, z, −x), has det −1 and rendered the whole sky as a mirror
  image (stapledons-godot D-28, 2026-10-03). The fix was (x, y, z) → (−y, z, −x).
- **Check (must pass, map-independent):** face the galactic centre with the NGP
  up. Antares (l 352°) and α Cen (l 316°) appear to the right of the centre, and
  Vega (l 67°) and the Scutum star cloud (l 27°) to the left. A ship's starboard
  side then faces l 270°, and its port side l 90°.

## 3. General relativity (Schwarzschild; the black-hole feature)

The design docs (`gr-visual-mechanics.md`) list full ray tracing as a
non-goal. This spec replaces that with an accurate method that is still
affordable: **precomputed null geodesics**.

| Quantity | Correct value | Old implementation |
|---|---|---|
| Event horizon | r_s = 2GM/c² | The black disk was drawn at r_s ✗ |
| Photon sphere | r = 1.5 r_s | A three-sample blur at 1.5 r_s |
| Shadow (critical impact parameter) | b_c = (3√3/2) r_s ≈ 2.598 r_s. Angular radius seen from radius r: sin α = (b_c/r)·√(1 − r_s/r) | Wrong: drawn at r_s |
| Deflection | Exact: integrate d²u/dφ² = −u + (3/2) r_s u² (u = 1/r). Weak-field limit α = 2 r_s/b (radians) | Used as a UV shift, and the CPU and GPU pushed in opposite directions ✗ |
| Einstein ring | Present for any source behind the hole. Secondary and higher-order images inside it, crowding toward b_c | Missing ✗ |
| Observer gravitational shift | A static observer at r sees incoming starlight blueshifted by 1/√(1 − r_s/r). Background light is not redshifted by where it appears on screen | Computed from screen distance ✗ |
| Accretion-disk emission (later) | g = √(1 − 3r_s/2r)… plus disk Doppler; I_obs = g⁴ I_emit | n/a |

**Method**

1. On the CPU at load time, integrate the Binet equation for a grid of impact
   parameters b (dense near b_c). Store the total deflection angle Δφ(b) and a
   "captured" flag in a 1D float texture.
2. Per pixel, build the view ray. First apply the observer's own motion by
   inverse aberration, using the static-observer frame at r. Then compute b
   from the angle between the ray and the direction to the hole, look up
   Δφ(b), rotate the ray about the hole axis, and sample the sky cubemap or
   starfield. Captured rays render black.
3. Stars can't be resampled from a cubemap without losing their point
   sharpness. Transform each star instead: apply the inverse lens map to its
   direction to find image positions (primary and secondary), with
   magnification from the Jacobian.
4. **Observer at finite r.** For an observer at radius r, tabulate δ(ψ, r): the
   bending of a ray seen at angle ψ from the direction to the hole. This is a
   2D table. It may be generated by the integrator or by the exact elliptic-
   integral form, provided the other cross-checks it.

**Check values** (IDs in §7):
- The shadow's critical impact parameter is 2.598 r_s (RS-9). Its angular
  radius is 14.27°, 27.69° and 45.00° at 10, 5 and 3 r_s (RS-10 to RS-12).
- **Weak field, a pair** (D-13, 2026-10-01): the deflection is within 1% of
  2r_s/b at b = 1000 r_s (measured 0.148%; RS-14), and within a relative 3e-4
  of 2r_s/b + (15π/16)(r_s/b)² at b = 100 r_s (measured 2.68e-4; RS-15). The
  first-order formula alone is 1.48% off at b = 100 r_s, which is why the old
  "1% at 100 r_s" check was replaced.
- The Einstein ring appears at the angle predicted for a chosen geometry
  (RS-Q4).
- Photon-ring images converge on b_c (RS-Q3).
- A static observer's clock-rate and blueshift factor is 1/√(1 − r_s/r) (RS-16
  to RS-20).

## 4. Test requirements

- A **CPU reference** (`physics/*.gd` in the Godot repo) with a unit test for
  every row of the tables above.
- **GPU vs CPU golden tests:** render synthetic single sources and require the
  sub-pixel centroid to match the reference projection within 0.75 px. The
  spike achieves under 0.1 px. Also include hidden or invisible cases: behind
  the camera, and redshifted below the visible band.
- **Reference renders** at 0, 0.5, 0.9, 0.99 and 0.999c, each looking forward,
  to the side and astern, and near the black hole at 10, 5 and 3 r_s. These
  are regenerated and diffed in CI.

## 5. Audit of the Go implementation (commit `930eca1`)

| # | File | Defect |
|---|---|---|
| 1 | `engine/relativity/transform.go:115` | Photon-direction formula applied to a source direction, so aberration had the wrong sign (stars moved backward) |
| 2 | `engine/shader/shaders/sr_warp.kage:66` | Inverse aberration used +β instead of −β. Screen radius mapped linearly to angle, which is only valid on-axis |
| 3 | `sr_warp.kage:107` | Doppler used the rest-frame angle together with an apparent-frame formula |
| 4 | `sr_warp.kage:130–136`, `space_view.go:287` | Beaming used D³, clamped to [0.08, 6] and LDR 1.0. Point sources should scale as D² bolometric |
| 5 | `relativity/color.go:124` | 7 fixed temperatures per spectral class. The 1000–40000 K clamp hides the fade to infrared and ultraviolet |
| 6 | `gr_lensing.kage:50` | Shadow drawn at r_s instead of about 2.6 r_s |
| 7 | `gr_lensing.kage:69–81`, `space_view.go:224` | Lensing was a UV displacement; CPU and GPU used opposite signs |
| 8 | `gr_redshift.kage:68` | Redshift computed from screen distance, which has no physical meaning |
| 9 | none | No tests for transform, colour or shaders; no SR/GR golden images |

## 6. Bubble-derived physics

The Higgs bubble is the game's one admitted hand-wave. Its consequences (the
photon drive, ISM drag and glow, the forward CMB, tides across the bubble,
hover power) are derived exactly in [higgs-bubble.md](higgs-bubble.md), with
check values HB-n. Two of them meet this spec:
- the forward CMB is a blackbody at D·T_CMB (§2 "Spectrum"), giving HB-62 to
  HB-70;
- tides near a hole are not shielded by the wall, which is why the M3 demo
  hole is Sgr A* (HB-71 to HB-87).

## 7. Check-value index

Stable IDs for tests and for the in-game Archive (`lore/archive/`), which cites
them in its front matter. As in `higgs-bubble.md`, each registry row holds one
number in the columns `ID | Quantity | Value | Unit`, and `—` means
dimensionless.

| ID | Quantity | Value | Unit |
|---|---|---|---|
| RS-1 | Aberration: a source at 90° (rest frame) seen from 0.9c appears at | 25.842 | deg |
| RS-2 | Aberration: a source at 90° (rest frame) seen from 0.5c appears at | 60 | deg |
| RS-3 | Doppler factor straight ahead at 0.9c (√19) | 4.3589 | — |
| RS-4 | Doppler factor straight astern at 0.9c | 0.22942 | — |
| RS-5 | Colour: chromaticity x of a 2856 K blackbody (± 0.002) | 0.4476 | — |
| RS-6 | Colour: chromaticity y of a 2856 K blackbody (± 0.002) | 0.4074 | — |
| RS-7 | Colour: chromaticity x of a 6500 K blackbody | 0.3135 | — |
| RS-8 | Colour: chromaticity y of a 6500 K blackbody | 0.3236 | — |
| RS-9 | Critical impact parameter b_c = (3√3/2) r_s | 2.598 | r_s |
| RS-10 | Shadow angular radius, sin α = (b_c/r)√(1 − r_s/r), at 10 r_s | 14.27 | deg |
| RS-11 | Shadow angular radius at 5 r_s | 27.69 | deg |
| RS-12 | Shadow angular radius at 3 r_s | 45.00 | deg |
| RS-13 | Shadow angular radius at 1.5 r_s (the shadow fills half the sky) | 90 | deg |
| RS-14 | Weak-field tolerance vs 2r_s/b at b = 1000 r_s (measured 0.148%) | 1 | % |
| RS-15 | Weak-field relative tolerance vs 2r_s/b + (15π/16)(r_s/b)² at b = 100 r_s (measured 2.68e-4) | 3 × 10⁻⁴ | — |
| RS-16 | Static observer factor 1/√(1 − r_s/r) at 10 r_s | 1.054 | — |
| RS-17 | Static observer factor at 5 r_s | 1.118 | — |
| RS-18 | Static observer factor at 3 r_s | 1.225 | — |
| RS-19 | Static observer factor at 2 r_s | 1.414 | — |
| RS-20 | Static observer factor at 1.5 r_s (√3) | 1.732 | — |
| RS-21 | Photon sphere radius | 1.5 | r_s |
| RS-22 | Reference speed for RS-1, RS-3 and RS-4 | 0.9 | c |
| RS-23 | Reference speed for RS-2 | 0.5 | c |

Qualitative checks (not numbers, so not in the registry):
- **RS-Q1:** straight ahead and straight behind are unchanged by aberration,
  and the aberrated direction is unit length.
- **RS-Q2:** a source appearing at 90° has D = 1/γ; point-source bolometric
  brightness scales as D²; aberration round-trip error < 1e-6.
- **RS-Q3:** photon-ring images converge on b_c.
- **RS-Q4:** an Einstein ring appears for any source behind the hole, at the
  predicted angle.
