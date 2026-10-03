### Fixed

- A bright white ring around the forward view at γ ≈ 40–60 (from M1.8, #79). At these speeds the
  CMB pole is only 218–327 K. The PSF-blurred profile's radiance underflowed float32 near the cutoff,
  and the colour normalisation became 0/0 = NaN; the sky shader drew those texels as a white ring.
  The colour sums now run in float64, with the local temperature's colour as a fallback, and the
  shader also skips NaN texels.
- `make physics` checks every CMB profile texel is finite, that radiance never rises outward and
  that nothing is left at θ_max, at γ 40, 50, 60, 275 and 707, with and without the PSF.
  `make golden` adds 3 cases: γ 40, 50 and 60 ahead are exactly black at k = 1e6 (10 CMB cases).
  `make capture` adds a 20° view at γ 40–60 (`cmb_ring_sheet.png`).
