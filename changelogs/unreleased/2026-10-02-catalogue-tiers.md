### Changed

- The catalogue tool builds every list with linear builtins (map, filter,
  flatMap, take, one stable sort), never a consing fold (ailang#1501). On the VM,
  the medium tier drops from 6 min 23 s to 61 s and the large tier from
  8 min 56 s to 55 s. The output bytes are unchanged.

### Added

- All three tiers build from the real catalogues: quick (5,908 rows), medium
  (50,000 rows, 965 excluded) and large (331,312 rows, 7,951,488 B).
- N3: an exact 50,000-row boundary test with missing rows in between, an
  independent excluded count, and tests that the first error wins (row order) in
  the transform, the range check and `encodeRows`.
- `make catalogue-parity` builds a real tier once on the interpreter and five
  times on the VM, compares the bin and sidecar bytes, and prints each run's wall
  time and peak RSS.
