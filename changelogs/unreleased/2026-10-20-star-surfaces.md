### Added

- **Stars show their surfaces** (R2-STAR-SURFACES SS0-SS2, D-105). In the Auto view a star's disc now
  shows what its real surface would show at that size: Aldebaran's giant convection cells (about 33
  across its disc at the stop), red dwarfs' dark starspots with bright faculae, and every star's own
  limb darkening (Claret & Bloemen 2011, per temperature and gravity). Structure appears only where
  it would resolve, so the Sun from home and every distant star look as before, and a star's total
  light is unchanged. Each surface element is a blackbody at its own temperature, so spots are redder
  and the whole surface Doppler-shifts as the disc does. The Realistic view still shows the clipped
  white disc an eye would see.
- **sunholo/celestial 0.5.0** (`stellar`, `stellar_ld`): limb darkening, convection, spot, rotation and
  corona numbers, each cited. **Protocol 2.13**: every finite star carries its `surface` record.
