### Added

- M1.5a photometric exposure (F5, Q8/D-19). Scene units are physical: stars carry E_v in lux
  and the background is in cd/m², calibrated so the panorama's dark-sky patch (median of the
  galactic caps, |b| ≥ 70°) reads 23.5 mag/arcsec², the deep-space value (D-25: integrated starlight, diffuse galactic light and EBL; no airglow or zodiacal light; Leinert et al. 1998), through `luminanceFromSurfaceMag`.
  `sky/exposure.gd` maps luminance to pixels with an EV100 exposure
  (L_white = 1.2 × 2^EV). It has two metering modes. **Eye** is the default: dark-adapted
  at EV_dark, where a star at the Crumey naked-eye threshold (`pointThresholdIlluminance`,
  field factor 2) lands on the display's lowest visible level. AC8 measures V_lim 6.9 against Crumey's 6.897; the window is 6.6–7.4. The eye light-adapts only
  when the log-average meter asks for less sensitivity. **Camera** is labelled: log-average
  metering, K = 12.5.
- Exposure honesty: the HUD shows the EV and the metering mode. **F** locks a fixed EV at the
  rest value and **M** switches eye/camera. In eye mode the HUD says "pinned at EV_dark" or "light-adapted", never "auto". The default camera EV clamp floor is −14 (ISO 102400, f/1.4, 30 s). The readability aids are off by default and
  labelled on the HUD when on: **[ ]** for exposure bias, **G** for a magnitude floor (V 8).
  The same controls exist as flags: `--exposure`, `--fixed-ev`, `--ev-bias`, `--ev-clamp`
  and `--mag-floor`.
- GDScript mirrors of `luminanceFromSurfaceMag`, `pointThresholdIlluminance`,
  `limitingMagnitude` and `vFromIlluminance` (sunholo/relativity 0.5.x), with package values
  in `make physics`.
- `make physics`: scene-unit tests and the corrected-F5 sideways-darker test. At θ′ = 90° and
  0.99c, D = 1/γ, and both the sky patch and an isotropic starfield patch read below the
  rest frame. The patch at θ′ = 8.1° (D = γ) is brighter, and the D = 1 boundary is at 29.83°.
- `make golden`: the display floor of the production chain, a known-lux star integrating to
  E·k/Ω_px within 1%, the calibrated sky reading L(23.5) within 1%, and the AC8
  limiting-magnitude ladder (V 5.0–8.5, measured in the rendered frame).
  `make bench` prints the AC8 limiting magnitude at 2560×1440.
- `make capture`: starboard pairs at rest and at 0.99c in camera mode, auto-exposed and at a
  fixed EV, beside the default eye view (`*_camera_auto.png`, `*_camera_fixed.png`,
  `exposure_sheet.png`).

### Changed

- `EXPOSURE` and `BG_EXPOSURE` are gone from `main.gd`; the goldens use a named `GOLDEN_PEAK`.
- The sky background un-stretches the panorama's luminance with one power law that keeps
  chromaticity, anchored at the dark patch (23.5 mag/arcsec²) and the photo's 99.9th-percentile
  luminance (20.8 mag/arcsec², the brightest Milky Way; D-25, Leinert 1998 Table 16, Duriscoe 2013). The
  NOIRLab photo is tone-stretched: its peak is about 290× its dark patch. With a purely linear
  calibration the Milky Way read about 6 mag too bright and buried the stars. The fitted
  exponent is 0.43; uniform (golden) panoramas keep 1.
