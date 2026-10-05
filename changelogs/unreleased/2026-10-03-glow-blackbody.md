### Changed

- **The forward glow is a blackbody at the impact temperature, and its wall efficiency is
  ε = 1e-10.** These are ledger D-30, D-29 and Mark's follow-up to D-29 (attended 2026-10-03);
  the canon is stapledons-design `physics/higgs-bubble.md` §6, rows HB-95 to HB-112.
  - **Package pin.** `sunholo/relativity` goes from 0.7.0 to 0.8.0, in both `sim/` and
    `tools/glow_probe/`.
  - **M4.1 step 2 (the sim's pole values).** The sim now emits `ship.ism.glow_pole_w_m2`, which is
    `glowEmittanceAt(…, 1)`, and `ship.ism.glow_pole_k`, which is `glowTemperatureAt(…, 1)`.
    The temperature is (K/σ)^¼ and does not depend on ε.
  - **New default ε.** `glowEps` defaults to 1e-10; it was 1e-9 under D-15, and it is still a
    scenario parameter that the sim echoes.
    - At 0.99c the glow pole is 1.65e-3 of the dark sky.
    - It becomes visible, at 0.3 of the dark sky, from about 0.997c.
    - At the cap it is 1.56 cd/m².
  - **Godot mirrors the package instead of the placeholder.** `interior/forward_glow.gd` drops
    the equal-energy white (182.6 lm/W) and mirrors the package:
    - `temperature` is T_pole·cos^¼θ;
    - `efficacy` is luminousEfficacy;
    - `luminance` is radiance × efficacy;
    - `colour` is rgbUnitLuminance.

    The shader reads T and efficacy from Blackbody's existing colour lookup (`efficacy_lut`,
    `colour_lut`), which is finite and tested over 1e-3 K to 1e9 K.
  - **Goldens.** G-M4-4 (d) now checks the blackbody chain at 0.999c and at the cap. The new
    G-M4-6 compares the GPU colour ramp against the CPU at 10 temperatures. The worst
    difference is 0.07 %.
  - **ε comparison sheet.** `make glow-eps-sheet` renders the bridge interior and the forward
    sky at 0.99c, 0.995c, 0.999c, 0.9999c and the cap, for each candidate ε, through the eye
    exposure. It writes the measured star counts, limiting magnitudes and EV shifts. The
    published copy is `gs://stapledons-voyage-assets/refs/glow/eps_compare.jpg`.
  - **Review captures.** The M4.2 captures no longer use the probe's "glow preview" poles,
    because the sim now owns the glow values.

The blackbody spectrum is the canon’s labelled game stand-in for the impact
cascade, not a claim that real GeV cascades yield Planck radiation. Plate
projection retains G-M4-5; the combined spectral colour ramp is G-M4-6.
