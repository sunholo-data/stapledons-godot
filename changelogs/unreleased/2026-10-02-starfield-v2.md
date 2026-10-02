### Added

- M1.3 starfield v2: the sky flight draws a binary catalogue tier (`--tier=quick|medium|large`;
  default large when built, else medium) through `sky/star_catalogue.gd`, plus the bright tier on
  top once M1.2d builds it. The large tier is 324,307 instances (7,005 GCNS rows without
  photometry are skipped). The starfield no longer reads `stars.json`.
- Instance custom data is (T_eff, E_v at Sol in lux from `illuminanceFromV`, flags, |p|²); the
  shader rescales E_v by inverse square and multiplies by `pointFluxRatio(T, D)`.
- Rebasing (gate 5): positions are float64 on the CPU and uploaded as float32 hi/lo pairs with
  the ship as a hi/lo uniform, so the direction to the destination at the 1,000 AU stand-off holds
  to 2.4e-8 rad (the float64 path to below 1e-9). A CPU rebase of the large tier takes ~74 ms, so the
  default is design plan B (no CPU rebase; the shader computes direction and 1/r²).
- O-1: `LUT_T_MAX` 1e7 K, `LUT_SIZE` 1320, with a finite-LUT test and a 60 kK / D 44.7 golden.
- `make bench`: a scripted 30 s flight at 2560×1440 on Metal (frame times) and Vulkan (GPU
  star-pass time, which the Metal driver doesn't report), plus the CPU rebase time.
- `make golden` also checks: the stand-off direction in both rebase modes, the hot white dwarf,
  and that the faint-star cull (splat peak below 1e-4) leaves nothing visible.

### Changed

- `catalogue_stats.gd`: a row with only half the default (teff 0, or v 99) and no MISSING_PHOT
  flag is now a violation. The output labels rows in the bin, with and without photometry,
  separately from rows excluded before the bin.
