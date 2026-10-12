### Added

- M1.8 forward CMB disc (queue row 6a, D-11). The sky shader adds the CMB per pixel as
  `photopicRadiance(T0 · D(θ′))` in cd/m², with D = 1/(γ(1 − β cos θ′)) and T0 = 2.725 K, in the
  same exposure as the galaxy and the stars. At the cap (1 − β = 1e-6, γ 707) the pole is
  3,853.7 K (HB-63) and 1.98e8 cd/m²; T halves near θ′ = 1/γ (4.9′), and the disc delivers
  ~189 lux. At γ 275 the pole is 1,499 K, a visible orange disc. At rest the term is exactly 0.
  `sky/cmb.gd` builds a radial profile once per speed (rebuilt when γ moves 0.5%), blurred by
  the same angular PSF as the stars (Hankel form with I0e), so the sub-pixel core neither aliases
  nor loses illuminance. It reads photopic radiance through a finite lookup over T ∈ [0, 5,000 K]
  (gate 5).
- GDScript mirrors of `photopicRadiance`, `cmbSeenTemperature` and `cmbSeenTemperatureApparent`
  (sunholo/relativity 0.5.2), written in the 1 − β form so nothing cancels near c. `make physics`
  checks them against the package's values: HB-62 38.44 K, HB-63 3,853.7 K, rest-frame 90° = 1,926.9 K
  (apparent asin(1/γ)), apparent 90° = T0/γ.
- `make golden`: 7 CMB cases. The sharp disc at γ 707 reads the package radiance within 1% at θ′ ≈ 0,
  1/γ and 2/γ; the PSF disc matches the CPU profile; θ′ = 45° and 90° read exactly 0, and so does
  every pixel at β = 0.
- `make capture`: γ 275 and γ 707 on a real journey (boost, then cruise), forward and starboard,
  each as eye, camera auto and camera fixed-at-rest; 4° zooms on the disc; `cmb_sheet.png`.

### Changed

- The star PSF is fixed in angle (σ = 6′, the dark-adapted eye's blur; at least 0.7 px). EV_dark is
  now one number (−4.40) at every render size, and the dark sky shows the same linear value at
  960×540 and 2560×1440. M1.5a measured a 7.1× difference. V_lim is 6.8 at 960×540 and 6.9 at
  2560×1440 (AC8 6.6–7.4).
- The eye mode meters with `sky/sky_meter.gd`: a centre-weighted (σ 12°) arithmetic mean that
  includes the stars (direction × temperature bins, nearer than 20 ly one by one) and the CMB
  disc. The eye now light-adapts forward at 0.99c (EV −3.8) and to the disc at γ 707 (EV +12.4),
  and stays pinned at EV_dark sideways. The camera mode keeps its log-average meter.
