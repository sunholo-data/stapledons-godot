### Added

- Real Milky Way background (M1.4, D-10): the NOIRLab `noirlab2430b` panorama with the
  catalogue-matched stars removed, rendered per pixel with inverse aberration and blackbody
  Doppler colour and brightness (`sky/background.gdshader`, `SkyBackground`, `SkyModel`).
- AILANG sky-model fitter `sim/tools/sky_model.ail`: per-colour T_c on the `sunholo/relativity`
  Planckian locus, residual and emission-line flags; `make sky-vm` (strict VM = interpreter,
  in `make test`) and the offline `make sky-model` (Godot headless I/O, `tools/sky_colours.gd`).
- `Relativity.surface_brightness_ratio` and physics checks for extended sources (D^4
  bolometric), the panorama contract and the T_c code; golden AC5 background marker (12 cases)
  and AC6 background colour (D = 0.3, 1, 3).

### Notes

- The panorama is valid to about 50 ly from Sol (parallax); emission nebulae are flagged,
  not yet line-modelled; exposure is hand-set until M1.5.
