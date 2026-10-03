### Changed

- Galaxy map catalogue switched off CNS3 (M1.7, F6, Q7): `data/starmap/stars.json` is now written
  by AILANG (`make starmap`, `sim/tools/starmap.ail` via `bright_main.ail mapMain`) from the same
  rows as the shipped point tiers, quick (CNS5 + Hipparcos photometry fill) + bright (HIP2), within
  25 pc: 5,687 stars (was 3,802), float64 positions, one star per line, nearest first. Ids are stable
  catalogue ids (`Gaia DR3 n`, `CNS5:n`, `HIP n`), one per star, so alpha Centauri A (`CNS5:3627`)
  and B (`HIP 71681`) are two selectable stars, both at the catalogue's 4.321 ly (Q2 (a), D-19).
  `make catalogue-verify` rebuilds and cmp-checks it; `make star-catalogue-test` checks every map
  row is a tier record bit for bit.
- `data/starmap/names.json` is keyed by catalogue id (52 names; Procyon, Kruger 60 and Ross 614 are
  one catalogue row each, so their B names are gone). The map subtitle is the catalogue id and the
  catalogue's own distance (D-17). `tools/check_star_names.py` checks every name by id against its
  SIMBAD reference: direction within 0.1 deg, distance within 3 %, V within 0.3 mag.
- Sky background destar (D-10) now masks only stars the point layers ship: Hipparcos V < 7 with
  Plx > 0 and B-V (the bright tier's cut) instead of V < 7.5. Masked sources 24,437 -> 17,690; the
  V 7-7.5 stars no layer draws stay as photo pixels. New texture pins in `data/sky/SHA256SUMS`.
- Replay golden `godot_map_voyage` re-recorded (Sirius A and alpha Cen A at their new catalogue
  doubles); `sim/core_test.ail` row 7 uses the alpha Cen A catalogue doubles (4.32103979249451 ly).
