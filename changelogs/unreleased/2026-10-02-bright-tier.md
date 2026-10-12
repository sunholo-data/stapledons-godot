### Added

- M1.2d bright tier (D-5, D-19): `data/starmap/stars_bright.bin` (10,713 rows,
  257,112 B) and its sidecar, committed (Q4). These are the Hipparcos stars with
  V < 7 and a positive parallax (HIP2 I/311 astrometry, I/239 Johnson V and
  B−V) that match no CNS5 row (by CNS5's HIP column) and no GCNS row (within
  1″ at J2016.0 after proper motion, |G − V| < 2). Of these, 463 matched CNS5,
  4,120 matched GCNS and 7 lack B−V. teff comes from `teffFromBV`, v is V
  verbatim, and flags are 8. Rigel, Canopus, Betelgeuse, Deneb, Polaris, Spica
  and Antares are now real catalogue stars. It is built with
  `make catalogue TIER=bright` (`sim/tools/bright.ail`, entry `brightMain`,
  about 7 s on the VM).
- Rule (b), the HIP photometry fill: a CNS5 row without Gaia photometry, whose
  HIP id it owns, takes that star's V and `teffFromBV(B−V)` in place (flag 8).
  The quick tier fills 137 rows, among them Sirius (V −1.44), α Cen A, Procyon,
  Altair, Vega, Arcturus, Capella and Aldebaran. A row whose HIP id another
  CNS5 row shares is filled only when no other row's Gaia G is within 2 mag of
  V, so a faint companion never takes its primary's light. 11 such rows and
  CNS5:1164 (no B−V) stay missing.
- Rule (c), `data/starmap/bright_overrides.json`: α Cen B (HIP 71681) sits at
  the CNS5 system parallax (754.81 mas, 4.321 ly), at its own HIP2 position,
  19″ from A (about 25 AU). It is never at its own 4.09 ly. Each row carries a
  citation, and an override that cannot apply refuses the tier.
- `tools/bright_star_audit.gd`, the AC11 auditor (Godot replaces the planned
  Python). `make test-bright-audit` checks it on synthetic renders. The render
  gate runs in M1.5b.
- `make bright-test` checks the named checks (Vega excluded, Arcturus matched
  only after proper-motion propagation, Rigel included, CNS5 per-row epoch,
  Sirius filled, α Cen components, the shared-HIP guard, the V/Plx cuts and
  override refusals) on real fixture bytes, with strict VM = interpreter.
- `download_stars.sh bright` fetches the inputs, and `data/sky/SHA256SUMS` pins
  `hip2.dat.gz` and `hip_main.dat`.

### Changed

- The committed quick tier is rebuilt with the fill. Its bin sha256 changed
  from 73f4d0e1… to 422a0600…, the size is unchanged (5,908 rows), there are
  137 more complete rows (5,138 → 5,275) and the M-dwarf share went from 76.8%
  to 75.5%. The medium tier's bytes are unchanged.
- Flag 8 (Hipparcos photometry) is a valid flags bit: `FLAG_SETS` gains 8 and
  24, and `catalogue-stats` reports HIP photometry counts and judges the bright
  tier.
